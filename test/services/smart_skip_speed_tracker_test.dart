import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/services/smart_skip_speed_tracker.dart';

void main() {
  test('display change compares against the last notified speed', () {
    expect(smartSkipDisplaySpeedChanged(1.25, 1.251), isFalse);
    expect(smartSkipDisplaySpeedChanged(1.25, 1.256), isTrue);
  });

  group('SmartSkipSpeedTracker', () {
    test('reports fallback speed until the session has enough data', () {
      final tracker = SmartSkipSpeedTracker(minSeconds: 3);
      final t0 = DateTime(2026, 1, 1, 12);

      expect(tracker.update(wallTime: t0, positionSeconds: 10, fallbackSpeed: 1.25), 1.25);
      expect(tracker.update(wallTime: t0.add(const Duration(seconds: 2)), positionSeconds: 12.5, fallbackSpeed: 1.25), 1.25);
    });

    test('calculates constant playback speed from position over wall time', () {
      final tracker = SmartSkipSpeedTracker(minSeconds: 3);
      final t0 = DateTime(2026, 1, 1, 12);

      tracker.update(wallTime: t0, positionSeconds: 0, fallbackSpeed: 1.0);
      final speed = tracker.update(wallTime: t0.add(const Duration(seconds: 10)), positionSeconds: 15, fallbackSpeed: 1.0);

      expect(speed, closeTo(1.5, 0.001));
    });

    test('includes skipped silence jumps in the effective speed', () {
      final tracker = SmartSkipSpeedTracker(minSeconds: 3);
      final t0 = DateTime(2026, 1, 1, 12);

      tracker.update(wallTime: t0, positionSeconds: 0, fallbackSpeed: 1.25);
      final speed = tracker.update(wallTime: t0.add(const Duration(seconds: 10)), positionSeconds: 20, fallbackSpeed: 1.25);

      expect(speed, closeTo(2.0, 0.001));
    });

    test('averages over the whole active play session', () {
      final tracker = SmartSkipSpeedTracker(minSeconds: 3);
      final t0 = DateTime(2026, 1, 1, 12);

      tracker.update(wallTime: t0, positionSeconds: 0, fallbackSpeed: 1.0);
      tracker.update(wallTime: t0.add(const Duration(seconds: 20)), positionSeconds: 20, fallbackSpeed: 1.0);
      final speed = tracker.update(wallTime: t0.add(const Duration(seconds: 40)), positionSeconds: 80, fallbackSpeed: 1.0);

      expect(speed, closeTo(2.0, 0.001));
    });

    test('accumulates small savings over the whole session', () {
      final tracker = SmartSkipSpeedTracker(minSeconds: 3);
      final t0 = DateTime(2026, 1, 1, 12);

      tracker.update(wallTime: t0, positionSeconds: 0, fallbackSpeed: 1.25);
      var speed = 1.25;
      for (var second = 1; second <= 60; second++) {
        speed = tracker.update(
          wallTime: t0.add(Duration(seconds: second)),
          positionSeconds: second * 1.5,
          fallbackSpeed: 1.25,
        );
      }

      expect(speed, closeTo(1.5, 0.001));
    });

    test('does not report slower than the configured playback speed', () {
      final tracker = SmartSkipSpeedTracker(minSeconds: 3);
      final t0 = DateTime(2026, 1, 1, 12);

      tracker.update(wallTime: t0, positionSeconds: 0, fallbackSpeed: 1.25);
      final speed = tracker.update(wallTime: t0.add(const Duration(seconds: 10)), positionSeconds: 12.1, fallbackSpeed: 1.25);

      expect(speed, 1.25);
    });

    test('resets on backward position jumps', () {
      final tracker = SmartSkipSpeedTracker(minSeconds: 3);
      final t0 = DateTime(2026, 1, 1, 12);

      tracker.update(wallTime: t0, positionSeconds: 100, fallbackSpeed: 1.0);
      tracker.update(wallTime: t0.add(const Duration(seconds: 10)), positionSeconds: 115, fallbackSpeed: 1.0);
      final speed = tracker.update(wallTime: t0.add(const Duration(seconds: 11)), positionSeconds: 20, fallbackSpeed: 1.25);

      expect(speed, 1.25);
      expect(tracker.effectiveSpeed, 1.25);
    });

    test('clamps absurd positive jumps', () {
      final tracker = SmartSkipSpeedTracker(minSeconds: 3, maxSpeed: 6);
      final t0 = DateTime(2026, 1, 1, 12);

      tracker.update(wallTime: t0, positionSeconds: 0, fallbackSpeed: 1.0);
      final speed = tracker.update(wallTime: t0.add(const Duration(seconds: 10)), positionSeconds: 500, fallbackSpeed: 1.0);

      expect(speed, 6.0);
    });
  });
}
