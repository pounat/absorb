import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scoped_prefs.dart';
import '../widgets/card_button_config.dart';

typedef QueueModeSnapshot = ({
  String bookMode,
  String podcastMode,
  String? playlistId,
  String? collectionId,
  String? collectionName,
});

// ─── Auto-rewind settings ───

class AutoRewindSettings {
  final bool enabled;
  final double minRewind;
  final double maxRewind;
  final double activationDelay; // seconds — how long pause must be before rewind kicks in
  final bool chapterBarrier; // don't rewind past the start of the current chapter
  final bool sessionStartRewind; // rewind by maxRewind when starting a new session

  const AutoRewindSettings({
    this.enabled = true,
    this.minRewind = 1.0,
    this.maxRewind = 30.0,
    this.activationDelay = 0.0, // 0 = always rewind on resume
    this.chapterBarrier = false,
    this.sessionStartRewind = false,
  });

  static Future<AutoRewindSettings> load() async {
    return AutoRewindSettings(
      enabled: await ScopedPrefs.getBool('autoRewind_enabled') ?? true,
      minRewind: await ScopedPrefs.getDouble('autoRewind_min') ?? 1.0,
      maxRewind: await ScopedPrefs.getDouble('autoRewind_max') ?? 30.0,
      activationDelay: await ScopedPrefs.getDouble('autoRewind_delay') ?? 0.0,
      chapterBarrier: await ScopedPrefs.getBool('autoRewind_chapterBarrier') ?? false,
      sessionStartRewind: await ScopedPrefs.getBool('autoRewind_sessionStart') ?? false,
    );
  }

  Future<void> save() async {
    await ScopedPrefs.setBool('autoRewind_enabled', enabled);
    await ScopedPrefs.setDouble('autoRewind_min', minRewind);
    await ScopedPrefs.setDouble('autoRewind_max', maxRewind);
    await ScopedPrefs.setDouble('autoRewind_delay', activationDelay);
    await ScopedPrefs.setBool('autoRewind_chapterBarrier', chapterBarrier);
    await ScopedPrefs.setBool('autoRewind_sessionStart', sessionStartRewind);
  }
}

enum CardScrubberMode { both, chapter, locked }

extension CardScrubberModeBehavior on CardScrubberMode {
  bool get allowsBookSeeking => this == CardScrubberMode.both;
  bool get allowsChapterSeeking => this != CardScrubberMode.locked;
}

class PlayerSettings {
  /// Notifier that fires when any player setting changes.
  /// Widgets can listen to this instead of polling SharedPreferences.
  static final ChangeNotifier settingsChanged = ChangeNotifier();
  static Future<void> _queueModeMutation = Future.value();

  static Future<T> _serializeQueueModeMutation<T>(
    Future<T> Function() mutation,
  ) {
    final result = _queueModeMutation.then((_) => mutation());
    _queueModeMutation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static void _notify() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    settingsChanged.notifyListeners();
  }
  /// Public trigger for external callers that save settings directly.
  static void notifySettingsChanged() => _notify();

  // ── Private helpers to eliminate boilerplate ──

  static Future<T> _get<T>(String key, T defaultValue) async {
    Object? value;
    if (defaultValue is bool) {
      value = await ScopedPrefs.getBool(key);
    } else if (defaultValue is int) {
      value = await ScopedPrefs.getInt(key);
    } else if (defaultValue is double) {
      value = await ScopedPrefs.getDouble(key);
    } else if (defaultValue is String) {
      value = await ScopedPrefs.getString(key);
    }
    if (value is T) return value;
    return defaultValue;
  }

  static Future<void> _set<T>(String key, T value, {bool notify = false}) async {
    if (value is bool) {
      await ScopedPrefs.setBool(key, value);
    } else if (value is int) {
      await ScopedPrefs.setInt(key, value);
    } else if (value is double) {
      await ScopedPrefs.setDouble(key, value);
    } else if (value is String) {
      await ScopedPrefs.setString(key, value);
    }
    if (notify) _notify();
  }

  // ── General settings ──

  static Future<double> getDefaultSpeed() => _get('defaultSpeed', 1.0);
  static Future<void> setDefaultSpeed(double speed) => _set('defaultSpeed', speed);

  static const List<double> defaultSpeedPresets = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5];

  static Future<List<double>> getSpeedPresets() async {
    final raw = await _get('speedPresets', '');
    if (raw.isEmpty) return List<double>.from(defaultSpeedPresets);
    final parsed = <double>[];
    for (final part in raw.split(',')) {
      final v = double.tryParse(part);
      if (v != null) parsed.add(v);
    }
    if (parsed.isEmpty) return List<double>.from(defaultSpeedPresets);
    parsed.sort();
    return parsed;
  }

  static Future<void> setSpeedPresets(List<double> presets) async {
    final sorted = [...presets]..sort();
    await _set('speedPresets', sorted.map((s) => s.toStringAsFixed(2)).join(','), notify: true);
  }

  static Future<void> resetSpeedPresets() async {
    await _set('speedPresets', '', notify: true);
  }

  /// Audible region override for Find Missing Books (e.g. "us", "uk", "de").
  /// Empty string means use device locale.
  static Future<String> getAudibleRegion() => _get('audibleRegion', '');
  static Future<void> setAudibleRegion(String value) => _set('audibleRegion', value);

  /// Font-size multiplier for the elapsed/remaining/percent text on the player
  /// card (GH #230, accessibility). 1.0 = default.
  static Future<double> getProgressTextScale() => _get('progressTextScale', 1.0);
  static Future<void> setProgressTextScale(double v) =>
      _set('progressTextScale', v, notify: true);

  static Future<bool> getUpcomingReleasesSortByDate() => _get('upcomingReleasesSortByDate', false);
  static Future<void> setUpcomingReleasesSortByDate(bool value) => _set('upcomingReleasesSortByDate', value);

  /// Years without a new release before the upcoming-releases scan considers
  /// a series finished and stops checking it every time (0 = never skip).
  static Future<int> getUpcomingFinishedAfterYears() => _get('upcomingFinishedAfterYears', 3);
  static Future<void> setUpcomingFinishedAfterYears(int value) => _set('upcomingFinishedAfterYears', value);

  /// Last state of the "delete files from the server" checkbox in the delete
  /// confirm. Starts ticked and remembers what you picked, same as the web UI
  /// (which keeps `softDeleteDefault` in localStorage).
  static Future<bool> getDeleteFromFileSystem() => _get('deleteFromFileSystem', true);
  static Future<void> setDeleteFromFileSystem(bool value) => _set('deleteFromFileSystem', value);

  static Future<bool> getWifiOnlyDownloads() => _get('wifiOnlyDownloads', false);
  static Future<void> setWifiOnlyDownloads(bool value) => _set('wifiOnlyDownloads', value);

  static Future<int> getRollingDownloadCount() => _get('rollingDownloadCount', 3);
  static Future<void> setRollingDownloadCount(int value) => _set('rollingDownloadCount', value);

  static Future<bool> getRollingDownloadDeleteFinished() => _get('rollingDownloadDeleteFinished', false);
  static Future<void> setRollingDownloadDeleteFinished(bool value) => _set('rollingDownloadDeleteFinished', value);

  static Future<bool> getQueueAutoDownload() => _get('queueAutoDownload', false);
  static Future<void> setQueueAutoDownload(bool value) => _set('queueAutoDownload', value);

  static Future<bool> getAutoDownloadOnStream() => _get('autoDownloadOnStream', false);
  static Future<void> setAutoDownloadOnStream(bool value) => _set('autoDownloadOnStream', value);

  /// When on, starting a book that's part of a series automatically turns on
  /// series auto-download for that series (the same per-series toggle shown in
  /// the series sheet). Default off.
  static Future<bool> getAutoSeriesDownloadDefault() => _get('autoSeriesDownloadDefault', false);
  static Future<void> setAutoSeriesDownloadDefault(bool value) => _set('autoSeriesDownloadDefault', value);

  /// Bookmark sort: 'newest' (default) or 'position'
  static Future<String> getBookmarkSort() => _get('bookmarkSort', 'newest');
  static Future<void> setBookmarkSort(String value) => _set('bookmarkSort', value);

  // On-device bookmark transcription (Whisper, opt-in). Stored globally
  // (raw SharedPreferences, not per-account) because the downloaded Whisper
  // model is shared across every profile on the device.

  static Future<bool> getTranscriptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('transcriptionEnabled') ?? false;
  }
  static Future<void> setTranscriptionEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('transcriptionEnabled', value);
    _notify();
  }

  /// How much audio a bookmark transcription covers, in seconds.
  static Future<int> getTranscriptionWindowSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('transcriptionWindowSeconds') ?? 30;
  }
  static Future<void> setTranscriptionWindowSeconds(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('transcriptionWindowSeconds', value);
  }

  /// Replace a bookmark transcript with the ebook's exact text when a
  /// confident match is found (only offered when the book has an EPUB).
  static Future<bool> getTranscriptionUseEbookText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('transcriptionUseEbookText') ?? true;
  }
  static Future<void> setTranscriptionUseEbookText(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('transcriptionUseEbookText', value);
  }

  /// Where Find in audiobook lands on success: true = switch to the player,
  /// false = stay in the reader while the audio plays.
  static Future<bool> getFindInAudiobookGoToPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('findInAudiobookGoToPlayer') ?? true;
  }
  static Future<void> setFindInAudiobookGoToPlayer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('findInAudiobookGoToPlayer', value);
  }

  // The dedicated Podcasts tab implies merged behavior: playback must survive
  // the tab-driven library flips and the Absorbing tab must keep showing the
  // playing item from either tab.
  static Future<bool> getMergeAbsorbingLibraries() async =>
      await _get('mergeAbsorbingLibraries', false) || await getPodcastTabEnabled();
  /// The stored toggle value, without the Podcasts-tab implication. For the
  /// settings UI and backups - exporting the effective value would bake
  /// merge=true into a restore permanently.
  static Future<bool> getMergeAbsorbingLibrariesRaw() => _get('mergeAbsorbingLibraries', false);
  static Future<void> setMergeAbsorbingLibraries(bool value) => _set('mergeAbsorbingLibraries', value);

  // Dedicated bottom-nav Podcasts tab (pinned to one podcast library).
  static Future<bool> getPodcastTabEnabled() => _get('podcastTabEnabled', false);
  static Future<void> setPodcastTabEnabled(bool value) => _set('podcastTabEnabled', value, notify: true);
  static Future<String> getPodcastTabLibraryId() => _get('podcastTabLibraryId', '');
  static Future<void> setPodcastTabLibraryId(String value) => _set('podcastTabLibraryId', value, notify: true);

  // Background new-episode notification checks, in minutes (0 = off).
  // WorkManager's floor for periodic jobs is 15 minutes.
  static Future<int> getEpisodeNotifIntervalMinutes() => _get('episodeNotifIntervalMinutes', 0);
  static Future<void> setEpisodeNotifIntervalMinutes(int value) => _set('episodeNotifIntervalMinutes', value, notify: true);

  static Future<int> getMaxConcurrentDownloads() => _get('maxConcurrentDownloads', 1);
  static Future<void> setMaxConcurrentDownloads(int value) => _set('maxConcurrentDownloads', value);

  // ── Stats page ──
  /// Listening goal periods, in the order they're shown.
  static const statsGoalPeriods = ['daily', 'weekly', 'monthly'];

  static String _statsGoalKey(String period) => 'stats_goal_${period}_minutes';
  static String _statsGoalOnKey(String period) => 'stats_goal_${period}_on';

  /// Target used when a period is first switched on, so the goal card starts
  /// somewhere sensible instead of at 0%.
  static int defaultStatsGoalMinutes(String period) => switch (period) {
        'weekly' => 7 * 60,
        'monthly' => 30 * 60,
        _ => 60,
      };

  /// The most a period's target can be: all the time that period holds. These
  /// match the rolling windows the stats page actually sums (7 and 30 days
  /// back from today), not calendar weeks or months.
  static int maxStatsGoalMinutes(String period) => switch (period) {
        'weekly' => 7 * 24 * 60,
        'monthly' => 30 * 24 * 60,
        _ => 24 * 60,
      };

  /// Target listening minutes for one goal period, or 0 when that goal is
  /// switched off. All three periods can be on at once. The target survives
  /// being switched off, so turning a goal back on restores the number you
  /// set instead of dropping back to the default.
  static Future<int> getStatsGoalMinutesFor(String period) async {
    await _migrateStatsGoals();
    if (!await _get(_statsGoalOnKey(period), false)) return 0;
    return _get(_statsGoalKey(period), defaultStatsGoalMinutes(period));
  }

  static Future<void> setStatsGoalMinutesFor(String period, int minutes) async {
    await _migrateStatsGoals();
    if (minutes <= 0) {
      await _set(_statsGoalOnKey(period), false, notify: true);
      return;
    }
    await _set(_statsGoalKey(period), minutes.clamp(1, maxStatsGoalMinutes(period)));
    await _set(_statsGoalOnKey(period), true, notify: true);
  }

  /// Switch a period's goal on or off without disturbing its target.
  static Future<void> setStatsGoalEnabled(String period, bool on) async {
    await _migrateStatsGoals();
    await _set(_statsGoalOnKey(period), on, notify: true);
  }

  /// One-time migration from the single active-period goal to per-period
  /// targets, so an existing goal survives the upgrade. Runs per account,
  /// which is why it hangs off the getters instead of app start.
  static Future<void> _migrateStatsGoals() async {
    if (await ScopedPrefs.containsKey('stats_goal_migrated')) return;
    final oldPeriod = await _get('stats_goal_type', 'off');
    if (statsGoalPeriods.contains(oldPeriod)) {
      final oldMinutes = await _get('stats_goal_minutes', 30);
      await _set(_statsGoalKey(oldPeriod),
          oldMinutes.clamp(1, maxStatsGoalMinutes(oldPeriod)));
      await _set(_statsGoalOnKey(oldPeriod), true);
    }
    await _set('stats_goal_migrated', true);
  }

  /// Territories that start the week on Sunday or Saturday, from CLDR.
  /// Everywhere else starts on Monday, which is most of the world.
  static const _sundayFirstCountries = {
    'AG', 'AS', 'BD', 'BR', 'BS', 'BT', 'BW', 'BZ', 'CA', 'CN', 'CO', 'DM',
    'DO', 'ET', 'GT', 'GU', 'HK', 'HN', 'ID', 'IL', 'IN', 'JM', 'JP', 'KE',
    'KH', 'KR', 'LA', 'MH', 'MM', 'MO', 'MT', 'MX', 'MZ', 'NI', 'NP', 'PA',
    'PE', 'PH', 'PK', 'PR', 'PY', 'SA', 'SG', 'SV', 'TH', 'TT', 'TW', 'UM',
    'US', 'VE', 'VI', 'WS', 'YE', 'ZA', 'ZW',
  };
  static const _saturdayFirstCountries = {
    'AE', 'AF', 'BH', 'DJ', 'DZ', 'EG', 'IQ', 'IR', 'JO', 'KW', 'LY', 'OM',
    'QA', 'SD', 'SY',
  };

  /// Day the stats week starts on: 0 = Sunday, 1 = Monday, 6 = Saturday. Same
  /// numbering as `MaterialLocalizations.firstDayOfWeekIndex`.
  ///
  /// Defaults from the DEVICE locale's country rather than the app's language
  /// setting - the language picker stores a bare language code with no region,
  /// so an English UI would otherwise report Sunday for the whole world.
  static int defaultStatsWeekStart() {
    final country = ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    if (country == null) return 1;
    if (_sundayFirstCountries.contains(country)) return 0;
    if (_saturdayFirstCountries.contains(country)) return 6;
    return 1;
  }

  static Future<int> getStatsWeekStart() async =>
      await ScopedPrefs.getInt('stats_week_start') ?? defaultStatsWeekStart();
  static Future<void> setStatsWeekStart(int day) =>
      _set('stats_week_start', day, notify: true);

  /// Yearly book-challenge target. 0 = off.
  static Future<int> getStatsBookGoal() => _get('stats_book_goal', 0);
  static Future<void> setStatsBookGoal(int value) => _set('stats_book_goal', value, notify: true);

  /// Wall-clock seconds saved by listening above 1x. Banked live by the
  /// player as listening time accrues; read-only here.
  static Future<double> getStatsTimeSaved() => _get('stats_time_saved', 0.0);

  /// When the time-saved counter started accruing (null until the first
  /// banked second). Set once in progress_sync_service.addTimeSaved.
  static Future<DateTime?> getStatsTimeSavedSince() async {
    final ms = await ScopedPrefs.getInt('stats_time_saved_since');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Clear the time-saved total and its start date so it counts fresh from
  /// the next second listened above 1x.
  static Future<void> resetStatsTimeSaved() async {
    await ScopedPrefs.remove('stats_time_saved');
    await ScopedPrefs.remove('stats_time_saved_since');
    _notify();
  }

  /// Listening chart style on the stats page: 'bar' | 'line'.
  /// 'heatmap' used to be a chart style; it's now its own stats section, so a
  /// saved 'heatmap' value is coerced back to 'bar'.
  static Future<String> getStatsChartStyle() async {
    final v = await _get('stats_chart_style', 'bar');
    return v == 'heatmap' ? 'bar' : v;
  }
  static Future<void> setStatsChartStyle(String value) => _set('stats_chart_style', value, notify: true);

  /// Days covered by the bar/line chart: 7 or 30. The heatmap is always a year.
  static Future<int> getStatsChartRange() => _get('stats_chart_range', 7);
  static Future<void> setStatsChartRange(int value) => _set('stats_chart_range', value, notify: true);

  /// Stats page section layout (ids ordered / hidden), per account.
  static Future<List<String>> getStatsSectionOrder() => ScopedPrefs.getStringList('stats_section_order');
  static Future<void> setStatsSectionOrder(List<String> order) async {
    await ScopedPrefs.setStringList('stats_section_order', order);
    _notify();
  }

  static Future<List<String>> getStatsHiddenSections() => ScopedPrefs.getStringList('stats_hidden_sections');
  static Future<void> setStatsHiddenSections(List<String> hidden) async {
    await ScopedPrefs.setStringList('stats_hidden_sections', hidden);
    _notify();
  }

  // ── Queue mode (replaces autoPlayNextBook + autoPlayNextPodcast) ──
  // Values: 'off', 'manual', 'auto_next', 'playlist'
  static Future<String> getQueueMode() => _get('queueMode', 'off');
  static Future<void> setQueueMode(String value) => _set('queueMode', value);

  static Future<String> getBookQueueMode() async {
    final value = await ScopedPrefs.getString('bookQueueMode');
    return value ?? await getQueueMode();
  }
  static Future<void> setBookQueueMode(String value) =>
      _serializeQueueModeMutation(
        () => _set('bookQueueMode', value, notify: true),
      );

  static Future<bool> getShowUpNextLabel() => _get('showUpNextLabel', true);
  static Future<void> setShowUpNextLabel(bool value) =>
      _set('showUpNextLabel', value, notify: true);

  static Future<String> getPodcastQueueMode() async {
    final value = await ScopedPrefs.getString('podcastQueueMode');
    return value ?? await getQueueMode();
  }
  static Future<void> setPodcastQueueMode(String value) =>
      _serializeQueueModeMutation(
        () => _set('podcastQueueMode', value, notify: true),
      );

  /// Per-show podcast auto-advance direction: 'oldest_first' (default) or
  /// 'newest_first'. Stored under a raw (un-scoped) key because the advance
  /// logic in _lp_absorbing reads it straight from SharedPreferences.
  static Future<String> getPodcastAdvanceDir(String showId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('podcast_advance_dir_$showId') ?? 'oldest_first';
  }
  static Future<void> setPodcastAdvanceDir(String showId, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('podcast_advance_dir_$showId', value);
    _notify();
  }

  /// Where a subscribed show's auto-downloaded new episode lands in the
  /// absorbing queue: 'start' (top, default), 'second' (2nd), or 'end'. Per
  /// show, stored under a raw key like the advance direction above.
  static Future<String> getPodcastNewEpisodePosition(String showId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('podcast_new_ep_pos_$showId') ?? 'start';
  }
  static Future<void> setPodcastNewEpisodePosition(String showId, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('podcast_new_ep_pos_$showId', value);
    _notify();
  }

  /// Active playlist ID for playlist queue mode. Null when no playlist is selected.
  static Future<String?> getQueuePlaylistId() async {
    final s = await ScopedPrefs.getString('queuePlaylistId');
    return (s == null || s.isEmpty) ? null : s;
  }
  static Future<void> setQueuePlaylistId(String? id) =>
      _serializeQueueModeMutation(() async {
        if (id == null || id.isEmpty) {
          await ScopedPrefs.remove('queuePlaylistId');
        } else {
          await ScopedPrefs.setString('queuePlaylistId', id);
        }
        _notify();
      });

  /// Enter playlist queue mode atomically: both book and podcast modes flip to
  /// 'playlist' and the active playlist is set. Playlists can mix book and
  /// podcast items, so the two modes always agree when in playlist mode.
  static Future<void> setQueueModePlaylist(String playlistId) =>
      _serializeQueueModeMutation(() async {
        await ScopedPrefs.setString('bookQueueMode', 'playlist');
        await ScopedPrefs.setString('podcastQueueMode', 'playlist');
        await ScopedPrefs.setString('queuePlaylistId', playlistId);
        _notify();
      });

  /// Exit playlist queue mode: both modes back to 'off' and active playlist cleared.
  static Future<void> clearQueueModePlaylist() =>
      _serializeQueueModeMutation(() async {
        await ScopedPrefs.setString('bookQueueMode', 'off');
        await ScopedPrefs.setString('podcastQueueMode', 'off');
        await ScopedPrefs.remove('queuePlaylistId');
        _notify();
      });

  static Future<bool> clearQueueModePlaylistIfActive(String playlistId) =>
      _serializeQueueModeMutation(() async {
        if (await getBookQueueMode() != 'playlist' ||
            await getPodcastQueueMode() != 'playlist' ||
            await getQueuePlaylistId() != playlistId) {
          return false;
        }
        await ScopedPrefs.setString('bookQueueMode', 'off');
        await ScopedPrefs.setString('podcastQueueMode', 'off');
        await ScopedPrefs.remove('queuePlaylistId');
        _notify();
        return true;
      });

  // ── Collection queue mode (books only) ──
  // Mirrors playlist queue mode but plays through a collection's books. Drives
  // bookQueueMode = 'collection' + queueCollectionId; the name is stored too so
  // the now-playing chip needn't fetch the collection.

  static Future<String?> getQueueCollectionId() async {
    final s = await ScopedPrefs.getString('queueCollectionId');
    return (s == null || s.isEmpty) ? null : s;
  }

  static Future<String?> getQueueCollectionName() =>
      ScopedPrefs.getString('queueCollectionName');

  static Future<void> setQueueModeCollection(String collectionId, String name) =>
      _serializeQueueModeMutation(() async {
        await ScopedPrefs.setString('bookQueueMode', 'collection');
        await ScopedPrefs.setString('queueCollectionId', collectionId);
        await ScopedPrefs.setString('queueCollectionName', name);
        // Collection mode replaces any active playlist queue.
        await ScopedPrefs.remove('queuePlaylistId');
        if ((await ScopedPrefs.getString('podcastQueueMode')) == 'playlist') {
          await ScopedPrefs.setString('podcastQueueMode', 'off');
        }
        _notify();
      });

  static Future<void> clearQueueModeCollection() =>
      _serializeQueueModeMutation(() async {
        await ScopedPrefs.setString('bookQueueMode', 'off');
        await ScopedPrefs.remove('queueCollectionId');
        await ScopedPrefs.remove('queueCollectionName');
        _notify();
      });

  static Future<bool> clearQueueModeCollectionIfActive(String collectionId) =>
      _serializeQueueModeMutation(() async {
        if (await getBookQueueMode() != 'collection' ||
            await getQueueCollectionId() != collectionId) {
          return false;
        }
        await ScopedPrefs.setString('bookQueueMode', 'off');
        await ScopedPrefs.remove('queueCollectionId');
        await ScopedPrefs.remove('queueCollectionName');
        _notify();
        return true;
      });

  /// Snapshot of the queue-mode settings, taken before a play activates a
  /// playlist/collection queue so a failed play can put them back.
  static Future<QueueModeSnapshot> queueModeSnapshot() async => (
        bookMode: await getBookQueueMode(),
        podcastMode: await getPodcastQueueMode(),
        playlistId: await ScopedPrefs.getString('queuePlaylistId'),
        collectionId: await ScopedPrefs.getString('queueCollectionId'),
        collectionName: await ScopedPrefs.getString('queueCollectionName'),
      );

  /// Restore a [queueModeSnapshot] if the given playlist queue is still the
  /// active one - same guard as [clearQueueModePlaylistIfActive], so a mode
  /// the user changed again in the meantime is left alone.
  static Future<bool> restoreQueueModeIfPlaylistActive(
          String playlistId, QueueModeSnapshot snapshot) =>
      _serializeQueueModeMutation(() async {
        if (await getBookQueueMode() != 'playlist' ||
            await getPodcastQueueMode() != 'playlist' ||
            await getQueuePlaylistId() != playlistId) {
          return false;
        }
        await _applyQueueModeSnapshot(snapshot);
        return true;
      });

  static Future<bool> restoreQueueModeIfCollectionActive(
          String collectionId, QueueModeSnapshot snapshot) =>
      _serializeQueueModeMutation(() async {
        if (await getBookQueueMode() != 'collection' ||
            await getQueueCollectionId() != collectionId) {
          return false;
        }
        await _applyQueueModeSnapshot(snapshot);
        return true;
      });

  static Future<void> _applyQueueModeSnapshot(QueueModeSnapshot s) async {
    Future<void> put(String key, String? value) => value == null
        ? ScopedPrefs.remove(key)
        : ScopedPrefs.setString(key, value);
    await put('bookQueueMode', s.bookMode);
    await put('podcastQueueMode', s.podcastMode);
    await put('queuePlaylistId', s.playlistId);
    await put('queueCollectionId', s.collectionId);
    await put('queueCollectionName', s.collectionName);
    _notify();
  }

  /// One-time migration from the old boolean auto-play settings to queueMode.
  static Future<void> migrateQueueMode() async {
    if (await ScopedPrefs.containsKey('queueMode')) return;
    final autoBook = await ScopedPrefs.getBool('autoPlayNextBook') ?? false;
    final autoPod = await ScopedPrefs.getBool('autoPlayNextPodcast') ?? false;
    await ScopedPrefs.setString('queueMode', (autoBook || autoPod) ? 'auto_next' : 'off');
  }

  /// One-time migration from the unified queueMode to per-type book/podcast modes.
  static Future<void> migrateBookPodcastQueueMode() async {
    if (await ScopedPrefs.containsKey('bookQueueMode')) return;
    final existing = await getQueueMode();
    await setBookQueueMode(existing);
    await setPodcastQueueMode(existing);
  }

  // Legacy getters kept for backup service compatibility
  static Future<bool> getAutoPlayNextBook() => _get('autoPlayNextBook', false);
  static Future<void> setAutoPlayNextBook(bool value) => _set('autoPlayNextBook', value);

  static Future<bool> getAutoPlayNextPodcast() => _get('autoPlayNextPodcast', false);
  static Future<void> setAutoPlayNextPodcast(bool value) => _set('autoPlayNextPodcast', value);

  static Future<String> getWhenFinished() => _get('whenFinished', 'auto_remove');
  static Future<void> setWhenFinished(String value) => _set('whenFinished', value);

  // ── Player UI settings (notify listeners on change) ──

  static Future<CardScrubberMode> getCardScrubberMode() async {
    final stored = await _get('cardScrubberMode', '');
    for (final mode in CardScrubberMode.values) {
      if (mode.name == stored) return mode;
    }
    final legacyBookSlider = await _get('showBookSlider', false);
    return legacyBookSlider
        ? CardScrubberMode.both
        : CardScrubberMode.chapter;
  }

  static Future<void> setCardScrubberMode(CardScrubberMode mode) async {
    await _set('cardScrubberMode', mode.name);
    await _set('showBookSlider', mode == CardScrubberMode.both);
    _notify();
  }

  static Future<bool> getShowBookSlider() async =>
      await getCardScrubberMode() == CardScrubberMode.both;
  static Future<void> setShowBookSlider(bool value) => setCardScrubberMode(
        value ? CardScrubberMode.both : CardScrubberMode.chapter,
      );

  static Future<bool> getSpeedAdjustedTime() => _get('speedAdjustedTime', true);
  static Future<void> setSpeedAdjustedTime(bool value) => _set('speedAdjustedTime', value, notify: true);

  static Future<int> getForwardSkip() => _get('forwardSkip', 30);
  static Future<void> setForwardSkip(int seconds) => _set('forwardSkip', seconds, notify: true);

  static Future<int> getBackSkip() => _get('backSkip', 10);
  static Future<void> setBackSkip(int seconds) => _set('backSkip', seconds, notify: true);
  static Future<bool> getSkipChapterBarrier() => _get('skipChapterBarrier', true);
  static Future<void> setSkipChapterBarrier(bool value) => _set('skipChapterBarrier', value);

  /// Per-library skip override: a library (podcast or book) can use its own
  /// forward/back amounts instead of the global ones. Both are set together;
  /// null = no override for that library.
  static Future<({int forward, int back})?> getSkipOverride(String libraryId) async {
    final fwd = await ScopedPrefs.getInt('skipOverrideForward_$libraryId');
    final back = await ScopedPrefs.getInt('skipOverrideBack_$libraryId');
    if (fwd == null || back == null) return null;
    return (forward: fwd, back: back);
  }

  static Future<void> setSkipOverride(String libraryId, {int? forward, int? back}) async {
    if (forward == null || back == null) {
      await ScopedPrefs.remove('skipOverrideForward_$libraryId');
      await ScopedPrefs.remove('skipOverrideBack_$libraryId');
    } else {
      await ScopedPrefs.setInt('skipOverrideForward_$libraryId', forward);
      await ScopedPrefs.setInt('skipOverrideBack_$libraryId', back);
    }
    _notify();
  }

  /// Skip amounts that respect a library's override, if it has one.
  static Future<int> getEffectiveForwardSkip({String? libraryId}) async {
    if (libraryId != null) {
      final o = await getSkipOverride(libraryId);
      if (o != null) return o.forward;
    }
    return getForwardSkip();
  }

  static Future<int> getEffectiveBackSkip({String? libraryId}) async {
    if (libraryId != null) {
      final o = await getSkipOverride(libraryId);
      if (o != null) return o.back;
    }
    return getBackSkip();
  }

  // Optional second, bigger skip pair on the player card (GH #242).
  static Future<bool> getLongSkipButtons() => _get('longSkipButtons', false);
  static Future<void> setLongSkipButtons(bool value) => _set('longSkipButtons', value, notify: true);
  static Future<int> getLongForwardSkip() => _get('longForwardSkip', 60);
  static Future<void> setLongForwardSkip(int seconds) => _set('longForwardSkip', seconds, notify: true);
  static Future<int> getLongBackSkip() => _get('longBackSkip', 60);
  static Future<void> setLongBackSkip(int seconds) => _set('longBackSkip', seconds, notify: true);

  /// Cached value for synchronous access in widget build methods.
  static bool showExplicitBadge = true;
  static Future<bool> getShowExplicitBadge() => _get('showExplicitBadge', true);
  static Future<void> setShowExplicitBadge(bool value) async {
    showExplicitBadge = value;
    await _set('showExplicitBadge', value);
  }

  /// Cached value for synchronous access when building audio sources.
  static bool mp3IndexSeeking = false;
  static Future<bool> getMp3IndexSeeking() => _get('mp3IndexSeeking', false);
  static Future<void> setMp3IndexSeeking(bool value) async {
    mp3IndexSeeking = value;
    await _set('mp3IndexSeeking', value);
  }

  static Future<bool> getNotificationChapterProgress() => _get('notificationChapterProgress', false);
  static Future<void> setNotificationChapterProgress(bool value) => _set('notificationChapterProgress', value, notify: true);

  // Android only: when true, the phone media controls show speed + bookmark in
  // the two extra slots instead of chapter skip. Android Auto shows all of them
  // either way; this just reorders which pair the phone "borrows".
  static Future<bool> getMediaControlsSpeedBookmark() => _get('mediaControlsSpeedBookmark', false);
  static Future<void> setMediaControlsSpeedBookmark(bool value) => _set('mediaControlsSpeedBookmark', value, notify: true);

  // Android only: lower the volume for brief focus interruptions instead of
  // pausing. Pausing remains the default.
  static Future<bool> getDuckBriefInterruptions() => _get('duckBriefInterruptions', false);
  static Future<void> setDuckBriefInterruptions(bool value) =>
      _set('duckBriefInterruptions', value, notify: true);

  // Android only (GH #371): start the last played book when Android Auto
  // connects and nothing is loaded yet. The warm case (session alive but
  // paused) is Android Auto's own "automatically resume media" setting; this
  // covers the cold start where no session exists for it to resume.
  static Future<bool> getAutoplayOnCarConnect() => _get('autoplayOnCarConnect', false);
  static Future<void> setAutoplayOnCarConnect(bool value) =>
      _set('autoplayOnCarConnect', value);

  // When true, the system media scrubber still shows progress but can't be
  // dragged to seek - stops accidental position jumps from the notification,
  // lockscreen, Android Auto and CarPlay. Implemented by dropping the seek
  // action from the playback state (Android ACTION_SEEK_TO / iOS
  // changePlaybackPositionCommand). Default off.
  static Future<bool> getLockSeekBar() => _get('lockSeekBar', false);
  static Future<void> setLockSeekBar(bool value) => _set('lockSeekBar', value, notify: true);

  // ── Sleep timer settings ──

  // 'off', 'addTime', 'resetTimer'
  static Future<String> getShakeMode() => _get('shakeMode', 'addTime');
  static Future<void> setShakeMode(String value) => _set('shakeMode', value);

  static Future<int> getShakeAddMinutes() => _get('shakeAddMinutes', 5);
  static Future<void> setShakeAddMinutes(int minutes) => _set('shakeAddMinutes', minutes);

  // 'veryLow', 'low', 'medium', 'high', 'veryHigh'
  static Future<String> getShakeSensitivity() => _get('shakeSensitivity', 'medium');
  static Future<void> setShakeSensitivity(String value) => _set('shakeSensitivity', value);

  /// Linear-acceleration threshold (m/s², gravity excluded) that a shake must
  /// exceed to be registered. Lower = more sensitive.
  static double shakeThresholdFor(String sensitivity) {
    switch (sensitivity) {
      case 'veryHigh': return 8.0;
      case 'high': return 13.0;
      case 'low': return 23.0;
      case 'veryLow': return 28.0;
      case 'medium':
      default: return 18.0;
    }
  }

  static Future<int> getSleepTimerMinutes() => _get('sleepTimerMinutes', 30);
  static Future<void> setSleepTimerMinutes(int minutes) => _set('sleepTimerMinutes', minutes);

  static Future<int> getSleepTimerChapters() => _get('sleepTimerChapters', 1);
  static Future<void> setSleepTimerChapters(int chapters) => _set('sleepTimerChapters', chapters);

  /// Media-button snooze during the sleep timer wind-down (GH #333):
  /// 'off' | 'addTime' | 'resetTimer'. A press inside the wind-down window
  /// resets or extends the timer instead of pausing.
  static Future<String> getSleepButtonMode() => _get('sleepButtonMode', 'off');
  static Future<void> setSleepButtonMode(String v) => _set('sleepButtonMode', v);

  static Future<bool> getResetSleepOnPause() => _get('resetSleepOnPause', false);
  static Future<void> setResetSleepOnPause(bool value) => _set('resetSleepOnPause', value);

  static Future<bool> getSleepFadeOut() => _get('sleepFadeOut', true);
  static Future<void> setSleepFadeOut(bool value) => _set('sleepFadeOut', value);
  static Future<int> getSleepFadeDuration() => _get('sleepFadeDuration', 30);
  static Future<void> setSleepFadeDuration(int seconds) => _set('sleepFadeDuration', seconds);
  static Future<bool> getSleepChime() => _get('sleepChime', false);
  static Future<void> setSleepChime(bool value) => _set('sleepChime', value);
  static Future<double> getSleepChimeVolume() => _get('sleepChimeVolume', 2.0);
  static Future<void> setSleepChimeVolume(double value) => _set('sleepChimeVolume', value);

  static Future<int> getSleepRewindSeconds() => _get('sleepRewindSeconds', 0);
  static Future<void> setSleepRewindSeconds(int seconds) => _set('sleepRewindSeconds', seconds);
  static Future<int> getSleepTimerTab() => _get('sleepTimerTab', 0);
  static Future<void> setSleepTimerTab(int tab) => _set('sleepTimerTab', tab);

  static Future<bool> getSheetGridView() => _get('sheetGridView', false);
  static Future<void> setSheetGridView(bool value) => _set('sheetGridView', value);
  static Future<bool> getSheetCollapseSeries() => _get('sheetCollapseSeries', true);
  static Future<void> setSheetCollapseSeries(bool value) => _set('sheetCollapseSeries', value);
  static Future<bool> getCollapseBookSeries() => _get('collapseBookSeries', false);
  static Future<void> setCollapseBookSeries(bool value) => _set('collapseBookSeries', value);

  static Future<bool> getHideEbookOnly() => _get('hideEbookOnly', false);
  static Future<void> setHideEbookOnly(bool value) => _set('hideEbookOnly', value, notify: true);

  static Future<bool> getCollapseSeries() => _get('collapseSeries', false);
  static Future<void> setCollapseSeries(bool value) => _set('collapseSeries', value, notify: true);

  // ── Streaming cache ──

  /// 0 = disabled, > 0 = cache size in MB (LRU eviction)
  static Future<int> getStreamingCacheSizeMb() => _get('streamingCacheSizeMb', 256);
  static Future<void> setStreamingCacheSizeMb(int value) async {
    debugPrint('[Settings] Streaming cache set to: $value MB');
    await _set('streamingCacheSizeMb', value);
    // Reconfigure the cache immediately
    try {
      await AudioPlayer.configureStreamingCache(value);
      debugPrint('[Settings] Streaming cache configured on native side');
    } catch (e) {
      debugPrint('[Settings] Streaming cache configure failed: $e');
    }
  }

  // ── Library sort/filter persistence ──

  static Future<String> getLibrarySort() => _get('librarySort', 'recentlyAdded');
  static Future<void> setLibrarySort(String value) => _set('librarySort', value);

  static Future<bool> getLibrarySortAsc() => _get('librarySortAsc', false);
  static Future<void> setLibrarySortAsc(bool value) => _set('librarySortAsc', value);

  static Future<String> getLibraryFilter() => _get('libraryFilter', 'none');
  static Future<void> setLibraryFilter(String value) => _set('libraryFilter', value);

  static Future<String> getLibraryGenreFilter() => _get('libraryGenreFilter', '');
  static Future<void> setLibraryGenreFilter(String? value) => _set('libraryGenreFilter', value ?? '');

  static Future<String> getLibraryTagFilter() => _get('libraryTagFilter', '');
  static Future<void> setLibraryTagFilter(String? value) => _set('libraryTagFilter', value ?? '');

  static Future<String> getLibraryMissingMetadataFilter() =>
      _get('libraryMissingMetadataFilter', '');
  static Future<void> setLibraryMissingMetadataFilter(String? value) =>
      _set('libraryMissingMetadataFilter', value ?? '');

  static Future<String> getLibraryFilterValue() =>
      _get('libraryFilterValue', '');
  static Future<void> setLibraryFilterValue(String? value) =>
      _set('libraryFilterValue', value ?? '');
  static Future<String> getLibraryFilterValueLabel() =>
      _get('libraryFilterValueLabel', '');
  static Future<void> setLibraryFilterValueLabel(String? value) =>
      _set('libraryFilterValueLabel', value ?? '');

  static Future<String> getLibrarySeriesFilter() => _get('librarySeriesFilter', 'none');
  static Future<void> setLibrarySeriesFilter(String value) => _set('librarySeriesFilter', value);

  static Future<int> getLibraryTab() => _get('libraryTab', 0);
  static Future<void> setLibraryTab(int value) => _set('libraryTab', value);

  /// Podcast library view: 0 = Shows grid, 1 = Episodes feed.
  static Future<int> getPodcastView() => _get('podcastView', 0);
  static Future<void> setPodcastView(int value) => _set('podcastView', value);

  // ── Podcast library sort persistence ──

  static Future<String> getPodcastSort() => _get('podcastSort', 'recentlyAdded');
  static Future<void> setPodcastSort(String value) => _set('podcastSort', value);

  static Future<bool> getPodcastSortAsc() => _get('podcastSortAsc', false);
  static Future<void> setPodcastSortAsc(bool value) => _set('podcastSortAsc', value);

  static Future<String> getPodcastFilter() => _get('podcastFilter', 'none');
  static Future<void> setPodcastFilter(String value) =>
      _set('podcastFilter', value);
  static Future<String> getPodcastGenreFilter() =>
      _get('podcastGenreFilter', '');
  static Future<void> setPodcastGenreFilter(String? value) =>
      _set('podcastGenreFilter', value ?? '');
  static Future<String> getPodcastTagFilter() =>
      _get('podcastTagFilter', '');
  static Future<void> setPodcastTagFilter(String? value) =>
      _set('podcastTagFilter', value ?? '');
  static Future<String> getPodcastFilterValue() =>
      _get('podcastFilterValue', '');
  static Future<void> setPodcastFilterValue(String? value) =>
      _set('podcastFilterValue', value ?? '');
  static Future<String> getPodcastFilterValueLabel() =>
      _get('podcastFilterValueLabel', '');
  static Future<void> setPodcastFilterValueLabel(String? value) =>
      _set('podcastFilterValueLabel', value ?? '');

  static Future<String> getSeriesSort() => _get('seriesSort', 'alphabetical');
  static Future<void> setSeriesSort(String value) => _set('seriesSort', value);

  static Future<bool> getSeriesSortAsc() => _get('seriesSortAsc', true);
  static Future<void> setSeriesSortAsc(bool value) => _set('seriesSortAsc', value);

  static Future<String> getListsSort() => _get('listsSort', 'alphabetical');
  static Future<void> setListsSort(String value) => _set('listsSort', value);

  static Future<bool> getListsSortAsc() => _get('listsSortAsc', true);
  static Future<void> setListsSortAsc(bool value) => _set('listsSortAsc', value);

  static Future<String> getAuthorSort() => _get('authorSort', 'alphabetical');
  static Future<void> setAuthorSort(String value) => _set('authorSort', value);

  static Future<bool> getAuthorSortAsc() => _get('authorSortAsc', true);
  static Future<void> setAuthorSortAsc(bool value) => _set('authorSortAsc', value);

  static Future<String> getNarratorSort() => _get('narratorSort', 'alphabetical');
  static Future<void> setNarratorSort(String value) => _set('narratorSort', value);

  static Future<bool> getNarratorSortAsc() => _get('narratorSortAsc', true);
  static Future<void> setNarratorSortAsc(bool value) => _set('narratorSortAsc', value);

  static Future<bool> getShowGoodreadsButton() => _get('showGoodreadsButton', false);
  static Future<void> setShowGoodreadsButton(bool value) => _set('showGoodreadsButton', value);

  static Future<bool> getLoggingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggingEnabled') ?? false;
  }
  static Future<void> setLoggingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggingEnabled', value);
  }

  static Future<bool> getFullScreenPlayer() => _get('fullScreenPlayer', false);
  static Future<void> setFullScreenPlayer(bool value) => _set('fullScreenPlayer', value);

  // Ebook reader: turn pages with the volume keys. 'off' | 'normal'
  // (up = previous page, down = next, matching the ABS app) | 'mirrored'.
  static Future<String> getEreaderVolumeNav() => _get('ereaderVolumeNav', 'off');
  static Future<void> setEreaderVolumeNav(String value) => _set('ereaderVolumeNav', value, notify: true);
  // Keep turning pages with the volume keys even while audio is playing
  // (off = playing audio gives the keys back to system volume).
  static Future<bool> getEreaderVolumeNavWhilePlaying() => _get('ereaderVolumeNavWhilePlaying', false);
  static Future<void> setEreaderVolumeNavWhilePlaying(bool value) => _set('ereaderVolumeNavWhilePlaying', value, notify: true);

  /// When on, the screen is locked to portrait (rotation disabled). Default off
  /// keeps the current behaviour where all orientations are allowed.
  static Future<bool> getLockPortrait() => _get('lockPortrait', false);
  static Future<void> setLockPortrait(bool value) => _set('lockPortrait', value);

  static Future<bool> getSnappyTransitions() => _get('snappyTransitions', false);
  static Future<void> setSnappyTransitions(bool value) => _set('snappyTransitions', value);

  static Future<bool> getClassicWording() => _get('classicWording', false);
  static Future<void> setClassicWording(bool value) => _set('classicWording', value);

  static Future<bool> getRectangleCovers() => _get('rectangleCovers', false);
  static Future<void> setRectangleCovers(bool value) => _set('rectangleCovers', value, notify: true);

  /// Cached value for synchronous access in grid builders.
  /// 'small' | 'medium' | 'large'; medium keeps the long-standing layout.
  static String coverSize = 'medium';
  static Future<String> getCoverSize() => _get('coverSize', 'medium');
  static Future<void> setCoverSize(String value) async {
    coverSize = value;
    await _set('coverSize', value, notify: true);
  }

  /// Per-library cover-shape override: 'rect', 'square', or null (= follow
  /// the global toggle). Lets an ebook library run tall covers while the
  /// audiobook libraries stay square.
  static Future<String?> getRectangleCoversOverride(String libraryId) async {
    final v = await ScopedPrefs.getString('rectangleCovers_$libraryId');
    return (v == 'rect' || v == 'square') ? v : null;
  }

  static Future<void> setRectangleCoversOverride(String libraryId, String? value) async {
    if (value == null) {
      await ScopedPrefs.remove('rectangleCovers_$libraryId');
    } else {
      await ScopedPrefs.setString('rectangleCovers_$libraryId', value);
    }
    _notify();
  }

  /// Cover shape for a library: its override if set, else the global toggle.
  static Future<bool> getRectangleCoversFor(String? libraryId) async {
    if (libraryId != null) {
      final v = await getRectangleCoversOverride(libraryId);
      if (v != null) return v == 'rect';
    }
    return getRectangleCovers();
  }

  static Future<bool> getSectionGridView() => _get('sectionGridView', false);
  static Future<void> setSectionGridView(bool value) => _set('sectionGridView', value);

  static Future<bool> getCoverPlayButton() => _get('coverPlayButton', false);
  static Future<void> setCoverPlayButton(bool value) => _set('coverPlayButton', value, notify: true);

  /// Absorbing-card background style: 'blurred' (cover blur, default), 'gradient'
  /// (gradient from the extracted cover colors), or 'off' (plain theme surface).
  static Future<String> getCardBackground() async =>
      einkMode ? 'off' : await getCardBackgroundRaw();

  /// The stored value, for backup/sync export - the plain getter reports
  /// 'off' while e-ink mode is on, which must not leak into synced settings.
  static Future<String> getCardBackgroundRaw() =>
      _get('cardBackground', 'blurred');
  static Future<void> setCardBackground(String value) => _set('cardBackground', value, notify: true);

  // ── Self-signed certificates (global, not per-user) ──

  static Future<bool> getTrustAllCerts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('trustAllCerts') ?? false;
  }
  static Future<void> setTrustAllCerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trustAllCerts', value);
  }

  // ── Pre-release updates (GitHub build only) ──

  static Future<bool> getIncludePreReleases() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('includePreReleases') ?? false;
  }
  static Future<void> setIncludePreReleases(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('includePreReleases', value);
  }

  // ── Local server ──

  static Future<bool> getLocalServerEnabled() => _get('localServerEnabled', false);
  static Future<void> setLocalServerEnabled(bool value) => _set('localServerEnabled', value);

  static Future<String> getLocalServerUrl() => _get('localServerUrl', '');
  static Future<void> setLocalServerUrl(String value) => _set('localServerUrl', value);

  // ── Card button order ──

  static const defaultButtonOrder = ['chapters', 'speed', 'sleep', 'bookmarks', 'details', 'ebook', 'findinebook', 'equalizer', 'cast', 'airplay', 'history', 'remove', 'car', 'notes', 'download'];

  static Future<List<String>> getCardButtonOrder() async {
    final stored = await ScopedPrefs.getStringList('card_button_order');
    if (stored.isEmpty) {
      final knownIds = allCardButtons.map((b) => b.id).toSet();
      return defaultButtonOrder.where((id) => knownIds.contains(id)).toList();
    }
    // Append any new buttons that were added since the user last saved their order
    final knownIds = allCardButtons.map((b) => b.id).toSet();
    final result = stored.where((id) => knownIds.contains(id) || id == '_more').toList();
    for (final b in allCardButtons) {
      if (!result.contains(b.id)) result.add(b.id);
    }
    return result;
  }

  static Future<void> setCardButtonOrder(List<String> order) async {
    await ScopedPrefs.setStringList('card_button_order', order);
    _notify();
  }

  // ── Card button layout ──

  static const defaultButtonVisibleCount = 4;

  static Future<int> getCardButtonVisibleCount() async {
    // Migrate old layout string to count on first load
    final oldLayout = await ScopedPrefs.getString('card_button_layout');
    if (oldLayout != null) {
      final count = _layoutToCount(oldLayout);
      await ScopedPrefs.remove('card_button_layout');
      await _set('card_button_visible_count', count);
      return count;
    }
    final v = await ScopedPrefs.getInt('card_button_visible_count');
    final raw = v ?? defaultButtonVisibleCount;
    return raw.clamp(1, 9);
  }

  static Future<void> setCardButtonVisibleCount(int count) async {
    await _set('card_button_visible_count', count.clamp(1, 9));
    _notify();
  }

  static int _layoutToCount(String layout) {
    switch (layout) {
      case 'compact': return 3;
      case 'standard': return 4;
      case 'row': return 5;
      case 'expanded': return 6;
      case 'full': return 9;
      default: return 4;
    }
  }

  static Future<bool> getCardIconsOnly() => _get('card_icons_only', false);
  static Future<void> setCardIconsOnly(bool v) async { await _set('card_icons_only', v); _notify(); }

  static Future<bool> getCardSingleRow() => _get('card_single_row', false);
  static Future<void> setCardSingleRow(bool v) async { await _set('card_single_row', v); _notify(); }

  static Future<bool> getCardMoreInline() => _get('card_more_inline', false);
  static Future<void> setCardMoreInline(bool v) async { await _set('card_more_inline', v); _notify(); }

  // ── Appearance ──

  static Future<String> getThemeMode() => _get('themeMode', 'dark');
  static Future<void> setThemeMode(String value) => _set('themeMode', value);

  /// Language override. Empty string means follow the system language.
  /// Otherwise an ISO 639-1 code matching a supported locale (e.g. 'en', 'de', 'zh').
  /// Stored globally (not per-user) so it persists across cold start before any
  /// account scope is active — and so all profiles on the device share one UI language.
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') ?? '';
  }
  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
  }

  /// App color source: 'dynamic' follows the playing book cover (default),
  /// 'manual' pins the app to [getManualSeedColor]. (Legacy values fall through
  /// to dynamic since only 'manual' is special-cased.)
  static Future<String> getColorSource() => _get('colorSource', 'dynamic');
  static Future<void> setColorSource(String value) => _set('colorSource', value);

  /// Whether the background gradient is removed (flat). In dark mode this also
  /// switches surfaces to pure black (OLED); in light mode to flat white.
  static Future<bool> getFlatBackground() => _get('flatBackground', false);
  static Future<void> setFlatBackground(bool v) => _set('flatBackground', v);

  /// E-ink mode: an override layer for e-ink screens - light flat monochrome
  /// theme, no animations, plain cards, and the live socket stays down for
  /// battery. The user's individual appearance settings are left untouched so
  /// turning it off restores everything. Device-specific by nature, so it is
  /// deliberately absent from settings sync and backups. The static mirrors
  /// the stored value for cheap checks from non-async code.
  static bool einkMode = false;
  static Future<bool> getEinkMode() => _get('einkMode', false);
  static Future<void> setEinkMode(bool v) => _set('einkMode', v);

  /// Seed color (ARGB int) used when [getColorSource] is 'manual'.
  static Future<int> getManualSeedColor() => _get('manualSeedColor', 0xFF7C6FBF);
  static Future<void> setManualSeedColor(int v) => _set('manualSeedColor', v);

  /// Strength of the primary-tinted background gradient (top alpha, 0 = flat).
  static Future<double> getGradientIntensity() => _get('gradientIntensity', 0.06);
  static Future<void> setGradientIntensity(double v) => _set('gradientIntensity', v);

  /// When manual color is on, also apply it to per-book surfaces (detail sheets,
  /// absorbing card background) instead of each book's cover color.
  static Future<bool> getUseColorEverywhere() => _get('useColorEverywhere', false);
  static Future<void> setUseColorEverywhere(bool v) => _set('useColorEverywhere', v);

  /// Default start screen tab index: 0=Home, 1=Library, 2=Absorbing, 3=Stats, 4=Settings
  static Future<int> getStartScreen() => _get('startScreen', 2);
  static Future<void> setStartScreen(int value) => _set('startScreen', value);

  /// Cached seed color from the last cover-art derivation, so we can show
  /// the correct color immediately on restart without waiting for the image.
  static Future<int?> getCoverSeedColor() async => await ScopedPrefs.getInt('coverSeedColor');
  static Future<void> setCoverSeedColor(int value) => _set('coverSeedColor', value);

  /// Check if an item has no audio content.
  /// For minified responses (library list), duration == 0 means no audio files.
  /// For full responses (detail sheet), we also check ebookFile + audioFiles.
  static bool isEbookOnly(Map<String, dynamic> item) {
    // Podcasts are never eBook-only (minified podcasts lack duration/audioFiles)
    if ((item['mediaType'] as String?) == 'podcast') return false;
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final duration = (media['duration'] as num?)?.toDouble() ?? 0;
    if (duration > 0) return false; // Has audio content
    // No duration — check if there's any audio indicator at all
    final audioFiles = media['audioFiles'] as List<dynamic>?;
    final tracks = media['tracks'] as List<dynamic>?;
    final numAudioFiles = (media['numAudioFiles'] as num?)?.toInt() ?? 0;
    if ((audioFiles != null && audioFiles.isNotEmpty) ||
        (tracks != null && tracks.isNotEmpty) ||
        numAudioFiles > 0) return false;
    return true; // No audio by any measure
  }

  // ── Per-book speed persistence ──

  static Future<double?> getBookSpeed(String itemId) =>
      ScopedPrefs.getDouble('bookSpeed_$itemId');

  static Future<void> setBookSpeed(String itemId, double speed) =>
      _set('bookSpeed_$itemId', speed);

  // ── Per-book sleep-rewind override (falls back to the global default) ──

  static Future<int?> getBookSleepRewindSeconds(String itemId) =>
      ScopedPrefs.getInt('sleepRewind_$itemId');

  static Future<void> setBookSleepRewindSeconds(String itemId, int seconds) =>
      _set('sleepRewind_$itemId', seconds);

  /// Per-book override if one is set for [itemId], otherwise the global default.
  static Future<int> getEffectiveSleepRewindSeconds(String? itemId) async {
    if (itemId != null) {
      final book = await getBookSleepRewindSeconds(itemId);
      if (book != null) return book;
    }
    return getSleepRewindSeconds();
  }
}
