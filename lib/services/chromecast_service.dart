import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'api_service.dart';
import 'audio_player_service.dart';
import 'cast_playback_policy.dart';
import 'cast_relay.dart';
import 'dart:convert';
import 'chapter_lookup.dart';
import 'download_service.dart';
import 'local_session_service.dart';
import 'narrated_books.dart';
import 'narration_stream.dart';
import 'progress_sync_service.dart';

enum CastConnectionState { disconnected, connecting, connected }
class ChromecastService extends ChangeNotifier {
  static final ChromecastService _instance = ChromecastService._();
  factory ChromecastService() => _instance;
  ChromecastService._()
    : _pauseCommand = null,
      _playCommand = null,
      _testMediaStatusStream = null,
      _testPositionStream = null,
      _now = DateTime.now;

  /// Narrow command/stream seam for deterministic Cast-control regression tests.
  /// Production construction continues to use the Cast plugin singleton.
  @visibleForTesting
  ChromecastService.forTesting({
    Future<void> Function()? pauseCommand,
    Future<void> Function()? playCommand,
    Stream<CastPlaybackState>? mediaStatusStream,
    Stream<Duration>? positionStream,
    DateTime Function()? now,
  }) : _pauseCommand = pauseCommand,
       _playCommand = playCommand,
       _testMediaStatusStream = mediaStatusStream,
       _testPositionStream = positionStream,
       _now = now ?? DateTime.now {
    _listenToTestStreams();
  }

  final Future<void> Function()? _pauseCommand;
  final Future<void> Function()? _playCommand;
  final Stream<CastPlaybackState>? _testMediaStatusStream;
  final Stream<Duration>? _testPositionStream;
  final DateTime Function() _now;

  /// Whether Chromecast is available in this build. True here; the GMS-free
  /// F-Droid stub sets it false so the UI hides all cast entry points.
  static const bool castSupported = true;

  CastConnectionState _connectionState = CastConnectionState.disconnected;
  CastPlaybackState _playbackState = CastPlaybackState.idle;

  CastConnectionState get connectionState => _connectionState;
  CastPlaybackState get playbackState => _playbackState;
  bool get isConnected => _connectionState == CastConnectionState.connected;
  bool get isCasting => isConnected && _playbackState != CastPlaybackState.idle;
  /// Active receiver playback used by the controls and sleep timer.
  ///
  /// Keep [isPlaying] strict so buffering time is not counted as listening
  /// statistics; a receiver can still be audibly playing while reporting it.
  bool get isReceiverActive => isCastReceiverActive(
    _playbackState,
    lastPositionAdvance: _lastCastPositionAdvanceAt,
    now: _now(),
    isPauseRequested: _castPlaybackIntent.isPauseRequested,
  ) || _castPlaybackIntent.isPlayRequested;
  bool get isPlaying => _playbackState == CastPlaybackState.playing;
  bool get shouldPauseOnToggle => _castPlaybackIntent.isPlayRequested ||
      shouldPauseCastOnToggle(_playbackState, receiverActive: isReceiverActive);

  /// True while a backstop reconnect is being attempted after the sender lost
  /// its connection but the receiver was actively playing (see [_tryReconnect]).
  bool get isReconnecting => _reconnecting;

  /// A cast session that's either live or actively trying to recover from a
  /// dropped sender connection - the sleep timer and other liveness checks
  /// use this instead of [isCasting] so a transient disconnect doesn't read
  /// as "casting stopped" while a backstop reconnect is still in flight.
  bool get isCastEngaged => isCasting || _reconnecting;

  bool _userEndedCast = false;

  /// A cast this phone started and hasn't given up on, even while its
  /// connection to the cast device is down for a moment. The device keeps
  /// playing through that, so nothing should start playing on the phone:
  /// it did, and the book played in both places at once.
  bool get holdsCast =>
      isCastEngaged ||
      (_castingItemId != null && !_userEndedCast && _connectionState == CastConnectionState.connecting);

  String? _castingItemId, _castingEpisodeId, _castingTitle, _castingAuthor, _castingCoverUrl;
  double _castingDuration = 0;
  List<dynamic> _castingChapters = [];
  ApiService? _api;
  Duration _castPosition = Duration.zero;
  DateTime? _lastCastPositionAdvanceAt;
  final CastPlaybackIntent _castPlaybackIntent = CastPlaybackIntent();
  int _playbackCommand = 0;
  CastPlaybackState? _playbackStateBeforePause;
  Timer? _resumeIntentTimer;
  Timer? _bufferingLivenessTimer;
  String? _connectedDeviceName;
  String? _playbackSessionId;
  int? _castPlayMethod;
  DateTime _lastSyncTime = DateTime.now();

  // Backstop reconnect (GH #338). The Cast SDK has its own session-resume
  // machinery, and the manifest now lets it actually run - this only kicks in
  // when that still isn't enough (e.g. the network was down longer than the
  // SDK's own resumption window).
  GoogleCastDevice? _lastConnectedDevice;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _reconnecting = false;
  // Set when the sleep timer fires while a backstop reconnect is in flight,
  // so the pause it wanted to apply lands the instant we're back instead of
  // silently no-oping because nothing was connected at the time.
  Completer<bool>? _pendingSleepPause;

  // Multi-track fallback state (when queueLoadItems fails)
  List<dynamic>? _fallbackTracks;
  List<double>? _fallbackOffsets;
  int _fallbackTrackIdx = -1;
  bool _isAdvancingTrack = false;

  // Multi-track queue state (queueLoadItems succeeded). The Cast SDK reports
  // and accepts positions relative to the CURRENT QUEUE ITEM, so absolute
  // book positions must be translated through these offsets in both
  // directions - sending absolute seconds straight to seek() jumps to the
  // wrong place in any track but the first (GH #273).
  List<double>? _queueOffsets;
  int _queueTrackIdx = 0;

  String? get castingItemId => _castingItemId;
  String? get castingEpisodeId => _castingEpisodeId;
  String? get castingTitle => _castingTitle;
  String? get castingAuthor => _castingAuthor;
  String? get castingCoverUrl => _castingCoverUrl;
  double get castingDuration => _castingDuration;
  List<dynamic> get castingChapters => _castingChapters;
  Duration get castPosition => _castPosition;
  String? get connectedDeviceName => _connectedDeviceName;

  /// Called when a book finishes during cast playback (before state is cleared).
  static void Function(String itemId)? _onBookFinishedCallback;
  static void setOnBookFinishedCallback(void Function(String itemId)? cb) {
    _onBookFinishedCallback = cb;
  }

  /// Called when cast playback state changes (playing/not playing).
  /// Used by LibraryProvider for idle timer / battery-saving lifecycle.
  static void Function(bool isPlaying)? _onPlaybackStateChangedCallback;
  static void setOnPlaybackStateChangedCallback(void Function(bool isPlaying)? cb) {
    _onPlaybackStateChangedCallback = cb;
  }

  StreamSubscription? _sessionSub, _mediaStatusSub, _positionSub;
  Timer? _syncTimer;
  Timer? _idleDebounceTimer;
  Timer? _disconnectDebounceTimer;
  final _progressSync = ProgressSyncService();
  bool _initialized = false;
  bool _isBackgrounded = false;
  bool _discoveryActive = false;
  bool _isCompletingBook = false;
  bool _foregroundServiceActive = false;

  bool get _hasActiveOrPendingSession =>
      _connectionState != CastConnectionState.disconnected || _reconnecting;

  void _clearPlaybackIntent() {
    _resumeIntentTimer?.cancel();
    _resumeIntentTimer = null;
    _castPlaybackIntent.clear();
    _playbackStateBeforePause = null;
  }

  void _requestPlayIntent() {
    _clearPlaybackIntent();
    _castPlaybackIntent.requestPlay();
    _resumeIntentTimer = Timer(castResumeIntentGrace, () {
      _resumeIntentTimer = null;
      if (!_castPlaybackIntent.isPlayRequested) return;
      _castPlaybackIntent.clear();
      _scheduleBufferingLivenessNotification();
      notifyListeners();
    });
  }

  void _requestPauseIntent() {
    _clearPlaybackIntent();
    _castPlaybackIntent.requestPause();
  }

  void _reconcilePlaybackIntentForStatus(CastPlaybackState target) {
    final pauseContradicted = _castPlaybackIntent.isPauseRequested &&
        shouldClearCastPauseIntent(target);
    final playConfirmedOrStopped = _castPlaybackIntent.isPlayRequested &&
        (target == CastPlaybackState.playing || target == CastPlaybackState.idle);
    if (pauseContradicted || playConfirmedOrStopped) _clearPlaybackIntent();
  }

  /// Rebuild the controls when buffering liveness expires even if the receiver
  /// stops emitting position events. Without this, the getter becomes false
  /// after the grace period but no listener is told to re-read it.
  void _scheduleBufferingLivenessNotification() {
    _bufferingLivenessTimer?.cancel();
    if (_playbackState != CastPlaybackState.buffering ||
        _castPlaybackIntent.isPauseRequested ||
        _lastCastPositionAdvanceAt == null) {
      _bufferingLivenessTimer = null;
      return;
    }
    final deadline = castBufferingLivenessDeadline(
      _playbackState,
      lastPositionAdvance: _lastCastPositionAdvanceAt,
      isPauseRequested: _castPlaybackIntent.isPauseRequested,
    )!;
    final delay = deadline.difference(_now());
    _bufferingLivenessTimer = Timer(
      delay.isNegative ? Duration.zero : delay + const Duration(milliseconds: 1),
      () {
        _bufferingLivenessTimer = null;
        if (_playbackState == CastPlaybackState.buffering &&
            !isReceiverActive) {
          notifyListeners();
        }
      },
    );
  }

  /// Method channel to the native Android CastForegroundService. The Cast SDK
  /// notification lives in Google Play Services' process, so Absorb's process
  /// has no foreground promotion during cast by default - Android Doze then
  /// throttles the 15s sync timer to ~9-15 min intervals under screen-lock.
  /// Fixes GH #184.
  static const MethodChannel _castServiceChannel =
      MethodChannel('com.absorb.cast_service');

  Timer? _relayStopTimer;

  Future<void> _setForegroundService(bool active, {bool keepRelay = false}) async {
    _relayStopTimer?.cancel();
    if (!active && !keepRelay) unawaited(CastRelay.instance.stop());
    if (!Platform.isAndroid) return;
    if (active == _foregroundServiceActive) return;
    _foregroundServiceActive = active;
    try {
      await _castServiceChannel.invokeMethod(active ? 'start' : 'stop');
    } catch (e) {
      debugPrint('[Cast] setForegroundService($active) error: $e');
    }
  }

  // Grace periods for transient cast hiccups. Idle/disconnect events during
  // active casting can be spurious (network blips, track transitions, stream
  // re-subscribe races) - we wait briefly before actually tearing down UI
  // state so the user doesn't see the card vanish while the Chromecast keeps
  // playing on its own.
  static const Duration _idleGrace = Duration(seconds: 5);
  static const Duration _disconnectGrace = Duration(seconds: 5);

  // ── Init ──

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[Cast] >>> init() called');
    try {
      const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
      debugPrint('[Cast] Using appId: $appId');
      final GoogleCastOptions options;
      if (Platform.isIOS) {
        options = IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
        );
      } else {
        options = GoogleCastOptionsAndroid(appId: appId);
      }
      GoogleCastContext.instance.setSharedInstanceWithOptions(options);
      debugPrint('[Cast] Context initialized OK');
    } catch (e, st) {
      debugPrint('[Cast] Init error: $e\n$st');
      _initialized = false;
      return;
    }
    _listenToSessionChanges();

    if (!_isBackgrounded) {
      await _setDiscovery(true);
    }
  }

  Future<void> _setDiscovery(bool active) async {
    if (!_initialized || active == _discoveryActive) return;
    _discoveryActive = active;
    try {
      if (active) {
        await GoogleCastDiscoveryManager.instance.startDiscovery();
        debugPrint('[Cast] Discovery started');
      } else {
        await GoogleCastDiscoveryManager.instance.stopDiscovery();
        debugPrint('[Cast] Discovery stopped');
      }
    } catch (e) {
      _discoveryActive = !active;
      debugPrint('[Cast] Discovery ${active ? 'start' : 'stop'} error: $e');
    }
  }

  Future<void> onAppBackgrounded() async {
    _isBackgrounded = true;
    if (!_hasActiveOrPendingSession) await _setDiscovery(false);
  }

  Future<void> onAppForegrounded() async {
    _isBackgrounded = false;
    await _setDiscovery(true);
  }

  // ── Session ──

  void _listenToSessionChanges() {
    debugPrint('[Cast] >>> _listenToSessionChanges() subscribing');
    _sessionSub?.cancel();
    _sessionSub = GoogleCastSessionManager.instance.currentSessionStream.listen(
      (session) {
        final state = GoogleCastSessionManager.instance.connectionState;
        debugPrint('[Cast] SESSION EVENT — connectionState: $state, session: ${session?.device?.friendlyName ?? "null"}');
        if (state == GoogleCastConnectState.disconnected) _noteSessionEnd();
        if (state == GoogleCastConnectState.connected) {
          _connectingDevice = null;
          // Cancel any pending disconnect wipe - we're back before the grace expired.
          if (_disconnectDebounceTimer?.isActive ?? false) {
            debugPrint('[Cast] Reconnected within grace period - cancelling disconnect wipe');
            _disconnectDebounceTimer?.cancel();
            _disconnectDebounceTimer = null;
          }
          // Whether this arrived via the SDK's own resumption or our backstop
          // retry, we're back - stop retrying.
          if (_reconnecting) {
            debugPrint('[Cast] Reconnect backstop succeeded');
            _reconnecting = false;
            _reconnectTimer?.cancel();
            _reconnectTimer = null;
          }
          final wasConnected = _connectionState == CastConnectionState.connected;
          _connectionState = CastConnectionState.connected;
          _connectedDeviceName = session?.device?.friendlyName;
          _lastConnectedDevice = session?.device ?? _lastConnectedDevice;
          debugPrint('[Cast] ✓ CONNECTED to: $_connectedDeviceName');
          _listenToMediaStatus();
          _listenToPosition();
          _updateVolumeFromSession();
          // Rehydrate casting metadata if we lost it (e.g. after a disconnect
          // wipe, or if app was restarted while cast was active).
          if (!wasConnected || _castingItemId == null) {
            _rehydrateFromRemoteMedia();
          }
          unawaited(_applyPendingSleepPause());
        } else if (state == GoogleCastConnectState.disconnected && _retryFirstConnect()) {
          _connectionState = CastConnectionState.connecting;
        } else if (state == GoogleCastConnectState.disconnected) {
          if (_connectionState == CastConnectionState.disconnected &&
              !_reconnecting) {
            return;
          }
          debugPrint('[Cast] ✗ DISCONNECTED (scheduling grace ${_disconnectGrace.inSeconds}s before deciding to reconnect or wipe)');
          // Debounce: transient wifi/session blips can emit disconnected then
          // reconnect shortly after. Only act if it sticks.
          _disconnectDebounceTimer?.cancel();
          _disconnectDebounceTimer = Timer(_disconnectGrace, () {
            debugPrint('[Cast] Disconnect grace expired');
            _beginReconnectOrWipe();
          });
          // Reflect "connecting" in the UI so controls aren't fully dead but
          // also aren't claiming a live connection.
          _connectionState = CastConnectionState.connecting;
        } else {
          debugPrint('[Cast] ~ CONNECTING...');
          _connectionState = CastConnectionState.connecting;
        }
        notifyListeners();
      },
      onError: (e) => debugPrint('[Cast] Session stream ERROR: $e'),
      onDone: () => debugPrint('[Cast] Session stream DONE (closed)'),
    );
    debugPrint('[Cast] Session stream subscription active');
  }

  static const _reconnectMaxAttempts = 3;
  static const _reconnectBaseDelay = Duration(seconds: 3);

  /// Decide whether a disconnect that's stuck past the grace period is worth
  /// fighting for: only if something was actually playing and we know which
  /// device to go back to. Otherwise there's nothing to reconnect for -
  /// fall straight through to the normal wipe.
  void _beginReconnectOrWipe() {
    final device = _lastConnectedDevice;
    final wasEngaged =
        _castingItemId != null && _playbackState != CastPlaybackState.idle;
    if (device == null || !wasEngaged) {
      _onDisconnected();
      return;
    }
    debugPrint('[Cast] Attempting backstop reconnect to ${device.friendlyName} before giving up');
    _reconnecting = true;
    _reconnectAttempts = 0;
    notifyListeners();
    _tryReconnect(device);
  }

  /// One attempt in a short, bounded backoff (3s, 6s, 12s). Each attempt
  /// clears whatever zombie sender-side session the SDK's own resumption may
  /// have left behind - startSessionWithDevice refuses to run while one is
  /// still established, even a dead one - then asks to reconnect. The actual
  /// outcome is driven by the session stream, same as any other connect; this
  /// just keeps trying it until that stream reports success or we run out of
  /// attempts, at which point it's a real disconnect and gets wiped normally.
  void _tryReconnect(GoogleCastDevice device) {
    _reconnectTimer?.cancel();
    if (!_reconnecting) return;
    if (isConnected) {
      _reconnecting = false;
      return;
    }
    if (_reconnectAttempts >= _reconnectMaxAttempts) {
      debugPrint('[Cast] Reconnect backstop exhausted after $_reconnectAttempts attempts - giving up');
      _reconnecting = false;
      _onDisconnected();
      return;
    }
    _reconnectAttempts++;
    final delay = _reconnectBaseDelay * (1 << (_reconnectAttempts - 1));
    debugPrint('[Cast] Reconnect backstop attempt $_reconnectAttempts/$_reconnectMaxAttempts in ${delay.inSeconds}s');
    _reconnectTimer = Timer(delay, () async {
      if (!_reconnecting || isConnected) return;
      try {
        // The plugin's Android handler runs endSession but never posts a
        // MethodChannel reply, so awaiting it bare hangs forever. The end
        // itself takes effect immediately; the timeout just keeps this chain
        // moving whether or not a reply ever shows up.
        await GoogleCastSessionManager.instance
            .endSession()
            .timeout(const Duration(milliseconds: 500));
      } catch (_) {}
      if (!_reconnecting) return;
      try {
        debugPrint('[Cast] Reconnect backstop: connecting to ${device.friendlyName}');
        await GoogleCastSessionManager.instance.startSessionWithDevice(device);
      } catch (e) {
        debugPrint('[Cast] Reconnect backstop attempt failed: $e');
      }
      _tryReconnect(device);
    });
  }

  /// Reports the pause outcome, waiting for an ongoing reconnect if necessary.
  Future<bool> pauseNowOrOnReconnect() async {
    if (isConnected) return _pause();
    if (_reconnecting) {
      return (_pendingSleepPause ??= Completer<bool>()).future;
    }
    return false;
  }

  Future<void> _applyPendingSleepPause() async {
    final pending = _pendingSleepPause;
    if (pending == null) return;
    _pendingSleepPause = null;
    pending.complete(await _pause());
  }

  void cancelPendingSleepPause() {
    _pendingSleepPause?.complete(false);
    _pendingSleepPause = null;
  }

  void _onDisconnected() {
    _playbackCommand++;
    if (_castingItemId != null && _castPosition > Duration.zero) _saveProgressLocal();
    unawaited(_endOwnSession());

    // A dropped connection often comes straight back, and the cast device
    // is still fetching audio through this phone meanwhile: keep answering
    // it for a few minutes before giving up.
    unawaited(_setForegroundService(false, keepRelay: true));
    _relayStopTimer = Timer(const Duration(minutes: 3), () {
      if (!isConnected) unawaited(CastRelay.instance.stop());
    });
    _connectionState = CastConnectionState.disconnected;
    _playbackState = CastPlaybackState.idle;
    _connectedDeviceName = null;
    _castingItemId = _castingEpisodeId = _castingTitle = _castingAuthor = _castingCoverUrl = null;
    _castingDuration = 0;
    _castingChapters = [];
    _castPosition = Duration.zero;
    _lastCastPositionAdvanceAt = null;
    _clearPlaybackIntent();
    _bufferingLivenessTimer?.cancel();
    _bufferingLivenessTimer = null;
    _fallbackTracks = null; _fallbackOffsets = null; _fallbackTrackIdx = -1;
    _queueOffsets = null; _queueTrackIdx = 0;
    _mediaStatusSub?.cancel();
    _positionSub?.cancel();
    _syncTimer?.cancel();
    _idleDebounceTimer?.cancel();
    _disconnectDebounceTimer?.cancel();
    _reconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    cancelPendingSleepPause();
    if (_isBackgrounded) unawaited(_setDiscovery(false));

    _onPlaybackStateChangedCallback?.call(false);
    notifyListeners();
  }

  /// After a reconnect where we lost our local casting state, try to read the
  /// current remote media status and repopulate enough metadata for the UI to
  /// show the now-playing card again. Best-effort: if nothing is playing
  /// remotely, this is a no-op.
  void _rehydrateFromRemoteMedia() {
    try {
      final status = GoogleCastRemoteMediaClient.instance.mediaStatus;
      if (status == null) {
        debugPrint('[Cast] Rehydrate: no remote media status available');
        return;
      }
      final info = status.mediaInformation;
      if (info == null) {
        debugPrint('[Cast] Rehydrate: no mediaInformation on status');
        return;
      }
      debugPrint('[Cast] Rehydrate: remote playerState=${status.playerState}, contentId=${info.contentId}');
      // We can't fully reconstruct itemId / chapters from the cast payload
      // alone, but we can at least surface title/author/duration so the UI
      // doesn't look dead. The sync timer and completion logic stay dormant
      // until castItem is invoked again for a known item.
      final meta = info.metadata;
      if (meta is GoogleCastGenericMediaMetadata) {
        _castingTitle ??= meta.title;
        _castingAuthor ??= meta.subtitle;
      }
      if (_castingDuration <= 0) {
        _castingDuration = info.duration?.inSeconds.toDouble() ?? 0;
      }
      switch (status.playerState) {
        case CastMediaPlayerState.playing: _playbackState = CastPlaybackState.playing; break;
        case CastMediaPlayerState.paused: _playbackState = CastPlaybackState.paused; break;
        case CastMediaPlayerState.buffering: _playbackState = CastPlaybackState.buffering; break;
        case CastMediaPlayerState.loading: _playbackState = CastPlaybackState.loading; break;
        default: break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[Cast] Rehydrate error: $e');
    }
  }

  // The address each queued file was loaded from, and the cast device's id
  // for the first of them: it numbers a queue's files in order.
  List<String>? _queueUrls;
  int? _queueFirstItemId;

  /// Which of the book's files the cast device is on, or -1 when that can't
  /// be told. The device's own list of queued files is only the few around
  /// the current one once it has been playing a while, so a place in that
  /// list says nothing: reading it that way took a book on its 20th file for
  /// one on its 2nd, and saved that as the book's position.
  int _queueTrackOf(GoggleCastMediaStatus status, int trackCount) {
    final current = status.currentItemId;
    if (current == null) return -1;
    final at = _queueUrls?.indexOf(status.mediaInformation?.contentId ?? '') ?? -1;
    if (at >= 0) {
      _queueFirstItemId = current - at;
    } else if (_queueFirstItemId == null) {
      final items = GoogleCastRemoteMediaClient.instance.queueItems;
      if (items.length == trackCount) {
        final listed = items.indexWhere((it) => it.itemId == current);
        if (listed >= 0) _queueFirstItemId = current - listed;
      }
    }
    final first = _queueFirstItemId;
    return first == null ? -1 : current - first;
  }

  void _listenToMediaStatus() {
    _mediaStatusSub?.cancel();
    _mediaStatusSub = GoogleCastRemoteMediaClient.instance.mediaStatusStream.listen((status) {
      final prev = _playbackState;

      // Queue mode: map the receiver's current item to our track index so
      // the position math below uses the right offset.
      final qOffsets = _queueOffsets;
      if (qOffsets != null && status?.currentItemId != null) {
        final idx = _queueTrackOf(status!, qOffsets.length - 1);
        if (idx >= 0 && idx != _queueTrackIdx && idx < qOffsets.length - 1) {
          debugPrint('[Cast] Queue track changed: $_queueTrackIdx -> $idx');
          _queueTrackIdx = idx;
        }
      }

      // Determine the raw target state this event implies.
      CastPlaybackState target;
      if (status == null) {
        target = CastPlaybackState.idle;
      } else {
        debugPrint('[Cast] Media status: ${status.playerState}');
        switch (status.playerState) {
          case CastMediaPlayerState.playing: target = CastPlaybackState.playing; break;
          case CastMediaPlayerState.paused: target = CastPlaybackState.paused; break;
          case CastMediaPlayerState.buffering: target = CastPlaybackState.buffering; break;
          case CastMediaPlayerState.loading: target = CastPlaybackState.loading; break;
          default: target = CastPlaybackState.idle;
        }
      }

      // Any non-idle event means we're still live - cancel any pending idle wipe.
      if (target != CastPlaybackState.idle && (_idleDebounceTimer?.isActive ?? false)) {
        debugPrint('[Cast] Idle grace cancelled - received $target');
        _idleDebounceTimer?.cancel();
        _idleDebounceTimer = null;
      }

      _reconcilePlaybackIntentForStatus(target);

      // If the cast reports idle while we still have an active item that isn't
      // near the end, treat it as a transient blip and wait before actually
      // flipping to idle. This prevents the UI card from vanishing on brief
      // stream hiccups / track transitions while the Chromecast keeps playing.
      if (target == CastPlaybackState.idle &&
          _castingItemId != null &&
          _castingDuration > 0 &&
          !_isAdvancingTrack) {
        final pos = _castPosition.inMilliseconds / 1000.0;
        final nearEnd = pos >= _castingDuration - 5;
        final atTrackBoundary = _fallbackTracks != null && _fallbackTrackIdx < _fallbackTracks!.length - 1;

        if (nearEnd || atTrackBoundary) {
          // Real end-of-track/book - apply immediately, existing completion
          // logic below will handle it.
          _playbackState = CastPlaybackState.idle;
        } else if (!(_idleDebounceTimer?.isActive ?? false)) {
          debugPrint('[Cast] Idle during active cast (pos=${pos.toStringAsFixed(1)}s/${_castingDuration.toStringAsFixed(1)}s) - debouncing ${_idleGrace.inSeconds}s');
          _idleDebounceTimer = Timer(_idleGrace, () {
            debugPrint('[Cast] Idle grace expired - applying idle state');
            _playbackState = CastPlaybackState.idle;
        
            _onPlaybackStateChangedCallback?.call(false);
            notifyListeners();
          });
          // Leave _playbackState as-is (typically playing/buffering) so the UI
          // keeps showing the cast card during the grace window.
          return;
        } else {
          // Grace already running - keep prior state visible.
          return;
        }
      } else {
        _playbackState = target;
      }
      _scheduleBufferingLivenessNotification();

      // Notify listeners & manage wake lock on playback state transitions
      final wasPlaying = prev == CastPlaybackState.playing || prev == CastPlaybackState.buffering;
      final nowPlaying = _playbackState == CastPlaybackState.playing || _playbackState == CastPlaybackState.buffering;
      if (wasPlaying != nowPlaying) {
        _onPlaybackStateChangedCallback?.call(nowPlaying);
      }

      // Detect playback completion: was playing/buffering → now idle
      if (_playbackState == CastPlaybackState.idle &&
          (prev == CastPlaybackState.playing || prev == CastPlaybackState.buffering) &&
          _castingItemId != null && _castingDuration > 0 && !_isAdvancingTrack) {
        final pos = _castPosition.inMilliseconds / 1000.0;
        // In fallback mode, check if this is a track end (not book end)
        if (_fallbackTracks != null && _fallbackTrackIdx < _fallbackTracks!.length - 1) {
          _advanceToNextTrack();
        } else if (pos >= _castingDuration - 5) {
          _onCastPlaybackComplete();
        }
      }

      notifyListeners();
    }, onError: (e) {
      debugPrint('[Cast] mediaStatusStream error - re-subscribing: $e');
      _listenToMediaStatus();
    }, onDone: () {
      debugPrint('[Cast] mediaStatusStream completed - re-subscribing');
      if (isConnected) _listenToMediaStatus();
    });
  }

  void _listenToPosition() {
    _positionSub?.cancel();
    _positionSub = GoogleCastRemoteMediaClient.instance.playerPositionStream.listen((pos) {
      // ignore: unnecessary_null_comparison
      if (pos != null) _handlePosition(pos);
    }, onError: (e) {
      debugPrint('[Cast] positionStream error - re-subscribing: $e');
      _listenToPosition();
    }, onDone: () {
      debugPrint('[Cast] positionStream completed - re-subscribing');
      if (isConnected) _listenToPosition();
    });
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (isCasting && _castingItemId != null) {
        _saveProgressLocal();
        // Only report listening time while actually playing. Wall-clock
        // elapsed would otherwise inflate server stats during pauses.
        // Explicit pause/play/stop paths still call _syncProgressToServer
        // directly to flush pending listening time around state changes.
        if (isPlaying) {
          _syncProgressToServer();
        } else {
          // Advance the sync baseline so a direct sync later (disconnect,
          // stop, remote resume) doesn't bill the paused seconds as
          // timeListened.
          _lastSyncTime = DateTime.now();
        }
      }
    });
  }

  /// A typed mirror of the receiver subscriptions, used only by deterministic
  /// service tests so delayed Cast events can be exercised without the plugin.
  void _listenToTestStreams() {
    final mediaStatusStream = _testMediaStatusStream;
    if (mediaStatusStream != null) {
      _mediaStatusSub = mediaStatusStream.listen(_handleTestMediaStatus);
    }
    final positionStream = _testPositionStream;
    if (positionStream != null) {
      _positionSub = positionStream.listen(_handlePosition);
    }
  }

  void _handleTestMediaStatus(CastPlaybackState target) {
    final previous = _playbackState;
    _reconcilePlaybackIntentForStatus(target);
    _playbackState = target;
    _scheduleBufferingLivenessNotification();
    final wasActive = previous == CastPlaybackState.playing ||
        previous == CastPlaybackState.buffering;
    final isActive = target == CastPlaybackState.playing ||
        target == CastPlaybackState.buffering;
    if (wasActive != isActive) _onPlaybackStateChangedCallback?.call(isActive);
    notifyListeners();
  }

  Stream<Duration>? get castPositionStream =>
      GoogleCastRemoteMediaClient.instance.playerPositionStream;

  void _handlePosition(Duration pos) {
    final previousPosition = _castPosition;
    if (_queueOffsets != null && _queueTrackIdx >= 0 && _queueTrackIdx < _queueOffsets!.length - 1) {
      final offsetMs = (_queueOffsets![_queueTrackIdx] * 1000).round();
      _castPosition = Duration(milliseconds: offsetMs + pos.inMilliseconds);
    } else if (_fallbackOffsets != null && _fallbackTrackIdx >= 0 && _fallbackTrackIdx < _fallbackOffsets!.length) {
      final offsetMs = (_fallbackOffsets![_fallbackTrackIdx] * 1000).round();
      _castPosition = Duration(milliseconds: offsetMs + pos.inMilliseconds);
    } else {
      _castPosition = pos;
    }
    var positionEvidence = CastPositionEvidence.none;
    if (_castPosition != previousPosition) {
      _lastCastPositionAdvanceAt = _now();
      positionEvidence = _castPlaybackIntent.recordPositionAdvance();
      if (positionEvidence == CastPositionEvidence.pauseIgnored) {
        _playbackState = _playbackStateBeforePause ?? _playbackState;
        _playbackStateBeforePause = null;
      } else if (positionEvidence == CastPositionEvidence.playConfirmed) {
        _resumeIntentTimer?.cancel();
        _resumeIntentTimer = null;
        _playbackStateBeforePause = null;
        if (_playbackState == CastPlaybackState.paused ||
            _playbackState == CastPlaybackState.idle) {
          _playbackState = CastPlaybackState.buffering;
        }
      }
      _scheduleBufferingLivenessNotification();
    }
    if (_playbackState == CastPlaybackState.buffering ||
        positionEvidence != CastPositionEvidence.none) notifyListeners();
  }

  @visibleForTesting
  void handleTestPosition(Duration position) => _handlePosition(position);

  @visibleForTesting
  void setTestReceiverState(CastPlaybackState state, {bool connected = true}) {
    _connectionState = connected ? CastConnectionState.connected : CastConnectionState.disconnected;
    _playbackState = state;
  }

  @visibleForTesting
  void setTestReconnecting(bool reconnecting) {
    _connectionState = CastConnectionState.disconnected;
    _reconnecting = reconnecting;
  }

  @visibleForTesting
  Future<void> completeTestReconnect() async {
    _connectionState = CastConnectionState.connected;
    _reconnecting = false;
    await _applyPendingSleepPause();
  }

  int _consumeTimeListened(DateTime now) {
    final elapsed = now.difference(_lastSyncTime).inSeconds.clamp(0, 300);
    _lastSyncTime = now;
    return isReceiverActive ? elapsed : 0;
  }

  @visibleForTesting
  int consumeTestTimeListened(DateTime now) => _consumeTimeListened(now);

  // ── Discovery / Connection ──

  Stream<List<GoogleCastDevice>> get devicesStream =>
      GoogleCastDiscoveryManager.instance.devicesStream;

  GoogleCastSessionEnd? _notedEnd;

  /// A cast stopped from its notification, or from the system's output
  /// picker, ends the session on purpose without going through this app.
  /// Read as a dropped connection, it was reconnected a few seconds later
  /// and the cast came back.
  void _noteSessionEnd() {
    final end = GoogleCastSessionEnd.last;
    if (end == null || identical(end, _notedEnd)) return;
    _notedEnd = end;
    debugPrint('[Cast] Session ${end.event}, code ${end.code}');
    final fresh = DateTime.now().difference(end.at) < const Duration(seconds: 3);
    // 0 is a clean end. 2160 to 2163 aren't in Cast's published list: the
    // notification's stop button reports 2161, and the four line up with the
    // reasons Android gives for a route being let go of, all of them
    // something done on this phone and none of them a lost connection.
    final onPurpose = end.code == 0 || (end.code >= 2160 && end.code <= 2163);
    if (fresh && end.event == 'ended' && onPurpose && !_userEndedCast) {
      debugPrint('[Cast] Ended on purpose from outside the app - not reconnecting');
      _userEndedCast = true;
      _lastConnectedDevice = null;
    }
  }

  // The device a tap is connecting to, until it connects.
  GoogleCastDevice? _connectingDevice;
  DateTime? _connectStartedAt;
  DateTime? _connectRetriedAt;

  /// A first tap on a device sometimes connects and drops within a moment,
  /// and the same tap again works. This makes that second try itself, once.
  /// True when the drop belongs to such a first try and is being handled.
  bool _retryFirstConnect() {
    final device = _connectingDevice;
    final started = _connectStartedAt;
    if (device == null || started == null) return false;
    final now = DateTime.now();
    if (now.difference(started) > const Duration(seconds: 8)) {
      _connectingDevice = null;
      return false;
    }
    final retried = _connectRetriedAt;
    if (retried != null) {
      // The drop is reported more than once: the repeats are the same drop,
      // anything after the second try began is that try failing too.
      if (now.isBefore(retried)) return true;
      _connectingDevice = null;
      return false;
    }
    const wait = Duration(milliseconds: 700);
    _connectRetriedAt = now.add(wait);
    debugPrint('[Cast] The connection to ${device.friendlyName} dropped straight away - trying once more');
    Timer(wait, () async {
      if (!identical(_connectingDevice, device) || isConnected) return;
      try {
        await GoogleCastSessionManager.instance.startSessionWithDevice(device);
      } catch (e) {
        debugPrint('[Cast] Second try error: $e');
      }
      // A second try that goes nowhere must not leave the app looking like
      // it is still connecting.
      Timer(const Duration(seconds: 15), () {
        if (!identical(_connectingDevice, device) || isConnected) return;
        debugPrint('[Cast] The second try never connected - giving up');
        _connectingDevice = null;
        _connectionState = CastConnectionState.disconnected;
        if (_isBackgrounded) unawaited(_setDiscovery(false));
        notifyListeners();
      });
    });
    return true;
  }

  Future<void> connectToDevice(GoogleCastDevice device) async {
    _connectingDevice = device;
    _connectStartedAt = DateTime.now();
    _connectRetriedAt = null;
    debugPrint('[Cast] >>> connectToDevice() — ${device.friendlyName}');
    debugPrint('[Cast] Current connectionState before connect: $_connectionState');
    _connectionState = CastConnectionState.connecting;
    notifyListeners();
    try {
      debugPrint('[Cast] Calling startSessionWithDevice...');
      await GoogleCastSessionManager.instance.startSessionWithDevice(device);
      debugPrint('[Cast] startSessionWithDevice returned (awaited)');
    } catch (e, st) {
      debugPrint('[Cast] Connect error: $e\n$st');
      _connectionState = CastConnectionState.disconnected;
      if (_isBackgrounded) unawaited(_setDiscovery(false));
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _userEndedCast = true;
    if (_castingItemId != null && _castPosition > Duration.zero) {
      await _saveProgressLocal();
      await _syncProgressToServer();
    }
    await _endOwnSession();
    if (_playbackSessionId != null && _api != null) {
      try { await _api!.closePlaybackSession(_playbackSessionId!); } catch (_) {}
      _playbackSessionId = null;
    }
    // User-initiated - don't let the disconnect event this triggers attempt a
    // backstop reconnect back to the device they just chose to leave.
    _lastConnectedDevice = null;
    _reconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _setForegroundService(false);
    try {
      await GoogleCastSessionManager.instance.endSessionAndStopCasting();
    } catch (e) { debugPrint('[Cast] Disconnect error: $e'); }
  }

  // ── Media Loading ──

  Future<bool>? _castStart;
  String? _castStartKey;
  // Whether this cast sends everything through the phone, and the headers a
  // server behind a login wants on each request.
  bool _relayAll = false;
  Map<String, String> _relayHeaders = const {};
  // A cast with no session on the server (a download, or a book narrated
  // from its EPUB) keeps its listening time the way offline playback does,
  // so it counts in the stats and waits on this phone while offline.
  bool _ownSession = false;

  String get _castProgressKey =>
      _castingEpisodeId != null ? '$_castingItemId-$_castingEpisodeId' : (_castingItemId ?? '');

  Future<void> _endOwnSession() async {
    if (!_ownSession) return;
    _ownSession = false;
    var pushed = false;
    try {
      final api = _api;
      if (api != null) pushed = await LocalSessionService().pushActive(api: api);
    } catch (_) {}
    try {
      await LocalSessionService().finalizeActive(pushed: pushed);
    } catch (e) {
      debugPrint('[Cast] Listening session not closed: $e');
    }
  }
  String? _castingNarrator;
  String? _castingSeries;

  /// Two taps on a device that was slow to connect each waited for it and
  /// then both started the same book, loading it twice.
  Future<bool> castItem({
    required ApiService api, required String itemId,
    required String title, required String author,
    required String? coverUrl, required double totalDuration,
    required List<dynamic> chapters, double startTime = 0,
    String? episodeId,
    String? libraryId,
  }) {
    final key = '$itemId-${episodeId ?? ''}';
    final running = _castStart;
    if (running != null && _castStartKey == key) {
      debugPrint('[Cast] "$title" is already starting - not starting it twice');
      return running;
    }
    _castStartKey = key;
    return _castStart = _castItem(
      api: api, itemId: itemId, title: title, author: author, coverUrl: coverUrl,
      totalDuration: totalDuration, chapters: chapters, startTime: startTime,
      episodeId: episodeId, libraryId: libraryId,
    ).whenComplete(() {
      if (_castStartKey == key) {
        _castStart = null;
        _castStartKey = null;
      }
    });
  }

  /// The two lines a cast device shows, in the layout picked for the media
  /// controls. A cast device takes them once per audio file, so they read as
  /// of where that file starts and don't follow along inside it.
  ({String title, String subtitle}) _castLines(String title, String author, double position) =>
      AudioPlayerService().nowPlayingLinesFor(
        title: title,
        author: author,
        chapters: _castingChapters,
        posSec: position,
        totalDuration: _castingDuration,
        narrator: _castingNarrator,
        series: _castingSeries,
      );

  Future<bool> _castItem({
    required ApiService api, required String itemId,
    required String title, required String author,
    required String? coverUrl, required double totalDuration,
    required List<dynamic> chapters, double startTime = 0,
    String? episodeId,
    String? libraryId,
  }) async {
    debugPrint('[Cast] >>> castItem() — "$title" (id: $itemId)');
    debugPrint('[Cast] isConnected=$isConnected, connectionState=$_connectionState');
    if (!isConnected) {
      debugPrint('[Cast] NOT CONNECTED — aborting castItem');
      return false;
    }

    final localPlayer = AudioPlayerService();
    if (localPlayer.hasBook) {
      debugPrint('[Cast] Stopping local player');
      // Keep a sleep timer armed on local playback running - it should track
      // the cast session that's about to start, not vanish on the handoff.
      await localPlayer.stop(keepSleepTimer: true);
    }

    _api = api;
    _userEndedCast = false;
    _castingItemId = itemId;
    _castingEpisodeId = episodeId;
    _castingTitle = title;
    _castingAuthor = author;
    _castingCoverUrl = coverUrl;
    _castingDuration = totalDuration;
    _castingChapters = chapters;
    _lastCastPositionAdvanceAt = null;
    _clearPlaybackIntent();
    _playbackState = CastPlaybackState.loading;
    notifyListeners();

    final localPos = await _progressSync.getSavedPosition(itemId);
    debugPrint('[Cast] Local saved position: $localPos');
    if (localPos > 0 && startTime == 0) startTime = localPos;

    try {
      debugPrint('[Cast] Starting playback session with server... (episodeId: $episodeId)');
      // An Audiobookshelf book narrated from its EPUB has no audio the server
      // can hand out: its files are read out of the EPUB on this phone.
      final narrated = episodeId == null && !api.isBookOrbit && NarratedBooks.contains(itemId);
      _relayAll = !api.isBookOrbit && await PlayerSettings.getCastThroughPhone();
      _relayHeaders = _relayAll ? api.customHeaders : const {};
      // A downloaded book can play out of this phone's storage. That is used
      // whenever the cast goes through the phone anyway, and below when the
      // server can't be asked.
      final download = _downloadedSession(episodeId != null ? '$itemId-$episodeId' : itemId, totalDuration);
      var fromStorage = false;
      Map<String, dynamic>? sessionData;
      if (download != null && (_relayAll || api.isBookOrbit || narrated)) {
        sessionData = download;
        fromStorage = true;
      } else if (narrated) {
        final source = await NarrationStream.instance.open(api, itemId, startTime: startTime);
        if (source != null) {
          final tracks = [
            for (final t in source.session['audioTracks'] as List<dynamic>) Map<String, dynamic>.from(t as Map),
          ];
          for (var i = 0; i < tracks.length && i < source.urls.length; i++) {
            tracks[i]['contentUrl'] = source.urls[i];
          }
          sessionData = {'duration': source.duration, 'audioTracks': tracks};
          _castingChapters = source.chapters;
          if (totalDuration <= 0) totalDuration = source.duration;
          debugPrint('[Cast] Narrated EPUB: ${tracks.length} file(s) read out of the EPUB');
        }
      } else {
        sessionData = episodeId != null
            ? await api.startEpisodePlaybackSession(itemId, episodeId)
            : await api.startPlaybackSession(itemId);
      }
      if (sessionData == null && download != null) {
        debugPrint('[Cast] No session from the server - casting the download from this phone');
        sessionData = download;
        fromStorage = true;
      }
      if (fromStorage) {
        debugPrint('[Cast] Casting ${(sessionData!['audioTracks'] as List).length} downloaded file(s) from this phone');
        final duration = (sessionData['duration'] as num?)?.toDouble() ?? 0;
        if (totalDuration <= 0 && duration > 0) totalDuration = duration;
      }
      if (sessionData == null) {
        debugPrint('[Cast] Server returned null session — aborting');
        _playbackState = CastPlaybackState.idle; notifyListeners(); return false;
      }
      debugPrint('[Cast] Got session data, keys: ${sessionData.keys.toList()}');

      final serverPos = (sessionData['currentTime'] as num?)?.toDouble() ?? 0;
      debugPrint('[Cast] Server position: $serverPos');
      if (serverPos > 0) {
        final localData = await _progressSync.getLocal(itemId);
        final lt = (localData?['timestamp'] as num?)?.toInt() ?? 0;
        final st = (sessionData['updatedAt'] as num?)?.toInt() ?? 0;
        if (st > lt && (serverPos - startTime).abs() > 1.0) startTime = serverPos;
        else if (startTime == 0 && serverPos > 0) startTime = serverPos;
      }

      // Update duration from server if we don't have it (common for podcast episodes)
      final serverDuration = (sessionData['duration'] as num?)?.toDouble() ?? 0;
      if (_castingDuration <= 0 && serverDuration > 0) {
        _castingDuration = serverDuration;
        debugPrint('[Cast] Updated duration from server: ${serverDuration}s');
      }

      final audioTracks = sessionData['audioTracks'] as List<dynamic>?;
      debugPrint('[Cast] Audio tracks count: ${audioTracks?.length ?? 0}');
      if (audioTracks == null || audioTracks.isEmpty) {
        debugPrint('[Cast] No audio tracks — aborting');
        _playbackState = CastPlaybackState.idle; notifyListeners(); return false;
      }

      _playbackSessionId = sessionData['id'] as String?;
      final credits = AudioPlayerService.creditsFrom(sessionData);
      _castingNarrator = credits?.narrator;
      _castingSeries = credits?.series;
      _castPlayMethod = (sessionData['playMethod'] as num?)?.toInt();
      _lastSyncTime = DateTime.now();
      // Audio only this phone can reach goes to the cast device through it.
      if ((api.isBookOrbit || narrated || fromStorage || _relayAll) && !await CastRelay.instance.start()) {
        debugPrint('[Cast] No Wi-Fi address for the cast device to reach this phone on - aborting');
        _playbackState = CastPlaybackState.idle; notifyListeners(); return false;
      }
      // Promote Absorb's process to foreground so Doze doesn't throttle the
      // per-15s sync timer when the user locks their screen. See GH #184.
      unawaited(_setForegroundService(true));

      // Load per-book speed (or global default)
      final bookSpeed = await PlayerSettings.getBookSpeed(itemId);
      final speed = bookSpeed ??
          await PlayerSettings.defaultSpeedFor(libraryId: libraryId);
      _castSpeed = speed;

      debugPrint('[Cast] Starting from position: ${startTime}s, speed: ${speed}x');
      bool loaded;
      if (audioTracks.length == 1) {
        debugPrint('[Cast] Single track mode');
        loaded = await _loadSingleTrack(api, audioTracks.first, title, author, coverUrl, totalDuration, startTime);
      } else {
        debugPrint('[Cast] Multi-track queue mode (${audioTracks.length} tracks)');
        loaded = await _loadMultiTrackQueue(api, audioTracks, title, author, coverUrl, totalDuration, chapters, startTime);
      }

      // Apply playback speed after media is loaded
      if (loaded && (speed - 1.0).abs() > 0.01) {
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          await GoogleCastRemoteMediaClient.instance.setPlaybackRate(speed);
          debugPrint('[Cast] Applied book speed: ${speed}x');
        } catch (e) {
          debugPrint('[Cast] setPlaybackRate error: $e');
        }
      }
      if (!loaded) {
        // loadMedia failed - release the foreground promotion we took above.
        await _setForegroundService(false);
      } else if (_playbackSessionId == null) {
        try {
          await LocalSessionService().beginSession(
            progressKey: _castProgressKey,
            libraryItemId: itemId,
            episodeId: episodeId,
            mediaType: episodeId != null ? 'podcast' : 'book',
            duration: _castingDuration > 0 ? _castingDuration : totalDuration,
            startTime: startTime,
            displayTitle: title,
            displayAuthor: author,
          );
          _ownSession = true;
        } catch (e) {
          debugPrint('[Cast] Listening session not started: $e');
        }
      }
      return loaded;
    } catch (e, st) {
      debugPrint('[Cast] castItem error: $e\n$st');
      await _setForegroundService(false);
      _playbackState = CastPlaybackState.idle; notifyListeners(); return false;
    }
  }

  Future<bool> _loadSingleTrack(ApiService api, dynamic track, String title,
      String author, String? coverUrl, double totalDuration, double startTime) async {
    final m = track as Map<String, dynamic>;
    final fullUrl = _trackUrl(api, m);
    debugPrint('[Cast] Loading single track URL: $fullUrl');
    final lines = _castLines(title, author, startTime);
    try {
      await GoogleCastRemoteMediaClient.instance.loadMedia(
        GoogleCastMediaInformation(
          contentId: fullUrl,
          streamType: CastMediaStreamType.buffered,
          contentUrl: Uri.parse(fullUrl),
          contentType: _trackType(m, fullUrl),
          metadata: GoogleCastGenericMediaMetadata(
            title: lines.title,
            subtitle: lines.subtitle,
            images: coverUrl != null ? [GoogleCastImage(url: Uri.parse(_coverUrl(coverUrl)), height: 400, width: 400)] : null,
          ),
          duration: Duration(seconds: totalDuration.round()),
        ),
        autoPlay: true,
        playPosition: Duration(milliseconds: (startTime * 1000).round()),
      );
      debugPrint('[Cast] ✓ loadMedia completed');
      _queueOffsets = null;
      _castPosition = Duration(milliseconds: (startTime * 1000).round());
      return true;
    } catch (e, st) {
      debugPrint('[Cast] loadMedia error: $e\n$st');
      _playbackState = CastPlaybackState.idle; notifyListeners(); return false;
    }
  }

  Future<bool> _loadMultiTrackQueue(ApiService api, List<dynamic> tracks, String title,
      String author, String? coverUrl, double totalDuration, List<dynamic> chapters, double startTime) async {
    final offsets = <double>[0.0];
    for (final t in tracks) {
      final dur = ((t as Map<String, dynamic>)['duration'] as num?)?.toDouble() ?? 0.0;
      offsets.add(offsets.last + dur);
    }

    int startIdx = 0;
    double localStart = startTime;
    for (int i = 0; i < offsets.length - 1; i++) {
      if (startTime < offsets[i + 1] || i == offsets.length - 2) {
        startIdx = i;
        localStart = startTime - offsets[i];
        break;
      }
    }

    debugPrint('[Cast] Multi-track: startTime=$startTime, track=$startIdx, localStart=$localStart');
    try {
      final items = <GoogleCastQueueItem>[];
      final urls = <String>[];
      for (int i = 0; i < tracks.length; i++) {
        final m = tracks[i] as Map<String, dynamic>;
        final fullUrl = _trackUrl(api, m);
        debugPrint('[Cast] Track $i URL: $fullUrl');
        urls.add(fullUrl);
        final lines = _castLines(title, author, i == startIdx ? startTime : offsets[i]);
        items.add(GoogleCastQueueItem(
          mediaInformation: GoogleCastMediaInformation(
            contentId: fullUrl,
            streamType: CastMediaStreamType.buffered,
            contentUrl: Uri.parse(fullUrl),
            contentType: _trackType(m, fullUrl),
            metadata: GoogleCastGenericMediaMetadata(
              title: lines.title,
              subtitle: lines.subtitle,
              images: coverUrl != null ? [GoogleCastImage(url: Uri.parse(_coverUrl(coverUrl)), height: 400, width: 400)] : null,
            ),
          ),
        ));
      }
      debugPrint('[Cast] Calling queueLoadItems with ${items.length} items (start track $startIdx at ${localStart.toStringAsFixed(1)}s)...');
      try {
        await GoogleCastRemoteMediaClient.instance.queueLoadItems(
          items,
          options: GoogleCastQueueLoadOptions(
            startIndex: startIdx,
            playPosition: Duration(milliseconds: (localStart * 1000).round()),
          ),
        );
        debugPrint('[Cast] ✓ queueLoadItems completed');
        _queueOffsets = offsets;
        _queueUrls = urls;
        _queueFirstItemId = null;
        _queueTrackIdx = startIdx;
        _castPosition = Duration(milliseconds: (startTime * 1000).round());
        return true;
      } catch (queueErr) {
        debugPrint('[Cast] queueLoadItems failed, falling back to single-track loadMedia: $queueErr');
      }

      // Fallback: load the correct track via loadMedia instead of queue
      _queueOffsets = null;
      // Store fallback state for auto-advance
      _fallbackTracks = tracks;
      _fallbackOffsets = offsets;
      _fallbackTrackIdx = startIdx;

      await _loadFallbackTrack(api, tracks, offsets, startIdx, localStart, title, author, coverUrl, totalDuration);
      _castPosition = Duration(milliseconds: (startTime * 1000).round());
      return true;
    } catch (e, st) {
      debugPrint('[Cast] Cast load error: $e\n$st');
      _playbackState = CastPlaybackState.idle; notifyListeners(); return false;
    }
  }

  Future<void> _loadFallbackTrack(ApiService api, List<dynamic> tracks,
      List<double> offsets, int trackIdx, double localStart,
      String title, String author, String? coverUrl, double totalDuration) async {
    final m = tracks[trackIdx] as Map<String, dynamic>;
    final fallbackUrl = _trackUrl(api, m);
    final trackDur = (m['duration'] as num?)?.toDouble() ?? totalDuration;
    debugPrint('[Cast] Fallback: loading track $trackIdx/${tracks.length} at ${localStart}s');
    final lines = _castLines(title, author, offsets[trackIdx] + localStart);
    await GoogleCastRemoteMediaClient.instance.loadMedia(
      GoogleCastMediaInformation(
        contentId: fallbackUrl,
        streamType: CastMediaStreamType.buffered,
        contentUrl: Uri.parse(fallbackUrl),
        contentType: _trackType(m, fallbackUrl),
        metadata: GoogleCastGenericMediaMetadata(
          title: lines.title,
          subtitle: lines.subtitle,
          images: coverUrl != null ? [GoogleCastImage(url: Uri.parse(_coverUrl(coverUrl)), height: 400, width: 400)] : null,
        ),
        duration: Duration(seconds: trackDur.round()),
      ),
      autoPlay: true,
      playPosition: Duration(milliseconds: (localStart * 1000).round()),
    );
    debugPrint('[Cast] ✓ Fallback loadMedia completed (track $trackIdx)');
  }

  /// Auto-advance to next track when in fallback single-track mode
  Future<void> _advanceToNextTrack() async {
    if (_isAdvancingTrack || _fallbackTracks == null || _api == null) return;
    final nextIdx = _fallbackTrackIdx + 1;
    if (nextIdx >= _fallbackTracks!.length) return; // last track — real completion
    _isAdvancingTrack = true;
    _fallbackTrackIdx = nextIdx;
    debugPrint('[Cast] Auto-advancing to track $nextIdx/${_fallbackTracks!.length}');
    try {
      await _loadFallbackTrack(
        _api!, _fallbackTracks!, _fallbackOffsets!, nextIdx, 0,
        _castingTitle ?? '', _castingAuthor ?? '', _castingCoverUrl, _castingDuration,
      );
      _castPosition = Duration(milliseconds: (_fallbackOffsets![nextIdx] * 1000).round());
      // Re-apply speed
      if ((_castSpeed - 1.0).abs() > 0.01) {
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          await GoogleCastRemoteMediaClient.instance.setPlaybackRate(_castSpeed);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[Cast] Auto-advance error: $e');
    }
    _isAdvancingTrack = false;
  }

  /// Where the cast device fetches a track from: the server, or this phone
  /// when the address is one only it can reach.
  String _trackUrl(ApiService api, Map<String, dynamic> m) {
    final stored = m['localPath'] as String?;
    if (stored != null) {
      final address = CastRelay.instance.urlForFile(stored);
      if (address != null) return address;
    }
    final raw = m['contentUrl'] as String? ?? '';
    final built = CastRelay.isPhoneOnly(raw)
        ? raw
        : api.buildTrackUrl(
            raw,
            sessionId: _playbackSessionId,
            trackIndex: (m['index'] as num?)?.toInt(),
            playMethod: _castPlayMethod,
          );
    return CastRelay.instance.urlFor(built, always: _relayAll, headers: _relayHeaders);
  }

  /// A cover as the cast device should fetch it.
  String _coverUrl(String url) => CastRelay.instance.urlFor(url, always: _relayAll, headers: _relayHeaders);

  /// What a downloaded book's files and saved details give a cast to play
  /// from, or null when it isn't downloaded.
  Map<String, dynamic>? _downloadedSession(String key, double totalDuration) {
    final downloads = DownloadService();
    final paths = downloads.getLocalPaths(key);
    if (paths == null || paths.isEmpty) return null;
    if (paths.any((p) => p.startsWith('http'))) return null;
    Map<String, dynamic> saved = const {};
    final json = downloads.getCachedSessionData(key);
    if (json != null) {
      try {
        saved = jsonDecode(json) as Map<String, dynamic>;
      } catch (_) {}
    }
    final known = (saved['audioTracks'] as List<dynamic>? ?? const []).whereType<Map>().toList();
    final duration = (saved['duration'] as num?)?.toDouble() ?? totalDuration;
    // Without a length for every file there is no telling where one ends and
    // the next begins, unless there is only the one.
    if (known.length != paths.length && paths.length != 1) return null;
    final tracks = <Map<String, dynamic>>[
      for (var i = 0; i < paths.length; i++)
        {
          if (known.length == paths.length) ...Map<String, dynamic>.from(known[i]) else 'duration': duration,
          'localPath': paths[i],
          'contentUrl': '',
        },
    ];
    return {
      'duration': duration,
      'audioTracks': tracks,
      if (saved['mediaMetadata'] != null) 'mediaMetadata': saved['mediaMetadata'],
    };
  }

  /// An address through this phone carries no file name to tell the type by,
  /// so the track's own type is used for those.
  String _trackType(Map<String, dynamic> m, String url) {
    final own = m['mimeType'] as String?;
    if (CastRelay.instance.isRunning && own != null && own.startsWith('audio/')) return own;
    return _contentType(url);
  }

  String _contentType(String url) {
    final l = url.toLowerCase();
    if (l.contains('.m4b') || l.contains('.m4a') || l.contains('.aac')) return 'audio/mp4';
    if (l.contains('.ogg') || l.contains('.opus')) return 'audio/ogg';
    if (l.contains('.flac')) return 'audio/flac';
    return 'audio/mpeg';
  }

  /// Get the current chapter title based on cast position
  String? get currentChapterTitle {
    final ch = currentChapter;
    return ch?['title'] as String?;
  }

  // ── Volume ──

  double _volume = 1.0;
  double get volume => _volume;

  void _updateVolumeFromSession() {
    try {
      final session = GoogleCastSessionManager.instance.currentSession;
      if (session != null) {
        _volume = session.currentDeviceVolume.clamp(0.0, 1.0);
      }
    } catch (_) {}
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
    try {
      GoogleCastSessionManager.instance.setDeviceVolume(value);
    } catch (e) {
      debugPrint('[Cast] setDeviceVolume error: $e');
    }
  }

  // ── Controls ──

  Future<void> play() async {
    if (!isConnected) return;
    final command = ++_playbackCommand;
    try {
      final playCommand = _playCommand;
      if (playCommand != null) await playCommand();
      else await GoogleCastRemoteMediaClient.instance.play();
      if (!isConnected || command != _playbackCommand) return;
      _requestPlayIntent();
      _scheduleBufferingLivenessNotification();
      notifyListeners();
    } catch (e) {
      debugPrint('[Cast] play error: $e');
      return;
    }
    // Reset the sync clock so the first tick after resume only counts the
    // seconds actually played since now, not the wall-clock elapsed since
    // the last sync (which would include the entire pause).
    _lastSyncTime = DateTime.now();
  }
  Future<void> pause() async {
    await _pause();
  }

  Future<bool> _pause() async {
    if (!isConnected) return false;
    final command = ++_playbackCommand;
    try {
      final pauseCommand = _pauseCommand;
      await (pauseCommand ?? GoogleCastRemoteMediaClient.instance.pause)()
          .timeout(const Duration(seconds: 10));
      if (!isConnected || command != _playbackCommand) return false;
      final playbackStateBeforePause = _playbackState;
      _requestPauseIntent();
      _playbackStateBeforePause = playbackStateBeforePause;
      _playbackState = CastPlaybackState.paused;
      _scheduleBufferingLivenessNotification();
      notifyListeners();
    } catch (e) {
      debugPrint('[Cast] pause error: $e');
      return false;
    }
    try {
      await _saveProgressLocal();
      await _syncProgressToServer();
    } catch (e) {
      debugPrint('[Cast] Progress save after pause failed: $e');
    }
    return true;
  }
  Future<void> togglePlayPause() async { shouldPauseOnToggle ? await pause() : await play(); }

  Future<void> seekTo(Duration position) async {
    if (!isConnected) return;
    try {
      if (_queueOffsets != null) {
        await _queueSeekAbsolute(position);
      } else if (_fallbackOffsets != null && _fallbackTracks != null) {
        await _fallbackSeekAbsolute(position);
      } else {
        await GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: position));
      }
      _castPosition = position;
      notifyListeners();
    } catch (e) {
      debugPrint('[Cast] seekTo error: $e');
    }
  }

  /// Translate an absolute book position to (track, local offset) and jump
  /// queue items when the target lands in a different track. The SDK's seek
  /// only ever moves within the current queue item.
  Future<void> _queueSeekAbsolute(Duration position) async {
    final offsets = _queueOffsets!;
    final posS = position.inMilliseconds / 1000.0;
    var idx = 0;
    for (int i = 0; i < offsets.length - 1; i++) {
      if (posS < offsets[i + 1] || i == offsets.length - 2) { idx = i; break; }
    }
    final local = Duration(milliseconds: ((posS - offsets[idx]) * 1000).round());
    if (idx != _queueTrackIdx) {
      final qItems = GoogleCastRemoteMediaClient.instance.queueItems;
      final first = _queueFirstItemId;
      final itemId = first != null
          ? first + idx
          : (qItems.length == offsets.length - 1 ? qItems[idx].itemId : null);
      if (itemId != null) {
        debugPrint('[Cast] Queue seek: track $_queueTrackIdx -> $idx at ${local.inSeconds}s');
        await GoogleCastRemoteMediaClient.instance.queueJumpToItemWithId(itemId);
        _queueTrackIdx = idx;
        // The jump starts the item from its beginning; give the receiver a
        // moment to switch before seeking within it.
        if (local > const Duration(seconds: 1)) {
          await Future.delayed(const Duration(milliseconds: 500));
          await GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: local));
        }
        return;
      }
      debugPrint('[Cast] Queue seek: receiver has no itemId for track $idx, seeking within current track');
    }
    await GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: local));
  }

  /// Same translation for fallback single-track mode: seek within the loaded
  /// track, or load the track that contains the target.
  Future<void> _fallbackSeekAbsolute(Duration position) async {
    final offsets = _fallbackOffsets!;
    final posS = position.inMilliseconds / 1000.0;
    var idx = 0;
    for (int i = 0; i < offsets.length - 1; i++) {
      if (posS < offsets[i + 1] || i == offsets.length - 2) { idx = i; break; }
    }
    final localS = posS - offsets[idx];
    if (idx == _fallbackTrackIdx) {
      await GoogleCastRemoteMediaClient.instance.seek(
          GoogleCastMediaSeekOption(position: Duration(milliseconds: (localS * 1000).round())));
      return;
    }
    final api = _api;
    if (api == null) return;
    debugPrint('[Cast] Fallback seek: track $_fallbackTrackIdx -> $idx at ${localS.toStringAsFixed(1)}s');
    _fallbackTrackIdx = idx;
    await _loadFallbackTrack(api, _fallbackTracks!, offsets, idx, localS,
        _castingTitle ?? '', _castingAuthor ?? '', _castingCoverUrl, _castingDuration);
  }

  Future<void> skipForward([int s = 30]) => seekTo(_castPosition + Duration(seconds: s));
  Future<void> skipBackward([int s = 10]) async {
    var p = _castPosition - Duration(seconds: s);
    if (p < Duration.zero) p = Duration.zero;
    await seekTo(p);
  }

  // ── Speed ──

  double _castSpeed = 1.0;
  double get castSpeed => _castSpeed;

  Future<void> setSpeed(double speed) async {
    _castSpeed = speed.clamp(0.5, 3.0);
    if (!isConnected) return;
    try {
      await GoogleCastRemoteMediaClient.instance.setPlaybackRate(speed);
      debugPrint('[Cast] Speed set to ${speed}x');
    } catch (e) {
      debugPrint('[Cast] setPlaybackRate error (may not be supported): $e');
    }
    notifyListeners();
  }

  Future<void> stopCasting() async {
    _userEndedCast = true;
    if (!isConnected) return;
    await _saveProgressLocal();
    await _syncProgressToServer();
    await _endOwnSession();
    try { await GoogleCastRemoteMediaClient.instance.stop(); } catch (_) {}


    // Close the playback session so stats are finalized
    if (_playbackSessionId != null && _api != null) {
      try { await _api!.closePlaybackSession(_playbackSessionId!); } catch (_) {}
      _playbackSessionId = null;
    }

    await _setForegroundService(false);
    _clearPlaybackIntent();
    _playbackState = CastPlaybackState.idle;
    _castingItemId = _castingEpisodeId = _castingTitle = _castingAuthor = _castingCoverUrl = null;
    _castingDuration = 0; _castingChapters = [];
    _fallbackTracks = null; _fallbackOffsets = null; _fallbackTrackIdx = -1;
    _queueOffsets = null; _queueTrackIdx = 0;
    _idleDebounceTimer?.cancel();

    _onPlaybackStateChangedCallback?.call(false);
    notifyListeners();
  }

  // ── Completion ──

  Future<void> _onCastPlaybackComplete() async {
    if (_isCompletingBook) return;
    _isCompletingBook = true;

    final itemId = _castingItemId;
    final episodeId = _castingEpisodeId;
    final duration = _castingDuration;
    debugPrint('[Cast] Book complete: $_castingTitle');

    // Mark as finished on the server
    if (itemId != null && _api != null) {
      try {
        if (episodeId != null) {
          await _api!.updateEpisodeProgress(
            itemId, episodeId,
            currentTime: duration,
            duration: duration,
            isFinished: true,
          );
        } else {
          await _api!.markFinished(itemId, duration);
        }
        debugPrint('[Cast] Marked as finished on server');
      } catch (e) {
        debugPrint('[Cast] Failed to mark finished: $e');
      }
    }

    // Save locally as finished
    if (itemId != null) {
      final progressKey = episodeId != null ? '$itemId-$episodeId' : itemId;
      await _progressSync.saveLocal(
        itemId: progressKey,
        currentTime: duration,
        duration: duration,
        speed: 1.0,
        isFinished: true,
      );
    }

    // Notify LibraryProvider so it can update isFinished locally
    if (itemId != null) {
      final key = episodeId != null ? '$itemId-$episodeId' : itemId;
      _onBookFinishedCallback?.call(key);
    }

    // Close playback session
    if (_playbackSessionId != null && _api != null) {
      try { await _api!.closePlaybackSession(_playbackSessionId!); } catch (_) {}
      _playbackSessionId = null;
    }

    // Clear casting state but keep connection
    _syncTimer?.cancel();
    await _setForegroundService(false);
    _castingItemId = _castingEpisodeId = _castingTitle = _castingAuthor = _castingCoverUrl = null;
    _castingDuration = 0;
    _castingChapters = [];
    _isCompletingBook = false;
    notifyListeners();
  }

  // ── Sync ──

  Future<void> _saveProgressLocal() async {
    if (_castingItemId == null) return;
    final ct = _castPosition.inMilliseconds / 1000.0;
    if (ct <= 0) return;
    await _progressSync.saveLocal(itemId: _castingItemId!, currentTime: ct, duration: _castingDuration, speed: 1.0);
  }

  Future<void> _syncProgressToServer() async {
    if (_castingItemId == null || _api == null) return;
    final ct = _castPosition.inMilliseconds / 1000.0;
    if (ct <= 0) return;
    try {
      final now = DateTime.now();
      final elapsed = _consumeTimeListened(now);

      if (_playbackSessionId != null) {
        debugPrint('[CastSync] ct=${ct.toStringAsFixed(1)}s timeListened=${elapsed}s sid=${_playbackSessionId!.substring(0, 8)}...');
        // Sync via playback session so timeListened is tracked in stats
        await _api!.syncPlaybackSession(
          _playbackSessionId!,
          currentTime: ct,
          duration: _castingDuration,
          timeListened: elapsed,
        );
      } else {
        if (_ownSession) {
          try {
            await LocalSessionService().accrue(
              progressKey: _castProgressKey,
              seconds: elapsed,
              currentTime: ct,
              api: _api,
            );
          } catch (e) {
            debugPrint('[Cast] Listening time not added: $e');
          }
        }
        // Fallback to progress update if no session
        final progressId = _castingEpisodeId != null
            ? '$_castingItemId-$_castingEpisodeId'
            : _castingItemId!;
        await _api!.updateProgress(progressId, currentTime: ct, duration: _castingDuration);
      }
    } catch (e) {
      debugPrint('[Cast] Server sync error: $e');
    }
  }

  // ── Chapters ──

  Map<String, dynamic>? get currentChapter {
    if (_castingChapters.isEmpty) return null;
    final p = _castPosition.inMilliseconds / 1000.0;
    for (final ch in _castingChapters) {
      final m = ch as Map<String, dynamic>;
      if (p >= ((m['start'] as num?)?.toDouble() ?? 0) && p < ((m['end'] as num?)?.toDouble() ?? 0)) return m;
    }
    return null;
  }

  Future<void> skipToNextChapter() async {
    if (_castingChapters.isEmpty) return;
    final p = _castPosition.inMilliseconds / 1000.0;
    final target = ChapterLookup.nextSkipTarget(
      _castingChapters,
      p,
      _castingDuration,
    );
    if (target == null) return;
    if (target.finishesItem) {
      final itemId = _castingItemId;
      await seekTo(Duration(milliseconds: (target.seconds * 1000).round()));
      if (_castingItemId == itemId) await _onCastPlaybackComplete();
      return;
    }
    await seekTo(Duration(milliseconds: (target.seconds * 1000).round()));
  }

  Future<void> skipToPreviousChapter() async {
    if (_castingChapters.isEmpty) return;
    final p = _castPosition.inMilliseconds / 1000.0;
    for (int i = _castingChapters.length - 1; i >= 0; i--) {
      final s = ((_castingChapters[i] as Map)['start'] as num?)?.toDouble() ?? 0;
      if (s < p - 3.0) { await seekTo(Duration(milliseconds: (s * 1000).round())); return; }
    }
    await seekTo(Duration.zero);
  }

  // ── Wake Lock ──


  @override
  void dispose() {
    _playbackCommand++;
    cancelPendingSleepPause();
    _sessionSub?.cancel();
    _mediaStatusSub?.cancel();
    _positionSub?.cancel();
    _syncTimer?.cancel();
    _idleDebounceTimer?.cancel();
    _disconnectDebounceTimer?.cancel();
    _reconnectTimer?.cancel();
    _resumeIntentTimer?.cancel();
    _bufferingLivenessTimer?.cancel();
    super.dispose();
  }
}
