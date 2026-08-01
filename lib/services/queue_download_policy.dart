List<T> queueTailFrom<T>({
  required List<T> items,
  required String currentKey,
  required String Function(T item) keyOf,
  bool startAtBeginningWhenMissing = false,
}) {
  final currentIndex = items.indexWhere((item) => keyOf(item) == currentKey);
  if (currentIndex < 0) {
    return startAtBeginningWhenMissing ? List<T>.from(items) : const [];
  }
  return items.sublist(currentIndex);
}

List<T> manualQueueTail<T>({
  required List<T> items,
  required String currentKey,
  required String Function(T item) keyOf,
  required bool Function(T item) isFinished,
  required bool Function(T item) isPodcast,
  required String Function(T item) queueMode,
  required String? Function(T item) libraryId,
  required bool merged,
  required bool currentIsPodcast,
  required String? currentLibraryId,
}) {
  final tail = queueTailFrom(
    items: items,
    currentKey: currentKey,
    keyOf: keyOf,
    startAtBeginningWhenMissing: true,
  );
  return tail.where((item) {
    if (isFinished(item) || queueMode(item) == 'off') return false;
    if (!merged && isPodcast(item) != currentIsPodcast) return false;
    if (!merged && currentLibraryId != null) {
      final candidateLibraryId = libraryId(item);
      if (candidateLibraryId != null &&
          candidateLibraryId != currentLibraryId) {
        return false;
      }
    }
    return true;
  }).toList();
}

List<T> podcastQueueTail<T>({
  required List<T> episodes,
  required String currentEpisodeId,
  required String Function(T episode) idOf,
  required int Function(T episode) publishedAt,
  required bool newestFirst,
}) {
  final ordered = List<T>.from(episodes)
    ..sort((a, b) {
      final comparison = publishedAt(a).compareTo(publishedAt(b));
      return newestFirst ? -comparison : comparison;
    });
  return queueTailFrom(
    items: ordered,
    currentKey: currentEpisodeId,
    keyOf: idOf,
  );
}

List<T> seriesQueueTail<T>({
  required T current,
  required Iterable<T> books,
  required String currentKey,
  required String currentSeriesId,
  required double currentSequence,
  required String Function(T book) keyOf,
  required String? Function(T book) seriesId,
  required double? Function(T book) sequence,
}) {
  final candidates = <String, T>{currentKey: current};
  for (final book in books) {
    final key = keyOf(book);
    final candidateSequence = sequence(book);
    if (key.isEmpty ||
        key == currentKey ||
        seriesId(book) != currentSeriesId ||
        candidateSequence == null ||
        candidateSequence <= currentSequence) {
      continue;
    }
    candidates.putIfAbsent(key, () => book);
  }
  final ordered = candidates.values.toList()
    ..sort((a, b) {
      final aSequence = keyOf(a) == currentKey
          ? currentSequence
          : sequence(a) ?? double.maxFinite;
      final bSequence = keyOf(b) == currentKey
          ? currentSequence
          : sequence(b) ?? double.maxFinite;
      return aSequence.compareTo(bSequence);
    });
  return ordered;
}

List<T> queueDownloadWindow<T>({
  required Iterable<T> items,
  required int count,
  required String Function(T item) keyOf,
  required bool Function(T item) isFinished,
}) {
  if (count <= 0) return const [];
  final result = <T>[];
  final seen = <String>{};
  for (final item in items) {
    final key = keyOf(item);
    if (key.isEmpty || !seen.add(key)) continue;
    if (isFinished(item)) continue;
    result.add(item);
    if (result.length == count) break;
  }
  return result;
}

List<T> queueItemsNeedingDownload<T>({
  required Iterable<T> items,
  required int count,
  required String Function(T item) keyOf,
  required bool Function(T item) isFinished,
  required bool Function(T item) isAvailable,
}) {
  return queueDownloadWindow(
    items: items,
    count: count,
    keyOf: keyOf,
    isFinished: isFinished,
  ).where((item) => !isAvailable(item)).toList();
}
