import 'package:flutter/material.dart';

/// Drives a continuous 0..1 reveal value from a scroll position so headers
/// and the bottom nav can hide/reveal in lockstep with finger movement.
///
/// 1.0 = fully visible, 0.0 = fully hidden. Snap to nearest end on scroll
/// stop using a short ease, so partial states never persist.
class ScrollRevealDriver {
  ScrollRevealDriver({
    required TickerProvider vsync,
    this.hideBudgetPx = 60.0,
    Duration snapDuration = const Duration(milliseconds: 200),
    Curve snapCurve = Curves.easeOutCubic,
  })  : _snapCurve = snapCurve {
    _snapController = AnimationController(vsync: vsync, duration: snapDuration);
    _snapController.addListener(_onSnapTick);
  }

  /// Pixels of accumulated scroll delta that take the bar from shown to hidden.
  final double hideBudgetPx;
  final Curve _snapCurve;

  /// Continuous 0..1. Bind your SizeTransition / SlideTransition to this.
  final ValueNotifier<double> notifier = ValueNotifier(1.0);

  late final AnimationController _snapController;
  double _snapStart = 1.0;
  double _snapEnd = 1.0;

  ScrollController? _attached;
  double _lastOffset = 0.0;
  bool _enabled = true;

  /// Sign of the most recent meaningful scroll delta: +1 = scrolling down
  /// (hide direction), -1 = scrolling up (show direction). Used by `settle`
  /// so a stop mid-scroll snaps in the direction the user was already going,
  /// rather than always snapping to the nearest 0/1 endpoint.
  int _lastDir = 0;
  double _lastPixels = 0.0;

  /// Hook the driver to the currently visible scroll controller. Switching
  /// tabs should call this with the new controller; the previous one is
  /// detached and the offset baseline is rebased so the bar doesn't jump.
  void attach(ScrollController controller) {
    if (identical(_attached, controller)) return;
    detach();
    _attached = controller;
    _lastOffset = controller.hasClients ? controller.offset : 0.0;
    controller.addListener(_onScroll);
  }

  void detach() {
    _attached?.removeListener(_onScroll);
    _attached = null;
  }

  /// Force the bar fully visible without animation. Safe to call from
  /// lifecycle events, tab switches, search activation, etc.
  void resetToShown() {
    _snapController.stop();
    notifier.value = 1.0;
    // Desktop disables the driver during the first build, before the list has
    // attached to the controller; reading offset then threw.
    final c = _attached;
    _lastOffset = c != null && c.hasClients ? c.offset : 0.0;
    _lastDir = 0;
  }

  /// Disable scroll-driven hiding (use during search). Snaps bar to shown
  /// while disabled so the user always sees navigation.
  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    if (!enabled) resetToShown();
  }

  void _onScroll() {
    if (!_enabled) return;
    final c = _attached;
    if (c == null || !c.hasClients) return;
    final offset = c.offset;
    final delta = offset - _lastOffset;
    _lastOffset = offset;
    _lastPixels = offset;

    if (offset <= 0) {
      if (notifier.value < 1.0) {
        _snapController.stop();
        notifier.value = 1.0;
      }
      return;
    }
    if (delta.abs() < 0.5) return;
    _lastDir = delta > 0 ? 1 : -1;

    final current = notifier.value;
    final next = (current - delta / hideBudgetPx).clamp(0.0, 1.0);
    // Skip no-op updates so we don't trigger an AppShell rebuild + Scaffold
    // relayout on every scroll tick after the bar is already fully hidden or
    // fully visible. This is the difference between buttery scroll and jank.
    if ((current - next).abs() < 0.005) return;

    _snapController.stop();
    notifier.value = next;
  }

  /// Feed a scroll delta directly. Use when listening via NotificationListener
  /// instead of attaching a ScrollController (e.g. across multiple per-tab
  /// scroll views in an IndexedStack).
  void noteScroll(double scrollDelta, double pixels) {
    if (!_enabled) return;
    _lastPixels = pixels;
    if (pixels <= 0) {
      if (notifier.value < 1.0) {
        _snapController.stop();
        notifier.value = 1.0;
      }
      return;
    }
    if (scrollDelta.abs() < 0.5) return;
    _lastDir = scrollDelta > 0 ? 1 : -1;
    final current = notifier.value;
    final next = (current - scrollDelta / hideBudgetPx).clamp(0.0, 1.0);
    if ((current - next).abs() < 0.005) return;
    _snapController.stop();
    notifier.value = next;
  }

  /// Animate to the end matching the last scroll direction (so a stop while
  /// the user was still scrolling down hides the bar; a stop while scrolling
  /// up shows it). At the very top of the scroll, always show. Wire to
  /// ScrollEndNotification.
  void settle() {
    if (!_enabled) {
      notifier.value = 1.0;
      return;
    }
    final v = notifier.value;
    final c = _attached;
    final atTop = (c != null && c.hasClients && c.offset <= 0) ||
        (c == null && _lastPixels <= 0);
    final double target;
    if (atTop) {
      target = 1.0;
    } else if (_lastDir < 0) {
      target = 1.0; // scrolling up — finish revealing
    } else if (_lastDir > 0) {
      target = 0.0; // scrolling down — finish hiding
    } else {
      // No recorded direction (rare): fall back to nearest end.
      target = v >= 0.5 ? 1.0 : 0.0;
    }
    if ((v - target).abs() < 0.001) return;
    _snapStart = v;
    _snapEnd = target;
    _snapController
      ..value = 0.0
      ..forward();
  }

  void _onSnapTick() {
    final t = _snapCurve.transform(_snapController.value);
    notifier.value = _snapStart + (_snapEnd - _snapStart) * t;
  }

  void dispose() {
    detach();
    _snapController.removeListener(_onSnapTick);
    _snapController.dispose();
    notifier.dispose();
  }
}
