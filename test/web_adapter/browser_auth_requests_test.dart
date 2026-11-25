import 'dart:convert';

import 'package:absorb/services/browser_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final origin = Uri.parse('https://synthetic.example/absorb/');
  for (final path in [
    '/auth/refresh', '/logout',
    '/sessions/Abcdef0123456789_-ABCDEF/auth/refresh',
    '/sessions/Abcdef0123456789_-ABCDEF/logout',
  ]) {
    test('actual browser transport supplies bounded JSON for $path', () async {
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return http.Response('{}', 200);
      });
      await BrowserAdapter.post(origin, origin.resolve(path), client: client,
          headers: {'x-refresh-token': 'synthetic', 'Authorization': 'synthetic'});
      expect(sent.method, 'POST');
      expect(sent.url.path, path);
      expect(sent.headers['content-type'], 'application/json');
      expect(sent.headers.containsKey('x-refresh-token'), false);
      expect(sent.headers.containsKey('authorization'), false);
      expect(sent.body, '{}');
      expect(sent.bodyBytes.length, lessThanOrEqualTo(65536));
      expect(jsonDecode(sent.body), isEmpty);
    });
  }
  test('scoped mutations retain same-origin and credential URL rejection', () {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response('{}', 200);
    });
    for (final destination in [
      'https://other.example/sessions/Abcdef0123456789_-ABCDEF/logout',
      'https://synthetic.example/logout?token=synthetic',
      'https://synthetic.example/logout#fragment',
      'https://synthetic@synthetic.example/logout',
    ]) {
      expect(() => BrowserAdapter.post(origin, Uri.parse(destination), client: client),
          throwsArgumentError);
    }
    expect(calls, 0);
  });
  test('browser defaults do not alter other endpoints or explicit payloads', () async {
    final bodies = <String>[];
    final client = MockClient((request) async {
      bodies.add(request.body);
      return http.Response('{}', 200);
    });
    const label = 'Abcdef0123456789_-ABCDEF';
    final untouched = [
      '/login', '/auth/refresh/', '/logout/', '/prefix/logout',
      '/sessions/$label/logout/extra', '/sessions/$label/auth/refresh/',
      '/sessions/${label}x/logout', '/sessions/${label.substring(1)}/logout',
      '/sessions/Abcdef0123456789.!ABCDEF0/logout', '/sessions//logout',
      '/unknown/sessions/$label/logout', '/sessions/$label/login',
      '/bookorbit/sessions/$label/logout',
      '/bookorbit/sessions/$label/api/v1/auth/logout',
    ];
    for (final path in untouched) {
      await BrowserAdapter.post(origin, origin.resolve(path), client: client);
    }
    for (final path in ['/logout', '/sessions/$label/logout']) {
      await BrowserAdapter.post(origin, origin.resolve(path), client: client, body: '{"explicit":true}');
      await BrowserAdapter.post(origin, origin.resolve(path), client: client, body: '');
    }
    expect(bodies, [...List.filled(untouched.length, ''), '{"explicit":true}', '', '{"explicit":true}', '']);
  });
}
