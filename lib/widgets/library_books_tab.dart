import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import 'library_grid_tiles.dart';

class LibraryBooksTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isLoadingPage;
  final bool hasMore;

  /// The last page request failed. The loader slot becomes a retry button and
  /// the auto-fetch triggers stay quiet until the user taps it or refreshes.
  final bool loadFailed;
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

  /// Called when the grid gets within [_loadAheadRows] rows of its end, or the
  /// user taps retry after a failed page; library_screen owns the actual
  /// page-fetch logic.
  final VoidCallback onLoadMore;

  // How many rows before the end the next page is requested. Eight rows is
  // about two phone screens, so the fetch is usually done before the user
  // gets there.
  static const _loadAheadRows = 8;

  /// Optional explicit ScrollController. When tabs are kept alive in an
  /// IndexedStack each one needs its own controller so scroll positions don't
  /// collide on the PrimaryScrollController.
  final ScrollController? scrollController;
  final bool selectionMode;
  final Set<String> selectedItemIds;
  final void Function(Map<String, dynamic> item, int index)? onSelectionToggle;

  const LibraryBooksTab({
    super.key,
    required this.items,
    required this.isLoadingPage,
    required this.hasMore,
    this.loadFailed = false,
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
    this.selectionMode = false,
    this.selectedItemIds = const {},
    this.onSelectionToggle,
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
    } else if (items.isEmpty && !isLoadingPage && loadFailed) {
      // The first page never arrived. Say so rather than "no books", which is
      // what an empty grid otherwise claims.
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
                  Icon(Icons.cloud_off_outlined,
                      size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(l.failedToLoad,
                      style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  TextButton(onPressed: onLoadMore, child: Text(l.retry)),
                ],
              ),
            ),
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
      // Next-page trigger, driven by what the viewport actually builds rather
      // than by scroll metrics. A sliver only re-measures when a child it has
      // already laid out changes, so after appending items beyond the fold it
      // kept quoting the old extent; an extent-based "is there less than two
      // screens left" check then read true on every rebuild and pulled the
      // whole library while the user sat at the top. A tile index can only be
      // built when it is really within a screen or so of the viewport, and
      // the loader cell itself gets built on a tall viewport a page can't
      // fill - so this covers both the scroll case and the iPad fill case.
      final cols = responsiveGridCount(context);
      final loadAheadAt = items.length - cols * _loadAheadRows;
      // Not while a sheet is open on top: on a slow server every grid page
      // is seconds of work, queued ahead of whatever the sheet is asking for.
      final route = ModalRoute.of(context);
      void maybeLoadAhead(int index) {
        if (!hasMore || isLoadingPage || loadFailed) return;
        if (index < loadAheadAt) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (route != null && !route.isCurrent) return;
          onLoadMore();
        });
      }

      body = CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...headers,
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, libraryGridBottomPadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: rectangleCovers ? 0.48 : 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  maybeLoadAhead(index);
                  if (index >= items.length) {
                    if (loadFailed) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.failedToLoad,
                                textAlign: TextAlign.center,
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                            TextButton(
                                onPressed: onLoadMore, child: Text(l.retry)),
                          ],
                        ),
                      );
                    }
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
                  final itemId = item['id'] as String?;
                  return GridBookTile(
                    item: item,
                    coverAspectRatio: coverAspectRatio,
                    selectionMode: selectionMode,
                    selected: itemId != null && selectedItemIds.contains(itemId),
                    onSelectionToggle: itemId == null || onSelectionToggle == null
                        ? null
                        : () => onSelectionToggle!(item, index),
                  );
                },
                childCount: items.length + (hasMore ? 1 : 0),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(onRefresh: onRefresh, child: body);
  }
}
