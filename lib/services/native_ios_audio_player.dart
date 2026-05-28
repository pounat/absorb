import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'scoped_prefs.dart';

/// Native iOS audio engine wrapper. Mimics enough of just_audio's
/// `AudioPlayer` surface that AudioPlayerHandler treats it as a drop-in.
/// Talks to AbsorbAudioEngine via `com.absorb.audio_engine` method channel
/// and `com.absorb.audio_engine.events` event channel.
class NativeIosAudioPlayer {
  static const _methodChannel = MethodChannel('com.absorb.audio_engine');
  static const _eventChannel = EventChannel('com.absorb.audio_engine.events');

  NativeIosAudioPlayer() {
    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object e) {
        debugPrint('[NativeIosAudioPlayer] event stream error: $e');
      },
    );
  }

  StreamSubscription? _eventSub;

  // Cached state mirrors the native engine.
  Duration _position = Duration.zero;
  Duration? _duration;
  Duration _bufferedPosition = Duration.zero;
  bool _playing = false;
  ja.ProcessingState _processingState = ja.ProcessingState.idle;
  double _speed = 1.0;
  double _volume = 1.0;
  int? _currentIndex;
  DateTime _updateTime = DateTime.now();

  // Stream controllers; broadcast so multiple listeners are allowed.
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _bufferedPositionController = StreamController<Duration>.broadcast();
  final _playerStateController = StreamController<ja.PlayerState>.broadcast();
  final _processingStateController = StreamController<ja.ProcessingState>.broadcast();
  final _playbackEventController = StreamController<ja.PlaybackEvent>.broadcast();
  final _currentIndexController = StreamController<int?>.broadcast();

  // Notified by AudioPlayerHandler-style consumers when the engine auto-advances
  // mid-book to the pre-buffered next book.
  final _bookAutoAdvancedController = StreamController<void>.broadcast();

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<Duration> get bufferedPositionStream => _bufferedPositionController.stream;
  Stream<ja.PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<ja.ProcessingState> get processingStateStream => _processingStateController.stream;
  Stream<ja.PlaybackEvent> get playbackEventStream => _playbackEventController.stream;
  Stream<int?> get currentIndexStream => _currentIndexController.stream;

  /// Fired when the engine has swapped to a pre-buffered next book mid-flight.
  /// AudioPlayerService listens to this instead of inferring from position
  /// jumps + completion races.
  Stream<void> get bookAutoAdvancedStream => _bookAutoAdvancedController.stream;

  Duration get position => _position;
  Duration? get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;
  bool get playing => _playing;
  ja.ProcessingState get processingState => _processingState;
  double get speed => _speed;
  double get volume => _volume;
  int? get currentIndex => _currentIndex;

  /// Android-only; always null on iOS, matches just_audio's iOS behavior.
  int? get androidAudioSessionId => null;

  /// Current playback event snapshot. AudioPlayerHandler reads this in
  /// `refreshPlaybackState`; mirror the just_audio shape.
  ja.PlaybackEvent get playbackEvent => _buildPlaybackEvent();

  // ─── Source loading ───

  Future<Duration?> setAudioSource(ja.AudioSource source, {
    Duration? initialPosition,
    int? initialIndex,
    bool preload = true,
  }) async {
    final tracks = _flattenSource(source);
    if (tracks.isEmpty) return null;

    final startS = (initialPosition?.inMilliseconds ?? 0) / 1000.0;
    final eqEnabled = await ScopedPrefs.getBool('eq_enabled') ?? false;
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('load', {
      'tracks': tracks.map(_trackToMap).toList(),
      'trackOffsets': _buildTrackOffsets(tracks),
      'startPositionS': startS,
      'totalDurationS': _totalDurationHint,
      'speed': _speed,
      'volume': _volume,
      'eqEnabled': eqEnabled,
    });
    final durS = result?['durationS'] as double?;
    if (durS != null) {
      _duration = Duration(milliseconds: (durS * 1000).round());
      _durationController.add(_duration);
    }
    return _duration;
  }

  /// New: pre-buffer the next book so the engine can swap to it gaplessly when
  /// the current item ends. Not part of just_audio's API.
  Future<bool> setNextSource(ja.AudioSource? source, {double startPositionS = 0, double totalDurationS = 0}) async {
    if (source == null) {
      await _methodChannel.invokeMethod('clearNextSource');
      return true;
    }
    final tracks = _flattenSource(source);
    if (tracks.isEmpty) return false;
    final result = await _methodChannel.invokeMethod<bool>('setNextSource', {
      'tracks': tracks.map(_trackToMap).toList(),
      'trackOffsets': _buildTrackOffsets(tracks),
      'startPositionS': startPositionS,
      'totalDurationS': totalDurationS,
    });
    return result ?? false;
  }

  // ─── Control ───

  Future<void> play() async {
    await _methodChannel.invokeMethod('play');
    _playing = true;
    _emitPlayerState();
  }

  Future<void> pause() async {
    await _methodChannel.invokeMethod('pause');
    _playing = false;
    _emitPlayerState();
  }

  Future<void> stop() async {
    await _methodChannel.invokeMethod('stop');
    _playing = false;
    _processingState = ja.ProcessingState.idle;
    _emitPlayerState();
  }

  Future<void> seek(Duration? position, {int? index}) async {
    final s = (position?.inMilliseconds ?? 0) / 1000.0;
    // `index` is the track within a multi-file book. The engine seeks to the
    // track-local position `s` inside that track; AudioPlayerService has
    // already converted the absolute book position into (index, local offset).
    await _methodChannel.invokeMethod<bool>('seek', {
      'positionS': s,
      if (index != null) 'index': index,
    });
    _position = position ?? Duration.zero;
    if (index != null) _currentIndex = index;
    _updateTime = DateTime.now();
    _positionController.add(_position);
    _playbackEventController.add(_buildPlaybackEvent());
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _methodChannel.invokeMethod('setSpeed', {'speed': speed});
    _playbackEventController.add(_buildPlaybackEvent());
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _methodChannel.invokeMethod('setVolume', {'volume': volume});
  }

  /// No-op on iOS; just_audio's iOS plugin doesn't support skip-silence either.
  Future<void> setSkipSilenceEnabled(bool enabled) async {}

  /// Sleep timer chime uses ja.AudioPlayer.setAsset directly; this wrapper
  /// should never be the chime player. Throw to surface misuse early.
  Future<Duration?> setAsset(String asset) async {
    throw UnsupportedError('NativeIosAudioPlayer.setAsset is not implemented; use ja.AudioPlayer for the chime.');
  }

  Future<void> attachEqualizerTap() async {
    await _methodChannel.invokeMethod('attachEqualizerTap');
  }

  Future<void> detachEqualizerTap() async {
    await _methodChannel.invokeMethod('detachEqualizerTap');
  }

  Future<void> dispose() async {
    await _eventSub?.cancel();
    _eventSub = null;
    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (_) {}
    await _positionController.close();
    await _durationController.close();
    await _bufferedPositionController.close();
    await _playerStateController.close();
    await _processingStateController.close();
    await _playbackEventController.close();
    await _currentIndexController.close();
    await _bookAutoAdvancedController.close();
  }

  // ─── Event channel handler ───

  void _onEvent(dynamic raw) {
    if (raw is! Map) return;
    final type = raw['type'] as String?;
    switch (type) {
      case 'position':
        final s = (raw['positionS'] as num?)?.toDouble() ?? 0;
        _position = Duration(milliseconds: (s * 1000).round());
        _updateTime = DateTime.now();
        _positionController.add(_position);
        _playbackEventController.add(_buildPlaybackEvent());
        break;
      case 'state':
        _playing = (raw['playing'] as bool?) ?? false;
        final psRaw = (raw['processingState'] as int?) ?? 0;
        _processingState = _mapProcessingState(psRaw);
        _processingStateController.add(_processingState);
        _emitPlayerState();
        _playbackEventController.add(_buildPlaybackEvent());
        break;
      case 'duration':
        final s = (raw['durationS'] as num?)?.toDouble();
        _duration = s != null && s > 0 ? Duration(milliseconds: (s * 1000).round()) : null;
        _durationController.add(_duration);
        _playbackEventController.add(_buildPlaybackEvent());
        break;
      case 'trackChanged':
        final idx = (raw['trackIndex'] as int?);
        _currentIndex = idx;
        _currentIndexController.add(idx);
        _playbackEventController.add(_buildPlaybackEvent());
        break;
      case 'bookCompleted':
        _processingState = ja.ProcessingState.completed;
        _processingStateController.add(_processingState);
        _emitPlayerState();
        _playbackEventController.add(_buildPlaybackEvent());
        break;
      case 'bookAutoAdvanced':
        _bookAutoAdvancedController.add(null);
        break;
      case 'bufferedPosition':
        final s = (raw['bufferedPositionS'] as num?)?.toDouble() ?? 0;
        _bufferedPosition = Duration(milliseconds: (s * 1000).round());
        _bufferedPositionController.add(_bufferedPosition);
        _playbackEventController.add(_buildPlaybackEvent());
        break;
      case 'error':
        final msg = raw['message'] as String? ?? 'engine error';
        debugPrint('[NativeIosAudioPlayer] engine error: $msg');
        break;
    }
  }

  ja.ProcessingState _mapProcessingState(int raw) {
    switch (raw) {
      case 0: return ja.ProcessingState.idle;
      case 1: return ja.ProcessingState.loading;
      case 2: return ja.ProcessingState.buffering;
      case 3: return ja.ProcessingState.ready;
      case 4: return ja.ProcessingState.completed;
      default: return ja.ProcessingState.idle;
    }
  }

  void _emitPlayerState() {
    _playerStateController.add(ja.PlayerState(_playing, _processingState));
  }

  ja.PlaybackEvent _buildPlaybackEvent() {
    return ja.PlaybackEvent(
      processingState: _processingState,
      updateTime: _updateTime,
      updatePosition: _position,
      bufferedPosition: _bufferedPosition,
      duration: _duration,
      currentIndex: _currentIndex,
    );
  }

  // ─── AudioSource translation ───

  // Used as a hint to the native engine when load lacks an explicit duration.
  // setAudioSource doesn't receive a duration directly, so we leave it at 0
  // and let the engine read it from the asset after load.
  double get _totalDurationHint => 0;

  List<_NativeTrack> _flattenSource(ja.AudioSource source) {
    final out = <_NativeTrack>[];
    _collect(source, out);
    return out;
  }

  void _collect(ja.AudioSource source, List<_NativeTrack> out) {
    if (source is ja.ConcatenatingAudioSource) {
      for (final child in source.children) {
        _collect(child, out);
      }
      return;
    }
    if (source is ja.UriAudioSource) {
      final uri = source.uri;
      final headers = source.headers ?? const <String, String>{};
      final isLocal = uri.scheme == 'file' || uri.scheme.isEmpty;
      out.add(_NativeTrack(
        url: isLocal ? uri.toFilePath() : uri.toString(),
        isLocal: isLocal,
        headers: headers,
      ));
      return;
    }
    debugPrint('[NativeIosAudioPlayer] Unsupported AudioSource: ${source.runtimeType}');
  }

  Map<String, dynamic> _trackToMap(_NativeTrack t) => {
        'url': t.url,
        'isLocal': t.isLocal,
        'headers': t.headers,
      };

  /// Without per-track durations available here, hand the engine an empty
  /// offsets list and let it fall back to single-track behavior. The
  /// AudioPlayerService already maintains its own `_trackStartOffsets` from
  /// the cached audioTracks and applies the global-position math on the Dart
  /// side, so the engine's offsets are only used internally for seek routing.
  List<double> _buildTrackOffsets(List<_NativeTrack> tracks) {
    if (tracks.length <= 1) return const [];
    return const [];
  }
}

class _NativeTrack {
  _NativeTrack({required this.url, required this.isLocal, required this.headers});
  final String url;
  final bool isLocal;
  final Map<String, String> headers;
}
