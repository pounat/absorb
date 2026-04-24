import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_player_service.dart';
import 'api_service.dart';
import 'download_service.dart';

const String _androidWidgetName = 'NowPlayingWidget';
const String _androidWidgetCompactName = 'NowPlayingWidgetCompact';
const String _androidWidgetStatsName = 'StatsWidget';
const Duration _statsThrottle = Duration(minutes: 15);

class HomeWidgetService {
  static final HomeWidgetService _instance = HomeWidgetService._();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._();

  Timer? _progressTimer;
  Timer? _statsTimer;
  Timer? _pendingUpdate;
  String? _lastCoverItemId;
  DateTime? _lastUpdate;
  DateTime? _lastStatsFetch;
  bool _initialized = false;
  bool _updating = false;
  bool _refreshingStats = false;
  StreamSubscription? _clickSub;

  /// Call after AudioPlayerService is initialized to start pushing state.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final player = AudioPlayerService();
    player.addListener(_onPlayerChanged);

    // Listen for widget click actions (e.g. play/pause button)
    _clickSub = HomeWidget.widgetClicked.listen(_onWidgetClicked);

    // Check if the app was cold-started from a widget tap
    final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (launchUri != null) {
      _onWidgetClicked(launchUri);
    }

    // Push current state in case a widget already exists.
    _scheduleUpdate();
    // Fetch stats in the background so the StatsWidget renders fresh on launch.
    refreshStats();

    // Stats timer runs even while the app is backgrounded so "today" keeps
    // ticking on the widget during long listening sessions without needing
    // the user to open the app. 15-min cadence matches the refresh throttle.
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(_statsThrottle, (_) => refreshStats());
  }

  void dispose() {
    _progressTimer?.cancel();
    _statsTimer?.cancel();
    _pendingUpdate?.cancel();
    _clickSub?.cancel();
    AudioPlayerService().removeListener(_onPlayerChanged);
  }

  void _onWidgetClicked(Uri? uri) {
    debugPrint('[HomeWidget] widgetClicked: $uri');
    if (uri == null) return;
    if (uri.host == 'widget' && uri.path == '/play_pause') {
      _handlePlayPause();
    }
  }

  /// Public entry point for cold-start resume of the last-played item.
  ///
  /// Wraps the original widget play/pause handler so the same restore path
  /// can be invoked from elsewhere (for example from AudioPlayerService when
  /// a media button press hits the service before the UI has bootstrapped
  /// the current item).
  Future<void> resumeLastPlayedIfAvailable() => _handlePlayPause();

  Future<void> _handlePlayPause() async {
    final player = AudioPlayerService();

    // When there's an active session the widget uses a MediaSession media button
    // instead of launching the app, so this path is only hit for cold resume.
    if (player.hasBook) return;

    // No active session — cold resume (app stays open for initial setup)
    final prefs = await SharedPreferences.getInstance();
    final itemId = prefs.getString('widget_item_id');
    debugPrint('[HomeWidget] play_pause: cold resume, itemId=$itemId');
    if (itemId == null) return;

    final serverUrl = prefs.getString('server_url');
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refresh_token');
    debugPrint('[HomeWidget] play_pause: server=${serverUrl != null}, token=${token != null}');
    if (serverUrl == null || token == null) return;

    Map<String, String>? customHeaders;
    final headersJson = prefs.getString('custom_headers');
    if (headersJson != null) {
      try {
        customHeaders =
            Map<String, String>.from(jsonDecode(headersJson) as Map);
      } catch (_) {}
    }

    final api = ApiService(
      baseUrl: serverUrl,
      token: token,
      refreshToken: refreshToken,
      isLegacyToken: refreshToken == null,
      customHeaders: customHeaders ?? const {},
    );

    final episodeId = prefs.getString('widget_episode_id');

    try {
      debugPrint('[HomeWidget] play_pause: fetching item $itemId (episode=$episodeId)');
      final fullItem = await api.getLibraryItem(itemId);
      if (fullItem == null) {
        debugPrint('[HomeWidget] play_pause: getLibraryItem returned null');
        return;
      }

      final media = fullItem['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String? ?? '';
      final author = metadata['authorName'] as String? ?? '';
      final coverUrl = api.getCoverUrl(itemId);
      final duration = (media['duration'] is num)
          ? (media['duration'] as num).toDouble()
          : 0.0;
      final chapters = (media['chapters'] as List<dynamic>?) ?? [];

      if (episodeId != null) {
        final episodes = (media['episodes'] as List<dynamic>?) ?? [];
        final episode = episodes.cast<Map<String, dynamic>>().firstWhere(
              (e) => e['id'] == episodeId,
              orElse: () => <String, dynamic>{},
            );
        final epTitle = episode['title'] as String? ?? title;
        final epDuration =
            (episode['duration'] as num?)?.toDouble() ?? duration;

        await player.playItem(
          api: api,
          itemId: itemId,
          title: epTitle,
          author: title,
          coverUrl: coverUrl,
          totalDuration: epDuration,
          chapters: [],
          episodeId: episodeId,
          episodeTitle: epTitle,
        );
      } else {
        await player.playItem(
          api: api,
          itemId: itemId,
          title: title,
          author: author,
          coverUrl: coverUrl,
          totalDuration: duration,
          chapters: chapters,
        );
      }
    } catch (e) {
      debugPrint('[HomeWidget] Resume playback failed: $e');
    }
  }

  void _onPlayerChanged() {
    // Throttle to max once per 2 seconds, but never drop an update —
    // schedule a deferred one so the final state always gets pushed.
    final now = DateTime.now();
    if (_lastUpdate != null &&
        now.difference(_lastUpdate!).inMilliseconds < 2000) {
      _pendingUpdate?.cancel();
      _pendingUpdate = Timer(const Duration(seconds: 2), _scheduleUpdate);
      return;
    }
    _scheduleUpdate();
  }

  /// Schedule an update on the next microtask so we never do async work
  /// inside the synchronous ChangeNotifier callback.
  void _scheduleUpdate() {
    if (_updating) return;
    _updating = true;
    Future.microtask(() async {
      try {
        await _updateWidgetData();
      } catch (e) {
        debugPrint('[HomeWidget] Update failed: $e');
      } finally {
        _updating = false;
      }
    });
  }

  Future<void> _updateWidgetData() async {
    _lastUpdate = DateTime.now();
    final player = AudioPlayerService();
    final hasBook = player.hasBook;

    await HomeWidget.saveWidgetData<bool>('widget_has_book', hasBook);

    // Push user's skip durations so the widget shows them on the buttons.
    final skipBack = await PlayerSettings.getBackSkip();
    final skipForward = await PlayerSettings.getForwardSkip();
    await HomeWidget.saveWidgetData<int>('widget_skip_back', skipBack);
    await HomeWidget.saveWidgetData<int>('widget_skip_forward', skipForward);

    if (hasBook) {
      await HomeWidget.saveWidgetData<String>(
          'widget_title', player.currentTitle ?? '');
      await HomeWidget.saveWidgetData<String>(
          'widget_author', player.currentAuthor ?? '');
      final chapter = player.currentChapter;
      final chapterTitle = chapter?['title'] as String? ?? '';
      await HomeWidget.saveWidgetData<String>('widget_chapter', chapterTitle);
      await HomeWidget.saveWidgetData<bool>(
          'widget_is_playing', player.isPlaying);

      final totalDur = player.totalDuration;
      final posSec = player.position.inMilliseconds / 1000.0;
      int progress = 0;
      if (totalDur > 0) {
        progress = ((posSec / totalDur) * 1000).round().clamp(0, 1000);
      }
      await HomeWidget.saveWidgetData<int>('widget_progress', progress);

      // Persist item/episode ID so the widget can resume after app kill
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_item_id', player.currentItemId!);
      if (player.currentEpisodeId != null) {
        await prefs.setString('widget_episode_id', player.currentEpisodeId!);
      } else {
        await prefs.remove('widget_episode_id');
      }

      // Cover art — fire-and-forget so it doesn't block the update.
      _updateCoverArt(player.currentItemId!);

      if (player.isPlaying) {
        _startProgressTimer();
      } else {
        _stopProgressTimer();
      }
    } else {
      // No active book — just mark as paused but keep the last book's data
      // so the widget still shows it after app close / force stop.
      await HomeWidget.saveWidgetData<bool>('widget_is_playing', false);
      _stopProgressTimer();
    }

    await HomeWidget.updateWidget(name: _androidWidgetName);
    await HomeWidget.updateWidget(name: _androidWidgetCompactName);
    await HomeWidget.updateWidget(name: _androidWidgetStatsName);
  }

  /// Fetch listening stats from the server and push them to the StatsWidget.
  /// Throttled to once per 15 minutes since stats drift slowly. Pass `force`
  /// to bypass the throttle (e.g. on app foreground after a long gap).
  /// Wipe stats values so a stale user's numbers don't linger on the widget
  /// during an account switch. Call before refreshStats so the widget shows
  /// zeros for the few hundred ms until the new user's data arrives.
  Future<void> clearStats() async {
    try {
      await HomeWidget.saveWidgetData<int>('widget_stats_today', 0);
      await HomeWidget.saveWidgetData<int>('widget_stats_week', 0);
      await HomeWidget.saveWidgetData<int>('widget_stats_streak', 0);
      await HomeWidget.saveWidgetData<int>('widget_stats_books_year', 0);
      await HomeWidget.updateWidget(name: _androidWidgetStatsName);
      _lastStatsFetch = null;
      debugPrint('[StatsWidget] Cleared (account switch or logout)');
    } catch (e) {
      debugPrint('[StatsWidget] Clear failed: $e');
    }
  }

  Future<void> refreshStats({bool force = false}) async {
    if (_refreshingStats) {
      debugPrint('[StatsWidget] Skipping refresh: already in flight');
      return;
    }
    if (!force && _lastStatsFetch != null) {
      final since = DateTime.now().difference(_lastStatsFetch!);
      if (since < _statsThrottle) {
        debugPrint('[StatsWidget] Skipping refresh: ${since.inSeconds}s since last (throttle=${_statsThrottle.inSeconds}s)');
        return;
      }
    }
    _refreshingStats = true;
    try {
      final api = await _buildApiService();
      if (api == null) {
        debugPrint('[StatsWidget] Skipping refresh: no server/token in prefs');
        return;
      }

      debugPrint('[StatsWidget] Fetching listening-stats and /me');
      final stats = await api.getListeningStats();
      final me = await api.getMe();
      _lastStatsFetch = DateTime.now();

      if (stats == null) debugPrint('[StatsWidget] listening-stats returned null');
      if (me == null) debugPrint('[StatsWidget] /me returned null');

      final dailyMap = _extractDailyMap(stats);
      final today = _todaySeconds(dailyMap).round();
      final week = _weekSeconds(dailyMap).round();
      final streak = _currentStreak(dailyMap);
      final booksYear = _countBooksFinishedThisYear(me);

      debugPrint('[StatsWidget] Computed: today=${today}s week=${week}s streak=${streak}d booksThisYear=$booksYear (dailyMapKeys=${dailyMap.length})');

      await HomeWidget.saveWidgetData<int>('widget_stats_today', today);
      await HomeWidget.saveWidgetData<int>('widget_stats_week', week);
      await HomeWidget.saveWidgetData<int>('widget_stats_streak', streak);
      await HomeWidget.saveWidgetData<int>('widget_stats_books_year', booksYear);
      await HomeWidget.updateWidget(name: _androidWidgetStatsName);
      debugPrint('[StatsWidget] Pushed and updateWidget(StatsWidget) called');
    } catch (e) {
      debugPrint('[StatsWidget] Refresh failed: $e');
    } finally {
      _refreshingStats = false;
    }
  }

  Future<ApiService?> _buildApiService() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url');
    final token = prefs.getString('token');
    if (serverUrl == null || token == null) return null;
    final refreshToken = prefs.getString('refresh_token');

    Map<String, String>? customHeaders;
    final headersJson = prefs.getString('custom_headers');
    if (headersJson != null) {
      try {
        customHeaders =
            Map<String, String>.from(jsonDecode(headersJson) as Map);
      } catch (_) {}
    }

    return ApiService(
      baseUrl: serverUrl,
      token: token,
      refreshToken: refreshToken,
      isLegacyToken: refreshToken == null,
      customHeaders: customHeaders ?? const {},
    );
  }

  Map<String, dynamic> _extractDailyMap(Map<String, dynamic>? stats) {
    if (stats == null) return {};
    for (final key in ['dayListeningMap', 'days']) {
      final val = stats[key];
      if (val is Map<String, dynamic>) return val;
    }
    return {};
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double _daySeconds(Map<String, dynamic> map, String key) {
    final val = map[key];
    if (val is num) return val.toDouble();
    if (val is Map) {
      final t = val['timeListening'];
      if (t is num && t > 0) return t.toDouble();
      final total = val['totalTime'];
      if (total is num) return total.toDouble();
    }
    return 0;
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

  int _currentStreak(Map<String, dynamic> dailyMap) {
    int streak = 0;
    final now = DateTime.now();
    final startOffset = _daySeconds(dailyMap, _dateKey(now)) > 0 ? 0 : 1;
    for (int i = startOffset; i < 365; i++) {
      if (_daySeconds(dailyMap, _dateKey(now.subtract(Duration(days: i)))) > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _countBooksFinishedThisYear(Map<String, dynamic>? me) {
    if (me == null) return 0;
    final progress = me['mediaProgress'];
    if (progress is! List) return 0;
    final year = DateTime.now().year;
    var count = 0;
    for (final entry in progress) {
      if (entry is! Map) continue;
      if (entry['isFinished'] != true) continue;
      // episodeId is non-null for podcast entries — exclude so the "books"
      // count doesn't inflate with every finished podcast episode.
      final episodeId = entry['episodeId'];
      if (episodeId is String && episodeId.isNotEmpty) continue;
      final raw = entry['finishedAt'];
      if (raw is! num) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      if (dt.year == year) count++;
    }
    return count;
  }

  Future<void> _updateCoverArt(String itemId) async {
    final player = AudioPlayerService();
    final coverUrl = player.currentCoverUrl;
    final cacheKey = '$itemId|$coverUrl';
    if (_lastCoverItemId == cacheKey) return;
    _lastCoverItemId = cacheKey;

    String? coverPath;

    try {
      // Check for a locally downloaded cover first.
      final downloadService = DownloadService();
      if (downloadService.isDownloaded(itemId)) {
        coverPath = await downloadService.getLocalCoverPath(itemId);
      }

      // If no local cover, download from server to a temp file.
      if (coverPath == null) {
        if (coverUrl != null && coverUrl.isNotEmpty) {
          final cacheDir = await getTemporaryDirectory();
          final widgetCoverDir = Directory('${cacheDir.path}/widget_covers');
          if (!widgetCoverDir.existsSync()) {
            widgetCoverDir.createSync(recursive: true);
          }
          final coverFile = File('${widgetCoverDir.path}/$itemId.jpg');

          final response = await http
              .get(Uri.parse(coverUrl))
              .timeout(const Duration(seconds: 10));
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            await coverFile.writeAsBytes(response.bodyBytes);
            coverPath = coverFile.path;
          }
        }
      }
    } catch (e) {
      debugPrint('[HomeWidget] Cover update failed: $e');
    }

    try {
      await HomeWidget.saveWidgetData<String?>('widget_cover_path', coverPath);
      await HomeWidget.updateWidget(name: _androidWidgetName);
      await HomeWidget.updateWidget(name: _androidWidgetCompactName);
    } catch (e) {
      debugPrint('[HomeWidget] Cover save failed: $e');
    }
  }

  void _startProgressTimer() {
    if (_progressTimer?.isActive == true) return;
    _progressTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      _scheduleUpdate();
      // Piggyback a stats refresh; the 15-min throttle inside refreshStats
      // keeps this cheap even though the timer ticks every 2 minutes.
      refreshStats();
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void onAppBackgrounded() {
    _stopProgressTimer();
  }

  void onAppForegrounded() {
    if (AudioPlayerService().isPlaying) {
      _startProgressTimer();
      _scheduleUpdate();
    }
    refreshStats();
  }
}
