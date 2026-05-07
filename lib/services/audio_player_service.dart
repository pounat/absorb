import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'download_service.dart';
import 'playback_history_service.dart' hide PlaybackEvent;
import 'progress_sync_service.dart';
import 'sleep_timer_service.dart';
import 'equalizer_service.dart';
import 'android_auto_service.dart';
import 'chromecast_service.dart';
import 'chapter_lookup.dart';
import 'cold_start_play_policy.dart';
import 'player_settings.dart';
import 'session_cache.dart';
import 'home_widget_service.dart';
export 'player_settings.dart';

// ─── AudioHandler (runs in background, controls notification) ───

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: false,
    // Bypass the local HTTP proxy — headers are sent natively on both
    // platforms (ExoPlayer via setDefaultRequestProperties, AVPlayer via
    // AVURLAssetHTTPHeaderFieldsKey). The proxy doubles the packet count.
    useProxyForRequestHeaders: false,
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        bufferForPlaybackDuration: Duration(seconds: 2),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 5),
        targetBufferBytes: 5 * 1024 * 1024, // 5 MB buffer
      ),
    ),
  );
  AudioPlayerService? _service; // back-reference for auto-rewind

  // Cached skip amounts for notification icon selection (updated when settings change)
  int _cachedForwardSkip = 30;
  int _cachedBackSkip = 10;

  AudioPlayer get player => _player;

  void bindService(AudioPlayerService service) => _service = service;

  /// Force-push current PlaybackState so the notification picks up
  /// new chapter-relative position immediately (e.g. on chapter change).
  void refreshPlaybackState() {
    try {
      playbackState.add(_transformEvent(_player.playbackEvent));
      _lastPlaybackStateUpdate = DateTime.now();
      _lastPlaying = _player.playing;
      _lastProcessingState = _player.processingState;
    } catch (_) {}
  }

  AudioPlayerHandler() {
    _subscribePlaybackEvents();
  }

  /// Subscribe to the player's playback event stream and forward state to
  /// the system MediaSession. If the stream errors or completes unexpectedly,
  /// re-subscribe so system media controls stay alive.
  /// Rate-limited to prevent infinite error loops (e.g. multi-channel audio).
  int _resubscribeCount = 0;
  DateTime _lastResubscribe = DateTime.now();

  // Throttle playback state updates to avoid excessive notification refreshes
  DateTime _lastPlaybackStateUpdate = DateTime.now();
  bool? _lastPlaying;
  ProcessingState? _lastProcessingState;

  void _subscribePlaybackEvents() {
    _player.playbackEventStream.map(_transformEvent).listen(
      (state) {
        // Only push state on meaningful changes (play/pause, processing state)
        // or at most every 5 seconds for position updates
        final now = DateTime.now();
        final playingChanged = _player.playing != _lastPlaying;
        final processingChanged = _player.processingState != _lastProcessingState;
        final elapsed = now.difference(_lastPlaybackStateUpdate);

        if (playingChanged || processingChanged || elapsed.inSeconds >= 5) {
          playbackState.add(state);
          _lastPlaybackStateUpdate = now;
          _lastPlaying = _player.playing;
          _lastProcessingState = _player.processingState;
        }
        // Reset error counter on successful events
        _resubscribeCount = 0;
      },
      onError: (Object e, StackTrace st) {
        final now = DateTime.now();
        // Reset counter if it's been more than 5 seconds since last error
        if (now.difference(_lastResubscribe).inSeconds > 5) {
          _resubscribeCount = 0;
        }
        _lastResubscribe = now;
        _resubscribeCount++;

        if (_resubscribeCount <= 3) {
          debugPrint('[Player] playbackEvent error ($_resubscribeCount/3) - re-subscribing: $e');
          refreshPlaybackState();
          Future.delayed(const Duration(seconds: 1), _subscribePlaybackEvents);
        } else {
          debugPrint('[Player] playbackEvent error - too many rapid failures, stopping re-subscribe: $e');
          final errStr = e.toString();
          if (errStr.contains('MediaCodecAudioRenderer') ||
              errStr.contains('AudioTrack') ||
              errStr.contains('Decoder') ||
              errStr.contains('format_supported')) {
            AudioPlayerService()._retryWithTranscode();
          }
        }
      },
      onDone: () {
        _resubscribeCount++;
        if (_resubscribeCount <= 3) {
          debugPrint('[Player] playbackEvent stream completed ($_resubscribeCount/3) - re-subscribing');
          refreshPlaybackState();
          Future.delayed(const Duration(seconds: 1), _subscribePlaybackEvents);
        } else {
          debugPrint('[Player] playbackEvent stream completed - too many rapid re-subscribes, stopping');
        }
      },
    );
  }


  PlaybackState _transformEvent(PlaybackEvent event) {
    final playPause = _player.playing ? MediaControl.pause : MediaControl.play;

    final rewindControl = MediaControl(
      androidIcon: 'drawable/ic_skip_back',
      label: 'Back ${_cachedBackSkip}s',
      action: MediaAction.rewind,
    );
    final fastForwardControl = MediaControl(
      androidIcon: 'drawable/ic_skip_forward',
      label: 'Forward ${_cachedForwardSkip}s',
      action: MediaAction.fastForward,
    );

    // 3 controls: rewind | play | forward.
    final controls = [rewindControl, playPause, fastForwardControl];
    final compactIndices = const [0, 1, 2];

    return PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToQueueItem,
      },
      androidCompactActionIndices: compactIndices,
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _speedAdjustedPosition(),
      bufferedPosition: _player.bufferedPosition,
      // Report speed as 1.0 because duration and position are already
      // divided by the playback speed. This makes Android Auto, WearOS,
      // and the notification show "real time remaining" instead of raw
      // content duration.
      speed: 1.0,
      queueIndex: _safeCurrentChapterIndex(),
    );
  }

  /// Return the index of the chapter containing the current playback position,
  /// or null if there are no chapters.  Used as queueIndex so Android Auto
  /// highlights the active chapter in the queue view.
  int? _safeCurrentChapterIndex() {
    try {
      if (_service == null) return null;
      final posSec = _player.position.inMilliseconds / 1000.0;
      return ChapterLookup.indexAt(
        _service!.chapters,
        posSec,
        _service!.totalDuration,
      );
    } catch (e) {
      debugPrint('[Handler] _safeCurrentChapterIndex error: $e');
      return null;
    }
  }

  /// Compute the position to report to the MediaSession, divided by playback
  /// speed so that Android Auto / WearOS / notification show "real time
  /// remaining" rather than raw content duration.
  Duration _speedAdjustedPosition() {
    Duration pos;
    if (_service != null && _service!.notifChapterMode) {
      final absPos = _service!.position;
      final chStart = Duration(seconds: _service!.currentChapterStart.round());
      final relative = absPos - chStart;
      pos = relative.isNegative ? Duration.zero : relative;
    } else {
      pos = _service?.position ?? _player.position;
    }
    final speed = _player.speed;
    if (speed <= 0 || speed == 1.0) return pos;
    return Duration(milliseconds: (pos.inMilliseconds / speed).round());
  }

  @override
  Future<void> play() async {
    debugPrint('[Handler] play() called - routing to service (state=${_player.processingState.name})');
    final entryBt = await AudioPlayerService._isBluetoothAudioConnected();
    if (entryBt) AudioPlayerService._lastPlayedOnBtAt = DateTime.now();
    debugPrint('[ClickDebug] play() entry: ${_clickDebugSnapshot(btNow: entryBt)}');
    // Mirror the click() guard: a raw play() arriving within 5s of a
    // headphone/AA/BT disconnect is almost always the platform echoing a
    // resume command, not the user. Drop it so playback doesn't jump to
    // the phone speaker after the user unplugs or AA tears down.
    if (_noisyPauseAt != null) {
      final elapsed = DateTime.now().difference(_noisyPauseAt!).inMilliseconds;
      if (elapsed < 5000) {
        debugPrint('[Handler] Ignoring phantom play (${elapsed}ms after platform pause)');
        return;
      }
      _noisyPauseAt = null;
    }
    _lastHandlerPlayAt = DateTime.now();
    if (_service != null) {
      await _service!.play();
    } else {
      debugPrint('[Handler] play() - no service ref, using player directly');
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    debugPrint('[Handler] pause() called - routing to service');
    final pauseEntryBt = await AudioPlayerService._isBluetoothAudioConnected();
    debugPrint('[ClickDebug] pause() entry: ${_clickDebugSnapshot(btNow: pauseEntryBt)}');
    _lastHandlerPauseAt = DateTime.now();
    // Android Auto disconnect can dispatch both a MediaButton click and a
    // pause() action simultaneously. The click's 400ms debounce timer would
    // then see playing=false and misinterpret it as "user wants to play",
    // triggering a cold-start restore. Cancel any pending click so the
    // platform-initiated pause wins.
    final clickPending = _clickTimer?.isActive ?? false;
    if (clickPending) {
      debugPrint('[Handler] Cancelling pending click (platform pause)');
      _clickTimer!.cancel();
      _clickCount = 0;
    }
    // A pause arriving outside the click resolver is the platform signalling
    // a disconnect (AA tearing down, BT going away, headphones unplugged).
    // Stamp _noisyPauseAt so the play() / click() guards drop any spurious
    // resume commands that follow in the next 5s. becomingNoisy already
    // stamps for the headphone-unplug case; this covers AA/BT disconnect
    // where no noisy event fires.
    if (!_inClickResolver) {
      _noisyPauseAt = DateTime.now();
    }
    if (_service != null) {
      await _service!.pause();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('[Handler] seek(${position.inSeconds}s)');
    if (_service != null) {
      final speed = _player.speed;
      final realPos = speed > 0 && speed != 1.0
          ? Duration(milliseconds: (position.inMilliseconds * speed).round())
          : position;
      final absPos = _service!.notifChapterMode
          ? realPos + Duration(seconds: _service!.currentChapterStart.round())
          : realPos;
      await _service!.seekTo(absPos);
    } else {
      await _player.seek(position);
    }
  }

  @override
  Future<void> stop() async {
    // Don't call super.stop() - it deactivates the MediaSession, and on some
    // devices (Android 16+) the system never re-routes BT media buttons /
    // notification controls to a reactivated session. Same reasoning as
    // onTaskRemoved below: keep the session alive so external controls
    // recover when the user comes back. Just stop the player.
    //
    // Alpha: stack trace tells us who is calling stop() so we can decide if
    // any caller deserves a true teardown. Strip [Handler] stop trace before
    // beta.
    debugPrint('[Handler] stop() - keeping MediaSession alive '
        '(playing=${_player.playing}, processingState=${_player.processingState.name}, '
        'hasService=${_service != null})');
    debugPrint('[Handler] stop() trace:\n${StackTrace.current}');
    try { await _player.stop(); } catch (e) { debugPrint('[Handler] stop() player.stop error: $e'); }
  }

  /// Called when the user swipes the app away from recents.
  ///
  /// Only pause instead of stopping - the 10-minute pause timeout already
  /// handles cleanup (server session + audio focus). Calling stop() here
  /// deactivates the MediaSession, and on some devices (Android 16+) the
  /// system never re-routes BT media buttons to a reactivated session,
  /// leaving earbud controls permanently broken until reboot.
  @override
  Future<void> onTaskRemoved() async {
    debugPrint('[Handler] onTaskRemoved - app swiped away');
    // Don't stop cast playback when app is swiped away
    if (ChromecastService().isCasting) return;
    if (_service != null) {
      await _service!.pause();
    } else {
      await _player.pause();
    }
    // Don't call super.onTaskRemoved() - it calls stop() which deactivates
    // the MediaSession and breaks BT media button routing on restart.
  }

  @override
  Future<void> fastForward() async {
    debugPrint('[Handler] fastForward() - seeking forward');
    if (_service != null) {
      final skipAmount = await PlayerSettings.getForwardSkip();
      await _service!.skipForward(skipAmount);
    } else {
      final skipAmount = await PlayerSettings.getForwardSkip();
      final adjusted = (skipAmount * _player.speed).round();
      await _player.seek(_player.position + Duration(seconds: adjusted));
    }
  }

  @override
  Future<void> rewind() async {
    debugPrint('[Handler] rewind() - seeking back');
    if (_service != null) {
      final skipAmount = await PlayerSettings.getBackSkip();
      await _service!.skipBackward(skipAmount);
    } else {
      final skipAmount = await PlayerSettings.getBackSkip();
      final adjusted = (skipAmount * _player.speed).round();
      var pos = _player.position - Duration(seconds: adjusted);
      if (pos < Duration.zero) pos = Duration.zero;
      await _player.seek(pos);
    }
  }

  // Custom click handler with proper multi-press detection
  Timer? _clickTimer;
  int _clickCount = 0;
  DateTime? _hardwareButtonTime; // cooldown after hardware next/prev
  DateTime? _noisyPauseAt; // suppress clicks for a window after BT disconnect
  // True while the click resolver is synchronously calling pause()/play().
  // pause() uses this to skip stamping _noisyPauseAt for click-driven pauses,
  // so legit user pause-then-play flows are not blocked by the disconnect guard.
  bool _inClickResolver = false;
  // [ClickDebug] — timestamp of the last Handler-level pause() call.
  // Used to correlate phantom play/click commands with a preceding pause.
  DateTime? _lastHandlerPauseAt;
  // [ClickDebug] — timestamp of the last Handler-level play() call.
  // Used to spot the variant-3 phantom-resume fingerprint: click-initiated
  // play followed by a raw pause a few seconds later (AA disconnect tearing
  // down after a spurious transport event).
  DateTime? _lastHandlerPlayAt;

  /// [ClickDebug] — one-line snapshot of state around a media-button event.
  /// Helps diagnose phantom clicks after Android Auto disconnect.
  ///
  /// `btNow` should be pre-fetched async by the caller when available so
  /// the AA-disconnect heuristic can be evaluated. When null, that flag
  /// is reported as `unknown`.
  String _clickDebugSnapshot({bool? btNow}) {
    final now = DateTime.now();
    int sincePrevPauseMs = -1;
    if (_lastHandlerPauseAt != null) {
      sincePrevPauseMs = now.difference(_lastHandlerPauseAt!).inMilliseconds;
    }
    int sincePrevPlayMs = -1;
    if (_lastHandlerPlayAt != null) {
      sincePrevPlayMs = now.difference(_lastHandlerPlayAt!).inMilliseconds;
    }
    int sinceForegroundMs = -1;
    if (AudioPlayerService._lastForegroundAt != null) {
      sinceForegroundMs = now.difference(AudioPlayerService._lastForegroundAt!).inMilliseconds;
    }
    int sinceNoisyPauseMs = -1;
    if (_noisyPauseAt != null) {
      sinceNoisyPauseMs = now.difference(_noisyPauseAt!).inMilliseconds;
    }
    final backgrounded = _service?.isBackgrounded;
    // Variant-3 fingerprint: raw pause fires within 5s of a click-initiated
    // play while still playing in background. Flag it so the pause log line
    // is self-describing without having to cross-reference timestamps.
    final phantomSuspect = sincePrevPlayMs >= 0
        && sincePrevPlayMs < 5000
        && _player.playing
        && (backgrounded ?? false);
    // AA-disconnect fingerprint: BT/AA was the audio route within the last
    // 10 min, isn't anymore, and the click came in while bg + not playing.
    int sinceBtMs = -1;
    final lastBt = AudioPlayerService._lastPlayedOnBtAt;
    if (lastBt != null) sinceBtMs = now.difference(lastBt).inMilliseconds;
    final String aaDisconnect;
    if (btNow == null) {
      aaDisconnect = 'unknown';
    } else {
      final fired = lastBt != null
          && !btNow
          && sinceBtMs >= 0
          && sinceBtMs < 600000;
      aaDisconnect = fired ? 'true' : 'false';
    }
    return 'bg=$backgrounded, sincePrevPauseMs=$sincePrevPauseMs, '
        'sincePrevPlayMs=$sincePrevPlayMs, '
        'sinceForegroundMs=$sinceForegroundMs, '
        'sinceNoisyPauseMs=$sinceNoisyPauseMs, '
        'playing=${_player.playing}, '
        'processingState=${_player.processingState.name}, '
        'noisyPause=${AudioPlayerService._noisyPause}, '
        'phantomSuspect=$phantomSuspect, '
        'sinceBtMs=$sinceBtMs, btNow=${btNow ?? 'unknown'}, '
        'aaDisconnectSuspect=$aaDisconnect';
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    debugPrint('[Handler] click(button=$button) count=${_clickCount + 1} playing=${_player.playing}');
    // Pre-fetch BT-route state so the snapshot can fill in the AA-disconnect
    // heuristic and the suppression branch below has a value to test against.
    final btNow = await AudioPlayerService._isBluetoothAudioConnected();
    final snapshot = _clickDebugSnapshot(btNow: btNow);
    debugPrint('[ClickDebug] click arrival (button=$button): $snapshot');
    _service?._logEvent(PlaybackEventType.clickDebounce, detail: 'button=$button | $snapshot');

    if (button != MediaButton.media) {
      // Hardware next/prev button — set cooldown to ignore phantom media click
      _hardwareButtonTime = DateTime.now();
      if (button == MediaButton.next) {
        debugPrint('[Handler] Hardware NEXT button');
        await fastForward();
      } else if (button == MediaButton.previous) {
        debugPrint('[Handler] Hardware PREV button');
        await rewind();
      }
      return;
    }

    // Ignore phantom media click that follows hardware next/prev within 500ms
    if (_hardwareButtonTime != null) {
      final elapsed = DateTime.now().difference(_hardwareButtonTime!).inMilliseconds;
      if (elapsed < 500) {
        debugPrint('[Handler] Ignoring phantom media click (${elapsed}ms after hardware button)');
        _hardwareButtonTime = null;
        return;
      }
      _hardwareButtonTime = null;
    }

    // Suppress phantom play commands within 5s of a BT/auto disconnect
    if (_noisyPauseAt != null) {
      final elapsed = DateTime.now().difference(_noisyPauseAt!).inMilliseconds;
      if (elapsed < 5000) {
        debugPrint('[Handler] Ignoring phantom click (${elapsed}ms after noisy pause)');
        return;
      }
      _noisyPauseAt = null;
    }

    // AA-disconnect phantom: a delayed MediaButton.media event arrives in
    // background, not playing, after we last played on BT/AA — and BT is
    // gone now. On devices where AA disconnect doesn't fire becomingNoisy
    // (Pixel 10 Pro / Android 16 observed), this is the only way to catch
    // the lingering MediaSession resume that the OS sends minutes later.
    final lastBt = AudioPlayerService._lastPlayedOnBtAt;
    final bg = _service?.isBackgrounded ?? false;
    if (bg && !_player.playing && lastBt != null && !btNow) {
      final ageMs = DateTime.now().difference(lastBt).inMilliseconds;
      if (ageMs < 600000) {
        debugPrint('[Handler] Ignoring phantom click after AA/BT disconnect '
            '(${ageMs}ms since last BT-on, btNow=false, bg=true, playing=false)');
        _service?._logEvent(PlaybackEventType.clickDebounce,
            detail: 'phantom AA/BT click suppressed | sinceBtMs=$ageMs');
        // Re-arm the 5s noisy guard so a follow-up click in the same
        // burst is also ignored, matching the BT-disconnect suppression flow.
        _noisyPauseAt = DateTime.now();
        return;
      }
    }

    _clickCount++;
    _clickTimer?.cancel();
    _clickTimer = Timer(const Duration(milliseconds: 400), () async {
      final count = _clickCount;
      _clickCount = 0;
      debugPrint('[Handler] click resolved: count=$count playing=${_player.playing}');
      final resolveBt = await AudioPlayerService._isBluetoothAudioConnected();
      debugPrint('[ClickDebug] click resolve (count=$count): ${_clickDebugSnapshot(btNow: resolveBt)}');
      switch (count) {
        case 1:
          _inClickResolver = true;
          try {
            if (_player.playing) {
              debugPrint('[Handler] → single press → PAUSE');
              await pause();
            } else {
              debugPrint('[Handler] → single press → PLAY');
              await play();
            }
          } finally {
            _inClickResolver = false;
          }
          break;
        case 2:
          debugPrint('[Handler] → double press → SKIP FORWARD');
          await fastForward();
          break;
        case 3:
        default:
          debugPrint('[Handler] → triple press → SKIP BACK');
          await rewind();
          break;
      }
    });
  }

  /// Cancel any pending media-button click so a BT disconnect doesn't
  /// accidentally resume playback on the phone speaker.
  void cancelPendingClick() {
    _noisyPauseAt = DateTime.now();
    if (_clickTimer?.isActive ?? false) {
      debugPrint('[Handler] Cancelling pending click (noisy pause)');
      _clickTimer!.cancel();
      _clickCount = 0;
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    debugPrint('[Handler] customAction($name)');
    switch (name) {
      case 'nextChapter':
        if (_service != null) await _service!.skipToNextChapter();
        break;
      case 'previousChapter':
        if (_service != null) await _service!.skipToPreviousChapter();
        break;
    }
  }

  // ─── Chapter queue (for Android Auto queue button) ─────────────────

  /// Populate the MediaSession queue with chapter entries so AA shows
  /// a chapter list via the queue button on the Now Playing screen.
  void updateChaptersQueue(List<dynamic> chapters) {
    if (chapters.isEmpty) {
      queue.add(const []);
      return;
    }
    final items = chapters.asMap().entries.map((e) {
      final ch = e.value as Map<String, dynamic>;
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? 0;
      return MediaItem(
        id: 'chapter_${e.key}',
        title: ch['title'] as String? ?? 'Chapter ${e.key + 1}',
        duration: Duration(milliseconds: ((end - start) * 1000).round()),
      );
    }).toList();
    queue.add(items);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    debugPrint('[Handler] skipToQueueItem($index)');
    if (_service == null) return;
    final chapters = _service!.chapters;
    if (index < 0 || index >= chapters.length) return;
    final start = (chapters[index]['start'] as num?)?.toDouble() ?? 0;
    await _service!.seekTo(Duration(milliseconds: (start * 1000).round()));
  }

  // ─── Android Auto browse tree ──────────────────────────────────────

  final _autoService = AndroidAutoService();

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    debugPrint('[Handler] getChildren($parentMediaId)');
    // Don't await refresh() here — getChildrenOf() handles it:
    // downloads are populated instantly, server data loads in background.
    return _autoService.getChildrenOf(parentMediaId);
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    debugPrint('[Handler] getMediaItem($mediaId)');
    return _autoService.getMediaItem(mediaId);
  }

  @override
  Future<List<MediaItem>> search(String query,
      [Map<String, dynamic>? extras]) async {
    debugPrint('[Handler] search("$query")');
    return _autoService.search(query);
  }

  @override
  Future<void> prepareFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    debugPrint('[Handler] prepareFromMediaId($mediaId)');
    await _playFromAutoMediaId(mediaId);
  }

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    debugPrint('[Handler] playFromMediaId($mediaId)');
    await _playFromAutoMediaId(mediaId);
  }

  Future<void> _playFromAutoMediaId(String mediaId) async {
    final absId = AutoMediaIds.absItemId(mediaId);
    if (absId == null) {
      debugPrint('[Handler] Invalid media ID for playback: $mediaId');
      return;
    }

    if (_service == null) {
      debugPrint('[Handler] No service bound — cannot play');
      return;
    }

    final api = await _autoService.getApi();
    if (api == null) {
      debugPrint('[Handler] No API credentials — cannot play');
      return;
    }

    // Detect podcast episodes via compound key (showId-episodeId, length > 36)
    final isEpisode = absId.length > 36;
    final showId = isEpisode ? absId.substring(0, 36) : null;
    final episodeId = isEpisode ? absId.substring(37) : null;
    // For API calls, use the show ID (not compound key) for podcast episodes
    final apiItemId = showId ?? absId;

    // Try to find in cached entries first
    var entry = _autoService.findEntry(absId);

    // If not in AA cache, check if the item is downloaded locally.
    // This handles cold-start scenarios where the AA browse tree hasn't
    // been populated yet but the user taps a downloaded item.
    if (entry == null) {
      final ds = DownloadService();
      if (ds.isDownloaded(absId)) {
        debugPrint('[Handler] Item not in AA cache but downloaded locally: $absId');
        final dl = ds.getInfo(absId);
        double duration = 0;
        List<dynamic> chapters = [];
        if (dl.sessionData != null) {
          try {
            final session = jsonDecode(dl.sessionData!) as Map<String, dynamic>;
            duration = (session['duration'] as num?)?.toDouble() ?? 0;
            chapters = session['chapters'] as List<dynamic>? ?? [];
          } catch (_) {}
        }
        entry = AutoBookEntry(
          id: absId,
          title: dl.title ?? 'Unknown',
          author: dl.author ?? '',
          duration: duration,
          coverUrl: AndroidAutoService.localCoverUri(apiItemId),
          chapters: chapters,
          episodeId: episodeId,
          showId: showId,
        );
      }
    }

    // If still not found, fetch the item details from server
    if (entry == null) {
      debugPrint('[Handler] Item not cached, fetching from server: $apiItemId');
      try {
        final response = await api.getLibraryItem(apiItemId);
        if (response != null) {
          final media = response['media'] as Map<String, dynamic>?;
          final metadata = media?['metadata'] as Map<String, dynamic>? ?? {};

          if (isEpisode) {
            // Find the specific episode in the show's episode list
            final episodes = media?['episodes'] as List<dynamic>? ?? [];
            final ep = episodes.cast<Map<String, dynamic>?>().firstWhere(
              (e) => e?['id'] == episodeId,
              orElse: () => null,
            );
            if (ep != null) {
              entry = AutoBookEntry(
                id: absId,
                title: ep['title'] as String? ?? 'Episode',
                author: metadata['title'] as String? ?? '', // show name
                duration: (ep['duration'] as num?)?.toDouble() ?? 0,
                coverUrl: AndroidAutoService.localCoverUri(apiItemId),
                chapters: ep['chapters'] as List<dynamic>? ?? [],
                episodeId: episodeId,
                showId: showId,
              );
            }
          } else {
            entry = AutoBookEntry(
              id: absId,
              title: metadata['title'] as String? ?? 'Unknown',
              author: metadata['authorName'] as String? ?? '',
              duration: (media?['duration'] as num?)?.toDouble() ?? 0,
              coverUrl: AndroidAutoService.localCoverUri(absId),
              chapters: media?['chapters'] as List<dynamic>? ?? [],
            );
          }
        }
      } catch (e) {
        debugPrint('[Handler] Error fetching item: $e');
      }
    }

    if (entry == null) {
      debugPrint('[Handler] Item not found: $absId');
      return;
    }

    debugPrint('[Handler] Android Auto play: "${entry.title}" by ${entry.author}');

    // Always generate a fresh HTTP cover URL for Now Playing — api is
    // available here, so use it directly rather than relying on the cached
    // entry.coverUrl (which may be a content:// URI when offline).
    final nowPlayingCoverUrl = api.getCoverUrl(apiItemId, width: 400);

    await _service!.playItem(
      api: api,
      itemId: apiItemId,
      title: entry.title,
      author: entry.author,
      coverUrl: nowPlayingCoverUrl,
      totalDuration: entry.duration,
      chapters: entry.chapters,
      startTime: entry.currentTime ?? 0,
      episodeId: entry.episodeId,
      episodeTitle: entry.episodeId != null ? entry.title : null,
    );
  }
}

// ─── Singleton service ───

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._();

  /// Called when a book completes naturally (before player state is cleared).
  /// Register via [setOnBookFinishedCallback]. Used by LibraryProvider to
  /// update local finished state immediately without waiting for a server refresh.
  static void Function(String itemId)? _onBookFinishedCallback;
  // Buffers the most recent completion key when the callback fires before
  // LibraryProvider is ready to handle it (e.g. Android Auto cold-start).
  // LibraryProvider calls [drainPendingBookFinished] once its absorbing cache
  // is loaded so auto-advance has the state it needs.
  static String? _pendingBookFinishedKey;
  static void setOnBookFinishedCallback(void Function(String itemId)? cb) {
    _onBookFinishedCallback = cb;
  }

  static void drainPendingBookFinished() {
    final cb = _onBookFinishedCallback;
    final pending = _pendingBookFinishedKey;
    if (cb == null || pending == null) return;
    _pendingBookFinishedKey = null;

    // If something is loaded in the player by the time the drain fires, the
    // user already moved on (manually selected a new item in AA, or is paused
    // mid-book). Replaying the completion here would auto-advance on top of
    // their current state — the "phantom resume after pause" regression.
    // Drop the stale completion instead.
    final loaded = _instance._currentItemId;
    if (loaded != null) {
      debugPrint('[Player] Dropping stale book-finished drain (player has item=$loaded, buffered key=$pending)');
      return;
    }

    debugPrint('[Player] Draining buffered book-finished key=$pending');
    cb(pending);
  }

  /// Called when a new item starts playing. Used by LibraryProvider to trigger
  /// rolling downloads for the next items in a series/podcast.
  static void Function(String key)? _onPlayStartedCallback;
  static void setOnPlayStartedCallback(void Function(String key)? cb) {
    _onPlayStartedCallback = cb;
  }

  /// Called when a podcast episode starts playing. Used by AppShell to
  /// auto-navigate to the Absorbing tab.
  static void Function()? _onEpisodePlayStartedCallback;
  static void setOnEpisodePlayStartedCallback(void Function()? cb) {
    _onEpisodePlayStartedCallback = cb;
  }

  /// Called when playback state changes (playing/paused). Used by
  /// LibraryProvider for battery-saving socket lifecycle.
  static void Function(bool isPlaying)? _onPlaybackStateChangedCallback;
  static void setOnPlaybackStateChangedCallback(void Function(bool isPlaying)? cb) {
    _onPlaybackStateChangedCallback = cb;
  }

  /// Invoked when `play()` fires on a cold-started service that has no
  /// current item loaded (typical headphone / lock-screen tap after the OS
  /// killed the app). Registered by main.dart to delegate the restore to
  /// HomeWidgetService (which has the item-fetch + ApiService construction
  /// logic), avoiding a circular import.
  static Future<void> Function()? onColdStartPlayRequested;

  static AudioPlayerHandler? _handler;
  static AudioPlayerHandler? get handler => _handler;
  static Completer<void> _initCompleter = Completer<void>();
  AudioPlayer? get _player => _handler?.player;

  String? _currentItemId;
  String? _currentTitle;
  String? _currentAuthor;
  String? _currentCoverUrl;
  double _totalDuration = 0;
  List<dynamic> _chapters = [];
  ApiService? _api;
  ApiService? get currentApi => _api;
  String? _playbackSessionId;
  /// Phase 1.7: latest streaming URLs (with auth token already in the
  /// query string) and custom HTTP headers needed by reverse proxies like
  /// Cloudflare Access. Stashed to the iOS app group on each player update
  /// so the native widget core can keep playing if Flutter dies.
  List<String> _activeStreamUrls = const [];
  Map<String, String> _activeStreamHeaders = const {};
  List<String> get activeStreamUrls => _activeStreamUrls;
  Map<String, String> get activeStreamHeaders => _activeStreamHeaders;
  bool _isOfflineMode = false;

  /// Externally-pushed signal that the server is currently unreachable.
  /// AuthProvider mirrors `serverReachable` here on each ping result so we
  /// can short-circuit pre-play server calls (e.g. session creation) for
  /// instant offline playback - no need to wait for a network timeout to
  /// discover what the auth layer already knows. Other services
  /// (AndroidAuto/CarPlay browse) read it via [knownOffline] to skip
  /// their own server fetches.
  bool _knownOffline = false;
  bool get knownOffline => _knownOffline;
  void setKnownOffline(bool offline) {
    _knownOffline = offline;
  }

  bool _isBackgrounded = false;
  bool get isBackgrounded => _isBackgrounded;
  SharedPreferences? _prefs;
  StreamSubscription? _syncSub;
  StreamSubscription? _completionSub;
  Timer? _bgSaveTimer;
  Timer? _pauseStopTimer;
  static const _pauseStopTimeout = Duration(minutes: 10);
  /// Last known position in seconds — used to detect end→0 position jumps.
  double _lastKnownPositionSec = 0;
  // ── Stream error retry tracking ──
  int _streamRetryCount = 0;
  static const _maxStreamRetries = 3;
  bool _retryInProgress = false;
  // ── Stuck position detection (xHE-AAC/USAC iOS seek failures) ──
  Timer? _stuckCheckTimer;
  double _stuckCheckLastPosition = -1;
  int _stuckConsecutiveCount = 0; // consecutive checks with no advancement
  int _stuckReseekAttempts = 0; // how many re-seeks we've tried
  static const _maxStuckReseekAttempts = 2;
  // ── Play verification (iOS USAC can silently fail to start after seek) ──
  Timer? _playVerifyTimer;
  // ── Multi-file track offset tracking ──
  // For ConcatenatingAudioSource, _player.position is track-relative.
  // We store cumulative start offsets so we can compute absolute book position.
  List<double> _trackStartOffsets = []; // [0, dur0, dur0+dur1, ...]
  List<double> get trackStartOffsets => _trackStartOffsets;
  int _currentTrackIndex = 0;
  int _lastNotifiedChapterIndex = -1;
  int _lastChapterCheckSec = -1;
  StreamSubscription? _indexSub;

  // ── Notification chapter progress mode ──
  bool _notifChapterMode = false;
  double _currentChapterStart = 0;
  double _currentChapterEnd = 0;
  bool get notifChapterMode => _notifChapterMode && _chapters.isNotEmpty;
  double get currentChapterStart => _currentChapterStart;
  double get currentChapterEnd => _currentChapterEnd;

  void _onSettingsChanged() {
    PlayerSettings.getNotificationChapterProgress().then((v) {
      if (v == _notifChapterMode) return;
      _notifChapterMode = v;
      // Re-push MediaItem + PlaybackState so notification updates immediately
      if (_currentItemId != null) {
        _pushMediaItem(_mediaItemKey, _currentTitle ?? '', _currentAuthor ?? '',
            _currentCoverUrl, _totalDuration,
            chapter: _lastNotifiedChapterIndex >= 0 && _chapters.isNotEmpty
                ? (_chapters[_lastNotifiedChapterIndex] as Map<String, dynamic>)['title'] as String?
                : null);
        _handler?.refreshPlaybackState();
      }
    });
    // Update cached skip amounts so notification icons stay in sync
    PlayerSettings.getForwardSkip().then((v) {
      if (_handler != null && v != _handler!._cachedForwardSkip) {
        _handler!._cachedForwardSkip = v;
        _handler!.refreshPlaybackState();
      }
    });
    PlayerSettings.getBackSkip().then((v) {
      if (_handler != null && v != _handler!._cachedBackSkip) {
        _handler!._cachedBackSkip = v;
        _handler!.refreshPlaybackState();
      }
    });
  }

  /// The last seek target in seconds (absolute book position).
  /// UI can use this to immediately snap to the target before stream catches up.
  double? _lastSeekTargetSeconds;
  DateTime? _lastSeekTime;

  /// If a seek happened recently, returns the seek target.
  /// Otherwise returns null (use the stream position).
  double? get activeSeekTarget {
    if (_lastSeekTargetSeconds == null || _lastSeekTime == null) return null;
    final elapsed = DateTime.now().difference(_lastSeekTime!).inMilliseconds;
    if (elapsed > 8000) {
      _lastSeekTargetSeconds = null;
      _lastSeekTime = null;
      return null;
    }
    return _lastSeekTargetSeconds;
  }

  /// Clear the seek target once the stream has caught up.
  void clearSeekTarget() {
    _lastSeekTargetSeconds = null;
    _lastSeekTime = null;
  }

  final _progressSync = ProgressSyncService();
  final _downloadService = DownloadService();
  final _history = PlaybackHistoryService();

  /// Log a playback event to history.
  void _logEvent(PlaybackEventType type, {String? detail, double? overridePosition}) {
    if (_currentItemId == null) return;
    _history.log(
      itemId: _currentItemId!,
      type: type,
      positionSeconds: overridePosition ?? position.inMilliseconds / 1000.0,
      detail: detail,
    );
  }

  static String _formatPos(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String? get currentItemId => _currentItemId;
  String? get currentTitle => _currentTitle;
  String? get currentAuthor => _currentAuthor;
  String? get currentCoverUrl => _currentCoverUrl;
  double get totalDuration => _totalDuration;
  List<dynamic> get chapters => _chapters;

  void updateChapters(List<dynamic> chapters) {
    _chapters = chapters;
    _handler?.updateChaptersQueue(chapters);
    notifyListeners();
  }
  bool get hasBook => _currentItemId != null;
  bool get isPlaying => _player?.playing ?? false;
  /// True while [playItem] is setting up a new audio source.
  bool _isLoadingNewItem = false;
  bool get isLoadingNewItem => _isLoadingNewItem;
  bool get isLoadingOrBuffering {
    if (_isLoadingNewItem) return true;
    final s = _player?.processingState;
    return s == ProcessingState.loading || s == ProcessingState.buffering;
  }
  bool get isOfflineMode => _isOfflineMode;
  double get volume => _player?.volume ?? 1.0;
  Future<void> setVolume(double v) async => _player?.setVolume(v);

  static const _eqChannelForDiag = MethodChannel('com.absorb.equalizer');

  /// Diagnostic snapshot for the "tap play, no sound" issue. Logs both
  /// just_audio player state AND iOS AVAudioSession route/volume info so
  /// we can tell apart "player thinks it's playing but no audio reaches
  /// speakers" from "player is buffering forever" from "wrong output
  /// route" etc.
  Future<void> _logAudioDiagnostics(String stage) async {
    try {
      final p = _player;
      final pos = p?.position;
      final dur = p?.duration;
      final buffered = p?.bufferedPosition;
      final pieces = <String>[
        'stage=$stage',
        'playing=${p?.playing}',
        'state=${p?.processingState.name}',
        'volume=${p?.volume?.toStringAsFixed(2)}',
        'speed=${p?.speed?.toStringAsFixed(2)}',
        'pos=${pos != null ? "${(pos.inMilliseconds / 1000.0).toStringAsFixed(1)}s" : "null"}',
        'dur=${dur != null ? "${(dur.inMilliseconds / 1000.0).toStringAsFixed(1)}s" : "null"}',
        'buf=${buffered != null ? "${(buffered.inMilliseconds / 1000.0).toStringAsFixed(1)}s" : "null"}',
        'item=$_currentItemId',
        'ep=$_currentEpisodeId',
      ];

      if (Platform.isIOS) {
        try {
          final info = await _eqChannelForDiag
              .invokeMethod<Map<dynamic, dynamic>>('getAudioDiagnostics');
          if (info != null) {
            final outputs = (info['outputs'] as List?)
                    ?.map((o) =>
                        '${(o as Map)["type"]}:${o["name"]}')
                    .join(',') ??
                '?';
            pieces.addAll([
              'ios.cat=${info["category"]}',
              'ios.mode=${info["mode"]}',
              'ios.outVol=${info["outputVolume"]}',
              'ios.otherAudio=${info["isOtherAudioPlaying"]}',
              'ios.silenceHint=${info["secondaryAudioShouldBeSilencedHint"]}',
              'ios.route=[$outputs]',
              'ios.sampleRate=${info["sampleRate"]}',
            ]);
          }
        } catch (e) {
          pieces.add('ios.err=$e');
        }
      }

      debugPrint('[AudioDiag] ${pieces.join(' ')}');
    } catch (e) {
      debugPrint('[AudioDiag] log failed: $e');
    }
  }

  /// Schedule a sequence of diagnostic snapshots after starting playback so
  /// we can see whether state advanced as expected ("playing then
  /// position-stuck-at-0" is a classic no-sound fingerprint).
  void _scheduleAudioDiagnostics(String startStage) {
    _logAudioDiagnostics('$startStage:t0');
    Future.delayed(const Duration(seconds: 1), () => _logAudioDiagnostics('$startStage:t1s'));
    Future.delayed(const Duration(seconds: 3), () => _logAudioDiagnostics('$startStage:t3s'));
    Future.delayed(const Duration(seconds: 10), () => _logAudioDiagnostics('$startStage:t10s'));
  }

  Stream<Duration> get positionStream =>
      _player?.positionStream ?? const Stream.empty();
  Stream<Duration?> get durationStream =>
      _player?.durationStream ?? const Stream.empty();
  Stream<PlayerState> get playerStateStream =>
      _player?.playerStateStream ?? const Stream.empty();

  /// Absolute book position (accounts for multi-file track offsets).
  Duration get position {
    if (_player == null) return Duration.zero;
    // While swapping to a new item, return the target seek position so the UI
    // doesn't flash stale progress from the previous book.
    final seekTarget = _lastSeekTargetSeconds;
    if (_isLoadingNewItem && seekTarget != null && seekTarget > 0) {
      return Duration(milliseconds: (seekTarget * 1000).round());
    }
    final trackRelative = _player!.position;
    if (_trackStartOffsets.length <= 1) return trackRelative; // single file
    final offsetMs = (_trackStartOffsets[_currentTrackIndex] * 1000).round();
    final result = trackRelative + Duration(milliseconds: offsetMs);
    // Don't log every call — this is called very frequently by sync and UI
    return result;
  }

  /// Absolute book position stream (adjusted for multi-file offsets).
  /// IMPORTANT: Always returns a mapped stream that checks offsets at event time.
  /// Do NOT short-circuit to raw positionStream — the caller may subscribe before
  /// track offsets are built, and would miss the offset transform forever.
  Stream<Duration> get absolutePositionStream {
    if (_player == null) return const Stream.empty();
    return _player!.positionStream.map((trackRelative) {
      if (_trackStartOffsets.length <= 1) return trackRelative; // single file, no offset
      final trackIdx = _currentTrackIndex;
      final offsetMs = (_trackStartOffsets[trackIdx] * 1000).round();
      final absolute = trackRelative + Duration(milliseconds: offsetMs);
      return absolute;
    });
  }

  Duration get duration => _player?.duration ?? Duration.zero;
  double get speed => _player?.speed ?? 1.0;

  /// Build track start offsets from audioTracks list.
  void _buildTrackOffsets(List<dynamic> audioTracks) {
    _trackStartOffsets = [0.0];
    double acc = 0;
    for (final t in audioTracks) {
      final track = t as Map<String, dynamic>;
      final dur = (track['duration'] as num?)?.toDouble() ?? 0;
      acc += dur;
      _trackStartOffsets.add(acc);
    }
    debugPrint('[Player] Track offsets: $_trackStartOffsets');
  }

  /// Phase 1.7: snapshot the URLs and HTTP headers used to build the
  /// streaming AudioSource so the iOS native widget core can hit the same
  /// endpoints if Flutter dies. Token is already in the URL; custom headers
  /// (Cloudflare Access etc.) ride along for reverse-proxy auth.
  void _captureStreamUrls(List<dynamic> audioTracks, ApiService api) {
    final urls = <String>[];
    for (final t in audioTracks) {
      final track = t as Map<String, dynamic>;
      final contentUrl = track['contentUrl'] as String? ?? '';
      if (contentUrl.isEmpty) continue;
      urls.add(api.buildTrackUrl(contentUrl));
    }
    _activeStreamUrls = urls;
    _activeStreamHeaders = Map<String, String>.from(api.mediaHeaders);
  }

  /// Subscribe to track index changes for multi-file playback.
  void _subscribeTrackIndex() {
    _indexSub?.cancel();
    if (_player == null || _trackStartOffsets.length <= 1) return;
    _indexSub = _player!.currentIndexStream.listen((index) {
      if (index != null) {
        _currentTrackIndex = index.clamp(0, _trackStartOffsets.length - 2);
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('[Player] Index stream error: $e');
    });
  }

  /// Seek to an absolute book position, handling multi-file offset conversion.
  Future<void> _seekAbsolute(double absoluteSeconds) async {
    if (_player == null) return;

    // Record seek target so UI can snap immediately
    _lastSeekTargetSeconds = absoluteSeconds;
    _lastSeekTime = DateTime.now();

    if (_trackStartOffsets.length <= 1) {
      // Single file — seek directly
      await _player!.seek(Duration(milliseconds: (absoluteSeconds * 1000).round()));
      notifyListeners();
      return;
    }
    // Multi-file — find the right track and local offset
    for (int i = 0; i < _trackStartOffsets.length - 1; i++) {
      final trackStart = _trackStartOffsets[i];
      final trackEnd = _trackStartOffsets[i + 1];
      if (absoluteSeconds < trackEnd || i == _trackStartOffsets.length - 2) {
        final localOffset = absoluteSeconds - trackStart;
        // Update index BEFORE seeking so positionStream events use the right offset
        _currentTrackIndex = i;
        await _player!.seek(Duration(milliseconds: (localOffset * 1000).round()), index: i);
        notifyListeners();
        return;
      }
    }
  }

  /// MUST be called after Activity is ready.
  static Future<void> init() async {
    if (_handler != null) return; // Already initialized
    // Reset for hot restart — previous completer may already be completed
    // while _handler was reset to null by the Dart VM restart.
    if (_initCompleter.isCompleted) {
      _initCompleter = Completer<void>();
    }
    try {
      final fwdSkip = await PlayerSettings.getForwardSkip();
      final backSkip = await PlayerSettings.getBackSkip();
      _handler = await AudioService.init<AudioPlayerHandler>(
        builder: () => AudioPlayerHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.audiobookshelf.app.channel.audio',
          androidNotificationChannelName: 'Absorb',
          // Keep foreground service alive when paused — prevents Android from
          // killing audio after notification interruptions on locked screen.
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'drawable/ic_notification',
          fastForwardInterval: Duration(seconds: fwdSkip),
          rewindInterval: Duration(seconds: backSkip),
          androidBrowsableRootExtras: {
            AndroidContentStyle.supportedKey: true,
            AndroidContentStyle.browsableHintKey:
                AndroidContentStyle.categoryListItemHintValue,
            AndroidContentStyle.playableHintKey:
                AndroidContentStyle.gridItemHintValue,
            'android.media.browse.SEARCH_SUPPORTED': true,
          },
        ),
      );
      // Bind service so handler routes play/pause through service (for auto-rewind)
      _handler!.bindService(_instance);
      // Wire the EQ service's skip-silence toggle through to just_audio.
      // Android-only: just_audio's setSkipSilenceEnabled is a no-op on iOS.
      if (Platform.isAndroid) {
        EqualizerService().setSkipSilenceApplier((enabled) {
          try {
            _handler?.player.setSkipSilenceEnabled(enabled);
          } catch (e) {
            debugPrint('[Player] setSkipSilenceEnabled failed: $e');
          }
        });
      }
      // Initialize cached skip amounts so notification icons show the correct values
      _handler!._cachedForwardSkip = fwdSkip;
      _handler!._cachedBackSkip = backSkip;
      debugPrint('[Player] AudioService initialized');
      // Configure streaming cache if enabled
      final cacheSizeMb = await PlayerSettings.getStreamingCacheSizeMb();
      debugPrint('[Player] Streaming cache setting: $cacheSizeMb MB');
      if (cacheSizeMb > 0) {
        try {
          await AudioPlayer.configureStreamingCache(cacheSizeMb);
          debugPrint('[Player] Streaming cache configured: $cacheSizeMb MB');
        } catch (e) {
          debugPrint('[Player] Streaming cache init failed: $e');
        }
      }
      // Load notification chapter progress setting and watch for changes
      _instance._notifChapterMode = await PlayerSettings.getNotificationChapterProgress();
      PlayerSettings.settingsChanged.addListener(_instance._onSettingsChanged);
      // Configure audio session for audiobook playback
      await _configureAudioSession();
    } catch (e, st) {
      debugPrint('[Player] AudioService.init failed: $e\n$st');
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }
  }

  static StreamSubscription? _interruptSub;
  static StreamSubscription? _noisySub;
  // Set true when BT/headphones disconnect so the interruption handler
  // won't auto-resume playback onto the phone speaker.
  static bool _noisyPause = false;
  // Whether BT audio was connected when the current interruption began.
  static bool _wasOnBluetooth = false;
  // Last time the app entered the foreground. Used by [ClickDebug] to see
  // whether a MediaSession click's 400ms debounce window overlapped with
  // an app-foreground event — the fingerprint of an Android Auto disconnect
  // handing control back to the phone.
  static DateTime? _lastForegroundAt;
  // Last time we observed BT/AA to be the audio route while playing/pausing.
  // Stamped from interruption begin/end and from service.pause(). Used at
  // click arrival to detect the AA-disconnect phantom: BT was the route
  // recently, isn't now, click came in while bg + not playing. Some devices
  // (Pixel 10 Pro on Android 16 with Android Auto observed) never fire
  // becomingNoisy on AA disconnect, so the 5s _noisyPauseAt guard alone
  // can't catch the delayed phantom MediaButton.media event.
  static DateTime? _lastPlayedOnBtAt;
  static const _eqChannel = MethodChannel('com.absorb.equalizer');

  /// Check if BT audio (A2DP/SCO) is currently connected via native AudioManager.
  static Future<bool> _isBluetoothAudioConnected() async {
    try {
      final result = await _eqChannel.invokeMethod<bool>('isBluetoothAudioConnected');
      return result ?? false;
    } catch (e) {
      debugPrint('[AudioSession] BT check failed: $e');
      return false;
    }
  }

  /// True when BT/headphones just disconnected — callers can check before
  /// starting new playback to avoid blasting audio on the phone speaker.
  static bool get wasNoisyPause => _noisyPause;

  static Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;

    await session.configure(AudioSessionConfiguration(
      // iOS: playback category — no duckOthers so iOS properly recognises this
      // app as the Now Playing app and shows lock screen / Control Center controls.
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionCategoryOptions: Platform.isIOS
          ? AVAudioSessionCategoryOptions.none
          : AVAudioSessionCategoryOptions.duckOthers,
      // Android: speech content type enables OS voice-intelligibility
      // processing so audiobooks play at normal listening levels. Matches the
      // reference ABS Android client.
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    // Don't activate the session here — defer to first playback.
    // Activating during init creates a stale MediaSession that Android
    // can garbage-collect after hours in background, leaving bluetooth /
    // notification / widget controls permanently broken.
    // play() and startLocalPlayback() call setActive(true) before playing.

    _interruptSub?.cancel();
    _interruptSub = session.interruptionEventStream.listen((event) async {
      try {
        final service = _instance;

        if (event.begin) {
          if (service.isPlaying) {
            debugPrint('[AudioSession] Interrupted (${event.type}) — pausing');
            _wasOnBluetooth = await _isBluetoothAudioConnected();
            if (_wasOnBluetooth) _lastPlayedOnBtAt = DateTime.now();
            debugPrint('[AudioSession] Was on BT: $_wasOnBluetooth');
            // Pause the underlying player directly — NOT service.pause() —
            // to keep the interruption lightweight. service.pause() saves progress,
            // syncs to server, clears _wasPlayingBeforeInterrupt, and sets
            // _lastPauseTime (triggering auto-rewind on resume). For transient
            // notification interruptions we just need to duck the audio briefly.
            await service._player?.pause();
            service._wasPlayingBeforeInterrupt = true;
          }
        } else {
          // Don't auto-resume if the pause was caused by BT/headphone disconnect.
          // Some devices fire interruption-end AFTER becoming-noisy, which would
          // resume playback on the phone speaker.
          if (_noisyPause) {
            debugPrint('[AudioSession] Interruption ended after noisy — skipping resume');
            service._wasPlayingBeforeInterrupt = false;
            return;
          }
          if (service._wasPlayingBeforeInterrupt) {
            service._wasPlayingBeforeInterrupt = false;
            await Future.delayed(const Duration(milliseconds: 600));
            // Re-check: another event (like becoming-noisy) might have fired
            // during the delay.
            if (_noisyPause) return;
            // If we were on BT when interrupted, check if BT is still connected.
            // Some car head units never send AUDIO_BECOMING_NOISY on disconnect,
            // so _noisyPause alone is not enough.
            if (_wasOnBluetooth) {
              final stillOnBt = await _isBluetoothAudioConnected();
              debugPrint('[AudioSession] Interruption ended — was BT, still BT: $stillOnBt');
              if (!stillOnBt) {
                debugPrint('[AudioSession] BT disconnected during interruption — skipping resume');
                _noisyPause = true;
                return;
              }
              _lastPlayedOnBtAt = DateTime.now();
            }
            debugPrint('[AudioSession] Interruption ended — resuming');
            await service.play(logDetail: 'Auto-resumed after interruption');
          }
        }
      } catch (e) {
        debugPrint('[AudioSession] Interruption handler error: $e');
      }
    }, onError: (e) {
      debugPrint('[AudioSession] Interruption stream error - re-subscribing: $e');
      _configureAudioSession();
    });

    // Headphones unplugged / BT disconnected — pause, no auto-resume
    _noisySub?.cancel();
    _noisySub = session.becomingNoisyEventStream.listen((_) async {
      try {
        final service = _instance;
        debugPrint('[AudioSession] Becoming noisy — pausing');
        debugPrint('[ClickDebug] becoming-noisy fired: bg=${service._isBackgrounded}, playing=${service.isPlaying}');
        _noisyPause = true;
        service._wasPlayingBeforeInterrupt = false;
        // Cancel any pending media-button click from the BT disconnect so the
        // delayed click handler doesn't resume playback on the phone speaker.
        _handler?.cancelPendingClick();
        if (service.isPlaying) {
          await service.pause();
        }
      } catch (e) {
        debugPrint('[AudioSession] Noisy handler error: $e');
      }
    }, onError: (e) {
      debugPrint('[AudioSession] Noisy stream error - re-subscribing: $e');
      _configureAudioSession();
    });
  }

  /// Refresh the media session when the app returns to foreground.
  /// After a long background idle, Android can garbage-collect the stale
  /// MediaSession, leaving bluetooth / notification / widget controls dead.
  /// Re-activating the audio session and re-pushing handler state recovers it.
  static void onAppBackgrounded() {
    _instance._isBackgrounded = true;
    debugPrint('[ClickDebug] App backgrounded');
  }

  static Future<void> onAppForegrounded() async {
    final service = _instance;
    service._isBackgrounded = false;
    _lastForegroundAt = DateTime.now();
    // Relative timing on foreground arrival is the second half of the
    // AA-disconnect fingerprint (variant 3): raw pause, then foreground
    // within ~2s. Log sincePrevPauseMs / sincePrevPlayMs so the disconnect
    // pattern is obvious on one line.
    final handler = _handler;
    int sincePrevPauseMs = -1;
    int sincePrevPlayMs = -1;
    if (handler != null) {
      if (handler._lastHandlerPauseAt != null) {
        sincePrevPauseMs = _lastForegroundAt!.difference(handler._lastHandlerPauseAt!).inMilliseconds;
      }
      if (handler._lastHandlerPlayAt != null) {
        sincePrevPlayMs = _lastForegroundAt!.difference(handler._lastHandlerPlayAt!).inMilliseconds;
      }
    }
    final aaDisconnectSuspect = sincePrevPauseMs >= 0 && sincePrevPauseMs < 3000;
    debugPrint('[ClickDebug] App foregrounded: sincePrevPauseMs=$sincePrevPauseMs, '
        'sincePrevPlayMs=$sincePrevPlayMs, aaDisconnectSuspect=$aaDisconnectSuspect');
    service._positionSyncFailures = 0; // retry on foreground
    if (!service.hasBook) return;
    final sessionAlive = service._playbackSessionId != null;
    debugPrint('[MediaSession] Foregrounded - refreshing (playing=${service.isPlaying}, session=$sessionAlive, item=${service._currentItemId})');
    // Alpha: when session=false, the playback session was closed (pause
    // timeout) and likely handler.stop() ran too. Log handler state so we
    // can see whether the MediaSession is recoverable. Strip before beta.
    if (!sessionAlive && handler != null) {
      try {
        final ps = handler.playbackState.value;
        debugPrint('[MediaSession] Recovery diagnostic: handlerPlaying=${ps.playing}, '
            'processingState=${ps.processingState.name}, '
            'playerPlaying=${handler.player.playing}, '
            'playerProcessing=${handler.player.processingState.name}');
      } catch (e) {
        debugPrint('[MediaSession] Recovery diagnostic error: $e');
      }
    }
    // Flush missed UI updates from background
    service.notifyListeners();
    // Flush overdue server sync
    if (service.isPlaying && service._currentItemId != null) {
      final sinceSync = DateTime.now().difference(service._lastServerSync).inSeconds;
      if (sinceSync > 60) {
        service._syncToServer(service.position);
      }
    }
    // Re-activate audio session to get a fresh system token
    try { (await AudioSession.instance).setActive(true); } catch (_) {}
    // Re-push playback state so the system re-registers the MediaSession
    _handler?.refreshPlaybackState();
    // Re-push media item so notification metadata is fresh
    if (service._currentItemId != null && service._currentTitle != null) {
      final chapterTitle = service._lastNotifiedChapterIndex >= 0 && service._chapters.isNotEmpty
          ? (service._chapters[service._lastNotifiedChapterIndex] as Map<String, dynamic>)['title'] as String?
          : null;
      service._pushMediaItem(
        service._mediaItemKey,
        service._currentTitle!,
        service._currentAuthor ?? '',
        service._currentCoverUrl,
        service._totalDuration,
        chapter: chapterTitle,
      );
      debugPrint('[MediaSession] Re-pushed media item and playback state');
    }
  }

  String? _currentEpisodeId;
  String? get currentEpisodeId => _currentEpisodeId;

  /// MediaSession / AA item id. Podcast episodes use the compound
  /// `parentId-episodeId` key so AA doesn't treat them as a separate item
  /// from the initial load. Books use the plain itemId.
  String get _mediaItemKey => _currentEpisodeId != null
      ? '${_currentItemId!}-$_currentEpisodeId'
      : _currentItemId!;

  String? _currentEpisodeTitle;
  String? get currentEpisodeTitle => _currentEpisodeTitle;

  Future<String?> playItem({
    required ApiService api,
    required String itemId,
    required String title,
    required String author,
    required String? coverUrl,
    required double totalDuration,
    required List<dynamic> chapters,
    double startTime = 0,
    bool forceStartTime = false,
    String? episodeId,
    String? episodeTitle,
  }) async {
    if (_handler == null) {
      debugPrint('[Player] Handler not yet initialized, waiting…');
      await _initCompleter.future;
    }
    if (_handler == null) {
      debugPrint('[Player] Handler init failed, cannot play');
      return 'Player failed to initialize';
    }

    // Don't start local playback while casting
    final cast = ChromecastService();
    if (cast.isCasting) {
      debugPrint('[Player] Cast active - skipping local playback');
      return null;
    }

    // Stop old audio immediately so it doesn't keep playing while the new
    // source is loading (avoids briefly hearing the previous book).
    await _player?.pause();

    _isLoadingNewItem = true;
    _api = api;
    _currentItemId = itemId;
    _currentEpisodeId = episodeId;
    _currentEpisodeTitle = episodeTitle;
    _currentTitle = title;
    _currentAuthor = author;
    _currentCoverUrl = coverUrl;
    _totalDuration = totalDuration;
    _chapters = chapters;
    _handler?.updateChaptersQueue(chapters);
    // New book = fresh session — clear any auto sleep dismissal
    SleepTimerService().resetDismiss();

    // Progress key: compound for episodes, plain for books
    final progressKey = episodeId != null ? '$itemId-$episodeId' : itemId;

    // Notify rolling download listener that a new item is playing
    _onPlayStartedCallback?.call(progressKey);

    // Check for local saved position (skip if startTime was forced).
    // Always prefer the local position when it's further ahead - the
    // caller's startTime may be stale (e.g. Android Auto browse tree
    // entry cached before the user listened further).
    final localPos = await _progressSync.getSavedPosition(progressKey);
    if (localPos > 0 && !forceStartTime) {
      if (startTime == 0 || localPos > startTime + 1.0) {
        debugPrint('[Player] Resuming from local position: ${localPos}s (caller startTime was ${startTime}s)');
        startTime = localPos;
      }
    }

    // Phase 1.6: if the iOS native player core was driving while Flutter was
    // dead, it stamped a fresher `np_position_s` to the app group. Pick that
    // up so opening absorb after a widget-tap session shows the right spot.
    if (Platform.isIOS && !forceStartTime) {
      final nativePos = await HomeWidgetService()
          .getNativeNowPlayingPosition(itemId, episodeId);
      if (nativePos != null && nativePos > startTime + 1.0) {
        debugPrint('[Player] Resuming from native widget position: ${nativePos}s (was ${startTime}s)');
        startTime = nativePos;
      }
    }

    // Set seek target early so the UI doesn't flash chapter 1 while loading
    if (startTime > 0) {
      _lastSeekTargetSeconds = startTime;
      _lastSeekTime = DateTime.now();
    }
    notifyListeners();

    // Cancel old sync/completion listeners before switching sources.
    // Without this, stale position or processingState events from the
    // previous book can fire during setAudioSource() and trigger
    // _onPlaybackComplete(), killing the new playback before it starts.
    _syncSub?.cancel();
    _syncSub = null;
    _completionSub?.cancel();
    _completionSub = null;
    _indexSub?.cancel();
    _indexSub = null;
    _lastKnownPositionSec = 0;
    _isCompletingBook = false;

    // Check if downloaded — play locally
    String? result;
    if (_downloadService.isDownloaded(progressKey)) {
      result = await _playFromLocal(progressKey, title, author, coverUrl,
          totalDuration, chapters, startTime, forceStartTime);
    } else {
      // Check manual offline — don't stream from server
      final prefs = await SharedPreferences.getInstance();
      final manualOffline = prefs.getBool('manual_offline_mode') ?? false;
      if (manualOffline) {
        debugPrint('[Player] Manual offline — cannot stream non-downloaded item');
        _clearState();
        return 'This item isn\'t downloaded and offline mode is on';
      }
      // Try to play from cached session metadata first (instant start)
      final cachedSession = await SessionCache.load(
        itemId: itemId,
        episodeId: episodeId,
      );
      if (cachedSession != null) {
        result = await _playFromSessionCache(api, itemId, title, author,
            coverUrl, totalDuration, chapters, startTime, cachedSession,
            forceStartTime);
        // Fall through to normal server path if cache was stale/invalid
        if (result == 'cache-miss') {
          result = await _playFromServer(api, itemId, title, author, coverUrl,
              totalDuration, chapters, startTime, forceStartTime);
        }
      } else {
        // No cache - stream from server
        result = await _playFromServer(api, itemId, title, author, coverUrl,
            totalDuration, chapters, startTime, forceStartTime);
      }
    }

    _isLoadingNewItem = false;
    notifyListeners();

    // Session-start rewind: rewind by maxRewind when starting a new session
    if (result == null && !forceStartTime) {
      final rewindSettings = await AutoRewindSettings.load();
      if (rewindSettings.enabled && rewindSettings.sessionStartRewind) {
        final rewindSeconds = rewindSettings.maxRewind;
        if (rewindSeconds > 0.5 && _player != null) {
          final currentAbsolutePos = position.inMilliseconds / 1000.0;
          // Scale by speed so the listener gets the same perceived amount of
          // re-orientation time regardless of playback speed - at 1.5x a 2s
          // setting covers 3s of book content (= 2s of real listening time).
          final currentSpeed = _player!.speed;
          var newPosSeconds = currentAbsolutePos - (rewindSeconds * currentSpeed);
          if (newPosSeconds < 0) newPosSeconds = 0;
          if (rewindSettings.chapterBarrier && _chapters.isNotEmpty) {
            for (final ch in _chapters) {
              final start = (ch['start'] as num?)?.toDouble() ?? 0;
              final end = (ch['end'] as num?)?.toDouble() ?? 0;
              if (currentAbsolutePos >= start && currentAbsolutePos < end) {
                if (newPosSeconds < start) newPosSeconds = start;
                break;
              }
            }
          }
          await _seekAbsolute(newPosSeconds);
          // Use actual book-time delta so chapter barrier caps are reflected.
          final actualDelta = currentAbsolutePos - newPosSeconds;
          _lastAutoRewindAmount = actualDelta;
          final detail = currentSpeed == 1.0
              ? '${rewindSeconds.toStringAsFixed(1)}s (session start)'
              : '${rewindSeconds.toStringAsFixed(1)}s (${actualDelta.toStringAsFixed(1)}s at ${currentSpeed.toStringAsFixed(2)}x, session start)';
          _logEvent(PlaybackEventType.autoRewind, detail: detail);
          debugPrint(
              '[Player] Session-start rewind ${rewindSeconds.toStringAsFixed(1)}s '
              '(${actualDelta.toStringAsFixed(1)}s at ${currentSpeed.toStringAsFixed(2)}x)');
        }
      }
    }

    // Auto-navigate to Absorbing tab when an episode starts playing
    if (result == null && episodeId != null) {
      _onEpisodePlayStartedCallback?.call();
    }
    return result;
  }

  /// Hot-swap from streaming to local files without interrupting playback position.
  /// Called when a download completes for the currently-playing item.
  Future<bool> switchToLocal(String itemId) async {
    if (_currentItemId != itemId) return false;
    if (!_downloadService.isDownloaded(itemId)) return false;
    if (_player == null) return false;

    final wasPlaying = _player!.playing;
    final currentAbsolutePos = position; // use absolute position getter
    final currentSpeed = _player!.speed;

    debugPrint('[Player] Hot-swapping to local files at ${currentAbsolutePos.inSeconds}s');

    final localPaths = _downloadService.getLocalPaths(itemId);
    if (localPaths == null || localPaths.isEmpty) return false;

    // Get cached session data for track durations (multi-file seeking)
    final cachedJson = _downloadService.getCachedSessionData(itemId);
    List<dynamic>? audioTracks;
    if (cachedJson != null) {
      try {
        final session = jsonDecode(cachedJson) as Map<String, dynamic>;
        audioTracks = session['audioTracks'] as List<dynamic>?;
      } catch (_) {}
    }

    // Rebuild track offsets for local files
    if (audioTracks != null) {
      _buildTrackOffsets(audioTracks);
    } else {
      _trackStartOffsets = [0.0];
    }
    _currentTrackIndex = 0;

    try {
      AudioSource source;
      if (localPaths.length == 1) {
        source = AudioSource.file(localPaths.first);
      } else {
        final sources = localPaths.map((p) => AudioSource.file(p) as AudioSource).toList();
        source = ConcatenatingAudioSource(children: sources);
      }

      await _player!.setAudioSource(source);

      // Seek to the same absolute position
      final posSeconds = currentAbsolutePos.inMilliseconds / 1000.0;
      await _seekAbsolute(posSeconds);

      _subscribeTrackIndex();

      // Restore speed
      await _player!.setSpeed(currentSpeed);

      // Resume if was playing
      if (wasPlaying) _player!.play();

      _logEvent(PlaybackEventType.play, detail: 'Switched to local playback');
      debugPrint('[Player] Hot-swap complete — now playing from local files');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Player] Hot-swap failed: $e');
      return false;
    }
  }

  Future<String?> _playFromLocal(
    String itemId,
    String title,
    String author,
    String? coverUrl,
    double totalDuration,
    List<dynamic> chapters,
    double startTime, [
    bool forceStartTime = false,
  ]) async {
    debugPrint('[Player] Playing from local files: $title');
    // Alpha [PodDur]: trace podcast-episode duration loading. Symptom:
    // Android Auto progress bar missing for ~60s on cold-start podcast play
    // because the first MediaItem push carries dur=0. We want to know what
    // value arrived at this function, and what's available from nearby state.
    debugPrint('[PodDur] _playFromLocal entry: itemId=$itemId ep=$_currentEpisodeId totalDurationArg=${totalDuration.toStringAsFixed(1)}s _totalDuration=${_totalDuration.toStringAsFixed(1)}s chapters=${chapters.length}');
    _isOfflineMode = false; // We still sync to server if possible
    _playbackSessionId = null;

    // Check if manual offline mode is on
    final prefs = await SharedPreferences.getInstance();
    final manualOffline = prefs.getBool('manual_offline_mode') ?? false;
    debugPrint('[Player] manualOffline=$manualOffline, api=${_api != null}');

    // Try to start a server session for sync. Skip entirely if the user
    // is in manual offline mode OR if AuthProvider has told us the server
    // is unreachable (skip = instant local playback). Otherwise the call
    // is capped at 5s so a silently-dropping reverse proxy doesn't hold
    // up local playback for the full 20s api-level timeout.
    if (_api != null && !manualOffline && !_knownOffline) {
      try {
        debugPrint('[Player] Starting server session for local playback...');
        final sessionData = await (_currentEpisodeId != null
            ? _api!.startEpisodePlaybackSession(_currentItemId!, _currentEpisodeId!)
            : _api!.startPlaybackSession(itemId)
        ).timeout(const Duration(seconds: 5), onTimeout: () => null);
        if (sessionData != null) {
          _playbackSessionId = sessionData['id'] as String?;
          debugPrint('[Player] Got server session for local playback: $_playbackSessionId');
          _logEvent(PlaybackEventType.sessionStart, detail: 'local');

          // Alpha [PodDur]: which duration fields did the session response carry?
          // If the server ships a usable duration here and we ignore it, we
          // know the fix is to pick it up. Dump all plausible keys.
          final sdDuration = (sessionData['duration'] as num?)?.toDouble();
          final sdMediaDuration = (sessionData['mediaDuration'] as num?)?.toDouble();
          final sdMetaDur = (sessionData['mediaMetadata'] is Map<String, dynamic>)
              ? ((sessionData['mediaMetadata'] as Map<String, dynamic>)['duration'] as num?)?.toDouble()
              : null;
          debugPrint('[PodDur] session response: duration=$sdDuration mediaDuration=$sdMediaDuration mediaMetadata.duration=$sdMetaDur keys=${sessionData.keys.toList()}');

          // Fall back to session duration when the caller didn't have one.
          // Without this, podcast cold-starts from Android Auto push a first
          // MediaItem with dur=0, and AA never renders the progress bar.
          if (totalDuration <= 0 && sdDuration != null && sdDuration > 0) {
            totalDuration = sdDuration;
            _totalDuration = sdDuration;
          }

          // Pick up chapters from session (e.g. podcast episodes with embedded chapters)
          if (chapters.isEmpty) {
            final sessionChapters = sessionData['chapters'] as List<dynamic>? ?? [];
            if (sessionChapters.isNotEmpty) {
              chapters = sessionChapters;
              _chapters = sessionChapters;
              _handler?.updateChaptersQueue(sessionChapters);
              debugPrint('[Player] Loaded ${sessionChapters.length} chapters from session');
            }
          }

          // Compare server position vs local.
          // Usually the furthest position wins, but if local is ahead we also
          // check timestamps: a stale local save (e.g. from a crashed write)
          // shouldn't override a more recently synced server position.
          final serverPos = (sessionData['currentTime'] as num?)?.toDouble() ?? 0;
          final pKey = _currentEpisodeId != null ? '$itemId-$_currentEpisodeId' : itemId;
          final localTs = await _progressSync.getSavedTimestamp(pKey);
          if (serverPos > startTime + 1.0) {
            debugPrint('[Player] Server position is ahead: server=${serverPos}s vs local=${startTime}s — using server');
            startTime = serverPos;
            await _progressSync.saveLocal(
              itemId: itemId,
              currentTime: serverPos,
              duration: totalDuration,
              speed: 1.0,
            );
          } else if (startTime > 0) {
            // Local is ahead — verify via timestamp that this isn't stale data.
            // Fetch the server's lastUpdate to compare with the local save time.
            bool useServer = false;
            if (localTs > 0) {
              try {
                final serverProgress = await _api!.getItemProgress(pKey);
                final serverLastUpdate = (serverProgress?['lastUpdate'] as num?)?.toInt() ?? 0;
                if (serverLastUpdate > localTs) {
                  debugPrint('[Player] Local position is ahead but stale: local=${startTime}s (ts=$localTs) vs server=${serverPos}s (ts=$serverLastUpdate) — using server');
                  startTime = serverPos;
                  useServer = true;
                }
              } catch (_) {}
            }
            if (!useServer) {
              debugPrint('[Player] Local position is ahead: local=${startTime}s vs server=${serverPos}s — keeping local');
            }
          } else if (serverPos > 0) {
            debugPrint('[Player] No local position, using server: ${serverPos}s');
            startTime = serverPos;
          }
        } else {
          debugPrint('[Player] startPlaybackSession returned null');
        }
      } catch (e) {
        debugPrint('[Player] Could not start server session: $e');
      }
    } else {
      debugPrint('[Player] Skipping server session — manual offline or no API');
    }

    // If no session, fall back to offline mode
    if (_playbackSessionId == null) {
      _isOfflineMode = true;
      debugPrint('[Player] No server session — true offline mode');
    }

    final localPaths = _downloadService.getLocalPaths(itemId);
    if (localPaths == null || localPaths.isEmpty) {
      debugPrint('[Player] No local files found');
      _clearState();
      return 'Downloaded files not found - try re-downloading';
    }

    // Get cached session data for track durations (and chapters if needed)
    final cachedJson = _downloadService.getCachedSessionData(itemId);
    List<dynamic>? audioTracks;
    if (cachedJson != null) {
      try {
        final session = jsonDecode(cachedJson) as Map<String, dynamic>;
        audioTracks = session['audioTracks'] as List<dynamic>?;
        // Pick up chapters from cached session when not already loaded
        if (chapters.isEmpty) {
          final cachedChapters = session['chapters'] as List<dynamic>? ?? [];
          if (cachedChapters.isNotEmpty) {
            chapters = cachedChapters;
            _chapters = cachedChapters;
            _handler?.updateChaptersQueue(cachedChapters);
            debugPrint('[Player] Loaded ${cachedChapters.length} chapters from cached session');
          }
        }
      } catch (_) {}
    }

    try {
      _currentTrackIndex = 0;

      // Build multi-file track offsets for absolute position tracking
      if (audioTracks != null) {
        _buildTrackOffsets(audioTracks);
      } else {
        _trackStartOffsets = [0.0]; // single file fallback
      }

      AudioSource source;
      if (localPaths.length == 1) {
        source = AudioSource.file(localPaths.first);
      } else {
        final sources = localPaths
            .map((p) => AudioSource.file(p) as AudioSource)
            .toList();
        source = ConcatenatingAudioSource(children: sources);
      }

      await _player!.setAudioSource(source);

      // If the saved position is at (or past) the end, restart from the beginning
      if (totalDuration > 0 && startTime >= totalDuration - 1.0) startTime = 0;
      if (startTime > 0) {
        await _seekAbsolute(startTime);
      }
      clearSeekTarget(); // Seek done; let position events flow immediately

      _subscribeTrackIndex();
      final initChapter = _initChapterInfo(startTime);
      _pushMediaItem(itemId, title, author, coverUrl, totalDuration, chapter: initChapter);
      // Use _currentItemId for speed lookup — itemId here is the progressKey
      // (compound "$showId-$episodeId" for podcasts) but speed is saved under
      // the raw show/book ID via _currentItemId in setSpeed().
      final speedKey = _currentItemId ?? itemId;
      final bookSpeed = await PlayerSettings.getBookSpeed(speedKey);
      final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
      await _player!.setSpeed(speed);
      await EqualizerService().switchItem(speedKey);
      debugPrint('[Player] Starting local playback at ${speed}x');
      // Re-activate audio session before play so the first playback event
      // reaches the audio_service iOS plugin with an active session.
      // Without this, iOS ignores the MPNowPlayingInfoCenter update and
      // lock screen / Control Center / AirPod controls never appear.
      try { (await AudioSession.instance).setActive(true); } catch (_) {}
      _player!.play();
      _scheduleAudioDiagnostics('local');
      notifyListeners();
      _setupSync();
      // Ensure iOS lock screen / Control Center controls appear by pushing
      // a fresh playback state after a short delay. The initial event from
      // playbackEventStream can arrive before AVPlayer is fully "playing",
      // causing the audio_service iOS plugin to skip command center activation.
      Future.delayed(const Duration(milliseconds: 500), () {
        _handler?.refreshPlaybackState();
      });
      // Fresh session — reset auto sleep dismiss and check
      final sleepTimer = SleepTimerService();
      sleepTimer.resetDismiss();
      sleepTimer.checkAutoSleep();

      return null;
    } catch (e, stack) {
      debugPrint('[Player] Local play error: $e\n$stack');
      _clearState();
      return 'Playback failed: ${e.toString().split('\n').first}';
    }
  }

  /// Play from cached session metadata. Starts playback instantly without
  /// waiting for a server round-trip. Fires _refreshServerSession() in the
  /// background to get a fresh session ID and cross-client progress check.
  Future<String?> _playFromSessionCache(
    ApiService api,
    String itemId,
    String title,
    String author,
    String? coverUrl,
    double totalDuration,
    List<dynamic> chapters,
    double startTime,
    Map<String, dynamic> cached, [
    bool forceStartTime = false,
  ]) async {
    debugPrint('[Player] Playing from session cache: $title');
    _isOfflineMode = false;
    _playbackSessionId = null; // No server session yet; _refreshServerSession will set it

    final audioTracks = cached['audioTracks'] as List<dynamic>?;
    if (audioTracks == null || audioTracks.isEmpty) {
      debugPrint('[Player] Cached session has no audio tracks - falling back');
      return 'cache-miss';
    }

    // Pick up cached chapters if the caller didn't provide any
    if (chapters.isEmpty) {
      final cachedChapters = cached['chapters'] as List<dynamic>? ?? [];
      if (cachedChapters.isNotEmpty) {
        chapters = cachedChapters;
        _chapters = cachedChapters;
        _handler?.updateChaptersQueue(cachedChapters);
      }
    }

    // Use cached duration if caller didn't have one
    if (totalDuration <= 0) {
      final cachedDur = (cached['totalDuration'] as num?)?.toDouble() ?? 0;
      if (cachedDur > 0) {
        totalDuration = cachedDur;
        _totalDuration = cachedDur;
      }
    }

    try {
      _currentTrackIndex = 0;
      final audioHeaders = api.mediaHeaders;
      _buildTrackOffsets(audioTracks);
      _captureStreamUrls(audioTracks, api);
      AudioSource source;
      if (audioTracks.length == 1) {
        final track = audioTracks.first as Map<String, dynamic>;
        final contentUrl = track['contentUrl'] as String? ?? '';
        final fullUrl = api.buildTrackUrl(contentUrl);
        source = AudioSource.uri(Uri.parse(fullUrl), headers: audioHeaders);
      } else {
        final sources = <AudioSource>[];
        for (final t in audioTracks) {
          final track = t as Map<String, dynamic>;
          final contentUrl = track['contentUrl'] as String? ?? '';
          final fullUrl = api.buildTrackUrl(contentUrl);
          sources.add(AudioSource.uri(Uri.parse(fullUrl), headers: audioHeaders));
        }
        source = ConcatenatingAudioSource(children: sources);
      }

      await _player!.setAudioSource(source);

      if (totalDuration > 0 && startTime >= totalDuration - 1.0) startTime = 0;
      if (startTime > 0) {
        await _seekAbsolute(startTime);
      }
      clearSeekTarget();

      _subscribeTrackIndex();
      final initChapter = _initChapterInfo(startTime);
      _pushMediaItem(itemId, title, author, coverUrl, totalDuration, chapter: initChapter);
      final bookSpeed = await PlayerSettings.getBookSpeed(itemId);
      final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
      await _player!.setSpeed(speed);
      await EqualizerService().switchItem(itemId);
      debugPrint('[Player] Starting cached session playback at ${speed}x');
      try { (await AudioSession.instance).setActive(true); } catch (_) {}
      _player!.play();
      _scheduleAudioDiagnostics('cached-session');
      notifyListeners();
      _setupSync();
      Future.delayed(const Duration(milliseconds: 500), () {
        _handler?.refreshPlaybackState();
      });
      final sleepTimer = SleepTimerService();
      sleepTimer.resetDismiss();
      sleepTimer.checkAutoSleep();
      // Refresh server session in background - gets fresh session ID and
      // handles cross-client progress sync without blocking playback start
      _refreshServerSession(api, itemId);
      return null;
    } catch (e, stack) {
      debugPrint('[Player] Cached session play error: $e\n$stack');
      // Cache was stale or invalid - clear it and signal fallback
      SessionCache.clear(itemId: itemId, episodeId: _currentEpisodeId);
      return 'cache-miss';
    }
  }

  /// Re-create the server playback session in the background after starting
  /// playback from cache. Gets a fresh session ID so progress syncing works,
  /// and handles cross-client progress (seek to server position if ahead).
  void _refreshServerSession(ApiService api, String itemId) async {
    if (_isOfflineMode) return;
    try {
      final sessionData = _currentEpisodeId != null
          ? await api.startEpisodePlaybackSession(itemId, _currentEpisodeId!)
          : await api.startPlaybackSession(itemId);
      if (sessionData == null) {
        debugPrint('[Player] Background session refresh returned null');
        return;
      }
      _playbackSessionId = sessionData['id'] as String?;
      _lastServerSync = DateTime.now();
      debugPrint('[Player] Background session refreshed: $_playbackSessionId');
      _logEvent(PlaybackEventType.sessionStart, detail: 'refresh');

      // Update cached session with fresh track data in case it changed
      final audioTracks = sessionData['audioTracks'] as List<dynamic>?;
      final sessionChapters = sessionData['chapters'] as List<dynamic>? ?? [];
      final sessionDur = (sessionData['duration'] as num?)?.toDouble() ?? 0;
      if (audioTracks != null && audioTracks.isNotEmpty) {
        SessionCache.save(
          itemId: itemId,
          episodeId: _currentEpisodeId,
          audioTracks: audioTracks,
          chapters: sessionChapters.isNotEmpty ? sessionChapters : _chapters,
          totalDuration: sessionDur > 0 ? sessionDur : _totalDuration,
        );
      }

      // Check if server position is ahead (another client advanced)
      final serverPos = (sessionData['currentTime'] as num?)?.toDouble() ?? 0;
      final localPos = position.inMilliseconds / 1000.0;
      if (serverPos > localPos + 5.0) {
        debugPrint('[Player] Server is ahead on cache-start: server=${serverPos}s vs local=${localPos}s - seeking');
        await _seekAbsolute(serverPos);
      }
    } catch (e) {
      debugPrint('[Player] Background session refresh failed: $e');
    }
  }

  Future<String?> _playFromServer(
    ApiService api,
    String itemId,
    String title,
    String author,
    String? coverUrl,
    double totalDuration,
    List<dynamic> chapters,
    double startTime, [
    bool forceStartTime = false,
  ]) async {
    debugPrint('[Player] Streaming from server: $title');
    _isOfflineMode = false;

    // Use episode endpoint if this is a podcast episode
    final sessionData = _currentEpisodeId != null
        ? await api.startEpisodePlaybackSession(_currentItemId!, _currentEpisodeId!)
        : await api.startPlaybackSession(itemId);
    if (sessionData == null) {
      debugPrint('[Player] Failed to start playback session');
      _clearState();
      return 'Could not connect to server';
    }

    _playbackSessionId = sessionData['id'] as String?;
    _lastServerSync = DateTime.now();
    _logEvent(PlaybackEventType.sessionStart, detail: 'stream');
    var audioTracks = sessionData['audioTracks'] as List<dynamic>?;
    if (audioTracks == null || audioTracks.isEmpty) {
      _clearState();
      return 'No audio files found - this item may be missing on the server';
    }

    // Detect Dolby Atmos / EAC-3 / AC-3 tracks. Samsung has a hardware Dolby
    // decoder and iOS AVPlayer handles EAC3 natively, so only force transcode
    // on other Android devices where the software codec often fails or outputs silence.
    if (!forceStartTime && Platform.isAndroid &&
        !ApiService.deviceManufacturer.toLowerCase().contains('samsung')) {
      final needsTranscode = audioTracks.any((t) {
        final mime = ((t as Map<String, dynamic>)['mimeType'] as String? ?? '').toLowerCase();
        final codec = (t['codec'] as String? ?? '').toLowerCase();
        return mime.contains('eac3') || mime.contains('ac3') || mime.contains('ac4') ||
            mime.contains('atmos') || codec.contains('eac3') || codec.contains('ac3') ||
            codec.contains('ac4') || codec.contains('atmos');
      });
      if (needsTranscode) {
        debugPrint('[Player] Dolby/EAC3 track detected - restarting with server transcoding');
        try { await api.closePlaybackSession(_playbackSessionId!); } catch (_) {}
        _playbackSessionId = null;
        final retrySession = _currentEpisodeId != null
            ? await api.startEpisodePlaybackSession(_currentItemId!, _currentEpisodeId!, forceTranscode: true)
            : await api.startPlaybackSession(itemId, forceTranscode: true);
        if (retrySession == null) {
          _clearState();
          return 'Could not start transcoded playback';
        }
        _playbackSessionId = retrySession['id'] as String?;
        audioTracks = retrySession['audioTracks'] as List<dynamic>? ?? [];
        if (audioTracks.isEmpty) {
          _clearState();
          return 'No audio files in transcoded session';
        }
        final sessionChapters = retrySession['chapters'] as List<dynamic>? ?? [];
        if (sessionChapters.isNotEmpty) {
          chapters = sessionChapters;
          _chapters = sessionChapters;
          _handler?.updateChaptersQueue(sessionChapters);
        }
        final sessionDur = (retrySession['duration'] as num?)?.toDouble() ?? 0;
        if (sessionDur > 0) {
          totalDuration = sessionDur;
          _totalDuration = sessionDur;
        }
      }
    }

    // Pick up chapters from session (e.g. podcast episodes with embedded chapters)
    if (chapters.isEmpty) {
      final sessionChapters = sessionData['chapters'] as List<dynamic>? ?? [];
      if (sessionChapters.isNotEmpty) {
        chapters = sessionChapters;
        _chapters = sessionChapters;
        _handler?.updateChaptersQueue(sessionChapters);
        debugPrint('[Player] Loaded ${sessionChapters.length} chapters from session');
      }
    }


    // Update totalDuration from session if it was unknown (e.g. podcast episodes
    // where the embedded recentEpisode didn't include a duration field)
    if (totalDuration <= 0) {
      final sessionDur = (sessionData['duration'] as num?)?.toDouble() ?? 0;
      if (sessionDur > 0) {
        totalDuration = sessionDur;
        _totalDuration = sessionDur;
        debugPrint('[Player] Updated totalDuration from session: ${sessionDur}s');
      }
    }

    // Compare server position vs local.
    // Usually the furthest position wins, but if local is ahead we also
    // check timestamps to catch stale local saves.
    // Skip all of this when startTime was forced (bookmark/chapter jump).
    final serverPos = (sessionData['currentTime'] as num?)?.toDouble() ?? 0;
    final pKey = _currentEpisodeId != null ? '$itemId-$_currentEpisodeId' : itemId;
    final localTs = await _progressSync.getSavedTimestamp(pKey);
    if (forceStartTime) {
      debugPrint('[Player] Forced start time: ${startTime}s — skipping server/local position comparison');
    } else if (serverPos > startTime + 1.0) {
      debugPrint('[Player] Server position is ahead: server=${serverPos}s vs local=${startTime}s — using server');
      startTime = serverPos;
    } else if (startTime > 0) {
      bool useServer = false;
      if (localTs > 0) {
        try {
          final serverProgress = await api.getItemProgress(pKey);
          final serverLastUpdate = (serverProgress?['lastUpdate'] as num?)?.toInt() ?? 0;
          if (serverLastUpdate > localTs) {
            debugPrint('[Player] Local position is ahead but stale: local=${startTime}s (ts=$localTs) vs server=${serverPos}s (ts=$serverLastUpdate) — using server');
            startTime = serverPos;
            useServer = true;
          }
        } catch (_) {}
      }
      if (!useServer) {
        debugPrint('[Player] Local position is ahead: local=${startTime}s vs server=${serverPos}s — keeping local');
      }
    } else if (serverPos > 0) {
      debugPrint('[Player] No local position, using server: ${serverPos}s');
      startTime = serverPos;
    }

    try {
      _currentTrackIndex = 0;
      final audioHeaders = api.mediaHeaders;

      // Build audio source - one source per track file
      _buildTrackOffsets(audioTracks);
      _captureStreamUrls(audioTracks, api);
      AudioSource source;
      if (audioTracks.length == 1) {
        final track = audioTracks.first as Map<String, dynamic>;
        final contentUrl = track['contentUrl'] as String? ?? '';
        final fullUrl = api.buildTrackUrl(contentUrl);
        source = AudioSource.uri(Uri.parse(fullUrl), headers: audioHeaders);
      } else {
        final sources = <AudioSource>[];
        for (final t in audioTracks) {
          final track = t as Map<String, dynamic>;
          final contentUrl = track['contentUrl'] as String? ?? '';
          final fullUrl = api.buildTrackUrl(contentUrl);
          sources.add(AudioSource.uri(Uri.parse(fullUrl), headers: audioHeaders));
        }
        source = ConcatenatingAudioSource(children: sources);
      }

      await _player!.setAudioSource(source);

      // If the saved position is at (or past) the end, restart from the beginning
      if (totalDuration > 0 && startTime >= totalDuration - 1.0) startTime = 0;
      if (startTime > 0) {
        await _seekAbsolute(startTime);
      }
      clearSeekTarget(); // Seek done; let position events flow immediately

      _subscribeTrackIndex();
      final initChapter = _initChapterInfo(startTime);
      _pushMediaItem(itemId, title, author, coverUrl, totalDuration, chapter: initChapter);
      final bookSpeed = await PlayerSettings.getBookSpeed(itemId);
      final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
      await _player!.setSpeed(speed);
      await EqualizerService().switchItem(itemId);
      debugPrint('[Player] Starting stream playback at ${speed}x');
      // Re-activate audio session before play (see local playback comment above)
      try { (await AudioSession.instance).setActive(true); } catch (_) {}
      _player!.play();
      _scheduleAudioDiagnostics('stream');
      notifyListeners();
      _setupSync();
      // Ensure iOS lock screen / Control Center controls appear (see local playback comment)
      Future.delayed(const Duration(milliseconds: 500), () {
        _handler?.refreshPlaybackState();
      });
      // Fresh session — reset auto sleep dismiss and check
      final sleepTimer = SleepTimerService();
      sleepTimer.resetDismiss();
      sleepTimer.checkAutoSleep();
      // Cache session metadata so next play can start instantly
      SessionCache.save(
        itemId: itemId,
        episodeId: _currentEpisodeId,
        audioTracks: audioTracks,
        chapters: chapters,
        totalDuration: totalDuration,
      );
      return null;
    } catch (e, stack) {
      debugPrint('[Player] Stream error: $e\n$stack');

      // If this looks like a codec/renderer error, retry with server-side
      // transcoding.  Common with Dolby Atmos, EAC-3, multi-channel audio, etc.
      final errStr = e.toString();
      if (!forceStartTime && // avoid infinite retry loops (forceStartTime is reused as retry guard)
          (errStr.contains('MediaCodecAudioRenderer') ||
           errStr.contains('AudioTrack') ||
           errStr.contains('Decoder') ||
           errStr.contains('format_supported'))) {
        debugPrint('[Player] Codec error detected - retrying with server transcoding');
        // Preserve item identity before wiping state so the absorbing card
        // stays visible during the retry and the episode endpoint can be used
        // correctly. _clearState() would null _currentItemId/_currentEpisodeId,
        // making hasBook = false (card vanishes) and breaking podcast retries.
        final retryItemId = _currentItemId;
        final retryEpId = _currentEpisodeId;
        final retryEpTitle = _currentEpisodeTitle;
        final retryTitle = _currentTitle;
        final retryAuthor = _currentAuthor;
        final retryCover = _currentCoverUrl;
        _clearState();
        _currentItemId = retryItemId;
        _currentEpisodeId = retryEpId;
        _currentEpisodeTitle = retryEpTitle;
        _currentTitle = retryTitle;
        _currentAuthor = retryAuthor;
        _currentCoverUrl = retryCover;
        // Close the failed session
        if (_playbackSessionId != null) {
          try { await api.closePlaybackSession(_playbackSessionId!); } catch (_) {}
          _playbackSessionId = null;
        }
        // Retry with transcode
        final retrySession = _currentEpisodeId != null
            ? await api.startEpisodePlaybackSession(_currentItemId!, _currentEpisodeId!, forceTranscode: true)
            : await api.startPlaybackSession(itemId, forceTranscode: true);
        if (retrySession != null) {
          _playbackSessionId = retrySession['id'] as String?;
          _lastServerSync = DateTime.now();
          final retryTracks = retrySession['audioTracks'] as List<dynamic>?;
          if (retryTracks != null && retryTracks.isNotEmpty) {
            try {
              _currentTrackIndex = 0;
              _buildTrackOffsets(retryTracks);
              AudioSource retrySource;
              final audioHeaders = api.mediaHeaders;
              if (retryTracks.length == 1) {
                final track = retryTracks.first as Map<String, dynamic>;
                final contentUrl = track['contentUrl'] as String? ?? '';
                final fullUrl = api.buildTrackUrl(contentUrl);
                retrySource = AudioSource.uri(Uri.parse(fullUrl), headers: audioHeaders);
              } else {
                final sources = <AudioSource>[];
                for (final t in retryTracks) {
                  final track = t as Map<String, dynamic>;
                  final contentUrl = track['contentUrl'] as String? ?? '';
                  final fullUrl = api.buildTrackUrl(contentUrl);
                  sources.add(AudioSource.uri(Uri.parse(fullUrl), headers: audioHeaders));
                }
                retrySource = ConcatenatingAudioSource(children: sources);
              }
              await _player!.setAudioSource(retrySource);
              if (totalDuration > 0 && startTime >= totalDuration - 1.0) startTime = 0;
              if (startTime > 0) await _seekAbsolute(startTime);
              clearSeekTarget();
              _subscribeTrackIndex();
              final initChapter = _initChapterInfo(startTime);
              _pushMediaItem(itemId, title, author, coverUrl, totalDuration, chapter: initChapter);
              final bookSpeed = await PlayerSettings.getBookSpeed(itemId);
              final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
              await _player!.setSpeed(speed);
              await EqualizerService().switchItem(itemId);
              debugPrint('[Player] Transcoded playback starting at ${speed}x');
              try { (await AudioSession.instance).setActive(true); } catch (_) {}
              _player!.play();
              _scheduleAudioDiagnostics('transcoded-retry');
              notifyListeners();
              _setupSync();
              Future.delayed(const Duration(milliseconds: 500), () {
                _handler?.refreshPlaybackState();
              });
              final sleepTimer = SleepTimerService();
              sleepTimer.resetDismiss();
              sleepTimer.checkAutoSleep();
              // Cache the transcoded session so next cold start is instant
              SessionCache.save(
                itemId: itemId,
                episodeId: _currentEpisodeId,
                audioTracks: retryTracks,
                chapters: _chapters,
                totalDuration: totalDuration,
              );
              return null;
            } catch (retryError) {
              debugPrint('[Player] Transcoded playback also failed: $retryError');
            }
          }
        }
      }

      _clearState();
      return 'Playback failed: ${e.toString().split('\n').first}';
    }
  }

  bool _transcodeRetryInFlight = false;

  Future<void> _retryWithTranscode() async {
    if (_transcodeRetryInFlight) return;
    _transcodeRetryInFlight = true;
    try {
      final api = _api;
      if (api == null || _currentItemId == null) return;
      debugPrint('[Player] Codec error in playback stream - retrying with server transcoding');
      final itemId = _currentItemId!;
      final retryEpId = _currentEpisodeId;
      final retryEpTitle = _currentEpisodeTitle;
      final retryTitle = _currentTitle ?? '';
      final retryAuthor = _currentAuthor ?? '';
      final retryCover = _currentCoverUrl;
      final startTime = (_player?.position.inMilliseconds ?? 0) / 1000.0;
      _clearState();
      _currentItemId = itemId;
      _currentEpisodeId = retryEpId;
      _currentEpisodeTitle = retryEpTitle;
      _currentTitle = retryTitle;
      _currentAuthor = retryAuthor;
      _currentCoverUrl = retryCover;
      if (_playbackSessionId != null) {
        try { await api.closePlaybackSession(_playbackSessionId!); } catch (_) {}
        _playbackSessionId = null;
      }
      final retrySession = retryEpId != null
          ? await api.startEpisodePlaybackSession(itemId, retryEpId, forceTranscode: true)
          : await api.startPlaybackSession(itemId, forceTranscode: true);
      if (retrySession == null) return;
      _playbackSessionId = retrySession['id'] as String?;
      _lastServerSync = DateTime.now();
      final retryTracks = retrySession['audioTracks'] as List<dynamic>?;
      final totalDuration = (retrySession['duration'] as num?)?.toDouble() ?? _totalDuration;
      final chapters = retrySession['chapters'] as List<dynamic>? ?? _chapters;
      _chapters = chapters;
      _totalDuration = totalDuration;
      if (retryTracks == null || retryTracks.isEmpty) return;
      _currentTrackIndex = 0;
      _buildTrackOffsets(retryTracks);
      AudioSource retrySource;
      final audioHeaders = api.mediaHeaders;
      if (retryTracks.length == 1) {
        final track = retryTracks.first as Map<String, dynamic>;
        final contentUrl = track['contentUrl'] as String? ?? '';
        retrySource = AudioSource.uri(Uri.parse(api.buildTrackUrl(contentUrl)), headers: audioHeaders);
      } else {
        final sources = <AudioSource>[];
        for (final t in retryTracks) {
          final track = t as Map<String, dynamic>;
          final contentUrl = track['contentUrl'] as String? ?? '';
          sources.add(AudioSource.uri(Uri.parse(api.buildTrackUrl(contentUrl)), headers: audioHeaders));
        }
        retrySource = ConcatenatingAudioSource(children: sources);
      }
      await _player!.setAudioSource(retrySource);
      if (startTime > 0) await _seekAbsolute(startTime);
      clearSeekTarget();
      _subscribeTrackIndex();
      final initChapter = _initChapterInfo(startTime);
      _pushMediaItem(itemId, retryTitle, retryAuthor, retryCover, totalDuration, chapter: initChapter);
      final bookSpeed = await PlayerSettings.getBookSpeed(itemId);
      final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
      await _player!.setSpeed(speed);
      await EqualizerService().switchItem(itemId);
      debugPrint('[Player] Transcoded playback starting at ${speed}x');
      try { (await AudioSession.instance).setActive(true); } catch (_) {}
      _player!.play();
      _scheduleAudioDiagnostics('transcoded');
      notifyListeners();
      _setupSync();
      Future.delayed(const Duration(milliseconds: 500), () {
        _handler?.refreshPlaybackState();
      });
      final sleepTimer = SleepTimerService();
      sleepTimer.resetDismiss();
      sleepTimer.checkAutoSleep();
      SessionCache.save(
        itemId: itemId,
        episodeId: retryEpId,
        audioTracks: retryTracks,
        chapters: chapters,
        totalDuration: totalDuration,
      );
    } catch (e) {
      debugPrint('[Player] Transcode retry failed: $e');
    } finally {
      _transcodeRetryInFlight = false;
    }
  }

  /// Set _currentChapterStart/End for the chapter containing [posSeconds].
  /// Returns the chapter title (or null) so _pushMediaItem can show it.
  String? _initChapterInfo(double posSeconds) {
    if (_chapters.isEmpty) return null;
    for (int i = 0; i < _chapters.length; i++) {
      final ch = _chapters[i] as Map<String, dynamic>;
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? _totalDuration;
      if (posSeconds >= start && posSeconds < end) {
        _currentChapterStart = start;
        _currentChapterEnd = end;
        _lastNotifiedChapterIndex = i;
        return ch['title'] as String?;
      }
    }
    // Past all chapters — use the last one
    if (_chapters.isNotEmpty) {
      final last = _chapters.last as Map<String, dynamic>;
      _currentChapterStart = (last['start'] as num?)?.toDouble() ?? 0;
      _currentChapterEnd = (last['end'] as num?)?.toDouble() ?? _totalDuration;
      _lastNotifiedChapterIndex = _chapters.length - 1;
      return last['title'] as String?;
    }
    return null;
  }

  /// Content provider authority — must match CoverContentProvider and AndroidManifest.
  static const _coverAuthority = 'com.barnabas.absorb.covers';

  void _pushMediaItem(String itemId, String title, String author,
      String? coverUrl, double totalDuration, {String? chapter}) {
    // Alpha [PodDur]: trace every push-site. We want to see which callers
    // pass only the parent itemId (missing -episodeId suffix) and/or a zero
    // duration, so we can pinpoint what to fix for the AA podcast progress
    // bar. Includes the current _totalDuration so "stale 0" paths are visible.
    debugPrint('[PodDur] _pushMediaItem: itemId=$itemId ep=$_currentEpisodeId argDur=${totalDuration.toStringAsFixed(1)}s _totalDuration=${_totalDuration.toStringAsFixed(1)}s');
    // Android: Always use content:// URI for Now Playing artwork - some OEMs
    // (e.g. Vivo) don't load HTTP URLs in MediaSession. The CoverContentProvider
    // handles both downloaded and streamed covers.
    // iOS: prefer the local cover file for downloaded books so the lock
    // screen shows artwork even when the user is offline. Fall back to the
    // remote HTTP URL when there's no local cover (streaming).
    String? effectiveCoverUrl;
    if (Platform.isIOS) {
      final localCover = DownloadService().getInfo(itemId).localCoverPath;
      if (localCover != null && localCover.isNotEmpty) {
        effectiveCoverUrl = Uri.file(localCover).toString();
      } else {
        effectiveCoverUrl = coverUrl;
      }
    } else {
      effectiveCoverUrl = 'content://$_coverAuthority/cover/$itemId';
    }
    _updateNotificationMediaItem(itemId, title, author, effectiveCoverUrl, totalDuration, chapter: chapter);
  }

  void _updateNotificationMediaItem(String itemId, String title, String author,
      String? coverUrl, double totalDuration, {String? chapter}) {
    final displayArtist = chapter != null && chapter.isNotEmpty
        ? '$author · $chapter'
        : author;
    // In chapter progress mode, show chapter duration instead of full book
    final rawDuration = notifChapterMode
        ? (_currentChapterEnd - _currentChapterStart)
        : totalDuration;
    // Divide by playback speed so Android Auto / WearOS / notification
    // show "real time remaining" instead of raw content duration.
    final speed = _player?.speed ?? 1.0;
    final displayDuration = speed > 0 && speed != 1.0
        ? rawDuration / speed
        : rawDuration;
    // Alpha: confirms MediaItem metadata flowing to MediaSession for GH #172
    // (BT car display stuck on prior chapter). If this fires with fresh
    // artist/chapter text but the car still shows old, the issue is downstream
    // of audio_service's MediaSession push.
    debugPrint('[Handler] mediaItem.add: item=$itemId artist="$displayArtist" dur=${displayDuration.round()}s chapter=$chapter hasHandler=${_handler != null}');
    _handler!.mediaItem.add(MediaItem(
      id: itemId,
      title: title,
      artist: displayArtist,
      album: title,
      duration: Duration(seconds: displayDuration.round()),
      artUri: coverUrl != null ? Uri.tryParse(coverUrl) : null,
    ));
  }


  void _clearState() {
    _currentItemId = null;
    _currentEpisodeId = null;
    _currentEpisodeTitle = null;
    _currentTitle = null;
    _currentAuthor = null;
    _currentCoverUrl = null;
    _playbackSessionId = null;
    _isOfflineMode = false;
    _trackStartOffsets = [];
    _currentTrackIndex = 0;
    _lastNotifiedChapterIndex = -1;
    _lastSeekTargetSeconds = null;
    _lastSeekTime = null;
    _indexSub?.cancel();
    _indexSub = null;
    _syncSub?.cancel();
    _syncSub = null;
    _completionSub?.cancel();
    _completionSub = null;
    _lastKnownPositionSec = 0;

    _bgSaveTimer?.cancel();
    _bgSaveTimer = null;
    _eqSessionSub?.cancel();
    _eqSessionSub = null;
    _streamRetryCount = 0;
    _retryInProgress = false;

    _stuckCheckTimer?.cancel();
    _stuckCheckTimer = null;
    _playVerifyTimer?.cancel();
    _playVerifyTimer = null;
    _resetStuckDetection();
    _noisyPause = false;
    notifyListeners();
  }

  /// Attempt to recover from a stream error by restarting playback from the
  /// last known position.  Tries up to [_maxStreamRetries] times with
  /// exponential back-off (1s, 2s, 4s).  If the item has been downloaded in
  /// the meantime, falls back to local files automatically.
  Future<void> _attemptStreamRetry(Object error) async {
    if (_retryInProgress) return;
    if (_currentItemId == null || _api == null) return;
    if (_streamRetryCount >= _maxStreamRetries) {
      debugPrint('[Player] Max retries reached ($_maxStreamRetries) — giving up');
      return;
    }

    _retryInProgress = true;
    _streamRetryCount++;
    final delay = Duration(seconds: 1 << (_streamRetryCount - 1)); // 1s, 2s, 4s
    debugPrint('[Player] Stream error — retry $_streamRetryCount/$_maxStreamRetries in ${delay.inSeconds}s');

    await Future<void>.delayed(delay);

    // Snapshot state before retry — playItem will overwrite these
    final itemId = _currentItemId;
    final title = _currentTitle ?? '';
    final author = _currentAuthor ?? '';
    final coverUrl = _currentCoverUrl;
    final totalDuration = _totalDuration;
    final chapters = List<dynamic>.from(_chapters);
    final episodeId = _currentEpisodeId;
    final episodeTitle = _currentEpisodeTitle;
    final api = _api!;
    final retryPos = _lastKnownPositionSec;

    if (itemId == null) {
      _retryInProgress = false;
      return;
    }

    debugPrint('[Player] Retrying playback at ${retryPos.toStringAsFixed(1)}s');
    final ok = await playItem(
      api: api,
      itemId: itemId,
      title: title,
      author: author,
      coverUrl: coverUrl,
      totalDuration: totalDuration,
      chapters: chapters,
      startTime: retryPos,
      episodeId: episodeId,
      episodeTitle: episodeTitle,
    );

    _retryInProgress = false;
    if (ok == null) {
      debugPrint('[Player] Retry succeeded');
    } else {
      debugPrint('[Player] Retry failed: $ok');
    }
  }

  int _lastSyncSecond = -1;
  int _lastBgProcessedSec = -1;

  StreamSubscription? _eqSessionSub;

  void _attachEqualizer() {
    _eqSessionSub?.cancel();
    _eqSessionSub = null;
    if (_player == null) return;

    // Try immediately — works if audio source is already set
    final sessionId = _player!.androidAudioSessionId;
    if (sessionId != null && sessionId > 0) {
      EqualizerService().attachToSession(sessionId);
      return;
    }

    // Not available yet — poll briefly after playback starts
    // (safer than androidAudioSessionIdStream which may not exist in all versions)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_player == null) return;
      final id = _player!.androidAudioSessionId;
      if (id != null && id > 0) {
        debugPrint('[Player] Got audio session ID (delayed): $id');
        EqualizerService().attachToSession(id);
      } else {
        // Try once more after another second
        Future.delayed(const Duration(seconds: 1), () {
          if (_player == null) return;
          final id2 = _player!.androidAudioSessionId;
          if (id2 != null && id2 > 0) {
            debugPrint('[Player] Got audio session ID (retry): $id2');
            EqualizerService().attachToSession(id2);
          }
        });
      }
    });
  }

  void _setupSync() {
    _syncSub?.cancel();
    _completionSub?.cancel();
    _bgSaveTimer?.cancel();
    _lastSyncSecond = -1;
    _lastBgProcessedSec = -1;
    _lastChapterCheckSec = -1;
    _lastKnownPositionSec = 0;
    _lastServerSync = DateTime.now();
    _positionSyncInProgress = false;
    _positionSyncFailures = 0;
    // Cache prefs in background - not needed synchronously here
    if (_prefs == null) {
      SharedPreferences.getInstance().then((p) => _prefs = p);
    }

    // Safety-net timer for position persistence when Android throttles the
    // Dart position stream in the background. The primary positionStream
    // listener saves every 5s; this only matters when that stream goes silent.

    _bgSaveTimer = Timer.periodic(const Duration(seconds: 300), (_) async {
      if (_currentItemId == null || _player == null || !_player!.playing) return;
      final pos = position;
      final posSec = pos.inMilliseconds / 1000.0;
      if (posSec <= 0) return;
      await _saveProgressLocal(pos);
    });

    // Attach equalizer to current audio session
    _attachEqualizer();

    // ─── Primary completion detection via processingState ───
    // This fires reliably when ExoPlayer reaches STATE_ENDED, before any
    // position-reset can confuse the position-based detection.
    _completionSub = _player?.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _currentItemId != null) {
        _onPlaybackComplete();
      }
      // Notify UI when buffering/loading state changes so spinners update.
      // Skip when backgrounded - no visible UI to rebuild; flushed on foreground.
      if (!_isBackgrounded &&
          (state == ProcessingState.ready || state == ProcessingState.loading || state == ProcessingState.buffering)) {
        notifyListeners();
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('[Player] processingState stream error: $e');
      _attemptStreamRetry(e);
    });
    _syncSub = _player?.positionStream.listen((trackRelativePos) async {
      // Reset retry counter on successful position updates
      _streamRetryCount = 0;
      // Convert track-relative position to absolute book position
      final absolutePos = position; // uses the getter which adds track offset
      final sec = absolutePos.inSeconds;
      final posSec = absolutePos.inMilliseconds / 1000.0;

      // ─── Position-reset guard ────────────────────────────
      // ExoPlayer can seek to 0 on STATE_ENDED. If we were near the end
      // and suddenly jump to near 0 without a user seek, treat it as
      // completion rather than restarting playback.
      if (_lastKnownPositionSec > 0 && _totalDuration > 0) {
        final wasNearEnd = _lastKnownPositionSec >= _totalDuration - 5.0;
        final nowNearStart = posSec < 2.0;
        if (wasNearEnd && nowNearStart) {
          debugPrint('[Player] Position jumped from ${_lastKnownPositionSec.toStringAsFixed(1)}s to ${posSec.toStringAsFixed(1)}s — treating as completion');
          _onPlaybackComplete();
          return;
        }
      }
      if (posSec > 0) _lastKnownPositionSec = posSec;

      if (sec <= 0) return;

      // In background, only process once per second to save CPU.
      if (_isBackgrounded) {
        if (sec == _lastBgProcessedSec) return;
        _lastBgProcessedSec = sec;
      }

      // ─── Chapter change detection ──────────────────────────
      // Update notification subtitle when the chapter changes.
      // Throttled to once per second — chapters can't change faster than that.
      if (_chapters.isNotEmpty && _currentItemId != null && sec != _lastChapterCheckSec) {
        _lastChapterCheckSec = sec;
        int chapterIdx = -1;
        String? chapterTitle;
        double chapterStart = 0;
        double chapterEnd = _totalDuration;

        // Fast path: check if still in the cached chapter
        if (_lastNotifiedChapterIndex >= 0 && _lastNotifiedChapterIndex < _chapters.length) {
          final ch = _chapters[_lastNotifiedChapterIndex] as Map<String, dynamic>;
          final s = (ch['start'] as num?)?.toDouble() ?? 0;
          final e = (ch['end'] as num?)?.toDouble() ?? _totalDuration;
          if (posSec >= s && posSec < e) {
            chapterIdx = _lastNotifiedChapterIndex;
            chapterTitle = ch['title'] as String?;
            chapterStart = s;
            chapterEnd = e;
          }
        }

        // Slow path: linear scan only if cached chapter didn't match
        if (chapterIdx < 0) {
          for (int i = 0; i < _chapters.length; i++) {
            final ch = _chapters[i] as Map<String, dynamic>;
            final start = (ch['start'] as num?)?.toDouble() ?? 0;
            final end = (ch['end'] as num?)?.toDouble() ?? _totalDuration;
            if (posSec >= start && posSec < end) {
              chapterIdx = i;
              chapterTitle = ch['title'] as String?;
              chapterStart = start;
              chapterEnd = end;
              break;
            }
          }
        }

        if (chapterIdx >= 0 && chapterIdx != _lastNotifiedChapterIndex) {
          debugPrint('[Battery] Chapter change: idx=$chapterIdx "$chapterTitle" at ${posSec.toStringAsFixed(1)}s');
          _lastNotifiedChapterIndex = chapterIdx;
          _currentChapterStart = chapterStart;
          _currentChapterEnd = chapterEnd;
          _pushMediaItem(
            _currentItemId!, _currentTitle ?? '', _currentAuthor ?? '',
            _currentCoverUrl, _totalDuration,
            chapter: chapterTitle,
          );
          // Force PlaybackState refresh so the notification position resets
          // to 0 immediately instead of waiting for the next stream event.
          if (_notifChapterMode) _handler?.refreshPlaybackState();
        }
      }

      // ─── Completion detection (fallback) ───────────────────
      // processingStateStream is the primary signal; this is a safety net.
      if (_totalDuration > 0 && posSec >= _totalDuration - 1.0) {
        _onPlaybackComplete();
        return;
      }

      // Save locally every 5 seconds (always works, even offline)
      if (sec % 5 == 0 && sec != _lastSyncSecond && _currentItemId != null) {
        _lastSyncSecond = sec;
        _saveProgressLocal(absolutePos);

        // Sync to server: 60s foreground, 300s background
        final syncInterval = _isBackgrounded ? 300 : 60;
        final sinceLastSync = DateTime.now().difference(_lastServerSync).inSeconds;
        if (sinceLastSync >= syncInterval && !_positionSyncInProgress) {
          _positionSyncInProgress = true;
          try {
            final manualOffline = (_prefs ?? await SharedPreferences.getInstance())
                .getBool('manual_offline_mode') ?? false;

            if (manualOffline || _isOfflineMode || _playbackSessionId == null) {
              // Offline or no session - accumulate listening time locally
              final progressKey = _currentEpisodeId != null
                  ? '$_currentItemId-$_currentEpisodeId'
                  : _currentItemId!;
              final offlineSeconds = sinceLastSync.clamp(0, 300);
              _progressSync.addOfflineListeningTime(progressKey, offlineSeconds);
              // Widget ticks forward even when the server is unreachable.
              unawaited(HomeWidgetService()
                  .addLocalListeningSeconds(offlineSeconds));
              // Reset the sync clock so the next tick waits a full interval
              // before accumulating again.
              _lastServerSync = DateTime.now();
            }

            // Back off when the server is unreachable to avoid hammering
            // every sync interval with requests that will just timeout.
            if (_positionSyncFailures >= 3) {
              // Skip server sync - will retry after connectivity change
              // or app foreground resets the counter.
              _lastServerSync = DateTime.now();
            } else if (manualOffline) {
              // Manual offline - local save only, no server sync
            } else if (!_isOfflineMode && _playbackSessionId != null) {
              // Streaming/local with session: sync via session
              _syncToServer(absolutePos);
            } else if (!_isOfflineMode && _api != null && _currentItemId != null) {
              // No session but online - sync via progress update endpoint
              try {
                final syncKey = _currentEpisodeId != null
                    ? '$_currentItemId-$_currentEpisodeId'
                    : _currentItemId!;
                final ok = await _progressSync.syncToServer(
                    api: _api!, itemId: syncKey);
                if (ok) {
                  debugPrint('[Player] No-session sync succeeded');
                  _positionSyncFailures = 0;
                } else {
                  _positionSyncFailures++;
                  debugPrint('[Player] No-session sync returned false (failures=$_positionSyncFailures)');
                }
              } catch (e) {
                _positionSyncFailures++;
                debugPrint('[Player] No-session sync error (failures=$_positionSyncFailures): $e');
              }
            }
          } finally {
            _positionSyncInProgress = false;
          }
        }
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('[Player] Position stream error: $e');
      _attemptStreamRetry(e);
    });

    // Start stuck position detection (xHE-AAC/USAC iOS seek failures)
    _startStuckDetection();
  }

  /// Reset stuck detection state - call on manual seek or when position advances.
  void _resetStuckDetection() {
    _stuckConsecutiveCount = 0;
    _stuckReseekAttempts = 0;
    _stuckCheckLastPosition = -1;
  }

  /// Verify that playback actually started after calling play().
  /// iOS USAC/xHE-AAC decoder can silently fail after a seek, leaving the
  /// player in a non-playing state with no error events. If after 3 seconds
  /// the player isn't playing and isn't loading, re-seek and retry.
  void _schedulePlayVerify() {
    _playVerifyTimer?.cancel();
    if (!Platform.isIOS) return; // only needed on iOS
    final posAtPlay = _lastKnownPositionSec;
    _playVerifyTimer = Timer(const Duration(seconds: 3), () async {
      if (_player == null || _currentItemId == null) return;
      // If playing or actively loading/buffering, all is well
      if (_player!.playing) return;
      final state = _player!.processingState;
      if (state == ProcessingState.loading || state == ProcessingState.buffering) return;
      // Player is idle/ready but not playing — silent failure
      final currentPos = position.inMilliseconds / 1000.0;
      debugPrint('[Player] Play verify failed: not playing after 3s '
          '(state=${state.name}, pos=${currentPos.toStringAsFixed(1)}s, '
          'posAtPlay=${posAtPlay.toStringAsFixed(1)}s)');
      // Re-seek to current position to kick the decoder, then retry play
      await _seekAbsolute(currentPos > 0 ? currentPos : posAtPlay);
      _player?.play();
      notifyListeners();
    });
  }

  /// Start a periodic timer that checks if playback position is advancing.
  /// If position is stuck for ~20 seconds while playing (2 consecutive checks),
  /// force a re-seek to the same position to kick the iOS decoder.
  void _startStuckDetection() {
    _stuckCheckTimer?.cancel();
    _resetStuckDetection();

    // Stuck detection is only needed on iOS (xHE-AAC/USAC decoder freeze).
    // Skip on Android to reduce background CPU wakeups.
    if (!Platform.isIOS) return;


    _stuckCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      // Only check while actively playing
      if (_player == null || !_player!.playing) {
        _stuckCheckLastPosition = -1;
        _stuckConsecutiveCount = 0;
        return;
      }

      // Don't check during loading/buffering
      final state = _player!.processingState;
      if (state == ProcessingState.loading || state == ProcessingState.buffering) {
        return;
      }

      // Give up after max re-seek attempts to avoid infinite loops
      if (_stuckReseekAttempts >= _maxStuckReseekAttempts) return;

      final currentPos = position.inMilliseconds / 1000.0;
      if (currentPos <= 0) return;

      if (_stuckCheckLastPosition >= 0) {
        // Check if position has advanced (allow small tolerance for rounding)
        final advanced = (currentPos - _stuckCheckLastPosition).abs() > 0.1;
        if (advanced) {
          // Position is moving - reset counters
          _stuckConsecutiveCount = 0;
          _stuckReseekAttempts = 0;
        } else {
          // Position hasn't moved
          _stuckConsecutiveCount++;
          if (_stuckConsecutiveCount >= 2) {
            // Stuck for ~20 seconds - force re-seek
            _stuckReseekAttempts++;
            _stuckConsecutiveCount = 0;
            debugPrint('[Player] Stuck position detected - re-seeking '
                '(attempt $_stuckReseekAttempts/$_maxStuckReseekAttempts '
                'at ${currentPos.toStringAsFixed(1)}s)');
            await _seekAbsolute(currentPos);
          }
        }
      }

      _stuckCheckLastPosition = currentPos;
    });
  }

  bool _isCompletingBook = false;

  Future<void> _onPlaybackComplete() async {
    // Alpha: captures completion path choice for GH #186 (book restart bug).
    // Re-entry attempts are logged too so we can see if completion fires
    // multiple times from different signals (processingState, position-jump,
    // fallback) and races with auto-advance.
    debugPrint('[Complete] entry: pos=${_lastKnownPositionSec.toStringAsFixed(1)}s totalDur=${_totalDuration.toStringAsFixed(1)}s item=$_currentItemId ep=$_currentEpisodeId reentry=$_isCompletingBook');
    if (_isCompletingBook) return; // prevent re-entry
    _isCompletingBook = true;

    // Sanity check: if we're not near the end of the book, this is a spurious
    // completion signal (iOS AVPlayer can fire completed on audio interruptions,
    // buffer errors, etc.). Save current position and stop - don't mark finished
    // or advance the queue.
    if (_totalDuration > 0 && _lastKnownPositionSec > 0 &&
        _lastKnownPositionSec < _totalDuration * 0.9 &&
        _lastKnownPositionSec < _totalDuration - 30) {
      debugPrint('[Player] Spurious completion at ${_lastKnownPositionSec.toStringAsFixed(1)}s / ${_totalDuration.toStringAsFixed(1)}s — saving position instead of marking finished');
      _logEvent(PlaybackEventType.pause, detail: 'Spurious completion blocked');
      _syncSub?.cancel();
      _syncSub = null;
      _completionSub?.cancel();
      _completionSub = null;
      _bgSaveTimer?.cancel();
      _bgSaveTimer = null;
      await _player?.stop();
      await _saveProgressLocal(Duration(milliseconds: (_lastKnownPositionSec * 1000).round()));
      _isCompletingBook = false;
      notifyListeners();
      return;
    }

    debugPrint('[Player] Book complete: $_currentTitle');
    _logEvent(PlaybackEventType.bookFinished);

    // Stop immediately to prevent ExoPlayer from seeking back to position 0
    // (which triggers position-stream events that look like a restart).
    // Cancel subscriptions first so we don't process stale events.
    _syncSub?.cancel();
    _syncSub = null;
    _completionSub?.cancel();
    _completionSub = null;
    _bgSaveTimer?.cancel();
    _bgSaveTimer = null;
    await _player?.stop();

    // Mark as finished on the server (fire-and-forget to avoid blocking
    // auto-advance — the local save below is the source of truth).
    final itemId = _currentItemId;
    final episodeId = _currentEpisodeId;
    if (itemId != null && _api != null) {
      final api = _api!;
      final dur = _totalDuration;
      unawaited(() async {
        try {
          if (episodeId != null) {
            await api.updateEpisodeProgress(
              itemId, episodeId,
              currentTime: dur,
              duration: dur,
              isFinished: true,
            );
          } else {
            await api.markFinished(itemId, dur);
          }
          debugPrint('[Player] Marked as finished on server');
        } catch (e) {
          debugPrint('[Player] Failed to mark finished: $e');
        }
      }());
    }

    // Save locally as finished (fast, ensures offline correctness)
    if (itemId != null) {
      final progressKey = episodeId != null ? '$itemId-$episodeId' : itemId;
      await _progressSync.saveLocal(
        itemId: progressKey,
        currentTime: _totalDuration,
        duration: _totalDuration,
        speed: speed,
        isFinished: true,
      );
    }

    // Close the playback session (fire-and-forget)
    if (_playbackSessionId != null && _api != null) {
      final api = _api!;
      final sessionId = _playbackSessionId!;
      _logEvent(PlaybackEventType.sessionEnd, detail: 'book finished');
      unawaited(() async {
        try {
          debugPrint('[Player] Closing session (book finished)');
          await api.closePlaybackSession(sessionId);
        } catch (_) {}
      }());
    }

    // Notify LibraryProvider before clearing state so it can update isFinished locally.
    if (itemId != null) {
      final key = episodeId != null ? '$itemId-$episodeId' : itemId;
      if (_onBookFinishedCallback != null) {
        _onBookFinishedCallback!(key);
      } else {
        _pendingBookFinishedKey = key;
        debugPrint('[Player] Book-finished callback not registered, buffering key=$key');
      }
    }

    // Clear state (player already stopped at top of method)
    _clearState();
    _chapters = [];
    _handler?.updateChaptersQueue(const []);
    _isCompletingBook = false;
    notifyListeners();
  }

  Future<void> _saveProgressLocal(Duration pos) async {
    if (_currentItemId == null) return;
    final ct = pos.inMilliseconds / 1000.0;
    // Use compound key for podcast episodes
    final progressKey = _currentEpisodeId != null
        ? '$_currentItemId-$_currentEpisodeId'
        : _currentItemId!;
    await _progressSync.saveLocal(
      itemId: progressKey,
      currentTime: ct,
      duration: _totalDuration,
      speed: speed,
    );
    // _logEvent(PlaybackEventType.syncLocal); // too noisy for history
  }

  DateTime _lastServerSync = DateTime.now();
  bool _syncRecoveryInProgress = false;
  bool _positionSyncInProgress = false;
  int _positionSyncFailures = 0;

  Future<void> _syncToServer(Duration pos, {int? timeListenedOverride}) async {
    if (_api == null || _playbackSessionId == null) return;
    final ct = pos.inMilliseconds / 1000.0;
    final now = DateTime.now();
    final elapsed = timeListenedOverride ??
        now.difference(_lastServerSync).inSeconds.clamp(0, 300);
    _lastServerSync = now;
    // Alpha: volume/sessionId piggybacked for GH #179 (volume falls off).
    // We sample these on each sync tick so drift over time is visible.
    final vol = _player?.volume;
    final eqSid = _player?.androidAudioSessionId;
    debugPrint('[Player] Sync session ${_playbackSessionId!.substring(0, 8)}... | currentTime=${ct.toStringAsFixed(1)}s, timeListened=${elapsed}s, volume=$vol, eqSession=$eqSid');
    final ok = await _api!.syncPlaybackSession(
      _playbackSessionId!,
      currentTime: ct,
      duration: _totalDuration,
      timeListened: elapsed,
    );
    if (ok && elapsed > 0) {
      // Tick the StatsWidget forward locally so "today" stays fresh between
      // 15-min authoritative refreshes (which Android Doze throttles).
      unawaited(HomeWidgetService().addLocalListeningSeconds(elapsed));
    }
    if (ok) {
      _logEvent(PlaybackEventType.syncServer, detail: '+${elapsed}s');
    }
    if (!ok && !_syncRecoveryInProgress) {
      debugPrint('[Player] Session sync failed - attempting recovery');
      _syncRecoveryInProgress = true;
      try {
        await _recoverSession(ct, elapsed);
      } finally {
        _syncRecoveryInProgress = false;
      }
    }
  }

  /// Try to start a new server session when the current one becomes invalid.
  Future<void> _recoverSession(double currentTime, int lostTimeListened) async {
    if (_api == null || _currentItemId == null) return;
    try {
      final sessionData = _currentEpisodeId != null
          ? await _api!.startEpisodePlaybackSession(_currentItemId!, _currentEpisodeId!)
          : await _api!.startPlaybackSession(_currentItemId!);
      if (sessionData != null) {
        _playbackSessionId = sessionData['id'] as String?;
        debugPrint('[Player] Recovered session: $_playbackSessionId');
        _logEvent(PlaybackEventType.sessionStart, detail: 'recovery');
        // Re-sync the lost time to the new session
        if (_playbackSessionId != null && lostTimeListened > 0) {
          await _api!.syncPlaybackSession(
            _playbackSessionId!,
            currentTime: currentTime,
            duration: _totalDuration,
            timeListened: lostTimeListened,
          );
        }
      } else {
        debugPrint('[Player] Session recovery failed - no session returned');
        _playbackSessionId = null;
      }
    } catch (e) {
      debugPrint('[Player] Session recovery error: $e');
    }
  }

  DateTime? _lastPauseTime;
  double _lastAutoRewindAmount = 0;
  bool _seekedWhilePaused = false;
  bool _wasPlayingBeforeInterrupt = false;

  /// Auto-rewind calculation using linear scaling.
  /// Scales linearly from minRewind at activationDelay to maxRewind at 1 hour.
  /// activationDelay = minimum pause before rewind kicks in (0 = always).
  static double calculateAutoRewind(
      Duration pauseDuration, double minRewind, double maxRewind,
      {double activationDelay = 0}) {
    final pauseSeconds = pauseDuration.inSeconds.toDouble();

    // Don't rewind if pause is shorter than activation delay
    if (pauseSeconds < activationDelay) return 0;

    // Linear from min to max over 1 hour of pause time
    const maxPause = 3600.0; // 1 hour = full rewind
    final effectivePause = (pauseSeconds - activationDelay).clamp(0.0, maxPause);
    final t = effectivePause / maxPause;
    final rewind = minRewind + (maxRewind - minRewind) * t;
    return rewind.clamp(minRewind, maxRewind);
  }

  Future<void> play({String? logDetail}) async {
    debugPrint('[Service] play() called — lastPause=${_lastPauseTime != null}');

    // Cold-start play guard. If the OS killed absorb during a long pause
    // and the user tapped play via headphones / lock screen / Android Auto,
    // the handler routes play() into this service before any UI code has
    // had a chance to restore the last-played item. _currentItemId is null
    // here, so falling through to _player.play() fires on an empty player
    // and nothing happens. Route through the cold-start callback instead.
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;
    final decision = ColdStartPlayPolicy.decide(
      currentItemId: _currentItemId,
      lastPlayedItemId: prefs.getString('widget_item_id'),
    );
    if (decision == ColdStartPlayDecision.restoreLastPlayed) {
      debugPrint('[Service] play() on cold-started service - routing to cold-start restore');
      final restore = AudioPlayerService.onColdStartPlayRequested;
      if (restore != null) {
        unawaited(restore());
      } else {
        debugPrint('[Service] No cold-start restore handler registered - ignoring play');
      }
      return;
    }
    if (decision == ColdStartPlayDecision.nothing) {
      debugPrint('[Service] play() called with no current item and no history - ignoring');
      return;
    }

    _pauseStopTimer?.cancel();
    _pauseStopTimer = null;
    _noisyPause = false; // User explicitly resumed — allow interrupt-resume again
    _handler?._noisyPauseAt = null; // Clear noisy suppression window
    _lastAutoRewindAmount = 0;
    // Auto-rewind on resume if enabled
    if (_lastPauseTime != null && _player != null) {
      final settings = await AutoRewindSettings.load();
      if (settings.enabled) {
        final pauseDuration = DateTime.now().difference(_lastPauseTime!);
        final rewindSeconds = calculateAutoRewind(
            pauseDuration, settings.minRewind, settings.maxRewind,
            activationDelay: settings.activationDelay);
        if (rewindSeconds > 0.5) {
          final currentAbsolutePos = position.inMilliseconds / 1000.0;
          final currentSpeed = _player!.speed;
          var newPosSeconds = currentAbsolutePos - (rewindSeconds * currentSpeed);
          if (newPosSeconds < 0) newPosSeconds = 0;
          // Chapter barrier: don't rewind past the current chapter start
          if (settings.chapterBarrier && _chapters.isNotEmpty) {
            for (final ch in _chapters) {
              final start = (ch['start'] as num?)?.toDouble() ?? 0;
              final end = (ch['end'] as num?)?.toDouble() ?? 0;
              if (currentAbsolutePos >= start && currentAbsolutePos < end) {
                if (newPosSeconds < start) newPosSeconds = start;
                break;
              }
            }
          }
          await _seekAbsolute(newPosSeconds);
          // Store the actual book-time position delta, not raw rewindSeconds.
          // At speed>1.0 the delta is larger (rewindSeconds * speed), and the
          // chapter barrier above may cap it smaller. The "server ahead on
          // resume" check compares serverPos vs localPos+_lastAutoRewindAmount;
          // using raw seconds at 1.4x makes it misread a legitimate auto-rewind
          // gap as the server being ahead and seeks forward, erasing the rewind.
          final actualDelta = currentAbsolutePos - newPosSeconds;
          _lastAutoRewindAmount = actualDelta;
          final rewindDetail = currentSpeed == 1.0
              ? '${rewindSeconds.toStringAsFixed(1)}s'
              : '${rewindSeconds.toStringAsFixed(1)}s (${actualDelta.toStringAsFixed(1)}s at ${currentSpeed.toStringAsFixed(2)}x)';
          _logEvent(PlaybackEventType.autoRewind, detail: rewindDetail);
          debugPrint(
              '[Player] Auto-rewind ${rewindSeconds.toStringAsFixed(1)}s '
              '(paused ${pauseDuration.inSeconds}s)');
        }
      }
    }
    _lastPauseTime = null;
    // Reset server sync clock so the first sync after resume doesn't
    // include pause duration as timeListened
    _lastServerSync = DateTime.now();
    // Re-activate audio session (needed after pause timeout releases it)
    try { (await AudioSession.instance).setActive(true); } catch (_) {}
    // If the player is idle (source was disposed), we need to fully re-initialize
    // playback instead of just calling play() on an empty player.
    if (_player?.processingState == ProcessingState.idle && _currentItemId != null && _api != null) {
      debugPrint('[Player] Player is idle on resume - re-initializing playback for $_currentItemId');
      playItem(
        api: _api!,
        itemId: _currentItemId!,
        title: _currentTitle ?? '',
        author: _currentAuthor ?? '',
        coverUrl: _currentCoverUrl,
        totalDuration: _totalDuration,
        chapters: _chapters,
        episodeId: _currentEpisodeId,
        episodeTitle: _currentEpisodeTitle,
      );
      return;
    }
    // Start playback immediately — don't wait for server calls
    _player?.play();
    _scheduleAudioDiagnostics('resume');
    _logEvent(PlaybackEventType.play, detail: logDetail);
    _onPlaybackStateChangedCallback?.call(true);
    // Re-create server session and check progress in the background
    // so resume is instant instead of waiting for network round-trips
    _resumeServerSync();

    // Restart safety-net save timer (stopped on pause to avoid background wakes)
    if (_bgSaveTimer == null || !_bgSaveTimer!.isActive) {
      _bgSaveTimer?.cancel();
      _bgSaveTimer = Timer.periodic(const Duration(seconds: 300), (_) async {
        if (_currentItemId == null || _player == null || !_player!.playing) return;
        final pos = position;
        final posSec = pos.inMilliseconds / 1000.0;
        if (posSec <= 0) return;
        await _saveProgressLocal(pos);
      });
    }
    // Restart stuck detection (stopped on pause to avoid background wakes)
    if (_stuckCheckTimer == null || !_stuckCheckTimer!.isActive) {
      _startStuckDetection();
    }
    // Verify playback actually started — iOS USAC decoder can silently fail
    // after a seek, leaving the player in a non-playing state with no errors.
    _schedulePlayVerify();
    // Check auto sleep on every resume — catches window entry between pauses
    SleepTimerService().checkAutoSleep();
    notifyListeners();
  }

  /// Re-create server session and check if server progress is ahead.
  /// Runs in the background so play() returns instantly.
  void _resumeServerSync() async {
    if (_api == null || _currentItemId == null) return;
    final manualOffline = (_prefs ?? await SharedPreferences.getInstance())
        .getBool('manual_offline_mode') ?? false;
    if (manualOffline || _isOfflineMode) {
      debugPrint('[Player] Skipping session re-create on resume (manualOffline=$manualOffline, isOffline=$_isOfflineMode)');
      return;
    }
    // Skip server position override if user manually seeked while paused
    // (e.g. jumped to a different chapter) — respect the intentional seek.
    final skipOverride = _seekedWhilePaused;
    _seekedWhilePaused = false;
    try {
      if (_playbackSessionId == null) {
        // Session expired - re-create it
        final sessionData = _currentEpisodeId != null
            ? await _api!.startEpisodePlaybackSession(_currentItemId!, _currentEpisodeId!)
            : await _api!.startPlaybackSession(_currentItemId!);
        if (sessionData != null) {
          _playbackSessionId = sessionData['id'] as String?;
          debugPrint('[Player] Re-created session on resume: $_playbackSessionId');
          if (!skipOverride) {
            final serverPos = (sessionData['currentTime'] as num?)?.toDouble() ?? 0;
            final localPos = position.inMilliseconds / 1000.0;
            if (serverPos > localPos + _lastAutoRewindAmount + 5.0) {
              debugPrint('[Player] Server is ahead on resume: server=${serverPos}s vs local=${localPos}s - seeking');
              await _seekAbsolute(serverPos);
            }
          }
        }
      } else {
        // Session still active - check server progress in case another client advanced
        if (!skipOverride) {
          final pKey = _currentEpisodeId != null
              ? '$_currentItemId-$_currentEpisodeId'
              : _currentItemId!;
          final serverProgress = await _api!.getItemProgress(pKey);
          if (serverProgress != null) {
            final serverPos = (serverProgress['currentTime'] as num?)?.toDouble() ?? 0;
            final localPos = position.inMilliseconds / 1000.0;
            if (serverPos > localPos + _lastAutoRewindAmount + 5.0) {
              debugPrint('[Player] Server is ahead on resume: server=${serverPos}s vs local=${localPos}s - seeking');
              await _seekAbsolute(serverPos);
            }
          }
        }
      }
      _lastAutoRewindAmount = 0;
    } catch (e) {
      debugPrint('[Player] Failed to check server progress on resume: $e');
    }
  }

  Future<void> pause() async {
    debugPrint('[Service] pause() called');
    _playVerifyTimer?.cancel();
    _wasPlayingBeforeInterrupt = false;
    _lastPauseTime = DateTime.now();
    // Stamp BT-route observation for AA-disconnect phantom-click detection.
    // Fire-and-forget: pause shouldn't block on a native call.
    unawaited(_isBluetoothAudioConnected().then((bt) {
      if (bt) _lastPlayedOnBtAt = DateTime.now();
    }));
    // Stop timers to avoid background wakes while paused
    if (_bgSaveTimer != null) {
      _bgSaveTimer!.cancel();
      _bgSaveTimer = null;
    }
    if (_stuckCheckTimer != null) {
      _stuckCheckTimer!.cancel();
      _stuckCheckTimer = null;
    }
    await _player?.pause();
    _logEvent(PlaybackEventType.pause);
    _onPlaybackStateChangedCallback?.call(false);

    notifyListeners();
    final pos = position;
    debugPrint('[Player] Saving on pause: ${(pos.inMilliseconds / 1000.0).toStringAsFixed(1)}s');
    await _saveProgressLocal(pos);

    // Check manual offline before syncing
    final manualOffline = (_prefs ?? await SharedPreferences.getInstance())
        .getBool('manual_offline_mode') ?? false;
    if (manualOffline) return;

    if (!_isOfflineMode && _playbackSessionId != null) {
      await _syncToServer(pos);
    } else if (!_isOfflineMode && _currentItemId != null && _api != null) {
      final syncKey = _currentEpisodeId != null
          ? '$_currentItemId-$_currentEpisodeId'
          : _currentItemId!;
      _progressSync.syncToServer(api: _api!, itemId: syncKey);
    }

    // After 10 min paused, close the server session and release audio focus
    // to save battery/bandwidth. The player stays paused (not stopped) so the
    // MediaSession remains active and WearOS/notification controls keep working.
    _pauseStopTimer?.cancel();
    _pauseStopTimer = Timer(_pauseStopTimeout, () async {
      debugPrint('[Player] Pause timeout - releasing server session and audio focus');
      // Close server playback session. timeListened=0 because the user has
      // been paused for the whole pause-timeout window - the wall-clock diff
      // would otherwise inflate server listening stats by up to 300s.
      if (_playbackSessionId != null && _api != null) {
        _logEvent(PlaybackEventType.sessionEnd, detail: 'pause timeout');
        try {
          await _syncToServer(position, timeListenedOverride: 0);
          debugPrint('[Player] Closing session (pause timeout)');
          await _api!.closePlaybackSession(_playbackSessionId!);
        } catch (_) {}
        _playbackSessionId = null;
      }
      // Release audio focus so other apps can use it
      debugPrint('[Battery] AudioSession DEACTIVATED (pause timeout)');
      try { (await AudioSession.instance).setActive(false); } catch (_) {}
      // Cancel sleep timer
      if (SleepTimerService().isActive) {
        SleepTimerService().cancel();
      }
    });
  }

  Future<void> togglePlayPause() async {
    debugPrint('[Service] togglePlayPause() — isPlaying=$isPlaying');
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(Duration pos) async {
    _resetStuckDetection();
    if (_player != null && !_player!.playing) _seekedWhilePaused = true;
    final from = position;
    await _seekAbsolute(pos.inMilliseconds / 1000.0);
    _logEvent(PlaybackEventType.seek,
        detail: '${_formatPos(from)} → ${_formatPos(pos)}',
        overridePosition: from.inMilliseconds / 1000.0);
    notifyListeners();
  }

  Future<void> skipForward([int seconds = 30]) async {
    if (_player == null) return;
    _resetStuckDetection();
    if (!_player!.playing) _seekedWhilePaused = true;
    // Multiply by speed so the skip feels like the configured amount of real time
    final adjusted = (seconds * speed).round();
    debugPrint('[Service] skipForward(${seconds}s × ${speed}x = ${adjusted}s) — playing=${_player!.playing}');
    final newPos = position + Duration(seconds: adjusted);
    await _seekAbsolute(newPos.inMilliseconds / 1000.0);
    _logEvent(PlaybackEventType.skipForward, detail: '+${seconds}s (${adjusted}s @ ${speed}x)');
    debugPrint('[Service] skipForward done — playing=${_player!.playing}');
  }

  DateTime? _lastRewindChapterSnap;

  Future<void> skipBackward([int seconds = 10]) async {
    if (_player == null) return;
    _resetStuckDetection();
    if (!_player!.playing) _seekedWhilePaused = true;
    // Multiply by speed so the skip feels like the configured amount of real time
    final adjusted = (seconds * speed).round();
    final posS = position.inMilliseconds / 1000.0;
    final targetS = posS - adjusted;

    // Find current chapter start (gated by setting)
    final chapterBarrier = await PlayerSettings.getSkipChapterBarrier();
    if (chapterBarrier && _chapters.isNotEmpty) {
      double chapterStart = 0;
      for (int i = _chapters.length - 1; i >= 0; i--) {
        final s = (_chapters[i]['start'] as num?)?.toDouble() ?? 0;
        if (s <= posS + 0.5) { chapterStart = s; break; }
      }

      final intoChapter = posS - chapterStart;
      // If the rewind would cross the chapter boundary
      if (targetS < chapterStart && intoChapter > 0.5) {
        final now = DateTime.now();
        final recentSnap = _lastRewindChapterSnap != null &&
            now.difference(_lastRewindChapterSnap!).inMilliseconds < 2000;
        if (!recentSnap) {
          // Snap to chapter start instead of crossing
          _lastRewindChapterSnap = now;
          await _seekAbsolute(chapterStart);
          _logEvent(PlaybackEventType.skipBackward, detail: 'snap to chapter start');
          return;
        }
        // Double-tap within 2s - break through the barrier
        _lastRewindChapterSnap = null;
      }
    }

    var n = targetS < 0 ? 0.0 : targetS;
    await _seekAbsolute(n);
    _logEvent(PlaybackEventType.skipBackward, detail: '-${seconds}s (${adjusted}s @ ${speed}x)');
  }

  Future<void> skipToNextChapter() async {
    if (_player == null || _chapters.isEmpty) return;
    _resetStuckDetection();
    if (!_player!.playing) _seekedWhilePaused = true;
    final posS = position.inMilliseconds / 1000.0;
    for (int i = 0; i < _chapters.length; i++) {
      final start = (_chapters[i]['start'] as num?)?.toDouble() ?? 0;
      if (start > posS + 1.0) {
        debugPrint('[Service] skipToNextChapter → chapter $i at ${start}s');
        await _seekAbsolute(start);
        _logEvent(PlaybackEventType.seek, detail: 'next chapter');
        notifyListeners();
        return;
      }
    }
  }

  Future<void> skipToPreviousChapter() async {
    if (_player == null || _chapters.isEmpty) return;
    _resetStuckDetection();
    if (!_player!.playing) _seekedWhilePaused = true;
    final posS = position.inMilliseconds / 1000.0;
    // If more than 3s into current chapter, go to start of current chapter
    // Otherwise go to previous chapter
    for (int i = _chapters.length - 1; i >= 0; i--) {
      final start = (_chapters[i]['start'] as num?)?.toDouble() ?? 0;
      if (start < posS - 3.0) {
        debugPrint('[Service] skipToPreviousChapter → chapter $i at ${start}s');
        await _seekAbsolute(start);
        _logEvent(PlaybackEventType.seek, detail: 'prev chapter');
        notifyListeners();
        return;
      }
    }
    // If at the very start, seek to 0
    await _seekAbsolute(0);
    notifyListeners();
  }

  Future<void> setSpeed(double s) async {
    if (_player == null) return;
    debugPrint('[Service] setSpeed(${s}x) — before: ${_player!.speed}x');
    await _player!.setSpeed(s);
    debugPrint('[Service] setSpeed done — after: ${_player!.speed}x');
    _logEvent(PlaybackEventType.speedChange, detail: '${s.toStringAsFixed(2)}x');
    if (_currentItemId != null) {
      PlayerSettings.setBookSpeed(_currentItemId!, s);
      // Re-push MediaItem so the notification/AA duration updates for the
      // new speed (duration is divided by speed for speed-adjusted time).
      if (_handler != null) {
        final chTitle = currentChapter?['title'] as String?;
        _pushMediaItem(_mediaItemKey, _currentTitle ?? '', _currentAuthor ?? '',
            _currentCoverUrl, _totalDuration, chapter: chTitle);
      }
    }
    notifyListeners();
  }

  Map<String, dynamic>? get currentChapter {
    if (_chapters.isEmpty || _player == null) return null;
    final pos = position.inMilliseconds / 1000.0; // absolute book position
    for (final ch in _chapters) {
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? _totalDuration;
      if (pos >= start && pos < end) return ch as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> stop() async {
    _pauseStopTimer?.cancel();
    _pauseStopTimer = null;
    // Save final position locally
    if (_currentItemId != null) {
      final pos = position;
      debugPrint('[Player] Saving on stop: ${(pos.inMilliseconds / 1000.0).toStringAsFixed(1)}s');
      await _saveProgressLocal(pos);
    }

    // Check manual offline before syncing
    final manualOffline = (_prefs ?? await SharedPreferences.getInstance())
        .getBool('manual_offline_mode') ?? false;

    if (!manualOffline) {
      // Try server sync. If stop() was called while already paused, we were
      // not playing in the interval since the last sync - pass timeListened=0
      // so the wall-clock diff doesn't inflate server listening stats.
      if (_playbackSessionId != null && _api != null) {
        final wasPlaying = _player?.playing ?? false;
        _logEvent(PlaybackEventType.sessionEnd, detail: 'stop');
        await _syncToServer(position,
            timeListenedOverride: wasPlaying ? null : 0);
        try {
          debugPrint('[Player] Closing session (stop)');
          await _api!.closePlaybackSession(_playbackSessionId!);
        } catch (_) {}
      } else if (_currentItemId != null && _api != null) {
        await _progressSync.syncToServer(api: _api!, itemId: _currentItemId!);
      }
    }

    await _player?.stop();
    _onPlaybackStateChangedCallback?.call(false);

    _clearState();
    _chapters = [];
    _handler?.updateChaptersQueue(const []);
    // Cancel sleep timer when playback is stopped
    if (SleepTimerService().isActive) {
      SleepTimerService().cancel();
    }
    // Release audio focus so other apps can use it - but not during casting,
    // because deactivating the session can interfere with cast playback.
    if (!ChromecastService().isCasting) {
      debugPrint('[Battery] AudioSession DEACTIVATED (stop)');
      try { (await AudioSession.instance).setActive(false); } catch (_) {}
    }
  }

  /// Stop playback without saving progress — used by reset progress.
  Future<void> stopWithoutSaving() async {
    // Close server session without syncing position
    if (_playbackSessionId != null && _api != null) {
      try {
        debugPrint('[Player] Closing session (reset progress)');
        await _api!.closePlaybackSession(_playbackSessionId!);
      } catch (_) {}
    }
    await _player?.stop();
    _clearState();
    _chapters = [];
    _handler?.updateChaptersQueue(const []);
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _bgSaveTimer?.cancel();
    _pauseStopTimer?.cancel();
    _stuckCheckTimer?.cancel();
    _playVerifyTimer?.cancel();
    _indexSub?.cancel();
    _player?.dispose();
    super.dispose();
  }
}
