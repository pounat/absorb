import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/backup_service.dart';
import '../services/setup_link_service.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/absorb_wave_icon.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/setup_link_share_sheet.dart';
import '../l10n/app_localizations.dart';
import '../utils/duration_format.dart';
import '../utils/app_platform.dart';

class AdminUsersScreen extends StatefulWidget {
  final List<dynamic> users;
  final List<dynamic> onlineUsers;
  final List<dynamic> libraries;
  const AdminUsersScreen({super.key, required this.users, required this.onlineUsers, required this.libraries});
  @override State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late List<dynamic> _users;
  late List<dynamic> _onlineUsers;

  @override
  void initState() { super.initState(); _users = List.from(widget.users); _onlineUsers = List.from(widget.onlineUsers); }

  Future<void> _reload() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final results = await Future.wait([api.getUsers(), api.getOnlineUsers()]);
    if (mounted) setState(() { _users = results[0]; _onlineUsers = results[1]; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: cs.primary,
        onPressed: () => _showEditor(null),
        child: Icon(Icons.person_add_rounded, color: cs.onPrimary),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.adminUsers, padding: EdgeInsets.zero)),
              IconButton(icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: LayoutBuilder(builder: (ctx, constraints) {
                const gap = 10.0;
                final cellW = (constraints.maxWidth - 32 - gap * 2) / 3;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: _sortedUsers.map((u) => SizedBox(width: cellW, child: _userCell(cs, tt, u))).toList(),
                  ),
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }

  bool _isOnline(Map<String, dynamic> user) {
    final userId = user['id'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final socketOnline = _onlineUsers.any((o) {
      if (o is! Map) return false;
      final oId = o['id'] as String? ?? '';
      if (oId.isNotEmpty && oId == userId) return true;
      final oName = o['username'] as String? ?? '';
      return oName.isNotEmpty && oName == username;
    });
    if (socketOnline) return true;
    // The server only counts open socket connections, which mobile clients
    // drop in the background even while listening. Mirror the detail page's
    // 5-minute activity window so those users still show as online.
    final lastSeen = user['lastSeen'] as num?;
    return lastSeen != null &&
        DateTime.now().millisecondsSinceEpoch - lastSeen < 300000;
  }

  /// Online users first, then alphabetical so the green pills cluster at the top.
  List<Map<String, dynamic>> get _sortedUsers {
    final list = _users.whereType<Map<String, dynamic>>().toList();
    list.sort((a, b) {
      final ao = _isOnline(a), bo = _isOnline(b);
      if (ao != bo) return ao ? -1 : 1;
      final an = (a['username'] as String? ?? '').toLowerCase();
      final bn = (b['username'] as String? ?? '').toLowerCase();
      return an.compareTo(bn);
    });
    return list;
  }

  Widget _userCell(ColorScheme cs, TextTheme tt, Map<String, dynamic> user) {
    final l = AppLocalizations.of(context)!;
    final username = user['username'] as String? ?? l.unknown;
    final type = user['type'] as String? ?? 'user';
    final isActive = user['isActive'] as bool? ?? true;
    final isLocked = user['isLocked'] as bool? ?? false;
    final isOnline = _isOnline(user);
    final lastSeen = user['lastSeen'] as num?;

    const green = Color(0xFF4CAF50);
    final dotColor = type == 'root'
        ? Colors.amber
        : type == 'admin'
            ? cs.primary
            : isOnline
                ? green
                : null;
    final borderColor = isOnline ? green : cs.onSurface.withValues(alpha: 0.08);
    final textColor = isActive ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35);

    final String subtext;
    final Color subColor;
    if (!isActive) {
      subtext = l.disabled;
      subColor = Colors.red.withValues(alpha: 0.5);
    } else if (isOnline) {
      subtext = l.adminUsersOnlineNow;
      subColor = green.withValues(alpha: 0.85);
    } else if (lastSeen != null) {
      subtext = _timeAgo(DateTime.fromMillisecondsSinceEpoch(lastSeen.toInt()));
      subColor = cs.onSurface.withValues(alpha: 0.32);
    } else {
      subtext = l.adminUsersNever;
      subColor = cs.onSurface.withValues(alpha: 0.32);
    }

    return GestureDetector(
      onTap: () => _showUserDetail(user),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isOnline ? green.withValues(alpha: 0.08) : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isOnline ? 1.5 : 1),
          boxShadow: isOnline
              ? [BoxShadow(color: green.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: -2)]
              : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (dotColor != null) ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(username, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
                decoration: isActive ? null : TextDecoration.lineThrough,
                decorationColor: cs.onSurface.withValues(alpha: 0.35),
              ))),
            if (isLocked) ...[
              const SizedBox(width: 4),
              Icon(Icons.lock_rounded, size: 11, color: Colors.red.withValues(alpha: 0.6)),
            ],
          ]),
          const SizedBox(height: 3),
          Text(subtext, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(color: subColor, fontSize: 10)),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final l = AppLocalizations.of(context)!;
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return l.justNow;
    if (d.inMinutes < 60) return l.minutesAgo(d.inMinutes);
    if (d.inHours < 24) return l.hoursAgo(d.inHours);
    if (d.inDays < 30) return l.daysAgo(d.inDays);
    return l.adminUsersMonthsAgo((d.inDays / 30).floor());
  }

  void _showUserDetail(Map<String, dynamic> user) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _UserDetailScreen(user: user, libraries: widget.libraries, onChanged: _reload),
    ));
  }

  void _showEditor(Map<String, dynamic>? user) {
    showAdaptiveActionMenu(context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      desktopWidth: 560, desktopScrollWrap: false,
      builder: (_) => _UserEditorSheet(user: user, libraries: widget.libraries, onSaved: _reload));
  }
}

// ═══════════════════════════════════════════════════════════════
//  User Detail Screen
// ═══════════════════════════════════════════════════════════════

class _UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> libraries;
  final VoidCallback onChanged;
  const _UserDetailScreen({required this.user, required this.libraries, required this.onChanged});
  @override State<_UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<_UserDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _fullUser;
  List<Map<String, dynamic>> _progressItems = [];
  final Map<String, Map<String, dynamic>> _itemCache = {};
  List<dynamic> _sessions = [];
  bool _loadingSessions = false;
  bool _loadingMoreSessions = false;
  bool _sessionsExpanded = false;
  int _sessionsPage = 0;
  int _sessionsTotal = 0;
  static const _sessionsPerPage = 10;
  int _visibleCount = 25;
  bool _fetchingMore = false;

  static const _pageSize = 25;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() { _loading = true; _visibleCount = _pageSize; });

    final userId = widget.user['id'] as String? ?? '';
    final userData = await api.getUser(userId);

    if (userData != null) {
      _fullUser = userData;
      final progress = (userData['mediaProgress'] as List<dynamic>?) ?? [];

      final items = <Map<String, dynamic>>[];
      for (final p in progress) {
        if (p is Map<String, dynamic>) items.add(p);
      }

      // Sort: in-progress first (by last update), then finished
      items.sort((a, b) {
        final aFinished = a['isFinished'] as bool? ?? false;
        final bFinished = b['isFinished'] as bool? ?? false;
        if (aFinished != bFinished) return aFinished ? 1 : -1;
        final aTime = a['lastUpdate'] as num? ?? 0;
        final bTime = b['lastUpdate'] as num? ?? 0;
        return bTime.compareTo(aTime);
      });

      _progressItems = items;
      _itemCache.clear();

      // Only fetch item details for the first visible page
      await _fetchItemDetails(api, items.take(_pageSize).toList());
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchItemDetails(dynamic api, List<Map<String, dynamic>> items) async {
    final futures = <Future>[];
    for (final p in items) {
      final itemId = p['libraryItemId'] as String? ?? '';
      if (itemId.isNotEmpty && !_itemCache.containsKey(itemId)) {
        futures.add(
          api.getLibraryItem(itemId).then((item) {
            if (item != null) _itemCache[itemId] = item;
          }),
        );
      }
    }
    for (var i = 0; i < futures.length; i += 15) {
      await Future.wait(futures.skip(i).take(15));
    }
  }

  Future<void> _loadMore() async {
    if (_fetchingMore) return;
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _fetchingMore = true);
    final nextItems = _progressItems.skip(_visibleCount).take(_pageSize).toList();
    await _fetchItemDetails(api, nextItems);
    if (mounted) setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _progressItems.length);
      _fetchingMore = false;
    });
  }

  Future<void> _loadSessions() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final userId = widget.user['id'] as String? ?? '';
    if (userId.isEmpty) return;
    setState(() { _loadingSessions = true; _sessionsPage = 0; });
    final data = await api.getUserListeningSessions(userId, itemsPerPage: _sessionsPerPage);
    if (mounted) setState(() {
      _sessions = (data?['sessions'] as List<dynamic>?) ?? [];
      _sessionsTotal = (data?['total'] as num?)?.toInt() ?? _sessions.length;
      _loadingSessions = false;
    });
  }

  Future<void> _loadMoreSessions() async {
    if (_loadingMoreSessions) return;
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final userId = widget.user['id'] as String? ?? '';
    if (userId.isEmpty) return;
    setState(() => _loadingMoreSessions = true);
    final nextPage = _sessionsPage + 1;
    final data = await api.getUserListeningSessions(userId, page: nextPage, itemsPerPage: _sessionsPerPage);
    if (mounted) setState(() {
      final more = (data?['sessions'] as List<dynamic>?) ?? [];
      _sessions.addAll(more);
      _sessionsPage = nextPage;
      _sessionsTotal = (data?['total'] as num?)?.toInt() ?? _sessions.length;
      _loadingMoreSessions = false;
    });
  }

  String get _username => widget.user['username'] as String? ?? AppLocalizations.of(context)!.userFallback;
  String get _userType => widget.user['type'] as String? ?? 'user';
  bool get _isRoot => _userType == 'root';

  bool get _isOnline {
    if (_progressItems.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final p in _progressItems) {
      final lastUpdate = p['lastUpdate'] as num? ?? 0;
      if ((now - lastUpdate) < 300000) return true;
    }
    return false;
  }

  String get _lastSeenStr {
    num? mostRecent;
    for (final p in _progressItems) {
      final lu = p['lastUpdate'] as num? ?? 0;
      if (mostRecent == null || lu > mostRecent) mostRecent = lu;
    }
    // Fall back to user's lastSeen if no progress data
    final userLastSeen = (_fullUser ?? widget.user)['lastSeen'] as num?;
    final best = (mostRecent != null && (userLastSeen == null || mostRecent > userLastSeen))
        ? mostRecent : userLastSeen;
    if (best == null) return AppLocalizations.of(context)!.adminUsersNever;
    return _timeAgo(DateTime.fromMillisecondsSinceEpoch(best.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final finished = _progressItems.where((p) => p['isFinished'] == true).length;
    final inProgress = _progressItems.where((p) => (p['isFinished'] != true) && (p['progress'] as num? ?? 0) > 0).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: _username, padding: EdgeInsets.zero)),
              if (!_isRoot)
                IconButton(
                  icon: Icon(Icons.ios_share_rounded, color: cs.primary.withValues(alpha: 0.7), size: 20),
                  tooltip: l.adminCreateSetupFile,
                  onPressed: _exportSetupFile,
                ),
              if (!_isRoot)
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: cs.primary.withValues(alpha: 0.7), size: 20),
                  tooltip: l.adminUsersEditUserTooltip,
                  onPressed: _showEditor,
                ),
              IconButton(icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          // Online / last seen
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 2, 20, 0),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isOnline ? const Color(0xFF4CAF50) : cs.onSurface.withValues(alpha: 0.24),
              )),
              const SizedBox(width: 8),
              Text(
                _isOnline ? l.adminUsersOnlineNow : l.adminUsersLastSeen(_lastSeenStr),
                style: tt.labelSmall?.copyWith(
                  color: _isOnline ? const Color(0xFF4CAF50).withValues(alpha: 0.8) : cs.onSurface.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _isRoot ? Colors.amber.withValues(alpha: 0.12) : cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(_userType, style: tt.labelSmall?.copyWith(
                  color: _isRoot ? Colors.amber : cs.primary, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                _summaryChip(cs, tt, '$inProgress', l.inProgress, cs.primary),
                const SizedBox(width: 10),
                _summaryChip(cs, tt, '$finished', l.finished, Colors.green),
                const SizedBox(width: 10),
                _summaryChip(cs, tt, '${_progressItems.length}', l.adminUsersTotal, cs.onSurfaceVariant),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _progressItems.isEmpty && _sessions.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 80),
                            Center(child: Icon(Icons.menu_book_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.08))),
                            const SizedBox(height: 12),
                            Center(child: Text(l.adminUsersNoReadingActivity, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.24)))),
                          ])
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 40),
                            children: [
                              // Recent Sessions
                              if (!_sessionsExpanded)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                  child: GestureDetector(
                                    onTap: () async {
                                      setState(() => _sessionsExpanded = true);
                                      await _loadSessions();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.history_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                                        const SizedBox(width: 8),
                                        Text(l.statsRecentSessions, style: tt.bodySmall?.copyWith(
                                          color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                                      ]),
                                    ),
                                  ),
                                )
                              else if (_loadingSessions)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.2)))),
                                )
                              else if (_sessions.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                                  child: Text(l.statsRecentSessions, style: tt.titleSmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                ),
                                ..._sessions.map((s) => _sessionTile(cs, tt, s)),
                                if (_sessions.length < _sessionsTotal)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                                    child: GestureDetector(
                                      onTap: _loadingMoreSessions ? null : _loadMoreSessions,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          if (_loadingMoreSessions)
                                            SizedBox(width: 12, height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.3)))
                                          else
                                            Icon(Icons.expand_more_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                                          const SizedBox(width: 6),
                                          Text(_loadingMoreSessions ? l.adminUsersLoadingDots : l.adminUsersLoadMoreSessions,
                                            style: tt.bodySmall?.copyWith(
                                              color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                                        ]),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                              ] else ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                                  child: Text(l.adminUsersNoRecentSessions, style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.24))),
                                ),
                              ],
                              // Progress items
                              if (_progressItems.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                                  child: Text(l.adminUsersLibraryProgress, style: tt.titleSmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                ),
                                ..._progressItems.take(_visibleCount).map((p) => _progressTile(cs, tt, p)),
                                if (_visibleCount < _progressItems.length)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                    child: GestureDetector(
                                      onTap: _fetchingMore ? null : _loadMore,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          if (_fetchingMore)
                                            SizedBox(width: 14, height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.3)))
                                          else
                                            Icon(Icons.expand_more_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                                          const SizedBox(width: 8),
                                          Text(
                                            _fetchingMore ? l.adminUsersLoadingDots : l.adminUsersLoadMoreRemaining(_progressItems.length - _visibleCount),
                                            style: tt.bodySmall?.copyWith(
                                              color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                                        ]),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _summaryChip(ColorScheme cs, TextTheme tt, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _progressTile(ColorScheme cs, TextTheme tt, Map<String, dynamic> progress) {
    final itemId = progress['libraryItemId'] as String? ?? '';
    final episodeId = progress['episodeId'] as String?;
    final isFinished = progress['isFinished'] as bool? ?? false;
    final progressVal = (progress['progress'] as num? ?? 0).toDouble();
    final percent = (progressVal * 100).round();
    final currentTime = progress['currentTime'] as num? ?? 0;
    final duration = progress['duration'] as num? ?? 0;
    final lastUpdate = progress['lastUpdate'] as num?;

    final item = _itemCache[itemId];
    final media = item?['media'] as Map<String, dynamic>?;
    final metadata = media?['metadata'] as Map<String, dynamic>?;
    final title = metadata?['title'] as String? ?? itemId;
    final author = metadata?['authorName'] as String? ?? metadata?['author'] as String? ?? '';

    String? episodeTitle;
    if (episodeId != null && media != null) {
      final episodes = media['episodes'] as List?;
      if (episodes != null) {
        final ep = episodes.cast<Map<String, dynamic>?>().firstWhere(
          (e) => e?['id'] == episodeId, orElse: () => null);
        episodeTitle = ep?['title'] as String?;
      }
    }

    final displayTitle = episodeTitle ?? title;
    final subtitle = episodeTitle != null ? title : author;

    final auth = context.read<AuthProvider>();
    final coverUrl = item != null ? '${auth.serverUrl}/api/items/$itemId/cover?token=${auth.token}' : null;

    final lastUpdateStr = lastUpdate != null
        ? _timeAgo(DateTime.fromMillisecondsSinceEpoch(lastUpdate.toInt()))
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: coverUrl != null
                ? Image.network(coverUrl, width: 44, height: 44, fit: BoxFit.cover,
                    headers: auth.apiService?.mediaHeaders ?? {},
                    errorBuilder: (_, __, ___) => _coverFallback(cs))
                : _coverFallback(cs),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displayTitle, style: tt.bodySmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(subtitle, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progressVal.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(
                      isFinished ? Colors.green : cs.primary.withValues(alpha: 0.8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(isFinished ? AppLocalizations.of(context)!.finished : '$percent%',
                style: tt.labelSmall?.copyWith(
                  color: isFinished ? Colors.green.withValues(alpha: 0.8) : cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600, fontSize: 10)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Text('${formatHm(currentTime.toDouble())} / ${formatHm(duration.toDouble())}',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.2), fontSize: 9)),
              if (lastUpdateStr.isNotEmpty) ...[
                const Spacer(),
                Text(lastUpdateStr, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.2), fontSize: 9)),
              ],
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _sessionTile(ColorScheme cs, TextTheme tt, dynamic s) {
    if (s is! Map<String, dynamic>) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final rawTitle = s['displayTitle'] as String?;
    final rawAuthor = s['displayAuthor'] as String?;
    final meta = s['mediaMetadata'] as Map<String, dynamic>?;
    final title = (rawTitle != null && !_looksLikeId(rawTitle))
        ? rawTitle : meta?['title'] as String? ?? l.unknown;
    final author = (rawAuthor != null && !_looksLikeId(rawAuthor))
        ? rawAuthor : meta?['authorName'] as String? ?? '';
    final duration = (s['timeListening'] as num?)?.toDouble() ?? 0;
    final updatedAt = s['updatedAt'] is num
        ? DateTime.fromMillisecondsSinceEpoch((s['updatedAt'] as num).toInt())
        : null;

    final deviceInfo = s['deviceInfo'] as Map<String, dynamic>? ?? {};
    final clientName = deviceInfo['clientName'] as String? ?? deviceInfo['deviceName'] as String? ?? '';
    final isAbsorb = clientName.toLowerCase().contains('absorb');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showSessionDetails(s),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: (isAbsorb ? Colors.tealAccent : cs.onSurfaceVariant).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isAbsorb
                  ? AbsorbWaveIcon(size: 16, color: Colors.tealAccent.withValues(alpha: 0.7))
                  : Icon(_clientIcon(clientName), size: 15, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 12)),
            if (author.isNotEmpty)
              Text(author, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 10)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatHm(duration), style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w600, fontSize: 11)),
            if (updatedAt != null)
              Text(_relativeDate(updatedAt), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.18), fontSize: 9)),
          ]),
        ]),
      ),
    )),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showAdaptiveActionMenu(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      desktopWidth: 560,
      desktopScrollWrap: false,
      builder: (_) => _AdminSessionDetailsSheet(session: session),
    );
  }

  static final _idPattern = RegExp(
    r'^([a-z]{2,4}_)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static bool _looksLikeId(String v) => _idPattern.hasMatch(v);

  IconData _clientIcon(String clientName) {
    final lower = clientName.toLowerCase();
    if (lower.contains('audiobookshelf') || lower.contains('abs')) return Icons.headphones_rounded;
    if (lower.contains('web') || lower.contains('browser')) return Icons.language_rounded;
    if (lower.contains('ios') || lower.contains('apple')) return Icons.phone_iphone_rounded;
    if (lower.contains('android')) return Icons.phone_android_rounded;
    if (lower.contains('sonos') || lower.contains('cast')) return Icons.speaker_rounded;
    return Icons.devices_rounded;
  }

  String _relativeDate(DateTime date) {
    final l = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.daysAgo(diff.inDays);
    return '${date.month}/${date.day}';
  }

  Widget _coverFallback(ColorScheme cs) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Icon(Icons.auto_stories_rounded, size: 18, color: cs.primary.withValues(alpha: 0.3)),
  );

  void _showEditor() {
    showAdaptiveActionMenu(context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      desktopWidth: 560, desktopScrollWrap: false,
      builder: (_) => _UserEditorSheet(user: widget.user, libraries: widget.libraries, onSaved: () {
        widget.onChanged();
        _load();
      }));
  }

  /// Mint an API key for this user and package it into a private sign-in link.
  Future<void> _exportSetupFile() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final userId = widget.user['id'] as String? ?? '';
    final username = widget.user['username'] as String? ?? '';
    if (userId.isEmpty) return;

    final l = AppLocalizations.of(context)!;
    final urlCtrl = TextEditingController(text: auth.serverUrl ?? '');
    final hasHeaders = auth.customHeaders.isNotEmpty;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l.adminCreateSetupFile),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.adminSetupFileDescription(username),
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 14),
            TextField(
              controller: urlCtrl,
              autocorrect: false,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l.adminSetupFileServerUrl, isDense: true),
            ),
            const SizedBox(height: 10),
            Text(
              hasHeaders ? l.adminSetupFileNoteWithHeaders : l.adminSetupFileNote,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.adminSetupFileCreate)),
          ],
        );
      },
    );

    if (proceed != true) return;
    final serverUrl = urlCtrl.text.trim();
    if (serverUrl.isEmpty) return;

    final key = await api.createApiKey(name: 'Absorb setup: $username', userId: userId);
    final token = key?['apiKey'] as String?;
    if (token == null || token.isEmpty) {
      if (mounted) {
        showOverlayToast(context, l.adminSetupFileKeyError,
            icon: Icons.error_outline_rounded);
      }
      return;
    }

    try {
      final payload = await BackupService.buildSetupFile(
        serverUrl: serverUrl,
        username: username,
        token: token,
        userId: userId,
        customHeaders: auth.customHeaders,
      );
      final setupLink = SetupLinkService.createLink(payload);
      if (!mounted) return;

      await showAdaptiveActionMenu<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: false,
        desktopWidth: 560,
        desktopScrollWrap: false,
        builder: (sheetContext) => SetupLinkShareSheet(
          username: username,
          setupLink: setupLink,
          onShare: () async {
            final box = sheetContext.findRenderObject() as RenderBox?;
            final origin = box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size;
            await Share.share(
              setupLink.toString(),
              subject: l.setupLinkShareSubject(username),
              sharePositionOrigin: origin,
            );
          },
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: setupLink.toString()));
            if (sheetContext.mounted) {
              showOverlayToast(sheetContext, l.setupLinkCopied,
                  icon: Icons.content_copy_rounded);
            }
          },
          onSaveFile: () => _saveSetupFile(payload, username),
        ),
      );
    } catch (e) {
      if (mounted) {
        showOverlayToast(context, l.adminSetupFileFailed(e.toString()),
            icon: Icons.error_outline_rounded);
      }
    }
  }

  Future<void> _saveSetupFile(Map<String, dynamic> payload, String username) async {
    final l = AppLocalizations.of(context)!;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final safeName = username.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));

    final result = await FilePicker.platform.saveFile(
      dialogTitle: l.adminSetupFileSaveTitle,
      fileName: 'absorb_setup_$safeName.absorb',
      type: FileType.any,
      bytes: bytes,
    );

    if (result == null) return;
    if (AppPlatform.isDesktop) {
      await File(result).writeAsString(jsonStr);
    }
    if (mounted) {
      showOverlayToast(context, l.adminSetupFileSaved(username),
          icon: Icons.check_circle_outline_rounded);
    }
  }

  String _timeAgo(DateTime dt) {
    final l = AppLocalizations.of(context)!;
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return l.justNow;
    if (d.inMinutes < 60) return l.minutesAgo(d.inMinutes);
    if (d.inHours < 24) return l.hoursAgo(d.inHours);
    if (d.inDays < 30) return l.daysAgo(d.inDays);
    return l.adminUsersMonthsAgo((d.inDays / 30).floor());
  }

}

// ═══════════════════════════════════════════════════════════════
//  User Editor Sheet
// ═══════════════════════════════════════════════════════════════

class _UserEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? user;
  final List<dynamic> libraries;
  final VoidCallback onSaved;
  const _UserEditorSheet({this.user, required this.libraries, required this.onSaved});
  @override State<_UserEditorSheet> createState() => _UserEditorSheetState();
}

class _UserEditorSheetState extends State<_UserEditorSheet> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late String _type;
  late bool _isActive, _isLocked;
  late bool _canDownload, _canUpdate, _canDelete, _canUpload, _accessExplicit, _accessAllLibraries;
  final Set<String> _selectedLibraries = {};
  bool _saving = false;
  bool _deleting = false;
  bool _unlinking = false;
  late bool _hasOpenIDLink;

  bool get _isNew => widget.user == null;
  bool get _isSelf => !_isNew && widget.user?['id'] == context.read<AuthProvider>().userId;
  bool get _canDeleteUser => !_isNew && !_isSelf && widget.user?['type'] != 'root';

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usernameCtrl.text = u?['username'] as String? ?? '';
    _type = u?['type'] as String? ?? 'user';
    _isActive = u?['isActive'] as bool? ?? true;
    _isLocked = u?['isLocked'] as bool? ?? false;
    final p = u?['permissions'] as Map<String, dynamic>? ?? {};
    _canDownload = p['download'] as bool? ?? true;
    _canUpdate = p['update'] as bool? ?? false;
    _canDelete = p['delete'] as bool? ?? false;
    _canUpload = p['upload'] as bool? ?? false;
    _accessExplicit = p['accessExplicitContent'] as bool? ?? true;
    _accessAllLibraries = p['accessAllLibraries'] as bool? ?? true;
    final accessible = (u?['librariesAccessible'] as List?)?.cast<String>() ?? [];
    _selectedLibraries.addAll(accessible);
    _hasOpenIDLink = u?['hasOpenIDLink'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).bottomSheetTheme.backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4,
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(children: [
            Expanded(child: Text(_isNew ? l.adminUsersNewUser : l.adminUsersEditUser, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface))),
            if (_canDeleteUser) IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 20),
              onPressed: _deleting ? null : _deleteUser),
          ])),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl(cs, tt, l.adminUsersUsername), const SizedBox(height: 6),
            TextField(controller: _usernameCtrl, enabled: _isNew, style: TextStyle(color: cs.onSurface),
              decoration: _deco(cs, l.adminUsersEnterUsername)),
            if (_isNew || !_isSelf) ...[
              const SizedBox(height: 16),
              _lbl(cs, tt, _isNew ? l.adminUsersPassword : l.adminUsersNewPassword), const SizedBox(height: 6),
              TextField(controller: _passwordCtrl, obscureText: true, style: TextStyle(color: cs.onSurface),
                decoration: _deco(cs, _isNew ? l.adminUsersEnterPassword : l.adminUsersLeaveBlankToKeep)),
              if (!_isNew) ...[
                const SizedBox(height: 6),
                Text(l.otherUserPasswordResetWarning, style: tt.bodySmall?.copyWith(color: cs.error)),
              ],
            ],
            const SizedBox(height: 20),
            _lbl(cs, tt, l.adminUsersAccountType), const SizedBox(height: 8),
            Row(children: [
              _chip(cs, tt, 'guest', Icons.person_outline_rounded, l.adminUsersTypeGuest), const SizedBox(width: 8),
              _chip(cs, tt, 'user', Icons.person_rounded, l.adminUsersTypeUser), const SizedBox(width: 8),
              _chip(cs, tt, 'admin', Icons.admin_panel_settings_rounded, l.adminUsersTypeAdmin),
            ]),
            const SizedBox(height: 20),
            _lbl(cs, tt, l.adminUsersStatus), const SizedBox(height: 4),
            _sw(cs, l.adminUsersAccountActive, _isActive, (v) => setState(() => _isActive = v), sub: l.adminUsersAccountActiveSub),
            _sw(cs, l.adminUsersLocked, _isLocked, (v) => setState(() => _isLocked = v), sub: l.adminUsersLockedSub),
            const SizedBox(height: 12),
            _lbl(cs, tt, l.adminUsersPermissions), const SizedBox(height: 4),
            _sw(cs, l.adminUsersPermDownload, _canDownload, (v) => setState(() => _canDownload = v)),
            _sw(cs, l.adminUsersPermUpdate, _canUpdate, (v) => setState(() => _canUpdate = v), sub: l.adminUsersPermUpdateSub),
            _sw(cs, l.adminUsersPermDelete, _canDelete, (v) => setState(() => _canDelete = v)),
            _sw(cs, l.adminUsersPermUpload, _canUpload, (v) => setState(() => _canUpload = v)),
            _sw(cs, l.adminUsersPermExplicit, _accessExplicit, (v) => setState(() => _accessExplicit = v)),
            const SizedBox(height: 12),
            _lbl(cs, tt, l.adminUsersLibraryAccess), const SizedBox(height: 4),
            _sw(cs, l.adminUsersAccessAllLibraries, _accessAllLibraries, (v) => setState(() => _accessAllLibraries = v)),
            if (!_accessAllLibraries) ...[
              const SizedBox(height: 8),
              ...widget.libraries.map((lib) {
                final id = lib['id'] as String? ?? '';
                final name = lib['name'] as String? ?? l.libraryFallback;
                final sel = _selectedLibraries.contains(id);
                return Padding(padding: const EdgeInsets.only(bottom: 4), child: GestureDetector(
                  onTap: () => setState(() { if (sel) _selectedLibraries.remove(id); else _selectedLibraries.add(id); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? cs.primary.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? cs.primary.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.06))),
                    child: Row(children: [
                      Icon(sel ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: sel ? cs.primary : cs.onSurface.withValues(alpha: 0.24)),
                      const SizedBox(width: 10),
                      Text(name, style: TextStyle(color: sel ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54), fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ]),
                  ),
                ));
              }),
            ],
            if (!_isNew && _hasOpenIDLink) ...[
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: _unlinking ? null : _unlinkOpenID,
                icon: _unlinking
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.error))
                  : Icon(Icons.link_off_rounded, size: 18, color: cs.error),
                label: Text(l.adminUsersUnlinkOpenId, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            ],
          ]))),
        Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 12),
          child: SizedBox(width: double.infinity, height: 48, child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: cs.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _saving
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
              : Text(_isNew ? l.adminUsersCreateUser : l.adminUsersSaveChanges, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onPrimary)),
          ))),
      ]));
  }

  Widget _lbl(ColorScheme cs, TextTheme tt, String t) => Text(t, style: tt.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w600));

  InputDecoration _deco(ColorScheme cs, String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.2)),
    filled: true, fillColor: cs.onSurface.withValues(alpha: 0.04),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5))),
    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.04))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12));

  Widget _chip(ColorScheme cs, TextTheme tt, String type, IconData ic, String label) {
    final on = _type == type;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _type = type),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: on ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? cs.primary.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.06))),
        child: Column(children: [
          Icon(ic, size: 20, color: on ? cs.primary : cs.onSurface.withValues(alpha: 0.3)), const SizedBox(height: 4),
          Text(label,
            style: tt.labelSmall?.copyWith(color: on ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.6), fontWeight: on ? FontWeight.w700 : FontWeight.w500, fontSize: 11)),
        ]))));
  }

  Widget _sw(ColorScheme cs, String l, bool v, ValueChanged<bool> cb, {String? sub}) => SwitchListTile(dense: true, contentPadding: EdgeInsets.zero,
    title: Text(l, style: TextStyle(color: cs.onSurface, fontSize: 14)),
    subtitle: sub != null ? Text(sub, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)) : null,
    value: v, onChanged: cb);

  Future<void> _save() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final l = AppLocalizations.of(context)!;
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) { _snk(l.adminUsersUsernameRequired, icon: Icons.error_outline_rounded); return; }
    if (_isNew && _passwordCtrl.text.isEmpty) { _snk(l.adminUsersPasswordRequired, icon: Icons.error_outline_rounded); return; }
    setState(() => _saving = true);
    final perms = {'download': _canDownload, 'update': _canUpdate, 'delete': _canDelete, 'upload': _canUpload,
      'accessExplicitContent': _accessExplicit, 'accessAllLibraries': _accessAllLibraries, 'accessAllTags': true};
    bool ok;
    if (_isNew) {
      final r = await api.createUser(username: username, password: _passwordCtrl.text, type: _type,
        permissions: perms, librariesAccessible: _accessAllLibraries ? [] : _selectedLibraries.toList(),
        isActive: _isActive);
      ok = r != null;
    } else {
      final up = <String, dynamic>{'type': _type, 'isActive': _isActive, 'isLocked': _isLocked,
        'permissions': perms, 'librariesAccessible': _accessAllLibraries ? [] : _selectedLibraries.toList()};
      if (!_isSelf && _passwordCtrl.text.isNotEmpty) up['password'] = _passwordCtrl.text;
      ok = await api.updateUser(widget.user!['id'] as String, up);
    }
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      setState(() => _saving = false);
      if (ok) { widget.onSaved(); _snk(_isNew ? l2.adminUsersUserCreated : l2.adminUsersUserUpdated, icon: Icons.check_circle_outline_rounded); Navigator.pop(context); }
      else { _snk(_isNew ? l2.adminUsersFailedCreate : l2.adminUsersFailedUpdate, icon: Icons.error_outline_rounded); }
    }
  }

  Future<void> _deleteUser() async {
    if (!_canDeleteUser) return;
    final l = AppLocalizations.of(context)!;
    final name = widget.user?['username'] ?? l.adminUsersThisUser;
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.adminUsersDeleteUserTitle),
      content: Text(l.adminUsersDeleteUserContent(name)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete, style: TextStyle(color: Colors.red.shade300)))],
    ));
    if (yes != true) return;
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _deleting = true);
    final ok = await api.deleteUser(widget.user!['id'] as String);
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      setState(() => _deleting = false);
      if (ok) { widget.onSaved(); _snk(l2.adminUsersUserDeleted(name), icon: Icons.delete_outline_rounded); Navigator.pop(context); }
      else { _snk(l2.adminUsersFailedDelete, icon: Icons.error_outline_rounded); }
    }
  }

  Future<void> _unlinkOpenID() async {
    final l = AppLocalizations.of(context)!;
    final name = widget.user?['username'] as String? ?? l.adminUsersThisUser;
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.adminUsersUnlinkOpenIdTitle),
      content: Text(l.adminUsersUnlinkOpenIdContent(name)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.adminUsersUnlinkOpenId, style: TextStyle(color: Colors.red.shade300)))],
    ));
    if (yes != true) return;
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _unlinking = true);
    final ok = await api.unlinkOpenID(widget.user!['id'] as String);
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      setState(() { _unlinking = false; if (ok) _hasOpenIDLink = false; });
      if (ok) { widget.onSaved(); _snk(l2.adminUsersOpenIdUnlinked, icon: Icons.link_off_rounded); }
      else { _snk(l2.adminUsersFailedUnlinkOpenId, icon: Icons.error_outline_rounded); }
    }
  }

  void _snk(String s, {IconData? icon}) =>
      showOverlayToast(context, s, icon: icon);
}

// ═══════════════════════════════════════════════════════════════
//  Admin Session Details Sheet
// ═══════════════════════════════════════════════════════════════

class _AdminSessionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> session;
  const _AdminSessionDetailsSheet({required this.session});

  static double _n(dynamic v) => v is num ? v.toDouble() : 0;

  String _fmtPos(double seconds) {
    final s = seconds.round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _fmtDuration(double seconds) {
    if (seconds >= 60) return formatHm(seconds);
    if (seconds > 0) return '<1m';
    return '0m';
  }

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final hour12 = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} at $hour12:$min $ampm';
  }

  String _playMethodLabel(dynamic m, AppLocalizations l) {
    final i = m is num ? m.toInt() : -1;
    switch (i) {
      case 0: return l.adminUsersPlayDirect;
      case 1: return l.adminUsersPlayDirectStream;
      case 2: return l.adminUsersPlayTranscode;
      case 3: return l.adminUsersPlayLocal;
      default: return m.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final desktopMode = ModalSurface.isDesktopOf(context);
    final s = session;

    final meta = s['mediaMetadata'] as Map<String, dynamic>? ?? {};
    final rawTitle = s['displayTitle'] as String?;
    final rawAuthor = s['displayAuthor'] as String?;
    final idPattern = RegExp(
      r'^([a-z]{2,4}_)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    bool looksLikeId(String v) => idPattern.hasMatch(v);
    final title = (rawTitle != null && !looksLikeId(rawTitle))
        ? rawTitle
        : meta['title'] as String? ?? l.unknown;
    final author = (rawAuthor != null && !looksLikeId(rawAuthor))
        ? rawAuthor
        : meta['authorName'] as String? ?? '';
    final narrator = meta['narratorName'] as String? ?? '';
    final subtitle = meta['subtitle'] as String? ?? '';

    final itemId = s['libraryItemId'] as String?;
    final timeListening = _n(s['timeListening']);
    final startTime = _n(s['startTime']);
    final currentTime = _n(s['currentTime']);
    final totalDuration = _n(s['duration']);

    final deviceInfo = s['deviceInfo'] as Map<String, dynamic>? ?? {};
    final clientName = deviceInfo['clientName'] as String? ?? '';
    final clientVersion = deviceInfo['clientVersion'] as String? ?? '';
    final deviceModel = deviceInfo['model'] as String? ??
        deviceInfo['manufacturer'] as String? ??
        deviceInfo['deviceName'] as String? ??
        '';
    final osName = deviceInfo['osName'] as String? ?? '';
    final osVersion = deviceInfo['osVersion'] as String? ?? '';
    final playMethod = s['playMethod'];
    final startedAt = s['startedAt'];
    final updatedAt = s['updatedAt'];

    final lib = context.read<LibraryProvider>();
    final coverUrl = itemId != null ? lib.getCoverUrl(itemId) : null;

    return AdaptiveDraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: desktopMode
                ? BorderRadius.zero
                : const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            if (desktopMode)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 88,
                        height: 88,
                        color: cs.onSurface.withValues(alpha: 0.06),
                        child: coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: coverUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(
                                    Icons.menu_book_rounded,
                                    color: cs.onSurface.withValues(alpha: 0.3)),
                              )
                            : Icon(Icons.menu_book_rounded,
                                color: cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface)),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.7))),
                          ],
                          if (author.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(l.adminUsersByAuthor(author),
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.6))),
                          ],
                          if (narrator.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(l.narratedBy(narrator),
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.5))),
                          ],
                        ])),
                  ]),
                  const SizedBox(height: 20),
                  _infoRow(cs, tt, l.adminUsersListened, _fmtDuration(timeListening)),
                  _infoRow(cs, tt, l.adminUsersStartedAtPosition, _fmtPos(startTime)),
                  _infoRow(cs, tt, l.adminUsersEndedAtPosition, _fmtPos(currentTime)),
                  if (totalDuration > 0)
                    _infoRow(cs, tt, l.adminUsersTotalDuration, _fmtPos(totalDuration)),
                  const SizedBox(height: 16),
                  if (startedAt is num)
                    _infoRow(cs, tt, l.adminUsersStarted, _fmtDate(startedAt.toInt())),
                  if (updatedAt is num)
                    _infoRow(cs, tt, l.adminUsersUpdated, _fmtDate(updatedAt.toInt())),
                  const SizedBox(height: 16),
                  if (clientName.isNotEmpty)
                    _infoRow(
                        cs,
                        tt,
                        l.adminUsersClient,
                        clientVersion.isNotEmpty
                            ? '$clientName $clientVersion'
                            : clientName),
                  if (deviceModel.isNotEmpty)
                    _infoRow(cs, tt, l.adminUsersDevice, deviceModel),
                  if (osName.isNotEmpty)
                    _infoRow(
                        cs,
                        tt,
                        l.adminUsersOs,
                        osVersion.isNotEmpty
                            ? '$osName $osVersion'
                            : osName),
                  if (playMethod != null)
                    _infoRow(cs, tt, l.adminUsersPlayMethod, _playMethodLabel(playMethod, l)),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _infoRow(ColorScheme cs, TextTheme tt, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55)))),
        Text(value,
            style: tt.bodyMedium?.copyWith(
                color: cs.onSurface, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
