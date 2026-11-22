import 'package:flutter/material.dart';

import '../widgets/remote_ok.dart';
import 'tv_focus_ring.dart';

/// Anything the remote can land on: lifts and rings itself while focused,
/// and OK runs [onSelect].
class TvFocusable extends StatefulWidget {
  final Widget? child;

  /// Draws the focused look itself instead of the ring.
  final Widget Function(BuildContext context, bool focused)? builder;
  final VoidCallback? onSelect;

  /// Holding OK, when the control has something to do on a hold.
  final VoidCallback? onHold;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final double radius;
  final double focusScale;

  const TvFocusable({
    super.key,
    this.child,
    this.builder,
    this.onSelect,
    this.onHold,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.radius = 14,
    this.focusScale = 1.06,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hold = widget.onHold;
    final detector = FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (v) {
        setState(() => _focused = v);
        widget.onFocusChange?.call(v);
      },
      // OK is read by RemoteOk around this: a press acts on release, so a
      // hold can open the player instead.
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedScale(
          scale: _focused ? widget.focusScale : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.builder != null
              ? widget.builder!(context, _focused)
              : DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: _focused ? Border.all(color: cs.onSurface, width: 3) : null,
                  ),
                  child: widget.child,
                ),
        ),
      ),
    );
    return RemoteOk(onPress: widget.onSelect, onHold: hold, child: TvDrawsOwnFocus(child: detector));
  }
}

/// Wraps a scrolling grid or list so moving through it glides the row with
/// focus toward the middle, the way TV apps scroll, instead of jumping.
class TvScrollFocusGroup extends StatelessWidget {
  final Widget child;

  const TvScrollFocusGroup({super.key, required this.child});

  static void _requestFocus(
    FocusNode node, {
    ScrollPositionAlignmentPolicy? alignmentPolicy,
    double? alignment,
    Duration? duration,
    Curve? curve,
  }) {
    node.requestFocus();
    final context = node.context;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.4,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(requestFocusCallback: _requestFocus),
        child: child,
      );
}

/// A pill button for the TV. Focus fills it solid, the way TV apps show
/// where the remote is; [selected] (the open tab) is a softer tint.
class TvPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onSelect;
  final VoidCallback? onHold;
  final ValueChanged<bool>? onFocusChange;
  final bool selected;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Flips the icon side to side, so the back-skip arrow can point forward.
  final bool mirrorIcon;

  /// The player's look: tinted with the book's color, with a soft edge.
  final bool tinted;

  const TvPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onSelect,
    this.onHold,
    this.onFocusChange,
    this.selected = false,
    this.autofocus = false,
    this.focusNode,
    this.mirrorIcon = false,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return TvFocusable(
      onSelect: onSelect,
      onHold: onHold,
      onFocusChange: onFocusChange,
      autofocus: autofocus,
      focusNode: focusNode,
      focusScale: 1.0,
      builder: (context, focused) {
        final bg = focused
            ? cs.onSurface
            : selected
                ? cs.primaryContainer
                : tinted
                    ? cs.primary.withValues(alpha: 0.12)
                    : cs.surfaceContainerHigh;
        final fg = focused
            ? cs.surface
            : selected
                ? cs.onPrimaryContainer
                : cs.onSurface;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(horizontal: icon != null && label.isEmpty ? 14 : 22, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: tinted && !focused ? Border.all(color: cs.primary.withValues(alpha: 0.3)) : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null)
              Transform.flip(flipX: mirrorIcon, child: Icon(icon, size: 22, color: fg)),
            if (icon != null && label.isNotEmpty) const SizedBox(width: 10),
            if (label.isNotEmpty)
              Text(
                label,
                style: tt.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: selected || focused ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
          ]),
        );
      },
    );
  }
}
