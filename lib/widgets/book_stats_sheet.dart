import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/scoped_prefs.dart';

/// Listening stats for one book: always the reader's own, plus a server-wide
/// picture for admins (who listened, who finished, how long altogether).
///
/// The server has no per-item stats endpoint, so this adds up playback
/// sessions: the current user's own item sessions, and for admins the
/// sessions of each user whose progress mentions this book. Users who never
/// touched it are never fetched, which keeps the admin view to a handful of
/// requests on a normal server.
Future<void> showBookStatsSheet(
  BuildContext context, {
  required String itemId,
  required String title,
  String? episodeId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => _BookStatsSheet(
        itemId: itemId,
        title: title,
        episodeId: episodeId,
        scrollController: scrollController,
      ),
    ),
  );
}

class _UserStat {
  final String username;
  final double progress;
  final bool finished;
  final int? finishedAt;

  /// When this user's progress on the item last moved. Cached alongside the
  /// total so a later visit can tell, without fetching anything heavy, that
  /// their sessions haven't changed.
  final int lastUpdate;
  double seconds = 0;
  _UserStat(this.username, this.progress, this.finished, this.finishedAt,
      this.lastUpdate);

  Map<String, dynamic> toJson() => {
        'u': username,
        'p': progress,
        'f': finished,
        'fa': finishedAt,
        'lu': lastUpdate,
        's': seconds,
      };

  static _UserStat fromJson(Map<String, dynamic> j) => _UserStat(
        j['u'] as String? ?? '',
        (j['p'] as num?)?.toDouble() ?? 0,
        j['f'] == true,
        (j['fa'] as num?)?.toInt(),
        (j['lu'] as num?)?.toInt() ?? 0,
      )..seconds = (j['s'] as num?)?.toDouble() ?? 0;
}

class _BookStatsSheet extends StatefulWidget {
  final String itemId;
  final String title;
  final String? episodeId;
  final ScrollController scrollController;
  const _BookStatsSheet({
    required this.itemId,
    required this.title,
    required this.episodeId,
    required this.scrollController,
  });

  @override
  State<_BookStatsSheet> createState() => _BookStatsSheetState();
}

class _BookStatsSheetState extends State<_BookStatsSheet> {
  bool _loading = true;
  bool _failed = false;

  double _mySeconds = 0;
  int _mySessions = 0;
  int? _myFirst;
  int? _myLast;

  bool _isAdmin = false;
  bool _serverLoading = false;
  List<_UserStat> _users = [];

  /// Progress through the per-user session scan, for the wait message.
  int _scanDone = 0;
  int _scanTotal = 0;
  int? _checkedAt;

  String get _cacheKey => widget.episodeId != null
      ? 'bookStats_${widget.itemId}_${widget.episodeId}'
      : 'bookStats_${widget.itemId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Last visit's numbers, shown instantly so the sheet is never empty while
  /// the scan below brings them up to date.
  Future<void> _loadCache() async {
    final raw = await ScopedPrefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty || !mounted) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final me = j['me'] as Map<String, dynamic>?;
      final users = (j['users'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_UserStat.fromJson)
          .toList();
      setState(() {
        _checkedAt = (j['at'] as num?)?.toInt();
        if (me != null) {
          _mySeconds = (me['s'] as num?)?.toDouble() ?? 0;
          _mySessions = (me['n'] as num?)?.toInt() ?? 0;
          _myFirst = (me['f'] as num?)?.toInt();
          _myLast = (me['l'] as num?)?.toInt();
        }
        _users = users;
        _loading = false;
      });
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    final payload = jsonEncode({
      'at': DateTime.now().millisecondsSinceEpoch,
      'me': {
        's': _mySeconds,
        'n': _mySessions,
        'f': _myFirst,
        'l': _myLast,
      },
      'users': [for (final u in _users) u.toJson()],
    });
    await ScopedPrefs.setString(_cacheKey, payload);
  }

  Future<void> _load() async {
    await _loadCache();
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) {
      setState(() {
        _loading = false;
        _failed = _checkedAt == null;
      });
      return;
    }
    final sessions = await api.getMyItemListeningSessions(
      widget.itemId,
      episodeId: widget.episodeId,
    );
    if (!mounted) return;
    var total = 0.0;
    int? first;
    int? last;
    for (final s in sessions) {
      if (s is! Map) continue;
      total += (s['timeListening'] as num?)?.toDouble() ?? 0;
      final at = (s['updatedAt'] as num?)?.toInt() ??
          (s['startedAt'] as num?)?.toInt();
      if (at != null) {
        if (first == null || at < first) first = at;
        if (last == null || at > last) last = at;
      }
    }
    setState(() {
      _mySeconds = total;
      _mySessions = sessions.length;
      _myFirst = first;
      _myLast = last;
      _loading = false;
      _isAdmin = auth.isAdmin;
    });
    if (auth.isAdmin) {
      _loadServerWide();
    } else {
      _checkedAt = DateTime.now().millisecondsSinceEpoch;
      await _saveCache();
    }
  }

  Future<void> _loadServerWide() async {
    setState(() => _serverLoading = true);
    final api = context.read<AuthProvider>().apiService;
    if (api == null) {
      if (mounted) setState(() => _serverLoading = false);
      return;
    }
    final userList = await api.getUsers();
    if (!mounted) return;
    // Anything already scanned, keyed by name so a cached total can be reused
    // when that person's progress hasn't moved since.
    final cached = {for (final u in _users) u.username: u};
    final stats = <String, _UserStat>{};
    for (final entry in userList) {
      if (entry is! Map) continue;
      final id = entry['id'] as String?;
      if (id == null) continue;
      // The users list is deliberately minimal server-side and carries no
      // progress at all - only the single-user endpoint returns it.
      final u = await api.getUser(id);
      if (!mounted) return;
      if (u == null) continue;
      for (final p in (u['mediaProgress'] as List<dynamic>? ?? const [])) {
        if (p is! Map) continue;
        if (p['libraryItemId'] != widget.itemId) continue;
        if (widget.episodeId != null && p['episodeId'] != widget.episodeId) {
          continue;
        }
        stats[id] = _UserStat(
          u['username'] as String? ?? '',
          (p['progress'] as num?)?.toDouble() ?? 0,
          p['isFinished'] == true,
          (p['finishedAt'] as num?)?.toInt(),
          (p['lastUpdate'] as num?)?.toInt() ?? 0,
        );
        break;
      }
    }
    // The session scan is the slow part, so skip anyone whose progress hasn't
    // moved since the last visit and reuse their stored total.
    final pending = <String, _UserStat>{};
    for (final e in stats.entries) {
      final was = cached[e.value.username];
      if (was != null && was.lastUpdate >= e.value.lastUpdate) {
        e.value.seconds = was.seconds;
      } else {
        pending[e.key] = e.value;
      }
    }
    if (mounted) {
      setState(() {
        _scanDone = 0;
        _scanTotal = pending.length;
      });
    }
    for (final entry in pending.entries) {
      final payload = await api.getUserListeningSessions(entry.key,
          itemsPerPage: 1000);
      if (!mounted) return;
      final sessions = (payload?['sessions'] as List<dynamic>?) ?? const [];
      var total = 0.0;
      for (final s in sessions) {
        if (s is! Map) continue;
        if (s['libraryItemId'] != widget.itemId) continue;
        if (widget.episodeId != null && s['episodeId'] != widget.episodeId) {
          continue;
        }
        total += (s['timeListening'] as num?)?.toDouble() ?? 0;
      }
      entry.value.seconds = total;
      if (mounted) setState(() => _scanDone++);
    }
    if (!mounted) return;
    debugPrint('[BookStats] item=${widget.itemId} users=${userList.length} '
        'withProgress=${stats.length} rescanned=${pending.length}');
    final list = stats.values.toList()
      ..sort((a, b) => b.seconds.compareTo(a.seconds));
    setState(() {
      _users = list;
      _serverLoading = false;
      _checkedAt = DateTime.now().millisecondsSinceEpoch;
    });
    await _saveCache();
  }

  String _dur(double seconds, AppLocalizations l) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (h > 0) return l.statsScreenDurationHm(h, m);
    if (m > 0) return l.statsScreenDurationM(m);
    if (seconds > 0) return l.statsScreenDurationLessThanMin;
    return l.statsScreenDurationZero;
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(widget.title,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_failed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l.statsCouldNotLoad,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          )
        else ...[
          Text(l.bookStatsYou.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant, letterSpacing: 1)),
          const SizedBox(height: 8),
          _row(l.bookStatsListened, _dur(_mySeconds, l), cs, tt),
          _row(l.bookStatsSessions, '$_mySessions', cs, tt),
          if (_myFirst != null)
            _row(l.bookStatsFirst, _date(_myFirst!), cs, tt),
          if (_myLast != null) _row(l.bookStatsLast, _date(_myLast!), cs, tt),
          if (_isAdmin) ...[
            const SizedBox(height: 22),
            Row(children: [
              Text(l.bookStatsEveryone.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant, letterSpacing: 1)),
              const Spacer(),
              // Cached numbers stay on screen while the rescan runs, so say
              // when they were last brought up to date.
              if (_serverLoading && _users.isNotEmpty)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: cs.onSurfaceVariant),
                )
              else if (_checkedAt != null)
                Text(l.bookStatsLastChecked(_date(_checkedAt!)),
                    style:
                        tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
            const SizedBox(height: 8),
            if (_serverLoading && _users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    _scanTotal > 0
                        ? l.bookStatsScanningCount(_scanDone, _scanTotal)
                        : l.bookStatsScanning,
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ]),
              )
            else if (_users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l.bookStatsNobody,
                    style:
                        tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              )
            else ...[
              _row(
                  l.bookStatsListeners, '${_users.length}', cs, tt),
              _row(l.bookStatsFinishedCount,
                  '${_users.where((u) => u.finished).length}', cs, tt),
              _row(
                  l.bookStatsTotalTime,
                  _dur(_users.fold(0.0, (a, u) => a + u.seconds), l),
                  cs,
                  tt),
              const SizedBox(height: 12),
              for (final u in _users)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(
                      u.finished
                          ? Icons.check_circle_rounded
                          : Icons.headphones_rounded,
                      size: 18,
                      color: u.finished ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(u.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium),
                    ),
                    Text(
                      '${(u.progress * 100).clamp(0, 100).round()}%  ${_dur(u.seconds, l)}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ]),
                ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _row(String label, String value, ColorScheme cs, TextTheme tt) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: tt.bodyMedium),
            Text(value,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
