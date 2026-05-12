import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../services/download_service.dart';
import '../services/scoped_prefs.dart';
import '../widgets/absorb_page_header.dart';
import '../main.dart' show oledNotifier;
import '../widgets/absorbing_card.dart';
import '../widgets/offline_status_icon.dart';
import '../l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _lastSeenHasBook = _player.hasBook;
    _lastSeenIsPlaying = _player.isPlaying;
    _player.addListener(_rebuild);
    _cast.addListener(_rebuild);
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

  Future<void> _loadQueueMode() async {
    final lib = context.read<LibraryProvider>();
    String mode;
    if (_mergeLibraries) {
      // When merged, use the more restrictive of the two modes
      // (matches Settings screen's _mergedQueueMode logic)
      final bm = await PlayerSettings.getBookQueueMode();
      final pm = await PlayerSettings.getPodcastQueueMode();
      const order = ['off', 'manual', 'auto_next'];
      final bi = order.indexOf(bm);
      final pi = order.indexOf(pm);
      mode = order[(bi < pi ? bi : pi).clamp(0, 2)];
    } else {
      mode = lib.isPodcastLibrary
          ? await PlayerSettings.getPodcastQueueMode()
          : await PlayerSettings.getBookQueueMode();
    }
    if (mounted && mode != _queueMode) setState(() => _queueMode = mode);
  }

  @override
  void dispose() {
    _player.removeListener(_rebuild);
    _cast.removeListener(_rebuild);
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
  String? _lastSeenLibraryId;

  void _rebuild() {
    if (!mounted) return;

    final hasBookChanged = _player.hasBook != _lastSeenHasBook;
    final isPlayingChanged = _player.isPlaying != _lastSeenIsPlaying;
    _lastSeenHasBook = _player.hasBook;
    _lastSeenIsPlaying = _player.isPlaying;
    var shouldRebuild = hasBookChanged || isPlayingChanged;

    // Detect item or episode change (same show, different episode counts as a change)
    final itemChanged = _player.currentItemId != _lastPlayingId;
    final episodeChanged = _player.currentEpisodeId != _lastPlayingEpisodeId;
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
        if (!_suppressReorder && existingIdx > 0) {
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
        if (finishedIdx > 0) {
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
        decoration: oledNotifier.value ? null : BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.22, 0.72, 1.0],
            colors: [
              cs.primary.withValues(alpha: 0.06),
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
                          _queueMode == 'auto_next'
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
            title: l.absorbingTitle,
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
              : (isPod ? l.absorbingNothingPlayingYet : l.absorbingNothingAbsorbingYet),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, __) => _ReorderAbsorbingSheet(
          keys: keys,
          books: books,
          lib: lib,
          absorbingKeyFn: _absorbingKey,
          queueMode: _queueMode,
          isMerged: _mergeLibraries,
          isPodcast: lib.isPodcastLibrary,
          onQueueModeChanged: (mode) async {
            setState(() => _queueMode = mode);
            if (_mergeLibraries) {
              // Merged view: keep both types in sync
              await PlayerSettings.setBookQueueMode(mode);
              await PlayerSettings.setPodcastQueueMode(mode);
            } else {
              final isPod = lib.isPodcastLibrary;
              if (isPod) {
                await PlayerSettings.setPodcastQueueMode(mode);
              } else {
                await PlayerSettings.setBookQueueMode(mode);
              }
            }
            PlayerSettings.notifySettingsChanged();
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
  final String Function(Map<String, dynamic>) absorbingKeyFn;
  final String queueMode;
  final bool isMerged;
  final bool isPodcast;
  final ValueChanged<String> onQueueModeChanged;

  const _ReorderAbsorbingSheet({
    required this.keys,
    required this.books,
    required this.lib,
    required this.absorbingKeyFn,
    required this.queueMode,
    required this.isMerged,
    required this.isPodcast,
    required this.onQueueModeChanged,
  });

  @override
  State<_ReorderAbsorbingSheet> createState() => _ReorderAbsorbingSheetState();
}

class _ReorderAbsorbingSheetState extends State<_ReorderAbsorbingSheet> {
  late List<String> _order;
  late Map<String, Map<String, dynamic>> _booksByKey;
  late String _queueMode;

  @override
  void initState() {
    super.initState();
    _order = List.from(widget.keys);
    _booksByKey = {
      for (final b in widget.books) widget.absorbingKeyFn(b): b,
    };
    _queueMode = widget.queueMode;
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
          margin: const EdgeInsets.only(top: 10),
          width: 32, height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'off', icon: const Icon(Icons.stop_rounded, size: 16), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeOff, maxLines: 1))),
              ButtonSegment(value: 'manual', icon: const Icon(Icons.queue_music_rounded, size: 16), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeManual, maxLines: 1))),
              ButtonSegment(value: 'auto_next', icon: const Icon(Icons.skip_next_rounded, size: 16),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.isMerged ? l.queueModeAuto : widget.isPodcast ? l.queueModeShowLabel : l.queueModeSeriesLabel, maxLines: 1))),
            ],
            selected: {_queueMode},
            onSelectionChanged: (v) {
              setState(() => _queueMode = v.first);
              widget.onQueueModeChanged(v.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
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
                      // Drag handle (long-press to avoid conflict with system home gesture)
                      _DragHandle(index: i, color: cs.onSurface),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
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
