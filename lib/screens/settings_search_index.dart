import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import '../services/wording.dart';

class SettingSearchEntry {
  final String sectionId;    // exact string passed to _keyFor(...)
  final String sectionTitle; // localized section display name
  final String title;        // tile title as rendered
  final List<String> extras; // subtitle variants / description strings
  const SettingSearchEntry(this.sectionId, this.sectionTitle, this.title, this.extras);
}

List<SettingSearchEntry> settingsSearchEntries(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final w = Wording.of(context);
  return [
    // ── Appearance ──
    SettingSearchEntry('Appearance', l.sectionAppearance, l.languageLabel, [l.languageSystemDefault]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.themeLabel, [l.themeDark, l.themeLight, l.themeAuto]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.flatBackgroundLabel, [l.flatBackgroundSubtitle]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.einkModeLabel, [l.einkModeSubtitle]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.backgroundIntensityLabel, const []),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.colorSourceLabel, [l.colorSourceDynamic, l.colorSourceManual, l.colorSourceManualDescription, l.colorSourceCoverDescription, l.colorSourceCustom]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.useColorEverywhereLabel, [l.useColorEverywhereSubtitle]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.startScreenLabel, [l.startScreenSubtitle, l.startScreenHome, l.startScreenLibrary, w.startScreenAbsorb, l.startScreenStats]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.progressTextSize, const []),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.disablePageFade, [l.disablePageFadeOnSubtitle, l.disablePageFadeOffSubtitle]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.showSubtitles, [l.showSubtitlesOnSubtitle, l.showSubtitlesOffSubtitle]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.rectangleBookCovers, [l.rectangleBookCoversOnSubtitle, l.rectangleBookCoversOffSubtitle]),
    SettingSearchEntry('Appearance', l.sectionAppearance, l.coverSize, [l.coverSizeSubtitle, l.coverSizeSmall, l.coverSizeMedium, l.coverSizeLarge]),
    SettingSearchEntry('Appearance', l.sectionAppearance, 'Classic wording', const ['Using "Play", "Now Playing", "Finished"', 'Using "Absorb", "Absorbing", "Fully Absorbed"']),
    if (!(Platform.isIOS && MediaQuery.sizeOf(context).shortestSide >= 600))
      SettingSearchEntry('Appearance', l.sectionAppearance, 'Lock rotation', const ['Screen stays in portrait', 'Screen can rotate with the device']),

    // ── Customize Stats ──
    SettingSearchEntry('Customize Stats', l.settingsCustomizeStats, l.statsGoalTitle, [l.statsGoalDaily, l.statsGoalWeekly, l.statsGoalMonthly, l.statsGoalOff]),
    SettingSearchEntry('Customize Stats', l.settingsCustomizeStats, l.statsWeekStartsOn, [l.absorbingSharedSunday, l.absorbingSharedMonday, l.absorbingSharedSaturday]),
    SettingSearchEntry('Customize Stats', l.settingsCustomizeStats, l.statsBookChallengeTitle, [l.statsBookChallengeDesc]),
    SettingSearchEntry('Customize Stats', l.settingsCustomizeStats, l.statsChartTitle, [l.statsChartBar, l.statsChartLine, l.statsChartDays7, l.statsChartDays30]),
    SettingSearchEntry('Customize Stats', l.settingsCustomizeStats, l.statsSectionsTitle, [l.dragToReorderTapEye]),

    // ── Absorbing Cards ──
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, l.fullScreenPlayer, [l.fullScreenPlayerOnSubtitle, l.fullScreenPlayerOffSubtitle]),
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, l.coverPlayPause, [l.coverPlayPauseOnSubtitle, l.coverPlayPauseOffSubtitle]),
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, l.cardBackground, [l.cardBackgroundBlurred, l.cardBackgroundGradient, l.off]),
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, l.cardScrubbers, [l.cardScrubbersBothSubtitle, l.cardScrubbersChapterSubtitle, l.cardScrubbersLockedSubtitle]),
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, l.speedAdjustedTime, [l.speedAdjustedTimeOnSubtitle, l.speedAdjustedTimeOffSubtitle]),
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, w.mergeLibraries, [w.mergeLibrariesOnSubtitle, w.mergeLibrariesOffSubtitle, l.settingsMergeImpliedByPodcastTab]),
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, l.queueMode, [l.queueModeMergedSubtitle, l.queueModeBooks, l.queueModePodcasts, l.queueModeOff, l.queueModeManual, l.queueModeAuto, l.queueModeSeriesLabel, l.queueModeShowLabel, l.queueModePlaylist]),
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, l.autoDownloadQueue, [l.autoDownloadQueueOffSubtitle]),
    SettingSearchEntry('Absorbing Cards', w.sectionAbsorbingCards, l.resetButtonGrid, const []),

    // ── Playback ──
    SettingSearchEntry('Playback', l.sectionPlayback, l.defaultSpeed, [l.defaultSpeedSubtitle]),
    SettingSearchEntry('Playback', l.sectionPlayback, l.resetSpeedPresets, [l.resetSpeedPresetsSubtitle]),
    SettingSearchEntry('Playback', l.sectionPlayback, l.skipBack, const []),
    SettingSearchEntry('Playback', l.sectionPlayback, l.skipForward, const []),
    SettingSearchEntry('Playback', l.sectionPlayback, l.chapterBarrierOnRewind, [l.chapterBarrierOnRewindOnSubtitle, l.chapterBarrierOnRewindOffSubtitle]),
    SettingSearchEntry('Playback', l.sectionPlayback, l.longSkipButtons, [l.longSkipButtonsOnSubtitle, l.longSkipButtonsOffSubtitle]),
    SettingSearchEntry('Playback', l.sectionPlayback, l.longSkipBack, const []),
    SettingSearchEntry('Playback', l.sectionPlayback, l.longSkipForward, const []),
    SettingSearchEntry('Playback', l.sectionPlayback, l.autoRewindOnResume, [l.autoRewindOffSubtitle]),
    SettingSearchEntry('Playback', l.sectionPlayback, l.rewindRange, const []),
    SettingSearchEntry('Playback', l.sectionPlayback, l.rewindAfterPausedFor, [l.rewindAnyPause, l.rewindAlwaysDescription]),
    SettingSearchEntry('Playback', l.sectionPlayback, l.chapterBarrier, [l.chapterBarrierSubtitle]),
    SettingSearchEntry('Playback', l.sectionPlayback, l.rewindOnSessionStart, [l.autoRewindOffSubtitle]),

    // ── Media Controls ──
    SettingSearchEntry('Media Controls', l.sectionMediaControls, l.chapterProgressInNotification, [l.chapterProgressInNotificationIos, l.chapterProgressOnSubtitle, l.chapterProgressOnSubtitleIos, l.chapterProgressOffSubtitle]),
    SettingSearchEntry('Media Controls', l.sectionMediaControls, l.lockSeekBar, [l.lockSeekBarOnSubtitle, l.lockSeekBarOffSubtitle]),
    SettingSearchEntry(
        'Media Controls',
        l.sectionMediaControls,
        Platform.isIOS ? l.carConnectAutoplayIos : l.carConnectAutoplay,
        [l.carConnectAutoplayOnSubtitle, l.carConnectAutoplayOffSubtitle]),
    if (Platform.isAndroid) ...[
      SettingSearchEntry('Media Controls', l.sectionMediaControls, 'Duck brief interruptions', const ['Notifications and prompts lower the volume instead of pausing', 'Notifications and prompts pause playback']),
      SettingSearchEntry('Media Controls', l.sectionMediaControls, l.speedBookmarkInControls, [l.speedBookmarkOnSubtitle, l.speedBookmarkOffSubtitle]),
    ],

    // ── Sleep Timer ──
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.shakeDuringSleepTimer, [l.shakeOff, l.shakeAddTime, l.shakeReset]),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.shakeSensitivity, [l.shakeSensitivityVeryLow, l.shakeSensitivityLow, l.shakeSensitivityMedium, l.shakeSensitivityHigh, l.shakeSensitivityVeryHigh]),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.buttonDuringSleepTimer, [l.shakeOff, l.shakeAddTime, l.shakeReset, l.buttonDuringSleepTimerHint]),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.sleepAddAmount, const []),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.resetTimerOnPause, [l.resetTimerOnPauseOnSubtitle, l.resetTimerOnPauseOffSubtitle]),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.sleepTimerSheetRewindOnSleep, const []),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.fadeVolumeBeforeSleep, [l.fadeVolumeOffSubtitle]),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.chimeBeforeSleep, [l.chimeBeforeSleepOnSubtitle, l.chimeBeforeSleepOffSubtitle]),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.windDownDuration, const []),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.autoSleepTimer, [l.autoSleepTimerOffSubtitle]),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.windowStart, const []),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.windowEnd, const []),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.endOfChapterShort, [l.endOfChapterOnSubtitle, l.endOfChapterOffSubtitle]),
    SettingSearchEntry('Sleep Timer', l.sectionSleepTimer, l.timerDuration, const []),

    // ── Downloads & Storage ──
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, l.downloadOverWifiOnly, [l.downloadOverWifiOnSubtitle, l.downloadOverWifiOffSubtitle]),
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, l.autoDownloadOnWifi, [l.autoDownloadOnWifiOnSubtitle, l.autoDownloadOnWifiOffSubtitle]),
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, 'Auto-download series', const ['Starting a book in a series keeps the next books downloaded', 'Turn on series downloads yourself from the series menu']),
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, l.concurrentDownloads, const []),
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, l.autoDownload, [l.autoDownloadSubtitle]),
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, l.keepNext, const []),
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, w.deleteAbsorbedDownloads, [l.deleteAbsorbedOnSubtitle, l.deleteAbsorbedOffSubtitle]),
    if (!Platform.isIOS)
      SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, l.downloadLocation, const []),
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, l.manageDownloads, const []),
    SettingSearchEntry('Downloads & Storage', l.sectionDownloadsAndStorage, l.streamingCache, [l.streamingCacheOffSubtitle, l.streamingCacheOff, l.clearCache]),

    // ── Library ──
    SettingSearchEntry('Library', l.sectionLibrary, l.settingsPodcastTab, [l.settingsPodcastTabDesc]),
    SettingSearchEntry('Library', l.sectionLibrary, l.settingsPodcastTabLibrary, const []),
    SettingSearchEntry('Library', l.sectionLibrary, l.hideEbookOnlyTitles, [l.hideEbookOnlyOnSubtitle, l.hideEbookOnlyOffSubtitle]),
    SettingSearchEntry('Library', l.sectionLibrary, l.showGoodreadsButton, [l.showGoodreadsOnSubtitle, l.showGoodreadsOffSubtitle]),
    SettingSearchEntry('Library', l.sectionLibrary, l.showExplicitBadge, [l.showExplicitBadgeOnSubtitle, l.showExplicitBadgeOffSubtitle]),
    SettingSearchEntry('Library', l.sectionLibrary, l.coverShapeLabel, [l.coverShapeDefault, l.coverShapeSquare, l.coverShapeRectangle]),
    SettingSearchEntry('Library', l.sectionLibrary, l.subtitleVisibilityLabel, [l.subtitleVisibilityDefault, l.subtitleVisibilityShow, l.subtitleVisibilityHide]),
    SettingSearchEntry('Library', l.sectionLibrary, l.currentLibrarySkipOverride, [l.currentLibrarySkipOverrideOnSubtitle, l.currentLibrarySkipOverrideOffSubtitle]),
    SettingSearchEntry('Library', l.sectionLibrary, l.currentLibrarySkipBack, const []),
    SettingSearchEntry('Library', l.sectionLibrary, l.currentLibrarySkipForward, const []),

    // ── Permissions ──
    SettingSearchEntry('Permissions', l.sectionPermissions, l.notifications, [l.notificationsSubtitle]),
    if (Platform.isAndroid) ...[
      SettingSearchEntry('Permissions', l.sectionPermissions, l.settingsEpisodeNotifs, [l.settingsEpisodeNotifsDesc]),
      SettingSearchEntry('Permissions', l.sectionPermissions, l.unrestrictedBattery, [l.unrestrictedBatterySubtitle]),
    ],

    // ── Issues & Support ──
    SettingSearchEntry('Issues & Support', l.sectionIssuesAndSupport, l.showTipsAgain, [l.showTipsAgainSubtitle]),
    SettingSearchEntry('Issues & Support', l.sectionIssuesAndSupport, l.bugsAndFeatureRequests, [l.bugsAndFeatureRequestsSubtitle]),
    SettingSearchEntry('Issues & Support', l.sectionIssuesAndSupport, l.joinDiscord, [l.joinDiscordSubtitle]),
    SettingSearchEntry('Issues & Support', l.sectionIssuesAndSupport, l.contact, [l.contactSubtitle]),
    SettingSearchEntry('Issues & Support', l.sectionIssuesAndSupport, l.enableLogging, [l.enableLoggingOnSubtitle, l.enableLoggingOffSubtitle]),
    SettingSearchEntry('Issues & Support', l.sectionIssuesAndSupport, l.sendLogs, [l.sendLogsSubtitle]),
    SettingSearchEntry('Issues & Support', l.sectionIssuesAndSupport, l.clearLogs, const []),

    // ── Advanced ──
    SettingSearchEntry('Advanced', l.sectionAdvanced, l.navHoldSettingTitle, [l.navHoldSettingSubtitle]),
    SettingSearchEntry('Advanced', l.sectionAdvanced, l.localServer, [l.localServerOnConnectedSubtitle, l.localServerOnRemoteSubtitle, l.localServerOffSubtitle, l.localServerUrlLabel]),
    SettingSearchEntry('Advanced', l.sectionAdvanced, l.trustAllCertificates, [l.trustAllCertificatesOnSubtitle, l.trustAllCertificatesOffSubtitle]),
    if (Platform.isAndroid)
      SettingSearchEntry('Advanced', l.sectionAdvanced, l.mp3IndexSeeking, [l.mp3IndexSeekingOnSubtitle, l.mp3IndexSeekingOffSubtitle]),
    if (const bool.fromEnvironment('GITHUB_BUILD'))
      SettingSearchEntry('Advanced', l.sectionAdvanced, l.includePreReleases, [l.includePreReleasesOnSubtitle, l.includePreReleasesOffSubtitle]),
    SettingSearchEntry('Advanced', l.sectionAdvanced, l.adminRmab, [l.adminRmabConnected, l.adminRmabAskAdmin]),
    SettingSearchEntry('Advanced', l.sectionAdvanced, l.transcriptionTitle, [l.transcriptionAdvancedSubtitle]),
  ];
}
