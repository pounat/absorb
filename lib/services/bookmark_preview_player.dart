import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'api_service.dart';
import 'audio_player_service.dart';
import 'book_track_resolver.dart';
import 'offline_source.dart';

/// Auditions a book at a given position WITHOUT moving the user's real playback
/// position. Resolves audio for ANY book - downloaded (local files) or streamed
/// (per-file URLs built on demand). Pauses the main player while auditioning and
/// restores it on stop/dispose. Owned by the bookmark detail dialog.
class BookmarkPreviewPlayer extends ChangeNotifier {
  BookmarkPreviewPlayer({required this.itemId, this.api});

  final String itemId;
  final ApiService? api;

  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;
  bool _loading = false;
  bool _playing = false;
  bool _disposed = false;
  bool? _mainWasPlaying;
  Timer? _autoStop;

  // Track-local position (ms) the current audition started at, so pausing then
  // hitting Listen again restarts the clip from the top instead of resuming
  // mid-clip - makes it easy to re-judge the in-point while trimming.
  int? _lastSeekMs;

  /// The audition auto-stops after this long so a single tap never plays the
  /// rest of the book (a single-file m4b would otherwise run for hours). The
  /// bookmark dialog keeps this in sync with the chosen clip length, so what you
  /// preview is exactly what an export would produce.
  Duration clipLength = const Duration(seconds: 60);

  /// When true, the clip-length timer and the natural end of the audio fully
  /// [stop] the audition (resuming the main player) instead of just pausing.
  /// The bookmark dialog leaves this false - there the audited book is
  /// usually the one loaded in the main player, and yanking it back to life
  /// mid-edit would be jarring.
  bool stopOnClipEnd = false;

  List<BookTrack>? _tracks;

  bool get isLoading => _loading;
  bool get isPlaying => _playing;

  /// Toggle playback at [globalSeconds]. Pauses if playing, resumes if paused,
  /// otherwise loads + plays from that position. Throws on resolve/playback
  /// failure so the UI can show a message.
  Future<void> toggleAt(double globalSeconds) async {
    final p = _player;
    if (p != null) {
      if (p.playing) {
        _autoStop?.cancel();
        await p.pause();
      } else {
        await _pauseMain();
        // Restart from the clip start so every replay auditions the beginning
        // of the selection (also recovers from the auto-stop at the clip end).
        if (_lastSeekMs != null) {
          await p.seek(Duration(milliseconds: _lastSeekMs!));
        }
        _startAutoStop();
        await p.play();
      }
      return;
    }
    await _playAt(globalSeconds);
  }

  Future<void> _playAt(double globalSeconds) async {
    _loading = true;
    notifyListeners();
    await _pauseMain();

    final tracks = await _resolveTracks();
    if (_disposed) return;
    if (tracks == null || tracks.isEmpty) {
      debugPrint('[BookmarkPreview] $itemId: no tracks resolved');
      _loading = false;
      notifyListeners();
      throw StateError('no audio for $itemId');
    }

    final hit = BookTrackResolver.mapGlobal(tracks, globalSeconds);
    final track = hit.track;
    final local = hit.localOffset;
    debugPrint('[BookmarkPreview] $itemId: play ${globalSeconds.toStringAsFixed(1)}s -> '
        'track[${hit.index}] ${track.local ? "local" : "stream"} @${local.toStringAsFixed(1)}s');

    try {
      await _disposePlayer();
      // Match the main player: no localhost proxy on Android. The proxy was
      // aborting large seeks into single-file streamed books ("Connection
      // aborted"); without it ExoPlayer ranges the server directly. Token auth
      // rides in the URL (buildFileUrl), so streaming still authenticates.
      final player = AudioPlayer(useProxyForRequestHeaders: false);
      _player = player;
      _stateSub = player.playerStateStream.listen((s) {
        if (_disposed) return;
        final done = s.processingState == ProcessingState.completed;
        _loading = s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering;
        _playing = s.playing && !done;
        notifyListeners();
        if (done) {
          if (stopOnClipEnd) {
            unawaited(stop());
          } else {
            player.pause();
          }
        }
      });
      if (track.local) {
        await player.setAudioSource(localAudioSource(track.source));
      } else {
        await player.setAudioSource(AudioSource.uri(Uri.parse(track.source),
            headers: api?.mediaHeaders, options: mp3ExtractorOptions()));
      }
      _lastSeekMs = (local * 1000).round();
      await player.seek(Duration(milliseconds: _lastSeekMs!));
      // Start the auto-stop BEFORE awaiting play(): just_audio's play() future
      // doesn't complete until playback ends, so a timer after it never armed -
      // that's why the cap wasn't firing.
      _startAutoStop();
      await player.play();
    } catch (e) {
      debugPrint('[BookmarkPreview] $itemId: playback error: $e');
      if (_disposed) return;
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<BookTrack>?> _resolveTracks() async {
    _tracks ??= await BookTrackResolver.resolve(itemId, api);
    return _tracks;
  }

  Future<void> _pauseMain() async {
    final main = AudioPlayerService();
    _mainWasPlaying ??= main.isPlaying;
    if (main.isPlaying) await main.pause();
  }

  void _startAutoStop() {
    _autoStop?.cancel();
    _autoStop = Timer(clipLength, () {
      debugPrint('[BookmarkPreview] auto-stop after ${clipLength.inSeconds}s');
      if (stopOnClipEnd) {
        unawaited(stop());
      } else {
        _player?.pause();
      }
    });
  }

  Future<void> _disposePlayer() async {
    _autoStop?.cancel();
    _autoStop = null;
    _lastSeekMs = null;
    await _stateSub?.cancel();
    _stateSub = null;
    final p = _player;
    _player = null;
    _playing = false;
    if (p != null) {
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }
  }

  /// Stop the audition and resume the main player if we had paused it.
  Future<void> stop() async {
    await _disposePlayer();
    // Reset the snapshot even when it's false, or a sheet-lifetime player's
    // second audition would pause the main book and never resume it.
    final shouldResume = _mainWasPlaying == true;
    _mainWasPlaying = null;
    if (shouldResume) await AudioPlayerService().play();
    if (!_disposed) notifyListeners();
  }

  /// Tear down the audition without resuming the main player - for callers
  /// about to start real playback themselves.
  Future<void> discard() async {
    _mainWasPlaying = null;
    await _disposePlayer();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoStop?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    if (_mainWasPlaying == true) AudioPlayerService().play();
    super.dispose();
  }
}
