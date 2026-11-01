import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Page turns drawn over pictures of the page.
const kDrawnTurnStyles = ['curl', 'ripple'];

/// Drives a [PageCurlLayer]: the reader hands it pictures of pages and the
/// finger's position, and the layer draws and animates the turn.
class PageCurlController {
  _PageCurlLayerState? _layer;

  bool get showing => _layer?._top != null;
  Size get size => _layer?._size ?? Size.zero;

  /// Lays [top] over the page, with [under] beneath it (the live page shows
  /// through when null). [away] is how far it has turned: 0 whole, 1 gone.
  /// [grabY] is the height a curl is held at; [origin] is where the other
  /// turns start from.
  void show(ui.Image top, {ui.Image? under, double away = 0, double? grabY, Offset? origin}) =>
      _layer?._show(top, under, away, grabY, origin);

  /// Moves the turn to [point]: the edge in hand for a curl, and for the
  /// others how far across the page it has come.
  void follow(Offset point) => _layer?._follow(point);

  /// Turns the page the rest of the way off, or lays it back down.
  Future<void> settle({required bool away}) => _layer?._settle(away) ?? Future.value();

  /// Plays the rest of the running turn quickly.
  void hurry() => _layer?._hurry();

  void hide() => _layer?._hide();
}

/// A page turn drawn over the reader. The page itself is a web view that
/// can't be bent or dissolved, so a picture of it turns while the real page
/// has already turned underneath.
class PageCurlLayer extends StatefulWidget {
  const PageCurlLayer({
    super.key,
    required this.controller,
    required this.pageColor,
    this.style = 'curl',
    this.inset = EdgeInsets.zero,
  });

  final PageCurlController controller;
  final Color pageColor;

  /// One of [kDrawnTurnStyles].
  final String style;

  /// Where the pictured page sits inside this layer; the rest is plain page.
  final EdgeInsets inset;

  @override
  State<PageCurlLayer> createState() => _PageCurlLayerState();
}

class _Shaders {
  static ui.FragmentProgram? ripple;
  static Future<void>? _loading;

  static Future<void> load() => _loading ??= () async {
        try {
          ripple = await ui.FragmentProgram.fromAsset('shaders/page_ripple.frag');
        } catch (e) {
          debugPrint('[PageTurn] the ripple shader did not load: $e');
        }
      }();
}

class _PageCurlLayerState extends State<PageCurlLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this);
  ui.Image? _top;
  ui.Image? _under;
  Size _size = Size.zero;
  double _grabY = 0;
  Offset _origin = Offset.zero;
  Offset _finger = Offset.zero;
  bool _settling = false;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  double _arc = 0;
  ui.FragmentShader? _ripple;
  Completer<void>? _settled;

  @override
  void initState() {
    super.initState();
    widget.controller._layer = this;
    _Shaders.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(PageCurlLayer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller._layer == this) old.controller._layer = null;
      widget.controller._layer = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._layer == this) widget.controller._layer = null;
    _anim.dispose();
    _ripple?.dispose();
    super.dispose();
  }

  Offset _at(double away) => Offset(_size.width - 2 * _size.width * away, _grabY);

  void _show(ui.Image top, ui.Image? under, double away, double? grabY, Offset? origin) {
    _anim.stop();
    _finishSettle();
    setState(() {
      _top = top;
      _under = under;
      _settling = false;
      _grabY = (grabY ?? _size.height * 0.88).clamp(0.0, _size.height);
      _origin = origin ?? Offset(_size.width * 0.8, _size.height * 0.5);
      _finger = _at(away);
    });
  }

  void _follow(Offset point) {
    if (_top == null) return;
    _anim.stop();
    _finishSettle();
    setState(() {
      _settling = false;
      _finger = point;
    });
  }

  Future<void> _settle(bool away) {
    if (_top == null || _size.isEmpty) return Future.value();
    _finishSettle();
    _from = _finger;
    _to = _at(away ? 1 : 0);
    final span = ((_to.dx - _from.dx).abs() / (2 * _size.width)).clamp(0.0, 1.0);
    final curl = widget.style == 'curl';
    // A longer trip lifts a curling page a little on the way, like a hand
    // turning it. The others take their time so the effect can be seen.
    _arc = curl ? _size.height * 0.08 * span : 0;
    final full = curl ? 340 : 1150;
    _anim.duration = Duration(milliseconds: (150 + full * span).round());
    _anim.value = 0;
    setState(() => _settling = true);
    final done = _settled = Completer<void>();
    unawaited(_anim.animateTo(1, curve: curl ? Curves.easeInOut : Curves.easeInOutSine).then((_) => _landed(done)));
    return done.future;
  }

  void _landed(Completer<void> done) {
    if (done.isCompleted) return;
    if (mounted && identical(done, _settled)) {
      _settling = false;
      _finger = _to;
    }
    done.complete();
  }

  void _hurry() {
    final done = _settled;
    if (done == null || done.isCompleted || !_anim.isAnimating) return;
    final left = 1 - _anim.value;
    unawaited(_anim
        .animateTo(1, duration: Duration(milliseconds: (40 + 180 * left).round()), curve: Curves.easeOut)
        .then((_) => _landed(done)));
  }

  /// Lets whoever waits on a settle go when something else cuts it short.
  void _finishSettle() {
    final done = _settled;
    _settled = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  void _hide() {
    _anim.stop();
    _finishSettle();
    if (_top == null) return;
    setState(() {
      _top = null;
      _under = null;
      _settling = false;
    });
  }

  CustomPainter _painter(ui.Image top, Offset finger) {
    final away = ((_size.width - finger.dx) / (2 * _size.width)).clamp(0.0, 1.0);
    final page = _Page(widget.pageColor, widget.inset);
    final ripple = _Shaders.ripple;
    if (widget.style == 'ripple' && ripple != null) {
      return _ShaderPainter(_ripple ??= ripple.fragmentShader(), page, top, _under, away, _origin);
    }
    return _CurlPainter(
      page: page,
      top: top,
      under: _under,
      edge: Offset(_size.width, _grabY),
      finger: finger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = constraints.biggest;
      final top = _top;
      if (top == null) return const SizedBox.shrink();
      return IgnorePointer(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final t = _anim.value;
            final finger = _settling ? Offset.lerp(_from, _to, t)! - Offset(0, _arc * sin(pi * t)) : _finger;
            return CustomPaint(size: _size, painter: _painter(top, finger));
          },
        ),
      );
    });
  }
}

/// A picture of the page laid where the web view sits, page color around it.
class _Page {
  const _Page(this.color, this.inset);

  final Color color;
  final EdgeInsets inset;

  Rect pictureRect(Rect area) => inset.deflateRect(area);

  void paint(Canvas canvas, Rect area, ui.Image image) {
    canvas.drawRect(area, Paint()..color = color);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, src, pictureRect(area), Paint()..filterQuality = FilterQuality.medium);
  }
}

/// The page folded along the line halfway between the edge being held and
/// the finger: the part beyond it flips over, showing its back.
class _CurlPainter extends CustomPainter {
  _CurlPainter({
    required this.page,
    required this.top,
    required this.under,
    required this.edge,
    required this.finger,
  });

  final _Page page;
  final ui.Image top;
  final ui.Image? under;
  final Offset edge;
  final Offset finger;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.clipRect(area);
    final under = this.under;
    if (under != null) page.paint(canvas, area, under);

    // The page turns on its spine, so the edge in hand can't be pulled
    // further from it than the page is wide.
    final spine = Offset(0, edge.dy);
    var f = finger;
    final reach = (f - spine).distance;
    if (reach > size.width) f = spine + (f - spine) * (size.width / reach);
    final pull = edge - f;
    final length = pull.distance;
    if (length < 0.5) {
      page.paint(canvas, area, top);
      return;
    }
    final n = pull / length;
    final fold = (edge + f) / 2;
    final corners = [area.topLeft, area.topRight, area.bottomRight, area.bottomLeft];
    final flat = _polygon(_side(corners, fold, n, lifted: false));
    final lifted = _polygon(_side(corners, fold, n, lifted: true));
    final mirror = _mirror(fold, n);
    final flap = lifted.transform(mirror.storage);

    // The page coming into view, darker where the lifted page still hangs
    // over it.
    canvas.save();
    canvas.clipPath(lifted);
    canvas.drawRect(
      area,
      Paint()
        ..shader = ui.Gradient.linear(fold, fold + n * min(48.0, length * 0.5 + 8), [
          Colors.black.withValues(alpha: 0.3),
          Colors.black.withValues(alpha: 0),
        ]),
    );
    canvas.restore();

    // The part still lying flat, with the shadow the flap throws on it.
    canvas.save();
    canvas.clipPath(flat);
    page.paint(canvas, area, top);
    canvas.drawPath(
      flap.shift(n * -3),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.restore();

    // The back of the flap: the print shows through faintly, mirrored.
    canvas.save();
    canvas.clipPath(flap);
    canvas.save();
    canvas.transform(mirror.storage);
    page.paint(canvas, area, top);
    canvas.restore();
    canvas.drawRect(area, Paint()..color = page.color.withValues(alpha: 0.88));
    canvas.drawRect(
      area,
      Paint()
        ..shader = ui.Gradient.linear(fold, f, [
          Colors.black.withValues(alpha: 0.16),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0.05),
        ], [0, 0.4, 1]),
    );
    canvas.restore();
  }

  /// The part of the convex polygon [points] on one side of the line through
  /// [fold] with normal [n]; [lifted] is the side [n] points to.
  static List<Offset> _side(List<Offset> points, Offset fold, Offset n, {required bool lifted}) {
    double side(Offset p) => (p.dx - fold.dx) * n.dx + (p.dy - fold.dy) * n.dy;
    bool keep(Offset p) => lifted ? side(p) > 0 : side(p) <= 0;
    final out = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      if (keep(a)) out.add(a);
      if (keep(a) != keep(b)) {
        final sa = side(a);
        final sb = side(b);
        out.add(Offset.lerp(a, b, sa / (sa - sb))!);
      }
    }
    return out;
  }

  static Path _polygon(List<Offset> points) {
    final path = Path();
    if (points.length >= 3) path.addPolygon(points, true);
    return path;
  }

  /// Reflection across the line through [fold] with unit normal [n].
  static Matrix4 _mirror(Offset fold, Offset n) {
    final d = 2 * (fold.dx * n.dx + fold.dy * n.dy);
    final xx = 1 - 2 * n.dx * n.dx;
    final xy = -2 * n.dx * n.dy;
    final yy = 1 - 2 * n.dy * n.dy;
    return Matrix4(xx, xy, 0, 0, xy, yy, 0, 0, 0, 0, 1, 0, d * n.dx, d * n.dy, 0, 1);
  }

  @override
  bool shouldRepaint(_CurlPainter old) => true;
}

/// Ripple: a shader blends the two pages, starting at [origin].
class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.shader, this.page, this.top, this.under, this.away, this.origin);

  final ui.FragmentShader shader;
  final _Page page;
  final ui.Image top;
  final ui.Image? under;
  final double away;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    final rect = page.pictureRect(area);
    final values = [
      size.width, size.height,
      rect.left, rect.top, rect.right, rect.bottom,
      page.color.r, page.color.g, page.color.b, 1.0,
      origin.dx, origin.dy,
      away,
      under != null ? 1.0 : 0.0,
    ];
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i, values[i]);
    }
    shader.setImageSampler(0, top);
    shader.setImageSampler(1, under ?? top);
    canvas.drawRect(area, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter old) => true;
}
