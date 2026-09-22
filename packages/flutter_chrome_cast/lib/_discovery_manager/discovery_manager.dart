import 'dart:io';
import 'package:flutter_chrome_cast/_discovery_manager/android_discovery_manager.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:flutter_chrome_cast/_discovery_manager/ios_discovery_manager.dart';

/// Main entry point for Google Cast device discovery functionality.
///
/// This class provides a platform-agnostic interface for discovering Google Cast
/// devices on the network. It automatically selects the appropriate platform-specific
/// implementation based on the current operating system.
class GoogleCastDiscoveryManager {
  static GoogleCastDiscoveryManagerPlatformInterface? _instance;

  /// Gets the singleton instance of the discovery manager.
  ///
  /// Returns the appropriate platform-specific implementation
  /// (Android or iOS) based on the current platform.
  static GoogleCastDiscoveryManagerPlatformInterface get instance {
    return _instance ??= Platform.isAndroid
        ? GoogleCastDiscoveryManagerMethodChannelAndroid()
        : GoogleCastDiscoveryManagerMethodChannelIOS();
  }

  /// Private constructor to enforce singleton pattern.
  GoogleCastDiscoveryManager._();
}
