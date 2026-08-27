import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/audio_player_service.dart';
import '../services/lyrics_service.dart';
import '../services/transcript_line_store.dart';

/// Live transcript on the player cover.
///
/// It reads like a page of a book: sentences fill downwards, the spoken one
/// lights up as the narration walks down them, and only when it reaches the
/// bottom does the next page come up. Sentences are measured before they are
/// drawn, so a page holds what fits whole - a long sentence takes the room it
/// needs instead of being cut off.
///
/// Taking over the cover (the default) the card hides its artwork, and the
/// transcript sits straight on the card's own background - blur, gradient or
/// flat, whatever the user has it set to. Otherwise it's a strip across the
/// bottom of the artwork, which works the same way in less room.
class LyricsOverlay extends StatefulWidget {
  /// When set, renders only while lyrics run for this store key - card lists
  /// show several books, and the line belongs to the playing one alone.
  final String? forKey;
  final bool compact;
  /// The card's ink color, so the transcript reads like the rest of the card
  /// on whatever background it has. Defaults to white-on-artwork.
  final Color? onSurface;
  /// The card's base color, used to keep the read-along highlight readable.
  final Color? surface;
  const LyricsOverlay({
    super.key,
    this.forKey,
    this.compact = false,
    this.onSurface,
    this.surface,
  });

  @override
  State<LyricsOverlay> createState() => _LyricsOverlayState();
}

/// [color], nudged toward the background's opposite until it can actually be
/// read on it - a pale amber on a pale cover is a picked color nobody can see.
/// Stops at a 3:1 ratio, the readable threshold for text this size.
Color readableOn(Color color, Color background) {
  final bg = background.computeLuminance();
  var c = color;
  for (var i = 0; i < 8; i++) {
    final lum = c.computeLuminance();
    final contrast = (math.max(lum, bg) + 0.05) / (math.min(lum, bg) + 0.05);
    if (contrast >= 3) break;
    c = Color.lerp(c, bg > 0.5 ? Colors.black : Colors.white, 0.2)!;
  }
  return c;
}

class _LyricsOverlayState extends State<LyricsOverlay> {
  /// Start time of the first sentence on the page being shown. Kept here so
  /// the page holds still while the narration moves down it, instead of
  /// re-centring on every sentence.
  double? _pageStart;

  /// The sync nudge is a tuning control, not something to stare at all
  /// session, so it shows itself when it is likely to be wanted - the
  /// transcript starting, or the output changing to or from headphones - and
  /// otherwise waits for a long press on the transcript.
  bool _pillVisible = false;
  Timer? _pillTimer;
  bool _lastOn = false;
  bool? _lastBluetooth;

  static const _linePad = 6.0;

  void _revealPill() {
    _pillTimer?.cancel();
    if (mounted && !_pillVisible) setState(() => _pillVisible = true);
    _pillTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _pillVisible = false);
    });
  }

  @override
  void dispose() {
    _pillTimer?.cancel();
    super.dispose();
  }

  Color get _ink => widget.onSurface ?? Colors.white;
  Color get _inkQuiet => _ink.withValues(alpha: 0.4);

  /// The transcript can sit on blurred artwork, so it always carries a halo -
  /// dark behind light text, light behind dark text.
  Color get _halo => _ink.computeLuminance() > 0.5
      ? Colors.black.withValues(alpha: 0.7)
      : Colors.white.withValues(alpha: 0.7);

  TextStyle _base(double size) => TextStyle(
        fontSize: size,
        height: 1.35,
        fontWeight: FontWeight.w600,
        shadows: [Shadow(blurRadius: 6, color: _halo)],
      );

  /// The line, with the word being spoken in the read-along color and the
  /// rest of it a shade back. Falls back to plain text when the line has no
  /// word timing (older cached lines) or word tracking is off.
  InlineSpan _lineSpan(LyricsService svc, String line) {
    final index = svc.currentWordIndex;
    final words = svc.current?.words ?? const <String>[];
    if (index < 0 || index >= words.length) return TextSpan(text: line);
    final accent =
        readableOn(Color(svc.readAlongColor), widget.surface ?? Colors.black);
    final rest = _ink.withValues(alpha: 0.8);
    return TextSpan(
      children: [
        for (var i = 0; i < words.length; i++)
          TextSpan(
            text: i == words.length - 1 ? words[i] : '${words[i]} ',
            style: TextStyle(color: i == index ? accent : rest),
          ),
      ],
    );
  }

  /// Must match how the page's Text widgets actually render, or _fit packs
  /// more lines than the page can hold and the bottom one gets clipped -
  /// which is why this applies the ambient text scale the widgets will get.
  TextScaler _scaler = TextScaler.noScaling;

  double _measure(String text, TextStyle style, double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      textScaler: _scaler,
    )..layout(maxWidth: maxWidth);
    return tp.height;
  }

  Widget _spoken(LyricsService svc, String text, double size, {int? maxLines}) =>
      Text.rich(
        _lineSpan(svc, text),
        textAlign: TextAlign.center,
        maxLines: maxLines,
        overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
        style: _base(size).copyWith(color: _ink),
      );

  Widget _quiet(String text, double size) => Text(
        text,
        textAlign: TextAlign.center,
        style: _base(size).copyWith(
          color: _inkQuiet,
          fontWeight: FontWeight.w500,
        ),
      );

  /// A page of sentences starting at [anchor]: as many as fit whole in
  /// [maxHeight]. The first is always included even when it is taller than the
  /// page on its own - it gets scaled down rather than clipped.
  List<TranscriptLine> _fit(String key, double anchor, double maxWidth,
      double maxHeight, TextStyle style) {
    final candidates = TranscriptLineStore.instance.fromLine(key, anchor, 16);
    final out = <TranscriptLine>[];
    var used = 0.0;
    for (final l in candidates) {
      final h = _measure(l.text.trim(), style, maxWidth) + _linePad;
      if (out.isNotEmpty && used + h > maxHeight) break;
      out.add(l);
      used += h;
    }
    return out;
  }

  /// Fills downwards, turning a page only when the spoken sentence runs off
  /// the bottom of the current one.
  Widget _page(
      LyricsService svc, double maxWidth, double maxHeight, double size) {
    final key = svc.activeKey;
    final current = svc.current;
    final style = _base(size);
    if (key == null || current == null) {
      return _spoken(svc, current?.text.trim() ?? '', size, maxLines: 4);
    }
    var anchor = _pageStart;
    // A seek backwards, or a page we no longer have lines for, starts over at
    // whatever is being spoken now.
    if (anchor == null || current.start < anchor) anchor = current.start;
    var page = _fit(key, anchor, maxWidth, maxHeight, style);
    // The narration walked off the bottom of this page: turn to a new one
    // starting at the sentence being spoken.
    if (page.isEmpty || !page.any((l) => l.start == current.start)) {
      anchor = current.start;
      page = _fit(key, anchor, maxWidth, maxHeight, style);
    }
    _pageStart = anchor;
    if (page.isEmpty) {
      return current.approx
          ? _quiet(current.text.trim(), size)
          : _spoken(svc, current.text.trim(), size, maxLines: 4);
    }
    final tall = page.length == 1 &&
        _measure(page.first.text.trim(), style, maxWidth) > maxHeight;
    final column = Column(
      key: ValueKey('p$anchor'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final l in page)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: _linePad / 2),
            // Previews stay in the quiet style even while being "spoken" -
            // the dimming is what says their timing is estimated.
            child: l.start == current.start && !l.approx
                ? _spoken(svc, l.text.trim(), size)
                : _quiet(l.text.trim(), size),
          ),
      ],
    );
    // One sentence longer than the whole page: shrink it rather than hide
    // half of it.
    return tall ? FittedBox(fit: BoxFit.scaleDown, child: column) : column;
  }

  /// Waiting on the transcript. Says what it is waiting for rather than
  /// spinning forever: how far the initial runway has got, or - when this
  /// device simply cannot transcribe as fast as you are listening - that it
  /// cannot.
  Widget _waiting(BuildContext context, LyricsService svc) {
    final l = AppLocalizations.of(context)!;
    final quiet = TextStyle(color: _inkQuiet, fontSize: 12);
    final progress = svc.gateProgress;
    final rows = <Widget>[];
    if (progress != null) {
      final percent = '${(progress * 100).round()}%';
      rows.add(Text(l.lyricsBuildingLead(percent),
          textAlign: TextAlign.center, style: quiet));
      rows.add(const SizedBox(height: 8));
      rows.add(SizedBox(
        width: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: _ink.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(_ink.withValues(alpha: 0.6)),
          ),
        ),
      ));
    } else if (svc.cannotKeepUp) {
      final speed = AudioPlayerService().speed;
      rows.add(Text(
          l.lyricsCantKeepUp('${speed.toStringAsFixed(speed % 1 == 0 ? 0 : 2)}x'),
          textAlign: TextAlign.center,
          style: quiet));
    } else {
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _inkQuiet),
          ),
          const SizedBox(width: 8),
          Text(l.lyricsListeningAhead, style: quiet),
        ],
      ));
    }
    return Column(
      key: const ValueKey('_buffering'),
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  /// Fades between pages, not between sentences - inside a page the spoken
  /// line just moves down, which shouldn't animate the whole block.
  Widget _switcher(Widget child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: child,
      );

  /// Sync nudge, on the player itself: shifting the transcript against the
  /// audio is only judgeable while listening to it, so it can't live in a
  /// settings screen you have to walk back and forth from. Bluetooth runs a
  /// couple of hundred milliseconds behind the playhead, and every pair of
  /// headphones is different.
  Widget _syncPill(LyricsService svc) {
    return AnimatedOpacity(
      opacity: _pillVisible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !_pillVisible,
        child: _syncPillBody(svc),
      ),
    );
  }

  Widget _syncPillBody(LyricsService svc) {
    final ms = svc.offsetMs;
    final label = ms == 0
        ? '0'
        : '${ms > 0 ? '+' : '-'}${(ms.abs() / 1000).toStringAsFixed(2)}s';
    Widget button(IconData icon, int delta) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            svc.nudgeOffset(delta);
            _revealPill();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Icon(icon, size: 16, color: _ink.withValues(alpha: 0.75)),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 2),
            child: Icon(
                svc.onBluetooth
                    ? Icons.bluetooth_rounded
                    : Icons.volume_up_rounded,
                size: 13,
                color: _ink.withValues(alpha: 0.5)),
          ),
          button(Icons.remove_rounded, -50),
          // Long press to drop back to no offset.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () {
              svc.clearOffset();
              _revealPill();
            },
            child: SizedBox(
              width: 52,
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _ink.withValues(alpha: 0.75))),
            ),
          ),
          button(Icons.add_rounded, 50),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LyricsService.instance,
      builder: (context, _) {
        final svc = LyricsService.instance;
        if (!svc.isOn) return const SizedBox.shrink();
        if (widget.forKey != null && svc.activeKey != widget.forKey) {
          return const SizedBox.shrink();
        }
        _scaler = MediaQuery.textScalerOf(context);
        final line = svc.current?.text.trim() ?? '';
        // The initial runway build shows its progress even when the playhead
        // is inside saved coverage - lines are held back until the gate opens.
        final showBuffer =
            line.isEmpty && (svc.buffering || svc.gateProgress != null);
        if (line.isEmpty && !showBuffer) return const SizedBox.shrink();
        final size = widget.compact ? svc.fontSize * 0.8 : svc.fontSize;
        final padH = widget.compact ? 14.0 : 18.0;
        // Starting the transcript, or plugging in headphones, is exactly when
        // the offset might need a nudge - so offer it, briefly, unasked.
        if (svc.isOn != _lastOn || svc.onBluetooth != _lastBluetooth) {
          _lastOn = svc.isOn;
          _lastBluetooth = svc.onBluetooth;
          if (svc.isOn && !widget.compact) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _revealPill());
          }
        }

        // Taking the cover: the card hides its artwork, so the transcript
        // paints nothing of its own and sits on the card's background.
        if (svc.fullCover) {
          return Positioned.fill(
            child: Stack(
              children: [
                IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: padH, vertical: widget.compact ? 10 : 14),
                    child: LayoutBuilder(
                      builder: (context, box) => Align(
                        alignment: Alignment.topCenter,
                        child: _switcher(showBuffer
                            ? _waiting(context, svc)
                            : _page(
                                svc,
                                box.maxWidth,
                                box.maxHeight.isFinite ? box.maxHeight : 260,
                                size)),
                      ),
                    ),
                  ),
                ),
                if (!widget.compact) ...[
                  // Long press claims only the long press, so a plain tap
                  // still falls through to play/pause on the cover.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onLongPress: _revealPill,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Center(child: _syncPill(svc)),
                  ),
                ],
              ],
            ),
          );
        }

        // Strip across the bottom of the artwork: the same page in less room,
        // capped so it never swallows the whole cover.
        return Positioned.fill(
          child: Stack(children: [
            IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, box) {
                  final height = box.maxHeight.isFinite ? box.maxHeight : 260.0;
                  return Container(
                    padding: EdgeInsets.fromLTRB(padH, widget.compact ? 26 : 36,
                        padH, widget.compact ? 10 : 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                          Colors.black87
                        ],
                      ),
                    ),
                    child: _switcher(showBuffer
                        ? _waiting(context, svc)
                        : _page(svc, box.maxWidth - padH * 2, height * 0.6,
                            size)),
                  );
                },
              ),
            ),
          ),
            if (!widget.compact) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPress: _revealPill,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(child: _syncPill(svc)),
              ),
            ],
          ]),
        );
      },
    );
  }
}
