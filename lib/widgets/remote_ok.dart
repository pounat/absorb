import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Tells a press of the remote's OK from a hold. The remote repeats the key
/// while OK is held, so the first repeat is the hold; a release with no
/// repeat was a press. Wraps a focusable control, below the app's own
/// shortcuts, so they never act on OK first.
class RemoteOk extends StatefulWidget {
  final VoidCallback? onPress;
  final VoidCallback? onHold;

  /// OK going down and coming back up, for a press animation.
  final VoidCallback? onDown;
  final VoidCallback? onUp;
  final Widget child;

  const RemoteOk({super.key, this.onPress, this.onHold, this.onDown, this.onUp, required this.child});

  /// What a hold does on a control with no hold of its own: on the TV,
  /// open the player for the book playing, from anywhere. Answers whether
  /// it did; with nothing to open, the hold stays a plain press.
  static bool Function()? globalHold;

  static bool isOk(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter;

  @override
  State<RemoteOk> createState() => _RemoteOkState();
}

class _RemoteOkState extends State<RemoteOk> {
  bool _down = false;
  bool _held = false;

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!RemoteOk.isOk(event.logicalKey)) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      _down = true;
      _held = false;
      widget.onDown?.call();
    } else if (event is KeyRepeatEvent) {
      if (_down && !_held) {
        final own = widget.onHold;
        if (own != null) {
          _held = true;
          own();
        } else if (RemoteOk.globalHold?.call() ?? false) {
          _held = true;
        }
      }
    } else if (event is KeyUpEvent) {
      widget.onUp?.call();
      if (_down && !_held) widget.onPress?.call();
      _down = false;
      _held = false;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) =>
      Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: _onKey, child: widget.child);
}
