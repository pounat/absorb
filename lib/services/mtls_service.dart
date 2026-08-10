import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/icloud_backup.dart';
import 'scoped_prefs.dart';
import 'user_account_service.dart';

enum MtlsImportStatus {
  ok,

  /// BoringSSL reports a wrong password and a non-PKCS#12 file alike.
  badPasswordOrFile,
  storeFailed,
}

/// Client certificate for servers that require mutual TLS, stored per account.
///
/// [securityContext] is handed to every `HttpClient` by the `HttpOverrides` in
/// `main.dart`. Native playback and downloads never touch Dart's HTTP stack, so
/// [_syncToNative] pushes the same bundle down a method channel for those.
class MtlsService {
  static final MtlsService _instance = MtlsService._();
  factory MtlsService() => _instance;
  MtlsService._();

  static const _channel = MethodChannel('com.absorb.mtls');

  static const _labelKey = 'mtls_cert_label';
  static const _passwordPrefKey = 'mtls_cert_password';
  static const _serverKey = 'mtls_cert_server';
  static const _certKeys = [_passwordPrefKey, _labelKey, _serverKey];

  Uint8List? _bundle;
  String? _password;
  String? _label;
  SecurityContext? _context;
  String? _loadedScope;

  /// Remembered rather than looked up: signing out removes the account row.
  Uri? _server;
  _StagedCertificate? _staged;

  /// False when the platform layer refused the bundle, so Dart presents the
  /// certificate but native playback does not.
  bool _platformCovered = true;
  Future<void>? _syncing;

  /// So a load that started earlier cannot apply on top of a newer one.
  int _generation = 0;

  /// Bumped on every change so widgets showing the certificate can rebuild.
  final ValueNotifier<int> revision = ValueNotifier(0);

  bool get isConfigured => _context != null;

  bool get platformCovered => _platformCovered;

  /// A certificate picked on the login screen, owned by no account yet.
  bool get hasStaged => _staged != null;

  /// File name it was imported from, for display.
  String? get label => _label;

  /// Null when no certificate is set, which leaves plain TLS in place.
  SecurityContext? get securityContext => _context;

  String get _scope => UserAccountService().activeScopeKey;

  /// Hashed: scope keys carry the server URL, path separators and all.
  Future<File> _certFile(String scope) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/mtls');
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = sha256.convert(utf8.encode(scope)).toString().substring(0, 32);
    return File('${dir.path}/$name.p12');
  }

  // Storing the password negates the bundle's own encryption, so the app
  // sandbox is what guards it.
  String _passwordKey(String scope) =>
      ScopedPrefs.keyForScope(scope, _passwordPrefKey);

  /// Activates the current account's certificate, or clears the identity when it
  /// has none.
  Future<void> loadForActiveAccount() async {
    final scope = _scope;
    final generation = ++_generation;
    _loadedScope = scope;
    _staged = null;

    if (scope.isEmpty) return _apply();

    SecurityContext? context;
    Uint8List? bundle;
    String? password;
    String? label;
    Uri? server;
    try {
      final file = await _certFile(scope);
      if (await file.exists()) {
        final prefs = await SharedPreferences.getInstance();
        password = prefs.getString(_passwordKey(scope)) ?? '';
        bundle = await file.readAsBytes();
        context = _buildContext(bundle, password);
        if (context == null) {
          // Keep the file: the user can re-import rather than silently lose it.
          debugPrint('[mTLS] Stored certificate for "$scope" is unusable');
          bundle = null;
          password = null;
        } else {
          label = prefs.getString(ScopedPrefs.keyForScope(scope, _labelKey));
          server = Uri.tryParse(
              prefs.getString(ScopedPrefs.keyForScope(scope, _serverKey)) ?? '');
          final current = _serverForScope(scope);
          if (current != null && current != server) {
            await prefs.setString(
                ScopedPrefs.keyForScope(scope, _serverKey), current.toString());
          }
        }
      }
    } catch (e) {
      debugPrint('[mTLS] Could not load certificate for "$scope": $e');
      context = null;
      bundle = null;
      password = null;
      label = null;
      server = null;
    }

    if (generation != _generation) return;
    _apply(
      context: context,
      bundle: bundle,
      password: password,
      label: label,
      // The stored URL is only a fallback for when the account row is gone.
      server: _serverForScope(scope) ?? server,
    );
  }

  /// Stores [bundle] for the current account and activates it.
  ///
  /// [stagedForServer] keeps it in memory instead, for a login that has no
  /// account yet — or one reached while another account is signed in, whose
  /// certificate must not be touched. [adoptCertificateForActiveAccount] writes
  /// it out once login creates the account it was picked for.
  Future<MtlsImportStatus> import({
    required Uint8List bundle,
    required String password,
    required String label,
    String? stagedForServer,
  }) async {
    final context = _buildContext(bundle, password);
    if (context == null) return MtlsImportStatus.badPasswordOrFile;

    if (stagedForServer != null) {
      final server = Uri.tryParse(stagedForServer);
      _staged = _StagedCertificate(
        bundle: bundle,
        password: password,
        label: label,
        server: server,
      );
      _loadedScope = null;
      _generation++;
      _apply(
        context: context,
        bundle: bundle,
        password: password,
        label: label,
        server: server,
        mirror: false,
      );
      return MtlsImportStatus.ok;
    }

    final scope = _scope;
    if (scope.isEmpty) return MtlsImportStatus.storeFailed;
    final server = _serverForScope(scope);
    // Bundle and password live in different stores, and a bundle beside the
    // wrong password cannot be loaded again — so half a write is rolled back.
    SharedPreferences? prefs;
    Map<String, String?>? previous;
    File? incoming;
    File? stored;
    try {
      prefs = await SharedPreferences.getInstance();
      previous = {
        for (final key in _certKeys) key: prefs.getString(ScopedPrefs.keyForScope(scope, key)),
      };
      await prefs.setString(_passwordKey(scope), password);
      await prefs.setString(ScopedPrefs.keyForScope(scope, _labelKey), label);
      if (server != null) {
        await prefs.setString(ScopedPrefs.keyForScope(scope, _serverKey), server.toString());
      }

      final file = await _certFile(scope);
      incoming = File('${file.path}.new');
      await incoming.writeAsBytes(bundle, flush: true);
      await incoming.rename(file.path);
      incoming = null;
      stored = file;
    } catch (e) {
      debugPrint('[mTLS] Could not store certificate: $e');
      await _rollBack(scope, prefs, previous, incoming);
      return MtlsImportStatus.storeFailed;
    }

    // Outside the try: once the bundle is in place nothing may roll the prefs
    // back. A private key does not belong in a device backup.
    await excludeFromICloudBackup(stored.path);

    _loadedScope = scope;
    _staged = null;
    _generation++;
    _apply(
      context: context,
      bundle: bundle,
      password: password,
      label: label,
      server: server,
    );
    // So [platformCovered] is settled before the caller reports success.
    await _syncing;
    return MtlsImportStatus.ok;
  }

  /// Best effort: there is nothing left to try if this fails too.
  Future<void> _rollBack(String scope, SharedPreferences? prefs,
      Map<String, String?>? previous, File? incoming) async {
    try {
      if (prefs != null && previous != null) {
        for (final entry in previous.entries) {
          final key = ScopedPrefs.keyForScope(scope, entry.key);
          final value = entry.value;
          if (value == null) {
            await prefs.remove(key);
          } else {
            await prefs.setString(key, value);
          }
        }
      }
      if (incoming != null && await incoming.exists()) await incoming.delete();
    } catch (e) {
      debugPrint('[mTLS] Could not undo a failed import: $e');
    }
  }

  /// Removes the certificate of [scope], defaulting to the current account.
  Future<void> clear({String? scope}) async {
    final target = scope ?? _scope;
    // Bumped only when this will apply, or it would cancel a load without
    // replacing what that load was about to install.
    final active = target == _loadedScope || target == _scope;
    final generation = active ? ++_generation : _generation;
    if (target.isEmpty) {
      if (active) {
        _staged = null;
        _apply();
      }
      return;
    }
    try {
      final file = await _certFile(target);
      if (await file.exists()) await file.delete();
      // An import interrupted mid-write can leave this behind.
      final incoming = File('${file.path}.new');
      if (await incoming.exists()) await incoming.delete();
      final prefs = await SharedPreferences.getInstance();
      for (final key in _certKeys) {
        await prefs.remove(ScopedPrefs.keyForScope(target, key));
      }
    } catch (e) {
      debugPrint('[mTLS] Could not remove certificate: $e');
    }
    if (active && generation == _generation) {
      _staged = null;
      _apply();
    }
  }

  /// Drops a staged certificate and puts the account's identity back.
  Future<void> clearStaged() async {
    if (_staged == null) return;
    await loadForActiveAccount();
  }

  /// Gives the account login just created the certificate it should have: the one
  /// staged during login, or else the identity already live, since a proxy asks
  /// every user of that server for one.
  ///
  /// Either way only for the server it belongs to — restoring a backup creates
  /// several accounts in a row.
  Future<void> adoptCertificateForActiveAccount() async {
    final staged = _staged;
    final target = _scope;

    // A later account in this restore may still be the server it was picked for.
    Future<void> keepStagedAndLoad() async {
      await loadForActiveAccount();
      _staged = staged;
    }

    if (target.isEmpty) return keepStagedAndLoad();

    final actual = _authority(_serverForScope(target));
    var source = staged;
    if (source != null && _authority(source.server) != actual) {
      debugPrint('[mTLS] Certificate was picked for another server — kept aside');
      // This account may still be a sibling of the one that has a certificate.
      source = null;
    }
    final inherited = source == null;
    source ??= _liveIdentity;
    if (source == null || target == _loadedScope) return keepStagedAndLoad();

    final wanted = _authority(source.server);
    if (wanted == null || wanted != actual) return keepStagedAndLoad();

    if (inherited) {
      // The account's own certificate wins, as long as it still loads.
      await loadForActiveAccount();
      if (isConfigured) {
        _staged = staged;
        return;
      }
    }

    final status = await import(
      bundle: source.bundle,
      password: source.password,
      label: source.label,
    );
    if (status != MtlsImportStatus.ok) {
      debugPrint('[mTLS] Could not store the certificate for the new account: $status');
    }
    // Both calls above clear it, and this was not the one set aside.
    if (inherited) _staged = staged;
  }

  /// The live identity, described like a staged one: the account it was loaded
  /// for is not necessarily the one signing in.
  _StagedCertificate? get _liveIdentity {
    final bundle = _bundle;
    if (bundle == null) return null;
    return _StagedCertificate(
      bundle: bundle,
      password: _password ?? '',
      label: _label ?? '',
      server: _server,
    );
  }

  /// Follows the address the login screen is checking: editing it — adding the
  /// port, say — still means this server.
  void repinStaged(String serverUrl) {
    final staged = _staged;
    if (staged == null) return;
    final server = Uri.tryParse(serverUrl);
    if (_authority(server) == _authority(staged.server)) return;
    _staged = staged.pinnedTo(server);
    // Only while the staged certificate is the live one.
    if (identical(_bundle, staged.bundle)) _server = server;
  }

  /// Host and port, the granularity at which a certificate belongs to a server.
  static String? _authority(Uri? server) {
    if (server == null || server.host.isEmpty) return null;
    return '${server.host.toLowerCase()}:${server.port}';
  }

  /// Follows an account whose scope key changed, e.g. after editing the server
  /// URL. Call before the generic scoped-prefs migration, which keeps whatever
  /// the destination has and would pair this bundle with another password.
  Future<void> migrateScope(String oldScope, String newScope) async {
    if (oldScope == newScope) return;
    try {
      final from = await _certFile(oldScope);
      if (await from.exists()) {
        final to = await _certFile(newScope);
        final prefs = await SharedPreferences.getInstance();
        if (await to.exists()) {
          // The destination's own certificate wins.
          await from.delete();
          for (final key in _certKeys) {
            await prefs.remove(ScopedPrefs.keyForScope(oldScope, key));
          }
        } else {
          await from.rename(to.path);
          for (final key in _certKeys) {
            final value = prefs.getString(ScopedPrefs.keyForScope(oldScope, key));
            if (value != null) {
              await prefs.setString(ScopedPrefs.keyForScope(newScope, key), value);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[mTLS] Could not move certificate between scopes: $e');
    }
    if (_loadedScope == oldScope) _loadedScope = newScope;
  }

  /// The one place the active identity changes. [mirror] is false for a staged
  /// certificate: it belongs to no account, and mirroring it would outlive the
  /// login on disk and take playback's identity away from the account signed in.
  void _apply({
    SecurityContext? context,
    Uint8List? bundle,
    String? password,
    String? label,
    Uri? server,
    bool mirror = true,
  }) {
    _context = context;
    _bundle = bundle;
    _password = password;
    _label = (label == null || label.isEmpty) ? null : label;
    _server = server;
    if (mirror) {
      _syncing = _syncToNative();
      unawaited(_syncing!);
    }
    revision.value++;
  }

  /// `withTrustedRoots: true` keeps server verification as it was — mTLS adds a
  /// client identity, it must not weaken how the server is checked.
  SecurityContext? _buildContext(Uint8List bundle, String password) {
    try {
      return SecurityContext(withTrustedRoots: true)
        ..useCertificateChainBytes(bundle, password: password)
        ..usePrivateKeyBytes(bundle, password: password);
    } catch (e) {
      debugPrint('[mTLS] Certificate rejected: $e');
      return null;
    }
  }

  Uri? _serverForScope(String scope) {
    for (final account in UserAccountService().accounts) {
      if (account.scopeKey == scope) return Uri.tryParse(account.serverUrl);
    }
    return null;
  }

  /// Mirrors the identity to the platform layer, which scopes it to the server's
  /// host and port. Never fatal: Dart-side mTLS works without it.
  Future<void> _syncToNative() async {
    final generation = _generation;
    _platformCovered = true;
    try {
      if (_bundle == null) {
        await _channel.invokeMethod<void>('clearCertificate');
        return;
      }
      await _channel.invokeMethod<void>('setCertificate', {
        'bundle': _bundle,
        'password': _password ?? '',
        'host': _server?.host ?? '',
        'port': _server?.port ?? 443,
      });
    } on MissingPluginException {
      // Platform without the channel, e.g. tests.
    } catch (e) {
      if (generation == _generation) _platformCovered = false;
      debugPrint('[mTLS] The platform layer would not take the certificate: $e');
    }
  }

  /// Does [error] look like the server demanding a certificate we didn't send?
  /// Matched on the message, not the type: `package:http` flattens TLS errors
  /// into `ClientException`, and the alert depends on the server's TLS version.
  static bool looksLikeClientCertRequired(Object error) {
    final msg = error.toString().toLowerCase();
    // A server whose own certificate we reject fails with the same words, and
    // that needs Trust all certificates instead.
    if (msg.contains('certificate_verify_failed') ||
        msg.contains('self signed') ||
        msg.contains('self-signed') ||
        msg.contains('unable to get local issuer')) {
      return false;
    }
    return msg.contains('certificate_required') ||
        msg.contains('certificate required') ||
        // Alert 40, which TLS 1.2 sends without mentioning certificates at all.
        msg.contains('handshake_failure') ||
        msg.contains('bad certificate') ||
        msg.contains('bad_certificate') ||
        msg.contains('peer did not return a certificate') ||
        (msg.contains('handshake') && msg.contains('certificate'));
  }

  /// Proxies that finish the handshake and reject at the HTTP layer instead: 496
  /// is nginx's "SSL Certificate Required", 403 the `ssl_verify_client optional`
  /// recipe, 400 `ssl_verify_client on`. 400 is gated on the body because a bare
  /// 400 is far too common, and 403 is ambiguous too — a WAF looks the same.
  static bool responseDemandsClientCert(int statusCode, String body) {
    if (statusCode == 496 || statusCode == 403) return true;
    if (statusCode != 400) return false;
    final lower = body.toLowerCase();
    return lower.contains('ssl certificate') || lower.contains('client certificate');
  }
}

/// A certificate picked on the login screen, before the account that will own it
/// exists. Memory-only: on disk it would outlive the login it was meant for.
class _StagedCertificate {
  final Uint8List bundle;
  final String password;
  final String label;
  final Uri? server;

  const _StagedCertificate({
    required this.bundle,
    required this.password,
    required this.label,
    required this.server,
  });

  _StagedCertificate pinnedTo(Uri? server) => _StagedCertificate(
        bundle: bundle,
        password: password,
        label: label,
        server: server,
      );
}
