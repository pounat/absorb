import 'package:flutter/material.dart';

import 'expressive.dart';

/// A settings section's row on the main settings list: the section's icon on
/// a tinted tile, its name, and a line of what it's set to now. Opens the
/// section as its own page.
class SettingsSectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? summary;
  final VoidCallback onTap;

  const SettingsSectionTile({
    super.key,
    required this.icon,
    required this.title,
    this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.onSurface, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (summary != null && summary!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section opened as its own page, with a big title that shrinks into the
/// bar as the page scrolls. [pinned] stays under the bar while the rest
/// scrolls, on screens tall enough to spare the room.
class SettingsPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? pinned;
  final double pinnedHeight;

  const SettingsPage({
    super.key,
    required this.title,
    required this.child,
    this.pinned,
    this.pinnedHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pinned = this.pinned;
    final roomToPin = MediaQuery.sizeOf(context).height - pinnedHeight >= 440;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(title)),
          if (pinned != null && roomToPin)
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeader(
                height: pinnedHeight,
                child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor, child: pinned),
              ),
            )
          else if (pinned != null)
            SliverToBoxAdapter(child: SizedBox(height: pinnedHeight, child: pinned)),
          SliverToBoxAdapter(child: child),
          SliverToBoxAdapter(child: SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom)),
        ],
      ),
    );
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _PinnedHeader({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_PinnedHeader old) => old.height != height || old.child != child;
}

/// Related settings kept together under a small label. Each row is its own
/// card, joined to its neighbours: the outside corners round off, the ones
/// between rows stay tight.
class SettingsGroup extends StatelessWidget {
  final String? label;
  final List<Widget> children;

  const SettingsGroup({super.key, this.label, required this.children});

  static const _outer = Radius.circular(20);
  static const _inner = Radius.circular(6);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final n = children.length;
    if (n == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                label!,
                style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
              ),
            ),
          for (var i = 0; i < n; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
              child: Material(
                color: cs.surfaceContainerHigh,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? _outer : _inner,
                  bottom: i == n - 1 ? _outer : _inner,
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: children[i],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One settings row: a title, an optional line under it, and whatever sits
/// on the right (a switch, a value, an arrow).
class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onInfo;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: cs.onSurfaceVariant, size: 22),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
                      if (onInfo != null)
                        InkResponse(
                          onTap: onInfo,
                          radius: 18,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.info_outline_rounded,
                                size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                          ),
                        ),
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A row with a switch. Tapping anywhere on the row flips it.
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onInfo;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      onInfo: onInfo,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: ExpressivePop(
        active: value,
        child: Switch.adaptive(value: value, onChanged: onChanged),
      ),
    );
  }
}

/// A row with a slider under its title and the current value in a pill on
/// the right. [below] sits under the slider (presets, a hint).
class SettingsSliderTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget slider;
  final Widget? below;

  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.slider,
    this.below,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(value, style: tt.labelLarge?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
            ),
          const SizedBox(height: 4),
          slider,
          if (below != null) below!,
        ],
      ),
    );
  }
}
