import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin bridge to the Android-side WearAuthBridge that publishes the
/// current ABS session to the paired Wear OS app (AbsorbWear) via the
/// Google Play Services Wearable Data Layer.
///
/// No-op on every platform except Android — iOS doesn't talk to Wear OS,
/// and desktop/web have nowhere to push to.
class WearAuthService {
  WearAuthService._();
  static final WearAuthService instance = WearAuthService._();

  static const MethodChannel _channel = MethodChannel(
    'com.barnabas.absorb/wear_auth',
  );

  bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Push the current session to the paired watch. Safe to call on any
  /// login/refresh/account-switch; the Data Layer dedupes by hash.
  ///
  /// [customHeaders] are forwarded so the watch can replay Cloudflare
  /// Access / proxy auth headers on its own ABS API calls.
  Future<void> publish({
    required String serverUrl,
    required String accessToken,
    String? refreshToken,
    required String username,
    String? userId,
    required bool isLegacyToken,
    Map<String, String> customHeaders = const {},
    bool supportsTokenReturn = false,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('publish', {
        'serverUrl': serverUrl,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'username': username,
        'userId': userId,
        'isLegacyToken': isLegacyToken,
        'customHeaders': customHeaders,
        'supportsTokenReturn': supportsTokenReturn,
      });
    } catch (e) {
      // Pure-best-effort: the phone app must work even if Play Services
      // is missing (e.g. on degoogled ROMs).
      debugPrint('[WearAuth] publish failed: $e');
    }
  }

  /// Clear the published session so the paired watch signs out too.
  Future<void> clear() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('clear');
    } catch (e) {
      debugPrint('[WearAuth] clear failed: $e');
    }
  }
}
