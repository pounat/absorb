import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/app_platform.dart';

/// One tab of the native bar. [icon] is an SF Symbol name.
class NativeTab {
  final String id;
  final String title;
  final String icon;
  const NativeTab({required this.id, required this.title, required this.icon});

  Map<String, String> toMap() => {'id': id, 'title': title, 'icon': icon};
}

/// The iOS bottom tabs as a real UITabBar over the Flutter view, which is what
/// gets Liquid Glass on iOS 26. Everything here is a no-op off iOS.
class NativeTabBar {
  NativeTabBar._();

  static const _channel = MethodChannel('com.absorb.native_tabs');
  static bool? _supported;
  static ValueChanged<String>? _onSelect;
  static bool _handlerSet = false;

  /// Called with a tab's id when it is pressed and held.
  static ValueChanged<String>? onHold;

  /// Called when a pill of the Library row is tapped. `reselect` is true when
  /// it was already the active one.
  static void Function(int index, bool reselect)? onPillSelect;

  static int _nextToastId = 1;
  static int _tappableToastId = -1;
  static VoidCallback? _onToastTap;

  /// True while the native bar stands in for the Flutter one.
  static final ValueNotifier<bool> active = ValueNotifier(false);

  /// The tab page whose native chrome is on screen right now, or null while
  /// the bar is off, covered by another page, or scrolled away.
  static final ValueNotifier<int?> shownPage = ValueNotifier(null);

  /// True on iOS 26 and later. Asked once, then remembered.
  static Future<bool> isSupported() async {
    if (!AppPlatform.isIOS) return false;
    final known = _supported;
    if (known != null) return known;
    try {
      final supported = await _channel.invokeMethod<bool>('isSupported') ?? false;
      _supported = supported;
      return supported;
    } on MissingPluginException {
      debugPrint('[NativeTabs] not built into this app');
      _supported = false;
      return false;
    } on PlatformException catch (e) {
      debugPrint('[NativeTabs] isSupported failed: ${e.code} ${e.message}');
      return false;
    }
  }

  /// Called with a tab's id when it is tapped, including the selected one.
  static set onSelect(ValueChanged<String>? handler) {
    _onSelect = handler;
    if (_handlerSet) return;
    _handlerSet = true;
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments as Map?;
      switch (call.method) {
        case 'select':
          final id = args?['id'];
          if (id is String) _onSelect?.call(id);
        case 'hold':
          final id = args?['id'];
          if (id is String) onHold?.call(id);
        case 'pillSelect':
          final index = args?['index'];
          if (index is int) {
            onPillSelect?.call(index, args?['reselect'] == true);
          }
        case 'toastTap':
          if (args?['id'] == _tappableToastId) {
            final handler = _onToastTap;
            _onToastTap = null;
            _tappableToastId = -1;
            handler?.call();
          }
      }
    });
  }

  /// Shows or updates the bar. Returns its height in logical pixels, or null
  /// when the bar could not be shown.
  static Future<double?> show({
    required List<NativeTab> tabs,
    required String selected,
    required int tintArgb,
    required bool dark,
  }) async {
    try {
      return await _channel.invokeMethod<double>('show', {
        'tabs': [for (final tab in tabs) tab.toMap()],
        'selected': selected,
        'tint': tintArgb,
        'dark': dark,
      });
    } on MissingPluginException {
      debugPrint('[NativeTabs] not built into this app');
      return null;
    } on PlatformException catch (e) {
      debugPrint('[NativeTabs] show failed: ${e.code} ${e.message}');
      return null;
    }
  }

  static Future<void> setHidden(bool hidden) =>
      _send('setHidden', {'hidden': hidden});

  static Future<void> remove() => _send('remove');

  /// Shows or updates the Library page's pill row as a glass capsule above
  /// the tabs. Returns false when it could not be shown.
  static Future<bool> showPill({
    required List<String> labels,
    required int selected,
    required int tintArgb,
    required bool dark,
  }) async {
    try {
      await _channel.invokeMethod<void>('pillShow', {
        'labels': labels,
        'selected': selected,
        'tint': tintArgb,
        'dark': dark,
      });
      return true;
    } on MissingPluginException {
      debugPrint('[NativeTabs] not built into this app');
      return false;
    } on PlatformException catch (e) {
      debugPrint('[NativeTabs] pillShow failed: ${e.code} ${e.message}');
      return false;
    }
  }

  static Future<void> setPillHidden(bool hidden) =>
      _send('pillSetHidden', {'hidden': hidden});

  static Future<void> removePill() => _send('pillRemove');

  /// A fresh id for a toast. Showing the same id again updates it in place.
  static int newToastId() => _nextToastId++;

  /// Shows a glass toast, replacing whichever one is up. Leave [seconds] out
  /// for a toast that stays until [dismissToast]. Returns false when it could
  /// not be shown, so the caller can fall back to the Flutter toast.
  static Future<bool> showToast({
    required int id,
    required String message,
    Uint8List? iconPng,
    VoidCallback? onTap,
    double? seconds,
    required bool dark,
  }) async {
    if (onTap != null) {
      _tappableToastId = id;
      _onToastTap = onTap;
    } else if (_tappableToastId != id) {
      _tappableToastId = -1;
      _onToastTap = null;
    }
    try {
      await _channel.invokeMethod<void>('toastShow', {
        'id': id,
        'message': message,
        'icon': iconPng,
        'tappable': onTap != null,
        'seconds': seconds,
        'dark': dark,
      });
      return true;
    } on MissingPluginException {
      debugPrint('[NativeTabs] not built into this app');
      return false;
    } on PlatformException catch (e) {
      debugPrint('[NativeTabs] toastShow failed: ${e.code} ${e.message}');
      return false;
    }
  }

  static Future<void> dismissToast(int id) => _send('toastDismiss', {'id': id});

  static Future<void> _send(String method, [Map<String, Object?>? args]) async {
    if (!AppPlatform.isIOS) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      debugPrint('[NativeTabs] not built into this app');
    } on PlatformException catch (e) {
      debugPrint('[NativeTabs] $method failed: ${e.code} ${e.message}');
    }
  }
}
