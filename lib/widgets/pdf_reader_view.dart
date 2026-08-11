import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/ebook_cache.dart';
import '../services/progress_sync_service.dart';
import '../services/volume_key_service.dart';
import 'adaptive_modal.dart';

/// Full-screen PDF reader. PDFs are fixed-layout, so this is deliberately
/// simpler than the EPUB reader (no font/margin/theme reflow): page scrolling,
/// an outline-as-chapters sheet, resume, and progress sync. Page number is
/// stored as the ebookLocation, the same field the EPUB reader uses for its CFI.
class PdfReaderView extends StatefulWidget {
  final String itemId;
  final String title;
  final Map<String, dynamic> ebookFile;

  const PdfReaderView({
    super.key,
    required this.itemId,
    required this.title,
    required this.ebookFile,
  });

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> with WidgetsBindingObserver {
  final _controller = PdfViewerController();
  ApiService? _api;
  LibraryProvider? _lib;
  File? _file;
  String? _error;
  bool _loading = true;

  int _initialPage = 1;
  int _page = 1;
  int _pageCount = 0;
  List<PdfOutlineNode> _outline = [];
  bool _showControls = true;

  // Progress sync throttling - same gentle cadence as the EPUB reader.
  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastSyncedPage = -1;
  int? _pendingPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullscreen(true);
    _api = context.read<AuthProvider>().apiService;
    _lib = context.read<LibraryProvider>();
    _loadInitialPage();
    _open();
    _volumeNav.attach();
  }

  // Flush on background so an OS kill can't lose the last pages read.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _flushProgress();
  }

  late final EreaderVolumeNav _volumeNav = EreaderVolumeNav(
    onPrev: () {
      if (_page > 1) _controller.goToPage(pageNumber: _page - 1);
    },
    onNext: () {
      if (_pageCount <= 0 || _page < _pageCount) {
        _controller.goToPage(pageNumber: _page + 1);
      }
    },
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _volumeNav.detach();
    _setFullscreen(false);
    _flushProgress();
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

  void _loadInitialPage() {
    final lib = context.read<LibraryProvider>();
    final loc = lib.getProgressData(widget.itemId)?['ebookLocation'] as String?;
    final p = int.tryParse(loc?.trim() ?? '');
    if (p != null && p >= 1) {
      _initialPage = p;
      _page = p;
    }
  }

  Future<void> _open() async {
    try {
      final api = _api;
      if (api == null) {
        setState(() { _error = 'Not connected to server'; _loading = false; });
        return;
      }
      final f = await fetchEbookToCache(api, widget.itemId, widget.ebookFile, widget.title);
      if (mounted) setState(() { _file = f; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  void _onPageChanged(int? page) {
    if (page == null || !mounted) return;
    setState(() => _page = page);
    _pendingPage = page;
    if (DateTime.now().difference(_lastSync).inSeconds >= 10) _flushProgress();
  }

  void _flushProgress() {
    final page = _pendingPage;
    final api = _api;
    if (page == null || api == null || _pageCount <= 0 || page == _lastSyncedPage) return;
    final frac = (page / _pageCount).clamp(0.0, 1.0);
    ProgressSyncService().pushEbookProgress(api, widget.itemId, location: '$page', progress: frac);
    _lib?.applyLocalEbookProgress(widget.itemId, location: '$page', progress: frac);
    _lastSync = DateTime.now();
    _lastSyncedPage = page;
    _pendingPage = null;
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _showOutline() {
    final cs = Theme.of(context).colorScheme;
    Widget header(BuildContext ctx, {required bool showClose}) => Padding(
      padding: showClose
          ? const EdgeInsets.fromLTRB(16, 8, 8, 8)
          : const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(ctx)!.readerChapters,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          if (showClose)
            IconButton(
              tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );

    showAdaptiveActionMenu<void>(
      context: context,
      backgroundColor: cs.surface,
      desktopWidth: 520,
      desktopScrollWrap: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (!ModalSurface.isDesktopOf(ctx)) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header(ctx, showClose: false),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _outlineTiles(_outline, ctx, 0),
                  ),
                ),
              ],
            ),
          );
        }
        return AdaptiveDraggableScrollableSheet(
          expand: false,
          builder: (_, scrollController) => SafeArea(
            child: Column(
              children: [
                header(ctx, showClose: true),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: _outlineTiles(_outline, ctx, 0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _outlineTiles(List<PdfOutlineNode> nodes, BuildContext ctx, int depth) {
    final cs = Theme.of(ctx).colorScheme;
    final out = <Widget>[];
    for (final n in nodes) {
      final title = n.title.trim();
      if (title.isNotEmpty) {
        out.add(ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: 16.0 + depth * 16, right: 16),
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurface)),
          onTap: () {
            Navigator.pop(ctx);
            if (n.dest != null) _controller.goToDest(n.dest);
          },
        ));
      }
      if (n.children.isNotEmpty) out.addAll(_outlineTiles(n.children, ctx, depth + 1));
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
    } else if (_error != null || _file == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error ?? l.noEbookFileFound,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    } else {
      final pct = _pageCount > 0 ? ((_page / _pageCount) * 100).round() : 0;
      body = Stack(
        children: [
          Positioned.fill(
            child: PdfViewer.file(
              _file!.path,
              controller: _controller,
              initialPageNumber: _initialPage,
              params: PdfViewerParams(
                backgroundColor: cs.surface,
                onViewerReady: (document, controller) async {
                  _pageCount = controller.pageCount;
                  try {
                    final o = await document.loadOutline();
                    if (mounted) setState(() => _outline = o);
                  } catch (_) {}
                  if (mounted) setState(() {});
                },
                onPageChanged: _onPageChanged,
                onGeneralTap: (ctx, controller, details) {
                  if (details.type == PdfViewerGeneralTapType.tap) _toggleControls();
                  return false;
                },
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
                        if (_outline.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.list_rounded, color: cs.onSurface),
                            onPressed: _showOutline,
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
                        Text('$_page / ${_pageCount > 0 ? _pageCount : '-'}',
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        const Spacer(),
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
