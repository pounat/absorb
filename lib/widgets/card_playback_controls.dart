import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'glass_look.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import 'card_buttons.dart';
import 'expressive.dart';

// ─── PLAYBACK CONTROLS (card version) ───────────────────────

class CardPlaybackControls extends StatefulWidget {
  final AudioPlayerService player;
  final Color accent;
  final bool isActive;
  final bool isStarting;
  final VoidCallback onStart;
  final String? itemId;
  final bool showPlayButton;
  final double playButtonSize;
  final String? libraryId;
  final FocusNode? playFocusNode;
  /// 0 as the card, rising to 1 as it grows into the full player, where the
  /// buttons get bigger to use the wider row.
  final double grow;
  const CardPlaybackControls({super.key, required this.player, required this.accent, required this.isActive, required this.isStarting, required this.onStart, this.itemId, this.showPlayButton = false, this.playButtonSize = 65, this.libraryId, this.playFocusNode, this.grow = 0});
  @override State<CardPlaybackControls> createState() => _CardPlaybackControlsState();
}

class _CardPlaybackControlsState extends State<CardPlaybackControls> {
  int _backSkip = 10;
  int _forwardSkip = 30;
  bool _longSkip = false;
  int _longBackSkip = 60;
  int _longForwardSkip = 60;

  @override void initState() {
    super.initState();
    _loadSkipSettings();
    PlayerSettings.settingsChanged.addListener(_loadSkipSettings);
  }

  void _loadSkipSettings() {
    PlayerSettings.getEffectiveBackSkip(libraryId: widget.libraryId).then((v) { if (mounted && v != _backSkip) setState(() => _backSkip = v); });
    PlayerSettings.getEffectiveForwardSkip(libraryId: widget.libraryId).then((v) { if (mounted && v != _forwardSkip) setState(() => _forwardSkip = v); });
    PlayerSettings.getLongSkipButtons().then((v) { if (mounted && v != _longSkip) setState(() => _longSkip = v); });
    PlayerSettings.getLongBackSkip().then((v) { if (mounted && v != _longBackSkip) setState(() => _longBackSkip = v); });
    PlayerSettings.getLongForwardSkip().then((v) { if (mounted && v != _longForwardSkip) setState(() => _longForwardSkip = v); });
  }

  @override void didUpdateWidget(CardPlaybackControls old) {
    super.didUpdateWidget(old);
    if (old.libraryId != widget.libraryId) _loadSkipSettings();
  }

  @override void dispose() {
    PlayerSettings.settingsChanged.removeListener(_loadSkipSettings);
    super.dispose();
  }

  Widget _skipIcon(int seconds, bool isForward, {bool active = true, double size = 42}) {
    final cs = Theme.of(context).colorScheme;
    final hasBuiltIn = [5, 10, 30].contains(seconds);
    if (hasBuiltIn) {
      IconData icon;
      if (isForward) { icon = seconds == 5 ? Icons.forward_5_rounded : seconds == 10 ? Icons.forward_10_rounded : Icons.forward_30_rounded; }
      else { icon = seconds == 5 ? Icons.replay_5_rounded : seconds == 10 ? Icons.replay_10_rounded : Icons.replay_30_rounded; }
      return Icon(icon, size: size, color: active ? cs.onSurface.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.24));
    }
    return Stack(alignment: Alignment.center, children: [
      Icon(isForward ? Icons.rotate_right_rounded : Icons.rotate_left_rounded, size: size, color: active ? cs.onSurface.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.24)),
      Padding(padding: const EdgeInsets.only(top: 2), child: Text('$seconds', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: active ? cs.onSurface : cs.onSurface.withValues(alpha: 0.24)))),
    ]);
  }

  // With the play circle plus the long pair the row holds seven controls, so
  // everything steps down a notch to keep it airy. The six-control cover-play
  // row keeps the regular sizes.
  bool get _sevenControls => _longSkip && widget.showPlayButton;

  /// The optional bigger jump (GH #242): same rotate glyph as the custom
  /// short-skip fallback but smaller, with a minutes label so the two pairs
  /// read differently at a glance.
  Widget _longSkipIcon(int seconds, bool isForward, {bool active = true}) {
    final cs = Theme.of(context).colorScheme;
    final label = seconds % 60 == 0 ? '${seconds ~/ 60}m' : '$seconds';
    return Stack(alignment: Alignment.center, children: [
      Icon(isForward ? Icons.rotate_right_rounded : Icons.rotate_left_rounded, size: 34, color: active ? cs.onSurface.withValues(alpha: 0.55) : cs.onSurface.withValues(alpha: 0.24)),
      Padding(padding: const EdgeInsets.only(top: 2), child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: active ? cs.onSurface.withValues(alpha: 0.8) : cs.onSurface.withValues(alpha: 0.24)))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cast = ChromecastService();

    return ListenableBuilder(
      listenable: Listenable.merge([cast, widget.player, expressiveNotifier]),
      builder: (context, _) {
        // Check if we're casting this specific book
        final castItemId = widget.itemId ?? widget.player.currentItemId;
        final isCastingThis = cast.isCasting && cast.castingItemId == castItemId;

        return _grown(isCastingThis ? _buildCastControls(cast) : _buildLocalControls());
      },
    );
  }

  /// The row drawn bigger for the full player: up to a quarter larger, less
  /// when that would leave the buttons touching.
  Widget _grown(Widget row) {
    if (widget.grow <= 0) return row;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (!width.isFinite) return row;
      final chBox = _sevenControls ? 46.0 : 52.0;
      final skBox = _sevenControls ? 54.0 : 60.0;
      final play = !widget.showPlayButton ? 0.0 : (_sevenControls ? 56.0 : widget.playButtonSize);
      final buttons = 2 * chBox + 2 * skBox + play + (_longSkip ? 96.0 : 0.0);
      final count = 4 + (widget.showPlayButton ? 1 : 0) + (_longSkip ? 2 : 0);
      const leastGap = 16.0;
      final most = (width - leastGap * (count - 1)) / buttons;
      final scale = math.min(1 + 0.25 * widget.grow, most);
      if (scale <= 1.01) return row;
      return FittedBox(
        fit: BoxFit.fitWidth,
        child: SizedBox(width: width / scale, child: row),
      );
    });
  }

  Widget _playPauseButton(ColorScheme cs, {required bool playing, required bool loading, required VoidCallback? onTap}) {
    final s = _sevenControls ? 56.0 : widget.playButtonSize;
    final iconSize = s * 0.49;
    final spinnerSize = s * 0.4;
    // The same soft cover color as the played part of the chapter bar,
    // made solid, with the icon in whichever of black or white reads on it.
    final fill = Color.alphaBlend(widget.accent.withValues(alpha: 0.38), cs.surface);
    final onFill = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : Colors.black;
    if (expressiveNotifier.value) {
      return Pressable(focusCircle: true, 
        onTap: onTap,
        focusNode: widget.playFocusNode,
        child: ExpressivePlayShape(
          size: s,
          playing: playing,
          color: fill,
          child: loading
              ? SizedBox(width: spinnerSize, height: spinnerSize, child: AdaptiveSpinner(strokeWidth: 2, color: onFill))
              : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: iconSize, color: onFill),
        ),
      );
    }
    return Pressable(focusCircle: true, 
      onTap: onTap,
      focusNode: widget.playFocusNode,
      child: Container(
        width: s, height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
        ),
        child: loading
            ? Center(child: SizedBox(width: spinnerSize, height: spinnerSize, child: AdaptiveSpinner(strokeWidth: 2, color: onFill)))
            : glassLook
            ? Center(child: MorphingPlayIcon(playing: playing, size: iconSize, color: onFill))
            : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: iconSize, color: onFill),
      ),
    );
  }

  /// Controls that route to ChromecastService
  Widget _buildCastControls(ChromecastService cast) {
    final cs = Theme.of(context).colorScheme;
    final chIcon = _sevenControls ? 30.0 : 34.0;
    final chBox = _sevenControls ? 46.0 : 52.0;
    final skIcon = _sevenControls ? 38.0 : 42.0;
    final skBox = _sevenControls ? 54.0 : 60.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Pressable(focusCircle: true, 
          onTap: cast.skipToPreviousChapter,
          child: ExpressiveControlBox(soft: false, width: chBox, height: chBox, child: Center(
            child: Icon(Icons.skip_previous_rounded, size: chIcon, color: cs.onSurfaceVariant),
          )),
        )),
        if (_longSkip)
          Flexible(child: Pressable(focusCircle: true, 
            onTap: () => cast.skipBackward(_longBackSkip),
            child: ExpressiveControlBox(soft: true, width: 48, height: skBox, child: Center(child: _longSkipIcon(_longBackSkip, false))),
          )),
        Flexible(child: Pressable(focusCircle: true, 
          onTap: () => cast.skipBackward(_backSkip),
          child: ExpressiveControlBox(soft: true, width: skBox, height: skBox, child: Center(child: _skipIcon(_backSkip, false, size: skIcon))),
        )),
        if (widget.showPlayButton)
          Flexible(child: _playPauseButton(cs, playing: cast.isReceiverActive, loading: false, onTap: cast.togglePlayPause)),
        Flexible(child: Pressable(focusCircle: true, 
          onTap: () => cast.skipForward(_forwardSkip),
          child: ExpressiveControlBox(soft: true, width: skBox, height: skBox, child: Center(child: _skipIcon(_forwardSkip, true, size: skIcon))),
        )),
        if (_longSkip)
          Flexible(child: Pressable(focusCircle: true, 
            onTap: () => cast.skipForward(_longForwardSkip),
            child: ExpressiveControlBox(soft: true, width: 48, height: skBox, child: Center(child: _longSkipIcon(_longForwardSkip, true))),
          )),
        Flexible(child: Pressable(focusCircle: true, 
          onTap: cast.skipToNextChapter,
          child: ExpressiveControlBox(soft: false, width: chBox, height: chBox, child: Center(
            child: Icon(Icons.skip_next_rounded, size: chIcon, color: cs.onSurfaceVariant),
          )),
        )),
      ],
    );
  }

  /// Original local player controls
  Widget _buildLocalControls() {
    final cs = Theme.of(context).colorScheme;
    final loading = widget.isStarting || (widget.isActive && widget.player.isLoadingOrBuffering && !widget.player.isPlaying);
    final chIcon = _sevenControls ? 30.0 : 34.0;
    final chBox = _sevenControls ? 46.0 : 52.0;
    final skIcon = _sevenControls ? 38.0 : 42.0;
    final skBox = _sevenControls ? 54.0 : 60.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Pressable(focusCircle: true, 
          onTap: widget.isActive ? widget.player.skipToPreviousChapter : null,
          child: ExpressiveControlBox(soft: false, width: chBox, height: chBox, child: Center(
            child: Icon(Icons.skip_previous_rounded, size: chIcon, color: widget.isActive ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.12)),
          )),
        )),
        if (_longSkip)
          Flexible(child: Pressable(focusCircle: true, 
            onTap: widget.isActive ? () => widget.player.skipBackward(_longBackSkip) : null,
            child: ExpressiveControlBox(soft: true, width: 48, height: skBox, child: Center(child: _longSkipIcon(_longBackSkip, false, active: widget.isActive))),
          )),
        Flexible(child: Pressable(focusCircle: true, 
          onTap: widget.isActive ? () => widget.player.skipBackward(_backSkip) : null,
          child: ExpressiveControlBox(soft: true, width: skBox, height: skBox, child: Center(child: _skipIcon(_backSkip, false, active: widget.isActive, size: skIcon))),
        )),
        if (widget.showPlayButton)
          Flexible(child: _playPauseButton(cs, playing: widget.isActive && widget.player.isPlaying, loading: loading,
            onTap: widget.isActive ? () => widget.player.togglePlayPause(fromUi: true) : widget.onStart)),
        Flexible(child: Pressable(focusCircle: true, 
          onTap: widget.isActive ? () => widget.player.skipForward(_forwardSkip) : null,
          child: ExpressiveControlBox(soft: true, width: skBox, height: skBox, child: Center(child: _skipIcon(_forwardSkip, true, active: widget.isActive, size: skIcon))),
        )),
        if (_longSkip)
          Flexible(child: Pressable(focusCircle: true, 
            onTap: widget.isActive ? () => widget.player.skipForward(_longForwardSkip) : null,
            child: ExpressiveControlBox(soft: true, width: 48, height: skBox, child: Center(child: _longSkipIcon(_longForwardSkip, true, active: widget.isActive))),
          )),
        Flexible(child: Pressable(focusCircle: true, 
          onTap: widget.isActive ? widget.player.skipToNextChapter : null,
          child: ExpressiveControlBox(soft: false, width: chBox, height: chBox, child: Center(
            child: Icon(Icons.skip_next_rounded, size: chIcon, color: widget.isActive ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.12)),
          )),
        )),
      ],
    );
  }
}
