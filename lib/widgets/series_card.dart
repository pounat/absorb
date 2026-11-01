import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import '../l10n/app_localizations.dart';
import 'cover_badges.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import 'series_books_sheet.dart';

class SeriesCard extends StatelessWidget {
  final Map<String, dynamic> series;
  final double coverAspectRatio;

  const SeriesCard({super.key, required this.series, this.coverAspectRatio = 1.0});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();
    final auth = context.read<AuthProvider>();

    final name = series['name'] as String? ?? l.seriesCardUnknownSeries;
    final seriesId = series['id'] as String? ?? '';
    final books = series['books'] as List<dynamic>? ?? [];
    final bookCount = books.length;

    // Gather up to 4 cover URLs
    final coverUrls = books
        .take(4)
        .map((b) {
          final bookId = (b as Map<String, dynamic>)['id'] as String? ?? '';
          return bookId.isNotEmpty ? lib.getCoverUrl(bookId) : null;
        })
        .toList();

    // Calculate series progress
    double totalProgress = 0;
    int finished = 0;
    for (final b in books) {
      final bookId = (b as Map<String, dynamic>)['id'] as String? ?? '';
      if (bookId.isEmpty) continue;
      final pd = lib.getProgressData(bookId);
      if (pd?['isFinished'] == true) {
        finished++;
        totalProgress += 1.0;
      } else {
        totalProgress += lib.getProgress(bookId);
      }
    }
    final seriesProgress = books.isNotEmpty ? totalProgress / books.length : 0.0;

    return GestureDetector(
      onTap: () {
        if (seriesId.isNotEmpty) {
          showSeriesBooksSheet(
            context,
            seriesName: name,
            seriesId: seriesId,
            books: const [],
            serverUrl: auth.serverUrl,
            token: auth.token,
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stacked covers
          AspectRatio(
            aspectRatio: coverAspectRatio,
            child: _StackedCovers(
              coverUrls: coverUrls,
              numBooks: bookCount,
              mediaHeaders: lib.mediaHeaders,
              cs: cs,
              seriesProgress: seriesProgress,
              booksFinished: finished,
              coverAspectRatio: coverAspectRatio,
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                fontSize: 11,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              l.seriesCardBookCount(bookCount),
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacked cover art for series - shows up to 4 covers layered.
class _StackedCovers extends StatelessWidget {
  final List<String?> coverUrls;
  final int numBooks;
  final Map<String, String> mediaHeaders;
  final ColorScheme cs;
  final double seriesProgress;
  final int booksFinished;
  final double coverAspectRatio;

  const _StackedCovers({
    required this.coverUrls,
    required this.numBooks,
    required this.mediaHeaders,
    required this.cs,
    this.seriesProgress = 0,
    this.booksFinished = 0,
    this.coverAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final count = coverUrls.length.clamp(1, 4);
    const inset = 5.0;
    final totalOffset = count > 1 ? inset * (count - 1) : 0.0;

    return Stack(
      children: [
        for (int i = count - 1; i > 0; i--)
          Positioned(
            top: (totalOffset - i * inset),
            right: (totalOffset - i * inset),
            left: i * inset,
            bottom: i * inset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 2,
                    offset: const Offset(-1, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _coverImage(coverUrls[i]),
              ),
            ),
          ),
        Positioned(
          top: totalOffset,
          right: totalOffset,
          left: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: count > 1
                  ? [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                      offset: const Offset(-1, 1),
                    )]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _coverImage(coverUrls.isNotEmpty ? coverUrls[0] : null),
                  if (seriesProgress > 0 && booksFinished < numBooks)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: LinearProgressIndicator(
                        value: seriesProgress.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: Colors.black38,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                  if (booksFinished > 0 && booksFinished >= numBooks)
                    const Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: CoverStateBadges(isDownloaded: false, isFinished: true),
                    ),
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 9, color: cs.onPrimaryContainer),
                          const SizedBox(width: 2),
                          Text(booksFinished > 0 && booksFinished < numBooks
                              ? '$booksFinished/$numBooks'
                              : '$numBooks',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverImage(String? url) {
    if (url == null) return _placeholder();
    // Series stacked covers are always cropped to fit - no blur padding needed
    if (url.startsWith('/')) {
      return Image.file(File(url), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return CachedNetworkImage(imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet, imageUrl: url, fit: BoxFit.cover,
        httpHeaders: mediaHeaders, placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder());
  }

  Widget _placeholder() {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.auto_stories_rounded,
            size: 24, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
      ),
    );
  }
}
