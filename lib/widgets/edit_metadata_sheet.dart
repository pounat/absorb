import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';

/// Opens a full-screen editor for a library item's metadata (admin only).
/// Has two tabs: Quick Match (search providers) and Custom (manual fields).
void showEditMetadataSheet(
  BuildContext context, {
  required String itemId,
  required Map<String, dynamic> metadata,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      snap: true,
      builder: (ctx, sc) => _EditMetadataContent(
        itemId: itemId,
        metadata: metadata,
        scrollController: sc,
      ),
    ),
  );
}

class _EditMetadataContent extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> metadata;
  final ScrollController scrollController;

  const _EditMetadataContent({
    required this.itemId,
    required this.metadata,
    required this.scrollController,
  });

  @override
  State<_EditMetadataContent> createState() => _EditMetadataContentState();
}

class _EditMetadataContentState extends State<_EditMetadataContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Custom edit controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _narratorCtrl;
  final List<({TextEditingController name, TextEditingController seq})> _seriesRows = [];
  late final TextEditingController _descCtrl;
  late final TextEditingController _publisherCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _genresCtrl;
  late final TextEditingController _asinCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _coverUrlCtrl;

  // Quick match
  late final TextEditingController _searchTitleCtrl;
  late final TextEditingController _searchAuthorCtrl;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _provider = 'audible';
  static const _providerKeys = ['audible', 'itunes', 'openlibrary'];

  String _providerLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'audible': return l.audible;
      case 'itunes': return l.iTunes;
      case 'openlibrary': return l.openLibrary;
    }
    return key;
  }

  String? _coverFilePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final m = widget.metadata;
    _titleCtrl = TextEditingController(text: m['title'] as String? ?? '');
    _subtitleCtrl = TextEditingController(text: m['subtitle'] as String? ?? '');
    _authorCtrl = TextEditingController(text: m['authorName'] as String? ?? '');
    _narratorCtrl = TextEditingController(text: m['narratorName'] as String? ?? '');
    _descCtrl = TextEditingController(text: m['description'] as String? ?? '');
    _publisherCtrl = TextEditingController(text: m['publisher'] as String? ?? '');
    _yearCtrl = TextEditingController(text: m['publishedYear'] as String? ?? '');
    _asinCtrl = TextEditingController(text: m['asin'] as String? ?? '');
    _isbnCtrl = TextEditingController(text: m['isbn'] as String? ?? '');
    _languageCtrl = TextEditingController(text: m['language'] as String? ?? '');
    _coverUrlCtrl = TextEditingController();

    final series = m['series'] as List<dynamic>? ?? [];
    for (final s in series) {
      if (s is Map<String, dynamic>) {
        _seriesRows.add((
          name: TextEditingController(text: s['name'] as String? ?? ''),
          seq: TextEditingController(text: s['sequence'] as String? ?? ''),
        ));
      }
    }
    if (_seriesRows.isEmpty) {
      _seriesRows.add((name: TextEditingController(), seq: TextEditingController()));
    }

    final genres = (m['genres'] as List<dynamic>?)?.cast<String>() ?? [];
    _genresCtrl = TextEditingController(text: genres.join(', '));

    // Search fields default to current title/author
    _searchTitleCtrl = TextEditingController(text: m['title'] as String? ?? '');
    _searchAuthorCtrl = TextEditingController(text: m['authorName'] as String? ?? '');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _authorCtrl.dispose();
    _narratorCtrl.dispose();
    for (final row in _seriesRows) {
      row.name.dispose();
      row.seq.dispose();
    }
    _descCtrl.dispose();
    _publisherCtrl.dispose();
    _yearCtrl.dispose();
    _genresCtrl.dispose();
    _asinCtrl.dispose();
    _isbnCtrl.dispose();
    _languageCtrl.dispose();
    _coverUrlCtrl.dispose();
    _searchTitleCtrl.dispose();
    _searchAuthorCtrl.dispose();
    super.dispose();
  }

  // ─── Quick Match ────────────────────────────────────────────

  Future<void> _doSearch() async {
    final title = _searchTitleCtrl.text.trim();
    if (title.isEmpty) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;

    setState(() { _isSearching = true; _hasSearched = true; });

    final results = await api.searchBooks(
      title: title,
      author: _searchAuthorCtrl.text.trim(),
      provider: _provider,
    );

    if (mounted) {
      setState(() { _searchResults = results; _isSearching = false; });
    }
  }

  Future<void> _applyMatch(Map<String, dynamic> result) async {
    final book = result['book'] as Map<String, dynamic>? ?? result;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;

    final update = <String, dynamic>{};

    void add(String key, dynamic value) {
      final s = _safeString(value);
      if (s.isNotEmpty) update[key] = s;
    }

    add('title', book['title']);
    add('subtitle', book['subtitle']);
    add('description', book['description']);
    add('publisher', book['publisher']);
    add('publishedYear', book['publishedYear'] ?? book['publishedDate']);
    add('asin', book['asin']);
    add('isbn', book['isbn']);
    add('language', book['language']);

    // Authors/narrators are arrays in ABS
    final authorStr = _safeString(book['author']).isNotEmpty
        ? _safeString(book['author'])
        : _safeString(book['authorName']);
    if (authorStr.isNotEmpty) {
      update['authors'] = authorStr.split(',').map((a) => {'name': a.trim()}).where((a) => (a['name'] as String).isNotEmpty).toList();
    }

    final narratorStr = _safeString(book['narrator']).isNotEmpty
        ? _safeString(book['narrator'])
        : _safeString(book['narratorName']);
    if (narratorStr.isNotEmpty) {
      update['narrators'] = narratorStr.split(',').map((n) => {'name': n.trim()}).where((n) => (n['name'] as String).isNotEmpty).toList();
    }

    // Genres
    final genres = book['genres'] ?? book['tags'];
    if (genres is List && genres.isNotEmpty) {
      update['genres'] = genres.whereType<String>().toList();
    }

    // Series
    final series = book['series'];
    if (series is List && series.isNotEmpty) {
      update['series'] = series;
    } else if (series is String && series.isNotEmpty) {
      update['series'] = [
        {'name': series, 'sequence': _safeString(book['volumeNumber'] ?? book['sequence'])}
      ];
    }

    setState(() => _saving = true);

    bool ok = await api.updateItemMedia(widget.itemId, update);

    // Cover
    final coverUrl = _safeString(book['cover']).isNotEmpty
        ? _safeString(book['cover'])
        : _safeString(book['image']);
    if (ok && coverUrl.isNotEmpty) {
      await api.updateItemCoverUrl(widget.itemId, coverUrl);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final l = AppLocalizations.of(context)!;
    if (ok) {
      context.read<LibraryProvider>().refresh();
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(l.editMetadataUpdatedFromMatch),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(l.failedToUpdateMetadata),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
    }
  }

  void _confirmMatch(Map<String, dynamic> result) {
    final book = result['book'] as Map<String, dynamic>? ?? result;
    final title = _safeString(book['title']);
    final author = _safeString(book['author']).isNotEmpty
        ? _safeString(book['author'])
        : _safeString(book['authorName']);
    final l = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.applyThisMatch),
        content: Text(author.isNotEmpty
            ? l.editMetadataConfirmMatchWithAuthor(title, author)
            : l.editMetadataConfirmMatch(title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () { Navigator.pop(ctx); _applyMatch(result); }, child: Text(l.apply)),
        ],
      ),
    );
  }

  // ─── Custom Save ────────────────────────────────────────────

  Future<void> _saveCustom() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;

    setState(() => _saving = true);

    final update = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'subtitle': _subtitleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'publisher': _publisherCtrl.text.trim(),
      'publishedYear': _yearCtrl.text.trim(),
      'asin': _asinCtrl.text.trim(),
      'isbn': _isbnCtrl.text.trim(),
      'language': _languageCtrl.text.trim(),
    };

    // Authors/narrators are arrays in ABS, not simple strings
    final authorText = _authorCtrl.text.trim();
    if (authorText.isNotEmpty) {
      update['authors'] = authorText.split(',').map((a) => {'name': a.trim()}).where((a) => (a['name'] as String).isNotEmpty).toList();
    } else {
      update['authors'] = <Map<String, dynamic>>[];
    }

    final narratorText = _narratorCtrl.text.trim();
    if (narratorText.isNotEmpty) {
      update['narrators'] = narratorText.split(',').map((n) => {'name': n.trim()}).where((n) => (n['name'] as String).isNotEmpty).toList();
    } else {
      update['narrators'] = <Map<String, dynamic>>[];
    }

    final genresText = _genresCtrl.text.trim();
    update['genres'] = genresText.isNotEmpty
        ? genresText.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList()
        : <String>[];

    final seriesList = <Map<String, dynamic>>[];
    for (final row in _seriesRows) {
      final name = row.name.text.trim();
      if (name.isNotEmpty) {
        seriesList.add({'name': name, 'sequence': row.seq.text.trim()});
      }
    }
    update['series'] = seriesList;

    bool ok = await api.updateItemMedia(widget.itemId, update);

    if (ok && _coverFilePath != null) {
      ok = await api.uploadItemCover(widget.itemId, _coverFilePath!);
    } else if (ok && _coverUrlCtrl.text.trim().isNotEmpty) {
      ok = await api.updateItemCoverUrl(widget.itemId, _coverUrlCtrl.text.trim());
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final l = AppLocalizations.of(context)!;
    if (ok) {
      context.read<LibraryProvider>().refresh();
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(l.metadataUpdated),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(l.failedToUpdateMetadata),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
    }
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _coverFilePath = result.files.single.path;
        _coverUrlCtrl.clear();
      });
    }
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) return value.whereType<String>().join(', ');
    return value.toString();
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Drag pill
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text(l.editDetails, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_saving)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
        ),
        const SizedBox(height: 8),

        // Tabs
        TabBar(
          controller: _tabCtrl,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: [
            Tab(text: l.quickMatch),
            Tab(text: l.custom),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildQuickMatchTab(cs, tt, l),
              _buildCustomTab(cs, tt, l),
            ],
          ),
        ),
      ]),
    );
  }

  // ─── Quick Match Tab ────────────────────────────────────────

  Widget _buildQuickMatchTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(children: [
          _searchField(_searchTitleCtrl, l.title, Icons.book_rounded, cs, tt),
          const SizedBox(height: 8),
          _searchField(_searchAuthorCtrl, l.authorOptionalLabel, Icons.person_rounded, cs, tt),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _provider,
                    isExpanded: true,
                    dropdownColor: cs.surfaceContainerHigh,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    icon: Icon(Icons.expand_more_rounded, size: 18, color: cs.onSurfaceVariant),
                    items: _providerKeys.map((k) => DropdownMenuItem(value: k, child: Text(_providerLabel(l, k)))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _provider = v); },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: _isSearching ? null : _doSearch,
                icon: _isSearching
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                    : const Icon(Icons.search_rounded, size: 18),
                label: Text(l.search),
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Divider(color: cs.onSurface.withValues(alpha: 0.08), height: 1),
      Expanded(
        child: _isSearching
            ? ListView(controller: widget.scrollController, children: [
                const SizedBox(height: 80),
                Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurfaceVariant)),
              ])
            : _searchResults.isEmpty
                ? ListView(controller: widget.scrollController, children: [
                    const SizedBox(height: 80),
                    Center(child: Text(
                      _hasSearched ? l.noResultsFound : l.searchForMetadataAbove,
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    )),
                  ])
                : ListView.separated(
                    controller: widget.scrollController,
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildResultCard(_searchResults[i], cs, tt, l),
                  ),
      ),
    ]);
  }

  Widget _searchField(TextEditingController ctrl, String label, IconData icon, ColorScheme cs, TextTheme tt) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: ctrl,
        onSubmitted: (_) => _doSearch(),
        textInputAction: TextInputAction.search,
        style: tt.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          filled: true,
          fillColor: cs.onSurface.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5))),
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final book = result['book'] as Map<String, dynamic>? ?? result;
    final title = _safeString(book['title']);
    final author = _safeString(book['author']).isNotEmpty ? _safeString(book['author']) : _safeString(book['authorName']);
    final narrator = _safeString(book['narrator']).isNotEmpty ? _safeString(book['narrator']) : _safeString(book['narratorName']);
    final desc = _safeString(book['description']).replaceAll(RegExp(r'<[^>]*>'), '').trim();
    final cover = _safeString(book['cover']).isNotEmpty ? _safeString(book['cover']) : _safeString(book['image']);
    final year = _safeString(book['publishedYear']).isNotEmpty ? _safeString(book['publishedYear']) : _safeString(book['publishedDate']);
    final publisher = _safeString(book['publisher']);
    final series = _safeString(book['series']);

    return Card(
      elevation: 0,
      color: cs.onSurface.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _confirmMatch(result),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60, height: 60,
                child: cover.isNotEmpty
                    ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(cs),
                        errorWidget: (_, __, ___) => _placeholder(cs))
                    : _placeholder(cs),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (author.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(author, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
              if (narrator.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(l.narratedBy(narrator), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
              ],
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (year.isNotEmpty) _miniChip(cs, Icons.calendar_today_rounded, year),
                if (publisher.isNotEmpty) _miniChip(cs, Icons.business_rounded, publisher),
                if (series.isNotEmpty) _miniChip(cs, Icons.auto_stories_rounded, series),
              ]),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5), height: 1.3)),
              ],
            ])),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(child: Icon(Icons.headphones_rounded, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
    );
  }

  Widget _miniChip(ColorScheme cs, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        const SizedBox(width: 3),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1,
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10))),
      ]),
    );
  }

  // ─── Custom Tab ─────────────────────────────────────────────

  Widget _buildCustomTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Column(children: [
      // Save button bar
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
        child: Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: _saving ? null : _saveCustom,
            icon: _saving
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(l.save),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom),
          children: [
            _field(l.titleLabel, _titleCtrl, tt),
            _field(l.subtitleLabel, _subtitleCtrl, tt),
            _field(l.authorLabel, _authorCtrl, tt),
            _field(l.narratorLabel, _narratorCtrl, tt),
            for (int i = 0; i < _seriesRows.length; i++)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _field(l.seriesLabel, _seriesRows[i].name, tt)),
                const SizedBox(width: 12),
                SizedBox(width: 80, child: _field('#', _seriesRows[i].seq, tt)),
                IconButton(
                  tooltip: l.removeSeries,
                  onPressed: _seriesRows.length == 1 && _seriesRows[i].name.text.isEmpty && _seriesRows[i].seq.text.isEmpty
                      ? null
                      : () => setState(() {
                          if (_seriesRows.length == 1) {
                            _seriesRows[i].name.clear();
                            _seriesRows[i].seq.clear();
                          } else {
                            final removed = _seriesRows.removeAt(i);
                            removed.name.dispose();
                            removed.seq.dispose();
                          }
                        }),
                  icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: cs.onSurfaceVariant),
                  padding: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(),
                ),
              ]),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _seriesRows.add((name: TextEditingController(), seq: TextEditingController()));
                  }),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l.addSeries),
                ),
              ),
            ),
            _field(l.descriptionLabel, _descCtrl, tt, maxLines: 5),
            _field(l.publisherLabel, _publisherCtrl, tt),
            Row(children: [
              Expanded(child: _field(l.yearLabel, _yearCtrl, tt, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field(l.languageLabel, _languageCtrl, tt)),
            ]),
            _field(l.genresLabel, _genresCtrl, tt, hint: l.commaSeparated),
            Row(children: [
              Expanded(child: _field(l.asinLabel, _asinCtrl, tt)),
              const SizedBox(width: 12),
              Expanded(child: _field(l.isbnLabel, _isbnCtrl, tt)),
            ]),

            const SizedBox(height: 20),
            Text(l.coverImage, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _coverUrlCtrl,
                  decoration: InputDecoration(
                    labelText: l.coverUrlLabel,
                    hintText: l.coverUrlHint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  style: tt.bodyMedium,
                  onChanged: (_) => setState(() => _coverFilePath = null),
                ),
              ),
              const SizedBox(width: 8),
              Text(l.or, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _pickCoverImage,
                icon: const Icon(Icons.image_rounded, size: 18),
                label: Text(l.file),
              ),
            ]),
            if (_coverFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    _coverFilePath!.split('/').last.split('\\').last,
                    style: tt.labelSmall?.copyWith(color: cs.primary),
                    overflow: TextOverflow.ellipsis,
                  )),
                  GestureDetector(
                    onTap: () => setState(() => _coverFilePath = null),
                    child: Icon(Icons.close_rounded, size: 16, color: cs.onSurfaceVariant),
                  ),
                ]),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _field(String label, TextEditingController ctrl, TextTheme tt, {int maxLines = 1, String? hint, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        style: tt.bodyMedium,
      ),
    );
  }
}
