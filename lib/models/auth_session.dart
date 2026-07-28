class AuthSessionDeviceInfo {
  final String? browserName;
  final String? browserVersion;
  final String? osName;
  final String? osVersion;
  final String? deviceType;
  final String? model;
  final String? vendor;

  const AuthSessionDeviceInfo({
    this.browserName,
    this.browserVersion,
    this.osName,
    this.osVersion,
    this.deviceType,
    this.model,
    this.vendor,
  });

  factory AuthSessionDeviceInfo.fromJson(Map<String, dynamic> json) {
    return AuthSessionDeviceInfo(
      browserName: json['browserName'] as String?,
      browserVersion: json['browserVersion'] as String?,
      osName: json['osName'] as String?,
      osVersion: json['osVersion'] as String?,
      deviceType: json['deviceType'] as String?,
      model: json['model'] as String?,
      vendor: json['vendor'] as String?,
    );
  }

  String? get deviceLabel {
    final parts = <String?>[
      vendor,
      model,
      deviceType,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  String? get softwareLabel {
    final browser = [
      browserName,
      browserVersion,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
    final os = [
      osName,
      osVersion,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
    final parts = [browser, os].where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' on ');
  }
}

class AuthSession {
  final String id;
  final String? ipAddress;
  final String? userAgent;
  final AuthSessionDeviceInfo? deviceInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool current;

  const AuthSession({
    required this.id,
    this.ipAddress,
    this.userAgent,
    this.deviceInfo,
    this.createdAt,
    this.updatedAt,
    this.current = false,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawDeviceInfo = json['deviceInfo'];
    return AuthSession(
      id: json['id'] as String? ?? '',
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      deviceInfo: rawDeviceInfo is Map<String, dynamic>
          ? AuthSessionDeviceInfo.fromJson(rawDeviceInfo)
          : null,
      createdAt: _dateFromEpoch(json['createdAt']),
      updatedAt: _dateFromEpoch(json['updatedAt']),
      current: json['current'] == true,
    );
  }

  static DateTime? _dateFromEpoch(Object? value) {
    if (value is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
}

class AuthSessionsPage {
  final List<AuthSession> sessions;
  final int total;
  final int numPages;
  final int page;
  final int itemsPerPage;

  const AuthSessionsPage({
    required this.sessions,
    required this.total,
    required this.numPages,
    required this.page,
    required this.itemsPerPage,
  });

  factory AuthSessionsPage.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'] as List<dynamic>? ?? const [];
    return AuthSessionsPage(
      sessions: rawSessions
          .whereType<Map<String, dynamic>>()
          .map(AuthSession.fromJson)
          .where((session) => session.id.isNotEmpty)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      numPages: (json['numPages'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 0,
      itemsPerPage: (json['itemsPerPage'] as num?)?.toInt() ?? 10,
    );
  }
}

enum AuthSessionsStatus { supported, unsupported, failed }

class AuthSessionsResult {
  final AuthSessionsStatus status;
  final AuthSessionsPage? page;

  const AuthSessionsResult(this.status, [this.page]);
}
