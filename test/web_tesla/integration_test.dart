import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main installs Tesla above navigator and loads saved mode', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('builder: AppPlatform.isTv'));
    expect(source, contains(': kIsWeb\n                      ? (context, child) => TeslaAdaptiveScope(child: child!)'));
    expect(source, contains('child: ValueListenableBuilder<bool>('));
    expect(source, contains('valueListenable: TvPip.inPip'));
    expect(source, contains('await TeslaMode.load()'));
  });
  test('release web suppresses debug printing before startup and skips log capture', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('if (kIsWeb && kReleaseMode) debugPrint ='));
    expect(source, contains('if (!(kIsWeb && kReleaseMode)) {'));
  });
  test('settings exposes manual Tesla mode only on web', () {
    final source = File('lib/screens/settings_screen.dart').readAsStringSync();
    expect(source, contains('if (AppPlatform.isWeb) const TeslaModeSetting()'));
  });
}
