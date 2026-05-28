import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer;
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/sleep_timer_service.dart';
import '../services/user_account_service.dart';
import '../services/backup_service.dart';
import '../services/log_service.dart';
import '../services/scoped_prefs.dart';
import '../screens/login_screen.dart';
import '../screens/app_shell.dart';
import '../services/update_checker_service.dart';
import '../widgets/update_dialog.dart';
import '../screens/admin_screen.dart';
import '../screens/downloads_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../main.dart' show applyThemeMode, applyTrustAllCerts, localeNotifier, oledNotifier, snappyTransitionsNotifier;
import '../services/wording.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/absorb_slider.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/tips_sheet.dart';
import '../widgets/feature_hint.dart';
import '../widgets/welcome_sheet.dart';
import '../widgets/rmab_config_sheet.dart';
import '../widgets/queue_playlist_picker_sheet.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _isPlayStoreBuild = bool.fromEnvironment('PLAYSTORE_BUILD');
  static const _isGithubBuild = bool.fromEnvironment('GITHUB_BUILD');
  AutoRewindSettings _rewindSettings = const AutoRewindSettings();
  double _defaultSpeed = 1.0;
  bool _wifiOnlyDownloads = false;
  bool _autoDownloadOnStream = false;
  int _rollingDownloadCount = 3;
  bool _rollingDownloadDeleteFinished = false;
  bool _showBookSlider = false;
  bool _notifChapterProgress = false;
  bool _speedAdjustedTime = true;
  int _forwardSkip = 30;
  int _backSkip = 10;
  bool _skipChapterBarrier = true;
  String _shakeMode = 'addTime';
  bool _resetSleepOnPause = false;
  bool _sleepFadeOut = true;
  int _sleepFadeDuration = 30;
  bool _sleepChime = false;
  double _sleepChimeVolume = 0.7;
  int _shakeAddMinutes = 5;
  String _shakeSensitivity = 'medium';
  String _bookQueueMode = 'off';
  String _podcastQueueMode = 'off';
  String? _queuePlaylistId;
  // Returns the more restrictive of the two modes so the merged control
  // never shows 'Auto' if one type is still 'off' or 'manual'. Playlist
  // mode is set atomically on both, so if either is 'playlist' the merged
  // value is 'playlist'.
  String get _mergedQueueMode {
    if (_bookQueueMode == 'playlist' || _podcastQueueMode == 'playlist') {
      return 'playlist';
    }
    const order = ['off', 'manual', 'auto_next'];
    final bi = order.indexOf(_bookQueueMode);
    final pi = order.indexOf(_podcastQueueMode);
    return order[(bi < pi ? bi : pi).clamp(0, 2)];
  }
  bool _queueAutoDownload = false;
  bool _mergeAbsorbingLibraries = false;
  int _maxConcurrentDownloads = 1;
  bool _hideEbookOnly = false;
  bool _showGoodreadsButton = false;
  bool _showExplicitBadge = true;
  bool _loggingEnabled = false;
  bool _fullScreenPlayer = false;
  // card button layout is now managed in the edit sheet (more menu)
  bool _snappyTransitions = false;
  bool _classicWording = false;
  bool _rectangleCovers = false;
  bool _coverPlayButton = false;
  String _themeMode = 'dark';
  String _language = '';
  int _startScreen = 2;
  int _streamingCacheSizeMb = 0;
  bool _localServerEnabled = false;
  String _localServerUrl = '';
  late final TextEditingController _localServerController;
  bool _trustAllCerts = false;
  bool _includePreReleases = false;
  String? _rmabBaseUrl;
  String? _rmabApiToken;
  bool _loaded = false;
  String _downloadLocationLabel = 'App Internal Storage (Default)';
  bool _canPickDownloadLocation = false;
  int _totalDownloadSizeBytes = 0;
  int _deviceTotalBytes = 0;
  int _deviceAvailableBytes = 0;
  AutoSleepSettings _autoSleepSettings = const AutoSleepSettings();
  String _appVersion = '';
  String? _expandedSection;
  final Map<String, GlobalKey> _sectionKeys = {};

  GlobalKey _keyFor(String section) => _sectionKeys.putIfAbsent(section, () => GlobalKey());

  void _onSectionExpanded(String section, bool expanded) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (expanded) {
          _expandedSection = section;
        } else if (_expandedSection == section) {
          _expandedSection = null;
        }
      });
      if (expanded) {
        Future.delayed(const Duration(milliseconds: 350), () {
          final ctx = _keyFor(section).currentContext;
          if (ctx != null && mounted) {
            Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeOut, alignment: 0.3);
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _localServerController = TextEditingController();
    _loadSettings();
    PlayerSettings.settingsChanged.addListener(_onExternalSettingsChange);
  }

  @override
  void dispose() {
    PlayerSettings.settingsChanged.removeListener(_onExternalSettingsChange);
    _localServerController.dispose();
    super.dispose();
  }

  void _onExternalSettingsChange() async {
    final bookMode = await PlayerSettings.getBookQueueMode();
    final podMode = await PlayerSettings.getPodcastQueueMode();
    final qpId = await PlayerSettings.getQueuePlaylistId();
    if (mounted) {
      setState(() {
        _bookQueueMode = bookMode;
        _podcastQueueMode = podMode;
        _queuePlaylistId = qpId;
      });
    }
  }

  Future<void> _enterPlaylistMode() async {
    final id = _queuePlaylistId;
    if (id == null) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      showOverlayToast(context, l.queueModePlaylistHint,
          icon: Icons.playlist_play_rounded);
      return;
    }
    await PlayerSettings.setQueueModePlaylist(id);
    if (!mounted) return;
    setState(() {
      _bookQueueMode = 'playlist';
      _podcastQueueMode = 'playlist';
    });
  }

  Future<void> _setBookQueueMode(String mode) async {
    if (mode == 'playlist') return _enterPlaylistMode();
    final wasPlaylist =
        _bookQueueMode == 'playlist' || _podcastQueueMode == 'playlist';
    await PlayerSettings.setBookQueueMode(mode);
    if (wasPlaylist) {
      await PlayerSettings.setPodcastQueueMode(mode);
    }
    if (!mounted) return;
    setState(() {
      _bookQueueMode = mode;
      if (wasPlaylist) _podcastQueueMode = mode;
    });
    PlayerSettings.notifySettingsChanged();
  }

  Future<void> _setPodcastQueueMode(String mode) async {
    if (mode == 'playlist') return _enterPlaylistMode();
    final wasPlaylist =
        _bookQueueMode == 'playlist' || _podcastQueueMode == 'playlist';
    await PlayerSettings.setPodcastQueueMode(mode);
    if (wasPlaylist) {
      await PlayerSettings.setBookQueueMode(mode);
    }
    if (!mounted) return;
    setState(() {
      _podcastQueueMode = mode;
      if (wasPlaylist) _bookQueueMode = mode;
    });
    PlayerSettings.notifySettingsChanged();
  }

  Widget _buildActivePlaylistRow(
    ColorScheme cs,
    TextTheme tt,
    LibraryProvider lib,
    AppLocalizations l,
  ) {
    String name = l.queuePlaylistNone;
    if (_queuePlaylistId != null) {
      final match = lib.playlists.cast<Map<String, dynamic>>().where(
        (p) => p['id'] == _queuePlaylistId,
      ).firstOrNull;
      final n = match?['name'] as String?;
      if (n != null && n.isNotEmpty) name = n;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.playlist_play_rounded, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(
          name,
          style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        )),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 16),
          color: cs.onPrimaryContainer.withValues(alpha: 0.7),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          visualDensity: VisualDensity.compact,
          tooltip: l.exit,
          onPressed: () => PlayerSettings.clearQueueModePlaylist(),
        ),
      ]),
    );
  }

  Future<void> _setMergedQueueMode(String mode) async {
    if (mode == 'playlist') return _enterPlaylistMode();
    await PlayerSettings.setBookQueueMode(mode);
    await PlayerSettings.setPodcastQueueMode(mode);
    if (!mounted) return;
    setState(() {
      _bookQueueMode = mode;
      _podcastQueueMode = mode;
    });
    PlayerSettings.notifySettingsChanged();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      AutoRewindSettings.load(),                              // 0
      PlayerSettings.getDefaultSpeed(),                       // 1
      PlayerSettings.getWifiOnlyDownloads(),                  // 2
      PlayerSettings.getRollingDownloadCount(),                // 3
      PlayerSettings.getRollingDownloadDeleteFinished(),       // 4
      PlayerSettings.getShowBookSlider(),                     // 5
      PlayerSettings.getNotificationChapterProgress(),        // 6
      PlayerSettings.getSpeedAdjustedTime(),                  // 7
      PlayerSettings.getForwardSkip(),                        // 8
      PlayerSettings.getBackSkip(),                           // 9
      PlayerSettings.getShakeMode(),                           // 10
      PlayerSettings.getResetSleepOnPause(),                  // 11
      PlayerSettings.getSleepFadeOut(),                       // 12
      PlayerSettings.getShakeAddMinutes(),                    // 13
      PlayerSettings.getBookQueueMode(),                      // 14
      PlayerSettings.getQueueAutoDownload(),                  // 15
      PlayerSettings.getMergeAbsorbingLibraries(),            // 16
      PlayerSettings.getMaxConcurrentDownloads(),             // 17
      PlayerSettings.getHideEbookOnly(),                      // 18
      PlayerSettings.getShowGoodreadsButton(),                // 19
      PlayerSettings.getLoggingEnabled(),                     // 20
      PlayerSettings.getFullScreenPlayer(),                   // 21
      PlayerSettings.getThemeMode(),                          // 22
      PlayerSettings.getSnappyTransitions(),                  // 23
      DownloadService().downloadLocationLabel,                // 24
      DownloadService().totalDownloadSize,                    // 25
      DownloadService.getDeviceStorage(),                     // 26
      AutoSleepSettings.load(),                               // 27
      PackageInfo.fromPlatform(),                             // 29
      PlayerSettings.getStreamingCacheSizeMb(),               // 30
      PlayerSettings.getLocalServerEnabled(),                  // 31
      PlayerSettings.getLocalServerUrl(),                      // 32
      PlayerSettings.getAutoDownloadOnStream(),                  // 33
      PlayerSettings.getStartScreen(),                           // 36
      PlayerSettings.getPodcastQueueMode(),                      // 37
      Future.value(''),                                              // 38 (unused, kept for index stability)
      PlayerSettings.getRectangleCovers(),                           // 39
      PlayerSettings.getTrustAllCerts(),                               // 40
      PlayerSettings.getCoverPlayButton(),                             // 41
      PlayerSettings.getSkipChapterBarrier(),                            // 42
      PlayerSettings.getShowExplicitBadge(),                               // 43
      PlayerSettings.getIncludePreReleases(),                               // 44
      PlayerSettings.getSleepFadeDuration(),                                  // 45
      PlayerSettings.getSleepChime(),                                         // 46
      PlayerSettings.getSleepChimeVolume(),                                   // 47
      PlayerSettings.getShakeSensitivity(),                                   // 48
      PlayerSettings.getLanguage(),                                           // 49
      PlayerSettings.getClassicWording(),                                     // 50
      PlayerSettings.getQueuePlaylistId(),                                    // 51
    ]);
    final s = results[0] as AutoRewindSettings;
    final speed = results[1] as double;
    final wifiOnly = results[2] as bool;
    final rollingCount = results[3] as int;
    final rollingDelete = results[4] as bool;
    final bookSlider = results[5] as bool;
    final notifChapter = results[6] as bool;
    final speedAdj = results[7] as bool;
    final fwd = results[8] as int;
    final bk = results[9] as int;
    final shake = results[10] as String;
    final resetOnPause = results[11] as bool;
    final sleepFade = results[12] as bool;
    final shakeMins = results[13] as int;
    final bookQueueMode = results[14] as String;
    final queueAutoDl = results[15] as bool;
    final mergeLibs = results[16] as bool;
    final maxConc = results[17] as int;
    final hideEbook = results[18] as bool;
    final showGoodreads = results[19] as bool;
    final logging = results[20] as bool;
    final fullScreen = results[21] as bool;
    final theme = results[22] as String;
    final snappyTrans = results[23] as bool;
    final dlLabel = results[24] as String;
    final dlSize = results[25] as int;
    final deviceStorage = results[26] as Map<String, int>?;
    final autoSleep = results[27] as AutoSleepSettings;
    final pkgInfo = results[28] as PackageInfo;
    final cacheSizeMb = results[29] as int;
    final localEnabled = results[30] as bool;
    final localUrl = results[31] as String;
    final autoDlStream = results[32] as bool;
    final startScreen = results[33] as int;
    final podcastQueueMode = results[34] as String;
    // results[35] was cardButtonLayout, now unused
    final rectCovers = results[36] as bool;
    final trustCerts = results[37] as bool;
    final coverPlay = results[38] as bool;
    final skipBarrier = results[39] as bool;
    final showExplicit = results[40] as bool;
    final preReleases = results[41] as bool;
    final fadeDur = results[42] as int;
    final chime = results[43] as bool;
    final chimeVol = results[44] as double;
    final shakeSens = results[45] as String;
    final language = results[46] as String;
    final classicWording = results[47] as bool;
    final qpId = results[48] as String?;
    final rmabBaseUrl = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final rmabApiToken = await ScopedPrefs.getString(kRmabApiTokenKey);
    if (mounted) setState(() {
      _rmabBaseUrl = rmabBaseUrl;
      _rmabApiToken = rmabApiToken;
      _rewindSettings = s;
      _defaultSpeed = speed;
      _wifiOnlyDownloads = wifiOnly;
      _autoDownloadOnStream = autoDlStream;
      _rollingDownloadCount = rollingCount;
      _rollingDownloadDeleteFinished = rollingDelete;
      _showBookSlider = bookSlider;
      _notifChapterProgress = notifChapter;
      _speedAdjustedTime = speedAdj;
      _forwardSkip = fwd;
      _backSkip = bk;
      _shakeMode = shake;
      _resetSleepOnPause = resetOnPause;
      _sleepFadeOut = sleepFade;
      _shakeAddMinutes = shakeMins;
      _bookQueueMode = bookQueueMode;
      _podcastQueueMode = podcastQueueMode;
      _queuePlaylistId = qpId;
      _queueAutoDownload = queueAutoDl;
      _mergeAbsorbingLibraries = mergeLibs;
      _maxConcurrentDownloads = maxConc;
      _hideEbookOnly = hideEbook;
      _showGoodreadsButton = showGoodreads;
      _loggingEnabled = logging;
      _fullScreenPlayer = fullScreen;
      _snappyTransitions = snappyTrans;
      _classicWording = classicWording;
      _themeMode = theme;
      _downloadLocationLabel = dlLabel;
      _totalDownloadSizeBytes = dlSize;
      if (deviceStorage != null) {
        _deviceTotalBytes = deviceStorage['totalBytes']!;
        _deviceAvailableBytes = deviceStorage['availableBytes']!;
      }
      _autoSleepSettings = autoSleep;
      _appVersion = pkgInfo.version;
      _streamingCacheSizeMb = cacheSizeMb;
      _localServerEnabled = localEnabled;
      _localServerUrl = localUrl;
      _localServerController.text = localUrl;
      _startScreen = startScreen;
      // cardBtnLayout removed (now managed in edit sheet)
      _rectangleCovers = rectCovers;
      _coverPlayButton = coverPlay;
      _skipChapterBarrier = skipBarrier;
      _trustAllCerts = trustCerts;
      _showExplicitBadge = showExplicit;
      _includePreReleases = preReleases;
      _sleepFadeDuration = fadeDur;
      _sleepChime = chime;
      _sleepChimeVolume = chimeVol;
      _shakeSensitivity = shakeSens;
      _language = language;
      _canPickDownloadLocation = !_isPlayStoreBuild;

      _loaded = true;
    });
  }

  static const _shakeSensitivityKeys = ['veryLow', 'low', 'medium', 'high', 'veryHigh'];

  int _shakeSensitivityIndex(String key) {
    final i = _shakeSensitivityKeys.indexOf(key);
    return i < 0 ? 2 : i;
  }

  String _shakeSensitivityKey(int index) =>
      _shakeSensitivityKeys[index.clamp(0, _shakeSensitivityKeys.length - 1)];

  String _shakeSensitivityLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'veryLow': return l.shakeSensitivityVeryLow;
      case 'low': return l.shakeSensitivityLow;
      case 'high': return l.shakeSensitivityHigh;
      case 'veryHigh': return l.shakeSensitivityVeryHigh;
      case 'medium':
      default: return l.shakeSensitivityMedium;
    }
  }

  /// Display name for a language code, in that language's own script.
  /// Empty string => "System default" in the active locale.
  String _languageDisplayName(String code, AppLocalizations l) {
    switch (code) {
      case 'en': return 'English';
      case 'de': return 'Deutsch';
      case 'zh': return '中文';
      default: return l.languageSystemDefault;
    }
  }

  Future<void> _pickLanguage() async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    const codes = ['', 'en', 'de', 'zh'];

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.languageLabel,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final code in codes)
              RadioListTile<String>(
                value: code,
                groupValue: _language,
                onChanged: (v) => Navigator.pop(ctx, v),
                title: Text(_languageDisplayName(code, l)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://crowdin.com/project/absorb'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  l.languageHelpTranslateInvite,
                  style: tt.bodySmall?.copyWith(
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: cs.primary.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (picked == null || picked == _language) return;
    setState(() => _language = picked);
    await PlayerSettings.setLanguage(picked);
    localeNotifier.value = picked.isEmpty ? null : Locale(picked);
  }

  Widget _infoIcon(String title, String content) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.gotIt))],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(Icons.info_outline_rounded, size: 16, color: cs.onSurfaceVariant),
      ),
    );
  }

  Future<void> _saveRewind(AutoRewindSettings s) async {
    setState(() => _rewindSettings = s);
    await s.save();
  }

  Future<void> _saveLocalServerUrl(AuthProvider auth, AppLocalizations l) async {
    final url = _localServerController.text.trim();
    if (url.isEmpty) return;
    _localServerUrl = url;
    await auth.setLocalServerConfig(enabled: _localServerEnabled, url: _localServerUrl);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.localServerUrlSetSnackbar),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    await auth.checkLocalServer();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();
    final lib = context.watch<LibraryProvider>();
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: oledNotifier.value ? null : BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.35, 1.0],
            colors: [
              cs.primary.withValues(alpha: 0.10),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
        child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AbsorbPageHeader(
              title: l.settingsTitle,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ── Tips & Tricks ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GestureDetector(
                    onTap: () => showTipsSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: oledNotifier.value ? null : LinearGradient(
                          colors: [cs.primaryContainer, cs.tertiaryContainer],
                        ),
                        color: oledNotifier.value ? cs.surfaceContainerHigh : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: cs.onPrimaryContainer, size: 22),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.tipsAndHiddenFeatures, style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
                              const SizedBox(height: 2),
                              Text(l.tipsSubtitle, style: tt.bodySmall?.copyWith(
                                color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
                            ],
                          )),
                          Icon(Icons.chevron_right_rounded, color: cs.onPrimaryContainer.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── User Profile ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: GestureDetector(
                    onTap: () => _showAccountSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cs.primary.withValues(alpha: 0.12),
                            cs.primary.withValues(alpha: 0.04),
                          ],
                        ),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.person_rounded, size: 22, color: cs.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Flexible(child: Text(auth.username ?? l.userFallback, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis)),
                            if (auth.isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: auth.isRoot ? Colors.amber.withValues(alpha: 0.12) : cs.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(auth.isRoot ? l.root : l.admin, style: tt.labelSmall?.copyWith(
                                  color: auth.isRoot ? Colors.amber : cs.primary, fontWeight: FontWeight.w600, fontSize: 9)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            auth.serverUrl?.replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), '') ?? '',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                        ])),
                        Icon(Icons.chevron_right_rounded, size: 20, color: cs.primary.withValues(alpha: 0.5)),
                      ]),
                    ),
                  ),
                ),

                // ── Admin Controls ──
                if (auth.isAdmin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Material(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const AdminScreen(),
                          ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: cs.primary, size: 22),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.serverAdmin, style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600)),
                                  Text(l.serverAdminSubtitle,
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                ],
                              )),
                              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Appearance ──
                CollapsibleSection(
                  key: _keyFor('Appearance'),
                  icon: Icons.palette_outlined,
                  title: l.sectionAppearance,
                  cs: cs,
                  isExpanded: _expandedSection == 'Appearance',
                  onExpansionChanged: (v) => _onSectionExpanded('Appearance', v),
                  children: [
                    InkWell(
                      onTap: _loaded ? () => _pickLanguage() : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          children: [
                            Expanded(child: Text(l.languageLabel, style: tt.titleSmall)),
                            Text(
                              _languageDisplayName(_language, l),
                              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.themeLabel, style: tt.titleSmall),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: 'dark', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.themeDark, maxLines: 1))),
                                ButtonSegment(value: 'oled', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.themeOled, maxLines: 1))),
                                ButtonSegment(value: 'light', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.themeLight, maxLines: 1))),
                                ButtonSegment(value: 'system', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.themeAuto, maxLines: 1))),
                              ],
                              selected: {_themeMode},
                              onSelectionChanged: _loaded ? (selected) {
                                final mode = selected.first;
                                setState(() => _themeMode = mode);
                                PlayerSettings.setThemeMode(mode);
                                applyThemeMode(mode);
                              } : null,
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.startScreenLabel, style: tt.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            l.startScreenSubtitle,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<int>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: 0, label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.startScreenHome, maxLines: 1))),
                                ButtonSegment(value: 1, label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.startScreenLibrary, maxLines: 1))),
                                ButtonSegment(value: 2, label: FittedBox(fit: BoxFit.scaleDown, child: Text(Wording.of(context).startScreenAbsorb, maxLines: 1))),
                                ButtonSegment(value: 3, label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.startScreenStats, maxLines: 1))),
                              ],
                              selected: {_startScreen},
                              onSelectionChanged: _loaded ? (selected) {
                                final idx = selected.first;
                                setState(() => _startScreen = idx);
                                PlayerSettings.setStartScreen(idx);
                              } : null,
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.disablePageFade),
                      subtitle: Text(
                        _snappyTransitions ? l.disablePageFadeOnSubtitle : l.disablePageFadeOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _snappyTransitions,
                      onChanged: _loaded ? (v) {
                        setState(() => _snappyTransitions = v);
                        PlayerSettings.setSnappyTransitions(v);
                        snappyTransitionsNotifier.value = v;
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.rectangleBookCovers),
                      subtitle: Text(
                        _rectangleCovers ? l.rectangleBookCoversOnSubtitle : l.rectangleBookCoversOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _rectangleCovers,
                      onChanged: _loaded ? (v) {
                        setState(() => _rectangleCovers = v);
                        PlayerSettings.setRectangleCovers(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text('Classic wording'),
                      subtitle: Text(
                        _classicWording
                            ? 'Using "Play", "Now Playing", "Finished"'
                            : 'Using "Absorb", "Absorbing", "Fully Absorbed"',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _classicWording,
                      onChanged: _loaded ? (v) {
                        setState(() => _classicWording = v);
                        PlayerSettings.setClassicWording(v);
                        classicWordingNotifier.value = v;
                      } : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Absorbing Cards ──
                CollapsibleSection(
                  key: _keyFor('Absorbing Cards'),
                  icon: Icons.style_rounded,
                  title: Wording.of(context).sectionAbsorbingCards,
                  cs: cs,
                  isExpanded: _expandedSection == 'Absorbing Cards',
                  onExpansionChanged: (v) => _onSectionExpanded('Absorbing Cards', v),
                  children: [
                    SwitchListTile(
                      title: Text(l.fullScreenPlayer),
                      subtitle: Text(
                        _fullScreenPlayer ? l.fullScreenPlayerOnSubtitle : l.fullScreenPlayerOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _fullScreenPlayer,
                      onChanged: _loaded ? (v) {
                        setState(() => _fullScreenPlayer = v);
                        PlayerSettings.setFullScreenPlayer(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.coverPlayPause),
                      subtitle: Text(
                        _coverPlayButton ? l.coverPlayPauseOnSubtitle : l.coverPlayPauseOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _coverPlayButton,
                      onChanged: _loaded ? (v) {
                        setState(() => _coverPlayButton = v);
                        PlayerSettings.setCoverPlayButton(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.fullBookScrubber),
                      subtitle: Text(
                        _showBookSlider ? l.fullBookScrubberOnSubtitle : l.fullBookScrubberOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _showBookSlider,
                      onChanged: _loaded ? (v) {
                        setState(() => _showBookSlider = v);
                        PlayerSettings.setShowBookSlider(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.speedAdjustedTime),
                      subtitle: Text(
                        _speedAdjustedTime ? l.speedAdjustedTimeOnSubtitle : l.speedAdjustedTimeOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _speedAdjustedTime,
                      onChanged: _loaded ? (v) {
                        setState(() => _speedAdjustedTime = v);
                        PlayerSettings.setSpeedAdjustedTime(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: classicWordingNotifier,
                      builder: (context, _, __) {
                        final w = Wording.of(context);
                        return SwitchListTile(
                          title: Row(children: [
                            Flexible(child: Text(w.mergeLibraries)),
                            _infoIcon(w.mergeLibrariesInfoTitle, w.mergeLibrariesInfoContent),
                          ]),
                          subtitle: Text(
                            _mergeAbsorbingLibraries
                                ? w.mergeLibrariesOnSubtitle
                                : w.mergeLibrariesOffSubtitle,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          value: _mergeAbsorbingLibraries,
                          onChanged: _loaded ? (v) {
                            setState(() => _mergeAbsorbingLibraries = v);
                            PlayerSettings.setMergeAbsorbingLibraries(v);
                          } : null,
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(l.queueMode, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l.queueModeInfoTitle),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.queueModeInfoOff, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(l.queueModeInfoOffDesc),
                                    const SizedBox(height: 12),
                                    Text(l.queueModeInfoManual, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(Wording.of(ctx).queueModeInfoManualDesc),
                                    const SizedBox(height: 12),
                                    Text(l.queueModeInfoSeries, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(l.queueModeInfoSeriesDesc),
                                    const SizedBox(height: 12),
                                    Text(l.queueModeInfoPlaylist, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(l.queueModeInfoPlaylistDesc),
                                  ],
                                ),
                                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.gotIt))],
                              ),
                            ),
                            child: Icon(Icons.info_outline_rounded, size: 16, color: cs.onSurfaceVariant),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        // When libraries are merged, show a single unified control
                        if (_mergeAbsorbingLibraries) ...[
                          Text(l.queueModeMergedSubtitle,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: 'off', icon: const Icon(Icons.stop_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeOff))),
                              ButtonSegment(value: 'manual', icon: const Icon(Icons.queue_music_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeManual))),
                              ButtonSegment(value: 'auto_next', icon: const Icon(Icons.skip_next_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeAuto))),
                              ButtonSegment(value: 'playlist', icon: const Icon(Icons.playlist_play_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModePlaylist))),
                            ],
                            selected: {_mergedQueueMode},
                            onSelectionChanged: _loaded
                                ? (s) { if (s.isNotEmpty) _setMergedQueueMode(s.first); }
                                : null,
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                          )),
                        ] else ...[
                          // Separate controls per type
                          Text(l.queueModeBooks, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          SizedBox(width: double.infinity, child: SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: 'off', icon: const Icon(Icons.stop_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeOff))),
                              ButtonSegment(value: 'manual', icon: const Icon(Icons.queue_music_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeManual))),
                              ButtonSegment(value: 'auto_next', icon: const Icon(Icons.skip_next_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeSeriesLabel))),
                              ButtonSegment(value: 'playlist', icon: const Icon(Icons.playlist_play_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModePlaylist))),
                            ],
                            selected: {_bookQueueMode},
                            onSelectionChanged: _loaded
                                ? (s) { if (s.isNotEmpty) _setBookQueueMode(s.first); }
                                : null,
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                          )),
                          if (lib.libraries.any((lib) => lib['mediaType'] == 'podcast')) ...[
                            const SizedBox(height: 8),
                            Text(l.queueModePodcasts, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            SizedBox(width: double.infinity, child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: 'off', icon: const Icon(Icons.stop_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeOff))),
                                ButtonSegment(value: 'manual', icon: const Icon(Icons.queue_music_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeManual))),
                                ButtonSegment(value: 'auto_next', icon: const Icon(Icons.skip_next_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModeShowLabel))),
                                ButtonSegment(value: 'playlist', icon: const Icon(Icons.playlist_play_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.queueModePlaylist))),
                              ],
                              selected: {_podcastQueueMode},
                              onSelectionChanged: _loaded
                                  ? (s) { if (s.isNotEmpty) _setPodcastQueueMode(s.first); }
                                  : null,
                              style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            )),
                          ],
                        ],
                        if (_bookQueueMode == 'manual' || _podcastQueueMode == 'manual') ...[
                          const SizedBox(height: 4),
                          SwitchListTile(
                            title: Text(l.autoDownloadQueue),
                            subtitle: Text(
                              _queueAutoDownload
                                  ? l.autoDownloadQueueOnSubtitle(_rollingDownloadCount)
                                  : l.autoDownloadQueueOffSubtitle,
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            value: _queueAutoDownload,
                            onChanged: _loaded ? (v) {
                              setState(() => _queueAutoDownload = v);
                              PlayerSettings.setQueueAutoDownload(v);
                            } : null,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ]),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Center(child: TextButton.icon(
                        onPressed: _loaded ? () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l.resetButtonGridQuestion),
                              content: Text(l.resetButtonGridContent),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.reset)),
                              ],
                            ),
                          );
                          if (confirmed != true || !mounted) return;
                          await PlayerSettings.setCardButtonOrder(PlayerSettings.defaultButtonOrder);
                          await PlayerSettings.setCardButtonVisibleCount(PlayerSettings.defaultButtonVisibleCount);
                          await PlayerSettings.setCardIconsOnly(false);
                          await PlayerSettings.setCardMoreInline(false);
                          if (mounted) showOverlayToast(context, l.buttonGridReset, icon: Icons.restart_alt_rounded);
                        } : null,
                        icon: Icon(Icons.restart_alt_rounded, size: 16, color: cs.onSurfaceVariant),
                        label: Text(l.resetButtonGrid, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Playback ──
                CollapsibleSection(
                  key: _keyFor('Playback'),
                  icon: Icons.play_circle_outline_rounded,
                  title: l.sectionPlayback,
                  cs: cs,
                  isExpanded: _expandedSection == 'Playback',
                  onExpansionChanged: (v) => _onSectionExpanded('Playback', v),
                  children: [
                    // Default speed
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.defaultSpeed, style: tt.bodyMedium),
                          Text(l.speedValue(_defaultSpeed.toStringAsFixed(2)),
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700, color: cs.primary)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Text(l.defaultSpeedSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
                    ),
                    AbsorbSlider(
                      value: _defaultSpeed,
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
                      onChanged: _loaded ? (v) {
                        setState(() => _defaultSpeed = double.parse(v.toStringAsFixed(2)));
                        PlayerSettings.setDefaultSpeed(double.parse(v.toStringAsFixed(2)));
                      } : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Wrap(
                        spacing: 6, runSpacing: 4,
                        children: [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0].map((s) {
                          final isActive = (_defaultSpeed - s).abs() < 0.01;
                          return ActionChip(
                            label: Text(l.speedValue(s.toString()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                color: isActive ? cs.onPrimary : cs.onSurface,
                              )),
                            backgroundColor: isActive ? cs.primary : cs.surfaceContainerHighest,
                            side: BorderSide.none,
                            onPressed: () {
                              setState(() => _defaultSpeed = s);
                              PlayerSettings.setDefaultSpeed(s);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
                      title: Text(l.resetSpeedPresets),
                      subtitle: Text(l.resetSpeedPresetsSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      onTap: () async {
                        await PlayerSettings.resetSpeedPresets();
                        if (!mounted) return;
                        showOverlayToast(context, l.speedPresetsReset,
                            icon: Icons.refresh_rounded);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // Skip amounts
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.skipBack, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                          Text(l.secondsValue(_backSkip.toString()), style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600, color: cs.primary)),
                        ],
                      ),
                    ),
                    AbsorbSlider(
                      value: _backSkip.toDouble(),
                      min: 5, max: 60, divisions: 11,
                      onChanged: _loaded ? (v) {
                        setState(() => _backSkip = v.round());
                        PlayerSettings.setBackSkip(v.round());
                      } : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.skipForward, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                          Text(l.secondsValue(_forwardSkip.toString()), style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600, color: cs.primary)),
                        ],
                      ),
                    ),
                    AbsorbSlider(
                      value: _forwardSkip.toDouble(),
                      min: 5, max: 60, divisions: 11,
                      onChanged: _loaded ? (v) {
                        setState(() => _forwardSkip = v.round());
                        PlayerSettings.setForwardSkip(v.round());
                      } : null,
                    ),
                    SwitchListTile(
                      title: Row(children: [
                        Expanded(child: Text(l.chapterBarrierOnRewind)),
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(l.chapterBarrierInfoTitle),
                              content: Text(l.chapterBarrierInfoContent),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.gotIt))],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.info_outline_rounded, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          ),
                        ),
                      ]),
                      subtitle: Text(
                        _skipChapterBarrier ? l.chapterBarrierOnRewindOnSubtitle : l.chapterBarrierOnRewindOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      value: _skipChapterBarrier,
                      onChanged: _loaded ? (v) {
                        setState(() => _skipChapterBarrier = v);
                        PlayerSettings.setSkipChapterBarrier(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.chapterProgressInNotification),
                      subtitle: Text(
                        _notifChapterProgress ? l.chapterProgressOnSubtitle : l.chapterProgressOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _notifChapterProgress,
                      onChanged: _loaded ? (v) {
                        setState(() => _notifChapterProgress = v);
                        PlayerSettings.setNotificationChapterProgress(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // ── Auto-Rewind ──
                    SwitchListTile(
                      title: Text(l.autoRewindOnResume),
                      subtitle: Text(
                        _rewindSettings.enabled
                            ? l.autoRewindOnSubtitleFormat(_rewindSettings.minRewind.round().toString(), _rewindSettings.maxRewind.round().toString())
                            : l.autoRewindOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _rewindSettings.enabled,
                      onChanged: _loaded ? (v) => _saveRewind(
                        AutoRewindSettings(
                          enabled: v,
                          minRewind: _rewindSettings.minRewind,
                          maxRewind: _rewindSettings.maxRewind,
                          activationDelay: _rewindSettings.activationDelay,
                          chapterBarrier: _rewindSettings.chapterBarrier,
                          sessionStartRewind: _rewindSettings.sessionStartRewind,
                        ),
                      ) : null,
                    ),
                    if (_rewindSettings.enabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.rewindRange, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            Text(l.rewindRangeValue(_rewindSettings.minRewind.round().toString(), _rewindSettings.maxRewind.round().toString()),
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                          ],
                        ),
                      ),
                      AbsorbRangeSlider(
                        values: RangeValues(_rewindSettings.minRewind, _rewindSettings.maxRewind),
                        min: 0, max: 60, divisions: 60,
                        onChanged: (v) => _saveRewind(AutoRewindSettings(
                          enabled: true, minRewind: v.start, maxRewind: v.end,
                          activationDelay: _rewindSettings.activationDelay,
                          chapterBarrier: _rewindSettings.chapterBarrier,
                          sessionStartRewind: _rewindSettings.sessionStartRewind,
                        )),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(l.rewindAfterPausedFor,
                              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                            Text(_rewindSettings.activationDelay == 0 ? l.rewindAnyPause : l.rewindActivationDelayValue(_rewindSettings.activationDelay.round().toString()),
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Slider(
                          value: _rewindSettings.activationDelay, min: 0, max: 10, divisions: 10,
                          label: _rewindSettings.activationDelay == 0 ? l.rewindAlwaysLabel : l.secondsValue(_rewindSettings.activationDelay.round().toString()),
                          onChanged: (v) => _saveRewind(AutoRewindSettings(
                            enabled: true, minRewind: _rewindSettings.minRewind,
                            maxRewind: _rewindSettings.maxRewind, activationDelay: v,
                            chapterBarrier: _rewindSettings.chapterBarrier,
                            sessionStartRewind: _rewindSettings.sessionStartRewind,
                          )),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Text(
                          _rewindSettings.activationDelay == 0
                            ? l.rewindAlwaysDescription
                            : l.rewindAfterDescription(_rewindSettings.activationDelay.round().toString()),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: Text(l.chapterBarrier),
                        subtitle: Text(
                          l.chapterBarrierSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        value: _rewindSettings.chapterBarrier,
                        onChanged: (v) => _saveRewind(AutoRewindSettings(
                          enabled: true,
                          minRewind: _rewindSettings.minRewind,
                          maxRewind: _rewindSettings.maxRewind,
                          activationDelay: _rewindSettings.activationDelay,
                          chapterBarrier: v,
                          sessionStartRewind: _rewindSettings.sessionStartRewind,
                        )),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: Row(children: [
                          Expanded(child: Text(l.rewindOnSessionStart)),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(l.rewindOnSessionStart),
                                content: Text(l.rewindOnSessionStartInfoContent),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.gotIt))],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.info_outline_rounded, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                            ),
                          ),
                        ]),
                        subtitle: Text(
                          _rewindSettings.sessionStartRewind
                              ? l.rewindOnSessionStartOnSubtitle(_rewindSettings.maxRewind.round().toString())
                              : l.autoRewindOffSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        value: _rewindSettings.sessionStartRewind,
                        onChanged: (v) => _saveRewind(AutoRewindSettings(
                          enabled: true,
                          minRewind: _rewindSettings.minRewind,
                          maxRewind: _rewindSettings.maxRewind,
                          activationDelay: _rewindSettings.activationDelay,
                          chapterBarrier: _rewindSettings.chapterBarrier,
                          sessionStartRewind: v,
                        )),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.preview, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              ..._buildRewindPreviews(cs, tt, l),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // ── Sleep Timer ──
                CollapsibleSection(
                  key: _keyFor('Sleep Timer'),
                  icon: Icons.bedtime_outlined,
                  title: l.sectionSleepTimer,
                  cs: cs,
                  isExpanded: _expandedSection == 'Sleep Timer',
                  onExpansionChanged: (v) => _onSectionExpanded('Sleep Timer', v),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(l.shakeDuringSleepTimer, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: 'off', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.shakeOff))),
                            ButtonSegment(value: 'addTime', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.shakeAddTime))),
                            ButtonSegment(value: 'resetTimer', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.shakeReset))),
                          ],
                          selected: {_shakeMode},
                          onSelectionChanged: _loaded ? (v) {
                            setState(() => _shakeMode = v.first);
                            PlayerSettings.setShakeMode(v.first);
                            SleepTimerService().restartShakeDetection();
                          } : null,
                        ),
                      ),
                    ),
                    if (_shakeMode != 'off') ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.shakeSensitivity, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            Text(_shakeSensitivityLabel(l, _shakeSensitivity),
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                          ],
                        ),
                      ),
                      AbsorbSlider(
                        value: _shakeSensitivityIndex(_shakeSensitivity).toDouble(),
                        min: 0, max: 4, divisions: 4,
                        onChanged: _loaded ? (v) {
                          final key = _shakeSensitivityKey(v.round());
                          setState(() => _shakeSensitivity = key);
                          PlayerSettings.setShakeSensitivity(key);
                          SleepTimerService().restartShakeDetection();
                        } : null,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_shakeMode == 'addTime') ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.shakeAdds, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            Text(l.shakeAddsValue(_shakeAddMinutes),
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                          ],
                        ),
                      ),
                      AbsorbSlider(
                        value: _shakeAddMinutes.toDouble(),
                        min: 1, max: 30, divisions: 29,
                        onChanged: _loaded ? (v) {
                          setState(() => _shakeAddMinutes = v.round());
                          PlayerSettings.setShakeAddMinutes(v.round());
                        } : null,
                      ),
                      const SizedBox(height: 4),
                    ],
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.resetTimerOnPause),
                      subtitle: Text(
                        _resetSleepOnPause
                            ? l.resetTimerOnPauseOnSubtitle
                            : l.resetTimerOnPauseOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _resetSleepOnPause,
                      onChanged: _loaded ? (v) {
                        setState(() => _resetSleepOnPause = v);
                        PlayerSettings.setResetSleepOnPause(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.fadeVolumeBeforeSleep),
                      subtitle: Text(
                        _sleepFadeOut
                            ? l.fadeVolumeOnSubtitleDynamic(_sleepFadeDuration)
                            : l.fadeVolumeOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _sleepFadeOut,
                      onChanged: _loaded ? (v) {
                        setState(() => _sleepFadeOut = v);
                        PlayerSettings.setSleepFadeOut(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.chimeBeforeSleep),
                      subtitle: Text(
                        _sleepChime
                            ? l.chimeBeforeSleepOnSubtitle
                            : l.chimeBeforeSleepOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _sleepChime,
                      onChanged: _loaded ? (v) {
                        setState(() => _sleepChime = v);
                        PlayerSettings.setSleepChime(v);
                      } : null,
                    ),
                    if (_sleepChime) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          Icon(Icons.volume_down_rounded, size: 18, color: cs.onSurfaceVariant),
                          Expanded(child: Slider(
                            value: _sleepChimeVolume,
                            min: 0.5, max: 3.0, divisions: 10,
                            label: '${(_sleepChimeVolume * 100 / 3).round()}%',
                            onChanged: _loaded ? (v) {
                              setState(() => _sleepChimeVolume = v);
                              PlayerSettings.setSleepChimeVolume(v);
                            } : null,
                          )),
                          Icon(Icons.volume_up_rounded, size: 18, color: cs.onSurfaceVariant),
                        ]),
                      ),
                    ],
                    if (_sleepFadeOut || _sleepChime) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: Text(l.windDownDuration),
                        subtitle: Text(
                          l.windDownDurationSubtitle(_sleepFadeDuration),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          Text(l.secondsValue(_sleepFadeDuration.toString()), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          Expanded(child: Slider(
                            value: _sleepFadeDuration.toDouble(),
                            min: 10, max: 60, divisions: 10,
                            label: l.secondsValue(_sleepFadeDuration.toString()),
                            onChanged: _loaded ? (v) {
                              setState(() => _sleepFadeDuration = v.round());
                              PlayerSettings.setSleepFadeDuration(v.round());
                            } : null,
                          )),
                        ]),
                      ),
                    ],
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // ── Auto Sleep Timer ──
                    SwitchListTile(
                      title: Text(l.autoSleepTimer),
                      subtitle: Text(
                        _autoSleepSettings.enabled
                            ? l.autoSleepTimerEnabledSubtitle(
                                _autoSleepSettings.startLabel,
                                _autoSleepSettings.endLabel,
                                _autoSleepSettings.useEndOfChapter
                                    ? l.endOfChapterShort
                                    : l.shakeAddsValue(_autoSleepSettings.durationMinutes))
                            : l.autoSleepTimerOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _autoSleepSettings.enabled,
                      onChanged: _loaded ? (v) {
                        final updated = _autoSleepSettings.copyWith(enabled: v);
                        setState(() => _autoSleepSettings = updated);
                        updated.save();
                        SleepTimerService().updateAutoSleepSettings(updated);
                      } : null,
                    ),
                    if (_autoSleepSettings.enabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      // Start time picker
                      ListTile(
                        title: Text(l.windowStart),
                        trailing: Text(_autoSleepSettings.startLabel,
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: _autoSleepSettings.startHour, minute: _autoSleepSettings.startMinute),
                          );
                          if (picked != null) {
                            final updated = _autoSleepSettings.copyWith(startHour: picked.hour, startMinute: picked.minute);
                            setState(() => _autoSleepSettings = updated);
                            updated.save();
                            SleepTimerService().updateAutoSleepSettings(updated);
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      // End time picker
                      ListTile(
                        title: Text(l.windowEnd),
                        trailing: Text(_autoSleepSettings.endLabel,
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: _autoSleepSettings.endHour, minute: _autoSleepSettings.endMinute),
                          );
                          if (picked != null) {
                            final updated = _autoSleepSettings.copyWith(endHour: picked.hour, endMinute: picked.minute);
                            setState(() => _autoSleepSettings = updated);
                            updated.save();
                            SleepTimerService().updateAutoSleepSettings(updated);
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      // End of chapter toggle
                      SwitchListTile(
                        title: Text(l.endOfChapterShort),
                        subtitle: Text(
                          _autoSleepSettings.useEndOfChapter
                              ? l.endOfChapterOnSubtitle
                              : l.endOfChapterOffSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        value: _autoSleepSettings.useEndOfChapter,
                        onChanged: _loaded ? (v) {
                          final updated = _autoSleepSettings.copyWith(useEndOfChapter: v);
                          setState(() => _autoSleepSettings = updated);
                          updated.save();
                          SleepTimerService().updateAutoSleepSettings(updated);
                        } : null,
                      ),
                      // Duration slider (only for timed mode)
                      if (!_autoSleepSettings.useEndOfChapter) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.timerDuration, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                              Text(l.shakeAddsValue(_autoSleepSettings.durationMinutes),
                                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                            ],
                          ),
                        ),
                        AbsorbSlider(
                          value: _autoSleepSettings.durationMinutes.toDouble(),
                          min: 5, max: 120, divisions: 23,
                          onChanged: _loaded ? (v) {
                            final updated = _autoSleepSettings.copyWith(durationMinutes: v.round());
                            setState(() => _autoSleepSettings = updated);
                            updated.save();
                            SleepTimerService().updateAutoSleepSettings(updated);
                          } : null,
                        ),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // ── Downloads & Storage ──
                CollapsibleSection(
                  key: _keyFor('Downloads & Storage'),
                  icon: Icons.download_outlined,
                  title: l.sectionDownloadsAndStorage,
                  cs: cs,
                  isExpanded: _expandedSection == 'Downloads & Storage',
                  onExpansionChanged: (v) => _onSectionExpanded('Downloads & Storage', v),
                  children: [
                    SwitchListTile(
                      title: Text(l.downloadOverWifiOnly),
                      subtitle: Text(
                        _wifiOnlyDownloads ? l.downloadOverWifiOnSubtitle : l.downloadOverWifiOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _wifiOnlyDownloads,
                      onChanged: _loaded ? (v) {
                        setState(() => _wifiOnlyDownloads = v);
                        PlayerSettings.setWifiOnlyDownloads(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Row(children: [
                        Flexible(child: Text(l.autoDownloadOnWifi)),
                        _infoIcon(l.autoDownloadOnWifiInfoTitle, l.autoDownloadOnWifiInfoContent),
                      ]),
                      subtitle: Text(
                        _autoDownloadOnStream
                            ? l.autoDownloadOnWifiOnSubtitle
                            : l.autoDownloadOnWifiOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _autoDownloadOnStream,
                      onChanged: _loaded ? (v) {
                        setState(() => _autoDownloadOnStream = v);
                        PlayerSettings.setAutoDownloadOnStream(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(l.concurrentDownloads, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1')),
                              ButtonSegment(value: 2, label: Text('2')),
                              ButtonSegment(value: 3, label: Text('3')),
                              ButtonSegment(value: 4, label: Text('4')),
                              ButtonSegment(value: 5, label: Text('5')),
                            ],
                            selected: {_maxConcurrentDownloads},
                            onSelectionChanged: (v) {
                              setState(() => _maxConcurrentDownloads = v.first);
                              PlayerSettings.setMaxConcurrentDownloads(v.first);
                            },
                          )),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: Text(l.autoDownload),
                      subtitle: Text(
                        l.autoDownloadSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      leading: Icon(Icons.downloading_rounded, color: cs.primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(l.keepNext, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                            _infoIcon(l.keepNextInfoTitle, l.keepNextInfoContent),
                          ]),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 2, label: Text('2')),
                              ButtonSegment(value: 3, label: Text('3')),
                              ButtonSegment(value: 4, label: Text('4')),
                              ButtonSegment(value: 5, label: Text('5')),
                            ],
                            selected: {_rollingDownloadCount},
                            onSelectionChanged: (v) {
                              setState(() => _rollingDownloadCount = v.first);
                              PlayerSettings.setRollingDownloadCount(v.first);
                            },
                          )),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      title: Row(children: [
                        Flexible(child: Text(Wording.of(context).deleteAbsorbedDownloads)),
                        _infoIcon(Wording.of(context).deleteAbsorbedDownloadsInfoTitle, l.deleteAbsorbedDownloadsInfoContent),
                      ]),
                      subtitle: Text(
                        _rollingDownloadDeleteFinished
                            ? l.deleteAbsorbedOnSubtitle
                            : l.deleteAbsorbedOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _rollingDownloadDeleteFinished,
                      onChanged: _loaded ? (v) {
                        setState(() => _rollingDownloadDeleteFinished = v);
                        PlayerSettings.setRollingDownloadDeleteFinished(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    if (!Platform.isIOS && _canPickDownloadLocation)
                    ListTile(
                      leading: Icon(Icons.folder_outlined, color: cs.primary),
                      title: Text(l.downloadLocation),
                      subtitle: Text(
                        _downloadLocationLabel,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickDownloadLocation(context, cs, tt),
                    ),
                    if (_totalDownloadSizeBytes > 0 || _deviceTotalBytes > 0) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.data_usage_rounded, color: cs.onSurfaceVariant),
                        title: Text(l.storageUsed),
                        subtitle: Text(
                          [
                            if (_totalDownloadSizeBytes > 0) l.storageUsedByDownloads(_formatBytes(_totalDownloadSizeBytes)),
                            if (_deviceTotalBytes > 0) l.storageFreeOfTotal(_formatBytes(_deviceAvailableBytes), _formatBytes(_deviceTotalBytes)),
                          ].join('\n'),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        isThreeLine: _totalDownloadSizeBytes > 0 && _deviceTotalBytes > 0,
                      ),
                    ],
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.storage_rounded, color: cs.primary),
                      title: Text(l.manageDownloads),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DownloadsScreen())),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(children: [
                            Text(l.streamingCache, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                            _infoIcon(l.streamingCacheInfoTitle, l.streamingCacheInfoContent),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            _streamingCacheSizeMb == 0
                                ? l.streamingCacheOffSubtitle
                                : l.streamingCacheOnSubtitle(_streamingCacheSizeMb),
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: 0, label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.streamingCacheOff))),
                              const ButtonSegment(value: 128, label: FittedBox(fit: BoxFit.scaleDown, child: Text('128 MB'))),
                              const ButtonSegment(value: 256, label: FittedBox(fit: BoxFit.scaleDown, child: Text('256 MB'))),
                              const ButtonSegment(value: 512, label: FittedBox(fit: BoxFit.scaleDown, child: Text('512 MB'))),
                            ],
                            selected: {_streamingCacheSizeMb},
                            onSelectionChanged: (v) {
                              setState(() => _streamingCacheSizeMb = v.first);
                              PlayerSettings.setStreamingCacheSizeMb(v.first);
                            },
                          )),
                          if (_streamingCacheSizeMb > 0) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                              label: Text(l.clearCache),
                              onPressed: () async {
                                try {
                                  await AudioPlayer.clearStreamingCache();
                                } catch (_) {}
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l.streamingCacheCleared)));
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Library ──
                CollapsibleSection(
                  key: _keyFor('Library'),
                  icon: Icons.auto_stories_outlined,
                  title: l.sectionLibrary,
                  cs: cs,
                  isExpanded: _expandedSection == 'Library',
                  onExpansionChanged: (v) => _onSectionExpanded('Library', v),
                  children: [
                    SwitchListTile(
                      title: Text(l.hideEbookOnlyTitles),
                      subtitle: Text(
                        _hideEbookOnly
                            ? l.hideEbookOnlyOnSubtitle
                            : l.hideEbookOnlyOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _hideEbookOnly,
                      onChanged: _loaded ? (v) {
                        setState(() => _hideEbookOnly = v);
                        PlayerSettings.setHideEbookOnly(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.showGoodreadsButton),
                      subtitle: Text(
                        _showGoodreadsButton
                            ? l.showGoodreadsOnSubtitle
                            : l.showGoodreadsOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _showGoodreadsButton,
                      onChanged: _loaded ? (v) {
                        setState(() => _showGoodreadsButton = v);
                        PlayerSettings.setShowGoodreadsButton(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.showExplicitBadge),
                      subtitle: Text(
                        _showExplicitBadge
                            ? l.showExplicitBadgeOnSubtitle
                            : l.showExplicitBadgeOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _showExplicitBadge,
                      onChanged: _loaded ? (v) {
                        setState(() => _showExplicitBadge = v);
                        PlayerSettings.setShowExplicitBadge(v);
                      } : null,
                    ),
                    if (lib.libraries.length > 1) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ...lib.libraries
                        .map((library) {
                        final id = library['id'] as String;
                        final name = library['name'] as String? ?? l.libraryFallback;
                        final mediaType = library['mediaType'] as String? ?? 'book';
                        final isSelected = id == lib.selectedLibraryId;
                        return ListTile(
                          leading: Icon(
                            mediaType == 'podcast' ? Icons.podcasts_rounded : Icons.auto_stories_rounded,
                            color: isSelected ? cs.primary : cs.onSurfaceVariant),
                          title: Text(name),
                          trailing: isSelected ? Icon(Icons.check_circle_rounded, color: cs.primary) : null,
                          onTap: () { if (!isSelected) lib.selectLibrary(id); },
                        );
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // ── Permissions ──
                CollapsibleSection(
                  key: _keyFor('Permissions'),
                  icon: Icons.shield_outlined,
                  title: l.sectionPermissions,
                  cs: cs,
                  isExpanded: _expandedSection == 'Permissions',
                  onExpansionChanged: (v) => _onSectionExpanded('Permissions', v),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: Text(l.notifications),
                      subtitle: Text(l.notificationsSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                      onTap: () async {
                        final status = await Permission.notification.status;
                        if (status.isGranted) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(seconds: 2),
                              content: Text(l.notificationsAlreadyEnabled),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        } else {
                          final result = await Permission.notification.request();
                          if (result.isPermanentlyDenied && mounted) await openAppSettings();
                        }
                      },
                    ),
                    if (Platform.isAndroid) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.battery_saver_outlined),
                      title: Text(l.unrestrictedBattery),
                      subtitle: Text(l.unrestrictedBatterySubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                      onTap: () async {
                        final status = await Permission.ignoreBatteryOptimizations.status;
                        if (status.isGranted) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(seconds: 2),
                              content: Text(l.batteryAlreadyUnrestricted),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        } else {
                          final result = await Permission.ignoreBatteryOptimizations.request();
                          if (result.isPermanentlyDenied && mounted) await openAppSettings();
                        }
                      },
                    ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // ── Issues & Support ──
                CollapsibleSection(
                  key: _keyFor('Issues & Support'),
                  icon: Icons.support_agent_rounded,
                  title: l.sectionIssuesAndSupport,
                  cs: cs,
                  isExpanded: _expandedSection == 'Issues & Support',
                  onExpansionChanged: (v) => _onSectionExpanded('Issues & Support', v),
                  children: [
                    ListTile(
                      leading: Icon(Icons.lightbulb_outline_rounded,
                          color: cs.onSurfaceVariant),
                      title: Text(l.showTipsAgain),
                      subtitle: Text(l.showTipsAgainSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      onTap: () async {
                        await FeatureHint.resetAll();
                        if (!mounted) return;
                        showOverlayToast(context, l.tipsRestored,
                            icon: Icons.lightbulb_outline_rounded);
                        // Re-trigger the welcome dialog without an app
                        // restart. resetAll() already cleared the flag.
                        WelcomeSheet.showIfNeeded(context);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.bug_report_outlined, color: cs.onSurfaceVariant),
                      title: Text(l.bugsAndFeatureRequests),
                      subtitle: Text(l.bugsAndFeatureRequestsSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.open_in_new_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      onTap: () => launchUrl(
                          Uri.parse('https://github.com/pounat/absorb/issues'),
                          mode: LaunchMode.externalApplication),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.discord, color: cs.onSurfaceVariant),
                      title: Text(l.joinDiscord),
                      subtitle: Text(l.joinDiscordSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.open_in_new_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      onTap: () => launchUrl(
                          Uri.parse('https://discord.gg/bwH6hdvzZ4'),
                          mode: LaunchMode.externalApplication),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.email_outlined, color: cs.primary),
                      title: Text(l.contact),
                      subtitle: Text(l.contactSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        LogService().contactEmail(
                          serverVersion: auth.serverVersion,
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(l.enableLogging),
                      subtitle: Text(
                        _loggingEnabled
                            ? l.enableLoggingOnSubtitle
                            : l.enableLoggingOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _loggingEnabled,
                      onChanged: _loaded ? (v) {
                        setState(() => _loggingEnabled = v);
                        PlayerSettings.setLoggingEnabled(v);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(v
                              ? l.loggingEnabledSnackbar
                              : l.loggingDisabledSnackbar),
                        ));
                      } : null,
                    ),
                    if (_loggingEnabled && LogService().enabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.attach_file_rounded, color: cs.primary),
                        title: Text(l.sendLogs),
                        subtitle: Text(l.sendLogsSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          try {
                            final box = context.findRenderObject() as RenderBox?;
                            final origin = box != null
                                ? box.localToGlobal(Offset.zero) & box.size
                                : null;
                            await LogService().shareLogs(
                              serverVersion: auth.serverVersion,
                              sharePositionOrigin: origin,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.failedToShare(e.toString()))),
                              );
                            }
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                        title: Text(l.clearLogs),
                        onTap: () async {
                          await LogService().clearLogs();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.logsCleared)),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // ── Advanced ──
                CollapsibleSection(
                  key: _keyFor('Advanced'),
                  icon: Icons.tune_rounded,
                  title: l.sectionAdvanced,
                  cs: cs,
                  isExpanded: _expandedSection == 'Advanced',
                  onExpansionChanged: (v) => _onSectionExpanded('Advanced', v),
                  children: [
                    SwitchListTile(
                      title: Row(children: [
                        Flexible(child: Text(l.localServer)),
                        _infoIcon(l.localServerInfoTitle, l.localServerInfoContent),
                      ]),
                      subtitle: Text(
                        _localServerEnabled
                            ? (auth.useLocalServer
                                ? l.localServerOnConnectedSubtitle
                                : l.localServerOnRemoteSubtitle)
                            : l.localServerOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _localServerEnabled,
                      onChanged: _loaded ? (v) {
                        setState(() => _localServerEnabled = v);
                        auth.setLocalServerConfig(enabled: v, url: _localServerUrl);
                      } : null,
                    ),
                    if (_localServerEnabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: TextField(
                          controller: _localServerController,
                          decoration: InputDecoration(
                            labelText: l.localServerUrlLabel,
                            hintText: l.localServerUrlHint,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (_) => _saveLocalServerUrl(auth, l),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(l.setTooltip),
                            onPressed: () => _saveLocalServerUrl(auth, l),
                          ),
                        ),
                      ),
                      if (auth.useLocalServer) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: Icon(Icons.check_circle_rounded, color: Colors.greenAccent.shade400),
                          title: Text(l.localServerOnConnectedSubtitle),
                          subtitle: Text(_localServerUrl,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                      ],
                    ],
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Row(children: [
                        Flexible(child: Text(l.trustAllCertificates)),
                        _infoIcon(l.trustAllCertificatesInfoTitle, l.trustAllCertificatesInfoContent),
                      ]),
                      subtitle: Text(
                        _trustAllCerts
                            ? l.trustAllCertificatesOnSubtitle
                            : l.trustAllCertificatesOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _trustAllCerts,
                      onChanged: _loaded ? (v) async {
                        setState(() => _trustAllCerts = v);
                        await PlayerSettings.setTrustAllCerts(v);
                        applyTrustAllCerts(v);
                      } : null,
                    ),
                    if (_isGithubBuild) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: Row(children: [
                          Flexible(child: Text(l.includePreReleases)),
                          _infoIcon(l.preReleaseUpdatesInfoTitle, l.preReleaseUpdatesInfoContent),
                        ]),
                        subtitle: Text(
                          _includePreReleases
                              ? l.includePreReleasesOnSubtitle
                              : l.includePreReleasesOffSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        value: _includePreReleases,
                        onChanged: _loaded ? (v) async {
                          setState(() => _includePreReleases = v);
                          await PlayerSettings.setIncludePreReleases(v);
                        } : null,
                      ),
                    ],
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.menu_book_rounded, color: cs.primary),
                      title: Text(l.adminRmab),
                      subtitle: Text(
                        ((_rmabBaseUrl ?? '').isNotEmpty && (_rmabApiToken ?? '').isNotEmpty)
                            ? l.adminRmabConnected
                            : l.adminRmabAskAdmin,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      onTap: _openRmabSheetFromSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Support the Dev ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Card(
                        color: cs.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: Icon(Icons.coffee_rounded,
                              color: Colors.amber.shade600),
                          title: Text(l.supportTheDev),
                          subtitle: Text(l.buyMeACoffee,
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          trailing: Icon(Icons.favorite_rounded,
                              size: 18, color: Colors.amber.shade600),
                          onTap: () => launchUrl(
                              Uri.parse(
                                  'https://www.buymeacoffee.com/BarnabasApps'),
                              mode: LaunchMode.externalApplication),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Backup & Restore ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.settings_backup_restore_rounded, color: cs.primary, size: 22),
                            const SizedBox(width: 10),
                            Text(l.backupAndRestore, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 4),
                          Text(l.backupAndRestoreSubtitle,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: FilledButton.tonalIcon(
                              icon: const Icon(Icons.upload_rounded, size: 18),
                              label: Text(l.backUp),
                              onPressed: () => _backupSettings(context, cs, tt),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: OutlinedButton.icon(
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: Text(l.restore),
                              onPressed: () => _restoreSettings(context, cs, tt),
                            )),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── All Bookmarks ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Icon(Icons.bookmarks_rounded, color: cs.primary),
                      title: Text(l.allBookmarks),
                      subtitle: Text(l.allBookmarksSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BookmarksScreen())),
                    ),
                  ),
                ),

                // ── Version Info ──
                Center(child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.appVersionFormat(_appVersion),
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isGithubBuild ? Icons.code_rounded : Icons.store_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    if (auth.serverVersion != null)
                      Text(
                        l.appVersionServerSuffix(auth.serverVersion!),
                        style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      ),
                  ],
                )),

                if (_isGithubBuild) ...[
                  const SizedBox(height: 4),
                  Center(child: TextButton.icon(
                    onPressed: () async {
                      final info = await UpdateCheckerService.check(force: true, includePreReleases: _includePreReleases);
                      if (!mounted) return;
                      if (info == null || !info.hasUpdate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.onLatestVersion)),
                        );
                        return;
                      }
                      await UpdateDialog.show(context, info);
                    },
                    icon: const Icon(Icons.system_update_rounded, size: 16),
                    label: Text(l.checkForUpdate),
                  )),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  List<Widget> _buildRewindPreviews(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final s = _rewindSettings;
    final delay = s.activationDelay.round();

    // Build dynamic preview durations starting from the delay value
    final durations = <int, String>{};

    String pauseLabel(int seconds) {
      if (seconds < 60) return l.rewindSecondsPause(seconds.toString());
      if (seconds < 3600) {
        final m = seconds ~/ 60;
        return l.rewindMinPause(m.toString());
      }
      final h = seconds ~/ 3600;
      if (h == 1) return l.rewindOneHrPause;
      return l.rewindHrPause(h.toString());
    }

    // First row: the activation delay itself (or instant if 0)
    if (delay == 0) {
      durations[0] = l.rewindInstant;
    } else {
      durations[delay] = pauseLabel(delay);
    }

    // Add useful reference points above the delay, spread across the full range
    for (final secs in [30, 120, 600, 1800, 3600]) {
      if (secs > delay && durations.length < 5) {
        durations[secs] = pauseLabel(secs);
      }
    }

    // Always include 1 hour as the max reference
    if (!durations.containsKey(3600)) {
      durations[3600] = l.rewindOneHrPause;
    }

    final rows = <Widget>[];
    for (final entry in durations.entries) {
      final rewind = AudioPlayerService.calculateAutoRewind(
        Duration(seconds: entry.key), s.minRewind, s.maxRewind,
        activationDelay: s.activationDelay);
      rows.add(_rewindPreviewRow(entry.value, rewind, cs, tt, l));
    }

    return rows;
  }

  Widget _rewindPreviewRow(
      String label, double rewind, ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final isSkipped = rewind < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: tt.bodySmall?.copyWith(
            color: isSkipped ? cs.onSurfaceVariant.withValues(alpha: 0.4) : cs.onSurfaceVariant)),
          Text(isSkipped ? '→ ${l.rewindNoRewind}' : '→ ${l.rewindSeconds(rewind.toStringAsFixed(1))}',
            style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSkipped ? cs.onSurfaceVariant.withValues(alpha: 0.3) : cs.primary)),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _pickDownloadLocation(BuildContext context, ColorScheme cs, TextTheme tt) async {
    final l = AppLocalizations.of(context)!;
    final dl = DownloadService();
    final hasExistingDownloads = dl.downloadedItems.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(l.downloadLocationSheetTitle,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(l.downloadLocationSheetSubtitle,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),

            // Current location display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(Icons.folder_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.currentLocation,
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(_downloadLocationLabel,
                        style: tt.bodySmall?.copyWith(color: cs.onSurface),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            if (hasExistingDownloads)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: cs.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.existingDownloadsWarning,
                        style: tt.bodySmall?.copyWith(
                          color: cs.error.withValues(alpha: 0.8), fontSize: 11),
                      ),
                    ),
                  ]),
                ),
              ),

            // Choose folder button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.folder_open_rounded),
                label: Text(l.chooseFolder),
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (Platform.isAndroid) {
                    // Android 11+ needs MANAGE_EXTERNAL_STORAGE for custom paths.
                    // Android 9-10 use WRITE_EXTERNAL_STORAGE.
                    // If manageExternalStorage is restricted, the OS doesn't
                    // support it (Android 10 or below) so fall back to storage.
                    final manageStatus = await Permission.manageExternalStorage.status;
                    final Permission perm = manageStatus == PermissionStatus.restricted
                        ? Permission.storage
                        : Permission.manageExternalStorage;
                    final status = await perm.status;
                    if (status.isPermanentlyDenied) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l.storagePermissionDenied),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                          action: SnackBarAction(
                            label: l.openSettings,
                            onPressed: openAppSettings,
                          ),
                        ));
                      }
                      return;
                    }
                    if (!status.isGranted) {
                      final result = await perm.request();
                      if (!result.isGranted) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(l.storagePermissionRequired),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                        return;
                      }
                    }
                  }
                  final result = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: l.chooseDownloadFolder,
                  );
                  if (result != null) {
                    // Write test - verify we can actually create files here
                    try {
                      final testDir = Directory(result);
                      if (!testDir.existsSync()) testDir.createSync(recursive: true);
                      final testFile = File('${testDir.path}/.absorb_write_test');
                      testFile.writeAsStringSync('test');
                      testFile.deleteSync();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l.cannotWriteToFolder),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                          action: SnackBarAction(
                            label: l.openSettings,
                            onPressed: openAppSettings,
                          ),
                        ));
                      }
                      return;
                    }
                    await dl.setCustomDownloadPath(result);
                    final label = await dl.downloadLocationLabel;
                    if (mounted) {
                      setState(() => _downloadLocationLabel = label);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l.downloadLocationSetTo(label)),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 8),

            // Reset to default button
            if (dl.customDownloadPath != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l.resetToDefault),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await dl.setCustomDownloadPath(null);
                    final label = await dl.downloadLocationLabel;
                    if (mounted) {
                      setState(() => _downloadLocationLabel = label);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l.resetToDefaultStorage),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _backupSettings(BuildContext context, ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.shield_rounded),
        title: Text(l.includeLoginInfoTitle),
        content: Text(l.includeLoginInfoContent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performBackup(context, includeAccounts: false);
            },
            child: Text(l.noSettingsOnly),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performBackup(context, includeAccounts: true);
            },
            child: Text(l.yesIncludeAccounts),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup(BuildContext context, {required bool includeAccounts}) async {
    final l = AppLocalizations.of(context)!;
    try {
      final data = await BackupService.exportSettings(includeAccounts: includeAccounts);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final now = DateTime.now();
      final datePart = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'absorb_backup_$datePart.absorb';

      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final result = await FilePicker.platform.saveFile(
        dialogTitle: l.saveAbsorbBackup,
        fileName: fileName,
        type: FileType.any,
        bytes: bytes,
      );

      if (result != null) {
        // Desktop platforms need manual file write; mobile writes via bytes param
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          await File(result).writeAsString(jsonStr);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(includeAccounts
                ? l.backupSavedWithAccounts
                : l.backupSavedSettingsOnly),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.backupFailed(e.toString()))),
        );
      }
    }
  }

  void _restoreSettings(BuildContext context, ColorScheme cs, TextTheme tt) async {
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data['version'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.invalidBackupFile)),
          );
        }
        return;
      }

      if (!mounted) return;

      final accounts = data['accounts'] as List<dynamic>?;
      final hasAccounts = accounts != null && accounts.isNotEmpty;
      final bookmarks = data['bookmarks'] as Map<String, dynamic>?;
      final hasBookmarks = bookmarks != null && bookmarks.isNotEmpty;
      final hasCustomHeaders = data['customHeaders'] != null;
      final createdAt = data['createdAt'] as String?;
      final appVersion = data['appVersion'] as String?;

      String details = '';
      if (appVersion != null) details += l.fromAbsorbVersion(appVersion);
      if (createdAt != null) {
        final dt = DateTime.tryParse(createdAt);
        if (dt != null) {
          details += details.isEmpty ? '' : l.backupDetailsSeparator;
          details += l.backupDateFormat(dt.month, dt.day, dt.year);
        }
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.restore_rounded),
          title: Text(l.restoreBackupTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.restoreBackupContent),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(details, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
              if (hasAccounts || hasBookmarks || hasCustomHeaders) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasAccounts)
                      _restoreChip(Icons.people_rounded, l.restoreAccountsChip(accounts.length), cs),
                    if (hasBookmarks)
                      _restoreChip(Icons.bookmark_rounded, l.restoreBookmarksChip(bookmarks.length), cs),
                    if (hasCustomHeaders)
                      _restoreChip(Icons.vpn_key_rounded, l.restoreCustomHeadersChip, cs),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.restore),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await BackupService.importSettings(data);

      // Apply theme immediately
      final theme = data['settings']?['themeMode'] as String?;
      if (theme != null) {
        applyThemeMode(theme);
      }

      // Refresh UI
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.settingsRestoredSuccessfully),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.restoreFailed(e.toString()))),
        );
      }
    }
  }

  Widget _restoreChip(IconData icon, String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: cs.primary)),
      ]),
    );
  }

  void _showAccountSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final accounts = UserAccountService().accounts;
    final otherAccounts = accounts.where((a) =>
      !(a.serverUrl == auth.serverUrl && a.username == auth.username)
    ).toList();

    final shortServer = auth.serverUrl?.replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), '') ?? '';
    final userType = auth.isRoot ? l.rootAdmin : auth.isAdmin ? l.admin : l.userFallback;
    final libraryCount = lib.libraries.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4,
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
          // Current user info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.username ?? l.userFallback, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.dns_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Expanded(child: Text(shortServer, style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.shield_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(userType, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                const SizedBox(width: 12),
                Icon(Icons.library_books_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(libraryCount == 1 ? l.libraryCountOne(libraryCount) : l.libraryCountOther(libraryCount),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
              ]),
              if (auth.serverVersion != null) ...[
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text(l.serverVersionLabel(auth.serverVersion!), style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, indent: 20, endIndent: 20, color: cs.onSurface.withValues(alpha: 0.06)),
          // Other accounts
          if (otherAccounts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(alignment: Alignment.centerLeft,
                child: Text(l.switchAccount, style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontWeight: FontWeight.w600, letterSpacing: 0.5))),
            ),
            ...otherAccounts.map((account) {
              final shortUrl = account.serverUrl
                  .replaceAll(RegExp(r'^https?://'), '')
                  .replaceAll(RegExp(r'/+$'), '');
              return InkWell(
                onTap: () { Navigator.pop(ctx); _switchAccount(context, account); },
                onLongPress: () { Navigator.pop(ctx); _removeAccount(context, account); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(children: [
                    Icon(Icons.person_rounded, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(account.username, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(shortUrl, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Icon(Icons.swap_horiz_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.15)),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 4),
            Divider(height: 1, indent: 20, endIndent: 20, color: cs.onSurface.withValues(alpha: 0.06)),
          ],
          // Add account
          InkWell(
            onTap: () { Navigator.pop(ctx); _addAccount(context); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Icon(Icons.person_add_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 14),
                Text(l.addAccount, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
              ]),
            ),
          ),
          // Sign out
          InkWell(
            onTap: () { Navigator.pop(ctx); _confirmLogout(context); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Icon(Icons.logout_rounded, size: 20, color: cs.error),
                const SizedBox(width: 14),
                Text(l.signOut, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.error)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ]),
        ),
      ),
    );
  }

  /// Stop any active playback and sync progress to the server before
  /// switching users, adding an account, or signing out.
  Future<void> _stopAndSyncPlayback() async {
    final player = AudioPlayerService();
    if (player.hasBook) {
      await player.pause();
      await player.stop();
    }
  }

  Future<void> _openRmabSheetFromSettings() async {
    final l = AppLocalizations.of(context)!;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final result =
        await showRmabConfigSheet(context, isAdminContext: isAdmin);
    if (!mounted || result == null) return;
    if (result.changed || result.disconnected) {
      final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
      final token = await ScopedPrefs.getString(kRmabApiTokenKey);
      if (!mounted) return;
      setState(() {
        _rmabBaseUrl = base;
        _rmabApiToken = token;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.disconnected
            ? l.rmabConfigDisconnectedSnackbar
            : l.rmabConfigSavedSnackbar),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _confirmLogout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: Text(l.logOutTitle),
        content: Text(l.logOutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.stay),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _stopAndSyncPlayback();
              if (context.mounted) context.read<AuthProvider>().logout();
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
  }

  void _addAccount(BuildContext context) async {
    // Stop playback and sync before navigating to login
    await _stopAndSyncPlayback();
    if (!context.mounted) return;
    // Navigate to login screen as a pushed route (not replacing current)
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    // After login, refresh the library for the newly active account
    if (!context.mounted) return;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    if (auth.isAuthenticated) {
      lib.updateAuth(auth);
      await lib.refresh();
      if (context.mounted) AppShell.goToAbsorbingGlobal();
    }
  }

  void _removeAccount(BuildContext context, SavedAccount account) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.removeAccountTitle),
        content: Text(l.removeAccountContent(
          account.username,
          account.serverUrl.replaceAll(RegExp(r'^https?://'), ''),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l.remove)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await UserAccountService().removeAccount(account.serverUrl, account.username);
    if (context.mounted) setState(() {});
  }

  void _switchAccount(BuildContext context, SavedAccount account) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.switchAccountTitle),
        content: Text(l.switchAccountContent(
          account.username,
          account.serverUrl.replaceAll(RegExp(r'^https?://'), ''),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.switchButton)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Stop playback and sync before switching
    await _stopAndSyncPlayback();
    if (!context.mounted) return;

    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();

    await auth.switchToAccount(account);

    // Re-init the library provider with the new user
    if (context.mounted) {
      lib.updateAuth(auth);
      await lib.refresh();
      // Reload settings for the new account
      _loadSettings();
      // Jump to the absorbing screen
      AppShell.goToAbsorbingGlobal();
    }
  }
}
