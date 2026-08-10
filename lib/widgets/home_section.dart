import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cover_badges.dart';
import '../providers/library_provider.dart';
import '../services/download_service.dart';
import 'absorbing_shared.dart';
import 'book_card.dart';
import 'author_card.dart';
import 'hover_cover_actions.dart';
import 'series_card.dart';
import 'episode_list_sheet.dart';
import '../utils/desktop_workspace.dart';
import '../utils/app_platform.dart';
import '../utils/media_card_gesture_policy.dart';

class HomeSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<dynamic> entities;
  final String sectionType;
  final String sectionId;
  final VoidCallback? onTitleTap;
  final double coverAspectRatio;

  const HomeSection({
    super.key,
    required this.title,
    required this.icon,
    required this.entities,
    required this.sectionType,
    required this.sectionId,
    this.onTitleTap,
    this.coverAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isContinueListening = sectionId == 'continue-listening';
    final isPlaylistSection = sectionType == 'playlist';
    final isCollectionSection = sectionType == 'collection';
    final isAuthorSection = sectionType == 'author' || sectionType == 'authors';
    final isSeriesSection = sectionType == 'series';
    final isEpisodeSection = sectionType == 'episode';
    final sourcePlaylistId = isPlaylistSection
        ? _sourceIdFromSectionId('playlist')
        : null;
    final sourceCollectionId = isCollectionSection
        ? _sourceIdFromSectionId('collection')
        : null;
    final sourceCollectionName = sourceCollectionId == null
        ? null
        : _collectionNameFromTitle(title);

    // Check if any entities have recentEpisode (podcast episode sections)
    final hasEpisodeEntities = !isEpisodeSection && entities.isNotEmpty &&
        entities.first is Map<String, dynamic> &&
        (entities.first as Map<String, dynamic>)['recentEpisode'] != null;
    final effectiveEpisode = isEpisodeSection || hasEpisodeEntities;

    final bool isRectCover = coverAspectRatio < 1.0;
    final desktop = isDesktopWorkspace(context);
    final scale = desktop ? 1.2 : 1.0;
    final double cardWidth =
        (isContinueListening ? 300 : (isAuthorSection ? 120 : 140)) * scale;
    final double cardHeight =
        (isContinueListening ? 120 : effectiveEpisode ? 200 : (isAuthorSection ? 170 : (isRectCover ? 260 : 200))) * scale;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          GestureDetector(
            onTap: onTitleTap,
            behavior: onTitleTap != null ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: cs.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.8),
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (onTitleTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 0.5,
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Snap-scrolling horizontal list
          SizedBox(
            height: cardHeight,
            child: SnapScrollList(
              cardWidth: cardWidth,
              desktop: desktop,
              itemCount: entities.length,
              itemBuilder: (context, index) {
                var entity = entities[index];
                String? sourcePlaylistEpisodeId;

                // Playlist items nest actual item under 'libraryItem'
                if (isPlaylistSection && entity is Map<String, dynamic>) {
                  final inner = entity['libraryItem'] as Map<String, dynamic>?;
                  if (inner != null) {
                    final episodeId = entity['episodeId'] as String?;
                    sourcePlaylistEpisodeId = episodeId;
                    final episode = entity['episode'] as Map<String, dynamic>?;
                    entity = Map<String, dynamic>.from(inner);
                    if (episodeId != null && episode != null) {
                      entity['recentEpisode'] = episode;
                    }
                  }
                }

                if (isAuthorSection) {
                  return SizedBox(
                    width: cardWidth,
                    child: AuthorCard(author: entity),
                  );
                }

                if (isSeriesSection) {
                  return SizedBox(
                    width: cardWidth,
                    child: SeriesCard(series: entity, coverAspectRatio: coverAspectRatio),
                  );
                }

                // Podcast episode sections - show cover with episode title overlay
                if (isEpisodeSection && entity is Map<String, dynamic>) {
                  return SizedBox(
                    width: cardWidth,
                    child: _EpisodeCard(
                      item: entity,
                      sourcePlaylistId: sourcePlaylistId,
                    ),
                  );
                }

                // If entity has recentEpisode (podcast continue-listening etc),
                // use episode card even if section type isn't explicitly 'episode'
                if (entity is Map<String, dynamic> &&
                    entity['recentEpisode'] != null) {
                  return SizedBox(
                    width: cardWidth,
                    child: _EpisodeCard(
                      item: entity,
                      sourcePlaylistId: sourcePlaylistId,
                    ),
                  );
                }

                return SizedBox(
                  width: cardWidth,
                  child: BookCard(
                    item: entity,
                    showProgress: isContinueListening,
                    isWide: isContinueListening,
                    coverAspectRatio: isContinueListening ? 1.0 : coverAspectRatio,
                    sourcePlaylistId: sourcePlaylistId,
                    sourcePlaylistEpisodeId: sourcePlaylistEpisodeId,
                    sourceCollectionId: sourceCollectionId,
                    sourceCollectionName: sourceCollectionName,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _sourceIdFromSectionId(String type) {
    final prefix = '$type:';
    if (!sectionId.startsWith(prefix)) return null;
    final id = sectionId.substring(prefix.length);
    return id.isEmpty ? null : id;
  }

  String _collectionNameFromTitle(String value) {
    const prefix = 'Server Collection - ';
    return value.startsWith(prefix) ? value.substring(prefix.length) : value;
  }
}

/// A horizontal scrolling list with smooth snap-to-card behavior. On the
/// desktop workspace it adds hover paging arrows and clamping physics.
class SnapScrollList extends StatefulWidget {
  final double cardWidth;
  final bool desktop;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const SnapScrollList({
    super.key,
    required this.cardWidth,
    this.desktop = false,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<SnapScrollList> createState() => SnapScrollListState();
}

class SnapScrollListState extends State<SnapScrollList> {
  late final ScrollController _controller;
  bool _hovering = false;
  bool _canPageBack = false;
  bool _canPageForward = false;

  double get _itemExtent => widget.cardWidth + 12;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_updateArrows);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!widget.desktop || !_controller.hasClients) return;
    final canBack = _controller.offset > 1;
    final canForward =
        _controller.offset < _controller.position.maxScrollExtent - 1;
    if (canBack != _canPageBack || canForward != _canPageForward) {
      setState(() {
        _canPageBack = canBack;
        _canPageForward = canForward;
      });
    }
  }

  void _page(int direction) {
    if (!_controller.hasClients) return;
    final viewport = _controller.position.viewportDimension;
    final cardsPerPage = (viewport ~/ _itemExtent).clamp(1, 50);
    final step = cardsPerPage * _itemExtent;
    final raw = _controller.offset + direction * step;
    final maxExtent = _controller.position.maxScrollExtent;
    var target = ((raw / _itemExtent).round() * _itemExtent)
        .clamp(0.0, maxExtent);
    if (target > maxExtent - _itemExtent) {
      target = direction > 0 ? maxExtent : target;
    }
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _arrow({required bool forward}) {
    final cs = Theme.of(context).colorScheme;
    final visible =
        _hovering && (forward ? _canPageForward : _canPageBack);
    return Positioned(
      left: forward ? null : 4,
      right: forward ? 4 : null,
      top: 0,
      bottom: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: IgnorePointer(
            ignoring: !visible,
            child: Material(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _page(forward ? 1 : -1),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    forward
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 24,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemExtent = _itemExtent;

    final list = NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        final maxExtent = _controller.position.maxScrollExtent;
        final offset = _controller.offset;
        double targetOffset;
        if (maxExtent < itemExtent) {
          // Short list that barely overflows: snapping to an item boundary would
          // force the far end and cut off the first card. Rest at whichever end
          // is closer so the first or last card stays fully visible.
          targetOffset = offset < maxExtent / 2 ? 0.0 : maxExtent;
        } else {
          final targetIndex = (offset / itemExtent).round();
          targetOffset = (targetIndex * itemExtent).toDouble();
          // The last card can't left-align (no content after it), so snapping in
          // the final stretch leaves it cut off the right edge. Rest at the true
          // end instead so the last card stays fully visible.
          if (targetOffset > maxExtent - itemExtent) targetOffset = maxExtent;
          targetOffset = targetOffset.clamp(0.0, maxExtent);
        }
        if ((offset - targetOffset).abs() > 1) {
          Future.microtask(() {
            if (_controller.hasClients) {
              _controller.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              );
            }
          });
        }
        return false;
      },
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: widget.desktop
            ? const ClampingScrollPhysics()
            : const BouncingScrollPhysics(),
        itemCount: widget.itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: widget.itemBuilder,
      ),
    );

    if (!widget.desktop) return list;
    // Arrow visibility depends on maxScrollExtent, which only exists after
    // the first layout; refresh once attached.
    if (!_controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
    }
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
        _updateArrows();
      },
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        children: [
          list,
          _arrow(forward: false),
          _arrow(forward: true),
        ],
      ),
    );
  }
}

/// Card for episodes in podcast sections (e.g. episodes-recently-added).
/// Shows the show cover with the episode title overlaid at the bottom.
class _EpisodeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? sourcePlaylistId;

  const _EpisodeCard({
    required this.item,
    this.sourcePlaylistId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lib = context.watch<LibraryProvider>();
    final gesturePolicy = MediaCardGesturePolicy(isWeb: AppPlatform.isWeb);

    final itemId = item['id'] as String? ?? '';
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final showTitle = metadata['title'] as String? ?? '';
    final coverUrl = lib.getCoverUrl(itemId);
    final isSubscribed = lib.isPodcastSubscribed(itemId);

    // Get episode info from recentEpisode
    final episode = item['recentEpisode'] as Map<String, dynamic>?;
    final episodeTitle = episode?['title'] as String? ?? showTitle;
    final episodeId = episode?['id'] as String?;
    final progress = episodeId != null ? lib.getEpisodeProgress(itemId, episodeId) : 0.0;
    final isFinished = episodeId != null && lib.getEpisodeProgressData(itemId, episodeId)?['isFinished'] == true;
    final isDownloaded = episodeId != null && DownloadService().isDownloaded('$itemId-$episodeId');

    return HoverCoverActions(
      onMenu: episode == null
          ? null
          : () => EpisodeDetailSheet.showQuick(
                context,
                item,
                episode,
                sourcePlaylistId: sourcePlaylistId,
              ),
      child: GestureDetector(
      onTap: () {
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
          );
        }
      },
      // Long-press an episode card for its quick-actions sheet (shows stay as-is).
      onLongPress: episode == null || !gesturePolicy.allowsLongPressShortcuts ? null
          : () => EpisodeDetailSheet.showQuick(
                context,
                item,
                episode,
                sourcePlaylistId: sourcePlaylistId,
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Square cover
          AspectRatio(
            aspectRatio: 1,
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
                  if (coverUrl != null)
                    coverUrl.startsWith('/')
                        ? BlurPaddedCover(
                            blurChild: Image.file(File(coverUrl), fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                            child: Image.file(File(coverUrl), fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  color: cs.surfaceContainerHigh,
                                  child: Icon(Icons.podcasts_rounded, size: 32,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.3)))))
                        : BlurPaddedCover(
                            blurChild: Image.network(coverUrl, fit: BoxFit.cover,
                                headers: lib.mediaHeaders,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                            child: Image.network(coverUrl, fit: BoxFit.contain,
                                headers: lib.mediaHeaders,
                                errorBuilder: (_, __, ___) => Container(
                                  color: cs.surfaceContainerHigh,
                                  child: Icon(Icons.podcasts_rounded, size: 32,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.3)))))
                  else
                    Container(
                      color: cs.surfaceContainerHigh,
                      child: Icon(Icons.podcasts_rounded, size: 32,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                  // Progress bar
                  if (progress > 0 && !isFinished)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 3,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(cs.primary),
                        ),
                      ),
                    ),
                  // Finished / downloaded badge
                  if (isFinished || isDownloaded)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: CoverStateBadges(
                        isDownloaded: isDownloaded,
                        isFinished: isFinished,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Episode title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              episodeTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          // Show name
          if (showTitle.isNotEmpty && episode != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                showTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
