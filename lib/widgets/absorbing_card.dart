import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/app_shell.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'absorbing_shared.dart';
import 'card_edge_progress_bar.dart';
import 'card_progress_bar.dart';
import 'card_playback_controls.dart';
import 'card_buttons.dart';
import '../services/chromecast_service.dart';
import 'expanded_card.dart';

class AbsorbingCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final AudioPlayerService player;
  const AbsorbingCard({super.key, required this.item, required this.player});

  @override
  State<AbsorbingCard> createState() => AbsorbingCardState();
}

class AbsorbingCardState extends State<AbsorbingCard> with AutomaticKeepAliveClientMixin {
  ColorScheme? _coverScheme;
  Brightness? _coverBrightness; // brightness used to generate _coverScheme
  ImageProvider? _coverProvider; // cached for re-deriving on theme change
  bool _isStarting = false;
  List<dynamic>? _fetchedChapters;
  StreamSubscription<Duration>? _chapterTrackSub;
  int _lastChapterIdx = -1;
  ui.Image? _blurredCover; // Precached blurred background
  String? _blurredCoverUrl; // URL the blur was built from
  List<String> _buttonOrder = PlayerSettings.defaultButtonOrder;
  int _buttonVisibleCount = PlayerSettings.defaultButtonVisibleCount;
  bool _iconsOnly = false;
  bool _moreInline = false;
  bool _rectangleCovers = false;
  bool _coverPlayButton = false;
  bool _speedAdjustedTime = true;
  double _savedSpeed = 1.0; // per-book or default speed for inactive display
  final ValueNotifier<bool> _edgeBarExpanded = ValueNotifier(false);
  String? _lastRenderLogSig;

  @override
  bool get wantKeepAlive => true;

  String get _itemId => widget.item['id'] as String? ?? '';
  Map<String, dynamic> get _media => widget.item['media'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get _metadata => _media['metadata'] as Map<String, dynamic>? ?? {};
  String get _title {
    final t = _metadata['title'] as String?;
    if (t != null && t.isNotEmpty) return t;
    return mounted ? AppLocalizations.of(context)!.unknown : 'Unknown';
  }
  String get _author => _metadata['authorName'] as String? ?? '';
  double get _duration => (_media['duration'] as num?)?.toDouble() ?? 0;
  List<dynamic> get _chapters {
    // Prefer fetched chapters (from full item or episode), fall back to inline data
    if (_fetchedChapters != null && _fetchedChapters!.isNotEmpty) return _fetchedChapters!;
    final inline = _media['chapters'] as List<dynamic>? ?? [];
    if (inline.isNotEmpty) return inline;
    // For podcast episodes, chapters live on the episode object
    final epChapters = _recentEpisode?['chapters'] as List<dynamic>? ?? [];
    if (epChapters.isNotEmpty) return epChapters;
    // For active podcast episodes, chapters come from the playback session
    if (_isActive && widget.player.chapters.isNotEmpty) return widget.player.chapters;
    return [];
  }
  bool get _isActive {
    if (widget.player.currentItemId != _itemId) return false;
    // For podcast episode cards, only active if the same episode is playing
    if (_episodeId != null && widget.player.currentEpisodeId != null) {
      return _episodeId == widget.player.currentEpisodeId;
    }
    return true;
  }
  bool get _isCastingThis {
    final cast = ChromecastService();
    return cast.isCasting && cast.castingItemId == _itemId;
  }
  bool get _isPlaybackActive => _isActive || _isCastingThis;
  bool get _isPodcastEpisode => _isActive && widget.player.currentEpisodeId != null;

  // For inactive podcast show cards: recentEpisode is embedded in the continue-listening entity
  Map<String, dynamic>? get _recentEpisode => widget.item['recentEpisode'] as Map<String, dynamic>?;

  /// Resolve full episode data for the current episode.
  // Episode ID: prefer recentEpisode, fall back to compound absorbing key
  String? get _episodeId {
    final re = _recentEpisode;
    if (re != null) return re['id'] as String?;
    // Compound absorbing keys are "showUUID-episodeId" (>36 chars)
    final absKey = widget.item['_absorbingKey'] as String?;
    if (absKey != null && absKey.length > 36) return absKey.substring(37);
    return null;
  }
  // Use episode duration for inactive podcast show cards (show duration is aggregate/incorrect)
  double get _effectiveDuration {
    if (!_isActive && _recentEpisode != null) {
      // Try top-level duration first, then audioFile.duration
      final epDur = (_recentEpisode!['duration'] as num?)?.toDouble();
      if (epDur != null && epDur > 0) return epDur;
      final audioFile = _recentEpisode!['audioFile'] as Map<String, dynamic>?;
      final afDur = (audioFile?['duration'] as num?)?.toDouble();
      if (afDur != null && afDur > 0) return afDur;
    }
    return _duration;
  }

  String? get _coverUrl {
    final lib = context.read<LibraryProvider>();
    return lib.getCoverUrl(_itemId, width: 800);
  }

  bool get _isLocalCover => _coverUrl != null && _coverUrl!.startsWith('/');

  @override
  void initState() {
    super.initState();
    _fetchChaptersIfNeeded();
    _startChapterTracking();
    ChromecastService().addListener(_onCastChanged);
    DownloadService().addListener(_onDownloadChanged);
    PlayerSettings.settingsChanged.addListener(_reloadButtonOrder);
    _reloadButtonOrder();
  }

  void _onSpeedMaybeChanged() => _loadSavedSpeed();

  Future<void> _loadSavedSpeed() async {
    final bookSpeed = await PlayerSettings.getBookSpeed(_itemId);
    final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
    if (mounted && speed != _savedSpeed) setState(() => _savedSpeed = speed);
  }

  void _reloadButtonOrder() {
    PlayerSettings.getCardButtonOrder().then((o) {
      if (mounted && o.join(',') != _buttonOrder.join(',')) setState(() => _buttonOrder = o);
    });
    PlayerSettings.getCardButtonVisibleCount().then((c) {
      if (mounted && c != _buttonVisibleCount) setState(() => _buttonVisibleCount = c);
    });
    PlayerSettings.getCardIconsOnly().then((v) {
      if (mounted && v != _iconsOnly) setState(() => _iconsOnly = v);
    });
    PlayerSettings.getCardMoreInline().then((v) {
      if (mounted && v != _moreInline) {
        setState(() {
          _moreInline = v;
          if (v && !_buttonOrder.contains('_more')) {
            final insertAt = (_buttonVisibleCount >= 9 ? 8 : _buttonVisibleCount).clamp(0, _buttonOrder.length);
            _buttonOrder.insert(insertAt, '_more');
            _buttonVisibleCount = (_buttonVisibleCount < 9 ? _buttonVisibleCount + 1 : 9);
            PlayerSettings.setCardButtonOrder(_buttonOrder);
            PlayerSettings.setCardButtonVisibleCount(_buttonVisibleCount);
          }
        });
      }
    });
    PlayerSettings.getRectangleCovers().then((v) {
      if (mounted && v != _rectangleCovers) setState(() => _rectangleCovers = v);
    });
    PlayerSettings.getCoverPlayButton().then((v) {
      if (mounted && v != _coverPlayButton) setState(() => _coverPlayButton = v);
    });
    PlayerSettings.getSpeedAdjustedTime().then((v) {
      if (mounted && v != _speedAdjustedTime) setState(() => _speedAdjustedTime = v);
    });
    _loadSavedSpeed();
  }

  void _onDownloadChanged() { if (mounted) setState(() {}); }

  void _onCastChanged() {
    _startChapterTracking();
    if (mounted) setState(() {});
  }

  Future<void> _fetchChaptersIfNeeded() async {
    // If chapters are already available, skip
    if (_chapters.isNotEmpty) return;
    // Fetch full item to get chapters
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    try {
      final fullItem = await api.getLibraryItem(_itemId);
      if (fullItem != null && mounted) {
        final media = fullItem['media'] as Map<String, dynamic>? ?? {};
        // Books: chapters at media level
        var chapters = media['chapters'] as List<dynamic>? ?? [];
        // Podcasts: chapters on the specific episode
        if (chapters.isEmpty && _episodeId != null) {
          final episodes = media['episodes'] as List<dynamic>? ?? [];
          for (final ep in episodes) {
            if (ep is Map<String, dynamic> && ep['id'] == _episodeId) {
              chapters = ep['chapters'] as List<dynamic>? ?? [];
              break;
            }
          }
        }
        if (chapters.isNotEmpty) {
          setState(() => _fetchedChapters = chapters);
          // If this is the active item and player has no chapters, update them
          if (_isActive && widget.player.chapters.isEmpty) {
            widget.player.updateChapters(chapters);
          }
        }
      }
    } catch (_) {}
  }

  void _startChapterTracking() {
    _chapterTrackSub?.cancel();

    if (_isCastingThis) {
      final stream = ChromecastService().castPositionStream;
      if (stream == null) return;
      _chapterTrackSub = stream.listen((_) {
        if (!_isCastingThis) return;
        // Use translated book-level position from ChromecastService, not the raw
        // stream value (which is track-local in multi-track fallback mode).
        final cast = ChromecastService();
        final posS = cast.castPosition.inMilliseconds / 1000.0;
        final chapters = cast.castingChapters;
        if (chapters.isEmpty) {
          final sec = cast.castPosition.inSeconds;
          if (sec != _lastChapterIdx) {
            _lastChapterIdx = sec;
            if (mounted) setState(() {});
          }
          return;
        }
        int idx = 0;
        for (int i = 0; i < chapters.length; i++) {
          final ch = chapters[i] as Map<String, dynamic>;
          final start = (ch['start'] as num?)?.toDouble() ?? 0;
          final end = (ch['end'] as num?)?.toDouble() ?? 0;
          if (posS >= start && posS < end) { idx = i; break; }
        }
        if (idx != _lastChapterIdx) {
          _lastChapterIdx = idx;
          if (mounted) setState(() {});
        }
      });
      return;
    }

    _chapterTrackSub = widget.player.absolutePositionStream.listen((pos) {
      if (!_isActive) return;
      final posS = pos.inMilliseconds / 1000.0;
      final chapters = widget.player.chapters.isNotEmpty ? widget.player.chapters : _chapters;
      if (chapters.isEmpty) {
        final sec = pos.inSeconds;
        if (sec != _lastChapterIdx) {
          _lastChapterIdx = sec;
          if (mounted) setState(() {});
        }
        return;
      }
      int idx = 0;
      for (int i = 0; i < chapters.length; i++) {
        final ch = chapters[i] as Map<String, dynamic>;
        final start = (ch['start'] as num?)?.toDouble() ?? 0;
        final end = (ch['end'] as num?)?.toDouble() ?? 0;
        if (posS >= start && posS < end) { idx = i; break; }
      }
      if (idx != _lastChapterIdx) {
        _lastChapterIdx = idx;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-derive cover color scheme when theme brightness changes
    _rederiveCoverScheme();
  }

  @override
  void didUpdateWidget(AbsorbingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.item['id'] as String? ?? '';
    if (oldId != _itemId) {
      // Item changed — reset all stale state
      _coverScheme = null;
      _coverBrightness = null;
      _coverProvider = null;
      _blurredCover?.dispose();
      _blurredCover = null;
      _fetchedChapters = null;
      _lastChapterIdx = -1;
      _fetchChaptersIfNeeded();
    }
    if (oldWidget.player != widget.player) _startChapterTracking();
  }

  @override
  void dispose() {
    PlayerSettings.settingsChanged.removeListener(_reloadButtonOrder);
    ChromecastService().removeListener(_onCastChanged);
    DownloadService().removeListener(_onDownloadChanged);
    widget.player.removeListener(_onSpeedMaybeChanged);
    _chapterTrackSub?.cancel();
    _blurredCover?.dispose();
    _edgeBarExpanded.dispose();
    super.dispose();
  }

  void _onCoverLoaded(ImageProvider provider) {
    _coverProvider = provider;
    _rederiveCoverScheme();
    // Precache the blurred version of the cover
    if (_blurredCover == null) {
      _blurredCoverUrl = _coverUrl;
      _precacheBlur(provider);
    }
  }

  void _rederiveCoverScheme() {
    final provider = _coverProvider;
    if (provider == null) return;
    final brightness = Theme.of(context).brightness;
    if (_coverScheme != null && _coverBrightness == brightness) return;
    _coverBrightness = brightness;
    ColorScheme.fromImageProvider(provider: provider, brightness: brightness)
        .then((s) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _coverScheme = s);
            });
          }
        })
        .catchError((_) {});
  }

  /// Resolve the image, render it blurred to an offscreen canvas, cache the result.
  Future<void> _precacheBlur(ImageProvider provider) async {
    try {
      final completer = Completer<ui.Image>();
      final stream = provider.resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener((info, _) {
        completer.complete(info.image);
        stream.removeListener(listener);
      }, onError: (e, _) {
        if (!completer.isCompleted) completer.completeError(e);
        stream.removeListener(listener);
      });
      stream.addListener(listener);

      final srcImage = await completer.future;
      // Render at reduced size for performance (blur hides detail anyway)
      const targetWidth = 200;
      final aspect = srcImage.height / srcImage.width;
      final targetHeight = (targetWidth * aspect).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()));
      final paint = Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30, tileMode: TileMode.decal);
      canvas.drawImageRect(
        srcImage,
        Rect.fromLTWH(0, 0, srcImage.width.toDouble(), srcImage.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        paint,
      );
      final picture = recorder.endRecording();
      final blurred = await picture.toImage(targetWidth, targetHeight);
      picture.dispose();

      if (mounted) {
        setState(() => _blurredCover = blurred);
      } else {
        blurred.dispose();
      }
    } catch (_) {
      // Fallback: card will show without blurred background, which is fine
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    final tt = Theme.of(context).textTheme;
    final cs = _coverScheme ?? Theme.of(context).colorScheme;
    final accent = cs.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    final lib = context.watch<LibraryProvider>();
    final mediaHeaders = lib.mediaHeaders;
    // For podcast episodes, look up progress by compound key (itemId-episodeId)
    final progress = (_episodeId != null)
        ? lib.getEpisodeProgress(_itemId, _episodeId!)
        : (_isPodcastEpisode
            ? lib.getEpisodeProgress(_itemId, widget.player.currentEpisodeId!)
            : lib.getProgress(_itemId));
    final chapterIdx = _currentChapterIndex();
    final cast = ChromecastService();
    final totalChapters = _isCastingThis ? cast.castingChapters.length : (_isActive ? widget.player.chapters.length : _chapters.length);
    final double bookProgress;
    if (_isCastingThis && cast.castingDuration > 0) {
      final castPos = cast.castPosition.inMilliseconds / 1000.0;
      bookProgress = (castPos / cast.castingDuration).clamp(0.0, 1.0);
    } else if (_isActive && widget.player.totalDuration > 0) {
      final playerPos = widget.player.position.inMilliseconds / 1000.0;
      if (playerPos < 1.0 && progress > 0.01) {
        bookProgress = progress;
      } else {
        bookProgress = (playerPos / widget.player.totalDuration).clamp(0.0, 1.0);
      }
    } else {
      bookProgress = progress;
    }

    // Alpha diagnostic: fires only when a state-shape transition happens
    // (not on every position tick), to confirm why a card's progress bar
    // would render empty after an AA cold-start.
    final durBucket = widget.player.totalDuration > 0 ? 'pos' : 'zero';
    final progBucket = progress <= 0.001 ? '0' : (progress >= 0.999 ? '1' : 'mid');
    final bookBucket = bookProgress <= 0.001 ? '0' : (bookProgress >= 0.999 ? '1' : 'mid');
    final sig = 'item=$_itemId ep=$_episodeId active=$_isActive hasBook=${widget.player.hasBook} dur=$durBucket prog=$progBucket bar=$bookBucket playerItem=${widget.player.currentItemId} playerEp=${widget.player.currentEpisodeId}';
    if (sig != _lastRenderLogSig) {
      _lastRenderLogSig = sig;
      debugPrint('[Card] $sig');
    }

    // Invalidate blurred background when cover URL changes (e.g. after server update)
    if (_blurredCover != null && _blurredCoverUrl != _coverUrl) {
      _blurredCover?.dispose();
      _blurredCover = null;
    }

    final showBookBar = (!_isPodcastEpisode || _chapters.isNotEmpty) && (!lib.isPodcastLibrary || _chapters.isNotEmpty);
    return GestureDetector(
      onVerticalDragEnd: (details) {
        final vy = details.primaryVelocity ?? 0;
        if (vy < -300) expandCard(context); // swipe up to expand
      },
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.15), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          fit: StackFit.expand,
          children: [
          // Layer 1: Pre-blurred cover background (cached bitmap — no per-frame blur)
          if (_blurredCover != null)
            RepaintBoundary(
              child: RawImage(
                image: _blurredCover,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          else if (_coverUrl != null)
            // Fallback while blur is being computed: show unblurred cover dimmed
            RepaintBoundary(
              child: _isLocalCover
                  ? Builder(builder: (_) {
                      final provider = FileImage(File(_coverUrl!));
                      _onCoverLoaded(provider);
                      return Opacity(
                        opacity: 0.3,
                        child: Image.file(File(_coverUrl!), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: isDark ? Colors.black : Colors.white)),
                      );
                    })
                  : CachedNetworkImage(
                      imageUrl: _coverUrl!,
                      fit: BoxFit.cover,
                      httpHeaders: mediaHeaders,
                      imageBuilder: (_, provider) {
                        _onCoverLoaded(provider);
                        return Opacity(
                          opacity: 0.3,
                          child: Image(image: provider, fit: BoxFit.cover),
                        );
                      },
                      placeholder: (_, __) => Container(color: isDark ? Colors.black : Colors.white),
                      errorWidget: (_, __, ___) => Container(color: isDark ? Colors.black : Colors.white),
                    ),
            ),
          // Layer 2: Scrim
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.85),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                      ],
                ),
              ),
            ),
          ),
          // Layer 3: Content
          LayoutBuilder(
          builder: (context, cardConstraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
          final compact = cardConstraints.maxHeight < 600 * textScale;
          // In landscape the card is wider than tall — switch to a two-pane
          // layout with the cover on the left and everything else on the right.
          final wide = cardConstraints.maxWidth > cardConstraints.maxHeight;

          final statsRow = ValueListenableBuilder<bool>(
                valueListenable: _edgeBarExpanded,
                builder: (_, expanded, child) => AnimatedOpacity(
                  opacity: expanded ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: child,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, compact ? 6 : 10, 24, 0),
                  child: StreamBuilder<Duration>(
                    stream: _isCastingThis
                        ? cast.castPositionStream
                        : widget.player.absolutePositionStream,
                    builder: (_, snap) {
                      final double pos;
                      final double dur;
                      if (_isCastingThis) {
                        pos = cast.castPosition.inMilliseconds / 1000.0;
                        dur = cast.castingDuration;
                      } else if (_isActive) {
                        pos = (snap.data?.inMilliseconds ?? 0) / 1000.0;
                        dur = _effectiveDuration;
                      } else {
                        // Use exact currentTime from server progress if available,
                        // otherwise fall back to progress ratio * duration.
                        final pd = _episodeId != null
                            ? lib.getEpisodeProgressData(_itemId, _episodeId!)
                            : lib.getProgressData(_itemId);
                        final ct = (pd?['currentTime'] as num?)?.toDouble();
                        pos = (ct != null && ct > 0) ? ct : bookProgress * _effectiveDuration;
                        dur = _effectiveDuration;
                      }
                      final speed = _speedAdjustedTime ? (_isActive ? widget.player.speed : _savedSpeed) : 1.0;
                      final liveBookProgress = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : bookProgress;
                      final elapsed = pos / speed;
                      final remaining = (dur - pos) / speed;
                      final timeStyle = tt.labelSmall?.copyWith(
                        color: isDark ? Colors.white.withValues(alpha: 0.55) : cs.onSurface,
                        fontWeight: FontWeight.w500, fontSize: compact ? 10 : 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: [Shadow(color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6), blurRadius: 4)],
                      );
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            children: [
                              if (_effectiveDuration > 0 && showBookBar)
                                Text(fmtTime(elapsed), style: timeStyle),
                              const Spacer(),
                              if (_effectiveDuration > 0 && showBookBar)
                                Text('-${fmtTime(remaining)}', style: timeStyle),
                            ],
                          ),
                          Text('${(liveBookProgress * 100).clamp(0, 100).toStringAsFixed(1)}%',
                            style: timeStyle),
                        ],
                      );
                    },
                  ),
                ),
              );

          final coverArea = Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ListenableBuilder(
                    listenable: Listenable.merge([ChromecastService(), widget.player]),
                    builder: (context, _) => LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth * 0.75;
                      final rawH = constraints.maxHeight.isFinite ? constraints.maxHeight : maxW;
                      final maxH = rawH - 24;
                      double coverW, coverH;
                      if (_rectangleCovers) {
                        coverW = maxW;
                        coverH = coverW * 1.5;
                        if (coverH > maxH) { coverH = maxH; coverW = coverH / 1.5; }
                      } else {
                        final s = maxW < maxH ? maxW : maxH;
                        coverW = s;
                        coverH = s;
                      }
                      final dlKey = _episodeId != null ? '$_itemId-$_episodeId' : _itemId;
                      final isDownloaded = DownloadService().isDownloaded(dlKey);
                      final castService = ChromecastService();
                      final isCastingThis = castService.isCasting && castService.castingItemId == _itemId;
                      final coverPlaying = isCastingThis ? castService.isPlaying : (_isActive && widget.player.isPlaying);
                      final coverLoading = _isStarting || (_isActive && widget.player.isLoadingOrBuffering && !widget.player.isPlaying);
                      return Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: () {
                              final showStreaming = !isDownloaded && _isActive;
                              final showSaved = isDownloaded;
                              final visible = showSaved || showStreaming;
                              final streamColor = isDark ? Colors.white.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.6);
                              final savedColor = isDark ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.green.shade700.withValues(alpha: 0.7);
                              return Opacity(
                                opacity: visible ? 1.0 : 0.0,
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(
                                    showSaved ? Icons.download_done_rounded : Icons.cell_tower_rounded,
                                    size: 11, color: showSaved ? savedColor : streamColor),
                                  const SizedBox(width: 3),
                                  Text(showSaved ? l.saved : l.expandedCardStreaming, style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w500,
                                    color: showSaved ? savedColor : streamColor,
                                  )),
                                ]),
                              );
                            }(),
                          ),
                          GestureDetector(
                        onTap: _coverPlayButton ? () {
                          if (isCastingThis) {
                            castService.togglePlayPause();
                          } else if (_isActive) {
                            widget.player.togglePlayPause();
                          } else {
                            _startPlayback();
                          }
                        } : null,
                        child: Container(
                          width: coverW,
                          height: coverH,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15), blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 6)),
                              BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: -5),
                            ],
                          ),
                          child: RepaintBoundary(
                            child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Cover image
                                _coverUrl != null
                                    ? _isLocalCover
                                        ? BlurPaddedCover(child: Image.file(File(_coverUrl!), fit: _rectangleCovers ? BoxFit.cover : BoxFit.contain,
                                            errorBuilder: (_, __, ___) => CoverPlaceholder(title: _title, author: _author)),
                                            blurChild: Image.file(File(_coverUrl!), fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                            enabled: !_rectangleCovers)
                                        : BlurPaddedCover(child: CachedNetworkImage(imageUrl: _coverUrl!, fit: _rectangleCovers ? BoxFit.cover : BoxFit.contain,
                                              httpHeaders: mediaHeaders,
                                              placeholder: (_, __) => CoverPlaceholder(title: _title, author: _author),
                                              errorWidget: (_, __, ___) => CoverPlaceholder(title: _title, author: _author)),
                                            blurChild: CachedNetworkImage(imageUrl: _coverUrl!, fit: BoxFit.cover,
                                              httpHeaders: mediaHeaders,
                                              errorWidget: (_, __, ___) => const SizedBox.shrink()),
                                            enabled: !_rectangleCovers)
                                    : CoverPlaceholder(title: _title, author: _author),
                                                // Casting overlay
                                if (isCastingThis) ...[
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cast_connected_rounded, size: 36, color: accent.withValues(alpha: 0.9)),
                                        const SizedBox(height: 8),
                                        Text(l.castingTo, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 2),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            castService.connectedDeviceName ?? l.expandedCardDeviceFallback,
                                            style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w700),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                // Play/pause overlay
                                if (_coverPlayButton) Positioned.fill(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: coverPlaying ? Colors.transparent : Colors.black.withValues(alpha: 0.25),
                                    ),
                                    child: Center(
                                      child: coverLoading
                                          ? Container(
                                              width: 65, height: 65,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withValues(alpha: 0.5),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: CircularProgressIndicator(strokeWidth: 3, color: accent),
                                              ),
                                            )
                                          : AnimatedOpacity(
                                              opacity: coverPlaying ? 0.2 : 0.9,
                                              duration: const Duration(milliseconds: 200),
                                              child: Container(
                                                width: 72, height: 72,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.black.withValues(alpha: 0.45),
                                                ),
                                                child: Icon(
                                                  coverPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                  size: 42, color: accent,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ),
                      ]));
                    },
                  ),
                  ),
              );

          final scrubberBar = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CardDualProgressBar(player: widget.player, accent: accent, isActive: _isActive, staticProgress: (_isPodcastEpisode && _chapters.isEmpty) ? 0.0 : progress, staticDuration: (_isPodcastEpisode && _chapters.isEmpty) ? widget.player.totalDuration : _effectiveDuration, chapters: _chapters, showBookBar: false, showChapterBar: true, chapterName: (_isPodcastEpisode && _chapters.isEmpty) ? (widget.player.currentEpisodeTitle ?? widget.player.currentTitle ?? _title) : (_episodeId != null && !_isActive ? (_recentEpisode?['title'] as String? ?? _title) : _chapterName(chapterIdx)), chapterIndex: chapterIdx, totalChapters: totalChapters, itemId: _itemId, compact: compact),
                );

          final controlsRow = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CardPlaybackControls(
                    player: widget.player,
                    accent: accent,
                    isActive: _isActive,
                    isStarting: _isStarting,
                    onStart: _startPlayback,
                    itemId: _itemId,
                    showPlayButton: !_coverPlayButton,
                  ),
                );

          final buttonGrid = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.noScaling,
                  ),
                  child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, buttonsConstraints) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: buttonsConstraints.maxWidth - 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ..._buildButtonGrid(accent, tt),
                          if (!_moreInline) ...[
                          const SizedBox(height: 6),
                          Center(
                            child: ListenableBuilder(
                              listenable: ChromecastService(),
                              builder: (context, _) {
                                final castActive = ChromecastService().isCasting && !_buttonOrder.take(_visibleButtonCount).contains('cast');
                                return Pressable(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _showMoreMenu(context, accent, tt),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: castActive ? accent.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: castActive
                                          ? [
                                              Icon(Icons.cast_connected_rounded, size: 18, color: accent),
                                              const SizedBox(width: 4),
                                              Text(l.casting, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: accent)),
                                            ]
                                          : [
                                              Icon(Icons.more_horiz_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.54)),
                                              const SizedBox(width: 4),
                                              Text(l.more, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.54))),
                                            ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          ],
                          SizedBox(height: compact ? 4 : 8),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
                );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: coverArea),
                Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    statsRow,
                    SizedBox(height: compact ? 6 : 10),
                    scrubberBar,
                    SizedBox(height: compact ? 6 : 10),
                    controlsRow,
                    SizedBox(height: compact ? 6 : 12),
                    buttonGrid,
                  ],
                )),
              ],
            );
          }

          return Column(
            children: [
              statsRow,
              Expanded(child: coverArea),
              SizedBox(height: compact ? 6 : 10),
              scrubberBar,
              SizedBox(height: compact ? 6 : 10),
              controlsRow,
              SizedBox(height: compact ? 6 : 12),
              buttonGrid,
            ],
          );
          }),
          // Edge progress bar (thin strip at top of card)
          if (showBookBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CardEdgeProgressBar(
                player: widget.player,
                accent: accent,
                isActive: _isActive,
                staticProgress: progress,
                staticDuration: _effectiveDuration,
                chapters: _chapters,
                itemId: _itemId,
                expandedNotifier: _edgeBarExpanded,
              ),
            ),
        ],
      ),
      ),
    ),
    );
  }

  int _currentChapterIndex() {
    final cast = ChromecastService();
    final chapters = _isCastingThis ? cast.castingChapters : (_isActive ? widget.player.chapters : _chapters);
    if (chapters.isEmpty) return -1;
    double pos;
    if (_isCastingThis) {
      pos = cast.castPosition.inMilliseconds / 1000.0;
    } else if (_isActive) {
      final seekTarget = widget.player.activeSeekTarget;
      if (seekTarget != null) {
        pos = seekTarget;
      } else {
        pos = widget.player.position.inMilliseconds / 1000.0;
      }
    } else {
      // Use stored progress to calculate position when not actively playing
      final lib = context.read<LibraryProvider>();
      final progress = (_episodeId != null)
          ? lib.getEpisodeProgress(_itemId, _episodeId!)
          : lib.getProgress(_itemId);
      pos = progress * _effectiveDuration;
    }
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i] as Map<String, dynamic>;
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? 0;
      if (pos >= start && pos < end) return i;
    }
    // If past the last chapter end, return last chapter
    if (pos > 0 && chapters.isNotEmpty) return chapters.length - 1;
    return 0;
  }

  String? _chapterName(int chapterIdx) {
    if (_isCastingThis) {
      final ch = ChromecastService().currentChapter;
      return ch?['title'] as String?;
    }
    if (_isActive && widget.player.activeSeekTarget == null && widget.player.currentChapter != null) {
      return widget.player.currentChapter!['title'] as String?;
    }
    if (chapterIdx >= 0 && chapterIdx < _chapters.length) {
      final ch = _chapters[chapterIdx] as Map<String, dynamic>;
      return ch['title'] as String?;
    }
    return null;
  }

  void expandCard(BuildContext context) {
    AppShell.setExpandedOpen(true);
    Navigator.of(context, rootNavigator: true).push(
      ExpandedCardRoute(
        child: ExpandedCard(
          item: widget.item,
          player: widget.player,
          initialCoverScheme: _coverScheme,
          initialBlurredCover: _blurredCover,
          initialChapters: _fetchedChapters,
        ),
      ),
    ).then((_) => AppShell.setExpandedOpen(false));
  }

  Future<void> _startPlayback() async {
    if (_isStarting) return;
    // If we're casting this book, don't start local playback
    final cast = ChromecastService();
    if (cast.isCasting && cast.castingItemId == _itemId) return;
    setState(() => _isStarting = true);
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) { setState(() => _isStarting = false); return; }
    final error = await widget.player.playItem(
      api: api, itemId: _itemId, title: _title, author: _author,
      coverUrl: _coverUrl, totalDuration: _effectiveDuration, chapters: _chapters,
      episodeId: _episodeId,
      episodeTitle: _recentEpisode?['title'] as String?,
    );
    if (mounted) {
      if (error != null) showErrorSnackBar(context, error);
      setState(() => _isStarting = false);
    }
  }

  Future<void> _removeFromAbsorbing() async {
    if (widget.player.currentItemId == _itemId) {
      await widget.player.pause();
      await widget.player.stop();
    }
    if (mounted) {
      final lib = context.read<LibraryProvider>();
      // Use compound key for podcast episodes
      final key = _episodeId != null ? '$_itemId-$_episodeId' : _itemId;
      await lib.removeFromAbsorbing(key);
    }
  }

  // ── Dynamic button builders (delegated) ─────────────────────

  CardActionDelegate _makeActions() => CardActionDelegate(
    context: context,
    player: widget.player,
    item: widget.item,
    itemId: _itemId,
    episodeId: _episodeId,
    isPodcastEpisode: _isPodcastEpisode,
    title: _title,
    author: _author,
    coverUrl: _coverUrl,
    duration: _duration,
    effectiveDuration: _effectiveDuration,
    chapters: _chapters,
    recentEpisode: _recentEpisode,
    isActive: _isActive,
    isPlaybackActive: _isPlaybackActive,
    isCastingThis: _isCastingThis,
    speedAdjustedTime: _speedAdjustedTime,
    savedSpeed: _savedSpeed,
    visibleCount: _buttonVisibleCount,
    iconsOnly: _iconsOnly,
    moreInline: _moreInline,
    buttonOrder: _buttonOrder,
    removeFromAbsorbing: _removeFromAbsorbing,
    onReorder: (newOrder, newCount) {
      setState(() { _buttonOrder = newOrder; _buttonVisibleCount = newCount; });
      PlayerSettings.setCardButtonOrder(newOrder);
      PlayerSettings.setCardButtonVisibleCount(newCount);
    },
  );

  int get _visibleButtonCount => _buttonVisibleCount;

  List<Widget> _buildButtonGrid(Color accent, TextTheme tt) => _makeActions().buildButtonGrid(accent, tt);

  void _showMoreMenu(BuildContext context, Color accent, TextTheme tt) => _makeActions().showMoreMenu(accent, tt);

}

