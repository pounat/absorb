import 'dart:io';

import 'package:flutter_chrome_cast/_session_manager/android_cast_session_manager.dart';
import 'package:flutter_chrome_cast/_session_manager/ios_cast_session_manager.dart';

import 'cast_session_manager_platform.dart';

/// Main entry point for Google Cast session management functionality.
///
/// This class provides a platform-agnostic interface for managing Cast sessions,
/// including starting, ending, and monitoring session state. It automatically
/// selects the appropriate platform-specific implementation based on the current OS.
class GoogleCastSessionManager {
  static final GoogleCastSessionManagerPlatformInterface _instance =
      Platform.isAndroid
          ? GoogleCastSessionManagerAndroidMethodChannel()
          : GoogleCastSessionManagerIOSMethodChannel();

  /// Gets the singleton instance of the session manager.
  ///
  /// Returns the appropriate platform-specific implementation
  /// (Android or iOS) based on the current platform.
  static GoogleCastSessionManagerPlatformInterface get instance => _instance;

  GoogleCastSessionManager._();
}
