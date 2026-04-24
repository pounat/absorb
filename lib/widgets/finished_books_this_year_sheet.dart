import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'book_detail_sheet.dart';
import 'stackable_sheet.dart';

/// Show a modal sheet listing every book the user has finished in the
/// current calendar year. Loads full item metadata on demand so it can
/// render covers + metadata + still-in-library detection for each one.
void showFinishedBooksThisYearSheet(BuildContext context) {
  showStackableSheet(
    context: context,
    useSafeArea: true,
    showHandle: true,
    maxChildSize: 0.95,
    builder: (ctx, scrollController) => FinishedBooksThisYearSheet(
      scrollController: scrollController,
    ),
  );
}

class FinishedBooksThisYearSheet extends StatefulWidget {
  final ScrollController scrollController;
  const FinishedBooksThisYearSheet({
    super.key,
    required this.scrollController,
  });

  @override
  State<FinishedBooksThisYearSheet> createState() =>
      _FinishedBooksThisYearSheetState();
}

class _FinishedBooksThisYearSheetState
    extends State<FinishedBooksThisYearSheet> {
  bool _isLoading = true;
  bool _gridView = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    PlayerSettings.getSectionGridView().then((v) {
      if (mounted && v != _gridView) setState(() => _gridView = v);
    });
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    final ids = lib.finishedBooksThisYearIds;

    if (api == null || ids.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final results = await Future.wait(ids.map((id) => api.getLibraryItem(id)));
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      if (r == null) continue;
      items.add(r);
    }

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          Icon(Icons.auto_stories_rounded, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.statsBooksThisYear,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text('${_items.length}',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _toggleGridView,
            child: Icon(
              _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? Center(
                    child: Text(l.noBooksFound,
                        style: tt.bodyLarge
                            ?.copyWith(color: cs.onSurfaceVariant)))
                : _gridView
                    ? _buildGrid(cs, tt, lib, l)
                    : _buildList(cs, tt, lib, l),
      ),
    ]);
  }

  Widget _buildList(ColorScheme cs, TextTheme tt, LibraryProvider lib,
      AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doneColor = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;
    final bottomPad = 24 + MediaQuery.of(context).viewPadding.bottom;

    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final itemId = item['id'] as String? ?? '';
        final media = item['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? l.unknown;
        final author = metadata['authorName'] as String? ?? '';
        final coverUrl = lib.getCoverUrl(itemId);
        final isDownloaded = DownloadService().isDownloaded(itemId);
        final progressData = lib.getProgressData(itemId);
        final startedAt = progressData?['startedAt'];
        final finishedAt = progressData?['finishedAt'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 0,
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showBookDetailSheet(context, itemId),
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 128,
                child: Row(children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(children: [
                      Positioned.fill(child: _cover(coverUrl, lib, cs)),
                      _finishedBadge(doneColor, isDownloaded, cs, l),
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
                          const SizedBox(height: 2),
                          Text(author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          if (startedAt is num)
                            _dateRow(Icons.play_circle_outline_rounded,
                                _fmtDate(startedAt.toInt()), cs, tt),
                          if (finishedAt is num) ...[
                            const SizedBox(height: 2),
                            _dateRow(Icons.check_circle_outline_rounded,
                                _fmtDate(finishedAt.toInt()), cs, tt),
                          ],
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(ColorScheme cs, TextTheme tt, LibraryProvider lib,
      AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doneColor = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;
    final bottomPad = 24 + MediaQuery.of(context).viewPadding.bottom;

    return GridView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.55,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final itemId = item['id'] as String? ?? '';
        final media = item['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? l.unknown;
        final author = metadata['authorName'] as String? ?? '';
        final coverUrl = lib.getCoverUrl(itemId);
        final isDownloaded = DownloadService().isDownloaded(itemId);
        final finishedAt = lib.getProgressData(itemId)?['finishedAt'];

        return GestureDetector(
          onTap: () => showBookDetailSheet(context, itemId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(children: [
                    Positioned.fill(child: _cover(coverUrl, lib, cs)),
                    _finishedBadge(doneColor, isDownloaded, cs, l),
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
                    style: tt.labelSmall
                        ?.copyWith(fontSize: 10, color: cs.onSurfaceVariant)),
              if (finishedAt is num)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _dateRow(Icons.check_circle_outline_rounded,
                      _fmtDate(finishedAt.toInt()), cs, tt),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _cover(String? coverUrl, LibraryProvider lib, ColorScheme cs) {
    if (coverUrl == null) return _placeholder(cs);
    if (coverUrl.startsWith('/')) {
      return Image.file(File(coverUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(cs));
    }
    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      httpHeaders: lib.mediaHeaders,
      placeholder: (_, __) => _placeholder(cs),
      errorWidget: (_, __, ___) => _placeholder(cs),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.book_rounded,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
      );

  Widget _dateRow(IconData icon, String date, ColorScheme cs, TextTheme tt) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.85))),
        ),
      ],
    );
  }

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _finishedBadge(Color doneColor, bool isDownloaded, ColorScheme cs,
          AppLocalizations l) =>
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
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 10, color: doneColor),
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
