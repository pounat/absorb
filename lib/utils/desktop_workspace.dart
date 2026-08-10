import 'package:flutter/widgets.dart';
import 'app_platform.dart';

const double kDesktopWorkspaceBreakpoint = 960;
const double kStandardWorkspaceBreakpoint = 1200;
const double kWideWorkspaceBreakpoint = 1440;

enum WorkspaceLayoutTier { mobile, compact, standard, wide }

WorkspaceLayoutTier workspaceLayoutTierForWidth(double width) {
  if (width < kDesktopWorkspaceBreakpoint) {
    return WorkspaceLayoutTier.mobile;
  }
  if (width < kStandardWorkspaceBreakpoint) {
    return WorkspaceLayoutTier.compact;
  }
  if (width < kWideWorkspaceBreakpoint) {
    return WorkspaceLayoutTier.standard;
  }
  return WorkspaceLayoutTier.wide;
}

bool usesExtendedDesktopSidebar(WorkspaceLayoutTier tier) =>
    tier == WorkspaceLayoutTier.standard || tier == WorkspaceLayoutTier.wide;

double desktopSidebarWidth(WorkspaceLayoutTier tier) =>
    usesExtendedDesktopSidebar(tier) ? 248 : 72;

/// Registration point for the desktop workspace's content-pane navigator.
/// AppShell registers a resolver on mount; anything that pushes full pages
/// resolves through [contentNavigator] so pages land inside the pane on
/// desktop and on the root navigator everywhere else.
abstract final class DesktopWorkspaceNavigator {
  static NavigatorState? Function()? _resolver;

  static void register(NavigatorState? Function() resolver) =>
      _resolver = resolver;

  static void unregister() => _resolver = null;
}

NavigatorState contentNavigator(BuildContext context) =>
    DesktopWorkspaceNavigator._resolver?.call() ??
    Navigator.of(context, rootNavigator: true);

/// Whether the app is showing the desktop web workspace (sidebar shell).
/// Measures the window via the View, not MediaQuery: pages run inside a
/// MediaQuery whose size is overridden to the content pane, which would
/// disagree with the shell's own breakpoint between 960 and ~1208px.
bool isDesktopWorkspace(BuildContext context) {
  if (!AppPlatform.isWeb) return false;
  // Subscribe to size changes so callers rebuild on window resize.
  MediaQuery.sizeOf(context);
  final view = View.of(context);
  final width = view.physicalSize.width / view.devicePixelRatio;
  return workspaceLayoutTierForWidth(width) != WorkspaceLayoutTier.mobile;
}
