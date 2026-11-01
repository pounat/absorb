import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/bookorbit_email.dart';
import '../widgets/overlay_toast.dart';
import 'bookorbit_admin_screen.dart';
import 'bookorbit_email_screen.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// A page that edits one thing. Saving or deleting pops it with true.
class _EditorPage extends StatelessWidget {
  final String title;
  final bool busy;
  final VoidCallback onSave;
  final List<Widget> children;

  const _EditorPage({required this.title, required this.busy, required this.onSave, required this.children});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context, false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              FilledButton(onPressed: busy ? null : onSave, child: Text(l.save)),
              const SizedBox(width: 8),
            ]),
          ),
          if (busy) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: children,
            ),
          ),
        ]),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String name, String body) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.boEmailDeleteTitle(name)),
      content: Text(body),
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
  return ok == true;
}

Widget _hint(BuildContext context, String text, {Color? color}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
              )),
    );

Widget _label(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
    );

Widget _dangerTile(BuildContext context, String label, VoidCallback onTap) {
  final cs = Theme.of(context).colorScheme;
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(Icons.delete_outline_rounded, color: cs.error),
    title: Text(label, style: TextStyle(color: cs.error)),
    onTap: onTap,
  );
}

Widget _templatePicker(
  BuildContext context, {
  required List<BoEmailTemplate> templates,
  required int? value,
  required ValueChanged<int?> onChanged,
}) {
  final l = AppLocalizations.of(context)!;
  final known = templates.any((t) => t.id == value);
  return DropdownButtonFormField<int?>(
    initialValue: known ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: l.boEmailTemplate),
    items: [
      DropdownMenuItem<int?>(value: null, child: Text(l.boEmailTemplateYourDefault)),
      for (final t in templates) DropdownMenuItem<int?>(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
    ],
    onChanged: onChanged,
  );
}

/// One device or inbox books are sent to.
class BoEmailDeviceScreen extends StatefulWidget {
  final BoEmailDevice? device;
  final BoEmailSetup setup;
  const BoEmailDeviceScreen({super.key, this.device, required this.setup});

  @override
  State<BoEmailDeviceScreen> createState() => _BoEmailDeviceScreenState();
}

class _BoEmailDeviceScreenState extends State<BoEmailDeviceScreen> {
  late final _name = TextEditingController(text: widget.device?.name ?? '');
  late final _email = TextEditingController(text: widget.device?.email ?? '');
  late String? _type = widget.device?.deviceType;
  late String? _format = widget.device?.preferredFormat;
  late String? _readAlong = widget.device?.readAlong;
  late int? _template = widget.device?.templateId;
  late bool _default = widget.device != null && widget.setup.defaults.deviceId == widget.device!.id;
  bool _busy = false;
  bool _testing = false;

  BoEmailDevice? get _d => widget.device;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _setType(String? type) {
    setState(() {
      _type = type;
      if (type == 'kindle') {
        if (_format != null && !boKindleAccepts(_format!)) _format = null;
        if (_readAlong == 'original') _readAlong = 'audioless_epub';
      }
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || email.isEmpty) {
      showOverlayToast(context, l.boEmailDeviceRequired, icon: Icons.error_outline_rounded);
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      showOverlayToast(context, l.boUserEmailInvalid, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await api.emailSaveDevice(_d?.id, {
        'name': name,
        'email': email,
        'deviceType': _type,
        'preferredFormat': _format,
        'defaultTemplateId': _template,
        if (widget.setup.readAlongChoice) 'readAloudDelivery': _readAlong,
      });
      final wasDefault = _d != null && widget.setup.defaults.deviceId == _d!.id;
      if (_default != wasDefault) await api.emailSetDefaults(deviceId: _default ? saved.id : null);
      if (!mounted) return;
      showOverlayToast(context, l.boAdminSaved, icon: Icons.check_circle_outline_rounded);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    final d = _d;
    if (api == null || d == null) return;
    setState(() => _testing = true);
    try {
      final r = await api.emailTestDevice(d.id, subject: l.boEmailTestSubject, text: l.boEmailTestBody(d.name));
      if (!mounted) return;
      showOverlayToast(
        context,
        r.ok ? l.boEmailTestSent(d.name) : l.boEmailTestFailed(r.error ?? ''),
        icon: r.ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
      );
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    final d = _d;
    if (api == null || d == null) return;
    if (!await _confirmDelete(context, d.name, l.boEmailDeleteDeviceBody) || !mounted) return;
    try {
      await api.emailDeleteDevice(d.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final kindle = _type == 'kindle';
    final sender = widget.setup.defaultServer?.sender;
    final readAlongHint = switch (_readAlong) {
      'audioless_epub' => l.boEmailReadAlongTextHint,
      'original' => l.boEmailReadAlongOriginalHint,
      _ => l.boEmailReadAlongAutoHint,
    };

    return _EditorPage(
      title: _d?.name ?? l.boEmailNewDevice,
      busy: _busy,
      onSave: _save,
      children: [
        BoEmailSection(children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.boEmailName, hintText: l.boEmailDeviceNameHint),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(labelText: l.boEmailDeviceAddress),
          ),
          const SizedBox(height: 8),
          _label(context, l.boEmailDeviceType),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final t in [null, ...boEmailDeviceTypes])
              ChoiceChip(
                avatar: Icon(boDeviceIcon(t), size: 18),
                label: Text(boDeviceLabel(l, t)),
                selected: _type == t,
                onSelected: (_) => _setType(t),
              ),
          ]),
          if (kindle) ...[
            _hint(context, l.boEmailKindleHint),
            _hint(
              context,
              sender == null ? l.boEmailKindleApproveNoServer : l.boEmailKindleApprove(sender),
              color: cs.primary,
            ),
          ],
        ]),
        BoEmailSection(children: [
          _label(context, l.boEmailFormat),
          Wrap(spacing: 8, runSpacing: 4, children: [
            ChoiceChip(
              label: Text(l.boEmailFormatPrimary),
              selected: _format == null,
              onSelected: (_) => setState(() => _format = null),
            ),
            for (final f in boFormatsFor(_type))
              ChoiceChip(
                label: Text(f.toUpperCase()),
                selected: _format == f,
                onSelected: (_) => setState(() => _format = f),
              ),
          ]),
          _hint(context, l.boEmailFormatHint),
          if (widget.setup.readAlongChoice) ...[
            _label(context, l.boEmailReadAlong),
            Wrap(spacing: 8, runSpacing: 4, children: [
              ChoiceChip(
                label: Text(l.boEmailReadAlongAuto),
                selected: _readAlong == null,
                onSelected: (_) => setState(() => _readAlong = null),
              ),
              ChoiceChip(
                label: Text(l.boEmailReadAlongText),
                selected: _readAlong == 'audioless_epub',
                onSelected: (_) => setState(() => _readAlong = 'audioless_epub'),
              ),
              if (!kindle)
                ChoiceChip(
                  label: Text(l.boEmailReadAlongOriginal),
                  selected: _readAlong == 'original',
                  onSelected: (_) => setState(() => _readAlong = 'original'),
                ),
            ]),
            _hint(context, readAlongHint),
          ],
          const SizedBox(height: 8),
          _templatePicker(
            context,
            templates: widget.setup.templates,
            value: _template,
            onChanged: (v) => setState(() => _template = v),
          ),
          if (kindle) _hint(context, l.boEmailTemplateKindleHint),
        ]),
        BoEmailSection(children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(l.boEmailDefaultDevice),
            subtitle: Text(l.boEmailDefaultDeviceHint),
            value: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
          if (_d != null) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: _testing
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.outgoing_mail),
              title: Text(l.boEmailSendTest),
              onTap: _testing ? null : _test,
            ),
            _dangerTile(context, l.boEmailDeleteDevice, _delete),
          ],
        ]),
      ],
    );
  }
}

/// Several devices that get a book in one send.
class BoEmailGroupScreen extends StatefulWidget {
  final BoEmailGroup? group;
  final BoEmailSetup setup;
  const BoEmailGroupScreen({super.key, this.group, required this.setup});

  @override
  State<BoEmailGroupScreen> createState() => _BoEmailGroupScreenState();
}

class _BoEmailGroupScreenState extends State<BoEmailGroupScreen> {
  late final _name = TextEditingController(text: widget.group?.name ?? '');
  late int? _template = widget.group?.templateId;
  late final Set<int> _members = {...?widget.group?.memberIds};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      showOverlayToast(context, l.boEmailGroupRequired, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _busy = true);
    try {
      final g = widget.group;
      final int id;
      if (g == null) {
        id = await api.emailCreateGroup(name, templateId: _template);
      } else {
        await api.emailUpdateGroup(g.id, name: name, templateId: _template);
        id = g.id;
      }
      final before = g?.memberIds ?? const <int>{};
      for (final add in _members.difference(before)) {
        await api.emailAddToGroup(id, add);
      }
      for (final drop in before.difference(_members)) {
        await api.emailRemoveFromGroup(id, drop);
      }
      if (!mounted) return;
      showOverlayToast(context, l.boAdminSaved, icon: Icons.check_circle_outline_rounded);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    final g = widget.group;
    if (api == null || g == null) return;
    if (!await _confirmDelete(context, g.name, l.boEmailDeleteGroupBody) || !mounted) return;
    try {
      await api.emailDeleteGroup(g.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final devices = widget.setup.devices;
    return _EditorPage(
      title: widget.group?.name ?? l.boEmailNewGroup,
      busy: _busy,
      onSave: _save,
      children: [
        BoEmailSection(children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.boEmailName, hintText: l.boEmailGroupNameHint),
          ),
          const SizedBox(height: 8),
          _templatePicker(
            context,
            templates: widget.setup.templates,
            value: _template,
            onChanged: (v) => setState(() => _template = v),
          ),
        ]),
        BoEmailSection(title: l.boEmailGroupMembers, children: [
          if (devices.isEmpty) BoEmailEmpty(l.boEmailGroupMembersEmpty),
          for (final d in devices)
            CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              secondary: Icon(boDeviceIcon(d.deviceType), color: cs.primary),
              title: Text(d.name),
              subtitle: Text(d.email),
              value: _members.contains(d.id),
              onChanged: (v) => setState(() => v == true ? _members.add(d.id) : _members.remove(d.id)),
            ),
        ]),
        if (widget.group != null) BoEmailSection(children: [_dangerTile(context, l.boEmailDeleteGroup, _delete)]),
      ],
    );
  }
}

/// An SMTP server books go out through. Only the person who added it can
/// change it.
class BoEmailServerScreen extends StatefulWidget {
  final BoMailServer? server;
  final BoEmailSetup setup;
  const BoEmailServerScreen({super.key, this.server, required this.setup});

  @override
  State<BoEmailServerScreen> createState() => _BoEmailServerScreenState();
}

class _BoEmailServerScreenState extends State<BoEmailServerScreen> {
  late final _name = TextEditingController(text: widget.server?.name ?? '');
  late final _host = TextEditingController(text: widget.server?.host ?? '');
  late final _port = TextEditingController(text: '${widget.server?.port ?? 587}');
  late final _username = TextEditingController(text: widget.server?.username ?? '');
  final _password = TextEditingController();
  late final _fromName = TextEditingController(text: widget.server?.fromName ?? '');
  late final _fromAddress = TextEditingController(text: widget.server?.fromAddress ?? '');
  late BoMailSecurity _security = widget.server?.security ?? BoMailSecurity.startTls;
  late bool _auth = widget.server?.auth ?? true;
  late bool _shared = widget.server?.isShared ?? false;
  late bool _system = widget.server?.isSystem ?? false;
  late bool _verifyTls = widget.server?.verifyTls ?? true;
  late bool _default = widget.server != null && widget.setup.defaults.serverId == widget.server!.id;
  bool _showPassword = false;
  bool _busy = false;
  bool _testing = false;
  bool _dirty = false;
  ({bool ok, String? error})? _testResult;

  BoMailServer? get _s => widget.server;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _host, _port, _username, _password, _fromName, _fromAddress]) {
      c.addListener(_touch);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _host, _port, _username, _password, _fromName, _fromAddress]) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _change(VoidCallback f) => setState(() {
        f();
        _dirty = true;
      });

  void _applyPreset(BoMailPreset? p) {
    _change(() {
      if (p == null) {
        if (BoMailPreset.forHost(_host.text) != null) _host.text = '';
        return;
      }
      final previous = BoMailPreset.forHost(_host.text);
      if (_name.text.trim().isEmpty || _name.text.trim() == previous?.name) _name.text = p.name;
      _host.text = p.host;
      _port.text = '${p.port}';
      _security = p.security;
      _auth = true;
    });
  }

  void _setSecurity(BoMailSecurity s) => _change(() {
        _security = s;
        if (s == BoMailSecurity.ssl && _port.text.trim() == '587') _port.text = '465';
        if (s == BoMailSecurity.startTls && _port.text.trim() == '465') _port.text = '587';
      });

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    final superuser = context.read<AuthProvider>().bookOrbitAdmin?.isSuperuser == true;
    if (api == null) return;
    final name = _name.text.trim();
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    if (name.isEmpty || host.isEmpty || port == null || port < 1 || port > 65535) {
      showOverlayToast(context, l.boEmailServerRequired, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _busy = true);
    try {
      var saved = await api.emailSaveServer(_s?.id, {
        'name': name,
        'host': host,
        'port': port,
        'username': _username.text.trim(),
        if (_password.text.isNotEmpty) 'password': _password.text,
        'fromName': _fromName.text.trim(),
        'fromAddress': _fromAddress.text.trim(),
        'auth': _auth,
        'ssl': _security == BoMailSecurity.ssl,
        'startTls': _security == BoMailSecurity.startTls,
        'tlsRejectUnauthorized': _verifyTls,
      });
      if (saved.isShared != _shared) saved = await api.emailToggleShared(saved.id);
      if (superuser && saved.isSystem != _system) {
        if (_system) {
          await api.emailSetSystemServer(saved.id);
        } else {
          await api.emailClearSystemServer();
        }
      }
      final wasDefault = _s != null && widget.setup.defaults.serverId == _s!.id;
      if (_default != wasDefault && context.read<AuthProvider>().bookOrbitAdmin?.emailSend == true) {
        await api.emailSetDefaults(serverId: _default ? saved.id : null);
      }
      if (!mounted) return;
      showOverlayToast(context, l.boAdminSaved, icon: Icons.check_circle_outline_rounded);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final api = boAdminApi(context);
    final s = _s;
    if (api == null || s == null) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final r = await api.emailTestServer(s.id);
      if (mounted) setState(() => _testResult = r);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    final s = _s;
    if (api == null || s == null) return;
    if (s.isSystem) {
      showOverlayToast(context, l.boEmailServerSystemFirst, icon: Icons.info_outline_rounded);
      return;
    }
    if (!await _confirmDelete(context, s.name, l.boEmailServerDeleteBody) || !mounted) return;
    try {
      await api.emailDeleteServer(s.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final access = context.watch<AuthProvider>().bookOrbitAdmin;
    final preset = BoMailPreset.forHost(_host.text);
    final appPassword = preset?.appPassword == true;

    return _EditorPage(
      title: _s?.name ?? l.boEmailNewServer,
      busy: _busy,
      onSave: _save,
      children: [
        BoEmailSection(children: [
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final p in BoMailPreset.all)
              ChoiceChip(label: Text(p.name), selected: preset == p, onSelected: (_) => _applyPreset(p)),
            ChoiceChip(
              label: Text(l.boEmailServerPresetOther),
              selected: preset == null,
              onSelected: (_) => _applyPreset(null),
            ),
          ]),
          _hint(context, l.boEmailServerPresetHint),
          const SizedBox(height: 4),
          TextField(controller: _name, decoration: InputDecoration(labelText: l.boEmailName)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _host,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(labelText: l.boEmailServerHost, hintText: 'smtp.example.com'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l.boEmailServerPort),
              ),
            ),
          ]),
          _label(context, l.boEmailServerSecurity),
          SegmentedButton<BoMailSecurity>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(value: BoMailSecurity.startTls, label: Text('STARTTLS')),
              const ButtonSegment(value: BoMailSecurity.ssl, label: Text('SSL/TLS')),
              ButtonSegment(value: BoMailSecurity.none, label: Text(l.boEmailServerSecurityNone)),
            ],
            selected: {_security},
            onSelectionChanged: (v) => _setSecurity(v.first),
          ),
          _hint(context, l.boEmailServerSecurityHint),
        ]),
        BoEmailSection(children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(l.boEmailServerNeedsPassword),
            value: _auth,
            onChanged: (v) => _change(() => _auth = v),
          ),
          if (_auth) ...[
            TextField(
              controller: _username,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l.boEmailServerUsername),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: appPassword ? l.boEmailServerAppPassword : l.boEmailServerPassword,
                hintText: _s?.hasPassword == true ? l.boEmailServerPasswordKeep : null,
                floatingLabelBehavior: _s?.hasPassword == true ? FloatingLabelBehavior.always : null,
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            if (appPassword) _hint(context, l.boEmailServerAppPasswordHint),
          ],
        ]),
        BoEmailSection(children: [
          TextField(controller: _fromName, decoration: InputDecoration(labelText: l.boEmailServerFromName)),
          const SizedBox(height: 8),
          TextField(
            controller: _fromAddress,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(labelText: l.boEmailServerFromAddress),
          ),
          _hint(context, l.boEmailServerFromAddressHint),
        ]),
        BoEmailSection(children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(l.boEmailServerShare),
            subtitle: Text(l.boEmailServerShareHint),
            value: _shared,
            onChanged: (v) => _change(() => _shared = v),
          ),
          if (access?.isSuperuser == true)
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(l.boEmailServerSystem),
              subtitle: Text(l.boEmailServerSystemHint),
              value: _system,
              onChanged: (v) => _change(() => _system = v),
            ),
          if (access?.emailSend == true)
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(l.boEmailBadgeDefault),
              value: _default,
              onChanged: (v) => _change(() => _default = v),
            ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(l.boEmailServerVerifyTls),
            subtitle: Text(l.boEmailServerVerifyTlsHint),
            value: _verifyTls,
            onChanged: (v) => _change(() => _verifyTls = v),
          ),
        ]),
        if (_s != null)
          BoEmailSection(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: _testing
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering_rounded),
              title: Text(l.boEmailServerTest),
              subtitle: _dirty
                  ? Text(l.boEmailServerTestSaveFirst)
                  : _testResult == null
                      ? null
                      : Text(
                          _testResult!.ok ? l.boEmailServerTestOk : l.boEmailServerTestFailed(_testResult!.error ?? ''),
                          style: TextStyle(color: _testResult!.ok ? Colors.green : cs.error),
                        ),
              onTap: _testing || _dirty ? null : _test,
            ),
            _dangerTile(context, l.boEmailServerDelete, _delete),
          ]),
      ],
    );
  }
}

/// The subject and message that go with each book. Built-in templates are
/// for a superuser to change.
class BoEmailTemplateScreen extends StatefulWidget {
  final BoEmailTemplate? template;
  final BoEmailSetup setup;
  const BoEmailTemplateScreen({super.key, this.template, required this.setup});

  @override
  State<BoEmailTemplateScreen> createState() => _BoEmailTemplateScreenState();
}

class _BoEmailTemplateScreenState extends State<BoEmailTemplateScreen> {
  late final _name = TextEditingController(text: widget.template?.name ?? '');
  late final _subject = TextEditingController(text: widget.template?.subject ?? '');
  late final _body = TextEditingController(text: widget.template?.body ?? '');
  final _subjectFocus = FocusNode();
  final _bodyFocus = FocusNode();
  late TextEditingController _target = _body;
  late bool _default = widget.template != null && widget.setup.defaults.templateId == widget.template!.id;
  bool _busy = false;
  bool _previewing = false;

  BoEmailTemplate? get _t => widget.template;

  @override
  void initState() {
    super.initState();
    _subjectFocus.addListener(() {
      if (_subjectFocus.hasFocus) _target = _subject;
    });
    _bodyFocus.addListener(() {
      if (_bodyFocus.hasFocus) _target = _body;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    _body.dispose();
    _subjectFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  bool get _editable {
    final t = _t;
    if (t == null) return true;
    final access = context.read<AuthProvider>().bookOrbitAdmin;
    if (t.isSystem) return access?.isSuperuser == true;
    return t.ownerId != null && '${t.ownerId}' == access?.userId;
  }

  void _insert(String key) {
    final c = _target;
    final token = '{{$key}}';
    final sel = c.selection;
    final text = c.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    c.value = TextEditingValue(
      text: text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    final name = _name.text.trim();
    if (name.isEmpty || _subject.text.trim().isEmpty) {
      showOverlayToast(context, l.boEmailTemplateRequired, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _busy = true);
    try {
      var id = _t?.id;
      if (_editable) {
        id = (await api.emailSaveTemplate(_t?.id, name: name, subject: _subject.text, body: _body.text)).id;
      }
      final wasDefault = _t != null && widget.setup.defaults.templateId == _t!.id;
      if (_default != wasDefault && id != null) await api.emailSetDefaults(templateId: _default ? id : null);
      if (!mounted) return;
      showOverlayToast(context, l.boAdminSaved, icon: Icons.check_circle_outline_rounded);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    if (api == null) return;
    setState(() => _previewing = true);
    try {
      final recent = await api.emailHistory(size: 10);
      final bookId = recent.where((e) => e.bookId != null).firstOrNull?.bookId;
      if (!mounted) return;
      if (bookId == null) {
        showOverlayToast(context, l.boEmailTemplatePreviewNone, icon: Icons.info_outline_rounded);
        return;
      }
      final p = await api.emailPreviewTemplate(subject: _subject.text, body: _body.text, bookId: bookId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(p.subject),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              SelectableText(p.body),
              if (p.attachment != null) ...[
                const SizedBox(height: 12),
                Text(l.boEmailTemplateAttached(p.attachment!),
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              ],
            ]),
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l.done))],
        ),
      );
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final api = boAdminApi(context);
    final t = _t;
    if (api == null || t == null) return;
    if (!await _confirmDelete(context, t.name, l.boEmailTemplateDeleteBody) || !mounted) return;
    try {
      await api.emailDeleteTemplate(t.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final editable = _editable;
    final groups = {
      l.boEmailVarBook: boTemplateVariables['book']!,
      l.boEmailVarFile: boTemplateVariables['file']!,
      l.boEmailVarOther: boTemplateVariables['other']!,
    };

    return _EditorPage(
      title: _t?.name ?? l.boEmailNewTemplate,
      busy: _busy,
      onSave: _save,
      children: [
        BoEmailSection(children: [
          if (_t?.isSystem == true && !editable) _hint(context, l.boEmailTemplateBuiltIn, color: cs.primary),
          TextField(controller: _name, enabled: editable, decoration: InputDecoration(labelText: l.boEmailName)),
          const SizedBox(height: 8),
          TextField(
            controller: _subject,
            focusNode: _subjectFocus,
            enabled: editable,
            decoration: InputDecoration(labelText: l.boEmailTemplateSubject),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            focusNode: _bodyFocus,
            enabled: editable,
            minLines: 6,
            maxLines: 16,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(labelText: l.boEmailTemplateMessage, alignLabelWithHint: true),
          ),
          _hint(context, l.boEmailTemplateKindleNote),
        ]),
        if (editable)
          BoEmailSection(title: l.boEmailTemplateInsert, hint: l.boEmailTemplateInsertHint, children: [
            for (final g in groups.entries) ...[
              _label(context, g.key),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final v in g.value)
                  ActionChip(label: Text(v), visualDensity: VisualDensity.compact, onPressed: () => _insert(v)),
              ]),
            ],
          ]),
        BoEmailSection(children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: _previewing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.preview_rounded),
            title: Text(l.boEmailTemplatePreview),
            onTap: _previewing ? null : _preview,
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(l.boEmailBadgeDefault),
            value: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
          if (_t != null && !_t!.isSystem && editable) _dangerTile(context, l.boEmailTemplateDelete, _delete),
        ]),
      ],
    );
  }
}
