import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/_remote_media_client/remote_media_client_platform.dart';
import 'package:flutter_chrome_cast/entities/cast_media_status.dart';
import 'package:flutter_chrome_cast/entities/load_options.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast/entities/queue_item.dart';
import 'package:flutter_chrome_cast/models/android/android_media_status.dart';
import 'package:flutter_chrome_cast/models/android/android_queue_item.dart';
import 'package:rxdart/subjects.dart';

/// Android-specific implementation of Google Cast remote media client functionality.
class GoogleCastRemoteMediaClientAndroidMethodChannel
    implements GoogleCastRemoteMediaClientPlatformInterface {
  /// Creates a new Android remote media client method channel.
  GoogleCastRemoteMediaClientAndroidMethodChannel() {
    _channel.setMethodCallHandler(_onMethodCallHandler);
  }

  final _channel = const MethodChannel(
    'com.felnanuke.google_cast.remote_media_client',
  );

  // Media Status
  final _mediaStatusStreamController = BehaviorSubject<GoggleCastMediaStatus?>()
    ..add(null);

  @override
  GoggleCastMediaStatus? get mediaStatus => _mediaStatusStreamController.value;

  @override
  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      _mediaStatusStreamController.stream;

  // QueueItems
  final _queueItemsStreamController =
      BehaviorSubject<List<GoogleCastQueueItem>>()..add([]);

  @override
  List<GoogleCastQueueItem> get queueItems => _queueItemsStreamController.value;

  @override
  Stream<List<GoogleCastQueueItem>> get queueItemsStream =>
      _queueItemsStreamController.stream;

  // PlayerPosition
  final _playerPositionStreamController = BehaviorSubject<Duration>()
    ..add(Duration.zero);
  @override
  Duration get playerPosition => _playerPositionStreamController.value;

  @override
  Stream<Duration> get playerPositionStream =>
      _playerPositionStreamController.stream;

  // Queue has Next or revious item
  @override
  bool get queueHasNextItem {
    final currentQueueItemId = mediaStatus?.currentItemId;
    final currentItemIndex = queueItems
        .map((e) => e.itemId)
        .toList()
        .lastIndexOf(currentQueueItemId);
    return (queueItems.length - 1) > currentItemIndex;
  }

  @override
  bool get queueHasPreviousItem => true;

  @override
  Future<void> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
  }) async {
    await _channel.invokeMethod('loadMedia', {
      'mediaInfo': mediaInfo.toMap(),
      'autoPlay': autoPlay,
      'playPosition': playPosition.inSeconds,
      'playbackRate': playbackRate,
      'activeTrackIds': activeTrackIds,
      'credentials': credentials,
      'credentialsType': credentialsType,
    });
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  @override
  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  @override
  Future<void> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  }) async {
    await _channel.invokeMethod('queueLoadItems', {
      'queueItems': queueItems.map((item) => item.toMap()).toList(),
      'options': options?.toMap(android: true),
    });
  }

  @override
  Future<void> queueNextItem() async {
    await _channel.invokeMethod('queueNextItem');
  }

  @override
  Future<void> queuePrevItem() async {
    await _channel.invokeMethod('queuePrevItem');
  }

  @override
  Future<void> seek(GoogleCastMediaSeekOption option) async {
    await _channel.invokeMethod('seek', option.toMap());
  }

  @override
  Future<void> setActiveTrackIDs(List<int> activeTrackIDs) async {
    await _channel.invokeMethod(
      'setActiveTrackIds',
      activeTrackIDs,
    );
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    await _channel.invokeMethod('setPlaybackRate', rate);
  }

  @override
  Future<void> setTextTrackStyle(
    TextTrackStyle textTrackStyle,
  ) async {
    await _channel.invokeMethod(
      'setTextTrackStyle',
      textTrackStyle.toMap(),
    );
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  @override
  Future<void> queueJumpToItemWithId(int itemId) async {
    await _channel.invokeMethod('queueJumpToItemWithId', itemId);
  }

  @override
  Future<void> queueRemoveItemsWithIds(List<int> itemIds) async {
    await _channel.invokeMethod(
      'queueRemoveItemsWithIds',
      itemIds,
    );
  }

  @override
  Future<void> queueInsertItemAndPlay(
    GoogleCastQueueItem item, {
    required int beforeItemWithId,
  }) async {
    await _channel.invokeMethod('queueInsertItemAndPlay', {
      'item': item.toMap(),
      'beforeItemWithId': beforeItemWithId,
    });
  }

  @override
  Future<void> queueInsertItems(
    List<GoogleCastQueueItem> items, {
    int? beforeItemWithId,
  }) async {
    await _channel.invokeMethod('queueInsertItems', {
      'items': items.map((item) => item.toMap()).toList(),
      'beforeItemWithId': beforeItemWithId,
    });
  }

  Future _onMethodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onMediaStatusChanged':
        return _onMediaStatusChanged(call.arguments);
      case 'onQueueStatusChanged':
        return _onQueueStatusChanged(call.arguments);
      case 'onPlayerPositionChanged':
        return _onPlayerPositionChanged(call.arguments);
      default:
    }
  }

  Future<void> _onMediaStatusChanged(dynamic arguments) async {
    if (arguments == null) {
      _mediaStatusStreamController.add(null);
      return;
    }
    final mediaStatus = GoogleCastAndroidMediaStatus.fromMap(
      Map<String, dynamic>.from(jsonDecode(arguments)),
    );

    _mediaStatusStreamController.add(mediaStatus);
  }

  Future<void> _onQueueStatusChanged(dynamic arguments) async {
    if (arguments == null) {
      _queueItemsStreamController.add([]);
      return;
    }

    final map = List.from(arguments);

    final queueItems = map
        .map(
          (e) => GoogleCastAndroidQueueItem.fromMap(
            Map<String, dynamic>.from(
              Map<String, dynamic>.from(jsonDecode(e)),
            ),
          ),
        )
        .toList();
    _queueItemsStreamController.add(queueItems);
  }

  Future<void> _onPlayerPositionChanged(dynamic arguments) async {
    if (arguments == null) {
      _playerPositionStreamController.add(Duration.zero);
      return;
    }
    arguments = Map<String, dynamic>.from(arguments);

    final playerPosition = Duration(milliseconds: arguments["progress"] ?? 0);
    _playerPositionStreamController.add(playerPosition);
  }

  @override
  Future<void> queueReorderItems({
    required List<int> itemsIds,
    required int? beforeItemWithId,
  }) {
    return _channel.invokeMethod('queueReorderItems', {
      'itemsIds': itemsIds,
      'beforeItemWithId': beforeItemWithId,
    });
  }
}
