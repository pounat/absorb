import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/player_settings.dart';
import '../services/transcription_service.dart';
import '../services/lyrics_service.dart';
import '../widgets/overlay_toast.dart';

/// Colors the spoken words can be painted in. Vivid enough to read on the
/// light, sepia and dark reader pages alike, and over cover art.
const _readAlongPalette = [
  0xFFFFC400,
  0xFFFF6D00,
  0xFFFF1744,
  0xFFFF4081,
  0xFFD500F9,
  0xFF2979FF,
  0xFF00B8D4,
  0xFF00C853,
];

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
  double _lyricsFontSize = 16;
  int _lyricsMaxLines = 3;
  bool _lyricsFullCover = true;
  String _readAlongMode = 'word';
  int _readAlongColor = PlayerSettings.defaultReadAlongColor;
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
    _lyricsFontSize = await PlayerSettings.getLyricsFontSize();
    _lyricsMaxLines = await PlayerSettings.getLyricsMaxLines();
    _lyricsFullCover = await PlayerSettings.getLyricsFullCover();
    _readAlongMode = await PlayerSettings.getReadAlongMode();
    _readAlongColor = await PlayerSettings.getReadAlongColor();
    for (final s in TranscriptionModelSize.values) {
      _downloaded[s] = await TranscriptionService.instance.isModelDownloaded(s);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _setEnabled(bool v) async {
    setState(() => _enabled = v);
    await PlayerSettings.setTranscriptionEnabled(v);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.record_voice_over_rounded, size: 18, color: cs.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.transcriptionWhisperInfo,
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => launchUrl(
                                Uri.parse('https://openai.com/index/whisper/'),
                                mode: LaunchMode.externalApplication),
                            child: Text(l.transcriptionWhisperLearnMore),
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
                  size: TranscriptionModelSize.base,
                  label: l.transcriptionModelBase,
                  desc: l.transcriptionModelBaseDesc,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l.transcriptionAutoHint,
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(l.lyricsDisplaySection,
                      style: tt.titleSmall?.copyWith(color: cs.primary)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.battery_alert_rounded, size: 18, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.lyricsBatteryInfo,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  title: Text(l.lyricsFontSize),
                  subtitle: Slider(
                    value: _lyricsFontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    label: _lyricsFontSize.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _lyricsFontSize = v),
                    onChangeEnd: (v) async {
                      await PlayerSettings.setLyricsFontSize(v);
                      await LyricsService.instance.reloadDisplayPrefs();
                    },
                  ),
                  trailing: Text(_lyricsFontSize.toStringAsFixed(0),
                      style: tt.titleMedium),
                ),
                SwitchListTile(
                  title: Text(l.lyricsFullCover),
                  subtitle: Text(l.lyricsFullCoverHint,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  value: _lyricsFullCover,
                  onChanged: (v) async {
                    setState(() => _lyricsFullCover = v);
                    await PlayerSettings.setLyricsFullCover(v);
                    await LyricsService.instance.reloadDisplayPrefs();
                  },
                ),
                // Taking the whole cover fits as many lines as the space
                // allows, so the count only applies to the strip.
                if (!_lyricsFullCover)
                ListTile(
                  title: Text(l.lyricsMaxLines),
                  trailing: SegmentedButton<int>(
                    segments: [
                      for (final n in const [2, 3, 4, 5])
                        ButtonSegment(value: n, label: Text('$n')),
                    ],
                    selected: {_lyricsMaxLines},
                    showSelectedIcon: false,
                    onSelectionChanged: (sel) async {
                      setState(() => _lyricsMaxLines = sel.first);
                      await PlayerSettings.setLyricsMaxLines(sel.first);
                      await LyricsService.instance.reloadDisplayPrefs();
                    },
                  ),
                ),
                ListTile(
                  title: Text(l.readAlongFollow),
                  subtitle: Text(l.readAlongFollowHint,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  trailing: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'word', label: Text(l.readAlongFollowWord)),
                      ButtonSegment(
                          value: 'sentence',
                          label: Text(l.readAlongFollowSentence)),
                    ],
                    selected: {_readAlongMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (sel) async {
                      setState(() => _readAlongMode = sel.first);
                      await PlayerSettings.setReadAlongMode(sel.first);
                      await LyricsService.instance.reloadDisplayPrefs();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(l.readAlongColor, style: tt.bodyLarge),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final c in _readAlongPalette)
                        _colorSwatch(c, cs),
                    ],
                  ),
                ),
              ],
            ),
    );
  }


  Widget _colorSwatch(int argb, ColorScheme cs) {
    final selected = _readAlongColor == argb;
    return GestureDetector(
      onTap: () async {
        setState(() => _readAlongColor = argb);
        await PlayerSettings.setReadAlongColor(argb);
        await LyricsService.instance.reloadDisplayPrefs();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(argb),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? cs.onSurface : cs.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(Icons.check_rounded,
                size: 20,
                color: ThemeData.estimateBrightnessForColor(Color(argb)) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black)
            : null,
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

    return ListTile(
      title: Text(label),
      subtitle: Text(desc,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
      trailing: trailing,
    );
  }

}
