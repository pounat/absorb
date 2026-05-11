import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import 'library_grid_tiles.dart';
import 'library_search_results.dart';
import 'stackable_sheet.dart';

enum _NarratorLayout { list, grid }

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
  _NarratorLayout _layout = _NarratorLayout.list;

  @override
  void initState() {
    super.initState();
    _loadViewSettings();
    _loadBooks();
  }

  Future<void> _loadViewSettings() async {
    final grid = await PlayerSettings.getSheetGridView();
    if (mounted) setState(() {
      _layout = grid ? _NarratorLayout.grid : _NarratorLayout.list;
    });
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

    final lib = context.read<LibraryProvider>();
    final books = raw.whereType<Map<String, dynamic>>().toList();
    for (final book in books) {
      final id = book['id'] as String?;
      final bts = book['updatedAt'] as num?;
      if (id != null && bts != null) lib.registerUpdatedAt(id, bts.toInt());
      if (id != null) {
        final coverPath = (book['media'] as Map<String, dynamic>?)?['coverPath'] as String?;
        lib.registerHasCover(id, coverPath != null && coverPath.isNotEmpty);
      }
    }

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final bottomPad = 24 + MediaQuery.of(context).viewPadding.bottom;

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(cs, tt, l),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    final headerWidgets = <Widget>[
      _buildHeader(cs, tt, l),
      if (_books.isNotEmpty) _buildViewModeBar(cs, l),
    ];

    if (_books.isEmpty) {
      return ListView(
        controller: widget.scrollController,
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

    if (_layout == _NarratorLayout.list) {
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (MediaQuery.of(context).size.width / 130).floor().clamp(3, 10),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.55,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => GridBookTile(item: _books[i]),
              childCount: _books.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeBar(ColorScheme cs, AppLocalizations l) {
    Widget layoutBtn(IconData icon, _NarratorLayout mode, String tooltip) {
      final active = _layout == mode;
      return IconButton(
        icon: Icon(icon, size: 20, color: active ? cs.primary : cs.onSurfaceVariant),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: () {
          setState(() => _layout = mode);
          PlayerSettings.setSheetGridView(mode == _NarratorLayout.grid);
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          const Spacer(),
          layoutBtn(Icons.view_list_rounded, _NarratorLayout.list, l.authorBooksList),
          layoutBtn(Icons.apps_rounded, _NarratorLayout.grid, l.authorBooksGrid),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(widget.narratorName,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (_books.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l.authorBooksBookCount(_books.length),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
