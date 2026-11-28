import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Supplementary source tripwires; listening correctness lives in runtime tests.
void main() {
  final audio = File(
    'lib/services/audio_player_service.dart',
  ).readAsStringSync();
  final progress = File(
    'lib/services/progress_sync_service.dart',
  ).readAsStringSync();
  test(
    'web sync and accrual exit before native fallbacks and durable queues',
    () {
      expect(
        audio,
        contains('if (kIsWeb) return _webCheckpoint(pos, force: true);'),
      );
      expect(
        audio,
        contains(
          'if (kIsWeb) {\n      _sampleWebPlayback(absolutePos);\n      return;\n    }',
        ),
      );
      expect(
        audio,
        contains('if (kIsWeb) return; // Never replay lost increments.'),
      );
    },
  );
  test('web event clock, seek and lifecycle use browser checkpoint path', () {
    expect(
      audio,
      contains(
        '_webCheckpointTimer = Timer.periodic(const Duration(seconds: 1)',
      ),
    );
    expect(audio, contains('await _webSeekAbsolute(absoluteSeconds)'));
    expect(
      audio,
      contains(
        'unawaited(_instance._webCheckpoint(_instance.position, force: true))',
      ),
    );
    expect(audio, contains('Future<bool> recoverWebPlayback('));
  });
  test(
    'completion uses ordered browser close and native local replays are disabled',
    () {
      final local = File(
        'lib/services/local_session_service.dart',
      ).readAsStringSync();
      expect(audio.contains('await _finishWebPlayback();'), isTrue);
      expect(
        local.contains(
          'if (kIsWeb) return; // Browser playback has no LOCAL queue.',
        ),
        isTrue,
      );
      expect(local.contains('if (kIsWeb) return false;'), isTrue);
    },
  );
  test('web checkpoints cannot become native progress/offline replays', () {
    expect(
      progress,
      contains(
        'if (kIsWeb) return false; // Browser writes require a live session.',
      ),
    );
    expect(
      progress,
      contains('if (kIsWeb) return; // No browser offline replay.'),
    );
    expect(progress, contains('if (kIsWeb || _staysOnPhone(itemId)) return;'));
  });
}
