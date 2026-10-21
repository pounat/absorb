import 'dart:io';

import 'package:absorb/services/download_export_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  const origin = Rect.fromLTWH(120, 40, 48, 48);
  final service = DownloadExportService();
  late Directory root;
  late List<MethodCall> calls;
  var nativeResult = 'com.apple.UIKit.activity.AirDrop';

  Future<File> track(String relativePath) async {
    final file = File('${root.path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1, 2, 3, 4]);
    return file;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('absorb_export_test_');
    calls = [];
    nativeResult = 'com.apple.UIKit.activity.AirDrop';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return nativeResult;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await root.delete(recursive: true);
  });

  test('shares an App Group audiobook with the iPad button anchor', () async {
    final file = await track('AppGroup/audio/downloads/Author/Book/Book.m4b');
    final result = await service.shareAudioFiles([
      file.path,
    ], sharePositionOrigin: origin);

    expect(result.status, ShareResultStatus.success);
    expect(calls.single.method, 'shareFiles');
    expect(calls.single.arguments, containsPair('paths', [file.path]));
    expect(calls.single.arguments, containsPair('originX', 120.0));
    expect(calls.single.arguments, containsPair('originY', 40.0));
    expect(calls.single.arguments, containsPair('originWidth', 48.0));
    expect(calls.single.arguments, containsPair('originHeight', 48.0));
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
  });

  test(
    'shares every track in playback order and retains original names',
    () async {
      final first = await track('Documents/downloads/Book/02 Chapter.mp3');
      final second = await track('Documents/downloads/Book/01 Chapter.mp3');
      await service.shareAudioFiles([
        first.path,
        second.path,
      ], sharePositionOrigin: origin);

      expect(
        calls.single.arguments,
        containsPair('paths', [first.path, second.path]),
      );
      expect(
        calls.single.arguments,
        containsPair('mimeTypes', ['audio/mpeg', 'audio/mpeg']),
      );
      expect(await first.readAsBytes(), [1, 2, 3, 4]);
      expect(await second.readAsBytes(), [1, 2, 3, 4]);
    },
  );

  test('rejects a missing chapter without sharing a partial book', () async {
    final first = await track('chapter1.mp3');
    await expectLater(
      service.shareAudioFiles([
        first.path,
        '${root.path}/missing.mp3',
      ], sharePositionOrigin: origin),
      throwsA(isA<DownloadExportUnavailable>()),
    );
    expect(calls, isEmpty);
    expect(await first.exists(), isTrue);
  });

  test('rejects an empty download', () async {
    await expectLater(
      service.shareAudioFiles([], sharePositionOrigin: origin),
      throwsA(isA<DownloadExportUnavailable>()),
    );
    expect(calls, isEmpty);
  });

  test('rejects zero-byte tracks', () async {
    final file = await File('${root.path}/empty.m4b').create();
    await expectLater(
      service.shareAudioFiles([file.path], sharePositionOrigin: origin),
      throwsA(isA<DownloadExportUnavailable>()),
    );
    expect(calls, isEmpty);
  });

  test('rejects a directory in place of a track', () async {
    await expectLater(
      service.shareAudioFiles([root.path], sharePositionOrigin: origin),
      throwsA(isA<DownloadExportUnavailable>()),
    );
    expect(calls, isEmpty);
  });

  test('rejects an inaccessible filesystem path', () async {
    final file = await track('track.mp3');
    await expectLater(
      service.shareAudioFiles([
        '${file.path}/not-a-directory.mp3',
      ], sharePositionOrigin: origin),
      throwsA(isA<DownloadExportUnavailable>()),
    );
    expect(calls, isEmpty);
  });

  test(
    'passes a large file by path without loading it into Dart memory',
    () async {
      final file = await track('large.m4b');
      final handle = await file.open(mode: FileMode.append);
      await handle.truncate(1024 * 1024 * 1024);
      await handle.close();

      await service.shareAudioFiles([file.path], sharePositionOrigin: origin);

      expect(calls.single.arguments, containsPair('paths', [file.path]));
      expect(await file.length(), 1024 * 1024 * 1024);
    },
  );

  test('cancelling the share sheet leaves the download intact', () async {
    final file = await track('episode.mp3');
    nativeResult = '';

    final result = await service.shareAudioFiles([
      file.path,
    ], sharePositionOrigin: origin);

    expect(result.status, ShareResultStatus.dismissed);
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
  });

  test('propagates a native sharing error and allows retry', () async {
    final file = await track('book.m4b');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'share_failed');
        });

    await expectLater(
      service.shareAudioFiles([file.path], sharePositionOrigin: origin),
      throwsA(isA<PlatformException>()),
    );
    expect(await file.readAsBytes(), [1, 2, 3, 4]);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => nativeResult);
    final result = await service.shareAudioFiles([
      file.path,
    ], sharePositionOrigin: origin);
    expect(result.status, ShareResultStatus.success);
  });
}
