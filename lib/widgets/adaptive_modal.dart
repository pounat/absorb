import 'package:flutter/material.dart';
import '../utils/desktop_workspace.dart';
import 'desktop_wheel_scroll_region.dart';

enum DialogWidthClass {
  action(480),
  content(720);

  const DialogWidthClass(this.width);
  final double width;
}

/// Marks which surface a modal's content is rendered in so shared content can
/// adapt (hide drag handles, square off sheet corners) without new params.
class ModalSurface extends InheritedWidget {
  const ModalSurface({super.key, required this.desktop, required super.child});

  final bool desktop;

  static bool isDesktopOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ModalSurface>()?.desktop ??
      false;

  @override
  bool updateShouldNotify(ModalSurface oldWidget) =>
      oldWidget.desktop != desktop;
}

/// Keeps sheet-style content draggable on mobile while giving it a finite,
/// conventional dialog height on desktop. The same builder and scroll
/// controller work in both surfaces.
class AdaptiveDraggableScrollableSheet extends StatelessWidget {
  const AdaptiveDraggableScrollableSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 1.0,
    this.expand = true,
    this.desktopHeightFraction = 0.76,
    this.desktopMaxHeight = 720,
  });

  final ScrollableWidgetBuilder builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool expand;
  final double desktopHeightFraction;
  final double desktopMaxHeight;

  @override
  Widget build(BuildContext context) {
    if (ModalSurface.isDesktopOf(context)) {
      final availableHeight =
          MediaQuery.sizeOf(context).height * desktopHeightFraction;
      final height = availableHeight < desktopMaxHeight
          ? availableHeight
          : desktopMaxHeight;
      return SizedBox(
        height: height,
        child: _SheetDialogScrollHost(builder: builder),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: expand,
      builder: builder,
    );
  }
}

/// Scrollable browse/detail surface: draggable bottom sheet on mobile,
/// centered dialog on the desktop workspace. The builder's ScrollController
/// comes from the DraggableScrollableSheet on mobile and a dialog-owned
/// controller on desktop, so existing sheet bodies work unchanged.
Future<T?> showAdaptiveSheetDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  DialogWidthClass widthClass = DialogWidthClass.content,
  double desktopMaxHeightFraction = 0.85,
  bool desktopCloseButton = true,
  double initialChildSize = 0.7,
  double minChildSize = 0.5,
  double maxChildSize = 1.0,
  bool snap = false,
  bool expand = false,
  bool useSafeArea = true,
  Color? backgroundColor,
  bool isDismissible = true,
  bool showDragHandle = false,
}) {
  if (isDesktopWorkspace(context)) {
    return showDesktopSheetDialog<T>(
      context: context,
      builder: builder,
      maxWidth: widthClass.width,
      maxHeightFraction: desktopMaxHeightFraction,
      closeButton: desktopCloseButton,
      backgroundColor: backgroundColor,
      isDismissible: isDismissible,
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    isDismissible: isDismissible,
    showDragHandle: showDragHandle,
    builder: (ctx) => DraggableScrollableSheet(
      expand: expand,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: snap,
      builder: (c, sc) => ModalSurface(desktop: false, child: builder(c, sc)),
    ),
  );
}

/// Intrinsic-height action menu / picker: plain bottom sheet on mobile, small
/// centered dialog on the desktop workspace. Set [desktopScrollWrap] false
/// when the content manages its own scrolling.
Future<T?> showAdaptiveActionMenu<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double desktopWidth = 480,
  double desktopMaxHeightFraction = 0.85,
  bool desktopScrollWrap = true,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isDismissible = true,
  bool showDragHandle = false,
  BoxConstraints? constraints,
}) {
  if (isDesktopWorkspace(context)) {
    return showDesktopModalDialog<T>(
      context: context,
      maxWidth: desktopWidth,
      maxHeightFraction: desktopMaxHeightFraction,
      closeButton: false,
      backgroundColor: backgroundColor,
      isDismissible: isDismissible,
      builder: desktopScrollWrap
          ? (ctx) => SingleChildScrollView(child: Builder(builder: builder))
          : builder,
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    shape: shape,
    isDismissible: isDismissible,
    showDragHandle: showDragHandle,
    constraints: constraints,
    builder: (ctx) => ModalSurface(desktop: false, child: builder(ctx)),
  );
}

/// Desktop dialog surface for sheet-style builders that expect a
/// ScrollController. Used by the adaptive helpers and showStackableSheet.
Future<T?> showDesktopSheetDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  double maxWidth = 720,
  double maxHeightFraction = 0.85,
  bool closeButton = true,
  Color? backgroundColor,
  bool isDismissible = true,
  void Function(Route<dynamic>)? onRouteCaptured,
  void Function(Route<dynamic>)? onRouteDisposed,
}) => showDesktopModalDialog<T>(
  context: context,
  maxWidth: maxWidth,
  maxHeightFraction: maxHeightFraction,
  closeButton: closeButton,
  backgroundColor: backgroundColor,
  isDismissible: isDismissible,
  onRouteCaptured: onRouteCaptured,
  onRouteDisposed: onRouteDisposed,
  builder: (ctx) => _SheetDialogScrollHost(builder: builder),
);

/// Centered dialog with the shared desktop modal chrome (matches the
/// settings surfaces). Always presents on the root navigator so it covers
/// the whole window.
Future<T?> showDesktopModalDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 720,
  double maxHeightFraction = 0.85,
  bool closeButton = true,
  Color? backgroundColor,
  bool isDismissible = true,
  void Function(Route<dynamic>)? onRouteCaptured,
  void Function(Route<dynamic>)? onRouteDisposed,
}) {
  final cs = Theme.of(context).colorScheme;
  // Transparent means "the sheet body paints its own rounded container";
  // inside a clipped dialog that container needs a real backdrop instead.
  final bg = backgroundColor == null || backgroundColor == Colors.transparent
      ? cs.surfaceContainerHigh
      : backgroundColor;
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: isDismissible,
    builder: (dialogContext) => DesktopWheelScrollRegion(
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isDismissible
                ? () => Navigator.of(dialogContext).maybePop()
                : null,
          ),
          Dialog(
            backgroundColor: bg,
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(dialogContext).height * maxHeightFraction,
              ),
              child: SizedBox(
                width: maxWidth,
                child: _DesktopDialogBody(
                  builder: builder,
                  closeButton: closeButton,
                  onRouteCaptured: onRouteCaptured,
                  onRouteDisposed: onRouteDisposed,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SheetDialogScrollHost extends StatefulWidget {
  const _SheetDialogScrollHost({required this.builder});

  final Widget Function(BuildContext, ScrollController) builder;

  @override
  State<_SheetDialogScrollHost> createState() => _SheetDialogScrollHostState();
}

class _SheetDialogScrollHostState extends State<_SheetDialogScrollHost> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

class _DesktopDialogBody extends StatefulWidget {
  const _DesktopDialogBody({
    required this.builder,
    required this.closeButton,
    this.onRouteCaptured,
    this.onRouteDisposed,
  });

  final WidgetBuilder builder;
  final bool closeButton;
  final void Function(Route<dynamic>)? onRouteCaptured;
  final void Function(Route<dynamic>)? onRouteDisposed;

  @override
  State<_DesktopDialogBody> createState() => _DesktopDialogBodyState();
}

class _DesktopDialogBodyState extends State<_DesktopDialogBody> {
  Route<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _route = ModalRoute.of(context);
      if (_route != null) widget.onRouteCaptured?.call(_route!);
    });
  }

  @override
  void dispose() {
    if (_route != null) widget.onRouteDisposed?.call(_route!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = ModalSurface(
      desktop: true,
      child: Builder(builder: widget.builder),
    );
    if (!widget.closeButton) return content;
    return ModalSurface(
      desktop: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            key: const ValueKey('desktop-dialog-chrome'),
            height: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    key: const ValueKey('desktop-dialog-close-button'),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          Flexible(child: Builder(builder: widget.builder)),
        ],
      ),
    );
  }
}
