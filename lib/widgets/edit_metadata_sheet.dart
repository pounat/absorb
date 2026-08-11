import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/socket_service.dart';
import '../screens/chapter_editor_screen.dart';
import '../utils/desktop_workspace.dart';
import 'metadata_lookup_sheet.dart'
    show metadataFieldPickerDialogConstraints;
import 'overlay_toast.dart';

enum _ETab { details, cover, chapters, match, encode, embed }

const double _metadataDetailsWideBreakpoint = 700;

/// The unified per-book editor body: one swipeable tab bar over Details, Cover,
/// Chapters, Match and Encode (in Audiobookshelf web order). Hosted full-screen
/// by BookEditScreen. The Chapters tab embeds [ChapterEditBody]; the rest are
/// built here. Each tab has its own scroll controller so swiping between
/// adjacent tabs never double-attaches one controller.
class MetadataEditView extends StatefulWidget {
  static const quickMatchButtonKey = Key('metadataQuickMatchButton');
  static const filePathsSectionKey = Key('metadataFilePathsSection');
  static const descriptionFieldKey = Key('metadataDescriptionField');

  final String itemId;
  final String bookTitle;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final List<dynamic> audioFiles;
  final List<dynamic> libraryFiles;
  final String relPath;
  final bool isEbookOnly;
  final bool isAdmin;
  final String? libraryId;

  const MetadataEditView({
    super.key,
    required this.itemId,
    required this.bookTitle,
    required this.metadata,
    this.tags = const [],
    this.audioFiles = const [],
    this.libraryFiles = const [],
    this.relPath = '',
    this.isEbookOnly = false,
    this.isAdmin = false,
    this.libraryId,
  });

  @override
  State<MetadataEditView> createState() => _MetadataEditViewState();
}

class _MetadataEditViewState extends State<MetadataEditView>
    with SingleTickerProviderStateMixin {
  final ScrollController _detailsScroll = ScrollController();
  final ScrollController _coverScroll = ScrollController();
  final ScrollController _matchScroll = ScrollController();
  final ScrollController _encodeScroll = ScrollController();
  final ScrollController _embedScroll = ScrollController();
  late final List<_ETab> _tabs;
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
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _asinCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _coverUrlCtrl;
  late final TextEditingController _coverSearchTitleCtrl;
  late final TextEditingController _coverSearchAuthorCtrl;

  // Quick match
  late final TextEditingController _searchTitleCtrl;
  late final TextEditingController _searchAuthorCtrl;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _quickMatching = false;
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
  int _coverVersion = 0; // cache-bust the cover preview when it changes
  List<String> _coverResults = [];
  bool _coverSearching = false;
  String _coverProvider = 'best';
  bool _saving = false;
  bool _explicit = false;
  bool _abridged = false;

  // Existing library values for the series/genres/tags typeahead. Fetched once
  // from the library's filterdata so a value can be picked instead of retyped.
  List<String> _allSeries = [];
  List<String> _allGenres = [];
  List<String> _allTags = [];

  // Encode tab
  String _encodeCodec = 'aac';
  String _encodeBitrate = '128k';
  int _encodeChannels = 2;
  bool _shouldBackup = true; // embed: back up original audio files

  // One server task (encode-m4b or embed-metadata) runs per item at a time.
  String? _runningAction; // 'encode-m4b' | 'embed-metadata' | null
  double? _taskProgress; // 0-100, null until the first tick
  bool get _encoding => _runningAction == 'encode-m4b';
  bool get _embedding => _runningAction == 'embed-metadata';

  @override
  void initState() {
    super.initState();
    _tabs = [
      _ETab.details,
      _ETab.cover,
      if (!widget.isEbookOnly) _ETab.chapters,
      _ETab.match,
      if (widget.isAdmin && !widget.isEbookOnly) _ETab.encode,
      if (widget.isAdmin && !widget.isEbookOnly) _ETab.embed,
    ];
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    // Listen for encode progress/finish for the editor's lifetime so a running
    // encode shows up even if it was started elsewhere (e.g. the web UI).
    SocketService()
      ..addTaskStartedListener(_onTaskStarted)
      ..addTaskProgressListener(_onTaskProgress)
      ..addTaskFinishedListener(_onTaskFinished);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreRunningTask());
    });
    _loadFilterSuggestions();
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
    _explicit = m['explicit'] == true;
    _abridged = m['abridged'] == true;
    _coverUrlCtrl = TextEditingController();
    _coverSearchTitleCtrl = TextEditingController(text: m['title'] as String? ?? '');
    _coverSearchAuthorCtrl = TextEditingController(text: m['authorName'] as String? ?? '');

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
    _tagsCtrl = TextEditingController(text: widget.tags.join(', '));

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
    _tagsCtrl.dispose();
    _asinCtrl.dispose();
    _isbnCtrl.dispose();
    _languageCtrl.dispose();
    _coverUrlCtrl.dispose();
    _coverSearchTitleCtrl.dispose();
    _coverSearchAuthorCtrl.dispose();
    _detailsScroll.dispose();
    _coverScroll.dispose();
    _matchScroll.dispose();
    _encodeScroll.dispose();
    _embedScroll.dispose();
    SocketService()
      ..removeTaskStartedListener(_onTaskStarted)
      ..removeTaskProgressListener(_onTaskProgress)
      ..removeTaskFinishedListener(_onTaskFinished);
    _searchTitleCtrl.dispose();
    _searchAuthorCtrl.dispose();
    super.dispose();
  }

  // ─── Quick Match ────────────────────────────────────────────

  String _serverMatchProvider() {
    final libraryId = widget.libraryId;
    if (libraryId == null) return 'google';
    for (final library in context.read<LibraryProvider>().libraries) {
      if (library is! Map || library['id'] != libraryId) continue;
      final provider = library['provider']?.toString().trim() ?? '';
      if (provider.isNotEmpty) return provider;
    }
    return 'google';
  }

  Future<void> _runServerQuickMatch() async {
    final l = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      showOverlayToast(context, l.chapterErrorTitleRequired,
          icon: Icons.error_outline_rounded);
      return;
    }

    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _quickMatching = true);
    final author = _authorCtrl.text.trim();
    final result = await api.matchLibraryItem(
      widget.itemId,
      title: title,
      author: author.isEmpty ? null : author,
      provider: _serverMatchProvider(),
    );
    if (!mounted) return;

    final warning = result?['warning']?.toString().trim() ?? '';
    final updated = result?['updated'] == true;
    setState(() {
      _quickMatching = false;
      if (updated) {
        _loadMatchedLibraryItem(result?['libraryItem']);
        _coverVersion++;
      }
    });

    if (updated) context.read<LibraryProvider>().refresh();

    final message = result == null
        ? l.failedToUpdateMetadata
        : warning.isNotEmpty
            ? warning
            : updated
                ? l.editMetadataUpdatedFromMatch
                : l.quickMatchNoUpdates;
    showOverlayToast(
      context,
      message,
      icon: result == null
          ? Icons.error_outline_rounded
          : warning.isNotEmpty
              ? Icons.warning_amber_rounded
              : updated
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
    );
  }

  void _loadMatchedLibraryItem(dynamic rawItem) {
    if (rawItem is! Map) return;
    final media = rawItem['media'];
    if (media is! Map) return;
    final metadata = media['metadata'];
    if (metadata is! Map) return;

    String value(String key) => _safeString(metadata[key]);
    _titleCtrl.text = value('title');
    _subtitleCtrl.text = value('subtitle');
    _authorCtrl.text = value('authorName');
    _narratorCtrl.text = value('narratorName');
    _descCtrl.text = value('description');
    _publisherCtrl.text = value('publisher');
    _yearCtrl.text = value('publishedYear');
    _languageCtrl.text = value('language');
    _genresCtrl.text = value('genres');
    _tagsCtrl.text = _safeString(media['tags']);
    _asinCtrl.text = value('asin');
    _isbnCtrl.text = value('isbn');
    _explicit = metadata['explicit'] == true;
    _abridged = metadata['abridged'] == true;

    final previousSeriesRows = List.of(_seriesRows);
    _seriesRows.clear();
    final series = metadata['series'];
    if (series is List) {
      for (final entry in series) {
        if (entry is! Map) continue;
        _seriesRows.add((
          name: TextEditingController(text: _safeString(entry['name'])),
          seq: TextEditingController(text: _safeString(entry['sequence'])),
        ));
      }
    }
    if (_seriesRows.isEmpty) {
      _seriesRows.add((name: TextEditingController(), seq: TextEditingController()));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in previousSeriesRows) {
        row.name.dispose();
        row.seq.dispose();
      }
    });

    _searchTitleCtrl.text = _titleCtrl.text;
    _searchAuthorCtrl.text = _authorCtrl.text;
    _coverSearchTitleCtrl.text = _titleCtrl.text;
    _coverSearchAuthorCtrl.text = _authorCtrl.text;
  }

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

  Future<void> _applyMatch(Map<String, dynamic> result, Set<String> selected) async {
    final book = result['book'] as Map<String, dynamic>? ?? result;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;

    final update = <String, dynamic>{};

    void add(String key, dynamic value) {
      if (!selected.contains(key)) return;
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
    if (selected.contains('author')) {
      final authorStr = _safeString(book['author']).isNotEmpty
          ? _safeString(book['author'])
          : _safeString(book['authorName']);
      if (authorStr.isNotEmpty) {
        update['authors'] = authorStr.split(',').map((a) => {'name': a.trim()}).where((a) => (a['name'] as String).isNotEmpty).toList();
      }
    }

    if (selected.contains('narrator')) {
      final narratorStr = _safeString(book['narrator']).isNotEmpty
          ? _safeString(book['narrator'])
          : _safeString(book['narratorName']);
      if (narratorStr.isNotEmpty) {
        update['narrators'] = narratorStr.split(',').map((n) => {'name': n.trim()}).where((n) => (n['name'] as String).isNotEmpty).toList();
      }
    }

    // Genres
    if (selected.contains('genres')) {
      final genres = book['genres'] ?? book['tags'];
      if (genres is List && genres.isNotEmpty) {
        update['genres'] = genres.whereType<String>().toList();
      }
    }

    // Series
    if (selected.contains('series')) {
      final series = book['series'];
      if (series is List && series.isNotEmpty) {
        update['series'] = series;
      } else if (series is String && series.isNotEmpty) {
        update['series'] = [
          {'name': series, 'sequence': _safeString(book['volumeNumber'] ?? book['sequence'])}
        ];
      }
    }

    setState(() => _saving = true);

    bool ok = update.isEmpty ? true : await api.updateItemMedia(widget.itemId, update);

    // Cover
    if (ok && selected.contains('cover')) {
      final coverUrl = _safeString(book['cover']).isNotEmpty
          ? _safeString(book['cover'])
          : _safeString(book['image']);
      if (coverUrl.isNotEmpty) {
        await api.updateItemCoverUrl(widget.itemId, coverUrl);
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final l = AppLocalizations.of(context)!;
    if (ok) {
      context.read<LibraryProvider>().refresh();
      _coverVersion++;
      // stays on the edit page
      showOverlayToast(context, l.editMetadataUpdatedFromMatch,
          icon: Icons.check_circle_outline_rounded);
    } else {
      showOverlayToast(context, l.failedToUpdateMetadata,
          icon: Icons.error_outline_rounded);
    }
  }

  void _confirmMatch(Map<String, dynamic> result) {
    final book = result['book'] as Map<String, dynamic>? ?? result;
    final l = AppLocalizations.of(context)!;

    // Build the fields this match offers (key -> preview), so the user can pick
    // which to apply instead of overwriting everything.
    final fields = <String, String>{};
    void tryAdd(String key, dynamic value) {
      final s = _safeString(value);
      if (s.isNotEmpty) fields[key] = s;
    }
    tryAdd('title', book['title']);
    tryAdd('subtitle', book['subtitle']);
    tryAdd('author', book['author'] ?? book['authorName']);
    tryAdd('narrator', book['narrator'] ?? book['narratorName']);
    tryAdd('description', book['description']);
    tryAdd('publisher', book['publisher']);
    tryAdd('publishedYear', book['publishedYear'] ?? book['publishedDate']);
    tryAdd('asin', book['asin']);
    tryAdd('isbn', book['isbn']);
    tryAdd('language', book['language']);

    final genres = book['genres'] ?? book['tags'];
    if (genres is List && genres.isNotEmpty) {
      fields['genres'] = genres.whereType<String>().join(', ');
    }
    final series = book['series'];
    if (series is String && series.isNotEmpty) {
      fields['series'] = series;
    } else if (series is List && series.isNotEmpty && series[0] is Map) {
      fields['series'] = (series[0] as Map)['name']?.toString() ?? '';
    }
    final cover = _safeString(book['cover']).isNotEmpty
        ? _safeString(book['cover'])
        : _safeString(book['image']);
    if (cover.isNotEmpty) fields['cover'] = cover;

    if (fields.isEmpty) return;

    final selected = Set<String>.from(fields.keys);
    final labels = {
      'title': l.titleLabel,
      'subtitle': l.subtitleLabel,
      'author': l.authorLabel,
      'narrator': l.narratorLabel,
      'description': l.descriptionLabel,
      'publisher': l.publisherLabel,
      'publishedYear': l.yearLabel,
      'asin': l.asinLabel,
      'isbn': l.isbnLabel,
      'language': l.languageLabel,
      'genres': l.genresLabel,
      'series': l.seriesLabel,
      'cover': l.metadataLookupCover,
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;
          return AlertDialog(
            constraints: metadataFieldPickerDialogConstraints(
              desktop: isDesktopWorkspace(ctx),
              viewportHeight: MediaQuery.sizeOf(ctx).height,
            ),
            title: Text(l.metadataLookupChooseFields),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: fields.entries.map((e) {
                  final label = labels[e.key] ?? e.key;
                  final clean = e.value.replaceAll(RegExp(r'<[^>]*>'), '');
                  final preview = clean.length > 60 ? '${clean.substring(0, 57)}...' : clean;
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    value: selected.contains(e.key),
                    onChanged: (v) => setDialogState(() {
                      if (v == true) {
                        selected.add(e.key);
                      } else {
                        selected.remove(e.key);
                      }
                    }),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _applyMatch(result, selected);
                      },
                child: Text(l.metadataLookupApplyFields(selected.length)),
              ),
            ],
          );
        });
      },
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
      'explicit': _explicit,
      'abridged': _abridged,
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

    final tagsText = _tagsCtrl.text.trim();
    final tags = tagsText.isNotEmpty
        ? tagsText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    bool ok = await api.updateItemMedia(widget.itemId, update, tags: tags);

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
      _coverVersion++;
      // stays on the edit page
      showOverlayToast(context, l.metadataUpdated,
          icon: Icons.check_circle_outline_rounded);
    } else {
      showOverlayToast(context, l.failedToUpdateMetadata,
          icon: Icons.error_outline_rounded);
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

  // ─── Encode Tab ─────────────────────────────────────────────

  Map<String, dynamic>? get _firstAudioFile {
    if (widget.audioFiles.isEmpty) return null;
    final f = widget.audioFiles.first;
    return f is Map<String, dynamic> ? f : null;
  }

  String? get _currentCodec {
    final c = _firstAudioFile?['codec'] as String?;
    if (c == null || c.isEmpty) return null;
    return c.toUpperCase();
  }

  int? get _currentBitrateKbps {
    final b = (_firstAudioFile?['bitRate'] as num?)?.toInt();
    if (b == null || b <= 0) return null;
    return (b / 1000).round();
  }

  String? _currentChannelText(AppLocalizations l) {
    final ch = (_firstAudioFile?['channels'] as num?)?.toInt();
    if (ch == null) return null;
    final layout = (_firstAudioFile?['channelLayout'] as String?)?.trim();
    final name = layout != null && layout.isNotEmpty
        ? layout
        : (ch == 1 ? l.mono : l.stereo);
    return '$ch ($name)';
  }

  Widget _buildEncodeTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final codecText = _currentCodec;
    final bitrateText = _currentBitrateKbps;
    final channelText = _currentChannelText(l);

    return SingleChildScrollView(
      controller: _encodeScroll,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _encodeLabel(l.codec, tt, cs),
        _encodeToggleRow<String>(
          values: const ['copy', 'aac', 'opus'],
          labels: const ['Copy', 'AAC', 'OPUS'],
          selected: _encodeCodec,
          onTap: (v) => setState(() => _encodeCodec = v),
          cs: cs, tt: tt,
        ),
        if (codecText != null) _currentLine(codecText, cs, tt, l),
        const SizedBox(height: 20),
        _encodeLabel(l.bitrate, tt, cs),
        _encodeToggleRow<String>(
          values: const ['32k', '64k', '128k', '192k'],
          labels: const ['32k', '64k', '128k', '192k'],
          selected: _encodeBitrate,
          onTap: (v) => setState(() => _encodeBitrate = v),
          cs: cs, tt: tt,
        ),
        if (bitrateText != null) _currentLine(l.kbpsValue(bitrateText), cs, tt, l),
        const SizedBox(height: 20),
        _encodeLabel(l.channels, tt, cs),
        _encodeToggleRow<int>(
          values: const [1, 2],
          labels: [l.mono, l.stereo],
          selected: _encodeChannels,
          onTap: (v) => setState(() => _encodeChannels = v),
          cs: cs, tt: tt,
        ),
        if (channelText != null) _currentLine(channelText, cs, tt, l),
        const SizedBox(height: 24),
        if (widget.relPath.isNotEmpty)
          _encodeNote(l.encodeOutputPathNote('.../${widget.relPath}'), cs, tt),
        _encodeNote(l.encodeBackupNote(widget.itemId), cs, tt),
        _encodeNote(l.encodeTimeNote, cs, tt),
        _encodeNote(l.encodeRescanNote, cs, tt),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.icon(
            onPressed: _encoding ? null : _startEncode,
            icon: _encoding
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Icon(Icons.transform_rounded, size: 18),
            label: Text(_encoding
                ? (_taskProgress != null ? l.encodeProgress(_taskProgress!.toStringAsFixed(0)) : l.encodeProgressIndeterminate)
                : l.startM4bEncode),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_encoding) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _taskProgress != null ? (_taskProgress! / 100).clamp(0.0, 1.0) : null,
              minHeight: 6,
              backgroundColor: cs.onSurface.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _taskProgress != null
                ? l.taskProgressKeepsRunning(_taskProgress!.toStringAsFixed(0))
                : l.taskStarting,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ]),
    );
  }

  Widget _buildEmbedTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final multiFile = widget.audioFiles.length > 1;
    return SingleChildScrollView(
      controller: _embedScroll,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.embedIntro,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
        const SizedBox(height: 16),
        InkWell(
          onTap: _embedding ? null : () => setState(() => _shouldBackup = !_shouldBackup),
          borderRadius: BorderRadius.circular(10),
          child: Row(children: [
            Checkbox(
              value: _shouldBackup,
              onChanged: _embedding ? null : (v) => setState(() => _shouldBackup = v ?? true),
            ),
            Expanded(child: Text(l.embedBackupOption, style: tt.bodyMedium)),
          ]),
        ),
        const SizedBox(height: 16),
        _encodeNote(l.embedNoteInFolder, cs, tt),
        if (_shouldBackup) _embedBackupNote(cs, tt, l),
        if (multiFile) _encodeNote(l.embedNoteMultiTrack, cs, tt),
        _encodeNote(l.embedNoteNavigateAway, cs, tt),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.icon(
            onPressed: _embedding ? null : _startEmbed,
            icon: _embedding
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_embedding
                ? (_taskProgress != null ? l.embedProgress(_taskProgress!.toStringAsFixed(0)) : l.embedProgressIndeterminate)
                : l.embedStartButton),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_embedding) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _taskProgress != null ? (_taskProgress! / 100).clamp(0.0, 1.0) : null,
              minHeight: 6,
              backgroundColor: cs.onSurface.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _taskProgress != null
                ? l.taskProgressKeepsRunning(_taskProgress!.toStringAsFixed(0))
                : l.taskStarting,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ]),
    );
  }

  Widget _embedBackupNote(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.star_rounded, size: 14, color: cs.tertiary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(TextSpan(
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
            children: [
              TextSpan(text: l.embedBackupNoteIntro),
              TextSpan(
                text: l.embedBackupNotePath(widget.itemId),
                style: TextStyle(fontFamily: 'monospace', color: cs.onSurface),
              ),
              TextSpan(text: l.embedBackupNoteOutro),
            ],
          )),
        ),
      ]),
    );
  }

  Widget _encodeNote(String text, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.star_rounded, size: 14, color: cs.tertiary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
          ),
        ),
      ]),
    );
  }

  Widget _encodeLabel(String text, TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
    );
  }

  Widget _currentLine(String value, ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(
        TextSpan(
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          children: [
            TextSpan(text: '${l.currentlyLabel} '),
            TextSpan(text: value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _encodeToggleRow<T>({
    required List<T> values,
    required List<String> labels,
    required T selected,
    required void Function(T) onTap,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    return Wrap(spacing: 8, runSpacing: 8, children: List.generate(values.length, (i) {
      final isSel = values[i] == selected;
      return InkWell(
        onTap: () => onTap(values[i]),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? cs.primaryContainer : cs.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? cs.primary : cs.onSurface.withValues(alpha: 0.1)),
          ),
          child: Text(
            labels[i],
            style: tt.bodyMedium?.copyWith(
              color: isSel ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    }));
  }

  Future<void> _startEncode() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() {
      _runningAction = 'encode-m4b';
      _taskProgress = 0;
    });
    final ok = await api.startM4bEncode(
      widget.itemId,
      codec: _encodeCodec,
      bitrate: _encodeBitrate,
      channels: _encodeChannels,
    );
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    if (!ok) {
      setState(() {
        _runningAction = null;
        _taskProgress = null;
      });
      showOverlayToast(context, l.encodeFailed,
          icon: Icons.error_outline_rounded);
      return;
    }
    showOverlayToast(context, l.encodeStarted,
        icon: Icons.graphic_eq_rounded);
  }

  Future<void> _startEmbed() async {
    final l = AppLocalizations.of(context)!;
    final count = widget.audioFiles.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.embedDialogTitle),
        content: Text(
          l.embedConfirmMessage(count, _shouldBackup ? l.embedConfirmBackupClause : ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(dctx, true), child: Text(l.embedConfirmAction)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() {
      _runningAction = 'embed-metadata';
      _taskProgress = 0;
    });
    final ok = await api.embedMetadata(widget.itemId, backup: _shouldBackup);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _runningAction = null;
        _taskProgress = null;
      });
      showOverlayToast(context, l.embedCouldNotStart,
          icon: Icons.error_outline_rounded);
      return;
    }
    showOverlayToast(context, l.embedStarted,
        icon: Icons.edit_note_rounded);
  }

  void _onTaskStarted(Map<String, dynamic> data) {
    if (!mounted) return;
    final id = (data['data'] as Map?)?['libraryItemId'] ?? data['libraryItemId'];
    if (id != widget.itemId) return;
    final action = data['action'] as String?;
    if (action != 'encode-m4b' && action != 'embed-metadata') return;
    setState(() {
      _runningAction = action;
      _taskProgress = 0;
    });
  }

  Future<void> _restoreRunningTask() async {
    if (!mounted) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final tasks = await api.getServerTasks();
    if (!mounted || _runningAction != null || tasks == null) return;
    final matching = tasks.where((task) {
      final itemId = (task['data'] as Map?)?['libraryItemId']?.toString();
      final action = task['action'] as String?;
      return itemId == widget.itemId &&
          task['isFinished'] != true &&
          (action == 'encode-m4b' || action == 'embed-metadata');
    }).toList()
      ..sort((a, b) =>
          ((b['startedAt'] as num?)?.toInt() ?? 0)
              .compareTo((a['startedAt'] as num?)?.toInt() ?? 0));
    if (matching.isEmpty || !mounted || _runningAction != null) return;
    setState(() {
      _runningAction = matching.first['action'] as String?;
      _taskProgress = null;
    });
  }

  void _onTaskProgress(Map<String, dynamic> data) {
    // task_progress is generic; only attribute it once we know what's running.
    if (!mounted || _runningAction == null) return;
    if (data['libraryItemId'] != widget.itemId) return;
    final p = (data['progress'] as num?)?.toDouble();
    if (p == null) return;
    setState(() => _taskProgress = p.clamp(0, 100));
  }

  void _onTaskFinished(Map<String, dynamic> data) {
    if (!mounted) return;
    final id = (data['data'] as Map?)?['libraryItemId'] ?? data['libraryItemId'];
    if (id != null && id != widget.itemId) return;
    final wasRunning = _runningAction;
    final action = data['action'] as String? ?? wasRunning;
    setState(() {
      _runningAction = null;
      _taskProgress = null;
    });
    if (wasRunning == null) return;
    final l = AppLocalizations.of(context)!;
    final failed = data['error'] != null || data['isFailed'] == true;
    if (!failed) context.read<LibraryProvider>().refresh();
    final embed = action == 'embed-metadata';
    final msg = failed
        ? (embed ? l.embedFailed : l.encodeFailedTask)
        : (embed ? l.embedComplete : l.encodeComplete);
    showOverlayToast(
      context,
      msg,
      icon: failed
          ? Icons.error_outline_rounded
          : Icons.check_circle_outline_rounded,
    );
  }

  // ─── Build ──────────────────────────────────────────────────

  String _tabLabel(_ETab t, AppLocalizations l) => switch (t) {
        _ETab.details => l.editTabDetails,
        _ETab.cover => l.editTabCover,
        _ETab.chapters => l.chapters,
        _ETab.match => l.editTabMatch,
        _ETab.encode => l.encodeTab,
        _ETab.embed => l.editTabEmbed,
      };

  Widget _tabBody(_ETab t, ColorScheme cs, TextTheme tt, AppLocalizations l) => switch (t) {
        _ETab.details => _buildCustomTab(cs, tt, l),
        _ETab.cover => _buildCoverTab(cs, tt, l),
        _ETab.chapters => ChapterEditBody(itemId: widget.itemId, bookTitle: widget.bookTitle),
        _ETab.match => _buildQuickMatchTab(cs, tt, l),
        _ETab.encode => _buildEncodeTab(cs, tt, l),
        _ETab.embed => _buildEmbedTab(cs, tt, l),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Column(children: [
      TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        tabs: [for (final t in _tabs) Tab(text: _tabLabel(t, l))],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [for (final t in _tabs) _tabBody(t, cs, tt, l)],
        ),
      ),
    ]);
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
            ? ListView(controller: _matchScroll, children: [
                const SizedBox(height: 80),
                Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurfaceVariant)),
              ])
            : _searchResults.isEmpty
                ? ListView(controller: _matchScroll, children: [
                    const SizedBox(height: 80),
                    Center(child: Text(
                      _hasSearched ? l.noResultsFound : l.searchForMetadataAbove,
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    )),
                  ])
                : ListView.separated(
                    controller: _matchScroll,
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
    return LayoutBuilder(
      builder: (context, constraints) => _buildCustomTabLayout(
        cs,
        tt,
        l,
        wide: constraints.maxWidth >= _metadataDetailsWideBreakpoint,
      ),
    );
  }

  Widget _buildCustomTabLayout(ColorScheme cs, TextTheme tt, AppLocalizations l, {required bool wide}) {
    final filePaths = fullLibraryFilePaths(widget.libraryFiles);
    return Column(children: [
      // Save button bar
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
        child: Row(children: [
          if (widget.isAdmin)
            OutlinedButton.icon(
              key: MetadataEditView.quickMatchButtonKey,
              onPressed: _saving || _quickMatching ? null : _runServerQuickMatch,
              icon: _quickMatching
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                  : const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: Text(l.quickMatch),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _saving || _quickMatching ? null : _saveCustom,
            icon: _saving
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(l.save),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          controller: _detailsScroll,
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom),
          children: [
            if (wide) ...[
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _field(l.titleLabel, _titleCtrl, tt)),
                const SizedBox(width: 16),
                Expanded(child: _field(l.subtitleLabel, _subtitleCtrl, tt)),
              ]),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _field(l.authorLabel, _authorCtrl, tt)),
                const SizedBox(width: 16),
                Expanded(child: _field(l.narratorLabel, _narratorCtrl, tt)),
              ]),
            ] else ...[
              _field(l.titleLabel, _titleCtrl, tt),
              _field(l.subtitleLabel, _subtitleCtrl, tt),
              _field(l.authorLabel, _authorCtrl, tt),
              _field(l.narratorLabel, _narratorCtrl, tt),
            ],
            for (int i = 0; i < _seriesRows.length; i++) ...[
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
              _suggestionChips(_seriesRows[i].name, _allSeries, multi: false),
            ],
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
            _field(
              l.descriptionLabel,
              _descCtrl,
              tt,
              maxLines: wide ? null : 5,
              minLines: wide ? 10 : null,
              fieldKey: MetadataEditView.descriptionFieldKey,
            ),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 2, child: _field(l.publisherLabel, _publisherCtrl, tt)),
                const SizedBox(width: 16),
                Expanded(child: _field(l.yearLabel, _yearCtrl, tt, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _field(l.languageLabel, _languageCtrl, tt)),
              ])
            else ...[
              _field(l.publisherLabel, _publisherCtrl, tt),
              Row(children: [
                Expanded(child: _field(l.yearLabel, _yearCtrl, tt, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field(l.languageLabel, _languageCtrl, tt)),
              ]),
            ],
            _field(l.genresLabel, _genresCtrl, tt, hint: l.commaSeparated),
            _suggestionChips(_genresCtrl, _allGenres, multi: true),
            _field(l.tagsLabel, _tagsCtrl, tt, hint: l.commaSeparated),
            _suggestionChips(_tagsCtrl, _allTags, multi: true),
            Row(children: [
              Expanded(child: _field(l.asinLabel, _asinCtrl, tt)),
              const SizedBox(width: 12),
              Expanded(child: _field(l.isbnLabel, _isbnCtrl, tt)),
            ]),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _explicit = !_explicit),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(children: [
                    Checkbox(
                      value: _explicit,
                      onChanged: (v) => setState(() => _explicit = v ?? false),
                    ),
                    Expanded(child: Text(l.explicitContent, style: tt.bodyMedium)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _abridged = !_abridged),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(children: [
                    Checkbox(
                      value: _abridged,
                      onChanged: (v) => setState(() => _abridged = v ?? false),
                    ),
                    Expanded(child: Text(l.abridged, style: tt.bodyMedium)),
                  ]),
                ),
              ),
            ]),
            if (widget.isAdmin && filePaths.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(l.libraryFilesCount(filePaths.length),
                key: MetadataEditView.filePathsSectionKey,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final path in filePaths)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableText(path, style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant, height: 1.35)),
                ),
            ],
          ],
        ),
      ),
    ]);
  }

  // ─── Cover Tab ──────────────────────────────────────────────

  Widget _buildCoverTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final base = _safeBaseCoverUrl();
    final coverUrl = base.isEmpty ? '' : '$base?v=$_coverVersion';
    return Column(children: [
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
          controller: _coverScroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    httpHeaders: context.read<AuthProvider>().apiService?.mediaHeaders,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => _placeholder(cs),
                    placeholder: (_, __) => _placeholder(cs),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            Text(l.coverSearchTitle, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(l.coverSearchRefineHint,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _coverSearchTitleCtrl,
              decoration: InputDecoration(
                labelText: l.title,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: tt.bodyMedium,
              onSubmitted: (_) => _searchCovers(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _coverSearchAuthorCtrl,
              decoration: InputDecoration(
                labelText: l.author,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: tt.bodyMedium,
              onSubmitted: (_) => _searchCovers(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              DropdownButton<String>(
                value: _coverProvider,
                onChanged: (v) => setState(() => _coverProvider = v ?? 'best'),
                items: const [
                  DropdownMenuItem(value: 'best', child: Text('Best')),
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'google', child: Text('Google')),
                  DropdownMenuItem(value: 'fantlab', child: Text('FantLab')),
                  DropdownMenuItem(value: 'audible', child: Text('Audible')),
                  DropdownMenuItem(value: 'itunes', child: Text('iTunes')),
                  DropdownMenuItem(value: 'openlibrary', child: Text('OpenLibrary')),
                  DropdownMenuItem(value: 'audiobookcovers', child: Text('AudiobookCovers.com')),
                ],
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _coverSearching ? null : _searchCovers,
                icon: _coverSearching
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search_rounded, size: 18),
                label: Text(l.search),
              ),
            ]),
            if (_coverResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
                children: [
                  for (final url in _coverResults)
                    GestureDetector(
                      onTap: () => _showCoverPreview(url),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => _placeholder(cs),
                          errorWidget: (_, __, ___) => _placeholder(cs),
                        ),
                      ),
                    ),
                ],
              ),
              if (_coverSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ],
          ],
        ),
      ),
    ]);
  }

  String _safeBaseCoverUrl() {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return '';
    final base = api.baseUrl.endsWith('/') ? api.baseUrl.substring(0, api.baseUrl.length - 1) : api.baseUrl;
    return '$base/api/items/${widget.itemId}/cover';
  }

  static const _bestCoverProviders = ['audiobookcovers', 'google', 'fantlab', 'audible'];
  static const _allCoverProviders = ['google', 'fantlab', 'audible', 'openlibrary', 'itunes', 'audiobookcovers'];

  Future<void> _searchCovers() async {
    final l = AppLocalizations.of(context)!;
    final api = context.read<AuthProvider>().apiService;
    final title = _coverSearchTitleCtrl.text.trim();
    if (api == null || title.isEmpty) {
      showOverlayToast(context, l.coverEnterTitleFirst,
          icon: Icons.error_outline_rounded);
      return;
    }
    final author = _coverSearchAuthorCtrl.text.trim();
    final providers = switch (_coverProvider) {
      'best' => _bestCoverProviders,
      'all' => _allCoverProviders,
      _ => [_coverProvider],
    };
    // Query one provider at a time and append results as they arrive, so a
    // slow provider can't time out the whole search and covers stream in.
    setState(() {
      _coverSearching = true;
      _coverResults = [];
    });
    final seen = <String>{};
    for (final p in providers) {
      if (!mounted) return;
      final results = await api.searchCovers(title, author: author, provider: p);
      if (!mounted) return;
      final fresh = results.where(seen.add).toList();
      if (fresh.isNotEmpty) setState(() => _coverResults = [..._coverResults, ...fresh]);
    }
    if (!mounted) return;
    setState(() => _coverSearching = false);
    if (_coverResults.isEmpty) {
      showOverlayToast(context, l.coverNoneFound,
          icon: Icons.search_off_rounded);
    }
  }

  Future<void> _applyCoverUrl(String url) async {
    final l = AppLocalizations.of(context)!;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _saving = true);
    final ok = await api.updateItemCoverUrl(widget.itemId, url);
    if (!mounted) return;
    if (ok) context.read<LibraryProvider>().refresh();
    setState(() {
      _saving = false;
      if (ok) _coverVersion++;
    });
    showOverlayToast(
      context,
      ok ? l.coverUpdated : l.coverCouldNotUpdate,
      icon: ok
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
    );
  }

  /// Show a cover result full-size with its resolution and an explicit Apply.
  Future<void> _showCoverPreview(String url) async {
    Size? size;
    try {
      final provider = CachedNetworkImageProvider(url);
      final completer = Completer<Size>();
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener((info, _) {
        if (!completer.isCompleted) {
          completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
        }
        stream.removeListener(listener);
      }, onError: (e, __) {
        if (!completer.isCompleted) completer.completeError(e);
        stream.removeListener(listener);
      });
      stream.addListener(listener);
      size = await completer.future.timeout(const Duration(seconds: 10));
    } catch (_) {}

    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final apply = await showDialog<bool>(
      context: context,
      builder: (dctx) {
        final cs = Theme.of(dctx).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const SizedBox(
                          height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (_, __, ___) => const SizedBox(
                          height: 200, child: Center(child: Icon(Icons.broken_image_rounded))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                size != null ? '${size.width.toInt()} x ${size.height.toInt()}' : l.coverUnknownResolution,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(children: [
                TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text(l.cancel)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dctx, true),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(l.coverApply),
                ),
              ]),
            ]),
          ),
        );
      },
    );
    if (apply == true && mounted) {
      await _applyCoverUrl(url);
    }
  }

  Widget _field(String label, TextEditingController ctrl, TextTheme tt, {int? maxLines = 1, int? minLines, String? hint, TextInputType? keyboardType, Key? fieldKey}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: fieldKey,
        controller: ctrl,
        maxLines: maxLines,
        minLines: minLines,
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

  Future<void> _loadFilterSuggestions() async {
    final api = context.read<AuthProvider>().apiService;
    final libId = widget.libraryId ?? context.read<LibraryProvider>().selectedLibraryId;
    if (api == null || libId == null) return;
    final data = await api.getLibraryFilterData(libId);
    if (data == null || !mounted) return;
    List<String> names(String key) {
      final raw = data[key] as List<dynamic>? ?? [];
      return raw
          .map((e) => e is Map ? (e['name'] as String? ?? '') : e.toString())
          .where((s) => s.isNotEmpty)
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    setState(() {
      _allSeries = names('series');
      _allGenres = names('genres');
      _allTags = names('tags');
    });
  }

  /// Inline typeahead under a field: as the user types, shows up to 6 existing
  /// library values that match, tapping one fills it in. For [multi] fields
  /// (comma-separated genres/tags) it completes the word after the last comma
  /// and leaves a trailing ", " ready for the next one.
  Widget _suggestionChips(TextEditingController ctrl, List<String> source, {required bool multi}) {
    if (source.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (context, value, _) {
        final full = value.text;
        final existing = (multi ? full.split(',') : [full])
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toSet();
        final token = (multi ? full.split(',').last : full).trim();
        if (token.isEmpty) return const SizedBox.shrink();
        final tl = token.toLowerCase();
        final matches = source.where((s) {
          final sl = s.toLowerCase();
          return sl.contains(tl) && sl != tl && !existing.contains(sl);
        }).toList()
          ..sort((a, b) {
            final ar = a.toLowerCase().startsWith(tl) ? 0 : 1;
            final br = b.toLowerCase().startsWith(tl) ? 0 : 1;
            return ar != br ? ar - br : a.length - b.length;
          });
        if (matches.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 6, runSpacing: 6,
            children: matches.take(6).map((name) => ActionChip(
              label: Text(name, style: tt.bodySmall),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: cs.primary.withValues(alpha: 0.10),
              side: BorderSide(color: cs.primary.withValues(alpha: 0.25)),
              onPressed: () {
                final String next;
                if (multi) {
                  final parts = full.split(',').map((s) => s.trim()).toList();
                  parts[parts.length - 1] = name;
                  next = '${parts.join(', ')}, ';
                } else {
                  next = name;
                }
                ctrl.value = TextEditingValue(
                  text: next,
                  selection: TextSelection.collapsed(offset: next.length),
                );
              },
            )).toList(),
          ),
        );
      },
    );
  }
}

List<String> fullLibraryFilePaths(List<dynamic> libraryFiles) {
  final paths = <String>[];
  for (final file in libraryFiles) {
    if (file is! Map) continue;
    final metadata = file['metadata'];
    if (metadata is! Map) continue;
    final path = metadata['path']?.toString().trim() ?? '';
    if (path.isNotEmpty && !paths.contains(path)) paths.add(path);
  }
  return paths;
}
