import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'api_service.dart';
import 'audio_player_service.dart';
import 'book_track_resolver.dart';
import 'offline_source.dart';

/// Drives the play-and-mark clip editor: loads the track the bookmark lives in,
/// plays a navigable window around it, reports a playhead, and tracks the
/// in/out points the user marks by ear. Pauses the main player while open and
/// restores it on dispose. All positions are GLOBAL book seconds (so they line
/// up with bookmark times and feed [ClipExportService] directly); internally we
/// translate to the loaded track's local time.
class ClipEditorController extends ChangeNotifier {
  ClipEditorController({
    required this.itemId,
    required this.bookmarkSeconds,
    this.api,
  });

  final String itemId;
  final double bookmarkSeconds;
  final ApiService? api;

  // Shortest allowed clip, and how far before/after the bookmark the editor
  // window reaches (clamped to the track) so the scrub bar stays navigable
  // instead of spanning a whole single-file book.
  static const double minClip = 1;
  static const double _leadIn = 30;
  static const double _leadOut = 330;

  AudioPlayer? _player;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;
  bool _disposed = false;
  bool? _mainWasPlaying;

  bool _ready = false;
  bool _loading = true;
  bool _playing = false;
  double _trackBase = 0; // global seconds at the loaded track's start
  double _winStart = 0;
  double _winEnd = 0;
  double _position = 0; // global playhead
  double _inPoint = 0; // global
  double _outPoint = 0; // global

  bool get isReady => _ready;
  bool get isLoading => _loading;
  bool get isPlaying => _playing;
  double get windowStart => _winStart;
  double get windowEnd => _winEnd;
  double get position => _position.clamp(_winStart, _winEnd);
  double get inPoint => _inPoint;
  double get outPoint => _outPoint;
  double get clipDuration => _outPoint - _inPoint;

  Future<void> init() async {
    _pauseMain();
    final tracks = await BookTrackResolver.resolve(itemId, api);
    if (_disposed) return;
    if (tracks == null || tracks.isEmpty) {
      _loading = false;
      notifyListeners();
      throw StateError('no audio for $itemId');
    }
    final hit = BookTrackResolver.mapGlobal(tracks, bookmarkSeconds);
    var base = 0.0;
    for (var i = 0; i < hit.index; i++) {
      base += tracks[i].duration;
    }
    _trackBase = base;
    final trackDur = hit.track.duration > 0
        ? hit.track.duration
        : (bookmarkSeconds - base + _leadOut + _leadIn);
    final trackEnd = base + trackDur;
    _winStart = (bookmarkSeconds - _leadIn).clamp(base, trackEnd);
    _winEnd = (bookmarkSeconds + _leadOut).clamp(_winStart + minClip, trackEnd);
    _inPoint = bookmarkSeconds.clamp(_winStart, _winEnd - minClip);
    _outPoint = (bookmarkSeconds + 60).clamp(_inPoint + minClip, _winEnd);
    _position = _inPoint;

    try {
      final track = hit.track;
      final player = AudioPlayer(useProxyForRequestHeaders: false);
      _player = player;
      if (track.local) {
        await player.setAudioSource(localAudioSource(track.source));
      } else {
        await player.setAudioSource(AudioSource.uri(Uri.parse(track.source),
            headers: api?.mediaHeaders, options: mp3ExtractorOptions()));
      }
      await player.seek(Duration(milliseconds: ((_position - _trackBase) * 1000).round()));
      _posSub = player.positionStream.listen((d) {
        if (_disposed) return;
        _position = _trackBase + d.inMilliseconds / 1000.0;
        // Stop at the out point so the preview ends exactly where the clip does
        // and you can hear where it stops.
        if (_playing && _position >= _outPoint) {
          player.pause();
          _position = _outPoint;
          player.seek(Duration(milliseconds: ((_outPoint - _trackBase) * 1000).round()));
        }
        notifyListeners();
      });
      _stateSub = player.playerStateStream.listen((s) {
        if (_disposed) return;
        final done = s.processingState == ProcessingState.completed;
        _loading = s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering;
        _playing = s.playing && !done;
        notifyListeners();
      });
      _ready = true;
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[ClipEditor] load failed: $e');
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> togglePlay() async {
    final p = _player;
    if (p == null) return;
    if (p.playing) {
      await p.pause();
    } else {
      // Once it's stopped at the out point, play restarts the clip from the in point.
      if (_position >= _outPoint - 0.1) await seekToGlobal(_inPoint);
      await p.play();
    }
  }

  /// Audition just the tail of the clip: jump a few seconds before the out
  /// point and play through to it. Playback stops at the out point, so this is
  /// the quick way to fine-tune where the clip ends.
  Future<void> previewEnd() async {
    final p = _player;
    if (p == null) return;
    final from = (_outPoint - 4).clamp(_inPoint, _outPoint);
    await seekToGlobal(from);
    await p.play();
  }

  Future<void> seekToGlobal(double global) async {
    final p = _player;
    if (p == null) return;
    final clamped = global.clamp(_winStart, _winEnd);
    _position = clamped;
    notifyListeners();
    await p.seek(Duration(milliseconds: ((clamped - _trackBase) * 1000).round()));
  }

  Future<void> skip(double delta) => seekToGlobal(_position + delta);

  void setStart() {
    _inPoint = _position.clamp(_winStart, _outPoint - minClip);
    notifyListeners();
  }

  void setEnd() {
    _outPoint = _position.clamp(_inPoint + minClip, _winEnd);
    notifyListeners();
  }

  void nudgeStart(double delta) {
    _inPoint = (_inPoint + delta).clamp(_winStart, _outPoint - minClip);
    notifyListeners();
  }

  void nudgeEnd(double delta) {
    _outPoint = (_outPoint + delta).clamp(_inPoint + minClip, _winEnd);
    notifyListeners();
  }

  void _pauseMain() {
    final main = AudioPlayerService();
    _mainWasPlaying ??= main.isPlaying;
    if (main.isPlaying) main.pause();
  }

  @override
  void dispose() {
    _disposed = true;
    _posSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    if (_mainWasPlaying == true) AudioPlayerService().play();
    super.dispose();
  }
}
