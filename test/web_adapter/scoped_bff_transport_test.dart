// Actual production Dart request bodies sent to the real portable Node BFF.
import 'dart:convert';
import 'dart:io';
import 'package:absorb/services/browser_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'bff_transport_contract_test.dart' show SyntheticBrowser;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Process fixture;
  late Uri origin;
  late String upstream;
  setUpAll(() async {
    fixture = await Process.start('node', ['test/web_adapter/scoped_bff_fixture.mjs']);
    final ready = jsonDecode(await fixture.stdout.transform(utf8.decoder)
        .transform(const LineSplitter()).first) as Map<String, dynamic>;
    origin = Uri.parse(ready['url'] as String);
    upstream = ready['upstreamUrl'] as String;
  });
  tearDownAll(() async {
    fixture.kill();
    await fixture.exitCode;
  });
  for (final bookorbit in [false, true]) {
    test('scoped ${bookorbit ? 'BookOrbit explicit JSON' : 'ABS null body'} refresh and logout revoke only their cookie', () async {
      final first = SyntheticBrowser(origin);
      final other = SyntheticBrowser(origin);
      addTearDown(first.close);
      addTearDown(other.close);
      final prefix = bookorbit ? '/bookorbit/api/v1/auth' : '';
      final refreshPath = bookorbit ? '/api/v1/auth/refresh' : '/auth/refresh';
      final logoutPath = bookorbit ? '/api/v1/auth/logout' : '/logout';
      final mePath = bookorbit ? '/api/v1/auth/me' : '/api/me';
      Future<String> login(SyntheticBrowser client) async {
        final response = await BrowserAdapter.post(origin, origin.resolve('$prefix/login'),
            client: client, body: BrowserAdapter.loginBody(upstream, 'synthetic', 'synthetic-password'));
        expect(response.statusCode, 200, reason: response.body);
        return (jsonDecode(response.body) as Map)['webSessionRoute'] as String;
      }
      final route = await login(first);
      final otherRoute = await login(other);
      expect(route, matches(bookorbit
          ? r'^/bookorbit/sessions/[A-Za-z0-9_-]{24}$'
          : r'^/sessions/[A-Za-z0-9_-]{24}$'));
      final before = jsonDecode((await first.get(origin.resolve('/__synthetic_receipt'))).body) as List;
      final savedCookie = first.cookie;
      if (!bookorbit) {
        // Explicit empty bodies must still fail; do not weaken the BFF parser
        // or retire authority on a rejected JSON request to mask the regression.
        for (final path in [refreshPath, logoutPath]) {
          final empty = await BrowserAdapter.post(origin, origin.resolve('$route$path'),
              client: first, body: '');
          expect(empty.statusCode, 400);
          expect(jsonDecode(empty.body), {'error': 'invalid_json'});
        }
        expect((await first.get(origin.resolve('$route$mePath'))).statusCode, 200);
      }
      expect((await first.get(origin.resolve('$otherRoute$mePath'))).statusCode, 401);
      final refresh = await BrowserAdapter.post(origin, origin.resolve('$route$refreshPath'),
          client: first, body: bookorbit ? '{}' : null);
      // No test-authored body for ABS: this must pass the real BFF JSON parser.
      expect(refresh.statusCode, 200, reason: refresh.body);
      final logout = await BrowserAdapter.post(origin, origin.resolve('$route$logoutPath'),
          client: first, body: bookorbit ? '{}' : null);
      expect(logout.statusCode, 200, reason: logout.body);
      expect(logout.headers['set-cookie'], contains('Max-Age=0'));
      first.cookie = savedCookie;
      expect((await first.get(origin.resolve('$route$mePath'))).statusCode, 401);
      expect((await other.get(origin.resolve('$otherRoute$mePath'))).statusCode, 200);
      final after = jsonDecode((await first.get(origin.resolve('/__synthetic_receipt'))).body) as List;
      final logoutCalls = after.skip(before.length).where((r) => r['path'] ==
          (bookorbit ? '/api/v1/auth/logout' : '/logout')).toList();
      expect(logoutCalls, hasLength(1));
      expect(after.skip(before.length).any((r) => (r['path'] as String).contains('allDevices')), false);
    });
  }
}
