import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'auth_tokens.dart';
import '../models/auth_session.dart';
import '../utils/server_url.dart';

/// Outcome of a local-session upsert. [serverTooOld] flags a 404/501 (the
/// server predates /api/session/local) so the caller can fall back to the
/// legacy /play flush instead of stranding the session in the replay queue.
class LocalSessionResult {
  final bool ok;
  final bool serverTooOld;
  const LocalSessionResult({required this.ok, required this.serverTooOld});
}

class MediaUploadFile {
  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;
  final Stream<List<int>>? readStream;

  const MediaUploadFile({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
    this.readStream,
  });
}

class MediaUploadRequest {
  final String libraryId;
  final String folderId;
  final String mediaType;
  final String title;
  final String? author;
  final String? series;
  final List<MediaUploadFile> files;

  const MediaUploadRequest({
    required this.libraryId,
    required this.folderId,
    required this.mediaType,
    required this.title,
    this.author,
    this.series,
    required this.files,
  });

  String get directory {
    final parts = mediaType == 'podcast'
        ? <String?>[title]
        : <String?>[author, series, title];
    return parts
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join('/');
  }
}

class UploadPathCheckResult {
  final bool success;
  final bool exists;
  final String? libraryItemTitle;
  final String? error;

  const UploadPathCheckResult({
    required this.success,
    this.exists = false,
    this.libraryItemTitle,
    this.error,
  });
}

class MediaUploadResult {
  final bool success;
  final String? error;

  const MediaUploadResult({required this.success, this.error});
}

class AuthorQuickMatchResult {
  final int statusCode;
  final bool updated;
  final Map<String, dynamic>? author;

  const AuthorQuickMatchResult({
    required this.statusCode,
    this.updated = false,
    this.author,
  });

  bool get found => statusCode == 200;
}

class LibraryMetadataRemovalResult {
  final int found;
  final int removed;

  const LibraryMetadataRemovalResult({
    required this.found,
    required this.removed,
  });
}

enum _RefreshOutcome {
  refreshed,
  rejected,
  transientFailure,
}

enum PasswordChangeStatus {
  success,
  invalidPassword,
  unsupported,
  failed,
}

class PasswordChangeResult {
  final PasswordChangeStatus status;
  final String? message;

  const PasswordChangeResult(this.status, {this.message});
}

class ApiService {
  /// Remove sidecar metadata files from every item in a library (admin only).
  /// [extension] is the server-supported sidecar type: `json` or `abs`.
  Future<LibraryMetadataRemovalResult?> removeLibraryMetadataFiles(
    String libraryId,
    String extension,
  ) async {
    if (extension != 'json' && extension != 'abs') {
      throw ArgumentError.value(extension, 'extension', 'Must be json or abs');
    }
    try {
      final uri = Uri.parse(
        '$_cleanBaseUrl/api/libraries/$libraryId/remove-metadata',
      ).replace(queryParameters: {'ext': extension});
      final r = await _authPost(uri, timeout: const Duration(minutes: 30));
      if (r.statusCode != 200) {
        debugPrint('[API] removeLibraryMetadataFiles failed: ${r.statusCode}');
        return null;
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return LibraryMetadataRemovalResult(
        found: (data['found'] as num?)?.toInt() ?? 0,
        removed: (data['removed'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('[API] removeLibraryMetadataFiles error: $e');
      return null;
    }
  }

  Future<String?> validateCronExpression(String expression) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/validate-cron'),
        body: jsonEncode({'expression': expression}),
      );
      if (r.statusCode == 200) return null;
      final message = r.body.trim();
      return message.isEmpty ? 'Invalid cron expression' : message;
    } catch (e) {
      debugPrint('[API] validateCronExpression error: $e');
      return 'Could not validate the cron expression';
    }
  }

  /// Get the server's current daily log entries (admin only).
  ///
  /// GET /api/logger-data returns `{ currentDailyLogs: [...] }`. A nullable
  /// result distinguishes a request failure from a valid empty log file.
  Future<List<Map<String, dynamic>>?> getServerLogs() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/logger-data'));
      if (r.statusCode != 200) {
        debugPrint('[API] getServerLogs failed: ${r.statusCode}');
        return null;
      }
      final decoded = jsonDecode(r.body);
      if (decoded is! Map) return const <Map<String, dynamic>>[];
      final rawLogs = decoded['currentDailyLogs'];
      if (rawLogs is! List) return const <Map<String, dynamic>>[];
      return rawLogs
          .whereType<Map>()
          .map(
            (log) => log.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('[API] getServerLogs error: $e');
      return null;
    }
  }

  static String appVersion = '1.3.0'; // fallback; overwritten by initVersion()
  static String appBuild = ''; // build number; set by initVersion()

  /// Version plus build (e.g. "1.9.1+198") for logs. `appVersion` stays clean
  /// because it's also sent to the server as clientVersion.
  static String get appVersionFull =>
      appBuild.isEmpty ? appVersion : '$appVersion+$appBuild';

  /// Audible region code derived from device locale.
  static String get _region {
    final locale = PlatformDispatcher.instance.locale;
    final code = (locale.countryCode ?? 'us').toLowerCase();
    return code == 'gb' ? 'uk' : code;
  }

  /// Current Audible region/TLD for default region in series discovery UI.
  static String get debugRegion => _region;
  static String get debugTld => _audibleTld;

  /// Call once at startup to read the real version from pubspec via package_info_plus.
  static Future<void> initVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      appBuild = info.buildNumber;
    } catch (_) {}
  }

  final String baseUrl;
  String _accessToken;
  String? _refreshToken;
  final bool _isLegacyToken;
  final Map<String, String> customHeaders;
  final http.Client? _httpClient;

  /// Called after a successful token refresh so the auth layer can persist.
  /// Returns whether the pair actually reached storage - a rotation that only
  /// lives in memory dies with the process and leaves a spent refresh token
  /// behind, so callers must be able to tell the difference.
  FutureOr<bool> Function(String newAccessToken, String? newRefreshToken)? onTokensRefreshed;

  /// Loads the latest persisted tokens before refreshing. Background isolates
  /// can rotate tokens while this instance is still alive, so the store is the
  /// only source of truth shared by every ApiService holder.
  Future<AuthTokens?> Function()? loadPersistedTokens;

  /// Called when refresh fails and the user must re-login.
  VoidCallback? onAuthExpired;

  final Duration _refreshRetryDelay;

  // Each ApiService instance already deduplicates its own refreshes. This lock
  // also serializes token rotation across the short-lived instances created by
  // providers, widgets, and the background browse service.
  Completer<_RefreshOutcome>? _refreshCompleter;
  static Completer<void>? _tokenMutationCompleter;

  // Device info - set once at app start
  static String deviceManufacturer = '';
  static String deviceModel = '';
  static String deviceId = '';
  static int deviceSdkInt = 0;

  /// Generate or load a persistent unique device ID
  static Future<void> initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('absorb_device_id');
    if (id == null || id.isEmpty) {
      id = 'absorb-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${(DateTime.now().microsecond * 31337).toRadixString(36)}';
      await prefs.setString('absorb_device_id', id);
    }
    deviceId = id;
  }

  ApiService({
    required this.baseUrl,
    required String token,
    String? refreshToken,
    bool isLegacyToken = false,
    this.customHeaders = const {},
    this.onTokensRefreshed,
    this.loadPersistedTokens,
    this.onAuthExpired,
    Duration refreshRetryDelay = const Duration(milliseconds: 250),
    http.Client? httpClient,
  })  : _accessToken = token,
        _refreshToken = refreshToken,
        _isLegacyToken = isLegacyToken,
        _refreshRetryDelay = refreshRetryDelay,
        _httpClient = httpClient {
    _loadCachedServerVersion(baseUrl);
  }

  /// Current access token (for external use like cover URLs, socket auth).
  String get token => _accessToken;

  bool get hasRefreshToken => _refreshToken?.isNotEmpty == true;
  bool get isLegacyToken => _isLegacyToken;

  static String get userAgent => 'Absorb/$appVersionFull';

  Map<String, String> get _headers => {
        ...customHeaders,
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  /// Public headers for image/audio requests (no Content-Type needed).
  Map<String, String> get mediaHeaders => {
        ...customHeaders,
        'Authorization': 'Bearer $_accessToken',
      };

  /// Playback-session tracks use ABS's unguessable public session URLs, so
  /// only reverse-proxy headers belong on the media request. Keeping the
  /// account token off the AVPlayer/ExoPlayer source prevents token rotation
  /// from invalidating a stream that is already playing.
  Map<String, String> get playbackSessionHeaders => {...customHeaders};

  String get _cleanBaseUrl => normalizeServerUrl(baseUrl);

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) {
    return _httpClient?.get(url, headers: headers) ?? http.get(url, headers: headers);
  }

  Future<http.Response> _post(Uri url, {Map<String, String>? headers, Object? body}) {
    return _httpClient?.post(url, headers: headers, body: body) ??
        http.post(url, headers: headers, body: body);
  }

  Future<http.Response> _patch(Uri url, {Map<String, String>? headers, Object? body}) {
    return _httpClient?.patch(url, headers: headers, body: body) ??
        http.patch(url, headers: headers, body: body);
  }

  Future<http.Response> _delete(Uri url, {Map<String, String>? headers}) {
    return _httpClient?.delete(url, headers: headers) ?? http.delete(url, headers: headers);
  }

  /// Loggable token identity: length plus the signature tail, enough to tell
  /// token A from token B across a log without exposing the credential.
  static String tokenFp(String? token) {
    if (token == null || token.isEmpty) return 'none';
    final tail = token.length <= 8 ? token : token.substring(token.length - 8);
    return '${token.length}:$tail';
  }

  Future<bool> _adoptPersistedTokens() async {
    final loader = loadPersistedTokens;
    if (loader == null) return false;

    final previousAccess = _accessToken;
    try {
      final persisted = await loader();
      final persistedAccess = persisted?.accessToken;
      if (persistedAccess == null) return false;
      _accessToken = persistedAccess;
      if (persisted?.refreshToken != null) {
        _refreshToken = persisted!.refreshToken;
      }
      final adopted = _accessToken != previousAccess;
      if (adopted) {
        debugPrint(
          '[API] Adopted persisted tokens: access=${tokenFp(_accessToken)} '
          'refresh=${tokenFp(_refreshToken)}',
        );
        await _notifyTokensRefreshed();
      }
      return adopted;
    } catch (e) {
      debugPrint('[API] Failed to reload persisted tokens: $e');
      return false;
    }
  }

  Future<void> _notifyTokensRefreshed() async {
    try {
      final persisted = await onTokensRefreshed?.call(_accessToken, _refreshToken);
      debugPrint(
        persisted == false
            ? '[API] Tokens NOT persisted (rotation held in memory only): '
                  'access=${tokenFp(_accessToken)} '
                  'refresh=${tokenFp(_refreshToken)}'
            : '[API] Tokens handed to persistence: access=${tokenFp(_accessToken)} '
                  'refresh=${tokenFp(_refreshToken)}',
      );
    } catch (e) {
      debugPrint('[API] Failed to persist refreshed tokens: $e');
    }
  }

  Future<Completer<void>> _acquireTokenMutationLock() async {
    while (_tokenMutationCompleter != null) {
      await _tokenMutationCompleter!.future;
    }
    final lock = Completer<void>();
    _tokenMutationCompleter = lock;
    return lock;
  }

  void _releaseTokenMutationLock(Completer<void> lock) {
    if (identical(_tokenMutationCompleter, lock)) {
      _tokenMutationCompleter = null;
    }
    if (!lock.isCompleted) lock.complete();
  }

  Future<bool> _refreshTokenPairOnce() async {
    final refreshToken = _refreshToken;
    if (_isLegacyToken || refreshToken == null) return false;
    try {
      final response = await _post(
        Uri.parse('$_cleanBaseUrl/auth/refresh'),
        headers: {
          ...customHeaders,
          'x-refresh-token': refreshToken,
          if (!kIsWeb) 'User-Agent': userAgent,
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint(
          '[API] Proactive token refresh failed: ${response.statusCode} '
          '(refresh=${tokenFp(refreshToken)})',
        );
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tokens = AuthTokens.fromResponse(data);
      if (tokens.accessToken == null || tokens.refreshToken == null) return false;
      _accessToken = tokens.accessToken!;
      _refreshToken = tokens.refreshToken!;
      await _notifyTokensRefreshed();
      debugPrint(
        '[API] Proactive token refresh ok -> '
        'refresh=${tokenFp(_refreshToken)}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Attempt to refresh the access token using the refresh token. A rejected
  /// refresh is kept distinct from a temporary network/server failure so only
  /// an explicit 401/403 can expire the local session.
  Future<_RefreshOutcome> _refreshAccessToken() async {
    if (_isLegacyToken || _refreshToken == null) {
      debugPrint('[API] Cannot refresh: isLegacy=$_isLegacyToken, hasRefreshToken=${_refreshToken != null}');
      return _RefreshOutcome.transientFailure;
    }

    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      debugPrint('[API] Token refresh joining in-flight attempt');
      return _refreshCompleter!.future;
    }

    debugPrint(
      '[API] Token refresh start: access=${tokenFp(_accessToken)} '
      'refresh=${tokenFp(_refreshToken)}',
    );
    _refreshCompleter = Completer<_RefreshOutcome>();
    final mutationLock = await _acquireTokenMutationLock();
    try {
      if (await _adoptPersistedTokens()) {
        _refreshCompleter!.complete(_RefreshOutcome.refreshed);
        return _RefreshOutcome.refreshed;
      }

      for (var attempt = 0; attempt < 2; attempt++) {
        final refreshTokenSent = _refreshToken;
        if (refreshTokenSent == null) break;

        try {
          // Timeout is load-bearing: this is awaited from tryRestoreSession via
          // the 401-retry path, and a stalled response here would otherwise hold
          // the splash screen forever.
          final response = await _post(
            Uri.parse('$_cleanBaseUrl/auth/refresh'),
            headers: {
              ...customHeaders,
              'x-refresh-token': refreshTokenSent,
              if (!kIsWeb) 'User-Agent': userAgent,
            },
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final tokens = AuthTokens.fromResponse(data);
            final newAccess = tokens.accessToken;
            final newRefresh = tokens.refreshToken;
            if (newAccess != null) {
              _accessToken = newAccess;
              if (newRefresh != null) _refreshToken = newRefresh;
              await _notifyTokensRefreshed();
              debugPrint(
                '[API] Token refreshed successfully -> '
                'access=${tokenFp(newAccess)} refresh=${tokenFp(newRefresh)} '
                'rotated=${newRefresh != null && newRefresh != refreshTokenSent}',
              );
              _refreshCompleter!.complete(_RefreshOutcome.refreshed);
              return _RefreshOutcome.refreshed;
            }
          }

          if (response.statusCode == 401 || response.statusCode == 403) {
            if (await _adoptPersistedTokens()) {
              _refreshCompleter!.complete(_RefreshOutcome.refreshed);
              return _RefreshOutcome.refreshed;
            }
            if (_refreshToken != refreshTokenSent && attempt == 0) continue;
            debugPrint(
              '[API] Token refresh rejected: ${response.statusCode} '
              '(sent refresh=${tokenFp(refreshTokenSent)})'
              '${_refreshToken == refreshTokenSent ? " - storage holds the same spent token, session is dead until re-login" : ""}',
            );
            _refreshCompleter!.complete(_RefreshOutcome.rejected);
            return _RefreshOutcome.rejected;
          }

          debugPrint('[API] Token refresh failed: ${response.statusCode}');
        } catch (e) {
          debugPrint('[API] Token refresh error: $e');
        }

        if (attempt == 0) {
          await Future<void>.delayed(_refreshRetryDelay);
          if (await _adoptPersistedTokens()) {
            _refreshCompleter!.complete(_RefreshOutcome.refreshed);
            return _RefreshOutcome.refreshed;
          }
        }
      }

      _refreshCompleter!.complete(_RefreshOutcome.transientFailure);
      return _RefreshOutcome.transientFailure;
    } finally {
      _refreshCompleter = null;
      _releaseTokenMutationLock(mutationLock);
    }
  }

  /// Seconds of headroom before the access token's own expiry at which we stop
  /// trusting it. Generous because a slow request that starts valid can still
  /// arrive expired.
  static const _accessTokenSkew = Duration(seconds: 60);

  /// Expiry stamped in the access token, or null when it can't be read
  /// (legacy static tokens, opaque tokens, malformed payloads).
  DateTime? get _accessTokenExpiry {
    final parts = _accessToken.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final exp = payload['exp'];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

  /// Suppresses the pre-flight after a refresh that couldn't reach the server.
  /// Static because callers construct a fresh ApiService per use.
  static DateTime? _preflightCooldownUntil;
  static const _preflightCooldown = Duration(minutes: 2);

  /// Static state outlives a single test, so a test that trips the cooldown
  /// would otherwise silently disable the pre-flight for whatever runs next.
  @visibleForTesting
  static void resetPreflightCooldown() => _preflightCooldownUntil = null;

  /// Refresh BEFORE spending a known-expired access token, rather than firing
  /// the request, taking a 401, and recovering afterwards.
  ///
  /// Reactive-only refresh means every parallel call that happens to fall after
  /// expiry races into its own recovery - four concurrent refreshes inside one
  /// second showed up in the 2026-08-13 logout log - and it widens the window
  /// in which a rotation can be lost. The server's grace period for a spent
  /// refresh token is only ten minutes, so noticing early matters.
  ///
  /// The cooldown is what keeps this from being worse than the old behaviour
  /// when the server is routable but not answering (LAN-only server, away from
  /// home): without it every call would spend two 15s refresh timeouts, holding
  /// the token mutation lock, before its own request even started - so a
  /// handful of queued calls turn into minutes. After one unreachable attempt
  /// we go back to letting the request itself fail.
  Future<void> _ensureFreshAccessToken() async {
    if (_isLegacyToken || _refreshToken == null) return;
    final cooldownUntil = _preflightCooldownUntil;
    if (cooldownUntil != null && DateTime.now().isBefore(cooldownUntil)) return;
    final expiry = _accessTokenExpiry;
    if (expiry == null) return;
    if (DateTime.now().add(_accessTokenSkew).isBefore(expiry)) return;
    final outcome = await _refreshAccessToken();
    switch (outcome) {
      case _RefreshOutcome.refreshed:
        _preflightCooldownUntil = null;
      case _RefreshOutcome.rejected:
        _preflightCooldownUntil = null;
        onAuthExpired?.call();
      case _RefreshOutcome.transientFailure:
        _preflightCooldownUntil = DateTime.now().add(_preflightCooldown);
        debugPrint(
          '[API] Pre-flight refresh could not reach the server - '
          'falling back to on-401 refresh for '
          '${_preflightCooldown.inMinutes}m',
        );
    }
  }

  /// Make an authenticated GET request, retrying once on 401 with a refreshed token.
  ///
  /// [sendRefreshTokenHeader] adds `x-refresh-token` from whatever the current
  /// pair is once the pre-flight has run, rather than from a value the caller
  /// captured earlier.
  Future<http.Response> _authGet(Uri url, {Map<String, String>? headers, bool sendRefreshTokenHeader = false, Duration timeout = const Duration(seconds: 15)}) async {
    await _ensureFreshAccessToken();
    var h = headers ?? _headers;
    if (sendRefreshTokenHeader && _refreshToken != null) {
      h = {...h, 'x-refresh-token': _refreshToken!};
    }
    var response = await _get(url, headers: h).timeout(timeout);
    if (response.statusCode == 401) {
      debugPrint('[API] 401 on GET ${url.path} - isLegacy=$_isLegacyToken, hasRefresh=${_refreshToken != null}, tokenLen=${_accessToken.length}');
    }
    if (response.statusCode == 401 && !_isLegacyToken) {
      final outcome = await _refreshAccessToken();
      if (outcome == _RefreshOutcome.refreshed) {
        final refreshedHeaders = Map<String, String>.from(h)
          ..['Authorization'] = 'Bearer $_accessToken';
        if (refreshedHeaders.containsKey('x-refresh-token') &&
            _refreshToken != null) {
          refreshedHeaders['x-refresh-token'] = _refreshToken!;
        }
        response = await _get(url, headers: refreshedHeaders).timeout(timeout);
      }
      if (outcome == _RefreshOutcome.rejected) onAuthExpired?.call();
    }
    return response;
  }

  /// Make an authenticated POST request, retrying once on 401 with a refreshed token.
  Future<http.Response> _authPost(Uri url, {Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 15)}) async {
    await _ensureFreshAccessToken();
    final h = headers ?? _headers;
    var response = await _post(url, headers: h, body: body).timeout(timeout);
    if (response.statusCode == 401 && !_isLegacyToken) {
      final outcome = await _refreshAccessToken();
      if (outcome == _RefreshOutcome.refreshed) {
        final refreshedHeaders = Map<String, String>.from(h)
          ..['Authorization'] = 'Bearer $_accessToken';
        response = await _post(url, headers: refreshedHeaders, body: body).timeout(timeout);
      }
      if (outcome == _RefreshOutcome.rejected) onAuthExpired?.call();
    }
    return response;
  }

  /// Make an authenticated PATCH request, retrying once on 401 with a refreshed token.
  Future<http.Response> _authPatch(Uri url, {Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 15)}) async {
    await _ensureFreshAccessToken();
    final h = headers ?? _headers;
    var response = await _patch(url, headers: h, body: body).timeout(timeout);
    if (response.statusCode == 401 && !_isLegacyToken) {
      final outcome = await _refreshAccessToken();
      if (outcome == _RefreshOutcome.refreshed) {
        final refreshedHeaders = Map<String, String>.from(h)
          ..['Authorization'] = 'Bearer $_accessToken';
        response = await _patch(url, headers: refreshedHeaders, body: body).timeout(timeout);
      }
      if (outcome == _RefreshOutcome.rejected) onAuthExpired?.call();
    }
    return response;
  }

  /// Make an authenticated DELETE request, retrying once on 401 with a refreshed token.
  Future<http.Response> _authDelete(Uri url, {Map<String, String>? headers, Duration timeout = const Duration(seconds: 15)}) async {
    await _ensureFreshAccessToken();
    final h = headers ?? _headers;
    var response = await _delete(url, headers: h).timeout(timeout);
    if (response.statusCode == 401 && !_isLegacyToken) {
      final outcome = await _refreshAccessToken();
      if (outcome == _RefreshOutcome.refreshed) {
        final refreshedHeaders = Map<String, String>.from(h)
          ..['Authorization'] = 'Bearer $_accessToken';
        response = await _delete(url, headers: refreshedHeaders).timeout(timeout);
      }
      if (outcome == _RefreshOutcome.rejected) onAuthExpired?.call();
    }
    return response;
  }

  /// Login and return the full response JSON (contains user, token, etc.) and HTTP status code.
  static Future<(Map<String, dynamic>?, int)> login({
    required String serverUrl,
    required String username,
    required String password,
    Map<String, String> customHeaders = const {},
  }) async {
    final url = serverUrl.endsWith('/')
        ? '${serverUrl}login'
        : '$serverUrl/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...customHeaders,
          'Content-Type': 'application/json',
          'x-return-tokens': 'true',
          if (!kIsWeb) 'User-Agent': userAgent,
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as Map<String, dynamic>, 200);
      }
      return (null, response.statusCode);
    } catch (e) {
      return (null, 0);
    }
  }

  /// Validate an API key by hitting `/api/me`. Returns the user JSON and the
  /// HTTP status code. API keys are sent as a Bearer token, same as JWT/legacy
  /// tokens, so successful validation lets us reuse the legacy-token path
  /// (no refresh, persists like any other session).
  static Future<(Map<String, dynamic>?, int)> loginWithApiKey({
    required String serverUrl,
    required String apiKey,
    Map<String, String> customHeaders = const {},
  }) async {
    final base = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
    final url = '${base}api/me';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {...customHeaders, 'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as Map<String, dynamic>, 200);
      }
      return (null, response.statusCode);
    } catch (_) {
      return (null, 0);
    }
  }

  /// Ping the server to check connectivity.
  static Future<bool> pingServer(String serverUrl, {Map<String, String> customHeaders = const {}}) async {
    final url = serverUrl.endsWith('/')
        ? '${serverUrl}ping'
        : '$serverUrl/ping';
    try {
      final response = await http.get(Uri.parse(url), headers: customHeaders.isNotEmpty ? customHeaders : null)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Ping the server and report why it failed, for the login screen. The
  /// plain [pingServer] collapses every failure into a single false, which
  /// leaves users (and us) blind when a server reachable in a browser won't
  /// connect in the app - usually a proxy/CDN treating the app's request
  /// differently than a browser. Kept separate so the connectivity hot paths
  /// keep their lean bool + short timeouts. [detail] is null on success.
  static Future<({bool ok, String? detail})> pingServerDetailed(
    String serverUrl, {
    Map<String, String> customHeaders = const {},
  }) async {
    final url = serverUrl.endsWith('/') ? '${serverUrl}ping' : '$serverUrl/ping';
    try {
      final response = await http
          .get(Uri.parse(url), headers: customHeaders.isNotEmpty ? customHeaders : null)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return (ok: true, detail: null);
      return (ok: false, detail: 'Server returned HTTP ${response.statusCode} instead of 200.');
    } catch (e) {
      return (ok: false, detail: _describePingError(e));
    }
  }

  /// Turn a raw ping exception into a plain-language reason. Classifies by
  /// message text rather than type because the http package flattens socket
  /// and TLS errors into ClientException, hiding the original class.
  static String _describePingError(Object e) {
    if (e is TimeoutException) {
      return 'Timed out after 15s. The server is slow to respond, or something on the way is dropping the connection.';
    }
    final msg = e.toString();
    final lower = msg.toLowerCase();
    if (lower.contains('failed host lookup') || lower.contains('nodename nor servname')) {
      return 'Could not resolve the domain (DNS). Check the address is spelled right. ($msg)';
    }
    if (lower.contains('handshake') || lower.contains('certificate') || lower.contains('tls')) {
      return 'Secure connection (TLS) failed. If your server uses a self-signed certificate, turn on Trust all certificates above. Otherwise the server may be blocking non-browser apps. ($msg)';
    }
    if (lower.contains('connection refused')) {
      return 'Connection refused - nothing is listening on that address or port. ($msg)';
    }
    if (lower.contains('connection closed before full header') ||
        lower.contains('http/2') ||
        lower.contains('protocol error')) {
      return 'The server closed the connection early. This can happen when a proxy only speaks HTTP/2. ($msg)';
    }
    if (lower.contains('connection reset') || lower.contains('connection terminated')) {
      return 'The connection was reset, which usually means a proxy or firewall is blocking the app even though browsers get through. ($msg)';
    }
    return msg;
  }

  /// Get the server version via the /status endpoint (no auth needed).
  static Future<String?> getServerVersion(String serverUrl, {Map<String, String> customHeaders = const {}}) async {
    final url = serverUrl.endsWith('/')
        ? '${serverUrl}status'
        : '$serverUrl/status';
    try {
      final response = await http.get(Uri.parse(url), headers: customHeaders.isNotEmpty ? customHeaders : null)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final version = data['serverVersion'] as String?;
        cacheServerVersion(serverUrl, version);
        return version;
      }
    } catch (_) {}
    return null;
  }

  // Last-known version per server origin. Stream URL shape depends on the
  // server's capabilities, and buildTrackUrl is synchronous, so the version
  // has to already be in memory by the time playback starts. Persisted per
  // origin and re-hydrated on construction to cover cold starts where the
  // /status fetch hasn't answered yet.
  static final Map<String, String> _serverVersions = {};
  static final Set<String> _serverVersionLoads = {};

  static String? _originOf(String url) {
    try {
      return Uri.parse(normalizeServerUrl(url)).origin;
    } catch (_) {
      return null;
    }
  }

  /// Remember [version] for the server at [serverUrl], in memory and in prefs.
  /// Called from every place a version is learned: login responses, /status,
  /// and admin settings saves.
  static void cacheServerVersion(String serverUrl, String? version) {
    if (version == null || version.isEmpty) return;
    final origin = _originOf(serverUrl);
    if (origin == null) return;
    _serverVersionLoads.add(origin);
    if (_serverVersions[origin] == version) return;
    _serverVersions[origin] = version;
    unawaited(
      SharedPreferences.getInstance()
          .then((p) => p.setString('server_version_$origin', version))
          .catchError((Object _) => false),
    );
  }

  static void _loadCachedServerVersion(String serverUrl) {
    final origin = _originOf(serverUrl);
    if (origin == null || !_serverVersionLoads.add(origin)) return;
    unawaited(
      SharedPreferences.getInstance().then((p) {
        final v = p.getString('server_version_$origin');
        if (v != null && v.isNotEmpty) {
          _serverVersions.putIfAbsent(origin, () => v);
        }
      }).catchError((Object _) {}),
    );
  }

  /// True when [version] parses as `major.minor[.patch]` (optionally with a
  /// leading `v`) and is at least [major].[minor]. Unparseable = false.
  static bool serverVersionAtLeast(String? version, int major, int minor) {
    final m = RegExp(r'^\s*v?(\d+)\.(\d+)').firstMatch(version ?? '');
    if (m == null) return false;
    final vMajor = int.parse(m.group(1)!);
    if (vMajor != major) return vMajor > major;
    return int.parse(m.group(2)!) >= minor;
  }

  /// Whether this server has the tokenless public session track endpoint
  /// (added in Audiobookshelf v2.22.0). False while the version is unknown,
  /// which safely degrades to the tokened URL form.
  bool get _hasPublicSessionTracks {
    final origin = _originOf(_cleanBaseUrl);
    if (origin == null) return false;
    return serverVersionAtLeast(_serverVersions[origin], 2, 22);
  }

  /// Get all libraries.
  Future<List<dynamic>> getLibraries() async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final libs = (data['libraries'] as List?) ?? [];
        debugPrint('[API] getLibraries: ${libs.length} libraries');
        return libs;
      } else {
        debugPrint('[API] getLibraries failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API] getLibraries error: $e');
    }
    return [];
  }

  /// Get the personalized home view for a library.
  /// Returns sections like "continue-listening", "recently-added", "discover", etc.
  /// Null means the request failed (network / non-200), as opposed to an
  /// empty list of shelves.
  Future<List<dynamic>?> getPersonalizedView(
    String libraryId, {
    bool minified = true,
    List<String> include = const ['numEpisodesIncomplete'],
    List<String>? shelves,
    int? limit,
  }) async {
    try {
      final query = <String, String>{};
      if (minified) query['minified'] = '1';
      if (include.isNotEmpty) query['include'] = include.join(',');
      if (shelves != null && shelves.isNotEmpty) {
        query['shelves'] = shelves.join(',');
      }
      if (limit != null) query['limit'] = '$limit';

      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/personalized')
            .replace(queryParameters: query.isEmpty ? null : query),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List<dynamic>) return data;
        if (data is Map<String, dynamic>) {
          final shelvesData = data['shelves'];
          if (shelvesData is List<dynamic>) return shelvesData;
          final results = data['results'];
          if (results is List<dynamic>) return results;
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Get library items (paginated).
  Future<Map<String, dynamic>?> getLibraryItems(
    String libraryId, {
    int page = 0,
    int limit = 20,
    String sort = 'addedAt',
    int desc = 1,
    String? filter,
    bool expanded = false,
    bool collapseSeries = false,
  }) async {
    try {
      var url = '$_cleanBaseUrl/api/libraries/$libraryId/items'
          '?page=$page&limit=$limit&sort=$sort&desc=$desc'
          // Ask the server to populate numEpisodesIncomplete on podcast items
          // so podcast tiles can show an unplayed-count badge without loading
          // every show's full episode list.
          '&include=numEpisodesIncomplete';
      if (filter != null) url += '&filter=$filter';
      if (expanded) url += '&minified=0';
      if (collapseSeries) url += '&collapseseries=1';
      final response = await _authGet(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Fetch every library item the server has flagged with an issue - missing
  /// (files gone from disk) or invalid (present but unparseable). ABS exposes
  /// both under the plain `filter=issues` param. Each result carries the
  /// `isMissing` / `isInvalid` booleans so the caller can tell them apart.
  Future<List<dynamic>> getIssueItems(String libraryId) async {
    final all = <dynamic>[];
    var page = 0;
    while (page < 100) {
      final data = await getLibraryItems(
        libraryId,
        filter: 'issues',
        page: page,
        limit: 100,
        sort: 'media.metadata.title',
        desc: 0,
      );
      final results = data?['results'] as List? ?? const [];
      all.addAll(results);
      final total = data?['total'] as int?;
      page++;
      if (results.isEmpty || (total != null && all.length >= total)) break;
    }
    return all;
  }

  /// Count of issue items in a library (missing + invalid), fetched cheaply by
  /// reading `total` from a single-item issues query. Returns 0 on any failure.
  Future<int> getIssueItemCount(String libraryId) async {
    final data = await getLibraryItems(libraryId, filter: 'issues', limit: 1);
    return data?['total'] as int? ?? 0;
  }

  /// Build a cover image URL for a library item.
  String getCoverUrl(String itemId, {int? width = 400, int? updatedAt}) {
    var url = '$_cleanBaseUrl/api/items/$itemId/cover?token=$token';
    if (width != null) url += '&width=$width';
    if (updatedAt != null) url += '&ts=$updatedAt';
    return url;
  }

  /// POST /api/authorize - validates the current token and returns the same
  /// payload shape as /login: { user, userDefaultLibraryId, serverSettings,
  /// ereaderDevices, Source }. Use on cold-start restore when you need the
  /// top-level extras (especially ereaderDevices, since /api/me drops them).
  Future<Map<String, dynamic>?> authorize() async {
    try {
      final response = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/authorize'),
        timeout: const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[API] authorize failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('[API] authorize error: $e');
    }
    return null;
  }

  /// Get current user info including all mediaProgress.
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me'),
        timeout: const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[API] getMe failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('[API] getMe error: $e');
    }
    return null;
  }

  /// Use the compact v2.36 endpoint, with one `/api/me` fallback for older servers.
  Future<List<Map<String, dynamic>>?> getAllProgress() async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/progress'),
        timeout: const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['mediaProgress'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      if (response.statusCode != 404) return null;
      final user = await getMe();
      return (user?['mediaProgress'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('[API] getAllProgress error: $e');
      return null;
    }
  }

  /// Use the compact v2.36 endpoint, with one `/api/me` fallback for older servers.
  Future<List<Map<String, dynamic>>?> getAllBookmarks() async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/bookmarks'),
        timeout: const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['bookmarks'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      if (response.statusCode != 404) return null;
      final user = await getMe();
      return (user?['bookmarks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('[API] getAllBookmarks error: $e');
      return null;
    }
  }

  Future<AuthSessionsResult> getAuthSessions({int page = 0, int itemsPerPage = 20}) async {
    try {
      // Headers are built by _authGet AFTER its pre-flight refresh, so this
      // can't be snapshotted here - a rotation would leave both the Bearer and
      // the x-refresh-token stale, guaranteeing a 401 and a second rotation.
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/sessions?page=$page&itemsPerPage=$itemsPerPage'),
        sendRefreshTokenHeader: true,
        timeout: const Duration(seconds: 10));
      if (response.statusCode == 404) {
        return const AuthSessionsResult(AuthSessionsStatus.unsupported);
      }
      if (response.statusCode != 200) {
        return const AuthSessionsResult(AuthSessionsStatus.failed);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSessionsResult(
        AuthSessionsStatus.supported,
        AuthSessionsPage.fromJson(data));
    } catch (e) {
      debugPrint('[API] getAuthSessions error: $e');
      return const AuthSessionsResult(AuthSessionsStatus.failed);
    }
  }

  Future<bool> deleteAuthSession(AuthSession session) async {
    if (session.current) return false;
    try {
      final response = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/me/sessions/${session.id}'),
        timeout: const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[API] deleteAuthSession error: $e');
      return false;
    }
  }

  Future<bool> revokeServerSession({bool allDevices = false}) async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final suffix = allDevices ? '?allDevices=1' : '';
      final response = await _post(
        Uri.parse('$_cleanBaseUrl/logout$suffix'),
        headers: {
          ...customHeaders,
          'x-refresh-token': refreshToken,
          if (!kIsWeb) 'User-Agent': userAgent,
        }).timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[API] logout error: $e');
      return false;
    }
  }

  Future<PasswordChangeResult> changeMyPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final mutationLock = await _acquireTokenMutationLock();
    try {
      await _adoptPersistedTokens();
      Future<http.Response> sendPasswordChange() => _patch(
          Uri.parse('$_cleanBaseUrl/api/me/password'),
          headers: {
            ..._headers,
            if (_refreshToken != null) 'x-refresh-token': _refreshToken!,
            if (!kIsWeb) 'User-Agent': userAgent,
          },
          body: jsonEncode({'password': currentPassword, 'newPassword': newPassword})
        ).timeout(const Duration(seconds: 15));

      var response = await sendPasswordChange();
      if (response.statusCode == 401 && !_isLegacyToken) {
        final adopted = await _adoptPersistedTokens();
        if (adopted || await _refreshTokenPairOnce()) {
          response = await sendPasswordChange();
        }
      }

      if (response.statusCode == 404) {
        return const PasswordChangeResult(PasswordChangeStatus.unsupported);
      }
      if (response.statusCode == 400) {
        return PasswordChangeResult(
          PasswordChangeStatus.invalidPassword,
          message: response.body.trim().isEmpty ? null : response.body.trim());
      }
      if (response.statusCode != 200) {
        return const PasswordChangeResult(PasswordChangeStatus.failed);
      }

      if (response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return const PasswordChangeResult(PasswordChangeStatus.failed);
        }
        final data = decoded;
        final error = data['error'];
        if (error is String && error.trim().isNotEmpty) {
          return PasswordChangeResult(
            PasswordChangeStatus.invalidPassword,
            message: error.trim(),
          );
        }
        final tokens = AuthTokens.fromResponse(data);
        // The server rotates these together. Never adopt half a pair.
        if (tokens.accessToken != null && tokens.refreshToken != null) {
          _accessToken = tokens.accessToken!;
          _refreshToken = tokens.refreshToken!;
          await _notifyTokensRefreshed();
        }
      }
      // Older servers return an empty 200 and keep the current pair valid.
      return const PasswordChangeResult(PasswordChangeStatus.success);
    } catch (e) {
      debugPrint('[API] changeMyPassword error: $e');
      return const PasswordChangeResult(PasswordChangeStatus.failed);
    } finally {
      _releaseTokenMutationLock(mutationLock);
    }
  }

  /// Get user's listening stats.
  Future<Map<String, dynamic>?> getListeningStats() async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/listening-stats'),
        timeout: const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Get user's listening sessions (paginated).
  Future<Map<String, dynamic>?> getListeningSessions({int page = 0, int itemsPerPage = 20}) async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/listening-sessions?itemsPerPage=$itemsPerPage&page=$page'),
        timeout: const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>?> getItemListeningSessions(
    String libraryItemId, {
    String? episodeId,
  }) async {
    const itemsPerPage = 100;
    final itemPath = Uri.encodeComponent(libraryItemId);
    final episodePath = episodeId == null
        ? ''
        : '/${Uri.encodeComponent(episodeId)}';
    final endpoint =
        '$_cleanBaseUrl/api/me/item/listening-sessions/$itemPath$episodePath';
    final sessions = <Map<String, dynamic>>[];
    var page = 0;

    try {
      while (true) {
        final uri = Uri.parse(endpoint).replace(queryParameters: {
          'itemsPerPage': '$itemsPerPage',
          'page': '$page',
        });
        final response = await _authGet(
          uri,
          timeout: const Duration(seconds: 10),
        );
        if (response.statusCode != 200) return null;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pageSessions = (data['sessions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
        sessions.addAll(pageSessions);

        final numPages = (data['numPages'] as num?)?.toInt() ?? 1;
        if (pageSessions.isEmpty || page + 1 >= numPages) break;
        page++;
      }
      return sessions;
    } catch (_) {
      return null;
    }
  }

  /// Get a specific user's listening sessions (admin, paginated).
  Future<Map<String, dynamic>?> getUserListeningSessions(String userId, {int page = 0, int itemsPerPage = 10}) async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/users/$userId/listening-sessions?itemsPerPage=$itemsPerPage&page=$page'),
        timeout: const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Get a library's series (paginated).
  Future<Map<String, dynamic>?> getLibrarySeries(
    String libraryId, {
    int page = 0,
    int limit = 50,
    String sort = 'addedAt',
    int desc = 1,
  }) async {
    try {
      final response = await _authGet(
        Uri.parse(
          '$_cleanBaseUrl/api/libraries/$libraryId/series'
          '?page=$page&limit=$limit&sort=$sort&desc=$desc',
        ),
        timeout: const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Build an author image URL.
  String getAuthorImageUrl(String authorId, {int width = 200, int? updatedAt}) {
    var url = '$_cleanBaseUrl/api/authors/$authorId/image?width=$width&token=$token';
    if (updatedAt != null) url += '&ts=$updatedAt';
    return url;
  }

  /// Get a library's filter data (authors, series, genres, etc.)
  /// Used by Android Auto to build browse tree without fetching full items.
  Future<Map<String, dynamic>?> getLibraryFilterData(String libraryId) async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId?include=filterdata'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['filterdata'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Get books by a specific author using the filter API.
  /// Filter format: authors.<base64(authorId)>
  Future<List<dynamic>> getBooksByAuthor(
    String libraryId,
    String authorId, {
    int limit = 50,
  }) async {
    try {
      final filterValue = base64Encode(utf8.encode(authorId));
      final url = '$_cleanBaseUrl/api/libraries/$libraryId/items'
          '?filter=authors.$filterValue&sort=media.metadata.title&limit=$limit';
      final response = await _authGet(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['results'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      debugPrint('[API] getBooksByAuthor error: $e');
    }
    return [];
  }

  /// Get all authors for a library.
  Future<List<Map<String, dynamic>>> getLibraryAuthors(String libraryId) async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/authors'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authors = data['authors'] as List<dynamic>? ?? [];
        return authors.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[API] getLibraryAuthors error: $e');
    }
    return [];
  }

  /// Get all narrators for a library. ABS exposes narrators only via the
  /// filterdata endpoint as a list of name strings (no IDs/images/bios).
  Future<List<String>> getLibraryNarrators(String libraryId) async {
    try {
      final data = await getLibraryFilterData(libraryId);
      if (data == null) return [];
      final raw = data['narrators'] as List<dynamic>? ?? [];
      return raw
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[API] getLibraryNarrators error: $e');
    }
    return [];
  }

  /// Get books narrated by a specific person.
  /// Filter format: narrators.<base64(name)>
  Future<List<dynamic>> getBooksByNarrator(
    String libraryId,
    String narratorName, {
    int limit = 50,
  }) async {
    try {
      final filterValue = base64Encode(utf8.encode(narratorName));
      final url = '$_cleanBaseUrl/api/libraries/$libraryId/items'
          '?filter=narrators.$filterValue&sort=media.metadata.title&limit=$limit';
      final response = await _authGet(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['results'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      debugPrint('[API] getBooksByNarrator error: $e');
    }
    return [];
  }

  /// Get full author details including description/bio.
  Future<Map<String, dynamic>?> getAuthorById(String authorId, {String? libraryId}) async {
    try {
      var url = '$_cleanBaseUrl/api/authors/$authorId?include=items';
      if (libraryId != null) url += '&library=$libraryId';
      final response = await _authGet(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[API] getAuthorById error: $e');
    }
    return null;
  }

  /// Update an author's editable fields (admin/root only).
  /// Returns one of:
  ///   { ok: true, author: {...} }         - normal update succeeded
  ///   { ok: true, merged: { id, name } }  - name matched another author, this one was merged
  ///   { ok: false }                       - request failed
  /// PATCH /api/authors/:id
  Future<Map<String, dynamic>> updateAuthor(
    String authorId, {
    String? name,
    String? description,
    String? asin,
    String? imagePath,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (asin != null) body['asin'] = asin;
      if (imagePath != null) body['imagePath'] = imagePath;
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/authors/$authorId'),
        body: jsonEncode(body),
      );
      debugPrint('[API] updateAuthor $authorId -> ${r.statusCode}: ${r.body}');
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        if (data['merged'] != null) {
          return {'ok': true, 'merged': data['merged']};
        }
        return {'ok': true, 'author': data['author'] ?? data};
      }
    } catch (e) { debugPrint('updateAuthor error: $e'); }
    return {'ok': false};
  }

  /// Quick-match an author against the configured provider (Audible).
  /// Server fetches name/asin/description/image, updates the author server-side,
  /// and returns the author. Returns null if no match or on error. A successful
  /// match can return the unchanged author when its stored details are already
  /// current.
  /// POST /api/authors/:id/match  body: { q, region }
  /// Response: { updated, author } on match; a missing provider match is 404.
  Future<Map<String, dynamic>?> matchAuthor(
    String authorId, {
    required String q,
    String region = 'us',
  }) async {
    final result = await quickMatchAuthor(authorId, q: q, region: region);
    if (!result.found) return null;
    return result.author;
  }

  /// Quick-match one author using the same ASIN-first request shape as the
  /// Audiobookshelf web client. The full response is retained so batch callers
  /// can distinguish a match with no changes from a missing author or a failed
  /// request.
  Future<AuthorQuickMatchResult> quickMatchAuthor(
    String authorId, {
    String? q,
    String? asin,
    String region = 'us',
  }) async {
    final trimmedAsin = asin?.trim() ?? '';
    final trimmedQuery = q?.trim() ?? '';
    if (trimmedAsin.isEmpty && trimmedQuery.isEmpty) {
      return const AuthorQuickMatchResult(statusCode: 0);
    }

    try {
      final body = <String, dynamic>{'region': region};
      if (trimmedAsin.isNotEmpty) {
        body['asin'] = trimmedAsin;
      } else {
        body['q'] = trimmedQuery;
      }
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/authors/$authorId/match'),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 30),
      );
      debugPrint(
        '[API] quickMatchAuthor $authorId -> ${r.statusCode}: ${r.body}',
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final author = data['author'] is Map
            ? Map<String, dynamic>.from(data['author'] as Map)
            : null;
        // Current ABS returns 404 when the provider has no match. Older
        // servers returned 200 with {updated: false} and no author payload.
        if (author == null && data['updated'] == false) {
          return const AuthorQuickMatchResult(statusCode: 404);
        }
        return AuthorQuickMatchResult(
          statusCode: r.statusCode,
          updated: data['updated'] == true,
          author: author,
        );
      }
      return AuthorQuickMatchResult(statusCode: r.statusCode);
    } catch (e) {
      debugPrint('quickMatchAuthor error: $e');
    }
    return const AuthorQuickMatchResult(statusCode: 0);
  }

  /// Set the author image from a remote URL.
  /// POST /api/authors/:id/image  body: { url }
  Future<bool> updateAuthorImageFromUrl(String authorId, String url) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/authors/$authorId/image'),
        body: jsonEncode({'url': url}),
        timeout: const Duration(seconds: 30),
      );
      debugPrint('[API] updateAuthorImageFromUrl $authorId -> ${r.statusCode}');
      return r.statusCode == 200;
    } catch (e) { debugPrint('updateAuthorImageFromUrl error: $e'); }
    return false;
  }

  /// Remove the author's image.
  /// DELETE /api/authors/:id/image
  Future<bool> deleteAuthorImage(String authorId) async {
    try {
      final r = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/authors/$authorId/image'),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('deleteAuthorImage error: $e'); }
    return false;
  }

  /// Get books in a specific series using the filter API.
  /// Filter format: series.<base64(seriesId)>
  Future<List<dynamic>> getBooksBySeries(
    String libraryId,
    String seriesId, {
    int limit = 50,
  }) async {
    try {
      final filterValue = base64Encode(utf8.encode(seriesId));
      final url = '$_cleanBaseUrl/api/libraries/$libraryId/items'
          '?filter=series.$filterValue'
          '&sort=media.metadata.series.sequence&limit=$limit&collapseseries=0';
      final response = await _authGet(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['results'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      debugPrint('[API] getBooksBySeries error: $e');
    }
    return [];
  }

  /// Expose clean base URL for audio player to build URLs
  String get cleanBaseUrl => _cleanBaseUrl;

  /// The device descriptor ABS attaches to playback sessions. Shared by the
  /// /play session calls and the client-owned local-session calls.
  Map<String, dynamic> get _deviceInfo => {
        'clientName': 'Absorb',
        'clientVersion': appVersion,
        'deviceId': deviceId,
        'deviceName': '${deviceManufacturer.isNotEmpty ? "$deviceManufacturer " : ""}$deviceModel'.trim(),
        'manufacturer': deviceManufacturer,
        'model': deviceModel,
      };

  /// Start a playback session for a library item.
  /// POST /api/items/:id/play
  /// Returns the full session object including audioTracks with contentUrl.
  Future<Map<String, dynamic>?> startPlaybackSession(String itemId, {String? episodeId, bool forceDirectPlay = false, bool forceTranscode = false, double? startOffset}) async {
    try {
      final epPath = episodeId != null ? '/$episodeId' : '';
      final url = '$_cleanBaseUrl/api/items/$itemId/play$epPath';
      debugPrint('[ABS] Starting playback session: POST $url (forceDirectPlay: $forceDirectPlay, forceTranscode: $forceTranscode)');
      final body = <String, dynamic>{
        'deviceInfo': _deviceInfo,
        'forceDirectPlay': !forceTranscode,
        'forceTranscode': forceTranscode,
        // Match what the native ABS Android app sends so the server treats us
        // as a known ExoPlayer client and picks direct-play correctly.
        'mediaPlayer': 'exo-player',
        'supportedMimeTypes': [
          'audio/flac',
          'audio/mpeg',
          'audio/mp4',
          'audio/ogg',
          'audio/aac',
          'audio/x-m4a',
          'audio/x-m4b',
          'audio/opus',
          'audio/webm',
          'audio/wav',
          'audio/x-wav',
          'audio/x-matroska',
          'audio/x-ms-wma',
        ],
      };
      if (startOffset != null && startOffset > 0) body['startOffset'] = startOffset;
      final response = await _authPost(
        Uri.parse(url),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 20));

      debugPrint('[ABS] Play session response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tracks = data['audioTracks'] as List<dynamic>?;
        debugPrint('[ABS] Session ID: ${data['id']}');
        debugPrint('[ABS] Audio tracks: ${tracks?.length ?? 0}');
        if (tracks != null && tracks.isNotEmpty) {
          final firstTrack = tracks.first as Map<String, dynamic>;
          debugPrint('[ABS] First track contentUrl: ${firstTrack['contentUrl']}');
        }
        return data;
      } else {
        debugPrint('[ABS] Play session failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ABS] Play session error: $e');
    }
    return null;
  }

  /// Build a full audio track URL from a contentUrl returned by the play
  /// session. When the caller passes the session context ([sessionId], the
  /// track's own [trackIndex], [playMethod]) and the session is direct play
  /// on a server with the public session endpoint, the URL is synthesized
  /// with no token in it at all - the unguessable session id is the
  /// credential, so token rotation can't 401 a stream mid-book. Everything
  /// else keeps the contentUrl-based forms.
  String buildTrackUrl(
    String contentUrl, {
    String? sessionId,
    int? trackIndex,
    int? playMethod,
  }) {
    // ABS servers with ROUTER_BASE_PATH set return contentUrls that already
    // include the base path (e.g. "/abs/public/session/.../track/0"). If the
    // user's server URL also includes that base path, blindly concatenating
    // would double it ("/abs/abs/..."). Detect and use origin only.
    final baseUri = Uri.parse(_cleanBaseUrl);
    final basePath = baseUri.path;
    final isAbsolute = contentUrl.startsWith('http');
    final Uri trackUri;
    if (isAbsolute) {
      trackUri = Uri.parse(contentUrl);
    } else if (basePath.isNotEmpty && contentUrl.startsWith('$basePath/')) {
      trackUri = Uri.parse('${baseUri.origin}$contentUrl');
    } else {
      trackUri = Uri.parse('$_cleanBaseUrl$contentUrl');
    }

    if (trackUri.path.contains('/public/session/')) {
      final query = Map<String, dynamic>.from(trackUri.queryParametersAll)
        ..remove('token');
      if (query.isEmpty) {
        final value = trackUri.toString();
        final queryStart = value.indexOf('?');
        if (queryStart < 0) return value;
        final fragmentStart = value.indexOf('#', queryStart);
        return value.substring(0, queryStart) +
            (fragmentStart < 0 ? '' : value.substring(fragmentStart));
      }
      return trackUri.replace(queryParameters: query).toString();
    }

    if (isAbsolute) return contentUrl;

    // playMethod 0 = direct play. Transcode sessions must keep their HLS
    // contentUrl, and pre-2.22 servers lack the endpoint but hand out legacy
    // tokens that never expire, so both fall through safely.
    if (sessionId != null &&
        sessionId.isNotEmpty &&
        trackIndex != null &&
        playMethod == 0 &&
        _hasPublicSessionTracks) {
      return '$_cleanBaseUrl/public/session/$sessionId/track/$trackIndex';
    }

    // No per-track logging here: this runs in a hot loop over every track, and
    // books with thousands of files would flood (and roll over) the log buffer.
    // The session's "First track contentUrl" line already gives a sample.
    final query = Map<String, dynamic>.from(trackUri.queryParametersAll)
      ..['token'] = token;
    return trackUri.replace(queryParameters: query).toString();
  }

  /// Build a durable, session-independent file download URL for [ino] within
  /// [itemId]. Unlike a playback-session track URL, this survives session close
  /// and app suspension, so it is safe for background downloads that outlive the
  /// session/app. Auth travels as `?token=` (the Authorization header can be
  /// dropped across reverse-proxy redirects); custom proxy headers still ride
  /// along via [mediaHeaders] when the downloader sets them.
  String buildFileUrl(String itemId, String ino) {
    return '$_cleanBaseUrl/api/items/$itemId/file/$ino?token=$token';
  }

  /// Sync playback progress. Returns true if sync succeeded.
  /// POST /api/session/:id/sync
  Future<bool> syncPlaybackSession(
    String sessionId, {
    required double currentTime,
    required double duration,
    int timeListened = 60,
  }) async {
    try {
      final response = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/session/$sessionId/sync'),
        body: jsonEncode({
          'currentTime': currentTime,
          'timeListened': timeListened,
          // Older servers use this duration unconditionally for the progress
          // row, so it must be sent; progress is ignored by every version
          // (the server derives it from the session).
          'duration': duration,
        }),
        timeout: const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Close a playback session.
  /// POST /api/session/:id/close
  Future<void> closePlaybackSession(String sessionId) async {
    try {
      await _authPost(
        Uri.parse('$_cleanBaseUrl/api/session/$sessionId/close'),
        timeout: const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Upsert a client-owned local playback session (downloaded/offline plays).
  /// POST /api/session/local — preserves our playMethod (LOCAL) and the
  /// client-supplied date/timestamps, unlike /play which forces Direct Play.
  /// [session] is a fully-built session map; deviceInfo/mediaPlayer/playMethod
  /// are stamped here so they can't be omitted.
  Future<LocalSessionResult> syncLocalSession(Map<String, dynamic> session) async {
    try {
      final body = {
        ...session,
        'deviceInfo': _deviceInfo,
        'mediaPlayer': 'exo-player',
        'playMethod': 3, // LOCAL
      };
      final resp = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/session/local'),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 10));
      return LocalSessionResult(
        ok: resp.statusCode == 200,
        serverTooOld: resp.statusCode == 404 || resp.statusCode == 501,
      );
    } catch (_) {
      return const LocalSessionResult(ok: false, serverTooOld: false);
    }
  }

  /// Batch-upsert local sessions, used to replay the offline queue on reconnect.
  /// POST /api/session/local-all
  Future<LocalSessionResult> syncLocalSessionsAll(
      List<Map<String, dynamic>> sessions) async {
    if (sessions.isEmpty) return const LocalSessionResult(ok: true, serverTooOld: false);
    try {
      final body = {
        'sessions': sessions
            .map((s) => {...s, 'mediaPlayer': 'exo-player', 'playMethod': 3})
            .toList(),
        'deviceInfo': _deviceInfo,
      };
      final resp = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/session/local-all'),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 20));
      return LocalSessionResult(
        ok: resp.statusCode == 200,
        serverTooOld: resp.statusCode == 404 || resp.statusCode == 501,
      );
    } catch (_) {
      return const LocalSessionResult(ok: false, serverTooOld: false);
    }
  }

  /// Edit an existing listening session by re-POSTing it through the local
  /// upsert. The server honors timeListening, currentTime, and updatedAt (it
  /// re-derives the session's day from updatedAt); other fields on an existing
  /// session are left untouched, so the original playMethod/device stay intact.
  /// Returns true on success.
  Future<bool> updateListeningSession(Map<String, dynamic> session) async {
    try {
      final resp = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/session/local'),
        body: jsonEncode(session),
        timeout: const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Delete a listening session. Needs the user's delete permission on the
  /// server (403 otherwise). Returns true on success.
  Future<bool> deleteListeningSession(String sessionId) async {
    try {
      final resp = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/sessions/$sessionId'),
        timeout: const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get server progress for a single item.
  /// GET /api/me/progress/:id
  Future<Map<String, dynamic>?> getItemProgress(String itemId) async {
    try {
      // Podcast episodes use compound key "showId-episodeId" →
      // ABS endpoint: /api/me/progress/{showId}/{episodeId}
      final progressPath = itemId.length > 36
          ? '${itemId.substring(0, 36)}/${itemId.substring(37)}'
          : itemId;
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _progressRecreationBody(
    Map<String, dynamic> progress, {
    required int startedAt,
  }) {
    final originalStartedAt = progress['startedAt'];
    if (progress['id'] is! String || originalStartedAt is! num) return null;

    final body = <String, dynamic>{
      'createdAt': startedAt,
      'isFinished': progress['isFinished'] == true,
    };
    for (final key in [
      'currentTime',
      'duration',
      'progress',
      'hideFromContinueListening',
      'ebookLocation',
      'ebookProgress',
      'finishedAt',
    ]) {
      if (progress[key] != null) body[key] = progress[key];
    }
    return body;
  }

  /// Change a book's start date while preserving its listening progress.
  /// Audiobookshelf stores the displayed start date as the progress record's
  /// creation time, so changing it requires recreating that record.
  Future<bool> updateProgressStartDate(String itemId, int startedAt) async {
    try {
      final progress = await getItemProgress(itemId);
      if (progress == null) return false;
      final progressId = progress['id'];
      final originalStartedAt = progress['startedAt'];
      if (progressId is! String || originalStartedAt is! num) return false;

      final updatedBody = _progressRecreationBody(
        progress,
        startedAt: startedAt,
      );
      final originalBody = _progressRecreationBody(
        progress,
        startedAt: originalStartedAt.toInt(),
      );
      if (updatedBody == null || originalBody == null) return false;

      final deleteResponse = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressId'),
        timeout: const Duration(seconds: 10),
      );
      if (deleteResponse.statusCode < 200 || deleteResponse.statusCode >= 300) {
        return false;
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
      int? updateStatus;
      try {
        final updateResponse = await _authPatch(
          Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId'),
          body: jsonEncode(updatedBody),
          timeout: const Duration(seconds: 10),
        );
        updateStatus = updateResponse.statusCode;
        if (updateStatus >= 200 && updateStatus < 300) return true;
      } catch (e) {
        debugPrint('[API] updateProgressStartDate recreate error: $e');
      }

      try {
        final restoreResponse = await _authPatch(
          Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId'),
          body: jsonEncode(originalBody),
          timeout: const Duration(seconds: 10),
        );
        debugPrint(
          '[API] updateProgressStartDate failed ($updateStatus); '
          'restore=${restoreResponse.statusCode}',
        );
      } catch (e) {
        debugPrint('[API] updateProgressStartDate restore error: $e');
      }
    } catch (e) {
      debugPrint('[API] updateProgressStartDate error: $e');
    }
    return false;
  }

  /// Change the finish date on an existing progress record.
  Future<bool> updateProgressFinishedDate(String itemId, int finishedAt) async {
    try {
      final response = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId'),
        body: jsonEncode({'finishedAt': finishedAt, 'isFinished': true}),
        timeout: const Duration(seconds: 10),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[API] updateProgressFinishedDate error: $e');
      return false;
    }
  }

  /// Update media progress directly (for offline sync).
  /// PATCH /api/me/progress/:id
  Future<void> updateProgress(
    String itemId, {
    required double currentTime,
    required double duration,
    bool isFinished = false,
  }) async {
    try {
      final body = jsonEncode({
        'currentTime': currentTime,
        'duration': duration,
        'progress': duration > 0 ? (currentTime / duration).clamp(0.0, 1.0) : 0,
        'isFinished': isFinished,
      });
      final progressPath = itemId.length > 36
          ? '${itemId.substring(0, 36)}/${itemId.substring(37)}'
          : itemId;
      debugPrint('[API] updateProgress PATCH /api/me/progress/$progressPath');
      debugPrint('[API] updateProgress body: currentTime=$currentTime');
      final resp = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        body: body,
        timeout: const Duration(seconds: 10));
      debugPrint('[API] updateProgress response: ${resp.statusCode} ${resp.body}');
    } catch (e) {
      debugPrint('[API] updateProgress error: $e');
      rethrow;
    }
  }

  /// Update ebook reading progress on the server. Returns whether the PATCH
  /// landed, so the caller can queue the position for a later retry.
  /// PATCH /api/me/progress/:id
  Future<bool> updateEbookProgress(
    String itemId, {
    required String ebookLocation,
    required double ebookProgress,
  }) async {
    try {
      final body = jsonEncode({
        'ebookLocation': ebookLocation,
        'ebookProgress': ebookProgress,
        // Only ever MARK finished from the ebook; never send isFinished:false.
        // The server shares one isFinished flag for audio+ebook, and on a
        // true->false transition it also resets currentTime to 0 - so sending
        // false here would un-finish the book and wipe the audiobook's position.
        if (ebookProgress >= 1.0) 'isFinished': true,
      });
      final progressPath = itemId.length > 36
          ? '${itemId.substring(0, 36)}/${itemId.substring(37)}'
          : itemId;
      debugPrint('[API] updateEbookProgress PATCH /api/me/progress/$progressPath');
      final resp = await http.patch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 10));
      debugPrint('[API] updateEbookProgress response: ${resp.statusCode} ${resp.body}');
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('[API] updateEbookProgress error: $e');
      return false;
    }
  }

  /// Mark a book as finished on the server.
  Future<void> markFinished(String itemId, double duration) async {
    await updateProgress(
      itemId,
      currentTime: duration,
      duration: duration,
      isFinished: true,
    );
  }

  /// Mark a book as not finished (reset progress to a position).
  Future<void> markNotFinished(String itemId, {
    required double currentTime,
    required double duration,
  }) async {
    await updateProgress(
      itemId,
      currentTime: currentTime,
      duration: duration,
      isFinished: false,
    );
  }

  /// Reset progress to zero.
  Future<bool> resetProgress(String itemId, double duration) async {
    try {
      final progressPath = itemId.length > 36
          ? '${itemId.substring(0, 36)}/${itemId.substring(37)}'
          : itemId;
      final isCompound = itemId.length > 36;
      final apiItemId = isCompound ? itemId.substring(0, 36) : itemId;
      final episodeId = isCompound ? itemId.substring(37) : null;

      // DELETE progress entry
      await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        timeout: const Duration(seconds: 10));

      // Start session at 0 and close — forces server to update position
      final sessionData = await startPlaybackSession(apiItemId, episodeId: episodeId);
      if (sessionData != null) {
        final sessionId = sessionData['id'] as String?;
        if (sessionId != null) {
          await syncPlaybackSession(sessionId, currentTime: 0, duration: duration);
          await closePlaybackSession(sessionId);
        }
      }

      // PATCH last to hide from continue listening (after session sync)
      await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        body: jsonEncode({
          'currentTime': 0,
          'progress': 0,
          'isFinished': false,
          'hideFromContinueListening': true,
          'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        }),
        timeout: const Duration(seconds: 10));

      return true;
    } catch (e) {
      debugPrint('[API] resetProgress error: $e');
      return false;
    }
  }

  /// Hide an entire series from the "Continue Series" home shelf.
  /// GET /api/me/series/:seriesId/remove-from-continue-listening
  Future<bool> removeSeriesFromContinueListening(String seriesId) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/series/$seriesId/remove-from-continue-listening'),
        timeout: const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('[API] removeSeriesFromContinueListening error: $e');
      return false;
    }
  }

  /// Hide a single item from the "Continue Listening" home shelf.
  /// GET /api/me/progress/:mediaProgressId/remove-from-continue-listening
  /// The path id is the media-progress record id (not the libraryItemId).
  Future<bool> removeItemFromContinueListening(String mediaProgressId) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$mediaProgressId/remove-from-continue-listening'),
        timeout: const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('[API] removeItemFromContinueListening error: $e');
      return false;
    }
  }

  // ─── Podcast Episode Endpoints ─────────────────────────────

  /// Start a playback session for a podcast episode.
  /// POST /api/items/:itemId/play/:episodeId
  Future<Map<String, dynamic>?> startEpisodePlaybackSession(
      String itemId, String episodeId, {bool forceTranscode = false}) async {
    try {
      final url = '$_cleanBaseUrl/api/items/$itemId/play/$episodeId';
      debugPrint('[ABS] Starting episode session: POST $url (forceTranscode: $forceTranscode)');
      final response = await _authPost(
        Uri.parse(url),
        body: jsonEncode({
          'deviceInfo': _deviceInfo,
          'forceDirectPlay': !forceTranscode,
          'forceTranscode': forceTranscode,
          'mediaPlayer': 'exo-player',
          'supportedMimeTypes': [
            'audio/flac',
            'audio/mpeg',
            'audio/mp4',
            'audio/ogg',
            'audio/aac',
            'audio/x-m4a',
            'audio/x-m4b',
            'audio/opus',
            'audio/webm',
            'audio/wav',
            'audio/x-wav',
            'audio/x-matroska',
            'audio/x-ms-wma',
          ],
        }),
        timeout: const Duration(seconds: 20));

      debugPrint('[ABS] Episode session response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('[ABS] Episode session failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ABS] Episode session error: $e');
    }
    return null;
  }

  /// Get server progress for a podcast episode.
  /// GET /api/me/progress/:itemId/:episodeId
  Future<Map<String, dynamic>?> getEpisodeProgress(
      String itemId, String episodeId) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId/$episodeId'),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Update progress for a podcast episode.
  /// PATCH /api/me/progress/:itemId/:episodeId
  Future<void> updateEpisodeProgress(
    String itemId,
    String episodeId, {
    required double currentTime,
    required double duration,
    bool isFinished = false,
  }) async {
    try {
      await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId/$episodeId'),
        body: jsonEncode({
          'currentTime': currentTime,
          'duration': duration,
          'progress': duration > 0 ? (currentTime / duration).clamp(0.0, 1.0) : 0,
          'isFinished': isFinished,
        }),
        timeout: const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[API] updateEpisodeProgress error: $e');
    }
  }

  /// DELETE /api/me/progress/:itemId/:episodeId
  Future<bool> deleteEpisodeProgress(String itemId, String episodeId) async {
    try {
      final resp = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId/$episodeId'),
        timeout: const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('[API] deleteEpisodeProgress error: $e');
      return false;
    }
  }

  /// Get recent podcast episodes for a library.
  /// GET /api/libraries/:id/recent-episodes
  Future<List<dynamic>> getRecentEpisodes(String libraryId, {int limit = 25, int page = 0}) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/recent-episodes?limit=$limit&page=$page'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data['episodes'] is List) return data['episodes'] as List<dynamic>;
        if (data is List) return data;
      }
    } catch (e) {
      debugPrint('[API] getRecentEpisodes error: $e');
    }
    return [];
  }

  /// Get a single library item with full detail (expanded=1 gives chapters, tracks, etc.)
  Future<Map<String, dynamic>?> getLibraryItem(String itemId) async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId?expanded=1&include=progress'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // ─── Bookmark Endpoints ───────────────────────────────────

  /// Get bookmarks for an item from the server.
  Future<List<Map<String, dynamic>>?> getServerBookmarks(String itemId) async {
    try {
      final response = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/me/bookmarks/$itemId'),
        timeout: const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['bookmarks'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      if (response.statusCode != 404) return null;

      final user = await getMe();
      if (user != null) {
        final bookmarks = user['bookmarks'] as List<dynamic>?;
        if (bookmarks != null) {
          // Filter to bookmarks for this item
          return bookmarks
              .whereType<Map<String, dynamic>>()
              .where((b) => b['libraryItemId'] == itemId)
              .toList();
        }
      }
      return [];
    } catch (e) { debugPrint('getServerBookmarks error: $e'); }
    return null;
  }

  /// Create a bookmark on the server.
  /// POST /api/me/item/:id/bookmark  body: { time, title }
  Future<bool> createBookmark(String itemId, {required double time, required String title}) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/me/item/$itemId/bookmark'),
        body: jsonEncode({'time': time, 'title': title}),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('createBookmark error: $e'); }
    return false;
  }

  /// Update a bookmark on the server.
  /// PATCH /api/me/item/:id/bookmark  body: { time, title }
  Future<bool> updateBookmark(String itemId, {required double time, required String title}) async {
    try {
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/me/item/$itemId/bookmark'),
        body: jsonEncode({'time': time, 'title': title}),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('updateBookmark error: $e'); }
    return false;
  }

  /// Delete a bookmark on the server.
  /// DELETE /api/me/item/:id/bookmark/:time
  Future<bool> deleteBookmark(String itemId, {required double time}) async {
    try {
      final r = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/me/item/$itemId/bookmark/$time'),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('deleteBookmark error: $e'); }
    return false;
  }

  // ─── Email / E-Reader ──────────────────────────────────────────────

  /// Send the ebook file for [libraryItemId] to a configured ereader.
  /// POST /api/emails/send-ebook-to-device  body: { libraryItemId, deviceName }
  Future<bool> sendEBookToDevice({
    required String libraryItemId,
    required String deviceName,
  }) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/emails/send-ebook-to-device'),
        body: jsonEncode({'libraryItemId': libraryItemId, 'deviceName': deviceName}),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('[API] sendEBookToDevice error: $e'); }
    return false;
  }

  /// GET /api/emails/settings (admin only)
  Future<Map<String, dynamic>?> getEmailSettings() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/emails/settings'));
      if (r.statusCode != 200) return null;
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) {
        // ABS wraps the settings in `settings` on this endpoint.
        final settings = body['settings'];
        if (settings is Map<String, dynamic>) return settings;
        return body;
      }
      return null;
    } catch (e) { debugPrint('[API] getEmailSettings error: $e'); }
    return null;
  }

  /// PATCH /api/emails/settings (admin only)
  Future<bool> updateEmailSettings(Map<String, dynamic> patch) async {
    try {
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/emails/settings'),
        body: jsonEncode(patch),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('[API] updateEmailSettings error: $e'); }
    return false;
  }

  /// POST /api/emails/test (admin only)
  Future<bool> sendTestEmail() async {
    try {
      final r = await _authPost(Uri.parse('$_cleanBaseUrl/api/emails/test'));
      return r.statusCode == 200;
    } catch (e) { debugPrint('[API] sendTestEmail error: $e'); }
    return false;
  }

  /// Replace the full ereader devices list (admin only).
  /// POST /api/emails/ereader-devices  body: { ereaderDevices: [{name, email, availabilityOption, users}, ...] }
  Future<bool> updateEReaderDevices(List<Map<String, dynamic>> devices) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/emails/ereader-devices'),
        body: jsonEncode({'ereaderDevices': devices}),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('[API] updateEReaderDevices error: $e'); }
    return false;
  }

  /// Get a single series with its books (paginated).
  /// If [onPageLoaded] is provided, it's called after each page with the
  /// cumulative results and total so the UI can show books as they arrive.
  /// Series metadata only, for ids stored without a name. Tries the direct
  /// series endpoint first and falls back to the per-library one for servers
  /// that don't expose it.
  Future<Map<String, dynamic>?> getSeriesInfo(
    String seriesId, {
    List<String> libraryIds = const [],
  }) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/series/$seriesId'),
      );
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    for (final libraryId in libraryIds) {
      try {
        final resp = await _authGet(
          Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/series/$seriesId'),
        );
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<Map<String, dynamic>?> getSeries(String seriesId, {String? libraryId, void Function(List<dynamic> books, int total, {double? totalDuration})? onPageLoaded}) async {
    try {
      Map<String, dynamic>? seriesMeta;

      // Get series metadata
      if (libraryId != null) {
        final metaResp = await _authGet(
          Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/series/$seriesId'),
          timeout: const Duration(seconds: 30));
        if (metaResp.statusCode == 200) {
          seriesMeta = jsonDecode(metaResp.body) as Map<String, dynamic>;
        }
      }

      // Get all books in the series, paginating if needed.
      // ABS filter format: series.<base64(seriesId)>
      if (libraryId != null) {
        final filterValue = base64Encode(utf8.encode(seriesId));
        const pageSize = 100;
        final allResults = <dynamic>[];
        int total = 0;
        int page = 0;
        while (true) {
          final url = '$_cleanBaseUrl/api/libraries/$libraryId/items?filter=series.$filterValue&sort=media.metadata.series.sequence&limit=$pageSize&page=$page&collapseseries=0';
          final itemsResp = await _authGet(
            Uri.parse(url),
            timeout: const Duration(seconds: 30));
          if (itemsResp.statusCode != 200) {
            debugPrint('[API] getSeries items page $page failed: ${itemsResp.statusCode}');
            break;
          }
          final data = jsonDecode(itemsResp.body) as Map<String, dynamic>;
          final results = data['results'] as List<dynamic>? ?? [];
          total = (data['total'] as num?)?.toInt() ?? results.length;
          allResults.addAll(results);
          onPageLoaded?.call(allResults, total, totalDuration: (seriesMeta?['totalDuration'] as num?)?.toDouble());
          if (allResults.length >= total || results.isEmpty) break;
          page++;
        }
        if (allResults.isNotEmpty) {
          return {
            'id': seriesId,
            'name': seriesMeta?['name'] ?? '',
            'books': allResults,
            'total': total,
            if (seriesMeta != null) 'totalDuration': seriesMeta['totalDuration'],
          };
        }
      }
    } catch (_) {
    }
    return null;
  }

  /// Get books in a series with collapseseries=1 to detect sub-series.
  /// Returns items where books sharing another series are collapsed into
  /// a single entry with a 'collapsedSeries' object.
  Future<List<dynamic>> getSeriesCollapsed(String seriesId, {required String libraryId}) async {
    try {
      final filterValue = base64Encode(utf8.encode(seriesId));
      final allResults = <dynamic>[];
      int page = 0;
      while (true) {
        final url = '$_cleanBaseUrl/api/libraries/$libraryId/items?filter=series.$filterValue&sort=addedAt&limit=100&page=$page&collapseseries=1';
        final resp = await _authGet(Uri.parse(url), timeout: const Duration(seconds: 60));
        if (resp.statusCode != 200) {
          debugPrint('[API] getSeriesCollapsed page $page failed: ${resp.statusCode}');
          break;
        }
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        final total = (data['total'] as num?)?.toInt() ?? results.length;
        allResults.addAll(results);
        if (allResults.length >= total || results.isEmpty) break;
        page++;
      }
      return allResults;
    } catch (e) { debugPrint('[API] getSeriesCollapsed error: $e'); }
    return [];
  }

  /// Search a library. Returns { book: [...], series: [...], authors: [...] }
  Future<Map<String, dynamic>?> searchLibrary(
    String libraryId,
    String query, {
    int limit = 25,
  }) async {
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final response = await _authGet(
        Uri.parse(
          '$_cleanBaseUrl/api/libraries/$libraryId/search?q=$encoded&limit=$limit',
        ),
        timeout: const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Search for book metadata via the ABS server's search endpoint.
  /// Uses the server's configured providers (Audible, Google, etc.).
  /// Returns a list of result maps with title, author, description, cover, etc.
  Future<List<Map<String, dynamic>>> searchBooks({
    required String title,
    String? author,
    String provider = 'audible',
  }) async {
    try {
      final params = <String, String>{
        'title': title,
        'provider': provider,
        'region': _region,
      };
      if (author != null && author.isNotEmpty) {
        params['author'] = author;
      }
      final uri = Uri.parse('$_cleanBaseUrl/api/search/books')
          .replace(queryParameters: params);
      debugPrint('[API] searchBooks: $uri');
      final response = await _authGet(
        uri,
      );

      debugPrint('[API] searchBooks status=${response.statusCode} bodyLen=${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ABS returns a plain List for most providers
        if (data is List) {
          debugPrint('[API] searchBooks: got List with ${data.length} items');
          return data.whereType<Map<String, dynamic>>().toList();
        }

        // Some providers may return a Map with results nested under a key
        if (data is Map<String, dynamic>) {
          debugPrint('[API] searchBooks: got Map with keys: ${data.keys.join(', ')}');
          // Try common nesting patterns
          for (final key in ['results', 'items', 'books', 'matches']) {
            final nested = data[key];
            if (nested is List && nested.isNotEmpty) {
              return nested.whereType<Map<String, dynamic>>().toList();
            }
          }
          // Single result as a map — wrap it
          if (data.containsKey('title') || data.containsKey('book')) {
            return [data];
          }
        }

        debugPrint('[API] searchBooks: unexpected response type: ${data.runtimeType}');
      }
    } catch (e) {
      debugPrint('[API] searchBooks error: $e');
    }
    return [];
  }

  /// Fetch Audible rating from Audnexus API using ASIN.
  /// Returns { rating, asin } or null.
  static Future<Map<String, dynamic>?> getAudibleRating(String asin) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.audnex.us/books/$asin?region=$_region&update=1'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rating = data['rating'] as String?;
        if (rating != null) {
          return {
            'rating': double.tryParse(rating) ?? 0.0,
            'asin': asin,
          };
        }
      }
    } catch (e) {
      // ignore — Audnexus is optional
    }
    return null;
  }

  /// Read a previously-fetched Audible rating from local cache, keyed by
  /// library item id. Used so the rating shows immediately on book detail
  /// open even when Audnexus is slow or unreachable, and so a transient
  /// network failure doesn't make a known rating disappear.
  static Future<Map<String, dynamic>?> getCachedAudibleRating(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('audible_rating_$itemId');
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final rating = (data['rating'] as num?)?.toDouble();
      if (rating == null || rating <= 0) return null;
      return {
        'rating': rating,
        'asin': data['asin'] as String?,
      };
    } catch (_) {
      return null;
    }
  }

  /// Persist a fresh Audible rating so subsequent book detail opens render
  /// the stars instantly without waiting on Audnexus.
  static Future<void> setCachedAudibleRating(
      String itemId, double rating, String? asin) async {
    if (rating <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('audible_rating_$itemId', jsonEncode({
        'rating': rating,
        'asin': asin,
        'fetchedAt': DateTime.now().millisecondsSinceEpoch,
      }));
    } catch (_) {}
  }

  /// Search Audible via the audiobookshelf server for an ASIN by title+author,
  /// then fetch the rating from Audnexus. Used as a fallback when the book's
  /// stored ASIN returns no rating.
  Future<Map<String, dynamic>?> searchAudibleRating(
      String title, String? author) async {
    try {
      // Use the ABS server's search endpoint to query Audible for the book.
      final response = await _authGet(
        Uri.parse(
          '$_cleanBaseUrl/api/search/covers?title=${Uri.encodeQueryComponent(title)}'
          '&author=${Uri.encodeQueryComponent(author ?? '')}'
          '&provider=audible&region=$_region',
        ),
      );

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List<dynamic>? ?? [];
        // Look for an ASIN in the results
        for (final r in results) {
          if (r is Map<String, dynamic>) {
            final asin = r['asin'] as String? ?? r['key'] as String? ?? '';
            if (asin.isNotEmpty && asin.startsWith('B')) {
              return await getAudibleRating(asin);
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // ─── Audible Series Discovery ─────────────────────────────

  /// Supported Audible regions for series discovery.
  static const audibleRegions = {
    'us': 'Audible.com (US)',
    'uk': 'Audible.co.uk (UK)',
    'au': 'Audible.com.au (AU)',
    'ca': 'Audible.ca (CA)',
    'de': 'Audible.de (DE)',
    'fr': 'Audible.fr (FR)',
    'it': 'Audible.it (IT)',
    'es': 'Audible.es (ES)',
    'jp': 'Audible.co.jp (JP)',
    'in': 'Audible.in (IN)',
    'br': 'Audible.com.br (BR)',
  };

  /// Map region code to Audible API TLD.
  static String _audibleTldFor(String region) {
    const tlds = {
      'us': '.com', 'uk': '.co.uk', 'gb': '.co.uk', 'au': '.com.au',
      'ca': '.ca', 'de': '.de', 'fr': '.fr', 'it': '.it', 'es': '.es',
      'jp': '.co.jp', 'in': '.in', 'br': '.com.br',
    };
    return tlds[region] ?? '.com';
  }

  static String get _audibleTld => _audibleTldFor(_region);

  /// Fetch full book metadata from Audnexus by ASIN.
  /// Returns the raw Audnexus response including seriesPrimary, releaseDate, etc.
  /// If [region] is provided, it overrides the device locale region.
  static Future<Map<String, dynamic>?> getAudnexusBook(String asin, {String? region}) async {
    try {
      final r = region ?? _region;
      final response = await http.get(
        Uri.parse('https://api.audnex.us/books/$asin?region=$r'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[API] getAudnexusBook error: $e');
    }
    return null;
  }

  /// Get all book ASINs in an Audible series using the catalog relationships endpoint.
  /// Returns a list of { asin, sequence, sort } maps.
  static Future<List<Map<String, dynamic>>> getAudibleSeriesBooks(String seriesAsin, {String? region}) async {
    try {
      final tld = region != null ? _audibleTldFor(region) : _audibleTld;
      final url = 'https://api.audible$tld/1.0/catalog/products/$seriesAsin'
          '?response_groups=relationships';
      debugPrint('[API] getAudibleSeriesBooks: $url');
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final product = data['product'] as Map<String, dynamic>? ?? {};
        final relationships = product['relationships'] as List<dynamic>? ?? [];

        final books = <Map<String, dynamic>>[];
        for (final r in relationships) {
          if (r is! Map<String, dynamic>) continue;
          final asin = r['asin'] as String?;
          if (asin == null || asin.isEmpty) continue;
          books.add({
            'asin': asin,
            'sequence': r['sequence']?.toString() ?? '',
            'sort': r['sort']?.toString() ?? '0',
          });
        }
        return books;
      }
      debugPrint('[API] getAudibleSeriesBooks status=${response.statusCode}');
    } catch (e) {
      debugPrint('[API] getAudibleSeriesBooks error: $e');
    }
    return [];
  }

  /// Fetch details for a single book from the Audible catalog API.
  /// Returns title, authors, narrators, release_date, runtime, rating, cover, etc.
  static Future<Map<String, dynamic>?> getAudibleBookDetails(String asin, {String? region}) async {
    try {
      final tld = region != null ? _audibleTldFor(region) : _audibleTld;
      final url = 'https://api.audible$tld/1.0/catalog/products/$asin'
          '?response_groups=product_attrs,product_desc,product_details,series,rating,media';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['product'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('[API] getAudibleBookDetails error: $e');
    }
    return null;
  }

  /// High-level: discover all books in an Audible series, returning enriched data.
  /// [seriesAsin] is the Audible series ASIN.
  /// Returns a list of book maps with: asin, title, subtitle, authors, narrators,
  /// releaseDate, runtimeMinutes, rating, coverUrl, sequence.
  /// Books are deduplicated by sequence (prefers user's region) and sorted.
  /// When [newestOnly] is true (default false), only fetches details for the
  /// newest ~50 books by sequence - used by upcoming releases scan to avoid
  /// hammering the Audible API for series with hundreds of entries.
  static Future<List<Map<String, dynamic>>> discoverAudibleSeries(
    String seriesAsin, {
    String? region,
    bool newestOnly = false,
  }) async {
    final relationships = await getAudibleSeriesBooks(seriesAsin, region: region);
    if (relationships.isEmpty) return [];

    final bySequence = <String, List<Map<String, dynamic>>>{};
    for (final r in relationships) {
      final seq = r['sequence'] as String? ?? '';
      final sort = r['sort'] as String? ?? '0';
      final key = seq.isNotEmpty ? seq : 'sort_$sort';
      bySequence.putIfAbsent(key, () => []).add(r);
    }

    var uniqueBooks = <Map<String, dynamic>>[];
    for (final entry in bySequence.entries) {
      uniqueBooks.add({
        ...entry.value.first,
        '_allAsins': entry.value.map((e) => e['asin'] as String).toList(),
      });
    }

    // For upcoming releases scan, only fetch details for the newest books.
    // Sort by sequence descending and take the tail - upcoming/recent releases
    // will always be among the highest-numbered entries.
    if (newestOnly && uniqueBooks.length > 50) {
      uniqueBooks.sort((a, b) {
        final seqA = double.tryParse(a['sequence']?.toString() ?? '') ?? 999999;
        final seqB = double.tryParse(b['sequence']?.toString() ?? '') ?? 999999;
        return seqB.compareTo(seqA); // descending
      });
      debugPrint('[API] discoverAudibleSeries: capping ${uniqueBooks.length} books to newest 50');
      uniqueBooks = uniqueBooks.take(50).toList();
    }

    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < uniqueBooks.length; i += 10) {
      final batch = uniqueBooks.skip(i).take(10);
      final futures = batch.map((book) async {
        final asin = book['asin'] as String;
        final details = await getAudibleBookDetails(asin, region: region);
        if (details == null) return null;

        final authors = (details['authors'] as List<dynamic>? ?? [])
            .map((a) => (a as Map<String, dynamic>)['name'] ?? '').join(', ');
        final narrators = (details['narrators'] as List<dynamic>? ?? [])
            .map((n) => (n as Map<String, dynamic>)['name'] ?? '').join(', ');
        final rating = details['rating'] as Map<String, dynamic>?;

        return <String, dynamic>{
          'asin': asin,
          'title': details['title'] ?? '',
          'subtitle': details['subtitle'] ?? '',
          'authors': authors,
          'narrators': narrators,
          'releaseDate': details['release_date'] ?? '',
          'runtimeMinutes': details['runtime_length_min'] ?? 0,
          'rating': rating?['overall_distribution']?['display_average_rating'] ?? 0.0,
          'numRatings': rating?['overall_distribution']?['num_ratings'] ?? 0,
          'coverUrl': details['product_images']?['500'] ?? details['product_images']?['1024'] ?? '',
          'sequence': book['sequence'] ?? '',
          'sort': book['sort'] ?? '0',
          'publisherSummary': details['publisher_summary'] ?? '',
          'allAsins': book['_allAsins'] ?? <String>[asin],
        };
      });
      final batchResults = await Future.wait(futures);
      results.addAll(batchResults.whereType<Map<String, dynamic>>());
    }

    results.sort((a, b) {
      final seqA = double.tryParse(a['sequence']?.toString() ?? '') ?? 999;
      final seqB = double.tryParse(b['sequence']?.toString() ?? '') ?? 999;
      return seqA.compareTo(seqB);
    });

    return results;
  }

  // ─── Admin Endpoints ──────────────────────────────────────

  /// Get all users (admin only)
  Future<List<dynamic>> getUsers() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/users'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is List) return data;
        if (data is Map) {
          // ABS wraps in {"users": [...]}
          if (data['users'] is List) return data['users'] as List<dynamic>;
          // Fallback: return first list found
          for (final v in data.values) {
            if (v is List) return v;
          }
        }
      }
    } catch (e) { debugPrint('getUsers error: $e'); }
    return [];
  }

  /// Get online users (admin only)
  Future<List<dynamic>> getOnlineUsers() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/users/online'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map && data['usersOnline'] is List) return data['usersOnline'] as List<dynamic>;
        if (data is Map && data['openSessions'] is List) return data['openSessions'] as List<dynamic>;
        if (data is List) return data;
      }
    } catch (e) { debugPrint('getOnlineUsers error: $e'); }
    return [];
  }

  /// Get all listening sessions (admin only)
  Future<List<dynamic>> getAllSessions({int limit = 25}) async {
    try {
      final r = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/sessions?itemsPerPage=$limit'),
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return (data['sessions'] as List<dynamic>?) ?? [];
      }
    } catch (e) { debugPrint('getAllSessions error: $e'); }
    return [];
  }

  /// Admin: paginated listing of every user's sessions. Returns the full
  /// envelope (total, numPages, page, sessions) with each session carrying its
  /// user. Optionally filter to a single [userId]. Admin-only server-side.
  Future<Map<String, dynamic>?> getAllSessionsPaged({
    int page = 0,
    int itemsPerPage = 25,
    String? userId,
    String sort = 'updatedAt',
    bool desc = true,
  }) async {
    try {
      final params = <String, String>{
        'itemsPerPage': '$itemsPerPage',
        'page': '$page',
        'sort': sort,
        'desc': desc ? '1' : '0',
        if (userId != null && userId.isNotEmpty) 'user': userId,
      };
      final uri = Uri.parse('$_cleanBaseUrl/api/sessions')
          .replace(queryParameters: params);
      final r = await _authGet(uri, timeout: const Duration(seconds: 15));
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('getAllSessionsPaged error: $e');
    }
    return null;
  }

  /// Get all backups (admin only)
  Future<List<dynamic>> getBackups() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/backups'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return (data['backups'] as List<dynamic>?) ?? [];
      }
    } catch (e) { debugPrint('getBackups error: $e'); }
    return [];
  }

  /// Get the server's currently running background tasks.
  Future<List<Map<String, dynamic>>?> getServerTasks() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/tasks'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final rawTasks = data is Map ? data['tasks'] : data;
        if (rawTasks is List) {
          return rawTasks
              .whereType<Map>()
              .map((task) => Map<String, dynamic>.from(task))
              .toList();
        }
      }
      debugPrint('[API] getServerTasks failed: ${r.statusCode}');
    } catch (e) {
      debugPrint('[API] getServerTasks error: $e');
    }
    return null;
  }

  /// Check whether Audiobookshelf's destination directory for an upload is
  /// already in use. The web client performs this check before POST /api/upload
  /// so files are not merged into an existing library item directory.
  Future<UploadPathCheckResult> checkUploadPathExists({
    required String directory,
    required String folderPath,
  }) async {
    try {
      final response = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/filesystem/pathexists'),
        body: jsonEncode({
          'directory': directory,
          'folderPath': folderPath,
        }),
        timeout: const Duration(seconds: 20),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UploadPathCheckResult(
          success: true,
          exists: data['exists'] == true,
          libraryItemTitle: data['libraryItemTitle'] as String?,
        );
      }
      final error = response.body.trim();
      return UploadPathCheckResult(
        success: false,
        error: error.isEmpty ? 'HTTP ${response.statusCode}' : error,
      );
    } catch (e) {
      debugPrint('[API] checkUploadPathExists error: $e');
      return UploadPathCheckResult(success: false, error: '$e');
    }
  }

  /// Upload one book or podcast and its related files to Audiobookshelf.
  /// File fields are numbered to match the server's web uploader.
  Future<MediaUploadResult> uploadMedia(
    MediaUploadRequest upload, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_cleanBaseUrl/api/upload'),
      );
      request.headers.addAll(mediaHeaders);
      request.fields.addAll({
        'title': upload.title.trim(),
        'library': upload.libraryId,
        'folder': upload.folderId,
        if (upload.mediaType != 'podcast') ...{
          'author': upload.author?.trim() ?? '',
          'series': upload.series?.trim() ?? '',
        },
      });

      final totalBytes = upload.files.fold<int>(
        0,
        (total, file) => total + file.size,
      );
      var sentBytes = 0;

      for (var i = 0; i < upload.files.length; i++) {
        final file = upload.files[i];
        if (file.bytes != null) {
          final source = Stream<List<int>>.value(file.bytes!);
          final tracked = source.map((chunk) {
            sentBytes += chunk.length;
            onProgress?.call(sentBytes, totalBytes);
            return chunk;
          });
          request.files.add(http.MultipartFile(
            '$i',
            tracked,
            file.size > 0 ? file.size : file.bytes!.length,
            filename: file.name,
          ));
        } else if (file.path != null && file.path!.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath(
            '$i',
            file.path!,
            filename: file.name,
          ));
        } else if (file.readStream != null) {
          final tracked = file.readStream!.map((chunk) {
            sentBytes += chunk.length;
            onProgress?.call(sentBytes, totalBytes);
            return chunk;
          });
          request.files.add(http.MultipartFile(
            '$i',
            tracked,
            file.size,
            filename: file.name,
          ));
        } else {
          return MediaUploadResult(
            success: false,
            error: 'Unable to read ${file.name}',
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        onProgress?.call(totalBytes, totalBytes);
        return const MediaUploadResult(success: true);
      }

      final error = response.body.trim();
      return MediaUploadResult(
        success: false,
        error: error.isEmpty ? 'HTTP ${response.statusCode}' : error,
      );
    } catch (e) {
      debugPrint('[API] uploadMedia error: $e');
      return MediaUploadResult(success: false, error: '$e');
    }
  }

  /// Create a backup (admin only)
  Future<bool> createBackup() async {
    try {
      final r = await _authPost(Uri.parse('$_cleanBaseUrl/api/backups'), timeout: const Duration(seconds: 60));
      return r.statusCode == 200;
    } catch (e) { debugPrint('createBackup error: $e'); }
    return false;
  }

  /// Scan a library's folders (admin only)
  Future<bool> scanLibrary(String libraryId) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/scan'),
        timeout: const Duration(seconds: 30));
      return r.statusCode == 200;
    } catch (e) { debugPrint('scanLibrary error: $e'); }
    return false;
  }

  /// Match all items in a library (admin only)
  Future<bool> matchLibrary(String libraryId) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/match'),
        timeout: const Duration(seconds: 30));
      return r.statusCode == 200;
    } catch (e) { debugPrint('matchLibrary error: $e'); }
    return false;
  }

  /// Get library stats (admin only)
  Future<Map<String, dynamic>?> getLibraryStats(String libraryId) async {
    try {
      final r = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/stats'),
      );
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('getLibraryStats error: $e'); }
    return null;
  }

  /// Purge server cache (admin only)
  Future<bool> purgeCache() async {
    try {
      final r = await _authPost(Uri.parse('$_cleanBaseUrl/api/cache/purge'), timeout: const Duration(seconds: 30));
      return r.statusCode == 200;
    } catch (e) { debugPrint('purgeCache error: $e'); }
    return false;
  }

  /// GET /api/filesystem?path= — browse server directories (admin only).
  /// Omit [path] for the root listing (drive letters on Windows servers).
  /// Returns { posix: bool, directories: [{path, dirname, level}] }.
  Future<Map<String, dynamic>?> getFilesystemPaths({String? path}) async {
    try {
      final uri = Uri.parse('$_cleanBaseUrl/api/filesystem')
          .replace(queryParameters: path != null ? {'path': path} : null);
      final r = await _authGet(uri, timeout: const Duration(seconds: 20));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('[API] getFilesystemPaths error: $e'); }
    return null;
  }

  /// POST /api/libraries — create a library (admin only).
  /// [body] needs name + folders (each {fullPath}); optional mediaType, icon,
  /// provider, settings. Returns the new library object on success.
  Future<Map<String, dynamic>?> createLibrary(Map<String, dynamic> body) async {
    try {
      final r = await _authPost(Uri.parse('$_cleanBaseUrl/api/libraries'),
          body: jsonEncode(body), timeout: const Duration(seconds: 30));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
      debugPrint('[API] createLibrary failed: ${r.statusCode}');
    } catch (e) { debugPrint('[API] createLibrary error: $e'); }
    return null;
  }

  /// PATCH /api/libraries/:id — partial update (admin only).
  /// In [body]'s folders array, keep existing folders as {id, fullPath}, add
  /// new ones as {fullPath}; omitting a folder DELETES it (cascades on server).
  Future<bool> updateLibrary(String id, Map<String, dynamic> body) async {
    try {
      final r = await _authPatch(Uri.parse('$_cleanBaseUrl/api/libraries/$id'),
          body: jsonEncode(body), timeout: const Duration(seconds: 30));
      return r.statusCode == 200;
    } catch (e) { debugPrint('[API] updateLibrary error: $e'); }
    return false;
  }

  /// DELETE /api/libraries/:id — removes the library and all its items (admin only).
  Future<bool> deleteLibrary(String id) async {
    try {
      final r = await _authDelete(Uri.parse('$_cleanBaseUrl/api/libraries/$id'),
          timeout: const Duration(seconds: 30));
      return r.statusCode == 200;
    } catch (e) { debugPrint('[API] deleteLibrary error: $e'); }
    return false;
  }

  /// POST /api/libraries/order — body is a raw array [{id, newOrder}] (admin only).
  Future<bool> reorderLibraries(List<Map<String, dynamic>> order) async {
    try {
      final r = await _authPost(Uri.parse('$_cleanBaseUrl/api/libraries/order'),
          body: jsonEncode(order));
      return r.statusCode == 200;
    } catch (e) { debugPrint('[API] reorderLibraries error: $e'); }
    return false;
  }

  /// Metadata provider ids for the library editor. The server has no endpoint
  /// for these - the ABS web UI hardcodes them client-side - so this is the
  /// same fixed set, plus any custom metadata providers configured on the
  /// server (GET /api/custom-metadata-providers, dropdown value custom-<id>).
  Future<List<String>> getMetadataProviders() async {
    final out = <String>[
      'google', 'openlibrary', 'itunes',
      'audible', 'audible.ca', 'audible.uk', 'audible.au', 'audible.fr',
      'audible.de', 'audible.jp', 'audible.it', 'audible.in', 'audible.es',
      'audnexus', 'fantlab',
    ];
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/custom-metadata-providers'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        for (final p in (data['providers'] as List?) ?? []) {
          if (p is Map && p['id'] != null) {
            final v = 'custom-${p['id']}';
            if (!out.contains(v)) out.add(v);
          }
        }
      }
    } catch (e) { debugPrint('[API] getMetadataProviders error: $e'); }
    return out;
  }

  /// PATCH /api/settings — update server settings (admin only).
  /// There is no GET; read current values from AuthProvider.serverSettings.
  /// Returns the fresh serverSettings map so the caller can re-cache it.
  Future<Map<String, dynamic>?> updateServerSettings(Map<String, dynamic> patch) async {
    try {
      final r = await _authPatch(Uri.parse('$_cleanBaseUrl/api/settings'),
          body: jsonEncode(patch));
      if (r.statusCode == 200) {
        return jsonDecode(r.body)['serverSettings'] as Map<String, dynamic>?;
      }
      debugPrint('[API] updateServerSettings failed: ${r.statusCode}');
    } catch (e) { debugPrint('[API] updateServerSettings error: $e'); }
    return null;
  }

  /// PATCH /api/sorting-prefixes — body { sortingPrefixes: [..] } (admin only).
  /// Returns the fresh serverSettings map (the response also has rowsUpdated).
  Future<Map<String, dynamic>?> updateSortingPrefixes(List<String> prefixes) async {
    try {
      final r = await _authPatch(Uri.parse('$_cleanBaseUrl/api/sorting-prefixes'),
          body: jsonEncode({'sortingPrefixes': prefixes}),
          timeout: const Duration(seconds: 30));
      if (r.statusCode == 200) {
        return jsonDecode(r.body)['serverSettings'] as Map<String, dynamic>?;
      }
    } catch (e) { debugPrint('[API] updateSortingPrefixes error: $e'); }
    return null;
  }

  /// GET /api/stats/server — { books, podcasts, total } (admin only).
  Future<Map<String, dynamic>?> getServerStats() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/stats/server'));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('[API] getServerStats error: $e'); }
    return null;
  }

  /// GET /api/stats/year/:year — admin year-in-review stats (admin only).
  Future<Map<String, dynamic>?> getServerYearStats(int year) async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/stats/year/$year'),
          timeout: const Duration(seconds: 30));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('[API] getServerYearStats error: $e'); }
    return null;
  }

  /// GET /api/me/stats/year/:year — the signed-in user's year-in-review stats.
  Future<Map<String, dynamic>?> getMyYearStats(int year) async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/me/stats/year/$year'),
          timeout: const Duration(seconds: 30));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('[API] getMyYearStats error: $e'); }
    return null;
  }

  /// Create a new user (admin only)
  Future<Map<String, dynamic>?> createUser({
    required String username,
    required String password,
    required String type,
    Map<String, dynamic>? permissions,
    List<String>? librariesAccessible,
    bool isActive = true,
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'password': password,
        'type': type,
        'isActive': isActive,
      };
      if (permissions != null) body['permissions'] = permissions;
      if (librariesAccessible != null) body['librariesAccessible'] = librariesAccessible;
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/users'),
        body: jsonEncode(body),
      );
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('createUser error: $e'); }
    return null;
  }

  /// Get a single user with full details including mediaProgress (admin only)
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final r = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/users/$userId'),
      );
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('getUser error: $e'); }
    return null;
  }

  /// Update a user (admin only)
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/users/$userId'),
        body: jsonEncode(updates),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('updateUser error: $e'); }
    return false;
  }

  /// Delete a user (admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      final r = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/users/$userId'),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('deleteUser error: $e'); }
    return false;
  }

  /// Unlink a user from their OpenID/SSO connection (admin only). Clears the
  /// server's stored authOpenIDSub so the user can re-enroll. The server
  /// returns 200 even if there was no link to begin with.
  Future<bool> unlinkOpenID(String userId) async {
    try {
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/users/$userId/openid-unlink'),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('unlinkOpenID error: $e'); }
    return false;
  }

  /// List all API keys (admin only). Each entry includes the expanded `user`
  /// ({id, username, type}) plus name, isActive, expiresAt, lastUsedAt, createdAt.
  /// The actual key string is never returned here, only on creation.
  Future<List<dynamic>> getApiKeys() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/api-keys'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map && data['apiKeys'] is List) return data['apiKeys'] as List<dynamic>;
        if (data is List) return data;
      }
    } catch (e) { debugPrint('getApiKeys error: $e'); }
    return [];
  }

  /// Create an API key (admin only). [expiresIn] is in seconds; pass null for
  /// no expiration. Returns the created key map which — only on creation —
  /// includes the actual token under `apiKey`.
  Future<Map<String, dynamic>?> createApiKey({
    required String name,
    required String userId,
    int? expiresIn,
    bool isActive = true,
  }) async {
    try {
      final body = <String, dynamic>{'name': name, 'userId': userId, 'isActive': isActive};
      if (expiresIn != null) body['expiresIn'] = expiresIn;
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/api-keys'),
        body: jsonEncode(body),
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map && data['apiKey'] is Map) return Map<String, dynamic>.from(data['apiKey'] as Map);
      }
    } catch (e) { debugPrint('createApiKey error: $e'); }
    return null;
  }

  /// Update an API key (admin only). Only `isActive` and `userId` are mutable
  /// server-side (name and expiry are baked into the JWT).
  Future<bool> updateApiKey(String keyId, {bool? isActive, String? userId}) async {
    try {
      final body = <String, dynamic>{};
      if (isActive != null) body['isActive'] = isActive;
      if (userId != null) body['userId'] = userId;
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/api-keys/$keyId'),
        body: jsonEncode(body),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('updateApiKey error: $e'); }
    return false;
  }

  /// Delete (revoke) an API key (admin only).
  Future<bool> deleteApiKey(String keyId) async {
    try {
      final r = await _authDelete(Uri.parse('$_cleanBaseUrl/api/api-keys/$keyId'));
      return r.statusCode == 200;
    } catch (e) { debugPrint('deleteApiKey error: $e'); }
    return false;
  }

  /// Update a library item's media metadata (admin/root only).
  /// PATCH /api/items/:id/media. Tags live on `media`, not `metadata`, so
  /// pass them via the [tags] arg to be included at the top level of the
  /// payload alongside the metadata block.
  Future<bool> updateItemMedia(
    String itemId,
    Map<String, dynamic> media, {
    List<String>? tags,
  }) async {
    try {
      final body = <String, dynamic>{'metadata': media};
      if (tags != null) body['tags'] = tags;
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/media'),
        body: jsonEncode(body),
      );
      debugPrint('[API] updateItemMedia $itemId -> ${r.statusCode}: ${r.body}');
      return r.statusCode == 200;
    } catch (e) { debugPrint('updateItemMedia error: $e'); }
    return false;
  }

  /// Upload a cover image URL for a library item (admin only)
  Future<bool> updateItemCoverUrl(String itemId, String url) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/cover'),
        body: jsonEncode({'url': url}),
        timeout: const Duration(seconds: 30));
      debugPrint('[API] updateItemCoverUrl $itemId -> ${r.statusCode}: ${r.body}');
      return r.statusCode == 200;
    } catch (e) { debugPrint('updateItemCoverUrl error: $e'); }
    return false;
  }

  /// Remove a library item's cover, leaving it with none (admin only).
  /// DELETE /api/items/:id/cover
  Future<bool> removeItemCover(String itemId) async {
    try {
      final r = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/cover'),
        timeout: const Duration(seconds: 30));
      debugPrint('[API] removeItemCover $itemId -> ${r.statusCode}');
      return r.statusCode == 200;
    } catch (e) { debugPrint('removeItemCover error: $e'); }
    return false;
  }

  /// Upload a cover image file for a library item (admin only)
  Future<bool> uploadItemCover(String itemId, String filePath) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/cover'),
      );
      req.headers.addAll(_headers);
      req.files.add(await http.MultipartFile.fromPath('cover', filePath));
      final res = await req.send().timeout(const Duration(seconds: 60));
      return res.statusCode == 200;
    } catch (e) { debugPrint('uploadItemCover error: $e'); }
    return false;
  }

  /// Search provider cover images for a book.
  /// GET /api/search/covers?title=&author=&provider=  ->  { results: [url, ...] }
  Future<List<String>> searchCovers(String title,
      {String? author, String provider = 'google'}) async {
    try {
      final uri = Uri.parse('$_cleanBaseUrl/api/search/covers').replace(queryParameters: {
        'title': title,
        if (author != null && author.trim().isNotEmpty) 'author': author.trim(),
        'provider': provider,
      });
      final r = await _authGet(uri, timeout: const Duration(seconds: 25));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final results = data is Map<String, dynamic> ? data['results'] : data;
        if (results is List) {
          final urls = <String>[];
          for (final e in results) {
            if (e is String && e.isNotEmpty) {
              urls.add(e);
            } else if (e is Map<String, dynamic>) {
              final u = (e['cover'] ?? e['url'] ?? e['image']) as String?;
              if (u != null && u.isNotEmpty) urls.add(u);
            }
          }
          return urls;
        }
      }
    } catch (e) {
      debugPrint('[API] searchCovers error: $e');
    }
    return [];
  }

  // ─── Podcast Endpoints ────────────────────────────────────

  /// Search for podcasts (uses iTunes)
  Future<List<dynamic>> searchPodcasts(String query) async {
    try {
      final r = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/search/podcast?term=${Uri.encodeComponent(query)}'),
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is List) return data;
        if (data is Map) {
          if (data['podcasts'] is List) return data['podcasts'] as List<dynamic>;
          for (final key in data.keys) {
            if (data[key] is List) return data[key] as List<dynamic>;
          }
        }
      }
    } catch (e) { debugPrint('searchPodcasts error: $e'); }
    return [];
  }

  /// Create a podcast (add to library from feed URL)
  Future<Map<String, dynamic>?> createPodcast({
    required String libraryId,
    required String folderId,
    required String feedUrl,
    required Map<String, dynamic> podcastData,
    bool autoDownloadEpisodes = false,
    String? autoDownloadSchedule,
  }) async {
    try {
      // ABS search returns: id, artistId, title, artistName, description,
      // descriptionPlain, releaseDate, genres, cover, trackCount, feedUrl,
      // pageUrl, explicit
      final title = podcastData['title'] as String? ?? 'Podcast';

      // Build the podcast path from the library folder + title
      String podcastPath = '';
      try {
        final libs = await getLibraries();
        final lib = libs.firstWhere((l) => l['id'] == libraryId, orElse: () => <String, dynamic>{});
        final folders = lib['folders'] as List?;
        if (folders != null && folders.isNotEmpty) {
          final folder = folders.firstWhere((f) => f['id'] == folderId, orElse: () => folders.first);
          final folderPath = folder['fullPath'] as String? ?? '';
          if (folderPath.isNotEmpty) {
            final cleanTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
            podcastPath = '$folderPath/$cleanTitle';
          }
        }
      } catch (_) {}

      final body = <String, dynamic>{
        'libraryId': libraryId,
        'folderId': folderId,
        'path': podcastPath,
        'media': {
          'metadata': {
            'title': title,
            'author': podcastData['artistName'] ?? '',
            'description': podcastData['description'] ?? podcastData['descriptionPlain'] ?? '',
            'releaseDate': podcastData['releaseDate'] ?? '',
            'genres': podcastData['genres'] ?? [],
            'feedUrl': feedUrl,
            'imageUrl': podcastData['cover'] ?? podcastData['imageUrl'] ?? '',
            'itunesPageUrl': podcastData['pageUrl'] ?? '',
            'itunesId': podcastData['id'],
            'itunesArtistId': podcastData['artistId'],
            'explicit': podcastData['explicit'] ?? false,
            'language': podcastData['language'],
          },
          'autoDownloadEpisodes': autoDownloadEpisodes,
          'autoDownloadSchedule': autoDownloadSchedule ?? '0 0 * * 1',
        },
      };
      final bodyJson = jsonEncode(body);
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/podcasts'),
        body: bodyJson,
        timeout: const Duration(seconds: 30));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('createPodcast error: $e'); }
    return null;
  }

  /// Get a podcast's RSS feed episodes by feed URL
  /// POST /api/podcasts/feed  body: { "rssFeed": "https://..." }
  Future<Map<String, dynamic>?> getPodcastFeed(String rssFeedUrl) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/podcasts/feed'),
        body: jsonEncode({'rssFeed': rssFeedUrl}),
        timeout: const Duration(seconds: 20));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map<String, dynamic>) return data;
      }
    } catch (e) { debugPrint('getPodcastFeed error: $e'); }
    return null;
  }

  /// Get podcast episode download queue for a library
  Future<Map<String, dynamic>?> getEpisodeDownloads(String libraryId) async {
    try {
      final r = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/episode-downloads'),
        timeout: const Duration(seconds: 10));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('getEpisodeDownloads error: $e'); }
    return null;
  }

  /// Download specific podcast episodes
  Future<bool> downloadPodcastEpisodes(String libraryItemId, List<Map<String, dynamic>> episodes) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/podcasts/$libraryItemId/download-episodes'),
        body: jsonEncode(episodes),
        timeout: const Duration(seconds: 30),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('downloadPodcastEpisodes error: $e'); }
    return false;
  }

  /// Check for new podcast episodes across all podcasts in a library
  /// Uses per-podcast check since there's no single library-level endpoint
  Future<bool> checkNewEpisodes(String libraryId) async {
    try {
      // First get all podcast items in the library
      final items = await getLibraryItems(libraryId, limit: 100);
      final results = items?['results'] as List? ?? [];
      if (results.isEmpty) return false;

      // Trigger check on each podcast
      int success = 0;
      for (final item in results) {
        final libItem = item is Map ? (item['libraryItem'] ?? item) : item;
        final id = libItem is Map ? libItem['id'] as String? : null;
        if (id == null) continue;
        try {
          final r = await _authGet(
            Uri.parse('$_cleanBaseUrl/api/podcasts/$id/checknew'),
            timeout: const Duration(seconds: 10));
          if (r.statusCode == 200) success++;
        } catch (_) {}
      }
      return success > 0;
    } catch (e) { debugPrint('checkNewEpisodes error: $e'); }
    return false;
  }

  /// Check a single podcast for new episodes from its RSS feed
  /// GET /api/podcasts/:id/checknew?limit=N
  /// Returns the list of new episodes found, or null on failure.
  Future<List<dynamic>?> checkNewPodcastEpisodes(String podcastId, {int? limit}) async {
    try {
      final limitParam = limit != null ? '?limit=$limit' : '';
      final r = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/podcasts/$podcastId/checknew$limitParam'),
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return (data['episodes'] as List<dynamic>?) ?? [];
      }
    } catch (e) { debugPrint('checkNewPodcastEpisodes error: $e'); }
    return null;
  }

  /// Match a library item with external metadata.
  /// POST /api/items/:id/match
  ///
  /// When the override flags are omitted, the server applies its configured
  /// "Prefer matched metadata" setting.
  Future<Map<String, dynamic>?> matchLibraryItem(
    String itemId, {
    String? title,
    String? author,
    String? provider,
    bool? overrideCover,
    bool? overrideDetails,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (author != null) body['author'] = author;
      if (provider != null) body['provider'] = provider;
      if (overrideCover != null) body['overrideCover'] = overrideCover;
      if (overrideDetails != null) body['overrideDetails'] = overrideDetails;
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/match'),
        body: jsonEncode(body),
      );
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (e) { debugPrint('matchLibraryItem error: $e'); }
    return null;
  }

  /// Update a book's chapters. POST /api/items/:id/chapters
  /// [chapters] is the full ordered list of {id, start, end, title}. Pass an
  /// empty list to clear all chapters. Returns true on a 200 response.
  Future<bool> updateChapters(
      String itemId, List<Map<String, dynamic>> chapters) async {
    try {
      final r = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/chapters'),
        body: jsonEncode({'chapters': chapters}),
        timeout: const Duration(seconds: 20),
      );
      if (r.statusCode != 200) {
        debugPrint('[API] updateChapters failed: ${r.statusCode}');
      }
      return r.statusCode == 200;
    } catch (e) {
      debugPrint('[API] updateChapters error: $e');
      return false;
    }
  }

  /// Look up chapters for an ASIN. The server proxies this to Audnexus.
  /// GET /api/search/chapters?asin=&region=
  /// Returns the raw result map on 200 (chapters + runtime + brand-intro/outro
  /// durations, or {error, stringKey} when the lookup fails), else null.
  Future<Map<String, dynamic>?> searchChapters(String asin, String region) async {
    try {
      final uri = Uri.parse('$_cleanBaseUrl/api/search/chapters')
          .replace(queryParameters: {'asin': asin, 'region': region});
      final r = await _authGet(uri, timeout: const Duration(seconds: 20));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map<String, dynamic>) return data;
      }
      debugPrint('[API] searchChapters failed: ${r.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[API] searchChapters error: $e');
      return null;
    }
  }

  /// Start an embed-metadata task: writes tags/chapters/cover into the audio
  /// files. POST /api/tools/item/:id/embed-metadata?backup=0|1  (admin)
  Future<bool> embedMetadata(String itemId, {bool backup = true}) async {
    try {
      final uri = Uri.parse('$_cleanBaseUrl/api/tools/item/$itemId/embed-metadata')
          .replace(queryParameters: {'backup': backup ? '1' : '0'});
      final r = await _authPost(uri);
      return r.statusCode == 200;
    } catch (e) {
      debugPrint('embedMetadata error: $e');
    }
    return false;
  }

  /// Start an M4B encode task on the server.
  /// POST /api/tools/item/:id/encode-m4b?codec=&bitrate=&channels=
  Future<bool> startM4bEncode(
    String itemId, {
    required String codec,
    required String bitrate,
    required int channels,
  }) async {
    try {
      final uri = Uri.parse('$_cleanBaseUrl/api/tools/item/$itemId/encode-m4b')
          .replace(queryParameters: {
        'codec': codec,
        'bitrate': bitrate,
        'channels': '$channels',
      });
      final r = await _authPost(uri);
      return r.statusCode == 200;
    } catch (e) {
      debugPrint('startM4bEncode error: $e');
    }
    return false;
  }

  /// Update podcast media settings (auto-download, etc.)
  /// PATCH /api/items/:id/media  body: mediaUpdates at the media level
  Future<bool> updatePodcastMedia(String itemId, Map<String, dynamic> mediaUpdates) async {
    try {
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/media'),
        body: jsonEncode(mediaUpdates),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('updatePodcastMedia error: $e'); }
    return false;
  }

  /// Delete a podcast episode
  /// Returns the HTTP status code (0 on exception). 200 = success;
  /// 403 = caller lacks the `delete` permission flag on the server. Callers
  /// should surface 403 with a "needs delete permission" message.
  /// [hard] true also deletes the episode's audio file from the server's disk;
  /// false leaves the file and only drops the episode from the database.
  Future<int> deletePodcastEpisode(String podcastId, String episodeId, {bool hard = false}) async {
    try {
      final r = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/podcasts/$podcastId/episode/$episodeId?hard=${hard ? 1 : 0}'),
      );
      return r.statusCode;
    } catch (e) { debugPrint('deletePodcastEpisode error: $e'); }
    return 0;
  }

  /// Delete a library item (e.g. remove a podcast show). See [deletePodcastEpisode] for status semantics.
  ///
  /// [hard] true deletes the item's folder from the server's disk as well;
  /// false keeps the files, so a later library scan can pick the item back up.
  Future<int> deleteLibraryItem(String itemId, {bool hard = false}) async {
    try {
      final r = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId?hard=${hard ? 1 : 0}'),
      );
      return r.statusCode;
    } catch (e) { debugPrint('deleteLibraryItem error: $e'); }
    return 0;
  }

  /// Delete several library items in one server operation.
  /// Returns the HTTP status code so callers can distinguish a missing
  /// `delete` permission (403) from other failures. Zero means no request was
  /// made or the request threw.
  Future<int> deleteLibraryItems(
    List<String> itemIds, {
    bool hard = false,
  }) async {
    if (itemIds.isEmpty) return 0;
    try {
      final response = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/items/batch/delete?hard=${hard ? 1 : 0}'),
        body: jsonEncode({'libraryItemIds': itemIds}),
        timeout: const Duration(seconds: 60),
      );
      return response.statusCode;
    } catch (e) {
      debugPrint('deleteLibraryItems error: $e');
      return 0;
    }
  }

  /// Quick-match several items using Audiobookshelf's native batch endpoint.
  Future<bool> quickMatchLibraryItems(
    List<String> itemIds, {
    required String provider,
    bool overrideCover = false,
    bool overrideDetails = false,
  }) async {
    if (itemIds.isEmpty) return false;
    try {
      final response = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/items/batch/quickmatch'),
        body: jsonEncode({
          'options': {
            'provider': provider,
            'overrideCover': overrideCover,
            'overrideDetails': overrideDetails,
          },
          'libraryItemIds': itemIds,
        }),
        timeout: const Duration(seconds: 60),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('quickMatchLibraryItems error: $e');
      return false;
    }
  }

  /// Mark several library items finished or unfinished in one request.
  Future<bool> updateLibraryItemsFinished(
    List<String> itemIds, {
    required bool isFinished,
  }) async {
    if (itemIds.isEmpty) return false;
    try {
      final response = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/batch/update'),
        body: jsonEncode([
          for (final itemId in itemIds)
            {'libraryItemId': itemId, 'isFinished': isFinished},
        ]),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updateLibraryItemsFinished error: $e');
      return false;
    }
  }

  // ── Playlists ──────────────────────────────────────────────────────────

  /// GET /api/libraries/:libraryId/playlists
  Future<List<dynamic>> getLibraryPlaylists(String libraryId) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/playlists'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['results'] as List<dynamic>?) ?? [];
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/playlists/:id
  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/playlists/$playlistId'),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/playlists
  Future<Map<String, dynamic>?> createPlaylist(
    String libraryId,
    String name, {
    List<Map<String, dynamic>> items = const [],
  }) async {
    try {
      final resp = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/playlists'),
        body: jsonEncode({
          'libraryId': libraryId,
          'name': name,
          'items': items,
        }),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// PATCH /api/playlists/:id
  Future<Map<String, dynamic>?> updatePlaylist(
    String playlistId, {
    String? name,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (items != null) body['items'] = items;
      final resp = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/playlists/$playlistId'),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// DELETE /api/playlists/:id
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final resp = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/playlists/$playlistId'),
        timeout: const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// POST /api/playlists/:id/item
  Future<Map<String, dynamic>?> addItemToPlaylist(
    String playlistId,
    String libraryItemId, {
    String? episodeId,
  }) async {
    try {
      final body = <String, dynamic>{'libraryItemId': libraryItemId};
      if (episodeId != null) body['episodeId'] = episodeId;
      final resp = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/playlists/$playlistId/item'),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// DELETE /api/playlists/:id/item/:libraryItemId/:episodeId
  Future<Map<String, dynamic>?> removeItemFromPlaylist(
    String playlistId,
    String libraryItemId, {
    String? episodeId,
  }) async {
    try {
      var path = '$_cleanBaseUrl/api/playlists/$playlistId/item/$libraryItemId';
      if (episodeId != null) path += '/$episodeId';
      final resp = await _authDelete(
        Uri.parse(path),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Collections ────────────────────────────────────────────────────────

  /// GET /api/libraries/:libraryId/collections
  Future<List<dynamic>> getLibraryCollections(String libraryId) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/collections'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['results'] as List<dynamic>?) ?? [];
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/collections/:id
  Future<Map<String, dynamic>?> getCollection(String collectionId) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId'),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/collections
  Future<Map<String, dynamic>?> createCollection(
    String libraryId,
    String name, {
    String? description,
    List<String> books = const [],
  }) async {
    try {
      final body = <String, dynamic>{
        'libraryId': libraryId,
        'name': name,
        'books': books,
      };
      if (description != null) body['description'] = description;
      final resp = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/collections'),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// PATCH /api/collections/:id
  Future<Map<String, dynamic>?> updateCollection(
    String collectionId, {
    String? name,
    String? description,
    List<String>? books,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (books != null) body['books'] = books;
      final resp = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId'),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// DELETE /api/collections/:id. Returns the HTTP status code
  /// (0 on exception). 200 = success; 403 = caller lacks the `delete`
  /// permission flag on the server.
  Future<int> deleteCollection(String collectionId) async {
    try {
      final resp = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId'),
        timeout: const Duration(seconds: 10));
      return resp.statusCode;
    } catch (_) {}
    return 0;
  }

  /// POST /api/collections/:id/books
  Future<Map<String, dynamic>?> addBookToCollection(
    String collectionId,
    String libraryItemId,
  ) async {
    try {
      final resp = await _authPost(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId/book'),
        body: jsonEncode({'id': libraryItemId}),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// DELETE /api/collections/:id/books/:libraryItemId
  Future<Map<String, dynamic>?> removeBookFromCollection(
    String collectionId,
    String libraryItemId,
  ) async {
    try {
      final resp = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId/book/$libraryItemId'),
        timeout: const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
