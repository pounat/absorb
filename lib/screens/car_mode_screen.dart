import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' hide PlaybackEvent;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/bookmark_service.dart';
import '../widgets/card_buttons.dart';
import '../l10n/app_localizations.dart';

class CarModeScreen extends StatefulWidget {
  final AudioPlayerService player;
  final String? itemId;
  final String? fallbackTitle;
  final String? fallbackAuthor;
  final String? fallbackCoverUrl;
  final double fallbackDuration;
  final List<dynamic> fallbackChapters;
  final String? episodeId;
  final String? episodeTitle;

  const CarModeScreen({
    super.key,
    required this.player,
    this.itemId,
    this.fallbackTitle,
    this.fallbackAuthor,
    this.fallbackCoverUrl,
    this.fallbackDuration = 0,
    this.fallbackChapters = const [],
    this.episodeId,
    this.episodeTitle,
  });

  @override
  State<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends State<CarModeScreen>
    with SingleTickerProviderStateMixin {
  int _backSkip = 10;
  int _forwardSkip = 30;
  bool _preferChapterBar = false;
  late AnimationController _playPauseController;
  Timer? _displayTimer;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.player.isPlaying ? 1.0 : 0.0,
    );
    _loadSkipSettings();
    PlayerSettings.settingsChanged.addListener(_loadSkipSettings);
    widget.player.addListener(_onPlayerChanged);
    // Tick every second so the speed-adjusted time display updates smoothly
    // even when the position stream fires less often (e.g. at 0.5x speed).
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.player.isPlaying) setState(() {});
    });
    // Allow both portrait and landscape — many in-car mounts are landscape.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _loadSkipSettings() {
    PlayerSettings.getBackSkip().then((v) {
      if (mounted && v != _backSkip) setState(() => _backSkip = v);
    });
    PlayerSettings.getForwardSkip().then((v) {
      if (mounted && v != _forwardSkip) setState(() => _forwardSkip = v);
    });
    PlayerSettings.getNotificationChapterProgress().then((v) {
      if (mounted && v != _preferChapterBar) setState(() => _preferChapterBar = v);
    });
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    PlayerSettings.settingsChanged.removeListener(_loadSkipSettings);
    widget.player.removeListener(_onPlayerChanged);
    _playPauseController.dispose();
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  bool _isStarting = false;

  String? _getCoverUrl(BuildContext context) {
    final lib = context.read<LibraryProvider>();
    final itemId = widget.player.currentItemId ?? widget.itemId;
    if (itemId == null) return null;
    return lib.getCoverUrl(itemId, width: 800);
  }

  Future<void> _startPlayback() async {
    if (_isStarting || widget.itemId == null) return;
    setState(() => _isStarting = true);
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) { setState(() => _isStarting = false); return; }
    await widget.player.playItem(
      api: api,
      itemId: widget.itemId!,
      title: widget.fallbackTitle ?? l.unknown,
      author: widget.fallbackAuthor ?? '',
      coverUrl: widget.fallbackCoverUrl,
      totalDuration: widget.fallbackDuration,
      chapters: widget.fallbackChapters,
      episodeId: widget.episodeId,
      episodeTitle: widget.episodeTitle,
    );
    if (mounted) setState(() => _isStarting = false);
  }

  bool get _isLocalCover {
    final url = _getCoverUrl(context);
    return url != null && url.startsWith('/');
  }

  String _currentChapterTitle() {
    final chapters = widget.player.chapters;
    if (chapters.isEmpty) return '';
    final pos = widget.player.position.inSeconds.toDouble();
    for (final ch in chapters) {
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? 0;
      if (pos >= start && pos < end) {
        return ch['title'] as String? ?? '';
      }
    }
    return '';
  }

  /// Returns (chapterProgress, chapterElapsed, chapterRemaining)
  (double, Duration, Duration) _chapterProgress() {
    final chapters = widget.player.chapters;
    if (chapters.isEmpty) return (0, Duration.zero, Duration.zero);
    final pos = widget.player.position.inSeconds.toDouble();
    final speed = widget.player.speed;
    for (final ch in chapters) {
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? 0;
      if (pos >= start && pos < end) {
        final chLen = end - start;
        final chPos = pos - start;
        final progress = chLen > 0 ? (chPos / chLen).clamp(0.0, 1.0) : 0.0;
        return (
          progress,
          Duration(seconds: (chPos / speed).round()),
          Duration(seconds: ((chLen - chPos) / speed).round()),
        );
      }
    }
    return (0, Duration.zero, Duration.zero);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatRemaining(Duration remaining) {
    if (remaining.isNegative) return '0:00';
    return '-${_formatDuration(remaining)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final player = widget.player;
    final title = player.currentTitle ?? widget.fallbackTitle ?? l.carModeNoBookLoaded;
    final author = player.currentAuthor ?? widget.fallbackAuthor ?? '';
    final coverUrl = _getCoverUrl(context);
    final auth = context.read<AuthProvider>();
    final hasChapters = player.chapters.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final h = constraints.maxHeight;
          // Landscape: cover on the left, everything else stacked vertically on the right.
          final wide = constraints.maxWidth > h;
          // Tier sizing uses the available height of the *column that owns the
          // text* — in landscape that's the right column, same h as full card.
          // Three tiers: ultra (<380), compact (<520), full
          final ultra = h < 380;
          final compact = h < 520;
          final titleSize = ultra ? 15.0 : compact ? 18.0 : 24.0;
          final authorSize = ultra ? 12.0 : compact ? 14.0 : 17.0;
          final timeSize = ultra ? 10.0 : compact ? 12.0 : 15.0;
          final skipSize = ultra ? 44.0 : compact ? 56.0 : 72.0;
          final skipIconSize = ultra ? 30.0 : compact ? 38.0 : 48.0;
          final hPad = ultra ? 16.0 : compact ? 24.0 : 32.0;
          final closeSize = ultra ? 22.0 : compact ? 26.0 : 32.0;
          final bottomIconSize = ultra ? 24.0 : compact ? 28.0 : 36.0;
          // In ultra mode, only show one bar based on user's notification preference
          final showBookProgress = !ultra || !_preferChapterBar || !hasChapters;
          final showChapterProgress = hasChapters && (!ultra || _preferChapterBar);
          final showAuthor = author.isNotEmpty && !ultra;

          final headerSection = Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 0 : 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.white, size: closeSize),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Icon(Icons.directions_car_rounded, color: Colors.white54, size: compact ? 18 : 22),
                    const SizedBox(width: 6),
                    Text(l.carModeTitle, style: TextStyle(color: Colors.white54, fontSize: compact ? 13 : 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                  ],
                ),
              );

          final bookProgressSection = showBookProgress
              ? StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, _) {
                  final pos = player.position;
                  final total = Duration(seconds: player.totalDuration.round());
                  final speed = player.speed;
                  final bookProgress = total.inMilliseconds > 0
                      ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0;
                  final bookElapsed = Duration(milliseconds: (pos.inMilliseconds / speed).round());
                  final bookRemaining = Duration(milliseconds: ((total - pos).inMilliseconds / speed).round());

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(children: [
                      SizedBox(height: compact ? 2 : 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: bookProgress,
                          minHeight: compact ? 4 : 6,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(bookElapsed),
                              style: TextStyle(color: Colors.white54, fontSize: timeSize, fontWeight: FontWeight.w600)),
                          Text(_formatRemaining(bookRemaining),
                              style: TextStyle(color: Colors.white54, fontSize: timeSize, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ]),
                  );
                },
              )
              : const SizedBox.shrink();

          final titleAuthorSection = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Text(
                      title,
                      style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showAuthor) ...[
                    SizedBox(height: compact ? 2 : 4),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Text(
                        author,
                        style: TextStyle(color: Colors.white60, fontSize: authorSize, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              );

          final coverArea = Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad + (ultra ? 4 : 16), vertical: ultra ? 2 : compact ? 6 : 12),
                  child: Center(
                    child: StreamBuilder<PlayerState>(
                      stream: player.hasBook ? player.playerStateStream : const Stream.empty(),
                      builder: (_, snapshot) {
                        final playing = snapshot.data?.playing ?? player.isPlaying;
                        final processingState = snapshot.data?.processingState ?? ProcessingState.ready;
                        final isLoading = _isStarting || (player.hasBook &&
                            (processingState == ProcessingState.loading ||
                             processingState == ProcessingState.buffering));

                        if (playing) {
                          _playPauseController.forward();
                        } else {
                          _playPauseController.reverse();
                        }

                        return AspectRatio(
                          aspectRatio: 1,
                          child: GestureDetector(
                            onTap: player.hasBook
                                ? player.togglePlayPause
                                : widget.itemId != null ? _startPlayback : null,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(compact ? 12 : 20),
                                    child: coverUrl != null
                                        ? (_isLocalCover
                                            ? Image.file(File(coverUrl), fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _placeholderCover(cs))
                                            : CachedNetworkImage(
                                                imageUrl: coverUrl,
                                                fit: BoxFit.cover,
                                                httpHeaders: auth.apiService?.mediaHeaders ?? {},
                                                errorWidget: (_, __, ___) => _placeholderCover(cs),
                                              ))
                                        : _placeholderCover(cs),
                                  ),
                                ),
                                // Play/pause overlay
                                Positioned.fill(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(compact ? 12 : 20),
                                      color: playing ? Colors.transparent : Colors.black.withValues(alpha: 0.3),
                                    ),
                                    child: Center(
                                      child: isLoading
                                          ? SizedBox(
                                              width: compact ? 40 : 56,
                                              height: compact ? 40 : 56,
                                              child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                            )
                                          : AnimatedOpacity(
                                              opacity: playing ? 0.15 : 0.8,
                                              duration: const Duration(milliseconds: 200),
                                              child: Icon(
                                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                size: compact ? 64 : 88, color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              );

          final chapterProgressSection = showChapterProgress
              ? StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, snapshot) {
                    final (chProgress, chElapsed, chRemaining) = _chapterProgress();
                    final chapterTitle = _currentChapterTitle();

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Column(children: [
                        if (chapterTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(chapterTitle,
                              style: TextStyle(color: Colors.white54, fontSize: compact ? 12.0 : 14.0, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: chProgress,
                            minHeight: compact ? 4 : 6,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(chElapsed),
                                style: TextStyle(color: Colors.white54, fontSize: timeSize, fontWeight: FontWeight.w600)),
                            Text(_formatRemaining(chRemaining),
                                style: TextStyle(color: Colors.white54, fontSize: timeSize, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ]),
                    );
                  },
                )
              : const SizedBox.shrink();

          final skipControls = Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: GestureDetector(
                      onTap: player.hasBook ? player.skipToPreviousChapter : null,
                      child: SizedBox(width: skipSize, height: skipSize,
                        child: Center(child: Icon(Icons.skip_previous_rounded,
                          size: skipIconSize * 0.85,
                          color: player.hasBook ? Colors.white70 : Colors.white24))),
                    )),
                    Flexible(child: GestureDetector(
                      onTap: player.hasBook ? () => player.skipBackward(_backSkip) : null,
                      child: SizedBox(width: skipSize, height: skipSize,
                        child: Center(child: _buildSkipIcon(_backSkip, false, player.hasBook, skipIconSize))),
                    )),
                    Flexible(child: GestureDetector(
                      onTap: player.hasBook ? () => player.skipForward(_forwardSkip) : null,
                      child: SizedBox(width: skipSize, height: skipSize,
                        child: Center(child: _buildSkipIcon(_forwardSkip, true, player.hasBook, skipIconSize))),
                    )),
                    Flexible(child: GestureDetector(
                      onTap: player.hasBook ? player.skipToNextChapter : null,
                      child: SizedBox(width: skipSize, height: skipSize,
                        child: Center(child: Icon(Icons.skip_next_rounded,
                          size: skipIconSize * 0.85,
                          color: player.hasBook ? Colors.white70 : Colors.white24))),
                    )),
                  ],
                ),
              );

          final speedBookmarkRow = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.speed_rounded, size: bottomIconSize),
                    color: Colors.white54,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        useSafeArea: true,
                        builder: (_) => CardSpeedSheet(
                          player: player,
                          accent: Colors.white,
                          itemId: player.currentItemId,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: ultra ? 16 : compact ? 24 : 40),
                  IconButton(
                    icon: Icon(Icons.bookmark_add_outlined, size: bottomIconSize),
                    color: Colors.white54,
                    onPressed: player.hasBook ? () {
                      final pos = player.position.inMilliseconds / 1000.0;
                      final chTitle = _currentChapterTitle();
                      final itemId = player.currentEpisodeId != null
                          ? '${player.currentItemId}-${player.currentEpisodeId}'
                          : player.currentItemId;
                      if (itemId == null) return;
                      BookmarkService().addBookmark(
                        itemId: itemId,
                        positionSeconds: pos,
                        title: chTitle.isNotEmpty ? chTitle : l.carModeBookmarkDefault,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l.carModeBookmarkAdded),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } : null,
                  ),
                ],
              );

          final bottomPad = SizedBox(height: (compact ? 4 : 8) + MediaQuery.of(context).viewPadding.bottom);

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: Center(child: coverArea)),
                Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    headerSection,
                    bookProgressSection,
                    SizedBox(height: ultra ? 2 : compact ? 4 : 10),
                    titleAuthorSection,
                    SizedBox(height: ultra ? 4 : compact ? 6 : 14),
                    chapterProgressSection,
                    SizedBox(height: ultra ? 2 : compact ? 6 : 14),
                    skipControls,
                    SizedBox(height: ultra ? 0 : compact ? 4 : 10),
                    speedBookmarkRow,
                    bottomPad,
                  ],
                )),
              ],
            );
          }

          return Column(
            children: [
              headerSection,
              bookProgressSection,
              SizedBox(height: ultra ? 2 : compact ? 4 : 10),
              titleAuthorSection,
              Expanded(child: Center(child: coverArea)),
              chapterProgressSection,
              SizedBox(height: ultra ? 2 : compact ? 6 : 14),
              skipControls,
              SizedBox(height: ultra ? 0 : compact ? 4 : 10),
              speedBookmarkRow,
              bottomPad,
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSkipIcon(int seconds, bool isForward, bool active, [double iconSize = 52]) {
    final hasBuiltIn = [5, 10, 30].contains(seconds);
    final color = active ? Colors.white70 : Colors.white24;
    if (hasBuiltIn) {
      IconData icon;
      if (isForward) {
        icon = seconds == 5
            ? Icons.forward_5_rounded
            : seconds == 10
                ? Icons.forward_10_rounded
                : Icons.forward_30_rounded;
      } else {
        icon = seconds == 5
            ? Icons.replay_5_rounded
            : seconds == 10
                ? Icons.replay_10_rounded
                : Icons.replay_30_rounded;
      }
      return Icon(icon, size: iconSize, color: color);
    }
    return Stack(alignment: Alignment.center, children: [
      Icon(
        isForward ? Icons.rotate_right_rounded : Icons.rotate_left_rounded,
        size: iconSize,
        color: color,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '$seconds',
          style: TextStyle(
            fontSize: iconSize * 0.27,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    ]);
  }

  Widget _placeholderCover(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.headphones_rounded, size: 64, color: Colors.white24),
      ),
    );
  }
}
