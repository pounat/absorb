import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart' as ja;
import 'native_ios_audio_player.dart';

// Re-export just_audio's data types so consumers don't need a second import.
export 'package:just_audio/just_audio.dart'
    show
        AudioSource,
        UriAudioSource,
        ConcatenatingAudioSource,
        ProgressiveAudioSource,
        PlayerState,
        PlaybackEvent,
        ProcessingState,
        AudioLoadConfiguration,
        AndroidLoadControl,
        DarwinLoadControl;

/// Platform-aware audio player. Routes to a native iOS engine when the
/// experimental flag is on (iOS only); otherwise falls back to just_audio.
class AudioPlayer {
  AudioPlayer({
    bool handleInterruptions = true,
    bool useProxyForRequestHeaders = true,
    ja.AudioLoadConfiguration? audioLoadConfiguration,
  }) {
    if (Platform.isIOS) {
      _native = NativeIosAudioPlayer();
    } else {
      _ja = ja.AudioPlayer(
        handleInterruptions: handleInterruptions,
        useProxyForRequestHeaders: useProxyForRequestHeaders,
        audioLoadConfiguration: audioLoadConfiguration,
      );
    }
  }

  ja.AudioPlayer? _ja;
  NativeIosAudioPlayer? _native;

  bool get _isNative => _native != null;

  /// Expose the just_audio inner player for code paths that absolutely need
  /// it (rare). Null when running on the native engine.
  ja.AudioPlayer? get jaPlayer => _ja;

  // ─── State getters ───

  Duration get position => _isNative ? _native!.position : _ja!.position;
  Duration? get duration => _isNative ? _native!.duration : _ja!.duration;
  Duration get bufferedPosition =>
      _isNative ? _native!.bufferedPosition : _ja!.bufferedPosition;
  bool get playing => _isNative ? _native!.playing : _ja!.playing;
  ja.ProcessingState get processingState =>
      _isNative ? _native!.processingState : _ja!.processingState;
  double get speed => _isNative ? _native!.speed : _ja!.speed;
  double get volume => _isNative ? _native!.volume : _ja!.volume;
  int? get currentIndex =>
      _isNative ? _native!.currentIndex : _ja!.currentIndex;
  int? get androidAudioSessionId =>
      _isNative ? null : _ja!.androidAudioSessionId;
  ja.PlaybackEvent get playbackEvent =>
      _isNative ? _native!.playbackEvent : _ja!.playbackEvent;

  // ─── Streams ───

  Stream<Duration> get positionStream =>
      _isNative ? _native!.positionStream : _ja!.positionStream;
  Stream<Duration?> get durationStream =>
      _isNative ? _native!.durationStream : _ja!.durationStream;
  Stream<Duration> get bufferedPositionStream =>
      _isNative ? _native!.bufferedPositionStream : _ja!.bufferedPositionStream;
  Stream<ja.PlayerState> get playerStateStream =>
      _isNative ? _native!.playerStateStream : _ja!.playerStateStream;
  Stream<ja.ProcessingState> get processingStateStream =>
      _isNative ? _native!.processingStateStream : _ja!.processingStateStream;
  Stream<ja.PlaybackEvent> get playbackEventStream =>
      _isNative ? _native!.playbackEventStream : _ja!.playbackEventStream;
  Stream<int?> get currentIndexStream =>
      _isNative ? _native!.currentIndexStream : _ja!.currentIndexStream;

  /// Native-only signal that the engine swapped to a pre-buffered next book
  /// mid-flight. Empty stream on Android — pre-buffer there still uses
  /// ConcatenatingAudioSource.add and is detected via position-jump.
  Stream<void> get bookAutoAdvancedStream =>
      _isNative ? _native!.bookAutoAdvancedStream : const Stream.empty();

  // ─── Source loading ───

  Future<Duration?> setAudioSource(ja.AudioSource source, {
    Duration? initialPosition,
    int? initialIndex,
    bool preload = true,
  }) async {
    if (_isNative) {
      return _native!.setAudioSource(source, initialPosition: initialPosition, initialIndex: initialIndex, preload: preload);
    }
    return _ja!.setAudioSource(source, initialPosition: initialPosition, initialIndex: initialIndex, preload: preload);
  }

  /// Pre-buffer the next book so cross-book transitions are gapless.
  /// On iOS-native this swaps via replaceCurrentItem when current ends.
  /// On just_audio this is left as a no-op — caller still appends to its
  /// ConcatenatingAudioSource the old way.
  Future<bool> setNextSource(ja.AudioSource? source, {double startPositionS = 0, double totalDurationS = 0}) async {
    if (_isNative) {
      return _native!.setNextSource(source, startPositionS: startPositionS, totalDurationS: totalDurationS);
    }
    return false;
  }

  Future<void> attachEqualizerTap() async {
    if (_isNative) await _native!.attachEqualizerTap();
  }

  Future<void> detachEqualizerTap() async {
    if (_isNative) await _native!.detachEqualizerTap();
  }

  // ─── Control ───

  Future<void> play() => _isNative ? _native!.play() : _ja!.play();
  Future<void> pause() => _isNative ? _native!.pause() : _ja!.pause();
  Future<void> stop() => _isNative ? _native!.stop() : _ja!.stop();
  Future<void> seek(Duration? position, {int? index}) =>
      _isNative ? _native!.seek(position, index: index) : _ja!.seek(position, index: index);
  Future<void> setSpeed(double speed) =>
      _isNative ? _native!.setSpeed(speed) : _ja!.setSpeed(speed);
  Future<void> setVolume(double volume) =>
      _isNative ? _native!.setVolume(volume) : _ja!.setVolume(volume);
  Future<void> setSkipSilenceEnabled(bool enabled) =>
      _isNative ? _native!.setSkipSilenceEnabled(enabled) : _ja!.setSkipSilenceEnabled(enabled);
  Future<Duration?> setAsset(String asset) =>
      _isNative ? _native!.setAsset(asset) : _ja!.setAsset(asset);
  Future<void> dispose() =>
      _isNative ? _native!.dispose() : _ja!.dispose();

  // ─── just_audio-specific configuration (Android path) ───

  static Future<void> configureStreamingCache(int sizeInMB) async {
    // Forward to just_audio's static. Native iOS engine ignores this and
    // uses default AVPlayer caching; acceptable for the experimental flag.
    await ja.AudioPlayer.configureStreamingCache(sizeInMB);
  }
}
