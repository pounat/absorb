import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/server_url.dart';
import 'auth_tokens.dart';

/// Represents a saved user account (server + credentials).
class SavedAccount {
  final String serverUrl;
  final String username;
  final String token; // accessToken (or legacy token for old servers)
  final String? refreshToken;
  final String? userId;
  final bool isLegacyToken;
  final Map<String, String> customHeaders;

  SavedAccount({
    required this.serverUrl,
    required this.username,
    required this.token,
    this.refreshToken,
    this.userId,
    this.isLegacyToken = false,
    Map<String, String> customHeaders = const {},
  }) : customHeaders = Map.unmodifiable(customHeaders);

  /// Unique key for scoping per-user SharedPreferences data.
  /// Uses serverUrl + username to uniquely identify an account.
  String get scopeKey {
    // Normalize: strip protocol and trailing slashes for consistency
    final cleanUrl = serverUrl
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/+$'), '');
    return '${cleanUrl}_$username';
  }

  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'token': token,
        if (refreshToken != null) 'refreshToken': refreshToken,
        'userId': userId,
        'isLegacyToken': isLegacyToken,
        'customHeaders': customHeaders,
      };

  factory SavedAccount.fromJson(
    Map<String, dynamic> json, {
    Map<String, String> legacyCustomHeaders = const {},
  }) =>
      SavedAccount(
        serverUrl: json['serverUrl'] as String,
        username: json['username'] as String,
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String?,
        userId: json['userId'] as String?,
        isLegacyToken: json['isLegacyToken'] as bool? ?? (json['refreshToken'] == null),
        customHeaders: json.containsKey('customHeaders')
            ? Map<String, String>.from(json['customHeaders'] as Map? ?? const {})
            : legacyCustomHeaders,
      );

  @override
  bool operator ==(Object other) =>
      other is SavedAccount &&
      other.serverUrl == serverUrl &&
      other.username == username;

  @override
  int get hashCode => Object.hash(serverUrl, username);
}

/// Manages multiple saved user accounts and provides scoped storage keys.
///
/// Downloads (audio files on disk) are shared across all users — there's no
/// point re-downloading the same audiobook for a different user on the same
/// device. But progress, absorbing lists, playback history, bookmarks, and
/// metadata overrides are all scoped per-user.
class UserAccountService {
  static final UserAccountService _instance = UserAccountService._();
  factory UserAccountService() => _instance;
  UserAccountService._();

  static const _accountsKey = 'saved_accounts';
  static const _activeKey = 'active_account_scope';

  List<SavedAccount> _accounts = [];
  String? _activeScopeKey;

  List<SavedAccount> get accounts => List.unmodifiable(_accounts);
  String get activeScopeKey => _activeScopeKey ?? '';

  /// Initialise from SharedPreferences. Call once at app startup.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var legacyCustomHeaders = <String, String>{};
    final headersJson = prefs.getString('custom_headers');
    if (headersJson != null) {
      try {
        legacyCustomHeaders =
            Map<String, String>.from(jsonDecode(headersJson) as Map);
      } catch (_) {}
    }

    // Load saved accounts
    final json = prefs.getString(_accountsKey);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List<dynamic>;
        _accounts = list
            .map((e) => SavedAccount.fromJson(
                  e as Map<String, dynamic>,
                  legacyCustomHeaders: legacyCustomHeaders,
                ))
            .toList();
      } catch (e) {
        debugPrint('[UserAccount] Failed to load accounts: $e');
      }
    }

    // Load active scope
    _activeScopeKey = prefs.getString(_activeKey);
    debugPrint('[UserAccount] Loaded ${_accounts.length} accounts, active=$_activeScopeKey');
  }

  /// Save or update an account after login. Sets it as active.
  Future<void> saveAccount(SavedAccount account) async {
    // Remove existing entry for same server+username (update token)
    _accounts.removeWhere(
        (a) => a.serverUrl == account.serverUrl && a.username == account.username);
    _accounts.insert(0, account); // Most recent first
    _activeScopeKey = account.scopeKey;
    await _persist();
    debugPrint('[UserAccount] Saved & activated: ${account.username}@${account.serverUrl}');
  }

  /// Switch to a different saved account. Returns the account or null if not found.
  SavedAccount? switchTo(String serverUrl, String username) {
    final account = _accounts.firstWhere(
      (a) => a.serverUrl == serverUrl && a.username == username,
      orElse: () => SavedAccount(serverUrl: '', username: '', token: ''),
    );
    if (account.token.isEmpty) return null;
    _activeScopeKey = account.scopeKey;
    _persistActiveKey();
    debugPrint('[UserAccount] Switched to: ${account.username}@${account.serverUrl}');
    return account;
  }

  /// Remove a saved account. Does NOT delete its scoped data (in case the
  /// user wants to re-add later). Returns true if found and removed.
  Future<bool> removeAccount(String serverUrl, String username) async {
    final before = _accounts.length;
    _accounts.removeWhere(
        (a) => a.serverUrl == serverUrl && a.username == username);
    if (_accounts.length < before) {
      await _persist();
      debugPrint('[UserAccount] Removed: $username@$serverUrl');
      return true;
    }
    return false;
  }

  /// Update tokens for the active account (e.g. after token refresh).
  Future<void> updateTokens(String serverUrl, String username, String newToken, {String? refreshToken}) async {
    final idx = _accounts.indexWhere(
        (a) => a.serverUrl == serverUrl && a.username == username);
    if (idx >= 0) {
      final old = _accounts[idx];
      _accounts[idx] = SavedAccount(
        serverUrl: old.serverUrl,
        username: old.username,
        token: newToken,
        refreshToken: refreshToken ?? old.refreshToken,
        userId: old.userId,
        isLegacyToken: old.isLegacyToken,
        customHeaders: old.customHeaders,
      );
      await _persist();
    }
  }

  /// Persist tokens refreshed outside the live session (background isolates,
  /// widget cold paths). The server rotates refresh tokens - each one is
  /// single-use - so a refresh whose result is only kept in memory strands
  /// the on-disk session with an expired access token and a consumed refresh
  /// token, and the next app launch can't sign in.
  Future<void> persistRefreshedTokens(
    String accessToken,
    String? refreshToken, {
    required String serverUrl,
    required String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final activeServer = prefs.getString('server_url');
    final activeUsername = prefs.getString('username');
    if (activeServer == null ||
        normalizeServerUrl(activeServer) != normalizeServerUrl(serverUrl) ||
        activeUsername != username) {
      return;
    }
    await prefs.setString('token', accessToken);
    if (refreshToken != null) await prefs.setString('refresh_token', refreshToken);
    if (username != null) {
      if (_accounts.isEmpty) await init();
      await updateTokens(serverUrl, username, accessToken, refreshToken: refreshToken);
    }
  }

  /// Reload the active session from disk. SharedPreferences keeps an
  /// isolate-local cache, so reload is required before a foreground client can
  /// see a token rotation performed by background work.
  Future<AuthTokens?> loadPersistedTokens(
      String serverUrl, String? username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final activeServer = prefs.getString('server_url');
    final activeUsername = prefs.getString('username');
    if (activeServer == null ||
        normalizeServerUrl(activeServer) != normalizeServerUrl(serverUrl) ||
        activeUsername != username) {
      return null;
    }
    final accessToken = prefs.getString('token');
    if (accessToken == null || accessToken.isEmpty) return null;
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: prefs.getString('refresh_token'),
    );
  }

  /// Keep the server/account available for a prefilled re-login while making
  /// sure a rejected token cannot be quick-switched back into the app.
  Future<void> clearTokens(String serverUrl, String username) async {
    final idx = _accounts.indexWhere(
        (a) => a.serverUrl == serverUrl && a.username == username);
    if (idx < 0) return;
    final old = _accounts[idx];
    _accounts[idx] = SavedAccount(
      serverUrl: old.serverUrl,
      username: old.username,
      token: '',
      userId: old.userId,
      isLegacyToken: old.isLegacyToken,
      customHeaders: old.customHeaders,
    );
    await _persist();
  }

  /// Change the server URL of a saved account (e.g. a dynamic-DNS hostname
  /// changed) WITHOUT losing the account's per-user data. The scopeKey is
  /// derived from the URL, so every scoped SharedPreferences key is migrated
  /// from the old scope to the new one. Returns true if the account was found.
  Future<bool> updateAccountUrl(
      String oldServerUrl, String username, String newServerUrl) async {
    final index = _accounts.indexWhere(
        (a) => a.serverUrl == oldServerUrl && a.username == username);
    if (index < 0) return false;
    return updateAccountConnection(
      oldServerUrl,
      username,
      newServerUrl,
      _accounts[index].customHeaders,
    );
  }

  /// Update the URL and proxy headers for one saved account. If the URL
  /// changes, scoped per-account data follows it just as it did for the older
  /// URL-only editor.
  Future<bool> updateAccountConnection(
    String oldServerUrl,
    String username,
    String newServerUrl,
    Map<String, String> customHeaders,
  ) async {
    final idx = _accounts.indexWhere(
        (a) => a.serverUrl == oldServerUrl && a.username == username);
    if (idx < 0) return false;

    final old = _accounts[idx];
    final updated = SavedAccount(
      serverUrl: newServerUrl,
      username: old.username,
      token: old.token,
      refreshToken: old.refreshToken,
      userId: old.userId,
      isLegacyToken: old.isLegacyToken,
      customHeaders: customHeaders,
    );

    final oldScope = old.scopeKey;
    final newScope = updated.scopeKey;
    await _migrateScopedData(oldScope, newScope);

    _accounts[idx] = updated;
    // If this was the active account, re-point the active scope so scoped
    // reads/writes land on the migrated data.
    if (_activeScopeKey == oldScope) {
      _activeScopeKey = newScope;
    }
    await _persist();
    debugPrint(
        '[UserAccount] Updated server URL for $username: $oldServerUrl -> $newServerUrl');
    return true;
  }

  /// Copy every `oldScope:*` SharedPreferences key to `newScope:*` (without
  /// clobbering keys that already exist under the new scope), then remove the
  /// old ones. No-op when the scope is unchanged.
  Future<void> _migrateScopedData(String oldScope, String newScope) async {
    if (oldScope.isEmpty || newScope.isEmpty || oldScope == newScope) return;
    final prefs = await SharedPreferences.getInstance();
    final oldPrefix = '$oldScope:';
    final newPrefix = '$newScope:';
    int moved = 0;
    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith(oldPrefix)) continue;
      final newKey = '$newPrefix${key.substring(oldPrefix.length)}';
      if (prefs.containsKey(newKey)) {
        // Target already has data for this key; drop the stale old copy.
        await prefs.remove(key);
        continue;
      }
      final value = prefs.get(key);
      bool copied = true;
      if (value is String) {
        await prefs.setString(newKey, value);
      } else if (value is bool) {
        await prefs.setBool(newKey, value);
      } else if (value is int) {
        await prefs.setInt(newKey, value);
      } else if (value is double) {
        await prefs.setDouble(newKey, value);
      } else if (value is List<String>) {
        await prefs.setStringList(newKey, value);
      } else {
        copied = false; // unknown type — leave the old key untouched
      }
      if (copied) {
        await prefs.remove(key);
        moved++;
      }
    }
    debugPrint(
        '[UserAccount] Migrated $moved scoped key(s): $oldScope -> $newScope');
  }

  // ── Scoped key helpers ──────────────────────────────────

  /// Returns a SharedPreferences key scoped to the active user.
  /// Example: `scopedKey('progress_li_123')` → `abs.example.com_nathan:progress_li_123`
  String scopedKey(String key) {
    if (_activeScopeKey == null || _activeScopeKey!.isEmpty) return key;
    return '$_activeScopeKey:$key';
  }

  /// Check if we have a scope (i.e. at least one login has occurred).
  bool get hasScope => _activeScopeKey != null && _activeScopeKey!.isNotEmpty;

  // ── Persistence ─────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_accountsKey, json);
    if (_activeScopeKey != null) {
      await prefs.setString(_activeKey, _activeScopeKey!);
    }
  }

  Future<void> _persistActiveKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeScopeKey != null) {
      await prefs.setString(_activeKey, _activeScopeKey!);
    }
  }
}
