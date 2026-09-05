import 'dart:ui' as ui;
import 'package:flutter/material.dart';

OverlayEntry? _currentToast;

// remove() is not idempotent, and a toast has two removers: its own exit
// animation and any newer toast taking its place. When both landed in the
// same frame (tap to pause, then hold to stop) the second call threw. Every
// removal goes through here so the second one is a no-op.
final Expando<bool> _removedToasts = Expando<bool>();

void _removeToast(OverlayEntry entry) {
  if (_removedToasts[entry] == true) return;
  _removedToasts[entry] = true;
  entry.remove();
}

/// Show a styled toast that renders above modal sheets and overlays.
///
/// Pass [icon] for a leading icon (e.g. Icons.check_circle_rounded).
void showOverlayToast(BuildContext context, String message, {IconData? icon}) {
  _insertOverlayToast(Overlay.maybeOf(context), message, icon: icon);
}

/// Show the same toast from provider/service code that owns a navigator but
/// does not have a context beneath its overlay.
void showNavigatorOverlayToast(
  NavigatorState? navigator,
  String message, {
  IconData? icon,
}) {
  _insertOverlayToast(navigator?.overlay, message, icon: icon);
}

void _insertOverlayToast(
  OverlayState? overlay,
  String message, {
  IconData? icon,
}) {
  final previous = _currentToast;
  if (previous != null) _removeToast(previous);
  _currentToast = null;

  // No overlay (startup, account switch, background-triggered callers): drop
  // the toast instead of throwing into whatever async flow asked for it.
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AnimatedToast(
      message: message,
      icon: icon,
      onDone: () {
        _removeToast(entry);
        if (_currentToast == entry) _currentToast = null;
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

/// A toast that stays up and can change its text, for something the user is
/// actively adjusting (auto-scroll speed, say). Call [update] as the value
/// changes and [dismiss] when done - it does not time out on its own.
class LiveOverlayToast {
  final ValueNotifier<({String message, IconData? icon})> _value;
  OverlayEntry? _entry;

  LiveOverlayToast._(this._value, this._entry);

  static LiveOverlayToast? show(BuildContext context, String message, {IconData? icon}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return null;
    final previous = _currentToast;
    if (previous != null) _removeToast(previous);
    _currentToast = null;
    final value = ValueNotifier<({String message, IconData? icon})>(
        (message: message, icon: icon));
    final entry = OverlayEntry(builder: (_) => _LiveToast(value: value));
    overlay.insert(entry);
    return LiveOverlayToast._(value, entry);
  }

  void update(String message, {IconData? icon}) {
    if (_entry == null) return;
    _value.value = (message: message, icon: icon);
  }

  void dismiss() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    _removeToast(entry);
    _value.dispose();
  }
}

class _LiveToast extends StatelessWidget {
  final ValueNotifier<({String message, IconData? icon})> value;
  const _LiveToast({required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      left: 32,
      right: 32,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
              ),
              child: ValueListenableBuilder<({String message, IconData? icon})>(
                valueListenable: value,
                builder: (context, v, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (v.icon != null) ...[
                      Icon(v.icon, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        v.message,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedToast extends StatefulWidget {
  final String message;
  final IconData? icon;
  final VoidCallback onDone;

  const _AnimatedToast({required this.message, this.icon, required this.onDone});

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.reverse().then((_) => widget.onDone());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      left: 32,
      right: 32,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
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
