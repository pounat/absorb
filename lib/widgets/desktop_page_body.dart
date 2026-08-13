import 'package:flutter/material.dart';
import '../utils/desktop_workspace.dart';
import 'desktop_wheel_scroll_region.dart';

/// Centers a pushed page's content in a readable column on the desktop
/// workspace; returns the child untouched everywhere else.
class DesktopPageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DesktopPageBody({super.key, required this.child, this.maxWidth = 840});

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWorkspace(context)) return child;
    return DesktopWheelScrollRegion(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
