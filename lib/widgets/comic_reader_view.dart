import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/ebook_cache.dart';
import '../services/progress_sync_service.dart';
import '../services/scoped_prefs.dart';
import '../services/volume_key_service.dart';
import 'ebook_router.dart' show ebookExt;

const _imageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};

/// Natural order for page file names, so "page2" comes before "page10".
int comicPageNameCompare(String a, String b) {
  final re = RegExp(r'\d+|\D+');
  final pa = re.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
  final pb = re.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final x = pa[i], y = pb[i];
    final xd = int.tryParse(x), yd = int.tryParse(y);
    final c = xd != null && yd != null ? xd.compareTo(yd) : x.compareTo(y);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}

bool _isPageEntry(String name) {
  final parts = name.replaceAll('\\', '/').split('/');
  if (parts.any((p) => p.startsWith('.') || p == '__MACOSX')) return false;
  final dot = name.lastIndexOf('.');
  return dot > 0 && _imageExts.contains(name.substring(dot + 1).toLowerCase());
}

/// Unpacks a CBZ's page images into [dest] as 00000.jpg, 00001.png, ... in
/// reading order. Runs in a background isolate. Returns the page paths.
List<String> extractComicPages(List<String> args) {
  final src = args[0], dest = args[1];
  final input = InputFileStream(src);
  try {
    final archive = ZipDecoder().decodeStream(input);
    final entries = archive.files.where((f) => f.isFile && _isPageEntry(f.name)).toList()
      ..sort((a, b) => comicPageNameCompare(a.name, b.name));
    Directory(dest).createSync(recursive: true);
    final paths = <String>[];
    for (var i = 0; i < entries.length; i++) {
      final name = entries[i].name;
      final ext = name.substring(name.lastIndexOf('.') + 1).toLowerCase();
      final path = '$dest${Platform.pathSeparator}${i.toString().padLeft(5, '0')}.$ext';
      final out = OutputFileStream(path);
      entries[i].writeContent(out);
      out.closeSync();
      paths.add(path);
    }
    File('$dest${Platform.pathSeparator}.done').writeAsStringSync('${paths.length}');
    return paths;
  } finally {
    input.closeSync();
  }
}

/// Where a comic's pages come from: images unpacked on the phone, or pages
/// the server hands out one at a time (BookOrbit, which also opens CBR and
/// CB7 archives the phone can't).
abstract class _ComicPages {
  int get count;
  ImageProvider image(int index);
}

class _FilePages implements _ComicPages {
  final List<String> paths;
  _FilePages(this.paths);
  @override
  int get count => paths.length;
  @override
  ImageProvider image(int index) => FileImage(File(paths[index]));
}

class _ServerPages implements _ComicPages {
  final ApiService api;
  final String fileId;
  @override
  final int count;
  _ServerPages(this.api, this.fileId, this.count);
  @override
  ImageProvider image(int index) =>
      CachedNetworkImageProvider(api.comicPageUrl(fileId, index)!, headers: api.mediaHeaders);
}

/// Full-screen comic reader: one page at a time, pinch or double-tap to zoom
/// and drag to pan, swipe or tap the edges to turn pages, left to right or
/// right to left (manga) per book. The page number is stored as the
/// ebookLocation, like the PDF reader, which is also what BookOrbit's own
/// comic reader saves.
class ComicReaderView extends StatefulWidget {
  final String itemId;
  final String title;
  final Map<String, dynamic> ebookFile;

  const ComicReaderView({
    super.key,
    required this.itemId,
    required this.title,
    required this.ebookFile,
  });

  @override
  State<ComicReaderView> createState() => _ComicReaderViewState();
}

class _ComicReaderViewState extends State<ComicReaderView> with WidgetsBindingObserver {
  ApiService? _api;
  LibraryProvider? _lib;
  _ComicPages? _pages;
  PageController? _controller;
  String? _error;
  bool _loading = true;

  int _page = 1;
  bool _rtl = false;
  bool _zoomed = false;
  bool _showControls = true;
  double? _scrubPage;

  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastSyncedPage = -1;
  int? _pendingPage;

  String get _directionKey => 'comic_rtl_${widget.itemId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullscreen(true);
    _api = context.read<AuthProvider>().apiService;
    _lib = context.read<LibraryProvider>();
    _lib?.setReaderQuiet(true);
    ScopedPrefs.getBool(_directionKey).then((v) {
      if (mounted && v != null) setState(() => _rtl = v);
    });
    _open();
    _volumeNav.attach();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _flushProgress();
  }

  late final EreaderVolumeNav _volumeNav = EreaderVolumeNav(
    onPrev: () => _turn(-1),
    onNext: () => _turn(1),
  );

  @override
  void dispose() {
    _lib?.setReaderQuiet(false);
    WidgetsBinding.instance.removeObserver(this);
    _volumeNav.detach();
    _setFullscreen(false);
    _flushProgress();
    _controller?.dispose();
    super.dispose();
  }

  void _setFullscreen(bool fullscreen) {
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
  }

  /// The saved page: the location when it is a page number, otherwise the
  /// progress fraction (a CBZ last read in the old reader saved neither).
  int _savedPage(int count) {
    final data = _lib?.getProgressData(widget.itemId);
    final loc = int.tryParse((data?['ebookLocation'] as String?)?.trim() ?? '');
    if (loc != null && loc >= 1) return loc.clamp(1, count);
    final frac = (data?['ebookProgress'] as num?)?.toDouble() ?? 0;
    if (frac > 0 && frac < 1) return (frac * count).round().clamp(1, count);
    return 1;
  }

  Future<void> _open() async {
    final l = AppLocalizations.of(context)!;
    final ext = ebookExt(widget.ebookFile);
    final api = _api;
    final offline = _lib?.isOffline ?? true;
    try {
      _ComicPages? pages;
      if (ext == 'cbz' && await isEbookCached(widget.itemId, widget.ebookFile)) {
        pages = await _unpack(await ebookCacheFileFor(widget.itemId, widget.ebookFile));
      }
      final fileId = widget.ebookFile['ino'] as String?;
      if (pages == null && api != null && fileId != null && !offline) {
        final count = await api.comicPageCount(fileId);
        if (count != null && count > 0) pages = _ServerPages(api, fileId, count);
      }
      if (pages == null && ext == 'cbz' && api != null && !offline) {
        pages = await _unpack(await fetchEbookToCache(api, widget.itemId, widget.ebookFile, widget.title));
      }
      if (!mounted) return;
      if (pages == null) {
        setState(() {
          _error = ext == 'cbz' ? l.noEbookFileFound : l.comicNeedsConnection;
          _loading = false;
        });
        return;
      }
      if (pages.count == 0) {
        setState(() {
          _error = l.comicNoPages;
          _loading = false;
        });
        return;
      }
      final start = _savedPage(pages.count);
      setState(() {
        _pages = pages;
        _page = start;
        _controller = PageController(initialPage: start - 1);
        _loading = false;
      });
      _precacheAround(start - 1);
    } catch (e) {
      debugPrint('[Comic] open failed: $e');
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  /// Unpacks a CBZ into a scratch folder once per file version, keeping the
  /// three most recent comics so the cache doesn't grow without end.
  Future<_ComicPages> _unpack(File archive) async {
    final root = Directory('${(await getTemporaryDirectory()).path}/comic_pages');
    final dest = Directory('${root.path}/${widget.itemId}_${await archive.length()}');
    final done = File('${dest.path}/.done');
    List<String> paths;
    if (done.existsSync()) {
      paths = dest
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => !p.endsWith('.done'))
          .toList()
        ..sort();
    } else {
      if (dest.existsSync()) dest.deleteSync(recursive: true);
      paths = await compute(extractComicPages, [archive.path, dest.path]);
    }
    try {
      done.setLastModifiedSync(DateTime.now());
      DateTime opened(Directory d) {
        final marker = File('${d.path}/.done');
        return marker.existsSync() ? marker.lastModifiedSync() : d.statSync().modified;
      }
      final others = root.listSync().whereType<Directory>().where((d) => d.path != dest.path).toList()
        ..sort((a, b) => opened(b).compareTo(opened(a)));
      for (final old in others.skip(2)) {
        old.deleteSync(recursive: true);
      }
    } catch (_) {}
    return _FilePages(paths);
  }

  void _precacheAround(int index) {
    final pages = _pages;
    if (pages == null || !mounted) return;
    for (final i in [index + 1, index + 2, index - 1]) {
      if (i >= 0 && i < pages.count) {
        precacheImage(pages.image(i), context).catchError((_) {});
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _page = index + 1;
      _zoomed = false;
    });
    _precacheAround(index);
    _pendingPage = _page;
    if (DateTime.now().difference(_lastSync).inSeconds >= 10) _flushProgress();
  }

  void _flushProgress() {
    final page = _pendingPage;
    final api = _api;
    final count = _pages?.count ?? 0;
    if (page == null || api == null || count <= 0 || page == _lastSyncedPage) return;
    final frac = (page / count).clamp(0.0, 1.0);
    ProgressSyncService().pushEbookProgress(api, widget.itemId, location: '$page', progress: frac);
    _lib?.applyLocalEbookProgress(widget.itemId, location: '$page', progress: frac);
    _lastSync = DateTime.now();
    _lastSyncedPage = page;
    _pendingPage = null;
  }

  /// [delta] in reading order: +1 is the next page whichever way it reads.
  void _turn(int delta) {
    final c = _controller;
    final pages = _pages;
    if (c == null || pages == null) return;
    final target = (_page - 1 + delta).clamp(0, pages.count - 1);
    if (target == _page - 1) return;
    c.animateToPage(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  /// Edges turn the page (mirrored when reading right to left), the middle
  /// shows or hides the controls.
  void _onPageTap(TapUpDetails d) {
    final width = MediaQuery.of(context).size.width;
    final x = d.globalPosition.dx;
    if (x < width * 0.3) {
      _turn(_rtl ? 1 : -1);
    } else if (x > width * 0.7) {
      _turn(_rtl ? -1 : 1);
    } else {
      setState(() => _showControls = !_showControls);
    }
  }

  void _setDirection(bool rtl) {
    setState(() => _rtl = rtl);
    ScopedPrefs.setBool(_directionKey, rtl);
  }

  void _showSettings() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l.comicReadingDirection,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          for (final rtl in [false, true])
            ListTile(
              leading: Icon(rtl ? Icons.format_textdirection_r_to_l_rounded : Icons.format_textdirection_l_to_r_rounded),
              title: Text(rtl ? l.comicRightToLeft : l.comicLeftToRight),
              trailing: rtl == _rtl ? Icon(Icons.check_rounded, color: Theme.of(ctx).colorScheme.primary) : null,
              onTap: () {
                Navigator.pop(ctx);
                _setDirection(rtl);
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final pages = _pages;
    final controller = _controller;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(color: Colors.white70));
    } else if (_error != null || pages == null || controller == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error ?? l.noEbookFileFound,
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ),
      );
    } else {
      final shownPage = (_scrubPage?.round() ?? _page).clamp(1, pages.count);
      body = Stack(children: [
        Positioned.fill(
          child: PageView.builder(
            controller: controller,
            reverse: _rtl,
            physics: _zoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemCount: pages.count,
            itemBuilder: (_, i) => _ComicPage(
              key: ValueKey('comic-page-$i'),
              image: pages.image(i),
              active: i == _page - 1,
              onTap: _onPageTap,
              onZoomChanged: (z) {
                if (i == _page - 1 && z != _zoomed) setState(() => _zoomed = z);
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _bar(
            top: true,
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(widget.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleSmall?.copyWith(color: Colors.white)),
              ),
              IconButton(
                tooltip: l.comicReadingDirection,
                icon: Icon(
                  _rtl ? Icons.format_textdirection_r_to_l_rounded : Icons.format_textdirection_l_to_r_rounded,
                  color: Colors.white,
                ),
                onPressed: _showSettings,
              ),
            ]),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _bar(
            top: false,
            child: Row(children: [
              Text('$shownPage / ${pages.count}', style: tt.bodySmall?.copyWith(color: Colors.white70)),
              Expanded(
                child: pages.count > 1
                    ? Directionality(
                        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                        child: Slider(
                          min: 1,
                          max: pages.count.toDouble(),
                          divisions: pages.count - 1,
                          value: (_scrubPage ?? _page.toDouble()).clamp(1, pages.count.toDouble()),
                          onChanged: (v) => setState(() => _scrubPage = v),
                          onChangeEnd: (v) {
                            setState(() => _scrubPage = null);
                            controller.jumpToPage(v.round() - 1);
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      ]);
    }
    return Scaffold(backgroundColor: Colors.black, body: body);
  }

  Widget _bar({required bool top, required Widget child}) => AnimatedOpacity(
        opacity: _showControls ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.85), Colors.black.withValues(alpha: 0)],
              ),
            ),
            child: SafeArea(
              top: top,
              bottom: !top,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: top ? 4 : 16, vertical: top ? 4 : 8),
                child: child,
              ),
            ),
          ),
        ),
      );
}

/// One page: fit to the screen, pinch or double-tap to zoom, drag to pan
/// while zoomed. Zoom resets when the page is swiped away.
class _ComicPage extends StatefulWidget {
  final ImageProvider image;
  final bool active;
  final GestureTapUpCallback onTap;
  final ValueChanged<bool> onZoomChanged;

  const _ComicPage({
    super.key,
    required this.image,
    required this.active,
    required this.onTap,
    required this.onZoomChanged,
  });

  @override
  State<_ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<_ComicPage> with SingleTickerProviderStateMixin {
  static const _doubleTapScale = 2.5;
  final _transform = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() {
      final a = _animation;
      if (a != null) _transform.value = a.value;
    });
  Animation<Matrix4>? _animation;
  Offset? _doubleTapAt;

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  @override
  void didUpdateWidget(covariant _ComicPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active && _isZoomed) {
      _anim.stop();
      _transform.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      _animateTo(Matrix4.identity());
      widget.onZoomChanged(false);
      return;
    }
    final size = context.size ?? Size.zero;
    final at = _doubleTapAt ?? Offset(size.width / 2, size.height / 2);
    _animateTo(Matrix4.identity()
      ..translate(-at.dx * (_doubleTapScale - 1), -at.dy * (_doubleTapScale - 1))
      ..scale(_doubleTapScale));
    widget.onZoomChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTap,
      onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 5,
        onInteractionEnd: (_) => widget.onZoomChanged(_isZoomed),
        child: SizedBox.expand(
          child: Image(
            image: widget.image,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48)),
          ),
        ),
      ),
    );
  }
}
