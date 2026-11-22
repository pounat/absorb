import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tv_focus_ring.dart';

/// A text box made for the remote. Landing on it does nothing; OK opens the
/// TV's keyboard to type. Up and down always move on to the next control,
/// side to side moves the cursor only while typing, and the keyboard's
/// action key finishes and moves on.
class TvTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const TvTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<TvTextField> createState() => _TvTextFieldState();
}

class _TvTextFieldState extends State<TvTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode(debugLabel: 'tv text');
  bool _editing = false;

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final shape = BorderRadius.circular(999);
    return Focus(
      onKeyEvent: _onKey,
      skipTraversal: true,
      onFocusChange: (has) {
        if (!has && _editing) setState(() => _editing = false);
      },
      child: TvDrawsOwnFocus(
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          autofocus: widget.autofocus,
          readOnly: !_editing,
          showCursor: _editing,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autocorrect: false,
          enableSuggestions: !widget.obscure,
          style: tt.titleLarge,
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon),
            hintText: widget.hint,
            filled: true,
            border: OutlineInputBorder(borderRadius: shape, borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: shape, borderSide: BorderSide(color: cs.onSurface, width: 3)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
          onChanged: widget.onChanged,
          // The keyboard's action key moves on once, below; left to itself
          // the box would also step to the next field.
          onEditingComplete: () {},
          onSubmitted: (v) {
            setState(() => _editing = false);
            widget.onSubmitted?.call(v);
            _focus.focusInDirection(TraversalDirection.down);
          },
        ),
      ),
    );
  }
}
