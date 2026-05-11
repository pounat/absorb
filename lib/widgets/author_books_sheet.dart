import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'overlay_toast.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import 'edit_author_sheet.dart';
import 'library_grid_tiles.dart';
import 'library_search_results.dart';
import 'series_books_sheet.dart';
import 'stackable_sheet.dart';

enum _AuthorLayout { list, grid }

/// Show a bottom sheet with author info and books.
void showAuthorDetailSheet(BuildContext context, {
  required String authorId,
  required String authorName,
}) {
  final auth = context.read<AuthProvider>();
  final lib = context.read<LibraryProvider>();
  showStackableSheet(
    context: context,
    showHandle: true,
    builder: (ctx, scrollController) => AuthorBooksSheet(
      libraryId: lib.selectedLibraryId ?? '',
      authorId: authorId,
      authorName: authorName,
      serverUrl: auth.serverUrl,
      token: auth.token,
      scrollController: scrollController,
    ),
  );
}

class AuthorBooksSheet extends StatefulWidget {
  final String libraryId;
  final String authorId;
  final String authorName;
  final String? serverUrl;
  final String? token;
  final ScrollController scrollController;

  const AuthorBooksSheet({
    super.key,
    required this.libraryId,
    required this.authorId,
    required this.authorName,
    required this.serverUrl,
    required this.token,
    required this.scrollController,
  });

  @override
  State<AuthorBooksSheet> createState() => _AuthorBooksSheetState();
}

class _AuthorBooksSheetState extends State<AuthorBooksSheet> {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  String? _description;
  String? _imageUrl;
  String? _asin;
  late String _displayName;
  bool _descExpanded = false;
  _AuthorLayout _layout = _AuthorLayout.list;
  bool _groupBySeries = true;

  @override
  void initState() {
    super.initState();
    _displayName = widget.authorName;
    _loadViewSettings();
    _loadAuthorAndBooks();
  }

  Future<void> _loadViewSettings() async {
    final grid = await PlayerSettings.getSheetGridView();
    final collapse = await PlayerSettings.getSheetCollapseSeries();
    if (mounted) setState(() {
      _layout = grid ? _AuthorLayout.grid : _AuthorLayout.list;
      _groupBySeries = collapse;
    });
  }

  Future<void> _loadAuthorAndBooks() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final authorData = await api.getAuthorById(widget.authorId, libraryId: widget.libraryId);

    if (mounted) {
      setState(() {
        if (authorData != null) {
          _description = authorData['description'] as String?;
          _asin = authorData['asin'] as String?;
          final updatedName = authorData['name'] as String?;
          if (updatedName != null && updatedName.isNotEmpty) _displayName = updatedName;
          if (authorData['imagePath'] != null && (authorData['imagePath'] as String).isNotEmpty) {
            final ts = (authorData['updatedAt'] as num?)?.toInt();
            _imageUrl = api.getAuthorImageUrl(widget.authorId, updatedAt: ts);
          } else {
            _imageUrl = null;
          }
          // libraryItems from the author endpoint include full metadata with series info
          final rawItems = authorData['libraryItems'] as List<dynamic>? ?? [];
          _books = rawItems.whereType<Map<String, dynamic>>().toList();
          // Register updatedAt for cover cache busting
          final lib = context.read<LibraryProvider>();
          for (final book in _books) {
            final id = book['id'] as String?;
            final bts = book['updatedAt'] as num?;
            if (id != null && bts != null) lib.registerUpdatedAt(id, bts.toInt());
            if (id != null) {
              final coverPath = (book['media'] as Map<String, dynamic>?)?['coverPath'] as String?;
              lib.registerHasCover(id, coverPath != null && coverPath.isNotEmpty);
            }
          }
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.read<LibraryProvider>();
    final auth = context.watch<AuthProvider>();
    final headers = lib.mediaHeaders;
    final canEdit = auth.isRoot && !lib.isOffline;

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(cs, tt, headers, l, canEdit: canEdit),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    final bottomPad = 24 + MediaQuery.of(context).viewPadding.bottom;
    final hasDesc = _description != null && _description!.isNotEmpty;
    final sections = _buildSections(l);

    // Header + description are always at the top
    final headerWidgets = <Widget>[
      _buildHeader(cs, tt, headers, l, canEdit: canEdit),
      if (hasDesc) _buildDescription(cs, tt, l),
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

    if (_layout == _AuthorLayout.list) {
      return _buildListView(cs, tt, lib, sections, headerWidgets, bottomPad, l);
    }
    return _buildGridView(cs, tt, lib, sections, headerWidgets, bottomPad, l);
  }

  List<_BookSection> _buildSections(AppLocalizations l) {
    final seriesMap = <String, _BookSection>{};
    final standalones = <Map<String, dynamic>>[];

    for (final book in _books) {
      final media = book['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final seriesNameRaw = metadata['seriesName'] as String? ?? '';

      // Split comma-separated series entries like "Mistborn #3, Cosmere #6"
      final entries = seriesNameRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      bool addedToSeries = false;

      // Also try to get series ID from the structured series list
      final seriesList = metadata['series'] as List<dynamic>? ?? [];

      for (final entry in entries) {
        final name = entry.replaceFirst(RegExp(r'\s*#\s*[\d.]+$'), '').trim();
        if (name.isEmpty) continue;
        // Try to find the series ID from the structured data
        String? sid;
        for (final s in seriesList) {
          if (s is Map<String, dynamic> && (s['name'] as String? ?? '').toLowerCase() == name.toLowerCase()) {
            sid = s['id'] as String?;
            break;
          }
        }
        seriesMap.putIfAbsent(name, () => _BookSection(label: name, seriesId: sid, books: []));
        // Update seriesId if we found one and the section didn't have one
        if (sid != null && seriesMap[name]!.seriesId == null) {
          seriesMap[name] = _BookSection(label: name, seriesId: sid, books: seriesMap[name]!.books);
        }
        seriesMap[name]!.books.add(book);
        addedToSeries = true;
      }

      if (!addedToSeries) {
        standalones.add(book);
      }
    }

    // Sort books within each series by their sequence in that specific series
    final seqPattern = RegExp(r'#\s*([\d.]+)$');
    for (final entry in seriesMap.entries) {
      final seriesName = entry.key;
      entry.value.books.sort((a, b) {
        final snA = ((a['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?)?['seriesName'] as String? ?? '';
        final snB = ((b['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?)?['seriesName'] as String? ?? '';
        final seqA = _extractSequenceFor(snA, seriesName, seqPattern);
        final seqB = _extractSequenceFor(snB, seriesName, seqPattern);
        return seqA.compareTo(seqB);
      });
    }

    // Series sections sorted alphabetically, then standalone group at the end
    final seriesSections = seriesMap.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    // Sort standalones alphabetically by title
    standalones.sort((a, b) {
      final tA = ((a['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?)?['title'] as String? ?? '';
      final tB = ((b['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?)?['title'] as String? ?? '';
      return tA.toLowerCase().compareTo(tB.toLowerCase());
    });

    final allSections = <_BookSection>[...seriesSections];
    if (standalones.isNotEmpty) {
      allSections.add(_BookSection(label: l.standalone, books: standalones, isStandalone: true));
    }
    return allSections;
  }

  /// Get just the "#N" for a book within a specific series.
  String? _sequenceFor(Map<String, dynamic> book, String seriesName) {
    final sn = ((book['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?)?['seriesName'] as String? ?? '';
    final pattern = RegExp(r'#\s*([\d.]+)');
    for (final entry in sn.split(',').map((e) => e.trim())) {
      final name = entry.replaceFirst(RegExp(r'\s*#\s*[\d.]+$'), '').trim();
      if (name.toLowerCase() == seriesName.toLowerCase()) {
        final match = pattern.firstMatch(entry);
        if (match != null) return '#${match.group(1)}';
      }
    }
    return null;
  }

  /// Extract the sequence number for a specific series from the seriesName string.
  double _extractSequenceFor(String seriesNameRaw, String targetSeries, RegExp seqPattern) {
    final entries = seriesNameRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    for (final entry in entries) {
      final name = entry.replaceFirst(seqPattern, '').trim();
      if (name.toLowerCase() == targetSeries.toLowerCase()) {
        final match = seqPattern.firstMatch(entry);
        if (match != null) return double.tryParse(match.group(1)!) ?? double.maxFinite;
      }
    }
    return double.maxFinite;
  }

  Widget _buildViewModeBar(ColorScheme cs, AppLocalizations l) {
    Widget layoutBtn(IconData icon, _AuthorLayout mode, String tooltip) {
      final active = _layout == mode;
      return IconButton(
        icon: Icon(icon, size: 20, color: active ? cs.primary : cs.onSurfaceVariant),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: () {
          setState(() => _layout = mode);
          PlayerSettings.setSheetGridView(mode == _AuthorLayout.grid);
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.collections_bookmark_rounded, size: 20,
              color: _groupBySeries ? cs.primary : cs.onSurfaceVariant),
            tooltip: l.authorBooksGroupBySeries,
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() => _groupBySeries = !_groupBySeries);
              PlayerSettings.setSheetCollapseSeries(_groupBySeries);
            },
          ),
          const Spacer(),
          layoutBtn(Icons.view_list_rounded, _AuthorLayout.list, l.authorBooksList),
          layoutBtn(Icons.apps_rounded, _AuthorLayout.grid, l.authorBooksGrid),
        ],
      ),
    );
  }

  /// Build a flat list of items mixing collapsed series tiles and standalone books.
  List<dynamic> _buildCollapsedItems(List<_BookSection> sections) {
    final items = <dynamic>[];
    for (final section in sections) {
      if (section.isStandalone) {
        items.addAll(section.books);
      } else {
        items.add(section); // collapsed series
      }
    }
    return items;
  }

  Widget _buildListView(ColorScheme cs, TextTheme tt, LibraryProvider lib,
      List<_BookSection> sections, List<Widget> headerWidgets, double bottomPad, AppLocalizations l) {
    final items = <Widget>[...headerWidgets];
    if (_groupBySeries) {
      // Collapsed: series as tappable rows, standalones as book tiles
      final collapsed = _buildCollapsedItems(sections);
      for (final item in collapsed) {
        if (item is _BookSection) {
          items.add(_collapsedSeriesTile(cs, tt, lib, item, l));
        } else if (item is Map<String, dynamic>) {
          items.add(_dismissibleBookTile(lib, cs, item, l.standalone, l));
        }
      }
    } else {
      for (final section in sections) {
        items.add(_sectionDivider(cs, tt, section.label));
        for (final book in section.books) {
          items.add(_dismissibleBookTile(lib, cs, book, section.label, l));
        }
      }
    }
    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildGridView(ColorScheme cs, TextTheme tt, LibraryProvider lib,
      List<_BookSection> sections, List<Widget> headerWidgets, double bottomPad, AppLocalizations l) {
    if (_groupBySeries) {
      // Collapsed: mix series tiles and standalone book tiles in a grid
      final collapsed = _buildCollapsedItems(sections);
      return CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverList(delegate: SliverChildListDelegate(headerWidgets)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (MediaQuery.of(context).size.width / 130).floor().clamp(3, 10),
                mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.55,
              ),
              delegate: SliverChildBuilderDelegate((_, i) {
                final item = collapsed[i];
                if (item is _BookSection) {
                  return _collapsedSeriesGridTile(cs, tt, lib, item);
                }
                return GridBookTile(item: item as Map<String, dynamic>);
              }, childCount: collapsed.length),
            ),
          ),
        ],
      );
    }
    // Non-collapsed grid with series dividers
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverList(delegate: SliverChildListDelegate(headerWidgets)),
        for (final section in sections) ...[
          SliverToBoxAdapter(child: _sectionDivider(cs, tt, section.label)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (MediaQuery.of(context).size.width / 130).floor().clamp(3, 10),
                mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.55,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => GridBookTile(item: section.books[i], sequenceBadge: _sequenceFor(section.books[i], section.label)?.replaceFirst('#', '')),
                childCount: section.books.length,
              ),
            ),
          ),
        ],
        SliverPadding(padding: EdgeInsets.only(bottom: bottomPad)),
      ],
    );
  }

  Widget _collapsedSeriesTile(ColorScheme cs, TextTheme tt, LibraryProvider lib, _BookSection section, AppLocalizations l) {
    final bookCount = section.books.length;
    final headers = lib.mediaHeaders;
    final coverUrls = section.books.take(3).map((b) {
      final id = b['id'] as String? ?? '';
      return id.isNotEmpty ? lib.getCoverUrl(id) : null;
    }).toList();
    final coverCount = coverUrls.length.clamp(1, 3);
    final stackWidth = 40.0 + (coverCount - 1) * 8.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openSeriesSheet(section),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(children: [
              SizedBox(
                width: stackWidth, height: 40,
                child: Stack(children: [
                  for (int i = coverCount - 1; i >= 0; i--)
                    Positioned(
                      left: i * 8.0,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: i > 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2, offset: const Offset(-1, 1))] : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: coverUrls[i] != null
                            ? CachedNetworkImage(imageUrl: coverUrls[i]!, fit: BoxFit.cover, httpHeaders: headers, width: 40, height: 40,
                                errorWidget: (_, __, ___) => Container(color: cs.surfaceContainerHighest,
                                  child: Icon(Icons.auto_stories_rounded, size: 18, color: cs.onSurfaceVariant)))
                            : Container(color: cs.surfaceContainerHighest,
                                child: Icon(Icons.auto_stories_rounded, size: 18, color: cs.onSurfaceVariant)),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(l.authorBooksBookCount(bookCount),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              )),
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _collapsedSeriesGridTile(ColorScheme cs, TextTheme tt, LibraryProvider lib, _BookSection section) {
    return GridSeriesTileDirect(series: {
      'name': section.label,
      'id': section.seriesId ?? '',
      'books': section.books,
    });
  }


  void _openSeriesSheet(_BookSection section) {
    showSeriesBooksSheet(context,
      seriesName: section.label,
      seriesId: section.seriesId,
      books: section.books,
      serverUrl: widget.serverUrl,
      token: widget.token,
      libraryId: widget.libraryId,
    );
  }

  Widget _sectionDivider(ColorScheme cs, TextTheme tt, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(child: Divider(color: cs.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ]),
    );
  }

  Widget _dismissibleBookTile(LibraryProvider lib, ColorScheme cs, Map<String, dynamic> book, String sectionLabel, AppLocalizations l) {
    final bookId = book['id'] as String? ?? '';
    final bookTitle = (book['media'] as Map<String, dynamic>?)?['metadata']?['title'] as String? ?? l.unknown;
    final isOnAbsorbing = lib.isOnAbsorbingList(bookId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Dismissible(
        key: ValueKey('absorb-$bookId'),
        direction: isOnAbsorbing ? DismissDirection.none : DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          await lib.addToAbsorbingQueue(bookId);
          lib.absorbingItemCache[bookId] = Map<String, dynamic>.from(book);
          HapticFeedback.mediumImpact();
          if (context.mounted) {
            showOverlayToast(context, l.sectionDetailAddedToAbsorbing(bookTitle), icon: Icons.add_circle_outline_rounded);
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
        child: BookResultTile(
          item: book,
          serverUrl: widget.serverUrl,
          token: widget.token,
          subtitle: _sequenceFor(book, sectionLabel),
          sequenceBadge: _sequenceFor(book, sectionLabel)?.replaceFirst('#', ''),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, TextTheme tt, Map<String, String> headers, AppLocalizations l, {bool canEdit = false}) {
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
              color: cs.secondaryContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: _imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: _imageUrl!,
                    fit: BoxFit.cover,
                    httpHeaders: headers,
                    placeholder: (_, __) => _avatarPlaceholder(cs),
                    errorWidget: (_, __, ___) => _avatarPlaceholder(cs),
                  )
                : _avatarPlaceholder(cs),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(_displayName,
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
          if (canEdit)
            IconButton(
              icon: Icon(Icons.edit_rounded, size: 20, color: cs.onSurfaceVariant),
              tooltip: l.editAuthor,
              onPressed: _openEditAuthor,
            ),
        ],
      ),
    );
  }

  void _openEditAuthor() {
    showEditAuthorSheet(
      context,
      authorId: widget.authorId,
      currentName: _displayName,
      currentDescription: _description,
      currentAsin: _asin,
      currentImageUrl: _imageUrl,
      onUpdated: () {
        if (mounted) {
          setState(() => _isLoading = true);
          _loadAuthorAndBooks();
        }
      },
      onMerged: (mergedIntoId, mergedIntoName) {
        // The current author was merged into another; close this sheet.
        if (!mounted) return;
        final l = AppLocalizations.of(context)!;
        Navigator.of(context).pop();
        showOverlayToast(
          context,
          l.authorMergedInto(mergedIntoName),
          icon: Icons.merge_type_rounded,
        );
      },
    );
  }

  Widget _buildDescription(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: GestureDetector(
        onTap: () => setState(() => _descExpanded = !_descExpanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _description!,
              maxLines: _descExpanded ? null : 4,
              overflow: _descExpanded ? null : TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _descExpanded ? l.showLess : l.readMore,
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(ColorScheme cs) {
    return Center(
      child: Icon(Icons.person_rounded,
          size: 32, color: cs.onSecondaryContainer.withValues(alpha: 0.5)),
    );
  }
}

class _BookSection {
  final String label;
  final String? seriesId;
  final List<Map<String, dynamic>> books;
  final bool isStandalone;
  _BookSection({required this.label, this.seriesId, required this.books, this.isStandalone = false});
}
