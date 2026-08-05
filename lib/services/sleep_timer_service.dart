import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'scoped_prefs.dart';
import 'audio_player_service.dart';
import 'chromecast_service.dart';
import 'sleep_timer_tick_policy.dart';

enum SleepTimerMode { off, time, chapters, episodes }

/// Auto sleep timer settings — automatically start a sleep timer within a time window.
class AutoSleepSettings {
  final bool enabled;
  final int startHour;   // 24h format, e.g. 22 for 10 PM
  final int startMinute;
  final int endHour;     // 24h format, e.g. 6 for 6 AM
  final int endMinute;
  final int durationMinutes; // how many minutes the auto-started timer runs
  final bool useEndOfChapter; // use end-of-chapter mode instead of timed

  const AutoSleepSettings({
    this.enabled = false,
    this.startHour = 22,
    this.startMinute = 0,
    this.endHour = 6,
    this.endMinute = 0,
    this.durationMinutes = 30,
    this.useEndOfChapter = false,
  });

  AutoSleepSettings copyWith({
    bool? enabled, int? startHour, int? startMinute,
    int? endHour, int? endMinute, int? durationMinutes, bool? useEndOfChapter,
  }) => AutoSleepSettings(
    enabled: enabled ?? this.enabled,
    startHour: startHour ?? this.startHour,
    startMinute: startMinute ?? this.startMinute,
    endHour: endHour ?? this.endHour,
    endMinute: endMinute ?? this.endMinute,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    useEndOfChapter: useEndOfChapter ?? this.useEndOfChapter,
  );

  /// Check if the current time is within the auto sleep window.
  bool isInWindow() {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes <= endMinutes) {
      // Same-day window (e.g. 14:00 – 18:00)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight window (e.g. 22:00 – 06:00)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  String get startLabel => _formatTime(startHour, startMinute);
  String get endLabel => _formatTime(endHour, endMinute);

  static String _formatTime(int h, int m) {
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  static Future<AutoSleepSettings> load() async {
    return AutoSleepSettings(
      enabled: await ScopedPrefs.getBool('autoSleep_enabled') ?? false,
      startHour: await ScopedPrefs.getInt('autoSleep_startHour') ?? 22,
      startMinute: await ScopedPrefs.getInt('autoSleep_startMinute') ?? 0,
      endHour: await ScopedPrefs.getInt('autoSleep_endHour') ?? 6,
      endMinute: await ScopedPrefs.getInt('autoSleep_endMinute') ?? 0,
      durationMinutes: await ScopedPrefs.getInt('autoSleep_duration') ?? 30,
      useEndOfChapter: await ScopedPrefs.getBool('autoSleep_endOfChapter') ?? false,
    );
  }

  Future<void> save() async {
    await ScopedPrefs.setBool('autoSleep_enabled', enabled);
    await ScopedPrefs.setInt('autoSleep_startHour', startHour);
    await ScopedPrefs.setInt('autoSleep_startMinute', startMinute);
    await ScopedPrefs.setInt('autoSleep_endHour', endHour);
    await ScopedPrefs.setInt('autoSleep_endMinute', endMinute);
    await ScopedPrefs.setInt('autoSleep_duration', durationMinutes);
    await ScopedPrefs.setBool('autoSleep_endOfChapter', useEndOfChapter);
  }
}

class SleepTimerService extends ChangeNotifier {
  // Singleton
  static final SleepTimerService _instance = SleepTimerService._();
  factory SleepTimerService() => _instance;
  SleepTimerService._();

  final _player = AudioPlayerService();
  final _cast = ChromecastService();

  bool get _isPlaybackActive => _player.isPlaying || _cast.isPlaying;

  // ── State ──
  SleepTimerMode _mode = SleepTimerMode.off;
  
  // Time mode
  Duration _timeRemaining = Duration.zero;
  Duration _initialDuration = Duration.zero;
  Timer? _timer;
  
  // Chapter mode. We stop at the END of _targetChapterIndex, and it's
  // _targetEndSeconds that actually drives the trigger - comparing chapter
  // indices alone dies whenever the position can't be resolved to a chapter.
  int _chaptersRemaining = 0;
  int _targetChapterIndex = -1;
  double _targetEndSeconds = -1;
  StreamSubscription? _positionSub;

  // Where a sleep rewind put us, so hitting play again shortly after can undo
  // it. Falling asleep is what the rewind is for; coming straight back means
  // you were awake for it and shouldn't have to listen through it again.
  static const sleepRewindUndoWindow = Duration(minutes: 5);
  DateTime? _sleepRewoundAt;
  String? _sleepRewoundItemId;
  Duration? _sleepRewoundFrom; // position the timer fired at
  Duration? _sleepRewoundTo; // position after the rewind
  
  // Shake detection
  String _shakeMode = 'addTime'; // 'off', 'addTime', 'resetTimer'
  StreamSubscription? _accelSub;
  DateTime _lastShake = DateTime(2000);
  double _shakeThreshold = 18.0; // m/s² of linear acceleration (gravity excluded); loaded from settings
  static const _shakeCooldown = Duration(seconds: 3);

  // Wind-down warning & fade
  bool _warningSent = false;
  Duration _fadeThreshold = const Duration(seconds: 30);
  double _fadeStartVolume = 1.0; // volume when fade begins
  bool _tickInProgress = false;
  bool _isTriggeringSleep = false;

  // Reset on pause/play
  bool _wasPlaying = false; // tracks play state transitions

  // Tracked locally so tick scheduling doesn't race AudioPlayerService's flag
  // during the lifecycle callback fan-out.
  bool _isBackgrounded = false;

  // ── Getters ──
  SleepTimerMode get mode => _mode;
  Duration get timeRemaining => _timeRemaining;
  Duration get initialDuration => _initialDuration;
  double get timeProgress => _initialDuration.inSeconds > 0
      ? (_timeRemaining.inSeconds / _initialDuration.inSeconds).clamp(0.0, 1.0)
      : 0.0;
  int get chaptersRemaining => _chaptersRemaining;
  bool get isActive => _mode != SleepTimerMode.off;
  String get shakeMode => _shakeMode;

  String get displayLabel {
    if (_mode == SleepTimerMode.time) {
      final totalMins = _timeRemaining.inMinutes;
      if (totalMins > 0) return '${totalMins}m';
      return '<1m';
    } else if (_mode == SleepTimerMode.chapters) {
      return '$_chaptersRemaining ch';
    } else if (_mode == SleepTimerMode.episodes) {
      return 'ep';
    }
    return '';
  }

  // ── Time-based sleep ──
  
  void setTimeSleep(Duration duration) async {
    cancel();
    _mode = SleepTimerMode.time;
    _timeRemaining = duration;
    _initialDuration = duration;
    _warningSent = false;
    final fadeSecs = await PlayerSettings.getSleepFadeDuration();
    _fadeThreshold = Duration(seconds: fadeSecs);
    _startTimeCountdown();
    _startShakeDetection();
    notifyListeners();
    debugPrint('[SleepTimer] Set time sleep: ${duration.inMinutes}m (fade: ${fadeSecs}s)');
  }

  int _tickIntervalSeconds = 5;

  void _startTimeCountdown() {
    _timer?.cancel();
    _wasPlaying = _isPlaybackActive;
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    // Tick every 1s when the app is foregrounded (so the UI countdown looks
    // smooth) or during the fade period (volume ramp needs per-second resolution).
    // Only slow down to 5s when backgrounded and far from the fade - no UI to
    // update, so we save a handful of wake-ups.
    final nearFade = _timeRemaining <= _fadeThreshold + const Duration(seconds: 5);
    final fastTick = nearFade || !_isBackgrounded;
    _tickIntervalSeconds = fastTick ? 1 : 5;
    _timer = Timer.periodic(Duration(seconds: _tickIntervalSeconds), _onTimerTick);
  }

  void _onTimerTick(Timer timer) async {
    if (_tickInProgress) return;
    _tickInProgress = true;
    try {
      if (_mode != SleepTimerMode.time) return;
      final isPlaying = _isPlaybackActive;
      final pauseRequested = !_cast.isCasting && _player.isPauseRequested;
      var action = sleepTimerTickAction(
        timeRemaining: _timeRemaining,
        isPlaybackActive: isPlaying,
        isPauseRequested: pauseRequested,
      );
      if (action == SleepTimerTickAction.wait) {
        _wasPlaying = false;
        return;
      }

      // Detect pause->play transition and reset if setting is on
      if (!_wasPlaying) {
        final resetOnPause = await PlayerSettings.getResetSleepOnPause();
        if (resetOnPause) {
          _timeRemaining = _initialDuration;
          _warningSent = false;
          if (_isFadingOut) {
            _isFadingOut = false;
            _player.setVolume(_fadeStartVolume);
          }
          debugPrint('[SleepTimer] Reset to ${_initialDuration.inMinutes}m on resume');
          onToast?.call('Sleep timer reset: ${_initialDuration.inMinutes}m');
          _scheduleNextTick();
        }
      }
      _wasPlaying = true;

      action = sleepTimerTickAction(
        timeRemaining: _timeRemaining,
        isPlaybackActive: _isPlaybackActive,
        isPauseRequested: !_cast.isCasting && _player.isPauseRequested,
      );
      if (action == SleepTimerTickAction.wait) {
        _wasPlaying = false;
        return;
      }
      if (action == SleepTimerTickAction.trigger) {
        await _triggerSleep();
        return;
      }

      _timeRemaining -= Duration(seconds: _tickIntervalSeconds);
      // Switch to fast ticks when approaching fade threshold
      if (_tickIntervalSeconds > 1 &&
          _timeRemaining <= _fadeThreshold + const Duration(seconds: 5)) {
        _scheduleNextTick();
      }

      // Wind-down: vibration + optional fade + optional chime
      if (!_warningSent && _timeRemaining <= _fadeThreshold && _timeRemaining.inSeconds > 0) {
        _warningSent = true;
        onToast?.call('Sleep timer ending soon...');
        final fadeEnabled = await PlayerSettings.getSleepFadeOut();
        if (fadeEnabled && !_cast.isCasting) {
          _isFadingOut = true;
          _fadeStartVolume = _player.volume;
          debugPrint('[SleepTimer] Warning: ${_timeRemaining.inSeconds}s remaining - starting fade (${_fadeThreshold.inSeconds}s)');
        } else {
          debugPrint('[SleepTimer] Warning: ${_timeRemaining.inSeconds}s remaining');
        }
        // Play chime sound if enabled
        final chimeEnabled = await PlayerSettings.getSleepChime();
        if (chimeEnabled) _playChime();
      }

      // Gradually lower volume during the fade period
      if (_isFadingOut && _timeRemaining.inSeconds > 0 && !_cast.isCasting) {
        final fraction = _timeRemaining.inSeconds / _fadeThreshold.inSeconds;
        _player.setVolume((_fadeStartVolume * fraction).clamp(0.0, 1.0));
      }

      notifyListeners();
    } finally {
      _tickInProgress = false;
    }
  }

  /// Add time (used by shake reset in time mode, or manual add)
  void addTime(Duration extra) {
    if (_mode != SleepTimerMode.time) return;
    _timeRemaining += extra;
    // Reset warning and restore volume if we're above threshold again
    if (_timeRemaining > _fadeThreshold) {
      _warningSent = false;
      if (_isFadingOut) {
        _isFadingOut = false;
        _player.setVolume(_fadeStartVolume);
      }
    }
    // Reschedule in case we jumped between slow/fast tick zones
    if (_timer?.isActive == true) _scheduleNextTick();
    notifyListeners();
    debugPrint('[SleepTimer] Added ${extra.inMinutes}m — now ${_timeRemaining.inMinutes}m');
  }

  // ── Chapter-based sleep ──

  /// Pause this many seconds before the target chapter ends. On the final
  /// chapter that stops the player from ever "completing" and handing off to
  /// the next book.
  static const _chapterEndGuardSec = 2.5;

  /// A chapter with less than this left isn't worth stopping at - the timer
  /// would expire almost the moment it started - so aim at the next one.
  static const _minChapterRemainingSec = 60;

  void setChapterSleep(int numChapters) {
    cancel();

    final chapters = _chapterList();
    final currentIdx = _getCurrentChapterIndex();
    if (chapters.isEmpty || currentIdx < 0 || _positionStream() == null) {
      // Arming here would leave a timer that reads as active but can never
      // fire, and an active timer blocks auto sleep from ever retrying. Stay
      // off instead so the next resume or foreground check has another go.
      debugPrint('[SleepTimer] Chapter sleep not started: '
          '${chapters.isEmpty ? "no chapters loaded" : currentIdx < 0 ? "position is outside every chapter" : "no position stream"}');
      return;
    }

    // numChapters counts the current chapter, so stop at the end of
    // current + numChapters - 1.
    var target = (currentIdx + numChapters - 1).clamp(0, chapters.length - 1);

    // Resuming right after a sleep can leave the position all but on top of
    // the boundary we stopped at, and aiming there again would sleep within
    // seconds. Judged on how much is actually left to hear, not on whether we
    // slept here: sleep-rewind can be anything up to two hours, and a 15
    // minute rewind leaves a real 15 minutes to listen, so that should still
    // stop at this same boundary rather than running on into the next chapter.
    final pos = _currentPositionSeconds();
    while (target + 1 < chapters.length &&
        _chapterEnd(target) - pos < _minChapterRemainingSec) {
      target += 1;
      debugPrint('[SleepTimer] Under ${_minChapterRemainingSec}s left here - '
          'targeting chapter $target instead');
    }

    _mode = SleepTimerMode.chapters;
    _targetChapterIndex = target;
    _targetEndSeconds = _chapterEnd(target);
    _chaptersRemaining = (target - currentIdx + 1).clamp(0, 999);
    debugPrint('[SleepTimer] Set chapter sleep: current=$currentIdx '
        'target=$target end=${_targetEndSeconds.toStringAsFixed(0)}s');

    _startChapterMonitor();
    _startShakeDetection();
    notifyListeners();
  }

  /// Cast position stream when casting, local player stream otherwise. Null
  /// only while casting without a stream attached.
  Stream<Duration>? _positionStream() =>
      _cast.isCasting ? _cast.castPositionStream : _player.positionStream;

  void _startChapterMonitor() {
    _positionSub?.cancel();
    final stream = _positionStream();
    if (stream == null) return;
    _positionSub = stream.listen((pos) {
      if (!_isPlaybackActive) return;
      if (_targetEndSeconds <= 0) return;

      // Trigger off the position, not the chapter index: a position that lands
      // in a gap between chapters resolves to no index at all.
      if (_currentPositionSeconds() >= _targetEndSeconds - _chapterEndGuardSec) {
        unawaited(_triggerSleep());
        return;
      }

      final currentIdx = _getCurrentChapterIndex();
      if (currentIdx < 0) return;
      final remaining = (_targetChapterIndex - currentIdx + 1).clamp(0, 999);
      if (remaining != _chaptersRemaining) {
        _chaptersRemaining = remaining;
        notifyListeners();
      }
    });
  }

  /// Add a chapter (used by shake reset in chapter mode, or manual add)
  void addChapter() {
    if (_mode != SleepTimerMode.chapters) return;
    final chapters = _chapterList();
    if (_targetChapterIndex + 1 >= chapters.length) {
      debugPrint('[SleepTimer] Already targeting the last chapter — nothing to add');
      return;
    }
    _targetChapterIndex++;
    _targetEndSeconds = _chapterEnd(_targetChapterIndex);
    _chaptersRemaining++;
    notifyListeners();
    debugPrint('[SleepTimer] Added 1 chapter — now $_chaptersRemaining remaining');
  }

  // ── Episode-based sleep (podcasts) ──

  /// Stop at the end of the current podcast episode. Implemented as the
  /// end-of-chapter analog: we pause a few seconds before the episode's natural
  /// end so the player never "completes". That keeps every queue auto-advance
  /// path (manual / auto_next / playlist, gapless or not) from firing, so it
  /// works the same in any queue mode. Rewind-on-sleep masks the small gap.
  void setEpisodeSleep() {
    cancel();
    _mode = SleepTimerMode.episodes;
    _startEpisodeMonitor();
    notifyListeners();
    debugPrint('[SleepTimer] Set episode sleep (stop at end of current episode)');
  }

  // Pause this many seconds before the episode end. Wide enough that a 1 Hz
  // position tick reliably lands in the window before any auto-advance triggers.
  static const _episodeEndGuardSec = 2.5;

  void _startEpisodeMonitor() {
    _positionSub?.cancel();
    // Targets local playback; while casting totalDuration is 0 so this no-ops.
    _positionSub = _player.positionStream.listen((_) {
      if (_mode != SleepTimerMode.episodes) return;
      if (!_isPlaybackActive) return;
      final totalSec = _player.totalDuration;
      if (totalSec <= 0) return;
      final posSec = _player.position.inMilliseconds / 1000.0;
      if (posSec >= totalSec - _episodeEndGuardSec) {
        unawaited(_triggerSleep());
      }
    });
  }

  // ── Common ──

  List<dynamic> _chapterList() =>
      _cast.isCasting ? _cast.castingChapters : _player.chapters;

  double _currentPositionSeconds() => _cast.isCasting
      ? _cast.castPosition.inMilliseconds / 1000.0
      : _player.position.inMilliseconds / 1000.0;

  double _chapterEnd(int index) {
    final chapters = _chapterList();
    if (index < 0 || index >= chapters.length) return -1;
    final ch = chapters[index] as Map<String, dynamic>;
    return (ch['end'] as num?)?.toDouble() ?? -1;
  }

  int _getCurrentChapterIndex() {
    final chapters = _chapterList();
    if (chapters.isEmpty) return -1;
    final pos = _currentPositionSeconds();
    // Falls back to the last chapter that has started, so a position sitting in
    // a gap between chapters or past the final end still resolves instead of
    // reporting "no chapter" and stalling everything downstream.
    int started = -1;
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i] as Map<String, dynamic>;
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? 0;
      if (pos >= start && pos < end) return i;
      if (pos >= start) started = i;
    }
    return started;
  }

  bool _isFadingOut = false;
  bool get isFadingOut => _isFadingOut;

  Future<void> _triggerSleep() async {
    if (_isTriggeringSleep) return;
    final pauseRequested = !_cast.isCasting && _player.isPauseRequested;
    if (!_isPlaybackActive || pauseRequested) {
      _wasPlaying = false;
      return;
    }
    _isTriggeringSleep = true;
    debugPrint('[SleepTimer] Triggering sleep — pausing playback');
    try {
      if (_cast.isCasting) {
        await _cast.pause();
      } else {
        await _player.pause();
        // Restore volume so next playback starts at normal level
        _player.setVolume(_fadeStartVolume);
        // Auto-rewind so the user resumes from a few seconds back
        final rewindSeconds = await PlayerSettings.getEffectiveSleepRewindSeconds(_player.currentItemId);
        if (rewindSeconds > 0) {
          final from = _player.position;
          await _player.sleepTimerRewind(rewindSeconds);
          _sleepRewoundAt = DateTime.now();
          _sleepRewoundItemId = _player.currentItemId;
          _sleepRewoundFrom = from;
          _sleepRewoundTo = _player.position;
          debugPrint('[SleepTimer] Rewound ${rewindSeconds}s');
        }
      }
      _isFadingOut = false;
      cancel();
    } finally {
      _isTriggeringSleep = false;
    }
  }

  /// Position to jump back to when playback resumes soon after a sleep rewind,
  /// or null if there's nothing to undo. Consumed on read, so it only ever
  /// applies once.
  ///
  /// Deliberately separate from the ordinary auto-rewind-on-pause: this only
  /// reverses the extra jump the sleep timer made. Whatever auto-rewind wants
  /// to do afterwards still applies from the restored position.
  Duration? takeSleepRewindUndo(String? itemId, Duration currentPosition) {
    final at = _sleepRewoundAt;
    final from = _sleepRewoundFrom;
    final to = _sleepRewoundTo;
    if (at == null || from == null || to == null) return null;

    void forget() {
      _sleepRewoundAt = null;
      _sleepRewoundItemId = null;
      _sleepRewoundFrom = null;
      _sleepRewoundTo = null;
    }

    if (DateTime.now().difference(at) > sleepRewindUndoWindow) {
      debugPrint('[SleepTimer] Sleep rewind too old to undo');
      forget();
      return null;
    }
    if (itemId == null || itemId != _sleepRewoundItemId) {
      debugPrint('[SleepTimer] Different item since the sleep rewind - not undoing');
      forget();
      return null;
    }
    // Moved since we rewound (a manual seek, or resuming somewhere else), so
    // the rewind is no longer the thing that put us here.
    if ((currentPosition - to).abs() > const Duration(seconds: 2)) {
      debugPrint('[SleepTimer] Position moved since the sleep rewind - not undoing');
      forget();
      return null;
    }
    forget();
    debugPrint('[SleepTimer] Undoing sleep rewind - back to ${from.inSeconds}s');
    return from;
  }

  void cancel() {
    final wasFading = _isFadingOut;
    _isFadingOut = false;
    _timer?.cancel();
    _timer = null;
    _positionSub?.cancel();
    _positionSub = null;
    if (_accelSub != null) debugPrint('[SleepTimer] Accelerometer stream stopped');
    _accelSub?.cancel();
    _accelSub = null;
    _mode = SleepTimerMode.off;
    _timeRemaining = Duration.zero;
    _chaptersRemaining = 0;
    _targetChapterIndex = -1;
    _targetEndSeconds = -1;
    _warningSent = false;
    _autoStarted = false;
    // Restore volume if cancelled during fade-out
    if (wasFading) {
      _player.setVolume(_fadeStartVolume);
    }
    notifyListeners();
    debugPrint('[SleepTimer] Cancelled');
  }

  // ── Haptic feedback ──

  /// Double buzz when shake-snooze adds time
  void _vibrateSnooze() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 150, 100, 150]);
    }
  }

  /// Play a gentle bell chime to warn that sleep timer is ending soon.
  /// Ducks the main player volume briefly so the chime is audible over the
  /// audiobook, then restores it.
  ja.AudioPlayer? _chimePlayer;
  void _playChime() async {
    try {
      final vol = await PlayerSettings.getSleepChimeVolume();
      _chimePlayer?.dispose();
      final chime = ja.AudioPlayer();
      _chimePlayer = chime;
      await chime.setVolume(vol);
      await chime.setAsset('assets/audio/bell.mp3');

      // Duck the main player so the chime cuts through
      final player = AudioPlayerService();
      final prevVol = player.volume;
      final ducked = (prevVol * 0.15).clamp(0.0, 1.0);
      await player.setVolume(ducked);
      debugPrint('[SleepTimer] Chime: playing (vol=$vol, ducked main ${prevVol.toStringAsFixed(2)} -> ${ducked.toStringAsFixed(2)})');

      chime.play();
      chime.playerStateStream.where((s) => s.processingState == ja.ProcessingState.completed).first.then((_) {
        // Restore main player volume after chime finishes
        player.setVolume(prevVol);
        chime.dispose();
        if (_chimePlayer == chime) _chimePlayer = null;
      });
    } catch (e) {
      debugPrint('[SleepTimer] Chime error: $e');
    }
  }


  // ── Shake detection ──

  Future<void> _startShakeDetection() async {
    _shakeMode = await PlayerSettings.getShakeMode();
    if (_shakeMode == 'off') return;

    final sensitivity = await PlayerSettings.getShakeSensitivity();
    _shakeThreshold = PlayerSettings.shakeThresholdFor(sensitivity);

    _accelSub?.cancel();
    debugPrint('[Battery] Accelerometer stream STARTED (shakeMode=$_shakeMode, sensitivity=$sensitivity, threshold=$_shakeThreshold)');
    _accelSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > _shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShake) > _shakeCooldown) {
          _lastShake = now;
          _onShake();
        }
      }
    }, onError: (e) {
      debugPrint('[SleepTimer] Accelerometer error: $e');
    });
  }

  // Toast callback — UI sets this to show snackbars
  void Function(String message)? onToast;

  // ── Auto Sleep Timer ──
  AutoSleepSettings? _autoSleepSettings;
  bool _autoSleepDismissed = false; // user manually cancelled — don't re-trigger this window
  bool _wasInWindow = false; // tracks window transitions to reset dismiss flag
  Timer? _windowBoundaryTimer; // fires once at exact window start time
  bool _autoStarted = false; // current timer was started by auto sleep (not manual)

  /// Load auto sleep settings.
  Future<void> loadAutoSleepSettings() async {
    _autoSleepSettings = await AutoSleepSettings.load();
    _onSettingsUpdated();
  }

  /// Directly update settings (avoids save/load race condition).
  void updateAutoSleepSettings(AutoSleepSettings settings) {
    _autoSleepSettings = settings;
    _onSettingsUpdated();
  }

  void _onSettingsUpdated() {
    final s = _autoSleepSettings;
    debugPrint('[SleepTimer] _onSettingsUpdated enabled=${s?.enabled} window=${s?.startLabel}-${s?.endLabel} mode=${s?.useEndOfChapter == true ? "chapter" : "${s?.durationMinutes}m"} autoStarted=$_autoStarted isActive=$isActive');
    // Cancel stale boundary timer — it was for the old window
    _windowBoundaryTimer?.cancel();
    _windowBoundaryTimer = null;
    // If an auto-started timer is running, tear it down so the new duration /
    // mode / window can take effect on re-evaluation.
    if (_autoStarted && isActive) {
      debugPrint('[SleepTimer] Settings changed — restarting auto-started timer');
      cancel();
    }
    // Re-evaluate with new settings if playing, or schedule boundary
    if (_autoSleepSettings != null && _autoSleepSettings!.enabled) {
      checkAutoSleep();
    }
  }

  AutoSleepSettings? get autoSleepSettings => _autoSleepSettings;

  /// Cancel the sleep timer because the user chose to.
  /// Suppresses auto sleep re-triggering until the window resets.
  void cancelByUser() {
    debugPrint('[SleepTimer] Cancelled by user — suppressing auto sleep for this window');
    _autoSleepDismissed = true;
    _windowBoundaryTimer?.cancel();
    _windowBoundaryTimer = null;
    cancel();
  }

  /// Reset the dismiss flag — call when starting a new book or resetting playback.
  /// This lets auto sleep re-trigger even if the user cancelled it earlier.
  void resetDismiss() {
    _autoSleepDismissed = false;
  }

  /// Called on playback start, resume, and app foreground.
  Future<void> checkAutoSleep() async {
    if (_autoSleepSettings == null) await loadAutoSleepSettings();
    final settings = _autoSleepSettings;
    if (settings == null || !settings.enabled) {
      debugPrint('[SleepTimer] checkAutoSleep: disabled or no settings');
      return;
    }

    final inWindow = settings.isInWindow();
    debugPrint('[SleepTimer] checkAutoSleep: inWindow=$inWindow isActive=$isActive dismissed=$_autoSleepDismissed autoStarted=$_autoStarted');

    // If we just left the window, reset the dismiss flag for next entry
    if (!inWindow && _wasInWindow) {
      _autoSleepDismissed = false;
    }
    _wasInWindow = inWindow;

    if (inWindow) {
      // We're in the window — try to activate
      _windowBoundaryTimer?.cancel();
      _windowBoundaryTimer = null;
      if (!isActive && !_autoSleepDismissed) {
        if (settings.useEndOfChapter) {
          debugPrint('[SleepTimer] Auto sleep: in window ${settings.startLabel}–${settings.endLabel}, '
              'starting end-of-chapter timer');
          setChapterSleep(1);
          onToast?.call('Auto sleep: end of chapter timer started');
        } else {
          debugPrint('[SleepTimer] Auto sleep: in window ${settings.startLabel}–${settings.endLabel}, '
              'starting ${settings.durationMinutes}m timer');
          setTimeSleep(Duration(minutes: settings.durationMinutes));
          onToast?.call('Auto sleep: ${settings.durationMinutes}m timer started');
        }
        _autoStarted = true;
      }
    } else {
      // Not in window yet — schedule a one-shot timer for when it opens
      _scheduleWindowBoundary(settings);
    }
  }

  /// Schedule a single timer that fires when the window starts.
  /// If playback is still going at that moment, starts the sleep timer.
  void _scheduleWindowBoundary(AutoSleepSettings settings) {
    _windowBoundaryTimer?.cancel();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, settings.startHour, settings.startMinute);
    final nextStart = todayStart.isAfter(now) ? todayStart : todayStart.add(const Duration(days: 1));
    final delay = nextStart.difference(now);

    debugPrint('[SleepTimer] Window boundary timer set for ${delay.inMinutes}m from now');
    _windowBoundaryTimer = Timer(delay, () {
      _windowBoundaryTimer = null;
      if (_isPlaybackActive && !isActive && !_autoSleepDismissed) {
        _wasInWindow = true;
        if (settings.useEndOfChapter) {
          debugPrint('[SleepTimer] Window boundary hit — starting end-of-chapter timer');
          setChapterSleep(1);
          onToast?.call('Auto sleep: end of chapter timer started');
        } else {
          debugPrint('[SleepTimer] Window boundary hit — starting ${settings.durationMinutes}m timer');
          setTimeSleep(Duration(minutes: settings.durationMinutes));
          onToast?.call('Auto sleep: ${settings.durationMinutes}m timer started');
        }
        _autoStarted = true;
      }
    });
  }

  void _onShake() async {
    if (!isActive || !_isPlaybackActive) return;
    _shakeMode = await PlayerSettings.getShakeMode();
    if (_shakeMode == 'off') return;
    debugPrint('[SleepTimer] Shake detected! mode=$_shakeMode');

    _vibrateSnooze();

    if (_shakeMode == 'resetTimer') {
      if (_mode == SleepTimerMode.time) {
        _timeRemaining = _initialDuration;
        _warningSent = false;
        notifyListeners();
        onToast?.call('Timer reset to ${_initialDuration.inMinutes}m');
      } else if (_mode == SleepTimerMode.chapters) {
        // For chapter mode, re-count from current position
        onToast?.call('Timer reset');
      }
    } else if (_shakeMode == 'addTime') {
      if (_mode == SleepTimerMode.time) {
        final addMins = await PlayerSettings.getShakeAddMinutes();
        addTime(Duration(minutes: addMins));
        onToast?.call('+$addMins min added!');
      } else if (_mode == SleepTimerMode.chapters) {
        addChapter();
        onToast?.call('+1 chapter added!');
      }
    }
  }

  /// Re-read shake settings and restart the accelerometer stream. Call when
  /// the user changes shake mode or sensitivity from settings UI.
  Future<void> restartShakeDetection() async {
    _accelSub?.cancel();
    _accelSub = null;
    if (isActive) await _startShakeDetection();
  }

  /// Pause battery-intensive operations when app is backgrounded.
  /// Only pauses shake detection if nothing is playing (user might shake
  /// with screen off to extend sleep timer).
  void onAppBackgrounded() {
    _isBackgrounded = true;
    if (!_isPlaybackActive) {
      _accelSub?.cancel();
      _accelSub = null;
      debugPrint('[SleepTimer] Paused shake detection (backgrounded, not playing)');
    }
    // Switch the countdown to 5s ticks - no UI to update while backgrounded.
    if (_mode == SleepTimerMode.time && (_timer?.isActive ?? false)) {
      _scheduleNextTick();
    }
  }

  /// Resume operations when app is foregrounded.
  void onAppForegrounded() {
    _isBackgrounded = false;
    if (isActive && _accelSub == null) {
      _startShakeDetection();
      debugPrint('[SleepTimer] Resumed shake detection (foregrounded)');
    }
    // Switch the countdown back to 1s ticks so the UI countdown is smooth.
    if (_mode == SleepTimerMode.time && (_timer?.isActive ?? false)) {
      _scheduleNextTick();
    }
  }

  @override
  void dispose() {
    cancel();
    _windowBoundaryTimer?.cancel();
    _windowBoundaryTimer = null;
    super.dispose();
  }
}
