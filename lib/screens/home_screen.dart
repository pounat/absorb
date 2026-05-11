import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import '../widgets/absorbing_shared.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../widgets/home_section.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/shimmer.dart';
import '../widgets/book_detail_sheet.dart';
import '../widgets/card_buttons.dart';
import '../widgets/episode_list_sheet.dart';
import '../main.dart' show oledNotifier;
import '../widgets/home_customize_sheet.dart';
import '../widgets/playlist_detail_sheet.dart';
import '../widgets/collection_detail_sheet.dart';
import '../widgets/section_detail_sheet.dart';
import '../widgets/feature_hint.dart';
import '../widgets/offline_status_icon.dart';
import '../widgets/section_labels.dart';
import 'app_shell.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _player = AudioPlayerService();
  bool _hideEbookOnly = false;
  bool _rectangleCovers = false;

  // ── Scroll-to-hide bars ──
  final ValueNotifier<bool> barsVisibleNotifier = ValueNotifier(true);
  final _scrollController = ScrollController();
  double _lastScrollOffset = 0;
  double _scrollAccumulator = 0;
  static const _scrollThreshold = 40.0;

  // Cached filtered sections — invalidated when source data or settings change.
  List<Map<String, dynamic>>? _cachedSections;
  List<dynamic>? _cachedClItems;
  List<dynamic>? _lastSectionsRef;
  List<dynamic>? _lastPlaylistsRef;
  List<dynamic>? _lastCollectionsRef;
  List<String>? _lastSectionOrder;
  Set<String>? _lastHiddenIds;
  bool _lastHideEbook = false;
  bool _lastIsPodcast = false;

  // Track player state to know when to re-fetch personalized sections.
  String? _lastKnownItemId;
  bool _lastKnownPlaying = false;

  void _onScrollDirection() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    if (offset <= 0) {
      _scrollAccumulator = 0;
      _showBars();
      return;
    }
    if (delta.abs() < 0.5) return;

    if ((delta > 0) != (_scrollAccumulator > 0)) _scrollAccumulator = 0;
    _scrollAccumulator += delta;

    if (_scrollAccumulator > _scrollThreshold) {
      _hideBars();
    } else if (_scrollAccumulator < -_scrollThreshold) {
      _showBars();
    }
  }

  void _showBars() {
    if (!barsVisibleNotifier.value) {
      barsVisibleNotifier.value = true;
    }
  }

  void _hideBars() {
    if (barsVisibleNotifier.value) {
      barsVisibleNotifier.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollDirection);
    _player.addListener(_onPlayerChanged);
    PlayerSettings.settingsChanged.addListener(_loadSettings);
    _loadSettings();
    Future.microtask(() {
      final lib = context.read<LibraryProvider>();
      if (lib.libraries.isEmpty) lib.loadLibraries();
      lib.refreshLocalProgress();
    });
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      PlayerSettings.getHideEbookOnly(),
      PlayerSettings.getRectangleCovers(),
    ]);
    if (mounted) setState(() {
      _hideEbookOnly = results[0];
      _rectangleCovers = results[1];
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh setting when returning to screen, but only if changed
    PlayerSettings.getHideEbookOnly().then((v) {
      if (mounted && v != _hideEbookOnly) setState(() => _hideEbookOnly = v);
    });
  }

  List<dynamic> _filterEbookOnly(List<dynamic> items, {String? sectionType}) {
    if (!_hideEbookOnly) return items;
    // Only book shelves can contain ebook-only entries. Series/author/
    // episode/playlist/collection shelves hold aggregate objects that have
    // no audio metadata and would all be incorrectly filtered out.
    if (sectionType != null && sectionType != 'book') return items;
    return items.where((e) {
      if (e is! Map<String, dynamic>) return true;
      // Personalized view entities may nest the item under 'libraryItem'
      final item = e.containsKey('libraryItem')
          ? e['libraryItem'] as Map<String, dynamic>? ?? e
          : e;
      return !PlayerSettings.isEbookOnly(item);
    }).toList();
  }

  /// Recompute cached filtered sections only when input data changes.
  void _refreshFilteredCache(LibraryProvider lib) {
    final sections = lib.personalizedSections;
    final playlists = lib.playlists;
    final collections = lib.collections;
    final isPod = lib.isPodcastLibrary;
    final sectionOrder = lib.sectionOrder;
    final hiddenIds = lib.hiddenSectionIds;
    if (identical(sections, _lastSectionsRef) &&
        identical(playlists, _lastPlaylistsRef) &&
        identical(collections, _lastCollectionsRef) &&
        identical(sectionOrder, _lastSectionOrder) &&
        identical(hiddenIds, _lastHiddenIds) &&
        _hideEbookOnly == _lastHideEbook &&
        isPod == _lastIsPodcast &&
        _cachedSections != null) {
      return; // cache is still valid
    }
    _lastSectionsRef = sections;
    _lastPlaylistsRef = playlists;
    _lastCollectionsRef = collections;
    _lastSectionOrder = sectionOrder;
    _lastHiddenIds = hiddenIds;
    _lastHideEbook = _hideEbookOnly;
    _lastIsPodcast = isPod;

    // Continue-listening items
    List<dynamic> clItems = [];
    for (final section in sections) {
      if (section['id'] == 'continue-listening') {
        clItems = _filterEbookOnly(
            (section['entities'] as List<dynamic>?) ?? [],
            sectionType: section['type'] as String?);
        break;
      }
    }
    if (isPod && clItems.isNotEmpty) {
      final seen = <String>{};
      clItems = clItems.where((item) {
        final id = (item as Map<String, dynamic>)['id'] as String? ?? '';
        return seen.add(id);
      }).toList();
    }
    _cachedClItems = clItems;
    _cachedSections = lib.getOrderedHomeSections();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    barsVisibleNotifier.dispose();
    _player.removeListener(_onPlayerChanged);
    PlayerSettings.settingsChanged.removeListener(_loadSettings);
    super.dispose();
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    final lib = context.read<LibraryProvider>();
    lib.refreshLocalProgress();

    // Refresh only progress-driven shelves when the playing item changes or
    // playback stops. Keep Discover stable unless there is a full refresh.
    final currentId = _player.currentItemId;
    final playing = _player.isPlaying;
    final itemChanged = currentId != _lastKnownItemId;
    final stopped = _lastKnownPlaying && !playing;
    _lastKnownItemId = currentId;
    _lastKnownPlaying = playing;
    if (itemChanged || stopped) {
      lib.refreshProgressShelves(
        force: stopped,
        reason: stopped ? 'player-stopped' : 'player-item-changed',
      );
    }

    if (itemChanged || stopped) {
      setState(() {});
    }
  }

  void _showLibraryPicker(BuildContext context, ColorScheme cs, TextTheme tt,
      List<dynamic> allLibraries, LibraryProvider lib) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
        return Container(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(l.selectLibrary,
                    style:
                        tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: bottomPad + 16),
                  itemCount: allLibraries.length,
                  itemBuilder: (_, i) {
                    final library = allLibraries[i] as Map<String, dynamic>;
                    final id = library['id'] as String;
                    final name = library['name'] as String? ?? l.libraryFallback;
                    final mediaType = library['mediaType'] as String? ?? 'book';
                    final isSelected = id == lib.selectedLibraryId;
                    return ListTile(
                      leading: Icon(
                          mediaType == 'podcast'
                              ? Icons.podcasts_rounded
                              : Icons.auto_stories_rounded,
                          color: isSelected ? cs.primary : cs.onSurfaceVariant),
                      title: Text(name),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: cs.primary)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!isSelected) lib.selectLibrary(id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _sectionIcons = {
    'continue-listening': Icons.play_circle_outline_rounded,
    'continue-series': Icons.auto_stories_rounded,
    'recently-added': Icons.new_releases_outlined,
    'listen-again': Icons.replay_rounded,
    'discover': Icons.explore_outlined,
    'episodes-recently-added': Icons.podcasts_rounded,
    'downloaded-books': Icons.download_done_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final lowerFade = Color.lerp(cs.surface, scaffoldBg, 0.55) ?? scaffoldBg;
    final lib = context.watch<LibraryProvider>();
    final allLibraries = lib.libraries;
    final libraryName = lib.selectedLibrary?['name'] as String? ?? l.libraryFallback;
    if (lib.isLoading) {
      // Reset cache so stale data isn't shown after a user switch
      // (where the new user may have the same number of sections).
      _cachedSections = null;
      _cachedClItems = null;
      _lastSectionsRef = null;
    } else {
      _refreshFilteredCache(lib);
    }

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
          child: RefreshIndicator(
            onRefresh: () async {
              await lib.refresh();
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Top bar: ABSORB title + page name ──
                SliverToBoxAdapter(
                  child: AbsorbPageHeader(
                    title: l.homeTitle,
                    trailing: OfflineStatusIcon(
                      onTapWhenOnline: () {
                        lib.setManualOffline(true);
                        final dl = DownloadService();
                        final player = AudioPlayerService();
                        final itemId = player.currentItemId;
                        final epId = player.currentEpisodeId;
                        final dlKey = epId != null && itemId != null
                            ? '$itemId-$epId'
                            : itemId;
                        if (dlKey == null || !dl.isDownloaded(dlKey)) {
                          player.stop();
                        }
                      },
                    ),
                    actions: [
                      if (allLibraries.length > 1)
                        Material(
                          color: cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _showLibraryPicker(
                                context, cs, tt, allLibraries, lib),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.08)),
                              ),
                              child: SizedBox(
                                height: 20,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        lib.isPodcastLibrary
                                            ? Icons.podcasts_rounded
                                            : Icons.auto_stories_rounded,
                                        size: 18,
                                        color: cs.onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 140),
                                      child: Text(libraryName,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurfaceVariant),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.unfold_more_rounded,
                                        size: 18, color: cs.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!lib.isOffline)
                        GestureDetector(
                          onTap: () => HomeCustomizeSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                            ),
                            child: SizedBox(height: 20, child: Icon(Icons.tune_rounded, size: 18, color: cs.onSurfaceVariant)),
                          ),
                        ),
                    ],
                  ),
                ),

                // (Continue Listening is now rendered in the generic sections loop below)

                // ── Loading shimmer ──
                if (lib.isLoading) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(child: ShimmerHeroCard()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  const SliverToBoxAdapter(child: ShimmerBookRow()),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  const SliverToBoxAdapter(child: ShimmerBookRow()),
                ],

                // ── Error ──
                if (!lib.isLoading &&
                    lib.errorMessage != null &&
                    lib.personalizedSections.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 48, color: cs.error),
                          const SizedBox(height: 12),
                          Text(lib.errorMessage!,
                              style: tt.bodyLarge?.copyWith(color: cs.error)),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                              onPressed: lib.refresh,
                              child: Text(l.retry)),
                        ],
                      ),
                    ),
                  ),

                // ── Empty ──
                if (!lib.isLoading &&
                    lib.errorMessage == null &&
                    lib.personalizedSections.isEmpty &&
                    (lib.libraries.isNotEmpty || lib.isOffline))
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            lib.isOffline
                                ? Icons.download_for_offline_outlined
                                : Icons.library_music_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            lib.isOffline
                                ? l.noDownloadedBooks
                                : l.yourLibraryIsEmpty,
                            style: tt.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (lib.isOffline) ...[
                            const SizedBox(height: 4),
                            Text(
                              l.downloadBooksWhileOnline,
                              style: tt.bodySmall?.copyWith(
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // ── All sections (including Continue Listening) ──
                if (!lib.isLoading)
                  ...(_cachedSections ?? []).expand((section) {
                    final id = section['id'] as String? ?? '';
                    final isPlaylist = id.startsWith('playlist:');
                    final isCollection = id.startsWith('collection:');

                    // Playlists/collections are server-only; hide when offline
                    if ((isPlaylist || isCollection) && lib.isOffline) return <Widget>[];

                    // Continue Listening gets its own compact card layout
                    if (id == 'continue-listening') {
                      final clItems = _cachedClItems ?? [];
                      if (clItems.isEmpty) return <Widget>[];
                      return <Widget>[
                        SliverToBoxAdapter(
                          child: GestureDetector(
                            onTap: () => SectionDetailSheet.show(
                              context,
                              title: l.continueListening,
                              icon: Icons.play_circle_outline_rounded,
                              entities: clItems,
                              coverAspectRatio: _rectangleCovers ? 2 / 3 : 1.0,
                            ),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                              child: Row(children: [
                                Icon(Icons.play_circle_outline_rounded,
                                    size: 16, color: cs.primary.withValues(alpha: 0.7)),
                                const SizedBox(width: 8),
                                Text(l.continueListening,
                                    style: tt.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurface.withValues(alpha: 0.8),
                                      letterSpacing: 0.3,
                                    )),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, size: 16,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                                const SizedBox(width: 12),
                                Expanded(child: Container(height: 0.5,
                                    color: cs.outlineVariant.withValues(alpha: 0.2))),
                              ]),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: FeatureHint(
                            prefKey: 'hint_continue_listening_gestures',
                            message:
                                'Tap a card to resume. Press and hold to see details.',
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              // Taller row when 2:3 covers are on; the card's
                              // cover alone is ~225 with rectangle covers.
                              height: _rectangleCovers ? 320 : 250,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                physics: const BouncingScrollPhysics(),
                                itemCount: clItems.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 10),
                                itemBuilder: (context, i) {
                                  final item = clItems[i] as Map<String, dynamic>;
                                  return RepaintBoundary(child: _ContinueListeningCard(
                                    item: item, lib: lib, player: _player,
                                    rectangleCovers: _rectangleCovers,
                                  ));
                                },
                              ),
                            ),
                          ),
                        ),
                      ];
                    }

                    final label = sectionLabel(id, section['label'] as String?, l);
                    final entities = _filterEbookOnly(
                        (section['entities'] as List<dynamic>?) ?? [],
                        sectionType: section['type'] as String?);
                    final type = isPlaylist ? 'playlist'
                        : isCollection ? 'collection'
                        : (section['type'] ?? 'book');
                    if (entities.isEmpty) return <Widget>[];

                    VoidCallback? titleTap;
                    IconData sectionIcon;
                    if (isPlaylist) {
                      titleTap = () => PlaylistDetailSheet.show(
                          context, section['_playlistId'] as String);
                      sectionIcon = Icons.playlist_play_rounded;
                    } else if (isCollection) {
                      titleTap = () => CollectionDetailSheet.show(
                          context, section['_collectionId'] as String);
                      sectionIcon = Icons.collections_bookmark_rounded;
                    } else if (id.startsWith('genre:')) {
                      sectionIcon = Icons.label_outline_rounded;
                      final sectionLabel = label as String;
                      titleTap = () => SectionDetailSheet.show(
                        context,
                        title: sectionLabel,
                        icon: sectionIcon,
                        entities: entities,
                        coverAspectRatio: _rectangleCovers ? 2 / 3 : 1.0,
                      );
                    } else {
                      sectionIcon = _sectionIcons[id] ?? Icons.album_outlined;
                      // Author/series sections don't have book-shaped entities,
                      // so skip the book-oriented SectionDetailSheet for them.
                      if (type != 'authors' && type != 'series') {
                        final sectionLabel = label as String;
                        titleTap = () => SectionDetailSheet.show(
                          context,
                          title: sectionLabel,
                          icon: sectionIcon,
                          entities: entities,
                          coverAspectRatio: _rectangleCovers ? 2 / 3 : 1.0,
                        );
                      }
                    }

                    return <Widget>[
                      SliverToBoxAdapter(
                        child: HomeSection(
                          title: label,
                          icon: sectionIcon,
                          entities: entities,
                          sectionType: type,
                          sectionId: id,
                          onTitleTap: titleTap,
                          coverAspectRatio: _rectangleCovers ? 2 / 3 : 1.0,
                        ),
                      ),
                    ];
                  }),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Process-wide cache of cover-derived accent colors. Same cover URL never
// runs PaletteGenerator twice in a session - extraction is image-decode +
// k-means clustering, far too expensive to repeat as tiles scroll past.
final Map<String, Color> _accentCache = {};

// ══════════════════════════════════════════════════════════════
// Continue Listening Card — compact card with play button
// ══════════════════════════════════════════════════════════════

class _ContinueListeningCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final LibraryProvider lib;
  final AudioPlayerService player;
  final bool rectangleCovers;

  const _ContinueListeningCard({
    required this.item,
    required this.lib,
    required this.player,
    required this.rectangleCovers,
  });

  @override
  State<_ContinueListeningCard> createState() => _ContinueListeningCardState();
}

class _ContinueListeningCardState extends State<_ContinueListeningCard> {
  bool _isLoading = false;
  Color? _accent;
  String? _derivedCoverKey;

  static String _fmtRemaining(double s) {
    if (s <= 0) return '';
    final h = (s / 3600).floor();
    final m = ((s % 3600) / 60).floor();
    if (h > 0) return '${h}h ${m}m left';
    if (m > 0) return '${m}m left';
    return '<1m left';
  }

  Widget _buildCoverImage(String? coverUrl, ColorScheme cs, Map<String, String> headers) {
    final fallback = Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.headphones_rounded, size: 32, color: cs.onSurfaceVariant),
    );
    if (coverUrl == null) return fallback;

    final isLocal = coverUrl.startsWith('/');
    Widget image({required BoxFit fit}) {
      if (isLocal) {
        return Image.file(File(coverUrl), fit: fit,
            errorBuilder: (_, __, ___) => fallback);
      }
      return CachedNetworkImage(
        imageUrl: coverUrl,
        fit: fit,
        httpHeaders: headers,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }

    // Rectangle mode: tile aspect (2:3) matches most book covers, so fill it.
    if (widget.rectangleCovers) return image(fit: BoxFit.cover);

    // Square mode: tile is 1:1. Most audiobook covers are square and fill it,
    // but rectangular covers would letterbox - fill the gaps with a blurred
    // copy of the cover (matches the absorbing card aesthetic). Both image()
    // calls share the same cached bytes by URL.
    return BlurPaddedCover(
      child: image(fit: BoxFit.contain),
      blurChild: image(fit: BoxFit.cover),
    );
  }

  /// Pull a vivid accent color from the cover. Uses PaletteGenerator instead
  /// of ColorScheme.fromImageProvider because Material 3's harmonized palette
  /// flattens vibrant covers into muted tones (a yellow/black cover ends up
  /// looking olive-green). The vibrant/dominant swatch keeps the original
  /// hue intact. Results are memoized in `_accentCache` so the same cover
  /// never runs the extraction twice in a session.
  void _deriveScheme(String? coverUrl) {
    final key = coverUrl;
    if (key == _derivedCoverKey) return;
    _derivedCoverKey = key;
    if (coverUrl == null) {
      if (_accent != null) setState(() => _accent = null);
      return;
    }
    final cached = _accentCache[coverUrl];
    if (cached != null) {
      _accent = cached;
      return;
    }
    final ImageProvider provider;
    if (coverUrl.startsWith('/')) {
      provider = FileImage(File(coverUrl));
    } else {
      provider = CachedNetworkImageProvider(coverUrl, headers: widget.lib.mediaHeaders);
    }
    PaletteGenerator.fromImageProvider(provider, maximumColorCount: 16)
        .then((palette) {
          final picked = palette.vibrantColor?.color
              ?? palette.lightVibrantColor?.color
              ?? palette.darkVibrantColor?.color
              ?? palette.dominantColor?.color
              ?? palette.colors.firstOrNull;
          if (picked == null) return;
          _accentCache[coverUrl] = picked;
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _accent = picked);
          });
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final item = widget.item;
    final lib = widget.lib;
    final player = widget.player;

    final itemId = item['id'] as String? ?? '';
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final recentEpisode = item['recentEpisode'] as Map<String, dynamic>?;

    final title = recentEpisode != null
        ? (recentEpisode['title'] as String? ?? l.homeScreenEpisodeFallback)
        : (metadata['title'] as String? ?? l.unknown);
    final author = recentEpisode != null
        ? (metadata['title'] as String? ?? '')
        : (metadata['authorName'] as String? ?? '');

    final coverUrl = lib.getCoverUrl(itemId);
    _deriveScheme(coverUrl);

    final episodeId = recentEpisode?['id'] as String?;
    final progress = episodeId != null
        ? lib.getEpisodeProgress(itemId, episodeId)
        : lib.getProgress(itemId);
    final progressData = episodeId != null
        ? lib.getEpisodeProgressData(itemId, episodeId)
        : lib.getProgressData(itemId);
    final isCurrentItem = player.currentItemId == itemId;
    final serverCurrentTime = (progressData?['currentTime'] as num?)?.toDouble() ?? 0;

    double currentTime;
    double totalDuration;
    if (isCurrentItem && player.hasBook) {
      currentTime = player.position.inMilliseconds / 1000.0;
      totalDuration = player.totalDuration;
    } else {
      currentTime = (progressData?['currentTime'] as num?)?.toDouble() ?? 0;
      totalDuration = (progressData?['duration'] as num?)?.toDouble() ??
          (recentEpisode != null
              ? (recentEpisode['duration'] as num?)?.toDouble() ?? 0
              : (media['duration'] as num?)?.toDouble() ?? 0);
    }

    final accent = _accent ?? cs.primary;
    // Force the cover's hue/sat into a theme-appropriate lightness so each
    // card reads as its own tint rather than near-identical dark gray. Two
    // shades are used as gradient stops to add depth.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final HSLColor? bgHsl = _accent == null
        ? null
        : HSLColor.fromColor(accent).withSaturation(
            (HSLColor.fromColor(accent).saturation * (isDark ? 0.85 : 0.55))
                .clamp(0.0, 1.0));
    final Color cardBgTop = bgHsl != null
        ? bgHsl.withLightness(isDark ? 0.19 : 0.95).toColor()
        : (isCurrentItem ? cs.primary.withValues(alpha: 0.08) : cs.surfaceContainerHigh);
    final Color cardBgBottom = bgHsl != null
        ? bgHsl.withLightness(isDark ? 0.11 : 0.88).toColor()
        : cardBgTop;
    final progressValue =
        (totalDuration > 0 ? currentTime / totalDuration : progress).clamp(0.0, 1.0);
    final remaining = totalDuration > 0 ? totalDuration - currentTime : 0.0;

    void resume() {
      if (_isLoading) return;
      if (isCurrentItem) {
        if (player.isPlaying) {
          player.pause();
        } else {
          final playerPosSec = player.position.inMilliseconds / 1000.0;
          if (serverCurrentTime > playerPosSec + 5.0) {
            _startBook(context, itemId);
          } else {
            player.play();
          }
        }
      } else {
        _startBook(context, itemId);
      }
    }

    void openDetails() {
      if (lib.isPodcastLibrary) {
        if (recentEpisode != null) {
          EpisodeDetailSheet.show(context, item, recentEpisode);
        } else {
          EpisodeListSheet.show(context, item);
        }
      } else {
        showBookDetailSheet(context, itemId);
      }
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardBgTop, cardBgBottom],
          ),
        ),
        child: InkWell(
          onTap: resume,
          onLongPress: openDetails,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Floating cover with a colored glow
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: -2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: widget.rectangleCovers ? 2 / 3 : 1,
                      child: Stack(children: [
                  Positioned.fill(
                    child: _buildCoverImage(coverUrl, cs, lib.mediaHeaders),
                  ),
                  if (isCurrentItem && player.isPlaying)
                    Positioned(
                      right: 6, bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.graphic_eq_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Center(
                          child: SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                      ]),
                    ),
                  ),
                ),
              ),
              // Text + progress area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reserve 2 lines of title height so the author row
                      // stays in a consistent position whether the title
                      // wraps or not.
                      SizedBox(
                        height: 30,
                        child: Text(title, maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                                height: 1.2)),
                      ),
                      if (author.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(author, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 3,
                          backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('${(progressValue * 100).round()}%',
                            style: tt.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: accent,
                                fontSize: 11)),
                        if (remaining > 0) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_fmtRemaining(remaining),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant, fontSize: 10)),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _startBook(BuildContext context, String itemId) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Check if this is a podcast with a recentEpisode
    final recentEpisode = widget.item['recentEpisode'] as Map<String, dynamic>?;

    if (recentEpisode != null) {
      // Podcast episode — play the recent episode directly
      final l = AppLocalizations.of(context)!;
      final episodeId = recentEpisode['id'] as String? ?? '';
      final episodeTitle = recentEpisode['title'] as String? ?? l.homeScreenEpisodeFallback;
      final media = widget.item['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final showTitle = metadata['title'] as String? ?? '';
      final epDuration = (recentEpisode['duration'] as num?)?.toDouble() ?? 0;
      final coverUrl = widget.lib.getCoverUrl(itemId);

      final error = await widget.player.playItem(
        api: api,
        itemId: itemId,
        title: episodeTitle,
        author: showTitle,
        coverUrl: coverUrl,
        totalDuration: epDuration,
        chapters: [],
        episodeId: episodeId,
        episodeTitle: episodeTitle,
      );
      if (mounted) {
        if (error != null) showErrorSnackBar(context, error);
        setState(() => _isLoading = false);
      }
      return;
    }

    // Fetch full item data to get chapters
    final fullItem = await api.getLibraryItem(itemId);
    if (fullItem == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final media = fullItem['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? '';
    final author = metadata['authorName'] as String? ?? '';
    final coverUrl = widget.lib.getCoverUrl(itemId);
    final duration = (media['duration'] is num)
        ? (media['duration'] as num).toDouble()
        : 0.0;
    final chapters = (media['chapters'] as List<dynamic>?) ?? [];

    // Start playback
    final error = await widget.player.playItem(
      api: api,
      itemId: itemId,
      title: title,
      author: author,
      coverUrl: coverUrl,
      totalDuration: duration,
      chapters: chapters,
    );
    if (error != null && mounted) showErrorSnackBar(context, error);

    // Ensure this book is on the absorbing list (clear any manual remove)
    if (context.mounted) {
      context.read<LibraryProvider>().addToAbsorbing(itemId);
    }

    if (mounted) setState(() => _isLoading = false);
    // Navigate to absorbing screen
    if (context.mounted) AppShell.goToAbsorbing(context);
  }
}
