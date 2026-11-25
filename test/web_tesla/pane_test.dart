import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/web_tesla/tesla_playback_controls.dart';
import 'package:absorb/web_tesla/tesla_book_pane.dart';

void main() {
  for (final width in [320.0, 480.0, 640.0]) {
    testWidgets('book pane and touch callbacks at $width without hover', (tester) async {
      tester.view.physicalSize = Size(width, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var back = 0, forward = 0, play = 0, previous = 0, next = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: TeslaBookPane(
        title: 'A long book title that remains readable in the narrow pane',
        author: 'An author', cover: const Icon(Icons.book),
        progress: const Text('12:34  35.0%  -23:45'),
        controls: TeslaPlaybackControls(playing: false, loading: false,
          onPlay: () => play++, onBack: () => back++, onForward: () => forward++,
          onPrevious: () => previous++, onNext: () => next++),
      ))));
      expect(find.text('15'), findsOneWidget);
      for (final label in ['Back 15 seconds', 'Play', 'Forward 30 seconds', 'Previous chapter', 'Next chapter']) {
        final button = find.byTooltip(label);
        await tester.ensureVisible(button);
        await tester.tap(button);
        expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(48));
        final rect = tester.getRect(button);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
      expect([back, play, forward, previous, next], [1, 1, 1, 1, 1]);
      expect(tester.takeException(), isNull);
    });
  }
}
