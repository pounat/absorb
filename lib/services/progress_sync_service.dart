import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import 'scoped_prefs.dart';
import 'sync_logic.dart';

/// Manages local progress storage and server sync.
/// Progress is ALWAYS saved locally first, then synced to server when online.
/// All progress data is scoped to the active user account via ScopedPrefs.
class ProgressSyncService {
  static final ProgressSyncService _instance = ProgressSyncService._();
  factory ProgressSyncService() => _instance;
  ProgressSyncService._();

  StreamSubscription? _connectivitySub;
  bool _isOnline = true;
  bool _isFlushing = false;
  bool _flushAgain = false;
  bool _isFlushingOfflineListening = false;
  int _consecutiveFailures = 0;
  static const _maxConsecutiveFailures = 10;

  /// Initialize — start listening for connectivity changes.
  Future<void> init() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);
      if (_isOnline && wasOffline) {
        _consecutiveFailures = 0; // reset backoff on connectivity change
        flushPendingSync();
      }
    });
  }

  bool get isOnline => _isOnline;

  /// Save progress locally and mark it as a pending change to sync.
  Future<void> saveLocal({
    required String itemId,
    required double currentTime,
    required double duration,
    required double speed,
    bool? isFinished,
  }) async {
    // Preserve existing isFinished flag if not explicitly provided
    if (isFinished == null) {
      final existing = await getLocal(itemId);
      isFinished = existing?['isFinished'] as bool? ?? false;
    }
    final data = {
      'itemId': itemId,
      'currentTime': currentTime,
      'duration': duration,
      'speed': speed,
      'isFinished': isFinished,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await ScopedPrefs.setString('progress_$itemId', jsonEncode(data));

    final pendingList = await ScopedPrefs.getStringList('pending_syncs');
    if (!pendingList.contains(itemId)) {
      pendingList.add(itemId);
      await ScopedPrefs.setStringList('pending_syncs', pendingList);
    }
  }

  /// Cache server-known progress locally without marking it as a pending sync.
  /// Skips items with a pending sync so unsynced local writes (e.g. a finished
  /// state saved while offline) are not clobbered by a stale server snapshot.
  Future<void> cacheServerProgress({
    required String itemId,
    required double currentTime,
    required double duration,
    bool isFinished = false,
  }) async {
    final pendingList = await ScopedPrefs.getStringList('pending_syncs');
    if (pendingList.contains(itemId)) {
      debugPrint('[Sync] Skipping server cache for $itemId - pending local sync would be clobbered (isFinished=$isFinished)');
      return;
    }
    final data = {
      'itemId': itemId,
      'currentTime': currentTime,
      'duration': duration,
      'speed': 1.0,
      'isFinished': isFinished,
      'timestamp': 0,
    };
    await ScopedPrefs.setString('progress_$itemId', jsonEncode(data));
  }

  /// Get locally saved progress for an item.
  Future<Map<String, dynamic>?> getLocal(String itemId) async {
    final json = await ScopedPrefs.getString('progress_$itemId');
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Get the saved currentTime for an item (for resuming).
  Future<double> getSavedPosition(String itemId) async {
    final data = await getLocal(itemId);
    return (data?['currentTime'] as num?)?.toDouble() ?? 0;
  }

  /// Get the saved timestamp (milliseconds since epoch) for an item.
  Future<int> getSavedTimestamp(String itemId) async {
    final data = await getLocal(itemId);
    return (data?['timestamp'] as num?)?.toInt() ?? 0;
  }

  /// Whether the given item has unsynced local progress. Callers can use this
  /// to avoid clobbering offline-listening progress with a stale server snapshot.
  Future<bool> hasPendingSync(String itemId) async {
    final pendingList = await ScopedPrefs.getStringList('pending_syncs');
    return pendingList.contains(itemId);
  }

  /// Delete locally saved progress for an item.
  Future<void> deleteLocal(String itemId) async {
    await ScopedPrefs.remove('progress_$itemId');
    final pendingList = await ScopedPrefs.getStringList('pending_syncs');
    pendingList.remove(itemId);
    await ScopedPrefs.setStringList('pending_syncs', pendingList);
  }

  /// Sync a single item to the server. Returns true if synced.
  Future<bool> syncToServer({
    required ApiService api,
    required String itemId,
    String? sessionId,
  }) async {
    if (!_isOnline) {
      debugPrint('[Sync] Skipped — offline');
      return false;
    }

    final data = await getLocal(itemId);
    if (data == null) {
      debugPrint('[Sync] Skipped — no local data for $itemId');
      return false;
    }

    final currentTime = (data['currentTime'] as num?)?.toDouble() ?? 0;
    final duration = (data['duration'] as num?)?.toDouble() ?? 0;
    final isFinished = data['isFinished'] as bool? ?? false;
    debugPrint('[Sync] Syncing $itemId: currentTime=$currentTime, duration=$duration, isFinished=$isFinished, sessionId=$sessionId');

    try {
      if (sessionId != null) {
        await api.syncPlaybackSession(
          sessionId,
          currentTime: currentTime,
          duration: duration,
        );
      } else {
        await api.updateProgress(
          itemId,
          currentTime: currentTime,
          duration: duration,
          isFinished: isFinished,
        );
      }

      final pendingList = await ScopedPrefs.getStringList('pending_syncs');
      pendingList.remove(itemId);
      await ScopedPrefs.setStringList('pending_syncs', pendingList);

      debugPrint('[Sync] Synced $itemId: ${currentTime}s');
      return true;
    } catch (e) {
      debugPrint('[Sync] Failed for $itemId: $e');
      return false;
    }
  }

  /// Flush all pending syncs (call when coming back online).
  /// Compares local vs server timestamps — last-write-wins.
  Future<void> flushPendingSync({ApiService? api, int maxItems = 5}) async {
    if (!_isOnline || api == null) return;

    if (_isFlushing) {
      _flushAgain = true;
      return;
    }

    _isFlushing = true;
    try {
      final pendingList = List<String>.from(
          await ScopedPrefs.getStringList('pending_syncs'));

      if (pendingList.isEmpty) return;

      final batch = pendingList.take(maxItems).toList();
      debugPrint('[Sync] Flushing ${batch.length}/${pendingList.length} pending syncs');

      for (final itemId in batch) {
        final data = await getLocal(itemId);
        if (data == null) {
          final updated = await ScopedPrefs.getStringList('pending_syncs');
          updated.remove(itemId);
          await ScopedPrefs.setStringList('pending_syncs', updated);
          continue;
        }

        final localTime = (data['currentTime'] as num?)?.toDouble() ?? 0;
        final localDuration = (data['duration'] as num?)?.toDouble() ?? 0;
        final localTimestamp = (data['timestamp'] as num?)?.toInt() ?? 0;
        if (localTime <= 0) {
          final updated = await ScopedPrefs.getStringList('pending_syncs');
          updated.remove(itemId);
          await ScopedPrefs.setStringList('pending_syncs', updated);
          continue;
        }

        try {
          final serverProgress = await api.getItemProgress(itemId);
          if (serverProgress != null) {
            final serverTimestamp = (serverProgress['lastUpdate'] as num?)?.toInt() ?? 0;
            final serverTime = (serverProgress['currentTime'] as num?)?.toDouble() ?? 0;

            // Check if there's pending offline listening time for this item.
            // If so, the server doesn't have the full picture yet - always
            // push local to avoid overwriting progress with a stale position.
            final hasOfflineListening =
                (await ScopedPrefs.getInt('offline_listening_$itemId') ?? 0) > 0;

            if (SyncLogic.shouldPullServer(
              serverTimestamp: serverTimestamp,
              serverTime: serverTime,
              localTimestamp: localTimestamp,
              localTime: localTime,
              hasOfflineListening: hasOfflineListening,
            )) {
              debugPrint('[Sync] Server is newer for $itemId: server=$serverTime s ($serverTimestamp) vs local=$localTime s ($localTimestamp) — pulling');
              await cacheServerProgress(
                itemId: itemId,
                currentTime: serverTime,
                duration: localDuration,
                isFinished: serverProgress['isFinished'] as bool? ?? false,
              );
              final updated = await ScopedPrefs.getStringList('pending_syncs');
              updated.remove(itemId);
              await ScopedPrefs.setStringList('pending_syncs', updated);
              continue;
            }
            debugPrint('[Sync] Local is newer for $itemId: local=$localTime s ($localTimestamp) vs server=$serverTime s ($serverTimestamp) — pushing');
          }

          // Use the direct progress endpoint instead of creating a new
          // playback session.  Creating a session can invalidate the
          // player's active session on the server, causing subsequent
          // in-playback syncs to silently fail.
          final isCompound = itemId.length > 36;
          final apiItemId = isCompound ? itemId.substring(0, 36) : itemId;
          final episodeId = isCompound ? itemId.substring(37) : null;

          final localFinished = data['isFinished'] as bool? ?? false;
          if (episodeId != null) {
            await api.updateEpisodeProgress(
              apiItemId, episodeId,
              currentTime: localTime,
              duration: localDuration,
              isFinished: localFinished,
            );
          } else {
            await api.updateProgress(
              apiItemId,
              currentTime: localTime,
              duration: localDuration,
              isFinished: localFinished,
            );
          }
          debugPrint('[Sync] Flushed $itemId via progress update: ${localTime}s');
          // Reset backoff on success - a successful response proves
          // the server is reachable, so resume normal sync behaviour.
          if (_consecutiveFailures > 0) {
            debugPrint('[Sync] Backoff reset (was $_consecutiveFailures)');
            _consecutiveFailures = 0;
          }

          final updated = await ScopedPrefs.getStringList('pending_syncs');
          updated.remove(itemId);
          await ScopedPrefs.setStringList('pending_syncs', updated);
        } catch (e) {
          debugPrint('[Sync] Flush failed for $itemId: $e');
          // Stop the batch on any network/TLS error - don't keep hammering
          final msg = e.toString();
          if (msg.contains('SocketException') ||
              msg.contains('connection abort') ||
              msg.contains('HandshakeException') ||
              msg.contains('CERTIFICATE_VERIFY_FAILED') ||
              msg.contains('Connection refused') ||
              msg.contains('Connection reset') ||
              msg.contains('timed out') ||
              msg.contains('TimeoutException') ||
              msg.contains('Network is unreachable')) {
            debugPrint('[Sync] Network/TLS error - stopping flush');
            _consecutiveFailures++;
            break;
          }
        }
      }
      // Also flush offline listening time while we have a connection
      if (_consecutiveFailures == 0) {
        await _flushOfflineListeningTimeInternal(api: api);
      }
    } finally {
      _isFlushing = false;
    }

    final remaining = await ScopedPrefs.getStringList('pending_syncs');
    final pendingOffline = await ScopedPrefs.getStringList('pending_offline_listening');
    if ((_flushAgain || remaining.isNotEmpty || pendingOffline.isNotEmpty) && _isOnline) {
      _flushAgain = false;

      // Exponential backoff: 5s, 10s, 20s, 40s, ... capped at 5 minutes
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        debugPrint('[Sync] Too many consecutive failures ($_consecutiveFailures) - waiting for next connectivity change');
        return;
      }
      final clampedDelay = SyncLogic.backoffDelay(_consecutiveFailures);
      debugPrint('[Sync] Scheduling retry in ${clampedDelay.inSeconds}s (failures=$_consecutiveFailures)');

      unawaited(
        Future<void>.delayed(clampedDelay, () {
          return flushPendingSync(api: api, maxItems: maxItems);
        }),
      );
    } else {
      _flushAgain = false;
    }
  }

  // ── Offline listening time tracking ──

  /// Add listening time for an item that was played offline.
  Future<void> addOfflineListeningTime(String itemId, int seconds) async {
    if (seconds <= 0) return;
    final key = 'offline_listening_$itemId';
    final existing = await ScopedPrefs.getInt(key) ?? 0;
    await ScopedPrefs.setInt(key, existing + seconds);
    debugPrint('[Sync] Offline listening +${seconds}s for $itemId (total=${existing + seconds}s)');

    // Track which items have pending offline time
    final pending = await ScopedPrefs.getStringList('pending_offline_listening');
    if (!pending.contains(itemId)) {
      pending.add(itemId);
      await ScopedPrefs.setStringList('pending_offline_listening', pending);
    }
  }

  /// Flush accumulated offline listening time to the server by creating
  /// a session, syncing the accumulated time, and closing it.
  /// Called externally (e.g. from library_provider) and also internally
  /// from flushPendingSync's retry loop.
  Future<void> flushOfflineListeningTime({required ApiService api}) async {
    if (!_isOnline) return;
    await _flushOfflineListeningTimeInternal(api: api);
  }

  Future<void> _flushOfflineListeningTimeInternal({required ApiService api}) async {
    // Guard against concurrent runs. Without this, "back online" triggers
    // both the external flushOfflineListeningTime and flushPendingSync's
    // internal tail-call to this method, producing duplicate listening
    // sessions on the server.
    if (_isFlushingOfflineListening) return;
    _isFlushingOfflineListening = true;
    try {
      final pending = List<String>.from(
          await ScopedPrefs.getStringList('pending_offline_listening'));
      if (pending.isEmpty) return;
      final flushed = <String>{};

      debugPrint('[Sync] Flushing offline listening time for ${pending.length} item(s)');

      for (final itemId in pending) {
        final key = 'offline_listening_$itemId';
        final seconds = await ScopedPrefs.getInt(key) ?? 0;
        if (seconds <= 0) {
          await ScopedPrefs.remove(key);
          flushed.add(itemId);
          continue;
        }

        final data = await getLocal(itemId);
        final currentTime = (data?['currentTime'] as num?)?.toDouble() ?? 0;
        final duration = (data?['duration'] as num?)?.toDouble() ?? 0;

        try {
          final isCompound = itemId.length > 36;
          final apiItemId = isCompound ? itemId.substring(0, 36) : itemId;
          final episodeId = isCompound ? itemId.substring(37) : null;

          final sessionData = episodeId != null
              ? await api.startEpisodePlaybackSession(apiItemId, episodeId)
              : await api.startPlaybackSession(apiItemId);

          if (sessionData != null) {
            final sid = sessionData['id'] as String?;
            if (sid != null) {
              await api.syncPlaybackSession(
                sid,
                currentTime: currentTime,
                duration: duration,
                timeListened: seconds,
              );
              await api.closePlaybackSession(sid);
              debugPrint('[Sync] Flushed ${seconds}s offline listening for $itemId');
            }
          }
          // Subtract only what we actually synced. Any ticks added to the
          // key during the flush (e.g. a +60s tick that fired while the
          // server session was in flight) are preserved for the next run
          // instead of being wiped by an outright remove.
          final current = await ScopedPrefs.getInt(key) ?? 0;
          final remaining = current - seconds;
          if (remaining > 0) {
            await ScopedPrefs.setInt(key, remaining);
          } else {
            await ScopedPrefs.remove(key);
            flushed.add(itemId);
          }
        } catch (e) {
          debugPrint('[Sync] Failed to flush offline listening for $itemId: $e');
          final msg = e.toString();
          if (msg.contains('SocketException') ||
              msg.contains('TimeoutException') ||
              msg.contains('timed out') ||
              msg.contains('Connection refused') ||
              msg.contains('Network is unreachable')) {
            _consecutiveFailures++;
            break;
          }
        }
      }

      // Only remove successfully flushed items from pending list
      if (flushed.isNotEmpty) {
        final remaining = List<String>.from(
            await ScopedPrefs.getStringList('pending_offline_listening'));
        remaining.removeWhere((id) => flushed.contains(id));
        await ScopedPrefs.setStringList('pending_offline_listening', remaining);
      }
    } finally {
      _isFlushingOfflineListening = false;
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
