import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'scoped_prefs.dart';
import 'user_account_service.dart';

/// A single bookmark in an audiobook.
class Bookmark {
  final String id;
  final double positionSeconds;
  final DateTime created;
  String title;
  String? note;

  Bookmark({
    required this.id,
    required this.positionSeconds,
    required this.created,
    required this.title,
    this.note,
  });

  /// Combined text for syncing to ABS server (which only has a single "title" field).
  String get serverTitle {
    if (note != null && note!.isNotEmpty) return '$title - $note';
    return title;
  }

  /// The inverse of [serverTitle]: split a server title back into title and
  /// note at the first " - ", so a bookmark written on one phone comes apart
  /// the same way on another. Re-encoding the split pair yields the identical
  /// server string, so nothing is ever lost - at worst a title that itself
  /// contains " - " moves its tail into the note.
  static ({String title, String? note}) splitServerTitle(String raw) {
    final i = raw.indexOf(' - ');
    if (i <= 0) return (title: raw.trim(), note: null);
    final title = raw.substring(0, i).trim();
    final note = raw.substring(i + 3).trim();
    if (title.isEmpty || note.isEmpty) return (title: raw.trim(), note: null);
    return (title: title, note: note);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pos': positionSeconds,
        'ts': created.millisecondsSinceEpoch,
        'title': title,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    var title = json['title'] as String? ?? 'Bookmark';
    var note = json['note'] as String?;
    // Bookmarks pulled from the server before splitServerTitle existed were
    // stored with the combined "title - note" as their title - come apart now.
    if (note == null || note.isEmpty) {
      final parts = splitServerTitle(title);
      title = parts.title;
      note = parts.note;
    }
    return Bookmark(
      id: json['id'] as String? ?? '${DateTime.now().millisecondsSinceEpoch}',
      positionSeconds: (json['pos'] as num?)?.toDouble() ?? (json['time'] as num?)?.toDouble() ?? 0,
      created: json['ts'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['ts'] as int)
          : json['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch((json['createdAt'] as num).toInt())
              : DateTime.now(),
      title: title,
      note: note,
    );
  }

  /// Create from ABS server bookmark format: { title, time, createdAt }.
  /// The server only has "title", carrying our "title - note" encoding.
  factory Bookmark.fromServer(Map<String, dynamic> json) {
    final parts = splitServerTitle(json['title'] as String? ?? 'Bookmark');
    return Bookmark(
      id: '${(json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch}',
      positionSeconds: (json['time'] as num?)?.toDouble() ?? 0,
      created: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['createdAt'] as num).toInt())
          : DateTime.now(),
      title: parts.title,
      note: parts.note,
    );
  }

  String get formattedPosition => formattedAt(1.0);

  /// Position formatted for display at [speed] (stored seconds / speed), so
  /// lists can honor the speed-adjusted-time setting. The stored position and
  /// everything sent to the server stay raw book seconds.
  String formattedAt(double speed) {
    final div = speed > 0 ? speed : 1.0;
    // Guard against a negative stored position (e.g. a stray -1): Dart's modulo
    // on negatives would otherwise render -1s as "59:59".
    final p = positionSeconds < 0 ? 0.0 : positionSeconds / div;
    final h = p ~/ 3600;
    final m = (p % 3600) ~/ 60;
    final s = p.toInt() % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Stores per-book bookmarks in SharedPreferences with server sync.
class BookmarkService {
  static final BookmarkService _instance = BookmarkService._();
  factory BookmarkService() => _instance;
  BookmarkService._();

  static const int _maxBookmarksPerBook = 100;
  static const _keyPrefix = 'bookmarks_';
  // Persisted via ScopedPrefs so offline pending state survives app restart.
  static const _pendingCreatesKey = 'bookmarks_pending_creates';
  static const _pendingDeletesKey = 'bookmarks_pending_deletes';

  // Track bookmarks not yet pushed to server (created offline).
  final Set<String> _unpushed = {}; // "itemId::position" keys
  // Track bookmarks deleted offline that need to be deleted on server.
  final Map<String, Set<double>> _pendingDeletes = {}; // itemId -> positions
  // Scope key whose pending state is currently hydrated into the two fields above.
  String? _hydratedScope;

  /// Lazily load pending creates/deletes from prefs, re-hydrating when the
  /// active account scope changes.
  Future<void> _ensureHydrated() async {
    final scope = UserAccountService().activeScopeKey;
    if (_hydratedScope == scope) return;

    _unpushed.clear();
    _pendingDeletes.clear();

    final createsJson = await ScopedPrefs.getString(_pendingCreatesKey);
    if (createsJson != null && createsJson.isNotEmpty) {
      try {
        final list = jsonDecode(createsJson) as List<dynamic>;
        _unpushed.addAll(list.whereType<String>());
      } catch (e) {
        debugPrint('[Bookmarks] Failed to parse pending creates: $e');
      }
    }

    final deletesJson = await ScopedPrefs.getString(_pendingDeletesKey);
    if (deletesJson != null && deletesJson.isNotEmpty) {
      try {
        final map = jsonDecode(deletesJson) as Map<String, dynamic>;
        for (final entry in map.entries) {
          final positions = (entry.value as List<dynamic>)
              .whereType<num>()
              .map((n) => n.toDouble())
              .toSet();
          if (positions.isNotEmpty) _pendingDeletes[entry.key] = positions;
        }
      } catch (e) {
        debugPrint('[Bookmarks] Failed to parse pending deletes: $e');
      }
    }

    _hydratedScope = scope;
  }

  Future<void> _persistUnpushed() async {
    await ScopedPrefs.setString(_pendingCreatesKey, jsonEncode(_unpushed.toList()));
  }

  Future<void> _persistPendingDeletes() async {
    final out = <String, List<double>>{};
    for (final entry in _pendingDeletes.entries) {
      if (entry.value.isNotEmpty) out[entry.key] = entry.value.toList();
    }
    await ScopedPrefs.setString(_pendingDeletesKey, jsonEncode(out));
  }

  /// Get all bookmarks for a book.
  Future<List<Bookmark>> getBookmarks(String itemId, {String sort = 'newest'}) async {
    final stored = await ScopedPrefs.getStringList('$_keyPrefix$itemId');

    final bookmarks = <Bookmark>[];
    for (final json in stored) {
      try {
        bookmarks.add(Bookmark.fromJson(jsonDecode(json)));
      } catch (e) {
        debugPrint('[Bookmarks] Failed to parse: $e');
      }
    }

    if (sort == 'position') {
      bookmarks.sort((a, b) => a.positionSeconds.compareTo(b.positionSeconds));
    } else if (sort == 'position_desc') {
      bookmarks.sort((a, b) => b.positionSeconds.compareTo(a.positionSeconds));
    } else {
      bookmarks.sort((a, b) => b.created.compareTo(a.created));
    }
    return bookmarks;
  }

  /// Add a bookmark. Returns the new bookmark.
  Future<Bookmark> addBookmark({
    required String itemId,
    required double positionSeconds,
    required String title,
    String? note,
    ApiService? api,
  }) async {
    final bookmark = Bookmark(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      positionSeconds: positionSeconds,
      created: DateTime.now(),
      title: title,
      note: note,
    );

    final key = '$_keyPrefix$itemId';
    final existing = (await ScopedPrefs.getStringList(key)).toList();
    existing.add(jsonEncode(bookmark.toJson()));

    if (existing.length > _maxBookmarksPerBook) {
      existing.removeRange(0, existing.length - _maxBookmarksPerBook);
    }

    await ScopedPrefs.setStringList(key, existing);
    debugPrint('[Bookmarks] Added "${bookmark.title}" at ${bookmark.formattedPosition}');

    await _ensureHydrated();

    // Flag the bookmark pending BEFORE pushing it to the server. If the app is
    // suspended or killed mid-push (common on iOS right after bookmarking then
    // pausing), the flag is already persisted, so the next sync keeps and
    // retries it instead of seeing it missing on the server and deleting it.
    // Cleared only once the server confirms the create.
    final unpushedKey = '$itemId::${positionSeconds.toStringAsFixed(1)}';
    _unpushed.add(unpushedKey);
    await _persistUnpushed();
    if (api != null &&
        await api.createBookmark(itemId, time: positionSeconds, title: bookmark.serverTitle)) {
      _unpushed.remove(unpushedKey);
      await _persistUnpushed();
    }

    return bookmark;
  }

  /// Update a bookmark's title and/or note.
  Future<void> updateBookmark({
    required String itemId,
    required String bookmarkId,
    String? title,
    String? note,
    ApiService? api,
  }) async {
    final key = '$_keyPrefix$itemId';
    final stored = await ScopedPrefs.getStringList(key);

    double? time;
    String? serverTitle;
    final updated = <String>[];
    for (final json in stored) {
      try {
        final bm = Bookmark.fromJson(jsonDecode(json));
        if (bm.id == bookmarkId) {
          if (title != null) bm.title = title;
          // null = leave the note as-is; empty string = clear it.
          if (note != null) bm.note = note.isEmpty ? null : note;
          time = bm.positionSeconds;
          serverTitle = bm.serverTitle;
          updated.add(jsonEncode(bm.toJson()));
        } else {
          updated.add(json);
        }
      } catch (_) {
        updated.add(json);
      }
    }

    await ScopedPrefs.setStringList(key, updated);

    // Update on server
    if (api != null && time != null && serverTitle != null) {
      await api.updateBookmark(itemId, time: time, title: serverTitle);
    }
  }

  /// Move a bookmark to a new time. Updates locally and re-points the server
  /// entry - ABS keys bookmarks by time, so moving is delete-old + create-new.
  /// Falls back to the offline pending queues when the server can't be reached.
  Future<void> moveBookmark({
    required String itemId,
    required String bookmarkId,
    required double newPositionSeconds,
    ApiService? api,
  }) async {
    final newPos = newPositionSeconds < 0 ? 0.0 : newPositionSeconds;
    final key = '$_keyPrefix$itemId';
    final stored = await ScopedPrefs.getStringList(key);

    double? oldTime;
    String? serverTitle;
    final updated = <String>[];
    for (final json in stored) {
      try {
        final bm = Bookmark.fromJson(jsonDecode(json));
        if (bm.id == bookmarkId) {
          oldTime = bm.positionSeconds;
          serverTitle = bm.serverTitle;
          updated.add(jsonEncode(Bookmark(
            id: bm.id,
            positionSeconds: newPos,
            created: bm.created,
            title: bm.title,
            note: bm.note,
          ).toJson()));
        } else {
          updated.add(json);
        }
      } catch (_) {
        updated.add(json);
      }
    }
    if (oldTime == null) return; // bookmark not found
    await ScopedPrefs.setStringList(key, updated);
    if ((oldTime - newPos).abs() < 0.05) return; // no real change

    await _ensureHydrated();

    // The old position's pending-create (if any) no longer applies. Flag the
    // new position pending BEFORE the network calls (same write-ahead reasoning
    // as addBookmark) so a suspend or kill mid-move can't orphan the moved
    // bookmark and have the next sync delete it. Cleared once the server
    // confirms the create.
    final newKey = '$itemId::${newPos.toStringAsFixed(1)}';
    _unpushed.remove('$itemId::${oldTime.toStringAsFixed(1)}');
    _unpushed.add(newKey);
    await _persistUnpushed();

    bool deletedOk = false;
    bool createdOk = false;
    if (api != null) {
      deletedOk = await api.deleteBookmark(itemId, time: oldTime);
      createdOk = await api.createBookmark(itemId, time: newPos, title: serverTitle ?? '');
    }
    if (createdOk) _unpushed.remove(newKey);
    if (!deletedOk) _pendingDeletes.putIfAbsent(itemId, () => {}).add(oldTime);
    await _persistUnpushed();
    await _persistPendingDeletes();
    debugPrint('[Bookmarks] Moved $bookmarkId: ${oldTime}s -> ${newPos}s');
  }

  /// Delete a bookmark.
  Future<void> deleteBookmark({
    required String itemId,
    required String bookmarkId,
    ApiService? api,
  }) async {
    final key = '$_keyPrefix$itemId';
    final stored = await ScopedPrefs.getStringList(key);

    double? time;
    final updated = <String>[];
    for (final json in stored) {
      try {
        final bm = Bookmark.fromJson(jsonDecode(json));
        if (bm.id != bookmarkId) {
          updated.add(json);
        } else {
          time = bm.positionSeconds;
        }
      } catch (_) {
        updated.add(json);
      }
    }

    await ScopedPrefs.setStringList(key, updated);
    debugPrint('[Bookmarks] Deleted bookmark $bookmarkId');

    await _ensureHydrated();

    // If this bookmark was an unpushed offline create, drop the pending-create
    // flag - the server never knew about it, so there's nothing to delete.
    if (time != null) {
      final unpushedKey = '$itemId::${time.toStringAsFixed(1)}';
      if (_unpushed.remove(unpushedKey)) {
        await _persistUnpushed();
        return;
      }
    }

    // Delete on server
    if (time != null) {
      bool needsPersist = false;
      if (api != null) {
        final ok = await api.deleteBookmark(itemId, time: time);
        if (!ok) {
          _pendingDeletes.putIfAbsent(itemId, () => {}).add(time);
          needsPersist = true;
        }
      } else {
        _pendingDeletes.putIfAbsent(itemId, () => {}).add(time);
        needsPersist = true;
      }
      if (needsPersist) await _persistPendingDeletes();
    }
  }

  /// Sync bookmarks for a specific item with the server.
  /// Merges local and server bookmarks by position (time).
  /// If [preloadedServerBookmarks] is provided, uses that instead of fetching.
  Future<void> syncBookmarks(String itemId, ApiService api, {List<Map<String, dynamic>>? preloadedServerBookmarks}) async {
    try {
      await _ensureHydrated();

      // Flush any pending deletes first. Keep entries that still failed so we
      // can retry next sync instead of silently dropping them.
      final pendingDels = _pendingDeletes[itemId];
      if (pendingDels != null && pendingDels.isNotEmpty) {
        final stillPending = <double>{};
        for (final time in pendingDels) {
          final deleted = await api.deleteBookmark(itemId, time: time);
          if (deleted) {
            debugPrint('[Bookmarks] Flushed pending delete at ${time}s');
          } else {
            stillPending.add(time);
          }
        }
        if (stillPending.isEmpty) {
          _pendingDeletes.remove(itemId);
        } else {
          _pendingDeletes[itemId] = stillPending;
        }
        await _persistPendingDeletes();
      }

      final serverBookmarks = preloadedServerBookmarks ?? await api.getServerBookmarks(itemId);
      if (serverBookmarks == null) return; // offline or error

      final localBookmarks = await getBookmarks(itemId);

      // Build position-based lookup (with 1s tolerance)
      bool posMatch(double a, double b) => (a - b).abs() < 1.0;

      // Find server bookmarks not in local
      for (final sb in serverBookmarks) {
        final serverBm = Bookmark.fromServer(sb);
        final localMatch = localBookmarks.where((lb) => posMatch(lb.positionSeconds, serverBm.positionSeconds)).firstOrNull;
        if (localMatch == null) {
          // Server has it, local doesn't - add locally
          final key = '$_keyPrefix$itemId';
          final existing = (await ScopedPrefs.getStringList(key)).toList();
          existing.add(jsonEncode(serverBm.toJson()));
          await ScopedPrefs.setStringList(key, existing);
          debugPrint('[Bookmarks] Synced from server: "${serverBm.title}" at ${serverBm.formattedPosition}');
        } else if (serverBm.serverTitle != localMatch.serverTitle && serverBm.created.isAfter(localMatch.created)) {
          // Server is newer - take its title and note (fromServer already
          // split the combined server string back into the two fields).
          localMatch
            ..title = serverBm.title
            ..note = serverBm.note;
          await _saveAll(itemId, localBookmarks);
          debugPrint('[Bookmarks] Updated from server: "${serverBm.title}"');
        }
      }

      // Remove local bookmarks that no longer exist on server,
      // but push any that were created offline and haven't been synced yet.
      final refreshedLocal = await getBookmarks(itemId);
      final kept = <Bookmark>[];
      bool localChanged = false;
      bool unpushedChanged = false;
      for (final lb in refreshedLocal) {
        final serverMatch = serverBookmarks.whereType<Map<String, dynamic>>().where((sb) =>
            posMatch((sb['time'] as num?)?.toDouble() ?? 0, lb.positionSeconds)).firstOrNull;
        if (serverMatch != null) {
          kept.add(lb);
          continue;
        }
        final unpushedKey = '$itemId::${lb.positionSeconds.toStringAsFixed(1)}';
        if (_unpushed.contains(unpushedKey)) {
          // Created offline, try to push now. Only clear the pending flag if
          // the push actually succeeded - otherwise we keep retrying on the
          // next sync instead of silently losing the bookmark.
          final pushed = await api.createBookmark(itemId, time: lb.positionSeconds, title: lb.serverTitle);
          if (pushed) {
            _unpushed.remove(unpushedKey);
            unpushedChanged = true;
            debugPrint('[Bookmarks] Pushed offline bookmark: "${lb.title}" at ${lb.formattedPosition}');
          } else {
            debugPrint('[Bookmarks] Push failed, will retry: "${lb.title}" at ${lb.formattedPosition}');
          }
          kept.add(lb);
        } else {
          debugPrint('[Bookmarks] Removed locally (deleted on server): "${lb.title}" at ${lb.formattedPosition}');
          localChanged = true;
        }
      }
      if (localChanged) await _saveAll(itemId, kept);
      if (unpushedChanged) await _persistUnpushed();
    } catch (e) {
      debugPrint('[Bookmarks] Sync error: $e');
    }
  }

  /// Save all bookmarks for an item (used internally after batch updates).
  Future<void> _saveAll(String itemId, List<Bookmark> bookmarks) async {
    final key = '$_keyPrefix$itemId';
    await ScopedPrefs.setStringList(key, bookmarks.map((b) => jsonEncode(b.toJson())).toList());
  }

  /// Get all bookmarks across all books for the current account, keyed by itemId.
  Future<Map<String, List<Bookmark>>> getAllBookmarks({String sort = 'newest'}) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = UserAccountService().activeScopeKey;
    final scopedPrefix = scope.isNotEmpty ? '$scope:$_keyPrefix' : _keyPrefix;
    final result = <String, List<Bookmark>>{};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(scopedPrefix)) continue;
      final itemId = key.substring(scopedPrefix.length);
      // The service's own offline-sync keys (bookmarks_pending_creates /
      // bookmarks_pending_deletes) live under the same "bookmarks_" prefix but
      // are Strings, not String lists. getStringList() throws on them, which
      // used to leave the Bookmarks screen spinning forever for any account
      // that had made offline bookmark changes. Skip them (and guard defensively).
      if (itemId == 'pending_creates' || itemId == 'pending_deletes') continue;
      final List<String> stored;
      try {
        stored = prefs.getStringList(key) ?? [];
      } catch (_) {
        continue;
      }
      final bookmarks = <Bookmark>[];
      for (final json in stored) {
        try {
          bookmarks.add(Bookmark.fromJson(jsonDecode(json)));
        } catch (_) {}
      }
      if (bookmarks.isNotEmpty) {
        if (sort == 'position') {
          bookmarks.sort((a, b) => a.positionSeconds.compareTo(b.positionSeconds));
        } else if (sort == 'position_desc') {
          bookmarks.sort((a, b) => b.positionSeconds.compareTo(a.positionSeconds));
        } else {
          bookmarks.sort((a, b) => b.created.compareTo(a.created));
        }
        result[itemId] = bookmarks;
      }
    }

    if (sort == 'newest') {
      final sorted = Map.fromEntries(
        result.entries.toList()..sort((a, b) => b.value.first.created.compareTo(a.value.first.created)),
      );
      return sorted;
    }

    return result;
  }

  /// Get bookmark count for a book.
  Future<int> getCount(String itemId) async {
    return (await ScopedPrefs.getStringList('$_keyPrefix$itemId')).length;
  }

  /// Clear all bookmarks for a book.
  Future<void> clearBookmarks(String itemId) async {
    await ScopedPrefs.remove('$_keyPrefix$itemId');
    await _ensureHydrated();
    final prefix = '$itemId::';
    final dropped = _unpushed.where((k) => k.startsWith(prefix)).toList();
    if (dropped.isNotEmpty) {
      _unpushed.removeAll(dropped);
      await _persistUnpushed();
    }
    if (_pendingDeletes.remove(itemId) != null) {
      await _persistPendingDeletes();
    }
  }
}
