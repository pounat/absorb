import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One displayed transcript line: a Whisper segment (or its ebook-corrected
/// replacement), timed in the item's own seconds (episode-relative for
/// podcast episodes, global book time for audiobooks).
class TranscriptLine {
  final double start;
  final double end;
  final String text;
  /// True when the text came from the ebook's real words, not Whisper.
  final bool exact;
  /// Start time of each whitespace-separated word in [text], for read-along
  /// word tracking. Empty on lines cached before word timing existed, and on
  /// anything the timing couldn't be worked out for - callers fall back to
  /// whole-line highlighting.
  final List<double> wordStarts;
  /// True for an estimated preview: the book's next sentences after the last
  /// transcribed stretch, timed by pace guess rather than heard audio. Shown
  /// dimmed, never counted as coverage, and replaced the moment the real
  /// transcription of that stretch lands.
  final bool approx;
  const TranscriptLine(this.start, this.end, this.text,
      {this.exact = false, this.wordStarts = const [], this.approx = false});

  /// The words [wordStarts] is indexed against.
  List<String> get words =>
      text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  /// Index into [words] of the word being spoken at [t], or -1 when the line
  /// has no word timing or [t] sits before the first word.
  int wordIndexAt(double t) {
    if (wordStarts.isEmpty) return -1;
    if (t < wordStarts.first) return -1;
    var lo = 0, hi = wordStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (wordStarts[mid] <= t) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  Map<String, dynamic> toJson() => {
        's': start,
        'e': end,
        't': text,
        if (exact) 'x': true,
        if (approx) 'a': true,
        if (wordStarts.isNotEmpty)
          'w': [for (final w in wordStarts) double.parse(w.toStringAsFixed(2))],
      };

  factory TranscriptLine.fromJson(Map<String, dynamic> j) => TranscriptLine(
        (j['s'] as num).toDouble(),
        (j['e'] as num).toDouble(),
        j['t'] as String? ?? '',
        exact: j['x'] == true,
        approx: j['a'] == true,
        wordStarts: [
          for (final w in (j['w'] as List<dynamic>? ?? const []))
            (w as num).toDouble(),
        ],
      );
}

/// Per-book / per-episode cache of transcript lines, so audio is transcribed
/// once ever: replays, seeks and app restarts are lookups. Keys are the same
/// composite the rest of the app uses - itemId for books,
/// "itemId-episodeId" for podcast episodes. One JSON file per key under
/// app support; writes are debounced so the transcribe-ahead loop doesn't
/// grind the disk.
class TranscriptLineStore {
  TranscriptLineStore._();
  static final TranscriptLineStore instance = TranscriptLineStore._();

  final Map<String, List<TranscriptLine>> _cache = {};
  final Set<String> _dirty = {};
  // Keys whose lines are a read-along's, and which read-along file made them.
  final Map<String, String> _readAlongs = {};
  final Map<String, Future<void>> _writes = {};
  bool _flushScheduled = false;

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/transcript_lines');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String key) async =>
      File('${(await _dir()).path}/$key.json');

  Future<List<TranscriptLine>> _load(String key) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    var lines = <TranscriptLine>[];
    try {
      final f = await _fileFor(key);
      if (f.existsSync()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        lines = (j['lines'] as List<dynamic>? ?? const [])
            .map((e) => TranscriptLine.fromJson(e as Map<String, dynamic>))
            .toList();
        final readAlong = j['readAlong'] as String?;
        if (readAlong != null) _readAlongs[key] = readAlong;
      }
    } catch (e) {
      debugPrint('[Lyrics] store load failed for $key: $e');
    }
    lines.sort((a, b) => a.start.compareTo(b.start));
    _cache[key] = lines;
    return lines;
  }

  /// Warm the in-memory cache; call before the sync lookups below.
  Future<void> hydrate(String key) => _load(key);

  /// The read-along file [key]'s lines were made from, or null when they
  /// were transcribed.
  String? readAlongOf(String key) => _readAlongs[key];

  /// Replaces [key]'s lines, transcribed or not, with the sentences of the
  /// read-along named by [source]: the book's own words, all of them, timed
  /// exactly, so nothing is transcribed while they last. Written at once, so
  /// they are there offline.
  Future<void> setReadAlong(String key, String source, List<TranscriptLine> lines) async {
    await _load(key);
    _cache[key] = [...lines]..sort((a, b) => a.start.compareTo(b.start));
    _readAlongs[key] = source;
    _dirty.remove(key);
    await _write(key);
  }

  /// Forgets [key]'s read-along lines, so the book is transcribed again.
  Future<void> dropReadAlong(String key) async {
    if (_readAlongs.remove(key) == null) return;
    _cache[key] = [];
    _dirty.remove(key);
    await (_writes[key] ?? Future.value());
    try {
      final f = await _fileFor(key);
      if (f.existsSync()) await f.delete();
    } catch (e) {
      debugPrint('[Lyrics] store delete failed for $key: $e');
    }
  }

  static final _apostrophes = RegExp(r"['’]");
  static final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static List<String> _words(String s) =>
      s.toLowerCase().replaceAll(_apostrophes, '').split(_nonWord).where((w) => w.isNotEmpty).toList();

  /// When the word [after] begins with is spoken, [before] being the words
  /// just ahead of it, for finding a spot of the book in a read-along's
  /// lines; the hit nearest [near] when the words occur more than once. Null
  /// when they aren't in the lines, or occur more than once with no [near].
  double? timeOfText(String key, String before, String after, {double? near}) {
    final lines = _cache[key];
    if (lines == null || lines.isEmpty) return null;
    // The book's words in a row, and for each its line and its place among
    // that line's words (the ones word timing counts).
    final words = <String>[];
    final at = <(TranscriptLine, int)>[];
    for (final l in lines) {
      final tokens = l.words;
      for (var i = 0; i < tokens.length; i++) {
        for (final w in _words(tokens[i])) {
          words.add(w);
          at.add((l, i));
        }
      }
    }
    final ahead = _words(before), from = _words(after);
    if (from.length < 2) return null;
    // The most words around the spot first; fewer when they run into text
    // the narration skips, like a heading it doesn't read.
    for (final (b, a) in const [(4, 8), (0, 8), (0, 4)]) {
      final lead = ahead.length > b ? ahead.sublist(ahead.length - b) : ahead;
      final needle = [...lead, ...from.take(a)];
      final hits = <double>[];
      for (var i = 0; i + needle.length <= words.length; i++) {
        var j = 0;
        while (j < needle.length && words[i + j] == needle[j]) {
          j++;
        }
        if (j < needle.length) continue;
        final (line, w) = at[i + lead.length];
        hits.add(w < line.wordStarts.length ? line.wordStarts[w] : line.start);
      }
      if (hits.length == 1) return hits.single;
      if (hits.isEmpty) continue;
      if (near == null) return null;
      return hits.reduce((x, y) => (x - near).abs() <= (y - near).abs() ? x : y);
    }
    return null;
  }

  /// The line containing [t], or null when that moment isn't transcribed yet
  /// (or was silence/music). Binary search over the sorted cache.
  TranscriptLine? lineAt(String key, double t) {
    final lines = _cache[key];
    if (lines == null || lines.isEmpty) return null;
    var lo = 0, hi = lines.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final l = lines[mid];
      if (t < l.start) {
        hi = mid - 1;
      } else if (t > l.end) {
        lo = mid + 1;
      } else {
        return l;
      }
    }
    return null;
  }

  /// Like [lineAt], but forgiving around the gaps Whisper's VAD leaves
  /// between segments: holds the previous line up to [holdAfter] seconds past
  /// its end, and shows the next line up to [preShow] seconds early - so
  /// inter-sentence silences don't blank the overlay.
  TranscriptLine? lineNear(String key, double t,
      {double holdAfter = 2.5, double preShow = 0.8}) {
    final exact = lineAt(key, t);
    if (exact != null) return exact;
    final lines = _cache[key];
    if (lines == null || lines.isEmpty) return null;
    TranscriptLine? prev;
    for (final l in lines) {
      if (l.start > t) {
        if (l.start - t <= preShow && l.text.trim().isNotEmpty) return l;
        break;
      }
      prev = l;
    }
    if (prev != null && t - prev.end <= holdAfter && prev.text.trim().isNotEmpty) {
      return prev;
    }
    return null;
  }

  /// The first real, ebook-exact line starting at or after [t] within
  /// [within] seconds, or null. Read along can only find the book's own
  /// words on the page, so with no anchor yet it looks ahead for one.
  TranscriptLine? nextExactLine(String key, double t, {double within = 90}) {
    final lines = _cache[key];
    if (lines == null || lines.isEmpty) return null;
    for (final l in lines) {
      if (l.start < t) continue;
      if (l.start > t + within) break;
      if (l.exact && !l.approx && l.text.trim().isNotEmpty) return l;
    }
    return null;
  }

  /// Up to [count] lines running on from the one that begins at [start],
  /// for filling a page of transcript downwards. Silence placeholders are
  /// left out. Empty when that line isn't in the cache.
  List<TranscriptLine> fromLine(String key, double start, int count) {
    final lines = _cache[key];
    if (lines == null || lines.isEmpty) return const [];
    final idx = lines.indexWhere((l) => l.start == start);
    if (idx < 0) return const [];
    final out = <TranscriptLine>[];
    for (var i = idx; i < lines.length && out.length < count; i++) {
      if (lines[i].text.trim().isNotEmpty) out.add(lines[i]);
    }
    return out;
  }

  /// Total seconds of this item that have been transcribed, gaps excluded.
  /// Silence placeholders count - that stretch is done with either way.
  double preparedSeconds(String key) {
    final lines = _cache[key];
    if (lines == null || lines.isEmpty) return 0;
    var total = 0.0;
    var last = double.negativeInfinity;
    for (final l in lines) {
      if (l.approx) continue;
      final from = l.start > last ? l.start : last;
      if (l.end > from) total += l.end - from;
      if (l.end > last) last = l.end;
    }
    return total;
  }

  /// How far continuous coverage extends from [from]: the end of the chained
  /// lines starting at or before [from], tolerating small inter-line gaps
  /// (Whisper trims silence between segments). Returns [from] when nothing
  /// covers it yet.
  double coveredUntil(String key, double from) {
    // A read-along's lines are the whole book.
    if (_readAlongs.containsKey(key)) return double.infinity;
    final lines = _cache[key];
    if (lines == null || lines.isEmpty) return from;
    const gapTolerance = 4.0;
    var covered = from;
    for (final l in lines) {
      // Estimated previews are display-only - counting them as coverage
      // would stop the loop from ever really transcribing that stretch.
      if (l.approx) continue;
      if (l.end <= covered) continue;
      if (l.start > covered + gapTolerance) break;
      covered = l.end;
    }
    return covered;
  }

  /// Merge [fresh] into the cache. Lines overlapping an existing one are
  /// dropped unless they're exact and the existing one isn't - an ebook
  /// correction may upgrade a line, but a re-transcription never downgrades.
  /// Estimated previews are the weakest of all: real lines always replace
  /// them, and they never displace anything real.
  Future<void> addLines(String key, List<TranscriptLine> fresh) async {
    final lines = await _load(key);
    if (_readAlongs.containsKey(key)) return;
    var changed = false;
    for (final nl in fresh) {
      if (nl.text.trim().isEmpty) continue;
      final overlapIdx = lines.indexWhere((e) =>
          nl.start < e.end - 0.3 && nl.end > e.start + 0.3);
      if (overlapIdx >= 0) {
        final old = lines[overlapIdx];
        final upgrade = old.approx
            ? true // anything beats a preview, and a newer preview is fresher
            : (!nl.approx && nl.exact && !old.exact);
        if (upgrade) {
          lines[overlapIdx] = nl;
          // One real line can span several stale previews - sweep the rest.
          lines.removeWhere((e) =>
              !identical(e, nl) &&
              e.approx &&
              nl.start < e.end - 0.3 &&
              nl.end > e.start + 0.3);
          changed = true;
        }
        continue;
      }
      lines.add(nl);
      changed = true;
    }
    if (!changed) return;
    lines.sort((a, b) => a.start.compareTo(b.start));
    _dirty.add(key);
    _scheduleFlush();
  }

  /// Total bytes the on-disk transcript cache occupies.
  Future<int> cacheBytes() async {
    var total = 0;
    try {
      final dir = await _dir();
      for (final f in dir.listSync()) {
        if (f is File) total += f.lengthSync();
      }
    } catch (_) {}
    return total;
  }

  /// Wipe every cached transcript, memory and disk. Emptying [_cache] also
  /// defuses any flush in flight - it re-reads the cache per key and skips
  /// keys that are gone, so a pending write can't resurrect a file.
  Future<void> clearAll() async {
    _cache.clear();
    _dirty.clear();
    _readAlongs.clear();
    try {
      final dir = await _dir();
      for (final f in dir.listSync()) {
        if (f is! File) continue;
        try {
          await f.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[Lyrics] store clear failed: $e');
    }
  }

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    Future.delayed(const Duration(seconds: 3), () async {
      _flushScheduled = false;
      final keys = _dirty.toList();
      _dirty.clear();
      for (final key in keys) {
        await _write(key);
      }
    });
  }

  /// One write per key at a time, each to a new file put in place whole, so
  /// a book's lines are never half written.
  Future<void> _write(String key) => _writes[key] = (_writes[key] ?? Future.value()).then((_) async {
        final lines = _cache[key];
        if (lines == null) return;
        try {
          final f = await _fileFor(key);
          final tmp = File('${f.path}.tmp');
          await tmp.writeAsString(jsonEncode({
            'v': 1,
            if (_readAlongs[key] != null) 'readAlong': _readAlongs[key],
            'lines': [for (final l in lines) l.toJson()],
          }));
          await tmp.rename(f.path);
        } catch (e) {
          debugPrint('[Lyrics] store write failed for $key: $e');
        }
      });
}
