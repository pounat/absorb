import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'overlay_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import '../utils/cover_accent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/wording.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import 'card_buttons.dart';
import '../services/api_service.dart';
import '../services/bookmark_preview_player.dart';
import '../services/bookmark_service.dart';
import '../services/download_service.dart';
import '../services/ebook_cache.dart';
import '../services/progress_sync_service.dart';
import '../services/metadata_override_service.dart';
import '../services/socket_service.dart';
import '../services/scoped_prefs.dart';
import '../main.dart' show rootNavigatorKey, colorSourceNotifier, useColorEverywhereNotifier, manualSeedNotifier, manualColorScheme;
import '../screens/app_shell.dart';
import '../screens/book_edit_screen.dart';
import 'author_books_sheet.dart';
import 'narrator_books_sheet.dart';
import 'series_books_sheet.dart';
import 'absorbing_shared.dart';
import 'html_description.dart';
import 'metadata_lookup_sheet.dart';
import 'playlist_picker_sheet.dart';
import 'collection_picker_sheet.dart';
import 'absorb_wave_icon.dart';
import 'stackable_sheet.dart';
import 'ebook_router.dart';
import '../utils/duration_format.dart';

// ─── BOOK DETAIL BOTTOM SHEET ───────────────────────────────

void showBookDetailSheet(BuildContext context, String itemId) {
  showStackableSheet(
    context: context,
    useSafeArea: true,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (ctx, sc) => _BookDetailSheetContent(itemId: itemId, scrollController: sc),
  );
}

/// Long-press shortcut: a compact sheet with Absorb + Download up top and the
/// full set of book actions as pills, skipping the trip into the detail sheet.
/// Pass [initialItem] (the tile's library-item map) so it renders instantly.
void showQuickActionsSheet(BuildContext context, String itemId, {Map<String, dynamic>? initialItem}) {
  showStackableSheet(
    context: context,
    useSafeArea: true,
    initialChildSize: 0.6,
    maxChildSize: 0.92,
    builder: (ctx, sc) => _BookDetailSheetContent(
      itemId: itemId,
      scrollController: sc,
      quick: true,
      initialItem: initialItem,
    ),
  );
}

class _BookDetailSheetContent extends StatefulWidget {
  final String itemId;
  final ScrollController scrollController;
  final bool quick;
  final Map<String, dynamic>? initialItem;
  const _BookDetailSheetContent({
    required this.itemId,
    required this.scrollController,
    this.quick = false,
    this.initialItem,
  });
  @override State<_BookDetailSheetContent> createState() => _BookDetailSheetContentState();
}

class _BookDetailSheetContentState extends State<_BookDetailSheetContent> {
  Map<String, dynamic>? _item;
  Map<String, dynamic>? _rating;
  String? _asin;
  bool _isLoading = true;
  bool _chaptersExpanded = false;
  bool _bookmarksExpanded = false;
  bool _tracksExpanded = false;
  bool _filesExpanded = false;
  BookmarkPreviewPlayer? _preview;
  List<Bookmark> _bookmarks = [];
  bool _isAbsorbing = false;
  bool _hasLocalOverride = false;
  bool _showGoodreads = false;
  bool _ebookSaved = false;
  bool _ebookOfflineDownloading = false;
  bool _authorsExpanded = false;
  bool _narratorsExpanded = false;
  bool _squareCovers = false;
  ColorScheme? _rawCoverScheme;
  String? _coverSchemeUrl; // URL the current scheme was derived from

  /// The cover-derived scheme, unless the user has chosen a manual app color
  /// and opted to use it everywhere - then book pages wear that color too.
  ColorScheme? get _coverScheme {
    if (colorSourceNotifier.value == 'manual' && useColorEverywhereNotifier.value) {
      return manualColorScheme(manualSeedNotifier.value, Theme.of(context).brightness);
    }
    return _rawCoverScheme;
  }

  @override void initState() {
    super.initState();
    // Quick-actions sheet seeds from the tile's item map so it paints instantly
    // instead of flashing a spinner; _loadItem still runs to refine overrides.
    if (widget.initialItem != null) {
      _item = widget.initialItem;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _deriveCoverScheme();
      });
    }
    _loadItem();
    _loadBookmarks();
    SocketService().addItemUpdatedListener(_onSocketItemUpdated);
    PlayerSettings.getRectangleCovers().then((v) { if (mounted) setState(() => _squareCovers = !v); });
    PlayerSettings.getShowGoodreadsButton().then((v) { if (mounted) setState(() => _showGoodreads = v); });
    ScopedPrefs.getStringList('saved_ebooks').then((list) {
      if (mounted && list.contains(widget.itemId)) {
        setState(() => _ebookSaved = true);
      }
    });
  }

  @override
  void dispose() {
    SocketService().removeItemUpdatedListener(_onSocketItemUpdated);
    _liveRefreshDebounce?.cancel();
    _preview?.removeListener(_onPreviewChanged);
    _preview?.dispose();
    super.dispose();
  }

  // Live-refresh when this item changes on the server (web UI edit, scan,
  // match) so an open sheet shows the new cover/metadata without reopening.
  Timer? _liveRefreshDebounce;
  void _onSocketItemUpdated(Map<String, dynamic> data) {
    if (!mounted || data['id'] != widget.itemId) return;
    _liveRefreshDebounce?.cancel();
    _liveRefreshDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _loadItem();
    });
  }

  Future<void> _loadBookmarks() async {
    final bm = await BookmarkService().getBookmarks(widget.itemId, sort: 'position');
    if (mounted) setState(() => _bookmarks = bm);
  }

  Future<void> _loadItem() async {
    debugPrint('[BookDetail] _loadItem start item=${widget.itemId}');
    final loadStart = DateTime.now();
    // Force re-derivation of cover scheme on reload (cover may have changed).
    _coverSchemeUrl = null;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;

    // Try server first
    if (api != null && !lib.isOffline) {
      try {
        final item = await api.getLibraryItem(widget.itemId);
        debugPrint('[BookDetail] server fetch done in ${DateTime.now().difference(loadStart).inMilliseconds}ms (item=${item != null ? "ok" : "null"})');
        if (item != null && mounted) {
          // Apply local metadata overrides
          final overrideService = MetadataOverrideService();
          final override = await overrideService.get(widget.itemId);
          Map<String, dynamic> finalItem = item;
          if (override != null) {
            finalItem = overrideService.applyOverrides(item, override);
            _hasLocalOverride = true;
          }

          setState(() { _item = finalItem; _isLoading = false; });
          _deriveCoverScheme();

          // Fetch Audible rating
          final media = finalItem['media'] as Map<String, dynamic>? ?? {};
          final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
          final asin = metadata['asin'] as String?;
          final title = metadata['title'] as String? ?? '';
          final author = metadata['authorName'] as String?;

          // Show any cached rating immediately so the stars don't blink in
          // and out between detail opens. The fresh fetch below replaces it
          // if Audnexus answers; if it doesn't, the cached value stays.
          final cached = await ApiService.getCachedAudibleRating(widget.itemId);
          if (cached != null && mounted) {
            setState(() {
              _rating = cached;
              _asin = cached['asin'] as String? ?? asin;
            });
          }

          Map<String, dynamic>? rating;
          if (asin != null && asin.isNotEmpty) {
            rating = await ApiService.getAudibleRating(asin);
          }
          if ((rating == null || (rating['rating'] as num).toDouble() <= 0) &&
              title.isNotEmpty) {
            final fallback = await api.searchAudibleRating(title, author);
            if (fallback != null && (fallback['rating'] as num).toDouble() > 0) {
              rating = fallback;
            }
          }
          if (rating != null && mounted) {
            final freshRating = (rating['rating'] as num).toDouble();
            final freshAsin = rating['asin'] as String? ?? asin;
            setState(() {
              _rating = rating;
              _asin = freshAsin;
            });
            await ApiService.setCachedAudibleRating(
                widget.itemId, freshRating, freshAsin);
          }
          return;
        }
      } catch (_) {
        // Server unreachable — fall through to offline
      }
    }

    // Offline fallback: build item from local download data
    final dl = DownloadService().getInfo(widget.itemId);
    if (dl.sessionData != null) {
      try {
        final session = jsonDecode(dl.sessionData!) as Map<String, dynamic>;
        // Prefer full libraryItem if it wasn't stripped
        final localItem = session['libraryItem'] as Map<String, dynamic>?;
        if (localItem != null && mounted) {
          setState(() { _item = localItem; _isLoading = false; });
          _deriveCoverScheme();
          return;
        }
        // Build a synthetic item from session-level fields (mediaMetadata,
        // chapters, duration) which survive the libraryItem strip.
        final meta = session['mediaMetadata'] as Map<String, dynamic>?;
        if (meta != null && mounted) {
          setState(() {
            _item = {
              'id': widget.itemId,
              'media': {
                'metadata': meta,
                'duration': session['duration'],
                'chapters': session['chapters'],
              },
            };
            _isLoading = false;
          });
          _deriveCoverScheme();
          return;
        }
      } catch (_) {}
    }
    // Minimal fallback from DownloadInfo metadata
    if (dl.title != null && mounted) {
      setState(() {
        _item = {
          'id': widget.itemId,
          'media': {
            'metadata': {
              'title': dl.title,
              'authorName': dl.author ?? '',
            },
          },
        };
        _isLoading = false;
      });
      _deriveCoverScheme();
      return;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _deriveCoverScheme() {
    try {
    final url = _coverUrl;
    if (url == null) {
      debugPrint('[BookDetail] _deriveCoverScheme skipped (no cover url)');
      return;
    }
    // Skip if the scheme was already derived from this exact URL.
    if (url == _coverSchemeUrl) {
      debugPrint('[BookDetail] _deriveCoverScheme skipped (cached for this url)');
      return;
    }
    _coverSchemeUrl = url;
    final brightness = Theme.of(context).brightness;
    final ImageProvider provider;
    if (url.startsWith('/')) {
      provider = FileImage(File(url));
    } else {
      final lib = context.read<LibraryProvider>();
      provider = CachedNetworkImageProvider(url, headers: lib.mediaHeaders);
    }
    final t0 = DateTime.now();
    debugPrint('[BookDetail] _deriveCoverScheme start url=$url');
    PaletteGenerator.fromImageProvider(provider, maximumColorCount: 16)
        .then((palette) {
      debugPrint('[BookDetail] PaletteGenerator ok in ${DateTime.now().difference(t0).inMilliseconds}ms');
      final seedColor = accentFromCoverPalette(palette);
      if (seedColor == null || !mounted) return;
      setState(() => _rawCoverScheme = ColorScheme.fromSeed(
        seedColor: seedColor, brightness: brightness));
    }).catchError((e) {
      debugPrint('[BookDetail] PaletteGenerator error after ${DateTime.now().difference(t0).inMilliseconds}ms: $e');
      if (!mounted) return;
      setState(() {
        _coverSchemeUrl = null;
        _rawCoverScheme = ColorScheme.fromSeed(
          seedColor: Theme.of(context).colorScheme.primary,
          brightness: brightness,
        );
      });
    });
    } catch (e) {
      debugPrint('[BookDetail] _deriveCoverScheme failed (non-fatal): $e');
    }
  }

  String? get _coverUrl {
    final localCover = _item?['_localCoverUrl'] as String?;
    if (localCover != null && localCover.isNotEmpty) return localCover;
    final media = _item?['media'] as Map<String, dynamic>?;
    final coverPath = media?['coverPath'] as String?;
    if (coverPath == null || coverPath.isEmpty) return null;
    return context.read<LibraryProvider>().getCoverUrl(widget.itemId, width: 800);
  }

  /// Full-res cover for the viewer and sharing.
  String? get _fullResCoverUrl {
    final localCover = _item?['_localCoverUrl'] as String?;
    if (localCover != null && localCover.isNotEmpty) return localCover;
    final media = _item?['media'] as Map<String, dynamic>?;
    final coverPath = media?['coverPath'] as String?;
    if (coverPath == null || coverPath.isEmpty) return null;
    return context.read<LibraryProvider>().getCoverUrl(widget.itemId, width: 4000);
  }


  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Stack(children: [
        // Cover-derived color gradient background - lighter than blurred image.
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          stops: const [0.0, 0.4, 1.0],
          colors: [
            (_coverScheme?.primaryContainer ?? Theme.of(context).scaffoldBackgroundColor).withValues(alpha: 0.5),
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        )))),
        // Don't block sheet rendering on cover-scheme palette generation -
        // on iOS it can stall indefinitely when a download is saturating the
        // connection pool, leaving the sheet stuck with an undismissable
        // spinner. Accent colors fall back to the default scheme until the
        // palette resolves. Loading/failed states are wrapped in a scrollable
        // so drag-to-dismiss works even before content arrives.
        _isLoading
            ? SingleChildScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.24))),
                ),
              )
            : _item == null
                ? SingleChildScrollView(
                    controller: widget.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.85,
                      child: Center(child: Text(l.failedToLoad, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                    ),
                  )
                : AnimatedOpacity(
                    opacity: 1.0, duration: const Duration(milliseconds: 300),
                    child: widget.quick
                        ? _buildQuickContent(context, cs, tt, l)
                        : _buildContent(context, cs, tt, l)),
      ]),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final accent = _coverScheme?.primary ?? cs.primary;
    final media = _item!['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final chapters = media['chapters'] as List<dynamic>? ?? [];
    final audioFiles = media['audioFiles'] as List<dynamic>? ?? [];
    final libraryFiles = _item!['libraryFiles'] as List<dynamic>? ?? [];
    final title = metadata['title'] as String? ?? l.unknown;
    final authorName = metadata['authorName'] as String? ?? '';
    final descRaw = metadata['description'] as String? ?? '';
    final duration = (media['duration'] as num?)?.toDouble() ?? 0;
    final seriesEntries = metadata['series'] as List<dynamic>? ?? [];
    final genres = (metadata['genres'] as List<dynamic>?)?.cast<String>() ?? [];
    // ABS puts tags on the media object (LibraryItem.media.tags), not in
    // metadata. Some endpoints may stash them in metadata too — fall back to
    // that if media doesn't have them.
    final tagsRaw = (media['tags'] as List<dynamic>?)
        ?? (metadata['tags'] as List<dynamic>?)
        ?? const [];
    final tags = tagsRaw.cast<String>();
    final publisher = metadata['publisher'] as String? ?? '';
    final year = metadata['publishedYear'] as String? ?? '';
    final serverPath = _item!['path'] as String? ?? _item!['relPath'] as String? ?? '';
    final lib = context.watch<LibraryProvider>();
    final progress = lib.getProgress(widget.itemId);
    final auth = context.read<AuthProvider>();

    final progressData = lib.getProgressData(widget.itemId);
    final isFinished = progressData?['isFinished'] == true;
    final currentTime = (progressData?['currentTime'] as num?)?.toDouble() ?? 0;
    final ebookFile = resolveEbookFile(_item);

    final isEbookOnly = PlayerSettings.isEbookOnly(_item!);
    // Preview only makes sense before the book has been started. The 60s
    // grace means an accidental tap-and-close doesn't hide it forever. Check
    // the override-aware progress fraction too - the server currentTime can
    // lag local playback.
    final showPreview = !isEbookOnly && !isFinished && currentTime < 60 &&
        progress * duration < 60 && duration > 0;

    return ListView(controller: widget.scrollController, padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + MediaQuery.of(context).viewPadding.bottom), children: [
      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
      if (_coverUrl != null) ...[
        Center(child: GestureDetector(
          onTap: () => _showFullCover(context, _fullResCoverUrl ?? _coverUrl!, lib.mediaHeaders, title),
          child: Container(
            height: 240,
            width: _squareCovers ? 240 : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: _squareCovers
                ? (_coverUrl!.startsWith('/')
                    ? BlurPaddedCover(
                        blurChild: Image.file(File(_coverUrl!), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                        child: Image.file(File(_coverUrl!), fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox()),
                      )
                    : BlurPaddedCover(
                        blurChild: CachedNetworkImage(
                          imageUrl: _coverUrl!, fit: BoxFit.cover,
                          httpHeaders: lib.mediaHeaders,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: _coverUrl!, fit: BoxFit.contain,
                          httpHeaders: lib.mediaHeaders,
                          placeholder: (_, __) => const SizedBox(),
                          errorWidget: (_, __, ___) => const SizedBox(),
                        ),
                      ))
                : CachedNetworkImage(
                    imageUrl: _coverUrl!, fit: BoxFit.contain,
                    httpHeaders: lib.mediaHeaders,
                    placeholder: (_, __) => const SizedBox(),
                    errorWidget: (_, __, ___) => const SizedBox(),
                  ),
          ),
        )),
        const SizedBox(height: 16),
      ],
      Text(title, textAlign: TextAlign.center, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
      const SizedBox(height: 4),
      _buildAuthorLinks(context, metadata, cs, tt, accent),
      _buildNarratorLinks(context, metadata, cs, tt, accent),
      // ─── AUDIBLE RATING (space always reserved) ─────────
      const SizedBox(height: 8),
      if (_rating != null && (_rating!['rating'] as num).toDouble() > 0)
        Center(
          child: GestureDetector(
            onTap: _asin != null ? () => _showAudibleReviews(context) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ..._buildStars((_rating!['rating'] as num).toDouble(), accent),
                const SizedBox(width: 6),
                Text((_rating!['rating'] as num).toStringAsFixed(1),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                const SizedBox(width: 4),
                Text(l.onAudible, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ]),
            ),
          ),
        )
      else
        const SizedBox(height: 20),
      const SizedBox(height: 12),
      if (progress > 0 && !isFinished) ...[
        ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 4,
            backgroundColor: cs.onSurface.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(accent))),
        const SizedBox(height: 4),
        Text(l.percentComplete((progress * 100).toStringAsFixed(1)), textAlign: TextAlign.center,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
      ],
      if (isEbookOnly && ebookFile != null && canReadEbook(ebookFile))
        SizedBox(height: 52, child: FilledButton.icon(
          onPressed: () => _openEbookReader(context, auth, ebookFile, title),
          icon: const Icon(Icons.menu_book_rounded, size: 24),
          label: Text(l.readEbook,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary)),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ))
      else if (isEbookOnly && ebookFile != null)
        // Ebook-only but not readable in-app (CBR) - can't open it, so the
        // primary action exports the file to the device instead.
        SizedBox(height: 52, child: FilledButton.icon(
          onPressed: () => _saveEbook(context, auth, ebookFile, title),
          icon: Icon(_ebookSaved ? Icons.download_done_rounded : Icons.save_alt_rounded, size: 24),
          label: Text(l.ebookSaveToDevice,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary)),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ))
      else if (isEbookOnly)
        SizedBox(height: 52, child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.menu_book_rounded, size: 24),
          label: Text(l.ebookOnlyNoAudio,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ))
      else
      SizedBox(
        height: 52,
        child: ListenableBuilder(
          listenable: AudioPlayerService(),
          builder: (_, __) {
            final player = AudioPlayerService();
            final isCurrentPlaying =
                player.currentItemId == widget.itemId && player.isPlaying;
            final showAbsorbingState = _isAbsorbing || isCurrentPlaying;

            return FilledButton.icon(
              onPressed: showAbsorbingState
                  ? () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      AppShell.goToAbsorbingGlobal();
                    }
                  : () {
                      setState(() => _isAbsorbing = true);
                      _startAbsorb(
                        context,
                        auth: auth,
                        title: title,
                        author: authorName,
                        coverUrl: _coverUrl,
                        duration: duration,
                        chapters: chapters,
                      );
                    },
              icon: showAbsorbingState
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: AbsorbingWave(color: _coverScheme?.onPrimary ?? cs.onPrimary),
                    )
                  : isFinished
                      ? AbsorbReplayIcon(size: 24, color: _coverScheme?.onPrimary ?? cs.onPrimary)
                      : Icon(Icons.waves_rounded, size: 24, color: _coverScheme?.onPrimary ?? cs.onPrimary),
              label: Text(
                showAbsorbingState
                    ? Wording.of(context).absorbing
                    : isFinished
                        ? Wording.of(context).absorbAgain
                        : Wording.of(context).absorb,
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600, color: _coverScheme?.onPrimary ?? cs.onPrimary),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            );
          },
        ),
      ),
      // Primary action row: Download | Fully Absorb | Read (when ebook)
      const SizedBox(height: 12),
      Row(children: [
        if (!isEbookOnly) ...[
          Expanded(child: DownloadWideButton(itemId: widget.itemId, coverUrl: _coverUrl, title: title, author: authorName, accent: accent)),
          const SizedBox(width: 8),
        ],
        Expanded(child: GestureDetector(
          onTap: () => isFinished
              ? _markNotFinished(context, auth, currentTime, duration)
              : _markFinished(context, auth, duration),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: isFinished ? Colors.green.withValues(alpha: 0.06) : cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isFinished ? Colors.green.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                isFinished ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                size: 16,
                color: isFinished ? Colors.green : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                isFinished ? Wording.of(context).fullyAbsorbed : Wording.of(context).fullyAbsorbAction,
                style: TextStyle(
                  color: isFinished ? Colors.green : cs.onSurfaceVariant,
                  fontSize: 12, fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
        )),
        if (ebookFile != null && canReadEbook(ebookFile)) ...[
          const SizedBox(width: 8),
          // For ebook-only books the big button above is already "Read", so this
          // slot is the offline download (matching the audiobook download
          // button's Saved/green styling). For audiobooks with a companion ebook
          // it stays "Read" - the audio download already pulls the ebook along.
          Expanded(child: isEbookOnly
              ? ListenableBuilder(
                  listenable: DownloadService(),
                  builder: (_, __) {
                    final saved = DownloadService().isDownloaded(widget.itemId);
                    final dlGreen = Theme.of(context).brightness == Brightness.dark
                        ? Colors.greenAccent : Colors.green.shade700;
                    return GestureDetector(
                      onTap: _ebookOfflineDownloading
                          ? null
                          : (saved
                              ? () => _removeEbookOffline(context)
                              : () => _downloadEbookOffline(context, auth, ebookFile, title)),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: saved ? dlGreen.withValues(alpha: 0.08) : cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: saved ? dlGreen.withValues(alpha: 0.2) : cs.onSurface.withValues(alpha: 0.08)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          if (_ebookOfflineDownloading)
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurfaceVariant))
                          else
                            Icon(saved ? Icons.download_done_rounded : Icons.download_rounded,
                                size: 16, color: saved ? dlGreen : cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(saved ? l.saved : l.ebookDownload,
                              style: TextStyle(color: saved ? dlGreen : cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    );
                  },
                )
              : GestureDetector(
                  onTap: () => _openEbookReader(context, auth, ebookFile, title),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.menu_book_rounded, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(l.readEbook, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                )),
        ],
      ]),
      if (showPreview) ...[
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _togglePreview(context, chapters, duration),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (_preview?.isLoading ?? false)
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurfaceVariant))
              else
                Icon((_preview?.isPlaying ?? false) ? Icons.stop_rounded : Icons.headphones_rounded,
                    size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text((_preview?.isPlaying ?? false) ? l.chapterStopPreview : l.preview,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ],
      // More button below primary row
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => _showMoreSheet(context, auth, lib, title, authorName, progress, isFinished, duration, ebookFile, isEbookOnly, serverPath),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.more_horiz_rounded, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(l.moreActions, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (year.isNotEmpty) _chip(Icons.calendar_today_rounded, year),
        _chip(Icons.schedule_rounded, formatHm(duration)),
        if (chapters.isNotEmpty) _chip(Icons.list_rounded, l.chaptersChip(chapters.length)),
        ..._audioInfoChips(media),
        if (publisher.isNotEmpty) _chip(Icons.business_rounded, publisher),
        ...genres.take(3).map((g) => _chip(
              Icons.tag_rounded,
              g,
              onTap: () {
                Navigator.of(context).pop();
                AppShell.openLibraryWithGenreFilterGlobal(g);
              },
            )),
        ...tags.take(5).map((t) => _chip(
              Icons.local_offer_outlined,
              t,
              onTap: () {
                Navigator.of(context).pop();
                AppShell.openLibraryWithTagFilterGlobal(t);
              },
            )),
        if (progressData?['startedAt'] is num)
          _chip(Icons.play_circle_outline_rounded, l.startedDate(_fmtDate((progressData!['startedAt'] as num).toInt()))),
        if (progressData?['finishedAt'] is num)
          _chip(Icons.check_circle_outline_rounded, l.finishedDate(_fmtDate((progressData!['finishedAt'] as num).toInt()))),
      ]),
      if (seriesEntries.isNotEmpty) ...[const SizedBox(height: 16),
        ...seriesEntries.map((s) {
          final name = s['name'] as String? ?? '';
          final seq = s['sequence'] as String? ?? '';
          final seriesId = s['id'] as String?;
          return Padding(padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () => _openSeries(context, seriesId, name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  Icon(Icons.auto_stories_rounded, size: 16, color: accent.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$name${seq.isNotEmpty ? ' #$seq' : ''}',
                    style: tt.bodySmall?.copyWith(color: accent.withValues(alpha: 0.9), fontWeight: FontWeight.w500))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: accent.withValues(alpha: 0.5)),
                ]),
              ),
            ));
        })],
      if (descRaw.isNotEmpty) ...[const SizedBox(height: 16),
        Text(l.aboutSection, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        HtmlDescription(
          html: descRaw,
          maxLines: 6,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.7), height: 1.5),
          linkColor: accent,
        )],
      if (chapters.isNotEmpty) ...[const SizedBox(height: 16),
        GestureDetector(onTap: () => setState(() => _chaptersExpanded = !_chaptersExpanded),
          child: Row(children: [
            Text(l.chaptersCount(chapters.length), style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const Spacer(), Icon(_chaptersExpanded ? Icons.expand_less : Icons.expand_more, color: cs.onSurface.withValues(alpha: 0.3), size: 20)])),
        if (_chaptersExpanded) ...[const SizedBox(height: 8),
          ...chapters.asMap().entries.map((e) {
            final ch = e.value as Map<String, dynamic>;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 28, child: Text('${e.key + 1}', style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)))),
                Expanded(child: Text(ch['title'] as String? ?? l.chapterNumber(e.key + 1), maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)))),
                Text(formatHm(((ch['end'] as num?)?.toDouble() ?? 0) - ((ch['start'] as num?)?.toDouble() ?? 0)), style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3))),
              ]));
          })]],
      if (_bookmarks.isNotEmpty) ...[const SizedBox(height: 16),
        GestureDetector(onTap: () => setState(() => _bookmarksExpanded = !_bookmarksExpanded),
          child: Row(children: [
            Text(l.bookmarksWithCount(_bookmarks.length), style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const Spacer(), Icon(_bookmarksExpanded ? Icons.expand_less : Icons.expand_more, color: cs.onSurface.withValues(alpha: 0.3), size: 20)])),
        if (_bookmarksExpanded) ...[const SizedBox(height: 8),
          ..._bookmarks.map((bm) {
            final hasNote = bm.note != null && bm.note!.isNotEmpty;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 56, child: Text(bm.formattedPosition, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)))),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(bm.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                  if (hasNote)
                    Text(bm.note!, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.35))),
                ])),
              ]));
          })]],
      if (audioFiles.isNotEmpty) ...[const SizedBox(height: 16),
        GestureDetector(onTap: () => setState(() => _tracksExpanded = !_tracksExpanded),
          child: Row(children: [
            Text(l.audioTracksCount(audioFiles.length), style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const Spacer(), Icon(_tracksExpanded ? Icons.expand_less : Icons.expand_more, color: cs.onSurface.withValues(alpha: 0.3), size: 20)])),
        if (_tracksExpanded) ...[const SizedBox(height: 8),
          ...audioFiles.asMap().entries.map((e) {
            final af = e.value as Map<String, dynamic>;
            final afMeta = af['metadata'] as Map<String, dynamic>? ?? {};
            final trackDuration = (af['duration'] as num?)?.toDouble() ?? 0;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 28, child: Text('${(af['index'] as num?)?.toInt() ?? e.key + 1}', style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)))),
                Expanded(child: Text(afMeta['filename'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)))),
                if (trackDuration > 0)
                  Text(formatHm(trackDuration), style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3))),
              ]));
          })]],
      if (libraryFiles.isNotEmpty) ...[const SizedBox(height: 16),
        GestureDetector(onTap: () => setState(() => _filesExpanded = !_filesExpanded),
          child: Row(children: [
            Text(l.libraryFilesCount(libraryFiles.length), style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const Spacer(), Icon(_filesExpanded ? Icons.expand_less : Icons.expand_more, color: cs.onSurface.withValues(alpha: 0.3), size: 20)])),
        if (_filesExpanded) ...[const SizedBox(height: 8),
          ...libraryFiles.map((f) {
            final lf = f as Map<String, dynamic>;
            final lfMeta = lf['metadata'] as Map<String, dynamic>? ?? {};
            final size = (lfMeta['size'] as num?)?.toInt() ?? 0;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lfMeta['relPath'] as String? ?? lfMeta['filename'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                  if ((lf['fileType'] as String?)?.isNotEmpty ?? false)
                    Text(lf['fileType'] as String, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.35))),
                ])),
                if (size > 0) ...[const SizedBox(width: 8),
                  Text(_fmtSize(size), style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)))],
              ]));
          })]],
    ]);
  }

  // ─── QUICK ACTIONS (long-press) ─────────────────────────────
  // Compact long-press layout: cover + title, an Absorb/Download grid, then
  // the same actions as the detail sheet's "more" menu rendered as pills.
  // Actions run on this (live) sheet context just like the detail sheet, so we
  // never pop-then-touch a defunct context; navigation actions dismiss us.
  Widget _buildQuickContent(BuildContext context, ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final accent = _coverScheme?.primary ?? cs.primary;
    final onAccent = _coverScheme?.onPrimary ?? cs.onPrimary;
    final media = _item!['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final chapters = media['chapters'] as List<dynamic>? ?? [];
    final title = metadata['title'] as String? ?? l.unknown;
    final authorName = metadata['authorName'] as String? ?? '';
    final duration = (media['duration'] as num?)?.toDouble() ?? 0;
    final serverPath = _item!['path'] as String? ?? _item!['relPath'] as String? ?? '';
    final ebookFile = resolveEbookFile(_item);
    final isEbookOnly = PlayerSettings.isEbookOnly(_item!);

    final lib = context.watch<LibraryProvider>();
    final auth = context.read<AuthProvider>();
    final progress = lib.getProgress(widget.itemId);
    final progressData = lib.getProgressData(widget.itemId);
    final isFinished = progressData?['isFinished'] == true;
    final currentTime = (progressData?['currentTime'] as num?)?.toDouble() ?? 0;

    // Continue-shelf actions (mirror the detail sheet's more menu).
    final inContinueListening = lib.isInContinueListeningShelf(widget.itemId);
    final rawSeries = ((_item?['media'] as Map<String, dynamic>?)?['metadata']
        as Map<String, dynamic>?)?['series'];
    final bookSeriesIds = <String>[];
    if (rawSeries is List) {
      for (final s in rawSeries.whereType<Map<String, dynamic>>()) {
        final id = (s['id'] as String? ?? '').trim();
        if (id.isNotEmpty) bookSeriesIds.add(id);
      }
    } else if (rawSeries is Map<String, dynamic>) {
      final id = (rawSeries['id'] as String? ?? '').trim();
      if (id.isNotEmpty) bookSeriesIds.add(id);
    }
    final continueSeriesId = lib.continueSeriesShelfMatch(bookSeriesIds);

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).viewPadding.bottom),
      children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
        // Header: cover thumb + title/author
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _quickThumb(56, lib.mediaHeaders, cs),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
            if (authorName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(authorName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ])),
        ]),
        const SizedBox(height: 18),
        // Primary actions: Absorb | Download side by side
        if (!isEbookOnly)
          Row(children: [
            Expanded(child: _quickAbsorbButton(context, cs, tt, auth, accent, onAccent, title, authorName, duration, chapters, isFinished)),
            const SizedBox(width: 10),
            Expanded(child: DownloadWideButton(itemId: widget.itemId, coverUrl: _coverUrl, title: title, author: authorName, accent: accent)),
          ])
        else
          SizedBox(height: 44, child: Center(child: Text(l.ebookOnlyNoAudio,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 10),
        // Mark finished toggle
        _quickFinishedPill(context, cs, auth, isFinished, currentTime, duration),
        const SizedBox(height: 18),
        // Secondary actions as the shared responsive pill grid. The quick sheet
        // stays open behind navigation actions, so dismiss is a no-op here.
        _actionPillGrid(context, cs, tt, l, auth, lib, title, authorName, progress,
          isFinished, duration, ebookFile, isEbookOnly, serverPath, inContinueListening,
          continueSeriesId, dismiss: () {}, includeOpenDetails: true),
      ],
    );
  }

  /// The book's secondary actions as a responsive pill grid (admin-Users-page
  /// style). Shared by the long-press quick sheet and the detail sheet's
  /// overflow menu. [dismiss] closes the surrounding sheet before an action
  /// runs (the overflow menu pops itself; the quick sheet passes a no-op and
  /// stays open). [includeOpenDetails] adds a "Book Details" pill (quick sheet
  /// only — pointless when you're already in the detail sheet).
  Widget _actionPillGrid(BuildContext context, ColorScheme cs, TextTheme tt, AppLocalizations l,
      AuthProvider auth, LibraryProvider lib, String title, String authorName, double progress,
      bool isFinished, double duration, Map<String, dynamic>? ebookFile, bool isEbookOnly,
      String serverPath, bool inContinueListening, String? continueSeriesId,
      {required VoidCallback dismiss, bool includeOpenDetails = false}) {
    final onAbsorbing = lib.isOnAbsorbingList(widget.itemId);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      LayoutBuilder(builder: (ctx, constraints) {
        const gap = 10.0;
        // Responsive grid: 3 pills across normally, but drop to 2 on a narrow
        // screen or when the system font is scaled up, so labels keep room to
        // show in full. Cell height tracks the text scale so 2-line labels at a
        // large zoom don't get clipped.
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final cols = (constraints.maxWidth < 340 || textScale >= 1.3) ? 2 : 3;
        final cellW = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final cellH = (cols == 2 ? 72.0 : 80.0) * textScale.clamp(1.0, 1.7) + 8;
        final pills = <Widget>[];
        void add(IconData icon, String label, VoidCallback onTap, {Color? tint}) {
          pills.add(SizedBox(width: cellW, height: cellH,
            child: _quickPill(cs, tt, icon, label, () { dismiss(); onTap(); }, tint: tint)));
        }
        add(onAbsorbing ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
          onAbsorbing ? Wording.of(context).removeFromAbsorbing : Wording.of(context).addToAbsorbing, () async {
            if (onAbsorbing) {
              await lib.removeFromAbsorbing(widget.itemId);
              HapticFeedback.mediumImpact();
              if (context.mounted) showOverlayToast(context, Wording.of(context).removedFromAbsorbing, icon: Icons.remove_circle_outline_rounded);
            } else {
              await lib.addToAbsorbingQueue(widget.itemId);
              if (_item != null) {
                final cached = Map<String, dynamic>.from(_item!);
                cached['_absorbingKey'] = widget.itemId;
                lib.absorbingItemCache[widget.itemId] = cached;
              }
              HapticFeedback.mediumImpact();
              if (context.mounted) showOverlayToast(context, Wording.of(context).addedToAbsorbing, icon: Icons.add_circle_outline_rounded);
            }
          });
        if (!lib.isOffline) {
          add(Icons.playlist_add_rounded, l.addToPlaylist, () => PlaylistPickerSheet.show(context, widget.itemId));
        }
        if (!includeOpenDetails && !lib.isOffline) {
          add(
            Icons.history_rounded,
            l.historyServerTab,
            () => showPlaybackHistorySheet(
              context,
              itemId: widget.itemId,
              initialTab: PlaybackHistoryTab.sessions,
              accent: _coverScheme?.primary ?? cs.primary,
            ),
          );
        }
        if (!lib.isOffline && !lib.isPodcastLibrary && auth.isAdmin) {
          add(Icons.collections_bookmark_rounded, l.addToCollection, () => CollectionPickerSheet.show(context, widget.itemId));
        }
        if (ebookFile != null && canReadEbook(ebookFile)) {
          add(Icons.menu_book_rounded, l.readEbook, () => _openEbookReader(context, auth, ebookFile, title));
        }
        if (ebookFile != null) {
          add(_ebookSaved ? Icons.download_done_rounded : Icons.save_alt_rounded,
            l.ebookSaveToDevice, () => _saveEbook(context, auth, ebookFile, title));
        }
        if (ebookFile != null && auth.ereaderDevices.isNotEmpty) {
          add(Icons.send_to_mobile_rounded, l.sendToEreader, () => _sendToEreader(context, auth));
        }
        if (progress > 0 || isFinished) {
          add(Icons.restart_alt_rounded, l.resetProgress, () => _resetProgress(context, auth, duration));
        }
        if (inContinueListening && !lib.isOffline) {
          add(Icons.playlist_remove_rounded, l.removeFromContinueListening, () => _removeFromContinueListening(context, auth, lib));
        }
        if (continueSeriesId != null && !lib.isOffline) {
          add(Icons.bookmark_remove_rounded, l.removeSeriesFromContinueSeries, () => _removeSeriesFromContinueSeries(context, auth, lib, continueSeriesId));
        }
        if (auth.apiService != null && !lib.isOffline) {
          add(Icons.manage_search_rounded, _hasLocalOverride ? l.reLookupLocalMetadata : l.lookupLocalMetadata,
            () => _openMetadataLookup(context, auth, title, authorName));
        }
        if (_hasLocalOverride) {
          add(Icons.layers_clear_rounded, l.clearLocalMetadata, () => _clearOverride(context));
        }
        if (_showGoodreads) {
          add(Icons.local_library_rounded, l.searchOnGoodreads, () => _openGoodreads(title, authorName));
        }
        if (auth.canUpdateMetadata && !lib.isOffline) {
          add(Icons.edit_rounded, l.edit, () => _openEditPage(auth, title, isEbookOnly));
        }
        if (includeOpenDetails) {
          add(Icons.open_in_full_rounded, l.bookDetailsLabel, () {
            final rc = rootNavigatorKey.currentContext;
            Navigator.of(context).pop();
            if (rc != null) showBookDetailSheet(rc, widget.itemId);
          });
        }
        // The full item (with ebookFile) loads after the sheet is already open,
        // which inserts the eBook pills mid-grid. Animate the size change so they
        // ease in instead of snapping the layout.
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Wrap(spacing: gap, runSpacing: gap, children: pills),
        );
      }),
      if (auth.isAdmin && serverPath.isNotEmpty) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            dismiss();
            Clipboard.setData(ClipboardData(text: serverPath));
            HapticFeedback.lightImpact();
          },
          child: Text(serverPath, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.25), fontSize: 11)),
        ),
      ],
    ]);
  }

  Widget _quickThumb(double size, Map<String, String> headers, ColorScheme cs) {
    final url = _coverUrl;
    Widget img;
    if (url == null) {
      img = Container(color: cs.surfaceContainerHighest,
        child: Icon(Icons.headphones_rounded, size: 24, color: cs.onSurfaceVariant.withValues(alpha: 0.4)));
    } else if (url.startsWith('/')) {
      img = Image.file(File(url), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: cs.surfaceContainerHighest));
    } else {
      img = CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, httpHeaders: headers,
        placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
        errorWidget: (_, __, ___) => Container(color: cs.surfaceContainerHighest));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: size, height: size, child: img));
  }

  Widget _quickAbsorbButton(BuildContext context, ColorScheme cs, TextTheme tt, AuthProvider auth,
      Color accent, Color onAccent, String title, String author, double duration, List<dynamic> chapters, bool isFinished) {
    return ListenableBuilder(
      listenable: AudioPlayerService(),
      builder: (_, __) {
        final player = AudioPlayerService();
        final isCurrentPlaying = player.currentItemId == widget.itemId && player.isPlaying;
        final showAbsorbingState = _isAbsorbing || isCurrentPlaying;
        return GestureDetector(
          onTap: showAbsorbingState
              ? () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  AppShell.goToAbsorbingGlobal();
                }
              : () {
                  setState(() => _isAbsorbing = true);
                  _startAbsorb(context, auth: auth, title: title, author: author,
                    coverUrl: _coverUrl, duration: duration, chapters: chapters);
                },
          child: Container(
            height: 36,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              showAbsorbingState
                  ? SizedBox(width: 16, height: 16, child: AbsorbingWave(color: onAccent))
                  : isFinished
                      ? AbsorbReplayIcon(size: 16, color: onAccent)
                      : Icon(Icons.waves_rounded, size: 16, color: onAccent),
              const SizedBox(width: 8),
              Flexible(child: Text(
                showAbsorbingState
                    ? Wording.of(context).absorbing
                    : isFinished
                        ? Wording.of(context).absorbAgain
                        : Wording.of(context).absorb,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onAccent),
              )),
            ]),
          ),
        );
      },
    );
  }

  Widget _quickFinishedPill(BuildContext context, ColorScheme cs, AuthProvider auth,
      bool isFinished, double currentTime, double duration) {
    return GestureDetector(
      onTap: () => isFinished
          ? _markNotFinished(context, auth, currentTime, duration)
          : _markFinished(context, auth, duration),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isFinished ? Colors.green.withValues(alpha: 0.06) : cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isFinished ? Colors.green.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isFinished ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
            size: 16, color: isFinished ? Colors.green : cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(child: Text(isFinished ? Wording.of(context).fullyAbsorbed : Wording.of(context).fullyAbsorbAction,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isFinished ? Colors.green : cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      ),
    );
  }

  // Grid pill styled like the admin Users page cells: rounded card, centered
  // icon over a short label, fixed height so the Wrap rows line up.
  Widget _quickPill(ColorScheme cs, TextTheme tt, IconData icon, String label, VoidCallback onTap, {Color? tint}) {
    final iconColor = tint ?? cs.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 7),
          // Loose Flexible so an extra-long label ellipsises inside the cell at
          // big font scales rather than overflowing the fixed cell height.
          Flexible(child: Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w500, height: 1.15, fontSize: 11))),
        ]),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, AuthProvider auth, LibraryProvider lib,
      String title, String authorName, double progress, bool isFinished,
      double duration, Map<String, dynamic>? ebookFile, bool isEbookOnly, String serverPath) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    // Continue-shelf actions only make sense when this book is actually shown
    // in the relevant home shelf right now.
    final inContinueListening = lib.isInContinueListeningShelf(widget.itemId);
    final rawSeries = ((_item?['media'] as Map<String, dynamic>?)?['metadata']
        as Map<String, dynamic>?)?['series'];
    final bookSeriesIds = <String>[];
    if (rawSeries is List) {
      for (final s in rawSeries.whereType<Map<String, dynamic>>()) {
        final id = (s['id'] as String? ?? '').trim();
        if (id.isNotEmpty) bookSeriesIds.add(id);
      }
    } else if (rawSeries is Map<String, dynamic>) {
      final id = (rawSeries['id'] as String? ?? '').trim();
      if (id.isNotEmpty) bookSeriesIds.add(id);
    }
    final continueSeriesId = lib.continueSeriesShelfMatch(bookSeriesIds);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              Flexible(
                child: SingleChildScrollView(
                  child: _actionPillGrid(context, cs, tt, l, auth, lib, title, authorName,
                    progress, isFinished, duration, ebookFile, isEbookOnly, serverPath,
                    inContinueListening, continueSeriesId, dismiss: () => Navigator.pop(ctx)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _removeFromContinueListening(
      BuildContext context, AuthProvider auth, LibraryProvider lib) async {
    final l = AppLocalizations.of(context)!;
    final api = auth.apiService;
    final progressId = lib.getProgressData(widget.itemId)?['id'] as String?;
    if (api == null || progressId == null) {
      if (context.mounted) {
        showOverlayToast(context, l.couldNotUpdate, icon: Icons.error_outline_rounded);
      }
      return;
    }
    final ok = await api.removeItemFromContinueListening(progressId);
    if (ok) {
      await lib.refreshProgressShelves(force: true, reason: 'remove-continue-listening');
    }
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    showOverlayToast(context,
        ok ? l.removedFromContinueListening : l.couldNotUpdate,
        icon: ok ? Icons.playlist_remove_rounded : Icons.error_outline_rounded);
  }

  Future<void> _removeSeriesFromContinueSeries(
      BuildContext context, AuthProvider auth, LibraryProvider lib, String seriesId) async {
    final l = AppLocalizations.of(context)!;
    final api = auth.apiService;
    if (api == null) {
      if (context.mounted) {
        showOverlayToast(context, l.couldNotUpdate, icon: Icons.error_outline_rounded);
      }
      return;
    }
    final ok = await api.removeSeriesFromContinueListening(seriesId);
    if (ok) {
      await lib.refreshProgressShelves(force: true, reason: 'remove-continue-series');
    }
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    showOverlayToast(context,
        ok ? l.removedSeriesFromContinueSeries : l.couldNotUpdate,
        icon: ok ? Icons.bookmark_remove_rounded : Icons.error_outline_rounded);
  }

  /// Opens the unified per-book edit page (Chapters / Details / Match / Encode)
  /// from the "..." menu.
  void _openEditPage(AuthProvider auth, String title, bool isEbookOnly) {
    final media = _item!['media'] as Map<String, dynamic>? ?? {};
    final meta = media['metadata'] as Map<String, dynamic>? ?? {};
    final mediaTags = ((media['tags'] as List<dynamic>?) ?? const []).cast<String>();
    final audioFiles = (media['audioFiles'] as List<dynamic>?) ?? const [];
    final rel = _item!['relPath'] as String? ?? '';
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => BookEditScreen(
        itemId: widget.itemId,
        bookTitle: title,
        metadata: meta,
        tags: mediaTags,
        audioFiles: audioFiles,
        relPath: rel,
        isEbookOnly: isEbookOnly,
        isAdmin: auth.isAdmin,
        libraryId: _item!['libraryId'] as String?,
      ),
    ));
  }

  List<Widget> _audioInfoChips(Map<String, dynamic> media) {
    final audioFiles = media['audioFiles'] as List<dynamic>?;
    if (audioFiles == null || audioFiles.isEmpty) return [];
    final first = audioFiles.first as Map<String, dynamic>;
    final codec = (first['codec'] as String?)?.toUpperCase();
    final bitRate = (first['bitRate'] as num?)?.toInt();
    // Sum size across all audio files
    int totalSize = 0;
    for (final af in audioFiles) {
      if (af is Map<String, dynamic>) {
        final meta = af['metadata'] as Map<String, dynamic>?;
        totalSize += (meta?['size'] as num?)?.toInt() ?? 0;
      }
    }
    final l = AppLocalizations.of(context)!;
    return [
      if (codec != null && codec.isNotEmpty) _chip(Icons.audio_file_rounded, codec),
      if (bitRate != null && bitRate > 0) _chip(Icons.speed_rounded, l.kbpsValue((bitRate / 1000).round())),
      if (totalSize > 0) _chip(Icons.storage_rounded, _fmtSize(totalSize)),
    ];
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).round()} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  Widget _chip(IconData icon, String text, {VoidCallback? onTap}) {
    final cs = Theme.of(context).colorScheme;
    final pill = Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onTap != null
            ? cs.tertiary.withValues(alpha: 0.10)
            : cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: onTap != null
              ? cs.tertiary.withValues(alpha: 0.30)
              : cs.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 12,
            color: onTap != null
                ? cs.tertiary
                : cs.onSurface.withValues(alpha: 0.3)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  color: onTap != null ? cs.tertiary : cs.onSurfaceVariant,
                  fontSize: 11)),
        ),
      ]),
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }


  List<Widget> _buildStars(double rating, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final stars = <Widget>[];
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.4;
    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star_rounded, size: 16, color: accent));
      } else if (i == fullStars && hasHalf) {
        stars.add(Icon(Icons.star_half_rounded, size: 16, color: accent));
      } else {
        stars.add(Icon(Icons.star_outline_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.24)));
      }
    }
    return stars;
  }

  static String get _audibleDomain {
    final code = (ui.PlatformDispatcher.instance.locale.countryCode ?? 'US').toUpperCase();
    const domains = {
      'US': 'audible.com',
      'GB': 'audible.co.uk',
      'AU': 'audible.com.au',
      'CA': 'audible.ca',
      'DE': 'audible.de',
      'FR': 'audible.fr',
      'IT': 'audible.it',
      'ES': 'audible.es',
      'JP': 'audible.co.jp',
      'IN': 'audible.in',
      'BR': 'audible.com.br',
    };
    return domains[code] ?? 'audible.com';
  }

  void _showAudibleReviews(BuildContext context) {
    final asin = _asin;
    if (asin == null) return;
    final url = 'https://www.$_audibleDomain/pd/$asin#customer-reviews';
    final cs = Theme.of(context).colorScheme;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(cs.surface)
      ..loadRequest(Uri.parse(url));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 32, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(2))),
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SizedBox.expand(
                child: WebViewWidget(
                  controller: controller,
                  gestureRecognizers: {
                    Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                    ),
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAuthorLinks(BuildContext context, Map<String, dynamic> metadata, ColorScheme cs, TextTheme tt, Color accent) {
    final authors = metadata['authors'] as List<dynamic>? ?? [];
    // Fall back to authorName string if no structured authors array
    if (authors.isEmpty) {
      final name = metadata['authorName'] as String? ?? '';
      if (name.isEmpty) return const SizedBox.shrink();
      return Text(name, textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant));
    }

    const int collapsedCount = 3;
    final showAll = _authorsExpanded || authors.length <= collapsedCount;
    final visible = showAll ? authors : authors.sublist(0, collapsedCount);
    final remaining = authors.length - collapsedCount;

    final linkStyle = tt.bodyMedium?.copyWith(
      color: accent,
      decoration: TextDecoration.underline,
      decorationColor: accent.withValues(alpha: 0.4),
    );
    final commaStyle = tt.bodyMedium?.copyWith(color: accent);

    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          GestureDetector(
            onTap: () {
              final a = visible[i] as Map<String, dynamic>? ?? {};
              final id = a['id'] as String? ?? '';
              final name = a['name'] as String? ?? '';
              if (id.isEmpty || name.isEmpty) return;
              showAuthorDetailSheet(context, authorId: id, authorName: name);
            },
            child: Text(
              (visible[i] as Map<String, dynamic>?)?['name'] as String? ?? '',
              style: linkStyle,
            ),
          ),
          if (i < visible.length - 1 || (!showAll && remaining > 0))
            Text(', ', style: commaStyle),
        ],
        if (!showAll)
          GestureDetector(
            onTap: () => setState(() => _authorsExpanded = true),
            child: Text(AppLocalizations.of(context)!.andCountMore(remaining), style: tt.bodyMedium?.copyWith(
              color: accent.withValues(alpha: 0.7),
            )),
          ),
      ],
    );
  }

  Widget _buildNarratorLinks(BuildContext context, Map<String, dynamic> metadata, ColorScheme cs, TextTheme tt, Color accent) {
    final raw = metadata['narrators'] as List<dynamic>? ?? [];
    final names = <String>[
      for (final n in raw)
        if (n is String && n.trim().isNotEmpty)
          n.trim()
        else if (n is Map<String, dynamic>)
          (n['name'] as String? ?? '').trim()
    ].where((s) => s.isNotEmpty).toList();

    if (names.isEmpty) {
      final fallback = (metadata['narratorName'] as String? ?? '').trim();
      if (fallback.isEmpty) return const SizedBox.shrink();
      names.addAll(fallback.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
    if (names.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    // Split the localized "Narrated by {narrator}" template so we can prepend
    // the prefix (and append any suffix, e.g. Chinese colon) around clickable
    // narrator links.
    final parts = l.narratedBy('||X||').split('||X||');
    final prefix = parts.isNotEmpty ? parts[0] : '';
    final suffix = parts.length > 1 ? parts[1] : '';

    const int collapsedCount = 3;
    final showAll = _narratorsExpanded || names.length <= collapsedCount;
    final visible = showAll ? names : names.sublist(0, collapsedCount);
    final remaining = names.length - collapsedCount;

    final baseStyle = tt.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final linkStyle = tt.bodySmall?.copyWith(
      color: accent,
      decoration: TextDecoration.underline,
      decorationColor: accent.withValues(alpha: 0.4),
    );
    final commaStyle = tt.bodySmall?.copyWith(color: accent);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          if (prefix.isNotEmpty) Text(prefix, style: baseStyle),
          for (int i = 0; i < visible.length; i++) ...[
            GestureDetector(
              onTap: () => showNarratorBooksSheet(context, narratorName: visible[i]),
              child: Text(visible[i], style: linkStyle),
            ),
            if (i < visible.length - 1 || (!showAll && remaining > 0))
              Text(', ', style: commaStyle),
          ],
          if (!showAll)
            GestureDetector(
              onTap: () => setState(() => _narratorsExpanded = true),
              child: Text(l.andCountMore(remaining), style: tt.bodySmall?.copyWith(
                color: accent.withValues(alpha: 0.7),
              )),
            ),
          if (suffix.isNotEmpty) Text(suffix, style: baseStyle),
        ],
      ),
    );
  }

  Future<void> _openSeries(BuildContext context, String? seriesId, String seriesName) async {
    if (seriesId == null) return;
    final auth = context.read<AuthProvider>();
    final itemLibraryId = _item?['libraryId'] as String?;
    showSeriesBooksSheet(
      context,
      seriesName: seriesName,
      seriesId: seriesId,
      serverUrl: auth.serverUrl,
      token: auth.token,
      libraryId: itemLibraryId,
    );
  }

  void _openEbookReader(BuildContext context, AuthProvider auth, Map<String, dynamic> ebookFile, String title) {
    openEbookReader(context, itemId: widget.itemId, title: title, ebookFile: ebookFile);
  }

  /// Caches the ebook for offline reading and registers it as a download so it
  /// shows in the offline library and its detail sheet loads offline. Distinct
  /// from "Save to device", which exports a copy elsewhere.
  Future<void> _downloadEbookOffline(
      BuildContext context, AuthProvider auth, Map<String, dynamic> ebookFile, String title) async {
    if (_ebookOfflineDownloading) return;
    final l = AppLocalizations.of(context)!;
    final api = auth.apiService;
    if (api == null) return;
    setState(() => _ebookOfflineDownloading = true);
    try {
      await fetchEbookToCache(api, widget.itemId, ebookFile, title);
      await DownloadService().registerEbookDownload(
        api: api,
        itemId: widget.itemId,
        item: _item,
        libraryId: _item?['libraryId'] as String?,
      );
      if (mounted) {
        setState(() => _ebookOfflineDownloading = false);
        showOverlayToast(context, l.ebookSavedOffline, icon: Icons.download_done_rounded);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _ebookOfflineDownloading = false);
        showOverlayToast(context, l.ebookOfflineFailed, icon: Icons.error_outline_rounded);
      }
    }
  }

  Future<void> _removeEbookOffline(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    await DownloadService().deleteDownload(widget.itemId);
    if (mounted) showOverlayToast(context, l.ebookRemovedOffline, icon: Icons.delete_outline_rounded);
  }

  bool _ebookSaving = false;

  Future<void> _saveEbook(BuildContext context, AuthProvider auth, Map<String, dynamic> ebookFile, String bookTitle) async {
    if (_ebookSaving) return;
    final l = AppLocalizations.of(context)!;

    // Clarify this exports a copy elsewhere on the device and is NOT the same as
    // the offline Download, which is a common point of confusion.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.ebookSaveToDeviceTitle),
        content: Text(l.ebookSaveToDeviceBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.ebookSaveToDevice)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _ebookSaving = true);

    try {
      final api = auth.apiService;
      if (api == null) return;

      final ino = ebookFile['ino'] as String?;
      if (ino == null) {
        if (mounted) {
          showOverlayToast(
            context,
            l.noEbookFileFound,
            icon: Icons.error_outline_rounded,
          );
        }
        return;
      }

      final ebookName = ebookFile['metadata']?['filename'] as String? ?? ebookFile['name'] as String? ?? 'book.epub';
      final ext = ebookName.contains('.') ? ebookName.substring(ebookName.lastIndexOf('.')) : '.epub';
      final safeTitle = bookTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim();

      // Download to cache first (reuse if already cached)
      final cacheDir = await getTemporaryDirectory();
      final cachedFile = File('${cacheDir.path}/$safeTitle$ext');

      if (!cachedFile.existsSync()) {
        final cleanBase = api.baseUrl.endsWith('/') ? api.baseUrl.substring(0, api.baseUrl.length - 1) : api.baseUrl;
        final url = '$cleanBase/api/items/${widget.itemId}/file/$ino';

        // Use streamed download with proper headers (including custom
        // reverse-proxy headers) and manual redirect following so auth
        // headers are preserved across redirects.
        final request = http.Request('GET', Uri.parse(url));
        request.followRedirects = false;
        api.mediaHeaders.forEach((k, v) => request.headers[k] = v);
        final client = http.Client();
        try {
          var response = await client.send(request);

          // Manually follow redirects while preserving auth headers
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
            if (mounted) {
              showOverlayToast(
                context,
                l.failedToDownloadEbook(response.statusCode),
                icon: Icons.error_outline_rounded,
              );
            }
            return;
          }

          // Sanity-check: if the server returned HTML instead of a binary
          // file, the download is likely an error/login page.
          final ct = response.headers['content-type'] ?? '';
          if (ct.contains('text/html')) {
            debugPrint('[Ebook] Server returned HTML instead of ebook file (content-type: $ct)');
            if (mounted) {
              showOverlayToast(
                context,
                l.serverReturnedErrorPage,
                icon: Icons.error_outline_rounded,
              );
            }
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

      final bytes = await cachedFile.readAsBytes();

      // Open system save dialog so user can choose the location
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: l.saveEbook,
        fileName: '$safeTitle$ext',
        bytes: Uint8List.fromList(bytes),
      );

      if (savedPath == null) return; // user cancelled

      // Track that this ebook has been saved
      final saved = await ScopedPrefs.getStringList('saved_ebooks');
      if (!saved.contains(widget.itemId)) {
        saved.add(widget.itemId);
        await ScopedPrefs.setStringList('saved_ebooks', saved);
      }
      if (mounted) setState(() => _ebookSaved = true);

      if (mounted) {
        showOverlayToast(
          context,
          l.ebookSaved('$safeTitle$ext'),
          icon: Icons.download_done_rounded,
        );
      }
    } catch (e) {
      debugPrint('[Ebook] Save error: $e');
      if (mounted) {
        showOverlayToast(
          context,
          l.errorSavingEbook(e.toString()),
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _ebookSaving = false);
    }
  }

  Future<void> _sendToEreader(BuildContext context, AuthProvider auth) async {
    final api = auth.apiService;
    final devices = auth.ereaderDevices;
    if (api == null || devices.isEmpty) return;
    final l = AppLocalizations.of(context)!;

    String? deviceName;
    if (devices.length == 1) {
      deviceName = devices.first['name'] as String?;
    } else {
      deviceName = await _pickEreaderDevice(context, devices);
    }
    if (deviceName == null || !context.mounted) return;

    showOverlayToast(context, l.sendingToEreader(deviceName),
        icon: Icons.send_to_mobile_rounded);

    final ok = await api.sendEBookToDevice(
      libraryItemId: widget.itemId,
      deviceName: deviceName,
    );
    if (!context.mounted) return;
    if (ok) {
      showOverlayToast(context, l.sendToEreaderSuccess(deviceName),
          icon: Icons.check_circle_outline_rounded);
    } else {
      showOverlayToast(context, l.sendToEreaderFailed,
          icon: Icons.error_outline_rounded);
    }
  }

  Future<String?> _pickEreaderDevice(
      BuildContext context, List<Map<String, dynamic>> devices) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
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
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l.pickEreaderDevice,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: devices.map((d) {
                    final name = d['name'] as String? ?? '';
                    final email = d['email'] as String? ?? '';
                    return ListTile(
                      leading: Icon(Icons.send_to_mobile_rounded, color: cs.onSurfaceVariant),
                      title: Text(name),
                      subtitle: Text(email, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                      onTap: () => Navigator.pop(ctx, name),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  /// Where a preview should start. Front matter (credits, dedication, intro)
  /// is always short, so the first chapter long enough to be real prose is the
  /// sample point - capped to the first 10% of the book so a preview can never
  /// spoil. Books without a usable chapter land shortly past the credits.
  double _previewStartSeconds(List<dynamic> chapters, double duration) {
    const minRealChapter = 300.0;
    const fallback = 90.0;
    final clampedFallback = duration * 0.25 < fallback ? duration * 0.25 : fallback;
    final spoilerCap = duration * 0.10;
    for (final c in chapters) {
      if (c is! Map<String, dynamic>) continue;
      final start = (c['start'] as num?)?.toDouble() ?? 0;
      final end = (c['end'] as num?)?.toDouble() ?? 0;
      if (end - start >= minRealChapter && start <= spoilerCap) {
        // A qualifying chapter at 0:00 means the credits are baked into it
        // (single-file books) - nudge past them instead.
        return start == 0 ? clampedFallback : start;
      }
    }
    return clampedFallback;
  }

  Future<void> _togglePreview(BuildContext context, List<dynamic> chapters, double duration) async {
    final l = AppLocalizations.of(context)!;
    if (_preview?.isLoading ?? false) return;
    if (_preview?.isPlaying ?? false) {
      await _preview!.stop();
      return;
    }
    _preview ??= BookmarkPreviewPlayer(itemId: widget.itemId, api: context.read<AuthProvider>().apiService)
      ..clipLength = const Duration(minutes: 5)
      ..stopOnClipEnd = true
      ..addListener(_onPreviewChanged);
    final startAt = _previewStartSeconds(chapters, duration);
    debugPrint('[BookDetail] preview start at ${startAt.toStringAsFixed(1)}s of ${duration.toStringAsFixed(0)}s');
    try {
      await _preview!.toggleAt(startAt);
    } catch (e) {
      debugPrint('[BookDetail] preview failed: $e');
      if (mounted) {
        showOverlayToast(context, l.bookmarkPreviewFailed, icon: Icons.error_outline_rounded);
      }
    }
  }

  void _onPreviewChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startAbsorb(BuildContext context, {required AuthProvider auth, required String title, required String author, required String? coverUrl, required double duration, required List<dynamic> chapters}) async {
    // Discard, not stop: we're about to start playback ourselves, so briefly
    // resuming the previous book would just be an audible blip.
    await _preview?.discard();
    final player = AudioPlayerService();
    // Grab the root navigator before we pop the sheet
    final rootNav = Navigator.of(context, rootNavigator: true);

    // Ensure this book is on the absorbing list (clear any manual remove)
    // Clear finished state so the card updates immediately
    if (context.mounted) {
      final lib = context.read<LibraryProvider>();
      lib.addToAbsorbing(widget.itemId);
      if (lib.getProgressData(widget.itemId)?['isFinished'] == true) {
        lib.resetProgressFor(widget.itemId);
      }
    }
    
    if (player.currentItemId == widget.itemId) {
      if (!player.isPlaying) player.play();
      rootNav.popUntil((route) => route.isFirst);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppShell.goToAbsorbingGlobal();
      });
      return;
    }
    final api = auth.apiService;
    if (api == null) return;

    final lib = context.mounted ? context.read<LibraryProvider>() : null;

    // Pop sheets and switch tab BEFORE starting playback. Otherwise the
    // auto-expand triggered by playItem pushes the expanded player on top
    // of the sheet, and the popUntil below kills the expanded player too.
    rootNav.popUntil((route) => route.isFirst);
    AppShell.goToAbsorbingGlobal();

    final error = await player.playItem(api: api, itemId: widget.itemId, title: title, author: author, coverUrl: coverUrl, totalDuration: duration, chapters: chapters, libraryId: _item?['libraryId'] as String?);
    if (error != null) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) showErrorToast(ctx, error);
    }
    lib?.refreshLocalProgress();
    lib?.refresh();
  }

  Future<void> _markFinished(BuildContext context, AuthProvider auth, double duration) async {
    final l = AppLocalizations.of(context)!;
    final w = Wording.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(w.markAsFullyAbsorbedQuestion),
        content: Text(l.markAsFullyAbsorbedContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(w.fullyAbsorbAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = auth.apiService;
    if (api == null) return;
    final player = AudioPlayerService();
    // Mark finished locally first so the card updates immediately
    // when the player stops (which triggers the expanded card to pop)
    if (context.mounted) {
      context.read<LibraryProvider>().markFinishedLocally(widget.itemId, skipRefresh: true, skipAutoAdvance: true);
    }
    if (player.currentItemId == widget.itemId) await player.stopWithoutSaving();
    try {
      await api.markFinished(widget.itemId, duration);
      await ProgressSyncService().deleteLocal(widget.itemId);
      if (context.mounted) {
        final lib = context.read<LibraryProvider>();
        await _loadItem();
        await lib.refresh();
        await lib.removeFromAbsorbing(widget.itemId);
        if (mounted) setState(() {});
        if (context.mounted) {
          showOverlayToast(context, l.markedAsFinishedNiceWork, icon: Icons.check_circle_rounded);
        }
      }
    } catch (_) {
      if (context.mounted) {
        showOverlayToast(context, l.failedToUpdateCheckConnection, icon: Icons.error_outline_rounded);
      }
    }
  }

  Future<void> _markNotFinished(BuildContext context, AuthProvider auth, double currentTime, double duration) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.markAsNotFinishedQuestion),
        content: Text(l.markAsNotFinishedContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.unmark)),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = auth.apiService;
    if (api == null) return;
    try {
      await api.markNotFinished(widget.itemId, currentTime: currentTime, duration: duration);
      await ProgressSyncService().deleteLocal(widget.itemId);
      if (context.mounted) {
        final lib = context.read<LibraryProvider>();
        lib.resetProgressFor(widget.itemId);
        lib.unblockFromAbsorbing(widget.itemId);
        await _loadItem();
        await lib.refresh();
        if (mounted) setState(() {});
        showOverlayToast(context, l.markedAsNotFinishedBackAtIt, icon: Icons.replay_rounded);
      }
    } catch (_) {
      if (context.mounted) {
        showOverlayToast(context, l.failedToUpdateCheckConnection, icon: Icons.error_outline_rounded);
      }
    }
  }

  Future<void> _resetProgress(BuildContext context, AuthProvider auth, double duration) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetProgressQuestion),
        content: Text(l.resetProgressContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l.reset)),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = auth.apiService;
    if (api == null) return;
    final player = AudioPlayerService();
    
    // Stop player without saving progress
    if (player.currentItemId == widget.itemId) {
      await player.stopWithoutSaving();
    }
    
    // Clear local progress
    await ProgressSyncService().deleteLocal(widget.itemId);
    
    // Reset server progress (PATCH to zero + hide from continue listening)
    final serverSuccess = await api.resetProgress(widget.itemId, duration);
    
    // Clear from library provider (mark as reset — forces 0 progress)
    if (context.mounted) context.read<LibraryProvider>().resetProgressFor(widget.itemId);
    if (context.mounted) {
      await _loadItem();
      await context.read<LibraryProvider>().refresh();
      showOverlayToast(
        context,
        serverSuccess ? l.progressResetFreshStart : l.resetMayNotHaveSynced,
        icon: serverSuccess ? Icons.restart_alt_rounded : Icons.warning_amber_rounded,
      );
    }
  }

  void _openGoodreads(String title, String author) async {
    final q = author.isNotEmpty ? '$title $author' : title;
    final uri = Uri.https('www.goodreads.com', '/search', {'q': q});
    try {
      // Open in Goodreads app if installed
      if (!await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // App not installed — fall back to browser
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openMetadataLookup(BuildContext context, AuthProvider auth, String title, String author) {
    final api = auth.apiService;
    if (api == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.05, snap: true,
        maxChildSize: 0.95,
        builder: (ctx, sc) => MetadataLookupSheet(
          scrollController: sc,
          itemId: widget.itemId,
          api: api,
          initialTitle: title,
          initialAuthor: author,
          currentMetadata: (_item?['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?,
          onApplied: () {
            // Reload the item to show the new override, and repaint the
            // library so the grid/absorbing card pick up the override cover.
            _loadItem();
            if (mounted) {
              context.read<LibraryProvider>().notifyCoverOverridesChanged();
            }
          },
        ),
      ),
    );
  }

  Future<void> _clearOverride(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.clearLocalMetadataQuestion),
        content: Text(l.clearLocalMetadataContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.clear)),
        ],
      ),
    );
    if (confirmed != true) return;
    await MetadataOverrideService().delete(widget.itemId);
    if (mounted) {
      setState(() => _hasLocalOverride = false);
      await _loadItem();
      if (context.mounted) {
        // Repaint the library so the grid/card drop the override cover too.
        context.read<LibraryProvider>().notifyCoverOverridesChanged();
        showOverlayToast(
          context,
          l.localMetadataCleared,
          icon: Icons.delete_outline_rounded,
        );
      }
    }
  }

  void _showFullCover(BuildContext context, String url, Map<String, String> headers, String title) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => _FullCoverViewer(url: url, headers: headers, title: title),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }
}

class _FullCoverViewer extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  final String title;
  const _FullCoverViewer({required this.url, required this.headers, required this.title});
  @override State<_FullCoverViewer> createState() => _FullCoverViewerState();
}

class _FullCoverViewerState extends State<_FullCoverViewer> {
  bool _saving = false;

  Future<void> _saveAndShare() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final response = await http.get(Uri.parse(widget.url), headers: widget.headers);
      if (response.statusCode != 200) throw Exception('Download failed');
      final ext = widget.url.contains('.png') ? '.png' : '.jpg';
      final safeTitle = widget.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$safeTitle$ext');
      await file.writeAsBytes(response.bodyBytes);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await Share.shareXFiles([XFile(file.path)], sharePositionOrigin: origin);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        showOverlayToast(
          context,
          l.failedToSaveError(e.toString()),
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        // Dismiss on tap outside image
        GestureDetector(onTap: () => Navigator.pop(context)),
        // Zoomable cover — fills screen so zoomed content can pan freely
        Positioned.fill(
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            minScale: 1.0,
            maxScale: 5.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.url,
                httpHeaders: widget.headers,
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
              ),
            ),
          ),
        ),
        // Close button
        Positioned(
          top: MediaQuery.of(context).viewPadding.top + 8,
          left: 8,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
          ),
        ),
        // Save/share button
        Positioned(
          top: MediaQuery.of(context).viewPadding.top + 8,
          right: 8,
          child: IconButton(
            onPressed: _saving ? null : _saveAndShare,
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_alt_rounded, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
          ),
        ),
      ]),
    );
  }
}

