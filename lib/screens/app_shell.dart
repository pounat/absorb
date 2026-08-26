import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/volume_key_service.dart';
import '../services/chromecast_service.dart';
import '../services/home_widget_service.dart';
import '../services/sleep_timer_service.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import '../utils/cover_accent.dart';
import '../main.dart'
    show snappyTransitionsNotifier, einkModeNotifier, coverSchemeNotifier, rootNavigatorKey, applyOrientationLock, applyEinkModeTheme;
import '../services/scoped_prefs.dart';
import 'dart:convert';
import 'admin_screen.dart';
import 'admin_api_keys_screen.dart';
import 'admin_rmab_screen.dart';
import '../widgets/rmab_config_sheet.dart'
    show showRmabConfigSheet, kRmabBaseUrlKey, kRmabApiTokenKey, kRmabLegacyUrlKey;
import '../widgets/rmab_search_results_sheet.dart';
import 'admin_email_screen.dart';
import 'admin_libraries_screen.dart';
import 'admin_server_logs_screen.dart';
import 'admin_server_settings_screen.dart';
import 'admin_sessions_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_upload_screen.dart';
import 'admin_users_screen.dart';
import 'bookmarks_screen.dart';
import 'downloads_screen.dart';
import 'upcoming_releases_screen.dart';
import '../services/ebook_cache.dart';
import '../widgets/action_pill.dart';
import '../widgets/book_detail_sheet.dart' show showBookDetailSheet;
import '../widgets/ebook_router.dart';
import '../widgets/nav_hold_options.dart';
import '../widgets/sleep_timer_sheet.dart';
import '../l10n/app_localizations.dart';
import '../services/wording.dart';
import '../services/android_auto_service.dart';
import '../services/carplay_service.dart';
import '../widgets/expanded_card.dart';
import 'absorbing_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'app_shell_navigation_policy.dart';
import '../widgets/library_picker_sheet.dart';
import '../widgets/welcome_sheet.dart';
import '../services/review_service.dart';
import '../services/settings_sync_service.dart';
import '../services/update_checker_service.dart';
import '../widgets/update_dialog.dart';
import '../widgets/overlay_toast.dart';

class AppShell extends StatefulWidget {
  final bool startOnAbsorbing;

  const AppShell({super.key, this.startOnAbsorbing = false});

  /// Navigate to the Absorbing tab using BuildContext (ancestor lookup).
  static void goToAbsorbing(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    state?._switchToAbsorbing();
  }

  /// Navigate to the Absorbing tab without needing a context.
  static void goToAbsorbingGlobal() {
    _AppShellState._instance?._switchToAbsorbing();
  }

  /// Track when expanded card is opened/closed externally (e.g. chevron tap).
  static void setExpandedOpen(bool open) {
    _AppShellState._instance?._expandedIsOpen = open;
  }

  /// Switch to the Library tab and focus the search bar. Used by the
  /// app-icon "Search" shortcut. Returns false when the shell isn't mounted
  /// yet so callers can retry during cold start.
  static bool openSearchGlobal() {
    final inst = _AppShellState._instance;
    if (inst == null) return false;
    inst._openSearch();
    return true;
  }

  /// Switch to the Library tab and apply a tag filter. Used by the book
  /// detail sheet's tag chip so tapping a tag jumps the user to the library
  /// view filtered by that tag. Returns false when the shell or library
  /// state isn't mounted yet.
  static bool openLibraryWithTagFilterGlobal(String tag) =>
      _applyLibraryFilterGlobal((s) => s.applyTagFilter(tag));

  /// Switch to the Library tab and apply a genre filter. Mirrors the tag
  /// version above; used by the genre chip in book detail.
  static bool openLibraryWithGenreFilterGlobal(String genre) =>
      _applyLibraryFilterGlobal((s) => s.applyGenreFilter(genre));

  static bool _applyLibraryFilterGlobal(
    void Function(LibraryScreenState) apply,
  ) {
    final inst = _AppShellState._instance;
    if (inst == null) return false;
    // If the full-screen expanded player is on top of the shell, pop it
    // first. Otherwise switching to the Library tab leaves the player
    // covering the filtered library underneath. Caller (e.g. the book
    // detail sheet) has already popped its own modal route at this point.
    if (inst._expandedIsOpen && inst.mounted) {
      Navigator.of(inst.context, rootNavigator: true).maybePop();
    }
    inst._navigateTo(1);
    // The retry budget has to survive the fade transition (~200ms by
    // default, see `_fadeController` and `_navigateTo`) plus the library
    // widget's own mount + first build. On cold start that easily takes
    // 300-500ms before `_libraryKey.currentState` becomes non-null. ~3s
    // worth of frames is generous enough to cover slow devices and stingy
    // enough to give up if something is genuinely broken.
    const maxAttempts = 180; // ~3s at 60fps
    var attempts = 0;
    void tryApply() {
      if (!inst.mounted) return;
      final state = inst._libraryKey.currentState;
      if (state != null) {
        apply(state);
        return;
      }
      if (++attempts < maxAttempts) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tryApply());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryApply());
    return true;
  }

  /// Called by Home (callingTab=0) and Library (callingTab=1) after their
  /// first frame. Lets the AppShell re-sync the bottom-nav listener to the
  /// right notifier — handles both "screen state didn't exist on initial
  /// attach" and "lazy attach attached to the wrong tab during a fade
  /// transition" (LibraryProvider notify can rebuild AppShell mid-fade and
  /// schedule a postFrame that fires before _currentIndex transitions).
  static void notifyScreenReady(int callingTab) {
    _AppShellState._instance?._reattachIfNeeded(callingTab);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static _AppShellState? _instance;

  // Tabs: 0=Home, 1=Library, 2=Absorbing (default), 3=Stats, 4=Settings
  int _currentIndex = 2; // overridden by user preference in initState

  // Dedicated Podcasts tab (optional 6th destination, display order Home,
  // Library, Podcasts, Absorbing, Stats, Settings). Stack pages keep their
  // historic 0-4 indexes: the Podcasts and Library destinations share page 1,
  // and which one is highlighted is derived from the selected library.
  bool _podcastTabEnabled = false;
  String _podcastTabLibraryId = '';
  final _homeKey = GlobalKey<HomeScreenState>();
  final _libraryKey = GlobalKey<LibraryScreenState>();
  final _player = AudioPlayerService();
  final _cast = ChromecastService();
  bool _playerHadBook = false;
  bool _wasPlaying = false;
  bool _lifecycleBackgrounded = false;
  String? _lastItemId;
  bool _expandedIsOpen = false;
  bool _wasCasting = false;
  DateTime? _lastBackPress;
  // Tracks which item's cover we derived the scheme from.
  String? _lastCoverItemId;

  // ── Scroll-to-hide bottom nav (driven by Library screen) ──
  late final AnimationController _navBarAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1.0,
  );
  VoidCallback? _navBarListener;

  // Lazily build tabs so startup on Absorbing does not initialize Home/Library
  // work until the user actually visits those tabs.
  final List<Widget?> _pages = List<Widget?>.filled(5, null, growable: false);

  void _openSearch() {
    if (!mounted) return;
    // If the user triggered Search while a pushed route (Downloads, Bookmarks,
    // Settings pages, etc.) is on top of the shell, pop back so the shell's
    // Library tab actually becomes visible.
    final nav = rootNavigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((r) => r.isFirst);
    }
    _navigateTo(1);
    // Library tab may need a frame to mount its state before we can focus
    // the search field. Retry up to a few frames to cover fade transitions.
    int attempts = 0;
    void tryFocus() {
      if (!mounted) return;
      final state = _libraryKey.currentState;
      if (state != null) {
        state.focusSearch();
        return;
      }
      if (++attempts < 10) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tryFocus());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryFocus());
  }

  void _switchToAbsorbing() {
    if (mounted) {
      _navigateTo(2);
      // Scroll to the currently playing book after the tab switch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AbsorbingScreen.scrollToActive();
      });
    }
  }

  void _navigateTo(int index) {
    if (index == _currentIndex) {
      // Already on this tab — handle re-tap actions
      if (index == 2) {
        // Absorbing tab: scroll to first card
        AbsorbingScreen.scrollToFirst();
      }
      return;
    }
    _ensurePageBuilt(index);
    _syncNavBarListener(index);
    if (snappyTransitionsNotifier.value || einkModeNotifier.value) {
      setState(() => _currentIndex = index);
    } else {
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = index;
        });
        _fadeController.forward();
      });
    }
  }

  /// Subscribe to the active screen's barsRevealNotifier when on Home or
  /// Library tab, and ensure the nav bar is visible on all other tabs.
  void _syncNavBarListener(int index) {
    _detachNavBarListener();
    // Snap visible immediately on every tab change so a partial-hide state
    // from another tab can never bleed into the new tab.
    _navBarAnimController.value = 1.0;
    ValueListenable<double>? notifier;
    if (index == 0) {
      notifier = _homeKey.currentState?.barsRevealNotifier;
    } else if (index == 1) {
      notifier = _libraryKey.currentState?.barsRevealNotifier;
    }
    if (notifier != null) {
      _activeBarNotifier = notifier;
      // Mirror the screen's continuous 0..1 reveal value directly onto the
      // controller so the bottom nav slides in lockstep with the header.
      _navBarListener = () {
        final v = notifier!.value.clamp(0.0, 1.0);
        // Skip no-op controller writes. AnimationController.value setter
        // notifies listeners (and triggers SizeTransition + Scaffold layout)
        // even when the value didn't change, which causes scroll jank when
        // the bar is already fully open/closed.
        if ((_navBarAnimController.value - v).abs() < 0.005) return;
        _navBarAnimController.value = v;
      };
      notifier.addListener(_navBarListener!);
      _navBarListener!();
    }
  }

  ValueListenable<double>? _activeBarNotifier;

  void _detachNavBarListener() {
    if (_navBarListener != null && _activeBarNotifier != null) {
      _activeBarNotifier!.removeListener(_navBarListener!);
    }
    _navBarListener = null;
    _activeBarNotifier = null;
  }

  /// Hook called by Home/Library when their state finishes mounting so we can
  /// pick up (or correct) the listener attach. Re-syncs unconditionally when
  /// the calling tab matches the current tab, even if a listener is already
  /// attached — that listener may have been attached to the wrong tab by the
  /// lazy-attach race during a fade transition.
  void _reattachIfNeeded(int callingTab) {
    if (!mounted) return;
    // Only act when the screen calling us is actually the active one. If the
    // user has navigated away in the meantime, leave the existing attachment
    // to whatever screen they're on.
    if (_currentIndex != callingTab) return;
    _syncNavBarListener(_currentIndex);
  }

  void _ensurePageBuilt(int index) {
    if (_pages[index] != null) return;
    switch (index) {
      case 0:
        _pages[index] = HomeScreen(key: _homeKey);
        break;
      case 1:
        _pages[index] = LibraryScreen(key: _libraryKey);
        break;
      case 2:
        _pages[index] = AbsorbingScreen(key: AbsorbingScreen.globalKey);
        break;
      case 3:
        _pages[index] = const StatsScreen();
        break;
      case 4:
        _pages[index] = const SettingsScreen();
        break;
    }
  }

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1.0,
  );

  void _loadStartScreen() {
    PlayerSettings.getStartScreen().then((idx) {
      if (mounted && idx != _currentIndex && idx >= 0 && idx <= 4) {
        setState(() => _currentIndex = idx);
        _ensurePageBuilt(idx);
        _restoreBookLibraryForCurrentTab(restoreLibraryPage: true);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _instance = this;
    EreaderVolumeNav.ensureHandler();
    if (!widget.startOnAbsorbing) _loadStartScreen();
    _ensurePageBuilt(_currentIndex);
    _playerHadBook = _player.hasBook;
    _wasPlaying = _player.isPlaying;
    _lastItemId = _player.currentItemId;
    WidgetsBinding.instance.addObserver(this);
    AudioPlayerService.setOnEpisodePlayStartedCallback(
      AppShell.goToAbsorbingGlobal,
    );
    _player.addListener(_onPlayerChanged);
    _wasCasting = _cast.isCasting;
    _cast.addListener(_onCastChanged);
    // Try immediately; _onLibraryChanged picks it up once data loads.
    // Deferred to post-frame so Theme.of(context) inside _deriveCoverScheme
    // doesn't establish an inherited-widget dependency during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _deriveCoverScheme();
    });
    context.read<LibraryProvider>().addListener(_onLibraryChanged);
    _loadPodcastTabPrefs();
    PlayerSettings.settingsChanged.addListener(_loadPodcastTabPrefs);
    WelcomeSheet.showIfNeeded(context);
    _checkForUpdate();
  }

  Future<void> _loadPodcastTabPrefs() async {
    final enabled = await PlayerSettings.getPodcastTabEnabled();
    final libId = await PlayerSettings.getPodcastTabLibraryId();
    if (!mounted) return;
    if (enabled != _podcastTabEnabled || libId != _podcastTabLibraryId) {
      setState(() {
        _podcastTabEnabled = enabled;
        _podcastTabLibraryId = libId;
      });
    }
    _restoreBookLibraryForCurrentTab(restoreLibraryPage: true);
  }

  bool _podcastsShown(LibraryProvider lib) =>
      _podcastTabEnabled &&
      _podcastTabLibraryId.isNotEmpty &&
      lib.libraries.any((l) => l['id'] == _podcastTabLibraryId);

  void _restoreBookLibraryForCurrentTab({bool restoreLibraryPage = false}) {
    final lib = context.read<LibraryProvider>();
    final podcastsShown = _podcastsShown(lib);
    if (shouldRestoreBookLibrary(
      pageIndex: _currentIndex,
      podcastsShown: podcastsShown,
      selectedLibraryId: lib.selectedLibraryId,
      podcastLibraryId: _podcastTabLibraryId,
      restoreLibraryPage: restoreLibraryPage,
    )) {
      _syncTabLibrary(_currentIndex, podcastsShown);
    }
  }

  // Display-destination index <-> stack page mapping when the Podcasts tab
  // is shown (it sits at display slot 2 and shares stack page 1).
  int _pageForDest(int dest, bool podcastsShown) {
    if (!podcastsShown) return dest;
    if (dest <= 1) return dest;
    if (dest == 2) return 1;
    return dest - 1;
  }

  int _selectedDest(LibraryProvider lib, bool podcastsShown) {
    if (!podcastsShown) return _currentIndex;
    if (_currentIndex == 0) return 0;
    if (_currentIndex == 1) {
      return lib.selectedLibraryId == _podcastTabLibraryId ? 2 : 1;
    }
    return _currentIndex + 1;
  }

  /// Keep the selected library in step with the destination being entered:
  /// Podcasts pins its library; Home/Library return to the remembered book
  /// library. Uses the light switch so playback and cached shelves survive.
  void _syncTabLibrary(int dest, bool podcastsShown) {
    if (!podcastsShown) return;
    final lib = context.read<LibraryProvider>();
    if (dest == 2) {
      if (lib.selectedLibraryId != _podcastTabLibraryId) {
        lib.selectLibraryLight(_podcastTabLibraryId);
      }
    } else if (dest == 0 || dest == 1) {
      if (lib.selectedLibraryId == _podcastTabLibraryId) {
        lib.lastBookLibraryId().then((bookLib) {
          if (mounted && bookLib != null && bookLib != _podcastTabLibraryId) {
            lib.selectLibraryLight(bookLib);
          }
        });
      }
    }
  }

  static const _isGithubBuild = bool.fromEnvironment('GITHUB_BUILD');

  void _checkForUpdate() async {
    if (!_isGithubBuild) return;
    final includePreReleases = await PlayerSettings.getIncludePreReleases();
    final info = await UpdateCheckerService.check(
      includePreReleases: includePreReleases,
    );
    if (info == null || !mounted) return;
    await UpdateDialog.show(context, info);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _detachNavBarListener();
    _navBarAnimController.dispose();
    _player.removeListener(_onPlayerChanged);
    _cast.removeListener(_onCastChanged);
    PlayerSettings.settingsChanged.removeListener(_loadPodcastTabPrefs);
    try {
      context.read<LibraryProvider>().removeListener(_onLibraryChanged);
    } catch (_) {}
    if (_instance == this) _instance = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (!mounted) return;
    // Re-derive cover scheme whenever absorbing list changes so the app
    // theme always reflects the current [0] book.
    _deriveCoverScheme();
    _restoreBookLibraryForCurrentTab();
  }

  /// Attempt to derive cover scheme. Returns true if successful.
  bool _deriveCoverScheme() {
    if (!mounted) return false;
    // Use player's current item, or fall back to absorbing list's first item
    var itemId = _player.currentItemId;
    if (itemId == null) {
      final lib = context.read<LibraryProvider>();
      final ids = lib.absorbingBookIds;
      if (ids.isNotEmpty) {
        final key = ids.first;
        // Composite keys are "itemId-episodeId"; extract the item ID
        itemId = key.length > 36 ? key.substring(0, 36) : key;
      }
    }
    if (itemId == null) {
      return false;
    }
    if (itemId == _lastCoverItemId) return true;

    final lib = context.read<LibraryProvider>();
    final coverUrl = lib.getCoverUrl(itemId, width: 400);
    if (coverUrl == null) {
      return false;
    }
    _lastCoverItemId = itemId;

    final ImageProvider provider;
    if (coverUrl.startsWith('/')) {
      provider = FileImage(File(coverUrl));
    } else {
      provider = CachedNetworkImageProvider(
        coverUrl,
        headers: lib.mediaHeaders,
      );
    }

    final brightness = Theme.of(context).brightness;
    PaletteGenerator.fromImageProvider(provider, maximumColorCount: 16)
        .then((palette) {
          final seedColor = accentFromCoverPalette(palette);
          if (seedColor == null) {
            _lastCoverItemId = null;
            return;
          }
          final scheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
          );
          coverSchemeNotifier.value = scheme;
          PlayerSettings.setCoverSeedColor(seedColor.toARGB32());
        })
        .catchError((_) {
          _lastCoverItemId = null;
        });
    return true; // cover URL found, image load in progress
  }

  void _onPlayerChanged() {
    final hasBook = _player.hasBook;
    final playing = _player.isPlaying;
    final itemId = _player.currentItemId;

    // Detect playback starting: new book loaded, play resumed, or item changed
    final newBook = hasBook && !_playerHadBook;
    final playStarted = playing && !_wasPlaying;
    final itemChanged = itemId != null && itemId != _lastItemId;

    _playerHadBook = hasBook;
    _wasPlaying = playing;
    _lastItemId = itemId;

    if (itemChanged || newBook) _deriveCoverScheme();

    if ((newBook || playStarted || itemChanged) && !_expandedIsOpen) {
      _maybeAutoExpand();
    }
  }

  void _onCastChanged() {
    final casting = _cast.isCasting;
    if (casting && !_wasCasting) {
      _switchToAbsorbing();
    }
    _wasCasting = casting;
  }

  Future<void> _maybeAutoExpand() async {
    // Only auto-open the full-screen player from the Absorbing tab - starting
    // playback from elsewhere (another tab, the nav long-press) shouldn't
    // yank the user into the player.
    if (_currentIndex != 2) return;
    // The ebook reader is a route above this shell, so the tab check can't
    // see it: audio started from the reader (Find in audiobook with "Keep
    // reading", volume-key play) must not pop the full player underneath it.
    if (context.read<LibraryProvider>().readerQuiet) return;
    final enabled = await PlayerSettings.getFullScreenPlayer();
    if (!enabled || !mounted || !_player.hasBook) return;

    // Synthesize item data from player state
    final itemId = _player.currentItemId;
    if (itemId == null) return;

    final lib = context.read<LibraryProvider>();
    // Try to find the real item data from the library
    Map<String, dynamic>? item;
    for (final section in lib.personalizedSections) {
      for (final e in (section['entities'] as List<dynamic>? ?? [])) {
        if (e is Map<String, dynamic> && e['id'] == itemId) {
          item = e;
          break;
        }
      }
      if (item != null) break;
    }
    // Fallback: synthesize from player data
    item ??= {
      'id': itemId,
      'libraryId': _player.currentLibraryId,
      'media': {
        'metadata': {
          'title': _player.currentTitle ?? 'Unknown',
          'authorName': _player.currentAuthor ?? '',
        },
        'duration': _player.totalDuration,
        'chapters': _player.chapters,
      },
    };
    if (_player.currentEpisodeId != null) {
      item['recentEpisode'] = {
        'id': _player.currentEpisodeId,
        'title': _player.currentEpisodeTitle ?? _player.currentTitle,
        'duration': _player.totalDuration,
      };
    }

    _expandedIsOpen = true;
    final nav = Navigator.of(context, rootNavigator: true);
    await nav.push(
      ExpandedCardRoute(
        child: ExpandedCard(item: item, player: _player),
      ),
    );
    // Route was popped — expanded view closed
    _expandedIsOpen = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Before the backgrounded guard: when the activity attaches to an
        // engine that has never drawn (born from a headless Android Auto /
        // media-button start, kept alive because audio is playing), nothing
        // schedules a frame for the new surface and the launch sits on the
        // splash screen - and that engine never saw a backgrounded state.
        WidgetsBinding.instance.scheduleForcedFrame();
        _handleAppForegrounded();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // `hidden` fires on desktop (macOS/Windows) when the window is
        // minimized or hidden, where `paused` often never arrives - without
        // handling it, every background timer and the socket keep running at
        // full foreground cadence forever and drain the battery. On mobile
        // `hidden` precedes `paused`; the _lifecycleBackgrounded guard makes
        // the second call a no-op (and stops `hidden` on the way back up from
        // flapping the socket).
        _handleAppBackgrounded();
        break;
      case AppLifecycleState.detached:
        final cast = ChromecastService();
        if (cast.isConnected) cast.disconnect();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _handleAppForegrounded() {
    if (!_lifecycleBackgrounded) return;
    _lifecycleBackgrounded = false;
    // The rotation lock lives on the Activity, and Android can recreate the
    // activity over the still-running cached engine (swipe away from recents
    // while playback keeps the service alive). main() doesn't re-run then, so
    // re-apply the saved lock on every return to the foreground.
    applyOrientationLock();
    // Belt-and-suspenders: never let the nav bar come back hidden after a
    // resume. The screens snap their own driver back to shown on next scroll
    // anyway, but mirror it here in case the user resumes onto a stale tab.
    _navBarAnimController.value = 1.0;
    unawaited(context.read<AuthProvider>().adoptCompanionTokens());
    context.read<LibraryProvider>().onAppForegrounded();
    SleepTimerService().onAppForegrounded();
    AudioPlayerService.onAppForegrounded();
    HomeWidgetService().onAppForegrounded();
    ReviewService.onAppForegrounded();
    unawaited(SettingsSyncService().onAppForegrounded());
    _refreshDataForTab(_currentIndex);
    // Check auto sleep in case we resumed into the window
    SleepTimerService().checkAutoSleep();
    _checkForUpdate();
  }

  void _handleAppBackgrounded() {
    if (_lifecycleBackgrounded) return;
    _lifecycleBackgrounded = true;
    context.read<LibraryProvider>().onAppBackgrounded();
    SleepTimerService().onAppBackgrounded();
    AudioPlayerService.onAppBackgrounded();
    HomeWidgetService().onAppBackgrounded();
    unawaited(SettingsSyncService().onAppBackgrounded());
  }

  @override
  void didChangeMetrics() {
    // Orientation change, software keyboard, anything that resizes the window:
    // make sure the bottom nav isn't stuck partway hidden.
    _navBarAnimController.value = 1.0;
    _homeKey.currentState?.resetReveal();
    _libraryKey.currentState?.resetReveal();
  }

  DateTime? _lastRefresh;
  static const _refreshCooldown = Duration(minutes: 1);

  void _refreshDataForTab(int tabIndex) {
    final now = DateTime.now();
    final lib = context.read<LibraryProvider>();

    // Always sync local progress (cheap, no network)
    lib.refreshLocalProgress();

    // Tabs that do not need full personalized shelf rebuilds.
    if (tabIndex == 1 || tabIndex == 2 || tabIndex == 3) {
      unawaited(lib.refreshProgressOnly());
      return;
    }

    // Only do a full server refresh if enough time has passed
    if (_lastRefresh == null ||
        now.difference(_lastRefresh!) > _refreshCooldown) {
      _lastRefresh = now;
      lib.refresh();
      // Keep Android Auto / CarPlay browse tree in sync
      AndroidAutoService().refresh();
      CarPlayService().refreshTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // If on Library tab with active search, clear search first
        if (_currentIndex == 1 &&
            _libraryKey.currentState?.isSearchActive == true) {
          _libraryKey.currentState?.clearSearch();
          return;
        }

        // If already on Absorbing tab, require double-back to exit
        if (_currentIndex == 2) {
          final now = DateTime.now();
          if (_lastBackPress != null &&
              now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop', true);
            return;
          }
          _lastBackPress = now;
          showOverlayToast(
            context,
            AppLocalizations.of(context)!.appShellPressBackToExit,
            icon: Icons.exit_to_app_rounded,
          );
          return;
        }

        // From any other tab, go to Absorbing
        _switchToAbsorbing();
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeController,
          child: IndexedStack(
            index: _currentIndex,
            children: List<Widget>.generate(
              _pages.length,
              (i) => _pages[i] ?? const SizedBox.shrink(),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    // Determine the *correct* notifier for the active tab so we can detect
    // both "no listener" and "listener attached to the wrong tab" — the
    // second happens when LibraryProvider.notify() rebuilds AppShell mid-fade
    // and the lazy attach captures the pre-fade _currentIndex.
    final isHomeOrLibrary = _currentIndex == 0 || _currentIndex == 1;
    ValueListenable<double>? correctNotifier;
    if (_currentIndex == 0) {
      correctNotifier = _homeKey.currentState?.barsRevealNotifier;
    } else if (_currentIndex == 1) {
      correctNotifier = _libraryKey.currentState?.barsRevealNotifier;
    }
    final wrongAttachment =
        isHomeOrLibrary &&
        _navBarListener != null &&
        correctNotifier != null &&
        !identical(_activeBarNotifier, correctNotifier);
    final missingAttachment = isHomeOrLibrary && _navBarListener == null;

    if (missingAttachment || wrongAttachment) {
      final scheduledIndex = _currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentIndex != scheduledIndex) return;
        _syncNavBarListener(_currentIndex);
        if (_navBarListener == null && _currentIndex == scheduledIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentIndex == scheduledIndex) {
              _syncNavBarListener(_currentIndex);
            }
          });
        }
      });
    } else if (!isHomeOrLibrary && _navBarListener != null) {
      // Stale listener left over from a fade transition — detach and snap the
      // nav bar visible so it doesn't get hidden by the previous tab's notifier.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_currentIndex != 0 &&
            _currentIndex != 1 &&
            _navBarListener != null) {
          _detachNavBarListener();
          _navBarAnimController.value = 1.0;
        }
      });
    }
    // On phone landscape, shrink the nav bar so it doesn't eat ~20% of the
    // shorter screen height. Tablets keep the full-size bar in any orientation.
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.shortestSide >= 600;
    final isPhoneLandscape =
        !isTablet && mq.orientation == Orientation.landscape;
    final lib = context.watch<LibraryProvider>();
    final podcastsShown = _podcastsShown(lib);
    final destinations = _buildDestinations(context, podcastsShown);
    return SizeTransition(
      sizeFactor: _navBarAnimController,
      axisAlignment: 1.0,
      // NavigationBar has no per-destination long-press, so map the press x
      // to a destination slot. Plain taps pass through untouched.
      child: GestureDetector(
        onLongPressStart: (details) =>
            _onNavLongPress(details.localPosition.dx, destinations.length),
        child: NavigationBar(
          selectedIndex: _selectedDest(lib, podcastsShown),
          height: isPhoneLandscape ? 56 : null,
          labelBehavior: isPhoneLandscape
              ? NavigationDestinationLabelBehavior.alwaysHide
              : NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (dest) {
            final page = _pageForDest(dest, podcastsShown);
            // Re-tapping the active library-ish destination clears search
            if (page == 1 &&
                _currentIndex == 1 &&
                dest == _selectedDest(lib, podcastsShown) &&
                _libraryKey.currentState?.isSearchActive == true) {
              _libraryKey.currentState?.clearSearch();
              return;
            }
            _syncTabLibrary(dest, podcastsShown);
            _navigateTo(page);
            // Refresh data on switching to Library, Home, Absorbing, or Stats
            if (page == 0 || page == 1 || page == 2 || page == 3) {
              _refreshDataForTab(page);
            }
          },
          destinations: destinations,
        ),
      ),
    );
  }

  void _onNavLongPress(double dx, int destCount) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0 || destCount <= 0) return;
    final slot = (dx / (width / destCount)).floor().clamp(0, destCount - 1);
    HapticFeedback.mediumImpact();
    unawaited(_runNavHold(_tabForSlot(slot, destCount)));
  }

  /// Slot index to stable tab key. The Podcasts tab only exists sometimes, so
  /// everything after it shifts by one without this.
  String _tabForSlot(int slot, int destCount) {
    final hasPodcasts = destCount >= 6;
    if (slot == 0) return 'home';
    if (slot == 1) return 'library';
    if (hasPodcasts && slot == 2) return 'podcasts';
    final rest = hasPodcasts ? slot - 3 : slot - 2;
    return switch (rest) {
      0 => 'absorbing',
      1 => 'stats',
      _ => 'settings',
    };
  }

  bool _rmabConfigured = false;
  bool _rmabWeb = false;

  Future<void> _loadRmabAvailability() async {
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    final legacy = await ScopedPrefs.getString(kRmabLegacyUrlKey);
    _rmabConfigured =
        (base?.isNotEmpty ?? false) && (token?.isNotEmpty ?? false);
    // The site opens from the legacy URL when there is one, otherwise the
    // API base's origin - same rule the setup sheet's button uses.
    _rmabWeb = (legacy?.isNotEmpty ?? false) || (base?.isNotEmpty ?? false);
  }

  Future<void> _runNavHold(String tab) async {
    final key = navHoldPrefKey(tab);
    var id = navHoldResolve(await ScopedPrefs.getString(key), tab);
    if (!mounted) return;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    await _loadRmabAvailability();
    if (!mounted) return;
    // A choice that can't act on this account - admin pages after losing
    // admin, ReadMeABook before it is set up - asks again instead of doing
    // nothing.
    if (id != null &&
        !navHoldIdAvailable(id,
            isAdmin: isAdmin,
            rmabConfigured: _rmabConfigured,
            rmabWeb: _rmabWeb)) {
      id = null;
    }
    if (id == null) {
      final chosen = await _showNavHoldPicker(tab, isAdmin);
      if (chosen == null || !mounted) return;
      await ScopedPrefs.setString(key, chosen);
      if (!mounted) return;
      id = chosen;
      debugPrint('[NavHold] $tab set to $id');
    }
    if (id == 'menu') {
      // Always-show-menu: the saved choice stays 'menu' forever - what gets
      // tapped here runs once and is deliberately NOT written back, otherwise
      // the first pick would quietly replace the menu.
      final picked = await _showNavHoldPicker(tab, isAdmin, forRun: true);
      if (picked == null || !mounted) return;
      debugPrint('[NavHold] $tab menu ran $picked (still menu)');
      _runNavHoldAction(picked);
      return;
    }
    debugPrint('[NavHold] $tab ran $id');
    _runNavHoldAction(id);
  }

  /// The action grid. [forRun] is launcher mode - the sheet is the menu itself
  /// rather than a one-time setup, so the entries that only make sense as a
  /// saved choice are left out.
  Future<String?> _showNavHoldPicker(String tab, bool isAdmin,
      {bool forRun = false}) async {
    final l = AppLocalizations.of(context)!;
    // Launcher mode shows the user's own arrangement, which they can edit in
    // place; setup mode always offers everything.
    var ids = forRun ? await _launcherIds(isAdmin) : <String>[];
    if (!mounted) return null;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final tt = Theme.of(ctx).textTheme;
          final cs = Theme.of(ctx).colorScheme;
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forRun
                          ? navHoldTabLabel(tab, l)
                          : l.navHoldPickTitle(navHoldTabLabel(tab, l)),
                      style: tt.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      forRun ? l.navHoldEditHint : l.navHoldPickBody,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    if (forRun)
                      ActionPillGrid(items: [
                        for (final id in ids)
                          ActionPillData(
                            icon: _iconForId(id),
                            label: navHoldLabel(id, l,
                                libraryName: _libraryNameOf),
                            onTap: () => Navigator.pop(ctx, id),
                            onLongPress: () async {
                              final next = await _editMenuItem(ids, id);
                              if (next != null) setSheetState(() => ids = next);
                            },
                          ),
                        ActionPillData(
                          icon: Icons.add_rounded,
                          label: l.navHoldAdd,
                          onTap: () async {
                            final next = await _addMenuItem(ids, isAdmin);
                            if (next != null) setSheetState(() => ids = next);
                          },
                        ),
                      ])
                    else
                      ActionPillGrid(items: [
                        for (final o in navHoldOptions)
                          if ((o.isFolder
                                  ? isAdmin
                                  : navHoldIdAvailable(o.id,
                                      isAdmin: isAdmin,
                                      rmabConfigured: _rmabConfigured,
                                      rmabWeb: _rmabWeb)))
                            ActionPillData(
                              icon: o.icon,
                              label: navHoldLabel(o.id, l),
                              onTap: () => Navigator.pop(ctx, o.id),
                            ),
                      ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (picked == null || !mounted) return null;
    // Folders open a second sheet; anything else is the answer.
    if (picked == 'admin') return _showNavHoldSubSheet(_adminSubItems());
    if (picked == 'scan') return _showNavHoldSubSheet(_scanSubItems());
    return picked;
  }

  /// The hold menu's contents: the user's saved arrangement, minus anything
  /// that no longer applies, or the default set when untouched.
  Future<List<String>> _launcherIds(bool isAdmin) async {
    final raw = await ScopedPrefs.getString(navHoldMenuPrefKey);
    List<String>? saved;
    if (raw != null && raw.isNotEmpty) {
      try {
        saved = (jsonDecode(raw) as List<dynamic>).cast<String>();
      } catch (_) {}
    }
    final ids = saved ??
        navHoldDefaultMenu(
          isAdmin: isAdmin,
          rmabConfigured: _rmabConfigured,
          rmabWeb: _rmabWeb,
        );
    return [
      for (final id in ids)
        if (navHoldIdAvailable(id,
            isAdmin: isAdmin,
            rmabConfigured: _rmabConfigured,
            rmabWeb: _rmabWeb))
          id,
    ];
  }

  Future<void> _saveLauncherIds(List<String> ids) =>
      ScopedPrefs.setString(navHoldMenuPrefKey, jsonEncode(ids));

  IconData _iconForId(String id) {
    if (id.startsWith('admin:')) return navHoldAdminIcon(id.substring(6));
    if (id.startsWith('scan:')) {
      return id == 'scan:all' ? Icons.sync_rounded : Icons.folder_rounded;
    }
    for (final o in navHoldOptions) {
      if (o.id == id) return o.icon;
    }
    return Icons.bolt_rounded;
  }

  String? _libraryNameOf(String libraryId) {
    for (final lib in context.read<LibraryProvider>().libraries) {
      if (lib['id'] == libraryId) return lib['name'] as String?;
    }
    return null;
  }

  /// Hold a menu pill: shuffle it along or drop it. Returns the new order, or
  /// null when nothing changed.
  Future<List<String>?> _editMenuItem(List<String> ids, String id) async {
    final l = AppLocalizations.of(context)!;
    final i = ids.indexOf(id);
    if (i < 0) return null;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text(navHoldLabel(id, AppLocalizations.of(ctx)!,
                libraryName: _libraryNameOf)),
          ),
          if (i > 0)
            ListTile(
              leading: const Icon(Icons.arrow_back_rounded),
              title: Text(l.navHoldMoveLeft),
              onTap: () => Navigator.pop(ctx, 'left'),
            ),
          if (i < ids.length - 1)
            ListTile(
              leading: const Icon(Icons.arrow_forward_rounded),
              title: Text(l.navHoldMoveRight),
              onTap: () => Navigator.pop(ctx, 'right'),
            ),
          ListTile(
            leading: Icon(Icons.remove_circle_outline_rounded,
                color: Theme.of(ctx).colorScheme.error),
            title: Text(l.navHoldRemoveFromMenu,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (action == null) return null;
    final next = [...ids];
    switch (action) {
      case 'left':
        next
          ..removeAt(i)
          ..insert(i - 1, id);
      case 'right':
        next
          ..removeAt(i)
          ..insert(i + 1, id);
      case 'remove':
        next.removeAt(i);
    }
    await _saveLauncherIds(next);
    return next;
  }

  /// Add anything not already in the menu, admin pages and library scans
  /// included, so a page like Users can sit on the front grid.
  Future<List<String>?> _addMenuItem(List<String> ids, bool isAdmin) async {
    final l = AppLocalizations.of(context)!;
    final all = navHoldAllIds(
      isAdmin: isAdmin,
      libraryIds: [
        for (final lib in context.read<LibraryProvider>().libraries)
          if ((lib['id'] as String?)?.isNotEmpty == true) lib['id'] as String,
      ],
      rmabConfigured: _rmabConfigured,
      rmabWeb: _rmabWeb,
    ).where((id) =>
        id != 'menu' && id != 'none' && !ids.contains(id)).toList();
    if (all.isEmpty) return null;
    final picked = await _showNavHoldSubSheet([
      for (final id in all)
        (id, _iconForId(id), navHoldLabel(id, l, libraryName: _libraryNameOf)),
    ]);
    if (picked == null) return null;
    final next = [...ids, picked];
    await _saveLauncherIds(next);
    return next;
  }

  List<(String, IconData, String)> _adminSubItems() {
    final l = AppLocalizations.of(context)!;
    return [
      for (final p in navHoldAdminPages)
        ('admin:$p', navHoldAdminIcon(p), navHoldAdminPageLabel(p, l)),
    ];
  }

  List<(String, IconData, String)> _scanSubItems() {
    final l = AppLocalizations.of(context)!;
    final libs = context.read<LibraryProvider>().libraries;
    return [
      ('scan:all', Icons.sync_rounded, l.navHoldScanAll),
      for (final lib in libs)
        if ((lib['id'] as String?)?.isNotEmpty == true)
          (
            'scan:${lib['id']}',
            Icons.folder_rounded,
            (lib['name'] as String?) ?? '',
          ),
    ];
  }

  Future<String?> _showNavHoldSubSheet(List<(String, IconData, String)> items) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ActionPillGrid(items: [
              for (final (id, icon, label) in items)
                ActionPillData(
                  icon: icon,
                  label: label,
                  onTap: () => Navigator.pop(ctx, id),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _runNavHoldAction(String id) {
    if (id.startsWith('admin:')) {
      unawaited(_openAdminPage(id.substring(6)));
      return;
    }
    if (id.startsWith('scan:')) {
      unawaited(_runServerScan(id.substring(5)));
      return;
    }
    switch (id) {
      case 'search':
        final lib = context.read<LibraryProvider>();
        if (_podcastsShown(lib)) _syncTabLibrary(1, true);
        _openSearch();
      case 'switchLibrary':
        final lib = context.read<LibraryProvider>();
        if (lib.libraries.length < 2) return;
        showLibraryPickerSheet(context, lib);
      case 'bookmarks':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BookmarksScreen()));
      case 'downloads':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DownloadsScreen()));
      case 'admin':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AdminScreen()));
      case 'sleep':
        showSleepTimerSheet(context, Theme.of(context).colorScheme.primary);
      case 'eink':
        final v = !PlayerSettings.einkMode;
        PlayerSettings.setEinkMode(v);
        applyEinkModeTheme(v);
        context.read<LibraryProvider>().applyEinkMode(v);
      case 'playPause':
        // Nothing loaded at all: start the front card rather than doing
        // nothing, so the shortcut always plays something.
        if (!_player.hasBook) {
          unawaited(_playFrontCard());
          return;
        }
        if (_player.isPlaying) {
          _player.pause();
        } else {
          _player.play(fromUi: true);
        }
      case 'stop':
        if (!_player.hasBook) return;
        unawaited(_player.stop());
      case 'queue':
        // The Absorbing page is built lazily, and the sheet lives on it - if
        // it isn't up yet, switch to the tab and open the sheet once it is.
        if (!AbsorbingScreen.openQueueManager(context)) {
          _switchToAbsorbing();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) AbsorbingScreen.openQueueManager(context);
          });
        }
      case 'offline':
        final lib = context.read<LibraryProvider>();
        final going = !lib.isOffline;
        unawaited(lib.setManualOffline(going));
        showOverlayToast(
          context,
          going
              ? AppLocalizations.of(context)!.navHoldOfflineOn
              : AppLocalizations.of(context)!.navHoldOfflineOff,
          icon: going ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
        );
      case 'readBook':
        unawaited(_openCurrentEbook());
      case 'bookDetails':
        // Playing book if there is one, otherwise the front Absorbing card,
        // so this works before anything has been started.
        final itemId =
            _player.currentItemId ?? _frontAbsorbingItem()?['id'] as String?;
        if (itemId == null) {
          showOverlayToast(
              context, AppLocalizations.of(context)!.navHoldNothingPlaying,
              icon: Icons.info_outline_rounded);
          return;
        }
        showBookDetailSheet(context, itemId);
      case 'scanSeries':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    const UpcomingReleasesScreen(openScanChooser: true)));
      case 'rmabSearch':
        showRmabSearchResultsSheet(context, initialQuery: '');
      case 'rmabRequests':
        // The setup sheet opens on its My Requests tab.
        showRmabConfigSheet(context,
            isAdminContext: context.read<AuthProvider>().isAdmin);
      case 'rmabWeb':
        unawaited(_openRmabSite());
      case 'none':
        break;
    }
  }

  /// Push an Admin page straight from the nav bar. Most of them need the user
  /// or library lists the Admin hub normally loads, so fetch just those first
  /// - the hub itself stays the fallback if a fetch comes back empty.
  Future<void> _openAdminPage(String page) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    Widget? screen;
    switch (page) {
      case 'settings':
        screen = const AdminServerSettingsScreen();
      case 'logs':
        screen = const AdminServerLogsScreen();
      case 'stats':
        screen = const AdminStatsScreen();
      case 'users':
        final r = await Future.wait(
            [api.getUsers(), api.getOnlineUsers(), api.getLibraries()]);
        screen = AdminUsersScreen(
            users: r[0], onlineUsers: r[1], libraries: r[2]);
      case 'sessions':
        screen = AdminSessionsScreen(users: await api.getUsers());
      case 'email':
        screen = AdminEmailScreen(users: await api.getUsers());
      case 'apikeys':
        screen = AdminApiKeysScreen(users: await api.getUsers());
      case 'libraries':
        screen = AdminLibrariesScreen(libraries: await api.getLibraries());
      case 'upload':
        if (!mounted) return;
        screen = AdminUploadScreen(
          libraries: await api.getLibraries(),
          initialLibraryId: context.read<AuthProvider>().defaultLibraryId,
          apiService: api,
        );
      default:
        screen = const AdminScreen();
    }
    if (!mounted) return;
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen!));
  }

  /// Open the ReadMeABook site in the in-app browser: the legacy URL when one
  /// is set, otherwise the API base's origin.
  Future<void> _openRmabSite() async {
    final legacy = await ScopedPrefs.getString(kRmabLegacyUrlKey);
    var target = legacy ?? '';
    if (target.isEmpty) {
      final base = await ScopedPrefs.getString(kRmabBaseUrlKey) ?? '';
      final uri = Uri.tryParse(base.trim());
      target = (uri != null && uri.hasScheme && uri.host.isNotEmpty)
          ? uri.origin
          : '';
    }
    if (!mounted || target.isEmpty) return;
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => AdminRmabScreen(url: target)));
  }

  /// Kick off a server-side scan of one library, or every library.
  Future<void> _runServerScan(String target) async {
    final l = AppLocalizations.of(context)!;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final libs = context.read<LibraryProvider>().libraries;
    final ids = target == 'all'
        ? [
            for (final lib in libs)
              if ((lib['id'] as String?)?.isNotEmpty == true) lib['id'] as String
          ]
        : [target];
    if (ids.isEmpty) return;
    var ok = false;
    for (final id in ids) {
      if (await api.scanLibrary(id)) ok = true;
    }
    if (!mounted) return;
    showOverlayToast(
      context,
      ok ? l.navHoldScanStarted : l.navHoldScanFailed,
      icon: ok ? Icons.sync_rounded : Icons.error_outline_rounded,
    );
  }

  /// The item behind the front Absorbing card - what the user sees first when
  /// nothing is playing. The absorbing order is the card order.
  Map<String, dynamic>? _frontAbsorbingItem() {
    final lib = context.read<LibraryProvider>();
    for (final key in lib.absorbingBookIds) {
      final item = lib.absorbingItemCache[key];
      if (item != null) return item;
    }
    return null;
  }

  /// Start the front Absorbing card. Podcast episodes carry their episode in
  /// the cached entry; books need the full item for chapters and duration.
  Future<void> _playFrontCard() async {
    final l = AppLocalizations.of(context)!;
    final item = _frontAbsorbingItem();
    final api = context.read<AuthProvider>().apiService;
    final itemId = item?['id'] as String?;
    if (item == null || itemId == null || api == null) {
      showOverlayToast(context, l.navHoldNothingPlaying,
          icon: Icons.play_disabled_rounded);
      return;
    }
    final lib = context.read<LibraryProvider>();
    final coverUrl = lib.getCoverUrl(itemId);
    final episode = item['recentEpisode'] as Map<String, dynamic>?;
    if (episode != null) {
      final media = item['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final error = await _player.playItem(
        api: api,
        itemId: itemId,
        title: episode['title'] as String? ?? '',
        author: metadata['title'] as String? ?? '',
        coverUrl: coverUrl,
        totalDuration: (episode['duration'] as num?)?.toDouble() ?? 0,
        chapters: const [],
        episodeId: episode['id'] as String?,
        episodeTitle: episode['title'] as String?,
        libraryId: item['libraryId'] as String?,
        fromUi: true,
      );
      if (mounted && error != null) showOverlayToast(context, error, icon: Icons.error_outline_rounded);
      return;
    }
    final full = await api.getLibraryItem(itemId) ?? item;
    if (!mounted) return;
    final media = full['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final error = await _player.playItem(
      api: api,
      itemId: itemId,
      title: metadata['title'] as String? ?? '',
      author: metadata['authorName'] as String? ?? '',
      coverUrl: coverUrl,
      totalDuration: (media['duration'] as num?)?.toDouble() ?? 0,
      chapters: (media['chapters'] as List<dynamic>?) ?? const [],
      libraryId: full['libraryId'] as String?,
      fromUi: true,
    );
    if (mounted && error != null) showOverlayToast(context, error, icon: Icons.error_outline_rounded);
  }

  /// Open the playing (or last-played) book's ebook, falling back to the front
  /// Absorbing card when nothing is loaded. The reader cache is checked first
  /// so this works with no signal, same as the player card's Read button.
  Future<void> _openCurrentEbook() async {
    final l = AppLocalizations.of(context)!;
    final front = _player.hasBook ? null : _frontAbsorbingItem();
    final itemId = _player.currentItemId ?? front?['id'] as String?;
    var title = _player.currentTitle ?? '';
    if (front != null) {
      final metadata = (front['media'] as Map<String, dynamic>?)?['metadata']
          as Map<String, dynamic>?;
      title = metadata?['title'] as String? ?? title;
    }
    if (itemId == null) {
      showOverlayToast(context, l.noEbookFileFound,
          icon: Icons.menu_book_outlined);
      return;
    }
    var ebookFile = await cachedEbookFileFor(itemId);
    if (!mounted) return;
    if (ebookFile == null) {
      final api = context.read<AuthProvider>().apiService;
      if (api != null) {
        try {
          final item = await api.getLibraryItem(itemId);
          ebookFile = resolveEbookFile(item);
        } catch (_) {}
      }
    }
    if (!mounted) return;
    if (ebookFile == null) {
      showOverlayToast(context, l.noEbookFileFound,
          icon: Icons.menu_book_outlined);
      return;
    }
    await openEbookReader(
      context,
      itemId: itemId,
      title: title,
      ebookFile: ebookFile,
    );
  }

  List<NavigationDestination> _buildDestinations(
    BuildContext context,
    bool podcastsShown,
  ) {
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();
    // With the dedicated Podcasts tab, Home/Library always wear their book
    // labels - the podcast library being selected must not morph them.
    final isPodcast = !podcastsShown && lib.isPodcastLibrary;

    // tooltip: '' everywhere: the default label Tooltip registers its own
    // long-press recognizer, which silently wins the gesture arena over the
    // bar-level long-press handler (quick actions per slot).
    return [
      NavigationDestination(
        icon: Icon(isPodcast ? Icons.explore_outlined : Icons.home_outlined),
        selectedIcon: Icon(
          isPodcast ? Icons.explore_rounded : Icons.home_rounded,
        ),
        label: isPodcast ? l.appShellDiscoverTab : l.appShellHomeTab,
        tooltip: '',
      ),
      NavigationDestination(
        icon: Icon(
          isPodcast ? Icons.podcasts_outlined : Icons.library_books_outlined,
        ),
        selectedIcon: Icon(
          isPodcast ? Icons.podcasts_rounded : Icons.library_books_rounded,
        ),
        label: isPodcast ? l.appShellShowsTab : l.appShellLibraryTab,
        tooltip: '',
      ),
      if (podcastsShown)
        NavigationDestination(
          icon: const Icon(Icons.podcasts_outlined),
          selectedIcon: const Icon(Icons.podcasts_rounded),
          label: l.appShellPodcastsTab,
          tooltip: '',
        ),
      NavigationDestination(
        icon: const _AnimatedWaveIcon(size: 24, active: false),
        selectedIcon: const _AnimatedWaveIcon(size: 24, active: true),
        label: Wording.of(context).appShellAbsorbingTab,
        tooltip: '',
      ),
      NavigationDestination(
        icon: const Icon(Icons.bar_chart_rounded),
        selectedIcon: const Icon(Icons.bar_chart_rounded),
        label: l.appShellStatsTab,
        tooltip: '',
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: l.appShellSettingsTab,
        tooltip: '',
      ),
    ];
  }
}

// ─── Animated wave icon for nav bar matching notification icon ────
class _AnimatedWaveIcon extends StatefulWidget {
  final double size;
  final bool active;

  const _AnimatedWaveIcon({required this.size, required this.active});

  @override
  State<_AnimatedWaveIcon> createState() => _AnimatedWaveIconState();
}

class _AnimatedWaveIconState extends State<_AnimatedWaveIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _player = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _player.addListener(_onPlayerChanged);
    _syncAnimation();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _player.removeListener(_onPlayerChanged);
    super.dispose();
  }

  void _onPlayerChanged() {
    _syncAnimation();
    if (mounted) setState(() {});
  }

  void _syncAnimation() {
    if (_player.isPlaying) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else {
      if (_ctrl.isAnimating) _ctrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final playing = _player.isPlaying;
    // Painted rather than an Icon, so the nav bar's icon theme passes it by.
    // That only matters in e-ink mode, where the selected pill is solid black
    // and the theme is what turns a selected icon white - without this the
    // wave paints black on black and the tab looks empty.
    final einkColor =
        PlayerSettings.einkMode ? IconTheme.of(context).color : null;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _NavWavePainter(
          phase: _ctrl.value,
          color: einkColor ??
              (widget.active ? cs.primary : cs.onSurfaceVariant),
          playing: playing,
        ),
      ),
    );
  }
}

class _NavWavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final bool playing;

  _NavWavePainter({
    required this.phase,
    required this.color,
    required this.playing,
  });

  static const _barHeights = [0.35, 0.6, 1.0, 0.6, 0.35];
  static const _barCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final totalWidth = size.width * 0.6;
    final startX = (size.width - totalWidth) / 2;
    final spacing = totalWidth / (_barCount - 1);
    final midY = size.height / 2;
    final maxHalf = size.height * 0.38;

    for (int i = 0; i < _barCount; i++) {
      final x = startX + spacing * i;
      final baseRatio = _barHeights[i];

      if (playing) {
        final barPhase = phase * 2 * math.pi + i * 1.2;
        final ratio = (baseRatio * (0.5 + 0.5 * math.sin(barPhase))).clamp(
          0.2,
          1.0,
        );
        final half = maxHalf * ratio;
        canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), paint);
      } else {
        final half = maxHalf * baseRatio;
        canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_NavWavePainter old) =>
      old.phase != phase || old.playing != playing || old.color != color;
}
