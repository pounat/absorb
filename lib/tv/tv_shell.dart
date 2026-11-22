import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/user_account_service.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/remote_ok.dart';
import 'tv_focusable.dart';
import 'tv_night_mode.dart';
import 'tv_pip.dart';
import 'tv_settings_controls.dart';
import 'tv_home_screen.dart';
import 'tv_library_screen.dart';
import 'tv_now_playing_bar.dart';
import 'tv_pair_screen.dart';
import 'tv_search_screen.dart';

enum _TvTab { home, library, search, settings }

/// The TV app once signed in: a bar of tabs along the top, reached by
/// pressing up, with the library picker beside them.
class TvShell extends StatefulWidget {
  const TvShell({super.key});

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  static const _appChannel = MethodChannel('com.absorb.equalizer');

  static const _barHeight = 92.0;

  _TvTab _tab = _TvTab.home;
  final _tabFocus = {for (final t in _TvTab.values) t: FocusNode(debugLabel: 'tv tab ${t.name}')};
  FocusNode get _homeTabFocus => _tabFocus[_TvTab.home]!;

  @override
  void initState() {
    super.initState();
    tvPlayerRequest.addListener(_onPlayRequest);
    tvFocusTabs.addListener(_focusTabs);
    RemoteOk.globalHold = _openPlaying;
    TvAutoNight.start();
    TvPip.start();
  }

  /// Hold OK anywhere: straight to the player for the book playing.
  bool _openPlaying() {
    final p = AudioPlayerService();
    final id = p.currentItemId;
    if (id == null || !mounted) return false;
    final ep = p.currentEpisodeId;
    final cached = context.read<LibraryProvider>().absorbingItemCache[ep == null ? id : '$id-$ep'];
    final item = cached ??
        <String, dynamic>{
          'id': id,
          'media': {
            'metadata': {'title': p.currentTitle, 'authorName': p.currentAuthor},
            'duration': p.totalDuration,
          },
        };
    final episode = ep == null
        ? null
        : ((item['recentEpisode'] as Map?)?.cast<String, dynamic>() ?? {'id': ep, 'title': p.currentEpisodeTitle});
    Navigator.of(context).popUntil((r) => r.isFirst);
    tvPlayerRequest.value = TvPlayRequest(item, episode: episode, play: false);
    return true;
  }

  // Up lands on the tab already showing, so it doesn't switch pages.
  void _focusTabs() => _tabFocus[_tab]!.requestFocus();

  bool _refreshing = false;

  /// Everything fresh from the server: libraries, the Absorbing row and
  /// progress, as pull to refresh does on the phone.
  Future<void> _refresh() async {
    if (_refreshing) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _refreshing = true);
    try {
      await context.read<LibraryProvider>().refresh();
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
        showOverlayToast(context, l.tvRefreshed, icon: Icons.refresh_rounded);
      }
    }
  }

  @override
  void dispose() {
    tvPlayerRequest.removeListener(_onPlayRequest);
    tvFocusTabs.removeListener(_focusTabs);
    if (RemoteOk.globalHold == _openPlaying) RemoteOk.globalHold = null;
    for (final n in _tabFocus.values) {
      n.dispose();
    }
    _pickerFocus.dispose();
    _refreshFocus.dispose();
    super.dispose();
  }

  // Play on a book's page opens the player, which lives on Home.
  // Any change counts: Home may clear the request before this hears it.
  // Focus goes to the Home tab too: left where it was, it falls back to the
  // tab of the page being left, and the tabs switch on focus, so it would
  // flip straight back.
  void _onPlayRequest() {
    _show(_TvTab.home);
    _homeTabFocus.requestFocus();
  }

  /// Back goes Home from the other tabs; from Home it tucks the app away
  /// instead of closing it, so it opens where it was and keeps playing.
  void _onBack(bool didPop, Object? _) {
    if (didPop) return;
    if (tvPlayerOpen.value) {
      tvPlayerClose.value++;
      return;
    }
    if (_tab != _TvTab.home) {
      _show(_TvTab.home);
      tvHomeFocusRow.value++;
      return;
    }
    unawaited(_tuckAway());
  }

  // Playing, it shrinks into the corner window where the TV has one.
  Future<void> _tuckAway() async {
    if (AudioPlayerService().isPlaying && await TvPip.enter()) return;
    _appChannel.invokeMethod<void>('moveToBackground').catchError((_) {});
  }

  // Bumped on each visit to Settings, so it opens at its top.
  int _settingsVisit = 0;
  final _pickerFocus = FocusNode(debugLabel: 'tv library picker');
  final _refreshFocus = FocusNode(debugLabel: 'tv refresh');

  void _show(_TvTab tab) {
    if (tab == _tab) return;
    setState(() {
      if (tab == _TvTab.settings) _settingsVisit++;
      _tab = tab;
    });
  }

  /// Up with nowhere left to go in the page lands on its tab.
  KeyEventResult _onPageKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent || event.logicalKey != LogicalKeyboardKey.arrowUp) return KeyEventResult.ignored;
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return KeyEventResult.ignored;
    if (!focused.focusInDirection(TraversalDirection.up)) {
      _tabFocus[_tab]!.requestFocus();
      return KeyEventResult.handled;
    }
    // Leaving the page for the bar always lands on the page's own tab, not
    // whichever bar button happens to sit above. The move lands a moment
    // later, so look once it has.
    Future.microtask(() {
      final now = FocusManager.instance.primaryFocus;
      final inBar = _tabFocus.values.contains(now) || now == _pickerFocus || now == _refreshFocus;
      if ((inBar || now == focused) && mounted) _tabFocus[_tab]!.requestFocus();
    });
    return KeyEventResult.handled;
  }

  /// The bar's own arrows: side to side steps along it in order, never down
  /// into the page under it, and down goes into the page showing.
  KeyEventResult _onBarKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final order = [
      _tabFocus[_TvTab.home]!,
      _tabFocus[_TvTab.library]!,
      _tabFocus[_TvTab.search]!,
      if (_pickerFocus.context != null) _pickerFocus,
      _refreshFocus,
      _tabFocus[_TvTab.settings]!,
    ];
    final at = order.indexWhere((n) => n.hasPrimaryFocus);
    if (at < 0) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowRight) {
      final next = at + (k == LogicalKeyboardKey.arrowRight ? 1 : -1);
      if (next >= 0 && next < order.length) order[next].requestFocus();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      switch (_tab) {
        case _TvTab.home:
          tvHomeFocusRow.value++;
        case _TvTab.settings:
          tvSettingsTop.requestFocus();
        case _TvTab.library:
          tvFocusLibraryTop?.call();
        default:
          _tabFocus[_tab]!.focusInDirection(TraversalDirection.down);
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  Future<void> _pickLibrary() async {
    final lib = context.read<LibraryProvider>();
    final l = AppLocalizations.of(context)!;
    final libraries = lib.libraries.whereType<Map>().toList();
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        return Dialog(
          backgroundColor: cs.surfaceContainer,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(l.tvLibraries, style: tt.headlineSmall),
                const SizedBox(height: 16),
                for (final library in libraries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TvFocusable(
                      autofocus: library['id'] == lib.selectedLibraryId,
                      focusScale: 1.03,
                      onSelect: () => Navigator.pop(ctx, library['id'] as String?),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: library['id'] == lib.selectedLibraryId ? cs.primaryContainer : cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(library['mediaType'] == 'podcast' ? Icons.podcasts_rounded : Icons.headphones_rounded),
                            const SizedBox(width: 14),
                            Expanded(child: Text('${library['name'] ?? ''}', style: tt.titleMedium)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || picked == lib.selectedLibraryId || !mounted) return;
    // A new library means finding something to listen to: back to Home.
    _show(_TvTab.home);
    tvHomeFocusRow.value++;
    await lib.selectLibrary(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final current = lib.libraries.whereType<Map>().where((x) => x['id'] == lib.selectedLibraryId).firstOrNull;

    Widget tab(_TvTab t, String label, IconData icon) => Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TvPillButton(
        focusNode: _tabFocus[t],
        label: label,
        icon: icon,
        selected: _tab == t,
        // TV apps switch as the remote moves along the bar.
        onFocusChange: (v) {
          if (v) _show(t);
        },
        onSelect: () => _show(t),
      ),
    );

    final pages = <_TvTab, Widget>{
      _TvTab.home: TvHomeScreen(active: _tab == _TvTab.home, topInset: _barHeight),
      _TvTab.library: const Padding(padding: EdgeInsets.only(top: _barHeight), child: TvLibraryScreen()),
      _TvTab.search: const Padding(padding: EdgeInsets.only(top: _barHeight), child: TvSearchScreen()),
      _TvTab.settings: Padding(
        padding: const EdgeInsets.only(top: _barHeight),
        child: _TvSettings(key: ValueKey(_settingsVisit)),
      ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: _onPageKey,
                child: FocusTraversalGroup(
                child: Stack(
                  children: [
                    for (final entry in pages.entries)
                      Offstage(
                        offstage: entry.key != _tab,
                        child: TickerMode(
                          enabled: entry.key == _tab,
                          child: ExcludeFocus(excluding: entry.key != _tab, child: entry.value),
                        ),
                      ),
                    if (_tab != _TvTab.home)
                      Positioned(right: 28, bottom: 24, child: TvNowPlayingBar(hint: l.tvNowPlayingHint)),
                  ],
                ),
                ),
              ),
            ),
            // Over the pages, out of sight and out of reach while the player
            // is open.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: _barHeight,
              child: ValueListenableBuilder<bool>(
              valueListenable: tvPlayerOpen,
              builder: (context, playerOpen, bar) => ExcludeFocus(
                excluding: playerOpen,
                child: AnimatedOpacity(
                  opacity: playerOpen ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: bar,
                ),
              ),
              child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onBarKey,
              child: FocusTraversalGroup(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(56, 28, 56, 12),
                child: Row(
                  children: [
                    tab(_TvTab.home, l.tvHome, Icons.home_rounded),
                    tab(_TvTab.library, l.tvLibrary, Icons.grid_view_rounded),
                    tab(_TvTab.search, l.tvSearch, Icons.search_rounded),
                    const Spacer(),
                    if (lib.libraries.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: TvPillButton(
                          focusNode: _pickerFocus,
                          icon: Icons.unfold_more_rounded,
                          label: '${current?['name'] ?? l.tvLibraries}',
                          onSelect: _pickLibrary,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: TvPillButton(
                        focusNode: _refreshFocus,
                        icon: _refreshing ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                        label: '',
                        onSelect: _refresh,
                      ),
                    ),
                    TvPillButton(
                      focusNode: _tabFocus[_TvTab.settings],
                      icon: Icons.settings_rounded,
                      label: '',
                      selected: _tab == _TvTab.settings,
                      onFocusChange: (v) {
                        if (v) _show(_TvTab.settings);
                      },
                      onSelect: () => _show(_TvTab.settings),
                    ),
                  ],
                ),
              ),
            ),
            ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The first control in Settings, where down from the bar lands.
final tvSettingsTop = FocusNode(debugLabel: 'tv settings top');

class _TvSettings extends StatelessWidget {
  const _TvSettings({super.key});

  static String _host(String url) => Uri.tryParse(url)?.host ?? url;

  /// The same switch the phone makes: the loading view covers the change, the
  /// player stops, and the library loads for the other account.
  static Future<void> _switchTo(BuildContext context, SavedAccount account) async {
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    if (account.token.isEmpty) {
      await _addAccount(context);
      return;
    }
    auth.beginAccountSwitch();
    try {
      final player = AudioPlayerService();
      if (player.hasBook) {
        await player.pause();
        await player.stop();
      }
      if (!await auth.switchToAccount(account)) return;
      lib.updateAuth(auth);
      await lib.waitForActiveAccountReady();
    } finally {
      auth.finishAccountSwitch();
    }
  }

  /// One stray press of the remote shouldn't sign anyone out.
  static Future<void> _confirmSignOut(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tvSignOutQuestion(auth.username ?? '')),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.tvSignOut)),
        ],
      ),
    );
    if (ok == true) await auth.logout();
  }

  static Future<void> _addAccount(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TvPairScreen(adding: true)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();
    final server = _host(auth.serverUrl ?? '');
    final others = auth.savedAccounts
        .where((a) => !(a.serverUrl == auth.serverUrl && a.username == auth.username))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(56, 16, 56, 160),
      children: [
        Text(l.tvSignedInAs, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(l.signInTvAs(server, auth.username ?? ''), style: tt.headlineSmall),
        const SizedBox(height: 32),
        Text(l.tvAccounts, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        for (final account in others)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TvPillButton(
                focusNode: account == others.first ? tvSettingsTop : null,
                icon: Icons.person_rounded,
                label: l.signInTvAs(_host(account.serverUrl), account.username),
                onSelect: () => _switchTo(context, account),
              ),
            ),
          ),
        Row(children: [
          TvPillButton(
            focusNode: others.isEmpty ? tvSettingsTop : null,
            icon: Icons.person_add_alt_1_rounded,
            label: l.addAccount,
            onSelect: () => _addAccount(context),
          ),
          const SizedBox(width: 14),
          TvPillButton(icon: Icons.logout_rounded, label: l.tvSignOut, onSelect: () => _confirmSignOut(context)),
        ]),
        const SizedBox(height: 32),
        Text(l.tvPlayback, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        const _TvSkipSettings(),
        const SizedBox(height: 14),
        const TvPlaybackExtras(),
        const SizedBox(height: 32),
        Text(l.tvSleep, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        const TvSleepSettings(),
        const SizedBox(height: 10),
        Text(l.tvAutoNightHint, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 40),
        Text('Absorb ${ApiService.appVersionFull}', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

/// How far the player's skip buttons jump, back and forward. Each pill steps
/// through the usual amounts on OK.
class _TvSkipSettings extends StatefulWidget {
  const _TvSkipSettings();

  @override
  State<_TvSkipSettings> createState() => _TvSkipSettingsState();
}

class _TvSkipSettingsState extends State<_TvSkipSettings> {
  static const _steps = [5, 10, 15, 30, 45, 60];
  int? _back;
  int? _forward;

  @override
  void initState() {
    super.initState();
    PlayerSettings.getBackSkip().then((v) {
      if (mounted) setState(() => _back = v);
    });
    PlayerSettings.getForwardSkip().then((v) {
      if (mounted) setState(() => _forward = v);
    });
  }

  static int _next(int v) => _steps[(_steps.indexOf(v) + 1) % _steps.length];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final back = _back;
    final forward = _forward;
    if (back == null || forward == null) return const SizedBox(height: 48);
    return Row(children: [
      TvPillButton(
        icon: Icons.replay_rounded,
        label: l.tvSkipBack(back),
        onSelect: () {
          final v = _next(back);
          setState(() => _back = v);
          PlayerSettings.setBackSkip(v);
        },
      ),
      const SizedBox(width: 14),
      TvPillButton(
        icon: Icons.replay_rounded,
        mirrorIcon: true,
        label: l.tvSkipForward(forward),
        onSelect: () {
          final v = _next(forward);
          setState(() => _forward = v);
          PlayerSettings.setForwardSkip(v);
        },
      ),
    ]);
  }
}
