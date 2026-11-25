import 'package:flutter/material.dart';

/// Shared player-controls slot for a browser recovery notice.
class PlaybackRecoveryNotice extends StatelessWidget {
  const PlaybackRecoveryNotice({
    super.key,
    required this.isWeb,
    required this.isActive,
    required this.recoveryRequired,
    required this.message,
    required this.child,
  });

  final bool isWeb;
  final bool isActive;
  final bool recoveryRequired;
  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isWeb || !isActive || !recoveryRequired) return child;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: const ValueKey('playback-recovery-notice'),
          liveRegion: true,
          container: true,
          child: ColoredBox(
            key: const ValueKey('playback-recovery-background'),
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                message ?? 'Playback paused. Press Play to recover.',
                softWrap: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
