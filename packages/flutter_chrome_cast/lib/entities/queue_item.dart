import 'media_information.dart';

///Represents an item in a media queue.
class GoogleCastQueueItem {
  /// Array of Track trackIds that should be active. If the array is not provided, the default tracks will be active. If two incompatible trackIds are provided (for example two active audio tracks) the command will fail with INVALID_PARAMETER.
  final List<int>? activeTrackIds;

  /// Whether the media will automatically play.
  final bool autoPlay;

  /// Custom data set by the receiver application.
  final Map<String, dynamic>? customData;

  /// Unique identifier of the item in the queue. If used in chrome.cast.media.QueueLoad or chrome.cast.media.QueueInsert it must be null (as it will be assigned by the receiver when an item is first created/inserted). For other operations it is mandatory.
  final int? itemId;

  /// Media description.
  final GoogleCastMediaInformation mediaInformation;

  /// Playback duration of the item in seconds. If it is larger than the actual duration - startTime it will be limited to the actual duration - startTime. It can be negative, in such case the duration will be the actual item duration minus the duration provided. A duration of value zero effectively means that the item will not be played.
  final Duration? playbackDuration;

  /// This parameter is a hint for the receiver to preload this media item before it is played. It allows for a smooth transition between items played from the queue.
  ///The time is expressed in seconds, relative to the beginning of this item playback (usually the end of the previous item playback). Only positive values are valid. For example, if the value is 10 seconds, this item will be preloaded 10 seconds before the previous item has finished. The receiver will try to honor this value but will not guarantee it, for example if the value is larger than the previous item duration the receiver may just preload this item shortly after the previous item has started playing (there will never be two items being preloaded in parallel). Also, if an item is inserted in the queue just after the currentItem and the time to preload is higher than the time left on the currentItem, the preload will just happen as soon as possible.
  final Duration? preLoadTime;

  /// Seconds from the beginning of the media to start playback.
  final Duration? startTime;

  /// Creates a queue item instance.
  GoogleCastQueueItem({
    this.activeTrackIds,
    this.autoPlay = true,
    this.customData,
    this.itemId,
    required this.mediaInformation,
    this.playbackDuration,
    this.preLoadTime,
    this.startTime,
  });

  /// Converts the queue item to a map.
  Map<String, dynamic> toMap() {
    return {
      'activeTrackIds': activeTrackIds,
      'autoplay': autoPlay,
      'customData': customData,
      'itemId': itemId,
      'media': mediaInformation.toMap(),
      'playbackDuration': playbackDuration?.inSeconds,
      'preloadTime': preLoadTime?.inSeconds,
      'startTime': startTime?.inSeconds,
    }..removeWhere((key, value) => value == null);
  }
}
