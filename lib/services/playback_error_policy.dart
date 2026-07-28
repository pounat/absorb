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
