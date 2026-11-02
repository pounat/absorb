import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils/app_platform.dart';
import 'audio_player_service.dart';

/// Windows' media overlay and media keys. Shows the playing book with its
/// cover, and turns the keyboard media keys and headphone presses into the
/// player's own buttons: next and previous are the skip buttons, not chapters.
/// audio_service does this on the phones; it has no Windows side.
class WindowsMediaControls {
  WindowsMediaControls._();
  static final WindowsMediaControls instance = WindowsMediaControls._();

  static const _channel = MethodChannel('com.barnabas.absorb/media_controls');
  static const _timelineEvery = Duration(seconds: 5);

  bool _started = false;
  Timer? _pending;
  Timer? _ticker;
  String? _lastKey;
  DateTime? _lastTimeline;
  String? _coverUrl;
  String? _coverPath;

  void start() {
    if (_started || !AppPlatform.isWindows) return;
    _started = true;
    _channel.setMethodCallHandler(_onCall);
    AudioPlayerService().addListener(_schedule);
    _ticker = Timer.periodic(_timelineEvery, (_) => _schedule());
    _schedule();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _channel.setMethodCallHandler(null);
    AudioPlayerService().removeListener(_schedule);
    _ticker?.cancel();
    _pending?.cancel();
  }

  Future<dynamic> _onCall(MethodCall call) async {
    final handler = AudioPlayerService.handler;
    if (handler == null) return null;
    switch (call.method) {
      case 'button':
        switch (call.arguments as String?) {
          case 'play':
            await handler.play();
          case 'pause' || 'stop':
            await handler.pause();
          case 'next' || 'fastForward':
            await handler.fastForward();
          case 'previous' || 'rewind':
            await handler.rewind();
        }
      case 'seek':
        final ms = call.arguments as int?;
        if (ms != null) await handler.seek(Duration(milliseconds: ms));
    }
    return null;
  }

  // The player notifies on every position tick; one send per burst is plenty.
  void _schedule() {
    _pending ??= Timer(const Duration(milliseconds: 300), () {
      _pending = null;
      unawaited(_send());
    });
  }

  Future<void> _send() async {
    final player = AudioPlayerService();
    final itemId = player.currentItemId;
    if (itemId == null || player.currentTitle == null) {
      if (_lastKey != null) {
        _lastKey = null;
        await _invoke('clear');
      }
      return;
    }
    final chapter = player.currentChapter?['title'] as String? ?? '';
    final playing = player.isPlaying;
    final cover = await _coverFile(player.currentCoverUrl);
    final key =
        '$itemId|${player.currentTitle}|${player.currentAuthor}|$chapter|$playing|$cover';
    final now = DateTime.now();
    final timelineDue = _lastTimeline == null ||
        now.difference(_lastTimeline!) >= _timelineEvery;
    if (key == _lastKey && !timelineDue) return;
    _lastKey = key;
    _lastTimeline = now;
    await _invoke('update', {
      'title': player.currentTitle ?? '',
      'artist': player.currentAuthor ?? '',
      'album': chapter,
      'playing': playing,
      'thumbnail': cover ?? '',
      'position': player.position.inMilliseconds.toDouble(),
      'duration': player.totalDuration * 1000,
      'rate': player.speed,
    });
  }

  /// The cover as a local file the system can read: downloads keep one on
  /// disk already, server covers go through the image cache.
  Future<String?> _coverFile(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (url == _coverUrl) return _coverPath;
    String? path;
    try {
      if (url.startsWith('file:')) {
        path = Uri.parse(url).toFilePath(windows: true);
      } else if (url.startsWith('http')) {
        final headers = AudioPlayerService().currentApi?.mediaHeaders;
        final file =
            await DefaultCacheManager().getSingleFile(url, headers: headers);
        path = file.path;
      } else if (File(url).existsSync()) {
        path = url;
      }
    } catch (e) {
      debugPrint('[MediaControls] cover for the overlay failed: $e');
    }
    _coverUrl = url;
    _coverPath = path;
    return path;
  }

  Future<void> _invoke(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<bool>(method, args);
    } on MissingPluginException {
      // An older runner without the channel: nothing to show.
    } catch (e) {
      debugPrint('[MediaControls] $method failed: $e');
    }
  }
}
