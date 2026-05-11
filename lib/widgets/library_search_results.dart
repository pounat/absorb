import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'author_books_sheet.dart';
import 'book_detail_sheet.dart';
import 'episode_list_sheet.dart';
import 'narrator_books_sheet.dart';
import 'series_books_sheet.dart';

class BookResultTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? serverUrl;
  final String? token;
  final String? subtitle;
  final String? sequenceBadge;

  const BookResultTile({
    super.key,
    required this.item,
    required this.serverUrl,
    required this.token,
    this.subtitle,
    this.sequenceBadge,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final itemId = item['id'] as String?;
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? l.unknown;
    final authorName = metadata['authorName'] as String? ?? '';
    final lib = context.watch<LibraryProvider>();
    final isExplicit = PlayerSettings.showExplicitBadge && metadata['explicit'] == true;
    final isDownloaded = itemId != null && DownloadService().isDownloaded(itemId);
    final isFinished = itemId != null && lib.getProgressData(itemId)?['isFinished'] == true;
    final greenColor = Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent[400]! : Colors.green.shade700;

    String? coverUrl;
    if (itemId != null && serverUrl != null && token != null) {
      final cleanUrl = serverUrl!.endsWith('/')
          ? serverUrl!.substring(0, serverUrl!.length - 1)
          : serverUrl!;
      coverUrl = '$cleanUrl/api/items/$itemId/cover?width=200&token=$token';
      final ts = item['updatedAt'] as num?;
      if (ts != null) coverUrl = '$coverUrl&ts=${ts.toInt()}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            if (itemId != null) {
              final lib = context.read<LibraryProvider>();
              if (lib.isPodcastLibrary) {
                EpisodeListSheet.show(context, item);
              } else {
                showBookDetailSheet(context, itemId);
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                            httpHeaders: lib.mediaHeaders,
                            placeholder: (_, __) => _ph(cs),
                            errorWidget: (_, __, ___) => _ph(cs),
                          )
                        : _ph(cs),
                    if (sequenceBadge != null)
                      Positioned(
                        top: 3, left: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(l.librarySearchResultsSequence(sequenceBadge!),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (isExplicit)
                      Positioned(
                        top: 3, right: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(l.librarySearchResultsExplicitBadge, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    if (isFinished || isDownloaded)
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.85), Colors.black.withValues(alpha: 0.0)],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFinished) ...[
                                Icon(Icons.check_circle_rounded, size: 8, color: greenColor),
                                const SizedBox(width: 2),
                                Text(l.librarySearchResultsDone, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: greenColor)),
                              ],
                              if (isFinished && isDownloaded) const SizedBox(width: 4),
                              if (isDownloaded) ...[
                                Icon(Icons.download_done_rounded, size: 8, color: cs.primary),
                                const SizedBox(width: 2),
                                Text(l.librarySearchResultsSaved, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: cs.primary)),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      if (subtitle != null)
                        Text(subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                                color: cs.primary, fontSize: 11)),
                      if (authorName.isNotEmpty)
                        Text(authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ph(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.headphones_rounded,
          size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
    );
  }
}

class SeriesResultCard extends StatelessWidget {
  final Map<String, dynamic> series;
  final List<dynamic> books;
  final String? serverUrl;
  final String? token;

  const SeriesResultCard({
    super.key,
    required this.series,
    required this.books,
    required this.serverUrl,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final seriesName = series['name'] as String? ?? l.librarySearchResultsUnknownSeries;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showSeriesBooks(context, seriesName),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(Icons.auto_stories_rounded,
                        size: 22, color: cs.onSecondaryContainer.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(seriesName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      Text(
                          l.librarySearchResultsBookCount(books.length),
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSeriesBooks(BuildContext context, String seriesName) {
    showSeriesBooksSheet(
      context,
      seriesName: seriesName,
      seriesId: series['id'] as String?,
      books: books,
      serverUrl: serverUrl,
      token: token,
    );
  }
}

class EpisodeResultTile extends StatelessWidget {
  final Map<String, dynamic> show;
  final Map<String, dynamic> episode;
  final String? serverUrl;
  final String? token;

  const EpisodeResultTile({
    super.key,
    required this.show,
    required this.episode,
    required this.serverUrl,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final episodeTitle = episode['title'] as String? ?? l.librarySearchResultsUnknownEpisode;
    final showMedia = show['media'] as Map<String, dynamic>? ?? {};
    final showMeta = showMedia['metadata'] as Map<String, dynamic>? ?? {};
    final showTitle = showMeta['title'] as String? ?? '';
    final showId = show['id'] as String?;

    String? coverUrl;
    if (showId != null && serverUrl != null && token != null) {
      final cleanUrl = serverUrl!.endsWith('/')
          ? serverUrl!.substring(0, serverUrl!.length - 1)
          : serverUrl!;
      coverUrl = '$cleanUrl/api/items/$showId/cover?width=200&token=$token';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            EpisodeDetailSheet.show(context, show, episode);
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        httpHeaders: context.read<LibraryProvider>().mediaHeaders,
                        placeholder: (_, __) => _ph(cs),
                        errorWidget: (_, __, ___) => _ph(cs),
                      )
                    : _ph(cs),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(episodeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      if (showTitle.isNotEmpty)
                        Text(showTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ph(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.podcasts_rounded,
          size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
    );
  }
}

class AuthorResultTile extends StatelessWidget {
  final Map<String, dynamic> author;
  final String? serverUrl;
  final String? token;

  const AuthorResultTile({
    super.key,
    required this.author,
    required this.serverUrl,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final name = author['name'] as String? ?? l.unknown;
    final authorId = author['id'] as String? ?? '';
    final numBooks = author['numBooks'] as int?;

    String? imageUrl;
    if (authorId.isNotEmpty && serverUrl != null && token != null) {
      final cleanUrl = serverUrl!.endsWith('/')
          ? serverUrl!.substring(0, serverUrl!.length - 1)
          : serverUrl!;
      imageUrl =
          '$cleanUrl/api/authors/$authorId/image?width=200&token=$token';
      final ts = author['updatedAt'] as num?;
      if (ts != null) imageUrl = '$imageUrl&ts=${ts.toInt()}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showAuthorBooks(context, authorId, name),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Author avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.secondaryContainer,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          httpHeaders: context.read<LibraryProvider>().mediaHeaders,
                          placeholder: (_, __) => _ph(cs),
                          errorWidget: (_, __, ___) => _ph(cs),
                        )
                      : _ph(cs),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      if (numBooks != null)
                        Text(
                            l.librarySearchResultsBookCount(numBooks),
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ph(ColorScheme cs) {
    return Center(
      child: Icon(Icons.person_rounded,
          size: 22, color: cs.onSecondaryContainer.withValues(alpha: 0.5)),
    );
  }

  void _showAuthorBooks(
      BuildContext context, String authorId, String authorName) {
    showAuthorDetailSheet(context, authorId: authorId, authorName: authorName);
  }
}

class NarratorResultTile extends StatelessWidget {
  final String name;

  const NarratorResultTile({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showNarratorBooksSheet(context, narratorName: name),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.tertiaryContainer,
                  ),
                  child: Center(
                    child: Icon(Icons.mic_rounded,
                        size: 22,
                        color: cs.onTertiaryContainer.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
