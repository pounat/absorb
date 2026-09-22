import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'scoped_prefs.dart';

/// One other user's standing on a book, from the admin scan.
class BookUserStat {
  final String username;
  final double progress;
  final bool finished;
  final int? finishedAt;

  /// When this user's progress on the item last moved. Cached alongside the
  /// total so a later visit can tell, without fetching anything heavy, that
  /// their sessions haven't changed.
  final int lastUpdate;
  double seconds = 0;
  BookUserStat(this.username, this.progress, this.finished, this.finishedAt,
      this.lastUpdate);

  Map<String, dynamic> toJson() => {
        'u': username,
        'p': progress,
        'f': finished,
        'fa': finishedAt,
        'lu': lastUpdate,
        's': seconds,
      };

  static BookUserStat fromJson(Map<String, dynamic> j) => BookUserStat(
        j['u'] as String? ?? '',
        (j['p'] as num?)?.toDouble() ?? 0,
        j['f'] == true,
        (j['fa'] as num?)?.toInt(),
        (j['lu'] as num?)?.toInt() ?? 0,
      )..seconds = (j['s'] as num?)?.toDouble() ?? 0;
}

/// Listening stats for one book (or podcast episode): the reader's own
/// sessions, and for admins a server-wide picture. Lives past any one sheet,
/// so the detail sheet can start the load the moment it opens and the stats
/// sheet finds the numbers ready, or already on their way.
class BookStats extends ChangeNotifier {
  final String itemId;
  final String? episodeId;
  BookStats(this.itemId, this.episodeId);

  bool loading = true;
  bool failed = false;

  /// Own sessions, newest first, as the server sent them.
  List<Map<String, dynamic>> sessions = const [];
  double mySeconds = 0;
  int mySessions = 0;
  int? myFirst;
  int? myLast;

  bool isAdmin = false;
  bool serverLoading = false;
  List<BookUserStat> users = [];

  /// Progress through the per-user session scan, for the wait message.
  int scanDone = 0;
  int scanTotal = 0;
  int? checkedAt;

  /// When the last full load finished, to skip a pointless repeat.
  DateTime? _loadedAt;
  Future<void>? _inFlight;

  String get cacheKey => episodeId != null
      ? 'bookStats_${itemId}_$episodeId'
      : 'bookStats_$itemId';

  /// Everyone from the scan except [me].
  int othersCount(String? me) =>
      users.where((u) => u.username != me).length;

  /// The service mutates the fields above and calls this after each step.
  void bump() => notifyListeners();
}

class BookStatsService {
  BookStatsService._();
  static final BookStatsService instance = BookStatsService._();

  static const Duration _freshFor = Duration(minutes: 5);

  final Map<String, BookStats> _books = {};

  static String _key(String itemId, String? episodeId) =>
      episodeId != null ? '$itemId-$episodeId' : itemId;

  BookStats stats(String itemId, {String? episodeId}) =>
      _books.putIfAbsent(
          _key(itemId, episodeId), () => BookStats(itemId, episodeId));

  /// Load [itemId]'s stats unless they are fresh or already loading; a
  /// caller arriving mid-load simply waits on the same work.
  Future<void> ensureLoaded(String itemId, ApiService api,
      {String? episodeId, required bool isAdmin, bool force = false}) {
    final s = stats(itemId, episodeId: episodeId);
    final inFlight = s._inFlight;
    if (inFlight != null) return inFlight;
    final loadedAt = s._loadedAt;
    if (!force &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _freshFor &&
        (!isAdmin || s.isAdmin)) {
      return Future.value();
    }
    final run = _load(s, api, isAdmin).whenComplete(() => s._inFlight = null);
    s._inFlight = run;
    return run;
  }

  Future<void> _load(BookStats s, ApiService api, bool isAdmin) async {
    await _loadCache(s);
    final sessions = await api.getMyItemListeningSessions(
      s.itemId,
      episodeId: s.episodeId,
    );
    var total = 0.0;
    int? first;
    int? last;
    final list = <Map<String, dynamic>>[];
    for (final raw in sessions) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      list.add(m);
      total += (m['timeListening'] as num?)?.toDouble() ?? 0;
      final at = (m['updatedAt'] as num?)?.toInt() ??
          (m['startedAt'] as num?)?.toInt();
      if (at != null) {
        if (first == null || at < first) first = at;
        if (last == null || at > last) last = at;
      }
    }
    list.sort((a, b) {
      final ta = (a['updatedAt'] as num?)?.toInt() ?? (a['startedAt'] as num?)?.toInt() ?? 0;
      final tb = (b['updatedAt'] as num?)?.toInt() ?? (b['startedAt'] as num?)?.toInt() ?? 0;
      return tb.compareTo(ta);
    });
    s.sessions = list;
    s.mySeconds = total;
    s.mySessions = list.length;
    s.myFirst = first;
    s.myLast = last;
    s.loading = false;
    s.failed = false;
    s.isAdmin = isAdmin;
    s.bump();
    if (isAdmin) {
      await _loadServerWide(s, api);
    } else {
      s.checkedAt = DateTime.now().millisecondsSinceEpoch;
      await _saveCache(s);
    }
    s._loadedAt = DateTime.now();
    s.bump();
  }

  /// Last visit's numbers, shown instantly so nothing is empty while the
  /// scan brings them up to date.
  Future<void> _loadCache(BookStats s) async {
    if (s.checkedAt != null) return;
    final raw = await ScopedPrefs.getString(s.cacheKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final me = j['me'] as Map<String, dynamic>?;
      s.checkedAt = (j['at'] as num?)?.toInt();
      if (me != null) {
        s.mySeconds = (me['s'] as num?)?.toDouble() ?? 0;
        s.mySessions = (me['n'] as num?)?.toInt() ?? 0;
        s.myFirst = (me['f'] as num?)?.toInt();
        s.myLast = (me['l'] as num?)?.toInt();
      }
      s.users = (j['users'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BookUserStat.fromJson)
          .toList();
      s.loading = false;
      s.bump();
    } catch (_) {}
  }

  Future<void> _saveCache(BookStats s) async {
    final payload = jsonEncode({
      'at': DateTime.now().millisecondsSinceEpoch,
      'me': {
        's': s.mySeconds,
        'n': s.mySessions,
        'f': s.myFirst,
        'l': s.myLast,
      },
      'users': [for (final u in s.users) u.toJson()],
    });
    await ScopedPrefs.setString(s.cacheKey, payload);
  }

  Future<void> _loadServerWide(BookStats s, ApiService api) async {
    s.serverLoading = true;
    s.bump();
    try {
      final userList = await api.getUsers();
      // Anything already scanned, keyed by name so a cached total can be
      // reused when that person's progress hasn't moved since.
      final cached = {for (final u in s.users) u.username: u};
      final found = <String, BookUserStat>{};
      for (final entry in userList) {
        if (entry is! Map) continue;
        final id = entry['id'] as String?;
        if (id == null) continue;
        // The users list is deliberately minimal server-side and carries no
        // progress at all - only the single-user endpoint returns it.
        final u = await api.getUser(id);
        if (u == null) continue;
        for (final p in (u['mediaProgress'] as List<dynamic>? ?? const [])) {
          if (p is! Map) continue;
          if (p['libraryItemId'] != s.itemId) continue;
          if (s.episodeId != null && p['episodeId'] != s.episodeId) continue;
          found[id] = BookUserStat(
            u['username'] as String? ?? '',
            (p['progress'] as num?)?.toDouble() ?? 0,
            p['isFinished'] == true,
            (p['finishedAt'] as num?)?.toInt(),
            (p['lastUpdate'] as num?)?.toInt() ?? 0,
          );
          break;
        }
      }
      // The session scan is the slow part, so skip anyone whose progress
      // hasn't moved since the last visit and reuse their stored total.
      final pending = <String, BookUserStat>{};
      for (final e in found.entries) {
        final was = cached[e.value.username];
        if (was != null && was.lastUpdate >= e.value.lastUpdate) {
          e.value.seconds = was.seconds;
        } else {
          pending[e.key] = e.value;
        }
      }
      s.scanDone = 0;
      s.scanTotal = pending.length;
      s.bump();
      for (final entry in pending.entries) {
        final payload =
            await api.getUserListeningSessions(entry.key, itemsPerPage: 1000);
        final sessions = (payload?['sessions'] as List<dynamic>?) ?? const [];
        var total = 0.0;
        for (final sess in sessions) {
          if (sess is! Map) continue;
          if (sess['libraryItemId'] != s.itemId) continue;
          if (s.episodeId != null && sess['episodeId'] != s.episodeId) continue;
          total += (sess['timeListening'] as num?)?.toDouble() ?? 0;
        }
        entry.value.seconds = total;
        s.scanDone++;
        s.bump();
      }
      debugPrint('[BookStats] item=${s.itemId} users=${userList.length} '
          'withProgress=${found.length} rescanned=${pending.length}');
      s.users = found.values.toList()
        ..sort((a, b) => b.seconds.compareTo(a.seconds));
      s.checkedAt = DateTime.now().millisecondsSinceEpoch;
      await _saveCache(s);
    } catch (e) {
      debugPrint('[BookStats] server-wide scan failed for ${s.itemId}: $e');
    } finally {
      s.serverLoading = false;
      s.bump();
    }
  }
}
