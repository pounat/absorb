import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/android_auto_service.dart';
import '../services/audio_player_service.dart';
import '../services/equalizer_service.dart';
import '../services/session_cache.dart';
import '../services/socket_service.dart';
import '../services/user_account_service.dart';
import '../services/home_widget_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show scaffoldMessengerKey, rootNavigatorKey;

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  bool _isLegacyToken = false;
  String? _serverUrl;
  String? _username;
  String? _userId;
  String? _defaultLibraryId;
  Map<String, dynamic>? _userJson;
  Map<String, dynamic>? _serverSettings;
  String? _serverVersion;
  bool _serverReachable = true;
  Map<String, String> _customHeaders = {};

  // Local server auto-switch
  String _localServerUrl = '';
  bool _localServerEnabled = false;
  bool _useLocalServer = false;

  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _accessToken != null && _serverUrl != null;
  bool get isLoading => _isLoading;
  bool get serverReachable => _serverReachable;
  /// Current access token (or legacy token for old servers).
  String? get token => _accessToken;
  String? get serverUrl => _serverUrl;
  String? get activeServerUrl => (_useLocalServer && _localServerUrl.isNotEmpty) ? _localServerUrl : _serverUrl;
  bool get useLocalServer => _useLocalServer;
  bool get localServerEnabled => _localServerEnabled;
  String get localServerUrl => _localServerUrl;
  String? get username => _username;
  String? get userId => _userId;
  String? get defaultLibraryId => _defaultLibraryId;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userJson => _userJson;
  Map<String, dynamic>? get serverSettings => _serverSettings;
  String? get serverVersion => _serverVersion;
  Map<String, String> get customHeaders => _customHeaders;
  bool get isAdmin {
    final t = _userJson?['type'] as String?;
    return t == 'admin' || t == 'root';
  }

  bool get isRoot => _userJson?['type'] == 'root';

  ApiService? get apiService {
    final url = activeServerUrl;
    if (url != null && _accessToken != null) {
      return ApiService(
        baseUrl: url,
        token: _accessToken!,
        refreshToken: _refreshToken,
        isLegacyToken: _isLegacyToken,
        customHeaders: _customHeaders,
        onTokensRefreshed: _onTokensRefreshed,
        onAuthExpired: _onAuthExpired,
      );
    }
    return null;
  }

  void _onTokensRefreshed(String newAccessToken, String? newRefreshToken) {
    _accessToken = newAccessToken;
    if (newRefreshToken != null) _refreshToken = newRefreshToken;
    // Persist updated tokens
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('token', _accessToken!);
      if (_refreshToken != null) prefs.setString('refresh_token', _refreshToken!);
    });
    // Update saved account
    if (_serverUrl != null && _username != null) {
      UserAccountService().updateTokens(_serverUrl!, _username!, _accessToken!, refreshToken: _refreshToken);
    }
    // Push new token to socket
    SocketService().updateToken(_accessToken!);
    notifyListeners();
  }

  void _onAuthExpired() {
    debugPrint('[Auth] Token refresh failed, forcing re-login');
    // Show a message to the user
    final ctx = rootNavigatorKey.currentContext;
    final l = ctx != null ? AppLocalizations.of(ctx) : null;
    final msg = l?.authSessionExpired ?? 'Session expired. Please log in again.';
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(msg)),
    );
    logout();
  }

  /// Try to restore a saved session from SharedPreferences.
  /// If the server is unreachable, still restore credentials so offline mode works.
  Future<void> tryRestoreSession() async {
    final sw = Stopwatch()..start();
    debugPrint('[Auth] tryRestoreSession started');
    _isLoading = true;
    _serverReachable = true;
    notifyListeners();

    try {
      debugPrint('[Auth] getting SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      debugPrint('[Auth] SharedPreferences loaded (${sw.elapsedMilliseconds}ms)');
      final savedUrl = prefs.getString('server_url');
      final savedToken = prefs.getString('token');
      final savedRefreshToken = prefs.getString('refresh_token');
      final savedUsername = prefs.getString('username');
      final savedLibraryId = prefs.getString('default_library_id');

      debugPrint('[Auth] saved credentials: url=${savedUrl != null}, token=${savedToken != null}, refreshToken=${savedRefreshToken != null}');

      if (savedUrl != null && savedToken != null) {
        // Always restore credentials so we can at least go offline
        _serverUrl = savedUrl;
        _accessToken = savedToken;
        _refreshToken = savedRefreshToken;
        _isLegacyToken = savedRefreshToken == null;
        debugPrint('[Auth] Restored token: ${savedToken.substring(0, savedToken.length.clamp(0, 20))}... (${savedToken.length} chars, isLegacy=$_isLegacyToken)');
        _username = savedUsername;
        _userId = prefs.getString('user_id');
        _defaultLibraryId = savedLibraryId;

        // Restore custom headers
        final headersJson = prefs.getString('custom_headers');
        if (headersJson != null) {
          try {
            _customHeaders = Map<String, String>.from(jsonDecode(headersJson) as Map);
          } catch (_) {}
        }

        // Load local server config
        await _loadLocalServerSettings();

        // Check if server is actually reachable.
        // If local server is enabled and we're on WiFi, try local first
        // (lower latency) and only fall back to remote if local fails.
        var reachable = false;
        if (_localServerEnabled && _localServerUrl.isNotEmpty) {
          final connectivity = await Connectivity().checkConnectivity();
          if (connectivity.contains(ConnectivityResult.wifi)) {
            debugPrint('[Auth] On WiFi with local server enabled, trying local first... (${sw.elapsedMilliseconds}ms)');
            final localReachable = await ApiService.pingServer(_localServerUrl, customHeaders: _customHeaders)
                .timeout(const Duration(seconds: 2), onTimeout: () => false);
            if (localReachable) {
              debugPrint('[Auth] Local server reachable - using local (${sw.elapsedMilliseconds}ms)');
              _useLocalServer = true;
              reachable = true;
            }
          }
        }
        if (!reachable) {
          debugPrint('[Auth] pinging remote server... (${sw.elapsedMilliseconds}ms)');
          reachable = await ApiService.pingServer(savedUrl, customHeaders: _customHeaders);
          debugPrint('[Auth] remote ping result: reachable=$reachable (${sw.elapsedMilliseconds}ms)');
        }
        _serverReachable = reachable;

        // Fetch full user info (needed for isAdmin, permissions, etc.)
        if (reachable) {
          try {
            debugPrint('[Auth] fetching /me... (${sw.elapsedMilliseconds}ms)');
            final api = ApiService(
              baseUrl: activeServerUrl!,
              token: savedToken,
              refreshToken: savedRefreshToken,
              isLegacyToken: _isLegacyToken,
              customHeaders: _customHeaders,
              onTokensRefreshed: _onTokensRefreshed,
              onAuthExpired: _onAuthExpired,
            );
            final me = await api.getMe();
            if (me != null) {
              _userJson = me;
              _userId = me['id'] as String?;
            } else {
              debugPrint('[Auth] /me returned null (token may be invalid)');
            }
            debugPrint('[Auth] /me done (${sw.elapsedMilliseconds}ms)');
          } catch (_) {}
          _fetchServerVersion(activeServerUrl!);
        }
      }
    } catch (e) {
      // Restore failed — but if we already set credentials, keep them
      debugPrint('[Auth] tryRestoreSession error: $e (${sw.elapsedMilliseconds}ms)');
      _serverReachable = false;
    }

    debugPrint('[Auth] tryRestoreSession done, isAuthenticated=$isAuthenticated (${sw.elapsedMilliseconds}ms)');
    _isLoading = false;
    notifyListeners();
  }

  /// Login with username/password.
  ///
  /// [l] is used to localize error messages stored in [errorMessage]. If null,
  /// English fallbacks are used (e.g. when called from a non-UI context).
  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
    Map<String, String> customHeaders = const {},
    AppLocalizations? l,
  }) async {
    _errorMessage = null;

    // Normalize server URL
    String url = serverUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    // Check server reachability
    final reachable = await ApiService.pingServer(url, customHeaders: customHeaders);
    if (!reachable) {
      _errorMessage = l?.authCannotReachServer(url) ?? 'Cannot reach server at $url';
      return false;
    }

    // Attempt login
    final (result, statusCode) = await ApiService.login(
      serverUrl: url,
      username: username,
      password: password,
      customHeaders: customHeaders,
    );

    if (result == null) {
      _errorMessage = statusCode == 401
          ? (l?.authInvalidUsernameOrPassword ?? 'Invalid username or password')
          : (l?.authLoginFailedDetail ?? 'Login failed - check your server address and credentials');
      return false;
    }

    // Extract user info
    final user = result['user'] as Map<String, dynamic>?;
    if (user == null) {
      _errorMessage = l?.authUnexpectedServerResponse ?? 'Unexpected server response';
      return false;
    }

    _serverUrl = url;
    // Prefer new JWT accessToken, fall back to legacy user.token for old servers
    final newAccessToken = result['accessToken'] as String?;
    final newRefreshToken = result['refreshToken'] as String?;
    _isLegacyToken = newAccessToken == null;
    _accessToken = newAccessToken ?? user['token'] as String?;
    _refreshToken = newRefreshToken;
    debugPrint('[Auth] Login response keys: ${result.keys.toList()}');
    debugPrint('[Auth] Login user keys: ${user.keys.toList()}');
    debugPrint('[Auth] accessToken=${newAccessToken != null}, refreshToken=${newRefreshToken != null}, legacyToken=${user['token'] != null}, isLegacy=$_isLegacyToken');
    debugPrint('[Auth] Token being used: ${_accessToken != null ? '${_accessToken!.substring(0, _accessToken!.length.clamp(0, 20))}... (${_accessToken!.length} chars)' : 'null'}');
    _username = user['username'] as String?;
    _userId = user['id'] as String?;
    _defaultLibraryId = result['userDefaultLibraryId'] as String?;
    _userJson = user;
    _serverSettings = result['serverSettings'] as Map<String, dynamic>?;
    _customHeaders = customHeaders;

    // Try to get version from login response first, fall back to /status
    final loginVersion = result['serverVersion'] as String?
        ?? (_serverSettings?['version'] as String?);
    if (loginVersion != null && loginVersion.isNotEmpty) {
      _serverVersion = loginVersion;
    } else {
      _fetchServerVersion(url);
    }

    // Persist session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', _serverUrl!);
      if (_accessToken != null) await prefs.setString('token', _accessToken!);
      if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
      if (_username != null) await prefs.setString('username', _username!);
      if (_userId != null) await prefs.setString('user_id', _userId!);
      if (_defaultLibraryId != null) {
        await prefs.setString('default_library_id', _defaultLibraryId!);
      }
      if (customHeaders.isNotEmpty) {
        await prefs.setString('custom_headers', jsonEncode(customHeaders));
      } else {
        await prefs.remove('custom_headers');
      }
    } catch (_) {}

    // Save to multi-account service
    try {
      await UserAccountService().saveAccount(SavedAccount(
        serverUrl: _serverUrl!,
        username: _username ?? '',
        token: _accessToken ?? '',
        refreshToken: _refreshToken,
        userId: _userId,
        isLegacyToken: _isLegacyToken,
      ));
    } catch (_) {}

    // Wipe any previous user's stats from the widget and pull this user's.
    await HomeWidgetService().clearStats();
    HomeWidgetService().refreshStats(force: true);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Login using OIDC callback response data.
  /// [result] is the JSON from /auth/openid/callback — same shape as /login response.
  ///
  /// [l] is used to localize error messages stored in [errorMessage]. If null,
  /// English fallbacks are used.
  Future<bool> loginWithOidc({
    required String serverUrl,
    required Map<String, dynamic> result,
    AppLocalizations? l,
  }) async {
    _errorMessage = null;

    String url = serverUrl.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

    final user = result['user'] as Map<String, dynamic>?;
    if (user == null) {
      _errorMessage = l?.authSsoUnexpectedResponse ?? 'SSO returned an unexpected response';
      notifyListeners();
      return false;
    }

    _serverUrl = url;
    final newAccessToken = result['accessToken'] as String?;
    final newRefreshToken = result['refreshToken'] as String?;
    _isLegacyToken = newAccessToken == null;
    _accessToken = newAccessToken ?? user['token'] as String?;
    _refreshToken = newRefreshToken;
    debugPrint('[Auth] OIDC response keys: ${result.keys.toList()}');
    debugPrint('[Auth] OIDC user keys: ${user.keys.toList()}');
    debugPrint('[Auth] accessToken=${newAccessToken != null}, refreshToken=${newRefreshToken != null}, legacyToken=${user['token'] != null}, isLegacy=$_isLegacyToken');
    debugPrint('[Auth] Token being used: ${_accessToken != null ? '${_accessToken!.substring(0, _accessToken!.length.clamp(0, 20))}... (${_accessToken!.length} chars)' : 'null'}');
    _username = user['username'] as String?;
    _userId = user['id'] as String?;
    _defaultLibraryId = result['userDefaultLibraryId'] as String?;
    _userJson = user;
    _serverSettings = result['serverSettings'] as Map<String, dynamic>?;
    _serverReachable = true;

    // Try to get version from response first, fall back to /status
    final oidcVersion = result['serverVersion'] as String?
        ?? (_serverSettings?['version'] as String?);
    if (oidcVersion != null && oidcVersion.isNotEmpty) {
      _serverVersion = oidcVersion;
    } else {
      _fetchServerVersion(url);
    }

    // Persist session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', _serverUrl!);
      if (_accessToken != null) await prefs.setString('token', _accessToken!);
      if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
      if (_username != null) await prefs.setString('username', _username!);
      if (_userId != null) await prefs.setString('user_id', _userId!);
      if (_defaultLibraryId != null) {
        await prefs.setString('default_library_id', _defaultLibraryId!);
      }
    } catch (_) {}

    // Save to multi-account service
    try {
      await UserAccountService().saveAccount(SavedAccount(
        serverUrl: _serverUrl!,
        username: _username ?? '',
        token: _accessToken ?? '',
        refreshToken: _refreshToken,
        userId: _userId,
        isLegacyToken: _isLegacyToken,
      ));
    } catch (_) {}

    // Wipe any previous user's stats from the widget and pull this user's.
    await HomeWidgetService().clearStats();
    HomeWidgetService().refreshStats(force: true);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Load local server settings from PlayerSettings.
  Future<void> _loadLocalServerSettings() async {
    _localServerEnabled = await PlayerSettings.getLocalServerEnabled();
    _localServerUrl = await PlayerSettings.getLocalServerUrl();
    if (_localServerEnabled) {
      debugPrint('[Auth] Local server config loaded: enabled=$_localServerEnabled, url=${_localServerUrl.isNotEmpty ? "(set)" : "(empty)"}');
    }
  }

  /// Check if the configured local server is reachable.
  /// Called on WiFi connectivity changes by LibraryProvider.
  Future<void> checkLocalServer() async {
    if (!_localServerEnabled || _localServerUrl.isEmpty || _serverUrl == null) return;
    final wasLocal = _useLocalServer;
    try {
      final reachable = await ApiService.pingServer(_localServerUrl, customHeaders: _customHeaders)
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      _useLocalServer = reachable;
      if (reachable) _serverReachable = true;
    } catch (_) {
      _useLocalServer = false;
    }
    if (_useLocalServer != wasLocal) {
      debugPrint('[Auth] Local server switch: useLocal=$_useLocalServer');
      SocketService().switchServer(activeServerUrl!);
      final ctx = rootNavigatorKey.currentContext;
      final l = ctx != null ? AppLocalizations.of(ctx) : null;
      _showServerToast(_useLocalServer
          ? (l?.authSwitchedToLocalServer ?? 'Switched to local server')
          : (l?.authSwitchedToRemoteServer ?? 'Switched to remote server'));
      notifyListeners();
    }
  }

  /// Revert to the remote server URL (e.g. when WiFi disconnects).
  void clearLocalOverride() {
    if (!_useLocalServer) return;
    _useLocalServer = false;
    debugPrint('[Auth] Cleared local server override, back to remote');
    if (_serverUrl != null) {
      SocketService().switchServer(_serverUrl!);
    }
    final ctx = rootNavigatorKey.currentContext;
    final l = ctx != null ? AppLocalizations.of(ctx) : null;
    _showServerToast(l?.authSwitchedToRemoteServer ?? 'Switched to remote server');
    notifyListeners();
  }

  void _showServerToast(String message) {
    try {
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.dns_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(message),
        ]),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (_) {}
  }

  /// Update local server settings from the UI.
  Future<void> setLocalServerConfig({required bool enabled, required String url}) async {
    _localServerEnabled = enabled;
    _localServerUrl = url;
    await PlayerSettings.setLocalServerEnabled(enabled);
    await PlayerSettings.setLocalServerUrl(url);
    if (!enabled) clearLocalOverride();
  }

  /// Logout and clear stored session.
  /// Fetch server version asynchronously (non-blocking).
  void _fetchServerVersion(String url) async {
    try {
      final version = await ApiService.getServerVersion(url, customHeaders: _customHeaders);
      if (version != null) {
        _serverVersion = version;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    // Stop any active playback
    try {
      final player = AudioPlayerService();
      if (player.hasBook) {
        await player.pause();
        await player.stop();
      }
    } catch (_) {}

    // Clear Android Auto browse tree cache so it doesn't show stale data
    AndroidAutoService().clearCache();

    // Clear the stats widget so the previous user's numbers don't linger.
    await HomeWidgetService().clearStats();

    // Clear cached session metadata for this user (track URLs would be invalid
    // on next login anyway)
    await SessionCache.clearAll();

    // Remove account from saved accounts list
    final logoutServer = _serverUrl;
    final logoutUser = _username;

    _accessToken = null;
    _refreshToken = null;
    _isLegacyToken = false;
    _serverUrl = null;
    _username = null;
    _userId = null;
    _defaultLibraryId = null;
    _userJson = null;
    _serverSettings = null;
    _serverVersion = null;
    _errorMessage = null;

    try {
      if (logoutServer != null && logoutUser != null) {
        await UserAccountService().removeAccount(logoutServer, logoutUser);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('server_url');
      await prefs.remove('token');
      await prefs.remove('refresh_token');
      await prefs.remove('username');
      await prefs.remove('user_id');
      await prefs.remove('default_library_id');
    } catch (_) {}

    notifyListeners();
  }

  /// Switch to a saved account without going through the login screen.
  /// Stops playback, swaps credentials, and notifies listeners so the
  /// app reloads with the new user's data.
  Future<bool> switchToAccount(SavedAccount account) async {
    // Stop current playback
    try {
      final player = AudioPlayerService();
      if (player.hasBook) {
        await player.pause();
        await player.stop();
      }
    } catch (_) {}

    // Clear Android Auto browse tree cache so it refreshes for the new user
    AndroidAutoService().clearCache();

    // Set the new account as active in the account service
    UserAccountService().switchTo(account.serverUrl, account.username);

    // Notify widgets that read scoped settings (e.g. card button layout) so
    // they reload from the new account's ScopedPrefs instead of keeping the
    // previous account's values cached in widget state.
    PlayerSettings.notifySettingsChanged();

    // Reload EQ settings from the new account's scope. Without this the
    // EqualizerService singleton keeps the previous account's in-memory
    // state and would write it back into the new scope on any change.
    await EqualizerService().reloadForActiveAccount();

    // Set credentials
    _serverUrl = account.serverUrl;
    _accessToken = account.token;
    _refreshToken = account.refreshToken;
    _isLegacyToken = account.isLegacyToken;
    _username = account.username;
    _userId = account.userId;
    _defaultLibraryId = null;
    _userJson = null;
    _serverSettings = null;
    _serverVersion = null;
    _errorMessage = null;
    _serverReachable = true;

    // Persist as the active session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', _serverUrl!);
      if (_accessToken != null) await prefs.setString('token', _accessToken!);
      if (_username != null) await prefs.setString('username', _username!);
      if (_userId != null) await prefs.setString('user_id', _userId!);
    } catch (_) {}

    // Clear the stats widget so the previous account's numbers don't linger
    // while the new user's data is fetched, then force a refresh.
    await HomeWidgetService().clearStats();
    HomeWidgetService().refreshStats(force: true);

    // Restore custom headers for this session
    try {
      final prefs = await SharedPreferences.getInstance();
      final headersJson = prefs.getString('custom_headers');
      if (headersJson != null) {
        try {
          _customHeaders = Map<String, String>.from(jsonDecode(headersJson) as Map);
        } catch (_) {
          _customHeaders = {};
        }
      } else {
        _customHeaders = {};
      }
    } catch (_) {
      _customHeaders = {};
    }

    // Verify the token still works and get user info
    try {
      final api = ApiService(
        baseUrl: _serverUrl!,
        token: _accessToken!,
        refreshToken: _refreshToken,
        isLegacyToken: _isLegacyToken,
        customHeaders: _customHeaders,
        onTokensRefreshed: _onTokensRefreshed,
        onAuthExpired: _onAuthExpired,
      );
      final me = await api.getMe();
      if (me != null) {
        _userJson = me;
        _userId = me['id'] as String?;
      }
    } catch (_) {
      _serverReachable = false;
    }

    await _loadLocalServerSettings();
    _useLocalServer = false;
    // Check if local server should be active (same logic as tryRestoreSession)
    if (_localServerEnabled && _localServerUrl.isNotEmpty) {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.wifi)) {
        final localReachable = await ApiService.pingServer(_localServerUrl, customHeaders: _customHeaders)
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
        if (localReachable) {
          debugPrint('[Auth] switchToAccount: local server reachable - using local');
          _useLocalServer = true;
        }
      }
    }
    _fetchServerVersion(activeServerUrl!);
    notifyListeners();
    return true;
  }

  /// Get all saved accounts (for the account switcher UI).
  List<SavedAccount> get savedAccounts => UserAccountService().accounts;
}
