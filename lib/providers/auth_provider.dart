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
import '../utils/app_platform.dart';
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
  bool _startOnAbsorbingAfterAccountChange = false;
  String? _errorMessage;
  bool _authExpiryInProgress = false;

  // Getters
  bool get isAuthenticated => _accessToken != null && _serverUrl != null;
  bool get isLoading => _isLoading;
  bool get startOnAbsorbingAfterAccountChange =>
      _startOnAbsorbingAfterAccountChange;
  bool get serverReachable => _serverReachable;

  /// Current access token (or legacy token for old servers).
  String? get token => _accessToken;
  String? get serverUrl => _serverUrl;
  String? get activeServerUrl => (_useLocalServer && _localServerUrl.isNotEmpty)
      ? _localServerUrl
      : _serverUrl;
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

  /// True when the server allows this user to download library item files.
  bool get canDownload {
    final perms = _userJson?['permissions'] as Map<String, dynamic>?;
    return perms?['download'] == true;
  }

  /// Replace the live app shell with the startup loading view while a saved
  /// account is being activated and its library is prepared.
  void beginAccountSwitch() {
    _startOnAbsorbingAfterAccountChange = true;
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
  }

  void finishAccountSwitch() {
    if (!_isLoading) return;
    _isLoading = false;
    notifyListeners();
  }

  /// Apply the serverSettings (and, if present, version) carried on an
  /// /api/authorize response - the same shape /login and /login/oidc return,
  /// used on every session-restore path (tryRestoreSession, ensureUserInfo,
  /// switchToAccount). Those paths never call login(), so without this the
  /// version cache stayed empty for a process that only ever restored a
  /// session - stream URLs would fall back to the tokened form even on a
  /// server whose version had already been learned in an earlier process.
  void _applyAuthorizeServerInfo(Map<String, dynamic> auth, String serverUrl) {
    final sSettings = auth['serverSettings'] as Map<String, dynamic>?;
    if (sSettings != null) _serverSettings = sSettings;
    final version =
        auth['serverVersion'] as String? ?? (sSettings?['version'] as String?);
    if (version != null && version.isNotEmpty) {
      _serverVersion = version;
      ApiService.cacheServerVersion(serverUrl, version);
    }
  }

  /// Re-cache server settings after an admin saves them via PATCH /api/settings
  /// (which echoes the updated serverSettings). Keeps cached values and the
  /// shown server version fresh without forcing a re-login.
  void applyServerSettings(Map<String, dynamic> settings) {
    _serverSettings = settings;
    final v = settings['version'] as String?;
    if (v != null && v.isNotEmpty) {
      _serverVersion = v;
      final url = activeServerUrl;
      if (url != null) ApiService.cacheServerVersion(url, v);
    }
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
    List<Map<String, dynamic>> all,
  ) {
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
      return _createSessionApi(
        baseUrl: url,
        token: _accessToken!,
        refreshToken: _refreshToken,
        isLegacyToken: _isLegacyToken,
      );
    }
    return null;
  }

  ApiService _createSessionApi({
    required String baseUrl,
    required String token,
    required String? refreshToken,
    required bool isLegacyToken,
  }) {
    final sessionServer = _serverUrl ?? baseUrl;
    final sessionUsername = _username;
    return ApiService(
      baseUrl: baseUrl,
      token: token,
      refreshToken: refreshToken,
      isLegacyToken: isLegacyToken,
      customHeaders: _customHeaders,
      loadPersistedTokens: () => UserAccountService().loadPersistedTokens(
        sessionServer,
        sessionUsername,
      ),
      onTokensRefreshed: (access, refresh) =>
          _onTokensRefreshed(sessionServer, sessionUsername, access, refresh),
      onAuthExpired: () => _onAuthExpired(sessionServer, sessionUsername),
    );
  }

  bool _isCurrentSession(String serverUrl, String? username) {
    final currentServer = _serverUrl;
    return currentServer != null &&
        normalizeServerUrl(currentServer) == normalizeServerUrl(serverUrl) &&
        _username == username;
  }

  Future<void> _onTokensRefreshed(
    String sessionServer,
    String? sessionUsername,
    String newAccessToken,
    String? newRefreshToken,
  ) async {
    if (!_isCurrentSession(sessionServer, sessionUsername) ||
        _accessToken == null) {
      return;
    }
    final refreshUnchanged =
        newRefreshToken == null || newRefreshToken == _refreshToken;
    if (_accessToken == newAccessToken && refreshUnchanged) return;
    _accessToken = newAccessToken;
    if (newRefreshToken != null) _refreshToken = newRefreshToken;
    try {
      await UserAccountService().persistRefreshedTokens(
        _accessToken!,
        _refreshToken,
        serverUrl: sessionServer,
        username: sessionUsername,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'token_saved_at', DateTime.now().millisecondsSinceEpoch);
      debugPrint(
        '[Auth] Rotated tokens persisted: '
        'access=${ApiService.tokenFp(_accessToken)} '
        'refresh=${ApiService.tokenFp(_refreshToken)}',
      );
    } catch (e) {
      debugPrint('[Auth] Failed to persist refreshed tokens: $e');
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
    if (AppPlatform.isWeb) return;
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
      supportsTokenReturn: true,
    );
  }

  /// Adopt a token pair rotated by Android Auto or the paired Wear app.
  Future<void> adoptCompanionTokens() async {
    final server = _serverUrl;
    final username = _username;
    if (server == null || _accessToken == null) return;
    final tokens = await UserAccountService().loadPersistedTokens(
      server,
      username,
    );
    if (tokens?.accessToken == null || tokens!.accessToken == _accessToken)
      return;
    await _onTokensRefreshed(
      server,
      username,
      tokens.accessToken!,
      tokens.refreshToken,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wear_token_pair_pending');
  }

  void _onAuthExpired(String sessionServer, String? sessionUsername) {
    if (!_isCurrentSession(sessionServer, sessionUsername) ||
        _accessToken == null ||
        _authExpiryInProgress) {
      return;
    }
    _authExpiryInProgress = true;
    debugPrint(
      '[Auth] Token refresh failed, forcing re-login '
      '(access=${ApiService.tokenFp(_accessToken)} '
      'refresh=${ApiService.tokenFp(_refreshToken)})',
    );
    unawaited(SharedPreferences.getInstance().then((prefs) {
      final savedAt = prefs.getInt('token_saved_at');
      if (savedAt != null) {
        final age = Duration(
            milliseconds: DateTime.now().millisecondsSinceEpoch - savedAt);
        debugPrint(
            '[Auth] Expired session tokens were last persisted ${age.inHours}h ago');
      }
    }));
    // Show a message to the user
    final ctx = rootNavigatorKey.currentContext;
    final l = ctx != null ? AppLocalizations.of(ctx) : null;
    final msg =
        l?.authSessionExpired ?? 'Session expired. Please log in again.';
    if (ctx != null)
      showOverlayToast(ctx, msg, icon: Icons.error_outline_rounded);
    unawaited(
      logout(forgetAccount: false).whenComplete(() {
        _authExpiryInProgress = false;
      }),
    );
  }

  /// Try to restore a saved session from SharedPreferences.
  /// If the server is unreachable, still restore credentials so offline mode works.
  Future<void> tryRestoreSession() async {
    final sw = Stopwatch()..start();
    debugPrint('[Auth] tryRestoreSession started');
    _isLoading = true;
    _startOnAbsorbingAfterAccountChange = false;
    _serverReachable = true;
    notifyListeners();

    try {
      debugPrint('[Auth] getting SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      debugPrint(
        '[Auth] SharedPreferences loaded (${sw.elapsedMilliseconds}ms)',
      );
      final savedUrl = prefs.getString('server_url');
      final savedToken = prefs.getString('token');
      final savedRefreshToken = prefs.getString('refresh_token');
      final savedUsername = prefs.getString('username');
      final savedLibraryId = prefs.getString('default_library_id');
      // Restore ereader devices alongside other session data. /api/me doesn't
      // return them, so without this they'd stay empty until next login.
      await _restoreEreaderDevices();

      final tokenSavedAt = prefs.getInt('token_saved_at');
      final tokenAge = tokenSavedAt == null
          ? 'unknown'
          : '${Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - tokenSavedAt).inHours}h';
      debugPrint(
        '[Auth] saved credentials: url=${savedUrl != null}, token=${savedToken != null}, refreshToken=${savedRefreshToken != null} '
        '(access=${ApiService.tokenFp(savedToken)}, refresh=${ApiService.tokenFp(savedRefreshToken)}, saved $tokenAge ago)',
      );

      if (savedUrl != null && savedToken != null) {
        // Always restore credentials so we can at least go offline
        final restoredUrl = normalizeServerUrl(savedUrl);
        if (restoredUrl != savedUrl) {
          await prefs.setString('server_url', restoredUrl);
          if (savedUsername != null) {
            await UserAccountService().updateAccountUrl(
              savedUrl,
              savedUsername,
              restoredUrl,
            );
          }
        }
        _serverUrl = restoredUrl;
        _accessToken = savedToken;
        _refreshToken = savedRefreshToken;
        _isLegacyToken = savedRefreshToken == null;
        debugPrint(
          '[Auth] Restored token: ${savedToken.substring(0, savedToken.length.clamp(0, 20))}... (${savedToken.length} chars, isLegacy=$_isLegacyToken)',
        );
        _username = savedUsername;
        _userId = prefs.getString('user_id');
        _defaultLibraryId = savedLibraryId;

        // Older releases stored one global header map. Saved accounts now own
        // their headers, but keep the global value as a migration fallback.
        final headersJson = prefs.getString('custom_headers');
        var legacyCustomHeaders = <String, String>{};
        if (headersJson != null) {
          try {
            legacyCustomHeaders = Map<String, String>.from(
              jsonDecode(headersJson) as Map,
            );
          } catch (_) {}
        }
        SavedAccount? restoredAccount;
        for (final account in UserAccountService().accounts) {
          if (normalizeServerUrl(account.serverUrl) == restoredUrl &&
              account.username == savedUsername) {
            restoredAccount = account;
            break;
          }
        }
        _customHeaders = restoredAccount?.customHeaders ?? legacyCustomHeaders;

        // Load local server config
        await _loadLocalServerSettings();

        // Check if server is actually reachable.
        // If local server is enabled and we're on WiFi, try local first
        // (lower latency) and only fall back to remote if local fails.
        var reachable = false;
        if (_localServerEnabled && _localServerUrl.isNotEmpty) {
          final connectivity = await Connectivity().checkConnectivity();
          if (connectivity.contains(ConnectivityResult.wifi)) {
            debugPrint(
              '[Auth] On WiFi with local server enabled, trying local first... (${sw.elapsedMilliseconds}ms)',
            );
            final localReachable = await ApiService.pingServer(
              _localServerUrl,
              customHeaders: _customHeaders,
            ).timeout(const Duration(seconds: 2), onTimeout: () => false);
            if (localReachable) {
              debugPrint(
                '[Auth] Local server reachable - using local (${sw.elapsedMilliseconds}ms)',
              );
              _useLocalServer = true;
              reachable = true;
            }
          }
        }
        if (!reachable) {
          debugPrint(
            '[Auth] pinging remote server... (${sw.elapsedMilliseconds}ms)',
          );
          // Cap at 5s so a silently-dropping reverse proxy or dead network
          // path doesn't hold up app launch. The health-check timer will
          // re-probe every 60s once we're past startup, so a transient
          // false-offline self-corrects quickly.
          reachable = await ApiService.pingServer(
            restoredUrl,
            customHeaders: _customHeaders,
          ).timeout(const Duration(seconds: 5), onTimeout: () => false);
          debugPrint(
            '[Auth] remote ping result: reachable=$reachable (${sw.elapsedMilliseconds}ms)',
          );
        }
        _serverReachable = reachable;
        if (AppPlatform.isWeb && !reachable) {
          _accessToken = null;
          _refreshToken = null;
          _isLegacyToken = false;
        }

        // Fetch full user info (needed for isAdmin, permissions, etc.)
        if (reachable) {
          try {
            debugPrint('[Auth] fetching /me... (${sw.elapsedMilliseconds}ms)');
            final api = _createSessionApi(
              baseUrl: activeServerUrl!,
              token: savedToken,
              refreshToken: savedRefreshToken,
              isLegacyToken: _isLegacyToken,
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
              _applyAuthorizeServerInfo(auth, activeServerUrl!);
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
            debugPrint(
              '[Auth] authorize/me done (${sw.elapsedMilliseconds}ms)',
            );
          } catch (_) {}
          _fetchServerVersion(activeServerUrl!);
        }
      } else if (savedUrl != null) {
        // A rejected refresh clears credentials but keeps enough identity to
        // prefill the login form instead of making the user re-enter the server.
        _serverUrl = normalizeServerUrl(savedUrl);
        _username = savedUsername;
      }
    } catch (e) {
      // Restore failed — but if we already set credentials, keep them
      debugPrint(
        '[Auth] tryRestoreSession error: $e (${sw.elapsedMilliseconds}ms)',
      );
      _serverReachable = false;
    }

    debugPrint(
      '[Auth] tryRestoreSession done, isAuthenticated=$isAuthenticated (${sw.elapsedMilliseconds}ms)',
    );
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
    if (!isAuthenticated || _accessToken == null || activeServerUrl == null)
      return;
    _ensuringUserInfo = true;
    try {
      final api = _createSessionApi(
        baseUrl: activeServerUrl!,
        token: _accessToken!,
        refreshToken: _refreshToken,
        isLegacyToken: _isLegacyToken,
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
        _applyAuthorizeServerInfo(auth, activeServerUrl!);
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
        debugPrint(
          '[Auth] Loaded user info on reconnect (type=${_userJson?['type']})',
        );
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
    final reachable = await ApiService.pingServer(
      url,
      customHeaders: customHeaders,
    );
    if (!reachable) {
      _errorMessage =
          l?.authCannotReachServer(url) ?? 'Cannot reach server at $url';
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
          : (l?.authLoginFailedDetail ??
                'Login failed - check your server address and credentials');
      return false;
    }

    // Extract user info
    final user = result['user'] as Map<String, dynamic>?;
    if (user == null) {
      _errorMessage =
          l?.authUnexpectedServerResponse ?? 'Unexpected server response';
      return false;
    }

    _serverUrl = url;
    // Prefer the JWTs returned inside user by current servers, while accepting
    // the top-level shape and legacy token used by older servers.
    final tokens = AuthTokens.fromResponse(result);
    if (tokens.token == null) {
      _errorMessage =
          l?.authUnexpectedServerResponse ?? 'Unexpected server response';
      return false;
    }
    _isLegacyToken = tokens.isLegacy;
    _accessToken = tokens.token;
    _refreshToken = tokens.refreshToken;
    _serverReachable = true;
    debugPrint('[Auth] Login response keys: ${result.keys.toList()}');
    debugPrint('[Auth] Login user keys: ${user.keys.toList()}');
    debugPrint(
      '[Auth] accessToken=${tokens.accessToken != null}, refreshToken=${tokens.refreshToken != null}, legacyToken=${tokens.legacyToken != null}, isLegacy=$_isLegacyToken',
    );
    debugPrint(
      '[Auth] Token being used: ${_accessToken != null ? '${_accessToken!.substring(0, _accessToken!.length.clamp(0, 20))}... (${_accessToken!.length} chars)' : 'null'}',
    );
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
    final loginVersion =
        result['serverVersion'] as String? ??
        (_serverSettings?['version'] as String?);
    if (loginVersion != null && loginVersion.isNotEmpty) {
      _serverVersion = loginVersion;
      ApiService.cacheServerVersion(url, loginVersion);
    } else {
      _fetchServerVersion(url);
    }

    // Persist session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', _serverUrl!);
      if (_accessToken != null) await prefs.setString('token', _accessToken!);
      if (_refreshToken != null)
        await prefs.setString('refresh_token', _refreshToken!);
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
      await UserAccountService().saveAccount(
        SavedAccount(
          serverUrl: _serverUrl!,
          username: _username ?? '',
          token: _accessToken ?? '',
          refreshToken: _refreshToken,
          userId: _userId,
          isLegacyToken: _isLegacyToken,
          customHeaders: customHeaders,
        ),
      );
    } catch (_) {}

    await _onAccountActivated();

    if (!AppPlatform.isWeb) {
      await HomeWidgetService().clearStats();
      HomeWidgetService().refreshStats(force: true);
      _pushSessionToWear();
    }
    _startOnAbsorbingAfterAccountChange = true;
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

    final reachable = await ApiService.pingServer(
      url,
      customHeaders: customHeaders,
    );
    if (!reachable) {
      _errorMessage =
          l?.authCannotReachServer(url) ?? 'Cannot reach server at $url';
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
          : (l?.authLoginFailedDetail ??
                'Login failed - check your server address and API key');
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
    _serverReachable = true;
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
      await UserAccountService().saveAccount(
        SavedAccount(
          serverUrl: _serverUrl!,
          username: _username ?? '',
          token: _accessToken!,
          refreshToken: null,
          userId: _userId,
          isLegacyToken: true,
          customHeaders: customHeaders,
        ),
      );
    } catch (_) {}

    await _onAccountActivated();

    if (!AppPlatform.isWeb) {
      await HomeWidgetService().clearStats();
      HomeWidgetService().refreshStats(force: true);
      _pushSessionToWear();
    }
    _startOnAbsorbingAfterAccountChange = true;
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
      _errorMessage =
          l?.authSsoUnexpectedResponse ?? 'SSO returned an unexpected response';
      notifyListeners();
      return false;
    }

    _serverUrl = url;
    final tokens = AuthTokens.fromResponse(result);
    if (tokens.token == null) {
      _errorMessage =
          l?.authSsoUnexpectedResponse ?? 'SSO returned an unexpected response';
      notifyListeners();
      return false;
    }
    _isLegacyToken = tokens.isLegacy;
    _accessToken = tokens.token;
    _refreshToken = tokens.refreshToken;
    debugPrint('[Auth] OIDC response keys: ${result.keys.toList()}');
    debugPrint('[Auth] OIDC user keys: ${user.keys.toList()}');
    debugPrint(
      '[Auth] accessToken=${tokens.accessToken != null}, refreshToken=${tokens.refreshToken != null}, legacyToken=${tokens.legacyToken != null}, isLegacy=$_isLegacyToken',
    );
    debugPrint(
      '[Auth] Token being used: ${_accessToken != null ? '${_accessToken!.substring(0, _accessToken!.length.clamp(0, 20))}... (${_accessToken!.length} chars)' : 'null'}',
    );
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
    final oidcVersion =
        result['serverVersion'] as String? ??
        (_serverSettings?['version'] as String?);
    if (oidcVersion != null && oidcVersion.isNotEmpty) {
      _serverVersion = oidcVersion;
      ApiService.cacheServerVersion(url, oidcVersion);
    } else {
      _fetchServerVersion(url);
    }

    // Persist session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', _serverUrl!);
      if (_accessToken != null) await prefs.setString('token', _accessToken!);
      if (_refreshToken != null)
        await prefs.setString('refresh_token', _refreshToken!);
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
      await UserAccountService().saveAccount(
        SavedAccount(
          serverUrl: _serverUrl!,
          username: _username ?? '',
          token: _accessToken ?? '',
          refreshToken: _refreshToken,
          userId: _userId,
          isLegacyToken: _isLegacyToken,
          customHeaders: customHeaders,
        ),
      );
    } catch (_) {}

    await _onAccountActivated();

    if (!AppPlatform.isWeb) {
      await HomeWidgetService().clearStats();
      HomeWidgetService().refreshStats(force: true);
      _pushSessionToWear();
    }
    _startOnAbsorbingAfterAccountChange = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Load local server settings from PlayerSettings.
  Future<void> _loadLocalServerSettings() async {
    if (AppPlatform.isWeb) {
      _localServerEnabled = false;
      _localServerUrl = '';
      _useLocalServer = false;
      return;
    }
    _localServerEnabled = await PlayerSettings.getLocalServerEnabled();
    final savedUrl = await PlayerSettings.getLocalServerUrl();
    _localServerUrl = normalizeServerUrl(savedUrl);
    if (_localServerUrl != savedUrl) {
      await PlayerSettings.setLocalServerUrl(_localServerUrl);
    }
    if (_localServerEnabled) {
      debugPrint(
        '[Auth] Local server config loaded: enabled=$_localServerEnabled, url=${_localServerUrl.isNotEmpty ? "(set)" : "(empty)"}',
      );
    }
  }

  /// Refresh in-memory state to match the now-active account's scope. Call
  /// after `UserAccountService.saveAccount()` so settings cached from the
  /// previous account don't leak across. The big one is the local-server
  /// override: if left stale, API calls route to the previous account's
  /// local URL with the new account's token, producing 401s.
  Future<void> _onAccountActivated() async {
    PlayerSettings.notifySettingsChanged();
    if (!AppPlatform.isWeb) {
      await EqualizerService().reloadForActiveAccount();
    }

    await _loadLocalServerSettings();
    _useLocalServer = false;
    if (_localServerEnabled && _localServerUrl.isNotEmpty) {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.wifi)) {
        final localReachable = await ApiService.pingServer(
          _localServerUrl,
          customHeaders: _customHeaders,
        ).timeout(const Duration(seconds: 2), onTimeout: () => false);
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
    if (AppPlatform.isWeb) return;
    if (!_localServerEnabled || _localServerUrl.isEmpty || _serverUrl == null)
      return;
    final wasLocal = _useLocalServer;
    try {
      final reachable = await ApiService.pingServer(
        _localServerUrl,
        customHeaders: _customHeaders,
      ).timeout(const Duration(seconds: 3), onTimeout: () => false);
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
      _showServerToast(
        _useLocalServer
            ? (l?.authSwitchedToLocalServer ?? 'Switched to local server')
            : (l?.authSwitchedToRemoteServer ?? 'Switched to remote server'),
      );
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
    _showServerToast(
      l?.authSwitchedToRemoteServer ?? 'Switched to remote server',
    );
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
  Future<void> setLocalServerConfig({
    required bool enabled,
    required String url,
  }) async {
    if (AppPlatform.isWeb) return;
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
      final version = await ApiService.getServerVersion(
        url,
        customHeaders: _customHeaders,
      );
      if (version != null) {
        _serverVersion = version;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout({
    bool forgetAccount = true,
    bool keepServer = false,
    bool revokeServerSession = false,
    bool allDevices = false,
  }) async {
    if (revokeServerSession) await adoptCompanionTokens();

    // Stop any active playback
    try {
      final player = AudioPlayerService();
      if (player.hasBook) {
        await player.pause();
        await player.stop();
      }
    } catch (_) {}

    if (!AppPlatform.isWeb) {
      AndroidAutoService().clearCache();
      CarPlayService().clearAndRefresh();
    }

    // Drop the per-library search index so the next account can't reuse it.
    BookSearchIndex().clear();

    if (!AppPlatform.isWeb) await HomeWidgetService().clearStats();

    // Clear cached session metadata for this user (track URLs would be invalid
    // on next login anyway)
    await SessionCache.clearAll();

    // Remove account from saved accounts list
    final logoutServer = _serverUrl;
    final logoutUser = _username;

    // Only an explicit sign-out revokes the server session. Account switches
    // and auth-expiry cleanup intentionally keep their existing local behavior.
    if (revokeServerSession &&
        logoutServer != null &&
        _accessToken != null &&
        _refreshToken != null) {
      final api = _createSessionApi(
        baseUrl: logoutServer,
        token: _accessToken!,
        refreshToken: _refreshToken,
        isLegacyToken: _isLegacyToken,
      );
      await api.revokeServerSession(allDevices: allDevices);
    }

    _accessToken = null;
    _refreshToken = null;
    _isLegacyToken = false;
    if (forgetAccount) {
      _serverUrl = keepServer ? logoutServer : null;
      _username = null;
    }
    _userId = null;
    _defaultLibraryId = null;
    _userJson = null;
    _serverSettings = null;
    _serverVersion = null;
    _startOnAbsorbingAfterAccountChange = false;
    _errorMessage = null;
    _ereaderDevices = const [];
    await _persistEreaderDevices();

    try {
      if (logoutServer != null && logoutUser != null) {
        if (forgetAccount) {
          await UserAccountService().removeAccount(logoutServer, logoutUser);
        } else {
          await UserAccountService().clearTokens(logoutServer, logoutUser);
        }
      }
      final prefs = await SharedPreferences.getInstance();
      if (forgetAccount) {
        if (keepServer && logoutServer != null) {
          await prefs.setString('server_url', logoutServer);
        } else {
          await prefs.remove('server_url');
        }
      }
      await prefs.remove('token');
      await prefs.remove('refresh_token');
      if (forgetAccount) await prefs.remove('username');
      await prefs.remove('user_id');
      await prefs.remove('default_library_id');
    } catch (_) {}

    if (!AppPlatform.isWeb) WearAuthService.instance.clear();

    notifyListeners();
  }

  /// Switch to a saved account without going through the login screen.
  /// Stops playback, swaps credentials, and notifies listeners so the
  /// app reloads with the new user's data.
  Future<bool> switchToAccount(SavedAccount account) async {
    if (account.token.isEmpty) return false;
    await adoptCompanionTokens();

    // Stop current playback
    try {
      final player = AudioPlayerService();
      if (player.hasBook) {
        await player.pause();
        await player.stop();
      }
    } catch (_) {}

    if (!AppPlatform.isWeb) {
      AndroidAutoService().clearCache();
      CarPlayService().clearAndRefresh();
    }

    // Set the new account as active in the account service. It may have been
    // removed since the caller loaded its saved-account row.
    final selected = UserAccountService().switchTo(
      account.serverUrl,
      account.username,
    );
    if (selected == null) return false;
    _startOnAbsorbingAfterAccountChange = true;

    // Notify widgets that read scoped settings (e.g. card button layout) so
    // they reload from the new account's ScopedPrefs instead of keeping the
    // previous account's values cached in widget state.
    PlayerSettings.notifySettingsChanged();

    // Synchronous PlayerSettings caches are loaded at startup, so refresh
    // them from the new account's scope or playback keeps the old account's
    // values until restart.
    PlayerSettings.showExplicitBadge =
        await PlayerSettings.getShowExplicitBadge();
    PlayerSettings.mp3IndexSeeking = await PlayerSettings.getMp3IndexSeeking();

    // Reload EQ settings from the new account's scope. Without this the
    // EqualizerService singleton keeps the previous account's in-memory
    // state and would write it back into the new scope on any change.
    if (!AppPlatform.isWeb) {
      await EqualizerService().reloadForActiveAccount();
    }

    // Set credentials
    _serverUrl = selected.serverUrl;
    _accessToken = selected.token;
    _refreshToken = selected.refreshToken;
    _isLegacyToken = selected.isLegacyToken;
    _username = selected.username;
    _userId = selected.userId;
    _customHeaders = selected.customHeaders;
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
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      } else {
        await prefs.remove('refresh_token');
      }
      if (_username != null) await prefs.setString('username', _username!);
      if (_userId != null) {
        await prefs.setString('user_id', _userId!);
      } else {
        await prefs.remove('user_id');
      }
      await prefs.remove('default_library_id');
      if (_customHeaders.isNotEmpty) {
        await prefs.setString('custom_headers', jsonEncode(_customHeaders));
      } else {
        await prefs.remove('custom_headers');
      }
    } catch (_) {}

    if (!AppPlatform.isWeb) {
      await HomeWidgetService().clearStats();
      HomeWidgetService().refreshStats(force: true);
    }

    // Verify the token still works and get user info
    try {
      final api = _createSessionApi(
        baseUrl: _serverUrl!,
        token: _accessToken!,
        refreshToken: _refreshToken,
        isLegacyToken: _isLegacyToken,
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
        _applyAuthorizeServerInfo(auth, _serverUrl!);
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
        final localReachable = await ApiService.pingServer(
          _localServerUrl,
          customHeaders: _customHeaders,
        ).timeout(const Duration(seconds: 2), onTimeout: () => false);
        if (localReachable) {
          debugPrint(
            '[Auth] switchToAccount: local server reachable - using local',
          );
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
    return editServerConnection(account, newServerUrl, account.customHeaders);
  }

  /// Update the connection details for one saved account. Custom headers are
  /// account-specific so users on different reverse proxies do not inherit
  /// each other's credentials.
  Future<bool> editServerConnection(
    SavedAccount account,
    String newServerUrl,
    Map<String, String> customHeaders,
  ) async {
    final url = normalizeServerUrl(newServerUrl);
    if (url.isEmpty) return false;
    final headersUnchanged =
        customHeaders.length == account.customHeaders.length &&
        customHeaders.entries.every(
          (entry) => account.customHeaders[entry.key] == entry.value,
        );
    if (url == account.serverUrl && headersUnchanged) return true;

    final ok = await UserAccountService().updateAccountConnection(
      account.serverUrl,
      account.username,
      url,
      customHeaders,
    );
    if (!ok) return false;

    // If we just edited the currently active session, update it live.
    final isActiveSession =
        account.serverUrl == _serverUrl && account.username == _username;
    if (isActiveSession) {
      _serverUrl = url;
      _customHeaders = Map.unmodifiable(customHeaders);
      _serverReachable = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_url', url);
        if (_customHeaders.isNotEmpty) {
          await prefs.setString('custom_headers', jsonEncode(_customHeaders));
        } else {
          await prefs.remove('custom_headers');
        }
      } catch (_) {}
      final token = _accessToken;
      if (token != null) {
        SocketService().connect(
          activeServerUrl!,
          token,
          customHeaders: _customHeaders,
        );
      }
      _pushSessionToWear();
      notifyListeners();
    }
    return true;
  }

  /// Get all saved accounts (for the account switcher UI).
  List<SavedAccount> get savedAccounts => UserAccountService().accounts;
}
