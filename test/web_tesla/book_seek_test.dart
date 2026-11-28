import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absorb/l10n/app_localizations.dart';
import 'package:absorb/services/audio_player_service.dart';
import 'package:absorb/services/playback_history_service.dart';
import 'package:absorb/widgets/card_buttons.dart';
import 'package:absorb/widgets/card_progress_bar.dart';
import 'package:absorb/web_tesla/tesla_mode.dart';

// Only the engine boundary is substituted: gestures, layout and dispatch are real.
class TouchPlayer extends ChangeNotifier implements AudioPlayerService {
  final positions = StreamController<Duration>.broadcast();
  final seeks = <Duration>[];
  final rates = <double>[];
  @override Future<void> setSpeed(double value) async {
    rates.add(value);
    rate = value;
    notifyListeners();
  }
  double rate = 1;
  @override double get speed => rate;
  @override bool get isPlaying => false;
  @override bool get hasBook => true;
  @override double get totalDuration => 3600;
  @override Duration get position => const Duration(seconds: 900);
  @override double? get activeSeekTarget => null;
  @override List<dynamic> get chapters => [];
  @override Stream<Duration> get absolutePositionStream => positions.stream;
  @override Future<void> seekTo(Duration position, {
    PlaybackEventType logAs = PlaybackEventType.seek, String? logDetail,
  }) async { seeks.add(position); }
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 480.0, 640.0]) {
    testWidgets('whole-book tap seeking has a large target at $width', (tester) async {
      SharedPreferences.setMockInitialValues({});
      TeslaMode.manual.value = false;
      tester.view.physicalSize = Size(width, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final player = TouchPlayer();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (_, child) => TeslaAdaptiveScope(web: true, child: child!),
        home: Scaffold(body: CardDualProgressBar(
          player: player, accent: Colors.blue, isActive: true,
          staticProgress: .25, staticDuration: 3600, chapters: const [],
          showChapterBar: false,
        )),
      ));
      await tester.pumpAndSettle();
      final seek = find.byKey(const ValueKey('tesla-book-seek'));
      expect(seek, findsOneWidget);
      final rect = tester.getRect(seek);
      expect(rect.height, greaterThanOrEqualTo(48));
      // Tap well away from the thin visual rail: no precision drag required.
      await tester.tapAt(Offset(rect.left + rect.width * .75, rect.top + 4));
      await tester.pump();
      expect(player.seeks.single.inSeconds, closeTo(2700, 1));
      await tester.tapAt(Offset(rect.left + rect.width * .25, rect.bottom - 4));
      await tester.pump();
      expect(player.seeks.last.inSeconds, closeTo(900, 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await player.positions.close();
      player.dispose();
    });
  }

  testWidgets('current rate follows player notifications', (tester) async {
    SharedPreferences.setMockInitialValues({});
    TeslaMode.manual.value = true;
    addTearDown(() => TeslaMode.manual.value = false);
    final player = TouchPlayer();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (_, child) => TeslaAdaptiveScope(web: true, child: child!),
      home: Scaffold(body: CardSpeedButtonInline(player: player, accent: Colors.blue, isActive: true)),
    ));
    expect(find.text('Speed 1.00x'), findsOneWidget);
    player.rate = 1.75;
    player.notifyListeners();
    await tester.pump();
    expect(find.text('Speed 1.75x'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tesla-speed')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5x'));
    await tester.pumpAndSettle();
    expect(player.rates, [1.5]);
    expect(find.text('Speed 1.50x'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await player.positions.close();
    player.dispose();
  });
}
