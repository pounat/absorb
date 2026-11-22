import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../main.dart' show rootNavigatorKey;
import '../services/api_service.dart';
import '../services/scoped_prefs.dart';
import 'tv_login_screen.dart';
import '../services/server_backend.dart';
import '../services/tv_pairing.dart';

/// The TV's sign-in: a QR code the phone scans to hand over a sign-in of the
/// TV's own, with the usual sign-in screen one press away for anyone
/// without a phone.
class TvPairScreen extends StatefulWidget {
  /// Signing in another account on a TV that already has one.
  final bool adding;

  const TvPairScreen({super.key, this.adding = false});

  @override
  State<TvPairScreen> createState() => _TvPairScreenState();
}

class _TvPairScreenState extends State<TvPairScreen> {
  TvPairServer? _server;
  bool _starting = true;
  bool _signingIn = false;

  late final AuthProvider _auth;
  late final String _startAccount;

  String get _accountKey => '${_auth.userId}@${_auth.serverUrl}';

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>()..addListener(_onAuth);
    _startAccount = widget.adding ? _accountKey : '';
    _start();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    _server?.close();
    super.dispose();
  }

  // Signed in on the TV's own sign-in screen: close it so the home shows.
  void _onAuth() {
    if (!_auth.isAuthenticated || !mounted) return;
    // Adding one, the TV was signed in all along: wait for the other account.
    if (widget.adding && _accountKey == _startAccount) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    TvPairServer? server;
    try {
      server = await TvPairServer.start(onSignIn: _signIn);
    } catch (e) {
      debugPrint('[TvPair] could not start: $e');
    }
    if (!mounted) {
      await server?.close();
      return;
    }
    setState(() {
      _server = server;
      _starting = false;
    });
  }

  Future<String?> _signIn(TvSignIn s) async {
    if (!mounted) return 'Closed';
    final l = AppLocalizations.of(context)!;
    final auth = _auth;
    setState(() => _signingIn = true);
    if (widget.adding) {
      // As on the phone: the first account's book stops before the other signs in.
      final player = AudioPlayerService();
      if (player.hasBook) {
        await player.pause();
        await player.stop();
      }
    }
    final backend = ServerBackend.fromKey(s.backend);
    final serverUrl = await _reachable(s, backend);
    final ok = s.apiKey != null
        ? await auth.loginWithApiKey(
            serverUrl: serverUrl,
            apiKey: s.apiKey!,
            customHeaders: s.customHeaders,
            backend: backend,
            l: l,
          )
        : await auth.login(
            serverUrl: serverUrl,
            username: s.username!,
            password: s.password!,
            customHeaders: s.customHeaders,
            backend: backend,
            l: l,
          );
    final local = s.localServerUrl;
    if (ok && local != null && local != serverUrl) {
      // Same as the phone: the home address while the TV can reach it, the
      // usual one otherwise.
      await auth.setLocalServerConfig(enabled: true, url: local);
      unawaited(auth.checkLocalServer());
    }
    if (ok) await _matchPhone(s);
    if (mounted) setState(() => _signingIn = false);
    debugPrint('[TvPair] sign-in from phone ${ok ? 'worked' : 'failed: ${auth.errorMessage}'}');
    return ok ? null : (auth.errorMessage ?? l.loginFailed);
  }

  /// The phone's address for the server, or the first other one the TV can
  /// reach: its home address, then the name by number.
  Future<String> _reachable(TvSignIn s, ServerBackend backend) async {
    final tries = [s.serverUrl, ?s.localServerUrl, ...s.alternates];
    for (final url in tries) {
      if (await ApiService.pingServer(url, customHeaders: s.customHeaders, backend: backend)) {
        if (url != s.serverUrl) debugPrint('[TvPair] the phone\'s server address is out of reach here; using $url');
        return url;
      }
    }
    return s.serverUrl;
  }

  /// Opens the library the phone is on, so the row shows the same cards.
  Future<void> _matchPhone(TvSignIn s) async {
    try {
      // Only after the sign-in: touching the library before it lands makes
      // it miss that this is a new sign-in, and it never loads. This screen
      // is already gone by now, so go through the app's own navigator.
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      final lib = Provider.of<LibraryProvider>(ctx, listen: false);
      if (s.mergeLibraries) await PlayerSettings.setMergeAbsorbingLibraries(true);
      final id = s.libraryId;
      if (id == null) return;
      // Saved first, so a library list still loading picks it up too.
      await ScopedPrefs.setString('last_selected_library', id);
      if (lib.selectedLibraryId != id && lib.libraries.any((l) => l['id'] == id)) {
        await lib.selectLibrary(id);
      }
    } catch (e) {
      debugPrint('[TvPair] could not open the phone library: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final server = _server;

    Widget code;
    if (_starting || _signingIn) {
      code = const SizedBox(width: 320, height: 320, child: Center(child: CircularProgressIndicator()));
    } else if (server == null) {
      code = SizedBox(
        width: 320,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.tvSignInNoNetwork, textAlign: TextAlign.center, style: tt.titleMedium),
          const SizedBox(height: 20),
          FilledButton(onPressed: _start, child: Text(l.tvSignInRetry)),
        ]),
      );
    } else {
      code = ValueListenableBuilder<String>(
        valueListenable: server.qrUrl,
        builder: (_, url, _) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: QrImageView(data: url, version: QrVersions.auto, size: 280, padding: EdgeInsets.zero),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Absorb', style: tt.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text(l.tvSignInTitle, style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 28),
                      _Step(number: 1, text: l.tvSignInStep1),
                      const SizedBox(height: 14),
                      _Step(number: 2, text: l.tvSignInStep2),
                      const SizedBox(height: 24),
                      Text(l.tvSignInNeedsPhone, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        autofocus: true,
                        icon: const Icon(Icons.keyboard_rounded),
                        label: Text(l.tvSignInHere),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const TvLoginScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 72),
              code,
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: cs.primaryContainer,
        child: Text('$number', style: tt.titleSmall?.copyWith(color: cs.onPrimaryContainer)),
      ),
      const SizedBox(width: 14),
      Flexible(child: Text(text, style: tt.titleMedium)),
    ]);
  }
}
