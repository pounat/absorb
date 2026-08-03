import 'dart:ui' as ui;
import 'package:flutter/material.dart';

OverlayEntry? _currentToast;

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
  _currentToast?.remove();
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
        entry.remove();
        if (_currentToast == entry) _currentToast = null;
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: cs.primary.withValues(alpha: 0.25)),
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
      ),
    );
  }
}
