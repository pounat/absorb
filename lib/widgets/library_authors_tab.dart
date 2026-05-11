import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import 'library_grid_tiles.dart';

class LibraryAuthorsTab extends StatelessWidget {
  final List<Map<String, dynamic>> authors;
  final bool isLoadingAuthors;
  final bool authorsLoaded;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  const LibraryAuthorsTab({
    super.key,
    required this.authors,
    required this.isLoadingAuthors,
    required this.authorsLoaded,
    required this.scrollController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    if (isLoadingAuthors) {
      return const Center(child: CircularProgressIndicator());
    }
    if (authors.isEmpty && authorsLoaded) {
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
          childAspectRatio: 0.68,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: authors.length,
        itemBuilder: (context, index) {
          return GridAuthorTile(author: authors[index]);
        },
      ),
    );
  }
}
