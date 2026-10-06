part of 'api_service.dart';

class _BoHttpError implements Exception {
  final int status;
  final String message;
  _BoHttpError(this.status, this.message);
  @override
  String toString() => 'BookOrbit HTTP $status: $message';
}

class _BoListenSession {
  final String bookId;
  final String sessionUuid;
  final DateTime startedAt;
  int? fileId;
  double listenedSeconds = 0;
  double? startPercent;
  double? lastPercent;
  bool deviceRemembered = false;

  _BoListenSession(this.bookId, this.sessionUuid, this.startedAt);
}

class _BoTicket {
  final String token;
  final DateTime expiresAt;
  final Set<String> fileIds;
  _BoTicket(this.token, this.expiresAt, this.fileIds);
}

/// ApiService for a BookOrbit server.
///
/// The rest of the app speaks Audiobookshelf, so this keeps every public
/// method and answers the Audiobookshelf routes they call from BookOrbit
/// instead: the authenticated request helpers are overridden and each
/// `/api/...` request is routed to a handler that calls `/api/v1/...` on the
/// BookOrbit server and returns an Audiobookshelf-shaped response. Routes
/// with no BookOrbit counterpart answer 404, which the callers already treat
/// as "not supported here".
class BookOrbitApiService extends ApiService implements BookOrbitTokenSource {
  BookOrbitApiService({
    required super.baseUrl,
    required super.token,
    super.refreshToken,
    super.isLegacyToken,
    super.customHeaders,
    super.onTokensRefreshed,
    super.loadPersistedTokens,
    super.onAuthExpired,
    super.httpClient,
  }) {
    if (token.isNotEmpty && baseUrl.isNotEmpty) {
      BookOrbitMediaProxy.instance.attach(this);
      unawaited(BookOrbitMediaProxy.instance.ensureRunning());
    }
  }

  @override
  ServerBackend get backend => ServerBackend.bookorbit;

  String get _basePath => Uri.parse(_cleanBaseUrl).path;
  String get _v1 => '$_cleanBaseUrl/api/v1';

  static String? _platformSource() {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }

  static final math.Random _rng = math.Random.secure();

  static String _uuid() {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  /// ISO-8601 in UTC to the millisecond, the precision the server keeps.
  static String _iso(DateTime t) {
    final u = t.toUtc();
    return DateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second, u.millisecond)
        .toIso8601String();
  }

  static final Map<String, Map<String, dynamic>> _manifests = {};
  static final Map<String, DateTime> _manifestAt = {};
  static final Map<String, Map<String, dynamic>> _details = {};
  static final Map<String, DateTime> _detailAt = {};
  static final Map<String, int> _revisions = {};
  static final Map<String, _BoListenSession> _sessions = {};
  static final Map<String, String> _coverVersions = {};
  static final Map<String, String> _bookLibrary = {};
  static final Map<String, _BoTicket> _tickets = {};
  static final Map<String, String> _assetByFile = {};
  static final Map<String, String> _serverVersions = {};
  static List<Map<String, dynamic>>? _librariesCache;
  static DateTime? _librariesAt;
  static final Map<String, ({DateTime at, Future<Object?> value})> _recent = {};

  /// One answer per [key] for [ttl], shared by concurrent callers. Failures
  /// are not kept.
  Future<T> _cached<T>(String key, Duration ttl, Future<T> Function() load) {
    final k = _key(key);
    final hit = _recent[k];
    if (hit != null && DateTime.now().difference(hit.at) < ttl) return hit.value.then((v) => v as T);
    final future = load();
    _recent[k] = (at: DateTime.now(), value: future);
    future.then<void>((_) {}, onError: (Object _) {
      if (identical(_recent[k]?.value, future)) _recent.remove(k);
    });
    return future;
  }

  static const _manifestTtl = Duration(minutes: 10);
  static const _detailTtl = Duration(minutes: 2);

  /// Keyed by book alone so the local and remote address of one server share
  /// them (cover URLs stay the same and image caches keep hitting). They are
  /// cleared whenever the signed-in account changes.
  String _key(String id) => id;

  /// Forget everything cached for the signed-in account.
  static void clearCaches() {
    _manifests.clear();
    _manifestAt.clear();
    _details.clear();
    _detailAt.clear();
    _revisions.clear();
    _sessions.clear();
    _coverVersions.clear();
    _bookLibrary.clear();
    _tickets.clear();
    _assetByFile.clear();
    _librariesCache = null;
    _librariesAt = null;
    _recent.clear();
  }

  @override
  String get upstreamBaseUrl => _cleanBaseUrl;

  @override
  Map<String, String> get upstreamCustomHeaders => customHeaders;

  @override
  Future<String?> currentAccessToken() async {
    await _ensureFreshAccessToken();
    return _accessToken.isEmpty ? null : _accessToken;
  }

  @override
  Future<String?> tokenAfterRejection() async {
    final outcome = await _refreshAccessToken();
    if (outcome == _RefreshOutcome.rejected) onAuthExpired?.call();
    return outcome == _RefreshOutcome.refreshed ? _accessToken : null;
  }

  @override
  Future<void> ensureMediaReady() async {
    BookOrbitMediaProxy.instance.attach(this);
    await BookOrbitMediaProxy.instance.ensureRunning();
    if (!_watchingCoverShape) {
      _watchingCoverShape = true;
      PlayerSettings.settingsChanged.addListener(() => unawaited(loadCoverShape()));
    }
    await loadCoverShape();
  }

  /// The cover shape picked in settings, globally and per library. With
  /// rectangle covers a book shows BookOrbit's portrait book cover, falling
  /// back to the square one when it has none. Kept here because cover URLs
  /// are built synchronously during layout.
  static bool _rectCovers = false;
  static final Map<String, bool> _rectCoversByLibrary = {};
  static bool _watchingCoverShape = false;

  static Future<void> loadCoverShape() async {
    final global = await PlayerSettings.getRectangleCovers();
    final byLibrary = <String, bool>{};
    for (final lib in _librariesCache ?? const <Map<String, dynamic>>[]) {
      final id = '${lib['id']}';
      final v = await PlayerSettings.getRectangleCoversOverride(id);
      if (v != null) byLibrary[id] = v == 'rect';
    }
    final changed = global != _rectCovers ||
        byLibrary.length != _rectCoversByLibrary.length ||
        byLibrary.entries.any((e) => _rectCoversByLibrary[e.key] != e.value);
    if (!changed) return;
    _rectCovers = global;
    _rectCoversByLibrary
      ..clear()
      ..addAll(byLibrary);
    // Screens rebuilt on the settings change before this finished; once
    // more so they pick up the other cover.
    PlayerSettings.notifySettingsChanged();
  }

  String _listCoverSlot(String itemId) {
    final lib = _bookLibrary[_key(itemId)];
    final rect = (lib == null ? null : _rectCoversByLibrary[lib]) ?? _rectCovers;
    return rect ? 'ebook' : 'audio';
  }

  /// A magic-link sign-in is a browser-style session: its refresh token only
  /// travels as the `refresh_token` cookie. Stored with this prefix so the
  /// refresh and sign-out calls know to send it that way.
  static const _webRefreshPrefix = 'web:';

  static String? _refreshCookie(http.Response r) {
    final raw = r.headers['set-cookie'];
    if (raw == null) return null;
    return RegExp(r'refresh_token=([^;,\s]+)').firstMatch(raw)?.group(1);
  }

  Map<String, String> _refreshHeaders(String refreshToken) => {
        ...customHeaders,
        'Content-Type': 'application/json',
        if (!kIsWeb) 'User-Agent': ApiService.userAgent,
        if (refreshToken.startsWith(_webRefreshPrefix))
          'Cookie': 'refresh_token=${refreshToken.substring(_webRefreshPrefix.length)}',
      };

  String _refreshBody(String refreshToken) => refreshToken.startsWith(_webRefreshPrefix)
      ? '{}'
      : jsonEncode({'refreshToken': refreshToken});

  @override
  Future<http.Response> _sendRefresh(String refreshToken) async {
    final r = await _post(
      Uri.parse('$_v1/auth/refresh'),
      headers: _refreshHeaders(refreshToken),
      body: _refreshBody(refreshToken),
    );
    if (r.statusCode != 200 || !refreshToken.startsWith(_webRefreshPrefix)) return r;
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final next = _refreshCookie(r);
    if (next != null) data['refreshToken'] = '$_webRefreshPrefix$next';
    return http.Response.bytes(
      utf8.encode(jsonEncode(data)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  static String _deviceLabel() {
    final model = [ApiService.deviceManufacturer, ApiService.deviceModel]
        .where((s) => s.isNotEmpty)
        .join(' ');
    final label = model.isEmpty ? 'Absorb' : 'Absorb on $model';
    return label.length > 100 ? label.substring(0, 100) : label;
  }

  static String _v1Of(String serverUrl) => '${normalizeServerUrl(serverUrl)}/api/v1';

  /// A BookOrbit server answers its public login options with a JSON object
  /// carrying `passwordLoginEnabled`; nothing else does.
  static Future<({bool ok, String? detail})> probe(
    String serverUrl, {
    Map<String, String> customHeaders = const {},
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final r = await http
          .get(Uri.parse('${_v1Of(serverUrl)}/auth/login-options'),
              headers: customHeaders.isNotEmpty ? customHeaders : null)
          .timeout(timeout);
      if (r.statusCode != 200) {
        return (ok: false, detail: 'Server returned HTTP ${r.statusCode} for the BookOrbit login options.');
      }
      final data = jsonDecode(r.body);
      if (data is Map && data.containsKey('passwordLoginEnabled')) {
        final sso = (data['oidcProviders'] as List<dynamic>? ?? const []).isNotEmpty;
        if (data['passwordLoginEnabled'] == false && !sso) {
          return (ok: false, detail: 'Password sign-in is turned off on this BookOrbit server.');
        }
        return (ok: true, detail: null);
      }
      return (ok: false, detail: 'The server answered, but it does not look like BookOrbit.');
    } on FormatException {
      return (ok: false, detail: 'The server answered, but it does not look like BookOrbit.');
    } catch (e) {
      return (ok: false, detail: ApiService._describePingError(e));
    }
  }

  /// Sign in and answer in the shape of an Audiobookshelf /login response.
  static Future<(Map<String, dynamic>?, int)> signIn({
    required String serverUrl,
    required String username,
    required String password,
    Map<String, String> customHeaders = const {},
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('${_v1Of(serverUrl)}/auth/login'),
            headers: {
              ...customHeaders,
              'Content-Type': 'application/json',
              if (!kIsWeb) 'User-Agent': ApiService.userAgent,
            },
            body: jsonEncode({
              'username': username,
              'password': password,
              'clientKind': 'native',
              'deviceLabel': _deviceLabel(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200 && r.statusCode != 201) {
        debugPrint('[BookOrbit] login failed: ${r.statusCode} ${r.body}');
        return (null, r.statusCode);
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final rawUser = data['user'] as Map<String, dynamic>? ?? const {};
      if (rawUser['isDefaultPassword'] == true) {
        return (<String, dynamic>{'bookOrbitDefaultPassword': true}, 403);
      }
      return (await _loginShape(serverUrl, data, customHeaders, data['refreshToken'] as String?), 200);
    } catch (e) {
      debugPrint('[BookOrbit] login error: $e');
      return (null, 0);
    }
  }

  /// A BookOrbit sign-in answer as an Audiobookshelf /login response, with
  /// the tokens inside `user` the way current Audiobookshelf servers put them.
  static Future<Map<String, dynamic>> _loginShape(
    String serverUrl,
    Map<String, dynamic> data,
    Map<String, String> customHeaders,
    String? refreshToken,
  ) async {
    final rawUser = data['user'] as Map<String, dynamic>? ?? const {};
    final access = data['accessToken'] as String?;
    final version = access == null ? null : await _fetchVersion(serverUrl, access, customHeaders);
    final user = BookOrbitMapper.user(rawUser)
      ..['accessToken'] = access
      ..['refreshToken'] = refreshToken;
    return {
      'user': user,
      'userDefaultLibraryId': null,
      'serverSettings': {'version': version ?? ''},
      'ereaderDevices': const [],
      'Source': 'bookorbit',
    };
  }

  /// What a BookOrbit server offers before anyone signs in: whether
  /// passwords work and which single sign-on providers it has. Null when the
  /// server can't be read or isn't BookOrbit.
  static Future<({bool passwordLogin, List<Map<String, dynamic>> oidcProviders})?> loginOptions(
    String serverUrl, {
    Map<String, String> customHeaders = const {},
  }) async {
    try {
      final r = await http
          .get(Uri.parse('${_v1Of(serverUrl)}/auth/login-options'),
              headers: customHeaders.isNotEmpty ? customHeaders : null)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final data = jsonDecode(r.body);
      if (data is! Map || !data.containsKey('passwordLoginEnabled')) return null;
      return (
        passwordLogin: data['passwordLoginEnabled'] != false,
        oidcProviders: (data['oidcProviders'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .where((p) => p['enabled'] != false && p['slug'] is String && p['clientId'] is String)
            .toList(),
      );
    } catch (e) {
      debugPrint('[BookOrbit] login options failed: $e');
      return null;
    }
  }

  static Map<String, String> _publicHeaders(Map<String, String> customHeaders) => {
        ...customHeaders,
        'Content-Type': 'application/json',
        if (!kIsWeb) 'User-Agent': ApiService.userAgent,
      };

  static String _errorText(http.Response r) {
    try {
      final m = (jsonDecode(r.body) as Map)['message'];
      if (m != null) return '$m';
    } catch (_) {}
    return r.body.length > 200 ? r.body.substring(0, 200) : r.body;
  }

  /// The one-time state for an OIDC sign-in and the identity provider's
  /// sign-in page. The app sends the user there itself.
  static Future<({String state, String authorizationEndpoint})> oidcState(
    String serverUrl,
    String slug, {
    Map<String, String> customHeaders = const {},
  }) async {
    final r = await http
        .post(
          Uri.parse('${_v1Of(serverUrl)}/auth/oidc/${Uri.encodeComponent(slug)}/state'),
          headers: _publicHeaders(customHeaders),
          body: '{}',
        )
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('BookOrbit returned HTTP ${r.statusCode}: ${_errorText(r)}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (state: data['state'] as String, authorizationEndpoint: data['authorizationEndpoint'] as String);
  }

  /// Trade the identity provider's code for BookOrbit tokens and answer like
  /// [signIn], with the server's reason when it says no.
  static Future<(Map<String, dynamic>?, int, String?)> signInWithOidc({
    required String serverUrl,
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String nonce,
    required String state,
    Map<String, String> customHeaders = const {},
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('${_v1Of(serverUrl)}/auth/oidc/callback'),
            headers: _publicHeaders(customHeaders),
            body: jsonEncode({
              'code': code,
              'codeVerifier': codeVerifier,
              'redirectUri': redirectUri,
              'nonce': nonce,
              'state': state,
              'clientKind': 'native',
              'deviceLabel': _deviceLabel(),
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (r.statusCode != 200 && r.statusCode != 201) {
        debugPrint('[BookOrbit] OIDC callback failed: ${r.statusCode} ${r.body}');
        return (null, r.statusCode, _errorText(r));
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      if (data['accessToken'] is! String) return (null, r.statusCode, 'No sign-in tokens in the reply');
      final cookie = _refreshCookie(r);
      final refresh = data['refreshToken'] as String? ?? (cookie == null ? null : '$_webRefreshPrefix$cookie');
      return (await _loginShape(serverUrl, data, customHeaders, refresh), 200, null);
    } catch (e) {
      debugPrint('[BookOrbit] OIDC callback error: $e');
      return (null, 0, '$e');
    }
  }

  /// The token from a BookOrbit magic link (`https://host/magic?token=...`),
  /// or the token itself when that is what was pasted.
  static String? magicLinkToken(String input) {
    final text = input.trim();
    final fromUrl = Uri.tryParse(text)?.queryParameters['token'];
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    if (RegExp(r'^[A-Za-z0-9_-]{16,512}$').hasMatch(text)) return text;
    return null;
  }

  /// Sign in with a magic link and answer like [signIn].
  static Future<(Map<String, dynamic>?, int)> signInWithMagicLink({
    required String serverUrl,
    required String link,
    Map<String, String> customHeaders = const {},
  }) async {
    final token = magicLinkToken(link);
    if (token == null) return (null, 400);
    try {
      final r = await http
          .post(
            Uri.parse('${_v1Of(serverUrl)}/auth/magic-links/login'),
            headers: {
              ...customHeaders,
              'Content-Type': 'application/json',
              if (!kIsWeb) 'User-Agent': ApiService.userAgent,
            },
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200 && r.statusCode != 201) {
        debugPrint('[BookOrbit] magic link login failed: ${r.statusCode} ${r.body}');
        return (null, r.statusCode);
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final cookie = _refreshCookie(r);
      return (
        await _loginShape(serverUrl, data, customHeaders, cookie == null ? null : '$_webRefreshPrefix$cookie'),
        200,
      );
    } catch (e) {
      debugPrint('[BookOrbit] magic link login error: $e');
      return (null, 0);
    }
  }

  static Future<String?> _fetchVersion(
    String serverUrl,
    String accessToken,
    Map<String, String> customHeaders,
  ) async {
    final origin = ApiService._originOf(serverUrl) ?? serverUrl;
    final cached = _serverVersions[origin];
    if (cached != null) return cached;
    try {
      final r = await http.get(
        Uri.parse('${_v1Of(serverUrl)}/app-info'),
        headers: {...customHeaders, 'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final v = (jsonDecode(r.body) as Map<String, dynamic>)['version'] as String?;
        if (v != null && v.isNotEmpty) {
          final label = 'BookOrbit ${v.startsWith('v') ? v.substring(1) : v}';
          _serverVersions[origin] = label;
          return label;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> revokeServerSession({bool allDevices = false}) async {
    final refresh = _refreshToken;
    if (refresh == null) return false;
    try {
      final r = await _post(
        Uri.parse('$_v1/auth/logout'),
        headers: _refreshHeaders(refresh),
        body: _refreshBody(refresh),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (e) {
      debugPrint('[BookOrbit] logout error: $e');
      return false;
    }
  }

  @override
  Future<PasswordChangeResult> changeMyPassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      // BookOrbit signs every device out on a password change, so leave it
      // to the web app rather than strand this session.
      const PasswordChangeResult(PasswordChangeStatus.unsupported);

  @override
  Future<AuthSessionsResult> getAuthSessions({int page = 0, int itemsPerPage = 20}) async =>
      const AuthSessionsResult(AuthSessionsStatus.unsupported);

  Uri _boUri(String path, [Map<String, dynamic>? query]) {
    final q = <String, dynamic>{};
    query?.forEach((k, v) {
      if (v == null) return;
      q[k] = v is Iterable ? v.map((e) => '$e').toList() : '$v';
    });
    return Uri.parse('$_v1$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  bool _isNative(Uri url) => url.path.startsWith('$_basePath/api/v1/');

  static const _timeout = Duration(seconds: 20);

  dynamic _decode(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _BoHttpError(r.statusCode, r.body.length > 300 ? r.body.substring(0, 300) : r.body);
    }
    if (r.body.isEmpty) return null;
    return jsonDecode(r.body);
  }

  Future<dynamic> _boGet(String path, [Map<String, dynamic>? query, Duration timeout = _timeout]) async =>
      _decode(await super._authGet(_boUri(path, query), timeout: timeout));

  Future<dynamic> _boPost(String path, [Object? body, Duration timeout = _timeout]) async =>
      _decode(await super._authPost(
        _boUri(path),
        body: body == null ? null : jsonEncode(body),
        timeout: timeout,
      ));

  /// PUT, and DELETE with a body, which the shared helpers don't cover.
  Future<dynamic> _boSend(String method, String path, Object body) async {
    await _ensureFreshAccessToken();
    final payload = jsonEncode(body);
    Future<http.Response> send() async {
      final req = http.Request(method, _boUri(path))
        ..headers.addAll(_headers)
        ..body = payload;
      final client = _httpClient ?? http.Client();
      try {
        final streamed = await client.send(req).timeout(_timeout);
        return await http.Response.fromStream(streamed).timeout(_timeout);
      } finally {
        if (_httpClient == null) client.close();
      }
    }

    var r = await send();
    if (r.statusCode == 401) {
      final outcome = await _refreshAccessToken();
      if (outcome == _RefreshOutcome.refreshed) r = await send();
      if (outcome == _RefreshOutcome.rejected) onAuthExpired?.call();
    }
    return _decode(r);
  }

  Future<dynamic> _boPut(String path, Object body) => _boSend('PUT', path, body);

  Future<dynamic> _boPatch(String path, Object body) async => _decode(await super._authPatch(
        _boUri(path),
        body: jsonEncode(body),
        timeout: _timeout,
      ));

  Future<dynamic> _boDelete(String path, {Object? body}) async {
    if (body != null) return _boSend('DELETE', path, body);
    return _decode(await super._authDelete(_boUri(path), timeout: _timeout));
  }

  static Future<List<T>> _pool<T>(List<Future<T> Function()> jobs, {int width = 6}) async {
    final results = List<T?>.filled(jobs.length, null);
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= jobs.length) return;
        results[i] = await jobs[i]();
      }
    }

    await Future.wait(List.generate(math.min(width, jobs.length), (_) => worker()));
    return results.cast<T>();
  }

  @override
  Future<http.Response> _authGet(Uri url,
      {Map<String, String>? headers,
      bool sendRefreshTokenHeader = false,
      Duration timeout = const Duration(seconds: 15)}) {
    if (_isNative(url)) return super._authGet(url, headers: headers, timeout: timeout);
    return _route('GET', url, null);
  }

  @override
  Future<http.Response> _authPost(Uri url,
      {Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 15)}) {
    if (_isNative(url)) return super._authPost(url, headers: headers, body: body, timeout: timeout);
    return _route('POST', url, body);
  }

  @override
  Future<http.Response> _authPatch(Uri url,
      {Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 15)}) {
    if (_isNative(url)) return super._authPatch(url, headers: headers, body: body, timeout: timeout);
    return _route('PATCH', url, body);
  }

  @override
  Future<http.Response> _authDelete(Uri url,
      {Map<String, String>? headers, Duration timeout = const Duration(seconds: 15)}) {
    if (_isNative(url)) return super._authDelete(url, headers: headers, timeout: timeout);
    return _route('DELETE', url, null);
  }

  static http.Response _json(Object? data, [int status = 200]) => http.Response.bytes(
        utf8.encode(jsonEncode(data)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  static http.Response _status(int status, [String message = '']) =>
      _json({'error': message}, status);

  Future<http.Response> _route(String method, Uri url, Object? body) async {
    var path = url.path;
    if (_basePath.isNotEmpty && path.startsWith(_basePath)) {
      path = path.substring(_basePath.length);
    }
    final seg = path.split('/').where((s) => s.isNotEmpty).map(Uri.decodeComponent).toList();
    final q = url.queryParameters;
    Map<String, dynamic> json = const {};
    if (body is String && body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {}
    }
    try {
      final result = await _dispatch(method, seg, q, json);
      if (result == null) {
        debugPrint('[BookOrbit] No BookOrbit route for $method $path');
        return _status(404, 'Not available on BookOrbit');
      }
      return result;
    } on _BoHttpError catch (e) {
      debugPrint('[BookOrbit] $method $path -> ${e.status} ${e.message}');
      return _status(e.status, e.message);
    } on http.ClientException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e, st) {
      debugPrint('[BookOrbit] $method $path failed: $e\n$st');
      return _status(500, '$e');
    }
  }

  Future<http.Response?> _dispatch(
    String method,
    List<String> s,
    Map<String, String> q,
    Map<String, dynamic> body,
  ) async {
    if (s.isEmpty || s[0] != 'api') return null;
    final n = s.length;
    String at(int i) => i < n ? s[i] : '';

    switch (at(1)) {
      case 'authorize':
        if (method == 'POST') return _json(await _authorizePayload());
      case 'me':
        return _routeMe(method, s, q, body);
      case 'libraries':
        if (method != 'GET') return null;
        if (n == 2) return _json({'libraries': await _libraries()});
        final libId = at(2);
        if (n == 3) {
          final lib = (await _libraries()).firstWhere((l) => l['id'] == libId,
              orElse: () => const <String, dynamic>{});
          if (lib.isEmpty) return null;
          final out = Map<String, dynamic>.from(lib);
          if ((q['include'] ?? '').contains('filterdata')) {
            out['filterdata'] = await _filterData(libId);
          }
          return _json(out);
        }
        switch (at(3)) {
          case 'items':
            return _json(await _libraryItems(libId, q));
          case 'personalized':
            return _json(await _cached('personalized:$libId:${q['shelves'] ?? ''}:${q['limit'] ?? ''}',
                const Duration(seconds: 20), () => _personalized(libId, q)));
          case 'series':
            if (n == 4) return _json(await _librarySeries(libId, q));
            return _json(await _seriesMeta(at(4), libId));
          case 'authors':
            return _json(await _libraryAuthors(libId, q));
          case 'search':
            return _json(await _search(libId, q['q'] ?? '', int.tryParse(q['limit'] ?? '') ?? 25));
          case 'filterdata':
            return _json(await _filterData(libId));
          case 'narrators':
            final narrators = await _entityCounts('narrator', pages: 20);
            return _json({
              'narrators': [for (final n in narrators) {'name': n.name, 'numBooks': n.books}],
            });
          case 'collections':
            return _json(await _libraryCollections(libId, q));
          case 'playlists':
            return _json({'results': const [], 'total': 0});
          case 'stats':
            return _json(await _libraryStats(libId));
        }
        return null;
      case 'series':
        if (method == 'GET' && n == 3) return _json(await _seriesMeta(at(2), null));
        return null;
      case 'authors':
        if (method == 'GET' && n == 3) {
          final author = await _authorDetail(at(2), q);
          return author == null ? _status(404, 'Author not found') : _json(author);
        }
        if (n < 3) return null;
        final authorId = await _resolveAuthorId(at(2));
        if (authorId == null) return _status(404, 'Author not found');
        if (n == 3 && method == 'PATCH') return _json(await _updateAuthor(authorId, body));
        if (n == 4 && at(3) == 'image' && method == 'POST') return _authorImageFromUrl(authorId, '${body['url'] ?? ''}');
        if (n == 4 && at(3) == 'image' && method == 'DELETE') {
          await _boDelete('/authors/$authorId/image');
          return _json({'success': true});
        }
        if (n == 4 && at(3) == 'match' && method == 'POST') return _json(await _matchAuthor(authorId));
        return null;
      case 'search':
        if (method != 'GET') return null;
        switch (at(2)) {
          case 'covers':
            return _json({'results': await _searchCovers(q)});
          case 'books':
            return _json(await _searchBooks(q));
          case 'chapters':
            return _json(await _searchChapters(q['asin'] ?? '', q['region'] ?? 'us'));
        }
        return null;
      case 'items':
        if (at(2) == 'batch' && at(3) == 'get' && method == 'POST') {
          final ids = (body['libraryItemIds'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
          return _json({'libraryItems': await _itemsBatch(ids)});
        }
        if (at(2) == 'batch' && at(3) == 'delete' && method == 'POST') {
          final ids = (body['libraryItemIds'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
          return _deleteBooks(ids, hard: q['hard'] == '1');
        }
        if (n == 3 && method == 'GET') {
          final include = q['include'] ?? '';
          return _json(await _item(at(2), withProgress: include.contains('progress')));
        }
        if (n == 3 && method == 'DELETE') return _deleteBooks([at(2)], hard: q['hard'] == '1');
        if (n == 4 && at(3) == 'media' && method == 'PATCH') return _json(await _updateMedia(at(2), body));
        if (n == 4 && at(3) == 'cover' && method == 'POST') return _coverFromUrl(at(2), '${body['url'] ?? ''}');
        if (n == 4 && at(3) == 'cover' && method == 'DELETE') {
          await _boDelete('/books/${at(2)}/cover?medium=${await _coverMedium(at(2))}');
          await _afterEdit(at(2));
          return _json({'success': true});
        }
        if (n == 4 && at(3) == 'match' && method == 'POST') return _json(await _quickMatch(at(2)));
        if (n == 4 && at(3) == 'chapters' && method == 'POST') {
          final chapters = BookOrbitMapper.chapters(body['chapters'] as List<dynamic>? ?? const []);
          await _boPatch('/books/${at(2)}/metadata', {
            'audioMetadata': {'chapters': chapters},
          });
          await _afterEdit(at(2), chaptersChanged: true);
          return _json({'success': true, 'updated': true});
        }
        if (n >= 4 && at(3) == 'play' && method == 'POST') {
          if (n > 4) return null;
          return _json(await _startSession(at(2), body));
        }
        return null;
      case 'session':
        if (method != 'POST') return null;
        if (at(2) == 'local') return _json(await _localSession(body));
        if (at(2) == 'local-all') {
          final sessions = (body['sessions'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          for (final session in sessions) {
            await _localSession(session);
          }
          return _json({'results': sessions.map((e) => {'id': e['id'], 'success': true}).toList()});
        }
        if (n == 4 && at(3) == 'sync') return _syncSession(at(2), body);
        if (n == 4 && at(3) == 'close') {
          await _closeSession(at(2), body);
          return _json(const <String, dynamic>{});
        }
        return null;
      case 'collections':
        return _routeCollections(method, s, body);
    }
    return null;
  }

  Future<http.Response?> _routeMe(
    String method,
    List<String> s,
    Map<String, String> q,
    Map<String, dynamic> body,
  ) async {
    final n = s.length;
    String at(int i) => i < n ? s[i] : '';
    if (n == 2 && method == 'GET') {
      final me = Map<String, dynamic>.from(BookOrbitMapper.user(
          await _boGet('/auth/me') as Map<String, dynamic>));
      return _json(me);
    }
    switch (at(2)) {
      case 'progress':
        if (n == 3 && method == 'GET') {
          return _json({
            'mediaProgress': await _cached('progress', const Duration(seconds: 30), _allProgress),
          });
        }
        if (n == 4 && method == 'GET') {
          final p = await _itemProgress(at(3));
          return p == null ? _status(404, 'No progress') : _json(p);
        }
        if (n == 4 && method == 'PATCH') {
          await _patchProgress(at(3), body);
          return _json(const <String, dynamic>{});
        }
        if (n == 4 && method == 'DELETE') {
          await _deleteProgress(at(3));
          return _json(const <String, dynamic>{});
        }
        return null;
      case 'bookmarks':
        if (method != 'GET') return null;
        if (n == 4) return _json({'bookmarks': await _bookmarksFor(at(3))});
        return _json({'bookmarks': await _recentBookmarks()});
      case 'item':
        if (at(3) == 'listening-sessions' && n >= 5 && method == 'GET') {
          if (n > 5) return _json({'sessions': const [], 'total': 0, 'numPages': 1, 'page': 0});
          return _json(await _itemListeningSessions(at(4), q));
        }
        if (n >= 5 && at(4) == 'bookmark') {
          final itemId = at(3);
          if (method == 'POST') {
            final b = await _createBookmark(itemId, body);
            return _json(b);
          }
          if (method == 'PATCH') {
            final ok = await _updateBookmark(itemId, body);
            return ok ? _json(const <String, dynamic>{}) : _status(404, 'Bookmark not found');
          }
          if (method == 'DELETE' && n == 6) {
            final ok = await _deleteBookmark(itemId, double.tryParse(at(5)) ?? -1);
            return ok ? _json(const <String, dynamic>{}) : _status(404, 'Bookmark not found');
          }
        }
        return null;
      case 'listening-stats':
        if (method == 'GET') {
          return _json(await _cached('listening-stats', const Duration(minutes: 5), _listeningStats));
        }
        return null;
      case 'listening-sessions':
        if (method == 'GET') {
          return _json({
            'sessions': const [],
            'total': 0,
            'numPages': 0,
            'page': int.tryParse(q['page'] ?? '') ?? 0,
            'itemsPerPage': int.tryParse(q['itemsPerPage'] ?? '') ?? 20,
          });
        }
        return null;
      case 'items-in-progress':
        if (method == 'GET') {
          final cards = await _shelfCards('continue-listening', 50);
          return _json({'libraryItems': cards.map((c) => _cardItem(c)).toList()});
        }
        return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> _authorizePayload() async {
    final raw = await _boGet('/auth/me') as Map<String, dynamic>;
    final version = await _fetchVersion(_cleanBaseUrl, _accessToken, customHeaders);
    return {
      'user': BookOrbitMapper.user(raw),
      'userDefaultLibraryId': null,
      'serverSettings': {'version': version ?? ''},
      'ereaderDevices': const [],
      'Source': 'bookorbit',
    };
  }

  Future<List<Map<String, dynamic>>> _libraries() async {
    final cached = _librariesCache;
    final at = _librariesAt;
    if (cached != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 5)) {
      return cached;
    }
    final raw = await _boGet('/libraries') as List<dynamic>;
    final libs = raw
        .whereType<Map<String, dynamic>>()
        .where((l) => l['type'] != 'podcasts')
        .map(BookOrbitMapper.library)
        .toList();
    _librariesCache = libs;
    _librariesAt = DateTime.now();
    unawaited(loadCoverShape());
    return libs;
  }

  Future<Map<String, dynamic>?> _libraryStats(String libId) async {
    final s = await _boGet('/libraries/$libId/stats') as Map<String, dynamic>;
    final formats = (s['formatCounts'] as Map?)?.cast<String, dynamic>() ?? const {};
    final audio = formats.entries
        .where((e) => BookOrbitMapper.isAudioFormat(e.key))
        .fold<num>(0, (sum, e) => sum + ((e.value as num?) ?? 0));
    return {
      'totalItems': s['totalBooks'] ?? 0,
      'totalSize': s['totalSizeBytes'] ?? 0,
      'totalDuration': 0,
      'numAudioFiles': audio,
      'numAudioTracks': audio,
      'totalAuthors': 0,
      'totalGenres': 0,
    };
  }

  Map<String, dynamic> _cardItem(Map<String, dynamic> card, {String? libraryId}) {
    final id = '${card['id']}';
    final cv = card['coverVersion'] as String?;
    if (cv != null) _coverVersions[_key(id)] = cv;
    if (libraryId != null) _bookLibrary[_key(id)] = libraryId;
    final manifest = _manifests[_key(id)];
    return BookOrbitMapper.item(
      card: card,
      manifest: manifest,
      libraryId: libraryId ?? _bookLibrary[_key(id)],
    );
  }

  Future<Map<String, dynamic>> _detail(String bookId, {bool fresh = false}) async {
    final k = _key(bookId);
    final at = _detailAt[k];
    if (!fresh && at != null && DateTime.now().difference(at) < _detailTtl) {
      return _details[k]!;
    }
    final d = await _boGet('/books/$bookId') as Map<String, dynamic>;
    _details[k] = d;
    _detailAt[k] = DateTime.now();
    final cv = d['coverVersion'] as String?;
    if (cv != null) _coverVersions[k] = cv;
    final lib = d['libraryId'];
    if (lib != null) _bookLibrary[k] = '$lib';
    return d;
  }

  static bool _detailHasAudio(Map<String, dynamic> detail) =>
      (detail['files'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .where((f) => f['role'] == 'primary' || f['role'] == 'content')
          .any((f) => BookOrbitMapper.isAudioFormat(f['format'] as String?));

  Future<Map<String, dynamic>?> _manifest(String bookId, {bool fresh = false}) async {
    final k = _key(bookId);
    final at = _manifestAt[k];
    if (!fresh && at != null && DateTime.now().difference(at) < _manifestTtl) {
      return _manifests[k];
    }
    try {
      final m = await _boGet('/audiobooks/$bookId/manifest') as Map<String, dynamic>;
      _manifests[k] = m;
      _manifestAt[k] = DateTime.now();
      for (final a in (m['assets'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
        _assetByFile[_key('${a['fileId']}')] = '${a['assetId']}';
      }
      return m;
    } on _BoHttpError catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _item(String bookId, {bool withProgress = false}) async {
    final detail = await _detail(bookId, fresh: true);
    final manifest = _detailHasAudio(detail) ? await _manifest(bookId) : null;
    final item = BookOrbitMapper.item(detail: detail, manifest: manifest);
    if (withProgress) {
      final p = await _itemProgress(bookId, detail: detail, manifest: manifest);
      if (p != null) item['userMediaProgress'] = p;
    }
    return item;
  }

  Future<List<Map<String, dynamic>>> _itemsBatch(List<String> ids) async {
    final jobs = ids.map((id) => () async {
          try {
            final detail = await _detail(id);
            return BookOrbitMapper.item(detail: detail, manifest: _manifests[_key(id)]);
          } catch (_) {
            return null;
          }
        }).toList();
    final items = await _pool(jobs);
    return items.whereType<Map<String, dynamic>>().toList();
  }

  static const _audioFormatList = ['m4b', 'mp3', 'm4a', 'opus', 'ogg', 'flac'];
  static const _ebookFormatList = ['epub', 'kepub', 'pdf', 'mobi', 'azw3', 'azw', 'fb2', 'cbz', 'cbr', 'cb7'];

  Map<String, dynamic> _rule(String field, String op, [Object? value, Object? valueTo]) => {
        'type': 'rule',
        'field': field,
        'operator': op,
        if (value != null) 'value': value,
        if (valueTo != null) 'valueTo': valueTo,
      };

  /// Turns an Audiobookshelf `group.base64value` filter into BookOrbit rules.
  /// Returns (rules, q, unsupported).
  Future<({List<Map<String, dynamic>> rules, String? q, bool unsupported, String? seriesId})>
      _translateFilter(String? filter) async {
    final rules = <Map<String, dynamic>>[];
    if (filter == null || filter.isEmpty) {
      return (rules: rules, q: null, unsupported: false, seriesId: null);
    }
    final dot = filter.indexOf('.');
    final group = dot < 0 ? filter : filter.substring(0, dot);
    var value = '';
    if (dot >= 0) {
      final raw = Uri.decodeComponent(filter.substring(dot + 1));
      try {
        value = utf8.decode(base64Decode(base64.normalize(raw)));
      } catch (_) {
        value = raw;
      }
    }
    String? q;
    switch (group) {
      case 'progress':
        switch (value) {
          case 'finished':
            rules.add(_rule('readStatus', 'includesAny', ['read', 'skimmed']));
          case 'in-progress':
            rules.add(_rule('readStatus', 'includesAny', ['reading', 'rereading', 'on_hold']));
          case 'not-started':
            rules.add(_rule('readStatus', 'includesAny', ['unread', 'want_to_read']));
          case 'not-finished':
            rules.add(_rule('readStatus', 'excludesAll', ['read', 'skimmed']));
        }
      case 'series':
        if (int.tryParse(value) != null) {
          return (rules: rules, q: null, unsupported: false, seriesId: value);
        }
        final name = value.startsWith('name:') ? value.substring(5) : value;
        rules.add(_rule('series', 'eq', name));
      case 'authors':
        final name = await _authorName(value);
        if (name == null) return (rules: rules, q: null, unsupported: true, seriesId: null);
        rules.add(_rule('author', 'includesAny', [name]));
      case 'narrators':
        q = value;
      case 'genres':
        rules.add(_rule('genre', 'includesAny', [value]));
      case 'tags':
        rules.add(_rule('tag', 'includesAny', [value]));
      case 'languages':
        rules.add(_rule('language', 'eq', value));
      case 'publishers':
        rules.add(_rule('publisher', 'eq', value));
      case 'publishedDecades':
        final decade = int.tryParse(value);
        if (decade != null) rules.add(_rule('publishedYear', 'between', decade, decade + 9));
      case 'ebooks':
        if (value == 'ebook' || value == 'supplementary') {
          rules.add(_rule('format', 'includesAny', _ebookFormatList));
        } else {
          rules.add(_rule('format', 'excludesAll', _ebookFormatList));
        }
      case 'tracks':
        if (value == 'none') {
          rules.add(_rule('format', 'excludesAll', _audioFormatList));
        } else {
          rules.add(_rule('format', 'includesAny', _audioFormatList));
        }
      case 'issues':
        rules.add(_rule('fileAvailability', 'isMissing'));
      case 'missing':
        final field = switch (value) {
          'isbn' => 'isbn',
          'description' => 'description',
          'series' => 'series',
          'authors' => 'author',
          'publishedYear' => 'publishedYear',
          'publisher' => 'publisher',
          'genres' => 'genre',
          'tags' => 'tag',
          'language' => 'language',
          'cover' => 'cover',
          _ => null,
        };
        if (field == null) return (rules: rules, q: null, unsupported: true, seriesId: null);
        rules.add(field == 'cover' ? _rule('cover', 'isMissing') : _rule(field, 'isEmpty'));
      default:
        return (rules: rules, q: null, unsupported: true, seriesId: null);
    }
    return (rules: rules, q: q, unsupported: false, seriesId: null);
  }

  List<Map<String, dynamic>> _translateSort(String? sort, bool desc) {
    final dir = desc ? 'desc' : 'asc';
    final field = switch (sort) {
      'addedAt' || 'birthtimeMs' || 'mtimeMs' => 'addedAt',
      'updatedAt' => 'updatedAt',
      'media.metadata.title' || 'media.metadata.titleIgnorePrefix' => 'title',
      'media.metadata.authorName' ||
      'media.metadata.authorNameLF' ||
      'media.metadata.author' =>
        'author',
      'media.metadata.publishedYear' => 'publishedYear',
      'size' => 'fileSize',
      'progress' => 'lastReadAt',
      'progress.createdAt' => 'startedAt',
      'progress.finishedAt' => 'finishedAt',
      'sequence' || 'media.metadata.series.sequence' => 'seriesIndex',
      'random' => 'random',
      _ => 'title',
    };
    return [
      {'field': field, 'dir': dir},
      if (field != 'title') {'field': 'title', 'dir': 'asc'},
    ];
  }

  Future<String?> _authorName(String authorId) async {
    if (authorId.startsWith(BookOrbitMapper.authorNamePrefix)) {
      return authorId.substring(BookOrbitMapper.authorNamePrefix.length);
    }
    if (int.tryParse(authorId) == null) return authorId;
    try {
      final a = await _boGet('/authors/$authorId') as Map<String, dynamic>;
      return a['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _libraryItems(String libId, Map<String, String> q) async {
    var page = int.tryParse(q['page'] ?? '') ?? 0;
    var limit = int.tryParse(q['limit'] ?? '') ?? 20;
    final desc = q['desc'] == '1';
    final sort = q['sort'];
    final collapse = q['collapseseries'] == '1';
    final filter = q['filter'];
    final t = await _translateFilter(filter);

    Map<String, dynamic> envelope(List<Map<String, dynamic>> results, int total) => {
          'results': results,
          'total': total,
          'limit': limit,
          'page': page,
          'sortBy': sort,
          'sortDesc': desc,
          'filterBy': filter,
          'mediaType': 'book',
          'minified': q['minified'] != '0',
          'collapseseries': collapse,
          'include': '',
        };

    if (t.unsupported) {
      debugPrint('[BookOrbit] Filter $filter has no BookOrbit equivalent');
      return envelope(const [], 0);
    }
    // BookOrbit has no narrator rule, so a narrator is a text search narrowed
    // to exact names here. Paging happens after the narrowing.
    final narrator = filter != null && filter.startsWith('narrators.') ? t.q?.toLowerCase() : null;
    final wantPage = page;
    final wantLimit = limit;
    if (narrator != null) {
      page = 0;
      limit = 0;
    }
    if (t.seriesId != null) {
      final books = await _seriesBooks(t.seriesId!, libId, sort: sort, desc: desc);
      final start = limit <= 0 ? 0 : page * limit;
      final slice = limit <= 0
          ? books
          : books.skip(start).take(limit).toList();
      return envelope(slice, books.length);
    }

    final rules = t.rules;
    Map<String, dynamic> query(int p, int size) => {
          if (rules.isNotEmpty) 'filter': {'type': 'group', 'join': 'AND', 'rules': rules},
          'sort': _translateSort(sort, desc),
          'pagination': {'page': p, 'size': size},
          if (collapse) 'collapseSeries': true,
          if (t.q != null) 'q': t.q,
        };

    final cards = <Map<String, dynamic>>[];
    var total = 0;
    if (limit > 0 && limit <= 200) {
      final res = await _boPost('/libraries/$libId/books', query(page, limit)) as Map<String, dynamic>;
      cards.addAll((res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>());
      total = (res['total'] as num?)?.toInt() ?? cards.length;
    } else {
      // limit 0 means everything; bigger pages are stitched from 200s.
      final start = limit <= 0 ? 0 : page * limit;
      final want = limit <= 0 ? 1 << 30 : limit;
      var serverPage = start ~/ 200;
      var skip = start % 200;
      for (var guard = 0; guard < 100 && cards.length < want; guard++) {
        final res = await _boPost('/libraries/$libId/books', query(serverPage, 200)) as Map<String, dynamic>;
        final items = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
        total = (res['total'] as num?)?.toInt() ?? total;
        cards.addAll(items.skip(skip).take(want - cards.length));
        skip = 0;
        serverPage++;
        if (items.length < 200 || serverPage * 200 >= total) break;
      }
      if (limit <= 0) limit = cards.length;
    }

    var results = cards.map((c) => _cardItem(c, libraryId: libId)).toList();
    if (narrator != null) {
      results = results.where((item) {
        final names = ((item['media'] as Map)['metadata'] as Map)['narrators'] as List;
        return names.any((n) => '$n'.toLowerCase() == narrator);
      }).toList();
      total = results.length;
      page = wantPage;
      limit = wantLimit;
      if (limit > 0) results = results.skip(page * limit).take(limit).toList();
    }
    return envelope(results, total);
  }

  Future<List<Map<String, dynamic>>> _seriesBooks(
    String seriesId,
    String? libId, {
    String? sort,
    bool desc = false,
  }) async {
    final bySort = switch (sort) {
      'addedAt' => 'addedAt',
      'media.metadata.title' => 'title',
      _ => 'seriesIndex',
    };
    final out = <Map<String, dynamic>>[];
    for (var page = 0; page < 20; page++) {
      final res = await _boGet('/series/$seriesId/books', {
        'page': page,
        'size': 100,
        'sort': bySort,
        'order': desc ? 'desc' : 'asc',
        if (libId != null) 'libraryId': libId,
      }) as Map<String, dynamic>;
      final items = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
      for (final c in items) {
        final item = _cardItem(c, libraryId: libId);
        // A series listing names this series' number in the single-map form
        // the series sheets read.
        final meta = (item['media'] as Map<String, dynamic>)['metadata'] as Map<String, dynamic>;
        meta['series'] = {
          'id': seriesId,
          'name': c['seriesName'],
          'sequence': c['seriesIndex'],
        };
        out.add(item);
      }
      final total = (res['total'] as num?)?.toInt() ?? out.length;
      if (items.length < 100 || out.length >= total) break;
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _shelfCards(String type, int limit) async {
    final res = await _boGet('/dashboard/scrollers/$type', {'limit': limit.clamp(1, 50)}) as Map<String, dynamic>;
    return (res['books'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  Future<bool> _hasOneLibrary() async => (await _libraries()).length <= 1;

  /// Dashboard shelves span every library. With more than one, keep the
  /// cards this library's in-progress books (one query) say belong here.
  Future<List<Map<String, dynamic>>> _inProgressHere(List<Map<String, dynamic>> cards, String libId) async {
    if (await _hasOneLibrary()) return cards;
    final here = await _libraryQueryCards(
      libId,
      rules: [_rule('readStatus', 'includesAny', ['reading', 'rereading', 'on_hold'])],
      sort: [{'field': 'lastReadAt', 'dir': 'desc'}],
      size: 200,
    );
    final ids = {for (final c in here) '${c['id']}'};
    for (final c in here) {
      _bookLibrary[_key('${c['id']}')] = libId;
    }
    final kept = cards.where((c) => ids.contains('${c['id']}')).toList();
    final keptIds = {for (final c in kept) '${c['id']}'};
    return [...kept, ...here.where((c) => !keptIds.contains('${c['id']}'))];
  }

  Future<List<Map<String, dynamic>>> _libraryQueryCards(
    String libId, {
    List<Map<String, dynamic>> rules = const [],
    required List<Map<String, dynamic>> sort,
    int size = 20,
  }) async {
    final res = await _boPost('/libraries/$libId/books', {
      if (rules.isNotEmpty) 'filter': {'type': 'group', 'join': 'AND', 'rules': rules},
      'sort': sort,
      'pagination': {'page': 0, 'size': size.clamp(1, 200)},
    }) as Map<String, dynamic>;
    return (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> _personalized(String libId, Map<String, String> q) async {
    final limit = (int.tryParse(q['limit'] ?? '') ?? 15).clamp(1, 50);
    final wanted = (q['shelves'] ?? '').split(',').where((s) => s.isNotEmpty).toSet();
    bool want(String id) => wanted.isEmpty || wanted.contains(id);

    Map<String, dynamic> shelf(String id, String label, List<Map<String, dynamic>> cards, {bool seriesEntity = false}) {
      final entities = cards.map((c) {
        final item = _cardItem(c, libraryId: libId);
        if (seriesEntity && c['seriesName'] != null) {
          ((item['media'] as Map<String, dynamic>)['metadata'] as Map<String, dynamic>)['series'] = {
            'id': '${c['seriesId'] ?? 'name:${c['seriesName']}'}',
            'name': c['seriesName'],
            'sequence': c['seriesIndex'],
          };
        }
        return item;
      }).toList();
      return {
        'id': id,
        'label': label,
        'labelStringKey': label,
        'type': 'book',
        'entities': entities,
        'total': entities.length,
      };
    }

    final shelves = <Map<String, dynamic>>[];
    Future<void> add(String id, Future<Map<String, dynamic>> Function() build) async {
      if (!want(id)) return;
      try {
        final s = await build();
        if ((s['entities'] as List).isNotEmpty) shelves.add(s);
      } catch (e) {
        debugPrint('[BookOrbit] Shelf $id failed: $e');
      }
    }

    await add('continue-listening', () async {
      final listening = await _shelfCards('continue-listening', 50);
      final reading = await _shelfCards('continue-reading', 50);
      final seen = <String>{};
      final merged = [...listening, ...reading].where((c) => seen.add('${c['id']}')).toList();
      final cards = (await _inProgressHere(merged, libId)).take(limit).toList();
      return shelf('continue-listening', 'Continue Listening', cards);
    });
    await add('continue-series', () async {
      final cards = await _hasOneLibrary()
          ? await _shelfCards('up-next-in-series', limit)
          : await _libraryQueryCards(
              libId,
              rules: [_rule('seriesStatus', 'isUpNext')],
              sort: [{'field': 'series', 'dir': 'asc'}],
              size: limit,
            );
      return shelf('continue-series', 'Continue Series', cards.take(limit).toList(), seriesEntity: true);
    });
    await add('recently-added', () async {
      final cards = await _libraryQueryCards(libId, sort: [{'field': 'addedAt', 'dir': 'desc'}], size: limit);
      return shelf('recently-added', 'Recently Added', cards);
    });
    await add('listen-again', () async {
      final cards = await _libraryQueryCards(
        libId,
        rules: [_rule('readStatus', 'includesAny', ['read'])],
        sort: [{'field': 'finishedAt', 'dir': 'desc'}],
        size: limit,
      );
      return shelf('listen-again', 'Listen Again', cards);
    });
    await add('discover', () async {
      final cards = await _libraryQueryCards(
        libId,
        rules: [_rule('readStatus', 'includesAny', ['unread'])],
        sort: [{'field': 'random', 'dir': 'asc'}],
        size: limit,
      );
      return shelf('discover', 'Discover', cards);
    });
    return shelves;
  }

  Map<String, dynamic> _stubItem(String bookId, {String? title, String? seriesId, String? seriesName, Object? sequence}) => {
        'id': bookId,
        'mediaType': 'book',
        'libraryId': _bookLibrary[_key(bookId)] ?? '',
        'media': {
          'coverPath': '/bookorbit/books/$bookId/cover',
          'metadata': {
            'title': title ?? '',
            'authorName': '',
            if (seriesId != null) 'series': {'id': seriesId, 'name': seriesName, 'sequence': sequence?.toString()},
          },
        },
      };

  Map<String, dynamic> _seriesSummary(Map<String, dynamic> s, String? libId) {
    final id = '${s['id']}';
    final books = <Map<String, dynamic>>[];
    for (final v in (s['volumes'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
      final bookId = v['bookId'];
      if (bookId == null) continue;
      books.add(_stubItem('$bookId', title: v['title'] as String?, seriesId: id, seriesName: s['name'] as String?, sequence: v['index']));
    }
    if (books.isEmpty) {
      for (final bookId in (s['coverBookIds'] as List<dynamic>? ?? const [])) {
        books.add(_stubItem('$bookId', seriesId: id, seriesName: s['name'] as String?));
      }
    }
    return BookOrbitMapper.series(s, books: books)..['libraryId'] = libId ?? '';
  }

  Future<Map<String, dynamic>> _librarySeries(String libId, Map<String, String> q) async {
    final page = int.tryParse(q['page'] ?? '') ?? 0;
    final limit = (int.tryParse(q['limit'] ?? '') ?? 50).clamp(1, 1000);
    final desc = q['desc'] == '1';
    final sort = switch (q['sort']) {
      'numBooks' || 'totalDuration' => 'bookCount',
      'addedAt' || 'lastBookAdded' || 'lastBookUpdated' || 'updatedAt' => 'lastAddedAt',
      _ => 'name',
    };
    final results = <Map<String, dynamic>>[];
    var total = 0;
    final start = page * limit;
    var serverPage = start ~/ 100;
    var skip = start % 100;
    for (var guard = 0; guard < 50 && results.length < limit; guard++) {
      final res = await _boGet('/series', {
        'page': serverPage,
        'size': 100,
        'sort': sort,
        'order': desc ? 'desc' : 'asc',
        'libraryId': libId,
      }) as Map<String, dynamic>;
      final items = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
      total = (res['total'] as num?)?.toInt() ?? total;
      results.addAll(items.skip(skip).take(limit - results.length).map((s) => _seriesSummary(s, libId)));
      skip = 0;
      serverPage++;
      if (items.length < 100 || serverPage * 100 >= total) break;
    }
    return {'results': results, 'total': total, 'limit': limit, 'page': page};
  }

  Future<Map<String, dynamic>?> _seriesMeta(String seriesId, String? libId) async {
    if (int.tryParse(seriesId) == null) return null;
    final res = await _boGet('/series/$seriesId/books', {
      'page': 0,
      'size': 1,
      if (libId != null) 'libraryId': libId,
    }) as Map<String, dynamic>;
    final info = res['seriesInfo'] as Map<String, dynamic>? ?? const {};
    return {
      'id': seriesId,
      'name': info['name'] ?? '',
      'nameIgnorePrefix': info['name'] ?? '',
      'numBooks': info['bookCount'] ?? res['total'] ?? 0,
      'libraryId': libId ?? '',
      'authors': info['authors'] ?? const [],
    };
  }

  Future<Map<String, dynamic>> _libraryAuthors(String libId, Map<String, String> q) async {
    final paged = q.containsKey('page');
    final page = int.tryParse(q['page'] ?? '') ?? 0;
    final limit = (int.tryParse(q['limit'] ?? '') ?? 100).clamp(1, 1000);
    final desc = q['desc'] == '1';
    final sort = switch (q['sort']) {
      'lastFirst' => 'sortName',
      'numBooks' => 'bookCount',
      'addedAt' || 'updatedAt' => 'lastAddedAt',
      _ => 'name',
    };
    final authors = <Map<String, dynamic>>[];
    var total = 0;
    final start = paged ? page * limit : 0;
    final want = paged ? limit : 5000;
    var serverPage = start ~/ 100;
    var skip = start % 100;
    for (var guard = 0; guard < 60 && authors.length < want; guard++) {
      final res = await _boGet('/authors', {
        'page': serverPage,
        'size': 100,
        'sort': sort,
        'order': desc ? 'desc' : 'asc',
        'libraryId': libId,
      }) as Map<String, dynamic>;
      final items = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
      total = (res['total'] as num?)?.toInt() ?? total;
      authors.addAll(items.skip(skip).take(want - authors.length).map(BookOrbitMapper.author));
      skip = 0;
      serverPage++;
      if (items.length < 100 || serverPage * 100 >= total) break;
    }
    if (!paged) return {'authors': authors};
    return {'results': authors, 'total': total, 'limit': limit, 'page': page};
  }

  Future<String?> _resolveAuthorId(String authorId) async {
    if (int.tryParse(authorId) != null) return authorId;
    final name = authorId.startsWith(BookOrbitMapper.authorNamePrefix)
        ? authorId.substring(BookOrbitMapper.authorNamePrefix.length)
        : authorId;
    final res = await _boGet('/authors', {'q': name, 'size': 25}) as Map<String, dynamic>;
    for (final a in (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
      if ('${a['name']}'.toLowerCase() == name.toLowerCase()) return '${a['id']}';
    }
    return null;
  }

  Future<Map<String, dynamic>?> _authorDetail(String authorId, Map<String, String> q) async {
    final id = await _resolveAuthorId(authorId);
    if (id == null) return null;
    final raw = await _boGet('/authors/$id') as Map<String, dynamic>;
    final author = BookOrbitMapper.author(raw);
    final include = q['include'] ?? '';
    if (include.contains('items') || include.contains('series')) {
      final libId = q['library'];
      final items = <Map<String, dynamic>>[];
      for (var page = 0; page < 20; page++) {
        final res = await _boGet('/authors/$id/books', {
          'page': page,
          'size': 100,
          'sort': 'title',
          'order': 'asc',
          if (libId != null) 'libraryId': libId,
        }) as Map<String, dynamic>;
        final cards = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
        items.addAll(cards.map((c) => _cardItem(c, libraryId: libId)));
        final total = (res['total'] as num?)?.toInt() ?? items.length;
        if (cards.length < 100 || items.length >= total) break;
      }
      author['libraryItems'] = items;
      final bySeries = <String, Map<String, dynamic>>{};
      for (final item in items) {
        final meta = (item['media'] as Map<String, dynamic>)['metadata'] as Map<String, dynamic>;
        for (final s in (meta['series'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
          final entry = bySeries.putIfAbsent('${s['id']}', () => {'id': s['id'], 'name': s['name'], 'items': <Map<String, dynamic>>[]});
          (entry['items'] as List<Map<String, dynamic>>).add(item);
        }
      }
      author['series'] = bySeries.values.toList();
    }
    return author;
  }

  Future<Map<String, dynamic>> _search(String libId, String text, int limit) async {
    final query = text.trim();
    final empty = {
      'book': const [],
      'podcast': const [],
      'series': const [],
      'authors': const [],
      'narrators': const [],
      'tags': const [],
      'genres': const [],
    };
    if (query.isEmpty) return empty;
    final booksFuture = _boPost('/libraries/$libId/books', {
      'q': query.length > 200 ? query.substring(0, 200) : query,
      'sort': [{'field': 'relevance', 'dir': 'desc'}],
      'pagination': {'page': 0, 'size': limit.clamp(1, 200)},
    });
    Future<dynamic>? globalFuture;
    if (query.length >= 2) {
      globalFuture = _boGet('/search', {
        'q': query.length > 200 ? query.substring(0, 200) : query,
        'limit': 10,
        'libraryId': libId,
      }).catchError((_) => null);
    }
    final books = await booksFuture as Map<String, dynamic>;
    final global = await globalFuture as Map<String, dynamic>?;

    final bookHits = (books['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((c) => {'libraryItem': _cardItem(c, libraryId: libId), 'matchKey': 'title', 'matchText': c['title']})
        .toList();
    final series = ((global?['series'] as Map?)?['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((hit) {
      final summary = _seriesSummary(hit['item'] as Map<String, dynamic>, libId);
      return {'series': summary, 'books': summary['books']};
    }).toList();
    final authors = ((global?['authors'] as Map?)?['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((hit) => BookOrbitMapper.author(hit['item'] as Map<String, dynamic>))
        .toList();
    final narratorCounts = <String, int>{};
    final lower = query.toLowerCase();
    for (final hit in bookHits) {
      final meta = ((hit['libraryItem'] as Map)['media'] as Map)['metadata'] as Map;
      for (final name in (meta['narrators'] as List? ?? const [])) {
        if ('$name'.toLowerCase().contains(lower)) {
          narratorCounts['$name'] = (narratorCounts['$name'] ?? 0) + 1;
        }
      }
    }
    return {
      ...empty,
      'book': bookHits,
      'series': series,
      'authors': authors,
      'narrators': narratorCounts.entries.map((e) => {'name': e.key, 'numBooks': e.value}).toList(),
    };
  }

  /// Names and book counts of a genre, tag, narrator, publisher or language,
  /// most used first, [pages] of 100 at most. BookOrbit only lists them for
  /// accounts that can edit metadata; others get none.
  Future<List<({String name, int books})>> _entityCounts(String type, {int pages = 1}) async {
    final out = <({String name, int books})>[];
    try {
      for (var page = 1; page <= pages; page++) {
        final res = await _boGet('/entity-manager/$type/browse', {
          'page': page,
          'pageSize': 100,
          'sortBy': 'bookCount',
          'sortOrder': 'desc',
        }) as Map<String, dynamic>;
        final items = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
        for (final e in items) {
          final name = '${e['name'] ?? ''}';
          final books = (e['bookCount'] as num?)?.toInt() ?? 1;
          if (name.isNotEmpty && books > 0) out.add((name: name, books: books));
        }
        final total = (res['total'] as num?)?.toInt() ?? 0;
        if (items.length < 100 || page * 100 >= total) break;
      }
    } on _BoHttpError catch (e) {
      if (e.status != 403) debugPrint('[BookOrbit] No $type list: ${e.status}');
    }
    return out;
  }

  Future<List<String>> _entityNames(String type, {int pages = 1}) async =>
      (await _entityCounts(type, pages: pages)).map((e) => e.name).toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  /// The decades that have books in the library, newest last.
  Future<List<String>> _publishedDecades(String libId) async {
    Future<Map<String, dynamic>> books(List<Map<String, dynamic>> rules, String dir) async =>
        await _boPost('/libraries/$libId/books', {
          'filter': {'type': 'group', 'join': 'AND', 'rules': rules},
          'sort': [{'field': 'publishedYear', 'dir': dir}],
          'pagination': {'page': 0, 'size': 1},
        }) as Map<String, dynamic>;
    int? year(Map<String, dynamic> res) {
      final items = res['items'] as List<dynamic>? ?? const [];
      return items.isEmpty ? null : ((items.first as Map)['publishedYear'] as num?)?.toInt();
    }

    try {
      final known = [_rule('publishedYear', 'isNotEmpty')];
      final ends = await Future.wait([books(known, 'asc'), books(known, 'desc')]);
      final first = year(ends[0]);
      final last = year(ends[1]);
      if (first == null || last == null) return const [];
      final decades = [for (var d = last - last % 10; d >= first - first % 10 && d > 0; d -= 10) d].take(30).toList();
      final counts = await Future.wait(decades.map((d) async =>
          ((await books([_rule('publishedYear', 'between', d, d + 9)], 'asc'))['total'] as num?)?.toInt() ?? 0));
      return [for (var i = decades.length - 1; i >= 0; i--) if (counts[i] > 0) '${decades[i]}'];
    } catch (e) {
      debugPrint('[BookOrbit] No decade list: $e');
      return const [];
    }
  }

  Future<Map<String, dynamic>> _filterData(String libId) =>
      _cached('filterdata:$libId', const Duration(minutes: 5), () => _loadFilterData(libId));

  Future<Map<String, dynamic>> _loadFilterData(String libId) async {
    final authors = (await _libraryAuthors(libId, const {}))['authors'] as List<dynamic>;
    final series = <Map<String, dynamic>>[];
    for (var page = 0; page < 30; page++) {
      final res = await _boGet('/series', {'page': page, 'size': 100, 'sort': 'name', 'order': 'asc', 'libraryId': libId}) as Map<String, dynamic>;
      final items = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
      series.addAll(items.map((s) => {'id': '${s['id']}', 'name': s['name'] ?? ''}));
      final total = (res['total'] as num?)?.toInt() ?? series.length;
      if (items.length < 100 || series.length >= total) break;
    }
    final lists = await Future.wait([
      _entityNames('genre'),
      _entityNames('tag'),
      _entityNames('narrator', pages: 20),
      _entityNames('language'),
      _entityNames('publisher', pages: 5),
      _publishedDecades(libId),
    ]);
    return {
      'authors': authors.map((a) => {'id': (a as Map)['id'], 'name': a['name']}).toList(),
      'series': series,
      'genres': lists[0],
      'tags': lists[1],
      'narrators': lists[2],
      'languages': lists[3],
      'publishers': lists[4],
      'publishedDecades': lists[5],
    };
  }

  Future<Map<String, dynamic>> _collection(Map<String, dynamic> c, {bool withBooks = true, int maxBooks = 2000}) async {
    final id = '${c['id']}';
    final books = <Map<String, dynamic>>[];
    if (withBooks) {
      for (var page = 0; page < 40 && books.length < maxBooks; page++) {
        final res = await _boGet('/collections/$id/books', {'page': page, 'size': 100}) as Map<String, dynamic>;
        final items = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
        books.addAll(items.map((card) => _cardItem(card)));
        final total = (res['total'] as num?)?.toInt() ?? books.length;
        if (items.length < 100 || books.length >= total) break;
      }
    }
    return {
      'id': id,
      'name': c['name'] ?? '',
      'description': c['description'],
      'libraryId': '',
      'userId': '${c['userId'] ?? ''}',
      'books': books,
      'lastUpdate': BookOrbitMapper.ms(c['updatedAt']),
      'createdAt': BookOrbitMapper.ms(c['createdAt']),
      'bookOrbit': {'isOwner': c['isOwner'], 'isPublic': c['isPublic'], 'bookCount': c['bookCount']},
    };
  }

  Future<Map<String, dynamic>> _libraryCollections(String libId, Map<String, String> q) async {
    final page = int.tryParse(q['page'] ?? '') ?? 0;
    final limit = (int.tryParse(q['limit'] ?? '') ?? 25).clamp(1, 200);
    final all = (await _boGet('/collections') as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((c) => (c['mediaType'] ?? 'books') == 'books')
        .toList();
    final slice = all.skip(page * limit).take(limit).toList();
    final results = await _pool(slice.map((c) => () => _collection(c, maxBooks: 500)).toList(), width: 4);
    for (final r in results) {
      r['libraryId'] = libId;
    }
    return {'results': results, 'total': all.length, 'limit': limit, 'page': page};
  }

  Future<http.Response?> _routeCollections(String method, List<String> s, Map<String, dynamic> body) async {
    final n = s.length;
    String at(int i) => i < n ? s[i] : '';
    if (n == 2 && method == 'POST') {
      final created = await _boPost('/collections', {
        'name': body['name'] ?? 'Collection',
        'icon': 'pi pi-book',
        if ((body['description'] as String?)?.isNotEmpty == true) 'description': body['description'],
      }) as Map<String, dynamic>;
      final books = (body['books'] as List<dynamic>? ?? const []).map((e) => int.tryParse('$e')).whereType<int>().toList();
      if (books.isNotEmpty) await _boPost('/collections/${created['id']}/books', {'bookIds': books});
      return _json(await _collection(created)..['libraryId'] = body['libraryId'] ?? '');
    }
    final id = at(2);
    if (n == 3) {
      switch (method) {
        case 'GET':
          return _json(await _collection(await _boGet('/collections/$id') as Map<String, dynamic>));
        case 'DELETE':
          await _boDelete('/collections/$id');
          return _json(const <String, dynamic>{});
        case 'PATCH':
          final patch = <String, dynamic>{
            if (body['name'] != null) 'name': body['name'],
            if (body['description'] != null) 'description': body['description'],
          };
          if (patch.isNotEmpty) await _boPatch('/collections/$id', patch);
          final wanted = body['books'] as List<dynamic>?;
          if (wanted != null) {
            final current = await _collection(await _boGet('/collections/$id') as Map<String, dynamic>);
            final have = (current['books'] as List).map((b) => '${(b as Map)['id']}').toList();
            final want = wanted.map((e) => '$e').where((e) => int.tryParse(e) != null).toList();
            if (have.join(',') != want.join(',')) {
              // BookOrbit has no reorder call and keeps books in the order
              // they were added, so the new list is added back in sequence.
              if (have.isNotEmpty) {
                await _boDelete('/collections/$id/books', body: {'bookIds': have.map(int.parse).toList()});
              }
              if (want.isNotEmpty) {
                await _boPost('/collections/$id/books', {'bookIds': want.map(int.parse).toList()});
              }
            }
          }
          return _json(await _collection(await _boGet('/collections/$id') as Map<String, dynamic>));
      }
    }
    if (at(3) == 'book' || at(3) == 'books') {
      if (method == 'POST') {
        final bookId = int.tryParse('${body['id']}');
        if (bookId == null) return _status(400, 'Missing book id');
        await _boPost('/collections/$id/books', {'bookIds': [bookId]});
      } else if (method == 'DELETE' && n == 5) {
        final bookId = int.tryParse(at(4));
        if (bookId == null) return _status(400, 'Bad book id');
        await _boDelete('/collections/$id/books', body: {'bookIds': [bookId]});
      } else {
        return null;
      }
      return _json(await _collection(await _boGet('/collections/$id') as Map<String, dynamic>));
    }
    return null;
  }

  /// With [coverSlot] the URL shows that slot only (no fallback to the other
  /// one), which is what the cover editor wants.
  @override
  String getCoverUrl(String itemId, {int? width = 400, int? updatedAt, String? coverSlot}) {
    final kind = coverSlot == null && width != null && width <= 400 ? 'thumbnail' : 'cover';
    final cv = _coverVersions[_key(itemId)];
    final t = cv == null ? '' : '&t=${Uri.encodeQueryComponent(cv)}';
    final slot = coverSlot == null ? _listCoverSlot(itemId) : '$coverSlot&strict=true';
    return BookOrbitMediaProxy.instance.urlFor('/api/v1/books/$itemId/$kind?medium=$slot$t');
  }

  @override
  Future<int?> comicPageCount(String fileId) async {
    try {
      final r = await _boGet('/cbz/files/$fileId/pages') as Map<String, dynamic>;
      return (r['pageCount'] as num?)?.toInt();
    } catch (e) {
      debugPrint('[BookOrbit] comic page count for file $fileId: $e');
      return null;
    }
  }

  @override
  String? comicPageUrl(String fileId, int index) =>
      BookOrbitMediaProxy.instance.urlFor('/api/v1/cbz/files/$fileId/pages/$index');

  @override
  Future<List<String>> coverSlots(String itemId) async {
    try {
      final d = await _detail(itemId);
      return (d['coverMedia'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .where((e) => e == 'audio' || e == 'ebook')
          .toList();
    } catch (e) {
      debugPrint('[BookOrbit] cover slots for $itemId: $e');
      return const [];
    }
  }

  @override
  Future<String?> defaultCoverSearchProvider() async {
    try {
      final p = await _boGet('/user-preferences/cover-search') as Map<String, dynamic>;
      return ((p['settings'] as Map?)?['defaultProvider'] ?? p['defaultProvider']) as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  String getAuthorImageUrl(String authorId, {int width = 200, int? updatedAt}) {
    final id = int.tryParse(authorId) ?? 0;
    final kind = width <= 400 ? 'thumbnail' : 'image';
    final t = updatedAt == null ? '' : '?t=$updatedAt';
    return BookOrbitMediaProxy.instance.urlFor('/api/v1/authors/$id/$kind$t');
  }

  /// The cover slot an edit goes to: the audiobook's when there is audio,
  /// since that is the one the app shows.
  Future<String> _coverMedium(String bookId) async =>
      _detailHasAudio(await _detail(bookId)) ? 'audio' : 'ebook';

  /// Re-read a book after an edit and tell open views about it the way the
  /// Audiobookshelf socket would.
  Future<Map<String, dynamic>> _afterEdit(String bookId, {bool chaptersChanged = false}) async {
    final k = _key(bookId);
    if (chaptersChanged) {
      _manifests.remove(k);
      _manifestAt.remove(k);
    }
    _recent.removeWhere((key, _) => key.startsWith('personalized:'));
    final detail = await _detail(bookId, fresh: true);
    final manifest = _detailHasAudio(detail) ? await _manifest(bookId) : null;
    final item = BookOrbitMapper.item(detail: detail, manifest: manifest);
    SocketService().emitLocalItemUpdated(item);
    return item;
  }

  Future<Map<String, dynamic>> _updateMedia(String bookId, Map<String, dynamic> body) async {
    final detail = await _detail(bookId, fresh: true);
    final current = BookOrbitMapper.item(detail: detail)['media'] as Map<String, dynamic>;
    final changes = BookOrbitMapper.metadataPatch(
      metadata: (body['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      tags: (body['tags'] as List<dynamic>?)?.map((e) => '$e').toList(),
      current: current,
      hasAudio: _detailHasAudio(detail),
    );
    if (changes.isEmpty) return {'updated': false, 'libraryItem': await _afterEdit(bookId)};
    await _boPatch('/books/$bookId/metadata', changes);
    return {'updated': true, 'libraryItem': await _afterEdit(bookId)};
  }

  /// Covers picked from a search come back through the proxy; BookOrbit
  /// wants the original address.
  String _upstreamImageUrl(String url) {
    final picked = _coverPicks[url];
    if (picked != null) return picked;
    if (!BookOrbitMediaProxy.instance.owns(url)) return url;
    final uri = Uri.parse(url);
    return uri.path.endsWith('/books/cover/proxy') ? (uri.queryParameters['url'] ?? url) : url;
  }

  Future<http.Response> _coverFromUrl(String bookId, String url, {String? slot}) async {
    if (url.isEmpty) return _status(400, 'No cover URL');
    await _boPost(
      '/books/$bookId/cover/from-url?medium=${slot ?? await _coverMedium(bookId)}',
      {'url': _upstreamImageUrl(url)},
      const Duration(seconds: 45),
    );
    await _afterEdit(bookId);
    return _json({'success': true});
  }

  @override
  Future<bool> updateItemCoverUrl(String itemId, String url, {String? coverSlot}) async {
    try {
      return (await _coverFromUrl(itemId, url, slot: coverSlot)).statusCode == 200;
    } catch (e) {
      debugPrint('[BookOrbit] updateItemCoverUrl error: $e');
      return false;
    }
  }

  @override
  Future<bool> removeItemCover(String itemId, {String? coverSlot}) async {
    try {
      await _boDelete('/books/$itemId/cover?medium=${coverSlot ?? await _coverMedium(itemId)}');
      await _afterEdit(itemId);
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] removeItemCover error: $e');
      return false;
    }
  }

  @override
  Future<bool> uploadItemCover(String itemId, String filePath, {String? coverSlot}) async {
    try {
      final bytes = await (await http.MultipartFile.fromPath('file', filePath)).finalize().toBytes();
      await _boMultipart(
        '/books/$itemId/cover?medium=${coverSlot ?? await _coverMedium(itemId)}',
        bytes,
        filename: filePath.split(RegExp(r'[\\/]')).last,
        contentType: _imageType(filePath, null),
      );
      await _afterEdit(itemId);
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] uploadItemCover error: $e');
      return false;
    }
  }

  static String _imageType(String name, String? header) {
    final h = header?.split(';').first.trim().toLowerCase();
    if (h != null && h.startsWith('image/')) return h;
    final ext = name.toLowerCase().split('?').first.split('.').last;
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'avif' => 'image/avif',
      _ => 'image/jpeg',
    };
  }

  /// POST one image as multipart. The body is built here because the http
  /// package can't label a part's type without another dependency, and
  /// BookOrbit turns away anything not marked image/*.
  Future<dynamic> _boMultipart(String path, List<int> bytes,
      {required String filename, required String contentType}) async {
    await _ensureFreshAccessToken();
    final boundary = 'absorb${DateTime.now().microsecondsSinceEpoch}';
    final safeName = filename.replaceAll('"', '');
    final body = <int>[
      ...utf8.encode('--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; filename="$safeName"\r\n'
          'Content-Type: $contentType\r\n\r\n'),
      ...bytes,
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ];
    Future<http.Response> send() async {
      final req = http.Request('POST', _boUri(path))
        ..headers.addAll(_headers)
        ..headers['Content-Type'] = 'multipart/form-data; boundary=$boundary'
        ..bodyBytes = body;
      final client = _httpClient ?? http.Client();
      try {
        final streamed = await client.send(req).timeout(const Duration(seconds: 60));
        return await http.Response.fromStream(streamed).timeout(const Duration(seconds: 60));
      } finally {
        if (_httpClient == null) client.close();
      }
    }

    var r = await send();
    if (r.statusCode == 401) {
      final outcome = await _refreshAccessToken();
      if (outcome == _RefreshOutcome.refreshed) r = await send();
      if (outcome == _RefreshOutcome.rejected) onAuthExpired?.call();
    }
    return _decode(r);
  }

  /// BookOrbit's own one-tap match: it searches with what the book already
  /// has and fills fields by the server's metadata rules, so the title,
  /// author and provider the app sends have nothing to steer.
  Future<Map<String, dynamic>> _quickMatch(String bookId) async {
    String fingerprint(Map<String, dynamic> d) => jsonEncode([
          BookOrbitMapper.item(detail: d)['media'],
          d['coverVersion'],
        ]);
    final before = fingerprint(await _detail(bookId, fresh: true));
    await _boPost('/books/$bookId/refresh-metadata', null, const Duration(seconds: 120));
    final item = await _afterEdit(bookId, chaptersChanged: true);
    final after = fingerprint(_details[_key(bookId)]!);
    return {'updated': before != after, 'libraryItem': item};
  }

  Future<http.Response> _deleteBooks(List<String> ids, {required bool hard}) async {
    // BookOrbit has no way to drop a book and keep its files.
    if (!hard) return _status(400, 'BookOrbit always deletes the files');
    final bookIds = ids.map(int.tryParse).whereType<int>().toList();
    if (bookIds.isEmpty || bookIds.length != ids.length) return _status(404, 'Book not found');
    await _boDelete('/books', body: {'bookIds': bookIds});
    for (final id in ids) {
      final k = _key(id);
      _details.remove(k);
      _detailAt.remove(k);
      _manifests.remove(k);
      _manifestAt.remove(k);
      SocketService().emitLocalItemRemoved({'id': id});
    }
    _recent.removeWhere((key, _) => key.startsWith('personalized:'));
    return _json({'success': true});
  }

  /// Sends only what changed: a new name makes BookOrbit look the author up
  /// again in the background.
  Future<Map<String, dynamic>> _updateAuthor(String authorId, Map<String, dynamic> body) async {
    final current = await _boGet('/authors/$authorId') as Map<String, dynamic>;
    final changes = <String, dynamic>{};
    final name = '${body['name'] ?? ''}'.trim();
    if (name.isNotEmpty && name != current['name']) {
      changes['name'] = name.length > 500 ? name.substring(0, 500) : name;
    }
    if (body.containsKey('description')) {
      final d = '${body['description'] ?? ''}'.trim();
      final next = d.isEmpty ? null : (d.length > 10000 ? d.substring(0, 10000) : d);
      if (next != current['description']) changes['description'] = next;
    }
    final res = changes.isEmpty ? current : await _boPatch('/authors/$authorId', changes);
    return {'author': BookOrbitMapper.author(res as Map<String, dynamic>)};
  }

  /// BookOrbit only takes an uploaded author image, so fetch it here first.
  Future<http.Response> _authorImageFromUrl(String authorId, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return _status(400, 'Not an image URL');
    }
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    final type = res.headers['content-type'];
    if (res.statusCode != 200 || res.bodyBytes.isEmpty || (type != null && !type.startsWith('image/'))) {
      return _status(400, 'Could not download the image');
    }
    await _boMultipart(
      '/authors/$authorId/image',
      res.bodyBytes,
      filename: uri.pathSegments.isEmpty ? 'author.jpg' : uri.pathSegments.last,
      contentType: _imageType(uri.path, type),
    );
    return _json({'success': true});
  }

  /// Like Quick Match for books: the server looks the author up with its
  /// own provider settings.
  Future<Map<String, dynamic>> _matchAuthor(String authorId) async {
    final before = await _boGet('/authors/$authorId') as Map<String, dynamic>;
    final after = await _boPost('/authors/$authorId/enrichment/refresh', null, const Duration(seconds: 60))
        as Map<String, dynamic>;
    String key(Map<String, dynamic> a) => jsonEncode([a['name'], a['description'], a['imageUrl']]);
    return {'updated': key(before) != key(after), 'author': BookOrbitMapper.author(after)};
  }

  static const _coverProviders = {
    'audiobookcovers': 'audiobookcovers',
    'itunes': 'itunes',
    'duckduckgo': 'duckduckgo',
    'google': 'duckduckgo',
    'all': 'all',
  };

  Future<List<String>> _searchCovers(Map<String, String> q) => _searchCoverUrls(
        title: q['title'] ?? '',
        author: q['author'],
        provider: q['provider'] ?? 'all',
        audiobook: q['isAudiobook'] != 'false',
      );

  @override
  Future<List<String>> searchCovers(String title,
      {String? author, String provider = 'google', String? coverSlot}) async {
    try {
      return await _searchCoverUrls(
        title: title,
        author: author,
        provider: provider,
        audiobook: coverSlot != 'ebook',
      );
    } catch (e) {
      debugPrint('[BookOrbit] cover search failed: $e');
      return const [];
    }
  }

  /// Display URL of a cover search result -> the full-size image to set.
  static final Map<String, String> _coverPicks = {};

  /// Cover search the way BookOrbit's web editor does it: [audiobook] says
  /// which slot it is for, which changes what each source looks for, and
  /// results show through BookOrbit's image proxy like on the web.
  Future<List<String>> _searchCoverUrls({
    required String title,
    String? author,
    required String provider,
    required bool audiobook,
  }) async {
    final source = _coverProviders[provider];
    final t = title.trim();
    if (source == null || t.isEmpty || (source == 'audiobookcovers' && !audiobook)) return const [];
    final a = (author ?? '').trim();
    final res = await _boGet('/books/cover/search', {
      'title': t,
      if (a.isNotEmpty) 'author': a,
      'isAudiobook': '$audiobook',
      'provider': source,
    }, const Duration(seconds: 30));
    if (_coverPicks.length > 500) _coverPicks.clear();
    final urls = <String>[];
    for (final r in (res as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
      final full = '${r['url'] ?? ''}';
      final preview = r['previewUrl'];
      if (preview is String && preview.startsWith('/')) {
        final shown = BookOrbitMediaProxy.instance.urlFor(preview);
        if (full.startsWith('http')) _coverPicks[shown] = full;
        urls.add(shown);
      } else if (full.startsWith('http')) {
        urls.add(full);
      }
    }
    return urls;
  }

  /// Audiobookshelf finds a book's Audible match through its own server.
  /// BookOrbit only searches Audible when its admin turned that provider on,
  /// so ask Audible's catalog directly, as the rating lookup by ASIN does.
  @override
  Future<Map<String, dynamic>?> searchAudibleRating(String title, String? author) async {
    final wanted = _plainTitle(title);
    if (wanted.isEmpty) return null;
    final firstAuthor = (author ?? '').split(',').first.trim();
    try {
      final uri = Uri.parse('https://api.audible${ApiService._audibleTld}/1.0/catalog/products').replace(
        queryParameters: {
          'title': title.trim(),
          if (firstAuthor.isNotEmpty) 'author': firstAuthor,
          'num_results': '5',
          'products_sort_by': 'Relevance',
          'response_groups': 'product_desc,rating',
        },
      );
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final products = ((jsonDecode(r.body) as Map<String, dynamic>)['products'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      for (final p in products) {
        final asin = p['asin'] as String?;
        final found = _plainTitle('${p['title'] ?? ''}');
        // Same book, not just a good keyword hit.
        if (asin == null || found.isEmpty || !(found.contains(wanted) || wanted.contains(found))) continue;
        final overall = (p['rating'] as Map?)?['overall_distribution'] as Map?;
        final score = (overall?['average_rating'] as num?)?.toDouble();
        if (score == null || !score.isFinite || score <= 0 || score > 5) continue;
        final count = (overall?['num_ratings'] as num?)?.toInt();
        return {'rating': score, 'count': count != null && count >= 0 ? count : null, 'asin': asin};
      }
    } catch (e) {
      debugPrint('[BookOrbit] Audible rating search failed: $e');
    }
    return null;
  }

  static String _plainTitle(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();

  @override
  Future<List<Map<String, dynamic>>> getSimilarBooks(String itemId) async {
    try {
      final res = await _boGet('/books/$itemId/recommendations') as List<dynamic>;
      return res.whereType<Map<String, dynamic>>().map(BookOrbitMapper.similarBook).toList();
    } catch (e) {
      debugPrint('[BookOrbit] No similar books for $itemId: $e');
      return const [];
    }
  }

  @override
  Future<bool> setReadStatus(String itemId, String status) async {
    try {
      await _boPatch('/books/$itemId/status', {'status': status});
      _details.remove(_key(itemId));
      _detailAt.remove(_key(itemId));
      _recent.removeWhere((key, _) => key == 'progress' || key.startsWith('personalized:'));
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] setReadStatus error: $e');
      return false;
    }
  }

  @override
  Future<bool> setPersonalNote(String itemId, String? note) async {
    final text = note?.trim();
    try {
      final d = await _boPatch('/books/$itemId/personal-note', {
        'note': text == null || text.isEmpty ? null : (text.length > 10000 ? text.substring(0, 10000) : text),
      }) as Map<String, dynamic>;
      _details[_key(itemId)] = d;
      _detailAt[_key(itemId)] = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] setPersonalNote error: $e');
      return false;
    }
  }

  @override
  Future<List<Map<String, String>>?> bookMatchProviders() async {
    try {
      final res = await _boGet('/metadata-fetch/providers') as List<dynamic>;
      return [
        for (final p in res.whereType<Map<String, dynamic>>())
          if (p['key'] is String) {'key': p['key'] as String, 'label': '${p['label'] ?? p['key']}'},
      ];
    } catch (e) {
      debugPrint('[BookOrbit] provider list failed: $e');
      return null;
    }
  }

  /// The app's provider names that BookOrbit spells differently. Anything
  /// else is passed through, since the list mostly comes from the server.
  static const _bookProviders = {'openlibrary': 'openLibrary'};

  /// Provider search, which BookOrbit streams back as server-sent events,
  /// one candidate per event.
  Future<List<Map<String, dynamic>>> _searchBooks(Map<String, String> q) async {
    final asked = (q['provider'] ?? '').trim();
    final provider = _bookProviders[asked] ?? asked;
    final title = (q['title'] ?? '').trim();
    final author = (q['author'] ?? '').trim();
    if (provider.isEmpty || (title.isEmpty && author.isEmpty)) return const [];
    final r = await super._authGet(
      _boUri('/metadata-fetch/stream', {
        if (title.isNotEmpty) 'title': title.length > 500 ? title.substring(0, 500) : title,
        if (author.isNotEmpty) 'author': author.length > 255 ? author.substring(0, 255) : author,
        'providers': provider,
      }),
      timeout: const Duration(seconds: 60),
    );
    if (r.statusCode != 200) throw _BoHttpError(r.statusCode, r.body);
    final out = <Map<String, dynamic>>[];
    for (final block in utf8.decode(r.bodyBytes).split(RegExp(r'\r?\n\r?\n'))) {
      final lines = block.split(RegExp(r'\r?\n'));
      if (lines.any((l) => l.startsWith('event:'))) continue;
      final data = lines.where((l) => l.startsWith('data:')).map((l) => l.substring(5).trim()).join('\n');
      if (data.isEmpty) continue;
      try {
        final c = jsonDecode(data);
        if (c is Map<String, dynamic>) out.add(BookOrbitMapper.searchResult(c));
      } catch (_) {}
    }
    return out;
  }

  /// Chapter lookup by ASIN. BookOrbit only fetches chapters for an ASIN a
  /// book already has stored, so this asks Audnexus directly, the same
  /// source Audiobookshelf's lookup reads.
  Future<Map<String, dynamic>> _searchChapters(String asin, String region) async {
    const notFound = {'error': 'Chapters not found', 'stringKey': 'MessageChaptersNotFound'};
    final id = asin.trim();
    if (!RegExp(r'^[A-Za-z0-9]{10}$').hasMatch(id)) return notFound;
    final uri = Uri.https('api.audnex.us', '/books/$id/chapters', {'region': region.toLowerCase()});
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return notFound;
      final data = jsonDecode(r.body);
      return data is Map<String, dynamic> && data['chapters'] is List ? data : notFound;
    } catch (e) {
      debugPrint('[BookOrbit] chapter lookup failed: $e');
      return notFound;
    }
  }

  /// Audiobookshelf-shaped content URLs (`/api/items/<book>/file/<file>`)
  /// become proxied BookOrbit asset streams.
  @override
  String buildTrackUrl(String contentUrl, {String? sessionId, int? trackIndex, int? playMethod}) {
    final uri = Uri.parse(contentUrl);
    if (BookOrbitMediaProxy.instance.owns(contentUrl)) return contentUrl;
    final seg = uri.pathSegments;
    final i = seg.indexOf('items');
    if (i >= 0 && i + 3 < seg.length && seg[i + 2] == 'file') {
      final bookId = seg[i + 1];
      final fileId = seg[i + 3];
      final asset = uri.queryParameters['asset'] ?? _assetByFile[_key(fileId)];
      if (asset != null) {
        return BookOrbitMediaProxy.instance.urlFor('/api/v1/audiobooks/$bookId/assets/$asset/content');
      }
      return BookOrbitMediaProxy.instance.urlFor('/api/v1/books/files/$fileId/download');
    }
    if (uri.path.contains('/api/v1/')) {
      final at = uri.path.indexOf('/api/v1/');
      return BookOrbitMediaProxy.instance.urlFor(uri.path.substring(at) + (uri.hasQuery ? '?${uri.query}' : ''));
    }
    return contentUrl;
  }

  @override
  String buildDownloadFileUrl(String itemId, String ino) {
    final ticket = _tickets[_key(itemId)];
    if (ticket != null &&
        ticket.fileIds.contains(ino) &&
        ticket.expiresAt.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
      return '$_v1/watch-downloads/files/$ino';
    }
    return buildFileUrl(itemId, ino);
  }

  @override
  String buildFileUrl(String itemId, String ino) {
    final asset = _assetByFile[_key(ino)];
    if (asset != null) {
      return BookOrbitMediaProxy.instance.urlFor('/api/v1/audiobooks/$itemId/assets/$asset/content');
    }
    return BookOrbitMediaProxy.instance.urlFor('/api/v1/books/files/$ino/serve');
  }

  @override
  String buildEbookUrl(String itemId, String ino) =>
      BookOrbitMediaProxy.instance.urlFor('/api/v1/books/files/$ino/serve');

  @override
  Map<String, String> downloadHeadersFor(String url) {
    if (url.startsWith('$_v1/watch-downloads/files/')) {
      final fileId = Uri.parse(url).pathSegments.last;
      for (final t in _tickets.values) {
        if (t.fileIds.contains(fileId)) {
          return {...customHeaders, 'Authorization': 'Bearer ${t.token}'};
        }
      }
    }
    return mediaHeaders;
  }

  /// Background downloads outlive a fifteen-minute access token, so ask the
  /// server for a download ticket (good for twelve hours) covering the
  /// book's audio files. Without one the files go through the in-app proxy.
  @override
  Future<void> prepareDownload(String itemId) async {
    await ensureMediaReady();
    final manifest = await _manifest(itemId, fresh: true);
    final fileIds = (manifest?['assets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((a) => a['fileId'])
        .whereType<int>()
        .toList();
    if (fileIds.isEmpty) return;
    try {
      final res = await _boPost('/watch-downloads', {
        'bookId': int.parse(itemId),
        'fileIds': fileIds.take(256).toList(),
      }) as Map<String, dynamic>;
      final token = res['token'] as String?;
      final expires = DateTime.tryParse(res['expiresAt'] as String? ?? '');
      if (token != null && expires != null) {
        _tickets[_key(itemId)] = _BoTicket(token, expires, fileIds.map((e) => '$e').toSet());
      }
    } catch (e) {
      debugPrint('[BookOrbit] No download ticket for $itemId ($e) - using the proxy');
    }
  }

  Future<Map<String, dynamic>?> _playbackState(String bookId) async {
    try {
      final state = await _boGet('/audiobooks/$bookId/playback-state');
      if (state is Map<String, dynamic>) {
        final rev = (state['revision'] as num?)?.toInt();
        if (rev != null) _revisions[_key(bookId)] = rev;
        return state;
      }
      _revisions[_key(bookId)] = 0;
      return null;
    } on _BoHttpError catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  ({String? cfi, double? percent, int? updated, int? fileId}) _ebookFrom(
      Map<String, dynamic> detail, List<dynamic> fileProgress) {
    final item = BookOrbitMapper.item(detail: detail);
    final ebook = (item['media'] as Map)['ebookFile'] as Map?;
    final fileId = int.tryParse('${ebook?['ino']}');
    if (fileId == null) return (cfi: null, percent: null, updated: null, fileId: null);
    for (final p in fileProgress.whereType<Map<String, dynamic>>()) {
      if (p['fileId'] == fileId) {
        final pct = (p['percentage'] as num?)?.toDouble();
        final cfi = p['cfi'] as String? ?? (p['pageNumber'] != null ? '${p['pageNumber']}' : null);
        if ((pct == null || pct == 0) && cfi == null) break;
        return (cfi: cfi, percent: pct, updated: BookOrbitMapper.ms(p['updatedAt']), fileId: fileId);
      }
    }
    return (cfi: null, percent: null, updated: null, fileId: fileId);
  }

  Future<Map<String, dynamic>?> _itemProgress(
    String bookId, {
    Map<String, dynamic>? detail,
    Map<String, dynamic>? manifest,
  }) async {
    detail ??= await _detail(bookId);
    final hasAudio = _detailHasAudio(detail);
    manifest ??= hasAudio ? await _manifest(bookId) : null;
    final state = manifest != null ? await _playbackState(bookId) : null;
    ({String? cfi, double? percent, int? updated, int? fileId}) ebook =
        (cfi: null, percent: null, updated: null, fileId: null);
    if ((BookOrbitMapper.item(detail: detail)['media'] as Map)['ebookFile'] != null) {
      try {
        final fp = await _boGet('/books/$bookId/progress') as List<dynamic>;
        ebook = _ebookFrom(detail, fp);
      } catch (_) {}
    }
    final readStatus = detail['readStatus'] as Map<String, dynamic>?;
    if (state == null && ebook.percent == null && readStatus == null) return null;
    final p = BookOrbitMapper.progress(
      bookId: bookId,
      manifest: manifest,
      state: state,
      readStatus: readStatus,
      ebookPercent: ebook.percent,
      ebookLocation: ebook.cfi,
      ebookUpdatedAt: ebook.updated,
    );
    if (!hasAudio && ebook.percent != null) p['progress'] = (ebook.percent! / 100).clamp(0.0, 1.0);
    return p;
  }

  Future<List<Map<String, dynamic>>> _allProgress() async {
    final byId = <String, Map<String, dynamic>>{};
    Future<void> collect(List<String> statuses, String sortField, int maxPages) async {
      for (var page = 0; page < maxPages; page++) {
        final res = await _boPost('/books/query', {
          'filter': {
            'type': 'group',
            'join': 'AND',
            'rules': [_rule('readStatus', 'includesAny', statuses)],
          },
          'sort': [{'field': sortField, 'dir': 'desc'}],
          'pagination': {'page': page, 'size': 200},
        }) as Map<String, dynamic>;
        final items = (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
        for (final c in items) {
          _cardItem(c);
          byId['${c['id']}'] = BookOrbitMapper.cardProgress(c);
        }
        final total = (res['total'] as num?)?.toInt() ?? 0;
        if (items.length < 200 || (page + 1) * 200 >= total) break;
      }
    }

    await collect(['reading', 'rereading', 'on_hold'], 'startedAt', 5);
    await collect(['read', 'skimmed'], 'finishedAt', 2);
    // Real positions for what is being listened to right now, so another
    // device's place carries over.
    try {
      final listening = (await _shelfCards('continue-listening', 12)).map((c) => '${c['id']}').toList();
      final real = await _pool(listening.map((id) => () async {
            try {
              final manifest = await _manifest(id);
              if (manifest == null) return null;
              final state = await _playbackState(id);
              if (state == null) return null;
              final card = byId[id];
              return BookOrbitMapper.progress(
                bookId: id,
                manifest: manifest,
                state: state,
                readStatus: card == null ? null : {'status': card['isFinished'] == true ? 'read' : 'reading', 'updatedAt': null},
              );
            } catch (_) {
              return null;
            }
          }).toList());
      for (final p in real.whereType<Map<String, dynamic>>()) {
        byId['${p['libraryItemId']}'] = p;
      }
    } catch (e) {
      debugPrint('[BookOrbit] Continue-listening positions failed: $e');
    }
    return byId.values.toList();
  }

  /// Save a book-absolute position. Returns the HTTP status that best
  /// describes the outcome for Audiobookshelf callers.
  Future<int> _putPosition(String bookId, double absoluteSeconds, {DateTime? capturedAt}) async {
    var manifest = await _manifest(bookId);
    if (manifest == null) return 404;
    final when = (capturedAt ?? DateTime.now()).toUtc();
    final operationId = _uuid();
    for (var attempt = 0; attempt < 3; attempt++) {
      final pos = BookOrbitMapper.trackPosition(manifest!, absoluteSeconds);
      if (pos == null) return 404;
      var base = _revisions[_key(bookId)];
      if (base == null) {
        final state = await _playbackState(bookId);
        final serverAt = DateTime.tryParse(state?['capturedAt'] as String? ?? '');
        if (serverAt != null && serverAt.isAfter(when)) return 200;
        base = _revisions[_key(bookId)] ?? 0;
      }
      try {
        final saved = await _boPut('/audiobooks/$bookId/playback-state', {
          'assetId': pos.assetId,
          'positionMs': pos.positionMs,
          'capturedAt': _iso(when),
          'operationId': operationId,
          'baseRevision': base,
          'manifestRevision': manifest['revision'],
        }) as Map<String, dynamic>;
        final rev = (saved['revision'] as num?)?.toInt();
        if (rev != null) _revisions[_key(bookId)] = rev;
        return 200;
      } on _BoHttpError catch (e) {
        if (e.status == 409) {
          _revisions.remove(_key(bookId));
          final state = await _playbackState(bookId);
          final serverAt = DateTime.tryParse(state?['capturedAt'] as String? ?? '');
          if (serverAt != null && !serverAt.isBefore(when)) return 200;
          continue;
        }
        if (e.status == 412) {
          manifest = await _manifest(bookId, fresh: true);
          if (manifest == null) return 404;
          continue;
        }
        debugPrint('[BookOrbit] Position for $bookId not saved: ${e.status} ${e.message}');
        return e.status;
      }
    }
    return 409;
  }

  Future<void> _setStatus(String bookId, Map<String, dynamic> body) async {
    await _boPatch('/books/$bookId/status', body);
    _detailAt.remove(_key(bookId));
  }

  static String? _dateParam(Object? ms) {
    if (ms is! num || ms <= 0) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    final now = DateTime.now();
    return _iso(d.isAfter(now) ? now : d);
  }

  Future<void> _patchProgress(String bookId, Map<String, dynamic> body) async {
    if (bookId.length > 36) return;
    final isFinished = body['isFinished'];
    if (isFinished == true) {
      // List items carry no duration here, so the caller's end-of-book
      // position can be 0. The end comes from the track list instead.
      final manifest = await _manifest(bookId);
      if (manifest != null) {
        final status = await _putPosition(bookId, BookOrbitMapper.totalSeconds(manifest));
        if (status >= 500) throw _BoHttpError(status, 'Position not saved');
      }
    } else if (body['currentTime'] is num && isFinished == null) {
      final status = await _putPosition(bookId, (body['currentTime'] as num).toDouble());
      if (status >= 500) throw _BoHttpError(status, 'Position not saved');
    }
    if (body.containsKey('ebookLocation') || body.containsKey('ebookProgress')) {
      await _saveEbookProgress(bookId, body['ebookLocation'] as String?, (body['ebookProgress'] as num?)?.toDouble());
    }
    if (isFinished == true) {
      await _setStatus(bookId, {
        'status': 'read',
        if (_dateParam(body['finishedAt']) != null) 'finishedAt': _dateParam(body['finishedAt']),
      });
    } else if (isFinished == false) {
      // Audiobookshelf clears the position when a book is un-finished.
      await _clearPosition(bookId);
      await _unfinish(bookId);
    } else if (body['finishedAt'] != null) {
      final d = _dateParam(body['finishedAt']);
      if (d != null) await _setStatus(bookId, {'finishedAt': d});
    }
    final started = _dateParam(body['startedAt'] ?? body['createdAt']);
    if (started != null && isFinished == null && body['currentTime'] == null) {
      await _setStatus(bookId, {'startedAt': started});
    }
  }

  Future<void> _saveEbookProgress(String bookId, String? location, double? progress) async {
    final detail = await _detail(bookId);
    final ebook = (BookOrbitMapper.item(detail: detail)['media'] as Map)['ebookFile'] as Map?;
    final fileId = ebook?['ino'];
    if (fileId == null) return;
    final pct = ((progress ?? 0) * 100).clamp(0.0, 100.0);
    final page = location == null ? null : int.tryParse(location);
    await _boPost('/books/files/$fileId/progress', {
      'percentage': pct,
      if (location != null && page == null) 'cfi': location,
      if (page != null) 'pageNumber': page,
    });
    if (progress != null && progress >= 1.0) {
      await _setStatus(bookId, {'status': 'read'});
    }
  }

  Future<void> _clearPosition(String bookId) async {
    try {
      await _boDelete('/audiobooks/$bookId/playback-state');
    } on _BoHttpError catch (e) {
      if (e.status != 404) rethrow;
    }
    _revisions[_key(bookId)] = 0;
  }

  /// Take a finished book back to reading. Any status set from here is a
  /// manual one, which BookOrbit never updates on its own again, so nothing
  /// is written unless the book is actually marked finished.
  Future<void> _unfinish(String bookId) async {
    final status = ((await _detail(bookId, fresh: true))['readStatus'] as Map?)?['status'];
    if (status == 'read' || status == 'skimmed') {
      await _setStatus(bookId, {'status': 'reading'});
    }
  }

  Future<void> _deleteProgress(String progressId) async {
    final bookId = progressId.startsWith('bo-') ? progressId.substring(3) : progressId;
    await _clearPosition(bookId);
    await _unfinish(bookId);
  }

  @override
  Future<bool> updateEbookProgress(String itemId, {required String ebookLocation, required double ebookProgress}) async {
    try {
      await _saveEbookProgress(itemId, ebookLocation, ebookProgress);
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] updateEbookProgress error: $e');
      return false;
    }
  }

  @override
  Future<bool> setCollectionPublic(String collectionId, bool isPublic) async {
    try {
      await _boPatch('/collections/$collectionId', {'isPublic': isPublic});
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] setCollectionPublic error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateLibraryItemsFinished(List<String> itemIds, {required bool isFinished}) async {
    if (itemIds.isEmpty) return false;
    try {
      await _pool(itemIds.map((id) => () => _patchProgress(id, {'isFinished': isFinished})).toList(), width: 4);
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] updateLibraryItemsFinished error: $e');
      return false;
    }
  }

  @override
  Future<bool> resetProgress(String itemId, double duration, {String? progressId}) async {
    try {
      await _deleteProgress(itemId);
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] resetProgress error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateProgressStartDate(String itemId, int startedAt) async {
    try {
      final d = _dateParam(startedAt);
      if (d == null) return false;
      await _setStatus(itemId, {'startedAt': d});
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] updateProgressStartDate error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateProgressFinishedDate(String itemId, int finishedAt) async {
    try {
      final d = _dateParam(finishedAt);
      if (d == null) return false;
      await _setStatus(itemId, {'status': 'read', 'finishedAt': d});
      return true;
    } catch (e) {
      debugPrint('[BookOrbit] updateProgressFinishedDate error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _startSession(String bookId, Map<String, dynamic> body) async {
    final detail = await _detail(bookId, fresh: true);
    final manifest = await _manifest(bookId, fresh: true);
    if (manifest == null) throw _BoHttpError(404, 'Book has no audiobook assets');
    final state = await _playbackState(bookId);
    final item = BookOrbitMapper.item(detail: detail, manifest: manifest);
    final media = item['media'] as Map<String, dynamic>;
    final metadata = media['metadata'] as Map<String, dynamic>;
    final current = state == null ? 0.0 : BookOrbitMapper.absolutePosition(manifest, state);
    final now = DateTime.now();
    final sessionId = 'bo-$bookId-${now.millisecondsSinceEpoch}';
    final assets = (manifest['assets'] as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    _sessions[sessionId] = _BoListenSession(bookId, _uuid(), now)
      ..fileId = assets.isEmpty ? null : (assets.first['fileId'] as num?)?.toInt()
      ..startPercent = BookOrbitMapper.totalSeconds(manifest) > 0
          ? (current / BookOrbitMapper.totalSeconds(manifest) * 100).clamp(0.0, 100.0)
          : null;
    return {
      'id': sessionId,
      'userId': '',
      'libraryId': item['libraryId'],
      'libraryItemId': bookId,
      'episodeId': null,
      'mediaType': 'book',
      'mediaMetadata': metadata,
      'chapters': media['chapters'],
      'displayTitle': metadata['title'],
      'displayAuthor': metadata['authorName'],
      'coverPath': media['coverPath'],
      'duration': media['duration'],
      'playMethod': 0,
      'mediaPlayer': 'exo-player',
      'deviceInfo': _deviceInfo,
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'timeListening': 0,
      'startTime': current,
      'currentTime': current,
      'startedAt': now.millisecondsSinceEpoch,
      'updatedAt': BookOrbitMapper.ms(state?['capturedAt']) ?? now.millisecondsSinceEpoch,
      'audioTracks': media['tracks'],
      'libraryItem': item,
    };
  }

  _BoListenSession? _sessionFor(String sessionId) {
    final existing = _sessions[sessionId];
    if (existing != null) return existing;
    final m = RegExp(r'^bo-(\d+)-(\d+)$').firstMatch(sessionId);
    if (m == null) return null;
    final started = DateTime.fromMillisecondsSinceEpoch(int.parse(m.group(2)!));
    return _sessions[sessionId] = _BoListenSession(m.group(1)!, _uuid(), started);
  }

  Future<void> _checkpoint(_BoListenSession s, {DateTime? endedAt}) async {
    final seconds = s.listenedSeconds.round();
    if (seconds < 10) return;
    var fileId = s.fileId;
    if (fileId == null) {
      final manifest = await _manifest(s.bookId);
      final assets = (manifest?['assets'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>();
      fileId = assets.isEmpty ? null : (assets.first['fileId'] as num?)?.toInt();
      s.fileId = fileId;
    }
    if (fileId == null) return;
    final end = endedAt ?? DateTime.now();
    final span = end.difference(s.startedAt).inSeconds;
    final source = _platformSource();
    try {
      await _boPost('/books/files/$fileId/sessions', {
        'sessionId': s.sessionUuid,
        'startedAt': _iso(s.startedAt),
        'endedAt': _iso(end),
        'durationSeconds': span < seconds ? math.max(span, 0) : seconds,
        if (s.startPercent != null && s.lastPercent != null)
          'progressDelta': double.parse((s.lastPercent! - s.startPercent!).toStringAsFixed(4)),
        if (s.lastPercent != null) 'endProgress': s.lastPercent!.clamp(0.0, 100.0),
        'sessionType': 'listen',
        if (source != null) 'source': source,
      });
      if (!s.deviceRemembered) {
        s.deviceRemembered = true;
        await _rememberSessionDevice(s.bookId, _iso(s.startedAt));
      }
    } catch (e) {
      debugPrint('[BookOrbit] Listening session checkpoint failed: $e');
    }
  }

  /// BookOrbit keeps a platform tag on each session but no device, so the
  /// sessions this phone recorded are remembered here to name them later.
  static const _sessionDevicesKey = 'bookorbit_session_devices';

  static String _thisDevice() {
    final name = [ApiService.deviceManufacturer, ApiService.deviceModel]
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? 'Absorb' : name;
  }

  Future<void> _rememberSessionDevice(String bookId, String startedAtIso) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionDevicesKey);
      final map = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
      map['$bookId@$startedAtIso'] = _thisDevice();
      while (map.length > 500) {
        map.remove(map.keys.first);
      }
      await prefs.setString(_sessionDevicesKey, jsonEncode(map));
    } catch (_) {}
  }

  static String _sourceLabel(Object? source) => switch (source) {
        'android' => 'Android',
        'ios' => 'iOS',
        'watchos' => 'Apple Watch',
        'web' => 'BookOrbit web',
        'koreader' => 'KOReader',
        'kobo' => 'Kobo',
        'manual' => 'Manual entry',
        _ => 'BookOrbit',
      };

  Future<http.Response> _syncSession(String sessionId, Map<String, dynamic> body) async {
    final s = _sessionFor(sessionId);
    if (s == null) return _status(404, 'Unknown session');
    final currentTime = (body['currentTime'] as num?)?.toDouble();
    final listened = (body['timeListened'] as num?)?.toDouble() ?? 0;
    if (listened > 0) s.listenedSeconds += listened;
    var status = 200;
    if (currentTime != null) {
      status = await _putPosition(s.bookId, currentTime);
      final manifest = _manifests[_key(s.bookId)];
      final total = manifest == null ? 0.0 : BookOrbitMapper.totalSeconds(manifest);
      if (total > 0) {
        s.lastPercent = (currentTime / total * 100).clamp(0.0, 100.0);
        s.startPercent ??= s.lastPercent;
      }
    }
    await _checkpoint(s);
    return status == 200 ? _json(const <String, dynamic>{}) : _status(status, 'Sync failed');
  }

  Future<void> _closeSession(String sessionId, Map<String, dynamic> body) async {
    final s = _sessions.remove(sessionId);
    if (s == null) return;
    final currentTime = (body['currentTime'] as num?)?.toDouble();
    if (currentTime != null) await _putPosition(s.bookId, currentTime);
    await _checkpoint(s);
  }

  /// An offline listen from the app's own session log: the position (only if
  /// nothing newer reached the server since) and the listening time.
  Future<Map<String, dynamic>> _localSession(Map<String, dynamic> session) async {
    final bookId = '${session['libraryItemId'] ?? ''}';
    if (bookId.isEmpty || session['episodeId'] != null) return const {};
    final updated = (session['updatedAt'] as num?)?.toInt();
    final when = updated == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(updated);
    final currentTime = (session['currentTime'] as num?)?.toDouble();
    if (currentTime != null) await _putPosition(bookId, currentTime, capturedAt: when);
    final started = (session['startedAt'] as num?)?.toInt();
    final listened = (session['timeListening'] as num?)?.toDouble() ?? 0;
    if (listened >= 10) {
      final rawId = '${session['id'] ?? _uuid()}';
      final s = _BoListenSession(
        bookId,
        rawId.length > 64 ? rawId.substring(0, 64) : rawId,
        started == null ? when.subtract(Duration(seconds: listened.round())) : DateTime.fromMillisecondsSinceEpoch(started),
      )..listenedSeconds = listened;
      final manifest = _manifests[_key(bookId)] ?? await _manifest(bookId);
      final total = manifest == null ? 0.0 : BookOrbitMapper.totalSeconds(manifest);
      final startTime = (session['startTime'] as num?)?.toDouble();
      if (total > 0 && currentTime != null) s.lastPercent = (currentTime / total * 100).clamp(0.0, 100.0);
      if (total > 0 && startTime != null) s.startPercent = (startTime / total * 100).clamp(0.0, 100.0);
      await _checkpoint(s, endedAt: when);
    }
    return {'id': session['id']};
  }

  @override
  Future<Map<String, dynamic>?> startEpisodePlaybackSession(String itemId, String episodeId,
          {bool forceTranscode = false}) async =>
      null;

  Future<List<Map<String, dynamic>>> _rawBookmarks(String bookId) async {
    try {
      final list = await _boGet('/audiobooks/$bookId/bookmarks') as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().toList();
    } on _BoHttpError catch (e) {
      if (e.status == 404 || e.status == 400) return const [];
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _bookmarksFor(String bookId) async =>
      (await _rawBookmarks(bookId)).map(BookOrbitMapper.bookmark).toList();

  Future<List<Map<String, dynamic>>> _recentBookmarks() async {
    final ids = <String>{};
    try {
      ids.addAll((await _shelfCards('continue-listening', 50)).map((c) => '${c['id']}'));
    } catch (_) {}
    final lists = await _pool(ids.map((id) => () async {
          try {
            return await _bookmarksFor(id);
          } catch (_) {
            return <Map<String, dynamic>>[];
          }
        }).toList());
    return lists.expand((l) => l).toList();
  }

  Future<Map<String, dynamic>> _createBookmark(String bookId, Map<String, dynamic> body) async {
    final time = (body['time'] as num?)?.toDouble() ?? 0;
    final title = '${body['title'] ?? ''}'.trim();
    final created = await _boPost('/audiobooks/$bookId/bookmarks', {
      'clientId': _uuid(),
      'positionMs': (time * 1000).round(),
      'title': title.isEmpty ? 'Bookmark' : (title.length > 500 ? title.substring(0, 500) : title),
    }) as Map<String, dynamic>;
    return BookOrbitMapper.bookmark(created);
  }

  Future<Map<String, dynamic>?> _findBookmark(String bookId, double time) async {
    Map<String, dynamic>? best;
    var bestGap = 1.0;
    for (final b in await _rawBookmarks(bookId)) {
      final gap = (((b['positionMs'] as num?) ?? 0) / 1000.0 - time).abs();
      if (gap < bestGap) {
        best = b;
        bestGap = gap;
      }
    }
    return best;
  }

  Future<bool> _updateBookmark(String bookId, Map<String, dynamic> body) async {
    final b = await _findBookmark(bookId, (body['time'] as num?)?.toDouble() ?? -1);
    if (b == null) return false;
    final title = '${body['title'] ?? ''}'.trim();
    if (title.isEmpty) return true;
    await _boPatch('/audiobooks/$bookId/bookmarks/${b['id']}', {'title': title});
    return true;
  }

  Future<bool> _deleteBookmark(String bookId, double time) async {
    final b = await _findBookmark(bookId, time);
    if (b == null) return false;
    await _boDelete('/audiobooks/$bookId/bookmarks/${b['id']}');
    return true;
  }

  Future<Map<String, dynamic>> _listeningStats() async {
    final overview = await _boGet('/user-statistics/activity-overview', null, const Duration(seconds: 45)) as Map<String, dynamic>;
    final days = <String, num>{};
    void addDays(Object? list) {
      for (final d in (list as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
        final day = d['day'] as String?;
        final secs = (d['listeningSeconds'] as num?) ?? 0;
        if (day != null && secs > 0) days[day] = secs;
      }
    }

    addDays((overview['calendar'] as Map?)?['days']);
    addDays((overview['dailyActivity'] as Map?)?['days']);
    const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayOfWeek = <String, num>{};
    days.forEach((day, secs) {
      final d = DateTime.tryParse(day);
      if (d == null) return;
      final name = names[d.weekday % 7];
      dayOfWeek[name] = (dayOfWeek[name] ?? 0) + secs;
    });
    final today = ((overview['snapshot'] as Map?)?['today'] as Map?)?['listeningSeconds'] as num? ?? 0;
    final items = <String, dynamic>{};
    try {
      final genres = await _boGet('/user-statistics/activity-details/genre-time', null, const Duration(seconds: 45)) as Map<String, dynamic>;
      for (final g in (genres['genres'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
        for (final a in (g['authors'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
          for (final b in (a['books'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
            final id = '${b['bookId']}';
            final prev = (items[id] as Map?)?['timeListening'] as num? ?? 0;
            items[id] = {
              'id': id,
              'timeListening': prev + ((b['totalSeconds'] as num?) ?? 0),
              'mediaMetadata': {'title': b['title'], 'author': a['author']},
            };
          }
        }
      }
    } catch (_) {}
    return {
      'totalTime': days.values.fold<num>(0, (sum, v) => sum + v),
      'items': items,
      'days': days,
      'dayOfWeek': dayOfWeek,
      'today': today,
      'recentSessions': const [],
    };
  }

  Future<Map<String, dynamic>> _itemListeningSessions(String bookId, Map<String, String> q) async {
    final perPage = (int.tryParse(q['itemsPerPage'] ?? '') ?? 100).clamp(1, 100);
    final page = int.tryParse(q['page'] ?? '') ?? 0;
    final res = await _boGet('/books/$bookId/sessions', {
      'page': page + 1,
      'pageSize': perPage,
      'sortBy': 'startedAt',
      'sortDir': 'desc',
    }) as Map<String, dynamic>;
    final total = (res['total'] as num?)?.toInt() ?? 0;
    Map<String, dynamic>? manifest;
    try {
      manifest = await _manifest(bookId);
    } catch (_) {}
    final bookSeconds = manifest == null ? 0.0 : BookOrbitMapper.totalSeconds(manifest);
    // Session rows carry the book's own title and author, as Audiobookshelf's do.
    final book = manifest?['book'] as Map?;
    var title = book?['title'] as String?;
    var author = (book?['authors'] as List<dynamic>?)?.map((a) => '$a').join(', ');
    if (title == null) {
      try {
        final d = await _detail(bookId);
        title = d['title'] as String?;
        author = (d['authors'] as List<dynamic>? ?? const [])
            .map((a) => a is Map ? '${a['name'] ?? ''}' : '$a')
            .where((a) => a.isNotEmpty)
            .join(', ');
      } catch (_) {}
    }
    var mine = <String, dynamic>{};
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_sessionDevicesKey);
      if (raw != null) mine = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
    final sessions = (res['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        // Reading the ebook of the same book is not listening.
        .where((s) => s['format'] == null || BookOrbitMapper.isAudioFormat(s['format'] as String?))
        .map((s) {
      final started = DateTime.tryParse(s['startedAt'] as String? ?? '')?.toLocal();
      final endPct = (s['endProgress'] as num?)?.toDouble();
      final deltaPct = (s['progressDelta'] as num?)?.toDouble();
      final endAt = endPct != null && bookSeconds > 0 ? endPct / 100 * bookSeconds : null;
      final startAt = endAt != null && deltaPct != null
          ? ((endPct! - deltaPct) / 100 * bookSeconds).clamp(0.0, bookSeconds)
          : endAt;
      final ownDevice = mine['$bookId@${s['startedAt']}'] as String?;
      return {
        'id': 'bo-session-${s['id']}',
        'libraryItemId': bookId,
        'episodeId': null,
        'mediaType': 'book',
        'displayTitle': title,
        'displayAuthor': author,
        'mediaMetadata': {'title': title, 'authorName': author},
        if (bookSeconds > 0) 'duration': bookSeconds,
        'timeListening': s['durationSeconds'] ?? 0,
        if (startAt != null) 'startTime': startAt,
        if (endAt != null) 'currentTime': endAt,
        'startedAt': BookOrbitMapper.ms(s['startedAt']),
        'updatedAt': BookOrbitMapper.ms(s['endedAt']),
        'date': started == null
            ? null
            : '${started.year}-${started.month.toString().padLeft(2, '0')}-${started.day.toString().padLeft(2, '0')}',
        'deviceInfo': ownDevice != null
            ? {'clientName': 'Absorb', 'deviceName': ownDevice}
            : {'clientName': _sourceLabel(s['source'])},
        'mediaPlayer': s['source'] ?? 'web',
      };
    }).toList();
    return {
      'sessions': sessions,
      'total': total,
      'numPages': total == 0 ? 1 : (total / perPage).ceil(),
      'page': page,
      'itemsPerPage': perPage,
    };
  }
}
