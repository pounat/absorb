import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';

/// Saves a BookOrbit book's cover where the Android media notification looks
/// for it, before the notification is told to show it.
///
/// Left to fetch the cover itself, the notification asks this app's own
/// BookOrbit relay for it while holding a lock the app then waits on, and
/// the relay can't answer until the app stops waiting. Each side waited on
/// the other until the request timed out, eight seconds later, with the app
/// frozen the whole time. With the file already there, nothing is fetched.
class NotificationCover {
  NotificationCover._();

  static String? _dir;
  static final Set<String> _saving = {};

  static Future<String> _folder() async =>
      _dir ??= '${(await getTemporaryDirectory()).path}/aa_covers';

  /// Call once at startup so [ready] can answer straight away.
  static Future<void> init() async {
    try {
      await _folder();
    } catch (_) {}
  }

  /// Whether the cover is saved and no older than [changedAt], when its
  /// server says the cover last changed.
  static bool ready(String itemId, int? changedAt) {
    final dir = _dir;
    if (dir == null) return false;
    try {
      final file = File('$dir/$itemId.jpg');
      if (!file.existsSync() || file.lengthSync() == 0) return false;
      return changedAt == null || file.lastModifiedSync().millisecondsSinceEpoch >= changedAt;
    } catch (_) {
      return false;
    }
  }

  /// Fetches and saves the cover. True once it is there.
  static Future<bool> save(ApiService api, String itemId) async {
    if (!_saving.add(itemId)) return false;
    try {
      final dir = await _folder();
      await api.ensureMediaReady();
      final got = await http
          .get(Uri.parse(api.getCoverUrl(itemId, width: 400)), headers: api.mediaHeaders)
          .timeout(const Duration(seconds: 15));
      if (got.statusCode != 200 || got.bodyBytes.isEmpty) {
        debugPrint('[NotificationCover] $itemId answered HTTP ${got.statusCode}');
        return false;
      }
      await Directory(dir).create(recursive: true);
      final tmp = File('$dir/$itemId.jpg.tmp');
      await tmp.writeAsBytes(got.bodyBytes, flush: true);
      await tmp.rename('$dir/$itemId.jpg');
      return true;
    } catch (e) {
      debugPrint('[NotificationCover] Could not save the cover for $itemId: $e');
      return false;
    } finally {
      _saving.remove(itemId);
    }
  }
}
