import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer;
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/episode_notification_service.dart';
import '../services/sleep_timer_service.dart';
import '../services/user_account_service.dart';
import '../services/log_service.dart';
import '../services/scoped_prefs.dart';
import '../services/socket_service.dart';
import '../screens/login_screen.dart';
import '../screens/app_shell.dart';
import '../build_info.dart';
import '../services/update_checker_service.dart';
import '../services/audiobookshelf_update_service.dart';
import '../widgets/update_dialog.dart';
import '../widgets/nav_hold_options.dart';
import '../screens/admin_screen.dart';
import '../screens/downloads_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/backup_sync_screen.dart';
import '../services/settings_sync_service.dart';
import '../screens/change_password_screen.dart';
import '../screens/auth_sessions_screen.dart';
import '../screens/transcription_settings_screen.dart';
import '../main.dart' show applyThemeMode, applyTrustAllCerts, applyFlatBackground, applyColorSource, applyManualSeed, applyGradientIntensity, applyUseColorEverywhere, applyEinkModeTheme, applyOrientationLock, localeNotifier, flatNotifier, gradientIntensityNotifier, snappyTransitionsNotifier;
import '../services/wording.dart';
import '../utils/share_origin.dart';
import '../widgets/settings_search.dart';
import 'settings_search_index.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/theme_presets.dart';
import '../widgets/color_wheel_picker.dart';
import '../widgets/absorb_slider.dart';
import '../widgets/card_scrubber_mode_selector.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/tips_sheet.dart';
import '../widgets/feature_hint.dart';
import '../widgets/welcome_sheet.dart';
import '../widgets/rmab_config_sheet.dart';
import '../widgets/server_connection_editor.dart';
import '../widgets/server_admin_status_badges.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _isPlayStoreBuild = bool.fromEnvironment('PLAYSTORE_BUILD');
  static const _isGithubBuild = bool.fromEnvironment('GITHUB_BUILD');
  // Distribution label shown next to the version. The F-Droid build passes
  // neither define, so it falls through here.
  static String get _flavorLabel =>
      _isGithubBuild ? 'GitHub' : _isPlayStoreBuild ? 'Play Store' : 'F-Droid';

  String _versionLine(AppLocalizations l) {
    final base = Platform.isIOS
        ? l.appVersionFormat(_appVersion)
        : '$_flavorLabel - $_appVersion';
    final beta = betaNumberFor(_appVersion);
    return beta == null ? base : '$base (${l.betaLabel(beta)})';
  }
  AutoRewindSettings _rewindSettings = const AutoRewindSettings();
  double _defaultSpeed = 1.0;

  void _setDefaultSpeed(double v) {
    final s = ((v * 20).round() / 20.0).clamp(0.5, 3.0);
    setState(() => _defaultSpeed = s);
    PlayerSettings.setDefaultSpeed(s);
  }

  bool _wifiOnlyDownloads = false;
  bool _autoDownloadOnStream = false;
  int _rollingDownloadCount = 3;
  bool _rollingDownloadDeleteFinished = false;
  CardScrubberMode _cardScrubberMode = CardScrubberMode.chapter;
  bool _notifChapterProgress = false;
  bool _notifSpeedBookmark = false;
  bool _duckBriefInterruptions = false;
  bool _autoplayOnCarConnect = false;
  bool _lockSeekBar = false;
  bool _mp3IndexSeeking = false;
  bool _speedAdjustedTime = true;
  int _forwardSkip = 30;
  int _backSkip = 10;
  bool _skipChapterBarrier = true;
  bool _longSkipButtons = false;
  int _longForwardSkip = 60;
  int _longBackSkip = 60;
  String _shakeMode = 'addTime';
  int _sleepRewindSeconds = 0;
  static const _maxRewindMinutes = 120;
  bool _resetSleepOnPause = false;
  bool _sleepFadeOut = true;
  int _sleepFadeDuration = 30;
  bool _sleepChime = false;
  double _sleepChimeVolume = 0.7;
  int _shakeAddMinutes = 5;
  String _shakeSensitivity = 'medium';
  String _sleepButtonMode = 'off';
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
  bool _podcastTabEnabled = false;
  String _podcastTabLibraryId = '';
  int _episodeNotifMinutes = 0;
  int _maxConcurrentDownloads = 1;
  bool _hideEbookOnly = false;
  bool _showGoodreadsButton = false;
  bool _showExplicitBadge = true;
  bool _loggingEnabled = false;
  bool _fullScreenPlayer = false;
  bool _lockPortrait = false;
  bool _autoSeriesDownloadDefault = false;
  // card button layout is now managed in the edit sheet (more menu)
  bool _snappyTransitions = false;
  bool _classicWording = false;
  bool _rectangleCovers = false;
  String _coverSize = 'medium';
  // Per-library overrides shown in the Library section, scoped to whichever
  // library is currently selected (scales to accounts with many libraries -
  // no giant list, just "whatever you're browsing right now").
  String? _curLibId;
  String _curLibCoverShape = 'default'; // 'default' | 'square' | 'rect'
  bool _curLibSkipOverride = false;
  int _curLibSkipForward = 30;
  int _curLibSkipBack = 10;
  bool _coverPlayButton = false;
  String _cardBackground = 'blurred';
  double _progressTextScale = 1.0;
  String _themeMode = 'dark';
  bool _flatBackground = false;
  bool _einkMode = false;
  String _colorSource = 'dynamic';
  int _manualSeed = 0xFF7C6FBF;
  double _gradientIntensity = 0.06;
  bool _useColorEverywhere = false;
  String _language = '';
  int _startScreen = 2;
  final Map<String, int> _statsGoalMinutes = {
    for (final p in PlayerSettings.statsGoalPeriods) p: 0
  };
  int _statsBookGoal = 0;
  int _statsWeekStart = 1;
  String _statsChartStyle = 'bar';
  int _statsChartRange = 7;
  List<String> _statsSectionOrder = [];
  Set<String> _statsHiddenSections = {};

  // Recent sessions is intentionally absent: it infinite-scrolls, so it is
  // pinned to the bottom of the stats page and can't be reordered or hidden.
  static const _statsSectionIds = [
    'hero', 'goals', 'periods', 'activity', 'chart', 'heatmap', 'dayofweek', 'top', 'yearreview',
  ];
  int _streamingCacheSizeMb = 0;
  bool _localServerEnabled = false;
  String _localServerUrl = '';
  late final TextEditingController _localServerController;
  bool _trustAllCerts = false;
  bool _includePreReleases = false;
  String? _rmabBaseUrl;
  String? _rmabApiToken;
  bool _loaded = false;
  int _adminIssueCount = 0;
  AudiobookshelfServerUpdate? _serverUpdate;
  String? _serverUpdateCheckedFor;
  bool _serverUpdateCheckRunning = false;
  String _downloadLocationLabel = 'App Internal Storage (Default)';
  bool _canPickDownloadLocation = false;
  int _totalDownloadSizeBytes = 0;
  int _deviceTotalBytes = 0;
  int _deviceAvailableBytes = 0;
  AutoSleepSettings _autoSleepSettings = const AutoSleepSettings();
  String _appVersion = '';
  String? _expandedSection;
  final Map<String, GlobalKey> _sectionKeys = {};
  final TextEditingController _settingsSearchController = TextEditingController();
  String _settingsQuery = '';

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
    _loadAdminIssueCount();
    _refreshSyncStatus();
    SocketService().addItemsChangedListener(_onServerItemsChanged);
    PlayerSettings.settingsChanged.addListener(_onExternalSettingsChange);
  }

  // Keep the Server Admin badge current: scans flag items missing/invalid
  // server-side and stream items_updated events, so re-count after a quiet
  // moment instead of only once at screen creation (this screen is cached in
  // the shell, so initState runs a single time per session).
  Timer? _issueBadgeDebounce;
  bool _issueCountFetched = false;

  void _onServerItemsChanged() {
    if (!mounted || !context.read<AuthProvider>().isAdmin) return;
    _issueBadgeDebounce?.cancel();
    _issueBadgeDebounce = Timer(const Duration(seconds: 3), _loadAdminIssueCount);
  }

  /// Sum missing/invalid item counts across all libraries so the Server Admin
  /// button can show a badge when there's cleanup to do, without opening admin.
  Future<void> _loadAdminIssueCount() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) return;
    final api = auth.apiService;
    if (api == null) return;
    final ids = context
        .read<LibraryProvider>()
        .libraries
        .map((l) => (l as Map)['id'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;
    _issueCountFetched = true;
    final counts = await Future.wait(ids.map(api.getIssueItemCount));
    if (!mounted) return;
    setState(() => _adminIssueCount = counts.fold<int>(0, (a, b) => a + b));
  }

  Future<void> _loadServerUpdate(String currentVersion) async {
    _serverUpdateCheckedFor = currentVersion;
    _serverUpdateCheckRunning = true;
    final update = await AudiobookshelfUpdateService.check(currentVersion: currentVersion);
    _serverUpdateCheckRunning = false;
    if (!mounted || _serverUpdateCheckedFor != currentVersion) return;
    setState(() => _serverUpdate = update);
  }

  @override
  void dispose() {
    SocketService().removeItemsChangedListener(_onServerItemsChanged);
    _issueBadgeDebounce?.cancel();
    PlayerSettings.settingsChanged.removeListener(_onExternalSettingsChange);
    _localServerController.dispose();
    _settingsSearchController.dispose();
    super.dispose();
  }

  void _openSearchResult(SettingSearchEntry entry) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _settingsSearchController.clear();
      _settingsQuery = '';
      _expandedSection = entry.sectionId;
    });
    // The section list re-appears and the target section expands; once the
    // expansion animation and the section-level auto-scroll have settled,
    // locate the tile by its rendered title text and pulse it.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final ctx = _keyFor(entry.sectionId).currentContext;
      if (ctx == null) return;
      highlightSettingInSection(sectionContext: ctx, title: entry.title);
    });
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
    unawaited(context.read<LibraryProvider>().syncQueueAutoDownloads());
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
    unawaited(context.read<LibraryProvider>().syncQueueAutoDownloads());
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
    unawaited(context.read<LibraryProvider>().syncQueueAutoDownloads());
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
    unawaited(context.read<LibraryProvider>().syncQueueAutoDownloads());
  }

  void _setManualColor(int argb) {
    setState(() => _manualSeed = argb);
    PlayerSettings.setManualSeedColor(argb);
    applyManualSeed(argb);
  }

  Widget _buildColorSwatches(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final preset in kThemePresets)
          _swatch(
            color: preset.color,
            selected: _manualSeed == preset.color.toARGB32(),
            tooltip: preset.name,
            onTap: () => _setManualColor(preset.color.toARGB32()),
          ),
        // Custom color wheel entry
        Tooltip(
          message: l.colorSourceCustom,
          child: InkWell(
            onTap: () => _showCustomColorDialog(),
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(colors: [
                  Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                  Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
                ]),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.add_rounded, size: 20, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _swatch({required Color color, required bool selected, required String tooltip, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? cs.onSurface : cs.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: 20,
                  color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black)
              : null,
        ),
      ),
    );
  }

  Future<void> _showNavHoldDialog() async {
    final l = AppLocalizations.of(context)!;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final libraries = context.read<LibraryProvider>().libraries;
    final ids = navHoldAllIds(
      isAdmin: isAdmin,
      libraryIds: [
        for (final lib in libraries)
          if ((lib['id'] as String?)?.isNotEmpty == true) lib['id'] as String,
      ],
    );
    final validIds = ids.toSet();
    final podcastTab = await PlayerSettings.getPodcastTabEnabled();
    final tabs = navHoldTabs
        .where((t) => t != 'podcasts' || podcastTab)
        .toList();
    final chosen = <String, String?>{};
    for (final tab in tabs) {
      final saved = await ScopedPrefs.getString(navHoldPrefKey(tab)) ??
          navHoldDefaults[tab];
      chosen[tab] = validIds.contains(saved) ? saved : null;
    }
    if (!mounted) return;
    String? libraryName(String id) {
      for (final lib in libraries) {
        if (lib['id'] == id) return lib['name'] as String?;
      }
      return null;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.navHoldSettingTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tab in tabs) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: chosen[tab],
                    decoration:
                        InputDecoration(labelText: navHoldTabLabel(tab, l)),
                    items: [
                      DropdownMenuItem<String?>(
                          value: null, child: Text(l.navHoldAskNextTime)),
                      for (final id in ids)
                        DropdownMenuItem<String?>(
                          value: id,
                          child: Text(
                            navHoldLabel(id, l, libraryName: libraryName),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      setDialogState(() => chosen[tab] = v);
                      // Store the ask marker rather than clearing the key:
                      // a cleared key reads as "never chose" and runs the
                      // tab's default instead of asking.
                      ScopedPrefs.setString(
                          navHoldPrefKey(tab), v ?? navHoldAskValue);
                    },
                  ),
                  if (tab != tabs.last) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ScopedPrefs.remove(navHoldMenuPrefKey);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                showOverlayToast(context, l.navHoldMenuReset,
                    icon: Icons.refresh_rounded);
              },
              child: Text(l.navHoldResetMenu),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.done),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomColorDialog() async {
    var picked = Color(_manualSeed);
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.colorSourceCustom),
          content: SizedBox(
            width: 300,
            child: ColorWheelPicker(
              initialColor: picked,
              onChanged: (c) => picked = c,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            FilledButton(
              onPressed: () {
                _setManualColor(picked.withValues(alpha: 1.0).toARGB32());
                Navigator.pop(ctx);
              },
              child: Text(l.save),
            ),
          ],
        );
      },
    );
  }

  Widget _statsStepperRow(ColorScheme cs, TextTheme tt, String label, String value,
      {VoidCallback? onMinus, VoidCallback? onPlus, VoidCallback? onTapValue}) {
    return Row(children: [
      Expanded(child: Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
      IconButton(
        onPressed: _loaded ? onMinus : null,
        icon: const Icon(Icons.remove_circle_outline_rounded),
        color: cs.primary,
        visualDensity: VisualDensity.compact,
      ),
      InkWell(
        onTap: _loaded ? onTapValue : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
      IconButton(
        onPressed: _loaded ? onPlus : null,
        icon: const Icon(Icons.add_circle_outline_rounded),
        color: cs.primary,
        visualDensity: VisualDensity.compact,
      ),
    ]);
  }

  String _statsMinutesLabel(AppLocalizations l, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? l.statsScreenDurationHm(h, m) : l.statsScreenDurationM(m);
  }

  /// Stepper granularity, scaled so the longer periods aren't hundreds of taps
  /// wide. Tapping the value still takes an exact number.
  int _statsGoalStepMinutes(String period) => switch (period) {
        'weekly' => 30,
        'monthly' => 60,
        _ => 5,
      };

  String _statsGoalLabel(AppLocalizations l, String period) => switch (period) {
        'weekly' => l.statsGoalWeekly,
        'monthly' => l.statsGoalMonthly,
        _ => l.statsGoalDaily,
      };

  Widget _statsGoalRow(
      ColorScheme cs, TextTheme tt, AppLocalizations l, String period) {
    final minutes = _statsGoalMinutes[period]!;
    final step = _statsGoalStepMinutes(period);
    final max = PlayerSettings.maxStatsGoalMinutes(period);
    return _statsStepperRow(
        cs, tt, _statsGoalLabel(l, period), _statsMinutesLabel(l, minutes),
        onTapValue: () => _editStatsTimeTarget(period),
        onMinus: minutes > step
            ? () => _setStatsGoalMinutes(period, minutes - step)
            : null,
        onPlus:
            minutes < max ? () => _setStatsGoalMinutes(period, minutes + step) : null);
  }

  /// Accepts plain minutes ("90") or h:mm ("1:30").
  int? _parseGoalMinutes(String input, String period) {
    final t = input.trim();
    if (t.isEmpty) return null;
    int? minutes;
    if (t.contains(':')) {
      final parts = t.split(':');
      if (parts.length != 2) return null;
      final h = int.tryParse(parts[0].trim());
      final m = int.tryParse(parts[1].trim());
      if (h == null || m == null || h < 0 || m < 0 || m >= 60) return null;
      minutes = h * 60 + m;
    } else {
      minutes = int.tryParse(t);
    }
    if (minutes == null || minutes < 1) return null;
    return minutes.clamp(1, PlayerSettings.maxStatsGoalMinutes(period));
  }

  Future<String?> _promptStatsValue(String hint, TextInputType keyboard) async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.statsGoalEnterTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(l.save)),
        ],
      ),
    );
  }

  Future<void> _editStatsTimeTarget(String period) async {
    final l = AppLocalizations.of(context)!;
    final input = await _promptStatsValue(l.statsGoalEnterTimeHint, TextInputType.datetime);
    if (input == null) return;
    final minutes = _parseGoalMinutes(input, period);
    if (minutes == null) return;
    _setStatsGoalMinutes(period, minutes);
  }

  void _setStatsGoalMinutes(String period, int minutes) {
    final clamped = minutes.clamp(0, PlayerSettings.maxStatsGoalMinutes(period));
    setState(() => _statsGoalMinutes[period] = clamped);
    PlayerSettings.setStatsGoalMinutesFor(period, clamped);
  }

  /// Switching a period on reinstates whatever target it last held, so the
  /// stored value has to come back from the store rather than being assumed.
  Future<void> _toggleStatsGoal(String period, bool on) async {
    await PlayerSettings.setStatsGoalEnabled(period, on);
    final minutes = await PlayerSettings.getStatsGoalMinutesFor(period);
    if (!mounted) return;
    setState(() => _statsGoalMinutes[period] = minutes);
  }

  Future<void> _editStatsBookTarget() async {
    final input = await _promptStatsValue('', TextInputType.number);
    if (input == null) return;
    final books = int.tryParse(input.trim());
    if (books == null || books < 0) return;
    setState(() => _statsBookGoal = books.clamp(0, 500));
    PlayerSettings.setStatsBookGoal(_statsBookGoal);
  }

  List<String> get _mergedStatsOrder => [
        ..._statsSectionOrder.where(_statsSectionIds.contains),
        ..._statsSectionIds.where((id) => !_statsSectionOrder.contains(id)),
      ];

  String _statsSectionLabel(AppLocalizations l, String id) {
    switch (id) {
      case 'hero': return l.statsTotalListeningTime;
      case 'goals': return l.statsGoalTitle;
      case 'periods': return l.statsSectionTimePeriods;
      case 'activity': return l.statsActivity;
      case 'chart': return l.statsChartTitle;
      case 'heatmap': return l.statsChartHeatmap;
      case 'dayofweek': return l.statsDayOfWeek;
      case 'top': return l.statsMostListened;
      case 'yearreview': return 'Year in Review';
    }
    return id;
  }

  IconData _statsSectionIcon(String id) {
    switch (id) {
      case 'hero': return Icons.headphones_rounded;
      case 'goals': return Icons.flag_rounded;
      case 'periods': return Icons.date_range_rounded;
      case 'activity': return Icons.local_fire_department_rounded;
      case 'chart': return Icons.bar_chart_rounded;
      case 'heatmap': return Icons.calendar_view_month_rounded;
      case 'dayofweek': return Icons.view_week_rounded;
      case 'top': return Icons.star_outline_rounded;
      case 'yearreview': return Icons.auto_awesome_rounded;
    }
    return Icons.widgets_outlined;
  }

  Widget _statsSectionsList(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final order = _mergedStatsOrder;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: order.length,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorder: (oldIndex, newIndex) {
        final list = List<String>.from(order);
        if (newIndex > oldIndex) newIndex--;
        final item = list.removeAt(oldIndex);
        list.insert(newIndex, item);
        setState(() => _statsSectionOrder = list);
        PlayerSettings.setStatsSectionOrder(list);
      },
      itemBuilder: (context, index) {
        final id = order[index];
        final isHidden = _statsHiddenSections.contains(id);
        return Container(
          key: ValueKey(id),
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: isHidden ? 0.02 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(_statsSectionIcon(id), size: 18,
                color: isHidden
                    ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                    : cs.onSurfaceVariant),
            title: Text(_statsSectionLabel(l, id),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isHidden
                      ? cs.onSurface.withValues(alpha: 0.35)
                      : cs.onSurface,
                )),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () {
                  final updated = Set<String>.from(_statsHiddenSections);
                  if (!updated.add(id)) updated.remove(id);
                  setState(() => _statsHiddenSections = updated);
                  PlayerSettings.setStatsHiddenSections(updated.toList());
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isHidden
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: isHidden
                        ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  String _episodeNotifIntervalLabel(AppLocalizations l, int minutes) {
    if (minutes <= 0) return l.notifIntervalOff;
    if (minutes < 60) return l.notifIntervalMinutes(minutes);
    if (minutes == 60) return l.notifIntervalHour;
    return l.notifIntervalHours(minutes ~/ 60);
  }

  String _episodeNotifLabel(AppLocalizations l) =>
      _episodeNotifIntervalLabel(l, _episodeNotifMinutes);

  Future<void> _pickEpisodeNotifInterval() async {
    final l = AppLocalizations.of(context)!;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.settingsEpisodeNotifs),
        children: [
          for (final m in [0, 15, 30, 60, 180, 360, 720, 1440])
            RadioListTile<int>(
              value: m,
              groupValue: _episodeNotifMinutes,
              title: Text(_episodeNotifIntervalLabel(l, m)),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
        ],
      ),
    );
    if (picked == null || picked == _episodeNotifMinutes) return;
    setState(() => _episodeNotifMinutes = picked);
    await PlayerSettings.setEpisodeNotifIntervalMinutes(picked);
    await EpisodeNotificationService.syncRegistration();
    // Make sure notifications are allowed when turning the feature on.
    if (picked > 0) await Permission.notification.request();
  }

  Future<void> _pickPodcastTabLibrary(List<Map<String, dynamic>> podcastLibs) async {
    final l = AppLocalizations.of(context)!;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.settingsPodcastTabLibrary),
        children: [
          for (final p in podcastLibs)
            RadioListTile<String>(
              value: p['id'] as String,
              groupValue: _podcastTabLibraryId,
              title: Text(p['name'] as String? ?? ''),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
        ],
      ),
    );
    if (picked == null || picked == _podcastTabLibraryId) return;
    setState(() => _podcastTabLibraryId = picked);
    await PlayerSettings.setPodcastTabLibraryId(picked);
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      AutoRewindSettings.load(),                              // 0
      PlayerSettings.getDefaultSpeed(),                       // 1
      PlayerSettings.getWifiOnlyDownloads(),                  // 2
      PlayerSettings.getRollingDownloadCount(),                // 3
      PlayerSettings.getRollingDownloadDeleteFinished(),       // 4
      PlayerSettings.getCardScrubberMode(),                   // 5
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
      PlayerSettings.getMergeAbsorbingLibrariesRaw(),         // 16
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
      UpdateCheckerService.currentInstalledVersion(),         // 29
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
      PlayerSettings.getMediaControlsSpeedBookmark(),                         // 52
      PlayerSettings.getLockSeekBar(),                                        // 53
      PlayerSettings.getCardBackground(),                                     // card background
      PlayerSettings.getProgressTextScale(),                                  // 54 (kept last — read via results.last)
    ]);
    final s = results[0] as AutoRewindSettings;
    final progressScale = results.last as double;
    final mp3IndexSeek = await PlayerSettings.getMp3IndexSeeking();
    final coverSize = await PlayerSettings.getCoverSize();
    final flatBackground = await PlayerSettings.getFlatBackground();
    final einkMode = await PlayerSettings.getEinkMode();
    final colorSource = await PlayerSettings.getColorSource();
    final manualSeed = await PlayerSettings.getManualSeedColor();
    final gradientIntensity = await PlayerSettings.getGradientIntensity();
    final useColorEverywhere = await PlayerSettings.getUseColorEverywhere();
    final sleepButtonMode = await PlayerSettings.getSleepButtonMode();
    final statsGoalMinutes = <String, int>{
      for (final p in PlayerSettings.statsGoalPeriods)
        p: await PlayerSettings.getStatsGoalMinutesFor(p)
    };
    final statsBookGoal = await PlayerSettings.getStatsBookGoal();
    final statsWeekStart = await PlayerSettings.getStatsWeekStart();
    final statsChartStyle = await PlayerSettings.getStatsChartStyle();
    final statsChartRange = await PlayerSettings.getStatsChartRange();
    final statsSectionOrder = await PlayerSettings.getStatsSectionOrder();
    final statsHiddenSections = await PlayerSettings.getStatsHiddenSections();
    final speed = results[1] as double;
    final wifiOnly = results[2] as bool;
    final rollingCount = results[3] as int;
    final rollingDelete = results[4] as bool;
    final cardScrubberMode = results[5] as CardScrubberMode;
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
    final appVersion = results[28] as String;
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
    final notifSpeedBookmark = results[49] as bool;
    final lockSeek = results[50] as bool;
    final cardBg = results[51] as String;
    final rmabBaseUrl = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final rmabApiToken = await ScopedPrefs.getString(kRmabApiTokenKey);
    final sleepRewind = await PlayerSettings.getSleepRewindSeconds();
    final lockPortrait = await PlayerSettings.getLockPortrait();
    final autoSeriesDownload = await PlayerSettings.getAutoSeriesDownloadDefault();
    final longSkipButtons = await PlayerSettings.getLongSkipButtons();
    final longFwd = await PlayerSettings.getLongForwardSkip();
    final longBack = await PlayerSettings.getLongBackSkip();
    final podcastTabEnabled = await PlayerSettings.getPodcastTabEnabled();
    final podcastTabLibraryId = await PlayerSettings.getPodcastTabLibraryId();
    final episodeNotifMinutes = await PlayerSettings.getEpisodeNotifIntervalMinutes();
    final duckBriefInterruptions = await PlayerSettings.getDuckBriefInterruptions();
    final autoplayOnCarConnect = await PlayerSettings.getAutoplayOnCarConnect();
    if (mounted) setState(() {
      _podcastTabEnabled = podcastTabEnabled;
      _podcastTabLibraryId = podcastTabLibraryId;
      _episodeNotifMinutes = episodeNotifMinutes;
      _sleepRewindSeconds = sleepRewind;
      _lockPortrait = lockPortrait;
      _autoSeriesDownloadDefault = autoSeriesDownload;
      _rmabBaseUrl = rmabBaseUrl;
      _rmabApiToken = rmabApiToken;
      _rewindSettings = s;
      _defaultSpeed = speed;
      _wifiOnlyDownloads = wifiOnly;
      _autoDownloadOnStream = autoDlStream;
      _rollingDownloadCount = rollingCount;
      _rollingDownloadDeleteFinished = rollingDelete;
      _cardScrubberMode = cardScrubberMode;
      _notifChapterProgress = notifChapter;
      _notifSpeedBookmark = notifSpeedBookmark;
      _duckBriefInterruptions = duckBriefInterruptions;
      _autoplayOnCarConnect = autoplayOnCarConnect;
      _lockSeekBar = lockSeek;
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
      _mp3IndexSeeking = mp3IndexSeek;
      _themeMode = theme == 'oled' ? 'dark' : theme;
      _flatBackground = flatBackground;
      _einkMode = einkMode;
      _colorSource = colorSource == 'manual' ? 'manual' : 'dynamic';
      _manualSeed = manualSeed;
      _gradientIntensity = gradientIntensity;
      _useColorEverywhere = useColorEverywhere;
      _downloadLocationLabel = dlLabel;
      _totalDownloadSizeBytes = dlSize;
      if (deviceStorage != null) {
        _deviceTotalBytes = deviceStorage['totalBytes']!;
        _deviceAvailableBytes = deviceStorage['availableBytes']!;
      }
      _autoSleepSettings = autoSleep;
      _appVersion = appVersion;
      _streamingCacheSizeMb = cacheSizeMb;
      _localServerEnabled = localEnabled;
      _localServerUrl = localUrl;
      _localServerController.text = localUrl;
      _startScreen = startScreen;
      // cardBtnLayout removed (now managed in edit sheet)
      _rectangleCovers = rectCovers;
      _coverSize = coverSize;
      _coverPlayButton = coverPlay;
      _cardBackground = cardBg;
      _progressTextScale = progressScale;
      _skipChapterBarrier = skipBarrier;
      _longSkipButtons = longSkipButtons;
      _longForwardSkip = longFwd;
      _longBackSkip = longBack;
      _trustAllCerts = trustCerts;
      _showExplicitBadge = showExplicit;
      _includePreReleases = preReleases;
      _sleepFadeDuration = fadeDur;
      _sleepChime = chime;
      _sleepChimeVolume = chimeVol;
      _shakeSensitivity = shakeSens;
      _sleepButtonMode = sleepButtonMode;
      _language = language;
      _canPickDownloadLocation = true;
      _statsGoalMinutes
        ..clear()
        ..addAll(statsGoalMinutes);
      _statsBookGoal = statsBookGoal;
      _statsWeekStart = statsWeekStart;
      _statsChartStyle = statsChartStyle;
      _statsChartRange = statsChartRange;
      _statsSectionOrder = statsSectionOrder;
      _statsHiddenSections = statsHiddenSections.toSet();

      _loaded = true;
    });
    final libId = mounted ? context.read<LibraryProvider>().selectedLibraryId : null;
    if (libId != null) _loadCurrentLibraryOverrides(libId);
  }

  /// (Re)loads the cover-shape + skip overrides for whichever library is
  /// currently selected. Called on load and again whenever the user picks a
  /// different library from the list in this same section.
  Future<void> _loadCurrentLibraryOverrides(String libraryId) async {
    final shape = await PlayerSettings.getRectangleCoversOverride(libraryId);
    final skip = await PlayerSettings.getSkipOverride(libraryId);
    if (mounted) setState(() {
      _curLibId = libraryId;
      _curLibCoverShape = shape ?? 'default';
      _curLibSkipOverride = skip != null;
      _curLibSkipForward = skip?.forward ?? 30;
      _curLibSkipBack = skip?.back ?? 10;
    });
  }

  String _coverShapeValueLabel(AppLocalizations l, String value) {
    switch (value) {
      case 'rect': return l.coverShapeRectangle;
      case 'square': return l.coverShapeSquare;
      default: return l.coverShapeDefault;
    }
  }

  /// Default/Square/Rectangle picker for the currently selected library,
  /// same bottom-sheet pattern as the language picker.
  Future<void> _pickCurrentLibraryCoverShape() async {
    final libId = _curLibId;
    if (libId == null) return;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

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
            Text(l.coverShapeLabel, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'default',
              groupValue: _curLibCoverShape,
              onChanged: (v) => Navigator.pop(ctx, v),
              title: Text(l.coverShapeDefault),
              subtitle: Text(_rectangleCovers ? l.coverShapeRectangle : l.coverShapeSquare),
            ),
            RadioListTile<String>(
              value: 'square',
              groupValue: _curLibCoverShape,
              onChanged: (v) => Navigator.pop(ctx, v),
              title: Text(l.coverShapeSquare),
            ),
            RadioListTile<String>(
              value: 'rect',
              groupValue: _curLibCoverShape,
              onChanged: (v) => Navigator.pop(ctx, v),
              title: Text(l.coverShapeRectangle),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || picked == _curLibCoverShape) return;
    setState(() => _curLibCoverShape = picked);
    await PlayerSettings.setRectangleCoversOverride(libId, picked == 'default' ? null : picked);
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
      case 'fr': return 'Français';
      case 'zh': return '中文';
      default: return l.languageSystemDefault;
    }
  }

  Future<void> _pickLanguage() async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    const codes = ['', 'en', 'de', 'fr', 'zh'];

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

  IconData _autoDownloadSourceIcon(String? kind) {
    switch (kind) {
      case 'playlist':
        return Icons.playlist_play_rounded;
      case 'collection':
        return Icons.collections_bookmark_rounded;
      case 'series':
        return Icons.auto_stories_rounded;
      case 'podcast':
        return Icons.podcasts_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  bool _autoDownloadSourcesExpanded = false;

  /// Auto-download is switched on per source from that source's own page, so
  /// without this there is nowhere to see what it's on for - a list left
  /// enabled keeps stocking itself with nothing pointing at it.
  Widget _buildAutoDownloadSources(
      LibraryProvider lib, AppLocalizations l, ColorScheme cs, TextTheme tt) {
    final sources = lib.enabledAutoDownloadSources();
    // Entries enabled before names were stored resolve against the server.
    if (sources.any((s) => s['name'] == null)) {
      lib.resolveAutoDownloadSourceNames();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: sources.isEmpty
                ? null
                : () => setState(() => _autoDownloadSourcesExpanded =
                    !_autoDownloadSourcesExpanded),
            child: Row(
              children: [
                Text(
                    sources.isEmpty
                        ? l.autoDownloadEnabledFor
                        : '${l.autoDownloadEnabledFor} (${sources.length})',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                if (sources.isNotEmpty)
                  AnimatedRotation(
                    turns: _autoDownloadSourcesExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (sources.isEmpty)
            Text(l.autoDownloadEnabledForNone,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
          else if (_autoDownloadSourcesExpanded)
            ...sources.map((source) {
              final name = source['name'];
              return Row(children: [
                Icon(_autoDownloadSourceIcon(source['kind']),
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name ?? l.autoDownloadSourceUnnamed,
                    style: tt.bodySmall?.copyWith(
                        color: name == null ? cs.onSurfaceVariant : cs.onSurface,
                        fontStyle: name == null ? FontStyle.italic : null),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: l.turnAutoDownloadOff,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => lib.disableRollingDownload(source['id']!),
                ),
              ]);
            }),
        ],
      ),
    );
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

  String _rewindLabel(int seconds, AppLocalizations l) {
    if (seconds == 0) return l.off;
    if (seconds < 60) return l.sleepTimerSheetSecondsShort(seconds);
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0
        ? l.sleepTimerSheetMinSecShort(m, s)
        : l.sleepTimerSheetMinShort(m);
  }

  Future<void> _saveLocalServerUrl(AuthProvider auth, AppLocalizations l) async {
    final url = _localServerController.text.trim();
    if (url.isEmpty) return;
    _localServerUrl = url;
    await auth.setLocalServerConfig(enabled: _localServerEnabled, url: _localServerUrl);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    showOverlayToast(context, l.localServerUrlSetSnackbar,
        icon: Icons.check_circle_outline_rounded);
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
    // Libraries may not have loaded yet when initState fetched the admin issue
    // badge; retry once they arrive.
    if (!_issueCountFetched && auth.isAdmin && lib.libraries.isNotEmpty) {
      _issueCountFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAdminIssueCount();
      });
    }
    final serverVersion = auth.serverVersion?.trim();
    if (auth.isAdmin && serverVersion != null && serverVersion.isNotEmpty &&
        !_serverUpdateCheckRunning && _serverUpdateCheckedFor != serverVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadServerUpdate(serverVersion);
      });
    }
    if (lib.selectedLibraryId != null && lib.selectedLibraryId != _curLibId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCurrentLibraryOverrides(lib.selectedLibraryId!);
      });
    }

    return Scaffold(
      body: Container(
        decoration: flatNotifier.value ? null : BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.35, 1.0],
            colors: [
              cs.primary.withValues(alpha: gradientIntensityNotifier.value),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _settingsSearchController,
                      onChanged: (v) => setState(() => _settingsQuery = v),
                      decoration: InputDecoration(
                        hintText: l.settingsSearchHint,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: tt.bodyMedium,
                    ),
                  ),
                  if (_settingsQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: cs.onSurfaceVariant,
                      onPressed: () => setState(() {
                        _settingsSearchController.clear();
                        _settingsQuery = '';
                      }),
                    ),
                  const SizedBox(width: 4),
                ]),
              ),
            ),
          ),
          if (_settingsQuery.trim().isEmpty)
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
                        gradient: flatNotifier.value ? null : LinearGradient(
                          colors: [cs.primaryContainer, cs.tertiaryContainer],
                        ),
                        color: flatNotifier.value ? cs.surfaceContainerHigh : null,
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
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const AdminScreen(),
                          ));
                          _loadAdminIssueCount();
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
                              if (_adminIssueCount > 0 || _serverUpdate != null) ...[
                                ServerAdminStatusBadges(
                                  issueCount: _adminIssueCount,
                                  updateVersion: _serverUpdate?.latestVersion,
                                  updateTooltip: _serverUpdate == null
                                      ? ''
                                      : l.serverUpdateAvailable(_serverUpdate!.latestVersion),
                                ),
                                const SizedBox(width: 10),
                              ],
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
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l.flatBackgroundLabel, style: tt.bodyLarge),
                            subtitle: Text(l.flatBackgroundSubtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            value: _flatBackground,
                            onChanged: _loaded ? (v) {
                              setState(() => _flatBackground = v);
                              PlayerSettings.setFlatBackground(v);
                              applyFlatBackground(v);
                            } : null,
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l.einkModeLabel, style: tt.bodyLarge),
                            subtitle: Text(l.einkModeSubtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            value: _einkMode,
                            onChanged: _loaded ? (v) async {
                              if (v) {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l.einkModeLabel),
                                    content: Text(l.einkModeIntroBody),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text(l.cancel),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text(l.einkModeIntroConfirm),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true || !mounted) return;
                              }
                              setState(() => _einkMode = v);
                              PlayerSettings.setEinkMode(v);
                              applyEinkModeTheme(v);
                              if (mounted) {
                                context.read<LibraryProvider>().applyEinkMode(v);
                              }
                            } : null,
                          ),
                          if (!_flatBackground) ...[
                            const SizedBox(height: 4),
                            Text(l.backgroundIntensityLabel, style: tt.bodyMedium),
                            Slider(
                              value: _gradientIntensity.clamp(0.0, 0.45),
                              min: 0.0,
                              max: 0.45,
                              onChanged: _loaded ? (v) {
                                setState(() => _gradientIntensity = v);
                                applyGradientIntensity(v);
                              } : null,
                              onChangeEnd: (v) => PlayerSettings.setGradientIntensity(v),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.colorSourceLabel, style: tt.titleSmall),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: 'dynamic', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.colorSourceDynamic, maxLines: 1))),
                                ButtonSegment(value: 'manual', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.colorSourceManual, maxLines: 1))),
                              ],
                              selected: {_colorSource},
                              onSelectionChanged: _loaded ? (selected) {
                                final src = selected.first;
                                setState(() => _colorSource = src);
                                PlayerSettings.setColorSource(src);
                                applyColorSource(src);
                              } : null,
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _colorSource == 'manual' ? l.colorSourceManualDescription : l.colorSourceCoverDescription,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          if (_colorSource == 'manual') ...[
                            const SizedBox(height: 14),
                            _buildColorSwatches(cs),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l.useColorEverywhereLabel, style: tt.bodyLarge),
                              subtitle: Text(l.useColorEverywhereSubtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              value: _useColorEverywhere,
                              onChanged: _loaded ? (v) {
                                setState(() => _useColorEverywhere = v);
                                PlayerSettings.setUseColorEverywhere(v);
                                applyUseColorEverywhere(v);
                              } : null,
                            ),
                          ],
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.progressTextSize, style: tt.titleSmall),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<double>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 1.0, label: Text('A', style: TextStyle(fontSize: 13))),
                                ButtonSegment(value: 1.5, label: Text('A', style: TextStyle(fontSize: 17))),
                                ButtonSegment(value: 2.0, label: Text('A', style: TextStyle(fontSize: 21))),
                              ],
                              selected: {_progressTextScale},
                              onSelectionChanged: _loaded ? (selected) {
                                final v = selected.first;
                                setState(() => _progressTextScale = v);
                                PlayerSettings.setProgressTextScale(v);
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.coverSize, style: tt.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            l.coverSizeSubtitle,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: 'small', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.coverSizeSmall, maxLines: 1))),
                                ButtonSegment(value: 'medium', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.coverSizeMedium, maxLines: 1))),
                                ButtonSegment(value: 'large', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.coverSizeLarge, maxLines: 1))),
                              ],
                              selected: {_coverSize},
                              onSelectionChanged: _loaded ? (selected) {
                                final v = selected.first;
                                setState(() => _coverSize = v);
                                PlayerSettings.setCoverSize(v);
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
                    // iPadOS ignores orientation preferences for multitasking
                    // apps, so the lock can't work there - hide it on iPad.
                    if (!(Platform.isIOS && MediaQuery.sizeOf(context).shortestSide >= 600)) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: const Text('Lock rotation'),
                        subtitle: Text(
                          _lockPortrait
                              ? 'Screen stays in portrait'
                              : 'Screen can rotate with the device',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        value: _lockPortrait,
                        onChanged: _loaded ? (v) {
                          setState(() => _lockPortrait = v);
                          PlayerSettings.setLockPortrait(v);
                          applyOrientationLock();
                        } : null,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // ── Customize Stats ──
                CollapsibleSection(
                  key: _keyFor('Customize Stats'),
                  icon: Icons.bar_chart_rounded,
                  title: l.settingsCustomizeStats,
                  cs: cs,
                  isExpanded: _expandedSection == 'Customize Stats',
                  onExpansionChanged: (v) => _onSectionExpanded('Customize Stats', v),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.statsGoalTitle, style: tt.titleSmall),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              multiSelectionEnabled: true,
                              emptySelectionAllowed: true,
                              segments: [
                                for (final p in PlayerSettings.statsGoalPeriods)
                                  ButtonSegment(
                                      value: p,
                                      label: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(_statsGoalLabel(l, p), maxLines: 1))),
                              ],
                              selected: {
                                for (final e in _statsGoalMinutes.entries)
                                  if (e.value > 0) e.key
                              },
                              onSelectionChanged: _loaded ? (selected) {
                                for (final p in PlayerSettings.statsGoalPeriods) {
                                  final on = selected.contains(p);
                                  if (on == (_statsGoalMinutes[p]! > 0)) continue;
                                  _toggleStatsGoal(p, on);
                                }
                              } : null,
                              style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            ),
                          ),
                          if (_statsGoalMinutes.values.every((m) => m == 0))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(l.statsGoalOff,
                                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            ),
                          for (final p in PlayerSettings.statsGoalPeriods)
                            if (_statsGoalMinutes[p]! > 0)
                              _statsGoalRow(cs, tt, l, p),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(children: [
                        Expanded(
                            child: Text(l.statsWeekStartsOn,
                                style: tt.bodyMedium
                                    ?.copyWith(color: cs.onSurfaceVariant))),
                        DropdownButton<int>(
                          value: _statsWeekStart,
                          underline: const SizedBox.shrink(),
                          items: [
                            DropdownMenuItem(value: 0, child: Text(l.absorbingSharedSunday)),
                            DropdownMenuItem(value: 1, child: Text(l.absorbingSharedMonday)),
                            DropdownMenuItem(value: 6, child: Text(l.absorbingSharedSaturday)),
                          ],
                          onChanged: _loaded
                              ? (v) {
                                  if (v == null) return;
                                  setState(() => _statsWeekStart = v);
                                  PlayerSettings.setStatsWeekStart(v);
                                }
                              : null,
                        ),
                      ]),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.statsBookChallengeTitle, style: tt.titleSmall),
                          _statsStepperRow(cs, tt, l.statsBookChallengeDesc,
                              _statsBookGoal == 0 ? l.statsGoalOff : l.statsBooksShort(_statsBookGoal),
                              onTapValue: _editStatsBookTarget,
                              onMinus: _statsBookGoal > 0
                                  ? () {
                                      setState(() => _statsBookGoal--);
                                      PlayerSettings.setStatsBookGoal(_statsBookGoal);
                                    }
                                  : null,
                              onPlus: _statsBookGoal < 500
                                  ? () {
                                      setState(() => _statsBookGoal++);
                                      PlayerSettings.setStatsBookGoal(_statsBookGoal);
                                    }
                                  : null),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.statsChartTitle, style: tt.titleSmall),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: 'bar', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.statsChartBar, maxLines: 1))),
                                ButtonSegment(value: 'line', label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.statsChartLine, maxLines: 1))),
                              ],
                              selected: {_statsChartStyle},
                              onSelectionChanged: _loaded ? (selected) {
                                setState(() => _statsChartStyle = selected.first);
                                PlayerSettings.setStatsChartStyle(_statsChartStyle);
                              } : null,
                              style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<int>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: 7, label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.statsChartDays7, maxLines: 1))),
                                ButtonSegment(value: 30, label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.statsChartDays30, maxLines: 1))),
                              ],
                              selected: {_statsChartRange},
                              onSelectionChanged: _loaded ? (selected) {
                                setState(() => _statsChartRange = selected.first);
                                PlayerSettings.setStatsChartRange(_statsChartRange);
                              } : null,
                              style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.statsSectionsTitle, style: tt.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            l.dragToReorderTapEye,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          _statsSectionsList(cs, tt, l),
                        ],
                      ),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.cardBackground, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: 'blurred', icon: const Icon(Icons.blur_on_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.cardBackgroundBlurred))),
                            ButtonSegment(value: 'gradient', icon: const Icon(Icons.gradient_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.cardBackgroundGradient))),
                            ButtonSegment(value: 'off', icon: const Icon(Icons.block_rounded, size: 18), label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.off))),
                          ],
                          selected: {_cardBackground},
                          onSelectionChanged: _loaded ? (s) {
                            if (s.isEmpty) return;
                            setState(() => _cardBackground = s.first);
                            PlayerSettings.setCardBackground(s.first);
                          } : null,
                          style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        )),
                      ]),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.cardScrubbers,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            switch (_cardScrubberMode) {
                              CardScrubberMode.both =>
                                l.cardScrubbersBothSubtitle,
                              CardScrubberMode.chapter =>
                                l.cardScrubbersChapterSubtitle,
                              CardScrubberMode.locked =>
                                l.cardScrubbersLockedSubtitle,
                            },
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CardScrubberModeSelector(
                            mode: _cardScrubberMode,
                            enabled: _loaded,
                            onChanged: (mode) {
                              setState(() => _cardScrubberMode = mode);
                              PlayerSettings.setCardScrubberMode(mode);
                            },
                          ),
                        ],
                      ),
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
                        // The dedicated Podcasts tab implies merged libraries;
                        // show it locked on rather than a toggle that snaps back.
                        final effectiveMerge =
                            _mergeAbsorbingLibraries || _podcastTabEnabled;
                        return SwitchListTile(
                          title: Row(children: [
                            Flexible(child: Text(w.mergeLibraries)),
                            _infoIcon(w.mergeLibrariesInfoTitle, w.mergeLibrariesInfoContent),
                          ]),
                          subtitle: Text(
                            _podcastTabEnabled
                                ? l.settingsMergeImpliedByPodcastTab
                                : effectiveMerge
                                    ? w.mergeLibrariesOnSubtitle
                                    : w.mergeLibrariesOffSubtitle,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          value: effectiveMerge,
                          onChanged: (_loaded && !_podcastTabEnabled) ? (v) async {
                            setState(() => _mergeAbsorbingLibraries = v);
                            await PlayerSettings.setMergeAbsorbingLibraries(v);
                            unawaited(lib.syncQueueAutoDownloads());
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
                        if (_mergeAbsorbingLibraries || _podcastTabEnabled) ...[
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
                        if (_bookQueueMode != 'off' || _podcastQueueMode != 'off') ...[
                          const SizedBox(height: 4),
                          SwitchListTile(
                            title: Text(l.autoDownloadQueue),
                            subtitle: Text(
                              _queueAutoDownload
                                  ? l.autoDownloadQueueOnSubtitle(_rollingDownloadCount)
                                  : l.autoDownloadQueueOffSubtitle,
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            value: _queueAutoDownload,
                            onChanged: _loaded ? (v) async {
                              setState(() => _queueAutoDownload = v);
                              await PlayerSettings.setQueueAutoDownload(v);
                              unawaited(lib.syncQueueAutoDownloads());
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Row(children: [
                        GestureDetector(
                          onTap: _loaded ? () => _setDefaultSpeed(_defaultSpeed - 0.05) : null,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: cs.onSurface.withValues(alpha: 0.08)),
                            child: Icon(Icons.remove_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                        ),
                        Expanded(child: AbsorbSlider(
                          value: _defaultSpeed,
                          min: 0.5,
                          max: 3.0,
                          divisions: 50,
                          activeColor: cs.primary,
                          onChanged: _loaded ? _setDefaultSpeed : null,
                        )),
                        GestureDetector(
                          onTap: _loaded ? () => _setDefaultSpeed(_defaultSpeed + 0.05) : null,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: cs.onSurface.withValues(alpha: 0.08)),
                            child: Icon(Icons.add_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(52, 0, 52, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0.5x', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
                          Text('3.0x', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
                        ],
                      ),
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
                            onPressed: _loaded ? () => _setDefaultSpeed(s) : null,
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
                    if (Platform.isIOS)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          l.iosLockScreenSkipHint,
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant, height: 1.35),
                        ),
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
                    // Long skip pair (GH #242)
                    SwitchListTile(
                      title: Text(l.longSkipButtons),
                      subtitle: Text(
                        _longSkipButtons ? l.longSkipButtonsOnSubtitle : l.longSkipButtonsOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      value: _longSkipButtons,
                      onChanged: _loaded ? (v) {
                        setState(() => _longSkipButtons = v);
                        PlayerSettings.setLongSkipButtons(v);
                      } : null,
                    ),
                    if (_longSkipButtons) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.longSkipBack, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            Text(l.minutesValue(_longBackSkip ~/ 60), style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600, color: cs.primary)),
                          ],
                        ),
                      ),
                      AbsorbSlider(
                        value: (_longBackSkip ~/ 60).toDouble(),
                        min: 1, max: 10, divisions: 9,
                        onChanged: _loaded ? (v) {
                          setState(() => _longBackSkip = v.round() * 60);
                          PlayerSettings.setLongBackSkip(v.round() * 60);
                        } : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.longSkipForward, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            Text(l.minutesValue(_longForwardSkip ~/ 60), style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600, color: cs.primary)),
                          ],
                        ),
                      ),
                      AbsorbSlider(
                        value: (_longForwardSkip ~/ 60).toDouble(),
                        min: 1, max: 10, divisions: 9,
                        onChanged: _loaded ? (v) {
                          setState(() => _longForwardSkip = v.round() * 60);
                          PlayerSettings.setLongForwardSkip(v.round() * 60);
                        } : null,
                      ),
                    ],
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

                // ── Media Controls ──
                CollapsibleSection(
                  key: _keyFor('Media Controls'),
                  icon: Icons.dvr_rounded,
                  title: l.sectionMediaControls,
                  cs: cs,
                  isExpanded: _expandedSection == 'Media Controls',
                  onExpansionChanged: (v) => _onSectionExpanded('Media Controls', v),
                  children: [
                    SwitchListTile(
                      title: Text(Platform.isIOS
                          ? l.chapterProgressInNotificationIos
                          : l.chapterProgressInNotification),
                      subtitle: Text(
                        _notifChapterProgress
                            ? (Platform.isIOS
                                ? l.chapterProgressOnSubtitleIos
                                : l.chapterProgressOnSubtitle)
                            : l.chapterProgressOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _notifChapterProgress,
                      onChanged: _loaded ? (v) {
                        setState(() => _notifChapterProgress = v);
                        PlayerSettings.setNotificationChapterProgress(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // Cross-platform: drops the seek action so the scrubber in the
                    // notification / lockscreen / car can't be dragged.
                    SwitchListTile(
                      title: Text(l.lockSeekBar),
                      subtitle: Text(
                        _lockSeekBar ? l.lockSeekBarOnSubtitle : l.lockSeekBarOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _lockSeekBar,
                      onChanged: _loaded ? (v) {
                        setState(() => _lockSeekBar = v);
                        PlayerSettings.setLockSeekBar(v);
                      } : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: Text(Platform.isIOS
                          ? l.carConnectAutoplayIos
                          : l.carConnectAutoplay),
                      subtitle: Text(
                        _autoplayOnCarConnect
                            ? l.carConnectAutoplayOnSubtitle
                            : l.carConnectAutoplayOffSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _autoplayOnCarConnect,
                      onChanged: _loaded ? (v) {
                        setState(() => _autoplayOnCarConnect = v);
                        PlayerSettings.setAutoplayOnCarConnect(v);
                      } : null,
                    ),
                    // Android only: chooses which pair fills the phone media
                    // player's two extra slots. iOS uses CarPlay's own buttons.
                    if (Platform.isAndroid) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: const Text('Duck brief interruptions'),
                        subtitle: Text(
                          _duckBriefInterruptions
                              ? 'Notifications and prompts lower the volume instead of pausing'
                              : 'Notifications and prompts pause playback',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        value: _duckBriefInterruptions,
                        onChanged: _loaded ? (v) {
                          setState(() => _duckBriefInterruptions = v);
                          PlayerSettings.setDuckBriefInterruptions(v);
                        } : null,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: Text(l.speedBookmarkInControls),
                        subtitle: Text(
                          _notifSpeedBookmark
                              ? l.speedBookmarkOnSubtitle
                              : l.speedBookmarkOffSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        value: _notifSpeedBookmark,
                        onChanged: _loaded ? (v) {
                          setState(() => _notifSpeedBookmark = v);
                          PlayerSettings.setMediaControlsSpeedBookmark(v);
                        } : null,
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
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(l.buttonDuringSleepTimer, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
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
                          selected: {_sleepButtonMode},
                          onSelectionChanged: _loaded ? (v) {
                            setState(() => _sleepButtonMode = v.first);
                            PlayerSettings.setSleepButtonMode(v.first);
                          } : null,
                        ),
                      ),
                    ),
                    if (_sleepButtonMode != 'off')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(l.buttonDuringSleepTimerHint,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11)),
                      ),
                    // Shared by shake and button add-time modes, so it shows
                    // whenever either trigger needs it
                    if (_shakeMode == 'addTime' || _sleepButtonMode == 'addTime') ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.sleepAddAmount, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(children: [
                        Icon(Icons.replay_rounded, size: 18,
                          color: _sleepRewindSeconds > 0 ? cs.primary : cs.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(child: Text(l.sleepTimerSheetRewindOnSleep,
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                        Text(_rewindLabel(_sleepRewindSeconds, l),
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _sleepRewindSeconds > 0 ? cs.primary : cs.onSurfaceVariant)),
                      ]),
                    ),
                    AbsorbSlider(
                      value: (_sleepRewindSeconds / 60).clamp(0.0, _maxRewindMinutes.toDouble()),
                      min: 0,
                      max: _maxRewindMinutes.toDouble(),
                      divisions: _maxRewindMinutes,
                      onChanged: _loaded ? (v) {
                        final seconds = (v * 60).round();
                        setState(() => _sleepRewindSeconds = seconds);
                        PlayerSettings.setSleepRewindSeconds(seconds);
                      } : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.off, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
                          Text(l.sleepTimerSheetMinShort(_maxRewindMinutes),
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
                        ],
                      ),
                    ),
                    if (_sleepRewindSeconds > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
                        child: Text(
                          l.sleepRewindUndoNote(
                              SleepTimerService.sleepRewindUndoWindow.inMinutes),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(l.downloadOverWifiOnly, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: true, label: Text(l.downloadOverWifiOnSubtitle)),
                              ButtonSegment(value: false, label: Text(l.downloadOverWifiOffSubtitle)),
                            ],
                            selected: {_wifiOnlyDownloads},
                            onSelectionChanged: _loaded ? (v) {
                              setState(() => _wifiOnlyDownloads = v.first);
                              PlayerSettings.setWifiOnlyDownloads(v.first);
                            } : null,
                          )),
                          const SizedBox(height: 8),
                        ],
                      ),
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
                    SwitchListTile(
                      title: const Text('Auto-download series'),
                      subtitle: Text(
                        _autoSeriesDownloadDefault
                            ? 'Starting a book in a series keeps the next books downloaded'
                            : 'Turn on series downloads yourself from the series menu',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      value: _autoSeriesDownloadDefault,
                      onChanged: _loaded ? (v) {
                        setState(() => _autoSeriesDownloadDefault = v);
                        PlayerSettings.setAutoSeriesDownloadDefault(v);
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
                    _buildAutoDownloadSources(lib, l, cs, tt),
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
                            onSelectionChanged: (v) async {
                              setState(() => _rollingDownloadCount = v.first);
                              await PlayerSettings.setRollingDownloadCount(v.first);
                              if (_queueAutoDownload) {
                                unawaited(lib.syncQueueAutoDownloads());
                              }
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
                                  showOverlayToast(context, l.streamingCacheCleared,
                                      icon: Icons.delete_outline_rounded);
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
                    Consumer<LibraryProvider>(builder: (context, lib, _) {
                      final podcastLibs = lib.libraries
                          .whereType<Map<String, dynamic>>()
                          .where((l) => (l['mediaType'] as String? ?? 'book') == 'podcast')
                          .toList();
                      if (podcastLibs.isEmpty) return const SizedBox.shrink();
                      final currentName = podcastLibs.firstWhere(
                        (p) => p['id'] == _podcastTabLibraryId,
                        orElse: () => podcastLibs.first,
                      )['name'] as String? ?? '';
                      return Column(children: [
                        SwitchListTile(
                          title: Text(l.settingsPodcastTab),
                          subtitle: Text(l.settingsPodcastTabDesc,
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          value: _podcastTabEnabled,
                          onChanged: _loaded ? (v) async {
                            var libId = _podcastTabLibraryId;
                            if (v && !podcastLibs.any((p) => p['id'] == libId)) {
                              libId = podcastLibs.first['id'] as String;
                              await PlayerSettings.setPodcastTabLibraryId(libId);
                            }
                            setState(() {
                              _podcastTabEnabled = v;
                              _podcastTabLibraryId = libId;
                            });
                            await PlayerSettings.setPodcastTabEnabled(v);
                          } : null,
                        ),
                        if (_podcastTabEnabled && podcastLibs.length > 1)
                          ListTile(
                            title: Text(l.settingsPodcastTabLibrary),
                            subtitle: Text(currentName,
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                            onTap: () => _pickPodcastTabLibrary(podcastLibs),
                          ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                      ]);
                    }),
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
                    if (_curLibId != null) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                        child: Text(
                          l.currentLibrarySettingsTitle(lib.selectedLibrary?['name'] as String? ?? l.libraryFallback),
                          style: tt.titleSmall,
                        ),
                      ),
                      InkWell(
                        onTap: _loaded ? () => _pickCurrentLibraryCoverShape() : null,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(children: [
                            Expanded(child: Text(l.coverShapeLabel)),
                            Text(_coverShapeValueLabel(l, _curLibCoverShape),
                                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            Icon(Icons.chevron_right_rounded,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          ]),
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: Text(l.currentLibrarySkipOverride),
                        subtitle: Text(
                          _curLibSkipOverride
                              ? l.currentLibrarySkipOverrideOnSubtitle
                              : l.currentLibrarySkipOverrideOffSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        value: _curLibSkipOverride,
                        onChanged: _loaded ? (v) {
                          setState(() => _curLibSkipOverride = v);
                          if (v) {
                            PlayerSettings.setSkipOverride(_curLibId!,
                                forward: _curLibSkipForward, back: _curLibSkipBack);
                          } else {
                            PlayerSettings.setSkipOverride(_curLibId!, forward: null, back: null);
                          }
                        } : null,
                      ),
                      if (_curLibSkipOverride) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.currentLibrarySkipBack, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                              Text(l.secondsValue(_curLibSkipBack.toString()), style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600, color: cs.primary)),
                            ],
                          ),
                        ),
                        AbsorbSlider(
                          value: _curLibSkipBack.toDouble(),
                          min: 5, max: 60, divisions: 11,
                          onChanged: _loaded ? (v) {
                            setState(() => _curLibSkipBack = v.round());
                            PlayerSettings.setSkipOverride(_curLibId!,
                                forward: _curLibSkipForward, back: v.round());
                          } : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.currentLibrarySkipForward, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                              Text(l.secondsValue(_curLibSkipForward.toString()), style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600, color: cs.primary)),
                            ],
                          ),
                        ),
                        AbsorbSlider(
                          value: _curLibSkipForward.toDouble(),
                          min: 5, max: 60, divisions: 11,
                          onChanged: _loaded ? (v) {
                            setState(() => _curLibSkipForward = v.round());
                            PlayerSettings.setSkipOverride(_curLibId!,
                                forward: v.round(), back: _curLibSkipBack);
                          } : null,
                        ),
                      ],
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
                            showOverlayToast(context, l.notificationsAlreadyEnabled,
                                icon: Icons.notifications_active_outlined);
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
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: Text(l.settingsEpisodeNotifs),
                      subtitle: Text(
                          '${l.settingsEpisodeNotifsDesc} - ${_episodeNotifLabel(l)}',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                      onTap: _loaded ? _pickEpisodeNotifInterval : null,
                    ),
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
                            showOverlayToast(context, l.batteryAlreadyUnrestricted,
                                icon: Icons.battery_saver_outlined);
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
                        showOverlayToast(
                          context,
                          v
                              ? l.loggingEnabledSnackbar
                              : l.loggingDisabledSnackbar,
                          icon: Icons.article_outlined,
                        );
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
                            await LogService().shareLogs(
                              serverVersion: auth.serverVersion,
                              sharePositionOrigin: shareOriginFor(context),
                            );
                          } catch (e) {
                            if (mounted) {
                              showOverlayToast(
                                context,
                                l.failedToShare(e.toString()),
                                icon: Icons.error_outline_rounded,
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
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l.clearLogsQuestion),
                              content: Text(l.clearLogsContent),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.clear)),
                              ],
                            ),
                          );
                          if (confirmed != true || !mounted) return;
                          await LogService().clearLogs();
                          if (mounted) {
                            showOverlayToast(context, l.logsCleared,
                                icon: Icons.delete_outline_rounded);
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
                    ListTile(
                      title: Text(l.navHoldSettingTitle),
                      subtitle: Text(l.navHoldSettingSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showNavHoldDialog,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
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
                    if (Platform.isAndroid) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: Row(children: [
                          Flexible(child: Text(l.mp3IndexSeeking)),
                          _infoIcon(l.mp3IndexSeekingInfoTitle, l.mp3IndexSeekingInfoContent),
                        ]),
                        subtitle: Text(
                          _mp3IndexSeeking
                              ? l.mp3IndexSeekingOnSubtitle
                              : l.mp3IndexSeekingOffSubtitle,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        value: _mp3IndexSeeking,
                        onChanged: _loaded ? (v) {
                          setState(() => _mp3IndexSeeking = v);
                          PlayerSettings.setMp3IndexSeeking(v);
                        } : null,
                      ),
                    ],
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
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.record_voice_over_rounded, color: cs.primary),
                      title: Text(l.transcriptionTitle),
                      subtitle: Text(l.transcriptionAdvancedSubtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const TranscriptionSettingsScreen())),
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

                // ── Backup and sync ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Icon(Icons.cloud_sync_rounded, color: cs.primary),
                      title: Text(l.backupAndSync),
                      subtitle: Text(_backupSyncStatus(l),
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onTap: () async {
                        await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BackupSyncScreen()));
                        if (mounted) await _refreshSyncStatus();
                      },
                      // Shortcut for the impatient: push straight from here
                      // rather than opening the screen for one button. Only
                      // offered while sync is on, since there is nowhere to
                      // send it otherwise.
                      onLongPress: _syncOn ? () => _uploadSyncNow(l) : null,
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
                      // Flavor prefix is an Android distribution concept
                      // (GitHub / Play Store / F-Droid). iOS has no flavor, so
                      // it keeps the plain version. Beta builds add which
                      // beta of the cycle this is; full releases show nothing.
                      _versionLine(l),
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
                        showOverlayToast(context, l.onLatestVersion,
                            icon: Icons.check_circle_outline_rounded);
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
          )
          else
            SliverToBoxAdapter(
              child: SettingsSearchResults(
                results: filterSettingEntries(
                    settingsSearchEntries(context), _settingsQuery),
                onOpen: _openSearchResult,
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
    final api = context.read<AuthProvider>().apiService;
    final legacyCount = dl.legacyExternalDownloads.length;

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

            if (legacyCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.legacyDownloadsNotice(legacyCount),
                          style: tt.bodySmall?.copyWith(color: cs.onSurface)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await dl.dismissLegacyDownloads();
                            if (mounted) setState(() {});
                          },
                          child: Text(l.dismiss),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: api == null
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  await dl.redownloadAllLegacy(api);
                                  if (mounted) {
                                    showOverlayToast(context, l.redownloadStarted,
                                        icon: Icons.download_rounded);
                                  }
                                },
                          child: Text(l.redownload),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                  // Storage Access Framework: the user grants a folder through
                  // the system picker, no storage permission needed.
                  Uri? treeUri;
                  try {
                    treeUri = await FileDownloader().uri.pickDirectory(
                      startLocation: SharedStorage.downloads,
                      persistedUriPermission: true,
                    );
                  } catch (e) {
                    if (mounted) {
                      showOverlayToast(context, l.cannotWriteToFolder,
                          icon: Icons.error_outline_rounded);
                    }
                    return;
                  }
                  if (treeUri == null) return; // user cancelled
                  // Verify we can actually create files in the chosen folder.
                  try {
                    final probe = await FileDownloader()
                        .uri
                        .createDirectory(treeUri, '.absorb_write_test');
                    await FileDownloader().uri.deleteFile(probe);
                  } catch (e) {
                    if (mounted) {
                      showOverlayToast(context, l.cannotWriteToFolder,
                          icon: Icons.error_outline_rounded);
                    }
                    return;
                  }
                  await dl.setCustomDownloadUri(treeUri);
                  final label = await dl.downloadLocationLabel;
                  if (mounted) {
                    setState(() => _downloadLocationLabel = label);
                    showOverlayToast(context, l.downloadLocationSetTo(label),
                        icon: Icons.folder_outlined);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),

            // Reset to default button
            if (dl.customDownloadUri != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l.resetToDefault),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await dl.setCustomDownloadUri(null);
                    final label = await dl.downloadLocationLabel;
                    if (mounted) {
                      setState(() => _downloadLocationLabel = label);
                      showOverlayToast(context, l.resetToDefaultStorage,
                          icon: Icons.restart_alt_rounded);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _syncUploading = false;

  /// Long-press upload from the settings row. Goes through the content check
  /// rather than forcing a push: an upload that changes nothing still bumps the
  /// file's timestamp, which wakes the other device to apply an identical copy.
  Future<void> _uploadSyncNow(AppLocalizations l) async {
    if (_syncUploading) return;
    _syncUploading = true;
    HapticFeedback.mediumImpact();
    try {
      final result = await SettingsSyncService().pushIfChanged();
      if (!mounted) return;
      await _refreshSyncStatus();
      if (!mounted) return;
      final message = result.ok
          ? (result.message == 'unchanged'
              ? l.syncSettingsUpToDate
              : l.syncSettingsUploaded)
          : l.syncSettingsNetworkError;
      showOverlayToast(
        context,
        message,
        icon: result.ok
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
      );
    } finally {
      _syncUploading = false;
    }
  }

  DateTime? _syncLastAt;
  bool _syncOn = false;

  /// Live status for the settings row, so the common question - is it syncing,
  /// and when did it last manage it - is answered without opening the screen.
  String _backupSyncStatus(AppLocalizations l) {
    if (!_syncOn) return l.backupAndSyncSubtitle;
    final at = _syncLastAt;
    final status =
        at == null ? l.syncSettingsNever : l.syncSettingsLastSynced(_syncTimeAgo(l, at));
    // A long-press nobody is told about is a long-press nobody uses, and this
    // row is the only place it could be discovered.
    return '$status  ·  ${l.syncSettingsHoldToUpload}';
  }

  static String _syncTimeAgo(AppLocalizations l, DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return l.justNow.toLowerCase();
    if (d.inMinutes < 60) return l.minutesAgo(d.inMinutes);
    if (d.inHours < 24) return l.hoursAgo(d.inHours);
    return l.daysAgo(d.inDays);
  }

  Future<void> _refreshSyncStatus() async {
    final on = await SettingsSyncService().getEnabled();
    final at = await SettingsSyncService().getLastSyncTime();
    if (!mounted) return;
    setState(() {
      _syncOn = on;
      _syncLastAt = at;
    });
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
    SavedAccount? activeAccount;
    for (final a in accounts) {
      if (a.serverUrl == auth.serverUrl && a.username == auth.username) {
        activeAccount = a;
        break;
      }
    }

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
                if (activeAccount != null)
                  InkResponse(
                    onTap: () { Navigator.pop(ctx); _editServerConnection(context, activeAccount!); },
                    radius: 22,
                    child: Padding(padding: const EdgeInsets.all(6),
                      child: Icon(Icons.edit_rounded, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                  ),
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
          InkWell(
            onTap: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen(),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Icon(Icons.password_rounded, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.changePasswordTitle, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(l.changePasswordSubtitle, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ])),
                Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurfaceVariant),
              ]),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AuthSessionsScreen(),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Icon(Icons.devices_rounded, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.manageSessionsTitle, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(l.manageSessionsSubtitle, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ])),
                Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurfaceVariant),
              ]),
            ),
          ),
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
                onLongPress: () { Navigator.pop(ctx); _accountOptions(context, account); },
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
      showOverlayToast(
        context,
        result.disconnected
            ? l.rmabConfigDisconnectedSnackbar
            : l.rmabConfigSavedSnackbar,
        icon: result.disconnected
            ? Icons.link_off_rounded
            : Icons.check_circle_outline_rounded,
      );
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
              if (context.mounted) {
                await context.read<AuthProvider>().logout(
                  keepServer: true,
                  revokeServerSession: true,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
  }

  Future<void> _addAccount(
    BuildContext context, {
    SavedAccount? prefillAccount,
  }) async {
    // Stop playback and sync before navigating to login
    await _stopAndSyncPlayback();
    if (!context.mounted) return;
    final currentServer = context.read<AuthProvider>().serverUrl;
    // Navigate to login screen as a pushed route (not replacing current)
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          prefillAccount: prefillAccount,
          prefillServerUrl: prefillAccount == null ? currentServer : null,
        ),
      ),
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

  /// Long-press menu for a saved (non-active) account: edit its server
  /// address or remove it.
  void _accountOptions(BuildContext context, SavedAccount account) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 8),
        ListTile(
          leading: Icon(Icons.dns_rounded, color: cs.primary),
          title: Text(l.editServerConnectionAction),
          onTap: () { Navigator.pop(ctx); _editServerConnection(context, account); }),
        ListTile(
          leading: Icon(Icons.delete_outline_rounded, color: cs.error),
          title: Text(l.removeAccountAction, style: TextStyle(color: cs.error)),
          onTap: () { Navigator.pop(ctx); _removeAccount(context, account); }),
        const SizedBox(height: 8),
      ])),
    );
  }

  /// Edit the URL and custom proxy headers for one saved account without
  /// losing its scoped data.
  Future<void> _editServerConnection(
      BuildContext context, SavedAccount account) async {
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<ServerConnectionSettings>(
      context: context,
      builder: (_) => ServerConnectionEditor(
        username: account.username,
        serverUrl: account.serverUrl,
        customHeaders: account.customHeaders,
      ),
    );
    if (result == null || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final wasActive = account.serverUrl == auth.serverUrl &&
        account.username == auth.username;
    final ok = await auth.editServerConnection(
      account,
      result.serverUrl,
      result.customHeaders,
    );
    if (!context.mounted) return;
    if (ok && wasActive) context.read<LibraryProvider>().refresh();
    setState(() {});
    showOverlayToast(
      context,
      ok
          ? l.editServerConnectionUpdated
          : l.editServerConnectionFailed,
      icon: ok
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
    );
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

    if (account.token.isEmpty) {
      await _addAccount(context, prefillAccount: account);
      return;
    }

    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    auth.beginAccountSwitch();
    try {
      // The startup view is visible now, so none of the previous account's
      // Settings or Stats state remains on screen during the transition.
      await _stopAndSyncPlayback();
      final switched = await auth.switchToAccount(account);
      if (!switched) return;

      // Re-init the library provider with the new user and keep the startup
      // view up until its first account-specific data refresh completes.
      lib.updateAuth(auth);
      await lib.waitForActiveAccountReady();
    } finally {
      auth.finishAccountSwitch();
    }
  }
}
