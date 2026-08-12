import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_account_service.dart';

/// Wrapper around SharedPreferences that automatically scopes keys
/// to the active user account. Use this for any data that should be
/// per-user (progress, absorbing lists, playback history, etc.).
///
/// For data that should be GLOBAL (downloads, device ID, EQ settings),
/// use SharedPreferences directly.
class ScopedPrefs {
  ScopedPrefs._();

  static String keyForScope(String scope, String key) =>
      scope.isEmpty ? key : '$scope:$key';

  static String _scope(String key) =>
      keyForScope(UserAccountService().activeScopeKey, key);

  /// Only fall back to un-scoped data when there is no active scope
  /// (i.e. pre-multi-user migration). Once scoped, a missing key means
  /// the account has no data — not that it should inherit another account's.
  static bool get _shouldFallback => !UserAccountService().hasScope;

  /// Keys that are global (not per-user) and should NOT be copied during
  /// the unscoped-to-scoped migration.
  static const _globalKeys = <String>{
    'saved_accounts', 'active_account_scope',
    'server_url', 'token', 'username', 'user_id', 'default_library_id',
    'custom_headers',
    'loggingEnabled', 'manual_offline_mode',
    'custom_download_path', 'custom_download_uri', 'downloads',
    'absorb_device_id',
    'desktop_sidebar_pinned',
    'widget_item_id', 'widget_episode_id',
    'cached_stats', 'cached_sessions',
    'update_last_check', 'update_dismissed_version',
  };

  /// One-time migration: copy unscoped settings to the active scope.
  /// This handles the case where settings were written before scope was
  /// active (first login, or old init order where UserAccountService
  /// initialized after settings reads).
  static Future<void> migrateToScope() async {
    final scope = UserAccountService().activeScopeKey;
    if (scope.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final flag = '$scope:_scope_migrated';
    if (prefs.getBool(flag) == true) return;

    int copied = 0;
    for (final key in prefs.getKeys()) {
      // Skip keys that already have a scope prefix (contain ':')
      if (key.contains(':')) continue;
      // Skip known global keys
      if (_globalKeys.contains(key)) continue;
      // Skip Flutter framework keys
      if (key.startsWith('flutter.')) continue;
      // Skip per-podcast sort keys (global, keyed by item ID)
      if (key.startsWith('podcast_sort_newest_')) continue;

      final scopedKey = '$scope:$key';
      if (prefs.containsKey(scopedKey)) continue; // already exists

      final value = prefs.get(key);
      if (value is String) {
        await prefs.setString(scopedKey, value);
      } else if (value is bool) {
        await prefs.setBool(scopedKey, value);
      } else if (value is int) {
        await prefs.setInt(scopedKey, value);
      } else if (value is double) {
        await prefs.setDouble(scopedKey, value);
      } else if (value is List<String>) {
        await prefs.setStringList(scopedKey, value);
      } else {
        continue;
      }
      copied++;
    }

    await prefs.setBool(flag, true);
    if (copied > 0) {
      debugPrint('[ScopedPrefs] Migrated $copied unscoped settings to scope: $scope');
    }
  }

  // ── String ──

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = prefs.getString(_scope(key));
    if (scoped != null) return scoped;
    if (_shouldFallback) return prefs.getString(key);
    return null;
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scope(key), value);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scope(key));
  }

  // ── StringList ──

  static Future<List<String>> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = prefs.getStringList(_scope(key));
    if (scoped != null) return scoped;
    if (_shouldFallback) return prefs.getStringList(key) ?? [];
    return [];
  }

  static Future<void> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scope(key), value);
  }

  // ── Bool ──

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = _scope(key);
    if (prefs.containsKey(scoped)) return prefs.getBool(scoped);
    if (_shouldFallback && prefs.containsKey(key)) return prefs.getBool(key);
    return null;
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scope(key), value);
  }

  // ── Double ──

  static Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = _scope(key);
    if (prefs.containsKey(scoped)) return prefs.getDouble(scoped);
    if (_shouldFallback && prefs.containsKey(key)) return prefs.getDouble(key);
    return null;
  }

  static Future<void> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scope(key), value);
  }

  // ── Int ──

  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = _scope(key);
    if (prefs.containsKey(scoped)) return prefs.getInt(scoped);
    if (_shouldFallback && prefs.containsKey(key)) return prefs.getInt(key);
    return null;
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scope(key), value);
  }

  // ── Convenience ──

  static Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_scope(key))) return true;
    if (_shouldFallback) return prefs.containsKey(key);
    return false;
  }
}
