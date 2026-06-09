import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart' show rootNavigatorKey;
import '../providers/auth_provider.dart';
import '../screens/settings_screen.dart';

/// Android Automotive OS glue. The car drives the app through the media browse
/// service, so the Flutter UI only surfaces while parked (settings, sign-in).
/// This detects whether we're running on a car head unit and bridges the
/// native AAOS intents to the app.
class AaosService {
  AaosService._();
  static final AaosService instance = AaosService._();

  static const MethodChannel _channel = MethodChannel('com.absorb.aaos');
  static const String _automotiveFeature = 'android.hardware.type.automotive';

  bool _initialized = false;
  bool _isAutomotive = false;

  /// True when the current device is an Android Automotive OS head unit.
  bool get isAutomotive => _isAutomotive;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!Platform.isAndroid) return;

    try {
      final info = await DeviceInfoPlugin().androidInfo;
      _isAutomotive = info.systemFeatures.contains(_automotiveFeature);
    } catch (_) {
      _isAutomotive = false;
    }

    if (!_isAutomotive) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openSettings') {
        _openSettings();
      }
      return null;
    });
  }

  /// Hand control back to the car's system media center, optionally finishing
  /// the parked Flutter activity behind it.
  Future<bool> launchMediaCenter({bool finishActivity = false}) async {
    if (!Platform.isAndroid || !_isAutomotive) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'launchMediaCenter',
        {'finishActivity': finishActivity},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Bring the app's sign-in screen to the front. Called from the car browse
  /// service when the user taps the sign-in prompt. No automotive guard here:
  /// the browse service can run in an engine that never ran [initialize], and
  /// this is only ever reached from the automotive-only sign-in row.
  Future<bool> launchSignIn() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('launchSignIn');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  void _openSettings() {
    final nav = rootNavigatorKey.currentState;
    final ctx = rootNavigatorKey.currentContext;
    if (nav == null || ctx == null) return;

    // Settings need a signed-in server. If we're not authenticated the login
    // screen is already showing, so there's nothing to push.
    if (!ctx.read<AuthProvider>().isAuthenticated) return;

    // Backing out of settings on a car returns to the media browser, not the
    // parked Flutter screen.
    nav.push(MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) {
      launchMediaCenter(finishActivity: true);
    });
  }
}
