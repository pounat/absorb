import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the proxy gets the server address and a working access token.
abstract class BookOrbitTokenSource {
  String get upstreamBaseUrl;
  Map<String, String> get upstreamCustomHeaders;

  /// A token that is valid right now, refreshing first when it is about to
  /// expire. Null when there is no session.
  Future<String?> currentAccessToken();

  /// The server turned the last token away. Refresh and hand back the new one,
  /// or null when the session is gone.
  Future<String?> tokenAfterRejection();
}

/// Loopback HTTP proxy for BookOrbit media.
///
/// BookOrbit only takes a Bearer header (no token in the query string) and
/// its access tokens last fifteen minutes. Covers, audio and ebook files are
/// fetched by players, image caches and native code that can't refresh a
/// header, so they get a 127.0.0.1 URL instead and this adds a fresh token to
/// every request on the way through.
///
/// The port and the path secret are kept across launches so cover URLs stay
/// the same and image caches keep hitting. The secret keeps other apps on the
/// device from borrowing the session through the port.
class BookOrbitMediaProxy {
  BookOrbitMediaProxy._();
  static final BookOrbitMediaProxy instance = BookOrbitMediaProxy._();

  static const _portKey = 'bookorbit_proxy_port';
  static const _secretKey = 'bookorbit_proxy_secret';

  HttpServer? _server;
  Future<void>? _starting;
  int _port = 0;
  String _secret = '';
  BookOrbitTokenSource? _source;
  HttpClient? _client;

  bool get isReady => _port > 0 && _secret.isNotEmpty;

  /// The newest BookOrbit client wins: it carries the current server address
  /// (local or remote) and the newest tokens.
  void attach(BookOrbitTokenSource source) => _source = source;

  String get _prefix => 'http://127.0.0.1:$_port/$_secret';

  /// Proxy URL for a server path like `/api/v1/books/5/thumbnail?t=x`.
  String urlFor(String serverPathAndQuery) {
    final path = serverPathAndQuery.startsWith('/')
        ? serverPathAndQuery
        : '/$serverPathAndQuery';
    return '$_prefix$path';
  }

  bool owns(String url) => isReady && url.startsWith(_prefix);

  /// The server URL a proxy URL stands for, for callers that can send their
  /// own headers (downloads that outlive the app).
  String? upstreamUrlFor(String proxyUrl) {
    final source = _source;
    if (source == null || !owns(proxyUrl)) return null;
    return '${source.upstreamBaseUrl}${proxyUrl.substring(_prefix.length)}';
  }

  /// Load the saved port and secret and start listening. Safe to call again;
  /// it rebinds when the platform took the socket away while suspended.
  Future<void> ensureRunning() {
    return _starting ??= _ensure().whenComplete(() => _starting = null);
  }

  Future<void> _ensure() async {
    final server = _server;
    if (server != null) {
      if (await _portAnswers(_port, _secret)) return;
      debugPrint('[BookOrbitProxy] Not answering on $_port, rebinding');
      _server = null;
      try {
        await server.close(force: true);
      } catch (_) {}
    }
    await _start();
  }

  Future<void> _start() async {
    final prefs = await SharedPreferences.getInstance();
    var secret = prefs.getString(_secretKey);
    if (secret == null || secret.length < 16) {
      final rng = Random.secure();
      secret = List.generate(24, (_) => rng.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      await prefs.setString(_secretKey, secret);
    }
    _secret = secret;

    final savedPort = prefs.getInt(_portKey) ?? 0;
    HttpServer? server;
    if (savedPort > 0) {
      try {
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, savedPort);
      } on SocketException catch (e) {
        // Another isolate of this app may already be serving it, in which
        // case the saved URLs still work and there is nothing to do.
        if (await _portAnswers(savedPort, secret)) {
          _port = savedPort;
          debugPrint('[BookOrbitProxy] Port $savedPort already served');
          return;
        }
        debugPrint('[BookOrbitProxy] Port $savedPort busy ($e), picking another');
      }
    }
    server ??= await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (server.port != savedPort) await prefs.setInt(_portKey, server.port);
    _port = server.port;
    _server = server;
    server.listen(
      _handle,
      onError: (Object e) => debugPrint('[BookOrbitProxy] Server error: $e'),
      onDone: () {
        if (identical(_server, server)) _server = null;
        debugPrint('[BookOrbitProxy] Server closed');
      },
    );
    debugPrint('[BookOrbitProxy] Listening on 127.0.0.1:$_port');
  }

  Future<bool> _portAnswers(int port, String secret) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
    try {
      final req = await client.get('127.0.0.1', port, '/$secret/__ping');
      final res = await req.close().timeout(const Duration(seconds: 1));
      await res.drain<void>();
      return res.statusCode == 204;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  HttpClient get _http {
    return _client ??= HttpClient()
      ..autoUncompress = false
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 30);
  }

  static const _forwardRequestHeaders = [
    HttpHeaders.rangeHeader,
    HttpHeaders.ifRangeHeader,
    HttpHeaders.ifNoneMatchHeader,
    HttpHeaders.ifModifiedSinceHeader,
    HttpHeaders.acceptHeader,
  ];

  static const _forwardResponseHeaders = [
    HttpHeaders.contentTypeHeader,
    HttpHeaders.contentLengthHeader,
    HttpHeaders.contentRangeHeader,
    HttpHeaders.acceptRangesHeader,
    HttpHeaders.etagHeader,
    HttpHeaders.lastModifiedHeader,
    HttpHeaders.cacheControlHeader,
    'content-disposition',
  ];

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    final path = req.uri.path;
    if (!path.startsWith('/$_secret/')) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    final serverPath = path.substring(_secret.length + 1);
    if (serverPath == '/__ping') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    if (req.method != 'GET' && req.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    final source = _source;
    if (source == null) {
      res.statusCode = HttpStatus.serviceUnavailable;
      await res.close();
      return;
    }

    final query = req.uri.hasQuery ? '?${req.uri.query}' : '';
    final upstream = Uri.parse('${source.upstreamBaseUrl}$serverPath$query');

    HttpClientRequest? upstreamReq;
    try {
      var token = await source.currentAccessToken();
      upstreamReq = await _open(req, upstream, source, token);
      var upstreamRes = await upstreamReq.close();
      if (upstreamRes.statusCode == HttpStatus.unauthorized) {
        await upstreamRes.drain<void>().catchError((_) {});
        token = await source.tokenAfterRejection();
        if (token != null) {
          upstreamReq = await _open(req, upstream, source, token);
          upstreamRes = await upstreamReq.close();
        }
      }

      res.statusCode = upstreamRes.statusCode;
      for (final name in _forwardResponseHeaders) {
        final value = upstreamRes.headers.value(name);
        if (value != null) res.headers.set(name, value);
      }
      if (upstreamRes.statusCode >= 400) {
        debugPrint('[BookOrbitProxy] ${upstreamRes.statusCode} for $serverPath');
      }
      if (req.method == 'HEAD') {
        await upstreamRes.drain<void>().catchError((_) {});
        await res.close();
        return;
      }
      try {
        await res.addStream(upstreamRes);
        await res.close();
      } catch (_) {
        // The player hung up (seek, skip, stop). Drop the upstream body too.
        upstreamReq.abort();
      }
    } catch (e) {
      debugPrint('[BookOrbitProxy] Upstream failed for $serverPath: $e');
      upstreamReq?.abort();
      try {
        res.statusCode = HttpStatus.badGateway;
        await res.close();
      } catch (_) {}
    }
  }

  Future<HttpClientRequest> _open(
    HttpRequest incoming,
    Uri upstream,
    BookOrbitTokenSource source,
    String? token,
  ) async {
    final out = await _http.openUrl(incoming.method, upstream);
    out.followRedirects = true;
    source.upstreamCustomHeaders.forEach(out.headers.set);
    if (token != null && token.isNotEmpty) {
      out.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    out.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    for (final name in _forwardRequestHeaders) {
      final value = incoming.headers.value(name);
      if (value != null) out.headers.set(name, value);
    }
    return out;
  }
}
