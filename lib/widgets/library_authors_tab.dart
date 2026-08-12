import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import '../utils/desktop_workspace.dart';
import 'library_grid_tiles.dart';

class LibraryAuthorsTab extends StatelessWidget {
  final List<Map<String, dynamic>> authors;
  final bool isLoadingAuthors;
  final bool authorsLoaded;
  final double desktopMaxCrossAxisExtent;
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
    this.desktopMaxCrossAxisExtent = kDesktopLibraryTileMaxExtent,
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
    if (isLoadingAuthors) {
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
                  Icon(
                    Icons.people_outline_rounded,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.libraryNoAuthorsFound,
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
                childAspectRatio: 0.68,
                desktopMaxCrossAxisExtent: desktopMaxCrossAxisExtent,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
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
              }, childCount: authors.length),
            ),
          ),
        ],
      );
    }

    return isDesktopWorkspace(context)
        ? body
        : RefreshIndicator(onRefresh: onRefresh, child: body);
  }
}
