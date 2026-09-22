import 'dart:io';
import 'dart:math';

/// Serves one file to the WebView over the loopback interface. The page then
/// fetches the epub straight from disk, instead of Dart reading the whole
/// file into memory, base64-encoding it in chunks and pushing every chunk
/// across the bridge to be decoded again: on a 322MB book that took about
/// twelve seconds before the first page could even start rendering.
///
/// One random path per server, loopback only, closed with the viewer.
class LocalBookServer {
  LocalBookServer(this.file);

  final File file;
  final String _token = _randomToken();
  HttpServer? _server;

  String? get url => _server == null
      ? null
      : 'http://127.0.0.1:${_server!.port}/$_token/book.epub';

  Future<String> start() async {
    if (_server == null) {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen(_handle, onError: (_) {});
      _server = server;
    }
    return url!;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final wanted = req.uri.path == '/$_token/book.epub' &&
          (req.method == 'GET' || req.method == 'HEAD');
      if (!wanted) {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      final length = await file.length();
      res.headers.set(HttpHeaders.accessControlAllowOriginHeader, '*');
      res.headers.set(HttpHeaders.contentTypeHeader, 'application/epub+zip');
      res.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      var start = 0;
      var end = length - 1;
      final range = req.headers.value(HttpHeaders.rangeHeader);
      final m = range == null
          ? null
          : RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range.trim());
      if (m != null && (m.group(1)!.isNotEmpty || m.group(2)!.isNotEmpty)) {
        if (m.group(1)!.isEmpty) {
          start = length - int.parse(m.group(2)!);
        } else {
          start = int.parse(m.group(1)!);
          if (m.group(2)!.isNotEmpty) end = int.parse(m.group(2)!);
        }
        if (start < 0) start = 0;
        if (end > length - 1) end = length - 1;
        if (start >= length || end < start) {
          res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          res.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$length');
          await res.close();
          return;
        }
        res.statusCode = HttpStatus.partialContent;
        res.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$length',
        );
      }
      res.contentLength = end - start + 1;
      if (req.method == 'HEAD') {
        await res.close();
        return;
      }
      await res.addStream(file.openRead(start, end + 1));
      await res.close();
    } catch (_) {
      try {
        await res.close();
      } catch (_) {}
    }
  }

  static String _randomToken() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
