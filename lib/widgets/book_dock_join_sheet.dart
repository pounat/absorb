import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/book_dock.dart';
import 'adaptive_modal.dart';
import 'expressive.dart';

/// How a dock file goes into a library: as a book of its own ([book] null)
/// or as another format of [book].
class BookDockJoinPick {
  final BookDockJoinBook? book;
  const BookDockJoinPick([this.book]);
}

/// Asks whether a dock file becomes a new book in [destination] or joins a
/// book already there. Null when dismissed.
Future<BookDockJoinPick?> showBookDockJoinSheet(
  BuildContext context, {
  required ApiService api,
  required BookDockDestination destination,
  BookDockJoinBook? suggested,
}) {
  return showAdaptiveActionMenu<BookDockJoinPick>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    desktopScrollWrap: false,
    builder: (ctx) => _JoinSheet(api: api, destination: destination, suggested: suggested),
  );
}

class _JoinSheet extends StatefulWidget {
  final ApiService api;
  final BookDockDestination destination;
  final BookDockJoinBook? suggested;
  const _JoinSheet({required this.api, required this.destination, this.suggested});

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  bool _searching = false;
  bool _failed = false;
  List<BookDockJoinBook>? _results;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      _generation++;
      setState(() {
        _searching = false;
        _failed = false;
        _results = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    final generation = ++_generation;
    final res = await widget.api.searchLibrary(widget.destination.libraryId, q, limit: 20);
    if (!mounted || generation != _generation) return;
    final found = <BookDockJoinBook>[];
    for (final hit in (res?['book'] as List<dynamic>? ?? const []).whereType<Map>()) {
      final item = hit['libraryItem'];
      if (item is! Map) continue;
      final id = int.tryParse('${item['id']}');
      if (id == null || id == widget.suggested?.bookId) continue;
      final meta = (item['media'] as Map?)?['metadata'] as Map?;
      final author = '${meta?['authorName'] ?? ''}';
      found.add(BookDockJoinBook(
        bookId: id,
        title: '${meta?['title'] ?? ''}',
        authors: [if (author.isNotEmpty) author],
      ));
    }
    setState(() {
      _searching = false;
      _failed = res == null;
      _results = found;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final suggested = widget.suggested;
    final results = _results;

    Widget bookTile(BookDockJoinBook b, {String? note, bool lead = false}) => ListTile(
          leading: Icon(Icons.library_add_rounded, color: lead ? cs.primary : cs.onSurfaceVariant),
          title: Text(b.title.isEmpty ? l.unknown : b.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [if (b.authors.isNotEmpty) b.authors.join(', '), ?note].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.pop(context, BookDockJoinPick(b)),
        );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l.bookDockJoinTitle, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l.bookDockJoinHint, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ),
            Flexible(
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 16), children: [
                if (suggested != null)
                  bookTile(
                    suggested,
                    lead: true,
                    note: switch (suggested.reason) {
                      'isbn' => l.bookDockJoinSameIsbn,
                      'title_author' => l.bookDockJoinSameTitle,
                      _ => l.bookDockJoinLooksSame,
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.add_rounded, color: cs.onSurfaceVariant),
                  title: Text(l.bookDockJoinNewBook),
                  onTap: () => Navigator.pop(context, const BookDockJoinPick()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _query,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      hintText: l.bookDockJoinSearch(widget.destination.libraryName),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: SizedBox(width: 20, height: 20, child: AdaptiveSpinner(strokeWidth: 2))),
                  )
                else if (_failed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                    child: Text(l.bookDockJoinSearchFailed, style: tt.bodySmall?.copyWith(color: cs.error)),
                  )
                else if (results != null && results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                    child: Text(l.bookDockJoinNoMatch, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  )
                else if (results != null)
                  for (final b in results) bookTile(b),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
