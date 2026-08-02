import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import 'cover_badges.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'absorbing_shared.dart';
import 'book_detail_sheet.dart';
import 'episode_list_sheet.dart';

class BookCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool showProgress;
  final bool isWide;
  final double coverAspectRatio;
  final String? sourcePlaylistId;
  final String? sourcePlaylistEpisodeId;
  final String? sourceCollectionId;
  final String? sourceCollectionName;

  const BookCard({
    super.key,
    required this.item,
    this.showProgress = false,
    this.isWide = false,
    this.coverAspectRatio = 1.0,
    this.sourcePlaylistId,
    this.sourcePlaylistEpisodeId,
    this.sourceCollectionId,
    this.sourceCollectionName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();

    final itemId = item['id'] as String?;
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};

    final title = metadata['title'] as String? ?? l.bookCardUnknownTitle;
    final authorName = metadata['authorName'] as String? ?? '';
    final coverUrl = lib.getCoverUrl(itemId);

    // Progress from LibraryProvider (fetched via /api/me, same source as book detail)
    final progress = lib.getProgress(itemId);
    final isFinished = lib.getProgressData(itemId)?['isFinished'] == true;
    final isExplicit = PlayerSettings.showExplicitBadge && metadata['explicit'] == true;
    final isDownloaded = DownloadService().isDownloaded(itemId ?? '');
    // Only compute for podcast shows that aren't being rendered as an episode
    // (an episode card shows the recentEpisode payload, not show-level info).
    final unfinishedCount = (lib.isPodcastLibrary && item['recentEpisode'] == null)
        ? lib.getUnfinishedEpisodeCount(item)
        : 0;

    final headers = lib.mediaHeaders;

    if (isWide) {
      return _buildWideCard(context, cs, tt, l, title, authorName, coverUrl, progress, headers, isExplicit: isExplicit);
    }
    return _buildCompactCard(context, cs, tt, l, title, authorName, coverUrl, progress, headers, isFinished: isFinished, isDownloaded: isDownloaded, isExplicit: isExplicit, unfinishedCount: unfinishedCount);
  }

  void _navigateToDetail(BuildContext context) {
    final itemId = item['id'] as String?;
    if (itemId == null) return;
    final lib = context.read<LibraryProvider>();
    if (lib.isPodcastLibrary) {
      final episode = item['recentEpisode'] as Map<String, dynamic>?;
      if (episode != null) {
        EpisodeDetailSheet.show(
          context,
          item,
          episode,
          sourcePlaylistId: sourcePlaylistId,
        );
      } else {
        EpisodeListSheet.show(
          context,
          item,
          sourcePlaylistId: sourcePlaylistId,
          sourcePlaylistEpisodeId: sourcePlaylistEpisodeId,
        );
      }
    } else {
      showBookDetailSheet(
        context,
        itemId,
        sourcePlaylistId: sourcePlaylistId,
        sourceCollectionId: sourceCollectionId,
        sourceCollectionName: sourceCollectionName,
      );
    }
  }

  /// Long-press shortcut to the quick-actions sheet (podcasts skipped — they
  /// keep the normal open-details behaviour).
  void _onLongPress(BuildContext context) {
    final itemId = item['id'] as String?;
    if (itemId == null) return;
    if (context.read<LibraryProvider>().isPodcastLibrary) {
      // Episode card -> episode quick sheet; show cover -> keep current behaviour.
      final episode = item['recentEpisode'] as Map<String, dynamic>?;
      if (episode != null) {
        EpisodeDetailSheet.showQuick(
          context,
          item,
          episode,
          sourcePlaylistId: sourcePlaylistId,
        );
      } else {
        _navigateToDetail(context);
      }
      return;
    }
    showQuickActionsSheet(
      context,
      itemId,
      initialItem: item,
      sourcePlaylistId: sourcePlaylistId,
      sourceCollectionId: sourceCollectionId,
      sourceCollectionName: sourceCollectionName,
    );
  }

  /// Wide "continue listening" card with square cover + text side-by-side.
  /// Uses IntrinsicHeight so the row sizes to the square cover without overflow.
  Widget _buildWideCard(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    AppLocalizations l,
    String title,
    String authorName,
    String? coverUrl,
    double progress,
    Map<String, String> headers, {
    bool isExplicit = false,
  }) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        onLongPress: () => _onLongPress(context),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Square cover with download badge
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  _CoverImage(coverUrl: coverUrl, cs: cs, fit: BoxFit.contain, httpHeaders: headers),
                  if (isExplicit)
                    Positioned(
                      top: 4, right: DownloadService().isDownloaded(item['id'] as String? ?? '') ? 30 : 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(l.bookCardExplicitBadge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  if (DownloadService().isDownloaded(item['id'] as String? ?? ''))
                    const Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: CoverStateBadges(isDownloaded: true, isFinished: false),
                    ),
                ],
              ),
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (authorName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (showProgress) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0, 1),
                                minHeight: 5,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(cs.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).round()}%',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact vertical card with a square cover on top and text below.
  Widget _buildCompactCard(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    AppLocalizations l,
    String title,
    String authorName,
    String? coverUrl,
    double progress,
    Map<String, String> headers, {
    bool isFinished = false,
    bool isDownloaded = false,
    bool isExplicit = false,
    int unfinishedCount = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cover
        AspectRatio(
          aspectRatio: coverAspectRatio,
          child: _PressableCard(
            onTap: () => _navigateToDetail(context),
            onLongPress: () => _onLongPress(context),
            borderRadius: 12,
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: cs.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverImage(coverUrl: coverUrl, cs: cs, httpHeaders: headers, coverAspectRatio: coverAspectRatio),
                  if (progress > 0 && !isFinished)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 3,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(cs.primary),
                        ),
                      ),
                    ),
                  if (isExplicit)
                    Positioned(
                      top: unfinishedCount > 0 ? 26 : 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(l.bookCardExplicitBadge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  if (unfinishedCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unfinishedCount',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (isFinished || isDownloaded)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: CoverStateBadges(
                        isDownloaded: isDownloaded,
                        isFinished: isFinished,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            title,
            maxLines: coverAspectRatio < 1.0 ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
        if (authorName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Reusable cover image with placeholder.
class _CoverImage extends StatelessWidget {
  final String? coverUrl;
  final ColorScheme cs;
  final BoxFit fit;
  final Map<String, String> httpHeaders;
  final double coverAspectRatio;

  const _CoverImage({required this.coverUrl, required this.cs, this.fit = BoxFit.cover, this.httpHeaders = const {}, this.coverAspectRatio = 1.0});

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return _placeholder();
    }

    final isSquare = (coverAspectRatio - 1.0).abs() < 0.01;
    final effectiveFit = isSquare ? BoxFit.contain : fit;

    // Local file path (offline cached cover)
    if (coverUrl!.startsWith('/')) {
      final file = File(coverUrl!);
      if (file.existsSync()) {
        return BlurPaddedCover(
          enabled: isSquare,
          blurChild: Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          child: Image.file(file, fit: effectiveFit, errorBuilder: (_, __, ___) => _placeholder()),
        );
      }
      return _placeholder();
    }

    return BlurPaddedCover(
      enabled: isSquare,
      blurChild: CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        httpHeaders: httpHeaders,
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      ),
      child: CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: effectiveFit,
        httpHeaders: httpHeaders,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.headphones_rounded,
          size: 32,
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// Pressable wrapper that scales down slightly on tap for tactile feedback.
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;

  const _PressableCard({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.borderRadius = 12,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _controller.reverse();
              widget.onLongPress!();
            },
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
