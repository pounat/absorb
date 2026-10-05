import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'player_settings.dart';

/// Keeps the screen from timing out while something hands-free is on screen,
/// like the ebook reader's auto scroll. FLAG_KEEP_SCREEN_ON on Android, the
/// idle timer on iOS. Each caller holds it under its own name and must let
/// go: neither platform clears it, and the screen stays on while anyone holds.
class ScreenWake {
  static const _channel = MethodChannel('com.absorb.screen_wake');
  static final _holders = <String>{};
  static bool _on = false;

  static Future<void> hold(String owner, bool on) async {
    if (on) {
      _holders.add(owner);
    } else {
      _holders.remove(owner);
    }
    final want = _holders.isNotEmpty;
    if (want == _on) return;
    _on = want;
    try {
      await _channel.invokeMethod('set', {'on': want});
    } catch (e) {
      debugPrint('[ScreenWake] keepOn($want) failed: $e');
    }
  }
}

/// The player's hold: while the Absorbing tab or the full screen card is up,
/// playing or paused, when the Settings switch or the card's button asks. The
/// button lasts until the app is closed; the switch is for good.
class PlayerScreenWake {
  static final sessionOn = ValueNotifier<bool>(false);
  static final onScreen = ValueNotifier<bool>(false);
  // The ebook reader sits over the shell and holds the screen on its own terms.
  static final covered = ValueNotifier<bool>(false);
  /// What the card's button shows: the switch or the session toggle.
  static final wanted = ValueNotifier<bool>(false);
  static bool _always = false;
  static bool _started = false;

  static bool get always => _always;

  static void start() {
    if (_started) return;
    _started = true;
    sessionOn.addListener(_sync);
    onScreen.addListener(_sync);
    covered.addListener(_sync);
    PlayerSettings.settingsChanged.addListener(_reload);
    _reload();
  }

  static Future<void> _reload() async {
    _always = await PlayerSettings.getKeepScreenOnInPlayer();
    _sync();
  }

  static void _sync() {
    wanted.value = _always || sessionOn.value;
    ScreenWake.hold('player', wanted.value && onScreen.value && !covered.value);
  }
}
