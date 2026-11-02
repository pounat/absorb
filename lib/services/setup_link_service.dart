import 'dart:convert';

import '../utils/server_url.dart';

class SetupLinkData {
  final String serverUrl;
  final String username;

  /// Signs straight in. Null on a BookOrbit password link.
  final String? apiKey;

  /// A BookOrbit password link's token: the person picks their own password
  /// with it, then signs in with that.
  final String? passwordToken;
  final String? userId;
  final Map<String, String> customHeaders;

  const SetupLinkData({
    required this.serverUrl,
    required this.username,
    required this.apiKey,
    required this.userId,
    required this.customHeaders,
    this.passwordToken,
  });

  bool get setsPassword => passwordToken != null;
}

class SetupLinkException implements Exception {
  final String message;

  const SetupLinkException(this.message);

  @override
  String toString() => 'SetupLinkException: $message';
}

class SetupLinkService {
  static const scheme = 'absorb';
  static const host = 'setup';
  static const _maxEncodedLength = 16000;

  static bool isSetupLink(Uri uri) =>
      uri.scheme.toLowerCase() == scheme && uri.host.toLowerCase() == host;

  static Uri createLink(Map<String, dynamic> payload) {
    parsePayload(payload);
    final json = jsonEncode(payload);
    final encoded = base64Url.encode(utf8.encode(json)).replaceAll('=', '');
    return Uri(scheme: scheme, host: host, pathSegments: [encoded]);
  }

  /// A link that lets someone pick the password for a new or reset
  /// BookOrbit account, then signs them in. [token] is the one in the
  /// server's password link, so it works for as long as that link does.
  static Uri createBookOrbitPasswordLink({
    required String serverUrl,
    required String username,
    required String token,
    Map<String, String> customHeaders = const {},
  }) =>
      createLink({
        'version': 3,
        'setup': true,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'accounts': [
          {
            'serverUrl': serverUrl,
            'username': username,
            'backend': 'bookorbit',
            'passwordToken': token,
          },
        ],
        if (customHeaders.isNotEmpty) 'customHeaders': customHeaders,
      });

  // A line break in a header would let a link smuggle extra headers or a
  // second request line into every call to the server.
  static final _headerName = RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]{1,128}$");
  static const _maxHeaderValueLength = 4096;

  static SetupLinkData parseLink(Uri uri) {
    if (!isSetupLink(uri) || uri.pathSegments.length != 1) {
      throw const SetupLinkException('Not an Absorb setup link');
    }

    final encoded = uri.pathSegments.single;
    if (encoded.isEmpty || encoded.length > _maxEncodedLength) {
      throw const SetupLinkException('Invalid setup link length');
    }

    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(encoded)),
      );
      final payload = jsonDecode(decoded);
      if (payload is! Map<String, dynamic>) {
        throw const SetupLinkException('Setup payload is not an object');
      }
      return parsePayload(payload);
    } on SetupLinkException {
      rethrow;
    } catch (_) {
      throw const SetupLinkException('Setup link could not be decoded');
    }
  }

  static SetupLinkData parsePayload(Map<String, dynamic> payload) {
    if (payload['setup'] != true || payload['version'] is! int) {
      throw const SetupLinkException('Setup payload is missing its version');
    }

    final accounts = payload['accounts'];
    if (accounts is! List || accounts.length != 1 || accounts.single is! Map) {
      throw const SetupLinkException('Setup payload must contain one account');
    }

    final account = Map<String, dynamic>.from(accounts.single as Map);
    final rawServerUrl = account['serverUrl'];
    final username = account['username'];
    final passwordToken = account['backend'] == 'bookorbit' ? account['passwordToken'] : null;
    final apiKey = passwordToken is String ? '' : account['token'];
    final userId = account['userId'];

    if (rawServerUrl is! String ||
        username is! String ||
        apiKey is! String ||
        (passwordToken != null && passwordToken is! String) ||
        (userId != null && userId is! String)) {
      throw const SetupLinkException('Setup account fields are invalid');
    }

    final serverUrl = normalizeServerUrl(rawServerUrl);
    final parsedServerUrl = Uri.tryParse(serverUrl);
    if (serverUrl.isEmpty ||
        parsedServerUrl == null ||
        !parsedServerUrl.hasAuthority ||
        !{'http', 'https'}.contains(parsedServerUrl.scheme.toLowerCase()) ||
        username.trim().isEmpty ||
        (passwordToken is String ? passwordToken.trim().isEmpty : apiKey.trim().isEmpty)) {
      throw const SetupLinkException('Setup account is incomplete');
    }

    final rawHeaders = payload['customHeaders'];
    final headers = <String, String>{};
    if (rawHeaders != null) {
      if (rawHeaders is! Map) {
        throw const SetupLinkException('Custom headers are invalid');
      }
      for (final entry in rawHeaders.entries) {
        if (entry.key is! String ||
            entry.value is! String ||
            !_headerName.hasMatch(entry.key as String) ||
            (entry.value as String).length > _maxHeaderValueLength ||
            (entry.value as String).contains(RegExp(r'[\r\n\x00]'))) {
          throw const SetupLinkException('Custom headers are invalid');
        }
        headers[entry.key as String] = entry.value as String;
      }
    }

    return SetupLinkData(
      serverUrl: serverUrl,
      username: username.trim(),
      apiKey: passwordToken is String ? null : apiKey,
      passwordToken: passwordToken as String?,
      userId: userId as String?,
      customHeaders: Map.unmodifiable(headers),
    );
  }
}
