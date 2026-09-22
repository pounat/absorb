import 'dart:io';

import 'package:flutter_chrome_cast/_google_cast_context/android_google_cast_context_method_channel.dart';
import 'package:flutter_chrome_cast/_google_cast_context/google_cast_context_platform_interface.dart';

import 'ios_google_cast_context_method_channel.dart';

/// Main entry point for Google Cast context functionality.
///
/// This class provides a platform-agnostic interface for initializing and
/// managing the Google Cast context. It automatically selects the appropriate
/// platform-specific implementation based on the current operating system.
class GoogleCastContext {
  static final GoogleCastContextPlatformInterface _instance = Platform.isAndroid
      ? GoogleCastContextAndroidMethodChannel()
      : FlutterIOSGoogleCastContextMethodChannel();

  /// Gets the singleton instance of the Google Cast context.
  ///
  /// Returns the appropriate platform-specific implementation
  /// (Android or iOS) based on the current platform.
  static GoogleCastContextPlatformInterface instance = _instance;

  /// Private constructor to enforce singleton pattern.
  GoogleCastContext._();
}
