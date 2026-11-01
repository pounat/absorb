import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/book_stats_service.dart';
import '../services/api_service.dart';
import '../services/bookorbit_mapper.dart';
import '../utils/read_status.dart';
import '../widgets/book_activity_card.dart';
import '../widgets/overlay_toast.dart';

enum _Range { all, last30, last90, thisYear }

/// A book's reading log on BookOrbit, after the web app's Reading Log tab:
/// where the book stands, records, attempts, and every session on it from
/// any app or device.
class ReadingLogScreen extends StatefulWidget {
  final String itemId;
  final String title;
  final Map<String, dynamic>? item;
  final Color? accent;
  const ReadingLogScreen({super.key, required this.itemId, required this.title, this.item, this.accent});

  @override
  State<ReadingLogScreen> createState() => _ReadingLogScreenState();
}

class _ReadingLogScreenState extends State<ReadingLogScreen> {
  static const _pageSize = 25;

  BookOrbitApiService? _api;
  List<Map<String, dynamic>> _sessions = [];
  int _total = 0;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _attempts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  _Range _range = _Range.all;
  String? _format;
  String _sortBy = 'startedAt';
  bool _desc = true;
  final Set<String> _formatsSeen = {};

  /// Bumped on every reload, so an answer to an older filter is dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    final api = context.read<AuthProvider>().apiService;
    _api = api is BookOrbitApiService ? api : null;
    _load();
    _loadAttempts();
  }

  DateTime? get _from {
    final now = DateTime.now();
    return switch (_range) {
      _Range.all => null,
      _Range.last30 => now.subtract(const Duration(days: 30)),
      _Range.last90 => now.subtract(const Duration(days: 90)),
      _Range.thisYear => DateTime(now.year),
    };
  }

  bool get _chronological => _sortBy == 'startedAt';

  static List<Map<String, dynamic>> _items(Map<String, dynamic> res) =>
      (res['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();

  void _noteFormats(Iterable<Map<String, dynamic>> sessions) {
    for (final s in sessions) {
      final f = (s['format'] as String?)?.toLowerCase();
      if (f != null && f.isNotEmpty) _formatsSeen.add(f);
    }
  }

  Future<void> _load({bool silent = false}) async {
    final api = _api;
    if (api == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    final gen = ++_generation;
    if (!silent) setState(() => _loading = true);
    try {
      final res = await api.readingLog(widget.itemId,
          pageSize: _pageSize, sortBy: _sortBy, descending: _desc, from: _from, format: _format);
      if (!mounted || gen != _generation) return;
      setState(() {
        _sessions = _items(res);
        _total = (res['total'] as num?)?.toInt() ?? _sessions.length;
        _stats = (res['stats'] as Map?)?.cast<String, dynamic>();
        if (_format == null) _noteFormats(_sessions);
        _loading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('[ReadingLog] ${widget.itemId}: $e');
      if (!mounted || gen != _generation) return;
      setState(() {
        _loading = false;
        _failed = _stats == null;
      });
      if (!_failed) showOverlayToast(context, AppLocalizations.of(context)!.readingLogLoadFailed);
    }
  }

  Future<void> _loadMore() async {
    final api = _api;
    if (api == null || _loading || _loadingMore || _sessions.length >= _total) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final res = await api.readingLog(widget.itemId,
          page: _sessions.length ~/ _pageSize + 1,
          pageSize: _pageSize,
          sortBy: _sortBy,
          descending: _desc,
          from: _from,
          format: _format);
      if (!mounted || gen != _generation) return;
      final seen = {for (final s in _sessions) s['id']};
      setState(() {
        final more = _items(res).where((s) => !seen.contains(s['id'])).toList();
        _sessions = [..._sessions, ...more];
        _total = (res['total'] as num?)?.toInt() ?? _total;
        if (_format == null) _noteFormats(more);
      });
    } catch (e) {
      debugPrint('[ReadingLog] more for ${widget.itemId}: $e');
      if (mounted) showOverlayToast(context, AppLocalizations.of(context)!.readingLogLoadFailed);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadAttempts() async {
    final api = _api;
    if (api == null) return;
    try {
      final list = await api.readingAttempts(widget.itemId);
      if (mounted) setState(() => _attempts = list);
    } catch (e) {
      debugPrint('[ReadingLog] attempts for ${widget.itemId}: $e');
    }
  }

  Future<void> _refresh() => Future.wait([_load(silent: true), _loadAttempts()]);

  void _setFilter({_Range? range, String? format, bool clearFormat = false}) {
    setState(() {
      if (range != null) _range = range;
      if (clearFormat) {
        _format = null;
      } else if (format != null) {
        _format = format;
      }
    });
    _load();
  }

  void _setSort(String value) {
    setState(() {
      if (value == 'desc' || value == 'asc') {
        _desc = value == 'desc';
      } else {
        _sortBy = value;
        _desc = true;
      }
    });
    _load();
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    final l = AppLocalizations.of(context)!;
    final api = _api;
    if (api == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.readingLogDeleteTitle),
        content: Text(l.readingLogDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = await api.deleteListeningSession('bo-session-${s['id']}', itemId: widget.itemId);
    if (!mounted) return;
    if (!done) {
      showOverlayToast(context, l.readingLogDeleteFailed);
      return;
    }
    setState(() {
      _sessions = _sessions.where((x) => x['id'] != s['id']).toList();
      _total = math.max(0, _total - 1);
    });
    await _refresh();
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    BookStatsService.instance.ensureLoaded(widget.itemId, api, isAdmin: auth.isAdmin, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = widget.accent ?? cs.primary;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.readingLogTitle),
          Text(widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.readingLogSortBy,
            icon: const Icon(Icons.sort_rounded),
            onSelected: _setSort,
            itemBuilder: (_) => [
              for (final e in {
                'startedAt': l.readingLogSortDay,
                'durationSeconds': l.readingLogSortLength,
                'progressDelta': l.readingLogSortChange,
                'endProgress': l.readingLogSortReached,
              }.entries)
                CheckedPopupMenuItem(value: e.key, checked: _sortBy == e.key, child: Text(e.value)),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                  value: 'desc',
                  checked: _desc,
                  child: Text(_chronological ? l.readingLogNewestFirst : l.readingLogMostFirst)),
              CheckedPopupMenuItem(
                  value: 'asc',
                  checked: !_desc,
                  child: Text(_chronological ? l.readingLogOldestFirst : l.readingLogLeastFirst)),
            ],
          ),
        ],
      ),
      body: _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(l.readingLogLoadFailed, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  FilledButton.tonal(onPressed: _load, child: Text(l.retry)),
                ]),
              ),
            )
          : _stats == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(context).padding.bottom),
                    children: [
                      _vitals(context, l, cs, tt, accent),
                      if (_hasChart) ...[
                        const SizedBox(height: 12),
                        _chart(context, l, cs, tt, accent),
                      ],
                      if (_recordRows(context, l).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _records(context, l, cs, tt, accent),
                      ],
                      if (_attempts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _attemptsCard(context, l, cs, tt, accent),
                      ],
                      const SizedBox(height: 12),
                      _ledger(context, l, cs, tt, accent),
                    ],
                  ),
                ),
    );
  }

  Widget _card(ColorScheme cs, {required Widget child, EdgeInsets padding = const EdgeInsets.fromLTRB(14, 12, 14, 12)}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: child,
      );

  Widget _heading(String text, ColorScheme cs, TextTheme tt, {Widget? trailing}) => Row(children: [
        Text(text.toUpperCase(),
            style: tt.labelSmall?.copyWith(
                fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        if (trailing != null) ...[const SizedBox(width: 8), Expanded(child: trailing)],
      ]);

  Widget _line(String label, Widget value, ColorScheme cs, TextTheme tt, {bool first = false}) => Container(
        height: 30,
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
        ),
        child: Row(children: [
          Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const Spacer(),
          DefaultTextStyle.merge(
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
            child: value,
          ),
        ]),
      );

  // Vitals

  _Insights get _insights => _Insights.of(_stats);

  double get _currentProgress {
    final lib = context.read<LibraryProvider>();
    final logged = (_stats?['latestEndProgress'] as num?)?.toDouble() ?? 0;
    return [
      lib.getProgress(widget.itemId) * 100,
      lib.getEbookProgress(widget.itemId) * 100,
      logged,
    ].reduce(math.max).clamp(0.0, 100.0);
  }

  Map<String, dynamic>? get _readStatus =>
      ((widget.item?['bookOrbit'] as Map?)?['readStatus'] as Map?)?.cast<String, dynamic>();

  String _date(BuildContext context, DateTime d, {bool year = true}) {
    final locale = Localizations.localeOf(context).toString();
    return year && d.year != DateTime.now().year ? DateFormat.yMMMd(locale).format(d) : DateFormat.MMMd(locale).format(d);
  }

  /// A reading date as BookOrbit stores it: the day is what counts.
  static DateTime? _day(Object? v) {
    if (v is! String || v.length < 10) return null;
    return DateTime.tryParse(v.substring(0, 10));
  }

  String? _eta(AppLocalizations l, String status) {
    if (status == 'read' || status == 'abandoned') return null;
    final pace = _insights.pace;
    if (pace == null) return null;
    final remaining = 100 - _currentProgress;
    if (remaining <= 0) return null;
    final minutes = remaining / pace * 60;
    if (!minutes.isFinite || minutes <= 0) return null;
    if (minutes > 99 * 60) return l.readingLogLeftMax;
    final rounded = math.max(5, (minutes / 5).round() * 5);
    final h = rounded ~/ 60;
    final m = rounded % 60;
    if (h == 0) return l.readingLogLeftMinutes(m);
    if (m == 0) return l.readingLogLeftHours(h);
    return l.readingLogLeftHoursMinutes(h, m);
  }

  String _formatsLine() {
    final files = ((widget.item?['bookOrbit'] as Map?)?['files'] as List<dynamic>? ?? const []).whereType<Map>();
    return files
        .where((f) => f['role'] == 'primary' || f['role'] == 'content')
        .map((f) => (f['format'] as String?)?.toUpperCase())
        .whereType<String>()
        .toSet()
        .join(' · ');
  }

  List<String> get _formats {
    final files = ((widget.item?['bookOrbit'] as Map?)?['files'] as List<dynamic>? ?? const []).whereType<Map>();
    final out = <String>{
      for (final f in files)
        if ((f['role'] == 'primary' || f['role'] == 'content') && f['format'] is String) (f['format'] as String).toLowerCase(),
      ..._formatsSeen,
    }.toList()
      ..sort();
    return out;
  }

  Widget _vitals(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, Color accent) {
    final s = _stats!;
    final i = _insights;
    final rs = _readStatus;
    final status = rs?['status'] as String? ?? 'unread';
    final progress = _currentProgress;
    final eta = _eta(l, status);
    final formats = _formatsLine();
    final started = _day(rs?['startedAt']);
    final finished = _day(rs?['finishedAt']);
    final lastAt = BookOrbitMapper.ms(s['lastSessionAt']);
    final m = i.momentum;
    final momentumIcon = !m.hasActivity || (m.percent == 0 && !m.isNew)
        ? Icon(Icons.remove_rounded, size: 14, color: cs.onSurfaceVariant)
        : m.up
            ? Icon(Icons.trending_up_rounded, size: 14, color: accent)
            : const Icon(Icons.trending_down_rounded, size: 14, color: Colors.amber);
    final momentumText = !m.hasActivity
        ? l.readingLogQuietTwoWeeks
        : m.isNew
            ? l.readingLogNewThisWeek
            : m.percent == 0
                ? l.readingLogSameAsLastWeek
                : m.up
                    ? l.readingLogUpOnLastWeek(m.percent!)
                    : l.readingLogDownOnLastWeek(m.percent!.abs());
    final sources = (s['bySource'] as List<dynamic>? ?? const []).whereType<Map>().toList();
    return _card(cs,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 5,
                    color: accent,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                Text(activityPercent(progress), style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(readStatusIcon(status), size: 16, color: accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(readStatusLabel(l, status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ]),
                if (eta != null || formats.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    if (eta != null) ...[
                      Icon(Icons.schedule_rounded, size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(eta ?? formats,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                  ]),
                ],
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          _line(l.readingLogStarted, Text(started == null ? l.readingLogNotSet : _date(context, started)), cs, tt,
              first: true),
          _line(l.readingLogFinished, Text(finished == null ? l.readingLogNotSet : _date(context, finished)), cs, tt),
          Divider(height: 12, color: cs.onSurface.withValues(alpha: 0.12)),
          _line(
            l.readingLogTotalTime,
            Row(mainAxisSize: MainAxisSize.min, children: [
              Tooltip(message: momentumText, child: momentumIcon),
              const SizedBox(width: 4),
              Text(activityDuration(l, (s['totalSeconds'] as num?)?.toDouble() ?? 0)),
            ]),
            cs,
            tt,
            first: true,
          ),
          _line(l.bookStatsSessions, Text('${(s['totalSessions'] as num?)?.toInt() ?? 0}'), cs, tt),
          _line(l.readingLogAverageSession, Text(activityDuration(l, (s['avgDurationSeconds'] as num?)?.toDouble() ?? 0)),
              cs, tt),
          _line(
              l.readingLogActiveDays,
              Text(i.spanDays > 0 ? l.readingLogActiveDaysOf(i.activeDays, i.spanDays) : '0'),
              cs,
              tt),
          _line(l.readingLogPace,
              Text(i.pace == null ? '-' : l.readingLogPacePerHour(i.pace!.toStringAsFixed(1))), cs, tt),
          _line(l.readingLogLastRead, Text(lastAt == null ? '-' : activityAgo(context, l, lastAt)), cs, tt),
          if (sources.length >= 2) ...[
            const SizedBox(height: 12),
            _heading(l.readingLogWhereYouRead, cs, tt),
            const SizedBox(height: 8),
            _sourceSplit(context, l, cs, tt, sources),
          ],
        ]));
  }

  Widget _sourceSplit(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, List<Map> sources) {
    final total = sources.fold<double>(0, (a, s) => a + ((s['totalSeconds'] as num?)?.toDouble() ?? 0));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 6,
          child: Row(children: [
            for (final s in sources)
              if (((s['totalSeconds'] as num?)?.toDouble() ?? 0) > 0)
                Expanded(
                  flex: math.max(1, (((s['totalSeconds'] as num).toDouble()) / math.max(1, total) * 1000).round()),
                  child: ColoredBox(color: _bucketColor(cs, '${s['bucket']}')),
                ),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      for (final s in sources)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: _bucketColor(cs, '${s['bucket']}'), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(_bucketLabel(l, '${s['bucket']}'), style: tt.bodySmall)),
            Text(
              '${activityDuration(l, (s['totalSeconds'] as num?)?.toDouble() ?? 0)} · '
              '${l.readingLogSessionCount((s['totalSessions'] as num?)?.toInt() ?? 0)}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ]),
        ),
    ]);
  }

  static String _bucket(Object? source) => switch (source) {
        'ios' || 'watchos' || 'android' || 'koreader' || 'kobo' => source as String,
        _ => 'bookorbit',
      };

  static String _bucketLabel(AppLocalizations l, String bucket) => switch (bucket) {
        'ios' => l.readingLogSourceIos,
        'android' => l.readingLogSourceAndroid,
        'watchos' => 'Apple Watch',
        'koreader' => 'KOReader',
        'kobo' => 'Kobo',
        _ => 'BookOrbit',
      };

  static Color _bucketColor(ColorScheme cs, String bucket) => switch (bucket) {
        'ios' => const Color(0xFF4C8DF6),
        'android' => const Color(0xFF3DBE6E),
        'watchos' => const Color(0xFFF2994A),
        'koreader' => const Color(0xFFA77BE0),
        'kobo' => const Color(0xFF2FB5C4),
        _ => cs.primary,
      };

  // Chart

  bool get _hasChart {
    final s = _stats;
    if (s == null) return false;
    return (s['dailySummary'] as List?)?.isNotEmpty == true || (s['progressSummary'] as List?)?.isNotEmpty == true;
  }

  Widget _chart(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, Color accent) {
    final s = _stats!;
    final locale = Localizations.localeOf(context).toString();
    final minutesByDay = <String, double>{
      for (final d in (s['dailySummary'] as List<dynamic>? ?? const []).whereType<Map>())
        '${d['day']}': (d['totalMinutes'] as num?)?.toDouble() ?? 0,
    };
    final progressByDay = <String, double>{
      for (final d in (s['progressSummary'] as List<dynamic>? ?? const []).whereType<Map>())
        if (d['endProgress'] is num) '${d['day']}': (d['endProgress'] as num).toDouble(),
    };
    final labels = <String>[];
    final minutes = <double>[];
    final progress = <double?>[];
    final days = {...minutesByDay.keys, ...progressByDay.keys}.toList()..sort();
    // A book read in one sitting has a single day to plot, so it goes
    // session by session instead.
    final oneDay = _sessions.length >= 2 &&
        _sessions
                .map((x) => DateTime.tryParse('${x['startedAt']}')?.toLocal())
                .whereType<DateTime>()
                .map(BookActivity.dayKey)
                .toSet()
                .length ==
            1;
    if (oneDay) {
      final timeline = [..._sessions]
        ..sort((a, b) => '${a['startedAt']}'.compareTo('${b['startedAt']}'));
      for (final x in timeline) {
        final at = DateTime.tryParse('${x['startedAt']}')?.toLocal();
        labels.add(at == null ? '' : DateFormat.jm(locale).format(at));
        minutes.add(((x['durationSeconds'] as num?)?.toDouble() ?? 0) / 60);
        progress.add((x['endProgress'] as num?)?.toDouble());
      }
    } else {
      for (final d in days) {
        final at = DateTime.tryParse(d);
        labels.add(at == null ? d : DateFormat.MMMd(locale).format(at));
        minutes.add(minutesByDay[d] ?? 0);
        progress.add(progressByDay[d]);
      }
    }
    final i = _insights;
    final muted = tt.labelSmall?.copyWith(color: cs.onSurfaceVariant);
    return _card(cs,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _heading(l.readingLogChartTitle, cs, tt,
              trailing: i.spanDays > 1
                  ? Text(l.readingLogActiveDaysOf(i.activeDays, i.spanDays),
                      textAlign: TextAlign.end, style: muted)
                  : null),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _ProgressChartPainter(
                minutes: minutes,
                progress: progress,
                line: accent,
                bar: accent.withValues(alpha: 0.28),
                grid: cs.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (labels.isNotEmpty)
            Row(children: [
              Text(labels.first, style: muted),
              const Spacer(),
              if (labels.length > 1) Text(labels.last, style: muted),
            ]),
          const SizedBox(height: 8),
          Wrap(spacing: 16, runSpacing: 4, children: [
            _legend(Container(width: 14, height: 2, color: accent), l.readingLogChartPosition, muted),
            _legend(
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(2))),
                l.readingLogChartMinutes,
                muted),
          ]),
        ]));
  }

  Widget _legend(Widget swatch, String text, TextStyle? style) =>
      Row(mainAxisSize: MainAxisSize.min, children: [swatch, const SizedBox(width: 6), Text(text, style: style)]);

  // Records

  List<(IconData, String, String, String?)> _recordRows(BuildContext context, AppLocalizations l) {
    final s = _stats;
    if (s == null) return const [];
    final i = _insights;
    final out = <(IconData, String, String, String?)>[];
    final longest = (s['longestSessionSeconds'] as num?)?.toDouble() ?? 0;
    if (longest > 0) {
      final at = DateTime.tryParse('${s['longestSessionAt']}')?.toLocal();
      out.add((
        Icons.timer_outlined,
        l.readingLogLongestSession,
        activityDuration(l, longest),
        at == null ? null : _date(context, at, year: false),
      ));
    }
    if (i.bestDay != null) {
      out.add((Icons.emoji_events_outlined, l.readingLogBestDay, activityDuration(l, i.bestDay!.value * 60), null));
    }
    if (i.longestStreak > 0) {
      out.add((
        Icons.local_fire_department_outlined,
        l.readingLogLongestStreak,
        l.readingLogStreakDays(i.longestStreak),
        null,
      ));
    }
    if (i.pace != null) {
      out.add((Icons.bolt_rounded, l.readingLogPace, l.readingLogPacePerHour(i.pace!.toStringAsFixed(1)), null));
    }
    final back = (s['backtrackCount'] as num?)?.toInt() ?? 0;
    if (back > 0) {
      out.add((Icons.u_turn_left_rounded, l.readingLogJumpedBack, l.readingLogJumpedBackTimes(back), null));
    }
    final first = DateTime.tryParse('${s['firstSessionAt']}')?.toLocal();
    if (first != null) {
      out.add((Icons.calendar_today_outlined, l.readingLogFirstOpened, _date(context, first), null));
    }
    return out;
  }

  Widget _records(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, Color accent) {
    final rows = _recordRows(context, l);
    return _card(cs,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _heading(l.readingLogRecords, cs, tt),
          const SizedBox(height: 6),
          for (var n = 0; n < rows.length; n++)
            Container(
              height: 30,
              decoration: BoxDecoration(
                border: n == 0 ? null : Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
              ),
              child: Row(children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(rows[n].$1, size: 12, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(rows[n].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ),
                Text(rows[n].$3, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                if (rows[n].$4 != null) ...[
                  const SizedBox(width: 6),
                  Text(rows[n].$4!, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ]),
            ),
        ]));
  }

  // Attempts

  List<Map<String, dynamic>> get _attemptsInOrder => [..._attempts]..sort((a, b) {
      final da = '${a['startedOn'] ?? a['endedOn'] ?? ''}';
      final db = '${b['startedOn'] ?? b['endedOn'] ?? ''}';
      if (da != db) return da.compareTo(db);
      return ((a['id'] as num?) ?? 0).compareTo((b['id'] as num?) ?? 0);
    });

  int? _attemptOrdinal(Object? id) {
    final ordered = _attemptsInOrder;
    final i = ordered.indexWhere((a) => a['id'] == id);
    return i < 0 ? null : i + 1;
  }

  String _span(BuildContext context, AppLocalizations l, Map<String, dynamic> a) {
    final from = _day(a['startedOn']);
    final to = _day(a['endedOn']);
    if (from != null && to != null) return l.readingLogSpanRange(_date(context, from), _date(context, to));
    if (from != null) return l.readingLogSpanSince(_date(context, from));
    if (to != null) return l.readingLogSpanEnded(_date(context, to));
    return l.readingLogSpanUnknown;
  }

  String _outcome(AppLocalizations l, Map<String, dynamic> a) => switch (a['outcome']) {
        'completed' => l.readingLogOutcomeCompleted,
        'skimmed' => l.readingLogOutcomeSkimmed,
        'abandoned' => l.readingLogOutcomeAbandoned,
        _ => l.readingLogOutcomeInProgress,
      };

  Widget _attemptsCard(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, Color accent) {
    final ordered = _attemptsInOrder.reversed.toList();
    return _card(cs,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _heading(l.readingLogAttempts, cs, tt),
          const SizedBox(height: 4),
          for (var n = 0; n < ordered.length; n++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: n == 0 ? null : Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(l.readingLogAttempt(ordered.length - n),
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (ordered[n]['outcome'] == null ? accent : cs.onSurfaceVariant)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_outcome(l, ordered[n]),
                            style: tt.labelSmall?.copyWith(
                                color: ordered[n]['outcome'] == null ? accent : cs.onSurfaceVariant)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(_span(context, l, ordered[n]),
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                ),
                Text(
                  '${l.readingLogSessionCount((ordered[n]['totalSessions'] as num?)?.toInt() ?? 0)}\n'
                  '${activityDuration(l, (ordered[n]['totalSeconds'] as num?)?.toDouble() ?? 0)}',
                  textAlign: TextAlign.end,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ]),
            ),
        ]));
  }

  // Sessions

  Widget _ledger(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, Color accent) {
    final muted = tt.labelSmall?.copyWith(color: cs.onSurfaceVariant);
    final formats = _formats;
    final filtered = _range != _Range.all || _format != null;
    final mixed = _sessions.map((s) => s['format']).whereType<String>().toSet().length > 1;
    return _card(cs,
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _heading(l.bookStatsSessions, cs, tt,
                trailing: Text(
                  _total == 0
                      ? ''
                      : _sessions.length < _total
                          ? l.readingLogShowing(_sessions.length, _total)
                          : '$_total',
                  style: muted,
                )),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (final r in _Range.values) ...[
                  ChoiceChip(
                    label: Text(switch (r) {
                      _Range.all => l.readingLogAllTime,
                      _Range.last30 => l.readingLogLast30,
                      _Range.last90 => l.readingLogLast90,
                      _Range.thisYear => l.readingLogThisYear,
                    }),
                    selected: _range == r,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _setFilter(range: r),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          if (formats.length >= 2) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  ChoiceChip(
                    label: Text(l.readingLogAllFormats),
                    selected: _format == null,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _setFilter(clearFormat: true),
                  ),
                  for (final f in formats) ...[
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(f.toUpperCase()),
                      selected: _format == f,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => _setFilter(format: f),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
          if (_sessions.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(children: [
                Text(filtered ? l.readingLogNoMatches : l.readingLogEmpty,
                    textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (!filtered) ...[
                  const SizedBox(height: 6),
                  Text(l.readingLogEmptyHint,
                      textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ]),
            )
          else
            Opacity(
              opacity: _loading ? 0.5 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _rows(context, l, cs, tt, accent, mixed),
              ),
            ),
          if (_sessions.length < _total && !_loading)
            Center(
              child: TextButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: _loadingMore
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.showMore),
              ),
            ),
        ]));
  }

  static String _localDay(Object? iso) {
    final d = DateTime.tryParse('$iso')?.toLocal();
    return d == null ? '' : BookActivity.dayKey(d);
  }

  List<Widget> _rows(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, Color accent, bool mixed) {
    final locale = Localizations.localeOf(context).toString();
    final muted = tt.labelSmall?.copyWith(color: cs.onSurfaceVariant);
    final out = <Widget>[];
    String? previousDay;
    for (var n = 0; n < _sessions.length; n++) {
      final s = _sessions[n];
      final day = _localDay(s['startedAt']);
      if (_chronological && n > 0) {
        final previous = _sessions[n - 1];
        if (s['attemptId'] != previous['attemptId']) {
          final newer = _desc ? previous['attemptId'] : s['attemptId'];
          if (newer != null) out.add(_attemptMarker(context, l, cs, tt, accent, newer));
        }
        final a = DateTime.tryParse(_localDay(previous['startedAt']));
        final b = DateTime.tryParse(day);
        if (a != null && b != null) {
          final gap = a.difference(b).inDays.abs() - 1;
          if (gap >= 3) out.add(_gapMarker(l, cs, tt, gap));
        }
      }
      if (_chronological && day != previousDay) {
        final d = DateTime.tryParse(day);
        if (d != null) {
          out.add(Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
            child: Text(
              d.year == DateTime.now().year ? DateFormat.MMMEd(locale).format(d) : DateFormat.yMMMEd(locale).format(d),
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ));
        }
      }
      previousDay = day;
      out.add(_sessionRow(context, l, cs, tt, accent, s, mixed, muted));
    }
    final last = _sessions.isEmpty ? null : _sessions.last;
    if (_chronological && _desc && last?['attemptId'] != null && _sessions.length >= _total) {
      out.add(_attemptMarker(context, l, cs, tt, accent, last!['attemptId']));
    }
    return out;
  }

  Widget _gapMarker(AppLocalizations l, ColorScheme cs, TextTheme tt, int days) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          Expanded(child: Divider(color: cs.onSurface.withValues(alpha: 0.12))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(l.readingLogGapDays(days), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(child: Divider(color: cs.onSurface.withValues(alpha: 0.12))),
        ]),
      );

  Widget _attemptMarker(
      BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, Color accent, Object? attemptId) {
    final ordinal = _attemptOrdinal(attemptId);
    if (ordinal == null) return const SizedBox.shrink();
    final attempt = _attempts.firstWhere((a) => a['id'] == attemptId);
    final from = _day(attempt['startedOn']);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.4))),
      ),
      child: Row(children: [
        Icon(Icons.replay_rounded, size: 13, color: accent),
        const SizedBox(width: 6),
        Text(l.readingLogAttemptBegan(ordinal),
            style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: accent)),
        if (from != null) ...[
          const SizedBox(width: 6),
          Text(_date(context, from), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ]),
    );
  }

  Widget _sessionRow(BuildContext context, AppLocalizations l, ColorScheme cs, TextTheme tt, Color accent,
      Map<String, dynamic> s, bool mixed, TextStyle? muted) {
    final locale = Localizations.localeOf(context).toString();
    final at = DateTime.tryParse('${s['startedAt']}')?.toLocal();
    final delta = (s['progressDelta'] as num?)?.toDouble();
    final end = (s['endProgress'] as num?)?.toDouble();
    final change = delta == null
        ? '-'
        : delta.abs() < 0.05
            ? '0%'
            : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}%';
    final changeColor = (delta ?? 0) > 0.05
        ? accent
        : (delta ?? 0) < -0.05
            ? Colors.amber.shade700
            : cs.onSurfaceVariant;
    final bucket = _bucket(s['source']);
    final bold = tt.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 2, 0),
      child: Row(children: [
        Tooltip(
          message: _bucketLabel(l, bucket),
          child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: _bucketColor(cs, bucket), shape: BoxShape.circle)),
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 62,
          child: Text(
            at == null
                ? '-'
                : _chronological
                    ? DateFormat.jm(locale).format(at)
                    : DateFormat.MMMd(locale).format(at),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
        if (mixed)
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: s['format'] is String ? FormatChip(format: s['format'] as String) : null,
            ),
          ),
        SizedBox(
          width: 50,
          child: Text(activityDuration(l, (s['durationSeconds'] as num?)?.toDouble() ?? 0),
              maxLines: 1, style: bold),
        ),
        SizedBox(
          width: 48,
          child: Text(change, maxLines: 1, style: bold?.copyWith(color: changeColor)),
        ),
        Expanded(child: _PositionBar(end: end, delta: delta ?? 0, accent: accent)),
        SizedBox(
          width: 40,
          child: Text(end == null ? '-' : '${end.toStringAsFixed(0)}%',
              maxLines: 1, textAlign: TextAlign.end, style: bold?.copyWith(color: cs.onSurfaceVariant)),
        ),
        IconButton(
          tooltip: l.delete,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          color: cs.onSurfaceVariant,
          onPressed: () => _delete(s),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ]),
    );
  }
}

/// The stretch of the book one session covered, with a tick where it ended.
class _PositionBar extends StatelessWidget {
  final double? end;
  final double delta;
  final Color accent;
  const _PositionBar({required this.end, required this.delta, required this.accent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final children = <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ];
      final e = end;
      if (e != null) {
        final to = e.clamp(0.0, 100.0);
        final from = (to - delta).clamp(0.0, 100.0);
        final low = math.min(from, to);
        // A session that ends at the very end still needs a visible mark.
        final width = math.max(1.5, (from - to).abs());
        final left = math.min(low, 100 - width);
        children
          ..add(Positioned(
            left: w * left / 100,
            width: w * width / 100,
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: delta < -0.5 ? Colors.amber : accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ))
          ..add(Positioned(
            left: (w * to / 100 - 1).clamp(0.0, math.max(0.0, w - 2)),
            width: 2,
            top: 0,
            bottom: 0,
            child: ColoredBox(color: cs.onSurface.withValues(alpha: 0.7)),
          ));
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(height: 6, child: Stack(children: children)),
      );
    });
  }
}

/// Bars for the minutes on each day (or session), and a line through the
/// position each one reached.
class _ProgressChartPainter extends CustomPainter {
  final List<double> minutes;
  final List<double?> progress;
  final Color line;
  final Color bar;
  final Color grid;
  _ProgressChartPainter({
    required this.minutes,
    required this.progress,
    required this.line,
    required this.bar,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = minutes.length;
    if (n == 0) return;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final slot = size.width / n;
    final peak = minutes.fold<double>(1, math.max);
    final barPaint = Paint()..color = bar;
    final barWidth = math.min(18.0, slot * 0.6);
    for (var i = 0; i < n; i++) {
      if (minutes[i] <= 0) continue;
      final h = size.height * 0.9 * minutes[i] / peak;
      final x = slot * i + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, barWidth, h), const Radius.circular(2)),
        barPaint,
      );
    }
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = line;
    final path = Path();
    var started = false;
    for (var i = 0; i < n; i++) {
      final p = progress[i];
      if (p == null) continue;
      final o = Offset(slot * i + slot / 2, size.height * (1 - p.clamp(0, 100) / 100));
      if (started) {
        path.lineTo(o.dx, o.dy);
      } else {
        path.moveTo(o.dx, o.dy);
        started = true;
      }
      canvas.drawCircle(o, n > 40 ? 1.5 : 2.5, dot);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_ProgressChartPainter old) =>
      old.minutes != minutes || old.progress != progress || old.line != line || old.bar != bar || old.grid != grid;
}

class _Momentum {
  final bool hasActivity;
  final bool isNew;
  final bool up;
  final int? percent;
  const _Momentum({this.hasActivity = false, this.isNew = false, this.up = false, this.percent});
}

/// What no single field of BookOrbit's summary says outright: active days,
/// streaks, the best day, a pace that is safe to show, and how this week
/// compares with the one before.
class _Insights {
  final int activeDays;
  final int spanDays;
  final int longestStreak;
  final MapEntry<String, double>? bestDay;
  final double? pace;
  final _Momentum momentum;
  const _Insights({
    this.activeDays = 0,
    this.spanDays = 0,
    this.longestStreak = 0,
    this.bestDay,
    this.pace,
    this.momentum = const _Momentum(),
  });

  /// A pace over a few seconds is noise, not a rate.
  static const _minPaceSeconds = 600;

  static DateTime _utc(String day) {
    final d = DateTime.parse(day);
    return DateTime.utc(d.year, d.month, d.day);
  }

  static _Insights of(Map<String, dynamic>? stats) {
    if (stats == null) return const _Insights();
    final days = <MapEntry<String, double>>[
      for (final d in (stats['dailySummary'] as List<dynamic>? ?? const []).whereType<Map>())
        if (((d['totalMinutes'] as num?) ?? 0) > 0 && DateTime.tryParse('${d['day']}') != null)
          MapEntry('${d['day']}', (d['totalMinutes'] as num).toDouble()),
    ]..sort((a, b) => a.key.compareTo(b.key));
    var span = 0;
    var streak = 0;
    MapEntry<String, double>? best;
    if (days.isNotEmpty) {
      span = _utc(days.last.key).difference(_utc(days.first.key)).inDays + 1;
      streak = 1;
      var run = 1;
      for (var i = 1; i < days.length; i++) {
        final gap = _utc(days[i].key).difference(_utc(days[i - 1].key)).inDays;
        run = gap == 1 ? run + 1 : 1;
        streak = math.max(streak, run);
      }
      for (final d in days) {
        if (best == null || d.value > best.value) best = d;
      }
    }
    double? pace;
    final delta = (stats['paceProgressDelta'] as num?)?.toDouble() ?? 0;
    final seconds = (stats['paceDurationSeconds'] as num?)?.toDouble() ?? 0;
    if (delta > 0 && seconds >= _minPaceSeconds) pace = delta / (seconds / 3600);

    final byDay = {for (final d in days) d.key: d.value};
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    var recent = 0.0;
    var previous = 0.0;
    for (var o = 0; o < 7; o++) {
      recent += byDay[BookActivity.dayKey(today.subtract(Duration(days: o)))] ?? 0;
      previous += byDay[BookActivity.dayKey(today.subtract(Duration(days: o + 7)))] ?? 0;
    }
    final _Momentum momentum;
    if (recent == 0 && previous == 0) {
      momentum = const _Momentum();
    } else if (previous <= 0) {
      momentum = const _Momentum(hasActivity: true, isNew: true, up: true);
    } else {
      final pct = ((recent - previous) / previous * 100).round();
      momentum = _Momentum(hasActivity: true, up: pct > 0, percent: pct);
    }
    return _Insights(
      activeDays: days.length,
      spanDays: span,
      longestStreak: streak,
      bestDay: best,
      pace: pace,
      momentum: momentum,
    );
  }
}
