import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific extension for stream type.
extension GoogleCastAndroidStreamType on CastMediaStreamType {
  /// Creates a stream type from a map value.
  static CastMediaStreamType fromMap(String value) {
    return CastMediaStreamType.values.firstWhere(
      (element) => element.value == value,
      orElse: () => CastMediaStreamType.none,
    );
  }
}
