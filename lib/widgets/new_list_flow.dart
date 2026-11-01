import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import 'add_books_search_sheet.dart';
import 'overlay_toast.dart';

/// Starts a new collection or playlist from the Lists tab. Audiobookshelf
/// refuses an empty collection, so there the books are picked first and the
/// collection is made with them; a playlist, or a BookOrbit collection, can
/// start empty with adding books offered as an option.
Future<void> startNewList(BuildContext context, {required bool playlist}) async {
  final l = AppLocalizations.of(context)!;
  final lib = context.read<LibraryProvider>();
  final auth = context.read<AuthProvider>();
  final libraryId = lib.selectedLibraryId;
  if (libraryId == null) return;
  final needsBook = !playlist && !auth.isBookOrbit;
  // The picker searches books; a podcast library's playlist starts empty.
  final canPickBooks = !lib.isPodcastLibrary;

  final choice = await showDialog<({String name, bool addBooks})>(
    context: context,
    builder: (_) => _NewListDialog(
      title: playlist ? l.newPlaylist : l.newCollection,
      hint: playlist ? l.playlistNameHint : l.collectionNameHint,
      offerAddBooks: canPickBooks && !needsBook,
      needsBook: needsBook,
    ),
  );
  if (choice == null || !context.mounted) return;

  if (needsBook) {
    final picked = <String>[];
    await AddBooksSearchSheet.show(
      context,
      title: choice.name,
      libraryId: libraryId,
      initialMemberIds: const {},
      onAdd: (id) async {
        if (!picked.contains(id)) picked.add(id);
        return true;
      },
      onRemove: (id) async {
        picked.remove(id);
        return true;
      },
    );
    if (!context.mounted) return;
    if (picked.isEmpty) {
      showOverlayToast(context, l.listsCollectionNeedsBook, icon: Icons.info_outline_rounded);
      return;
    }
    final created = await lib.createCollection(choice.name, books: picked);
    if (created == null && context.mounted) {
      showOverlayToast(context, l.listsCreateFailed, icon: Icons.error_outline_rounded);
    }
    return;
  }

  final created = playlist ? await lib.createPlaylist(choice.name) : await lib.createCollection(choice.name);
  if (!context.mounted) return;
  if (created == null) {
    showOverlayToast(context, l.listsCreateFailed, icon: Icons.error_outline_rounded);
    return;
  }
  if (!choice.addBooks) return;
  final id = '${created['id']}';
  await AddBooksSearchSheet.show(
    context,
    title: choice.name,
    libraryId: libraryId,
    initialMemberIds: const {},
    onAdd: (itemId) => playlist ? lib.addToPlaylist(id, itemId) : lib.addToCollection(id, itemId),
    onRemove: (itemId) => playlist ? lib.removeFromPlaylist(id, itemId) : lib.removeFromCollection(id, itemId),
  );
}

class _NewListDialog extends StatefulWidget {
  final String title;
  final String hint;
  final bool offerAddBooks;
  final bool needsBook;

  const _NewListDialog({
    required this.title,
    required this.hint,
    required this.offerAddBooks,
    required this.needsBook,
  });

  @override
  State<_NewListDialog> createState() => _NewListDialogState();
}

class _NewListDialogState extends State<_NewListDialog> {
  final _name = TextEditingController();
  bool _addBooks = true;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, addBooks: widget.offerAddBooks && _addBooks));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: widget.hint),
          onSubmitted: (_) => _submit(),
        ),
        if (widget.offerAddBooks)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.listsAddBooksNow),
            value: _addBooks,
            onChanged: (v) => setState(() => _addBooks = v),
          ),
        if (widget.needsBook)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(l.listsPickBooksNext, style: tt.bodySmall),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
        TextButton(
          onPressed: _name.text.trim().isEmpty ? null : _submit,
          child: Text(l.listsCreate),
        ),
      ],
    );
  }
}
