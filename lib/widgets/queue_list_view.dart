import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'ap_episode_tile.dart';
import 'card_buttons.dart' show showErrorToast;
import 'episode_detail_sheet.dart';
import 'now_playing_sheet.dart';

// Fork addition: the Now Playing tab as a queue you read top to bottom.
//
// Replaces the sideways card carousel when the list layout is on. Order is
// the whole point of a queue, and a carousel shows you one item of it at a
// time; here the order is the screen. Drag the handle to move something,
// swipe left to drop it, tap to play it. Transport controls are not here at
// all - they live in the mini player docked above the nav bar and the full
// player that opens from it.

class QueueListView extends StatefulWidget {
  /// The queue as the absorbing screen resolved it (library filter, offline
  /// filter and the not-yet-adopted playing item already applied).
  final List<Map<String, dynamic>> books;
  final String Function(Map<String, dynamic>) keyOf;
  final Future<void> Function() onRefresh;

  /// Opens upstream's Manage Queue sheet, which still owns queue modes and
  /// the auto-download switches.
  final VoidCallback onOpenManager;

  const QueueListView({
    super.key,
    required this.books,
    required this.keyOf,
    required this.onRefresh,
    required this.onOpenManager,
  });

  @override
  State<QueueListView> createState() => _QueueListViewState();
}

class _QueueListViewState extends State<QueueListView> {
  final _player = AudioPlayerService();
  final _downloads = DownloadService();
  Timer? _tick;

  /// Keys swiped away this frame. Dismissible insists its row is gone from
  /// the tree by the next build, and the provider only notifies after its
  /// prefs write, so the row is hidden here first.
  final _dismissed = <String>{};

  @override
  void initState() {
    super.initState();
    _downloads.addListener(_onChanged);
    // The screen above already rebuilds us on player events; this only keeps
    // the active row's clock moving while audio runs.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _player.hasBook && _player.isPlaying) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _downloads.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String? get _activeKey {
    final id = _player.currentItemId;
    if (!_player.hasBook || id == null) return null;
    final ep = _player.currentEpisodeId;
    return ep == null ? id : '$id-$ep';
  }

  Map<String, dynamic>? _episodeOf(Map<String, dynamic> book) {
    final re = book['recentEpisode'];
    return re is Map<String, dynamic> ? re : null;
  }

  double _durationOf(Map<String, dynamic> book) {
    final ep = _episodeOf(book);
    final media = book['media'] as Map<String, dynamic>? ?? const {};
    return (ep?['duration'] as num?)?.toDouble() ??
        (media['duration'] as num?)?.toDouble() ??
        0;
  }

  Future<void> _play(String key, Map<String, dynamic> book) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final lib = context.read<LibraryProvider>();
    final media = book['media'] as Map<String, dynamic>? ?? const {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
    final title = metadata['title'] as String? ?? '';
    final author = metadata['authorName'] as String? ?? '';
    final ep = _episodeOf(book);
    final libraryId = book['libraryId'] as String? ?? lib.selectedLibraryId;

    HapticFeedback.selectionClick();
    final String? error;
    if (key.length > 36) {
      // Podcast episodes are keyed "<showId>-<episodeId>".
      final showId = key.substring(0, 36);
      final epTitle = ep?['title'] as String?;
      error = await _player.playItem(
        api: api,
        itemId: showId,
        title: epTitle ?? title,
        author: title,
        coverUrl: lib.getCoverUrl(showId),
        totalDuration: _durationOf(book),
        chapters: ep?['chapters'] as List<dynamic>? ?? const [],
        episodeId: key.substring(37),
        episodeTitle: epTitle,
        libraryId: libraryId,
        fromUi: true,
      );
    } else {
      error = await _player.playItem(
        api: api,
        itemId: key,
        title: title,
        author: author,
        coverUrl: lib.getCoverUrl(key),
        totalDuration: _durationOf(book),
        chapters: media['chapters'] as List<dynamic>? ?? const [],
        libraryId: libraryId,
        fromUi: true,
      );
    }
    if (!mounted) return;
    if (error != null) {
      showErrorToast(context, error);
    } else {
      unawaited(lib.syncQueueAutoDownloads());
    }
  }

  void _reorder(List<String> keys, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    final next = List<String>.from(keys);
    next.insert(newIndex, next.removeAt(oldIndex));
    context.read<LibraryProvider>().reorderAbsorbingVisible(next);
  }

  Widget _header(ColorScheme cs, TextTheme tt, int count, double secondsLeft) {
    final summary = count == 0
        ? 'Nothing queued'
        : '$count ${count == 1 ? 'item' : 'items'}, '
            '${apRoughDuration(secondsLeft)} left';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Queue', style: tt.headlineMedium),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Queue options',
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
            onSelected: (v) {
              if (v == 'manage') widget.onOpenManager();
              if (v == 'refresh') widget.onRefresh();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'manage',
                child: Text('Queue modes and downloads'),
              ),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lib = context.watch<LibraryProvider>();
    final incoming = {for (final b in widget.books) widget.keyOf(b)};
    _dismissed.removeWhere((k) => !incoming.contains(k));
    final books = [
      for (final b in widget.books)
        if (!_dismissed.contains(widget.keyOf(b))) b,
    ];
    final keys = [for (final b in books) widget.keyOf(b)];
    final active = _activeKey;
    final queued = lib.absorbingBookIds.toSet();
    final livePos = _player.position.inMilliseconds / 1000.0;

    var secondsLeft = 0.0;
    for (var i = 0; i < books.length; i++) {
      if (lib.isItemFinishedByKey(keys[i])) continue;
      final d = _durationOf(books[i]);
      if (d <= 0) continue;
      final done = keys[i] == active ? livePos : lib.getProgress(keys[i]) * d;
      secondsLeft += (d - done).clamp(0.0, d).toDouble();
    }

    final header = _header(cs, tt, books.length, secondsLeft);

    if (books.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                  child: Text(
                    'Swipe an episode in the Inbox to add it here. '
                    'They play in the order you add them.',
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            header: header,
            itemCount: books.length,
            onReorderStart: (_) => HapticFeedback.mediumImpact(),
            onReorder: (o, n) => _reorder(keys, o, n),
            proxyDecorator: (child, index, animation) => Material(
              elevation: 6,
              color: cs.surfaceContainerHigh,
              child: child,
            ),
            itemBuilder: (context, i) {
              final book = books[i];
              final key = keys[i];
              final media = book['media'] as Map<String, dynamic>? ?? const {};
              final metadata =
                  media['metadata'] as Map<String, dynamic>? ?? const {};
              final showTitle = metadata['title'] as String? ?? '';
              final author = metadata['authorName'] as String? ?? '';
              final ep = _episodeOf(book);
              final epTitle = ep?['title'] as String?;
              final isEpisode = key.length > 36;
              final isActive = key == active;
              final inQueue = queued.contains(key);
              final duration = _durationOf(book);
              final coverId = isEpisode ? key.substring(0, 36) : key;

              final tile = ApEpisodeTile(
                title: isEpisode && epTitle != null
                    ? epTitle
                    : (showTitle.isEmpty ? 'Untitled' : showTitle),
                // A playing item that hasn't been adopted into the queue yet
                // says so, rather than looking like it has a position.
                contextLine: inQueue
                    ? (isEpisode ? showTitle : author)
                    : 'Playing now, not queued',
                coverUrl: lib.getCoverUrl(coverId, width: 120),
                coverHeaders: lib.mediaHeaders,
                publishedAtMs: (ep?['publishedAt'] as num?)?.toInt() ?? 0,
                sizeBytes: (ep?['size'] as num?) ?? 0,
                durationSec: duration,
                progress: lib.getProgress(key),
                positionSec: isActive ? livePos : null,
                finished: lib.isItemFinishedByKey(key),
                active: isActive,
                downloaded: _downloads.isDownloaded(key),
                leading: ReorderableDragStartListener(
                  index: i,
                  enabled: inQueue,
                  child: SizedBox(
                    width: 40,
                    height: 56,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: cs.onSurfaceVariant
                          .withValues(alpha: inQueue ? 0.7 : 0.2),
                    ),
                  ),
                ),
                trailing: ApRoundButton(
                  icon: isActive && _player.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  filled: isActive,
                  busy: isActive && _player.isLoadingOrBuffering,
                  tooltip: isActive && _player.isPlaying ? 'Pause' : 'Play',
                  onTap: isActive
                      ? () => _player.togglePlayPause(fromUi: true)
                      : () => _play(key, book),
                ),
                onTap: isActive
                    ? () => showNowPlayingSheet(context)
                    : () => _play(key, book),
                onLongPress: isEpisode && ep != null
                    ? () => EpisodeDetailSheet.show(context, book, ep)
                    : null,
              );

              if (!inQueue) {
                return KeyedSubtree(key: ValueKey('queue-$key'), child: tile);
              }
              return Dismissible(
                key: ValueKey('queue-$key'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 28),
                  color: cs.errorContainer,
                  child: Icon(
                    Icons.playlist_remove_rounded,
                    color: cs.onErrorContainer,
                  ),
                ),
                onDismissed: (_) {
                  setState(() => _dismissed.add(key));
                  lib.removeFromAbsorbing(key);
                },
                child: tile,
              );
            },
          ),
        ),
      ),
    );
  }
}
