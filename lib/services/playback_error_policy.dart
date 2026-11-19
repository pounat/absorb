import 'package:flutter/services.dart';

class PlaybackErrorPolicy {
  PlaybackErrorPolicy._();

  static bool isSourceError(Object error) {
    final text = error.toString().toLowerCase();

    if (error is PlatformException) {
      final message = error.message?.toLowerCase() ?? '';
      return error.code == '0' && message.contains('source error');
    }

    return text.contains('source error') || text.contains('type_source');
  }

  /// A byte range turned down: by the server with a 416, or by the disk
  /// cache in front of the Android player, which reports a bare
  /// DataSourceException with nothing after it when the position asked for
  /// is past the length it has on record for the URL.
  static bool isCacheRangeError(Object error) {
    final text = error.toString();
    return text.contains('Response code: 416') ||
        RegExp(r'Source error: DataSourceException(?![:\w])').hasMatch(text);
  }

  static bool shouldRetryWithTranscode(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('mediacodecaudiorenderer') ||
        text.contains('audiotrack') ||
        text.contains('decoder') ||
        text.contains('format_supported')) {
      return true;
    }

    return isSourceError(error);
  }
}
