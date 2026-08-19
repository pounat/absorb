import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/ebook_cache.dart';
import '../services/progress_sync_service.dart';
import '../services/foliate_book_server.dart';
import '../services/volume_key_service.dart';

/// A table-of-contents entry from foliate-js.
class _TocItem {
  final String label;
  final String? href;
  final List<_TocItem> subitems;
  _TocItem(this.label, this.href, this.subitems);

  static _TocItem fromJson(Map<dynamic, dynamic> j) => _TocItem(
        (j['label'] as String?)?.trim() ?? '',
        j['href'] as String?,
        ((j['subitems'] as List?) ?? [])
            .whereType<Map>()
            .map(_TocItem.fromJson)
            .toList(),
      );
}

/// Reader for the non-EPUB, non-PDF formats foliate-js can render (MOBI, AZW3,
/// FB2, FBZ, CBZ). Renders foliate-js in a webview fed by a loopback server.
/// Reading position is foliate's CFI, stored as the ebookLocation - the same
/// field the EPUB reader uses.
class FoliateReaderView extends StatefulWidget {
  final String itemId;
  final String title;
  final Map<String, dynamic> ebookFile;

  const FoliateReaderView({
    super.key,
    required this.itemId,
    required this.title,
    required this.ebookFile,
  });

  @override
  State<FoliateReaderView> createState() => _FoliateReaderViewState();
}

class _FoliateReaderViewState extends State<FoliateReaderView> with WidgetsBindingObserver {
  final _server = FoliateBookServer();
  InAppWebViewController? _controller;
  ApiService? _api;
  LibraryProvider? _lib;

  bool _loading = true;
  String? _error;
  int _port = 0;
  String _bookUrlName = 'book.epub';

  String? _initialCfi;
  String? _cfi;
  double _progress = 0;
  String? _tocLabel;
  List<_TocItem> _toc = [];
  bool _showControls = true;

  // Tap handling. Taps arrive from a Flutter Listener (works on iOS) and a JS
  // click fallback (Android); both funnel through _readerTapAt, debounced so
  // they can't double-fire.
  double? _ptrDownX;
  double? _ptrDownY;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  // Progress sync throttling - matches the EPUB/PDF reader cadence.
  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastSyncedCfi;
  bool _firstRelocate = true; // log only the first render position

  void _log(String msg) => debugPrint('[Foliate] item=${widget.itemId} $msg');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullscreen(true);
    _api = context.read<AuthProvider>().apiService;
    _lib = context.read<LibraryProvider>();
    _lib?.setReaderQuiet(true);
    _loadInitialCfi();
    _prepare();
    _volumeNav.attach();
  }

  // Flush on background so an OS kill can't lose the last pages read.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _flushProgress();
  }

  late final EreaderVolumeNav _volumeNav = EreaderVolumeNav(
    onPrev: () => _controller?.evaluateJavascript(source: 'window.AbsorbReader.prev();'),
    onNext: () => _controller?.evaluateJavascript(source: 'window.AbsorbReader.next();'),
  );

  @override
  void dispose() {
    _lib?.setReaderQuiet(false);
    WidgetsBinding.instance.removeObserver(this);
    _volumeNav.detach();
    _setFullscreen(false);
    _flushProgress();
    _server.stop();
    super.dispose();
  }

  void _setFullscreen(bool fullscreen) {
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void _loadInitialCfi() {
    final lib = context.read<LibraryProvider>();
    final loc = lib.getProgressData(widget.itemId)?['ebookLocation'] as String?;
    if (loc != null && loc.isNotEmpty) {
      _initialCfi = loc;
      _cfi = loc;
    }
    final p = (lib.getProgressData(widget.itemId)?['ebookProgress'] as num?)?.toDouble();
    if (p != null) _progress = p.clamp(0.0, 1.0);
  }

  String get _ext => ebookExtFromFile(widget.ebookFile);

  String _mimeFor(String ext) {
    switch (ext) {
      case '.mobi':
        return 'application/x-mobipocket-ebook';
      case '.azw3':
      case '.kf8':
        return 'application/x-mobi8-ebook';
      case '.fb2':
        return 'application/x-fictionbook+xml';
      case '.fbz':
        return 'application/x-zip-compressed-fb2';
      case '.cbz':
        return 'application/vnd.comicbook+zip';
      case '.epub':
        return 'application/epub+zip';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _prepare() async {
    try {
      final api = _api;
      if (api == null) {
        setState(() { _error = 'Not connected to server'; _loading = false; });
        return;
      }
      _log('prepare ext=$_ext playing=${AudioPlayerService().isPlaying}');
      final file = await fetchEbookToCache(api, widget.itemId, widget.ebookFile, widget.title);
      final ext = _ext.isEmpty ? '.epub' : _ext;
      _bookUrlName = 'book$ext';
      final port = await _server.start(bookFile: file, mime: _mimeFor(ext));
      final len = file.existsSync() ? await file.length() : 0;
      _log('server up port=$port bytes=$len mime=${_mimeFor(ext)}');
      if (!mounted) return;
      setState(() { _port = port; _loading = false; });
    } catch (e) {
      _log('prepare error $e');
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  void _registerHandlers(InAppWebViewController c) {
    c.addJavaScriptHandler(handlerName: 'onReady', callback: (args) {
      _log('onReady');
      _openBook();
      return null;
    });
    c.addJavaScriptHandler(handlerName: 'onBookLoaded', callback: (args) {
      final data = args.isNotEmpty ? args[0] as Map? : null;
      final toc = (data?['toc'] as List?) ?? [];
      _log('onBookLoaded toc=${toc.length}');
      if (mounted) {
        setState(() => _toc = toc.whereType<Map>().map(_TocItem.fromJson).toList());
      }
      // Rescue a blank first paint: re-apply the position after a tick so the
      // renderer relays out (mirrors the EPUB reader's re-display rescue).
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        final cfi = _initialCfi;
        _controller?.evaluateJavascript(source: (cfi != null && cfi.isNotEmpty)
            ? 'window.AbsorbReader.goTo(${jsonEncode(cfi)});'
            : 'window.AbsorbReader.goToFraction(0);');
      });
      return null;
    });
    c.addJavaScriptHandler(handlerName: 'onRelocate', callback: (args) {
      final data = args.isNotEmpty ? args[0] as Map? : null;
      if (data == null) return null;
      final cfi = data['cfi'] as String?;
      if (_firstRelocate) { _firstRelocate = false; _log('first onRelocate cfi=${cfi != null}'); }
      final frac = (data['fraction'] as num?)?.toDouble();
      final label = data['tocLabel'] as String?;
      if (mounted) {
        setState(() {
          if (cfi != null) _cfi = cfi;
          if (frac != null) _progress = frac.clamp(0.0, 1.0);
          _tocLabel = label;
        });
      }
      if (cfi != null && frac != null) _syncProgress(cfi, frac);
      return null;
    });
    c.addJavaScriptHandler(handlerName: 'onTap', callback: (args) {
      final data = args.isNotEmpty ? args[0] as Map? : null;
      final frac = (data?['frac'] as num?)?.toDouble();
      if (frac != null) _readerTapAt(frac);
      return null;
    });
    c.addJavaScriptHandler(handlerName: 'onError', callback: (args) {
      final msg = args.isNotEmpty ? '${args[0]}' : 'Unknown error';
      _log('onError tocEmpty=${_toc.isEmpty} msg=$msg');
      if (mounted && _toc.isEmpty) setState(() => _error = msg);
      return null;
    });
  }

  void _openBook() {
    final c = _controller;
    if (c == null) return;
    final cs = Theme.of(context).colorScheme;
    final bg = _hex(cs.surface);
    final fg = _hex(cs.onSurface);
    final css = 'html,body{background:$bg !important;color:$fg !important;}';
    final bookUrl = 'http://127.0.0.1:$_port/book/$_bookUrlName';
    final js = 'window.AbsorbReader.openBook('
        '${jsonEncode(bookUrl)}, '
        '${_initialCfi != null ? jsonEncode(_initialCfi) : 'null'}, '
        '${jsonEncode('paginated')}, '
        '1, '
        '${jsonEncode(css)});';
    c.evaluateJavascript(source: js);
  }

  String _hex(Color c) {
    String h(double v) => (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${h(c.r)}${h(c.g)}${h(c.b)}';
  }

  void _syncProgress(String cfi, double frac) {
    if (cfi == _lastSyncedCfi) return;
    if (DateTime.now().difference(_lastSync).inSeconds < 10) return;
    _flushProgress();
  }

  void _flushProgress() {
    final api = _api;
    final cfi = _cfi;
    if (api == null || cfi == null || cfi == _lastSyncedCfi) return;
    ProgressSyncService().pushEbookProgress(api, widget.itemId, location: cfi, progress: _progress);
    _lib?.applyLocalEbookProgress(widget.itemId, location: cfi, progress: _progress);
    _lastSync = DateTime.now();
    _lastSyncedCfi = cfi;
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  /// Shared tap handler: left quarter = previous page, right quarter = next,
  /// center = toggle the reader chrome. [frac] is the tap's x position 0..1.
  void _readerTapAt(double frac) {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 350) return;
    _lastTap = now;
    if (frac < 0.25) {
      _controller?.evaluateJavascript(source: 'window.AbsorbReader.prev();');
    } else if (frac > 0.75) {
      _controller?.evaluateJavascript(source: 'window.AbsorbReader.next();');
    } else {
      _toggleControls();
    }
  }

  void _showToc() {
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
              child: Text(AppLocalizations.of(ctx)!.readerChapters,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: cs.onSurface)),
            ),
            Flexible(child: ListView(shrinkWrap: true, children: _tocTiles(_toc, ctx, 0))),
          ],
        ),
      ),
    );
  }

  List<Widget> _tocTiles(List<_TocItem> items, BuildContext ctx, int depth) {
    final cs = Theme.of(ctx).colorScheme;
    final out = <Widget>[];
    for (final it in items) {
      if (it.label.isNotEmpty) {
        out.add(ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: 16.0 + depth * 16, right: 16),
          title: Text(it.label, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurface)),
          onTap: () {
            Navigator.pop(ctx);
            final href = it.href;
            if (href != null) {
              _controller?.evaluateJavascript(source: 'window.AbsorbReader.goTo(${jsonEncode(href)});');
            }
          },
        ));
      }
      if (it.subitems.isNotEmpty) out.addAll(_tocTiles(it.subitems, ctx, depth + 1));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null || _port == 0) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error ?? l.noEbookFileFound,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    } else {
      final pct = (_progress * 100).round();
      body = Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (ctx, cons) => Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) {
                  _ptrDownX = e.localPosition.dx;
                  _ptrDownY = e.localPosition.dy;
                },
                onPointerUp: (e) {
                  final w = cons.maxWidth;
                  final dx = _ptrDownX != null ? (e.localPosition.dx - _ptrDownX!).abs() : 0.0;
                  final dy = _ptrDownY != null ? (e.localPosition.dy - _ptrDownY!).abs() : 0.0;
                  _ptrDownX = null;
                  _ptrDownY = null;
                  if (dx > 16 || dy > 16 || w <= 0) return;
                  _readerTapAt(e.localPosition.dx / w);
                },
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri('http://127.0.0.1:$_port/reader.html')),
                  initialSettings: InAppWebViewSettings(
                    transparentBackground: true,
                    javaScriptEnabled: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    mediaPlaybackRequiresUserGesture: false,
                  ),
                  onWebViewCreated: (c) {
                    _controller = c;
                    _registerHandlers(c);
                  },
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                        ),
                        if (_toc.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.list_rounded, color: cs.onSurface),
                            onPressed: _showToc,
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom bar
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(children: [
                        if (_tocLabel != null && _tocLabel!.isNotEmpty)
                          Expanded(
                            child: Text(_tocLabel!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 12),
                        Text('$pct%', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(backgroundColor: cs.surface, body: body);
  }
}
