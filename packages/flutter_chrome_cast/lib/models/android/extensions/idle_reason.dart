import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific extension for idle reason.
extension GoogleCastIdleReasonAndroid on GoogleCastMediaIdleReason {
  /// Creates an idle reason from a map value.
  static GoogleCastMediaIdleReason fromMap(String value) {
    return GoogleCastMediaIdleReason.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => GoogleCastMediaIdleReason.none,
    );
  }
}
