import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/bookorbit_admin.dart';
import '../services/setup_link_service.dart';
import '../utils/share_origin.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/setup_link_share_sheet.dart';
import 'bookorbit_admin_screen.dart';

/// Everyone on the BookOrbit server, for people who manage users.
class BookOrbitUsersScreen extends StatefulWidget {
  const BookOrbitUsersScreen({super.key});

  @override
  State<BookOrbitUsersScreen> createState() => _BookOrbitUsersScreenState();
}

class _BookOrbitUsersScreenState extends State<BookOrbitUsersScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _searchDelay;
  BoUserFilter _filter = BoUserFilter.all;
  BoUserCounts _counts = const BoUserCounts();
  final List<BoUser> _users = [];
  int _total = 0;
  int _page = 0;
  bool _loading = false;
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _searchDelay?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final api = boAdminApi(context);
    if (api == null) return;
    final id = ++_loadId;
    setState(() {
      _loading = true;
      _page = 0;
    });
    try {
      final results = await Future.wait([
        api.adminUsers(search: _search.text, filter: _filter),
        api.adminUserCounts(),
      ]);
      if (!mounted || id != _loadId) return;
      final page = results[0] as BoUserPage;
      setState(() {
        _users
          ..clear()
          ..addAll(page.users);
        _total = page.total;
        _counts = results[1] as BoUserCounts;
      });
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted && id == _loadId) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _users.length >= _total) return;
    final api = boAdminApi(context);
    if (api == null) return;
    final id = _loadId;
    setState(() => _loading = true);
    try {
      final page = await api.adminUsers(page: _page + 1, search: _search.text, filter: _filter);
      if (!mounted || id != _loadId) return;
      setState(() {
        _page++;
        _users.addAll(page.users);
        _total = page.total;
      });
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted && id == _loadId) setState(() => _loading = false);
    }
  }

  void _searchChanged(String _) {
    _searchDelay?.cancel();
    _searchDelay = Timer(const Duration(milliseconds: 350), _reload);
  }

  Future<void> _open(BoUser user) async {
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => _BookOrbitUserScreen(user: user)));
    if (changed == true) _reload();
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const _BookOrbitNewUserScreen()));
    if (created == true) _reload();
  }

  String _filterLabel(AppLocalizations l, BoUserFilter f) => switch (f) {
        BoUserFilter.all => l.boUsersFilterAll,
        BoUserFilter.admins => l.boUsersFilterAdmins,
        BoUserFilter.active => l.boUsersFilterActive,
        BoUserFilter.inactive => l.boUsersFilterInactive,
        BoUserFilter.attention => l.boUsersFilterAttention,
      };

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
              Expanded(child: AbsorbPageHeader(title: l.boAdminUsers, padding: EdgeInsets.zero)),
              IconButton(
                icon: Icon(Icons.person_add_alt_1_rounded, color: cs.primary),
                tooltip: l.boUserNew,
                onPressed: _create,
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: _searchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.boUsersSearch,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final f in BoUserFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${_filterLabel(l, f)} ${_counts.of(f)}'),
                      selected: _filter == f,
                      onSelected: (_) {
                        if (_filter == f) return;
                        setState(() => _filter = f);
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: _users.isEmpty && !_loading
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(l.boUsersNone,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                      ),
                    ])
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _users.length,
                      itemBuilder: (context, i) => _UserTile(user: _users[i], onTap: () => _open(_users[i])),
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final BoUser user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final last = user.lastActive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(children: [
              _Avatar(name: user.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text('@${user.username}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (user.isSuperuser) _Badge(l.boUserBadgeAdmin, cs.primary),
                    if (!user.active) _Badge(l.boUserBadgeInactive, cs.onSurfaceVariant),
                    if (user.locked) _Badge(l.boUserBadgeLocked, cs.error),
                    if (user.isDefaultPassword) _Badge(l.boUserBadgeNoPassword, cs.tertiary),
                    Text(
                      last == null ? l.boUserNeverSignedIn : l.boUserLastActive(_date(l, last)),
                      style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ]),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }
}

String _date(AppLocalizations l, DateTime d) => l.backupDateFormat(d.month, d.day, d.year);

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 20,
      backgroundColor: cs.primaryContainer,
      child: Text(initial, style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// Grouped permission checkboxes with BookOrbit's presets on top.
class _PermissionPicker extends StatelessWidget {
  final Set<String> selected;
  final bool enabled;
  final ValueChanged<Set<String>> onChanged;

  const _PermissionPicker({required this.selected, required this.onChanged, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final all = boAllPermissions;
    Widget preset(String label, Set<String> perms) {
      final on = selected.length == perms.length && selected.containsAll(perms);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          onSelected: enabled ? (_) => onChanged({...perms}) : null,
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Wrap(children: [
          preset(l.boUserPresetNone, const {}),
          preset(l.boUserPresetStandard, boStandardPermissions),
          preset(l.boUserPresetEverything, all),
        ]),
      ),
      for (final group in boPermissionGroups) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 2),
          child: Text(boPermissionGroupLabel(l, group.key),
              style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
        ),
        for (final p in group.permissions)
          CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            value: selected.contains(p),
            title: Text(boPermissionLabel(l, p)),
            onChanged: enabled
                ? (v) => onChanged(v == true ? {...selected, p} : ({...selected}..remove(p)))
                : null,
          ),
      ],
    ]);
  }
}

class _LibraryPicker extends StatelessWidget {
  final List<BoLibrary> libraries;
  final Set<int> selected;
  final bool enabled;
  final ValueChanged<Set<int>> onChanged;

  const _LibraryPicker({
    required this.libraries,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final lib in libraries)
        CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          secondary: Icon(boLibraryIcon(lib.icon)),
          value: selected.contains(lib.id),
          title: Text(lib.name),
          onChanged: enabled
              ? (v) => onChanged(v == true ? {...selected, lib.id} : ({...selected}..remove(lib.id)))
              : null,
        ),
    ]);
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final String? hint;
  final List<Widget> children;

  const _Section({this.title, this.hint, required this.children});

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
          const SizedBox(height: 6),
          ...children,
        ]),
      ),
    );
  }
}

/// Shares a password link as an Absorb link and QR code, so [username] picks
/// their password in Absorb and is signed straight in. The server's own web
/// link stays a tap away.
Future<void> _showPasswordLink(BuildContext context, String username, String link) {
  final l = AppLocalizations.of(context)!;
  final auth = context.read<AuthProvider>();
  final parts = BookOrbitApiService.passwordLink(link);
  final serverUrl = auth.serverUrl;
  if (parts == null || serverUrl == null) return _showWebPasswordLink(context, username, link);
  final setupLink = SetupLinkService.createBookOrbitPasswordLink(
    serverUrl: serverUrl,
    username: username,
    token: parts.token,
    customHeaders: auth.customHeaders,
  );
  Future<void> copy(BuildContext sheetContext, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (sheetContext.mounted) {
      showOverlayToast(sheetContext, l.setupLinkCopied, icon: Icons.content_copy_rounded);
    }
  }

  return showAdaptiveActionMenu<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    desktopWidth: 560,
    desktopScrollWrap: false,
    builder: (sheetContext) => SetupLinkShareSheet(
      username: username,
      setupLink: setupLink,
      description: l.boPasswordShareDescription(username),
      warning: l.boPasswordShareWarning(username),
      onShare: () => Share.share(
        setupLink.toString(),
        subject: l.setupLinkShareSubject(username),
        sharePositionOrigin: shareOriginFor(sheetContext),
      ),
      onCopy: () => copy(sheetContext, setupLink.toString()),
      onCopyWebLink: () => copy(sheetContext, link),
    ),
  );
}

/// The plain web link, for a link Absorb can't read.
Future<void> _showWebPasswordLink(BuildContext context, String name, String link) {
  final l = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.boUserLinkTitle),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.boUserLinkBody(name)),
        const SizedBox(height: 12),
        SelectableText(link, style: Theme.of(ctx).textTheme.bodySmall),
      ]),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (ctx.mounted) {
              showOverlayToast(ctx, l.boUserLinkCopied, icon: Icons.check_circle_outline_rounded);
            }
          },
          child: Text(l.boUserLinkCopy),
        ),
        TextButton(onPressed: () => Share.share(link), child: Text(l.boUserLinkShare)),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l.done)),
      ],
    ),
  );
}

class _BookOrbitUserScreen extends StatefulWidget {
  final BoUser user;
  const _BookOrbitUserScreen({required this.user});

  @override
  State<_BookOrbitUserScreen> createState() => _BookOrbitUserScreenState();
}

class _BookOrbitUserScreenState extends State<_BookOrbitUserScreen> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _email = TextEditingController(text: widget.user.email ?? '');
  late bool _active = widget.user.active;
  late bool _superuser = widget.user.isSuperuser;
  late Set<String> _permissions = {...widget.user.permissions}..remove('*');
  Set<int> _libraries = {};
  Set<int> _savedLibraries = {};
  List<BoLibrary> _allLibraries = const [];
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;

  BoUser get _u => widget.user;

  @override
  void initState() {
    super.initState();
    _name.addListener(_touch);
    _email.addListener(_touch);
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _touch() => setState(() {});

  Future<void> _load() async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final libs = await api.adminLibraries();
      final mine = _u.isSuperuser ? <int>[] : await api.adminUserLibraries(_u.id);
      if (!mounted) return;
      setState(() {
        _allLibraries = libs;
        _libraries = {...mine};
        _savedLibraries = {...mine};
      });
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _dirty =>
      _name.text.trim() != _u.name ||
      _email.text.trim() != (_u.email ?? '') ||
      _active != _u.active ||
      _superuser != _u.isSuperuser ||
      !_samePerms ||
      !(_libraries.length == _savedLibraries.length && _libraries.containsAll(_savedLibraries));

  bool get _samePerms {
    final saved = {..._u.permissions}..remove('*');
    return saved.length == _permissions.length && saved.containsAll(_permissions);
  }

  Future<void> _save() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    final email = _email.text.trim();
    if (email.isNotEmpty && !_validEmail(email)) {
      showOverlayToast(context, l.boUserEmailInvalid, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      if (name != _u.name || email != (_u.email ?? '') || _active != _u.active) {
        await api.adminUpdateUser(
          _u.id,
          name: name != _u.name && name.isNotEmpty ? name : null,
          email: email != (_u.email ?? '') && email.isNotEmpty ? email : null,
          active: _active != _u.active ? _active : null,
        );
      }
      if (_superuser != _u.isSuperuser) await api.adminSetUserSuperuser(_u.id, _superuser);
      if (!_superuser) {
        if (!_samePerms || _superuser != _u.isSuperuser) await api.adminSetUserPermissions(_u.id, _permissions);
        if (!(_libraries.length == _savedLibraries.length && _libraries.containsAll(_savedLibraries)) ||
            _superuser != _u.isSuperuser) {
          await api.adminSetUserLibraries(_u.id, _libraries.toList());
        }
      }
      _changed = true;
      if (!mounted) return;
      showOverlayToast(context, l.boAdminSaved, icon: Icons.check_circle_outline_rounded);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendLink() async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final link = await api.adminResetPassword(_u.id);
      if (!mounted) return;
      if (link == null) {
        showBoAdminError(context, const BookOrbitAdminError(-1));
        return;
      }
      await _showPasswordLink(context, _u.username, link);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  Future<void> _unlock() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    try {
      await api.adminUnlockUser(_u.id);
      _changed = true;
      if (mounted) showOverlayToast(context, l.boUserUnlocked, icon: Icons.lock_open_rounded);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  Future<void> _delete() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.boUserDeleteTitle(_u.name)),
        content: Text(l.boUserDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await api.adminDeleteUser(_u.id);
      if (!mounted) return;
      showOverlayToast(context, l.boUserDeleted, icon: Icons.check_circle_outline_rounded);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final me = context.watch<AuthProvider>().bookOrbitAdmin;
    final self = me?.userId == '${_u.id}';
    final iAmSuperuser = me?.isSuperuser == true;
    // Only administrators may change administrators.
    final editable = iAmSuperuser || !_u.isSuperuser;

    // Back hands the list whether anything changed (an unlock saves at once).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context, _changed),
                ),
                const SizedBox(width: 4),
                _Avatar(name: _u.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_u.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('@${_u.username}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                ),
                if (editable)
                  FilledButton(
                    onPressed: _dirty && !_saving ? _save : null,
                    child: Text(l.save),
                  ),
                const SizedBox(width: 8),
              ]),
            ),
            if (_loading || _saving) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _Section(children: [
                    TextField(
                      controller: _name,
                      enabled: editable,
                      decoration: InputDecoration(labelText: l.boUserName),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _email,
                      enabled: editable,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l.boUserEmail),
                    ),
                    const SizedBox(height: 4),
                    if (!self)
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        title: Text(l.boUserActive),
                        subtitle: Text(l.boUserActiveSubtitle),
                        value: _active,
                        onChanged: editable ? (v) => setState(() => _active = v) : null,
                      ),
                    if (!self && iAmSuperuser)
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        title: Text(l.boUserAdmin),
                        subtitle: Text(l.boUserAdminSubtitle),
                        value: _superuser,
                        onChanged: (v) => setState(() => _superuser = v),
                      ),
                  ]),
                  if (_superuser)
                    _Section(title: l.boUserPermissions, hint: l.boUserAdminHasAll, children: const [])
                  else ...[
                    _Section(title: l.boUserPermissions, children: [
                      _PermissionPicker(
                        selected: _permissions,
                        enabled: editable && !self,
                        onChanged: (p) => setState(() => _permissions = p),
                      ),
                    ]),
                    if (_allLibraries.isNotEmpty)
                      _Section(title: l.boUserLibraries, hint: l.boUserLibrariesHint, children: [
                        _LibraryPicker(
                          libraries: _allLibraries,
                          selected: _libraries,
                          enabled: editable,
                          onChanged: (s) => setState(() => _libraries = s),
                        ),
                      ]),
                  ],
                  if (editable)
                    _Section(children: [
                      if (_u.external)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(l.boUserExternal, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        )
                      else
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: const Icon(Icons.link_rounded),
                          title: Text(l.boUserPasswordLink),
                          subtitle: Text(l.boUserPasswordLinkSubtitle),
                          onTap: _sendLink,
                        ),
                      if (_u.locked)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: const Icon(Icons.lock_open_rounded),
                          title: Text(l.boUserUnlock),
                          onTap: _unlock,
                        ),
                      if (!self)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                          title: Text(l.boUserDelete, style: TextStyle(color: cs.error)),
                          onTap: _delete,
                        ),
                    ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

bool _validEmail(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);

class _BookOrbitNewUserScreen extends StatefulWidget {
  const _BookOrbitNewUserScreen();

  @override
  State<_BookOrbitNewUserScreen> createState() => _BookOrbitNewUserScreenState();
}

class _BookOrbitNewUserScreenState extends State<_BookOrbitNewUserScreen> {
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  Set<String> _permissions = {...boStandardPermissions};
  Set<int> _libraries = {};
  List<BoLibrary> _allLibraries = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_username, _name, _email]) {
      c.addListener(() => setState(() {}));
    }
    _load();
  }

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final libs = await api.adminLibraries();
      List<int> defaults;
      try {
        defaults = await api.adminDefaultLibraryAccess();
      } on BookOrbitAdminError {
        defaults = const [];
      }
      if (!mounted) return;
      setState(() {
        _allLibraries = libs;
        _libraries = {...defaults};
      });
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    }
  }

  bool get _ready =>
      _username.text.trim().length >= 3 && _name.text.trim().isNotEmpty && _validEmail(_email.text.trim());

  Future<void> _create() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    setState(() => _saving = true);
    try {
      final created = await api.adminCreateUser(
        username: _username.text,
        name: _name.text,
        email: _email.text,
        permissions: _permissions,
        libraryIds: _libraries.toList(),
      );
      if (!mounted) return;
      final link = created.resetUrl;
      if (link != null) {
        await _showPasswordLink(context, created.username, link);
      } else {
        showOverlayToast(context, l.boUserNoLink, icon: Icons.info_outline_rounded);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final emailText = _email.text.trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 4),
              Expanded(child: AbsorbPageHeader(title: l.boUserNew, padding: EdgeInsets.zero)),
              FilledButton(onPressed: _ready && !_saving ? _create : null, child: Text(l.boUserCreate)),
              const SizedBox(width: 8),
            ]),
          ),
          if (_saving) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _Section(children: [
                  TextField(
                    controller: _username,
                    autocorrect: false,
                    decoration: InputDecoration(labelText: l.boUserUsername, helperText: l.boUserUsernameHint),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: _name, decoration: InputDecoration(labelText: l.boUserName)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l.boUserEmail,
                      errorText: emailText.isNotEmpty && !_validEmail(emailText) ? l.boUserEmailInvalid : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                ]),
                _Section(title: l.boUserPermissions, children: [
                  _PermissionPicker(selected: _permissions, onChanged: (p) => setState(() => _permissions = p)),
                ]),
                if (_allLibraries.isNotEmpty)
                  _Section(title: l.boUserLibraries, hint: l.boUserLibrariesHint, children: [
                    _LibraryPicker(
                      libraries: _allLibraries,
                      selected: _libraries,
                      onChanged: (s) => setState(() => _libraries = s),
                    ),
                  ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
