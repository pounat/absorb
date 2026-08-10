import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';
import '../l10n/app_localizations.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _loading = true;
  Map<String, List<Bookmark>> _allBookmarks = {};
  bool _selecting = false;
  String _sort = 'newest';
  // Selected bookmarks as "itemId::bookmarkId" keys
  final Set<String> _selected = {};
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
    _loadSort();
    PlayerSettings.getSpeedAdjustedTime().then((v) {
      if (mounted && v != _speedAdjustedTime) setState(() => _speedAdjustedTime = v);
    });
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
    });
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
                        if (_allBookmarks.isNotEmpty) ...[
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

                  // Content
                  if (_allBookmarks.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_border_rounded, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(l.bookmarksNoBookmarks, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
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
                            onJump: (id, bm) =>
                                _jumpToBookmark(id, bm, resolvedTitle ?? ''),
                          );
                        },
                      ),
                    ),

                  // Bottom delete bar
                  if (_selecting && _selected.isNotEmpty)
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
                            l.bookmarksSelectedCount(_selected.length),
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
                            onPressed: _deleteSelected,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: _buildCover(),
                    ),
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

  Widget _buildCover() {
    if (coverUrl == null || coverUrl!.isEmpty) return _coverPlaceholder();

    if (coverUrl!.startsWith('/')) {
      final file = File(coverUrl!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coverPlaceholder());
      }
      return _coverPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: coverUrl!,
      fit: BoxFit.cover,
      httpHeaders: mediaHeaders,
      placeholder: (_, __) => _coverPlaceholder(),
      errorWidget: (_, __, ___) => _coverPlaceholder(),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.headphones_rounded, size: 20,
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
