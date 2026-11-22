import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../widgets/absorbing_shared.dart';
import 'tv_focusable.dart';

/// Title and author out of a library item map, books and podcasts alike.
({String title, String author}) tvItemNames(Map<String, dynamic> item) {
  final meta = (item['media'] as Map?)?['metadata'] as Map?;
  final title = meta?['title'] as String? ?? '';
  final author = meta?['authorName'] as String? ?? meta?['author'] as String? ?? '';
  return (title: title, author: author);
}

/// A cover with its title under it, for the library grid and search.
class TvCoverTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onSelect;
  final bool autofocus;
  final FocusNode? focusNode;

  const TvCoverTile({super.key, required this.item, required this.onSelect, this.autofocus = false, this.focusNode});

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryProvider>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final id = item['id'] as String?;
    final names = tvItemNames(item);
    final progress = id == null ? null : lib.getProgressData(id);
    final pct = (progress?['progress'] as num?)?.toDouble() ?? 0;
    final finished = progress?['isFinished'] == true;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: TvFocusable(
              onSelect: onSelect,
              autofocus: autofocus,
              focusNode: focusNode,
              radius: 12,
              focusScale: 1.08,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TvCover(itemId: id, title: names.title, author: names.author, width: 300),
                    if (finished || pct > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: finished ? 1 : pct,
                          minHeight: 5,
                          backgroundColor: Colors.black45,
                          color: cs.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(names.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleSmall),
          Text(
            names.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class TvCover extends StatelessWidget {
  final String? itemId;
  final String title;
  final String author;
  final int width;

  const TvCover({super.key, required this.itemId, required this.title, required this.author, this.width = 400});

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryProvider>();
    final url = lib.getCoverUrl(itemId, width: width);
    final placeholder = CoverPlaceholder(title: title, author: author);
    if (url == null || url.isEmpty) return placeholder;
    // No fades: a grid full of covers each fading in is what made
    // scrolling stutter. A flat color holds the spot until it loads.
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: lib.mediaHeaders,
      fit: BoxFit.cover,
      memCacheWidth: width,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (context, _) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHigh),
      errorWidget: (_, _, _) => placeholder,
    );
  }
}
