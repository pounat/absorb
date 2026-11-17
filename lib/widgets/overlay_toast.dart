import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/native_tab_bar.dart';

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

final Map<String, Uint8List> _toastIconCache = {};

/// The glass toast is drawn by iOS, which has no Material icons, so the icon
/// goes over as a small picture.
Future<Uint8List?> _toastIconPng(IconData icon, Color color) async {
  final key = '${icon.fontFamily}|${icon.codePoint}|${color.toARGB32()}';
  final cached = _toastIconCache[key];
  if (cached != null) return cached;
  const size = 18.0;
  const scale = 3.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        height: 1,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset((size - painter.width) / 2, (size - painter.height) / 2),
  );
  painter.dispose();
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (size * scale).round(),
    (size * scale).round(),
  );
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) return null;
  final bytes = data.buffer.asUint8List();
  _toastIconCache[key] = bytes;
  return bytes;
}

/// Shows the toast as iOS glass. False means it could not be shown and the
/// Flutter toast should be used instead.
Future<bool> _showGlassToast(
  OverlayState overlay,
  int id,
  String message, {
  IconData? icon,
  VoidCallback? onTap,
  double? seconds,
}) async {
  final cs = Theme.of(overlay.context).colorScheme;
  final iconPng = icon == null ? null : await _toastIconPng(icon, cs.primary);
  return NativeTabBar.showToast(
    id: id,
    message: message,
    iconPng: iconPng,
    onTap: onTap,
    seconds: seconds,
    dark: cs.brightness == Brightness.dark,
  );
}

/// Show a styled toast that renders above modal sheets and overlays.
///
/// Pass [icon] for a leading icon (e.g. Icons.check_circle_rounded). With
/// [onTap] the toast is an offer: it stays up longer and tapping it runs the
/// action.
void showOverlayToast(BuildContext context, String message,
    {IconData? icon, VoidCallback? onTap}) {
  _insertOverlayToast(Overlay.maybeOf(context), message,
      icon: icon, onTap: onTap);
}

/// Show the same toast from provider/service code that owns a navigator but
/// does not have a context beneath its overlay.
void showNavigatorOverlayToast(
  NavigatorState? navigator,
  String message, {
  IconData? icon,
  VoidCallback? onTap,
}) {
  _insertOverlayToast(navigator?.overlay, message, icon: icon, onTap: onTap);
}

void _insertOverlayToast(
  OverlayState? overlay,
  String message, {
  IconData? icon,
  VoidCallback? onTap,
}) {
  final previous = _currentToast;
  if (previous != null) _removeToast(previous);
  _currentToast = null;

  // No overlay (startup, account switch, background-triggered callers): drop
  // the toast instead of throwing into whatever async flow asked for it.
  if (overlay == null) return;
  if (NativeTabBar.active.value) {
    unawaited(() async {
      final shown = await _showGlassToast(
        overlay,
        NativeTabBar.newToastId(),
        message,
        icon: icon,
        onTap: onTap,
        seconds: onTap != null ? 6 : 2,
      );
      if (!shown && overlay.mounted) {
        _insertFlutterToast(overlay, message, icon: icon, onTap: onTap);
      }
    }());
    return;
  }
  _insertFlutterToast(overlay, message, icon: icon, onTap: onTap);
}

void _insertFlutterToast(
  OverlayState overlay,
  String message, {
  IconData? icon,
  VoidCallback? onTap,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AnimatedToast(
      message: message,
      icon: icon,
      onTap: onTap,
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

  // Set when the toast is drawn by iOS as glass instead of in the overlay.
  final OverlayState? _glassOverlay;
  final int _glassId;
  bool _glassOpen = false;

  LiveOverlayToast._(this._value, this._entry)
      : _glassOverlay = null,
        _glassId = -1;

  LiveOverlayToast._glass(this._value, OverlayState overlay)
      : _glassOverlay = overlay,
        _glassId = NativeTabBar.newToastId(),
        _glassOpen = true;

  void _sendGlass() {
    final overlay = _glassOverlay;
    if (overlay == null || !_glassOpen || !overlay.mounted) return;
    final v = _value.value;
    unawaited(_showGlassToast(overlay, _glassId, v.message, icon: v.icon));
  }

  static LiveOverlayToast? show(BuildContext context, String message, {IconData? icon}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return null;
    final previous = _currentToast;
    if (previous != null) _removeToast(previous);
    _currentToast = null;
    final value = ValueNotifier<({String message, IconData? icon})>(
        (message: message, icon: icon));
    if (NativeTabBar.active.value) {
      return LiveOverlayToast._glass(value, overlay).._sendGlass();
    }
    final entry = OverlayEntry(builder: (_) => _LiveToast(value: value));
    overlay.insert(entry);
    return LiveOverlayToast._(value, entry);
  }

  void update(String message, {IconData? icon}) {
    if (_glassOpen) {
      _value.value = (message: message, icon: icon);
      _sendGlass();
      return;
    }
    if (_entry == null) return;
    _value.value = (message: message, icon: icon);
  }

  void dismiss() {
    if (_glassOpen) {
      _glassOpen = false;
      unawaited(NativeTabBar.dismissToast(_glassId));
      _value.dispose();
      return;
    }
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
  final VoidCallback? onTap;
  final VoidCallback onDone;

  const _AnimatedToast(
      {required this.message, this.icon, this.onTap, required this.onDone});

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

    Future.delayed(Duration(seconds: widget.onTap != null ? 6 : 2), () {
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap == null
                    ? null
                    : () {
                        widget.onDone();
                        widget.onTap!();
                      },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: cs.primary.withValues(alpha: 0.25)),
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
      ),
    );
  }
}
