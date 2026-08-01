import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'overlay_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import 'cover_badges.dart';
import '../services/wording.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'add_books_search_sheet.dart';
import 'book_detail_sheet.dart';
import 'editable_sheet_item.dart';
import 'stackable_sheet.dart';
import '../screens/app_shell.dart';

class CollectionDetailSheet extends StatefulWidget {
  final String collectionId;
  final ScrollController? scrollController;

  const CollectionDetailSheet({
    super.key,
    required this.collectionId,
    this.scrollController,
  });

  static void show(BuildContext context, String collectionId) {
    showStackableSheet(
      context: context,
      useSafeArea: true,
      showHandle: true,
      maxChildSize: 0.95,
      builder: (context, scrollController) => CollectionDetailSheet(
        collectionId: collectionId,
        scrollController: scrollController,
      ),
    );
  }

  @override
  State<CollectionDetailSheet> createState() => _CollectionDetailSheetState();
}

class _CollectionDetailSheetState extends State<CollectionDetailSheet> {
  bool _editing = false;
  bool _gridView = false;
  List<Map<String, dynamic>>? _editItems;
  final Set<String> _selectedItemIds = {};
  bool _isRemovingSelected = false;

  Future<void> _removeItem(LibraryProvider lib, String libraryItemId) async {
    await lib.removeFromCollection(widget.collectionId, libraryItemId);
  }

  void _openAddBooks(LibraryProvider lib, Map<String, dynamic> collection,
      String name, List<dynamic> books) {
    final libraryId = collection['libraryId'] as String? ?? lib.selectedLibraryId;
    if (libraryId == null) return;
    final memberIds = books
        .whereType<Map<String, dynamic>>()
        .map((b) => b['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    AddBooksSearchSheet.show(
      context,
      title: name,
      libraryId: libraryId,
      initialMemberIds: memberIds,
      onAdd: (id) => lib.addToCollection(widget.collectionId, id),
      onRemove: (id) => lib.removeFromCollection(widget.collectionId, id),
    );
  }

  /// Header icon with a comfortable (>=44px tall) tap target and ripple, so
  /// the small top-row controls aren't fiddly to press.
  Widget _headerIconButton(ColorScheme cs, IconData icon, VoidCallback onTap,
      {String? tooltip}) {
    return IconButton(
      icon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 44),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      ),
    );
  }

  Widget _headerTextButton(ColorScheme cs, String label, VoidCallback? onTap,
      {required Color color}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _deleteCollection(BuildContext context, LibraryProvider lib) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteCollection),
        content: Text(l.deleteCollectionContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final status = await lib.deleteCollection(widget.collectionId);
      if (!context.mounted) return;
      if (status == 200) {
        Navigator.pop(context);
      } else if (status == 403) {
        showOverlayToast(context, l.deletePermissionRequired,
            icon: Icons.lock_outline_rounded);
      } else {
        showOverlayToast(context, l.deleteCollectionFailed,
            icon: Icons.error_outline_rounded);
      }
    }
  }

  void _startEdit(List<dynamic> books) {
    setState(() {
      _editing = true;
      _editItems = books
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList();
      _selectedItemIds.clear();
    });
  }

  void _saveEdit(LibraryProvider lib) {
    final items = _editItems;
    if (items != null) {
      final bookIds = items
          .map((b) => b['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      // Persist in the background so "Done" closes instantly instead of
      // hanging on the PATCH + collections reload.
      unawaited(lib.reorderCollectionBooks(widget.collectionId, bookIds));
    }
    Navigator.pop(context);
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _editItems = null;
      _selectedItemIds.clear();
    });
  }

  Future<void> _removeSelected(LibraryProvider lib) async {
    if (_selectedItemIds.isEmpty) return;
    setState(() => _isRemovingSelected = true);

    final removedIds = <String>{};
    for (final itemId in List<String>.from(_selectedItemIds)) {
      if (await lib.removeFromCollection(widget.collectionId, itemId)) {
        removedIds.add(itemId);
      }
    }

    if (!mounted) return;
    setState(() {
      _editItems?.removeWhere((item) => removedIds.contains(item['id']));
      _selectedItemIds.removeAll(removedIds);
      _isRemovingSelected = false;
    });
    if (removedIds.isNotEmpty) {
      showOverlayToast(
        context,
        AppLocalizations.of(context)!.playlistDetailItemsRemoved(removedIds.length),
        icon: Icons.playlist_remove_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();
    final auth = context.read<AuthProvider>();
    // Both gated at isAdmin in the UI; server returns 403 when admin lacks
    // the `delete` permission flag and we show a friendly toast then.
    final canEditCollection = auth.isAdmin;
    final canDeleteCollection = auth.isAdmin;

    final collection = lib.collections.cast<Map<String, dynamic>>().where(
      (c) => c['id'] == widget.collectionId,
    ).firstOrNull;

    if (collection == null) {
      return Center(child: Text(l.collectionNotFound));
    }

    final name = collection['name'] as String? ?? l.collectionDetailDefaultName;
    final description = collection['description'] as String? ?? '';
    final books = (collection['books'] as List<dynamic>?) ?? [];

    return Column(children: [
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          if (_editing) ...[
            _headerTextButton(cs, l.cancel, _cancelEdit, color: cs.onSurfaceVariant),
            const Spacer(),
            Flexible(
              child: Text(
                _selectedItemIds.isEmpty
                    ? name
                    : l.selectedCount(_selectedItemIds.length),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: cs.onSurface)),
            ),
            const Spacer(),
            _headerTextButton(
              cs,
              l.done,
              _isRemovingSelected ? null : () => _saveEdit(lib),
              color: cs.primary,
            ),
          ] else ...[
            Icon(Icons.collections_bookmark_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name, style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600, color: cs.onSurface,
              )),
            ),
            Text(l.collectionDetailBookCount(books.length),
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (canEditCollection)
              _headerIconButton(cs, Icons.library_add_rounded,
                () => _openAddBooks(lib, collection, name, books)),
            _headerIconButton(cs,
              _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              () => setState(() => _gridView = !_gridView)),
            if (canEditCollection)
              _headerIconButton(cs, Icons.edit_rounded, () => _startEdit(books),
                tooltip: l.edit),
          ],
        ]),
      ),
      if (!_editing && description.isNotEmpty) ...[
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(description,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      const SizedBox(height: 12),
      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3),
        indent: 20, endIndent: 20),
      if (!_editing)
        _buildPlayButton(cs, lib, books, name, l),
      // Content
      Expanded(
        child: _editing
            ? _buildEditList(cs, tt, lib, l)
            : _gridView
                ? _buildGrid(cs, tt, lib, books, l)
                : _buildItemList(cs, tt, lib, books, l, canEditCollection: canEditCollection),
      ),
      if (_editing && canDeleteCollection)
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 8, 16,
            8 + MediaQuery.of(context).viewPadding.bottom),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            border: Border(top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.3))),
          ),
          child: _isRemovingSelected
              ? Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)))
              : _selectedItemIds.isNotEmpty
                  ? FilledButton.tonalIcon(
                      onPressed: () => _removeSelected(lib),
                      icon: const Icon(Icons.playlist_remove_rounded),
                      label: Text('${l.remove} (${_selectedItemIds.length})'),
                      style: FilledButton.styleFrom(foregroundColor: cs.error),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _deleteCollection(context, lib),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l.deleteCollection),
                      style: OutlinedButton.styleFrom(foregroundColor: cs.error),
                    ),
        ),
    ]);
  }

  Widget _buildPlayButton(ColorScheme cs, LibraryProvider lib, List<dynamic> books, String name, AppLocalizations l) {
    int firstIdx = -1;
    for (var i = 0; i < books.length; i++) {
      final b = books[i];
      if (b is! Map<String, dynamic>) continue;
      final id = b['id'] as String? ?? '';
      if (id.isEmpty) continue;
      if (!lib.isItemFinishedByKey(id)) { firstIdx = i; break; }
    }
    final allFinished = books.isNotEmpty && firstIdx < 0;
    final enabled = books.isNotEmpty && firstIdx >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: enabled
              ? () async {
                  HapticFeedback.selectionClick();
                  final id = widget.collectionId;
                  Navigator.pop(context);
                  AppShell.goToAbsorbingGlobal();
                  await PlayerSettings.setQueueModeCollection(id, name);
                  final started = await lib.playCollectionFromStart(id);
                  if (started) unawaited(lib.syncQueueAutoDownloads());
                }
              : null,
          icon: Icon(allFinished
              ? Icons.check_circle_outline_rounded
              : Icons.play_arrow_rounded),
          label: Text(allFinished ? l.playlistAllFinished : l.playlistPlayAction),
        ),
      ),
    );
  }

  Widget _buildEditList(ColorScheme cs, TextTheme tt, LibraryProvider lib, AppLocalizations l) {
    final items = _editItems!;
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
        });
      },
      itemCount: items.length,
      itemBuilder: (context, index) {
        final book = items[index];
        final itemId = book['id'] as String? ?? '';
        final media = book['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? l.unknown;
        final author = metadata['authorName'] as String? ?? '';
        final coverUrl = lib.getCoverUrl(itemId);

        return EditableSheetItem(
          key: ValueKey(itemId),
          index: index,
          selected: _selectedItemIds.contains(itemId),
          onSelectedChanged: (selected) => setState(() {
            if (selected) {
              _selectedItemIds.add(itemId);
            } else {
              _selectedItemIds.remove(itemId);
            }
          }),
          title: title,
          subtitle: author.isEmpty ? null : author,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: coverUrl != null
                ? (coverUrl.startsWith('/')
                    ? Image.file(File(coverUrl), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(cs))
                    : Image.network(coverUrl, fit: BoxFit.cover,
                        headers: lib.mediaHeaders,
                        errorBuilder: (_, __, ___) => _placeholder(cs)))
                : _placeholder(cs),
          ),
        );
      },
    );
  }

  Widget _buildItemList(ColorScheme cs, TextTheme tt, LibraryProvider lib, List<dynamic> books, AppLocalizations l, {required bool canEditCollection}) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4).copyWith(bottom: 40),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index] as Map<String, dynamic>;
        final itemId = book['id'] as String? ?? '';
        final media = book['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? l.unknown;
        final author = metadata['authorName'] as String? ?? '';
        final coverUrl = lib.getCoverUrl(itemId);
        final isExplicit = PlayerSettings.showExplicitBadge && metadata['explicit'] == true;
        final progress = lib.getProgress(itemId);
        final isFinished = lib.getProgressData(itemId)?['isFinished'] == true;
        final isDownloaded = DownloadService().isDownloaded(itemId);

        final card = Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 0,
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showBookDetailSheet(context, itemId),
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 112,
                child: Row(children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(children: [
                      Positioned.fill(
                        child: coverUrl != null
                            ? (coverUrl.startsWith('/')
                                ? Image.file(File(coverUrl), fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholder(cs))
                                : CachedNetworkImage(
                                    imageUrl: coverUrl, fit: BoxFit.cover,
                                    httpHeaders: lib.mediaHeaders,
                                    placeholder: (_, __) => _placeholder(cs),
                                    errorWidget: (_, __, ___) => _placeholder(cs),
                                  ))
                            : _placeholder(cs),
                      ),
                      if (isExplicit)
                        Positioned(
                          top: 4, right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(l.bookCardExplicitBadge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      if (progress > 0 && !isFinished)
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 3,
                            backgroundColor: Colors.black38,
                            valueColor: AlwaysStoppedAnimation(cs.primary),
                          ),
                        ),
                      if (isFinished || isDownloaded)
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: CoverStateBadges(isDownloaded: isDownloaded, isFinished: isFinished),
                        ),
                    ]),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                          const SizedBox(height: 4),
                          Text(author,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );

        final isOnAbsorbing = lib.isOnAbsorbingList(itemId);

        if (!canEditCollection) {
          return Dismissible(
            key: ValueKey('absorb-$itemId'),
            direction: isOnAbsorbing ? DismissDirection.none : DismissDirection.startToEnd,
            confirmDismiss: (_) async {
              await lib.addToAbsorbingQueue(itemId);
              lib.absorbingItemCache[itemId] = Map<String, dynamic>.from(book);
              HapticFeedback.mediumImpact();
              if (context.mounted) {
                showOverlayToast(context, Wording.of(context).collectionDetailAddedToAbsorbing(title), icon: Icons.add_circle_outline_rounded);
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
        }

        return Dismissible(
          key: ValueKey(itemId),
          direction: isOnAbsorbing ? DismissDirection.endToStart : DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await lib.addToAbsorbingQueue(itemId);
              lib.absorbingItemCache[itemId] = Map<String, dynamic>.from(book);
              HapticFeedback.mediumImpact();
              if (context.mounted) {
                showOverlayToast(context, Wording.of(context).collectionDetailAddedToAbsorbing(title), icon: Icons.add_circle_outline_rounded);
              }
              return false;
            }
            _removeItem(lib, itemId);
            return true;
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
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: cs.error.withValues(alpha: 0.1),
            child: Icon(Icons.delete_rounded, color: cs.error),
          ),
          child: card,
        );
      },
    );
  }

  Widget _buildGrid(ColorScheme cs, TextTheme tt, LibraryProvider lib, List<dynamic> books, AppLocalizations l) {
    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          .copyWith(bottom: 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index] as Map<String, dynamic>;
        final itemId = book['id'] as String? ?? '';
        final media = book['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? l.unknown;
        final author = metadata['authorName'] as String? ?? '';
        final coverUrl = lib.getCoverUrl(itemId);
        final isExplicit = PlayerSettings.showExplicitBadge && metadata['explicit'] == true;
        final progress = lib.getProgress(itemId);
        final isFinished = lib.getProgressData(itemId)?['isFinished'] == true;
        final isDownloaded = DownloadService().isDownloaded(itemId);

        return GestureDetector(
          onTap: () => showBookDetailSheet(context, itemId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(children: [
                    Positioned.fill(
                      child: coverUrl != null
                          ? (coverUrl.startsWith('/')
                              ? Image.file(File(coverUrl), fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder(cs))
                              : CachedNetworkImage(
                                  imageUrl: coverUrl, fit: BoxFit.cover,
                                  httpHeaders: lib.mediaHeaders,
                                  placeholder: (_, __) => _placeholder(cs),
                                  errorWidget: (_, __, ___) => _placeholder(cs),
                                ))
                          : _placeholder(cs),
                    ),
                    if (isExplicit)
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(l.bookCardExplicitBadge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    if (progress > 0 && !isFinished)
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 3,
                          backgroundColor: Colors.black38,
                          valueColor: AlwaysStoppedAnimation(cs.primary),
                        ),
                      ),
                    if (isFinished || isDownloaded)
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: CoverStateBadges(isDownloaded: isDownloaded, isFinished: isFinished),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              if (author.isNotEmpty)
                Text(author, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(fontSize: 10, color: cs.onSurfaceVariant)),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHigh,
      child: Icon(Icons.book_rounded, size: 20,
        color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
    );
  }
}
