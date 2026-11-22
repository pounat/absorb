import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/audio_player_service.dart';
import '../services/now_playing_layout.dart';
import 'overlay_toast.dart';

/// Settings > Media Controls > Now playing text: drag pieces onto the media
/// controls' top and second line, or off them. Saves as it goes.
class NowPlayingTextSheet extends StatefulWidget {
  final ScrollController? scrollController;

  const NowPlayingTextSheet({super.key, this.scrollController});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).bottomSheetTheme.backgroundColor ??
                        Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: NowPlayingTextSheet(scrollController: scrollController),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  State<NowPlayingTextSheet> createState() => _NowPlayingTextSheetState();
}

enum _Zone { top, second, unused }

/// One row of the list: a zone header or a piece.
class _Row {
  final _Zone? header;
  final NowPlayingPiece? piece;
  const _Row.header(_Zone zone) : header = zone, piece = null;
  const _Row.piece(NowPlayingPiece p) : header = null, piece = p;
}

class _NowPlayingTextSheetState extends State<NowPlayingTextSheet> {
  NowPlayingLayout _layout = NowPlayingLayout.standard;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    PlayerSettings.getNowPlayingLayout().then((json) {
      if (!mounted) return;
      setState(() {
        _layout = NowPlayingLayout.fromJson(json);
        _loaded = true;
      });
    });
  }

  List<_Row> get _rows => [
        const _Row.header(_Zone.top),
        for (final p in _layout.top) _Row.piece(p),
        const _Row.header(_Zone.second),
        for (final p in _layout.second) _Row.piece(p),
        const _Row.header(_Zone.unused),
        for (final p in _layout.unused) _Row.piece(p),
      ];

  void _save(NowPlayingLayout layout) {
    setState(() => _layout = layout);
    PlayerSettings.setNowPlayingLayout(layout.isStandard ? '' : layout.toJson());
  }

  void _onReorder(int oldIndex, int newIndex) {
    final rows = _rows;
    if (rows[oldIndex].piece == null) return;
    if (newIndex > oldIndex) newIndex--;
    final moved = rows.removeAt(oldIndex);
    // Nothing goes above the first header.
    rows.insert(newIndex.clamp(1, rows.length), moved);

    final top = <NowPlayingPiece>[];
    final second = <NowPlayingPiece>[];
    var zone = _Zone.top;
    for (final row in rows) {
      if (row.header != null) {
        zone = row.header!;
      } else if (zone == _Zone.top) {
        top.add(row.piece!);
      } else if (zone == _Zone.second) {
        second.add(row.piece!);
      }
    }
    if (top.isEmpty) {
      showOverlayToast(context, AppLocalizations.of(context)!.nowPlayingTopLineRequired,
          icon: Icons.info_outline_rounded);
      return;
    }
    _save(NowPlayingLayout(top: top, second: second));
  }

  String _pieceName(AppLocalizations l, NowPlayingPiece piece) => switch (piece) {
        NowPlayingPiece.chapter => l.nowPlayingPieceChapter,
        NowPlayingPiece.title => l.nowPlayingPieceTitle,
        NowPlayingPiece.author => l.author,
        NowPlayingPiece.narrator => l.nowPlayingPieceNarrator,
        NowPlayingPiece.series => l.nowPlayingPieceSeries,
        NowPlayingPiece.percent => l.nowPlayingPiecePercent,
        NowPlayingPiece.chapterNumber => l.nowPlayingPieceChapterNumber,
        NowPlayingPiece.timeLeft => l.nowPlayingPieceTimeLeft,
      };

  IconData _pieceIcon(NowPlayingPiece piece) => switch (piece) {
        NowPlayingPiece.chapter => Icons.bookmark_outline_rounded,
        NowPlayingPiece.title => Icons.menu_book_rounded,
        NowPlayingPiece.author => Icons.person_outline_rounded,
        NowPlayingPiece.narrator => Icons.record_voice_over_outlined,
        NowPlayingPiece.series => Icons.collections_bookmark_outlined,
        NowPlayingPiece.percent => Icons.percent_rounded,
        NowPlayingPiece.chapterNumber => Icons.format_list_numbered_rounded,
        NowPlayingPiece.timeLeft => Icons.timelapse_rounded,
      };

  String _zoneName(AppLocalizations l, _Zone zone) => switch (zone) {
        _Zone.top => l.nowPlayingTopLine,
        _Zone.second => l.nowPlayingSecondLine,
        _Zone.unused => l.nowPlayingNotShown,
      };

  /// The playing book in this layout, or the piece names with nothing playing.
  ({String title, String subtitle}) _preview(AppLocalizations l) {
    return AudioPlayerService().previewNowPlayingLines(_layout) ??
        _layout.build(NowPlayingValues(
          title: _pieceName(l, NowPlayingPiece.title),
          author: _pieceName(l, NowPlayingPiece.author),
          chapter: _pieceName(l, NowPlayingPiece.chapter),
          narrator: _pieceName(l, NowPlayingPiece.narrator),
          series: _pieceName(l, NowPlayingPiece.series),
          percent: _pieceName(l, NowPlayingPiece.percent),
          chapterNumber: _pieceName(l, NowPlayingPiece.chapterNumber),
          timeLeft: _pieceName(l, NowPlayingPiece.timeLeft),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final rows = _rows;
    final preview = _preview(l);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
        child: Row(children: [
          Expanded(child: Text(l.nowPlayingText, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          TextButton(
            onPressed: !_loaded || _layout.isStandard ? null : () => _save(NowPlayingLayout.standard),
            child: Text(l.resetToDefault),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.headphones_rounded, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(preview.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (preview.subtitle.isNotEmpty)
                  Text(preview.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ),
          ]),
        ),
      ),
      Expanded(
        child: !_loaded
            ? const SizedBox.shrink()
            : ReorderableListView.builder(
                scrollController: widget.scrollController,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.only(bottom: 24),
                onReorderStart: (_) => HapticFeedback.mediumImpact(),
                proxyDecorator: (child, index, animation) => Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surfaceContainer,
                  child: child,
                ),
                itemCount: rows.length,
                onReorder: _onReorder,
                itemBuilder: (context, i) {
                  final row = rows[i];
                  if (row.header != null) {
                    return Padding(
                      key: ValueKey('header-${row.header!.name}'),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Text(_zoneName(l, row.header!),
                          style: tt.labelLarge?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                    );
                  }
                  final piece = row.piece!;
                  final shown = _layout.uses(piece);
                  return Padding(
                    key: ValueKey(piece.name),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: shown ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(_pieceIcon(piece), size: 20, color: cs.onSurface.withValues(alpha: 0.7)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_pieceName(l, piece), style: tt.bodyMedium)),
                        ReorderableDragStartListener(
                          index: i,
                          child: Icon(Icons.drag_handle_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}
