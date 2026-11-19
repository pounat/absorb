import 'package:flutter/material.dart';
import 'expressive.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'absorb_page_header.dart';

/// Browses the server filesystem via GET /api/filesystem and returns the chosen
/// absolute directory path (or null if cancelled) through Navigator.pop.
///
/// Navigation uses a history stack rather than path math so "up" works the same
/// on posix servers and Windows drive listings.
class FilesystemPickerScreen extends StatefulWidget {
  const FilesystemPickerScreen({super.key});

  @override
  State<FilesystemPickerScreen> createState() => _FilesystemPickerScreenState();
}

class _FilesystemPickerScreenState extends State<FilesystemPickerScreen> {
  // null = the root listing (drive letters on Windows, '/' children on posix).
  final List<String?> _history = [null];
  List<Map<String, dynamic>> _dirs = [];
  bool _loading = true;

  String? get _current => _history.last;
  bool get _canGoUp => _history.length > 1;

  @override
  void initState() {
    super.initState();
    _browse(null);
  }

  Future<void> _browse(String? path) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _loading = true);
    final result = await api.getFilesystemPaths(path: path);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _dirs = ((result?['directories'] as List?) ?? [])
          .whereType<Map>()
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
    });
  }

  void _enter(String path) {
    _history.add(path);
    _browse(path);
  }

  void _up() {
    if (!_canGoUp) return;
    _history.removeLast();
    _browse(_current);
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
              Expanded(child: AbsorbPageHeader(title: l.fsPickerTitle, padding: EdgeInsets.zero)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(children: [
              Icon(Icons.folder_open_rounded, size: 15, color: cs.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _current ?? l.fsServerRoot,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: AdaptiveSpinner(strokeWidth: 2))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (_canGoUp)
                        ListTile(
                          leading: Icon(Icons.arrow_upward_rounded, color: cs.onSurfaceVariant),
                          title: const Text('..'),
                          onTap: _up,
                        ),
                      if (_dirs.isEmpty && !_canGoUp)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(l.fsEmptyFolder,
                                style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                          ),
                        ),
                      ..._dirs.map((d) => ListTile(
                            leading: Icon(Icons.folder_rounded, color: cs.primary.withValues(alpha: 0.8)),
                            title: Text(d['dirname']?.toString() ?? d['path']?.toString() ?? ''),
                            trailing: Icon(Icons.chevron_right_rounded,
                                color: cs.onSurface.withValues(alpha: 0.2)),
                            onTap: () {
                              final p = d['path']?.toString();
                              if (p != null && p.isNotEmpty) _enter(p);
                            },
                          )),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _current == null ? null : () => Navigator.pop(context, _current),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(l.fsUseThisFolder),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
