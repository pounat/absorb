import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/bookorbit_admin.dart';
import '../services/bookorbit_email.dart';
import '../utils/file_size.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';
import 'bookorbit_admin_screen.dart';
import 'bookorbit_email_editors.dart';
import 'server_notifications_screen.dart';

enum BoEmailTab { devices, servers, templates, history }

/// What a BookOrbit user has set up for sending books by email.
class BoEmailSetup {
  final List<BoMailServer> servers;
  final List<BoEmailDevice> devices;
  final List<BoEmailGroup> groups;
  final List<BoEmailTemplate> templates;
  final BoEmailDefaults defaults;
  final bool readAlongChoice;

  const BoEmailSetup({
    this.servers = const [],
    this.devices = const [],
    this.groups = const [],
    this.templates = const [],
    this.defaults = const BoEmailDefaults(),
    this.readAlongChoice = false,
  });

  /// Someone who only manages mail servers can't read the rest.
  static Future<BoEmailSetup> load(BookOrbitApiService api, {required bool canSend}) async {
    if (!canSend) return BoEmailSetup(servers: await api.emailServers());
    final r = await Future.wait<Object>([
      api.emailServers(),
      api.emailDevices(),
      api.emailGroups(),
      api.emailTemplates(),
      api.emailDefaults(),
      api.emailReadAlongChoice(),
    ]);
    return BoEmailSetup(
      servers: r[0] as List<BoMailServer>,
      devices: r[1] as List<BoEmailDevice>,
      groups: r[2] as List<BoEmailGroup>,
      templates: r[3] as List<BoEmailTemplate>,
      defaults: r[4] as BoEmailDefaults,
      readAlongChoice: r[5] as bool,
    );
  }

  /// The server a send goes through when none is picked.
  BoMailServer? get defaultServer {
    for (final s in servers) {
      if (s.id == defaults.serverId) return s;
    }
    for (final s in servers) {
      if (s.isShared && s.isDefault) return s;
    }
    return servers.isEmpty ? null : servers.first;
  }

  BoEmailTemplate? get defaultTemplate {
    for (final t in templates) {
      if (t.id == defaults.templateId) return t;
    }
    for (final t in templates) {
      if (t.isSystem) return t;
    }
    return templates.isEmpty ? null : templates.first;
  }
}

IconData boDeviceIcon(String? deviceType) => switch (deviceType) {
      'kindle' || 'kobo' => Icons.tablet_android_rounded,
      'other' => Icons.chrome_reader_mode_rounded,
      _ => Icons.person_rounded,
    };

String boDeviceLabel(AppLocalizations l, String? deviceType) => switch (deviceType) {
      'kindle' => l.boEmailDeviceKindle,
      'kobo' => l.boEmailDeviceKobo,
      'other' => l.boEmailDeviceOther,
      _ => l.boEmailDeviceNone,
    };

/// Shows why an email request failed, naming the refusals BookOrbit only gives
/// a code for.
void showBoEmailError(BuildContext context, Object error) {
  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  final code = error is BookOrbitAdminError ? error.code : null;
  final message = switch (code) {
    'KINDLE_ORIGINAL_UNAVAILABLE' => l.boEmailKindleOriginal,
    'DELIVERY_ARTIFACT_UNAVAILABLE' || 'DELIVERY_PREPARATION_FAILED' => l.boEmailNoCopy,
    _ => null,
  };
  if (message == null) {
    showBoAdminError(context, error);
  } else {
    showOverlayToast(context, message, icon: Icons.error_outline_rounded);
  }
}

/// Sending books by email on BookOrbit: the devices books go to, the mail
/// servers they go through, the message that goes with them and what was sent.
class BookOrbitEmailScreen extends StatefulWidget {
  final BoEmailTab? initialTab;
  const BookOrbitEmailScreen({super.key, this.initialTab});

  @override
  State<BookOrbitEmailScreen> createState() => _BookOrbitEmailScreenState();
}

class _BookOrbitEmailScreenState extends State<BookOrbitEmailScreen> with SingleTickerProviderStateMixin {
  late final List<BoEmailTab> _tabs;
  late final TabController _tabController;
  BoEmailSetup _setup = const BoEmailSetup();
  bool _loading = true;

  List<BoEmailSend> _history = const [];
  bool _historyLoaded = false;
  bool _historyLoading = false;
  bool _historyMore = false;
  int _historyPage = 0;
  String? _historyStatus;
  bool _everyone = false;

  static const _pageSize = 30;

  BookOrbitAdminAccess? get _access => context.read<AuthProvider>().bookOrbitAdmin;

  @override
  void initState() {
    super.initState();
    _tabs = _access?.emailSend == true ? BoEmailTab.values : const [BoEmailTab.servers];
    final initial = _tabs.indexOf(widget.initialTab ?? _tabs.first);
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initial < 0 ? 0 : initial);
    _tabController.addListener(_tabChanged);
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tabChanged();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _tabChanged() {
    if (_tabs[_tabController.index] == BoEmailTab.history && !_historyLoaded && !_historyLoading) {
      _loadHistory(reset: true);
    }
  }

  Future<void> _load() async {
    final api = boAdminApi(context);
    final access = _access;
    if (api == null || access == null) return;
    try {
      final setup = await BoEmailSetup.load(api, canSend: access.emailSend);
      if (mounted) setState(() => _setup = setup);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHistory({bool reset = false}) async {
    final api = boAdminApi(context);
    if (api == null || _historyLoading) return;
    final page = reset ? 0 : _historyPage;
    setState(() => _historyLoading = true);
    try {
      final rows = _everyone
          ? await api.emailEveryonesHistory(page: page, size: _pageSize)
          : await api.emailHistory(page: page, size: _pageSize, status: _historyStatus);
      if (!mounted) return;
      setState(() {
        _history = reset ? rows : [..._history, ...rows];
        _historyPage = page + 1;
        _historyMore = rows.length == _pageSize;
        _historyLoaded = true;
      });
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _open(Widget screen) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => screen));
    if (changed == true) await _load();
  }

  Future<void> _setDefault({int? serverId, int? deviceId, int? templateId}) async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final d = _setup.defaults;
      final defaults = serverId != null
          ? await api.emailSetDefaults(serverId: d.serverId == serverId ? null : serverId)
          : deviceId != null
              ? await api.emailSetDefaults(deviceId: d.deviceId == deviceId ? null : deviceId)
              : await api.emailSetDefaults(templateId: d.templateId == templateId ? null : templateId);
      if (!mounted) return;
      setState(() => _setup = BoEmailSetup(
            servers: _setup.servers,
            devices: _setup.devices,
            groups: _setup.groups,
            templates: _setup.templates,
            defaults: defaults,
            readAlongChoice: _setup.readAlongChoice,
          ));
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final canSend = _tabs.length > 1;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(children: [
        Expanded(
          child: AbsorbPageHeader(
            title: canSend ? l.boEmailTitle : l.boEmailTabServers,
            padding: EdgeInsets.zero,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
      ]),
    );

    Widget body(BoEmailTab tab) => switch (tab) {
          BoEmailTab.devices => _devicesTab(),
          BoEmailTab.servers => _serversTab(),
          BoEmailTab.templates => _templatesTab(),
          BoEmailTab.history => _historyTab(),
        };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          header,
          if (canSend) TabBar(controller: _tabController, tabs: [for (final t in _tabs) Tab(text: _tabLabel(l, t))]),
          if (_loading) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
          Expanded(
            child: TabBarView(controller: _tabController, children: [for (final t in _tabs) body(t)]),
          ),
        ]),
      ),
    );
  }

  String _tabLabel(AppLocalizations l, BoEmailTab t) => switch (t) {
        BoEmailTab.devices => l.boEmailTabDevices,
        BoEmailTab.servers => l.boEmailTabServers,
        BoEmailTab.templates => l.boEmailTabTemplates,
        BoEmailTab.history => l.boEmailTabHistory,
      };

  Widget _list(List<Widget> children, {Future<void> Function()? onRefresh}) => RefreshIndicator(
        onRefresh: onRefresh ?? _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: children,
        ),
      );

  Widget _devicesTab() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final s = _setup;
    return _list([
      BoEmailSection(title: l.boEmailTabDevices, children: [
        if (s.devices.isEmpty && !_loading) BoEmailEmpty(l.boEmailDevicesEmpty),
        for (final d in s.devices)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(boDeviceIcon(d.deviceType), color: cs.primary),
            title: Text(d.name, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.email, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              Text(
                [
                  boDeviceLabel(l, d.deviceType),
                  if (d.preferredFormat != null) d.preferredFormat!.toUpperCase(),
                ].join(' · '),
                style: tt.labelSmall?.copyWith(color: cs.primary),
              ),
              if (d.lastSend?.status == 'failed')
                Text(l.boEmailLastSendFailed, style: tt.labelSmall?.copyWith(color: cs.error)),
            ]),
            trailing: _star(s.defaults.deviceId == d.id, () => _setDefault(deviceId: d.id)),
            onTap: () => _open(BoEmailDeviceScreen(device: d, setup: s)),
          ),
        BoEmailAddButton(label: l.boEmailAddDevice, onPressed: () => _open(BoEmailDeviceScreen(setup: s))),
      ]),
      BoEmailSection(title: l.boEmailGroups, hint: l.boEmailGroupsHint, children: [
        for (final g in s.groups)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(Icons.groups_rounded, color: cs.primary),
            title: Text(g.name, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(l.boEmailGroupMemberCount(g.members.length),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            onTap: () => _open(BoEmailGroupScreen(group: g, setup: s)),
          ),
        BoEmailAddButton(label: l.boEmailNewGroup, onPressed: () => _open(BoEmailGroupScreen(setup: s))),
      ]),
    ]);
  }

  Widget _serversTab() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final access = _access;
    final manage = access?.manageEmail == true;
    final canSend = access?.emailSend == true;
    final me = access?.userId ?? '';
    final s = _setup;
    final def = canSend ? s.defaultServer : null;
    return _list([
      BoEmailSection(children: [
        if (s.servers.isEmpty && !_loading)
          BoEmailEmpty(manage ? l.boEmailServersEmptyManage : l.boEmailServersEmpty),
        for (final server in s.servers)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(Icons.dns_rounded, color: cs.primary),
            title: Text(server.name, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${server.host}:${server.port}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              if (server.sender != null)
                Text(server.sender!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (def?.id == server.id) BoEmailBadge(l.boEmailBadgeDefault),
                if (server.isShared) BoEmailBadge(l.boEmailBadgeShared),
                if (server.isSystem) BoEmailBadge(l.boEmailBadgeSystem),
                if (server.lastTestOk == true) BoEmailBadge(l.boEmailServerTestOk, color: Colors.green),
                if (server.lastTestOk == false)
                  BoEmailBadge(l.boEmailServerTestFailed(server.lastTestError ?? ''), color: cs.error),
              ]),
            ]),
            trailing: canSend ? _star(s.defaults.serverId == server.id, () => _setDefault(serverId: server.id)) : null,
            onTap: () {
              if (manage && server.ownedBy(me)) {
                _open(BoEmailServerScreen(server: server, setup: s));
              } else {
                showOverlayToast(context, l.boEmailServerNotYours, icon: Icons.info_outline_rounded);
              }
            },
          ),
        if (manage) BoEmailAddButton(label: l.boEmailAddServer, onPressed: () => _open(BoEmailServerScreen(setup: s))),
      ]),
    ]);
  }

  Widget _templatesTab() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final s = _setup;
    final def = s.defaultTemplate;
    return _list([
      BoEmailSection(children: [
        if (s.templates.isEmpty && !_loading) BoEmailEmpty(l.boEmailTemplatesEmpty),
        for (final t in s.templates)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(Icons.article_outlined, color: cs.primary),
            title: Text(t.name, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.subject, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              if (t.isSystem || def?.id == t.id) ...[
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: [
                  if (def?.id == t.id) BoEmailBadge(l.boEmailBadgeDefault),
                  if (t.isSystem) BoEmailBadge(l.boEmailBadgeBuiltIn),
                ]),
              ],
            ]),
            trailing: _star(s.defaults.templateId == t.id, () => _setDefault(templateId: t.id)),
            onTap: () => _open(BoEmailTemplateScreen(template: t, setup: s)),
          ),
        BoEmailAddButton(
          label: l.boEmailNewTemplate,
          onPressed: () => _open(BoEmailTemplateScreen(setup: s)),
        ),
      ]),
    ]);
  }

  Widget _historyTab() {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final superuser = _access?.isSuperuser == true;
    void filter(String? status, {bool everyone = false}) {
      setState(() {
        _historyStatus = status;
        _everyone = everyone;
      });
      _loadHistory(reset: true);
    }

    return _list(onRefresh: () => _loadHistory(reset: true), [
      Wrap(spacing: 8, runSpacing: 4, children: [
        ChoiceChip(
          label: Text(l.boEmailHistoryAll),
          selected: !_everyone && _historyStatus == null,
          onSelected: (_) => filter(null),
        ),
        ChoiceChip(
          label: Text(l.boEmailStatusFailed),
          selected: !_everyone && _historyStatus == 'failed',
          onSelected: (_) => filter('failed'),
        ),
        ChoiceChip(
          label: Text(l.boEmailStatusSending),
          selected: !_everyone && _historyStatus == 'pending',
          onSelected: (_) => filter('pending'),
        ),
        if (superuser)
          ChoiceChip(
            label: Text(l.boEmailHistoryEveryone),
            selected: _everyone,
            onSelected: (_) => filter(null, everyone: true),
          ),
      ]),
      const SizedBox(height: 8),
      if (_historyLoaded && _history.isEmpty) BoEmailEmpty(l.boEmailHistoryEmpty),
      for (final e in _history) _historyTile(e),
      if (_historyLoading)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
        )
      else if (_historyMore)
        Center(
          child: TextButton(
            onPressed: () => _loadHistory(),
            child: Text(l.boEmailLoadMore, style: TextStyle(color: cs.primary)),
          ),
        ),
    ]);
  }

  Widget _historyTile(BoEmailSend e) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final (icon, color, status) = switch (e.status) {
      'sent' => (Icons.check_circle_rounded, Colors.green, l.boEmailStatusSent),
      'failed' => (Icons.error_rounded, cs.error, l.boEmailStatusFailed),
      _ => (
          Icons.schedule_rounded,
          cs.primary,
          e.attempts > 1 ? l.boEmailStatusRetrying(e.attempts) : l.boEmailStatusSending,
        ),
    };
    final title = e.bookTitle ?? (_everyone ? e.subject : null) ?? l.boEmailUnknownBook;
    final file = [
      if (e.format != null) e.format!.toUpperCase(),
      if (e.size != null && e.size! > 0) formatFileSize(e.size!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Icon(icon, color: color),
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              [l.boEmailTo(e.toLabel), notificationTimeAgo(l, e.sentAt ?? e.createdAt, locale)]
                  .where((p) => p.isNotEmpty)
                  .join(' · '),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text([status, if (file.isNotEmpty) file].join(' · '), style: tt.labelSmall?.copyWith(color: color)),
            if (e.failed && e.error != null)
              Text(e.error!, maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.error)),
          ]),
          onTap: _everyone ? null : () => _historyActions(e),
        ),
      ),
    );
  }

  Future<void> _historyActions(BoEmailSend e) async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (e.bookId != null && !e.pending)
            ListTile(
              leading: const Icon(Icons.send_rounded),
              title: Text(l.boEmailResend),
              onTap: () => Navigator.pop(ctx, 'resend'),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: Text(l.boEmailForget),
            onTap: () => Navigator.pop(ctx, 'forget'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'resend') {
        await api.emailResend(e.id);
        if (mounted) showOverlayToast(context, l.boEmailResent, icon: Icons.send_rounded);
      } else {
        await api.emailForget(e.id);
      }
      await _loadHistory(reset: true);
    } catch (err) {
      if (mounted) showBoEmailError(context, err);
    }
  }

  Widget _star(bool on, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: AppLocalizations.of(context)!.boEmailMakeDefault,
      icon: Icon(on ? Icons.star_rounded : Icons.star_outline_rounded,
          color: on ? cs.primary : cs.onSurfaceVariant),
      onPressed: onTap,
    );
  }
}

class BoEmailSection extends StatelessWidget {
  final String? title;
  final String? hint;
  final List<Widget> children;

  const BoEmailSection({super.key, this.title, this.hint, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(title!, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: Text(hint!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          if (title != null || hint != null) const SizedBox(height: 6),
          ...children,
        ]),
      ),
    );
  }
}

class BoEmailBadge extends StatelessWidget {
  final String label;
  final Color? color;
  const BoEmailBadge(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w600)),
    );
  }
}

class BoEmailEmpty extends StatelessWidget {
  final String text;
  const BoEmailEmpty(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      );
}

class BoEmailAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const BoEmailAddButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
          label: Text(label),
        ),
      );
}
