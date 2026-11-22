import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/server_backend.dart';
import '../utils/server_url.dart';
import 'tv_focusable.dart';
import 'tv_text_field.dart';

/// Signing in on the TV itself, for when no phone is handy: the server,
/// which kind it is, and the account, each typed with the TV's keyboard.
class TvLoginScreen extends StatefulWidget {
  const TvLoginScreen({super.key});

  @override
  State<TvLoginScreen> createState() => _TvLoginScreenState();
}

class _TvLoginScreenState extends State<TvLoginScreen> {
  final _server = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  ServerBackend _backend = ServerBackend.audiobookshelf;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _server.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l = AppLocalizations.of(context)!;
    if (_server.text.trim().isEmpty || _username.text.trim().isEmpty) {
      setState(() => _error = l.tvLoginFillIn);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final serverUrl = await _withScheme(_server.text.trim());
    if (!mounted) return;
    final ok = await auth.login(
      serverUrl: serverUrl,
      username: _username.text.trim(),
      password: _password.text,
      backend: _backend,
      l: l,
    );
    if (!mounted) return;
    if (ok) {
      // Back to the TV's home, even when this was the account already in use.
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      _busy = false;
      _error = auth.errorMessage ?? l.loginFailed;
    });
  }

  /// The address as typed when it says http or https; otherwise https if
  /// the server answers there (a domain behind a proxy), else http (a
  /// server at home by its number).
  Future<String> _withScheme(String typed) async {
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(typed)) return normalizeServerUrl(typed);
    final bare = normalizeServerUrl(typed).replaceFirst(RegExp(r'^http://'), '');
    final secure = 'https://$bare';
    if (await ApiService.pingServer(secure, backend: _backend)) return secure;
    return 'http://$bare';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget kind(ServerBackend b, String label) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TvPillButton(
            label: label,
            selected: _backend == b,
            onSelect: () => setState(() => _backend = b),
          ),
        );

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: SizedBox(
            width: 640,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Absorb', style: tt.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(l.tvLoginTitle, style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 28),
                Row(children: [
                  kind(ServerBackend.audiobookshelf, 'Audiobookshelf'),
                  kind(ServerBackend.bookorbit, 'BookOrbit'),
                ]),
                const SizedBox(height: 20),
                TvTextField(
                  controller: _server,
                  hint: l.tvLoginServerHint,
                  icon: Icons.dns_rounded,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 14),
                TvTextField(controller: _username, hint: l.tvLoginUsername, icon: Icons.person_rounded),
                const SizedBox(height: 14),
                TvTextField(
                  controller: _password,
                  hint: l.loginPassword,
                  icon: Icons.lock_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: tt.bodyLarge?.copyWith(color: cs.error)),
                ],
                const SizedBox(height: 24),
                Row(children: [
                  TvPillButton(
                    icon: _busy ? Icons.hourglass_top_rounded : Icons.login_rounded,
                    label: l.loginSignIn,
                    selected: true,
                    onSelect: _busy ? null : _signIn,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
