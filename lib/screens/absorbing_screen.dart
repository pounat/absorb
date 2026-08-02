import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../services/download_service.dart';
import '../services/queue_download_policy.dart';
import '../services/scoped_prefs.dart';
import '../widgets/absorb_page_header.dart';
import '../main.dart' show flatNotifier, gradientIntensityNotifier, rootNavigatorKey;
import '../widgets/absorbing_card.dart';
import '../widgets/offline_status_icon.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/series_books_sheet.dart';
import '../widgets/playlist_detail_sheet.dart';
import '../widgets/collection_detail_sheet.dart';
import '../widgets/episode_list_sheet.dart';
import '../l10n/app_localizations.dart';
import '../services/wording.dart';

class AbsorbingScreen extends StatefulWidget {
  const AbsorbingScreen({super.key});

  /// Global key for accessing the absorbing screen state
  static final globalKey = GlobalKey<_AbsorbingScreenState>();

  /// Scroll to the currently playing book card
  static void scrollToActive() {
    globalKey.currentState?._scrollToActiveCard();
  }

  /// Scroll to the first card (used when re-tapping the Absorbing tab)
  static void scrollToFirst() {
    final state = globalKey.currentState;
    if (state != null && state._pageController.hasClients) {
      state._pageController.animateToPage(0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  State<AbsorbingScreen> createState() => _AbsorbingScreenState();
}

class _AbsorbingScreenState extends State<AbsorbingScreen> {
  final _player = AudioPlayerService();
  // viewportFraction is fixed at construction time, so we swap controllers
  // when orientation changes (preserving the current page index).
  PageController _pageController = PageController(viewportFraction: 0.92);
  Orientation? _lastOrientation;
  final _cardKeys = <String, GlobalKey<AbsorbingCardState>>{};

  GlobalKey<AbsorbingCardState> _cardKey(String absorbingKey) {
    return _cardKeys.putIfAbsent(absorbingKey, () => GlobalKey<AbsorbingCardState>());
  }


  final _cast = ChromecastService();
  String _queueMode = 'off';
  // Raw per-type modes behind the derived _queueMode. peekUpNext keys off these
  // (and the merge flag) directly, so the Up Next stamp must too - otherwise a
  // change to the podcast mode that leaves the derived mode unchanged (e.g. the
  // second of two sequential writes when merged) never triggers a recompute.
  String _bookQueueMode = 'off';
  String _podcastQueueMode = 'off';
  String? _queuePlaylistId;
  String? _queueCollectionName;

  @override
  void initState() {
    super.initState();
    _lastSeenHasBook = _player.hasBook;
    _lastSeenIsPlaying = _player.isPlaying;
    _player.addListener(_rebuild);
    _cast.addListener(_rebuild);
    PlayerSettings.settingsChanged.addListener(_loadQueueMode);
    _restoreLastFinished();
    _loadMergeLibraries();
    _loadQueueMode();
  }

  Future<void> _restoreLastFinished() async {
    final saved = await ScopedPrefs.getString('absorbing_last_finished');
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _lastFinishedId = saved);
    }
  }

  Future<void> _loadMergeLibraries() async {
    final v = await PlayerSettings.getMergeAbsorbingLibraries();
    if (mounted && v != _mergeLibraries) setState(() => _mergeLibraries = v);
  }

  String _activePlaylistChipLabel(LibraryProvider lib, AppLocalizations l) {
    final id = _queuePlaylistId;
    if (id == null) return l.queueModePlaylist;
    final match = lib.playlists.cast<Map<String, dynamic>>().where(
      (p) => p['id'] == id,
    ).firstOrNull;
    final n = match?['name'] as String?;
    if (n == null || n.isEmpty) return l.queueModePlaylist;
    return n.length > 24 ? '${n.substring(0, 23)}…' : n;
  }

  String _activeCollectionChipLabel(AppLocalizations l) {
    final n = _queueCollectionName;
    if (n == null || n.isEmpty) return l.queueModeCollection;
    return n.length > 24 ? '${n.substring(0, 23)}…' : n;
  }

  Future<void> _loadQueueMode() async {
    final lib = context.read<LibraryProvider>();
    String mode;
    final bm = await PlayerSettings.getBookQueueMode();
    final pm = await PlayerSettings.getPodcastQueueMode();
    final activeIsPodcast = _player.currentItemId == null
        ? lib.isPodcastLibrary
        : _player.currentEpisodeId != null;
    if (bm == 'playlist' || pm == 'playlist') {
      mode = 'playlist';
    } else if (bm == 'collection') {
      mode = activeIsPodcast ? pm : 'collection';
    } else if (_mergeLibraries) {
      // When merged, use the more restrictive of the two modes
      // (matches Settings screen's _mergedQueueMode logic)
      const order = ['off', 'manual', 'auto_next'];
      final bi = order.indexOf(bm);
      final pi = order.indexOf(pm);
      mode = order[(bi < pi ? bi : pi).clamp(0, 2)];
    } else {
      mode = activeIsPodcast ? pm : bm;
    }
    final qpId = await PlayerSettings.getQueuePlaylistId();
    final qcName = await PlayerSettings.getQueueCollectionName();
    final showUpNext = await PlayerSettings.getShowUpNextLabel();
    if (mounted) {
      setState(() {
        _queueMode = mode;
        _bookQueueMode = bm;
        _podcastQueueMode = pm;
        _queuePlaylistId = qpId;
        _queueCollectionName = qcName;
        _showUpNextLabel = showUpNext;
      });
      _refreshUpNext();
    }
  }

  bool _showUpNextLabel = true;
  String? _upNextLabel;
  String? _upNextComputedFor;
  Future<void> _refreshUpNext() async {
    final lib = context.read<LibraryProvider>();
    final currentId = _player.currentEpisodeId != null
        ? '${_player.currentItemId}-${_player.currentEpisodeId}'
        : _player.currentItemId;
    // Key off the whole queue order, not just the first item - manual mode
    // walks the queue from the current item forward, so reordering items after
    // the front changes what's up next without changing the first key.
    final queueOrder = lib.absorbingBookIds.join(',');
    final stamp = '$_queueMode|$_bookQueueMode|$_podcastQueueMode|$_mergeLibraries'
        '|$_queuePlaylistId|$_queueCollectionName|$currentId|$queueOrder';
    if (stamp == _upNextComputedFor) return;
    _upNextComputedFor = stamp;
    final label = await lib.peekUpNext(currentItemId: currentId);
    if (!mounted) return;
    if (stamp != _upNextComputedFor) return;
    if (label != _upNextLabel) setState(() => _upNextLabel = label);
  }

  @override
  void dispose() {
    _player.removeListener(_rebuild);
    _cast.removeListener(_rebuild);
    PlayerSettings.settingsChanged.removeListener(_loadQueueMode);
    _pageController.dispose();
    super.dispose();
  }

  String? _lastPlayingId;
  String? _lastPlayingEpisodeId;
  String? _lastFinishedId;
  bool _wasCasting = false;
  String? _lastCastItemId;
  String? _lastCastEpisodeId;
  bool _isSyncing = false;
  // When true, _getAbsorbingBooks keeps the original list order (no move-to-front).
  // Used during the slide-to-front animation so the user sees their book smoothly
  // slide to the beginning rather than the list instantly reordering underneath them.
  bool _suppressReorder = false;
  bool _mergeLibraries = false;
  bool? _lastSeenHasBook;
  bool? _lastSeenIsPlaying;
  bool? _lastSeenActiveSession;
  String? _lastSeenLibraryId;

  void _rebuild() {
    if (!mounted) return;

    final hasBookChanged = _player.hasBook != _lastSeenHasBook;
    final isPlayingChanged = _player.isPlaying != _lastSeenIsPlaying;
    // Stopping while already paused changes neither hasBook nor isPlaying, so
    // track the active-session flag too or the Up Next label can linger.
    final activeSessionChanged =
        _player.hasActiveSession != _lastSeenActiveSession;
    _lastSeenHasBook = _player.hasBook;
    _lastSeenIsPlaying = _player.isPlaying;
    _lastSeenActiveSession = _player.hasActiveSession;
    var shouldRebuild = hasBookChanged || isPlayingChanged || activeSessionChanged;

    // Detect item or episode change (same show, different episode counts as a change)
    final itemChanged = _player.currentItemId != _lastPlayingId;
    final episodeChanged = _player.currentEpisodeId != _lastPlayingEpisodeId;
    if (itemChanged || episodeChanged) _refreshUpNext();
    if (itemChanged || episodeChanged) {
      final wasPlayingId = _lastPlayingId;
      final wasEpisodeId = _lastPlayingEpisodeId;
      _lastPlayingId = _player.currentItemId;
      _lastPlayingEpisodeId = _player.currentEpisodeId;
      if (_player.hasBook) {
        // If this item was previously removed from Absorbing, un-block it now
        // that the user has explicitly played it again.
        final lib = context.read<LibraryProvider>();
        final playingKey = _player.currentEpisodeId != null
            ? '${_player.currentItemId!}-${_player.currentEpisodeId!}'
            : _player.currentItemId!;
        lib.unblockFromAbsorbing(playingKey,
          episodeTitle: _player.currentEpisodeTitle,
          episodeDuration: _player.currentEpisodeId != null ? _player.totalDuration : null,
        );
        // Persist so this item stays at front even if the app is killed
        _lastFinishedId = playingKey;
        ScopedPrefs.setString('absorbing_last_finished', playingKey);
        // Suppress the list reorder if we're not already at page 0, so the
        // animation slides the current view to the front instead of jumping.
        final currentPage = _pageController.hasClients
            ? (_pageController.page ?? 0).round()
            : 0;
        _suppressReorder = currentPage > 0;
        if (!_suppressReorder) {
          // No animation needed — persist the move-to-front immediately.
          lib.moveAbsorbingToFront(playingKey);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveCard());
      } else if (wasPlayingId != null && !_isSyncing) {
        // Playback stopped — keep this item at the front of the list.
        // Don't call markFinishedLocally here: actual completion is handled
        // by _onBookFinishedCallback, which fires from the player service.
        _suppressReorder = false;
        final finishedKey = wasEpisodeId != null
            ? '$wasPlayingId-$wasEpisodeId'
            : wasPlayingId;
        _lastFinishedId = finishedKey;
        ScopedPrefs.setString('absorbing_last_finished', finishedKey);
      }
      shouldRebuild = true;
    }

    // Track cast state — when casting starts, scroll to the card;
    // when it stops/disconnects, keep that card at front.
    final nowCasting = _cast.isCasting;
    if (nowCasting && !_wasCasting) {
      // Casting just started — move cast card to front, same as local playback
      _lastCastItemId = _cast.castingItemId;
      _lastCastEpisodeId = _cast.castingEpisodeId;
      final castKey = _lastCastEpisodeId != null
          ? '$_lastCastItemId-$_lastCastEpisodeId'
          : _lastCastItemId!;
      final lib = context.read<LibraryProvider>();
      lib.unblockFromAbsorbing(castKey);
      _lastFinishedId = castKey;
      ScopedPrefs.setString('absorbing_last_finished', castKey);
      final currentPage = _pageController.hasClients
          ? (_pageController.page ?? 0).round() : 0;
      _suppressReorder = currentPage > 0;
      if (!_suppressReorder) {
        lib.moveAbsorbingToFront(castKey);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveCard());
    } else if (nowCasting) {
      _lastCastItemId = _cast.castingItemId;
      _lastCastEpisodeId = _cast.castingEpisodeId;
    } else if (_wasCasting && _lastCastItemId != null) {
      final finishedKey = _lastCastEpisodeId != null
          ? '$_lastCastItemId-$_lastCastEpisodeId'
          : _lastCastItemId!;
      _lastFinishedId = finishedKey;
      ScopedPrefs.setString('absorbing_last_finished', finishedKey);
      _lastCastItemId = null;
      _lastCastEpisodeId = null;
    }
    final castChanged = nowCasting != _wasCasting;
    _wasCasting = nowCasting;

    if (shouldRebuild || castChanged) {
      setState(() {});
    }
  }

  void _scrollToActiveCard({int retries = 2}) {
    if (!mounted) return;

    // Determine the active key — local player takes priority, then cast
    String? playingKey;
    if (_player.hasBook && _player.currentItemId != null) {
      playingKey = _player.currentEpisodeId != null
          ? '${_player.currentItemId!}-${_player.currentEpisodeId!}'
          : _player.currentItemId!;
    } else if (_cast.isCasting && _cast.castingItemId != null) {
      playingKey = _cast.castingEpisodeId != null
          ? '${_cast.castingItemId!}-${_cast.castingEpisodeId!}'
          : _cast.castingItemId!;
    }
    if (playingKey == null) return;

    final lib = context.read<LibraryProvider>();
    final books = _getAbsorbingBooks(lib);
    final idx = books.indexWhere((b) => _absorbingKey(b) == playingKey);
    if (idx >= 0 && _pageController.hasClients) {
      if (_suppressReorder) {
        // Animate from the current page to 0 while keeping the original list order.
        // After the animation lands at 0, release suppression so the list properly
        // reorders with the playing item at index 0.
        _pageController
            .animateToPage(0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic)
            .then((_) {
          if (!mounted) return;
          _suppressReorder = false;
          // Persist the played item at front so subsequent plays
          // maintain the correct order instead of reverting.
          if (playingKey != null) {
            context.read<LibraryProvider>().moveAbsorbingToFront(playingKey);
          }
          setState(() {});
        });
      } else {
        _pageController.animateToPage(idx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic);
      }
    } else if (retries > 0) {
      // Book might not be in the list yet — retry after a rebuild
      _suppressReorder = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToActiveCard(retries: retries - 1);
      });
    } else {
      _suppressReorder = false;
    }
  }

  Future<void> _stopAndRefresh(LibraryProvider lib) async {
    if (_isSyncing) return;
    // Capture what was playing before stopping, so _lastFinishedId survives
    // the _isSyncing guard in _rebuild and keeps the card at the front.
    if (_player.hasBook && _player.currentItemId != null) {
      final epId = _player.currentEpisodeId;
      _lastFinishedId = epId != null
          ? '${_player.currentItemId!}-$epId'
          : _player.currentItemId!;
      ScopedPrefs.setString('absorbing_last_finished', _lastFinishedId!);
    }
    setState(() => _isSyncing = true);
    if (_player.hasBook) {
      await _player.pause();
      await _player.stop();
    }
    lib.refreshLocalProgress();
    await lib.refresh();
    if (mounted) setState(() => _isSyncing = false);
  }

  /// Pull-to-refresh: sync progress to/from server without stopping playback.
  Future<void> _pullRefresh() async {
    final lib = context.read<LibraryProvider>();
    if (lib.isOffline) return;
    await lib.refresh();
  }


  /// Derive the absorbing key for an item map: compound "itemId-episodeId" for
  /// podcast episodes, plain "itemId" for books.
  String _absorbingKey(Map<String, dynamic> item) {
    // Explicit key stored by _updateAbsorbingCache
    final explicit = item['_absorbingKey'] as String?;
    if (explicit != null) return explicit;
    final itemId = item['id'] as String? ?? '';
    final re = item['recentEpisode'] as Map<String, dynamic>?;
    final epId = re?['id'] as String?;
    if (epId != null) return '$itemId-$epId';
    return itemId;
  }

  List<Map<String, dynamic>> _getAbsorbingBooks(LibraryProvider lib) {
    final removes = lib.manualAbsorbRemoves;
    final cache = lib.absorbingItemCache;

    // Quick lookup of fresh data — only from the in-progress sections.
    // For podcast episodes, key by compound "itemId-episodeId".
    const allowedSections = {'continue-listening', 'continue-series', 'downloaded-books'};
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
    final skippedKeys = <String, String>{};
    for (final key in lib.absorbingBookIds) {
      if (removes.contains(key)) { skippedKeys[key] = 'removed'; continue; }
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
        if (_mergeLibraries || selectedLibraryId == null ||
            (itemLibId != null ? itemLibId == selectedLibraryId : isPodItem == lib.isPodcastLibrary)) {
          items.add(cached);
        } else {
          skippedKeys[key] = 'wrong library (item=$itemLibId, selected=$selectedLibraryId)';
        }
      } else {
        skippedKeys[key] = 'not in section or cache';
      }
    }
    // Offline-only fallback: surface all downloads that aren't already in the
    // absorbing list. Online we keep Absorbing focused on started/queued items;
    // offline the user has no other way to reach unstarted downloads, so we
    // merge them in. Started ones already appear via the absorbingBookIds path.
    if (lib.isOffline) {
      final seenKeys = items.map(_absorbingKey).toSet();
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

    if (_player.hasBook && _player.currentItemId != null) {
      activeId = _player.currentItemId;
      activeEpId = _player.currentEpisodeId;
      activeTitle = _player.currentTitle;
      activeAuthor = _player.currentAuthor;
      activeEpTitle = _player.currentEpisodeTitle;
      activeDuration = _player.totalDuration;
      activeChapters = _player.chapters;
    } else if (_cast.isCasting && _cast.castingItemId != null) {
      activeId = _cast.castingItemId;
      activeTitle = _cast.castingTitle;
      activeAuthor = _cast.castingAuthor;
      activeDuration = _cast.castingDuration;
      activeChapters = _cast.castingChapters;
    }

    if (activeId != null) {
      final activeIsPodcast = activeEpId != null;
      // Only show if the active item matches the current library type (or merge is on)
      if (_mergeLibraries || activeIsPodcast == isPod) {
        final activeKey = activeEpId != null ? '$activeId-$activeEpId' : activeId;

        final existingIdx = items.indexWhere((b) => _absorbingKey(b) == activeKey);
        // Only pull the active item to the top while it's actually playing.
        // When paused, leave the queue order alone so a freshly-queued
        // "beginning" episode stays first instead of being bumped to 2nd.
        final activePlaying = _player.hasBook ? _player.isPlaying : _cast.isCasting;
        if (!_suppressReorder && existingIdx > 0 && activePlaying) {
          final item = items.removeAt(existingIdx);
          items.insert(0, item);
        } else if (existingIdx < 0) {
          // Synthesize entry for the currently active item
          final entry = <String, dynamic>{
            'id': activeId,
            'media': {
              'metadata': {
                'title': activeTitle,
                'authorName': activeAuthor,
              },
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
    if (!_player.hasBook && !_cast.isCasting && _lastFinishedId != null && !removes.contains(_lastFinishedId)) {
      // Compound podcast keys are "uuid-uuid" (>36 chars); plain book UUIDs are 36.
      final finishedIsPodcast = _lastFinishedId!.length > 36;
      if (_mergeLibraries || finishedIsPodcast == isPod) {
        final finishedIdx = items.indexWhere((b) => _absorbingKey(b) == _lastFinishedId);
        // Don't pull the last-finished item over a brand-new "beginning"
        // episode that's deliberately sitting at the top.
        final freshOnTop = items.isNotEmpty &&
            _absorbingKey(items[0]) == lib.freshQueuedFrontKey;
        if (finishedIdx > 0 && !freshOnTop) {
          final item = items.removeAt(finishedIdx);
          items.insert(0, item);
        }
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    _loadMergeLibraries(); // refresh in case setting changed
    _loadQueueMode(); // refresh for current library type
    _refreshUpNext(); // stamp short-circuits when nothing changed
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final lowerFade = Color.lerp(cs.surface, scaffoldBg, 0.55) ?? scaffoldBg;
    final lib = context.watch<LibraryProvider>();
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.shortestSide >= 600;
    final isPhoneLandscape = !isTablet && mq.orientation == Orientation.landscape;

    // Swap the PageController when orientation changes so we can go nearly
    // edge-to-edge on phone landscape while keeping the side peek in portrait.
    if (_lastOrientation != null && _lastOrientation != mq.orientation) {
      final currentPage = _pageController.hasClients
          ? (_pageController.page ?? _pageController.initialPage.toDouble()).round()
          : 0;
      final oldController = _pageController;
      _pageController = PageController(
        initialPage: currentPage,
        viewportFraction: isPhoneLandscape ? 0.95 : 0.92,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => oldController.dispose());
    }
    _lastOrientation = mq.orientation;

    // Reset carousel to first card when library changes
    if (lib.selectedLibraryId != _lastSeenLibraryId && _lastSeenLibraryId != null) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
    _lastSeenLibraryId = lib.selectedLibraryId;
    final dl = DownloadService();
    var books = _getAbsorbingBooks(lib);
    
    // When offline, only show downloaded books — but always keep the
    // currently playing/casting item visible so controls remain accessible.
    final effectiveOffline = lib.isOffline;
    if (effectiveOffline) {
      String? activeKey;
      if (_player.hasBook && _player.currentItemId != null) {
        activeKey = _player.currentEpisodeId != null
            ? '${_player.currentItemId!}-${_player.currentEpisodeId!}'
            : _player.currentItemId!;
      } else if (_cast.isCasting && _cast.castingItemId != null) {
        activeKey = _cast.castingEpisodeId != null
            ? '${_cast.castingItemId!}-${_cast.castingEpisodeId!}'
            : _cast.castingItemId!;
      }
      books = books.where((b) {
        if (activeKey != null && _absorbingKey(b) == activeKey) return true;
        final dlKey = _absorbingKey(b);
        return dl.isDownloaded(dlKey);
      }).toList();
    }

    final showBlockingLoader = lib.isLoading &&
        books.isEmpty &&
        !_player.hasBook &&
        !_cast.isCasting &&
        lib.personalizedSections.isEmpty;

    final muted = cs.onSurfaceVariant;
    final subtleBg = cs.onSurface.withValues(alpha: 0.06);
    final subtleBorder = cs.onSurface.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Container(
        decoration: flatNotifier.value ? null : BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.22, 0.72, 1.0],
            colors: [
              cs.primary.withValues(alpha: gradientIntensityNotifier.value),
              cs.surface,
              lowerFade,
              scaffoldBg,
            ],
          ),
        ),
        child: SafeArea(
        child: Builder(builder: (context) {
          final offlineIcon = OfflineStatusIcon(
            onTapWhenOnline: () {
              lib.setManualOffline(true);
              final dl = DownloadService();
              final itemId = _player.currentItemId;
              final epId = _player.currentEpisodeId;
              final dlKey = epId != null && itemId != null
                  ? '$itemId-$epId'
                  : itemId;
              if (dlKey == null || !dl.isDownloaded(dlKey)) {
                _stopAndRefresh(lib);
              }
            },
          );

          final headerActions = <Widget>[
            if (_player.hasBook)
              GestureDetector(
                onTap: _isSyncing ? null : () => _stopAndRefresh(lib),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: subtleBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: subtleBorder),
                  ),
                  child: SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSyncing)
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: muted))
                        else
                          Icon(Icons.stop_rounded, size: 18, color: muted),
                        const SizedBox(width: 4),
                        Text(l.absorbingStop, style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              )
            else if (!effectiveOffline)
              GestureDetector(
                onTap: _isSyncing ? null : () async {
                  setState(() => _isSyncing = true);
                  await _pullRefresh();
                  if (mounted) setState(() => _isSyncing = false);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: subtleBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: subtleBorder),
                  ),
                  child: _isSyncing
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: muted))
                      : Icon(Icons.refresh_rounded, size: 18, color: muted),
                ),
              ),
            if (books.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showReorderSheet(context, lib, books),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: subtleBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: subtleBorder),
                  ),
                  child: SizedBox(
                    height: 20,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.reorder_rounded, size: 18, color: muted),
                      if (_queueMode != 'off') ...[
                        const SizedBox(width: 4),
                        Text(
                          _queueMode == 'playlist'
                              ? _activePlaylistChipLabel(lib, l)
                              : _queueMode == 'collection'
                                  ? _activeCollectionChipLabel(l)
                                  : _queueMode == 'auto_next'
                                      ? (_mergeLibraries ? l.queueModeAuto : lib.isPodcastLibrary ? l.queueModeShowLabel : l.queueModeSeriesLabel)
                                      : l.queueModeManual,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.primary),
                        ),
                      ],
                    ]),
                  ),
                ),
              ),
            ],
          ];

          final pageDots = books.length > 1
              ? _PageDots(count: books.length, controller: _pageController)
              : null;

          // Compact landscape header: one row containing the ABSORB branding,
          // offline icon, page dots, and actions. Skips the large "Absorbing"
          // title row to give the card more vertical breathing room.
          final landscapeHeader = Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
            child: Row(
              children: [
                Text(
                  l.appTitle,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(width: 8),
                offlineIcon,
                if (pageDots != null) ...[
                  const SizedBox(width: 12),
                  Expanded(child: pageDots),
                  const SizedBox(width: 12),
                ] else
                  const Spacer(),
                ...headerActions,
              ],
            ),
          );

          final portraitHeader = AbsorbPageHeader(
            title: Wording.of(context).absorbingTitle,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            trailing: offlineIcon,
            actions: headerActions,
          );

        return Column(
          children: [
            // ── Header ──
            // Phone landscape uses the compact single-row header; everything
            // else (portrait, tablets in any orientation) keeps the full header.
            if (isPhoneLandscape) landscapeHeader else portraitHeader,
            // Hide Up Next when the session is stopped (not merely paused) -
            // hasActiveSession stays true while paused but goes false once the
            // engine is stopped, so a stopped session with items still in the
            // queue won't show a confusing "Nothing is up next".
            if (_player.hasActiveSession && _showUpNextLabel && _queueMode != 'off' && books.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Builder(builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final greenColor = isDark ? Colors.greenAccent[400] : Colors.green.shade700;
                    final redColor = isDark ? Colors.redAccent[200] : Colors.red.shade700;
                    final hasNext = _upNextLabel != null;
                    return Text(
                      hasNext ? l.upNext(_upNextLabel!) : l.nothingUpNext,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasNext ? greenColor : redColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ),
              ),
            // ── Page Dots (compact header inlines them in phone landscape) ──
            if (!isPhoneLandscape && pageDots != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: pageDots,
              ),
            // ── Cards (refreshable) ──
            Expanded(
              child: showBlockingLoader
                  ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.24)))
                  : books.isEmpty
                      ? _emptyState(cs, tt, effectiveOffline, l)
                      : books.length == 1
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                final vPad = isPhoneLandscape
                                    ? 0.0
                                    : (constraints.maxHeight * 0.01).clamp(2.0, 16.0);
                                final hPad = isPhoneLandscape ? 0.0 : 4.0;
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                                  child: RepaintBoundary(child: AbsorbingCard(key: _cardKey(_absorbingKey(books[0])), item: books[0], player: _player)),
                                );
                              },
                            )
                          : PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                          itemCount: books.length,
                          itemBuilder: (_, i) => LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = constraints.maxWidth;
                              final vPad = isPhoneLandscape
                                  ? 0.0
                                  : (constraints.maxHeight * 0.01).clamp(2.0, 16.0);
                              final hPad = isPhoneLandscape ? 0.0 : 4.0;
                              return AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, child) {
                                  double distFromCenter = 0.0;
                                  double rawDist = 0.0;
                                  if (_pageController.hasClients && _pageController.positions.length == 1 && _pageController.position.haveDimensions) {
                                    final page = _pageController.page ?? _pageController.initialPage.toDouble();
                                    rawDist = page - i; // negative = card is to the right
                                    distFromCenter = rawDist.abs();
                                  }
                                  final double scaleX;
                                  if (distFromCenter >= 1.0) {
                                    scaleX = 0.85;
                                  } else {
                                    // Use easeOut curve for smoother transition
                                    final t = Curves.easeOut.transform(1.0 - distFromCenter);
                                    scaleX = 0.85 + (t * 0.15); // 0.85 → 1.0
                                  }
                                  // Calculate how much space the squeeze frees up, then translate toward center
                                  final squeezedWidth = cardWidth * scaleX;
                                  final freedSpace = cardWidth - squeezedWidth;
                                  // Pull card toward center by half the freed space
                                  final direction = rawDist > 0 ? 1.0 : (rawDist < 0 ? -1.0 : 0.0);
                                  final translateX = direction * freedSpace * 0.45;

                                  return Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..translate(translateX, 0.0, 0.0)
                                      ..scale(scaleX, 1.0, 1.0),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                                      child: child,
                                    ),
                                  );
                                },
                                child: RepaintBoundary(child: AbsorbingCard(key: _cardKey(_absorbingKey(books[i])), item: books[i], player: _player)),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
        }),
      ),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs, TextTheme tt, bool isOffline, AppLocalizations l) {
    final lib = context.read<LibraryProvider>();
    final isPod = lib.isPodcastLibrary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOffline ? Icons.cloud_off_rounded
              : isPod ? Icons.podcasts_rounded : Icons.headphones_rounded,
            size: 64, color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(isOffline
              ? (isPod ? l.absorbingNoDownloadedEpisodes : l.absorbingNoDownloadedBooks)
              : (isPod ? l.absorbingNothingPlayingYet : Wording.of(context).absorbingNothingAbsorbingYet),
            style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(isOffline
              ? (isPod ? l.absorbingDownloadEpisodesToListen : l.absorbingDownloadBooksToListen)
              : (isPod ? l.absorbingStartEpisodeFromShows : l.absorbingStartBookFromLibrary),
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24))),
        ],
      ),
    );
  }

  void _showReorderSheet(BuildContext context, LibraryProvider lib, List<Map<String, dynamic>> books) {
    final keys = books.map((b) => _absorbingKey(b)).toList();
    final media = MediaQuery.of(context);
    final needsMoreRoom = media.size.height < 600 ||
        media.textScaler.scale(1) > 1.2;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: needsMoreRoom ? 0.9 : 0.7,
        minChildSize: needsMoreRoom ? 0.85 : 0.5,
        maxChildSize: 1.0,
        builder: (_, scrollController) => _ReorderAbsorbingSheet(
          keys: keys,
          books: books,
          lib: lib,
          scrollController: scrollController,
          absorbingKeyFn: _absorbingKey,
          queueMode: _queueMode,
          isMerged: _mergeLibraries,
          isPodcast: lib.isPodcastLibrary,
          currentItemId: _player.currentEpisodeId != null
              ? '${_player.currentItemId}-${_player.currentEpisodeId}'
              : _player.currentItemId,
          onQueueModeChanged: (mode) async {
            if (mode == 'playlist') {
              final pid = await PlayerSettings.getQueuePlaylistId();
              if (pid == null) {
                if (context.mounted) {
                  final hint = AppLocalizations.of(context)!.queueModePlaylistHint;
                  showOverlayToast(context, hint,
                      icon: Icons.playlist_play_rounded);
                }
                return;
              }
              await PlayerSettings.setQueueModePlaylist(pid);
              unawaited(lib.syncQueueAutoDownloads());
              return;
            }
            if (_mergeLibraries || _queueMode == 'playlist') {
              await PlayerSettings.setBookQueueMode(mode);
              await PlayerSettings.setPodcastQueueMode(mode);
            } else {
              final isPod = _player.currentItemId == null
                  ? lib.isPodcastLibrary
                  : _player.currentEpisodeId != null;
              if (isPod) {
                await PlayerSettings.setPodcastQueueMode(mode);
              } else {
                await PlayerSettings.setBookQueueMode(mode);
              }
            }
            PlayerSettings.notifySettingsChanged();
            unawaited(lib.syncQueueAutoDownloads());
          },
        ),
      ),
    );
  }
}

// ─── PAGE DOTS ──────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final PageController controller;
  const _PageDots({required this.count, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      // Active dot is 20 wide, inactive is 6, each has horizontal padding on both sides.
      // Solve for padding: count * (6 + 2*pad) + (20 - 6) <= maxWidth
      // pad = (maxWidth - 14 - count * 6) / (count * 2)
      const double dotSize = 6;
      const double activeDotWidth = 20;
      final maxWidth = constraints.maxWidth;
      final extraActive = activeDotWidth - dotSize;
      final available = maxWidth - extraActive - count * dotSize;
      final hPad = (available / (count * 2)).clamp(1.5, 8.0);

      return ListenableBuilder(
        listenable: controller,
        builder: (_, __) {
          final page = controller.hasClients && controller.positions.length == 1 ? (controller.page ?? 0).round() : 0;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final active = i == page;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => controller.animateToPage(i,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: active ? activeDotWidth : dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: active ? cs.onSurface.withValues(alpha: 0.54) : cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      );
    });
  }
}

// ─── REORDER ABSORBING SHEET ──────────────────────────────────

class _ReorderAbsorbingSheet extends StatefulWidget {
  final List<String> keys;
  final List<Map<String, dynamic>> books;
  final LibraryProvider lib;
  final ScrollController scrollController;
  final String Function(Map<String, dynamic>) absorbingKeyFn;
  final String queueMode;
  final bool isMerged;
  final bool isPodcast;
  final ValueChanged<String> onQueueModeChanged;
  final String? currentItemId;

  const _ReorderAbsorbingSheet({
    required this.keys,
    required this.books,
    required this.lib,
    required this.scrollController,
    required this.absorbingKeyFn,
    required this.queueMode,
    required this.isMerged,
    required this.isPodcast,
    required this.onQueueModeChanged,
    required this.currentItemId,
  });

  @override
  State<_ReorderAbsorbingSheet> createState() => _ReorderAbsorbingSheetState();
}

class _ReorderAbsorbingSheetState extends State<_ReorderAbsorbingSheet> {
  late List<String> _order;
  late Map<String, Map<String, dynamic>> _booksByKey;
  late String _queueMode;
  late final DownloadService _downloads;
  late final AudioPlayerService _player;
  String? _currentItemId;

  @override
  void initState() {
    super.initState();
    _order = List.from(widget.keys);
    _booksByKey = {
      for (final b in widget.books) widget.absorbingKeyFn(b): b,
    };
    _queueMode = widget.queueMode;
    _currentItemId = widget.currentItemId;
    _downloads = DownloadService()..addListener(_onDownloadsChanged);
    _player = AudioPlayerService()..addListener(_onPlayerChanged);
    PlayerSettings.settingsChanged.addListener(_refreshMode);
    PlayerSettings.getShowUpNextLabel().then((v) {
      if (mounted) setState(() => _showUpNext = v);
    });
    final showId = _currentPodcastShowId;
    if (showId != null) {
      PlayerSettings.getPodcastAdvanceDir(showId).then((v) {
        if (mounted && _currentPodcastShowId == showId) {
          setState(() => _podcastAdvanceDir = v);
        }
      });
    }
    unawaited(_refreshMode());
    unawaited(_loadModeContent());
  }

  bool _showUpNext = true;
  bool _queueAutoDownload = false;
  bool _queueDownloadSettingsLoaded = false;
  int _rollingDownloadCount = 3;
  String _podcastAdvanceDir = 'oldest_first';

  void _onDownloadsChanged() {
    if (mounted) setState(() {});
  }

  void _onPlayerChanged() {
    final itemId = _player.currentItemId;
    final episodeId = _player.currentEpisodeId;
    final nextKey = itemId == null
        ? null
        : episodeId == null
            ? itemId
            : '$itemId-$episodeId';
    if (!mounted || nextKey == _currentItemId) return;
    setState(() {
      _currentItemId = nextKey;
      _queueDownloadSettingsLoaded = false;
      _seriesBooks = null;
      _seriesId = null;
      _seriesName = null;
      _showEpisodes = null;
      _showItem = null;
      _showName = null;
    });
    final showId = _currentPodcastShowId;
    if (showId != null) {
      PlayerSettings.getPodcastAdvanceDir(showId).then((value) {
        if (mounted && _currentPodcastShowId == showId) {
          setState(() => _podcastAdvanceDir = value);
        }
      });
    }
    unawaited(_refreshMode());
    unawaited(_loadModeContent());
  }

  // Show id of the currently playing podcast, or null if a book (or nothing)
  // is playing. _currentItemId is the compound "<itemId>-<episodeId>" key for
  // podcasts, so a length past 36 means an episode is playing.
  String? get _currentPodcastShowId {
    final id = _currentItemId;
    if (id == null || id.length <= 36) return null;
    return id.substring(0, 36);
  }

  bool get _currentIsPodcast =>
      _currentPodcastShowId != null ||
      (_currentItemId == null && widget.isPodcast);

  String? get _activeAutoDownloadSourceId {
    if (_queueMode != 'auto_next') return null;
    return _currentPodcastShowId ?? _seriesId;
  }

  Future<void> _refreshQueueDownloadSettings() async {
    final queueMode = _queueMode;
    final sourceId = _activeAutoDownloadSourceId;
    final globalEnabled = await PlayerSettings.getQueueAutoDownload();
    final count = await PlayerSettings.getRollingDownloadCount();
    if (!mounted ||
        queueMode != _queueMode ||
        sourceId != _activeAutoDownloadSourceId) return;
    setState(() {
      _queueAutoDownload = resolveQueueAutoDownloadEnabled(
        queueMode: queueMode,
        globalEnabled: globalEnabled,
        activeSourceId: sourceId,
        activeSourceEnabled:
            sourceId != null && widget.lib.isRollingDownloadEnabled(sourceId),
      );
      _rollingDownloadCount = count;
      _queueDownloadSettingsLoaded = true;
    });
  }

  Future<void> _setQueueAutoDownload(bool value) async {
    final sourceId = _activeAutoDownloadSourceId;
    setState(() => _queueAutoDownload = value);
    if (_queueMode == 'auto_next' && sourceId != null) {
      if (value) {
        await widget.lib.enableRollingDownload(sourceId);
      } else {
        await widget.lib.disableRollingDownload(sourceId);
      }
    } else {
      await PlayerSettings.setQueueAutoDownload(value);
    }
    unawaited(widget.lib.syncQueueAutoDownloads());
  }

  // Stage 3: mode-aware rendering. For auto_next we show the active series'
  // books; for playlist we show the active playlist's items. Cached here so
  // the list paints without a flash while the API call completes.
  List<Map<String, dynamic>>? _seriesBooks;
  String? _seriesId;
  String? _seriesName;
  List<Map<String, dynamic>>? _playlistItems;
  String? _playlistId;
  String? _playlistName;
  List<Map<String, dynamic>>? _collectionBooks;
  String? _collectionId;
  String? _collectionName;
  String? _activeQueueSourceId;
  int _modeContentGeneration = 0;
  // Podcast auto_next: the current show's episodes (unsorted - the list sorts
  // by _podcastAdvanceDir at build so flipping the toggle reorders live).
  List<Map<String, dynamic>>? _showEpisodes;
  Map<String, dynamic>? _showItem;
  String? _showName;

  Future<void> _loadModeContent() async {
    final generation = ++_modeContentGeneration;
    if (_queueMode == 'auto_next') {
      // Discriminate on the playing item, not the library: a podcast can be
      // playing inside a book library (and vice versa). Podcast auto advances
      // within the current show; books advance through the series.
      if (_currentPodcastShowId != null) {
        await _loadShowEpisodes(generation);
      } else if (_currentItemId != null) {
        await _loadSeriesBooks(generation);
      }
    } else if (_queueMode == 'playlist') {
      await _loadPlaylistContent(generation);
    } else if (_queueMode == 'collection') {
      await _loadCollectionContent(generation);
    }
    if (!mounted || generation != _modeContentGeneration) return;
    await _refreshQueueDownloadSettings();
  }

  Future<void> _loadShowEpisodes(int generation) async {
    final showId = _currentPodcastShowId;
    if (showId == null) return;
    // The absorbing cache only holds per-episode synthetic entries, so fetch
    // the show fresh to get the full episode list.
    final item = await widget.lib.fetchLibraryItem(showId);
    if (!mounted ||
        generation != _modeContentGeneration ||
        _queueMode != 'auto_next' ||
        item == null ||
        _currentPodcastShowId != showId) {
      return;
    }
    final media = item['media'] as Map<String, dynamic>? ?? const {};
    final eps = (media['episodes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
    setState(() {
      _showItem = item;
      _showEpisodes = eps;
      _showName = metadata['title'] as String?;
    });
  }

  Future<void> _loadSeriesBooks(int generation) async {
    final currentId = _currentItemId;
    if (currentId == null) return;
    final cache = widget.lib.absorbingItemCache;
    Map<String, dynamic>? data = cache[currentId];
    final auth = widget.lib;
    // Fall back to the server if we don't have full series metadata cached.
    if (data == null || widget.lib.extractSeries(data).$1 == null) {
      final fetched = await auth.fetchLibraryItem(currentId);
      if (fetched != null) data = fetched;
    }
    if (data == null) return;
    final (sid, _) = widget.lib.extractSeries(data);
    if (sid == null) return;
    final libraryId = data['libraryId'] as String? ?? widget.lib.selectedLibraryId;
    if (libraryId == null) return;
    final books = await auth.fetchBooksBySeries(libraryId, sid);
    if (!mounted ||
        generation != _modeContentGeneration ||
        _queueMode != 'auto_next' ||
        _currentItemId != currentId) {
      return;
    }
    // Pull the series name from the current book's metadata.
    final media = data['media'] as Map<String, dynamic>? ?? const {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
    final seriesRaw = metadata['series'];
    String? seriesName;
    if (seriesRaw is List) {
      for (final s in seriesRaw) {
        if (s is Map && s['id'] == sid) {
          seriesName = s['name'] as String?;
          break;
        }
      }
    } else if (seriesRaw is Map) {
      seriesName = seriesRaw['name'] as String?;
    }
    setState(() {
      _seriesBooks = books;
      _seriesId = sid;
      _seriesName = seriesName;
    });
  }

  Future<void> _loadPlaylistContent(int generation) async {
    final pid =
        _activeQueueSourceId ?? await PlayerSettings.getQueuePlaylistId();
    if (pid == null) return;
    final pl = await widget.lib.fetchPlaylistById(pid);
    final currentPid = await PlayerSettings.getQueuePlaylistId();
    if (!mounted ||
        generation != _modeContentGeneration ||
        _queueMode != 'playlist' ||
        currentPid != pid ||
        pl == null) {
      return;
    }
    final items = ((pl['items'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    setState(() {
      _playlistItems = items;
      _playlistId = pid;
      _playlistName = pl['name'] as String?;
      _activeQueueSourceId = pid;
    });
  }

  Future<void> _loadCollectionContent(int generation) async {
    final cid =
        _activeQueueSourceId ?? await PlayerSettings.getQueueCollectionId();
    if (cid == null) return;
    final c = await widget.lib.fetchCollectionById(cid);
    final currentCid = await PlayerSettings.getQueueCollectionId();
    if (!mounted ||
        generation != _modeContentGeneration ||
        _queueMode != 'collection' ||
        currentCid != cid ||
        c == null) {
      return;
    }
    final books = ((c['books'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    setState(() {
      _collectionBooks = books;
      _collectionId = cid;
      _collectionName = c['name'] as String?;
      _activeQueueSourceId = cid;
    });
  }

  @override
  void dispose() {
    _downloads.removeListener(_onDownloadsChanged);
    _player.removeListener(_onPlayerChanged);
    PlayerSettings.settingsChanged.removeListener(_refreshMode);
    super.dispose();
  }

  Future<void> _refreshMode() async {
    final bm = await PlayerSettings.getBookQueueMode();
    final pm = await PlayerSettings.getPodcastQueueMode();
    String mode;
    if (bm == 'playlist' || pm == 'playlist') {
      mode = 'playlist';
    } else if (bm == 'collection') {
      mode = _currentIsPodcast ? pm : 'collection';
    } else if (widget.isMerged) {
      const order = ['off', 'manual', 'auto_next'];
      final bi = order.indexOf(bm);
      final pi = order.indexOf(pm);
      mode = order[(bi < pi ? bi : pi).clamp(0, 2)];
    } else {
      mode = _currentIsPodcast ? pm : bm;
    }
    final sourceId = mode == 'playlist'
        ? await PlayerSettings.getQueuePlaylistId()
        : mode == 'collection'
            ? await PlayerSettings.getQueueCollectionId()
            : null;
    if (!mounted) return;
    final modeChanged = mode != _queueMode;
    final sourceChanged = sourceId != _activeQueueSourceId;
    if (modeChanged || sourceChanged) {
      setState(() {
        _queueMode = mode;
        _activeQueueSourceId = sourceId;
        _queueDownloadSettingsLoaded = false;
        if (modeChanged || mode == 'playlist') {
          _playlistItems = null;
          _playlistId = null;
          _playlistName = null;
        }
        if (modeChanged || mode == 'collection') {
          _collectionBooks = null;
          _collectionId = null;
          _collectionName = null;
        }
      });
      await _loadModeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // Handle
        Center(child: Container(
          margin: const EdgeInsets.only(top: 8),
          width: 32, height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(children: [
            Expanded(child: Text(l.absorbingManageQueue,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            TextButton(
              onPressed: () {
                widget.lib.reorderAbsorbing(_order);
                Navigator.pop(context);
              },
              child: Text(l.absorbingDone),
            ),
          ]),
        ),
        // Queue mode toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'off', icon: const Icon(Icons.stop_rounded, size: 16), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeOff, maxLines: 1))),
              ButtonSegment(value: 'manual', icon: const Icon(Icons.queue_music_rounded, size: 16), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeManual, maxLines: 1))),
              ButtonSegment(value: 'auto_next', icon: const Icon(Icons.skip_next_rounded, size: 16),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.isMerged ? l.queueModeAuto : _currentIsPodcast ? l.queueModeShowLabel : l.queueModeSeriesLabel, maxLines: 1))),
              ButtonSegment(value: 'playlist', icon: const Icon(Icons.playlist_play_rounded, size: 16), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModePlaylist, maxLines: 1))),
              // Collection mode is entered via a collection's Play button, not
              // picked here - shown only while active so the selection is valid.
              if (_queueMode == 'collection')
                ButtonSegment(value: 'collection', icon: const Icon(Icons.collections_bookmark_rounded, size: 16), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeCollection, maxLines: 1))),
            ],
            selected: {_queueMode},
            onSelectionChanged: (v) {
              if (v.isNotEmpty) widget.onQueueModeChanged(v.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        if (_queueMode != 'off')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.autoDownloadQueue,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    Text(
                      _queueAutoDownload
                          ? l.autoDownloadQueueOnSubtitle(_rollingDownloadCount)
                          : l.autoDownloadQueueOffSubtitle,
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant, fontSize: 11.5),
                    ),
                  ],
                )),
                if (_queueAutoDownload)
                  Tooltip(
                    message: l.keepNext,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _rollingDownloadCount,
                        isDense: true,
                        items: const [2, 3, 4, 5]
                            .map((count) => DropdownMenuItem(
                                  value: count,
                                  child: Text('$count'),
                                ))
                            .toList(),
                        onChanged: _queueDownloadSettingsLoaded
                            ? (value) async {
                                if (value == null) return;
                                setState(() => _rollingDownloadCount = value);
                                await PlayerSettings.setRollingDownloadCount(value);
                                unawaited(widget.lib.syncQueueAutoDownloads());
                              }
                            : null,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Switch(
                  value: _queueAutoDownload,
                  onChanged: _queueDownloadSettingsLoaded
                      ? _setQueueAutoDownload
                      : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ]),
            ]),
          ),
        if (_queueMode != 'off')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(children: [
              Expanded(child: Text(l.showUpNextLabel,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
              Switch(
                value: _showUpNext,
                onChanged: (v) {
                  setState(() => _showUpNext = v);
                  PlayerSettings.setShowUpNextLabel(v);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
          ),
        if (_queueMode == 'auto_next' && _currentPodcastShowId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.reversePlayOrder,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                Text(
                  _podcastAdvanceDir == 'newest_first'
                      ? l.episodeListPlaysNewerToOlder
                      : l.episodeListPlaysOlderToNewer,
                  style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant, fontSize: 11.5),
                ),
              ])),
              Switch(
                value: _podcastAdvanceDir == 'newest_first',
                onChanged: (v) async {
                  final dir = v ? 'newest_first' : 'oldest_first';
                  setState(() => _podcastAdvanceDir = dir);
                  await PlayerSettings.setPodcastAdvanceDir(
                      _currentPodcastShowId!, dir);
                  unawaited(widget.lib.syncQueueAutoDownloads());
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
          ),
        if (_queueMode == 'auto_next' && !_currentIsPodcast && _seriesId != null)
          _modeHeaderButton(
            cs, tt,
            label: l.openSeries,
            subtitle: _seriesName,
            icon: Icons.collections_bookmark_rounded,
            onTap: () {
              final auth = context.read<AuthProvider>();
              final outer = rootNavigatorKey.currentContext ?? context;
              Navigator.pop(context);
              showSeriesBooksSheet(
                outer,
                seriesName: _seriesName ?? '',
                seriesId: _seriesId,
                books: const [],
                serverUrl: auth.serverUrl,
                token: auth.token,
                libraryId: widget.lib.selectedLibraryId,
              );
            },
          ),
        if (_queueMode == 'auto_next' && _currentPodcastShowId != null && _showItem != null)
          _modeHeaderButton(
            cs, tt,
            label: l.allEpisodes,
            subtitle: _showName,
            icon: Icons.podcasts_rounded,
            onTap: () {
              final outer = rootNavigatorKey.currentContext ?? context;
              Navigator.pop(context);
              EpisodeListSheet.show(outer, _showItem!);
            },
          ),
        if (_queueMode == 'playlist' && _playlistId != null)
          _modeHeaderButton(
            cs, tt,
            label: l.openPlaylist,
            subtitle: _playlistName,
            icon: Icons.playlist_play_rounded,
            onTap: () {
              final outer = rootNavigatorKey.currentContext ?? context;
              Navigator.pop(context);
              PlaylistDetailSheet.show(outer, _playlistId!);
            },
          ),
        if (_queueMode == 'collection' && _collectionId != null)
          _modeHeaderButton(
            cs, tt,
            label: l.openCollection,
            subtitle: _collectionName,
            icon: Icons.collections_bookmark_rounded,
            onTap: () {
              final outer = rootNavigatorKey.currentContext ?? context;
              Navigator.pop(context);
              CollectionDetailSheet.show(outer, _collectionId!);
            },
          ),
        Expanded(
          child: _buildQueueList(cs, tt, l, bottomInset),
        ),
      ]),
    );
  }

  Widget _modeHeaderButton(
    ColorScheme cs,
    TextTheme tt, {
    required String label,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }

  Widget _buildQueueList(ColorScheme cs, TextTheme tt, AppLocalizations l, double bottomInset) {
    if (_queueMode == 'auto_next') {
      if (_currentPodcastShowId != null) {
        return _buildShowEpisodesList(cs, tt, l, bottomInset);
      }
      // A book library with nothing playing has no series context to load, so
      // fall through to the manual queue rather than spinning forever.
      if (!_currentIsPodcast && _currentItemId != null) {
        return _buildSeriesList(cs, tt, l, bottomInset);
      }
      return _buildManualList(cs, tt, l, bottomInset);
    }
    if (_queueMode == 'playlist') {
      return _buildPlaylistList(cs, tt, l, bottomInset);
    }
    if (_queueMode == 'collection') {
      return _buildCollectionList(cs, tt, l, bottomInset);
    }
    return _buildManualList(cs, tt, l, bottomInset);
  }

  Widget _buildCollectionList(ColorScheme cs, TextTheme tt, AppLocalizations l, double bottomInset) {
    final books = _collectionBooks;
    if (books == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.absorbingNothingAbsorbingYet,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }
    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.only(bottom: bottomInset + 16),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        final id = book['id'] as String? ?? '';
        return _readOnlyQueueItem(cs, tt, l, key: id, book: book, index: i);
      },
    );
  }

  Widget _buildShowEpisodesList(ColorScheme cs, TextTheme tt, AppLocalizations l, double bottomInset) {
    final eps = _showEpisodes;
    if (eps == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (eps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.absorbingNothingAbsorbingYet,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }
    final showId = _currentPodcastShowId;
    final newestFirst = _podcastAdvanceDir == 'newest_first';
    final sorted = [...eps]..sort((a, b) {
        final at = (a['publishedAt'] as num?)?.toInt() ?? 0;
        final bt = (b['publishedAt'] as num?)?.toInt() ?? 0;
        return newestFirst ? bt.compareTo(at) : at.compareTo(bt);
      });
    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.only(bottom: bottomInset + 16),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final ep = sorted[i];
        final epId = ep['id'] as String? ?? '';
        return _readOnlyQueueItem(
          cs, tt, l,
          key: '$showId-$epId',
          book: _showItem ?? const {},
          index: i,
          episodeOverride: ep,
        );
      },
    );
  }

  Widget _buildSeriesList(ColorScheme cs, TextTheme tt, AppLocalizations l, double bottomInset) {
    final books = _seriesBooks;
    if (books == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.absorbingNothingAbsorbingYet,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }
    // Sort by series sequence (numeric leading).
    books.sort((a, b) {
      double seqOf(Map<String, dynamic> book) {
        final (_, seq) = widget.lib.extractSeries(book);
        return seq ?? double.maxFinite;
      }
      return seqOf(a).compareTo(seqOf(b));
    });
    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.only(bottom: bottomInset + 16),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        final id = book['id'] as String? ?? '';
        return _readOnlyQueueItem(cs, tt, l, key: id, book: book, index: i);
      },
    );
  }

  Widget _buildPlaylistList(ColorScheme cs, TextTheme tt, AppLocalizations l, double bottomInset) {
    final items = _playlistItems;
    if (items == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.playlistAllFinished,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }
    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.only(bottom: bottomInset + 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final libraryItemId = item['libraryItemId'] as String? ?? '';
        final episodeId = item['episodeId'] as String?;
        final key = episodeId != null ? '$libraryItemId-$episodeId' : libraryItemId;
        final book = item['libraryItem'] as Map<String, dynamic>? ?? const {};
        return _readOnlyQueueItem(
          cs, tt, l,
          key: key,
          book: book,
          index: i,
          episodeOverride: item['episode'] as Map<String, dynamic>?,
        );
      },
    );
  }

  Widget _downloadStatus(String key, ColorScheme cs) {
    if (_downloads.isDownloaded(key)) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(Icons.download_done_rounded, size: 18, color: cs.primary),
      );
    }
    if (_downloads.isDownloading(key)) {
      final progress = _downloads.downloadProgress(key);
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 2,
            color: cs.primary,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _readOnlyQueueItem(
    ColorScheme cs,
    TextTheme tt,
    AppLocalizations l, {
    required String key,
    required Map<String, dynamic> book,
    required int index,
    Map<String, dynamic>? episodeOverride,
  }) {
    final media = book['media'] as Map<String, dynamic>? ?? const {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
    final title = metadata['title'] as String? ?? l.unknown;
    final author = metadata['authorName'] as String? ?? '';
    final epTitle = episodeOverride?['title'] as String?;
    final isFinished = widget.lib.isItemFinishedByKey(key);
    final isPlaying = _currentItemId == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Tapping a series book or playlist item plays it. For playlist
          // items the user expects this to be the same as opening the item
          // from the playlist sheet; closing the manage queue sheet first.
          Navigator.pop(context);
          final api = context.read<AuthProvider>().apiService;
          if (api == null) return;
          late Future<String?> playback;
          if (key.length > 36) {
            // podcast compound key
            final showId = key.substring(0, 36);
            final epId = key.substring(37);
            playback = AudioPlayerService().playItem(
              api: api,
              itemId: showId,
              title: epTitle ?? title,
              author: title,
              coverUrl: widget.lib.getCoverUrl(showId),
              totalDuration: (episodeOverride?['duration'] as num?)?.toDouble() ?? 0,
              chapters: const [],
              episodeId: epId,
              episodeTitle: epTitle,
              libraryId: book['libraryId'] as String? ?? widget.lib.selectedLibraryId,
            );
          } else {
            playback = AudioPlayerService().playItem(
              api: api,
              itemId: key,
              title: title,
              author: author,
              coverUrl: widget.lib.getCoverUrl(key),
              totalDuration: (media['duration'] as num?)?.toDouble() ?? 0,
              chapters: media['chapters'] as List<dynamic>? ?? const [],
              libraryId: book['libraryId'] as String? ?? widget.lib.selectedLibraryId,
            );
          }
          unawaited(playback.then((error) async {
            if (error == null) {
              await widget.lib.syncQueueAutoDownloads();
            }
          }));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isPlaying
                ? cs.primaryContainer.withValues(alpha: 0.25)
                : (isFinished ? cs.onSurface.withValues(alpha: 0.03) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            SizedBox(
              width: 24,
              child: Text('${index + 1}',
                  style: tt.labelMedium?.copyWith(
                    color: isFinished ? cs.onSurface.withValues(alpha: 0.3) : cs.primary,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            if (isFinished)
              Icon(Icons.check_circle_rounded,
                  size: 16, color: Colors.green.withValues(alpha: 0.5))
            else
              () {
                final progress = widget.lib.getProgress(key);
                return progress > 0
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.5,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: cs.primary,
                        ),
                      )
                    : Icon(Icons.circle_outlined,
                        size: 16, color: cs.onSurface.withValues(alpha: 0.2));
              }(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(epTitle ?? title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        color: isFinished
                            ? cs.onSurface.withValues(alpha: 0.4)
                            : null,
                      )),
                  if (epTitle != null)
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
                  else if (author.isNotEmpty)
                    Text(author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            _downloadStatus(key, cs),
          ]),
        ),
      ),
    );
  }

  Widget _buildManualList(ColorScheme cs, TextTheme tt, AppLocalizations l, double bottomInset) {
    return ReorderableListView.builder(
            scrollController: widget.scrollController,
            buildDefaultDragHandles: false,
            onReorderStart: (_) => HapticFeedback.mediumImpact(),
            padding: EdgeInsets.only(bottom: bottomInset + 16),
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surfaceContainer,
                  child: child,
                ),
                child: child,
              );
            },
            itemCount: _order.length,
            onReorder: (oldIdx, newIdx) {
              setState(() {
                if (newIdx > oldIdx) newIdx--;
                final item = _order.removeAt(oldIdx);
                _order.insert(newIdx, item);
              });
            },
            itemBuilder: (context, i) {
              final key = _order[i];
              final book = _booksByKey[key];
              if (book == null) return SizedBox.shrink(key: ValueKey(key));

              final media = book['media'] as Map<String, dynamic>? ?? {};
              final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
              final title = metadata['title'] as String? ?? l.unknown;
              final author = metadata['authorName'] as String? ?? '';
              final re = book['recentEpisode'] as Map<String, dynamic>?;
              final epTitle = re?['title'] as String?;
              final isFinished = widget.lib.isItemFinishedByKey(key);

              return Dismissible(
                key: ValueKey(key),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.remove_circle_outline_rounded, color: cs.error),
                ),
                onDismissed: (_) {
                  final removedKey = _order[i];
                  setState(() => _order.removeAt(i));
                  widget.lib.removeFromAbsorbing(removedKey);
                  widget.lib.reorderAbsorbing(_order);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFinished ? cs.onSurface.withValues(alpha: 0.03) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      // Queue position number
                      SizedBox(width: 24, child: Text('${i + 1}',
                        style: tt.labelMedium?.copyWith(
                          color: isFinished ? cs.onSurface.withValues(alpha: 0.3) : cs.primary,
                          fontWeight: FontWeight.w700,
                        ))),
                      // Progress indicator
                      if (isFinished)
                        Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.withValues(alpha: 0.5))
                      else ...[
                        () {
                          final progress = widget.lib.getProgress(key);
                          return progress > 0
                              ? SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 2.5,
                                    backgroundColor: cs.surfaceContainerHighest,
                                    color: cs.primary,
                                  ))
                              : Icon(Icons.circle_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.2));
                        }(),
                      ],
                      const SizedBox(width: 8),
                      // Title + subtitle
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(epTitle ?? title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              color: isFinished ? cs.onSurface.withValues(alpha: 0.4) : null,
                            )),
                          if (epTitle != null)
                            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          if (author.isNotEmpty && epTitle == null)
                            Text(author, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      )),
                      _downloadStatus(key, cs),
                      // Drag handle (long-press to avoid conflict with system home gesture)
                      _DragHandle(index: i, color: cs.onSurface),
                    ]),
                  ),
                ),
              );
            },
          );
  }
}

// ─── DRAG HANDLE WITH HOLD FEEDBACK ─────────────────────────

class _DragHandle extends StatefulWidget {
  final int index;
  final Color color;
  const _DragHandle({required this.index, required this.color});

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // Match ReorderableDelayedDragStartListener's default delay
  static const _holdDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _holdDuration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent _) {
    _controller.forward(from: 0);
  }

  void _onUp(PointerEvent _) {
    _controller.stop();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: ReorderableDelayedDragStartListener(
        index: widget.index,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final ready = _controller.isCompleted;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ready ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.drag_handle_rounded, size: 20,
                color: widget.color.withValues(alpha: ready ? 0.7 : 0.3)),
            );
          },
        ),
      ),
    );
  }
}
