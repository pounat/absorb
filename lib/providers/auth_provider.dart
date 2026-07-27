import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_tokens.dart';
import '../services/android_auto_service.dart';
import '../services/book_search_index.dart';
import '../services/carplay_service.dart';
import '../services/audio_player_service.dart';
import '../services/equalizer_service.dart';
import '../services/session_cache.dart';
import '../services/socket_service.dart';
import '../services/user_account_service.dart';
import '../services/home_widget_service.dart';
import '../services/wear_auth_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import '../widgets/overlay_toast.dart';
import '../utils/server_url.dart';

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
  // Ereader devices come on the login response (top-level, NOT inside user).
  // /api/me doesn't include them, so cache to prefs so the list survives
  // cold restarts until the next login.
  List<Map<String, dynamic>> _ereaderDevices = const [];
  bool __serverReachable = true;
  bool get _serverReachable => __serverReachable;
  set _serverReachable(bool value) {
    if (__serverReachable == value) return;
    __serverReachable = value;
    // Mirror the offline state into AudioPlayerService so it can short-
    // circuit pre-play server calls (e.g. session creation) without
    // waiting on a network timeout. Lets downloaded books start playing
    // instantly when we already know we're offline.
    AudioPlayerService().setKnownOffline(!value);
    // If we launched while the server was briefly unreachable (e.g. right
    // after an app update, before networking settles), _userJson never loaded
    // and isAdmin stayed false — hiding the admin settings until a force-close.
    // Now that the server is back, pull the user info we missed.
    if (value) unawaited(_ensureUserInfo());
  }
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

  bool get canAccessExplicitContent {
    final perms = _userJson?['permissions'] as Map<String, dynamic>?;
    return perms?['accessExplicitContent'] == true;
  }

  /// True when this user is allowed to edit library item metadata on the
  /// server. Admins/root always can; regular users need the `update`
  /// permission flag (set per-user in the ABS admin UI).
  bool get canUpdateMetadata {
    if (isAdmin) return true;
    final perms = _userJson?['permissions'] as Map<String, dynamic>?;
    return perms?['update'] == true;
  }

  /// True when the server will accept a destructive call from this user.
  /// Root has `permissions.delete = true` by default; admins do NOT (they
  /// need root to grant it explicitly), so most delete actions are
  /// effectively root-only on a fresh install.
  bool get canDelete {
    final perms = _userJson?['permissions'] as Map<String, dynamic>?;
    return perms?['delete'] == true;
  }

  /// Re-cache server settings after an admin saves them via PATCH /api/settings
  /// (which echoes the updated serverSettings). Keeps cached values and the
  /// shown server version fresh without forcing a re-login.
  void applyServerSettings(Map<String, dynamic> settings) {
    _serverSettings = settings;
    final v = settings['version'] as String?;
    if (v != null && v.isNotEmpty) _serverVersion = v;
    notifyListeners();
  }

  /// E-reader devices the current user is allowed to send ebooks to.
  /// Populated from the login response (top-level `ereaderDevices`, NOT
  /// nested inside the user object) and persisted across restarts since
  /// /api/me doesn't include them.
  List<Map<String, dynamic>> get ereaderDevices => _ereaderDevices;

  /// Replace the cached ereader devices list and persist it. Call this
  /// after an admin edit so the book detail sheet sees fresh devices
  /// without waiting for a re-login.
  Future<void> setEreaderDevices(List<Map<String, dynamic>> devices) async {
    _ereaderDevices = List<Map<String, dynamic>>.from(devices);
    await _persistEreaderDevices();
    notifyListeners();
  }

  Future<void> _persistEreaderDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_ereaderDevices.isEmpty) {
        await prefs.remove('ereader_devices');
      } else {
        await prefs.setString('ereader_devices', jsonEncode(_ereaderDevices));
      }
    } catch (e) {
      debugPrint('[Auth] _persistEreaderDevices error: $e');
    }
  }

  Future<void> _restoreEreaderDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ereader_devices');
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _ereaderDevices = list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[Auth] _restoreEreaderDevices error: $e');
    }
  }

  /// Apply the same access filter ABS uses server-side. Used after an
  /// admin updates the full device list to figure out what THIS user can
  /// still see.
  List<Map<String, dynamic>> filterDevicesForCurrentUser(
      List<Map<String, dynamic>> all) {
    final id = _userId;
    final type = _userJson?['type'] as String? ?? 'user';
    final isAdminLike = type == 'admin' || type == 'root';
    return all.where((d) {
      final opt = d['availabilityOption'] as String? ?? 'adminOrUp';
      switch (opt) {
        case 'adminOrUp':
          return isAdminLike;
        case 'userOrUp':
          return isAdminLike || type == 'user';
        case 'guestOrUp':
          return true;
        case 'specificUsers':
          final users = (d['users'] as List<dynamic>?) ?? const [];
          return id != null && users.contains(id);
        default:
          return false;
      }
    }).toList();
  }

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
    // Keep the paired Wear OS app's cached token in sync.
    _pushSessionToWear();
    notifyListeners();
  }

  /// Push the current session to the paired Wear OS app (if any). Safe
  /// to call unconditionally — the service is a no-op on non-Android
  /// platforms and when no watch is connected.
  void _pushSessionToWear() {
    final url = _serverUrl;
    final token = _accessToken;
    if (url == null || token == null) return;
    WearAuthService.instance.publish(
      serverUrl: url,
      accessToken: token,
      refreshToken: _refreshToken,
      username: _username ?? '',
      userId: _userId,
      isLegacyToken: _isLegacyToken,
      customHeaders: _customHeaders,
    );
  }

  void _onAuthExpired() {
    debugPrint('[Auth] Token refresh failed, forcing re-login');
    // Show a message to the user
    final ctx = rootNavigatorKey.currentContext;
    final l = ctx != null ? AppLocalizations.of(ctx) : null;
    final msg = l?.authSessionExpired ?? 'Session expired. Please log in again.';
    if (ctx != null) showOverlayToast(ctx, msg, icon: Icons.error_outline_rounded);
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
      // Restore ereader devices alongside other session data. /api/me doesn't
      // return them, so without this they'd stay empty until next login.
      await _restoreEreaderDevices();

      debugPrint('[Auth] saved credentials: url=${savedUrl != null}, token=${savedToken != null}, refreshToken=${savedRefreshToken != null}');

      if (savedUrl != null && savedToken != null) {
        // Always restore credentials so we can at least go offline
        final restoredUrl = normalizeServerUrl(savedUrl);
        if (restoredUrl != savedUrl) {
          await prefs.setString('server_url', restoredUrl);
          if (savedUsername != null) {
            await UserAccountService()
                .updateAccountUrl(savedUrl, savedUsername, restoredUrl);
          }
        }
        _serverUrl = restoredUrl;
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
          // Cap at 5s so a silently-dropping reverse proxy or dead network
          // path doesn't hold up app launch. The health-check timer will
          // re-probe every 60s once we're past startup, so a transient
          // false-offline self-corrects quickly.
          reachable = await ApiService.pingServer(restoredUrl, customHeaders: _customHeaders)
              .timeout(const Duration(seconds: 5), onTimeout: () => false);
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
            // Prefer /api/authorize over /api/me because it returns the
            // full login payload (including ereaderDevices) — /api/me drops
            // those extras. Fall back to /api/me if authorize fails (older
            // server versions).
            final auth = await api.authorize();
            if (auth != null) {
              final user = auth['user'] as Map<String, dynamic>?;
              if (user != null) {
                _userJson = user;
                _userId = user['id'] as String?;
              }
              final devicesRaw = auth['ereaderDevices'] as List<dynamic>?;
              if (devicesRaw != null) {
                _ereaderDevices = devicesRaw.cast<Map<String, dynamic>>();
                await _persistEreaderDevices();
              }
              final sSettings = auth['serverSettings'] as Map<String, dynamic>?;
              if (sSettings != null) _serverSettings = sSettings;
              final defaultLib = auth['userDefaultLibraryId'] as String?;
              if (defaultLib != null) _defaultLibraryId = defaultLib;
            } else {
              final me = await api.getMe();
              if (me != null) {
                _userJson = me;
                _userId = me['id'] as String?;
              } else {
                debugPrint('[Auth] /me returned null (token may be invalid)');
              }
            }
            debugPrint('[Auth] authorize/me done (${sw.elapsedMilliseconds}ms)');
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
    if (isAuthenticated) _pushSessionToWear();
    _isLoading = false;
    notifyListeners();
  }

  bool _ensuringUserInfo = false;

  /// Public entry point for the reconnect paths (e.g. LibraryProvider going
  /// back online for a remote server, which doesn't flow through the
  /// `_serverReachable` setter). No-op once the user info is already loaded.
  Future<void> ensureUserInfoLoaded() => _ensureUserInfo();

  /// Fetch the current user's full info (type, permissions, ereader devices)
  /// when we never managed to load it — e.g. the app launched while the server
  /// was momentarily unreachable, so `tryRestoreSession` skipped the /me fetch
  /// and `isAdmin` is stuck false. Called when the server becomes reachable
  /// again so the admin settings appear without a force-close. No-op once we
  /// already have the user.
  Future<void> _ensureUserInfo() async {
    if (_userJson != null || _ensuringUserInfo) return;
    if (!isAuthenticated || _accessToken == null || activeServerUrl == null) return;
    _ensuringUserInfo = true;
    try {
      final api = ApiService(
        baseUrl: activeServerUrl!,
        token: _accessToken!,
        refreshToken: _refreshToken,
        isLegacyToken: _isLegacyToken,
        customHeaders: _customHeaders,
        onTokensRefreshed: _onTokensRefreshed,
        onAuthExpired: _onAuthExpired,
      );
      final auth = await api.authorize();
      if (auth != null) {
        final user = auth['user'] as Map<String, dynamic>?;
        if (user != null) {
          _userJson = user;
          _userId = user['id'] as String?;
        }
        final devicesRaw = auth['ereaderDevices'] as List<dynamic>?;
        if (devicesRaw != null) {
          _ereaderDevices = devicesRaw.cast<Map<String, dynamic>>();
          await _persistEreaderDevices();
        }
        final sSettings = auth['serverSettings'] as Map<String, dynamic>?;
        if (sSettings != null) _serverSettings = sSettings;
        final defaultLib = auth['userDefaultLibraryId'] as String?;
        if (defaultLib != null) _defaultLibraryId = defaultLib;
      } else {
        final me = await api.getMe();
        if (me != null) {
          _userJson = me;
          _userId = me['id'] as String?;
        }
      }
      if (_userJson != null) {
        debugPrint('[Auth] Loaded user info on reconnect (type=${_userJson?['type']})');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Auth] _ensureUserInfo failed: $e');
    } finally {
      _ensuringUserInfo = false;
    }
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

    final url = normalizeServerUrl(serverUrl);

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
    // Prefer the JWTs returned inside user by current servers, while accepting
    // the top-level shape and legacy token used by older servers.
    final tokens = AuthTokens.fromResponse(result);
    if (tokens.token == null) {
      _errorMessage = l?.authUnexpectedServerResponse ?? 'Unexpected server response';
      return false;
    }
    _isLegacyToken = tokens.isLegacy;
    _accessToken = tokens.token;
    _refreshToken = tokens.refreshToken;
    debugPrint('[Auth] Login response keys: ${result.keys.toList()}');
    debugPrint('[Auth] Login user keys: ${user.keys.toList()}');
    debugPrint('[Auth] accessToken=${tokens.accessToken != null}, refreshToken=${tokens.refreshToken != null}, legacyToken=${tokens.legacyToken != null}, isLegacy=$_isLegacyToken');
    debugPrint('[Auth] Token being used: ${_accessToken != null ? '${_accessToken!.substring(0, _accessToken!.length.clamp(0, 20))}... (${_accessToken!.length} chars)' : 'null'}');
    _username = user['username'] as String?;
    _userId = user['id'] as String?;
    _defaultLibraryId = result['userDefaultLibraryId'] as String?;
    _userJson = user;
    _serverSettings = result['serverSettings'] as Map<String, dynamic>?;
    _customHeaders = customHeaders;
    // Ereader devices come at the top level of the login response.
    final devicesRaw = result['ereaderDevices'] as List<dynamic>?;
    _ereaderDevices = devicesRaw?.cast<Map<String, dynamic>>() ?? const [];
    await _persistEreaderDevices();

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

    await _onAccountActivated();

    // Wipe any previous user's stats from the widget and pull this user's.
    await HomeWidgetService().clearStats();
    HomeWidgetService().refreshStats(force: true);

    _pushSessionToWear();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Login with an admin-generated API key. Skips `/login` entirely - the key
  /// is just a bearer token. Treated as a legacy token (no refresh) since API
  /// keys don't expire and don't have a refresh-token counterpart.
  Future<bool> loginWithApiKey({
    required String serverUrl,
    required String apiKey,
    Map<String, String> customHeaders = const {},
    AppLocalizations? l,
  }) async {
    _errorMessage = null;

    final url = normalizeServerUrl(serverUrl);

    final reachable = await ApiService.pingServer(url, customHeaders: customHeaders);
    if (!reachable) {
      _errorMessage = l?.authCannotReachServer(url) ?? 'Cannot reach server at $url';
      return false;
    }

    final (user, statusCode) = await ApiService.loginWithApiKey(
      serverUrl: url,
      apiKey: apiKey,
      customHeaders: customHeaders,
    );

    if (user == null) {
      _errorMessage = statusCode == 401
          ? (l?.authInvalidApiKey ?? 'Invalid API key')
          : (l?.authLoginFailedDetail ?? 'Login failed - check your server address and API key');
      return false;
    }

    _serverUrl = url;
    _accessToken = apiKey;
    _refreshToken = null;
    _isLegacyToken = true;
    _username = user['username'] as String?;
    _userId = user['id'] as String?;
    _defaultLibraryId = null;
    _userJson = user;
    _serverSettings = null;
    _customHeaders = customHeaders;

    _fetchServerVersion(url);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', _serverUrl!);
      await prefs.setString('token', _accessToken!);
      await prefs.remove('refresh_token');
      if (_username != null) await prefs.setString('username', _username!);
      if (_userId != null) await prefs.setString('user_id', _userId!);
      if (customHeaders.isNotEmpty) {
        await prefs.setString('custom_headers', jsonEncode(customHeaders));
      } else {
        await prefs.remove('custom_headers');
      }
    } catch (_) {}

    try {
      await UserAccountService().saveAccount(SavedAccount(
        serverUrl: _serverUrl!,
        username: _username ?? '',
        token: _accessToken!,
        refreshToken: null,
        userId: _userId,
        isLegacyToken: true,
      ));
    } catch (_) {}

    await _onAccountActivated();

    await HomeWidgetService().clearStats();
    HomeWidgetService().refreshStats(force: true);

    _pushSessionToWear();
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
    Map<String, String> customHeaders = const {},
    AppLocalizations? l,
  }) async {
    _errorMessage = null;

    final url = normalizeServerUrl(serverUrl);

    final user = result['user'] as Map<String, dynamic>?;
    if (user == null) {
      _errorMessage = l?.authSsoUnexpectedResponse ?? 'SSO returned an unexpected response';
      notifyListeners();
      return false;
    }

    _serverUrl = url;
    final tokens = AuthTokens.fromResponse(result);
    if (tokens.token == null) {
      _errorMessage = l?.authSsoUnexpectedResponse ?? 'SSO returned an unexpected response';
      notifyListeners();
      return false;
    }
    _isLegacyToken = tokens.isLegacy;
    _accessToken = tokens.token;
    _refreshToken = tokens.refreshToken;
    debugPrint('[Auth] OIDC response keys: ${result.keys.toList()}');
    debugPrint('[Auth] OIDC user keys: ${user.keys.toList()}');
    debugPrint('[Auth] accessToken=${tokens.accessToken != null}, refreshToken=${tokens.refreshToken != null}, legacyToken=${tokens.legacyToken != null}, isLegacy=$_isLegacyToken');
    debugPrint('[Auth] Token being used: ${_accessToken != null ? '${_accessToken!.substring(0, _accessToken!.length.clamp(0, 20))}... (${_accessToken!.length} chars)' : 'null'}');
    _username = user['username'] as String?;
    _userId = user['id'] as String?;
    _defaultLibraryId = result['userDefaultLibraryId'] as String?;
    _userJson = user;
    _serverSettings = result['serverSettings'] as Map<String, dynamic>?;
    _serverReachable = true;
    _customHeaders = customHeaders;
    final devicesRaw = result['ereaderDevices'] as List<dynamic>?;
    _ereaderDevices = devicesRaw?.cast<Map<String, dynamic>>() ?? const [];
    await _persistEreaderDevices();

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

    await _onAccountActivated();

    // Wipe any previous user's stats from the widget and pull this user's.
    await HomeWidgetService().clearStats();
    HomeWidgetService().refreshStats(force: true);

    _pushSessionToWear();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Load local server settings from PlayerSettings.
  Future<void> _loadLocalServerSettings() async {
    _localServerEnabled = await PlayerSettings.getLocalServerEnabled();
    final savedUrl = await PlayerSettings.getLocalServerUrl();
    _localServerUrl = normalizeServerUrl(savedUrl);
    if (_localServerUrl != savedUrl) {
      await PlayerSettings.setLocalServerUrl(_localServerUrl);
    }
    if (_localServerEnabled) {
      debugPrint('[Auth] Local server config loaded: enabled=$_localServerEnabled, url=${_localServerUrl.isNotEmpty ? "(set)" : "(empty)"}');
    }
  }

  /// Refresh in-memory state to match the now-active account's scope. Call
  /// after `UserAccountService.saveAccount()` so settings cached from the
  /// previous account don't leak across. The big one is the local-server
  /// override: if left stale, API calls route to the previous account's
  /// local URL with the new account's token, producing 401s.
  Future<void> _onAccountActivated() async {
    PlayerSettings.notifySettingsChanged();
    await EqualizerService().reloadForActiveAccount();

    await _loadLocalServerSettings();
    _useLocalServer = false;
    if (_localServerEnabled && _localServerUrl.isNotEmpty) {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.wifi)) {
        final localReachable = await ApiService.pingServer(
                _localServerUrl, customHeaders: _customHeaders)
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
        if (localReachable) {
          debugPrint('[Auth] Local server reachable - using local');
          _useLocalServer = true;
        }
      }
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
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      showOverlayToast(ctx, message, icon: Icons.dns_rounded);
    } catch (_) {}
  }

  /// Update local server settings from the UI.
  Future<void> setLocalServerConfig({required bool enabled, required String url}) async {
    final normalizedUrl = normalizeServerUrl(url);
    _localServerEnabled = enabled;
    _localServerUrl = normalizedUrl;
    await PlayerSettings.setLocalServerEnabled(enabled);
    await PlayerSettings.setLocalServerUrl(normalizedUrl);
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

    // Clear Android Auto / CarPlay browse tree cache so it doesn't show stale data
    AndroidAutoService().clearCache();
    CarPlayService().clearAndRefresh();

    // Drop the per-library search index so the next account can't reuse it.
    BookSearchIndex().clear();

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
    _ereaderDevices = const [];
    await _persistEreaderDevices();

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

    // Sign the paired watch out too.
    WearAuthService.instance.clear();

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

    // Clear Android Auto / CarPlay browse tree cache so it refreshes for the new user
    AndroidAutoService().clearCache();
    CarPlayService().clearAndRefresh();

    // Set the new account as active in the account service
    UserAccountService().switchTo(account.serverUrl, account.username);

    // Notify widgets that read scoped settings (e.g. card button layout) so
    // they reload from the new account's ScopedPrefs instead of keeping the
    // previous account's values cached in widget state.
    PlayerSettings.notifySettingsChanged();

    // Synchronous PlayerSettings caches are loaded at startup, so refresh
    // them from the new account's scope or playback keeps the old account's
    // values until restart.
    PlayerSettings.showExplicitBadge = await PlayerSettings.getShowExplicitBadge();
    PlayerSettings.mp3IndexSeeking = await PlayerSettings.getMp3IndexSeeking();

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
      final auth = await api.authorize();
      if (auth != null) {
        final user = auth['user'] as Map<String, dynamic>?;
        if (user != null) {
          _userJson = user;
          _userId = user['id'] as String?;
        }
        final devicesRaw = auth['ereaderDevices'] as List<dynamic>?;
        if (devicesRaw != null) {
          _ereaderDevices = devicesRaw.cast<Map<String, dynamic>>();
          await _persistEreaderDevices();
        }
      } else {
        final me = await api.getMe();
        if (me != null) {
          _userJson = me;
          _userId = me['id'] as String?;
        }
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
    _pushSessionToWear();
    notifyListeners();
    return true;
  }

  /// Change the server URL of a saved account in place (e.g. a dynamic-DNS
  /// hostname changed) without re-adding it. The account's per-user data is
  /// migrated to the new scope by [UserAccountService.updateAccountUrl]. If the
  /// edited account is the live session, its URL is updated immediately so the
  /// next API call (and the [apiService] getter) uses the new address.
  /// Returns true if the account was found and updated.
  Future<bool> editServerUrl(SavedAccount account, String newServerUrl) async {
    final url = normalizeServerUrl(newServerUrl);
    if (url.isEmpty) return false;
    if (url == account.serverUrl) return true; // nothing to change

    final ok = await UserAccountService()
        .updateAccountUrl(account.serverUrl, account.username, url);
    if (!ok) return false;

    // If we just edited the currently active session, update it live.
    final isActiveSession =
        account.serverUrl == _serverUrl && account.username == _username;
    if (isActiveSession) {
      _serverUrl = url;
      _serverReachable = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_url', url);
      } catch (_) {}
      _pushSessionToWear();
      notifyListeners();
    }
    return true;
  }

  /// Get all saved accounts (for the account switcher UI).
  List<SavedAccount> get savedAccounts => UserAccountService().accounts;
}
