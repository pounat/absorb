import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_platform.dart';
import 'home_widget_service.dart';
import 'quick_actions_service.dart';

/// Switches the home screen icon between the colors in
/// lib/utils/app_icon_palette.dart, on Android and iPhone.
class AppIconService {
  AppIconService._();

  static const _channel = MethodChannel('com.barnabas.absorb/app_icon');

  static bool get supported => AppPlatform.isAndroid || AppPlatform.isIOS;

  /// The icon showing now.
  static final current = ValueNotifier<String>('classic');

  static Future<void> load() async {
    if (!supported) return;
    try {
      current.value = await _channel.invokeMethod<String>('get') ?? 'classic';
    } catch (e) {
      debugPrint('[AppIcon] reading the icon failed: $e');
    }
  }

  /// True once the home screen has the icon [id].
  static Future<bool> set(String id) async {
    if (!supported) return false;
    try {
      final now = await _channel.invokeMethod<String>('set', {'icon': id});
      current.value = now ?? id;
      if (AppPlatform.isAndroid) {
        unawaited(QuickActionsService().publish());
        HomeWidgetService().republishToWatch();
      }
      return true;
    } catch (e) {
      debugPrint('[AppIcon] changing the icon to $id failed: $e');
      return false;
    }
  }
}
