import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'book_detail_sheet.dart';
import 'episode_detail_sheet.dart';
import 'overlay_toast.dart';
import 'stackable_sheet.dart';

/// Open the right detail sheet for a section entity: episode detail for
/// podcast entries (which carry a `recentEpisode`), book detail otherwise.
/// Falls back to book detail if a podcast entry is missing its episode payload.
void _openEntityDetail(BuildContext context, Map<String, dynamic> item) {
  final recentEpisode = item['recentEpisode'] as Map<String, dynamic>?;
  if (recentEpisode != null) {
    EpisodeDetailSheet.show(context, item, recentEpisode);
    return;
  }
  final itemId = item['id'] as String? ?? '';
  if (itemId.isEmpty) return;
  showBookDetailSheet(context, itemId);
}

/// Generic detail sheet for any home screen section (Continue Listening,
/// Recently Added, Downloads, etc.). Shows items in a list or 3-column grid
/// with progress bars, saved/done badges, and explicit badges.
class SectionDetailSheet extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<dynamic> entities;
  final double coverAspectRatio;
  final ScrollController? scrollController;

  const SectionDetailSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.entities,
    this.coverAspectRatio = 1.0,
    this.scrollController,
  });

  static void show(BuildContext context, {
    required String title,
    required IconData icon,
    required List<dynamic> entities,
    double coverAspectRatio = 1.0,
  }) {
    showStackableSheet(
      context: context,
      useSafeArea: true,
      showHandle: true,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SectionDetailSheet(
        title: title,
        icon: icon,
        entities: entities,
        coverAspectRatio: coverAspectRatio,
        scrollController: scrollController,
      ),
    );
  }

  @override
  State<SectionDetailSheet> createState() => _SectionDetailSheetState();
}

class _SectionDetailSheetState extends State<SectionDetailSheet> {
  bool _gridView = false;

  @override
  void initState() {
    super.initState();
    PlayerSettings.getSectionGridView().then((v) {
      if (mounted && v != _gridView) setState(() => _gridView = v);
    });
  }

  void _toggleGridView() {
    setState(() => _gridView = !_gridView);
    PlayerSettings.setSectionGridView(_gridView);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lib = context.watch<LibraryProvider>();
    final l = AppLocalizations.of(context)!;

    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          Icon(widget.icon, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text('${widget.entities.length}',
            style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _toggleGridView,
            child: Icon(
              _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              size: 20, color: cs.onSurfaceVariant,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Expanded(
        child: _gridView
            ? _buildGrid(cs, tt, lib, l)
            : _buildList(cs, tt, lib, l),
      ),
    ]);
  }

  Widget _buildList(ColorScheme cs, TextTheme tt, LibraryProvider lib, AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doneColor = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          .copyWith(bottom: 40),
      itemCount: widget.entities.length,
      itemBuilder: (context, index) {
        final item = widget.entities[index] as Map<String, dynamic>;
        final itemId = item['id'] as String? ?? '';
        final media = item['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? l.unknown;
        final author = metadata['authorName'] as String? ?? '';
        final coverUrl = lib.getCoverUrl(itemId);
        final isExplicit = PlayerSettings.showExplicitBadge &&
            metadata['explicit'] == true;
        final progress = lib.getProgress(itemId);
        final isFinished =
            lib.getProgressData(itemId)?['isFinished'] == true;
        final isDownloaded = DownloadService().isDownloaded(itemId);
        final isOnAbsorbing = lib.isOnAbsorbingList(itemId);

        final card = Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 0,
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openEntityDetail(context, item),
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 112,
                child: Row(children: [
                  AspectRatio(
                    aspectRatio: widget.coverAspectRatio,
                    child: Stack(children: [
                      Positioned.fill(child: _cover(coverUrl, lib, cs)),
                      if (isExplicit) _explicitBadge(l),
                      if (progress > 0 && !isFinished) _progressBar(cs, progress),
                      if (isFinished || isDownloaded)
                        _badges(cs, doneColor, isFinished, isDownloaded, l),
                    ]),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                          const SizedBox(height: 4),
                          Text(author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );

        return Dismissible(
          key: ValueKey('absorb-$itemId'),
          direction: isOnAbsorbing
              ? DismissDirection.none
              : DismissDirection.startToEnd,
          confirmDismiss: (_) async {
            await lib.addToAbsorbingQueue(itemId);
            lib.absorbingItemCache[itemId] = Map<String, dynamic>.from(item);
            HapticFeedback.mediumImpact();
            if (context.mounted) {
              showOverlayToast(context, l.sectionDetailAddedToAbsorbing(title),
                  icon: Icons.add_circle_outline_rounded);
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.add_circle_outline_rounded, color: cs.primary),
          ),
          child: card,
        );
      },
    );
  }

  Widget _buildGrid(ColorScheme cs, TextTheme tt, LibraryProvider lib, AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doneColor = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;
    final isRect = widget.coverAspectRatio < 1.0;
    // Text area is ~50px; cover uses aspect ratio to determine height
    final childAspectRatio = isRect ? 0.45 : 0.62;

    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          .copyWith(bottom: 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: widget.entities.length,
      itemBuilder: (context, index) {
        final item = widget.entities[index] as Map<String, dynamic>;
        final itemId = item['id'] as String? ?? '';
        final media = item['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? l.unknown;
        final author = metadata['authorName'] as String? ?? '';
        final coverUrl = lib.getCoverUrl(itemId);
        final isExplicit = PlayerSettings.showExplicitBadge &&
            metadata['explicit'] == true;
        final progress = lib.getProgress(itemId);
        final isFinished =
            lib.getProgressData(itemId)?['isFinished'] == true;
        final isDownloaded = DownloadService().isDownloaded(itemId);

        return GestureDetector(
          onTap: () => _openEntityDetail(context, item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: widget.coverAspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(children: [
                    Positioned.fill(child: _cover(coverUrl, lib, cs)),
                    if (isExplicit) _explicitBadge(l),
                    if (progress > 0 && !isFinished)
                      _progressBar(cs, progress),
                    if (isFinished || isDownloaded)
                      _badges(cs, doneColor, isFinished, isDownloaded, l),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: cs.onSurface)),
              if (author.isNotEmpty)
                Text(author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(
                        fontSize: 10, color: cs.onSurfaceVariant)),
            ],
          ),
        );
      },
    );
  }

  // ── Shared widgets ──

  Widget _cover(String? coverUrl, LibraryProvider lib, ColorScheme cs) {
    if (coverUrl == null) return _placeholder(cs);
    if (coverUrl.startsWith('/')) {
      return Image.file(File(coverUrl), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(cs));
    }
    return CachedNetworkImage(
      imageUrl: coverUrl, fit: BoxFit.cover,
      httpHeaders: lib.mediaHeaders,
      placeholder: (_, __) => _placeholder(cs),
      errorWidget: (_, __, ___) => _placeholder(cs),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.book_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
      );

  Widget _explicitBadge(AppLocalizations l) => Positioned(
        top: 4, right: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(l.bookCardExplicitBadge,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800)),
        ),
      );

  Widget _progressBar(ColorScheme cs, double progress) => Positioned(
        left: 0, right: 0, bottom: 0,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 3,
          backgroundColor: Colors.black38,
          valueColor: AlwaysStoppedAnimation(cs.primary),
        ),
      );

  Widget _badges(ColorScheme cs, Color doneColor, bool isFinished,
      bool isDownloaded, AppLocalizations l) =>
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (isFinished)
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 10, color: doneColor),
                    const SizedBox(width: 3),
                    Text(l.sectionDetailDoneBadge,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: doneColor)),
                  ]),
            if (isDownloaded)
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_done_rounded,
                        size: 10, color: cs.primary),
                    const SizedBox(width: 3),
                    Text(l.saved,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: cs.primary)),
                  ]),
          ]),
        ),
      );
}
