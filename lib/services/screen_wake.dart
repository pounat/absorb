import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the screen from timing out while something hands-free is on screen,
/// like the ebook reader's auto scroll. FLAG_KEEP_SCREEN_ON on Android, the
/// idle timer on iOS. Callers must release it: neither platform clears it.
class ScreenWake {
  static const _channel = MethodChannel('com.absorb.screen_wake');

  static Future<void> keepOn(bool on) async {
    try {
      await _channel.invokeMethod('set', {'on': on});
    } catch (e) {
      debugPrint('[ScreenWake] keepOn($on) failed: $e');
    }
  }
}
