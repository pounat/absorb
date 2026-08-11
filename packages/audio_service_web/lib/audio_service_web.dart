import 'dart:async';
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe';

import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'js/media_session_web.dart';

class AudioServiceWeb extends AudioServicePlatform {
  static void registerWith(Registrar registrar) {
    AudioServicePlatform.instance = AudioServiceWeb();
  }

  web.MediaSession get _mediaSession => web.window.navigator.mediaSession;

  final _mediaSessionSupported = _SupportChecker(
    () => js.globalContext.hasProperty('MediaSession'.toJS).toDart,
    'MediaSession is not supported in this browser, so the plugin is a no-op',
  );
  final _setPositionStateSupported = _SupportChecker(
    () => web.window.navigator.mediaSession
        .hasProperty('setPositionState'.toJS)
        .toDart,
    'MediaSession.setPositionState is not supported in this browser',
  );
  final Set<String> _unsupportedActions = {};

  AudioHandlerCallbacks? handlerCallbacks;
  MediaItemMessage? mediaItem;

  @override
  Future<void> configure(ConfigureRequest request) async {
    _mediaSessionSupported.check();
  }

  @override
  Future<void> setState(SetStateRequest request) async {
    if (!_mediaSessionSupported.check()) return;

    final state = request.state;
    _mediaSession.playbackState = switch (state.processingState) {
      AudioProcessingStateMessage.idle => MediaSessionPlaybackState.none,
      _ when state.playing => MediaSessionPlaybackState.playing,
      _ => MediaSessionPlaybackState.paused,
    };

    _installCoreHandlers();
    for (final control in state.controls) {
      switch (control.action) {
        case MediaActionMessage.rewind:
          _setActionHandler(MediaSessionActions.seekbackward, (_) {
            unawaited(handlerCallbacks?.rewind(const RewindRequest()));
          });
        case MediaActionMessage.fastForward:
          _setActionHandler(MediaSessionActions.seekforward, (_) {
            unawaited(
              handlerCallbacks?.fastForward(const FastForwardRequest()),
            );
          });
        case MediaActionMessage.skipToPrevious:
          _setActionHandler(MediaSessionActions.previoustrack, (_) {
            unawaited(
              handlerCallbacks?.skipToPrevious(const SkipToPreviousRequest()),
            );
          });
        case MediaActionMessage.skipToNext:
          _setActionHandler(MediaSessionActions.nexttrack, (_) {
            unawaited(
              handlerCallbacks?.skipToNext(const SkipToNextRequest()),
            );
          });
        case MediaActionMessage.stop:
          _setActionHandler(MediaSessionActions.stop, (_) {
            unawaited(handlerCallbacks?.stop(const StopRequest()));
          });
        case MediaActionMessage.play:
        case MediaActionMessage.pause:
        default:
          break;
      }
    }

    if (state.systemActions.contains(MediaActionMessage.seek)) {
      _setActionHandler(MediaSessionActions.seekto, (details) {
        final seekTime = details.seekTime;
        if (seekTime == null || !seekTime.isFinite) return;
        unawaited(
          handlerCallbacks?.seek(
            SeekRequest(
              position: Duration(
                milliseconds: (seekTime * 1000).round(),
              ),
            ),
          ),
        );
      });
    }

    _updatePositionState(state);
  }

  void _installCoreHandlers() {
    _setActionHandler(MediaSessionActions.play, (_) {
      unawaited(handlerCallbacks?.play(const PlayRequest()));
    });
    _setActionHandler(MediaSessionActions.pause, (_) {
      unawaited(handlerCallbacks?.pause(const PauseRequest()));
    });
  }

  void _setActionHandler(
    String action,
    void Function(MediaSessionActionDetails) handler,
  ) {
    try {
      _mediaSession.setActionHandler(action, handler.toJS);
    } catch (error) {
      if (_unsupportedActions.add(action)) {
        debugPrint(
          '[AudioServiceWeb] Media action "$action" is unavailable: $error',
        );
      }
    }
  }

  void _updatePositionState(PlaybackStateMessage state) {
    if (!_setPositionStateSupported.check()) return;

    final durationSeconds =
        (mediaItem?.duration ?? Duration.zero).inMilliseconds / 1000;
    final rate = state.speed;
    if (!durationSeconds.isFinite ||
        durationSeconds <= 0 ||
        !rate.isFinite ||
        rate <= 0) {
      try {
        _mediaSession.setPositionState();
      } catch (_) {}
      return;
    }

    final rawPosition = state.updatePosition.inMilliseconds / 1000;
    final position = rawPosition.isFinite
        ? rawPosition.clamp(0.0, durationSeconds).toDouble()
        : 0.0;
    try {
      _mediaSession.setPositionState(
        web.MediaPositionState(
          duration: durationSeconds,
          playbackRate: rate,
          position: position,
        ),
      );
    } catch (error) {
      debugPrint('[AudioServiceWeb] Could not update media position: $error');
    }
  }

  @override
  Future<void> setQueue(SetQueueRequest request) async {}

  @override
  Future<void> setMediaItem(SetMediaItemRequest request) async {
    if (!_mediaSessionSupported.check()) return;

    mediaItem = request.mediaItem;
    final item = request.mediaItem;
    final artUri = item.artUri;
    final artwork = artUri != null && _isBrowserArtworkUri(artUri)
        ? [web.MediaImage(src: artUri.toString(), sizes: '512x512')]
        : <web.MediaImage>[];

    _mediaSession.metadata = web.MediaMetadata(
      web.MediaMetadataInit(
        title: item.title,
        artist: item.artist ?? '',
        album: item.album ?? '',
        artwork: artwork.toJS,
      ),
    );
  }

  bool _isBrowserArtworkUri(Uri uri) =>
      uri.scheme == 'http' ||
      uri.scheme == 'https' ||
      uri.scheme == 'data' ||
      uri.scheme == 'blob';

  @override
  Future<void> stopService(StopServiceRequest request) async {
    if (!_mediaSessionSupported.check()) return;
    _mediaSession.playbackState = MediaSessionPlaybackState.none;
    _mediaSession.metadata = null;
    mediaItem = null;
  }

  @override
  void setHandlerCallbacks(AudioHandlerCallbacks callbacks) {
    handlerCallbacks = callbacks;
    if (_mediaSessionSupported.check()) _installCoreHandlers();
  }
}

class _SupportChecker {
  _SupportChecker(this._checkCallback, this._warningMessage);

  final ValueGetter<bool> _checkCallback;
  final String _warningMessage;
  bool _logged = false;

  bool check() {
    final supported = _checkCallback();
    if (!_logged && !supported) {
      _logged = true;
      debugPrint('[AudioServiceWeb] $_warningMessage');
    }
    return supported;
  }
}
