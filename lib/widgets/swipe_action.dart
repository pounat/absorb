import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// How far a row has to travel before a swipe action fires.
///
/// Flutter's 0.4 default was easy to cross by accident while scrolling: a drag
/// that starts with any sideways bias hands the gesture to the horizontal
/// recognizer, and the natural arc of a thumb carries it the rest of the way.
const double kSwipeActionThreshold = 0.6;

const Map<DismissDirection, double> kSwipeActionThresholds = {
  DismissDirection.startToEnd: kSwipeActionThreshold,
  DismissDirection.endToStart: kSwipeActionThreshold,
};

/// One side of a swipe: what it looks like and what it does.
class SwipeActionSpec {
  final IconData icon;
  final Color color;
  final FutureOr<void> Function() onTrigger;

  const SwipeActionSpec({
    required this.icon,
    required this.color,
    required this.onTrigger,
  });
}

/// A row you can swipe sideways to act on, without the row going anywhere.
///
/// The reveal builds with the drag rather than sitting flat: the pad deepens,
/// the icon grows into place, and crossing the commit point ticks the haptics
/// so you can feel it before you let go. Releasing past that point washes the
/// action's colour across the row, like it soaked in.
class SwipeAction extends StatefulWidget {
  final Widget child;
  final SwipeActionSpec? onStartToEnd;
  final SwipeActionSpec? onEndToStart;
  final BorderRadius borderRadius;

  const SwipeAction({
    super.key,
    required this.child,
    this.onStartToEnd,
    this.onEndToStart,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<SwipeAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  final ValueNotifier<double> _progress = ValueNotifier(0);
  // The row never actually dismisses, so this only has to stay stable and
  // unique among siblings.
  final Key _dismissKey = UniqueKey();
  bool _reached = false;
  bool _washFromLeft = true;
  Color _washColor = Colors.transparent;

  @override
  void dispose() {
    _wash.dispose();
    _progress.dispose();
    super.dispose();
  }

  DismissDirection get _direction {
    final start = widget.onStartToEnd != null;
    final end = widget.onEndToStart != null;
    if (start && end) return DismissDirection.horizontal;
    if (start) return DismissDirection.startToEnd;
    if (end) return DismissDirection.endToStart;
    return DismissDirection.none;
  }

  void _handleUpdate(DismissUpdateDetails details) {
    if (details.reached && !_reached) HapticFeedback.selectionClick();
    _reached = details.reached;
    _progress.value = details.progress;
  }

  Future<bool> _handleConfirm(DismissDirection direction) async {
    final spec = direction == DismissDirection.startToEnd
        ? widget.onStartToEnd
        : widget.onEndToStart;
    if (spec == null) return false;
    _washFromLeft = direction == DismissDirection.startToEnd;
    _washColor = spec.color;
    _wash.forward(from: 0);
    await spec.onTrigger();
    return false;
  }

  Widget _pad(SwipeActionSpec spec, Alignment alignment) {
    return ValueListenableBuilder<double>(
      valueListenable: _progress,
      builder: (context, progress, _) {
        final t = (progress / kSwipeActionThreshold).clamp(0.0, 1.0);
        final grow = Curves.easeOutBack.transform(t);
        return Container(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: spec.color.withValues(alpha: 0.05 + 0.20 * t),
          ),
          child: Opacity(
            opacity: (0.3 + 0.7 * t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.7 + 0.45 * grow,
              child: Icon(spec.icon, color: spec.color),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kept in the tree even with nothing to swipe, so a row gaining or losing
    // an action doesn't rebuild its subtree.
    return Dismissible(
      key: _dismissKey,
      direction: _direction,
      dismissThresholds: kSwipeActionThresholds,
      onUpdate: _handleUpdate,
      confirmDismiss: _handleConfirm,
      background: widget.onStartToEnd == null
          ? null
          : _pad(widget.onStartToEnd!, Alignment.centerLeft),
      secondaryBackground: widget.onEndToStart == null
          ? null
          : _pad(widget.onEndToStart!, Alignment.centerRight),
      child: AnimatedBuilder(
        animation: _wash,
        builder: (context, child) {
          final v = _wash.value;
          if (v == 0) return child!;
          // A small dip on the way in reads as the row taking the action in.
          final dip = Curves.easeOutCubic.transform((v / 0.35).clamp(0.0, 1.0)) -
              Curves.easeInOutCubic.transform(
                  ((v - 0.35) / 0.65).clamp(0.0, 1.0));
          return Transform.scale(
            scale: 1 - 0.015 * dip,
            child: Stack(children: [
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: widget.borderRadius,
                    child: CustomPaint(
                      painter: _AbsorbWashPainter(
                        t: v,
                        color: _washColor,
                        fromLeft: _washFromLeft,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A band of colour that spreads from the swiped edge and fades as it goes,
/// so the row looks like it drank the action in rather than flashing.
class _AbsorbWashPainter extends CustomPainter {
  final double t;
  final Color color;
  final bool fromLeft;

  _AbsorbWashPainter({
    required this.t,
    required this.color,
    required this.fromLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(fromLeft ? 0 : size.width, size.height / 2);
    final radius = Curves.easeOutCubic.transform(t) * size.width * 1.25;
    if (radius <= 0) return;
    final fade = (1 - Curves.easeInQuad.transform(t)).clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.28 * fade),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: origin, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_AbsorbWashPainter old) =>
      old.t != t || old.color != color || old.fromLeft != fromLeft;
}
