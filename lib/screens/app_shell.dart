import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../services/home_widget_service.dart';
import '../services/sleep_timer_service.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import '../main.dart'
    show snappyTransitionsNotifier, coverSchemeNotifier, rootNavigatorKey;
import '../l10n/app_localizations.dart';
import '../services/android_auto_service.dart';
import '../services/carplay_service.dart';
import '../widgets/expanded_card.dart';
import 'absorbing_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../widgets/welcome_sheet.dart';
import '../services/update_checker_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

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

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver, TickerProviderStateMixin {
  static _AppShellState? _instance;

  // Tabs: 0=Home, 1=Library, 2=Absorbing (default), 3=Stats, 4=Settings
  int _currentIndex = 2; // overridden by user preference in initState
  final _homeKey = GlobalKey<HomeScreenState>();
  final _libraryKey = GlobalKey<LibraryScreenState>();
  final _player = AudioPlayerService();
  final _cast = ChromecastService();
  bool _playerHadBook = false;
  bool _wasPlaying = false;
  String? _lastItemId;
  bool _expandedIsOpen = false;
  bool _wasCasting = false;
  DateTime? _lastBackPress;
  String? _lastCoverItemId; // tracks which item's cover we derived the scheme from

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
    if (snappyTransitionsNotifier.value) {
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

  /// Subscribe to the active screen's barsVisibleNotifier when on Home or
  /// Library tab, and ensure the nav bar is visible on all other tabs.
  void _syncNavBarListener(int index) {
    debugPrint('[NavBar] _syncNavBarListener(index=$index) ctrl=${_navBarAnimController.value.toStringAsFixed(2)}');
    _detachNavBarListener();
    ValueNotifier<bool>? notifier;
    if (index == 0) {
      notifier = _homeKey.currentState?.barsVisibleNotifier;
    } else if (index == 1) {
      notifier = _libraryKey.currentState?.barsVisibleNotifier;
    }
    if (notifier != null) {
      _activeBarNotifier = notifier;
      _navBarListener = () {
        if (notifier!.value) {
          _navBarAnimController.forward();
        } else {
          _navBarAnimController.reverse();
        }
      };
      notifier.addListener(_navBarListener!);
      _navBarListener!();
      debugPrint('[NavBar] Attached listener to tab=$index notifier.value=${notifier.value} ctrl=${_navBarAnimController.value.toStringAsFixed(2)}');
    } else {
      // Not a scroll-hide tab - force nav bar visible immediately.
      // Use .value to snap instead of animate, avoiding races where
      // the controller gets stuck mid-animation.
      _navBarAnimController.value = 1.0;
      debugPrint('[NavBar] Snap to 1.0 for non-scroll tab=$index');
    }
  }

  ValueNotifier<bool>? _activeBarNotifier;

  void _detachNavBarListener() {
    if (_navBarListener != null && _activeBarNotifier != null) {
      _activeBarNotifier!.removeListener(_navBarListener!);
      // Reset the notifier so bars are visible when the user returns to this tab
      _activeBarNotifier!.value = true;
    }
    _navBarListener = null;
    _activeBarNotifier = null;
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
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _instance = this;
    _loadStartScreen();
    _ensurePageBuilt(_currentIndex);
    _playerHadBook = _player.hasBook;
    _wasPlaying = _player.isPlaying;
    _lastItemId = _player.currentItemId;
    WidgetsBinding.instance.addObserver(this);
    AudioPlayerService.setOnEpisodePlayStartedCallback(AppShell.goToAbsorbingGlobal);
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
    WelcomeSheet.showIfNeeded(context);
    _checkForUpdate();
  }

  static const _isGithubBuild = bool.fromEnvironment('GITHUB_BUILD');

  void _checkForUpdate() async {
    if (!_isGithubBuild) return;
    final includePreReleases = await PlayerSettings.getIncludePreReleases();
    final info = await UpdateCheckerService.check(includePreReleases: includePreReleases);
    if (info == null || !mounted) return;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(info.isPreRelease ? l.preReleaseAvailable : l.updateAvailable),
        content: Text(l.updateDialogContent(
          info.isPreRelease ? l.updateKindPreRelease : l.updateKindVersion,
          info.latestVersion,
          info.currentVersion,
        )),
        actions: [
          TextButton(
            onPressed: () {
              UpdateCheckerService.dismiss(info.latestVersion);
              Navigator.pop(ctx);
            },
            child: Text(l.later),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(info.downloadUrl), mode: LaunchMode.externalApplication);
            },
            child: Text(l.downloadButton),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _detachNavBarListener();
    _navBarAnimController.dispose();
    _player.removeListener(_onPlayerChanged);
    _cast.removeListener(_onCastChanged);
    try { context.read<LibraryProvider>().removeListener(_onLibraryChanged); } catch (_) {}
    if (_instance == this) _instance = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (!mounted) return;
    // Re-derive cover scheme whenever absorbing list changes so the app
    // theme always reflects the current [0] book.
    _deriveCoverScheme();
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
      provider = CachedNetworkImageProvider(coverUrl, headers: lib.mediaHeaders);
    }

    final brightness = Theme.of(context).brightness;
    PaletteGenerator.fromImageProvider(provider, maximumColorCount: 16)
        .then((palette) {
      final seedColor = palette.vibrantColor?.color
          ?? palette.dominantColor?.color
          ?? palette.colors.firstOrNull;
      if (seedColor == null) {
        _lastCoverItemId = null;
        return;
      }
      final scheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
      coverSchemeNotifier.value = scheme;
      PlayerSettings.setCoverSeedColor(seedColor.toARGB32());
    }).catchError((_) {
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
    await nav.push(ExpandedCardRoute(
      child: ExpandedCard(
        item: item,
        player: _player,
      ),
    ));
    // Route was popped — expanded view closed
    _expandedIsOpen = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<LibraryProvider>().onAppForegrounded();
      SleepTimerService().onAppForegrounded();
      AudioPlayerService.onAppForegrounded();
      HomeWidgetService().onAppForegrounded();
      _refreshDataForTab(_currentIndex);
      // Check auto sleep in case we resumed into the window
      SleepTimerService().checkAutoSleep();
      _checkForUpdate();
    } else if (state == AppLifecycleState.paused) {
      context.read<LibraryProvider>().onAppBackgrounded();
      SleepTimerService().onAppBackgrounded();
      AudioPlayerService.onAppBackgrounded();
      HomeWidgetService().onAppBackgrounded();
    } else if (state == AppLifecycleState.detached) {
      final cast = ChromecastService();
      if (cast.isConnected) cast.disconnect();
    }
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
    if (_lastRefresh == null || now.difference(_lastRefresh!) > _refreshCooldown) {
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
          if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop', true);
            return;
          }
          _lastBackPress = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.appShellPressBackToExit),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
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
    // Lazily attach listener when on Home or Library tab (handles start-on-tab case).
    // The screen's state may not exist on the first frame, so retry until attached.
    if ((_currentIndex == 0 || _currentIndex == 1) && _navBarListener == null) {
      final scheduledIndex = _currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentIndex != scheduledIndex) return;
        _syncNavBarListener(_currentIndex);
        // If the screen state wasn't ready yet, retry on next frame
        if (_navBarListener == null && _currentIndex == scheduledIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentIndex == scheduledIndex) {
              _syncNavBarListener(_currentIndex);
            }
          });
        }
      });
    }
    return SizeTransition(
      sizeFactor: _navBarAnimController,
      axisAlignment: 1.0,
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          // If tapping Library while already on Library, clear search
          if (i == 1 && _currentIndex == 1 &&
              _libraryKey.currentState?.isSearchActive == true) {
            _libraryKey.currentState?.clearSearch();
            return;
          }
          _navigateTo(i);
          // Refresh data on switching to Library, Home, Absorbing, or Stats
          if (i == 0 || i == 1 || i == 2 || i == 3) {
            _refreshDataForTab(i);
          }
        },
        destinations: _buildDestinations(context),
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lib = context.watch<LibraryProvider>();
    final isPodcast = lib.isPodcastLibrary;

    return [
      NavigationDestination(
        icon: Icon(isPodcast ? Icons.explore_outlined : Icons.home_outlined),
        selectedIcon: Icon(isPodcast ? Icons.explore_rounded : Icons.home_rounded),
        label: isPodcast ? l.appShellDiscoverTab : l.appShellHomeTab,
      ),
      NavigationDestination(
        icon: Icon(isPodcast ? Icons.podcasts_outlined : Icons.library_books_outlined),
        selectedIcon: Icon(isPodcast ? Icons.podcasts_rounded : Icons.library_books_rounded),
        label: isPodcast ? l.appShellShowsTab : l.appShellLibraryTab,
      ),
      NavigationDestination(
        icon: const _AnimatedWaveIcon(size: 24, active: false),
        selectedIcon: const _AnimatedWaveIcon(size: 24, active: true),
        label: l.appShellAbsorbingTab,
      ),
      NavigationDestination(
        icon: const Icon(Icons.bar_chart_rounded),
        selectedIcon: const Icon(Icons.bar_chart_rounded),
        label: l.appShellStatsTab,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
        label: l.appShellSettingsTab,
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

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _NavWavePainter(
          phase: _ctrl.value,
          color: widget.active ? cs.primary : cs.onSurfaceVariant,
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

  _NavWavePainter({required this.phase, required this.color, required this.playing});

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
        final ratio = (baseRatio * (0.5 + 0.5 * math.sin(barPhase))).clamp(0.2, 1.0);
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
