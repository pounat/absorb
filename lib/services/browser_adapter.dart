import 'package:http/http.dart' as http;
import 'dart:convert';

/// Same-origin cookie transport policy shared by the web API and player.
class BrowserAdapter {
  // This is account-state compatibility, never an authentication credential.
  static String loginBody(String serverUrl, String username, String password) =>
      jsonEncode({'serverUrl': serverUrl, 'username': username, 'password': password, 'sessionRouting': true});

  // This public routing label is not a credential. The matching HttpOnly
  // cookie is required, including after restoring a saved account.
  static bool isSessionLabel(String value) =>
      RegExp(r'^browser-cookie@/(?:bookorbit/)?sessions/[A-Za-z0-9_-]{24}$').hasMatch(value);
  static String sessionBase(Uri origin, String token) =>
      currentOrigin(origin) + (isSessionLabel(token) ? token.substring('browser-cookie@'.length) : '');

  static const cookieSentinel = 'browser-cookie';

  static String currentOrigin(Uri uri) {
    if (!const ['https', 'http'].contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw ArgumentError('An HTTP browser origin is required');
    }
    return uri.origin;
  }

  static Uri requestUri(Uri origin, Uri destination) {
    if (!const ['https', 'http'].contains(destination.scheme) ||
        destination.origin != currentOrigin(origin) || destination.userInfo.isNotEmpty ||
        destination.hasFragment || destination.queryParameters.keys.any((key) =>
          const ['token', 'access_token', 'refresh_token', 'accesstoken', 'refreshtoken', 'authorization'].contains(key.toLowerCase()))) {
      throw ArgumentError('Browser requests must use the current origin without credentials in URLs');
    }
    return destination;
  }

  static Map<String, String> requestHeaders(Map<String, String>? headers) =>
      const {'Content-Type': 'application/json'};

  /// The production browser POST path, also executable without a DOM.
  static Future<http.Response> post(Uri origin, Uri destination,
      {http.Client? client, Map<String, String>? headers, Object? body}) {
    final url = requestUri(origin, destination);
    final safeHeaders = requestHeaders(headers);
    // These cookie-authorized mutations still cross the BFF's bounded JSON
    // parser. Do not change empty-body behavior for any other endpoint/native.
    if (body == null && RegExp(r'^(?:/sessions/[A-Za-z0-9_-]{24})?/(?:auth/refresh|logout)$').hasMatch(url.path)) {
      body = '{}';
    }
    return client?.post(url, headers: safeHeaders, body: body) ??
        http.post(url, headers: safeHeaders, body: body);
  }

  static Map<String, dynamic> playbackOptions(String Function(String) probe) {
    const candidates = {
      'audio/mpeg': 'audio/mpeg',
      'audio/mp4': 'audio/mp4; codecs="mp4a.40.2"',
      'audio/ogg': 'audio/ogg; codecs="vorbis"',
      'audio/webm': 'audio/webm; codecs="opus"',
      'audio/flac': 'audio/flac',
      'audio/wav': 'audio/wav; codecs="1"',
    };
    final supported = <String>[];
    for (final entry in candidates.entries) {
      if (const ['probably', 'maybe'].contains(probe(entry.value))) supported.add(entry.key);
    }
    return {
      'mediaPlayer': 'html5',
      'forceDirectPlay': false,
      'forceTranscode': false,
      'supportedMimeTypes': supported,
    };
  }

  static String mediaUrl(Uri origin, String value) {
    final base = Uri.parse(currentOrigin(origin));
    final media = base.resolve(value);
    if (value.startsWith('//') || media.origin != base.origin || media.userInfo.isNotEmpty ||
        media.hasFragment || media.path.toLowerCase().contains('.m3u8') || media.path.startsWith('/hls/')) {
      throw ArgumentError('Unsupported browser media origin or HLS. Choose a browser-playable audio format.');
    }
    final query = Map<String, dynamic>.from(media.queryParametersAll);
    for (final key in query.keys.toList()) {
      if (key.toLowerCase() == 'token') { query.remove(key); continue; }
      if (const ['accesstoken', 'refreshtoken', 'access_token', 'refresh_token', 'authorization'].contains(key.toLowerCase())) {
        throw ArgumentError('Credentials are forbidden in browser media URLs');
      }
    }
    final clean = media.replace(queryParameters: query);
    return query.isEmpty ? clean.toString().replaceFirst(RegExp(r'\?$'), '') : clean.toString();
  }
}

/// One current app-owned session; never transfer a queued increment to a new
/// generation. Allocate before dispatch and never reuse a sequence on timeout.
class BrowserSessionWrites {
  String? _session;
  int? _generation;
  int _sequence = 0;

  void register(Map<String, dynamic> session) {
    final id = session['id'];
    final generation = session['webGeneration'];
    if (id is! String || id.isEmpty || generation is! int ||
        generation <= 0 || generation > 9007199254740991) {
      throw StateError('Playback session is missing browser ownership');
    }
    _session = id;
    _generation = generation;
    _sequence = 0;
  }

  Map<String, dynamic> next(String id) {
    if (_session != id || _generation == null) {
      throw StateError('Playback session expired. Resume from current server progress.');
    }
    return {'webGeneration': _generation, 'webSequence': ++_sequence};
  }

  void invalidate(String id) {
    if (_session == id) { _session = null; _generation = null; }
  }
}
