// Real BFF + actual production browser POST helper, SYNTHETIC upstream only.
// Start synthetic_bff_fixture.mjs and set SYNTHETIC_BFF_URL to enable.
import 'dart:convert';
import 'dart:io';

import 'package:absorb/services/auth_tokens.dart';
import 'package:absorb/services/api_service.dart';
import 'package:absorb/web_playback/web_playback_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absorb/services/browser_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Deliberately real loopback HTTP, not Flutter's widget-test 400 override.
class SyntheticNetwork extends HttpOverrides {}

// Emulate only browser-managed Origin/cookie headers. All request bodies come
// from the same transport used by ApiService's kIsWeb branch, never this harness.
class SyntheticBrowser extends http.BaseClient {
  final http.Client inner = IOClient(SyntheticNetwork().createHttpClient(null));
  final Uri origin;
  String? cookie;
  final bool browserPolicy;
  SyntheticBrowser(this.origin, {this.browserPolicy = false});
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (browserPolicy) {
      BrowserAdapter.requestUri(origin, request.url);
      final safe = BrowserAdapter.requestHeaders(request.headers);
      request.headers..clear()..addAll(safe);
    }
    // BFF requires an exact HTTPS Origin, even on this loopback HTTP fixture.
    request.headers['Origin'] = 'https://synthetic.example';
    if (cookie != null) request.headers['Cookie'] = cookie!;
    final response = await inner.send(request);
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && cookie == null) cookie = setCookie.split(';').first;
    return response;
  }
  @override
  void close() => inner.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final url = Platform.environment['SYNTHETIC_BFF_URL'];
  test('real BFF progress failure through browser policy freezes actual API writer', () async {
    SharedPreferences.setMockInitialValues({});
    final origin = Uri.parse(url!);
    final client = SyntheticBrowser(origin, browserPolicy: true);
    addTearDown(client.close);
    final login = await BrowserAdapter.post(origin, origin.resolve('/login'),
        client: client, body: jsonEncode({'username': 'synthetic', 'password': 'SYNTHETIC_PASSWORD'}));
    expect(login.statusCode, 200);
    final failedRead = await client.get(origin.resolve('/api/me/progress/synthetic-book'));
    expect(failedRead.statusCode, 502); // BFF sanitizes upstream 503.
    final api = ApiService(baseUrl: url, token: BrowserAdapter.cookieSentinel, httpClient: client);
    var writes = 0;
    final owner = WebPlaybackSession(clock: () => Duration.zero,
        readProgress: () => api.getWebItemProgress('synthetic-book'),
        send: (p, t) async { writes++; return 200; });
    owner.sample(10, audible: false);
    await owner.checkpoint(force: true);
    expect(writes, 0);
    expect(owner.recoveryRequired, isTrue);
    await expectLater(api.getWebItemProgress('synthetic-book'), throwsA(isA<WebProgressReadException>()));
  }, skip: url == null ? 'Set SYNTHETIC_BFF_URL; synthetic fixture must be running' : false);
  test('real BFF accepts adapter refresh, integer generation writes and revokes cookie', () async {
    final origin = Uri.parse(url!);
    final client = SyntheticBrowser(origin);
    addTearDown(client.close);
    final priorCalls = (jsonDecode((await client.get(origin.resolve('/__synthetic_receipt'))).body) as List).length;
    Future<http.Response> post(String path, {Object? body}) =>
        BrowserAdapter.post(origin, origin.resolve(path), client: client, body: body);

    final login = await post('/login', body: jsonEncode({
      'username': 'synthetic', 'password': 'SYNTHETIC_PASSWORD',
    }));
    expect(login.statusCode, 200);
    expect(login.headers['set-cookie'], contains('HttpOnly'));
    expect(client.cookie, isNotNull);

    // No {} supplied by test: this is the regression in the adapter's request.
    final refresh = await post('/auth/refresh');
    expect(refresh.statusCode, 200, reason: refresh.body);
    final tokens = AuthTokens.fromResponse(jsonDecode(refresh.body), browser: true);
    expect(tokens.accessToken, BrowserAdapter.cookieSentinel);
    expect(tokens.refreshToken, BrowserAdapter.cookieSentinel);

    final start = await post('/api/items/synthetic-book/play',
        body: jsonEncode(BrowserAdapter.playbackOptions((_) => 'probably')));
    expect(start.statusCode, 200, reason: start.body);
    final session = jsonDecode(start.body) as Map<String, dynamic>;
    expect(session['webGeneration'], isA<int>());
    final writes = BrowserSessionWrites()..register(session);
    final id = session['id'] as String;
    final syncBody = {...writes.next(id), 'currentTime': 10, 'timeListened': 2, 'duration': 100};
    final sync = await post('/api/session/$id/sync', body: jsonEncode(syncBody));
    expect(sync.statusCode, 200, reason: sync.body);
    expect(sync.body, 'OK');
    final close = await post('/api/session/$id/close', body: jsonEncode(writes.next(id)));
    expect(close.statusCode, 200, reason: close.body);

    final logout = await post('/logout');
    expect(logout.statusCode, 200, reason: logout.body);
    expect(logout.headers['set-cookie'], contains('Max-Age=0'));
    // Deliberately replay the original cookie; server authority must be revoked.
    final me = await client.get(origin.resolve('/api/me'));
    expect(me.statusCode, 401);
    final receipt = (jsonDecode((await client.get(origin.resolve('/__synthetic_receipt'))).body) as List).skip(priorCalls).toList();
    final upstreamLogout = receipt.where((r) => r['path'] == '/logout').single;
    expect(upstreamLogout['refreshToken'], 'synthetic-refresh-next');
    expect(receipt.any((r) => (r['path'] as String).contains('allDevices')), false);
    final upstreamSync = receipt.where((r) => r['path'] == '/api/session/$id/sync').single;
    expect(upstreamSync['body'], {'currentTime': 10, 'timeListened': 2, 'duration': 100});
  }, skip: url == null ? 'Set SYNTHETIC_BFF_URL; synthetic fixture must be running' : false);
}
