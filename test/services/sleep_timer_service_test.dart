import 'dart:async';

import 'package:absorb/services/cast_playback_policy.dart';
import 'package:absorb/services/chromecast_service.dart';
import 'package:absorb/services/sleep_timer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('expiry stays armed when Cast rejects pause', (tester) async {
    SharedPreferences.setMockInitialValues({'shakeMode': 'off'});
    var calls = 0;
    final cast = ChromecastService.forTesting(
      pauseCommand: () async {
        if (++calls == 1) throw StateError('receiver rejected pause');
      },
    )..setTestReceiverState(CastPlaybackState.playing);
    final timer = SleepTimerService.forTesting(cast);
    addTearDown(cast.dispose);
    addTearDown(timer.dispose);
    timer.setTimeSleep(Duration.zero);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    expect(cast.isReceiverActive, isTrue);
    expect(timer.isActive, isTrue);

    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    for (var tick = 0; tick < 5; tick++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(calls, 2);
    expect(cast.isReceiverActive, isFalse);
    expect(timer.isActive, isFalse);
  });

  for (final resetOnResume in [true, false]) {
    testWidgets('quick Cast pause/resume honors reset=$resetOnResume', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'shakeMode': 'off',
        'resetSleepOnPause': resetOnResume,
      });
      final statuses = StreamController<CastPlaybackState>();
      final cast = ChromecastService.forTesting(
        mediaStatusStream: statuses.stream,
      )..setTestReceiverState(CastPlaybackState.playing);
      final timer = SleepTimerService.forTesting(cast);
      addTearDown(() => unawaited(statuses.close()));
      addTearDown(cast.dispose);
      addTearDown(timer.dispose);
      const duration = Duration(minutes: 2);
      timer.setTimeSleep(duration);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(timer.timeRemaining, duration - const Duration(seconds: 1));

      statuses.add(CastPlaybackState.paused);
      statuses.add(CastPlaybackState.playing);
      await tester.pump();
      expect(
        timer.timeRemaining,
        resetOnResume ? duration : duration - const Duration(seconds: 1),
      );
      timer.cancel();
    });
  }

  testWidgets('old Cast pause result does not clear a replacement timer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'shakeMode': 'off'});
    final pause = Completer<void>();
    final cast = ChromecastService.forTesting(pauseCommand: () => pause.future)
      ..setTestReceiverState(CastPlaybackState.playing);
    final timer = SleepTimerService.forTesting(cast);
    addTearDown(cast.dispose);
    addTearDown(timer.dispose);
    timer.setTimeSleep(Duration.zero);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(timer.isActive, isTrue);

    const replacement = Duration(minutes: 2);
    timer.setTimeSleep(replacement);
    await tester.pump();
    pause.complete();
    await tester.pump();
    expect(timer.isActive, isTrue);
    expect(timer.timeRemaining, replacement);
    timer.cancel();
  });
}
