import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/app_shell.dart';
import '../services/audio_player_service.dart';
import '../services/ebook_annotation_service.dart';
import '../services/scoped_prefs.dart';

class EbookReaderScreen extends StatefulWidget {
  final String itemId;
  final String title;
  final Map<String, dynamic> ebookFile;

  const EbookReaderScreen({
    super.key,
    required this.itemId,
    required this.title,
    required this.ebookFile,
  });

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  EpubController? _epubController;
  bool _loading = true;
  String? _error;
  File? _cachedFile;
  String? _initialCfi;
  bool _showControls = false;
  List<EpubChapter> _chapters = [];
  double _progress = 0;
  int _chapterPage = 0;
  int _chapterPageTotal = 0;

  // Annotations
  final _annotationService = EbookAnnotationService();
  List<EbookAnnotation> _annotations = [];
  bool _hasBookmarkAtCurrent = false;
  String? _currentCfi;

  // Audiobook sync data
  Map<String, dynamic>? _itemData;
  List<dynamic> _audioChapters = [];
  bool _hasAudiobook = false;

  // Selection state for highlight menu
  String? _selectionText;
  String? _selectionCfi;
  Rect? _selectionRect;
  // Track touch start position to distinguish taps from swipes
  double? _touchDownX;
  double? _touchDownY;

  // Key to force-rebuild EpubViewer when layout mode changes
  int _viewerKey = 0;

  // Reader settings
  int _fontSize = 16;
  double _lineHeight = 1.4;
  int _margin = 16;
  bool _isPaginated = true;

  static const _kFontSize = 'ereader_fontSize';
  static const _kLineHeight = 'ereader_lineHeight';
  static const _kMargin = 'ereader_margin';
  static const _kPaginated = 'ereader_paginated';

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();
    _loadInitialLocation();
    _loadSettings().then((_) => _downloadAndOpen());
    _fetchItemData();
    _setFullscreen(true);
  }

  Future<void> _loadSettings() async {
    _fontSize = await ScopedPrefs.getInt(_kFontSize) ?? 16;
    _lineHeight = await ScopedPrefs.getDouble(_kLineHeight) ?? 1.4;
    _margin = await ScopedPrefs.getInt(_kMargin) ?? 16;
    _isPaginated = await ScopedPrefs.getBool(_kPaginated) ?? true;
    if (mounted) setState(() {});
  }

  EpubTheme _buildTheme(bool isDark) {
    return EpubTheme.custom(
      foregroundColor: isDark ? Colors.white : Colors.black,
      backgroundDecoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
      ),
      customCss: {
        'body': {
          'color': isDark ? '#ffffff' : '#000000',
          'background': isDark ? '#000000' : '#ffffff',
          'line-height': '$_lineHeight',
          'padding': '${_margin}px !important',
          'margin': '0px !important',
          'box-sizing': 'border-box !important',
          'max-width': '100vw !important',
          'overflow-x': 'hidden !important',
          '-webkit-overflow-scrolling': 'touch',
          'will-change': 'scroll-position',
        },
        'p, div, span, h1, h2, h3, h4, h5, h6, li, td, th, a, em, strong, blockquote': {
          'color': 'inherit !important',
        },
      },
    );
  }

  void _applySettings() {
    _epubController?.setFontSize(fontSize: _fontSize.toDouble());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _epubController?.updateTheme(theme: _buildTheme(isDark));
  }

  Future<void> _updateFontSize(int size) async {
    setState(() => _fontSize = size);
    _epubController?.setFontSize(fontSize: size.toDouble());
    await ScopedPrefs.setInt(_kFontSize, size);
  }

  Future<void> _updateLineHeight(double height) async {
    setState(() => _lineHeight = height);
    _applySettings();
    await ScopedPrefs.setDouble(_kLineHeight, height);
  }

  Future<void> _updateMargin(int margin) async {
    setState(() => _margin = margin);
    _applySettings();
    await ScopedPrefs.setInt(_kMargin, margin);
  }

  Future<void> _updatePaginated(bool paginated) async {
    // Save current position before rebuilding
    try {
      final loc = await _epubController?.getCurrentLocation();
      if (loc != null) _initialCfi = loc.startCfi;
    } catch (_) {}
    _epubController = EpubController();
    setState(() {
      _isPaginated = paginated;
      _viewerKey++;
    });
    await ScopedPrefs.setBool(_kPaginated, paginated);
  }

  @override
  void dispose() {
    // Restore system UI when leaving
    _setFullscreen(false);
    super.dispose();
  }

  void _setFullscreen(bool fullscreen) {
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _loadInitialLocation() {
    final lib = context.read<LibraryProvider>();
    final progressData = lib.getProgressData(widget.itemId);
    final loc = progressData?['ebookLocation'] as String?;
    if (loc != null && loc.isNotEmpty) {
      _initialCfi = loc;
    }
  }

  Future<void> _downloadAndOpen() async {
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.apiService;
      if (api == null) {
        setState(() { _error = 'Not connected to server'; _loading = false; });
        return;
      }

      final ino = widget.ebookFile['ino'] as String?;
      if (ino == null) {
        setState(() { _error = 'No ebook file found'; _loading = false; });
        return;
      }

      final ebookName = widget.ebookFile['metadata']?['filename'] as String?
          ?? widget.ebookFile['name'] as String?
          ?? 'book.epub';
      final ext = ebookName.contains('.')
          ? ebookName.substring(ebookName.lastIndexOf('.'))
          : '.epub';
      final safeTitle = widget.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();

      final cacheDir = await getTemporaryDirectory();
      final cachedFile = File('${cacheDir.path}/ereader_$safeTitle$ext');

      if (!cachedFile.existsSync()) {
        final cleanBase = api.baseUrl.endsWith('/')
            ? api.baseUrl.substring(0, api.baseUrl.length - 1)
            : api.baseUrl;
        final url = '$cleanBase/api/items/${widget.itemId}/file/$ino';

        final request = http.Request('GET', Uri.parse(url));
        request.followRedirects = false;
        api.mediaHeaders.forEach((k, v) => request.headers[k] = v);
        final client = http.Client();
        try {
          var response = await client.send(request);

          // Follow redirects preserving auth headers
          var redirects = 0;
          while ([301, 302, 303, 307, 308].contains(response.statusCode) && redirects < 5) {
            final location = response.headers['location'];
            if (location == null) break;
            final redirectUrl = Uri.parse(url).resolve(location);
            final rReq = http.Request('GET', redirectUrl);
            api.mediaHeaders.forEach((k, v) => rReq.headers[k] = v);
            rReq.followRedirects = false;
            response = await client.send(rReq);
            redirects++;
          }

          if (response.statusCode != 200) {
            setState(() { _error = 'Failed to download ebook (${response.statusCode})'; _loading = false; });
            return;
          }

          final ct = response.headers['content-type'] ?? '';
          if (ct.contains('text/html')) {
            setState(() { _error = 'Server returned an error page'; _loading = false; });
            return;
          }

          final sink = cachedFile.openWrite();
          try {
            await response.stream.pipe(sink);
          } finally {
            await sink.close();
          }
        } finally {
          client.close();
        }
      }

      if (mounted) {
        setState(() {
          _cachedFile = cachedFile;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[EbookReader] Error: $e');
      if (mounted) {
        setState(() { _error = 'Error loading ebook: $e'; _loading = false; });
      }
    }
  }

  void _syncProgress(String cfi, double progress) {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    api.updateEbookProgress(
      widget.itemId,
      ebookLocation: cfi,
      ebookProgress: progress,
    );
  }

  Future<void> _fetchItemData() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    try {
      final item = await api.getLibraryItem(widget.itemId);
      if (item != null && mounted) {
        _itemData = item;
        final media = item['media'] as Map<String, dynamic>? ?? {};
        _audioChapters = media['chapters'] as List<dynamic>? ?? [];
        final duration = (media['duration'] as num?)?.toDouble() ?? 0;
        _hasAudiobook = duration > 0 && _audioChapters.isNotEmpty;
        setState(() {});
      }
    } catch (e) {
      debugPrint('[EbookReader] Failed to fetch item data: $e');
    }
  }

  /// Match an ebook chapter title to the best audiobook chapter.
  int _matchAudioChapter(String ebookTitle) {
    if (_audioChapters.isEmpty) return -1;

    final normalised = _normalise(ebookTitle);

    // Exact match first
    for (var i = 0; i < _audioChapters.length; i++) {
      final audioTitle = _audioChapters[i]['title'] as String? ?? '';
      if (_normalise(audioTitle) == normalised) return i;
    }

    // Substring match - check if one contains the other
    for (var i = 0; i < _audioChapters.length; i++) {
      final audioNorm = _normalise(_audioChapters[i]['title'] as String? ?? '');
      if (audioNorm.contains(normalised) || normalised.contains(audioNorm)) {
        return i;
      }
    }

    // Number-based match - extract chapter numbers
    final ebookNum = _extractChapterNumber(normalised);
    if (ebookNum != null) {
      for (var i = 0; i < _audioChapters.length; i++) {
        final audioNum = _extractChapterNumber(
          _normalise(_audioChapters[i]['title'] as String? ?? ''),
        );
        if (audioNum == ebookNum) return i;
      }
    }

    return -1;
  }

  String _normalise(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

  int? _extractChapterNumber(String normalised) {
    final match = RegExp(r'(?:chapter|ch|part)\s*(\d+)').firstMatch(normalised);
    if (match != null) return int.tryParse(match.group(1)!);
    // Try just a standalone number
    final numMatch = RegExp(r'^\d+$').firstMatch(normalised.trim());
    if (numMatch != null) return int.tryParse(numMatch.group(0)!);
    return null;
  }

  Future<void> _listenFromHere() async {
    if (!_hasAudiobook || _itemData == null) return;

    final media = _itemData!['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};

    // Get current ebook chapter title via JS
    final currentChapterResult = await _epubController?.webViewController
        ?.evaluateJavascript(source: '''
      (function() {
        var loc = rendition.currentLocation();
        if (loc && loc.start && loc.start.href) {
          var href = loc.start.href;
          var toc = book.navigation.toc;
          function findTitle(items, href) {
            for (var i = 0; i < items.length; i++) {
              if (items[i].href && items[i].href.indexOf(href) !== -1) return items[i].label;
              if (items[i].subitems && items[i].subitems.length > 0) {
                var found = findTitle(items[i].subitems, href);
                if (found) return found;
              }
            }
            return null;
          }
          return findTitle(toc, href) || href;
        }
        return null;
      })();
    ''');

    final ebookChapterTitle = currentChapterResult?.toString().trim();
    if (ebookChapterTitle == null || ebookChapterTitle == 'null' || ebookChapterTitle.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine current chapter')),
        );
      }
      return;
    }

    debugPrint('[EbookReader] Current ebook chapter: $ebookChapterTitle');

    // Match to audio chapter
    var audioIdx = _matchAudioChapter(ebookChapterTitle);

    // Fallback: try index-based matching using ebook chapter list
    if (audioIdx == -1 && _chapters.isNotEmpty) {
      // Find which ebook chapter we're in by matching the title
      final ebookIdx = _chapters.indexWhere((ch) =>
          _normalise(ch.title) == _normalise(ebookChapterTitle) ||
          _normalise(ch.title).contains(_normalise(ebookChapterTitle)) ||
          _normalise(ebookChapterTitle).contains(_normalise(ch.title)));
      if (ebookIdx != -1 && ebookIdx < _audioChapters.length) {
        audioIdx = ebookIdx;
        debugPrint('[EbookReader] Fallback index match: ebook[$ebookIdx] -> audio[$audioIdx]');
      }
    }

    if (audioIdx == -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No matching audio chapter for "$ebookChapterTitle"')),
        );
      }
      return;
    }

    // Calculate position within chapter using page progress
    final audioChapter = _audioChapters[audioIdx];
    final chapterStart = (audioChapter['start'] as num).toDouble();
    final chapterEnd = (audioChapter['end'] as num).toDouble();
    final chapterDuration = chapterEnd - chapterStart;

    double chapterProgress = 0;
    if (_chapterPageTotal > 0) {
      chapterProgress = (_chapterPage / _chapterPageTotal).clamp(0.0, 1.0);
    }

    final startTime = chapterStart + (chapterDuration * chapterProgress);
    final audioTitle = audioChapter['title'] as String? ?? 'Chapter ${audioIdx + 1}';

    debugPrint('[EbookReader] Syncing to audio: "$audioTitle" at ${startTime.toStringAsFixed(1)}s '
        '(${(chapterProgress * 100).toStringAsFixed(0)}% through chapter)');

    // Start audiobook playback
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;

    final player = AudioPlayerService();
    final title = metadata['title'] as String? ?? widget.title;
    final author = metadata['authorName'] as String? ?? '';
    final coverPath = _itemData!['id'] as String? ?? widget.itemId;
    final coverUrl = '${api.baseUrl}/api/items/$coverPath/cover';
    final totalDuration = (media['duration'] as num?)?.toDouble() ?? 0;

    final error = await player.playItem(
      api: api,
      itemId: widget.itemId,
      title: title,
      author: author,
      coverUrl: coverUrl,
      totalDuration: totalDuration,
      chapters: _audioChapters,
      startTime: startTime,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    if (mounted) {
      context.read<LibraryProvider>()
        ..addToAbsorbing(widget.itemId)
        ..refreshLocalProgress()
        ..refresh();
    }

    // Navigate to the audio player
    if (mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppShell.goToAbsorbingGlobal();
      });
    }
  }

  Future<void> _loadAnnotations() async {
    _annotations = await _annotationService.getAnnotations(widget.itemId);
    if (mounted) setState(() {});
  }

  void _restoreHighlights() {
    for (final a in _annotations) {
      if (a.type == AnnotationType.highlight && a.color != null) {
        _epubController?.addHighlight(
          cfi: a.cfi,
          color: Color(int.parse('FF${a.color!.hex.substring(1)}', radix: 16)),
          opacity: 0.35,
        );
      }
    }
  }

  void _setupPageInfoHandler() {
    _epubController?.webViewController?.addJavaScriptHandler(
      handlerName: 'pageInfo',
      callback: (args) {
        if (!mounted || args.isEmpty) return;
        final data = args[0] as Map<String, dynamic>?;
        if (data == null) return;
        final page = data['page'] as int? ?? 0;
        final total = data['total'] as int? ?? 0;
        if (page != _chapterPage || total != _chapterPageTotal) {
          setState(() {
            _chapterPage = page;
            _chapterPageTotal = total;
          });
        }
      },
    );
    _epubController?.webViewController?.evaluateJavascript(
      source: '''
        (function() {
          rendition.on('relocated', function(location) {
            if (location && location.start && location.start.displayed) {
              window.flutter_inappwebview.callHandler('pageInfo', {
                page: location.start.displayed.page,
                total: location.start.displayed.total
              });
            }
          });
        })();
      ''',
    );
  }

  Future<void> _addHighlight(HighlightColor color) async {
    if (_selectionCfi == null || _selectionText == null) return;
    final annotation = await _annotationService.addHighlight(
      itemId: widget.itemId,
      cfi: _selectionCfi!,
      selectedText: _selectionText!,
      color: color,
    );
    _epubController?.addHighlight(
      cfi: annotation.cfi,
      color: Color(int.parse('FF${color.hex.substring(1)}', radix: 16)),
      opacity: 0.35,
    );
    _annotations.insert(0, annotation);
    _clearSelection();
    if (mounted) setState(() {});
  }

  Future<void> _removeHighlight(EbookAnnotation annotation) async {
    _epubController?.removeHighlight(cfi: annotation.cfi);
    await _annotationService.delete(
      itemId: widget.itemId,
      annotationId: annotation.id,
    );
    _annotations.removeWhere((a) => a.id == annotation.id);
    if (mounted) setState(() {});
  }

  Future<void> _toggleBookmark() async {
    final cfi = _currentCfi;
    if (cfi == null) return;

    if (_hasBookmarkAtCurrent) {
      // Remove existing bookmark at this location
      final existing = _annotations.where(
        (a) => a.type == AnnotationType.bookmark && a.cfi == cfi,
      ).toList();
      for (final bm in existing) {
        await _annotationService.delete(
          itemId: widget.itemId,
          annotationId: bm.id,
        );
        _annotations.removeWhere((a) => a.id == bm.id);
      }
    } else {
      final annotation = await _annotationService.addBookmark(
        itemId: widget.itemId,
        cfi: cfi,
      );
      _annotations.insert(0, annotation);
    }
    _updateBookmarkState();
    if (mounted) setState(() {});
  }

  void _updateBookmarkState() {
    final cfi = _currentCfi;
    _hasBookmarkAtCurrent = cfi != null &&
        _annotations.any((a) => a.type == AnnotationType.bookmark && a.cfi == cfi);
  }

  void _clearSelection() {
    _selectionText = null;
    _selectionCfi = null;
    _selectionRect = null;
  }

  Widget _divider(ColorScheme cs) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Container(width: 1, height: 24, color: cs.onSurface.withValues(alpha: 0.15)),
  );

  void _copySelection() {
    if (_selectionText == null) return;
    Clipboard.setData(ClipboardData(text: _selectionText!));
    setState(() => _clearSelection());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  void _searchSelection() {
    if (_selectionText == null) return;
    final query = Uri.encodeComponent(_selectionText!.trim());
    launchUrl(Uri.parse('https://www.google.com/search?q=$query'), mode: LaunchMode.externalApplication);
    setState(() => _clearSelection());
  }

  void _defineSelection() {
    if (_selectionText == null) return;
    final word = _selectionText!.trim().split(RegExp(r'\s+')).first;
    final query = Uri.encodeComponent('define $word');
    launchUrl(Uri.parse('https://www.google.com/search?q=$query'), mode: LaunchMode.externalApplication);
    setState(() => _clearSelection());
  }

  void _onSelection(String text, String cfi, Rect selRect, Rect vRect) {
    if (text.trim().isEmpty) return;
    setState(() {
      _selectionText = text;
      _selectionCfi = cfi;
      _selectionRect = selRect;
    });
  }

  Future<void> _addNoteToAnnotation(EbookAnnotation annotation) async {
    final controller = TextEditingController(text: annotation.note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Note'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Add a note...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _annotationService.updateNote(
        itemId: widget.itemId,
        annotationId: annotation.id,
        note: result.isEmpty ? null : result,
      );
      annotation.note = result.isEmpty ? null : result;
      if (mounted) setState(() {});
    }
  }

  void _navigateToChapter(String href) {
    final escaped = href.replaceAll("'", "\\'");
    _epubController?.webViewController?.evaluateJavascript(
      source: '''
        (function() {
          rendition.display('$escaped').then(function() {
            rendition.resize();
          });
        })();
      ''',
    );
  }

  List<EpubChapter> _flattenChapters(List<EpubChapter> chapters) {
    final flat = <EpubChapter>[];
    for (final ch in chapters) {
      flat.add(ch);
      if (ch.subitems.isNotEmpty) {
        flat.addAll(_flattenChapters(ch.subitems));
      }
    }
    return flat;
  }

  void _showChapterList() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Chapters', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _chapters.length,
                itemBuilder: (ctx, i) {
                  final ch = _chapters[i];
                  return ListTile(
                    title: Text(ch.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    dense: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToChapter(ch.href);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Reader Settings', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                // Font size
                Row(children: [
                  Icon(Icons.text_fields_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('Font Size', style: tt.bodyMedium),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.remove_rounded, size: 20, color: cs.onSurfaceVariant),
                    onPressed: _fontSize > 10 ? () {
                      setSheetState(() {});
                      _updateFontSize(_fontSize - 1);
                    } : null,
                  ),
                  Text('$_fontSize', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: Icon(Icons.add_rounded, size: 20, color: cs.onSurfaceVariant),
                    onPressed: _fontSize < 32 ? () {
                      setSheetState(() {});
                      _updateFontSize(_fontSize + 1);
                    } : null,
                  ),
                ]),
                const SizedBox(height: 8),

                // Line height
                Row(children: [
                  Icon(Icons.format_line_spacing_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('Line Spacing', style: tt.bodyMedium),
                  const Spacer(),
                  Text(_lineHeight.toStringAsFixed(1), style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                Slider(
                  value: _lineHeight,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  onChanged: (v) {
                    setSheetState(() {});
                    _updateLineHeight(double.parse(v.toStringAsFixed(1)));
                  },
                ),
                const SizedBox(height: 8),

                // Margins
                Row(children: [
                  Icon(Icons.padding_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('Margins', style: tt.bodyMedium),
                  const Spacer(),
                  Text('${_margin}px', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                Slider(
                  value: _margin.toDouble(),
                  min: 0,
                  max: 48,
                  divisions: 12,
                  onChanged: (v) {
                    setSheetState(() {});
                    _updateMargin(v.round());
                  },
                ),
                const SizedBox(height: 8),

                // Layout mode
                Row(children: [
                  Icon(Icons.auto_stories_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('Layout', style: tt.bodyMedium),
                  const Spacer(),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Page')),
                      ButtonSegment(value: false, label: Text('Scroll')),
                    ],
                    selected: {_isPaginated},
                    onSelectionChanged: (v) {
                      Navigator.pop(ctx);
                      _updatePaginated(v.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAnnotationsSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final highlights = _annotations.where((a) => a.type == AnnotationType.highlight).toList();
    final bookmarks = _annotations.where((a) => a.type == AnnotationType.bookmark).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, scrollController) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Text('Annotations', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      '${_annotations.length}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: 'Highlights (${highlights.length})'),
                  Tab(text: 'Bookmarks (${bookmarks.length})'),
                ],
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Highlights tab
                    highlights.isEmpty
                        ? Center(child: Text('No highlights yet', style: TextStyle(color: cs.onSurfaceVariant)))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: highlights.length,
                            itemBuilder: (ctx, i) {
                              final h = highlights[i];
                              return Dismissible(
                                key: ValueKey(h.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  color: cs.error,
                                  child: Icon(Icons.delete_rounded, color: cs.onError),
                                ),
                                onDismissed: (_) => _removeHighlight(h),
                                child: ListTile(
                                  leading: Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse('FF${h.color!.hex.substring(1)}', radix: 16)),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  title: Text(
                                    h.selectedText ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodyMedium,
                                  ),
                                  subtitle: h.note != null && h.note!.isNotEmpty
                                      ? Text(h.note!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
                                      : null,
                                  dense: true,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _epubController?.display(cfi: h.cfi);
                                  },
                                  onLongPress: () => _addNoteToAnnotation(h),
                                ),
                              );
                            },
                          ),

                    // Bookmarks tab
                    bookmarks.isEmpty
                        ? Center(child: Text('No bookmarks yet', style: TextStyle(color: cs.onSurfaceVariant)))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: bookmarks.length,
                            itemBuilder: (ctx, i) {
                              final bm = bookmarks[i];
                              final date = '${bm.createdAt.month}/${bm.createdAt.day}/${bm.createdAt.year}';
                              return Dismissible(
                                key: ValueKey(bm.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  color: cs.error,
                                  child: Icon(Icons.delete_rounded, color: cs.onError),
                                ),
                                onDismissed: (_) async {
                                  await _annotationService.delete(
                                    itemId: widget.itemId,
                                    annotationId: bm.id,
                                  );
                                  _annotations.removeWhere((a) => a.id == bm.id);
                                  _updateBookmarkState();
                                  if (mounted) setState(() {});
                                },
                                child: ListTile(
                                  leading: Icon(Icons.bookmark_rounded, color: cs.primary),
                                  title: Text(
                                    bm.note ?? 'Bookmark',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodyMedium,
                                  ),
                                  subtitle: Text(date, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                  dense: true,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _epubController?.display(cfi: bm.cfi);
                                  },
                                  onLongPress: () => _addNoteToAnnotation(bm),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null || _cachedFile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(_error ?? 'Unknown error', textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Epub viewer with safe area padding for camera cutouts
          SafeArea(
            child: SizedBox.expand(
              child: EpubViewer(
              key: ValueKey(_viewerKey),
              epubSource: EpubSource.fromFile(_cachedFile!),
              epubController: _epubController!,
              initialCfi: _initialCfi,
              displaySettings: EpubDisplaySettings(
                flow: _isPaginated ? EpubFlow.paginated : EpubFlow.scrolled,
                snap: _isPaginated,
                useSnapAnimationAndroid: !_isPaginated,
                theme: _buildTheme(isDark),
              ),
              onChaptersLoaded: (chapters) {
                if (mounted) setState(() => _chapters = _flattenChapters(chapters));
              },
              suppressNativeContextMenu: true,
              onSelection: _onSelection,
              onDeselection: () {
                if (mounted) setState(() => _clearSelection());
              },
              onAnnotationClicked: (cfi, rect) {
                final match = _annotations.where(
                  (a) => a.type == AnnotationType.highlight && a.cfi == cfi,
                ).firstOrNull;
                if (match != null) _addNoteToAnnotation(match);
              },
              onEpubLoaded: () {
                debugPrint('[EbookReader] Epub loaded');
                _applySettings();
                _loadAnnotations().then((_) => _restoreHighlights());
                _setupPageInfoHandler();
              },
              onRelocated: (value) {
                if (mounted) {
                  _currentCfi = value.startCfi;
                  _updateBookmarkState();
                  setState(() => _progress = value.progress);
                  _syncProgress(value.startCfi, value.progress);
                }
              },
              onTouchDown: (x, y) {
                _touchDownX = x;
                _touchDownY = y;
              },
              onTouchUp: (x, y) {
                final dx = _touchDownX != null ? (x - _touchDownX!).abs() : 1.0;
                final dy = _touchDownY != null ? (y - _touchDownY!).abs() : 1.0;
                _touchDownX = null;
                _touchDownY = null;
                if (dx > 0.05 || dy > 0.05) return;
                if (!_isPaginated) {
                  if (x > 0.2 && x < 0.8) _toggleControls();
                  return;
                }
                if (x < 0.25) {
                  _epubController?.prev();
                } else if (x > 0.75) {
                  _epubController?.next();
                } else {
                  _toggleControls();
                }
              },
            ),
          )),

          // Top bar overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg.withValues(alpha: 0.9), bg.withValues(alpha: 0.0)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_hasAudiobook)
                          IconButton(
                            icon: Icon(Icons.headphones_rounded, color: cs.onSurface),
                            tooltip: 'Listen from here',
                            onPressed: _listenFromHere,
                          ),
                        IconButton(
                          icon: Icon(
                            _hasBookmarkAtCurrent
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _hasBookmarkAtCurrent ? cs.primary : cs.onSurface,
                          ),
                          onPressed: _toggleBookmark,
                        ),
                        IconButton(
                          icon: Icon(Icons.sticky_note_2_outlined, color: cs.onSurface),
                          onPressed: _showAnnotationsSheet,
                        ),
                        IconButton(
                          icon: Icon(Icons.text_fields_rounded, color: cs.onSurface),
                          onPressed: _showSettingsSheet,
                        ),
                        if (_chapters.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.list_rounded, color: cs.onSurface),
                            onPressed: _showChapterList,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom progress bar overlay
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [bg.withValues(alpha: 0.9), bg.withValues(alpha: 0.0)],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progress.clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(cs.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_chapterPageTotal > 0)
                                Text(
                                  '$_chapterPage / $_chapterPageTotal',
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                                )
                              else
                                const SizedBox.shrink(),
                              Text(
                                '${(_progress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Selection toolbar - appears when text is selected
          if (_selectionRect != null && _selectionCfi != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Center(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(28),
                  color: cs.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final color in HighlightColor.values)
                          _HighlightColorButton(
                            color: Color(int.parse('FF${color.hex.substring(1)}', radix: 16)),
                            onTap: () => _addHighlight(color),
                          ),
                        _divider(cs),
                        IconButton(
                          icon: Icon(Icons.copy_rounded, size: 20, color: cs.onSurfaceVariant),
                          onPressed: _copySelection,
                          tooltip: 'Copy',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(Icons.search_rounded, size: 20, color: cs.onSurfaceVariant),
                          onPressed: _searchSelection,
                          tooltip: 'Search',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(Icons.menu_book_rounded, size: 20, color: cs.onSurfaceVariant),
                          onPressed: _defineSelection,
                          tooltip: 'Define',
                          visualDensity: VisualDensity.compact,
                        ),
                        _divider(cs),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: cs.onSurfaceVariant),
                          onPressed: () => setState(() => _clearSelection()),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HighlightColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _HighlightColorButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
