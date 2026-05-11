import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'absorbing_shared.dart';
import 'book_detail_sheet.dart';
import 'episode_list_sheet.dart';
import 'series_books_sheet.dart';
import 'author_books_sheet.dart';

// ═══════════════════════════════════════════════════════════════
// Grid book tile (cover + title + author)
// ═══════════════════════════════════════════════════════════════
class GridBookTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final double coverAspectRatio;
  final String? sequenceBadge;

  const GridBookTile({super.key, required this.item, this.coverAspectRatio = 1.0, this.sequenceBadge});

  @override
  State<GridBookTile> createState() => _GridBookTileState();
}

class _GridBookTileState extends State<GridBookTile> {
  final _dl = DownloadService();

  @override
  void initState() {
    super.initState();
    _dl.addListener(_rebuild);
  }

  @override
  void dispose() {
    _dl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();

    final itemId = widget.item['id'] as String? ?? '';
    final media = widget.item['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? l.unknown;
    final author = metadata['authorName'] as String? ?? '';
    final coverUrl = lib.getCoverUrl(itemId);
    final progress = lib.getProgress(itemId);
    final isExplicit = PlayerSettings.showExplicitBadge && metadata['explicit'] == true;
    final isDownloaded = _dl.isDownloaded(itemId);
    final isFinished = lib.getProgressData(itemId)?['isFinished'] == true;
    final isSubscribed = lib.isPodcastLibrary && lib.isPodcastSubscribed(itemId);

    return GestureDetector(
      onTap: () {
        if (itemId.isNotEmpty) {
          if (lib.isPodcastLibrary) {
            EpisodeListSheet.show(context, widget.item);
          } else {
            showBookDetailSheet(context, itemId);
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          AspectRatio(
            aspectRatio: widget.coverAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  coverUrl != null
                      ? _blurCover(coverUrl, lib.mediaHeaders, cs, widget.coverAspectRatio, title, author)
                      : CoverPlaceholder(title: title, author: author),

                  // Progress bar at bottom of cover
                  if (progress > 0 && !isFinished)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: Colors.black38,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),

                  // Subscribed bell
                  if (isSubscribed)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_rounded,
                            size: 11, color: Colors.white),
                      ),
                    ),

                  // Explicit badge
                  if (isExplicit)
                    Positioned(
                      top: isSubscribed ? 22 : 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(l.libraryGridTilesExplicitBadge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ),

                  // Sequence badge
                  if (widget.sequenceBadge != null)
                    Positioned(
                      top: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(l.libraryGridTilesSequence(widget.sequenceBadge!),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ),

                  // ── Banners ──
                  if (isFinished || isDownloaded)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isFinished) ...[
                              Icon(Icons.check_circle_rounded,
                                  size: 10, color: Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent[400] : Colors.green.shade700),
                              const SizedBox(width: 3),
                              Text(l.libraryGridTilesDone,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent[400] : Colors.green.shade700)),
                            ],
                            if (isFinished && isDownloaded)
                              const SizedBox(width: 6),
                            if (isDownloaded) ...[
                              Icon(Icons.download_done_rounded,
                                  size: 10, color: cs.primary),
                              const SizedBox(width: 3),
                              Text(l.libraryGridTilesSaved,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary)),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontSize: 11,
            ),
          ),
          // Author
          if (author.isNotEmpty)
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _blurCover(String coverUrl, Map<String, String> headers, ColorScheme cs, double aspectRatio, String title, String author) {
    final placeholder = CoverPlaceholder(title: title, author: author);
    final isSquare = (aspectRatio - 1.0).abs() < 0.01;
    if (!isSquare) {
      if (coverUrl.startsWith('/')) {
        return Image.file(File(coverUrl), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder);
      }
      return CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover,
          httpHeaders: headers, placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder);
    }
    if (coverUrl.startsWith('/')) {
      return BlurPaddedCover(
        child: Image.file(File(coverUrl), fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => placeholder),
        blurChild: Image.file(File(coverUrl), fit: BoxFit.cover,
            errorBuilder: (_, __ ,___) => const SizedBox.shrink()),
      );
    }
    return BlurPaddedCover(
      child: CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.contain,
          httpHeaders: headers, placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder),
      blurChild: CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover,
          httpHeaders: headers, errorWidget: (_, __, ___) => const SizedBox.shrink()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Stacked cover art for series tiles
// Shows up to 3 covers offset behind each other.
// ═══════════════════════════════════════════════════════════════
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
    final l = AppLocalizations.of(context)!;
    final count = coverUrls.length.clamp(1, 4);

    const inset = 5.0;
    final totalOffset = count > 1 ? inset * (count - 1) : 0.0;

    return AspectRatio(
      aspectRatio: coverAspectRatio,
      child: Stack(
        children: [
          // Back covers (furthest back first so front paints on top)
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
          // Front cover (bottom-left)
          Positioned(
            top: totalOffset,
            right: totalOffset,
            left: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: count > 1
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 3,
                          offset: const Offset(-1, 1),
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _coverImage(coverUrls.isNotEmpty ? coverUrls[0] : null),
                    // Series progress bar
                    if (seriesProgress > 0 && booksFinished < numBooks)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: seriesProgress.clamp(0.0, 1.0),
                          minHeight: 3,
                          backgroundColor: Colors.black38,
                          valueColor: AlwaysStoppedAnimation(cs.primary),
                        ),
                      ),
                    // Finished banner
                    if (booksFinished > 0 && booksFinished >= numBooks)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.black.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 10,
                                  color: Colors.greenAccent),
                              const SizedBox(width: 3),
                              Text(l.finished,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9))),
                            ],
                          ),
                        ),
                      ),
                    // Book count badge
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories_rounded, size: 11, color: cs.onPrimaryContainer),
                            const SizedBox(width: 3),
                            Text(booksFinished > 0 && booksFinished < numBooks
                                ? '$booksFinished/$numBooks'
                                : '$numBooks',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _coverImage(String? url) {
    if (url == null) return _placeholder();
    // Series stacked covers are always cropped to fit - no blur padding needed
    if (url.startsWith('/')) {
      return Image.file(File(url), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
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

// ═══════════════════════════════════════════════════════════════
// Grid series tile (collapsed series in browse grid)
// ═══════════════════════════════════════════════════════════════
class GridSeriesTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final double coverAspectRatio;
  const GridSeriesTile({super.key, required this.item, this.coverAspectRatio = 1.0});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();
    final auth = context.read<AuthProvider>();

    final collapsedSeries = item['collapsedSeries'] as Map<String, dynamic>? ?? {};
    final seriesName = collapsedSeries['name'] as String? ?? l.libraryGridTilesUnknownSeries;
    final seriesId = collapsedSeries['id'] as String? ?? '';
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final author = metadata['authorName'] as String? ?? '';

    // Gather up to 4 cover URLs from libraryItemIds
    final itemIds = (collapsedSeries['libraryItemIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [item['id'] as String? ?? ''];
    final rawNumBooks = collapsedSeries['numBooks'] as int? ?? 0;
    final numBooks = rawNumBooks > 0 ? rawNumBooks : itemIds.length;
    final coverUrls = itemIds
        .take(4)
        .map((id) => lib.getCoverUrl(id))
        .toList();

    // Calculate series progress
    double totalProgress = 0;
    int finished = 0;
    for (final id in itemIds) {
      final pd = lib.getProgressData(id);
      if (pd?['isFinished'] == true) {
        finished++;
        totalProgress += 1.0;
      } else {
        totalProgress += lib.getProgress(id);
      }
    }
    final seriesProgress = itemIds.isNotEmpty ? totalProgress / itemIds.length : 0.0;

    return GestureDetector(
      onTap: () {
        if (seriesId.isNotEmpty) {
          showSeriesBooksSheet(
            context,
            seriesName: seriesName,
            seriesId: seriesId,
            books: const [],
            serverUrl: auth.serverUrl,
            token: auth.token,
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StackedCovers(
            coverUrls: coverUrls,
            numBooks: numBooks,
            mediaHeaders: lib.mediaHeaders,
            cs: cs,
            seriesProgress: seriesProgress,
            booksFinished: finished,
            coverAspectRatio: coverAspectRatio,
          ),
          const SizedBox(height: 5),
          Text(
            seriesName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontSize: 11,
            ),
          ),
          if (author.isNotEmpty)
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Grid series tile for the series API format (series tab)
// The series endpoint returns { id, name, books: [...] } instead
// of the collapsedSeries format used by the library items endpoint.
// ═══════════════════════════════════════════════════════════════
class GridSeriesTileDirect extends StatelessWidget {
  final Map<String, dynamic> series;
  final double coverAspectRatio;
  final String? parentSeriesId;
  const GridSeriesTileDirect({super.key, required this.series, this.coverAspectRatio = 1.0, this.parentSeriesId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();
    final auth = context.read<AuthProvider>();

    final seriesName = series['name'] as String? ?? l.libraryGridTilesUnknownSeries;
    final seriesId = series['id'] as String? ?? '';
    final books = series['books'] as List<dynamic>? ?? [];
    final numBooks = books.length;

    // Get author from first book
    String author = '';
    if (books.isNotEmpty) {
      final firstBook = books.first as Map<String, dynamic>? ?? {};
      final media = firstBook['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      author = metadata['authorName'] as String? ?? '';
    }

    // Gather up to 4 cover URLs from books
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
            seriesName: seriesName,
            seriesId: seriesId,
            books: const [],
            serverUrl: auth.serverUrl,
            token: auth.token,
            parentSeriesId: parentSeriesId,
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StackedCovers(
            coverUrls: coverUrls,
            numBooks: numBooks,
            mediaHeaders: lib.mediaHeaders,
            cs: cs,
            seriesProgress: seriesProgress,
            booksFinished: finished,
            coverAspectRatio: coverAspectRatio,
          ),
          const SizedBox(height: 5),
          Text(
            seriesName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontSize: 11,
            ),
          ),
          if (author.isNotEmpty)
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Grid author tile (circular avatar + name + book count)
// ═══════════════════════════════════════════════════════════════
class GridAuthorTile extends StatelessWidget {
  final Map<String, dynamic> author;
  const GridAuthorTile({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();

    final name = author['name'] as String? ?? l.unknown;
    final authorId = author['id'] as String? ?? '';
    final numBooks = author['numBooks'] as int? ?? 0;

    String? imageUrl;
    if (authorId.isNotEmpty && auth.apiService != null) {
      final ts = (author['updatedAt'] as num?)?.toInt();
      imageUrl = auth.apiService!.getAuthorImageUrl(authorId, updatedAt: ts);
    }

    final headers = lib.mediaHeaders;

    return GestureDetector(
      onTap: () {
        if (authorId.isNotEmpty) {
          showAuthorDetailSheet(context, authorId: authorId, authorName: name);
        }
      },
      child: Column(
        children: [
          // Circular avatar
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.secondaryContainer,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          httpHeaders: headers,
                          placeholder: (_, __) => _placeholder(cs),
                          errorWidget: (_, __, ___) => _placeholder(cs),
                        )
                      : _placeholder(cs),
                ),
                if (numBooks > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 11, color: cs.onPrimaryContainer),
                          const SizedBox(width: 3),
                          Text('$numBooks',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Center(
      child: Icon(Icons.person_rounded,
          size: 32, color: cs.onSecondaryContainer.withValues(alpha: 0.4)),
    );
  }
}

