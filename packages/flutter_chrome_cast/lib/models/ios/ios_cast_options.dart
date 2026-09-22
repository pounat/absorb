import 'package:flutter_chrome_cast/entities/discovery_criteria.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';

/// iOS-specific Google Cast options.
///
/// This class extends [GoogleCastOptions] to provide additional configuration
/// for iOS, such as specifying discovery criteria for Cast devices.
class IOSGoogleCastOptions extends GoogleCastOptions {
  /// The discovery criteria used to find Cast devices on iOS.
  final GoogleCastDiscoveryCriteriaInitialize _discoveryCriteria;

  /// Creates an instance of [IOSGoogleCastOptions] with the given [discoveryCriteria].
  ///
  /// [stopCastingOnAppTerminated] when set to true, will automatically stop
  /// casting and end the session when the app is killed/terminated. Defaults to false.
  IOSGoogleCastOptions(
    this._discoveryCriteria, {
    super.stopCastingOnAppTerminated,
  });

  /// Converts this iOS Cast options object to a map representation.
  ///
  /// The returned map includes all base options and the iOS-specific discovery criteria.
  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll(
        {
          'discoveryCriteria': _discoveryCriteria.toMap(),
        },
      );
  }
}
