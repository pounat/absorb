import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/web_playback/web_playback_session.dart';

void main() {
  test(
    'latest progress wins at start except finished replay starts at session zero',
    () {
      expect(
        WebPlaybackSession.resumePosition(100, {
          'currentTime': 50,
          'lastUpdate': 999,
        }),
        50,
      );
      expect(
        WebPlaybackSession.resumePosition(0, {
          'currentTime': 900,
          'isFinished': true,
        }),
        0,
      );
      expect(WebPlaybackSession.resumePosition(0, null), 0);
      expect(WebPlaybackSession.resumePosition(100, null), 0);
    },
  );
  test(
    'ambiguous in-flight write discards coalesced nonzero checkpoint',
    () async {
      var now = Duration.zero;
      final gate = Completer<int?>();
      final writes = <List<num>>[];
      final session = WebPlaybackSession(
        clock: () => now,
        send: (p, t) {
          writes.add([p, t]);
          return gate.future;
        },
      );
      session.sample(0, audible: true);
      now = const Duration(seconds: 10);
      session.sample(10, audible: true);
      final first = session.checkpoint();
      now = const Duration(seconds: 20);
      session.sample(20, audible: true);
      final queued = session.checkpoint(force: true);
      gate.complete(null);
      await Future.wait([first, queued]);
      await session.checkpoint(force: true);
      expect(writes, [
        [10, 10],
      ]);
      expect(session.recoveryRequired, isTrue);
    },
  );
  test(
    'close waits for the write and runs only once without another delta',
    () async {
      var now = Duration.zero;
      final gate = Completer<int?>();
      final events = <String>[];
      final session = WebPlaybackSession(
        clock: () => now,
        send: (p, t) {
          events.add('sync:$t');
          return gate.future;
        },
      );
      session.sample(0, audible: true);
      now = const Duration(seconds: 10);
      session.sample(10, audible: true);
      final write = session.checkpoint();
      final close = session.close(() async {
        events.add('close');
      });
      expect(events, ['sync:10']);
      gate.complete(200);
      await Future.wait([write, close]);
      await session.close(() async {
        events.add('duplicate');
      });
      expect(events, ['sync:10', 'close']);
    },
  );

  test(
    'rate transition accounts preceding interval at its previous speed',
    () async {
      var now = Duration.zero;
      final writes = <List<num>>[];
      final session = WebPlaybackSession(
        clock: () => now,
        send: (p, t) async {
          writes.add([p, t]);
          return 200;
        },
      );
      session.sample(0, audible: true);
      now = const Duration(seconds: 5);
      session.sample(5, audible: true, rate: 2);
      now = const Duration(seconds: 10);
      session.sample(15, audible: true, rate: 2);
      await session.checkpoint();
      expect(writes, [
        [15, 10],
      ]);
    },
  );

  test(
    'paused seeks and buffering cannot bank offline listening time',
    () async {
      var now = Duration.zero;
      final writes = <List<num>>[];
      final session = WebPlaybackSession(
        clock: () => now,
        send: (p, t) async {
          writes.add([p, t]);
          return 200;
        },
      );
      session.sample(10, audible: true, rate: 0.5);
      now = const Duration(seconds: 4);
      session.sample(12, audible: false, rate: 0.5); // pause tail
      await session.checkpoint(force: true);
      now = const Duration(seconds: 200);
      session.sample(800, audible: false); // paused chapter jump
      await session.checkpoint(force: true);
      now = const Duration(seconds: 300);
      session.sample(800, audible: true); // stalled resume
      now = const Duration(seconds: 310);
      session.sample(800, audible: false); // buffering
      await session.checkpoint(force: true);
      expect(writes, [
        [12, 4],
        [800, 0],
        [800, 0],
      ]);
    },
  );
  test(
    'retirement during progress read prevents dispatch and late recovery',
    () async {
      var now = Duration.zero;
      var writes = 0;
      final gate = Completer<Map<String, dynamic>?>();
      final session = WebPlaybackSession(
        clock: () => now,
        readProgress: () => gate.future,
        send: (p, t) async {
          writes++;
          return 200;
        },
      );
      session.sample(0, audible: true);
      now = const Duration(seconds: 10);
      session.sample(10, audible: true);
      final write = session.checkpoint();
      session.retire();
      gate.complete({'currentTime': 0});
      await write;
      expect(writes, 0);
      await session.checkpoint(force: true);
      expect(writes, 0);
    },
  );

  test(
    'newer other-device progress blocks stale checkpoint even when behind local',
    () async {
      var now = Duration.zero;
      var writes = 0;
      final session = WebPlaybackSession(
        clock: () => now,
        send: (p, t) async {
          writes++;
          return 200;
        },
        readProgress: () async => {'currentTime': 50, 'lastUpdate': 999999},
        serverPosition: 100,
      );
      session.sample(100, audible: true);
      now = const Duration(seconds: 10);
      session.sample(110, audible: true);
      await session.checkpoint();
      expect(writes, 0);
      expect(session.recoveryRequired, isTrue);
    },
  );

  test(
    'retired owner cannot close or send queued lifecycle position',
    () async {
      var now = Duration.zero;
      final gate = Completer<int?>();
      var writes = 0;
      var closes = 0;
      final session = WebPlaybackSession(
        clock: () => now,
        send: (p, t) {
          writes++;
          return gate.future;
        },
      );
      session.sample(0, audible: true);
      now = const Duration(seconds: 10);
      session.sample(10, audible: true);
      final first = session.checkpoint();
      final close = session.close(() async {
        closes++;
      });
      session.retire();
      gate.complete(200);
      await Future.wait([first, close]);
      expect(writes, 1);
      expect(closes, 0);
    },
  );
  test(
    'explicit recovery reads latest progress before choosing server over checkpoint',
    () async {
      final gate = Completer<Map<String, dynamic>?>();
      var sessionReads = 0;
      final session = WebPlaybackSession(
        clock: () => Duration.zero,
        send: (p, t) async => 200,
      );
      session.sample(100, audible: false);
      final position = session.recoveryPosition(
        readProgress: () => gate.future,
        readSession: () async {
          sessionReads++;
          return {'currentTime': 90, 'timeListening': 10};
        },
      );
      gate.complete({'currentTime': 800, 'lastUpdate': 99999});
      expect(await position, 800);
      expect(sessionReads, 1);
      expect(
        await session.recoveryPosition(
          readProgress: () async => null, // Confirmed absent row, not a read failure.
          readSession: () async => null,
        ),
        0,
      );
    },
  );

  test(
    'lifecycle writes coalesce behind pending write and stale close is inert',
    () async {
      var now = Duration.zero;
      final gate = Completer<int?>();
      final writes = <List<num>>[];
      final session = WebPlaybackSession(
        clock: () => now,
        send: (p, t) {
          writes.add([p, t]);
          return writes.length == 1 ? gate.future : Future.value(200);
        },
      );
      session.sample(0, audible: true);
      now = const Duration(seconds: 10);
      session.sample(10, audible: true);
      final first = session.checkpoint();
      now = const Duration(seconds: 11);
      session.sample(11, audible: false);
      final pause = session.checkpoint(force: true);
      session.sample(400, audible: false);
      final visibility = session.checkpoint(force: true);
      expect(writes, [
        [10, 10],
      ]);
      gate.complete(200);
      await Future.wait([first, pause, visibility]);
      expect(writes, [
        [10, 10],
        [400, 1],
      ]);
    },
  );

  for (final status in <int?>[null, 404, 409, 502]) {
    test(
      'ambiguous nonzero write $status freezes every automatic retry',
      () async {
        var now = Duration.zero;
        final writes = <List<num>>[];
        final session = WebPlaybackSession(
          clock: () => now,
          send: (p, t) async {
            writes.add([p, t]);
            return status;
          },
        );
        session.sample(0, audible: true);
        now = const Duration(seconds: 10);
        session.sample(10, audible: true);
        await session.checkpoint();
        for (var i = 20; i <= 100; i += 10) {
          now = Duration(seconds: i);
          session.sample(i.toDouble(), audible: true);
          await session.checkpoint(force: true);
        }
        expect(writes, [
          [10, 10],
        ]);
      },
    );
  }
  test(
    'ten second wall checkpoint counts audible seconds at 2x, not distance',
    () async {
      var now = Duration.zero;
      final writes = <List<num>>[];
      final session = WebPlaybackSession(
        clock: () => now,
        send: (position, listened) async {
          writes.add([position, listened]);
          return 200;
        },
      );
      session.sample(100, audible: true, rate: 2);
      for (var i = 1; i <= 10; i++) {
        now = Duration(seconds: i);
        session.sample(100 + i * 2.0, audible: true, rate: 2);
        await session.checkpoint();
      }
      expect(writes, [
        [120, 10],
      ]);
    },
  );
}
