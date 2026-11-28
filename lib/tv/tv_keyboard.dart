import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tv_focus_ring.dart';

/// How the keyboard was left.
enum TvKeyboardResult {
  /// The action key: the text is finished.
  done,

  /// Back: stop typing, keep what's there.
  closed,

  /// The globe key: use the TV's own keyboard instead, for another language
  /// or voice typing.
  system,
}

/// Absorb's own on-screen keyboard for a TV, moved around with the remote's
/// arrows. A TV's built-in keyboard is supposed to take the arrows itself
/// once it is open, and on some TVs it doesn't: they came through to the
/// page instead, so Down closed the keyboard and nothing could be typed.
/// This one is part of the page, so it works the same on every TV.
///
/// Types straight into [controller]; [onChanged] hears each change.
Future<TvKeyboardResult> showTvKeyboard(
  BuildContext context, {
  required TextEditingController controller,
  bool obscure = false,
  bool multiline = false,
  bool search = false,
  String? hint,
  ValueChanged<String>? onChanged,
}) async {
  final result = await showGeneralDialog<TvKeyboardResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (_, __, ___) => _TvKeyboard(
      controller: controller,
      obscure: obscure,
      multiline: multiline,
      search: search,
      hint: hint,
      onChanged: onChanged,
    ),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
        child: child,
      ),
    ),
  );
  return result ?? TvKeyboardResult.closed;
}

enum _Shift { off, once, locked }

class _TvKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final bool obscure;
  final bool multiline;
  final bool search;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const _TvKeyboard({
    required this.controller,
    required this.obscure,
    required this.multiline,
    required this.search,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_TvKeyboard> createState() => _TvKeyboardState();
}

class _TvKeyboardState extends State<_TvKeyboard> {
  _Shift _shift = _Shift.off;
  bool _symbols = false;

  static const _letters = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', '@'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', '.', '-', '_'],
  ];
  static const _marks = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['!', '@', '#', r'$', '%', '^', '&', '*', '(', ')'],
    ['+', '=', '/', r'\', ':', ';', "'", '"', '?', ','],
    ['~', '`', '|', '<', '>', '[', ']', '{', '}', '.'],
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_redraw);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_redraw);
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // One per key, so the ends of a row can hand the remote to each other.
  final Map<String, FocusNode> _nodes = {};
  FocusNode _node(String id) => _nodes.putIfAbsent(id, FocusNode.new);

  /// Lays [keys] out as a row where Left on the first key lands on the last
  /// and Right on the last lands on the first.
  Widget _row(String id, List<_Key Function(FocusNode node, FocusNode? left, FocusNode? right)> keys) {
    final nodes = [for (var i = 0; i < keys.length; i++) _node('$id-$i')];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        for (var i = 0; i < keys.length; i++)
          keys[i](nodes[i], i == 0 ? nodes.last : null, i == keys.length - 1 ? nodes.first : null),
      ]),
    );
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  void _set(String text) {
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call(text);
  }

  void _type(String s) {
    final upper = _shift != _Shift.off && !_symbols;
    _set(widget.controller.text + (upper ? s.toUpperCase() : s));
    if (_shift == _Shift.once) setState(() => _shift = _Shift.off);
  }

  void _erase() {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    _set(text.characters.skipLast(1).toString());
  }

  void _leave(TvKeyboardResult how) => Navigator.of(context).pop(how);

  /// A keyboard plugged into the TV, or a phone acting as its remote, types
  /// straight in.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _erase();
      return KeyEventResult.handled;
    }
    final ch = event.character;
    if (ch != null && ch.length == 1 && ch.codeUnitAt(0) >= 32 && ch.codeUnitAt(0) != 127) {
      _set(widget.controller.text + ch);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final text = widget.controller.text;
    final shown = widget.obscure ? '•' * text.characters.length : text;
    final rows = _symbols ? _marks : _letters;
    final upper = _shift != _Shift.off && !_symbols;

    return TvDrawsOwnFocus(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: cs.surfaceContainer,
            elevation: 12,
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              // Small enough that a search's results still show above it.
              width: 620,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Focus(
                  onKeyEvent: _onKey,
                  skipTraversal: true,
                  canRequestFocus: false,
                  child: FocusTraversalGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            shown.isEmpty ? (widget.hint ?? ' ') : '$shown▏',
                            maxLines: widget.multiline ? 3 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium?.copyWith(color: shown.isEmpty ? cs.onSurfaceVariant : cs.onSurface),
                          ),
                        ),
                        for (var r = 0; r < rows.length; r++)
                          // Each layer's keys are their own, so a key keeps
                          // the remote when the layer changes.
                          _row('${_symbols ? 's' : 'l'}$r', [
                            for (var c = 0; c < rows[r].length; c++)
                              (node, left, right) => _Key(
                                    key: ValueKey('${_symbols ? 's' : 'l'}$r-$c'),
                                    focusNode: node,
                                    wrapLeft: left,
                                    wrapRight: right,
                                    autofocus: r == 1 && c == 0,
                                    label: upper ? rows[r][c].toUpperCase() : rows[r][c],
                                    onTap: () => _type(rows[r][c]),
                                  ),
                          ]),
                        _row(widget.multiline ? 'bm' : 'b', [
                          (node, left, right) => _Key(
                                focusNode: node,
                                wrapLeft: left,
                                wrapRight: right,
                                flex: 3,
                                icon: _shift == _Shift.locked
                                    ? Icons.keyboard_capslock_rounded
                                    : Icons.arrow_upward_rounded,
                                lit: _shift != _Shift.off,
                                onTap: () => setState(() {
                                  _shift = _Shift.values[(_shift.index + 1) % _Shift.values.length];
                                }),
                              ),
                          (node, left, right) => _Key(
                                focusNode: node,
                                flex: 3,
                                label: _symbols ? 'abc' : '!#1',
                                onTap: () => setState(() => _symbols = !_symbols),
                              ),
                          (node, left, right) => _Key(
                                focusNode: node,
                                flex: 2,
                                icon: Icons.language_rounded,
                                onTap: () => _leave(TvKeyboardResult.system),
                              ),
                          (node, left, right) =>
                              _Key(focusNode: node, flex: 8, icon: Icons.space_bar_rounded, onTap: () => _type(' ')),
                          if (widget.multiline)
                            (node, left, right) => _Key(
                                  focusNode: node,
                                  flex: 2,
                                  icon: Icons.keyboard_return_rounded,
                                  onTap: () => _type('\n'),
                                ),
                          (node, left, right) => _Key(
                                focusNode: node,
                                flex: 3,
                                icon: Icons.backspace_outlined,
                                repeats: true,
                                onTap: _erase,
                              ),
                          (node, left, right) => _Key(
                                focusNode: node,
                                wrapLeft: left,
                                wrapRight: right,
                                flex: 4,
                                icon: widget.search ? Icons.search_rounded : Icons.check_rounded,
                                strong: true,
                                onTap: () => _leave(TvKeyboardResult.done),
                              ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final int flex;
  final bool autofocus;

  /// Drawn as switched on (shift held).
  final bool lit;

  /// The action key, drawn to stand out.
  final bool strong;

  /// Holding OK keeps going (backspace).
  final bool repeats;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  /// Where Left goes from the first key of a row, and Right from the last.
  final FocusNode? wrapLeft;
  final FocusNode? wrapRight;

  const _Key({
    super.key,
    this.label,
    this.icon,
    this.flex = 2,
    this.autofocus = false,
    this.lit = false,
    this.strong = false,
    this.repeats = false,
    required this.onTap,
    this.focusNode,
    this.wrapLeft,
    this.wrapRight,
  });

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    final k = event.logicalKey;
    final wrap = k == LogicalKeyboardKey.arrowLeft
        ? widget.wrapLeft
        : k == LogicalKeyboardKey.arrowRight
            ? widget.wrapRight
            : null;
    if (wrap != null) {
      if (event is! KeyUpEvent) wrap.requestFocus();
      return KeyEventResult.handled;
    }
    final ok = k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.gameButtonA;
    if (!ok) return KeyEventResult.ignored;
    if (event is KeyDownEvent || (event is KeyRepeatEvent && widget.repeats)) widget.onTap();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color fill;
    final Color ink;
    if (_focused) {
      fill = cs.onSurface;
      ink = cs.surface;
    } else if (widget.strong || widget.lit) {
      fill = cs.primaryContainer;
      ink = cs.onPrimaryContainer;
    } else {
      fill = cs.surfaceContainerHighest;
      ink = cs.onSurface;
    }
    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Focus(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onFocusChange: (v) => setState(() => _focused = v),
          onKeyEvent: _onKey,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(9)),
              child: widget.icon != null
                  ? Icon(widget.icon, color: ink, size: 22)
                  : Text(
                      widget.label ?? '',
                      style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
