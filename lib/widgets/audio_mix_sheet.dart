import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';

/// What each "Mix with other audio" mode does, for the sheet and settings.
String iosAudioMixModeDescription(String mode) => switch (mode) {
      'auto' => 'If music or a video is already playing in another app, the book plays over it. Lock screen controls stay with that app.',
      'always' => 'The book never pauses other apps. Lock screen and headphone controls stay with the other app.',
      _ => "Starting a book pauses other apps' audio",
    };

/// iOS: how the book plays alongside another app's audio - whether it mixes,
/// whether the other app is turned down, and the book's level against it.
void showAudioMixSheet(BuildContext context, Color accent) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AudioMixSheet(accent: accent),
  );
}

class _AudioMixSheet extends StatefulWidget {
  final Color accent;
  const _AudioMixSheet({required this.accent});

  @override
  State<_AudioMixSheet> createState() => _AudioMixSheetState();
}

class _AudioMixSheetState extends State<_AudioMixSheet> {
  bool _loaded = false;
  String _mode = 'off';
  bool _duck = false;
  double _levelDb = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await PlayerSettings.getIosAudioMixMode();
    final duck = await PlayerSettings.getIosAudioMixDuck();
    final level = await PlayerSettings.getIosAudioMixBookLevelDb();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _duck = duck;
      _levelDb = level.clamp(PlayerSettings.iosAudioMixBookLevelMinDb,
          PlayerSettings.iosAudioMixBookLevelMaxDb);
      _loaded = true;
    });
  }

  void _setLevel(double db, {required bool save}) {
    setState(() => _levelDb = db);
    if (save) {
      PlayerSettings.setIosAudioMixBookLevelDb(db);
    } else {
      AudioPlayerService.previewIosBookLevel(db);
    }
  }

  static String _levelLabel(double db) {
    final n = db.round();
    if (n == 0) return 'Normal';
    return n > 0 ? '+$n dB' : '−${-n} dB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = widget.accent;
    final caption = tt.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    const minDb = PlayerSettings.iosAudioMixBookLevelMinDb;
    const maxDb = PlayerSettings.iosAudioMixBookLevelMaxDb;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.2), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 22, color: accent),
              const SizedBox(width: 10),
              Text('Mix with other audio', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Book level ──
          Row(
            children: [
              Text('Book level', style: tt.bodyLarge),
              const Spacer(),
              Text(_levelLabel(_levelDb), style: tt.bodyLarge?.copyWith(color: accent, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: _levelDb,
            min: minDb,
            max: maxDb,
            divisions: (maxDb - minDb).round(),
            activeColor: accent,
            onChanged: _loaded ? (v) => _setLevel(v, save: false) : null,
            onChangeEnd: _loaded ? (v) => _setLevel(v, save: true) : null,
          ),
          Row(
            children: [
              Text('Other app louder', style: caption),
              const Spacer(),
              TextButton(
                onPressed: _loaded && _levelDb.round() != 0 ? () => _setLevel(0, save: true) : null,
                child: const Text('Reset'),
              ),
              const Spacer(),
              Text('Book louder', style: caption),
            ],
          ),
          Text(
            "The phone's volume buttons set the overall level; this sets the book against the other app. "
            'Above Normal the book is boosted, limited so it does not distort.',
            style: caption,
          ),
          const SizedBox(height: 24),

          // ── Mode ──
          Text('When another app is playing', style: tt.bodyLarge),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'off', label: Text('Pause it')),
                ButtonSegment(value: 'auto', label: Text('Auto')),
                ButtonSegment(value: 'always', label: Text('Always mix')),
              ],
              selected: {_mode},
              onSelectionChanged: _loaded
                  ? (v) {
                      setState(() => _mode = v.first);
                      PlayerSettings.setIosAudioMixMode(v.first);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(iosAudioMixModeDescription(_mode), style: caption),
          if (_mode != 'off')
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lower other audio'),
              subtitle: Text(
                _duck ? 'The other app is turned down while the book plays' : 'The other app keeps its volume',
                style: caption),
              value: _duck,
              activeTrackColor: accent,
              onChanged: _loaded
                  ? (v) {
                      setState(() => _duck = v);
                      PlayerSettings.setIosAudioMixDuck(v);
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}
