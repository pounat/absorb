import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../services/sleep_timer_service.dart';
import '../services/android_auto_service.dart';
import '../widgets/expanded_card.dart';
import 'absorbing_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

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

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static _AppShellState? _instance;

  // Tabs: 0=Home, 1=Library, 2=Absorbing (default), 3=Stats, 4=Settings
  int _currentIndex = 2;
  final _libraryKey = GlobalKey<LibraryScreenState>();
  final _player = AudioPlayerService();
  final _cast = ChromecastService();
  bool _playerHadBook = false;
  bool _wasPlaying = false;
  String? _lastItemId;
  bool _expandedIsOpen = false;
  bool _wasCasting = false;
  Timer? _castDisconnectTimer;

  // Lazily build tabs so startup on Absorbing does not initialize Home/Library
  // work until the user actually visits those tabs.
  final List<Widget?> _pages = List<Widget?>.filled(5, null, growable: false);

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
    if (index == _currentIndex) return;
    _ensurePageBuilt(index);
    setState(() {
      _currentIndex = index;
    });
  }

  void _ensurePageBuilt(int index) {
    if (_pages[index] != null) return;
    switch (index) {
      case 0:
        _pages[index] = const HomeScreen();
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

  @override
  void initState() {
    super.initState();
    _instance = this;
    _ensurePageBuilt(_currentIndex);
    _playerHadBook = _player.hasBook;
    _wasPlaying = _player.isPlaying;
    _lastItemId = _player.currentItemId;
    WidgetsBinding.instance.addObserver(this);
    AudioPlayerService.setOnEpisodePlayStartedCallback(AppShell.goToAbsorbingGlobal);
    _player.addListener(_onPlayerChanged);
    _wasCasting = _cast.isCasting;
    _cast.addListener(_onCastChanged);
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerChanged);
    _cast.removeListener(_onCastChanged);
    if (_instance == this) _instance = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      _castDisconnectTimer?.cancel();
      _castDisconnectTimer = null;
      _refreshDataForTab(_currentIndex);
      // Check auto sleep in case we resumed into the window
      SleepTimerService().checkAutoSleep();
    } else if (state == AppLifecycleState.paused) {
      // Disconnect cast if app doesn't resume (e.g. swiped away).
      // detached doesn't fire reliably on Android swipe-away.
      final cast = ChromecastService();
      if (cast.isConnected) {
        _castDisconnectTimer = Timer(const Duration(seconds: 3), () {
          cast.disconnect();
        });
      }
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
      // Keep Android Auto browse tree in sync
      AndroidAutoService().refresh();
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

        // If already on Absorbing tab, move app to background (keep playback alive)
        if (_currentIndex == 2) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop', true);
          return;
        }

        // From any other tab, go to Absorbing
        _switchToAbsorbing();
      },
      child: Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(
          _pages.length,
          (i) => _pages[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationBar(
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
        ],
      ),
    ),
    );
  }

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final isPodcast = lib.isPodcastLibrary;

    return [
      NavigationDestination(
        icon: Icon(isPodcast ? Icons.explore_outlined : Icons.home_outlined),
        selectedIcon: Icon(isPodcast ? Icons.explore_rounded : Icons.home_rounded),
        label: isPodcast ? 'Discover' : 'Home',
      ),
      NavigationDestination(
        icon: Icon(isPodcast ? Icons.podcasts_outlined : Icons.library_books_outlined),
        selectedIcon: Icon(isPodcast ? Icons.podcasts_rounded : Icons.library_books_rounded),
        label: isPodcast ? 'Shows' : 'Library',
      ),
      NavigationDestination(
        icon: const _AnimatedWaveIcon(size: 24, active: false),
        selectedIcon: const _AnimatedWaveIcon(size: 24, active: true),
        label: 'Absorbing',
      ),
      const NavigationDestination(
        icon: Icon(Icons.bar_chart_rounded),
        selectedIcon: Icon(Icons.bar_chart_rounded),
        label: 'Stats',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings_rounded),
        label: 'Settings',
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
    )..repeat();
    _player.addListener(_rebuild);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _player.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() { if (mounted) setState(() {}); }

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
