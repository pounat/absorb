import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/browser_adapter.dart';
void main() {
  test('browser login payload preserves typed upstream separately from cookie origin', () {
    final payload = BrowserAdapter.loginBody('https://shelf.example.test/abs/', 'reader', 'synthetic-password');
    expect(jsonDecode(payload), {'serverUrl': 'https://shelf.example.test/abs/', 'username': 'reader', 'password': 'synthetic-password', 'sessionRouting': true});
  });
}
