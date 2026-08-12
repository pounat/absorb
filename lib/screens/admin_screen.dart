import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/scoped_prefs.dart';
import '../services/server_task_tracker.dart';
import '../services/socket_service.dart';
import '../widgets/admin_adaptive_frame.dart';
import '../widgets/admin_task_indicator.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/rmab_config_sheet.dart';
import '../widgets/overlay_toast.dart';
import '../l10n/app_localizations.dart';
import '../utils/desktop_workspace.dart';
import '../widgets/desktop_page_body.dart';
import 'admin_users_screen.dart';
import 'admin_upload_screen.dart';
import 'admin_podcasts_screen.dart';
import 'admin_missing_items_screen.dart';
import 'admin_email_screen.dart';
import 'admin_api_keys_screen.dart';
import 'admin_libraries_screen.dart';
import 'admin_server_settings_screen.dart';
import 'admin_server_logs_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_sessions_screen.dart';

class _AdminNavigatorObserver extends NavigatorObserver {
  final VoidCallback onStackChanged;
  int routeDepth = 0;

  _AdminNavigatorObserver(this.onStackChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    routeDepth++;
    onStackChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    routeDepth--;
    onStackChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    routeDepth--;
    onStackChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    onStackChanged();
  }
}

class AdminScreen extends StatefulWidget {
  final ServerTaskTracker? taskTracker;

  const AdminScreen({super.key, this.taskTracker});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with WidgetsBindingObserver {
  static const _overviewSection = 'overview';

  bool _loading = true;
  bool _loadedOnce = false;
  List<dynamic> _users = [];
  List<dynamic> _onlineUsers = [];
  List<dynamic> _libraries = [];
  List<dynamic> _backups = [];
  List<dynamic> _sessions = [];
  final Map<String, Map<String, dynamic>> _libraryStats = {};
  final Map<String, int> _libraryIssues = {};
  String? _serverVersion;
  String? _rmabBaseUrl;
  String? _rmabApiToken;

  final Set<String> _scanningLibraries = {};
  final Set<String> _matchingLibraries = {};
  bool _creatingBackup = false;
  bool _purgingCache = false;
  late final ServerTaskTracker _taskTracker;
  late final bool _ownsTaskTracker;

  Timer? _issuesDebounce;
  Timer? _taskRefreshTimer;
  bool _refreshingTasks = false;
  final GlobalKey<NavigatorState> _desktopNavigatorKey = GlobalKey<NavigatorState>();
  late final _AdminNavigatorObserver _desktopNavigatorObserver;
  String _desktopSection = _overviewSection;
  bool _desktopNavigatorCanPop = false;
  bool _desktopNavigationChanging = false;
  int _desktopNavigationSerial = 0;
  bool _desktopUsersDirty = false;
  bool _desktopLibrariesDirty = false;
  bool _desktopOverviewDirty = false;
  int _desktopUsersDirtyGeneration = 0;
  int _desktopLibrariesDirtyGeneration = 0;
  int _desktopOverviewDirtyGeneration = 0;
  bool _desktopOverviewRefreshActive = false;
  Future<void>? _desktopUsersRefresh;
  Future<void>? _desktopLibrariesRefresh;
  bool? _desktopPresentation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _desktopNavigatorObserver = _AdminNavigatorObserver(_onDesktopStackChanged);
    DesktopWorkspaceNavigator.registerExitGuard(this, _prepareForDesktopPaneReset);
    _ownsTaskTracker = widget.taskTracker == null;
    _taskTracker = widget.taskTracker ?? ServerTaskTracker();
    if (_ownsTaskTracker) _startTaskRefreshTimer();
    _loadAll();
    SocketService().addItemsChangedListener(_onItemsChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _desktopPresentation ??= isDesktopWorkspace(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DesktopWorkspaceNavigator.unregisterExitGuard(this);
    SocketService().removeItemsChangedListener(_onItemsChanged);
    _issuesDebounce?.cancel();
    _taskRefreshTimer?.cancel();
    if (_ownsTaskTracker) _taskTracker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ownsTaskTracker) return;
    if (state == AppLifecycleState.resumed) {
      _startTaskRefreshTimer();
      unawaited(_refreshServerTasks());
    } else {
      _taskRefreshTimer?.cancel();
    }
  }

  void _startTaskRefreshTimer() {
    _taskRefreshTimer?.cancel();
    _taskRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_refreshServerTasks());
    });
  }

  Future<void> _refreshServerTasks() async {
    if (!mounted || _refreshingTasks) return;
    final service = context.read<AuthProvider>().apiService;
    if (service == null) return;
    _refreshingTasks = true;
    try {
      await _taskTracker.refresh(service);
    } finally {
      _refreshingTasks = false;
    }
  }

  // Scans flag items missing/invalid server-side and stream items_updated
  // events in chunks, so wait for a quiet moment then re-count once.
  void _onItemsChanged() {
    if (!mounted) return;
    _issuesDebounce?.cancel();
    _issuesDebounce = Timer(const Duration(seconds: 2), _refreshIssueCounts);
  }

  Future<void> _refreshIssueCounts() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null || !mounted) return;
    for (final lib in _libraries) {
      final id = lib['id'] as String? ?? '';
      if (id.isEmpty) continue;
      _libraryIssues[id] = await api.getIssueItemCount(id);
      if (!mounted) return;
    }
    setState(() {});
  }

  Future<void> _loadAll() async {
    final usersGeneration = _desktopUsersDirtyGeneration;
    final librariesGeneration = _desktopLibrariesDirtyGeneration;
    final overviewGeneration = _desktopOverviewDirtyGeneration;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    if (!_loadedOnce) setState(() => _loading = true);

    final taskRefresh = _refreshServerTasks();
    final futures = await Future.wait([
      api.getUsers(), api.getOnlineUsers(), api.getLibraries(), api.getBackups(), api.getAllSessions(limit: 10),
    ]);
    await taskRefresh;
    if (!mounted) return;
    _users = futures[0];
    _onlineUsers = futures[1];
    _libraries = futures[2];
    _backups = futures[3];
    _sessions = futures[4];
    _serverVersion = context.read<AuthProvider>().serverVersion;

    for (final lib in _libraries) {
      final id = lib['id'] as String? ?? '';
      if (id.isNotEmpty) {
        final stats = await api.getLibraryStats(id);
        if (!mounted) return;
        if (stats != null) _libraryStats[id] = stats;
        _libraryIssues[id] = await api.getIssueItemCount(id);
        if (!mounted) return;
      }
    }
    _rmabBaseUrl = await ScopedPrefs.getString(kRmabBaseUrlKey);
    if (!mounted) return;
    _rmabApiToken = await ScopedPrefs.getString(kRmabApiTokenKey);
    if (!mounted) return;
    if (_desktopUsersDirtyGeneration == usersGeneration) {
      _desktopUsersDirty = false;
    }
    if (_desktopLibrariesDirtyGeneration == librariesGeneration) {
      _desktopLibrariesDirty = false;
    }
    if (_desktopOverviewDirtyGeneration == overviewGeneration) {
      _desktopOverviewDirty = false;
    }
    setState(() {
      _loadedOnce = true;
      _loading = false;
    });
    _leaveUnavailablePodcastSection();
  }

  bool get _hasRmab =>
      (_rmabBaseUrl ?? '').isNotEmpty && (_rmabApiToken ?? '').isNotEmpty;

  bool get _hasPodcastLibrary => _libraries.any((l) => l['mediaType'] == 'podcast');

  List<dynamic> get _activeSessions => _sessions.where((s) {
    final updatedAt = s['updatedAt'] as num? ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - updatedAt) < 300000;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final desktopPresentation = _desktopPresentation ?? false;
    if (desktopPresentation) {
      return _buildDesktopScaffold(context, l);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : DesktopPageBody(
                child: RefreshIndicator(
                onRefresh: _loadAll,
                notificationPredicate: (n) => !desktopPresentation && n.depth == 0,
                child: ListView(
                  padding: EdgeInsets.only(
                      bottom: desktopPresentation ? 24 : 80),
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                      child: Row(children: [
                        Expanded(child: AbsorbPageHeader(title: l.adminTitle, padding: EdgeInsets.zero)),
                        ListenableBuilder(
                          listenable: _taskTracker,
                          builder: (_, __) => AdminTaskIndicator(
                            tasks: _taskTracker.visibleTasks,
                            onPressed: () => showAdminTasksSheet(context, _taskTracker),
                          ),
                        ),
                        if (desktopPresentation)
                          IconButton(
                            tooltip: l.refreshTooltip,
                            icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
                            onPressed: _loadAll,
                          ),
                        IconButton(icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant), onPressed: () => Navigator.pop(context)),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Server Overview ──
                    _section(cs, tt, l.adminServer),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDeco(cs),
                        child: Row(children: [
                          _stat(tt, cs, Icons.dns_rounded, _serverVersion ?? '–', l.adminVersion),
                          _stat(tt, cs, Icons.people_rounded, '${_users.length}', l.adminUsers),
                          _stat(tt, cs, Icons.wifi_rounded, '${_onlineUsers.length}', l.adminOnline),
                          _stat(tt, cs, Icons.backup_rounded, '${_backups.length}', l.adminBackupsLabel),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Expanded(child: _actionBtn(cs, tt, Icons.backup_rounded, l.adminBackup, _creatingBackup, _createBackup)),
                        const SizedBox(width: 10),
                        Expanded(child: _actionBtn(cs, tt, Icons.cleaning_services_rounded, l.adminPurgeCache, _purgingCache, _purgeCache)),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // ── Manage Buttons ──
                    _section(cs, tt, l.adminManage),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [
                        _navButton(cs, tt,
                          icon: Icons.people_rounded,
                          label: l.adminUsers,
                          subtitle: l.adminUsersSubtitle(_users.length, _onlineUsers.length),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AdminUsersScreen(users: _users, onlineUsers: _onlineUsers, libraries: _libraries)));
                            _loadAll();
                          },
                        ),
                        const SizedBox(height: 10),
                        _navButton(cs, tt,
                          icon: Icons.cloud_upload_rounded,
                          label: l.adminUploadTitle,
                          subtitle: l.adminUploadSubtitle,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AdminUploadScreen(
                                libraries: _libraries,
                                initialLibraryId: context.read<AuthProvider>().defaultLibraryId,
                                apiService: context.read<AuthProvider>().apiService,
                              ),
                            ));
                          },
                        ),
                        const SizedBox(height: 10),
                        if (_hasPodcastLibrary)
                          _navButton(cs, tt,
                            icon: Icons.podcasts_rounded,
                            label: l.adminPodcasts,
                            subtitle: l.adminPodcastsSubtitle,
                            onTap: () {
                              final podLib = _libraries.firstWhere((l) => l['mediaType'] == 'podcast', orElse: () => null);
                              if (podLib != null) {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => AdminPodcastsScreen(library: podLib)));
                              }
                            },
                          ),
                        if (_hasPodcastLibrary) const SizedBox(height: 10),
                        _navButton(cs, tt,
                          icon: Icons.email_rounded,
                          label: l.adminEmail,
                          subtitle: l.adminEmailSubtitle,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AdminEmailScreen(users: _users)));
                          },
                        ),
                        const SizedBox(height: 10),
                        _navButton(cs, tt,
                          icon: Icons.vpn_key_rounded,
                          label: l.adminApiKeys,
                          subtitle: l.adminApiKeysSubtitle,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AdminApiKeysScreen(users: _users)));
                          },
                        ),
                        const SizedBox(height: 10),
                        _navButton(cs, tt,
                          icon: Icons.library_books_rounded,
                          label: l.adminLibrariesManage,
                          subtitle: l.adminLibrariesManageSubtitle,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AdminLibrariesScreen(libraries: _libraries)));
                            _loadAll();
                          },
                        ),
                        const SizedBox(height: 10),
                        _navButton(cs, tt,
                          icon: Icons.tune_rounded,
                          label: l.adminServerSettings,
                          subtitle: l.adminServerSettingsSubtitle,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const AdminServerSettingsScreen()));
                          },
                        ),
                        const SizedBox(height: 10),
                        _navButton(cs, tt,
                          icon: Icons.description_outlined,
                          label: 'Server logs',
                          subtitle: l.sendLogsSubtitle,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const AdminServerLogsScreen()));
                          },
                        ),
                        const SizedBox(height: 10),
                        _navButton(cs, tt,
                          icon: Icons.bar_chart_rounded,
                          label: l.adminStats,
                          subtitle: l.adminStatsSubtitle,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const AdminStatsScreen()));
                          },
                        ),
                        const SizedBox(height: 10),
                        _navButton(cs, tt,
                          icon: Icons.history_rounded,
                          label: l.adminAllSessions,
                          subtitle: l.adminAllSessionsSubtitle,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AdminSessionsScreen(users: _users)));
                            _loadAll();
                          },
                        ),
                        const SizedBox(height: 10),
                        if (_hasRmab) _rmabTile(cs, tt) else _rmabAddRow(cs, tt),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // ── Active Sessions ──
                    if (_activeSessions.isNotEmpty) ...[
                      _section(cs, tt, l.adminListeningNow),
                      ..._activeSessions.map((s) => _sessionCard(cs, tt, s)),
                      const SizedBox(height: 18),
                    ],

                    // ── Libraries ──
                    _section(cs, tt, l.adminLibraries),
                    ListenableBuilder(
                      listenable: _taskTracker,
                      builder: (_, __) => Column(
                        children: _libraries
                            .map((lib) => _libraryCard(cs, tt, lib))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              ),
      ),
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────

  Widget _buildDesktopScaffold(BuildContext context, AppLocalizations l) {
    final outerNavigator = Navigator.of(context);
    final destinations = <AdminSectionDestination>[
      AdminSectionDestination(_overviewSection, Icons.dashboard_rounded, l.adminServer),
      AdminSectionDestination('users', Icons.people_rounded, l.adminUsers),
      AdminSectionDestination('upload', Icons.cloud_upload_rounded, l.adminUploadTitle),
      if (_hasPodcastLibrary || _desktopSection == 'podcasts')
        AdminSectionDestination('podcasts', Icons.podcasts_rounded, l.adminPodcasts),
      AdminSectionDestination('email', Icons.email_rounded, l.adminEmail),
      AdminSectionDestination('api-keys', Icons.vpn_key_rounded, l.adminApiKeys),
      AdminSectionDestination('libraries', Icons.library_books_rounded, l.adminLibrariesManage),
      AdminSectionDestination('server-settings', Icons.tune_rounded, l.adminServerSettings),
      const AdminSectionDestination('logs', Icons.description_outlined, 'Server logs'),
      AdminSectionDestination('stats', Icons.bar_chart_rounded, l.adminStats),
      AdminSectionDestination('sessions', Icons.history_rounded, l.adminAllSessions),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : PopScope(
                canPop: !_desktopNavigatorCanPop,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  final navigator = _desktopNavigatorKey.currentState;
                  if (navigator != null) unawaited(navigator.maybePop(result));
                },
                child: AdminAdaptiveFrame(
                  desktopMode: true,
                  title: l.adminTitle,
                  selectedSection: _desktopSection,
                  destinations: destinations,
                  onSectionSelected: (section) => unawaited(_selectDesktopSection(section)),
                  child: Navigator(
                    key: _desktopNavigatorKey,
                    observers: [_desktopNavigatorObserver],
                    onDidRemovePage: (_) {},
                    pages: [
                      MaterialPage<void>(
                        key: const ValueKey('admin-overview-page'),
                        name: '/admin/overview',
                        child: Builder(
                          builder: (pageContext) => _buildDesktopOverview(
                            pageContext,
                            onClose: () => outerNavigator.pop(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopOverview(BuildContext pageContext, {required VoidCallback onClose}) {
    final cs = Theme.of(pageContext).colorScheme;
    final tt = Theme.of(pageContext).textTheme;
    final l = AppLocalizations.of(pageContext)!;

    return DesktopPageBody(
      maxWidth: 1040,
      child: RefreshIndicator(
        onRefresh: _loadAll,
        notificationPredicate: (_) => false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(children: [
                Expanded(child: AbsorbPageHeader(title: l.adminTitle, padding: EdgeInsets.zero)),
                IconButton(
                  tooltip: l.refreshTooltip,
                  icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
                  onPressed: _loadAll,
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                  onPressed: onClose,
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _section(cs, tt, l.adminServer),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDeco(cs),
                child: Row(children: [
                  _stat(tt, cs, Icons.dns_rounded, _serverVersion ?? '–', l.adminVersion),
                  _stat(tt, cs, Icons.people_rounded, '${_users.length}', l.adminUsers),
                  _stat(tt, cs, Icons.wifi_rounded, '${_onlineUsers.length}', l.adminOnline),
                  _stat(tt, cs, Icons.backup_rounded, '${_backups.length}', l.adminBackupsLabel),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: _actionBtn(cs, tt, Icons.backup_rounded, l.adminBackup, _creatingBackup, _createBackup)),
                const SizedBox(width: 10),
                Expanded(child: _actionBtn(cs, tt, Icons.cleaning_services_rounded, l.adminPurgeCache, _purgingCache, _purgeCache)),
              ]),
            ),
            const SizedBox(height: 28),
            _section(cs, tt, l.adminRmab),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _hasRmab ? _rmabTile(cs, tt) : _rmabAddRow(cs, tt),
            ),
            const SizedBox(height: 28),
            if (_activeSessions.isNotEmpty) ...[
              _section(cs, tt, l.adminListeningNow),
              ..._activeSessions.map((session) => _sessionCard(cs, tt, session)),
              const SizedBox(height: 18),
            ],
            _section(cs, tt, l.adminLibraries),
            ListenableBuilder(
              listenable: _taskTracker,
              builder: (_, __) => Column(
                children: _libraries.map((library) => _libraryCard(cs, tt, library)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDesktopStackChanged() {
    DesktopWorkspaceNavigator.notifyExitGuardChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final canPop = _desktopNavigatorKey.currentState?.canPop() ?? false;
      if (canPop != _desktopNavigatorCanPop) {
        setState(() => _desktopNavigatorCanPop = canPop);
      }
    });
  }

  Future<void> _selectDesktopSection(String section) async {
    final navigator = _desktopNavigatorKey.currentState;
    if (navigator == null || _desktopNavigationChanging) return;
    if (section == _desktopSection &&
        (section != _overviewSection || !navigator.canPop())) return;

    final previousSection = _desktopSection;
    final previousSerial = _desktopNavigationSerial;
    _desktopNavigationChanging = true;
    final navigationSerial = ++_desktopNavigationSerial;

    try {
      if (!await _popDesktopNavigatorToOverview(navigator)) {
        _desktopNavigationSerial = previousSerial;
        return;
      }
      if (!mounted || _desktopNavigatorKey.currentState != navigator) return;
      _markDesktopSectionDirty(previousSection);

      if (section == _overviewSection) {
        if (_desktopSection != _overviewSection || _desktopNavigatorCanPop) {
          setState(() {
            _desktopSection = _overviewSection;
            _desktopNavigatorCanPop = false;
          });
        }
        unawaited(_refreshDesktopOverviewIfNeeded());
        return;
      }

      setState(() {
        _desktopSection = section;
        _desktopNavigatorCanPop = true;
      });
      final sectionPreparation = _prepareDesktopSectionInputs(section);
      final route = MaterialPageRoute<void>(
        settings: RouteSettings(name: '/admin/$section'),
        builder: (routeContext) => _buildPreparedDesktopSectionPage(
          routeContext,
          section,
          sectionPreparation,
        ),
      );
      unawaited(navigator.push(route).then((_) {
        if (!mounted || navigationSerial != _desktopNavigationSerial) return;
        setState(() {
          _desktopSection = _overviewSection;
          _desktopNavigatorCanPop = false;
        });
        _markDesktopSectionDirty(section);
        unawaited(_refreshDesktopOverviewIfNeeded());
      }));
    } finally {
      _desktopNavigationChanging = false;
    }
  }

  Future<bool> _prepareForDesktopPaneReset() async {
    if (!mounted || _desktopPresentation != true) return true;
    final navigator = _desktopNavigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) return true;
    if (_desktopNavigationChanging) return false;

    final previousSerial = _desktopNavigationSerial;
    _desktopNavigationChanging = true;
    _desktopNavigationSerial++;
    try {
      if (!await _popDesktopNavigatorToOverview(navigator)) {
        _desktopNavigationSerial = previousSerial;
        return false;
      }
      if (mounted) {
        setState(() {
          _desktopSection = _overviewSection;
          _desktopNavigatorCanPop = false;
        });
      }
      return true;
    } finally {
      _desktopNavigationChanging = false;
    }
  }

  Future<bool> _popDesktopNavigatorToOverview(
    NavigatorState navigator,
  ) async {
    while (navigator.canPop()) {
      final routeDepth = _desktopNavigatorObserver.routeDepth;
      await navigator.maybePop();
      if (_desktopNavigatorObserver.routeDepth >= routeDepth) return false;
    }
    return true;
  }

  void _markDesktopSectionDirty(String section) {
    if (section == 'users') {
      _desktopUsersDirty = true;
      _desktopUsersDirtyGeneration++;
      _desktopOverviewDirty = true;
      _desktopOverviewDirtyGeneration++;
    } else if (section == 'libraries') {
      _desktopLibrariesDirty = true;
      _desktopLibrariesDirtyGeneration++;
      _desktopOverviewDirty = true;
      _desktopOverviewDirtyGeneration++;
    } else if (section == 'sessions') {
      _desktopOverviewDirty = true;
      _desktopOverviewDirtyGeneration++;
    }
  }

  Future<void> _refreshDesktopOverviewIfNeeded() async {
    if (!_desktopOverviewDirty || _desktopOverviewRefreshActive) return;
    _desktopOverviewRefreshActive = true;
    try {
      do {
        await _loadAll();
      } while (mounted && _desktopOverviewDirty);
    } catch (error) {
      debugPrint('[Admin] Could not refresh overview: $error');
    } finally {
      _desktopOverviewRefreshActive = false;
    }
  }

  Future<void>? _prepareDesktopSectionInputs(String nextSection) {
    if (_desktopUsersDirty &&
        (nextSection == 'email' ||
            nextSection == 'api-keys' ||
            nextSection == 'sessions')) {
      return _refreshDesktopUsers();
    }
    if (_desktopLibrariesDirty &&
        (nextSection == 'users' ||
            nextSection == 'upload' ||
            nextSection == 'podcasts')) {
      return _refreshDesktopLibraries();
    }
    return null;
  }

  Future<void> _refreshDesktopUsers() {
    final activeRefresh = _desktopUsersRefresh;
    if (activeRefresh != null) return activeRefresh;
    final refresh = _runDesktopUsersRefresh();
    _desktopUsersRefresh = refresh;
    unawaited(refresh.whenComplete(() {
      if (identical(_desktopUsersRefresh, refresh)) {
        _desktopUsersRefresh = null;
      }
    }));
    return refresh;
  }

  Future<void> _runDesktopUsersRefresh() async {
    if (!mounted) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    try {
      do {
        final generation = _desktopUsersDirtyGeneration;
        final results = await Future.wait([
          api.getUsers(),
          api.getOnlineUsers(),
        ]);
        if (!mounted) return;
        setState(() {
          _users = results[0];
          _onlineUsers = results[1];
          if (_desktopUsersDirtyGeneration == generation) {
            _desktopUsersDirty = false;
          }
        });
      } while (mounted && _desktopUsersDirty);
    } catch (error) {
      debugPrint('[Admin] Could not refresh users: $error');
    }
  }

  Future<void> _refreshDesktopLibraries() {
    final activeRefresh = _desktopLibrariesRefresh;
    if (activeRefresh != null) return activeRefresh;
    final refresh = _runDesktopLibrariesRefresh();
    _desktopLibrariesRefresh = refresh;
    unawaited(refresh.whenComplete(() {
      if (identical(_desktopLibrariesRefresh, refresh)) {
        _desktopLibrariesRefresh = null;
      }
    }));
    return refresh;
  }

  Future<void> _runDesktopLibrariesRefresh() async {
    if (!mounted) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    try {
      do {
        final generation = _desktopLibrariesDirtyGeneration;
        final libraries = await api.getLibraries();
        if (!mounted) return;
        setState(() {
          _libraries = libraries;
          if (_desktopLibrariesDirtyGeneration == generation) {
            _desktopLibrariesDirty = false;
          }
        });
      } while (mounted && _desktopLibrariesDirty);
      _leaveUnavailablePodcastSection();
    } catch (error) {
      debugPrint('[Admin] Could not refresh libraries: $error');
    }
  }

  void _leaveUnavailablePodcastSection() {
    if (_desktopPresentation != true ||
        _desktopSection != 'podcasts' ||
        _hasPodcastLibrary) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _desktopSection != 'podcasts' ||
          _hasPodcastLibrary) {
        return;
      }
      unawaited(_selectDesktopSection(_overviewSection));
    });
  }

  Widget _buildPreparedDesktopSectionPage(
    BuildContext routeContext,
    String section,
    Future<void>? preparation,
  ) {
    if (preparation == null) {
      return _buildDesktopSectionPage(routeContext, section);
    }
    return FutureBuilder<void>(
      future: preparation,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _buildDesktopSectionPage(context, section);
      },
    );
  }

  Widget _buildDesktopSectionPage(BuildContext routeContext, String section) {
    switch (section) {
      case 'users':
        return AdminUsersScreen(users: _users, onlineUsers: _onlineUsers, libraries: _libraries);
      case 'upload':
        return AdminUploadScreen(
          libraries: _libraries,
          initialLibraryId: routeContext.read<AuthProvider>().defaultLibraryId,
          apiService: routeContext.read<AuthProvider>().apiService,
          onNavigationGuardChanged:
              DesktopWorkspaceNavigator.notifyExitGuardChanged,
        );
      case 'podcasts':
        final podcastLibrary = _libraries.firstWhere(
          (library) => library['mediaType'] == 'podcast',
          orElse: () => null,
        );
        return podcastLibrary == null
            ? const SizedBox.shrink()
            : AdminPodcastsScreen(library: podcastLibrary);
      case 'email':
        return AdminEmailScreen(users: _users);
      case 'api-keys':
        return AdminApiKeysScreen(users: _users);
      case 'libraries':
        return AdminLibrariesScreen(libraries: _libraries);
      case 'server-settings':
        return const AdminServerSettingsScreen();
      case 'logs':
        return const AdminServerLogsScreen();
      case 'stats':
        return const AdminStatsScreen();
      case 'sessions':
        return AdminSessionsScreen(users: _users);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _section(ColorScheme cs, TextTheme tt, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Text(t, style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontWeight: FontWeight.w600, letterSpacing: 0.5)));

  BoxDecoration _cardDeco(ColorScheme cs) => BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16));

  Widget _stat(TextTheme tt, ColorScheme cs, IconData ic, String v, String l) => Expanded(child: Column(children: [
    Icon(ic, size: 18, color: cs.primary.withValues(alpha: 0.6)), const SizedBox(height: 6),
    Text(v, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)), const SizedBox(height: 2),
    Text(l, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10)),
  ]));

  Widget _actionBtn(ColorScheme cs, TextTheme tt, IconData ic, String l, bool loading, VoidCallback onTap) =>
    GestureDetector(onTap: loading ? null : onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (loading) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onSurfaceVariant.withValues(alpha: 0.5)))
        else Icon(ic, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(l, style: tt.labelMedium?.copyWith(color: loading ? cs.onSurface.withValues(alpha: 0.24) : cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
      ])));

  Widget _navButton(ColorScheme cs, TextTheme tt, {required IconData icon, required String label, required String subtitle, required VoidCallback onTap}) =>
    GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDeco(cs),
      child: Row(children: [
        Icon(icon, color: cs.primary, size: 22), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
          Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        ])),
        Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.15)),
      ])));

  // ─── ReadMeABook Integration ────────────────────────────────

  Widget _rmabTile(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _openRmabSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: _cardDeco(cs),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Icon(Icons.menu_book_rounded, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.adminRmab, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
            Text(l.adminRmabConnected, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
          ])),
          Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.15)),
        ]),
      ),
    );
  }

  Widget _rmabAddRow(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _openRmabSheet,
        style: TextButton.styleFrom(
          foregroundColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(l.adminRmabAdd, style: tt.labelMedium),
      ),
    );
  }

  Future<void> _openRmabSheet() async {
    final l = AppLocalizations.of(context)!;
    final result =
        await showRmabConfigSheet(context, isAdminContext: true);
    if (!mounted || result == null) return;
    if (result.changed || result.disconnected) {
      await _loadAll();
      if (!mounted) return;
      _msg(
        result.disconnected
            ? l.rmabConfigDisconnectedSnackbar
            : l.rmabConfigSavedSnackbar,
        icon: result.disconnected
            ? Icons.link_off_rounded
            : Icons.check_circle_outline_rounded,
      );
    }
  }

  // ─── Library Card ───────────────────────────────────────────

  Widget _libraryCard(ColorScheme cs, TextTheme tt, dynamic lib) {
    final l = AppLocalizations.of(context)!;
    final id = lib['id'] as String? ?? '';
    final name = lib['name'] as String? ?? l.libraryFallback;
    final mediaType = lib['mediaType'] as String? ?? 'book';
    final folders = (lib['folders'] as List?)?.length ?? 0;
    final stats = _libraryStats[id];
    final totalItems = stats?['totalItems'] ?? 0;
    final totalSize = stats?['totalSize'] as num?;
    final totalDur = stats?['totalDuration'] as num?;
    final isScanning = _scanningLibraries.contains(id) ||
        _taskTracker.isLibraryActionRunning('library-scan', id);
    final isMatching = _matchingLibraries.contains(id) ||
        _taskTracker.isLibraryActionRunning('library-match-all', id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(padding: const EdgeInsets.all(16), decoration: _cardDeco(cs),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(mediaType == 'podcast' ? Icons.podcasts_rounded : Icons.auto_stories_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(mediaType, style: tt.labelSmall?.copyWith(color: cs.primary, fontSize: 10, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _mini(cs, tt, '$totalItems', mediaType == 'podcast' ? l.adminLibraryShows : l.adminLibraryBooks),
            if (folders > 0) _mini(cs, tt, '$folders', l.adminLibraryFolders),
            if (totalSize != null) _mini(cs, tt, _fmtB(totalSize.toInt()), l.adminLibrarySize),
            if (totalDur != null) _mini(cs, tt, _fmtD(totalDur.toDouble()), l.adminLibraryDuration),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _libAct(cs, tt, Icons.search_rounded, isScanning ? l.adminScanning : l.adminScan, isScanning, () => _scanLib(id, name))),
            const SizedBox(width: 8),
            Expanded(child: _libAct(cs, tt, Icons.auto_fix_high_rounded, isMatching ? l.adminMatching : l.adminMatchAll, isMatching, () => _matchLib(id, name))),
          ]),
          if ((_libraryIssues[id] ?? 0) > 0) ...[
            const SizedBox(height: 8),
            _issuesRow(cs, tt, lib, _libraryIssues[id]!),
          ],
        ])));
  }

  Widget _issuesRow(ColorScheme cs, TextTheme tt, dynamic lib, int count) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () async {
        final navigator = _desktopNavigatorKey.currentState ?? Navigator.of(context);
        await navigator.push(MaterialPageRoute(
          builder: (_) => AdminMissingItemsScreen(library: Map<String, dynamic>.from(lib as Map))));
        _loadAll();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(Icons.report_problem_rounded, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(l.adminLibraryIssues(count),
            style: tt.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
          Text(l.adminLibraryReview, style: tt.labelSmall?.copyWith(color: Colors.orange.shade700, fontWeight: FontWeight.w700)),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 16, color: Colors.orange.shade700),
        ]),
      ),
    );
  }

  Widget _mini(ColorScheme cs, TextTheme tt, String v, String l) => Padding(padding: const EdgeInsets.only(right: 20), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(v, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface, fontSize: 13)),
      Text(l, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 10)),
    ]));

  Widget _libAct(ColorScheme cs, TextTheme tt, IconData ic, String l, bool loading, VoidCallback onTap) =>
    GestureDetector(onTap: loading ? null : onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (loading) SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onSurfaceVariant.withValues(alpha: 0.5)))
        else Icon(ic, size: 14, color: cs.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(l, style: tt.labelSmall?.copyWith(color: loading ? cs.onSurface.withValues(alpha: 0.24) : cs.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w600, fontSize: 11)),
      ])));

  Widget _sessionCard(ColorScheme cs, TextTheme tt, dynamic session) {
    final l = AppLocalizations.of(context)!;
    final displayTitle = session['displayTitle'] as String? ?? l.unknown;
    final displayAuthor = session['displayAuthor'] as String? ?? '';
    final userName = _userNameForSession(session);
    final currentTime = session['currentTime'] as num? ?? 0;
    final duration = session['duration'] as num? ?? 0;
    final updatedAt = session['updatedAt'] as num? ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isActive = (now - updatedAt) < 300000;
    final progress = duration > 0 ? (currentTime / duration).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(padding: const EdgeInsets.all(14), decoration: _cardDeco(cs),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF4CAF50) : cs.onSurface.withValues(alpha: 0.24),
          )),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displayTitle, style: tt.bodySmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              [if (userName.isNotEmpty) userName, if (displayAuthor.isNotEmpty) displayAuthor].join(' · '),
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 10),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress.toDouble(),
                minHeight: 2, backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.24)))),
          ])),
          const SizedBox(width: 12),
          Text('${_fmtD(currentTime.toDouble())} / ${_fmtD(duration.toDouble())}',
            style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 9)),
        ])),
    );
  }

  String _userNameForSession(dynamic session) {
    final userId = session['userId'] as String? ?? '';
    if (userId.isEmpty) return '';
    final user = _users.cast<Map<String, dynamic>?>().firstWhere(
      (u) => u?['id'] == userId, orElse: () => null);
    return user?['username'] as String? ?? '';
  }

  // ─── Actions ────────────────────────────────────────────────

  Future<void> _scanLib(String id, String name) async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _scanningLibraries.add(id));
    final ok = await api.scanLibrary(id);
    if (ok) await _refreshServerTasks();
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() => _scanningLibraries.remove(id));
      _msg(ok ? l.adminScanStarted(name) : l.adminScanFailed(name),
          icon: ok ? Icons.refresh_rounded : Icons.error_outline_rounded);
    }
  }

  Future<void> _matchLib(String id, String name) async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.adminMatchAllTitle),
      content: Text(l.adminMatchAllContent(name)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.adminMatchAction))],
    ));
    if (yes != true) return;
    setState(() => _matchingLibraries.add(id));
    final ok = await api.matchLibrary(id);
    if (ok) await _refreshServerTasks();
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      setState(() => _matchingLibraries.remove(id));
      _msg(ok ? l2.adminMatchingStarted(name) : l2.adminMatchFailed,
          icon: ok ? Icons.manage_search_rounded : Icons.error_outline_rounded);
    }
  }

  Future<void> _createBackup() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _creatingBackup = true);
    final ok = await api.createBackup();
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() => _creatingBackup = false);
      _msg(ok ? l.adminBackupCreated : l.adminBackupFailed,
          icon: ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded);
      if (ok) _loadAll();
    }
  }

  Future<void> _purgeCache() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _purgingCache = true);
    final ok = await api.purgeCache();
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() => _purgingCache = false);
      _msg(ok ? l.adminCachePurged : l.adminPurgeCacheFailed,
          icon: ok ? Icons.cleaning_services_rounded : Icons.error_outline_rounded);
    }
  }

  void _msg(String s, {IconData? icon}) =>
      showOverlayToast(context, s, icon: icon);

  String _fmtB(int b) { if (b < 1024) return '$b B'; if (b < 1048576) return '${(b / 1024).toStringAsFixed(0)} KB';
    if (b < 1073741824) return '${(b / 1048576).toStringAsFixed(1)} MB'; return '${(b / 1073741824).toStringAsFixed(1)} GB'; }
  String _fmtD(double s) { final h = (s / 3600).floor(); if (h > 24) return '${(h / 24).floor()}d ${h % 24}h';
    final m = ((s % 3600) / 60).floor(); return h > 0 ? '${h}h ${m}m' : '${m}m'; }
}
