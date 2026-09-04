import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/library_screen.dart';
import 'narrator_books_sheet.dart';

class LibraryNarratorsTab extends StatelessWidget {
  final List<String> narrators;

  /// Book count per narrator, when the server has answered; rows without an
  /// entry show no count.
  final Map<String, int> narratorCounts;
  final bool isLoading;
  final bool loaded;
  final Future<void> Function() onRefresh;
  final Widget? headerSliver;
  final ScrollController? scrollController;

  const LibraryNarratorsTab({
    super.key,
    required this.narrators,
    this.narratorCounts = const {},
    required this.isLoading,
    required this.loaded,
    required this.onRefresh,
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
    if (isLoading) {
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
    } else if (narrators.isEmpty && loaded) {
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
      );
    } else {
      body = CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...headers,
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, libraryGridBottomPadding),
            sliver: SliverList.separated(
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
                        Icon(Icons.mic_rounded,
                            size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
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
                        if (narratorCounts[name] case final count?) ...[
                          Text(
                            l.seriesBooksBookCount(count),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(onRefresh: onRefresh, child: body);
  }
}
