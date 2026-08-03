import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/app_shell.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
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
  if (chapters.isEmpty) return;

  int currentIdx = -1;
  for (int i = 0; i < chapters.length; i++) {
    final ch = chapters[i] as Map<String, dynamic>;
    final start = (ch['start'] as num?)?.toDouble() ?? 0;
    final end = (ch['end'] as num?)?.toDouble() ?? 0;
    if (currentPosition >= start && currentPosition < end) { currentIdx = i; break; }
  }

  final cast = ChromecastService();

  showAdaptiveSheetDialog(
    context: context, useSafeArea: true,
    backgroundColor: Colors.transparent,
    widthClass: DialogWidthClass.action,
    initialChildSize: 0.6, minChildSize: 0.05, snap: true, maxChildSize: 0.9,
    builder: (ctx, sc) {
        if (currentIdx > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final target = currentIdx * 48.0 - 48;
            if (sc.hasClients) sc.jumpTo(target.clamp(0, sc.position.maxScrollExtent));
          });
        }
        final l = AppLocalizations.of(ctx)!;
        return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: accent.withValues(alpha: 0.2), width: 1)),
        ),
        child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
          Text(l.chaptersCount(chapters.length), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(child: ListView.builder(
            controller: sc, itemCount: chapters.length,
            itemBuilder: (_, i) {
              final ch = chapters[i] as Map<String, dynamic>;
              final chTitle = ch['title'] as String? ?? l.chapterNumber(i + 1);
              final start = (ch['start'] as num?)?.toDouble() ?? 0;
              final end = (ch['end'] as num?)?.toDouble() ?? 0;
              final pos = isCastingThis
                  ? cast.castPosition.inMilliseconds / 1000.0
                  : (player.currentItemId != null ? player.position.inMilliseconds / 1000.0 : 0.0);
              final isCurrent = isPlaybackActive && pos >= start && pos < end;
              final isFinished = isPlaybackActive && pos >= end;
              final pct = totalDuration > 0 ? (end / totalDuration * 100).round() : 0;
              final cs = Theme.of(context).colorScheme;
              return ListTile(
                dense: true, selected: isCurrent,
                selectedTileColor: accent.withValues(alpha: 0.1),
                leading: SizedBox(width: 28, child: isFinished
                  ? Icon(Icons.check_rounded, size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.4))
                  : Text('${i + 1}', textAlign: TextAlign.center,
                      style: tt.labelMedium?.copyWith(fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400, color: isCurrent ? accent : cs.onSurfaceVariant))),
                title: Text(chTitle,
                  style: tt.bodyMedium?.copyWith(fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrent ? cs.onSurface : isFinished ? cs.onSurface.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.7))),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$pct%', style: tt.labelSmall?.copyWith(
                    color: isCurrent ? accent.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.24), fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text(fmtDur((end - start) / displaySpeed), style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
                onTap: () async {
                  if (isPlaybackActive) {
                    // Active card - jump directly
                    final seekDur = Duration(seconds: start.round());
                    if (isCastingThis) {
                      cast.seekTo(seekDur);
                    } else {
                      player.seekTo(seekDur);
                    }
                    Navigator.pop(ctx);
                  } else if (itemId != null) {
                    // Inactive card - confirm then start playback
                    final confirmed = await showDialog<bool>(context: ctx, builder: (dlg) => AlertDialog(
                      title: Text(l.cardChaptersPlayFromChapterTitle),
                      content: Text(l.cardChaptersPlayFromChapterContent(chTitle)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dlg, false), child: Text(l.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(dlg, true), child: Text(l.cardChaptersPlay)),
                      ],
                    ));
                    if (confirmed != true || !ctx.mounted) return;
                    Navigator.pop(ctx); // Close chapter sheet first
                    final api = context.read<AuthProvider>().apiService;
                    if (api == null) return;
                    final lib = context.read<LibraryProvider>();
                    final fullItem = await api.getLibraryItem(itemId);
                    if (fullItem == null) return;
                    final media = fullItem['media'] as Map<String, dynamic>? ?? {};
                    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
                    final title = metadata['title'] as String? ?? '';
                    final author = metadata['authorName'] as String? ?? '';
                    final coverUrl = lib.getCoverUrl(itemId);
                    final dur = (media['duration'] is num) ? (media['duration'] as num).toDouble() : 0.0;
                    final chs = (media['chapters'] as List<dynamic>?) ?? [];
                    await player.playItem(
                      api: api, itemId: itemId,
                      title: title, author: author, coverUrl: coverUrl,
                      totalDuration: dur, chapters: chs,
                      startTime: start, forceStartTime: true,
                      libraryId: fullItem['libraryId'] as String?,
                    );
                    AppShell.goToAbsorbingGlobal();
                  }
                },
              );
            },
          )),
        ]),
      );
    },
  );
}
