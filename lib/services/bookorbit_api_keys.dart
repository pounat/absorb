/// BookOrbit API keys (3.8 and later): a key signs a script, a home
/// automation or another Absorb in without a password. The calls live on
/// BookOrbitApiService (bookorbit_api_key_api.dart).
library;

/// Every key starts with this, so a key is told from a magic link or a
/// session token without parsing it.
const boApiKeyPrefix = 'bok_';

/// The lifetimes BookOrbit offers for a new key, in days. Null never expires.
const boApiKeyExpiryPresets = <int?>[30, 90, 365, null];
const boApiKeyDefaultExpiryDays = 90;
const boApiKeyMaxActive = 25;
const boApiKeyNameMaxLength = 100;

/// Permissions a key may be granted out of its owner's: never the one for
/// making keys, and never a restriction, which a key keeps regardless.
Set<String> boApiKeyGrantable(Set<String> owner) =>
    {...owner}..removeAll(const {'api_keys', 'demo_restricted', '*'});

bool boLooksLikeApiKey(String text) => text.trim().startsWith(boApiKeyPrefix);

enum BoApiKeyState { active, expiring, expired, revoked }

class BoApiKey {
  final int id;
  final String name;

  /// The last characters of the token, the only part kept in the clear.
  final String hint;
  final String access;
  final Set<String> permissions;
  final bool admin;

  /// The only libraries the key reaches, or null for all its owner sees.
  final List<int>? libraryIds;
  final DateTime? createdAt;

  /// The administrator who issued the key, or null when the owner made it.
  final String? createdBy;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final String? lastUsedIp;
  final DateTime? revokedAt;

  const BoApiKey({
    required this.id,
    required this.name,
    required this.hint,
    required this.access,
    required this.permissions,
    required this.admin,
    required this.libraryIds,
    required this.createdAt,
    required this.createdBy,
    required this.expiresAt,
    required this.lastUsedAt,
    required this.lastUsedIp,
    required this.revokedAt,
  });

  factory BoApiKey.fromJson(Map<String, dynamic> j) {
    final libs = j['libraryIds'];
    final by = j['createdBy'];
    return BoApiKey(
      id: (j['id'] as num).toInt(),
      name: j['name'] as String? ?? '',
      hint: j['hint'] as String? ?? '',
      access: j['access'] as String? ?? 'read',
      permissions: {for (final p in (j['permissions'] as List? ?? const [])) '$p'},
      admin: j['admin'] == true,
      libraryIds: libs is List ? [for (final id in libs) if (id is num) id.toInt()] : null,
      createdAt: _date(j['createdAt']),
      createdBy: by is Map ? by['username'] as String? : null,
      expiresAt: _date(j['expiresAt']),
      lastUsedAt: _date(j['lastUsedAt']),
      lastUsedIp: j['lastUsedIp'] as String?,
      revokedAt: _date(j['revokedAt']),
    );
  }

  bool get write => access == 'write';

  /// How the token is shown once it is gone: the prefix and its tail.
  String get masked => '$boApiKeyPrefix...$hint';

  BoApiKeyState get state {
    if (revokedAt != null) return BoApiKeyState.revoked;
    final until = expiresAt;
    if (until == null) return BoApiKeyState.active;
    final left = until.difference(DateTime.now());
    if (left.isNegative) return BoApiKeyState.expired;
    return left <= const Duration(days: 7) ? BoApiKeyState.expiring : BoApiKeyState.active;
  }

  bool get usable => state == BoApiKeyState.active || state == BoApiKeyState.expiring;
}

/// A key as it is handed over: the token is here and nowhere else again.
class BoCreatedApiKey {
  final BoApiKey key;
  final String token;

  const BoCreatedApiKey(this.key, this.token);

  factory BoCreatedApiKey.fromJson(Map<String, dynamic> j) =>
      BoCreatedApiKey(BoApiKey.fromJson(j['key'] as Map<String, dynamic>), j['token'] as String? ?? '');
}

/// The server's say over keys: whether any work, and how long a new one may last.
class BoApiKeySettings {
  final bool enabled;
  final int? maxLifetimeDays;

  const BoApiKeySettings({required this.enabled, required this.maxLifetimeDays});

  factory BoApiKeySettings.fromJson(Map<String, dynamic> j) => BoApiKeySettings(
        enabled: j['enabled'] != false,
        maxLifetimeDays: (j['maxLifetimeDays'] as num?)?.toInt(),
      );
}

/// A lifetime to ask for. A cap below every preset leaves only the cap
/// itself, which is not a value the server accepts; then the request leaves
/// the lifetime out and the server applies its own default, the cap.
class BoApiKeyExpiry {
  final int? days;
  final bool serverDefault;

  const BoApiKeyExpiry(this.days, {this.serverDefault = false});

  bool get never => days == null && !serverDefault;

  @override
  bool operator ==(Object other) =>
      other is BoApiKeyExpiry && other.days == days && other.serverDefault == serverDefault;

  @override
  int get hashCode => Object.hash(days, serverDefault);
}

/// The lifetimes a new key may be given under [cap], longest last.
List<BoApiKeyExpiry> boApiKeyExpiryChoices(int? cap) {
  final out = <BoApiKeyExpiry>[
    for (final d in boApiKeyExpiryPresets)
      if (cap == null || (d != null && d <= cap)) BoApiKeyExpiry(d),
  ];
  final fallback = cap == null || cap >= boApiKeyDefaultExpiryDays ? boApiKeyDefaultExpiryDays : cap;
  if (!out.any((c) => c.days == fallback)) {
    out.add(BoApiKeyExpiry(fallback, serverDefault: true));
    out.sort((a, b) => (a.days ?? 1 << 30).compareTo(b.days ?? 1 << 30));
  }
  return out;
}

/// The choice a new key starts on: the default lifetime, or the longest
/// one the cap allows below it.
BoApiKeyExpiry boApiKeyDefaultChoice(List<BoApiKeyExpiry> choices) {
  BoApiKeyExpiry? pick;
  for (final c in choices) {
    if (c.days != null && c.days! <= boApiKeyDefaultExpiryDays) pick = c;
  }
  return pick ?? choices.first;
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
