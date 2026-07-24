import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../services/download_service.dart';
import '../services/scoped_prefs.dart';
import 'card_buttons.dart' show showErrorToast;
import 'episode_list_sheet.dart';
import 'episode_row.dart';
import 'overlay_toast.dart';

bool podcastEpisodeMatchesFilter(
  String filter, {
  required double progress,
  required bool finished,
  required bool downloaded,
  required bool subscribed,
}) => switch (filter) {
  'downloaded' => downloaded,
  'subscribed' => subscribed,
  'notfinished' => !finished,
  'unplayed' => progress <= 0 && !finished,
  'inprogress' => progress > 0 && !finished,
  'finished' => finished,
  _ => true,
};

/// Recent-episodes feed for podcast libraries (the "Episodes" pill): the
/// library's newest episodes across all shows, with quick filters and swipe
/// actions (mark played / download).
class PodcastEpisodeFeed extends StatefulWidget {
  final String libraryId;

  /// The library page header (title, search, library chip), passed in so the
  /// feed keeps the same chrome as the Shows grid.
  final Widget? headerSliver;
  const PodcastEpisodeFeed({
    super.key,
    required this.libraryId,
    this.headerSliver,
  });

  @override
  State<PodcastEpisodeFeed> createState() => _PodcastEpisodeFeedState();
}

class _PodcastEpisodeFeedState extends State<PodcastEpisodeFeed> {
  static const _pageSize = 50;

  final _episodes = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  String _filter = 'all';
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ScopedPrefs.getString('episode_feed_filter_${widget.libraryId}').then((v) {
      if (mounted && v != null && v.isNotEmpty) {
        setState(() => _filter = v);
        _fillFilteredResults();
      }
    });
    _scroll.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) {
      setState(() {
        _error = 'Not connected to server';
        _loading = false;
      });
      return;
    }
    setState(() => _loadingMore = _page > 0);
    final batch = await api.getRecentEpisodes(
      widget.libraryId,
      limit: _pageSize,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      _episodes.addAll(batch.whereType<Map<String, dynamic>>());
      _hasMore = batch.length >= _pageSize;
      _page++;
      _loading = false;
      _loadingMore = false;
    });
    _fillFilteredResults();
  }

  Future<void> _refresh() async {
    _episodes.clear();
    _page = 0;
    _hasMore = true;
    await _loadPage();
  }

  void _setFilter(String f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    ScopedPrefs.setString('episode_feed_filter_${widget.libraryId}', f);
    _fillFilteredResults();
  }

  void _fillFilteredResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _filter == 'all' ||
          !_hasMore ||
          _loading ||
          _loadingMore) {
        return;
      }
      final lib = context.read<LibraryProvider>();
      final matchCount = _episodes.where((ep) => _matchesFilter(lib, ep)).length;
      if (matchCount < 20) _loadPage();
    });
  }

  String _showIdOf(Map<String, dynamic> ep) =>
      ep['libraryItemId'] as String? ??
      ep['podcastId'] as String? ??
      (ep['podcast'] as Map<String, dynamic>?)?['id'] as String? ??
      '';

  /// The recent-episodes payload carries the parent show as `podcast` (a
  /// library item without its episode list). Fall back to a minimal synthetic
  /// item so the detail sheets can still resolve title/cover by id.
  Map<String, dynamic> _podcastItemOf(Map<String, dynamic> ep) {
    final podcast = ep['podcast'];
    if (podcast is Map<String, dynamic> && podcast['id'] != null) {
      return {
        ...podcast,
        'libraryId': podcast['libraryId'] ?? widget.libraryId,
      };
    }
    return {
      'id': _showIdOf(ep),
      'libraryId': widget.libraryId,
      'mediaType': 'podcast',
      'media': {
        'metadata': {'title': ep['podcastTitle'] as String? ?? ''},
      },
    };
  }

  String _showTitleOf(Map<String, dynamic> ep) {
    final podcast = ep['podcast'] as Map<String, dynamic>?;
    final meta =
        (podcast?['media'] as Map<String, dynamic>?)?['metadata']
            as Map<String, dynamic>?;
    return meta?['title'] as String? ?? ep['podcastTitle'] as String? ?? '';
  }

  Widget _showCover(LibraryProvider lib, String showId, ColorScheme cs) {
    final url = lib.getCoverUrl(showId, width: 96);
    final placeholder = Container(
      width: 48,
      height: 48,
      color: cs.surfaceContainer,
      child: Icon(Icons.podcasts_rounded, size: 22, color: cs.onSurfaceVariant),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? placeholder
          // Downloaded shows resolve to a local file path.
          : url.startsWith('/')
          ? Image.file(
              File(url),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : CachedNetworkImage(
              imageUrl: url,
              httpHeaders: lib.mediaHeaders,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => placeholder,
            ),
    );
  }

  bool _matchesFilter(LibraryProvider lib, Map<String, dynamic> ep) {
    final showId = _showIdOf(ep);
    final epId = ep['id'] as String? ?? '';
    final progress = lib.getEpisodeProgress(showId, epId);
    final finished =
        lib.getEpisodeProgressData(showId, epId)?['isFinished'] == true;
    return podcastEpisodeMatchesFilter(
      _filter,
      progress: progress,
      finished: finished,
      downloaded: DownloadService().isDownloaded('$showId-$epId'),
      subscribed: lib.isPodcastSubscribed(showId),
    );
  }

  Future<void> _playEpisode(Map<String, dynamic> ep) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final showId = _showIdOf(ep);
    final episodeId = ep['id'] as String? ?? '';
    final title = ep['title'] as String? ?? '';
    final duration = (ep['duration'] as num?)?.toDouble() ?? 0;
    final coverUrl = api.getCoverUrl(showId);
    final chapters = ep['chapters'] as List<dynamic>? ?? [];
    final showTitle = _showTitleOf(ep);

    final cast = ChromecastService();
    if (cast.isConnected) {
      await cast.castItem(
        api: api,
        itemId: showId,
        title: title,
        author: showTitle,
        coverUrl: coverUrl,
        totalDuration: duration,
        chapters: chapters,
        episodeId: episodeId,
      );
      return;
    }
    final error = await AudioPlayerService().playItem(
      api: api,
      itemId: showId,
      title: title,
      author: showTitle,
      coverUrl: coverUrl,
      totalDuration: duration,
      chapters: chapters,
      episodeId: episodeId,
      episodeTitle: title,
      // Prefer the show's own library - the feed can aggregate shows from
      // other libraries when unified libraries is on.
      libraryId: (ep['podcast'] as Map<String, dynamic>?)?['libraryId'] as String? ??
          widget.libraryId,
    );
    if (error != null && mounted) showErrorToast(context, error);
  }

  Future<void> _downloadEpisode(Map<String, dynamic> ep) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final showId = _showIdOf(ep);
    final episodeId = ep['id'] as String? ?? '';
    final error = await DownloadService().downloadItem(
      api: api,
      itemId: '$showId-$episodeId',
      title: ep['title'] as String? ?? '',
      author: _showTitleOf(ep),
      coverUrl: api.getCoverUrl(showId),
      episodeId: episodeId,
      libraryId: widget.libraryId,
    );
    if (error != null && mounted) {
      showOverlayToast(context, error, icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _toggleFinished(Map<String, dynamic> ep) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final lib = context.read<LibraryProvider>();
    final showId = _showIdOf(ep);
    final epId = ep['id'] as String? ?? '';
    final duration = (ep['duration'] as num?)?.toDouble() ?? 0;
    final finished =
        lib.getEpisodeProgressData(showId, epId)?['isFinished'] == true;

    if (finished) {
      await api.updateEpisodeProgress(
        showId,
        epId,
        currentTime: 0,
        duration: duration,
        isFinished: false,
      );
      await lib.refreshProgressOnly();
    } else {
      await api.updateEpisodeProgress(
        showId,
        epId,
        currentTime: duration,
        duration: duration,
        isFinished: true,
      );
      lib.markFinishedLocally('$showId-$epId', skipAutoAdvance: true);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _episodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final filtered = _episodes.where((ep) => _matchesFilter(lib, ep)).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.headerSliver != null) widget.headerSliver!,
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (key, label) in [
                        ('all', l.filterAllEpisodes),
                        ('subscribed', l.episodeListSubscribedChip),
                        ('notfinished', l.notFinished),
                        ('unplayed', l.filterUnplayed),
                        ('inprogress', l.inProgress),
                        ('finished', l.filterFinished),
                        ('downloaded', l.downloaded),
                      ]) ...[
                        ChoiceChip(
                          label: Text(label),
                          selected: _filter == key,
                          onSelected: (_) => _setFilter(key),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l.episodeFeedEmpty,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: filtered.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= filtered.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final ep = filtered[i];
                final showId = _showIdOf(ep);
                final epId = ep['id'] as String? ?? '';
                final finished =
                    lib.getEpisodeProgressData(showId, epId)?['isFinished'] ==
                    true;
                return Dismissible(
                  key: ValueKey('feed-$showId-$epId'),
                  // Swipes act without dismissing the row.
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _toggleFinished(ep);
                    } else {
                      _downloadEpisode(ep);
                    }
                    return false;
                  },
                  background: Container(
                    color: cs.primaryContainer,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    child: Icon(
                      finished
                          ? Icons.radio_button_unchecked_rounded
                          : Icons.check_circle_rounded,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  secondaryBackground: Container(
                    color: cs.secondaryContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.download_rounded,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Show cover so the feed reads at a glance; tapping it
                      // opens the show's episode list.
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: GestureDetector(
                          onTap: () => EpisodeListSheet.show(
                            context,
                            _podcastItemOf(ep),
                          ),
                          child: _showCover(lib, showId, cs),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20, top: 2),
                              child: Text(
                                _showTitleOf(ep),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            EpisodeRow(
                              episode: ep,
                              podcastItem: _podcastItemOf(ep),
                              itemId: showId,
                              podcastTitle: _showTitleOf(ep),
                              onPlay: () => _playEpisode(ep),
                              onDownload: () => _downloadEpisode(ep),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Room for the floating pill bar.
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}
