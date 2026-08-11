import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import '../utils/desktop_workspace.dart';
import 'library_grid_tiles.dart';

class LibrarySeriesTab extends StatelessWidget {
  final List<Map<String, dynamic>> seriesItems;
  final bool isLoadingSeriesPage;
  final bool hasMoreSeries;
  final bool rectangleCovers;
  final double coverAspectRatio;
  final double desktopMaxCrossAxisExtent;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget? headerSliver;
  final ScrollController? scrollController;

  const LibrarySeriesTab({
    super.key,
    required this.seriesItems,
    required this.isLoadingSeriesPage,
    required this.hasMoreSeries,
    required this.rectangleCovers,
    required this.coverAspectRatio,
    this.desktopMaxCrossAxisExtent = kDesktopLibraryTileMaxExtent,
    required this.onRefresh,
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
    if (seriesItems.isEmpty && isLoadingSeriesPage) {
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
    } else if (seriesItems.isEmpty && !isLoadingSeriesPage) {
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
                  Icon(
                    Icons.collections_bookmark_outlined,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.libraryNoSeriesFound,
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
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
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              libraryGridBottomPadding(context),
            ),
            sliver: SliverGrid(
              gridDelegate: libraryGridDelegate(
                context,
                childAspectRatio: rectangleCovers ? 0.48 : 0.68,
                desktopMaxCrossAxisExtent: desktopMaxCrossAxisExtent,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= seriesItems.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return GridSeriesTileDirect(
                  series: seriesItems[index],
                  coverAspectRatio: coverAspectRatio,
                );
              }, childCount: seriesItems.length + (hasMoreSeries ? 1 : 0)),
            ),
          ),
        ],
      );
    }

    // Tablets: the first page may not fill the screen, so nothing scrolls and
    // the bottom-trigger never fires. After layout, if the grid isn't scrollable
    // yet and there's more to load, pull the next page until the viewport fills.
    if (hasMoreSeries && !isLoadingSeriesPage && seriesItems.isNotEmpty) {
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
      child: isDesktopWorkspace(context)
          ? body
          : RefreshIndicator(onRefresh: onRefresh, child: body),
    );
  }
}
