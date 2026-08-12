import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'audio_player_service.dart';
import 'reader_font_service.dart';
import 'scoped_prefs.dart';
import 'sleep_timer_service.dart';
import 'user_account_service.dart';

class BackupService {
  static Future<Map<String, dynamic>> exportSettings({
    required bool includeAccounts,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pkgInfo = await PackageInfo.fromPlatform();

    // PlayerSettings (all scoped per-user now)
    final settings = <String, dynamic>{
      'defaultSpeed': await PlayerSettings.getDefaultSpeed(),
      'wifiOnlyDownloads': await PlayerSettings.getWifiOnlyDownloads(),
      'queueMode': await PlayerSettings.getQueueMode(),
      'bookQueueMode': await PlayerSettings.getBookQueueMode(),
      'podcastQueueMode': await PlayerSettings.getPodcastQueueMode(),
      // Legacy keys for backward compat with older app versions
      'autoPlayNextBook': (await PlayerSettings.getQueueMode()) == 'auto_next',
      'autoPlayNextPodcast': (await PlayerSettings.getQueueMode()) == 'auto_next',
      'cardScrubberMode': (await PlayerSettings.getCardScrubberMode()).name,
      'showBookSlider': await PlayerSettings.getShowBookSlider(),
      'speedAdjustedTime': await PlayerSettings.getSpeedAdjustedTime(),
      'forwardSkip': await PlayerSettings.getForwardSkip(),
      'backSkip': await PlayerSettings.getBackSkip(),
      'longSkipButtons': await PlayerSettings.getLongSkipButtons(),
      'longForwardSkip': await PlayerSettings.getLongForwardSkip(),
      'longBackSkip': await PlayerSettings.getLongBackSkip(),
      'shakeMode': await PlayerSettings.getShakeMode(),
      'shakeAddMinutes': await PlayerSettings.getShakeAddMinutes(),
      'shakeSensitivity': await PlayerSettings.getShakeSensitivity(),
      'resetSleepOnPause': await PlayerSettings.getResetSleepOnPause(),
      'sleepFadeOut': await PlayerSettings.getSleepFadeOut(),
      'sleepFadeDuration': await PlayerSettings.getSleepFadeDuration(),
      'sleepChime': await PlayerSettings.getSleepChime(),
      'sleepChimeVolume': await PlayerSettings.getSleepChimeVolume(),
      'hideEbookOnly': await PlayerSettings.getHideEbookOnly(),
      'collapseSeries': await PlayerSettings.getCollapseSeries(),
      'librarySort': await PlayerSettings.getLibrarySort(),
      'librarySortAsc': await PlayerSettings.getLibrarySortAsc(),
      'libraryFilter': await PlayerSettings.getLibraryFilter(),
      'libraryGenreFilter': await PlayerSettings.getLibraryGenreFilter(),
      'podcastSort': await PlayerSettings.getPodcastSort(),
      'podcastSortAsc': await PlayerSettings.getPodcastSortAsc(),
      'showGoodreadsButton': await PlayerSettings.getShowGoodreadsButton(),
      'loggingEnabled': await PlayerSettings.getLoggingEnabled(),
      'fullScreenPlayer': await PlayerSettings.getFullScreenPlayer(),
      'themeMode': await PlayerSettings.getThemeMode(),
      'cardButtonOrder': await PlayerSettings.getCardButtonOrder(),
      'rollingDownloadCount': await PlayerSettings.getRollingDownloadCount(),
      'rollingDownloadDeleteFinished': await PlayerSettings.getRollingDownloadDeleteFinished(),
      'queueAutoDownload': await PlayerSettings.getQueueAutoDownload(),
      'mergeAbsorbingLibraries': await PlayerSettings.getMergeAbsorbingLibrariesRaw(),
      'podcastTabEnabled': await PlayerSettings.getPodcastTabEnabled(),
      'podcastTabLibraryId': await PlayerSettings.getPodcastTabLibraryId(),
      'episodeNotifIntervalMinutes': await PlayerSettings.getEpisodeNotifIntervalMinutes(),
      'maxConcurrentDownloads': await PlayerSettings.getMaxConcurrentDownloads(),
      'colorSource': await PlayerSettings.getColorSource(),
      'flatBackground': await PlayerSettings.getFlatBackground(),
      'manualSeedColor': await PlayerSettings.getManualSeedColor(),
      'gradientIntensity': await PlayerSettings.getGradientIntensity(),
      'useColorEverywhere': await PlayerSettings.getUseColorEverywhere(),
      'snappyTransitions': await PlayerSettings.getSnappyTransitions(),
      'bookmarkSort': await PlayerSettings.getBookmarkSort(),
      'autoDownloadOnStream': await PlayerSettings.getAutoDownloadOnStream(),
      'notificationChapterProgress': await PlayerSettings.getNotificationChapterProgress(),
      'sleepTimerMinutes': await PlayerSettings.getSleepTimerMinutes(),
      'sleepTimerChapters': await PlayerSettings.getSleepTimerChapters(),
      'streamingCacheSizeMb': await PlayerSettings.getStreamingCacheSizeMb(),
      'seriesSort': await PlayerSettings.getSeriesSort(),
      'seriesSortAsc': await PlayerSettings.getSeriesSortAsc(),
      'authorSort': await PlayerSettings.getAuthorSort(),
      'authorSortAsc': await PlayerSettings.getAuthorSortAsc(),
      'trustAllCerts': await PlayerSettings.getTrustAllCerts(),
      'localServerEnabled': await PlayerSettings.getLocalServerEnabled(),
      'localServerUrl': await PlayerSettings.getLocalServerUrl(),
      'startScreen': await PlayerSettings.getStartScreen(),
      'cardButtonVisibleCount': await PlayerSettings.getCardButtonVisibleCount(),
      'cardIconsOnly': await PlayerSettings.getCardIconsOnly(),
      'cardSingleRow': await PlayerSettings.getCardSingleRow(),
      'cardMoreInline': await PlayerSettings.getCardMoreInline(),
      'rectangleCovers': await PlayerSettings.getRectangleCovers(),
      'coverPlayButton': await PlayerSettings.getCoverPlayButton(),
      'whenFinished': await PlayerSettings.getWhenFinished(),
      'sleepRewindSeconds': await PlayerSettings.getSleepRewindSeconds(),
      'sleepTimerTab': await PlayerSettings.getSleepTimerTab(),
      'sheetGridView': await PlayerSettings.getSheetGridView(),
      'sheetCollapseSeries': await PlayerSettings.getSheetCollapseSeries(),
      'skipChapterBarrier': await PlayerSettings.getSkipChapterBarrier(),
      'audibleRegion': await PlayerSettings.getAudibleRegion(),
      'upcomingReleasesSortByDate': await PlayerSettings.getUpcomingReleasesSortByDate(),
      'libraryTagFilter': await PlayerSettings.getLibraryTagFilter(),
      'librarySeriesFilter': await PlayerSettings.getLibrarySeriesFilter(),
      'narratorSort': await PlayerSettings.getNarratorSort(),
      'narratorSortAsc': await PlayerSettings.getNarratorSortAsc(),
      'classicWording': await PlayerSettings.getClassicWording(),
      'sectionGridView': await PlayerSettings.getSectionGridView(),
      'collapseBookSeries': await PlayerSettings.getCollapseBookSeries(),
      'showExplicitBadge': await PlayerSettings.getShowExplicitBadge(),
      'includePreReleases': await PlayerSettings.getIncludePreReleases(),
      'language': await PlayerSettings.getLanguage(),
      'showUpNextLabel': await PlayerSettings.getShowUpNextLabel(),
      'queuePlaylistId': await PlayerSettings.getQueuePlaylistId(),
      'queueCollectionId': await PlayerSettings.getQueueCollectionId(),
      'queueCollectionName': await PlayerSettings.getQueueCollectionName(),
      'coverSeedColor': await PlayerSettings.getCoverSeedColor(),
      'speedPresets': await PlayerSettings.getSpeedPresets(),
      'cardBackground': await PlayerSettings.getCardBackground(),
      'lockSeekBar': await PlayerSettings.getLockSeekBar(),
      'mediaControlsSpeedBookmark': await PlayerSettings.getMediaControlsSpeedBookmark(),
      'progressTextScale': await PlayerSettings.getProgressTextScale(),
      'lockPortrait': await PlayerSettings.getLockPortrait(),
      'autoSeriesDownloadDefault': await PlayerSettings.getAutoSeriesDownloadDefault(),
      'statsGoalDailyMinutes': await PlayerSettings.getStatsGoalMinutesFor('daily'),
      'statsGoalWeeklyMinutes': await PlayerSettings.getStatsGoalMinutesFor('weekly'),
      'statsGoalMonthlyMinutes': await PlayerSettings.getStatsGoalMinutesFor('monthly'),
      'statsBookGoal': await PlayerSettings.getStatsBookGoal(),
      'statsWeekStart': await PlayerSettings.getStatsWeekStart(),
      'statsChartStyle': await PlayerSettings.getStatsChartStyle(),
      'statsChartRange': await PlayerSettings.getStatsChartRange(),
      'statsSectionOrder': await PlayerSettings.getStatsSectionOrder(),
      'statsHiddenSections': await PlayerSettings.getStatsHiddenSections(),
    };

    // AutoRewind (scoped)
    final rewind = await AutoRewindSettings.load();
    final autoRewind = <String, dynamic>{
      'enabled': rewind.enabled,
      'min': rewind.minRewind,
      'max': rewind.maxRewind,
      'delay': rewind.activationDelay,
      'chapterBarrier': rewind.chapterBarrier,
      'sessionStartRewind': rewind.sessionStartRewind,
    };

    // AutoSleep (scoped)
    final sleep = await AutoSleepSettings.load();
    final autoSleep = <String, dynamic>{
      'enabled': sleep.enabled,
      'startHour': sleep.startHour,
      'startMinute': sleep.startMinute,
      'endHour': sleep.endHour,
      'endMinute': sleep.endMinute,
      'durationMinutes': sleep.durationMinutes,
    };

    // Equalizer (scoped)
    final equalizer = <String, dynamic>{
      'enabled': await ScopedPrefs.getBool('eq_enabled') ?? false,
      'preset': await ScopedPrefs.getString('eq_preset') ?? 'flat',
      'bassBoost': await ScopedPrefs.getDouble('eq_bassBoost') ?? 0.0,
      'virtualizer': await ScopedPrefs.getDouble('eq_virtualizer') ?? 0.0,
      'loudnessGain': await ScopedPrefs.getDouble('eq_loudnessGain') ?? 0.0,
      'bands': await ScopedPrefs.getString('eq_bands'),
      'mono': await ScopedPrefs.getBool('eq_mono') ?? false,
      'skipSilence': await ScopedPrefs.getBool('eq_skipSilence') ?? false,
      'perItem': await ScopedPrefs.getBool('eq_perItem') ?? false,
    };

    // Per-book speeds (scoped - scan scoped keys)
    final bookSpeeds = <String, double>{};
    final scope = UserAccountService().activeScopeKey;
    final speedPrefix = scope.isNotEmpty ? '$scope:bookSpeed_' : 'bookSpeed_';
    for (final key in prefs.getKeys()) {
      if (key.startsWith(speedPrefix)) {
        final itemId = key.substring(speedPrefix.length);
        final speed = prefs.getDouble(key);
        if (speed != null) bookSpeeds[itemId] = speed;
      }
    }

    // Offline mode (global)
    final offlineMode = prefs.getBool('manual_offline_mode') ?? false;

    // Notes for current account (scoped)
    final notes = <String, String>{};
    final notesPrefix = scope.isNotEmpty ? '$scope:notes_' : 'notes_';
    for (final key in prefs.getKeys()) {
      if (key.startsWith(notesPrefix)) {
        final itemId = key.substring(notesPrefix.length);
        final value = prefs.getString(key);
        if (value != null && value.isNotEmpty) notes[itemId] = value;
      }
    }

    // Saved ebooks (scoped)
    final savedEbooks = await ScopedPrefs.getStringList('saved_ebooks');

    // Rolling download series (scoped)
    final rollingDownloadSeries = await ScopedPrefs.getStringList('rolling_download_series');

    // Podcast subscriptions + manually-curated Absorbing list (scoped)
    final subscribedPodcasts = await ScopedPrefs.getStringList('subscribed_podcasts');
    final absorbingManualAdds = await ScopedPrefs.getStringList('absorbing_manual_adds');
    final absorbingFinishedManualAdds =
        await ScopedPrefs.getStringList('absorbing_finished_manual_adds');
    final absorbingManualRemoves = await ScopedPrefs.getStringList('absorbing_manual_removes');

    // Pending offline state (scoped) - server hasn't received these yet
    final pendingSyncs = await ScopedPrefs.getStringList('pending_syncs');
    final pendingOfflineListening = await ScopedPrefs.getStringList('pending_offline_listening');
    final bookmarksPendingCreates = await ScopedPrefs.getString('bookmarks_pending_creates');
    final bookmarksPendingDeletes = await ScopedPrefs.getString('bookmarks_pending_deletes');
    final pendingEbookProgress = await ScopedPrefs.getString('pending_ebook_progress');

    // Offline listening accumulators (scoped) - keyed by itemId
    final offlineListening = <String, int>{};
    final offlinePrefix = scope.isNotEmpty ? '$scope:offline_listening_' : 'offline_listening_';
    for (final key in prefs.getKeys()) {
      if (key.startsWith(offlinePrefix)) {
        final itemId = key.substring(offlinePrefix.length);
        final seconds = prefs.getInt(key);
        if (seconds != null && seconds > 0) offlineListening[itemId] = seconds;
      }
    }

    // RMAB integration config (scoped)
    final rmab = <String, dynamic>{
      'baseUrl': await ScopedPrefs.getString('rmab_base_url'),
      'apiToken': await ScopedPrefs.getString('rmab_api_token'),
      'legacyUrl': await ScopedPrefs.getString('rmab_url'),
      'customHeaders': await ScopedPrefs.getString('rmab_custom_headers'),
    };

    // Home screen layout per library (scoped, keyed by libraryId)
    final homeLayouts = <String, Map<String, List<String>>>{};
    final scopePrefix = scope.isNotEmpty ? '$scope:' : '';
    void collectHome(String shortPrefix, String bucket) {
      final fullPrefix = '$scopePrefix$shortPrefix';
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(fullPrefix)) continue;
        final libId = key.substring(fullPrefix.length);
        final list = prefs.getStringList(key);
        if (list == null) continue;
        homeLayouts.putIfAbsent(libId, () => {})[bucket] = list;
      }
    }
    collectHome('home_section_order_', 'order');
    collectHome('home_hidden_sections_', 'hidden');
    collectHome('home_genre_sections_', 'genres');

    final librarySettings = <String, Map<String, dynamic>>{};
    void collectLibrarySetting(String shortPrefix, String field) {
      final fullPrefix = '$scopePrefix$shortPrefix';
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(fullPrefix)) continue;
        final libraryId = key.substring(fullPrefix.length);
        final value = prefs.get(key);
        if (value is! String && value is! int) continue;
        librarySettings.putIfAbsent(libraryId, () => {})[field] = value;
      }
    }
    collectLibrarySetting('rectangleCovers_', 'coverShape');
    collectLibrarySetting('skipOverrideForward_', 'skipForward');
    collectLibrarySetting('skipOverrideBack_', 'skipBack');

    // Per-item metadata overrides (scoped, keyed by itemId)
    final metadataOverrides = <String, String>{};
    final metaPrefix = '${scopePrefix}metadata_override_';
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(metaPrefix)) continue;
      final itemId = key.substring(metaPrefix.length);
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) metadataOverrides[itemId] = value;
    }

    // Ebook annotations (scoped, keyed by itemId). Highlights, bookmarks and
    // their notes live only on-device (ABS has no ebook annotation API), so
    // the backup is their only way to survive a reinstall.
    final ebookAnnotations = <String, String>{};
    final annotPrefix = '${scopePrefix}ebook_annotations_';
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(annotPrefix)) continue;
      final itemId = key.substring(annotPrefix.length);
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) ebookAnnotations[itemId] = value;
    }

    // E-reader appearance + behavior (scoped)
    final ereader = <String, dynamic>{
      'fontSize': await ScopedPrefs.getInt('ereader_fontSize'),
      'lineHeight': await ScopedPrefs.getDouble('ereader_lineHeight'),
      'marginH': await ScopedPrefs.getInt('ereader_margin_h'),
      'marginV': await ScopedPrefs.getInt('ereader_margin_v'),
      'spread': await ScopedPrefs.getInt('ereader_spread'),
      'theme': await ScopedPrefs.getString('ereader_theme'),
      'font': await ScopedPrefs.getString('ereader_font'),
      'volumeNav': await PlayerSettings.getEreaderVolumeNav(),
      'volumeNavWhilePlaying': await PlayerSettings.getEreaderVolumeNavWhilePlaying(),
    };

    // Per-podcast UI prefs (GLOBAL, not scoped - keyed by itemId)
    final podcastPrefs = <String, Map<String, dynamic>>{};
    void collectPodcast(String prefix, String bucket, Object? Function(String) read) {
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(prefix)) continue;
        final itemId = key.substring(prefix.length);
        final value = read(key);
        if (value == null) continue;
        podcastPrefs.putIfAbsent(itemId, () => {})[bucket] = value;
      }
    }
    collectPodcast('podcast_sort_newest_', 'sortNewest', (k) => prefs.getBool(k));
    collectPodcast('podcast_hide_finished_', 'hideFinished', (k) => prefs.getBool(k));
    collectPodcast('podcast_advance_dir_', 'advanceDir', (k) => prefs.getString(k));

    // Custom download path (GLOBAL)
    final customDownloadPath = prefs.getString('custom_download_path');

    // Accounts & custom headers (optional - contain auth data)
    List<Map<String, dynamic>>? accounts;
    Map<String, String>? customHeaders;
    if (includeAccounts) {
      accounts = UserAccountService()
          .accounts
          .map((a) => a.toJson())
          .toList();
      final headersJson = prefs.getString('custom_headers');
      if (headersJson != null) {
        try {
          customHeaders = Map<String, String>.from(jsonDecode(headersJson) as Map);
        } catch (_) {}
      }
    }

    return {
      'version': 3,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': pkgInfo.version,
      'settings': settings,
      'autoRewind': autoRewind,
      'autoSleep': autoSleep,
      'equalizer': equalizer,
      'bookSpeeds': bookSpeeds,
      'offlineMode': offlineMode,
      'notes': notes,
      'savedEbooks': savedEbooks,
      'rollingDownloadSeries': rollingDownloadSeries,
      'subscribedPodcasts': subscribedPodcasts,
      'absorbingManualAdds': absorbingManualAdds,
      'absorbingFinishedManualAdds': absorbingFinishedManualAdds,
      'absorbingManualRemoves': absorbingManualRemoves,
      'pendingSyncs': pendingSyncs,
      'pendingOfflineListening': pendingOfflineListening,
      'bookmarksPendingCreates': bookmarksPendingCreates,
      'bookmarksPendingDeletes': bookmarksPendingDeletes,
      'pendingEbookProgress': pendingEbookProgress,
      'offlineListening': offlineListening,
      'rmab': rmab,
      'homeLayouts': homeLayouts,
      'librarySettings': librarySettings,
      'metadataOverrides': metadataOverrides,
      'ebookAnnotations': ebookAnnotations,
      'ereader': ereader,
      'podcastPrefs': podcastPrefs,
      'customDownloadPath': customDownloadPath,
      'accounts': accounts,
      'customHeaders': customHeaders,
    };
  }

  /// Build a minimal setup file for provisioning a new user: a single account
  /// whose token is an API key minted for them, plus any custom headers needed
  /// to reach the server. Importing it from the login screen signs them in.
  /// The token has no refresh counterpart, so it is flagged legacy and used as
  /// a standing bearer key.
  static Future<Map<String, dynamic>> buildSetupFile({
    required String serverUrl,
    required String username,
    required String token,
    String? userId,
    Map<String, String>? customHeaders,
  }) async {
    final pkgInfo = await PackageInfo.fromPlatform();
    return {
      'version': 3,
      'setup': true,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': pkgInfo.version,
      'accounts': [
        {
          'serverUrl': serverUrl,
          'username': username,
          'token': token,
          'userId': userId,
          'isLegacyToken': true,
        },
      ],
      if (customHeaders != null && customHeaders.isNotEmpty) 'customHeaders': customHeaders,
    };
  }

  static Future<void> importSettings(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final customHeaders = data['customHeaders'] as Map<String, dynamic>?;
    final restoredCustomHeaders = customHeaders == null
        ? const <String, String>{}
        : Map<String, String>.from(customHeaders);

    // Restore accounts FIRST so ScopedPrefs has the right scope
    // when we write settings below. saveAccount() sets the active scope key.
    final accounts = data['accounts'] as List<dynamic>?;
    if (accounts != null) {
      // saveAccount inserts at the front. Restore in reverse so the backup's
      // first (active) account stays first and owns the scoped settings below.
      for (final a in accounts.reversed) {
        final map = a as Map<String, dynamic>;
        await UserAccountService().saveAccount(SavedAccount.fromJson(
          map,
          legacyCustomHeaders: restoredCustomHeaders,
        ));
      }
    }

    // Custom headers (restore early, before any API calls)
    if (customHeaders != null) {
      await prefs.setString('custom_headers', jsonEncode(customHeaders));
    }

    // PlayerSettings (all go through scoped setters now)
    final s = data['settings'] as Map<String, dynamic>? ?? {};
    if (s['defaultSpeed'] != null) PlayerSettings.setDefaultSpeed((s['defaultSpeed'] as num).toDouble());
    if (s['wifiOnlyDownloads'] != null) PlayerSettings.setWifiOnlyDownloads(s['wifiOnlyDownloads'] as bool);
    if (s['queueMode'] != null) {
      PlayerSettings.setQueueMode(s['queueMode'] as String);
    } else {
      // Legacy backup - migrate the old booleans
      final autoBook = s['autoPlayNextBook'] as bool? ?? false;
      final autoPod = s['autoPlayNextPodcast'] as bool? ?? false;
      PlayerSettings.setQueueMode((autoBook || autoPod) ? 'auto_next' : 'off');
    }
    if (s['bookQueueMode'] != null) PlayerSettings.setBookQueueMode(s['bookQueueMode'] as String);
    if (s['podcastQueueMode'] != null) PlayerSettings.setPodcastQueueMode(s['podcastQueueMode'] as String);
    if (s['whenFinished'] != null) PlayerSettings.setWhenFinished(s['whenFinished'] as String);
    final cardScrubberMode = s['cardScrubberMode'] as String?;
    if (cardScrubberMode != null) {
      final mode = CardScrubberMode.values.firstWhere(
        (value) => value.name == cardScrubberMode,
        orElse: () => CardScrubberMode.chapter,
      );
      await PlayerSettings.setCardScrubberMode(mode);
    } else if (s['showBookSlider'] != null) {
      await PlayerSettings.setShowBookSlider(s['showBookSlider'] as bool);
    }
    if (s['speedAdjustedTime'] != null) PlayerSettings.setSpeedAdjustedTime(s['speedAdjustedTime'] as bool);
    if (s['forwardSkip'] != null) PlayerSettings.setForwardSkip(s['forwardSkip'] as int);
    if (s['backSkip'] != null) PlayerSettings.setBackSkip(s['backSkip'] as int);
    if (s['shakeMode'] != null) PlayerSettings.setShakeMode(s['shakeMode'] as String);
    // Migrate old bool setting
    if (s['shakeMode'] == null && s['shakeToResetSleep'] != null) {
      PlayerSettings.setShakeMode(s['shakeToResetSleep'] as bool ? 'addTime' : 'off');
    }
    if (s['shakeAddMinutes'] != null) PlayerSettings.setShakeAddMinutes(s['shakeAddMinutes'] as int);
    if (s['shakeSensitivity'] != null) PlayerSettings.setShakeSensitivity(s['shakeSensitivity'] as String);
    if (s['resetSleepOnPause'] != null) PlayerSettings.setResetSleepOnPause(s['resetSleepOnPause'] as bool);
    if (s['sleepFadeOut'] != null) PlayerSettings.setSleepFadeOut(s['sleepFadeOut'] as bool);
    if (s['sleepFadeDuration'] != null) PlayerSettings.setSleepFadeDuration(s['sleepFadeDuration'] as int);
    if (s['sleepChime'] != null) PlayerSettings.setSleepChime(s['sleepChime'] as bool);
    if (s['sleepChimeVolume'] != null) PlayerSettings.setSleepChimeVolume((s['sleepChimeVolume'] as num).toDouble());
    if (s['hideEbookOnly'] != null) PlayerSettings.setHideEbookOnly(s['hideEbookOnly'] as bool);
    if (s['collapseSeries'] != null) PlayerSettings.setCollapseSeries(s['collapseSeries'] as bool);
    if (s['librarySort'] != null) PlayerSettings.setLibrarySort(s['librarySort'] as String);
    if (s['librarySortAsc'] != null) PlayerSettings.setLibrarySortAsc(s['librarySortAsc'] as bool);
    if (s['libraryFilter'] != null) PlayerSettings.setLibraryFilter(s['libraryFilter'] as String);
    if (s.containsKey('libraryGenreFilter')) PlayerSettings.setLibraryGenreFilter(s['libraryGenreFilter'] as String?);
    if (s['podcastSort'] != null) PlayerSettings.setPodcastSort(s['podcastSort'] as String);
    if (s['podcastSortAsc'] != null) PlayerSettings.setPodcastSortAsc(s['podcastSortAsc'] as bool);
    if (s['showGoodreadsButton'] != null) PlayerSettings.setShowGoodreadsButton(s['showGoodreadsButton'] as bool);
    if (s['loggingEnabled'] != null) PlayerSettings.setLoggingEnabled(s['loggingEnabled'] as bool);
    if (s['fullScreenPlayer'] != null) PlayerSettings.setFullScreenPlayer(s['fullScreenPlayer'] as bool);
    if (s['themeMode'] != null) PlayerSettings.setThemeMode(s['themeMode'] as String);
    if (s['cardButtonOrder'] != null) {
      PlayerSettings.setCardButtonOrder(
        (s['cardButtonOrder'] as List<dynamic>).cast<String>(),
      );
    }
    if (s['rollingDownloadCount'] != null) PlayerSettings.setRollingDownloadCount(s['rollingDownloadCount'] as int);
    if (s['rollingDownloadDeleteFinished'] != null) PlayerSettings.setRollingDownloadDeleteFinished(s['rollingDownloadDeleteFinished'] as bool);
    if (s['queueAutoDownload'] != null) PlayerSettings.setQueueAutoDownload(s['queueAutoDownload'] as bool);
    if (s['mergeAbsorbingLibraries'] != null) PlayerSettings.setMergeAbsorbingLibraries(s['mergeAbsorbingLibraries'] as bool);
    if (s['podcastTabLibraryId'] != null) {
      await ScopedPrefs.setString(
        'podcastTabLibraryId',
        s['podcastTabLibraryId'] as String,
      );
    }
    if (s['podcastTabEnabled'] != null) {
      await ScopedPrefs.setBool(
        'podcastTabEnabled',
        s['podcastTabEnabled'] as bool,
      );
    }
    if (s['episodeNotifIntervalMinutes'] != null) PlayerSettings.setEpisodeNotifIntervalMinutes(s['episodeNotifIntervalMinutes'] as int);
    if (s['maxConcurrentDownloads'] != null) PlayerSettings.setMaxConcurrentDownloads(s['maxConcurrentDownloads'] as int);
    if (s['colorSource'] != null) PlayerSettings.setColorSource(s['colorSource'] as String);
    if (s['flatBackground'] != null) PlayerSettings.setFlatBackground(s['flatBackground'] as bool);
    if (s['manualSeedColor'] != null) PlayerSettings.setManualSeedColor(s['manualSeedColor'] as int);
    if (s['gradientIntensity'] != null) PlayerSettings.setGradientIntensity((s['gradientIntensity'] as num).toDouble());
    if (s['useColorEverywhere'] != null) PlayerSettings.setUseColorEverywhere(s['useColorEverywhere'] as bool);
    if (s['snappyTransitions'] != null) PlayerSettings.setSnappyTransitions(s['snappyTransitions'] as bool);
    if (s['bookmarkSort'] != null) PlayerSettings.setBookmarkSort(s['bookmarkSort'] as String);
    if (s['autoDownloadOnStream'] != null) PlayerSettings.setAutoDownloadOnStream(s['autoDownloadOnStream'] as bool);
    if (s['notificationChapterProgress'] != null) PlayerSettings.setNotificationChapterProgress(s['notificationChapterProgress'] as bool);
    if (s['sleepTimerMinutes'] != null) PlayerSettings.setSleepTimerMinutes(s['sleepTimerMinutes'] as int);
    if (s['sleepTimerChapters'] != null) PlayerSettings.setSleepTimerChapters(s['sleepTimerChapters'] as int);
    if (s['streamingCacheSizeMb'] != null) PlayerSettings.setStreamingCacheSizeMb(s['streamingCacheSizeMb'] as int);
    if (s['seriesSort'] != null) PlayerSettings.setSeriesSort(s['seriesSort'] as String);
    if (s['seriesSortAsc'] != null) PlayerSettings.setSeriesSortAsc(s['seriesSortAsc'] as bool);
    if (s['authorSort'] != null) PlayerSettings.setAuthorSort(s['authorSort'] as String);
    if (s['authorSortAsc'] != null) PlayerSettings.setAuthorSortAsc(s['authorSortAsc'] as bool);
    if (s['trustAllCerts'] != null) PlayerSettings.setTrustAllCerts(s['trustAllCerts'] as bool);
    if (s['localServerEnabled'] != null) PlayerSettings.setLocalServerEnabled(s['localServerEnabled'] as bool);
    if (s['localServerUrl'] != null) PlayerSettings.setLocalServerUrl(s['localServerUrl'] as String);
    if (s['startScreen'] != null) PlayerSettings.setStartScreen(s['startScreen'] as int);
    if (s['cardButtonVisibleCount'] != null) PlayerSettings.setCardButtonVisibleCount(s['cardButtonVisibleCount'] as int);
    if (s['cardIconsOnly'] != null) PlayerSettings.setCardIconsOnly(s['cardIconsOnly'] as bool);
    if (s['cardSingleRow'] != null) PlayerSettings.setCardSingleRow(s['cardSingleRow'] as bool);
    if (s['cardMoreInline'] != null) PlayerSettings.setCardMoreInline(s['cardMoreInline'] as bool);
    if (s['rectangleCovers'] != null) PlayerSettings.setRectangleCovers(s['rectangleCovers'] as bool);
    if (s['coverPlayButton'] != null) PlayerSettings.setCoverPlayButton(s['coverPlayButton'] as bool);
    if (s['sleepRewindSeconds'] != null) PlayerSettings.setSleepRewindSeconds(s['sleepRewindSeconds'] as int);
    if (s['sleepTimerTab'] != null) PlayerSettings.setSleepTimerTab(s['sleepTimerTab'] as int);
    if (s['sheetGridView'] != null) PlayerSettings.setSheetGridView(s['sheetGridView'] as bool);
    if (s['sheetCollapseSeries'] != null) PlayerSettings.setSheetCollapseSeries(s['sheetCollapseSeries'] as bool);
    if (s['skipChapterBarrier'] != null) PlayerSettings.setSkipChapterBarrier(s['skipChapterBarrier'] as bool);
    if (s['longSkipButtons'] != null) PlayerSettings.setLongSkipButtons(s['longSkipButtons'] as bool);
    if (s['longForwardSkip'] != null) PlayerSettings.setLongForwardSkip(s['longForwardSkip'] as int);
    if (s['longBackSkip'] != null) PlayerSettings.setLongBackSkip(s['longBackSkip'] as int);
    if (s['audibleRegion'] != null) await PlayerSettings.setAudibleRegion(s['audibleRegion'] as String);
    if (s['upcomingReleasesSortByDate'] != null) await PlayerSettings.setUpcomingReleasesSortByDate(s['upcomingReleasesSortByDate'] as bool);
    if (s['libraryTagFilter'] != null) await PlayerSettings.setLibraryTagFilter(s['libraryTagFilter'] as String);
    if (s['librarySeriesFilter'] != null) await PlayerSettings.setLibrarySeriesFilter(s['librarySeriesFilter'] as String);
    if (s['narratorSort'] != null) await PlayerSettings.setNarratorSort(s['narratorSort'] as String);
    if (s['narratorSortAsc'] != null) await PlayerSettings.setNarratorSortAsc(s['narratorSortAsc'] as bool);
    if (s['classicWording'] != null) await PlayerSettings.setClassicWording(s['classicWording'] as bool);
    if (s['sectionGridView'] != null) await PlayerSettings.setSectionGridView(s['sectionGridView'] as bool);
    if (s['collapseBookSeries'] != null) await PlayerSettings.setCollapseBookSeries(s['collapseBookSeries'] as bool);
    if (s['showExplicitBadge'] != null) await PlayerSettings.setShowExplicitBadge(s['showExplicitBadge'] as bool);
    if (s['includePreReleases'] != null) await PlayerSettings.setIncludePreReleases(s['includePreReleases'] as bool);
    if (s['language'] != null) await PlayerSettings.setLanguage(s['language'] as String);
    if (s['showUpNextLabel'] != null) await PlayerSettings.setShowUpNextLabel(s['showUpNextLabel'] as bool);
    if (s['queuePlaylistId'] != null) await PlayerSettings.setQueuePlaylistId(s['queuePlaylistId'] as String?);
    if (s['queueCollectionId'] != null) await ScopedPrefs.setString('queueCollectionId', s['queueCollectionId'] as String);
    if (s['queueCollectionName'] != null) await ScopedPrefs.setString('queueCollectionName', s['queueCollectionName'] as String);
    if (s['coverSeedColor'] != null) await PlayerSettings.setCoverSeedColor(s['coverSeedColor'] as int);
    if (s['speedPresets'] is List) {
      await PlayerSettings.setSpeedPresets((s['speedPresets'] as List).map((e) => (e as num).toDouble()).toList());
    }
    if (s['cardBackground'] != null) await PlayerSettings.setCardBackground(s['cardBackground'] as String);
    if (s['lockSeekBar'] != null) await PlayerSettings.setLockSeekBar(s['lockSeekBar'] as bool);
    if (s['mediaControlsSpeedBookmark'] != null) await PlayerSettings.setMediaControlsSpeedBookmark(s['mediaControlsSpeedBookmark'] as bool);
    if (s['progressTextScale'] != null) await PlayerSettings.setProgressTextScale((s['progressTextScale'] as num).toDouble());
    if (s['lockPortrait'] != null) await PlayerSettings.setLockPortrait(s['lockPortrait'] as bool);
    if (s['autoSeriesDownloadDefault'] != null) await PlayerSettings.setAutoSeriesDownloadDefault(s['autoSeriesDownloadDefault'] as bool);
    for (final p in PlayerSettings.statsGoalPeriods) {
      final key = 'statsGoal${p[0].toUpperCase()}${p.substring(1)}Minutes';
      if (s[key] != null) await PlayerSettings.setStatsGoalMinutesFor(p, s[key] as int);
    }
    // Backups from before goals went per-period carried one target plus the
    // period it applied to.
    if (s['statsGoalDailyMinutes'] == null &&
        s['statsGoalWeeklyMinutes'] == null &&
        s['statsGoalMonthlyMinutes'] == null &&
        s['statsGoalMinutes'] != null &&
        PlayerSettings.statsGoalPeriods.contains(s['statsGoalType'])) {
      await PlayerSettings.setStatsGoalMinutesFor(
          s['statsGoalType'] as String, s['statsGoalMinutes'] as int);
    }
    if (s['statsBookGoal'] != null) await PlayerSettings.setStatsBookGoal(s['statsBookGoal'] as int);
    if (s['statsWeekStart'] != null) await PlayerSettings.setStatsWeekStart(s['statsWeekStart'] as int);
    if (s['statsChartStyle'] != null) await PlayerSettings.setStatsChartStyle(s['statsChartStyle'] as String);
    if (s['statsChartRange'] != null) await PlayerSettings.setStatsChartRange(s['statsChartRange'] as int);
    if (s['statsSectionOrder'] is List) await PlayerSettings.setStatsSectionOrder((s['statsSectionOrder'] as List).cast<String>());
    if (s['statsHiddenSections'] is List) await PlayerSettings.setStatsHiddenSections((s['statsHiddenSections'] as List).cast<String>());

    // AutoRewind (scoped via save())
    final r = data['autoRewind'] as Map<String, dynamic>?;
    if (r != null) {
      await AutoRewindSettings(
        enabled: r['enabled'] as bool? ?? true,
        minRewind: (r['min'] as num?)?.toDouble() ?? 1.0,
        maxRewind: (r['max'] as num?)?.toDouble() ?? 30.0,
        activationDelay: (r['delay'] as num?)?.toDouble() ?? 0.0,
        chapterBarrier: r['chapterBarrier'] as bool? ?? false,
        sessionStartRewind: r['sessionStartRewind'] as bool? ?? false,
      ).save();
    }

    // AutoSleep (scoped via save())
    final sl = data['autoSleep'] as Map<String, dynamic>?;
    if (sl != null) {
      await AutoSleepSettings(
        enabled: sl['enabled'] as bool? ?? false,
        startHour: sl['startHour'] as int? ?? 22,
        startMinute: sl['startMinute'] as int? ?? 0,
        endHour: sl['endHour'] as int? ?? 6,
        endMinute: sl['endMinute'] as int? ?? 0,
        durationMinutes: sl['durationMinutes'] as int? ?? 30,
      ).save();
    }

    // Equalizer (scoped)
    final eq = data['equalizer'] as Map<String, dynamic>?;
    if (eq != null) {
      await ScopedPrefs.setBool('eq_enabled', eq['enabled'] as bool? ?? false);
      await ScopedPrefs.setString('eq_preset', eq['preset'] as String? ?? 'flat');
      await ScopedPrefs.setDouble('eq_bassBoost', (eq['bassBoost'] as num?)?.toDouble() ?? 0.0);
      await ScopedPrefs.setDouble('eq_virtualizer', (eq['virtualizer'] as num?)?.toDouble() ?? 0.0);
      await ScopedPrefs.setDouble('eq_loudnessGain', (eq['loudnessGain'] as num?)?.toDouble() ?? 0.0);
      if (eq['bands'] != null) {
        await ScopedPrefs.setString('eq_bands', eq['bands'] as String);
      }
      if (eq['mono'] != null) await ScopedPrefs.setBool('eq_mono', eq['mono'] as bool);
      if (eq['skipSilence'] != null) await ScopedPrefs.setBool('eq_skipSilence', eq['skipSilence'] as bool);
      if (eq['perItem'] != null) await ScopedPrefs.setBool('eq_perItem', eq['perItem'] as bool);
    }

    // Per-book speeds (scoped)
    final bookSpeeds = data['bookSpeeds'] as Map<String, dynamic>?;
    if (bookSpeeds != null) {
      for (final entry in bookSpeeds.entries) {
        await PlayerSettings.setBookSpeed(entry.key, (entry.value as num).toDouble());
      }
    }

    // Offline mode (global)
    if (data['offlineMode'] != null) {
      await prefs.setBool('manual_offline_mode', data['offlineMode'] as bool);
    }

    // Notes (scoped)
    final notes = data['notes'] as Map<String, dynamic>?;
    if (notes != null) {
      for (final entry in notes.entries) {
        await ScopedPrefs.setString('notes_${entry.key}', entry.value as String);
      }
    }

    // Saved ebooks (scoped)
    final savedEbooks = data['savedEbooks'] as List<dynamic>?;
    if (savedEbooks != null && savedEbooks.isNotEmpty) {
      await ScopedPrefs.setStringList('saved_ebooks', savedEbooks.cast<String>());
    }

    // Rolling download series (scoped)
    final rollingDownloadSeries = data['rollingDownloadSeries'] as List<dynamic>?;
    if (rollingDownloadSeries != null && rollingDownloadSeries.isNotEmpty) {
      await ScopedPrefs.setStringList(
        'rolling_download_series',
        rollingDownloadSeries.cast<String>(),
      );
    }

    // Podcast subscriptions + Absorbing manual list (scoped)
    final subscribedPodcasts = data['subscribedPodcasts'] as List<dynamic>?;
    if (subscribedPodcasts != null) {
      await ScopedPrefs.setStringList('subscribed_podcasts', subscribedPodcasts.cast<String>());
    }
    final absorbingManualAdds = data['absorbingManualAdds'] as List<dynamic>?;
    if (absorbingManualAdds != null) {
      await ScopedPrefs.setStringList('absorbing_manual_adds', absorbingManualAdds.cast<String>());
    }
    final absorbingFinishedManualAdds =
        data['absorbingFinishedManualAdds'] as List<dynamic>?;
    if (absorbingFinishedManualAdds != null) {
      await ScopedPrefs.setStringList(
        'absorbing_finished_manual_adds',
        absorbingFinishedManualAdds.cast<String>(),
      );
    }
    final absorbingManualRemoves = data['absorbingManualRemoves'] as List<dynamic>?;
    if (absorbingManualRemoves != null) {
      await ScopedPrefs.setStringList('absorbing_manual_removes', absorbingManualRemoves.cast<String>());
    }

    // Pending offline state (scoped) - so offline changes still push after restore
    final pendingSyncs = data['pendingSyncs'] as List<dynamic>?;
    if (pendingSyncs != null && pendingSyncs.isNotEmpty) {
      await ScopedPrefs.setStringList('pending_syncs', pendingSyncs.cast<String>());
    }
    final pendingOfflineListening = data['pendingOfflineListening'] as List<dynamic>?;
    if (pendingOfflineListening != null && pendingOfflineListening.isNotEmpty) {
      await ScopedPrefs.setStringList('pending_offline_listening', pendingOfflineListening.cast<String>());
    }
    final bmpc = data['bookmarksPendingCreates'] as String?;
    if (bmpc != null) await ScopedPrefs.setString('bookmarks_pending_creates', bmpc);
    final bmpd = data['bookmarksPendingDeletes'] as String?;
    if (bmpd != null) await ScopedPrefs.setString('bookmarks_pending_deletes', bmpd);
    final pep = data['pendingEbookProgress'] as String?;
    if (pep != null) await ScopedPrefs.setString('pending_ebook_progress', pep);

    // Offline listening accumulators (scoped, per-item) - write through SharedPreferences
    // directly because ScopedPrefs doesn't expose setInt with scope handling here.
    final offlineListening = data['offlineListening'] as Map<String, dynamic>?;
    if (offlineListening != null && offlineListening.isNotEmpty) {
      final scope = UserAccountService().activeScopeKey;
      final prefix = scope.isNotEmpty ? '$scope:offline_listening_' : 'offline_listening_';
      for (final entry in offlineListening.entries) {
        await prefs.setInt('$prefix${entry.key}', (entry.value as num).toInt());
      }
    }

    // RMAB integration config (scoped)
    final rmab = data['rmab'] as Map<String, dynamic>?;
    if (rmab != null) {
      final baseUrl = rmab['baseUrl'] as String?;
      if (baseUrl != null) await ScopedPrefs.setString('rmab_base_url', baseUrl);
      final apiToken = rmab['apiToken'] as String?;
      if (apiToken != null) await ScopedPrefs.setString('rmab_api_token', apiToken);
      final legacyUrl = rmab['legacyUrl'] as String?;
      if (legacyUrl != null) await ScopedPrefs.setString('rmab_url', legacyUrl);
      final customHeaders = rmab['customHeaders'] as String?;
      if (customHeaders != null) {
        await ScopedPrefs.setString('rmab_custom_headers', customHeaders);
      }
    }

    // Home screen layout per library (scoped)
    final homeLayouts = data['homeLayouts'] as Map<String, dynamic>?;
    if (homeLayouts != null) {
      for (final entry in homeLayouts.entries) {
        final libId = entry.key;
        final layout = entry.value as Map<String, dynamic>;
        final order = layout['order'] as List<dynamic>?;
        final hidden = layout['hidden'] as List<dynamic>?;
        final genres = layout['genres'] as List<dynamic>?;
        if (order != null) await ScopedPrefs.setStringList('home_section_order_$libId', order.cast<String>());
        if (hidden != null) await ScopedPrefs.setStringList('home_hidden_sections_$libId', hidden.cast<String>());
        if (genres != null) await ScopedPrefs.setStringList('home_genre_sections_$libId', genres.cast<String>());
      }
    }

    final librarySettings = data['librarySettings'] as Map<String, dynamic>?;
    if (librarySettings != null) {
      final scope = UserAccountService().activeScopeKey;
      final scopePrefix = scope.isNotEmpty ? '$scope:' : '';
      final prefixes = [
        '${scopePrefix}rectangleCovers_',
        '${scopePrefix}skipOverrideForward_',
        '${scopePrefix}skipOverrideBack_',
      ];
      final oldKeys = prefs
          .getKeys()
          .where((key) => prefixes.any(key.startsWith))
          .toList();
      for (final key in oldKeys) {
        await prefs.remove(key);
      }
      for (final entry in librarySettings.entries) {
        final libraryId = entry.key;
        final settings = entry.value as Map<String, dynamic>;
        final coverShape = settings['coverShape'] as String?;
        if (coverShape == 'rect' || coverShape == 'square') {
          await PlayerSettings.setRectangleCoversOverride(
            libraryId,
            coverShape,
          );
        }
        final skipForward = (settings['skipForward'] as num?)?.toInt();
        final skipBack = (settings['skipBack'] as num?)?.toInt();
        if (skipForward != null && skipBack != null) {
          await PlayerSettings.setSkipOverride(
            libraryId,
            forward: skipForward,
            back: skipBack,
          );
        }
      }
    }

    // Per-item metadata overrides (scoped)
    final metadataOverrides = data['metadataOverrides'] as Map<String, dynamic>?;
    if (metadataOverrides != null) {
      for (final entry in metadataOverrides.entries) {
        await ScopedPrefs.setString('metadata_override_${entry.key}', entry.value as String);
      }
    }

    // Ebook annotations (scoped, keyed by itemId)
    final ebookAnnotations = data['ebookAnnotations'] as Map<String, dynamic>?;
    if (ebookAnnotations != null) {
      for (final entry in ebookAnnotations.entries) {
        await ScopedPrefs.setString('ebook_annotations_${entry.key}', entry.value as String);
      }
    }

    // E-reader appearance + behavior (scoped)
    final er = data['ereader'] as Map<String, dynamic>?;
    if (er != null) {
      if (er['fontSize'] != null) await ScopedPrefs.setInt('ereader_fontSize', er['fontSize'] as int);
      if (er['lineHeight'] != null) await ScopedPrefs.setDouble('ereader_lineHeight', (er['lineHeight'] as num).toDouble());
      if (er['marginH'] != null) await ScopedPrefs.setInt('ereader_margin_h', er['marginH'] as int);
      if (er['marginV'] != null) await ScopedPrefs.setInt('ereader_margin_v', er['marginV'] as int);
      if (er['spread'] != null) await ScopedPrefs.setInt('ereader_spread', er['spread'] as int);
      if (er['theme'] != null) await ScopedPrefs.setString('ereader_theme', er['theme'] as String);
      if (er['font'] != null) {
        final fontId = er['font'] as String;
        await ScopedPrefs.setString('ereader_font', fontId);
        // The woff2 files aren't in the backup - re-fetch the selected font
        // so the restored choice actually renders.
        final font = readerFontById(fontId);
        if (font != null && font.downloadable) ReaderFontService().download(font);
      }
      if (er['volumeNav'] != null) await PlayerSettings.setEreaderVolumeNav(er['volumeNav'] as String);
      if (er['volumeNavWhilePlaying'] != null) await PlayerSettings.setEreaderVolumeNavWhilePlaying(er['volumeNavWhilePlaying'] as bool);
    }

    // Per-podcast UI prefs (GLOBAL, not scoped)
    final podcastPrefs = data['podcastPrefs'] as Map<String, dynamic>?;
    if (podcastPrefs != null) {
      for (final entry in podcastPrefs.entries) {
        final itemId = entry.key;
        final p = entry.value as Map<String, dynamic>;
        if (p['sortNewest'] != null) await prefs.setBool('podcast_sort_newest_$itemId', p['sortNewest'] as bool);
        if (p['hideFinished'] != null) await prefs.setBool('podcast_hide_finished_$itemId', p['hideFinished'] as bool);
        if (p['advanceDir'] != null) await prefs.setString('podcast_advance_dir_$itemId', p['advanceDir'] as String);
      }
    }

    // Custom download path (GLOBAL)
    final customDownloadPath = data['customDownloadPath'] as String?;
    if (customDownloadPath != null) {
      await prefs.setString('custom_download_path', customDownloadPath);
    }

    PlayerSettings.notifySettingsChanged();
  }
}
