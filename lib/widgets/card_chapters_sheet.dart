import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/app_shell.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../services/sponsor_skip_service.dart';
import 'absorbing_shared.dart';
import 'adaptive_modal.dart';

void showChaptersSheet({
  required BuildContext context,
  required Color accent,
  required TextTheme tt,
  required List<dynamic> chapters,
  required double totalDuration,
  required double currentPosition,
  required bool isPlaybackActive,
  required bool isCastingThis,
  required double displaySpeed,
  required AudioPlayerService player,
  String? itemId,
}) {
  if (chapters.isEmpty && player.currentEpisodeId == null) return;

  int currentIdx = -1;
  for (int i = 0; i < chapters.length; i++) {
    final ch = chapters[i] as Map<String, dynamic>;
    final start = (ch['start'] as num?)?.toDouble() ?? 0;
    final end = (ch['end'] as num?)?.toDouble() ?? 0;
    if (currentPosition >= start && currentPosition < end) {
      currentIdx = i;
      break;
    }
  }

  showAdaptiveSheetDialog(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    widthClass: DialogWidthClass.action,
    initialChildSize: 0.6,
    minChildSize: 0.05,
    snap: true,
    maxChildSize: 0.9,
    builder: (ctx, sc) {
      if (currentIdx > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = currentIdx * 48.0 - 48;
          if (sc.hasClients)
            sc.jumpTo(target.clamp(0, sc.position.maxScrollExtent));
        });
      }
      final l = AppLocalizations.of(ctx)!;
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: accent.withValues(alpha: 0.2), width: 1),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              chapters.isNotEmpty
                  ? l.chaptersCount(chapters.length)
                  : l.podcastSponsorBlockSheetTitle,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (isPlaybackActive && player.currentEpisodeId != null)
              _SponsorBlockStatusBar(player: player, accent: accent),
            const SizedBox(height: 8),
            Expanded(
              child: chapters.isNotEmpty
                  ? CardChaptersList(
                      accent: accent,
                      chapters: chapters,
                      totalDuration: totalDuration,
                      currentPosition: currentPosition,
                      isPlaybackActive: isPlaybackActive,
                      isCastingThis: isCastingThis,
                      displaySpeed: displaySpeed,
                      player: player,
                      itemId: itemId,
                      scrollController: sc,
                      closeOnSelection: true,
                    )
                  : _SponsorSegmentsOnlyList(
                      player: player,
                      accent: accent,
                      scrollController: sc,
                    ),
            ),
          ],
        ),
      );
    },
  );
}

/// Chapter list shared by the card chapter sheet and embedded player panels.
///
/// Set [closeOnSelection] to false when the list is embedded in a persistent
/// desktop panel. Chapter taps will still seek or start playback without
/// closing the surrounding route.
class CardChaptersList extends StatelessWidget {
  final Color accent;
  final List<dynamic> chapters;
  final double totalDuration;
  final double currentPosition;
  final bool isPlaybackActive;
  final bool isCastingThis;
  final double displaySpeed;
  final AudioPlayerService player;
  final String? itemId;
  final ScrollController? scrollController;
  final bool closeOnSelection;

  const CardChaptersList({
    super.key,
    required this.accent,
    required this.chapters,
    required this.totalDuration,
    required this.currentPosition,
    required this.isPlaybackActive,
    required this.isCastingThis,
    required this.displaySpeed,
    required this.player,
    this.itemId,
    this.scrollController,
    this.closeOnSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    final cast = ChromecastService();
    final Stream<Duration>? positionStream = isCastingThis
        ? cast.castPositionStream
        : isPlaybackActive
        ? player.absolutePositionStream
        : null;

    return StreamBuilder<Duration>(
      stream: positionStream,
      initialData: Duration(milliseconds: (currentPosition * 1000).round()),
      builder: (context, snapshot) {
        final position = isCastingThis
            ? cast.castPosition.inMilliseconds / 1000.0
            : isPlaybackActive
            ? (snapshot.data ?? player.position).inMilliseconds / 1000.0
            : currentPosition;
        final tt = Theme.of(context).textTheme;
        final cs = Theme.of(context).colorScheme;
        final l = AppLocalizations.of(context)!;

        return ListView.builder(
          controller: scrollController,
          itemCount: chapters.length,
          itemBuilder: (_, i) {
            final chapter = chapters[i] as Map<String, dynamic>;
            final chapterTitle =
                chapter['title'] as String? ?? l.chapterNumber(i + 1);
            final start = (chapter['start'] as num?)?.toDouble() ?? 0;
            final end = (chapter['end'] as num?)?.toDouble() ?? 0;
            final isCurrent =
                isPlaybackActive && position >= start && position < end;
            final isFinished = isPlaybackActive && position >= end;
            final percent = totalDuration > 0
                ? (end / totalDuration * 100).round()
                : 0;
            final isSponsorSegment =
                isPlaybackActive &&
                end > start &&
                SponsorSkipService.findSegmentAt(
                      player.sponsorSegments,
                      start + (end - start) * 0.5,
                    ) !=
                    null;

            return ListTile(
              dense: true,
              selected: isCurrent,
              selectedTileColor: accent.withValues(alpha: 0.1),
              leading: SizedBox(
                width: 28,
                child: isFinished
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      )
                    : Text(
                        '${i + 1}',
                        textAlign: TextAlign.center,
                        style: tt.labelMedium?.copyWith(
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isCurrent ? accent : cs.onSurfaceVariant,
                        ),
                      ),
              ),
              title: Text(
                chapterTitle,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent
                      ? cs.onSurface
                      : isFinished
                      ? cs.onSurface.withValues(alpha: 0.4)
                      : cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSponsorSegment) ...[
                    Icon(
                      Icons.fast_forward_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '$percent%',
                    style: tt.labelSmall?.copyWith(
                      color: isCurrent
                          ? accent.withValues(alpha: 0.7)
                          : cs.onSurface.withValues(alpha: 0.24),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fmtDur((end - start) / displaySpeed),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              onTap: () => _selectChapter(
                context,
                chapterTitle: chapterTitle,
                start: start,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectChapter(
    BuildContext context, {
    required String chapterTitle,
    required double start,
  }) async {
    final seekPosition = Duration(seconds: start.round());
    if (isPlaybackActive) {
      if (isCastingThis) {
        ChromecastService().seekTo(seekPosition);
      } else {
        player.seekTo(seekPosition);
      }
      if (closeOnSelection && context.mounted) Navigator.pop(context);
      return;
    }

    if (itemId == null) return;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.cardChaptersPlayFromChapterTitle),
        content: Text(l.cardChaptersPlayFromChapterContent(chapterTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.cardChaptersPlay),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    if (closeOnSelection) Navigator.pop(context);
    final api = auth.apiService;
    if (api == null) return;

    final fullItem = await api.getLibraryItem(itemId!);
    if (fullItem == null) return;
    final media = fullItem['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? '';
    final author = metadata['authorName'] as String? ?? '';
    final coverUrl = lib.getCoverUrl(itemId!);
    final duration = (media['duration'] is num)
        ? (media['duration'] as num).toDouble()
        : 0.0;
    final resolvedChapters = (media['chapters'] as List<dynamic>?) ?? [];
    await player.playItem(
      api: api,
      itemId: itemId!,
      title: title,
      author: author,
      coverUrl: coverUrl,
      totalDuration: duration,
      chapters: resolvedChapters,
      startTime: start,
      forceStartTime: true,
      libraryId: fullItem['libraryId'] as String?,
    );
    AppShell.goToAbsorbingGlobal();
  }
}

class _SponsorBlockStatusBar extends StatelessWidget {
  final AudioPlayerService player;
  final Color accent;

  const _SponsorBlockStatusBar({
    required this.player,
    required this.accent,
  });

  Future<void> _showLinkDialog(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(
      text: player.currentEpisodeYouTubeId ?? '',
    );
    String? errorText;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.podcastSponsorBlockLinkTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.podcastSponsorBlockLinkBody),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.podcastSponsorBlockLinkHint,
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            if (player.currentEpisodeYouTubeId != null)
              TextButton(
                onPressed: () async {
                  await player.setManualYouTubeVideoId(null);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(l.clear),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await player.setManualYouTubeVideoId(ctrl.text);
                if (!ok) {
                  setState(() {
                    errorText = l.podcastSponsorBlockInvalidId;
                  });
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final ytId = player.currentEpisodeYouTubeId;
        final segCount = player.sponsorSegments.length;
        final statusText = !player.isSponsorSkipEnabled
            ? l.podcastSponsorBlockDisabledForShow
            : ytId != null
                ? l.podcastSponsorBlockLinkedStatus(ytId, segCount)
                : l.podcastSponsorBlockNotLinkedStatus(segCount);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  ytId != null
                      ? Icons.fast_forward_rounded
                      : Icons.link_off_rounded,
                  size: 16,
                  color: ytId != null ? accent : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () => _showLinkDialog(context),
                  child: Text(
                    ytId != null
                        ? l.podcastSponsorBlockChangeButton
                        : l.podcastSponsorBlockLinkButton,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SponsorSegmentsOnlyList extends StatelessWidget {
  final AudioPlayerService player;
  final Color accent;
  final ScrollController scrollController;

  const _SponsorSegmentsOnlyList({
    required this.player,
    required this.accent,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final segs = player.sponsorSegments;
        if (segs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.podcastSponsorBlockEmptyHint,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          );
        }
        return ListView.builder(
          controller: scrollController,
          itemCount: segs.length,
          itemBuilder: (_, i) {
            final seg = segs[i];
            return ListTile(
              dense: true,
              leading: Icon(Icons.fast_forward_rounded, size: 18, color: accent),
              title: Text(seg.label, style: tt.bodyMedium),
              trailing: Text(
                '${fmtDur(seg.start)} → ${fmtDur(seg.end)}',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              onTap: () => player.seekTo(
                Duration(milliseconds: (seg.end * 1000).round()),
                logDetail: 'Skip segment ${seg.label}',
              ),
            );
          },
        );
      },
    );
  }
}
