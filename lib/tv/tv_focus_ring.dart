import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Marks a control that shows the remote's focus itself, so the ring
/// leaves it alone.
class TvDrawsOwnFocus extends InheritedWidget {
  const TvDrawsOwnFocus({super.key, required super.child});

  @override
  bool updateShouldNotify(TvDrawsOwnFocus oldWidget) => false;
}

/// Where the remote is, on a TV: a clear outline around whatever has focus,
/// in any sheet, dialog or list, so every standard control shows it without
/// each needing its own. Sits over the whole app and follows the focused
/// control as it moves or scrolls.
class TvFocusRing extends StatefulWidget {
  const TvFocusRing({super.key});

  @override
  State<TvFocusRing> createState() => _TvFocusRingState();
}

class _TvFocusRingState extends State<TvFocusRing> {
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_track);
    _track();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_track);
    super.dispose();
  }

  /// The rect to ring, or null for nothing: no focus, a whole screen or
  /// row taking keys, or a control that shows focus itself.
  Rect? _target() {
    final node = FocusManager.instance.primaryFocus;
    final ctx = node?.context;
    if (node == null || ctx == null || node is FocusScopeNode || !ctx.mounted) return null;
    if (ctx.getInheritedWidgetOfExactType<TvDrawsOwnFocus>() != null) return null;
    final screen = MediaQuery.sizeOf(context);
    final r = node.rect;
    if (r.isEmpty || r.width * r.height > screen.width * screen.height * 0.4) return null;
    return r;
  }

  // Re-checked after every frame while something is ringed, so the ring
  // keeps up with lists scrolling and sheets sliding; idle, nothing runs.
  void _track() {
    if (!mounted) return;
    final next = _target();
    if (next != _rect) setState(() => _rect = next);
    if (next != null) SchedulerBinding.instance.addPostFrameCallback((_) => _track());
  }

  @override
  Widget build(BuildContext context) {
    final r = _rect;
    if (r == null) return const SizedBox.shrink();
    final ring = r.inflate(4);
    final radius = (ring.shortestSide / 2).clamp(6.0, 16.0);
    return IgnorePointer(
      child: Stack(children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          left: ring.left,
          top: ring.top,
          width: ring.width,
          height: ring.height,
          // A white line with a thin dark edge outside it, so it shows on
          // light and dark alike. No shadow: one under a hollow box darkens
          // what's inside it.
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius + 1),
              border: Border.all(color: Colors.black54, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
