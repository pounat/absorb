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
import '../services/bookmark_service.dart';
import '../services/session_cache.dart';
import '../services/socket_service.dart';
import '../services/home_widget_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show scaffoldMessengerKey, rootNavigatorKey;

part '_lp_state.dart';
part '_lp_core.dart';
part '_lp_absorbing.dart';

class LibraryProvider extends ChangeNotifier
    with _StateMixin, _CoreMixin, _AbsorbingMixin {
  LibraryProvider() {
    // Registered once at provider construction so the audio service can
    // notify this provider on completion/playback events even when the
    // Flutter UI wasn't foregrounded yet (e.g. Android Auto cold-start,
    // where updateAuth may not run until much later).
    AudioPlayerService.setOnBookFinishedCallback(markFinishedLocally);
    AudioPlayerService.setOnPlayStartedCallback((key) {
      Future.delayed(const Duration(seconds: 30), () {
        final stillPlaying = AudioPlayerService().isPlaying;
        if (!stillPlaying) return;
        _checkRollingDownloads(key);
        _checkQueueAutoDownloads(key);
        _checkAutoDownloadOnStream(key);
      });
    });
    AudioPlayerService.setOnPlaybackStateChangedCallback((playing) {
      if (playing) {
        onPlaybackStarted();
      } else {
        onPlaybackStopped();
      }
    });
    ChromecastService.setOnBookFinishedCallback(markFinishedLocally);
    ChromecastService.setOnPlaybackStateChangedCallback((playing) {
      if (playing) {
        onPlaybackStarted();
      } else {
        onPlaybackStopped();
      }
    });
  }

  void updateAuth(AuthProvider auth) {
    if (!_listeningToDownloads) {
      _listeningToDownloads = true;
      DownloadService().addListener(_onDownloadsChanged);
    }
    final wasAuthenticated = _auth?.isAuthenticated ?? false;
    _auth = auth;

    if (auth.isAuthenticated) {
      final isFreshLogin = !wasAuthenticated;

      final authKey = '${auth.userId}@${auth.serverUrl}';
      final isNewUser = _lastAuthKey != null && authKey != _lastAuthKey;
      final isDuplicate = !isNewUser && !isFreshLogin;
      debugPrint(
          '[Library] updateAuth: key=$authKey lastKey=$_lastAuthKey isNewUser=$isNewUser isFreshLogin=$isFreshLogin isDuplicate=$isDuplicate');
      _lastAuthKey = authKey;

      if (isDuplicate) return;

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
        _rollingDownloadSeries.clear();
        _itemUpdatedAt.clear();
        _seriesBooksCache.clear();
        _seriesTabCache.clear();
        _personalizedInFlight = null;
        _lastPersonalizedFetchAt = null;
        _lastPersonalizedFetchLibraryId = null;
        _rssHydrationInFlight = false;
        _lastRssHydrationAt = null;
        _lastRssHydrationLibraryId = null;
        _networkOffline = false;
        _connectivitySub?.cancel();
        _stopServerPingTimer();
        _stopHealthCheckTimer();
        _isLoading = true;
        notifyListeners();
      }

      restoreOfflineMode().then((_) async {
        debugPrint(
            '[Library] restoreOfflineMode done, serverReachable=${auth.serverReachable} api=${_api != null} offline=$isOffline');
        _startConnectivityMonitoring();
        await _loadManualAbsorbing();
        await _loadRollingDownloadSeries();
        await _loadSubscribedPodcasts();
        await _loadKnownEpisodeIds();
        Future.microtask(() => checkSubscribedPodcasts());

        // Replay any book-finished event that fired before the absorbing
        // cache was loaded (Android Auto cold-start case).
        AudioPlayerService.drainPendingBookFinished();

        _buildProgressMap(auth);

        if (!auth.serverReachable) {
          debugPrint('[Library] Server not reachable — going offline');
          _networkOffline = true;
          _buildOfflineSections();
          _isLoading = false;
          notifyListeners();
          refreshLocalProgress();
          if (_deviceHasConnectivity) _startServerPingTimer();
          return;
        }
        if (_api != null && !isOffline) {
          ProgressSyncService().flushPendingSync(api: _api!);
          ProgressSyncService().flushOfflineListeningTime(api: _api!);
          DownloadService().enrichMetadata(_api!);
          // Start proactive reachability verification so the cloud icon
          // reflects actual server state, not just the initial login result.
          _startHealthCheckTimer();
        }
        if (auth.serverUrl != null && auth.token != null) {
          final socket = SocketService();
          socket.onProgressUpdated = _onRemoteProgressUpdated;
          socket.onItemUpdated = _onRemoteItemUpdated;
          socket.onItemRemoved = _onRemoteItemRemoved;
          socket.onSeriesUpdated = _onRemoteSeriesUpdated;
          socket.onCollectionUpdated = _onRemoteCollectionUpdated;
          socket.onUserUpdated = _onRemoteUserUpdated;
          socket.onReconnectFailed = _onSocketReconnectFailed;
          socket.connect(auth.serverUrl!, auth.token!, customHeaders: auth.customHeaders);
        }
        debugPrint('[Library] Calling loadLibraries()');
        loadLibraries();
      }).catchError((e) {
        debugPrint('[Library] restoreOfflineMode error: $e');
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _lastAuthKey = null;
      _idleDisconnectTimer?.cancel();
      _idleDisconnectTimer = null;
      _libraries = [];
      _personalizedSections = [];
      _series = [];
      _progressMap = {};
      _localProgressOverrides.clear();
      _itemUpdatedAt.clear();
      _selectedLibraryId = null;
      _errorMessage = null;
      _connectivitySub?.cancel();
      _progressRefreshDebounce?.cancel();
      _stopServerPingTimer();
      _stopHealthCheckTimer();
      SocketService().disconnect();
      _personalizedInFlight = null;
      _lastPersonalizedFetchAt = null;
      _lastPersonalizedFetchLibraryId = null;
      _rssHydrationInFlight = false;
      _lastRssHydrationAt = null;
      _lastRssHydrationLibraryId = null;
      notifyListeners();
    }
  }

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
      debugPrint(
          '[Library] loadLibraries: got ${_libraries.length} libraries');

      if (_libraries.isNotEmpty) {
        final savedId = await ScopedPrefs.getString('last_selected_library');
        final defaultId = _auth?.defaultLibraryId;
        if (savedId != null &&
            _libraries.any((l) => l['id'] == savedId)) {
          _selectedLibraryId = savedId;
        } else if (defaultId != null &&
            _libraries.any((l) => l['id'] == defaultId)) {
          _selectedLibraryId = defaultId;
        } else {
          final bookLibraries = _libraries
              .where((l) =>
                  (l['mediaType'] as String? ?? 'book') != 'podcast')
              .toList();
          _selectedLibraryId = bookLibraries.isNotEmpty
              ? bookLibraries.first['id']
              : _libraries.first['id'];
        }

        await _loadSectionPrefs();
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

    _catchUpRollingDownloads();
    _catchUpQueueAutoDownloads();
    catchUpSubscribedPodcasts();
  }

  Future<void> selectLibrary(String libraryId) async {
    final wasPlaying = AudioPlayerService().isPlaying;
    final wasCasting = ChromecastService().isPlaying;

    // Stop playback if something is playing from the old library
    if (wasPlaying) {
      debugPrint('[Library] Stopping playback on library switch');
      await AudioPlayerService().stop();
    }
    if (wasCasting) {
      debugPrint('[Library] Stopping cast on library switch');
      ChromecastService().stopCasting();
    }

    _selectedLibraryId = libraryId;
    _series = [];
    _playlists = [];
    _collections = [];
    await ScopedPrefs.setString('last_selected_library', libraryId);
    await _loadSectionPrefs();
    notifyListeners();
    await loadPersonalizedView(force: true);
    AndroidAutoService().refresh(force: true);
  }


  Future<void> refresh() async {
    if (isOffline) {
      _buildOfflineSections();
      notifyListeners();
      return;
    }
    if (_api != null) {
      await ProgressSyncService().flushPendingSync(api: _api!);
    }
    _lastFinishedItemId = null;
    await Future.wait([
      loadPersonalizedView(force: true),
      _refreshProgress(),
    ]);
    _localProgressOverrides.clear();
    _locallyFinishedItems.clear();
    final sync = ProgressSyncService();
    for (final entry in _progressMap.entries) {
      final itemId = entry.key;
      final mp = entry.value;
      final currentTime = (mp['currentTime'] as num?)?.toDouble() ?? 0;
      final duration = (mp['duration'] as num?)?.toDouble() ?? 0;
      if (duration > 0 && currentTime > 0) {
        await sync.cacheServerProgress(
          itemId: itemId,
          currentTime: currentTime,
          duration: duration,
        );
      }
    }
    notifyListeners();
  }

  Future<void> refreshProgressOnly() async {
    if (isOffline || _api == null) return;
    await ProgressSyncService().flushPendingSync(api: _api!);
    await _refreshProgress();
    notifyListeners();
  }

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
        // Register updatedAt for books in series for cover cache busting
        for (final s in _series) {
          if (s is! Map<String, dynamic>) continue;
          final books = s['books'] as List<dynamic>? ?? [];
          for (final b in books) {
            if (b is Map<String, dynamic>) {
              final id = b['id'] as String?;
              final ts = b['updatedAt'] as num?;
              if (id != null && ts != null) _itemUpdatedAt[id] = ts.toInt();
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }

    _isLoadingSeries = false;
    notifyListeners();
  }

  bool isOnAbsorbingList(String key) {
    if (_manualAbsorbRemoves.contains(key)) return false;
    return _absorbingBookIds.contains(key);
  }

  bool isItemFinishedByKey(String key) {
    if (_locallyFinishedItems.contains(key)) return true;
    if (key.length > 36) {
      final showId = key.substring(0, 36);
      final epId = key.substring(37);
      return getEpisodeProgressData(showId, epId)?['isFinished'] == true;
    }
    return getProgressData(key)?['isFinished'] == true;
  }
}
