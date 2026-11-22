import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'audio_file_duration.dart';
import 'ebook_cache.dart';
import 'media_overlay.dart';
import 'narration_service.dart';
import 'remote_zip.dart';
import '../utils/percent_escapes.dart';

/// What the player needs to stream a narration: one loopback URL per audio
/// file, and the book laid out the way a download's is.
typedef NarrationStreamSource = ({
  List<String> urls,
  double duration,
  List<Map<String, dynamic>> chapters,
  Map<String, dynamic> session,
});

class _Track {
  final RemoteZipEntry entry;
  final String mime;
  int? dataOffset;

  _Track(this.entry, this.mime);

  int get size => entry.size;
}

class _Book {
  final String itemId;
  final Uri url;
  final List<_Track> tracks;
  final Directory dir;

  _Book(this.itemId, this.url, this.tracks, this.dir);
}

/// Plays an Audiobookshelf narrated EPUB without downloading it first, the
/// way the watch does. Audiobookshelf only sees an ebook, so there is no
/// audio to stream; instead each audio file inside the EPUB is played as a
/// byte range of the EPUB on the server. The player gets a 127.0.0.1 URL per
/// file, and this moves each range it asks for to where that file sits in
/// the EPUB, with a fresh token. A file the EPUB keeps compressed can't be
/// read in pieces, so it is pulled out whole the first time it plays.
///
/// BookOrbit streams narration itself, but can't find a file whose name the
/// EPUB writes with certain escapes (a comma as %2C); those books come
/// through here too, from the EPUB BookOrbit serves.
///
/// The port and path secret are kept across launches like the BookOrbit
/// proxy's; the secret keeps other apps on the device off the session.
class NarrationStream {
  NarrationStream._();
  static final NarrationStream instance = NarrationStream._();

  static const _portKey = 'narration_stream_port';
  static const _secretKey = 'narration_stream_secret';

  HttpServer? _server;
  Future<void>? _starting;
  int _port = 0;
  String _secret = '';
  ApiService? _api;
  Map<String, String>? _headers;
  DateTime _headersAt = DateTime(0);
  HttpClient? _client;
  final Map<String, _Book> _books = {};
  // By book and file rather than on the book, so opening the book again
  // while a file is still coming down waits on that pull instead of
  // starting a second one into the same file.
  final Map<String, Future<File>> _pulls = {};

  String get _prefix => 'http://127.0.0.1:$_port/$_secret';

  bool owns(String url) => _port > 0 && url.startsWith(_prefix);

  /// Gets [itemId]'s narration ready to stream from the start of the track
  /// that [startTime] falls in. Null when it can't: not an Audiobookshelf
  /// narrated EPUB, or the server couldn't be read.
  Future<NarrationStreamSource?> open(ApiService api, String itemId, {double startTime = 0}) async {
    if (api.isBookOrbit || kIsWeb) return null;
    final started = DateTime.now();
    RemoteZip? zip;
    try {
      await ensureRunning();
      _api = api;
      _headers = null;
      final item = await api.getLibraryItem(itemId);
      final ino = resolveEbookFile(item)?['ino'] as String?;
      if (item == null || ino == null) {
        debugPrint('[NarrationStream] $itemId has no ebook file to stream from');
        return null;
      }
      final file = Uri.parse(api.buildFileUrl(itemId, ino));
      final url = Uri(scheme: file.scheme, userInfo: file.userInfo, host: file.host, port: file.port, path: file.path);
      zip = await RemoteZip.open(url, headers: await _freshHeaders());
      final narration = NarrationService.instance;
      var overlay = await narration.localOverlay(itemId) ?? await narration.probe(api, item);
      if (overlay == null || overlay.tracks.isEmpty) {
        debugPrint('[NarrationStream] $itemId holds no narration');
        return null;
      }
      final tracks = _tracksIn(zip, overlay.tracks);
      final opened = zip;
      overlay = await narration.timedForStream(itemId, overlay, (i) async {
        final t = tracks[i];
        if (!t.entry.stored) return null;
        final at = t.dataOffset ??= await opened.dataOffset(t.entry);
        return audioDuration((o, n) => opened.bytes(at + o, n), t.size);
      });

      final urls = await _serve(itemId, url, tracks, overlay.tracks, _trackAt(overlay.tracks, startTime));
      final chapters = overlay.chapters();
      debugPrint('[NarrationStream] $itemId ready in ${DateTime.now().difference(started).inMilliseconds}ms: '
          '${tracks.length} file(s)${_packed(tracks)}, ${overlay.duration.toStringAsFixed(0)}s');
      return (
        urls: urls,
        duration: overlay.duration,
        chapters: chapters,
        session: {
          'duration': overlay.duration,
          'chapters': chapters,
          'audioTracks': overlay.audioTracks((t) => t.href),
        },
      );
    } catch (e) {
      debugPrint('[NarrationStream] $itemId could not be streamed: $e');
      return null;
    } finally {
      zip?.close();
    }
  }

  /// Serves [tracks], the narration's audio files inside the EPUB at [epub],
  /// from that EPUB's bytes, for a server that has the EPUB but can't hand
  /// out a file inside it. One loopback URL per track, in order; null when
  /// the EPUB can't be read in ranges or a file isn't in it.
  Future<List<String>?> serveFromEpub(ApiService api, String itemId, Uri epub, List<OverlayTrack> tracks,
      {double startTime = 0}) async {
    if (kIsWeb || tracks.isEmpty) return null;
    final started = DateTime.now();
    RemoteZip? zip;
    try {
      await ensureRunning();
      _api = api;
      _headers = null;
      zip = await RemoteZip.open(epub, headers: await _freshHeaders());
      final found = _tracksIn(zip, tracks);
      final urls = await _serve(itemId, epub, found, tracks, _trackAt(tracks, startTime));
      debugPrint('[NarrationStream] $itemId ready from its EPUB in ${DateTime.now().difference(started).inMilliseconds}ms: '
          '${found.length} file(s)${_packed(found)}');
      return urls;
    } catch (e) {
      debugPrint('[NarrationStream] $itemId could not be streamed from its EPUB: $e');
      return null;
    } finally {
      zip?.close();
    }
  }

  List<_Track> _tracksIn(RemoteZip zip, List<OverlayTrack> tracks) => [
        for (final t in tracks)
          _Track(
            _entryFor(zip, t.href) ?? (throw RemoteZipException('${t.href} is not in the EPUB')),
            t.mediaType.isNotEmpty ? t.mediaType : _mimeFor(t.href),
          ),
      ];

  static String _packed(List<_Track> tracks) {
    final packed = tracks.where((t) => !t.entry.stored).length;
    return packed > 0 ? ', $packed compressed' : '';
  }

  /// Makes [itemId] the book being served and hands back its URLs.
  Future<List<String>> _serve(String itemId, Uri url, List<_Track> tracks, List<OverlayTrack> overlay, int first) async {
    final base = await getTemporaryDirectory();
    final root = Directory('${base.path}/narration_stream');
    // Pulled files are only kept for the book that is streaming.
    if (root.existsSync()) {
      for (final d in root.listSync().whereType<Directory>()) {
        if (d.path.split(Platform.pathSeparator).last != _safe(itemId)) {
          try {
            d.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    }
    final dir = Directory('${root.path}/${_safe(itemId)}')..createSync(recursive: true);
    final book = _Book(itemId, url, tracks, dir);
    _books
      ..clear()
      ..[itemId] = book;
    // A compressed file has to come down whole before it plays, so the one
    // playback starts in comes down now rather than on the player's clock.
    if (!tracks[first].entry.stored) await _pull(book, first);
    return [
      for (var i = 0; i < tracks.length; i++)
        '$_prefix/${Uri.encodeComponent(itemId)}/$i/${Uri.encodeComponent(_fileName(overlay[i].href))}',
    ];
  }

  static int _trackAt(List<OverlayTrack> tracks, double seconds) {
    for (var i = tracks.length - 1; i > 0; i--) {
      if (seconds >= tracks[i].start) return i;
    }
    return 0;
  }

  static RemoteZipEntry? _entryFor(RemoteZip zip, String href) {
    final plain = undoPathEscapes(href);
    return zip.entry(href) ??
        zip.entry(plain) ??
        zip.entries.where((e) => MediaOverlay.sameDoc(e.name, plain)).firstOrNull;
  }

  static String _fileName(String href) => undoPercentEscapes(href.split('/').last);

  static String _safe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  static String _mimeFor(String href) {
    final name = href.toLowerCase();
    if (name.endsWith('.mp3')) return 'audio/mpeg';
    if (name.endsWith('.ogg') || name.endsWith('.oga') || name.endsWith('.opus')) return 'audio/ogg';
    if (name.endsWith('.wav')) return 'audio/wav';
    if (name.endsWith('.flac')) return 'audio/flac';
    return 'audio/mp4';
  }

  Future<Map<String, String>> _freshHeaders({bool renew = false}) async {
    final api = _api;
    if (api == null) return const {};
    final cached = _headers;
    if (!renew && cached != null && DateTime.now().difference(_headersAt) < const Duration(minutes: 5)) {
      return cached;
    }
    final headers = await api.renewedMediaHeaders();
    _headers = headers;
    _headersAt = DateTime.now();
    return headers;
  }

  HttpClient get _http => _client ??= HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 15)
    ..idleTimeout = const Duration(seconds: 30);

  /// A GET of bytes [start] to [end] of the EPUB, asked again with a renewed
  /// token when the server turns the first one away.
  Future<(HttpClientRequest, HttpClientResponse)> _upstream(Uri url, int start, int end) async {
    Future<(HttpClientRequest, HttpClientResponse)> send(Map<String, String> headers) async {
      final req = await _http.getUrl(url);
      req.followRedirects = true;
      headers.forEach(req.headers.set);
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
      return (req, await req.close());
    }

    var (req, res) = await send(await _freshHeaders());
    if (res.statusCode == HttpStatus.unauthorized) {
      await res.drain<void>().catchError((_) {});
      (req, res) = await send(await _freshHeaders(renew: true));
    }
    if (res.statusCode != HttpStatus.partialContent) {
      req.abort();
      throw RemoteZipException('server answered ${res.statusCode} to a range request');
    }
    return (req, res);
  }

  Future<Uint8List> _bytes(Uri url, int start, int count) async {
    final (_, res) = await _upstream(url, start, start + count - 1);
    final out = BytesBuilder(copy: false);
    await for (final chunk in res) {
      out.add(chunk);
    }
    return out.takeBytes();
  }

  /// Where a file's data starts, read from its local header the first time.
  Future<int> _dataOffset(_Book book, _Track t) async {
    final known = t.dataOffset;
    if (known != null) return known;
    final h = ByteData.sublistView(await _bytes(book.url, t.entry.headerOffset, 30));
    if (h.getUint32(0, Endian.little) != 0x04034b50) {
      throw RemoteZipException('bad local header for ${t.entry.name}');
    }
    return t.dataOffset = t.entry.headerOffset + 30 + h.getUint16(26, Endian.little) + h.getUint16(28, Endian.little);
  }

  /// A compressed file pulled out of the EPUB whole, once; later asks share
  /// the first pull.
  Future<File> _pull(_Book book, int index) {
    final key = '${book.itemId}/$index';
    final running = _pulls[key];
    if (running != null) return running;
    final pull = () async {
      final t = book.tracks[index];
      final out = File('${book.dir.path}/track-$index');
      if (out.existsSync() && out.lengthSync() == t.size) return out;
      final started = DateTime.now();
      final at = await _dataOffset(book, t);
      final (_, res) = await _upstream(book.url, at, at + t.entry.compressedSize - 1);
      final part = File('${out.path}.part');
      final sink = part.openWrite();
      try {
        Stream<List<int>> body = res.timeout(const Duration(seconds: 60));
        if (t.entry.method == 8) body = body.transform(ZLibDecoder(raw: true));
        await sink.addStream(body);
      } finally {
        await sink.close();
      }
      final got = part.lengthSync();
      if (got != t.size) {
        part.deleteSync();
        throw RemoteZipException('${t.entry.name} came out $got bytes, not ${t.size}');
      }
      await part.rename(out.path);
      debugPrint('[NarrationStream] pulled ${t.entry.name} (${t.size} bytes) in '
          '${DateTime.now().difference(started).inMilliseconds}ms');
      return out;
    }();
    _pulls[key] = pull;
    pull.then<void>((_) {}, onError: (Object _) => _pulls.remove(key));
    return pull;
  }

  /// Load the saved port and secret and start listening. Safe to call again;
  /// it rebinds when the platform took the socket away while suspended.
  Future<void> ensureRunning() => _starting ??= _ensure().whenComplete(() => _starting = null);

  Future<void> _ensure() async {
    final server = _server;
    if (server != null) {
      if (await _portAnswers(_port, _secret)) return;
      debugPrint('[NarrationStream] Not answering on $_port, rebinding');
      _server = null;
      try {
        await server.close(force: true);
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    var secret = prefs.getString(_secretKey);
    if (secret == null || secret.length < 16) {
      final rng = Random.secure();
      secret = List.generate(24, (_) => rng.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_secretKey, secret);
    }
    _secret = secret;
    final savedPort = prefs.getInt(_portKey) ?? 0;
    HttpServer? bound;
    if (savedPort > 0) {
      try {
        bound = await HttpServer.bind(InternetAddress.loopbackIPv4, savedPort);
      } on SocketException catch (e) {
        debugPrint('[NarrationStream] Port $savedPort busy ($e), picking another');
      }
    }
    bound ??= await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (bound.port != savedPort) await prefs.setInt(_portKey, bound.port);
    _port = bound.port;
    _server = bound;
    bound.listen(
      _handle,
      onError: (Object e) => debugPrint('[NarrationStream] Server error: $e'),
      onDone: () {
        if (identical(_server, bound)) _server = null;
      },
    );
    debugPrint('[NarrationStream] Listening on 127.0.0.1:$_port');
  }

  Future<bool> _portAnswers(int port, String secret) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
    try {
      final req = await client.get('127.0.0.1', port, '/$secret/__ping');
      final res = await req.close().timeout(const Duration(seconds: 1));
      await res.drain<void>();
      return res.statusCode == HttpStatus.noContent;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  @visibleForTesting
  Future<void> stop() async {
    final server = _server;
    _server = null;
    _books.clear();
    _pulls.clear();
    await server?.close(force: true);
  }

  /// `bytes=a-b`, `bytes=a-` or `bytes=-n` as an inclusive span of a file
  /// [size] long. Null for no range; (-1, -1) for one that can't be met.
  static (int, int)? parseRange(String? header, int size) {
    if (header == null) return null;
    final m = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
    if (m == null) return null;
    final a = m.group(1)!, b = m.group(2)!;
    if (a.isEmpty && b.isEmpty) return null;
    if (a.isEmpty) {
      final n = int.parse(b);
      if (n <= 0) return (-1, -1);
      return (max(0, size - n), size - 1);
    }
    final start = int.parse(a);
    final end = b.isEmpty ? size - 1 : min(int.parse(b), size - 1);
    if (start >= size || end < start) return (-1, -1);
    return (start, end);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    final parts = req.uri.pathSegments;
    if (parts.isEmpty || parts.first != _secret) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (parts.length == 2 && parts[1] == '__ping') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    final book = parts.length >= 3 ? _books[parts[1]] : null;
    final index = parts.length >= 3 ? int.tryParse(parts[2]) : null;
    if (book == null || index == null || index < 0 || index >= book.tracks.length) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    if (req.method != 'GET' && req.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    final t = book.tracks[index];
    final range = parseRange(req.headers.value(HttpHeaders.rangeHeader), t.size);
    if (range != null && range.$1 < 0) {
      res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
      res.headers.set(HttpHeaders.contentRangeHeader, 'bytes */${t.size}');
      await res.close();
      return;
    }
    final start = range?.$1 ?? 0;
    final end = range?.$2 ?? t.size - 1;

    HttpClientRequest? upstreamReq;
    try {
      // Opened before the reply starts, so a failure can still say so.
      Stream<List<int>> body;
      if (t.entry.stored) {
        final at = await _dataOffset(book, t);
        final (r, upstreamRes) = await _upstream(book.url, at + start, at + end);
        upstreamReq = r;
        body = upstreamRes;
      } else {
        body = (await _pull(book, index)).openRead(start, end + 1);
      }
      res.statusCode = range == null ? HttpStatus.ok : HttpStatus.partialContent;
      res.headers.set(HttpHeaders.contentTypeHeader, t.mime);
      res.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      res.headers.contentLength = end - start + 1;
      if (range != null) res.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/${t.size}');
      if (req.method == 'HEAD') {
        upstreamReq?.abort();
        await res.close();
        return;
      }
      // The next file is likely to be asked for soon; a compressed one gets a
      // head start on its pull.
      if (index + 1 < book.tracks.length && !book.tracks[index + 1].entry.stored) {
        unawaited(_pull(book, index + 1).then<void>((_) {}, onError: (Object _) {}));
      }
      try {
        await res.addStream(body);
        await res.close();
      } catch (_) {
        // The player hung up (seek, skip, stop). Drop the upstream body too.
        upstreamReq?.abort();
      }
    } catch (e) {
      debugPrint('[NarrationStream] ${book.itemId} file $index failed: $e');
      upstreamReq?.abort();
      try {
        res.statusCode = HttpStatus.badGateway;
        await res.close();
      } catch (_) {}
    }
  }
}
