import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
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
    _setFullscreen(true);
  }

  Future<void> _loadSettings() async {
    _fontSize = await ScopedPrefs.getInt(_kFontSize) ?? 16;
    _lineHeight = await ScopedPrefs.getDouble(_kLineHeight) ?? 1.4;
    _margin = await ScopedPrefs.getInt(_kMargin) ?? 16;
    _isPaginated = await ScopedPrefs.getBool(_kPaginated) ?? true;
    if (mounted) setState(() {});
  }

  void _applySettings() {
    // Font size and line-height are safe to set after load.
    // Do NOT call setFlow here - it's already set via displaySettings
    // and re-calling it breaks snap animation on Android.
    _epubController?.setFontSize(fontSize: _fontSize.toDouble());
    _epubController?.webViewController?.evaluateJavascript(
      source: '''
        (function() {
          try {
            if (typeof rendition !== 'undefined') {
              rendition.themes.override('line-height', '$_lineHeight');
              rendition.themes.override('margin', '${_margin}px');
            }
          } catch(e) {}
        })();
      ''',
    );
  }

  Future<void> _updateFontSize(int size) async {
    setState(() => _fontSize = size);
    _epubController?.setFontSize(fontSize: size.toDouble());
    await ScopedPrefs.setInt(_kFontSize, size);
  }

  Future<void> _updateLineHeight(double height) async {
    setState(() => _lineHeight = height);
    _epubController?.webViewController?.evaluateJavascript(
      source: "rendition.themes.override('line-height', '$height')",
    );
    await ScopedPrefs.setDouble(_kLineHeight, height);
  }

  Future<void> _updateMargin(int margin) async {
    setState(() => _margin = margin);
    _epubController?.webViewController?.evaluateJavascript(
      source: "rendition.themes.override('margin', '${margin}px')",
    );
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
    _setFullscreen(!_showControls);
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
                      _epubController?.display(cfi: ch.href);
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
                      setSheetState(() {});
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
                useSnapAnimationAndroid: true,
                theme: isDark ? EpubTheme.dark() : EpubTheme.light(),
              ),
              onChaptersLoaded: (chapters) {
                if (mounted) setState(() => _chapters = chapters);
              },
              onEpubLoaded: () {
                debugPrint('[EbookReader] Epub loaded');
                _applySettings();
                // Disable epub.js built-in click-to-navigate to prevent double page turns
                _epubController?.webViewController?.evaluateJavascript(
                  source: '''
                    (function() {
                      try {
                        if (typeof rendition !== 'undefined' && rendition.manager) {
                          var views = rendition.manager.views;
                          if (views && views._views) {
                            views._views.forEach(function(view) {
                              if (view.document) {
                                view.document.addEventListener('click', function(e) {
                                  e.stopImmediatePropagation();
                                }, { capture: true });
                              }
                            });
                          }
                        }
                      } catch(e) { console.log('disable click nav error:', e); }
                    })();
                  ''',
                );
              },
              onRelocated: (value) {
                if (mounted) {
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
                if (x < 0.2) {
                  Future.delayed(const Duration(milliseconds: 100), () => _epubController?.prev());
                } else if (x > 0.8) {
                  Future.delayed(const Duration(milliseconds: 100), () => _epubController?.next());
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
                          Text(
                            '${(_progress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
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
