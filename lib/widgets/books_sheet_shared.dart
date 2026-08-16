import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';

/// Helpers shared by the book-list sheets (author, narrator, series).

/// Register cover cache-busting and has-cover info for one book.
void registerBookCover(LibraryProvider lib, Map<String, dynamic> book) {
  final id = book['id'] as String?;
  if (id == null) return;
  final ts = book['updatedAt'] as num?;
  if (ts != null) lib.registerUpdatedAt(id, ts.toInt());
  final coverPath = (book['media'] as Map<String, dynamic>?)?['coverPath'] as String?;
  lib.registerHasCover(id, coverPath != null && coverPath.isNotEmpty);
}

void registerBookCovers(LibraryProvider lib, Iterable<Map<String, dynamic>> books) {
  for (final book in books) {
    registerBookCover(lib, book);
  }
}

/// Column count for cover grids. Small/large scale the width-based medium
/// count by a third, so phones land on exactly 4/3/2 columns no matter their
/// display scale while tablets move proportionally (e.g. 8/6/4).
int coverGridCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final base = (width / 130).floor().clamp(3, 10);
  switch (PlayerSettings.coverSize) {
    case 'small':
      return ((base * 4) / 3).round().clamp(4, 12);
    case 'large':
      return ((base * 2) / 3).round().clamp(2, 10);
    default:
      return base;
  }
}

/// Label scale for cover-grid tiles: 1.0 at the stock phone tile width and
/// growing with the tile, so big tablet or large-cover grids don't pair big
/// covers with tiny labels. Never shrinks below 1.0 on dense grids.
double coverGridTextScale(BuildContext context) {
  final columns = coverGridCount(context);
  final width = MediaQuery.of(context).size.width;
  final tile = (width - 32 - 10 * (columns - 1)) / columns;
  return (tile / 120).clamp(1.0, 1.5);
}

/// Decode width in physical pixels for a cover in the current grid. Disk
/// caching only saves the download - every tile scrolled into view still
/// decodes its bitmap, so decoding at tile size instead of the full server
/// cover is what keeps a long scroll from ballooning memory.
int coverGridDecodeWidth(BuildContext context) {
  final columns = coverGridCount(context);
  final mq = MediaQuery.of(context);
  final tile = (mq.size.width - 32 - 10 * (columns - 1)) / columns;
  return (tile * mq.devicePixelRatio).round();
}

/// Standard grid delegate for book grids inside sheets.
SliverGridDelegateWithFixedCrossAxisCount sheetBookGridDelegate(
  BuildContext context, {
  double childAspectRatio = 0.55,
}) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: coverGridCount(context),
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: childAspectRatio,
  );
}

/// List/grid toggle row shown under a sheet header. Persists the choice via
/// [PlayerSettings.setSheetGridView]; [leading] is an optional control pinned
/// to the left (e.g. a group-by-series toggle).
Widget sheetViewModeBar(
  BuildContext context, {
  required bool gridView,
  required ValueChanged<bool> onChanged,
  Widget? leading,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 0, 16, 4),
}) {
  final cs = Theme.of(context).colorScheme;
  final l = AppLocalizations.of(context)!;
  Widget layoutBtn(IconData icon, bool grid, String tooltip) {
    final active = gridView == grid;
    return IconButton(
      icon: Icon(icon, size: 20, color: active ? cs.primary : cs.onSurfaceVariant),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        onChanged(grid);
        PlayerSettings.setSheetGridView(grid);
      },
    );
  }
  return Padding(
    padding: padding,
    child: Row(
      children: [
        if (leading != null) leading,
        const Spacer(),
        layoutBtn(Icons.view_list_rounded, false, l.authorBooksList),
        layoutBtn(Icons.apps_rounded, true, l.authorBooksGrid),
      ],
    ),
  );
}

/// Round-avatar header used by the author and narrator sheets:
/// 72px avatar, name, book count, optional trailing action.
Widget sheetPersonHeader(
  BuildContext context, {
  required Widget avatar,
  required String title,
  String? subtitle,
  Widget? trailing,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(title,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}

/// Scrollable "no books" body that keeps the header widgets visible.
Widget sheetEmptyBooksList(
  BuildContext context, {
  required ScrollController controller,
  required List<Widget> headerWidgets,
  required double bottomPad,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final l = AppLocalizations.of(context)!;
  return ListView(
    controller: controller,
    padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad),
    children: [
      ...headerWidgets,
      Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Text(l.noBooksFound,
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ),
    ],
  );
}
