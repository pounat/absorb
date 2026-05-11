import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import 'library_grid_tiles.dart';

class LibraryBooksTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isLoadingPage;
  final bool hasMore;
  final ScrollController scrollController;
  final LibraryFilter filter;
  final String? genreFilter;
  final bool rectangleCovers;
  final double coverAspectRatio;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearFilter;

  const LibraryBooksTab({
    super.key,
    required this.items,
    required this.isLoadingPage,
    required this.hasMore,
    required this.scrollController,
    required this.filter,
    this.genreFilter,
    required this.rectangleCovers,
    required this.coverAspectRatio,
    required this.onRefresh,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    if (items.isEmpty && isLoadingPage) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty && !isLoadingPage) {
      final filterMsg = switch (filter) {
        LibraryFilter.inProgress => l.libraryNoBooksInProgress,
        LibraryFilter.finished => l.libraryNoFinishedBooks,
        LibraryFilter.notStarted => l.libraryAllBooksStarted,
        LibraryFilter.downloaded => l.libraryNoDownloadedBooks,
        LibraryFilter.inASeries => l.libraryNoSeriesFound,
        LibraryFilter.hasEbook => l.libraryNoBooksWithEbooks,
        LibraryFilter.genre => l.libraryNoBooksInGenre(genreFilter ?? l.genre.toLowerCase()),
        LibraryFilter.none => l.libraryNoBooks,
      };
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
                    Icon(Icons.library_books_outlined,
                        size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(filterMsg,
                        style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                    if (filter != LibraryFilter.none) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onClearFilter,
                        child: Text(l.libraryClearFilter,
                            style: tt.bodySmall?.copyWith(color: cs.primary)),
                      ),
                    ],
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
      child: GridView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, libraryGridBottomPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsiveGridCount(context),
          childAspectRatio: rectangleCovers ? 0.48 : 0.68,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final item = items[index];
        if (item.containsKey('collapsedSeries')) {
          return GridSeriesTile(item: item, coverAspectRatio: coverAspectRatio);
        }
        return GridBookTile(item: item, coverAspectRatio: coverAspectRatio);
      },
    ),
    );
  }
}
