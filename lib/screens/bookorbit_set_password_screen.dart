import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/server_backend.dart';

/// Picks a new password for a BookOrbit account, then signs in with it.
/// Pops true once signed in.
class BookOrbitSetPasswordScreen extends StatefulWidget {
  final String serverUrl;
  final Map<String, String> customHeaders;

  /// Asked for when null.
  final String? username;

  /// The token from a password link.
  final String? token;

  /// The password the account was created with, when there's no link.
  final String? currentPassword;

  const BookOrbitSetPasswordScreen.fromLink({
    super.key,
    required this.serverUrl,
    required String this.token,
    this.username,
    this.customHeaders = const {},
  }) : currentPassword = null;

  const BookOrbitSetPasswordScreen.replaceStarting({
    super.key,
    required this.serverUrl,
    required String this.username,
    required String this.currentPassword,
    this.customHeaders = const {},
  }) : token = null;

  @override
  State<BookOrbitSetPasswordScreen> createState() => _BookOrbitSetPasswordScreenState();
}

class _BookOrbitSetPasswordScreenState extends State<BookOrbitSetPasswordScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  // Once BookOrbit takes the new password the link is used up, so a retry
  // only signs in again.
  bool _passwordSet = false;

  bool get _fromLink => widget.token != null;

  String get _serverLabel {
    final uri = Uri.tryParse(widget.serverUrl);
    if (uri == null || uri.host.isEmpty) return widget.serverUrl;
    return [
      uri.host,
      if (uri.hasPort) ':${uri.port}',
      if (uri.path.isNotEmpty && uri.path != '/') uri.path,
    ].join();
  }

  @override
  void initState() {
    super.initState();
    _username.text = widget.username ?? '';
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final username = _username.text.trim();
    if (username.isEmpty || _password.text.isEmpty || _confirm.text.isEmpty) {
      setState(() => _error = l.passwordFieldsRequired);
      return;
    }
    if (!_passwordSet) {
      if (_password.text != _confirm.text) {
        setState(() => _error = l.passwordsDoNotMatch);
        return;
      }
      if (!BookOrbitApiService.passwordAcceptable(_password.text)) {
        setState(() => _error = l.boPasswordRules);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    if (!_passwordSet) {
      final r = _fromLink
          ? await BookOrbitApiService.setPasswordFromLink(
              serverUrl: widget.serverUrl,
              token: widget.token!,
              newPassword: _password.text,
              customHeaders: widget.customHeaders,
            )
          : await BookOrbitApiService.replaceStartingPassword(
              serverUrl: widget.serverUrl,
              username: username,
              currentPassword: widget.currentPassword!,
              newPassword: _password.text,
              customHeaders: widget.customHeaders,
            );
      if (!mounted) return;
      if (!r.ok) {
        setState(() {
          _busy = false;
          _error = _describe(l, r.status, r.message);
        });
        return;
      }
      _passwordSet = true;
    }

    final auth = context.read<AuthProvider>();
    final signedIn = await auth.login(
      serverUrl: widget.serverUrl,
      username: username,
      password: _password.text,
      customHeaders: widget.customHeaders,
      backend: ServerBackend.bookorbit,
      l: l,
    );
    if (!mounted) return;
    if (signedIn) {
      TextInput.finishAutofillContext();
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = l.boPasswordSetSignInFailed(auth.errorMessage ?? l.loginFailed);
    });
  }

  String _describe(AppLocalizations l, int status, String? message) {
    if (status == 0) return l.authCannotReachServer(_serverLabel);
    if (_fromLink && status == 400 && (message ?? '').contains('reset token')) {
      return l.boPasswordLinkExpired;
    }
    if (!_fromLink && status == 401) return l.authInvalidUsernameOrPassword;
    return message ?? l.passwordChangeFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = widget.username;
    return Scaffold(
      appBar: AppBar(title: Text(l.boSetPasswordTitle)),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              !_fromLink
                  ? l.boSetPasswordStartingBody
                  : name == null
                      ? l.boSetPasswordLinkBodyNoName(_serverLabel)
                      : l.boSetPasswordLinkBody(name, _serverLabel),
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (_fromLink) ...[
              const SizedBox(height: 8),
              Text(l.boSetPasswordTrust, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 20),
            TextField(
              key: const Key('boSetPasswordUsername'),
              controller: _username,
              readOnly: name != null,
              enabled: !_busy && !_passwordSet,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(labelText: l.loginUsername),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('boSetPasswordNew'),
              controller: _password,
              enabled: !_busy && !_passwordSet,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l.newPassword,
                helperText: l.boPasswordRules,
                helperMaxLines: 3,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('boSetPasswordConfirm'),
              controller: _confirm,
              enabled: !_busy && !_passwordSet,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(labelText: l.confirmNewPassword),
              onSubmitted: (_) => _busy ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: tt.bodyMedium?.copyWith(color: cs.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('boSetPasswordSubmit'),
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login_rounded),
              label: Text(_passwordSet ? l.loginSignIn : l.boSetPasswordSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
