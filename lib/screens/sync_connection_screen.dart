import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_sync_service.dart';
import '../widgets/overlay_toast.dart';

/// Where the WebDAV folder lives and how to sign in. Split off the main backup
/// and sync screen because these four fields are filled in once and then never
/// touched, so they do not deserve permanent space above the controls people
/// actually use.
class SyncConnectionScreen extends StatefulWidget {
  const SyncConnectionScreen({super.key});

  @override
  State<SyncConnectionScreen> createState() => _SyncConnectionScreenState();
}

class _SyncConnectionScreenState extends State<SyncConnectionScreen> {
  final _sync = SettingsSyncService();
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _headersCtrl = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _headersCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = await _sync.getUrl();
    final user = await _sync.getUsername();
    final pass = await _sync.getPassword();
    final headers = await _sync.getCustomHeaders();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = url ?? '';
      _userCtrl.text = user ?? '';
      _passCtrl.text = pass ?? '';
      _headersCtrl.text = SettingsSyncService.headerLines(headers);
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _sync.setUrl(_urlCtrl.text);
    await _sync.setUsername(_userCtrl.text);
    await _sync.setPassword(_passCtrl.text);
    await _sync.setCustomHeaders(
      SettingsSyncService.parseHeaderLines(_headersCtrl.text),
    );
  }

  String _describe(AppLocalizations l, SyncResult r) {
    switch (r.status) {
      case SyncStatus.ok:
        return l.syncSettingsOk;
      case SyncStatus.noRemote:
        return l.syncSettingsNoRemote;
      case SyncStatus.authFailed:
        return l.syncSettingsAuthFailed;
      case SyncStatus.notConfigured:
        return l.syncSettingsNotConfigured;
      case SyncStatus.tooLarge:
        return l.syncSettingsTooLarge;
      case SyncStatus.network:
        return l.syncSettingsNetworkError;
    }
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    await _persist();
    final result = await _sync.testConnection();
    if (!mounted) return;
    setState(() => _busy = false);
    final good = result.ok || result.status == SyncStatus.noRemote;
    if (!good && result.detail != null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline_rounded),
          title: Text(_describe(l, result)),
          content: SingleChildScrollView(
            child: SelectableText(
              result.detail!,
              style: Theme.of(ctx)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.ok),
            ),
          ],
        ),
      );
      return;
    }
    showOverlayToast(
      context,
      _describe(l, result),
      icon: good
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.syncSettingsConnection)),
      // Save on the way out so a filled-in field is never lost to a back tap.
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _persist();
        },
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  TextField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l.syncSettingsServerUrl,
                      hintText: l.syncSettingsServerUrlHint,
                      hintMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _userCtrl,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l.syncSettingsUsername,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l.syncSettingsPassword,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _headersCtrl,
                    autocorrect: false,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l.syncSettingsHeaders,
                      hintText: l.syncSettingsHeadersHint,
                      hintMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: Text(l.syncSettingsTest),
                    onPressed: _busy ? null : _test,
                  ),
                  const SizedBox(height: 24),
                  // Named as an example, not a requirement - this is plain
                  // WebDAV and works against anything that speaks it.
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Icon(Icons.cloud_queue_rounded,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(l.syncSettingsNeedServer),
                      subtitle: Text(
                        l.syncSettingsNeedServerSub,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                      ),
                      trailing: Icon(Icons.open_in_new_rounded,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onTap: () => launchUrl(
                          Uri.parse('https://nextcloud.com/install/'),
                          mode: LaunchMode.externalApplication),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
