import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/library_provider.dart';
import '../services/backup_service.dart';
import '../services/settings_sync_service.dart';
import '../widgets/overlay_toast.dart';
import 'sync_connection_screen.dart';

/// Backup and sync in one place. They were separate screens, but a backup taken
/// with login info is what sets sync up on a second phone - a relationship
/// neither screen could explain while they sat apart.
class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  final _sync = SettingsSyncService();

  bool _enabled = false;
  bool _loading = true;
  bool _busy = false;
  bool _syncRmab = false;
  DateTime? _lastSynced;
  String _connectionSummary = '';

  /// Set when the last sync attempt from this screen failed, so the status
  /// banner can say so instead of showing a stale success time.
  String? _lastProblem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _sync.getEnabled();
    final url = await _sync.getUrl();
    final user = await _sync.getUsername();
    final rmab = await _sync.getSyncRmab();
    final last = await _sync.getLastSyncTime();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _syncRmab = rmab;
      _lastSynced = last;
      _connectionSummary = _summarise(url, user);
      _loading = false;
    });
  }

  static String _summarise(String? url, String? user) {
    if (url == null || url.trim().isEmpty) return '';
    final host = Uri.tryParse(url.trim())?.host ?? url.trim();
    return (user == null || user.isEmpty) ? host : '$host  ·  $user';
  }

  String _timeAgo(AppLocalizations l, DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return l.justNow.toLowerCase();
    if (d.inMinutes < 60) return l.minutesAgo(d.inMinutes);
    if (d.inHours < 24) return l.hoursAgo(d.inHours);
    return l.daysAgo(d.inDays);
  }

  String _describe(AppLocalizations l, SyncResult r) {
    switch (r.status) {
      case SyncStatus.ok:
        return r.message == 'applied'
            ? l.syncSettingsApplied
            : r.message == 'up to date'
                ? l.syncSettingsUpToDate
                : l.syncSettingsOk;
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

  Future<void> _run(Future<SyncResult> Function() action) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final result = await action();
    final last = await _sync.getLastSyncTime();
    if (!mounted) return;
    final good = result.ok || result.status == SyncStatus.noRemote;
    setState(() {
      _busy = false;
      _lastSynced = last;
      _lastProblem = good ? null : _describe(l, result);
    });
    // A failure with diagnostics gets a dialog rather than a toast: the useful
    // part is the status line and the exception, which a toast truncates and
    // nobody can copy out of.
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

  Future<void> _downloadNow() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.download_rounded),
        title: Text(l.syncSettingsDownloadWarnTitle),
        content: Text(l.syncSettingsDownloadWarnBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.syncSettingsDownloadWarnConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _sync.pull(force: true));
  }

  void _backupSettings(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.shield_rounded),
        title: Text(l.includeLoginInfoTitle),
        content: Text(l.includeLoginInfoContent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performBackup(context, includeAccounts: false);
            },
            child: Text(l.noSettingsOnly),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performBackup(context, includeAccounts: true);
            },
            child: Text(l.yesIncludeAccounts),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup(BuildContext context, {required bool includeAccounts}) async {
    final l = AppLocalizations.of(context)!;
    try {
      final data = await BackupService.exportSettings(includeAccounts: includeAccounts);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final now = DateTime.now();
      final datePart = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'absorb_backup_$datePart.absorb';

      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final result = await FilePicker.platform.saveFile(
        dialogTitle: l.saveAbsorbBackup,
        fileName: fileName,
        type: FileType.any,
        bytes: bytes,
      );

      if (result != null) {
        // Desktop platforms need manual file write; mobile writes via bytes param
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          await File(result).writeAsString(jsonStr);
        }
        if (mounted) {
          showOverlayToast(
            context,
            includeAccounts
                ? l.backupSavedWithAccounts
                : l.backupSavedSettingsOnly,
            icon: Icons.check_circle_outline_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showOverlayToast(context, l.backupFailed(e.toString()),
            icon: Icons.error_outline_rounded);
      }
    }
  }

  Future<void> _restoreSettings(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data['version'] == null) {
        if (mounted) {
          showOverlayToast(context, l.invalidBackupFile,
              icon: Icons.error_outline_rounded);
        }
        return;
      }

      if (!mounted) return;

      final accounts = data['accounts'] as List<dynamic>?;
      final hasAccounts = accounts != null && accounts.isNotEmpty;
      final hasCustomHeaders = data['customHeaders'] != null;
      final createdAt = data['createdAt'] as String?;
      final appVersion = data['appVersion'] as String?;

      String details = '';
      if (appVersion != null) details += l.fromAbsorbVersion(appVersion);
      if (createdAt != null) {
        final dt = DateTime.tryParse(createdAt);
        if (dt != null) {
          details += details.isEmpty ? '' : l.backupDetailsSeparator;
          details += l.backupDateFormat(dt.month, dt.day, dt.year);
        }
      }

      final cs = Theme.of(context).colorScheme;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.restore_rounded),
          title: Text(l.restoreBackupTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.restoreBackupContent),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(details, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
              if (hasAccounts || hasCustomHeaders) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasAccounts)
                      _restoreChip(Icons.people_rounded, l.restoreAccountsChip(accounts.length), cs),
                    if (hasCustomHeaders)
                      _restoreChip(Icons.vpn_key_rounded, l.restoreCustomHeadersChip, cs),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.restore),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await BackupService.importSettings(data);

      // Apply theme immediately
      final settings = data['settings'] as Map<String, dynamic>?;
      final theme = settings?['themeMode'] as String?;
      if (theme != null) {
        applyThemeMode(theme);
      }
      if (settings?['flatBackground'] is bool) applyFlatBackground(settings!['flatBackground'] as bool);
      if (settings?['colorSource'] is String) applyColorSource(settings!['colorSource'] as String);
      if (settings?['manualSeedColor'] is int) applyManualSeed(settings!['manualSeedColor'] as int);
      if (settings?['gradientIntensity'] is num) applyGradientIntensity((settings!['gradientIntensity'] as num).toDouble());
      if (settings?['useColorEverywhere'] is bool) applyUseColorEverywhere(settings!['useColorEverywhere'] as bool);
      await applyOrientationLock();

      // The provider caches these lists in memory at account load, so without
      // a reload it keeps serving the pre-restore copy - and the next absorbing
      // change writes that stale copy back over what was just restored.
      if (mounted) {
        await context.read<LibraryProvider>().reloadPrefsBackedState();
      }

      // Refresh UI
      await _load();

      if (mounted) {
        showOverlayToast(context, l.settingsRestoredSuccessfully,
            icon: Icons.check_circle_outline_rounded);
      }

      await _sync.resolveSourceAfterRestore();
      await _load();
    } catch (e) {
      if (mounted) {
        showOverlayToast(context, l.restoreFailed(e.toString()),
            icon: Icons.error_outline_rounded);
      }
    }
  }

  Widget _restoreChip(IconData icon, String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: cs.primary)),
      ]),
    );
  }

  Widget _statusBanner(AppLocalizations l, ColorScheme cs, TextTheme tt) {
    final problem = _lastProblem;
    final Color bg;
    final Color fg;
    final IconData icon;
    final String title;
    String? detail;

    if (!_enabled) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurfaceVariant;
      icon = Icons.cloud_off_rounded;
      title = l.syncSettingsStatusOff;
    } else if (problem != null) {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
      icon = Icons.cloud_off_rounded;
      title = l.syncSettingsStatusProblem;
      detail = problem;
    } else {
      bg = cs.secondaryContainer;
      fg = cs.onSecondaryContainer;
      icon = Icons.cloud_done_rounded;
      final at = _lastSynced;
      title = at == null
          ? l.syncSettingsNever
          : l.syncSettingsLastSynced(_timeAgo(l, at));
      detail = _connectionSummary.isEmpty ? null : _connectionSummary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: tt.bodyMedium
                    ?.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                detail,
                style: tt.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.backupAndSync)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _statusBanner(l, cs, tt),
                const SizedBox(height: 22),

                Text(l.syncSettingsBackupFile,
                    style: tt.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  // The "sets sync up on the other phone" half is only true
                  // when sync is actually on, and reads as a puzzle otherwise.
                  _enabled
                      ? l.syncSettingsBackupFileWithSync
                      : l.syncSettingsBackupFilePlain,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: Text(l.backUp),
                      onPressed: () => _backupSettings(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(l.restore),
                      onPressed: () => _restoreSettings(context),
                    ),
                  ),
                ]),

                const SizedBox(height: 26),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.syncSettings,
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    l.syncSettingsSubtitle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  value: _enabled,
                  onChanged: _busy
                      ? null
                      : (v) async {
                          await _sync.setEnabled(v);
                          if (!mounted) return;
                          setState(() => _enabled = v);
                        },
                ),

                // Shown whether sync is on or off: someone deciding whether to
                // turn it on is exactly who needs to read it.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.science_outlined,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.syncSettingsExperimental,
                                style: tt.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              l.syncSettingsExperimentalBody,
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_enabled) ...[
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Icon(Icons.dns_rounded, color: cs.primary),
                      title: Text(l.syncSettingsConnection),
                      subtitle: Text(
                        _connectionSummary.isEmpty
                            ? l.syncSettingsConnectionNotSet
                            : _connectionSummary,
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SyncConnectionScreen()),
                        );
                        await _load();
                      },
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.syncSettingsIncludeRmab),
                    subtitle: Text(
                      l.syncSettingsIncludeRmabSub,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    value: _syncRmab,
                    onChanged: _busy
                        ? null
                        : (v) async {
                            await _sync.setSyncRmab(v);
                            if (!mounted) return;
                            setState(() => _syncRmab = v);
                          },
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(l.syncSettingsUploadNow),
                        onPressed: _busy ? null : () => _run(_sync.push),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon:
                            const Icon(Icons.cloud_download_rounded, size: 18),
                        label: Text(l.syncSettingsDownloadNow),
                        onPressed: _busy ? null : _downloadNow,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Text(
                    l.syncSettingsWhatTravels,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
    );
  }
}
