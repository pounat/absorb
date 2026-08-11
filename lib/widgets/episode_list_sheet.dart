import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'overlay_toast.dart';
import 'swipe_action.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../services/wording.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/chromecast_service.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_podcasts_screen.dart';
import '../services/socket_service.dart';
import '../utils/app_platform.dart';
import 'card_buttons.dart';
import 'html_description.dart';
import 'stackable_sheet.dart';
import 'episode_row.dart';
import 'action_pill.dart';
import 'adaptive_modal.dart';
export 'episode_detail_sheet.dart';

/// Bottom sheet that shows a podcast's episode list.
/// Mirrors the UX of [BookDetailSheet] but adapted for podcast shows.
class EpisodeListSheet extends StatefulWidget {
  final Map<String, dynamic> podcastItem;
  final ScrollController? scrollController;
  final String? sourcePlaylistId;
  final String? sourcePlaylistEpisodeId;

  const EpisodeListSheet({
    super.key,
    required this.podcastItem,
    this.sourcePlaylistId,
    this.sourcePlaylistEpisodeId,
  })
      : scrollController = null;

  const EpisodeListSheet._({
    required this.podcastItem,
    required this.scrollController,
    this.sourcePlaylistId,
    this.sourcePlaylistEpisodeId,
  }) : super(key: null);

  /// Show the episode list as a modal bottom sheet.
  static void show(
    BuildContext context,
    Map<String, dynamic> podcastItem, {
    String? sourcePlaylistId,
    String? sourcePlaylistEpisodeId,
  }) {
    showStackableSheet(
      context: context,
      useSafeArea: true,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollController) => EpisodeListSheet._(
        podcastItem: podcastItem,
        scrollController: scrollController,
        sourcePlaylistId: sourcePlaylistId,
        sourcePlaylistEpisodeId: sourcePlaylistEpisodeId,
      ),
    );
  }

  @override
  State<EpisodeListSheet> createState() => _EpisodeListSheetState();
}

class _EpisodeListSheetState extends State<EpisodeListSheet> {
  late Map<String, dynamic> _podcastItem;
  List<dynamic> _episodes = [];
  bool _isLoading = true;
  bool _isDownloadingAll = false;
  bool _autoDownloadEnabled = false;
  bool _subscribed = false;
  String _newEpisodePosition = 'start';
  bool _newestFirst = true;
  bool _hideFinished = false;
  bool _selectMode = false;
  final Set<String> _selectedEpisodeIds = {};
  bool _isBatchUpdating = false;

  String get _itemId => _podcastItem['id'] as String? ?? '';

  Map<String, dynamic> get _media =>
      _podcastItem['media'] as Map<String, dynamic>? ?? {};

  Map<String, dynamic> get _metadata =>
      _media['metadata'] as Map<String, dynamic>? ?? {};

  String get _title {
    final t = _metadata['title'] as String?;
    if (t != null && t.isNotEmpty) return t;
    return mounted ? AppLocalizations.of(context)!.episodeListUnknownPodcast : 'Unknown Podcast';
  }
  String get _author => _metadata['author'] as String? ?? '';
  String get _description => _metadata['description'] as String? ?? '';
  List<String> get _genres =>
      (_metadata['genres'] as List<dynamic>?)?.cast<String>() ?? [];
  // ABS keeps tags on the media object, not in metadata. Fall back to
  // metadata in case some endpoint nests them differently.
  List<String> get _tags => ((_media['tags'] as List<dynamic>?)
          ?? (_metadata['tags'] as List<dynamic>?)
          ?? const [])
      .cast<String>();
  String get _language => _metadata['language'] as String? ?? '';
  bool get _explicit => PlayerSettings.showExplicitBadge && _metadata['explicit'] == true;
  String get _type => _metadata['type'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _podcastItem = Map<String, dynamic>.from(widget.podcastItem);
    _loadSortOrder();
    _loadHideFinished();
    _loadEpisodes();
    _loadAutoDownloadState();
    _loadNewEpisodePosition();
    SocketService().addItemUpdatedListener(_onSocketItemUpdated);
  }

  @override
  void dispose() {
    SocketService().removeItemUpdatedListener(_onSocketItemUpdated);
    _liveRefreshDebounce?.cancel();
    super.dispose();
  }

  // Live-refresh the episode list when this show changes on the server, e.g.
  // an episode download finishing or a new episode arriving via auto-download.
  // Always fetches fresh - _loadEpisodes would early-return on the stale
  // episode list already embedded in the sheet's item snapshot.
  Timer? _liveRefreshDebounce;
  void _onSocketItemUpdated(Map<String, dynamic> data) {
    if (!mounted || data['id'] != _itemId) return;
    _liveRefreshDebounce?.cancel();
    _liveRefreshDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) unawaited(_refreshShowFromServer());
    });
  }

  Future<void> _refreshShowFromServer() async {
    final lib = context.read<LibraryProvider>();
    final api = context.read<AuthProvider>().apiService;
    if (api == null || lib.isOffline) return;
    final fullItem = await api.getLibraryItem(_itemId);
    if (fullItem == null || !mounted) return;
    final media = fullItem['media'] as Map<String, dynamic>? ?? {};
    final episodes = media['episodes'] as List<dynamic>? ?? [];
    setState(() {
      _podcastItem = Map<String, dynamic>.from(fullItem);
      _episodes = _sortEpisodes(episodes);
      _isLoading = false;
    });
  }

  void _loadNewEpisodePosition() async {
    if (_itemId.isEmpty) return;
    final pos = await PlayerSettings.getPodcastNewEpisodePosition(_itemId);
    if (mounted) setState(() => _newEpisodePosition = pos);
  }

  void _loadSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('podcast_sort_newest_$_itemId');
    if (saved != null && mounted) {
      setState(() {
        _newestFirst = saved;
        _episodes = _sortEpisodes(_episodes);
      });
    }
  }

  void _loadAutoDownloadState() {
    if (_itemId.isEmpty) return;
    final lib = context.read<LibraryProvider>();
    setState(() {
      _autoDownloadEnabled = lib.isRollingDownloadEnabled(_itemId);
      _subscribed = lib.isPodcastSubscribed(_itemId);
    });
  }

  Future<void> _loadEpisodes() async {
    // Episodes may already be in the item from expanded=1 or from the library list
    final existing = _media['episodes'] as List<dynamic>?;
    if (existing != null && existing.isNotEmpty) {
      setState(() {
        _episodes = _sortEpisodes(existing);
        _isLoading = false;
      });
      return;
    }

    // Otherwise fetch the full item from the server. Skip when offline so
    // the sheet doesn't sit on a loading spinner for the full network timeout
    // (downloaded podcasts populate from the section entity above; everything
    // else just shows the empty state immediately).
    final lib = context.read<LibraryProvider>();
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null || lib.isOffline) {
      setState(() => _isLoading = false);
      return;
    }

    final fullItem = await api.getLibraryItem(_itemId);
    if (fullItem != null && mounted) {
      final media = fullItem['media'] as Map<String, dynamic>? ?? {};
      final episodes = media['episodes'] as List<dynamic>? ?? [];
      setState(() {
        // Adopt the full item so a synthetic/lean map from the caller gets
        // real metadata (title, description) once the fetch lands.
        _podcastItem = Map<String, dynamic>.from(fullItem);
        _episodes = _sortEpisodes(episodes);
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sort episodes by publishedAt according to current sort order.
  List<dynamic> _sortEpisodes(List<dynamic> episodes) {
    final sorted = List<dynamic>.from(episodes);
    sorted.sort((a, b) {
      final aTime = (a['publishedAt'] as num?)?.toInt() ?? 0;
      final bTime = (b['publishedAt'] as num?)?.toInt() ?? 0;
      return _newestFirst ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });
    return sorted;
  }

  void _loadHideFinished() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('podcast_hide_finished_$_itemId');
    if (saved != null && mounted) setState(() => _hideFinished = saved);
  }

  void _toggleHideFinished() {
    setState(() => _hideFinished = !_hideFinished);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('podcast_hide_finished_$_itemId', _hideFinished);
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _newestFirst = !_newestFirst;
      _episodes = _sortEpisodes(_episodes);
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('podcast_sort_newest_$_itemId', _newestFirst);
    });
  }

  String? _playlistSourceForEpisode(String episodeId) {
    if (widget.sourcePlaylistEpisodeId != episodeId) return null;
    return widget.sourcePlaylistId;
  }

  Future<void> _activateQueueSource(String episodeId) async {
    final playlistId = _playlistSourceForEpisode(episodeId);
    if (playlistId != null && playlistId.isNotEmpty) {
      await PlayerSettings.setQueueModePlaylist(playlistId);
    }
  }

  Future<void> _restoreActivatedQueueSource(
      String episodeId, QueueModeSnapshot backup) async {
    final playlistId = _playlistSourceForEpisode(episodeId);
    if (playlistId != null && playlistId.isNotEmpty) {
      await PlayerSettings.restoreQueueModeIfPlaylistActive(playlistId, backup);
    }
  }

  Future<void> _batchMarkFinished(bool finished) async {
    if (_selectedEpisodeIds.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final lib = context.read<LibraryProvider>();

    setState(() => _isBatchUpdating = true);

    final ids = List<String>.from(_selectedEpisodeIds);
    for (final epId in ids) {
      final ep = _episodes.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == epId,
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;
      final duration = (ep['duration'] as num?)?.toDouble() ?? 0;
      final key = '$_itemId-$epId';

      if (finished) {
        await api.updateEpisodeProgress(
          _itemId, epId,
          currentTime: duration,
          duration: duration,
          isFinished: true,
        );
        lib.markFinishedLocally(key, skipAutoAdvance: true);
      } else {
        final progressData = lib.getEpisodeProgressData(_itemId, epId);
        final currentTime = (progressData?['currentTime'] as num?)?.toDouble() ?? 0;
        await api.updateEpisodeProgress(
          _itemId, epId,
          currentTime: currentTime,
          duration: duration,
          isFinished: false,
        );
      }
    }

    await lib.refresh();
    if (mounted) {
      setState(() {
        _isBatchUpdating = false;
        _selectMode = false;
        _selectedEpisodeIds.clear();
      });
      final l = AppLocalizations.of(context)!;
      showOverlayToast(
        context,
        finished
            ? l.episodeListMarkedFinished(ids.length)
            : l.episodeListMarkedUnfinished(ids.length),
        icon: finished ? Icons.check_circle_rounded : Icons.replay_rounded,
      );
    }
  }

  Future<void> _playEpisode(Map<String, dynamic> episode) async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;

    final l = AppLocalizations.of(context)!;
    final episodeId = episode['id'] as String? ?? '';
    final episodeTitle = episode['title'] as String? ?? l.episodeListEpisodeFallback;
    final duration = (episode['duration'] as num?)?.toDouble() ?? 0;
    final coverUrl = api.getCoverUrl(_itemId);

    final chapters = episode['chapters'] as List<dynamic>? ?? [];

    // Check if Chromecast is connected
    final cast = ChromecastService();
    if (cast.isConnected) {
      await cast.castItem(
        api: api,
        itemId: _itemId,
        title: episodeTitle,
        author: _title,
        coverUrl: coverUrl,
        totalDuration: duration,
        chapters: chapters,
        episodeId: episodeId,
      );
      if (mounted) Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      return;
    }

    final lib = context.read<LibraryProvider>();
    final queueModeBackup = await PlayerSettings.queueModeSnapshot();
    await _activateQueueSource(episodeId);
    final player = AudioPlayerService();
    final error = await player.playItem(
      api: api,
      itemId: _itemId,
      title: episodeTitle,
      author: _title,
      coverUrl: coverUrl,
      totalDuration: duration,
      chapters: chapters,
      episodeId: episodeId,
      episodeTitle: episodeTitle,
      // The show's own library, not the browsing library - with unified
      // libraries on, this sheet can open shows from other libraries and the
      // selected library would pin the wrong per-library skip amounts. Null
      // is fine: the player resolves it from the session/server.
      libraryId: _podcastItem['libraryId'] as String?,
    );
    if (error == null) {
      unawaited(lib.syncQueueAutoDownloads());
    } else {
      unawaited(_restoreActivatedQueueSource(episodeId, queueModeBackup));
    }
    if (mounted) {
      if (error != null) showErrorToast(context, error);
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _downloadEpisode(Map<String, dynamic> episode) async {
    if (AppPlatform.isWeb) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;

    final l = AppLocalizations.of(context)!;
    final episodeId = episode['id'] as String? ?? '';
    final episodeTitle = episode['title'] as String? ?? l.episodeListEpisodeFallback;
    final coverUrl = api.getCoverUrl(_itemId);

    final error = await DownloadService().downloadItem(
      api: api,
      itemId: '$_itemId-$episodeId',
      title: episodeTitle,
      author: _title,
      coverUrl: coverUrl,
      episodeId: episodeId,
      libraryId: _podcastItem['libraryId'] as String? ??
          context.read<LibraryProvider>().selectedLibraryId,
    );

    if (error != null && mounted) {
      showOverlayToast(context, error, icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _downloadAll() async {
    if (AppPlatform.isWeb) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;

    // Offer to enable auto-download if not already on
    if (_itemId.isNotEmpty && !_autoDownloadEnabled) {
      final l = AppLocalizations.of(context)!;
      final enable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.autoDownloadThisPodcast),
          content: Text(l.autoDownloadPodcastContent),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.noThanks)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.enable)),
          ],
        ),
      );
      if (enable == true && mounted) {
        final lib = context.read<LibraryProvider>();
        await lib.enableRollingDownload(_itemId,
            name: _title, kind: 'podcast');
        setState(() => _autoDownloadEnabled = true);
      }
    }

    setState(() => _isDownloadingAll = true);

    final l2 = mounted ? AppLocalizations.of(context)! : null;
    final episodeFallback = l2?.episodeListEpisodeFallback ?? 'Episode';
    for (final ep in _episodes) {
      if (!mounted) break;
      final episodeId = ep['id'] as String? ?? '';
      final key = '$_itemId-$episodeId';
      if (DownloadService().isDownloaded(key) || DownloadService().isDownloading(key)) continue;

      await DownloadService().downloadItem(
        api: api,
        itemId: key,
        title: ep['title'] as String? ?? episodeFallback,
        author: _title,
        coverUrl: api.getCoverUrl(_itemId),
        episodeId: episodeId,
        libraryId: context.read<LibraryProvider>().selectedLibraryId,
      );
    }

    if (mounted) setState(() => _isDownloadingAll = false);
  }

  Widget _buildOverflowMenu(ColorScheme cs) {
    int downloaded = 0;
    if (!AppPlatform.isWeb) {
      final dl = DownloadService();
      for (final ep in _episodes) {
        final eid = ep['id'] as String? ?? '';
        final key = '$_itemId-$eid';
        if (dl.isDownloaded(key)) downloaded++;
      }
    }
    final allDownloaded = !AppPlatform.isWeb && downloaded == _episodes.length;

    if (_isDownloadingAll) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
      onPressed: () => _showPodcastMoreSheet(cs, allDownloaded, downloaded),
    );
  }

  void _showPodcastMoreSheet(ColorScheme cs, bool allDownloaded, int downloaded) {
    final l = AppLocalizations.of(context)!;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    showAdaptiveActionMenu(
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
              ActionPillGrid(items: [
                if (!AppPlatform.isWeb && !allDownloaded)
                  ActionPillData(
                    icon: Icons.download_rounded,
                    label: downloaded > 0 ? l.downloadRemainingCount(_episodes.length - downloaded) : l.downloadAll,
                    onTap: () { Navigator.pop(ctx); _downloadAll(); }),
                if (!AppPlatform.isWeb && _itemId.isNotEmpty)
                  ActionPillData(
                    icon: _autoDownloadEnabled ? Icons.downloading_rounded : Icons.download_outlined,
                    label: _autoDownloadEnabled ? l.turnAutoDownloadOff : l.turnAutoDownloadOn,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final lib = context.read<LibraryProvider>();
                      await lib.toggleRollingDownload(_itemId,
                          name: _title, kind: 'podcast');
                      setState(() => _autoDownloadEnabled = lib.isRollingDownloadEnabled(_itemId));
                    }),
                if (_itemId.isNotEmpty)
                  ActionPillData(
                    icon: _subscribed ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    label: _subscribed ? l.episodeListUnsubscribeFromNewEpisodes : l.episodeListSubscribeToNewEpisodes,
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (_subscribed) {
                        final lib = context.read<LibraryProvider>();
                        await lib.unsubscribePodcast(_itemId);
                        if (mounted) setState(() => _subscribed = false);
                      } else {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            icon: const Icon(Icons.notifications_active_rounded),
                            title: Text(l.episodeListSubscribeTitle),
                            content: Text(l.episodeListSubscribeContent),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text(l.cancel)),
                              FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: Text(l.episodeListSubscribe)),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          final lib = context.read<LibraryProvider>();
                          await lib.subscribePodcast(_itemId);
                          setState(() => _subscribed = true);
                          // Surface where new episodes will land right after
                          // subscribing; the position pill lets them change it
                          // later.
                          if (mounted) _showNewEpisodePositionPicker();
                        }
                      }
                    }),
                if (_itemId.isNotEmpty && _subscribed)
                  ActionPillData(
                    icon: Icons.low_priority_rounded,
                    label: l.episodeListNewEpisodePosition,
                    onTap: () { Navigator.pop(ctx); _showNewEpisodePositionPicker(); }),
                ActionPillData(
                  icon: _hideFinished ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  label: _hideFinished ? l.episodeListShowFinishedEpisodes : l.episodeListHideFinishedEpisodes,
                  onTap: () { Navigator.pop(ctx); _toggleHideFinished(); }),
                if (isAdmin && _itemId.isNotEmpty)
                  ActionPillData(
                    icon: Icons.settings_rounded,
                    label: l.episodeListShowSettings,
                    onTap: () {
                      Navigator.pop(ctx);
                      final libraryId = _podcastItem['libraryId'] as String? ??
                          context.read<LibraryProvider>().selectedLibraryId ??
                          '';
                      unawaited(showPodcastAdminSettings(
                        context,
                        item: _podcastItem,
                        libraryId: libraryId,
                        onChanged: () => unawaited(_refreshShowFromServer()),
                      ));
                    }),
              ]),
            ]),
          ),
        );
      },
    );
  }

  void _showNewEpisodePositionPicker() {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    // 'none' keeps everything else about the subscription - new-episode
    // detection, the notification, the download - and only skips the queue,
    // for people subscribed to enough shows that it buries the rest.
    final options = <String, ({String title, String? subtitle})>{
      'start': (title: l.episodeListPositionTop, subtitle: null),
      'second': (title: l.episodeListPositionSecond, subtitle: null),
      'end': (title: l.episodeListPositionEnd, subtitle: null),
      'none': (
        title: l.episodeListPositionNone,
        subtitle: l.episodeListPositionNoneDesc
      ),
    };
    showAdaptiveActionMenu(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l.episodeListNewEpisodePosition,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            for (final entry in options.entries)
              ListTile(
                leading: Icon(
                  _newEpisodePosition == entry.key
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: _newEpisodePosition == entry.key ? cs.primary : cs.onSurfaceVariant,
                ),
                title: Text(entry.value.title),
                subtitle: entry.value.subtitle == null
                    ? null
                    : Text(entry.value.subtitle!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await PlayerSettings.setPodcastNewEpisodePosition(_itemId, entry.key);
                  if (mounted) setState(() => _newEpisodePosition = entry.key);
                },
              ),
          ]),
        ),
      ),
    );
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(children: [
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
        // Content
        Column(children: [
          // Drag handle
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),

          // ── Header (shrinks when sheet is small) ──
          Flexible(
            flex: 0,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Show title with 3-dot menu pinned right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(_title, textAlign: TextAlign.center,
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                  ),
                  SizedBox(
                    width: 48,
                    child: _buildOverflowMenu(cs),
                  ),
                ],
              ),
              if (_author.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(_author, textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
              ],

              // Description
              if (_description.isNotEmpty) ...[
                const SizedBox(height: 10),
                HtmlDescription(
                  html: _description,
                  maxLines: 3,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                  linkColor: cs.primary,
                ),
              ],

              // Metadata chips
              const SizedBox(height: 12),
              Builder(builder: (_) {
                final unfinishedCount = _episodes.where((e) {
                  final epId = (e is Map<String, dynamic>) ? (e['id'] as String? ?? '') : '';
                  if (epId.isEmpty) return false;
                  final pd = lib.getEpisodeProgressData(_itemId, epId);
                  final isFinished = pd?['isFinished'] == true;
                  return !isFinished;
                }).length;
                return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                if (!_isLoading) _chip(Icons.podcasts_rounded, l.episodeListEpisodeCount(_episodes.length)),
                if (unfinishedCount > 0) _chip(Icons.fiber_new_rounded, l.episodeListUnfinishedCount(unfinishedCount), highlight: true),
                if (!AppPlatform.isWeb && _autoDownloadEnabled) _chip(Icons.downloading_rounded, l.episodeListAutoDownloadChip),
                if (_subscribed) _chip(Icons.notifications_active_rounded, l.episodeListSubscribedChip, highlight: true),
                ..._genres.take(3).map((g) => _chip(Icons.tag_rounded, g)),
                ..._tags.take(5).map((t) => _chip(Icons.local_offer_outlined, t)),
                if (_language.isNotEmpty) _chip(Icons.language_rounded, _language.toUpperCase()),
                if (_explicit) _chip(Icons.explicit_rounded, l.episodeListExplicitChip),
                if (_type.isNotEmpty && _type != 'episodic') _chip(Icons.list_rounded, _type[0].toUpperCase() + _type.substring(1)),
              ]);
              }),

              // Episodes section header
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_selectMode) ...[
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectMode = false;
                        _selectedEpisodeIds.clear();
                      }),
                      child: Icon(Icons.close_rounded, size: 20, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Text(l.selectedCount(_selectedEpisodeIds.length),
                      style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final visible = _hideFinished
                            ? _episodes.where((e) {
                                final ep = e as Map<String, dynamic>;
                                final epId = ep['id'] as String? ?? '';
                                return lib.getEpisodeProgressData(_itemId, epId)?['isFinished'] != true;
                              }).toList()
                            : _episodes;
                        setState(() {
                          if (_selectedEpisodeIds.length == visible.length) {
                            _selectedEpisodeIds.clear();
                          } else {
                            _selectedEpisodeIds.clear();
                            for (final e in visible) {
                              _selectedEpisodeIds.add((e as Map<String, dynamic>)['id'] as String? ?? '');
                            }
                          }
                        });
                      },
                      child: Text(l.selectAll,
                        style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w500)),
                    ),
                  ] else ...[
                    Text(l.episodes, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  if (!_selectMode) ...[
                    GestureDetector(
                      onTap: () => setState(() => _selectMode = true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Icon(Icons.checklist_rounded, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _toggleSortOrder,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_newestFirst ? l.episodeListSortNewest : l.episodeListSortOldest,
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                          const SizedBox(width: 2),
                          Icon(_newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
            ])),
          ),
          ),

          // ── Scrollable episode list ──
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.24)))
                : _episodes.isEmpty
                    ? ListView(
                        controller: widget.scrollController,
                        children: [
                          SizedBox(height: 120),
                          Icon(Icons.podcasts_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.15)),
                          const SizedBox(height: 12),
                          Center(child: Text(l.noEpisodesFound, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                        ],
                      )
                    : Builder(builder: (context) {
                        final visibleEpisodes = _hideFinished
                            ? _episodes.where((e) {
                                final ep = e as Map<String, dynamic>;
                                final epId = ep['id'] as String? ?? '';
                                return lib.getEpisodeProgressData(_itemId, epId)?['isFinished'] != true;
                              }).toList()
                            : _episodes;
                        return ListView.builder(
                          controller: widget.scrollController,
                          padding: EdgeInsets.only(bottom: (_selectMode && _selectedEpisodeIds.isNotEmpty ? 64.0 : 32.0) + MediaQuery.of(context).viewPadding.bottom),
                          itemCount: visibleEpisodes.length,
                          itemBuilder: (context, index) {
                            final ep = visibleEpisodes[index] as Map<String, dynamic>;
                            final epId = ep['id'] as String? ?? '';
                            if (_selectMode) {
                              final selected = _selectedEpisodeIds.contains(epId);
                              return InkWell(
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selectedEpisodeIds.remove(epId);
                                  } else {
                                    _selectedEpisodeIds.add(epId);
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                                  child: Row(children: [
                                    Checkbox(
                                      value: selected,
                                      onChanged: (v) => setState(() {
                                        if (v == true) {
                                          _selectedEpisodeIds.add(epId);
                                        } else {
                                          _selectedEpisodeIds.remove(epId);
                                        }
                                      }),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: SelectableEpisodeRow(
                                      episode: ep,
                                      itemId: _itemId,
                                    )),
                                  ]),
                                ),
                              );
                            }
                            final absorbKey = '$_itemId-$epId';
                            final isOnAbsorbing = lib.isOnAbsorbingList(absorbKey);
                            final epTitle = ep['title'] as String? ?? l.episodeListEpisodeFallback;
                            return SwipeAction(
                              key: ValueKey('absorb-$absorbKey'),
                              onStartToEnd: isOnAbsorbing
                                  ? null
                                  : SwipeActionSpec(
                                      icon: Icons.add_circle_outline_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      onTrigger: () async {
                                        await lib.addToAbsorbingQueue(absorbKey);
                                        final cached = Map<String, dynamic>.from(_podcastItem);
                                        cached['recentEpisode'] = Map<String, dynamic>.from(ep);
                                        cached['_absorbingKey'] = absorbKey;
                                        lib.absorbingItemCache[absorbKey] = cached;
                                        HapticFeedback.mediumImpact();
                                        if (context.mounted) {
                                          showOverlayToast(context, Wording.of(context).episodeListAddedToAbsorbing(epTitle), icon: Icons.add_circle_outline_rounded);
                                        }
                                      },
                                    ),
                              child: EpisodeRow(
                                episode: ep,
                                podcastItem: _podcastItem,
                                itemId: _itemId,
                                podcastTitle: _title,
                                onPlay: () => _playEpisode(ep),
                                onDownload: () => _downloadEpisode(ep),
                                sourcePlaylistId:
                                    _playlistSourceForEpisode(epId),
                              ),
                            );
                          },
                        );
                      }),
          ),

          // ── Batch action bar ──
          if (_selectMode && _selectedEpisodeIds.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).viewPadding.bottom),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: _isBatchUpdating
                  ? Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)))
                  : Row(children: [
                      Expanded(child: FilledButton.tonalIcon(
                        onPressed: () => _batchMarkFinished(true),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(l.markFinished),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _batchMarkFinished(false),
                        icon: const Icon(Icons.radio_button_unchecked_rounded, size: 18),
                        label: Text(l.markUnfinished),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      )),
                    ]),
            ),
        ]),
      ]),
    );
  }

  Widget _chip(IconData icon, String text, {bool highlight = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? cs.primary.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: highlight ? cs.primary : cs.onSurfaceVariant), const SizedBox(width: 4),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1,
          style: TextStyle(color: highlight ? cs.primary : cs.onSurfaceVariant, fontSize: 11)))]));
  }
}
