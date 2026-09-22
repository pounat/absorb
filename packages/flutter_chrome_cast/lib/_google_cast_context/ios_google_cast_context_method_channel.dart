import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';
import 'google_cast_context_platform_interface.dart';

/// iOS-specific implementation of Google Cast context functionality.
///
/// This class provides the iOS platform implementation for initializing
/// and managing the Google Cast context using method channels.
class FlutterIOSGoogleCastContextMethodChannel
    extends GoogleCastContextPlatformInterface {
  static const _methodChannel = MethodChannel('google_cast.context');

  @override
  Future<bool> setSharedInstanceWithOptions(
      GoogleCastOptions castOptions) async {
    try {
      final result = await _methodChannel.invokeMethod(
        'setSharedInstanceWithOptions',
        castOptions.toMap(),
      );
      return result == true;
    } catch (e) {
      rethrow;
    }
  }
}
