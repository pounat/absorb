import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show rootNavigatorKey;
import '../services/audio_player_service.dart';
import '../services/scoped_prefs.dart';
import '../services/screen_wake.dart';
import '../services/sleep_timer_service.dart';

/// Night mode for the TV: the screen goes nearly black while the book keeps
/// playing, with a faint panel of the time, where the book and chapter are
/// and the sleep timer. Any press of the remote, Back included, brings the
/// player back. It is a screen of its own so Back closes it rather than the
/// player under it. The screen is held on meanwhile, so the TV's own
/// screensaver doesn't light the room up.
class TvNightMode {
  static bool _on = false;

  static bool get isOn => _on;

  static void start() {
    final nav = rootNavigatorKey.currentState;
    if (_on || nav == null) return;
    nav.push(_NightRoute());
  }
}

class _NightRoute extends PageRoute<void> {
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  bool get opaque => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  @override
  void install() {
    super.install();
    TvNightMode._on = true;
    ScreenWake.hold('tv-night', true);
  }

  @override
  void dispose() {
    TvNightMode._on = false;
    ScreenWake.hold('tv-night', false);
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      const _NightScreen();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      FadeTransition(opacity: animation, child: child);
}

class _NightScreen extends StatefulWidget {
  const _NightScreen();

  @override
  State<_NightScreen> createState() => _NightScreenState();
}

class _NightScreenState extends State<_NightScreen> {
  static const _faint = Color(0x40FFFFFF);
  static const _fainter = Color(0x1FFFFFFF);

  final _player = AudioPlayerService();
  final _sleep = SleepTimerService();
  final _focus = FocusNode(debugLabel: 'tv night');
  final _random = Random();
  Timer? _tick;
  Timer? _move;
  Alignment _spot = const Alignment(0, 0.4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // The panel wanders, so nothing sits in one place on the panel for hours.
    _move = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) {
        setState(() => _spot = Alignment(_random.nextDouble() * 1.2 - 0.6, _random.nextDouble() * 1.2 - 0.6));
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _move?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _wake() {
    if (mounted) Navigator.of(context).maybePop();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    // Back arrives twice: as this key, then as the system's own back, which
    // closes this screen on its own. Waking on the key as well took the
    // player under it with it.
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.goBack || k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.browserBack) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    _wake();
    // Play/pause still does its job as it wakes the screen; any other
    // press only wakes it.
    final media = event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
        event.logicalKey == LogicalKeyboardKey.mediaPlay ||
        event.logicalKey == LogicalKeyboardKey.mediaPause;
    return media ? KeyEventResult.ignored : KeyEventResult.handled;
  }

  static String _clock(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(h > 0 ? 2 : 1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Widget _bar(double value) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 3,
          backgroundColor: _fainter,
          color: _faint,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pos = _player.position.inMilliseconds / 1000;
    final total = _player.totalDuration;
    final title = _player.currentEpisodeTitle ?? _player.currentTitle ?? '';
    final chapter = _player.currentChapter;
    final chStart = (chapter?['start'] as num?)?.toDouble() ?? 0;
    final chEnd = (chapter?['end'] as num?)?.toDouble() ?? total;
    final chTitle = chapter?['title'] as String?;
    final now = TimeOfDay.now().format(context);

    String? sleep;
    if (_sleep.mode == SleepTimerMode.time) {
      sleep = _clock(_sleep.timeRemaining);
    } else if (_sleep.isActive) {
      sleep = _sleep.displayLabel;
    }

    TextStyle? style(TextStyle? base, Color color) =>
        base?.copyWith(color: color, decoration: TextDecoration.none);

    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: _wake,
        child: ColoredBox(
          color: Colors.black,
          child: AnimatedAlign(
            alignment: _spot,
            duration: const Duration(seconds: 3),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(now, style: style(tt.displaySmall?.copyWith(fontWeight: FontWeight.w300), _faint)),
                  const SizedBox(height: 14),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: style(tt.titleMedium, _faint)),
                  if (chTitle != null && chEnd > chStart) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: Text(chTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: style(tt.bodySmall, _faint)),
                      ),
                      Text(_clock(Duration(seconds: (chEnd - pos).round().clamp(0, 1 << 30))), style: style(tt.bodySmall, _faint)),
                    ]),
                    const SizedBox(height: 6),
                    _bar((pos - chStart) / (chEnd - chStart)),
                  ],
                  if (total > 0) ...[
                    const SizedBox(height: 12),
                    _bar(pos / total),
                  ],
                  if (sleep != null) ...[
                    const SizedBox(height: 16),
                    Row(children: [
                      const Icon(Icons.bedtime_rounded, size: 16, color: _faint),
                      const SizedBox(width: 8),
                      Text(sleep, style: style(tt.bodyMedium, _faint)),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Night mode coming on by itself: only while a sleep timer runs and a book
/// plays, once the remote has sat still for [minutes]. 0 is off.
class TvAutoNight {
  static const _prefKey = 'tv_auto_night_minutes';
  static final minutes = ValueNotifier<int>(2);
  static DateTime _lastPress = DateTime.now();
  static Timer? _check;

  static Future<void> start() async {
    if (_check != null) return;
    minutes.value = await ScopedPrefs.getInt(_prefKey) ?? 2;
    HardwareKeyboard.instance.addHandler(_onKey);
    _check = Timer.periodic(const Duration(seconds: 15), (_) => _maybeDarken());
  }

  static void setMinutes(int m) {
    minutes.value = m;
    _lastPress = DateTime.now();
    ScopedPrefs.setInt(_prefKey, m);
  }

  // Only watches; the press still goes where it was going.
  static bool _onKey(KeyEvent event) {
    _lastPress = DateTime.now();
    return false;
  }

  static void _maybeDarken() {
    final m = minutes.value;
    if (m <= 0 || TvNightMode.isOn) return;
    if (!SleepTimerService().isActive || !AudioPlayerService().isPlaying) return;
    if (DateTime.now().difference(_lastPress) >= Duration(minutes: m)) TvNightMode.start();
  }
}
