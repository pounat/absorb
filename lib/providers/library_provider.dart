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
import '../services/local_session_service.dart';
import '../services/download_service.dart';
import '../services/library_cache.dart';
import '../services/android_auto_service.dart';
import '../services/carplay_service.dart';
import '../services/chromecast_service.dart';
import '../services/bookmark_service.dart';
import '../services/metadata_override_service.dart';
import '../services/session_cache.dart';
import '../services/socket_service.dart';
import '../services/book_search_index.dart';
import '../services/home_widget_service.dart';
import '../utils/absorbing_inclusion.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import '../widgets/overlay_toast.dart';

part '_lp_state.dart';
part '_lp_core.dart';
part '_lp_absorbing.dart';

class LibraryProvider extends ChangeNotifier
    with _StateMixin, _CoreMixin, _AbsorbingMixin {
  int _accountLoadGeneration = 0;
  Completer<void>? _accountReadyCompleter;

  Future<void> waitForActiveAccountReady() =>
      _accountReadyCompleter?.future ?? Future.value();

  void _completeAccountLoad(int generation) {
    if (generation != _accountLoadGeneration) return;
    final completer = _accountReadyCompleter;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  LibraryProvider() {
    // Registered once at provider construction so the audio service can
    // notify this provider on completion/playback events even when the
    // Flutter UI wasn't foregrounded yet (e.g. Android Auto cold-start,
    // where updateAuth may not run until much later).
    AudioPlayerService.setOnBookFinishedCallback(markFinishedLocally);
    AudioPlayerService.setOnAutoQueueAdvancedCallback((oldItemId) {
      // Pre-buffer auto-advance already loaded and started the next item.
      // Mark the old one finished WITHOUT triggering normal auto-advance
      // (which would call playItem again and rebuild the source).
      markFinishedLocally(oldItemId, skipAutoAdvance: true);
    });
    AudioPlayerService.setOnPeekNextItemCallback(peekNextQueueItemForPreBuffer);
    AudioPlayerService.setOnPlayStartedCallback((key) {
      // Auto-download the book/episode you're listening to kicks off quickly so
      // it doesn't feel broken; the short wait still skips it if you stop or
      // switch right away. Rolling/queue look-ahead stays deferred to keep the
      // moment playback starts light.
      Future.delayed(const Duration(seconds: 5), () {
        if (!AudioPlayerService().isPlaying) return;
        _checkAutoDownloadOnStream(key);
      });
      Future.delayed(const Duration(seconds: 30), () {
        if (!AudioPlayerService().isPlaying) return;
        _checkRollingDownloads(key);
        _checkQueueAutoDownloads(key);
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

      if (isDuplicate) {
        // The remote auth key didn't change, but the active server URL might
        // have flipped (local <-> remote). When it does, library data was
        // fetched from the OLD server and the home page can render with stale
        // or empty sections. Refresh once on each transition.
        if (_lastUseLocalServer != null && _lastUseLocalServer != auth.useLocalServer) {
          _lastUseLocalServer = auth.useLocalServer;
          if (!_networkOffline && !_manualOffline) {
            debugPrint('[Library] Active server switched - refreshing library data');
            refresh();
          }
        } else {
          _lastUseLocalServer = auth.useLocalServer;
        }
        return;
      }
      _lastUseLocalServer = auth.useLocalServer;

      final accountLoadGeneration = ++_accountLoadGeneration;
      final previousCompleter = _accountReadyCompleter;
      if (previousCompleter != null && !previousCompleter.isCompleted) {
        previousCompleter.complete();
      }
      _accountReadyCompleter = Completer<void>();

      if (isNewUser || isFreshLogin) {
        _libraries = [];
        _selectedLibraryId = null;
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
        _rssHydrationInFlight = false;
        _lastRssHydrationAt = null;
        _lastRssHydrationLibraryId = null;
        _networkOffline = false;
        _connectivitySub?.cancel();
        _connectivityDebounce?.cancel();
        _stopServerPingTimer();
        _stopHealthCheckTimer();
        _isLoading = true;
        notifyListeners();
      }

      // Refresh the local metadata cover overrides for this account so the
      // grid/card covers reflect them, then repaint once loaded.
      MetadataOverrideService().loadAll().then((_) {
        if (accountLoadGeneration == _accountLoadGeneration) notifyListeners();
      });

      restoreOfflineMode().then((_) async {
        if (accountLoadGeneration != _accountLoadGeneration) return;
        debugPrint(
            '[Library] restoreOfflineMode done, serverReachable=${auth.serverReachable} api=${_api != null} offline=$isOffline');
        _startConnectivityMonitoring();
        await _loadManualAbsorbing();
        await _loadRollingDownloadSeries();
        await _loadSubscribedPodcasts();
        await _loadYearHidden();
        await _loadKnownEpisodeIds();
        await _restoreCachedLibraries();
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
          _completeAccountLoad(accountLoadGeneration);
          return;
        }
        if (_api != null && !isOffline) {
          ProgressSyncService().flushPendingSync(api: _api!);
          ProgressSyncService().flushOfflineListeningTime(api: _api!);
          LocalSessionService().flushPending(api: _api!);
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
          socket.onPlaylistUpdated = _onRemotePlaylistUpdated;
          socket.onUserUpdated = _onRemoteUserUpdated;
          socket.onReconnectFailed = _onSocketReconnectFailed;
          socket.onEncodeFinished = _onEncodeFinished;
          socket.onEreaderDevicesUpdated = (devices) {
            // Admin broadcasts deliver the FULL unfiltered list; the per-user
            // emit is already filtered. Run the same filter here either way -
            // it's a no-op on an already-filtered list.
            auth.setEreaderDevices(auth.filterDevicesForCurrentUser(devices));
          };
          socket.connect(auth.serverUrl!, auth.token!, customHeaders: auth.customHeaders);
        }
        debugPrint('[Library] Calling loadLibraries()');
        await loadLibraries();
        _completeAccountLoad(accountLoadGeneration);
      }).catchError((e) {
        if (accountLoadGeneration != _accountLoadGeneration) return;
        debugPrint('[Library] restoreOfflineMode error: $e');
        _isLoading = false;
        notifyListeners();
        _completeAccountLoad(accountLoadGeneration);
      });
    } else {
      _accountLoadGeneration++;
      final completer = _accountReadyCompleter;
      if (completer != null && !completer.isCompleted) completer.complete();
      _accountReadyCompleter = null;
      _lastAuthKey = null;
      _lastUseLocalServer = null;
      _libraries = [];
      _personalizedSections = [];
      _series = [];
      _progressMap = {};
      _localProgressOverrides.clear();
      _itemUpdatedAt.clear();
      _selectedLibraryId = null;
      _errorMessage = null;
      _connectivitySub?.cancel();
      _connectivityDebounce?.cancel();
      _progressRefreshDebounce?.cancel();
      _stopServerPingTimer();
      _stopHealthCheckTimer();
      SocketService().disconnect();
      _personalizedInFlight = null;
      _rssHydrationInFlight = false;
      _lastRssHydrationAt = null;
      _lastRssHydrationLibraryId = null;
      notifyListeners();
    }
  }

  /// Repaint listeners after a local metadata cover override is saved or
  /// cleared, so the grid/absorbing card re-resolve [getCoverUrl] (the cache
  /// is already updated synchronously by MetadataOverrideService).
  void notifyCoverOverridesChanged() => notifyListeners();

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
      await LibraryCache.save(_libraries);

      if (_libraries.isNotEmpty) {
        await _restoreSelectedLibrary();

        await _loadSectionPrefs();
        await loadPersonalizedView(force: true);
      } else {
        _selectedLibraryId = null;
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

  Future<void> _restoreCachedLibraries() async {
    if (_libraries.isNotEmpty) return;
    final cached = await LibraryCache.load();
    if (cached.isEmpty) return;
    _libraries = cached;
    await _restoreSelectedLibrary();
    debugPrint(
        '[Library] Restored ${_libraries.length} cached libraries for offline use');
  }

  Future<void> _restoreSelectedLibrary() async {
    if (_libraries.isEmpty) {
      _selectedLibraryId = null;
      return;
    }
    final savedId = await ScopedPrefs.getString('last_selected_library');
    final defaultId = _auth?.defaultLibraryId;
    if (savedId != null && _libraries.any((l) => l['id'] == savedId)) {
      _selectedLibraryId = savedId;
      return;
    }
    if (defaultId != null && _libraries.any((l) => l['id'] == defaultId)) {
      _selectedLibraryId = defaultId;
      return;
    }
    final bookLibraries = _libraries
        .where((l) =>
            (l['mediaType'] as String? ?? 'book') != 'podcast')
        .toList();
    _selectedLibraryId = bookLibraries.isNotEmpty
        ? bookLibraries.first['id'] as String?
        : _libraries.first['id'] as String?;
  }

  Future<void> selectLibrary(String libraryId) async {
    // When Merge Libraries is on, the absorbing card stays visible across
    // libraries so the user can still control playback. Only stop on switch
    // when merge is off, otherwise the player would be unreachable from the
    // new library.
    final merged = await PlayerSettings.getMergeAbsorbingLibraries();
    if (!merged) {
      final wasPlaying = AudioPlayerService().isPlaying;
      final wasCasting = ChromecastService().isPlaying;
      if (wasPlaying) {
        debugPrint('[Library] Stopping playback on library switch');
        await AudioPlayerService().stop();
      }
      if (wasCasting) {
        debugPrint('[Library] Stopping cast on library switch');
        ChromecastService().stopCasting();
      }
    }

    _selectedLibraryId = libraryId;
    _series = [];
    _playlists = [];
    _collections = [];
    await ScopedPrefs.setString('last_selected_library', libraryId);
    await _rememberBookLibrary(libraryId);
    await _loadSectionPrefs();
    notifyListeners();
    await loadPersonalizedView(force: true);
    AndroidAutoService().refresh(force: true);
    CarPlayService().refreshTemplates();
  }

  /// Library switch for the dedicated Podcasts tab flips. Never stops
  /// playback, restores cached sections instantly and only refetches once
  /// the per-library cooldown expires - picker-driven switches keep using
  /// [selectLibrary] (full refresh).
  Future<void> selectLibraryLight(String libraryId) async {
    if (libraryId == _selectedLibraryId) return;
    _selectedLibraryId = libraryId;
    _series = [];
    _playlists = [];
    _collections = [];
    _personalizedSections = _sectionsByLibrary[libraryId] ?? [];
    await ScopedPrefs.setString('last_selected_library', libraryId);
    await _rememberBookLibrary(libraryId);
    await _loadSectionPrefs();
    notifyListeners();
    await loadPersonalizedView();
    AndroidAutoService().refresh(force: true);
    CarPlayService().refreshTemplates();
  }

  bool isPodcastLibraryId(String libraryId) {
    final library = _libraries.firstWhere(
      (l) => l['id'] == libraryId,
      orElse: () => null,
    );
    if (library is! Map<String, dynamic>) return false;
    return (library['mediaType'] as String? ?? 'book') == 'podcast';
  }

  /// Track the last non-podcast library so the Home/Library tabs know where
  /// to return when leaving the dedicated Podcasts tab.
  Future<void> _rememberBookLibrary(String libraryId) async {
    if (!isPodcastLibraryId(libraryId)) {
      await ScopedPrefs.setString('last_book_library', libraryId);
    }
  }

  /// The library the Home/Library tabs should show: the last-used book
  /// library, or the first non-podcast library as a fallback.
  Future<String?> lastBookLibraryId() async {
    final saved = await ScopedPrefs.getString('last_book_library');
    if (saved != null && _libraries.any((l) => l['id'] == saved)) return saved;
    for (final l in _libraries) {
      if ((l['mediaType'] as String? ?? 'book') != 'podcast') {
        return l['id'] as String?;
      }
    }
    return null;
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
    final pendingSyncs =
        (await ScopedPrefs.getStringList('pending_syncs')).toSet();
    _lastFinishedItemId = null;
    await Future.wait([
      loadPersonalizedView(force: true),
      _refreshProgress(),
    ]);
    _localProgressOverrides
        .removeWhere((itemId, _) => !pendingSyncs.contains(itemId));
    _locallyFinishedItems
        .removeWhere((itemId) => !pendingSyncs.contains(itemId));
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
              if (id != null && ts != null) registerUpdatedAt(id, ts.toInt());
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
