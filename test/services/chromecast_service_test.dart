import 'dart:async';

import 'package:absorb/services/cast_playback_policy.dart';
import 'package:absorb/services/chromecast_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChromecastService Cast pause seam', () {
    test('status and position streams retain a pause through delayed buffering',
        () async {
      final statuses = StreamController<CastPlaybackState>();
      final positions = StreamController<Duration>();
      var pauseCalls = 0;
      var playCalls = 0;
      final service = ChromecastService.forTesting(
        pauseCommand: () async => pauseCalls++,
        playCommand: () async => playCalls++,
        mediaStatusStream: statuses.stream,
        positionStream: positions.stream,
      )..setTestReceiverState(CastPlaybackState.playing);
      addTearDown(() async {
        service.dispose();
        await statuses.close();
        await positions.close();
      });

      await service.pause();
      positions.add(const Duration(seconds: 10));
      statuses.add(CastPlaybackState.buffering);
      await Future<void>.delayed(Duration.zero);

      expect(pauseCalls, 1);
      expect(service.playbackState, CastPlaybackState.buffering);
      expect(service.isReceiverActive, isFalse);
      expect(service.shouldPauseOnToggle, isFalse);

      await service.togglePlayPause();
      expect(playCalls, 1);
    });

    test(
      'public toggle remains pauseable after resume ACK and reordered stale streams',
      () async {
        final statuses = StreamController<CastPlaybackState>();
        final positions = StreamController<Duration>();
        var pauseCalls = 0;
        var playCalls = 0;
        final service = ChromecastService.forTesting(
          pauseCommand: () async => pauseCalls++,
          playCommand: () async => playCalls++,
          mediaStatusStream: statuses.stream,
          positionStream: positions.stream,
        )..setTestReceiverState(CastPlaybackState.playing);
        addTearDown(() async {
          service.dispose();
          await statuses.close();
          await positions.close();
        });

        await service.togglePlayPause();
        statuses
          ..add(CastPlaybackState.paused)
          ..add(CastPlaybackState.buffering);
        positions.add(const Duration(seconds: 10));
        await Future<void>.delayed(Duration.zero);
        expect(pauseCalls, 1);
        expect(service.shouldPauseOnToggle, isFalse);
        expect(service.isReceiverActive, isFalse);
        expect(service.consumeTestTimeListened(DateTime.now()), 0);

        await service.togglePlayPause();
        expect(playCalls, 1);
        expect(service.shouldPauseOnToggle, isTrue);
        expect(service.isReceiverActive, isTrue);

        statuses.add(CastPlaybackState.paused);
        positions.add(const Duration(seconds: 11));
        await Future<void>.delayed(Duration.zero);
        expect(service.shouldPauseOnToggle, isTrue);
        expect(service.isReceiverActive, isTrue);

        await service.togglePlayPause();
        expect(pauseCalls, 2);
        expect(playCalls, 1);
        expect(service.shouldPauseOnToggle, isFalse);
        expect(service.isReceiverActive, isFalse);

        await service.togglePlayPause();
        expect(playCalls, 2);
        statuses.add(CastPlaybackState.buffering);
        positions.add(const Duration(seconds: 12));
        await Future<void>.delayed(Duration.zero);
        await service.togglePlayPause();
        expect(pauseCalls, 3);
        expect(playCalls, 2);
      },
    );

    testWidgets('unconfirmed resume intent expires back to receiver state',
        (tester) async {
      final service = ChromecastService.forTesting(playCommand: () async {})
        ..setTestReceiverState(CastPlaybackState.paused);
      addTearDown(service.dispose);
      var notifications = 0;
      service.addListener(() => notifications++);

      await service.togglePlayPause();
      expect(service.shouldPauseOnToggle, isTrue);
      expect(service.isReceiverActive, isTrue);
      final afterResumeNotifications = notifications;

      await tester.pump(castResumeIntentGrace);

      expect(service.playbackState, CastPlaybackState.paused);
      expect(service.shouldPauseOnToggle, isFalse);
      expect(service.isReceiverActive, isFalse);
      expect(notifications, greaterThan(afterResumeNotifications));
    });

    test('thrown play command keeps paused receiver inactive', () async {
      var playCalls = 0;
      final service = ChromecastService.forTesting(
        playCommand: () {
          playCalls++;
          return Future<void>.error(StateError('receiver rejected play'));
        },
      )..setTestReceiverState(CastPlaybackState.paused);
      addTearDown(service.dispose);

      await service.togglePlayPause();

      expect(playCalls, 1);
      expect(service.playbackState, CastPlaybackState.paused);
      expect(service.shouldPauseOnToggle, isFalse);
      expect(service.isReceiverActive, isFalse);
    });

    test('toggle is a command no-op while disconnected', () async {
      var pauseCalls = 0;
      var playCalls = 0;
      final service = ChromecastService.forTesting(
        pauseCommand: () async => pauseCalls++,
        playCommand: () async => playCalls++,
      )..setTestReceiverState(CastPlaybackState.playing, connected: false);
      addTearDown(service.dispose);

      await service.togglePlayPause();

      expect(pauseCalls, 0);
      expect(playCalls, 0);
      expect(service.playbackState, CastPlaybackState.playing);
    });

    test('confirmed playing after play clears pause intent through status stream',
        () async {
      final statuses = StreamController<CastPlaybackState>();
      var playCalls = 0;
      final service = ChromecastService.forTesting(
        playCommand: () async => playCalls++,
        mediaStatusStream: statuses.stream,
      )..setTestReceiverState(CastPlaybackState.paused);
      addTearDown(() async {
        service.dispose();
        await statuses.close();
      });

      await service.play();
      statuses.add(CastPlaybackState.playing);
      await Future<void>.delayed(Duration.zero);

      expect(playCalls, 1);
      expect(service.playbackState, CastPlaybackState.playing);
      expect(service.isReceiverActive, isTrue);
    });

    test('sleep pause survives reconnect and is applied once connected',
        () async {
      var pauseCalls = 0;
      final service = ChromecastService.forTesting(
        pauseCommand: () async => pauseCalls++,
      )..setTestReconnecting(true);
      addTearDown(service.dispose);

      await service.pauseNowOrOnReconnect();
      expect(pauseCalls, 0);
      expect(service.isReconnecting, isTrue);

      await service.completeTestReconnect();
      expect(pauseCalls, 1);
      expect(service.playbackState, CastPlaybackState.paused);
    });

    test('paused Cast time-listened sync consumes no paused seconds', () {
      final service = ChromecastService.forTesting()
        ..setTestReceiverState(CastPlaybackState.paused);
      addTearDown(service.dispose);

      expect(
        service.consumeTestTimeListened(DateTime.now().add(const Duration(minutes: 2))),
        0,
      );
    });
    test('successful pause command immediately renders paused', () async {
      var pauseCalls = 0;
      final service = ChromecastService.forTesting(
        pauseCommand: () async => pauseCalls++,
      )..setTestReceiverState(CastPlaybackState.playing);
      addTearDown(service.dispose);

      await service.pause();

      expect(pauseCalls, 1);
      expect(service.playbackState, CastPlaybackState.paused);
      expect(service.isReceiverActive, isFalse);
      expect(service.shouldPauseOnToggle, isFalse);
    });

    test('thrown pause command leaves a playing receiver active', () async {
      final service = ChromecastService.forTesting(
        pauseCommand: () =>
            Future<void>.error(StateError('receiver rejected pause')),
      )..setTestReceiverState(CastPlaybackState.playing);
      addTearDown(service.dispose);

      await service.pause();

      expect(service.playbackState, CastPlaybackState.playing);
      expect(service.isReceiverActive, isTrue);
      expect(service.shouldPauseOnToggle, isTrue);
    });

    test(
      'continued position progress after ignored pause restores playing and notifies',
      () async {
        final service = ChromecastService.forTesting(pauseCommand: () async {})
          ..setTestReceiverState(CastPlaybackState.playing);
        addTearDown(service.dispose);
        var notifications = 0;
        service.addListener(() => notifications++);

        await service.pause();
        final afterPauseNotifications = notifications;
        service.handleTestPosition(const Duration(seconds: 10));
        expect(service.playbackState, CastPlaybackState.paused);
        service.handleTestPosition(const Duration(seconds: 11));

        expect(service.playbackState, CastPlaybackState.playing);
        expect(service.isReceiverActive, isTrue);
        expect(service.shouldPauseOnToggle, isTrue);
        expect(notifications, greaterThan(afterPauseNotifications));
      },
    );

    testWidgets(
      'buffering liveness expiry notifies without another position event',
      (tester) async {
        var now = DateTime.utc(2026, 1, 1, 12);
        final service = ChromecastService.forTesting(now: () => now)
          ..setTestReceiverState(CastPlaybackState.buffering);
        addTearDown(service.dispose);
        var notifications = 0;
        service.addListener(() => notifications++);

        service.handleTestPosition(const Duration(seconds: 10));
        final afterPositionNotifications = notifications;
        expect(service.isReceiverActive, isTrue);

        now = now.add(const Duration(seconds: 31));
        await tester.pump(const Duration(seconds: 31));

        expect(service.isReceiverActive, isFalse);
        expect(notifications, greaterThan(afterPositionNotifications));
      },
    );
  });
}
