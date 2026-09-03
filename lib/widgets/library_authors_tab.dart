import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import 'library_grid_tiles.dart';

class LibraryAuthorsTab extends StatelessWidget {
  final List<Map<String, dynamic>> authors;
  final bool isLoadingAuthors;
  final bool authorsLoaded;

  /// More pages exist past [authors]: the grid shows a loader cell and calls
  /// [onLoadMore] as the user nears the bottom.
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final Future<void> Function() onRefresh;
  final Widget? headerSliver;
  final ScrollController? scrollController;
  final bool selectionMode;
  final Set<String> selectedAuthorIds;
  final String? matchingAuthorId;
  final void Function(Map<String, dynamic> author, int index)?
      onSelectionToggle;

  const LibraryAuthorsTab({
    super.key,
    required this.authors,
    required this.isLoadingAuthors,
    required this.authorsLoaded,
    this.hasMore = false,
    this.onLoadMore,
    required this.onRefresh,
    this.headerSliver,
    this.scrollController,
    this.selectionMode = false,
    this.selectedAuthorIds = const {},
    this.matchingAuthorId,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final headers = <Widget>[if (headerSliver != null) headerSliver!];

    Widget body;
    if (isLoadingAuthors && authors.isEmpty) {
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
    } else if (authors.isEmpty && authorsLoaded) {
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
                  Icon(Icons.people_outline_rounded,
                      size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(l.libraryNoAuthorsFound,
                      style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Same next-page trigger as the books grid: driven by which tile index
      // the viewport builds, not by scroll metrics, which go stale after
      // items are appended beyond the fold (see LibraryBooksTab).
      final cols = responsiveGridCount(context);
      final loadAheadAt = authors.length - cols * 8;
      final route = ModalRoute.of(context);
      final loadMore = onLoadMore;
      void maybeLoadAhead(int index) {
        if (!hasMore || isLoadingAuthors || loadMore == null) return;
        if (index < loadAheadAt) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (route != null && !route.isCurrent) return;
          loadMore();
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
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  maybeLoadAhead(index);
                  if (index >= authors.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final author = authors[index];
                  final authorId = author['id'] as String? ?? '';
                  return GridAuthorTile(
                    author: author,
                    selectionMode: selectionMode,
                    isSelected: selectedAuthorIds.contains(authorId),
                    isMatching: matchingAuthorId == authorId,
                    onSelectionToggle: onSelectionToggle == null
                        ? null
                        : () => onSelectionToggle!(author, index),
                  );
                },
                childCount: authors.length + (hasMore ? 1 : 0),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(onRefresh: onRefresh, child: body);
  }
}
