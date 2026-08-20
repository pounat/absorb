import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/player_settings.dart';
import '../services/transcription_service.dart';
import '../widgets/overlay_toast.dart';

/// Advanced > Bookmark transcription settings: opt-in toggle and on-device
/// Whisper model management (download / pick / delete). Everything here runs
/// locally - no audio or text ever leaves the device.
class TranscriptionSettingsScreen extends StatefulWidget {
  const TranscriptionSettingsScreen({super.key});

  @override
  State<TranscriptionSettingsScreen> createState() =>
      _TranscriptionSettingsScreenState();
}

class _TranscriptionSettingsScreenState
    extends State<TranscriptionSettingsScreen> {
  bool _loaded = false;
  bool _enabled = false;
  String _model = 'tiny';
  final Map<TranscriptionModelSize, bool> _downloaded = {};
  TranscriptionModelSize? _downloading;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _enabled = await PlayerSettings.getTranscriptionEnabled();
    _model = await PlayerSettings.getTranscriptionModel();
    for (final s in TranscriptionModelSize.values) {
      _downloaded[s] = await TranscriptionService.instance.isModelDownloaded(s);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _setEnabled(bool v) async {
    setState(() => _enabled = v);
    await PlayerSettings.setTranscriptionEnabled(v);
  }

  Future<void> _selectModel(TranscriptionModelSize size) async {
    final value = size == TranscriptionModelSize.small ? 'small' : 'tiny';
    setState(() => _model = value);
    await PlayerSettings.setTranscriptionModel(value);
  }

  Future<void> _download(TranscriptionModelSize size) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _downloading = size;
      _progress = 0;
    });
    try {
      await TranscriptionService.instance.downloadModel(size, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) {
        setState(() {
          _downloaded[size] = true;
          _downloading = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _downloading = null);
        // Refresh in case a partial file was left behind.
        _downloaded[size] = await TranscriptionService.instance.isModelDownloaded(size);
        if (!mounted) return;
        showOverlayToast(context, l.transcriptionDownloadFailed,
            icon: Icons.error_outline_rounded);
      }
    }
  }

  void _cancelDownload() {
    TranscriptionService.instance.cancelActiveDownload();
  }

  Future<void> _delete(TranscriptionModelSize size) async {
    await TranscriptionService.instance.deleteModel(size);
    if (mounted) setState(() => _downloaded[size] = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final anyDownloaded = _downloaded.values.any((d) => d);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.transcriptionTitle),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(l.transcriptionEnable),
                  subtitle: Text(l.transcriptionEnableSubtitle,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  value: _enabled,
                  onChanged: _setEnabled,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 18, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.transcriptionDisclaimer,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_enabled && !anyDownloaded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l.transcriptionNeedModelHint,
                      style: tt.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(l.transcriptionModelSection,
                      style: tt.titleSmall?.copyWith(color: cs.primary)),
                ),
                _modelTile(
                  size: TranscriptionModelSize.tiny,
                  label: l.transcriptionModelTiny,
                  desc: l.transcriptionModelTinyDesc,
                  cs: cs,
                  tt: tt,
                  l: l,
                ),
                _modelTile(
                  size: TranscriptionModelSize.small,
                  label: l.transcriptionModelSmall,
                  desc: l.transcriptionModelSmallDesc,
                  cs: cs,
                  tt: tt,
                  l: l,
                ),
              ],
            ),
    );
  }

  Widget _modelTile({
    required TranscriptionModelSize size,
    required String label,
    required String desc,
    required ColorScheme cs,
    required TextTheme tt,
    required AppLocalizations l,
  }) {
    final isDownloaded = _downloaded[size] ?? false;
    final isDownloading = _downloading == size;
    final selected = (_model == 'small') == (size == TranscriptionModelSize.small);

    Widget trailing;
    if (isDownloading) {
      trailing = Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, value: _progress > 0 ? _progress : null),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l.cancel,
          onPressed: _cancelDownload,
        ),
      ]);
    } else if (isDownloaded) {
      trailing = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: cs.onSurfaceVariant),
          tooltip: l.delete,
          onPressed: () => _delete(size),
        ),
      ]);
    } else {
      trailing = TextButton.icon(
        icon: const Icon(Icons.download_rounded, size: 18),
        label: Text(l.transcriptionDownload),
        onPressed: _downloading == null ? () => _download(size) : null,
      );
    }

    return RadioListTile<bool>(
      value: true,
      groupValue: selected ? true : null,
      onChanged: isDownloaded ? (_) => _selectModel(size) : null,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(label),
      subtitle: Text(desc,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      secondary: trailing,
    );
  }
}
