import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/audio_player_service.dart';
import '../services/chapter_lookup.dart';
import '../services/chromecast_service.dart';
import 'absorb_slider.dart';

// ─── DUAL PROGRESS BAR (card version) ───────────────────────

class CardDualProgressBar extends StatefulWidget {
  final AudioPlayerService player;
  final Color accent;
  final bool isActive;
  final double staticProgress;
  final double staticDuration;
  final List<dynamic> chapters;
  final bool showBookBar;
  final bool showChapterBar;
  final String? chapterName;
  final int chapterIndex;
  final int totalChapters;
  final String? itemId;
  final bool compact;
  final bool showBookPercentage;
  const CardDualProgressBar({super.key, required this.player, required this.accent, required this.isActive, required this.staticProgress, required this.staticDuration, required this.chapters, this.showBookBar = true, this.showChapterBar = true, this.chapterName, this.chapterIndex = 0, this.totalChapters = 0, this.itemId, this.compact = false, this.showBookPercentage = false});
  @override State<CardDualProgressBar> createState() => _CardDualProgressBarState();
}

class _CardDualProgressBarState extends State<CardDualProgressBar> with WidgetsBindingObserver {
  double? _chapterDragValue;
  double? _bookDragValue;
  double _bookDragStartDy = 0;
  double _chapterDragStartDy = 0;
  double _bookScrubSpeed = 1.0;
  double _chapterScrubSpeed = 1.0;
  CardScrubberMode _scrubberMode = CardScrubberMode.chapter;
  bool _speedAdjustedTime = true;
  Timer? _smoothTicker;
  final _tickNotifier = ChangeNotifier(); // drives ListenableBuilder rebuilds

  // Smooth position tracking
  double _lastKnownPos = 0;
  DateTime _lastPosTime = DateTime.now();
  double _currentSpeed = 1.0;
  // Per-item speed used for the time display while the card is inactive,
  // so the expanded card's book time row matches the small card's behavior
  // when speed-adjusted time is enabled.
  double _savedSpeed = 1.0;
  double _progressTextScale = 1.0;
  bool _isPlaying = false;
  bool _isCastMode = false;
  StreamSubscription<Duration>? _posSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _subscribePosition();
    PlayerSettings.settingsChanged.addListener(_loadSettings);
    ChromecastService().addListener(_onCastChanged);
  }

  void _loadSettings() {
    PlayerSettings.getCardScrubberMode().then((mode) {
      if (mounted && mode != _scrubberMode) {
        setState(() => _scrubberMode = mode);
      }
    });
    PlayerSettings.getSpeedAdjustedTime().then((v) { if (mounted && v != _speedAdjustedTime) setState(() => _speedAdjustedTime = v); });
    PlayerSettings.getProgressTextScale().then((v) { if (mounted && v != _progressTextScale) setState(() => _progressTextScale = v); });
    _loadSavedSpeed();
  }

  Future<void> _loadSavedSpeed() async {
    final itemId = widget.itemId;
    final bookSpeed = itemId != null ? await PlayerSettings.getBookSpeed(itemId) : null;
    final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
    if (mounted && speed != _savedSpeed) setState(() => _savedSpeed = speed);
  }

  void _onCastChanged() {
    final cast = ChromecastService();
    final wasCast = _isCastMode;
    final isCast = widget.itemId != null && cast.isCasting && cast.castingItemId == widget.itemId;
    if (wasCast != isCast) _subscribePosition();
  }

  bool _backgrounded = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _backgrounded = false;
      _loadSettings();
      _syncTicker();
    } else if (state == AppLifecycleState.paused) {
      _backgrounded = true;
      _smoothTicker?.cancel();
      _smoothTicker = null;
    }
  }

  @override
  void didUpdateWidget(CardDualProgressBar old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) _subscribePosition();
    if (old.itemId != widget.itemId) _loadSavedSpeed();
  }

  void _syncTicker() {
    final shouldRun = _isPlaying && (widget.isActive || _isCastMode) && !_backgrounded;
    if (shouldRun && _smoothTicker == null) {
      _smoothTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        _tickNotifier.notifyListeners();
      });
    } else if (!shouldRun && _smoothTicker != null) {
      _smoothTicker!.cancel();
      _smoothTicker = null;
    }
  }

  void _subscribePosition() {
    _posSub?.cancel();
    final cast = ChromecastService();
    _isCastMode = widget.itemId != null && cast.isCasting && cast.castingItemId == widget.itemId;

    if (_isCastMode) {
      _lastKnownPos = cast.castPosition.inMilliseconds / 1000.0;
      _lastPosTime = DateTime.now();
      _currentSpeed = cast.castSpeed;
      _isPlaying = cast.isPlaying;
      _syncTicker();
      _posSub = cast.castPositionStream?.listen((_) {
        // Read from cast.castPosition (not the raw stream value) so we get the
        // book-level position after multi-track fallback offset translation.
        // The chromecast service subscribes to the raw stream first, so by the
        // time this listener fires, _castPosition is already updated.
        _lastKnownPos = cast.castPosition.inMilliseconds / 1000.0;
        _lastPosTime = DateTime.now();
        _currentSpeed = cast.castSpeed;
        _isPlaying = cast.isPlaying;
        _syncTicker();
      });
    } else if (widget.isActive) {
      // Reset to the seed on a fresh subscription — clears stale position from a
      // previous episode and gives the near-zero rejection filter a clean baseline.
      final seedPos = widget.staticProgress * widget.staticDuration;
      _lastKnownPos = seedPos;
      _lastPosTime = DateTime.now();

      _posSub = widget.player.absolutePositionStream.listen((dur) {
        final posSeconds = dur.inMilliseconds / 1000.0;

        // If a seek just happened, check if this position event is the real
        // post-seek value or a transient glitch. Accept values near the seek
        // target; reject obvious transitional near-zero values.
        final seekTarget = widget.player.activeSeekTarget;
        if (seekTarget != null) {
          // Accept if close to the seek target (within 5s tolerance)
          if ((posSeconds - seekTarget).abs() < 5.0) {
            _lastKnownPos = posSeconds;
            _lastPosTime = DateTime.now();
            _currentSpeed = widget.player.speed;
            _isPlaying = widget.player.isPlaying;
            _syncTicker();
            // Stream has caught up — clear the seek target so subsequent
            // position updates flow through normally without filtering.
            widget.player.clearSeekTarget();
            return;
          }
          // Reject transient values far from the seek target
          return;
        }

        // Normal playback: reject transient near-zero during track changes
        if (_lastKnownPos > 10.0 && posSeconds < 2.0) {
          return;
        }

        _lastKnownPos = posSeconds;
        _lastPosTime = DateTime.now();
        _currentSpeed = widget.player.speed;
        _isPlaying = widget.player.isPlaying;
        _syncTicker();
      });
      _currentSpeed = widget.player.speed;
      _isPlaying = widget.player.isPlaying;
      _syncTicker();
    }
  }

  /// Smoothly interpolated position — predicts where playback is right now.
  /// Snaps immediately to seek target when a seek is in progress.
  double get _smoothPos {
    if (_isCastMode) {
      if (!_isPlaying) return _lastKnownPos;
      final elapsed = DateTime.now().difference(_lastPosTime).inMilliseconds / 1000.0;
      final capped = elapsed.clamp(0.0, 1.0);
      return _lastKnownPos + capped * _currentSpeed;
    }
    // If a seek just happened, snap to the target immediately
    final seekTarget = widget.player.activeSeekTarget;
    if (seekTarget != null && (seekTarget - _lastKnownPos).abs() > 2.0) {
      return seekTarget;
    }
    // Paused while active: trust the engine's real position. The position
    // stream only ticks during playback, so a stale seed / last-known value
    // could otherwise leave the bar sitting ahead of the actual position until
    // the next play (TestFlight: bar appears further than it is, snaps back on
    // play).
    if (widget.isActive && !_isPlaying) {
      final realPos = widget.player.position.inMilliseconds / 1000.0;
      if (realPos > 0) return realPos;
    }
    if (!widget.isActive || !_isPlaying) return _lastKnownPos;
    // Use the player's real position as the baseline instead of interpolating
    // from a potentially stale stream event. This prevents overshoot when the
    // position stream slows down (e.g. tab offstage in IndexedStack).
    final realPos = widget.player.position.inMilliseconds / 1000.0;
    // Only interpolate a small amount from the real position for sub-tick smoothing
    final elapsed = DateTime.now().difference(_lastPosTime).inMilliseconds / 1000.0;
    if (elapsed > 1.0) return realPos;
    return _lastKnownPos + elapsed * _currentSpeed;
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PlayerSettings.settingsChanged.removeListener(_loadSettings);
    ChromecastService().removeListener(_onCastChanged);
    _posSub?.cancel();
    _smoothTicker?.cancel();
    _tickNotifier.dispose();
    super.dispose();
  }

  void _doSeek(int seekMs) {
    if (_isCastMode) {
      ChromecastService().seekTo(Duration(milliseconds: seekMs));
    } else {
      widget.player.seekTo(Duration(milliseconds: seekMs));
    }
  }

  static double _scrubScale(double vertDist) {
    if (vertDist < 50) return 1.0;
    if (vertDist < 100) return 0.5;
    if (vertDist < 175) return 0.25;
    return 0.1;
  }

  static String _scrubSpeedLabel(AppLocalizations l, double scale) {
    if (scale <= 0.1) return l.cardProgressFineScrubbing;
    if (scale <= 0.25) return l.cardProgressQuarterSpeed;
    return l.cardProgressHalfSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final player = widget.player;
    final cast = ChromecastService();
    final active = widget.isActive || _isCastMode;

    return ListenableBuilder(
      listenable: _tickNotifier,
      builder: (context, _) {
        final staticPos = widget.staticProgress * widget.staticDuration;
        final posS = active ? _smoothPos : staticPos;
        final totalDur = _isCastMode ? cast.castingDuration : (widget.isActive ? player.totalDuration : widget.staticDuration);
        final speed = active ? _currentSpeed : 1.0;
        final isPlaying = active && _isPlaying;
        final bookProgress = totalDur > 0 ? (posS / totalDur).clamp(0.0, 1.0) : 0.0;

        double chapterStart = 0, chapterEnd = totalDur;
        String? resolvedChapterName;
        int resolvedChapterIdx = -1;

        // Always resolve chapter from posS so boundaries, fill, and name
        // all use the same position. Using player.currentChapter can
        // disagree with _smoothPos in multi-track books (track index race).
        List<dynamic> chapterSource;
        if (_isCastMode) {
          chapterSource = cast.castingChapters;
        } else if (widget.isActive) {
          chapterSource = player.chapters.isNotEmpty ? player.chapters : widget.chapters;
        } else {
          chapterSource = widget.chapters;
        }

        if (chapterSource.isNotEmpty) {
          for (int ci = 0; ci < chapterSource.length; ci++) {
            final m = chapterSource[ci] as Map<String, dynamic>;
            final s = (m['start'] as num?)?.toDouble() ?? 0;
            final e = (m['end'] as num?)?.toDouble() ?? 0;
            if (posS >= s && posS < e) {
              chapterStart = s;
              chapterEnd = e;
              resolvedChapterName = m['title'] as String?;
              resolvedChapterIdx = ci;
              break;
            }
          }
          // Slightly past the last chapter end still counts as the last
          // chapter. Grossly past means the chapters don't cover the item's
          // timeline (e.g. duplicate audio files, GH #345) - keep the
          // whole-book span so the pill stays honest and keeps moving.
          if (resolvedChapterIdx < 0 && posS > 0) {
            final last = chapterSource.last as Map<String, dynamic>;
            final lastEnd = (last['end'] as num?)?.toDouble() ?? totalDur;
            if (posS <= lastEnd + ChapterLookup.graceSeconds) {
              chapterStart = (last['start'] as num?)?.toDouble() ?? 0;
              chapterEnd = lastEnd;
              resolvedChapterName = last['title'] as String?;
              resolvedChapterIdx = chapterSource.length - 1;
            }
          }
        }
        final chapterUnresolved =
            chapterSource.isNotEmpty && resolvedChapterIdx < 0 && posS > 0;
        final chapterDur = chapterEnd - chapterStart;
        final chapterPos = (posS - chapterStart).clamp(0.0, chapterDur);
        final chapterProgress = chapterDur > 0 ? chapterPos / chapterDur : 0.0;
        // When inactive, fall back to the per-item saved speed (or default)
        // so the book time row on the expanded card still reflects the
        // user's speed-adjusted-time setting. Matches absorbing_card's
        // inline book-time logic.
        final speedDiv = _speedAdjustedTime ? (active ? speed : _savedSpeed) : 1.0;
        final bookElapsed = posS / speedDiv;
        final bookRemaining = (totalDur - posS) / speedDiv;
        final chapterRemaining = (chapterDur - chapterPos) / speedDiv;
        final chapterElapsed = chapterPos / speedDiv;
        final displayedBookProgress =
            (_bookDragValue ?? bookProgress).clamp(0.0, 1.0);
        final bookPercentageLabel = l.percentComplete(
          (displayedBookProgress * 100).toStringAsFixed(1),
        );
        final bookPercentageStyle = tt.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontSize: 11 * _progressTextScale,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            // Book bar
            if (widget.showBookBar) ...[
            if (_scrubberMode.allowsBookSeeking) ...[
              SizedBox(height: 32, child: LayoutBuilder(builder: (_, cons) {
                final w = cons.maxWidth;
                final p = _bookDragValue ?? bookProgress;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: active ? (d) { _bookDragStartDy = d.localPosition.dy; _bookScrubSpeed = 1.0; setState(() => _bookDragValue = (d.localPosition.dx / w).clamp(0.0, 1.0)); } : null,
                  onHorizontalDragUpdate: active ? (d) { _bookScrubSpeed = _scrubScale((d.localPosition.dy - _bookDragStartDy).abs()); setState(() => _bookDragValue = ((_bookDragValue ?? bookProgress) + d.delta.dx / w * _bookScrubSpeed).clamp(0.0, 1.0)); } : null,
                  onHorizontalDragEnd: active ? (_) { if (_bookDragValue != null) { final seekMs = (_bookDragValue! * totalDur * 1000).round(); _doSeek(seekMs); } setState(() => _bookDragValue = null); } : null,
                  onTapUp: active ? (d) { final v = (d.localPosition.dx / w).clamp(0.0, 1.0); final seekMs = (v * totalDur * 1000).round(); _doSeek(seekMs); } : null,
                  child: CustomPaint(size: Size(w, 32), painter: AbsorbProgressPainter(progress: p, accent: widget.accent.withValues(alpha: 0.5), isDragging: _bookDragValue != null)),
                );
              })),
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Text(_fmt(_bookDragValue != null ? _bookDragValue! * totalDur / speedDiv : bookElapsed), style: tt.labelSmall?.copyWith(color: _bookDragValue != null ? cs.onSurface.withValues(alpha: 0.7) : cs.onSurfaceVariant, fontSize: 12 * _progressTextScale, fontWeight: FontWeight.w600, shadows: [Shadow(color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5), blurRadius: 3)])),
                        const Spacer(),
                        Text('-${_fmt(_bookDragValue != null ? (1.0 - _bookDragValue!) * totalDur / speedDiv : bookRemaining)}', style: tt.labelSmall?.copyWith(color: _bookDragValue != null ? cs.onSurface.withValues(alpha: 0.7) : cs.onSurfaceVariant, fontSize: 12 * _progressTextScale, fontWeight: FontWeight.w600, shadows: [Shadow(color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5), blurRadius: 3)])),
                      ],
                    ),
                    if (_bookDragValue != null && _bookScrubSpeed < 1.0)
                      Text(_scrubSpeedLabel(l, _bookScrubSpeed), style: tt.labelSmall?.copyWith(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w500))
                    else if (widget.showBookPercentage)
                      Text(
                        bookPercentageLabel,
                        key: const ValueKey('desktop-current-percent'),
                        style: bookPercentageStyle,
                      ),
                  ],
                ),
              ),
            ] else ...[
              Row(children: [
                Text(_fmt(_bookDragValue != null ? _bookDragValue! * totalDur / speedDiv : bookElapsed), style: tt.labelSmall?.copyWith(color: _bookDragValue != null ? cs.onSurface.withValues(alpha: 0.6) : cs.onSurface.withValues(alpha: 0.5), fontSize: 11 * _progressTextScale, fontWeight: FontWeight.w500, shadows: [Shadow(color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5), blurRadius: 3)])),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: bookProgress, minHeight: 3, backgroundColor: cs.onSurface.withValues(alpha: 0.08), valueColor: AlwaysStoppedAnimation(widget.accent.withValues(alpha: 0.5))))),
                if (widget.showBookPercentage) ...[
                  const SizedBox(width: 8),
                  Text(
                    bookPercentageLabel,
                    key: const ValueKey('desktop-current-percent'),
                    style: bookPercentageStyle,
                  ),
                ],
                const SizedBox(width: 8),
                Text('-${_fmt(_bookDragValue != null ? (1.0 - _bookDragValue!) * totalDur / speedDiv : bookRemaining)}', style: tt.labelSmall?.copyWith(color: _bookDragValue != null ? cs.onSurface.withValues(alpha: 0.6) : cs.onSurface.withValues(alpha: 0.5), fontSize: 11 * _progressTextScale, fontWeight: FontWeight.w500, shadows: [Shadow(color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5), blurRadius: 3)])),
              ]),
              SizedBox(height: widget.compact ? 4 : 10),
            ],
            ], // end showBookBar
            // Chapter bar
            if (widget.showChapterBar) ...[
            // ── Chapter pill-scrubber ──
            SizedBox(height: widget.compact ? 22 : 30, child: LayoutBuilder(builder: (_, cons) {
              final w = cons.maxWidth;
              final p = _chapterDragValue ?? chapterProgress;
              final isDragging = _chapterDragValue != null;
              // Prefer the chapter name resolved from posS (consistent with
              // the fill position) over the externally-passed name which
              // may come from player.currentChapter (different position source).
              final rawName = resolvedChapterName ??
                  (chapterUnresolved ? null : widget.chapterName);
              final chIdx = resolvedChapterIdx >= 0 ? resolvedChapterIdx : widget.chapterIndex;
              final chName = rawName != null
                  ? _smartChapterName(l, rawName, chIdx, widget.totalChapters)
                  : null;
              final chapterInteractive =
                  active && _scrubberMode.allowsChapterSeeking;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: chapterInteractive ? (d) { _chapterDragStartDy = d.localPosition.dy; _chapterScrubSpeed = 1.0; setState(() => _chapterDragValue = (d.localPosition.dx / w).clamp(0.0, 1.0)); } : null,
                onHorizontalDragUpdate: chapterInteractive ? (d) { _chapterScrubSpeed = _scrubScale((d.localPosition.dy - _chapterDragStartDy).abs()); setState(() => _chapterDragValue = ((_chapterDragValue ?? chapterProgress) + d.delta.dx / w * _chapterScrubSpeed).clamp(0.0, 1.0)); } : null,
                onHorizontalDragEnd: chapterInteractive ? (_) { if (_chapterDragValue != null) { final seekMs = ((chapterStart + _chapterDragValue! * chapterDur) * 1000).round(); _doSeek(seekMs); } setState(() => _chapterDragValue = null); } : null,
                onTapUp: chapterInteractive ? (d) { final v = (d.localPosition.dx / w).clamp(0.0, 1.0); final seekMs = ((chapterStart + v * chapterDur) * 1000).round(); _doSeek(seekMs); } : null,
                child: CustomPaint(
                  size: Size(w, 30),
                  painter: ChapterPillPainter(
                    progress: p,
                    accent: widget.accent,
                    wavePhase: 0,
                    isPlaying: isPlaying,
                    isDragging: isDragging,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: chName != null
                          ? MarqueeText(
                              text: chName,
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            })),
            // Time labels below pill — update during drag
            Padding(padding: EdgeInsets.only(top: widget.compact ? 1 : 3), child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(_chapterDragValue != null ? (_chapterDragValue! * chapterDur) / speedDiv : chapterElapsed),
                  style: tt.labelSmall?.copyWith(
                    color: _chapterDragValue != null ? widget.accent : cs.onSurface.withValues(alpha: 0.54),
                    fontSize: 11 * _progressTextScale, fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [Shadow(color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5), blurRadius: 3)])),
                if (_chapterDragValue != null && _chapterScrubSpeed < 1.0) Text(_scrubSpeedLabel(l, _chapterScrubSpeed), style: tt.labelSmall?.copyWith(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w500)),
                Text('-${_fmt(_chapterDragValue != null ? ((1.0 - _chapterDragValue!) * chapterDur) / speedDiv : chapterRemaining)}',
                  style: tt.labelSmall?.copyWith(
                    color: _chapterDragValue != null ? widget.accent : cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 11 * _progressTextScale, fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [Shadow(color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5), blurRadius: 3)])),
              ],
            )),
            ], // end showChapterBar
          ]),
        );
      },
    );
  }

  String _fmt(double s) {
    if (s < 0) s = 0;
    final h = (s / 3600).floor(); final m = ((s % 3600) / 60).floor(); final sec = (s % 60).floor();
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// Smart chapter name: prefix bare numbers, show chapter position.
  String _smartChapterName(AppLocalizations l, String raw, int index, int total) {
    final trimmed = raw.trim();
    // Pure number → "Chapter 16"
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return l.cardProgressChapterPrefix(trimmed);
    }
    // Very short (1-2 chars) → prefix
    if (trimmed.length <= 2) {
      return l.cardProgressChapterPrefix(trimmed);
    }
    return trimmed;
  }
}

// ─── CHAPTER PILL PAINTER ────────────────────────────────────

class ChapterPillPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double wavePhase;
  final bool isPlaying;
  final bool isDragging;
  final Color backgroundColor;

  ChapterPillPainter({
    required this.progress,
    required this.accent,
    required this.wavePhase,
    required this.isPlaying,
    required this.isDragging,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final radius = h / 2;
    final p = progress.clamp(0.0, 1.0);

    // Pill shape
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(radius),
    );

    // Background
    canvas.drawRRect(pillRect, Paint()..color = backgroundColor);

    // Border
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = isDragging ? accent.withValues(alpha: 0.5) : accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    if (p <= 0.001) return;

    // Fill — clip to pill, draw a simple rect
    final fillW = p * w;
    canvas.save();
    canvas.clipRRect(pillRect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fillW, h),
      Paint()..color = accent.withValues(alpha: 0.25),
    );
    canvas.restore();

    // Thin glowing line at progress edge — height follows pill curvature
    if (p < 0.995) {
      final lineX = fillW.clamp(1.0, w - 1.0);

      // Calculate how tall the line should be based on the pill circle at this x
      // The pill is a stadium shape: two semicircles of radius=h/2 at each end
      double lineH;
      if (lineX < radius) {
        // Left cap region — chord height
        final dx = radius - lineX;
        lineH = 2 * sqrt(radius * radius - dx * dx);
      } else if (lineX > w - radius) {
        // Right cap region — chord height
        final dx = lineX - (w - radius);
        lineH = 2 * sqrt(radius * radius - dx * dx);
      } else {
        // Middle — full height
        lineH = h;
      }

      final inset = (h - lineH) / 2 + 2; // 2px inner padding

      // Glow layers (more when playing)
      if (isPlaying) {
        // Outer glow
        canvas.drawLine(
          Offset(lineX, inset),
          Offset(lineX, h - inset),
          Paint()
            ..color = accent.withValues(alpha: 0.2)
            ..strokeWidth = 8.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        // Mid glow
        canvas.drawLine(
          Offset(lineX, inset),
          Offset(lineX, h - inset),
          Paint()
            ..color = accent.withValues(alpha: 0.4)
            ..strokeWidth = 4.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // Solid line
      canvas.drawLine(
        Offset(lineX, inset),
        Offset(lineX, h - inset),
        Paint()
          ..color = accent.withValues(alpha: isPlaying ? 0.95 : 0.5)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );

      // Thumb circle when dragging
      if (isDragging) {
        final center = Offset(lineX, h / 2);
        // Shadow
        canvas.drawCircle(
          center + const Offset(0, 1),
          7,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        // White border
        canvas.drawCircle(center, 7, Paint()..color = Colors.white);
        // Accent fill
        canvas.drawCircle(center, 5.5, Paint()..color = accent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ChapterPillPainter old) =>
      old.progress != progress ||
      old.isDragging != isDragging ||
      old.backgroundColor != backgroundColor;
}

// ─── MARQUEE TEXT ────────────────────────────────────────────

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const MarqueeText({super.key, required this.text, required this.style});
  @override State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;
  bool _duplicated = false;
  double _loopWidth = 0; // distance to scroll for one seamless loop

  static const double _gap = 48.0;   // space between the two text copies
  static const double _speed = 38.0; // pixels per second

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _animController.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _animController.stop();
      _animController.reset();
      _duplicated = false;
      _loopWidth = 0;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return; // text fits, nothing to do

    // In single-text mode: maxScroll = textWidth - viewportWidth
    // loopWidth = textWidth + gap (one seamless cycle in duplicated mode)
    _loopWidth = maxScroll + _scrollController.position.viewportDimension + _gap;

    setState(() => _duplicated = true);

    // After duplicated layout settles, start the continuous loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final durationMs = (_loopWidth / _speed * 1000).round();
      _animController.duration = Duration(milliseconds: durationMs);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _animController.repeat();
      });
    });
  }

  void _onTick() {
    if (!_scrollController.hasClients || _loopWidth <= 0) return;
    // value 0→1 maps to 0→loopWidth; repeat() resets value to 0 seamlessly
    final pos = _animController.value * _loopWidth;
    _scrollController.jumpTo(pos.clamp(0.0, _scrollController.position.maxScrollExtent));
  }

  @override
  void dispose() {
    _animController.removeListener(_onTick);
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _textSpan() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(widget.text, style: widget.style, maxLines: 1, softWrap: false),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: _duplicated
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              _textSpan(),
              const SizedBox(width: _gap),
              _textSpan(),
            ])
          : _textSpan(),
    );
  }
}
