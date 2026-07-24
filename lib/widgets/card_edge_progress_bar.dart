import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';

// ─── EDGE PROGRESS BAR (thin strip at card top) ───────────────────────
//
// Default: 3.5px accent-colored strip flush at the card's top edge.
// On horizontal drag or long-press: expands to a full scrubber overlay.

class CardEdgeProgressBar extends StatefulWidget {
  final AudioPlayerService player;
  final Color accent;
  final bool isActive;
  final double staticProgress;
  final double staticDuration;
  final List<dynamic> chapters;
  final String? itemId;
  final ValueNotifier<bool>? expandedNotifier;

  const CardEdgeProgressBar({
    super.key,
    required this.player,
    required this.accent,
    required this.isActive,
    required this.staticProgress,
    required this.staticDuration,
    required this.chapters,
    this.itemId,
    this.expandedNotifier,
  });

  @override
  State<CardEdgeProgressBar> createState() => _CardEdgeProgressBarState();
}

class _CardEdgeProgressBarState extends State<CardEdgeProgressBar>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  // ── Smooth position tracking (same pattern as CardDualProgressBar) ──
  Timer? _smoothTicker;
  final _tickNotifier = ChangeNotifier(); // drives ListenableBuilder rebuilds
  double _lastKnownPos = 0;
  DateTime _lastPosTime = DateTime.now();
  double _currentSpeed = 1.0;
  bool _isPlaying = false;
  bool _isCastMode = false;
  StreamSubscription<Duration>? _posSub;
  bool _speedAdjustedTime = true;

  // ── Expand/collapse animation ──
  late AnimationController _expandController;
  double? _dragValue;
  double _dragStartDy = 0;
  double _lastLongPressDx = 0;
  double _edgeScrubSpeed = 1.0;
  CardScrubberMode _scrubberMode = CardScrubberMode.chapter;

  static const _thinHeight = 3.5;
  static const _expandedHeight = 50.0;
  static const _hitTargetHeight = 28.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandController.addListener(() {
      widget.expandedNotifier?.value = _expandController.value > 0.1;
    });
    _loadSettings();
    _subscribePosition();
    PlayerSettings.settingsChanged.addListener(_loadSettings);
    ChromecastService().addListener(_onCastChanged);
  }

  void _loadSettings() {
    PlayerSettings.getSpeedAdjustedTime().then((v) {
      if (mounted && v != _speedAdjustedTime) setState(() => _speedAdjustedTime = v);
    });
    PlayerSettings.getCardScrubberMode().then((mode) {
      if (mounted && mode != _scrubberMode) {
        setState(() => _scrubberMode = mode);
      }
    });
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
  void didUpdateWidget(CardEdgeProgressBar old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) _subscribePosition();
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
        _lastKnownPos = cast.castPosition.inMilliseconds / 1000.0;
        _lastPosTime = DateTime.now();
        _currentSpeed = cast.castSpeed;
        _isPlaying = cast.isPlaying;
        _syncTicker();
      });
    } else if (widget.isActive) {
      final seedPos = widget.staticProgress * widget.staticDuration;
      _lastKnownPos = seedPos;
      _lastPosTime = DateTime.now();

      _posSub = widget.player.absolutePositionStream.listen((dur) {
        final posSeconds = dur.inMilliseconds / 1000.0;

        final seekTarget = widget.player.activeSeekTarget;
        if (seekTarget != null) {
          if ((posSeconds - seekTarget).abs() < 5.0) {
            _lastKnownPos = posSeconds;
            _lastPosTime = DateTime.now();
            _currentSpeed = widget.player.speed;
            _isPlaying = widget.player.isPlaying;
            _syncTicker();
            widget.player.clearSeekTarget();
            return;
          }
          return;
        }

        if (_lastKnownPos > 10.0 && posSeconds < 2.0) return;

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

  double get _smoothPos {
    if (_isCastMode) {
      if (!_isPlaying) return _lastKnownPos;
      final elapsed = DateTime.now().difference(_lastPosTime).inMilliseconds / 1000.0;
      return _lastKnownPos + elapsed * _currentSpeed;
    }
    final seekTarget = widget.player.activeSeekTarget;
    if (seekTarget != null && (seekTarget - _lastKnownPos).abs() > 2.0) {
      return seekTarget;
    }
    // Paused while active: trust the engine's real position (the position
    // stream only ticks during playback, so a stale seed could leave the bar
    // ahead of reality until the next play).
    if (widget.isActive && !_isPlaying) {
      final realPos = widget.player.position.inMilliseconds / 1000.0;
      if (realPos > 0) return realPos;
    }
    if (!widget.isActive || !_isPlaying) return _lastKnownPos;
    final elapsed = DateTime.now().difference(_lastPosTime).inMilliseconds / 1000.0;
    return _lastKnownPos + elapsed * _currentSpeed;
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
    if (scale <= 0.1) return l.cardEdgeProgressFineScrubbing;
    if (scale <= 0.25) return l.cardEdgeProgressQuarterSpeed;
    return l.cardEdgeProgressHalfSpeed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PlayerSettings.settingsChanged.removeListener(_loadSettings);
    ChromecastService().removeListener(_onCastChanged);
    _posSub?.cancel();
    _smoothTicker?.cancel();
    _tickNotifier.dispose();
    _expandController.dispose();
    super.dispose();
  }

  static String _fmt(double s) {
    if (s <= 0) return '0:00';
    final h = (s / 3600).floor();
    final m = ((s % 3600) / 60).floor();
    final sec = (s % 60).floor();
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cast = ChromecastService();
    final active = widget.isActive || _isCastMode;

    return ListenableBuilder(
      listenable: Listenable.merge([_tickNotifier, _expandController]),
      builder: (context, _) {
        final staticPos = widget.staticProgress * widget.staticDuration;
        final posS = active ? _smoothPos : staticPos;
        final totalDur = _isCastMode
            ? cast.castingDuration
            : (widget.isActive ? widget.player.totalDuration : widget.staticDuration);
        final speed = active ? _currentSpeed : 1.0;
        final bookProgress = totalDur > 0 ? (posS / totalDur).clamp(0.0, 1.0) : 0.0;
        final speedDiv = _speedAdjustedTime ? speed : 1.0;
        final bookElapsed = posS / speedDiv;
        final bookRemaining = (totalDur - posS) / speedDiv;

        final expandT = CurvedAnimation(
          parent: _expandController,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ).value;

        final totalHeight = lerpDouble(_hitTargetHeight, _expandedHeight, expandT)!;
        final barHeight = lerpDouble(_thinHeight, 8.0, expandT)!;
        final displayProgress = _dragValue ?? bookProgress;

        final interactive = active && _scrubberMode.allowsBookSeeking;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: interactive ? (d) {
            if (!_expandController.isAnimating && _expandController.value < 1.0) {
              _expandController.forward();
            }
            _dragStartDy = d.localPosition.dy;
            _edgeScrubSpeed = 1.0;
            final box = context.findRenderObject() as RenderBox;
            setState(() => _dragValue = (d.localPosition.dx / box.size.width).clamp(0.0, 1.0));
          } : null,
          onHorizontalDragUpdate: interactive ? (d) {
            final box = context.findRenderObject() as RenderBox;
            _edgeScrubSpeed = _scrubScale((d.localPosition.dy - _dragStartDy).abs());
            setState(() => _dragValue = ((_dragValue ?? bookProgress) + d.delta.dx / box.size.width * _edgeScrubSpeed).clamp(0.0, 1.0));
          } : null,
          onHorizontalDragEnd: interactive ? (_) {
            if (_dragValue != null) {
              final seekMs = (_dragValue! * totalDur * 1000).round();
              _doSeek(seekMs);
            }
            setState(() => _dragValue = null);
            _expandController.reverse();
          } : null,
          onLongPressStart: interactive ? (d) {
            _expandController.forward();
            _dragStartDy = d.localPosition.dy;
            _lastLongPressDx = d.localPosition.dx;
            _edgeScrubSpeed = 1.0;
            final box = context.findRenderObject() as RenderBox;
            setState(() => _dragValue = (d.localPosition.dx / box.size.width).clamp(0.0, 1.0));
          } : null,
          onLongPressMoveUpdate: interactive ? (d) {
            final box = context.findRenderObject() as RenderBox;
            _edgeScrubSpeed = _scrubScale((d.localPosition.dy - _dragStartDy).abs());
            final delta = d.localPosition.dx - _lastLongPressDx;
            _lastLongPressDx = d.localPosition.dx;
            setState(() => _dragValue = ((_dragValue ?? bookProgress) + delta / box.size.width * _edgeScrubSpeed).clamp(0.0, 1.0));
          } : null,
          onLongPressEnd: interactive ? (_) {
            if (_dragValue != null) {
              final seekMs = (_dragValue! * totalDur * 1000).round();
              _doSeek(seekMs);
            }
            setState(() => _dragValue = null);
            _expandController.reverse();
          } : null,
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Progress bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: barHeight,
                  child: CustomPaint(
                    painter: EdgeProgressPainter(
                      progress: displayProgress,
                      accent: widget.accent,
                      expandProgress: expandT,
                      isDragging: _dragValue != null,
                      trackBackground: cs.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Time labels (fade in when expanded)
                if (expandT > 0.2)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 2,
                    child: Opacity(
                      opacity: ((expandT - 0.2) / 0.8).clamp(0.0, 1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _fmt(_dragValue != null ? _dragValue! * totalDur / speedDiv : bookElapsed),
                            style: tt.labelSmall?.copyWith(
                              color: _dragValue != null
                                  ? widget.accent
                                  : cs.onSurface.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              shadows: [Shadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.6),
                                blurRadius: 3,
                              )],
                            ),
                          ),
                          if (_dragValue != null && _edgeScrubSpeed < 1.0) Text(_scrubSpeedLabel(l, _edgeScrubSpeed), style: tt.labelSmall?.copyWith(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w500)),
                          Text(
                            '-${_fmt(_dragValue != null ? (1.0 - _dragValue!) * totalDur / speedDiv : bookRemaining)}',
                            style: tt.labelSmall?.copyWith(
                              color: _dragValue != null
                                  ? widget.accent
                                  : cs.onSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              shadows: [Shadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.6),
                                blurRadius: 3,
                              )],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── EDGE PROGRESS PAINTER ───────────────────────────────────────────

class EdgeProgressPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double expandProgress;
  final bool isDragging;
  final Color trackBackground;

  EdgeProgressPainter({
    required this.progress,
    required this.accent,
    required this.expandProgress,
    required this.isDragging,
    required this.trackBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final r = h / 2;

    // Track background
    final bgPaint = Paint()..color = trackBackground;
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, w, h, Radius.circular(r)),
      bgPaint,
    );

    // Progress fill
    if (progress > 0) {
      final fillW = (progress * w).clamp(0.0, w);
      final fillPaint = Paint()..color = accent.withValues(alpha: lerpDouble(0.5, 0.6, expandProgress)!);
      canvas.drawRRect(
        RRect.fromLTRBR(0, 0, fillW, h, Radius.circular(r)),
        fillPaint,
      );
    }

    // Progress edge line (glow when dragging/expanded)
    if (progress > 0 && progress < 1) {
      final lineX = (progress * w).clamp(r, w - r);
      if (isDragging || expandProgress > 0.3) {
        // Glow effect
        final glowPaint = Paint()
          ..color = accent.withValues(alpha: 0.2)
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawLine(Offset(lineX, 0), Offset(lineX, h), glowPaint);
        final midPaint = Paint()
          ..color = accent.withValues(alpha: 0.5)
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawLine(Offset(lineX, 0), Offset(lineX, h), midPaint);
      }
      final corePaint = Paint()
        ..color = accent.withValues(alpha: lerpDouble(0.4, 0.9, expandProgress)!)
        ..strokeWidth = lerpDouble(1.0, 1.5, expandProgress)!;
      canvas.drawLine(Offset(lineX, 0), Offset(lineX, h), corePaint);
    }

    // Thumb (only when dragging) - positioned at bottom of bar so it hangs below
    if (isDragging && expandProgress > 0.3) {
      final thumbX = (progress * w).clamp(r, w - r);
      final thumbR = lerpDouble(0.0, 6.0, ((expandProgress - 0.3) / 0.7).clamp(0.0, 1.0))!;
      final thumbY = h;
      if (thumbR > 0) {
        // Shadow
        canvas.drawCircle(
          Offset(thumbX, thumbY + 1),
          thumbR,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        // Fill
        canvas.drawCircle(Offset(thumbX, thumbY), thumbR, Paint()..color = accent);
        // Border
        canvas.drawCircle(
          Offset(thumbX, thumbY),
          thumbR,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(EdgeProgressPainter old) =>
      progress != old.progress ||
      expandProgress != old.expandProgress ||
      isDragging != old.isDragging ||
      accent != old.accent;
}
