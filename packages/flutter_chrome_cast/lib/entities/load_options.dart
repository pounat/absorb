import 'package:flutter_chrome_cast/enums/repeat_mode.dart';

/// Configuration options for loading queue items in Google Cast.
class GoogleCastQueueLoadOptions {
  /// Starting index in the queue.
  final int startIndex;

  /// Position to start playback.
  final Duration playPosition;

  /// Repeat mode for the queue.
  final GoogleCastMediaRepeatMode repeatMode;

  /// Custom data to send with the request.
  final Map<String, dynamic>? customData;

  /// Creates a new [GoogleCastQueueLoadOptions].
  GoogleCastQueueLoadOptions({
    this.startIndex = 0,
    this.playPosition = Duration.zero,
    this.repeatMode = GoogleCastMediaRepeatMode.off,
    this.customData,
  });

  /// Converts these options to a map representation.
  Map<String, dynamic> toMap({bool android = false}) {
    return {
      'startIndex': startIndex,
      'playPosition': playPosition.inSeconds,
      'repeatMode': repeatMode.value,
      'customData': customData,
    };
  }
}
