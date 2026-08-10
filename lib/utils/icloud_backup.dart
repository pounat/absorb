import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.absorb.widget');

/// Stops iCloud from backing up [path]: downloaded audio is large and
/// re-downloadable, and the mTLS client certificate is a private key.
///
/// iOS-only; on Android the manifest's backup rules do this.
Future<void> excludeFromICloudBackup(String path) async {
  if (!Platform.isIOS) return;
  try {
    await _channel.invokeMethod<bool>('excludeFromBackup', {'path': path});
  } catch (e) {
    debugPrint('[Backup] excludeFromBackup failed for $path: $e');
  }
}
