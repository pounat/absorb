import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absorb/l10n/app_localizations.dart';
import 'package:absorb/providers/auth_provider.dart';
import 'package:absorb/providers/library_provider.dart';
import 'package:absorb/services/audio_player_service.dart';
import 'package:absorb/widgets/absorbing_card.dart';
import 'package:absorb/widgets/card_buttons.dart';
import 'package:absorb/web_tesla/tesla_mode.dart';

void main() {
  for (final viewport in [
    const Size(320, 600), const Size(480, 600), const Size(640, 600),
    const Size(320, 300), const Size(480, 300), const Size(640, 300),
  ]) {
    final width = viewport.width;
    testWidgets('real Absorb book card fits $viewport and keeps player across routes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      TeslaMode.manual.value = false;
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final player = AudioPlayerService();
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ], child: MaterialApp(
        navigatorKey: nav,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => TeslaAdaptiveScope(web: true, child: child!),
        home: Scaffold(body: AbsorbingCard(player: player, item: const {
          'id': 'synthetic-tesla-book', 'libraryId': 'synthetic-library',
          'mediaType': 'book', 'media': {
            'duration': 3600, 'chapters': [
              {'id': 0, 'start': 0, 'end': 1800, 'title': 'Opening chapter'},
              {'id': 1, 'start': 1800, 'end': 3600, 'title': 'Second named chapter'},
            ], 'metadata': {'title': 'Synthetic long book title for touch layout', 'authorName': 'Test author'},
          },
        })),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic long book title for touch layout'), findsWidgets);
      for (final label in ['Back 15 seconds', 'Play', 'Forward 30 seconds', 'Previous chapter', 'Next chapter']) {
        final button = find.byTooltip(label);
        await tester.ensureVisible(button);
        final size = tester.getSize(button);
        expect(size.shortestSide, greaterThanOrEqualTo(48));
        if (label != 'Previous chapter' && label != 'Next chapter') {
          expect(size, const Size(60, 60));
        }
        final rect = tester.getRect(button);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
      final seek = find.byKey(const ValueKey('tesla-book-seek'));
      expect(seek, findsOneWidget);
      await tester.ensureVisible(seek);
      expect(tester.getSize(seek).height, greaterThanOrEqualTo(48));
      expect(tester.getRect(seek).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(seek).right, lessThanOrEqualTo(width));
      for (final label in ['tesla-speed', 'tesla-chapters']) {
        final button = find.byKey(ValueKey(label));
        expect(button, findsOneWidget);
        await tester.ensureVisible(button);
        expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(48));
        expect(tester.getRect(button).left, greaterThanOrEqualTo(0));
        expect(tester.getRect(button).right, lessThanOrEqualTo(width));
      }
      expect(find.text('Speed 1.00x'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('tesla-speed')));
      await tester.tap(find.byKey(const ValueKey('tesla-speed')));
      await tester.pumpAndSettle();
      expect(find.byType(CardSpeedSheet), findsOneWidget);
      final preset = find.text('1.5x');
      await tester.ensureVisible(preset);
      await tester.tap(preset);
      await tester.pumpAndSettle();
      expect(await PlayerSettings.getBookSpeed('synthetic-tesla-book'), 1.5);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Speed 1.50x'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('tesla-chapters')));
      await tester.tap(find.byKey(const ValueKey('tesla-chapters')));
      await tester.pumpAndSettle();
      expect(find.text('Second named chapter'), findsOneWidget);
      await tester.tap(find.text('Second named chapter'));
      await tester.pumpAndSettle();
      // The existing chapter action asks to start this inactive book.
      expect(find.byType(AlertDialog), findsOneWidget);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Settings route probe'))));
      await tester.pumpAndSettle();
      expect(identical(player, AudioPlayerService()), isTrue);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.widget<AbsorbingCard>(find.byType(AbsorbingCard)).player, same(player));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
