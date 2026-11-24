import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_platform.dart';

/// Lets a TV remote get past a slider. A focused Slider takes all four
/// arrows as "more" and "less", so once the remote lands on one it can't
/// leave. On a TV this keeps left and right for the slider and gives up and
/// down back for moving on to the next control. On a phone it does nothing.
class RemoteSlider extends StatefulWidget {
  /// Builds the Slider; pass [node] as its focusNode.
  final Widget Function(FocusNode? node) builder;

  const RemoteSlider({super.key, required this.builder});

  @override
  State<RemoteSlider> createState() => _RemoteSliderState();
}

class _RemoteSliderState extends State<RemoteSlider> {
  late final FocusNode? _node = AppPlatform.isTv ? FocusNode(debugLabel: 'remote slider', onKeyEvent: _onKey) : null;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final k = event.logicalKey;
    final move = k == LogicalKeyboardKey.arrowUp
        ? TraversalDirection.up
        : k == LogicalKeyboardKey.arrowDown
            ? TraversalDirection.down
            : null;
    if (move == null) return KeyEventResult.ignored;
    if (event is! KeyUpEvent) node.focusInDirection(move);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _node?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_node);
}

/// A slider turned on its side ([child], a Slider in a RotatedBox), for a TV
/// remote. The remote can't land on the turned slider itself, since a
/// control that has been rotated measures as having no size and the arrows
/// skip it, so this takes the remote in its place.
///
/// Landing on it changes nothing, so the arrows can still pass over it in
/// every direction. OK picks it up: then up and down move the value, and OK,
/// Back or moving sideways puts it down again. On a phone it is just [child].
class RemoteVerticalSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final Widget child;

  const RemoteVerticalSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.child,
  });

  @override
  State<RemoteVerticalSlider> createState() => _RemoteVerticalSliderState();
}

class _RemoteVerticalSliderState extends State<RemoteVerticalSlider> {
  bool _held = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final change = widget.onChanged;
    if (change == null) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final ok = k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.gameButtonA;
    if (ok) {
      if (event is KeyDownEvent) setState(() => _held = !_held);
      return KeyEventResult.handled;
    }
    if (!_held) return KeyEventResult.ignored;
    final up = k == LogicalKeyboardKey.arrowUp;
    if (up || k == LogicalKeyboardKey.arrowDown) {
      if (event is! KeyUpEvent) {
        final step = (widget.max - widget.min) / 20;
        change((widget.value + (up ? step : -step)).clamp(widget.min, widget.max));
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.goBack || k == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) setState(() => _held = false);
      return KeyEventResult.handled;
    }
    // Sideways: put it down and let the arrow move on.
    if (event is KeyDownEvent) setState(() => _held = false);
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isTv) return widget.child;
    return Focus(
      canRequestFocus: widget.onChanged != null,
      onKeyEvent: _onKey,
      onFocusChange: (has) {
        if (!has && _held) setState(() => _held = false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _held ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExcludeFocus(child: widget.child),
      ),
    );
  }
}
