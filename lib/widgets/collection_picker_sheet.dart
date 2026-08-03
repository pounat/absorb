import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import 'adaptive_modal.dart';
import 'overlay_toast.dart';

class CollectionPickerSheet extends StatefulWidget {
  final String libraryItemId;

  const CollectionPickerSheet({
    super.key,
    required this.libraryItemId,
  });

  static void show(BuildContext context, String libraryItemId) {
    showAdaptiveActionMenu(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => CollectionPickerSheet(libraryItemId: libraryItemId),
    );
  }

  @override
  State<CollectionPickerSheet> createState() => _CollectionPickerSheetState();
}

class _CollectionPickerSheetState extends State<CollectionPickerSheet> {
  bool _creatingNew = false;
  final _nameController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAndAdd(LibraryProvider lib) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _adding = true);
    final collection = await lib.createCollection(name, books: [widget.libraryItemId]);
    if (collection != null) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        showOverlayToast(context, l.addedToName(name), icon: Icons.bookmark_added_rounded);
        Navigator.pop(context);
      }
    } else {
      setState(() => _adding = false);
    }
  }

  Future<void> _addToExisting(LibraryProvider lib, Map<String, dynamic> collection) async {
    setState(() => _adding = true);
    final collectionId = collection['id'] as String;
    final l = AppLocalizations.of(context)!;
    final name = collection['name'] as String? ?? l.collectionPickerCollectionFallback;
    final ok = await lib.addToCollection(collectionId, widget.libraryItemId);
    if (mounted) {
      showOverlayToast(
        context,
        ok ? l.addedToName(name) : l.failedToAdd,
        icon: ok ? Icons.bookmark_added_rounded : Icons.error_outline_rounded,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final collections = lib.collections;
    final l = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Grab handle
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          // Title
          Text(l.addToCollection, style: TextStyle(
            color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 12),
          // New collection
          if (_creatingNew)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: TextStyle(color: cs.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.collectionNameHint,
                    hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.2)),
                    ),
                  ),
                  onSubmitted: (_) => _createAndAdd(lib),
                )),
                const SizedBox(width: 8),
                _adding
                    ? const SizedBox(width: 36, height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                    : IconButton(
                        icon: Icon(Icons.check_rounded, color: cs.primary),
                        onPressed: () => _createAndAdd(lib),
                      ),
              ]),
            )
          else
            _sheetItem(cs, Icons.add_rounded, l.newCollection,
              onTap: () => setState(() => _creatingNew = true)),
          // Existing collections
          if (collections.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...collections.map((c) {
              final cm = c as Map<String, dynamic>;
              final name = cm['name'] as String? ?? l.collectionPickerCollectionFallback;
              final books = (cm['books'] as List<dynamic>?) ?? [];
              // Check if item is already in this collection
              final alreadyIn = books.any((book) {
                final bm = book as Map<String, dynamic>;
                return bm['id'] == widget.libraryItemId;
              });
              return _sheetItem(
                cs,
                alreadyIn ? Icons.check_rounded : Icons.collections_bookmark_rounded,
                l.collectionPickerNameWithCount(name, books.length),
                enabled: !alreadyIn && !_adding,
                onTap: () => _addToExisting(lib, cm),
              );
            }),
          ],
        ]),
      ),
    );
  }

  Widget _sheetItem(ColorScheme cs, IconData icon, String label,
      {required VoidCallback onTap, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: enabled ? 0.06 : 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16,
                color: enabled ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: enabled ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.4),
              fontSize: 13, fontWeight: FontWeight.w500,
            )),
          ]),
        ),
      ),
    );
  }
}
