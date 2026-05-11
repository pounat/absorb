import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApiService {
  static String appVersion = '1.3.0'; // fallback; overwritten by initVersion()

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
    } catch (_) {}
  }

  final String baseUrl;
  String _accessToken;
  String? _refreshToken;
  final bool _isLegacyToken;
  final Map<String, String> customHeaders;

  /// Called after a successful token refresh so the auth layer can persist.
  void Function(String newAccessToken, String? newRefreshToken)? onTokensRefreshed;

  /// Called when refresh fails and the user must re-login.
  VoidCallback? onAuthExpired;

  // Concurrency lock for refresh
  Completer<bool>? _refreshCompleter;

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
    this.onAuthExpired,
  })  : _accessToken = token,
        _refreshToken = refreshToken,
        _isLegacyToken = isLegacyToken;

  /// Current access token (for external use like cover URLs, socket auth).
  String get token => _accessToken;

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

  String get _cleanBaseUrl =>
      baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  /// Attempt to refresh the access token using the refresh token.
  /// Returns true if successful. Uses a lock so concurrent 401s only
  /// trigger one refresh.
  Future<bool> _refreshAccessToken() async {
    if (_isLegacyToken || _refreshToken == null) {
      debugPrint('[API] Cannot refresh: isLegacy=$_isLegacyToken, hasRefreshToken=${_refreshToken != null}');
      return false;
    }

    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    _refreshCompleter = Completer<bool>();
    try {
      final response = await http.post(
        Uri.parse('$_cleanBaseUrl/api/authorize'),
        headers: {
          ...customHeaders,
          'Authorization': 'Bearer $_refreshToken',
          'x-return-tokens': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newAccess != null) {
          _accessToken = newAccess;
          if (newRefresh != null) _refreshToken = newRefresh;
          onTokensRefreshed?.call(_accessToken, _refreshToken);
          debugPrint('[API] Token refreshed successfully');
          _refreshCompleter!.complete(true);
          return true;
        }
      }
      debugPrint('[API] Token refresh failed: ${response.statusCode}');
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      debugPrint('[API] Token refresh error: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Make an authenticated GET request, retrying once on 401 with a refreshed token.
  Future<http.Response> _authGet(Uri url, {Map<String, String>? headers, Duration timeout = const Duration(seconds: 15)}) async {

    final h = headers ?? _headers;
    var response = await http.get(url, headers: h).timeout(timeout);
    if (response.statusCode == 401) {
      debugPrint('[API] 401 on GET ${url.path} - isLegacy=$_isLegacyToken, hasRefresh=${_refreshToken != null}, tokenLen=${_accessToken.length}');
    }
    if (response.statusCode == 401 && !_isLegacyToken) {
      if (await _refreshAccessToken()) {
        final refreshedHeaders = Map<String, String>.from(h)
          ..['Authorization'] = 'Bearer $_accessToken';
        response = await http.get(url, headers: refreshedHeaders).timeout(timeout);
      }
      if (response.statusCode == 401) onAuthExpired?.call();
    }
    return response;
  }

  /// Make an authenticated POST request, retrying once on 401 with a refreshed token.
  Future<http.Response> _authPost(Uri url, {Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 15)}) async {

    final h = headers ?? _headers;
    var response = await http.post(url, headers: h, body: body).timeout(timeout);
    if (response.statusCode == 401 && !_isLegacyToken) {
      if (await _refreshAccessToken()) {
        final refreshedHeaders = Map<String, String>.from(h)
          ..['Authorization'] = 'Bearer $_accessToken';
        response = await http.post(url, headers: refreshedHeaders, body: body).timeout(timeout);
      }
      if (response.statusCode == 401) onAuthExpired?.call();
    }
    return response;
  }

  /// Make an authenticated PATCH request, retrying once on 401 with a refreshed token.
  Future<http.Response> _authPatch(Uri url, {Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 15)}) async {
    final h = headers ?? _headers;
    var response = await http.patch(url, headers: h, body: body).timeout(timeout);
    if (response.statusCode == 401 && !_isLegacyToken) {
      if (await _refreshAccessToken()) {
        final refreshedHeaders = Map<String, String>.from(h)
          ..['Authorization'] = 'Bearer $_accessToken';
        response = await http.patch(url, headers: refreshedHeaders, body: body).timeout(timeout);
      }
      if (response.statusCode == 401) onAuthExpired?.call();
    }
    return response;
  }

  /// Make an authenticated DELETE request, retrying once on 401 with a refreshed token.
  Future<http.Response> _authDelete(Uri url, {Map<String, String>? headers, Duration timeout = const Duration(seconds: 15)}) async {
    final h = headers ?? _headers;
    var response = await http.delete(url, headers: h).timeout(timeout);
    if (response.statusCode == 401 && !_isLegacyToken) {
      if (await _refreshAccessToken()) {
        final refreshedHeaders = Map<String, String>.from(h)
          ..['Authorization'] = 'Bearer $_accessToken';
        response = await http.delete(url, headers: refreshedHeaders).timeout(timeout);
      }
      if (response.statusCode == 401) onAuthExpired?.call();
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
        headers: {...customHeaders, 'Content-Type': 'application/json', 'x-return-tokens': 'true'},
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
        return data['serverVersion'] as String?;
      }
    } catch (_) {}
    return null;
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
  Future<List<dynamic>> getPersonalizedView(
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
    return [];
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
          '?page=$page&limit=$limit&sort=$sort&desc=$desc';
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

  /// Build a cover image URL for a library item.
  String getCoverUrl(String itemId, {int? width = 400, int? updatedAt}) {
    var url = '$_cleanBaseUrl/api/items/$itemId/cover?token=$token';
    if (width != null) url += '&width=$width';
    if (updatedAt != null) url += '&ts=$updatedAt';
    return url;
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
  /// and returns the updated author. Returns null if no match or on error.
  /// GET /api/authors/:id/match?q=...&region=...
  Future<Map<String, dynamic>?> matchAuthor(
    String authorId, {
    required String q,
    String region = 'us',
  }) async {
    try {
      final url = '$_cleanBaseUrl/api/authors/$authorId/match'
          '?q=${Uri.encodeQueryComponent(q)}'
          '&region=${Uri.encodeQueryComponent(region)}';
      final r = await _authGet(Uri.parse(url));
      debugPrint('[API] matchAuthor $authorId -> ${r.statusCode}: ${r.body}');
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        // Server returns the updated author directly, or { author: {...} }
        if (data['author'] is Map) return data['author'] as Map<String, dynamic>;
        if (data.containsKey('updated')) return data;
        return data;
      }
    } catch (e) { debugPrint('matchAuthor error: $e'); }
    return null;
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

  /// Start a playback session for a library item.
  /// POST /api/items/:id/play
  /// Returns the full session object including audioTracks with contentUrl.
  Future<Map<String, dynamic>?> startPlaybackSession(String itemId, {String? episodeId, bool forceDirectPlay = false, bool forceTranscode = false, double? startOffset}) async {
    try {
      final epPath = episodeId != null ? '/$episodeId' : '';
      final url = '$_cleanBaseUrl/api/items/$itemId/play$epPath';
      debugPrint('[ABS] Starting playback session: POST $url (forceDirectPlay: $forceDirectPlay, forceTranscode: $forceTranscode)');
      final body = <String, dynamic>{
        'deviceInfo': {
          'clientName': 'Absorb',
          'clientVersion': appVersion,
          'deviceId': deviceId,
          'deviceName': '${deviceManufacturer.isNotEmpty ? "$deviceManufacturer " : ""}$deviceModel'.trim(),
          'manufacturer': deviceManufacturer,
          'model': deviceModel,
        },
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

  /// Build a full audio track URL from a contentUrl returned by the play session.
  String buildTrackUrl(String contentUrl) {
    if (contentUrl.startsWith('http')) return contentUrl;
    // ABS servers with ROUTER_BASE_PATH set return contentUrls that already
    // include the base path (e.g. "/abs/public/session/.../track/0"). If the
    // user's server URL also includes that base path, blindly concatenating
    // would double it ("/abs/abs/..."). Detect and use origin only.
    final baseUri = Uri.parse(_cleanBaseUrl);
    final basePath = baseUri.path;
    if (basePath.isNotEmpty && contentUrl.startsWith('$basePath/')) {
      final url = '${baseUri.origin}$contentUrl?token=$token';
      debugPrint('[ABS] Track URL: $url');
      return url;
    }
    final url = '$_cleanBaseUrl$contentUrl?token=$token';
    debugPrint('[ABS] Track URL: $url');
    return url;
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
          'duration': duration,
          'progress': duration > 0 ? currentTime / duration : 0,
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
        'progress': duration > 0 ? currentTime / duration : 0,
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

  /// DELETE /api/me/progress/:id — fully remove progress entry
  Future<bool> deleteProgress(String itemId) async {
    try {
      final progressPath = itemId.length > 36
          ? '${itemId.substring(0, 36)}/${itemId.substring(37)}'
          : itemId;
      final resp = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        timeout: const Duration(seconds: 10));
      debugPrint('[API] deleteProgress response: ${resp.statusCode} ${resp.body}');
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('[API] deleteProgress error: $e');
      return false;
    }
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
          'deviceInfo': {
            'clientName': 'Absorb',
            'clientVersion': appVersion,
            'deviceId': deviceId,
            'deviceName': '${deviceManufacturer.isNotEmpty ? "$deviceManufacturer " : ""}$deviceModel'.trim(),
            'manufacturer': deviceManufacturer,
            'model': deviceModel,
          },
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
          'progress': duration > 0 ? currentTime / duration : 0,
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
  Future<List<dynamic>> getRecentEpisodes(String libraryId, {int limit = 25}) async {
    try {
      final resp = await _authGet(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/recent-episodes?limit=$limit'),
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
  /// Uses GET /api/me/item/:id which includes bookmarks in the response.
  Future<List<Map<String, dynamic>>?> getServerBookmarks(String itemId) async {
    try {
      // Try mediaProgress first
      final progress = await getItemProgress(itemId);
      if (progress != null) {
        final bookmarks = progress['bookmarks'] as List<dynamic>?;
        if (bookmarks != null && bookmarks.isNotEmpty) {
          return bookmarks.whereType<Map<String, dynamic>>().toList();
        }
      }
      // Fall back to user object - bookmarks may be stored there
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

  /// Get a single series with its books (paginated).
  /// If [onPageLoaded] is provided, it's called after each page with the
  /// cumulative results and total so the UI can show books as they arrive.
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
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/users'), headers: _headers)
          ;
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
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/users/online'), headers: _headers)
          ;
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

  /// Get all backups (admin only)
  Future<List<dynamic>> getBackups() async {
    try {
      final r = await _authGet(Uri.parse('$_cleanBaseUrl/api/backups'), headers: _headers)
          ;
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return (data['backups'] as List<dynamic>?) ?? [];
      }
    } catch (e) { debugPrint('getBackups error: $e'); }
    return [];
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

  /// Update a library item's media metadata (admin/root only).
  /// Uses POST /api/items/:id/match which requires update permission.
  Future<bool> updateItemMedia(String itemId, Map<String, dynamic> media) async {
    try {
      final r = await _authPatch(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/media'),
        body: jsonEncode({'metadata': media}),
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

  /// Match a library item with external metadata
  /// POST /api/items/:id/match
  Future<Map<String, dynamic>?> matchLibraryItem(String itemId, {String? title, String? author, String? provider}) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (author != null) body['author'] = author;
      if (provider != null) body['provider'] = provider;
      body['overrideCover'] = true;
      body['overrideDetails'] = true;
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
  Future<bool> deletePodcastEpisode(String podcastId, String episodeId) async {
    try {
      final r = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/podcasts/$podcastId/episode/$episodeId'),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('deletePodcastEpisode error: $e'); }
    return false;
  }

  /// Delete a library item (e.g. remove a podcast show)
  Future<bool> deleteLibraryItem(String itemId) async {
    try {
      final r = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId'),
      );
      return r.statusCode == 200;
    } catch (e) { debugPrint('deleteLibraryItem error: $e'); }
    return false;
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

  /// DELETE /api/collections/:id
  Future<bool> deleteCollection(String collectionId) async {
    try {
      final resp = await _authDelete(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId'),
        timeout: const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {}
    return false;
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
