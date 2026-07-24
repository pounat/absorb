/// Pure chapter index lookup, extracted from AudioPlayerService.
///
/// Finds which chapter contains a given playback position. Used by the
/// audio handler to drive Android Auto's current-chapter highlight,
/// notification chapter mode, and the queue index.
///
/// Extracted so the boundary logic can be unit-tested without spinning up
/// just_audio. Behavior must match the inline loop in
/// `audio_player_service.dart` exactly. Change one, change both.
class ChapterLookup {
  /// Return the index of the chapter containing [positionSeconds], or `null`
  /// if no chapter contains it (or if the chapter list is empty).
  ///
  /// Each chapter is expected to be a `Map<String, dynamic>` with `start`
  /// and `end` numeric fields (in seconds). Missing `start` defaults to 0;
  /// missing `end` defaults to [totalDuration].
  ///
  /// Boundary semantics: `start <= positionSeconds < end` (inclusive at
  /// start, exclusive at end). This means the boundary instant belongs to
  /// the next chapter, not the previous one.
  static int? indexAt(
    List<dynamic> chapters,
    double positionSeconds,
    double totalDuration,
  ) {
    if (chapters.isEmpty) return null;
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i] as Map<String, dynamic>;
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? totalDuration;
      if (positionSeconds >= start && positionSeconds < end) return i;
    }
    return null;
  }

  static ({double seconds, bool finishesItem})? nextSkipTarget(
    List<dynamic> chapters,
    double positionSeconds,
    double totalDuration,
  ) {
    if (chapters.isEmpty) return null;
    for (final chapter in chapters) {
      final map = chapter as Map<String, dynamic>;
      final start = (map['start'] as num?)?.toDouble() ?? 0;
      if (start > positionSeconds + 1.0) {
        return (seconds: start, finishesItem: false);
      }
    }

    final lastChapter = chapters.last as Map<String, dynamic>;
    final lastEnd = (lastChapter['end'] as num?)?.toDouble() ?? 0;
    final end = totalDuration > 0 ? totalDuration : lastEnd;
    if (end <= 0) return null;
    return (seconds: end, finishesItem: true);
  }
}
