import 'dart:convert';
import 'package:absorb/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  for (final status in [200, 401, 403, 503]) {
    test('BookOrbit protected identity maps without login markers: $status', () async {
      final api = BookOrbitApiService(baseUrl: 'https://synthetic.example/base', token: 'synthetic',
        httpClient: MockClient((r) async {
          expect(r.method, 'GET');
          expect(r.url.toString(), 'https://synthetic.example/base/api/v1/auth/me');
          return http.Response(jsonEncode(status == 200
            ? {'id': 7, 'username': 'reader', 'permissions': <String>[]}
            : {'error': 'Synthetic failure'}), status);
        }));
      final identity = await api.browserSessionIdentity();
      expect(identity.status, status);
      expect(identity.user?['username'], status == 200 ? 'reader' : null);
    });
  }
  for (final status in [200, 401, 403, 502, 503]) {
    test('browser identity retains status $status without login-only markers', () async {
      final api = ApiService(baseUrl: 'https://synthetic.example', token: 'browser-cookie',
        httpClient: MockClient((r) async => http.Response(jsonEncode(
          status == 200 ? {'id': '7', 'username': 'Synthetic reader'} : {}), status)));
      final result = await api.browserSessionIdentity();
      expect(result.status, status);
      expect(result.user?['id'], status == 200 ? '7' : null);
    });
  }
  for (final user in [{'id': '', 'username': 'reader'}, {'id': 7, 'username': 'reader'}, {'id': '7'}, <String, dynamic>{}]) {
    test('malformed identity cannot authorize: $user', () async {
      final api = ApiService(baseUrl: 'https://synthetic.example', token: 'browser-cookie',
        httpClient: MockClient((r) async => http.Response(jsonEncode(user), 200)));
      await expectLater(api.browserSessionIdentity(), throwsFormatException);
    });
  }
}
