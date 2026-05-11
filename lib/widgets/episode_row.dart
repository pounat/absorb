import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/download_service.dart';
import 'episode_detail_sheet.dart';

class EpisodeRow extends StatefulWidget {
  final Map<String, dynamic> episode;
  final Map<String, dynamic> podcastItem;
  final String itemId;
  final String podcastTitle;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const EpisodeRow({
    super.key,
    required this.episode,
    required this.podcastItem,
    required this.itemId,
    required this.podcastTitle,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  State<EpisodeRow> createState() => _EpisodeRowState();
}

class _EpisodeRowState extends State<EpisodeRow> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();
    final ep = widget.episode;

    final title = ep['title'] as String? ?? l.episodeRowEpisode;
    final episodeId = ep['id'] as String? ?? '';
    final duration = (ep['duration'] as num?)?.toDouble() ?? 0;
    final publishedAt = (ep['publishedAt'] as num?)?.toInt() ?? 0;
    final episodeNumber = ep['episode'] as String?;
    final season = ep['season'] as String?;

    // Progress
    final progress = lib.getEpisodeProgress(widget.itemId, episodeId);
    final progressData = lib.getEpisodeProgressData(widget.itemId, episodeId);
    final isFinished = progressData?['isFinished'] == true;

    // Download key for reactive lookups
    final dlKey = '${widget.itemId}-$episodeId';

    // Format publish date
    String dateLabel = '';
    if (publishedAt > 0) {
      final date = DateTime.fromMillisecondsSinceEpoch(publishedAt);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) {
        dateLabel = l.episodeRowToday;
      } else if (diff.inDays == 1) {
        dateLabel = l.episodeRowYesterday;
      } else if (diff.inDays < 7) {
        dateLabel = l.episodeRowDaysAgo(diff.inDays);
      } else if (diff.inDays < 30) {
        dateLabel = l.episodeRowWeeksAgo((diff.inDays / 7).floor());
      } else {
        dateLabel = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    }

    // Format duration
    String durationLabel = '';
    if (duration > 0) {
      final h = (duration / 3600).floor();
      final m = ((duration % 3600) / 60).floor();
      if (h > 0) {
        durationLabel = l.episodeRowDurationHm(h, m);
      } else {
        durationLabel = l.episodeRowDurationM(m);
      }
    }

    return InkWell(
      onTap: () {
        EpisodeDetailSheet.show(context, widget.podcastItem, ep);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Play/status indicator
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: isFinished
                      ? Icon(Icons.check_circle_rounded, size: 18, color: cs.primary.withValues(alpha: 0.6))
                      : progress > 0
                          ? SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2.5,
                                backgroundColor: cs.surfaceContainerHighest,
                                color: cs.primary,
                              ),
                            )
                          : Icon(Icons.circle_outlined, size: 18,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                ),
                const SizedBox(width: 12),

                // Title + metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isFinished
                              ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                              : cs.onSurface,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      if (episodeNumber != null || season != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (season != null) l.episodeRowSeasonShort(season),
                            if (episodeNumber != null) l.episodeRowEpisodeShort(episodeNumber),
                          ].join(' '),
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (dateLabel.isNotEmpty)
                            Flexible(
                              child: Text(dateLabel,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                              ),
                            ),
                          if (dateLabel.isNotEmpty && durationLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('·',
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                              ),
                            ),
                          if (durationLabel.isNotEmpty)
                            Flexible(
                              child: Text(durationLabel,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                              ),
                            ),
                          ListenableBuilder(
                            listenable: DownloadService(),
                            builder: (_, __) {
                              final downloaded = DownloadService().isDownloaded(dlKey);
                              if (!downloaded) return const SizedBox.shrink();
                              return Row(mainAxisSize: MainAxisSize.min, children: [
                                const SizedBox(width: 6),
                                Icon(Icons.download_done_rounded, size: 12, color: cs.primary.withValues(alpha: 0.6)),
                              ]);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Download button (reactive)
                    ListenableBuilder(
                      listenable: DownloadService(),
                      builder: (_, __) {
                        final dl = DownloadService();
                        final downloaded = dl.isDownloaded(dlKey);
                        final downloading = dl.isDownloading(dlKey);
                        final dlProgress = dl.downloadProgress(dlKey);

                        if (downloaded) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.download_done_rounded, size: 20,
                              color: (Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent : Colors.green.shade700).withValues(alpha: 0.7)),
                          );
                        }
                        if (downloading) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: SizedBox(width: 20, height: 20,
                              child: Stack(alignment: Alignment.center, children: [
                                CircularProgressIndicator(
                                  value: dlProgress > 0 ? dlProgress : null,
                                  strokeWidth: 2, color: cs.primary),
                                Text((dlProgress * 100).toStringAsFixed(0),
                                  style: TextStyle(fontSize: 7, color: cs.primary, fontWeight: FontWeight.w600)),
                              ])),
                          );
                        }
                        return IconButton(
                          onPressed: widget.onDownload,
                          icon: Icon(Icons.download_rounded, size: 20,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        );
                      },
                    ),

                    // Play button
                    IconButton(
                      onPressed: widget.onPlay,
                      icon: Icon(
                        progress > 0 && !isFinished
                            ? Icons.play_circle_filled_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 28,
                        color: cs.primary,
                      ),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}

class SelectableEpisodeRow extends StatelessWidget {
  final Map<String, dynamic> episode;
  final String itemId;

  const SelectableEpisodeRow({
    super.key,
    required this.episode,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();

    final title = episode['title'] as String? ?? l.episodeRowEpisode;
    final episodeId = episode['id'] as String? ?? '';
    final duration = (episode['duration'] as num?)?.toDouble() ?? 0;

    final progressData = lib.getEpisodeProgressData(itemId, episodeId);
    final isFinished = progressData?['isFinished'] == true;

    String durationLabel = '';
    if (duration > 0) {
      final h = (duration / 3600).floor();
      final m = ((duration % 3600) / 60).floor();
      durationLabel = h > 0 ? l.episodeRowDurationHm(h, m) : l.episodeRowDurationM(m);
    }

    return Row(children: [
      if (isFinished)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Icon(Icons.check_circle_rounded, size: 14, color: cs.primary.withValues(alpha: 0.6)),
        ),
      Expanded(
        child: Text(title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isFinished ? cs.onSurfaceVariant.withValues(alpha: 0.5) : cs.onSurface,
          ),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ),
      if (durationLabel.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(durationLabel,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
        ),
    ]);
  }
}
