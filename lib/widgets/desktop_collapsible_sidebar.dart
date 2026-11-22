import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef DesktopSidebarBuilder =
    Widget Function(BuildContext context, bool extended);

class DesktopSidebarBranding extends StatelessWidget {
  const DesktopSidebarBranding({
    super.key,
    required this.extended,
    required this.leading,
    required this.title,
    this.titleStyle,
  });

  static const leadingKey = ValueKey<String>(
    'desktop-sidebar-branding-leading',
  );

  final bool extended;
  final Widget leading;
  final String title;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          key: leadingKey,
          width: 48,
          height: 48,
          child: Center(child: leading),
        ),
        if (extended) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
        ],
      ],
    );
  }
}

class DesktopSidebarLayout extends StatelessWidget {
  const DesktopSidebarLayout({
    super.key,
    required this.pinned,
    required this.canPin,
    required this.onPinnedChanged,
    required this.sidebarBuilder,
    required this.child,
  });

  static const reservedSpaceKey = ValueKey<String>(
    'desktop-sidebar-reserved-space',
  );

  final bool pinned;
  final bool canPin;
  final ValueChanged<bool> onPinnedChanged;
  final DesktopSidebarBuilder sidebarBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reservedWidth = pinned
        ? DesktopCollapsibleSidebar.expandedWidth
        : DesktopCollapsibleSidebar.collapsedWidth;

    return Stack(
      children: [
        Row(
          children: [
            AnimatedContainer(
              key: reservedSpaceKey,
              width: reservedWidth,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
            ),
            Expanded(child: child),
          ],
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: DesktopCollapsibleSidebar(
            pinned: pinned,
            canPin: canPin,
            onPinnedChanged: onPinnedChanged,
            builder: sidebarBuilder,
          ),
        ),
      ],
    );
  }
}

class DesktopCollapsibleSidebar extends StatefulWidget {
  const DesktopCollapsibleSidebar({
    super.key,
    required this.pinned,
    required this.onPinnedChanged,
    required this.builder,
    this.canPin = true,
    this.pinTooltip = 'Keep sidebar expanded',
    this.unpinTooltip = 'Unpin sidebar',
  });

  static const panelKey = ValueKey<String>('desktop-collapsible-sidebar');
  static const pinButtonKey = ValueKey<String>('desktop-sidebar-pin-button');
  static const double collapsedWidth = 72;
  static const double expandedWidth = 248;

  final bool pinned;
  final ValueChanged<bool> onPinnedChanged;
  final DesktopSidebarBuilder builder;
  final bool canPin;
  final String pinTooltip;
  final String unpinTooltip;

  @override
  State<DesktopCollapsibleSidebar> createState() =>
      _DesktopCollapsibleSidebarState();
}

class _DesktopCollapsibleSidebarState extends State<DesktopCollapsibleSidebar> {
  bool _hovering = false;
  bool _focusWithin = false;
  Timer? _collapseTimer;

  void _showForPointer() {
    _collapseTimer?.cancel();
    if (!_hovering) setState(() => _hovering = true);
  }

  void _schedulePointerCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted && _hovering) setState(() => _hovering = false);
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final extended = widget.pinned || _hovering || _focusWithin;
    final width = extended
        ? DesktopCollapsibleSidebar.expandedWidth
        : DesktopCollapsibleSidebar.collapsedWidth;

    return Focus(
      canRequestFocus: false,
      onFocusChange: (focused) {
        if (focused != _focusWithin) setState(() => _focusWithin = focused);
      },
      onKeyEvent: (_, event) {
        if (!widget.pinned &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (_focusWithin) setState(() => _focusWithin = false);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => _showForPointer(),
        onExit: (_) => _schedulePointerCollapse(),
        child: AnimatedContainer(
          key: DesktopCollapsibleSidebar.panelKey,
          width: width,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              right: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            boxShadow: extended && !widget.pinned
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(6, 0),
                    ),
                  ]
                : null,
          ),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            child: SizedBox(
              width: width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.builder(context, extended),
                  if (extended && widget.canPin)
                    Positioned(
                      top: 14,
                      right: 8,
                      child: Tooltip(
                        message: widget.pinned
                            ? widget.unpinTooltip
                            : widget.pinTooltip,
                        child: IconButton(
                          key: DesktopCollapsibleSidebar.pinButtonKey,
                          onPressed: () =>
                              widget.onPinnedChanged(!widget.pinned),
                          icon: Icon(
                            widget.pinned
                                ? Icons.keyboard_double_arrow_left_rounded
                                : Icons.push_pin_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
