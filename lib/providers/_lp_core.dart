part of 'library_provider.dart';

mixin _CoreMixin on ChangeNotifier, _StateMixin {
  // ── Rolling download opt-in ──

  bool isRollingDownloadEnabled(String seriesOrShowId) =>
      _rollingDownloadSeries.contains(seriesOrShowId);

  Future<void> enableRollingDownload(String seriesOrShowId) async {
    _rollingDownloadSeries.add(seriesOrShowId);
    await _saveRollingDownloadSeries();
    notifyListeners();
    final playingKey = AudioPlayerService().currentItemId;
    if (playingKey != null) _checkRollingDownloads(playingKey);
  }

  Future<void> disableRollingDownload(String seriesOrShowId) async {
    _rollingDownloadSeries.remove(seriesOrShowId);
    await _saveRollingDownloadSeries();
    notifyListeners();
  }

  Future<void> toggleRollingDownload(String seriesOrShowId) async {
    if (_rollingDownloadSeries.contains(seriesOrShowId)) {
      await disableRollingDownload(seriesOrShowId);
    } else {
      await enableRollingDownload(seriesOrShowId);
    }
  }

  Future<void> _loadRollingDownloadSeries() async {
    _rollingDownloadSeries =
        (await ScopedPrefs.getStringList('rolling_download_series')).toSet();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('rollingDownload')) {
      await prefs.remove('rollingDownload');
    }
  }

  Future<void> _saveRollingDownloadSeries() async {
    await ScopedPrefs.setStringList(
        'rolling_download_series', _rollingDownloadSeries.toList());
  }

  // ── Podcast subscription opt-in ──

  bool isPodcastSubscribed(String podcastId) =>
      _subscribedPodcasts.contains(podcastId);

  Future<void> subscribePodcast(String podcastId) async {
    _subscribedPodcasts.add(podcastId);
    await _saveSubscribedPodcasts();
    final item = await _api?.getLibraryItem(podcastId);
    if (item != null) {
      final media = item['media'] as Map<String, dynamic>? ?? {};
      final episodes = media['episodes'] as List<dynamic>? ?? [];
      final ids = episodes
          .map((e) => (e as Map<String, dynamic>)['id'] as String?)
          .whereType<String>()
          .toSet();
      _knownEpisodeIds[podcastId] = ids;
      _saveKnownEpisodeIds(podcastId);
    }
    notifyListeners();
  }

  Future<void> unsubscribePodcast(String podcastId) async {
    _subscribedPodcasts.remove(podcastId);
    _knownEpisodeIds.remove(podcastId);
    await _saveSubscribedPodcasts();
    await ScopedPrefs.remove('known_episodes_$podcastId');
    notifyListeners();
  }

  Future<void> togglePodcastSubscription(String podcastId) async {
    if (_subscribedPodcasts.contains(podcastId)) {
      await unsubscribePodcast(podcastId);
    } else {
      await subscribePodcast(podcastId);
    }
  }

  Future<void> _loadSubscribedPodcasts() async {
    _subscribedPodcasts =
        (await ScopedPrefs.getStringList('subscribed_podcasts')).toSet();
  }

  Future<void> _saveSubscribedPodcasts() async {
    await ScopedPrefs.setStringList(
        'subscribed_podcasts', _subscribedPodcasts.toList());
  }

  // ── Offline mode ──

  Future<void> setManualOffline(bool value) async {
    debugPrint('[Library] setManualOffline($value)');
    _manualOffline = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('manual_offline_mode', value);
    if (!value) {
      _stopServerPingTimer();
      final serverUrl = _auth?.activeServerUrl ?? _auth?.serverUrl ?? '';
      final reachable = serverUrl.isNotEmpty
          ? await ApiService.pingServer(serverUrl, customHeaders: _auth?.customHeaders ?? {})
              .timeout(const Duration(seconds: 5), onTimeout: () => false)
          : false;
      if (!reachable) {
        debugPrint('[Library] Manual offline off but server unreachable — staying offline');
        _networkOffline = true;
        _buildOfflineSections();
        notifyListeners();
        if (_deviceHasConnectivity) _startServerPingTimer();
        return;
      }
      _networkOffline = false;
      if (_api != null) {
        debugPrint('[Library] Manual offline off — flushing pending syncs');
        ProgressSyncService().flushPendingSync(api: _api!);
        ProgressSyncService().flushOfflineListeningTime(api: _api!);
      }
      if (_selectedLibraryId == null) {
        (this as LibraryProvider).loadLibraries();
      } else {
        (this as LibraryProvider).refresh();
      }
    } else {
      _buildOfflineSections();
    }
    notifyListeners();
  }

  Future<void> restoreOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    _manualOffline = prefs.getBool('manual_offline_mode') ?? false;
  }

  /// User-triggered reconnect attempt for the offline cloud icon. If currently
  /// offline (manual or network), pings the server (local first when enabled)
  /// and flips back online on success. Returns true if online when the call
  /// completes. Sets [isReconnecting] for the duration so the UI can spin.
  Future<bool> tryReconnect() async {
    if (!isOffline) return true;
    if (_isReconnecting) return !isOffline;
    debugPrint('[Library] tryReconnect: manual=$_manualOffline network=$_networkOffline');
    _isReconnecting = true;
    notifyListeners();
    try {
      if (_manualOffline) {
        await setManualOffline(false);
        return !isOffline;
      }
      final auth = _auth;
      if (auth == null) return false;
      if (auth.localServerEnabled && auth.localServerUrl.isNotEmpty) {
        final localReachable = await ApiService.pingServer(
          auth.localServerUrl,
          customHeaders: auth.customHeaders,
        ).timeout(const Duration(seconds: 5), onTimeout: () => false);
        if (localReachable) {
          debugPrint('[Library] tryReconnect: local server reachable');
          await auth.checkLocalServer();
          _stopServerPingTimer();
          setNetworkOffline(false);
          return true;
        }
        if (auth.useLocalServer) {
          debugPrint('[Library] tryReconnect: local unreachable, clearing override');
          auth.clearLocalOverride();
        }
      }
      final serverUrl = auth.serverUrl;
      if (serverUrl == null || serverUrl.isEmpty) return false;
      final reachable = await ApiService.pingServer(
        serverUrl,
        customHeaders: auth.customHeaders,
      ).timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (reachable) {
        debugPrint('[Library] tryReconnect: remote server reachable');
        _stopServerPingTimer();
        setNetworkOffline(false);
        return true;
      }
      debugPrint('[Library] tryReconnect: still unreachable');
      return false;
    } finally {
      _isReconnecting = false;
      notifyListeners();
    }
  }

  void setNetworkOffline(bool offline) {
    final wasOffline = _networkOffline;
    _networkOffline = offline;
    if (offline && !wasOffline) {
      _stopHealthCheckTimer();
      _buildOfflineSections();
      notifyListeners();
      AndroidAutoService().refresh(force: true);
      CarPlayService().refreshTemplates();
      if (_deviceHasConnectivity && !_manualOffline) {
        _startServerPingTimer();
      }
    } else if (!offline && wasOffline && !_manualOffline) {
      _stopServerPingTimer();
      _startHealthCheckTimer();
      PaintingBinding.instance.imageCache.clear();
      if (_api != null) {
        debugPrint('[Library] Back online — flushing pending syncs');
        ProgressSyncService().flushPendingSync(api: _api!);
        ProgressSyncService().flushOfflineListeningTime(api: _api!);
      }
      if (_selectedLibraryId == null) {
        (this as LibraryProvider).loadLibraries();
      } else {
        (this as LibraryProvider).refresh();
      }
      AndroidAutoService().refresh(force: true);
      CarPlayService().refreshTemplates();
    }
  }

  void _buildOfflineSections() {
    final isPodcast = isPodcastLibrary;
    final allDownloads = DownloadService().downloadedItems;
    final downloads = allDownloads
        .where((dl) => (dl.itemId.length > 36) == isPodcast)
        .toList();
    debugPrint(
        '[Library] Building offline sections: ${downloads.length}/${allDownloads.length} downloads (${isPodcast ? "podcast" : "book"})');
    if (downloads.isEmpty) {
      _personalizedSections = [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final continueEntities = <Map<String, dynamic>>[];
    final downloadedEntities = <Map<String, dynamic>>[];
    for (final dl in downloads) {
      double duration = 0;
      List<dynamic> chapters = [];
      String? episodeTitle;
      if (dl.sessionData != null) {
        try {
          final session = jsonDecode(dl.sessionData!) as Map<String, dynamic>;
          duration = (session['duration'] as num?)?.toDouble() ?? 0;
          chapters = session['chapters'] as List<dynamic>? ?? [];
          episodeTitle = session['episodeTitle'] as String? ??
              session['displayTitle'] as String?;
        } catch (_) {}
      }

      final isCompound = dl.itemId.length > 36;
      late final Map<String, dynamic> entity;
      if (isCompound) {
        final showId = dl.itemId.substring(0, 36);
        final episodeId = dl.itemId.substring(37);
        entity = {
          'id': showId,
          '_absorbingKey': dl.itemId,
          'recentEpisode': {
            'id': episodeId,
            'title': episodeTitle ?? dl.title ?? 'Episode',
            'duration': duration,
            'chapters': chapters,
          },
          'media': {
            'metadata': {
              'title': dl.title ?? 'Unknown Title',
              'authorName': dl.author ?? '',
            },
            'duration': duration,
            'chapters': chapters,
          },
        };
      } else {
        entity = {
          'id': dl.itemId,
          'media': {
            'metadata': {
              'title': dl.title ?? 'Unknown Title',
              'authorName': dl.author ?? '',
            },
            'duration': duration,
            'chapters': chapters,
          },
        };
      }

      final progress = _resetItems.contains(dl.itemId)
          ? 0.0
          : _localProgressOverrides[dl.itemId] ??
              (_progressMap[dl.itemId]?['progress'] as num?)?.toDouble() ??
              0.0;
      final isFinished =
          _progressMap[dl.itemId]?['isFinished'] == true || progress >= 0.999;

      if (progress > 0 && !isFinished) {
        continueEntities.add(entity);
      } else {
        downloadedEntities.add(entity);
      }
    }

    _personalizedSections = [
      if (continueEntities.isNotEmpty)
        {
          'id': 'continue-listening',
          'label': 'Continue Listening',
          'type': isPodcast ? 'podcast' : 'book',
          'entities': continueEntities,
        },
      if (downloadedEntities.isNotEmpty)
        {
          'id': 'downloaded-books',
          'label': isPodcast ? 'Downloaded Episodes' : 'Downloaded Books',
          'type': isPodcast ? 'podcast' : 'book',
          'entities': downloadedEntities,
        },
    ];
    _errorMessage = null;
    _isLoading = false;
  }

  void _onDownloadsChanged() {
    if (isOffline || _personalizedSections.isEmpty) return;
    _personalizedSections = _personalizedSections
        .where((s) => (s as Map)['id'] != 'downloaded-books')
        .toList();
    _injectDownloadedSection();
    notifyListeners();
  }

  void _injectDownloadedSection() {
    final isPodcast = isPodcastLibrary;
    final allDownloads = DownloadService().downloadedItems;
    final downloads = allDownloads
        .where((dl) => (dl.itemId.length > 36) == isPodcast)
        .toList();
    if (downloads.isEmpty) return;

    final entities = <Map<String, dynamic>>[];
    for (final dl in downloads) {
      double duration = 0;
      List<dynamic> chapters = [];
      String? episodeTitle;
      if (dl.sessionData != null) {
        try {
          final session = jsonDecode(dl.sessionData!) as Map<String, dynamic>;
          duration = (session['duration'] as num?)?.toDouble() ?? 0;
          chapters = session['chapters'] as List<dynamic>? ?? [];
          episodeTitle = session['episodeTitle'] as String? ??
              session['displayTitle'] as String?;
        } catch (_) {}
      }

      final isCompound = dl.itemId.length > 36;
      if (isCompound) {
        final showId = dl.itemId.substring(0, 36);
        final episodeId = dl.itemId.substring(37);
        entities.add({
          'id': showId,
          '_absorbingKey': dl.itemId,
          'recentEpisode': {
            'id': episodeId,
            'title': episodeTitle ?? dl.title ?? 'Episode',
            'duration': duration,
            'chapters': chapters,
          },
          'media': {
            'metadata': {
              'title': dl.title ?? 'Unknown Title',
              'authorName': dl.author ?? '',
            },
            'duration': duration,
            'chapters': chapters,
          },
        });
      } else {
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
    }

    _personalizedSections.add({
      'id': 'downloaded-books',
      'label': isPodcast ? 'Downloaded Episodes' : 'Downloaded Books',
      'type': isPodcast ? 'podcast' : 'book',
      'entities': entities,
    });
  }

  // ── Progress ──

  double getProgress(String? itemId) {
    if (itemId == null) return 0;
    if (_resetItems.contains(itemId)) return 0;
    final local = _localProgressOverrides[itemId];
    if (local != null) return local;
    final mp = _progressMap[itemId];
    if (mp == null) return 0;
    return (mp['progress'] as num?)?.toDouble() ?? 0;
  }

  double getEpisodeProgress(String itemId, String episodeId) {
    final key = '$itemId-$episodeId';
    if (_resetItems.contains(key)) return 0;
    final local = _localProgressOverrides[key];
    if (local != null) return local;
    final mp = _progressMap[key];
    if (mp == null) return 0;
    return (mp['progress'] as num?)?.toDouble() ?? 0;
  }

  Map<String, dynamic>? getProgressData(String? itemId) {
    if (itemId == null) return null;
    if (_resetItems.contains(itemId)) return null;
    final data = _progressMap[itemId];
    if (_locallyFinishedItems.contains(itemId)) {
      debugPrint('[Progress] getProgressData($itemId) — forcing isFinished from local override (server isFinished=${data?['isFinished']})');
      return {...?data, 'isFinished': true};
    }
    return data;
  }

  Map<String, dynamic>? getEpisodeProgressData(
      String itemId, String episodeId) {
    final key = '$itemId-$episodeId';
    if (_resetItems.contains(key)) return null;
    final data = _progressMap[key];
    if (_locallyFinishedItems.contains(key)) {
      return {...?data, 'isFinished': true};
    }
    return data;
  }

  Future<void> refreshLocalProgress() async {
    final sync = ProgressSyncService();
    final itemIds = <String>{..._progressMap.keys};
    for (final dl in DownloadService().downloadedItems) {
      itemIds.add(dl.itemId);
    }
    for (final itemId in itemIds) {
      if (_locallyFinishedItems.contains(itemId)) continue;
      if (_resetItems.contains(itemId)) continue;
      final serverFinished = _progressMap[itemId]?['isFinished'] == true;
      final data = await sync.getLocal(itemId);
      if (data != null) {
        final currentTime = (data['currentTime'] as num?)?.toDouble() ?? 0;
        final duration = (data['duration'] as num?)?.toDouble() ?? 0;
        if (duration > 0) {
          final progress = (currentTime / duration).clamp(0.0, 1.0);
          if (progress >= 0.99 && !serverFinished) continue;
          if (serverFinished) continue;
          _localProgressOverrides[itemId] = progress;
          if (currentTime > 0) _resetItems.remove(itemId);
        }
      }
    }
    notifyListeners();
  }

  void clearProgressFor(String itemId) {
    _progressMap.remove(itemId);
    _localProgressOverrides.remove(itemId);
    notifyListeners();
  }

  void resetProgressFor(String itemId) {
    _progressMap.remove(itemId);
    _localProgressOverrides.remove(itemId);
    _locallyFinishedItems.remove(itemId);
    _resetItems.add(itemId);
    notifyListeners();
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
          final key = episodeId != null ? '$itemId-$episodeId' : itemId;
          _progressMap[key] = mp;
        }
      }
    }
  }

  Future<void> _refreshProgress() async {
    if (_api == null) return;
    try {
      final me = await _api!.getMe();
      if (me != null) {
        final progressList = me['mediaProgress'] as List<dynamic>?;
        if (progressList != null) {
          final localFinished = <String, Map<String, dynamic>>{};
          if (_lastFinishedItemId != null &&
              _progressMap.containsKey(_lastFinishedItemId!)) {
            localFinished[_lastFinishedItemId!] =
                _progressMap[_lastFinishedItemId!]!;
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
          for (final entry in localFinished.entries) {
            final serverEntry = _progressMap[entry.key];
            final serverHasFinished = serverEntry?['isFinished'] == true;
            if (serverEntry == null || !serverHasFinished) {
              _progressMap[entry.key] = {...?serverEntry, ...entry.value};
            }
          }
          if (_locallyFinishedItems.isNotEmpty) {
            debugPrint('[Progress] locallyFinished before cleanup: $_locallyFinishedItems');
          }
          if (_localProgressOverrides.isNotEmpty) {
            debugPrint('[Progress] localOverrides before cleanup: ${_localProgressOverrides.keys.toList()}');
          }
          _locallyFinishedItems.removeWhere((key) {
            final serverData = _progressMap[key];
            if (serverData?['isFinished'] == true) {
              debugPrint('[Progress] Clearing local finished (server confirmed): $key');
              return true;
            }
            if (serverData != null && serverData['isFinished'] == false) {
              debugPrint('[Progress] Clearing local finished (server says not finished): $key');
              return true;
            }
            debugPrint('[Progress] Keeping local finished (no server data): $key');
            return false;
          });
          final overridesBefore = _localProgressOverrides.length;
          _localProgressOverrides.removeWhere((key, localProgress) {
            if (_locallyFinishedItems.contains(key)) return false;
            // Keep the override if local progress is ahead of server
            final serverProgress = ((_progressMap[key]?['progress'] as num?)?.toDouble()) ?? 0;
            if (localProgress > serverProgress + 0.001) return false;
            return true;
          });
          final cleared = overridesBefore - _localProgressOverrides.length;
          if (cleared > 0) {
            debugPrint('[Progress] Cleared $cleared overrides');
          }
        }
      }
    } catch (_) {}
  }

  // ── Connectivity ──

  void _startConnectivityMonitoring() {
    _connectivitySub?.cancel();
    Connectivity().checkConnectivity().then((result) {
      _deviceHasConnectivity = !result.contains(ConnectivityResult.none);
      if (!_deviceHasConnectivity) {
        _stopServerPingTimer();
        _stopLocalProbeTimer();
        setNetworkOffline(true);
      } else if (_networkOffline && !_manualOffline) {
        _auth?.checkLocalServer().then((_) {
          if (_auth?.serverReachable == true || _auth?.useLocalServer == true) {
            setNetworkOffline(false);
          } else {
            _startServerPingTimer();
          }
          _startLocalProbeTimer();
        });
      } else if (_deviceHasConnectivity) {
        _startLocalProbeTimer();
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) async {
      final hasConnectivity = !result.contains(ConnectivityResult.none);
      _deviceHasConnectivity = hasConnectivity;
      if (!hasConnectivity) {
        _stopServerPingTimer();
        _stopLocalProbeTimer();
        setNetworkOffline(true);
        // Don't flip the local/remote choice here. The local server may still
        // be reachable on a lower-priority interface (e.g. wifi briefly drops
        // out of the connectivity list during scans). The probe timer decides.
        return;
      }
      if (_manualOffline) return;

      // Got connectivity back - re-probe and potentially come online.
      // We pick the active server based on actual reachability, not on
      // whether the connectivity list happens to contain wifi this tick.
      final activeUrl = _auth?.activeServerUrl ?? _auth?.serverUrl ?? '';
      final reachable = activeUrl.isNotEmpty
          ? await ApiService.pingServer(activeUrl, customHeaders: _auth?.customHeaders ?? {})
              .timeout(const Duration(seconds: 5), onTimeout: () => false)
          : false;
      if (reachable) {
        setNetworkOffline(false);
        if (_rollingDownloadSeries.isNotEmpty) _catchUpRollingDownloads();
        _catchUpQueueAutoDownloads();
        (this as LibraryProvider).catchUpSubscribedPodcasts();
      } else {
        debugPrint('[Library] Connectivity changed but server unreachable — starting ping timer');
        if (_networkOffline) {
          _startServerPingTimer();
        } else {
          _goOffline();
        }
      }
      _startLocalProbeTimer();
    });
  }

  void _startServerPingTimer() {
    _serverPingTimer?.cancel();
    if (_isBackgrounded) return;
    final serverUrl = _auth?.serverUrl;
    if (serverUrl == null) return;
    debugPrint('[Library] Starting server ping timer');
    _serverPingTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!_networkOffline || _manualOffline) {
        _stopServerPingTimer();
        return;
      }
      final auth = _auth;
      if (auth != null && auth.localServerEnabled && auth.localServerUrl.isNotEmpty) {
        final localReachable = await ApiService.pingServer(
          auth.localServerUrl,
          customHeaders: auth.customHeaders,
        ).timeout(const Duration(seconds: 3), onTimeout: () => false);
        if (localReachable) {
          debugPrint('[Library] Local server ping succeeded — going online');
          await auth.checkLocalServer();
          _stopServerPingTimer();
          setNetworkOffline(false);
          return;
        }
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

  // ── Local server reachability probe ──
  //
  // Replaces the old "react to every onConnectivityChanged event" switching,
  // which would flap between local and remote whenever the connectivity list
  // briefly dropped wifi (signal blips, mobile interface coming up, etc).
  // Polls every 30s with hysteresis: 2 consecutive failures to switch off
  // local, 1 success to switch back on. Skips the ping if some other code
  // path (progress sync, health check) already proved local is reachable
  // within the past 25s.
  static const _localProbeInterval = Duration(seconds: 30);
  static const _localProbeFailuresToFlip = 2;
  static const _localProbePiggybackWindow = Duration(seconds: 25);

  void _startLocalProbeTimer() {
    final auth = _auth;
    if (auth == null) return;
    if (!auth.localServerEnabled || auth.localServerUrl.isEmpty) {
      _stopLocalProbeTimer();
      return;
    }
    // Don't run when truly idle in the background (battery).
    if (_isBackgrounded && !AudioPlayerService().isPlaying) {
      _stopLocalProbeTimer();
      return;
    }
    if (_localProbeTimer != null) return;
    _localProbeFailures = 0;
    _localProbeTimer = Timer.periodic(_localProbeInterval, (_) => _probeLocalServer());
  }

  void _stopLocalProbeTimer() {
    _localProbeTimer?.cancel();
    _localProbeTimer = null;
    _localProbeFailures = 0;
  }

  /// Mark local-server reachability based on a successful API call, so the
  /// next probe tick can skip its own ping. Call sites: progress sync ok,
  /// health check ok - anything that confirms the active server responded.
  void notifyServerReachable(String url) {
    final auth = _auth;
    if (auth == null) return;
    if (auth.localServerUrl.isEmpty) return;
    if (url == auth.localServerUrl) {
      _localLastReachableAt = DateTime.now();
      _localProbeFailures = 0;
    }
  }

  Future<void> _probeLocalServer() async {
    final auth = _auth;
    if (auth == null || _manualOffline) return;
    if (!auth.localServerEnabled || auth.localServerUrl.isEmpty) {
      _stopLocalProbeTimer();
      return;
    }
    // Piggy-back: skip if another path proved reachability recently.
    final last = _localLastReachableAt;
    if (auth.useLocalServer && last != null &&
        DateTime.now().difference(last) < _localProbePiggybackWindow) {
      return;
    }

    final reachable = await ApiService.pingServer(
      auth.localServerUrl,
      customHeaders: auth.customHeaders,
    ).timeout(const Duration(seconds: 3), onTimeout: () => false);

    if (auth.useLocalServer) {
      if (reachable) {
        _localLastReachableAt = DateTime.now();
        _localProbeFailures = 0;
      } else {
        _localProbeFailures++;
        if (_localProbeFailures >= _localProbeFailuresToFlip) {
          debugPrint('[Library] Local probe failed ${_localProbeFailures}x — switching to remote');
          auth.clearLocalOverride();
          _localProbeFailures = 0;
        } else {
          debugPrint('[Library] Local probe miss ${_localProbeFailures}/$_localProbeFailuresToFlip');
        }
      }
    } else if (reachable) {
      debugPrint('[Library] Local probe succeeded — switching to local');
      await auth.checkLocalServer();
      _localLastReachableAt = DateTime.now();
      _localProbeFailures = 0;
    }
  }

  // ── Health check (proactive reachability verification while online) ──
  //
  // The offline state only flips via explicit triggers (connectivity change,
  // ping timer success, manual toggle). HTTP 5xx bursts and socket connect
  // failures don't feed back, so during a server outage the cloud icon stays
  // green until the next explicit event. This periodic ping closes that gap.

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    if (_isBackgrounded) return;
    debugPrint('[Library] Health check timer started (60s ping while online)');
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (_networkOffline || _manualOffline || !_deviceHasConnectivity) return;
      final serverUrl = _auth?.activeServerUrl ?? _auth?.serverUrl ?? '';
      if (serverUrl.isEmpty) return;
      final reachable = await ApiService.pingServer(
        serverUrl,
        customHeaders: _auth?.customHeaders ?? {},
      ).timeout(const Duration(seconds: 10), onTimeout: () => false);
      if (!reachable) {
        debugPrint('[Library] Health check failed — server unreachable, going offline');
        setNetworkOffline(true);
      } else {
        notifyServerReachable(serverUrl);
      }
    });
  }

  void _stopHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  // ── Battery-saving lifecycle ──

  void onAppBackgrounded() {
    _isBackgrounded = true;
    _stopServerPingTimer();
    _stopHealthCheckTimer();
    if (!AudioPlayerService().isPlaying) {
      _stopLocalProbeTimer();
    }
    _idleDisconnectTimer?.cancel(); // No timers in background
    _idleDisconnectTimer = null;
    _softDisconnectSocket(); // Always disconnect, even during playback
  }

  void onAppForegrounded() {
    _isBackgrounded = false;
    _softReconnectSocket();
    if (_networkOffline && _deviceHasConnectivity && !_manualOffline) {
      _startServerPingTimer();
    } else if (!_networkOffline && !_manualOffline) {
      _startHealthCheckTimer();
    }
    _startLocalProbeTimer();
    _restartIdleTimer();
    if (!isOffline && !_manualOffline) {
      (this as LibraryProvider).checkSubscribedPodcasts();
    }
  }

  void _restartIdleTimer() {
    _idleDisconnectTimer?.cancel();
    _idleDisconnectTimer = Timer(_StateMixin._idleTimeout, () {
      if (!AudioPlayerService().isPlaying && !ChromecastService().isPlaying) {
        _softDisconnectSocket();
      }
    });
  }

  void onPlaybackStarted() {
    if (!_isBackgrounded) {
      _softReconnectSocket();
    } else {
    }
    _idleDisconnectTimer?.cancel();
    _startLocalProbeTimer();
  }

  void onPlaybackStopped() {
    if (_isBackgrounded) {
      _softDisconnectSocket();
      _stopLocalProbeTimer();
    } else {
      _restartIdleTimer();
    }
  }

  void _softDisconnectSocket() {
    if (_socketSoftDisconnected || _manualOffline) return;
    _socketSoftDisconnected = true;
    SocketService().softDisconnect();
  }

  void _softReconnectSocket() {
    if (_manualOffline) return;
    if (!_socketSoftDisconnected && !SocketService().hasSocket) {
      _socketSoftDisconnected = true;
    }
    if (!_socketSoftDisconnected) return;
    _socketSoftDisconnected = false;
    SocketService().softReconnect();
  }

  void _onSocketReconnectFailed() {
    debugPrint('[Library] Socket reconnection failed — going offline');
    _goOffline();
  }

  void _goOffline() {
    if (_networkOffline) return;
    debugPrint('[Library] Network error — going offline');
    _networkOffline = true;
    _buildOfflineSections();
    notifyListeners();
    if (_deviceHasConnectivity && !_manualOffline) _startServerPingTimer();
  }

  // ── Socket event handlers ──

  void _onRemoteProgressUpdated(Map<String, dynamic> mp) {
    final itemId = mp['libraryItemId'] as String?;
    final episodeId = mp['episodeId'] as String?;
    if (itemId == null) return;
    final key = episodeId != null ? '$itemId-$episodeId' : itemId;
    if (_locallyFinishedItems.contains(key) && mp['isFinished'] != true) return;
    final player = AudioPlayerService();
    final playingKey = player.currentEpisodeId != null
        ? '${player.currentItemId}-${player.currentEpisodeId}'
        : player.currentItemId;
    if (key == playingKey && player.hasBook && player.isPlaying) {
      if (mp['isFinished'] == true) {
        (this as _AbsorbingMixin).markFinishedLocally(key, skipAutoAdvance: true);
      }
      return;
    }
    _progressMap[key] = mp;
    _localProgressOverrides.remove(key);
    _resetItems.remove(key);
    notifyListeners();

    _progressRefreshDebounce?.cancel();
    _progressRefreshDebounce = Timer(const Duration(seconds: 2), () {
      refreshProgressShelves(reason: 'remote-progress');
    });
  }

  void _onRemoteItemUpdated(Map<String, dynamic> data) {
    // Update cover cache buster timestamp
    final id = data['id'] as String?;
    final ts = data['updatedAt'] as num?;
    if (id != null && ts != null) _itemUpdatedAt[id] = ts.toInt();
    if (id != null) {
      final coverPath = (data['media'] as Map<String, dynamic>?)?['coverPath'] as String?;
      registerHasCover(id, coverPath != null && coverPath.isNotEmpty);
    }
    // Invalidate cached session metadata - track URLs may have changed
    if (id != null) SessionCache.clear(itemId: id);
    loadPersonalizedView(force: true);
    _checkSubscribedPodcastUpdate(data);
  }

  void _onRemoteItemRemoved(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    if (id != null) SessionCache.clear(itemId: id);
    loadPersonalizedView(force: true);
  }

  void _onRemoteSeriesUpdated() {
    loadPersonalizedView(force: true);
    (this as LibraryProvider).loadSeries();
  }

  void _onRemoteCollectionUpdated() {
    loadPersonalizedView(force: true);
    loadCollections();
  }

  void _onRemoteUserUpdated(Map<String, dynamic> data) {
    // Sync bookmarks from user_updated event
    final bookmarks = data['bookmarks'] as List<dynamic>?;
    if (bookmarks != null && _api != null) {
      // Group server bookmarks by libraryItemId
      final byItem = <String, List<Map<String, dynamic>>>{};
      for (final b in bookmarks) {
        if (b is Map<String, dynamic>) {
          final id = b['libraryItemId'] as String? ?? '';
          if (id.isNotEmpty) byItem.putIfAbsent(id, () => []).add(b);
        }
      }
      // Sync each item that has bookmarks, plus the currently playing item
      final player = AudioPlayerService();
      final currentId = player.currentItemId;
      final idsToSync = <String>{...byItem.keys};
      if (currentId != null) idsToSync.add(currentId);
      for (final itemId in idsToSync) {
        BookmarkService().syncBookmarks(itemId, _api!,
          preloadedServerBookmarks: byItem[itemId] ?? []);
      }
    }

    final progressList = data['mediaProgress'] as List<dynamic>?;
    if (progressList != null) {
      final player = AudioPlayerService();
      final playingKey = player.currentEpisodeId != null
          ? '${player.currentItemId}-${player.currentEpisodeId}'
          : player.currentItemId;
      for (final mp in progressList) {
        if (mp is Map<String, dynamic>) {
          final itemId = mp['libraryItemId'] as String?;
          final episodeId = mp['episodeId'] as String?;
          if (itemId != null) {
            final key = episodeId != null ? '$itemId-$episodeId' : itemId;
            if (_locallyFinishedItems.contains(key) && mp['isFinished'] != true) continue;
            if (key == playingKey && player.hasBook) continue;
            _progressMap[key] = mp;
            _localProgressOverrides.remove(key);
          }
        }
      }
      notifyListeners();
    } else {
      _progressRefreshDebounce?.cancel();
      _progressRefreshDebounce = Timer(const Duration(milliseconds: 800), () {
        refreshProgressShelves(force: true, reason: 'user-updated');
      });
    }
  }

  // ── Personalized home view ──

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
            _StateMixin._personalizedFetchCooldown) {
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
      for (final section in _personalizedSections) {
        for (final e in (section['entities'] as List<dynamic>? ?? [])) {
          if (e is Map<String, dynamic>) {
            final id = e['id'] as String?;
            final ts = e['updatedAt'] as num?;
            if (id != null && ts != null) _itemUpdatedAt[id] = ts.toInt();
            if (id != null) {
              final coverPath = (e['media'] as Map<String, dynamic>?)?['coverPath'] as String?;
              registerHasCover(id, coverPath != null && coverPath.isNotEmpty);
            }
          }
        }
      }
      await (this as _AbsorbingMixin)._updateAbsorbingCache();

      _injectDownloadedSection();

      if (isPodcastLibrary) {
        _hydrateRssFeedFieldsDeferred();
      }

      loadPlaylists();
      loadCollections();
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

  Future<void> refreshProgressShelves({
    bool force = false,
    String reason = 'unknown',
  }) async {
    if (_api == null || _selectedLibraryId == null || isOffline) return;
    if (_personalizedSections.isEmpty) {
      await loadPersonalizedView(force: force);
      return;
    }

    final existing = _progressShelvesInFlight;
    if (existing != null) {
      await existing;
      return;
    }

    if (!force &&
        _lastProgressShelvesFetchAt != null &&
        _lastProgressShelvesLibraryId == _selectedLibraryId &&
        DateTime.now().difference(_lastProgressShelvesFetchAt!) <
            _StateMixin._progressShelvesFetchCooldown) {
      return;
    }

    final inFlight = _loadProgressShelves(reason: reason);
    _progressShelvesInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_progressShelvesInFlight, inFlight)) {
        _progressShelvesInFlight = null;
      }
    }
  }

  Future<void> _loadProgressShelves({required String reason}) async {
    final api = _api;
    final libraryId = _selectedLibraryId;
    if (api == null || libraryId == null) return;

    try {
      final sections = await api.getPersonalizedView(
        libraryId,
        include: const ['numEpisodesIncomplete'],
        shelves: _StateMixin._progressDrivenShelfIds,
        limit: 10,
      );
      _lastProgressShelvesFetchAt = DateTime.now();
      _lastProgressShelvesLibraryId = libraryId;
      if (_selectedLibraryId != libraryId || isOffline) return;

      _mergeProgressShelves(sections);
      await (this as _AbsorbingMixin)._updateAbsorbingCache();
      notifyListeners();
      debugPrint(
          '[Library] refreshProgressShelves reason=$reason sections=${sections.length}');
    } catch (e) {
      debugPrint('[Library] refreshProgressShelves error ($reason): $e');
    }
  }

  void _mergeProgressShelves(List<dynamic> sections) {
    final updatedById = <String, dynamic>{};
    for (final section in sections) {
      if (section is Map<String, dynamic>) {
        final id = section['id'] as String?;
        if (id != null && _StateMixin._progressDrivenShelfIds.contains(id)) {
          updatedById[id] = section;
        }
      }
    }

    final merged = <dynamic>[];
    final seen = <String>{};
    for (final section in _personalizedSections) {
      if (section is! Map<String, dynamic>) {
        merged.add(section);
        continue;
      }
      final id = section['id'] as String?;
      if (id == null) {
        merged.add(section);
        continue;
      }
      if (_StateMixin._progressDrivenShelfIds.contains(id)) {
        final replacement = updatedById[id];
        if (replacement != null) {
          merged.add(replacement);
          seen.add(id);
        }
      } else {
        merged.add(section);
      }
    }

    for (final id in _StateMixin._progressDrivenShelfIds) {
      final replacement = updatedById[id];
      if (replacement != null && !seen.contains(id)) {
        merged.add(replacement);
      }
    }

    _personalizedSections = merged;
  }

  void _hydrateRssFeedFieldsDeferred() {
    final api = _api;
    final libraryId = _selectedLibraryId;
    if (api == null || libraryId == null || isOffline) return;
    if (_rssHydrationInFlight) return;

    final now = DateTime.now();
    if (_lastRssHydrationLibraryId == libraryId &&
        _lastRssHydrationAt != null &&
        now.difference(_lastRssHydrationAt!) < _StateMixin._rssHydrationCooldown) {
      return;
    }

    _rssHydrationInFlight = true;
    unawaited(() async {
      try {
        final sections = await api.getPersonalizedView(
          libraryId,
          include: const ['numEpisodesIncomplete', 'rssfeed'],
        );
        _lastRssHydrationAt = DateTime.now();
        _lastRssHydrationLibraryId = libraryId;

        if (_selectedLibraryId == libraryId && sections.isNotEmpty) {
          _personalizedSections = sections;
          await (this as _AbsorbingMixin)._updateAbsorbingCache();
          notifyListeners();
        }
      } catch (_) {
      } finally {
        _rssHydrationInFlight = false;
      }
    }());
  }

  // ── Playlists ──

  Future<void> loadPlaylists({bool force = false}) async {
    if (_api == null || _selectedLibraryId == null || isOffline) return;

    final existing = _playlistsInFlight;
    if (existing != null) {
      await existing;
      return;
    }

    final inFlight = _doLoadPlaylists();
    _playlistsInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_playlistsInFlight, inFlight)) {
        _playlistsInFlight = null;
      }
    }
  }

  Future<void> _doLoadPlaylists() async {
    _isLoadingPlaylists = true;
    try {
      _playlists = await _api!.getLibraryPlaylists(_selectedLibraryId!);
    } catch (_) {}
    _isLoadingPlaylists = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createPlaylist(String name) async {
    if (_api == null || _selectedLibraryId == null) return null;
    final result = await _api!.createPlaylist(_selectedLibraryId!, name);
    if (result != null) {
      _playlists = [..._playlists, result];
      notifyListeners();
    }
    return result;
  }

  Future<bool> addToPlaylist(
    String playlistId,
    String libraryItemId, {
    String? episodeId,
  }) async {
    if (_api == null) return false;
    final updated = await _api!.addItemToPlaylist(
      playlistId, libraryItemId, episodeId: episodeId,
    );
    if (updated != null) {
      await _doLoadPlaylists();
      return true;
    }
    return false;
  }

  Future<bool> removeFromPlaylist(
    String playlistId,
    String libraryItemId, {
    String? episodeId,
  }) async {
    if (_api == null) return false;
    final updated = await _api!.removeItemFromPlaylist(
      playlistId, libraryItemId, episodeId: episodeId,
    );
    if (updated != null) {
      await _doLoadPlaylists();
      return true;
    }
    return false;
  }

  Future<bool> reorderPlaylistItems(
    String playlistId,
    List<Map<String, dynamic>> reorderedItems,
  ) async {
    if (_api == null) return false;
    final itemRefs = reorderedItems.map((item) {
      final ref = <String, dynamic>{'libraryItemId': item['libraryItemId']};
      final eid = item['episodeId'] as String?;
      if (eid != null) ref['episodeId'] = eid;
      return ref;
    }).toList();
    final updated = await _api!.updatePlaylist(playlistId, items: itemRefs);
    if (updated != null) {
      await _doLoadPlaylists();
      return true;
    }
    return false;
  }

  Future<bool> deletePlaylist(String playlistId) async {
    if (_api == null) return false;
    final ok = await _api!.deletePlaylist(playlistId);
    if (ok) {
      _playlists = _playlists.where((p) => (p as Map)['id'] != playlistId).toList();
      _hiddenSectionIds.remove('playlist:$playlistId');
      _sectionOrder.remove('playlist:$playlistId');
      await _saveSectionPrefs();
      notifyListeners();
    }
    return ok;
  }

  // ── Collections ──

  Future<void> loadCollections({bool force = false}) async {
    if (_api == null || _selectedLibraryId == null || isOffline) return;

    final existing = _collectionsInFlight;
    if (existing != null) {
      await existing;
      return;
    }

    final inFlight = _doLoadCollections();
    _collectionsInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_collectionsInFlight, inFlight)) {
        _collectionsInFlight = null;
      }
    }
  }

  Future<void> _doLoadCollections() async {
    _isLoadingCollections = true;
    try {
      _collections = await _api!.getLibraryCollections(_selectedLibraryId!);
    } catch (_) {}
    _isLoadingCollections = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createCollection(String name, {List<String> books = const []}) async {
    if (_api == null || _selectedLibraryId == null) return null;
    final result = await _api!.createCollection(_selectedLibraryId!, name, books: books);
    if (result != null) {
      await _doLoadCollections();
    }
    return result;
  }

  Future<bool> addToCollection(String collectionId, String libraryItemId) async {
    if (_api == null) return false;
    final updated = await _api!.addBookToCollection(collectionId, libraryItemId);
    if (updated != null) {
      await _doLoadCollections();
      return true;
    }
    return false;
  }

  Future<bool> removeFromCollection(String collectionId, String libraryItemId) async {
    if (_api == null) return false;
    final updated = await _api!.removeBookFromCollection(collectionId, libraryItemId);
    if (updated != null) {
      await _doLoadCollections();
      return true;
    }
    return false;
  }

  Future<bool> reorderCollectionBooks(
    String collectionId,
    List<String> bookIds,
  ) async {
    if (_api == null) return false;
    final updated = await _api!.updateCollection(collectionId, books: bookIds);
    if (updated != null) {
      await _doLoadCollections();
      return true;
    }
    return false;
  }

  Future<bool> deleteCollection(String collectionId) async {
    if (_api == null) return false;
    final ok = await _api!.deleteCollection(collectionId);
    if (ok) {
      _collections = _collections.where((c) => (c as Map)['id'] != collectionId).toList();
      _hiddenSectionIds.remove('collection:$collectionId');
      _sectionOrder.remove('collection:$collectionId');
      await _saveSectionPrefs();
      notifyListeners();
    }
    return ok;
  }

  // ── Section customization ──

  Future<void> _loadSectionPrefs() async {
    final libId = _selectedLibraryId ?? '';
    final orderJson = await ScopedPrefs.getStringList('home_section_order_$libId');
    final hiddenJson = await ScopedPrefs.getStringList('home_hidden_sections_$libId');
    _sectionOrder = orderJson.toList();
    if (hiddenJson.isEmpty && orderJson.isEmpty) {
      _hiddenSectionIds = Set<String>.from(_defaultHiddenSections);
    } else {
      _hiddenSectionIds = hiddenJson.toSet();
    }
    _applyDefaultPlaylistCollectionHiding = false;
    // Load persisted genre sections
    final genreJson = await ScopedPrefs.getStringList('home_genre_sections_$libId');
    _addedGenres = genreJson.toSet();
    _genreSections = {};
    // Fetch items for each added genre in background
    for (final genre in _addedGenres) {
      _fetchGenreSectionItems(genre);
    }
  }

  Future<void> _saveSectionPrefs() async {
    final libId = _selectedLibraryId ?? '';
    await ScopedPrefs.setStringList('home_section_order_$libId', _sectionOrder);
    await ScopedPrefs.setStringList('home_hidden_sections_$libId', _hiddenSectionIds.toList());
  }

  Future<void> saveSectionOrder(List<String> order) async {
    _sectionOrder = List<String>.from(order);
    _applyDefaultPlaylistCollectionHiding = false;
    await _saveSectionPrefs();
    notifyListeners();
  }

  Future<void> toggleSectionVisibility(String sectionId) async {
    final updated = Set<String>.from(_hiddenSectionIds);
    if (updated.contains(sectionId)) {
      updated.remove(sectionId);
    } else {
      updated.add(sectionId);
    }
    _hiddenSectionIds = updated;
    await _saveSectionPrefs();
    notifyListeners();
  }

  static const _defaultHiddenSections = {'newest-authors', 'recent-series'};

  // ── Genre home sections ──

  Set<String> get addedGenres => _addedGenres;

  Future<void> _fetchGenreSectionItems(String genre) async {
    if (_api == null || _selectedLibraryId == null) return;
    final filterValue = base64Encode(utf8.encode(genre));
    final data = await _api!.getLibraryItems(
      _selectedLibraryId!,
      filter: 'genres.$filterValue',
      limit: 20,
      sort: 'addedAt',
      desc: 1,
    );
    if (data == null) return;
    final results = data['results'] as List<dynamic>? ?? [];
    _genreSections[genre] = results;
    notifyListeners();
  }

  Future<void> addGenreSection(String genre) async {
    if (_addedGenres.contains(genre)) return;
    _addedGenres.add(genre);
    final libId = _selectedLibraryId ?? '';
    await ScopedPrefs.setStringList('home_genre_sections_$libId', _addedGenres.toList());
    await _fetchGenreSectionItems(genre);
    notifyListeners();
  }

  Future<void> removeGenreSection(String genre) async {
    _addedGenres.remove(genre);
    _genreSections.remove(genre);
    final sectionId = 'genre:$genre';
    _sectionOrder.remove(sectionId);
    _hiddenSectionIds.remove(sectionId);
    final libId = _selectedLibraryId ?? '';
    await ScopedPrefs.setStringList('home_genre_sections_$libId', _addedGenres.toList());
    await _saveSectionPrefs();
    notifyListeners();
  }

  List<Map<String, dynamic>> getOrderedHomeSections() {
    final allSections = <String, Map<String, dynamic>>{};

    for (final s in _personalizedSections) {
      final id = (s as Map)['id'] as String? ?? '';
      if (id.isEmpty) continue;
      allSections[id] = Map<String, dynamic>.from(s);
    }

    for (final p in _playlists) {
      final pm = p as Map<String, dynamic>;
      final id = 'playlist:${pm['id']}';
      allSections[id] = {
        'id': id,
        'label': pm['name'] ?? 'Playlist',
        'type': 'playlist',
        'entities': (pm['items'] as List<dynamic>?) ?? [],
        '_playlistId': pm['id'],
      };
    }

    for (final c in _collections) {
      final cm = c as Map<String, dynamic>;
      final id = 'collection:${cm['id']}';
      allSections[id] = {
        'id': id,
        'label': 'Server Collection - ${cm['name'] ?? 'Collection'}',
        'type': 'collection',
        'entities': (cm['books'] as List<dynamic>?) ?? [],
        '_collectionId': cm['id'],
      };
    }

    for (final genre in _addedGenres) {
      final id = 'genre:$genre';
      final items = _genreSections[genre] ?? [];
      allSections[id] = {
        'id': id,
        'label': genre,
        'type': 'book',
        'entities': items,
      };
    }

    allSections.removeWhere((id, _) => _hiddenSectionIds.contains(id));
    if (_applyDefaultPlaylistCollectionHiding) {
      allSections.removeWhere((id, _) =>
          id.startsWith('playlist:') || id.startsWith('collection:'));
    }

    if (_sectionOrder.isEmpty) {
      final result = <Map<String, dynamic>>[];
      for (final s in _personalizedSections) {
        final id = (s as Map)['id'] as String? ?? '';
        if (allSections.containsKey(id)) result.add(allSections[id]!);
      }
      for (final p in _playlists) {
        final id = 'playlist:${(p as Map)['id']}';
        if (allSections.containsKey(id)) result.add(allSections[id]!);
      }
      for (final c in _collections) {
        final id = 'collection:${(c as Map)['id']}';
        if (allSections.containsKey(id)) result.add(allSections[id]!);
      }
      for (final genre in _addedGenres) {
        final id = 'genre:$genre';
        if (allSections.containsKey(id)) result.add(allSections[id]!);
      }
      return result;
    }

    final result = <Map<String, dynamic>>[];
    for (final id in _sectionOrder) {
      if (allSections.containsKey(id)) {
        result.add(allSections.remove(id)!);
      }
    }
    result.addAll(allSections.values);
    return result;
  }

  List<Map<String, String>> getAllSectionMeta() {
    final result = <Map<String, String>>[];
    for (final s in _personalizedSections) {
      final id = (s as Map)['id'] as String? ?? '';
      final label = s['label'] as String? ?? id;
      if (id.isNotEmpty) result.add({'id': id, 'label': label});
    }
    for (final p in _playlists) {
      final pm = p as Map<String, dynamic>;
      result.add({
        'id': 'playlist:${pm['id']}',
        'label': pm['name'] as String? ?? 'Playlist',
      });
    }
    for (final c in _collections) {
      final cm = c as Map<String, dynamic>;
      result.add({
        'id': 'collection:${cm['id']}',
        'label': 'Server Collection - ${cm['name'] as String? ?? 'Collection'}',
      });
    }
    for (final genre in _addedGenres) {
      result.add({
        'id': 'genre:$genre',
        'label': genre,
      });
    }
    return result;
  }

  // ── Podcast subscriptions ──

  Future<void> _loadKnownEpisodeIds() async {
    for (final podcastId in _subscribedPodcasts) {
      final ids = await ScopedPrefs.getStringList('known_episodes_$podcastId');
      if (ids.isNotEmpty) {
        _knownEpisodeIds[podcastId] = ids.toSet();
      }
    }
  }

  Future<void> _saveKnownEpisodeIds(String podcastId) async {
    final ids = _knownEpisodeIds[podcastId];
    if (ids != null) {
      await ScopedPrefs.setStringList('known_episodes_$podcastId', ids.toList());
    } else {
      await ScopedPrefs.remove('known_episodes_$podcastId');
    }
  }

  void _checkSubscribedPodcastUpdate(Map<String, dynamic> data) {
    if (_subscribedPodcasts.isEmpty || _api == null || isOffline) return;

    final itemId = data['id'] as String?;
    if (itemId == null || !_subscribedPodcasts.contains(itemId)) return;

    final mediaType = data['mediaType'] as String?;
    if (mediaType != 'podcast') return;

    _fetchAndCheckSubscribedPodcast(itemId);
  }

  Future<void> _fetchAndCheckSubscribedPodcast(String itemId) async {
    if (_api == null || isOffline) return;

    final item = await _api!.getLibraryItem(itemId);
    if (item == null) return;

    final media = item['media'] as Map<String, dynamic>? ?? {};
    final episodes = media['episodes'] as List<dynamic>? ?? [];
    final knownIds = _knownEpisodeIds[itemId];

    if (knownIds == null) {
      final ids = episodes
          .map((e) => (e as Map<String, dynamic>)['id'] as String?)
          .whereType<String>()
          .toSet();
      _knownEpisodeIds[itemId] = ids;
      _saveKnownEpisodeIds(itemId);
      debugPrint('[Subscription] Seeded $itemId with ${ids.length} episodes');
      return;
    }

    final newEpisodes = <Map<String, dynamic>>[];
    for (final ep in episodes) {
      final epMap = ep as Map<String, dynamic>;
      final epId = epMap['id'] as String?;
      if (epId != null && !knownIds.contains(epId)) {
        newEpisodes.add(epMap);
      }
    }

    if (newEpisodes.isNotEmpty) {
      debugPrint('[Subscription] ${newEpisodes.length} new episode(s) for $itemId');
      int queued = 0;

      for (final epMap in newEpisodes) {
        final epId = epMap['id'] as String;
        final key = '$itemId-$epId';

        _absorbingIdsAdd(key, atFront: true);
        _absorbingItemCache[key] = {
          'id': itemId,
          'libraryId': item['libraryId'] as String?,
          'mediaType': 'podcast',
          '_absorbingKey': key,
          'recentEpisode': epMap,
          'media': media,
        };
        _manualAbsorbAdds.add(key);
        _manualAbsorbRemoves.remove(key);
        knownIds.add(epId);
        queued++;
      }

      if (queued > 0) {
        _saveKnownEpisodeIds(itemId);
        (this as _AbsorbingMixin)._saveManualAbsorbing();
        notifyListeners();
        _downloadSubscribedEpisodes(itemId);
      }
    }
  }

  Future<void> checkSubscribedPodcasts() async {
    if (_subscribedPodcasts.isEmpty || _api == null) return;
    for (final podcastId in _subscribedPodcasts) {
      try {
        await _fetchAndCheckSubscribedPodcast(podcastId);
      } catch (e) {
        debugPrint('[Subscription] Failed to check $podcastId: $e');
      }
    }
  }

  Future<void> _downloadSubscribedEpisodes(String podcastId) async {
    if (_api == null || isOffline) return;
    final wifiOnly = await PlayerSettings.getWifiOnlyDownloads();
    if (wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.wifi)) {
        debugPrint('[Subscription] Skipping download (not on WiFi) - will retry on WiFi');
        return;
      }
    }

    final dl = DownloadService();
    int downloaded = 0;

    for (final key in _absorbingBookIds) {
      if (!key.startsWith(podcastId)) continue;
      if (dl.isDownloaded(key) || dl.isDownloading(key)) continue;

      final cached = _absorbingItemCache[key];
      final epId = key.substring(37);
      final ep = cached?['recentEpisode'] as Map<String, dynamic>?;
      final media = cached?['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};

      dl.downloadItem(
        api: _api!,
        itemId: key,
        title: ep?['title'] as String? ?? 'Episode',
        author: metadata['title'] as String? ?? '',
        coverUrl: getCoverUrl(podcastId),
        episodeId: epId,
        libraryId: cached?['libraryId'] as String? ?? _selectedLibraryId,
      );
      downloaded++;
    }

    if (downloaded > 0) {
      final cached = _absorbingItemCache.values.firstWhere(
        (c) => (c['id'] as String?) == podcastId,
        orElse: () => {},
      );
      final media = cached['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final showTitle = metadata['title'] as String? ?? 'Podcast';
      final l = _l();
      _showRollingSnackBar(l?.lpSubscribedPodcastDownloading(showTitle, downloaded)
          ?? '$showTitle: $downloaded new episode${downloaded == 1 ? '' : 's'} downloading');
    }
  }

  Future<void> catchUpSubscribedPodcasts() async {
    if (_subscribedPodcasts.isEmpty || _api == null || isOffline) return;
    for (final podcastId in _subscribedPodcasts) {
      await _downloadSubscribedEpisodes(podcastId);
    }
  }

  // ── Rolling auto-download ──

  void _catchUpRollingDownloads() async {
    if (_api == null || isOffline || _rollingDownloadSeries.isEmpty) return;

    final wifiOnly = await PlayerSettings.getWifiOnlyDownloads();
    if (wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.wifi)) return;
    }

    final count = await PlayerSettings.getRollingDownloadCount();

    for (final seriesOrShowId in _rollingDownloadSeries.toList()) {
      String? latestPodcastKey;
      num latestPodcastUpdate = 0;
      String? latestBookKey;
      num latestBookUpdate = 0;

      for (final entry in _progressMap.entries) {
        final key = entry.key;
        final data = entry.value;
        if (data['isFinished'] == true) continue;
        final lastUpdate = data['lastUpdate'] as num? ?? 0;

        if (key.length > 36 && key.substring(0, 36) == seriesOrShowId) {
          if (lastUpdate > latestPodcastUpdate) {
            latestPodcastUpdate = lastUpdate;
            latestPodcastKey = key;
          }
        } else if (key.length <= 36) {
          final itemData = _itemDataWithSeries(key);
          if (itemData != null) {
            final (sid, _) = _StateMixin._extractSeries(itemData);
            if (sid == seriesOrShowId && lastUpdate > latestBookUpdate) {
              latestBookUpdate = lastUpdate;
              latestBookKey = key;
            }
          }
        }
      }

      if (latestPodcastKey != null) {
        _rollingDownloadPodcast(latestPodcastKey, count);
      } else if (latestBookKey != null) {
        _rollingDownloadBook(latestBookKey, count);
      }
    }
  }

  void _checkRollingDownloads(String playingKey) async {
    if (_api == null || isOffline || _rollingDownloadSeries.isEmpty) {
      return;
    }
    final count = await PlayerSettings.getRollingDownloadCount();

    if (playingKey.length > 36) {
      final showId = playingKey.substring(0, 36);
      if (_rollingDownloadSeries.contains(showId)) {
        _rollingDownloadPodcast(playingKey, count);
      }
    } else {
      var data = _itemDataWithSeries(playingKey);
      var (seriesId, _) = data != null ? _StateMixin._extractSeries(data) : (null, null);
      if (seriesId == null) {
        final fullItem = await _api!.getLibraryItem(playingKey);
        if (fullItem != null) {
          (seriesId, _) = _StateMixin._extractSeries(fullItem);
        }
      }
      if (seriesId != null && _rollingDownloadSeries.contains(seriesId)) {
        _rollingDownloadBook(playingKey, count);
      }
    }
  }

  void _checkQueueAutoDownloads(String playingKey) async {
    if (_api == null || isOffline) {
      return;
    }
    final isPodcastKey = playingKey.length > 36;
    final queueMode = isPodcastKey
        ? await PlayerSettings.getPodcastQueueMode()
        : await PlayerSettings.getBookQueueMode();
    if (queueMode != 'manual') {
      return;
    }
    final enabled = await PlayerSettings.getQueueAutoDownload();
    if (!enabled) return;
    final merged = await PlayerSettings.getMergeAbsorbingLibraries();

    final wifiOnly = await PlayerSettings.getWifiOnlyDownloads();
    if (wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.wifi)) return;
    }

    final count = await PlayerSettings.getRollingDownloadCount();
    final dl = DownloadService();
    int queued = 0;
    int newDownloads = 0;

    final playingIdx = _absorbingBookIds.indexOf(playingKey);
    final startIdx = playingIdx >= 0 ? playingIdx : 0;

    final playingCached = _absorbingItemCache[playingKey];
    final playingLibId = playingCached?['libraryId'] as String?;

    for (int i = startIdx;
        i < _absorbingBookIds.length && queued < count;
        i++) {
      final key = _absorbingBookIds[i];
      if ((this as LibraryProvider).isItemFinishedByKey(key)) continue;

      final cached = _absorbingItemCache[key];
      if (cached == null) continue;

      if (!merged && playingLibId != null) {
        final candidateLibId = cached['libraryId'] as String?;
        if (candidateLibId != null && candidateLibId != playingLibId) continue;
      }

      if (dl.isDownloaded(key) || dl.isDownloading(key)) {
        queued++;
        continue;
      }

      final media = cached['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String? ?? '';
      final author = metadata['authorName'] as String? ?? '';

      if (key.length > 36) {
        final showId = key.substring(0, 36);
        final epId = key.substring(37);
        final ep = cached['recentEpisode'] as Map<String, dynamic>?;
        dl.downloadItem(
          api: _api!,
          itemId: key,
          title: ep?['title'] as String? ?? 'Episode',
          author: title,
          coverUrl: getCoverUrl(showId),
          episodeId: epId,
          libraryId: _selectedLibraryId,
        );
      } else {
        dl.downloadItem(
          api: _api!,
          itemId: key,
          title: title,
          author: author,
          coverUrl: getCoverUrl(key),
          libraryId: _selectedLibraryId,
        );
      }
      queued++;
      newDownloads++;
    }

    if (newDownloads > 0) {
      final l = _l();
      _showRollingSnackBar(
          l?.lpQueueDownloadingItems(newDownloads)
          ?? 'Queue: downloading $newDownloads item${newDownloads == 1 ? '' : 's'}');
    }
  }

  void _catchUpQueueAutoDownloads() {
    final itemId = AudioPlayerService().currentItemId;
    if (itemId == null) return;
    final epId = AudioPlayerService().currentEpisodeId;
    final key = epId != null ? '$itemId-$epId' : itemId;
    _checkQueueAutoDownloads(key);
  }

  void _checkAutoDownloadOnStream(String playingKey) async {
    if (_api == null || isOffline) {
      return;
    }
    final enabled = await PlayerSettings.getAutoDownloadOnStream();
    if (!enabled) {
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.wifi)) return;

    final dl = DownloadService();
    if (dl.isDownloaded(playingKey) || dl.isDownloading(playingKey)) return;

    final player = AudioPlayerService();
    final itemId = player.currentItemId;
    if (itemId == null) return;

    dl.downloadItem(
      api: _api!,
      itemId: itemId,
      title: player.currentTitle ?? '',
      author: player.currentAuthor ?? '',
      coverUrl: player.currentCoverUrl,
      episodeId: player.currentEpisodeId,
      libraryId: _selectedLibraryId,
    );
  }

  Future<void> _rollingDownloadBook(String bookId, int count) async {
    var data = _itemDataWithSeries(bookId);
    var (seriesId, currentSeq) =
        data != null ? _StateMixin._extractSeries(data) : (null, null);
    if (seriesId == null || currentSeq == null) {
      final fullItem = await _api!.getLibraryItem(bookId);
      if (fullItem == null) return;
      data = fullItem;
      (seriesId, currentSeq) = _StateMixin._extractSeries(fullItem);
    }
    if (seriesId == null || currentSeq == null) return;

    final books = await _api!.getBooksBySeries(
      _selectedLibraryId ?? '',
      seriesId,
      limit: 100,
    );
    if (books.isEmpty) return;

    final dl = DownloadService();
    int queued = 0;
    int newDownloads = 0;

    final anchorFinished = _progressMap[bookId]?['isFinished'] == true;
    if (!anchorFinished &&
        !dl.isDownloaded(bookId) &&
        !dl.isDownloading(bookId)) {
      final media = data!['media'] as Map<String, dynamic>? ?? {};
      final md = media['metadata'] as Map<String, dynamic>? ?? {};
      dl.downloadItem(
        api: _api!,
        itemId: bookId,
        title: md['title'] as String? ?? '',
        author: md['authorName'] as String? ?? '',
        coverUrl: getCoverUrl(bookId),
        libraryId: _selectedLibraryId,
      );
      newDownloads++;
    }
    if (!anchorFinished) queued++;

    for (final book in books) {
      if (queued >= count) break;
      final bookMap = book as Map<String, dynamic>;
      final id = bookMap['id'] as String?;
      if (id == null || id == bookId) continue;

      final media = bookMap['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final seriesRaw = metadata['series'];
      double? seq;
      if (seriesRaw is Map<String, dynamic> && seriesRaw['id'] == seriesId) {
        seq = _StateMixin._parseSequence((seriesRaw['sequence'] ?? '').toString());
      } else if (seriesRaw is List) {
        for (final s in seriesRaw) {
          if (s is Map<String, dynamic> && s['id'] == seriesId) {
            seq = _StateMixin._parseSequence((s['sequence'] ?? '').toString());
            break;
          }
        }
      }
      if (seq == null || seq <= currentSeq) continue;

      if (dl.isDownloaded(id) || dl.isDownloading(id)) {
        queued++;
        continue;
      }
      if (_progressMap[id]?['isFinished'] == true) continue;

      dl.downloadItem(
        api: _api!,
        itemId: id,
        title: metadata['title'] as String? ?? '',
        author: metadata['authorName'] as String? ?? '',
        coverUrl: getCoverUrl(id),
        libraryId: _selectedLibraryId,
      );
      queued++;
      newDownloads++;
    }

    if (newDownloads > 0) {
      final l = _l();
      _showRollingSnackBar(
          l?.lpDownloadingBooks(newDownloads)
          ?? 'Downloading $newDownloads book${newDownloads == 1 ? '' : 's'}');
    }
  }

  Future<void> _rollingDownloadPodcast(String compoundKey, int count) async {
    final showId = compoundKey.substring(0, 36);
    final episodeId = compoundKey.substring(37);

    final fullItem = await _api!.getLibraryItem(showId);
    if (fullItem == null) return;
    final media = fullItem['media'] as Map<String, dynamic>? ?? {};
    final episodes =
        List<dynamic>.from(media['episodes'] as List<dynamic>? ?? []);
    if (episodes.isEmpty) return;

    episodes.sort((a, b) {
      final aTime = (a['publishedAt'] as num?)?.toInt() ?? 0;
      final bTime = (b['publishedAt'] as num?)?.toInt() ?? 0;
      return aTime.compareTo(bTime);
    });

    final currentIdx = episodes.indexWhere(
      (e) => e is Map<String, dynamic> && (e['id'] as String?) == episodeId,
    );
    if (currentIdx < 0) return;

    final dl = DownloadService();
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    int queued = 0;
    int newDownloads = 0;

    final anchorFinished = _progressMap[compoundKey]?['isFinished'] == true;
    if (!anchorFinished &&
        !dl.isDownloaded(compoundKey) &&
        !dl.isDownloading(compoundKey)) {
      final curEp = episodes[currentIdx] as Map<String, dynamic>;
      dl.downloadItem(
        api: _api!,
        itemId: compoundKey,
        title: curEp['title'] as String? ?? 'Episode',
        author: metadata['title'] as String? ?? '',
        coverUrl: getCoverUrl(showId),
        episodeId: episodeId,
        libraryId: _selectedLibraryId,
      );
      newDownloads++;
    }
    if (!anchorFinished) queued++;

    for (int i = currentIdx + 1; i < episodes.length && queued < count; i++) {
      final ep = episodes[i] as Map<String, dynamic>;
      final epId = ep['id'] as String?;
      if (epId == null) continue;
      final key = '$showId-$epId';

      if (dl.isDownloaded(key) || dl.isDownloading(key)) {
        queued++;
        continue;
      }
      if (_progressMap[key]?['isFinished'] == true) continue;

      dl.downloadItem(
        api: _api!,
        itemId: key,
        title: ep['title'] as String? ?? 'Episode',
        author: metadata['title'] as String? ?? '',
        coverUrl: getCoverUrl(showId),
        episodeId: epId,
        libraryId: _selectedLibraryId,
      );
      queued++;
      newDownloads++;
    }

    if (newDownloads > 0) {
      final l = _l();
      _showRollingSnackBar(
          l?.lpDownloadingEpisodes(newDownloads)
          ?? 'Downloading $newDownloads episode${newDownloads == 1 ? '' : 's'}');
    }
  }

  // ── Absorbing helpers used by _CoreMixin ──

  void _absorbingIdsAdd(String key, {String? afterKey, bool atFront = true}) {
    if (_absorbingBookIds.contains(key) && afterKey == null) return;

    if (afterKey != null) {
      _absorbingBookIds.remove(key);
      final afterIdx = _absorbingBookIds.indexOf(afterKey);
      if (afterIdx >= 0) {
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
}
