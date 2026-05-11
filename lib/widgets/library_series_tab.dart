import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import 'library_grid_tiles.dart';

class LibrarySeriesTab extends StatelessWidget {
  final List<Map<String, dynamic>> seriesItems;
  final bool isLoadingSeriesPage;
  final bool hasMoreSeries;
  final ScrollController scrollController;
  final bool rectangleCovers;
  final double coverAspectRatio;
  final Future<void> Function() onRefresh;

  const LibrarySeriesTab({
    super.key,
    required this.seriesItems,
    required this.isLoadingSeriesPage,
    required this.hasMoreSeries,
    required this.scrollController,
    required this.rectangleCovers,
    required this.coverAspectRatio,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    if (seriesItems.isEmpty && isLoadingSeriesPage) {
      return const Center(child: CircularProgressIndicator());
    }
    if (seriesItems.isEmpty && !isLoadingSeriesPage) {
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
                    Icon(Icons.collections_bookmark_outlined,
                        size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(l.libraryNoSeriesFound,
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
        itemCount: seriesItems.length + (hasMoreSeries ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= seriesItems.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return GridSeriesTileDirect(series: seriesItems[index], coverAspectRatio: coverAspectRatio);
        },
      ),
    );
  }
}
