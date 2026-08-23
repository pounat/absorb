import 'package:flutter/material.dart';

/// One action in an [ActionPillGrid]: a centered icon over a short label.
class ActionPillData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color? tint;

  /// Optional hold action, for grids the user can rearrange.
  final VoidCallback? onLongPress;
  const ActionPillData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.tint,
    this.onLongPress,
  });
}

/// Responsive grid of action pills (the book-menu / admin-Users-page style):
/// 3 across normally, dropping to 2 on a narrow screen or a large system font
/// scale, with cell height that tracks the text scale so a 2-line label stays
/// inside its cell instead of overflowing.
class ActionPillGrid extends StatelessWidget {
  final List<ActionPillData> items;
  const ActionPillGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (ctx, constraints) {
      const gap = 10.0;
      final textScale = MediaQuery.textScalerOf(context).scale(1.0);
      final cols = (constraints.maxWidth < 340 || textScale >= 1.3) ? 2 : 3;
      final cellW = (constraints.maxWidth - gap * (cols - 1)) / cols;
      final cellH = (cols == 2 ? 72.0 : 80.0) * textScale.clamp(1.0, 1.7) + 8;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final it in items)
          SizedBox(width: cellW, height: cellH, child: _ActionPill(data: it, cs: cs)),
      ]);
    });
  }
}

class _ActionPill extends StatelessWidget {
  final ActionPillData data;
  final ColorScheme cs;
  const _ActionPill({required this.data, required this.cs});

  @override
  Widget build(BuildContext context) {
    final iconColor = data.enabled
        ? (data.tint ?? cs.onSurfaceVariant)
        : cs.onSurface.withValues(alpha: 0.24);
    final textColor = data.enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.24);
    return GestureDetector(
      onTap: data.onTap,
      onLongPress: data.onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, size: 22, color: iconColor),
            const SizedBox(height: 7),
            // Loose Flexible so a long label ellipsises inside the cell at big
            // font scales rather than overflowing it.
            Flexible(child: Text(data.label, textAlign: TextAlign.center, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500, height: 1.15))),
          ],
        ),
      ),
    );
  }
}
