class SmartSkipSpeedSample {
  const SmartSkipSpeedSample({required this.wallTime, required this.positionSeconds});

  final DateTime wallTime;
  final double positionSeconds;
}

bool smartSkipDisplaySpeedChanged(double lastNotifiedSpeed, double nextSpeed) {
  return lastNotifiedSpeed.toStringAsFixed(2) != nextSpeed.toStringAsFixed(2);
}

/// Session effective-speed tracker for Smart-Skip.
///
/// The player reports raw content position. When silence is skipped that
/// position jumps farther than wall-clock time alone would explain, so the
/// ratio of content delta to wall-clock delta is the virtual playback speed.
/// The service resets this tracker on pauses, seeks, item changes, and speed
/// changes, so samples here represent only the current active play session.
class SmartSkipSpeedTracker {
  SmartSkipSpeedTracker({this.minSeconds = 3, this.minSpeed = 0.5, this.maxSpeed = 6.0});

  final double minSeconds;
  final double minSpeed;
  final double maxSpeed;
  final List<SmartSkipSpeedSample> _samples = [];

  double? _effectiveSpeed;
  double _estimatedSavedSeconds = 0;

  double? get effectiveSpeed => _effectiveSpeed;
  double get estimatedSavedSeconds => _estimatedSavedSeconds;

  void reset() {
    _samples.clear();
    _effectiveSpeed = null;
    _estimatedSavedSeconds = 0;
  }

  double update({required DateTime wallTime, required double positionSeconds, required double fallbackSpeed}) {
    if (!positionSeconds.isFinite || positionSeconds < 0) {
      reset();
      return fallbackSpeed;
    }

    if (_samples.isNotEmpty) {
      final previous = _samples.last;
      final wallDelta = wallTime.difference(previous.wallTime).inMilliseconds / 1000.0;
      final positionDelta = positionSeconds - previous.positionSeconds;

      if (wallDelta <= 0 || positionDelta < -0.25) {
        reset();
      }
    }

    _samples.add(SmartSkipSpeedSample(wallTime: wallTime, positionSeconds: positionSeconds));

    final speed = _calculate(fallbackSpeed);
    _effectiveSpeed = speed;
    return speed;
  }

  double _calculate(double fallbackSpeed) {
    if (_samples.length < 2) {
      _estimatedSavedSeconds = 0;
      return fallbackSpeed;
    }
    final first = _samples.first;
    final last = _samples.last;
    final wallDelta = last.wallTime.difference(first.wallTime).inMilliseconds / 1000.0;
    if (wallDelta <= 0) {
      _estimatedSavedSeconds = 0;
      return fallbackSpeed;
    }

    final positionDelta = last.positionSeconds - first.positionSeconds;
    if (positionDelta <= 0) {
      _estimatedSavedSeconds = 0;
      return fallbackSpeed;
    }

    final fallbackFloor = fallbackSpeed.isFinite && fallbackSpeed > 0 ? fallbackSpeed.clamp(minSpeed, maxSpeed).toDouble() : minSpeed;
    _estimatedSavedSeconds = (positionDelta - wallDelta * fallbackFloor).clamp(0.0, double.infinity).toDouble();
    if (wallDelta < minSeconds) return fallbackSpeed;

    final raw = positionDelta / wallDelta;
    if (!raw.isFinite || raw <= 0) return fallbackSpeed;
    return raw.clamp(fallbackFloor, maxSpeed).toDouble();
  }
}
