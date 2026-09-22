import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One confirmed place where the audiobook and the ebook line up: [t] seconds
/// into the audio is [off] characters into spine section [si]. Written by
/// every successful Find in audiobook, Find in ebook and read along line, and
/// read back as anchors so the next find starts from a known spot instead of
/// a chapter-title guess.
class SyncPoint {
  final double t;
  final int si;
  final double off;
  /// 'a' = Find in audiobook, 'e' = Find in ebook, 'r' = read along.
  final String src;
  /// How far off [t] may be, in seconds. Find in ebook only knows the
  /// transcript window the words came from; the other two are near exact.
  final double err;
  final int at;

  const SyncPoint({
    required this.t,
    required this.si,
    required this.off,
    required this.src,
    this.err = 0,
    this.at = 0,
  });

  Map<String, dynamic> toJson() => {
        't': double.parse(t.toStringAsFixed(1)),
        'si': si,
        'o': off.round(),
        's': src,
        if (err > 0) 'e': double.parse(err.toStringAsFixed(1)),
        'at': at,
      };

  factory SyncPoint.fromJson(Map<String, dynamic> j) => SyncPoint(
        t: (j['t'] as num).toDouble(),
        si: (j['si'] as num).toInt(),
        off: (j['o'] as num).toDouble(),
        src: j['s'] as String? ?? 'a',
        err: (j['e'] as num?)?.toDouble() ?? 0,
        at: (j['at'] as num?)?.toInt() ?? 0,
      );
}

/// Where a finder should look first, worked out from sync points.
class SyncEstimate {
  final double est;
  final double lo;
  final double hi;
  final double rate;
  final String how;
  const SyncEstimate(this.est, this.lo, this.hi, this.rate, this.how);
}

class SyncPointEstimator {
  static const double _minRate = 0.02;
  static const double _maxRate = 0.3;

  /// Estimate for [offset] from points in the same section. Two points
  /// either side give the section's real narration pace and a tight window;
  /// one point paces from it at [fallbackRate] with a window that grows with
  /// the distance. Null when [points] is empty.
  static SyncEstimate? inSection(
      List<SyncPoint> points, double offset, double fallbackRate) {
    if (points.isEmpty) return null;
    SyncPoint? before, after;
    for (final p in points) {
      if (p.off <= offset && (before == null || p.off > before.off)) before = p;
      if (p.off >= offset && (after == null || p.off < after.off)) after = p;
    }
    if (before != null && after != null && after.off - before.off >= 50) {
      final rate = (after.t - before.t) / (after.off - before.off);
      if (rate >= _minRate && rate <= _maxRate) {
        final est = before.t + (offset - before.off) * rate;
        final span = after.t - before.t;
        final half = (span * 0.25 + before.err + after.err).clamp(60.0, 900.0);
        return SyncEstimate(est, est - half, est + half, rate, 'between');
      }
    }
    final nearest = (before == null)
        ? after!
        : (after == null)
            ? before
            : ((offset - before.off) <= (after.off - offset) ? before : after);
    return fromPoint(nearest, offset - nearest.off, fallbackRate);
  }

  /// Pace [chars] characters (negative = backwards) from [p] at [rate].
  static SyncEstimate fromPoint(SyncPoint p, double chars, double rate) {
    final est = p.t + chars * rate;
    final half = ((chars * rate).abs() * 0.5 + 90 + p.err).clamp(90.0, 1500.0);
    return SyncEstimate(est, est - half, est + half, rate, 'from ${p.src}');
  }
}

/// Per-book sync points, one JSON file per library item under app support.
/// The audio duration and spine length are stored with them so a re-encoded
/// audiobook or a swapped epub throws the old points away instead of steering
/// finds to the wrong place.
class SyncPointStore {
  SyncPointStore._();
  static final SyncPointStore instance = SyncPointStore._();

  static const int maxPoints = 600;

  final Map<String, _Book> _cache = {};
  final Set<String> _dirty = {};
  bool _flushScheduled = false;

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/sync_points');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String itemId) async =>
      File('${(await _dir()).path}/$itemId.json');

  Future<_Book> _load(String itemId) async {
    final cached = _cache[itemId];
    if (cached != null) return cached;
    var book = _Book();
    try {
      final f = await _fileFor(itemId);
      if (f.existsSync()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        book = _Book(
          audioDuration: (j['dur'] as num?)?.toDouble(),
          spineLength: (j['spine'] as num?)?.toInt(),
          points: (j['p'] as List<dynamic>? ?? const [])
              .map((e) => SyncPoint.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('[SyncPoints] load failed for $itemId: $e');
    }
    _cache[itemId] = book;
    return book;
  }

  /// Points for [itemId], dropped wholesale when the audio or the epub no
  /// longer matches what they were recorded against.
  Future<List<SyncPoint>> load(String itemId,
      {double? audioDuration, int? spineLength}) async {
    final book = await _load(itemId);
    if (_stale(book, audioDuration, spineLength)) {
      debugPrint('[SyncPoints] $itemId: book changed '
          '(audio ${book.audioDuration?.toStringAsFixed(0)} -> '
          '${audioDuration?.toStringAsFixed(0)}s, spine ${book.spineLength} -> '
          '$spineLength) - forgetting ${book.points.length} points');
      book.points.clear();
      book.audioDuration = null;
      book.spineLength = null;
      _dirty.add(itemId);
      _scheduleFlush();
    }
    _adoptShape(book, audioDuration, spineLength, itemId);
    return List.unmodifiable(book.points);
  }

  /// What [load] last returned, without touching the disk.
  List<SyncPoint> cached(String itemId) =>
      List.unmodifiable(_cache[itemId]?.points ?? const <SyncPoint>[]);

  Future<void> add(String itemId, SyncPoint p,
      {double? audioDuration, int? spineLength}) async {
    await load(itemId, audioDuration: audioDuration, spineLength: spineLength);
    final book = _cache[itemId]!;
    final stamped = SyncPoint(
      t: p.t,
      si: p.si,
      off: p.off,
      src: p.src,
      err: p.err,
      at: p.at > 0 ? p.at : DateTime.now().millisecondsSinceEpoch,
    );
    final merged = merge(book.points, stamped);
    if (identical(merged, book.points)) return;
    book.points = merged;
    debugPrint('[SyncPoints] $itemId: +${p.src} t=${p.t.toStringAsFixed(1)} '
        'si=${p.si} off=${p.off.round()} (${merged.length} points)');
    _dirty.add(itemId);
    _scheduleFlush();
  }

  /// [existing] with [p] folded in, or [existing] itself when [p] adds
  /// nothing: a near-duplicate keeps whichever is more exact, read along
  /// lines only land every so often per section, and the table stays under
  /// [maxPoints] by dropping the oldest read along points first.
  static List<SyncPoint> merge(List<SyncPoint> existing, SyncPoint p) {
    final out = List<SyncPoint>.from(existing);
    for (var i = 0; i < out.length; i++) {
      final q = out[i];
      if (q.si != p.si) continue;
      final nearChars = (q.off - p.off).abs();
      final nearSecs = (q.t - p.t).abs();
      if (nearChars < 60 && nearSecs < 8) {
        if (p.err < q.err) {
          out[i] = p;
          return out;
        }
        return existing;
      }
      if (p.src == 'r' && q.src == 'r' && (nearChars < 300 || nearSecs < 20)) {
        return existing;
      }
    }
    out.add(p);
    while (out.length > maxPoints) {
      var victim = -1;
      for (var i = 0; i < out.length; i++) {
        if (out[i].src != 'r') continue;
        if (victim < 0 || out[i].at < out[victim].at) victim = i;
      }
      if (victim < 0) {
        for (var i = 0; i < out.length; i++) {
          if (victim < 0 || out[i].at < out[victim].at) victim = i;
        }
      }
      out.removeAt(victim);
    }
    return out;
  }

  /// Forget every book's points, memory and disk. Goes with clearing the
  /// transcript cache: the points came from those transcripts.
  Future<void> clearAll() async {
    _cache.clear();
    _dirty.clear();
    try {
      final dir = await _dir();
      for (final f in dir.listSync()) {
        if (f is! File) continue;
        try {
          await f.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[SyncPoints] clear failed: $e');
    }
  }

  bool _stale(_Book book, double? audioDuration, int? spineLength) {
    if (book.points.isEmpty) return false;
    // A minute of slack: the session total and the metadata total of the
    // same audiobook can disagree by that much. A different edition is off
    // by far more.
    if (audioDuration != null &&
        book.audioDuration != null &&
        (audioDuration - book.audioDuration!).abs() > 60) {
      return true;
    }
    if (spineLength != null &&
        book.spineLength != null &&
        spineLength != book.spineLength) {
      return true;
    }
    return false;
  }

  void _adoptShape(
      _Book book, double? audioDuration, int? spineLength, String itemId) {
    var changed = false;
    if (audioDuration != null && audioDuration > 0 && book.audioDuration == null) {
      book.audioDuration = audioDuration;
      changed = true;
    }
    if (spineLength != null && spineLength > 0 && book.spineLength == null) {
      book.spineLength = spineLength;
      changed = true;
    }
    if (changed && book.points.isNotEmpty) {
      _dirty.add(itemId);
      _scheduleFlush();
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
        final book = _cache[key];
        if (book == null) continue;
        try {
          final f = await _fileFor(key);
          await f.writeAsString(jsonEncode({
            'v': 1,
            if (book.audioDuration != null) 'dur': book.audioDuration,
            if (book.spineLength != null) 'spine': book.spineLength,
            'p': [for (final p in book.points) p.toJson()],
          }));
        } catch (e) {
          debugPrint('[SyncPoints] write failed for $key: $e');
        }
      }
    });
  }
}

class _Book {
  double? audioDuration;
  int? spineLength;
  List<SyncPoint> points;
  _Book({this.audioDuration, this.spineLength, List<SyncPoint>? points})
      : points = points ?? [];
}
