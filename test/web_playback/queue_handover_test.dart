import 'dart:io';

import 'package:absorb/web_playback/queue_handover_policy.dart';
import 'package:absorb/web_playback/web_playback_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('queued B cannot send its position through A browser owner', () async {
    var now = Duration.zero;
    final writes = <String>[];
    final events = <String>[];
    WebPlaybackSession owner(String book, double baseline) =>
        WebPlaybackSession(
          clock: () => now,
          serverPosition: baseline,
          readProgress: () async => {'currentTime': baseline},
          send: (position, listened) async {
            writes.add('$book/session-$book:$position:$listened');
            return 200;
          },
        );
    final a = owner('A', 170);
    var active = a;
    active.sample(170, audible: true);
    now = const Duration(seconds: 1);
    active.sample(171, audible: true);

    // Same boundary as the service: cached cross-book audio/promotion retains
    // the writer; ordinary completion -> playItem retires it and starts B.
    if (allowsNativeCrossBookHandover(isWeb: true)) {
      events.add('cached-preload-B');
      events.add('metadata-only-B');
    } else {
      await active.checkpoint(force: true);
      active.retire();
      events.add('retire-A');
      active = owner('B', 0);
      events.add('fresh-owned-start-B');
    }
    active.sample(0, audible: true);
    for (var second = 1; second <= 8; second++) {
      now = Duration(seconds: second + 1);
      active.sample(second.toDouble(), audible: true);
    }
    await active.checkpoint(force: true);
    // Even a queued/stale timer callback cannot resurrect A after handover.
    a.sample(8, audible: true);
    await a.checkpoint(force: true);

    expect(
      writes.where((write) => write.startsWith('A/session-A:8.')),
      isEmpty,
    );
    expect(events, ['retire-A', 'fresh-owned-start-B']);
    expect(writes, ['A/session-A:171.0:1', 'B/session-B:8.0:8']);
  });

  test('native cached prebuffer and metadata-only handover stay enabled', () {
    expect(allowsNativeCrossBookHandover(isWeb: false), isTrue);
  });

  test('service gates both native entry points before any side effects', () {
    final source = File(
      'lib/services/audio_player_service.dart',
    ).readAsStringSync();
    for (final method in ['_maybePreloadNextBook', '_onAutoQueueAdvanced']) {
      expect(
        source,
        contains(
          'void $method() {\n'
          '    if (!allowsNativeCrossBookHandover(isWeb: kIsWeb)) return;',
        ),
      );
    }
    // The normal web start still retires the old owner before changing books,
    // and installs a newly owned strict progress reader/session writer.
    final start = source.substring(
      source.indexOf('final playbackGeneration = ++_playbackGeneration;'),
    );
    expect(
      start.indexOf('owner?.retire();'),
      lessThan(start.indexOf('_currentItemId = itemId;')),
    );
    expect(source, contains('readProgress: () => api.getWebItemProgress(key)'));
    expect(source, contains('nativeSessionSync: !api.isBookOrbit,'));
    expect(source, contains('send: (pos, listened) {'));
    expect(
      source,
      contains('return api.syncPlaybackSessionStatus(id,'),
    );
  });
}
