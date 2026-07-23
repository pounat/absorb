import 'dart:convert';

import '../utils/server_url.dart';

class SetupLinkData {
  final String serverUrl;
  final String username;
  final String apiKey;
  final String? userId;
  final Map<String, String> customHeaders;

  const SetupLinkData({
    required this.serverUrl,
    required this.username,
    required this.apiKey,
    required this.userId,
    required this.customHeaders,
  });
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
    final apiKey = account['token'];
    final userId = account['userId'];

    if (rawServerUrl is! String ||
        username is! String ||
        apiKey is! String ||
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
        apiKey.trim().isEmpty) {
      throw const SetupLinkException('Setup account is incomplete');
    }

    final rawHeaders = payload['customHeaders'];
    final headers = <String, String>{};
    if (rawHeaders != null) {
      if (rawHeaders is! Map) {
        throw const SetupLinkException('Custom headers are invalid');
      }
      for (final entry in rawHeaders.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw const SetupLinkException('Custom headers are invalid');
        }
        headers[entry.key as String] = entry.value as String;
      }
    }

    return SetupLinkData(
      serverUrl: serverUrl,
      username: username.trim(),
      apiKey: apiKey,
      userId: userId as String?,
      customHeaders: Map.unmodifiable(headers),
    );
  }
}
