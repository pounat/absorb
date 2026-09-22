import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific extension for repeat mode.
extension GoogleCastRepeatModeAndroid on GoogleCastMediaRepeatMode {
  /// Creates a repeat mode from a map value.
  static GoogleCastMediaRepeatMode fromMap(String value) {
    return GoogleCastMediaRepeatMode.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => GoogleCastMediaRepeatMode.unchanged,
    );
  }
}
