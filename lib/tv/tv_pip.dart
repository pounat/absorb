import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_player_service.dart';
import 'tv_cover_tile.dart';

/// The TV's picture-in-picture: while a book plays, leaving the app for
/// the TV's home screen shrinks it into the corner window, showing the
/// cover, the way TV apps keep a show going there.
class TvPip {
  static const _channel = MethodChannel('com.barnabas.absorb/tv_pip');

  /// Whether the app is in the corner window now.
  static final inPip = ValueNotifier<bool>(false);

  static bool _started = false;
  static bool? _sent;

  static void start() {
    if (_started) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pipChanged') inPip.value = call.arguments == true;
    });
    AudioPlayerService().addListener(_sync);
    _sync();
  }

  // The window only opens while something plays; paused, Home just leaves.
  static void _sync() {
    final playing = AudioPlayerService().isPlaying;
    if (playing == _sent) return;
    _sent = playing;
    _channel.invokeMethod<void>('setAutoPip', playing).catchError((_) {});
  }

  /// Into the corner window now, as Back from Home does while playing.
  /// False where the TV has no picture-in-picture.
  static Future<bool> enter() async {
    try {
      return await _channel.invokeMethod<bool>('enter') ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// What the corner window shows: the cover, and a thin line for how far
/// into the book.
class TvPipView extends StatefulWidget {
  const TvPipView({super.key});

  @override
  State<TvPipView> createState() => _TvPipViewState();
}

class _TvPipViewState extends State<TvPipView> {
  final _player = AudioPlayerService();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _player.addListener(_changed);
    _tick = Timer.periodic(const Duration(seconds: 5), (_) => _changed());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _player.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = _player.totalDuration;
    final pos = _player.position.inMilliseconds / 1000;
    final title = _player.currentEpisodeTitle ?? _player.currentTitle ?? '';
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = box.biggest.shortestSide;
          return Stack(
            children: [
              Center(
                child: SizedBox.square(
                  dimension: side,
                  child: TvCover(itemId: _player.currentItemId, title: title, author: '', width: 300),
                ),
              ),
              if (total > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: (pos / total).clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: Colors.black45,
                    color: Colors.white,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
