import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/oidc_service.dart';
import 'overlay_toast.dart';

/// Hooks the BookOrbit service up to ask for, and mention, the sign-in it
/// uses for what an API key isn't allowed to do.
void wireBoPasswordSession() {
  BookOrbitApiService.askForPasswordSession = _ask;
  BookOrbitApiService.onPasswordSessionUsed = (via) {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final l = AppLocalizations.of(context)!;
    showOverlayToast(
      context,
      via == null ? l.boPasswordSessionUsed : l.boPasswordSessionUsedWith(via),
      icon: Icons.lock_open_rounded,
    );
  };
}

Future<bool> _ask(BookOrbitApiService api) async {
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return false;
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _PasswordSessionDialog(api: api),
  );
  return saved ?? false;
}

class _PasswordSessionDialog extends StatefulWidget {
  final BookOrbitApiService api;
  const _PasswordSessionDialog({required this.api});

  @override
  State<_PasswordSessionDialog> createState() => _PasswordSessionDialogState();
}

class _PasswordSessionDialogState extends State<_PasswordSessionDialog> {
  final _password = TextEditingController();
  OidcConfig? _options;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    OidcService.checkBookOrbitOidc(widget.api.baseUrl, customHeaders: widget.api.customHeaders).then((o) {
      if (mounted) setState(() {
        _options = o;
        _loading = false;
      });
    }).catchError((Object _) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// Keeps the sign-in, but only if it is the account already signed in:
  /// anything else would act as someone else under this account's name.
  Future<void> _keep(Map<String, dynamic>? login, {String? via}) async {
    final l = AppLocalizations.of(context)!;
    final user = login?['user'] as Map<String, dynamic>?;
    final access = user?['accessToken'] as String?;
    if (user == null || access == null) {
      setState(() => _error = l.boPasswordSessionFailed);
      return;
    }
    final me = context.read<AuthProvider>().userId;
    if (me != null && '${user['id']}' != me) {
      setState(() => _error = l.boPasswordSessionOtherAccount);
      return;
    }
    await widget.api.savePasswordSession(
      access: access,
      refresh: user['refreshToken'] as String?,
      via: via,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _signInWithPassword() async {
    final l = AppLocalizations.of(context)!;
    final username = context.read<AuthProvider>().username ?? '';
    if (_password.text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final (login, status) = await BookOrbitApiService.signIn(
      serverUrl: widget.api.baseUrl,
      username: username,
      password: _password.text,
      customHeaders: widget.api.customHeaders,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (status == 200) {
      await _keep(login);
    } else {
      setState(() => _error = status == 401 ? l.boPasswordSessionWrongPassword : l.boPasswordSessionFailed);
    }
  }

  Future<void> _signInWith(BookOrbitOidcProvider provider) async {
    final l = AppLocalizations.of(context)!;
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final oidc = OidcService();
    final callback = await oidc.startBookOrbitLogin(
      widget.api.baseUrl,
      provider,
      customHeaders: widget.api.customHeaders,
    );
    final login = callback == null ? null : await oidc.handleBookOrbitCallback(callback);
    if (!mounted) return;
    setState(() => _busy = false);
    if (login == null) {
      if (!oidc.lastWasUserCancel) setState(() => _error = oidc.lastError ?? l.boPasswordSessionFailed);
      return;
    }
    await _keep(login, via: provider.displayName);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = _options;
    final password = options?.hasLocalAuth ?? true;
    final providers = options?.bookOrbitProviders ?? const <BookOrbitOidcProvider>[];
    return AlertDialog(
      title: Text(l.boPasswordSessionTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.boPasswordSessionBody),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
            else ...[
              if (password)
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofocus: true,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(labelText: l.loginPassword),
                  onSubmitted: (_) => _signInWithPassword(),
                ),
              for (final p in providers) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _signInWith(p),
                  child: Text(l.boPasswordSessionWith(p.displayName)),
                ),
              ],
              if (!password && providers.isEmpty) Text(l.boPasswordSessionNoMethods),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        if (!_loading && password)
          FilledButton(
            onPressed: _busy ? null : _signInWithPassword,
            child: Text(l.boPasswordSessionSignIn),
          ),
      ],
    );
  }
}
