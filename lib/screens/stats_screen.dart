import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/scoped_prefs.dart';
import '../services/user_account_service.dart';
import '../utils/app_platform.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/finished_books_this_year_sheet.dart';
import '../widgets/stats_charts.dart';
import '../widgets/day_sessions_sheet.dart';
import '../widgets/listening_session_card.dart';
import '../widgets/overlay_toast.dart';
import '../main.dart' show flatNotifier, gradientIntensityNotifier;
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
  String _goalType = 'off';
  int _goalMinutes = 30;
  int _bookGoal = 0;
  String _chartStyle = 'bar';
  int _chartRange = 7;
  List<String> _statsOrder = [];
  Set<String> _statsHidden = {};
  String? _selectedDayKey;
  // Which section owns the current day selection ('chart' or 'heatmap') so the
  // detail card only shows under the one that was tapped.
  String? _selectedSection;
  double _selectedDaySeconds = 0;
  double _timeSavedSeconds = 0;
  DateTime? _timeSavedSince;
  int _yirYear = DateTime.now().year;
  Map<String, dynamic>? _yirData;
  bool _yirLoading = false;
  int? _yirLoadedYear;
  late AnimationController _animController;

  // Recent sessions stays out of the reorderable sections: it loads more as
  // you scroll, so anything placed under it would never be reachable.
  static const _defaultSectionOrder = [
    'hero', 'goals', 'periods', 'activity', 'chart', 'heatmap', 'dayofweek', 'top', 'yearreview',
  ];

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
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
    PlayerSettings.settingsChanged.addListener(_onSettingsChanged);
    _loadStats();
    _loadGoalSettings();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    PlayerSettings.settingsChanged.removeListener(_onSettingsChanged);
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

  void _onSettingsChanged() => _loadGoalSettings();

  Future<void> _loadGoalSettings() async {
    final type = await PlayerSettings.getStatsGoalType();
    final minutes = await PlayerSettings.getStatsGoalMinutes();
    final books = await PlayerSettings.getStatsBookGoal();
    final chartStyle = await PlayerSettings.getStatsChartStyle();
    final chartRange = await PlayerSettings.getStatsChartRange();
    final order = await PlayerSettings.getStatsSectionOrder();
    final hidden = await PlayerSettings.getStatsHiddenSections();
    final timeSaved = await PlayerSettings.getStatsTimeSaved();
    final timeSavedSince = await PlayerSettings.getStatsTimeSavedSince();
    if (!mounted) return;
    setState(() {
      if (chartStyle != _chartStyle || chartRange != _chartRange) {
        _selectedDayKey = null;
        _selectedSection = null;
      }
      _goalType = type;
      _goalMinutes = minutes;
      _bookGoal = books;
      _chartStyle = chartStyle;
      _chartRange = chartRange;
      _statsOrder = order;
      _statsHidden = hidden.toSet();
      _timeSavedSeconds = timeSaved;
      _timeSavedSince = timeSavedSince;
    });
  }

  Future<void> _loadYearReview(int year) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() {
      _yirYear = year;
      _yirLoading = true;
    });
    final data = await api.getMyYearStats(year);
    if (!mounted) return;
    setState(() {
      _yirData = data;
      _yirLoadedYear = year;
      _yirLoading = false;
    });
  }

  void _selectDay(String section, String key, double seconds) {
    setState(() {
      if (_selectedSection == section && _selectedDayKey == key) {
        _selectedSection = null;
        _selectedDayKey = null;
      } else {
        _selectedSection = section;
        _selectedDayKey = key;
        _selectedDaySeconds = seconds;
      }
    });
  }

  /// Detail card for the tapped day, scoped to [section] so it only appears
  /// under the chart or the heatmap — whichever was tapped. Animates in/out.
  Widget _dayDetailSlot(ColorScheme cs, TextTheme tt, String section) {
    final show = _selectedSection == section && _selectedDayKey != null;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: show
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _dayDetailCard(cs, tt),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  Widget _dayDetailCard(ColorScheme cs, TextTheme tt) {
    final parts = _selectedDayKey!.split('-');
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final l = AppLocalizations.of(context)!;
    final dateLabel = '${_dayLabel(date, l)}, ${months[date.month - 1]} ${date.day}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Expanded(
          child: InkWell(
            onTap: () => _showDaySessions(date),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateLabel,
                          style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(_formatDuration(_selectedDaySeconds),
                          style: tt.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        l.statsViewSessions,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => setState(() {
            _selectedSection = null;
            _selectedDayKey = null;
          }),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close_rounded,
                size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
          ),
        ),
      ]),
    );
  }

  static const _kStats = 'cached_stats';
  static const _kSessions = 'cached_sessions';

  Future<void> _loadStats() async {
    final accountScope = UserAccountService().activeScopeKey;
    bool isActiveAccount() =>
        UserAccountService().activeScopeKey == accountScope;
    final api = context.read<AuthProvider>().apiService;
    final lib = context.read<LibraryProvider>();
    final prefs = await SharedPreferences.getInstance();
    final statsCacheKey = ScopedPrefs.keyForScope(accountScope, _kStats);
    final sessionsCacheKey = ScopedPrefs.keyForScope(accountScope, _kSessions);

    // The saved-by-speed counter banks while listening, so re-read it on
    // every load (incl. pull-to-refresh), not just at screen creation.
    final timeSaved = await PlayerSettings.getStatsTimeSaved();
    final timeSavedSince = await PlayerSettings.getStatsTimeSavedSince();
    if (!isActiveAccount()) return;
    if (mounted && (timeSaved != _timeSavedSeconds || timeSavedSince != _timeSavedSince)) {
      setState(() {
        _timeSavedSeconds = timeSaved;
        _timeSavedSince = timeSavedSince;
      });
    }

    // Load cached data first so the page renders immediately even offline.
    if (_isLoading) {
      final cachedStats = prefs.getString(statsCacheKey);
      final cachedSessions = prefs.getString(sessionsCacheKey);
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
    if (!mounted || !isActiveAccount()) return;
    final finishedBooks = lib.finishedBooksCount;
    final finishedEpisodes = lib.finishedEpisodesCount;
    final finishedBooksYear = lib.finishedBooksThisYearCount;
    final finishedEpisodesYear = lib.finishedEpisodesThisYearCount;

    if (stats != null) {
      prefs.setString(statsCacheKey, jsonEncode(stats));
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
    if (!mounted || !isActiveAccount()) return;
    final sessions = sessionsData?['sessions'] as List<dynamic>? ?? [];
    if (sessions.isNotEmpty) {
      prefs.setString(sessionsCacheKey, jsonEncode(sessions));
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
        decoration: flatNotifier.value ? null : BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.22, 0.72, 1.0],
            colors: [
              cs.primary.withValues(alpha: gradientIntensityNotifier.value),
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
    final chartData = _lastNDays(dailyMap, _chartRange);
    final activeDays = _activeDayCount(dailyMap);
    final avgDaily = _averageDailySeconds(dailyMap);
    final topItems = _topItems();

    if (!_statsHidden.contains('yearreview') &&
        _yirLoadedYear != _yirYear &&
        !_yirLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadYearReview(_yirYear);
      });
    }

    final sections = <String, List<Widget>>{
      'hero': [
        _heroStat(tt, cs, l, totalSeconds),
        const SizedBox(height: 16),
      ],
      'goals': [
        if (_goalType != 'off' || _bookGoal > 0) ...[
          _goalCard(cs, tt, l, today, thisWeek, thisMonth),
          const SizedBox(height: 16),
        ],
      ],
      'periods': [
        Row(children: [
          Expanded(child: _periodCard(tt, cs, l.statsToday, today)),
          const SizedBox(width: 8),
          Expanded(child: _periodCard(tt, cs, l.statsThisWeek, thisWeek)),
          const SizedBox(width: 8),
          Expanded(child: _periodCard(tt, cs, l.statsThisMonth, thisMonth)),
        ]),
        const SizedBox(height: 24),
      ],
      'activity': [
        _sectionTitle(tt, cs, l.statsActivity),
        const SizedBox(height: 10),
        _responsiveStatsGrid([
          _accentStatCard(
              tt,
              cs,
              Icons.local_fire_department_rounded,
              Colors.orange,
              l.statsScreenStreakDays(streak),
              l.statsCurrentStreak),
          _accentStatCard(tt, cs, Icons.emoji_events_rounded,
              Colors.amber.shade600, l.statsScreenStreakDays(longestStreak), l.statsBestStreak),
          _accentStatCard(tt, cs, Icons.menu_book_rounded,
              Colors.green, '$_booksFinished', l.statsBooksFinished),
          if (_episodesFinished > 0)
            _accentStatCard(tt, cs, Icons.podcasts_rounded,
                Colors.purple, '$_episodesFinished', l.statsEpisodesFinished),
          _accentStatCard(tt, cs, Icons.auto_stories_rounded,
              Colors.teal, '$_booksFinishedThisYear', l.statsBooksThisYear,
              onTap: _booksFinishedThisYear > 0
                  ? () async {
                      await showFinishedBooksThisYearSheet(context);
                      if (mounted) {
                        setState(() => _booksFinishedThisYear = context
                            .read<LibraryProvider>()
                            .finishedBooksThisYearCount);
                      }
                    }
                  : null),
          if (_episodesFinishedThisYear > 0)
            _accentStatCard(tt, cs, Icons.graphic_eq_rounded,
                Colors.deepPurple, '$_episodesFinishedThisYear',
                l.statsEpisodesThisYear),
          _accentStatCard(tt, cs, Icons.calendar_today_rounded,
              cs.primary, '$activeDays', l.statsDaysActive),
          _accentStatCard(tt, cs, Icons.speed_rounded, cs.tertiary,
              _formatDuration(avgDaily), l.statsDailyAverage),
          if (_timeSavedSeconds >= 60)
            _accentStatCard(tt, cs, Icons.fast_forward_rounded,
                Colors.cyan, _formatDuration(_timeSavedSeconds),
                l.statsTimeSavedLabel,
                subtitle: _timeSavedSince != null
                    ? l.statsTimeSavedSince(
                        MaterialLocalizations.of(context).formatMediumDate(_timeSavedSince!))
                    : null,
                trailing: IconButton(
                  icon: Icon(Icons.restart_alt_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                  tooltip: l.statsTimeSavedReset,
                  onPressed: _confirmResetTimeSaved,
                )),
        ]),
        const SizedBox(height: 28),
      ],
      'chart': [
        _sectionTitle(tt, cs,
            _chartRange == 30 ? l.statsLast30Days : l.statsLast7Days),
        const SizedBox(height: 10),
        _chartCard(cs, tt, chartData),
        _dayDetailSlot(cs, tt, 'chart'),
        const SizedBox(height: 28),
      ],
      'heatmap': [
        _sectionTitle(tt, cs, l.statsThisYearTitle),
        const SizedBox(height: 10),
        _heatmapCard(cs, l, _cardDeco(cs), dailyMap),
        _dayDetailSlot(cs, tt, 'heatmap'),
        const SizedBox(height: 28),
      ],
      'dayofweek': [
        _sectionTitle(tt, cs, l.statsDayOfWeek),
        const SizedBox(height: 10),
        _dayOfWeekChart(cs, tt, l, dailyMap),
        const SizedBox(height: 28),
      ],
      'top': [
        if (topItems.isNotEmpty) ...[
          _sectionTitle(tt, cs, l.statsMostListened),
          const SizedBox(height: 10),
          _responsiveTwoColumnList(
            topItems.map((item) => _topItemCard(tt, cs, l, item)).toList(),
          ),
          const SizedBox(height: 28),
        ],
      ],
      'yearreview': _yearReviewSection(cs, tt),
    };

    final order = [
      ..._statsOrder.where(sections.containsKey),
      ..._defaultSectionOrder.where((id) => !_statsOrder.contains(id)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isDesktopWorkspace =
            AppPlatform.isWeb && constraints.maxWidth >= 960;
        final horizontalPadding = isWide ? 32.0 : 20.0;
        return ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              horizontalPadding, 0, horizontalPadding, 32),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AbsorbPageHeader(
                      title: l.statsTitle,
                      showBranding: !isDesktopWorkspace,
                      padding: EdgeInsets.only(top: isWide ? 24 : 12),
                    ),
                    const SizedBox(height: 24),
                    for (final id in order)
                      if (!_statsHidden.contains(id)) ...sections[id]!,
                    if (_sessions.isNotEmpty) ...[
                      _sectionTitle(tt, cs, l.statsRecentSessions),
                      const SizedBox(height: 10),
                      _responsiveTwoColumnList(_buildSessions()),
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _responsiveStatsGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 4
            : constraints.maxWidth >= 900
                ? 3
                : 2;
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _responsiveTwoColumnList(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(children: cards);
        }
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  /// Shared card background used by the line chart and the heatmap.
  BoxDecoration _cardDeco(ColorScheme cs) => BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      );

  Widget _chartCard(ColorScheme cs, TextTheme tt, List<_DayData> chartData) {
    if (_chartStyle == 'line') {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        decoration: _cardDeco(cs),
        child: StatsLineChart(
          data: chartData
              .map((d) => ChartDay(label: d.label, dateKey: d.fullLabel, seconds: d.seconds))
              .toList(),
          todayKey: _dateKey(DateTime.now()),
          animValue: _animValue.value,
          lineColor: cs.primary,
          labelColor: cs.onSurface,
          todayColor: cs.primary,
          formatValue: _shortDuration,
          selectedIndex: _selectedSection == 'chart'
              ? chartData.indexWhere((d) => d.fullLabel == _selectedDayKey)
              : -1,
          onDaySelected: (i) => _selectDay('chart', chartData[i].fullLabel, chartData[i].seconds),
        ),
      );
    }
    return _barChart(chartData, cs, tt, dense: _chartRange > 10);
  }

  /// Average listening per weekday (across days that had any listening),
  /// today's weekday highlighted. Averages instead of totals so a year of
  /// Saturdays doesn't read like one monster day.
  Widget _dayOfWeekChart(ColorScheme cs, TextTheme tt, AppLocalizations l,
      Map<String, dynamic> dailyMap) {
    final labels = [
      l.statsScreenDayMon,
      l.statsScreenDayTue,
      l.statsScreenDayWed,
      l.statsScreenDayThu,
      l.statsScreenDayFri,
      l.statsScreenDaySat,
      l.statsScreenDaySun,
    ];
    final sums = List.filled(7, 0.0);
    final counts = List.filled(7, 0);
    for (final e in dailyMap.entries) {
      final d = DateTime.tryParse(e.key);
      if (d == null) continue;
      final v = _safeNum(e.value);
      if (v <= 0) continue;
      sums[d.weekday - 1] += v;
      counts[d.weekday - 1]++;
    }
    final values = [
      for (var i = 0; i < 7; i++) counts[i] > 0 ? sums[i] / counts[i] : 0.0,
    ];
    final maxVal = values.fold(0.0, (a, b) => a > b ? a : b);
    final barMax = maxVal > 0 ? maxVal : 1.0;
    final todayIdx = DateTime.now().weekday - 1;
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
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (values[i] > 0)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(_formatDuration(values[i]),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: cs.onSurface.withValues(alpha: 0.35),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600))),
                        Container(
                          height: max(
                              (values[i] / barMax * anim).clamp(0.0, 1.0) * 72,
                              values[i] > 0 ? 4 : 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: i == todayIdx
                                ? cs.primary.withValues(alpha: 0.7)
                                : cs.onSurface.withValues(alpha: 0.12),
                          ),
                        ),
                      ]),
                )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
                child: Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == todayIdx
                          ? cs.primary.withValues(alpha: 0.8)
                          : cs.onSurface.withValues(alpha: 0.25),
                      fontSize: 10,
                      fontWeight:
                          i == todayIdx ? FontWeight.w600 : FontWeight.w400,
                    ))),
        ]),
      ]),
    );
  }

  Widget _heatmapCard(ColorScheme cs, AppLocalizations l, BoxDecoration deco,
      Map<String, dynamic> dailyMap) {
    final daily = <String, double>{
      for (final e in dailyMap.entries) e.key: _safeNum(e.value),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: deco,
      child: StatsHeatmap(
        dailySeconds: daily,
        fillColor: cs.primary,
        emptyColor: cs.onSurface.withValues(alpha: 0.06),
        labelColor: cs.onSurface,
        lessLabel: l.statsHeatmapLess,
        moreLabel: l.statsHeatmapMore,
        dayLabels: [
          l.statsScreenDayMon,
          l.statsScreenDayTue,
          l.statsScreenDayWed,
          l.statsScreenDayThu,
          l.statsScreenDayFri,
          l.statsScreenDaySat,
          l.statsScreenDaySun,
        ],
        selectedKey: _selectedSection == 'heatmap' ? _selectedDayKey : null,
        onDaySelected: (key, seconds) => _selectDay('heatmap', key, seconds),
      ),
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

  List<Widget> _yearReviewSection(ColorScheme cs, TextTheme tt) {
    final thisYear = DateTime.now().year;
    final years = [for (var y = thisYear; y >= thisYear - 6; y--) y];
    final header = Row(children: [
      Expanded(child: _sectionTitle(tt, cs, 'Year in Review')),
      Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _yirYear,
            isDense: true,
            borderRadius: BorderRadius.circular(12),
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            items: [
              for (final y in years) DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (y) {
              if (y != null && y != _yirYear) _loadYearReview(y);
            },
          ),
        ),
      ),
    ]);

    final body = <Widget>[];
    final d = _yirData;
    // The server reports listening time in seconds (summed timeListening).
    final totalSeconds = (d?['totalListeningTime'] as num?)?.toDouble() ?? 0;
    final sessions = (d?['totalListeningSessions'] as num?)?.toInt() ?? 0;
    final finished = (d?['numBooksFinished'] as num?)?.toInt() ?? 0;
    final listened = (d?['numBooksListened'] as num?)?.toInt() ?? 0;

    if (_yirLoading) {
      body.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (d == null || (totalSeconds <= 0 && sessions == 0 && finished == 0)) {
      body.add(Container(
        width: double.infinity,
        decoration: _cardDeco(cs),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Text('Nothing listened in $_yirYear yet',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ));
    } else {
      final api = context.read<AuthProvider>().apiService;
      final coverIds =
          ((d['booksWithCovers'] as List?) ?? const []).whereType<String>().toList();
      if (api != null && coverIds.isNotEmpty) {
        body.add(SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: coverIds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: api.getCoverUrl(coverIds[i], width: 120),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(width: 64, height: 64, color: cs.surfaceContainerHigh),
              ),
            ),
          ),
        ));
        body.add(const SizedBox(height: 14));
      }

      body.add(Row(children: [
        Expanded(child: _accentStatCard(tt, cs, Icons.headphones_rounded,
            cs.primary, _formatDuration(totalSeconds), 'Listened')),
        const SizedBox(width: 8),
        Expanded(child: _accentStatCard(tt, cs, Icons.menu_book_rounded,
            Colors.green, '$finished', 'Books finished')),
      ]));
      body.add(const SizedBox(height: 8));
      body.add(Row(children: [
        Expanded(child: _accentStatCard(tt, cs, Icons.play_circle_outline_rounded,
            cs.tertiary, '$sessions', 'Sessions')),
        const SizedBox(width: 8),
        Expanded(child: _accentStatCard(tt, cs, Icons.library_books_rounded,
            Colors.teal, '$listened', 'Books listened')),
      ]));
      body.add(const SizedBox(height: 14));

      final highlights = <Widget>[];
      final mm = d['mostListenedMonth'];
      if (mm is Map) {
        final name = _monthName((mm['month'] as num?)?.toInt());
        if (name.isNotEmpty) {
          highlights.add(_yirRow(cs, tt, Icons.calendar_month_rounded, 'Top month', name));
        }
      }
      final mn = d['mostListenedNarrator'];
      if (mn is Map && (mn['name']?.toString().isNotEmpty ?? false)) {
        highlights.add(_yirRow(cs, tt, Icons.record_voice_over_rounded,
            'Top narrator', mn['name'].toString()));
      }
      final lb = d['longestAudiobookFinished'];
      if (lb is Map && (lb['title']?.toString().isNotEmpty ?? false)) {
        highlights.add(_yirRow(cs, tt, Icons.straighten_rounded,
            'Longest finished', lb['title'].toString()));
      }
      if (highlights.isNotEmpty) {
        body.add(Container(
          decoration: _cardDeco(cs),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: highlights),
        ));
        body.add(const SizedBox(height: 14));
      }

      body.add(_yirTopList(cs, tt, 'Top authors', d['topAuthors'], 'name'));
      body.add(_yirTopList(cs, tt, 'Top genres', d['topGenres'], 'genre'));
    }

    return [header, const SizedBox(height: 10), ...body, const SizedBox(height: 28)];
  }

  Widget _yirRow(ColorScheme cs, TextTheme tt, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _yirTopList(ColorScheme cs, TextTheme tt, String title, dynamic raw, String labelKey) {
    final list = (raw as List?)?.whereType<Map>().toList() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(tt, cs, title),
      const SizedBox(height: 8),
      Container(
        decoration: _cardDeco(cs),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: list.map((e) {
            final name = e[labelKey]?.toString() ?? '';
            final secs = (e['time'] as num?)?.toDouble() ?? 0;
            return ListTile(
              dense: true,
              title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
              trailing: Text(_formatDuration(secs),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 14),
    ]);
  }

  String _monthName(int? m) => (m != null && m >= 0 && m < 12) ? _monthNames[m] : '';

  // --- GOAL CARD ---

  Widget _goalCard(ColorScheme cs, TextTheme tt, AppLocalizations l,
      double today, double thisWeek, double thisMonth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doneColor = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;

    final hasTimeGoal = _goalType != 'off';
    final hasBookGoal = _bookGoal > 0;

    final periodSeconds = _goalType == 'weekly'
        ? thisWeek
        : _goalType == 'monthly'
            ? thisMonth
            : today;
    final targetSeconds = _goalMinutes * 60.0;
    final double timeProgress =
        targetSeconds > 0 ? (periodSeconds / targetSeconds).clamp(0.0, 1.0).toDouble() : 0.0;
    final timeReached = hasTimeGoal && periodSeconds >= targetSeconds;
    final goalLabel = _goalType == 'weekly'
        ? l.statsWeeklyGoal
        : _goalType == 'monthly'
            ? l.statsMonthlyGoal
            : l.statsDailyGoal;

    final double bookProgress =
        hasBookGoal ? (_booksFinishedThisYear / _bookGoal).clamp(0.0, 1.0).toDouble() : 0.0;
    final bookReached = hasBookGoal && _booksFinishedThisYear >= _bookGoal;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final daysInYear =
        DateTime(now.year, 12, 31).difference(DateTime(now.year, 1, 1)).inDays + 1;
    final projectedBooks = (_booksFinishedThisYear * daysInYear / dayOfYear).round();
    final onTrack = projectedBooks >= _bookGoal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.onSurface.withValues(alpha: 0.03),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        if (hasTimeGoal)
          Row(children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: timeProgress,
                    strokeWidth: 5,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(timeReached ? doneColor : cs.primary),
                  ),
                ),
                if (timeReached)
                  Icon(Icons.check_rounded, color: doneColor, size: 24)
                else
                  Text('${(timeProgress * 100).round()}%',
                      style: tt.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(goalLabel,
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(
                l.statsGoalProgress(
                    _formatDuration(periodSeconds), _formatDuration(targetSeconds)),
                style: tt.bodySmall
                    ?.copyWith(color: timeReached ? doneColor : cs.onSurfaceVariant),
              ),
            ])),
          ]),
        if (hasTimeGoal && hasBookGoal) const SizedBox(height: 16),
        if (hasBookGoal)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_stories_rounded,
                  size: 16, color: bookReached ? doneColor : cs.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(l.statsBookChallengeTitle,
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface))),
              Text(
                l.statsBookChallengeProgress(_booksFinishedThisYear, _bookGoal),
                style: tt.bodySmall
                    ?.copyWith(color: bookReached ? doneColor : cs.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: bookProgress,
                minHeight: 8,
                backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(bookReached ? doneColor : cs.primary),
              ),
            ),
            if (!bookReached) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(
                    onTrack
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 13,
                    color: onTrack ? doneColor : Colors.orange),
                const SizedBox(width: 4),
                Text(l.statsOnPaceFor(projectedBooks),
                    style: tt.labelSmall?.copyWith(
                        color: onTrack ? doneColor : Colors.orange)),
              ]),
            ],
          ]),
      ]),
    );
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
        gradient: flatNotifier.value ? null : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.primary.withValues(alpha: 0.08),
            cs.primary.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: flatNotifier.value ? 0.08 : 0.15)),
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

  Future<void> _confirmResetTimeSaved() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.statsTimeSavedReset),
        content: Text(l.statsTimeSavedResetConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.reset)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await PlayerSettings.resetStatsTimeSaved();
    if (!mounted) return;
    setState(() {
      _timeSavedSeconds = 0;
      _timeSavedSince = null;
    });
    showOverlayToast(context, l.statsTimeSavedResetDone, icon: Icons.restart_alt_rounded);
  }

  Widget _accentStatCard(TextTheme tt, ColorScheme cs, IconData icon,
      Color accent, String value, String label,
      {VoidCallback? onTap, String? subtitle, Widget? trailing}) {
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: tt.labelSmall?.copyWith(
                    color: accent.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ])),
        if (trailing != null) trailing,
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

  Widget _barChart(List<_DayData> data, ColorScheme cs, TextTheme tt,
      {bool dense = false}) {
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
              final isSelected =
                  _selectedSection == 'chart' && d.fullLabel == _selectedDayKey;
              return Expanded(
                  child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selectDay('chart', d.fullLabel, d.seconds),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: dense ? 1 : 3),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if ((!dense || isSelected) && d.seconds > 0)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(_shortDuration(d.seconds),
                                  style: TextStyle(
                                      color: isSelected
                                          ? cs.primary
                                          : cs.onSurface.withValues(alpha: 0.35),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600))),
                        Container(
                          height: max(ratio * 80, d.seconds > 0 ? 4 : 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(dense ? 2 : 5),
                            color: isSelected
                                ? cs.primary
                                : isToday
                                    ? cs.primary.withValues(alpha: 0.7)
                                    : cs.onSurface.withValues(alpha: 0.12),
                          ),
                        ),
                      ]),
                ),
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < data.length; i++)
            Expanded(
                child: Text(
                    dense ? (i % 5 == 0 ? data[i].label : '') : data[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: data[i].fullLabel == _dateKey(DateTime.now())
                          ? cs.primary.withValues(alpha: 0.8)
                          : cs.onSurface.withValues(alpha: 0.25),
                      fontSize: 10,
                      fontWeight: data[i].fullLabel == _dateKey(DateTime.now())
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ))),
        ]),
      ]),
    );
  }

  // --- TOP ITEMS ---

  List<_TopItem> _topItems() {
    // Prefer the server's all-time per-item totals from /me/listening-stats,
    // which sum every session. The _sessions list below is only the paginated
    // recently-loaded page, so aggregating it under-counts older books and
    // makes "Most listened" look wrong.
    final serverItems = _stats?['items'];
    if (serverItems is Map && serverItems.isNotEmpty) {
      final items = <_TopItem>[];
      for (final v in serverItems.values) {
        if (v is! Map) continue;
        final meta = v['mediaMetadata'] as Map<String, dynamic>?;
        final title = meta?['title'] as String? ?? '';
        if (title.isEmpty) continue;
        items.add(_TopItem(
          title: title,
          author: meta?['authorName'] as String? ?? '',
          totalSeconds: _safeNum(v['timeListening']),
          sessionCount: 0, // server totals don't carry a session count
        ));
      }
      items.sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));
      return items.take(5).toList();
    }

    // Fallback (no stats loaded yet / offline): aggregate whatever sessions
    // are currently loaded.
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
            if (item.sessionCount > 0)
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

  List<Widget> _buildSessions() {
    return _sessions.map((s) {
      if (s is! Map<String, dynamic>) return const SizedBox.shrink();
      return ListeningSessionCard(
        session: s,
        onTap: () => _showSessionDetails(s),
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadSessionsForDay(DateTime day) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return const [];

    const pageSize = 100;
    final target = DateTime(day.year, day.month, day.day);
    final sessions = <Map<String, dynamic>>[];
    var page = 0;

    while (page < 200) {
      final data = await api.getListeningSessions(
        page: page,
        itemsPerPage: pageSize,
      );
      if (data == null) throw StateError('Could not load listening sessions');
      final batch = (data['sessions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (batch.isEmpty) break;

      sessions.addAll(
        batch.where((session) => listeningSessionMatchesDate(session, target)),
      );

      final oldestDay = listeningSessionDateOf(batch.last);
      if (oldestDay != null) {
        final oldest = DateTime(
          oldestDay.year,
          oldestDay.month,
          oldestDay.day,
        );
        if (oldest.isBefore(target)) break;
      }

      final total = (data['total'] as num?)?.toInt();
      if (batch.length < pageSize ||
          (total != null && (page + 1) * pageSize >= total)) {
        break;
      }
      page++;
    }

    sessions.sort((a, b) {
      final aTime = (a['updatedAt'] as num?)?.toInt() ?? 0;
      final bTime = (b['updatedAt'] as num?)?.toInt() ?? 0;
      return bTime.compareTo(aTime);
    });
    return sessions;
  }

  Future<void> _showDaySessions(DateTime day) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DaySessionsSheet(
        initialDate: day,
        loadSessions: _loadSessionsForDay,
        onSessionTap: (session) => _showSessionDetails(
          session,
          refreshStats: false,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _isLoading = true);
      await _loadStats();
    }
  }

  Future<bool> _showSessionDetails(
    Map<String, dynamic> s, {
    bool refreshStats = true,
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionDetailsSheet(session: s),
    );
    if (changed == true && mounted && refreshStats) {
      setState(() => _isLoading = true);
      await _loadStats();
    }
    return changed == true;
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

  List<_DayData> _lastNDays(Map<String, dynamic> dailyMap, int n) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    return List.generate(n, (i) {
      final date = now.subtract(Duration(days: n - 1 - i));
      return _DayData(
        label: n <= 7 ? _dayLabel(date, l) : '${date.day}',
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

class SessionDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> session;
  /// Whether the listened-time / day editor is offered. Hidden when an admin is
  /// viewing another user's session (the only edit path would write to the
  /// admin's own progress).
  final bool allowEdit;
  final VoidCallback? onJumped;
  const SessionDetailsSheet({
    super.key,
    required this.session,
    this.allowEdit = true,
    this.onJumped,
  });

  @override
  State<SessionDetailsSheet> createState() => SessionDetailsSheetState();
}

class SessionDetailsSheetState extends State<SessionDetailsSheet> {
  bool _jumping = false;
  bool _saving = false;

  static double _n(dynamic v) => v is num ? v.toDouble() : 0;

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Edit the fields the server supports for an existing session.
  Future<void> _editSession() async {
    final l = AppLocalizations.of(context)!;
    final s = widget.session;
    final origListening = _n(s['timeListening']).round();
    final origCurrent = _n(s['currentTime']).round();
    final origUpdatedMs = s['updatedAt'] is num
        ? (s['updatedAt'] as num).toInt()
        : DateTime.now().millisecondsSinceEpoch;
    final origUpdated = DateTime.fromMillisecondsSinceEpoch(origUpdatedMs);

    final hoursCtrl =
        TextEditingController(text: '${origListening ~/ 3600}');
    final minutesCtrl =
        TextEditingController(text: '${(origListening % 3600) ~/ 60}');
    final endHoursCtrl = TextEditingController(text: '${origCurrent ~/ 3600}');
    final endMinutesCtrl = TextEditingController(
      text: '${(origCurrent % 3600) ~/ 60}',
    );
    final endSecondsCtrl = TextEditingController(text: '${origCurrent % 60}');
    var day = DateTime(origUpdated.year, origUpdated.month, origUpdated.day);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (dialogCtx, setDialog) {
          return AlertDialog(
            scrollable: true,
            title: Text(l.sessionEditTitle),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.statsScreenListened,
                  style: Theme.of(dialogCtx).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: hoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: l.statsHoursUnit,
                      border: const OutlineInputBorder()),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                  controller: minutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: l.statsMinutesUnit,
                      border: const OutlineInputBorder()),
                )),
              ]),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.sessionEndPosition,
                  style: Theme.of(dialogCtx).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: endHoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l.statsHoursUnit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: endMinutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l.statsMinutesUnit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: endSecondsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l.statsSecondsUnit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                l.sessionEndPositionHint,
                style: Theme.of(dialogCtx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(dialogCtx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Text(l.sessionDayLabel,
                    style: Theme.of(dialogCtx).textTheme.bodyMedium),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text('${day.year}-${_two(day.month)}-${_two(day.day)}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: day,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialog(() => day =
                          DateTime(picked.year, picked.month, picked.day));
                    }
                  },
                ),
              ]),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: Text(l.cancel)),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  child: Text(l.save)),
            ],
          );
        });
      },
    );
    if (saved != true || !mounted) {
      hoursCtrl.dispose();
      minutesCtrl.dispose();
      endHoursCtrl.dispose();
      endMinutesCtrl.dispose();
      endSecondsCtrl.dispose();
      return;
    }

    final h = int.tryParse(hoursCtrl.text.trim()) ?? 0;
    final m = int.tryParse(minutesCtrl.text.trim()) ?? 0;
    final newListening = (h < 0 ? 0 : h) * 3600 + (m < 0 ? 0 : m) * 60;
    final endH = int.tryParse(endHoursCtrl.text.trim()) ?? 0;
    final endM = int.tryParse(endMinutesCtrl.text.trim()) ?? 0;
    final endS = int.tryParse(endSecondsCtrl.text.trim()) ?? 0;
    var newCurrent =
        (endH < 0 ? 0 : endH) * 3600 +
        (endM < 0 ? 0 : endM) * 60 +
        (endS < 0 ? 0 : endS);
    final duration = _n(s['duration']);
    if (duration > 0 && newCurrent > duration) {
      newCurrent = duration.round();
    }
    hoursCtrl.dispose();
    minutesCtrl.dispose();
    endHoursCtrl.dispose();
    endMinutesCtrl.dispose();
    endSecondsCtrl.dispose();
    // Keep the original time-of-day so only the date moves.
    final newUpdated = DateTime(day.year, day.month, day.day, origUpdated.hour,
            origUpdated.minute, origUpdated.second)
        .millisecondsSinceEpoch;

    final api = context.read<AuthProvider>().apiService;
    if (api == null) {
      showOverlayToast(context, AppLocalizations.of(context)!.bookmarksNotConnected,
          icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _saving = true);
    final edited = Map<String, dynamic>.from(s)
      ..['timeListening'] = newListening
      ..['currentTime'] = newCurrent
      ..['updatedAt'] = newUpdated;
    final ok = await api.updateListeningSession(edited);
    if (!mounted) return;
    if (ok) {
      showOverlayToast(context, l.sessionSaved, icon: Icons.check_rounded);
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      showOverlayToast(context, l.sessionSaveFailed,
          icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _deleteSession() async {
    final l = AppLocalizations.of(context)!;
    final id = widget.session['id'] as String?;
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.sessionDeleteConfirmTitle),
        content: Text(l.sessionDeleteConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final api = context.read<AuthProvider>().apiService;
    if (api == null) {
      showOverlayToast(context, AppLocalizations.of(context)!.bookmarksNotConnected,
          icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _saving = true);
    final ok = await api.deleteListeningSession(id);
    if (!mounted) return;
    if (ok) {
      showOverlayToast(context, l.sessionDeleted, icon: Icons.delete_outline_rounded);
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      showOverlayToast(context, l.sessionDeleteFailed,
          icon: Icons.error_outline_rounded);
    }
  }

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
      if (!mounted) return;
      _finishJump();
      return;
    }

    if (api == null) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        setState(() => _jumping = false);
        showOverlayToast(context, l.bookmarksNotConnected,
            icon: Icons.error_outline_rounded);
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
        showOverlayToast(context, l.statsScreenCouldNotLoadItem,
            icon: Icons.error_outline_rounded);
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
          showOverlayToast(context, l.statsScreenCouldNotFindEpisode,
              icon: Icons.error_outline_rounded);
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
      libraryId: sessionLibraryId ?? fullItem['libraryId'] as String?,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _jumping = false);
      showOverlayToast(
        context,
        error,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    _finishJump();
  }

  void _finishJump() {
    Navigator.pop(context);
    widget.onJumped?.call();
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
                  const SizedBox(height: 10),
                  Row(children: [
                    if (widget.allowEdit) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _editSession,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(l.edit),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _deleteSession,
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 18, color: cs.error),
                        label:
                            Text(l.delete, style: TextStyle(color: cs.error)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side:
                              BorderSide(color: cs.error.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ]),
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
