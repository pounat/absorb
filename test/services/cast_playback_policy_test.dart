import 'package:absorb/services/cast_playback_policy.dart';
import 'package:absorb/services/sleep_timer_tick_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cast playback policy', () {
    test('buffering receiver with recently advancing position is active', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final receiverActive = isCastReceiverActive(
        CastPlaybackState.buffering,
        lastPositionAdvance: now.subtract(const Duration(seconds: 10)),
        now: now,
      );

      expect(receiverActive, isTrue);
      expect(shouldPauseCastOnToggle(CastPlaybackState.buffering), isTrue);
      expect(
        sleepTimerTickAction(
          timeRemaining: const Duration(minutes: 30),
          isPlaybackActive: receiverActive,
          isPauseRequested: false,
        ),
        SleepTimerTickAction.countDown,
      );
    });

    test('stale buffering position holds the timer and shows play', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final receiverActive = isCastReceiverActive(
        CastPlaybackState.buffering,
        lastPositionAdvance: now.subtract(const Duration(seconds: 31)),
        now: now,
      );

      expect(receiverActive, isFalse);
      expect(
        shouldPauseCastOnToggle(
          CastPlaybackState.buffering,
          receiverActive: receiverActive,
        ),
        isFalse,
      );
      expect(
        sleepTimerTickAction(
          timeRemaining: const Duration(minutes: 30),
          isPlaybackActive: receiverActive,
          isPauseRequested: false,
        ),
        SleepTimerTickAction.wait,
      );
    });

    test('acknowledged pause holds despite a recent buffering position', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final receiverActive = isCastReceiverActive(
        CastPlaybackState.buffering,
        lastPositionAdvance: now.subtract(const Duration(seconds: 1)),
        now: now,
        isPauseRequested: true,
      );

      expect(receiverActive, isFalse);
      expect(
        shouldPauseCastOnToggle(
          CastPlaybackState.paused,
          receiverActive: receiverActive,
        ),
        isFalse,
      );
      expect(
        sleepTimerTickAction(
          timeRemaining: const Duration(minutes: 30),
          isPlaybackActive: receiverActive,
          isPauseRequested: false,
        ),
        SleepTimerTickAction.wait,
      );
    });

    test('delayed position and buffering events do not undo pause intent', () {
      const pausedBySender = true;

      // A position packet that was in flight before pause() completed is not
      // receiver resume evidence, and neither is a stale buffering status.
      expect(shouldClearCastPauseIntent(CastPlaybackState.buffering), isFalse);
      expect(shouldClearCastPauseIntent(CastPlaybackState.paused), isFalse);
      expect(
        isCastReceiverActive(
          CastPlaybackState.buffering,
          lastPositionAdvance: DateTime.utc(2026, 1, 1, 12),
          now: DateTime.utc(2026, 1, 1, 12, 0, 1),
          isPauseRequested: pausedBySender,
        ),
        isFalse,
      );
      expect(
        shouldPauseCastOnToggle(
          CastPlaybackState.buffering,
          receiverActive: false,
        ),
        isFalse,
      );
    });

    test('a single delayed position does not undo pause, but continued progress does', () {
      final intent = CastPlaybackIntent()..requestPause();

      // This packet may have been queued before pause() completed.
      expect(intent.recordPositionAdvance(), CastPositionEvidence.none);
      expect(intent.isPauseRequested, isTrue);
      expect(isCastReceiverActive(
        CastPlaybackState.buffering,
        lastPositionAdvance: DateTime.utc(2026, 1, 1, 12),
        now: DateTime.utc(2026, 1, 1, 12, 0, 1),
        isPauseRequested: intent.isPauseRequested,
      ), isFalse);

      // Repeated progress proves that the receiver ignored the pause command.
      expect(intent.recordPositionAdvance(), CastPositionEvidence.pauseIgnored);
      expect(intent.isPauseRequested, isFalse);
      expect(isCastReceiverActive(
        CastPlaybackState.buffering,
        lastPositionAdvance: DateTime.utc(2026, 1, 1, 12),
        now: DateTime.utc(2026, 1, 1, 12, 0, 1),
        isPauseRequested: intent.isPauseRequested,
      ), isTrue);
    });

    test('failed pause has no sender intent and confirmed resume clears it', () {
      final intent = CastPlaybackIntent();
      // A failed command never records an intent, so playback remains live.
      expect(intent.value, CastCommandIntent.none);
      intent.requestPause();
      intent.clear(); // successful play / receiver playing confirmation
      expect(intent.value, CastCommandIntent.none);
    });

    test('play intent replaces pause and position confirms the resume', () {
      final intent = CastPlaybackIntent()..requestPause();

      intent.requestPlay();
      expect(intent.isPauseRequested, isFalse);
      expect(intent.isPlayRequested, isTrue);
      expect(intent.recordPositionAdvance(), CastPositionEvidence.playConfirmed);
      expect(intent.value, CastCommandIntent.none);
    });

    test('confirmed playing or resume is the only status pause-intent reset', () {
      expect(shouldClearCastPauseIntent(CastPlaybackState.playing), isTrue);
      expect(shouldClearCastPauseIntent(CastPlaybackState.buffering), isFalse);
    });

    test('buffering liveness exposes a finite rebuild deadline', () {
      final positionAdvance = DateTime.utc(2026, 1, 1, 12);
      expect(
        castBufferingLivenessDeadline(
          CastPlaybackState.buffering,
          lastPositionAdvance: positionAdvance,
        ),
        positionAdvance.add(staleCastBufferingGrace),
      );
      expect(
        castBufferingLivenessDeadline(
          CastPlaybackState.buffering,
          lastPositionAdvance: positionAdvance,
          isPauseRequested: true,
        ),
        isNull,
      );
    });

    test('loading receiver pauses on toggle but does not run sleep timer', () {
      expect(isCastReceiverActive(CastPlaybackState.loading), isFalse);
      expect(shouldPauseCastOnToggle(CastPlaybackState.loading), isTrue);
    });

    test('playing receiver is active and pauses on toggle', () {
      expect(isCastReceiverActive(CastPlaybackState.playing), isTrue);
      expect(shouldPauseCastOnToggle(CastPlaybackState.playing), isTrue);
    });

    test('buffering without receiver position evidence holds the timer', () {
      expect(isCastReceiverActive(CastPlaybackState.buffering), isFalse);
      expect(
        shouldPauseCastOnToggle(
          CastPlaybackState.buffering,
          receiverActive: false,
        ),
        isFalse,
      );
    });

    test('paused and idle receivers are inactive and toggle to play', () {
      for (final state in [CastPlaybackState.paused, CastPlaybackState.idle]) {
        expect(isCastReceiverActive(state), isFalse);
        expect(shouldPauseCastOnToggle(state), isFalse);
      }
    });
  });
}
