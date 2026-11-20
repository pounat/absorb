import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'glass_look.dart';

/// Material 3 Expressive look (Android): shaped highlights that roll, squash
/// and morph. Off by default; driven by the setting of the same name.
final ValueNotifier<bool> expressiveNotifier = ValueNotifier(false);

/// A round shape with soft bumps around its edge, the family the Material
/// "cookie", "clover" and "sunny" shapes come from. [lobes] is how many bumps
/// and [depth] how deep the dips between them go (0 is a plain circle).
class WavyShape {
  final int lobes;
  final double depth;
  const WavyShape(this.lobes, this.depth);

  static const circle = WavyShape(1, 0);
  static const cookie9 = WavyShape(9, 0.07);
  static const clover = WavyShape(4, 0.14);
  static const cookie6 = WavyShape(6, 0.1);
  static const sunny = WavyShape(12, 0.05);
  static const softSquare = WavyShape(4, 0.045);

  /// The shapes the nav highlight cycles through, one per tab change.
  static const rolling = [cookie9, clover, cookie6, sunny];

  double radiusAt(double angle) =>
      1 - depth + depth * math.cos(lobes * angle);
}

const int _samples = 144;

/// The outline of [a] morphed toward [b] by [t], centred on the origin with
/// a radius of 1 at its widest.
Path wavyPath(WavyShape a, [WavyShape? b, double t = 0]) {
  final path = Path();
  for (var i = 0; i < _samples; i++) {
    final angle = i / _samples * math.pi * 2;
    var r = a.radiusAt(angle);
    if (b != null) r += (b.radiusAt(angle) - r) * t;
    final x = r * math.cos(angle);
    final y = r * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}

double _span(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0.0, 1.0);

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Draws the nav bar's highlight behind [child]. When the selected tab
/// changes, the pill pops into a bumpy shape, rolls over to the new tab,
/// squashes as it lands and settles flat again.
class ExpressiveNavHighlight extends StatefulWidget {
  final int selectedIndex;
  final int count;
  final Color background;
  final Color pillColor;
  final Color shapeColor;
  final Widget child;

  const ExpressiveNavHighlight({
    super.key,
    required this.selectedIndex,
    required this.count,
    required this.background,
    required this.pillColor,
    required this.shapeColor,
    required this.child,
  });

  @override
  State<ExpressiveNavHighlight> createState() => _ExpressiveNavHighlightState();
}

class _ExpressiveNavHighlightState extends State<ExpressiveNavHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
    value: 1,
  );
  late int _from = widget.selectedIndex;
  int _shapeAt = 0;
  WavyShape _shape = WavyShape.rolling.first;

  @override
  void didUpdateWidget(ExpressiveNavHighlight old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex == widget.selectedIndex) return;
    // A tab added or removed shifts every slot, so there is nothing sensible
    // to roll from.
    if (old.count != widget.count || MediaQuery.disableAnimationsOf(context)) {
      _from = widget.selectedIndex;
      _controller.value = 1;
      return;
    }
    _from = old.selectedIndex;
    _shape = WavyShape.rolling[_shapeAt++ % WavyShape.rolling.length];
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The bar keeps its tabs inside the safe area, so in landscape they sit
    // clear of the camera cutout; the highlight has to measure the same span
    // or it drifts further off with every tab.
    final inset = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: widget.background)),
        Positioned(
          left: inset.left,
          right: inset.right,
          top: 0,
          bottom: 0,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _NavHighlightPainter(
                progress: _controller,
                from: _from,
                to: widget.selectedIndex,
                count: widget.count,
                shape: _shape,
                pillColor: widget.pillColor,
                shapeColor: widget.shapeColor,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _NavHighlightPainter extends CustomPainter {
  final Animation<double> progress;
  final int from;
  final int to;
  final int count;
  final WavyShape shape;
  final Color pillColor;
  final Color shapeColor;
  final bool rtl;

  _NavHighlightPainter({
    required this.progress,
    required this.from,
    required this.to,
    required this.count,
    required this.shape,
    required this.pillColor,
    required this.shapeColor,
    required this.rtl,
  }) : super(repaint: progress);

  // The Material 3 nav bar's own measurements: a 64 by 32 pill whose middle
  // sits 28 down from the top, with or without labels.
  static const _pillWidth = 64.0;
  static const _pillHeight = 32.0;
  static const _centerY = 28.0;
  static const _shapeSize = 38.0;
  static const _travel = Cubic(0.45, 0, 0.25, 1);

  double _centerX(int index, double width) {
    final slot = width / count;
    final x = (index.clamp(0, count - 1) + 0.5) * slot;
    return rtl ? width - x : x;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0) return;
    final t = progress.value;
    final x1 = _centerX(from, size.width);
    final x2 = _centerX(to, size.width);

    if (t >= 1 || from == to) {
      _paintPill(canvas, x2, _pillWidth, 1);
      return;
    }

    // The pill: shrinks to a dot where it was, hides while the shape rolls,
    // then grows back out of a dot where it lands.
    if (t < 0.22) {
      final shrink = _span(t, 0, 0.16);
      _paintPill(
        canvas,
        x1,
        _lerp(_pillWidth, _pillHeight, shrink),
        1 - _span(t, 0.16, 0.22),
      );
    } else if (t > 0.8) {
      final grow = _span(t, 0.86, 1);
      _paintPill(
        canvas,
        x2,
        _lerp(_pillHeight, _pillWidth, grow),
        _span(t, 0.8, 0.86),
      );
    }

    // The shape: swells in, rolls across, then squashes flat as it lands.
    final roll = _travel.transform(_span(t, 0.24, 0.76));
    final x = _lerp(x1, x2, roll);
    final turn = (x2 - x1) / (math.pi * _shapeSize) * math.pi * 2;
    double scaleX;
    double scaleY;
    double opacity;
    if (t < 0.14) {
      scaleX = scaleY = _lerp(0.6, 0.8, _span(t, 0, 0.14));
      opacity = 0;
    } else if (t < 0.24) {
      final s = _span(t, 0.14, 0.24);
      scaleX = scaleY = _lerp(0.8, 1.12, s);
      opacity = s;
    } else if (t < 0.76) {
      scaleX = scaleY = 1.12;
      opacity = 1;
    } else if (t < 0.86) {
      final s = _span(t, 0.76, 0.86);
      scaleX = _lerp(1.12, 1.3, s);
      scaleY = _lerp(1.12, 0.7, s);
      opacity = _lerp(1, 0.6, s);
    } else {
      final s = _span(t, 0.86, 0.94);
      scaleX = _lerp(1.3, 1.4, s);
      scaleY = _lerp(0.7, 0.6, s);
      opacity = _lerp(0.6, 0, s);
    }
    if (opacity <= 0) return;
    canvas.save();
    canvas.translate(x, _centerY);
    canvas.scale(scaleX * _shapeSize / 2, scaleY * _shapeSize / 2);
    canvas.rotate(turn * roll);
    canvas.drawPath(
      wavyPath(shape),
      Paint()..color = shapeColor.withValues(alpha: shapeColor.a * opacity),
    );
    canvas.restore();
  }

  void _paintPill(Canvas canvas, double centerX, double width, double opacity) {
    if (opacity <= 0) return;
    final rect = Rect.fromCenter(
      center: Offset(centerX, _centerY),
      width: width,
      height: _pillHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(_pillHeight / 2)),
      Paint()..color = pillColor.withValues(alpha: pillColor.a * opacity),
    );
  }

  @override
  bool shouldRepaint(_NavHighlightPainter old) =>
      old.from != from ||
      old.to != to ||
      old.count != count ||
      old.shape != shape ||
      old.pillColor != pillColor ||
      old.shapeColor != shapeColor ||
      old.rtl != rtl;
}

/// The play button's body: a bumpy cookie while paused that turns and morphs
/// into a soft square while playing.
class ExpressivePlayShape extends StatelessWidget {
  final double size;
  final bool playing;
  final Color color;
  final Widget child;

  const ExpressivePlayShape({
    super.key,
    required this.size,
    required this.playing,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: playing ? 1 : 0),
      duration: still ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => CustomPaint(
        painter: _PlayShapePainter(t: t, color: color),
        child: child,
      ),
      child: SizedBox(width: size, height: size, child: Center(child: child)),
    );
  }
}

class _PlayShapePainter extends CustomPainter {
  final double t;
  final Color color;

  _PlayShapePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    // easeOutBack overshoots past 1, which gives the morph its little bounce
    // in size and turn; the outline itself stays between the two shapes.
    final morph = t.clamp(0.0, 1.0);
    final path = wavyPath(WavyShape.cookie9, WavyShape.softSquare, morph);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(t * math.pi / 4);
    final scale = radius * (1 + 0.06 * (t - morph).abs());
    canvas.scale(scale, scale);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlayShapePainter old) =>
      old.t != t || old.color != color;
}

/// The play button drawn over the cover: a dark circle with the accent icon,
/// or the morphing shape when the Expressive look is on.
class CoverPlayButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool playing;
  final Color accent;

  const CoverPlayButton({
    super.key,
    required this.size,
    required this.iconSize,
    required this.playing,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // On iOS glass the play icon morphs into the pause icon. It draws from
    // its top-left corner, so it needs centering in the circle.
    final Widget icon = glassLook && !expressiveNotifier.value
        ? Center(child: MorphingPlayIcon(playing: playing, size: iconSize, color: accent))
        : Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: iconSize,
            color: accent,
          );
    final fill = Colors.black.withValues(alpha: 0.45);
    return ValueListenableBuilder<bool>(
      valueListenable: expressiveNotifier,
      builder: (context, expressive, _) => expressive
          ? ExpressivePlayShape(
              size: size,
              playing: playing,
              color: fill,
              child: icon,
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
              child: icon,
            ),
    );
  }
}

/// The Expressive loading indicator: one filled shape that keeps turning
/// while it morphs from one outline to the next.
class ExpressiveLoader extends StatefulWidget {
  final Color? color;
  const ExpressiveLoader({super.key, this.color});

  @override
  State<ExpressiveLoader> createState() => _ExpressiveLoaderState();
}

class _ExpressiveLoaderState extends State<ExpressiveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _LoaderPainter(progress: _controller, color: color),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final Animation<double> progress;
  final Color color;

  _LoaderPainter({required this.progress, required this.color})
      : super(repaint: progress);

  static const _shapes = [
    WavyShape.cookie9,
    WavyShape.softSquare,
    WavyShape.clover,
    WavyShape.cookie6,
    WavyShape.sunny,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value * _shapes.length;
    final index = t.floor() % _shapes.length;
    // Hold each shape for a beat, then morph quickly into the next.
    final morph = Curves.easeInOutCubic.transform(_span(t - t.floor(), 0.35, 1));
    final path = wavyPath(
      _shapes[index],
      _shapes[(index + 1) % _shapes.length],
      morph,
    );
    final radius = size.shortestSide / 2;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(progress.value * math.pi * 2);
    canvas.scale(radius, radius);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.color != color;
}

/// A spinner that is the usual ring, or the shape loader when the Expressive
/// look is on. Takes the same two settings the ring is given around the app.
class AdaptiveSpinner extends StatelessWidget {
  final double? strokeWidth;
  final Color? color;
  const AdaptiveSpinner({super.key, this.strokeWidth, this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: expressiveNotifier,
      builder: (context, expressive, _) =>
          expressive && !MediaQuery.disableAnimationsOf(context)
              ? ExpressiveLoader(color: color)
              : CircularProgressIndicator(
                  strokeWidth: strokeWidth,
                  color: color,
                ),
    );
  }
}

/// Gives [child] a springy pop each time [active] turns on, when the
/// Expressive look is on. Otherwise it is just [child].
class ExpressivePop extends StatefulWidget {
  final bool active;
  final Widget child;
  const ExpressivePop({super.key, required this.active, required this.child});

  @override
  State<ExpressivePop> createState() => _ExpressivePopState();
}

class _ExpressivePopState extends State<ExpressivePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    value: 1,
  );

  // Squash and stretch: swells wide and flat, rebounds tall and narrow, then
  // settles. Width and height move opposite ways so it reads as jelly, not
  // as a plain grow and shrink.
  static final _wide = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.24)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 22,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.24, end: 0.93)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.93, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 48,
    ),
  ]);
  static final _tall = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.8)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 22,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.8, end: 1.12)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.12, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 48,
    ),
  ]);

  @override
  void didUpdateWidget(ExpressivePop old) {
    super.didUpdateWidget(old);
    if (widget.active &&
        !old.active &&
        expressiveNotifier.value &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            _wide.transform(_controller.value),
            _tall.transform(_controller.value),
            1,
          ),
          child: child,
        ),
        child: widget.child,
      );
}

/// Where a button sits in a connected row, so it can round its outer corners
/// and keep the ones facing its neighbours tight.
class ExpressiveGroupSlot extends InheritedWidget {
  final bool first;
  final bool last;
  final double outer;

  const ExpressiveGroupSlot({
    super.key,
    required this.first,
    required this.last,
    this.outer = 24,
    required super.child,
  });

  static ExpressiveGroupSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExpressiveGroupSlot>();

  @override
  bool updateShouldNotify(ExpressiveGroupSlot old) =>
      old.first != first || old.last != last || old.outer != outer;
}

/// A card button's corners. Outside a connected row this is the plain
/// [radius] all round. [round] is for a button
/// that is switched on, which goes fully round to stand out from the row.
BorderRadius cardButtonCorners(
  BuildContext context,
  double radius, {
  bool round = false,
}) {
  final slot = ExpressiveGroupSlot.maybeOf(context);
  if (slot == null) return BorderRadius.circular(radius);
  final outer = Radius.circular(slot.outer);
  const inner = Radius.circular(7);
  if (round) return BorderRadius.all(outer);
  return BorderRadiusDirectional.horizontal(
    start: slot.first ? outer : inner,
    end: slot.last ? outer : inner,
  ).resolve(Directionality.of(context));
}

/// A row of buttons that act as one group: a thin gap between them and,
/// with [widen], the one under the finger widens while its neighbours give
/// way.
class ExpressiveButtonRow extends StatefulWidget {
  final List<Widget> children;
  final bool widen;
  final double gap;
  final double outer;
  const ExpressiveButtonRow({
    super.key,
    required this.children,
    this.widen = true,
    this.gap = 3,
    this.outer = 24,
  });

  @override
  State<ExpressiveButtonRow> createState() => _ExpressiveButtonRowState();
}

class _ExpressiveButtonRowState extends State<ExpressiveButtonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  List<double> _from = const [];
  List<double> _to = const [];
  int? _pressed;

  List<double> _targets(int? pressed) {
    final n = widget.children.length;
    if (pressed == null || n < 2 || !widget.widen) return List.filled(n, 1.0);
    const grow = 0.2;
    return [for (var i = 0; i < n; i++) i == pressed ? 1 + grow : 1 - grow / (n - 1)];
  }

  List<double> _current() {
    final n = widget.children.length;
    if (_from.length != n || _to.length != n) return _targets(_pressed);
    final t = Curves.easeOutBack.transform(_controller.value);
    return [for (var i = 0; i < n; i++) _lerp(_from[i], _to[i], t)];
  }

  void _setPressed(int? index) {
    if (index == _pressed) return;
    _from = _current();
    _pressed = index;
    _to = _targets(index);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final weights = _current();
        return Row(
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              Expanded(
                flex: (weights[i] * 1000).round().clamp(1, 100000),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => _setPressed(i),
                  onPointerUp: (_) => _setPressed(null),
                  onPointerCancel: (_) => _setPressed(null),
                  child: ExpressiveGroupSlot(
                    first: i == 0,
                    last: i == n - 1,
                    outer: widget.outer,
                    child: widget.children[i],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A soft tonal shape drawn behind a player control, so the skip and chapter
/// buttons read as chunky controls next to the play button.
class ExpressiveControlBox extends StatelessWidget {
  final double width;
  final double height;
  final bool soft;
  final Widget child;

  const ExpressiveControlBox({
    super.key,
    required this.width,
    required this.height,
    required this.soft,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!expressiveNotifier.value) {
      return SizedBox(width: width, height: height, child: child);
    }
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ControlShapePainter(soft: soft, color: color),
        child: child,
      ),
    );
  }
}

class _ControlShapePainter extends CustomPainter {
  final bool soft;
  final Color color;
  _ControlShapePainter({required this.soft, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 * (soft ? 0.98 : 0.84);
    canvas.translate(size.width / 2, size.height / 2);
    if (soft) canvas.rotate(math.pi / 4);
    canvas.scale(radius, radius);
    canvas.drawPath(
      wavyPath(soft ? WavyShape.softSquare : WavyShape.circle),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_ControlShapePainter old) =>
      old.soft != soft || old.color != color;
}
