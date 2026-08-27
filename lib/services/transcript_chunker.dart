import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utils/passage_match.dart';
import '../utils/transcript_align.dart';
import 'ebook_cache.dart';
import 'transcript_line_store.dart';
import 'transcription_service.dart';

/// What one transcribed window produced.
typedef ChunkOutcome = ({
  /// Seconds of audio the window actually yielded, for measuring how fast
  /// this device is getting through it.
  double span,
  double wall,
  int lines,
  bool exact,
});

/// Turns one window of an item's audio into stored transcript lines: Whisper,
/// then the book's own words where the EPUB has them, timed against what was
/// actually heard, split into sentences.
///
/// Shared by the live transcript and the whole-book preparation job so both
/// produce identical lines - the store is the same cache either way, and a
/// stretch prepared ahead of time must be indistinguishable from one
/// transcribed as you listen.
class TranscriptChunker {
  TranscriptChunker({required this.key, this.epubItemId});

  /// Store key: itemId for books, "itemId-episodeId" for podcast episodes.
  final String key;

  /// Item to look for a cached EPUB under, or null for podcasts.
  final String? epubItemId;

  /// Chunks in a row the ebook couldn't be matched against. Bonus content and
  /// audio-only extras aren't in the EPUB at all, and scanning the whole book
  /// for every chunk of them is work that can never pay off.
  int _misses = 0;
  int _chunks = 0;

  void reset() {
    _misses = 0;
    _chunks = 0;
  }

  /// Path to this book's cached EPUB, or null when there isn't one. Checked
  /// per chunk rather than once, so opening the ebook mid-listen starts
  /// correcting the next chunk.
  Future<String?> cachedEpubPath() async {
    final itemId = epubItemId;
    if (itemId == null) return null;
    try {
      final ef = await cachedEbookFileFor(itemId);
      if (ef == null || ebookExtFromFile(ef) != '.epub') return null;
      final f = await ebookCacheFileFor(itemId, ef);
      return f.existsSync() ? f.path : null;
    } catch (e) {
      debugPrint('[Transcript] ebook lookup failed: $e');
      return null;
    }
  }

  /// The book's own words for a chunk (plus the sentences that follow, for
  /// the estimated preview), when the EPUB is cached and the passage matches
  /// confidently. Timing them against what was actually heard is
  /// [alignCorrected]'s job - this only finds the text. Any failure returns
  /// null, which leaves the honest Whisper transcript in place.
  Future<PassageWithNext?> _correctedText(
      List<TimedWord> heard, String? epubPath) async {
    if (epubPath == null || heard.isEmpty) return null;
    try {
      if (!File(epubPath).existsSync()) return null;
      final joined = heard.map((w) => w.text).join(' ');
      final corrected = await compute(
          correctFromEpubWithNext, (epubPath: epubPath, transcript: joined));
      if (corrected == null || corrected.passage.trim().isEmpty) return null;
      return corrected;
    } catch (e) {
      debugPrint('[Transcript] ebook correction failed: $e');
      return null;
    }
  }

  /// Transcribe [windowSeconds] from [start] and file the lines. Throws
  /// [TranscriptionException] the same way the engine does, so callers can
  /// tell silence from a missing model.
  Future<ChunkOutcome> transcribeInto({
    required double start,
    required double windowSeconds,
    required bool preferAccuracy,
  }) async {
    final epub = await cachedEpubPath();
    final watch = Stopwatch()..start();
    final segs = await TranscriptionService.instance.transcribeWindowSegments(
      itemId: key,
      startSeconds: start,
      windowSeconds: windowSeconds,
      preferAccuracy: preferAccuracy && epub == null,
    );
    final wall = watch.elapsedMilliseconds / 1000.0;
    final heard = wordsFromSegments([
      for (final s in segs)
        (start: start + s.start, end: start + s.end, text: s.text.trim()),
    ]);
    var words = heard;
    var exact = false;
    // After a few misses in a row, only try occasionally - an audio-only
    // extra will never match, but front matter that missed early shouldn't
    // rule the book's own chapters out for good.
    final skipCorrection = _misses >= 3 && (++_chunks % 5 != 0);
    final corrected =
        skipCorrection ? null : await _correctedText(heard, epub);
    if (corrected == null && !skipCorrection && epub != null) {
      _misses++;
      if (_misses == 3) {
        debugPrint('[Transcript] this stretch is not in the ebook (bonus or '
            'audio-only content) - checking it only occasionally now');
      }
    }
    var continuation = '';
    if (corrected != null) {
      final aligned = alignCorrected(heard, corrected.passage);
      if (aligned != null && aligned.words.isNotEmpty) {
        words = aligned.words;
        exact = true;
        continuation = corrected.continuation;
        _misses = 0;
        debugPrint('[Transcript] aligned book text: matched '
            '${aligned.matched}/${aligned.total} words, '
            'heard=${heard.length} book=${words.length}');
      } else {
        // The book's words are the right words at the wrong moments unless
        // enough of them anchor to what was actually heard.
        _misses++;
        debugPrint('[Transcript] correction rejected (matched '
            '${aligned?.matched ?? 0}/${aligned?.total ?? 0}, miss '
            '$_misses) - keeping the transcript');
      }
    }
    final lines = linesFromWords(words, exact: exact);
    await TranscriptLineStore.instance.addLines(key, lines);
    // Preview: the book's next sentences at estimated pace, dimmed on screen
    // until the real transcription of that stretch replaces them. Keeps the
    // display readable when playback outruns the transcriber.
    if (exact && continuation.isNotEmpty && words.isNotEmpty) {
      final avgWord = ((words.last.end - words.first.start) / words.length)
          .clamp(0.15, 0.6);
      final preview = estimatedWords(continuation, words.last.end, avgWord);
      if (preview.isNotEmpty) {
        await TranscriptLineStore.instance.addLines(
            key, linesFromWords(preview, exact: true, approx: true));
      }
    }
    return (
      span: segs.isEmpty ? windowSeconds : segs.last.end,
      wall: wall,
      lines: lines.length,
      exact: exact,
    );
  }

  /// Mark a stretch as covered without any text - silence or music, so the
  /// loop moves past it instead of retrying the same window forever.
  Future<void> markEmpty(double start, double windowSeconds) =>
      TranscriptLineStore.instance
          .addLines(key, [TranscriptLine(start, start + windowSeconds, ' ')]);
}
