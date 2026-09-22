import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific implementation of queue item.
class GoogleCastAndroidQueueItem extends GoogleCastQueueItem {
  /// Creates an Android queue item instance.
  GoogleCastAndroidQueueItem({
    required super.mediaInformation,
    super.activeTrackIds,
    super.autoPlay,
    super.customData,
    super.itemId,
    super.playbackDuration,
    super.preLoadTime,
    super.startTime,
  });

  /// Creates a queue item instance from a map.
  factory GoogleCastAndroidQueueItem.fromMap(Map<String, dynamic> map) {
    return GoogleCastAndroidQueueItem(
      mediaInformation: GoogleCastMediaInformationAndroid.fromMap(
          Map<String, dynamic>.from(map['media'])),
      activeTrackIds: List.from(map['activeTracksIds'] ?? []),
      autoPlay: map['autoplay'] ?? false,
      customData: map['customData'],
      itemId: map['itemId'],
      playbackDuration: map['playbackDuration'] == null
          ? null
          : Duration(seconds: map['playbackDuration']),
      preLoadTime: Duration(seconds: map['preLoadTime'] ?? 0),
      startTime: Duration(seconds: map['startTime'] ?? 0),
    );
  }
}
