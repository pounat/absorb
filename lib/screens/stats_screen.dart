import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/finished_books_this_year_sheet.dart';
import '../widgets/absorb_wave_icon.dart';
import '../widgets/card_buttons.dart';
import '../main.dart' show oledNotifier;
import 'app_shell.dart';
import '../l10n/app_localizations.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  int _booksFinished = 0;
  int _episodesFinished = 0;
  int _booksFinishedThisYear = 0;
  int _episodesFinishedThisYear = 0;
  late AnimationController _animController;
  late Animation<double> _animValue;

  static const int _sessionsPerPage = 10;
  int _sessionsPage = 0;
  bool _hasMoreSessions = true;
  bool _isLoadingMoreSessions = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _animValue =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _scrollController.addListener(_onScroll);
    _loadStats();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMoreSessions();
    }
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMoreSessions || !_hasMoreSessions) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _isLoadingMoreSessions = true);
    final nextPage = _sessionsPage + 1;
    final data = await api.getListeningSessions(
        page: nextPage, itemsPerPage: _sessionsPerPage);
    if (!mounted) return;
    final fetched = data?['sessions'] as List<dynamic>? ?? [];
    setState(() {
      if (fetched.isNotEmpty) {
        _sessions = [..._sessions, ...fetched];
        _sessionsPage = nextPage;
      }
      if (fetched.length < _sessionsPerPage) _hasMoreSessions = false;
      _isLoadingMoreSessions = false;
    });
  }

  static const _kStats = 'cached_stats';
  static const _kSessions = 'cached_sessions';

  Future<void> _loadStats() async {
    final api = context.read<AuthProvider>().apiService;
    final lib = context.read<LibraryProvider>();
    final prefs = await SharedPreferences.getInstance();

    // Load cached data first so the page renders immediately even offline.
    if (_isLoading) {
      final cachedStats = prefs.getString(_kStats);
      final cachedSessions = prefs.getString(_kSessions);
      if (cachedStats != null) {
        final stats = jsonDecode(cachedStats) as Map<String, dynamic>;
        final sessions = cachedSessions != null
            ? (jsonDecode(cachedSessions) as List<dynamic>)
            : <dynamic>[];
        if (mounted) {
          setState(() {
            _stats = stats;
            _sessions = sessions;
            _booksFinished = lib.finishedBooksCount;
            _episodesFinished = lib.finishedEpisodesCount;
            _booksFinishedThisYear = lib.finishedBooksThisYearCount;
            _episodesFinishedThisYear = lib.finishedEpisodesThisYearCount;
            _isLoading = false;
          });
          _animController.reset();
          _animController.forward();
        }
      }
    }

    if (api == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Phase 1: load core stats from network and cache them.
    final stats = await api.getListeningStats();
    final finishedBooks = lib.finishedBooksCount;
    final finishedEpisodes = lib.finishedEpisodesCount;
    final finishedBooksYear = lib.finishedBooksThisYearCount;
    final finishedEpisodesYear = lib.finishedEpisodesThisYearCount;

    if (stats != null) {
      prefs.setString(_kStats, jsonEncode(stats));
    }

    if (mounted) {
      setState(() {
        _stats = stats ?? _stats; // keep cached if network failed
        _booksFinished = finishedBooks;
        _episodesFinished = finishedEpisodes;
        _booksFinishedThisYear = finishedBooksYear;
        _episodesFinishedThisYear = finishedEpisodesYear;
        _isLoading = false;
      });
      if (_animController.status != AnimationStatus.forward &&
          _animController.status != AnimationStatus.completed) {
        _animController.reset();
        _animController.forward();
      }
    }

    // Phase 2: load heavier sessions list in background and cache.
    final sessionsData =
        await api.getListeningSessions(page: 0, itemsPerPage: _sessionsPerPage);
    final sessions = sessionsData?['sessions'] as List<dynamic>? ?? [];
    if (sessions.isNotEmpty) {
      prefs.setString(_kSessions, jsonEncode(sessions));
    }
    if (mounted) {
      setState(() {
        if (sessions.isNotEmpty) _sessions = sessions;
        _sessionsPage = 0;
        _hasMoreSessions = sessions.length >= _sessionsPerPage;
        _isLoadingMoreSessions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: oledNotifier.value ? null : BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.22, 0.72, 1.0],
            colors: [
              cs.primary.withValues(alpha: 0.06),
              cs.surface,
              Color.lerp(cs.surface, Theme.of(context).scaffoldBackgroundColor, 0.55) ?? Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onSurface.withValues(alpha: 0.24)))
              : _stats == null
                  ? _errorState(tt, cs, l)
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _isLoading = true);
                        await _loadStats();
                      },
                      color: cs.primary,
                      backgroundColor: cs.surfaceContainerHigh,
                      child: AnimatedBuilder(
                        animation: _animValue,
                        builder: (_, __) => _buildContent(cs, tt, l),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _errorState(TextTheme tt, ColorScheme cs, AppLocalizations l) {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.signal_wifi_off_rounded,
          size: 48, color: cs.onSurface.withValues(alpha: 0.15)),
      const SizedBox(height: 12),
      Text(l.statsCouldNotLoad,
          style: tt.bodyMedium
              ?.copyWith(color: cs.onSurface.withValues(alpha: 0.38))),
      const SizedBox(height: 8),
      TextButton(
          onPressed: () {
            setState(() => _isLoading = true);
            _loadStats();
          },
          child: Text(l.retry)),
    ]));
  }

  Widget _buildContent(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final totalSeconds = _safeNum(_stats!['totalTime']);
    final dailyMap = _extractDailyMap(_stats!);
    final today = _todaySeconds(dailyMap);
    final thisWeek = _weekSeconds(dailyMap);
    final thisMonth = _monthSeconds(dailyMap);
    final streak = _currentStreak(dailyMap);
    final longestStreak = _longestStreak(dailyMap);
    final weekData = _last7Days(dailyMap);
    final activeDays = _activeDayCount(dailyMap);
    final avgDaily = _averageDailySeconds(dailyMap);
    final topItems = _topItems();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        AbsorbPageHeader(
          title: l.statsTitle,
          padding: const EdgeInsets.only(top: 12),
        ),
        const SizedBox(height: 24),

        // -- Hero stat --
        _heroStat(tt, cs, l, totalSeconds),
        const SizedBox(height: 16),

        // -- Time periods --
        Row(children: [
          Expanded(child: _periodCard(tt, cs, l.statsToday, today)),
          const SizedBox(width: 8),
          Expanded(child: _periodCard(tt, cs, l.statsThisWeek, thisWeek)),
          const SizedBox(width: 8),
          Expanded(child: _periodCard(tt, cs, l.statsThisMonth, thisMonth)),
        ]),
        const SizedBox(height: 24),

        // -- Activity stats --
        _sectionTitle(tt, cs, l.statsActivity),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _accentStatCard(
                  tt,
                  cs,
                  Icons.local_fire_department_rounded,
                  Colors.orange,
                  l.statsScreenStreakDays(streak),
                  l.statsCurrentStreak)),
          const SizedBox(width: 8),
          Expanded(
              child: _accentStatCard(tt, cs, Icons.emoji_events_rounded,
                  Colors.amber.shade600, l.statsScreenStreakDays(longestStreak), l.statsBestStreak)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _accentStatCard(tt, cs, Icons.menu_book_rounded,
                  Colors.green, '$_booksFinished', l.statsBooksFinished)),
          if (_episodesFinished > 0) ...[
            const SizedBox(width: 8),
            Expanded(
                child: _accentStatCard(tt, cs, Icons.podcasts_rounded,
                    Colors.purple, '$_episodesFinished', l.statsEpisodesFinished)),
          ],
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _accentStatCard(tt, cs, Icons.auto_stories_rounded,
                  Colors.teal, '$_booksFinishedThisYear', l.statsBooksThisYear,
                  onTap: _booksFinishedThisYear > 0
                      ? () => showFinishedBooksThisYearSheet(context)
                      : null)),
          if (_episodesFinishedThisYear > 0) ...[
            const SizedBox(width: 8),
            Expanded(
                child: _accentStatCard(tt, cs, Icons.graphic_eq_rounded,
                    Colors.deepPurple, '$_episodesFinishedThisYear',
                    l.statsEpisodesThisYear)),
          ],
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _accentStatCard(tt, cs, Icons.calendar_today_rounded,
                  cs.primary, '$activeDays', l.statsDaysActive)),
          const SizedBox(width: 8),
          Expanded(
              child: _accentStatCard(tt, cs, Icons.speed_rounded, cs.tertiary,
                  _formatDuration(avgDaily), l.statsDailyAverage)),
        ]),
        const SizedBox(height: 28),

        // -- Last 7 days chart --
        _sectionTitle(tt, cs, l.statsLast7Days),
        const SizedBox(height: 10),
        _barChart(weekData, cs, tt),
        const SizedBox(height: 28),

        // -- Top items --
        if (topItems.isNotEmpty) ...[
          _sectionTitle(tt, cs, l.statsMostListened),
          const SizedBox(height: 10),
          ...topItems.map((item) => _topItemCard(tt, cs, l, item)),
          const SizedBox(height: 28),
        ],

        // -- Recent Sessions --
        if (_sessions.isNotEmpty) ...[
          _sectionTitle(tt, cs, l.statsRecentSessions),
          const SizedBox(height: 10),
          ..._buildSessions(tt, cs, l),
          if (_isLoadingMoreSessions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onSurface.withValues(alpha: 0.24)),
                ),
              ),
            ),
        ],
      ],
    );
  }

  // --- SECTION TITLE ---

  Widget _sectionTitle(TextTheme tt, ColorScheme cs, String title) {
    return Text(title,
        style: tt.titleSmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ));
  }

  // --- HERO STAT ---

  Widget _heroStat(TextTheme tt, ColorScheme cs, AppLocalizations l, double totalSeconds) {
    final hours = (totalSeconds / 3600).floor();
    final minutes = ((totalSeconds % 3600) / 60).floor();
    final anim = _animValue.value;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: oledNotifier.value ? null : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.primary.withValues(alpha: 0.08),
            cs.primary.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: oledNotifier.value ? 0.08 : 0.15)),
      ),
      child: Column(children: [
        Text(l.statsTotalListeningTime,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.35),
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            )),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${(hours * anim).round()}',
                style: tt.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    fontSize: 52,
                    height: 1)),
            const SizedBox(width: 2),
            Text(l.statsHoursUnit,
                style: tt.titleLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w300)),
            const SizedBox(width: 12),
            Text('${(minutes * anim).round()}',
                style: tt.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    fontSize: 52,
                    height: 1)),
            const SizedBox(width: 2),
            Text(l.statsMinutesUnit,
                style: tt.titleLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w300)),
          ],
        ),
        const SizedBox(height: 10),
        Text(_daysEquivalent(totalSeconds, l),
            style: tt.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.25))),
      ]),
    );
  }

  String _daysEquivalent(double seconds, AppLocalizations l) {
    final days = seconds / 86400;
    if (days >= 1) return l.statsDaysOfAudio(days.toStringAsFixed(1));
    final hours = seconds / 3600;
    return l.statsHoursOfAudio(hours.toStringAsFixed(1));
  }

  // --- ACCENT STAT CARD ---

  Widget _accentStatCard(TextTheme tt, ColorScheme cs, IconData icon,
      Color accent, String value, String label,
      {VoidCallback? onTap}) {
    final isTappable = onTap != null;
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: isTappable
            ? accent.withValues(alpha: 0.06)
            : cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isTappable
                ? accent.withValues(alpha: 0.25)
                : cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent.withValues(alpha: 0.8), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: cs.onSurface, height: 1)),
          const SizedBox(height: 2),
          Text(label,
              style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.35), fontSize: 11)),
        ])),
        if (isTappable)
          Icon(Icons.chevron_right_rounded,
              size: 20, color: accent.withValues(alpha: 0.7)),
      ]),
    );
    if (!isTappable) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      ),
    );
  }

  // --- PERIOD CARD ---

  Widget _periodCard(
      TextTheme tt, ColorScheme cs, String label, double seconds) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Text(_formatDuration(seconds),
            style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700, color: cs.onSurface, height: 1)),
        const SizedBox(height: 4),
        Text(label,
            style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35), fontSize: 10)),
      ]),
    );
  }

  // --- BAR CHART (7 days) ---

  Widget _barChart(List<_DayData> data, ColorScheme cs, TextTheme tt) {
    final maxVal =
        data.map((d) => d.seconds).fold(0.0, (a, b) => a > b ? a : b);
    final barMax = maxVal > 0 ? maxVal : 1.0;
    final anim = _animValue.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final ratio = (d.seconds / barMax * anim).clamp(0.0, 1.0);
              final isToday = d.fullLabel == _dateKey(DateTime.now());
              return Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (d.seconds > 0)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(_shortDuration(d.seconds),
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.35),
                                fontSize: 9,
                                fontWeight: FontWeight.w600))),
                  Container(
                    height: max(ratio * 80, d.seconds > 0 ? 4 : 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: isToday
                          ? cs.primary.withValues(alpha: 0.7)
                          : cs.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                ]),
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
            children: data.map((d) {
          final isToday = d.fullLabel == _dateKey(DateTime.now());
          return Expanded(
              child: Text(d.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isToday
                        ? cs.primary.withValues(alpha: 0.8)
                        : cs.onSurface.withValues(alpha: 0.25),
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                  )));
        }).toList()),
      ]),
    );
  }

  // --- TOP ITEMS ---

  List<_TopItem> _topItems() {
    final Map<String, _TopItem> byTitle = {};
    for (final s in _sessions) {
      if (s is! Map<String, dynamic>) continue;
      final rawTitle = s['displayTitle'] as String?;
      final meta = s['mediaMetadata'] as Map<String, dynamic>?;
      final title = (rawTitle != null && !_looksLikeId(rawTitle))
          ? rawTitle
          : meta?['title'] as String? ?? '';
      if (title.isEmpty) continue;
      final rawAuthor = s['displayAuthor'] as String?;
      final author = (rawAuthor != null && !_looksLikeId(rawAuthor))
          ? rawAuthor
          : meta?['authorName'] as String? ?? '';
      final duration = _safeNum(s['timeListening']);
      final existing = byTitle[title];
      if (existing != null) {
        existing.totalSeconds += duration;
        existing.sessionCount++;
      } else {
        byTitle[title] = _TopItem(
            title: title,
            author: author,
            totalSeconds: duration,
            sessionCount: 1);
      }
    }
    final items = byTitle.values.toList()
      ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));
    return items.take(5).toList();
  }

  Widget _topItemCard(TextTheme tt, ColorScheme cs, AppLocalizations l, _TopItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
        ),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600)),
                if (item.author.isNotEmpty)
                  Text(item.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.3),
                          fontSize: 10)),
              ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_formatDuration(item.totalSeconds),
                style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700)),
            Text(
                item.sessionCount == 1
                    ? l.statsScreenSessionCountOne(item.sessionCount)
                    : l.statsScreenSessionCountOther(item.sessionCount),
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.2), fontSize: 9)),
          ]),
        ]),
      ),
    );
  }

  // --- SESSIONS ---

  List<Widget> _buildSessions(TextTheme tt, ColorScheme cs, AppLocalizations l) {
    return _sessions.map((s) {
      if (s is! Map<String, dynamic>) return const SizedBox.shrink();
      final rawTitle = s['displayTitle'] as String?;
      final rawAuthor = s['displayAuthor'] as String?;
      final meta = s['mediaMetadata'] as Map<String, dynamic>?;
      final title = (rawTitle != null && !_looksLikeId(rawTitle))
          ? rawTitle
          : meta?['title'] as String? ?? l.unknown;
      final author = (rawAuthor != null && !_looksLikeId(rawAuthor))
          ? rawAuthor
          : meta?['authorName'] as String? ?? '';
      final duration = _safeNum(s['timeListening']);
      final updatedAt = s['updatedAt'] is num
          ? DateTime.fromMillisecondsSinceEpoch((s['updatedAt'] as num).toInt())
          : null;

      final deviceInfo = s['deviceInfo'] as Map<String, dynamic>? ?? {};
      final clientName = deviceInfo['clientName'] as String? ??
          deviceInfo['deviceName'] as String? ??
          '';
      final isAbsorb = clientName.toLowerCase().contains('absorb');

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSessionDetails(s),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isAbsorb ? Colors.tealAccent : cs.onSurfaceVariant)
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: isAbsorb
                    ? AbsorbWaveIcon(
                        size: 18,
                        color: Colors.tealAccent.withValues(alpha: 0.9))
                    : Icon(_clientIcon(clientName),
                        size: 17,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.85)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (author.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 12)),
                  ],
                ])),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_formatDuration(duration),
                  style: tt.labelMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              if (updatedAt != null) ...[
                const SizedBox(height: 2),
                Text(_relativeDate(updatedAt),
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 11)),
              ],
            ]),
          ]),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showSessionDetails(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionDetailsSheet(session: s),
    );
  }

  IconData _clientIcon(String clientName) {
    final lower = clientName.toLowerCase();
    if (lower.contains('audiobookshelf') || lower.contains('abs'))
      return Icons.headphones_rounded;
    if (lower.contains('web') || lower.contains('browser'))
      return Icons.language_rounded;
    if (lower.contains('ios') || lower.contains('apple'))
      return Icons.phone_iphone_rounded;
    if (lower.contains('android')) return Icons.phone_android_rounded;
    if (lower.contains('sonos') || lower.contains('cast'))
      return Icons.speaker_rounded;
    return Icons.devices_rounded;
  }

  // --- HELPERS ---

  static double _safeNum(dynamic val) => val is num ? val.toDouble() : 0;

  static final _idPattern = RegExp(
    r'^([a-z]{2,4}_)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static bool _looksLikeId(String v) => _idPattern.hasMatch(v);

  Map<String, dynamic> _extractDailyMap(Map<String, dynamic> stats) {
    for (final key in ['dayListeningMap', 'days']) {
      final val = stats[key];
      if (val is Map<String, dynamic>) return val;
    }
    return {};
  }

  double _todaySeconds(Map<String, dynamic> dailyMap) =>
      _daySeconds(dailyMap, _dateKey(DateTime.now()));

  double _weekSeconds(Map<String, dynamic> dailyMap) {
    final now = DateTime.now();
    double total = 0;
    for (int i = 0; i < 7; i++) {
      total += _daySeconds(dailyMap, _dateKey(now.subtract(Duration(days: i))));
    }
    return total;
  }

  double _monthSeconds(Map<String, dynamic> dailyMap) {
    final now = DateTime.now();
    double total = 0;
    for (int i = 0; i < 30; i++) {
      total += _daySeconds(dailyMap, _dateKey(now.subtract(Duration(days: i))));
    }
    return total;
  }

  double _daySeconds(Map<String, dynamic> map, String key) {
    final val = map[key];
    if (val is num) return val.toDouble();
    if (val is Map) {
      final t = _safeNum(val['timeListening']);
      return t > 0 ? t : _safeNum(val['totalTime']);
    }
    return 0;
  }

  int _currentStreak(Map<String, dynamic> dailyMap) {
    int streak = 0;
    final now = DateTime.now();
    int startOffset = _daySeconds(dailyMap, _dateKey(now)) > 0 ? 0 : 1;
    for (int i = startOffset; i < 365; i++) {
      if (_daySeconds(dailyMap, _dateKey(now.subtract(Duration(days: i)))) >
          0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _longestStreak(Map<String, dynamic> dailyMap) {
    int longest = 0, current = 0;
    final keys = dailyMap.keys.toList()..sort();
    DateTime? lastDate;
    for (final key in keys) {
      if (_daySeconds(dailyMap, key) <= 0) continue;
      final date = DateTime.tryParse(key);
      if (date == null) continue;
      if (lastDate != null && date.difference(lastDate).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      longest = max(longest, current);
      lastDate = date;
    }
    return longest;
  }

  int _activeDayCount(Map<String, dynamic> dailyMap) {
    int count = 0;
    for (final key in dailyMap.keys) {
      if (_daySeconds(dailyMap, key) > 0) count++;
    }
    return count;
  }

  double _averageDailySeconds(Map<String, dynamic> dailyMap) {
    // Average over the last 30 days
    final now = DateTime.now();
    double total = 0;
    int daysWithData = 0;
    for (int i = 0; i < 30; i++) {
      final s =
          _daySeconds(dailyMap, _dateKey(now.subtract(Duration(days: i))));
      if (s > 0) {
        total += s;
        daysWithData++;
      }
    }
    return daysWithData > 0 ? total / daysWithData : 0;
  }

  List<_DayData> _last7Days(Map<String, dynamic> dailyMap) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return _DayData(
        label: _dayLabel(date, l),
        fullLabel: _dateKey(date),
        seconds: _daySeconds(dailyMap, _dateKey(date)),
      );
    });
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dayLabel(DateTime d, AppLocalizations l) {
    switch (d.weekday) {
      case 1: return l.statsScreenDayMon;
      case 2: return l.statsScreenDayTue;
      case 3: return l.statsScreenDayWed;
      case 4: return l.statsScreenDayThu;
      case 5: return l.statsScreenDayFri;
      case 6: return l.statsScreenDaySat;
      case 7: return l.statsScreenDaySun;
    }
    return '';
  }

  String _formatDuration(double seconds) {
    final l = AppLocalizations.of(context)!;
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (h > 0) return l.statsScreenDurationHm(h, m);
    if (m > 0) return l.statsScreenDurationM(m);
    if (seconds > 0) return l.statsScreenDurationLessThanMin;
    return l.statsScreenDurationZero;
  }

  String _shortDuration(double seconds) {
    final l = AppLocalizations.of(context)!;
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (h > 0) return l.statsScreenDurationShortH(h);
    return l.statsScreenDurationShortM(m);
  }

  String _relativeDate(DateTime date) {
    final l = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.daysAgo(diff.inDays);
    return '${date.month}/${date.day}';
  }
}

class _DayData {
  final String label;
  final String fullLabel;
  final double seconds;
  const _DayData(
      {required this.label, required this.fullLabel, required this.seconds});
}

class _TopItem {
  final String title;
  final String author;
  double totalSeconds;
  int sessionCount;
  _TopItem(
      {required this.title,
      required this.author,
      required this.totalSeconds,
      required this.sessionCount});
}

class _SessionDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> session;
  const _SessionDetailsSheet({required this.session});

  @override
  State<_SessionDetailsSheet> createState() => _SessionDetailsSheetState();
}

class _SessionDetailsSheetState extends State<_SessionDetailsSheet> {
  bool _jumping = false;

  static double _n(dynamic v) => v is num ? v.toDouble() : 0;

  String _fmtPos(double seconds) {
    final s = seconds.round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _fmtDuration(double seconds, AppLocalizations l) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (h > 0) return l.statsScreenDurationHm(h, m);
    if (m > 0) return l.statsScreenDurationM(m);
    if (seconds > 0) return l.statsScreenDurationLessThanMin;
    return l.statsScreenDurationZero;
  }

  String _fmtDate(int ms, AppLocalizations l) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final monthName = _monthShort(d.month, l);
    final hour12 = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour >= 12 ? l.statsScreenPmLabel : l.statsScreenAmLabel;
    final min = d.minute.toString().padLeft(2, '0');
    return l.statsScreenDateAtTime(monthName, d.day, d.year, hour12, min, ampm);
  }

  String _monthShort(int m, AppLocalizations l) {
    switch (m) {
      case 1: return l.statsScreenMonthJan;
      case 2: return l.statsScreenMonthFeb;
      case 3: return l.statsScreenMonthMar;
      case 4: return l.statsScreenMonthApr;
      case 5: return l.statsScreenMonthMay;
      case 6: return l.statsScreenMonthJun;
      case 7: return l.statsScreenMonthJul;
      case 8: return l.statsScreenMonthAug;
      case 9: return l.statsScreenMonthSep;
      case 10: return l.statsScreenMonthOct;
      case 11: return l.statsScreenMonthNov;
      case 12: return l.statsScreenMonthDec;
    }
    return '';
  }

  Future<void> _jumpToStart() async {
    if (_jumping) return;
    final s = widget.session;
    final itemId = s['libraryItemId'] as String?;
    if (itemId == null) return;
    final episodeId = s['episodeId'] as String?;
    final startTime = _n(s['startTime']);

    setState(() => _jumping = true);

    final lib = context.read<LibraryProvider>();
    final api = context.read<AuthProvider>().apiService;
    final player = AudioPlayerService();

    if (player.currentItemId == itemId &&
        player.currentEpisodeId == episodeId) {
      await player.seekTo(Duration(seconds: startTime.round()));
      if (!player.isPlaying) player.play();
      if (mounted) Navigator.pop(context);
      AppShell.goToAbsorbingGlobal();
      return;
    }

    if (api == null) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        setState(() => _jumping = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.bookmarksNotConnected),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    // Switch library selection if session is from a different library.
    // selectLibrary stops playback itself, so call it BEFORE playItem.
    final sessionLibraryId = s['libraryId'] as String?;
    if (sessionLibraryId != null &&
        sessionLibraryId != lib.selectedLibraryId) {
      await lib.selectLibrary(sessionLibraryId);
    }

    final fullItem = await api.getLibraryItem(itemId);
    if (fullItem == null) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        setState(() => _jumping = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.statsScreenCouldNotLoadItem),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    final media = fullItem['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final coverUrl = lib.getCoverUrl(itemId);

    String title;
    String author;
    double duration;
    List<dynamic> chapters;
    String? episodeTitle;

    if (episodeId != null) {
      final episodes = (media['episodes'] as List<dynamic>?) ?? [];
      final episode = episodes.firstWhere(
        (e) => e is Map<String, dynamic> && e['id'] == episodeId,
        orElse: () => null,
      );
      if (episode is! Map<String, dynamic>) {
        if (mounted) {
          final l = AppLocalizations.of(context)!;
          setState(() => _jumping = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.statsScreenCouldNotFindEpisode),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      episodeTitle = episode['title'] as String? ?? '';
      title = episodeTitle;
      author = metadata['title'] as String? ??
          metadata['author'] as String? ??
          '';
      duration = (episode['duration'] is num)
          ? (episode['duration'] as num).toDouble()
          : 0.0;
      chapters = (episode['chapters'] as List<dynamic>?) ?? [];
    } else {
      title = metadata['title'] as String? ?? '';
      author = metadata['authorName'] as String? ?? '';
      duration = (media['duration'] is num)
          ? (media['duration'] as num).toDouble()
          : 0.0;
      chapters = (media['chapters'] as List<dynamic>?) ?? [];
    }

    final error = await player.playItem(
      api: api,
      itemId: itemId,
      title: title,
      author: author,
      coverUrl: coverUrl,
      totalDuration: duration,
      chapters: chapters,
      startTime: startTime,
      forceStartTime: true,
      episodeId: episodeId,
      episodeTitle: episodeTitle,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _jumping = false);
      showErrorSnackBar(context, error);
      return;
    }
    Navigator.pop(context);
    AppShell.goToAbsorbingGlobal();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final s = widget.session;

    final meta = s['mediaMetadata'] as Map<String, dynamic>? ?? {};
    final rawTitle = s['displayTitle'] as String?;
    final rawAuthor = s['displayAuthor'] as String?;
    final idPattern = RegExp(
      r'^([a-z]{2,4}_)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    bool looksLikeId(String v) => idPattern.hasMatch(v);
    final title = (rawTitle != null && !looksLikeId(rawTitle))
        ? rawTitle
        : meta['title'] as String? ?? l.unknown;
    final author = (rawAuthor != null && !looksLikeId(rawAuthor))
        ? rawAuthor
        : meta['authorName'] as String? ?? '';
    final narrator = meta['narratorName'] as String? ?? '';
    final subtitle = meta['subtitle'] as String? ?? '';

    final itemId = s['libraryItemId'] as String?;
    final timeListening = _n(s['timeListening']);
    final startTime = _n(s['startTime']);
    final currentTime = _n(s['currentTime']);
    final totalDuration = _n(s['duration']);

    final deviceInfo = s['deviceInfo'] as Map<String, dynamic>? ?? {};
    final clientName = deviceInfo['clientName'] as String? ?? '';
    final clientVersion = deviceInfo['clientVersion'] as String? ?? '';
    final deviceModel = deviceInfo['model'] as String? ??
        deviceInfo['manufacturer'] as String? ??
        deviceInfo['deviceName'] as String? ??
        '';
    final osName = deviceInfo['osName'] as String? ?? '';
    final osVersion = deviceInfo['osVersion'] as String? ?? '';
    final playMethod = s['playMethod'];
    final startedAt = s['startedAt'];
    final updatedAt = s['updatedAt'];

    final lib = context.read<LibraryProvider>();
    final coverUrl = itemId != null ? lib.getCoverUrl(itemId) : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 88,
                        height: 88,
                        color: cs.onSurface.withValues(alpha: 0.06),
                        child: coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: coverUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(
                                    Icons.menu_book_rounded,
                                    color: cs.onSurface.withValues(alpha: 0.3)),
                              )
                            : Icon(Icons.menu_book_rounded,
                                color: cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface)),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.7))),
                          ],
                          if (author.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(l.statsScreenByAuthor(author),
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.6))),
                          ],
                          if (narrator.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(l.narratedBy(narrator),
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.5))),
                          ],
                        ])),
                  ]),
                  const SizedBox(height: 20),
                  _infoRow(cs, tt, l.statsScreenListened, _fmtDuration(timeListening, l)),
                  _infoRow(cs, tt, l.statsScreenStartedAtPosition, _fmtPos(startTime)),
                  _infoRow(cs, tt, l.statsScreenEndedAtPosition, _fmtPos(currentTime)),
                  if (totalDuration > 0)
                    _infoRow(cs, tt, l.statsScreenTotalDuration,
                        _fmtPos(totalDuration)),
                  const SizedBox(height: 16),
                  if (startedAt is num)
                    _infoRow(cs, tt, l.statsScreenStarted, _fmtDate(startedAt.toInt(), l)),
                  if (updatedAt is num)
                    _infoRow(cs, tt, l.statsScreenUpdated, _fmtDate(updatedAt.toInt(), l)),
                  const SizedBox(height: 16),
                  if (clientName.isNotEmpty)
                    _infoRow(
                        cs,
                        tt,
                        l.statsScreenClient,
                        clientVersion.isNotEmpty
                            ? '$clientName $clientVersion'
                            : clientName),
                  if (deviceModel.isNotEmpty)
                    _infoRow(cs, tt, l.statsScreenDevice, deviceModel),
                  if (osName.isNotEmpty)
                    _infoRow(
                        cs,
                        tt,
                        l.statsScreenOs,
                        osVersion.isNotEmpty
                            ? '$osName $osVersion'
                            : osName),
                  if (playMethod != null)
                    _infoRow(cs, tt, l.statsScreenPlayMethod,
                        _playMethodLabel(playMethod, l)),
                  const SizedBox(height: 24),
                  if (itemId != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _jumping ? null : _jumpToStart,
                        icon: _jumping
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Icon(Icons.replay_rounded),
                        label: Text(_jumping
                            ? l.statsScreenLoading
                            : l.statsScreenJumpToSessionStart(_fmtPos(startTime))),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _infoRow(ColorScheme cs, TextTheme tt, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55)))),
        Text(value,
            style: tt.bodyMedium?.copyWith(
                color: cs.onSurface, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _playMethodLabel(dynamic m, AppLocalizations l) {
    final i = m is num ? m.toInt() : -1;
    switch (i) {
      case 0:
        return l.statsScreenPlayMethodDirect;
      case 1:
        return l.statsScreenPlayMethodDirectStream;
      case 2:
        return l.statsScreenPlayMethodTranscode;
      case 3:
        return l.statsScreenPlayMethodLocal;
      default:
        return m.toString();
    }
  }
}
