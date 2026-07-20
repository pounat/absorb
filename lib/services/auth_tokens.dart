class AuthTokens {
  final String? accessToken;
  final String? refreshToken;
  final String? legacyToken;

  const AuthTokens({this.accessToken, this.refreshToken, this.legacyToken});

  String? get token => accessToken ?? legacyToken;
  bool get isLegacy => accessToken == null;

  factory AuthTokens.fromResponse(Map<String, dynamic> response) {
    final rawUser = response['user'];
    final user = rawUser is Map<String, dynamic> ? rawUser : null;

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
