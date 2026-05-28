import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'scoped_prefs.dart';

/// Android AudioEffect equalizer bands and presets via platform channels.
/// Falls back gracefully on unsupported devices.
class EqualizerService extends ChangeNotifier {
  static final EqualizerService _instance = EqualizerService._();
  factory EqualizerService() => _instance;
  EqualizerService._();

  static const _channel = MethodChannel('com.absorb.equalizer');

  // ── State ──
  bool _available = false;
  bool _enabled = false;
  String _activePreset = 'flat';
  List<double> _bandLevels = []; // dB values per band
  List<int> _bandFrequencies = []; // center frequencies (Hz)
  double _minLevel = -15.0;
  double _maxLevel = 15.0;
  double _bassBoost = 0.0; // 0.0–1.0
  double _virtualizer = 0.0; // 0.0–1.0
  double _loudnessGain = 0.0; // 0.0–1.0
  bool _mono = false;
  bool _skipSilence = false;
  bool _perItem = false;
  String? _currentItemId;

  /// Applied to the just_audio AudioPlayer whenever skipSilence changes
  /// (toggle, per-book switch, account reload). Registered by
  /// AudioPlayerService.init so the EQ service stays decoupled from
  /// just_audio.
  void Function(bool enabled)? _skipSilenceApplier;

  /// Invoked when [anyProcessingActive] may have changed so the iOS engine can
  /// attach/detach its processing tap. Registered by AudioPlayerService.
  void Function(bool active)? _tapApplier;

  // Built-in presets (EQ curve shapes)
  static const Map<String, List<double>> presets = {
    'flat': [0, 0, 0, 0, 0],
    'voice boost': [2, 4, 5, 3, 1],
    'bass boost': [5, 3, 0, -1, -2],
    'treble boost': [-2, -1, 0, 3, 5],
    'podcast': [3, 5, 4, 2, 0],
    'audiobook': [1, 3, 5, 4, 2],
    'reduce noise': [-3, -1, 0, -1, -3],
    'loudness': [4, 2, 0, 2, 4],
  };

  // Getters
  bool get available => _available;
  bool get enabled => _enabled;
  String get activePreset => _activePreset;
  List<double> get bandLevels => List.unmodifiable(_bandLevels);
  List<int> get bandFrequencies => List.unmodifiable(_bandFrequencies);
  double get minLevel => _minLevel;
  double get maxLevel => _maxLevel;
  double get bassBoost => _bassBoost;
  double get virtualizer => _virtualizer;
  double get loudnessGain => _loudnessGain;
  bool get mono => _mono;
  bool get skipSilence => _skipSilence;
  bool get perItem => _perItem;
  String? get currentItemId => _currentItemId;

  /// True when any audio processing (band EQ, bass, loudness, or mono) is
  /// active. iOS uses this to decide whether the processing tap must be live;
  /// effects work even with the band-EQ master switch off.
  bool get anyProcessingActive =>
      _enabled || _bassBoost > 0 || _loudnessGain > 0 || _mono;

  /// Initialize — try to connect to platform EQ, fall back to software presets.
  Future<void> init() async {
    await _loadSettings();

    try {
      final result = await _channel.invokeMethod('init');
      if (result is Map) {
        _available = true;
        _bandFrequencies = List<int>.from(result['frequencies'] ?? []);
        _minLevel = (result['minLevel'] as num?)?.toDouble() ?? -15.0;
        _maxLevel = (result['maxLevel'] as num?)?.toDouble() ?? 15.0;
        final numBands = _bandFrequencies.length;
        if (_bandLevels.length != numBands) {
          _bandLevels = List.filled(numBands, 0.0);
        }
        debugPrint('[EQ] Platform EQ available: ${_bandFrequencies.length} bands');
        if (_enabled) _applyCurrentSettings();
      }
    } on MissingPluginException {
      debugPrint('[EQ] Platform channel not available — using software presets');
      _setupSoftwareFallback();
    } on PlatformException catch (e) {
      debugPrint('[EQ] Platform EQ error: $e — using software presets');
      _setupSoftwareFallback();
    } catch (e) {
      debugPrint('[EQ] Unexpected error: $e — using software presets');
      _setupSoftwareFallback();
    }
    _skipSilenceApplier?.call(_skipSilence);
    _tapApplier?.call(anyProcessingActive);
    notifyListeners();
  }

  void _setupSoftwareFallback() {
    _available = true; // We still expose the UI, just software-side
    _bandFrequencies = [60, 230, 910, 3600, 14000];
    _minLevel = -15.0;
    _maxLevel = 15.0;
    if (_bandLevels.length != 5) {
      _bandLevels = List.filled(5, 0.0);
    }
  }

  /// Toggle EQ on/off.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (_enabled) {
      _applyCurrentSettings();
    } else {
      _resetPlatform();
    }
    _tapApplier?.call(anyProcessingActive);
    await _saveSettings();
    notifyListeners();
  }

  /// Apply a named preset.
  Future<void> applyPreset(String name) async {
    final curve = presets[name];
    if (curve == null) return;

    _activePreset = name;

    // Scale preset values to our band count and level range
    final numBands = _bandLevels.length;
    for (int i = 0; i < numBands; i++) {
      final presetIdx = (i * curve.length / numBands).floor().clamp(0, curve.length - 1);
      _bandLevels[i] = curve[presetIdx].clamp(_minLevel, _maxLevel);
    }

    if (_enabled) _applyCurrentSettings();
    await _saveSettings();
    notifyListeners();
  }

  /// Set a single band level.
  Future<void> setBandLevel(int bandIndex, double level) async {
    if (bandIndex < 0 || bandIndex >= _bandLevels.length) return;
    _bandLevels[bandIndex] = level.clamp(_minLevel, _maxLevel);
    _activePreset = 'custom';
    if (_enabled) _applyBand(bandIndex, _bandLevels[bandIndex]);
    await _saveSettings();
    notifyListeners();
  }

  /// Set bass boost (0.0–1.0).
  Future<void> setBassBoost(double value) async {
    _bassBoost = value.clamp(0.0, 1.0);
    // Effects apply independently of the band-EQ master switch on both platforms.
    try {
      await _channel.invokeMethod('setBassBoost', {'strength': (_bassBoost * 1000).round()});
    } catch (_) {}
    _tapApplier?.call(anyProcessingActive);
    await _saveSettings();
    notifyListeners();
  }

  /// Set virtualizer / surround (0.0–1.0).
  Future<void> setVirtualizer(double value) async {
    _virtualizer = value.clamp(0.0, 1.0);
    if (_enabled) {
      try {
        await _channel.invokeMethod('setVirtualizer', {'strength': (_virtualizer * 1000).round()});
      } catch (_) {}
    }
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle mono audio mixing.
  Future<void> setMono(bool value) async {
    _mono = value;
    try {
      await _channel.invokeMethod('setMono', {'enabled': _mono});
    } catch (_) {}
    _tapApplier?.call(anyProcessingActive);
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle skip-silence on the just_audio player. Android-only;
  /// the applier no-ops on iOS.
  Future<void> setSkipSilence(bool value) async {
    _skipSilence = value;
    _skipSilenceApplier?.call(_skipSilence);
    await _saveSettings();
    notifyListeners();
  }

  /// Register a callback that the service invokes whenever skipSilence
  /// changes. Called once immediately with the current value so the player
  /// picks up persisted state on app start.
  void setSkipSilenceApplier(void Function(bool enabled) fn) {
    _skipSilenceApplier = fn;
    fn(_skipSilence);
  }

  /// Register the iOS processing-tap applier. Called once immediately so the
  /// engine reflects the current state.
  void setTapApplier(void Function(bool active) fn) {
    _tapApplier = fn;
    fn(anyProcessingActive);
  }

  /// Set loudness enhancer gain (0.0–1.0).
  Future<void> setLoudnessGain(double value) async {
    _loudnessGain = value.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod('setLoudness', {'gain': (_loudnessGain * 1500).round()});
    } catch (_) {}
    _tapApplier?.call(anyProcessingActive);
    await _saveSettings();
    notifyListeners();
  }

  /// Reset everything to flat/off.
  Future<void> resetAll() async {
    _activePreset = 'flat';
    _bandLevels = List.filled(_bandLevels.length, 0.0);
    _bassBoost = 0.0;
    _virtualizer = 0.0;
    _loudnessGain = 0.0;
    _mono = false;
    _skipSilence = false;
    _skipSilenceApplier?.call(_skipSilence);
    if (_enabled) {
      _applyCurrentSettings();
    } else {
      _resetPlatform();
    }
    _tapApplier?.call(anyProcessingActive);
    await _saveSettings();
    notifyListeners();
  }

  /// Attach effects to an ExoPlayer audio session.
  /// Call this whenever the audio session ID changes (new playback).
  Future<void> attachToSession(int sessionId) async {
    if (sessionId <= 0) return;
    try {
      await _channel.invokeMethod('attachSession', {'sessionId': sessionId});
      debugPrint('[EQ] Attached to audio session $sessionId');
      if (_enabled) {
        _applyCurrentSettings();
      } else {
        // Bands off, but still push bass/loudness/mono so independent effects
        // apply on a freshly-attached session.
        _resetPlatform();
      }
    } catch (e) {
      debugPrint('[EQ] attachSession failed: $e');
    }
  }

  // ── Platform communication ──

  Future<void> _applyCurrentSettings() async {
    for (int i = 0; i < _bandLevels.length; i++) {
      _applyBand(i, _bandLevels[i]);
    }
    try {
      await _channel.invokeMethod('setBassBoost', {'strength': (_bassBoost * 1000).round()});
      await _channel.invokeMethod('setVirtualizer', {'strength': (_virtualizer * 1000).round()});
      await _channel.invokeMethod('setLoudness', {'gain': (_loudnessGain * 1500).round()});
      await _channel.invokeMethod('setEnabled', {'enabled': _enabled});
      await _channel.invokeMethod('setMono', {'enabled': _mono});
    } catch (_) {}
  }

  Future<void> _applyBand(int index, double level) async {
    try {
      await _channel.invokeMethod('setBand', {
        'band': index,
        'level': (level * 100).round(), // millibels
      });
    } catch (_) {}
  }

  Future<void> _resetPlatform() async {
    try {
      // Master switch only gates the band EQ; effects stay applied so bass /
      // loudness / mono keep working with the equalizer off.
      await _channel.invokeMethod('setEnabled', {'enabled': false});
      await _channel.invokeMethod('setMono', {'enabled': _mono});
      await _channel.invokeMethod('setBassBoost', {'strength': (_bassBoost * 1000).round()});
      await _channel.invokeMethod('setLoudness', {'gain': (_loudnessGain * 1500).round()});
    } catch (_) {}
  }

  /// Toggle per-item EQ scoping.
  Future<void> setPerItem(bool value) async {
    _perItem = value;
    await ScopedPrefs.setBool('eq_perItem', value);
    notifyListeners();
  }

  /// Switch EQ to a new item. Saves current settings under the old item,
  /// then loads the new item's settings (or defaults to EQ off).
  Future<void> switchItem(String itemId) async {
    if (!_perItem) {
      _currentItemId = itemId;
      _tapApplier?.call(anyProcessingActive);
      return;
    }
    if (_currentItemId != null && _currentItemId != itemId) {
      await _saveItemSettings(_currentItemId!);
    }
    _currentItemId = itemId;
    await _loadItemSettings(itemId);
    _skipSilenceApplier?.call(_skipSilence);
    if (_enabled) {
      _applyCurrentSettings();
    } else {
      _resetPlatform();
    }
    _tapApplier?.call(anyProcessingActive);
    notifyListeners();
  }

  // ── Persistence ──

  String _itemKey(String key, String itemId) => 'eq_${itemId}_$key';

  /// Read an item's persisted EQ settings without mutating service state.
  /// Used by the EQ sheet to preview/edit a non-playing item's EQ.
  Future<Map<String, dynamic>> loadItemSnapshot(String itemId) async {
    final bandCount = _bandLevels.isEmpty ? 5 : _bandLevels.length;
    final hasItemEq = await ScopedPrefs.containsKey(_itemKey('enabled', itemId));
    if (!hasItemEq) {
      return {
        'enabled': false,
        'preset': 'flat',
        'bassBoost': 0.0,
        'virtualizer': 0.0,
        'loudnessGain': 0.0,
        'mono': false,
        'skipSilence': false,
        'bands': List<double>.filled(bandCount, 0.0),
      };
    }
    final bandStr = await ScopedPrefs.getString(_itemKey('bands', itemId));
    final bands = bandStr != null
        ? bandStr.split(',').map((s) => double.tryParse(s) ?? 0.0).toList()
        : List<double>.filled(bandCount, 0.0);
    return {
      'enabled': await ScopedPrefs.getBool(_itemKey('enabled', itemId)) ?? false,
      'preset': await ScopedPrefs.getString(_itemKey('preset', itemId)) ?? 'flat',
      'bassBoost': await ScopedPrefs.getDouble(_itemKey('bassBoost', itemId)) ?? 0.0,
      'virtualizer': await ScopedPrefs.getDouble(_itemKey('virtualizer', itemId)) ?? 0.0,
      'loudnessGain': await ScopedPrefs.getDouble(_itemKey('loudnessGain', itemId)) ?? 0.0,
      'mono': await ScopedPrefs.getBool(_itemKey('mono', itemId)) ?? false,
      'skipSilence': await ScopedPrefs.getBool(_itemKey('skipSilence', itemId)) ?? false,
      'bands': bands,
    };
  }

  /// Persist a full snapshot to an item's storage without affecting live state.
  Future<void> saveItemSnapshot(String itemId, Map<String, dynamic> s) async {
    await ScopedPrefs.setBool(_itemKey('enabled', itemId), s['enabled'] as bool);
    await ScopedPrefs.setString(_itemKey('preset', itemId), s['preset'] as String);
    await ScopedPrefs.setDouble(_itemKey('bassBoost', itemId), s['bassBoost'] as double);
    await ScopedPrefs.setDouble(_itemKey('virtualizer', itemId), s['virtualizer'] as double);
    await ScopedPrefs.setDouble(_itemKey('loudnessGain', itemId), s['loudnessGain'] as double);
    await ScopedPrefs.setBool(_itemKey('mono', itemId), s['mono'] as bool);
    await ScopedPrefs.setBool(_itemKey('skipSilence', itemId), s['skipSilence'] as bool? ?? false);
    final bands = (s['bands'] as List).cast<double>();
    await ScopedPrefs.setString(_itemKey('bands', itemId), bands.map((l) => l.toStringAsFixed(1)).join(','));
  }

  Future<void> _loadItemSettings(String itemId) async {
    final hasItemEq = await ScopedPrefs.containsKey(_itemKey('enabled', itemId));
    if (!hasItemEq) {
      _enabled = false;
      _activePreset = 'flat';
      _bassBoost = 0.0;
      _virtualizer = 0.0;
      _loudnessGain = 0.0;
      _mono = false;
      _skipSilence = false;
      _bandLevels = List.filled(_bandLevels.length, 0.0);
      return;
    }
    _enabled = await ScopedPrefs.getBool(_itemKey('enabled', itemId)) ?? false;
    _activePreset = await ScopedPrefs.getString(_itemKey('preset', itemId)) ?? 'flat';
    _bassBoost = await ScopedPrefs.getDouble(_itemKey('bassBoost', itemId)) ?? 0.0;
    _virtualizer = await ScopedPrefs.getDouble(_itemKey('virtualizer', itemId)) ?? 0.0;
    _loudnessGain = await ScopedPrefs.getDouble(_itemKey('loudnessGain', itemId)) ?? 0.0;
    _mono = await ScopedPrefs.getBool(_itemKey('mono', itemId)) ?? false;
    _skipSilence = await ScopedPrefs.getBool(_itemKey('skipSilence', itemId)) ?? false;
    final bandStr = await ScopedPrefs.getString(_itemKey('bands', itemId));
    if (bandStr != null) {
      _bandLevels = bandStr.split(',').map((s) => double.tryParse(s) ?? 0.0).toList();
    } else {
      _bandLevels = List.filled(_bandLevels.length, 0.0);
    }
  }

  Future<void> _saveItemSettings(String itemId) async {
    await ScopedPrefs.setBool(_itemKey('enabled', itemId), _enabled);
    await ScopedPrefs.setString(_itemKey('preset', itemId), _activePreset);
    await ScopedPrefs.setDouble(_itemKey('bassBoost', itemId), _bassBoost);
    await ScopedPrefs.setDouble(_itemKey('virtualizer', itemId), _virtualizer);
    await ScopedPrefs.setDouble(_itemKey('loudnessGain', itemId), _loudnessGain);
    await ScopedPrefs.setBool(_itemKey('mono', itemId), _mono);
    await ScopedPrefs.setBool(_itemKey('skipSilence', itemId), _skipSilence);
    await ScopedPrefs.setString(_itemKey('bands', itemId), _bandLevels.map((l) => l.toStringAsFixed(1)).join(','));
  }

  Future<void> _loadSettings() async {
    _perItem = await ScopedPrefs.getBool('eq_perItem') ?? false;
    _enabled = await ScopedPrefs.getBool('eq_enabled') ?? false;
    _activePreset = await ScopedPrefs.getString('eq_preset') ?? 'flat';
    _bassBoost = await ScopedPrefs.getDouble('eq_bassBoost') ?? 0.0;
    _virtualizer = await ScopedPrefs.getDouble('eq_virtualizer') ?? 0.0;
    _loudnessGain = await ScopedPrefs.getDouble('eq_loudnessGain') ?? 0.0;
    _mono = await ScopedPrefs.getBool('eq_mono') ?? false;
    _skipSilence = await ScopedPrefs.getBool('eq_skipSilence') ?? false;

    final bandStr = await ScopedPrefs.getString('eq_bands');
    if (bandStr != null) {
      _bandLevels = bandStr.split(',')
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();
    }
  }

  /// Reload settings from the currently-scoped SharedPreferences. Call this
  /// after switching user accounts so the singleton picks up the new user's
  /// stored EQ config instead of keeping the previous user's in-memory state
  /// (which would otherwise also get written back into the new user's scope
  /// on the next save).
  Future<void> reloadForActiveAccount() async {
    await _loadSettings();
    _currentItemId = null;
    _skipSilenceApplier?.call(_skipSilence);
    if (_enabled) {
      await _applyCurrentSettings();
    } else {
      await _resetPlatform();
    }
    _tapApplier?.call(anyProcessingActive);
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await ScopedPrefs.setBool('eq_enabled', _enabled);
    await ScopedPrefs.setString('eq_preset', _activePreset);
    await ScopedPrefs.setDouble('eq_bassBoost', _bassBoost);
    await ScopedPrefs.setDouble('eq_virtualizer', _virtualizer);
    await ScopedPrefs.setDouble('eq_loudnessGain', _loudnessGain);
    await ScopedPrefs.setBool('eq_mono', _mono);
    await ScopedPrefs.setBool('eq_skipSilence', _skipSilence);
    await ScopedPrefs.setString('eq_bands', _bandLevels.map((l) => l.toStringAsFixed(1)).join(','));
    if (_perItem && _currentItemId != null) {
      await _saveItemSettings(_currentItemId!);
    }
  }

  /// Formatted frequency label.
  String freqLabel(int hz) {
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';
    return '${hz}Hz';
  }

  String freqName(int hz) {
    if (hz <= 100) return 'Sub';
    if (hz <= 400) return 'Bass';
    if (hz <= 1500) return 'Mids';
    if (hz <= 6000) return 'High';
    return 'Air';
  }
}
