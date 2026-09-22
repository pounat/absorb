import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'remote_audio_slice.dart';
import 'transcription_service.dart';

/// One place in the audio that might be where a chapter starts: the end of a
/// silence, with what was heard right after it and how much that sounded
/// like the chapter being edited.
class ChapterCandidate {
  /// Global book time, seconds.
  final double time;
  final double silenceSeconds;
  final String heard;
  /// 2 = the chapter's own number or title was heard, 1 = some chapter-like
  /// word ("chapter", "part", "prologue"), 0 = just a gap in the audio.
  final int score;
  /// A title read off the narration ("Chapter 2", "Chapter 2: The Storm"),
  /// when the words after the gap announced one.
  final String? suggestedTitle;
  const ChapterCandidate({
    required this.time,
    required this.silenceSeconds,
    required this.heard,
    required this.score,
    this.suggestedTitle,
  });
}

/// Pure helpers, kept apart from the audio plumbing so they can be tested.
class ChapterStartAnalysis {
  /// Runs of quiet in 16-bit mono PCM at [sampleRate], at least [minSeconds]
  /// long. Quiet is judged against the loud parts of the same clip, so a
  /// softly recorded book and a loud one both work.
  static List<({double start, double end})> findSilences(
    Int16List pcm,
    int sampleRate, {
    double minSeconds = 0.8,
    double hopSeconds = 0.05,
  }) {
    if (pcm.isEmpty || sampleRate <= 0) return const [];
    final hop = max(1, (sampleRate * hopSeconds).round());
    final frames = pcm.length ~/ hop;
    if (frames < 4) return const [];
    final rms = Float64List(frames);
    for (var f = 0; f < frames; f++) {
      var acc = 0.0;
      final base = f * hop;
      for (var i = 0; i < hop; i++) {
        final s = pcm[base + i] / 32768.0;
        acc += s * s;
      }
      rms[f] = sqrt(acc / hop);
    }
    final sorted = List<double>.from(rms)..sort();
    final loud = sorted[(sorted.length * 0.9).floor().clamp(0, sorted.length - 1)];
    final threshold = max(loud * 0.12, 0.003);
    final minFrames = max(1, (minSeconds / hopSeconds).round());
    final out = <({double start, double end})>[];
    var runStart = -1;
    for (var f = 0; f <= frames; f++) {
      final quiet = f < frames && rms[f] < threshold;
      if (quiet) {
        if (runStart < 0) runStart = f;
      } else if (runStart >= 0) {
        if (f - runStart >= minFrames) {
          out.add((start: runStart * hopSeconds, end: f * hopSeconds));
        }
        runStart = -1;
      }
    }
    return out;
  }

  /// Cut [from]..[to] seconds out of a 16-bit mono WAV and wrap it in a new
  /// header. Times are clamped to the clip.
  static Uint8List sliceWav(Uint8List wav, int sampleRate, double from, double to) {
    final pcm = pcmOf(wav);
    final a = (from * sampleRate).round().clamp(0, pcm.length);
    final b = (to * sampleRate).round().clamp(a, pcm.length);
    final slice = Int16List.sublistView(pcm, a, b);
    return wavOf(slice, sampleRate);
  }

  /// The samples of a 16-bit mono WAV, header skipped.
  static Int16List pcmOf(Uint8List wav) {
    // The extractor writes a plain 44-byte header; fall back to scanning for
    // the data chunk in case a different writer produced the file.
    var dataStart = 44;
    var dataLen = wav.length - 44;
    for (var i = 12; i + 8 <= wav.length;) {
      final id = String.fromCharCodes(wav.sublist(i, i + 4));
      final len = ByteData.sublistView(wav, i + 4, i + 8).getUint32(0, Endian.little);
      if (id == 'data') {
        dataStart = i + 8;
        dataLen = min(len, wav.length - dataStart);
        break;
      }
      i += 8 + len + (len.isOdd ? 1 : 0);
    }
    final evenLen = dataLen - (dataLen.isOdd ? 1 : 0);
    return Int16List.sublistView(wav, dataStart, dataStart + evenLen);
  }

  static Uint8List wavOf(Int16List pcm, int sampleRate) {
    final dataLen = pcm.lengthInBytes;
    final out = ByteData(44 + dataLen);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        out.setUint8(offset + i, s.codeUnitAt(i));
      }
    }
    ascii(0, 'RIFF');
    out.setUint32(4, 36 + dataLen, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    out.setUint32(16, 16, Endian.little);
    out.setUint16(20, 1, Endian.little);
    out.setUint16(22, 1, Endian.little);
    out.setUint32(24, sampleRate, Endian.little);
    out.setUint32(28, sampleRate * 2, Endian.little);
    out.setUint16(32, 2, Endian.little);
    out.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    out.setUint32(40, dataLen, Endian.little);
    final bytes = out.buffer.asUint8List();
    bytes.setRange(44, 44 + dataLen, pcm.buffer.asUint8List(pcm.offsetInBytes, dataLen));
    return bytes;
  }

  static const _units = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
    'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12,
    'thirteen': 13, 'fourteen': 14, 'fifteen': 15, 'sixteen': 16,
    'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
  };
  static const _tens = {
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
    'seventy': 70, 'eighty': 80, 'ninety': 90,
  };
  static const _ordinals = {
    'first': 1, 'second': 2, 'third': 3, 'fourth': 4, 'fifth': 5, 'sixth': 6,
    'seventh': 7, 'eighth': 8, 'ninth': 9, 'tenth': 10, 'eleventh': 11,
    'twelfth': 12, 'thirteenth': 13, 'fourteenth': 14, 'fifteenth': 15,
    'sixteenth': 16, 'seventeenth': 17, 'eighteenth': 18, 'nineteenth': 19,
    'twentieth': 20, 'thirtieth': 30, 'fortieth': 40, 'fiftieth': 50,
  };
  static const _chapterWords = {
    'chapter', 'part', 'prologue', 'epilogue', 'interlude', 'book', 'section',
    'act', 'introduction', 'preface', 'afterword',
  };

  /// Words of [s], lower-cased, with spelled-out numbers turned into digits
  /// ("twenty one" and "twenty-first" both give "21").
  static List<String> words(String s) {
    final raw = s
        .toLowerCase()
        .replaceAll(RegExp(r"[^\p{L}\p{N}' ]+", unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final out = <String>[];
    for (var i = 0; i < raw.length; i++) {
      final w = raw[i];
      final tens = _tens[w];
      if (tens != null) {
        final next = i + 1 < raw.length ? raw[i + 1] : null;
        final unit = next == null ? null : (_units[next] ?? _ordinals[next]);
        if (unit != null && unit < 10) {
          out.add('${tens + unit}');
          i++;
        } else {
          out.add('$tens');
        }
        continue;
      }
      final n = _units[w] ?? _ordinals[w];
      if (n != null) {
        out.add('$n');
        continue;
      }
      if (w == 'hundred' && out.isNotEmpty && int.tryParse(out.last) != null) {
        out[out.length - 1] = '${int.parse(out.last) * 100}';
        continue;
      }
      out.add(w);
    }
    return out;
  }

  /// How much [heard] sounds like the start of chapter [number] titled
  /// [title]: 2 when the number or the title itself is spoken, 1 when any
  /// chapter-like word is, 0 otherwise.
  static int score(String heard, {required int number, required String title}) {
    final h = words(heard);
    if (h.isEmpty) return 0;
    final hasChapterWord = h.any(_chapterWords.contains);
    final numberSpoken = h.contains('$number');
    if (numberSpoken && hasChapterWord) return 2;
    final t = words(title).where((w) => w.length > 2 && !_chapterWords.contains(w)).toList();
    if (t.length >= 2) {
      final hit = t.where(h.contains).length;
      if (hit >= max(2, (t.length * 0.6).ceil())) return 2;
    } else if (t.length == 1 && h.contains(t.first) && t.first.length >= 4) {
      return 2;
    }
    if (numberSpoken && h.indexOf('$number') <= 2) return 2;
    return hasChapterWord ? 1 : 0;
  }

  static const _standaloneHeadings = {
    'prologue', 'epilogue', 'interlude', 'introduction', 'preface', 'afterword',
  };
  static const _numberedHeadings = {'chapter', 'part', 'book', 'section', 'act'};

  /// A chapter title read off what the narrator said right after the gap.
  /// "Chapter two" gives "Chapter 2"; "Chapter two, the storm. It was..."
  /// gives "Chapter 2: The Storm" when the extra words stop at a sentence
  /// break or a pause. Null when the words don't open with a heading.
  static String? suggestTitle(List<({double start, double end, String text})> segments) {
    if (segments.isEmpty) return null;
    final first = segments.first;
    final toks = words(first.text);
    if (toks.isEmpty) return null;
    final head = toks.first;
    String core;
    int consumed;
    if (_standaloneHeadings.contains(head)) {
      core = _cap(head);
      consumed = 1;
    } else if (_numberedHeadings.contains(head) && toks.length >= 2 && int.tryParse(toks[1]) != null) {
      core = '${_cap(head)} ${toks[1]}';
      consumed = 2;
    } else if (int.tryParse(head) != null && toks.length <= 8) {
      // Some narrators just say the number.
      core = 'Chapter $head';
      consumed = 1;
    } else {
      return null;
    }
    // Whatever else sits in the same breath before a sentence break is the
    // chapter's name. Whisper likes to put a full stop after the number
    // ("Chapter 3. Payback. I think..."), so a short clause right after that
    // stop counts as well, and so does a short second segment that follows
    // without a pause ("Chapter two." "The storm.").
    var rest = _clauseAfter(first.text, consumed);
    if (rest.isEmpty && consumed == 2) {
      final after = _clauseAfter(first.text, consumed, pastHeadingStop: true);
      final n = after.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      if (n >= 1 && n <= 3) rest = after;
    }
    if (rest.isEmpty && consumed == 2 && segments.length > 1) {
      final next = segments[1];
      if (next.start - first.end < 0.6) {
        final nextWords = words(next.text);
        if (nextWords.isNotEmpty && nextWords.length <= 3 && _endsSentence(next.text)) {
          rest = _clauseAfter(next.text, 0);
        }
      }
    }
    final restWords = rest.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (restWords.isEmpty || restWords.length > 6) return core;
    return '$core: ${restWords.map(_cap).join(' ')}';
  }

  static String _cap(String w) {
    if (w.isEmpty) return w;
    final lower = w.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static bool _endsSentence(String s) => RegExp(r'[.!?]\s*$').hasMatch(s.trim());

  /// The words of [raw] after its first [skipTokens] spoken tokens, up to the
  /// first sentence break, punctuation dropped. Empty when the heading
  /// itself ended the sentence ("Chapter two." and then narration), unless
  /// [pastHeadingStop] asks for the clause after that stop.
  static String _clauseAfter(String raw, int skipTokens, {bool pastHeadingStop = false}) {
    final rawWords = raw.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    var i = 0;
    var consumed = 0;
    var lastHeadingWord = '';
    while (i < rawWords.length && consumed < skipTokens) {
      // "twenty two" is one token once normalized, so a pair of raw words
      // that collapse together is stepped over as one.
      final mergesWithNext = i + 1 < rawWords.length &&
          words(rawWords[i]).length == 1 &&
          words('${rawWords[i]} ${rawWords[i + 1]}').length == 1;
      if (mergesWithNext) {
        lastHeadingWord = rawWords[i + 1];
        i += 2;
      } else {
        lastHeadingWord = rawWords[i];
        i += 1;
      }
      consumed++;
    }
    if (!pastHeadingStop && skipTokens > 0 && RegExp(r'[.!?]$').hasMatch(lastHeadingWord)) {
      return '';
    }
    final out = <String>[];
    for (; i < rawWords.length; i++) {
      final w = rawWords[i];
      final clean = w.replaceAll(RegExp(r"[^\p{L}\p{N}'-]+", unicode: true), '');
      if (clean.isNotEmpty) out.add(clean);
      if (RegExp(r'[.!?;]$').hasMatch(w)) break;
    }
    return out.join(' ');
  }
}

/// Listens through a stretch of the book around a chapter marker and offers
/// the places a chapter could start: every decent silence, with the first
/// words after it, ranked by whether those words name the chapter.
class ChapterStartFinder {
  static const double afterSilenceSeconds = 6.0;
  static const int maxCandidatesPerWindow = 8;

  /// [source] is a local file or a stream URL the native extractor can open;
  /// [sourceOffset] is where that file starts in global book time and
  /// [startLocal] where the window starts inside it. With [remote] set the
  /// window's bytes are pulled down first and decoded from that slice, for
  /// platforms whose decoder can't read a URL. Candidates arrive through
  /// [onCandidate] as they are heard. Returns how many were found, or throws
  /// a [TranscriptionException] when nothing could be listened to.
  static Future<int> run({
    required String source,
    required double sourceOffset,
    required double startLocal,
    required double windowSeconds,
    required int chapterNumber,
    required String title,
    required void Function(ChapterCandidate) onCandidate,
    bool Function()? cancelled,
    RemoteTrack? remote,
  }) async {
    final svc = TranscriptionService.instance;
    var extractFrom = source;
    var extractStart = startLocal;
    AudioSlice? slice;
    if (remote != null) {
      try {
        slice = await RemoteAudioSlicer.fetch(
          remote,
          startLocal,
          windowSeconds,
          tmpDir: (await getTemporaryDirectory()).path,
        );
      } catch (e) {
        debugPrint('[ChapterFind] slice failed: $e');
        throw TranscriptionException(TranscriptionError.extractFailed, e);
      }
      extractFrom = slice.path;
      extractStart = slice.startWithin;
    }
    final String? wavPath;
    try {
      wavPath = await svc.extractWindowWav(
        source: extractFrom,
        startSeconds: extractStart,
        durationSeconds: windowSeconds,
      );
    } finally {
      if (slice != null) {
        try {
          File(slice.path).deleteSync();
        } catch (_) {}
      }
    }
    if (wavPath == null) throw TranscriptionException(TranscriptionError.extractFailed);
    var found = 0;
    try {
      final wav = await File(wavPath).readAsBytes();
      const rate = 16000;
      final pcm = ChapterStartAnalysis.pcmOf(wav);
      final clipSeconds = pcm.length / rate;
      var silences = ChapterStartAnalysis.findSilences(pcm, rate);
      // A window that opens in the middle of a silence still counts: the
      // speech that follows may be the chapter.
      if (silences.isEmpty || silences.first.start > 0.3) {
        silences = [(start: 0.0, end: 0.0), ...silences];
      }
      // Longest gaps first when there are too many, then back in time order.
      if (silences.length > maxCandidatesPerWindow) {
        silences.sort((a, b) => (b.end - b.start).compareTo(a.end - a.start));
        silences = silences.take(maxCandidatesPerWindow).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
      }
      debugPrint('[ChapterFind] window ${startLocal.toStringAsFixed(1)}s+'
          '${windowSeconds.toStringAsFixed(0)}s: ${silences.length} gaps to listen after');
      for (final s in silences) {
        if (cancelled?.call() == true) break;
        final from = s.end;
        final to = min(clipSeconds, from + afterSilenceSeconds);
        if (to - from < 1.0) continue;
        final piece = ChapterStartAnalysis.sliceWav(wav, rate, from, to);
        final piecePath = '$wavPath.${(from * 10).round()}.wav';
        var heard = '';
        var segments = const <({double start, double end, String text})>[];
        try {
          await File(piecePath).writeAsBytes(piece, flush: true);
          segments = await svc.transcribeWavTimed(piecePath);
          heard = segments.map((s) => s.text).join(' ');
        } on TranscriptionException catch (e) {
          if (e.kind != TranscriptionError.empty) rethrow;
        } finally {
          try {
            File(piecePath).deleteSync();
          } catch (_) {}
        }
        final score = ChapterStartAnalysis.score(heard, number: chapterNumber, title: title);
        final candidate = ChapterCandidate(
          time: sourceOffset + startLocal + from,
          silenceSeconds: s.end - s.start,
          heard: heard,
          score: score,
          suggestedTitle: ChapterStartAnalysis.suggestTitle(segments),
        );
        debugPrint('[ChapterFind] ${candidate.time.toStringAsFixed(1)}s '
            'gap=${candidate.silenceSeconds.toStringAsFixed(1)}s score=$score "$heard"');
        found++;
        onCandidate(candidate);
      }
    } finally {
      try {
        File(wavPath).deleteSync();
      } catch (_) {}
    }
    return found;
  }
}
