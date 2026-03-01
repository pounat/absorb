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
  Future<void>? _personalizedInFlight;
  DateTime? _lastPersonalizedFetchAt;
  String? _lastPersonalizedFetchLibraryId;

  static const Duration _personalizedFetchCooldown = Duration(seconds: 5);

  // Offline mode
  bool _manualOffline = false;
  bool _networkOffline = false;
  bool _deviceHasConnectivity = true; // false only when device has no network at all
  Timer? _serverPingTimer;
  bool get isOffline => _manualOffline || _networkOffline;
  bool get isManualOffline => _manualOffline;

  void _logOfflineState(String source, {String? extra}) {
    final suffix = (extra == null || extra.isEmpty) ? '' : ' $extra';
    debugPrint(
      '[Library] $source '
      'manual=$_manualOffline '
      'network=$_networkOffline '
      'deviceNet=$_deviceHasConnectivity '
      'effective=$isOffline '
      'selected=$_selectedLibraryId '
      'sections=${_personalizedSections.length}$suffix',
    );
  }

  bool _isLikelyNetworkError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is HandshakeException ||
        error is HttpException;
  }

  /// Toggle manual offline mode.
  Future<void> setManualOffline(bool value) async {
    _logOfflineState('setManualOffline($value)');
    _manualOffline = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('manual_offline_mode', value);
    if (!value) {
      if (_deviceHasConnectivity) {
        final wasNetworkOffline = _networkOffline;
        _networkOffline = false;
        _stopServerPingTimer();
        _logOfflineState(
          'manual offline disabled',
          extra: 'clearedNetworkOffline=$wasNetworkOffline',
        );

        // Going back online — flush pending syncs and refresh
        if (_api != null) {
          debugPrint('[Library] Manual offline off — flushing pending syncs');
          ProgressSyncService().flushPendingSync(api: _api!);
        }
        if (_selectedLibraryId == null) {
          loadLibraries();
        } else {
          refresh();
        }
        if (wasNetworkOffline) {
          AndroidAutoService().refresh(force: true);
        }
      } else {
        // User disabled manual offline but device has no network.
        setNetworkOffline(true, reason: 'manual-off-disabled-no-connectivity');
      }
    } else {
      // Going offline — show downloaded books
      _buildOfflineSections();
      _logOfflineState('manual offline enabled');
    }
    notifyListeners();
  }

  /// Called on init to restore manual offline preference.
  Future<void> restoreOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    _manualOffline = prefs.getBool('manual_offline_mode') ?? false;
    _logOfflineState('restoreOfflineMode', extra: 'restoredManual=$_manualOffline');
  }

  /// Called when network connectivity changes.
  void setNetworkOffline(bool offline, {String reason = 'unknown'}) {
    final wasOffline = _networkOffline;
    if (wasOffline == offline) {
      _logOfflineState('setNetworkOffline($offline) noop', extra: 'reason=$reason');
      return;
    }

    _networkOffline = offline;
    _logOfflineState('setNetworkOffline($offline)', extra: 'reason=$reason');

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
    _logOfflineState('buildOfflineSections', extra: 'downloads=${downloads.length}');
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
    return _progressMap[itemId];
  }

  /// Get raw progress data for a podcast episode.
  Map<String, dynamic>? getEpisodeProgressData(String itemId, String episodeId) {
    final key = '$itemId-$episodeId';
    if (_resetItems.contains(key)) return null;
    return _progressMap[key];
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
        _personalizedInFlight = null;
        _lastPersonalizedFetchAt = null;
        _lastPersonalizedFetchLibraryId = null;
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

        // Do not trust /ping as an absolute offline signal.
        // Some reverse proxies block /ping while authenticated API calls still work.
        // Reset transient network-offline state and let real API calls decide.
        _networkOffline = false;
        _logOfflineState(
          'auth update reset network offline',
          extra: 'serverReachable=${auth.serverReachable}',
        );

        // If initial reachability probe failed, keep pinging in background,
        // but continue with normal API loading.
        if (!auth.serverReachable) {
          if (_deviceHasConnectivity) _startServerPingTimer();
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
      _logOfflineState('connectivity initial', extra: 'result=$result');
      if (!_deviceHasConnectivity) {
        _stopServerPingTimer();
        setNetworkOffline(true, reason: 'initial-no-connectivity');
      } else if (_networkOffline && !_manualOffline) {
        // Device has connectivity but we're still offline — server was unreachable
        _startServerPingTimer();
      }
    });
    // Then listen for changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final hasConnectivity = !result.contains(ConnectivityResult.none);
      _deviceHasConnectivity = hasConnectivity;
      _logOfflineState('connectivity changed', extra: 'result=$result');
      if (!hasConnectivity) {
        _stopServerPingTimer();
        setNetworkOffline(true, reason: 'connectivity-lost');
      } else if (!_manualOffline) {
        // Connectivity restored — optimistically go online; if server is still
        // down the API call will fail and _goOfflineWithPing() will be called.
        setNetworkOffline(false, reason: 'connectivity-restored');
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
      _logOfflineState('server ping tick');
      final reachable = await ApiService.pingServer(
        serverUrl,
        customHeaders: _auth?.customHeaders ?? {},
      );
      if (reachable) {
        debugPrint('[Library] Server ping succeeded — going online');
        _stopServerPingTimer();
        setNetworkOffline(false, reason: 'ping-succeeded');
      } else {
        debugPrint('[Library] Server ping failed — staying offline');
      }
    });
  }

  void _stopServerPingTimer() {
    _serverPingTimer?.cancel();
    _serverPingTimer = null;
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
      _logOfflineState('loadLibraries aborted (offline)');
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
      debugPrint('[Library] loadLibraries error: $e');
      if (_isLikelyNetworkError(e)) {
        // Network error — auto-switch to offline view
        setNetworkOffline(true, reason: 'loadLibraries-network-error');
      } else {
        // Non-network failures should not force offline mode.
        _errorMessage = 'Failed to load libraries';
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
  Future<void> loadPersonalizedView({bool force = false}) async {
    final existing = _personalizedInFlight;
    if (existing != null) {
      await existing;
      return;
    }

    if (!force &&
        _lastPersonalizedFetchAt != null &&
        _lastPersonalizedFetchLibraryId == _selectedLibraryId &&
        DateTime.now().difference(_lastPersonalizedFetchAt!) <
            _personalizedFetchCooldown) {
      return;
    }

    final inFlight = _loadPersonalizedView();
    _personalizedInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_personalizedInFlight, inFlight)) {
        _personalizedInFlight = null;
      }
    }
  }

  Future<void> _loadPersonalizedView() async {
    if (_api == null || _selectedLibraryId == null) return;

    if (isOffline) {
      _logOfflineState('loadPersonalizedView aborted (offline)');
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
      _personalizedSections =
          await _api!.getPersonalizedView(_selectedLibraryId!);
      await _updateAbsorbingCache();
    } catch (e) {
      debugPrint('[Library] loadPersonalizedView error: $e');
      if (_isLikelyNetworkError(e)) {
        // Network error — auto-switch to offline view
        setNetworkOffline(true, reason: 'loadPersonalizedView-network-error');
      } else {
        // Non-network failures should not force offline mode.
        _errorMessage = 'Failed to load home sections';
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
        }
      }
    } catch (_) {}
  }

  /// Refresh data (pull-to-refresh).
  Future<void> refresh() async {
    if (isOffline) {
      _logOfflineState('refresh aborted (offline)');
      _buildOfflineSections();
      notifyListeners();
      return;
    }
    // Flush local progress to server first, then pull fresh data
    if (_api != null) {
      await ProgressSyncService().flushPendingSync(api: _api!);
    }
    await _refreshProgress();
    await loadPersonalizedView(force: true);
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

  /// Build a cover URL for an item.
  /// When offline, prefers the locally cached cover file.
  /// For podcast episodes stored under composite keys (e.g. "showId-epId"),
  /// also checks downloads matching the given itemId as a prefix.
  String? getCoverUrl(String? itemId, {int width = 400}) {
    if (itemId == null) return null;

    // For podcast episodes stored under composite keys like "showId-ep_xxx",
    // extract the show ID for API calls so the server returns the show cover.
    final isCompositeKey = itemId.contains('-ep_');
    final apiItemId = isCompositeKey
        ? itemId.substring(0, itemId.indexOf('-ep_'))
        : itemId;

    // Try API first when online
    if (_api != null && !isOffline) {
      return _api!.getCoverUrl(apiItemId, width: width);
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

  Set<String> get manualAbsorbAdds => _manualAbsorbAdds;
  Set<String> get manualAbsorbRemoves => _manualAbsorbRemoves;
  List<String> get absorbingBookIds => _absorbingBookIds;

  /// Add a key to _absorbingBookIds if not already present.
  /// If [afterKey] is provided and exists, insert right after it.
  void _absorbingIdsAdd(String key, {String? afterKey}) {
    if (_absorbingBookIds.contains(key)) return;
    if (afterKey != null) {
      final idx = _absorbingBookIds.indexOf(afterKey);
      if (idx >= 0) {
        _absorbingBookIds.insert(idx + 1, key);
        return;
      }
    }
    _absorbingBookIds.add(key);
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

    for (final section in _personalizedSections) {
      final id = section['id'] as String? ?? '';
      if (id == 'continue-listening' || id == 'continue-series' ||
          id == 'downloaded-books') {
        // For continue-series items, insert right after the finished book
        final insertAfter = id == 'continue-series' ? _lastFinishedItemId : null;
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
                  _absorbingIdsAdd(key, afterKey: insertAfter);
                  _absorbingItemCache[key] = {...e, '_absorbingKey': key};
                }
              }
            } else {
              // Book — use plain itemId
              allowedKeys.add(itemId);
              if (!_manualAbsorbRemoves.contains(itemId)) {
                _absorbingIdsAdd(itemId, afterKey: insertAfter);
                _absorbingItemCache[itemId] = e;
              }
            }
          }
        }
      }
    }

    // For podcast libraries, scan _progressMap for additional in-progress
    // episodes not already represented in continue-listening sections.
    if (isPodcastLibrary) {
      // Collect show IDs we know about (from sections or cache)
      final knownShowIds = <String>{};
      for (final key in _absorbingBookIds) {
        if (key.contains('-')) {
          knownShowIds.add(key.split('-').first);
        }
      }
      // Also add show entities from sections
      knownShowIds.addAll(showEntities.keys);

      for (final entry in _progressMap.entries) {
        final key = entry.key;
        if (!key.contains('-')) continue; // not an episode entry
        final mp = entry.value;
        if (mp['isFinished'] == true) continue; // skip finished episodes
        final progress = (mp['progress'] as num?)?.toDouble() ?? 0;
        if (progress <= 0) continue; // never actually played

        final parts = key.split('-');
        final showId = parts[0];
        final episodeId = parts.sublist(1).join('-');

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
        _absorbingIdsAdd(key);
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
      final hasProgress = key.contains('-')
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
      if (key.contains('-')) continue; // already compound
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
      _absorbingIdsAdd(entry.key);
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
  void unblockFromAbsorbing(String key) {
    bool changed = _manualAbsorbRemoves.remove(key);
    if (!_absorbingBookIds.contains(key)) {
      _absorbingIdsAdd(key);
      changed = true;
      // Populate the cache from current sections if available
      final isCompound = key.contains('-');
      final showId = isCompound ? key.split('-').first : key;
      for (final section in _personalizedSections) {
        for (final e in (section['entities'] as List<dynamic>? ?? [])) {
          if (e is Map<String, dynamic> && (e['id'] as String?) == showId) {
            if (isCompound) {
              _absorbingItemCache[key] = {...e, '_absorbingKey': key};
            } else {
              _absorbingItemCache[key] = e;
            }
            break;
          }
        }
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
  /// Then refresh sections so next-in-series appears without navigating away.
  void markFinishedLocally(String itemId) {
    if (_resetItems.contains(itemId)) return;
    final existing = _progressMap[itemId] ?? {};
    _progressMap[itemId] = {...existing, 'isFinished': true};
    _localProgressOverrides[itemId] = 1.0;
    _lastFinishedItemId = itemId;
    notifyListeners();
    // Refresh sections so continue-series items appear immediately
    if (_api != null && _selectedLibraryId != null && !isOffline) {
      loadPersonalizedView(force: true);
    }
  }

  /// Check if a book/episode is on the absorbing page (persisted local list, not removed).
  /// [key] can be a plain itemId (books) or compound "itemId-episodeId" (podcasts).
  bool isOnAbsorbingList(String key) {
    if (_manualAbsorbRemoves.contains(key)) return false;
    return _absorbingBookIds.contains(key);
  }
}
