part of 'library_provider.dart';

mixin _StateMixin on ChangeNotifier {
  AuthProvider? _auth;
  ApiService? get _api => _auth?.apiService;

  List<dynamic> _libraries = [];
  String? _selectedLibraryId;
  List<dynamic> _personalizedSections = [];
  List<dynamic> _series = [];
  bool _isLoading = false;
  bool _isLoadingSeries = false;
  String? _errorMessage;

  final Map<String, int> _itemUpdatedAt = {};
  final Set<String> _itemsWithoutCover = {};

  Future<void>? _personalizedInFlight;
  Future<void>? _progressShelvesInFlight;
  DateTime? _lastPersonalizedFetchAt;
  String? _lastPersonalizedFetchLibraryId;
  DateTime? _lastProgressShelvesFetchAt;
  String? _lastProgressShelvesLibraryId;
  bool _rssHydrationInFlight = false;
  DateTime? _lastRssHydrationAt;
  String? _lastRssHydrationLibraryId;
  static const _personalizedFetchCooldown = Duration(seconds: 5);
  static const _progressShelvesFetchCooldown = Duration(seconds: 20);
  static const _rssHydrationCooldown = Duration(minutes: 10);
  Timer? _progressRefreshDebounce;
  static const _progressDrivenShelfIds = <String>[
    'continue-listening',
    'continue-series',
    'listen-again',
  ];

  List<dynamic> _playlists = [];
  bool _isLoadingPlaylists = false;
  Future<void>? _playlistsInFlight;

  List<dynamic> _collections = [];
  bool _isLoadingCollections = false;
  Future<void>? _collectionsInFlight;

  List<String> _sectionOrder = [];
  Set<String> _hiddenSectionIds = {};
  bool _applyDefaultPlaylistCollectionHiding = false;

  /// Genre sections added by the user (genre name -> cached items).
  Map<String, List<dynamic>> _genreSections = {};
  /// Persisted set of genre names the user has added as home sections.
  Set<String> _addedGenres = {};

  final Map<String, Map<String, dynamic>> _seriesBooksCache = {};
  final Map<String, Map<String, dynamic>> _seriesTabCache = {};
  final Map<String, Map<String, dynamic>> _subSeriesCache = {};

  Set<String> _rollingDownloadSeries = {};
  Set<String> _subscribedPodcasts = {};

  bool _manualOffline = false;
  bool _networkOffline = false;
  bool _deviceHasConnectivity = true;
  Timer? _serverPingTimer;
  Timer? _healthCheckTimer;

  bool _isBackgrounded = false;
  bool _socketSoftDisconnected = false;
  Timer? _idleDisconnectTimer;
  static const _idleTimeout = Duration(minutes: 5);

  Map<String, Map<String, dynamic>> _progressMap = {};
  final Map<String, double> _localProgressOverrides = {};
  final Set<String> _resetItems = {};

  Set<String> _manualAbsorbAdds = {};
  Set<String> _manualAbsorbRemoves = {};
  List<String> _absorbingBookIds = [];
  Map<String, Map<String, dynamic>> _absorbingItemCache = {};
  String? _lastFinishedItemId;
  final Set<String> _locallyFinishedItems = {};

  StreamSubscription? _connectivitySub;
  bool _listeningToDownloads = false;
  String? _lastAuthKey;

  final Map<String, Set<String>> _knownEpisodeIds = {};

  List<dynamic> get libraries => _libraries;
  String? get selectedLibraryId => _selectedLibraryId;
  List<dynamic> get personalizedSections => _personalizedSections;
  List<dynamic> get series => _series;
  bool get isLoading => _isLoading;
  bool get isLoadingSeries => _isLoadingSeries;
  String? get errorMessage => _errorMessage;
  List<dynamic> get playlists => _playlists;
  bool get isLoadingPlaylists => _isLoadingPlaylists;
  List<dynamic> get collections => _collections;
  bool get isLoadingCollections => _isLoadingCollections;
  List<String> get sectionOrder => _sectionOrder;
  Set<String> get hiddenSectionIds => _hiddenSectionIds;
  bool get isOffline => _manualOffline || _networkOffline;
  bool get isManualOffline => _manualOffline;
  Set<String> get manualAbsorbAdds => _manualAbsorbAdds;
  Set<String> get manualAbsorbRemoves => _manualAbsorbRemoves;
  List<String> get absorbingBookIds => _absorbingBookIds;
  Map<String, Map<String, dynamic>> get absorbingItemCache =>
      _absorbingItemCache;

  Map<String, dynamic>? get selectedLibrary {
    if (_selectedLibraryId == null) return null;
    try {
      return _libraries.firstWhere(
        (l) => l['id'] == _selectedLibraryId,
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool get isPodcastLibrary {
    final lib = selectedLibrary;
    if (lib == null) return false;
    return (lib['mediaType'] as String? ?? 'book') == 'podcast';
  }

  String get selectedMediaType {
    final lib = selectedLibrary;
    if (lib == null) return 'book';
    return lib['mediaType'] as String? ?? 'book';
  }

  int get finishedCount =>
      _progressMap.values.where((p) => p['isFinished'] == true).length;

  int get finishedBooksCount => _progressMap.values.where((p) {
        if (p['isFinished'] != true) return false;
        final ep = p['episodeId'];
        return ep == null || (ep is String && ep.isEmpty);
      }).length;

  int get finishedEpisodesCount => _progressMap.values.where((p) {
        if (p['isFinished'] != true) return false;
        final ep = p['episodeId'];
        return ep is String && ep.isNotEmpty;
      }).length;

  int get finishedBooksThisYearCount {
    final year = DateTime.now().year;
    var count = 0;
    for (final p in _progressMap.values) {
      if (p['isFinished'] != true) continue;
      final ep = p['episodeId'];
      if (ep is String && ep.isNotEmpty) continue;
      final raw = p['finishedAt'];
      if (raw is! num) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      if (dt.year == year) count++;
    }
    return count;
  }

  /// IDs of books finished this year, newest-first (by finishedAt).
  /// Podcasts are excluded. Used by the stats-screen detail sheet to load
  /// full item data on demand.
  List<String> get finishedBooksThisYearIds {
    final year = DateTime.now().year;
    final entries = <MapEntry<String, int>>[];
    for (final p in _progressMap.values) {
      if (p['isFinished'] != true) continue;
      final ep = p['episodeId'];
      if (ep is String && ep.isNotEmpty) continue;
      final raw = p['finishedAt'];
      if (raw is! num) continue;
      final ts = raw.toInt();
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (dt.year != year) continue;
      final id = p['libraryItemId'] as String?;
      if (id == null) continue;
      entries.add(MapEntry(id, ts));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  int get finishedEpisodesThisYearCount {
    final year = DateTime.now().year;
    var count = 0;
    for (final p in _progressMap.values) {
      if (p['isFinished'] != true) continue;
      final ep = p['episodeId'];
      if (ep is! String || ep.isEmpty) continue;
      final raw = p['finishedAt'];
      if (raw is! num) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      if (dt.year == year) count++;
    }
    return count;
  }

  Map<String, String> get mediaHeaders => _api?.mediaHeaders ?? {};

  Map<String, dynamic>? getSeriesBooksCache(String seriesId) =>
      _seriesBooksCache[seriesId];

  void setSeriesBooksCache(String seriesId, List<dynamic> books, int total) {
    _seriesBooksCache[seriesId] = {'books': books, 'total': total};
  }

  Map<String, dynamic>? getSubSeriesCache(String seriesId) =>
      _subSeriesCache[seriesId];

  void setSubSeriesCache(String seriesId, List<Map<String, dynamic>> subSeries, Set<String> assignedIds) {
    _subSeriesCache[seriesId] = {'subSeries': subSeries, 'assignedIds': assignedIds};
  }

  Map<String, dynamic>? getSeriesTabCache(String key) =>
      _seriesTabCache[key];

  void setSeriesTabCache(
      String key, List<Map<String, dynamic>> items, int total) {
    _seriesTabCache[key] = {'items': items, 'total': total};
  }

  void registerUpdatedAt(String id, int ts) => _itemUpdatedAt[id] = ts;

  void registerHasCover(String id, bool hasCover) {
    if (hasCover) {
      _itemsWithoutCover.remove(id);
    } else {
      _itemsWithoutCover.add(id);
    }
  }

  bool _isLikelyNetworkError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is HandshakeException ||
        error is HttpException;
  }

  static final _leadingNumber = RegExp(r'^[\d.]+');

  static double? _parseSequence(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = _leadingNumber.firstMatch(raw.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static (String?, double?) _extractSeries(Map<String, dynamic> item) {
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final seriesRaw = metadata['series'];
    if (seriesRaw is List) {
      for (final s in seriesRaw) {
        if (s is Map<String, dynamic>) {
          final id = s['id'] as String?;
          final seq = _parseSequence((s['sequence'] ?? '').toString());
          if (id != null && seq != null) return (id, seq);
        }
      }
    } else if (seriesRaw is Map<String, dynamic>) {
      final id = seriesRaw['id'] as String?;
      final seq = _parseSequence((seriesRaw['sequence'] ?? '').toString());
      if (id != null && seq != null) return (id, seq);
    }
    return (null, null);
  }

  Map<String, dynamic>? _itemDataWithSeries(String itemId) {
    final cached = _absorbingItemCache[itemId];
    if (cached != null) {
      final (sid, _) = _extractSeries(cached);
      if (sid != null) return cached;
    }
    final dl = DownloadService().getInfo(itemId);
    if (dl.sessionData == null) return cached;
    try {
      final session = jsonDecode(dl.sessionData!) as Map<String, dynamic>;
      final libItem = session['libraryItem'] as Map<String, dynamic>?;
      if (libItem != null) {
        final (sid, _) = _extractSeries(libItem);
        if (sid != null) return libItem;
      }
    } catch (_) {}
    return cached;
  }

  static bool _isLocalUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
      return true;
    }
    final parts = host.split('.');
    if (parts.length == 4) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      if (a == 10) return true;
      if (a == 172 && b != null && b >= 16 && b <= 31) return true;
      if (a == 192 && b == 168) return true;
    }
    if (host.endsWith('.local')) return true;
    if (host.endsWith('.ts.net')) return true;
    return false;
  }

  void _showRollingSnackBar(String message) {
    scaffoldMessengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ));
  }

  /// Look up [AppLocalizations] via the root navigator. Returns null if no
  /// context is mounted (e.g. very early startup); callers should provide
  /// English fallbacks.
  AppLocalizations? _l() {
    final ctx = rootNavigatorKey.currentContext;
    return ctx != null ? AppLocalizations.of(ctx) : null;
  }

  String? getCoverUrl(String? itemId, {int width = 400}) {
    if (itemId == null) return null;

    final isCompositeKey = itemId.length > 36;
    final apiItemId = isCompositeKey ? itemId.substring(0, 36) : itemId;

    if (_itemsWithoutCover.contains(apiItemId)) return null;

    if (_api != null && !isOffline) {
      final ts = _itemUpdatedAt[apiItemId];
      return _api!.getCoverUrl(apiItemId, width: width, updatedAt: ts);
    }

    final dl = DownloadService().getInfo(itemId);
    if (dl.localCoverPath != null) {
      return dl.localCoverPath;
    }

    if (dl.status == DownloadStatus.none) {
      final match = DownloadService()
          .downloadedItems
          .where((d) =>
              d.itemId.startsWith('$itemId-') && d.localCoverPath != null)
          .firstOrNull;
      if (match?.localCoverPath != null) {
        return match!.localCoverPath;
      }
    }

    if (_api != null) return _api!.getCoverUrl(apiItemId, width: width);
    return dl.coverUrl;
  }
}
