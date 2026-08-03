import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/overlay_toast.dart';

class AdminEmailScreen extends StatefulWidget {
  final List<dynamic> users;
  const AdminEmailScreen({super.key, required this.users});

  @override
  State<AdminEmailScreen> createState() => _AdminEmailScreenState();
}

class _AdminEmailScreenState extends State<AdminEmailScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;

  final _host = TextEditingController();
  final _port = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _fromAddress = TextEditingController();
  final _testAddress = TextEditingController();
  bool _secure = true;
  bool _rejectUnauthorized = true;
  bool _showPass = false;

  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _pass.dispose();
    _fromAddress.dispose();
    _testAddress.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final settings = await api.getEmailSettings();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _host.text = (settings?['host'] as String?) ?? '';
      _port.text = (settings?['port'] as num?)?.toString() ?? '465';
      _secure = settings?['secure'] as bool? ?? true;
      _rejectUnauthorized = settings?['rejectUnauthorized'] as bool? ?? true;
      _user.text = (settings?['user'] as String?) ?? '';
      _pass.text = (settings?['pass'] as String?) ?? '';
      _fromAddress.text = (settings?['fromAddress'] as String?) ?? '';
      _testAddress.text = (settings?['testAddress'] as String?) ?? '';
      final devices = settings?['ereaderDevices'] as List<dynamic>?;
      _devices = devices?.cast<Map<String, dynamic>>().map((d) =>
        Map<String, dynamic>.from(d)).toList() ?? [];
    });
  }

  Map<String, dynamic> _smtpPayload() => {
    'host': _host.text.trim(),
    'port': int.tryParse(_port.text.trim()) ?? 465,
    'secure': _secure,
    'rejectUnauthorized': _rejectUnauthorized,
    'user': _user.text.trim(),
    'pass': _pass.text,
    'fromAddress': _fromAddress.text.trim(),
    'testAddress': _testAddress.text.trim(),
  };

  Future<void> _save() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    final ok = await api.updateEmailSettings(_smtpPayload());
    if (!mounted) return;
    setState(() => _saving = false);
    showOverlayToast(context,
        ok ? l.smtpSaved : l.smtpSaveFailed,
        icon: ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded);
  }

  Future<void> _test() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _testing = true);
    // Save first so the server tests against the values shown on screen.
    final saved = await api.updateEmailSettings(_smtpPayload());
    final ok = saved ? await api.sendTestEmail() : false;
    if (!mounted) return;
    setState(() => _testing = false);
    showOverlayToast(context,
        ok ? l.smtpTestSent : l.smtpTestFailed,
        icon: ok ? Icons.mark_email_read_rounded : Icons.error_outline_rounded);
  }

  Future<void> _saveDevices(List<Map<String, dynamic>> next) async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;
    final ok = await api.updateEReaderDevices(next);
    if (!mounted) return;
    if (ok) {
      setState(() => _devices = next);
      // Push the freshly filtered list into AuthProvider so the book detail
      // sheet's "Send to E-Reader" entry sees changes without a re-login.
      await auth.setEreaderDevices(auth.filterDevicesForCurrentUser(next));
      if (!mounted) return;
      showOverlayToast(context, l.ereaderDevicesSaved,
          icon: Icons.check_circle_outline_rounded);
    } else {
      showOverlayToast(context, l.ereaderDevicesSaveFailed,
          icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _addOrEditDevice([int? index]) async {
    final existing = index != null ? _devices[index] : null;
    final result = await _showDeviceEditor(existing);
    if (result == null) return;
    final next = List<Map<String, dynamic>>.from(_devices);
    if (result['_delete'] == true) {
      if (index != null) next.removeAt(index);
    } else {
      result.remove('_delete');
      if (index != null) {
        next[index] = result;
      } else {
        next.add(result);
      }
    }
    await _saveDevices(next);
  }

  Future<Map<String, dynamic>?> _showDeviceEditor(
      Map<String, dynamic>? existing) async {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] as String? ?? '');
    String availability = (existing?['availabilityOption'] as String?) ?? 'adminOrUp';
    final specificUsers = <String>{
      ...((existing?['users'] as List<dynamic>?) ?? []).cast<String>(),
    };

    return showAdaptiveActionMenu<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      desktopWidth: 560,
      desktopScrollWrap: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16,
                  16 + MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Center(child: Container(width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(2)))),
                  Align(alignment: Alignment.centerLeft, child: Text(
                    existing == null ? l.addEreaderDevice : l.editEreaderDevice,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: l.ereaderDeviceName),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l.ereaderDeviceEmail),
                  ),
                  const SizedBox(height: 20),
                  Align(alignment: Alignment.centerLeft, child: Text(
                    l.ereaderAvailability,
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant))),
                  const SizedBox(height: 8),
                  _availabilityChoices(cs, availability, (v) {
                    setSheet(() => availability = v);
                  }),
                  if (availability == 'specificUsers') ...[
                    const SizedBox(height: 16),
                    Align(alignment: Alignment.centerLeft, child: Text(
                      l.ereaderAvailSpecificUsers,
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant))),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: widget.users.map((u) {
                      final id = u['id'] as String? ?? '';
                      final name = u['username'] as String? ?? id;
                      final selected = specificUsers.contains(id);
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (v) => setSheet(() {
                          if (v) {
                            specificUsers.add(id);
                          } else {
                            specificUsers.remove(id);
                          }
                        }),
                      );
                    }).toList()),
                  ],
                  const SizedBox(height: 24),
                  Row(children: [
                    if (existing != null)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx, {'_delete': true});
                        },
                        icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                        label: Text(l.deleteEreaderDevice,
                            style: TextStyle(color: cs.error)),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        if (name.isEmpty || email.isEmpty) return;
                        Navigator.pop(ctx, <String, dynamic>{
                          'name': name,
                          'email': email,
                          'availabilityOption': availability,
                          'users': availability == 'specificUsers'
                              ? specificUsers.toList()
                              : <String>[],
                        });
                      },
                      child: Text(l.save),
                    ),
                  ]),
                ]),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _availabilityChoices(
      ColorScheme cs, String current, ValueChanged<String> onChange) {
    final l = AppLocalizations.of(context)!;
    final options = <(String, String)>[
      ('adminOrUp', l.ereaderAvailAdminOrUp),
      ('userOrUp', l.ereaderAvailUserOrUp),
      ('guestOrUp', l.ereaderAvailGuestOrUp),
      ('specificUsers', l.ereaderAvailSpecificUsers),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: options.map((opt) {
      final selected = opt.$1 == current;
      return ChoiceChip(
        label: Text(opt.$2),
        selected: selected,
        onSelected: (_) => onChange(opt.$1),
      );
    }).toList());
  }

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
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                  child: Row(children: [
                    Expanded(child: AbsorbPageHeader(
                      title: l.adminEmail, padding: EdgeInsets.zero)),
                    IconButton(icon: Icon(Icons.close_rounded,
                      color: cs.onSurfaceVariant),
                      onPressed: () => Navigator.pop(context)),
                  ]),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      _section(cs, tt, l.smtpSection),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDeco(cs),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => launchUrl(
                                  Uri.parse('https://www.audiobookshelf.org/guides/send_to_ereader/'),
                                  mode: LaunchMode.externalApplication,
                                ),
                                icon: const Icon(Icons.menu_book_rounded, size: 16),
                                label: Text(l.smtpSetupGuide),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(controller: _host,
                              decoration: InputDecoration(labelText: l.smtpHost)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: TextField(
                                controller: _port,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(labelText: l.smtpPort))),
                              const SizedBox(width: 16),
                              Expanded(child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.smtpSecure,
                                    style: tt.bodyMedium),
                                value: _secure,
                                onChanged: (v) => setState(() => _secure = v))),
                            ]),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l.smtpRejectUnauthorized,
                                  style: tt.bodyMedium),
                              value: _rejectUnauthorized,
                              onChanged: (v) => setState(() => _rejectUnauthorized = v),
                            ),
                            TextField(controller: _user,
                              decoration: InputDecoration(labelText: l.smtpUser)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _pass,
                              obscureText: !_showPass,
                              decoration: InputDecoration(
                                labelText: l.smtpPass,
                                suffixIcon: IconButton(
                                  icon: Icon(_showPass
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded),
                                  onPressed: () => setState(() => _showPass = !_showPass),
                                )),
                            ),
                            const SizedBox(height: 12),
                            TextField(controller: _fromAddress,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(labelText: l.smtpFromAddress)),
                            const SizedBox(height: 12),
                            TextField(controller: _testAddress,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(labelText: l.smtpTestAddress)),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(child: OutlinedButton.icon(
                                onPressed: _testing || _saving ? null : _test,
                                icon: _testing
                                  ? const SizedBox(width: 14, height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send_rounded, size: 16),
                                label: Text(l.smtpSendTest))),
                              const SizedBox(width: 12),
                              Expanded(child: FilledButton.icon(
                                onPressed: _saving || _testing ? null : _save,
                                icon: _saving
                                  ? SizedBox(width: 14, height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: cs.onPrimary))
                                  : const Icon(Icons.save_rounded, size: 16),
                                label: Text(l.smtpSaveSettings))),
                            ]),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _section(cs, tt, l.ereaderDevicesTitle),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: _cardDeco(cs),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(children: [
                            if (_devices.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(l.ereaderDevicesEmpty,
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                              ),
                            ..._devices.asMap().entries.map((e) =>
                              _deviceTile(cs, tt, e.key, e.value)),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: () => _addOrEditDevice(),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(l.addEreaderDevice),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
      ),
    );
  }

  Widget _deviceTile(ColorScheme cs, TextTheme tt, int idx, Map<String, dynamic> d) {
    final l = AppLocalizations.of(context)!;
    final name = d['name'] as String? ?? '';
    final email = d['email'] as String? ?? '';
    final availability = d['availabilityOption'] as String? ?? 'adminOrUp';
    final users = (d['users'] as List<dynamic>?)?.length ?? 0;

    final availabilityLabel = switch (availability) {
      'userOrUp' => l.ereaderAvailUserOrUp,
      'guestOrUp' => l.ereaderAvailGuestOrUp,
      'specificUsers' => l.ereaderSpecificUsersN(users),
      _ => l.ereaderAvailAdminOrUp,
    };

    return ListTile(
      leading: Icon(Icons.send_to_mobile_rounded, color: cs.onSurfaceVariant),
      title: Text(name),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(email, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 2),
        Text(availabilityLabel,
          style: tt.labelSmall?.copyWith(color: cs.primary.withValues(alpha: 0.7))),
      ]),
      trailing: Icon(Icons.edit_rounded, size: 18, color: cs.onSurfaceVariant),
      onTap: () => _addOrEditDevice(idx),
    );
  }

  Widget _section(ColorScheme cs, TextTheme tt, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Text(t, style: tt.labelLarge?.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
      fontWeight: FontWeight.w600, letterSpacing: 0.5)));

  BoxDecoration _cardDeco(ColorScheme cs) => BoxDecoration(
    color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16));
}
