import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:io' show HttpClient, HttpHeaders;
import 'api_service.dart';

/// Manages the OIDC/OAuth2 PKCE flow for audiobookshelf SSO login.
class OidcService {
  static final OidcService _instance = OidcService._();
  factory OidcService() => _instance;
  OidcService._();

  // PKCE state
  String? _codeVerifier;
  String? _codeChallenge;
  String? _state;
  String? _serverUrl;
  String? _nonce;

  /// The raw cookie strings from the /auth/openid response.
  List<String> _rawCookies = [];

  /// Custom headers (e.g. Cloudflare Access) carried across the flow so the
  /// callback request can pass the same proxy as the pre-flight.
  Map<String, String> _customHeaders = const {};

  /// Diagnostic message from the most recent failure. Cleared on each
  /// startLogin() call. Null when the last attempt succeeded or the user
  /// simply cancelled the popup. Surface to the UI so SSO failures aren't
  /// silently swallowed.
  String? _lastError;
  String? get lastError => _lastError;

  /// True when the most recent failure was the user dismissing the popup
  /// (vs. a real network/protocol error). Lets the UI suppress the snackbar
  /// for plain cancellations.
  bool _lastWasUserCancel = false;
  bool get lastWasUserCancel => _lastWasUserCancel;

  static const _redirectUri = 'audiobookshelf://oauth';
  static const _clientId = 'Audiobookshelf-App';

  /// Generate a cryptographically random string of [length] bytes, base64url-encoded.
  String _generateRandom(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Generate PKCE code_verifier and code_challenge (S256).
  void _generatePkce() {
    _codeVerifier = _generateRandom(32); // 43-char min
    final bytes = utf8.encode(_codeVerifier!);
    final digest = sha256.convert(bytes);
    _codeChallenge = base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Start the OIDC login flow using a Chrome Custom Tab.
  /// Returns the callback [Uri] on success, or null on failure/cancellation.
  /// On failure, [lastError] holds a diagnostic message and [lastWasUserCancel]
  /// distinguishes user-dismissed popups from real errors.
  Future<Uri?> startLogin(String serverUrl, {Map<String, String> customHeaders = const {}}) async {
    _serverUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    _generatePkce();
    _state = _generateRandom(16);
    _rawCookies = [];
    _customHeaders = customHeaders;
    _lastError = null;
    _lastWasUserCancel = false;

    final authUrl = '$_serverUrl/auth/openid'
        '?code_challenge=$_codeChallenge'
        '&code_challenge_method=S256'
        '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
        '&client_id=${Uri.encodeComponent(_clientId)}'
        '&response_type=code'
        '&state=$_state';

    debugPrint('[OIDC] Starting auth flow: $authUrl');

    String? providerUrl;
    try {
      // Pre-flight request to capture cookies and get the OIDC provider redirect URL.
      // ABS sets a session cookie that links the PKCE challenge to this flow.
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      try {
        final request = await client.getUrl(Uri.parse(authUrl));
        request.followRedirects = false;
        _customHeaders.forEach(request.headers.set);
        request.headers.set('x-return-tokens', 'true');
        final response = await request.close();

        // Capture cookies for the callback request
        final cookies = response.cookies;
        for (final cookie in cookies) {
          _rawCookies.add('${cookie.name}=${cookie.value}');
          debugPrint('[OIDC] Captured cookie: ${cookie.name}');
        }
        if (_rawCookies.isEmpty) {
          final rawSetCookie = response.headers[HttpHeaders.setCookieHeader];
          if (rawSetCookie != null) {
            for (final sc in rawSetCookie) {
              final nameValue = sc.split(';').first.trim();
              _rawCookies.add(nameValue);
              debugPrint('[OIDC] Captured raw cookie: $nameValue');
            }
          }
        }

        if (response.statusCode == 302 || response.statusCode == 301) {
          providerUrl = response.headers.value(HttpHeaders.locationHeader);
          await response.drain<void>();
        } else {
          final body = await response.transform(utf8.decoder).join();
          debugPrint('[OIDC] Unexpected status ${response.statusCode}: $body');
          // Truncate body to keep the snackbar readable.
          final preview = body.length > 200 ? '${body.substring(0, 200)}…' : body;
          _lastError = 'Server returned HTTP ${response.statusCode} from /auth/openid '
              '(expected 302). Body: $preview';
          _cleanup();
          return null;
        }
      } finally {
        client.close();
      }
    } on Exception catch (e, st) {
      // TLS, connection, timeout, DNS — all surface here. Keep the message
      // verbatim so users can paste it back when reporting issues.
      debugPrint('[OIDC] Pre-flight error: $e\n$st');
      _lastError = 'Could not reach $_serverUrl/auth/openid: $e';
      _cleanup();
      return null;
    }

    if (providerUrl == null || providerUrl.isEmpty) {
      debugPrint('[OIDC] Server did not return a redirect URL');
      _lastError = 'Server accepted /auth/openid but did not return a Location '
          'header. Check that the OIDC provider is configured in ABS.';
      _cleanup();
      return null;
    }

    debugPrint('[OIDC] Opening Custom Tab for: $providerUrl');
    return _openBrowser(providerUrl, 'audiobookshelf');
  }

  /// BookOrbit only takes this return address from an app (unless its admin
  /// renamed it), the same one BookOrbit's own apps use.
  static const bookOrbitRedirectUri = 'bookorbit://oauth2-callback';

  /// The identity provider's sign-in page for a BookOrbit login, with PKCE.
  /// BookOrbit leaves this step to the app and only checks the result.
  static Uri bookOrbitAuthorizeUrl({
    required String authorizationEndpoint,
    required BookOrbitOidcProvider provider,
    required String state,
    required String nonce,
    required String codeChallenge,
  }) {
    final endpoint = Uri.parse(authorizationEndpoint);
    return endpoint.replace(queryParameters: {
      ...endpoint.queryParameters,
      'response_type': 'code',
      'client_id': provider.clientId,
      'scope': provider.scopes,
      'redirect_uri': bookOrbitRedirectUri,
      'state': state,
      'nonce': nonce,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });
  }

  /// Start a BookOrbit single sign-on through [provider]. Returns the
  /// callback like [startLogin].
  Future<Uri?> startBookOrbitLogin(
    String serverUrl,
    BookOrbitOidcProvider provider, {
    Map<String, String> customHeaders = const {},
  }) async {
    _serverUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    _generatePkce();
    _nonce = _generateRandom(16);
    _rawCookies = [];
    _customHeaders = customHeaders;
    _lastError = null;
    _lastWasUserCancel = false;
    final String url;
    try {
      final start = await BookOrbitApiService.oidcState(_serverUrl!, provider.slug, customHeaders: customHeaders);
      _state = start.state;
      url = bookOrbitAuthorizeUrl(
        authorizationEndpoint: start.authorizationEndpoint,
        provider: provider,
        state: start.state,
        nonce: _nonce!,
        codeChallenge: _codeChallenge!,
      ).toString();
    } catch (e) {
      debugPrint('[OIDC] BookOrbit start failed: $e');
      _lastError = 'Could not start sign-in with ${provider.displayName}: $e';
      _cleanup();
      return null;
    }
    debugPrint('[OIDC] Opening BookOrbit sign-in with ${provider.slug}');
    return _openBrowser(url, 'bookorbit');
  }

  /// Finish a BookOrbit sign-on from its callback. Returns an
  /// Audiobookshelf-shaped login response, or null with [lastError] set.
  Future<Map<String, dynamic>?> handleBookOrbitCallback(Uri uri) async {
    _lastError = null;
    _lastWasUserCancel = false;
    final providerError = uri.queryParameters['error'];
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    if (providerError != null) {
      final detail = uri.queryParameters['error_description'];
      _lastError = 'The sign-in provider answered "$providerError"${detail != null ? ': $detail' : ''}. '
          'Check that $bookOrbitRedirectUri is an allowed redirect URI for this client.';
      _cleanup();
      return null;
    }
    if (code == null || code.isEmpty) {
      _lastError = 'OIDC provider returned no authorization code. '
          'Check the provider logs for an "invalid redirect_uri" or '
          '"invalid client" error.';
      _cleanup();
      return null;
    }
    if (state != _state) {
      _lastError = 'OIDC state mismatch - possible session expiry or '
          'cross-tab interference. Try again.';
      _cleanup();
      return null;
    }
    if (_serverUrl == null || _codeVerifier == null || _nonce == null) {
      _lastError = 'OIDC flow state was lost between popup and callback.';
      _cleanup();
      return null;
    }
    final (result, status, message) = await BookOrbitApiService.signInWithOidc(
      serverUrl: _serverUrl!,
      code: code,
      codeVerifier: _codeVerifier!,
      redirectUri: bookOrbitRedirectUri,
      nonce: _nonce!,
      state: state!,
      customHeaders: _customHeaders,
    );
    _cleanup();
    if (result == null) {
      _lastError = status == 0
          ? 'BookOrbit sign-in request failed: $message'
          : 'BookOrbit returned HTTP $status${message != null && message.isNotEmpty ? ': $message' : ''}';
    }
    return result;
  }

  /// Open [url] in an in-app browser tab. On Android this is a Chrome Custom
  /// Tab; on iOS, ASWebAuthenticationSession. Both intercept the [scheme]
  /// callback and return it to us. Unlike an external browser, neither can be
  /// hijacked by PWAs or other apps registered for the provider's domain.
  Future<Uri?> _openBrowser(String url, String scheme) async {
    try {
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: scheme,
      );
      debugPrint('[OIDC] Custom Tab returned: $resultUrl');
      return Uri.parse(resultUrl);
    } on PlatformException catch (e) {
      // Cancellation arrives as PlatformException. Both plugins use code
      // CANCELED, but iOS occasionally surfaces the underlying ASWeb error
      // code (e.g. canceledLogin = 1). Treat the well-known cancel codes
      // as a quiet cancel and anything else as a real error.
      final code = e.code.toUpperCase();
      final msg = (e.message ?? '').toLowerCase();
      final isCancel = code == 'CANCELED'
          || code == 'CANCELLED'
          || code == 'USER_CANCELED'
          || msg.contains('canceled')
          || msg.contains('cancelled');
      if (isCancel) {
        debugPrint('[OIDC] User cancelled the popup');
        _lastWasUserCancel = true;
      } else {
        debugPrint('[OIDC] Auth session error: ${e.code} ${e.message}');
        _lastError = 'In-app browser failed: ${e.code}'
            '${e.message != null ? ' — ${e.message}' : ''}';
      }
      _cleanup();
      return null;
    } catch (e, st) {
      debugPrint('[OIDC] Auth session unexpected error: $e\n$st');
      _lastError = 'In-app browser failed: $e';
      _cleanup();
      return null;
    }
  }

  /// Build a Cookie header string from stored cookies.
  String get _cookieHeader => _rawCookies.join('; ');

  /// Handle the callback URI returned from the Custom Tab.
  /// Returns the user login response (same as /login) or null on failure.
  Future<Map<String, dynamic>?> handleCallback(Uri uri) async {
    _lastError = null;
    _lastWasUserCancel = false;
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];

    debugPrint('[OIDC] Callback received: code=${code != null ? '***' : 'null'}, state=$state');

    if (code == null || code.isEmpty) {
      debugPrint('[OIDC] No code in callback');
      _lastError = 'OIDC provider returned no authorization code. '
          'Check the provider logs for an "invalid redirect_uri" or '
          '"invalid client" error.';
      return null;
    }

    // Verify state matches
    if (state != _state) {
      debugPrint('[OIDC] State mismatch: expected=$_state, got=$state');
      _lastError = 'OIDC state mismatch — possible session expiry or '
          'cross-tab interference. Try again.';
      return null;
    }

    if (_serverUrl == null || _codeVerifier == null) {
      debugPrint('[OIDC] Missing server URL or code verifier');
      _lastError = 'OIDC flow state was lost between popup and callback.';
      return null;
    }

    // Call /auth/openid/callback with state + code + code_verifier
    final callbackUrl = '$_serverUrl/auth/openid/callback'
        '?state=${Uri.encodeComponent(_state!)}'
        '&code=${Uri.encodeComponent(code)}'
        '&code_verifier=${Uri.encodeComponent(_codeVerifier!)}';

    debugPrint('[OIDC] Calling callback: $callbackUrl');
    debugPrint('[OIDC] Sending ${_rawCookies.length} cookies');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      try {
        final request = await client.getUrl(Uri.parse(callbackUrl));
        request.followRedirects = false;
        _customHeaders.forEach(request.headers.set);
        request.headers.set('x-return-tokens', 'true');

        if (_rawCookies.isNotEmpty) {
          request.headers.set(HttpHeaders.cookieHeader, _cookieHeader);
        }

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        debugPrint('[OIDC] Callback response: ${response.statusCode}');
        debugPrint('[OIDC] Callback body length: ${body.length}');

        if (response.statusCode == 200) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          _cleanup();
          return data;
        } else {
          debugPrint('[OIDC] Callback error: $body');
          final preview = body.length > 200 ? '${body.substring(0, 200)}…' : body;
          _lastError = 'ABS callback returned HTTP ${response.statusCode}'
              '${preview.isNotEmpty ? ': $preview' : ''}';
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('[OIDC] Callback exception: $e');
      _lastError = 'ABS callback request failed: $e';
      return null;
    }
  }

  /// Clean up after flow completes or is cancelled.
  void _cleanup() {
    _codeVerifier = null;
    _codeChallenge = null;
    _state = null;
    _nonce = null;
    _rawCookies = [];
    _customHeaders = const {};
  }

  /// Cancel any in-progress flow.
  void cancel() => _cleanup();

  /// Fetch server status to check if OIDC is available.
  static Future<Map<String, dynamic>?> getServerAuthConfig(String serverUrl, {Map<String, String> customHeaders = const {}}) async {
    final url = serverUrl.endsWith('/') ? '${serverUrl}status' : '$serverUrl/status';
    try {
      final response = await http.get(Uri.parse(url), headers: customHeaders.isNotEmpty ? customHeaders : null)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[OIDC] Failed to fetch server status: $e');
    }
    return null;
  }

  /// Check if a server has OIDC enabled.
  static Future<OidcConfig?> checkOidcEnabled(String serverUrl, {Map<String, String> customHeaders = const {}}) async {
    final status = await getServerAuthConfig(serverUrl, customHeaders: customHeaders);
    if (status == null) return null;

    final authMethods = status['authMethods'] as List<dynamic>? ?? [];
    final hasOidc = authMethods.contains('openid');
    final authFormData = status['authFormData'] as Map<String, dynamic>? ?? {};
    final buttonText = authFormData['openIDButtonText'] as String? ?? 'Login with OpenID';

    return OidcConfig(
      enabled: hasOidc,
      buttonText: buttonText,
      hasLocalAuth: authMethods.contains('local'),
    );
  }

  /// The single sign-on providers a BookOrbit server offers.
  static Future<OidcConfig?> checkBookOrbitOidc(String serverUrl, {Map<String, String> customHeaders = const {}}) async {
    final options = await BookOrbitApiService.loginOptions(serverUrl, customHeaders: customHeaders);
    if (options == null) return null;
    final providers = [
      for (final p in options.oidcProviders)
        BookOrbitOidcProvider(
          slug: p['slug'] as String,
          displayName: '${p['displayName'] ?? p['slug']}',
          clientId: p['clientId'] as String,
          scopes: (p['scopes'] as String?)?.trim().isNotEmpty == true ? p['scopes'] as String : 'openid profile email',
        ),
    ];
    return OidcConfig(
      enabled: providers.isNotEmpty,
      buttonText: '',
      hasLocalAuth: options.passwordLogin,
      bookOrbitProviders: providers,
    );
  }
}

/// A BookOrbit single sign-on provider, from its public login options.
class BookOrbitOidcProvider {
  final String slug;
  final String displayName;
  final String clientId;
  final String scopes;

  const BookOrbitOidcProvider({
    required this.slug,
    required this.displayName,
    required this.clientId,
    required this.scopes,
  });
}

/// Configuration about what auth methods a server supports.
class OidcConfig {
  final bool enabled;
  final String buttonText;
  final bool hasLocalAuth;
  final List<BookOrbitOidcProvider> bookOrbitProviders;

  const OidcConfig({
    required this.enabled,
    required this.buttonText,
    required this.hasLocalAuth,
    this.bookOrbitProviders = const [],
  });
}
