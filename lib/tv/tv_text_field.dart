import 'package:flutter/material.dart';

import '../widgets/remote_text_field.dart';
import 'tv_focus_ring.dart';

/// The TV's pill-shaped text box, as on the sign-in screen. The remote
/// handling is [RemoteTextField]'s.
class TvTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final shape = BorderRadius.circular(999);
    return TvDrawsOwnFocus(
      child: RemoteTextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autocorrect: false,
        enableSuggestions: !obscure,
        style: tt.titleLarge,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          filled: true,
          border: OutlineInputBorder(borderRadius: shape, borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: shape, borderSide: BorderSide(color: cs.onSurface, width: 3)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
