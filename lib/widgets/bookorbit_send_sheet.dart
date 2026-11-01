import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../screens/bookorbit_admin_screen.dart';
import '../screens/bookorbit_email_editors.dart';
import '../screens/bookorbit_email_screen.dart';
import '../services/api_service.dart';
import '../services/bookorbit_email.dart';
import '../utils/file_size.dart';
import 'adaptive_modal.dart';

/// Sends a BookOrbit book to the user's devices by email, then follows each
/// email until the mail server takes it or turns it down.
Future<void> showBookOrbitSendSheet(BuildContext context, {required Map<String, dynamic> item, required String title}) {
  return showAdaptiveSheetDialog<void>(
    context: context,
    initialChildSize: 0.75,
    minChildSize: 0.4,
    builder: (ctx, scroll) => _SendBody(item: item, title: title, scroll: scroll),
  );
}

class _SendBody extends StatefulWidget {
  final Map<String, dynamic> item;
  final String title;
  final ScrollController scroll;
  const _SendBody({required this.item, required this.title, required this.scroll});

  @override
  State<_SendBody> createState() => _SendBodyState();
}

class _SendBodyState extends State<_SendBody> {
  static const _pollEvery = Duration(milliseconds: 1500);
  static const _followFor = Duration(seconds: 60);

  BoEmailSetup? _setup;
  late final List<BoSendableFile> _files = boSendableFiles(widget.item);
  late final int? _bookId = int.tryParse('${widget.item['id']}');
  final Set<int> _picked = {};
  String? _format;
  int? _serverId;
  int? _templateId;
  bool _loading = true;
  bool _sending = false;

  // After a send: which devices it went to, the newest email for this book
  // before it, and what has happened to each since.
  List<BoEmailDevice>? _sentTo;
  int _lastIdBefore = 0;
  DateTime? _sentAt;
  final Map<int, BoEmailSend> _deliveries = {};
  Timer? _poll;

  List<String> get _formats => {for (final f in _files) f.format}.toList();

  BoMailServer? get _server {
    for (final s in _setup?.servers ?? const <BoMailServer>[]) {
      if (s.id == _serverId) return s;
    }
    return _setup?.defaultServer;
  }

  @override
  void initState() {
    super.initState();
    _load(first: true);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool first = false, int? select}) async {
    final api = boAdminApi(context);
    final access = context.read<AuthProvider>().bookOrbitAdmin;
    if (api == null || access == null) return;
    try {
      final r = await Future.wait<Object>([
        BoEmailSetup.load(api, canSend: true),
        if (first && _bookId != null) api.emailHistory(bookId: _bookId, size: 1),
      ]);
      final setup = r[0] as BoEmailSetup;
      if (!mounted) return;
      setState(() {
        _setup = setup;
        if (r.length > 1) _lastIdBefore = (r[1] as List<BoEmailSend>).firstOrNull?.id ?? 0;
        final ids = {for (final d in setup.devices) d.id};
        _picked.retainAll(ids);
        if (select != null && ids.contains(select)) {
          _picked.add(select);
        } else if (first) {
          final def = setup.defaults.deviceId;
          if (def != null && ids.contains(def)) {
            _picked.add(def);
          } else if (setup.devices.length == 1) {
            _picked.add(setup.devices.first.id);
          }
        }
        _serverId ??= setup.defaultServer?.id;
      });
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addDevice() async {
    final setup = _setup;
    if (setup == null) return;
    final before = {for (final d in setup.devices) d.id};
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BoEmailDeviceScreen(setup: setup)),
    );
    if (changed != true || !mounted) return;
    await _load();
    final added = _setup?.devices.where((d) => !before.contains(d.id)).firstOrNull;
    if (added != null && mounted) setState(() => _picked.add(added.id));
  }

  Future<void> _addServer() async {
    final setup = _setup;
    if (setup == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BoEmailServerScreen(setup: setup)),
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const BookOrbitEmailScreen()));
    if (mounted && _sentTo == null) await _load();
  }

  BoEmailDevice? get _blockingKindle {
    final f = _format;
    if (f == null || boKindleAccepts(f)) return null;
    return _setup?.devices.where((d) => d.isKindle && _picked.contains(d.id)).firstOrNull;
  }

  int? _fileIdFor(String? format) {
    if (format == null) return null;
    final plain = _files.where((f) => f.format == format && !f.readAlong).firstOrNull;
    return (plain ?? _files.where((f) => f.format == format).firstOrNull)?.id;
  }

  Future<void> _send() async {
    final api = boAdminApi(context);
    final setup = _setup;
    final bookId = _bookId;
    if (api == null || setup == null || bookId == null || _picked.isEmpty || _blockingKindle != null) return;
    setState(() => _sending = true);
    try {
      await api.emailSendBook(
        bookId,
        deviceIds: _picked.toList(),
        serverId: _serverId,
        templateId: _templateId,
        fileId: _fileIdFor(_format),
      );
      if (!mounted) return;
      setState(() {
        _sentTo = setup.devices.where((d) => _picked.contains(d.id)).toList();
        _sentAt = DateTime.now();
      });
      _follow();
    } catch (e) {
      if (mounted) showBoEmailError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _follow() async {
    final api = boAdminApi(context);
    final sentTo = _sentTo;
    final bookId = _bookId;
    if (api == null || sentTo == null || bookId == null) return;
    try {
      final rows = await api.emailHistory(bookId: bookId, size: sentTo.length * 2 + 4);
      if (!mounted) return;
      setState(() {
        for (final d in sentTo) {
          final row = rows
              .where((e) =>
                  e.id > _lastIdBefore &&
                  (e.deviceId == d.id || e.toEmail.toLowerCase() == d.email.toLowerCase()))
              .firstOrNull;
          if (row != null) _deliveries[d.id] = row;
        }
      });
    } catch (_) {
      // Tried again on the next tick; the sheet already says it's sending.
    }
    if (!mounted) return;
    final settled = sentTo.every((d) => _deliveries[d.id] != null && !_deliveries[d.id]!.pending);
    if (!settled && DateTime.now().difference(_sentAt!) < _followFor) {
      _poll = Timer(_pollEvery, _follow);
    } else {
      setState(() {});
    }
  }

  /// What [d] would get, or a warning about it.
  (String, bool)? _plan(AppLocalizations l, BoEmailDevice d) {
    final f = _format;
    if (f != null && d.isKindle && !boKindleAccepts(f)) return (l.boEmailSendKindleRejects(f.toUpperCase()), true);
    final plan = boPlanFile(_files, d, f);
    if (plan == null) return null;
    final file = plan.file;
    final size = file.size != null && file.size! > 0 ? formatFileSize(file.size!) : '';
    final limit = boSizeLimit(file.size, d.deviceType, _server?.host);
    if (limit == BoSizeLimit.kindle) return (l.boEmailSendOverKindle(size), true);
    if (limit == BoSizeLimit.gmail) return (l.boEmailSendOverGmail(size), true);
    if (plan.missingFormat != null) {
      return (l.boEmailSendMissing(plan.missingFormat!.toUpperCase(), file.format.toUpperCase()), false);
    }
    if (file.readAlong) return (l.boEmailSendNarrated(size), false);
    return (size.isEmpty ? file.format.toUpperCase() : l.boEmailSendGets(file.format.toUpperCase(), size), false);
  }

  Widget _deliveryLine(AppLocalizations l, BoEmailDevice d) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final e = _deliveries[d.id];
    final server = _server?.name ?? '';
    if (e == null || e.pending) {
      return Row(children: [
        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
        const SizedBox(width: 8),
        Flexible(child: Text(l.boEmailSendHanding(server), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
      ]);
    }
    if (e.sent) {
      return Text(l.boEmailSendAccepted(server), style: tt.bodySmall?.copyWith(color: Colors.green));
    }
    return Text(l.boEmailSendFailedLine(e.error ?? ''), style: tt.bodySmall?.copyWith(color: cs.error));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final access = context.watch<AuthProvider>().bookOrbitAdmin;
    final setup = _setup;
    final sentTo = _sentTo;

    final children = <Widget>[
      Text(l.sendToEreader, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 16),
    ];

    if (_loading && setup == null) {
      children.add(const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    } else if (setup == null) {
      children.add(BoEmailEmpty(l.boAdminFailed));
    } else if (setup.servers.isEmpty) {
      children.addAll([
        BoEmailEmpty(access?.manageEmail == true ? l.boEmailSendNoServer : '${l.boEmailSendNoServer} ${l.boEmailSendAskAdmin}'),
        if (access?.manageEmail == true)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _addServer,
              icon: const Icon(Icons.add_rounded),
              label: Text(l.boEmailAddServer),
            ),
          ),
      ]);
    } else if (sentTo != null) {
      for (final d in sentTo) {
        children.add(ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(boDeviceIcon(d.deviceType), color: cs.primary),
          title: Text(d.name),
          subtitle: _deliveryLine(l, d),
        ));
      }
      final stillGoing = sentTo.any((d) => _deliveries[d.id]?.pending != false) &&
          _sentAt != null &&
          DateTime.now().difference(_sentAt!) >= _followFor;
      if (stillGoing) children.add(BoEmailEmpty(l.boEmailSendStillGoing));
      children.addAll([
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done)),
      ]);
    } else {
      final groups = setup.groups.where((g) => g.members.isNotEmpty).toList();
      if (setup.devices.isEmpty) children.add(BoEmailEmpty(l.boEmailSendNoDevices));
      for (final d in setup.devices) {
        final plan = _plan(l, d);
        children.add(CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(boDeviceIcon(d.deviceType), color: cs.primary),
          title: Text(d.name),
          subtitle: plan == null
              ? Text(d.email)
              : Text(plan.$1, style: TextStyle(color: plan.$2 ? cs.error : cs.onSurfaceVariant)),
          value: _picked.contains(d.id),
          onChanged: (v) => setState(() => v == true ? _picked.add(d.id) : _picked.remove(d.id)),
        ));
      }
      if (groups.isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Wrap(spacing: 8, runSpacing: 4, children: [
            for (final g in groups)
              FilterChip(
                avatar: const Icon(Icons.groups_rounded, size: 18),
                label: Text(g.name),
                selected: _picked.containsAll(g.memberIds),
                onSelected: (on) => setState(() => on ? _picked.addAll(g.memberIds) : _picked.removeAll(g.memberIds)),
              ),
          ]),
        ));
      }
      children.add(Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _addDevice,
          icon: const Icon(Icons.add_rounded),
          label: Text(l.boEmailAddDevice),
        ),
      ));

      final formats = _formats;
      final showServers = setup.servers.length > 1;
      final showTemplates = setup.templates.length > 1;
      if (formats.length > 1 || showServers || showTemplates) {
        children.add(Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(l.boEmailSendOptions, style: tt.titleSmall),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (formats.length > 1) ...[
                Text(l.boEmailFormat, style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  ChoiceChip(
                    label: Text(l.boEmailSendFormatEach),
                    selected: _format == null,
                    onSelected: (_) => setState(() => _format = null),
                  ),
                  for (final f in formats)
                    ChoiceChip(
                      label: Text(f.toUpperCase()),
                      selected: _format == f,
                      onSelected: (_) => setState(() => _format = f),
                    ),
                ]),
                const SizedBox(height: 12),
              ],
              if (showServers) ...[
                DropdownButtonFormField<int>(
                  initialValue: _server?.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.boEmailSendServer),
                  items: [
                    for (final s in setup.servers)
                      DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _serverId = v),
                ),
                const SizedBox(height: 12),
              ],
              if (showTemplates)
                DropdownButtonFormField<int?>(
                  initialValue: _templateId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.boEmailTemplate),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        setup.defaultTemplate == null
                            ? l.boEmailTemplateYourDefault
                            : '${l.boEmailTemplateYourDefault} (${setup.defaultTemplate!.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final t in setup.templates)
                      DropdownMenuItem<int?>(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _templateId = v),
                ),
            ],
          ),
        ));
      }

      final blocking = _blockingKindle;
      children.addAll([
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _picked.isEmpty || blocking != null || _sending ? null : _send,
          icon: _sending
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
              : const Icon(Icons.send_rounded),
          label: Text(l.boEmailSendButton),
        ),
      ]);
    }

    children.add(Align(
      alignment: Alignment.center,
      child: TextButton(onPressed: _openSettings, child: Text(l.boEmailTitle)),
    ));

    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: children,
    );
  }
}
