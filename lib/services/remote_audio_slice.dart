import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A track of a streamed book: where to fetch it and how long it runs.
class RemoteTrack {
  final String url;
  final Map<String, String> headers;
  final double durationSeconds;
  final String? mimeType;
  const RemoteTrack({
    required this.url,
    required this.headers,
    required this.durationSeconds,
    this.mimeType,
  });
}

/// A local file holding part of a track, and where the wanted moment sits
/// inside it. The caller deletes [path].
class AudioSlice {
  final String path;
  final double startWithin;
  const AudioSlice(this.path, this.startWithin);
}

/// Pulls a stretch of a streamed track down as a small local file the native
/// decoders can open, without fetching the whole book. M4B files are read
/// through their own index so the bytes for the exact samples come down and
/// get rewrapped as a plain AAC stream; MP3 files are cut by byte estimate,
/// which is only as exact as the file's bitrate is steady.
class RemoteAudioSlicer {
  static const int _headBytes = 64 * 1024;
  static const int _mp3MarginBytes = 96 * 1024;
  static final Map<String, Mp4Index> _indexCache = {};

  static Future<AudioSlice> fetch(
    RemoteTrack track,
    double startSeconds,
    double durationSeconds, {
    required String tmpDir,
  }) async {
    final head = await _range(track, 0, _headBytes - 1);
    final kind = _sniff(head.bytes, track.mimeType, track.url);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    if (kind == _Kind.mp4) {
      final index = _indexCache[track.url] ??=
          await _loadIndex(track, head.bytes, head.totalSize);
      final path = '$tmpDir${Platform.pathSeparator}absorb_slice_$stamp.aac';
      return _sliceMp4(track, index, startSeconds, durationSeconds, path);
    }
    if (kind == _Kind.mp3) {
      final path = '$tmpDir${Platform.pathSeparator}absorb_slice_$stamp.mp3';
      return _sliceMp3(track, head.bytes, head.totalSize, startSeconds, durationSeconds, path);
    }
    throw StateError('unsupported track format ${track.mimeType ?? ''}');
  }

  static void forget(String url) => _indexCache.remove(url);

  // MP4

  static Future<Mp4Index> _loadIndex(RemoteTrack track, Uint8List head, int total) async {
    // Walk the top-level atoms until moov turns up. It is usually at the
    // front, but a file that was never "faststarted" keeps it after mdat,
    // which for a 20 hour book is gigabytes away, so hop by atom size.
    var offset = 0;
    var buf = head;
    var bufStart = 0;
    for (var hops = 0; hops < 32; hops++) {
      if (offset + 16 > bufStart + buf.length || offset < bufStart) {
        final r = await _range(track, offset, offset + 15);
        buf = r.bytes;
        bufStart = offset;
      }
      final bd = ByteData.sublistView(buf, offset - bufStart);
      var size = bd.getUint32(0).toDouble();
      final type = String.fromCharCodes(buf.sublist(offset - bufStart + 4, offset - bufStart + 8));
      var headerLen = 8;
      if (size == 1) {
        size = bd.getUint64(8).toDouble();
        headerLen = 16;
      } else if (size == 0) {
        size = (total - offset).toDouble();
      }
      if (type == 'moov') {
        final end = offset + size.toInt() - 1;
        final Uint8List moov;
        if (end < bufStart + buf.length) {
          moov = Uint8List.sublistView(buf, offset - bufStart, end + 1 - bufStart);
        } else {
          moov = (await _range(track, offset, end)).bytes;
        }
        debugPrint('[Slice] moov ${moov.length} bytes at $offset of $total');
        return Mp4Index.parse(moov);
      }
      if (size < headerLen) break;
      offset += size.toInt();
      if (offset >= total) break;
    }
    throw StateError('no moov atom');
  }

  static Future<AudioSlice> _sliceMp4(RemoteTrack track, Mp4Index index,
      double startSeconds, double durationSeconds, String path) async {
    final samples = index.samplesBetween(startSeconds, startSeconds + durationSeconds);
    if (samples.isEmpty) throw StateError('window past the end of the track');
    final firstOffset = index.sampleOffset(samples.first);
    final lastOffset = index.sampleOffset(samples.last) + index.sampleSize(samples.last) - 1;
    final bytes = (await _range(track, firstOffset, lastOffset)).bytes;
    final out = BytesBuilder(copy: false);
    for (final s in samples) {
      final off = index.sampleOffset(s) - firstOffset;
      final size = index.sampleSize(s);
      if (off < 0 || off + size > bytes.length) break;
      out.add(Adts.header(index.config, size));
      out.add(Uint8List.sublistView(bytes, off, off + size));
    }
    await File(path).writeAsBytes(out.takeBytes(), flush: true);
    final startWithin = (startSeconds - index.sampleTime(samples.first)).clamp(0.0, durationSeconds);
    debugPrint('[Slice] mp4 ${samples.length} samples, ${lastOffset - firstOffset + 1} bytes, '
        'start ${startWithin.toStringAsFixed(2)}s into the slice');
    return AudioSlice(path, startWithin);
  }

  // MP3

  static Future<AudioSlice> _sliceMp3(RemoteTrack track, Uint8List head, int total,
      double startSeconds, double durationSeconds, String path) async {
    final dur = track.durationSeconds > 0 ? track.durationSeconds : 1.0;
    final audioStart = Mp3Probe.audioStart(head);
    final toc = Mp3Probe.xingToc(head, audioStart);
    double fracAt(double t) => (t / dur).clamp(0.0, 1.0);
    int byteAt(double t) {
      final f = fracAt(t);
      if (toc != null) {
        // The Xing table maps 100 points of time to 256ths of the file.
        final i = (f * 100).floor().clamp(0, 99);
        final a = toc[i] / 256.0;
        final b = (i + 1 < 100 ? toc[i + 1] : 256) / 256.0;
        final within = f * 100 - i;
        return (audioStart + (a + (b - a) * within) * (total - audioStart)).round();
      }
      return (audioStart + f * (total - audioStart)).round();
    }
    final from = max(audioStart, byteAt(startSeconds) - _mp3MarginBytes);
    final to = min(total - 1, byteAt(startSeconds + durationSeconds) + _mp3MarginBytes);
    final bytes = (await _range(track, from, to)).bytes;
    // Start on a frame header so the decoder doesn't guess at the first bytes.
    final sync = Mp3Probe.firstFrame(bytes);
    await File(path).writeAsBytes(Uint8List.sublistView(bytes, sync), flush: true);
    // The margin before the estimate is what the decoder should skip. Bytes
    // to seconds uses the average bitrate, which is all a byte estimate has.
    final bytesPerSecond = (total - audioStart) / dur;
    final startWithin = ((byteAt(startSeconds) - (from + sync)) / bytesPerSecond).clamp(0.0, durationSeconds);
    debugPrint('[Slice] mp3 ${to - from + 1} bytes from $from, '
        'start ${startWithin.toStringAsFixed(2)}s into the slice${toc != null ? ' (xing toc)' : ''}');
    return AudioSlice(path, startWithin);
  }

  // HTTP

  static Future<({Uint8List bytes, int totalSize})> _range(RemoteTrack track, int from, int to) async {
    final resp = await http.get(
      Uri.parse(track.url),
      headers: {...track.headers, 'Range': 'bytes=$from-$to'},
    ).timeout(const Duration(seconds: 60));
    if (resp.statusCode == 206) {
      final cr = resp.headers['content-range'] ?? '';
      final total = int.tryParse(cr.split('/').last) ?? (to + 1);
      return (bytes: resp.bodyBytes, totalSize: total);
    }
    if (resp.statusCode == 200) {
      // A server that ignores Range sends the whole file; take the part asked for.
      final all = resp.bodyBytes;
      final end = min(to + 1, all.length);
      return (bytes: Uint8List.sublistView(all, min(from, all.length), end), totalSize: all.length);
    }
    throw HttpException('range fetch failed: ${resp.statusCode}');
  }

  static _Kind _sniff(Uint8List head, String? mime, String url) {
    if (head.length >= 12) {
      final type = String.fromCharCodes(head.sublist(4, 8));
      if (type == 'ftyp' || type == 'moov' || type == 'mdat' || type == 'free') return _Kind.mp4;
      if (head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) return _Kind.mp3;
      if (head[0] == 0xFF && (head[1] & 0xE0) == 0xE0) return _Kind.mp3;
    }
    final m = (mime ?? '').toLowerCase();
    if (m.contains('mp4') || m.contains('m4a') || m.contains('m4b')) return _Kind.mp4;
    if (m.contains('mpeg') || m.contains('mp3')) return _Kind.mp3;
    final lower = url.toLowerCase();
    if (lower.contains('.m4b') || lower.contains('.m4a') || lower.contains('.mp4')) return _Kind.mp4;
    if (lower.contains('.mp3')) return _Kind.mp3;
    return _Kind.unknown;
  }
}

enum _Kind { mp4, mp3, unknown }

/// What the AAC frames need to stand on their own: an ADTS header carries
/// the profile, sample rate and channel count that an MP4 keeps in its
/// index instead.
class AacConfig {
  final int objectType;
  final int sampleRateIndex;
  final int channels;
  const AacConfig(this.objectType, this.sampleRateIndex, this.channels);

  static const sampleRates = [
    96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350,
  ];
  int get sampleRate => sampleRateIndex < sampleRates.length ? sampleRates[sampleRateIndex] : 44100;
}

class Adts {
  /// A 7-byte ADTS header for one raw AAC frame of [payload] bytes.
  static Uint8List header(AacConfig c, int payload) {
    final len = payload + 7;
    // HE-AAC signals its object type past what ADTS can carry; LC in the
    // header with implicit SBR is how every decoder expects it.
    final profile = (c.objectType.clamp(1, 4) - 1) & 0x3;
    final h = Uint8List(7);
    h[0] = 0xFF;
    h[1] = 0xF1;
    h[2] = (profile << 6) | ((c.sampleRateIndex & 0xF) << 2) | ((c.channels >> 2) & 0x1);
    h[3] = ((c.channels & 0x3) << 6) | ((len >> 11) & 0x3);
    h[4] = (len >> 3) & 0xFF;
    h[5] = ((len & 0x7) << 5) | 0x1F;
    h[6] = 0xFC;
    return h;
  }
}

/// The audio track's sample tables out of an MP4 moov atom: enough to say
/// which bytes hold any moment of the audio.
class Mp4Index {
  final int timescale;
  final AacConfig config;
  /// Decode time of each sample's start, in timescale units, plus one
  /// trailing entry for the end.
  final Int64List sampleStarts;
  final Uint32List sampleSizes;
  final Int64List sampleOffsets;

  Mp4Index._(this.timescale, this.config, this.sampleStarts, this.sampleSizes, this.sampleOffsets);

  int get sampleCount => sampleSizes.length;
  double sampleTime(int i) => sampleStarts[i] / timescale;
  int sampleSize(int i) => sampleSizes[i];
  int sampleOffset(int i) => sampleOffsets[i];

  /// Sample indexes whose audio falls in [from]..[to] seconds.
  List<int> samplesBetween(double from, double to) {
    final fromT = (from * timescale).floor();
    final toT = (to * timescale).ceil();
    var lo = 0, hi = sampleCount;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (sampleStarts[mid + 1] <= fromT) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final out = <int>[];
    for (var i = lo; i < sampleCount && sampleStarts[i] < toT; i++) {
      out.add(i);
    }
    return out;
  }

  static Mp4Index parse(Uint8List moov) {
    final root = _Atom(moov, 0, moov.length);
    for (final trak in root.children('moov').expand((m) => m.children('trak'))) {
      final mdia = trak.child('mdia');
      if (mdia == null) continue;
      final hdlr = mdia.child('hdlr');
      if (hdlr == null) continue;
      final handler = String.fromCharCodes(moov.sublist(hdlr.body + 8, hdlr.body + 12));
      if (handler != 'soun') continue;
      final mdhd = mdia.child('mdhd');
      final stbl = mdia.child('minf')?.child('stbl');
      if (mdhd == null || stbl == null) continue;
      final mdhdVersion = moov[mdhd.body];
      final timescale = ByteData.sublistView(moov).getUint32(mdhd.body + (mdhdVersion == 1 ? 20 : 12));
      final config = _aacConfig(moov, stbl.child('stsd'));
      if (config == null) throw StateError('audio track is not AAC');
      final stts = _stts(moov, stbl.child('stts'));
      final sizes = _stsz(moov, stbl.child('stsz'));
      final chunkOffsets = _stco(moov, stbl.child('stco') ?? stbl.child('co64'));
      final stsc = _stsc(moov, stbl.child('stsc'));
      final n = sizes.length;
      final starts = Int64List(n + 1);
      var t = 0;
      var si = 0;
      for (final e in stts) {
        for (var k = 0; k < e.count && si < n; k++) {
          starts[si++] = t;
          t += e.delta;
        }
      }
      starts[n] = t;
      final offsets = Int64List(n);
      var sample = 0;
      for (var ci = 0; ci < chunkOffsets.length && sample < n; ci++) {
        final perChunk = _samplesInChunk(stsc, ci + 1);
        var off = chunkOffsets[ci];
        for (var k = 0; k < perChunk && sample < n; k++) {
          offsets[sample] = off;
          off += sizes[sample];
          sample++;
        }
      }
      return Mp4Index._(timescale, config, starts, sizes, offsets);
    }
    throw StateError('no audio track');
  }

  static int _samplesInChunk(List<({int firstChunk, int samples})> stsc, int chunk) {
    var result = stsc.isNotEmpty ? stsc.first.samples : 0;
    for (final e in stsc) {
      if (e.firstChunk <= chunk) result = e.samples;
    }
    return result;
  }

  static List<({int count, int delta})> _stts(Uint8List b, _Atom? a) {
    if (a == null) throw StateError('no stts');
    final bd = ByteData.sublistView(b);
    final n = bd.getUint32(a.body + 4);
    return [
      for (var i = 0; i < n; i++)
        (count: bd.getUint32(a.body + 8 + i * 8), delta: bd.getUint32(a.body + 12 + i * 8)),
    ];
  }

  static Uint32List _stsz(Uint8List b, _Atom? a) {
    if (a == null) throw StateError('no stsz');
    final bd = ByteData.sublistView(b);
    final fixed = bd.getUint32(a.body + 4);
    final n = bd.getUint32(a.body + 8);
    final out = Uint32List(n);
    for (var i = 0; i < n; i++) {
      out[i] = fixed != 0 ? fixed : bd.getUint32(a.body + 12 + i * 4);
    }
    return out;
  }

  static List<int> _stco(Uint8List b, _Atom? a) {
    if (a == null) throw StateError('no stco');
    final bd = ByteData.sublistView(b);
    final n = bd.getUint32(a.body + 4);
    final wide = a.type == 'co64';
    return [
      for (var i = 0; i < n; i++)
        wide ? bd.getUint64(a.body + 8 + i * 8) : bd.getUint32(a.body + 8 + i * 4),
    ];
  }

  static List<({int firstChunk, int samples})> _stsc(Uint8List b, _Atom? a) {
    if (a == null) throw StateError('no stsc');
    final bd = ByteData.sublistView(b);
    final n = bd.getUint32(a.body + 4);
    return [
      for (var i = 0; i < n; i++)
        (firstChunk: bd.getUint32(a.body + 8 + i * 12), samples: bd.getUint32(a.body + 12 + i * 12)),
    ];
  }

  /// The AudioSpecificConfig out of stsd > mp4a > esds.
  static AacConfig? _aacConfig(Uint8List b, _Atom? stsd) {
    if (stsd == null) return null;
    // stsd: version/flags (4) + entry count (4), then sample entries.
    final entry = _Atom(b, stsd.body + 8, stsd.end);
    if (entry.type != 'mp4a') return null;
    // mp4a: 6 reserved + 2 data ref index + 8 reserved + channels (2) +
    // sample size (2) + 4 reserved + sample rate (4) = 28 bytes of fields.
    final bd = ByteData.sublistView(b);
    final channels = bd.getUint16(entry.body + 16);
    final esds = _Atom(b, entry.body + 28, entry.end).siblingsUntil(entry.end).firstWhere(
          (x) => x.type == 'esds',
          orElse: () => throw StateError('no esds'),
        );
    // esds: version/flags then ES_Descriptor (0x03) > DecoderConfig (0x04)
    // > DecoderSpecificInfo (0x05) which holds the AudioSpecificConfig.
    var p = esds.body + 4;
    int readLen() {
      var len = 0;
      for (var i = 0; i < 4; i++) {
        final v = b[p++];
        len = (len << 7) | (v & 0x7F);
        if (v & 0x80 == 0) break;
      }
      return len;
    }
    if (b[p] != 0x03) return null;
    p++;
    readLen();
    p += 2; // ES_ID
    final esFlags = b[p++];
    if (esFlags & 0x80 != 0) p += 2; // dependsOn_ES_ID
    if (esFlags & 0x40 != 0) p += 1 + b[p]; // URL string
    if (esFlags & 0x20 != 0) p += 2; // OCR_ES_ID
    if (b[p] != 0x04) return null;
    p++;
    readLen();
    p += 13;
    if (b[p] != 0x05) return null;
    p++;
    final dsiLen = readLen();
    if (dsiLen < 2) return null;
    final asc = (b[p] << 8) | b[p + 1];
    final objectType = asc >> 11;
    final rateIndex = (asc >> 7) & 0xF;
    final chanConfig = (asc >> 3) & 0xF;
    return AacConfig(objectType, rateIndex, chanConfig != 0 ? chanConfig : channels);
  }
}

/// One box of an MP4 file.
class _Atom {
  final Uint8List bytes;
  final int start;
  final int end;
  late final int size;
  late final String type;
  late final int body;

  _Atom(this.bytes, this.start, int limit) : end = limit {
    if (start + 8 > limit) {
      size = 0;
      type = '';
      body = start;
      return;
    }
    final bd = ByteData.sublistView(bytes);
    var s = bd.getUint32(start);
    type = String.fromCharCodes(bytes.sublist(start + 4, start + 8));
    var header = 8;
    if (s == 1 && start + 16 <= limit) {
      s = bd.getUint64(start + 8);
      header = 16;
    } else if (s == 0) {
      s = limit - start;
    }
    size = min(s, limit - start);
    body = start + header;
  }

  int get next => start + size;

  /// The boxes laid out directly inside this one.
  List<_Atom> children(String ofType) {
    // The root pseudo-atom is the whole buffer: its own header is the first
    // real atom, so walk from start rather than body.
    final from = start == 0 && end == bytes.length && type == ofType ? start : body;
    return _Atom(bytes, from, end).siblingsUntil(end).where((a) => a.type == ofType).toList();
  }

  _Atom? child(String ofType) {
    for (final a in _Atom(bytes, body, end).siblingsUntil(end)) {
      if (a.type == ofType) return a;
    }
    return null;
  }

  /// This box and the ones after it up to [limit].
  List<_Atom> siblingsUntil(int limit) {
    final out = <_Atom>[];
    var a = this;
    while (a.start + 8 <= limit && a.size >= 8) {
      out.add(a);
      if (a.next >= limit) break;
      a = _Atom(bytes, a.next, limit);
    }
    return out;
  }
}

/// Just enough MP3 knowledge to cut a file by byte position.
class Mp3Probe {
  /// Where the audio frames begin: after an ID3v2 tag if there is one.
  static int audioStart(Uint8List head) {
    if (head.length >= 10 && head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) {
      final size = ((head[6] & 0x7F) << 21) | ((head[7] & 0x7F) << 14) | ((head[8] & 0x7F) << 7) | (head[9] & 0x7F);
      return 10 + size + ((head[5] & 0x10) != 0 ? 10 : 0);
    }
    return 0;
  }

  /// The first byte of a frame header at or after [from].
  static int firstFrame(Uint8List bytes, [int from = 0]) {
    for (var i = from; i + 4 <= bytes.length; i++) {
      if (bytes[i] == 0xFF && (bytes[i + 1] & 0xE0) == 0xE0 && ((bytes[i + 1] >> 1) & 0x3) != 0 && ((bytes[i + 2] >> 4) & 0xF) != 0xF) {
        return i;
      }
    }
    return 0;
  }

  /// The 100-entry seek table of a VBR file's Xing header, or null.
  static List<int>? xingToc(Uint8List head, int audioStart) {
    final frame = firstFrame(head, audioStart);
    // The Xing tag sits after the side information, whose size depends on
    // the MPEG version and channel mode.
    if (frame + 4 > head.length) return null;
    final versionBits = (head[frame + 1] >> 3) & 0x3;
    final mono = ((head[frame + 3] >> 6) & 0x3) == 3;
    final mpeg1 = versionBits == 3;
    final side = mpeg1 ? (mono ? 17 : 32) : (mono ? 9 : 17);
    final p = frame + 4 + side;
    if (p + 8 > head.length) return null;
    final tag = String.fromCharCodes(head.sublist(p, p + 4));
    if (tag != 'Xing' && tag != 'Info') return null;
    final flags = ByteData.sublistView(head).getUint32(p + 4);
    var q = p + 8;
    if (flags & 0x1 != 0) q += 4;
    if (flags & 0x2 != 0) q += 4;
    if (flags & 0x4 == 0) return null;
    if (q + 100 > head.length) return null;
    return List<int>.generate(100, (i) => head[q + i]);
  }
}
