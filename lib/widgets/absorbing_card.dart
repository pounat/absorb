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
import '../screens/app_shell.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import 'absorbing_shared.dart';
import 'ebook_router.dart';
import 'overlay_toast.dart';
import '../services/ebook_cache.dart';
import '../services/find_in_ebook.dart';
import '../services/lyrics_service.dart';
import 'lyrics_overlay.dart';
import 'card_edge_progress_bar.dart';
import 'card_progress_bar.dart';
import 'card_playback_controls.dart';
import 'card_buttons.dart';
import '../services/chromecast_service.dart';
import 'expanded_card.dart';
import '../main.dart' show colorSourceNotifier, useColorEverywhereNotifier, manualSeedNotifier, manualColorScheme;
import 'stable_cached_network_image.dart';

class AbsorbingCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final AudioPlayerService player;
  const AbsorbingCard({super.key, required this.item, required this.player});

  @override
  State<AbsorbingCard> createState() => AbsorbingCardState();
}

class AbsorbingCardState extends State<AbsorbingCard> with AutomaticKeepAliveClientMixin {
  ColorScheme? _rawCoverScheme;
  Brightness? _coverBrightness; // brightness used to generate _coverScheme

  /// Cover-derived scheme, unless a manual app color is set to apply everywhere.
  ColorScheme? get _coverScheme {
    if (colorSourceNotifier.value == 'manual' && useColorEverywhereNotifier.value) {
      return manualColorScheme(manualSeedNotifier.value, Theme.of(context).brightness);
    }
    return _rawCoverScheme;
  }
  ImageProvider? _coverProvider; // cached for re-deriving on theme change
  String? _coverProviderIdentity;
  bool _isStarting = false;
  List<dynamic>? _fetchedChapters;
  Map<String, dynamic>? _fetchedEbookFile;
  // Server-change tick last acted on, so a same-id item_updated (e.g. an ebook
  // file added to this book) re-runs the full-item fetch. The card is kept
  // alive with a stable key, so without this it never picks up a server change.
  int? _lastSeenUpdatedAt;
  bool _refetchingItem = false;
  StreamSubscription<Duration>? _chapterTrackSub;
  int _lastChapterIdx = -1;
  ui.Image? _blurredCover; // Precached blurred background
  String? _blurredCoverIdentity;
  String? _pendingBlurIdentity;
  // Mean brightness of the blurred cover's top strip, which is what the
  // progress row is drawn on. Null until the blur is ready, or when the card
  // isn't using the blurred background at all.
  double? _coverTopLuminance;
  List<String> _buttonOrder = PlayerSettings.defaultButtonOrder;
  int _buttonVisibleCount = PlayerSettings.defaultButtonVisibleCount;
  bool _iconsOnly = false;
  bool _moreInline = false;
  bool _rectangleCovers = false;
  bool _coverPlayButton = false;
  String _cardBackground = 'blurred';
  bool _speedAdjustedTime = true;
  double _progressTextScale = 1.0; // elapsed/remaining/percent text size (GH #230)
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
  Map<String, dynamic>? get _ebookFile =>
      (_media['ebookFile'] as Map<String, dynamic>?) ?? _fetchedEbookFile;
  String? get _ebookExt {
    final ext = ebookExt(_ebookFile);
    return ext.isEmpty ? null : ext;
  }
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
    return lib.getCoverUrl(_itemId, width: 1200);
  }

  int? _coverUpdatedAt(LibraryProvider lib) {
    final key = widget.item['_absorbingKey'] as String? ?? _itemId;
    final cached = lib.absorbingItemCache[key];
    final candidates = <Object?>[
      widget.item['updatedAt'],
      cached?['updatedAt'],
      lib.itemUpdatedAt(_itemId),
    ];

    int? newest;
    for (final candidate in candidates) {
      final timestamp = switch (candidate) {
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      };
      if (timestamp != null && (newest == null || timestamp > newest)) {
        newest = timestamp;
      }
    }
    return newest;
  }

  String? _coverIdentity(String? coverUrl, LibraryProvider lib) {
    if (coverUrl == null) return null;
    if (coverUrl.startsWith('/')) return coverUrl;
    return stableCoverCacheKey(
      coverUrl,
      updatedAt: _coverUpdatedAt(lib),
    );
  }

  String? _currentCoverIdentity() {
    final lib = context.read<LibraryProvider>();
    return _coverIdentity(lib.getCoverUrl(_itemId, width: 1200), lib);
  }

  @override
  void initState() {
    super.initState();
    // Baseline the server-change tick so only a CHANGE after mount re-fetches
    // (the initial fill is handled by _fetchChaptersIfNeeded below).
    _lastSeenUpdatedAt = context.read<LibraryProvider>().itemUpdatedAt(_itemId);
    _fetchChaptersIfNeeded();
    _startChapterTracking();
    ChromecastService().addListener(_onCastChanged);
    DownloadService().addListener(_onDownloadChanged);
    PlayerSettings.settingsChanged.addListener(_reloadButtonOrder);
    _reloadButtonOrder();
  }

  void _onSpeedMaybeChanged() => _loadSavedSpeed();

  /// Which library this card's item belongs to, for the per-library cover
  /// shape. The absorbing shelf item can be a lean/synthetic map without a
  /// libraryId (especially with merge on, where podcast items are pulled from
  /// other libraries), so fall back to the cached absorbing entry and then to
  /// the player when this is the item currently playing.
  String? _resolveLibraryId() {
    final direct = widget.item['libraryId'] as String?;
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
      if (mounted && v != _cardBackground) setState(() => _cardBackground = v);
    });
    _loadSavedSpeed();
  }

  void _onDownloadChanged() { if (mounted) setState(() {}); }

  void _onCastChanged() {
    _startChapterTracking();
    if (mounted) setState(() {});
  }

  Future<void> _fetchChaptersIfNeeded() async {
    // Skip when the inline item already has both chapters and ebookFile
    final inlineEbook = _media['ebookFile'] as Map<String, dynamic>?;
    if (_chapters.isNotEmpty && inlineEbook != null) return;
    // Fetch full item to fill in whatever's missing
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    try {
      final fullItem = await api.getLibraryItem(_itemId);
      if (fullItem != null && mounted) {
        final media = fullItem['media'] as Map<String, dynamic>? ?? {};
        // Cache ebookFile if the inline item didn't have it. resolveEbookFile
        // also covers supplementary-only books (audiobooks-only libraries
        // never set media.ebookFile).
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
          // If this is the active item and player has no chapters, update them
          if (_isActive && widget.player.chapters.isEmpty) {
            widget.player.updateChapters(chapters);
          }
        }
      }
    } catch (_) {}
  }

  /// Re-fetch the full item when the server reports this book changed (socket
  /// item_updated bumps the provider's per-item tick). Targets the case where
  /// an ebook file is added while the app is open: the card's minified entity
  /// never carries ebookFile and the one-time initState fetch found none, so
  /// the "Read" action would stay disabled until a restart. Only fires while
  /// the ebook is still missing, so ordinary cover/metadata updates don't
  /// trigger needless fetches.
  void _maybeRefetchOnServerChange(LibraryProvider lib) {
    final ts = lib.itemUpdatedAt(_itemId);
    if (ts == _lastSeenUpdatedAt) return;
    _lastSeenUpdatedAt = ts;
    // The cover may have changed server-side. Drop the cached provider and
    // accent scheme so they re-derive from the new cache-busted URL (the
    // blurred background already re-derives itself on URL change in build).
    _coverProvider = null;
    _rawCoverScheme = null;
    if (_ebookFile != null || _refetchingItem) return;
    _refetchingItem = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _fetchChaptersIfNeeded();
      } finally {
        _refetchingItem = false;
      }
    });
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
      _rawCoverScheme = null;
      _coverBrightness = null;
      _coverProvider = null;
      _coverProviderIdentity = null;
      _blurredCover?.dispose();
      _blurredCover = null;
      _blurredCoverIdentity = null;
      _pendingBlurIdentity = null;
      _coverTopLuminance = null;
      _fetchedChapters = null;
      _fetchedEbookFile = null;
      _lastChapterIdx = -1;
      _lastSeenUpdatedAt = context.read<LibraryProvider>().itemUpdatedAt(_itemId);
      _fetchChaptersIfNeeded();
      // The per-show speed is item state too - without this, a card recycled
      // for a different item shows times computed at the old item's speed.
      _loadSavedSpeed();
    }
    // Re-resolve the cover shape: the item (or its libraryId) may have changed,
    // or the player may now know the library for the item that just started.
    _reloadCoverShape();
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

  void _onCoverLoaded(ImageProvider provider, String coverIdentity) {
    if (_currentCoverIdentity() != coverIdentity) return;
    if (_coverProviderIdentity != coverIdentity) {
      _rawCoverScheme = null;
      _coverBrightness = null;
    }
    _coverProvider = provider;
    _coverProviderIdentity = coverIdentity;
    _rederiveCoverScheme();
    // Precache the blurred version of the cover, but only when the blurred
    // background is actually in use (skip the work for gradient / off modes).
    if (_cardBackground == 'blurred' &&
        _blurredCoverIdentity != coverIdentity &&
        _pendingBlurIdentity != coverIdentity) {
      _pendingBlurIdentity = coverIdentity;
      _precacheBlur(provider, coverIdentity);
    }
  }

  /// In gradient/off mode the cover image isn't painted, so resolve it directly
  /// to keep the extracted [_coverScheme] (accent + gradient colors) available.
  void _ensureCoverScheme(
    String? coverUrl,
    String? coverIdentity,
    LibraryProvider lib,
  ) {
    if (coverUrl == null || coverIdentity == null) return;
    if (_coverProvider != null && _coverProviderIdentity == coverIdentity) {
      return;
    }
    final headers = lib.mediaHeaders;
    final ImageProvider provider;
    if (coverUrl.startsWith('/')) {
      provider = FileImage(File(coverUrl));
    } else {
      provider = CachedNetworkImageProvider(
        coverUrl,
        headers: headers,
        cacheKey: coverIdentity,
      );
    }
    _onCoverLoaded(provider, coverIdentity);
  }

  void _rederiveCoverScheme() {
    final provider = _coverProvider;
    final coverIdentity = _coverProviderIdentity;
    if (provider == null || coverIdentity == null) return;
    final brightness = Theme.of(context).brightness;
    if (_rawCoverScheme != null && _coverBrightness == brightness) return;
    _coverBrightness = brightness;
    ColorScheme.fromImageProvider(provider: provider, brightness: brightness)
        .then((s) {
          if (mounted &&
              _coverProviderIdentity == coverIdentity &&
              _coverBrightness == brightness) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _coverProviderIdentity == coverIdentity &&
                  _coverBrightness == brightness) {
                setState(() => _rawCoverScheme = s);
              }
            });
          }
        })
        .catchError((_) {});
  }

  /// Resolve the image, render it blurred to an offscreen canvas, cache the result.
  Future<void> _precacheBlur(
    ImageProvider provider,
    String coverIdentity,
  ) async {
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

      final topLuminance = await topStripLuminance(blurred);

      if (mounted && _currentCoverIdentity() == coverIdentity) {
        final previous = _blurredCover;
        setState(() {
          _blurredCover = blurred;
          _blurredCoverIdentity = coverIdentity;
          _coverTopLuminance = topLuminance;
        });
        previous?.dispose();
      } else {
        blurred.dispose();
      }
    } catch (_) {
      // Fallback: card will show without blurred background, which is fine
    } finally {
      if (_pendingBlurIdentity == coverIdentity) {
        _pendingBlurIdentity = null;
      }
    }
  }


  /// The store key the live transcript runs under for this card.
  String get _lyricsKey =>
      _episodeId != null ? '$_itemId-$_episodeId' : _itemId;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    // E-ink mode: the cover-derived palette renders as washed-out grey, so
    // the card sticks to the monochrome app theme.
    final cs = (PlayerSettings.einkMode ? null : _coverScheme) ??
        Theme.of(context).colorScheme;
    final accent = cs.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    final lib = context.watch<LibraryProvider>();
    final coverUrl = lib.getCoverUrl(_itemId, width: 1200);
    final coverIdentity = _coverIdentity(coverUrl, lib);
    final isLocalCover = coverUrl?.startsWith('/') ?? false;
    _maybeRefetchOnServerChange(lib);
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

    // In gradient/off mode the cover image isn't painted, so derive its scheme separately.
    if (_cardBackground != 'blurred') {
      _ensureCoverScheme(coverUrl, coverIdentity, lib);
    }

    final tt = Theme.of(context).textTheme;
    final mediaHeaders = lib.mediaHeaders;
    // A chapterless book gets the same single-bar look as a chapterless
    // podcast: no top book bar, just the scrubber bar carrying the title.
    final showBookBar = _chapters.isNotEmpty;
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
          // Layer 1: Card background — blurred cover, color gradient, or plain surface
          if (_cardBackground == 'off')
            ColoredBox(color: Theme.of(context).colorScheme.surface)
          else if (_cardBackground == 'gradient')
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primaryContainer, cs.surface],
                ),
              ),
            )
          // Pre-blurred cover background (cached bitmap — no per-frame blur)
          else if (_blurredCover != null)
            RepaintBoundary(
              child: RawImage(
                image: _blurredCover,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          else if (coverUrl != null && coverIdentity != null)
            // Fallback while blur is being computed: show unblurred cover dimmed
            RepaintBoundary(
              child: isLocalCover
                  ? Builder(builder: (_) {
                      final provider = FileImage(File(coverUrl));
                      _onCoverLoaded(provider, coverIdentity);
                      return Opacity(
                        opacity: 0.3,
                        child: Image.file(File(coverUrl), fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Container(color: isDark ? Colors.black : Colors.white)),
                      );
                    })
                  : StableCachedNetworkImage(
                      imageUrl: coverUrl,
                      cacheKey: coverIdentity,
                      fit: BoxFit.cover,
                      httpHeaders: mediaHeaders,
                      imageBuilder: (_, provider) {
                        _onCoverLoaded(provider, coverIdentity);
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
                      // This row sits on the cover, not on the theme surface.
                      // With a blurred background the scrim is at its thinnest
                      // right here (0.3 / 0.4), so a pale cover in dark mode
                      // used to leave white text on a near-white backdrop.
                      // Pick the ink from what is actually behind it; the other
                      // background modes follow the theme as before.
                      final coverLuminance =
                          _cardBackground == 'blurred' ? _coverTopLuminance : null;
                      final ink = coverLuminance == null
                          ? null
                          : inkForLuminance(scrimmedLuminance(
                              coverLuminance,
                              isDark ? Colors.black : Colors.white,
                              isDark ? 0.3 : 0.4,
                            ));
                      final timeStyle = tt.labelSmall?.copyWith(
                        color: ink?.ink ??
                            (isDark ? Colors.white.withValues(alpha: 0.55) : cs.onSurface),
                        fontWeight: FontWeight.w500, fontSize: (compact ? 10 : 11) * _progressTextScale,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: [Shadow(color: ink?.shadow ?? (isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6)), blurRadius: 4)],
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
                      final maxW = constraints.maxWidth * 0.85;
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
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Spacer(flex: 2),
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
                                // Cover image - hidden while the transcript
                                // has the cover.
                                AnimatedBuilder(
                                  animation: LyricsService.instance,
                                  builder: (context, child) =>
                                      LyricsService.instance
                                              .coversArtFor(_lyricsKey)
                                          ? Offstage(child: child)
                                          : child!,
                                  child: EinkCoverTone(child: coverUrl != null && coverIdentity != null
                                    ? isLocalCover
                                        ? BlurPaddedCover(blurChild: Image.file(File(coverUrl), fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                            enabled: !_rectangleCovers, child: Image.file(File(coverUrl), fit: _rectangleCovers ? BoxFit.cover : BoxFit.contain,
                                            gaplessPlayback: true,
                                            errorBuilder: (_, __, ___) => CoverPlaceholder(title: _title, author: _author)))
                                        : BlurPaddedCover(blurChild: StableCachedNetworkImage(imageUrl: coverUrl, cacheKey: coverIdentity, fit: BoxFit.cover,
                                              httpHeaders: mediaHeaders,
                                              errorWidget: (_, __, ___) => const SizedBox.shrink()),
                                            enabled: !_rectangleCovers, child: StableCachedNetworkImage(imageUrl: coverUrl, cacheKey: coverIdentity,
                                              fit: _rectangleCovers ? BoxFit.cover : BoxFit.contain,
                                              httpHeaders: mediaHeaders,
                                              imageBuilder: (_, provider) {
                                                _onCoverLoaded(provider, coverIdentity);
                                                return Image(image: provider, fit: _rectangleCovers ? BoxFit.cover : BoxFit.contain);
                                              },
                                              placeholder: (_, __) => CoverPlaceholder(title: _title, author: _author),
                                              errorWidget: (_, __, ___) => CoverPlaceholder(title: _title, author: _author)))
                                    : CoverPlaceholder(title: _title, author: _author))),
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
                                // Play/pause overlay - the tap still works
                                // with the transcript up, but the button would
                                // sit on the words.
                                if (_coverPlayButton) Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: LyricsService.instance,
                                    builder: (context, child) =>
                                        LyricsService.instance
                                                .coversArtFor(_lyricsKey)
                                            ? Offstage(child: child)
                                            : child!,
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
                                )),
                                // Live transcript (lyrics mode)
                                LyricsOverlay(
                                    compact: true,
                                    forKey: _lyricsKey,
                                    surface: cs.surface,
                                    onSurface: cs.onSurface),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ),
                      const Spacer(flex: 2),
                      ]);
                    },
                  ),
                  ),
              );

          final scrubberBar = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CardDualProgressBar(player: widget.player, accent: accent, isActive: _isActive, staticProgress: (_isPodcastEpisode && _chapters.isEmpty) ? 0.0 : progress, staticDuration: (_isPodcastEpisode && _chapters.isEmpty) ? widget.player.totalDuration : _effectiveDuration, chapters: _chapters, showBookBar: false, showChapterBar: true, chapterName: (_isPodcastEpisode && _chapters.isEmpty) ? (widget.player.currentEpisodeTitle ?? widget.player.currentTitle ?? _title) : (_episodeId != null && !_isActive ? (_recentEpisode?['title'] as String? ?? _title) : (_chapters.isEmpty ? _title : _chapterName(chapterIdx))), chapterIndex: chapterIdx, totalChapters: totalChapters, itemId: _itemId, compact: compact),
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
                    libraryId: _resolveLibraryId(),
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

  void _openEbookReader() async {
    var ebookFile = _ebookFile;
    // A downloaded book's ebook may already sit in the reader cache - check
    // that before any network retry, so offline Read opens instantly instead
    // of waiting out a timeout. The reader opens from this same cached file
    // either way.
    ebookFile ??= await cachedEbookFileFor(_itemId);
    if (ebookFile == null) {
      // The initState fetch is one-shot and can fail silently (network blip),
      // so give it another chance before declaring there's no ebook.
      await _fetchChaptersIfNeeded();
      ebookFile = _ebookFile;
    }
    if (!mounted) return;
    if (ebookFile == null) {
      showOverlayToast(context, AppLocalizations.of(context)!.noEbookFileFound, icon: Icons.menu_book_outlined);
      return;
    }
    openEbookReader(context, itemId: _itemId, title: _title, ebookFile: ebookFile);
  }

  void _findInEbook() async {
    var ebookFile = _ebookFile;
    ebookFile ??= await cachedEbookFileFor(_itemId);
    if (ebookFile == null) {
      await _fetchChaptersIfNeeded();
      ebookFile = _ebookFile;
    }
    if (!mounted) return;
    launchFindInEbook(context, itemId: _itemId, title: _title, ebookFile: ebookFile);
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
          initialEbookFile: _ebookFile,
          initialCardBackground: _cardBackground,
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
    isEbookPdf: _ebookExt == 'pdf',
    onEbookTap: _openEbookReader,
    onFindInEbookTap: _findInEbook,
  );

  int get _visibleButtonCount => _buttonVisibleCount;

  List<Widget> _buildButtonGrid(Color accent, TextTheme tt) => _makeActions().buildButtonGrid(accent, tt);

  void _showMoreMenu(BuildContext context, Color accent, TextTheme tt) => _makeActions().showMoreMenu(accent, tt);

}
