import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import 'card_buttons.dart';

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
  const CardPlaybackControls({super.key, required this.player, required this.accent, required this.isActive, required this.isStarting, required this.onStart, this.itemId, this.showPlayButton = false, this.playButtonSize = 65, this.libraryId});
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
      listenable: Listenable.merge([cast, widget.player]),
      builder: (context, _) {
        // Check if we're casting this specific book
        final castItemId = widget.itemId ?? widget.player.currentItemId;
        final isCastingThis = cast.isCasting && cast.castingItemId == castItemId;

        if (isCastingThis) {
          return _buildCastControls(cast);
        }

        return _buildLocalControls();
      },
    );
  }

  Widget _playPauseButton(ColorScheme cs, {required bool playing, required bool loading, required VoidCallback? onTap}) {
    final s = _sevenControls ? 56.0 : widget.playButtonSize;
    final iconSize = s * 0.49;
    final spinnerSize = s * 0.4;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: s, height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.onSurface,
          boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.4), blurRadius: 25, spreadRadius: -5)],
        ),
        child: loading
            ? Center(child: SizedBox(width: spinnerSize, height: spinnerSize, child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent)))
            : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: iconSize, color: cs.surface),
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
        Flexible(child: Pressable(
          onTap: cast.skipToPreviousChapter,
          child: SizedBox(width: chBox, height: chBox, child: Center(
            child: Icon(Icons.skip_previous_rounded, size: chIcon, color: cs.onSurfaceVariant),
          )),
        )),
        if (_longSkip)
          Flexible(child: Pressable(
            onTap: () => cast.skipBackward(_longBackSkip),
            child: SizedBox(width: 48, height: skBox, child: Center(child: _longSkipIcon(_longBackSkip, false))),
          )),
        Flexible(child: Pressable(
          onTap: () => cast.skipBackward(_backSkip),
          child: SizedBox(width: skBox, height: skBox, child: Center(child: _skipIcon(_backSkip, false, size: skIcon))),
        )),
        if (widget.showPlayButton)
          Flexible(child: _playPauseButton(cs, playing: cast.isPlaying, loading: false, onTap: cast.togglePlayPause)),
        Flexible(child: Pressable(
          onTap: () => cast.skipForward(_forwardSkip),
          child: SizedBox(width: skBox, height: skBox, child: Center(child: _skipIcon(_forwardSkip, true, size: skIcon))),
        )),
        if (_longSkip)
          Flexible(child: Pressable(
            onTap: () => cast.skipForward(_longForwardSkip),
            child: SizedBox(width: 48, height: skBox, child: Center(child: _longSkipIcon(_longForwardSkip, true))),
          )),
        Flexible(child: Pressable(
          onTap: cast.skipToNextChapter,
          child: SizedBox(width: chBox, height: chBox, child: Center(
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
        Flexible(child: Pressable(
          onTap: widget.isActive ? widget.player.skipToPreviousChapter : null,
          child: SizedBox(width: chBox, height: chBox, child: Center(
            child: Icon(Icons.skip_previous_rounded, size: chIcon, color: widget.isActive ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.12)),
          )),
        )),
        if (_longSkip)
          Flexible(child: Pressable(
            onTap: widget.isActive ? () => widget.player.skipBackward(_longBackSkip) : null,
            child: SizedBox(width: 48, height: skBox, child: Center(child: _longSkipIcon(_longBackSkip, false, active: widget.isActive))),
          )),
        Flexible(child: Pressable(
          onTap: widget.isActive ? () => widget.player.skipBackward(_backSkip) : null,
          child: SizedBox(width: skBox, height: skBox, child: Center(child: _skipIcon(_backSkip, false, active: widget.isActive, size: skIcon))),
        )),
        if (widget.showPlayButton)
          Flexible(child: _playPauseButton(cs, playing: widget.isActive && widget.player.isPlaying, loading: loading,
            onTap: widget.isActive ? () => widget.player.togglePlayPause(fromUi: true) : widget.onStart)),
        Flexible(child: Pressable(
          onTap: widget.isActive ? () => widget.player.skipForward(_forwardSkip) : null,
          child: SizedBox(width: skBox, height: skBox, child: Center(child: _skipIcon(_forwardSkip, true, active: widget.isActive, size: skIcon))),
        )),
        if (_longSkip)
          Flexible(child: Pressable(
            onTap: widget.isActive ? () => widget.player.skipForward(_longForwardSkip) : null,
            child: SizedBox(width: 48, height: skBox, child: Center(child: _longSkipIcon(_longForwardSkip, true, active: widget.isActive))),
          )),
        Flexible(child: Pressable(
          onTap: widget.isActive ? widget.player.skipToNextChapter : null,
          child: SizedBox(width: chBox, height: chBox, child: Center(
            child: Icon(Icons.skip_next_rounded, size: chIcon, color: widget.isActive ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.12)),
          )),
        )),
      ],
    );
  }
}
