import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Where on screen the thing that was tapped sits, so a sheet can grow out of
/// it. Null when [context] isn't a small, visible widget: a whole page, say,
/// or one that has scrolled off. The sheet then slides up as usual.
Rect? growOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final screen = MediaQuery.sizeOf(context);
  if (rect.isEmpty ||
      rect.width > screen.width * 0.7 ||
      rect.height > screen.height * 0.6 ||
      !rect.overlaps(Offset.zero & screen)) {
    return null;
  }
  return rect;
}

/// Makes a bottom sheet open by growing out of [origin] and close by
/// shrinking back into it, following the sheet route's own animation so the
/// timing and the dimmed background behave exactly as they do for a sheet
/// that slides. Whatever the route does to slide the sheet is undone here,
/// by drawing the sheet where the growing shape says it should be.
///
/// [active] turns the effect off part-way through: a sheet that was swiped
/// down is already at the bottom of the screen, so it should just leave, not
/// fly back up to where it came from.
class GrowFromOrigin extends StatelessWidget {
  final Rect? origin;
  final ValueListenable<bool>? active;
  final Widget child;

  const GrowFromOrigin({
    super.key,
    required this.origin,
    this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final origin = this.origin;
    final animation = ModalRoute.of(context)?.animation;
    if (origin == null ||
        animation == null ||
        MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final screenHeight = MediaQuery.sizeOf(context).height;
    Widget build(bool active) => _Grow(
          origin: origin,
          animation: animation,
          screenHeight: screenHeight,
          active: active,
          child: FadeTransition(
            // The sheet's content fades in over the cover as it starts to
            // grow.
            opacity: active
                ? CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0, 0.4, curve: Curves.easeOut),
                  )
                : kAlwaysCompleteAnimation,
            child: child,
          ),
        );
    final active = this.active;
    if (active == null) return build(true);
    return ValueListenableBuilder<bool>(
      valueListenable: active,
      builder: (context, on, _) => build(on),
    );
  }
}

class _Grow extends SingleChildRenderObjectWidget {
  final Rect origin;
  final Animation<double> animation;
  final double screenHeight;
  final bool active;

  const _Grow({
    required this.origin,
    required this.animation,
    required this.screenHeight,
    required this.active,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGrow(origin, animation, screenHeight, active);

  @override
  void updateRenderObject(BuildContext context, _RenderGrow renderObject) {
    renderObject
      ..origin = origin
      ..animation = animation
      ..screenHeight = screenHeight
      ..active = active;
  }
}

class _RenderGrow extends RenderProxyBox {
  _RenderGrow(this._origin, this._animation, this._screenHeight, this._active);

  bool _active;
  set active(bool value) {
    if (value == _active) return;
    _active = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  Rect _origin;
  set origin(Rect value) {
    if (value == _origin) return;
    _origin = value;
    markNeedsPaint();
  }

  double _screenHeight;
  set screenHeight(double value) {
    if (value == _screenHeight) return;
    _screenHeight = value;
    markNeedsPaint();
  }

  Animation<double> _animation;
  set animation(Animation<double> value) {
    if (value == _animation) return;
    if (attached) _animation.removeListener(markNeedsPaint);
    _animation = value;
    if (attached) _animation.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsPaint);
    super.detach();
  }

  bool get _growing => _active && _animation.value < 1.0;

  @override
  bool get alwaysNeedsCompositing => child != null && _growing;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (!_growing || size.isEmpty) {
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    final t = Curves.easeOutCubic.transform(_animation.value.clamp(0.0, 1.0));
    // Where the route has put the sheet this frame (part-way through its
    // slide), and where it will rest: against the bottom of the screen.
    final now = localToGlobal(Offset.zero);
    final rest = Rect.fromLTWH(
      now.dx,
      _screenHeight - size.height,
      size.width,
      size.height,
    );
    final shape = Rect.lerp(_origin, rest, t)!;
    // The sheet is scaled to the shape's width and cut off at its height, so
    // it grows without being stretched out of proportion.
    final scale = shape.width / rest.width;
    if (scale <= 0) return;
    final visibleHeight = math.min(size.height, shape.height / scale);
    final radius = Radius.circular(lerpDouble(10, 28, t)! / scale);
    final transform = Matrix4.identity()
      ..translate(shape.left - now.dx, shape.top - now.dy)
      ..scale(scale, scale, 1.0);
    final clip = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, visibleHeight),
      topLeft: radius,
      topRight: radius,
      bottomLeft: radius,
      bottomRight: radius,
    );
    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      (context, offset) {
        context.pushClipRRect(
          needsCompositing,
          offset,
          Offset.zero & size,
          clip,
          (context, offset) => context.paintChild(child, offset),
        );
      },
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }
}
