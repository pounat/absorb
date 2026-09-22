import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class AppPlatform {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isDesktop => isMacOS || isWindows || isLinux;
  static bool get isMobile => isAndroid || isIOS;

  /// The phone's plugins - audio engine, downloads, widgets, car, cast,
  /// notifications - exist on Android and iOS only. The browser and, for now,
  /// the desktop OSes run without them and take the web code paths.
  static bool get lacksPhonePlugins => isWeb || isDesktop;
}
