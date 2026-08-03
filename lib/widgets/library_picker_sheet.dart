import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/player_settings.dart';
import 'adaptive_modal.dart';

/// Bottom-sheet library switcher shared by the Home/Library headers and the
/// bottom-nav long-press. When the dedicated Podcasts tab is enabled, its
/// library is hidden here - the tab is its only surface.
Future<void> showLibraryPickerSheet(
  BuildContext context,
  LibraryProvider lib,
) async {
  String? excludeLibraryId;
  if (await PlayerSettings.getPodcastTabEnabled()) {
    final id = await PlayerSettings.getPodcastTabLibraryId();
    if (id.isNotEmpty) excludeLibraryId = id;
  }
  if (!context.mounted) return;

  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final l = AppLocalizations.of(context)!;
  final allLibraries = lib.libraries
      .whereType<Map<String, dynamic>>()
      .where((library) => library['id'] != excludeLibraryId)
      .toList();

  showAdaptiveActionMenu(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    desktopScrollWrap: false,
    builder: (ctx) {
      final desktop = ModalSurface.isDesktopOf(ctx);
      final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
      return Container(
        constraints: desktop
            ? null
            : BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
        decoration: desktop
            ? null
            : BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!desktop) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l.selectLibrary,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(bottom: bottomPad + 16),
                itemCount: allLibraries.length,
                itemBuilder: (_, i) {
                  final library = allLibraries[i];
                  final id = library['id'] as String;
                  final name = library['name'] as String? ?? l.libraryFallback;
                  final mediaType = library['mediaType'] as String? ?? 'book';
                  final isSelected = id == lib.selectedLibraryId;
                  return ListTile(
                    leading: Icon(
                      mediaType == 'podcast'
                          ? Icons.podcasts_rounded
                          : Icons.auto_stories_rounded,
                      color: isSelected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    title: Text(name),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: cs.primary)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (!isSelected) lib.selectLibrary(id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
