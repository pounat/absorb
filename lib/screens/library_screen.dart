import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/library_search_results.dart';
import '../main.dart' show oledNotifier;
import '../widgets/library_sort_filter_sheet.dart';
import '../widgets/library_books_tab.dart';
import '../widgets/library_series_tab.dart';
import '../widgets/library_authors_tab.dart';
import '../widgets/library_narrators_tab.dart';
import 'admin_podcasts_screen.dart';
import 'upcoming_releases_screen.dart';
import '../widgets/audible_series_sheet.dart' show showAudibleRegionPicker;
import '../widgets/offline_status_icon.dart';
import '../l10n/app_localizations.dart';

/// Responsive grid column count based on available width.
/// Returns 3 on phones, scales up on tablets/iPads.
int responsiveGridCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return (width / 130).floor().clamp(3, 10);
}

/// Bottom padding for the library tab grids/lists so the last row clears the
/// floating tab bar (`Library/Series/Authors/Narrators`) plus the AppShell
/// `NavigationBar` once both reappear at the end of a scroll. When the bars
/// hide-on-scroll then snap back, the viewport shrinks but the scroll offset
/// stays put, so the bottom items end up closer to the pill than steady-state
/// math would suggest. This value keeps a comfortable gap even in that case.
const double libraryGridBottomPadding = 180;

// ─── Sort modes ──────────────────────────────────────────────
enum LibrarySort { recentlyAdded, alphabetical, authorName, publishedYear, duration, random, totalDuration }

// ─── Filter modes ────────────────────────────────────────────
enum LibraryFilter { none, inProgress, finished, notStarted, downloaded, inASeries, hasEbook, genre }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  // ── Search state ──
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  /// Whether the search bar has active text.
  bool get isSearchActive => _searchController.text.trim().isNotEmpty;

  /// Clear the search and return to the browse grid.
  void clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
    _focusNode.unfocus();
    _showBars();
  }

  /// Give focus to the search bar (used by the app-icon "Search" shortcut).
  void focusSearch() {
    if (!mounted) return;
    _showBars();
    FocusScope.of(context).requestFocus(_focusNode);
    // Delay the explicit keyboard-show so focus has time to attach to the
    // text field and any in-flight navigation (popping Downloads/Bookmarks,
    // fading into the Library tab) can settle. Without this delay the IME
    // connection isn't ready yet and TextInput.show is a no-op.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (!_focusNode.hasFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }
  List<dynamic> _searchBookResults = [];
  List<dynamic> _searchSeriesResults = [];
  List<dynamic> _searchAuthorResults = [];
  List<Map<String, dynamic>> _searchEpisodeResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool get _isInSearchMode => _searchController.text.trim().isNotEmpty;

  // ── Tab state ──
  TabController? _tabController;
  int _currentTab = 0;

  // ── Browse state (Library tab) ──
  bool _collapseSeries = false;
  LibrarySort _sort = LibrarySort.recentlyAdded;
  bool _sortAsc = false; // false = desc (newest/longest first), true = asc
  LibraryFilter _filter = LibraryFilter.none;
  String? _genreFilter;
  List<String> _availableGenres = [];
  bool _hideEbookOnly = false;
  final List<Map<String, dynamic>> _items = [];
  bool _isLoadingPage = false;
  bool _hasMore = true;
  int _page = 0;
  int _totalItems = 0;
  int? _randomSeed;
  int _loadGeneration = 0; // prevents stale async loads from corrupting state
  static const _pageSize = 20;

  final _scrollController = ScrollController();

  // ── Series tab state ──
  final List<Map<String, dynamic>> _seriesItems = [];
  bool _isLoadingSeriesPage = false;
  bool _hasMoreSeries = true;
  int _seriesPage = 0;
  int _totalSeries = 0;
  LibrarySort _seriesSort = LibrarySort.alphabetical;
  bool _seriesSortAsc = true;
  final _seriesScrollController = ScrollController();

  // ── Podcast-specific sort (persisted separately) ──
  LibrarySort _podcastSort = LibrarySort.recentlyAdded;
  bool _podcastSortAsc = false;

  // ── Authors tab state ──
  List<Map<String, dynamic>> _authors = [];
  bool _isLoadingAuthors = false;
  bool _authorsLoaded = false;
  LibrarySort _authorSort = LibrarySort.alphabetical;
  bool _authorSortAsc = true;
  final _authorsScrollController = ScrollController();

  // ── Narrators tab state ──
  List<String> _narrators = [];
  bool _isLoadingNarrators = false;
  bool _narratorsLoaded = false;
  LibrarySort _narratorSort = LibrarySort.alphabetical;
  bool _narratorSortAsc = true;
  final _narratorsScrollController = ScrollController();

  // ── Cover aspect ratio ──
  bool _rectangleCovers = false;
  double get _coverAspectRatio => _rectangleCovers ? 2 / 3 : 1.0;

  // ── Scroll-to-hide bars ──
  /// Notifies AppShell whether the bottom nav bar should be visible.
  final ValueNotifier<bool> barsVisibleNotifier = ValueNotifier(true);
  late final AnimationController _headerAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1.0,
  );
  double _lastScrollOffset = 0;
  double _scrollAccumulator = 0;
  static const _scrollThreshold = 40.0; // pixels of scroll before hide/show triggers

  void _onScrollDirection(ScrollController controller) {
    if (_isInSearchMode) return;
    if (!controller.hasClients) return;
    final offset = controller.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    // At the top, always show
    if (offset <= 0) {
      _scrollAccumulator = 0;
      _showBars();
      return;
    }
    if (delta.abs() < 0.5) return;

    // Accumulate scroll in current direction; reset on direction change
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
      _headerAnimController.forward();
    }
  }

  void _hideBars() {
    if (barsVisibleNotifier.value) {
      barsVisibleNotifier.value = false;
      _headerAnimController.reverse();
    }
  }

  /// Called externally (e.g. from AppShell) to focus the search field.
  void requestSearchFocus() {
    _focusNode.requestFocus();
  }

  String? _lastLibraryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _seriesScrollController.addListener(_onSeriesScroll);
    _authorsScrollController.addListener(_onAuthorsScroll);
    _narratorsScrollController.addListener(_onNarratorsScroll);
    // Load initial page once the library is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTabController();
      _tryInitialLoad();
    });
  }

  void _initTabController() {
    final lib = context.read<LibraryProvider>();
    if (!lib.isPodcastLibrary) {
      _tabController = TabController(length: 4, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    final newTab = _tabController!.index;
    if (newTab == _currentTab) return;
    setState(() => _currentTab = newTab);
    // Reset scroll tracking and show bars when switching sub-tabs
    _lastScrollOffset = 0;
    _showBars();
    PlayerSettings.setLibraryTab(newTab);
    // Lazy load data for the tab
    if (newTab == 1 && _seriesItems.isEmpty && !_isLoadingSeriesPage) {
      _loadSeriesPage();
    } else if (newTab == 2 && !_authorsLoaded && !_isLoadingAuthors) {
      _loadAuthors();
    } else if (newTab == 3 && !_narratorsLoaded && !_isLoadingNarrators) {
      _loadNarrators();
    }
  }

  void _onLibraryProviderChanged() {
    if (!mounted) return;
    final lib = context.read<LibraryProvider>();
    if (lib.selectedLibraryId != _lastLibraryId && lib.selectedLibraryId != null) {
      _lastLibraryId = lib.selectedLibraryId;
      _loadGeneration++;

      // Rebuild tab controller if library type changed
      final needsTabs = !lib.isPodcastLibrary;
      final hasTabs = _tabController != null;
      if (needsTabs != hasTabs) {
        _tabController?.removeListener(_onTabChanged);
        _tabController?.dispose();
        if (needsTabs) {
          _tabController = TabController(length: 4, vsync: this);
          _tabController!.addListener(_onTabChanged);
        } else {
          _tabController = null;
        }
        _currentTab = 0;
      }

      setState(() {
        _items.clear();
        _page = 0;
        _hasMore = true;
        _isLoadingPage = false;
        _availableGenres = [];
        // Clear series and author data
        _seriesItems.clear();
        _seriesPage = 0;
        _hasMoreSeries = true;
        _isLoadingSeriesPage = false;
        _totalSeries = 0;
        _authors.clear();
        _authorsLoaded = false;
        _isLoadingAuthors = false;
        _narrators.clear();
        _narratorsLoaded = false;
        _isLoadingNarrators = false;
      });
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      if (_seriesScrollController.hasClients) _seriesScrollController.jumpTo(0);
      if (_authorsScrollController.hasClients) _authorsScrollController.jumpTo(0);
      if (_narratorsScrollController.hasClients) _narratorsScrollController.jumpTo(0);
      _lastScrollOffset = 0;
      _showBars();
      // Restore sort/filter for the new library type, then load
      _restoreSortFilter().then((_) {
        if (mounted) _loadPage();
      });
      _loadGenres();
    }
  }

  void _tryInitialLoad() {
    final lib = context.read<LibraryProvider>();
    PlayerSettings.getHideEbookOnly().then((v) {
      if (mounted) setState(() => _hideEbookOnly = v);
    });
    PlayerSettings.getCollapseSeries().then((v) {
      if (mounted) setState(() => _collapseSeries = v);
    });
    PlayerSettings.getRectangleCovers().then((v) {
      if (mounted) setState(() => _rectangleCovers = v);
    });
    _restoreSortFilter().then((_) {
      if (!mounted) return;
      _lastLibraryId = lib.selectedLibraryId;
      lib.addListener(_onLibraryProviderChanged);
      if (lib.selectedLibraryId != null) {
        _loadPage();
        _loadGenres();
      } else {
        lib.addListener(_onLibraryChanged);
      }
    });
    PlayerSettings.settingsChanged.addListener(_onSettingsChanged);
  }

  Future<void> _restoreSortFilter() async {
    final results = await Future.wait([
      PlayerSettings.getLibrarySort(),
      PlayerSettings.getLibrarySortAsc(),
      PlayerSettings.getLibraryFilter(),
      PlayerSettings.getLibraryGenreFilter(),
      PlayerSettings.getSeriesSort(),
      PlayerSettings.getSeriesSortAsc(),
      PlayerSettings.getAuthorSort(),
      PlayerSettings.getAuthorSortAsc(),
      PlayerSettings.getPodcastSort(),
      PlayerSettings.getPodcastSortAsc(),
      PlayerSettings.getLibraryTab(),
      PlayerSettings.getNarratorSort(),
      PlayerSettings.getNarratorSortAsc(),
    ]);
    if (!mounted) return;
    final sortName = results[0] as String;
    final sortAsc = results[1] as bool;
    final filterName = results[2] as String;
    final genreFilter = results[3] as String;
    final seriesSortName = results[4] as String;
    final seriesSortAsc = results[5] as bool;
    final authorSortName = results[6] as String;
    final authorSortAsc = results[7] as bool;
    final podcastSortName = results[8] as String;
    final podcastSortAsc = results[9] as bool;
    final savedTab = results[10] as int;
    final narratorSortName = results[11] as String;
    final narratorSortAsc = results[12] as bool;
    final isPodcast = context.read<LibraryProvider>().isPodcastLibrary;
    setState(() {
      // Book library sort/filter
      _sort = LibrarySort.values.firstWhere(
        (s) => s.name == sortName,
        orElse: () => LibrarySort.recentlyAdded,
      );
      _sortAsc = sortAsc;
      if (_sort == LibrarySort.random) _randomSeed = Random().nextInt(100000);
      _filter = LibraryFilter.values.firstWhere(
        (f) => f.name == filterName,
        orElse: () => LibraryFilter.none,
      );
      _genreFilter = genreFilter.isNotEmpty ? genreFilter : null;
      _seriesSort = LibrarySort.values.firstWhere(
        (s) => s.name == seriesSortName,
        orElse: () => LibrarySort.alphabetical,
      );
      _seriesSortAsc = seriesSortAsc;
      _authorSort = LibrarySort.values.firstWhere(
        (s) => s.name == authorSortName,
        orElse: () => LibrarySort.alphabetical,
      );
      _authorSortAsc = authorSortAsc;
      _narratorSort = LibrarySort.values.firstWhere(
        (s) => s.name == narratorSortName,
        orElse: () => LibrarySort.alphabetical,
      );
      _narratorSortAsc = narratorSortAsc;
      // Podcast sort
      _podcastSort = LibrarySort.values.firstWhere(
        (s) => s.name == podcastSortName,
        orElse: () => LibrarySort.recentlyAdded,
      );
      _podcastSortAsc = podcastSortAsc;
      // Apply podcast settings if currently on a podcast library
      if (isPodcast) {
        _sort = _podcastSort;
        _sortAsc = _podcastSortAsc;
        _filter = LibraryFilter.none;
        _genreFilter = null;
      }
      // Restore last active tab (only for book libraries with tabs)
      if (!isPodcast && savedTab > 0 && savedTab < 4) {
        _currentTab = savedTab;
        _tabController?.animateTo(savedTab);
      }
    });
    // Lazy load data for the restored tab
    if (!isPodcast && savedTab == 1 && _seriesItems.isEmpty && !_isLoadingSeriesPage) {
      _loadSeriesPage();
    } else if (!isPodcast && savedTab == 2 && !_authorsLoaded && !_isLoadingAuthors) {
      _loadAuthors();
    } else if (!isPodcast && savedTab == 3 && !_narratorsLoaded && !_isLoadingNarrators) {
      _loadNarrators();
    }
  }

  void _onSettingsChanged() {
    Future.wait([
      PlayerSettings.getHideEbookOnly(),
      PlayerSettings.getCollapseSeries(),
      PlayerSettings.getRectangleCovers(),
    ]).then((values) {
      final newHideEbook = values[0];
      final newCollapse = values[1];
      final newRectCovers = values[2];
      if (!mounted) return;
      final coversChanged = newRectCovers != _rectangleCovers;
      if (coversChanged) {
        setState(() => _rectangleCovers = newRectCovers);
      }
      if (newHideEbook != _hideEbookOnly || newCollapse != _collapseSeries) {
        _loadGeneration++;
        setState(() {
          _hideEbookOnly = newHideEbook;
          _collapseSeries = newCollapse;
          _items.clear();
          _page = 0;
          _hasMore = true;
          _isLoadingPage = false;
        });
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
        _loadPage();
      }
    });
  }

  void _onLibraryChanged() {
    if (!mounted) return;
    final lib = context.read<LibraryProvider>();
    if (lib.selectedLibraryId != null && _items.isEmpty && !_isLoadingPage) {
      lib.removeListener(_onLibraryChanged);
      _loadPage();
      _loadGenres();
    }
  }

  Future<void> _loadGenres() async {
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null || lib.selectedLibraryId == null) return;
    final filterData = await api.getLibraryFilterData(lib.selectedLibraryId!);
    if (filterData != null && mounted) {
      final genres = filterData['genres'] as List<dynamic>? ?? [];
      setState(() {
        _availableGenres = genres.map((g) => g is Map ? (g['name'] as String? ?? '') : g.toString()).where((g) => g.isNotEmpty).toList()..sort();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _seriesScrollController.dispose();
    _authorsScrollController.dispose();
    _narratorsScrollController.dispose();
    _headerAnimController.dispose();
    barsVisibleNotifier.dispose();
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    PlayerSettings.settingsChanged.removeListener(_onSettingsChanged);
    try {
      final lib = context.read<LibraryProvider>();
      lib.removeListener(_onLibraryChanged);
      lib.removeListener(_onLibraryProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  // ── Scroll-based pagination + direction tracking ──
  void _onScroll() {
    _onScrollDirection(_scrollController);
    if (_isInSearchMode) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadPage();
    }
  }

  void _onSeriesScroll() {
    _onScrollDirection(_seriesScrollController);
    if (_seriesScrollController.position.pixels >=
        _seriesScrollController.position.maxScrollExtent - 400) {
      _loadSeriesPage();
    }
  }

  void _onAuthorsScroll() {
    _onScrollDirection(_authorsScrollController);
  }

  void _onNarratorsScroll() {
    _onScrollDirection(_narratorsScrollController);
  }

  // ══════════════════════════════════════════════════════════════
  // LIBRARY TAB - Load a page of items
  // ══════════════════════════════════════════════════════════════
  Future<void> _loadPage() async {
    if (_isLoadingPage || !_hasMore) return;
    setState(() => _isLoadingPage = true);
    final gen = ++_loadGeneration;

    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (lib.selectedLibraryId == null) {
      setState(() => _isLoadingPage = false);
      return;
    }

    // Offline fallback: show downloaded items instead of hitting the API
    if (api == null || lib.isOffline) {
      _loadOfflinePage(lib);
      return;
    }

    String sort;
    int desc;
    switch (_sort) {
      case LibrarySort.recentlyAdded:
        sort = 'addedAt'; desc = _sortAsc ? 0 : 1; break;
      case LibrarySort.alphabetical:
        sort = 'media.metadata.title'; desc = _sortAsc ? 0 : 1; break;
      case LibrarySort.authorName:
        sort = 'media.metadata.authorNameLF'; desc = _sortAsc ? 0 : 1; break;
      case LibrarySort.publishedYear:
        sort = 'media.metadata.publishedYear'; desc = _sortAsc ? 0 : 1; break;
      case LibrarySort.duration:
      case LibrarySort.totalDuration:
        sort = 'media.duration'; desc = _sortAsc ? 0 : 1; break;
      case LibrarySort.random:
        sort = 'addedAt'; desc = 1; break;
    }

    String? filter;
    if (_filter == LibraryFilter.inProgress) {
      filter = 'progress.${base64Encode(utf8.encode('in-progress'))}';
    } else if (_filter == LibraryFilter.finished) {
      filter = 'progress.${base64Encode(utf8.encode('finished'))}';
    } else if (_filter == LibraryFilter.notStarted) {
      filter = 'progress.${base64Encode(utf8.encode('not-started'))}';
    } else if (_filter == LibraryFilter.hasEbook) {
      filter = 'ebooks.${base64Encode(utf8.encode('ebook'))}';
    } else if (_filter == LibraryFilter.genre && _genreFilter != null) {
      filter = 'genres.${base64Encode(utf8.encode(_genreFilter!))}';
    }
    // Downloaded filter is client-side — handled after loading

    final useClientFilter = _filter == LibraryFilter.downloaded;
    final fetchAll = _sort == LibrarySort.random || useClientFilter;

    if (fetchAll) {
      // Paginate through ALL items for client-side filters / random sort
      const fetchLimit = 500;
      int fetchPage = 0;
      int total = 0;
      while (mounted && gen == _loadGeneration) {
        final result = await api.getLibraryItems(
          lib.selectedLibraryId!,
          page: fetchPage,
          limit: fetchLimit,
          sort: sort,
          desc: desc,
          filter: filter,
          collapseSeries: _collapseSeries && !useClientFilter && !lib.isPodcastLibrary,
        );
        if (result == null || !mounted || gen != _loadGeneration) break;
        final results = (result['results'] as List<dynamic>?) ?? [];
        total = (result['total'] as int?) ?? 0;
        for (final r in results) {
          if (r is Map<String, dynamic>) {
            final id = r['id'] as String?;
            final ts = r['updatedAt'] as num?;
            if (id != null && ts != null) lib.registerUpdatedAt(id, ts.toInt());
            if (id != null) {
              final coverPath = (r['media'] as Map<String, dynamic>?)?['coverPath'] as String?;
              lib.registerHasCover(id, coverPath != null && coverPath.isNotEmpty);
            }
            if (useClientFilter && !DownloadService().isDownloaded(id ?? '')) continue;
            if (_hideEbookOnly && PlayerSettings.isEbookOnly(r)) continue;
            _items.add(r);
          }
        }
        fetchPage++;
        if (fetchPage * fetchLimit >= total) break;
      }
      if (mounted && gen == _loadGeneration) {
        setState(() {
          _totalItems = total;
          if (_sort == LibrarySort.random) _items.shuffle(Random(_randomSeed));
          _hasMore = false;
          _isLoadingPage = false;
        });
      }
    } else {
      final result = await api.getLibraryItems(
        lib.selectedLibraryId!,
        page: _page,
        limit: _pageSize,
        sort: sort,
        desc: desc,
        filter: filter,
        collapseSeries: _collapseSeries && !lib.isPodcastLibrary,
      );

      if (result != null && mounted && gen == _loadGeneration) {
        final results = (result['results'] as List<dynamic>?) ?? [];
        final total = (result['total'] as int?) ?? 0;
        setState(() {
          _totalItems = total;
          for (final r in results) {
            if (r is Map<String, dynamic>) {
              final id = r['id'] as String?;
              final ts = r['updatedAt'] as num?;
              if (id != null && ts != null) lib.registerUpdatedAt(id, ts.toInt());
              if (id != null) {
                final coverPath = (r['media'] as Map<String, dynamic>?)?['coverPath'] as String?;
                lib.registerHasCover(id, coverPath != null && coverPath.isNotEmpty);
              }
              if (_hideEbookOnly && PlayerSettings.isEbookOnly(r)) continue;
              _items.add(r);
            }
          }
          _page++;
          // Compare raw server results to page size, not filtered _items to total.
          // Client-side filters (e.g. hide-ebook-only) reduce _items below total,
          // which would leave _hasMore permanently true and the loader spinning.
          _hasMore = results.length >= _pageSize;
          debugPrint('[LibPage] page=${_page - 1} results=${results.length} pageSize=$_pageSize filtered=${_items.length} total=$total hideEbook=$_hideEbookOnly hasMore=$_hasMore');
          _isLoadingPage = false;
        });
      } else if (mounted && gen == _loadGeneration) {
        setState(() => _isLoadingPage = false);
      }
    }
  }

  /// Offline fallback: populate the grid from downloaded items.
  void _loadOfflinePage(LibraryProvider lib) {
    final l = AppLocalizations.of(context)!;
    final isPodcast = lib.isPodcastLibrary;
    final downloads = DownloadService().downloadedItems
        .where((dl) => (dl.itemId.length > 36) == isPodcast)
        .toList();

    final items = <Map<String, dynamic>>[];
    for (final dl in downloads) {
      double duration = 0;
      List<dynamic> chapters = [];
      if (dl.sessionData != null) {
        try {
          final session = jsonDecode(dl.sessionData!) as Map<String, dynamic>;
          duration = (session['duration'] as num?)?.toDouble() ?? 0;
          chapters = session['chapters'] as List<dynamic>? ?? [];
        } catch (_) {}
      }
      items.add({
        'id': dl.itemId,
        'media': {
          'metadata': {
            'title': dl.title ?? l.libraryScreenUnknownTitle,
            'authorName': dl.author ?? '',
          },
          'duration': duration,
          'chapters': chapters,
        },
      });
    }

    // Sort alphabetically by title for a clean offline view
    items.sort((a, b) {
      final ta = ((a['media'] as Map)['metadata'] as Map)['title'] as String;
      final tb = ((b['media'] as Map)['metadata'] as Map)['title'] as String;
      return ta.toLowerCase().compareTo(tb.toLowerCase());
    });

    setState(() {
      _items.clear();
      _items.addAll(items);
      _totalItems = items.length;
      _hasMore = false;
      _isLoadingPage = false;
    });
  }

  // ══════════════════════════════════════════════════════════════
  // SERIES TAB - Load a page of series
  // ══════════════════════════════════════════════════════════════
  Future<void> _loadSeriesPage() async {
    if (_isLoadingSeriesPage || !_hasMoreSeries) return;
    setState(() => _isLoadingSeriesPage = true);

    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null || lib.selectedLibraryId == null) {
      setState(() => _isLoadingSeriesPage = false);
      return;
    }

    String sort;
    switch (_seriesSort) {
      case LibrarySort.alphabetical:
        sort = 'name'; break;
      case LibrarySort.recentlyAdded:
        sort = 'addedAt'; break;
      case LibrarySort.totalDuration:
        sort = 'numBooks'; break;
      default:
        sort = 'name'; break;
    }

    // For large libraries (250+ series), serve cached data on first load
    final cacheKey = '${lib.selectedLibraryId}:$sort:${_seriesSortAsc ? 0 : 1}';
    if (_seriesPage == 0 && _seriesItems.isEmpty) {
      final cached = lib.getSeriesTabCache(cacheKey);
      if (cached != null) {
        final cachedTotal = (cached['total'] as int?) ?? 0;
        if (cachedTotal >= 250) {
          final items = (cached['items'] as List<Map<String, dynamic>>?) ?? [];
          if (items.isNotEmpty && mounted) {
            setState(() {
              _seriesItems.addAll(items);
              _totalSeries = cachedTotal;
              _seriesPage = (items.length / 50).ceil();
              _hasMoreSeries = items.length < cachedTotal;
              _isLoadingSeriesPage = false;
            });
            // Refresh in background
            _refreshSeriesInBackground(api, lib, sort, cacheKey);
            return;
          }
        }
      }
    }

    final result = await api.getLibrarySeries(
      lib.selectedLibraryId!,
      page: _seriesPage,
      limit: 50,
      sort: sort,
      desc: _seriesSortAsc ? 0 : 1,
    );

    if (result != null && mounted) {
      final results = (result['results'] as List<dynamic>?) ?? [];
      final total = (result['total'] as int?) ?? 0;
      setState(() {
        _totalSeries = total;
        for (final r in results) {
          if (r is Map<String, dynamic>) {
            _seriesItems.add(r);
          }
        }
        _seriesPage++;
        _hasMoreSeries = _seriesItems.length < total;
        _isLoadingSeriesPage = false;
      });
      // Update cache
      if (total >= 250) {
        lib.setSeriesTabCache(cacheKey, List<Map<String, dynamic>>.from(_seriesItems), total);
      }
    } else if (mounted) {
      setState(() => _isLoadingSeriesPage = false);
    }
  }

  Future<void> _refreshSeriesInBackground(ApiService api, LibraryProvider lib, String sort, String cacheKey) async {
    final allItems = <Map<String, dynamic>>[];
    int page = 0;
    int total = 0;
    while (true) {
      final result = await api.getLibrarySeries(
        lib.selectedLibraryId!,
        page: page,
        limit: 50,
        sort: sort,
        desc: _seriesSortAsc ? 0 : 1,
      );
      if (result == null) break;
      final results = (result['results'] as List<dynamic>?) ?? [];
      total = (result['total'] as int?) ?? 0;
      for (final r in results) {
        if (r is Map<String, dynamic>) allItems.add(r);
      }
      if (allItems.length >= total || results.isEmpty) break;
      page++;
    }
    if (allItems.isNotEmpty && mounted) {
      lib.setSeriesTabCache(cacheKey, allItems, total);
      setState(() {
        _seriesItems.clear();
        _seriesItems.addAll(allItems);
        _totalSeries = total;
        _seriesPage = (allItems.length / 50).ceil();
        _hasMoreSeries = allItems.length < total;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════
  // AUTHORS TAB - Load all authors
  // ══════════════════════════════════════════════════════════════
  Future<void> _loadAuthors() async {
    if (_isLoadingAuthors) return;
    setState(() => _isLoadingAuthors = true);

    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null || lib.selectedLibraryId == null) {
      setState(() { _isLoadingAuthors = false; _authorsLoaded = true; });
      return;
    }

    final authors = await api.getLibraryAuthors(lib.selectedLibraryId!);
    if (mounted) {
      setState(() {
        _authors = authors;
        _sortAuthors();
        _isLoadingAuthors = false;
        _authorsLoaded = true;
      });
    }
  }

  void _sortAuthors() {
    _authors.sort((a, b) {
      if (_authorSort == LibrarySort.totalDuration) {
        final aCount = a['numBooks'] as int? ?? 0;
        final bCount = b['numBooks'] as int? ?? 0;
        return _authorSortAsc ? aCount.compareTo(bCount) : bCount.compareTo(aCount);
      }
      final aName = (a['name'] as String? ?? '').toLowerCase();
      final bName = (b['name'] as String? ?? '').toLowerCase();
      return _authorSortAsc ? aName.compareTo(bName) : bName.compareTo(aName);
    });
  }

  Future<void> _loadNarrators() async {
    if (_isLoadingNarrators) return;
    setState(() => _isLoadingNarrators = true);

    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null || lib.selectedLibraryId == null) {
      setState(() { _isLoadingNarrators = false; _narratorsLoaded = true; });
      return;
    }

    final narrators = await api.getLibraryNarrators(lib.selectedLibraryId!);
    if (mounted) {
      setState(() {
        _narrators = narrators;
        _sortNarrators();
        _isLoadingNarrators = false;
        _narratorsLoaded = true;
      });
    }
  }

  void _sortNarrators() {
    _narrators.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      return _narratorSortAsc ? aLower.compareTo(bLower) : bLower.compareTo(aLower);
    });
  }

  // ── Change sort and reload ──
  void _changeSort(LibrarySort newSort) {
    if (_currentTab == 1) { _changeSeriesSort(newSort); return; }
    if (_currentTab == 2) { _changeAuthorSort(newSort); return; }
    if (_currentTab == 3) { _changeNarratorSort(newSort); return; }

    final isPodcast = context.read<LibraryProvider>().isPodcastLibrary;
    if (newSort == _sort) {
      // Tapping the same sort toggles direction (except Random)
      if (newSort == LibrarySort.random) return;
      setState(() {
        _sortAsc = !_sortAsc;
        _items.clear();
        _page = 0;
        _hasMore = true;
        _isLoadingPage = false;
      });
      if (isPodcast) {
        _podcastSortAsc = _sortAsc;
        PlayerSettings.setPodcastSortAsc(_sortAsc);
      } else {
        PlayerSettings.setLibrarySortAsc(_sortAsc);
      }
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      _loadPage();
      return;
    }
    setState(() {
      _sort = newSort;
      // Smart defaults: A-Z and Length start ascending, others start descending
      _sortAsc = newSort == LibrarySort.alphabetical || newSort == LibrarySort.authorName || newSort == LibrarySort.duration;
      _items.clear();
      _page = 0;
      _hasMore = true;
      _isLoadingPage = false;
      if (newSort == LibrarySort.random) {
        _randomSeed = Random().nextInt(100000);
      }
    });
    if (isPodcast) {
      _podcastSort = _sort;
      _podcastSortAsc = _sortAsc;
      PlayerSettings.setPodcastSort(_sort.name);
      PlayerSettings.setPodcastSortAsc(_sortAsc);
    } else {
      PlayerSettings.setLibrarySort(_sort.name);
      PlayerSettings.setLibrarySortAsc(_sortAsc);
    }
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _loadPage();
  }

  void _changeSeriesSort(LibrarySort newSort) {
    if (newSort == _seriesSort) {
      setState(() { _seriesSortAsc = !_seriesSortAsc; });
    } else {
      setState(() {
        _seriesSort = newSort;
        _seriesSortAsc = newSort == LibrarySort.alphabetical;
      });
    }
    setState(() {
      _seriesItems.clear();
      _seriesPage = 0;
      _hasMoreSeries = true;
      _isLoadingSeriesPage = false;
    });
    PlayerSettings.setSeriesSort(_seriesSort.name);
    PlayerSettings.setSeriesSortAsc(_seriesSortAsc);
    if (_seriesScrollController.hasClients) _seriesScrollController.jumpTo(0);
    _loadSeriesPage();
  }

  void _changeAuthorSort(LibrarySort newSort) {
    if (newSort == _authorSort) {
      setState(() { _authorSortAsc = !_authorSortAsc; });
    } else {
      setState(() {
        _authorSort = newSort;
        _authorSortAsc = newSort == LibrarySort.alphabetical;
      });
    }
    PlayerSettings.setAuthorSort(_authorSort.name);
    PlayerSettings.setAuthorSortAsc(_authorSortAsc);
    setState(() => _sortAuthors());
    if (_authorsScrollController.hasClients) _authorsScrollController.jumpTo(0);
  }

  void _changeNarratorSort(LibrarySort newSort) {
    if (newSort == _narratorSort) {
      setState(() { _narratorSortAsc = !_narratorSortAsc; });
    } else {
      setState(() {
        _narratorSort = newSort;
        _narratorSortAsc = true;
      });
    }
    PlayerSettings.setNarratorSort(_narratorSort.name);
    PlayerSettings.setNarratorSortAsc(_narratorSortAsc);
    setState(() => _sortNarrators());
    if (_narratorsScrollController.hasClients) _narratorsScrollController.jumpTo(0);
  }

  // ── Change filter and reload ──
  void _changeFilter(LibraryFilter newFilter, {String? genre}) {
    final effective = (newFilter == _filter && genre == _genreFilter) ? LibraryFilter.none : newFilter;
    if (effective == _filter && genre == _genreFilter) return;
    final isPodcast = context.read<LibraryProvider>().isPodcastLibrary;
    _loadGeneration++;
    setState(() {
      _filter = effective;
      _genreFilter = effective == LibraryFilter.genre ? genre : null;
      _items.clear();
      _page = 0;
      _hasMore = true;
      _isLoadingPage = false;
    });
    if (!isPodcast) {
      PlayerSettings.setLibraryFilter(_filter.name);
      PlayerSettings.setLibraryGenreFilter(_genreFilter);
    }
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _loadPage();
  }

  // ── Search ──
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    // Always show bars when entering/exiting search
    _showBars();
    if (query.trim().isEmpty) {
      setState(() {
        _searchBookResults = [];
        _searchSeriesResults = [];
        _searchAuthorResults = [];
        _searchEpisodeResults = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null || lib.selectedLibraryId == null) return;

    setState(() => _isSearching = true);

    final isPodcast = lib.isPodcastLibrary;
    final result = await api.searchLibrary(lib.selectedLibraryId!, query);
    if (result != null && mounted) {
      setState(() {
        if (isPodcast) {
          _searchBookResults = (result['podcast'] as List<dynamic>?) ?? [];
        } else {
          _searchBookResults = (result['book'] as List<dynamic>?) ?? [];
          if (_hideEbookOnly) {
            _searchBookResults = _searchBookResults.where((r) {
              final item = r['libraryItem'] as Map<String, dynamic>? ?? r as Map<String, dynamic>;
              return !PlayerSettings.isEbookOnly(item);
            }).toList();
          }
        }
        _searchSeriesResults = (result['series'] as List<dynamic>?) ?? [];
        _searchAuthorResults = (result['authors'] as List<dynamic>?) ?? [];
        _isSearching = false;
        _hasSearched = true;
      });

      // For podcast libraries, also search episode titles client-side
      if (isPodcast) {
        _searchEpisodes(query, lib.selectedLibraryId!, api);
      }
    } else if (mounted) {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  List<Map<String, dynamic>>? _cachedShowsWithEpisodes;
  String? _cachedShowsLibraryId;

  Future<void> _searchEpisodes(String query, String libraryId, dynamic api) async {
    final lowerQuery = query.toLowerCase();

    // Cache all shows with episodes so subsequent searches are instant
    if (_cachedShowsWithEpisodes == null || _cachedShowsLibraryId != libraryId) {
      final items = await api.getLibraryItems(libraryId, limit: 100);
      if (items == null || !mounted) return;
      final results = items['results'] as List<dynamic>? ?? [];

      final shows = <Map<String, dynamic>>[];
      final futures = <Future>[];
      for (final r in results) {
        final show = (r['libraryItem'] ?? r) as Map<String, dynamic>;
        final showId = show['id'] as String?;
        if (showId == null) continue;
        futures.add(api.getLibraryItem(showId).then((fullItem) {
          if (fullItem != null) shows.add(fullItem);
        }));
      }
      await Future.wait(futures);
      _cachedShowsWithEpisodes = shows;
      _cachedShowsLibraryId = libraryId;
    }

    final episodeMatches = <Map<String, dynamic>>[];
    for (final show in _cachedShowsWithEpisodes!) {
      final media = show['media'] as Map<String, dynamic>? ?? {};
      final episodes = media['episodes'] as List<dynamic>? ?? [];
      for (final ep in episodes) {
        final title = (ep['title'] as String? ?? '').toLowerCase();
        if (title.contains(lowerQuery)) {
          episodeMatches.add({'show': show, 'episode': ep});
        }
      }
    }
    if (mounted && _searchController.text.trim().toLowerCase() == lowerQuery) {
      setState(() => _searchEpisodeResults = episodeMatches);
    }
  }

  void _showLibraryPicker(BuildContext context, ColorScheme cs, TextTheme tt, List<dynamic> allLibraries, LibraryProvider lib) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(l.selectLibrary, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
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
                      leading: Icon(mediaType == 'podcast' ? Icons.podcasts_rounded : Icons.auto_stories_rounded,
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

  String _filterLabelOf(AppLocalizations l) => switch (_filter) {
    LibraryFilter.inProgress => l.inProgress,
    LibraryFilter.finished => l.filterFinished,
    LibraryFilter.notStarted => l.notStarted,
    LibraryFilter.downloaded => l.downloaded,
    LibraryFilter.inASeries => l.libraryTabSeries,
    LibraryFilter.hasEbook => l.hasEbook,
    LibraryFilter.genre => _genreFilter ?? l.genre,
    LibraryFilter.none => '',
  };

  void _showSortFilterSheet(BuildContext context, ColorScheme cs, TextTheme tt, {int initialTab = 0}) {
    final LibraryTab tab;
    final LibrarySort currentSort;
    final bool currentSortAsc;
    switch (_currentTab) {
      case 1:
        tab = LibraryTab.series;
        currentSort = _seriesSort;
        currentSortAsc = _seriesSortAsc;
        break;
      case 2:
        tab = LibraryTab.authors;
        currentSort = _authorSort;
        currentSortAsc = _authorSortAsc;
        break;
      case 3:
        tab = LibraryTab.narrators;
        currentSort = _narratorSort;
        currentSortAsc = _narratorSortAsc;
        break;
      default:
        tab = LibraryTab.library;
        currentSort = _sort;
        currentSortAsc = _sortAsc;
        break;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SortFilterSheet(
        currentSort: currentSort,
        sortAsc: currentSortAsc,
        currentFilter: _filter,
        genreFilter: _genreFilter,
        availableGenres: _availableGenres,
        initialTab: initialTab,
        cs: cs, tt: tt,
        libraryTab: tab,
        onSortChanged: (sort) { Navigator.pop(ctx); _changeSort(sort); },
        onSortDirectionToggled: () {
          if (_currentTab == 1) {
            setState(() { _seriesSortAsc = !_seriesSortAsc; _seriesItems.clear(); _seriesPage = 0; _hasMoreSeries = true; _isLoadingSeriesPage = false; });
            PlayerSettings.setSeriesSortAsc(_seriesSortAsc);
            if (_seriesScrollController.hasClients) _seriesScrollController.jumpTo(0);
            _loadSeriesPage();
          } else if (_currentTab == 2) {
            setState(() { _authorSortAsc = !_authorSortAsc; _sortAuthors(); });
            PlayerSettings.setAuthorSortAsc(_authorSortAsc);
            if (_authorsScrollController.hasClients) _authorsScrollController.jumpTo(0);
          } else if (_currentTab == 3) {
            setState(() { _narratorSortAsc = !_narratorSortAsc; _sortNarrators(); });
            PlayerSettings.setNarratorSortAsc(_narratorSortAsc);
            if (_narratorsScrollController.hasClients) _narratorsScrollController.jumpTo(0);
          } else {
            setState(() { _sortAsc = !_sortAsc; _items.clear(); _page = 0; _hasMore = true; _isLoadingPage = false; });
            final isPodcast = context.read<LibraryProvider>().isPodcastLibrary;
            if (isPodcast) {
              _podcastSortAsc = _sortAsc;
              PlayerSettings.setPodcastSortAsc(_sortAsc);
            } else {
              PlayerSettings.setLibrarySortAsc(_sortAsc);
            }
            if (_scrollController.hasClients) _scrollController.jumpTo(0);
            _loadPage();
          }
          Navigator.pop(ctx);
        },
        onFilterChanged: (filter, {String? genre}) { Navigator.pop(ctx); _changeFilter(filter, genre: genre); },
        onClearFilter: () { Navigator.pop(ctx); _changeFilter(LibraryFilter.none); },
        collapseSeries: _collapseSeries,
        onCollapseSeriesChanged: (value) {
          _loadGeneration++;
          setState(() {
            _collapseSeries = value;
            _items.clear();
            _page = 0;
            _hasMore = true;
            _isLoadingPage = false;
          });
          PlayerSettings.setCollapseSeries(value);
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
          _loadPage();
        },
        isPodcastLibrary: context.read<LibraryProvider>().isPodcastLibrary,
        onUpcomingReleases: tab == LibraryTab.series ? () {
          Navigator.pop(ctx);
          _openUpcomingReleases();
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final lowerFade = Color.lerp(cs.surface, scaffoldBg, 0.55) ?? scaffoldBg;
    final lib = context.watch<LibraryProvider>();
    final allLibraries = lib.libraries;
    final hasMultipleLibraries = allLibraries.length > 1;
    final libraryName = lib.selectedLibrary?['name'] as String? ?? l.libraryFallback;
    final hasTabs = _tabController != null && !_isInSearchMode;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          if (!oledNotifier.value)
            OverflowBox(
              maxHeight: MediaQuery.of(context).size.height,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
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
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                SizeTransition(
                  sizeFactor: _headerAnimController,
                  axisAlignment: -1.0,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                AbsorbPageHeader(
                  title: l.libraryTitle,
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
                  actions: hasMultipleLibraries ? [
                    GestureDetector(
                      onTap: () => _showLibraryPicker(context, cs, tt, allLibraries, lib),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                        ),
                        child: SizedBox(
                          height: 20,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(lib.isPodcastLibrary ? Icons.podcasts_rounded : Icons.auto_stories_rounded, size: 18, color: cs.onSurfaceVariant),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(libraryName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis, maxLines: 1),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.unfold_more_rounded, size: 18, color: cs.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SearchBar(
                    controller: _searchController,
                    focusNode: _focusNode,
                    hintText: lib.isPodcastLibrary
                        ? l.librarySearchShowsHint
                        : l.librarySearchBooksHint,
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.search_rounded),
                    ),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            _focusNode.unfocus();
                          },
                        ),
                    ],
                    onChanged: _onSearchChanged,
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                    ),
                  ),
                ),
                // Item count + filter badge row
                if (!_isInSearchMode)
                  _buildInfoRow(cs, tt, l),
                ]),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _isInSearchMode
                          ? _buildSearchResults(cs, tt, l)
                          : hasTabs
                              ? _buildTabbedContent(cs, tt)
                              : _buildGrid(),
                      // Floating tab bar at bottom (book libraries only, hidden during search)
                      if (hasTabs)
                        Positioned(
                          left: 0, right: 0,
                          bottom: 12,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: barsVisibleNotifier,
                            builder: (_, visible, child) => AnimatedSlide(
                              duration: const Duration(milliseconds: 250),
                              offset: visible ? Offset.zero : const Offset(0, 3),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: visible ? 1.0 : 0.0,
                                child: child,
                              ),
                            ),
                            child: _buildFloatingTabBar(cs),
                          ),
                        ),
                      // Floating sort button for podcast libraries
                      if (!hasTabs && !_isInSearchMode)
                        Positioned(
                          left: 0, right: 0,
                          bottom: 12,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: barsVisibleNotifier,
                            builder: (_, visible, child) => AnimatedSlide(
                              duration: const Duration(milliseconds: 250),
                              offset: visible ? Offset.zero : const Offset(0, 3),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: visible ? 1.0 : 0.0,
                                child: child,
                              ),
                            ),
                            child: Center(child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFloatingSortButton(cs, tt),
                                if (context.read<AuthProvider>().isRoot) ...[
                                  const SizedBox(width: 8),
                                  _buildFloatingManageButton(cs),
                                ],
                              ],
                            )),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTabBar(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final labels = [l.libraryTabLibrary, l.libraryTabSeries, l.libraryTabAuthors, l.libraryTabNarrators];
    return Center(child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(labels.length, (i) {
              final active = _currentTab == i;
              return GestureDetector(
                onTap: () {
                  if (active) {
                    _showSortFilterSheet(context, cs, Theme.of(context).textTheme);
                  } else {
                    _tabController?.animateTo(i);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: active ? 14 : 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.sort_rounded, size: 14, color: cs.primary),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ));
  }


  Future<void> _openUpcomingReleases() async {
    final saved = await PlayerSettings.getAudibleRegion();
    if (saved.isEmpty) {
      if (!mounted) return;
      final chosen = await showAudibleRegionPicker(context, currentRegion: '');
      if (chosen == null || !mounted) return;
      await PlayerSettings.setAudibleRegion(chosen);
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const UpcomingReleasesScreen(),
    ));
  }

  Widget _buildFloatingSortButton(ColorScheme cs, TextTheme tt) {
    return GestureDetector(
      onTap: () => _showSortFilterSheet(context, cs, tt),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.sort,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.sort_rounded, size: 14, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingManageButton(ColorScheme cs) {
    return GestureDetector(
      onTap: () {
        final lib = context.read<LibraryProvider>().selectedLibrary;
        if (lib != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AdminPodcastsScreen(library: lib)));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.settings_rounded, size: 16, color: cs.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    String countText;
    switch (_currentTab) {
      case 1:
        countText = l.librarySeriesCount(_totalSeries);
        break;
      case 2:
        countText = l.libraryAuthorsCount(_authors.length);
        break;
      case 3:
        countText = l.libraryNarratorsCount(_narrators.length);
        break;
      default:
        countText = l.libraryBooksCount(_items.length, _totalItems);
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (_currentTab == 0 && _filter != LibraryFilter.none) ...[
            GestureDetector(
              onTap: () => _changeFilter(LibraryFilter.none),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list_rounded, size: 14, color: cs.tertiary),
                    const SizedBox(width: 4),
                    Text(_filterLabelOf(l), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.tertiary),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                    const SizedBox(width: 4),
                    Icon(Icons.close_rounded, size: 14, color: cs.tertiary),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(countText,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildTabbedContent(ColorScheme cs, TextTheme tt) {
    // Use IndexedStack to preserve scroll positions across tabs
    return IndexedStack(
      index: _currentTab,
      children: [
        _buildGrid(),
        _buildSeriesGrid(),
        _buildAuthorsGrid(),
        _buildNarratorsGrid(),
      ],
    );
  }

  // ── Pull-to-refresh ──
  Future<void> _refreshAll() async {
    final lib = context.read<LibraryProvider>();
    await lib.refresh();
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      if (_sort == LibrarySort.random) {
        _randomSeed = Random(_randomSeed).nextInt(100000);
      }
    });
    await _loadPage();
  }

  Future<void> _refreshSeries() async {
    setState(() {
      _seriesItems.clear();
      _seriesPage = 0;
      _hasMoreSeries = true;
      _isLoadingSeriesPage = false;
    });
    await _loadSeriesPage();
  }

  Future<void> _refreshAuthors() async {
    setState(() {
      _authors.clear();
      _authorsLoaded = false;
      _isLoadingAuthors = false;
    });
    await _loadAuthors();
  }

  // ═══════════════════════════════════════════════════════════════
  // LIBRARY TAB - BROWSE GRID
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGrid() {
    return LibraryBooksTab(
      items: _items,
      isLoadingPage: _isLoadingPage,
      hasMore: _hasMore,
      scrollController: _scrollController,
      filter: _filter,
      genreFilter: _genreFilter,
      rectangleCovers: _rectangleCovers,
      coverAspectRatio: _coverAspectRatio,
      onRefresh: _refreshAll,
      onClearFilter: () => _changeFilter(LibraryFilter.none),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SERIES TAB - GRID
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSeriesGrid() {
    return LibrarySeriesTab(
      seriesItems: _seriesItems,
      isLoadingSeriesPage: _isLoadingSeriesPage,
      hasMoreSeries: _hasMoreSeries,
      scrollController: _seriesScrollController,
      rectangleCovers: _rectangleCovers,
      coverAspectRatio: _coverAspectRatio,
      onRefresh: _refreshSeries,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTHORS TAB - GRID
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAuthorsGrid() {
    return LibraryAuthorsTab(
      authors: _authors,
      isLoadingAuthors: _isLoadingAuthors,
      authorsLoaded: _authorsLoaded,
      scrollController: _authorsScrollController,
      onRefresh: _refreshAuthors,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NARRATORS TAB - GRID
  // ═══════════════════════════════════════════════════════════════
  Future<void> _refreshNarrators() async {
    setState(() {
      _narrators.clear();
      _narratorsLoaded = false;
      _isLoadingNarrators = false;
    });
    await _loadNarrators();
  }

  Widget _buildNarratorsGrid() {
    return LibraryNarratorsTab(
      narrators: _narrators,
      isLoading: _isLoadingNarrators,
      loaded: _narratorsLoaded,
      scrollController: _narratorsScrollController,
      onRefresh: _refreshNarrators,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH RESULTS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSearchResults(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return const SizedBox.shrink();
    }
    if (_searchBookResults.isEmpty && _searchSeriesResults.isEmpty && _searchAuthorResults.isEmpty && _searchEpisodeResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(l.libraryNoResults,
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    final auth = context.read<AuthProvider>();
    final isPodcast = context.read<LibraryProvider>().isPodcastLibrary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // ─── BOOKS / SHOWS (only title matches) ───
        if (_searchBookResults.isNotEmpty) ...[
          ...() {
            final query = _searchController.text.trim().toLowerCase();
            final titleMatches = _searchBookResults.where((result) {
              final item = result['libraryItem'] as Map<String, dynamic>? ?? {};
              final media = item['media'] as Map<String, dynamic>? ?? {};
              final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
              final title = (metadata['title'] as String? ?? '').toLowerCase();
              return title.contains(query);
            }).toList();
            if (titleMatches.isEmpty) return <Widget>[];
            return <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Text(isPodcast ? l.librarySearchShows : l.librarySearchBooks,
                    style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600, color: cs.primary)),
              ),
              ...titleMatches.map((result) {
                final item =
                    result['libraryItem'] as Map<String, dynamic>? ?? {};
                return BookResultTile(
                  item: item,
                  serverUrl: auth.serverUrl,
                  token: auth.token,
                );
              }),
            ];
          }(),
        ],

        // ─── EPISODES ───
        if (_searchEpisodeResults.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
                4, _searchBookResults.isNotEmpty ? 20 : 8, 4, 8),
            child: Text(l.librarySearchEpisodes,
                style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: cs.primary)),
          ),
          ..._searchEpisodeResults.map((result) {
            return EpisodeResultTile(
              show: result['show']!,
              episode: result['episode']!,
              serverUrl: auth.serverUrl,
              token: auth.token,
            );
          }),
        ],

        // ─── SERIES ───
        if (_searchSeriesResults.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
                4, _searchBookResults.isNotEmpty ? 20 : 8, 4, 8),
            child: Text(l.librarySearchSeries,
                style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: cs.primary)),
          ),
          ..._searchSeriesResults.map((result) {
            final seriesData =
                result['series'] as Map<String, dynamic>? ?? {};
            final books = result['books'] as List<dynamic>? ?? [];
            return SeriesResultCard(
              series: seriesData,
              books: books,
              serverUrl: auth.serverUrl,
              token: auth.token,
            );
          }),
        ],

        // ─── AUTHORS ───
        if (_searchAuthorResults.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
                4, (_searchBookResults.isNotEmpty || _searchSeriesResults.isNotEmpty) ? 20 : 8, 4, 8),
            child: Text(l.librarySearchAuthors,
                style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: cs.primary)),
          ),
          ..._searchAuthorResults.map((result) {
            final authorData =
                result['author'] as Map<String, dynamic>? ?? result as Map<String, dynamic>;
            return AuthorResultTile(
              author: authorData,
              serverUrl: auth.serverUrl,
              token: auth.token,
            );
          }),
        ],
      ],
    );
  }
}

