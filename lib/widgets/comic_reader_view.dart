import 'dart:async';
import 'dart:convert';
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
import '../services/download_service.dart';
import '../services/ebook_cache.dart';
import '../services/image_epub.dart';
import '../services/progress_sync_service.dart';
import '../services/scoped_prefs.dart';
import '../services/ebook_annotation_service.dart';
import '../services/volume_key_service.dart';
import 'ebook_router.dart' show ebookExt;
import 'overlay_toast.dart';

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

  /// An EPUB made of page pictures, read here instead of the EPUB reader.
  /// Its position is saved as an EPUB location, so the book still opens at
  /// the same page wherever it's read as an EPUB.
  final File? imageEpub;

  const ComicReaderView({
    super.key,
    required this.itemId,
    required this.title,
    required this.ebookFile,
    this.imageEpub,
  });

  @override
  State<ComicReaderView> createState() => _ComicReaderViewState();
}

class _ComicReaderViewState extends State<ComicReaderView> with WidgetsBindingObserver {
  ApiService? _api;
  // A download made on another account reads from the phone, and neither its
  // place nor its bookmarks go to the server signed in now.
  bool _otherAccount = false;
  ({String location, double progress})? _otherSpot;
  ApiService? get _syncApi => _otherAccount ? null : _api;
  LibraryProvider? _lib;
  _ComicPages? _pages;
  // Image EPUB only: each page's EPUB position.
  List<String>? _cfis;

  // Bookmarks live on the phone for every comic. A picture EPUB on BookOrbit
  // also keeps them on the server, at each page's EPUB position.
  final _annotationService = EbookAnnotationService();
  List<EbookAnnotation> _bookmarks = [];
  PageController? _controller;
  String? _error;
  bool _loading = true;

  int _page = 1;
  bool _rtl = false;
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
    _otherAccount = DownloadService().isFromOtherAccount(widget.itemId);
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
    final spot = _otherSpot;
    final data = _otherAccount
        ? (spot == null ? null : {'ebookLocation': spot.location, 'ebookProgress': spot.progress})
        : _lib?.getProgressData(widget.itemId);
    final cfis = _cfis;
    if (cfis != null) {
      final index = pageIndexForCfi(cfis, data?['ebookLocation'] as String?);
      if (index != null) return (index + 1).clamp(1, count);
    }
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
      final imageEpub = widget.imageEpub;
      if (imageEpub != null) {
        pages = await _unpack(imageEpub, epub: true);
      } else if (ext == 'cbz' && await isEbookCached(widget.itemId, widget.ebookFile)) {
        pages = await _unpack(await ebookCacheFileFor(widget.itemId, widget.ebookFile));
      }
      final fileId = widget.ebookFile['ino'] as String?;
      if (pages == null && imageEpub == null && api != null && fileId != null && !offline) {
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
      if (_otherAccount) {
        _otherSpot = await DownloadService().otherAccountReadingSpot(widget.itemId);
      } else {
        await _pullServerPosition();
      }
      if (!mounted) return;
      final start = _savedPage(pages.count);
      setState(() {
        _pages = pages;
        _page = start;
        _controller = PageController(initialPage: start - 1);
        _loading = false;
      });
      _precacheAround(start - 1);
      unawaited(_loadBookmarks());
    } catch (e) {
      debugPrint('[Comic] open failed: $e');
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  /// Unpacks a CBZ into a scratch folder once per file version, keeping the
  /// three most recent comics so the cache doesn't grow without end.
  Future<_ComicPages> _unpack(File archive, {bool epub = false}) async {
    final root = Directory('${(await getTemporaryDirectory()).path}/comic_pages');
    final dest = Directory('${root.path}/${widget.itemId}_${await archive.length()}${epub ? '_epub$imageEpubScanVersion' : ''}');
    final done = File('${dest.path}/.done');
    List<String> paths;
    if (done.existsSync()) {
      paths = dest
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => !p.endsWith('.done') && !p.endsWith('.cfis'))
          .toList()
        ..sort();
    } else {
      if (dest.existsSync()) dest.deleteSync(recursive: true);
      paths = await compute(epub ? extractImageEpubPages : extractComicPages, [archive.path, dest.path]);
    }
    if (epub) {
      final cfiFile = File('${dest.path}/.cfis');
      final raw = cfiFile.existsSync() ? cfiFile.readAsStringSync().trim() : '';
      final cfis = raw.isEmpty ? <String>[] : const LineSplitter().convert(raw);
      _cfis = cfis.length == paths.length ? cfis : null;
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

  /// Takes the server's page when it differs from the phone's (read on the
  /// web or another device; a BookOrbit library refresh carries no page). A
  /// page this phone hasn't sent yet wins, and a slow server keeps the phone's.
  Future<void> _pullServerPosition() async {
    final api = _syncApi;
    final lib = _lib;
    if (api == null || lib == null || lib.isOffline) return;
    try {
      final pending = await ProgressSyncService().getPendingEbookProgress();
      if (pending.containsKey(widget.itemId)) return;
      final server = await api
          .getItemProgress(widget.itemId)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      final loc = server?['ebookLocation'] as String?;
      if (loc == null || loc.isEmpty) return;
      final local = lib.getProgressData(widget.itemId);
      if (local?['ebookLocation'] == loc) return;
      final progress = (server!['ebookProgress'] as num?)?.toDouble() ??
          (local?['ebookProgress'] as num?)?.toDouble() ??
          0;
      debugPrint('[Comic] taking the server position item=${widget.itemId}');
      lib.applyLocalEbookProgress(widget.itemId, location: loc, progress: progress);
    } catch (e) {
      debugPrint('[Comic] server position check failed: $e');
    }
  }

  bool get _serverBookmarks => _cfis != null && (_syncApi?.isBookOrbit ?? false);

  /// What a bookmark on [page] is saved as: the page's EPUB position for a
  /// picture EPUB, otherwise the page number.
  String _pageKey(int page) {
    final cfis = _cfis;
    return cfis != null && page <= cfis.length ? cfis[page - 1] : 'page:$page';
  }

  /// The page a bookmark is on. A picture EPUB's bookmarks can come from any
  /// EPUB reader, so they're matched by position, not by exact text.
  int? _pageOf(EbookAnnotation b) {
    if (b.cfi.startsWith('page:')) return int.tryParse(b.cfi.substring(5));
    final cfis = _cfis;
    if (cfis == null) return null;
    final index = pageIndexForCfi(cfis, b.cfi);
    return index == null ? null : index + 1;
  }

  List<EbookAnnotation> _bookmarksOn(int page) => _bookmarks.where((b) => _pageOf(b) == page).toList();

  Future<void> _loadBookmarks() async {
    final local = await _annotationService.getBookmarks(widget.itemId);
    if (mounted) setState(() => _bookmarks = local);
    if (_serverBookmarks && !(_lib?.isOffline ?? true)) await _syncBookmarks();
  }

  /// Squares the phone's bookmarks with BookOrbit's: ones deleted elsewhere
  /// go, ones made here offline are sent, ones made elsewhere arrive.
  Future<void> _syncBookmarks() async {
    final api = _syncApi;
    if (api == null) return;
    final server = await api.ebookBookmarks(widget.itemId);
    if (server == null) return;
    final serverIds = {for (final s in server) s['id'] as String};
    var local = await _annotationService.getBookmarks(widget.itemId);
    for (final b in local) {
      final sid = b.serverId;
      if (sid != null && !serverIds.contains(sid)) {
        await _annotationService.delete(itemId: widget.itemId, annotationId: b.id);
      } else if (sid == null && b.cfi.startsWith('epubcfi(')) {
        final page = _pageOf(b);
        final id = await api.addEbookBookmark(widget.itemId,
            cfi: b.cfi, title: _bookmarkTitle(page ?? 1));
        if (id != null) {
          await _annotationService.setServerId(itemId: widget.itemId, annotationId: b.id, serverId: id);
        }
      }
    }
    local = await _annotationService.getBookmarks(widget.itemId);
    final known = {for (final b in local) b.serverId};
    for (final s in server) {
      if (known.contains(s['id'])) continue;
      await _annotationService.addBookmark(
        itemId: widget.itemId,
        cfi: s['cfi'] as String,
        note: s['note'] as String?,
        chapter: s['title'] as String?,
        serverId: s['id'] as String,
      );
    }
    final fresh = await _annotationService.getBookmarks(widget.itemId);
    if (mounted) setState(() => _bookmarks = fresh);
  }

  String _bookmarkTitle(int page) => AppLocalizations.of(context)!.comicPageNumber(page);

  /// Removes [b] here and, when the server keeps it, there first: a bookmark
  /// only removed here would come back with the next sync.
  Future<bool> _removeBookmark(EbookAnnotation b) async {
    final sid = b.serverId;
    final api = _api;
    if (sid != null && api != null && _serverBookmarks) {
      if (!await api.deleteEbookBookmark(widget.itemId, sid)) {
        if (mounted) {
          showOverlayToast(context, AppLocalizations.of(context)!.comicBookmarkRemoveFailed,
              icon: Icons.cloud_off_rounded);
        }
        return false;
      }
    }
    await _annotationService.delete(itemId: widget.itemId, annotationId: b.id);
    _bookmarks.removeWhere((x) => x.id == b.id);
    return true;
  }

  Future<void> _toggleBookmark() async {
    final l = AppLocalizations.of(context)!;
    final page = _page;
    final here = _bookmarksOn(page);
    if (here.isNotEmpty) {
      for (final b in here) {
        await _removeBookmark(b);
      }
    } else {
      final key = _pageKey(page);
      final api = _api;
      final serverId = _serverBookmarks && api != null
          ? await api.addEbookBookmark(widget.itemId, cfi: key, title: _bookmarkTitle(page))
          : null;
      final added = await _annotationService.addBookmark(itemId: widget.itemId, cfi: key, serverId: serverId);
      _bookmarks.insert(0, added);
      if (mounted) showOverlayToast(context, l.bookmarkAdded, icon: Icons.bookmark_rounded);
    }
    if (mounted) setState(() {});
  }

  void _showBookmarks() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        final marks = [
          for (final b in _bookmarks)
            if (_pageOf(b) != null) (bookmark: b, page: _pageOf(b)!),
        ]..sort((a, b) => a.page.compareTo(b.page));
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l.readerBookmarks(marks.length),
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (marks.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Text(l.readerNoBookmarks, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final m in marks)
                        Dismissible(
                          key: ValueKey(m.bookmark.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: cs.error,
                            child: Icon(Icons.delete_rounded, color: cs.onError),
                          ),
                          confirmDismiss: (_) => _removeBookmark(m.bookmark),
                          onDismissed: (_) {
                            setSheet(() {});
                            if (mounted) setState(() {});
                          },
                          child: ListTile(
                            leading: Icon(Icons.bookmark_rounded, color: cs.primary),
                            title: Text(m.bookmark.note ?? _bookmarkTitle(m.page),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: m.bookmark.note != null
                                ? Text(_bookmarkTitle(m.page),
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
                                : null,
                            dense: true,
                            onTap: () {
                              Navigator.pop(ctx);
                              _controller?.jumpToPage(m.page - 1);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ]),
          ),
        );
      }),
    );
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
    setState(() => _page = index + 1);
    _precacheAround(index);
    _pendingPage = _page;
    if (DateTime.now().difference(_lastSync).inSeconds >= 10) _flushProgress();
  }

  void _flushProgress() {
    final page = _pendingPage;
    final api = _syncApi;
    final count = _pages?.count ?? 0;
    if (page == null || count <= 0 || page == _lastSyncedPage) return;
    if (api == null && !_otherAccount) return;
    final frac = (page / count).clamp(0.0, 1.0);
    final cfis = _cfis;
    final location = cfis != null && page <= cfis.length ? cfis[page - 1] : '$page';
    if (api == null) {
      unawaited(DownloadService().saveOtherAccountReadingSpot(widget.itemId, location, frac));
    } else {
      ProgressSyncService().pushEbookProgress(api, widget.itemId, location: location, progress: frac);
      _lib?.applyLocalEbookProgress(widget.itemId, location: location, progress: frac);
    }
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
          child: ComicPager(
            controller: controller,
            itemCount: pages.count,
            imageFor: pages.image,
            reverse: _rtl,
            onPageChanged: _onPageChanged,
            onTap: _onPageTap,
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
                tooltip: l.addBookmark,
                icon: Icon(
                  _bookmarksOn(_page).isNotEmpty ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: Colors.white,
                ),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                tooltip: l.bookmarks,
                icon: const Icon(Icons.bookmarks_outlined, color: Colors.white),
                onPressed: _showBookmarks,
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

/// The pages: swipe or tap the edges to turn, pinch or double-tap to zoom,
/// drag to pan while zoomed. Turning is held while two fingers are down or
/// the page is zoomed: otherwise the page swipe claims a pinch whose first
/// finger moves before the second lands, and the page never zooms.
class ComicPager extends StatefulWidget {
  final PageController controller;
  final int itemCount;
  final ImageProvider Function(int index) imageFor;
  final bool reverse;
  final ValueChanged<int> onPageChanged;
  final GestureTapUpCallback onTap;

  const ComicPager({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.imageFor,
    required this.onPageChanged,
    required this.onTap,
    this.reverse = false,
  });

  @override
  State<ComicPager> createState() => _ComicPagerState();
}

class _ComicPagerState extends State<ComicPager> {
  final Set<int> _pointers = {};
  bool _zoomed = false;
  late int _current = widget.controller.initialPage;

  bool get _holdPage => _zoomed || _pointers.length > 1;

  void _trackPointers(VoidCallback change) {
    final before = _holdPage;
    change();
    if (_holdPage != before) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _trackPointers(() => _pointers.add(e.pointer)),
      onPointerUp: (e) => _trackPointers(() => _pointers.remove(e.pointer)),
      onPointerCancel: (e) => _trackPointers(() => _pointers.remove(e.pointer)),
      child: PageView.builder(
        controller: widget.controller,
        reverse: widget.reverse,
        physics: _holdPage ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
        onPageChanged: (i) {
          setState(() {
            _current = i;
            _zoomed = false;
          });
          widget.onPageChanged(i);
        },
        itemCount: widget.itemCount,
        itemBuilder: (_, i) => _ComicPage(
          key: ValueKey('comic-page-$i'),
          image: widget.imageFor(i),
          active: i == _current,
          onTap: widget.onTap,
          onZoomChanged: (z) {
            if (i == _current && z != _zoomed) setState(() => _zoomed = z);
          },
        ),
      ),
    );
  }
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
