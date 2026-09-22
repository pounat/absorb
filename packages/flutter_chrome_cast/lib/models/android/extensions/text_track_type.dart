import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific extension for text track type.
extension GoogleCastTextTrackStyleAndroid on TextTrackType {
  /// Creates a text track type from a map value.
  static TextTrackType fromMap(String value) {
    return TextTrackType.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => TextTrackType.unknown,
    );
  }
}
