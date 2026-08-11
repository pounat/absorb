import 'package:flutter/material.dart';
import '../screens/library_screen.dart';
import '../utils/desktop_workspace.dart';
import 'library_grid_tiles.dart';

/// Library "Lists" tab: a stacked-cover grid of all collections and playlists
/// together (sorted by the screen). Each [entry] carries an injected
/// `_isPlaylist` flag. Tapping a tile opens its detail sheet, like a series.
class LibraryListsTab extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final bool isLoading;
  final double coverAspectRatio;
  final double desktopMaxCrossAxisExtent;
  final void Function(Map<String, dynamic>) onOpenCollection;
  final void Function(Map<String, dynamic>) onOpenPlaylist;
  final Future<void> Function() onRefresh;
  final Widget? headerSliver;
  final ScrollController? scrollController;

  const LibraryListsTab({
    super.key,
    required this.entries,
    required this.coverAspectRatio,
    this.desktopMaxCrossAxisExtent = kDesktopLibraryTileMaxExtent,
    required this.onOpenCollection,
    required this.onOpenPlaylist,
    required this.onRefresh,
    this.isLoading = false,
    this.headerSliver,
    this.scrollController,
  });

  static List<String> _collectionBookIds(Map<String, dynamic> c) =>
      ((c['books'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map((b) => b['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

  static List<String> _playlistBookIds(Map<String, dynamic> p) {
    final ids = <String>[];
    for (final it in (p['items'] as List<dynamic>?) ?? []) {
      if (it is Map<String, dynamic>) {
        final li = it['libraryItem'];
        if (li is Map<String, dynamic>) {
          final id = li['id'] as String? ?? '';
          if (id.isNotEmpty) ids.add(id);
        }
      }
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final headers = <Widget>[if (headerSliver != null) headerSliver!];

    Widget body;
    if (entries.isEmpty) {
      body = CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...headers,
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.collections_bookmark_outlined,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No collections or playlists',
                          style: tt.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
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
                childAspectRatio: coverAspectRatio < 1 ? 0.48 : 0.68,
                desktopMaxCrossAxisExtent: desktopMaxCrossAxisExtent,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = entries[index];
                final isPlaylist = entry['_isPlaylist'] == true;
                final name = entry['name'] as String? ?? '';
                final ids = isPlaylist
                    ? _playlistBookIds(entry)
                    : _collectionBookIds(entry);
                final count = isPlaylist
                    ? (entry['items'] as List<dynamic>?)?.length ?? ids.length
                    : (entry['books'] as List<dynamic>?)?.length ?? ids.length;
                return GridListTile(
                  name: name,
                  bookIds: ids,
                  count: count,
                  isPlaylist: isPlaylist,
                  coverAspectRatio: coverAspectRatio,
                  onTap: () => isPlaylist
                      ? onOpenPlaylist(entry)
                      : onOpenCollection(entry),
                );
              }, childCount: entries.length),
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
