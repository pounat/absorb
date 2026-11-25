import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absorb/web_tesla/tesla_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('narrow web automatically enables Tesla without changing native', () {
    expect(TeslaMode.enabledFor(width: 320, web: true, manual: false), isTrue);
    expect(TeslaMode.enabledFor(width: 640, web: true, manual: false), isTrue);
    expect(TeslaMode.enabledFor(width: 1280, web: true, manual: false), isFalse);
    expect(TeslaMode.enabledFor(width: 1280, web: true, manual: true), isTrue);
    expect(TeslaMode.enabledFor(width: 320, web: false, manual: true), isFalse);
  });
  test('manual Tesla setting survives a fresh preferences read', () async {
    SharedPreferences.setMockInitialValues({});
    await TeslaMode.load();
    expect(TeslaMode.manual.value, isFalse);
    await TeslaMode.setManual(true);
    TeslaMode.manual.value = false;
    await TeslaMode.load();
    expect(TeslaMode.manual.value, isTrue);
    await TeslaMode.setManual(false);
  });
  testWidgets('adaptive wrapper reduces motion and retains child state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    TeslaMode.manual.value = false;
    Widget app(double width) => MaterialApp(home: MediaQuery(
      data: MediaQueryData(size: Size(width, 600)),
      child: TeslaAdaptiveScope(web: true, child: Builder(builder: (context) =>
        Text('${TeslaMode.of(context)}:${MediaQuery.disableAnimationsOf(context)}'))),
    ));
    await tester.pumpWidget(app(320));
    expect(find.text('true:true'), findsOneWidget);
    await tester.pumpWidget(app(1280));
    expect(find.text('false:false'), findsOneWidget);
    await TeslaMode.setManual(true);
    await tester.pump();
    expect(find.text('true:true'), findsOneWidget);
    await TeslaMode.setManual(false);
  });
}
