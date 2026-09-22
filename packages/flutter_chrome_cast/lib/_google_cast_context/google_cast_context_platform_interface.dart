import 'package:flutter_chrome_cast/entities/cast_options.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for Google Cast context functionality.
///
/// This abstract class defines the contract that platform-specific implementations
/// must follow for initializing and managing the Google Cast context.
abstract class GoogleCastContextPlatformInterface extends PlatformInterface {
  /// Creates a new instance of the platform interface.
  GoogleCastContextPlatformInterface() : super(token: Object());

//MARK: - CONTEXT
  /// Initializes the shared Google Cast context with the provided options.
  ///
  /// [castOptions] contains the configuration options for the Cast context.
  /// Returns true if the initialization was successful, false otherwise.
  Future<bool> setSharedInstanceWithOptions(GoogleCastOptions castOptions);
}
