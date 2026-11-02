import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';

/// Password and OpenID Connect sign-in settings, the same fields as the web's
/// Settings > Authentication page. Read with GET /api/auth-settings and saved
/// with PATCH /api/auth-settings.
class AdminAuthSettingsScreen extends StatefulWidget {
  const AdminAuthSettingsScreen({super.key});

  @override
  State<AdminAuthSettingsScreen> createState() => _AdminAuthSettingsScreenState();
}

class _AdminAuthSettingsScreenState extends State<AdminAuthSettingsScreen> {
  // The server's default ROUTER_BASE_PATH. The real one isn't exposed to apps.
  static const _defaultSubfolder = '/audiobookshelf';
  static const _absorbRedirect = 'absorb://oauth';
  static const _guideUrl =
      'https://audiobookshelf.org/docs/documentation/server-management/oidc-authentication';
  // Same checks the server and the web page apply.
  static final _redirectPattern = RegExp(r'^\w+://[\w.-]+(/[\w./-]*)*$', caseSensitive: false);
  static final _claimPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');

  Map<String, dynamic>? _settings;
  bool _loading = true;
  bool _saving = false;
  bool _populating = false;

  bool _showMessage = false;
  bool _localAuth = true;
  bool _openId = false;
  bool _autoLaunch = false;
  bool _autoRegister = false;
  bool _showSecret = false;
  // '' = do not match.
  String _matchExistingBy = '';
  String _subfolder = _defaultSubfolder;
  // A server that never saved a subfolder works out its own from the base
  // path, so only send one once it is set or picked here.
  bool _sendSubfolder = false;
  List<String> _redirectUris = [];
  List<String> _algorithms = [];

  final _message = TextEditingController();
  final _issuer = TextEditingController();
  final _authorizeUrl = TextEditingController();
  final _tokenUrl = TextEditingController();
  final _userInfoUrl = TextEditingController();
  final _jwksUrl = TextEditingController();
  final _logoutUrl = TextEditingController();
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();
  final _signingAlgorithm = TextEditingController();
  final _buttonText = TextEditingController();
  final _groupClaim = TextEditingController();
  final _permsClaim = TextEditingController();
  final _newRedirect = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _message, _issuer, _authorizeUrl, _tokenUrl, _userInfoUrl, _jwksUrl,
      _logoutUrl, _clientId, _clientSecret, _signingAlgorithm, _buttonText,
      _groupClaim, _permsClaim, _newRedirect,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiService;
    setState(() => _loading = true);
    final s = await api?.getAuthSettings();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _settings = s;
      if (s != null) _apply(s);
    });
  }

  void _apply(Map<String, dynamic> s) {
    String text(String key) => s[key]?.toString() ?? '';
    final methods = ((s['authActiveAuthMethods'] as List?) ?? const ['local']).map((e) => '$e').toList();
    _localAuth = methods.contains('local');
    _openId = methods.contains('openid');
    _message.text = text('authLoginCustomMessage');
    _showMessage = _message.text.trim().isNotEmpty;
    _issuer.text = text('authOpenIDIssuerURL');
    _authorizeUrl.text = text('authOpenIDAuthorizationURL');
    _tokenUrl.text = text('authOpenIDTokenURL');
    _userInfoUrl.text = text('authOpenIDUserInfoURL');
    _jwksUrl.text = text('authOpenIDJwksURL');
    _logoutUrl.text = text('authOpenIDLogoutURL');
    _clientId.text = text('authOpenIDClientID');
    _clientSecret.text = text('authOpenIDClientSecret');
    _signingAlgorithm.text = text('authOpenIDTokenSigningAlgorithm');
    _buttonText.text = text('authOpenIDButtonText');
    _autoLaunch = s['authOpenIDAutoLaunch'] == true;
    _autoRegister = s['authOpenIDAutoRegister'] == true;
    final match = text('authOpenIDMatchExistingBy');
    _matchExistingBy = match == 'email' || match == 'username' ? match : '';
    _redirectUris = ((s['authOpenIDMobileRedirectURIs'] as List?) ?? const []).map((e) => '$e').toList();
    _groupClaim.text = text('authOpenIDGroupClaim');
    _permsClaim.text = text('authOpenIDAdvancedPermsClaim');
    final subfolder = s['authOpenIDSubfolderForRedirectURLs'];
    _sendSubfolder = subfolder is String;
    _subfolder = subfolder is String ? subfolder : _defaultSubfolder;
  }

  void _toast(String message, {bool error = true}) => showOverlayToast(context, message,
      icon: error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded);

  Future<void> _autoPopulate() async {
    final l = AppLocalizations.of(context)!;
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    var issuer = _issuer.text.trim();
    if (issuer.endsWith('/')) issuer = issuer.substring(0, issuer.length - 1);
    const wellKnown = '/.well-known/openid-configuration';
    if (issuer.endsWith(wellKnown)) {
      issuer = issuer.substring(0, issuer.length - wellKnown.length);
      _issuer.text = issuer;
    }
    if (issuer.isEmpty) {
      _toast(l.authSetFieldRequired(l.authSetIssuerUrl));
      return;
    }
    setState(() => _populating = true);
    final r = await api.getOpenIdIssuerConfig(issuer);
    if (!mounted) return;
    final c = r.config;
    setState(() {
      _populating = false;
      if (c == null) return;
      void fill(TextEditingController field, String key) {
        final v = c[key];
        if (v is String && v.isNotEmpty) field.text = v;
      }
      fill(_issuer, 'issuer');
      fill(_authorizeUrl, 'authorization_endpoint');
      fill(_tokenUrl, 'token_endpoint');
      fill(_userInfoUrl, 'userinfo_endpoint');
      fill(_logoutUrl, 'end_session_endpoint');
      fill(_jwksUrl, 'jwks_uri');
      final algs = c['id_token_signing_alg_values_supported'];
      if (algs is List && algs.isNotEmpty) {
        _algorithms = algs.map((e) => '$e').toList();
        if (!_algorithms.contains(_signingAlgorithm.text.trim())) {
          _signingAlgorithm.text = _algorithms.first;
        }
      }
    });
    if (c == null) _toast(l.authSetIssuerFailed(r.error ?? ''));
  }

  void _addRedirect() {
    final l = AppLocalizations.of(context)!;
    final uri = _newRedirect.text.trim();
    if (uri.isEmpty) return;
    if (uri != '*' && !_redirectPattern.hasMatch(uri)) {
      _toast(l.authSetInvalidRedirectUri(uri));
      return;
    }
    setState(() {
      if (!_redirectUris.contains(uri)) _redirectUris = [..._redirectUris, uri];
      _newRedirect.clear();
    });
  }

  String? _validationError(AppLocalizations l) {
    if (!_localAuth && !_openId) return l.authSetNeedOneMethod;
    if (!_openId) return null;
    for (final (label, field) in [
      (l.authSetIssuerUrl, _issuer),
      (l.authSetAuthorizeUrl, _authorizeUrl),
      (l.authSetTokenUrl, _tokenUrl),
      (l.authSetUserinfoUrl, _userInfoUrl),
      (l.authSetJwksUrl, _jwksUrl),
      (l.authSetClientId, _clientId),
      (l.authSetClientSecret, _clientSecret),
      (l.authSetSigningAlgorithm, _signingAlgorithm),
    ]) {
      if (field.text.trim().isEmpty) return l.authSetFieldRequired(label);
    }
    if (_redirectUris.contains('*') && _redirectUris.length > 1) return l.authSetAsteriskAlone;
    for (final uri in _redirectUris) {
      if (uri != '*' && !_redirectPattern.hasMatch(uri)) return l.authSetInvalidRedirectUri(uri);
    }
    for (final (label, field) in [
      (l.authSetGroupClaim, _groupClaim),
      (l.authSetPermsClaim, _permsClaim),
    ]) {
      final claim = field.text.trim();
      if (claim.isNotEmpty && !_claimPattern.hasMatch(claim)) return l.authSetInvalidClaim(label);
    }
    return null;
  }

  Map<String, dynamic> _payload() {
    String? orNull(TextEditingController field) {
      final v = field.text.trim();
      return v.isEmpty ? null : v;
    }
    return {
      'authLoginCustomMessage': _showMessage ? orNull(_message) : null,
      'authActiveAuthMethods': [if (_localAuth) 'local', if (_openId) 'openid'],
      'authOpenIDIssuerURL': orNull(_issuer),
      'authOpenIDAuthorizationURL': orNull(_authorizeUrl),
      'authOpenIDTokenURL': orNull(_tokenUrl),
      'authOpenIDUserInfoURL': orNull(_userInfoUrl),
      'authOpenIDJwksURL': orNull(_jwksUrl),
      'authOpenIDLogoutURL': orNull(_logoutUrl),
      'authOpenIDClientID': orNull(_clientId),
      'authOpenIDClientSecret': orNull(_clientSecret),
      'authOpenIDTokenSigningAlgorithm': orNull(_signingAlgorithm),
      'authOpenIDButtonText': orNull(_buttonText),
      'authOpenIDAutoLaunch': _autoLaunch,
      'authOpenIDAutoRegister': _autoRegister,
      'authOpenIDMatchExistingBy': _matchExistingBy.isEmpty ? null : _matchExistingBy,
      'authOpenIDMobileRedirectURIs': _redirectUris,
      'authOpenIDGroupClaim': _groupClaim.text.trim(),
      'authOpenIDAdvancedPermsClaim': _permsClaim.text.trim(),
      if (_sendSubfolder) 'authOpenIDSubfolderForRedirectURLs': _subfolder,
    };
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final error = _validationError(l);
    if (error != null) {
      _toast(error);
      return;
    }
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    setState(() => _saving = true);
    final r = await api.updateAuthSettings(_payload());
    if (!mounted) return;
    setState(() => _saving = false);
    if (r == null) {
      _toast(l.srvSaveFailed);
      return;
    }
    final serverSettings = r['serverSettings'];
    if (serverSettings is Map<String, dynamic>) auth.applyServerSettings(serverSettings);
    _toast(r['updated'] == true ? l.srvSaved : l.authSetNoChanges, error: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.adminAuthentication, padding: EdgeInsets.zero)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _settings == null
                    ? _loadFailed(cs, tt, l)
                    : _form(cs, tt, l),
          ),
        ]),
      ),
    );
  }

  Widget _loadFailed(ColorScheme cs, TextTheme tt, AppLocalizations l) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.authSetLoadFailed, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: Text(l.retry)),
        ]),
      );

  Widget _form(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final subfolderOptions = [
      '',
      _defaultSubfolder,
      if (_subfolder.isNotEmpty && _subfolder != _defaultSubfolder) _subfolder,
    ];
    final sample = _settings?['authOpenIDSamplePermissions']?.toString() ?? '';
    final mono = tt.bodySmall?.copyWith(fontFamily: 'monospace', color: cs.onSurface);

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        _card(cs, [
          _switch(tt, l.authSetCustomMessage, _showMessage, (v) => setState(() => _showMessage = v)),
          if (_showMessage) ...[
            _field(_message, l.authSetMessage, maxLines: 5),
            const SizedBox(height: 4),
          ],
        ]),
        const SizedBox(height: 12),
        _card(cs, [
          _switch(tt, l.authSetPasswordAuth, _localAuth, (v) => setState(() => _localAuth = v)),
        ]),
        const SizedBox(height: 12),
        _card(cs, [
          Row(children: [
            Expanded(
              child: _switch(tt, l.authSetOpenId, _openId, (v) => setState(() => _openId = v)),
            ),
            IconButton(
              tooltip: l.authSetGuide,
              icon: Icon(Icons.help_outline_rounded, size: 20, color: cs.onSurfaceVariant),
              onPressed: () => launchUrl(Uri.parse(_guideUrl), mode: LaunchMode.externalApplication),
            ),
          ]),
          if (_openId) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: _field(_issuer, l.authSetIssuerUrl, url: true)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: OutlinedButton.icon(
                  onPressed: _populating || _saving ? null : _autoPopulate,
                  icon: _populating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_fix_high_rounded, size: 16),
                  label: Text(l.authSetAutoPopulate),
                ),
              ),
            ]),
            _field(_authorizeUrl, l.authSetAuthorizeUrl, url: true),
            _field(_tokenUrl, l.authSetTokenUrl, url: true),
            _field(_userInfoUrl, l.authSetUserinfoUrl, url: true),
            _field(_jwksUrl, l.authSetJwksUrl, url: true),
            _field(_logoutUrl, l.authSetLogoutUrl, url: true),
            _field(_clientId, l.authSetClientId),
            _field(_clientSecret, l.authSetClientSecret,
                obscure: !_showSecret,
                suffix: IconButton(
                  icon: Icon(_showSecret ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _showSecret = !_showSecret),
                )),
            if (_algorithms.isNotEmpty)
              _dropdown<String>(tt, l.authSetSigningAlgorithm, _signingAlgorithm.text.trim(), _algorithms,
                  (v) => setState(() => _signingAlgorithm.text = v))
            else
              _field(_signingAlgorithm, l.authSetSigningAlgorithm),
            const SizedBox(height: 16),
            Text(l.authSetRedirectUris, style: tt.bodyMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final uri in _redirectUris)
                Chip(
                  label: Text(uri),
                  onDeleted: _saving
                      ? null
                      : () => setState(() => _redirectUris = _redirectUris.where((u) => u != uri).toList()),
                ),
              if (!_redirectUris.contains(_absorbRedirect) && !_redirectUris.contains('*'))
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l.authSetAddAbsorbRedirect),
                  onPressed: _saving ? null : () => setState(() => _redirectUris = [..._redirectUris, _absorbRedirect]),
                ),
            ]),
            Row(children: [
              Expanded(
                child: _field(_newRedirect, l.authSetAddRedirectUri, hint: 'app://oauth', onSubmitted: (_) => _addRedirect()),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _saving ? null : _addRedirect, icon: const Icon(Icons.add_rounded)),
            ]),
            _info(cs, tt, l.authSetRedirectUrisInfo),
            const SizedBox(height: 8),
            _dropdown<String>(tt, l.authSetSubfolder, _subfolder, subfolderOptions,
                (v) => setState(() {
                      _subfolder = v;
                      _sendSubfolder = true;
                    }),
                labelFor: (v) => v.isEmpty ? l.authSetSubfolderNone : v),
            _info(cs, tt, l.authSetWebRedirectInfo),
            const SizedBox(height: 6),
            SelectableText(
              'https://<your.server.com>$_subfolder/auth/openid/callback\n'
              'https://<your.server.com>$_subfolder/auth/openid/mobile-redirect',
              style: mono,
            ),
            _field(_buttonText, l.authSetButtonText),
            const SizedBox(height: 8),
            _dropdown<String>(tt, l.authSetMatchExisting, _matchExistingBy, const ['', 'email', 'username'],
                (v) => setState(() => _matchExistingBy = v),
                labelFor: (v) => switch (v) {
                      'email' => l.authSetMatchEmail,
                      'username' => l.authSetMatchUsername,
                      _ => l.authSetMatchNone,
                    }),
            _info(cs, tt, l.authSetMatchExistingInfo),
            const SizedBox(height: 8),
            _switch(tt, l.authSetAutoLaunch, _autoLaunch, (v) => setState(() => _autoLaunch = v),
                subtitle: l.authSetAutoLaunchInfo),
            _switch(tt, l.authSetAutoRegister, _autoRegister, (v) => setState(() => _autoRegister = v),
                subtitle: l.authSetAutoRegisterInfo),
            const SizedBox(height: 8),
            _info(cs, tt, l.authSetClaimsInfo),
            _field(_groupClaim, l.authSetGroupClaim, hint: 'groups'),
            _info(cs, tt, l.authSetGroupClaimInfo),
            _field(_permsClaim, l.authSetPermsClaim, hint: 'abspermissions'),
            _info(cs, tt, l.authSetPermsClaimInfo),
            if (sample.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(sample, style: mono),
              ),
            ],
            const SizedBox(height: 4),
          ],
        ]),
        const SizedBox(height: 16),
        if (_openId)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.withValues(alpha: 0.9)),
                const SizedBox(width: 10),
                Expanded(child: Text(l.authSetRestartNote,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)))),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(l.srvSave),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(ColorScheme cs, List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      );

  Widget _switch(TextTheme tt, String label, bool value, ValueChanged<bool> onChanged, {String? subtitle}) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: tt.bodyMedium),
        subtitle: subtitle == null ? null : Text(subtitle, style: tt.bodySmall),
        value: value,
        onChanged: _saving ? null : onChanged,
      );

  Widget _field(TextEditingController controller, String label,
          {String? hint, bool url = false, bool obscure = false, int maxLines = 1, Widget? suffix,
          ValueChanged<String>? onSubmitted}) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: controller,
          enabled: !_saving,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: false,
          maxLines: obscure ? 1 : maxLines,
          minLines: 1,
          keyboardType: maxLines > 1 ? TextInputType.multiline : (url ? TextInputType.url : TextInputType.text),
          onSubmitted: onSubmitted,
          decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: suffix),
        ),
      );

  Widget _info(ColorScheme cs, TextTheme tt, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      );

  Widget _dropdown<T>(TextTheme tt, String label, T value, List<T> options, ValueChanged<T> onChanged,
          {String Function(T)? labelFor}) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          Expanded(child: Text(label, style: tt.bodyMedium)),
          DropdownButton<T>(
            value: value,
            borderRadius: BorderRadius.circular(12),
            underline: const SizedBox.shrink(),
            items: options
                .map((o) => DropdownMenuItem<T>(value: o, child: Text(labelFor?.call(o) ?? '$o')))
                .toList(),
            onChanged: _saving
                ? null
                : (v) {
                    if (v != null) onChanged(v);
                  },
          ),
        ]),
      );
}
