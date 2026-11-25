import 'package:flutter_test/flutter_test.dart';
import 'package:absorb/services/auth_tokens.dart';

void main() {
  test('browser DTOs reject real/legacy credentials before persistence', () {
    for (final user in [
      {'accessToken':'real-access', 'refreshToken':'real-refresh'},
      {'token':'legacy-secret'},
      {'accessToken':'browser-cookie', 'refreshToken':'browser-cookie', 'token':'legacy-secret'},
    ]) {
      expect(() => AuthTokens.fromResponse({'user':user}, browser: true), throwsFormatException);
    }
    final tokens = AuthTokens.fromResponse({'user':{'accessToken':'browser-cookie','refreshToken':'browser-cookie'}}, browser:true);
    expect(tokens.token, 'browser-cookie');
    expect(tokens.isLegacy, false);
  });
  test('native DTOs preserve modern and legacy token behavior', () {
    expect(AuthTokens.fromResponse({'user':{'token':'legacy'}}).token, 'legacy');
    expect(AuthTokens.fromResponse({'user':{'accessToken':'access','refreshToken':'refresh'}}).refreshToken, 'refresh');
  });
}
