import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absorb/services/audio_player_service.dart';
import 'package:absorb/widgets/card_playback_controls.dart';
import 'package:absorb/web_tesla/tesla_mode.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('narrow web book card has 60px back 15, play and forward 30', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(builder: (context, child) => TeslaAdaptiveScope(web: true, child: child!), home: Scaffold(body: CardPlaybackControls(
      player: AudioPlayerService(), accent: Colors.deepPurple,
      isActive: true, isStarting: false, onStart: () {}, showPlayButton: true,
    ))));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back 15 seconds'), findsOneWidget);
    for (final label in ['Back 15 seconds', 'Play', 'Forward 30 seconds']) {
      final size = tester.getSize(find.byTooltip(label));
      expect(size.width, inInclusiveRange(56, 64));
      expect(size.height, inInclusiveRange(56, 64));
    }
    expect(tester.takeException(), isNull);
  });
}
