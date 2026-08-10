import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Consistent page header used across all screens.
///
/// Shows the ABSORB branding + page title, left-aligned, with optional
/// trailing actions.  Designed to be placed inside scrollable content
/// (CustomScrollView slivers, ListView children, etc.) so it scrolls
/// away with the page.
class AbsorbPageHeader extends StatelessWidget {
  final String title;
  final Color? brandingColor;
  final Color? titleColor;
  final List<Widget>? actions;
  final Widget? trailing;
  final bool showBranding;
  final EdgeInsetsGeometry padding;

  const AbsorbPageHeader({
    super.key,
    required this.title,
    this.brandingColor,
    this.titleColor,
    this.actions,
    this.trailing,
    this.showBranding = true,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 0),
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final bColor = brandingColor ?? cs.onSurfaceVariant;
    final tColor = titleColor ?? cs.onSurface;
    final headerActions = actions;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final reservedWidth = showBranding ? 140.0 : 200.0;
              final maxActionWidth =
                  (constraints.maxWidth - reservedWidth)
                      .clamp(0.0, double.infinity)
                      .toDouble();
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 32),
                child: Row(
                  children: [
                    if (showBranding)
                      Text(
                        l.appTitle,
                        style: tt.labelSmall?.copyWith(
                          color: bColor,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w300,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                    if (showBranding)
                      const Spacer()
                    else
                      const SizedBox(width: 12),
                    if (headerActions != null && headerActions.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxActionWidth),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: headerActions,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (showBranding) ...[
            const SizedBox(height: 4),
            Text(
              title,
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: tColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
