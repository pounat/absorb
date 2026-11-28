import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absorb/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('native refresh/logout preserve empty bodies and refresh credentials', () async {
    final requests = <http.Request>[];
    final api = ApiService(baseUrl: 'https://fixture.example', token: 'synthetic-access',
        refreshToken: 'synthetic-refresh', httpClient: MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode({'user': {
        'accessToken': 'synthetic-access-next', 'refreshToken': 'synthetic-refresh-next',
      }}), 200);
    }));
    expect(await api.refreshAccessTokenNow(), true);
    expect(await api.revokeServerSession(), true);
    expect(requests.map((r) => r.url.path), ['/auth/refresh', '/logout']);
    expect(requests.map((r) => r.body), ['', '']);
    expect(requests.first.headers['x-refresh-token'], 'synthetic-refresh');
    expect(requests.last.headers['x-refresh-token'], 'synthetic-refresh-next');
  });
  test('open-session reconciliation reads the singular ABS session endpoint', () async {
    final api = ApiService(baseUrl:'https://fixture.example', token:'synthetic', httpClient:MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/session/synthetic-session');
      return http.Response(jsonEncode({'id':'synthetic-session','currentTime':42,'timeListening':8}), 200);
    }));
    final session = await api.getPlaybackSession('synthetic-session');
    expect(session?['currentTime'], 42);
    expect(session?['timeListening'], 8);
  });
  test('native cover and file URLs preserve upstream credential behavior', () {
    final api = ApiService(baseUrl:'https://fixture.example', token:'synthetic');
    expect(api.getCoverUrl('book'), 'https://fixture.example/api/items/book/cover?token=synthetic&width=400');
    expect(api.buildFileUrl('book', '1'), 'https://fixture.example/api/items/book/file/1?token=synthetic');
  });
  test('sync and close accept plain OK and retain native credential behavior', () async {
    final requests = <http.Request>[];
    final api = ApiService(baseUrl:'https://fixture.example', token:'synthetic', httpClient:MockClient((request) async {
      requests.add(request);
      return http.Response('OK', 200);
    }));
    expect(await api.syncPlaybackSession('s', currentTime:42, duration:600, timeListened:3), true);
    await api.closePlaybackSession('s');
    expect(requests.map((r) => r.url.path), ['/api/session/s/sync','/api/session/s/close']);
    expect(jsonDecode(requests.first.body), {'currentTime':42.0,'duration':600.0,'timeListened':3});
    expect(requests.first.headers['Authorization'], 'Bearer synthetic');
  });
}
