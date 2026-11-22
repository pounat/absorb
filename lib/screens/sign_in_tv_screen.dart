import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart' show PlayerSettings;
import '../services/api_service.dart';
import '../services/bookorbit_api_keys.dart';
import '../services/tv_pairing.dart';
import 'bookorbit_admin_screen.dart' show boAdminApi;

/// Opened from the TV's QR code: gives the TV a sign-in of its own to this
/// account. An API key made for it when the account can make one, or else
/// the password, which goes to the TV and nowhere else.
class SignInTvScreen extends StatefulWidget {
  final TvPairLink link;

  const SignInTvScreen({super.key, required this.link});

  @override
  State<SignInTvScreen> createState() => _SignInTvScreenState();
}

class _SignInTvScreenState extends State<SignInTvScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// Audiobookshelf admins make keys for themselves; BookOrbit lets anyone
  /// with the permission, but not from a session that is itself a key.
  bool _usesKey(AuthProvider auth) => auth.isBookOrbit
      ? auth.bookOrbitCanMakeApiKeys && !auth.bookOrbitSignedInWithKey
      : auth.isAdmin;

  /// A key for the TV and a way to take it back if the TV never gets it.
  Future<({String token, Future<void> Function() revoke})?> _makeKey(AuthProvider auth, AppLocalizations l) async {
    if (auth.isBookOrbit) {
      final api = boAdminApi(context);
      if (api == null) return null;
      final settings = await api.apiKeySettings();
      if (!settings.enabled) return null;
      final bo = auth.userJson?['bookOrbit'] as Map?;
      final superuser = bo?['isSuperuser'] == true;
      final owned = {for (final p in (bo?['permissions'] as List? ?? const [])) '$p'};
      final created = await api.createBoApiKey(
        name: l.signInTvKeyName,
        write: true,
        permissions: superuser ? const {} : boApiKeyGrantable(owned),
        expiry: boApiKeyExpiryChoices(settings.maxLifetimeDays).last,
        admin: superuser,
      );
      return (token: created.token, revoke: () => api.revokeApiKey(created.key.id));
    }
    final api = auth.apiService;
    final userId = auth.userId;
    if (api == null || userId == null) return null;
    final created = await api.createApiKey(name: l.signInTvKeyName, userId: userId);
    final token = created?['apiKey'] as String?;
    final id = created?['id'] as String?;
    if (token == null || token.isEmpty) return null;
    return (token: token, revoke: () async {
      if (id != null) await api.deleteApiKey(id);
    });
  }

  /// [url] with its name swapped for the numbers this phone finds for it,
  /// for a TV that can't look the name up. Plain http only: a certificate
  /// is for the name, so an https server can't be reached by number.
  static Future<List<String>> _byNumber(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'http' || InternetAddress.tryParse(uri.host) != null) return const [];
    try {
      final found = await InternetAddress.lookup(uri.host, type: InternetAddressType.IPv4).timeout(const Duration(seconds: 3));
      return [
        for (final a in found)
          if (!a.isLoopback) uri.replace(host: a.address).toString(),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final serverUrl = auth.serverUrl;
    if (serverUrl == null) return;
    final withKey = _usesKey(auth);
    if (!withKey && _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    ({String token, Future<void> Function() revoke})? key;
    if (withKey) {
      try {
        key = await _makeKey(auth, l);
      } catch (e) {
        debugPrint('[TvPair] making the TV a key failed: $e');
      }
      if (!mounted) return;
      if (key == null) {
        setState(() {
          _busy = false;
          _error = l.signInTvKeyFailed;
        });
        return;
      }
    }

    final libraryId = context.read<LibraryProvider>().selectedLibraryId;
    final merge = await PlayerSettings.getMergeAbsorbingLibrariesRaw();
    if (!mounted) return;
    final result = await sendSignInToTv(
      widget.link,
      TvSignIn(
        serverUrl: serverUrl,
        backend: auth.backend.key,
        apiKey: key?.token,
        username: key == null ? auth.username : null,
        password: key == null ? _password.text : null,
        customHeaders: auth.customHeaders,
        localServerUrl: auth.localServerEnabled && auth.localServerUrl.isNotEmpty ? auth.localServerUrl : null,
        alternates: await _byNumber(serverUrl),
        libraryId: libraryId,
        mergeLibraries: merge,
      ),
    );
    if (result.error != null && key != null) {
      // The TV never took it, so don't leave a key lying about.
      try {
        await key.revoke();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = result.error == null;
      _error = switch (result.error) {
        null => null,
        TvSendError.refused => l.signInTvRefused,
        TvSendError.busy => l.signInTvBusy,
        TvSendError.noAnswer => l.signInTvNoAnswer,
        TvSendError.unreachable => l.signInTvUnreachable,
        TvSendError.failed => result.detail == null ? l.signInTvFailed : '${l.signInTvFailed}: ${result.detail}',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();
    final server = Uri.tryParse(auth.serverUrl ?? '')?.host ?? auth.serverUrl ?? '';
    final withKey = _usesKey(auth);

    return Scaffold(
      appBar: AppBar(title: Text(l.signInTvTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Icon(_done ? Icons.check_circle_rounded : Icons.tv_rounded, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              _done ? l.signInTvDone : l.signInTvAs(server, auth.username ?? ''),
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (!_done) ...[
              Text(
                withKey ? l.signInTvKeyNote : l.signInTvPasswordNote,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (!withKey) ...[
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofocus: true,
                  enabled: !_busy,
                  decoration: InputDecoration(labelText: l.loginPassword, border: const OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _send(),
                ),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...[
                Text(_error!, textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.error)),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _busy || (!withKey && _password.text.isEmpty) ? null : _send,
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.signInTvButton),
              ),
            ] else ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.done)),
            ],
          ],
        ),
      ),
    );
  }
}
