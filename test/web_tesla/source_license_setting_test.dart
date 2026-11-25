import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/web_tesla/source_license_setting.dart';

void main() {
  test('Settings exposes source and license only on web', () {
    final settings = File(
      'lib/screens/settings_screen.dart',
    ).readAsStringSync();
    expect(
      settings.contains('if (AppPlatform.isWeb) const SourceLicenseSetting(),'),
      isTrue,
    );
  });

  for (final width in [320.0, 480.0]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'compact source offer at ${width}px, text scale $textScale has 48px targets and explicit root links',
        (tester) async {
          var networkAttempts = 0;
          await HttpOverrides.runZoned(
            () async {
              tester.view.physicalSize = Size(width, 640);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final opened = <Uri>[];
              await tester.pumpWidget(
                MaterialApp(
                  theme: ThemeData(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(textScale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: SourceLicenseSetting(
                      openUri: (uri) async {
                        opened.add(uri);
                        return true;
                      },
                    ),
                  ),
                ),
              );
              expect(
                tester.getSize(find.byType(ListTile)).height,
                greaterThanOrEqualTo(48),
              );
              await tester.tap(find.text('Source and license'));
              await tester.pumpAndSettle();
              expect(find.textContaining('Absorb'), findsOneWidget);
              expect(find.textContaining('Nathan Poulson'), findsOneWidget);
              expect(find.textContaining('GPL-3.0-or-later'), findsOneWidget);
              expect(opened, isEmpty);
              for (final entry in {
                'Download source': '/source/absorb-web-source.tar.gz',
                'View license': '/source/LICENSE',
              }.entries) {
                final button = find.widgetWithText(TextButton, entry.key);
                await tester.ensureVisible(button);
                await tester.pumpAndSettle();
                expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
                final rect = tester.getRect(button);
                expect(rect.left, greaterThanOrEqualTo(0));
                expect(rect.right, lessThanOrEqualTo(width));
                final material = find.descendant(
                  of: button,
                  matching: find.byType(Material),
                );
                expect(
                  tester.getSize(material).height,
                  greaterThanOrEqualTo(48),
                );
                // Touch the real target edge, not only its central text.
                await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
                await tester.pumpAndSettle();
                expect(opened.last, Uri.base.resolve(entry.value));
                expect(opened.last.path, entry.value);
                expect(opened.last.query, isEmpty);
                expect(opened.last.fragment, isEmpty);
              }
              expect(opened, hasLength(2));
              final close = find.widgetWithText(TextButton, 'Close');
              expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
              final closeRect = tester.getRect(close);
              expect(closeRect.left, greaterThanOrEqualTo(0));
              expect(closeRect.right, lessThanOrEqualTo(width));
              expect(
                tester
                    .getSize(
                      find.descendant(
                        of: close,
                        matching: find.byType(Material),
                      ),
                    )
                    .height,
                greaterThanOrEqualTo(48),
              );
              await tester.tapAt(
                Offset(closeRect.center.dx, closeRect.bottom - 2),
              );
              await tester.pumpAndSettle();
              expect(find.byType(AlertDialog), findsNothing);
              expect(opened, hasLength(2));
              await tester.tap(find.text('Source and license'));
              await tester.pumpAndSettle();
              await tester.tap(find.text('Close'));
              await tester.pumpAndSettle();
              expect(
                opened,
                hasLength(2),
                reason: 'Cancellation must not launch a link',
              );
              await tester.tap(find.text('Source and license'));
              await tester.pumpAndSettle();
              await tester.tapAt(const Offset(4, 4));
              await tester.pumpAndSettle();
              expect(find.byType(AlertDialog), findsNothing);
              expect(
                opened,
                hasLength(2),
                reason: 'Barrier dismissal must not launch',
              );
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            },
            createHttpClient: (_) {
              networkAttempts++;
              throw StateError(
                'Source offer must not contact or mutate the backend',
              );
            },
          );
          expect(networkAttempts, 0);
        },
      );
    }
  }
}
