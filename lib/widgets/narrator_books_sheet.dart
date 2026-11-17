import 'package:flutter/material.dart';
import 'expressive.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import 'books_sheet_shared.dart';
import 'library_grid_tiles.dart';
import 'library_search_results.dart';
import 'stackable_sheet.dart';

/// Show a stackable sheet listing books narrated by [narratorName].
void showNarratorBooksSheet(BuildContext context, {
  required String narratorName,
}) {
  final auth = context.read<AuthProvider>();
  final lib = context.read<LibraryProvider>();
  showStackableSheet(
    context: context,
    showHandle: true,
    builder: (ctx, scrollController) => NarratorBooksSheet(
      libraryId: lib.selectedLibraryId ?? '',
      narratorName: narratorName,
      serverUrl: auth.serverUrl,
      token: auth.token,
      scrollController: scrollController,
    ),
  );
}

class NarratorBooksSheet extends StatefulWidget {
  final String libraryId;
  final String narratorName;
  final String? serverUrl;
  final String? token;
  final ScrollController scrollController;

  const NarratorBooksSheet({
    super.key,
    required this.libraryId,
    required this.narratorName,
    required this.serverUrl,
    required this.token,
    required this.scrollController,
  });

  @override
  State<NarratorBooksSheet> createState() => _NarratorBooksSheetState();
}

class _NarratorBooksSheetState extends State<NarratorBooksSheet> {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  bool _gridView = false;

  @override
  void initState() {
    super.initState();
    _loadViewSettings();
    _loadBooks();
  }

  Future<void> _loadViewSettings() async {
    final grid = await PlayerSettings.getSheetGridView();
    if (mounted) setState(() => _gridView = grid);
  }

  Future<void> _loadBooks() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null || widget.libraryId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final raw = await api.getBooksByNarrator(widget.libraryId, widget.narratorName, limit: 200);
    if (!mounted) return;

    final books = raw.whereType<Map<String, dynamic>>().toList();
    registerBookCovers(context.read<LibraryProvider>(), books);

    // Sort alphabetically by title
    books.sort((a, b) {
      final tA = ((a['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?)?['title'] as String? ?? '';
      final tB = ((b['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?)?['title'] as String? ?? '';
      return tA.toLowerCase().compareTo(tB.toLowerCase());
    });

    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottomPad = 24 + MediaQuery.of(context).viewPadding.bottom;

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l),
          const Expanded(child: Center(child: AdaptiveSpinner())),
        ],
      );
    }

    final headerWidgets = <Widget>[
      _buildHeader(l),
      if (_books.isNotEmpty)
        sheetViewModeBar(context,
            gridView: _gridView,
            onChanged: (grid) => setState(() => _gridView = grid)),
    ];

    if (_books.isEmpty) {
      return sheetEmptyBooksList(context,
          controller: widget.scrollController,
          headerWidgets: headerWidgets,
          bottomPad: bottomPad);
    }

    if (!_gridView) {
      return ListView.builder(
        controller: widget.scrollController,
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad),
        itemCount: _books.length + headerWidgets.length,
        itemBuilder: (context, index) {
          if (index < headerWidgets.length) return headerWidgets[index];
          final book = _books[index - headerWidgets.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BookResultTile(
              item: book,
              serverUrl: widget.serverUrl,
              token: widget.token,
            ),
          );
        },
      );
    }

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverList(delegate: SliverChildListDelegate(headerWidgets)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
          sliver: SliverGrid(
            gridDelegate: sheetBookGridDelegate(context),
            delegate: SliverChildBuilderDelegate(
              (_, i) => GridBookTile(item: _books[i]),
              childCount: _books.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    return sheetPersonHeader(
      context,
      avatar: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.tertiaryContainer,
        ),
        child: Center(
          child: Icon(Icons.mic_rounded,
              size: 36, color: cs.onTertiaryContainer.withValues(alpha: 0.7)),
        ),
      ),
      title: widget.narratorName,
      subtitle: _books.isNotEmpty ? l.authorBooksBookCount(_books.length) : null,
    );
  }
}
