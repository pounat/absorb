import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../services/wording.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/progress_sync_service.dart';
import '../services/chromecast_service.dart';
import '../providers/auth_provider.dart';
import 'card_buttons.dart';
import 'html_description.dart';
import 'overlay_toast.dart';
import 'playlist_picker_sheet.dart';
import 'action_pill.dart';
import '../main.dart' show rootNavigatorKey;
import 'stackable_sheet.dart';
import 'episode_list_sheet.dart';
import '../utils/duration_format.dart';

class EpisodeDetailSheet extends StatefulWidget {
  static final Set<String> _openEpisodeKeys = <String>{};

  final Map<String, dynamic> podcastItem;
  final Map<String, dynamic> episode;
  final ScrollController? scrollController;
  /// Compact long-press layout: header + Play + Download + the action grid,
  /// skipping the description / chapters / all-episodes sections.
  final bool quick;

  const EpisodeDetailSheet({super.key, required this.podcastItem, required this.episode})
      : scrollController = null, quick = false;

  const EpisodeDetailSheet._({
    required this.podcastItem,
    required this.episode,
    required this.scrollController,
    this.quick = false,
  }) : super(key: null);

  static void show(BuildContext context, Map<String, dynamic> podcastItem, Map<String, dynamic> episode) {
    final itemKey = podcastItem['id'] ?? identityHashCode(podcastItem);
    final episodeKey = episode['id'] ?? identityHashCode(episode);
    final openKey = '$itemKey::$episodeKey';
    if (!_openEpisodeKeys.add(openKey)) return;

    showStackableSheet<void>(
      context: context,
      useSafeArea: true,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollController) => EpisodeDetailSheet._(
        podcastItem: podcastItem,
        episode: episode,
        scrollController: scrollController,
      ),
    ).whenComplete(() => _openEpisodeKeys.remove(openKey));
  }

  /// Long-press shortcut: a compact quick-actions sheet for one episode.
  static void showQuick(BuildContext context, Map<String, dynamic> podcastItem, Map<String, dynamic> episode) {
    showStackableSheet(
      context: context,
      useSafeArea: true,
      initialChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (_, scrollController) => EpisodeDetailSheet._(
        podcastItem: podcastItem,
        episode: episode,
        scrollController: scrollController,
        quick: true,
      ),
    );
  }

  @override
  State<EpisodeDetailSheet> createState() => _EpisodeDetailSheetState();
}

class _EpisodeDetailSheetState extends State<EpisodeDetailSheet> {
  bool _chaptersExpanded = false;

  String get _itemId => widget.podcastItem['id'] as String? ?? '';

  String get _showTitle {
    final media = widget.podcastItem['media'] as Map<String, dynamic>? ?? {};
    final meta = media['metadata'] as Map<String, dynamic>? ?? {};
    return meta['title'] as String? ?? '';
  }

  String get _episodeTitle {
    final t = widget.episode['title'] as String?;
    if (t != null && t.isNotEmpty) return t;
    return mounted ? AppLocalizations.of(context)!.episodeDetailEpisodeFallback : 'Episode';
  }
  String get _episodeId => widget.episode['id'] as String? ?? '';
  double get _duration {
    final d = (widget.episode['duration'] as num?)?.toDouble() ?? 0;
    if (d > 0) return d;
    // recentEpisode from ABS personalized sections often omits top-level duration
    final af = widget.episode['audioFile'] as Map<String, dynamic>?;
    return (af?['duration'] as num?)?.toDouble() ?? 0;
  }
  int get _publishedAt => (widget.episode['publishedAt'] as num?)?.toInt() ?? 0;
  String? get _episodeNumber => widget.episode['episode'] as String?;
  String? get _season => widget.episode['season'] as String?;
  List<dynamic> get _chapters => widget.episode['chapters'] as List<dynamic>? ?? [];

  String get _rawDescription => widget.episode['description'] as String? ?? '';

  Future<void> _play() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;

    final cast = ChromecastService();
    if (cast.isConnected) {
      await cast.castItem(
        api: api, itemId: _itemId, title: _episodeTitle, author: _showTitle,
        coverUrl: api.getCoverUrl(_itemId), totalDuration: _duration, chapters: _chapters,
        episodeId: _episodeId,
      );
      if (mounted) Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      return;
    }

    // Close sheets BEFORE starting playback so the callback-driven tab switch
    // inside playItem() lands on a clean nav stack. Fixes iOS nav bar stuck
    // collapsed after tab transition races with sheet pop animations.
    final rootNav = Navigator.of(context, rootNavigator: true);
    final rootContext = rootNav.context;
    debugPrint('[PodcastPlay] Popping stacked sheets before playItem (item=$_itemId episode=$_episodeId)');
    rootNav.popUntil((route) => route.isFirst);
    debugPrint('[PodcastPlay] Sheets popped, calling playItem');

    final t0 = DateTime.now();
    final error = await AudioPlayerService().playItem(
      api: api, itemId: _itemId, title: _episodeTitle, author: _showTitle,
      coverUrl: api.getCoverUrl(_itemId), totalDuration: _duration, chapters: _chapters,
      episodeId: _episodeId,
      episodeTitle: _episodeTitle,
      // The show's own library, not the browsing library (wrong with unified
      // libraries on). Null lets the player resolve it from the session.
      libraryId: widget.podcastItem['libraryId'] as String?,
    );
    debugPrint('[PodcastPlay] playItem returned in ${DateTime.now().difference(t0).inMilliseconds}ms (error=${error ?? 'none'})');
    if (error != null && rootContext.mounted) {
      showErrorToast(rootContext, error);
    }
  }

  Future<void> _download() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;

    final error = await DownloadService().downloadItem(
      api: api,
      itemId: '$_itemId-$_episodeId',
      title: _episodeTitle,
      author: _showTitle,
      coverUrl: api.getCoverUrl(_itemId),
      episodeId: _episodeId,
      libraryId: context.read<LibraryProvider>().selectedLibraryId,
    );
    if (error != null && mounted) {
      showOverlayToast(context, error, icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _toggleFinished() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final lib = context.read<LibraryProvider>();
    final key = '$_itemId-$_episodeId';
    final progressData = lib.getEpisodeProgressData(_itemId, _episodeId);
    final isFinished = progressData?['isFinished'] == true;
    final currentTime = (progressData?['currentTime'] as num?)?.toDouble() ?? 0;

    final l = AppLocalizations.of(context)!;
    try {
      if (isFinished) {
        // Confirm before un-finishing
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
        // Un-finish — keep current position
        await api.updateEpisodeProgress(
          _itemId, _episodeId,
          currentTime: currentTime,
          duration: _duration,
          isFinished: false,
        );
        await lib.refresh();
        if (mounted) {
          showOverlayToast(
            context,
            l.episodeDetailMarkedNotFinished,
            icon: Icons.replay_rounded,
          );
        }
      } else {
        // Confirm before marking finished
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(Wording.of(context).markAsFullyAbsorbedQuestion),
            content: Text(l.episodeDetailMarkAbsorbedContent),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(Wording.of(context).fullyAbsorbAction)),
            ],
          ),
        );
        if (confirmed != true) return;
        // Mark finished — update server then local state for instant UI
        await api.updateEpisodeProgress(
          _itemId, _episodeId,
          currentTime: _duration,
          duration: _duration,
          isFinished: true,
        );
        lib.markFinishedLocally(key, skipAutoAdvance: true);
        if (mounted) {
          showOverlayToast(
            context,
            l.episodeDetailMarkedFinishedNice,
            icon: Icons.check_circle_outline_rounded,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        showOverlayToast(
          context,
          l.failedToUpdateCheckConnection,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _confirmDeleteDownload(BuildContext context, String dlKey) {
    final l = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.removeDownloadQuestion),
      content: Text(l.removeDownloadContent),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        TextButton(onPressed: () {
          DownloadService().deleteDownload(dlKey);
          Navigator.pop(ctx);
          showOverlayToast(
            context,
            l.downloadRemoved,
            icon: Icons.delete_outline_rounded,
          );
        },
          child: Text(l.remove, style: const TextStyle(color: Colors.redAccent))),
      ],
    ));
  }

  String? get _coverUrl {
    final auth = context.read<AuthProvider>();
    return auth.apiService?.getCoverUrl(_itemId, width: 800);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();
    final coverUrl = _coverUrl;

    final dlKey = '$_itemId-$_episodeId';

    final progress = lib.getEpisodeProgress(_itemId, _episodeId);
    final progressData = lib.getEpisodeProgressData(_itemId, _episodeId);
    final isFinished = progressData?['isFinished'] == true;

    String dateLabel = '';
    if (_publishedAt > 0) {
      final date = DateTime.fromMillisecondsSinceEpoch(_publishedAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays == 0) dateLabel = l.episodeDetailToday;
      else if (diff.inDays == 1) dateLabel = l.episodeDetailYesterday;
      else if (diff.inDays < 7) dateLabel = l.episodeDetailDaysAgo(diff.inDays);
      else if (diff.inDays < 30) dateLabel = l.episodeDetailWeeksAgo((diff.inDays / 7).floor());
      else dateLabel = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    String durationLabel = '';
    if (_duration > 0) {
      final h = (_duration / 3600).floor();
      final m = ((_duration % 3600) / 60).floor();
      durationLabel = h > 0 ? l.episodeDetailDurationHm(h, m) : l.episodeDetailDurationM(m);
    }

    // Long-press quick layout: header + Play + Download + the action grid.
    if (widget.quick) {
      return _scaffold(context, coverUrl, lib,
        _quickChildren(cs, tt, l, lib, dlKey, progress, isFinished));
    }

    return _scaffold(context, coverUrl, lib, [
            // Drag handle
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),

            // Episode title (centered)
            Text(_episodeTitle, textAlign: TextAlign.center,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 4),

            // Show title
            if (_showTitle.isNotEmpty)
              Text(_showTitle, textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),

            const SizedBox(height: 12),

            // Progress bar
            if (progress > 0) ...[
              ClipRRect(borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0), minHeight: 4,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    isFinished ? cs.primary.withValues(alpha: 0.4) : cs.primary),
                )),
              const SizedBox(height: 4),
              Text(l.percentComplete((progress * 100).toStringAsFixed(1)), textAlign: TextAlign.center,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
            ],

            // Play button (full width, matching book detail)
            _playButton(cs, tt, l, progress, isFinished),
            const SizedBox(height: 12),

            // Download + Finished row
            Row(children: [
              Expanded(child: _downloadCell(cs, l, dlKey)),
              const SizedBox(width: 8),
              Expanded(child: _finishedCell(cs, isFinished)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showMoreSheet(context, lib, dlKey, progress, isFinished),
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

            // Metadata chips
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (dateLabel.isNotEmpty) _chip(Icons.calendar_today_rounded, dateLabel),
              if (durationLabel.isNotEmpty) _chip(Icons.schedule_rounded, durationLabel),
              if (_episodeNumber != null) _chip(Icons.tag_rounded, l.episodeDetailEpisodeNumber(_episodeNumber!)),
              if (_season != null) _chip(Icons.layers_rounded, l.episodeDetailSeasonNumber(_season!)),
            ]),

            // All Episodes button (series-style)
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                EpisodeListSheet.show(context, widget.podcastItem);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  Icon(Icons.podcasts_rounded, size: 16, color: cs.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.allEpisodes,
                    style: tt.bodySmall?.copyWith(color: cs.primary.withValues(alpha: 0.9), fontWeight: FontWeight.w500))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: cs.primary.withValues(alpha: 0.5)),
                ]),
              ),
            ),

            // Chapters
            if (_chapters.isNotEmpty) ...[const SizedBox(height: 16),
              GestureDetector(onTap: () => setState(() => _chaptersExpanded = !_chaptersExpanded),
                child: Row(children: [
                  Text(l.chaptersCount(_chapters.length), style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const Spacer(), Icon(_chaptersExpanded ? Icons.expand_less : Icons.expand_more, color: cs.onSurface.withValues(alpha: 0.3), size: 20)])),
              if (_chaptersExpanded) ...[const SizedBox(height: 8),
                ..._chapters.asMap().entries.map((e) {
                  final ch = e.value as Map<String, dynamic>;
                  return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      SizedBox(width: 28, child: Text('${e.key + 1}', style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)))),
                      Expanded(child: Text(ch['title'] as String? ?? l.chapterNumber(e.key + 1), maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)))),
                      Text(formatHm(((ch['end'] as num?)?.toDouble() ?? 0) - ((ch['start'] as num?)?.toDouble() ?? 0)), style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3))),
                    ]));
                })]],

            // Description
            if (_rawDescription.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l.aboutThisEpisode, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              HtmlDescription(
                html: _rawDescription,
                maxLines: 4,
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.7), height: 1.5),
                linkColor: cs.primary,
              ),
            ],
          ],
        );
  }

  // ─── Shared scaffold + extracted buttons (full + quick layouts) ─────
  Widget _scaffold(BuildContext context, String? coverUrl, LibraryProvider lib, List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(children: [
        ..._bgLayers(context, coverUrl, lib),
        ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + MediaQuery.of(context).viewPadding.bottom),
          children: children,
        ),
      ]),
    );
  }

  List<Widget> _bgLayers(BuildContext context, String? coverUrl, LibraryProvider lib) {
    return [
      // Blurred cover background
      if (coverUrl != null)
        Positioned.fill(
          child: RepaintBoundary(
            child: CachedNetworkImage(
              imageUrl: coverUrl, fit: BoxFit.cover,
              httpHeaders: lib.mediaHeaders,
              imageBuilder: (_, p) => ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50, tileMode: TileMode.decal),
                child: Image(image: p, fit: BoxFit.cover)),
              placeholder: (_, __) => const SizedBox(),
              errorWidget: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),
      // Gradient overlay
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
          Theme.of(context).scaffoldBackgroundColor,
        ],
      )))),
    ];
  }

  Widget _playButton(ColorScheme cs, TextTheme tt, AppLocalizations l, double progress, bool isFinished) {
    return SizedBox(height: 52, child: FilledButton.icon(
      onPressed: _play,
      icon: Icon(
        progress > 0 && !isFinished ? Icons.play_arrow_rounded : Icons.podcasts_rounded,
        size: 24,
      ),
      label: Text(
        progress > 0 && !isFinished ? l.episodeDetailResume : l.episodeDetailPlayEpisode,
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary),
      ),
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ));
  }

  Widget _downloadCell(ColorScheme cs, AppLocalizations l, String dlKey) {
    return ListenableBuilder(
      listenable: DownloadService(),
      builder: (context, _) {
        final dl = DownloadService();
        final downloaded = dl.isDownloaded(dlKey);
        final downloading = dl.isDownloading(dlKey);
        final dlProgress = dl.downloadProgress(dlKey);
        final dlGreen = (Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent : Colors.green.shade700);

        final IconData icon;
        final String label;
        final Color color;
        if (downloaded) {
          icon = Icons.download_done_rounded;
          label = l.saved;
          color = dlGreen.withValues(alpha: 0.7);
        } else if (downloading) {
          icon = Icons.downloading_rounded;
          label = '${(dlProgress * 100).toStringAsFixed(0)}%';
          color = cs.primary;
        } else {
          icon = Icons.download_outlined;
          label = l.download;
          color = cs.onSurfaceVariant;
        }

        return GestureDetector(
          onTap: downloaded
              ? () => _confirmDeleteDownload(context, dlKey)
              : downloading
                  ? () => DownloadService().cancelDownload(dlKey)
                  : _download,
          child: Container(
            height: 36,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: downloaded ? dlGreen.withValues(alpha: 0.06) : cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: downloaded ? dlGreen.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Stack(children: [
              if (downloading)
                FractionallySizedBox(
                  widthFactor: dlProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
              ])),
            ]),
          ),
        );
      },
    );
  }

  Widget _finishedCell(ColorScheme cs, bool isFinished) {
    return GestureDetector(
      onTap: _toggleFinished,
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
          Flexible(child: Text(
            isFinished ? Wording.of(context).fullyAbsorbed : Wording.of(context).fullyAbsorbAction,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isFinished ? Colors.green : cs.onSurfaceVariant,
              fontSize: 12, fontWeight: FontWeight.w500,
            ),
          )),
        ]),
      ),
    );
  }

  // Compact long-press layout children.
  List<Widget> _quickChildren(ColorScheme cs, TextTheme tt, AppLocalizations l,
      LibraryProvider lib, String dlKey, double progress, bool isFinished) {
    return [
      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
      Text(_episodeTitle, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,
        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
      if (_showTitle.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(_showTitle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
      ],
      const SizedBox(height: 18),
      _playButton(cs, tt, l, progress, isFinished),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _downloadCell(cs, l, dlKey)),
        const SizedBox(width: 8),
        Expanded(child: _finishedCell(cs, isFinished)),
      ]),
      const SizedBox(height: 18),
      ActionPillGrid(items: _episodeActionItems(lib, dlKey, progress, isFinished,
        dismiss: () {}, includeOpenDetails: true)),
    ];
  }

  // The episode's secondary actions, shared by the overflow menu (dismiss pops
  // the menu) and the quick sheet (dismiss is a no-op, sheet stays open).
  List<ActionPillData> _episodeActionItems(LibraryProvider lib,
      String dlKey, double progress, bool isFinished,
      {required VoidCallback dismiss, bool includeOpenDetails = false}) {
    final l = AppLocalizations.of(context)!;
    return [
      ActionPillData(
        icon: lib.isOnAbsorbingList(dlKey)
            ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
        label: lib.isOnAbsorbingList(dlKey) ? Wording.of(context).removeFromAbsorbing : Wording.of(context).addToAbsorbing,
        onTap: () async {
          dismiss();
          if (lib.isOnAbsorbingList(dlKey)) {
            await lib.removeFromAbsorbing(dlKey);
            if (context.mounted) {
              showOverlayToast(
                context,
                Wording.of(context).removedFromAbsorbing,
                icon: Icons.remove_circle_outline_rounded,
              );
            }
          } else {
            await lib.addToAbsorbingQueue(dlKey);
            final cached = Map<String, dynamic>.from(widget.podcastItem);
            cached['recentEpisode'] = Map<String, dynamic>.from(widget.episode);
            cached['_absorbingKey'] = dlKey;
            lib.absorbingItemCache[dlKey] = cached;
            if (context.mounted) {
              showOverlayToast(
                context,
                Wording.of(context).addedToAbsorbing,
                icon: Icons.add_circle_outline_rounded,
              );
            }
          }
        }),
      if (!lib.isOffline)
        ActionPillData(icon: Icons.playlist_add_rounded, label: l.addToPlaylist,
          onTap: () {
            dismiss();
            PlaylistPickerSheet.show(
              context,
              widget.podcastItem['id'] as String,
              episodeId: widget.episode['id'] as String?,
            );
          }),
      if (!includeOpenDetails && !lib.isOffline)
        ActionPillData(
          icon: Icons.history_rounded,
          label: l.historyServerTab,
          onTap: () {
            dismiss();
            showPlaybackHistorySheet(
              context,
              itemId: _itemId,
              episodeId: _episodeId,
              initialTab: PlaybackHistoryTab.sessions,
            );
          },
        ),
      if (progress > 0 || isFinished)
        ActionPillData(icon: Icons.restart_alt_rounded, label: l.resetProgress,
          onTap: () { dismiss(); _resetProgress(context); }),
      if (includeOpenDetails)
        ActionPillData(icon: Icons.open_in_full_rounded, label: l.episodeDetailsLabel,
          onTap: () {
            final rc = rootNavigatorKey.currentContext;
            Navigator.of(context).pop();
            if (rc != null) EpisodeDetailSheet.show(rc, widget.podcastItem, widget.episode);
          }),
    ];
  }

  void _showMoreSheet(BuildContext context, LibraryProvider lib, String dlKey, double progress, bool isFinished) {
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
              ActionPillGrid(items: _episodeActionItems(lib, dlKey, progress, isFinished,
                dismiss: () => Navigator.pop(ctx))),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _resetProgress(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetProgressQuestion),
        content: Text(l.episodeDetailResetProgressContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l.reset)),
        ],
      ),
    );
    if (confirmed != true) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final player = AudioPlayerService();

    if (player.currentItemId == _itemId && player.currentEpisodeId == _episodeId) {
      await player.stopWithoutSaving();
    }

    final compoundKey = '$_itemId-$_episodeId';
    await ProgressSyncService().deleteLocal(compoundKey);
    final ok = await api.deleteEpisodeProgress(_itemId, _episodeId);
    // Mark as unfinished with zero progress on the server
    await api.updateEpisodeProgress(
      _itemId, _episodeId,
      currentTime: 0,
      duration: _duration,
      isFinished: false,
    );

    if (context.mounted) {
      context.read<LibraryProvider>().resetProgressFor(compoundKey);
      showOverlayToast(
        context,
        ok ? l.progressResetFreshStart : l.resetMayNotHaveSynced,
        icon: ok
            ? Icons.restart_alt_rounded
            : Icons.warning_amber_rounded,
      );
    }
  }

  Widget _chip(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant), const SizedBox(width: 4),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)))]));
  }
}
