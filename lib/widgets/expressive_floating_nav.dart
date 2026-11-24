import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../services/native_tab_bar.dart';
import 'expressive.dart';

/// The bottom tabs as a pill floating over the page, for the Material 3
/// Expressive look. Scrolling a list down shrinks it to a short row of icons
/// instead of sliding it away, so the tabs stay in reach.
///
/// It always takes the same room at the bottom of the screen, whatever size
/// the pill is, so the page above it isn't laid out again on every frame of
/// a scroll.
class ExpressiveFloatingNav extends StatelessWidget {
  /// 1 with the labels showing, 0 shrunk to icons.
  final Animation<double> reveal;
  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onLongPress;

  /// Stay as the short row of icons (a phone on its side).
  final bool compact;

  const ExpressiveFloatingNav({
    super.key,
    required this.reveal,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
    required this.onLongPress,
    this.compact = false,
  });

  static const _tall = 64.0;
  static const _short = 48.0;
  static const _gapBelow = 8.0;
  static const _gapAbove = 4.0;
  static const _sidePadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final barTheme = theme.navigationBarTheme;
    final mq = MediaQuery.of(context);
    final count = destinations.length;
    final available = mq.size.width - mq.padding.left - mq.padding.right - 40;
    final wide = math.min(available, 560.0);
    final narrow = math.min(wide, count * 60.0 + _sidePadding * 2);
    final textScaler = mq.textScaler.clamp(maxScaleFactor: 1.15);
    NativeTabBar.pillWide = wide;
    NativeTabBar.pillNarrow = compact ? wide : narrow;

    return SizedBox(
      height: _gapAbove + (compact ? _short : _tall) + _gapBelow + mq.padding.bottom,
      child: Padding(
        padding: EdgeInsets.only(bottom: _gapBelow + mq.padding.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: reveal,
            builder: (context, _) {
              final t = compact ? 0.0 : Curves.easeOut.transform(reveal.value.clamp(0.0, 1.0));
              final height = lerpDouble(_short, _tall, t)!;
              final top = lerpDouble(8, 6, t)!;
              return Material(
                // A step lighter than the page and not quite solid, so it
                // reads as its own layer with the page passing behind it.
                color: cs.surfaceContainerHigh.withValues(alpha: 0.94),
                elevation: 6,
                shadowColor: Colors.black,
                clipBehavior: Clip.antiAlias,
                shape: StadiumBorder(side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35))),
                child: SizedBox(
                  width: lerpDouble(narrow, wide, t),
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
                    // The highlight leaves room for a camera cutout on a
                    // full-width bar. The pill is already clear of it.
                    child: MediaQuery.removePadding(
                      context: context,
                      removeLeft: true,
                      removeRight: true,
                      child: ExpressiveNavHighlight(
                        selectedIndex: selectedIndex,
                        count: count,
                        centerY: top + 16,
                        background: Colors.transparent,
                        pillColor: barTheme.indicatorColor ?? cs.secondaryContainer,
                        shapeColor: cs.primary.withValues(alpha: 0.5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < count; i++)
                              Expanded(child: _tab(context, i, t, top, textScaler)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i, double t, double top, TextScaler textScaler) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final barTheme = theme.navigationBarTheme;
    final d = destinations[i];
    final selected = i == selectedIndex;
    final states = <WidgetState>{if (selected) WidgetState.selected};
    final iconTheme = barTheme.iconTheme?.resolve(states) ??
        // The selected tab wears the app's color, as the Absorbing tab's
        // own icon always has.
        IconThemeData(size: 24, color: selected ? cs.primary : cs.onSurfaceVariant);
    final labelStyle = barTheme.labelTextStyle?.resolve(states) ??
        theme.textTheme.labelMedium?.copyWith(
          color: selected ? cs.onSurface : cs.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
    return Semantics(
      button: true,
      selected: selected,
      label: d.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(i),
        onLongPress: () => onLongPress(i),
        child: Column(
          children: [
            SizedBox(height: top),
            SizedBox(
              height: 32,
              child: Center(
                child: IconTheme.merge(data: iconTheme, child: selected ? (d.selectedIcon ?? d.icon) : d.icon),
              ),
            ),
            if (t > 0)
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: t,
                  child: Opacity(
                    opacity: t,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
                      child: ExcludeSemantics(
                        child: Text(
                          d.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          textScaler: textScaler,
                          style: labelStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
