import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '_audio_player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'download_service.dart';
import 'offline_source.dart';
import 'playback_history_service.dart' hide PlaybackEvent;
import 'progress_sync_service.dart';
import 'local_session_service.dart';
import 'sync_logic.dart';
import 'sleep_timer_service.dart';
import 'equalizer_service.dart';
import 'external_audio_output_types.dart';
import 'android_auto_service.dart';
import 'chromecast_service.dart';
import 'chapter_lookup.dart';
import 'cold_start_play_policy.dart';
import 'playback_error_policy.dart';
import 'player_settings.dart';
import 'session_cache.dart';
import 'home_widget_service.dart';
import 'bookmark_service.dart';
import 'review_service.dart';
import '../utils/episode_key.dart';
export 'player_settings.dart';

String playbackDownloadKey(String itemId, String? episodeId) =>
    episodeKeyFor(itemId, episodeId);

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
      // iOS: disable AVPlayer's "wait for sustained playback guarantee" mode.
      // Default true makes AVPlayer set _player.rate = speed and only actually
      // start playing once iOS thinks stalls are unlikely. In foreground this
      // resolves instantly; in background after a fresh asset load, iOS never
      // grants that guarantee, so the new track stays state=buffering at
      // pos=0.0 forever even with hundreds of seconds buffered (GH #244).
      darwinLoadControl: DarwinLoadControl(
        automaticallyWaitsToMinimizeStalling: false,
      ),
    ),
  );
  AudioPlayerService? _service; // back-reference for auto-rewind

  // Cached skip amounts for notification icon selection (updated when settings change)
  int _cachedForwardSkip = 30;
  int _cachedBackSkip = 10;
  // Android: which pair fills the phone media player's two extra slots - speed +
  // bookmark (true) or chapter skip (false). Android Auto shows all of them
  // regardless. See PlayerSettings.getMediaControlsSpeedBookmark.
  bool _cachedNotifSpeedBookmark = false;
  // When true, the system scrubber is non-draggable (seek action dropped from
  // the playback state). See PlayerSettings.getLockSeekBar.
  bool _cachedLockSeekBar = false;

  AudioPlayer get player => _player;

  void bindService(AudioPlayerService service) => _service = service;

  // [AbsorbDiag] Channel for phantom-resume diagnostics (GH #243). Reads
  // statics from the vendored audio_service Java side via MainActivity.kt.
  // Strip the call sites + the channel once #243 is closed.
  static const _absorbDiagChannel = MethodChannel('com.absorb.audio_diag');

  /// Fetch the raw diag snapshot from the Java side. Returns null on iOS or
  /// when the channel is unavailable. Used by click() to also read the
  /// keycode for intent disambiguation, not just to log it.
  static Future<Map<String, dynamic>?> _absorbDiagSnapshot() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _absorbDiagChannel.invokeMapMethod<String, dynamic>(
        'snapshot',
      );
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('[AbsorbDiag] snapshot failed: $e');
      return null;
    }
  }

  static void _logAbsorbDiagFromSnapshot(
    String tag,
    Map<String, dynamic>? snap,
  ) {
    if (snap == null) return;
    debugPrint(
      '[AbsorbDiag] $tag: '
      'keyCode=${snap['lastKeyCode']} keyAgeMs=${snap['lastKeyAgeMs']} '
      'lastPlayCaller=${snap['lastPlayCaller']} playAgeMs=${snap['lastPlayCallerAgeMs']} '
      'lastPauseCaller=${snap['lastPauseCaller']} pauseAgeMs=${snap['lastPauseCallerAgeMs']} '
      'carClientAgeMs=${snap['carClientAgeMs']}',
    );
  }

  static Future<void> _logAbsorbDiag(String tag) async {
    _logAbsorbDiagFromSnapshot(tag, await _absorbDiagSnapshot());
  }

  /// How long after a car client (Android Auto / Automotive) last touched the
  /// browse tree we still assume a car is attached. Long enough to span a
  /// drive where the head unit connected once and never browsed again, short
  /// enough that a headset press hours after the drive is taken at face value.
  static const _carClientWindow = Duration(hours: 2);

  /// Whether a car client has touched the media browse tree recently, per the
  /// Java-side stamp. The MEDIA_PAUSE-while-paused phantom (GH #243) only
  /// exists on Android Auto, so this is what decides whether the click
  /// resolver suppresses that keycode or honors it as a headset toggle.
  /// Snapshot missing (iOS, channel unavailable) reads as no car.
  static Future<bool> _carClientRecentlySeen() async {
    final snap = await _absorbDiagSnapshot();
    final age = snap?['carClientAgeMs'];
    final seen =
        age is int && age >= 0 && age < _carClientWindow.inMilliseconds;
    debugPrint(
      '[Handler] car client ${seen ? 'seen' : 'not seen'} (carClientAgeMs=$age)',
    );
    return seen;
  }

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
    // One line per ExoPlayer state transition (playerStateStream is already
    // distinct). Tells "the app paused it" apart from "the audio pipeline
    // stalled": a play/pause blip the app caused shows up as playing flips
    // next to a Handler/Service/AudioSession line, a rebuffer shows as
    // ready -> buffering -> ready, and a BT-link hiccup shows nothing here.
    _player.playerStateStream.listen((s) {
      debugPrint(
        '[PlayerState] playing=${s.playing} state=${s.processingState.name} '
        'pos=${(_player.position.inMilliseconds / 1000).toStringAsFixed(2)}s',
      );
    });
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

  // Brief "Saved" flash on the Android Auto bookmark button after a save.
  bool _bookmarkSavedFlash = false;
  Timer? _bookmarkFlashTimer;

  // Keep the media session in buffering while a queued item is taking over.
  // Android maps AudioProcessingState.loading to STATE_CONNECTING, which does
  // not show the buffering animation used for an in-progress media load.
  bool _advanceBuffering = false;
  DateTime? _advanceBufferingUntil;
  Timer? _advanceBufferingMinimumTimer;

  void setAdvanceBuffering(
    bool value, {
    Duration minimumDuration = Duration.zero,
  }) {
    _advanceBufferingMinimumTimer?.cancel();
    _advanceBufferingMinimumTimer = null;
    final changed = _advanceBuffering != value;
    _advanceBuffering = value;
    _advanceBufferingUntil = value ? DateTime.now().add(minimumDuration) : null;
    if (value) _clearAdvanceBufferingIfReady();
    if (!changed && !value) return;
    refreshPlaybackState();
  }

  void _clearAdvanceBufferingIfReady({bool refresh = true}) {
    if (!_advanceBuffering ||
        _player.processingState != ProcessingState.ready) {
      return;
    }
    final remaining =
        _advanceBufferingUntil?.difference(DateTime.now()) ?? Duration.zero;
    if (remaining > Duration.zero) {
      _advanceBufferingMinimumTimer?.cancel();
      _advanceBufferingMinimumTimer = Timer(remaining, () {
        _advanceBufferingMinimumTimer = null;
        _clearAdvanceBufferingIfReady();
      });
      return;
    }
    _advanceBuffering = false;
    _advanceBufferingUntil = null;
    if (refresh) refreshPlaybackState();
  }

  void _subscribePlaybackEvents() {
    _player.playbackEventStream.listen(
      (event) {
        _clearAdvanceBufferingIfReady(refresh: false);
        final state = _transformEvent(event);
        // Only push state on meaningful changes (play/pause, processing state)
        // or at most every 5 seconds for position updates
        final now = DateTime.now();
        final playingChanged = _player.playing != _lastPlaying;
        final processingChanged =
            _player.processingState != _lastProcessingState;
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
        if (PlaybackErrorPolicy.isSourceError(e)) {
          debugPrint(
            '[Player] playbackEvent source error - restarting stream: $e',
          );
          AudioPlayerService()._attemptStreamRetry(e);
          return;
        }

        final now = DateTime.now();
        // Reset counter if it's been more than 5 seconds since last error
        if (now.difference(_lastResubscribe).inSeconds > 5) {
          _resubscribeCount = 0;
        }
        _lastResubscribe = now;
        _resubscribeCount++;

        if (_resubscribeCount <= 3) {
          debugPrint(
            '[Player] playbackEvent error ($_resubscribeCount/3) - re-subscribing: $e',
          );
          refreshPlaybackState();
          Future.delayed(const Duration(seconds: 1), _subscribePlaybackEvents);
        } else {
          debugPrint(
            '[Player] playbackEvent error - too many rapid failures, stopping re-subscribe: $e',
          );
          if (PlaybackErrorPolicy.shouldRetryWithTranscode(e)) {
            AudioPlayerService()._retryWithTranscode();
          }
        }
      },
      onDone: () {
        _resubscribeCount++;
        if (_resubscribeCount <= 3) {
          debugPrint(
            '[Player] playbackEvent stream completed ($_resubscribeCount/3) - re-subscribing',
          );
          refreshPlaybackState();
          Future.delayed(const Duration(seconds: 1), _subscribePlaybackEvents);
        } else {
          debugPrint(
            '[Player] playbackEvent stream completed - too many rapid re-subscribes, stopping',
          );
        }
      },
    );
  }

  // The Android Auto speed button shows a pre-baked badge for the current rate.
  // We snap to the nearest 0.05 within the baked range (0.5x..3.0x); every step
  // has a generated ic_speed_*x drawable (rendered from Roboto Bold).
  String _speedBadgeIcon() {
    final speed = _service?.speed ?? _player.speed;
    var rate = (speed * 20).round() / 20; // nearest 0.05
    if (rate < 0.5) rate = 0.5;
    if (rate > 3.0) rate = 3.0;
    // 1.0 -> "1x", 1.2 -> "1_2x", 1.25 -> "1_25x" (matches the generated files).
    final s = rate
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return 'drawable/ic_speed_${s.replaceAll('.', '_')}x';
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

    // Base 3 controls (rewind | play | forward) feed both the phone
    // notification and Android Auto. compactIndices keeps the glanceable
    // notification to just these three.
    final controls = <MediaControl>[
      rewindControl,
      playPause,
      fastForwardControl,
    ];
    final compactIndices = const [0, 1, 2];

    // Extra Android Auto controls (custom actions). On Android 12 and below they
    // show only in AA; on 13+ they also feed the phone's media player. We always
    // add the chapter buttons - they no-op when the item has no chapters - which
    // (a) keeps the layout identical for books and podcasts and (b) since the
    // phone player caps at 5 buttons, makes the two chapter buttons push speed +
    // bookmark to AA-only for every item type. iOS uses the CarPlay Now Playing
    // buttons instead, so these are never added on iOS (lock screen stays as-is).
    if (Platform.isAndroid) {
      final prevChapter = MediaControl.custom(
        androidIcon: 'drawable/ic_widget_prev_chapter',
        label: 'Previous chapter',
        name: 'previousChapter',
      );
      final nextChapter = MediaControl.custom(
        androidIcon: 'drawable/ic_widget_next_chapter',
        label: 'Next chapter',
        name: 'nextChapter',
      );
      final speed = MediaControl.custom(
        androidIcon: _speedBadgeIcon(),
        label: 'Speed',
        name: 'cycleSpeed',
      );
      // Bookmark icon/label briefly flip to a checkmark + "Saved" after a save,
      // as on-screen confirmation for Android Auto (the CarPlay banner equivalent).
      final bookmark = MediaControl.custom(
        androidIcon: _bookmarkSavedFlash
            ? 'drawable/ic_check'
            : 'drawable/ic_bookmark',
        label: _bookmarkSavedFlash ? 'Saved' : 'Bookmark',
        name: 'bookmark',
      );
      // The phone media player (Android 13+) only shows the first 2 of these
      // extras (after rewind/forward); the rest stay Android-Auto-only. Order so
      // the user's chosen pair lands on the phone. Default: chapter skip.
      if (_cachedNotifSpeedBookmark) {
        controls.addAll([speed, bookmark, prevChapter, nextChapter]);
      } else {
        controls.addAll([prevChapter, nextChapter, speed, bookmark]);
      }
    }

    return PlaybackState(
      controls: controls,
      // iOS-only: declaring on Android adds prev/next buttons to the notification.
      systemActions: {
        // Dropping seek locks the scrubber: Android omits ACTION_SEEK_TO and iOS
        // omits changePlaybackPositionCommand, so it shows progress but can't be
        // dragged. The skip (rewind/forward) buttons stay functional.
        if (!_cachedLockSeekBar) MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToQueueItem,
        if (Platform.isIOS) MediaAction.skipToNext,
        if (Platform.isIOS) MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: compactIndices,
      processingState: () {
        final mapped = const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!;
        if (_advanceBuffering) return AudioProcessingState.buffering;
        return mapped;
      }(),
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
    debugPrint(
      '[Handler] play() called - routing to service (state=${_player.processingState.name})',
    );
    await _logAbsorbDiag('play');
    final entryBt = await AudioPlayerService._isBluetoothAudioConnected();
    if (entryBt) AudioPlayerService._lastPlayedOnBtAt = DateTime.now();
    debugPrint(
      '[ClickDebug] play() entry: ${_clickDebugSnapshot(btNow: entryBt)}',
    );
    // Mirror the click() guard: a raw play() arriving within 5s of a
    // headphone/AA/BT disconnect is almost always the platform echoing a
    // resume command, not the user. Drop it so playback doesn't jump to
    // the phone speaker after the user unplugs or AA tears down.
    if (_noisyPauseAt != null) {
      final elapsed = DateTime.now().difference(_noisyPauseAt!).inMilliseconds;
      if (elapsed < 5000) {
        debugPrint(
          '[Handler] Ignoring phantom play (${elapsed}ms after platform pause)',
        );
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
    _service?._markPauseRequested();
    debugPrint('[Handler] pause() called - routing to service');
    await _logAbsorbDiag('pause');
    final pauseEntryBt = await AudioPlayerService._isBluetoothAudioConnected();
    debugPrint(
      '[ClickDebug] pause() entry: ${_clickDebugSnapshot(btNow: pauseEntryBt)}',
    );
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
    // Detect BT/AA disconnect by route change: we were playing on BT recently
    // and BT is no longer connected at this pause. Arm the 5s phantom guard
    // so any echoed resume command from the dead route gets dropped. We do
    // NOT stamp for plain user pauses (notification, lock screen, in-app)
    // because that would block their immediate follow-up play. becomingNoisy
    // covers the headphone-unplug path independently.
    if (!_inClickResolver) {
      final lastBt = AudioPlayerService._lastPlayedOnBtAt;
      final btJustWent = lastBt != null && !pauseEntryBt;
      if (btJustWent) {
        _noisyPauseAt = DateTime.now();
      }
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
    debugPrint(
      '[Handler] stop() - keeping MediaSession alive '
      '(playing=${_player.playing}, processingState=${_player.processingState.name}, '
      'hasService=${_service != null})',
    );
    debugPrint('[Handler] stop() trace:\n${StackTrace.current}');
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('[Handler] stop() player.stop error: $e');
    }
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
    final skipAmount = await PlayerSettings.getEffectiveForwardSkip(
      libraryId: _service?.currentLibraryId,
    );
    debugPrint(
      '[SkipDebug] fastForward: lib=${_service?.currentLibraryId} amount=${skipAmount}s',
    );
    if (_service != null) {
      await _service!.skipForward(skipAmount);
    } else {
      final adjusted = (skipAmount * _player.speed).round();
      await _player.seek(_player.position + Duration(seconds: adjusted));
    }
  }

  @override
  Future<void> rewind() async {
    debugPrint('[Handler] rewind() - seeking back');
    final skipAmount = await PlayerSettings.getEffectiveBackSkip(
      libraryId: _service?.currentLibraryId,
    );
    debugPrint(
      '[SkipDebug] rewind: lib=${_service?.currentLibraryId} amount=${skipAmount}s',
    );
    if (_service != null) {
      await _service!.skipBackward(skipAmount);
    } else {
      final adjusted = (skipAmount * _player.speed).round();
      var pos = _player.position - Duration(seconds: adjusted);
      if (pos < Duration.zero) pos = Duration.zero;
      await _player.seek(pos);
    }
  }

  // iOS BT (AirPods, steering wheel) routes track-skip through these.
  @override
  Future<void> skipToNext() => fastForward();

  @override
  Future<void> skipToPrevious() => rewind();

  // Custom click handler with proper multi-press detection
  Timer? _clickTimer;
  int _clickCount = 0;
  DateTime? _hardwareButtonTime; // cooldown after hardware next/prev
  DateTime? _noisyPauseAt; // suppress clicks for a window after BT disconnect
  // Keycode of the media button event that arrived at the most recent click().
  // Read from the [AbsorbDiag] snapshot at click arrival and consumed by the
  // 400ms resolver to honor PAUSE/PLAY intent instead of blindly toggling -
  // Android Auto sends KEYCODE_MEDIA_PAUSE when the user switches to Radio,
  // and the old toggle path bounced it back as a phantom resume (GH #243).
  int? _lastClickKeyCode;
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
      sinceForegroundMs = now
          .difference(AudioPlayerService._lastForegroundAt!)
          .inMilliseconds;
    }
    int sinceNoisyPauseMs = -1;
    if (_noisyPauseAt != null) {
      sinceNoisyPauseMs = now.difference(_noisyPauseAt!).inMilliseconds;
    }
    final backgrounded = _service?.isBackgrounded;
    // Variant-3 fingerprint: raw pause fires within 5s of a click-initiated
    // play while still playing in background. Flag it so the pause log line
    // is self-describing without having to cross-reference timestamps.
    final phantomSuspect =
        sincePrevPlayMs >= 0 &&
        sincePrevPlayMs < 5000 &&
        _player.playing &&
        (backgrounded ?? false);
    // AA-disconnect fingerprint: BT/AA was the audio route within the last
    // 10 min, isn't anymore, and the click came in while bg + not playing.
    int sinceBtMs = -1;
    final lastBt = AudioPlayerService._lastPlayedOnBtAt;
    if (lastBt != null) sinceBtMs = now.difference(lastBt).inMilliseconds;
    final String aaDisconnect;
    if (btNow == null) {
      aaDisconnect = 'unknown';
    } else {
      final fired =
          lastBt != null && !btNow && sinceBtMs >= 0 && sinceBtMs < 600000;
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
    debugPrint(
      '[Handler] click(button=$button) count=${_clickCount + 1} playing=${_player.playing}',
    );
    final diagSnap = await _absorbDiagSnapshot();
    _logAbsorbDiagFromSnapshot('click', diagSnap);
    // Pre-fetch BT-route state so the snapshot can fill in the AA-disconnect
    // heuristic and the suppression branch below has a value to test against.
    final btNow = await AudioPlayerService._isBluetoothAudioConnected();
    final snapshot = _clickDebugSnapshot(btNow: btNow);
    debugPrint('[ClickDebug] click arrival (button=$button): $snapshot');
    _service?._logEvent(
      PlaybackEventType.clickDebounce,
      detail: 'button=$button | $snapshot',
    );

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
      final elapsed = DateTime.now()
          .difference(_hardwareButtonTime!)
          .inMilliseconds;
      if (elapsed < 500) {
        debugPrint(
          '[Handler] Ignoring phantom media click (${elapsed}ms after hardware button)',
        );
        _hardwareButtonTime = null;
        return;
      }
      _hardwareButtonTime = null;
    }

    // Suppress phantom play commands within 5s of a BT/auto disconnect
    if (_noisyPauseAt != null) {
      final elapsed = DateTime.now().difference(_noisyPauseAt!).inMilliseconds;
      if (elapsed < 5000) {
        debugPrint(
          '[Handler] Ignoring phantom click (${elapsed}ms after noisy pause)',
        );
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
        debugPrint(
          '[Handler] Ignoring phantom click after AA/BT disconnect '
          '(${ageMs}ms since last BT-on, btNow=false, bg=true, playing=false)',
        );
        _service?._logEvent(
          PlaybackEventType.clickDebounce,
          detail: 'phantom AA/BT click suppressed | sinceBtMs=$ageMs',
        );
        // Re-arm the 5s noisy guard so a follow-up click in the same
        // burst is also ignored, matching the BT-disconnect suppression flow.
        _noisyPauseAt = DateTime.now();
        return;
      }
    }

    // Stash the keycode for the resolver if it belongs to this click. Only
    // do this for clicks that actually count - early-return guards above
    // skip the stash so they can't poison the keycode of a click that does
    // make it to the resolver. 500ms cap is a safety margin; typical
    // keyAgeMs from the Java side is 0-2ms.
    if (diagSnap != null) {
      final age = diagSnap['lastKeyAgeMs'];
      final kc = diagSnap['lastKeyCode'];
      if (age is int && age >= 0 && age < 500 && kc is int && kc != 0) {
        _lastClickKeyCode = kc;
      }
    }

    _clickCount++;
    _clickTimer?.cancel();
    _clickTimer = Timer(const Duration(milliseconds: 400), () async {
      final count = _clickCount;
      _clickCount = 0;
      debugPrint(
        '[Handler] click resolved: count=$count playing=${_player.playing}',
      );
      final resolveBt = await AudioPlayerService._isBluetoothAudioConnected();
      debugPrint(
        '[ClickDebug] click resolve (count=$count): ${_clickDebugSnapshot(btNow: resolveBt)}',
      );
      switch (count) {
        case 1:
          // Sleep-timer snooze (GH #333): during the wind-down window a
          // single press resets the timer instead of pausing. Sits after all
          // the phantom guards so a spurious AA/BT click can't reset it, and
          // inside the resolver so double/triple presses still skip.
          if (await SleepTimerService().snoozeFromMediaButton()) {
            _lastClickKeyCode = null;
            debugPrint('[Handler] → single press consumed by sleep timer snooze');
            break;
          }
          _inClickResolver = true;
          try {
            // Honor the actual keycode the system dispatched when we can.
            // audio_service collapses MEDIA_PLAY / MEDIA_PAUSE / PLAY_PAUSE /
            // HEADSETHOOK all into MediaButton.media, but Android Auto sends
            // MEDIA_PAUSE specifically when the user switches to another media
            // app - blindly toggling there resumes us right after we paused
            // (GH #243). For the unambiguous play / pause keycodes, follow the
            // intent. PLAY_PAUSE / HEADSETHOOK / unknown / stale stay as
            // toggles so single-button BT remotes keep working.
            const keycodeMediaPlay = 126;
            const keycodeMediaPause = 127;
            final kc = _lastClickKeyCode;
            _lastClickKeyCode = null;
            if (kc == keycodeMediaPause) {
              if (_player.playing) {
                debugPrint('[Handler] → single press (MEDIA_PAUSE) → PAUSE');
                await pause();
              } else if (await _carClientRecentlySeen()) {
                debugPrint(
                  '[Handler] -> single press (MEDIA_PAUSE while paused) -> no-op (suppressed phantom toggle to PLAY, car client seen)',
                );
              } else {
                // Some BT headsets (Shokz seen in the wild) send MEDIA_PAUSE
                // for a play press when their idea of our state went stale.
                // Without a car around there is no #243 phantom to guard
                // against, so treat it as the toggle the user meant.
                debugPrint(
                  '[Handler] -> single press (MEDIA_PAUSE while paused, no car client) -> PLAY',
                );
                await play();
              }
            } else if (kc == keycodeMediaPlay) {
              if (!_player.playing) {
                debugPrint('[Handler] → single press (MEDIA_PLAY) → PLAY');
                await play();
              } else {
                debugPrint(
                  '[Handler] → single press (MEDIA_PLAY while playing) → no-op',
                );
              }
            } else if (_player.playing) {
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
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    debugPrint('[Handler] customAction($name)');
    switch (name) {
      case 'nextChapter':
        if (_service != null) await _service!.skipToNextChapter();
        break;
      case 'previousChapter':
        if (_service != null) await _service!.skipToPreviousChapter();
        break;
      case 'cycleSpeed':
        await _cycleSpeed();
        break;
      case 'bookmark':
        return await _bookmarkCurrentPosition();
    }
  }

  /// Step playback speed up to the next configured preset, wrapping back to the
  /// slowest once past the top. Used by the CarPlay / Android Auto speed button.
  Future<void> _cycleSpeed() async {
    final presets = await PlayerSettings.getSpeedPresets();
    if (presets.isEmpty) return;
    final cur = _service?.speed ?? _player.speed;
    var next = presets.first; // wrap to slowest when already at/above the top
    for (final p in presets) {
      if (p > cur + 0.001) {
        next = p;
        break;
      }
    }
    if (_service != null) {
      await _service!.setSpeed(next);
    } else {
      await setSpeed(next);
    }
  }

  /// Save a bookmark at the current position, mirroring the in-app car-mode
  /// button (chapter title as the label, pushed to the server via the API).
  /// A podcast episode is bookmarked under its own key, which keeps it on the
  /// device - ABS bookmarks have nowhere to put an episode id.
  Future<bool> _bookmarkCurrentPosition() async {
    final svc = _service;
    if (svc == null) return false;
    final itemId = svc.currentItemId;
    if (itemId == null) return false;
    final pos = svc.position.inMilliseconds / 1000.0;
    final chTitle = svc.currentChapter?['title'] as String?;
    await BookmarkService().addBookmark(
      itemId: playbackDownloadKey(itemId, svc.currentEpisodeId),
      positionSeconds: pos,
      title: (chTitle != null && chTitle.isNotEmpty) ? chTitle : 'Bookmark',
      api: svc.currentApi,
    );
    if (Platform.isAndroid) {
      // Flash a checkmark on the Android Auto bookmark button for ~2s. iOS gets
      // its confirmation via the CarPlay banner instead.
      _bookmarkSavedFlash = true;
      refreshPlaybackState();
      _bookmarkFlashTimer?.cancel();
      _bookmarkFlashTimer = Timer(const Duration(seconds: 2), () {
        _bookmarkSavedFlash = false;
        refreshPlaybackState();
      });
    }
    return true;
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
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
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
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    debugPrint('[Handler] search("$query")');
    return _autoService.search(query);
  }

  @override
  Future<void> prepareFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    debugPrint('[Handler] prepareFromMediaId($mediaId)');
    await _playFromAutoMediaId(mediaId);
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
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
        debugPrint(
          '[Handler] Item not in AA cache but downloaded locally: $absId',
        );
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
          libraryId: dl.libraryId,
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
                libraryId: response['libraryId'] as String?,
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
              libraryId: response['libraryId'] as String?,
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

    debugPrint(
      '[Handler] Android Auto play: "${entry.title}" by ${entry.author}',
    );

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
      libraryId: entry.libraryId,
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

  // Pre-buffer callback. AudioPlayerService asks LibraryProvider for the next
  // manual-queue item ~15s before current ends, so the next AVQueuePlayer item
  // is already in the queue when the current one finishes. iOS auto-advances
  // natively (no fresh setAudioSource in background, so iOS keeps granting
  // audio output). The map must contain at least: itemId, title, author,
  // duration, and either localPaths or audioTracks.
  static Future<Map<String, dynamic>?> Function(String currentItemId)?
  _onPeekNextItemCallback;
  static void setOnPeekNextItemCallback(
    Future<Map<String, dynamic>?> Function(String)? cb,
  ) {
    _onPeekNextItemCallback = cb;
  }

  // Fired when the AVQueuePlayer natively auto-advances from the current item
  // to a pre-buffered next item. LibraryProvider uses this to mark the old
  // item finished WITHOUT triggering its normal auto-advance flow (which would
  // call playItem and rebuild the source, defeating the pre-buffer).
  static void Function(String oldItemId)? _onAutoQueueAdvancedCallback;
  static void setOnAutoQueueAdvancedCallback(void Function(String)? cb) {
    _onAutoQueueAdvancedCallback = cb;
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
      debugPrint(
        '[Player] Dropping stale book-finished drain (player has item=$loaded, buffered key=$pending)',
      );
      return;
    }

    debugPrint('[Player] Draining buffered book-finished key=$pending');
    cb(pending);
  }

  /// Called when a new item starts playing. Used by LibraryProvider to trigger
  /// rolling downloads for the next items in a series/podcast.
  static Future<void> Function(String key, double duration)?
      _onPlayStartedCallback;
  static void setOnPlayStartedCallback(
    Future<void> Function(String key, double duration)? cb,
  ) {
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
  static void setOnPlaybackStateChangedCallback(
    void Function(bool isPlaying)? cb,
  ) {
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
  // The item's metadata duration as passed to playItem. _totalDuration gets
  // replaced by the playback session's track-sum once a stream opens, and the
  // two can disagree by minutes when the server's metadata is off - but the
  // in-app cards display the metadata number, so time surfaces that need to
  // match them (the iOS widget) read this instead.
  double _metaDuration = 0;
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

  /// True while the current play started from downloaded files and is reporting
  /// to the server via the client-owned LOCAL session model (GH #276/#280)
  /// instead of a live `/play` session. Position still syncs via /me/progress.
  bool _localSessionMode = false;

  // Set when a loadOnly playItem skipped starting the local session; the
  // first real play() begins it, so listening time still gets recorded.
  ({
    String progressKey,
    String itemId,
    String? episodeId,
    double duration,
    String title,
    String author,
  })? _pendingLoadOnlySession;

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
  StreamSubscription? _nativeAutoAdvanceSub;

  // ── Pre-buffer next book in queue (iOS background auto-advance fix) ──
  // iOS denies background audio output to freshly-loaded AVPlayerItems.
  // Workaround: append the next book to the live ConcatenatingAudioSource
  // ~15s before current ends. AVQueuePlayer auto-advances natively, audio
  // engine stays continuous, iOS keeps granting output.
  ConcatenatingAudioSource? _activeConcatSource;
  int _currentBookTrackCount = 0;
  bool _nextBookPreloading = false;
  Map<String, dynamic>? _preloadedNextBook;
  bool _autoQueueAdvancing = false;
  Timer? _bgSaveTimer;
  Timer? _advanceBufferingBackstop;
  Timer? _pauseStopTimer;
  static const _pauseStopTimeout = Duration(minutes: 10);
  // A streamed book's cover isn't in the content-provider cache on first play,
  // so the notification's first art request races the on-demand fetch and the
  // OS caches the empty result against the fixed cover URI. We re-push the
  // MediaItem once with a cache-busting URI so the OS re-requests it after the
  // cover has been fetched. Tracks the item already scheduled for this.
  String? _coverRepushItem;
  Timer? _coverRepushTimer;

  void _beginAdvanceBuffering() {
    if (!Platform.isAndroid) return;
    _handler?.setAdvanceBuffering(
      true,
      minimumDuration: const Duration(milliseconds: 900),
    );
    _advanceBufferingBackstop?.cancel();
    _advanceBufferingBackstop = Timer(const Duration(seconds: 30), () {
      _advanceBufferingBackstop = null;
      _handler?.setAdvanceBuffering(false);
    });
  }

  void _endAdvanceBuffering() {
    if (!Platform.isAndroid) return;
    _advanceBufferingBackstop?.cancel();
    _advanceBufferingBackstop = null;
    _handler?.setAdvanceBuffering(false);
  }

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

  // When a downloaded file decodes shorter than the book's metadata duration
  // (an incomplete or corrupt download), this holds the real playable length
  // in seconds. Seeks are clamped to it, and the truncation-end position is
  // never saved over a further-along stored position. null = file looks fine.
  // GH #278: a half-downloaded book otherwise clamped every resume back to the
  // file's end (50% of the book) and saved that over the user's real progress.
  double? _shortLocalDurationSec;
  // Ignore small encoder/container rounding when comparing decoded vs metadata.
  static const double _kLocalTruncationMarginSec = 60.0;
  int _lastNotifiedChapterIndex = -1;
  int _lastChapterCheckSec = -1;
  StreamSubscription? _indexSub;

  // ── iOS premature-completion guard (GH #219) ──
  // ConcatenatingAudioSource on iOS sometimes fires ProcessingState.completed
  // when advancing to the LAST item without actually rendering its audio,
  // making books appear to "skip" the final chapter. We watch how recently
  // _currentTrackIndex flipped to the last track; if completion fires within
  // a few seconds of that advance for a substantial last track, treat it as
  // spurious and seek-resume into the last track. Capped to prevent loops
  // if recovery itself can't get the player unstuck.
  DateTime? _lastIndexAdvanceTime;
  int _iosLastTrackRecoveryAttempts = 0;
  static const _maxIosLastTrackRecoveries = 2;

  // Force one lock-screen state push after an intra-book track advance.
  bool _pendingTrackAdvanceRefresh = false;

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
        _pushMediaItem(
          _mediaItemKey,
          _currentTitle ?? '',
          _currentAuthor ?? '',
          _currentCoverUrl,
          _totalDuration,
          chapter: _lastNotifiedChapterIndex >= 0 && _chapters.isNotEmpty
              ? (_chapters[_lastNotifiedChapterIndex]
                        as Map<String, dynamic>)['title']
                    as String?
              : null,
        );
        _handler?.refreshPlaybackState();
      }
    });
    // Update cached skip amounts so notification icons stay in sync
    _syncNotifSkipCache();
    PlayerSettings.getMediaControlsSpeedBookmark().then((v) {
      if (_handler != null && v != _handler!._cachedNotifSpeedBookmark) {
        _handler!._cachedNotifSpeedBookmark = v;
        _handler!.refreshPlaybackState();
      }
    });
    PlayerSettings.getLockSeekBar().then((v) {
      if (_handler != null && v != _handler!._cachedLockSeekBar) {
        _handler!._cachedLockSeekBar = v;
        _handler!.refreshPlaybackState();
      }
    });
    if (Platform.isAndroid) {
      PlayerSettings.getDuckBriefInterruptions().then((v) async {
        if (v == _duckBriefInterruptions) return;
        final previousVolume = _volumeBeforeInterruptionDuck;
        _volumeBeforeInterruptionDuck = null;
        _clearDuckWatchdog();
        if (previousVolume != null) {
          await _player?.setVolume(previousVolume);
        }
        await _configureAudioSession();
      });
    }
  }

  static const _playerCoreChannel = MethodChannel('com.absorb.player_core');
  static const _audioServiceClientChannel = MethodChannel(
    'com.ryanheise.audio_service.client.methods',
  );

  /// Point the iOS lock screen skip buttons at [forward] / [backward] seconds.
  /// Unlike Android, iOS doesn't ask how far to skip on each press - it reads
  /// the amounts off MPRemoteCommandCenter, which audio_service writes once at
  /// startup and the native core armed with the defaults, so changing the
  /// setting never reached the lock screen. Tell both, since they write the
  /// same properties and whoever goes last wins.
  static Future<void> _pushIosSkipIntervals(int forward, int backward) async {
    try {
      await _playerCoreChannel.invokeMethod('setSkipIntervals', {
        'forward': forward,
        'backward': backward,
      });
    } catch (e) {
      debugPrint('[SkipDebug] native core setSkipIntervals failed: $e');
    }
    try {
      await _audioServiceClientChannel.invokeMethod('updateSkipIntervals', {
        'fastForwardInterval': forward * 1000,
        'rewindInterval': backward * 1000,
      });
    } catch (e) {
      debugPrint('[SkipDebug] audio_service updateSkipIntervals failed: $e');
    }
  }

  /// Refresh the notification's cached skip labels with the amounts for the
  /// current library. Called on settings changes and whenever the loaded
  /// item changes.
  void _syncNotifSkipCache() {
    final libId = _currentLibraryId;
    final fwdFuture = PlayerSettings.getEffectiveForwardSkip(libraryId: libId);
    final backFuture = PlayerSettings.getEffectiveBackSkip(libraryId: libId);
    fwdFuture.then((v) {
      debugPrint(
        '[SkipDebug] notif cache: lib=$libId fwd=${v}s (was ${_handler?._cachedForwardSkip})',
      );
      if (_handler != null && v != _handler!._cachedForwardSkip) {
        _handler!._cachedForwardSkip = v;
        _handler!.refreshPlaybackState();
      }
    });
    backFuture.then((v) {
      if (_handler != null && v != _handler!._cachedBackSkip) {
        _handler!._cachedBackSkip = v;
        _handler!.refreshPlaybackState();
      }
    });
    if (Platform.isIOS) {
      unawaited(
        Future.wait([fwdFuture, backFuture])
            .then((v) => _pushIosSkipIntervals(v[0], v[1])),
      );
    }
  }

  /// Fill in a missing library id for the playing item so per-library skip
  /// amounts apply outside the in-app UI too (notification, headset, home
  /// widget, Android Auto). Lean shelf items and merged-library podcast
  /// entries often arrive without one; try download metadata synchronously,
  /// then the server.
  void _resolveMissingLibraryId(String itemId, String? episodeId) {
    if (itemId.isEmpty) return;
    if (_currentLibraryId != null && _currentLibraryId!.isNotEmpty) return;
    final key = episodeId != null ? '$itemId-$episodeId' : itemId;
    final fromDownload = DownloadService().getInfo(key).libraryId;
    if (fromDownload != null && fromDownload.isNotEmpty) {
      debugPrint(
        '[SkipDebug] libraryId resolved from download metadata: $fromDownload',
      );
      _currentLibraryId = fromDownload;
      return;
    }
    final api = _api;
    if (api == null) return;
    unawaited(() async {
      try {
        final item = await api.getLibraryItem(itemId);
        final libId = item?['libraryId'] as String?;
        if (libId == null || libId.isEmpty) return;
        // Only adopt if this item is still the one playing and nothing else
        // resolved the library in the meantime (e.g. the play session).
        if (_currentItemId != itemId) return;
        if (_currentLibraryId != null && _currentLibraryId!.isNotEmpty) return;
        debugPrint('[SkipDebug] libraryId resolved from server: $libId');
        _currentLibraryId = libId;
        _syncNotifSkipCache();
        notifyListeners();
      } catch (e) {
        debugPrint('[SkipDebug] libraryId lookup failed: $e');
      }
    }());
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
  void _logEvent(
    PlaybackEventType type, {
    String? detail,
    double? overridePosition,
  }) {
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
    if (h > 0)
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String? get currentItemId => _currentItemId;
  String? get currentTitle => _currentTitle;
  String? get currentAuthor => _currentAuthor;
  String? get currentCoverUrl => _currentCoverUrl;
  double get totalDuration => _totalDuration;
  double get displayDuration =>
      _metaDuration > 0 ? _metaDuration : _totalDuration;
  List<dynamic> get chapters => _chapters;

  /// GH #298: how every "now playing" surface (lock screen, CarPlay, Android
  /// Auto, home widget) labels the current item — the chapter goes on the
  /// primary line and the book sits beside the author ("Author · Book").
  /// Chapterless content (podcasts, books with no chapters) keeps the
  /// book/episode on the primary line.
  static ({String title, String subtitle}) nowPlayingLabels(
    String primaryTitle,
    String author,
    String? chapter,
  ) {
    final ch = chapter?.trim() ?? '';
    if (ch.isEmpty) return (title: primaryTitle, subtitle: author);
    final a = author.trim();
    final String subtitle;
    if (a.isEmpty) {
      subtitle = primaryTitle;
    } else if (primaryTitle.isEmpty) {
      subtitle = a;
    } else {
      subtitle = '$a · $primaryTitle';
    }
    return (title: ch, subtitle: subtitle);
  }

  /// Chapter-aware primary line for the current item (GH #298).
  String get nowPlayingTitle => nowPlayingLabels(
    _currentTitle ?? '',
    _currentAuthor ?? '',
    currentChapter?['title'] as String?,
  ).title;

  /// Chapter-aware secondary line ("Author · Book") for the current item.
  String get nowPlayingSubtitle => nowPlayingLabels(
    _currentTitle ?? '',
    _currentAuthor ?? '',
    currentChapter?['title'] as String?,
  ).subtitle;

  void updateChapters(List<dynamic> chapters) {
    _chapters = chapters;
    _handler?.updateChaptersQueue(chapters);
    notifyListeners();
  }

  bool get hasBook => _currentItemId != null;

  /// True when a loaded item is in an active session - playing OR paused.
  /// stop() drops the engine to idle while keeping _currentItemId, so this is
  /// false for a stopped session even though [hasBook] stays true.
  bool get hasActiveSession =>
      _currentItemId != null &&
      (_player?.processingState ?? ProcessingState.idle) !=
          ProcessingState.idle;
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
  static const _queueAdvancerChannel = MethodChannel(
    'com.absorb.queue_advancer',
  );
  void _resetPreBufferState() {
    _activeConcatSource = null;
    _currentBookTrackCount = 0;
    _nextBookPreloading = false;
    _preloadedNextBook = null;
    _iosResyncPending = false;
    if (Platform.isIOS) {
      _queueAdvancerChannel.invokeMethod('clear').catchError((Object e) {
        debugPrint('[QueueAdvance] clear failed: $e');
        return null;
      });
    }
  }

  void _maybePreloadNextBook() {
    if (_nextBookPreloading) return;
    if (_preloadedNextBook != null) return;
    if (_activeConcatSource == null) return;
    if (_currentBookTrackCount == 0) return;
    if (_totalDuration <= 0) return;
    final remaining = _totalDuration - _lastKnownPositionSec;
    if (remaining <= 0 || remaining > 15) return;
    if (_currentItemId == null) return;
    final cb = _onPeekNextItemCallback;
    if (cb == null) return;

    _nextBookPreloading = true;
    final currentId = _currentEpisodeId != null
        ? '$_currentItemId-$_currentEpisodeId'
        : _currentItemId!;
    unawaited(_preloadNextBookAsync(cb, currentId));
  }

  Future<void> _preloadNextBookAsync(
    Future<Map<String, dynamic>?> Function(String) cb,
    String currentId,
  ) async {
    try {
      final next = await cb(currentId);
      if (next == null) {
        debugPrint('[PreBuffer] No next item to preload');
        return;
      }
      final nextItemId = next['itemId'] as String?;
      if (nextItemId == null) {
        debugPrint('[PreBuffer] Next item has no itemId');
        return;
      }
      // Resolve the next book's resume position once and stash it on the map
      // so commitAdvance, Now Playing, and _onAutoQueueAdvanced all agree.
      double startS = 0;
      final progressKey = next['episodeId'] != null
          ? '$nextItemId-${next['episodeId']}'
          : nextItemId;
      double localS = 0;
      final saved = await _progressSync.getLocal(progressKey);
      if (saved != null && !(saved['isFinished'] as bool? ?? false)) {
        localS = (saved['currentTime'] as num?)?.toDouble() ?? 0;
      }
      startS = localS;
      // Local storage can be empty or behind when the progress lives on the
      // server (another device, fresh install). Server-ahead wins, same as
      // the playItem position pick.
      double serverS = 0;
      if (_api != null && !_isOfflineMode) {
        try {
          final server = await _api!
              .getItemProgress(progressKey)
              .timeout(const Duration(seconds: 5), onTimeout: () => null);
          final serverTime = (server?['currentTime'] as num?)?.toDouble() ?? 0;
          final serverFinished = server?['isFinished'] as bool? ?? false;
          if (!serverFinished) serverS = serverTime;
          if (serverS > startS) startS = serverS;
        } catch (_) {}
      }
      debugPrint(
        '[PreBuffer] Resume pick for $progressKey: '
        'local=${localS.toStringAsFixed(1)}s server=${serverS.toStringAsFixed(1)}s '
        '-> start=${startS.toStringAsFixed(1)}s',
      );
      next['startS'] = startS;

      // Build audio source for the next item.
      final localPaths = (next['localPaths'] as List<dynamic>?)?.cast<String>();
      final audioTracks = next['audioTracks'] as List<dynamic>?;
      final audioHeaders = next['audioHeaders'] as Map<String, String>?;

      List<AudioSource>? nextTrackSources;
      if (localPaths != null && localPaths.isNotEmpty) {
        nextTrackSources = localPaths.map((p) => localAudioSource(p)).toList();
      } else if (audioTracks != null && audioTracks.isNotEmpty) {
        nextTrackSources = audioTracks
            .map(
              (t) =>
                  AudioSource.uri(
                        Uri.parse((t as Map<String, dynamic>)['url'] as String),
                        headers: audioHeaders,
                        options: mp3ExtractorOptions(),
                      )
                      as AudioSource,
            )
            .toList();
      }
      if (nextTrackSources == null || nextTrackSources.isEmpty) {
        debugPrint('[PreBuffer] No playable sources for next item');
        return;
      }
      if (nextTrackSources.length != 1) {
        debugPrint(
          '[PreBuffer] Next item is multi-track, skipping (MVP supports single-track only)',
        );
        return;
      }

      if (Platform.isIOS) {
        // Native engine owns the cross-book swap. Skip concat.add entirely.
        final source = nextTrackSources.length == 1
            ? nextTrackSources.first
            : ConcatenatingAudioSource(children: nextTrackSources);
        final ok = await _player!.setNextSource(
          source,
          startPositionS: startS,
          totalDurationS: (next['duration'] as num?)?.toDouble() ?? 0,
          itemId: nextItemId,
        );
        if (!ok) {
          debugPrint('[PreBuffer] Native setNextSource failed');
          return;
        }
        _preloadedNextBook = next;
        debugPrint(
          '[PreBuffer] Pre-loaded native: ${next['title']} ($nextItemId) start=${startS.toStringAsFixed(1)}s',
        );
        return;
      }

      final concat = _activeConcatSource;
      if (concat == null) {
        debugPrint('[PreBuffer] Concat source went away mid-preload');
        return;
      }
      for (final s in nextTrackSources) {
        await concat.add(s);
      }
      _preloadedNextBook = next;
      debugPrint(
        '[PreBuffer] Pre-loaded next item: ${next['title']} ($nextItemId) '
        'start=${startS.toStringAsFixed(1)}s',
      );

      if (Platform.isIOS) {
        // Legacy native queue advancer kick (flag-off path).
        unawaited(
          _primeNativeQueueAdvancer(
            next,
            localPaths,
            audioTracks,
            audioHeaders,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[PreBuffer] Failed: $e\n$st');
    }
    // _nextBookPreloading stays true regardless of outcome — single attempt per
    // play session. Reset happens in _resetPreBufferState on the next playItem.
  }

  Future<bool> _primeNativeQueueAdvancer(
    Map<String, dynamic> next,
    List<String>? localPaths,
    List<dynamic>? audioTracks,
    Map<String, String>? audioHeaders,
  ) async {
    try {
      String? url;
      bool isLocal = false;
      if (localPaths != null && localPaths.isNotEmpty) {
        url = localPaths.first;
        isLocal = true;
      } else if (audioTracks != null && audioTracks.isNotEmpty) {
        url = (audioTracks.first as Map<String, dynamic>)['url'] as String?;
      }
      if (url == null || url.isEmpty) return false;

      String? coverPath;
      final itemId = next['itemId'] as String?;
      if (itemId != null) {
        final local = DownloadService().getInfo(itemId).localCoverPath;
        if (local != null && local.isNotEmpty) coverPath = local;
      }

      final startS = (next['startS'] as num?)?.toDouble() ?? 0;

      // GH #298: label the pre-buffered next book like the lock screen — its
      // chapter at the resume point as title, "Author · Book" beneath.
      final nextLabels = nowPlayingLabels(
        (next['title'] as String?) ?? '',
        (next['author'] as String?) ?? '',
        _chapterTitleAt(
          (next['chapters'] as List<dynamic>?) ?? const [],
          startS,
        ),
      );

      final ok = await _queueAdvancerChannel.invokeMethod<bool>('prepareNext', {
        'url': url,
        'isLocal': isLocal,
        'headers': audioHeaders ?? <String, String>{},
        'title': nextLabels.title,
        'artist': nextLabels.subtitle,
        'durationS': (next['duration'] as num?)?.toDouble() ?? 0,
        'coverPath': coverPath,
        'startS': startS,
      });
      debugPrint('[PreBuffer] native prepareNext returned $ok');
      return ok ?? false;
    } catch (e) {
      debugPrint('[PreBuffer] native prepareNext failed: $e');
      return false;
    }
  }

  void _onAutoQueueAdvanced() {
    final next = _preloadedNextBook;
    if (next == null) return;
    if (_autoQueueAdvancing) return;
    _autoQueueAdvancing = true;
    _beginAdvanceBuffering();
    debugPrint('[PreBuffer] Auto-queue advanced to ${next['title']}');
    final oldTrackCount = _currentBookTrackCount;

    final oldItemId = _currentItemId;
    final oldEpisodeId = _currentEpisodeId;
    final oldKey = oldEpisodeId != null
        ? '$oldItemId-$oldEpisodeId'
        : oldItemId;

    // Promote next book's metadata to current state
    _currentItemId = next['itemId'] as String?;
    _currentEpisodeId = next['episodeId'] as String?;
    _currentLibraryId = next['libraryId'] as String?;
    _resolveMissingLibraryId(_currentItemId ?? '', _currentEpisodeId);
    _syncNotifSkipCache();
    _currentTitle = next['title'] as String?;
    _currentAuthor = next['author'] as String?;
    _currentCoverUrl = next['coverUrl'] as String?;
    _totalDuration = (next['duration'] as num?)?.toDouble() ?? 0;
    _metaDuration = _totalDuration;
    _chapters = (next['chapters'] as List<dynamic>?) ?? [];
    _handler?.updateChaptersQueue(_chapters);
    _trackStartOffsets = [0.0, _totalDuration];
    _currentTrackIndex = 0;
    _playbackSessionId = null;
    final startS = (next['startS'] as num?)?.toDouble() ?? 0;
    _lastKnownPositionSec = startS;
    final newKey = _currentEpisodeId != null
        ? '$_currentItemId-$_currentEpisodeId'
        : _currentItemId;
    debugPrint(
      '[PreBuffer] Promoted $oldKey -> $newKey start=${startS.toStringAsFixed(1)}s',
    );
    _lastNotifiedChapterIndex = -1;
    _currentBookTrackCount = 1;
    _preloadedNextBook = null;
    _nextBookPreloading = false;

    // Push new media item to update Now Playing / lock screen
    final initChapter = _initChapterInfo(startS);
    _pushMediaItem(
      _currentItemId!,
      _currentTitle ?? '',
      _currentAuthor ?? '',
      _currentCoverUrl,
      _totalDuration,
      chapter: initChapter,
    );
    unawaited(
      _primeNowPlaying(
        title: _currentTitle ?? '',
        artist: _currentAuthor ?? '',
        duration: _totalDuration,
        elapsed: startS,
        chapter: initChapter,
      ),
    );

    if (Platform.isIOS) {
      unawaited(_iosAutoAdvanceKick());
    } else {
      unawaited(_finalizeAndroidAutoAdvance(oldTrackCount, startS));
    }

    // Notify LibraryProvider via auto-queue-specific callback (skipAutoAdvance
    // inside markFinishedLocally — next item is already playing, no playItem).
    if (oldKey != null) {
      final cb = _onAutoQueueAdvancedCallback;
      if (cb != null) cb(oldKey);
    }
    if (oldItemId != null && oldEpisodeId == null) {
      unawaited(ReviewService.onBookFinished(isForeground: !_isBackgrounded));
    }

    notifyListeners();
    _autoQueueAdvancing = false;
  }

  /// ExoPlayer walks into the pre-buffered book at position 0 with the
  /// finished item's tracks still in front of it in the concat, so absolute
  /// seeks map into the dead item (and clamp at its end) and the saved resume
  /// position is never applied. Drop the old tracks so the book becomes
  /// index 0, restore single-file offsets, and jump to where the user left it.
  Future<void> _finalizeAndroidAutoAdvance(
    int oldTrackCount,
    double startS,
  ) async {
    try {
      final concat = _activeConcatSource;
      if (concat != null &&
          oldTrackCount > 0 &&
          concat.length > oldTrackCount) {
        await concat.removeRange(0, oldTrackCount);
        debugPrint(
          '[PreBuffer] Dropped $oldTrackCount finished track(s); concat now ${concat.length}',
        );
      }
      _trackStartOffsets = [0.0];
      _currentTrackIndex = 0;
      if (startS > 0) {
        await _seekAbsolute(startS);
        clearSeekTarget();
        debugPrint(
          '[PreBuffer] Resumed advanced book at ${startS.toStringAsFixed(1)}s',
        );
      }
    } catch (e) {
      debugPrint('[PreBuffer] Android advance finalize failed: $e');
    }
  }

  // Set when native commitAdvance swaps in a foreign AVPlayerItem. just_audio
  // sees _index = -1 from then on; we need to rebuild its source the next
  // time the app is foregrounded so position and pause work normally.
  bool _iosResyncPending = false;

  Future<void> _iosAutoAdvanceKick() async {
    final speed = _player?.speed ?? 1.0;
    try {
      await (await AudioSession.instance).setActive(true);
    } catch (e) {
      debugPrint('[QueueAdvance] setActive failed: $e');
    }
    if (_isBackgrounded) {
      try {
        final ok = await _queueAdvancerChannel.invokeMethod<bool>(
          'commitAdvance',
          {'speed': speed},
        );
        if (ok == true) {
          _iosResyncPending = true;
          debugPrint('[QueueAdvance] native commit succeeded, resync armed');
        }
      } catch (e) {
        debugPrint('[QueueAdvance] commitAdvance failed: $e');
      }
    }
    try {
      await _player?.setSpeed(speed);
    } catch (e) {
      debugPrint('[QueueAdvance] setSpeed kick failed: $e');
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      _handler?.refreshPlaybackState();
    });
  }

  Future<void> _iosForegroundResyncIfNeeded() async {
    if (!_iosResyncPending) return;
    _iosResyncPending = false;
    final itemId = _currentItemId;
    final api = _api;
    if (itemId == null || api == null) {
      debugPrint('[QueueAdvance] resync: missing item or api, skipping');
      return;
    }
    double startS = 0;
    try {
      final pos = await _queueAdvancerChannel.invokeMethod<double>(
        'getPositionS',
      );
      if (pos != null && pos > 0) startS = pos;
    } catch (e) {
      debugPrint('[QueueAdvance] getPositionS failed: $e');
    }
    debugPrint(
      '[QueueAdvance] Resyncing just_audio for $itemId at ${startS.toStringAsFixed(1)}s',
    );
    try {
      await playItem(
        api: api,
        itemId: itemId,
        title: _currentTitle ?? '',
        author: _currentAuthor ?? '',
        coverUrl: _currentCoverUrl,
        totalDuration: _totalDuration,
        chapters: _chapters,
        startTime: startS,
        forceStartTime: true,
        episodeId: _currentEpisodeId,
        libraryId: _currentLibraryId,
      );
    } catch (e) {
      debugPrint('[QueueAdvance] resync playItem failed: $e');
    }
  }

  /// iOS: re-take the Now Playing claim after something may have knocked it
  /// out while paused - an interruption (call, Siri, nav, another app's
  /// session), a stretch suspended in the background where the interruption
  /// came and went unseen, or simply the user opening another app that played
  /// something. iOS deactivates the session for the interrupter, and a paused
  /// app that never re-activates quietly falls out of Now Playing candidacy:
  /// the next headset press then goes to Apple Music instead.
  ///
  /// Re-activating and republishing metadata is NOT enough on its own. iOS
  /// only hands the slot to an app that has actually rendered audio, which is
  /// what build 249 got wrong and 251 fixed with a silent blip - so the claim
  /// goes through the native primer rather than being done here. Doing it in
  /// Dart looked like it worked, because setActive succeeds either way.
  ///
  /// Only runs when nothing else is audibly playing (the primer's politeness
  /// guard, checked on both sides): the claim matters exactly when the next
  /// press should reach this app, and grabbing it out from under an app
  /// mid-playback would be rude.
  Future<void> reassertIosClaimWhilePaused(String reason) async {
    if (!Platform.isIOS || !hasBook || isPlaying) return;
    try {
      final info = await _eqChannelForDiag
          .invokeMethod<Map<dynamic, dynamic>>('getAudioDiagnostics');
      if (info?['isOtherAudioPlaying'] == true ||
          info?['secondaryAudioShouldBeSilencedHint'] == true) {
        debugPrint(
          '[AudioSession] claim reassert skipped ($reason) - other audio is playing',
        );
        return;
      }
      await (await AudioSession.instance).setActive(true);
      // Publish this book before the blip, so the slot we take back shows the
      // right title rather than whatever the app that stole it left behind.
      _handler?.refreshPlaybackState();
      final started = await _eqChannelForDiag.invokeMethod<bool>(
        'reclaimNowPlaying',
        {'reason': reason},
      );
      debugPrint(
        '[AudioSession] claim reassert ($reason): blip started=$started',
      );
    } catch (e) {
      debugPrint('[AudioSession] claim reassert failed ($reason): $e');
    }
  }

  /// iOS: a headset press can cold-launch the app into the background with
  /// the native core already driving the shared engine (its remote commands
  /// arm at app launch). Dart then boots with no book loaded, so
  /// audio_service publishes a blank Now Playing over the native core's and
  /// every later press defers to a player that knows nothing - the lock
  /// screen shows audio running with no title, cover or progress. Adopt
  /// instead: restore the last-played item at the engine's own live position,
  /// which re-publishes full metadata and puts Dart in charge of the audio
  /// that is already running. Called once from main.dart after init.
  Future<void> adoptBackgroundEngineIfRunning() async {
    if (!Platform.isIOS) return;
    if (_currentItemId != null) return;
    final player = _player;
    if (player == null) return;
    try {
      final state = await player.engineState();
      if (state != null && state.isLoaded && state.isPlaying) {
        debugPrint(
          '[Player] boot: native engine already playing at '
          '${state.globalPositionS.toStringAsFixed(1)}s with no book loaded - adopting',
        );
        if (state.globalPositionS > 0) {
          await HomeWidgetService().stashLivePosition(state.globalPositionS);
        }
        final restore = AudioPlayerService.onColdStartPlayRequested;
        if (restore != null) await restore();
        return;
      }
      // Idle engine: load the last played item paused instead, so a headset
      // press in the first seconds of a cold start has a live target - the
      // native core defers presses to Flutter the moment its heartbeat
      // exists, and with nothing loaded that press used to land on neither
      // layer.
      await HomeWidgetService().loadLastPlayedPaused();
    } catch (e) {
      debugPrint('[Player] boot engine adopt failed: $e');
    }
  }

  /// iOS foreground reconciliation after a possible widget-driven session.
  ///
  /// The shared engine (AbsorbAudioEngine) persists across Flutter suspension,
  /// so when the user tapped the widget while we were suspended the engine kept
  /// playing the same book. On resume we must NOT reload it - that restarts the
  /// stream. Instead, if the engine is still on our current book, adopt its
  /// playing-state, track index, and global position. If the engine has been
  /// stopped or holds a different book, leave the existing paths to handle it
  /// (the idle-on-resume re-init in play(), or a fresh playItem).
  Future<void> _iosReconcileEngineOnForeground() async {
    if (!Platform.isIOS) return;
    final player = _player;
    final itemId = _currentItemId;
    if (player == null || itemId == null) return;
    final state = await player.engineState();
    if (state == null) return;
    // Engine isn't on our book (stopped, disposed, or swapped) - nothing to
    // adopt; the normal play()/idle-reinit path will rebuild if needed.
    if (!state.isLoaded || state.itemId != itemId) {
      debugPrint(
        '[Player] iOS resume: engine not on current book '
        '(engine=${state.itemId} loaded=${state.isLoaded}) - skipping adopt',
      );
      return;
    }
    // Sync our track index to whatever track the engine actually reached while
    // we were suspended, so absolute-position math is correct.
    if (_trackStartOffsets.length > 1) {
      final clamped = state.trackIndex.clamp(0, _trackStartOffsets.length - 2);
      if (clamped != _currentTrackIndex) {
        debugPrint(
          '[Player] iOS resume: track index $_currentTrackIndex -> $clamped (from engine)',
        );
        _currentTrackIndex = clamped;
      }
    }
    // Adopt the engine's playing-state without issuing a new command, then let
    // the handler re-publish so the lock screen / notification reflect reality.
    final wasPlaying = isPlaying;
    player.adoptPlayingState(state.isPlaying);
    debugPrint(
      '[Player] iOS resume: adopted engine state playing=${state.isPlaying} '
      '(was $wasPlaying) global=${state.globalPositionS.toStringAsFixed(1)}s',
    );
    // Persist the adopted position locally so a subsequent sync/save doesn't
    // overwrite it with a stale value.
    if (state.globalPositionS > 0) {
      _lastKnownPositionSec = state.globalPositionS;
      await _saveProgressLocal(
        Duration(milliseconds: (state.globalPositionS * 1000).round()),
      );
    }
    _handler?.refreshPlaybackState();
    notifyListeners();
  }

  Future<void> _primeNowPlaying({
    required String title,
    required String artist,
    required double duration,
    required double elapsed,
    String? chapter,
  }) async {
    if (!Platform.isIOS) return;
    // GH #298: match the lock screen — chapter as title, "Author · Book" beneath.
    final labels = nowPlayingLabels(title, artist, chapter);
    try {
      await _eqChannelForDiag.invokeMethod('primeNowPlaying', {
        'title': labels.title,
        'artist': labels.subtitle,
        'duration': duration,
        'elapsed': elapsed,
      });
      debugPrint(
        '[Player] primeNowPlaying title="${labels.title}" elapsed=${elapsed.toStringAsFixed(1)}',
      );
    } catch (e) {
      debugPrint('[Player] primeNowPlaying failed: $e');
    }
  }

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
        'volume=${p?.volume.toStringAsFixed(2)}',
        'speed=${p?.speed.toStringAsFixed(2)}',
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
            final outputs =
                (info['outputs'] as List?)
                    ?.map((o) => '${(o as Map)["type"]}:${o["name"]}')
                    .join(',') ??
                '?';
            pieces.addAll([
              'ios.cat=${info["category"]}',
              'ios.mode=${info["mode"]}',
              'ios.policy=${info["routeSharingPolicy"]}',
              'ios.outVol=${info["outputVolume"]}',
              'ios.otherAudio=${info["isOtherAudioPlaying"]}',
              'ios.silenceHint=${info["secondaryAudioShouldBeSilencedHint"]}',
              'ios.route=[$outputs]',
              'ios.sampleRate=${info["sampleRate"]}',
              'ios.npHasInfo=${info["nowPlayingHasInfo"]}',
              'ios.npTitle="${info["nowPlayingTitle"]}"',
              'ios.npRate=${info["nowPlayingRate"]}',
              'ios.npElapsed=${info["nowPlayingElapsed"]}',
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
    Future.delayed(
      const Duration(seconds: 1),
      () => _logAudioDiagnostics('$startStage:t1s'),
    );
    Future.delayed(
      const Duration(seconds: 3),
      () => _logAudioDiagnostics('$startStage:t3s'),
    );
    Future.delayed(
      const Duration(seconds: 10),
      () => _logAudioDiagnostics('$startStage:t10s'),
    );
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
      if (_trackStartOffsets.length <= 1)
        return trackRelative; // single file, no offset
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
  /// endpoints if Flutter dies. Auth is in the URL (session id or token);
  /// custom headers (Cloudflare Access etc.) ride along for reverse-proxy auth.
  void _captureStreamUrls(
    List<dynamic> audioTracks,
    ApiService api, {
    String? sessionId,
    int? playMethod,
  }) {
    final urls = <String>[];
    for (final t in audioTracks) {
      final track = t as Map<String, dynamic>;
      final contentUrl = track['contentUrl'] as String? ?? '';
      if (contentUrl.isEmpty) continue;
      urls.add(api.buildTrackUrl(
        contentUrl,
        sessionId: sessionId,
        trackIndex: (track['index'] as num?)?.toInt(),
        playMethod: playMethod,
      ));
    }
    if (urls.isNotEmpty) {
      final u = Uri.parse(urls.first);
      final form = u.path.contains('/public/session/')
          ? 'public session'
          : (u.queryParameters.containsKey('token') ? 'tokened' : 'other');
      debugPrint('[Player] Stream URL form: $form (${u.path})');
    }
    _activeStreamUrls = urls;
    _activeStreamHeaders = Map<String, String>.from(api.playbackSessionHeaders);
  }

  /// Subscribe to track index changes for multi-file playback.
  void _subscribeTrackIndex() {
    _indexSub?.cancel();
    if (_player == null) return;
    _indexSub = _player!.currentIndexStream.listen(
      (index) {
        if (index == null) return;
        // Pre-buffer auto-advance: if the queue has grown past the current
        // book's tracks and AVQueuePlayer has stepped into the pre-loaded
        // next book's range, fire the book transition.
        if (_currentBookTrackCount > 0 &&
            index >= _currentBookTrackCount &&
            _preloadedNextBook != null) {
          debugPrint(
            '[PreBuffer] currentIndex=$index crossed book boundary at $_currentBookTrackCount',
          );
          _onAutoQueueAdvanced();
          return;
        }
        // Within-book multi-track advance (existing behavior).
        if (_trackStartOffsets.length > 1) {
          final clamped = index.clamp(0, _trackStartOffsets.length - 2);
          if (clamped != _currentTrackIndex) {
            _lastIndexAdvanceTime = DateTime.now();
            _pendingTrackAdvanceRefresh = true;
            debugPrint(
              '[Player] Track index advance: $_currentTrackIndex -> $clamped',
            );
          }
          _currentTrackIndex = clamped;
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[Player] Index stream error: $e');
      },
    );
  }

  /// Seek to an absolute book position, handling multi-file offset conversion.
  Future<void> _seekAbsolute(double absoluteSeconds) async {
    if (_player == null) return;

    // A seek already interrupts audio, so if a fresh session is waiting this
    // is the free moment to swap the source onto its tokenless URLs - the
    // rebuild lands directly at the target instead of seeking the old source.
    if (_pendingSessionUpgrade != null) {
      final resume = _player!.playing;
      if (await _applyPendingSessionUpgrade(
        seekToSeconds: absoluteSeconds,
        resumeAfter: resume,
      )) {
        return;
      }
    }

    // Incomplete download: there's no audio past the decoded end, so clamp the
    // target there instead of letting the player report a phantom position
    // beyond the file (which would then get saved/bookmarked). GH #278.
    if (_shortLocalDurationSec != null &&
        absoluteSeconds > _shortLocalDurationSec!) {
      absoluteSeconds = _shortLocalDurationSec!;
    }

    // Record seek target so UI can snap immediately
    _lastSeekTargetSeconds = absoluteSeconds;
    _lastSeekTime = DateTime.now();

    if (_trackStartOffsets.length <= 1) {
      // Single file — seek directly
      await _player!.seek(
        Duration(milliseconds: (absoluteSeconds * 1000).round()),
      );
      notifyListeners();
      return;
    }
    // Multi-file — find the right track and local offset
    for (int i = 0; i < _trackStartOffsets.length - 1; i++) {
      final trackStart = _trackStartOffsets[i];
      final trackEnd = _trackStartOffsets[i + 1];
      if (absoluteSeconds < trackEnd || i == _trackStartOffsets.length - 2) {
        final localOffset = absoluteSeconds - trackStart;
        debugPrint(
          '[Player] Seek ${absoluteSeconds.toStringAsFixed(1)}s -> track $i '
          'at ${localOffset.toStringAsFixed(1)}s '
          '(${_trackStartOffsets.length - 1} tracks)',
        );
        // Update index BEFORE seeking so positionStream events use the right offset
        _currentTrackIndex = i;
        await _player!.seek(
          Duration(milliseconds: (localOffset * 1000).round()),
          index: i,
        );
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
      // iOS native engine: keep the processing tap attached whenever any
      // EQ/effect is active so effects work with the band EQ off.
      if (Platform.isIOS) {
        EqualizerService().setTapApplier((active) {
          try {
            if (active) {
              _handler?.player.attachEqualizerTap();
            } else {
              _handler?.player.detachEqualizerTap();
            }
          } catch (e) {
            debugPrint('[Player] tap applier failed: $e');
          }
        });
      }
      // Initialize cached skip amounts so notification icons show the correct values
      _handler!._cachedForwardSkip = fwdSkip;
      _handler!._cachedBackSkip = backSkip;
      // Nothing is loaded yet so there's no library override to apply; the
      // per-library amounts follow from _syncNotifSkipCache once an item does.
      if (Platform.isIOS) {
        unawaited(_pushIosSkipIntervals(fwdSkip, backSkip));
      }
      _handler!._cachedNotifSpeedBookmark =
          await PlayerSettings.getMediaControlsSpeedBookmark();
      _handler!._cachedLockSeekBar = await PlayerSettings.getLockSeekBar();
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
      _instance._notifChapterMode =
          await PlayerSettings.getNotificationChapterProgress();
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
  static StreamSubscription? _devicesSub;
  // Output routes whose disappearance should pause playback. becomingNoisy only
  // fires when the LAST external output leaves (audio falling back to the phone
  // speaker). With two outputs connected at once (e.g. car stereo + earbuds),
  // dropping one just reroutes to the other and never fires it, so the book
  // plays on silently. Watching device removal covers that gap.
  // Set true when BT/headphones disconnect so the interruption handler
  // won't auto-resume playback onto the phone speaker.
  static bool _noisyPause = false;
  // Whether BT audio was connected when the current interruption began.
  static bool _wasOnBluetooth = false;
  static bool _duckBriefInterruptions = false;
  static double? _volumeBeforeInterruptionDuck;
  // Safety net for a duck whose matching "end" event never arrives - a known
  // flaky spot on Android, more so over Bluetooth where focus changes route
  // through an extra AVRCP arbitration layer. A duck is supposed to be brief
  // (a notification chime, a voice prompt); if it's still down after this
  // long with nothing having restored it, force it back rather than leaving
  // playback parked at 35% volume for the rest of the session.
  static Timer? _duckWatchdogTimer;
  static const _duckWatchdogTimeout = Duration(seconds: 4);

  static void _armDuckWatchdog() {
    _duckWatchdogTimer?.cancel();
    _duckWatchdogTimer = Timer(_duckWatchdogTimeout, () {
      final stuckVolume = _volumeBeforeInterruptionDuck;
      if (stuckVolume == null) return;
      _volumeBeforeInterruptionDuck = null;
      debugPrint(
        '[AudioSession] Duck watchdog: no end event after '
        '${_duckWatchdogTimeout.inSeconds}s - forcing volume back to $stuckVolume',
      );
      unawaited(_instance._player?.setVolume(stuckVolume));
    });
  }

  static void _clearDuckWatchdog() {
    _duckWatchdogTimer?.cancel();
    _duckWatchdogTimer = null;
  }
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
      final result = await _eqChannel.invokeMethod<bool>(
        'isBluetoothAudioConnected',
      );
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
    _duckBriefInterruptions =
        Platform.isAndroid && await PlayerSettings.getDuckBriefInterruptions();

    await session.configure(
      AudioSessionConfiguration(
        // iOS: playback category — no duckOthers so iOS properly recognises this
        // app as the Now Playing app and shows lock screen / Control Center controls.
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.longFormAudio,
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
        androidWillPauseWhenDucked: !_duckBriefInterruptions,
      ),
    );
    // Don't activate the session here — defer to first playback.
    // Activating during init creates a stale MediaSession that Android
    // can garbage-collect after hours in background, leaving bluetooth /
    // notification / widget controls permanently broken.
    // play() and startLocalPlayback() call setActive(true) before playing.

    _interruptSub?.cancel();
    _interruptSub = session.interruptionEventStream.listen(
      (event) async {
        try {
          final service = _instance;

          if (event.begin) {
            if (event.type == AudioInterruptionType.duck &&
                _duckBriefInterruptions) {
              if (service.isPlaying && _volumeBeforeInterruptionDuck == null) {
                final currentVolume = service._player?.volume ?? 1.0;
                _volumeBeforeInterruptionDuck = currentVolume;
                await service._player?.setVolume(
                  (currentVolume * 0.35).clamp(0.0, 1.0).toDouble(),
                );
                _armDuckWatchdog();
                debugPrint(
                  '[AudioSession] Interrupted (${event.type}) — ducking',
                );
              }
              return;
            }

            final duckedVolume = _volumeBeforeInterruptionDuck;
            if (duckedVolume != null) {
              _volumeBeforeInterruptionDuck = null;
              _clearDuckWatchdog();
              await service._player?.setVolume(duckedVolume);
            }
            if (service.isPlaying) {
              debugPrint(
                '[AudioSession] Interrupted (${event.type}) — pausing',
              );
              _wasOnBluetooth = await _isBluetoothAudioConnected();
              if (_wasOnBluetooth) _lastPlayedOnBtAt = DateTime.now();
              debugPrint('[AudioSession] Was on BT: $_wasOnBluetooth');
              // Pause the underlying player directly, not service.pause(), to keep
              // the interruption lightweight (service.pause() also saves and syncs,
              // which a transient duck doesn't need). Still stamp _lastPauseTime so
              // resume runs auto-rewind per the user's settings: calls and nav
              // prompts rewind like a manual pause, gated by activationDelay.
              await service._player?.pause();
              service._lastPauseTime = DateTime.now();
              service._wasPlayingBeforeInterrupt = true;
              // The notification reads the player directly, but the home
              // widget, cards and watch only refresh on notify - without this
              // the widget kept showing "playing" and ticking its clock
              // through the whole interruption.
              service.notifyListeners();
            }
          } else {
            if (event.type == AudioInterruptionType.duck &&
                _duckBriefInterruptions) {
              final previousVolume = _volumeBeforeInterruptionDuck;
              _volumeBeforeInterruptionDuck = null;
              _clearDuckWatchdog();
              if (previousVolume != null) {
                await service._player?.setVolume(previousVolume);
                debugPrint(
                  '[AudioSession] Interruption ended — volume restored',
                );
              }
              return;
            }

            // Don't auto-resume if the pause was caused by BT/headphone disconnect.
            // Some devices fire interruption-end AFTER becoming-noisy, which would
            // resume playback on the phone speaker.
            if (_noisyPause) {
              debugPrint(
                '[AudioSession] Interruption ended after noisy — skipping resume',
              );
              service._wasPlayingBeforeInterrupt = false;
              return;
            }
            if (!service._wasPlayingBeforeInterrupt) {
              // Interrupted while paused: nothing here was going to resume,
              // and iOS deactivated the session for the interrupter - left
              // alone, the Now Playing claim dies and the next headset press
              // falls to Apple Music. Take the claim back without playing.
              await service.reassertIosClaimWhilePaused('interruption end');
              return;
            }
            if (service._wasPlayingBeforeInterrupt) {
              service._wasPlayingBeforeInterrupt = false;
              await Future.delayed(const Duration(milliseconds: 600));
              // Re-check: another event (like becoming-noisy) might have fired
              // during the delay.
              if (_noisyPause) return;
              // Don't double-resume: Assistant may already have called play().
              if (service._player?.playing == true) return;
              // If we were on BT when interrupted, check if BT is still connected.
              // Some car head units never send AUDIO_BECOMING_NOISY on disconnect,
              // so _noisyPause alone is not enough.
              if (_wasOnBluetooth) {
                final stillOnBt = await _isBluetoothAudioConnected();
                debugPrint(
                  '[AudioSession] Interruption ended — was BT, still BT: $stillOnBt',
                );
                if (!stillOnBt) {
                  debugPrint(
                    '[AudioSession] BT disconnected during interruption — skipping resume',
                  );
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
      },
      onError: (e) {
        debugPrint(
          '[AudioSession] Interruption stream error - re-subscribing: $e',
        );
        _configureAudioSession();
      },
    );

    // Headphones unplugged / BT disconnected — pause, no auto-resume
    _noisySub?.cancel();
    _noisySub = session.becomingNoisyEventStream.listen(
      (_) async {
        try {
          final service = _instance;
          debugPrint('[AudioSession] Becoming noisy — pausing');
          debugPrint(
            '[ClickDebug] becoming-noisy fired: bg=${service._isBackgrounded}, playing=${service.isPlaying}',
          );
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
      },
      onError: (e) {
        debugPrint('[AudioSession] Noisy stream error - re-subscribing: $e');
        _configureAudioSession();
      },
    );

    // Pause when an output route we could be playing through disappears, even
    // if another output stays connected - the silent-playback case becomingNoisy
    // misses. Mirrors the noisy handler. Android only; iOS already pauses on
    // route loss. Tradeoff: a rare false pause if you power off a second output
    // you weren't actually listening on, undone with a single tap on play.
    _devicesSub?.cancel();
    if (Platform.isAndroid) {
      _devicesSub = session.devicesChangedEventStream.listen(
        (event) async {
          try {
            final service = _instance;
            if (!service.isPlaying) return;
            final lost = event.devicesRemoved
                .where(
                  (d) =>
                      d.isOutput && externalAudioOutputTypes.contains(d.type),
                )
                .toSet();
            if (lost.isEmpty) return;
            // Settle re-check: some devices briefly drop and re-add a route when
            // playback starts. Only pause if the output is genuinely gone.
            await Future.delayed(const Duration(milliseconds: 500));
            if (!service.isPlaying) return;
            final current = await session.getDevices(includeInputs: false);
            if (!lost.any((d) => !current.contains(d))) return;
            debugPrint(
              '[AudioSession] Output route removed while playing - pausing',
            );
            _noisyPause = true;
            service._wasPlayingBeforeInterrupt = false;
            _handler?.cancelPendingClick();
            if (service.isPlaying) await service.pause();
          } catch (e) {
            debugPrint('[AudioSession] Device-change handler error: $e');
          }
        },
        onError: (e) {
          debugPrint(
            '[AudioSession] Device-change stream error - re-subscribing: $e',
          );
          _configureAudioSession();
        },
      );
    }
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
        sincePrevPauseMs = _lastForegroundAt!
            .difference(handler._lastHandlerPauseAt!)
            .inMilliseconds;
      }
      if (handler._lastHandlerPlayAt != null) {
        sincePrevPlayMs = _lastForegroundAt!
            .difference(handler._lastHandlerPlayAt!)
            .inMilliseconds;
      }
    }
    final aaDisconnectSuspect =
        sincePrevPauseMs >= 0 && sincePrevPauseMs < 3000;
    debugPrint(
      '[ClickDebug] App foregrounded: sincePrevPauseMs=$sincePrevPauseMs, '
      'sincePrevPlayMs=$sincePrevPlayMs, aaDisconnectSuspect=$aaDisconnectSuspect',
    );
    service._positionSyncFailures = 0; // retry on foreground
    if (Platform.isIOS && service._iosResyncPending) {
      unawaited(service._iosForegroundResyncIfNeeded());
    }
    // After a widget-driven session the shared engine may have kept playing
    // (or advanced) while Flutter was suspended. Adopt its live state rather
    // than reloading - reloading would restart the same stream (bug #285).
    if (Platform.isIOS && service.hasBook) {
      await service._iosReconcileEngineOnForeground();
    }
    if (!service.hasBook) return;
    final sessionAlive = service._playbackSessionId != null;
    debugPrint(
      '[MediaSession] Foregrounded - refreshing (playing=${service.isPlaying}, session=$sessionAlive, item=${service._currentItemId})',
    );
    // Alpha: when session=false, the playback session was closed (pause
    // timeout) and likely handler.stop() ran too. Log handler state so we
    // can see whether the MediaSession is recoverable. Strip before beta.
    if (!sessionAlive && handler != null) {
      try {
        final ps = handler.playbackState.value;
        debugPrint(
          '[MediaSession] Recovery diagnostic: handlerPlaying=${ps.playing}, '
          'processingState=${ps.processingState.name}, '
          'playerPlaying=${handler.player.playing}, '
          'playerProcessing=${handler.player.processingState.name}',
        );
      } catch (e) {
        debugPrint('[MediaSession] Recovery diagnostic error: $e');
      }
    }
    // Flush missed UI updates from background
    service.notifyListeners();
    // Flush overdue server sync
    if (service.isPlaying && service._currentItemId != null) {
      final sinceSync = DateTime.now()
          .difference(service._lastServerSync)
          .inSeconds;
      if (sinceSync > 20) {
        service._syncToServer(service.position);
      }
    }
    // Re-activate audio session to get a fresh system token — but only while
    // actually playing. Doing it on every foreground grabbed AUDIOFOCUS_GAIN
    // even when paused/idle, pausing other apps' audio (e.g. Spotify) the
    // moment Absorb was opened without the user ever pressing play. When not
    // playing we don't need focus; the MediaSession refresh below doesn't
    // require it, and play()/startLocalPlayback reacquire focus themselves.
    if (service.isPlaying) {
      try {
        (await AudioSession.instance).setActive(true);
      } catch (_) {}
    } else if (Platform.isIOS && service.hasBook) {
      // Paused with a book loaded: an interruption while iOS had this app
      // suspended may have silently dropped the Now Playing claim. The
      // Android concern above (activation grabbing focus and pausing other
      // apps) doesn't apply - the reassert has its own other-audio guard.
      await service.reassertIosClaimWhilePaused('foreground');
    }
    // Re-push playback state so the system re-registers the MediaSession
    _handler?.refreshPlaybackState();
    // Re-push media item so notification metadata is fresh
    if (service._currentItemId != null && service._currentTitle != null) {
      final chapterTitle =
          service._lastNotifiedChapterIndex >= 0 && service._chapters.isNotEmpty
          ? (service._chapters[service._lastNotifiedChapterIndex]
                    as Map<String, dynamic>)['title']
                as String?
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

  // Which ABS library the currently-loaded item belongs to, so per-library
  // skip overrides (see PlayerSettings.getSkipOverride) can resolve. Set
  // wherever _currentItemId/_currentEpisodeId are (playItem + queue advance);
  // null when the caller didn't have it available (falls back to global skip).
  String? _currentLibraryId;
  String? get currentLibraryId => _currentLibraryId;

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
    String? libraryId,
    // Started from the app's own screen. Only those wait (briefly, capped)
    // for the server's saved position before audio; plays from Android
    // Auto, the widget, headphones or a cold-start restore begin at the
    // phone's own position immediately. See play().
    bool fromUi = false,
    // Load the item into the player at its resume position but leave it
    // paused, with no playback session: a headset press then always has a
    // live target, without deciding for the user that audio starts now.
    // Downloaded items only - a streamed item plays normally.
    bool loadOnly = false,
  }) async {
    _pauseRequested = false;
    _playFromUi = fromUi;
    if (_handler == null) {
      debugPrint('[Player] Handler not yet initialized, waiting…');
      await _initCompleter.future;
    }
    if (_handler == null) {
      debugPrint('[Player] Handler init failed, cannot play');
      return 'Player failed to initialize';
    }

    // Alpha: catalog every playItem caller so we can find the phantom
    // resume that fires after an AA disconnect without going through
    // Handler.play() / Service.play(). Strip before next beta.
    debugPrint(
      '[PlayItemEntry] itemId=$itemId episodeId=$episodeId '
      'startTime=$startTime forceStartTime=$forceStartTime fromUi=$fromUi\n'
      'Caller:\n${StackTrace.current}',
    );

    // Don't start local playback while casting
    final cast = ChromecastService();
    if (cast.isCasting) {
      debugPrint('[Player] Cast active - skipping local playback');
      return null;
    }

    _beginAdvanceBuffering();

    final playbackGeneration = ++_playbackGeneration;

    // Stop old audio immediately so it doesn't keep playing while the new
    // source is loading (avoids briefly hearing the previous book).
    await _player?.pause();

    // Podcast episodes arrive two ways: episode-shaped (title = the episode)
    // and show-shaped continue/queue entries (title = the show, episodeTitle =
    // the episode, author often blank). Normalise to episode-as-title +
    // show-as-artist so the episode shows everywhere — notification, lock
    // screen, Android Auto, and the server listening session.
    if (episodeId != null &&
        episodeTitle != null &&
        episodeTitle.isNotEmpty &&
        episodeTitle != title) {
      if (author.isEmpty) author = title; // `title` is the show name here
      title = episodeTitle;
    }

    _isLoadingNewItem = true;
    _api = api;
    _currentItemId = itemId;
    _currentEpisodeId = episodeId;
    _currentLibraryId = libraryId;
    debugPrint(
      '[SkipDebug] playItem libraryId=$libraryId (item=$itemId ep=$episodeId)',
    );
    _resolveMissingLibraryId(itemId, episodeId);
    _syncNotifSkipCache();
    // Reset local-session mode for every new play; _playFromLocal re-enables it
    // for downloaded items. Without this it leaks from a prior downloaded play
    // into a following streaming play and misroutes the listening time.
    _localSessionMode = false;
    _pendingLoadOnlySession = null;
    _currentEpisodeTitle = episodeTitle;
    _currentTitle = title;
    _currentAuthor = author;
    _currentCoverUrl = coverUrl;
    _totalDuration = totalDuration;
    _metaDuration = totalDuration;
    _chapters = chapters;
    _shortLocalDurationSec = null; // re-evaluated per source in _playFromLocal
    _handler?.updateChaptersQueue(chapters);
    // New book = fresh session — clear any auto sleep dismissal
    SleepTimerService().resetDismiss();

    // Progress key: compound for episodes, plain for books
    final progressKey = playbackDownloadKey(itemId, episodeId);

    // Notify rolling download listener that a new item is playing
    try {
      await _onPlayStartedCallback?.call(progressKey, totalDuration);
    } catch (e) {
      debugPrint('[Player] Playback-start preparation failed: $e');
    }

    // Check for local saved position (skip if startTime was forced).
    // Always prefer the local position when it's further ahead - the
    // caller's startTime may be stale (e.g. Android Auto browse tree
    // entry cached before the user listened further).
    final localProgressAtStart = await _progressSync.getLocal(progressKey);
    final localPos =
        (localProgressAtStart?['currentTime'] as num?)?.toDouble() ?? 0;
    var localTimestampAtStart =
        (localProgressAtStart?['timestamp'] as num?)?.toInt() ?? 0;
    if (localPos > 0 && !forceStartTime) {
      if (startTime == 0 || localPos > startTime + 1.0) {
        debugPrint(
          '[Player] Resuming from local position: ${localPos}s (caller startTime was ${startTime}s)',
        );
        startTime = localPos;
      }
    }

    // The widget stash is independent of the scoped SharedPreferences cache.
    // That matters on Android Auto cold starts, where a long-lived headless
    // engine can have an older browse entry and an older preferences snapshot.
    if (!forceStartTime) {
      final stashedPos = await HomeWidgetService().getStashedNowPlayingPosition(
        itemId,
        episodeId,
      );
      final newerStashedPos = HomeWidgetService.newerStashedNowPlayingPosition(
        startTime,
        stashedPos,
      );
      if (newerStashedPos != null) {
        debugPrint(
          '[Player] Resuming from stashed widget position: ${newerStashedPos}s (was ${startTime}s)',
        );
        startTime = newerStashedPos;
        localTimestampAtStart = DateTime.now().millisecondsSinceEpoch;
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
    _nativeAutoAdvanceSub?.cancel();
    _nativeAutoAdvanceSub = null;
    _indexSub?.cancel();
    _indexSub = null;
    _lastKnownPositionSec = 0;
    _isCompletingBook = false;

    // Check if downloaded — play locally
    String? result;
    if (_downloadService.isDownloaded(progressKey)) {
      result = await _playFromLocal(
        progressKey,
        title,
        author,
        coverUrl,
        totalDuration,
        chapters,
        startTime,
        forceStartTime,
        loadOnly,
      );
    } else {
      // Check manual offline — don't stream from server
      final prefs = await SharedPreferences.getInstance();
      final manualOffline = prefs.getBool('manual_offline_mode') ?? false;
      if (manualOffline) {
        debugPrint(
          '[Player] Manual offline — cannot stream non-downloaded item',
        );
        _endAdvanceBuffering();
        _clearState();
        return 'This item isn\'t downloaded and offline mode is on';
      }
      // Try to play from cached session metadata first (instant start)
      final cachedSession = await SessionCache.load(
        itemId: itemId,
        episodeId: episodeId,
      );
      if (cachedSession != null) {
        // Race the real session against the cache. When the server answers
        // inside the window (LAN, good WiFi) the play starts through the
        // fresh path with tokenless session URLs - immune to token expiry -
        // and its saved position; only a slow server falls back to the
        // instant cached start. An app-screen play waits the full position
        // cap since that is its one chance to pick up another device's
        // progress before audio; everything else keeps the short window.
        // The in-flight POST is handed to the background refresh either way
        // so a second session is never opened.
        final pendingSession = episodeId != null
            ? api.startEpisodePlaybackSession(itemId, episodeId)
            : api.startPlaybackSession(itemId);
        final raceWindow =
            fromUi ? _serverPositionCheckCap : _sessionRaceWindow;
        Map<String, dynamic>? racedSession;
        try {
          racedSession = await pendingSession.timeout(raceWindow);
        } catch (_) {
          racedSession = null;
        }
        if (racedSession != null) {
          debugPrint(
            '[Player] Session answered within the race window - using fresh path',
          );
          result = await _playFromServer(
            api,
            itemId,
            title,
            author,
            coverUrl,
            totalDuration,
            chapters,
            startTime,
            forceStartTime: forceStartTime,
            preFetchedSession: racedSession,
          );
        } else {
          result = await _playFromSessionCache(
            api,
            itemId,
            title,
            author,
            coverUrl,
            totalDuration,
            chapters,
            startTime,
            cachedSession,
            localTimestampAtStart,
            playbackGeneration,
            forceStartTime,
            pendingSession,
          );
          // Fall through to normal server path if cache was stale/invalid.
          // The cached path never consumed the in-flight POST on this route,
          // so hand its result over instead of opening a second session.
          if (result == 'cache-miss') {
            Map<String, dynamic>? lateSession;
            try {
              lateSession = await pendingSession;
            } catch (_) {}
            result = await _playFromServer(
              api,
              itemId,
              title,
              author,
              coverUrl,
              totalDuration,
              chapters,
              startTime,
              forceStartTime: forceStartTime,
              preFetchedSession: lateSession,
            );
          }
        }
      } else {
        // No cache - stream from server
        result = await _playFromServer(
          api,
          itemId,
          title,
          author,
          coverUrl,
          totalDuration,
          chapters,
          startTime,
          forceStartTime: forceStartTime,
        );
      }
    }

    _isLoadingNewItem = false;
    if (result != null) _endAdvanceBuffering();
    notifyListeners();

    if (result == null && playbackGeneration == _playbackGeneration) {
      _onPlaybackStateChangedCallback?.call(true);
      // Auto-navigate to Absorbing tab when an episode starts playing.
      if (episodeId != null) _onEpisodePlayStartedCallback?.call();
    }
    return result;
  }

  /// Session-start rewind (setting): pull a new session's start position back
  /// by maxRewind so playback opens with a little re-orientation. Scaled by
  /// speed so the perceived amount is the same at 1.5x, and capped at the
  /// chapter start when the barrier is on. Applied to the start position
  /// BEFORE the first seek - it used to run after play() and audibly jumped
  /// 50-90ms into live audio. Callers pass the speed they're about to set.
  Future<double> _sessionStartRewound(
    double startTime, {
    required bool forceStartTime,
    required double speed,
  }) async {
    if (forceStartTime || startTime <= 0) return startTime;
    final rewindSettings = await AutoRewindSettings.load();
    if (!rewindSettings.enabled || !rewindSettings.sessionStartRewind) {
      return startTime;
    }
    final rewindSeconds = rewindSettings.maxRewind;
    if (rewindSeconds <= 0.5) return startTime;
    var newPos = startTime - (rewindSeconds * speed);
    if (newPos < 0) newPos = 0;
    if (rewindSettings.chapterBarrier && _chapters.isNotEmpty) {
      for (final ch in _chapters) {
        final start = (ch['start'] as num?)?.toDouble() ?? 0;
        final end = (ch['end'] as num?)?.toDouble() ?? 0;
        if (startTime >= start && startTime < end) {
          if (newPos < start) newPos = start;
          break;
        }
      }
    }
    final actualDelta = startTime - newPos;
    if (actualDelta <= 0) return startTime;
    final detail = speed == 1.0
        ? '${rewindSeconds.toStringAsFixed(1)}s (session start)'
        : '${rewindSeconds.toStringAsFixed(1)}s (${actualDelta.toStringAsFixed(1)}s at ${speed.toStringAsFixed(2)}x, session start)';
    _logEvent(PlaybackEventType.autoRewind, detail: detail);
    debugPrint(
      '[Player] Session-start rewind ${rewindSeconds.toStringAsFixed(1)}s '
      '(${actualDelta.toStringAsFixed(1)}s at ${speed.toStringAsFixed(2)}x) '
      '-> starting at ${newPos.toStringAsFixed(1)}s',
    );
    return newPos;
  }

  /// Hot-swap from streaming to local files without interrupting playback position.
  /// Called when a download completes for the currently-playing item.
  Future<bool> switchToLocal(String itemId) async {
    final currentItemId = _currentItemId;
    if (currentItemId == null ||
        playbackDownloadKey(currentItemId, _currentEpisodeId) != itemId) {
      return false;
    }
    if (!_downloadService.isDownloaded(itemId)) return false;
    if (_player == null) return false;

    final wasPlaying = _player!.playing;
    final currentAbsolutePos = position; // use absolute position getter
    final currentSpeed = _player!.speed;
    // Paused means the pause sync already reported the tail and the span
    // since then is idle time, not listening (same phantom-time hazard the
    // resume path defends against by resetting _lastServerSync).
    final finalStreamingSeconds = !wasPlaying
        ? 0
        : DateTime.now().difference(_lastServerSync).inSeconds.clamp(0, 300);

    debugPrint(
      '[Player] Hot-swapping to local files at ${currentAbsolutePos.inSeconds}s',
    );

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
        source = localAudioSource(localPaths.first);
      } else {
        final sources = localPaths.map((p) => localAudioSource(p)).toList();
        source = ConcatenatingAudioSource(children: sources);
      }

      await _player!.setAudioSource(source, itemId: _currentItemId);

      // Seek to the same absolute position
      final posSeconds = currentAbsolutePos.inMilliseconds / 1000.0;
      await _seekAbsolute(posSeconds);

      _subscribeTrackIndex();

      // Restore speed
      await _player!.setSpeed(currentSpeed);

      // Resume if was playing
      if (wasPlaying) _player!.play();

      await _switchHotSwapReportingToLocal(
        position: currentAbsolutePos,
        streamingSeconds: finalStreamingSeconds,
      );

      _logEvent(PlaybackEventType.play, detail: 'Switched to local playback');
      debugPrint('[Player] Hot-swap complete — now playing from local files');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Player] Hot-swap failed: $e');
      return false;
    }
  }

  Future<void> _switchHotSwapReportingToLocal({
    required Duration position,
    required int streamingSeconds,
  }) async {
    if (_localSessionMode || _currentItemId == null) return;

    final api = _api;
    final streamingSessionId = _playbackSessionId;
    final progressKey = playbackDownloadKey(
      _currentItemId!,
      _currentEpisodeId,
    );
    final currentTime = position.inMilliseconds / 1000.0;

    try {
      await LocalSessionService().beginSession(
        progressKey: progressKey,
        libraryItemId: _currentItemId!,
        episodeId: _currentEpisodeId,
        mediaType: _currentEpisodeId != null ? 'podcast' : 'book',
        duration: _totalDuration,
        startTime: currentTime,
        displayTitle: _currentTitle,
        displayAuthor: _currentAuthor,
      );
    } catch (e) {
      debugPrint('[Player] Failed to start LOCAL reporting after hot-swap: $e');
      return;
    }

    _logEvent(PlaybackEventType.sessionEnd, detail: 'stream hot-swap');
    _localSessionMode = true;
    _playbackSessionId = null;
    _activeStreamUrls = const [];
    _activeStreamHeaders = const {};
    _lastServerSync = DateTime.now();
    _lastAccrual = _lastServerSync;
    _lastAccrualPos = null;
    _logEvent(PlaybackEventType.sessionStart, detail: 'local hot-swap');

    if (api == null || streamingSessionId == null) return;

    try {
      final pendingBefore =
          await _progressSync.getStreamingPendingTime(progressKey);
      final synced = await api.syncPlaybackSession(
        streamingSessionId,
        currentTime: currentTime,
        duration: _totalDuration,
        timeListened: streamingSeconds,
      );
      if (synced) {
        if (streamingSeconds > 0) {
          unawaited(
            _progressSync.addTimeSaved(streamingSeconds, _player?.speed ?? 1.0),
          );
          unawaited(
            HomeWidgetService().addLocalListeningSeconds(streamingSeconds),
          );
        }
        if (pendingBefore > 0) {
          unawaited(
            _progressSync.reduceStreamingPendingTime(
              progressKey,
              pendingBefore,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Player] Failed to finalize streaming hot-swap session: $e');
    }

    try {
      await api.closePlaybackSession(streamingSessionId);
    } catch (_) {}
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
    bool loadOnly = false,
  ]) async {
    debugPrint('[Player] Playing from local files: $title');
    // Alpha [PodDur]: trace podcast-episode duration loading. Symptom:
    // Android Auto progress bar missing for ~60s on cold-start podcast play
    // because the first MediaItem push carries dur=0. We want to know what
    // value arrived at this function, and what's available from nearby state.
    debugPrint(
      '[PodDur] _playFromLocal entry: itemId=$itemId ep=$_currentEpisodeId totalDurationArg=${totalDuration.toStringAsFixed(1)}s _totalDuration=${_totalDuration.toStringAsFixed(1)}s chapters=${chapters.length}',
    );
    _isOfflineMode = false; // We still sync to server if possible
    _playbackSessionId = null;

    // Check if manual offline mode is on
    final prefs = await SharedPreferences.getInstance();
    final manualOffline = prefs.getBool('manual_offline_mode') ?? false;
    debugPrint('[Player] manualOffline=$manualOffline, api=${_api != null}');

    // Downloaded plays report to the server via the client-owned LOCAL session
    // model (GH #276 Local label, GH #280 per-day attribution), NOT a live
    // /play session. Position still syncs through /me/progress; here we only
    // reconcile the start position against the server's saved progress (when
    // online) the way the /play response used to, sourced from GET /me/progress.
    _localSessionMode = true;
    _logEvent(PlaybackEventType.sessionStart, detail: 'local-session');
    // `itemId` here is the progress key (already `id-episodeId` for a podcast),
    // so build the key from the raw parts to avoid double-appending the episode.
    final pKey = _currentEpisodeId != null
        ? '$_currentItemId-$_currentEpisodeId'
        : _currentItemId!;
    // Only a play from the app screen waits on this, and only briefly: it is
    // the one moment a fresh start can pick up another device's progress
    // before audio. Headphone / widget / Android Auto / cold-start plays of
    // a download need nothing from the network to begin, so they don't ask
    // (GH #321) - unless this phone has no position for it at all, where
    // starting from zero would be the wrong guess and there is nothing to
    // preserve. Whatever position we start with, we keep - no seeking after.
    if (forceStartTime) {
      debugPrint(
        '[Player] Forced start time: ${startTime}s — skipping server/local position comparison',
      );
    } else if (!_playFromUi && startTime > 0) {
      debugPrint(
        '[Player] Skipping progress reconcile - not started from the app screen, playing local position ${startTime.toStringAsFixed(1)}s now',
      );
    } else if (_api != null && !manualOffline && !_knownOffline) {
      try {
        final serverProgress = await _api!
            .getItemProgress(pKey)
            .timeout(_serverPositionCheckCap, onTimeout: () => null);
        final serverPos =
            (serverProgress?['currentTime'] as num?)?.toDouble() ?? 0;
        final serverLastUpdate =
            (serverProgress?['lastUpdate'] as num?)?.toInt() ?? 0;
        final localTs = await _progressSync.getSavedTimestamp(pKey);
        if (serverPos > startTime + 1.0) {
          debugPrint(
            '[Player] Server position is ahead: server=${serverPos}s vs local=${startTime}s — using server',
          );
          startTime = serverPos;
          await _progressSync.saveLocal(
            itemId: itemId,
            currentTime: serverPos,
            duration: totalDuration,
            speed: 1.0,
          );
        } else if (startTime > 0) {
          // Local is ahead — verify via timestamp that this isn't stale data.
          // Skip the override if we have a pending local sync: local is the
          // truth, we just haven't shipped it to the server yet.
          bool useServer = false;
          final hasPending = await _progressSync.hasPendingSync(pKey);
          final gap = startTime - serverPos;
          if (localTs > 0 &&
              !hasPending &&
              gap <= SyncLogic.localAheadSafetySeconds &&
              serverLastUpdate > localTs) {
            debugPrint(
              '[Player] Local position is ahead but stale: local=${startTime}s (ts=$localTs) vs server=${serverPos}s (ts=$serverLastUpdate) — using server',
            );
            startTime = serverPos;
            useServer = true;
          }
          if (!useServer) {
            if (hasPending) {
              debugPrint(
                '[Player] Local position is ahead: local=${startTime}s vs server=${serverPos}s — keeping local (pending sync)',
              );
            } else if (gap > SyncLogic.localAheadSafetySeconds) {
              debugPrint(
                '[Player] Local position is ahead: local=${startTime}s vs server=${serverPos}s — keeping local (gap ${gap.toStringAsFixed(1)}s exceeds safety threshold)',
              );
            } else {
              debugPrint(
                '[Player] Local position is ahead: local=${startTime}s vs server=${serverPos}s — keeping local',
              );
            }
          }
        } else if (serverPos > 0) {
          debugPrint('[Player] No local position, using server: ${serverPos}s');
          startTime = serverPos;
        }
      } catch (e) {
        debugPrint('[Player] Local-play progress reconcile failed: $e');
      }
    } else {
      debugPrint(
        '[Player] Skipping progress reconcile — manual offline or no API',
      );
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
        // Fall back to the cached session duration when the caller didn't have
        // one (e.g. podcast cold-start from Android Auto pushes dur=0). Replaces
        // the old /play-response duration fallback now that local plays skip it.
        if (totalDuration <= 0) {
          final cachedDur = (session['duration'] as num?)?.toDouble();
          if (cachedDur != null && cachedDur > 0) {
            totalDuration = cachedDur;
            _totalDuration = cachedDur;
          }
        }
        // Pick up chapters from cached session when not already loaded
        if (chapters.isEmpty) {
          final cachedChapters = session['chapters'] as List<dynamic>? ?? [];
          if (cachedChapters.isNotEmpty) {
            chapters = cachedChapters;
            _chapters = cachedChapters;
            _handler?.updateChaptersQueue(cachedChapters);
            debugPrint(
              '[Player] Loaded ${cachedChapters.length} chapters from cached session',
            );
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

      final trackSources = localPaths.map((p) => localAudioSource(p)).toList();
      final source = ConcatenatingAudioSource(children: trackSources);

      await _configureAudioSession();
      try {
        final activated = await (await AudioSession.instance).setActive(true);
        debugPrint('[Player] Pre-source setActive(true)=$activated (local)');
      } catch (e) {
        debugPrint('[Player] Pre-source setActive failed (local): $e');
      }
      _resetPreBufferState();
      final decoded = await _player!.setAudioSource(
        source,
        itemId: _currentItemId,
      );
      _activeConcatSource = source;
      _currentBookTrackCount = trackSources.length;

      // Detect an incomplete/corrupt download: the audio on disk decodes to
      // materially less than the book's real length. If we trusted the
      // metadata duration we'd let the user seek past the end of the file,
      // clamp them to ~the file's end on resume, and save that over their real
      // progress (GH #278). Flag it so seeks clamp and saves are protected.
      //
      // Only valid for single-file books. On a multi-file
      // ConcatenatingAudioSource, setAudioSource returns just the first track's
      // duration (the current ExoPlayer window), not the whole book — so this
      // would flag every complete multi-file download as truncated and pin
      // playback to the first track, breaking seek and resume. The single-point
      // _shortLocalDurationSec clamp only models one truncated file anyway.
      final decodedSec = (decoded?.inMilliseconds ?? 0) / 1000.0;
      if (trackSources.length == 1 &&
          totalDuration > 0 &&
          decodedSec > 0 &&
          decodedSec < totalDuration - _kLocalTruncationMarginSec) {
        _shortLocalDurationSec = decodedSec;
        debugPrint(
          '[Player] Local audio decodes to ${decodedSec.toStringAsFixed(1)}s '
          'but book is ${totalDuration.toStringAsFixed(1)}s — download looks '
          'incomplete; clamping seeks and protecting saved progress (GH #278)',
        );
      }

      // If the saved position is at (or past) the end, restart from the beginning
      if (totalDuration > 0 && startTime >= totalDuration - 1.0) startTime = 0;
      final speedKey = _currentItemId ?? itemId;
      final bookSpeed = await PlayerSettings.getBookSpeed(speedKey);
      final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
      startTime = await _sessionStartRewound(
        startTime,
        forceStartTime: forceStartTime,
        speed: speed,
      );
      if (startTime > 0) {
        await _seekAbsolute(startTime);
      }
      clearSeekTarget(); // Seek done; let position events flow immediately

      _subscribeTrackIndex();
      final initChapter = _initChapterInfo(startTime);
      // Speed must be applied before _pushMediaItem: the pushed duration is
      // speed-adjusted at push time, and nothing re-pushes it on load - so
      // pushing at the default 1.0x left the notification/AA/widget bar
      // lagging (the chapter "ended" at 1/speed) until a foreground re-push.
      await _player!.setSpeed(speed);
      _pushMediaItem(
        itemId,
        title,
        author,
        coverUrl,
        totalDuration,
        chapter: initChapter,
      );
      await _primeNowPlaying(
        title: title,
        artist: author,
        duration: totalDuration,
        elapsed: startTime,
        chapter: initChapter,
      );
      await EqualizerService().switchItem(speedKey);
      if (loadOnly) {
        // Loaded and idle at the resume position: the lock screen shows the
        // book paused and a headset press has a live target, but nothing
        // plays and no session exists until the user presses play - the
        // normal play() path creates the session then.
        debugPrint('[Player] Loaded paused (no session) at '
            '${startTime.toStringAsFixed(0)}s');
        _pendingLoadOnlySession = (
          progressKey: pKey,
          itemId: _currentItemId!,
          episodeId: _currentEpisodeId,
          duration: totalDuration,
          title: title,
          author: author,
        );
        _handler?.refreshPlaybackState();
        notifyListeners();
        return null;
      }
      debugPrint('[Player] Starting local playback at ${speed}x');
      _handler?.refreshPlaybackState();
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        (await AudioSession.instance).setActive(true);
      } catch (_) {}
      _player!.play();
      _scheduleAudioDiagnostics('local');
      notifyListeners();
      _setupSync();
      await LocalSessionService().beginSession(
        progressKey: pKey,
        libraryItemId: _currentItemId!,
        episodeId: _currentEpisodeId,
        mediaType: _currentEpisodeId != null ? 'podcast' : 'book',
        duration: totalDuration,
        startTime: startTime,
        displayTitle: title,
        displayAuthor: author,
      );
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

      // A downloaded original can still be unreadable by the device (for
      // example a very large MP4/M4B that ExoPlayer cannot parse). When the
      // server is reachable, retry once through ABS transcoding instead of
      // leaving the user stuck with an unusable local file.
      if (PlaybackErrorPolicy.shouldRetryWithTranscode(e) &&
          _api != null &&
          !manualOffline &&
          !_knownOffline &&
          _currentItemId != null) {
        debugPrint(
          '[Player] Local source failed - retrying with server transcoding',
        );
        _shortLocalDurationSec = null;
        _localSessionMode = false;
        final fallbackResult = await _playFromServer(
          _api!,
          _currentItemId!,
          title,
          author,
          coverUrl,
          totalDuration,
          chapters,
          startTime,
          forceStartTime: forceStartTime,
          forceTranscode: true,
        );
        if (fallbackResult == null) return null;
        debugPrint(
          '[Player] Transcoded fallback after local failure did not start: $fallbackResult',
        );
        return fallbackResult;
      }

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
    Map<String, dynamic> cached,
    int localTimestampAtStart,
    int playbackGeneration, [
    bool forceStartTime = false,
    Future<Map<String, dynamic>?>? pendingSession,
  ]) async {
    debugPrint('[Player] Playing from session cache: $title');
    _isOfflineMode = false;
    _playbackSessionId =
        null; // No server session yet; _refreshServerSession will set it

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
      final audioHeaders = api.playbackSessionHeaders;
      _buildTrackOffsets(audioTracks);
      _captureStreamUrls(audioTracks, api);
      AudioSource source;
      final trackSources = <AudioSource>[];
      for (final t in audioTracks) {
        final track = t as Map<String, dynamic>;
        final contentUrl = track['contentUrl'] as String? ?? '';
        final fullUrl = api.buildTrackUrl(contentUrl);
        trackSources.add(
          AudioSource.uri(
            Uri.parse(fullUrl),
            headers: audioHeaders,
            options: mp3ExtractorOptions(),
          ),
        );
      }
      source = ConcatenatingAudioSource(children: trackSources);

      await _configureAudioSession();
      try {
        final activated = await (await AudioSession.instance).setActive(true);
        debugPrint(
          '[Player] Pre-source setActive(true)=$activated (cached-session)',
        );
      } catch (e) {
        debugPrint('[Player] Pre-source setActive failed (cached-session): $e');
      }
      _resetPreBufferState();
      await _player!.setAudioSource(source, itemId: _currentItemId);
      _activeConcatSource = source as ConcatenatingAudioSource;
      _currentBookTrackCount = trackSources.length;

      if (totalDuration > 0 && startTime >= totalDuration - 1.0) startTime = 0;
      final bookSpeed = await PlayerSettings.getBookSpeed(itemId);
      final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
      startTime = await _sessionStartRewound(
        startTime,
        forceStartTime: forceStartTime,
        speed: speed,
      );
      if (startTime > 0) {
        await _seekAbsolute(startTime);
      }
      clearSeekTarget();

      _subscribeTrackIndex();
      final initChapter = _initChapterInfo(startTime);
      // Speed before _pushMediaItem - the pushed duration is speed-adjusted.
      await _player!.setSpeed(speed);
      _pushMediaItem(
        itemId,
        title,
        author,
        coverUrl,
        totalDuration,
        chapter: initChapter,
      );
      await _primeNowPlaying(
        title: title,
        artist: author,
        duration: totalDuration,
        elapsed: startTime,
        chapter: initChapter,
      );
      await EqualizerService().switchItem(itemId);
      debugPrint('[Player] Starting cached session playback at ${speed}x');
      _handler?.refreshPlaybackState();
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        (await AudioSession.instance).setActive(true);
      } catch (_) {}
      _cachedStartReconcileGeneration = playbackGeneration;
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
      final episodeIdAtStart = _currentEpisodeId;
      final progressKey = episodeIdAtStart != null
          ? '$itemId-$episodeIdAtStart'
          : itemId;
      _refreshServerSession(
        api,
        itemId,
        episodeIdAtStart: episodeIdAtStart,
        progressKey: progressKey,
        localTimestampAtStart: localTimestampAtStart,
        localTimeAtStart: startTime,
        playbackGeneration: playbackGeneration,
        pendingSession: pendingSession,
      );
      return null;
    } catch (e, stack) {
      debugPrint('[Player] Cached session play error: $e\n$stack');
      if (_cachedStartReconcileGeneration == playbackGeneration) {
        _cachedStartReconcileGeneration = null;
      }
      // Cache was stale or invalid - clear it and signal fallback
      SessionCache.clear(itemId: itemId, episodeId: _currentEpisodeId);
      return 'cache-miss';
    }
  }

  /// Re-create the server playback session in the background after starting
  /// playback from cache. Gets a fresh session ID so progress syncing works,
  /// and handles cross-client progress (seek to server position if ahead).
  void _refreshServerSession(
    ApiService api,
    String itemId, {
    required String? episodeIdAtStart,
    required String progressKey,
    required int localTimestampAtStart,
    required double localTimeAtStart,
    required int playbackGeneration,
    Future<Map<String, dynamic>?>? pendingSession,
  }) async {
    try {
      if (_isOfflineMode) return;
      final progressRequest = api.getItemProgress(progressKey);
      // The race in playItem may already have a POST in flight - consume it
      // rather than opening a second session.
      final sessionData = await (pendingSession ??
          (episodeIdAtStart != null
              ? api.startEpisodePlaybackSession(itemId, episodeIdAtStart)
              : api.startPlaybackSession(itemId)));
      if (sessionData == null) {
        debugPrint('[Player] Background session refresh returned null');
        return;
      }
      final serverProgress = await progressRequest;
      if (_playbackGeneration != playbackGeneration ||
          _currentItemId != itemId ||
          _currentEpisodeId != episodeIdAtStart) {
        debugPrint(
          '[Player] Ignoring stale background session refresh for $progressKey',
        );
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
        // The playing source still carries the cached tokened URLs; hold this
        // session so the next pause or seek can swap to its tokenless URLs.
        _stashSessionUpgrade(sessionData);
      }

      // Audio is already running from the cached start; the server's saved
      // position is only logged here, never seeked to - a jump a few seconds
      // into playback is worse than the stale spot. An app-screen play had
      // its chance to adopt it in the pre-start race window.
      final serverPos =
          (serverProgress?['currentTime'] as num?)?.toDouble() ??
          (sessionData['currentTime'] as num?)?.toDouble() ??
          0;
      final serverTs =
          (serverProgress?['lastUpdate'] as num?)?.toInt() ??
          (localTimestampAtStart == 0
              ? (sessionData['updatedAt'] as num?)?.toInt() ?? 0
              : 0);
      final localPos = position.inMilliseconds / 1000.0;
      if (SyncLogic.shouldAdoptServerAtCachedStart(
        serverTimestamp: serverTs,
        serverTime: serverPos,
        localTimestampAtStart: localTimestampAtStart,
        localTimeAtStart: localTimeAtStart,
        currentPlaybackTime: localPos,
      )) {
        debugPrint(
          '[Player] Server is ahead on cache-start: server=${serverPos}s vs local=${localPos}s - not seeking (audio already running)',
        );
      }
    } catch (e) {
      debugPrint('[Player] Background session refresh failed: $e');
    } finally {
      if (_cachedStartReconcileGeneration == playbackGeneration) {
        _cachedStartReconcileGeneration = null;
      }
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
    double startTime, {
    bool forceStartTime = false,
    bool forceTranscode = false,
    Map<String, dynamic>? preFetchedSession,
  }) async {
    debugPrint('[Player] Streaming from server: $title');
    _isOfflineMode = false;
    _localSessionMode = false;

    // Use episode endpoint if this is a podcast episode
    final sessionData = preFetchedSession ??
        (_currentEpisodeId != null
            ? await api.startEpisodePlaybackSession(
                _currentItemId!,
                _currentEpisodeId!,
                forceTranscode: forceTranscode,
              )
            : await api.startPlaybackSession(
                itemId,
                forceTranscode: forceTranscode,
              ));
    if (sessionData == null) {
      debugPrint('[Player] Failed to start playback session');
      _clearState();
      return 'Could not connect to server';
    }

    _playbackSessionId = sessionData['id'] as String?;
    // Sessions know their library; adopt it when the caller couldn't provide
    // one so per-library skip amounts work for lean/merged shelf items.
    final sessionLibId = sessionData['libraryId'] as String?;
    if ((_currentLibraryId == null || _currentLibraryId!.isEmpty) &&
        sessionLibId != null &&
        sessionLibId.isNotEmpty) {
      debugPrint(
        '[SkipDebug] libraryId adopted from play session: $sessionLibId',
      );
      _currentLibraryId = sessionLibId;
      _syncNotifSkipCache();
    }
    _lastServerSync = DateTime.now();
    _logEvent(PlaybackEventType.sessionStart, detail: 'stream');
    var audioTracks = sessionData['audioTracks'] as List<dynamic>?;
    var sessionPlayMethod = (sessionData['playMethod'] as num?)?.toInt();
    if (audioTracks == null || audioTracks.isEmpty) {
      _clearState();
      return 'No audio files found - this item may be missing on the server';
    }

    // Detect Dolby Atmos / EAC-3 / AC-3 tracks. Samsung has a hardware Dolby
    // decoder and iOS AVPlayer handles EAC3 natively, so only force transcode
    // on other Android devices where the software codec often fails or outputs silence.
    if (!forceTranscode &&
        Platform.isAndroid &&
        !ApiService.deviceManufacturer.toLowerCase().contains('samsung')) {
      final needsTranscode = audioTracks.any((t) {
        final mime = ((t as Map<String, dynamic>)['mimeType'] as String? ?? '')
            .toLowerCase();
        final codec = (t['codec'] as String? ?? '').toLowerCase();
        return mime.contains('eac3') ||
            mime.contains('ac3') ||
            mime.contains('ac4') ||
            mime.contains('atmos') ||
            codec.contains('eac3') ||
            codec.contains('ac3') ||
            codec.contains('ac4') ||
            codec.contains('atmos');
      });
      if (needsTranscode) {
        debugPrint(
          '[Player] Dolby/EAC3 track detected - restarting with server transcoding',
        );
        try {
          await api.closePlaybackSession(_playbackSessionId!);
        } catch (_) {}
        _playbackSessionId = null;
        final retrySession = _currentEpisodeId != null
            ? await api.startEpisodePlaybackSession(
                _currentItemId!,
                _currentEpisodeId!,
                forceTranscode: true,
              )
            : await api.startPlaybackSession(itemId, forceTranscode: true);
        if (retrySession == null) {
          _clearState();
          return 'Could not start transcoded playback';
        }
        _playbackSessionId = retrySession['id'] as String?;
        audioTracks = retrySession['audioTracks'] as List<dynamic>? ?? [];
        sessionPlayMethod = (retrySession['playMethod'] as num?)?.toInt();
        if (audioTracks.isEmpty) {
          _clearState();
          return 'No audio files in transcoded session';
        }
        final sessionChapters =
            retrySession['chapters'] as List<dynamic>? ?? [];
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
        debugPrint(
          '[Player] Loaded ${sessionChapters.length} chapters from session',
        );
      }
    }

    // Update totalDuration from session if it was unknown (e.g. podcast episodes
    // where the embedded recentEpisode didn't include a duration field)
    if (totalDuration <= 0) {
      final sessionDur = (sessionData['duration'] as num?)?.toDouble() ?? 0;
      if (sessionDur > 0) {
        totalDuration = sessionDur;
        _totalDuration = sessionDur;
        debugPrint(
          '[Player] Updated totalDuration from session: ${sessionDur}s',
        );
      }
    }

    // Compare server position vs local.
    // Usually the furthest position wins, but if local is ahead we also
    // check timestamps to catch stale local saves.
    // Skip all of this when startTime was forced (bookmark/chapter jump).
    final serverPos = (sessionData['currentTime'] as num?)?.toDouble() ?? 0;
    final pKey = _currentEpisodeId != null
        ? '$itemId-$_currentEpisodeId'
        : itemId;
    final localTs = await _progressSync.getSavedTimestamp(pKey);
    if (forceStartTime) {
      debugPrint(
        '[Player] Forced start time: ${startTime}s — skipping server/local position comparison',
      );
    } else if (serverPos > startTime + 1.0) {
      debugPrint(
        '[Player] Server position is ahead: server=${serverPos}s vs local=${startTime}s — using server',
      );
      startTime = serverPos;
    } else if (startTime > 0) {
      // Skip the staleness override if we have a pending local sync: the
      // server's lastUpdate can be newer than the local timestamp for reasons
      // unrelated to listening progress, so trusting it would clobber offline
      // playback we haven't shipped yet. Also skip if local is meaningfully
      // ahead of server - a multi-minute gap is real listening progress, not
      // a save race.
      bool useServer = false;
      final hasPending = await _progressSync.hasPendingSync(pKey);
      final gap = startTime - serverPos;
      if (localTs > 0 &&
          !hasPending &&
          gap <= SyncLogic.localAheadSafetySeconds) {
        try {
          final serverProgress = await api.getItemProgress(pKey);
          final serverLastUpdate =
              (serverProgress?['lastUpdate'] as num?)?.toInt() ?? 0;
          if (serverLastUpdate > localTs) {
            debugPrint(
              '[Player] Local position is ahead but stale: local=${startTime}s (ts=$localTs) vs server=${serverPos}s (ts=$serverLastUpdate) — using server',
            );
            startTime = serverPos;
            useServer = true;
          }
        } catch (_) {}
      }
      if (!useServer) {
        if (hasPending) {
          debugPrint(
            '[Player] Local position is ahead: local=${startTime}s vs server=${serverPos}s — keeping local (pending sync)',
          );
        } else if (gap > SyncLogic.localAheadSafetySeconds) {
          debugPrint(
            '[Player] Local position is ahead: local=${startTime}s vs server=${serverPos}s — keeping local (gap ${gap.toStringAsFixed(1)}s exceeds safety threshold)',
          );
        } else {
          debugPrint(
            '[Player] Local position is ahead: local=${startTime}s vs server=${serverPos}s — keeping local',
          );
        }
      }
    } else if (serverPos > 0) {
      debugPrint('[Player] No local position, using server: ${serverPos}s');
      startTime = serverPos;
    }

    try {
      _currentTrackIndex = 0;
      final audioHeaders = api.playbackSessionHeaders;

      // Build audio source - one source per track file
      _buildTrackOffsets(audioTracks);
      _captureStreamUrls(
        audioTracks,
        api,
        sessionId: _playbackSessionId,
        playMethod: sessionPlayMethod,
      );
      final trackSources = <AudioSource>[];
      for (final t in audioTracks) {
        final track = t as Map<String, dynamic>;
        final contentUrl = track['contentUrl'] as String? ?? '';
        final fullUrl = api.buildTrackUrl(
          contentUrl,
          sessionId: _playbackSessionId,
          trackIndex: (track['index'] as num?)?.toInt(),
          playMethod: sessionPlayMethod,
        );
        trackSources.add(
          AudioSource.uri(
            Uri.parse(fullUrl),
            headers: audioHeaders,
            options: mp3ExtractorOptions(),
          ),
        );
      }
      final source = ConcatenatingAudioSource(children: trackSources);

      await _configureAudioSession();
      try {
        final activated = await (await AudioSession.instance).setActive(true);
        debugPrint('[Player] Pre-source setActive(true)=$activated (stream)');
      } catch (e) {
        debugPrint('[Player] Pre-source setActive failed (stream): $e');
      }
      _resetPreBufferState();
      await _player!.setAudioSource(source, itemId: _currentItemId);
      _activeConcatSource = source;
      _currentBookTrackCount = trackSources.length;

      // If the saved position is at (or past) the end, restart from the beginning
      if (totalDuration > 0 && startTime >= totalDuration - 1.0) startTime = 0;
      final bookSpeed = await PlayerSettings.getBookSpeed(itemId);
      final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
      startTime = await _sessionStartRewound(
        startTime,
        forceStartTime: forceStartTime,
        speed: speed,
      );
      if (startTime > 0) {
        await _seekAbsolute(startTime);
      }
      clearSeekTarget(); // Seek done; let position events flow immediately

      _subscribeTrackIndex();
      final initChapter = _initChapterInfo(startTime);
      // Speed before _pushMediaItem - the pushed duration is speed-adjusted.
      await _player!.setSpeed(speed);
      _pushMediaItem(
        itemId,
        title,
        author,
        coverUrl,
        totalDuration,
        chapter: initChapter,
      );
      await _primeNowPlaying(
        title: title,
        artist: author,
        duration: totalDuration,
        elapsed: startTime,
        chapter: initChapter,
      );
      await EqualizerService().switchItem(itemId);
      debugPrint('[Player] Starting stream playback at ${speed}x');
      _handler?.refreshPlaybackState();
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        (await AudioSession.instance).setActive(true);
      } catch (_) {}
      _player!.play();
      _scheduleAudioDiagnostics('stream');
      notifyListeners();
      _setupSync();
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

      // Retry source and codec failures through ABS once. A distinct flag from
      // forceStartTime keeps bookmark/chapter seeks eligible for recovery while
      // still preventing a transcode loop.
      if (!forceTranscode && PlaybackErrorPolicy.shouldRetryWithTranscode(e)) {
        debugPrint(
          '[Player] Source or codec error detected - retrying with server transcoding',
        );
        if (_playbackSessionId != null) {
          try {
            await api.closePlaybackSession(_playbackSessionId!);
          } catch (_) {}
          _playbackSessionId = null;
        }
        return _playFromServer(
          api,
          itemId,
          title,
          author,
          coverUrl,
          totalDuration,
          chapters,
          startTime,
          forceStartTime: forceStartTime,
          forceTranscode: true,
        );
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
      debugPrint(
        '[Player] Playback error in stream - retrying with server transcoding',
      );
      final itemId = _currentItemId!;
      final retryEpId = _currentEpisodeId;
      final retryEpTitle = _currentEpisodeTitle;
      final retryLibraryId = _currentLibraryId;
      final retryTitle = _currentTitle ?? '';
      final retryAuthor = _currentAuthor ?? '';
      final retryCover = _currentCoverUrl;
      final failedSessionId = _playbackSessionId;
      final startTime = position.inMilliseconds / 1000.0;
      _clearState();
      _currentItemId = itemId;
      _currentEpisodeId = retryEpId;
      _currentEpisodeTitle = retryEpTitle;
      _currentLibraryId = retryLibraryId;
      _currentTitle = retryTitle;
      _currentAuthor = retryAuthor;
      _currentCoverUrl = retryCover;
      _shortLocalDurationSec = null;
      _syncNotifSkipCache();
      if (failedSessionId != null) {
        try {
          await api.closePlaybackSession(failedSessionId);
        } catch (_) {}
      }
      final retrySession = retryEpId != null
          ? await api.startEpisodePlaybackSession(
              itemId,
              retryEpId,
              forceTranscode: true,
            )
          : await api.startPlaybackSession(itemId, forceTranscode: true);
      if (retrySession == null) return;
      _playbackSessionId = retrySession['id'] as String?;
      final retrySessionLibId = retrySession['libraryId'] as String?;
      if ((_currentLibraryId == null || _currentLibraryId!.isEmpty) &&
          retrySessionLibId != null &&
          retrySessionLibId.isNotEmpty) {
        _currentLibraryId = retrySessionLibId;
        _syncNotifSkipCache();
      }
      _lastServerSync = DateTime.now();
      final retryTracks = retrySession['audioTracks'] as List<dynamic>?;
      final totalDuration =
          (retrySession['duration'] as num?)?.toDouble() ?? _totalDuration;
      final chapters = retrySession['chapters'] as List<dynamic>? ?? _chapters;
      _chapters = chapters;
      _totalDuration = totalDuration;
      if (retryTracks == null || retryTracks.isEmpty) return;
      _currentTrackIndex = 0;
      _buildTrackOffsets(retryTracks);
      AudioSource retrySource;
      final audioHeaders = api.playbackSessionHeaders;
      if (retryTracks.length == 1) {
        final track = retryTracks.first as Map<String, dynamic>;
        final contentUrl = track['contentUrl'] as String? ?? '';
        retrySource = AudioSource.uri(
          Uri.parse(api.buildTrackUrl(contentUrl)),
          headers: audioHeaders,
          options: mp3ExtractorOptions(),
        );
      } else {
        final sources = <AudioSource>[];
        for (final t in retryTracks) {
          final track = t as Map<String, dynamic>;
          final contentUrl = track['contentUrl'] as String? ?? '';
          sources.add(
            AudioSource.uri(
              Uri.parse(api.buildTrackUrl(contentUrl)),
              headers: audioHeaders,
              options: mp3ExtractorOptions(),
            ),
          );
        }
        retrySource = ConcatenatingAudioSource(children: sources);
      }
      await _player!.setAudioSource(retrySource, itemId: _currentItemId);
      if (startTime > 0) await _seekAbsolute(startTime);
      clearSeekTarget();
      _subscribeTrackIndex();
      final initChapter = _initChapterInfo(startTime);
      // Speed before _pushMediaItem - the pushed duration is speed-adjusted.
      final bookSpeed = await PlayerSettings.getBookSpeed(itemId);
      final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
      await _player!.setSpeed(speed);
      _pushMediaItem(
        itemId,
        retryTitle,
        retryAuthor,
        retryCover,
        totalDuration,
        chapter: initChapter,
      );
      await EqualizerService().switchItem(itemId);
      debugPrint('[Player] Transcoded playback starting at ${speed}x');
      try {
        (await AudioSession.instance).setActive(true);
      } catch (_) {}
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
  /// Chapter title covering [posSeconds] in an arbitrary chapter list (used for
  /// the pre-buffered next book, whose chapters aren't in [_chapters] yet).
  String? _chapterTitleAt(List<dynamic> chapters, double posSeconds) {
    if (chapters.isEmpty) return null;
    for (final ch in chapters) {
      final m = ch as Map<String, dynamic>;
      final start = (m['start'] as num?)?.toDouble() ?? 0;
      final end = (m['end'] as num?)?.toDouble() ?? double.infinity;
      if (posSeconds >= start && posSeconds < end) return m['title'] as String?;
    }
    return (chapters.first as Map<String, dynamic>)['title'] as String?;
  }

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
    // Slightly past the last chapter still counts as the last chapter.
    // Grossly past it means the chapters don't cover the timeline (e.g.
    // duplicate audio files doubling the duration, GH #345) - report no
    // chapter rather than pinning the last one.
    final graceIdx =
        ChapterLookup.indexAtWithGrace(_chapters, posSeconds, _totalDuration);
    if (graceIdx != null) {
      final ch = _chapters[graceIdx] as Map<String, dynamic>;
      _currentChapterStart = (ch['start'] as num?)?.toDouble() ?? 0;
      _currentChapterEnd = (ch['end'] as num?)?.toDouble() ?? _totalDuration;
      _lastNotifiedChapterIndex = graceIdx;
      return ch['title'] as String?;
    }
    _currentChapterStart = 0;
    _currentChapterEnd = _totalDuration;
    _lastNotifiedChapterIndex = -1;
    return null;
  }

  /// Content provider authority — must match CoverContentProvider and AndroidManifest.
  static const _coverAuthority = 'com.barnabas.absorb.covers';

  void _pushMediaItem(
    String itemId,
    String title,
    String author,
    String? coverUrl,
    double totalDuration, {
    String? chapter,
    int? coverCacheBust,
  }) {
    // Alpha [PodDur]: trace every push-site. We want to see which callers
    // pass only the parent itemId (missing -episodeId suffix) and/or a zero
    // duration, so we can pinpoint what to fix for the AA podcast progress
    // bar. Includes the current _totalDuration so "stale 0" paths are visible.
    debugPrint(
      '[PodDur] _pushMediaItem: itemId=$itemId ep=$_currentEpisodeId argDur=${totalDuration.toStringAsFixed(1)}s _totalDuration=${_totalDuration.toStringAsFixed(1)}s',
    );
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
      if (coverCacheBust != null) effectiveCoverUrl += '?cb=$coverCacheBust';
      // Streamed cover (no local file) won't be cached on first play - schedule
      // one cache-busted re-push so the art shows up the first time too.
      final localCover = DownloadService().getInfo(itemId).localCoverPath;
      final streamed = localCover == null || localCover.isEmpty;
      if (streamed && coverCacheBust == null && _coverRepushItem != itemId) {
        _coverRepushItem = itemId;
        _scheduleStreamedCoverRepush(itemId);
      }
    }
    _updateNotificationMediaItem(
      itemId,
      title,
      author,
      effectiveCoverUrl,
      totalDuration,
      chapter: chapter,
    );
  }

  void _scheduleStreamedCoverRepush(String itemId) {
    _coverRepushTimer?.cancel();
    _coverRepushTimer = Timer(const Duration(seconds: 3), () {
      // Only re-push if we're still on the same item.
      if (_currentItemId == null) return;
      if (_currentItemId != itemId && _mediaItemKey != itemId) return;
      final chapterTitle =
          _lastNotifiedChapterIndex >= 0 && _chapters.isNotEmpty
          ? (_chapters[_lastNotifiedChapterIndex]
                    as Map<String, dynamic>)['title']
                as String?
          : null;
      _pushMediaItem(
        itemId,
        _currentTitle ?? '',
        _currentAuthor ?? '',
        _currentCoverUrl,
        _totalDuration,
        chapter: chapterTitle,
        coverCacheBust: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  void _updateNotificationMediaItem(
    String itemId,
    String title,
    String author,
    String? coverUrl,
    double totalDuration, {
    String? chapter,
  }) {
    // GH #298: chapter becomes the title, book moves beside the author.
    final labels = nowPlayingLabels(title, author, chapter);
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
    debugPrint(
      '[Handler] mediaItem.add: item=$itemId title="${labels.title}" artist="${labels.subtitle}" dur=${displayDuration.round()}s chapter=$chapter hasHandler=${_handler != null}',
    );
    _handler!.mediaItem.add(
      MediaItem(
        id: itemId,
        title: labels.title,
        artist: labels.subtitle,
        album: title,
        duration: Duration(seconds: displayDuration.round()),
        artUri: coverUrl != null ? Uri.tryParse(coverUrl) : null,
      ),
    );
  }

  void _clearState() {
    _currentItemId = null;
    _currentEpisodeId = null;
    _currentLibraryId = null;
    _currentEpisodeTitle = null;
    _currentTitle = null;
    _currentAuthor = null;
    _currentCoverUrl = null;
    _coverRepushTimer?.cancel();
    _coverRepushItem = null;
    _playbackSessionId = null;
    _isOfflineMode = false;
    _localSessionMode = false;
    _trackStartOffsets = [];
    _currentTrackIndex = 0;
    _lastNotifiedChapterIndex = -1;
    _lastSeekTargetSeconds = null;
    _lastSeekTime = null;
    _lastIndexAdvanceTime = null;
    _iosLastTrackRecoveryAttempts = 0;
    _indexSub?.cancel();
    _indexSub = null;
    _syncSub?.cancel();
    _syncSub = null;
    _completionSub?.cancel();
    _completionSub = null;
    _nativeAutoAdvanceSub?.cancel();
    _nativeAutoAdvanceSub = null;
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

  // How long a cached play waits for the real session before falling back to
  // the instant cached start. Long enough for LAN/WiFi round trips, short
  // enough that a slow reverse proxy doesn't make press-play feel laggy.
  static const _sessionRaceWindow = Duration(milliseconds: 700);

  // A fresh session whose tokenless URLs the playing source should adopt at
  // the next pause or seek - the two moments a source rebuild is inaudible.
  // Set whenever a session is (re)created behind an already-playing source:
  // cached fast-starts, sync-tick recreations, resume recreations. One-shot.
  Map<String, dynamic>? _pendingSessionUpgrade;
  int _pendingUpgradeGeneration = -1;

  void _stashSessionUpgrade(Map<String, dynamic> sessionData) {
    final tracks = sessionData['audioTracks'] as List<dynamic>?;
    if (tracks == null || tracks.isEmpty) return;
    _pendingSessionUpgrade = sessionData;
    _pendingUpgradeGeneration = _playbackGeneration;
    debugPrint(
      '[StreamUpgrade] Holding session ${sessionData['id']} for a swap at the next pause/seek',
    );
  }

  /// Swap the playing source onto [_pendingSessionUpgrade]'s tokenless session
  /// URLs. Called only from moments where playback is already interrupted
  /// (paused, or mid-seek), so the rebuild rides inside that interruption.
  /// Returns true when the swap happened and already landed at
  /// [seekToSeconds] (or the current position); the caller must then skip its
  /// own seek. Any failure keeps the old, still-working source.
  Future<bool> _applyPendingSessionUpgrade({
    double? seekToSeconds,
    bool resumeAfter = false,
  }) async {
    final session = _pendingSessionUpgrade;
    if (session == null || _player == null || _api == null) return false;
    if (_pendingUpgradeGeneration != _playbackGeneration ||
        _isOfflineMode ||
        _localSessionMode) {
      _pendingSessionUpgrade = null;
      return false;
    }
    // While casting, the local player isn't the real output - keep the
    // pending session for when local playback matters again.
    if (ChromecastService().isCasting) return false;
    final sessionId = session['id'] as String?;
    final tracks = session['audioTracks'] as List<dynamic>?;
    final playMethod = (session['playMethod'] as num?)?.toInt();
    if (sessionId == null ||
        sessionId != _playbackSessionId ||
        tracks == null ||
        tracks.isEmpty) {
      // Session got replaced or closed since it was stashed - a swap onto its
      // URLs would point at a dead session.
      _pendingSessionUpgrade = null;
      return false;
    }
    _pendingSessionUpgrade = null; // one-shot, success or not
    try {
      final api = _api!;
      final target = (seekToSeconds ?? position.inMilliseconds / 1000.0)
          .clamp(0.0, double.infinity)
          .toDouble();
      final audioHeaders = api.playbackSessionHeaders;
      final trackSources = <AudioSource>[];
      var tokenless = true;
      for (final t in tracks) {
        final track = t as Map<String, dynamic>;
        final contentUrl = track['contentUrl'] as String? ?? '';
        final fullUrl = api.buildTrackUrl(
          contentUrl,
          sessionId: sessionId,
          trackIndex: (track['index'] as num?)?.toInt(),
          playMethod: playMethod,
        );
        if (fullUrl.contains('token=')) tokenless = false;
        trackSources.add(
          AudioSource.uri(
            Uri.parse(fullUrl),
            headers: audioHeaders,
            options: mp3ExtractorOptions(),
          ),
        );
      }
      if (!tokenless) {
        // Old server or transcode session - the swap would just re-bake a
        // token, which is what the current source already has.
        debugPrint('[StreamUpgrade] Session URLs still carry a token - skipping');
        return false;
      }
      // Map the absolute target onto (track, local position) for the new source.
      _buildTrackOffsets(tracks);
      var idx = 0;
      for (int i = 0; i < _trackStartOffsets.length - 1; i++) {
        if (target < _trackStartOffsets[i + 1] ||
            i == _trackStartOffsets.length - 2) {
          idx = i;
          break;
        }
      }
      final localPos = Duration(
        milliseconds: ((target - _trackStartOffsets[idx]) * 1000).round(),
      );
      // Stamp the seek target so position readers (UI, progress save) hold at
      // the target while the new source loads instead of flashing 0.
      _lastSeekTargetSeconds = target;
      _lastSeekTime = DateTime.now();
      _captureStreamUrls(
        tracks,
        api,
        sessionId: sessionId,
        playMethod: playMethod,
      );
      final source = ConcatenatingAudioSource(children: trackSources);
      _resetPreBufferState();
      await _player!.setAudioSource(
        source,
        initialIndex: idx,
        initialPosition: localPos,
        itemId: _currentItemId,
      );
      _activeConcatSource = source;
      _currentBookTrackCount = trackSources.length;
      _subscribeTrackIndex();
      if (resumeAfter) _player!.play();
      debugPrint(
        '[StreamUpgrade] Swapped to tokenless session URLs at ${target.toStringAsFixed(1)}s '
        '(track $idx, resume=$resumeAfter)',
      );
      return true;
    } catch (e) {
      debugPrint('[StreamUpgrade] Swap failed - keeping current source: $e');
      return false;
    }
  }

  /// Attempt to recover from a stream error by restarting playback from the
  /// last known position.  Tries up to [_maxStreamRetries] times with
  /// exponential back-off (1s, 2s, 4s).  If the item has been downloaded in
  /// the meantime, falls back to local files automatically.
  Future<void> _attemptStreamRetry(Object error) async {
    if (_retryInProgress) return;
    if (_currentItemId == null || _api == null) return;
    if (_streamRetryCount >= _maxStreamRetries) {
      debugPrint(
        '[Player] Max retries reached ($_maxStreamRetries) — giving up',
      );
      return;
    }

    _retryInProgress = true;
    _streamRetryCount++;
    final delay = Duration(seconds: 1 << (_streamRetryCount - 1)); // 1s, 2s, 4s
    debugPrint(
      '[Player] Stream error — retry $_streamRetryCount/$_maxStreamRetries in ${delay.inSeconds}s',
    );

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
    final libraryId = _currentLibraryId;
    final api = _api!;
    final retryPos = _lastKnownPositionSec;

    if (itemId == null) {
      _retryInProgress = false;
      return;
    }

    // A stream error usually means the cached-session URLs went bad (expired
    // baked token, dead public session). Drop the cache entry so the rebuild
    // takes the fresh-session path - tokenless public URLs with a
    // known-good credential - instead of re-baking whatever just failed.
    await SessionCache.clear(itemId: itemId, episodeId: episodeId);

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
      forceStartTime: true,
      episodeId: episodeId,
      episodeTitle: episodeTitle,
      libraryId: libraryId,
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
    _nativeAutoAdvanceSub?.cancel();
    _bgSaveTimer?.cancel();
    _lastSyncSecond = -1;
    _lastBgProcessedSec = -1;
    _lastChapterCheckSec = -1;
    _lastKnownPositionSec = 0;
    _lastServerSync = DateTime.now();
    _lastAccrual = DateTime.now();
    _lastAccrualPos = null;
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
      if (_currentItemId == null || _player == null || !_player!.playing)
        return;
      final pos = position;
      final posSec = pos.inMilliseconds / 1000.0;
      if (posSec <= 0) return;
      await _saveProgressLocal(pos);
      // Backstop: if the position stream is frozen (Doze), this still banks
      // listening. Shares _lastAccrual so it can't double-count live ticks.
      await _accrueListening(pos);
    });

    // Attach equalizer to current audio session
    _attachEqualizer();

    // Native iOS engine fires bookAutoAdvancedStream when it has swapped to
    // the pre-buffered next book. Empty stream on Android / iOS-flag-off, so
    // this is a no-op everywhere else.
    _nativeAutoAdvanceSub?.cancel();
    _nativeAutoAdvanceSub = _player?.bookAutoAdvancedStream.listen((_) {
      if (_preloadedNextBook != null) {
        debugPrint(
          '[NativeEngine] bookAutoAdvanced received — firing auto-queue advance',
        );
        _onAutoQueueAdvanced();
      }
    });

    // ─── Primary completion detection via processingState ───
    // This fires reliably when ExoPlayer reaches STATE_ENDED, before any
    // position-reset can confuse the position-based detection.
    _completionSub = _player?.processingStateStream.listen(
      (state) {
        if (state == ProcessingState.completed && _currentItemId != null) {
          if (_preloadedNextBook != null) {
            debugPrint(
              '[PreBuffer] processingState=completed with pre-buffer loaded — firing auto-queue advance',
            );
            _onAutoQueueAdvanced();
          } else {
            _onPlaybackComplete();
          }
        }
        // Notify UI when buffering/loading state changes so spinners update.
        // Skip when backgrounded - no visible UI to rebuild; flushed on foreground.
        if (!_isBackgrounded &&
            (state == ProcessingState.ready ||
                state == ProcessingState.loading ||
                state == ProcessingState.buffering)) {
          notifyListeners();
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[Player] processingState stream error: $e');
        _attemptStreamRetry(e);
      },
    );
    _syncSub = _player?.positionStream.listen(
      (trackRelativePos) async {
        // Reset retry counter on successful position updates
        _streamRetryCount = 0;
        // Convert track-relative position to absolute book position
        final absolutePos = position; // uses the getter which adds track offset
        final sec = absolutePos.inSeconds;
        final posSec = absolutePos.inMilliseconds / 1000.0;

        // After a track advance, push once now that the new position has landed
        // so the background lock screen isn't left stale until foreground.
        if (_pendingTrackAdvanceRefresh) {
          _pendingTrackAdvanceRefresh = false;
          _handler?.refreshPlaybackState();
        }

        // ─── Position-reset guard ────────────────────────────
        // ExoPlayer can seek to 0 on STATE_ENDED. If we were near the end
        // and suddenly jump to near 0 without a user seek, treat it as
        // completion rather than restarting playback.
        if (_lastKnownPositionSec > 0 && _totalDuration > 0) {
          final wasNearEnd = _lastKnownPositionSec >= _totalDuration - 5.0;
          final nowNearStart = posSec < 2.0;
          if (wasNearEnd && nowNearStart) {
            if (_preloadedNextBook != null) {
              debugPrint(
                '[PreBuffer] Position jump near-end → 0 with pre-buffer loaded — firing auto-queue advance',
              );
              _onAutoQueueAdvanced();
              return;
            }
            debugPrint(
              '[Player] Position jumped from ${_lastKnownPositionSec.toStringAsFixed(1)}s to ${posSec.toStringAsFixed(1)}s — treating as completion',
            );
            _onPlaybackComplete();
            return;
          }
        }
        if (posSec > 0) _lastKnownPositionSec = posSec;

        _maybePreloadNextBook();

        // On iOS in background, fire the cross-book transition just before the
        // current item ends. The native handover swaps the player item in one
        // step, keeping the AVPlayer rate continuous so iOS doesn't drop the
        // background route. Foreground still uses the regular auto-advance path.
        if (Platform.isIOS &&
            _isBackgrounded &&
            _preloadedNextBook != null &&
            !_autoQueueAdvancing &&
            _totalDuration > 0 &&
            (_player?.playing ?? false)) {
          final remaining = _totalDuration - posSec;
          if (remaining > 0 && remaining <= 0.5) {
            debugPrint(
              '[PreBuffer] Proactive iOS transition at remaining=${remaining.toStringAsFixed(2)}s',
            );
            _onAutoQueueAdvanced();
            return;
          }
        }

        if (sec <= 0) return;

        // In background, only process once per second to save CPU.
        if (_isBackgrounded) {
          if (sec == _lastBgProcessedSec) return;
          _lastBgProcessedSec = sec;
        }

        // ─── Chapter change detection ──────────────────────────
        // Update notification subtitle when the chapter changes.
        // Throttled to once per second — chapters can't change faster than that.
        if (_chapters.isNotEmpty &&
            _currentItemId != null &&
            sec != _lastChapterCheckSec) {
          _lastChapterCheckSec = sec;
          int chapterIdx = -1;
          String? chapterTitle;
          double chapterStart = 0;
          double chapterEnd = _totalDuration;

          // Fast path: check if still in the cached chapter
          if (_lastNotifiedChapterIndex >= 0 &&
              _lastNotifiedChapterIndex < _chapters.length) {
            final ch =
                _chapters[_lastNotifiedChapterIndex] as Map<String, dynamic>;
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

          // Within the grace window past the last chapter, keep the last one
          if (chapterIdx < 0) {
            final g = ChapterLookup.indexAtWithGrace(_chapters, posSec, _totalDuration);
            if (g != null) {
              final ch = _chapters[g] as Map<String, dynamic>;
              chapterIdx = g;
              chapterTitle = ch['title'] as String?;
              chapterStart = (ch['start'] as num?)?.toDouble() ?? 0;
              chapterEnd = (ch['end'] as num?)?.toDouble() ?? _totalDuration;
            }
          }

          if (chapterIdx < 0 && _lastNotifiedChapterIndex >= 0) {
            // Position left the chapter span entirely - clear the stale
            // chapter so the notification stops claiming the last one
            debugPrint(
              '[Battery] Chapter cleared: ${posSec.toStringAsFixed(1)}s is outside the chapter span',
            );
            _lastNotifiedChapterIndex = -1;
            _currentChapterStart = 0;
            _currentChapterEnd = _totalDuration;
            _pushMediaItem(
              _currentItemId!,
              _currentTitle ?? '',
              _currentAuthor ?? '',
              _currentCoverUrl,
              _totalDuration,
            );
          }

          if (chapterIdx >= 0 && chapterIdx != _lastNotifiedChapterIndex) {
            debugPrint(
              '[Battery] Chapter change: idx=$chapterIdx "$chapterTitle" at ${posSec.toStringAsFixed(1)}s',
            );
            _lastNotifiedChapterIndex = chapterIdx;
            _currentChapterStart = chapterStart;
            _currentChapterEnd = chapterEnd;
            _pushMediaItem(
              _currentItemId!,
              _currentTitle ?? '',
              _currentAuthor ?? '',
              _currentCoverUrl,
              _totalDuration,
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
          if (_preloadedNextBook != null && _isBackgrounded && Platform.isIOS) {
            debugPrint(
              '[PreBuffer] Position-fallback near end with pre-buffer loaded — firing auto-queue advance',
            );
            _onAutoQueueAdvanced();
            return;
          }
          _onPlaybackComplete();
          return;
        }

        // Save locally every 5 seconds (always works, even offline)
        if (sec % 5 == 0 && sec != _lastSyncSecond && _currentItemId != null) {
          _lastSyncSecond = sec;
          _saveProgressLocal(absolutePos);
          // Seeks emit position events while paused too (auto-rewind on
          // resume, scrubbing), and such a tick must not accrue or sync -
          // the clocks are stale from the pause, so it would credit the
          // paused span as listening. The pause handler already banked the
          // playing tail.
          if (_player?.playing != true) return;
          // Bank listening to durable storage every tick, decoupled from the
          // server push below, so an abrupt kill loses at most one tick.
          await _accrueListening(absolutePos);
          if (_isCachedStartReconcilePending) return;

          // Push to server every 20s regardless of foreground state, in line
          // with the other ABS clients (official 15s, web 10s). Accuracy rides
          // on the accrual above, not this cadence - this is just server
          // freshness.
          const syncInterval = 20;
          final sinceLastSync = DateTime.now()
              .difference(_lastServerSync)
              .inSeconds;
          if (sinceLastSync >= syncInterval && !_positionSyncInProgress) {
            _positionSyncInProgress = true;
            try {
              final manualOffline =
                  (_prefs ?? await SharedPreferences.getInstance()).getBool(
                    'manual_offline_mode',
                  ) ??
                  false;

              // If we're online but lost the playback session (e.g. pause-
              // timeout closed it and _resumeServerSync silently failed when
              // playback resumed), recreate it before the accumulator branch.
              // Without this the offline accumulator fills for hours and gets
              // dumped later as one phantom session with startTime==lastTime.
              // Skipped for local-session plays — they never open a /play session.
              if (!_localSessionMode &&
                  !manualOffline &&
                  !_isOfflineMode &&
                  _playbackSessionId == null &&
                  _api != null &&
                  _currentItemId != null &&
                  !_recreatingSession) {
                _recreatingSession = true;
                try {
                  final sessionData = _currentEpisodeId != null
                      ? await _api!.startEpisodePlaybackSession(
                          _currentItemId!,
                          _currentEpisodeId!,
                        )
                      : await _api!.startPlaybackSession(_currentItemId!);
                  if (sessionData != null) {
                    _playbackSessionId = sessionData['id'] as String?;
                    if (_playbackSessionId != null) {
                      debugPrint(
                        '[Player] Recreated session in sync tick: '
                        '$_playbackSessionId',
                      );
                      // The playing source still points at the OLD session's
                      // URLs; adopt this one at the next pause/seek.
                      _stashSessionUpgrade(sessionData);
                    }
                  }
                } catch (e) {
                  debugPrint(
                    '[Player] Session recreate in sync tick failed: $e',
                  );
                } finally {
                  _recreatingSession = false;
                }
              }

              // Listening itself is banked every tick by _accrueListening. These
              // branches only handle the interval-rate bookkeeping (time-saved,
              // widget tick) and, for downloaded plays, pushing the local session.
              final secs = sinceLastSync.clamp(0, 300);
              if (_localSessionMode) {
                final online =
                    !manualOffline && !_isOfflineMode && _api != null;
                unawaited(
                  _progressSync.addTimeSaved(secs, _player?.speed ?? 1.0),
                );
                unawaited(HomeWidgetService().addLocalListeningSeconds(secs));
                if (online) await LocalSessionService().pushActive(api: _api!);
                _lastServerSync = DateTime.now();
              } else if (manualOffline ||
                  _isOfflineMode ||
                  _playbackSessionId == null) {
                unawaited(
                  _progressSync.addTimeSaved(secs, _player?.speed ?? 1.0),
                );
                // Widget ticks forward even when the server is unreachable.
                unawaited(HomeWidgetService().addLocalListeningSeconds(secs));
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
              } else if (!_isOfflineMode &&
                  _api != null &&
                  _currentItemId != null) {
                // No session but online - sync via progress update endpoint
                try {
                  final syncKey = _currentEpisodeId != null
                      ? '$_currentItemId-$_currentEpisodeId'
                      : _currentItemId!;
                  final ok = await _progressSync.syncToServer(
                    api: _api!,
                    itemId: syncKey,
                  );
                  if (ok) {
                    debugPrint('[Player] No-session sync succeeded');
                    _positionSyncFailures = 0;
                  } else {
                    _positionSyncFailures++;
                    debugPrint(
                      '[Player] No-session sync returned false (failures=$_positionSyncFailures)',
                    );
                  }
                } catch (e) {
                  _positionSyncFailures++;
                  debugPrint(
                    '[Player] No-session sync error (failures=$_positionSyncFailures): $e',
                  );
                }
              }
            } finally {
              _positionSyncInProgress = false;
            }
          }
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[Player] Position stream error: $e');
        _attemptStreamRetry(e);
      },
    );

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
      if (state == ProcessingState.loading ||
          state == ProcessingState.buffering)
        return;
      // Player is idle/ready but not playing — silent failure
      final currentPos = position.inMilliseconds / 1000.0;
      debugPrint(
        '[Player] Play verify failed: not playing after 3s '
        '(state=${state.name}, pos=${currentPos.toStringAsFixed(1)}s, '
        'posAtPlay=${posAtPlay.toStringAsFixed(1)}s)',
      );
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
      if (state == ProcessingState.loading ||
          state == ProcessingState.buffering) {
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
            debugPrint(
              '[Player] Stuck position detected - re-seeking '
              '(attempt $_stuckReseekAttempts/$_maxStuckReseekAttempts '
              'at ${currentPos.toStringAsFixed(1)}s)',
            );
            await _seekAbsolute(currentPos);
          }
        }
      }

      _stuckCheckLastPosition = currentPos;
    });
  }

  bool _isCompletingBook = false;

  Future<void> _onPlaybackComplete({bool userRequested = false}) async {
    // Alpha: captures completion path choice for GH #186 (book restart bug).
    // Re-entry attempts are logged too so we can see if completion fires
    // multiple times from different signals (processingState, position-jump,
    // fallback) and races with auto-advance.
    debugPrint(
      '[Complete] entry: pos=${_lastKnownPositionSec.toStringAsFixed(1)}s totalDur=${_totalDuration.toStringAsFixed(1)}s item=$_currentItemId ep=$_currentEpisodeId reentry=$_isCompletingBook',
    );
    if (_isCompletingBook) return; // prevent re-entry
    _isCompletingBook = true;

    // ── iOS premature last-track completion guard (GH #219) ──
    // iOS ConcatenatingAudioSource sometimes fires ProcessingState.completed
    // when advancing to the final item without actually rendering its audio.
    // Symptoms: _currentTrackIndex just flipped to the last track, completion
    // fires within seconds (impossible to have played through a multi-minute
    // last track that fast). Spurious-completion check below can't catch this
    // because the position-getter math (trackRel + offset[last]) lands at
    // total duration. Recovery: seek a hair into the last track and resume,
    // which forces AVPlayer to reload that single item correctly.
    if (!userRequested && Platform.isIOS && _trackStartOffsets.length > 2) {
      final lastIdx = _trackStartOffsets.length - 2;
      final lastTrackStart = _trackStartOffsets[lastIdx];
      final lastTrackDur = _trackStartOffsets[lastIdx + 1] - lastTrackStart;
      final advanceTime = _lastIndexAdvanceTime;
      final msSinceAdvance = advanceTime == null
          ? -1
          : DateTime.now().difference(advanceTime).inMilliseconds;
      if (_currentTrackIndex == lastIdx &&
          lastTrackDur > 5.0 &&
          msSinceAdvance >= 0 &&
          msSinceAdvance < 3000 &&
          _iosLastTrackRecoveryAttempts < _maxIosLastTrackRecoveries) {
        _iosLastTrackRecoveryAttempts++;
        final recoveryTarget = lastTrackStart + 0.5;
        debugPrint(
          '[Player] iOS premature last-track completion detected '
          '(idx=$_currentTrackIndex/$lastIdx, lastTrackDur=${lastTrackDur.toStringAsFixed(1)}s, '
          'advance=${msSinceAdvance}ms ago) — recovery attempt $_iosLastTrackRecoveryAttempts: '
          'seeking to ${recoveryTarget.toStringAsFixed(1)}s',
        );
        _logEvent(
          PlaybackEventType.pause,
          detail: 'iOS premature completion blocked',
        );
        _isCompletingBook = false;
        try {
          await _seekAbsolute(recoveryTarget);
          await _player?.play();
        } catch (e) {
          debugPrint('[Player] iOS last-track recovery failed: $e');
        }
        return;
      }
    }

    // Sanity check: if we're not near the end of the book, this is a spurious
    // completion signal (iOS AVPlayer can fire completed on audio interruptions,
    // buffer errors, etc.). Save current position and stop - don't mark finished
    // or advance the queue.
    if (!userRequested &&
        _totalDuration > 0 &&
        _lastKnownPositionSec > 0 &&
        _lastKnownPositionSec < _totalDuration * 0.9 &&
        _lastKnownPositionSec < _totalDuration - 30) {
      debugPrint(
        '[Player] Spurious completion at ${_lastKnownPositionSec.toStringAsFixed(1)}s / ${_totalDuration.toStringAsFixed(1)}s — saving position instead of marking finished',
      );
      _logEvent(PlaybackEventType.pause, detail: 'Spurious completion blocked');
      _syncSub?.cancel();
      _syncSub = null;
      _completionSub?.cancel();
      _completionSub = null;
      _bgSaveTimer?.cancel();
      _bgSaveTimer = null;
      await _player?.stop();
      await _saveProgressLocal(
        Duration(milliseconds: (_lastKnownPositionSec * 1000).round()),
      );
      _isCompletingBook = false;
      notifyListeners();
      return;
    }

    debugPrint('[Player] Book complete: $_currentTitle');
    _logEvent(PlaybackEventType.bookFinished);
    if (_currentEpisodeId == null) {
      unawaited(ReviewService.onBookFinished(isForeground: !_isBackgrounded));
    }

    // Cancel subscriptions first so we don't process stale events.
    _syncSub?.cancel();
    _syncSub = null;
    _completionSub?.cancel();
    _completionSub = null;
    _nativeAutoAdvanceSub?.cancel();
    _nativeAutoAdvanceSub = null;
    _bgSaveTimer?.cancel();
    _bgSaveTimer = null;
    // Android: stop() prevents ExoPlayer's phantom seek-to-0 on completion,
    // which would fire position-stream events that look like a restart.
    // iOS: stop() calls _setPlatformActive(false) which tears down the
    // AVPlayer entirely. The rebuilt AVPlayer for the next item is not
    // granted audio session privileges in background, so audio plays
    // silently and lock screen controls vanish. pause() preserves the
    // platform player + session — paired with darwinLoadControl's
    // automaticallyWaitsToMinimizeStalling=false this gives gapless
    // background auto-advance. GH #244.
    if (Platform.isAndroid) {
      await _player?.stop();
    } else {
      await _player?.pause();
    }

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
              itemId,
              episodeId,
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

    // Local-session play: push the final accrued listening and finalize before
    // any auto-advance begins a new session (awaited to avoid racing it).
    if (_localSessionMode) {
      _logEvent(PlaybackEventType.sessionEnd, detail: 'local book finished');
      bool pushed = false;
      if (_api != null) {
        pushed = await LocalSessionService().pushActive(api: _api!);
      }
      await LocalSessionService().finalizeActive(pushed: pushed);
    }

    // Notify LibraryProvider before clearing state so it can update isFinished locally.
    if (itemId != null) {
      final key = episodeId != null ? '$itemId-$episodeId' : itemId;
      if (_onBookFinishedCallback != null) {
        _onBookFinishedCallback!(key);
      } else {
        _pendingBookFinishedKey = key;
        debugPrint(
          '[Player] Book-finished callback not registered, buffering key=$key',
        );
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
    if (_isCachedStartReconcilePending) return;
    final ct = pos.inMilliseconds / 1000.0;
    // Use compound key for podcast episodes
    final progressKey = _currentEpisodeId != null
        ? '$_currentItemId-$_currentEpisodeId'
        : _currentItemId!;
    // Incomplete download: the player pins beyond-file positions to the file's
    // end. Don't let that clamped value clobber a further-along saved position
    // (the user's real progress, recoverable once the full file streams or
    // re-downloads). GH #278. Only refuses a backward jump at the clamp point.
    if (_shortLocalDurationSec != null && ct >= _shortLocalDurationSec! - 2.0) {
      final saved = await _progressSync.getSavedPosition(progressKey);
      if (saved > ct + 1.0) {
        debugPrint(
          '[Player] Skipping save ${ct.toStringAsFixed(1)}s — would '
          'clobber further saved ${saved.toStringAsFixed(1)}s from incomplete '
          'download (GH #278)',
        );
        return;
      }
    }
    await _progressSync.saveLocal(
      itemId: progressKey,
      currentTime: ct,
      duration: _totalDuration,
      speed: speed,
    );
    // _logEvent(PlaybackEventType.syncLocal); // too noisy for history
  }

  DateTime _lastServerSync = DateTime.now();
  // Separate from the server-sync clock: drives the every-5s durable accrual so
  // a kill loses at most one tick of listening, independent of how often we POST.
  DateTime _lastAccrual = DateTime.now();
  double? _lastAccrualPos;
  bool _syncRecoveryInProgress = false;
  bool _positionSyncInProgress = false;
  int _positionSyncFailures = 0;
  bool _recreatingSession = false;
  int _playbackGeneration = 0;
  int? _cachedStartReconcileGeneration;

  bool get _isCachedStartReconcilePending =>
      _cachedStartReconcileGeneration == _playbackGeneration;

  /// Bank listening time to the durable store for the active play mode. Called
  /// every ~5s while playing (decoupled from the server POST) so the recorded
  /// total survives a kill. Uses wall-clock elapsed since the last accrual, so
  /// it stays correct at any speed and excludes paused spans (no ticks fire
  /// while paused; [play] restarts the clock).
  Future<void> _accrueListening(Duration absolutePos) async {
    if (_currentItemId == null) return;
    final now = DateTime.now();
    final delta = now.difference(_lastAccrual).inSeconds;
    if (delta <= 0) return;
    final ct = absolutePos.inMilliseconds / 1000.0;
    // A player can report playing while its position sits still - a stalled
    // stream, a dead web audio element. Wall clock alone would bank that span
    // as listening, and the 300s backstop timer keeps doing it for as long as
    // the app is open, so hours of standing still later ship as one phantom
    // session. Only credit a span the position actually moved through, and
    // drop the frozen span rather than carrying it into the next tick.
    final prevPos = _lastAccrualPos;
    _lastAccrualPos = ct;
    if (prevPos != null && (ct - prevPos).abs() < 0.5) {
      _lastAccrual = now;
      debugPrint(
        '[Player] Position frozen at ${ct.toStringAsFixed(1)}s - '
        'not banking ${delta}s as listening',
      );
      return;
    }
    final secs = delta > 300 ? 300 : delta;
    _lastAccrual = now;
    final key = _currentEpisodeId != null
        ? '$_currentItemId-$_currentEpisodeId'
        : _currentItemId!;
    final manualOffline = (_prefs?.getBool('manual_offline_mode')) ?? false;
    if (_localSessionMode) {
      await LocalSessionService().accrue(
        progressKey: key,
        seconds: secs,
        currentTime: ct,
        api: null,
      );
    } else if (manualOffline || _isOfflineMode || _playbackSessionId == null) {
      await _progressSync.addOfflineListeningTime(key, secs);
    } else {
      await _progressSync.addStreamingPendingTime(key, secs);
    }
  }

  Future<void> _syncToServer(Duration pos, {int? timeListenedOverride}) async {
    if (_api == null || _playbackSessionId == null) return;
    if (_isCachedStartReconcilePending) return;
    final ct = pos.inMilliseconds / 1000.0;
    // Incomplete download: stuck at the truncated file's end. Don't push that
    // clamped position to the server (it would move real progress backward) or
    // report the stuck time as listened. GH #278.
    if (_shortLocalDurationSec != null && ct >= _shortLocalDurationSec! - 2.0) {
      return;
    }
    final now = DateTime.now();
    final elapsed =
        timeListenedOverride ??
        now.difference(_lastServerSync).inSeconds.clamp(0, 300);
    _lastServerSync = now;
    // The streaming safety buffer mirrors this same span; read it before the
    // POST so we only clear what the server is about to confirm. A real
    // timeListened (not an override) is what the buffer is shadowing.
    final streamKey = (timeListenedOverride == null && _currentItemId != null)
        ? (_currentEpisodeId != null
              ? '$_currentItemId-$_currentEpisodeId'
              : _currentItemId!)
        : null;
    final pendingBefore = streamKey != null
        ? await _progressSync.getStreamingPendingTime(streamKey)
        : 0;
    if (elapsed > 0) {
      unawaited(
        _progressSync.addTimeSaved(elapsed.toInt(), _player?.speed ?? 1.0),
      );
    }
    // Alpha: volume/sessionId piggybacked for GH #179 (volume falls off).
    // We sample these on each sync tick so drift over time is visible.
    final vol = _player?.volume;
    final eqSid = _player?.androidAudioSessionId;
    debugPrint(
      '[Player] Sync session ${_playbackSessionId!.substring(0, 8)}... | currentTime=${ct.toStringAsFixed(1)}s, timeListened=${elapsed}s, volume=$vol, eqSession=$eqSid',
    );
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
    if (ok && streamKey != null && pendingBefore > 0) {
      unawaited(
        _progressSync.reduceStreamingPendingTime(streamKey, pendingBefore),
      );
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
          ? await _api!.startEpisodePlaybackSession(
              _currentItemId!,
              _currentEpisodeId!,
            )
          : await _api!.startPlaybackSession(_currentItemId!);
      if (sessionData != null) {
        _playbackSessionId = sessionData['id'] as String?;
        debugPrint('[Player] Recovered session: $_playbackSessionId');
        _logEvent(PlaybackEventType.sessionStart, detail: 'recovery');
        _stashSessionUpgrade(sessionData);
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
  bool _seekedWhilePaused = false;
  // Origin of the playItem in flight, read by the play paths to decide
  // whether to wait on the server's saved position. See playItem().
  bool _playFromUi = false;
  bool _wasPlayingBeforeInterrupt = false;
  bool _pauseRequested = false;
  bool get isPauseRequested => _pauseRequested;

  void _markPauseRequested() {
    _pauseRequested = true;
  }

  // Storm guard for the idle-on-resume re-init path. A book the player can't
  // start (e.g. a thousands-of-files book the engine never leaves `idle` on)
  // would otherwise re-init in a tight loop, opening a new server play session
  // each pass. Cap re-inits within a short window.
  int _idleReinitCount = 0;
  DateTime? _lastIdleReinit;
  static const _idleReinitWindow = Duration(seconds: 10);
  static const _idleReinitMaxAttempts = 3;

  /// Auto-rewind calculation using linear scaling.
  /// Scales linearly from minRewind at activationDelay to maxRewind at 1 hour.
  /// activationDelay = minimum pause before rewind kicks in (0 = always).
  static double calculateAutoRewind(
    Duration pauseDuration,
    double minRewind,
    double maxRewind, {
    double activationDelay = 0,
  }) {
    final pauseSeconds = pauseDuration.inSeconds.toDouble();

    // Don't rewind if pause is shorter than activation delay
    if (pauseSeconds < activationDelay) return 0;

    // Linear from min to max over 1 hour of pause time
    const maxPause = 3600.0; // 1 hour = full rewind
    final effectivePause = (pauseSeconds - activationDelay).clamp(
      0.0,
      maxPause,
    );
    final t = effectivePause / maxPause;
    final rewind = minRewind + (maxRewind - minRewind) * t;
    return rewind.clamp(minRewind, maxRewind);
  }

  /// [fromUi] marks a play started from the app's own screen. Only those
  /// look at the server for a position another device may have advanced,
  /// and only before audio starts. Headphones, notification, widget, lock
  /// screen and Android Auto plays resume where the phone left off, right
  /// away - if you switched devices you'll open the app, and a jump a few
  /// seconds into playback is worse than starting where you paused.
  Future<void> play({String? logDetail, bool fromUi = false}) async {
    _pauseRequested = false;
    debugPrint(
      '[Service] play() called — lastPause=${_lastPauseTime != null} fromUi=$fromUi',
    );

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
      debugPrint(
        '[Service] play() on cold-started service - routing to cold-start restore',
      );
      final restore = AudioPlayerService.onColdStartPlayRequested;
      if (restore != null) {
        unawaited(restore());
      } else {
        debugPrint(
          '[Service] No cold-start restore handler registered - ignoring play',
        );
      }
      return;
    }
    if (decision == ColdStartPlayDecision.nothing) {
      debugPrint(
        '[Service] play() called with no current item and no history - ignoring',
      );
      return;
    }

    _pauseStopTimer?.cancel();
    _pauseStopTimer = null;
    _noisyPause =
        false; // User explicitly resumed — allow interrupt-resume again
    _handler?._noisyPauseAt = null; // Clear noisy suppression window
    // A loadOnly playItem left the item paused with no session; this first
    // real play is where listening actually starts, so the session does too.
    final pendingSession = _pendingLoadOnlySession;
    if (pendingSession != null) {
      _pendingLoadOnlySession = null;
      if (_currentItemId == pendingSession.itemId) {
        await LocalSessionService().beginSession(
          progressKey: pendingSession.progressKey,
          libraryItemId: pendingSession.itemId,
          episodeId: pendingSession.episodeId,
          mediaType: pendingSession.episodeId != null ? 'podcast' : 'book',
          duration: pendingSession.duration,
          startTime: position.inMilliseconds / 1000.0,
          displayTitle: pendingSession.title,
          displayAuthor: pendingSession.author,
        );
        // The loadOnly playItem returned before _setupSync, so this session
        // has no completion listener, no position sync, no EQ attach and no
        // stats accrual yet. Without it a hot-loaded book that plays to the
        // end just sits there: completed arrives, nobody reacts, the card
        // stays until a manual stop and the book is never marked finished.
        _setupSync();
      }
    }
    // A seek while paused (user, or the socket adopting another device's
    // position) is the position the user expects to hear next - don't let
    // the server check below override it.
    final seekedWhilePaused = _seekedWhilePaused;
    _seekedWhilePaused = false;
    final adoptedServerPos = fromUi && !seekedWhilePaused
        ? await _adoptServerPositionBeforeResume()
        : false;
    // Coming back within a few minutes of the sleep timer firing means you were
    // awake for it, so put back what its rewind took. Done before the ordinary
    // auto-rewind below so that still applies from the restored position.
    // Moot when we just jumped to another device's position; consume the undo
    // anyway so it can't fire on a later resume.
    if (_player != null) {
      final undoTo = SleepTimerService()
          .takeSleepRewindUndo(_currentItemId, position);
      if (undoTo != null && !adoptedServerPos) {
        await seekTo(undoTo, logDetail: 'sleep rewind undone');
        // seekTo flags a paused seek; this one is ours, not the user's, and
        // the server check has already run, so don't carry it to next resume.
        _seekedWhilePaused = false;
      }
    }
    // Auto-rewind on resume if enabled
    if (_lastPauseTime != null && _player != null) {
      final settings = await AutoRewindSettings.load();
      if (settings.enabled) {
        final pauseDuration = DateTime.now().difference(_lastPauseTime!);
        final rewindSeconds = calculateAutoRewind(
          pauseDuration,
          settings.minRewind,
          settings.maxRewind,
          activationDelay: settings.activationDelay,
        );
        if (rewindSeconds > 0.5) {
          final currentAbsolutePos = position.inMilliseconds / 1000.0;
          final currentSpeed = _player!.speed;
          var newPosSeconds =
              currentAbsolutePos - (rewindSeconds * currentSpeed);
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
          // Log the actual book-time delta: at speed>1.0 it's larger than
          // rewindSeconds, and the chapter barrier may cap it smaller.
          final actualDelta = currentAbsolutePos - newPosSeconds;
          final rewindDetail = currentSpeed == 1.0
              ? '${rewindSeconds.toStringAsFixed(1)}s'
              : '${rewindSeconds.toStringAsFixed(1)}s (${actualDelta.toStringAsFixed(1)}s at ${currentSpeed.toStringAsFixed(2)}x)';
          _logEvent(PlaybackEventType.autoRewind, detail: rewindDetail);
          debugPrint(
            '[Player] Auto-rewind ${rewindSeconds.toStringAsFixed(1)}s '
            '(paused ${pauseDuration.inSeconds}s)',
          );
        }
      }
    }
    _lastPauseTime = null;
    // Reset server sync clock so the first sync after resume doesn't
    // include pause duration as timeListened
    _lastServerSync = DateTime.now();
    _lastAccrual = DateTime.now();
    _lastAccrualPos = null;
    // Re-activate audio session in case a prior stop released it.
    try {
      (await AudioSession.instance).setActive(true);
    } catch (_) {}
    // If the player is idle (source was disposed), we need to fully re-initialize
    // playback instead of just calling play() on an empty player.
    if (_player?.processingState == ProcessingState.idle &&
        _currentItemId != null &&
        _api != null) {
      // Cap re-inits within a window so a book the engine can't start doesn't
      // spin here forever, hammering the server with fresh play sessions.
      final now = DateTime.now();
      if (_lastIdleReinit != null &&
          now.difference(_lastIdleReinit!) < _idleReinitWindow) {
        _idleReinitCount++;
      } else {
        _idleReinitCount = 1;
      }
      _lastIdleReinit = now;
      if (_idleReinitCount > _idleReinitMaxAttempts) {
        debugPrint(
          '[Player] Idle-on-resume re-init capped after $_idleReinitCount attempts — giving up to avoid a retry storm',
        );
        return;
      }
      debugPrint(
        '[Player] Player is idle on resume - re-initializing playback for $_currentItemId (attempt $_idleReinitCount)',
      );
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
        libraryId: _currentLibraryId,
        fromUi: fromUi,
      );
      return;
    }
    // Restart the listening-time clock so the paused span isn't counted as
    // listening on the first sync tick after resume (a long/overnight pause
    // would otherwise be credited as up to 300s of phantom listening).
    _lastServerSync = DateTime.now();
    _lastAccrual = DateTime.now();
    _lastAccrualPos = null;
    // Start playback immediately — don't wait for server calls
    _player?.play();
    // Any paused seek up to this instant belonged to this resume (a socket
    // adoption can land between the check above and here); the flag is for
    // seeks during the NEXT pause.
    _seekedWhilePaused = false;
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
        if (_currentItemId == null || _player == null || !_player!.playing)
          return;
        final pos = position;
        final posSec = pos.inMilliseconds / 1000.0;
        if (posSec <= 0) return;
        await _saveProgressLocal(pos);
        // Backstop accrual for a frozen position stream (Doze); shares
        // _lastAccrual so it never double-counts live ticks.
        await _accrueListening(pos);
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

  /// Pause long enough that another device could plausibly have listened
  /// meanwhile. Shorter pauses resume instantly with no server round trip.
  static const _serverPositionCheckMinPause = Duration(minutes: 2);

  /// Longest an app-screen resume waits on the server before starting where
  /// the phone left off. A late answer is dropped, never seeked to.
  static const _serverPositionCheckCap = Duration(seconds: 2);

  /// Before an app-screen resume, look at the server's saved progress and,
  /// if another device genuinely moved it ahead, start there. Returns true
  /// when the position was adopted. Runs only before audio, capped, and only
  /// after a pause long enough to matter; anything slower starts local.
  Future<bool> _adoptServerPositionBeforeResume() async {
    if (_api == null || _currentItemId == null || _player == null) return false;
    // An idle player is about to be re-initialised through playItem, which
    // reconciles the start position itself.
    if (_player!.processingState == ProcessingState.idle) return false;
    if (_knownOffline || _isOfflineMode) return false;
    if (ChromecastService().isCasting) return false;
    final lastPause = _lastPauseTime;
    if (lastPause == null ||
        DateTime.now().difference(lastPause) < _serverPositionCheckMinPause) {
      return false;
    }
    final manualOffline =
        (_prefs ?? await SharedPreferences.getInstance()).getBool(
          'manual_offline_mode',
        ) ??
        false;
    if (manualOffline) return false;
    final pKey = _currentEpisodeId != null
        ? '$_currentItemId-$_currentEpisodeId'
        : _currentItemId!;
    try {
      final localTs = await _progressSync.getSavedTimestamp(pKey);
      final serverProgress = await _api!
          .getItemProgress(pKey)
          .timeout(_serverPositionCheckCap, onTimeout: () => null);
      if (serverProgress == null) {
        debugPrint(
          '[Player] Resume server-check (pre-start): no answer within ${_serverPositionCheckCap.inMilliseconds}ms - starting local',
        );
        return false;
      }
      final serverPos = (serverProgress['currentTime'] as num?)?.toDouble() ?? 0;
      final serverTs = (serverProgress['lastUpdate'] as num?)?.toInt() ?? 0;
      final localPos = position.inMilliseconds / 1000.0;
      // Timestamp gate, like the sync path: our own pre-rewind position still
      // sits on the server after a resume, so position alone would call every
      // auto-rewind "server ahead".
      final ahead = serverTs > localTs && serverPos > localPos + 5.0;
      debugPrint(
        '[Player] Resume server-check (pre-start): server=${serverPos}s(ts=$serverTs) vs local=${localPos}s(ts=$localTs) -> ${ahead ? "SEEKING" : "keep local"}',
      );
      if (!ahead) return false;
      await _seekAbsolute(serverPos);
      _logEvent(
        PlaybackEventType.seek,
        detail: 'adopted server position ${serverPos.toStringAsFixed(1)}s before resume',
      );
      return true;
    } catch (e) {
      debugPrint('[Player] Resume server-check (pre-start) failed: $e');
      return false;
    }
  }

  /// Re-create the server session after a pause long enough to have closed
  /// it. Runs in the background so play() returns instantly. Position is not
  /// touched here: once audio is running we never seek it out from under the
  /// listener (see play()).
  void _resumeServerSync() async {
    if (_api == null || _currentItemId == null) return;
    if (_recreatingSession) return;
    if (_playbackSessionId != null) return;
    final manualOffline =
        (_prefs ?? await SharedPreferences.getInstance()).getBool(
          'manual_offline_mode',
        ) ??
        false;
    if (manualOffline || _isOfflineMode || _localSessionMode) {
      debugPrint(
        '[Player] Skipping session re-create on resume (manualOffline=$manualOffline, isOffline=$_isOfflineMode, localSession=$_localSessionMode)',
      );
      return;
    }
    _recreatingSession = true;
    try {
      final sessionData = _currentEpisodeId != null
          ? await _api!.startEpisodePlaybackSession(
              _currentItemId!,
              _currentEpisodeId!,
            )
          : await _api!.startPlaybackSession(_currentItemId!);
      if (sessionData != null) {
        _playbackSessionId = sessionData['id'] as String?;
        debugPrint(
          '[Player] Re-created session on resume: $_playbackSessionId',
        );
        _stashSessionUpgrade(sessionData);
      }
    } catch (e) {
      debugPrint('[Player] Failed to re-create session on resume: $e');
    } finally {
      _recreatingSession = false;
    }
  }

  Future<void> pause() async {
    _markPauseRequested();
    debugPrint('[Service] pause() called');
    _playVerifyTimer?.cancel();
    _wasPlayingBeforeInterrupt = false;
    _lastPauseTime = DateTime.now();
    // Stamp BT-route observation for AA-disconnect phantom-click detection.
    // Fire-and-forget: pause shouldn't block on a native call.
    unawaited(
      _isBluetoothAudioConnected().then((bt) {
        if (bt) _lastPlayedOnBtAt = DateTime.now();
      }),
    );
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
    debugPrint(
      '[Player] Saving on pause: ${(pos.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
    );
    await _saveProgressLocal(pos);

    // Check manual offline before syncing
    final manualOffline =
        (_prefs ?? await SharedPreferences.getInstance()).getBool(
          'manual_offline_mode',
        ) ??
        false;

    // Credit listening right up to the pause for whatever mode is active — we
    // were playing until now — then let the push below ship it. resume (play())
    // restarts both clocks so the paused span is never counted. Runs even under
    // manual offline since accrual works offline.
    await _accrueListening(pos);
    if (_localSessionMode) {
      final online = !manualOffline && !_isOfflineMode && _api != null;
      if (online) unawaited(LocalSessionService().pushActive(api: _api!));
      _lastServerSync = DateTime.now();
      _lastAccrual = DateTime.now();
    }

    if (manualOffline) return;

    if (!_isOfflineMode && _playbackSessionId != null) {
      await _syncToServer(pos);
    } else if (!_isOfflineMode && _currentItemId != null && _api != null) {
      final syncKey = _currentEpisodeId != null
          ? '$_currentItemId-$_currentEpisodeId'
          : _currentItemId!;
      _progressSync.syncToServer(api: _api!, itemId: syncKey);
    }

    // Paused audio is the other free moment to adopt a waiting session's
    // tokenless URLs - the rebuild is inaudible and playback resumes on a
    // source that can't hit token expiry.
    if (_pendingSessionUpgrade != null) {
      unawaited(_applyPendingSessionUpgrade(resumeAfter: false));
    }

    // After 10 min paused, close the server session so we don't inflate
    // listening stats with paused time. We deliberately keep the AudioSession
    // active and the player paused (not stopped) so the foreground service
    // stays in foreground state and the MediaSession stays alive - this is
    // what keeps notification / lock screen / Bluetooth / WearOS controls
    // responsive after a long pause. Same pattern as Spotify and Pocket Casts.
    _pauseStopTimer?.cancel();
    _pauseStopTimer = Timer(_pauseStopTimeout, () async {
      debugPrint('[Player] Pause timeout - releasing server session');
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
      // Cancel sleep timer
      if (SleepTimerService().isActive) {
        SleepTimerService().cancel();
      }
    });
  }

  Future<void> togglePlayPause({bool fromUi = false}) async {
    debugPrint('[Service] togglePlayPause() — isPlaying=$isPlaying');
    if (isPlaying) {
      await pause();
    } else {
      await play(fromUi: fromUi);
    }
  }

  Future<void> seekTo(
    Duration pos, {
    PlaybackEventType logAs = PlaybackEventType.seek,
    String? logDetail,
  }) async {
    // While this item is casting, the Chromecast is the real player - route
    // the seek there too or bookmark/chapter jumps only move the stopped
    // local player (GH #273).
    final cast = ChromecastService();
    if (cast.isCasting &&
        _currentItemId != null &&
        cast.castingItemId == _currentItemId &&
        cast.castingEpisodeId == _currentEpisodeId) {
      await cast.seekTo(pos);
    }
    _resetStuckDetection();
    if (_player != null && !_player!.playing) _seekedWhilePaused = true;
    final from = position;
    await _seekAbsolute(pos.inMilliseconds / 1000.0);
    _logEvent(
      logAs,
      detail: logDetail ?? '${_formatPos(from)} → ${_formatPos(pos)}',
      overridePosition: from.inMilliseconds / 1000.0,
    );
    notifyListeners();
  }

  /// Rewind triggered by the sleep timer firing. Same mechanics as a manual
  /// seek-back, but logged as an auto-rewind so the playback history reads
  /// "Auto-rewound 15m (sleep timer)" instead of a raw seek (GH #232).
  Future<void> sleepTimerRewind(int seconds) async {
    if (seconds <= 0) return;
    var target = position - Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    final amount = seconds % 60 == 0 ? '${seconds ~/ 60}m' : '${seconds}s';
    await seekTo(
      target,
      logAs: PlaybackEventType.autoRewind,
      logDetail: '$amount (sleep timer)',
    );
  }

  Future<void> skipForward([int seconds = 30]) async {
    if (_player == null) return;
    _resetStuckDetection();
    if (!_player!.playing) _seekedWhilePaused = true;
    // Multiply by speed so the skip feels like the configured amount of real time
    final adjusted = (seconds * speed).round();
    debugPrint(
      '[Service] skipForward(${seconds}s × ${speed}x = ${adjusted}s) — playing=${_player!.playing}',
    );
    final newPos = position + Duration(seconds: adjusted);
    await _seekAbsolute(newPos.inMilliseconds / 1000.0);
    _logEvent(
      PlaybackEventType.skipForward,
      detail: '+${seconds}s (${adjusted}s @ ${speed}x)',
    );
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
        if (s <= posS + 0.5) {
          chapterStart = s;
          break;
        }
      }

      final intoChapter = posS - chapterStart;
      // If the rewind would cross the chapter boundary
      if (targetS < chapterStart && intoChapter > 0.5) {
        final now = DateTime.now();
        final recentSnap =
            _lastRewindChapterSnap != null &&
            now.difference(_lastRewindChapterSnap!).inMilliseconds < 2000;
        if (!recentSnap) {
          // Snap to chapter start instead of crossing
          _lastRewindChapterSnap = now;
          await _seekAbsolute(chapterStart);
          _logEvent(
            PlaybackEventType.skipBackward,
            detail: 'snap to chapter start',
          );
          return;
        }
        // Double-tap within 2s - break through the barrier
        _lastRewindChapterSnap = null;
      }
    }

    var n = targetS < 0 ? 0.0 : targetS;
    await _seekAbsolute(n);
    _logEvent(
      PlaybackEventType.skipBackward,
      detail: '-${seconds}s (${adjusted}s @ ${speed}x)',
    );
  }

  Future<void> skipToNextChapter() async {
    if (_player == null || _chapters.isEmpty) return;
    _resetStuckDetection();
    if (!_player!.playing) _seekedWhilePaused = true;
    final posS = position.inMilliseconds / 1000.0;
    final target = ChapterLookup.nextSkipTarget(
      _chapters,
      posS,
      _totalDuration,
    );
    if (target == null) return;
    if (target.finishesItem) {
      debugPrint('[Service] skipToNextChapter → end at ${target.seconds}s');
      _lastKnownPositionSec = target.seconds;
      _logEvent(PlaybackEventType.seek, detail: 'next chapter to end');
      await _onPlaybackComplete(userRequested: true);
      return;
    }
    debugPrint('[Service] skipToNextChapter → ${target.seconds}s');
    await _seekAbsolute(target.seconds);
    _logEvent(PlaybackEventType.seek, detail: 'next chapter');
    notifyListeners();
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
    _logEvent(
      PlaybackEventType.speedChange,
      detail: '${s.toStringAsFixed(2)}x',
    );
    if (_currentItemId != null) {
      PlayerSettings.setBookSpeed(_currentItemId!, s);
      // Re-push MediaItem so the notification/AA duration updates for the
      // new speed (duration is divided by speed for speed-adjusted time).
      if (_handler != null) {
        final chTitle = currentChapter?['title'] as String?;
        _pushMediaItem(
          _mediaItemKey,
          _currentTitle ?? '',
          _currentAuthor ?? '',
          _currentCoverUrl,
          _totalDuration,
          chapter: chTitle,
        );
      }
    }
    // Refresh the PlaybackState so Android Auto's speed badge tracks the rate.
    _handler?.refreshPlaybackState();
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

  Future<void> stop({bool keepSleepTimer = false}) async {
    _pauseStopTimer?.cancel();
    _pauseStopTimer = null;
    _endAdvanceBuffering();
    final wasPlaying = _player?.playing ?? false;
    // Save final position locally
    if (_currentItemId != null) {
      final pos = position;
      debugPrint(
        '[Player] Saving on stop: ${(pos.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
      );
      await _saveProgressLocal(pos);
      // Credit the final playing tail before the push/close below. Skipped when
      // stopped from a paused state so the idle span isn't counted.
      if (wasPlaying) await _accrueListening(pos);
    }

    // Check manual offline before syncing
    final manualOffline =
        (_prefs ?? await SharedPreferences.getInstance()).getBool(
          'manual_offline_mode',
        ) ??
        false;

    if (!manualOffline) {
      // Try server sync. If stop() was called while already paused, we were
      // not playing in the interval since the last sync - pass timeListened=0
      // so the wall-clock diff doesn't inflate server listening stats.
      if (_playbackSessionId != null && _api != null) {
        _logEvent(PlaybackEventType.sessionEnd, detail: 'stop');
        await _syncToServer(
          position,
          timeListenedOverride: wasPlaying ? null : 0,
        );
        try {
          debugPrint('[Player] Closing session (stop)');
          await _api!.closePlaybackSession(_playbackSessionId!);
        } catch (_) {}
      } else if (_currentItemId != null && _api != null) {
        await _progressSync.syncToServer(api: _api!, itemId: _currentItemId!);
      }
    }

    // Local-session play: push the final accrued listening, then finalize.
    // Runs even under manual offline so the session is queued for replay.
    if (_localSessionMode) {
      bool pushed = false;
      if (!manualOffline && _api != null) {
        pushed = await LocalSessionService().pushActive(api: _api!);
      }
      await LocalSessionService().finalizeActive(pushed: pushed);
    }

    await _player?.stop();
    _onPlaybackStateChangedCallback?.call(false);

    _clearState();
    _chapters = [];
    _handler?.updateChaptersQueue(const []);
    // Cancel sleep timer when playback is stopped - unless the caller is
    // handing off to Chromecast, where an armed timer should keep running
    // against the cast session rather than vanish (GH #338).
    if (!keepSleepTimer && SleepTimerService().isActive) {
      SleepTimerService().cancel();
    }
    // Release audio focus so other apps can use it - but not during casting,
    // because deactivating the session can interfere with cast playback.
    if (!ChromecastService().isCasting) {
      debugPrint('[Battery] AudioSession DEACTIVATED (stop)');
      try {
        (await AudioSession.instance).setActive(false);
      } catch (_) {}
    }
  }

  /// Stop playback without saving progress — used by reset progress.
  Future<void> stopWithoutSaving() async {
    _endAdvanceBuffering();
    // Close server session without syncing position
    if (_playbackSessionId != null && _api != null) {
      try {
        debugPrint('[Player] Closing session (reset progress)');
        await _api!.closePlaybackSession(_playbackSessionId!);
      } catch (_) {}
    }
    // Local-session play: queue the accrued listening for replay (the user did
    // listen; resetting position shouldn't erase that).
    if (_localSessionMode) {
      await LocalSessionService().finalizeActive();
    }
    await _player?.stop();
    _clearState();
    _chapters = [];
    _handler?.updateChaptersQueue(const []);
  }

  @override
  void dispose() {
    _endAdvanceBuffering();
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
