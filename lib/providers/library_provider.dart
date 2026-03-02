import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/scoped_prefs.dart';
import '../services/audio_player_service.dart';
import 'auth_provider.dart';
import '../services/api_service.dart';
import '../services/progress_sync_service.dart';
import '../services/download_service.dart';
import '../services/android_auto_service.dart';
import '../services/chromecast_service.dart';

/// Holds library data and personalized home sections.
class LibraryProvider extends ChangeNotifier {
  AuthProvider? _auth;
  ApiService? get _api => _auth?.apiService;

  // State
  List<dynamic> _libraries = [];
  String? _selectedLibraryId;
  List<dynamic> _personalizedSections = [];
  List<dynamic> _series = [];
  bool _isLoading = false;
  bool _isLoadingSeries = false;
  String? _errorMessage;

  // Cache of item updatedAt timestamps for cover cache-busting
  final Map<String, int> _itemUpdatedAt = {};

  // Fetch deduplication for loadPersonalizedView
  Future<void>? _personalizedInFlight;
  DateTime? _lastPersonalizedFetchAt;
  String? _lastPersonalizedFetchLibraryId;
  static const _personalizedFetchCooldown = Duration(seconds: 5);

  // Offline mode
  bool _manualOffline = false;
  bool _networkOffline = false;
  bool _deviceHasConnectivity = true; // false only when device has no network at all
  Timer? _serverPingTimer;
  bool get isOffline => _manualOffline || _networkOffline;
  bool get isManualOffline => _manualOffline;

  /// Toggle manual offline mode.
  Future<void> setManualOffline(bool value) async {
    debugPrint('[Library] setManualOffline($value)');
    _manualOffline = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('manual_offline_mode', value);
    if (!value) {
      // Going back online — clear any stale network-offline flag too
      _networkOffline = false;
      _stopServerPingTimer();
      if (_api != null) {
        debugPrint('[Library] Manual offline off — flushing pending syncs');
        ProgressSyncService().flushPendingSync(api: _api!);
      }
      if (_selectedLibraryId == null) {
        loadLibraries();
      } else {
        refresh();
      }
    } else {
      // Going offline — show downloaded books
      _buildOfflineSections();
    }
    notifyListeners();
  }

  /// Called on init to restore manual offline preference.
  Future<void> restoreOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    _manualOffline = prefs.getBool('manual_offline_mode') ?? false;
  }

  /// Called when network connectivity changes.
  void setNetworkOffline(bool offline) {
    final wasOffline = _networkOffline;
    _networkOffline = offline;
    if (offline && !wasOffline) {
      // Just went offline — show downloads, and force AA to clear server tabs
      _buildOfflineSections();
      notifyListeners();
      AndroidAutoService().refresh(force: true);
      // If the device still has connectivity, the server is just unreachable —
      // start pinging so we auto-recover when it comes back.
      if (_deviceHasConnectivity && !_manualOffline) {
        _startServerPingTimer();
      }
    } else if (!offline && wasOffline && !_manualOffline) {
      // Came back online — stop pinging, flush pending syncs, then refresh
      _stopServerPingTimer();
      if (_api != null) {
        debugPrint('[Library] Back online — flushing pending syncs');
        ProgressSyncService().flushPendingSync(api: _api!);
      }
      if (_selectedLibraryId == null) {
        loadLibraries();
      } else {
        refresh();
      }
      AndroidAutoService().refresh(force: true);
    }
  }

  /// Build home sections from downloaded books.
  void _buildOfflineSections() {
    final downloads = DownloadService().downloadedItems;
    debugPrint('[Library] Building offline sections: ${downloads.length} downloads');
    if (downloads.isEmpty) {
      _personalizedSections = [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Build fake entities from download metadata
    final entities = <Map<String, dynamic>>[];
    for (final dl in downloads) {
      // Try to extract duration from cached session data
      double duration = 0;
      List<dynamic> chapters = [];
      if (dl.sessionData != null) {
        try {
          final session = jsonDecode(dl.sessionData!) as Map<String, dynamic>;
          duration = (session['duration'] as num?)?.toDouble() ?? 0;
          chapters = session['chapters'] as List<dynamic>? ?? [];
        } catch (_) {}
      }

      entities.add({
        'id': dl.itemId,
        'media': {
          'metadata': {
            'title': dl.title ?? 'Unknown Title',
            'authorName': dl.author ?? '',
          },
          'duration': duration,
          'chapters': chapters,
        },
      });
    }

    final isPodcast = isPodcastLibrary;
    _personalizedSections = [
      {
        'id': 'downloaded-books',
        'label': isPodcast ? 'Downloaded Episodes' : 'Downloaded Books',
        'type': isPodcast ? 'podcast' : 'book',
        'entities': entities,
      },
    ];
    _errorMessage = null;
    _isLoading = false;
  }

  // User's media progress, keyed by libraryItemId
  Map<String, Map<String, dynamic>> _progressMap = {};

  // Getters
  List<dynamic> get libraries => _libraries;
  String? get selectedLibraryId => _selectedLibraryId;
  List<dynamic> get personalizedSections => _personalizedSections;
  List<dynamic> get series => _series;
  bool get isLoading => _isLoading;
  bool get isLoadingSeries => _isLoadingSeries;
  String? get errorMessage => _errorMessage;

  /// Get progress (0.0–1.0) for a library item by ID.
  /// Checks local progress first (freshest), falls back to server data.
  double getProgress(String? itemId) {
    if (itemId == null) return 0;
    // If item was reset this session, always return 0
    if (_resetItems.contains(itemId)) return 0;
    // Check local override first
    final local = _localProgressOverrides[itemId];
    if (local != null) return local;
    // Fall back to server data
    final mp = _progressMap[itemId];
    if (mp == null) return 0;
    return (mp['progress'] as num?)?.toDouble() ?? 0;
  }

  /// Get progress for a podcast episode using compound key.
  double getEpisodeProgress(String itemId, String episodeId) {
    final key = '$itemId-$episodeId';
    if (_resetItems.contains(key)) return 0;
    final local = _localProgressOverrides[key];
    if (local != null) return local;
    final mp = _progressMap[key];
    if (mp == null) return 0;
    return (mp['progress'] as num?)?.toDouble() ?? 0;
  }

  /// Get the raw progress data map for an item (includes isFinished, currentTime, etc.)
  Map<String, dynamic>? getProgressData(String? itemId) {
    if (itemId == null) return null;
    if (_resetItems.contains(itemId)) return null;
    final data = _progressMap[itemId];
    if (_locallyFinishedItems.contains(itemId)) {
      return {...?data, 'isFinished': true};
    }
    return data;
  }

  /// Get raw progress data for a podcast episode.
  Map<String, dynamic>? getEpisodeProgressData(String itemId, String episodeId) {
    final key = '$itemId-$episodeId';
    if (_resetItems.contains(key)) return null;
    final data = _progressMap[key];
    if (_locallyFinishedItems.contains(key)) {
      return {...?data, 'isFinished': true};
    }
    return data;
  }

  /// Count of books marked as finished in the progress map.
  int get finishedCount => _progressMap.values
      .where((p) => p['isFinished'] == true)
      .length;

  // Local progress overrides (from ProgressSyncService)
  final Map<String, double> _localProgressOverrides = {};
  // Items that have been reset — force progress to 0 until app restart
  final Set<String> _resetItems = {};

  /// Merge local progress into the display. Call after playback.
  Future<void> refreshLocalProgress() async {
    final sync = ProgressSyncService();
    // Check both server-known items and downloaded items
    final itemIds = <String>{..._progressMap.keys};
    for (final dl in DownloadService().downloadedItems) {
      itemIds.add(dl.itemId);
    }
    for (final itemId in itemIds) {
      final data = await sync.getLocal(itemId);
      if (data != null) {
        final currentTime = (data['currentTime'] as num?)?.toDouble() ?? 0;
        final duration = (data['duration'] as num?)?.toDouble() ?? 0;
        if (duration > 0) {
          _localProgressOverrides[itemId] = (currentTime / duration).clamp(0.0, 1.0);
          // If item was reset but is now being played, clear the reset flag
          if (currentTime > 0) _resetItems.remove(itemId);
        }
      }
    }
    notifyListeners();
  }

  /// Clear all local progress caches for an item (used after mark finished/not finished).
  void clearProgressFor(String itemId) {
    _progressMap.remove(itemId);
    _localProgressOverrides.remove(itemId);
    notifyListeners();
  }

  /// Clear progress AND mark as reset — forces 0 progress until playback resumes.
  void resetProgressFor(String itemId) {
    _progressMap.remove(itemId);
    _localProgressOverrides.remove(itemId);
    _locallyFinishedItems.remove(itemId);
    _resetItems.add(itemId);
    notifyListeners();
  }

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

  /// Whether the currently selected library is a podcast library.
  bool get isPodcastLibrary {
    final lib = selectedLibrary;
    if (lib == null) return false;
    return (lib['mediaType'] as String? ?? 'book') == 'podcast';
  }

  /// The media type of the selected library ('book' or 'podcast').
  String get selectedMediaType {
    final lib = selectedLibrary;
    if (lib == null) return 'book';
    return lib['mediaType'] as String? ?? 'book';
  }

  StreamSubscription? _connectivitySub;

  /// Called by ProxyProvider when auth changes.
  String? _lastAuthKey; // Guard against redundant updateAuth from ProxyProvider

  void updateAuth(AuthProvider auth) {
    final wasAuthenticated = _auth?.isAuthenticated ?? false;
    final previousUserId = _auth?.userId;
    _auth = auth;

    if (auth.isAuthenticated) {
      final isNewUser = previousUserId != null && previousUserId != auth.userId;
      final isFreshLogin = !wasAuthenticated;

      // Build a key to detect duplicate calls from ProxyProvider re-triggering
      final authKey = '${auth.userId}@${auth.serverUrl}';
      final isDuplicate = authKey == _lastAuthKey && !isNewUser && !isFreshLogin;
      _lastAuthKey = authKey;

      if (isDuplicate) return; // Skip redundant update

      if (isNewUser || isFreshLogin) {
        _libraries = [];
        _personalizedSections = [];
        _series = [];
        _progressMap = {};
        _localProgressOverrides.clear();
        _resetItems.clear();
        _manualAbsorbAdds.clear();
        _manualAbsorbRemoves.clear();
        _absorbingBookIds.clear();
        _absorbingItemCache.clear();
        _itemUpdatedAt.clear();
        _personalizedInFlight = null;
        _lastPersonalizedFetchAt = null;
        _lastPersonalizedFetchLibraryId = null;
        _networkOffline = false;
        _connectivitySub?.cancel();
        _stopServerPingTimer();
        _isLoading = true;
        notifyListeners(); // Immediately clear old user's data from UI
      }

      // Restore manual offline preference and start connectivity monitoring
      // Must complete before loading libraries so offline state is correct
      AudioPlayerService.setOnBookFinishedCallback(markFinishedLocally);
      ChromecastService.setOnBookFinishedCallback(markFinishedLocally);

      restoreOfflineMode().then((_) {
        _startConnectivityMonitoring();
        _loadManualAbsorbing();

        // If server was unreachable on startup, force offline mode and ping
        if (!auth.serverReachable) {
          _networkOffline = true;
          _buildOfflineSections();
          _isLoading = false;
          notifyListeners();
          if (_deviceHasConnectivity) _startServerPingTimer();
          return;
        }

        _buildProgressMap(auth);
        if (_api != null && !isOffline) {
          ProgressSyncService().flushPendingSync(api: _api!);
          DownloadService().enrichMetadata(_api!);
        }
        loadLibraries();
      });
    } else {
      _lastAuthKey = null;
      AudioPlayerService.setOnBookFinishedCallback(null);
      ChromecastService.setOnBookFinishedCallback(null);
      _libraries = [];
      _personalizedSections = [];
      _series = [];
      _progressMap = {};
      _localProgressOverrides.clear();
      _itemUpdatedAt.clear();
      _selectedLibraryId = null;
      _errorMessage = null;
      _connectivitySub?.cancel();
      _stopServerPingTimer();
      _personalizedInFlight = null;
      _lastPersonalizedFetchAt = null;
      _lastPersonalizedFetchLibraryId = null;
      notifyListeners();
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySub?.cancel();
    // Check current state immediately
    Connectivity().checkConnectivity().then((result) {
      _deviceHasConnectivity = !result.contains(ConnectivityResult.none);
      if (!_deviceHasConnectivity) {
        _stopServerPingTimer();
        setNetworkOffline(true);
      } else if (_networkOffline && !_manualOffline) {
        // Device has connectivity but we're still offline — server was unreachable
        _startServerPingTimer();
      }
    });
    // Then listen for changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final hasConnectivity = !result.contains(ConnectivityResult.none);
      _deviceHasConnectivity = hasConnectivity;
      if (!hasConnectivity) {
        _stopServerPingTimer();
        setNetworkOffline(true);
      } else if (!_manualOffline) {
        // Connectivity restored — optimistically go online; if server is still
        // down the API call will fail and _goOfflineWithPing() will be called.
        setNetworkOffline(false);
      }
    });
  }

  /// Start a periodic timer that pings the server until it responds.
  /// Used when the device has network but the server was unreachable.
  void _startServerPingTimer() {
    _serverPingTimer?.cancel();
    final serverUrl = _auth?.serverUrl;
    if (serverUrl == null) return;
    debugPrint('[Library] Starting server ping timer');
    _serverPingTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!_networkOffline || _manualOffline) {
        _stopServerPingTimer();
        return;
      }
      final reachable = await ApiService.pingServer(
        serverUrl,
        customHeaders: _auth?.customHeaders ?? {},
      );
      if (reachable) {
        debugPrint('[Library] Server ping succeeded — going online');
        _stopServerPingTimer();
        setNetworkOffline(false);
      }
    });
  }

  void _stopServerPingTimer() {
    _serverPingTimer?.cancel();
    _serverPingTimer = null;
  }

  /// Returns true for exceptions that indicate a real network problem
  /// (unreachable server, DNS failure, TLS error). Non-network errors like
  /// server 500s or JSON parse failures should not trigger offline mode.
  bool _isLikelyNetworkError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is HandshakeException ||
        error is HttpException;
  }

  /// Go offline due to a network error. Builds offline sections and starts
  /// pinging the server for recovery if the device still has connectivity.
  void _goOffline() {
    if (_networkOffline) return;
    debugPrint('[Library] Network error — going offline');
    _networkOffline = true;
    _buildOfflineSections();
    notifyListeners();
    if (_deviceHasConnectivity && !_manualOffline) _startServerPingTimer();
  }

  void _buildProgressMap(AuthProvider auth) {
    _progressMap = {};
    final userJson = auth.userJson;
    if (userJson == null) return;
    final progressList = userJson['mediaProgress'] as List<dynamic>?;
    if (progressList == null) return;
    for (final mp in progressList) {
      if (mp is Map<String, dynamic>) {
        final itemId = mp['libraryItemId'] as String?;
        final episodeId = mp['episodeId'] as String?;
        if (itemId != null) {
          // For podcast episodes, key is "itemId-episodeId"
          // For books, key is just "itemId"
          final key = episodeId != null ? '$itemId-$episodeId' : itemId;
          _progressMap[key] = mp;
        }
      }
    }
  }

  /// Fetch all libraries and auto-select the default.
  Future<void> loadLibraries() async {
    if (_api == null) return;

    if (isOffline) {
      _buildOfflineSections();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _libraries = await _api!.getLibraries();

      if (_libraries.isNotEmpty) {
        // Prefer last user-selected library, then server default, then first book library
        final savedId = await ScopedPrefs.getString('last_selected_library');
        final defaultId = _auth?.defaultLibraryId;
        if (savedId != null && _libraries.any((l) => l['id'] == savedId)) {
          _selectedLibraryId = savedId;
        } else if (defaultId != null && _libraries.any((l) => l['id'] == defaultId)) {
          _selectedLibraryId = defaultId;
        } else {
          // Prefer a book library as the fallback default
          final bookLibraries = _libraries.where(
              (l) => (l['mediaType'] as String? ?? 'book') != 'podcast').toList();
          _selectedLibraryId = bookLibraries.isNotEmpty
              ? bookLibraries.first['id']
              : _libraries.first['id'];
        }
        await loadPersonalizedView(force: true);
      }
    } catch (e) {
      if (_isLikelyNetworkError(e)) {
        _goOffline();
      } else {
        debugPrint('[Library] Non-network error (staying online): $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Change the selected library and reload data.
  Future<void> selectLibrary(String libraryId) async {
    _selectedLibraryId = libraryId;
    _series = [];
    await ScopedPrefs.setString('last_selected_library', libraryId);
    notifyListeners();
    await loadPersonalizedView(force: true);
  }

  /// Fetch personalized home sections for the selected library.
  /// Deduplicates concurrent calls and enforces a cooldown unless [force] is true.
  Future<void> loadPersonalizedView({bool force = false}) async {
    // If a fetch is already in flight, just await it
    final existing = _personalizedInFlight;
    if (existing != null) {
      await existing;
      return;
    }

    // Skip if within cooldown (same library, not forced)
    if (!force &&
        _lastPersonalizedFetchAt != null &&
        _lastPersonalizedFetchLibraryId == _selectedLibraryId &&
        DateTime.now().difference(_lastPersonalizedFetchAt!) < _personalizedFetchCooldown) {
      return;
    }

    final inFlight = _doLoadPersonalizedView();
    _personalizedInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_personalizedInFlight, inFlight)) {
        _personalizedInFlight = null;
      }
    }
  }

  Future<void> _doLoadPersonalizedView() async {
    if (_api == null || _selectedLibraryId == null) return;

    if (isOffline) {
      _buildOfflineSections();
      return;
    }

    // Only show loading spinner if we have NO existing data.
    // If we already have sections, do a silent background refresh.
    final hadData = _personalizedSections.isNotEmpty;
    if (!hadData) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _lastPersonalizedFetchAt = DateTime.now();
      _lastPersonalizedFetchLibraryId = _selectedLibraryId;
      await _refreshProgress();
      _personalizedSections = await _api!.getPersonalizedView(
        _selectedLibraryId!,
        include: const ['numEpisodesIncomplete'],
      );
      // Cache updatedAt timestamps for cover cache-busting
      for (final section in _personalizedSections) {
        for (final e in (section['entities'] as List<dynamic>? ?? [])) {
          if (e is Map<String, dynamic>) {
            final id = e['id'] as String?;
            final ts = e['updatedAt'] as num?;
            if (id != null && ts != null) _itemUpdatedAt[id] = ts.toInt();
          }
        }
      }
      await _updateAbsorbingCache();
    } catch (e) {
      if (_isLikelyNetworkError(e)) {
        _goOffline();
      } else {
        debugPrint('[Library] Non-network error (staying online): $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshProgress() async {
    if (_api == null) return;
    try {
      final me = await _api!.getMe();
      if (me != null) {
        final progressList = me['mediaProgress'] as List<dynamic>?;
        if (progressList != null) {
          // Preserve locally-set isFinished flags that the server may not
          // have processed yet (e.g. episode just finished, server lags).
          final localFinished = <String, Map<String, dynamic>>{};
          if (_lastFinishedItemId != null && _progressMap.containsKey(_lastFinishedItemId!)) {
            localFinished[_lastFinishedItemId!] = _progressMap[_lastFinishedItemId!]!;
          }
          _progressMap = {};
          for (final mp in progressList) {
            if (mp is Map<String, dynamic>) {
              final itemId = mp['libraryItemId'] as String?;
              final episodeId = mp['episodeId'] as String?;
              if (itemId != null) {
                final key = episodeId != null ? '$itemId-$episodeId' : itemId;
                _progressMap[key] = mp;
              }
            }
          }
          // Re-apply local finished state if the server hasn't caught up
          for (final entry in localFinished.entries) {
            final serverEntry = _progressMap[entry.key];
            final serverHasFinished = serverEntry?['isFinished'] == true;
            if (serverEntry == null || !serverHasFinished) {
              _progressMap[entry.key] = {...?serverEntry, ...entry.value};
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Refresh data (pull-to-refresh).
  Future<void> refresh() async {
    if (isOffline) {
      _buildOfflineSections();
      notifyListeners();
      return;
    }
    // Flush local progress to server first, then pull fresh data
    if (_api != null) {
      await ProgressSyncService().flushPendingSync(api: _api!);
    }
    await Future.wait([
      loadPersonalizedView(force: true),
      _refreshProgress(),
    ]);
    // Clear stale local overrides — server data is now authoritative
    _localProgressOverrides.clear();
    // Update local SharedPreferences from fresh server data so they stay in sync
    final sync = ProgressSyncService();
    for (final entry in _progressMap.entries) {
      final itemId = entry.key;
      final mp = entry.value;
      final currentTime = (mp['currentTime'] as num?)?.toDouble() ?? 0;
      final duration = (mp['duration'] as num?)?.toDouble() ?? 0;
      if (duration > 0 && currentTime > 0) {
        await sync.saveLocal(
          itemId: itemId,
          currentTime: currentTime,
          duration: duration,
          speed: 1.0,
        );
      }
    }
    // Clear pending syncs since we just pulled fresh server data
    await ScopedPrefs.setStringList('pending_syncs', []);
    notifyListeners();
  }

  /// Lightweight refresh for views that only need up-to-date progress.
  /// Avoids expensive personalized shelf rebuilds.
  Future<void> refreshProgressOnly() async {
    if (isOffline || _api == null) return;
    await ProgressSyncService().flushPendingSync(api: _api!);
    await _refreshProgress();
    _localProgressOverrides.clear();
    notifyListeners();
  }

  /// Fetch series for the selected library.
  Future<void> loadSeries({String sort = 'addedAt', int desc = 1}) async {
    if (_api == null || _selectedLibraryId == null) return;

    _isLoadingSeries = true;
    notifyListeners();

    try {
      final result = await _api!.getLibrarySeries(
        _selectedLibraryId!,
        sort: sort,
        desc: desc,
      );
      if (result != null) {
        _series = (result['results'] as List<dynamic>?) ?? [];
      }
    } catch (e) {
      // ignore
    }

    _isLoadingSeries = false;
    notifyListeners();
  }

  /// Register an item's updatedAt timestamp for cover cache-busting.
  void registerUpdatedAt(String id, int ts) => _itemUpdatedAt[id] = ts;

  /// Build a cover URL for an item.
  /// When offline, prefers the locally cached cover file.
  /// For podcast episodes stored under composite keys (e.g. "showId-epId"),
  /// also checks downloads matching the given itemId as a prefix.
  String? getCoverUrl(String? itemId, {int width = 400}) {
    if (itemId == null) return null;

    // For podcast episodes stored under composite keys ("showUUID-episodeId"),
    // extract the show ID for API calls so the server returns the show cover.
    final isCompositeKey = itemId.length > 36;
    final apiItemId = isCompositeKey ? itemId.substring(0, 36) : itemId;

    // Try API first when online
    if (_api != null && !isOffline) {
      final ts = _itemUpdatedAt[apiItemId];
      return _api!.getCoverUrl(apiItemId, width: width, updatedAt: ts);
    }

    // Offline or no API: prefer local cover path
    final dl = DownloadService().getInfo(itemId);
    if (dl.localCoverPath != null) {
      return dl.localCoverPath;
    }

    // For podcast shows, the cover may be stored under a composite episode key.
    // Check if any downloaded episode matches this show ID as a prefix.
    if (dl.status == DownloadStatus.none) {
      final match = DownloadService().downloadedItems
          .where((d) => d.itemId.startsWith('$itemId-') && d.localCoverPath != null)
          .firstOrNull;
      if (match?.localCoverPath != null) {
        return match!.localCoverPath;
      }
    }

    // Fall back to remote URL (may work if CachedNetworkImage has it cached)
    if (_api != null) return _api!.getCoverUrl(apiItemId, width: width);
    return dl.coverUrl;
  }

  /// Headers needed for authenticated media requests (covers, audio).
  /// Returns empty map if no API is available.
  Map<String, String> get mediaHeaders => _api?.mediaHeaders ?? {};

  // ── Manual Absorbing List ──

  Set<String> _manualAbsorbAdds = {};
  Set<String> _manualAbsorbRemoves = {};
  // Persisted ordered list of all book IDs on the absorbing page
  List<String> _absorbingBookIds = [];
  // Cached item data for books that may no longer be in server sections
  Map<String, Map<String, dynamic>> _absorbingItemCache = {};
  // Track last finished item so we can insert next-in-series after it
  String? _lastFinishedItemId;
  // Robust local finished state — survives _refreshProgress rebuilds
  final Set<String> _locallyFinishedItems = {};

  Set<String> get manualAbsorbAdds => _manualAbsorbAdds;
  Set<String> get manualAbsorbRemoves => _manualAbsorbRemoves;
  List<String> get absorbingBookIds => _absorbingBookIds;

  /// Add a key to _absorbingBookIds if not already present.
  /// If [afterKey] is provided and exists, insert right after it —
  /// and reposition the key if it's already in the list elsewhere.
  /// Add a key to _absorbingBookIds.
  /// [atFront] — if true (default), new items go to index 0 (stack behavior).
  ///            Set false for background section refreshes where new items
  ///            should append without disrupting the current order.
  /// [afterKey] — insert right after this key (e.g. next-in-series after
  ///             the finished book). Repositions even if already in list.
  void _absorbingIdsAdd(String key, {String? afterKey, bool atFront = true}) {
    if (afterKey != null) {
      final afterIdx = _absorbingBookIds.indexOf(afterKey);
      if (afterIdx >= 0) {
        _absorbingBookIds.remove(key);
        _absorbingBookIds.insert(afterIdx + 1, key);
        return;
      }
    }
    if (_absorbingBookIds.contains(key)) return;
    if (atFront) {
      _absorbingBookIds.insert(0, key);
    } else {
      _absorbingBookIds.add(key);
    }
  }
  Map<String, Map<String, dynamic>> get absorbingItemCache => _absorbingItemCache;

  Future<void> _loadManualAbsorbing() async {
    _manualAbsorbAdds = (await ScopedPrefs.getStringList('absorbing_manual_adds')).toSet();
    _manualAbsorbRemoves = (await ScopedPrefs.getStringList('absorbing_manual_removes')).toSet();
    _absorbingBookIds = (await ScopedPrefs.getStringList('absorbing_seen_ids')).toList();
    final cacheList = await ScopedPrefs.getStringList('absorbing_item_cache_v2');
    _absorbingItemCache = {};
    for (final s in cacheList) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        // Use _absorbingKey if present (compound key for podcast episodes),
        // otherwise fall back to item id (books / legacy entries)
        final key = m['_absorbingKey'] as String? ?? m['id'] as String?;
        if (key != null) _absorbingItemCache[key] = m;
      } catch (_) {}
    }
  }

  Future<void> _saveManualAbsorbing() async {
    await ScopedPrefs.setStringList('absorbing_manual_adds', _manualAbsorbAdds.toList());
    await ScopedPrefs.setStringList('absorbing_manual_removes', _manualAbsorbRemoves.toList());
    await ScopedPrefs.setStringList('absorbing_seen_ids', _absorbingBookIds.toList());
    await ScopedPrefs.setStringList('absorbing_item_cache_v2',
        _absorbingItemCache.values.map((e) => jsonEncode(e)).toList());
  }

  /// Scans current sections and adds qualifying items to the persisted absorbing list.
  /// Called after each section refresh so finished books stay visible even after
  /// the server removes them from continue-listening.
  ///
  /// For podcasts, each in-progress episode gets its own entry keyed by
  /// "itemId-episodeId" so multiple episodes from the same show appear as
  /// separate cards on the Absorbing screen.
  Future<void> _updateAbsorbingCache() async {
    // Collect IDs currently present in the allowed in-progress sections
    final allowedKeys = <String>{};
    // Map showId -> show entity from sections (for cloning into episode entries)
    final showEntities = <String, Map<String, dynamic>>{};

    // Keys from continue-series that should be positioned after the finished book
    final continueSeriesKeys = <String>[];

    // Snapshot existing IDs so we only reposition truly NEW series continuations
    final existingIds = Set<String>.from(_absorbingBookIds);

    for (final section in _personalizedSections) {
      final id = section['id'] as String? ?? '';
      if (id == 'continue-listening' || id == 'continue-series' ||
          id == 'downloaded-books') {
        final isContinueSeries = id == 'continue-series';
        for (final e in (section['entities'] as List<dynamic>? ?? [])) {
          if (e is Map<String, dynamic>) {
            final itemId = e['id'] as String?;
            if (itemId == null) continue;
            final recentEpisode = e['recentEpisode'] as Map<String, dynamic>?;
            if (recentEpisode != null) {
              // Podcast episode — use compound key
              final episodeId = recentEpisode['id'] as String?;
              if (episodeId != null) {
                final key = '$itemId-$episodeId';
                allowedKeys.add(key);
                showEntities[itemId] = e;
                if (!_manualAbsorbRemoves.contains(key)) {
                  _absorbingIdsAdd(key, atFront: false);
                  _absorbingItemCache[key] = {...e, '_absorbingKey': key};
                  if (isContinueSeries) continueSeriesKeys.add(key);
                }
              }
            } else {
              // Book — use plain itemId
              allowedKeys.add(itemId);
              if (!_manualAbsorbRemoves.contains(itemId)) {
                _absorbingIdsAdd(itemId, atFront: false);
                _absorbingItemCache[itemId] = e;
                if (isContinueSeries) continueSeriesKeys.add(itemId);
              }
            }
          }
        }
      }
    }

    // Reposition continue-series items right after the finished book.
    // Done after all sections so the order is correct regardless of which
    // section the item appeared in first. Only move NEW items — ones already
    // in the list keep their position to avoid shuffling.
    if (_lastFinishedItemId != null && continueSeriesKeys.isNotEmpty) {
      for (final key in continueSeriesKeys) {
        if (!existingIds.contains(key)) {
          _absorbingIdsAdd(key, afterKey: _lastFinishedItemId);
        }
      }
    }

    // For podcast libraries, scan _progressMap for additional in-progress
    // episodes not already represented in continue-listening sections.
    if (isPodcastLibrary) {
      // Collect show IDs we know about (from sections or cache)
      final knownShowIds = <String>{};
      for (final key in _absorbingBookIds) {
        if (key.length > 36) {
          knownShowIds.add(key.substring(0, 36));
        }
      }
      // Also add show entities from sections
      knownShowIds.addAll(showEntities.keys);

      for (final entry in _progressMap.entries) {
        final key = entry.key;
        if (key.length <= 36) continue; // not an episode entry (plain UUID)
        final mp = entry.value;
        if (mp['isFinished'] == true) continue; // skip finished episodes
        final progress = (mp['progress'] as num?)?.toDouble() ?? 0;
        if (progress <= 0) continue; // never actually played

        final showId = key.substring(0, 36);
        final episodeId = key.substring(37);

        if (_absorbingBookIds.contains(key)) continue; // already have it
        if (_manualAbsorbRemoves.contains(key)) continue; // user removed it
        if (!knownShowIds.contains(showId)) continue; // unknown show

        // Find show data to clone
        final showData = showEntities[showId] ?? _absorbingItemCache.values
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (c) => c != null && (c['id'] as String?) == showId,
              orElse: () => null,
            );
        if (showData == null) continue;

        // Create synthetic entry with this episode as recentEpisode
        final duration = (mp['duration'] as num?)?.toDouble() ?? 0;
        final currentTime = (mp['currentTime'] as num?)?.toDouble() ?? 0;
        final syntheticEntry = Map<String, dynamic>.from(showData);
        syntheticEntry['recentEpisode'] = {
          'id': episodeId,
          'duration': duration,
          'currentTime': currentTime,
          // Title will be filled in by _enrichEpisodeTitles
          'title': 'Episode',
        };
        syntheticEntry['_absorbingKey'] = key;
        _absorbingIdsAdd(key, atFront: false);
        _absorbingItemCache[key] = syntheticEntry;
        allowedKeys.add(key);
      }

      // Fetch actual episode titles for synthetic entries (async, non-blocking)
      _enrichEpisodeTitles();
    }

    // Prune stale entries: items that are no longer in the allowed sections,
    // were not manually added, and have no progress recorded (never played).
    final toRemove = <String>[];
    for (final key in _absorbingBookIds) {
      if (allowedKeys.contains(key)) continue; // still in a live section
      if (_manualAbsorbAdds.contains(key)) continue; // user explicitly added it
      // Keep if there is any recorded progress
      final hasProgress = key.length > 36
          ? _progressMap.containsKey(key)
          : _progressMap.keys.any((k) => k == key || k.startsWith('$key-'));
      if (!hasProgress) toRemove.add(key);
    }
    for (final id in toRemove) {
      _absorbingBookIds.remove(id);
      _absorbingItemCache.remove(id);
    }

    // Migrate any old-style plain show IDs that should be compound keys
    // (from before this change). If an entry has recentEpisode, re-key it.
    final migrateRemove = <String>[];
    final migrateAdd = <String, Map<String, dynamic>>{};
    for (final key in _absorbingBookIds) {
      if (key.length > 36) continue; // already compound
      final cached = _absorbingItemCache[key];
      if (cached == null) continue;
      final re = cached['recentEpisode'] as Map<String, dynamic>?;
      if (re == null) continue; // book, not episode
      final epId = re['id'] as String?;
      if (epId == null) continue;
      final newKey = '$key-$epId';
      if (!_absorbingBookIds.contains(newKey)) {
        migrateRemove.add(key);
        migrateAdd[newKey] = {...cached, '_absorbingKey': newKey};
      }
    }
    for (final old in migrateRemove) {
      _absorbingBookIds.remove(old);
      _absorbingItemCache.remove(old);
    }
    for (final entry in migrateAdd.entries) {
      _absorbingIdsAdd(entry.key, atFront: false);
      _absorbingItemCache[entry.key] = entry.value;
    }

    await _saveManualAbsorbing();
  }

  /// Fetch full show data to fill in episode titles for synthetic entries.
  Future<void> _enrichEpisodeTitles() async {
    if (_api == null) return;
    // Collect show IDs that need episode title enrichment
    final needsEnrich = <String, List<String>>{}; // showId -> [episodeId, ...]
    for (final entry in _absorbingItemCache.entries) {
      final ep = entry.value['recentEpisode'] as Map<String, dynamic>?;
      if (ep == null) continue;
      if ((ep['title'] as String?) != 'Episode') continue; // only enrich placeholders
      final showId = entry.value['id'] as String?;
      final epId = ep['id'] as String?;
      if (showId == null || epId == null) continue;
      needsEnrich.putIfAbsent(showId, () => []).add(epId);
    }
    for (final showId in needsEnrich.keys) {
      try {
        final fullItem = await _api!.getLibraryItem(showId);
        if (fullItem == null) continue;
        final media = fullItem['media'] as Map<String, dynamic>? ?? {};
        final episodes = media['episodes'] as List<dynamic>? ?? [];
        for (final epId in needsEnrich[showId]!) {
          final key = '$showId-$epId';
          final cached = _absorbingItemCache[key];
          if (cached == null) continue;
          // Find matching episode
          final ep = episodes.cast<Map<String, dynamic>?>().firstWhere(
            (e) => e != null && (e['id'] as String?) == epId,
            orElse: () => null,
          );
          if (ep != null) {
            cached['recentEpisode'] = Map<String, dynamic>.from(ep);
            _absorbingItemCache[key] = cached;
          }
        }
      } catch (_) {}
    }
    if (needsEnrich.isNotEmpty) {
      await _saveManualAbsorbing();
      notifyListeners();
    }
  }

  /// Add a book to the absorbing list manually.
  Future<void> addToAbsorbing(String itemId) async {
    _manualAbsorbAdds.add(itemId);
    _manualAbsorbRemoves.remove(itemId);
    _absorbingIdsAdd(itemId);
    await _saveManualAbsorbing();
    notifyListeners();
  }

  /// Re-allow an item that was previously removed, so it can reappear in Absorbing.
  /// Called when the user explicitly plays an item that they had removed.
  /// [key] can be a plain itemId (books) or compound "itemId-episodeId" (podcasts).
  void unblockFromAbsorbing(String key, {String? episodeTitle, double? episodeDuration}) {
    // Clear stale finished state so the overlay doesn't persist when replaying
    _localProgressOverrides.remove(key);
    _locallyFinishedItems.remove(key);
    final pm = _progressMap[key];
    if (pm != null && pm['isFinished'] == true) {
      _progressMap[key] = {...pm, 'isFinished': false};
    }
    bool changed = _manualAbsorbRemoves.remove(key);
    final isCompound = key.length > 36;
    if (!_absorbingBookIds.contains(key)) {
      _absorbingIdsAdd(key);
      changed = true;
      // Populate the cache from current sections if available
      final showId = isCompound ? key.substring(0, 36) : key;
      for (final section in _personalizedSections) {
        for (final e in (section['entities'] as List<dynamic>? ?? [])) {
          if (e is Map<String, dynamic> && (e['id'] as String?) == showId) {
            if (isCompound) {
              final episodeId = key.substring(37);
              final cached = Map<String, dynamic>.from(e);
              cached['_absorbingKey'] = key;
              // Ensure recentEpisode points to the correct episode
              cached['recentEpisode'] = {
                ...?(cached['recentEpisode'] as Map<String, dynamic>?),
                'id': episodeId,
                if (episodeTitle != null) 'title': episodeTitle,
                if (episodeDuration != null && episodeDuration > 0) 'duration': episodeDuration,
              };
              _absorbingItemCache[key] = cached;
            } else {
              _absorbingItemCache[key] = e;
            }
            break;
          }
        }
      }
    }
    // Ensure existing cache entry has _absorbingKey and correct recentEpisode
    if (isCompound && _absorbingItemCache.containsKey(key)) {
      final cached = _absorbingItemCache[key]!;
      if (cached['_absorbingKey'] == null) cached['_absorbingKey'] = key;
      final episodeId = key.substring(37);
      final re = cached['recentEpisode'] as Map<String, dynamic>?;
      if (re == null || (re['id'] as String?) != episodeId) {
        cached['recentEpisode'] = {
          ...?re,
          'id': episodeId,
          if (episodeTitle != null) 'title': episodeTitle,
          if (episodeDuration != null && episodeDuration > 0) 'duration': episodeDuration,
        };
      } else if (episodeTitle != null && re['title'] == null) {
        cached['recentEpisode'] = {...re, 'title': episodeTitle};
      }
    }
    if (changed) _saveManualAbsorbing();
  }

  /// Remove a book/episode from the absorbing list manually.
  /// [key] can be a plain itemId (books) or compound "itemId-episodeId" (podcasts).
  Future<void> removeFromAbsorbing(String key) async {
    _manualAbsorbRemoves.add(key);
    _manualAbsorbAdds.remove(key);
    _absorbingBookIds.remove(key);
    _absorbingItemCache.remove(key);
    await _saveManualAbsorbing();
    notifyListeners();
  }

  /// Mark an item as finished locally so the overlay appears immediately,
  /// before the next server refresh confirms isFinished.
  /// [itemId] can be a plain book ID or a compound "showId-episodeId" key.
  /// If [skipRefresh] is true, the caller handles refreshing (e.g.
  /// book_detail_sheet calls refresh() after api.markFinished).
  void markFinishedLocally(String itemId, {bool skipRefresh = false}) {
    if (_resetItems.contains(itemId)) return;
    final existing = _progressMap[itemId] ?? {};
    _progressMap[itemId] = {...existing, 'isFinished': true};
    _localProgressOverrides[itemId] = 1.0;
    _lastFinishedItemId = itemId;
    _locallyFinishedItems.add(itemId);
    // Move finished item to front so the next-in-series/episode lands at index 1
    _absorbingBookIds.remove(itemId);
    _absorbingBookIds.insert(0, itemId);
    // Ensure cache entry has _absorbingKey so the card can extract the episode ID
    if (itemId.length > 36) {
      final cached = _absorbingItemCache[itemId];
      if (cached != null && cached['_absorbingKey'] == null) {
        cached['_absorbingKey'] = itemId;
      }
    }
    notifyListeners();

    // For podcast episodes, fetch the next episode and THEN refresh.
    // This avoids a race where the refresh prunes the newly added episode.
    final isCompound = itemId.length > 36;
    if (isCompound && !skipRefresh && _api != null && !isOffline) {
      // UUIDs are always 36 chars; compound key = "showUUID-episodeId"
      final showId = itemId.substring(0, 36);
      final episodeId = itemId.substring(37);
      _addNextPodcastEpisode(showId, episodeId, itemId).then((_) {
        if (_selectedLibraryId != null && !isOffline) {
          loadPersonalizedView(force: true);
        }
      });
      return; // skip the default refresh below — handled above
    }

    if (!skipRefresh && _api != null && _selectedLibraryId != null && !isOffline) {
      // Brief delay so the server has time to populate continue-series
      Future.delayed(const Duration(milliseconds: 500), () {
        loadPersonalizedView(force: true);
      });
    }
  }

  /// Fetch the podcast show's episode list and insert the next episode
  /// (chronologically after the finished one) into the absorbing list.
  Future<void> _addNextPodcastEpisode(String showId, String finishedEpisodeId, String finishedKey) async {
    // Brief delay so the server has time to register the finished state
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final fullItem = await _api!.getLibraryItem(showId);
      if (fullItem == null) return;
      final media = fullItem['media'] as Map<String, dynamic>? ?? {};
      final episodes = List<dynamic>.from(media['episodes'] as List<dynamic>? ?? []);
      if (episodes.isEmpty) return;

      // Sort oldest-first (ascending publishedAt) so "next" = index + 1
      episodes.sort((a, b) {
        final aTime = (a['publishedAt'] as num?)?.toInt() ?? 0;
        final bTime = (b['publishedAt'] as num?)?.toInt() ?? 0;
        return aTime.compareTo(bTime);
      });

      final currentIdx = episodes.indexWhere(
        (e) => e is Map<String, dynamic> && (e['id'] as String?) == finishedEpisodeId,
      );
      if (currentIdx < 0 || currentIdx >= episodes.length - 1) return;

      final nextEp = episodes[currentIdx + 1] as Map<String, dynamic>;
      final nextEpId = nextEp['id'] as String?;
      if (nextEpId == null) return;

      final nextKey = '$showId-$nextEpId';
      if (_manualAbsorbRemoves.contains(nextKey)) return;
      if (_progressMap[nextKey]?['isFinished'] == true) return;

      // Build a synthetic cache entry from the show data
      final showData = _absorbingItemCache.values
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (c) => c != null && (c['id'] as String?) == showId,
            orElse: () => null,
          ) ?? fullItem;
      final syntheticEntry = Map<String, dynamic>.from(showData);
      syntheticEntry['recentEpisode'] = Map<String, dynamic>.from(nextEp);
      syntheticEntry['_absorbingKey'] = nextKey;

      // Mark as manually added so pruning won't remove it (no progress yet)
      _manualAbsorbAdds.add(nextKey);
      _absorbingIdsAdd(nextKey, afterKey: finishedKey);
      _absorbingItemCache[nextKey] = syntheticEntry;
      await _saveManualAbsorbing();
      notifyListeners();
    } catch (_) {}
  }

  /// Check if a book/episode is on the absorbing page (persisted local list, not removed).
  /// [key] can be a plain itemId (books) or compound "itemId-episodeId" (podcasts).
  bool isOnAbsorbingList(String key) {
    if (_manualAbsorbRemoves.contains(key)) return false;
    return _absorbingBookIds.contains(key);
  }
}
