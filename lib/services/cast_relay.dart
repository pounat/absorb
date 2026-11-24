import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lets a cast device play audio by fetching it through this phone.
///
/// A cast device fetches its audio itself, from an address it is handed. That
/// only works when it can reach the address and needs nothing extra to be let
/// in. BookOrbit audio needs a sign-in header, a book narrated from its EPUB
/// is read out of the EPUB here, a downloaded book sits in this phone's
/// storage, and some servers are only reachable from this phone. For those,
/// this answers on the Wi-Fi address while a cast is running and passes each
/// request on, the way an app that plays files off the phone casts them.
///
/// Only what was handed to [urlFor] or [urlForFile] can be fetched, under a
/// secret made new for every cast, and nothing is listening once it stops.
class CastRelay {
  CastRelay._();
  static final CastRelay instance = CastRelay._();

  HttpServer? _server;
  HttpClient? _client;
  String _secret = '';
  String? _host;
  final List<_Source> _sources = [];

  bool get isRunning => _server != null;

  /// Whether [url] is one only this phone can reach.
  static bool isPhoneOnly(String url) {
    final host = Uri.tryParse(url)?.host;
    return host == '127.0.0.1' || host == 'localhost';
  }

  /// Starts answering on the Wi-Fi address. False when the phone has no
  /// address a cast device could reach.
  Future<bool> start() async {
    if (_server != null) return true;
    final host = await _wifiAddress();
    if (host == null) {
      debugPrint('[CastRelay] No Wi-Fi address to answer on');
      return false;
    }
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      final random = Random.secure();
      _secret = List.generate(24, (_) => random.nextInt(36).toRadixString(36)).join();
      _host = host;
      _sources.clear();
      _client = HttpClient()..autoUncompress = false;
      _server = server;
      server.listen(_handle, onError: (Object e) => debugPrint('[CastRelay] $e'));
      debugPrint('[CastRelay] Answering on $host:${server.port}');
      return true;
    } catch (e) {
      debugPrint('[CastRelay] Could not start: $e');
      return false;
    }
  }

  Future<void> stop() async {
    final server = _server;
    if (server == null) return;
    _server = null;
    _host = null;
    _sources.clear();
    _client?.close(force: true);
    _client = null;
    try {
      await server.close(force: true);
    } catch (_) {}
    debugPrint('[CastRelay] Stopped');
  }

  /// The address a cast device should fetch [url] from. That is [url] itself
  /// unless the relay is running and [url] is one only this phone can reach,
  /// or [always] asks for it to go through the phone anyway. [headers] are
  /// added to each request passed on, for a server that wants them.
  String urlFor(String url, {bool always = false, Map<String, String> headers = const {}}) {
    if (_server == null || !(always || isPhoneOnly(url))) return url;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;
    return _address(_Source.url(uri, headers)) ?? url;
  }

  /// The address a cast device should fetch the file at [path] from; null
  /// when the relay isn't running.
  String? urlForFile(String path) => _address(_Source.file(path));

  String? _address(_Source source) {
    final server = _server;
    final host = _host;
    if (server == null || host == null) return null;
    var index = _sources.indexWhere((s) => s.sameAs(source));
    if (index < 0) {
      _sources.add(source);
      index = _sources.length - 1;
    }
    return 'http://$host:${server.port}/$_secret/$index';
  }

  static const _passedOn = ['range', 'if-range', 'accept'];
  static const _passedBack = [
    'content-type',
    'content-length',
    'content-range',
    'accept-ranges',
    'last-modified',
    'etag',
  ];

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final seg = req.uri.pathSegments;
      final index = seg.length == 2 ? int.tryParse(seg[1]) : null;
      if (seg.length != 2 || seg[0] != _secret || index == null || index < 0 || index >= _sources.length) {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      if (req.method != 'GET' && req.method != 'HEAD') {
        res.statusCode = HttpStatus.methodNotAllowed;
        await res.close();
        return;
      }
      res.headers.set('access-control-allow-origin', '*');
      final source = _sources[index];
      final path = source.path;
      if (path != null) {
        await _sendFile(req, path);
        return;
      }
      final client = _client;
      if (client == null) {
        res.statusCode = HttpStatus.serviceUnavailable;
        await res.close();
        return;
      }
      final out = await client.openUrl(req.method, source.uri!);
      source.headers.forEach(out.headers.set);
      for (final name in _passedOn) {
        final value = req.headers.value(name);
        if (value != null) out.headers.set(name, value);
      }
      final got = await out.close();
      res.statusCode = got.statusCode;
      for (final name in _passedBack) {
        final value = got.headers.value(name);
        if (value != null) res.headers.set(name, value);
      }
      await res.addStream(got);
      await res.close();
    } catch (e) {
      // A cast device drops a request whenever it seeks, which lands here.
      try {
        await res.close();
      } catch (_) {}
    }
  }

  static final _rangeHeader = RegExp(r'^bytes=(\d*)-(\d*)$');
  static const _storage = MethodChannel('com.absorb.storage');
  static const _pieceSize = 512 * 1024;

  /// A file in a download folder the user picked has a content address, not
  /// a path, and is read through Android a piece at a time.
  static bool _isContent(String path) => path.startsWith('content://');

  /// Sends the file at [path], or the part of it a Range header asks for: a
  /// cast device seeks by asking for the file from some byte onward.
  Future<void> _sendFile(HttpRequest req, String path) async {
    final res = req.response;
    final content = _isContent(path);
    final file = File(path);
    final int length;
    if (content) {
      length = (await _storage.invokeMethod<int>('contentLength', {'uri': path})) ?? -1;
    } else {
      length = await file.exists() ? await file.length() : -1;
    }
    if (length < 0) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    var start = 0;
    var end = length - 1;
    var partial = false;
    final range = _rangeHeader.firstMatch(req.headers.value('range')?.trim() ?? '');
    if (range != null && length > 0) {
      final from = range.group(1)!;
      final to = range.group(2)!;
      if (from.isEmpty && to.isNotEmpty) {
        start = max(0, length - int.parse(to));
      } else if (from.isNotEmpty) {
        start = int.parse(from);
        if (to.isNotEmpty) end = min(end, int.parse(to));
      }
      if (start > end || start >= length) {
        res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        res.headers.set('content-range', 'bytes */$length');
        await res.close();
        return;
      }
      partial = true;
    }
    res.statusCode = partial ? HttpStatus.partialContent : HttpStatus.ok;
    res.headers.set('accept-ranges', 'bytes');
    res.headers.set('content-type', _fileType(Uri.decodeFull(path)));
    res.headers.set('content-length', '${length == 0 ? 0 : end - start + 1}');
    if (partial) res.headers.set('content-range', 'bytes $start-$end/$length');
    if (req.method != 'HEAD' && length > 0) {
      if (content) {
        var at = start;
        while (at <= end) {
          final piece = await _storage.invokeMethod<Uint8List>('readContent', {
            'uri': path,
            'offset': at,
            'length': min(_pieceSize, end - at + 1),
          });
          if (piece == null || piece.isEmpty) break;
          res.add(piece);
          await res.flush();
          at += piece.length;
        }
      } else {
        await res.addStream(file.openRead(start, end + 1));
      }
    }
    await res.close();
  }

  static String _fileType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.m4b') || p.endsWith('.m4a') || p.endsWith('.mp4') || p.endsWith('.aac')) return 'audio/mp4';
    if (p.endsWith('.ogg') || p.endsWith('.opus')) return 'audio/ogg';
    if (p.endsWith('.flac')) return 'audio/flac';
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'audio/mpeg';
  }

  /// This phone's address on the home network. A VPN's or a mobile carrier's
  /// address is no use: the cast device isn't on those.
  static Future<String?> _wifiAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      String? other;
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!_isHomeNetwork(address.rawAddress)) continue;
          if (interface.name.startsWith('wlan')) return address.address;
          other ??= address.address;
        }
      }
      return other;
    } catch (e) {
      debugPrint('[CastRelay] Could not read the network addresses: $e');
      return null;
    }
  }

  static bool _isHomeNetwork(Uint8List a) {
    if (a.length != 4) return false;
    if (a[0] == 10) return true;
    if (a[0] == 192 && a[1] == 168) return true;
    return a[0] == 172 && a[1] >= 16 && a[1] <= 31;
  }
}

/// One thing a cast device may fetch: an address passed on with [headers],
/// or a file in this phone's storage.
class _Source {
  final Uri? uri;
  final String? path;
  final Map<String, String> headers;

  _Source.url(Uri this.uri, this.headers) : path = null;
  _Source.file(String this.path)
      : uri = null,
        headers = const {};

  bool sameAs(_Source other) => uri == other.uri && path == other.path;
}
