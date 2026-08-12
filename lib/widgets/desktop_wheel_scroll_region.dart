import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lets a desktop pane's empty gutters scroll its primary content.
class DesktopWheelScrollRegion extends StatefulWidget {
  const DesktopWheelScrollRegion({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final ScrollController? controller;

  @override
  State<DesktopWheelScrollRegion> createState() =>
      _DesktopWheelScrollRegionState();
}

class _DesktopWheelScrollRegionState extends State<DesktopWheelScrollRegion> {
  final List<_DiscoveredScrollable> _discoveredScrollables = [];

  _WheelTarget? _targetFor(PointerScrollEvent event) {
    final controller = widget.controller;
    if (controller != null) {
      if (!controller.hasClients || controller.positions.length != 1) {
        return null;
      }
      return _targetForPosition(controller.position, event);
    }

    _discoveredScrollables.removeWhere(
      (candidate) => !candidate.scrollable.mounted,
    );
    _WheelTarget? bestTarget;
    var bestDepth = 1 << 20;
    var bestVisibleArea = -1.0;
    final preferredAxis =
        event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()
        ? Axis.vertical
        : Axis.horizontal;
    for (final candidate in _discoveredScrollables) {
      final scrollable = candidate.scrollable;
      if (!_isActive(scrollable)) continue;
      final position = scrollable.position;
      if (axisDirectionToAxis(position.axisDirection) != preferredAxis) {
        continue;
      }
      final target = _targetForPosition(position, event);
      if (target == null) continue;
      final visibleArea = _visibleArea(scrollable);
      if (visibleArea <= 0) continue;
      if (candidate.depth < bestDepth ||
          (candidate.depth == bestDepth && visibleArea > bestVisibleArea)) {
        bestTarget = target;
        bestDepth = candidate.depth;
        bestVisibleArea = visibleArea;
      }
    }
    return bestTarget;
  }

  double _visibleArea(ScrollableState scrollable) {
    final regionObject = context.findRenderObject();
    final scrollObject = scrollable.context.findRenderObject();
    if (regionObject is! RenderBox ||
        scrollObject is! RenderBox ||
        !regionObject.attached ||
        !scrollObject.attached) {
      return 0;
    }
    final scrollBounds = MatrixUtils.transformRect(
      scrollObject.getTransformTo(regionObject),
      scrollObject.paintBounds,
    );
    final visibleBounds = scrollBounds.intersect(
      Offset.zero & regionObject.size,
    );
    if (visibleBounds.isEmpty) return 0;
    return visibleBounds.width * visibleBounds.height;
  }

  _WheelTarget? _targetForPosition(
    ScrollPosition position,
    PointerScrollEvent event,
  ) {
    if (!position.hasContentDimensions ||
        !position.physics.shouldAcceptUserOffset(position)) {
      return null;
    }
    final axis = axisDirectionToAxis(position.axisDirection);
    var delta = axis == Axis.vertical
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (axisDirectionIsReversed(position.axisDirection)) delta = -delta;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (delta == 0 || target == position.pixels) return null;
    return _WheelTarget(position, delta);
  }

  bool _isActive(ScrollableState scrollable) {
    final renderObject = scrollable.context.findRenderObject();
    if (!(renderObject?.attached ?? false)) return false;
    final route = ModalRoute.of(scrollable.context);
    return (route == null || route.isCurrent) &&
        TickerMode.of(scrollable.context);
  }

  void _rememberPosition(BuildContext? notificationContext, int depth) {
    if (notificationContext == null) return;
    final scrollable = Scrollable.maybeOf(notificationContext);
    if (scrollable == null) return;
    _discoveredScrollables
      ..removeWhere((candidate) => candidate.scrollable == scrollable)
      ..insert(0, _DiscoveredScrollable(scrollable, depth));
  }

  bool _handleMetricsNotification(ScrollMetricsNotification notification) {
    _rememberPosition(notification.context, notification.depth);
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _rememberPosition(notification.context, notification.depth);
    return false;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final target = _targetFor(event);
    if (target == null) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (
      resolvedEvent,
    ) {
      if (resolvedEvent is! PointerScrollEvent) return;
      target.position.pointerScroll(target.delta);
      resolvedEvent.respond(allowPlatformDefault: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: _handlePointerSignal,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _handleMetricsNotification,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
      ),
    );
  }
}

class _DiscoveredScrollable {
  const _DiscoveredScrollable(this.scrollable, this.depth);

  final ScrollableState scrollable;
  final int depth;
}

class _WheelTarget {
  const _WheelTarget(this.position, this.delta);

  final ScrollPosition position;
  final double delta;
}
