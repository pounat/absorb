import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/mtls_service.dart';

/// Bottom sheet that imports a PKCS#12 client certificate for the active
/// account, or stages one for the server being set up when [stagedForServer] is
/// given. Returns true when a certificate was imported.
Future<bool> showMtlsCertificateSheet(BuildContext context, {String? stagedForServer}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MtlsCertificateSheet(stagedForServer: stagedForServer),
  );
  return result ?? false;
}

class _MtlsCertificateSheet extends StatefulWidget {
  final String? stagedForServer;

  const _MtlsCertificateSheet({required this.stagedForServer});

  @override
  State<_MtlsCertificateSheet> createState() => _MtlsCertificateSheetState();
}

class _MtlsCertificateSheetState extends State<_MtlsCertificateSheet> {
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  Uint8List? _bundle;
  String? _fileName;
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _error = null);
    try {
      // No extension filter: Android has no reliable MIME mapping for .p12/.pfx,
      // so it would hide the very files the user needs. Checked below instead.
      final picked = await FilePicker.platform.pickFiles(withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final name = file.name;
      final lower = name.toLowerCase();
      if (!lower.endsWith('.p12') && !lower.endsWith('.pfx')) {
        if (mounted) setState(() => _error = l.mtlsUnsupportedFile);
        return;
      }
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) setState(() => _error = l.mtlsImportFailedRead);
        return;
      }
      // The picker leaves a copy in a cache directory, which a private key must
      // not sit in. clearTemporaryFiles() is Android-only: on iOS it empties the
      // whole temporary directory, cover-art and audio caches included.
      try {
        if (Platform.isAndroid) {
          await FilePicker.platform.clearTemporaryFiles();
        } else if (file.path != null) {
          await File(file.path!).delete();
        }
      } catch (e) {
        debugPrint('[mTLS] Could not remove the picked file from the cache: $e');
      }
      if (!mounted) return;
      setState(() {
        _bundle = bytes;
        _fileName = name;
      });
      _passwordFocus.requestFocus();
    } catch (_) {
      if (mounted) setState(() => _error = l.mtlsImportFailedRead);
    }
  }

  Future<void> _import() async {
    final bundle = _bundle;
    final fileName = _fileName;
    if (bundle == null || fileName == null) return;
    final l = AppLocalizations.of(context)!;

    setState(() {
      _busy = true;
      _error = null;
    });

    final status = await MtlsService().import(
      bundle: bundle,
      password: _passwordController.text,
      label: fileName,
      stagedForServer: widget.stagedForServer,
    );

    if (!mounted) return;
    if (status == MtlsImportStatus.ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (status) {
        MtlsImportStatus.badPasswordOrFile => l.mtlsImportFailedPassword,
        MtlsImportStatus.storeFailed => l.mtlsImportFailedStore,
        MtlsImportStatus.ok => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final canImport = _bundle != null && !_busy;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(l.mtlsImportTitle, style: tt.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.mtlsImportBody, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_fileName ?? l.mtlsPickFile, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscure,
              enabled: !_busy,
              onSubmitted: (_) => canImport ? _import() : null,
              decoration: InputDecoration(
                labelText: l.mtlsPassword,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 18, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: tt.bodySmall?.copyWith(color: cs.error)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: canImport ? _import : null,
              child: _busy
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.mtlsImport),
            ),
          ],
        ),
      ),
    );
  }
}
