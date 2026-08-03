import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/auth_session.dart';
import '../providers/auth_provider.dart';
import '../widgets/desktop_page_body.dart';
import '../widgets/overlay_toast.dart';

class AuthSessionsScreen extends StatefulWidget {
  const AuthSessionsScreen({super.key});

  @override
  State<AuthSessionsScreen> createState() => _AuthSessionsScreenState();
}

class _AuthSessionsScreenState extends State<AuthSessionsScreen> {
  final _sessions = <AuthSession>[];
  bool _loading = true;
  bool _loadingMore = false;
  AuthSessionsStatus _status = AuthSessionsStatus.supported;
  int _page = 0;
  int _numPages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    if (more) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    final requestedPage = more ? _page + 1 : 0;
    final result = await api.getAuthSessions(page: requestedPage);
    if (!mounted) return;
    setState(() {
      _status = result.status;
      if (result.page != null) {
        if (!more) _sessions.clear();
        _sessions.addAll(result.page!.sessions);
        _page = result.page!.page;
        _numPages = result.page!.numPages;
      }
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _remove(AuthSession session) async {
    if (session.current) return;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.sessionsRemoveTitle),
        content: Text(l.sessionsRemoveContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.sessionsRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final api = context.read<AuthProvider>().apiService;
    final ok = await api?.deleteAuthSession(session) ?? false;
    if (!mounted) return;
    if (ok) {
      setState(() => _sessions.removeWhere((item) => item.id == session.id));
      showOverlayToast(
        context,
        l.sessionsRemoved,
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      showOverlayToast(
        context,
        l.sessionsRemoveFailed,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _signOutAll() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.sessionsSignOutAllTitle),
        content: Text(l.sessionsSignOutAllContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.sessionsSignOutAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout(
      keepServer: true,
      revokeServerSession: true,
      allDevices: true,
    );
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final api = auth.apiService;
    return Scaffold(
      appBar: AppBar(title: Text(l.manageSessionsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DesktopPageBody(
              maxWidth: 720,
              child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (api?.isLegacyToken == true)
                    _NoticeCard(
                      icon: Icons.info_outline_rounded,
                      text: l.sessionsLegacyNotice,
                    ),
                  if (_status == AuthSessionsStatus.unsupported)
                    _NoticeCard(
                      icon: Icons.update_rounded,
                      text: l.sessionsUnsupported,
                    )
                  else if (_status == AuthSessionsStatus.failed)
                    _NoticeCard(
                      icon: Icons.error_outline_rounded,
                      text: l.sessionsLoadFailed,
                    )
                  else if (_sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text(l.sessionsNone)),
                    )
                  else
                    ..._sessions.map(
                      (session) => Card(
                        child: AuthSessionTile(
                          session: session,
                          currentLabel: l.sessionsCurrent,
                          unknownDeviceLabel: l.sessionsUnknownDevice,
                          lastActiveLabel: session.updatedAt == null
                              ? null
                              : l.sessionsLastActive(
                                  DateFormat.yMMMd().add_jm().format(
                                    session.updatedAt!.toLocal(),
                                  ),
                                ),
                          removeTooltip: l.sessionsRemove,
                          onRemove: session.current
                              ? null
                              : () => _remove(session),
                        ),
                      ),
                    ),
                  if (_page + 1 < _numPages)
                    TextButton(
                      onPressed: _loadingMore ? null : () => _load(more: true),
                      child: _loadingMore
                          ? const CircularProgressIndicator()
                          : Text(l.sessionsLoadMore),
                    ),
                  if (api?.hasRefreshToken == true &&
                      _status == AuthSessionsStatus.supported) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _signOutAll,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l.sessionsSignOutAll),
                    ),
                  ],
                ],
              ),
              ),
            ),
    );
  }
}

class AuthSessionTile extends StatelessWidget {
  final AuthSession session;
  final String currentLabel;
  final String unknownDeviceLabel;
  final String? lastActiveLabel;
  final String removeTooltip;
  final VoidCallback? onRemove;

  const AuthSessionTile({
    super.key,
    required this.session,
    required this.currentLabel,
    required this.unknownDeviceLabel,
    required this.lastActiveLabel,
    required this.removeTooltip,
    this.onRemove,
  });

  String _title() {
    final userAgent = session.userAgent ?? '';
    if (userAgent.startsWith('AbsorbWear/')) return 'AbsorbWear';
    if (userAgent.startsWith('Absorb/')) return 'Absorb';
    return session.deviceInfo?.deviceLabel ??
        session.deviceInfo?.browserName ??
        unknownDeviceLabel;
  }

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (session.deviceInfo?.softwareLabel != null)
        session.deviceInfo!.softwareLabel!,
      if (session.ipAddress?.isNotEmpty == true) session.ipAddress!,
      if (lastActiveLabel != null) lastActiveLabel!,
    ];
    return ListTile(
      leading: Icon(
        session.current ? Icons.smartphone_rounded : Icons.devices_rounded,
      ),
      title: Row(
        children: [
          Flexible(child: Text(_title())),
          if (session.current) ...[
            const SizedBox(width: 8),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(currentLabel),
            ),
          ],
        ],
      ),
      subtitle: details.isEmpty ? null : Text(details.join('\n')),
      isThreeLine: details.length > 1,
      trailing: onRemove == null
          ? null
          : IconButton(
              key: Key('removeSession-${session.id}'),
              tooltip: removeTooltip,
              onPressed: onRemove,
              icon: const Icon(Icons.logout_rounded),
            ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NoticeCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
