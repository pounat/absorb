import 'package:flutter_chrome_cast/lib.dart';

/// Represents a queue item for Google Cast on iOS platforms.
///
/// This class extends [GoogleCastQueueItem] and provides additional
/// iOS-specific mapping and construction logic.
class GoogleCastQueueItemIOS extends GoogleCastQueueItem {
  /// Creates a [GoogleCastQueueItemIOS] instance.
  ///
  /// [mediaInformation] is required and contains the media details for the queue item.
  /// Other parameters are optional and provide additional playback and queue configuration.
  GoogleCastQueueItemIOS({
    required super.mediaInformation,
    super.activeTrackIds,
    super.autoPlay,
    super.customData,
    super.itemId,
    super.playbackDuration,
    super.preLoadTime,
    super.startTime,
  });

  /// Creates a [GoogleCastQueueItemIOS] from a [Map] representation.
  ///
  /// This factory parses the provided [map] and constructs an instance
  /// with the corresponding values, handling iOS-specific field names and types.
  factory GoogleCastQueueItemIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastQueueItemIOS(
      mediaInformation: GoogleCastMediaInformationIOS.fromMap(
          Map<String, dynamic>.from(map['mediaInformation'])),
      activeTrackIds: List.from(map['activeTracksIds'] ?? []),
      autoPlay: map['autoPlay'] ?? false,
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
