import 'package:flutter/material.dart';
import '../utils/desktop_workspace.dart';
import 'adaptive_modal.dart';

const int maxSheetDepth = 3;
final List<Route<dynamic>> _activeSheetRoutes = [];

/// Shows a modal bottom sheet that supports stacking.
///
/// Drag to minimum size closes the current sheet only (revealing any sheet below).
/// Back button / barrier tap also closes only the current sheet.
/// Stack is capped at [maxSheetDepth] - opening beyond that evicts the oldest sheet.
/// On the desktop workspace the sheet presents as a centered dialog instead;
/// the stack cap applies across both presentations.
Future<T?> showStackableSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  double initialChildSize = 0.7,
  double minChildSize = 0.05,
  double maxChildSize = 0.9,
  Color? backgroundColor,
  bool useSafeArea = false,
  bool showHandle = false,
  double desktopWidth = 720,
}) {
  FocusManager.instance.primaryFocus?.unfocus();

  // Enforce stack cap: evict the oldest sheet before opening a new one
  if (_activeSheetRoutes.length >= maxSheetDepth) {
    final oldest = _activeSheetRoutes.first;
    try {
      Navigator.of(context, rootNavigator: true).removeRoute(oldest);
    } catch (_) {
      // Route may already be disposed (e.g. rapid navigation)
      _activeSheetRoutes.remove(oldest);
    }
  }

  if (isDesktopWorkspace(context)) {
    return showDesktopSheetDialog<T>(
      context: context,
      builder: builder,
      maxWidth: desktopWidth,
      backgroundColor: backgroundColor,
      onRouteCaptured: _activeSheetRoutes.add,
      onRouteDisposed: _activeSheetRoutes.remove,
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor ?? (showHandle ? null : Colors.transparent),
    builder: (_) => _StackableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      showHandle: showHandle,
      builder: builder,
    ),
  );
}

class _StackableSheet extends StatefulWidget {
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool showHandle;
  final Widget Function(BuildContext, ScrollController) builder;

  const _StackableSheet({
    required this.initialChildSize,
    required this.minChildSize,
    required this.maxChildSize,
    required this.showHandle,
    required this.builder,
  });

  @override
  State<_StackableSheet> createState() => _StackableSheetState();
}

class _StackableSheetState extends State<_StackableSheet> {
  final _controller = DraggableScrollableController();
  bool _dismissed = false;
  Route<dynamic>? _ownRoute;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSizeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ownRoute = ModalRoute.of(context);
      if (_ownRoute != null) {
        _activeSheetRoutes.add(_ownRoute!);
      }
    });
  }

  @override
  void dispose() {
    if (_ownRoute != null) _activeSheetRoutes.remove(_ownRoute!);
    _controller.removeListener(_onSizeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSizeChanged() {
    if (!_dismissed && _controller.size <= widget.minChildSize) {
      _dismissed = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: widget.initialChildSize,
      minChildSize: widget.minChildSize,
      maxChildSize: widget.maxChildSize,
      snap: true,
      expand: false,
      builder: (ctx, scrollController) {
        final content = widget.builder(ctx, scrollController);
        if (widget.showHandle) {
          final cs = Theme.of(context).colorScheme;
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor ??
                  cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: content),
              ],
            ),
          );
        }
        return content;
      },
    );
  }
}
