import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'progress_sync_service.dart';
import 'scoped_prefs.dart';

/// Owns client-built LOCAL playback sessions for downloaded/offline plays.
///
/// Why this exists: routing downloaded listening through the live `/play`
/// session makes the server log "Direct Play" (GH #276) and, when offline,
/// collapses days of listening into one session dated "now" (GH #280). This
/// service instead builds Audiobookshelf local sessions (`playMethod: 3`),
/// accrues `timeListening` as a cumulative total, and mints a fresh session id
/// at each calendar-day boundary so each day's listening is attributed to the
/// right day. Position/progress is NOT handled here — it stays on the existing
/// `/me/progress` path (see [ProgressSyncService]).
///
/// Timestamps (`startedAt`/`updatedAt`/`date`) are captured at accrual time and
/// replayed verbatim; they are never restamped at flush, which is what would
/// re-collapse multi-day offline listening onto the reconnect day.
class LocalSessionService {
  LocalSessionService._();
  static final LocalSessionService _instance = LocalSessionService._();
  factory LocalSessionService() => _instance;

  static const _kActive = 'local_session_active';
  static const _kPending = 'local_session_pending';

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  /// Clock seam — overridden in tests to simulate day boundaries.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  Map<String, dynamic>? _active;
  bool _loaded = false;
  bool _flushing = false;
  // Set once a server returns 404/501 for /api/session/local: that server is
  // too old, so route everything through the legacy /play flush instead.
  bool _localUnsupported = false;

  // ── Date helpers (must match home_widget_service._dateKey so day buckets
  //    line up with the streak calculation). ──

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dayOfWeek(DateTime d) => _weekdays[d.weekday - 1];

  String _uuid() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant
    String h(int x) => x.toRadixString(16).padLeft(2, '0');
    final s = b.map(h).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  // ── Persistence ──

  Future<void> _loadActive() async {
    if (_loaded) return;
    final raw = await ScopedPrefs.getString(_kActive);
    if (raw != null) {
      try {
        _active = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        _active = null;
      }
    }
    _loaded = true;
  }

  Future<void> _persistActive() async {
    if (_active == null) {
      await ScopedPrefs.remove(_kActive);
    } else {
      await ScopedPrefs.setString(_kActive, jsonEncode(_active));
    }
  }

  Future<void> _enqueue(Map<String, dynamic> session) async {
    final pending = await ScopedPrefs.getStringList(_kPending);
    pending.add(jsonEncode(session));
    await ScopedPrefs.setStringList(_kPending, pending);
  }

  /// The subset sent to the server. deviceInfo/mediaPlayer/playMethod are
  /// stamped by [ApiService.syncLocalSession]/[ApiService.syncLocalSessionsAll].
  Map<String, dynamic> _payload(Map<String, dynamic> s) => {
        'id': s['id'],
        'libraryItemId': s['libraryItemId'],
        'episodeId': s['episodeId'],
        'mediaType': s['mediaType'],
        'displayTitle': s['displayTitle'],
        'displayAuthor': s['displayAuthor'],
        'duration': s['duration'],
        'startTime': s['startTime'],
        'currentTime': s['currentTime'],
        'timeListening': s['timeListening'],
        'startedAt': s['startedAt'],
        'updatedAt': s['updatedAt'],
        'date': s['date'],
        'dayOfWeek': s['dayOfWeek'],
      };

  /// Swap the payload's duration for the item's server-side duration when it
  /// can be fetched - a wrong player duration on a session otherwise corrupts
  /// the server's progress percent (abs issue #5468).
  Future<Map<String, dynamic>> _trustedPayload(
      ApiService api, Map<String, dynamic> s) async {
    final payload = _payload(s);
    final key = s['progressKey'] as String? ??
        (s['episodeId'] != null
            ? '${s['libraryItemId']}-${s['episodeId']}'
            : s['libraryItemId'] as String? ?? '');
    if (key.isNotEmpty) {
      final local = (payload['duration'] as num?)?.toDouble() ?? 0;
      payload['duration'] =
          await ProgressSyncService().serverTrustedDuration(api, key, local);
    }
    return payload;
  }

  /// Reset in-memory state between tests.
  @visibleForTesting
  void debugReset() {
    _active = null;
    _loaded = false;
    _flushing = false;
    _localUnsupported = false;
    clock = DateTime.now;
  }

  // ── Public API ──

  /// On startup, treat any surviving active session as orphaned (the process
  /// that owned it is gone): move it to the replay queue so it ships on the
  /// next connection, and start clean.
  Future<void> init() async {
    await _loadActive();
    if (_active != null) {
      debugPrint('[LocalSession] Recovering orphaned active session ${_active!['id']} into pending');
      await _enqueue(_active!);
      _active = null;
      await _persistActive();
    }
  }

  /// Begin a local session for a freshly started downloaded play. Finalizes any
  /// leftover active session for a different item first.
  Future<void> beginSession({
    required String progressKey,
    required String libraryItemId,
    String? episodeId,
    required String mediaType,
    required double duration,
    required double startTime,
    String? displayTitle,
    String? displayAuthor,
  }) async {
    await _loadActive();
    final now = clock();
    final nowMs = now.millisecondsSinceEpoch;
    final today = _dateKey(now);
    // Resume the existing session only if it's the same item on the same day.
    if (_active != null &&
        _active!['progressKey'] == progressKey &&
        _active!['date'] == today) {
      return;
    }
    // Any other lingering session — a different item, or the same item from a
    // prior day (e.g. paused overnight, resumed by re-tapping the next day) —
    // must be queued for replay before starting fresh, or its accrued
    // listening would be dropped.
    if (_active != null) {
      await finalizeActive();
    }
    _active = {
      'id': _uuid(),
      'progressKey': progressKey,
      'libraryItemId': libraryItemId,
      'episodeId': episodeId,
      'mediaType': mediaType,
      'duration': duration,
      'startTime': startTime,
      'currentTime': startTime,
      'timeListening': 0,
      'startedAt': nowMs,
      'updatedAt': nowMs,
      'date': today,
      'dayOfWeek': _dayOfWeek(now),
      // Sent so the server session shows the episode (for podcasts) rather than
      // defaulting to the library item title (the show). Books send their title.
      'displayTitle': displayTitle,
      'displayAuthor': displayAuthor,
    };
    await _persistActive();
    debugPrint('[LocalSession] Began session ${_active!['id']} for $progressKey ($today)');
  }

  /// Accrue [seconds] of listening at [currentTime]. Rolls over to a new
  /// session id when the calendar day changes. When [api] is non-null (online),
  /// also upserts the active session.
  Future<void> accrue({
    required String progressKey,
    required int seconds,
    required double currentTime,
    ApiService? api,
  }) async {
    if (seconds <= 0) return;
    await _loadActive();
    if (_active == null) {
      debugPrint('[LocalSession] accrue with no active session — skipping');
      return;
    }
    if (_active!['progressKey'] != progressKey) {
      debugPrint('[LocalSession] accrue key mismatch (${_active!['progressKey']} != $progressKey) — finalizing stale session');
      await finalizeActive();
      return;
    }

    final lastMs = (_active!['updatedAt'] as num).toInt();
    // A backward device clock must never move the session to an earlier day or
    // mint a spurious session — clamp to the last accrual time so the day is
    // derived from a non-decreasing timestamp.
    final rawMs = clock().millisecondsSinceEpoch;
    final nowMs = rawMs < lastMs ? lastMs : rawMs;
    final effective = DateTime.fromMillisecondsSinceEpoch(nowMs);
    final today = _dateKey(effective);

    if (_active!['date'] != today) {
      // Day boundary: freeze the old session (verbatim timestamps) and start a
      // new one for today so listening is attributed to the correct day.
      final old = _active!;
      debugPrint('[LocalSession] Day rollover: ${old['date']} -> $today (session ${old['id']})');
      await _enqueue(old);
      _active = {
        'id': _uuid(),
        'progressKey': progressKey,
        'libraryItemId': old['libraryItemId'],
        'episodeId': old['episodeId'],
        'mediaType': old['mediaType'],
        'duration': old['duration'],
        'startTime': currentTime,
        'currentTime': currentTime,
        'timeListening': 0,
        'startedAt': nowMs,
        'updatedAt': nowMs,
        'date': today,
        'dayOfWeek': _dayOfWeek(effective),
        'displayTitle': old['displayTitle'],
        'displayAuthor': old['displayAuthor'],
      };
      // Ship the just-closed day promptly when online.
      if (api != null) await flushPending(api: api);
    }

    _active!['timeListening'] = (_active!['timeListening'] as num).toInt() + seconds;
    _active!['currentTime'] = currentTime;
    _active!['updatedAt'] = nowMs;
    _active!['date'] = today;
    _active!['dayOfWeek'] = _dayOfWeek(effective);
    await _persistActive();

    if (api != null) await pushActive(api: api);
  }

  /// Upsert the active session now (idempotent — cumulative total). Returns
  /// true when the server durably recorded it (so the caller can skip queuing).
  Future<bool> pushActive({required ApiService api}) async {
    await _loadActive();
    if (_active == null) return true;
    if (_localUnsupported) {
      await _legacyFlush(api, _active!);
      return true;
    }
    final result =
        await api.syncLocalSession(await _trustedPayload(api, _active!));
    if (result.serverTooOld) {
      debugPrint('[LocalSession] Server lacks /api/session/local — falling back to /play');
      _localUnsupported = true;
      await _legacyFlush(api, _active!);
      return true;
    }
    return result.ok;
  }

  /// Clear the active session (stop / finish / item change). When [pushed] is
  /// false (offline, or the push failed) it's queued for replay; when true it's
  /// already on the server so we just drop it.
  Future<void> finalizeActive({bool pushed = false}) async {
    await _loadActive();
    if (_active == null) return;
    if (!pushed) await _enqueue(_active!);
    _active = null;
    await _persistActive();
  }

  /// Replay queued sessions (plus the in-progress active session) to the
  /// server. Called on reconnect / manual-offline-off.
  Future<void> flushPending({required ApiService api}) async {
    if (_flushing) return;
    _flushing = true;
    try {
      await _loadActive();
      final pendingRaw = await ScopedPrefs.getStringList(_kPending);
      final sessions = <Map<String, dynamic>>[];
      for (final raw in pendingRaw) {
        try {
          sessions.add(jsonDecode(raw) as Map<String, dynamic>);
        } catch (_) {}
      }
      // Include the active session so its accrued time isn't stranded until the
      // next finalize (e.g. reconnect while paused).
      final combined = [...sessions, if (_active != null) _active!];
      if (combined.isEmpty) return;

      if (_localUnsupported) {
        for (final s in combined) {
          await _legacyFlush(api, s);
        }
        await ScopedPrefs.setStringList(_kPending, []);
        return;
      }

      final payloads = <Map<String, dynamic>>[];
      for (final s in combined) {
        payloads.add(await _trustedPayload(api, s));
      }
      final result = await api.syncLocalSessionsAll(payloads);
      if (result.ok) {
        // Keep the active session live; only clear the finalized queue.
        await ScopedPrefs.setStringList(_kPending, []);
        debugPrint('[LocalSession] Flushed ${combined.length} local session(s)');
      } else if (result.serverTooOld) {
        debugPrint('[LocalSession] Server lacks /api/session/local-all — falling back to /play');
        _localUnsupported = true;
        for (final s in combined) {
          await _legacyFlush(api, s);
        }
        await ScopedPrefs.setStringList(_kPending, []);
      }
      // Network failure: leave the queue intact for the next trigger.
    } finally {
      _flushing = false;
    }
  }

  /// Fallback for servers without /api/session/local: record the listening time
  /// via the legacy open `/play` session. Loses per-day attribution and logs as
  /// Direct Play (the old behavior), but doesn't lose the time.
  Future<void> _legacyFlush(ApiService api, Map<String, dynamic> s) async {
    try {
      final libId = s['libraryItemId'] as String;
      final epId = s['episodeId'] as String?;
      final currentTime = (s['currentTime'] as num?)?.toDouble() ?? 0;
      final duration = (s['duration'] as num?)?.toDouble() ?? 0;
      final secs = (s['timeListening'] as num?)?.toInt() ?? 0;
      if (secs <= 0) return;
      final data = epId != null
          ? await api.startEpisodePlaybackSession(libId, epId)
          : await api.startPlaybackSession(libId);
      final sid = data?['id'] as String?;
      if (sid != null) {
        await api.syncPlaybackSession(sid,
            currentTime: currentTime, duration: duration, timeListened: secs);
        await api.closePlaybackSession(sid);
      }
    } catch (e) {
      debugPrint('[LocalSession] legacy flush failed: $e');
    }
  }
}
