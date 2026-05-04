import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/backup_service.dart';
import '../services/oidc_service.dart';
import '../services/user_account_service.dart';
import '../widgets/absorb_wave_icon.dart';
import '../services/audio_player_service.dart';
import '../main.dart' show applyTrustAllCerts, oledNotifier;
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _usernameFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureApiKey = true;
  bool _isConnecting = false;
  String _protocol = 'https://';

  // Server validation state
  bool _serverValid = false;
  bool _serverChecking = false;
  String? _serverError;
  Timer? _debounce;

  // Login error
  String? _loginError;

  // OIDC state
  OidcConfig? _oidcConfig;
  bool _isOidcLoading = false;

  // Custom headers (advanced)
  bool _showAdvanced = false;
  bool _trustAllCerts = false;
  final List<(TextEditingController, TextEditingController)> _headerControllers = [];

  // App version
  String _appVersion = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _serverController.addListener(_onServerChanged);
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = 'v${info.version}');
    } catch (_) {}
    try {
      final trust = await PlayerSettings.getTrustAllCerts();
      if (mounted) setState(() => _trustAllCerts = trust);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animController.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    _usernameFocus.dispose();
    for (final (k, v) in _headerControllers) { k.dispose(); v.dispose(); }
    OidcService().cancel();
    super.dispose();
  }

  String _lastValidatedServer = '';

  /// Re-trigger server validation when custom headers change.
  void _revalidateServer() {
    if (_serverController.text.trim().isEmpty) return;
    _lastValidatedServer = ''; // Force re-check
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () => _checkServer());
  }

  void _onServerChanged() {
    final text = _serverController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _serverValid = false;
        _serverChecking = false;
        _serverError = null;
        _lastValidatedServer = '';
      });
      _debounce?.cancel();
      return;
    }

    // Only invalidate if the server text actually changed from what we validated
    final cleanUrl = text.replaceAll(RegExp(r'^https?://'), '');
    final fullUrl = '$_protocol$cleanUrl';
    if (fullUrl != _lastValidatedServer) {
      setState(() {
        _serverValid = false;
        _serverChecking = true;
        _serverError = null;
      });
    } else {
      // Same server, just re-checking — keep fields visible
      setState(() {
        _serverChecking = true;
        _serverError = null;
      });
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () => _checkServer());
  }

  Future<void> _checkServer() async {
    final text = _serverController.text.trim();
    if (text.isEmpty) return;

    final cleanUrl = text.replaceAll(RegExp(r'^https?://'), '');
    final fullUrl = '$_protocol$cleanUrl';

    try {
      // Build custom headers for ping
      final headers = <String, String>{};
      for (final (keyCtrl, valCtrl) in _headerControllers) {
        final k = keyCtrl.text.trim();
        final v = valCtrl.text.trim();
        if (k.isNotEmpty && v.isNotEmpty) headers[k] = v;
      }

      final ok = await ApiService.pingServer(fullUrl, customHeaders: headers);
      if (!mounted) return;
      if (_serverController.text.trim() != text) return;

      setState(() {
        _serverChecking = false;
        _serverValid = ok;
        _serverError = ok ? null : AppLocalizations.of(context)!.loginCouldNotReachServer;
        if (ok) {
          _lastValidatedServer = fullUrl;
        } else {
          _oidcConfig = null;
          _lastValidatedServer = '';
        }
      });

      if (ok) {
        // Also check if OIDC is available
        OidcService.checkOidcEnabled(fullUrl).then((config) {
          if (mounted && _serverController.text.trim() == text) {
            setState(() => _oidcConfig = config);
          }
        });

        // Don't auto-focus — user may still be typing IP:port
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serverChecking = false;
        _serverValid = false;
        _serverError = AppLocalizations.of(context)!.loginCouldNotReachServer;
        _oidcConfig = null;
      });
    }
  }

  Future<void> _handleLogin() async {
    final apiKey = _apiKeyController.text.trim();

    // Skip form validation when an API key is supplied — the username
    // field's required-validator would otherwise block the submit.
    if (apiKey.isEmpty && !_formKey.currentState!.validate()) return;

    // Validate server first if not yet checked
    if (!_serverValid) {
      await _checkServer();
      if (!_serverValid) {
        setState(() => _loginError = _serverError ?? AppLocalizations.of(context)!.loginCouldNotReachServer);
        return;
      }
    }

    setState(() {
      _isConnecting = true;
      _loginError = null;
    });

    final auth = context.read<AuthProvider>();
    final serverText = _serverController.text.trim();
    final cleanUrl = serverText.replaceAll(RegExp(r'^https?://'), '');
    final fullUrl = '$_protocol$cleanUrl';

    // Build custom headers map
    final headers = <String, String>{};
    for (final (keyCtrl, valCtrl) in _headerControllers) {
      final k = keyCtrl.text.trim();
      final v = valCtrl.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) headers[k] = v;
    }

    final success = apiKey.isNotEmpty
        ? await auth.loginWithApiKey(
            serverUrl: fullUrl,
            apiKey: apiKey,
            customHeaders: headers,
            l: AppLocalizations.of(context),
          )
        : await auth.login(
            serverUrl: fullUrl,
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            customHeaders: headers,
            l: AppLocalizations.of(context),
          );

    if (mounted) {
      setState(() => _isConnecting = false);

      if (!success) {
        setState(() {
          _loginError = auth.errorMessage ?? AppLocalizations.of(context)!.loginFailed;
        });
      } else {
        TextInput.finishAutofillContext();
        FocusManager.instance.primaryFocus?.unfocus();
        if (Navigator.of(context).canPop()) {
          // If pushed as a route (e.g. Add Account), pop back
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _handleOidcLogin() async {
    if (!_serverValid) return;

    setState(() {
      _isOidcLoading = true;
      _loginError = null;
    });

    final serverText = _serverController.text.trim();
    final cleanUrl = serverText.replaceAll(RegExp(r'^https?://'), '');
    final fullUrl = '$_protocol$cleanUrl';

    final oidc = OidcService();
    final callbackUri = await oidc.startLogin(fullUrl);
    if (callbackUri == null) {
      if (!mounted) return;
      // Quiet path: user just dismissed the popup. Don't surface an error.
      if (oidc.lastWasUserCancel) {
        setState(() => _isOidcLoading = false);
        return;
      }
      final base = AppLocalizations.of(context)!.loginSsoFailed;
      final detail = oidc.lastError;
      setState(() {
        _isOidcLoading = false;
        _loginError = detail != null ? '$base\n\n$detail' : base;
      });
      return;
    }

    final result = await oidc.handleCallback(callbackUri);
    if (result != null && mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      final auth = context.read<AuthProvider>();
      final success = await auth.loginWithOidc(
        serverUrl: fullUrl,
        result: result,
        l: AppLocalizations.of(context),
      );
      if (mounted) {
        setState(() => _isOidcLoading = false);
        if (!success) {
          setState(() => _loginError = auth.errorMessage ?? AppLocalizations.of(context)!.loginSsoFailed);
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } else if (mounted) {
      final base = AppLocalizations.of(context)!.loginSsoAuthFailed;
      final detail = oidc.lastError;
      setState(() {
        _isOidcLoading = false;
        _loginError = detail != null ? '$base\n\n$detail' : base;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: oledNotifier.value ? null : BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.4, 0.7, 1.0],
            colors: [
              cs.primary.withValues(alpha: 0.15),
              cs.primary.withValues(alpha: 0.05),
              cs.surface,
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo + Tagline ──
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        // Wave icon with glow
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.3),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: AbsorbWaveIcon(
                                size: 44,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          l.appTitle,
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w200,
                            color: cs.onSurface,
                            letterSpacing: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.loginTagline,
                          style: tt.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Glass form card ──
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(_slideAnim),
                    child: FadeTransition(
                      opacity: _slideAnim,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section label
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                                    child: Text(
                                      l.loginConnectToServer,
                                      style: tt.titleSmall?.copyWith(
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // Server URL
                                  _buildInputField(
                                    controller: _serverController,
                                    label: l.loginServerAddress,
                                    hint: l.loginServerHint,
                                    helperText: l.loginServerHelper,
                                    keyboardType: TextInputType.url,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      if (!_serverValid && !_serverChecking) {
                                        _checkServer().then((_) {
                                          if (mounted && _serverValid) _usernameFocus.requestFocus();
                                        });
                                      } else if (_serverValid) {
                                        _usernameFocus.requestFocus();
                                      }
                                    },
                                    cs: cs,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _protocol,
                                          isDense: true,
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'https://',
                                              child: Text('https://'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'http://',
                                              child: Text('http://'),
                                            ),
                                          ],
                                          onChanged: (v) {
                                            if (v != null) {
                                              setState(() {
                                                _protocol = v;
                                                _serverValid = false;
                                              });
                                              _onServerChanged();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    suffixIcon: _serverChecking
                                        ? const Padding(
                                            padding: EdgeInsets.all(14),
                                            child: SizedBox(
                                              width: 18, height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : _serverValid
                                            ? Icon(Icons.check_circle_rounded,
                                                color: Colors.green.shade400, size: 22)
                                            : _serverError != null
                                                ? Icon(Icons.error_outline_rounded,
                                                    color: cs.error, size: 22)
                                                : null,
                                    borderColor: _serverValid
                                        ? Colors.green.shade400.withValues(alpha: 0.4)
                                        : _serverError != null
                                            ? cs.error.withValues(alpha: 0.4)
                                            : null,
                                    errorText: _serverError,
                                  ),

                                  // Advanced: Custom Headers — must be before server validation
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                                    child: Row(
                                      children: [
                                        Icon(_showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                          size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                        const SizedBox(width: 4),
                                        Text(l.loginAdvanced, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                                      ],
                                    ),
                                  ),
                                  if (_showAdvanced) ...[
                                    const SizedBox(height: 8),
                                    Text(l.loginCustomHttpHeaders, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                                    const SizedBox(height: 4),
                                    Text(l.loginCustomHeadersDescription,
                                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                                    const SizedBox(height: 8),
                                    ..._headerControllers.asMap().entries.map((entry) {
                                      final i = entry.key;
                                      final (keyCtrl, valCtrl) = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller: keyCtrl,
                                                style: TextStyle(fontSize: 13, color: cs.onSurface),
                                                onChanged: (_) => _revalidateServer(),
                                                decoration: InputDecoration(
                                                  hintText: l.loginHeaderName,
                                                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 13),
                                                  filled: true,
                                                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 3,
                                              child: TextField(
                                                controller: valCtrl,
                                                style: TextStyle(fontSize: 13, color: cs.onSurface),
                                                onChanged: (_) => _revalidateServer(),
                                                decoration: InputDecoration(
                                                  hintText: l.loginHeaderValue,
                                                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 13),
                                                  filled: true,
                                                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _headerControllers[i].$1.dispose();
                                                  _headerControllers[i].$2.dispose();
                                                  _headerControllers.removeAt(i);
                                                });
                                                _revalidateServer();
                                              },
                                              child: Icon(Icons.close_rounded, size: 18, color: cs.error.withValues(alpha: 0.6)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _headerControllers.add((TextEditingController(), TextEditingController()));
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_rounded, size: 16, color: cs.primary),
                                            const SizedBox(width: 4),
                                            Text(l.loginAddHeader, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(height: 1),
                                    const SizedBox(height: 4),
                                    Text(l.loginSelfSignedCertificates, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l.loginTrustAllCertificates,
                                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                                          ),
                                        ),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: _trustAllCerts,
                                            onChanged: (v) async {
                                              setState(() => _trustAllCerts = v);
                                              await PlayerSettings.setTrustAllCerts(v);
                                              applyTrustAllCerts(v);
                                              _revalidateServer();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Text(l.loginApiKey, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                                    const SizedBox(height: 4),
                                    Text(l.loginApiKeyDescription,
                                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _apiKeyController,
                                      obscureText: _obscureApiKey,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: l.loginApiKey,
                                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 13),
                                        filled: true,
                                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        prefixIcon: Icon(Icons.vpn_key_rounded, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureApiKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            size: 18,
                                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                                          ),
                                          onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // SSO / OIDC button — only shown when server supports it
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: _serverValid && _oidcConfig != null && _oidcConfig!.enabled
                                        ? _buildOidcButton(cs, tt)
                                        : const SizedBox.shrink(),
                                  ),

                                  // Credentials — always visible
                                  _buildCredentialFields(cs, tt),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Version + Restore pill ──
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          _appVersion,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ActionChip(
                          avatar: Icon(Icons.restore_rounded, size: 16,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                          label: Text(l.loginRestoreFromBackup,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            )),
                          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: _restoreFromBackup,
                        ),
                      ],
                    ),
                  ),

                  // ── Saved accounts quick-switch ──
                  _buildSavedAccounts(cs, tt),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSavedAccounts(ColorScheme cs, TextTheme tt) {
    final accounts = UserAccountService().accounts;
    if (accounts.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.15))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(l.loginSavedAccounts,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                ),
                Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.15))),
              ],
            ),
            const SizedBox(height: 12),
            ...accounts.map((account) {
              final shortUrl = account.serverUrl
                  .replaceAll(RegExp(r'^https?://'), '')
                  .replaceAll(RegExp(r'/+$'), '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: cs.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _quickSwitch(account),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: cs.primary.withValues(alpha: 0.15),
                            child: Text(
                              account.username.isNotEmpty
                                  ? account.username[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(account.username,
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface)),
                                Text(shortUrl,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreFromBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (!data.containsKey('version')) {
        if (mounted) {
          final l = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.loginInvalidBackupFile)),
          );
        }
        return;
      }

      final accounts = data['accounts'] as List<dynamic>?;
      final accountCount = accounts?.length ?? 0;
      final hasAccounts = accountCount > 0;

      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.loginRestoreBackupTitle),
          content: Text(hasAccounts
              ? l.loginRestoreBackupWithAccounts(accountCount)
              : l.loginRestoreBackupNoAccounts),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.loginRestore),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await BackupService.importSettings(data);

      // Auto-login with the first restored account
      if (hasAccounts && mounted) {
        final restoredAccounts = UserAccountService().accounts;
        if (restoredAccounts.isNotEmpty) {
          final auth = context.read<AuthProvider>();
          await auth.switchToAccount(restoredAccounts.first);

          if (mounted) {
            final l2 = AppLocalizations.of(context)!;
            if (auth.isAuthenticated && auth.serverReachable) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l2.loginRestoredAndSignedIn(restoredAccounts.first.username)),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            } else {
              // Token expired — accounts are saved but need re-auth
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l2.loginSessionExpired),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
              setState(() {}); // Refresh to show saved accounts list
            }
          }
        }
      } else if (mounted) {
        final l3 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l3.loginSettingsRestored),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        final l4 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l4.loginRestoreFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _quickSwitch(SavedAccount account) async {
    setState(() => _isConnecting = true);

    final auth = context.read<AuthProvider>();
    await auth.switchToAccount(account);

    if (mounted) {
      setState(() => _isConnecting = false);
      if (auth.isAuthenticated && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      // If this is the root login screen, AuthGate will react to the state change
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required ColorScheme cs,
    String? hint,
    String? helperText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? borderColor,
    String? errorText,
    bool obscureText = false,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    Iterable<String>? autofillHints,
  }) {
    final isUrl = keyboardType == TextInputType.url;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autocorrect: !isUrl,
      enableSuggestions: !isUrl,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11),
        helperMaxLines: 2,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: borderColor ?? cs.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.6), width: 1.5),
        ),
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildOidcButton(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isConnecting || _isOidcLoading ? null : _handleOidcLogin,
            icon: _isOidcLoading
                ? SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                  )
                : Icon(Icons.login_rounded, size: 20, color: cs.primary),
            label: Text(
              _isOidcLoading ? l.loginWaitingForSso : _oidcConfig!.buttonText,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.loginRedirectUri,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(l.loginOrSignInManually, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
            ),
            Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.2))),
          ],
        ),
      ],
    );
  }

  Widget _buildCredentialFields(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    final usingApiKey = _apiKeyController.text.trim().isNotEmpty;
    return AutofillGroup(
      child: Column(
      children: [
        const SizedBox(height: 16),

        // Login error message
        if (_loginError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _loginError!,
                      style: tt.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (!usingApiKey) ...[
          // Username
          _buildInputField(
            controller: _usernameController,
            focusNode: _usernameFocus,
            label: l.loginUsername,
            cs: cs,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            prefixIcon: Icon(Icons.person_outline_rounded, size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l.loginUsernameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          _buildInputField(
            controller: _passwordController,
            label: l.loginPassword,
            cs: cs,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _handleLogin(),
            prefixIcon: Icon(Icons.lock_outline_rounded, size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            // No validator — ABS allows passwordless accounts
          ),
        ],
        const SizedBox(height: 24),

        // Sign In button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _isConnecting || _isOidcLoading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isConnecting
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(
                      l.loginSignIn,
                      key: const ValueKey('text'),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimary,
                      ),
                    ),
            ),
          ),
        ),


      ],
      ),
    );
  }
}
