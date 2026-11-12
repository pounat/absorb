part of 'api_service.dart';

/// BookOrbit API keys: the signed-in user's own, another user's for an
/// administrator, and the server's say over all of them. Each call throws a
/// [BookOrbitAdminError] carrying the server's reason and code when it
/// refuses ("API_KEY_LIMIT_REACHED").
extension BookOrbitApiKeyApi on BookOrbitApiService {
  String _keysPath(int? userId) => userId == null ? '/api-keys' : '/users/$userId/api-keys';

  /// The keys of [userId], or the signed-in user's own when null. Revoked and
  /// expired keys stay in the list for 90 days.
  Future<List<BoApiKey>> apiKeys({int? userId}) => _admin(() async => [
        for (final k in (await _boGet(_keysPath(userId)) as List? ?? const []).whereType<Map<String, dynamic>>())
          BoApiKey.fromJson(k),
      ]);

  /// Whether the server lets keys work, and how long a new one may last.
  Future<BoApiKeySettings> apiKeySettings() =>
      _admin(() async => BoApiKeySettings.fromJson(await _boGet('/api-keys/settings') as Map<String, dynamic>));

  /// Makes a key, for [userId] when an administrator issues one. The token
  /// in the answer is shown once and never again.
  Future<BoCreatedApiKey> createBoApiKey({
    int? userId,
    required String name,
    required bool write,
    required Set<String> permissions,
    required BoApiKeyExpiry expiry,
    bool admin = false,
    List<int>? libraryIds,
  }) =>
      _admin(() async => BoCreatedApiKey.fromJson(await _boPost(_keysPath(userId), {
            'name': name,
            'access': write ? 'write' : 'read',
            'permissions': permissions.toList(),
            if (admin) 'admin': true,
            if (libraryIds != null && libraryIds.isNotEmpty) 'libraryIds': libraryIds,
            if (!expiry.serverDefault) 'expiresInDays': expiry.days,
          }) as Map<String, dynamic>));

  Future<BoApiKey> renameApiKey(int id, String name) =>
      _admin(() async => BoApiKey.fromJson(await _boPatch('/api-keys/$id', {'name': name}) as Map<String, dynamic>));

  /// A new token for the same key; the old one stops at once.
  Future<BoCreatedApiKey> regenerateApiKey(int id) =>
      _admin(() async => BoCreatedApiKey.fromJson(await _boPost('/api-keys/$id/regenerate') as Map<String, dynamic>));

  Future<void> revokeApiKey(int id, {int? userId}) => _admin(() => _boDelete('${_keysPath(userId)}/$id'));

  /// Revokes every key, and says how many that was.
  Future<int> revokeAllApiKeys({int? userId}) => _admin(() async {
        final res = await _boDelete(_keysPath(userId));
        return res is Map ? (res['revoked'] as num?)?.toInt() ?? 0 : 0;
      });

  Future<BoApiKeySettings> adminApiKeySettings() =>
      _admin(() async => BoApiKeySettings.fromJson(await _boGet('/app-settings/api-keys') as Map<String, dynamic>));

  /// [maxLifetimeDays] null lifts the cap.
  Future<BoApiKeySettings> adminSetApiKeySettings({required bool enabled, required int? maxLifetimeDays}) =>
      _admin(() async => BoApiKeySettings.fromJson(await _boPut('/app-settings/api-keys', {
            'enabled': enabled,
            'maxLifetimeDays': maxLifetimeDays,
          }) as Map<String, dynamic>));
}
