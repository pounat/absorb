import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'overlay_toast.dart';
import 'swipe_action.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import 'cover_badges.dart';
import '../services/wording.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'book_detail_sheet.dart';
import 'library_grid_tiles.dart';
import 'episode_list_sheet.dart';
import 'stackable_sheet.dart';
import 'audible_series_sheet.dart';
import 'action_pill.dart';
import 'adaptive_modal.dart';
import 'books_sheet_shared.dart';
import '../services/api_service.dart';
import '../utils/duration_format.dart';
import '../utils/app_platform.dart';

/// Show a bottom sheet with all books in a series, sorted by sequence.
/// Can be called from any screen.
void showSeriesBooksSheet(BuildContext context, {
  required String seriesName,
  String? seriesId,
  List<dynamic> books = const [],
  String? serverUrl,
  String? token,
  String? libraryId,
  String? parentSeriesId,
}) {
  showStackableSheet(
    context: context,
    showHandle: true,
    builder: (ctx, scrollController) => SeriesBooksSheet(
      seriesName: seriesName,
      seriesId: seriesId,
      books: books,
      serverUrl: serverUrl,
      token: token,
      libraryId: libraryId,
      scrollController: scrollController,
      parentSeriesId: parentSeriesId,
    ),
  );
}

class SeriesBooksSheet extends StatefulWidget {
  final String seriesName;
  final String? seriesId;
  final List<dynamic> books;
  final String? serverUrl;
  final String? token;
  final String? libraryId;
  final ScrollController scrollController;
  final String? parentSeriesId;

  const SeriesBooksSheet({
    super.key,
    required this.seriesName,
    this.seriesId,
    required this.books,
    required this.serverUrl,
    required this.token,
    this.libraryId,
    required this.scrollController,
    this.parentSeriesId,
  });

  @override
  State<SeriesBooksSheet> createState() => _SeriesBooksSheetState();
}

class _SeriesBooksSheetState extends State<SeriesBooksSheet> {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  bool _isDownloadingAll = false;
  bool _isMarkingAll = false;
  bool _autoDownloadEnabled = false;
  bool _collapseSeries = false;
  final Set<String> _expandedSubSeries = {};

  bool _didAutoScroll = false;
  LibraryProvider? _lib;

  int _totalBooks = 0;
  double _seriesDuration = 0; // from metadata, available before all books load
  bool _gridView = false;

  @override
  void initState() {
    super.initState();
    // Use passed books as initial data
    _books = _unwrapBooks(widget.books);
    _sortBooks();
    if (_books.isNotEmpty) {
      _isLoading = false;
      _scrollToUpNext();
    }
    // Fetch full data from API for proper sequence info
    _fetchFromApi();
    _loadAutoDownloadState();
    PlayerSettings.getSheetGridView().then((v) {
      if (mounted && v != _gridView) setState(() => _gridView = v);
    });
    PlayerSettings.getCollapseBookSeries().then((v) {
      if (mounted && v != _collapseSeries) {
        setState(() => _collapseSeries = v);
        // Don't load sub-series yet - _books may be empty. It triggers after books load.
      }
    });
    _lib = context.read<LibraryProvider>();
    _lib!.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    _lib?.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    // Just rebuild to pick up progress/cover changes — don't re-fetch
    if (mounted) {
      try { setState(() {}); } catch (_) {}
    }
  }

  void _scrollToUpNext() {
    if (_didAutoScroll || _books.isEmpty) return;
    _didAutoScroll = true;
    final lib = context.read<LibraryProvider>();
    int firstUnfinished = -1;
    for (int i = 0; i < _books.length; i++) {
      final bookId = _books[i]['id'] as String? ?? '';
      if (lib.getProgressData(bookId)?['isFinished'] != true) {
        firstUnfinished = i;
        break;
      }
    }
    // If all finished, scroll to bottom; if first is unfinished, stay at top
    final targetIndex = firstUnfinished == -1 ? _books.length - 1 : firstUnfinished;
    if (targetIndex <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollController.hasClients) return;
      // Each book card is ~120px (112 height + 8 bottom padding)
      final offset = (targetIndex * 120.0).clamp(
        0.0,
        widget.scrollController.position.maxScrollExtent,
      );
      widget.scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _loadAutoDownloadState() {
    final seriesId = widget.seriesId;
    if (seriesId == null || seriesId.isEmpty) return;
    final lib = context.read<LibraryProvider>();
    setState(() {
      _autoDownloadEnabled = lib.isRollingDownloadEnabled(seriesId);
    });
  }

  /// Unwrap ABS format: { libraryItem: {...}, sequence: "1" }
  /// Move sequence to top level of the item for consistent access.
  /// Also registers updatedAt for cover cache busting.
  List<Map<String, dynamic>> _unwrapBooks(List<dynamic> raw) {
    final lib = _lib ?? (mounted ? context.read<LibraryProvider>() : null);
    final result = <Map<String, dynamic>>[];
    for (final b in raw) {
      if (b is! Map<String, dynamic>) continue;
      if (b.containsKey('libraryItem') && b['libraryItem'] is Map<String, dynamic>) {
        final item = Map<String, dynamic>.from(b['libraryItem'] as Map<String, dynamic>);
        if (b['sequence'] != null) item['sequence'] = b['sequence'];
        if (lib != null) registerBookCover(lib, item);
        result.add(item);
      } else {
        if (lib != null) registerBookCover(lib, b);
        result.add(Map<String, dynamic>.from(b));
      }
    }
    return result;
  }

  void _sortBooks() {
    _books.sort((a, b) {
      final seqA = _getSequence(a);
      final seqB = _getSequence(b);
      if (seqA == null && seqB == null) return 0;
      if (seqA == null) return 1;
      if (seqB == null) return -1;
      return seqA.compareTo(seqB);
    });
  }

  /// Extract the raw sequence string from the book data.
  String? _getRawSequence(Map<String, dynamic> book) {
    // Books grouped under a collapsed sub-series carry that sub-series'
    // sequence so the number and ordering reflect the sub-series, not the
    // parent (e.g. Stormlight #1, not its position within Cosmere).
    final sub = book['_subSequence'];
    if (sub != null && sub.toString().trim().isNotEmpty) return sub.toString();
    final seq = book['sequence'];
    if (seq != null) return seq.toString();
    final media = book['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final seriesRaw = metadata['series'];
    if (seriesRaw is List) {
      for (final s in seriesRaw) {
        if (s is Map<String, dynamic> && s['sequence'] != null) {
          return s['sequence'].toString();
        }
      }
    } else if (seriesRaw is Map<String, dynamic> && seriesRaw['sequence'] != null) {
      return seriesRaw['sequence'].toString();
    }
    final fallback = metadata['seriesSequence'];
    if (fallback != null) return fallback.toString();

    // Author endpoint returns minified items that only have `seriesName` as a
    // joined string ("Foundation #1, Cosmere #6") with no structured `series`
    // array, so fall back to parsing the matching entry by name.
    final seriesNameRaw = metadata['seriesName'] as String? ?? '';
    if (seriesNameRaw.isNotEmpty) {
      final target = widget.seriesName.toLowerCase();
      for (final entry in seriesNameRaw.split(',').map((e) => e.trim())) {
        final match = RegExp(r'^(.+?)\s*#\s*([\d.]+)$').firstMatch(entry);
        if (match != null) {
          final name = (match.group(1) ?? '').trim().toLowerCase();
          if (name == target) return match.group(2);
        }
      }
    }
    return null;
  }

  /// Parse a sortable number from a sequence string.
  /// Handles plain numbers ("3", "1.5") and ranges ("1-2", "8-10")
  /// by extracting the first number.
  static final _leadingNumber = RegExp(r'^[\d.]+');

  double? _getSequence(Map<String, dynamic> book) {
    final raw = _getRawSequence(book);
    if (raw == null) return null;
    final match = _leadingNumber.firstMatch(raw.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  String? _getSequenceString(Map<String, dynamic> book) {
    final raw = _getRawSequence(book);
    if (raw == null || raw.trim().isEmpty) return null;
    final v = double.tryParse(raw.trim());
    if (v != null) {
      return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    }
    // Range or non-numeric sequence (e.g. "1-2") - show as-is
    return raw.trim();
  }

  /// Sortable number from a book's stored sub-series sequence; blanks sort last.
  double _subSeqNum(Map<String, dynamic> book) {
    final raw = book['_subSequence']?.toString().trim() ?? '';
    final m = _leadingNumber.firstMatch(raw);
    if (m == null) return double.maxFinite;
    return double.tryParse(m.group(0)!) ?? double.maxFinite;
  }

  void _sortSubSeriesBooks(List<Map<String, dynamic>> books) {
    books.sort((a, b) => _subSeqNum(a).compareTo(_subSeqNum(b)));
  }

  /// The sequence of [book] within a specific sub-series, found by id, falling
  /// back to the joined `seriesName` string for minified list items.
  String? _subSeqFor(Map<String, dynamic> book, String subId, String subName) {
    final media = book['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final seriesRaw = metadata['series'];
    final list = seriesRaw is List
        ? seriesRaw.whereType<Map<String, dynamic>>()
        : seriesRaw is Map<String, dynamic> ? [seriesRaw] : const <Map<String, dynamic>>[];
    for (final s in list) {
      if ((s['id'] as String? ?? '') == subId && s['sequence'] != null) {
        return s['sequence'].toString();
      }
    }
    final joined = metadata['seriesName'] as String? ?? '';
    if (joined.isNotEmpty && subName.isNotEmpty) {
      final target = subName.toLowerCase();
      for (final entry in joined.split(',').map((e) => e.trim())) {
        final m = RegExp(r'^(.+?)\s*#\s*([\d.]+)$').firstMatch(entry);
        if (m != null && (m.group(1) ?? '').trim().toLowerCase() == target) {
          return m.group(2);
        }
      }
    }
    return null;
  }

  // Cached sub-series grouping
  List<Map<String, dynamic>> _subSeriesList = [];
  Set<String> _assignedBookIds = {};
  bool _subSeriesLoaded = false;

  /// Load sub-series data. Uses per-item fetch for small series,
  /// collapsed API for large ones.
  Future<void> _loadSubSeriesData() async {
    if (_subSeriesLoaded) return;
    // Check cache first
    final seriesId = widget.seriesId;
    if (seriesId != null) {
      final cached = context.read<LibraryProvider>().getSubSeriesCache(seriesId);
      if (cached != null) {
        _subSeriesList = (cached['subSeries'] as List<Map<String, dynamic>>?) ?? [];
        _assignedBookIds = (cached['assignedIds'] as Set<String>?) ?? {};
        _subSeriesLoaded = true;
        if (mounted) setState(() {});
        return;
      }
    }
    if (_books.length <= 100) {
      await _loadSubSeriesFromItems();
    } else {
      await _loadSubSeriesFromCollapsed();
    }
    _subSeriesLoaded = true;
    // Cache the results
    if (seriesId != null) {
      try { context.read<LibraryProvider>().setSubSeriesCache(seriesId, _subSeriesList, _assignedBookIds); } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  /// Small series: fetch each book's full data to get complete series arrays.
  Future<void> _loadSubSeriesFromItems() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final currentId = widget.seriesId;
    final currentName = widget.seriesName.toLowerCase();
    final subSeriesMap = <String, Map<String, dynamic>>{};

    for (var i = 0; i < _books.length; i += 10) {
      final batch = _books.skip(i).take(10);
      await Future.wait(batch.map((book) async {
        final bookId = book['id'] as String? ?? '';
        if (bookId.isEmpty) return;
        final fullItem = await api.getLibraryItem(bookId);
        if (fullItem == null) return;
        final media = fullItem['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final seriesRaw = metadata['series'];
        final seriesList = seriesRaw is List
            ? seriesRaw.whereType<Map<String, dynamic>>().toList()
            : seriesRaw is Map<String, dynamic> ? [seriesRaw] : <Map<String, dynamic>>[];

        for (final s in seriesList) {
          final sId = s['id'] as String? ?? '';
          final sName = s['name'] as String? ?? '';
          if (sId == currentId || sId == widget.parentSeriesId || sName.toLowerCase() == currentName || sId.isEmpty) continue;
          subSeriesMap.putIfAbsent(sId, () => {
            'name': sName, 'id': sId, 'books': <Map<String, dynamic>>[], 'numBooks': 0,
          });
          final books = subSeriesMap[sId]!['books'] as List<Map<String, dynamic>>;
          if (!books.any((b) => b['id'] == bookId)) {
            // Store the sub-series sequence on the book for sorting
            final subSeq = s['sequence']?.toString();
            final bookCopy = Map<String, dynamic>.from(book);
            if (subSeq != null) bookCopy['_subSequence'] = subSeq;
            books.add(bookCopy);
            subSeriesMap[sId]!['numBooks'] = books.length;
          }
        }
      }));
    }

    subSeriesMap.removeWhere((_, v) => (v['numBooks'] as int) < 2);
    // Sort books within each sub-series by their sub-series sequence
    for (final s in subSeriesMap.values) {
      _sortSubSeriesBooks(s['books'] as List<Map<String, dynamic>>);
    }
    _subSeriesList = subSeriesMap.values.toList();
    _assignedBookIds = _subSeriesList
        .expand((s) => (s['books'] as List<Map<String, dynamic>>).map((b) => b['id'] as String? ?? ''))
        .toSet();
  }

  /// Large series: use collapseseries=1 API (one request, server groups them).
  Future<void> _loadSubSeriesFromCollapsed() async {
    final seriesId = widget.seriesId;
    final libraryId = widget.libraryId ?? context.read<LibraryProvider>().selectedLibraryId;
    if (seriesId == null || libraryId == null) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final results = await api.getSeriesCollapsed(seriesId, libraryId: libraryId);
    final byId = {for (final b in _books) (b['id'] as String? ?? ''): b};

    for (final raw in results) {
      if (raw is! Map<String, dynamic>) continue;
      final collapsed = raw['collapsedSeries'] as Map<String, dynamic>?;
      if (collapsed == null) continue;
      final subId = collapsed['id'] as String? ?? '';
      final subName = collapsed['name'] as String? ?? '';
      final itemIds = (collapsed['libraryItemIds'] as List<dynamic>?)?.cast<String>() ?? [];
      final matchingBooks = <Map<String, dynamic>>[];
      for (final id in itemIds) {
        final original = byId[id];
        if (original == null) {
          // Not yet loaded (pagination) - minimal placeholder, sorts last
          matchingBooks.add({'id': id});
          continue;
        }
        // Copy so the sub-series sequence we tag on doesn't leak into the
        // flat list, where the same book map is shown under the parent series.
        final copy = Map<String, dynamic>.from(original);
        final subSeq = _subSeqFor(original, subId, subName);
        if (subSeq != null) copy['_subSequence'] = subSeq;
        matchingBooks.add(copy);
      }
      _sortSubSeriesBooks(matchingBooks);
      _subSeriesList.add({
        'name': subName,
        'id': subId,
        'books': matchingBooks,
        'numBooks': (collapsed['numBooks'] as int? ?? 0) > 0 ? collapsed['numBooks'] as int : itemIds.length,
      });
      _assignedBookIds.addAll(itemIds);
    }
  }

  ({List<Map<String, dynamic>> subSeries, List<Map<String, dynamic>> standalone}) _buildSubSeriesGroups() {
    final subSeries = List<Map<String, dynamic>>.from(_subSeriesList)
      ..sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
    final standalone = _books.where((b) => !_assignedBookIds.contains(b['id'] as String? ?? '')).toList();
    return (subSeries: subSeries, standalone: standalone);
  }

  Widget _buildGroupedGrid(ColorScheme cs, TextTheme tt, LibraryProvider lib) {
    final parsed = _buildSubSeriesGroups();

    return GridView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
      gridDelegate: sheetBookGridDelegate(context, childAspectRatio: 0.65),
      itemCount: parsed.subSeries.length + parsed.standalone.length,
      itemBuilder: (context, index) {
        if (index < parsed.subSeries.length) {
          return GridSeriesTileDirect(series: parsed.subSeries[index], parentSeriesId: widget.seriesId);
        }
        final book = parsed.standalone[index - parsed.subSeries.length];
        return GridBookTile(item: book, sequenceBadge: _getSequenceString(book));
      },
    );
  }

  Widget _buildGroupedList(ColorScheme cs, TextTheme tt, LibraryProvider lib) {
    final parsed = _buildSubSeriesGroups();
    final l = AppLocalizations.of(context)!;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
      children: [
        // Sub-series headers
        for (final series in parsed.subSeries) ...[
          () {
            final seriesName = series['name'] as String? ?? '';
            final seriesId = series['id'] as String? ?? '';
            final subBooks = series['books'] as List<Map<String, dynamic>>;
            final numBooks = series['numBooks'] as int? ?? subBooks.length;
            final isExpanded = _expandedSubSeries.contains(seriesId);

            return AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isExpanded) _expandedSubSeries.remove(seriesId);
                      else _expandedSubSeries.add(seriesId);
                    }),
                    onLongPress: seriesId.isNotEmpty ? () {
                      showSeriesBooksSheet(context,
                        seriesName: seriesName, seriesId: seriesId,
                        serverUrl: widget.serverUrl, token: widget.token, libraryId: widget.libraryId,
                        parentSeriesId: widget.seriesId);
                    } : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8, top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(Icons.expand_more_rounded, size: 20, color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(seriesName, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text(l.seriesBooksBookCount(numBooks),
                            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11)),
                        ])),
                      ]),
                    ),
                  ),
                  if (isExpanded)
                    ...subBooks.map((book) => _buildBookCard(cs, tt, lib, book)),
                ],
              ),
            );
          }(),
        ],
        // Standalone books
        ...parsed.standalone.map((book) => _buildBookCard(cs, tt, lib, book)),
      ],
    );
  }

  Future<void> _fetchFromApi() async {
    final seriesId = widget.seriesId;
    if (seriesId == null || seriesId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final lib = context.read<LibraryProvider>();
    final libraryId = widget.libraryId ?? lib.selectedLibraryId;

    // For large series (100+ books), serve cached data instantly
    // then refresh in background. Small series always fetch fresh.
    final cached = lib.getSeriesBooksCache(seriesId);
    if (cached != null) {
      final cachedTotal = (cached['total'] as num?)?.toInt() ?? 0;
      if (cachedTotal >= 100) {
        final fetched = _unwrapBooks(cached['books'] as List<dynamic>);
        if (fetched.isNotEmpty && mounted) {
          setState(() {
            _books = fetched;
            _sortBooks();
            _isLoading = false;
            _totalBooks = cachedTotal;
          });
          _scrollToUpNext();
        }
      }
    }

    // Fetch fresh data (updates cache as pages arrive)
    final data = await api.getSeries(seriesId, libraryId: libraryId,
      onPageLoaded: (books, total, {double? totalDuration}) {
        if (!mounted) return;
        final fetched = _unwrapBooks(books);
        setState(() {
          _books = fetched;
          _sortBooks();
          _isLoading = false;
          _totalBooks = total;
          if (totalDuration != null && totalDuration > 0) _seriesDuration = totalDuration;
        });
        if (!_didAutoScroll) _scrollToUpNext();
        // Update cache - re-read lib safely, only cache non-empty results
        if (mounted && books.isNotEmpty) {
          try { context.read<LibraryProvider>().setSeriesBooksCache(seriesId, books, total); } catch (_) {}
        }
      },
    );
    if (data == null && mounted) setState(() => _isLoading = false);
    // If collapse is enabled and we now have books, load sub-series data
    if (_collapseSeries && _books.isNotEmpty && !_subSeriesLoaded) {
      _loadSubSeriesData();
    }
  }


  bool get _allFinished {
    final lib = context.read<LibraryProvider>();
    if (_books.isEmpty) return false;
    for (final book in _books) {
      final bookId = book['id'] as String? ?? '';
      if (lib.getProgressData(bookId)?['isFinished'] != true) return false;
    }
    return true;
  }

  Future<void> _markAllFinished() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final lib = context.read<LibraryProvider>();

    setState(() => _isMarkingAll = true);

    for (final book in _books) {
      final bookId = book['id'] as String? ?? '';
      if (bookId.isEmpty) continue;
      if (lib.getProgressData(bookId)?['isFinished'] == true) continue;
      final media = book['media'] as Map<String, dynamic>? ?? {};
      final duration = (media['duration'] is num)
          ? (media['duration'] as num).toDouble()
          : 0.0;
      await api.markFinished(bookId, duration);
      lib.markFinishedLocally(bookId, skipRefresh: true, skipAutoAdvance: true);
      lib.removeFromAbsorbing(bookId);
    }

    if (mounted) {
      lib.refresh();
      setState(() => _isMarkingAll = false);
    }
  }

  Future<void> _markAllNotFinished() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final lib = context.read<LibraryProvider>();

    setState(() => _isMarkingAll = true);

    for (final book in _books) {
      final bookId = book['id'] as String? ?? '';
      if (bookId.isEmpty) continue;
      if (lib.getProgressData(bookId)?['isFinished'] != true) continue;
      final media = book['media'] as Map<String, dynamic>? ?? {};
      final duration = (media['duration'] is num)
          ? (media['duration'] as num).toDouble()
          : 0.0;
      await api.markNotFinished(bookId, currentTime: 0, duration: duration);
      lib.resetProgressFor(bookId);
      lib.clearAbsorbingBlock(bookId);
    }

    if (mounted) {
      lib.refresh();
      setState(() => _isMarkingAll = false);
    }
  }

  Future<void> _findOnAudible() async {
    final l = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.seriesBooksFindMissingTitle),
        content: Text(l.seriesBooksFindMissingContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.search)),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    // Collect owned titles and ASINs for cross-referencing
    final ownedTitles = <String>{};
    final ownedAsins = <String>{};
    for (final book in _books) {
      final media = book['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String? ?? '';
      final asin = metadata['asin'] as String? ?? '';
      if (title.isNotEmpty) ownedTitles.add(title);
      if (asin.isNotEmpty) ownedAsins.add(asin);
    }

    // Try to get a series ASIN from one of the books via Audnexus
    String? seriesAsin;

    for (final book in _books) {
      final media = book['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final bookAsin = metadata['asin'] as String? ?? '';
      if (bookAsin.isEmpty) continue;

      final audnexus = await ApiService.getAudnexusBook(bookAsin);
      if (audnexus == null) continue;

      final primary = audnexus['seriesPrimary'] as Map<String, dynamic>?;
      if (primary != null && primary['asin'] != null) {
        seriesAsin = primary['asin'] as String;
        break;
      }
      final secondary = audnexus['seriesSecondary'] as Map<String, dynamic>?;
      if (secondary != null && secondary['asin'] != null) {
        seriesAsin = secondary['asin'] as String;
        break;
      }
    }

    // Fallback: search Audible for the first book if no ASINs found
    if (seriesAsin == null && _books.isNotEmpty) {
      final firstBook = _books.first;
      final media = firstBook['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String? ?? '';
      final author = metadata['authorName'] as String? ?? '';

      if (title.isNotEmpty && mounted) {
        final auth = context.read<AuthProvider>();
        final api = auth.apiService;
        if (api != null) {
          final results = await api.searchBooks(title: title, author: author.isNotEmpty ? author : null);
          for (final r in results) {
            final asin = r['asin'] as String? ?? '';
            if (asin.isEmpty) continue;
            final audnexus = await ApiService.getAudnexusBook(asin);
            if (audnexus == null) continue;
            final primary = audnexus['seriesPrimary'] as Map<String, dynamic>?;
            if (primary != null && primary['asin'] != null) {
              seriesAsin = primary['asin'] as String;
              break;
            }
          }
        }
      }
    }

    if (!mounted) return;

    if (seriesAsin == null) {
      showOverlayToast(context, l.seriesBooksCouldNotFindOnAudible, icon: Icons.search_off_rounded);
      return;
    }

    showAudibleSeriesSheet(context,
      seriesName: widget.seriesName,
      seriesAsin: seriesAsin,
      ownedTitles: ownedTitles,
      ownedAsins: ownedAsins,
    );
  }

  Widget _buildOverflowMenu(ColorScheme cs) {
    final allDone = _allFinished;
    int downloaded = 0;
    if (!AppPlatform.isWeb) {
      final dl = DownloadService();
      for (final book in _books) {
        final bookId = book['id'] as String? ?? '';
        if (dl.isDownloaded(bookId)) downloaded++;
      }
    }
    final allDownloaded = !AppPlatform.isWeb && downloaded == _books.length;
    final hasSeriesId = widget.seriesId != null && widget.seriesId!.isNotEmpty;

    if (_isMarkingAll || _isDownloadingAll) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
      onPressed: () => _showSeriesMoreSheet(cs, allDownloaded, downloaded, allDone, hasSeriesId),
    );
  }

  void _showSeriesMoreSheet(ColorScheme cs, bool allDownloaded, int downloaded, bool allDone, bool hasSeriesId) {
    final l = AppLocalizations.of(context)!;
    showAdaptiveActionMenu(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
              ActionPillGrid(items: [
                if (!AppPlatform.isWeb && !allDownloaded)
                  ActionPillData(
                    icon: Icons.download_rounded,
                    label: downloaded > 0 ? l.downloadRemainingCount((_totalBooks > 0 ? _totalBooks : _books.length) - downloaded) : l.downloadAll,
                    onTap: () { Navigator.pop(ctx); _downloadAll(); }),
                ActionPillData(
                  icon: allDone ? Icons.remove_done_rounded : Icons.done_all_rounded,
                  label: allDone ? l.markAllNotFinished : l.markAllFinished,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (allDone) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dlg) => AlertDialog(
                          title: Text(l.markAllNotFinishedQuestion),
                          content: Text(l.seriesBooksMarkAllNotFinishedContent(_books.length)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dlg, false), child: Text(l.cancel)),
                            FilledButton(onPressed: () => Navigator.pop(dlg, true), child: Text(l.seriesBooksUnmarkAll)),
                          ],
                        ),
                      );
                      if (confirmed == true) _markAllNotFinished();
                    } else {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dlg) => AlertDialog(
                          title: Text(Wording.of(context).fullyAbsorbSeries),
                          content: Text(l.seriesBooksFullyAbsorbContent(_books.length)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dlg, false), child: Text(l.cancel)),
                            FilledButton(onPressed: () => Navigator.pop(dlg, true), child: Text(Wording.of(context).fullyAbsorbAction)),
                          ],
                        ),
                      );
                      if (confirmed == true) _markAllFinished();
                    }
                  }),
                if (!AppPlatform.isWeb && hasSeriesId)
                  ActionPillData(
                    icon: _autoDownloadEnabled ? Icons.downloading_rounded : Icons.download_outlined,
                    label: _autoDownloadEnabled ? l.turnAutoDownloadOff : l.turnAutoDownloadOn,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final lib = context.read<LibraryProvider>();
                      await lib.toggleRollingDownload(widget.seriesId!,
                          name: widget.seriesName, kind: 'series');
                      setState(() => _autoDownloadEnabled = lib.isRollingDownloadEnabled(widget.seriesId!));
                    }),
                ActionPillData(icon: Icons.search_rounded, label: l.seriesBooksFindMissingTitle,
                  onTap: () { Navigator.pop(ctx); _findOnAudible(); }),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _downloadAll() async {
    if (AppPlatform.isWeb) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;

    // Offer to enable auto-download if not already on
    final seriesId = widget.seriesId;
    if (seriesId != null && seriesId.isNotEmpty && !_autoDownloadEnabled) {
      final l = AppLocalizations.of(context)!;
      final enable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.autoDownloadThisSeries),
          content: Text(l.autoDownloadSeriesContent),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.noThanks)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.enable)),
          ],
        ),
      );
      if (enable == true && mounted) {
        final lib = context.read<LibraryProvider>();
        await lib.enableRollingDownload(seriesId,
            name: widget.seriesName, kind: 'series');
        setState(() => _autoDownloadEnabled = true);
      }
    }

    setState(() => _isDownloadingAll = true);

    final l2 = mounted ? AppLocalizations.of(context)! : null;
    final unknownTitle = l2?.unknown ?? 'Unknown';
    for (final book in _books) {
      if (!mounted) break;
      final bookId = book['id'] as String? ?? '';
      if (DownloadService().isDownloaded(bookId) || DownloadService().isDownloading(bookId)) continue;

      final media = book['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String? ?? unknownTitle;
      final author = metadata['authorName'] as String? ?? '';

      await DownloadService().downloadItem(
        api: api,
        itemId: bookId,
        title: title,
        author: author,
        coverUrl: api.getCoverUrl(bookId),
        libraryId: context.read<LibraryProvider>().selectedLibraryId,
      );
    }

    if (mounted) setState(() => _isDownloadingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();

    // Calculate time-weighted series progress across all books
    double totalDuration = 0;
    double listenedDuration = 0;
    for (final book in _books) {
      final bookId = book['id'] as String? ?? '';
      final media = book['media'] as Map<String, dynamic>? ?? {};
      final dur = (media['duration'] is num) ? (media['duration'] as num).toDouble() : 0.0;
      final prog = lib.getProgress(bookId);
      totalDuration += dur;
      listenedDuration += dur * prog;
    }
    final seriesProgress = totalDuration > 0 ? (listenedDuration / totalDuration).clamp(0.0, 1.0) : 0.0;
    final seriesPercent = (seriesProgress * 100).round();

    return ClipRect(child: Column(
      children: [
        // Header row: 3-dot menu pinned top-right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.auto_stories_rounded, size: 20, color: cs.primary),
                  const SizedBox(height: 4),
                  Text(widget.seriesName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: tt.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: _books.isNotEmpty ? _buildOverflowMenu(cs) : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: () {
                  final displayDuration = _seriesDuration > totalDuration ? _seriesDuration : totalDuration;
                  final bookCount = _totalBooks > 0 ? _totalBooks : _books.length;
                  final base = l.booksInSeriesCount(bookCount);
                  return displayDuration > 0
                      ? '$base · ${formatHm(displayDuration)}'
                      : base;
                }(),
              ),
              if (!AppPlatform.isWeb && _autoDownloadEnabled) ...[
                const TextSpan(text: ' · '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.downloading_rounded, size: 14, color: cs.primary),
                ),
              ],
            ],
          ),
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        SizedBox(height: seriesProgress > 0 ? 4 : 12),
        if (seriesProgress > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: seriesProgress,
                      minHeight: 4,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l.percentComplete(seriesPercent.toString()),
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (_books.isNotEmpty)
          sheetViewModeBar(
            context,
            gridView: _gridView,
            onChanged: (grid) => setState(() => _gridView = grid),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            leading: IconButton(
              icon: Icon(Icons.collections_bookmark_rounded, size: 20,
                color: _collapseSeries ? cs.primary : cs.onSurfaceVariant),
              visualDensity: VisualDensity.compact,
              tooltip: _collapseSeries ? l.seriesBooksShowAllBooks : l.seriesBooksGroupBySubSeries,
              onPressed: () {
                setState(() {
                  _collapseSeries = !_collapseSeries;
                  if (_collapseSeries) {
                    _expandedSubSeries.clear();
                    if (!_subSeriesLoaded) _loadSubSeriesData();
                  }
                });
                PlayerSettings.setCollapseBookSeries(_collapseSeries);
              },
            ),
          ),
        if (_isLoading && _books.isEmpty)
          const Expanded(
              child: Center(child: CircularProgressIndicator()))
        else if (_books.isEmpty)
          Expanded(
            child: Center(
              child: Text(l.noBooksFound,
                  style: tt.bodyLarge
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          )
        else if (_collapseSeries && !_subSeriesLoaded)
          Expanded(
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 12),
              Text(l.seriesBooksLoadingSubSeries, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
            ])),
          )
        else if (_collapseSeries && _gridView)
          Expanded(
            child: ListenableBuilder(
              listenable: DownloadService(),
              builder: (context, _) => _buildGroupedGrid(cs, tt, lib),
            ),
          )
        else if (_collapseSeries)
          Expanded(
            child: ListenableBuilder(
              listenable: DownloadService(),
              builder: (context, _) => _buildGroupedList(cs, tt, lib),
            ),
          )
        else if (_gridView)
          Expanded(
            child: ListenableBuilder(
              listenable: DownloadService(),
              builder: (context, _) => GridView.builder(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
              gridDelegate: sheetBookGridDelegate(context, childAspectRatio: 0.65),
              itemCount: _books.length,
              itemBuilder: (context, index) => GridBookTile(item: _books[index], sequenceBadge: _getSequenceString(_books[index])),
            ),
          ))
        else
          Expanded(
            child: ListenableBuilder(
              listenable: DownloadService(),
              builder: (context, _) => ListView.builder(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
              itemCount: _books.length,
              itemBuilder: (context, index) => _buildBookCard(cs, tt, lib, _books[index]),
            ),
          ),
          ),
      ],
    ));
  }

  Widget _buildBookCard(ColorScheme cs, TextTheme tt, LibraryProvider lib, Map<String, dynamic> book) {
    final l = AppLocalizations.of(context)!;
    final bookId = book['id'] as String? ?? '';
    final media = book['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final bookTitle = metadata['title'] as String? ?? l.unknown;
    final authorName = metadata['authorName'] as String? ?? '';
    final sequence = _getSequenceString(book);
    final duration = (media['duration'] is num) ? (media['duration'] as num).toDouble() : 0.0;

    final isExplicit = PlayerSettings.showExplicitBadge && metadata['explicit'] == true;
    final progress = lib.getProgress(bookId);
    final isFinished = lib.getProgressData(bookId)?['isFinished'] == true;
    final isDownloaded =
        !AppPlatform.isWeb && DownloadService().isDownloaded(bookId);
    final isDownloading =
        !AppPlatform.isWeb && DownloadService().isDownloading(bookId);
    final downloadPct = AppPlatform.isWeb
        ? 0
        : (DownloadService().downloadProgress(bookId) * 100)
            .clamp(0, 100)
            .round();
    final coverUrl = lib.getCoverUrl(bookId);
    final isOnAbsorbing = lib.isOnAbsorbingList(bookId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwipeAction(
        key: ValueKey('absorb-$bookId'),
        onStartToEnd: isOnAbsorbing
            ? null
            : SwipeActionSpec(
                icon: Icons.add_circle_outline_rounded,
                color: cs.primary,
                onTrigger: () async {
                  await lib.addToAbsorbingQueue(bookId);
                  lib.absorbingItemCache[bookId] = Map<String, dynamic>.from(book);
                  if (context.mounted) {
                    HapticFeedback.mediumImpact();
                    showOverlayToast(context, Wording.of(context).episodeListAddedToAbsorbing(bookTitle), icon: Icons.add_circle_outline_rounded);
                  }
                },
              ),
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (bookId.isNotEmpty) {
                if (lib.isPodcastLibrary) {
                  EpisodeListSheet.show(context, book);
                } else {
                  showBookDetailSheet(context, bookId);
                }
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 112,
              child: Row(children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(children: [
                    Positioned.fill(
                      child: coverUrl != null
                          ? (!AppPlatform.isWeb && coverUrl.startsWith('/')
                              ? Image.file(File(coverUrl), fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder(cs))
                              : CachedNetworkImage(
                                  imageUrl: coverUrl, fit: BoxFit.cover,
                                  httpHeaders: lib.mediaHeaders,
                                  placeholder: (_, __) => _placeholder(cs),
                                  errorWidget: (_, __, ___) => _placeholder(cs)))
                          : _placeholder(cs),
                    ),
                    if (sequence != null && sequence.isNotEmpty)
                      Positioned(top: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
                          child: Text('#$sequence', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (isExplicit)
                      Positioned(top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
                          child: Text(l.seriesBooksExplicitBadge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    if (!isDownloaded && isDownloading)
                      Positioned(top: isExplicit ? 22 : 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                          child: Text('$downloadPct%', style: TextStyle(color: cs.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (progress > 0 && !isFinished)
                      Positioned(left: 0, right: 0, bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0), minHeight: 3,
                          backgroundColor: Colors.black38, valueColor: AlwaysStoppedAnimation(cs.primary)),
                      ),
                    if (isFinished || isDownloaded)
                      Positioned(left: 0, right: 0, bottom: 0,
                        child: CoverStateBadges(isDownloaded: isDownloaded, isFinished: isFinished),
                      ),
                  ]),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (sequence != null && sequence.isNotEmpty)
                        Text(l.bookNumber(sequence), style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                      Text(bookTitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                      if (authorName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(authorName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                      if (duration > 0) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Text(formatHm(duration), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                          if (progress > 0 && !isFinished) ...[
                            const SizedBox(width: 8),
                            Text('${(progress * 100).round()}%',
                              style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                          ],
                        ]),
                      ],
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.headphones_rounded,
            size: 24, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }

}
