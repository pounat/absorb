import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'player_settings.dart';

class SocketService {
  static const authorChangeEvents = <String>[
    'author_added',
    'author_updated',
    'author_removed',
    'authors_num_books_updated',
  ];
  static final SocketService _instance = SocketService._();
  factory SocketService() => _instance;
  SocketService._();

  io.Socket? _socket;
  String? _token;
  String? _serverUrl;
  DateTime? _connectedAt;

  bool get isConnected => _socket?.connected ?? false;
  bool get hasSocket => _socket != null;

  Map<String, String> _customHeaders = {};

  @visibleForTesting
  static ({String origin, String path}) socketTargetForServerUrl(
    String serverUrl,
  ) {
    final uri = Uri.parse(serverUrl.trim());
    final basePath = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return (
      origin: '${uri.scheme}://${uri.authority}',
      path: '$basePath/socket.io',
    );
  }

  /// Build socket.io options with capped reconnection to avoid
  /// hammering an unreachable server (and draining battery).
  @visibleForTesting
  static Map<String, dynamic> buildSocketOptions(
    String socketPath, {
    Map<String, String> customHeaders = const {},
  }) {
    final builder = io.OptionBuilder()
        .setTransports(['websocket'])
        .setPath(socketPath)
        .enableForceNew()
        .enableReconnection()
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(30000)
        .setReconnectionAttempts(5);
    if (customHeaders.isNotEmpty) {
      builder.setExtraHeaders(customHeaders);
    }
    return builder.build();
  }

  io.Socket _createSocket(String serverUrl) {
    final target = socketTargetForServerUrl(serverUrl);
    return io.io(
      target.origin,
      buildSocketOptions(target.path, customHeaders: _customHeaders),
    );
  }

  /// Called when the server pushes a progress update (cross-device sync).
  void Function(Map<String, dynamic> progress)? onProgressUpdated;

  /// Called after each successful socket auth (initial connect and every
  /// reconnect) so listeners can catch up on events missed while offline.
  void Function()? onAuthenticated;

  /// Called when a library item is added, updated, or removed.
  void Function(Map<String, dynamic> data)? onItemUpdated;

  /// Called when a library item is removed.
  void Function(Map<String, dynamic> data)? onItemRemoved;

  /// Called when series data changes.
  void Function()? onSeriesUpdated;

  /// Called when a collection changes.
  void Function()? onCollectionUpdated;

  /// Called when one of the user's playlists changes.
  void Function()? onPlaylistUpdated;

  /// Called when the current user's data changes on the server.
  void Function(Map<String, dynamic> data)? onUserUpdated;

  /// Called when socket.io exhausts all reconnection attempts.
  VoidCallback? onReconnectFailed;

  /// Called when an M4B encode task finishes on the server.
  /// Payload: serialized Task object including action and data.libraryItemId.
  void Function(Map<String, dynamic> data)? onEncodeFinished;

  // Server task event fan-out so admin and item screens can subscribe alongside
  // the library provider's onEncodeFinished above. task_started and
  // task_finished carry the action; task_progress is generic
  // {libraryItemId, progress}.
  final List<void Function(Map<String, dynamic>)> _taskStartedListeners = [];
  final List<void Function(Map<String, dynamic>)> _taskProgressListeners = [];
  final List<void Function(Map<String, dynamic>)> _taskFinishedListeners = [];

  void addTaskStartedListener(void Function(Map<String, dynamic>) fn) {
    if (!_taskStartedListeners.contains(fn)) _taskStartedListeners.add(fn);
  }
  void removeTaskStartedListener(void Function(Map<String, dynamic>) fn) =>
      _taskStartedListeners.remove(fn);
  void addTaskProgressListener(void Function(Map<String, dynamic>) fn) {
    if (!_taskProgressListeners.contains(fn)) _taskProgressListeners.add(fn);
  }
  void removeTaskProgressListener(void Function(Map<String, dynamic>) fn) =>
      _taskProgressListeners.remove(fn);
  void addTaskFinishedListener(void Function(Map<String, dynamic>) fn) {
    if (!_taskFinishedListeners.contains(fn)) _taskFinishedListeners.add(fn);
  }
  void removeTaskFinishedListener(void Function(Map<String, dynamic>) fn) =>
      _taskFinishedListeners.remove(fn);

  void _emitTaskStarted(Map<String, dynamic> data) {
    for (final fn in List.of(_taskStartedListeners)) {
      fn(data);
    }
  }

  void _emitTaskProgress(Map<String, dynamic> data) {
    for (final fn in List.of(_taskProgressListeners)) {
      fn(data);
    }
  }

  void _emitTaskFinished(Map<String, dynamic> data) {
    for (final fn in List.of(_taskFinishedListeners)) {
      fn(data);
    }
  }

  // Server log fan-out. Each consumer keeps its own minimum level so opening
  // another log surface later cannot steal or disable an existing listener.
  // The server is subscribed at the lowest requested threshold and entries
  // are filtered again before delivery to each consumer.
  final Map<void Function(Map<String, dynamic>), int> _serverLogListeners = {};

  void addServerLogListener(
    void Function(Map<String, dynamic>) fn, {
    required int level,
  }) {
    _serverLogListeners[fn] = _validLogLevel(level);
    _syncServerLogSubscription();
  }

  void updateServerLogListenerLevel(
    void Function(Map<String, dynamic>) fn,
    int level,
  ) {
    if (!_serverLogListeners.containsKey(fn)) return;
    _serverLogListeners[fn] = _validLogLevel(level);
    _syncServerLogSubscription();
  }

  void removeServerLogListener(void Function(Map<String, dynamic>) fn) {
    if (_serverLogListeners.remove(fn) == null) return;
    _syncServerLogSubscription();
  }

  int _validLogLevel(int level) => level.clamp(0, 6).toInt();

  int? get _lowestRequestedLogLevel {
    if (_serverLogListeners.isEmpty) return null;
    var lowest = _serverLogListeners.values.first;
    for (final level in _serverLogListeners.values.skip(1)) {
      if (level < lowest) lowest = level;
    }
    return lowest;
  }

  void _syncServerLogSubscription() {
    if (_socket?.connected != true) return;
    final level = _lowestRequestedLogLevel;
    if (level == null) {
      _socket!.emit('remove_log_listener');
    } else {
      _socket!.emit('set_log_listener', level);
    }
  }

  void _handleServerLog(dynamic data) {
    final log = normalizeSocketMap(data);
    if (log == null) return;
    final rawLevel = log['level'];
    final level = rawLevel is num
        ? rawLevel.toInt()
        : int.tryParse(rawLevel?.toString() ?? '') ?? 0;
    for (final listener in Map.of(_serverLogListeners).entries) {
      if (level >= listener.value) listener.key(log);
    }
  }

  void _registerServerLogEvents() {
    _socket!.on('log', _handleServerLog);
  }

  @visibleForTesting
  static Map<String, dynamic>? normalizeSocketMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  void _handleTaskStarted(dynamic data) {
    final task = normalizeSocketMap(data);
    if (task == null) return;
    debugPrint('[Socket] Task started: ${task['action'] ?? task['id']}');
    _emitTaskStarted(task);
  }

  void _handleTaskProgress(dynamic data) {
    final progress = normalizeSocketMap(data);
    if (progress != null) _emitTaskProgress(progress);
  }

  void _handleTaskFinished(dynamic data) {
    final task = normalizeSocketMap(data);
    if (task == null) return;
    debugPrint('[Socket] Task finished: ${task['action'] ?? task['id']}');
    if (task['action'] == 'encode-m4b') onEncodeFinished?.call(task);
    _emitTaskFinished(task);
  }

  // Library-item change fan-out so screens can react to scan/watcher-driven
  // changes (e.g. items flagged missing) without claiming the single-slot
  // onItemUpdated callback. Fires for item_added/item_updated/item_removed and
  // the scanner's bulk items_updated/items_added events.
  final List<VoidCallback> _itemsChangedListeners = [];

  void addItemsChangedListener(VoidCallback fn) {
    if (!_itemsChangedListeners.contains(fn)) _itemsChangedListeners.add(fn);
  }
  void removeItemsChangedListener(VoidCallback fn) =>
      _itemsChangedListeners.remove(fn);

  void _emitItemsChanged() {
    for (final fn in List.of(_itemsChangedListeners)) {
      fn();
    }
  }

  // Per-item update fan-out carrying the item JSON, so an open detail view can
  // live-refresh when its item changes on the server (web UI edits, scans,
  // finished episode downloads). Bulk events fan out one call per item.
  final List<void Function(Map<String, dynamic>)> _itemUpdatedListeners = [];

  void addItemUpdatedListener(void Function(Map<String, dynamic>) fn) {
    if (!_itemUpdatedListeners.contains(fn)) _itemUpdatedListeners.add(fn);
  }
  void removeItemUpdatedListener(void Function(Map<String, dynamic>) fn) =>
      _itemUpdatedListeners.remove(fn);

  void _emitItemUpdated(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final fn in List.of(_itemUpdatedListeners)) {
        fn(data);
      }
    } else if (data is List) {
      for (final item in data.whereType<Map<String, dynamic>>()) {
        for (final fn in List.of(_itemUpdatedListeners)) {
          fn(item);
        }
      }
    }
  }

  // Removal fan-out with payload ({id, ...}), alongside the single-slot
  // onItemRemoved owned by the library provider.
  final List<void Function(Map<String, dynamic>)> _itemRemovedListeners = [];

  void addItemRemovedListener(void Function(Map<String, dynamic>) fn) {
    if (!_itemRemovedListeners.contains(fn)) _itemRemovedListeners.add(fn);
  }
  void removeItemRemovedListener(void Function(Map<String, dynamic>) fn) =>
      _itemRemovedListeners.remove(fn);

  void _emitItemRemoved(Map<String, dynamic> data) {
    for (final fn in List.of(_itemRemovedListeners)) {
      fn(data);
    }
  }

  // Author change fan-out (added/updated/removed) so the authors tab can
  // live-refresh after quick-match or edits.
  final List<VoidCallback> _authorsChangedListeners = [];

  void addAuthorsChangedListener(VoidCallback fn) {
    if (!_authorsChangedListeners.contains(fn)) _authorsChangedListeners.add(fn);
  }
  void removeAuthorsChangedListener(VoidCallback fn) =>
      _authorsChangedListeners.remove(fn);

  void _emitAuthorsChanged() {
    for (final fn in List.of(_authorsChangedListeners)) {
      fn();
    }
  }

  void _registerAuthorListeners() {
    for (final event in authorChangeEvents) {
      _socket!.on(event, (_) => _emitAuthorsChanged());
    }
  }

  /// Called when ereader devices change. Server emits this both for the
  /// per-user update (always) and admin-wide updates (only to admins).
  /// Payload shape: { ereaderDevices: [...] } already filtered for this user.
  void Function(List<Map<String, dynamic>> devices)? onEreaderDevicesUpdated;

  /// Update the stored token (e.g. after a JWT refresh) and re-auth if connected.
  void updateToken(String newToken) {
    _token = newToken;
    if (_socket?.connected == true) {
      debugPrint('[Socket] Re-authenticating with refreshed token');
      _socket!.emit('auth', _token);
    }
  }

  void connect(String serverUrl, String token, {Map<String, String> customHeaders = const {}}) {
    if (_socket != null) disconnect();

    _token = token;
    _serverUrl = serverUrl;
    _customHeaders = customHeaders;

    // E-ink mode never holds a live socket (battery first) - keep the
    // credentials so turning the mode off can reconnect, but stop short of
    // opening the connection. Progress still syncs over plain HTTP.
    if (PlayerSettings.einkMode) {
      debugPrint('[Battery] Socket not opened (e-ink mode)');
      return;
    }

    try {
      _socket = _createSocket(serverUrl);

      // onConnect fires on initial connect AND every reconnect
      _socket!.onConnect((_) {
        _connectedAt = DateTime.now();
        debugPrint('[Socket] Connected, sending auth');
        _socket!.emit('auth', _token);
      });

      _socket!.on('init', (_) {
        debugPrint('[Socket] Authenticated - user is online');
        _syncServerLogSubscription();
        onAuthenticated?.call();
      });

      _socket!.on('auth_failed', (_) {
        debugPrint('[Socket] Auth failed');
        disconnect();
      });

      // Cross-device progress sync
      _socket!.on('user_item_progress_updated', (data) {
        if (data is Map<String, dynamic>) {
          final patch = data['data'] as Map<String, dynamic>?;
          if (patch != null) {
            onProgressUpdated?.call(patch);
          }
        }
      });

      // Library item changes
      _socket!.on('item_added', (data) {
        debugPrint('[Socket] Item added');
        if (data is Map<String, dynamic>) onItemUpdated?.call(data);
        _emitItemUpdated(data);
        _emitItemsChanged();
      });
      _socket!.on('item_updated', (data) {
        debugPrint('[Socket] Item updated');
        if (data is Map<String, dynamic>) onItemUpdated?.call(data);
        _emitItemUpdated(data);
        _emitItemsChanged();
      });
      _socket!.on('item_removed', (data) {
        debugPrint('[Socket] Item removed');
        if (data is Map<String, dynamic>) {
          onItemRemoved?.call(data);
          _emitItemRemoved(data);
        }
        _emitItemsChanged();
      });
      // Bulk events the scanner emits in chunks while a scan runs
      _socket!.on('items_updated', (data) {
        debugPrint('[Socket] Items updated (bulk)');
        _emitItemUpdated(data);
        _emitItemsChanged();
      });
      _socket!.on('items_added', (data) {
        debugPrint('[Socket] Items added (bulk)');
        _emitItemUpdated(data);
        _emitItemsChanged();
      });

      // Series changes
      _socket!.on('series_added', (_) {
        debugPrint('[Socket] Series added');
        onSeriesUpdated?.call();
      });
      _socket!.on('series_updated', (_) {
        debugPrint('[Socket] Series updated');
        onSeriesUpdated?.call();
      });
      _socket!.on('series_removed', (_) {
        debugPrint('[Socket] Series removed');
        onSeriesUpdated?.call();
      });

      // Collection changes
      _socket!.on('collection_added', (_) {
        debugPrint('[Socket] Collection added');
        onCollectionUpdated?.call();
      });
      _socket!.on('collection_updated', (_) {
        debugPrint('[Socket] Collection updated');
        onCollectionUpdated?.call();
      });
      _socket!.on('collection_removed', (_) {
        debugPrint('[Socket] Collection removed');
        onCollectionUpdated?.call();
      });

      // Playlist changes (server emits these per-user)
      _socket!.on('playlist_added', (_) {
        debugPrint('[Socket] Playlist added');
        onPlaylistUpdated?.call();
      });
      _socket!.on('playlist_updated', (_) {
        debugPrint('[Socket] Playlist updated');
        onPlaylistUpdated?.call();
      });
      _socket!.on('playlist_removed', (_) {
        debugPrint('[Socket] Playlist removed');
        onPlaylistUpdated?.call();
      });

      // Author changes
      _registerAuthorListeners();

      // Current user updated
      _socket!.on('user_updated', (data) {
        debugPrint('[Socket] User updated');
        if (data is Map<String, dynamic>) onUserUpdated?.call(data);
      });

      // Server task lifecycle. task_started + finished carry the action;
      // task_progress is generic {libraryItemId, progress}.
      _socket!.on('task_started', _handleTaskStarted);
      _socket!.on('task_progress', _handleTaskProgress);
      _socket!.on('task_finished', _handleTaskFinished);

      _registerServerLogEvents();

      // Ereader device list changed (admin-wide or per-user). Payload carries
      // the list already filtered for this connection's user.
      _socket!.on('ereader-devices-updated', (data) {
        if (data is! Map) return;
        final raw = data['ereaderDevices'] as List<dynamic>?;
        if (raw == null) return;
        debugPrint('[Socket] ereader-devices-updated (${raw.length} devices)');
        onEreaderDevicesUpdated?.call(raw.cast<Map<String, dynamic>>());
      });

      _socket!.onDisconnect((reason) {
        final duration = _connectedAt != null
            ? DateTime.now().difference(_connectedAt!).inSeconds
            : 0;
        debugPrint('[Socket] Disconnected after ${duration}s (Reason: $reason)');
        _connectedAt = null;
      });

      _socket!.onConnectError((err) {
        debugPrint('[Socket] Connect error: $err');
      });

      _socket!.on('reconnect_failed', (_) {
        debugPrint('[Socket] Reconnection attempts exhausted — giving up');
        _socket?.dispose();
        _socket = null;
        onReconnectFailed?.call();
      });
    } catch (e) {
      debugPrint('[Socket] Failed to connect: $e');
      _socket = null;
      _token = null;
      _serverUrl = null;
    }
  }

  /// Disconnect and tear down the socket, clearing all callbacks.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _token = null;
    _serverUrl = null;
    onProgressUpdated = null;
    onAuthenticated = null;
    onItemUpdated = null;
    onItemRemoved = null;
    onSeriesUpdated = null;
    onCollectionUpdated = null;
    onPlaylistUpdated = null;
    onUserUpdated = null;
    onReconnectFailed = null;
    onEncodeFinished = null;
    onEreaderDevicesUpdated = null;
  }

  /// Disconnect the socket but keep callbacks and credentials so we can
  /// cheaply reconnect later without re-wiring everything.
  void softDisconnect() {
    if (_socket == null) return;
    debugPrint('[Battery] Socket DISCONNECTED (soft, battery saving)');
    _socket!.dispose();
    _socket = null;
  }

  /// Switch to a different server URL (e.g. local/remote swap).
  /// Does a soft disconnect then reconnect with the new URL.
  void switchServer(String newUrl) {
    if (_serverUrl == newUrl) return;
    debugPrint('[Socket] Switching server: $_serverUrl -> $newUrl');
    _serverUrl = newUrl;
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
      softReconnect();
    }
  }

  /// Reconnect after a soft disconnect, reusing saved credentials.
  void softReconnect() {
    if (_socket != null) return; // already connected
    if (PlayerSettings.einkMode) return;
    final url = _serverUrl;
    final token = _token;
    if (url == null || token == null) return;
    debugPrint('[Battery] Socket RECONNECTED (soft)');

    try {
      _socket = _createSocket(url);

      _socket!.onConnect((_) {
        _connectedAt = DateTime.now();
        debugPrint('[Socket] Connected, sending auth');
        _socket!.emit('auth', _token);
      });

      _socket!.on('init', (_) {
        debugPrint('[Socket] Authenticated - user is online');
        _syncServerLogSubscription();
        onAuthenticated?.call();
      });

      _socket!.on('auth_failed', (_) {
        debugPrint('[Socket] Auth failed');
        disconnect();
      });

      _socket!.on('user_item_progress_updated', (data) {
        if (data is Map<String, dynamic>) {
          final patch = data['data'] as Map<String, dynamic>?;
          if (patch != null) onProgressUpdated?.call(patch);
        }
      });

      _socket!.on('item_added', (data) {
        if (data is Map<String, dynamic>) onItemUpdated?.call(data);
        _emitItemUpdated(data);
        _emitItemsChanged();
      });
      _socket!.on('item_updated', (data) {
        if (data is Map<String, dynamic>) onItemUpdated?.call(data);
        _emitItemUpdated(data);
        _emitItemsChanged();
      });
      _socket!.on('item_removed', (data) {
        if (data is Map<String, dynamic>) {
          onItemRemoved?.call(data);
          _emitItemRemoved(data);
        }
        _emitItemsChanged();
      });
      _socket!.on('items_updated', (data) {
        _emitItemUpdated(data);
        _emitItemsChanged();
      });
      _socket!.on('items_added', (data) {
        _emitItemUpdated(data);
        _emitItemsChanged();
      });

      _socket!.on('series_added', (_) => onSeriesUpdated?.call());
      _socket!.on('series_updated', (_) => onSeriesUpdated?.call());
      _socket!.on('series_removed', (_) => onSeriesUpdated?.call());

      _socket!.on('collection_added', (_) => onCollectionUpdated?.call());
      _socket!.on('collection_updated', (_) => onCollectionUpdated?.call());
      _socket!.on('collection_removed', (_) => onCollectionUpdated?.call());

      _socket!.on('playlist_added', (_) => onPlaylistUpdated?.call());
      _socket!.on('playlist_updated', (_) => onPlaylistUpdated?.call());
      _socket!.on('playlist_removed', (_) => onPlaylistUpdated?.call());

      _registerAuthorListeners();

      _socket!.on('user_updated', (data) {
        if (data is Map<String, dynamic>) onUserUpdated?.call(data);
      });

      _socket!.on('task_started', _handleTaskStarted);
      _socket!.on('task_progress', _handleTaskProgress);
      _socket!.on('task_finished', _handleTaskFinished);

      _registerServerLogEvents();

      _socket!.on('ereader-devices-updated', (data) {
        if (data is! Map) return;
        final raw = data['ereaderDevices'] as List<dynamic>?;
        if (raw == null) return;
        onEreaderDevicesUpdated?.call(raw.cast<Map<String, dynamic>>());
      });

      _socket!.onDisconnect((reason) {
        final duration = _connectedAt != null
            ? DateTime.now().difference(_connectedAt!).inSeconds
            : 0;
        debugPrint('[Socket] Disconnected after ${duration}s (Reason: $reason)');
        _connectedAt = null;
      });

      _socket!.onConnectError((err) {
        debugPrint('[Socket] Connect error: $err');
      });

      _socket!.on('reconnect_failed', (_) {
        debugPrint('[Socket] Reconnection attempts exhausted — giving up');
        _socket?.dispose();
        _socket = null;
        onReconnectFailed?.call();
      });
    } catch (e) {
      debugPrint('[Socket] Failed to reconnect: $e');
      _socket = null;
    }
  }
}
