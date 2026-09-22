import 'dart:io';

import 'package:flutter_chrome_cast/_remote_media_client/remote_media_client_platform.dart';

import 'android_remote_media_client_method_channel.dart';
import 'ios_remote_media_client_method_channel.dart';

/// Main entry point for Google Cast remote media client functionality.
///
/// This class provides a platform-agnostic interface for controlling media
/// playback on Google Cast devices. It automatically selects the appropriate
/// platform-specific implementation based on the current operating system.
class GoogleCastRemoteMediaClient {
  /// Private constructor to enforce singleton pattern.
  GoogleCastRemoteMediaClient._();

  static final GoogleCastRemoteMediaClientPlatformInterface _instance =
      Platform.isAndroid
          ? GoogleCastRemoteMediaClientAndroidMethodChannel()
          : GoogleCastRemoteMediaClientIOSMethodChannel();

  /// Gets the singleton instance of the remote media client.
  ///
  /// Returns the appropriate platform-specific implementation
  /// (Android or iOS) based on the current platform.
  static GoogleCastRemoteMediaClientPlatformInterface get instance => _instance;
}
