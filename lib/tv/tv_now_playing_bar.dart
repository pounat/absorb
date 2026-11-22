import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_player_service.dart';
import '../widgets/absorb_wave_icon.dart';
import 'tv_cover_tile.dart';

/// What's playing, as a small pill in the corner while browsing. Holding OK
/// anywhere opens the player for it.
class TvNowPlayingBar extends StatefulWidget {
  final String? hint;

  const TvNowPlayingBar({super.key, this.hint});

  @override
  State<TvNowPlayingBar> createState() => _TvNowPlayingBarState();
}

class _TvNowPlayingBarState extends State<TvNowPlayingBar> {
  final _player = AudioPlayerService();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _player.addListener(_changed);
    // Once a second is plenty for a progress line, and cheap.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _changed());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _player.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_player.hasBook) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = _player.totalDuration;
    final pos = _player.position.inMilliseconds / 1000;
    final pct = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
    final title = _player.currentEpisodeTitle ?? _player.currentTitle ?? '';

    return ExcludeFocus(
      child: Container(
        width: 250,
        padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(children: [
          ClipOval(
            child: SizedBox.square(
              dimension: 30,
              child: TvCover(itemId: _player.currentItemId, title: title, author: '', width: 100),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelLarge),
                if (widget.hint != null)
                  Text(widget.hint!, maxLines: 1, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
                const SizedBox(height: 3),
                LinearProgressIndicator(value: pct, minHeight: 2, borderRadius: BorderRadius.circular(1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _player.isPlaying
              ? AbsorbWaveIcon(size: 16, color: cs.primary)
              : Icon(Icons.pause_rounded, size: 16, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}
