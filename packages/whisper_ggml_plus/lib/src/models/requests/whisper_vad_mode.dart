enum WhisperVadMode {
  auto,
  disabled,
  enabled,
}

extension WhisperVadModeWireValue on WhisperVadMode {
  String get wireValue {
    switch (this) {
      case WhisperVadMode.auto:
        return 'auto';
      case WhisperVadMode.disabled:
        return 'disabled';
      case WhisperVadMode.enabled:
        return 'enabled';
    }
  }
}
