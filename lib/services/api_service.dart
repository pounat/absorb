import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApiService {
  static String appVersion = '1.3.0'; // fallback; overwritten by initVersion()

  /// Device country code (e.g. "us", "uk", "de") derived from the platform locale.
  static String get _region {
    final locale = PlatformDispatcher.instance.locale;
    final code = (locale.countryCode ?? 'us').toLowerCase();
    // Audnexus uses "uk" not "gb"
    return code == 'gb' ? 'uk' : code;
  }

  /// Call once at startup to read the real version from pubspec via package_info_plus.
  static Future<void> initVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (_) {}
  }

  final String baseUrl;
  final String token;
  final Map<String, String> customHeaders;

  // Device info — set once at app start
  static String deviceManufacturer = '';
  static String deviceModel = '';
  static String deviceId = '';
  static int deviceSdkInt = 0;

  /// Generate or load a persistent unique device ID
  static Future<void> initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('absorb_device_id');
    if (id == null || id.isEmpty) {
      // Generate a unique ID for this install
      id = 'absorb-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${(DateTime.now().microsecond * 31337).toRadixString(36)}';
      await prefs.setString('absorb_device_id', id);
    }
    deviceId = id;
  }

  ApiService({required this.baseUrl, required this.token, this.customHeaders = const {}});

  Map<String, String> get _headers => {
        ...customHeaders,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Public headers for image/audio requests (no Content-Type needed).
  /// Use this for CachedNetworkImage, Image.network, AudioSource.uri, etc.
  Map<String, String> get mediaHeaders => {
        ...customHeaders,
        'Authorization': 'Bearer $token',
      };

  String get _cleanBaseUrl =>
      baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

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
        headers: {...customHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as Map<String, dynamic>, 200);
      }
      return (null, response.statusCode);
    } catch (e) {
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
      final response = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['libraries'] as List?) ?? [];
      }
    } catch (e) {
      // ignore
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

      final response = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/personalized')
            .replace(queryParameters: query.isEmpty ? null : query),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Build a cover image URL for a library item.
  String getCoverUrl(String itemId, {int width = 400, int? updatedAt}) {
    var url = '$_cleanBaseUrl/api/items/$itemId/cover?width=$width&token=$token';
    if (updatedAt != null) url += '&ts=$updatedAt';
    return url;
  }

  /// Get current user info including all mediaProgress.
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$_cleanBaseUrl/api/me'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Get user's listening stats.
  Future<Map<String, dynamic>?> getListeningStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_cleanBaseUrl/api/me/listening-stats'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Get user's listening sessions (paginated).
  Future<Map<String, dynamic>?> getListeningSessions({int page = 0, int itemsPerPage = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_cleanBaseUrl/api/me/listening-sessions?itemsPerPage=$itemsPerPage&page=$page'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

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
      final response = await http.get(
        Uri.parse(
          '$_cleanBaseUrl/api/libraries/$libraryId/series'
          '?page=$page&limit=$limit&sort=$sort&desc=$desc',
        ),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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
      final response = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId?include=filterdata'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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
      final response = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/authors'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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

  /// Get full author details including description/bio.
  Future<Map<String, dynamic>?> getAuthorById(String authorId, {String? libraryId}) async {
    try {
      var url = '$_cleanBaseUrl/api/authors/$authorId?include=items';
      if (libraryId != null) url += '&library=$libraryId';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[API] getAuthorById error: $e');
    }
    return null;
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
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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
        'forceDirectPlay': forceDirectPlay,
        'forceTranscode': forceTranscode,
        'mediaPlayer': 'unknown',
        'supportedMimeTypes': [
          'audio/flac',
          'audio/mpeg',
          'audio/mp4',
          'audio/ogg',
          'audio/aac',
        ],
      };
      if (startOffset != null && startOffset > 0) body['startOffset'] = startOffset;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

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
    final url = '$_cleanBaseUrl$contentUrl?token=$token';
    debugPrint('[ABS] Track URL: $url');
    return url;
  }

  /// Sync playback progress.
  /// POST /api/session/:id/sync
  Future<void> syncPlaybackSession(
    String sessionId, {
    required double currentTime,
    required double duration,
  }) async {
    try {
      await http.post(
        Uri.parse('$_cleanBaseUrl/api/session/$sessionId/sync'),
        headers: _headers,
        body: jsonEncode({
          'currentTime': currentTime,
          'timeListened': 15,
          'duration': duration,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Close a playback session.
  /// POST /api/session/:id/close
  Future<void> closePlaybackSession(String sessionId) async {
    try {
      await http.post(
        Uri.parse('$_cleanBaseUrl/api/session/$sessionId/close'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.get(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.patch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 10));
      debugPrint('[API] updateProgress response: ${resp.statusCode} ${resp.body}');
    } catch (e) {
      debugPrint('[API] updateProgress error: $e');
      rethrow;
    }
  }

  /// Update ebook reading progress on the server.
  /// PATCH /api/me/progress/:id
  Future<void> updateEbookProgress(
    String itemId, {
    required String ebookLocation,
    required double ebookProgress,
  }) async {
    try {
      final body = jsonEncode({
        'ebookLocation': ebookLocation,
        'ebookProgress': ebookProgress,
        'isFinished': ebookProgress >= 1.0,
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
    } catch (e) {
      debugPrint('[API] updateEbookProgress error: $e');
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
      final resp = await http.delete(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      await http.delete(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

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
      await http.patch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$progressPath'),
        headers: _headers,
        body: jsonEncode({
          'currentTime': 0,
          'progress': 0,
          'isFinished': false,
          'hideFromContinueListening': true,
          'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(const Duration(seconds: 10));

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
      String itemId, String episodeId) async {
    try {
      final url = '$_cleanBaseUrl/api/items/$itemId/play/$episodeId';
      debugPrint('[ABS] Starting episode session: POST $url');
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'deviceInfo': {
            'clientName': 'Absorb',
            'clientVersion': appVersion,
            'deviceId': deviceId,
            'deviceName': '${deviceManufacturer.isNotEmpty ? "$deviceManufacturer " : ""}$deviceModel'.trim(),
            'manufacturer': deviceManufacturer,
            'model': deviceModel,
          },
          'forceDirectPlay': true,
          'forceTranscode': false,
          'mediaPlayer': 'unknown',
          'supportedMimeTypes': [
            'audio/flac',
            'audio/mpeg',
            'audio/mp4',
            'audio/ogg',
            'audio/aac',
          ],
        }),
      ).timeout(const Duration(seconds: 20));

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
      final resp = await http.get(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId/$episodeId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      await http.patch(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId/$episodeId'),
        headers: _headers,
        body: jsonEncode({
          'currentTime': currentTime,
          'duration': duration,
          'progress': duration > 0 ? currentTime / duration : 0,
          'isFinished': isFinished,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[API] updateEpisodeProgress error: $e');
    }
  }

  /// DELETE /api/me/progress/:itemId/:episodeId
  Future<bool> deleteEpisodeProgress(String itemId, String episodeId) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_cleanBaseUrl/api/me/progress/$itemId/$episodeId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/recent-episodes?limit=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
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
      final response = await http.get(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId?expanded=1&include=progress'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Get a single series with its books.
  Future<Map<String, dynamic>?> getSeries(String seriesId, {String? libraryId}) async {
    try {
      Map<String, dynamic>? seriesMeta;
      
      // Get series metadata
      if (libraryId != null) {
        final metaResp = await http.get(
          Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/series/$seriesId'),
          headers: _headers,
        ).timeout(const Duration(seconds: 15));
        if (metaResp.statusCode == 200) {
          seriesMeta = jsonDecode(metaResp.body) as Map<String, dynamic>;
        }
      }
      
      // Get books in the series via library items filter
      // ABS filter format: series.<base64(seriesId)>
      if (libraryId != null) {
        final filterValue = base64Encode(utf8.encode(seriesId));
        final url = '$_cleanBaseUrl/api/libraries/$libraryId/items?filter=series.$filterValue&sort=media.metadata.series.sequence&limit=100&collapseseries=0';
        final itemsResp = await http.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(const Duration(seconds: 15));
        if (itemsResp.statusCode == 200) {
          final data = jsonDecode(itemsResp.body) as Map<String, dynamic>;
          final results = data['results'] as List<dynamic>? ?? [];
          return {
            'id': seriesId,
            'name': seriesMeta?['name'] ?? '',
            'books': results,
          };
        }
      }
    } catch (_) {
    }
    return null;
  }

  /// Search a library. Returns { book: [...], series: [...], authors: [...] }
  Future<Map<String, dynamic>?> searchLibrary(
    String libraryId,
    String query, {
    int limit = 25,
  }) async {
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final response = await http.get(
        Uri.parse(
          '$_cleanBaseUrl/api/libraries/$libraryId/search?q=$encoded&limit=$limit',
        ),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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

  /// Search Audible via the audiobookshelf server for an ASIN by title+author,
  /// then fetch the rating from Audnexus. Used as a fallback when the book's
  /// stored ASIN returns no rating.
  Future<Map<String, dynamic>?> searchAudibleRating(
      String title, String? author) async {
    try {
      // Use the ABS server's search endpoint to query Audible for the book.
      final response = await http.get(
        Uri.parse(
          '$_cleanBaseUrl/api/search/covers?title=${Uri.encodeQueryComponent(title)}'
          '&author=${Uri.encodeQueryComponent(author ?? '')}'
          '&provider=audible&region=$_region',
        ),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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

  // ─── Admin Endpoints ──────────────────────────────────────

  /// Get all users (admin only)
  Future<List<dynamic>> getUsers() async {
    try {
      final r = await http.get(Uri.parse('$_cleanBaseUrl/api/users'), headers: _headers)
          .timeout(const Duration(seconds: 15));
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
      final r = await http.get(Uri.parse('$_cleanBaseUrl/api/users/online'), headers: _headers)
          .timeout(const Duration(seconds: 15));
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
      final r = await http.get(
        Uri.parse('$_cleanBaseUrl/api/sessions?itemsPerPage=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
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
      final r = await http.get(Uri.parse('$_cleanBaseUrl/api/backups'), headers: _headers)
          .timeout(const Duration(seconds: 15));
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
      final r = await http.post(Uri.parse('$_cleanBaseUrl/api/backups'), headers: _headers)
          .timeout(const Duration(seconds: 60));
      return r.statusCode == 200;
    } catch (e) { debugPrint('createBackup error: $e'); }
    return false;
  }

  /// Scan a library's folders (admin only)
  Future<bool> scanLibrary(String libraryId) async {
    try {
      final r = await http.post(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/scan'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      return r.statusCode == 200;
    } catch (e) { debugPrint('scanLibrary error: $e'); }
    return false;
  }

  /// Match all items in a library (admin only)
  Future<bool> matchLibrary(String libraryId) async {
    try {
      final r = await http.post(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/match'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      return r.statusCode == 200;
    } catch (e) { debugPrint('matchLibrary error: $e'); }
    return false;
  }

  /// Get library stats (admin only)
  Future<Map<String, dynamic>?> getLibraryStats(String libraryId) async {
    try {
      final r = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/stats'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('getLibraryStats error: $e'); }
    return null;
  }

  /// Purge server cache (admin only)
  Future<bool> purgeCache() async {
    try {
      final r = await http.post(Uri.parse('$_cleanBaseUrl/api/cache/purge'), headers: _headers)
          .timeout(const Duration(seconds: 30));
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
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'password': password,
        'type': type,
      };
      if (permissions != null) body['permissions'] = permissions;
      if (librariesAccessible != null) body['librariesAccessible'] = librariesAccessible;
      final r = await http.post(
        Uri.parse('$_cleanBaseUrl/api/users'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('createUser error: $e'); }
    return null;
  }

  /// Get a single user with full details including mediaProgress (admin only)
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final r = await http.get(
        Uri.parse('$_cleanBaseUrl/api/users/$userId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('getUser error: $e'); }
    return null;
  }

  /// Update a user (admin only)
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final r = await http.patch(
        Uri.parse('$_cleanBaseUrl/api/users/$userId'),
        headers: _headers,
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (e) { debugPrint('updateUser error: $e'); }
    return false;
  }

  /// Delete a user (admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      final r = await http.delete(
        Uri.parse('$_cleanBaseUrl/api/users/$userId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (e) { debugPrint('deleteUser error: $e'); }
    return false;
  }

  /// Update a library item's media metadata (admin/root only).
  /// Uses POST /api/items/:id/match which requires update permission.
  Future<bool> updateItemMedia(String itemId, Map<String, dynamic> media) async {
    try {
      final r = await http.patch(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/media'),
        headers: _headers,
        body: jsonEncode({'metadata': media}),
      ).timeout(const Duration(seconds: 15));
      debugPrint('[API] updateItemMedia $itemId -> ${r.statusCode}: ${r.body}');
      return r.statusCode == 200;
    } catch (e) { debugPrint('updateItemMedia error: $e'); }
    return false;
  }

  /// Upload a cover image URL for a library item (admin only)
  Future<bool> updateItemCoverUrl(String itemId, String url) async {
    try {
      final r = await http.post(
        Uri.parse('$_cleanBaseUrl/api/items/$itemId/cover'),
        headers: _headers,
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(seconds: 30));
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
      final r = await http.get(
        Uri.parse('$_cleanBaseUrl/api/search/podcast?term=${Uri.encodeComponent(query)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
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
      final r = await http.post(
        Uri.parse('$_cleanBaseUrl/api/podcasts'),
        headers: _headers,
        body: bodyJson,
      ).timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('createPodcast error: $e'); }
    return null;
  }

  /// Get a podcast's RSS feed episodes by feed URL
  /// POST /api/podcasts/feed  body: { "rssFeed": "https://..." }
  Future<Map<String, dynamic>?> getPodcastFeed(String rssFeedUrl) async {
    try {
      final r = await http.post(
        Uri.parse('$_cleanBaseUrl/api/podcasts/feed'),
        headers: _headers,
        body: jsonEncode({'rssFeed': rssFeedUrl}),
      ).timeout(const Duration(seconds: 20));
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
      final r = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/episode-downloads'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('getEpisodeDownloads error: $e'); }
    return null;
  }

  /// Download specific podcast episodes
  Future<bool> downloadPodcastEpisodes(String libraryItemId, List<Map<String, dynamic>> episodes) async {
    try {
      final r = await http.post(
        Uri.parse('$_cleanBaseUrl/api/podcasts/$libraryItemId/download-episodes'),
        headers: _headers,        body: jsonEncode(episodes),
      ).timeout(const Duration(seconds: 30));
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
          final r = await http.get(
            Uri.parse('$_cleanBaseUrl/api/podcasts/$id/checknew'),
            headers: _headers,
          ).timeout(const Duration(seconds: 10));
          if (r.statusCode == 200) success++;
        } catch (_) {}
      }
      return success > 0;
    } catch (e) { debugPrint('checkNewEpisodes error: $e'); }
    return false;
  }

  /// Delete a podcast episode
  Future<bool> deletePodcastEpisode(String podcastId, String episodeId) async {
    try {
      final r = await http.delete(
        Uri.parse('$_cleanBaseUrl/api/podcasts/$podcastId/episode/$episodeId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (e) { debugPrint('deletePodcastEpisode error: $e'); }
    return false;
  }

  // ── Playlists ──────────────────────────────────────────────────────────

  /// GET /api/libraries/:libraryId/playlists
  Future<List<dynamic>> getLibraryPlaylists(String libraryId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/playlists'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
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
      final resp = await http.get(
        Uri.parse('$_cleanBaseUrl/api/playlists/$playlistId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.post(
        Uri.parse('$_cleanBaseUrl/api/playlists'),
        headers: _headers,
        body: jsonEncode({
          'libraryId': libraryId,
          'name': name,
          'items': items,
        }),
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.patch(
        Uri.parse('$_cleanBaseUrl/api/playlists/$playlistId'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// DELETE /api/playlists/:id
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_cleanBaseUrl/api/playlists/$playlistId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.post(
        Uri.parse('$_cleanBaseUrl/api/playlists/$playlistId/item'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.delete(
        Uri.parse(path),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.get(
        Uri.parse('$_cleanBaseUrl/api/libraries/$libraryId/collections'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
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
      final resp = await http.get(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.post(
        Uri.parse('$_cleanBaseUrl/api/collections'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.patch(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// DELETE /api/collections/:id
  Future<bool> deleteCollection(String collectionId) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.post(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId/book'),
        headers: _headers,
        body: jsonEncode({'id': libraryItemId}),
      ).timeout(const Duration(seconds: 10));
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
      final resp = await http.delete(
        Uri.parse('$_cleanBaseUrl/api/collections/$collectionId/book/$libraryItemId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
