import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/metadata_override_service.dart';
import 'overlay_toast.dart';

/// Bottom sheet that lets users search for book metadata via the ABS server
/// and pick a result to store as a local override, or manually edit fields.
class MetadataLookupSheet extends StatefulWidget {
  final String itemId;
  final ApiService api;
  final String initialTitle;
  final String initialAuthor;
  final VoidCallback onApplied;
  /// Current metadata so the Custom tab can pre-fill fields.
  final Map<String, dynamic>? currentMetadata;
  final ScrollController? scrollController;

  const MetadataLookupSheet({
    super.key,
    required this.itemId,
    required this.api,
    required this.initialTitle,
    required this.initialAuthor,
    required this.onApplied,
    this.currentMetadata,
    this.scrollController,
  });

  @override
  State<MetadataLookupSheet> createState() => _MetadataLookupSheetState();
}

class _MetadataLookupSheetState extends State<MetadataLookupSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Search tab
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _provider = 'audible';
  Timer? _debounce;

  // Custom tab
  late final TextEditingController _cTitleCtrl;
  late final TextEditingController _cAuthorCtrl;
  late final TextEditingController _cNarratorCtrl;
  late final TextEditingController _cDescCtrl;
  late final TextEditingController _cPublisherCtrl;
  late final TextEditingController _cYearCtrl;
  late final TextEditingController _cGenresCtrl;
  late final TextEditingController _cSeriesCtrl;
  late final TextEditingController _cSeriesSeqCtrl;
  late final TextEditingController _cAsinCtrl;
  late final TextEditingController _cIsbnCtrl;
  late final TextEditingController _cCoverUrlCtrl;

  static const _providers = [
    ('audible', 'Audible'),
    ('itunes', 'iTunes'),
    ('openlibrary', 'Open Library'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _titleController.text = widget.initialTitle;
    _authorController.text = widget.initialAuthor;

    // Pre-fill custom fields from current metadata
    final m = widget.currentMetadata ?? {};
    _cTitleCtrl = TextEditingController(text: m['title'] as String? ?? '');
    _cAuthorCtrl = TextEditingController(text: m['authorName'] as String? ?? '');
    _cNarratorCtrl = TextEditingController(text: m['narratorName'] as String? ?? '');
    _cDescCtrl = TextEditingController(text: m['description'] as String? ?? '');
    _cPublisherCtrl = TextEditingController(text: m['publisher'] as String? ?? '');
    _cYearCtrl = TextEditingController(text: m['publishedYear'] as String? ?? '');
    _cAsinCtrl = TextEditingController(text: m['asin'] as String? ?? '');
    _cIsbnCtrl = TextEditingController(text: m['isbn'] as String? ?? '');
    _cCoverUrlCtrl = TextEditingController();

    final series = m['series'] as List<dynamic>? ?? [];
    if (series.isNotEmpty) {
      final first = series[0] as Map<String, dynamic>;
      _cSeriesCtrl = TextEditingController(text: first['name'] as String? ?? '');
      _cSeriesSeqCtrl = TextEditingController(text: first['sequence'] as String? ?? '');
    } else {
      _cSeriesCtrl = TextEditingController();
      _cSeriesSeqCtrl = TextEditingController();
    }

    final genres = (m['genres'] as List<dynamic>?)?.cast<String>() ?? [];
    _cGenresCtrl = TextEditingController(text: genres.join(', '));

    // Auto-search on open
    if (widget.initialTitle.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), _doSearch);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _debounce?.cancel();
    _titleController.dispose();
    _authorController.dispose();
    _cTitleCtrl.dispose();
    _cAuthorCtrl.dispose();
    _cNarratorCtrl.dispose();
    _cDescCtrl.dispose();
    _cPublisherCtrl.dispose();
    _cYearCtrl.dispose();
    _cGenresCtrl.dispose();
    _cSeriesCtrl.dispose();
    _cSeriesSeqCtrl.dispose();
    _cAsinCtrl.dispose();
    _cIsbnCtrl.dispose();
    _cCoverUrlCtrl.dispose();
    super.dispose();
  }

  // ─── Search ─────────────────────────────────────────────────

  Future<void> _doSearch() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() { _isSearching = true; _hasSearched = true; });

    final results = await widget.api.searchBooks(
      title: title,
      author: _authorController.text.trim(),
      provider: _provider,
    );

    if (mounted) {
      setState(() { _results = results; _isSearching = false; });
    }
  }

  // ─── Apply search result with field picker ──────────────────

  void _showFieldPicker(Map<String, dynamic> result) {
    final book = result['book'] as Map<String, dynamic>? ?? result;
    final l = AppLocalizations.of(context)!;

    // Build available fields from the result
    final fields = <String, String>{};
    void tryAdd(String key, dynamic value) {
      final s = _safeString(value);
      if (s.isNotEmpty) fields[key] = s;
    }

    tryAdd('title', book['title']);
    tryAdd('author', book['author'] ?? book['authorName']);
    tryAdd('narrator', book['narrator'] ?? book['narratorName']);
    tryAdd('description', book['description']);
    tryAdd('publisher', book['publisher']);
    tryAdd('publishedYear', book['publishedYear'] ?? book['publishedDate']);
    tryAdd('asin', book['asin']);
    tryAdd('isbn', book['isbn']);

    final coverUrl = _safeString(book['cover']).isNotEmpty
        ? _safeString(book['cover'])
        : _safeString(book['image']);
    if (coverUrl.isNotEmpty) fields['coverUrl'] = coverUrl;

    final genres = book['genres'] ?? book['tags'];
    if (genres is List && genres.isNotEmpty) {
      fields['genres'] = genres.whereType<String>().join(', ');
    }

    final series = book['series'];
    if (series is String && series.isNotEmpty) {
      fields['series'] = series;
    } else if (series is List && series.isNotEmpty) {
      final first = series[0];
      if (first is Map) fields['series'] = first['name']?.toString() ?? '';
    }

    // All fields selected by default
    final selected = Set<String>.from(fields.keys);

    final labels = {
      'title': l.titleLabel,
      'author': l.authorLabel,
      'narrator': l.narratorLabel,
      'description': l.descriptionLabel,
      'publisher': l.publisherLabel,
      'publishedYear': l.yearLabel,
      'asin': l.asinLabel,
      'isbn': l.isbnLabel,
      'coverUrl': l.metadataLookupCover,
      'genres': l.genresLabel,
      'series': l.seriesLabel,
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;
          return AlertDialog(
            title: Text(l.metadataLookupChooseFields),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: fields.entries.map((e) {
                  final label = labels[e.key] ?? e.key;
                  final preview = e.value.length > 60
                      ? '${e.value.replaceAll(RegExp(r'<[^>]*>'), '').substring(0, 57)}...'
                      : e.value.replaceAll(RegExp(r'<[^>]*>'), '');
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    value: selected.contains(e.key),
                    onChanged: (v) => setDialogState(() {
                      if (v == true) selected.add(e.key); else selected.remove(e.key);
                    }),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              FilledButton(
                onPressed: selected.isEmpty ? null : () {
                  Navigator.pop(ctx);
                  _applySelectedFields(result, selected);
                },
                child: Text(l.metadataLookupApplyFields(selected.length)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showSavedToastAndClose(String message) {
    showOverlayToast(context, message,
        icon: Icons.check_circle_outline_rounded);
    Navigator.pop(context);
  }

  Future<void> _applySelectedFields(Map<String, dynamic> result, Set<String> selected) async {
    final book = result['book'] as Map<String, dynamic>? ?? result;
    final override = <String, dynamic>{};

    void addIfSelected(String key, dynamic value) {
      if (!selected.contains(key)) return;
      final s = _safeString(value);
      if (s.isNotEmpty) override[key] = s;
    }

    addIfSelected('title', book['title']);
    addIfSelected('author', book['author'] ?? book['authorName']);
    addIfSelected('narrator', book['narrator'] ?? book['narratorName']);
    addIfSelected('description', book['description']);
    addIfSelected('publisher', book['publisher']);
    addIfSelected('publishedYear', book['publishedYear'] ?? book['publishedDate']);
    addIfSelected('asin', book['asin']);
    addIfSelected('isbn', book['isbn']);

    if (selected.contains('coverUrl')) {
      final coverRaw = book['cover'] ?? book['image'];
      if (coverRaw is String && coverRaw.isNotEmpty) {
        override['coverUrl'] = coverRaw;
      }
    }

    if (selected.contains('genres')) {
      final genres = book['genres'] ?? book['tags'];
      if (genres is List && genres.isNotEmpty) {
        override['genres'] = genres;
      }
    }

    if (selected.contains('series')) {
      final series = book['series'];
      if (series is List && series.isNotEmpty) {
        override['series'] = series;
      } else if (series is String && series.isNotEmpty) {
        override['series'] = [
          {'name': series, 'sequence': _safeString(book['volumeNumber'] ?? book['sequence'])}
        ];
      }
    }

    await MetadataOverrideService().save(widget.itemId, override);

    if (mounted) {
      final l = AppLocalizations.of(context)!;
      widget.onApplied();
      _showSavedToastAndClose(
          l.metadataLookupFieldsSavedLocally(selected.length));
    }
  }

  // ─── Custom save ────────────────────────────────────────────

  Future<void> _saveCustom() async {
    final override = <String, dynamic>{};

    void addIfNotEmpty(String key, String value) {
      if (value.isNotEmpty) override[key] = value;
    }

    addIfNotEmpty('title', _cTitleCtrl.text.trim());
    addIfNotEmpty('author', _cAuthorCtrl.text.trim());
    addIfNotEmpty('narrator', _cNarratorCtrl.text.trim());
    addIfNotEmpty('description', _cDescCtrl.text.trim());
    addIfNotEmpty('publisher', _cPublisherCtrl.text.trim());
    addIfNotEmpty('publishedYear', _cYearCtrl.text.trim());
    addIfNotEmpty('asin', _cAsinCtrl.text.trim());
    addIfNotEmpty('isbn', _cIsbnCtrl.text.trim());
    addIfNotEmpty('coverUrl', _cCoverUrlCtrl.text.trim());

    final genresText = _cGenresCtrl.text.trim();
    if (genresText.isNotEmpty) {
      override['genres'] = genresText.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList();
    }

    final seriesName = _cSeriesCtrl.text.trim();
    if (seriesName.isNotEmpty) {
      override['series'] = [
        {'name': seriesName, 'sequence': _cSeriesSeqCtrl.text.trim()},
      ];
    }

    if (override.isEmpty) return;

    await MetadataOverrideService().save(widget.itemId, override);

    if (mounted) {
      final l = AppLocalizations.of(context)!;
      widget.onApplied();
      _showSavedToastAndClose(l.metadataSavedLocally);
    }
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Drag handle
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
          decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(children: [
            Icon(Icons.manage_search_rounded, size: 22, color: cs.primary),
            const SizedBox(width: 8),
            Text(l.localMetadata, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
          ]),
        ),

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
              _buildSearchTab(cs, tt, l),
              _buildCustomTab(cs, tt, l),
            ],
          ),
        ),
      ]),
    );
  }

  // ─── Search Tab ─────────────────────────────────────────────

  Widget _buildSearchTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(children: [
          _buildField(controller: _titleController, label: l.titleLabel, icon: Icons.book_rounded, cs: cs, onSubmitted: (_) => _doSearch()),
          const SizedBox(height: 8),
          _buildField(controller: _authorController, label: l.authorOptionalLabel, icon: Icons.person_rounded, cs: cs, onSubmitted: (_) => _doSearch()),
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
                    style: tt.bodySmall?.copyWith(color: cs.onSurface),
                    icon: Icon(Icons.expand_more_rounded, size: 18, color: cs.onSurfaceVariant),
                    items: _providers.map((p) => DropdownMenuItem(value: p.$1, child: Text(p.$2))).toList(),
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
                Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
              ])
            : _results.isEmpty
                ? ListView(controller: widget.scrollController, children: [
                    const SizedBox(height: 80),
                    Center(child: Text(
                      _hasSearched ? l.noResultsFound : l.searchForMetadataAbove,
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    )),
                  ])
                : ListView.separated(
                    controller: widget.scrollController,
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildResultCard(_results[i], cs, tt, l),
                  ),
      ),
    ]);
  }

  // ─── Custom Tab ─────────────────────────────────────────────

  Widget _buildCustomTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
        child: Row(children: [
          Text(l.metadataLookupOverrideLocalDisplay, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const Spacer(),
          FilledButton.icon(
            onPressed: _saveCustom,
            icon: const Icon(Icons.check_rounded, size: 18),
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
            _customField(l.titleLabel, _cTitleCtrl, tt, cs),
            _customField(l.authorLabel, _cAuthorCtrl, tt, cs),
            _customField(l.narratorLabel, _cNarratorCtrl, tt, cs),
            Row(children: [
              Expanded(child: _customField(l.seriesLabel, _cSeriesCtrl, tt, cs)),
              const SizedBox(width: 12),
              SizedBox(width: 80, child: _customField('#', _cSeriesSeqCtrl, tt, cs)),
            ]),
            _customField(l.descriptionLabel, _cDescCtrl, tt, cs, maxLines: 4),
            _customField(l.publisherLabel, _cPublisherCtrl, tt, cs),
            Row(children: [
              Expanded(child: _customField(l.yearLabel, _cYearCtrl, tt, cs)),
              const SizedBox(width: 12),
              Expanded(child: _customField(l.asinLabel, _cAsinCtrl, tt, cs)),
            ]),
            Row(children: [
              Expanded(child: _customField(l.isbnLabel, _cIsbnCtrl, tt, cs)),
              const SizedBox(width: 12),
              Expanded(child: _customField(l.genresLabel, _cGenresCtrl, tt, cs, hint: l.commaSeparated)),
            ]),
            _customField(l.coverUrlLabel, _cCoverUrlCtrl, tt, cs, hint: l.coverUrlHint),
          ],
        ),
      ),
    ]);
  }

  Widget _customField(String label, TextEditingController ctrl, TextTheme tt, ColorScheme cs, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
          filled: true,
          fillColor: cs.onSurface.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5))),
        ),
      ),
    );
  }

  // ─── Shared widgets ─────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme cs,
    void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: cs.onSurfaceVariant),
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

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) return value.whereType<String>().join(', ');
    return value.toString();
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
        onTap: () => _showFieldPicker(result),
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
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              if (author.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(author, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
              if (narrator.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(l.narratedBy(narrator), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (year.isNotEmpty) _miniChip(Icons.calendar_today_rounded, year, cs),
                if (publisher.isNotEmpty) _miniChip(Icons.business_rounded, publisher, cs),
                if (series.isNotEmpty) _miniChip(Icons.auto_stories_rounded, series, cs),
              ]),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7), height: 1.3)),
              ],
            ])),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
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

  Widget _miniChip(IconData icon, String text, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: cs.onSurfaceVariant),
        const SizedBox(width: 3),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10))),
      ]),
    );
  }
}
