import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import 'narrator_books_sheet.dart';

class LibraryNarratorsTab extends StatelessWidget {
  final List<String> narrators;
  final bool isLoading;
  final bool loaded;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  const LibraryNarratorsTab({
    super.key,
    required this.narrators,
    required this.isLoading,
    required this.loaded,
    required this.scrollController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (narrators.isEmpty && loaded) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic_none_rounded,
                        size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(l.libraryNoNarratorsFound,
                        style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, libraryGridBottomPadding),
        itemCount: narrators.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.5,
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) {
          final name = narrators[index];
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => showNarratorBooksSheet(context, narratorName: name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
