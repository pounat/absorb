import 'package:flutter/material.dart';

class AdminSectionDestination {
  final String id;
  final IconData icon;
  final String label;

  const AdminSectionDestination(this.id, this.icon, this.label);
}

class AdminAdaptiveFrame extends StatelessWidget {
  final bool desktopMode;
  final String title;
  final String selectedSection;
  final List<AdminSectionDestination> destinations;
  final ValueChanged<String> onSectionSelected;
  final Widget child;

  const AdminAdaptiveFrame({
    super.key,
    required this.desktopMode,
    required this.title,
    required this.selectedSection,
    required this.destinations,
    required this.onSectionSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!desktopMode) return child;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The desktop shell may stay mounted briefly below its breakpoint so
        // an in-progress upload cannot be abandoned. Give the upload pane the
        // full narrow width instead of squeezing it between two sidebars.
        if (constraints.maxWidth < 720) return child;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const Key('admin-desktop-sidebar'),
              width: 224,
              child: Material(
                color: cs.surface.withValues(alpha: 0.38),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Text(
                        title,
                        style: tt.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    for (final destination in destinations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: selectedSection == destination.id
                              ? cs.primary.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey(
                              'admin-destination-${destination.id}',
                            ),
                            onTap: () => onSectionSelected(destination.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    destination.icon,
                                    size: 19,
                                    color: selectedSection == destination.id
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Text(
                                      destination.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.bodyMedium?.copyWith(
                                        color: selectedSection == destination.id
                                            ? cs.onSurface
                                            : cs.onSurfaceVariant,
                                        fontWeight:
                                            selectedSection == destination.id
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
            Expanded(
              key: const Key('admin-desktop-content'),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: LayoutBuilder(
                    builder: (context, constraints) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      child: ClipRect(child: SizedBox.expand(child: child)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
