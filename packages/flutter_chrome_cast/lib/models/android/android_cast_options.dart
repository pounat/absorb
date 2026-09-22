import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific cast options configuration.
class GoogleCastOptionsAndroid extends GoogleCastOptions {
  /// The Cast application ID.
  final String appId;

  /// Creates a new [GoogleCastOptionsAndroid].
  ///
  /// [appId] is required and specifies the Cast application ID.
  ///
  /// [stopCastingOnAppTerminated] when set to true, will automatically stop
  /// casting and end the session when the app is killed/terminated. Defaults to false.
  GoogleCastOptionsAndroid({
    required this.appId,
    super.stopCastingOnAppTerminated,
  });

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll({
        'appId': appId,
      });
  }
}
