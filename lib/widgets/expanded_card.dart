import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../utils/cover_accent.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/chromecast_service.dart';
import 'absorbing_shared.dart';
import 'card_progress_bar.dart';
import 'card_playback_controls.dart';
import 'card_buttons.dart';
import 'ebook_router.dart';
import 'overlay_toast.dart';
import '../services/ebook_cache.dart';
import '../services/find_in_ebook.dart';
import '../main.dart' show colorSourceNotifier, useColorEverywhereNotifier, manualSeedNotifier, manualColorScheme;

// ─── Custom route: slide-up + fade ────────────────────────────

class ExpandedCardRoute extends PageRoute<void> {
  final Widget child;
  ExpandedCardRoute({required this.child});

  @override Color? get barrierColor => null;
  @override String? get barrierLabel => null;
  @override bool get maintainState => true;
  @override bool get opaque => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => child;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}

// ─── Expanded card widget ─────────────────────────────────────

class ExpandedCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final AudioPlayerService player;
  final ColorScheme? initialCoverScheme;
  final ui.Image? initialBlurredCover;
  final List<dynamic>? initialChapters;
  final Map<String, dynamic>? initialEbookFile;
  final String initialCardBackground;

  const ExpandedCard({
    super.key,
    required this.item,
    required this.player,
    this.initialCoverScheme,
    this.initialBlurredCover,
    this.initialChapters,
    this.initialEbookFile,
    this.initialCardBackground = 'blurred',
  });

  @override
  State<ExpandedCard> createState() => _ExpandedCardState();
}

class _ExpandedCardState extends State<ExpandedCard> {
  ColorScheme? _rawCoverScheme;
  Brightness? _coverBrightness;

  /// Cover-derived scheme, unless a manual app color is set to apply everywhere.
  ColorScheme? get _coverScheme {
    if (colorSourceNotifier.value == 'manual' && useColorEverywhereNotifier.value) {
      return manualColorScheme(manualSeedNotifier.value, Theme.of(context).brightness);
    }
    return _rawCoverScheme;
  }
  ImageProvider? _coverProvider;
  ui.Image? _blurredCover;
  // Brightness of the blurred cover's top strip, where the percentage sits.
  double? _coverTopLuminance;
  List<dynamic>? _fetchedChapters;
  // The item passed to the full-screen player is often a lean/synthetic map
  // without media.ebookFile, so the "Read" action fell back to "no ebook".
  // Filled by the full-item fetch below, same as the small card does.
  Map<String, dynamic>? _fetchedEbookFile;
  bool _isStarting = false;
  StreamSubscription<Duration>? _chapterTrackSub;
  int _lastChapterIdx = -1;

  // Track current item for detecting changes
  late String? _currentItemId;
  late String? _currentEpisodeId;
  bool _wasPlaying = false;
  bool _isPopping = false; // Prevent double-pop and setState during exit
  List<String> _buttonOrder = PlayerSettings.defaultButtonOrder;
  int _buttonVisibleCount = PlayerSettings.defaultButtonVisibleCount;
  bool _iconsOnly = false;
  bool _moreInline = false;
  bool _rectangleCovers = false;
  bool _coverPlayButton = false;
  String _cardBackground = 'blurred';
  bool _speedAdjustedTime = true;
  double _progressTextScale = 1.0;

  // Our own route, captured for popUntil when modals are stacked above us
  Route<dynamic>? _ownRoute;

  // Current item data (may change if a new book starts)
  late Map<String, dynamic> _item;

  String get _itemId => _item['id'] as String? ?? '';
  Map<String, dynamic> get _media => _item['media'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get _metadata => _media['metadata'] as Map<String, dynamic>? ?? {};
  String get _title {
    final t = _metadata['title'] as String?;
    if (t != null && t.isNotEmpty) return t;
    return mounted ? AppLocalizations.of(context)!.unknown : 'Unknown';
  }
  String get _author => _metadata['authorName'] as String? ?? '';
  double get _duration => (_media['duration'] as num?)?.toDouble() ?? 0;
  List<dynamic> get _chapters {
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

  Map<String, dynamic>? get _recentEpisode => _item['recentEpisode'] as Map<String, dynamic>?;

  /// Resolve full episode data for the current episode.
  // Episode ID: prefer recentEpisode, fall back to compound absorbing key
  String? get _episodeId {
    final re = _recentEpisode;
    if (re != null) return re['id'] as String?;
    final absKey = _item['_absorbingKey'] as String?;
    if (absKey != null && absKey.length > 36) return absKey.substring(37);
    return null;
  }
  double get _effectiveDuration {
    if (!_isActive && _recentEpisode != null) {
      final epDur = (_recentEpisode!['duration'] as num?)?.toDouble();
      if (epDur != null && epDur > 0) return epDur;
      final audioFile = _recentEpisode!['audioFile'] as Map<String, dynamic>?;
      final afDur = (audioFile?['duration'] as num?)?.toDouble();
      if (afDur != null && afDur > 0) return afDur;
    }
    return _duration;
  }

  String? get _coverUrl {
    final episodeId = _episodeId;
    final downloadKey = episodeId == null ? _itemId : '$_itemId-$episodeId';
    final localCover = DownloadService().getInfo(downloadKey).localCoverPath;
    if (localCover != null && File(localCover).existsSync()) return localCover;

    if (_isActive) {
      final playingCover = widget.player.currentCoverUrl;
      if (playingCover != null && playingCover.isNotEmpty) return playingCover;
    }

    final lib = context.read<LibraryProvider>();
    return lib.getCoverUrl(_itemId, width: 800);
  }
  bool get _isLocalCover => _coverUrl != null && _coverUrl!.startsWith('/');

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _rawCoverScheme = widget.initialCoverScheme;
    _cardBackground = widget.initialCardBackground;
    _fetchedChapters = widget.initialChapters;
    _fetchedEbookFile = widget.initialEbookFile;
    _currentItemId = widget.player.currentItemId;
    _currentEpisodeId = widget.player.currentEpisodeId;
    _wasPlaying = widget.player.hasBook && _isActive;
    widget.player.addListener(_onPlayerChanged);
    ChromecastService().addListener(_onCastChanged);
    PlayerSettings.settingsChanged.addListener(_reloadButtonOrder);
    _reloadButtonOrder();
    _startChapterTracking();
    _fetchChaptersIfNeeded();
    // Always derive the cover scheme (accent + gradient colors); only build the
    // blurred bitmap when the blurred background is actually in use.
    _deriveCoverScheme();
    if (_cardBackground == 'blurred') _generateBlur();
  }

  void _onCastChanged() {
    if (!mounted || _isPopping) return;
    _startChapterTracking();
    setState(() {});
  }

  /// Which library the live [_item] belongs to, for the per-library cover
  /// shape. [_item] can be a synthetic fallback without a libraryId, so fall
  /// back to the cached absorbing entry and then the player.
  String? _resolveLibraryId() {
    final direct = _item['libraryId'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final lib = context.read<LibraryProvider>();
    final epId = _episodeId;
    final key = epId != null ? '$_itemId-$epId' : _itemId;
    final cached = lib.absorbingItemCache[key]?['libraryId'] as String?;
    if (cached != null && cached.isNotEmpty) return cached;
    if (_itemId == widget.player.currentItemId) return widget.player.currentLibraryId;
    return null;
  }

  void _reloadCoverShape() {
    PlayerSettings.getRectangleCoversFor(_resolveLibraryId()).then((v) {
      if (mounted && v != _rectangleCovers) setState(() => _rectangleCovers = v);
    });
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
    _reloadCoverShape();
    PlayerSettings.getCoverPlayButton().then((v) {
      if (mounted && v != _coverPlayButton) setState(() => _coverPlayButton = v);
    });
    PlayerSettings.getSpeedAdjustedTime().then((v) {
      if (mounted && v != _speedAdjustedTime) setState(() => _speedAdjustedTime = v);
    });
    PlayerSettings.getProgressTextScale().then((v) {
      if (mounted && v != _progressTextScale) setState(() => _progressTextScale = v);
    });
    PlayerSettings.getCardBackground().then((v) {
      if (!mounted) return;
      if (v != _cardBackground) setState(() => _cardBackground = v);
      // Switched to the blurred background after open — build the bitmap now.
      if (v == 'blurred' && _blurredCover == null) _generateBlur();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownRoute ??= ModalRoute.of(context);
    _rederiveCoverScheme();
  }

  @override
  void dispose() {
    PlayerSettings.settingsChanged.removeListener(_reloadButtonOrder);
    if (!_isPopping) {
      widget.player.removeListener(_onPlayerChanged);
      ChromecastService().removeListener(_onCastChanged);
      _chapterTrackSub?.cancel();
    }
    _blurredCover?.dispose();
    super.dispose();
  }

  void _onPlayerChanged() {
    if (!mounted || _isPopping) return;

    // Detect book finished: only dismiss if THIS card's item was playing
    if (_wasPlaying && !widget.player.hasBook) {
      _dismissExpanded();
      return;
    }

    // Detect item change: only react if this card was the active item
    final newItemId = widget.player.currentItemId;
    final newEpisodeId = widget.player.currentEpisodeId;
    if (newItemId != null && _currentItemId == _itemId &&
        (newItemId != _currentItemId || newEpisodeId != _currentEpisodeId)) {
      _handleItemChange(newItemId, newEpisodeId);
    }

    _wasPlaying = widget.player.hasBook && _isActive;
    _currentItemId = newItemId;
    _currentEpisodeId = newEpisodeId;
    setState(() {});
  }

  void _dismissExpanded() {
    if (_isPopping) return;
    _isPopping = true;
    // Remove listeners immediately to prevent further callbacks during pop animation
    widget.player.removeListener(_onPlayerChanged);
    ChromecastService().removeListener(_onCastChanged);
    _chapterTrackSub?.cancel();
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (!nav.canPop()) return;
    // Pop all routes above us (e.g. open modals/sheets) plus our own route
    if (_ownRoute != null) {
      nav.popUntil((route) => route == _ownRoute);
      if (nav.canPop()) nav.pop();
    } else {
      nav.pop();
    }
  }

  void _handleItemChange(String newItemId, String? newEpisodeId) {
    // Try to find the new item data from the library provider
    final lib = context.read<LibraryProvider>();
    Map<String, dynamic>? newItem;

    // Search personalized sections for the new item
    for (final section in lib.personalizedSections) {
      for (final e in (section['entities'] as List<dynamic>? ?? [])) {
        if (e is Map<String, dynamic> && e['id'] == newItemId) {
          newItem = e;
          break;
        }
      }
      if (newItem != null) break;
    }

    // Fallback: synthesize from player data
    final fallbackTitle = mounted ? AppLocalizations.of(context)!.unknown : 'Unknown';
    newItem ??= {
      'id': newItemId,
      'libraryId': widget.player.currentLibraryId,
      'media': {
        'metadata': {
          'title': widget.player.currentTitle ?? fallbackTitle,
          'authorName': widget.player.currentAuthor ?? '',
        },
        'duration': widget.player.totalDuration,
        'chapters': widget.player.chapters,
      },
    };
    if (newEpisodeId != null) {
      newItem['recentEpisode'] = {
        'id': newEpisodeId,
        'title': widget.player.currentEpisodeTitle ?? widget.player.currentTitle,
        'duration': widget.player.totalDuration,
      };
    }

    setState(() {
      _item = newItem!;
      _rawCoverScheme = null;
      _coverBrightness = null;
      _coverProvider = null;
      _fetchedChapters = null;
      _fetchedEbookFile = null;
      _lastChapterIdx = -1;
    });

    // Dispose old blur and regenerate
    _blurredCover?.dispose();
    _blurredCover = null;
    _coverTopLuminance = null;
    _generateBlur();
    _fetchChaptersIfNeeded();
    _startChapterTracking();
    // The new item may belong to a different library (per-library cover shape).
    _reloadCoverShape();
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
          if (sec != _lastChapterIdx) { _lastChapterIdx = sec; if (mounted) setState(() {}); }
          return;
        }
        int idx = 0;
        for (int i = 0; i < chapters.length; i++) {
          final ch = chapters[i] as Map<String, dynamic>;
          final start = (ch['start'] as num?)?.toDouble() ?? 0;
          final end = (ch['end'] as num?)?.toDouble() ?? 0;
          if (posS >= start && posS < end) { idx = i; break; }
        }
        if (idx != _lastChapterIdx) { _lastChapterIdx = idx; if (mounted) setState(() {}); }
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

  Future<void> _fetchChaptersIfNeeded() async {
    // Fetch the full item when either chapters OR the ebook file is missing
    // from the (often minified) inline item, so the "Read" action works.
    final inlineEbook = _media['ebookFile'] as Map<String, dynamic>?;
    if (_chapters.isNotEmpty && inlineEbook != null) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    try {
      final fullItem = await api.getLibraryItem(_itemId);
      if (fullItem != null && mounted) {
        final media = fullItem['media'] as Map<String, dynamic>? ?? {};
        // resolveEbookFile also covers supplementary-only books
        // (audiobooks-only libraries never set media.ebookFile).
        if (inlineEbook == null) {
          final ef = resolveEbookFile(fullItem);
          if (ef != null) setState(() => _fetchedEbookFile = ef);
        }
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
          if (_isActive && widget.player.chapters.isEmpty) {
            widget.player.updateChapters(chapters);
          }
        }
      }
    } catch (_) {}
  }

  void _onCoverLoaded(ImageProvider provider) {
    _coverProvider = provider;
    _rederiveCoverScheme();
  }

  /// Resolve the cover image to derive [_coverScheme] without building the blur
  /// (used by the gradient / off backgrounds, which never paint the cover).
  void _deriveCoverScheme() {
    if (_rawCoverScheme != null || _coverProvider != null) return;
    final url = _coverUrl;
    if (url == null) return;
    final ImageProvider provider;
    if (url.startsWith('/')) {
      provider = FileImage(File(url));
    } else {
      provider = CachedNetworkImageProvider(url, headers: context.read<LibraryProvider>().mediaHeaders);
    }
    _onCoverLoaded(provider);
  }

  void _rederiveCoverScheme() {
    final provider = _coverProvider;
    if (provider == null) return;
    final brightness = Theme.of(context).brightness;
    if (_rawCoverScheme != null && _coverBrightness == brightness) return;
    _coverBrightness = brightness;
    ColorScheme.fromImageProvider(provider: provider, brightness: brightness)
        .then((s) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _rawCoverScheme = s);
            });
          }
        })
        .catchError((_) {});
  }

  /// Generate our own blurred cover from the current cover URL.
  Future<void> _generateBlur() async {
    final url = _coverUrl;
    if (url == null) return;

    try {
      final ImageProvider provider;
      if (url.startsWith('/')) {
        provider = FileImage(File(url));
      } else {
        final lib = context.read<LibraryProvider>();
        provider = CachedNetworkImageProvider(url, headers: lib.mediaHeaders);
      }

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

      final topLuminance = await topStripLuminance(blurred);

      if (mounted) {
        setState(() {
          _blurredCover = blurred;
          _coverTopLuminance = topLuminance;
        });
      } else {
        blurred.dispose();
      }

      // Also derive cover scheme if needed
      if (_rawCoverScheme == null) _onCoverLoaded(provider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // E-ink mode: the cover-derived palette renders as washed-out grey, so
    // the card sticks to the monochrome app theme.
    final cs = (PlayerSettings.einkMode ? null : _coverScheme) ??
        Theme.of(context).colorScheme;
    final accent = cs.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    final lib = context.watch<LibraryProvider>();
    final mediaHeaders = lib.mediaHeaders;
    final progress = (_episodeId != null)
        ? lib.getEpisodeProgress(_itemId, _episodeId!)
        : (_isPodcastEpisode
            ? lib.getEpisodeProgress(_itemId, widget.player.currentEpisodeId!)
            : lib.getProgress(_itemId));
    final bool isFinished;
    if (_episodeId != null) {
      isFinished = lib.getEpisodeProgressData(_itemId, _episodeId!)?['isFinished'] == true;
    } else if (_isPodcastEpisode) {
      isFinished = lib.getEpisodeProgressData(_itemId, widget.player.currentEpisodeId!)?['isFinished'] == true;
    } else {
      isFinished = lib.getProgressData(_itemId)?['isFinished'] == true;
    }
    final chapterIdx = _currentChapterIndex();
    final cast = ChromecastService();
    final totalChapters = _isCastingThis ? cast.castingChapters.length : (_isActive ? widget.player.chapters.length : _chapters.length);
    // A chapterless book gets the same single-bar look as a chapterless
    // podcast: no top book bar, just the scrubber carrying the title.
    final showBookBar = _chapters.isNotEmpty;
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

    return GestureDetector(
      onVerticalDragEnd: (details) {
        final vy = details.primaryVelocity ?? 0;
        if (vy > 300) _dismissExpanded(); // swipe down to collapse
      },
      child: Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Card background (blurred cover / color gradient / plain surface)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: _buildBackground(isDark, cs, mediaHeaders),
                ),
                // Layer 2: Scrim
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        // Lighter scrim over the gradient/off backgrounds so the cover
                        // tint reads through; the blurred photo still needs the heavier one.
                        colors: _cardBackground == 'blurred'
                          ? (isDark
                              ? [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.black.withValues(alpha: 0.85),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.4),
                                  Colors.white.withValues(alpha: 0.7),
                                  Colors.white.withValues(alpha: 0.9),
                                ])
                          : (isDark
                              ? [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.black.withValues(alpha: 0.68),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.25),
                                  Colors.white.withValues(alpha: 0.55),
                                  Colors.white.withValues(alpha: 0.8),
                                ]),
                      ),
                    ),
                  ),
                ),
                // Layer 3: Content
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, outerConstraints) {
                    final compact = outerConstraints.maxHeight < 600;
                    // Landscape: split into left (cover) + right (controls/info).
                    final wide = outerConstraints.maxWidth > outerConstraints.maxHeight;

                    // Same story as the small card: the scrim is thinnest at
                    // the top, so on a blurred background take the ink from
                    // the cover rather than from the theme.
                    final coverLuminance =
                        _cardBackground == 'blurred' ? _coverTopLuminance : null;
                    final ink = coverLuminance == null
                        ? null
                        : inkForLuminance(scrimmedLuminance(
                            coverLuminance,
                            isDark ? Colors.black : Colors.white,
                            isDark ? 0.3 : 0.4,
                          ));
                    final statsRow = Padding(
                        padding: EdgeInsets.fromLTRB(24, compact ? 4 : 6, 24, 0),
                        child: Center(
                          child: Text('${(bookProgress * 100).clamp(0, 100).toStringAsFixed(1)}%',
                            style: tt.labelSmall?.copyWith(
                              color: ink?.ink ??
                                  (isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.45)),
                              fontWeight: FontWeight.w500, fontSize: (compact ? 10 : 11) * _progressTextScale,
                              fontFeatures: const [ui.FontFeature.tabularFigures()],
                              shadows: [Shadow(color: ink?.shadow ?? (isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6)), blurRadius: 4)],
                            )),
                        ),
                      );

                    final bookProgressBar = Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CardDualProgressBar(player: widget.player, accent: accent, isActive: _isActive, staticProgress: progress, staticDuration: _effectiveDuration, chapters: _chapters, showBookBar: showBookBar, showChapterBar: false, itemId: _itemId, showCenterPercent: true),
                      );

                    final coverArea = Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ListenableBuilder(
                            listenable: ChromecastService(),
                            builder: (context, _) => LayoutBuilder(
                              builder: (context, constraints) {
                                final maxW = constraints.maxWidth * 0.95;
                                final maxH = constraints.maxHeight - 24;
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
                                final coverLoading = _isStarting || (_isActive && widget.player.isLoadingOrBuffering);
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
                                      widget.player.togglePlayPause(fromUi: true);
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
                                          EinkCoverTone(child: _coverUrl != null
                                              ? _isLocalCover
                                                  ? BlurPaddedCover(blurChild: Image.file(File(_coverUrl!), fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                                      enabled: !_rectangleCovers, child: Image.file(File(_coverUrl!), fit: _rectangleCovers ? BoxFit.cover : BoxFit.contain,
                                                      errorBuilder: (_, __, ___) => CoverPlaceholder(title: _title, author: _author)))
                                                  : BlurPaddedCover(blurChild: CachedNetworkImage(imageUrl: _coverUrl!, fit: BoxFit.cover,
                                                        httpHeaders: mediaHeaders,
                                                        errorWidget: (_, __, ___) => const SizedBox.shrink()),
                                                      enabled: !_rectangleCovers, child: CachedNetworkImage(imageUrl: _coverUrl!, fit: _rectangleCovers ? BoxFit.cover : BoxFit.contain,
                                                        httpHeaders: mediaHeaders,
                                                        placeholder: (_, __) => CoverPlaceholder(title: _title, author: _author),
                                                        errorWidget: (_, __, ___) => CoverPlaceholder(title: _title, author: _author)))
                                              : CoverPlaceholder(title: _title, author: _author)),
                                          // Play/pause overlay
                                          if (_coverPlayButton && !isCastingThis && !isFinished)
                                            Positioned.fill(
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                decoration: BoxDecoration(
                                                  color: coverPlaying ? Colors.transparent : Colors.black.withValues(alpha: 0.25),
                                                ),
                                                child: Center(
                                                  child: coverLoading
                                                      ? Container(
                                                          width: 70, height: 70,
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
                                                            width: 76, height: 76,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: Colors.black.withValues(alpha: 0.45),
                                                            ),
                                                            child: Icon(
                                                              coverPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                              size: 44, color: accent,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
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
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
                                  ],
                                ));
                              },
                            ),
                          ),
                        );

                    final chapterScrubber = Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CardDualProgressBar(player: widget.player, accent: accent, isActive: _isActive, staticProgress: (_isPodcastEpisode && _chapters.isEmpty) ? 0.0 : progress, staticDuration: (_isPodcastEpisode && _chapters.isEmpty) ? widget.player.totalDuration : _effectiveDuration, chapters: _chapters, showBookBar: false, showChapterBar: true, chapterName: (_isPodcastEpisode && _chapters.isEmpty) ? (widget.player.currentEpisodeTitle ?? widget.player.currentTitle ?? _title) : (_episodeId != null && !_isActive ? (_recentEpisode?['title'] as String? ?? _title) : (_chapters.isEmpty ? _title : _chapterName(chapterIdx))), chapterIndex: chapterIdx, totalChapters: totalChapters, itemId: _itemId),
                      );

                    final controlsAndButtons = MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.noScaling,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: compact ? 4 : 18),
                                    CardPlaybackControls(
                                      player: widget.player,
                                      accent: accent,
                                      isActive: _isActive,
                                      isStarting: _isStarting,
                                      onStart: _startPlayback,
                                      itemId: _itemId,
                                      showPlayButton: !_coverPlayButton,
                                      playButtonSize: 70,
                                      libraryId: _resolveLibraryId(),
                                    ),
                                    SizedBox(height: compact ? 8 : 24),
                                    ..._buildButtonGrid(accent, tt),
                                    SizedBox(height: compact ? 4 : 14),
                                    if (!_moreInline) ...[
                                    Center(
                                      child: ListenableBuilder(
                                        listenable: ChromecastService(),
                                        builder: (context, _) {
                                          final castActive = ChromecastService().isCasting && !_buttonOrder.take(_visibleButtonCount).contains('cast');
                                          return Pressable(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _showMoreMenu(context, accent, tt),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: castActive ? accent.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(22),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: castActive
                                                    ? [
                                                        Icon(Icons.cast_connected_rounded, size: 20, color: accent),
                                                        const SizedBox(width: 6),
                                                        Text(l.casting, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: accent)),
                                                      ]
                                                    : [
                                                        Icon(Icons.more_horiz_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.54)),
                                                        const SizedBox(width: 6),
                                                        Text(l.more, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.54))),
                                                      ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    ],
                                    SizedBox(height: compact ? 4 : 12),
                                  ],
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
                              // The book bar carries the percent centered in
                              // its time row; the standalone line is only for
                              // layouts with no book bar at all.
                              if (!showBookBar) statsRow,
                              if (showBookBar) bookProgressBar,
                              if (showBookBar) SizedBox(height: compact ? 4 : 16),
                              chapterScrubber,
                              controlsAndButtons,
                            ],
                          )),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        // The book bar carries the percent centered in its
                        // time row; the standalone line is only for layouts
                        // with no book bar at all.
                        if (!showBookBar) statsRow,
                        if (showBookBar) bookProgressBar,
                        if (showBookBar) SizedBox(height: compact ? 4 : 8),
                        Expanded(child: coverArea),
                        SizedBox(height: compact ? 6 : 12),
                        chapterScrubber,
                        controlsAndButtons,
                      ],
                    );
                  }),
                ),
              ],
            ),
    ),
    );
  }

  // ── Background builder ──

  Widget _buildBackground(bool isDark, ColorScheme cs, Map<String, String> mediaHeaders) {
    if (_cardBackground == 'off') {
      // SizedBox.expand: the AnimatedSwitcher's Stack gives loose constraints,
      // so an unsized box would collapse to 0x0 and never show.
      return SizedBox.expand(
        key: const ValueKey('bg-off'),
        child: ColoredBox(color: Theme.of(context).colorScheme.surface),
      );
    }
    if (_cardBackground == 'gradient') {
      return SizedBox.expand(
        key: const ValueKey('bg-gradient'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.primaryContainer, cs.surface],
            ),
          ),
        ),
      );
    }
    if (_blurredCover != null) {
      return RepaintBoundary(
        key: ValueKey('blur-$_itemId'),
        child: RawImage(
          image: _blurredCover,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    if (_coverUrl != null) {
      return RepaintBoundary(
        key: ValueKey('cover-$_itemId'),
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
      );
    }
    return Container(key: const ValueKey('empty'), color: isDark ? Colors.black : Colors.white);
  }

  // ── Helpers (mirrored from AbsorbingCard) ──

  int _currentChapterIndex() {
    final cast = ChromecastService();
    final chapters = _isCastingThis ? cast.castingChapters : (_isActive ? widget.player.chapters : _chapters);
    if (chapters.isEmpty) return -1;
    double pos;
    if (_isCastingThis) {
      pos = cast.castPosition.inMilliseconds / 1000.0;
    } else if (_isActive) {
      pos = widget.player.position.inMilliseconds / 1000.0;
    } else {
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
    if (pos > 0 && chapters.isNotEmpty) return chapters.length - 1;
    return 0;
  }

  String? _chapterName(int chapterIdx) {
    if (_isCastingThis) {
      final ch = ChromecastService().currentChapter;
      return ch?['title'] as String?;
    }
    if (_isActive && widget.player.currentChapter != null) {
      return widget.player.currentChapter!['title'] as String?;
    }
    if (chapterIdx >= 0 && chapterIdx < _chapters.length) {
      final ch = _chapters[chapterIdx] as Map<String, dynamic>;
      return ch['title'] as String?;
    }
    return null;
  }

  // ── Playback actions ──

  Future<void> _startPlayback() async {
    if (_isStarting) return;
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
      libraryId: _resolveLibraryId(),
      fromUi: true,
    );
    if (mounted) {
      if (error != null) showErrorToast(context, error);
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
      final key = _episodeId != null ? '$_itemId-$_episodeId' : _itemId;
      await lib.removeFromAbsorbing(key);
    }
  }

  // ── Dynamic button builders (delegated) ─────────────────────

  CardActionDelegate _makeActions() => CardActionDelegate(
    context: context,
    player: widget.player,
    item: _item,
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
    savedSpeed: 1.0,
    visibleCount: _buttonVisibleCount,
    iconsOnly: _iconsOnly,
    moreInline: _moreInline,
    buttonOrder: _buttonOrder,
    removeFromAbsorbing: _removeFromAbsorbing,
    onRemoveExtra: _dismissExpanded,
    onReorder: (newOrder, newCount) {
      setState(() { _buttonOrder = newOrder; _buttonVisibleCount = newCount; });
      PlayerSettings.setCardButtonOrder(newOrder);
      PlayerSettings.setCardButtonVisibleCount(newCount);
    },
    isEbookPdf: _ebookExt == 'pdf',
    onEbookTap: _openReader,
    onFindInEbookTap: _findInEbook,
  );

  Map<String, dynamic>? get _ebookFile =>
      (_media['ebookFile'] as Map<String, dynamic>?) ?? _fetchedEbookFile;
  String? get _ebookExt {
    final ext = ebookExt(_ebookFile);
    return ext.isEmpty ? null : ext;
  }

  void _openReader() async {
    var ef = _ebookFile;
    // A downloaded book's ebook may already sit in the reader cache - check
    // that before any network retry, so offline Read opens instantly instead
    // of waiting out a timeout. The reader opens from this same cached file
    // either way.
    ef ??= await cachedEbookFileFor(_itemId);
    if (ef == null) {
      // The initState fetch is one-shot and can fail silently (network blip),
      // so give it another chance before declaring there's no ebook.
      await _fetchChaptersIfNeeded();
      ef = _ebookFile;
    }
    if (!mounted) return;
    if (ef == null) {
      showOverlayToast(context, AppLocalizations.of(context)!.noEbookFileFound, icon: Icons.menu_book_outlined);
      return;
    }
    openEbookReader(context, itemId: _itemId, title: _title, ebookFile: ef);
  }

  void _findInEbook() async {
    var ef = _ebookFile;
    ef ??= await cachedEbookFileFor(_itemId);
    if (ef == null) {
      await _fetchChaptersIfNeeded();
      ef = _ebookFile;
    }
    if (!mounted) return;
    launchFindInEbook(context, itemId: _itemId, title: _title, ebookFile: ef);
  }

  int get _visibleButtonCount => _buttonVisibleCount;

  List<Widget> _buildButtonGrid(Color accent, TextTheme tt) => _makeActions().buildButtonGrid(accent, tt);

  void _showMoreMenu(BuildContext context, Color accent, TextTheme tt) => _makeActions().showMoreMenu(accent, tt);
}

