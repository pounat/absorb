import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/web_tesla/playback_recovery_notice.dart';

const reason =
    'Playback paused: unable to sync with the server. Check your connection and press Play to recover.';

Widget player({
  bool web = true,
  bool active = true,
  bool recovery = true,
  String? message = reason,
}) => MaterialApp(
  home: Scaffold(
    body: PlaybackRecoveryNotice(
      isWeb: web,
      isActive: active,
      recoveryRequired: recovery,
      message: message,
      child: const Text('Existing playback controls'),
    ),
  ),
);

void main() {
  testWidgets('announces a high-contrast wrapping notice at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(player());
    final text = tester.widget<Text>(find.text(reason));
    expect(text.style?.fontSize, greaterThanOrEqualTo(16));
    final node = tester.getSemantics(
      find.byKey(const ValueKey('playback-recovery-notice')),
    );
    expect(node.getSemanticsData().hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    expect(node.label, contains(reason));
    final ink = text.style!.color!;
    final background = tester
        .widget<ColoredBox>(
          find.byKey(const ValueKey('playback-recovery-background')),
        )
        .color;
    final a = ink.computeLuminance();
    final b = background.computeLuminance();
    expect(
      ((a > b ? a : b) + 0.05) / ((a < b ? a : b) + 0.05),
      greaterThanOrEqualTo(7),
    );
    final rect = tester.getRect(find.text(reason));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.height, greaterThan(40));
    expect(text.maxLines, isNull);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final state in ['native', 'inactive', 'recovered']) {
    testWidgets('keeps notice hidden for $state', (tester) async {
      await tester.pumpWidget(
        player(
          web: state != 'native',
          active: state != 'inactive',
          recovery: state != 'recovered',
        ),
      );
      expect(find.text(reason), findsNothing);
      expect(find.text('Existing playback controls'), findsOneWidget);
    });
  }

  testWidgets('shows the stable recovery reason until recovery succeeds', (
    tester,
  ) async {
    await tester.pumpWidget(player());
    expect(find.text(reason), findsOneWidget);
    expect(find.text('Existing playback controls'), findsOneWidget);
    await tester.pump(const Duration(minutes: 2));
    expect(find.text(reason), findsOneWidget);
    await tester.pumpWidget(player(recovery: false));
    expect(find.text(reason), findsNothing);
    expect(find.text('Existing playback controls'), findsOneWidget);
  });
}
