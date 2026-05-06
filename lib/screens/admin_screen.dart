import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/scoped_prefs.dart';
import '../widgets/absorb_page_header.dart';
import '../l10n/app_localizations.dart';
import 'admin_users_screen.dart';
import 'admin_podcasts_screen.dart';
import 'admin_rmab_screen.dart';

const _kRmabUrlKey = 'rmab_url';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _loading = true;
  List<dynamic> _users = [];
  List<dynamic> _onlineUsers = [];
  List<dynamic> _libraries = [];
  List<dynamic> _backups = [];
  List<dynamic> _sessions = [];
  final Map<String, Map<String, dynamic>> _libraryStats = {};
  String? _serverVersion;
  String? _rmabUrl;

  final Set<String> _scanningLibraries = {};
  final Set<String> _matchingLibraries = {};
  bool _creatingBackup = false;
  bool _purgingCache = false;

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _loading = true);

    final futures = await Future.wait([
      api.getUsers(), api.getOnlineUsers(), api.getLibraries(), api.getBackups(), api.getAllSessions(limit: 10),
    ]);
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
        if (stats != null) _libraryStats[id] = stats;
      }
    }
    _rmabUrl = await ScopedPrefs.getString(_kRmabUrlKey);
    if (mounted) setState(() => _loading = false);
  }

  bool get _hasRmab => (_rmabUrl ?? '').isNotEmpty;

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                      child: Row(children: [
                        Expanded(child: AbsorbPageHeader(title: l.adminTitle, padding: EdgeInsets.zero)),
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
                    ..._libraries.map((lib) => _libraryCard(cs, tt, lib)),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────

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
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdminRmabScreen(url: _rmabUrl!))),
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
            Text(l.adminRmabSubtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
          ])),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurface.withValues(alpha: 0.4), size: 20),
            tooltip: '',
            onSelected: (v) {
              if (v == 'edit') _showRmabUrlDialog();
              if (v == 'remove') _clearRmab();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l.edit)),
              PopupMenuItem(value: 'remove', child: Text(l.remove)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _rmabAddRow(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _showRmabUrlDialog,
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

  Future<void> _showRmabUrlDialog() async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _rmabUrl ?? '');
    String? err;

    final saved = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
        title: Text(l.adminRmabUrlTitle),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.adminRmabUrlHelp, style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: l.adminRmabUrlHint,
              errorText: err,
              border: const OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isEmpty) { setLocal(() => err = l.adminRmabInvalidUrl); return; }
              final u = Uri.tryParse(v);
              if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) {
                setLocal(() => err = l.adminRmabInvalidUrl);
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: Text(l.save),
          ),
        ],
      )),
    );

    if (saved == null) return;
    await ScopedPrefs.setString(_kRmabUrlKey, saved);
    if (!mounted) return;
    setState(() => _rmabUrl = saved);
    _msg(l.adminRmabSaved);
  }

  Future<void> _clearRmab() async {
    final l = AppLocalizations.of(context)!;
    await ScopedPrefs.remove(_kRmabUrlKey);
    if (!mounted) return;
    setState(() => _rmabUrl = null);
    _msg(l.adminRmabRemoved);
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
    final isScanning = _scanningLibraries.contains(id);
    final isMatching = _matchingLibraries.contains(id);

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
        ])));
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
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() => _scanningLibraries.remove(id));
      _msg(ok ? l.adminScanStarted(name) : l.adminScanFailed(name));
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
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      setState(() => _matchingLibraries.remove(id));
      _msg(ok ? l2.adminMatchingStarted(name) : l2.adminMatchFailed);
    }
  }

  Future<void> _createBackup() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _creatingBackup = true);
    final ok = await api.createBackup();
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() => _creatingBackup = false);
      _msg(ok ? l.adminBackupCreated : l.adminBackupFailed);
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
      _msg(ok ? l.adminCachePurged : l.adminPurgeCacheFailed);
    }
  }

  void _msg(String s) => ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
    SnackBar(content: Text(s), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  String _fmtB(int b) { if (b < 1024) return '$b B'; if (b < 1048576) return '${(b / 1024).toStringAsFixed(0)} KB';
    if (b < 1073741824) return '${(b / 1048576).toStringAsFixed(1)} MB'; return '${(b / 1073741824).toStringAsFixed(1)} GB'; }
  String _fmtD(double s) { final h = (s / 3600).floor(); if (h > 24) return '${(h / 24).floor()}d ${h % 24}h';
    final m = ((s % 3600) / 60).floor(); return h > 0 ? '${h}h ${m}m' : '${m}m'; }
}
