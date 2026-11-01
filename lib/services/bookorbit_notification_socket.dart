import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';
import 'server_notifications.dart';

/// BookOrbit's live notification feed, its `/notifications` socket. It runs
/// on the same terms as the Audiobookshelf socket: only while the app is in
/// front and awake, so new notifications show at once and the unread count
/// stays current without costing battery in the background.
///
/// BookOrbit only creates the notifications a user's category settings let
/// through, so whatever arrives here is already one they asked for.
class BookOrbitNotificationSocket {
  BookOrbitNotificationSocket._();
  static final instance = BookOrbitNotificationSocket._();

  /// The unread count BookOrbit last gave, and for which account.
  final unread = ValueNotifier<({ApiService api, int count})?>(null);

  final _incoming = StreamController<ServerNotification>.broadcast();
  final _updated = StreamController<ServerNotification>.broadcast();

  /// Notifications as BookOrbit creates them.
  Stream<ServerNotification> get incoming => _incoming.stream;

  /// A notification that happened again and was folded into its row.
  Stream<ServerNotification> get updated => _updated.stream;

  io.Socket? _socket;
  ApiService? _api;
  int _generation = 0;
  int _authRetries = 0;
  Timer? _retry;

  bool get isConnected => _socket?.connected ?? false;

  /// The live count for [api], or null when the feed isn't for that account.
  int? unreadFor(ApiService? api) {
    final u = unread.value;
    return u != null && identical(u.api, api) ? u.count : null;
  }

  static ({String origin, String path}) target(String serverUrl) {
    final uri = Uri.parse(serverUrl.trim());
    final base = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return (origin: '${uri.scheme}://${uri.authority}', path: '$base/socket.io');
  }

  Future<void> start(ApiService api) async {
    if (identical(api, _api)) return;
    stop();
    if (!api.isBookOrbit) return;
    _api = api;
    final gen = ++_generation;
    if (!await api.hasServerNotifications() || gen != _generation) return;

    final t = target(api.baseUrl);
    final builder = io.OptionBuilder()
        .setTransports(['websocket'])
        .setPath(t.path)
        .enableForceNew()
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(30000)
        .setReconnectionAttempts(5)
        // Asked on every handshake, so a reconnect after the 15 minute access
        // token ran out signs in with a fresh one.
        .setAuthFn((send) {
          api.freshAccessToken().then((token) => send({'token': token}), onError: (_) => send({'token': ''}));
        });
    if (api.customHeaders.isNotEmpty) builder.setExtraHeaders(api.customHeaders);
    final socket = io.io('${t.origin}/notifications', builder.build());
    _socket = socket;

    socket.onConnect((_) {
      _authRetries = 0;
      debugPrint('[BookOrbit] Notification feed connected');
    });
    socket.on('notification:unread-count', (data) {
      final count = data is Map ? (data['count'] as num?)?.toInt() : null;
      if (count != null && gen == _generation) unread.value = (api: api, count: count);
    });
    socket.on('notification:new', (data) {
      final n = ServerNotification.fromJson(data);
      if (n == null || gen != _generation) return;
      unread.value = (api: api, count: (unreadFor(api) ?? 0) + 1);
      _incoming.add(n);
    });
    socket.on('notification:updated', (data) {
      final n = ServerNotification.fromJson(data);
      if (n != null && gen == _generation) _updated.add(n);
    });
    // Reads, dismissals and clears come with no count, from this phone or
    // another device, so ask for it.
    for (final event in const [
      'notification:read',
      'notification:dismissed',
      'notification:all-read',
      'notification:cleared',
      'notification:refresh',
    ]) {
      socket.on(event, (_) => _recount(api, gen));
    }
    // A refused token: the server says so before it closes the socket, and
    // won't take the socket back by itself.
    socket.on('unauthorized', (_) {
      if (gen != _generation || _authRetries >= 3) return;
      final delay = Duration(seconds: 2 << _authRetries);
      _authRetries++;
      _retry?.cancel();
      _retry = Timer(delay, () {
        if (gen == _generation) socket.connect();
      });
    });
    socket.connect();
  }

  Future<void> _recount(ApiService api, int gen) async {
    final count = await api.unreadNotificationCount();
    if (count != null && gen == _generation) unread.value = (api: api, count: count);
  }

  /// Close the feed. The last count stays for the screens to show.
  void stop() {
    _generation++;
    _api = null;
    _retry?.cancel();
    _retry = null;
    _authRetries = 0;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      socket.clearListeners();
      socket.dispose();
      debugPrint('[BookOrbit] Notification feed closed');
    }
  }

  @visibleForTesting
  void debugEmit(String event, Object? data) => _socket?.emitReserved(event, data);

  @visibleForTesting
  void debugArrive(ServerNotification n) => _incoming.add(n);
}
