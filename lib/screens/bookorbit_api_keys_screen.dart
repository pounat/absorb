import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/bookorbit_admin.dart';
import '../services/bookorbit_api_keys.dart';
import '../services/setup_link_service.dart';
import '../utils/share_origin.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/bookorbit_pickers.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/setup_link_share_sheet.dart';
import 'bookorbit_admin_screen.dart';

/// The BookOrbit API keys of the signed-in user, or of [user] for an
/// administrator who manages users. A key is shown once, when it is made;
/// from then on only its name and tail are known.
class BookOrbitApiKeysScreen extends StatefulWidget {
  final BoUser? user;

  const BookOrbitApiKeysScreen({super.key, this.user});

  @override
  State<BookOrbitApiKeysScreen> createState() => _BookOrbitApiKeysScreenState();
}

class _BookOrbitApiKeysScreenState extends State<BookOrbitApiKeysScreen> {
  List<BoApiKey> _keys = const [];
  BoApiKeySettings? _settings;
  List<BoLibrary> _libraries = const [];
  bool _loading = true;
  bool _busy = false;
  Object? _error;

  BoUser? get _user => widget.user;
  int? get _userId => _user?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// What the key's owner holds, which is the most a key may be given.
  ({Set<String> permissions, bool superuser}) _owner(AuthProvider auth) {
    final u = _user;
    if (u != null) return (permissions: {...u.permissions}..remove('*'), superuser: u.isSuperuser);
    final bo = auth.userJson?['bookOrbit'] as Map?;
    return (
      permissions: {for (final p in (bo?['permissions'] as List? ?? const [])) '$p'}..remove('*'),
      superuser: bo?['isSuperuser'] == true,
    );
  }

  Future<void> _load() async {
    final api = boAdminApi(context);
    if (api == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        api.apiKeys(userId: _userId),
        api.apiKeySettings(),
        _loadLibraries(api),
      ]);
      if (!mounted) return;
      setState(() {
        _keys = _sorted(results[0] as List<BoApiKey>);
        _settings = results[1] as BoApiKeySettings;
        _libraries = results[2] as List<BoLibrary>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// The libraries a key may be limited to: the owner's own. An
  /// administrator sees the whole list and narrows it to the user's.
  Future<List<BoLibrary>> _loadLibraries(BookOrbitApiService api) async {
    try {
      final all = [
        for (final l in await api.getLibraries())
          if (int.tryParse('${l['id']}') != null)
            BoLibrary(id: int.parse('${l['id']}'), name: l['name'] as String? ?? ''),
      ];
      final u = _user;
      if (u == null || u.isSuperuser) return all;
      final theirs = await api.adminUserLibraries(u.id);
      return theirs.isEmpty ? all : all.where((l) => theirs.contains(l.id)).toList();
    } catch (e) {
      debugPrint('[BookOrbit] Could not list libraries for a key: $e');
      return const [];
    }
  }

  List<BoApiKey> _sorted(List<BoApiKey> keys) {
    final out = [...keys];
    out.sort((a, b) {
      if (a.usable != b.usable) return a.usable ? -1 : 1;
      return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
    });
    return out;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showBoApiKeyError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final api = boAdminApi(context);
    final settings = _settings;
    if (api == null || settings == null) return;
    final owner = _owner(context.read<AuthProvider>());
    final request = await showBoApiKeyCreateSheet(
      context,
      ownerPermissions: owner.permissions,
      ownerIsSuperuser: owner.superuser,
      libraries: _libraries,
      settings: settings,
      forUser: _user?.name,
    );
    if (request == null || !mounted) return;
    await _run(() async {
      final created = await api.createBoApiKey(
        userId: _userId,
        name: request.name,
        write: request.write,
        permissions: request.permissions,
        expiry: request.expiry,
        admin: request.admin,
        libraryIds: request.libraryIds,
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      await showBoApiKeyRevealSheet(context, created, username: _user?.username);
    });
  }

  Future<void> _rename(BoApiKey key) async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    final ctrl = TextEditingController(text: key.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.boApiKeyRename),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: boApiKeyNameMaxLength,
          decoration: InputDecoration(labelText: l.boApiKeyName),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(l.save)),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == key.name || !mounted) return;
    await _run(() async {
      await api.renameApiKey(key.id, name);
      await _load();
    });
  }

  Future<void> _regenerate(BoApiKey key) async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    final ok = await _confirm(l.boApiKeyRegenerateTitle, l.boApiKeyRegenerateBody(key.name), l.boApiKeyRegenerate);
    if (!ok || !mounted) return;
    await _run(() async {
      final created = await api.regenerateApiKey(key.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      await showBoApiKeyRevealSheet(context, created, username: _user?.username);
    });
  }

  Future<void> _revoke(BoApiKey key) async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    final ok = await _confirm(l.boApiKeyRevokeTitle, l.boApiKeyRevokeBody(key.name), l.boApiKeyRevoke, danger: true);
    if (!ok || !mounted) return;
    await _run(() async {
      await api.revokeApiKey(key.id, userId: _userId);
      await _load();
      if (mounted) showOverlayToast(context, l.boApiKeyRevoked, icon: Icons.key_off_rounded);
    });
  }

  Future<void> _revokeAll() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    final count = _keys.where((k) => k.usable).length;
    final ok = await _confirm(l.boApiKeyRevokeAllTitle, l.boApiKeyRevokeAllBody(count), l.boApiKeyRevokeAll, danger: true);
    if (!ok || !mounted) return;
    await _run(() async {
      final n = await api.revokeAllApiKeys(userId: _userId);
      await _load();
      if (mounted) showOverlayToast(context, l.boApiKeyRevokedCount(n), icon: Icons.key_off_rounded);
    });
  }

  Future<bool> _confirm(String title, String body, String action, {bool danger = false}) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
              FilledButton(
                style: danger ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError) : null,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(action),
              ),
            ],
          ),
        ) ==
        true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final settings = _settings;
    final user = _user;
    final active = _keys.where((k) => k.usable).length;
    final canMake = user != null || auth.bookOrbitCanMakeApiKeys;
    final creatable = canMake && settings != null && settings.enabled && active < boApiKeyMaxActive;
    final own = user == null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Row(children: [
            Expanded(
              child: AbsorbPageHeader(
                title: own ? l.boApiKeysTitle : l.boApiKeysForUser(user.name),
                padding: const EdgeInsets.only(left: 20),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
          ]),
          if (_loading || _busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _error != null
                ? _Retry(error: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                          child: Text(own ? l.boApiKeysIntro : l.boApiKeysIntroAdmin(user.name),
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                        if (settings != null && !settings.enabled)
                          _Notice(icon: Icons.key_off_rounded, text: l.boApiKeysDisabled),
                        if (own && !canMake && !_loading)
                          _Notice(icon: Icons.info_outline_rounded, text: l.boApiKeysNoPermission),
                        if (settings != null && settings.enabled && active >= boApiKeyMaxActive)
                          _Notice(icon: Icons.info_outline_rounded, text: l.boApiKeysLimit(boApiKeyMaxActive)),
                        Row(children: [
                          FilledButton.icon(
                            onPressed: creatable && !_busy ? _create : null,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(own ? l.boApiKeyCreate : l.boApiKeyIssue),
                          ),
                          const Spacer(),
                          if (active > 1)
                            TextButton(
                              onPressed: _busy ? null : _revokeAll,
                              child: Text(l.boApiKeyRevokeAll, style: TextStyle(color: cs.error)),
                            ),
                        ]),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: creatable && !_busy
                              ? () => _run(() async {
                                    await showBoApiKeySignInLink(context, user: user);
                                    if (mounted) await _load();
                                  })
                              : null,
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: Text(own ? l.boApiKeySignInElsewhere : l.boApiKeyLinkFor(user.name)),
                        ),
                        const SizedBox(height: 12),
                        if (!_loading && _keys.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 24, 4, 0),
                            child: Column(children: [
                              Icon(Icons.vpn_key_outlined, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                              const SizedBox(height: 10),
                              Text(l.boApiKeysEmpty,
                                  textAlign: TextAlign.center,
                                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ]),
                          ),
                        for (final key in _keys)
                          _KeyTile(
                            keyInfo: key,
                            libraries: _libraries,
                            onRename: own && key.usable ? () => _rename(key) : null,
                            onRegenerate: own && key.usable ? () => _regenerate(key) : null,
                            onRevoke: key.usable ? () => _revoke(key) : null,
                          ),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _KeyTile extends StatelessWidget {
  final BoApiKey keyInfo;
  final List<BoLibrary> libraries;
  final VoidCallback? onRename;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRevoke;

  const _KeyTile({
    required this.keyInfo,
    required this.libraries,
    this.onRename,
    this.onRegenerate,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final k = keyInfo;
    final dates = MaterialLocalizations.of(context);
    final faded = !k.usable;
    final dim = cs.onSurfaceVariant;

    String when(DateTime d) => dates.formatMediumDate(d);
    final expiry = switch (k.state) {
      BoApiKeyState.revoked => l.boApiKeyRevokedOn(when(k.revokedAt!)),
      BoApiKeyState.expired => l.boApiKeyExpiredOn(when(k.expiresAt!)),
      BoApiKeyState.expiring => l.boApiKeyExpiresSoon(when(k.expiresAt!)),
      BoApiKeyState.active => k.expiresAt == null ? l.boApiKeyNeverExpires : l.boApiKeyExpiresOn(when(k.expiresAt!)),
    };
    final used = k.lastUsedAt == null
        ? l.boApiKeyNeverUsed
        : k.lastUsedIp == null
            ? l.boApiKeyLastUsed(when(k.lastUsedAt!))
            : l.boApiKeyLastUsedFrom(when(k.lastUsedAt!), k.lastUsedIp!);
    final libs = k.libraryIds;
    final scope =
        libs?.map((id) => libraries.where((x) => x.id == id).map((x) => x.name).firstOrNull ?? '#$id').join(', ');
    final hasMenu = onRename != null || onRegenerate != null || onRevoke != null;

    return Opacity(
      opacity: faded ? 0.6 : 1,
      child: BoSection(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 12, 0),
            child: Icon(faded ? Icons.key_off_rounded : Icons.vpn_key_rounded, color: faded ? dim : cs.primary),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k.name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(k.masked, style: tt.bodySmall?.copyWith(color: dim, fontFamily: 'monospace')),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _Badge(k.write ? l.boApiKeyAccessWrite : l.boApiKeyAccessRead, k.write ? cs.tertiary : dim),
                if (k.admin) _Badge(l.boApiKeyAdminBadge, cs.error),
                if (k.state == BoApiKeyState.expiring) _Badge(l.boApiKeyExpiringBadge, Colors.orange),
                if (k.state == BoApiKeyState.expired) _Badge(l.boApiKeyExpiredBadge, dim),
                if (k.state == BoApiKeyState.revoked) _Badge(l.boApiKeyRevokedBadge, dim),
              ]),
              const SizedBox(height: 6),
              Text(expiry, style: tt.bodySmall?.copyWith(color: dim)),
              Text(used, style: tt.bodySmall?.copyWith(color: dim)),
              if (scope != null) Text(l.boApiKeyLibrariesOnly(scope), style: tt.bodySmall?.copyWith(color: dim)),
              if (k.createdBy != null) Text(l.boApiKeyIssuedBy(k.createdBy!), style: tt.bodySmall?.copyWith(color: dim)),
            ]),
          ),
          if (hasMenu)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: dim),
              onSelected: (v) => switch (v) {
                'rename' => onRename?.call(),
                'regenerate' => onRegenerate?.call(),
                _ => onRevoke?.call(),
              },
              itemBuilder: (_) => [
                if (onRename != null) PopupMenuItem(value: 'rename', child: Text(l.boApiKeyRename)),
                if (onRegenerate != null) PopupMenuItem(value: 'regenerate', child: Text(l.boApiKeyRegenerate)),
                if (onRevoke != null)
                  PopupMenuItem(value: 'revoke', child: Text(l.boApiKeyRevoke, style: TextStyle(color: cs.error))),
              ],
            ),
        ]),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
      );
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: tt.bodySmall?.copyWith(color: cs.onSecondaryContainer))),
        ]),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _Retry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final message = error is BookOrbitAdminError
        ? (error as BookOrbitAdminError).status == 0
            ? l.boAdminOffline
            : (error as BookOrbitAdminError).message ?? l.boAdminFailed
        : l.boAdminFailed;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(l.retry)),
        ]),
      ),
    );
  }
}

/// What a new key should be. [libraryIds] null means every library.
class BoApiKeyRequest {
  final String name;
  final bool write;
  final Set<String> permissions;
  final BoApiKeyExpiry expiry;
  final bool admin;
  final List<int>? libraryIds;

  const BoApiKeyRequest({
    required this.name,
    required this.write,
    required this.permissions,
    required this.expiry,
    required this.admin,
    required this.libraryIds,
  });
}

/// Asks what the new key may do. Null when the person backed out.
Future<BoApiKeyRequest?> showBoApiKeyCreateSheet(
  BuildContext context, {
  required Set<String> ownerPermissions,
  required bool ownerIsSuperuser,
  required List<BoLibrary> libraries,
  required BoApiKeySettings settings,
  String? forUser,
}) {
  final l = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final grantable = ownerIsSuperuser ? boApiKeyGrantable(boAllPermissions) : boApiKeyGrantable(ownerPermissions);
  final choices = boApiKeyExpiryChoices(settings.maxLifetimeDays);
  final name = TextEditingController();
  var write = true;
  var expiry = boApiKeyDefaultChoice(choices);
  var permissions = <String>{};
  var admin = false;
  var allLibraries = true;
  var picked = <int>{};

  String expiryLabel(BoApiKeyExpiry e) => e.never ? l.boApiKeyExpiryNever : l.boApiKeyExpiryDays(e.days!);

  return showAdaptiveActionMenu<BoApiKeyRequest>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    desktopWidth: 560,
    desktopScrollWrap: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final valid = name.text.trim().isNotEmpty && (allLibraries || admin || picked.isNotEmpty);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(forUser == null ? l.boApiKeyCreate : l.boApiKeyIssueFor(forUser),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(l.boApiKeyCreateHint, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                autofocus: true,
                maxLength: boApiKeyNameMaxLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.boApiKeyName, hintText: l.boApiKeyNameHint),
                onChanged: (_) => setSheet(() {}),
              ),
              const SizedBox(height: 8),
              Text(l.boApiKeyAccess, style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.boApiKeyAccessRead), icon: const Icon(Icons.visibility_outlined)),
                  ButtonSegment(value: true, label: Text(l.boApiKeyAccessWrite), icon: const Icon(Icons.edit_outlined)),
                ],
                selected: {write},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setSheet(() => write = s.first),
              ),
              const SizedBox(height: 6),
              Text(write ? l.boApiKeyAccessWriteHint : l.boApiKeyAccessReadHint,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text(l.boApiKeyExpires, style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final c in choices)
                  ChoiceChip(
                    label: Text(expiryLabel(c)),
                    selected: expiry == c,
                    onSelected: (_) => setSheet(() => expiry = c),
                  ),
              ]),
              if (settings.maxLifetimeDays != null) ...[
                const SizedBox(height: 6),
                Text(l.boApiKeyExpiryCapped(settings.maxLifetimeDays!),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
              if (ownerIsSuperuser) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.boApiKeyAdmin),
                  subtitle: Text(l.boApiKeyAdminHint),
                  value: admin,
                  onChanged: (v) => setSheet(() {
                    admin = v;
                    if (v) allLibraries = true;
                  }),
                ),
              ],
              const SizedBox(height: 12),
              Text(l.boApiKeyPermissions, style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(admin ? l.boApiKeyAdminHasAll : l.boApiKeyPermissionsHint,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              if (!admin)
                grantable.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(l.boApiKeyNoGrantable, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      )
                    : BoPermissionPicker(
                        selected: permissions,
                        only: grantable,
                        onChanged: (p) => setSheet(() => permissions = p),
                      ),
              if (!admin && libraries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l.boApiKeyLibraries, style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.boApiKeyAllLibraries),
                  value: allLibraries,
                  onChanged: (v) => setSheet(() => allLibraries = v),
                ),
                if (!allLibraries)
                  BoLibraryPicker(
                    libraries: libraries,
                    selected: picked,
                    onChanged: (s) => setSheet(() => picked = s),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: valid
                    ? () => Navigator.pop(
                          ctx,
                          BoApiKeyRequest(
                            name: name.text.trim(),
                            write: write,
                            permissions: admin ? const {} : permissions,
                            expiry: expiry,
                            admin: admin,
                            libraryIds: admin || allLibraries ? null : picked.toList(),
                          ),
                        )
                    : null,
                child: Text(forUser == null ? l.boApiKeyCreate : l.boApiKeyIssue),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Makes a key that signs [user], or the signed-in person when null, in to
/// Absorb on another device and shows it as a link and QR code straight
/// away: read and write, every permission the owner has, every library,
/// administrator access for a superuser, and the longest lifetime the
/// server allows. The key is named after Absorb, so it is easy to find and
/// revoke in the list later.
Future<void> showBoApiKeySignInLink(BuildContext context, {BoUser? user}) async {
  final l = AppLocalizations.of(context)!;
  final api = boAdminApi(context);
  final auth = context.read<AuthProvider>();
  if (api == null) return;
  final username = user?.username ?? auth.username ?? '';
  final bo = auth.userJson?['bookOrbit'] as Map?;
  final superuser = user?.isSuperuser ?? (bo?['isSuperuser'] == true);
  final owned = user?.permissions ?? {for (final p in (bo?['permissions'] as List? ?? const [])) '$p'};
  try {
    final settings = await api.apiKeySettings();
    if (!context.mounted) return;
    if (!settings.enabled) {
      showOverlayToast(context, l.boApiKeysDisabled, icon: Icons.key_off_rounded);
      return;
    }
    final created = await api.createBoApiKey(
      userId: user?.id,
      name: l.boApiKeyLinkName,
      write: true,
      permissions: superuser ? const {} : boApiKeyGrantable(owned),
      expiry: boApiKeyExpiryChoices(settings.maxLifetimeDays).last,
      admin: superuser,
    );
    if (!context.mounted) return;
    await showBoApiKeyLinkSheet(context, created, username: username);
  } catch (e) {
    if (context.mounted) showBoApiKeyError(context, e);
  }
}

/// The sign-in link and QR code for a key just made.
Future<void> showBoApiKeyLinkSheet(BuildContext context, BoCreatedApiKey created, {required String username}) {
  final l = AppLocalizations.of(context)!;
  final auth = context.read<AuthProvider>();
  final serverUrl = auth.serverUrl;
  if (serverUrl == null) return Future.value();
  final link = SetupLinkService.createBookOrbitApiKeyLink(
    serverUrl: serverUrl,
    username: username,
    token: created.token,
    customHeaders: auth.customHeaders,
  );
  Future<void> copyText(BuildContext c, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (c.mounted) showOverlayToast(c, l.setupLinkCopied, icon: Icons.content_copy_rounded);
  }

  return showAdaptiveActionMenu<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    desktopWidth: 560,
    desktopScrollWrap: false,
    builder: (c) => SetupLinkShareSheet(
      username: username,
      setupLink: link,
      description: l.boApiKeyShareDescription(username),
      warning: l.boApiKeyShareWarning(created.key.name),
      onShare: () => Share.share(
        link.toString(),
        subject: l.setupLinkShareSubject(username),
        sharePositionOrigin: shareOriginFor(c),
      ),
      onCopy: () => copyText(c, link.toString()),
    ),
  );
}

/// Shows a token the one time it can be seen, with a copy button and a
/// sign-in link with QR code for putting it on another device.
Future<void> showBoApiKeyRevealSheet(BuildContext context, BoCreatedApiKey created, {String? username}) {
  final l = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final auth = context.read<AuthProvider>();
  final who = username ?? auth.username ?? '';
  final serverUrl = auth.serverUrl;

  Future<void> copy(BuildContext sheetContext) async {
    await Clipboard.setData(ClipboardData(text: created.token));
    if (sheetContext.mounted) {
      showOverlayToast(sheetContext, l.boApiKeyCopied, icon: Icons.content_copy_rounded);
    }
  }

  Future<void> shareLink(BuildContext sheetContext) => showBoApiKeyLinkSheet(sheetContext, created, username: who);

  return showAdaptiveActionMenu<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    desktopWidth: 560,
    desktopScrollWrap: false,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(created.key.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(l.boApiKeyRevealHint, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(created.token, style: tt.bodyMedium?.copyWith(fontFamily: 'monospace')),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => copy(ctx),
          icon: const Icon(Icons.content_copy_rounded),
          label: Text(l.boApiKeyCopy),
        ),
        if (serverUrl != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => shareLink(ctx),
            icon: const Icon(Icons.qr_code_2_rounded),
            label: Text(l.boApiKeySignInElsewhere),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(child: Text(l.boApiKeyRevealWarning, style: tt.bodySmall?.copyWith(color: cs.error))),
        ]),
        const SizedBox(height: 16),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.done)),
      ]),
    ),
  );
}

/// Shows why the server refused, in Absorb's words for the reasons it
/// names and the server's own for the rest.
void showBoApiKeyError(BuildContext context, Object error) {
  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  if (error is BookOrbitAdminError) {
    final text = switch (error.code) {
      'API_KEYS_DISABLED' => l.boApiKeysDisabled,
      'API_KEY_LIMIT_REACHED' => l.boApiKeysLimit(boApiKeyMaxActive),
      'API_KEY_EXPIRY_EXCEEDS_CAP' => l.boApiKeyErrorExpiryCap,
      'API_KEY_OWNER_NOT_PERMITTED' => l.boApiKeyErrorOwner,
      'API_KEY_ADMIN_WITH_LIBRARIES' => l.boApiKeyErrorAdminLibraries,
      'API_KEY_SCOPE_EXCEEDS_OWNER' => l.boApiKeyErrorScope,
      'API_KEY_ROUTE_FORBIDDEN' => l.boApiKeyErrorKeySession,
      _ => null,
    };
    if (text != null) {
      showOverlayToast(context, text, icon: Icons.error_outline_rounded);
      return;
    }
  }
  showBoAdminError(context, error);
}
