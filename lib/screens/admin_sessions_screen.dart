import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/adaptive_modal.dart';
import 'stats_screen.dart' show SessionDetailsSheet;

/// Admin view of every user's listening sessions. View + delete any session;
/// editing is offered only on the admin's own sessions (see SessionDetailsSheet).
class AdminSessionsScreen extends StatefulWidget {
  final List<dynamic> users;
  const AdminSessionsScreen({super.key, required this.users});
  @override
  State<AdminSessionsScreen> createState() => _AdminSessionsScreenState();
}

class _AdminSessionsScreenState extends State<AdminSessionsScreen> {
  static const _perPage = 25;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _userFilter; // null = all users
  List<dynamic> _sessions = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) _loadMore();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final data = await api.getAllSessionsPaged(
        page: 0, itemsPerPage: _perPage, userId: _userFilter);
    if (!mounted) return;
    final fetched = data?['sessions'] as List<dynamic>? ?? [];
    setState(() {
      _sessions = fetched;
      _page = 0;
      _hasMore = fetched.length >= _perPage;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    final data = await api.getAllSessionsPaged(
        page: next, itemsPerPage: _perPage, userId: _userFilter);
    if (!mounted) return;
    final fetched = data?['sessions'] as List<dynamic>? ?? [];
    setState(() {
      if (fetched.isNotEmpty) {
        _sessions = [..._sessions, ...fetched];
        _page = next;
      }
      if (fetched.length < _perPage) _hasMore = false;
      _loadingMore = false;
    });
  }

  Future<void> _openSession(Map<String, dynamic> s) async {
    final myId = context.read<AuthProvider>().userId;
    final ownerId = s['userId'] as String? ??
        (s['user'] as Map<String, dynamic>?)?['id'] as String?;
    final changed = await showAdaptiveActionMenu<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      desktopWidth: 520,
      builder: (_) =>
          SessionDetailsSheet(session: s, allowEdit: ownerId == myId),
    );
    if (changed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(
                  child: AbsorbPageHeader(
                      title: l.adminAllSessions, padding: EdgeInsets.zero)),
              IconButton(
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          _userFilterBar(cs, tt, l),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _sessions.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                  child: Icon(Icons.history_rounded,
                                      size: 48,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.08))),
                              const SizedBox(height: 14),
                              Center(
                                  child: Text(l.adminSessionsEmpty,
                                      style: tt.bodyMedium?.copyWith(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.3),
                                          fontWeight: FontWeight.w600))),
                            ])
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _sessions.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i >= _sessions.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                      child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))),
                                );
                              }
                              final s = _sessions[i];
                              if (s is! Map<String, dynamic>) {
                                return const SizedBox.shrink();
                              }
                              return _sessionRow(cs, tt, l, s);
                            },
                          ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _userFilterBar(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [
        Icon(Icons.filter_list_rounded,
            size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _userFilter,
              borderRadius: BorderRadius.circular(12),
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              items: [
                DropdownMenuItem<String?>(
                    value: null, child: Text(l.adminSessionsAllUsers)),
                ...widget.users.map((u) {
                  final id = u is Map<String, dynamic> ? u['id'] as String? : null;
                  final name = u is Map<String, dynamic>
                      ? (u['username'] as String? ?? '')
                      : '';
                  return DropdownMenuItem<String?>(value: id, child: Text(name));
                }),
              ],
              onChanged: (v) {
                if (v == _userFilter) return;
                setState(() => _userFilter = v);
                _load();
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sessionRow(
      ColorScheme cs, TextTheme tt, AppLocalizations l, Map<String, dynamic> s) {
    final meta = s['mediaMetadata'] as Map<String, dynamic>? ?? {};
    final rawTitle = s['displayTitle'] as String?;
    final title = (rawTitle != null && rawTitle.isNotEmpty)
        ? rawTitle
        : meta['title'] as String? ?? l.unknown;
    final username = (s['user'] as Map<String, dynamic>?)?['username'] as String?;
    final duration = (s['timeListening'] is num)
        ? (s['timeListening'] as num).toDouble()
        : 0.0;
    final updatedAt = s['updatedAt'] is num
        ? DateTime.fromMillisecondsSinceEpoch((s['updatedAt'] as num).toInt())
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSession(s),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      if (username != null && username.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.person_rounded,
                              size: 12,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(username,
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12)),
                        ]),
                      ],
                    ]),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_fmtDuration(duration, l),
                    style: tt.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                if (updatedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(_relativeDate(updatedAt, l),
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 11)),
                ],
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  String _fmtDuration(double seconds, AppLocalizations l) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (h > 0) return l.statsScreenDurationHm(h, m);
    if (m > 0) return l.statsScreenDurationM(m);
    if (seconds > 0) return l.statsScreenDurationLessThanMin;
    return l.statsScreenDurationZero;
  }

  String _relativeDate(DateTime date, AppLocalizations l) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.daysAgo(diff.inDays);
    return '${date.month}/${date.day}';
  }
}
