class SmartSkipJump {
  const SmartSkipJump({required this.fromSeconds, required this.toSeconds});

  final double fromSeconds;
  final double toSeconds;

  double get skippedSeconds => (toSeconds - fromSeconds).clamp(0.0, double.infinity).toDouble();
}
