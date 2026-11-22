import 'package:flutter/material.dart';

import '../utils/app_platform.dart';
import '../tv/tv_focus_ring.dart';
import 'remote_ok.dart';

/// A plain tap target that a TV remote can also reach: on a phone it is
/// just a GestureDetector, on a TV it takes focus, rings itself and OK taps.
class RemoteTap extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior? behavior;
  final double radius;
  final Widget child;

  const RemoteTap({
    super.key,
    this.onTap,
    this.onLongPress,
    this.behavior,
    this.radius = 20,
    required this.child,
  });

  @override
  State<RemoteTap> createState() => _RemoteTapState();
}

class _RemoteTapState extends State<RemoteTap> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tap = GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: widget.child,
    );
    if (!AppPlatform.isTv) return tap;
    final onTap = widget.onTap;
    return RemoteOk(
      onPress: onTap,
      onHold: widget.onLongPress,
      child: TvDrawsOwnFocus(
      child: FocusableActionDetector(
      enabled: onTap != null,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: _focused ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5) : null,
        ),
        child: tap,
      ),
      ),
      ),
    );
  }
}
