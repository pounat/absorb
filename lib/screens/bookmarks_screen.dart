import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/app_shell.dart';
import '../services/audio_player_service.dart';
import '../services/bookmark_service.dart';
import '../services/chromecast_service.dart';
import '../services/scoped_prefs.dart';
import '../widgets/bookmark_detail_dialog.dart';
import '../widgets/card_buttons.dart';
import '../services/download_service.dart';
import '../services/ebook_annotation_service.dart';
import '../services/ebook_cache.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/ebook_router.dart';
import '../widgets/quote_share_sheet.dart';
import '../widgets/overlay_toast.dart';
import '../l10n/app_localizations.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, List<Bookmark>> _allBookmarks = {};
  Map<String, List<EbookAnnotation>> _highlights = {};
  late final TabController _tabs;
  int _tabIndex = 0;
  bool _selecting = false;
  String _sort = 'newest';
  // Selected bookmarks as "itemId::bookmarkId" keys
  final Set<String> _selected = {};
  // Same idea on the highlights tab, keyed "itemId::annotationId". Separate
  // sets so a selection can't leak across tabs.
  final Set<String> _selectedHighlights = {};
  final Map<String, String> _titleCache = {};
  bool _speedAdjustedTime = true;
  // Per-book playback speed so each group's timestamps honor the
  // speed-adjusted-time setting at that book's own speed.
  final Map<String, double> _bookSpeeds = {};
  double _defaultSpeed = 1.0;

  static const _titleCacheKey = 'bookmark_book_titles';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!mounted || _tabs.index == _tabIndex) return;
      setState(() => _tabIndex = _tabs.index);
      // Selection is a bookmarks-only mode, so leave it behind on the way out.
      if (_tabs.index != 0 && _selecting) _exitSelection();
    });
    _loadSort();
    _loadHighlights();
    PlayerSettings.getSpeedAdjustedTime().then((v) {
      if (mounted && v != _speedAdjustedTime) setState(() => _speedAdjustedTime = v);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    final highlights = await EbookAnnotationService().getAllHighlights();
    if (!mounted) return;
    // The tab bar disappears with the last highlight, so don't strand the view
    // on a tab that no longer has a header.
    if (highlights.isEmpty && _tabs.index != 0) _tabs.index = 0;
    setState(() => _highlights = highlights);
    await _fetchMissingTitles(highlights.keys.toList());
  }

  /// Fills the title cache for books we only know by ID, so highlight cards
  /// show a real title instead of a placeholder bar.
  Future<void> _fetchMissingTitles(List<String> itemIds) async {
    final api = context.read<AuthProvider>().apiService;
    var dirty = false;
    for (final itemId in itemIds) {
      if (!mounted) break;
      if (_titleCache.containsKey(itemId)) continue;
      final resolved = _resolveTitle(itemId);
      if (resolved != null) {
        _titleCache[itemId] = resolved;
        dirty = true;
        continue;
      }
      if (api == null) continue;
      final item = await api.getLibraryItem(itemId);
      final media = item?['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String?;
      if (title != null && title.isNotEmpty) {
        _titleCache[itemId] = title;
        dirty = true;
      }
    }
    if (dirty) {
      await _saveTitleCache();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadBookSpeeds() async {
    _defaultSpeed = await PlayerSettings.getDefaultSpeed();
    var changed = false;
    for (final itemId in _allBookmarks.keys) {
      if (_bookSpeeds.containsKey(itemId)) continue;
      final s = await PlayerSettings.getBookSpeed(itemId);
      if (s != null) {
        _bookSpeeds[itemId] = s;
        changed = true;
      }
    }
    if (mounted && changed) setState(() {});
  }

  double _displaySpeedFor(String itemId) {
    if (!_speedAdjustedTime) return 1.0;
    final player = AudioPlayerService();
    if (player.currentItemId == itemId) return player.speed;
    return _bookSpeeds[itemId] ?? _defaultSpeed;
  }

  Future<void> _loadSort() async {
    _sort = await PlayerSettings.getBookmarkSort();
    // Read the persisted title cache before rendering so rows don't flash
    // raw item-ID fragments on the first paint while _syncAll fetches.
    await _loadTitleCache();
    // Show local bookmarks immediately, then sync with server
    _load();
    _syncAll();
  }

  Future<void> _loadTitleCache() async {
    final raw = await ScopedPrefs.getString(_titleCacheKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          if (k is String && v is String) _titleCache[k] = v;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveTitleCache() async {
    try {
      await ScopedPrefs.setString(_titleCacheKey, jsonEncode(_titleCache));
    } catch (_) {}
  }

  Future<void> _load() async {
    final all = await BookmarkService().getAllBookmarks(sort: _sort);
    if (mounted) setState(() { _allBookmarks = all; _loading = false; });
    await _loadBookSpeeds();
  }

  Future<void> _syncAll() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final userBookmarks = await api.getAllBookmarks();
    if (userBookmarks == null || !mounted) return;
    final itemIds = <String>{};
    for (final b in userBookmarks) {
      final itemId = b['libraryItemId'] as String? ?? '';
      if (itemId.isNotEmpty) itemIds.add(itemId);
    }
    // Also include items we have local bookmarks for
    final local = await BookmarkService().getAllBookmarks();
    itemIds.addAll(local.keys);
    // Group server bookmarks by itemId for efficient sync
    final serverByItem = <String, List<Map<String, dynamic>>>{};
    for (final b in userBookmarks) {
      final id = b['libraryItemId'] as String? ?? '';
      if (id.isNotEmpty) {
        serverByItem.putIfAbsent(id, () => []).add(b);
      }
    }
    // Sync each item with pre-loaded server data
    for (final itemId in itemIds) {
      if (!mounted) break;
      await BookmarkService().syncBookmarks(itemId, api,
        preloadedServerBookmarks: serverByItem[itemId] ?? []);
    }
    // Fetch titles for items not in any local cache
    bool titleCacheDirty = false;
    for (final itemId in itemIds) {
      if (!mounted) break;
      if (_titleCache.containsKey(itemId)) continue;
      // Only need a server fetch when no cache (library/download/title) has it.
      final resolved = _resolveTitle(itemId);
      if (resolved == null) {
        final item = await api.getLibraryItem(itemId);
        if (item != null) {
          final media = item['media'] as Map<String, dynamic>? ?? {};
          final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
          final title = metadata['title'] as String?;
          if (title != null && title.isNotEmpty) {
            _titleCache[itemId] = title;
            titleCacheDirty = true;
          }
        }
      } else {
        // Promote library/download-resolved titles into our persisted cache
        // so future cold visits don't flash the fallback either.
        _titleCache[itemId] = resolved;
        titleCacheDirty = true;
      }
    }
    if (titleCacheDirty) await _saveTitleCache();
    // Reload after sync
    if (mounted) _load();
  }

  String _selKey(String itemId, String bookmarkId) => '$itemId::$bookmarkId';

  void _toggleSelect(String itemId, String bookmarkId) {
    setState(() {
      final key = _selKey(itemId, bookmarkId);
      if (_selected.contains(key)) {
        _selected.remove(key);
        if (_selected.isEmpty) _selecting = false;
      } else {
        _selected.add(key);
      }
    });
  }

  void _toggleBookGroup(String itemId, List<Bookmark> bookmarks) {
    setState(() {
      final keys = bookmarks.map((b) => _selKey(itemId, b.id)).toSet();
      final allSelected = keys.every(_selected.contains);
      if (allSelected) {
        _selected.removeAll(keys);
        if (_selected.isEmpty) _selecting = false;
      } else {
        _selected.addAll(keys);
      }
    });
  }

  void _enterSelection(String itemId, String bookmarkId) {
    setState(() {
      _selecting = true;
      _selected.add(_selKey(itemId, bookmarkId));
    });
  }

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selected.clear();
      _selectedHighlights.clear();
    });
  }

  void _toggleHighlight(String itemId, String annotationId) {
    setState(() {
      final key = _selKey(itemId, annotationId);
      if (_selectedHighlights.contains(key)) {
        _selectedHighlights.remove(key);
        if (_selectedHighlights.isEmpty) _selecting = false;
      } else {
        _selectedHighlights.add(key);
      }
    });
  }

  void _toggleHighlightGroup(String itemId, List<EbookAnnotation> highlights) {
    setState(() {
      final keys = highlights.map((h) => _selKey(itemId, h.id)).toSet();
      if (keys.every(_selectedHighlights.contains)) {
        _selectedHighlights.removeAll(keys);
        if (_selectedHighlights.isEmpty) _selecting = false;
      } else {
        _selectedHighlights.addAll(keys);
      }
    });
  }

  void _enterHighlightSelection(String itemId, String annotationId) {
    setState(() {
      _selecting = true;
      _selectedHighlights.add(_selKey(itemId, annotationId));
    });
  }

  Future<void> _deleteSelectedHighlights() async {
    if (_selectedHighlights.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final count = _selectedHighlights.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(l.highlightsDeleteCount(count)),
        content: Text(l.bookmarksDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final grouped = <String, List<String>>{};
    for (final key in _selectedHighlights) {
      final parts = key.split('::');
      grouped.putIfAbsent(parts[0], () => []).add(parts[1]);
    }
    for (final entry in grouped.entries) {
      for (final id in entry.value) {
        await EbookAnnotationService()
            .delete(itemId: entry.key, annotationId: id);
      }
    }

    _exitSelection();
    await _loadHighlights();
    if (mounted) {
      showOverlayToast(context, l.highlightsDeletedCount(count),
          icon: Icons.delete_outline_rounded);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;

    final l = AppLocalizations.of(context)!;
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(l.bookmarksDeleteCount(count)),
        content: Text(l.bookmarksDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Group selections by itemId
    final grouped = <String, List<String>>{};
    for (final key in _selected) {
      final parts = key.split('::');
      grouped.putIfAbsent(parts[0], () => []).add(parts[1]);
    }

    for (final entry in grouped.entries) {
      for (final bmId in entry.value) {
        await BookmarkService().deleteBookmark(itemId: entry.key, bookmarkId: bmId, api: context.read<AuthProvider>().apiService);
      }
    }

    _exitSelection();
    await _load();

    if (mounted) {
      showOverlayToast(context, l.bookmarksDeletedCount(count),
          icon: Icons.delete_outline_rounded);
    }
  }

  /// Returns the book title for [itemId] from any available cache, or null
  /// when the title isn't known locally yet. Callers should render a neutral
  /// placeholder on null rather than the raw item ID.
  String? _resolveTitle(String itemId) {
    final cached = _titleCache[itemId];
    if (cached != null && cached.isNotEmpty) return cached;
    final libCache =
        context.read<LibraryProvider>().absorbingItemCache[itemId];
    if (libCache != null) {
      final media = libCache['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String?;
      if (title != null && title.isNotEmpty) return title;
    }
    final dl = DownloadService().getInfo(itemId);
    if (dl.title != null && dl.title!.isNotEmpty) return dl.title!;
    return null;
  }

  Future<void> _jumpToBookmark(String itemId, Bookmark bookmark, String bookTitle) async {
    final l = AppLocalizations.of(context)!;
    final api = context.read<AuthProvider>().apiService;
    final result = await showModalBottomSheet<BookmarkDetailResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BookmarkDetailSheet(
        itemId: itemId,
        bookmark: bookmark,
        api: api,
      ),
    );
    if (!mounted) return;

    // Anything other than Jump just reflects saved title/note/time edits.
    if (result == null || result.action != 'jump') {
      _load();
      return;
    }

    final position = result.position;
    final lib = context.read<LibraryProvider>();
    final player = AudioPlayerService();

    // This book is casting: seek the Chromecast. The local player may hold
    // nothing while a cast is active, so this has to come first.
    final cast = ChromecastService();
    if (cast.isCasting && cast.castingItemId == itemId) {
      await cast.seekTo(Duration(seconds: position.round()));
      if (!cast.isPlaying) cast.play();
      if (mounted) Navigator.pop(context);
      AppShell.goToAbsorbingGlobal();
      return;
    }

    // Same book already loaded: just seek.
    if (player.currentItemId == itemId) {
      await player.seekTo(Duration(seconds: position.round()));
      if (!player.isPlaying) player.play();
      if (mounted) Navigator.pop(context);
      AppShell.goToAbsorbingGlobal();
      return;
    }

    if (api == null) {
      if (mounted) {
        showOverlayToast(context, l.bookmarksNotConnected,
            icon: Icons.cloud_off_rounded);
      }
      return;
    }

    final fullItem = await api.getLibraryItem(itemId);
    if (fullItem == null) {
      if (mounted) {
        showOverlayToast(context, l.bookmarksCouldNotLoad,
            icon: Icons.error_outline_rounded);
      }
      return;
    }

    final media = fullItem['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? '';
    final author = metadata['authorName'] as String? ?? '';
    final coverUrl = lib.getCoverUrl(itemId);
    final duration = (media['duration'] is num)
        ? (media['duration'] as num).toDouble() : 0.0;
    final chapters = (media['chapters'] as List<dynamic>?) ?? [];

    final error = await player.playItem(
      api: api,
      itemId: itemId,
      title: title,
      author: author,
      coverUrl: coverUrl,
      totalDuration: duration,
      chapters: chapters,
      startTime: position,
      forceStartTime: true,
      libraryId: fullItem['libraryId'] as String?,
    );
    if (error != null && mounted) showErrorToast(context, error);

    if (mounted) Navigator.pop(context);
    AppShell.goToAbsorbingGlobal();
  }

  /// Opens the book at the highlight. A downloaded ebook opens from the reader
  /// cache, so this still works offline.
  Future<void> _openHighlight(String itemId, EbookAnnotation highlight) async {
    final l = AppLocalizations.of(context)!;
    final api = context.read<AuthProvider>().apiService;
    var title = _resolveTitle(itemId);
    var ebookFile = await cachedEbookFileFor(itemId);
    if (ebookFile == null && api != null) {
      final item = await api.getLibraryItem(itemId);
      ebookFile = resolveEbookFile(item);
      if (title == null) {
        final media = item?['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        title = metadata['title'] as String?;
      }
    }
    if (!mounted) return;
    if (ebookFile == null) {
      showOverlayToast(
        context,
        api == null ? l.bookmarksNotConnected : l.noEbookFileFound,
        icon: Icons.menu_book_outlined,
      );
      return;
    }
    await openEbookReader(
      context,
      itemId: itemId,
      title: title ?? '',
      ebookFile: ebookFile,
      openAtCfi: highlight.cfi,
    );
    // Highlights added or removed while reading show up on the way back.
    if (mounted) await _loadHighlights();
  }

  Future<void> _highlightActions(String itemId, EbookAnnotation highlight) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final action = await showAdaptiveActionMenu<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if ((highlight.selectedText ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                highlight.selectedText!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ListTile(
            leading: Icon(Icons.ios_share_rounded, color: cs.onSurfaceVariant),
            title: Text(l.quoteShareTitle),
            onTap: () => Navigator.pop(ctx, 'share'),
          ),
          ListTile(
            leading: Icon(Icons.menu_book_rounded, color: cs.onSurfaceVariant),
            title: Text(l.highlightOpenInBook),
            onTap: () => Navigator.pop(ctx, 'open'),
          ),
          ListTile(
            leading: Icon(Icons.copy_rounded, color: cs.onSurfaceVariant),
            title: Text(l.readerTooltipCopy),
            onTap: () => Navigator.pop(ctx, 'copy'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: cs.error),
            title: Text(l.highlightDeleteAction, style: TextStyle(color: cs.error)),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'share') {
      await _shareHighlight(itemId, highlight);
    } else if (action == 'open') {
      await _openHighlight(itemId, highlight);
    } else if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: highlight.selectedText ?? ''));
      if (mounted) showOverlayToast(context, l.readerCopied, icon: Icons.copy_rounded);
    } else if (action == 'delete') {
      await EbookAnnotationService()
          .delete(itemId: itemId, annotationId: highlight.id);
      await _loadHighlights();
      if (mounted) {
        showOverlayToast(context, l.highlightDeleted,
            icon: Icons.delete_outline_rounded);
      }
    }
  }

  Future<void> _shareHighlight(String itemId, EbookAnnotation highlight) async {
    await showQuoteShareSheet(
      context,
      itemId: itemId,
      quote: highlight.selectedText ?? '',
      bookTitle: _resolveTitle(itemId),
      author: _resolveAuthor(itemId),
      chapter: highlight.chapter,
    );
  }

  /// Author for the quote card, from whatever cache already knows this book.
  /// The card just drops the line when nothing does.
  String? _resolveAuthor(String itemId) {
    final libCache = context.read<LibraryProvider>().absorbingItemCache[itemId];
    if (libCache != null) {
      final media = libCache['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final author = metadata['authorName'] as String?;
      if (author != null && author.isNotEmpty) return author;
    }
    final dl = DownloadService().getInfo(itemId);
    if (dl.author != null && dl.author!.isNotEmpty) return dl.author;
    return null;
  }

  Widget _emptyState(ColorScheme cs, TextTheme tt, IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(label, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    if (_allBookmarks.isEmpty) {
      return _emptyState(
          cs, tt, Icons.bookmark_border_rounded, l.bookmarksNoBookmarks);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _allBookmarks.length,
      itemBuilder: (ctx, i) {
        final lib = context.read<LibraryProvider>();
        final itemId = _allBookmarks.keys.elementAt(i);
        final bookmarks = _allBookmarks[itemId]!;
        final resolvedTitle = _resolveTitle(itemId);
        final coverUrl = lib.getCoverUrl(itemId, width: 400);
        return _BookGroup(
          itemId: itemId,
          title: resolvedTitle,
          coverUrl: coverUrl,
          mediaHeaders: lib.mediaHeaders,
          bookmarks: bookmarks,
          displaySpeed: _displaySpeedFor(itemId),
          cs: cs,
          tt: tt,
          selecting: _selecting,
          selected: _selected,
          onToggle: _toggleSelect,
          onToggleGroup: () => _toggleBookGroup(itemId, bookmarks),
          onLongPress: _enterSelection,
          onJump: (id, bm) => _jumpToBookmark(id, bm, resolvedTitle ?? ''),
        );
      },
    );
  }

  Widget _buildHighlightsTab(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    if (_highlights.isEmpty) {
      return _emptyState(
          cs, tt, Icons.format_quote_rounded, l.readerNoHighlights);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _highlights.length,
      itemBuilder: (ctx, i) {
        final lib = context.read<LibraryProvider>();
        final itemId = _highlights.keys.elementAt(i);
        final highlights = _highlights[itemId]!;
        return _HighlightGroup(
          itemId: itemId,
          title: _resolveTitle(itemId),
          coverUrl: lib.getCoverUrl(itemId, width: 400),
          mediaHeaders: lib.mediaHeaders,
          highlights: highlights,
          cs: cs,
          tt: tt,
          selecting: _selecting,
          selected: _selectedHighlights,
          onActions: _highlightActions,
          onToggle: _toggleHighlight,
          onToggleGroup: () => _toggleHighlightGroup(itemId, highlights),
          onLongPress: _enterHighlightSelection,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                    child: Row(children: [
                      Expanded(child: AbsorbPageHeader(title: l.bookmarksTitle, padding: EdgeInsets.zero)),
                      if (_selecting)
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                          tooltip: l.bookmarksCancelSelection,
                          onPressed: _exitSelection,
                        )
                      else ...[
                        if (_tabIndex == 1 && _highlights.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.checklist_rounded, color: cs.onSurfaceVariant),
                            tooltip: l.bookmarksSelect,
                            onPressed: () => setState(() => _selecting = true),
                          ),
                        if (_tabIndex == 0 && _allBookmarks.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () {
                              final next = _sort == 'newest' ? 'position'
                                  : _sort == 'position' ? 'position_desc'
                                  : 'newest';
                              setState(() => _sort = next);
                              PlayerSettings.setBookmarkSort(next);
                              _load();
                            },
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: cs.onSurface.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(
                                  _sort == 'newest' ? Icons.schedule_rounded
                                      : _sort == 'position' ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: cs.onSurfaceVariant, size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _sort == 'newest' ? l.bookmarksScreenSortNewest
                                      : l.bookmarksScreenSortPosition,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ]),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.checklist_rounded, color: cs.onSurfaceVariant),
                            tooltip: l.bookmarksSelect,
                            onPressed: () => setState(() => _selecting = true),
                          ),
                        ],
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Audiobook bookmarks and ebook highlights, tabbed only once
                  // there's at least one highlight to show.
                  if (_highlights.isNotEmpty)
                    TabBar(
                      controller: _tabs,
                      tabs: [
                        Tab(text: l.bookmarksTabBookmarks),
                        Tab(text: l.bookmarksTabHighlights),
                      ],
                      labelColor: cs.primary,
                      unselectedLabelColor: cs.onSurfaceVariant,
                      indicatorColor: cs.primary,
                      dividerColor: Colors.transparent,
                    ),
                  if (_highlights.isNotEmpty) const SizedBox(height: 8),

                  Expanded(
                    child: _highlights.isEmpty
                        ? _buildBookmarksTab(cs, tt, l)
                        : TabBarView(
                            controller: _tabs,
                            children: [
                              _buildBookmarksTab(cs, tt, l),
                              _buildHighlightsTab(cs, tt, l),
                            ],
                          ),
                  ),

                  // Bottom delete bar
                  if (_selecting &&
                      (_tabIndex == 0
                          ? _selected.isNotEmpty
                          : _selectedHighlights.isNotEmpty))
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(children: [
                          Text(
                            l.bookmarksSelectedCount(_tabIndex == 0
                                ? _selected.length
                                : _selectedHighlights.length),
                            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                          ),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: Text(l.delete),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.errorContainer,
                              foregroundColor: cs.onErrorContainer,
                            ),
                            onPressed: _tabIndex == 0
                                ? _deleteSelected
                                : _deleteSelectedHighlights,
                          ),
                        ]),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _BookGroup extends StatelessWidget {
  final String itemId;
  final String? title;
  final String? coverUrl;
  final Map<String, String> mediaHeaders;
  final List<Bookmark> bookmarks;
  final double displaySpeed;
  final ColorScheme cs;
  final TextTheme tt;
  final bool selecting;
  final Set<String> selected;
  final void Function(String itemId, String bookmarkId) onToggle;
  final VoidCallback onToggleGroup;
  final void Function(String itemId, String bookmarkId) onLongPress;
  final void Function(String itemId, Bookmark bookmark) onJump;

  const _BookGroup({
    required this.itemId,
    required this.title,
    this.coverUrl,
    this.mediaHeaders = const {},
    required this.bookmarks,
    this.displaySpeed = 1.0,
    required this.cs,
    required this.tt,
    required this.selecting,
    required this.selected,
    required this.onToggle,
    required this.onToggleGroup,
    required this.onLongPress,
    required this.onJump,
  });

  String _selKey(String bmId) => '$itemId::$bmId';

  @override
  Widget build(BuildContext context) {
    final groupKeys = bookmarks.map((b) => _selKey(b.id)).toSet();
    final allSelected = selecting && groupKeys.every(selected.contains);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book header with cover + title
              GestureDetector(
                onTap: selecting ? onToggleGroup : null,
                child: Row(children: [
                  if (selecting)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        allSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 22,
                        color: allSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  _BookCover(coverUrl: coverUrl, mediaHeaders: mediaHeaders, cs: cs),
                  const SizedBox(width: 12),
                  Expanded(
                    child: title == null
                        ? Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : Text(
                            title!,
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  Text(
                    '${bookmarks.length}',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              // Bookmark rows
              for (var j = 0; j < bookmarks.length; j++) ...[
                if (j > 0) Divider(height: 1, indent: selecting ? 32 : 28, endIndent: 0, color: cs.outlineVariant.withValues(alpha: 0.3)),
                _BookmarkRow(
                  itemId: itemId,
                  bookmark: bookmarks[j],
                  displaySpeed: displaySpeed,
                  cs: cs,
                  tt: tt,
                  selecting: selecting,
                  isSelected: selected.contains(_selKey(bookmarks[j].id)),
                  onToggle: onToggle,
                  onLongPress: onLongPress,
                  onJump: onJump,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}

class _BookCover extends StatelessWidget {
  final String? coverUrl;
  final Map<String, String> mediaHeaders;
  final ColorScheme cs;
  final IconData placeholderIcon;

  const _BookCover({
    required this.coverUrl,
    required this.mediaHeaders,
    required this.cs,
    this.placeholderIcon = Icons.headphones_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(width: 40, height: 40, child: _image()),
    );
  }

  Widget _image() {
    if (coverUrl == null || coverUrl!.isEmpty) return _placeholder();

    if (coverUrl!.startsWith('/')) {
      final file = File(coverUrl!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder());
      }
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: coverUrl!,
      fit: BoxFit.cover,
      httpHeaders: mediaHeaders,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(placeholderIcon, size: 20,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  final String itemId;
  final Bookmark bookmark;
  final double displaySpeed;
  final ColorScheme cs;
  final TextTheme tt;
  final bool selecting;
  final bool isSelected;
  final void Function(String itemId, String bookmarkId) onToggle;
  final void Function(String itemId, String bookmarkId) onLongPress;
  final void Function(String itemId, Bookmark bookmark) onJump;

  const _BookmarkRow({
    required this.itemId,
    required this.bookmark,
    this.displaySpeed = 1.0,
    required this.cs,
    required this.tt,
    required this.selecting,
    required this.isSelected,
    required this.onToggle,
    required this.onLongPress,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selecting ? () => onToggle(itemId, bookmark.id) : () => onJump(itemId, bookmark),
      onLongPress: !selecting ? () => onLongPress(itemId, bookmark.id) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (selecting)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              )
            else
              Icon(Icons.bookmark_rounded, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookmark.title,
                    style: tt.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bookmark.note != null && bookmark.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        bookmark.note!,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              bookmark.formattedAt(displaySpeed),
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightGroup extends StatelessWidget {
  final String itemId;
  final String? title;
  final String? coverUrl;
  final Map<String, String> mediaHeaders;
  final List<EbookAnnotation> highlights;
  final ColorScheme cs;
  final TextTheme tt;
  final bool selecting;
  final Set<String> selected;
  final void Function(String itemId, EbookAnnotation highlight) onActions;
  final void Function(String itemId, String annotationId) onToggle;
  final VoidCallback onToggleGroup;
  final void Function(String itemId, String annotationId) onLongPress;

  const _HighlightGroup({
    required this.itemId,
    required this.title,
    this.coverUrl,
    this.mediaHeaders = const {},
    required this.highlights,
    required this.cs,
    required this.tt,
    required this.selecting,
    required this.selected,
    required this.onActions,
    required this.onToggle,
    required this.onToggleGroup,
    required this.onLongPress,
  });

  String _selKey(String id) => '$itemId::$id';

  @override
  Widget build(BuildContext context) {
    final groupKeys = highlights.map((h) => _selKey(h.id)).toSet();
    final allSelected = selecting && groupKeys.every(selected.contains);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: selecting ? onToggleGroup : null,
                child: Row(children: [
                if (selecting)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      allSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 22,
                      color: allSelected
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                _BookCover(
                  coverUrl: coverUrl,
                  mediaHeaders: mediaHeaders,
                  cs: cs,
                  placeholderIcon: Icons.menu_book_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: title == null
                      ? Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          title!,
                          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                Text(
                  '${highlights.length}',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                ]),
              ),
              const SizedBox(height: 8),
              for (var j = 0; j < highlights.length; j++) ...[
                if (j > 0)
                  Divider(height: 1, indent: 14, color: cs.outlineVariant.withValues(alpha: 0.3)),
                _HighlightRow(
                  itemId: itemId,
                  highlight: highlights[j],
                  cs: cs,
                  tt: tt,
                  selecting: selecting,
                  isSelected: selected.contains(_selKey(highlights[j].id)),
                  onActions: onActions,
                  onToggle: onToggle,
                  onLongPress: onLongPress,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String itemId;
  final EbookAnnotation highlight;
  final ColorScheme cs;
  final TextTheme tt;
  final bool selecting;
  final bool isSelected;
  final void Function(String itemId, EbookAnnotation highlight) onActions;
  final void Function(String itemId, String annotationId) onToggle;
  final void Function(String itemId, String annotationId) onLongPress;

  const _HighlightRow({
    required this.itemId,
    required this.highlight,
    required this.cs,
    required this.tt,
    required this.selecting,
    required this.isSelected,
    required this.onActions,
    required this.onToggle,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hex = (highlight.color ?? HighlightColor.yellow).hex;
    final barColor = Color(int.parse('FF${hex.substring(1)}', radix: 16));
    final created = highlight.createdAt;
    final date = l.backupDateFormat(created.month, created.day, created.year);
    final chapter = highlight.chapter;
    final meta = chapter != null && chapter.isNotEmpty
        ? l.highlightsMeta(chapter, date)
        : date;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selecting
          ? () => onToggle(itemId, highlight.id)
          : () => onActions(itemId, highlight),
      onLongPress: selecting ? null : () => onLongPress(itemId, highlight.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          if (selecting)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: isSelected
                    ? cs.primary
                    : cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          Expanded(
            child: Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: barColor, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                highlight.selectedText ?? '',
                style: tt.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (highlight.note != null && highlight.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.sticky_note_2_outlined, size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        highlight.note!,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 4),
              Text(
                meta,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
            ),
          ),
        ]),
      ),
    );
  }
}
