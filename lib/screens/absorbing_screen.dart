import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../services/download_service.dart';
import '../services/scoped_prefs.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/absorbing_card.dart';

class AbsorbingScreen extends StatefulWidget {
  const AbsorbingScreen({super.key});

  /// Global key for accessing the absorbing screen state
  static final globalKey = GlobalKey<_AbsorbingScreenState>();

  /// Scroll to the currently playing book card
  static void scrollToActive() {
    globalKey.currentState?._scrollToActiveCard();
  }

  @override
  State<AbsorbingScreen> createState() => _AbsorbingScreenState();
}

class _AbsorbingScreenState extends State<AbsorbingScreen> {
  final _player = AudioPlayerService();
  final _pageController = PageController(viewportFraction: 0.92);

  final _cast = ChromecastService();

  @override
  void initState() {
    super.initState();
    _player.addListener(_rebuild);
    _cast.addListener(_rebuild);
    _restoreLastFinished();
  }

  Future<void> _restoreLastFinished() async {
    final saved = await ScopedPrefs.getString('absorbing_last_finished');
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _lastFinishedId = saved);
    }
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

  void _rebuild() {
    if (!mounted) return;
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
    }

    // Track cast state — when casting starts, scroll to the card;
    // when it stops/disconnects, keep that card at front.
    final nowCasting = _cast.isCasting;
    if (nowCasting && !_wasCasting) {
      // Casting just started — scroll to the cast card
      _lastCastItemId = _cast.castingItemId;
      _lastCastEpisodeId = _cast.castingEpisodeId;
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
    _wasCasting = nowCasting;

    setState(() {});
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

  /// Confirm before syncing when idle — server positions will overwrite local.
  Future<void> _confirmAndSync(LibraryProvider lib) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync with server?'),
        content: const Text(
          'This will pull fresh positions from the server. '
          'Any local progress will be replaced with whatever '
          'the server has.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sync')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSyncing = true);
    await _pullRefresh();
    if (mounted) setState(() => _isSyncing = false);
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
      // Cache fallback — only include if it matches the current library
      final cached = cache[key];
      if (cached != null) {
        final itemLibId = cached['libraryId'] as String?;
        if (selectedLibraryId == null || itemLibId == null || itemLibId == selectedLibraryId) {
          items.add(cached);
        } else {
          skippedKeys[key] = 'wrong library (item=$itemLibId, selected=$selectedLibraryId)';
        }
      } else {
        skippedKeys[key] = 'not in section or cache';
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
      // Only show if the active item matches the current library type
      if (activeIsPodcast == isPod) {
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
    if (!_player.hasBook && _lastFinishedId != null && !removes.contains(_lastFinishedId)) {
      // Compound podcast keys are "uuid-uuid" (>36 chars); plain book UUIDs are 36.
      final finishedIsPodcast = _lastFinishedId!.length > 36;
      if (finishedIsPodcast == isPod) {
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lib = context.watch<LibraryProvider>();
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
        return dl.isDownloaded(b['id'] as String? ?? '');
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            AbsorbPageHeader(
              title: 'Absorbing',
              brandingColor: muted,
              titleColor: cs.onSurface,
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              actions: [
                // Offline mode toggle
                GestureDetector(
                  onTap: () {
                    final newVal = !lib.isManualOffline;
                    lib.setManualOffline(newVal);
                    if (newVal) _stopAndRefresh(lib);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: effectiveOffline ? Colors.orange.withValues(alpha: 0.15) : subtleBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: effectiveOffline ? Colors.orange.withValues(alpha: 0.3) : subtleBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          effectiveOffline ? Icons.airplanemode_active_rounded : Icons.airplanemode_inactive_rounded,
                          size: 14, color: effectiveOffline ? Colors.orange : muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          effectiveOffline ? 'Offline' : 'Online',
                          style: TextStyle(
                            color: effectiveOffline ? Colors.orange : muted,
                            fontSize: 11, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Unified button: "Sync" when idle, "Stop & Sync" when playing
                if (!effectiveOffline)
                  GestureDetector(
                    onTap: _isSyncing ? null : () {
                      if (_player.hasBook) {
                        _stopAndRefresh(lib);
                      } else {
                        _confirmAndSync(lib);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: subtleBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: subtleBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSyncing) ...[
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: muted)),
                            const SizedBox(width: 6),
                            Text('Syncing…', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w500)),
                          ] else if (_player.hasBook) ...[
                            Icon(Icons.stop_rounded, size: 14, color: muted),
                            const SizedBox(width: 4),
                            Text('Stop & Sync', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w500)),
                          ] else ...[
                            Icon(Icons.sync_rounded, size: 14, color: muted),
                            const SizedBox(width: 4),
                            Text('Sync', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  // Offline: just stop button (no sync)
                  AnimatedOpacity(
                    opacity: _player.hasBook ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_player.hasBook,
                      child: GestureDetector(
                        onTap: () => _stopAndRefresh(lib),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: subtleBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: subtleBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stop_rounded, size: 14, color: muted),
                              const SizedBox(width: 4),
                              Text('Stop', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // ── Page Dots ──
            if (books.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _PageDots(count: books.length, controller: _pageController),
              ),
            // ── Cards (refreshable) ──
            Expanded(
              child: showBlockingLoader
                  ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.24)))
                  : books.isEmpty
                      ? _emptyState(cs, tt, effectiveOffline)
                      : PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                          itemCount: books.length,
                          itemBuilder: (_, i) => LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = constraints.maxWidth;
                              final vPad = (constraints.maxHeight * 0.04).clamp(12.0, 40.0);
                              return AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, child) {
                                  double distFromCenter = 0.0;
                                  double rawDist = 0.0;
                                  if (_pageController.position.haveDimensions) {
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
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: vPad),
                                      child: child,
                                    ),
                                  );
                                },
                                child: RepaintBoundary(child: AbsorbingCard(key: ValueKey(_absorbingKey(books[i])), item: books[i], player: _player)),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs, TextTheme tt, bool isOffline) {
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
              ? (isPod ? 'No downloaded episodes' : 'No downloaded books')
              : (isPod ? 'Nothing playing yet' : 'Nothing absorbing yet'),
            style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(isOffline
              ? (isPod ? 'Download episodes to listen offline' : 'Download books to listen offline')
              : (isPod ? 'Start an episode from the Shows tab' : 'Start a book from the Library tab'),
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24))),
        ],
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
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) {
        final page = controller.hasClients ? (controller.page ?? 0).round() : 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final active = i == page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? cs.onSurface.withValues(alpha: 0.54) : cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}
