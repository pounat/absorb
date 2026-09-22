import 'package:flutter_chrome_cast/entities/cast_media_status.dart';
import 'package:flutter_chrome_cast/entities/load_options.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast/entities/queue_item.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for Google Cast remote media client functionality.
abstract class GoogleCastRemoteMediaClientPlatformInterface
    implements PlatformInterface {
  /// Current media status of the remote media client.
  GoggleCastMediaStatus? get mediaStatus;

  /// Stream of media status changes.
  Stream<GoggleCastMediaStatus?> get mediaStatusStream;

  /// Current player position.
  Duration get playerPosition;

  /// Stream of player position changes.
  Stream<Duration> get playerPositionStream;

  /// Stream of queue items changes.
  Stream<List<GoogleCastQueueItem>> get queueItemsStream;

  /// Current list of queue items.
  List<GoogleCastQueueItem> get queueItems;

  /// Whether the queue has a next item.
  bool get queueHasNextItem;

  /// Whether the queue has a previous item.
  bool get queueHasPreviousItem;

  /// Loads media on the remote media client.
  Future<void> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
  });

  /// Loads queue items on the remote media client.
  Future<void> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  });

  /// Sets the playback rate.
  Future<void> setPlaybackRate(double rate);

  /// Sets the active track IDs.
  Future<void> setActiveTrackIDs(List<int> activeTrackIDs);

  /// Sets the text track style.
  Future<void> setTextTrackStyle(TextTrackStyle textTrackStyle);

  /// Pauses media playback.
  Future<void> pause();

  /// Starts or resumes media playback.
  Future<void> play();

  /// Stops media playback.
  Future<void> stop();

  /// Plays the next item in the queue.
  Future<void> queueNextItem();

  /// Plays the previous item in the queue.
  Future<void> queuePrevItem();

  /// Seeks to a specific position in the media.
  Future<void> seek(GoogleCastMediaSeekOption option);

  /// Inserts items into the queue.
  Future<void> queueInsertItems(
    List<GoogleCastQueueItem> items, {
    int? beforeItemWithId,
  });

  /// Inserts an item into the queue and plays it.
  Future<void> queueInsertItemAndPlay(
    GoogleCastQueueItem item, {
    required int beforeItemWithId,
  });

  /// Removes items from the queue by their IDs.
  Future<void> queueRemoveItemsWithIds(
    List<int> itemIds,
  );

  /// Jumps to a specific item in the queue by its ID.
  Future<void> queueJumpToItemWithId(int itemId);

  /// Reorders items in the queue.
  ///
  /// [itemsIds] - List of IDs of the items to reorder.
  /// [beforeItemWithId] - The ID of the item before which the reordered items will be placed.
  ///                     If null, the items will be placed at the end of the queue.
  Future<void> queueReorderItems({
    required List<int> itemsIds,
    required int? beforeItemWithId,
  });
}
