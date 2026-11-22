import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_platform.dart';

/// A TextField that a TV remote can pass through. On phones it is a plain
/// TextField. On a TV, landing on it does nothing: OK opens the keyboard to
/// type, up and down always move on to the next control, side to side moves
/// the cursor only while typing, and the keyboard's action key finishes and
/// moves on. A plain TextField keeps every arrow once focused and opens the
/// keyboard just for being landed on.
class RemoteTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const RemoteTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<RemoteTextField> createState() => _RemoteTextFieldState();
}

class _RemoteTextFieldState extends State<RemoteTextField> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'remote text'));
  bool _editing = false;

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _type() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowDown) {
      _focus.focusInDirection(k == LogicalKeyboardKey.arrowUp ? TraversalDirection.up : TraversalDirection.down);
      return KeyEventResult.handled;
    }
    if (!_editing) {
      if (event is KeyDownEvent &&
          (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter)) {
        _type();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowRight) return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _field({required bool tv}) => TextField(
        controller: widget.controller,
        focusNode: _focus,
        decoration: widget.decoration,
        style: widget.style,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        enableSuggestions: widget.enableSuggestions,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        readOnly: tv && !_editing,
        showCursor: tv ? _editing : null,
        // No touch on a TV: without this a drag handle hangs under the cursor.
        enableInteractiveSelection: !tv,
        onChanged: widget.onChanged,
        // On a TV the action key moves on once, below; left to itself the box
        // would also step to the next field.
        onEditingComplete: tv ? () {} : null,
        onSubmitted: !tv
            ? widget.onSubmitted
            : (v) {
                setState(() => _editing = false);
                widget.onSubmitted?.call(v);
                _focus.focusInDirection(TraversalDirection.down);
              },
      );

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isTv) return _field(tv: false);
    return Focus(
      onKeyEvent: _onKey,
      skipTraversal: true,
      canRequestFocus: false,
      onFocusChange: (has) {
        if (!has && _editing) setState(() => _editing = false);
      },
      child: _field(tv: true),
    );
  }
}
