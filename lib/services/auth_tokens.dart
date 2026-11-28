class AuthTokens {
  final String? accessToken;
  final String? refreshToken;
  final String? legacyToken;

  const AuthTokens({this.accessToken, this.refreshToken, this.legacyToken});

  String? get token => accessToken ?? legacyToken;
  bool get isLegacy => accessToken == null;

  factory AuthTokens.fromResponse(Map<String, dynamic> response, {bool browser = false}) {
    final rawUser = response['user'];
    final user = rawUser is Map<String, dynamic> ? rawUser : null;

    if (browser) {
      if (user?['accessToken'] != 'browser-cookie' ||
          user?['refreshToken'] != 'browser-cookie' ||
          user?.containsKey('token') == true ||
          response.containsKey('accessToken') || response.containsKey('refreshToken') || response.containsKey('token')) {
        throw const FormatException('Unsafe browser authentication DTO');
      }
      final route = response['webSessionRoute'];
      if (route != null) {
        if (route is! String || !RegExp(r'^/(?:bookorbit/)?sessions/[A-Za-z0-9_-]{24}$').hasMatch(route)) {
          throw const FormatException('Invalid browser session route');
        }
        return AuthTokens(accessToken: 'browser-cookie@$route', refreshToken: 'browser-cookie');
      }
      return const AuthTokens(accessToken: 'browser-cookie', refreshToken: 'browser-cookie');
    }
    return AuthTokens(
      accessToken:
          _readToken(user?['accessToken']) ??
          _readToken(response['accessToken']),
      refreshToken:
          _readToken(user?['refreshToken']) ??
          _readToken(response['refreshToken']),
      legacyToken: _readToken(user?['token']),
    );
  }

  static String? _readToken(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }
}
