import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absorb/services/api_service.dart';
import 'package:absorb/web_playback/web_playback_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('all browser start checkpoint recovery reads use strict authority', () {
    final source = File(
      'lib/services/audio_player_service.dart',
    ).readAsStringSync();
    final start = source.substring(
      source.indexOf('Future<String?> _playFromServer('),
      source.indexOf('// Compare server position vs local.'),
    );
    expect(start.indexOf('api.getWebItemProgress('), greaterThan(0));
    expect(
      start.indexOf('api.getWebItemProgress('),
      lessThan(start.indexOf('await api.startEpisodePlaybackSession(')),
    );
    expect(source, contains('readProgress: () => api.getWebItemProgress(key)'));
    expect(
      source,
      isNot(contains('readProgress: () => api.getItemProgress(key)')),
    );
    expect(
      source,
      isNot(contains('final webProgress = await api.getItemProgress(pKey)')),
    );
  });

  for (final baseline in [0.0, 100.0]) {
    for (final failure in [
      '404',
      '401',
      '403',
      '503',
      'malformed',
      'timeout',
    ]) {
      test(
        'actual API $failure at baseline $baseline gates checkpoint and recovery',
        () async {
          var writes = 0;
          final api = ApiService(
            baseUrl: 'https://synthetic.example',
            token: 'synthetic',
            httpClient: MockClient((request) async {
              if (request.method == 'POST') {
                writes++;
                return http.Response('OK', 200);
              }
              if (failure == 'timeout')
                throw TimeoutException('https://secret.invalid/?token=secret');
              return http.Response(
                failure == 'malformed' ? '{broken' : '{}',
                int.tryParse(failure) ?? 200,
              );
            }),
          );
          final session = WebPlaybackSession(
            clock: () => Duration.zero,
            serverPosition: baseline,
            readProgress: () => api.getWebItemProgress('book'),
            send: (p, t) => api.syncPlaybackSessionStatus(
              'session',
              currentTime: p,
              duration: 1000,
              timeListened: t,
            ),
          );
          session.sample(baseline + 10, audible: false);
          await session.checkpoint(force: true);
          final newBook = failure == '404' && baseline == 0;
          expect(writes, newBook ? 1 : 0);
          expect(session.recoveryRequired, !newBook);
          await session.checkpoint(force: true);
          expect(
            writes,
            newBook ? 1 : 0,
          ); // No retry after any read/conflict failure.
          if (failure == '404') {
            expect(
              await session.recoveryPosition(
                readProgress: () => api.getWebItemProgress('book'),
                readSession: () async => null,
              ),
              0,
            );
          } else {
            await expectLater(
              session.recoveryPosition(
                readProgress: () => api.getWebItemProgress('book'),
                readSession: () async => null,
              ),
              throwsA(isA<WebProgressReadException>()),
            );
            await expectLater(
              api.getWebItemProgress('book'),
              throwsA(
                predicate(
                  (error) =>
                      error is WebProgressReadException &&
                      !error.toString().contains('secret') &&
                      !error.toString().contains('https:'),
                ),
              ),
            );
          }
        },
      );
    }
  }

  test(
    'another device advances after zero start then failed preflight cannot overwrite',
    () async {
      var phase = 0;
      var writes = 0;
      final api = ApiService(
        baseUrl: 'https://synthetic.example',
        token: 'synthetic',
        httpClient: MockClient((request) async {
          if (request.method == 'POST') {
            writes++;
            return http.Response('OK', 200);
          }
          if (phase == 1) return http.Response('{}', 503);
          return http.Response(
            jsonEncode({
              'currentTime': phase == 0 ? 0 : 800,
              'duration': 1000,
              'isFinished': false,
            }),
            200,
          );
        }),
      );
      final initial = await api.getWebItemProgress('book');
      final session = WebPlaybackSession(
        clock: () => Duration.zero,
        serverPosition: (initial!['currentTime'] as num).toDouble(),
        readProgress: () => api.getWebItemProgress('book'),
        send: (p, t) => api.syncPlaybackSessionStatus(
          'session',
          currentTime: p,
          duration: 1000,
          timeListened: t,
        ),
      );
      phase = 1; // Another device is now at 800; this browser cannot read it.
      session.sample(10, audible: false);
      await session.checkpoint(force: true);
      expect(writes, 0);
      expect(session.recoveryRequired, isTrue);
      phase = 2;
      expect(
        await session.recoveryPosition(
          readProgress: () => api.getWebItemProgress('book'),
          readSession: () async => null,
        ),
        800,
      );
      await session.checkpoint(force: true);
      expect(
        writes,
        0,
      ); // A successful evidence read does not revive the old writer.
    },
  );

  for (final body in [
    '[]',
    '{}',
    'null',
    '{"currentTime":0,"duration":1000}',
    '{"currentTime":"0","duration":1000,"isFinished":false}',
    '{"currentTime":-1,"duration":1000,"isFinished":false}',
    '{"currentTime":1e999,"duration":1000,"isFinished":false}',
    '{"currentTime":1001,"duration":1000,"isFinished":false}',
    '{"currentTime":0,"duration":-1,"isFinished":false}',
    '{"currentTime":0,"duration":31536001,"isFinished":false}',
    '{"currentTime":0,"duration":1e999,"isFinished":false}',
  ]) {
    test('invalid audio progress DTO fails closed: $body', () async {
      final api = ApiService(
        baseUrl: 'https://synthetic.example',
        token: 'synthetic',
        httpClient: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        api.getWebItemProgress('book'),
        throwsA(isA<WebProgressReadException>()),
      );
    });
  }

  for (final baseline in [0.0, 100.0]) {
    test(
      'actual ten-second API timeout at $baseline rejects late progress',
      () async {
        var writes = 0;
        final gate = Completer<http.Response>();
        final api = ApiService(
          baseUrl: 'https://synthetic.example',
          token: 'synthetic',
          httpClient: MockClient((_) => gate.future),
        );
        final session = WebPlaybackSession(
          clock: () => Duration.zero,
          serverPosition: baseline,
          readProgress: () => api.getWebItemProgress('book'),
          send: (p, t) async {
            writes++;
            return 200;
          },
        );
        session.sample(baseline + 10, audible: false);
        await session.checkpoint(force: true);
        expect(writes, 0);
        expect(session.recoveryRequired, isTrue);
        gate.complete(
          http.Response(
            jsonEncode({
              'currentTime': 800,
              'duration': 1000,
              'isFinished': false,
            }),
            200,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        await session.checkpoint(force: true);
        expect(writes, 0);
      },
    );
  }

  test('failed real API preflight discards queued lifecycle delta', () async {
    var now = Duration.zero;
    var writes = 0;
    final gate = Completer<http.Response>();
    final api = ApiService(
      baseUrl: 'https://synthetic.example',
      token: 'synthetic',
      httpClient: MockClient((_) => gate.future),
    );
    final session = WebPlaybackSession(
      clock: () => now,
      readProgress: () => api.getWebItemProgress('book'),
      send: (p, t) async {
        writes++;
        return 200;
      },
    );
    session.sample(0, audible: true);
    now = const Duration(seconds: 10);
    session.sample(10, audible: true);
    final first = session.checkpoint();
    session.sample(400, audible: false);
    final queued = session.checkpoint(force: true);
    gate.complete(http.Response('{}', 503));
    await Future.wait([first, queued]);
    expect(writes, 0);
    expect(session.recoveryRequired, isTrue);
    now = const Duration(seconds: 100);
    await session.checkpoint(force: true);
    expect(writes, 0);
  });

  test('native legacy progress failure behavior is unchanged', () async {
    final api = ApiService(
      baseUrl: 'https://synthetic.example',
      token: 'synthetic',
      httpClient: MockClient((_) async => http.Response('{}', 503)),
    );
    expect(await api.getItemProgress('book'), isNull);
  });

  test(
    'actual API HTTP 503 at zero baseline freezes before any sync',
    () async {
      var writes = 0;
      final api = ApiService(
        baseUrl: 'https://synthetic.example',
        token: 'synthetic',
        httpClient: MockClient((request) async {
          if (request.method == 'GET') {
            expect(request.url.path, '/api/me/progress/book');
            return http.Response('{"error":"upstream_unavailable"}', 503);
          }
          writes++;
          return http.Response('OK', 200);
        }),
      );
      final session = WebPlaybackSession(
        clock: () => Duration.zero,
        readProgress: () => api.getWebItemProgress('book'),
        send: (p, t) => api.syncPlaybackSessionStatus(
          'session',
          currentTime: p,
          duration: 1000,
          timeListened: t,
        ),
      );
      session.sample(10, audible: false);
      await session.checkpoint(force: true);
      expect(writes, 0);
      expect(session.recoveryRequired, isTrue);
    },
  );
}
