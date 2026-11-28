import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local preference: never tied to an ABS session or audio lifetime.
class TeslaMode {
  static final manual = ValueNotifier<bool>(false);
  static const _key = 'web_tesla_mode';
  static bool enabledFor({required double width, required bool web, required bool manual}) =>
      web && (manual || width <= 640);
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TeslaScope>()?.enabled ?? false;
  static Future<void> load() async {
    manual.value = (await SharedPreferences.getInstance()).getBool(_key) ?? false;
  }
  static Future<void> setManual(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(_key, value);
    manual.value = value;
  }
}

class TeslaAdaptiveScope extends StatelessWidget {
  final Widget child;
  final bool web;
  const TeslaAdaptiveScope({super.key, required this.child, this.web = kIsWeb});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: TeslaMode.manual,
    builder: (context, manual, _) => LayoutBuilder(builder: (context, constraints) {
      final media = MediaQuery.of(context);
      final width = constraints.maxWidth < media.size.width ? constraints.maxWidth : media.size.width;
      final enabled = TeslaMode.enabledFor(width: width, web: web, manual: manual);
      return _TeslaScope(enabled: enabled, child: MediaQuery(
        data: enabled ? media.copyWith(disableAnimations: true) : media,
        child: child,
      ));
    }),
  );
}

class _TeslaScope extends InheritedWidget {
  final bool enabled;
  const _TeslaScope({required this.enabled, required super.child});
  @override
  bool updateShouldNotify(_TeslaScope oldWidget) => enabled != oldWidget.enabled;
}

class TeslaModeSetting extends StatelessWidget {
  const TeslaModeSetting({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: TeslaMode.manual,
    builder: (context, value, _) => SwitchListTile(
      title: const Text('Tesla mode'),
      subtitle: const Text('Large touch controls. Automatic in web panes up to 640 px; enable here for wider panes.'),
      value: value,
      onChanged: TeslaMode.setManual,
    ),
  );
}
