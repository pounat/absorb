import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'remote_audio_slice.dart';

/// Reads [count] bytes at [offset] of an audio file, wherever it lives.
typedef AudioBytes = Future<Uint8List> Function(int offset, int count);

/// How long an audio file plays, from its headers: exact for MP4/M4A (the
/// movie header) and for an MP3 with a Xing, Info or VBRI frame count,
/// estimated from the bitrate for a plain MP3. Null when it can't tell.
Future<double?> audioFileDuration(String path) async {
  RandomAccessFile? raf;
  try {
    final f = raf = await File(path).open();
    return await audioDuration((offset, count) async {
      await f.setPosition(offset);
      return f.read(count);
    }, await f.length());
  } catch (_) {
    return null;
  } finally {
    await raf?.close();
  }
}

/// [audioFileDuration] for a file of [length] bytes read through [read],
/// such as one inside an EPUB on the server.
Future<double?> audioDuration(AudioBytes read, int length) async {
  try {
    final head = await read(0, min(length, 16));
    if (head.length >= 8 && String.fromCharCodes(head.sublist(4, 8)) == 'ftyp') {
      return await _mp4(read, length);
    }
    return await _mp3(read, length);
  } catch (_) {
    return null;
  }
}

Future<double?> _mp4(AudioBytes read, int length) async {
  Future<({int size, String type, int header})?> box(int at, int limit) async {
    if (at + 8 > limit) return null;
    final h = await read(at, min(16, limit - at));
    if (h.length < 8) return null;
    final d = ByteData.sublistView(h);
    var size = d.getUint32(0);
    var header = 8;
    if (size == 1 && h.length >= 16) {
      size = d.getUint64(8);
      header = 16;
    } else if (size == 0) {
      size = limit - at;
    }
    if (size < header) return null;
    return (size: size, type: String.fromCharCodes(h.sublist(4, 8)), header: header);
  }

  var at = 0;
  while (true) {
    final top = await box(at, length);
    if (top == null) return null;
    if (top.type == 'moov') {
      var child = at + top.header;
      final end = at + top.size;
      while (true) {
        final b = await box(child, end);
        if (b == null) return null;
        if (b.type == 'mvhd') {
          final body = await read(child + b.header, 32);
          final d = ByteData.sublistView(body);
          final v1 = body.isNotEmpty && body[0] == 1;
          if (body.length < (v1 ? 32 : 20)) return null;
          final scale = v1 ? d.getUint32(20) : d.getUint32(12);
          final duration = v1 ? d.getUint64(24) : d.getUint32(16);
          return scale > 0 && duration > 0 ? duration / scale : null;
        }
        child += b.size;
      }
    }
    at += top.size;
  }
}

const _bitratesV1L3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320];
const _bitratesV2L3 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];

Future<double?> _mp3(AudioBytes read, int length) async {
  final id3 = await read(0, min(length, 10));
  final start = Mp3Probe.audioStart(id3);
  if (start >= length) return null;
  final window = await read(start, min(length - start, 16 * 1024));
  final frame = Mp3Probe.firstFrame(window);
  if (frame + 4 > window.length || window[frame] != 0xFF) return null;
  final b1 = window[frame + 1], b2 = window[frame + 2], b3 = window[frame + 3];
  final version = (b1 >> 3) & 3; // 3 = MPEG 1, 2 = MPEG 2, 0 = MPEG 2.5
  if (((b1 >> 1) & 3) != 1 || version == 1) return null; // Layer III only
  final rates = switch (version) {
    3 => const [44100, 48000, 32000],
    2 => const [22050, 24000, 16000],
    _ => const [11025, 12000, 8000],
  };
  final srIndex = (b2 >> 2) & 3;
  if (srIndex == 3) return null;
  final sampleRate = rates[srIndex];
  final mpeg1 = version == 3;
  final samplesPerFrame = mpeg1 ? 1152 : 576;
  final mono = (b3 >> 6) == 3;
  final d = ByteData.sublistView(window);

  int? frames;
  final xingAt = frame + 4 + (mpeg1 ? (mono ? 17 : 32) : (mono ? 9 : 17));
  if (xingAt + 12 <= window.length) {
    final tag = String.fromCharCodes(window.sublist(xingAt, xingAt + 4));
    if ((tag == 'Xing' || tag == 'Info') && (d.getUint32(xingAt + 4) & 1) != 0) {
      frames = d.getUint32(xingAt + 8);
    }
  }
  final vbriAt = frame + 4 + 32;
  if (frames == null && vbriAt + 18 <= window.length &&
      String.fromCharCodes(window.sublist(vbriAt, vbriAt + 4)) == 'VBRI') {
    frames = d.getUint32(vbriAt + 14);
  }
  if (frames != null && frames > 0) return frames * samplesPerFrame / sampleRate;

  final kbps = (mpeg1 ? _bitratesV1L3 : _bitratesV2L3)[(b2 >> 4) & 0xF];
  if (kbps <= 0) return null;
  return (length - start - frame) * 8 / (kbps * 1000);
}
