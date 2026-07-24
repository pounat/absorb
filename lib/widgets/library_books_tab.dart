import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import 'library_grid_tiles.dart';

class LibraryBooksTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isLoadingPage;
  final bool hasMore;
  final LibraryFilter filter;
  final String? genreFilter;
  final String? tagFilter;
  final bool isPodcastLibrary;
  final bool rectangleCovers;
  final double coverAspectRatio;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearFilter;

  /// Optional sliver inserted at the top of this tab's scroll view (typically
  /// a SliverAppBar containing the shared library header). When non-null, the
  /// tab is responsible for owning its own scroll position so the SliverAppBar
  /// floats independently.
  final Widget? headerSliver;

  /// Called when the user scrolls within ~400px of the bottom; library_screen
  /// owns the actual page-fetch logic.
  final VoidCallback onLoadMore;

  /// Optional explicit ScrollController. When tabs are kept alive in an
  /// IndexedStack each one needs its own controller so scroll positions don't
  /// collide on the PrimaryScrollController.
  final ScrollController? scrollController;

  const LibraryBooksTab({
    super.key,
    required this.items,
    required this.isLoadingPage,
    required this.hasMore,
    required this.filter,
    this.genreFilter,
    this.tagFilter,
    this.isPodcastLibrary = false,
    required this.rectangleCovers,
    required this.coverAspectRatio,
    required this.onRefresh,
    required this.onClearFilter,
    required this.onLoadMore,
    this.headerSliver,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final headers = <Widget>[if (headerSliver != null) headerSliver!];

    Widget body;
    if (items.isEmpty && isLoadingPage) {
      body = CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...headers,
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    } else if (items.isEmpty && !isLoadingPage) {
      final filterMsg = isPodcastLibrary && filter != LibraryFilter.none
          ? l.libraryNoItemsMatchingFilter
          : switch (filter) {
        LibraryFilter.notFinished => l.libraryNoUnfinishedBooks,
        LibraryFilter.inProgress => l.libraryNoBooksInProgress,
        LibraryFilter.finished => l.libraryNoFinishedBooks,
        LibraryFilter.notStarted => l.libraryAllBooksStarted,
        LibraryFilter.downloaded => l.libraryNoDownloadedBooks,
        LibraryFilter.subscribed => l.libraryNoItemsMatchingFilter,
        LibraryFilter.inASeries => l.libraryNoSeriesFound,
        LibraryFilter.hasEbook => l.libraryNoBooksWithEbooks,
        LibraryFilter.noEbook ||
        LibraryFilter.hasSupplementaryEbook ||
        LibraryFilter.noSupplementaryEbook ||
        LibraryFilter.series ||
        LibraryFilter.author ||
        LibraryFilter.narrator ||
        LibraryFilter.language ||
        LibraryFilter.publisher ||
        LibraryFilter.publishedDecade ||
        LibraryFilter.noTracks ||
        LibraryFilter.singleTrack ||
        LibraryFilter.multipleTracks ||
        LibraryFilter.abridged ||
        LibraryFilter.issues ||
        LibraryFilter.feedOpen ||
        LibraryFilter.explicit => l.libraryNoItemsMatchingFilter,
        LibraryFilter.missingMetadata => l.libraryNoBooksMissingMetadata,
        LibraryFilter.genre => l.libraryNoBooksInGenre(genreFilter ?? l.genre.toLowerCase()),
        LibraryFilter.tag => l.libraryNoBooksWithTag(tagFilter ?? l.tag.toLowerCase()),
        LibraryFilter.none => l.libraryNoBooks,
      };
      body = CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...headers,
          SliverFillRemaining(
            hasScrollBody: false,
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
      );
    } else {
      body = CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...headers,
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, libraryGridBottomPadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: responsiveGridCount(context),
                childAspectRatio: rectangleCovers ? 0.48 : 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                childCount: items.length + (hasMore ? 1 : 0),
              ),
            ),
          ),
        ],
      );
    }

    // On a tall/wide viewport (tablets) the first page often doesn't fill the
    // screen, so nothing scrolls and the bottom-trigger below never fires. After
    // layout, if the grid isn't scrollable yet and there's more to load, pull
    // the next page. Repeats on each rebuild until the viewport fills or we run
    // out of items.
    if (hasMore && !isLoadingPage && items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = scrollController;
        if (c != null && c.hasClients && c.position.maxScrollExtent <= 0) {
          onLoadMore();
        }
      });
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
          onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(onRefresh: onRefresh, child: body),
    );
  }
}
