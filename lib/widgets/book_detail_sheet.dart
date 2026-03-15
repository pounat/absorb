import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import 'card_buttons.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/progress_sync_service.dart';
import '../services/metadata_override_service.dart';
import '../services/scoped_prefs.dart';
import '../screens/app_shell.dart';
import 'author_books_sheet.dart';
import 'series_books_sheet.dart';
import 'absorbing_shared.dart';
import 'html_description.dart';
import 'metadata_lookup_sheet.dart';
import 'playlist_picker_sheet.dart';
import 'collection_picker_sheet.dart';
import 'absorb_wave_icon.dart';
import 'edit_metadata_sheet.dart';
import '../screens/ebook_reader_screen.dart';

// ─── BOOK DETAIL BOTTOM SHEET ───────────────────────────────

void showBookDetailSheet(BuildContext context, String itemId) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.85, minChildSize: 0.05, snap: true, maxChildSize: 0.95,
      builder: (ctx, sc) => _BookDetailSheetContent(itemId: itemId, scrollController: sc),
    ),
  );
}

class _BookDetailSheetContent extends StatefulWidget {
  final String itemId;
  final ScrollController scrollController;
  const _BookDetailSheetContent({required this.itemId, required this.scrollController});
  @override State<_BookDetailSheetContent> createState() => _BookDetailSheetContentState();
}

class _BookDetailSheetContentState extends State<_BookDetailSheetContent> {
  Map<String, dynamic>? _item;
  Map<String, dynamic>? _rating;
  String? _asin;
  bool _isLoading = true;
  bool _chaptersExpanded = false;
  bool _isAbsorbing = false;
  bool _hasLocalOverride = false;
  bool _showGoodreads = false;
  bool _ebookSaved = false;
  bool _authorsExpanded = false;

  @override void initState() {
    super.initState();
    _loadItem();
    PlayerSettings.getShowGoodreadsButton().then((v) { if (mounted) setState(() => _showGoodreads = v); });
    ScopedPrefs.getStringList('saved_ebooks').then((list) {
      if (mounted && list.contains(widget.itemId)) {
        setState(() => _ebookSaved = true);
      }
    });
  }

  Future<void> _loadItem() async {
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;

    // Try server first
    if (api != null && !lib.isOffline) {
      try {
        final item = await api.getLibraryItem(widget.itemId);
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

          // Fetch Audible rating
          final media = finalItem['media'] as Map<String, dynamic>? ?? {};
          final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
          final asin = metadata['asin'] as String?;
          final title = metadata['title'] as String? ?? '';
          final author = metadata['authorName'] as String?;

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
            setState(() {
              _rating = rating;
              _asin = rating?['asin'] as String? ?? asin;
            });
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
      return;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String? get _coverUrl {
    // Check for local override cover first
    final localCover = _item?['_localCoverUrl'] as String?;
    if (localCover != null && localCover.isNotEmpty) return localCover;
    final auth = context.read<AuthProvider>();
    return auth.apiService?.getCoverUrl(widget.itemId, width: 800);
  }

  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Stack(children: [
        if (_coverUrl != null)
          Positioned.fill(
            child: RepaintBoundary(
              child: CachedNetworkImage(
                imageUrl: _coverUrl!, fit: BoxFit.cover,
                httpHeaders: context.read<LibraryProvider>().mediaHeaders,
                imageBuilder: (_, p) => ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50, tileMode: TileMode.decal),
                  child: Image(image: p, fit: BoxFit.cover)),
                placeholder: (_, __) => const SizedBox(),
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6), Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85), Theme.of(context).scaffoldBackgroundColor],
        )))),
        _isLoading
            ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.24)))
            : _item == null
                ? Center(child: Text('Failed to load', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)))
                : AnimatedOpacity(
                    opacity: 1.0, duration: const Duration(milliseconds: 300),
                    child: _buildContent(context, cs, tt)),
      ]),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs, TextTheme tt) {
    final media = _item!['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final chapters = media['chapters'] as List<dynamic>? ?? [];
    final title = metadata['title'] as String? ?? 'Unknown';
    final authorName = metadata['authorName'] as String? ?? '';
    final narrator = metadata['narratorName'] as String? ?? '';
    final descRaw = metadata['description'] as String? ?? '';
    final duration = (media['duration'] as num?)?.toDouble() ?? 0;
    final seriesEntries = metadata['series'] as List<dynamic>? ?? [];
    final genres = (metadata['genres'] as List<dynamic>?)?.cast<String>() ?? [];
    final publisher = metadata['publisher'] as String? ?? '';
    final year = metadata['publishedYear'] as String? ?? '';
    final lib = context.watch<LibraryProvider>();
    final progress = lib.getProgress(widget.itemId);
    final auth = context.read<AuthProvider>();

    final progressData = lib.getProgressData(widget.itemId);
    final isFinished = progressData?['isFinished'] == true;
    final currentTime = (progressData?['currentTime'] as num?)?.toDouble() ?? 0;
    final ebookFile = media['ebookFile'] as Map<String, dynamic>?;

    final isEbookOnly = PlayerSettings.isEbookOnly(_item!);

    return ListView(controller: widget.scrollController, padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + MediaQuery.of(context).viewPadding.bottom), children: [
      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
      Text(title, textAlign: TextAlign.center, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
      const SizedBox(height: 4),
      _buildAuthorLinks(context, metadata, cs, tt),
      if (narrator.isNotEmpty) ...[const SizedBox(height: 2),
        Text('Narrated by $narrator', textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))],
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
                ..._buildStars((_rating!['rating'] as num).toDouble(), cs),
                const SizedBox(width: 6),
                Text((_rating!['rating'] as num).toStringAsFixed(1),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                const SizedBox(width: 4),
                Text('on Audible', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
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
            backgroundColor: cs.onSurface.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(cs.primary))),
        const SizedBox(height: 4),
        Text('${(progress * 100).toStringAsFixed(1)}% complete', textAlign: TextAlign.center,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
      ],
      if (isEbookOnly && ebookFile != null)
        SizedBox(height: 52, child: FilledButton.icon(
          onPressed: () => _openEbookReader(context, auth, ebookFile, title),
          icon: const Icon(Icons.menu_book_rounded, size: 24),
          label: Text('Read',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary)),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ))
      else if (isEbookOnly)
        SizedBox(height: 52, child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.menu_book_rounded, size: 24),
          label: Text('eBook Only - No Audio',
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
                  ? () {}
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
                      child: AbsorbingWave(color: cs.onPrimary),
                    )
                  : isFinished
                      ? AbsorbReplayIcon(size: 24, color: cs.onPrimary)
                      : const Icon(Icons.waves_rounded, size: 24),
              label: Text(
                showAbsorbingState
                    ? 'Absorbing…'
                    : isFinished
                        ? 'Absorb Again'
                        : 'Absorb',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            );
          },
        ),
      ),
      // ─── Action row: Download | Finished | More ─────────────────
      const SizedBox(height: 12),
      Row(children: [
        if (!isEbookOnly) ...[
          Expanded(child: DownloadWideButton(itemId: widget.itemId, coverUrl: _coverUrl, title: title, author: authorName, accent: cs.primary)),
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
                isFinished ? 'Fully Absorbed' : 'Fully Absorb',
                style: TextStyle(
                  color: isFinished ? Colors.green : cs.onSurfaceVariant,
                  fontSize: 12, fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
        )),
        const SizedBox(width: 8),
        // More button - opens styled bottom sheet with secondary actions
        GestureDetector(
          onTap: () => _showMoreSheet(context, auth, lib, title, authorName, progress, isFinished, duration, ebookFile, isEbookOnly),
          child: Container(
            height: 36, width: 44,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.more_horiz_rounded, size: 18, color: cs.onSurfaceVariant),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (year.isNotEmpty) _chip(Icons.calendar_today_rounded, year),
        _chip(Icons.schedule_rounded, _fmtDur(duration)),
        if (chapters.isNotEmpty) _chip(Icons.list_rounded, '${chapters.length} chapters'),
        ..._audioInfoChips(media),
        if (publisher.isNotEmpty) _chip(Icons.business_rounded, publisher),
        ...genres.take(3).map((g) => _chip(Icons.tag_rounded, g)),
        if (progressData?['startedAt'] is num)
          _chip(Icons.play_circle_outline_rounded, 'Started ${_fmtDate((progressData!['startedAt'] as num).toInt())}'),
        if (progressData?['finishedAt'] is num)
          _chip(Icons.check_circle_outline_rounded, 'Finished ${_fmtDate((progressData!['finishedAt'] as num).toInt())}'),
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
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  Icon(Icons.auto_stories_rounded, size: 16, color: cs.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$name${seq.isNotEmpty ? ' #$seq' : ''}',
                    style: tt.bodySmall?.copyWith(color: cs.primary.withValues(alpha: 0.9), fontWeight: FontWeight.w500))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: cs.primary.withValues(alpha: 0.5)),
                ]),
              ),
            ));
        })],
      if (descRaw.isNotEmpty) ...[const SizedBox(height: 16),
        Text('About', style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        HtmlDescription(
          html: descRaw,
          maxLines: 6,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.7), height: 1.5),
          linkColor: cs.primary,
        )],
      if (chapters.isNotEmpty) ...[const SizedBox(height: 16),
        GestureDetector(onTap: () => setState(() => _chaptersExpanded = !_chaptersExpanded),
          child: Row(children: [
            Text('Chapters (${chapters.length})', style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const Spacer(), Icon(_chaptersExpanded ? Icons.expand_less : Icons.expand_more, color: cs.onSurface.withValues(alpha: 0.3), size: 20)])),
        if (_chaptersExpanded) ...[const SizedBox(height: 8),
          ...chapters.asMap().entries.map((e) {
            final ch = e.value as Map<String, dynamic>;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 28, child: Text('${e.key + 1}', style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)))),
                Expanded(child: Text(ch['title'] as String? ?? 'Chapter ${e.key + 1}', maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)))),
                Text(_fmtDur(((ch['end'] as num?)?.toDouble() ?? 0) - ((ch['start'] as num?)?.toDouble() ?? 0)), style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3))),
              ]));
          })]],
      // Secondary actions are in the More sheet now.
    ]);
  }

  void _showMoreSheet(BuildContext context, AuthProvider auth, LibraryProvider lib,
      String title, String authorName, double progress, bool isFinished,
      double duration, Map<String, dynamic>? ebookFile, bool isEbookOnly) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
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
              _moreItem(cs, lib.isOnAbsorbingList(widget.itemId)
                  ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                lib.isOnAbsorbingList(widget.itemId) ? 'Remove from Absorbing' : 'Add to Absorbing',
                onTap: () async {
                  Navigator.pop(ctx);
                  if (lib.isOnAbsorbingList(widget.itemId)) {
                    await lib.removeFromAbsorbing(widget.itemId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: const Duration(seconds: 3),
                        content: const Text('Removed from Absorbing'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                    }
                  } else {
                    await lib.addToAbsorbingQueue(widget.itemId);
                    if (_item != null) {
                      final cached = Map<String, dynamic>.from(_item!);
                      cached['_absorbingKey'] = widget.itemId;
                      lib.absorbingItemCache[widget.itemId] = cached;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: const Duration(seconds: 3),
                        content: const Text('Added to Absorbing'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                    }
                  }
                }),
              if (!lib.isOffline)
                _moreItem(cs, Icons.playlist_add_rounded, 'Add to Playlist',
                  onTap: () {
                    Navigator.pop(ctx);
                    PlaylistPickerSheet.show(context, widget.itemId);
                  }),
              if (!lib.isOffline && !lib.isPodcastLibrary && auth.isRoot)
                _moreItem(cs, Icons.collections_bookmark_rounded, 'Add to Collection',
                  onTap: () {
                    Navigator.pop(ctx);
                    CollectionPickerSheet.show(context, widget.itemId);
                  }),
              if (ebookFile != null)
                _moreItem(cs, Icons.menu_book_rounded, 'Read eBook',
                  onTap: () { Navigator.pop(ctx); _openEbookReader(context, auth, ebookFile, title); }),
              if (ebookFile != null)
                _moreItem(cs, _ebookSaved ? Icons.download_done_rounded : Icons.save_alt_rounded,
                  _ebookSaved ? 'Download eBook Again' : 'Download eBook',
                  onTap: () { Navigator.pop(ctx); _saveEbook(context, auth, ebookFile, title); }),
              if (progress > 0 || isFinished)
                _moreItem(cs, Icons.restart_alt_rounded, 'Reset Progress',
                  onTap: () { Navigator.pop(ctx); _resetProgress(context, auth, duration); }),
              if (auth.apiService != null && !lib.isOffline)
                _moreItem(cs, Icons.manage_search_rounded,
                  _hasLocalOverride ? 'Re-Lookup Local Metadata' : 'Lookup Local Metadata',
                  onTap: () { Navigator.pop(ctx); _openMetadataLookup(context, auth, title, authorName); }),
              if (_hasLocalOverride)
                _moreItem(cs, Icons.layers_clear_rounded, 'Clear Local Metadata',
                  onTap: () { Navigator.pop(ctx); _clearOverride(context); }),
              if (_showGoodreads)
                _moreItem(cs, Icons.local_library_rounded, 'Search on Goodreads',
                  onTap: () { Navigator.pop(ctx); _openGoodreads(title, authorName); }),
              if (auth.isRoot && !lib.isOffline)
                _moreItem(cs, Icons.edit_rounded, 'Edit Server Details',
                  onTap: () {
                    Navigator.pop(ctx);
                    final media = _item!['media'] as Map<String, dynamic>? ?? {};
                    final meta = media['metadata'] as Map<String, dynamic>? ?? {};
                    showEditMetadataSheet(context, itemId: widget.itemId, metadata: meta);
                  }),
            ]),
          ),
        );
      },
    );
  }

  Widget _moreItem(ColorScheme cs, IconData icon, String label, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(onTap: onTap, child: Container(height: 44,
        decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.1))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant), const SizedBox(width: 8),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500))]))),
    );
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
    return [
      if (codec != null && codec.isNotEmpty) _chip(Icons.audio_file_rounded, codec),
      if (bitRate != null && bitRate > 0) _chip(Icons.speed_rounded, '${(bitRate / 1000).round()} kbps'),
      if (totalSize > 0) _chip(Icons.storage_rounded, _fmtSize(totalSize)),
    ];
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).round()} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  Widget _chip(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: cs.onSurface.withValues(alpha: 0.3)), const SizedBox(width: 4),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)))]));
  }

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _fmtDur(double s) {
    final h = (s / 3600).floor(); final m = ((s % 3600) / 60).floor();
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  List<Widget> _buildStars(double rating, ColorScheme cs) {
    final stars = <Widget>[];
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.4;
    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star_rounded, size: 16, color: cs.primary));
      } else if (i == fullStars && hasHalf) {
        stars.add(Icon(Icons.star_half_rounded, size: 16, color: cs.primary));
      } else {
        stars.add(Icon(Icons.star_outline_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.24)));
      }
    }
    return stars;
  }

  static String get _audibleDomain {
    final code = (PlatformDispatcher.instance.locale.countryCode ?? 'US').toUpperCase();
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

  Widget _buildAuthorLinks(BuildContext context, Map<String, dynamic> metadata, ColorScheme cs, TextTheme tt) {
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
      color: cs.primary,
      decoration: TextDecoration.underline,
      decorationColor: cs.primary.withValues(alpha: 0.4),
    );
    final commaStyle = tt.bodyMedium?.copyWith(color: cs.primary);

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
              final nav = Navigator.of(context);
              nav.pop();
              showAuthorDetailSheet(nav.context, authorId: id, authorName: name);
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
            child: Text('and $remaining more', style: tt.bodyMedium?.copyWith(
              color: cs.primary.withValues(alpha: 0.7),
            )),
          ),
      ],
    );
  }

  Future<void> _openSeries(BuildContext context, String? seriesId, String seriesName) async {
    if (seriesId == null) return;
    final auth = context.read<AuthProvider>();
    final itemLibraryId = _item?['libraryId'] as String?;
    // Close current sheet before opening series to prevent infinite stacking
    final nav = Navigator.of(context);
    nav.pop();
    showSeriesBooksSheet(
      nav.context,
      seriesName: seriesName,
      seriesId: seriesId,
      serverUrl: auth.serverUrl,
      token: auth.token,
      libraryId: itemLibraryId,
    );
  }

  void _openEbookReader(BuildContext context, AuthProvider auth, Map<String, dynamic> ebookFile, String title) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => EbookReaderScreen(
          itemId: widget.itemId,
          title: title,
          ebookFile: ebookFile,
        ),
      ),
    );
  }

  bool _ebookSaving = false;

  Future<void> _saveEbook(BuildContext context, AuthProvider auth, Map<String, dynamic> ebookFile, String bookTitle) async {
    if (_ebookSaving) return;
    setState(() => _ebookSaving = true);

    try {
      final api = auth.apiService;
      if (api == null) return;

      final ino = ebookFile['ino'] as String?;
      if (ino == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No ebook file found')));
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to download ebook (${response.statusCode})')));
            }
            return;
          }

          // Sanity-check: if the server returned HTML instead of a binary
          // file, the download is likely an error/login page.
          final ct = response.headers['content-type'] ?? '';
          if (ct.contains('text/html')) {
            debugPrint('[Ebook] Server returned HTML instead of ebook file (content-type: $ct)');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Server returned an error page instead of the ebook file')));
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
        dialogTitle: 'Save eBook',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: $safeTitle$ext'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3)));
      }
    } catch (e) {
      debugPrint('[Ebook] Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving ebook: $e')));
      }
    } finally {
      if (mounted) setState(() => _ebookSaving = false);
    }
  }

  Future<void> _startAbsorb(BuildContext context, {required AuthProvider auth, required String title, required String author, required String? coverUrl, required double duration, required List<dynamic> chapters}) async {
    final player = AudioPlayerService();
    // Grab the root navigator before we pop the sheet
    final rootNav = Navigator.of(context, rootNavigator: true);

    // Ensure this book is on the absorbing list (clear any manual remove)
    // Clear finished state so the overlay disappears immediately
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

    // Start playback
    final error = await player.playItem(api: api, itemId: widget.itemId, title: title, author: author, coverUrl: coverUrl, totalDuration: duration, chapters: chapters);
    if (error != null && context.mounted) showErrorSnackBar(context, error);

    // Refresh library so the absorbing screen picks up the new book
    if (context.mounted) {
      final lib = context.read<LibraryProvider>();
      lib.refreshLocalProgress();
      lib.refresh();
    }

    // Close all sheets and navigate
    rootNav.popUntil((route) => route.isFirst);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppShell.goToAbsorbingGlobal();
    });
  }

  Future<void> _markFinished(BuildContext context, AuthProvider auth, double duration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Fully Absorbed?'),
        content: const Text('This will set your progress to 100% and stop playback if this book is playing.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Fully Absorb')),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = auth.apiService;
    if (api == null) return;
    final player = AudioPlayerService();
    // Mark finished locally first so the absorbing card shows the overlay
    // immediately when the player stops (which triggers the expanded card to pop)
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
        final mode = await PlayerSettings.getWhenFinished();
        if (mode == 'auto_remove') {
          await lib.removeFromAbsorbing(widget.itemId);
        }
        if (mounted) setState(() {});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 3), content: const Text('Marked as finished — nice work!'),
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        }
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 3), content: const Text('Failed to update — check your connection'),
        behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  Future<void> _markNotFinished(BuildContext context, AuthProvider auth, double currentTime, double duration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Not Finished?'),
        content: const Text('This will clear the finished status but keep your current position.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unmark')),
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
        await _loadItem();
        await context.read<LibraryProvider>().refresh();
        if (mounted) setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 3), content: const Text('Marked as not finished — back at it!'),
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 3), content: const Text('Failed to update — check your connection'),
        behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  Future<void> _resetProgress(BuildContext context, AuthProvider auth, double duration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text('This will erase all progress for this book and set it back to the beginning. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Reset')),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(serverSuccess ? 'Progress reset — fresh start!' : 'Reset may not have synced — check your server'),
        behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
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
          itemId: widget.itemId,
          api: api,
          initialTitle: title,
          initialAuthor: author,
          currentMetadata: (_item?['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?,
          onApplied: () {
            // Reload the item to show the new override
            _loadItem();
          },
        ),
      ),
    );
  }

  Future<void> _clearOverride(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Metadata?'),
        content: const Text(
            'This will remove the locally stored metadata and revert to whatever the server has.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true) return;
    await MetadataOverrideService().delete(widget.itemId);
    if (mounted) {
      setState(() => _hasLocalOverride = false);
      await _loadItem();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Local metadata cleared'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}

