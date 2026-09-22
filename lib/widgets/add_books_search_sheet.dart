import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/book_search_index.dart';
import 'overlay_toast.dart';
import 'stackable_sheet.dart';

/// A stay-open search picker for bulk-adding books to a target (collection or
/// playlist). Type to search the library, tap a result to add it (or tap an
/// already-added one to remove) without the sheet closing, then search again.
///
/// Membership is tracked locally and updated optimistically so taps feel
/// instant; the actual add/remove runs through [onAdd]/[onRemove].
class AddBooksSearchSheet extends StatefulWidget {
  final String title;
  final String libraryId;
  final Set<String> initialMemberIds;
  final Future<bool> Function(String libraryItemId) onAdd;
  final Future<bool> Function(String libraryItemId) onRemove;

  const AddBooksSearchSheet({
    super.key,
    required this.title,
    required this.libraryId,
    required this.initialMemberIds,
    required this.onAdd,
    required this.onRemove,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String libraryId,
    required Set<String> initialMemberIds,
    required Future<bool> Function(String libraryItemId) onAdd,
    required Future<bool> Function(String libraryItemId) onRemove,
  }) {
    showStackableSheet(
      context: context,
      showHandle: true,
      useSafeArea: true,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      builder: (_, scrollController) => AddBooksSearchSheet(
        title: title,
        libraryId: libraryId,
        initialMemberIds: initialMemberIds,
        onAdd: onAdd,
        onRemove: onRemove,
      ),
    );
  }

  @override
  State<AddBooksSearchSheet> createState() => _AddBooksSearchSheetState();
}

class _AddBooksSearchSheetState extends State<AddBooksSearchSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  late final Set<String> _memberIds = {...widget.initialMemberIds};
  final Set<String> _busyIds = {};
  int _addedCount = 0;

  @override
  void initState() {
    super.initState();
    // Warm the search index so results are fuzzy and instant by the time the
    // user has typed a few characters.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final api = context.read<AuthProvider>().apiService;
      if (api != null) BookSearchIndex().ensureIndex(api, widget.libraryId);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) {
      if (mounted) setState(() => _isSearching = false);
      return;
    }
    await BookSearchIndex().ensureIndex(api, widget.libraryId);
    if (!mounted || _controller.text.trim() != query) return;

    List<Map<String, dynamic>> results;
    if (BookSearchIndex().isReady(widget.libraryId)) {
      results = BookSearchIndex()
          .search(widget.libraryId, query)
          .map((h) => h.item)
          .toList();
      // A truncated index misses the newest items in a huge library - merge
      // in server hits the index doesn't know about (GH #349).
      if (BookSearchIndex().isTruncated(widget.libraryId)) {
        final server = await api.searchLibrary(widget.libraryId, query);
        if (!mounted || _controller.text.trim() != query) return;
        final seen = results.map((i) => i['id']).toSet();
        for (final r in (server?['book'] as List<dynamic>? ?? const [])) {
          final m = r as Map<String, dynamic>;
          final item = (m['libraryItem'] as Map<String, dynamic>?) ?? m;
          if (!seen.contains(item['id'])) results.add(item);
        }
      }
    } else {
      // Index didn't build (e.g. offline) - fall back to the server search.
      final result = await api.searchLibrary(widget.libraryId, query);
      if (!mounted || _controller.text.trim() != query) return;
      results = ((result?['book'] as List<dynamic>?) ?? []).map((r) {
        final m = r as Map<String, dynamic>;
        return (m['libraryItem'] as Map<String, dynamic>?) ?? m;
      }).toList();
    }
    setState(() {
      _results = results;
      _isSearching = false;
      _hasSearched = true;
    });
  }

  Future<void> _toggle(String itemId) async {
    if (itemId.isEmpty || _busyIds.contains(itemId)) return;
    final wasMember = _memberIds.contains(itemId);
    setState(() {
      _busyIds.add(itemId);
      if (wasMember) {
        _memberIds.remove(itemId);
      } else {
        _memberIds.add(itemId);
        _addedCount++;
      }
    });
    HapticFeedback.selectionClick();

    final ok = wasMember
        ? await widget.onRemove(itemId)
        : await widget.onAdd(itemId);
    if (!mounted) return;

    setState(() {
      _busyIds.remove(itemId);
      if (!ok) {
        // Revert the optimistic change
        if (wasMember) {
          _memberIds.add(itemId);
        } else {
          _memberIds.remove(itemId);
          _addedCount--;
        }
      }
    });
    if (!ok) {
      showOverlayToast(context, AppLocalizations.of(context)!.failedToAdd,
          icon: Icons.error_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(children: [
          Expanded(
            child: Text(widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
          ),
          if (_addedCount > 0)
            Text('$_addedCount added',
                style: tt.labelMedium
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: cs.onSurface, fontSize: 15),
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: l.librarySearchBooksHint,
            prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: cs.surfaceContainerHigh,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(child: _buildBody(cs, tt, l)),
    ]);
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    if (_isSearching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      // Hardcoded English (l10n follow-up, matches other new-feature strings).
      return _hint(cs, tt, Icons.search_rounded, 'Search your library to add books');
    }
    if (_results.isEmpty) {
      return _hint(cs, tt, Icons.search_off_rounded, l.noBooksFound);
    }
    final lib = context.read<LibraryProvider>();
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
          12, 0, 12, 24 + MediaQuery.of(context).viewInsets.bottom),
      itemCount: _results.length,
      itemBuilder: (context, index) => _resultRow(cs, tt, l, lib, _results[index]),
    );
  }

  Widget _resultRow(ColorScheme cs, TextTheme tt, AppLocalizations l,
      LibraryProvider lib, Map<String, dynamic> item) {
    final itemId = item['id'] as String? ?? '';
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? l.unknown;
    final author = metadata['authorName'] as String? ?? '';
    final coverUrl = lib.getCoverUrl(itemId);
    final isMember = _memberIds.contains(itemId);
    final isBusy = _busyIds.contains(itemId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isBusy ? null : () => _toggle(itemId),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: coverUrl != null && !coverUrl.startsWith('/')
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          httpHeaders: lib.mediaHeaders,
                          placeholder: (_, __) => _coverPh(cs),
                          errorWidget: (_, __, ___) => _coverPh(cs),
                        )
                      : _coverPh(cs),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600, color: cs.onSurface)),
                    if (author.isNotEmpty)
                      Text(author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                height: 32,
                child: isBusy
                    ? Padding(
                        padding: const EdgeInsets.all(7),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      )
                    : Icon(
                        isMember
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: isMember ? cs.primary : cs.onSurfaceVariant,
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _coverPh(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.book_rounded,
            size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
      );

  Widget _hint(ColorScheme cs, TextTheme tt, IconData icon, String text) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(text,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}
