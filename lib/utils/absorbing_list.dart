import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';

/// The absorbing key for an item map: compound "itemId-episodeId" for podcast
/// episodes, plain "itemId" for books.
String absorbingKeyOf(Map<String, dynamic> item) {
  final explicit = item['_absorbingKey'] as String?;
  if (explicit != null) return explicit;
  final itemId = item['id'] as String? ?? '';
  final re = item['recentEpisode'] as Map<String, dynamic>?;
  final epId = re?['id'] as String?;
  if (epId != null) return '$itemId-$epId';
  return itemId;
}

/// The cards in the Absorbing row, in order. Shared by the phone's Absorbing
/// page and the TV home so both show the same books.
List<Map<String, dynamic>> buildAbsorbingList(
  LibraryProvider lib, {
  required AudioPlayerService player,
  required ChromecastService cast,
  required bool mergeLibraries,
  bool suppressReorder = false,
  String? lastFinishedId,
}) {
  final removes = lib.manualAbsorbRemoves;
  final cache = lib.absorbingItemCache;

  // Quick lookup of fresh data — only from the in-progress sections.
  // For podcast episodes, key by compound "itemId-episodeId".
  const allowedSections = {
    'continue-listening',
    'continue-series',
    'downloaded-books',
  };
  final sectionLookup = <String, Map<String, dynamic>>{};
  for (final section in lib.personalizedSections) {
    final sectionId = section['id'] as String? ?? '';
    if (!allowedSections.contains(sectionId)) continue;
    for (final e in (section['entities'] as List<dynamic>? ?? [])) {
      if (e is Map<String, dynamic>) {
        final itemId = e['id'] as String?;
        if (itemId == null) continue;
        final re = e['recentEpisode'] as Map<String, dynamic>?;
        final epId = re?['id'] as String?;
        final key = epId != null ? '$itemId-$epId' : itemId;
        sectionLookup[key] = e;
      }
    }
  }

  // Build list from the persisted local absorbing set.
  // Books stay here even after the server removes them from continue-listening.
  // absorbingBookIds now contains compound keys for podcast episodes.
  final selectedLibraryId = lib.selectedLibraryId;
  final items = <Map<String, dynamic>>[];
  for (final key in lib.absorbingBookIds) {
    if (removes.contains(key)) continue;
    // Prefer fresh data from current library's sections
    final fromSection = sectionLookup[key];
    if (fromSection != null) {
      items.add(fromSection);
      continue;
    }
    // Cache fallback — include if it matches the current library (or merge is on)
    final cached = cache[key];
    if (cached != null) {
      final itemLibId = cached['libraryId'] as String?;
      final mediaType = cached['mediaType'] as String?;
      final isPodItem = mediaType == 'podcast' || key.length > 36;
      if (mergeLibraries ||
          selectedLibraryId == null ||
          (itemLibId != null
              ? itemLibId == selectedLibraryId
              : isPodItem == lib.isPodcastLibrary)) {
        items.add(cached);
      }
    }
  }
  // Offline-only fallback: surface all downloads that aren't already in the
  // absorbing list. Online we keep Absorbing focused on started/queued items;
  // offline the user has no other way to reach unstarted downloads, so we
  // merge them in. Started ones already appear via the absorbingBookIds path.
  if (lib.isOffline) {
    final seenKeys = items.map(absorbingKeyOf).toSet();
    for (final section in lib.personalizedSections) {
      if ((section['id'] as String?) != 'downloaded-books') continue;
      for (final e in (section['entities'] as List<dynamic>? ?? [])) {
        if (e is! Map<String, dynamic>) continue;
        final itemId = e['id'] as String?;
        if (itemId == null) continue;
        final re = e['recentEpisode'] as Map<String, dynamic>?;
        final epId = re?['id'] as String?;
        final key = epId != null ? '$itemId-$epId' : itemId;
        if (seenKeys.contains(key)) continue;
        if (removes.contains(key)) continue;
        items.add(e);
        seenKeys.add(key);
      }
    }
  }

  // If the currently playing/casting item isn't in the list, add it at the front.
  // For podcast episodes, match by compound key.
  // Skip if the playing item belongs to a different library type.
  final isPod = lib.isPodcastLibrary;

  // Determine active item — local player takes priority, then Chromecast
  String? activeId;
  String? activeEpId;
  String? activeTitle;
  String? activeAuthor;
  String? activeEpTitle;
  double activeDuration = 0;
  List<dynamic> activeChapters = [];

  if (player.hasBook && player.currentItemId != null) {
    activeId = player.currentItemId;
    activeEpId = player.currentEpisodeId;
    activeTitle = player.currentTitle;
    activeAuthor = player.currentAuthor;
    activeEpTitle = player.currentEpisodeTitle;
    activeDuration = player.totalDuration;
    activeChapters = player.chapters;
  } else if (cast.isCasting && cast.castingItemId != null) {
    activeId = cast.castingItemId;
    activeTitle = cast.castingTitle;
    activeAuthor = cast.castingAuthor;
    activeDuration = cast.castingDuration;
    activeChapters = cast.castingChapters;
  }

  if (activeId != null) {
    final activeIsPodcast = activeEpId != null;
    // Only show if the active item matches the current library type (or merge is on)
    if (mergeLibraries || activeIsPodcast == isPod) {
      final activeKey = activeEpId != null ? '$activeId-$activeEpId' : activeId;

      final existingIdx = items.indexWhere((b) => absorbingKeyOf(b) == activeKey);
      // Only pull the active item to the top while it's actually playing.
      // When paused, leave the queue order alone so a freshly-queued
      // "beginning" episode stays first instead of being bumped to 2nd.
      final activePlaying = player.hasBook ? player.isPlaying : cast.isCasting;
      if (!suppressReorder && existingIdx > 0 && activePlaying) {
        final item = items.removeAt(existingIdx);
        items.insert(0, item);
      } else if (existingIdx < 0) {
        // Synthesize entry for the currently active item
        final entry = <String, dynamic>{
          'id': activeId,
          'media': {
            'metadata': {'title': activeTitle, 'authorName': activeAuthor},
            'duration': activeDuration,
            'chapters': activeChapters,
          },
        };
        if (activeEpId != null) {
          entry['recentEpisode'] = {
            'id': activeEpId,
            'title': activeEpTitle ?? activeTitle,
            'duration': activeDuration,
          };
          entry['_absorbingKey'] = activeKey;
        }
        items.insert(0, entry);
      }
    }
  }

  // When nothing is playing, keep the last-finished item at the front
  // Only if it matches the current library type
  if (!player.hasBook &&
      !cast.isCasting &&
      lastFinishedId != null &&
      !removes.contains(lastFinishedId)) {
    // Compound podcast keys are "uuid-uuid" (>36 chars); plain book UUIDs are 36.
    final finishedIsPodcast = lastFinishedId.length > 36;
    if (mergeLibraries || finishedIsPodcast == isPod) {
      final finishedIdx = items.indexWhere((b) => absorbingKeyOf(b) == lastFinishedId);
      // Don't pull the last-finished item over a brand-new "beginning"
      // episode that's deliberately sitting at the top.
      final freshOnTop =
          items.isNotEmpty && absorbingKeyOf(items[0]) == lib.freshQueuedFrontKey;
      if (finishedIdx > 0 && !freshOnTop) {
        final item = items.removeAt(finishedIdx);
        items.insert(0, item);
      }
    }
  }

  return items;
}
