import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/book_search_index.dart';
import '../services/socket_service.dart';
import '../services/download_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/library_picker_sheet.dart';
import '../widgets/library_search_results.dart';
import '../widgets/podcast_episode_feed.dart';
import '../main.dart' show flatNotifier, gradientIntensityNotifier;
import '../widgets/library_sort_filter_sheet.dart';
import '../widgets/desktop_batch_actions.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/library_books_tab.dart';
import '../widgets/library_series_tab.dart';
import '../widgets/library_authors_tab.dart';
import '../widgets/library_narrators_tab.dart';
import '../widgets/library_lists_tab.dart';
import '../widgets/collection_detail_sheet.dart';
import '../widgets/playlist_detail_sheet.dart';
import 'admin_podcasts_screen.dart';
import 'app_shell.dart';
import 'upcoming_releases_screen.dart';
import '../widgets/audible_series_sheet.dart' show showAudibleRegionPicker;
import '../widgets/offline_status_icon.dart';
import '../widgets/rmab_config_sheet.dart'
    show kRmabBaseUrlKey, kRmabApiTokenKey;
import '../widgets/rmab_search_results_sheet.dart';
import '../widgets/scroll_reveal.dart';
import '../services/scoped_prefs.dart';
import '../services/user_account_service.dart';
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
enum LibrarySort {
  recentlyAdded,
  alphabetical,
  authorName,
  authorFirstLast,
  publishedYear,
  duration,
  fileSize,
  lastUpdated,
  fileCreated,
  lastModified,
  progress,
  dateStarted,
  dateFinished,
  episodeCount,
  sequence,
  random,
  totalDuration,
}

// ─── Filter modes ────────────────────────────────────────────
enum LibraryFilter {
  none,
  notFinished,
  inProgress,
  finished,
  notStarted,
  downloaded,
  subscribed,
  inASeries,
  hasEbook,
  noEbook,
  hasSupplementaryEbook,
  noSupplementaryEbook,
  series,
  author,
  narrator,
  language,
  publisher,
  publishedDecade,
  noTracks,
  singleTrack,
  multipleTracks,
  abridged,
  issues,
  feedOpen,
  explicit,
  missingMetadata,
  genre,
  tag,
}

extension LibraryFilterProgressValue on LibraryFilter {
  String? get progressValue => switch (this) {
    LibraryFilter.notFinished => 'not-finished',
    LibraryFilter.inProgress => 'in-progress',
    LibraryFilter.finished => 'finished',
    LibraryFilter.notStarted => 'not-started',
    _ => null,
  };
}

enum MissingMetadataField {
  asin,
  isbn,
  subtitle,
  authors,
  publishedYear,
  series,
  description,
  genres,
  tags,
  narrators,
  publisher,
  language,
  cover,
  chapters,
}

extension MissingMetadataFieldValue on MissingMetadataField {
  String get filterValue => switch (this) {
    MissingMetadataField.asin => 'asin',
    MissingMetadataField.isbn => 'isbn',
    MissingMetadataField.subtitle => 'subtitle',
    MissingMetadataField.authors => 'authors',
    MissingMetadataField.publishedYear => 'publishedYear',
    MissingMetadataField.series => 'series',
    MissingMetadataField.description => 'description',
    MissingMetadataField.genres => 'genres',
    MissingMetadataField.tags => 'tags',
    MissingMetadataField.narrators => 'narrators',
    MissingMetadataField.publisher => 'publisher',
    MissingMetadataField.language => 'language',
    MissingMetadataField.cover => 'cover',
    MissingMetadataField.chapters => 'chapters',
  };
}

String missingMetadataFieldLabel(
  AppLocalizations l,
  MissingMetadataField field,
) => switch (field) {
  MissingMetadataField.asin => l.asinLabel,
  MissingMetadataField.isbn => l.isbnLabel,
  MissingMetadataField.subtitle => l.subtitleLabel,
  MissingMetadataField.authors => l.libraryTabAuthors,
  MissingMetadataField.publishedYear => l.publishedYear,
  MissingMetadataField.series => l.libraryTabSeries,
  MissingMetadataField.description => l.descriptionLabel,
  MissingMetadataField.genres => l.genresLabel,
  MissingMetadataField.tags => l.tagsLabel,
  MissingMetadataField.narrators => l.libraryTabNarrators,
  MissingMetadataField.publisher => l.publisherLabel,
  MissingMetadataField.language => l.languageLabel,
  MissingMetadataField.cover => l.editTabCover,
  MissingMetadataField.chapters => l.chapters,
};

String _encodedLibraryFilter(String group, String value) =>
    '$group.${base64Encode(utf8.encode(value))}';

String? buildLibraryFilterQuery(
  LibraryFilter filter, {
  String? genre,
  String? tag,
  String? filterValue,
  MissingMetadataField? missingMetadata,
}) {
  final progressValue = filter.progressValue;
  if (progressValue != null) {
    return _encodedLibraryFilter('progress', progressValue);
  }
  return switch (filter) {
    LibraryFilter.hasEbook => _encodedLibraryFilter('ebooks', 'ebook'),
    LibraryFilter.noEbook => _encodedLibraryFilter('ebooks', 'no-ebook'),
    LibraryFilter.hasSupplementaryEbook =>
      _encodedLibraryFilter('ebooks', 'supplementary'),
    LibraryFilter.noSupplementaryEbook =>
      _encodedLibraryFilter('ebooks', 'no-supplementary'),
    LibraryFilter.series when filterValue != null =>
      _encodedLibraryFilter('series', filterValue),
    LibraryFilter.author when filterValue != null =>
      _encodedLibraryFilter('authors', filterValue),
    LibraryFilter.narrator when filterValue != null =>
      _encodedLibraryFilter('narrators', filterValue),
    LibraryFilter.language when filterValue != null =>
      _encodedLibraryFilter('languages', filterValue),
    LibraryFilter.publisher when filterValue != null =>
      _encodedLibraryFilter('publishers', filterValue),
    LibraryFilter.publishedDecade when filterValue != null =>
      _encodedLibraryFilter('publishedDecades', filterValue),
    LibraryFilter.noTracks => _encodedLibraryFilter('tracks', 'none'),
    LibraryFilter.singleTrack => _encodedLibraryFilter('tracks', 'single'),
    LibraryFilter.multipleTracks => _encodedLibraryFilter('tracks', 'multi'),
    LibraryFilter.abridged => 'abridged',
    LibraryFilter.issues => 'issues',
    LibraryFilter.feedOpen => 'feed-open',
    LibraryFilter.explicit => 'explicit',
    LibraryFilter.genre when genre != null =>
      _encodedLibraryFilter('genres', genre),
    LibraryFilter.tag when tag != null => _encodedLibraryFilter('tags', tag),
    LibraryFilter.missingMetadata when missingMetadata != null =>
      _encodedLibraryFilter('missing', missingMetadata.filterValue),
    _ => null,
  };
}

bool libraryFilterSupportsMediaType(
  LibraryFilter filter, {
  required bool isPodcast,
}) {
  if (!isPodcast) return filter != LibraryFilter.subscribed;
  return switch (filter) {
    LibraryFilter.none ||
    LibraryFilter.subscribed ||
    LibraryFilter.genre ||
    LibraryFilter.tag ||
    LibraryFilter.language ||
    LibraryFilter.issues ||
    LibraryFilter.feedOpen ||
    LibraryFilter.explicit => true,
    _ => false,
  };
}

bool libraryFilterRequiresValue(LibraryFilter filter) => switch (filter) {
  LibraryFilter.series ||
  LibraryFilter.author ||
  LibraryFilter.narrator ||
  LibraryFilter.language ||
  LibraryFilter.publisher ||
  LibraryFilter.publishedDecade => true,
  _ => false,
};

/// Series-tab progress filter. Computed client-side from per-book progress
/// because the ABS server's `?filter=` param doesn't support series-level
/// progress queries (only book-level). When a filter is active the series
/// tab fetches all pages upfront so the client-side join is correct.
enum SeriesFilter { none, notFinished, inProgress, finished, notStarted }

bool seriesProgressMatchesFilter(
  SeriesFilter filter, {
  required int bookCount,
  required int startedCount,
  required int finishedCount,
}) => switch (filter) {
  SeriesFilter.notFinished => finishedCount < bookCount,
  SeriesFilter.finished => finishedCount == bookCount,
  SeriesFilter.notStarted => startedCount == 0,
  SeriesFilter.inProgress => startedCount > 0 && finishedCount < bookCount,
  SeriesFilter.none => true,
};

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  // ── Search state ──
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _rmabConfigured = false;

  /// GlobalKey on the SearchBar so its Element (and the TextField + focus
  /// inside) survives the tree swap when `_isInSearchMode` flips. Without
  /// this, typing the first character unmounts the tabbed tree, the
  /// SearchBar element is destroyed, and the keyboard drops.
  final _searchBarKey = GlobalKey();
  Timer? _debounce;

  /// Whether the search bar has active text.
  bool get isSearchActive => _searchController.text.trim().isNotEmpty;

  /// Clear the search and return to the browse grid.
  void clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
    _focusNode.unfocus();
    _revealDriver.resetToShown();
  }

  /// Give focus to the search bar (used by the app-icon "Search" shortcut).
  void focusSearch() {
    if (!mounted) return;
    _revealDriver.resetToShown();
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
  List<String> _searchNarratorResults = [];
  List<String> _searchTagResults = [];
  List<String> _searchGenreResults = [];
  List<Map<String, dynamic>> _searchEpisodeResults = [];
  List<String>? _allNarratorsCache;
  String? _allNarratorsCacheLibraryId;
  bool _isSearching = false;
  bool _hasSearched = false;
  bool get _isInSearchMode => _searchController.text.trim().isNotEmpty;

  // ── Batch selection (books tab and authors tab) ──
  bool _selectionMode = false;
  bool _batchActionBusy = false;
  bool _matchingAuthors = false;
  String? _matchingAuthorId;
  int _authorMatchPosition = 0;
  int _authorMatchTotal = 0;
  final Set<String> _selectedItemIds = {};
  int? _lastSelectedVisibleIndex;

  // ── Tab state ──
  TabController? _tabController;
  int _currentTab = 0;
  // Podcast libraries: 0 = Shows grid, 1 = Episodes feed.
  int _podcastView = 0;

  // ── Browse state (Library tab) ──
  bool _collapseSeries = false;
  LibrarySort _sort = LibrarySort.recentlyAdded;
  bool _sortAsc = false; // false = desc (newest/longest first), true = asc
  LibraryFilter _filter = LibraryFilter.none;
  String? _genreFilter;
  String? _tagFilter;
  String? _filterValue;
  String? _filterValueLabel;
  MissingMetadataField? _missingMetadataFilter;

  /// Set to true the first time the user (or a chip tap via
  /// AppShell.openLibraryWith*FilterGlobal) explicitly changes the filter.
  /// `_restoreSortFilter` checks this before overwriting filter state from
  /// SharedPreferences — fixes the cold-start race where a tag/genre chip
  /// tap on a freshly opened app got clobbered by the prefs restore that
  /// runs in postFrame right after the library widget mounts.
  bool _filterOverriddenByUser = false;
  List<String> _availableGenres = [];
  List<String> _availableTags = [];
  List<Map<String, String>> _availableSeriesFilters = [];
  List<Map<String, String>> _availableAuthorFilters = [];
  List<String> _availableNarrators = [];
  List<String> _availableLanguages = [];
  List<String> _availablePublishers = [];
  List<String> _availablePublishedDecades = [];
  bool _hideEbookOnly = false;
  final List<Map<String, dynamic>> _items = [];

  // ── Collections / Playlists (Library tab) ──
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _playlists = [];
  // Keyed on "<accountScope>|<libraryId>" so it reloads on a library OR account
  // switch - playlists are per-user, so switching accounts must drop the old
  // user's lists.
  String? _listsLoadedKey;
  Future<void>? _listsLoadFuture;
  String? _listsLoadingKey;
  // Lists tab (collections/playlists). The tab is the 5th pill, only shown
  // when there's at least one list; re-tapping the active Lists pill flips
  // between collections and playlists.
  LibrarySort _listsSort = LibrarySort.alphabetical;
  bool _listsSortAsc = true;
  final _listsScrollController = ScrollController();
  // Remembered per library (persisted): once a library is known to have lists,
  // keep the Lists pill shown immediately on later opens and don't let it blink
  // out while the lists reload. Cleared only when a load confirms zero lists.
  bool _cachedHasLists = false;
  bool get _showLists =>
      _tabController != null &&
      (_collections.isNotEmpty || _playlists.isNotEmpty || _cachedHasLists);

  String _listsPresentKey(String libId) => 'lists_present_$libId';

  bool _isLoadingPage = false;
  bool _hasMore = true;
  // Tracks the offline state so the grid reloads when it flips (offline shows
  // only downloads; back online shows the full library again).
  bool _wasOffline = false;
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
  SeriesFilter _seriesFilter = SeriesFilter.none;
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
  /// Continuous 0..1 reveal: 1 = header + nav fully visible, 0 = both hidden.
  /// Drives the header SizeTransition, the floating tab bar, and the AppShell
  /// bottom nav in lockstep.
  late final ScrollRevealDriver _revealDriver = ScrollRevealDriver(vsync: this);
  ValueListenable<double> get barsRevealNotifier => _revealDriver.notifier;
  void resetReveal() => _revealDriver.resetToShown();

  /// Called externally (e.g. from AppShell) to focus the search field.
  void requestSearchFocus() {
    _focusNode.requestFocus();
  }

  String? _lastLibraryId;

  @override
  void initState() {
    super.initState();
    _wasOffline = context.read<LibraryProvider>().isOffline;
    // Reveal driver is fed by NotificationListener at the screen level —
    // works across multiple per-tab scroll controllers in the IndexedStack
    // without needing to re-attach on every tab switch.
    // Load initial page once the library is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTabController();
      _tryInitialLoad();
    });
    // Tell AppShell we're alive so its bottom-nav listener can attach now
    // rather than waiting on a postFrame retry that may never re-fire.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppShell.notifyScreenReady(1);
    });
    _loadRmabConfigured();
    SocketService().addAuthorsChangedListener(_onAuthorsChanged);
  }

  // Live-refresh the authors tab when authors change on the server (edits,
  // quick-match, books moving around). Silent swap - no spinner flag - so an
  // open tab doesn't flash while it updates.
  Timer? _authorsRefreshDebounce;
  void _onAuthorsChanged() {
    if (!mounted || !_authorsLoaded) return;
    _authorsRefreshDebounce?.cancel();
    _authorsRefreshDebounce = Timer(const Duration(seconds: 2), () async {
      if (!mounted || !_authorsLoaded) return;
      final lib = context.read<LibraryProvider>();
      final api = context.read<AuthProvider>().apiService;
      if (api == null || lib.selectedLibraryId == null || lib.isOffline) return;
      final authors = await api.getLibraryAuthors(lib.selectedLibraryId!);
      if (!mounted) return;
      setState(() {
        _authors = authors;
        _sortAuthors();
      });
    });
  }

  Future<void> _loadRmabConfigured() async {
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    if (!mounted) return;
    final next = (base ?? '').isNotEmpty && (token ?? '').isNotEmpty;
    debugPrint('[RMAB] library: _rmabConfigured=$next');
    if (next != _rmabConfigured) {
      setState(() => _rmabConfigured = next);
    }
  }

  void _initTabController() {
    final lib = context.read<LibraryProvider>();
    if (!lib.isPodcastLibrary) {
      // 5 = Library/Series/Authors/Narrators/Lists. The Lists pill is only
      // shown when lists exist; since the views are an IndexedStack (no swipe),
      // an unreachable 5th slot is harmless.
      _tabController = TabController(length: 5, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    final newTab = _tabController!.index;
    if (newTab == _currentTab) return;
    setState(() => _currentTab = newTab);
    // Reset reveal so the SliverAppBar is fully visible after a tab switch.
    _revealDriver.resetToShown();
    PlayerSettings.setLibraryTab(newTab);
    // Lazy load data for the tab
    if (newTab == 1 && _seriesItems.isEmpty && !_isLoadingSeriesPage) {
      _loadSeriesPage();
    } else if (newTab == 2 && !_authorsLoaded && !_isLoadingAuthors) {
      _loadAuthors();
    } else if (newTab == 3 && !_narratorsLoaded && !_isLoadingNarrators) {
      _loadNarrators();
    } else if (newTab == 4) {
      _loadLists();
    }
  }

  void _onLibraryProviderChanged() {
    if (!mounted) return;
    final lib = context.read<LibraryProvider>();
    // Reload collections/playlists when the library OR account changes; keyed
    // on account scope + libraryId inside _loadLists, so this is a no-op when
    // nothing relevant changed.
    _loadLists();
    if (lib.selectedLibraryId != _lastLibraryId &&
        lib.selectedLibraryId != null) {
      _lastLibraryId = lib.selectedLibraryId;
      _loadGeneration++;
      // Cover shape can differ per library.
      PlayerSettings.getRectangleCoversFor(lib.selectedLibraryId).then((v) {
        if (mounted && v != _rectangleCovers)
          setState(() => _rectangleCovers = v);
      });

      // Rebuild tab controller if library type changed
      final needsTabs = !lib.isPodcastLibrary;
      final hasTabs = _tabController != null;
      if (needsTabs != hasTabs) {
        _tabController?.removeListener(_onTabChanged);
        _tabController?.dispose();
        if (needsTabs) {
          _tabController = TabController(length: 5, vsync: this);
          _tabController!.addListener(_onTabChanged);
        } else {
          _tabController = null;
        }
        _currentTab = 0;
      }

      setState(() {
        _podcastView = 0;
        _items.clear();
        _page = 0;
        _hasMore = true;
        _isLoadingPage = false;
        _availableGenres = [];
        _availableTags = [];
        _availableSeriesFilters = [];
        _availableAuthorFilters = [];
        _availableNarrators = [];
        _availableLanguages = [];
        _availablePublishers = [];
        _availablePublishedDecades = [];
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
        // Different library: drop the old Lists state; _fetchLists re-seeds the
        // pill from the new library's remembered flag.
        _cachedHasLists = false;
        _allNarratorsCache = null;
        _allNarratorsCacheLibraryId = null;
        _searchNarratorResults = [];
        // New library, so any prior chip-driven override no longer
        // applies — let `_restoreSortFilter` set the new library's
        // saved filter freely.
        _filterOverriddenByUser = false;
      });
      _revealDriver.resetToShown();
      // Restore sort/filter for the new library type, then load
      _restoreSortFilter().then((_) {
        if (mounted) _loadPage();
      });
      _loadFilterData();
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
    PlayerSettings.getRectangleCoversFor(lib.selectedLibraryId).then((v) {
      if (mounted) setState(() => _rectangleCovers = v);
    });
    _restoreSortFilter().then((_) {
      if (!mounted) return;
      _lastLibraryId = lib.selectedLibraryId;
      lib.addListener(_onLibraryProviderChanged);
      if (lib.selectedLibraryId != null) {
        _loadPage();
        _loadFilterData();
        _loadLists();
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
      PlayerSettings.getLibraryTagFilter(),
      PlayerSettings.getLibrarySeriesFilter(),
      PlayerSettings.getListsSort(),
      PlayerSettings.getListsSortAsc(),
      PlayerSettings.getLibraryMissingMetadataFilter(),
      PlayerSettings.getLibraryFilterValue(),
      PlayerSettings.getLibraryFilterValueLabel(),
      PlayerSettings.getPodcastFilter(),
      PlayerSettings.getPodcastGenreFilter(),
      PlayerSettings.getPodcastTagFilter(),
      PlayerSettings.getPodcastFilterValue(),
      PlayerSettings.getPodcastFilterValueLabel(),
      PlayerSettings.getPodcastView(),
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
    final tagFilter = results[13] as String;
    final seriesFilterName = results[14] as String;
    final listsSortName = results[15] as String;
    final listsSortAsc = results[16] as bool;
    final missingMetadataFilterName = results[17] as String;
    final libraryFilterValue = results[18] as String;
    final libraryFilterValueLabel = results[19] as String;
    final podcastFilterName = results[20] as String;
    final podcastGenreFilter = results[21] as String;
    final podcastTagFilter = results[22] as String;
    final podcastFilterValue = results[23] as String;
    final podcastFilterValueLabel = results[24] as String;
    final lib = context.read<LibraryProvider>();
    final isPodcast = lib.isPodcastLibrary;
    // Read the remembered "has lists" flag so the Lists tab (and its pill) can
    // be restored immediately on cold start, before the lists finish loading.
    final libId = lib.selectedLibraryId;
    final hasListsRemembered = libId != null
        ? (await ScopedPrefs.getBool(_listsPresentKey(libId)) ?? false)
        : false;
    if (!mounted) return;
    setState(() {
      // Book library sort/filter
      _sort = LibrarySort.values.firstWhere(
        (s) => s.name == sortName,
        orElse: () => LibrarySort.recentlyAdded,
      );
      _sortAsc = sortAsc;
      if (_sort == LibrarySort.random) _randomSeed = Random().nextInt(100000);
      // Don't restore filter from prefs if the user (typically via a
      // chip tap from an open detail sheet) already set one during this
      // session — that race would otherwise undo their selection on cold
      // start when the library widget is mounting for the first time.
      if (!_filterOverriddenByUser) {
        final restoredFilterName = isPodcast ? podcastFilterName : filterName;
        _filter = LibraryFilter.values.firstWhere(
          (f) => f.name == restoredFilterName,
          orElse: () => LibraryFilter.none,
        );
        if (!libraryFilterSupportsMediaType(
          _filter,
          isPodcast: isPodcast,
        )) {
          _filter = LibraryFilter.none;
        }
        final restoredGenre = isPodcast ? podcastGenreFilter : genreFilter;
        final restoredTag = isPodcast ? podcastTagFilter : tagFilter;
        final restoredValue = isPodcast
            ? podcastFilterValue
            : libraryFilterValue;
        final restoredValueLabel = isPodcast
            ? podcastFilterValueLabel
            : libraryFilterValueLabel;
        _genreFilter = _filter == LibraryFilter.genre && restoredGenre.isNotEmpty
            ? restoredGenre
            : null;
        _tagFilter = _filter == LibraryFilter.tag && restoredTag.isNotEmpty
            ? restoredTag
            : null;
        _filterValue = libraryFilterRequiresValue(_filter) &&
                restoredValue.isNotEmpty
            ? restoredValue
            : null;
        _filterValueLabel = _filterValue == null
            ? null
            : (restoredValueLabel.isNotEmpty
                  ? restoredValueLabel
                  : _filterValue);
        _missingMetadataFilter = isPodcast
            ? null
            : MissingMetadataField.values
                  .where((field) => field.name == missingMetadataFilterName)
                  .firstOrNull;
        if (_filter == LibraryFilter.missingMetadata &&
            _missingMetadataFilter == null) {
          _filter = LibraryFilter.none;
        }
        if (libraryFilterRequiresValue(_filter) && _filterValue == null) {
          _filter = LibraryFilter.none;
        }
        if (!isPodcast &&
            _sort == LibrarySort.sequence &&
            !(_filter == LibraryFilter.series &&
                _filterValue != null &&
                _filterValue != 'no-series')) {
          _sort = LibrarySort.alphabetical;
          _sortAsc = true;
        }
      }
      _seriesSort = LibrarySort.values.firstWhere(
        (s) => s.name == seriesSortName,
        orElse: () => LibrarySort.alphabetical,
      );
      _seriesSortAsc = seriesSortAsc;
      _seriesFilter = SeriesFilter.values.firstWhere(
        (f) => f.name == seriesFilterName,
        orElse: () => SeriesFilter.none,
      );
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
      _listsSort = LibrarySort.values.firstWhere(
        (s) => s.name == listsSortName,
        orElse: () => LibrarySort.alphabetical,
      );
      _listsSortAsc = listsSortAsc;
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
      }
      // Seed the Lists pill from the remembered flag so it (and the restored
      // Lists tab) show right away, before the lists load.
      if (hasListsRemembered) _cachedHasLists = true;
      // Restore last active tab (only for book libraries with tabs). The Lists
      // tab (4) is only restorable if the library is known to have lists.
      final maxRestorableTab = hasListsRemembered ? 4 : 3;
      if (!isPodcast && savedTab > 0 && savedTab <= maxRestorableTab) {
        _currentTab = savedTab;
        _tabController?.animateTo(savedTab);
      }
      // Podcast libraries: restore the Shows/Episodes pill the same way
      // book libraries restore their tab.
      if (isPodcast) {
        _podcastView = (results.last as int) == 1 ? 1 : 0;
      }
    });
    // Lazy load data for the restored tab
    if (!isPodcast &&
        savedTab == 1 &&
        _seriesItems.isEmpty &&
        !_isLoadingSeriesPage) {
      _loadSeriesPage();
    } else if (!isPodcast &&
        savedTab == 2 &&
        !_authorsLoaded &&
        !_isLoadingAuthors) {
      _loadAuthors();
    } else if (!isPodcast &&
        savedTab == 3 &&
        !_narratorsLoaded &&
        !_isLoadingNarrators) {
      _loadNarrators();
    }
  }

  void _onSettingsChanged() {
    Future.wait([
      PlayerSettings.getHideEbookOnly(),
      PlayerSettings.getCollapseSeries(),
      PlayerSettings.getRectangleCoversFor(
        context.read<LibraryProvider>().selectedLibraryId,
      ),
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
      _loadFilterData();
    }
  }

  Future<void> _loadFilterData() async {
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    if (api == null || lib.selectedLibraryId == null) return;
    final filterData = await api.getLibraryFilterData(lib.selectedLibraryId!);
    if (filterData != null && mounted) {
      final genres = filterData['genres'] as List<dynamic>? ?? [];
      final tags = filterData['tags'] as List<dynamic>? ?? [];
      final series = filterData['series'] as List<dynamic>? ?? [];
      final authors = filterData['authors'] as List<dynamic>? ?? [];
      final narrators = filterData['narrators'] as List<dynamic>? ?? [];
      final languages = filterData['languages'] as List<dynamic>? ?? [];
      final publishers = filterData['publishers'] as List<dynamic>? ?? [];
      final publishedDecades =
          filterData['publishedDecades'] as List<dynamic>? ?? [];
      String unwrap(dynamic v) =>
          v is Map ? (v['name'] as String? ?? '') : v.toString();
      setState(() {
        _availableGenres =
            genres.map(unwrap).where((g) => g.isNotEmpty).toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _availableTags = tags.map(unwrap).where((t) => t.isNotEmpty).toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _availableSeriesFilters = series
            .whereType<Map>()
            .map(
              (value) => {
                'id': value['id']?.toString() ?? '',
                'name': value['name']?.toString() ?? '',
              },
            )
            .where(
              (value) =>
                  value['id']!.isNotEmpty && value['name']!.isNotEmpty,
            )
            .toList()
          ..sort(
            (a, b) => a['name']!.toLowerCase().compareTo(
              b['name']!.toLowerCase(),
            ),
          );
        _availableAuthorFilters = authors
            .whereType<Map>()
            .map(
              (value) => {
                'id': value['id']?.toString() ?? '',
                'name': value['name']?.toString() ?? '',
              },
            )
            .where(
              (value) =>
                  value['id']!.isNotEmpty && value['name']!.isNotEmpty,
            )
            .toList()
          ..sort(
            (a, b) => a['name']!.toLowerCase().compareTo(
              b['name']!.toLowerCase(),
            ),
          );
        _availableNarrators = narrators
            .map(unwrap)
            .where((value) => value.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _availableLanguages = languages
            .map(unwrap)
            .where((value) => value.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _availablePublishers = publishers
            .map(unwrap)
            .where((value) => value.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _availablePublishedDecades = publishedDecades
            .map(unwrap)
            .where((value) => value.isNotEmpty)
            .toList()
          ..sort();
      });
    }
  }

  @override
  void dispose() {
    SocketService().removeAuthorsChangedListener(_onAuthorsChanged);
    _authorsRefreshDebounce?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _revealDriver.dispose();
    _scrollController.dispose();
    _seriesScrollController.dispose();
    _authorsScrollController.dispose();
    _narratorsScrollController.dispose();
    _listsScrollController.dispose();
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

  // Pagination is now triggered by the NotificationListener inside each tab
  // widget, which calls back into _loadPage / _loadSeriesPage when the user
  // approaches the bottom of the visible scroll view.

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
        sort = 'addedAt';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.alphabetical:
        sort = 'media.metadata.title';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.authorName:
        sort = lib.isPodcastLibrary
            ? 'media.metadata.author'
            : 'media.metadata.authorNameLF';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.authorFirstLast:
        sort = 'media.metadata.authorName';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.publishedYear:
        sort = 'media.metadata.publishedYear';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.duration:
      case LibrarySort.totalDuration:
        sort = 'media.duration';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.fileSize:
        sort = 'size';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.lastUpdated:
        sort = 'updatedAt';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.fileCreated:
        sort = 'birthtimeMs';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.lastModified:
        sort = 'mtimeMs';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.progress:
        sort = 'progress';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.dateStarted:
        sort = 'progress.createdAt';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.dateFinished:
        sort = 'progress.finishedAt';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.episodeCount:
        sort = 'media.numTracks';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.sequence:
        sort = 'sequence';
        desc = _sortAsc ? 0 : 1;
        break;
      case LibrarySort.random:
        sort = 'addedAt';
        desc = 1;
        break;
    }

    final filter = buildLibraryFilterQuery(
      _filter,
      genre: _genreFilter,
      tag: _tagFilter,
      filterValue: _filterValue,
      missingMetadata: _missingMetadataFilter,
    );
    // Downloaded filter is client-side — handled after loading

    final filterDownloaded = _filter == LibraryFilter.downloaded;
    final filterSubscribed = _filter == LibraryFilter.subscribed;
    final useClientFilter = filterDownloaded || filterSubscribed;
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
          collapseSeries:
              _collapseSeries && !useClientFilter && !lib.isPodcastLibrary,
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
              final coverPath =
                  (r['media'] as Map<String, dynamic>?)?['coverPath']
                      as String?;
              lib.registerHasCover(
                id,
                coverPath != null && coverPath.isNotEmpty,
              );
            }
            if (filterDownloaded && !DownloadService().isDownloaded(id ?? ''))
              continue;
            if (filterSubscribed && !lib.isPodcastSubscribed(id ?? ''))
              continue;
            if (_hideEbookOnly && PlayerSettings.isEbookOnly(r)) continue;
            _items.add(r);
          }
        }
        fetchPage++;
        if (fetchPage * fetchLimit >= total) break;
      }
      if (mounted && gen == _loadGeneration) {
        setState(() {
          _totalItems = useClientFilter ? _items.length : total;
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
              if (id != null && ts != null)
                lib.registerUpdatedAt(id, ts.toInt());
              if (id != null) {
                final coverPath =
                    (r['media'] as Map<String, dynamic>?)?['coverPath']
                        as String?;
                lib.registerHasCover(
                  id,
                  coverPath != null && coverPath.isNotEmpty,
                );
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
          debugPrint(
            '[LibPage] page=${_page - 1} results=${results.length} pageSize=$_pageSize filtered=${_items.length} total=$total hideEbook=$_hideEbookOnly hasMore=$_hasMore',
          );
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
    final selectedId = lib.selectedLibraryId;
    final downloads = DownloadService().downloadedItems.where((dl) {
      final libraryId = dl.libraryId;
      if (libraryId != null && libraryId.isNotEmpty && selectedId != null) {
        return libraryId == selectedId;
      }
      return (dl.itemId.length > 36) == isPodcast;
    }).toList();

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
  /// Whether [series] matches [filter] based on per-book progress aggregated
  /// from [LibraryProvider]. Used by the series tab's client-side filter
  /// (the ABS server doesn't support series-level progress filters).
  bool _seriesMatchesFilter(
    Map<String, dynamic> series,
    SeriesFilter filter,
    LibraryProvider lib,
  ) {
    if (filter == SeriesFilter.none) return true;
    final books = series['books'] as List<dynamic>? ?? const [];
    if (books.isEmpty) return false;

    var finishedCount = 0;
    var startedCount = 0;
    for (final b in books) {
      if (b is! Map<String, dynamic>) continue;
      final id = b['id'] as String?;
      if (id == null || id.isEmpty) continue;
      final pd = lib.getProgressData(id);
      final isFinished = pd?['isFinished'] == true;
      final progress = lib.getProgress(id);
      if (isFinished) {
        finishedCount++;
        startedCount++;
      } else if (progress > 0.001) {
        startedCount++;
      }
    }

    return seriesProgressMatchesFilter(
      filter,
      bookCount: books.length,
      startedCount: startedCount,
      finishedCount: finishedCount,
    );
  }

  Future<void> _loadSeriesPage() async {
    if (_isLoadingSeriesPage) return;
    if (_seriesFilter == SeriesFilter.none && !_hasMoreSeries) return;
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
        sort = 'name';
        break;
      case LibrarySort.recentlyAdded:
        sort = 'addedAt';
        break;
      case LibrarySort.totalDuration:
        sort = 'numBooks';
        break;
      default:
        sort = 'name';
        break;
    }

    // ── Filtered mode: paginate the same way as the unfiltered path, but
    // apply the client-side filter to each page and only append matches.
    // hasMore is driven by the unfiltered server total so pagination stops
    // when we've actually exhausted the source. Auto-refire when matches
    // are sparse so the user doesn't see an empty list on libraries where
    // the filter only hits a few series per page.
    if (_seriesFilter != SeriesFilter.none) {
      const filteredPageSize = 100;
      final result = await api.getLibrarySeries(
        lib.selectedLibraryId!,
        page: _seriesPage,
        limit: filteredPageSize,
        sort: sort,
        desc: _seriesSortAsc ? 0 : 1,
      );
      if (!mounted) return;
      if (result == null) {
        setState(() => _isLoadingSeriesPage = false);
        return;
      }
      final results = (result['results'] as List<dynamic>?) ?? [];
      final unfilteredTotal = (result['total'] as int?) ?? 0;
      final matching = results
          .whereType<Map<String, dynamic>>()
          .where((s) => _seriesMatchesFilter(s, _seriesFilter, lib))
          .toList();
      setState(() {
        _seriesItems.addAll(matching);
        _seriesPage++;
        // hasMore = there's still source data left, regardless of how many
        // pages matched.
        _hasMoreSeries =
            (_seriesPage * filteredPageSize) < unfilteredTotal &&
            results.isNotEmpty;
        // The visible count is what the user sees; track it for the InfoRow.
        _totalSeries = _seriesItems.length;
        _isLoadingSeriesPage = false;
      });
      // Filter sparsity guard: if the user just activated this filter and
      // we don't have enough visible results to fill the screen, keep
      // pulling pages until we either have ~20 matches or run out.
      if (_hasMoreSeries && _seriesItems.length < 20) {
        Future.microtask(_loadSeriesPage);
      }
      return;
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
        lib.setSeriesTabCache(
          cacheKey,
          List<Map<String, dynamic>>.from(_seriesItems),
          total,
        );
      }
    } else if (mounted) {
      setState(() => _isLoadingSeriesPage = false);
    }
  }

  Future<void> _refreshSeriesInBackground(
    ApiService api,
    LibraryProvider lib,
    String sort,
    String cacheKey,
  ) async {
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
      setState(() {
        _isLoadingAuthors = false;
        _authorsLoaded = true;
      });
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
        return _authorSortAsc
            ? aCount.compareTo(bCount)
            : bCount.compareTo(aCount);
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
      setState(() {
        _isLoadingNarrators = false;
        _narratorsLoaded = true;
      });
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
      return _narratorSortAsc
          ? aLower.compareTo(bLower)
          : bLower.compareTo(aLower);
    });
  }

  // ── Change sort and reload ──
  void _changeSort(LibrarySort newSort) {
    if (_currentTab == 1) {
      _changeSeriesSort(newSort);
      return;
    }
    if (_currentTab == 2) {
      _changeAuthorSort(newSort);
      return;
    }
    if (_currentTab == 3) {
      _changeNarratorSort(newSort);
      return;
    }
    if (_currentTab == 4) {
      _changeListsSort(newSort);
      return;
    }

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
      _sortAsc =
          newSort == LibrarySort.alphabetical ||
          newSort == LibrarySort.authorName ||
          newSort == LibrarySort.authorFirstLast ||
          newSort == LibrarySort.duration ||
          newSort == LibrarySort.sequence;
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
      setState(() {
        _seriesSortAsc = !_seriesSortAsc;
      });
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
      setState(() {
        _authorSortAsc = !_authorSortAsc;
      });
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
      setState(() {
        _narratorSortAsc = !_narratorSortAsc;
      });
    } else {
      setState(() {
        _narratorSort = newSort;
        _narratorSortAsc = true;
      });
    }
    PlayerSettings.setNarratorSort(_narratorSort.name);
    PlayerSettings.setNarratorSortAsc(_narratorSortAsc);
    setState(() => _sortNarrators());
    if (_narratorsScrollController.hasClients)
      _narratorsScrollController.jumpTo(0);
  }

  void _changeListsSort(LibrarySort newSort) {
    if (newSort == _listsSort) {
      setState(() => _listsSortAsc = !_listsSortAsc);
    } else {
      setState(() {
        _listsSort = newSort;
        // A-Z ascending; date-added and item-count default to descending.
        _listsSortAsc = newSort == LibrarySort.alphabetical;
      });
    }
    PlayerSettings.setListsSort(_listsSort.name);
    PlayerSettings.setListsSortAsc(_listsSortAsc);
    if (_listsScrollController.hasClients) _listsScrollController.jumpTo(0);
  }

  /// All collections and playlists merged into one list, tagged with
  /// `_isPlaylist`, sorted by the current Lists sort.
  List<Map<String, dynamic>> _sortedLists() {
    final entries = <Map<String, dynamic>>[
      for (final c in _collections) {...c, '_isPlaylist': false},
      for (final p in _playlists) {...p, '_isPlaylist': true},
    ];
    int countOf(Map<String, dynamic> e) => e['_isPlaylist'] == true
        ? (e['items'] as List<dynamic>?)?.length ?? 0
        : (e['books'] as List<dynamic>?)?.length ?? 0;
    int asc(Map<String, dynamic> a, Map<String, dynamic> b) {
      switch (_listsSort) {
        case LibrarySort.recentlyAdded:
          final ca = (a['createdAt'] as num?)?.toDouble() ?? 0;
          final cb = (b['createdAt'] as num?)?.toDouble() ?? 0;
          return ca.compareTo(cb);
        case LibrarySort.totalDuration:
          return countOf(a).compareTo(countOf(b));
        default:
          return (a['name'] as String? ?? '').toLowerCase().compareTo(
            (b['name'] as String? ?? '').toLowerCase(),
          );
      }
    }

    entries.sort((a, b) => _listsSortAsc ? asc(a, b) : asc(b, a));
    return entries;
  }

  /// Switch to the Books sub-tab (if needed) and apply a tag filter. Used by
  /// AppShell.openLibraryWithTagFilterGlobal so a tag chip tapped from the
  /// book detail sheet drops the user into the matching library view.
  void applyTagFilter(String tag) {
    if (_currentTab != 0 && _tabController != null) {
      _tabController!.animateTo(0);
    }
    _changeFilter(LibraryFilter.tag, tag: tag);
  }

  /// Switch to the Books sub-tab (if needed) and apply a genre filter.
  /// Mirrors [applyTagFilter] for genre chips tapped from book detail.
  void applyGenreFilter(String genre) {
    if (_currentTab != 0 && _tabController != null) {
      _tabController!.animateTo(0);
    }
    _changeFilter(LibraryFilter.genre, genre: genre);
  }

  /// Change the Series tab's client-side progress filter and reload.
  void _changeSeriesFilter(SeriesFilter newFilter) {
    final effective = newFilter == _seriesFilter
        ? SeriesFilter.none
        : newFilter;
    if (effective == _seriesFilter) return;
    setState(() {
      _seriesFilter = effective;
      _seriesItems.clear();
      _seriesPage = 0;
      _hasMoreSeries = true;
      _isLoadingSeriesPage = false;
    });
    PlayerSettings.setLibrarySeriesFilter(_seriesFilter.name);
    if (_seriesScrollController.hasClients) _seriesScrollController.jumpTo(0);
    _loadSeriesPage();
  }

  // ── Change filter and reload ──
  void _changeFilter(
    LibraryFilter newFilter, {
    String? genre,
    String? tag,
    String? filterValue,
    String? filterValueLabel,
    MissingMetadataField? missingMetadata,
  }) {
    final sameAsCurrent =
        newFilter == _filter &&
        genre == _genreFilter &&
        tag == _tagFilter &&
        filterValue == _filterValue &&
        missingMetadata == _missingMetadataFilter;
    final effective = sameAsCurrent ? LibraryFilter.none : newFilter;
    if (effective == _filter &&
        genre == _genreFilter &&
        tag == _tagFilter &&
        filterValue == _filterValue &&
        missingMetadata == _missingMetadataFilter) {
      return;
    }
    final isPodcast = context.read<LibraryProvider>().isPodcastLibrary;
    final resetSequenceSort =
        !isPodcast &&
        _sort == LibrarySort.sequence &&
        !(effective == LibraryFilter.series &&
            filterValue != null &&
            filterValue != 'no-series');
    _loadGeneration++;
    setState(() {
      _filter = effective;
      _genreFilter = effective == LibraryFilter.genre ? genre : null;
      _tagFilter = effective == LibraryFilter.tag ? tag : null;
      _filterValue = libraryFilterRequiresValue(effective)
          ? filterValue
          : null;
      _filterValueLabel = _filterValue == null
          ? null
          : (filterValueLabel ?? filterValue);
      _missingMetadataFilter = effective == LibraryFilter.missingMetadata
          ? missingMetadata
          : null;
      if (resetSequenceSort) {
        _sort = LibrarySort.alphabetical;
        _sortAsc = true;
      }
      _items.clear();
      _page = 0;
      _hasMore = true;
      _isLoadingPage = false;
      _filterOverriddenByUser = true;
    });
    if (isPodcast) {
      PlayerSettings.setPodcastFilter(_filter.name);
      PlayerSettings.setPodcastGenreFilter(_genreFilter);
      PlayerSettings.setPodcastTagFilter(_tagFilter);
      PlayerSettings.setPodcastFilterValue(_filterValue);
      PlayerSettings.setPodcastFilterValueLabel(_filterValueLabel);
    } else {
      if (resetSequenceSort) {
        PlayerSettings.setLibrarySort(_sort.name);
        PlayerSettings.setLibrarySortAsc(_sortAsc);
      }
      PlayerSettings.setLibraryFilter(_filter.name);
      PlayerSettings.setLibraryGenreFilter(_genreFilter);
      PlayerSettings.setLibraryTagFilter(_tagFilter);
      PlayerSettings.setLibraryFilterValue(_filterValue);
      PlayerSettings.setLibraryFilterValueLabel(_filterValueLabel);
      PlayerSettings.setLibraryMissingMetadataFilter(
        _missingMetadataFilter?.name,
      );
    }
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _loadPage();
  }

  void _applyTagFilter(String tag) {
    clearSearch();
    _tabController?.animateTo(0);
    _changeFilter(LibraryFilter.tag, tag: tag);
  }

  void _applyGenreFilter(String genre) {
    clearSearch();
    _tabController?.animateTo(0);
    _changeFilter(LibraryFilter.genre, genre: genre);
  }

  // ── Collections / Playlists ──

  /// Loads the current library+account's collections/playlists. Returns the
  /// in-flight load so callers (the sort sheet) can await it - that's what
  /// makes the Lists tab show on first open instead of after a reopen.
  Future<void> _loadLists() {
    final lib = context.read<LibraryProvider>();
    final api = context.read<AuthProvider>().apiService;
    final libId = lib.selectedLibraryId;
    if (api == null || libId == null) return Future.value();
    final key = '${UserAccountService().activeScopeKey}|$libId';
    if (_listsLoadingKey == key && _listsLoadFuture != null)
      return _listsLoadFuture!;
    if (_listsLoadedKey == key) return Future.value();
    _listsLoadingKey = key;
    final f = _fetchLists(key, api, libId);
    _listsLoadFuture = f;
    return f;
  }

  Future<void> _fetchLists(String key, ApiService api, String libId) async {
    // Seed the Lists pill from the remembered flag so it shows right away (and
    // doesn't blink out while reloading) before the network confirms.
    final remembered =
        await ScopedPrefs.getBool(_listsPresentKey(libId)) ?? false;
    if (!mounted || _listsLoadingKey != key) return;
    // New key (library/account changed) or first load: drop the previous lists
    // before fetching the new ones.
    setState(() {
      _collections = [];
      _playlists = [];
      _cachedHasLists = remembered;
    });
    try {
      final results = await Future.wait([
        api.getLibraryCollections(libId),
        api.getLibraryPlaylists(libId),
      ]);
      if (!mounted || _listsLoadingKey != key) return;
      final cols = results[0].whereType<Map<String, dynamic>>().toList();
      final pls = results[1].whereType<Map<String, dynamic>>().toList();
      final hasLists = cols.isNotEmpty || pls.isNotEmpty;
      setState(() {
        _collections = cols;
        _playlists = pls;
        _listsLoadedKey = key;
        _cachedHasLists = hasLists;
        // Fall back to Library if the Lists tab is open but has nothing.
        if (_currentTab == 4 && !_showLists) {
          _currentTab = 0;
          _tabController?.animateTo(0);
        }
      });
      // Remember for next time so the pill is instant, and forget once a load
      // confirms the library genuinely has none.
      await ScopedPrefs.setBool(_listsPresentKey(libId), hasLists);
    } finally {
      if (_listsLoadingKey == key) _listsLoadFuture = null;
    }
  }

  Future<void> _refreshLists() async {
    _listsLoadedKey = null;
    await _loadLists();
  }

  // ── Search ──
  void _openPodcastLookup() {
    final lib = context.read<LibraryProvider>();
    final library = lib.selectedLibrary;
    final libraryId = lib.selectedLibraryId;
    if (library == null || libraryId == null) return;

    final folders = library['folders'];
    final firstFolder = folders is List && folders.isNotEmpty
        ? folders.first
        : null;
    final folderId = firstFolder is Map
        ? firstFolder['id'] as String? ?? ''
        : '';

    _focusNode.unfocus();
    showAddPodcastSheet(
      context,
      libraryId: libraryId,
      folderId: folderId,
      initialQuery: _searchController.text.trim(),
      onAdded: _onPodcastAdded,
    );
  }

  void _onPodcastAdded() {
    unawaited(_refreshAll());
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      unawaited(_performSearch(query));
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    // Always show bars when entering/exiting search
    _revealDriver.resetToShown();
    if (query.trim().isEmpty) {
      setState(() {
        _searchBookResults = [];
        _searchSeriesResults = [];
        _searchAuthorResults = [];
        _searchNarratorResults = [];
        _searchTagResults = [];
        _searchGenreResults = [];
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
              final item =
                  r['libraryItem'] as Map<String, dynamic>? ??
                  r as Map<String, dynamic>;
              return !PlayerSettings.isEbookOnly(item);
            }).toList();
          }
        }
        _searchSeriesResults = (result['series'] as List<dynamic>?) ?? [];
        _searchAuthorResults = (result['authors'] as List<dynamic>?) ?? [];
        if (!isPodcast) {
          final q = query.toLowerCase();
          _searchTagResults = _availableTags
              .where((t) => t.toLowerCase().contains(q))
              .toList();
          _searchGenreResults = _availableGenres
              .where((g) => g.toLowerCase().contains(q))
              .toList();
        } else {
          _searchTagResults = [];
          _searchGenreResults = [];
        }
        _isSearching = false;
        _hasSearched = true;
      });

      // Client-side narrator filter (ABS search endpoint doesn't return narrators)
      if (!isPodcast) {
        _searchNarrators(query, lib.selectedLibraryId!, api);
      }

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

    // Upgrade book results to the lenient client-side index (out-of-order
    // words, punctuation, typos). The server results above show instantly;
    // this replaces them once the index is built (instant on later searches).
    // Only override when the index actually built, so a failed fetch keeps the
    // server results instead of blanking them.
    if (!isPodcast) {
      final libId = lib.selectedLibraryId!;
      await BookSearchIndex().ensureIndex(api, libId);
      if (mounted &&
          BookSearchIndex().isReady(libId) &&
          _searchController.text.trim() == query) {
        var books = BookSearchIndex()
            .search(libId, query)
            .map(
              (h) => <String, dynamic>{
                'libraryItem': h.item,
                '_titleMatch': h.titleMatch,
              },
            )
            .toList();
        if (_hideEbookOnly) {
          books = books
              .where(
                (r) => !PlayerSettings.isEbookOnly(
                  r['libraryItem'] as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        setState(() => _searchBookResults = books);
      }
    }
  }

  Future<void> _searchNarrators(
    String query,
    String libraryId,
    dynamic api,
  ) async {
    final lowerQuery = query.toLowerCase();
    if (_allNarratorsCache == null ||
        _allNarratorsCacheLibraryId != libraryId) {
      final all = await api.getLibraryNarrators(libraryId);
      _allNarratorsCache = (all as List).cast<String>();
      _allNarratorsCacheLibraryId = libraryId;
    }
    final matches = _allNarratorsCache!
        .where((n) => n.toLowerCase().contains(lowerQuery))
        .toList();
    if (mounted && _searchController.text.trim().toLowerCase() == lowerQuery) {
      setState(() => _searchNarratorResults = matches);
    }
  }

  List<Map<String, dynamic>>? _cachedShowsWithEpisodes;
  String? _cachedShowsLibraryId;

  Future<void> _searchEpisodes(
    String query,
    String libraryId,
    dynamic api,
  ) async {
    final lowerQuery = query.toLowerCase();

    // Cache all shows with episodes so subsequent searches are instant
    if (_cachedShowsWithEpisodes == null ||
        _cachedShowsLibraryId != libraryId) {
      final items = await api.getLibraryItems(libraryId, limit: 100);
      if (items == null || !mounted) return;
      final results = items['results'] as List<dynamic>? ?? [];

      final shows = <Map<String, dynamic>>[];
      final futures = <Future>[];
      for (final r in results) {
        final show = (r['libraryItem'] ?? r) as Map<String, dynamic>;
        final showId = show['id'] as String?;
        if (showId == null) continue;
        futures.add(
          api.getLibraryItem(showId).then((fullItem) {
            if (fullItem != null) shows.add(fullItem);
          }),
        );
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

  String _seriesFilterLabelOf(AppLocalizations l) => switch (_seriesFilter) {
    SeriesFilter.notFinished => l.notFinished,
    SeriesFilter.inProgress => l.inProgress,
    SeriesFilter.finished => l.filterFinished,
    SeriesFilter.notStarted => l.notStarted,
    SeriesFilter.none => '',
  };

  String _filterLabelOf(AppLocalizations l) => switch (_filter) {
    LibraryFilter.notFinished => l.notFinished,
    LibraryFilter.inProgress => l.inProgress,
    LibraryFilter.finished => l.filterFinished,
    LibraryFilter.notStarted => l.notStarted,
    LibraryFilter.downloaded => l.downloaded,
    LibraryFilter.subscribed => l.episodeListSubscribedChip,
    LibraryFilter.inASeries => l.libraryTabSeries,
    LibraryFilter.hasEbook => l.hasEbook,
    LibraryFilter.noEbook => l.noEbook,
    LibraryFilter.hasSupplementaryEbook => l.hasSupplementaryEbook,
    LibraryFilter.noSupplementaryEbook => l.noSupplementaryEbook,
    LibraryFilter.series => _filterValueLabel ?? l.libraryTabSeries,
    LibraryFilter.author => _filterValueLabel ?? l.author,
    LibraryFilter.narrator => _filterValueLabel ?? l.libraryTabNarrators,
    LibraryFilter.language => _filterValueLabel ?? l.languageLabel,
    LibraryFilter.publisher => _filterValueLabel ?? l.publisherLabel,
    LibraryFilter.publishedDecade =>
      _filterValueLabel ?? l.publishedDecade,
    LibraryFilter.noTracks => l.noTracks,
    LibraryFilter.singleTrack => l.singleTrack,
    LibraryFilter.multipleTracks => l.multipleTracks,
    LibraryFilter.abridged => l.abridged,
    LibraryFilter.issues => l.issues,
    LibraryFilter.feedOpen => l.rssFeedOpen,
    LibraryFilter.explicit => l.explicitContent,
    LibraryFilter.missingMetadata => _missingMetadataFilter == null
        ? l.missingMetadata
        : missingMetadataFieldLabel(l, _missingMetadataFilter!),
    LibraryFilter.genre => _genreFilter ?? l.genre,
    LibraryFilter.tag => _tagFilter ?? l.tag,
    LibraryFilter.none => '',
  };

  Future<void> _showSortFilterSheet(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt, {
    int initialTab = 0,
  }) async {
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
      case 4:
        tab = LibraryTab.lists;
        currentSort = _listsSort;
        currentSortAsc = _listsSortAsc;
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
        tagFilter: _tagFilter,
        filterValue: _filterValue,
        missingMetadataFilter: _missingMetadataFilter,
        availableGenres: _availableGenres,
        availableTags: _availableTags,
        availableSeries: _availableSeriesFilters,
        availableAuthors: _availableAuthorFilters,
        availableNarrators: _availableNarrators,
        availableLanguages: _availableLanguages,
        availablePublishers: _availablePublishers,
        availablePublishedDecades: _availablePublishedDecades,
        initialTab: initialTab,
        cs: cs,
        tt: tt,
        libraryTab: tab,
        onSortChanged: (sort) {
          Navigator.pop(ctx);
          _changeSort(sort);
        },
        onSortDirectionToggled: () {
          if (_currentTab == 1) {
            setState(() {
              _seriesSortAsc = !_seriesSortAsc;
              _seriesItems.clear();
              _seriesPage = 0;
              _hasMoreSeries = true;
              _isLoadingSeriesPage = false;
            });
            PlayerSettings.setSeriesSortAsc(_seriesSortAsc);
            if (_seriesScrollController.hasClients)
              _seriesScrollController.jumpTo(0);
            _loadSeriesPage();
          } else if (_currentTab == 2) {
            setState(() {
              _authorSortAsc = !_authorSortAsc;
              _sortAuthors();
            });
            PlayerSettings.setAuthorSortAsc(_authorSortAsc);
            if (_authorsScrollController.hasClients)
              _authorsScrollController.jumpTo(0);
          } else if (_currentTab == 3) {
            setState(() {
              _narratorSortAsc = !_narratorSortAsc;
              _sortNarrators();
            });
            PlayerSettings.setNarratorSortAsc(_narratorSortAsc);
            if (_narratorsScrollController.hasClients)
              _narratorsScrollController.jumpTo(0);
          } else if (_currentTab == 4) {
            setState(() => _listsSortAsc = !_listsSortAsc);
            PlayerSettings.setListsSortAsc(_listsSortAsc);
            if (_listsScrollController.hasClients)
              _listsScrollController.jumpTo(0);
          } else {
            setState(() {
              _sortAsc = !_sortAsc;
              _items.clear();
              _page = 0;
              _hasMore = true;
              _isLoadingPage = false;
            });
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
        onFilterChanged: (
          filter, {
          String? genre,
          String? tag,
          String? filterValue,
          String? filterValueLabel,
          MissingMetadataField? missingMetadata,
        }) {
          Navigator.pop(ctx);
          _changeFilter(
            filter,
            genre: genre,
            tag: tag,
            filterValue: filterValue,
            filterValueLabel: filterValueLabel,
            missingMetadata: missingMetadata,
          );
        },
        onClearFilter: () {
          Navigator.pop(ctx);
          _changeFilter(LibraryFilter.none);
        },
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
        canAccessExplicitContent:
            context.read<AuthProvider>().canAccessExplicitContent,
        // Browsers block Audible's catalog API (no CORS), so the series scan
        // can't work on web - hide the entry there
        onUpcomingReleases: tab == LibraryTab.series && !kIsWeb
            ? () {
                Navigator.pop(ctx);
                _openUpcomingReleases();
              }
            : null,
        currentSeriesFilter: _seriesFilter,
        onSeriesFilterChanged: tab == LibraryTab.series
            ? (sf) {
                Navigator.pop(ctx);
                _changeSeriesFilter(sf);
              }
            : null,
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
    // Watch LibraryProvider so this screen rebuilds when the active library
    // or its data changes; the actual lib object is consumed inside
    // _buildHeaderSliver via context.watch.
    final libWatch = context.watch<LibraryProvider>();
    // Reload the grid when the offline state flips so it swaps between the full
    // library and the downloads-only offline view.
    if (libWatch.isOffline != _wasOffline) {
      _wasOffline = libWatch.isOffline;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _resetSelectionState();
          _items.clear();
          _page = 0;
          _hasMore = true;
          _isLoadingPage = false;
        });
        _loadPage();
      });
    }
    final hasTabs = _tabController != null && !_isInSearchMode;
    final auth = context.watch<AuthProvider>();
    final selectingAuthors = hasTabs && _currentTab == 2;
    final authorSelectionAvailable =
        selectingAuthors &&
        !libWatch.isOffline &&
        auth.canUpdateMetadata &&
        !_matchingAuthors;
    final bookSelectionAvailable =
        !libWatch.isOffline &&
        !_isInSearchMode &&
        (hasTabs ? _currentTab == 0 : _podcastView == 0);
    final selectionAvailable =
        authorSelectionAvailable || bookSelectionAvailable;
    if (!selectionAvailable && _selectionMode) _resetSelectionState();
    final selectableItems = selectionAvailable && _selectionMode
        ? _selectableVisibleItems()
        : const <Map<String, dynamic>>[];
    // Drop ids that scrolled out of the current filter so the count and the
    // select-all state always describe what is on screen.
    if (_selectionMode) {
      _selectedItemIds.retainAll(
        selectableItems.map((item) => item['id'] as String).toSet(),
      );
    }
    final selectableCount = selectableItems.length;

    return Scaffold(
      backgroundColor: scaffoldBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !_selectionMode
          ? null
          : authorSelectionAvailable
          ? DesktopBatchActionBar(
              selectedCount: _selectedItemIds.length,
              selectableCount: selectableCount,
              busy: _batchActionBusy,
              busyLabel: _authorMatchTotal > 0
                  ? '$_authorMatchPosition/$_authorMatchTotal'
                  : null,
              canQuickMatch: true,
              canMarkProgress: false,
              canDelete: false,
              onSelectAll: _toggleSelectAll,
              onClear: _clearSelection,
              onQuickMatch: () =>
                  _runBatchAction(() => _quickMatchAuthors(_selectedAuthors())),
              onMarkFinished: () {},
              onMarkUnfinished: () {},
              onDelete: () {},
            )
          : bookSelectionAvailable
          ? DesktopBatchActionBar(
              selectedCount: _selectedItemIds.length,
              selectableCount: selectableCount,
              busy: _batchActionBusy,
              canQuickMatch: auth.isAdmin && !libWatch.isPodcastLibrary,
              canMarkProgress: !libWatch.isPodcastLibrary,
              canDelete: auth.canDelete,
              onSelectAll: _toggleSelectAll,
              onClear: _clearSelection,
              onQuickMatch: () => _runBatchAction(
                () => DesktopBatchActions.quickMatch(
                  context,
                  _selectedItemIds.toList(),
                ),
              ),
              onMarkFinished: () => _runBatchAction(
                () => DesktopBatchActions.setFinished(
                  context,
                  _selectedItemIds.toList(),
                  isFinished: true,
                ),
              ),
              onMarkUnfinished: () => _runBatchAction(
                () => DesktopBatchActions.setFinished(
                  context,
                  _selectedItemIds.toList(),
                  isFinished: false,
                ),
              ),
              onDelete: () => _runBatchAction(
                () => DesktopBatchActions.delete(
                  context,
                  _selectedItemIds.toList(),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          if (!flatNotifier.value)
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
                        cs.primary.withValues(
                          alpha: gradientIntensityNotifier.value,
                        ),
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
            // Per-tab CustomScrollView with its own SliverAppBar(floating, snap)
            // for the header. No NestedScrollView coordinator in the scroll
            // path, which makes scrolling noticeably smoother. The reveal
            // driver is fed by a single NotificationListener at this level so
            // the bottom nav stays in sync regardless of which tab is active.
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification) {
                      _revealDriver.noteScroll(
                        n.scrollDelta ?? 0,
                        n.metrics.pixels,
                      );
                    } else if (n is ScrollEndNotification) {
                      _revealDriver.settle();
                    }
                    return false;
                  },
                  child: Builder(
                    builder: (ctx) {
                      return _isInSearchMode
                          ? _buildSearchResults(
                              cs,
                              tt,
                              l,
                              _buildHeaderSliver(context, useSharedFocus: true),
                            )
                          : hasTabs
                          ? _buildTabbedContent(cs, tt)
                          : _podcastView == 1
                          ? PodcastEpisodeFeed(
                              key: ValueKey(
                                'epfeed-${libWatch.selectedLibraryId}',
                              ),
                              libraryId: libWatch.selectedLibraryId ?? '',
                              headerSliver: _buildHeaderSliver(
                                context,
                                useSharedFocus: true,
                              ),
                            )
                          : _buildGrid(
                              _buildHeaderSliver(context, useSharedFocus: true),
                            );
                    },
                  ),
                ),
                if (hasTabs && !_isInSearchMode)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _revealDriver.notifier,
                      // Translate only; skip the Opacity saveLayer that was
                      // forcing a per-frame re-raster of the BackdropFilter
                      // pill. Skip painting entirely once basically hidden.
                      builder: (_, reveal, child) {
                        if (reveal < 0.02) return const SizedBox.shrink();
                        return IgnorePointer(
                          ignoring: reveal < 0.5,
                          child: Transform.translate(
                            offset: Offset(0, (1 - reveal) * 80),
                            child: child,
                          ),
                        );
                      },
                      child: RepaintBoundary(child: _buildFloatingTabBar(cs)),
                    ),
                  ),
                if (!hasTabs && !_isInSearchMode)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _revealDriver.notifier,
                      builder: (_, reveal, child) {
                        if (reveal < 0.02) return const SizedBox.shrink();
                        return IgnorePointer(
                          ignoring: reveal < 0.5,
                          child: Transform.translate(
                            offset: Offset(0, (1 - reveal) * 80),
                            child: child,
                          ),
                        );
                      },
                      child: RepaintBoundary(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPodcastViewPill(cs),
                              if (context.read<AuthProvider>().isAdmin) ...[
                                const SizedBox(width: 8),
                                _buildFloatingManageButton(cs),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the floating SliverAppBar header that goes at the top of each
  /// tab's CustomScrollView. Each tab in the IndexedStack gets its own
  /// instance — when [useSharedFocus] is true, the SearchBar inside binds to
  /// the screen-level [_focusNode] (so the active tab is the one that
  /// receives focus from taps and the Search app shortcut). Inactive tabs
  /// get a fresh internal FocusNode per SearchBar so they don't fight over
  /// the shared one.
  Widget _buildHeaderSliver(
    BuildContext context, {
    required bool useSharedFocus,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final lowerFade = Color.lerp(cs.surface, scaffoldBg, 0.55) ?? scaffoldBg;
    final lib = context.watch<LibraryProvider>();
    final allLibraries = lib.libraries;
    final hasMultipleLibraries = allLibraries.length > 1;
    // Batch selection is offered on the books grid and on the authors tab.
    // Authors need metadata permission (quick match writes to the server);
    // books only need to be online and out of search, where the visible list
    // is stable enough for select-all to mean something.
    final canSelectAuthors =
        _tabController != null &&
        _currentTab == 2 &&
        context.read<AuthProvider>().canUpdateMetadata &&
        !_matchingAuthors;
    final canSelectItems =
        !lib.isOffline &&
        !_isInSearchMode &&
        (canSelectAuthors ||
            (_tabController == null ? _podcastView == 0 : _currentTab == 0));
    final libraryName =
        lib.selectedLibrary?['name'] as String? ?? l.libraryFallback;
    final topInset = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final headerBackground = flatNotifier.value
        ? ColoredBox(color: scaffoldBg)
        : ClipRect(
            child: OverflowBox(
              maxHeight: screenH,
              minHeight: 0,
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, -topInset),
                child: SizedBox(
                  height: screenH,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scaffoldBg,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.22, 0.72, 1.0],
                        colors: [
                          cs.primary.withValues(
                            alpha: gradientIntensityNotifier.value,
                          ),
                          cs.surface,
                          lowerFade,
                          scaffoldBg,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
    return SliverAppBar(
      floating: true,
      snap: true,
      // primary: false disables Material's automatic status
      // bar padding so the header doesn't get inset twice
      // (we already wrap the whole NestedScrollView in
      // SafeArea above).
      primary: false,
      toolbarHeight: _isInSearchMode
          ? 156
          : ((_filter != LibraryFilter.none ||
                    _seriesFilter != SeriesFilter.none)
                ? 196
                : 184),
      backgroundColor: scaffoldBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: headerBackground),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  actions: [
                        if (hasMultipleLibraries)
                          GestureDetector(
                            onTap: () => showLibraryPickerSheet(context, lib),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: cs.onSurface.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: cs.onSurface.withValues(alpha: 0.08),
                                ),
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
                                      color: cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 140,
                                      ),
                                      child: Text(
                                        libraryName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.unfold_more_rounded,
                                      size: 18,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (canSelectItems)
                          Tooltip(
                            message: _selectionMode
                                ? l.downloadsCancelSelection
                                : l.downloadsSelect,
                            child: IconButton(
                              onPressed: _batchActionBusy
                                  ? null
                                  : _selectionMode
                                  ? _clearSelection
                                  : () => setState(() => _selectionMode = true),
                              icon: Icon(
                                _selectionMode
                                    ? Icons.close_rounded
                                    : Icons.library_add_check_rounded,
                              ),
                            ),
                          ),
                      ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SearchBar(
                    // Same GlobalKey on whichever SearchBar gets the shared
                    // focus, so when _isInSearchMode toggles and the tree
                    // swaps from tabbed -> search results, Flutter re-parents
                    // the existing Element instead of destroying and
                    // recreating it. Keeps focus + keyboard alive.
                    key: useSharedFocus ? _searchBarKey : null,
                    controller: _searchController,
                    // Only the active tab's SearchBar binds to the screen-
                    // level focus node. Inactive tabs' SearchBars use their
                    // own internal focus so multiple instances in the
                    // IndexedStack don't fight over the same FocusNode (the
                    // bug that left tap-to-focus dead until you switched
                    // libraries to force a state reset).
                    focusNode: useSharedFocus ? _focusNode : null,
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
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 8),
                    ),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                    ),
                  ),
                ),
                // Item count + filter badge row
                if (!_isInSearchMode) _buildInfoRow(cs, tt, l),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Shows | Episodes switcher for podcast libraries, styled like the book
  // libraries' floating tab pills.
  Widget _buildPodcastViewPill(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final labels = [l.appShellShowsTab, l.libraryTabEpisodes];
    return ClipRRect(
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
              final active = _podcastView == i;
              return GestureDetector(
                onTap: () {
                  if (!active) {
                    setState(() => _podcastView = i);
                    PlayerSettings.setPodcastView(i);
                  } else if (i == 0) {
                    // Re-tap on the active Shows pill opens the sort sheet,
                    // same as the book libraries' pills.
                    _showSortFilterSheet(
                      context,
                      cs,
                      Theme.of(context).textTheme,
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: active ? 14 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? cs.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[i],
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                      if (active && i == 0) ...[
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
    );
  }

  Widget _buildFloatingTabBar(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final labels = [
      l.libraryTabLibrary,
      l.libraryTabSeries,
      l.libraryTabAuthors,
      l.libraryTabNarrators,
      if (_showLists) 'Lists',
    ];
    return Center(
      child: Padding(
        // Inset from the screen edges; the FittedBox below scales the whole
        // pill row down to fit this width so it never overflows on small or
        // zoomed/large-font screens.
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(labels.length, (i) {
                    final active = _currentTab == i;
                    return GestureDetector(
                      onTap: () {
                        if (active) {
                          _showSortFilterSheet(
                            context,
                            cs,
                            Theme.of(context).textTheme,
                          );
                        } else {
                          _tabController?.animateTo(i);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: active ? 14 : 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? cs.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              labels[i],
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: active
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                            if (active) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.sort_rounded,
                                size: 14,
                                color: cs.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpcomingReleasesScreen()),
    );
  }

  Widget _buildFloatingManageButton(ColorScheme cs) {
    return GestureDetector(
      onTap: () {
        final lib = context.read<LibraryProvider>().selectedLibrary;
        if (lib != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPodcastsScreen(library: lib),
            ),
          );
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
      case 4:
        final cCount = _collections.length, pCount = _playlists.length;
        countText = cCount > 0 && pCount > 0
            ? '$cCount collections, $pCount playlists'
            : (pCount > 0 ? '$pCount playlists' : '$cCount collections');
        break;
      default:
        final lib = context.read<LibraryProvider>();
        final visibleCount = _visibleLibraryItems(lib).length;
        countText = l.libraryBooksCount(
          visibleCount,
          _filter == LibraryFilter.subscribed ? visibleCount : _totalItems,
        );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 14,
                      color: cs.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _filterLabelOf(l),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.close_rounded, size: 14, color: cs.tertiary),
                  ],
                ),
              ),
            ),
          ],
          if (_currentTab == 1 && _seriesFilter != SeriesFilter.none) ...[
            GestureDetector(
              onTap: () => _changeSeriesFilter(SeriesFilter.none),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 14,
                      color: cs.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _seriesFilterLabelOf(l),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.close_rounded, size: 14, color: cs.tertiary),
                  ],
                ),
              ),
            ),
          ],
          if (_currentTab == 2 &&
              !_selectionMode &&
              _authors.isNotEmpty &&
              context.read<AuthProvider>().canUpdateMetadata &&
              !context.read<LibraryProvider>().isOffline)
            TextButton.icon(
              onPressed: _matchingAuthors ? null : _quickMatchAllAuthors,
              icon: _matchingAuthors
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: Text(
                _matchingAuthors && _authorMatchTotal > 0
                    ? '${l.adminMatching} '
                          '$_authorMatchPosition/$_authorMatchTotal'
                    : _matchingAuthors
                    ? l.adminMatching
                    : l.adminMatchAll,
              ),
            ),
          const Spacer(),
          Text(
            countText,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedContent(ColorScheme cs, TextTheme tt) {
    // IndexedStack preserves each tab's scroll position when switching tabs.
    // Each tab gets its own SliverAppBar instance built fresh by
    // _buildHeaderSliver — only the active tab passes useSharedFocus: true so
    // the SearchBar inside binds to the screen-level _focusNode. Inactive
    // tabs' SearchBars use their own internal focus, avoiding the multi-bind
    // bug that left the search bar unresponsive on first tap.
    // If we're somehow on the Lists tab without any lists, fall back to Library.
    final effectiveTab = (_currentTab == 4 && !_showLists) ? 0 : _currentTab;
    Widget headerFor(int i) =>
        _buildHeaderSliver(context, useSharedFocus: i == effectiveTab);
    return IndexedStack(
      index: effectiveTab,
      children: [
        _buildGrid(headerFor(0)),
        _buildSeriesGrid(headerFor(1)),
        _buildAuthorsGrid(headerFor(2)),
        _buildNarratorsGrid(headerFor(3)),
        _buildListsGrid(headerFor(4)),
      ],
    );
  }

  Widget _buildListsGrid(Widget headerSliver) {
    final entries = _sortedLists();
    return LibraryListsTab(
      entries: entries,
      // We expect lists (the remembered flag is set) but haven't loaded them
      // yet - show a spinner instead of flashing the empty state.
      isLoading: entries.isEmpty && _cachedHasLists,
      coverAspectRatio: _coverAspectRatio,
      onOpenCollection: (c) {
        final id = c['id'] as String?;
        if (id != null && id.isNotEmpty)
          CollectionDetailSheet.show(context, id);
      },
      onOpenPlaylist: (p) {
        final id = p['id'] as String?;
        if (id != null && id.isNotEmpty) PlaylistDetailSheet.show(context, id);
      },
      onRefresh: _refreshLists,
      headerSliver: headerSliver,
      scrollController: _listsScrollController,
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
  Widget _buildGrid(Widget headerSliver) {
    final lib = context.watch<LibraryProvider>();
    return LibraryBooksTab(
      items: _visibleLibraryItems(lib),
      isLoadingPage: _isLoadingPage,
      hasMore: _hasMore,
      filter: _filter,
      genreFilter: _genreFilter,
      tagFilter: _tagFilter,
      isPodcastLibrary: context.read<LibraryProvider>().isPodcastLibrary,
      rectangleCovers: _rectangleCovers,
      coverAspectRatio: _coverAspectRatio,
      onRefresh: _refreshAll,
      onClearFilter: () => _changeFilter(LibraryFilter.none),
      headerSliver: headerSliver,
      scrollController: _scrollController,
      onLoadMore: _loadPage,
      selectionMode: _selectionMode && (_tabController == null || _currentTab == 0),
      selectedItemIds: _selectedItemIds,
      onSelectionToggle: _toggleSelection,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BATCH SELECTION
  // ═══════════════════════════════════════════════════════════════
  void _resetSelectionState() {
    _selectionMode = false;
    _batchActionBusy = false;
    _selectedItemIds.clear();
    _lastSelectedVisibleIndex = null;
  }

  void _clearSelection() {
    if (!_selectionMode && _selectedItemIds.isEmpty) return;
    setState(_resetSelectionState);
  }

  List<Map<String, dynamic>> _selectableVisibleItems() {
    if (_tabController != null && _currentTab == 2) {
      return _authors
          .where((author) => author['id'] is String)
          .toList(growable: false);
    }
    final lib = context.read<LibraryProvider>();
    return _visibleLibraryItems(lib)
        .where(
          (item) =>
              !item.containsKey('collapsedSeries') && item['id'] is String,
        )
        .toList();
  }

  void _toggleSelection(Map<String, dynamic> item, int visibleIndex) {
    final itemId = item['id'] as String?;
    if (itemId == null) return;
    // Shift-click extends the run on a hardware keyboard; plain taps toggle.
    final shiftPressed = HardwareKeyboard.instance.isShiftPressed;
    setState(() {
      _selectionMode = true;
      if (shiftPressed && _lastSelectedVisibleIndex != null) {
        final items = _selectableVisibleItems();
        final start = min(_lastSelectedVisibleIndex!, visibleIndex);
        final end = max(_lastSelectedVisibleIndex!, visibleIndex);
        for (var index = start; index <= end && index < items.length; index++) {
          final rangeItem = items[index];
          if (rangeItem.containsKey('collapsedSeries')) continue;
          final rangeId = rangeItem['id'] as String?;
          if (rangeId != null) _selectedItemIds.add(rangeId);
        }
      } else if (!_selectedItemIds.add(itemId)) {
        _selectedItemIds.remove(itemId);
      }
      _lastSelectedVisibleIndex = visibleIndex;
    });
  }

  void _toggleSelectAll() {
    final ids = _selectableVisibleItems()
        .map((item) => item['id'] as String)
        .toSet();
    setState(() {
      _selectionMode = true;
      if (ids.isNotEmpty && _selectedItemIds.containsAll(ids)) {
        _selectedItemIds.removeAll(ids);
      } else {
        _selectedItemIds.addAll(ids);
      }
      _lastSelectedVisibleIndex = null;
    });
  }

  Future<void> _runBatchAction(Future<bool?> Function() action) async {
    if (_batchActionBusy) return;
    // Anything that scrolled out of the filter since it was ticked is dropped,
    // so an action can never touch an item the user can no longer see.
    final visibleIds = _selectableVisibleItems()
        .map((item) => item['id'] as String)
        .toSet();
    setState(() {
      _selectedItemIds.retainAll(visibleIds);
      if (_selectedItemIds.isEmpty) {
        _resetSelectionState();
      } else {
        _batchActionBusy = true;
      }
    });
    if (_selectedItemIds.isEmpty) return;
    final success = await action();
    if (!mounted) return;
    setState(() {
      _batchActionBusy = false;
      if (success == true) _resetSelectionState();
    });
  }

  List<Map<String, dynamic>> _selectedAuthors() {
    return _authors
        .where((author) => _selectedItemIds.contains(author['id']))
        .toList(growable: false);
  }

  String _authorQuickMatchRegion(LibraryProvider lib) {
    final provider =
        lib.selectedLibrary?['provider']?.toString().toLowerCase() ?? '';
    if (!provider.startsWith('audible.')) return 'us';
    final region = provider.split('.').last.trim();
    return region.isEmpty ? 'us' : region;
  }

  /// Quick-match authors one at a time. There is no batch author endpoint, so
  /// this walks the list and reports a tally at the end; the tile shows a
  /// spinner on whichever author is in flight.
  Future<bool> _quickMatchAuthors(
    List<Map<String, dynamic>> authors, {
    bool allAuthors = false,
  }) async {
    if (authors.isEmpty) return false;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    final libraryId = lib.selectedLibraryId;
    if (api == null || libraryId == null || !auth.canUpdateMetadata) {
      return false;
    }

    final l = AppLocalizations.of(context)!;
    setState(() {
      _authorMatchPosition = 0;
      _authorMatchTotal = authors.length;
      _matchingAuthorId = null;
    });
    showOverlayToast(
      context,
      l.adminMatchingStarted(
        allAuthors
            ? l.libraryAuthorsCount(authors.length)
            : l.selectedCount(authors.length),
      ),
      icon: Icons.auto_fix_high_rounded,
    );

    final region = _authorQuickMatchRegion(lib);
    var found = 0;
    var updated = 0;
    var notFound = 0;
    var failed = 0;
    for (var index = 0; index < authors.length; index++) {
      final author = authors[index];
      final id = author['id']?.toString() ?? '';
      final name = author['name']?.toString().trim() ?? '';
      final asin = author['asin']?.toString().trim() ?? '';
      if (mounted) {
        setState(() {
          _matchingAuthorId = id.isEmpty ? null : id;
          _authorMatchPosition = index + 1;
        });
      }
      if (id.isEmpty || (asin.isEmpty && name.isEmpty)) {
        failed++;
        continue;
      }
      final result = await api.quickMatchAuthor(
        id,
        asin: asin.isEmpty ? null : asin,
        q: asin.isEmpty ? name : null,
        region: region,
      );
      if (result.found) {
        found++;
        if (result.updated) updated++;
      } else if (result.statusCode == 404) {
        notFound++;
      } else {
        failed++;
      }
    }

    if (!mounted) return failed < authors.length;
    setState(() => _matchingAuthorId = null);
    if (context.read<LibraryProvider>().selectedLibraryId == libraryId) {
      await _refreshAuthors();
    }
    if (!mounted) return failed < authors.length;

    final unchanged = found - updated;
    final summary = <String>[
      if (updated > 0) '${l.metadataUpdated} ($updated)',
      if (unchanged > 0) '${l.quickMatchNoUpdates} ($unchanged)',
      if (notFound > 0) '${l.authorNoMatchFound} ($notFound)',
      if (failed > 0) '${l.failedToUpdateMetadata} ($failed)',
    ];
    showOverlayToast(
      context,
      summary.join(' - '),
      icon: failed > 0
          ? Icons.error_outline_rounded
          : notFound > 0
          ? Icons.search_off_rounded
          : Icons.check_circle_outline_rounded,
    );
    return failed == 0 && notFound == 0;
  }

  Future<void> _quickMatchAllAuthors() async {
    if (_matchingAuthors || _batchActionBusy || _authors.isEmpty) return;
    final authors = List<Map<String, dynamic>>.from(_authors);
    setState(() => _matchingAuthors = true);
    await _quickMatchAuthors(authors, allAuthors: true);
    if (mounted) {
      setState(() {
        _matchingAuthors = false;
        _authorMatchPosition = 0;
        _authorMatchTotal = 0;
      });
    }
  }

  List<Map<String, dynamic>> _visibleLibraryItems(LibraryProvider lib) {
    if (_filter != LibraryFilter.subscribed) return _items;
    return _items.where((item) {
      final id = item['id'] as String?;
      return id != null && lib.isPodcastSubscribed(id);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // SERIES TAB - GRID
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSeriesGrid(Widget headerSliver) {
    return LibrarySeriesTab(
      seriesItems: _seriesItems,
      isLoadingSeriesPage: _isLoadingSeriesPage,
      hasMoreSeries: _hasMoreSeries,
      rectangleCovers: _rectangleCovers,
      coverAspectRatio: _coverAspectRatio,
      onRefresh: _refreshSeries,
      headerSliver: headerSliver,
      scrollController: _seriesScrollController,
      onLoadMore: _loadSeriesPage,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTHORS TAB - GRID
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAuthorsGrid(Widget headerSliver) {
    return LibraryAuthorsTab(
      authors: _authors,
      isLoadingAuthors: _isLoadingAuthors,
      authorsLoaded: _authorsLoaded,
      onRefresh: _refreshAuthors,
      headerSliver: headerSliver,
      scrollController: _authorsScrollController,
      selectionMode: _selectionMode && _currentTab == 2,
      selectedAuthorIds: _selectedItemIds,
      matchingAuthorId: _matchingAuthorId,
      onSelectionToggle: _toggleSelection,
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

  Widget _buildNarratorsGrid(Widget headerSliver) {
    return LibraryNarratorsTab(
      narrators: _narrators,
      isLoading: _isLoadingNarrators,
      loaded: _narratorsLoaded,
      onRefresh: _refreshNarrators,
      headerSliver: headerSliver,
      scrollController: _narratorsScrollController,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH RESULTS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSearchResults(
    ColorScheme cs,
    TextTheme tt,
    AppLocalizations l,
    Widget headerSliver,
  ) {
    final injector = headerSliver;
    if (_isSearching) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          injector,
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (!_hasSearched) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          injector,
          const SliverToBoxAdapter(child: SizedBox.shrink()),
        ],
      );
    }
    final auth = context.read<AuthProvider>();
    final libProv = context.read<LibraryProvider>();
    final isPodcast = libProv.isPodcastLibrary;
    final showPodcastLookup = isPodcast && auth.isAdmin;
    if (_searchBookResults.isEmpty &&
        _searchSeriesResults.isEmpty &&
        _searchAuthorResults.isEmpty &&
        _searchNarratorResults.isEmpty &&
        _searchEpisodeResults.isEmpty &&
        _searchTagResults.isEmpty &&
        _searchGenreResults.isEmpty) {
      final showRmabCta = _rmabConfigured && !libProv.isPodcastLibrary;
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          injector,
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.libraryNoResults,
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (showPodcastLookup) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.podcasts_rounded, size: 18),
                      label: Text(
                        l.adminPodcastsSearchItunesFor(
                          _searchController.text.trim(),
                        ),
                      ),
                      onPressed: _openPodcastLookup,
                    ),
                  ] else if (showRmabCta) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: Text(l.rmabRequestCta),
                      onPressed: () {
                        final q = _searchController.text.trim();
                        debugPrint('[RMAB] library CTA tapped (query="$q")');
                        showRmabSearchResultsSheet(context, initialQuery: q);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    final children = <Widget>[
      // ─── BOOKS / SHOWS (only title matches) ───
      if (_searchBookResults.isNotEmpty) ...[
        ...() {
          final query = _searchController.text.trim().toLowerCase();
          final titleMatches = _searchBookResults.where((result) {
            // Fuzzy index results carry their own title-match flag; fall back
            // to a substring check for server/podcast results.
            final tm = result['_titleMatch'];
            if (tm is bool) return tm;
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
              child: Text(
                isPodcast ? l.librarySearchShows : l.librarySearchBooks,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
            ...titleMatches.map((result) {
              final item = result['libraryItem'] as Map<String, dynamic>? ?? {};
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
            4,
            _searchBookResults.isNotEmpty ? 20 : 8,
            4,
            8,
          ),
          child: Text(
            l.librarySearchEpisodes,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
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
            4,
            _searchBookResults.isNotEmpty ? 20 : 8,
            4,
            8,
          ),
          child: Text(
            l.librarySearchSeries,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
        ..._searchSeriesResults.map((result) {
          final seriesData = result['series'] as Map<String, dynamic>? ?? {};
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
            4,
            (_searchBookResults.isNotEmpty || _searchSeriesResults.isNotEmpty)
                ? 20
                : 8,
            4,
            8,
          ),
          child: Text(
            l.librarySearchAuthors,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
        ..._searchAuthorResults.map((result) {
          final authorData =
              result['author'] as Map<String, dynamic>? ??
              result as Map<String, dynamic>;
          return AuthorResultTile(
            author: authorData,
            serverUrl: auth.serverUrl,
            token: auth.token,
          );
        }),
      ],

      // ─── NARRATORS ───
      if (_searchNarratorResults.isNotEmpty) ...[
        Padding(
          padding: EdgeInsets.fromLTRB(
            4,
            (_searchBookResults.isNotEmpty ||
                    _searchSeriesResults.isNotEmpty ||
                    _searchAuthorResults.isNotEmpty)
                ? 20
                : 8,
            4,
            8,
          ),
          child: Text(
            l.libraryTabNarrators,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
        ..._searchNarratorResults.map((name) => NarratorResultTile(name: name)),
      ],

      // ─── GENRES ───
      if (_searchGenreResults.isNotEmpty) ...[
        Padding(
          padding: EdgeInsets.fromLTRB(
            4,
            (_searchBookResults.isNotEmpty ||
                    _searchSeriesResults.isNotEmpty ||
                    _searchAuthorResults.isNotEmpty ||
                    _searchNarratorResults.isNotEmpty)
                ? 20
                : 8,
            4,
            8,
          ),
          child: Text(
            l.librarySearchGenres,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
        ..._searchGenreResults.map(
          (name) =>
              GenreResultTile(name: name, onTap: () => _applyGenreFilter(name)),
        ),
      ],

      // ─── TAGS ───
      if (_searchTagResults.isNotEmpty) ...[
        Padding(
          padding: EdgeInsets.fromLTRB(
            4,
            (_searchBookResults.isNotEmpty ||
                    _searchSeriesResults.isNotEmpty ||
                    _searchAuthorResults.isNotEmpty ||
                    _searchNarratorResults.isNotEmpty ||
                    _searchGenreResults.isNotEmpty)
                ? 20
                : 8,
            4,
            8,
          ),
          child: Text(
            l.librarySearchTags,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
        ..._searchTagResults.map(
          (name) =>
              TagResultTile(name: name, onTap: () => _applyTagFilter(name)),
        ),
      ],
      // ─── RMAB FOOTER (when results exist + RMAB configured) ───
      if (showPodcastLookup || (_rmabConfigured && !isPodcast)) ...[
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(
            l.rmabSearchFooterPrompt,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: showPodcastLookup
                ? _openPodcastLookup
                : () {
                    final q = _searchController.text.trim();
                    debugPrint('[RMAB] library footer CTA tapped (query="$q")');
                    showRmabSearchResultsSheet(context, initialQuery: q);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    showPodcastLookup
                        ? Icons.podcasts_rounded
                        : Icons.menu_book_rounded,
                    size: 20,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      showPodcastLookup
                          ? l.adminPodcastsSearchItunesFor(
                              _searchController.text.trim(),
                            )
                          : l.rmabSearchFooterCta(
                              _searchController.text.trim(),
                            ),
                      style: tt.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        injector,
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    );
  }
}
