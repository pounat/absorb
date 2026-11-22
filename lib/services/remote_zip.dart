import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// One file inside a [RemoteZip].
class RemoteZipEntry {
  final String name;
  final int method;
  final int compressedSize;
  final int size;
  final int headerOffset;
  final Uint8List centralRecord;
  final int offsetFieldAt;
  final bool offsetInZip64;
  int? _dataOffset;

  RemoteZipEntry._(this.name, this.method, this.compressedSize, this.size, this.headerOffset,
      this.centralRecord, this.offsetFieldAt, this.offsetInZip64);

  bool get stored => method == 0;
}

class RemoteZipException implements Exception {
  final String message;
  RemoteZipException(this.message);
  @override
  String toString() => 'RemoteZipException: $message';
}

/// A zip (an EPUB) on a server, read with HTTP range requests: its index and
/// any one file, without downloading the rest.
class RemoteZip {
  final Uri url;
  final Map<String, String> headers;
  final http.Client _client;
  final int length;
  final List<RemoteZipEntry> entries;
  final int centralOffset;

  RemoteZip._(this.url, this.headers, this._client, this.length, this.entries, this.centralOffset);

  RemoteZipEntry? entry(String name) {
    for (final e in entries) {
      if (e.name == name) return e;
    }
    return null;
  }

  static Future<(Uint8List, int)> _range(
    http.Client client,
    Uri url,
    Map<String, String> headers,
    String range,
  ) async {
    final req = http.Request('GET', url)
      ..headers.addAll(headers)
      ..headers['Range'] = 'bytes=$range';
    final res = await client.send(req).timeout(const Duration(seconds: 30));
    if (res.statusCode != 206) {
      // Not a range: it may be the whole file coming, so hang up on it.
      await res.stream.listen(null).cancel().catchError((_) {});
      throw RemoteZipException('server answered ${res.statusCode} to a range request');
    }
    final total = int.tryParse((res.headers['content-range'] ?? '').split('/').last) ?? -1;
    final body = await res.stream.toBytes().timeout(const Duration(minutes: 5));
    return (body, total);
  }

  Future<Uint8List> bytes(int start, int count) async {
    if (count <= 0) return Uint8List(0);
    final (body, _) = await _range(_client, url, headers, '$start-${start + count - 1}');
    if (body.length != count) throw RemoteZipException('short read: ${body.length} of $count bytes');
    return body;
  }

  /// Reads the zip's index from the end of the file. The length comes first:
  /// not every server takes a range counted from the end (BookOrbit sends
  /// the whole file for `bytes=-N`).
  static Future<RemoteZip> open(Uri url, {Map<String, String> headers = const {}, http.Client? client}) async {
    final c = client ?? http.Client();
    final (_, total) = await _range(c, url, headers, '0-0');
    if (total <= 0) throw RemoteZipException('server sent no file length');
    final (tail, _) = await _range(c, url, headers, '${max(0, total - (22 + 65535))}-${total - 1}');
    final tailStart = total - tail.length;
    final eocd = _lastIndexOf(tail, 0x06054b50);
    if (eocd < 0) throw RemoteZipException('no zip end record');
    final t = ByteData.sublistView(tail);
    final count = t.getUint16(eocd + 10, Endian.little);
    var cdSize = t.getUint32(eocd + 12, Endian.little);
    var cdOffset = t.getUint32(eocd + 16, Endian.little);
    if (count == 0xFFFF || cdSize == 0xFFFFFFFF || cdOffset == 0xFFFFFFFF) {
      final locAt = eocd - 20;
      if (locAt < 0 || t.getUint32(locAt, Endian.little) != 0x07064b50) {
        throw RemoteZipException('zip64 locator missing');
      }
      final z64Offset = t.getUint64(locAt + 8, Endian.little);
      final z64 = z64Offset >= tailStart
          ? ByteData.sublistView(tail, z64Offset - tailStart)
          : ByteData.sublistView(await _rangeBytes(c, url, headers, z64Offset, 56));
      cdSize = z64.getUint64(40, Endian.little);
      cdOffset = z64.getUint64(48, Endian.little);
    }
    final cd = cdOffset >= tailStart
        ? Uint8List.sublistView(tail, cdOffset - tailStart, cdOffset - tailStart + cdSize)
        : await _rangeBytes(c, url, headers, cdOffset, cdSize);
    return RemoteZip._(url, headers, c, total, _parseCentral(cd), cdOffset);
  }

  static Future<Uint8List> _rangeBytes(
      http.Client c, Uri url, Map<String, String> headers, int start, int count) async {
    final (body, _) = await _range(c, url, headers, '$start-${start + count - 1}');
    return body;
  }

  static int _lastIndexOf(Uint8List b, int signature) {
    final d = ByteData.sublistView(b);
    for (var i = b.length - 22; i >= 0; i--) {
      if (d.getUint32(i, Endian.little) == signature) return i;
    }
    return -1;
  }

  static List<RemoteZipEntry> _parseCentral(Uint8List cd) {
    final d = ByteData.sublistView(cd);
    final out = <RemoteZipEntry>[];
    var p = 0;
    while (p + 46 <= cd.length && d.getUint32(p, Endian.little) == 0x02014b50) {
      final method = d.getUint16(p + 10, Endian.little);
      var csize = d.getUint32(p + 20, Endian.little);
      var usize = d.getUint32(p + 24, Endian.little);
      final nameLen = d.getUint16(p + 28, Endian.little);
      final extraLen = d.getUint16(p + 30, Endian.little);
      final commentLen = d.getUint16(p + 32, Endian.little);
      var offset = d.getUint32(p + 42, Endian.little);
      final name = String.fromCharCodes(cd.sublist(p + 46, p + 46 + nameLen));
      var offsetFieldAt = 42;
      var inZip64 = false;
      // Zip64 extra field: the 64-bit values replace whichever 32-bit ones are
      // maxed out, in this order.
      var x = p + 46 + nameLen;
      final xEnd = x + extraLen;
      while (x + 4 <= xEnd) {
        final id = d.getUint16(x, Endian.little);
        final len = d.getUint16(x + 2, Endian.little);
        if (id == 0x0001) {
          var q = x + 4;
          if (usize == 0xFFFFFFFF) {
            usize = d.getUint64(q, Endian.little);
            q += 8;
          }
          if (csize == 0xFFFFFFFF) {
            csize = d.getUint64(q, Endian.little);
            q += 8;
          }
          if (offset == 0xFFFFFFFF) {
            offset = d.getUint64(q, Endian.little);
            offsetFieldAt = q - p;
            inZip64 = true;
          }
        }
        x += 4 + len;
      }
      final end = p + 46 + nameLen + extraLen + commentLen;
      out.add(RemoteZipEntry._(_utf8Name(cd.sublist(p + 46, p + 46 + nameLen), name), method, csize,
          usize, offset, Uint8List.fromList(cd.sublist(p, end)), offsetFieldAt, inZip64));
      p = end;
    }
    return out;
  }

  static String _utf8Name(List<int> bytes, String fallback) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return fallback;
    }
  }

  /// Where [e]'s data starts, read from its local header.
  Future<int> dataOffset(RemoteZipEntry e) async {
    final known = e._dataOffset;
    if (known != null) return known;
    final h = ByteData.sublistView(await bytes(e.headerOffset, 30));
    if (h.getUint32(0, Endian.little) != 0x04034b50) throw RemoteZipException('bad local header for ${e.name}');
    final at = e.headerOffset + 30 + h.getUint16(26, Endian.little) + h.getUint16(28, Endian.little);
    e._dataOffset = at;
    return at;
  }

  /// The whole of one (small) file.
  Future<Uint8List> read(RemoteZipEntry e) async {
    final raw = await bytes(await dataOffset(e), e.compressedSize);
    if (e.method == 0) return raw;
    if (e.method == 8) return Uint8List.fromList(ZLibDecoder(raw: true).convert(raw));
    throw RemoteZipException('${e.name} uses compression method ${e.method}');
  }

  /// Streams one file into [out], inflating it when it is compressed.
  Future<void> download(RemoteZipEntry e, File out, {void Function(int done)? onBytes}) async {
    final start = await dataOffset(e);
    final req = http.Request('GET', url)
      ..headers.addAll(headers)
      ..headers['Range'] = 'bytes=$start-${start + e.compressedSize - 1}';
    final res = await _client.send(req).timeout(const Duration(seconds: 30));
    if (res.statusCode != 206) {
      await res.stream.drain<void>().catchError((_) {});
      throw RemoteZipException('server answered ${res.statusCode} to a range request');
    }
    final part = File('${out.path}.part');
    final sink = part.openWrite();
    var done = 0;
    try {
      Stream<List<int>> body = res.stream.timeout(const Duration(seconds: 60)).map((chunk) {
        done += chunk.length;
        onBytes?.call(done);
        return chunk;
      });
      if (e.method == 8) body = body.transform(ZLibDecoder(raw: true));
      await sink.addStream(body);
    } finally {
      await sink.close();
    }
    if (out.existsSync()) await out.delete();
    await part.rename(out.path);
  }

  /// A copy of the zip holding only the files [keep] accepts, made from the
  /// server's bytes as they are (no recompression). Neighbouring files come
  /// down in one request.
  Future<void> writeCopy(File out, bool Function(RemoteZipEntry e) keep) async {
    final ordered = [...entries]..sort((a, b) => a.headerOffset.compareTo(b.headerOffset));
    final spans = <(RemoteZipEntry, int, int)>[];
    for (var i = 0; i < ordered.length; i++) {
      final e = ordered[i];
      final end = i + 1 < ordered.length ? ordered[i + 1].headerOffset : centralOffset;
      if (keep(e)) spans.add((e, e.headerOffset, end));
    }
    final part = File('${out.path}.part');
    final raf = await part.open(mode: FileMode.write);
    final central = BytesBuilder(copy: false);
    var written = 0;
    try {
      var i = 0;
      while (i < spans.length) {
        // Batch spans that follow one another on the server, up to 8MB.
        var j = i;
        while (j + 1 < spans.length && spans[j + 1].$2 == spans[j].$3 && spans[j + 1].$3 - spans[i].$2 < 8 << 20) {
          j++;
        }
        final data = await bytes(spans[i].$2, spans[j].$3 - spans[i].$2);
        for (var k = i; k <= j; k++) {
          final (e, s, end) = spans[k];
          final rel = s - spans[i].$2;
          await raf.writeFrom(data, rel, rel + (end - s));
          final rec = Uint8List.fromList(e.centralRecord);
          final rd = ByteData.sublistView(rec);
          if (e.offsetInZip64) {
            rd.setUint64(e.offsetFieldAt, written, Endian.little);
          } else {
            rd.setUint32(e.offsetFieldAt, written, Endian.little);
          }
          central.add(rec);
          written += end - s;
        }
        i = j + 1;
      }
      final cd = central.takeBytes();
      await raf.writeFrom(cd);
      final eocd = ByteData(22)
        ..setUint32(0, 0x06054b50, Endian.little)
        ..setUint16(8, min(spans.length, 0xFFFF), Endian.little)
        ..setUint16(10, min(spans.length, 0xFFFF), Endian.little)
        ..setUint32(12, cd.length, Endian.little)
        ..setUint32(16, written, Endian.little);
      await raf.writeFrom(eocd.buffer.asUint8List());
    } finally {
      await raf.close();
    }
    if (out.existsSync()) await out.delete();
    await part.rename(out.path);
  }

  void close() => _client.close();
}
