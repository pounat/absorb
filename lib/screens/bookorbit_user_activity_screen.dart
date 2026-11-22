import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/bookorbit_admin.dart';
import 'bookorbit_admin_screen.dart';

/// The reading activity a BookOrbit user chose to share. Opening this is
/// recorded by the server and shown to them.
class BookOrbitUserActivityScreen extends StatefulWidget {
  final BoUser user;
  const BookOrbitUserActivityScreen({super.key, required this.user});

  @override
  State<BookOrbitUserActivityScreen> createState() => _BookOrbitUserActivityScreenState();
}

class _BookOrbitUserActivityScreenState extends State<BookOrbitUserActivityScreen> {
  static const _periods = [30, 90, 365];

  int _days = 90;
  String? _viewSession;
  BoReadingSummary? _summary;
  BoReadingDetail? _detail;
  bool _loading = true;
  String? _error;
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    final id = ++_loadId;
    setState(() {
      _loading = true;
      _error = null;
      _summary = null;
      _detail = null;
    });
    try {
      final (summary, detail) = await _fetch(api);
      if (!mounted || id != _loadId) return;
      setState(() {
        _summary = summary;
        _detail = detail;
      });
    } on BookOrbitAdminError catch (e) {
      if (!mounted || id != _loadId) return;
      setState(() => _error = switch ((e.status, e.code)) {
            (_, 'READING_INSIGHTS_PRIVATE') => l.boActivityNowPrivate,
            (0, _) => l.boAdminOffline,
            _ => l.boActivityLoadFailed,
          });
    } catch (_) {
      if (mounted && id == _loadId) setState(() => _error = l.boActivityLoadFailed);
    } finally {
      if (mounted && id == _loadId) setState(() => _loading = false);
    }
  }

  /// A view lasts 15 minutes, so a period change after that starts a new one.
  Future<(BoReadingSummary, BoReadingDetail?)> _fetch(BookOrbitApiService api) async {
    final existing = _viewSession;
    try {
      return await _fetchWith(api, existing ?? await _openView(api));
    } on BookOrbitAdminError catch (e) {
      if (existing == null || e.code != 'READING_INSIGHTS_VIEW_SESSION_INVALID') rethrow;
      return _fetchWith(api, await _openView(api));
    }
  }

  Future<String> _openView(BookOrbitApiService api) async =>
      _viewSession = await api.adminOpenReadingActivity(widget.user.id);

  Future<(BoReadingSummary, BoReadingDetail?)> _fetchWith(BookOrbitApiService api, String view) async {
    final summary = await api.adminReadingSummary(widget.user.id, view, _days);
    if (!summary.detailed) return (summary, null);
    try {
      return (summary, await api.adminReadingDetail(widget.user.id, view, _days));
    } on BookOrbitAdminError catch (e) {
      // They cut back to a summary while this was open.
      if (e.code == 'READING_INSIGHTS_SUMMARY_ONLY') return (summary, null);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final summary = _summary;
    final error = _error;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 4),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.boActivityTitle, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(widget.user.name, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ]),
              ),
            ]),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final days in _periods)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l.boActivityDays(days)),
                      selected: _days == days,
                      onSelected: (_) {
                        if (_days == days) return;
                        setState(() => _days = days);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Row(children: [
                    Icon(Icons.visibility_outlined, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.boActivityNotice, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                  ]),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(children: [
                      Text(error, textAlign: TextAlign.center, style: tt.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _load, child: Text(l.retry)),
                    ]),
                  )
                else if (summary != null)
                  ..._content(context, l, summary, _detail),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _content(BuildContext context, AppLocalizations l, BoReadingSummary s, BoReadingDetail? d) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final metrics = [
      (l.boActivityReadingTime, _duration(l, s.readingSeconds)),
      (l.boActivitySessions, '${s.sessions}'),
      (l.boActivityActiveDays, '${s.activeDays}'),
      (l.boActivityStarted, '${s.booksStarted}'),
      (l.boActivityFinished, '${s.booksCompleted}'),
    ];
    return [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (label, value) in metrics)
          Container(
            width: 104,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ),
      ]),
      const SizedBox(height: 12),
      if (!s.hasReading)
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Text(l.boActivityEmpty, textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        )
      else ...[
        if (s.trend.isNotEmpty) _Card(title: l.boActivityTrend, children: [_Trend(points: s.trend, label: (v) => _duration(l, v))]),
        _times(l, l.boActivitySources, s.sources, name: (n) => _sourceName(l, n)),
        _times(l, l.boActivityFormats, s.formats),
        _times(l, l.boActivityGenres, s.genres, name: (n) => _genreName(l, n)),
        if (d != null) ...[
          if (d.topBooks.isNotEmpty)
            _Card(title: l.boActivityTopBooks, children: [
              for (final b in d.topBooks) _Row(b.title ?? l.boActivityUntitled, _duration(l, b.seconds)),
            ]),
          if (d.recentBooks.isNotEmpty)
            _Card(title: l.boActivityRecentBooks, children: [
              for (final b in d.recentBooks)
                _Row(
                  b.title ?? l.boActivityUntitled,
                  b.lastRead == null ? '' : l.backupDateFormat(b.lastRead!.month, b.lastRead!.day, b.lastRead!.year),
                ),
            ]),
          _times(l, l.boActivityTopAuthors, d.topAuthors),
          _times(l, l.boActivityTopGenres, d.topGenres),
          _times(l, l.boActivityTopSeries, d.topSeries),
          _times(l, l.boActivityTopNarrators, d.topNarrators),
        ],
      ],
    ];
  }

  Widget _times(AppLocalizations l, String title, List<BoReadingTime> items, {String Function(String)? name}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Card(title: title, children: [
      for (final item in items) _Row(name?.call(item.name) ?? item.name, _duration(l, item.seconds)),
    ]);
  }
}

String _duration(AppLocalizations l, int seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return l.boActivityMinutes(minutes);
  return l.boActivityHours(((minutes / 60) * 10).round() / 10);
}

String _sourceName(AppLocalizations l, String source) => switch (source) {
      'web' => l.boActivitySourceWeb,
      'ios' => l.boActivitySourceIos,
      'watchos' => l.boActivitySourceWatch,
      'android' => l.boActivitySourceAndroid,
      'koreader' => 'KOReader',
      'manual' => l.boActivitySourceManual,
      'kobo' => 'Kobo',
      'unknown' => l.boActivitySourceUnknown,
      _ => source,
    };

String _genreName(AppLocalizations l, String genre) => switch (genre) {
      'science_fiction' => l.boActivityGenreSciFi,
      'fantasy' => l.boActivityGenreFantasy,
      'mystery_thriller' => l.boActivityGenreMystery,
      'romance' => l.boActivityGenreRomance,
      'horror' => l.boActivityGenreHorror,
      'history_biography' => l.boActivityGenreHistory,
      'science_technology' => l.boActivityGenreScience,
      'business_economics' => l.boActivityGenreBusiness,
      'self_development' => l.boActivityGenreSelf,
      'society_culture' => l.boActivityGenreSociety,
      'children_young_adult' => l.boActivityGenreChildren,
      'comics_graphic_novels' => l.boActivityGenreComics,
      'poetry' => l.boActivityGenrePoetry,
      'other' => l.boActivityGenreOther,
      _ => genre,
    };

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodyMedium)),
        const SizedBox(width: 12),
        Text(value, style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _Trend extends StatelessWidget {
  final List<({DateTime day, int seconds})> points;
  final String Function(int seconds) label;
  const _Trend({required this.points, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final recent = points.length > 12 ? points.sublist(points.length - 12) : points;
    final most = recent.fold<int>(1, (m, p) => p.seconds > m ? p.seconds : m);
    return Column(children: [
      for (final p in recent)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(
              width: 84,
              child: Text(
                l.backupDateFormat(p.day.month, p.day.day, p.day.year),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (p.seconds / most).clamp(0.04, 1.0),
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(label(p.seconds), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),
    ]);
  }
}
