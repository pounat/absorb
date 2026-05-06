import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/equalizer_service.dart';

/// Show the equalizer & audio enhancements bottom sheet.
///
/// [itemId] and [itemTitle] identify which card the sheet was opened from;
/// in per-book EQ mode, the sheet uses them to show whether the displayed
/// EQ belongs to that card's book or to whatever is currently playing.
void showEqualizerSheet(BuildContext context, Color accent, {String? itemId, String? itemTitle}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.05, snap: true,
      maxChildSize: 0.92,
      builder: (ctx, sc) => _EqualizerSheetContent(
        accent: accent,
        scrollController: sc,
        openedForItemId: itemId,
        openedForItemTitle: itemTitle,
      ),
    ),
  );
}

class _EqualizerSheetContent extends StatefulWidget {
  final Color accent;
  final ScrollController scrollController;
  final String? openedForItemId;
  final String? openedForItemTitle;
  const _EqualizerSheetContent({
    required this.accent,
    required this.scrollController,
    this.openedForItemId,
    this.openedForItemTitle,
  });

  @override
  State<_EqualizerSheetContent> createState() => _EqualizerSheetContentState();
}

class _EqualizerSheetContentState extends State<_EqualizerSheetContent> {
  final _eq = EqualizerService();

  // Preview mode: the sheet was opened from a card whose book isn't currently
  // playing. We load that item's saved EQ into local state, render from it,
  // and write edits back to that item's storage without touching the platform
  // (which is still applying the playing book's EQ).
  bool _previewMode = false;
  bool _previewLoaded = false;
  bool _pEnabled = false;
  String _pPreset = 'flat';
  List<double> _pBands = [];
  double _pBass = 0.0, _pVirt = 0.0, _pLoud = 0.0;
  bool _pMono = false;
  bool _pSkipSilence = false;

  @override
  void initState() {
    super.initState();
    _eq.addListener(_rebuild);
    if (!_eq.available) _eq.init();
    _syncPreviewMode();
  }

  @override
  void dispose() {
    _eq.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    _syncPreviewMode();
    setState(() {});
  }

  void _syncPreviewMode() {
    final shouldPreview = _eq.perItem
        && widget.openedForItemId != null
        && widget.openedForItemId != _eq.currentItemId;
    if (shouldPreview && !_previewMode) {
      _previewMode = true;
      _previewLoaded = false;
      // Seed the buffer so the UI has a valid shape (correct band count)
      // until loadItemSnapshot returns. These defaults get overwritten
      // once the real saved snapshot loads.
      _pBands = List<double>.filled(_eq.bandLevels.length, 0.0);
      _pEnabled = false;
      _pPreset = 'flat';
      _pBass = 0.0;
      _pVirt = 0.0;
      _pLoud = 0.0;
      _pMono = false;
      _pSkipSilence = false;
      _loadPreview();
    } else if (!shouldPreview && _previewMode) {
      _previewMode = false;
      _previewLoaded = false;
    }
  }

  Future<void> _loadPreview() async {
    final id = widget.openedForItemId;
    if (id == null) return;
    final snap = await _eq.loadItemSnapshot(id);
    if (!mounted) return;
    setState(() {
      _pEnabled = snap['enabled'] as bool;
      _pPreset = snap['preset'] as String;
      _pBass = snap['bassBoost'] as double;
      _pVirt = snap['virtualizer'] as double;
      _pLoud = snap['loudnessGain'] as double;
      _pMono = snap['mono'] as bool;
      _pSkipSilence = snap['skipSilence'] as bool? ?? false;
      _pBands = List<double>.from((snap['bands'] as List).cast<double>());
      _previewLoaded = true;
    });
  }

  Future<void> _savePreview() async {
    final id = widget.openedForItemId;
    if (id == null) return;
    await _eq.saveItemSnapshot(id, {
      'enabled': _pEnabled,
      'preset': _pPreset,
      'bassBoost': _pBass,
      'virtualizer': _pVirt,
      'loudnessGain': _pLoud,
      'mono': _pMono,
      'skipSilence': _pSkipSilence,
      'bands': _pBands,
    });
  }

  // Branching getters - read from preview buffer when previewing, else service.
  bool get _vEnabled => _previewMode ? _pEnabled : _eq.enabled;
  String get _vPreset => _previewMode ? _pPreset : _eq.activePreset;
  List<double> get _vBands => _previewMode ? _pBands : _eq.bandLevels;
  double get _vBass => _previewMode ? _pBass : _eq.bassBoost;
  double get _vVirt => _previewMode ? _pVirt : _eq.virtualizer;
  double get _vLoud => _previewMode ? _pLoud : _eq.loudnessGain;
  bool get _vMono => _previewMode ? _pMono : _eq.mono;
  bool get _vSkipSilence => _previewMode ? _pSkipSilence : _eq.skipSilence;

  void _setEnabled(bool v) {
    if (_previewMode) {
      setState(() => _pEnabled = v);
      _savePreview();
    } else {
      _eq.setEnabled(v);
    }
  }

  void _applyPreset(String name) {
    if (_previewMode) {
      final curve = EqualizerService.presets[name];
      if (curve == null) return;
      setState(() {
        _pPreset = name;
        for (int i = 0; i < _pBands.length; i++) {
          final idx = (i * curve.length / _pBands.length).floor().clamp(0, curve.length - 1);
          _pBands[i] = curve[idx].clamp(_eq.minLevel, _eq.maxLevel);
        }
      });
      _savePreview();
    } else {
      _eq.applyPreset(name);
    }
  }

  void _setBand(int i, double v) {
    if (_previewMode) {
      if (i < 0 || i >= _pBands.length) return;
      setState(() {
        _pBands[i] = v.clamp(_eq.minLevel, _eq.maxLevel);
        _pPreset = 'custom';
      });
      _savePreview();
    } else {
      _eq.setBandLevel(i, v);
    }
  }

  void _setBass(double v) {
    if (_previewMode) {
      setState(() => _pBass = v.clamp(0.0, 1.0));
      _savePreview();
    } else {
      _eq.setBassBoost(v);
    }
  }

  void _setVirt(double v) {
    if (_previewMode) {
      setState(() => _pVirt = v.clamp(0.0, 1.0));
      _savePreview();
    } else {
      _eq.setVirtualizer(v);
    }
  }

  void _setLoud(double v) {
    if (_previewMode) {
      setState(() => _pLoud = v.clamp(0.0, 1.0));
      _savePreview();
    } else {
      _eq.setLoudnessGain(v);
    }
  }

  void _setMono(bool v) {
    if (_previewMode) {
      setState(() => _pMono = v);
      _savePreview();
    } else {
      _eq.setMono(v);
    }
  }

  void _setSkipSilence(bool v) {
    if (_previewMode) {
      setState(() => _pSkipSilence = v);
      _savePreview();
    } else {
      _eq.setSkipSilence(v);
    }
  }

  void _resetAll() {
    if (_previewMode) {
      setState(() {
        _pPreset = 'flat';
        _pBands = List<double>.filled(_pBands.length, 0.0);
        _pBass = 0.0;
        _pVirt = 0.0;
        _pLoud = 0.0;
        _pMono = false;
        _pSkipSilence = false;
      });
      _savePreview();
    } else {
      _eq.resetAll();
    }
  }

  String _presetLabel(AppLocalizations l, String name) {
    switch (name) {
      case 'flat': return l.equalizerPresetFlat;
      case 'voice boost': return l.equalizerPresetVoiceBoost;
      case 'bass boost': return l.equalizerPresetBassBoost;
      case 'treble boost': return l.equalizerPresetTrebleBoost;
      case 'podcast': return l.equalizerPresetPodcast;
      case 'audiobook': return l.equalizerPresetAudiobook;
      case 'reduce noise': return l.equalizerPresetReduceNoise;
      case 'loudness': return l.equalizerPresetLoudness;
      default: return name[0].toUpperCase() + name.substring(1);
    }
  }

  /// Shown only in preview mode (per-book EQ on, viewing a non-playing book's
  /// settings). The sliders already reflect the correct book's EQ, but we
  /// still surface the fact that edits won't hit live playback right now.
  Widget _buildScopeBanner(ColorScheme cs, TextTheme tt, Color accent, AppLocalizations l) {
    if (!_previewMode) return const SizedBox.shrink();

    final message = widget.openedForItemTitle != null
        ? l.equalizerEditingSavedNamed(widget.openedForItemTitle!)
        : l.equalizerEditingSavedGeneric;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(Icons.edit_note_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.75), height: 1.3)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final accent = widget.accent;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.2), width: 1)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header with toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.equalizer_rounded, size: 22, color: accent),
                const SizedBox(width: 10),
                Text(l.audioEnhancements, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                const Spacer(),
                // Master toggle
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _vEnabled,
                    activeTrackColor: accent,
                    onChanged: (v) => _setEnabled(v),
                  ),
                ),
              ],
            ),
          ),
          // Per-book EQ toggle - lives up top so users can tell at a glance
          // whether EQ is per-book or global, and flip it without scrolling.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: GestureDetector(
              onTap: () => _eq.setPerItem(!_eq.perItem),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _eq.perItem ? accent.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _eq.perItem ? accent.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08)),
                ),
                child: Row(children: [
                  Icon(Icons.library_music_rounded, size: 16,
                    color: _eq.perItem ? accent : cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.equalizerPerBookEq,
                      style: tt.labelMedium?.copyWith(
                        color: _eq.perItem ? accent : cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600)),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: _eq.perItem,
                      activeTrackColor: accent,
                      onChanged: (v) => _eq.setPerItem(v),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          _buildScopeBanner(cs, tt, accent, l),
          const SizedBox(height: 4),
          // Content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                // ── Presets ──
                Text(l.presets, style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.3), letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: EqualizerService.presets.keys.map((name) {
                    final isActive = _vPreset == name;
                    return GestureDetector(
                      onTap: _vEnabled ? () => _applyPreset(name) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? accent.withValues(alpha: 0.2) : cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? accent.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          _presetLabel(l, name),
                          style: TextStyle(
                            color: _vEnabled
                                ? (isActive ? accent : cs.onSurface.withValues(alpha: 0.7))
                                : cs.onSurface.withValues(alpha: 0.24),
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_vPreset == 'custom')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: _vEnabled ? () => _applyPreset('flat') : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withValues(alpha: 0.5)),
                        ),
                        child: Text(l.custom, style: TextStyle(
                          color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // ── EQ Bands ──
                Text(l.equalizer, style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.3), letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(_vBands.length, (i) {
                      return Expanded(
                        child: _EQBandSlider(
                          frequency: i < _eq.bandFrequencies.length ? _eq.bandFrequencies[i] : 0,
                          level: _vBands[i],
                          minLevel: _eq.minLevel,
                          maxLevel: _eq.maxLevel,
                          accent: accent,
                          enabled: _vEnabled,
                          onChanged: (v) => _setBand(i, v),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Audio Effects ──
                Text(l.effects, style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.3), letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                // Bass Boost
                _EffectRow(
                  icon: Icons.speaker_rounded,
                  label: l.bassBoost,
                  value: _vBass,
                  accent: accent,
                  enabled: _vEnabled,
                  onChanged: (v) => _setBass(v),
                ),
                const SizedBox(height: 8),

                // Virtualizer (Android only - no iOS equivalent)
                if (Platform.isAndroid) ...[
                  _EffectRow(
                    icon: Icons.surround_sound_rounded,
                    label: l.surround,
                    value: _vVirt,
                    accent: accent,
                    enabled: _vEnabled,
                    onChanged: (v) => _setVirt(v),
                  ),
                  const SizedBox(height: 8),
                ],

                // Loudness
                _EffectRow(
                  icon: Icons.volume_up_rounded,
                  label: l.loudness,
                  value: _vLoud,
                  accent: accent,
                  enabled: _vEnabled,
                  onChanged: (v) => _setLoud(v),
                ),
                const SizedBox(height: 8),

                // Mono toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.headphones_rounded, size: 18,
                        color: _vMono ? accent.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.monoAudio, style: TextStyle(
                          color: _vMono ? cs.onSurface.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.24),
                          fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _vMono,
                          activeTrackColor: accent,
                          onChanged: (v) => _setMono(v),
                        ),
                      ),
                    ],
                  ),
                ),

                // Skip silence (Android only - just_audio's setSkipSilenceEnabled
                // is a no-op on iOS).
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.fast_forward_rounded, size: 18,
                          color: _vSkipSilence ? accent.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l.skipSilence, style: TextStyle(
                            color: _vSkipSilence ? cs.onSurface.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.24),
                            fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _vSkipSilence,
                            activeTrackColor: accent,
                            onChanged: (v) => _setSkipSilence(v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Reset button
                Center(
                  child: TextButton.icon(
                    onPressed: _vEnabled ? () => _resetAll() : null,
                    icon: Icon(Icons.refresh_rounded, size: 18,
                      color: _vEnabled ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.12)),
                    label: Text(l.resetAll, style: TextStyle(
                      color: _vEnabled ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.12),
                      fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── EQ Band Vertical Slider ──

class _EQBandSlider extends StatelessWidget {
  final int frequency;
  final double level;
  final double minLevel;
  final double maxLevel;
  final Color accent;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _EQBandSlider({
    required this.frequency,
    required this.level,
    required this.minLevel,
    required this.maxLevel,
    required this.accent,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final eq = EqualizerService();
    final label = eq.freqLabel(frequency);
    return Column(
      children: [
        Text('${level >= 0 ? "+" : ""}${level.toStringAsFixed(0)}',
          style: TextStyle(
            color: enabled ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.2),
            fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: enabled ? accent : cs.onSurface.withValues(alpha: 0.24),
                inactiveTrackColor: cs.onSurface.withValues(alpha: 0.08),
                thumbColor: enabled ? accent : cs.onSurface.withValues(alpha: 0.3),
                overlayColor: accent.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: level,
                min: minLevel,
                max: maxLevel,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          color: enabled ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.15),
          fontSize: 10, fontWeight: FontWeight.w500)),
        Text(eq.freqName(frequency), style: TextStyle(
          color: enabled ? cs.onSurfaceVariant.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.1),
          fontSize: 9, fontWeight: FontWeight.w400)),
      ],
    );
  }
}

// ── Effect Row with slider ──

class _EffectRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color accent;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _EffectRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: enabled ? accent.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(
              color: enabled ? cs.onSurface.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.24),
              fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: enabled ? accent : cs.onSurface.withValues(alpha: 0.24),
                inactiveTrackColor: cs.onSurface.withValues(alpha: 0.06),
                thumbColor: enabled ? accent : cs.onSurface.withValues(alpha: 0.3),
                overlayColor: accent.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('${(value * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: enabled ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.15),
                fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
