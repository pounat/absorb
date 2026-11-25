import 'package:flutter/material.dart';

/// A wrapping control group; it never owns, starts or disposes an audio engine.
class TeslaPlaybackControls extends StatelessWidget {
  final bool playing;
  final bool loading;
  final VoidCallback? onPlay, onBack, onForward, onPrevious, onNext;
  const TeslaPlaybackControls({super.key, required this.playing, required this.loading,
    required this.onPlay, required this.onBack, required this.onForward,
    required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    Widget button(String label, IconData icon, VoidCallback? action, double size) =>
      SizedBox(width: size, height: size, child: IconButton(
        tooltip: label, onPressed: action,
        icon: label == 'Back 15 seconds'
            ? Stack(alignment: Alignment.center, children: [
                const Icon(Icons.replay_rounded, size: 40),
                Padding(padding: const EdgeInsets.only(top: 6),
                  child: Text('15', textScaler: TextScaler.noScaling,
                    style: Theme.of(context).textTheme.labelSmall)),
              ])
            : Icon(icon, size: size == 60 ? 32 : 26),
        style: IconButton.styleFrom(minimumSize: Size.square(size)),
      ));
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 8, children: [
        button('Back 15 seconds', Icons.replay_rounded, onBack, 60),
        SizedBox(width: 60, height: 60, child: IconButton.filled(
          tooltip: playing ? 'Pause' : 'Play', onPressed: loading ? null : onPlay,
          icon: loading ? const SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 34),
        )),
        button('Forward 30 seconds', Icons.forward_30_rounded, onForward, 60),
      ]),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, spacing: 24, runSpacing: 8, children: [
        button('Previous chapter', Icons.skip_previous_rounded, onPrevious, 48),
        button('Next chapter', Icons.skip_next_rounded, onNext, 48),
      ]),
    ]);
  }
}
