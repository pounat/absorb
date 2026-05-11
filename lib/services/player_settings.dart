import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scoped_prefs.dart';
import '../widgets/card_button_config.dart';

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

class PlayerSettings {
  /// Notifier that fires when any player setting changes.
  /// Widgets can listen to this instead of polling SharedPreferences.
  static final ChangeNotifier settingsChanged = ChangeNotifier();
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

  static Future<bool> getUpcomingReleasesSortByDate() => _get('upcomingReleasesSortByDate', false);
  static Future<void> setUpcomingReleasesSortByDate(bool value) => _set('upcomingReleasesSortByDate', value);

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

  /// Bookmark sort: 'newest' (default) or 'position'
  static Future<String> getBookmarkSort() => _get('bookmarkSort', 'newest');
  static Future<void> setBookmarkSort(String value) => _set('bookmarkSort', value);

  static Future<bool> getMergeAbsorbingLibraries() => _get('mergeAbsorbingLibraries', false);
  static Future<void> setMergeAbsorbingLibraries(bool value) => _set('mergeAbsorbingLibraries', value);

  static Future<int> getMaxConcurrentDownloads() => _get('maxConcurrentDownloads', 1);
  static Future<void> setMaxConcurrentDownloads(int value) => _set('maxConcurrentDownloads', value);

  // ── Queue mode (replaces autoPlayNextBook + autoPlayNextPodcast) ──
  // Values: 'off', 'manual', 'auto_next'
  static Future<String> getQueueMode() => _get('queueMode', 'off');
  static Future<void> setQueueMode(String value) => _set('queueMode', value);

  static Future<String> getBookQueueMode() async {
    final value = await ScopedPrefs.getString('bookQueueMode');
    return value ?? await getQueueMode();
  }
  static Future<void> setBookQueueMode(String value) => _set('bookQueueMode', value);

  static Future<String> getPodcastQueueMode() async {
    final value = await ScopedPrefs.getString('podcastQueueMode');
    return value ?? await getQueueMode();
  }
  static Future<void> setPodcastQueueMode(String value) => _set('podcastQueueMode', value);

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

  static Future<bool> getShowBookSlider() => _get('showBookSlider', false);
  static Future<void> setShowBookSlider(bool value) => _set('showBookSlider', value, notify: true);

  static Future<bool> getSpeedAdjustedTime() => _get('speedAdjustedTime', true);
  static Future<void> setSpeedAdjustedTime(bool value) => _set('speedAdjustedTime', value, notify: true);

  static Future<int> getForwardSkip() => _get('forwardSkip', 30);
  static Future<void> setForwardSkip(int seconds) => _set('forwardSkip', seconds, notify: true);

  static Future<int> getBackSkip() => _get('backSkip', 10);
  static Future<void> setBackSkip(int seconds) => _set('backSkip', seconds, notify: true);
  static Future<bool> getSkipChapterBarrier() => _get('skipChapterBarrier', true);
  static Future<void> setSkipChapterBarrier(bool value) => _set('skipChapterBarrier', value);

  /// Cached value for synchronous access in widget build methods.
  static bool showExplicitBadge = true;
  static Future<bool> getShowExplicitBadge() => _get('showExplicitBadge', true);
  static Future<void> setShowExplicitBadge(bool value) async {
    showExplicitBadge = value;
    await _set('showExplicitBadge', value);
  }

  static Future<bool> getNotificationChapterProgress() => _get('notificationChapterProgress', false);
  static Future<void> setNotificationChapterProgress(bool value) => _set('notificationChapterProgress', value, notify: true);

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

  static Future<int> getLibraryTab() => _get('libraryTab', 0);
  static Future<void> setLibraryTab(int value) => _set('libraryTab', value);

  // ── Podcast library sort persistence ──

  static Future<String> getPodcastSort() => _get('podcastSort', 'recentlyAdded');
  static Future<void> setPodcastSort(String value) => _set('podcastSort', value);

  static Future<bool> getPodcastSortAsc() => _get('podcastSortAsc', false);
  static Future<void> setPodcastSortAsc(bool value) => _set('podcastSortAsc', value);

  static Future<String> getSeriesSort() => _get('seriesSort', 'alphabetical');
  static Future<void> setSeriesSort(String value) => _set('seriesSort', value);

  static Future<bool> getSeriesSortAsc() => _get('seriesSortAsc', true);
  static Future<void> setSeriesSortAsc(bool value) => _set('seriesSortAsc', value);

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

  static Future<bool> getSnappyTransitions() => _get('snappyTransitions', false);
  static Future<void> setSnappyTransitions(bool value) => _set('snappyTransitions', value);

  static Future<bool> getRectangleCovers() => _get('rectangleCovers', false);
  static Future<void> setRectangleCovers(bool value) => _set('rectangleCovers', value, notify: true);

  static Future<bool> getSectionGridView() => _get('sectionGridView', false);
  static Future<void> setSectionGridView(bool value) => _set('sectionGridView', value);

  static Future<bool> getCoverPlayButton() => _get('coverPlayButton', false);
  static Future<void> setCoverPlayButton(bool value) => _set('coverPlayButton', value, notify: true);

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

  static const defaultButtonOrder = ['chapters', 'speed', 'sleep', 'bookmarks', 'details', 'equalizer', 'cast', 'history', 'remove', 'car', 'notes', 'download'];

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

  static Future<String> getColorSource() => _get('colorSource', 'default');
  static Future<void> setColorSource(String value) => _set('colorSource', value);

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
}
