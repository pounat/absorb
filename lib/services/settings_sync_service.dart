import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey, applyAppearanceFromPrefs;
import '../providers/library_provider.dart';
import '../widgets/overlay_toast.dart';
import 'backup_service.dart';
import 'player_settings.dart';
import 'scoped_prefs.dart';
import 'user_account_service.dart';

enum SyncStatus {
  ok,
  notConfigured,
  noRemote,
  authFailed,
  network,
  tooLarge,
}

class SyncResult {
  final SyncStatus status;
  final String? message;

  /// The real reason, kept verbatim for the settings screen to show: the HTTP
  /// status, or the exception type and text, plus the URL that was actually
  /// requested. A generic "could not reach that address" hides whether the
  /// server said no, the name did not resolve, or a redirect landed on a
  /// certificate the app will not trust.
  final String? detail;

  const SyncResult(this.status, [this.message, this.detail]);

  bool get ok => status == SyncStatus.ok;
}

/// Keeps app settings in step across a user's devices by parking one JSON file
/// on their own WebDAV server (Nextcloud and friends). It reuses the backup
/// payload rather than inventing a second serializer, but only an explicit
/// subset of it travels - see [_syncedKeys].
///
/// WebDAV rather than Drive: it works on the GMS-free F-Droid build, most
/// self-hosters already have one, and a push is a single authenticated PUT
/// with no OAuth dance.
class SettingsSyncService {
  static final SettingsSyncService _instance = SettingsSyncService._();
  factory SettingsSyncService() => _instance;
  SettingsSyncService._();

  /// Swapped out in tests so the WebDAV round trip can be exercised without a
  /// server. Null in the app, which falls through to the package-level helpers.
  @visibleForTesting
  static http.Client? testClient;

  Future<http.Response> _put(Uri url, Map<String, String> headers, String body) {
    final c = testClient;
    return c != null
        ? c.put(url, headers: headers, body: body)
        : http.put(url, headers: headers, body: body);
  }

  Future<http.Response> _getUrl(Uri url, Map<String, String> headers) {
    final c = testClient;
    return c != null ? c.get(url, headers: headers) : http.get(url, headers: headers);
  }

  /// The ONLY top-level backup keys that ever leave the device. This is an
  /// allowlist and not a denylist on purpose: a key added to the backup later
  /// must not start syncing just because someone forgot this file exists.
  ///
  /// Deliberately absent, and why:
  /// - pendingSyncs / pendingOfflineListening / offlineListening /
  ///   bookmarksPending* / pendingEbookProgress: this device's unsent listening
  ///   ledger. Copy it to a second device and both flush the same entries,
  ///   which is what produced the 28h phantom session.
  /// - accounts / customHeaders: real server tokens. Also, ABS rotates refresh
  ///   tokens, so a stale one arriving from the file could overwrite a freshly
  ///   rotated one and strand the session.
  /// - rmab: carries an API token, so it is opt-in rather than absent - see
  ///   [getSyncRmab].
  /// - customDownloadPath: a path that is only true on one phone.
  /// - offlineMode: a per-device switch.
  ///
  /// `podcastBookmarks` is here for the opposite reason: ABS bookmarks carry no
  /// episode id, so those never reach the server and this is the only way they
  /// reach another device. It is content, not a pending ledger.
  static const _syncedKeys = <String>{
    'settings',
    'autoRewind',
    'autoSleep',
    'equalizer',
    'bookSpeeds',
    'notes',
    'savedEbooks',
    'rollingDownloadSeries',
    'upcomingAlwaysScan',
    'upcomingNeverScan',
    'upcomingIgnoredBooks',
    'subscribedPodcasts',
    'absorbingManualAdds',
    'absorbingFinishedManualAdds',
    'absorbingManualRemoves',
    'yearHiddenIds',
    'homeLayouts',
    'librarySettings',
    'metadataOverrides',
    'ebookAnnotations',
    'podcastBookmarks',
    'ereader',
    'navHold',
    'podcastPrefs',
  };

  /// Entries inside the settings bucket that never travel, even though
  /// `settings` itself does. Stripped in BOTH directions.
  ///
  /// `trustAllCerts` is the one that matters: it feeds the global
  /// badCertificateCallback, so accepting it from the remote file would let
  /// anyone who can write to that file turn off certificate checking on every
  /// device that pulls. A sync file is not allowed to weaken transport
  /// security, so this stays a decision made on the device it applies to.
  ///
  /// `loggingEnabled` is here for a duller reason - you turn debug logging on
  /// for the device you are debugging, not for all of them.
  ///
  /// The local server address deliberately is NOT here: it travels with
  /// everything else, on the basis that a user's devices are usually on the
  /// same network as their server.
  static const _deviceLocalSettings = <String>{
    'loggingEnabled',
    'trustAllCerts',
  };

  /// Refuse to push anything bigger than this. Ebook annotations and per-item
  /// metadata overrides are unbounded, and silently shipping a huge blob to
  /// someone's Nextcloud every time a setting changes is not a kindness.
  static const _maxPayloadBytes = 2 * 1024 * 1024;

  static const _pushDebounce = Duration(seconds: 20);

  Timer? _debounce;

  /// Most settings never fire the change notifier - theme and default speed go
  /// through the plain setter, and the absorbing lists write prefs directly -
  /// so the debounce above misses nearly everything a user actually changes.
  /// Backgrounding is too late to rely on: the push is fire-and-forget and
  /// Android can freeze the process before the request lands. So while the app
  /// is open, check periodically whether the payload has moved. The check is a
  /// local hash and costs nothing when nothing changed.
  Timer? _changeCheck;
  static const _changeCheckInterval = Duration(seconds: 45);

  bool _started = false;
  bool _busy = false;
  DateTime? _lastPullAt;

  /// Applying a remote payload writes every setting locally, which fires the
  /// same change notification a user edit does. Left alone that pushes the
  /// settings straight back up with a fresh timestamp, the other device pulls
  /// them, applies, pushes again, and the two ping-pong forever. Ignore
  /// changes for a moment after an import - long enough to cover the import's
  /// un-awaited setters settling, short enough that a real edit right after
  /// still gets picked up by the next one.
  DateTime? _suppressPushUntil;
  static const _suppressAfterImport = Duration(seconds: 10);

  // Config, scoped per account.

  Future<bool> getEnabled() async =>
      await ScopedPrefs.getBool('settingsSyncEnabled') ?? false;

  Future<void> setEnabled(bool v) async {
    await ScopedPrefs.setBool('settingsSyncEnabled', v);
    if (v) {
      start();
    } else {
      stop();
    }
  }

  Future<String?> getUrl() => ScopedPrefs.getString('settingsSyncUrl');
  Future<void> setUrl(String v) =>
      ScopedPrefs.setString('settingsSyncUrl', v.trim());

  Future<String?> getUsername() => ScopedPrefs.getString('settingsSyncUser');
  Future<void> setUsername(String v) =>
      ScopedPrefs.setString('settingsSyncUser', v.trim());

  Future<String?> getPassword() => ScopedPrefs.getString('settingsSyncPass');
  Future<void> setPassword(String v) =>
      ScopedPrefs.setString('settingsSyncPass', v);

  /// Extra headers sent with every WebDAV request, for folders that sit behind
  /// a proxy wanting its own header (Cloudflare Access and friends). Not an
  /// alternative to the username and password - it rides alongside them.
  Future<Map<String, String>> getCustomHeaders() async {
    final raw = await ScopedPrefs.getString('settingsSyncHeaders');
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry('$k', '$v'));
      }
    } catch (_) {}
    return const {};
  }

  Future<void> setCustomHeaders(Map<String, String> headers) =>
      ScopedPrefs.setString(
        'settingsSyncHeaders',
        headers.isEmpty ? '' : jsonEncode(headers),
      );

  /// Parse the settings screen's one-per-line `Name: value` text. Lines
  /// without a colon are skipped rather than silently mangled.
  static Map<String, String> parseHeaderLines(String text) {
    final out = <String, String>{};
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final idx = trimmed.indexOf(':');
      if (idx <= 0) continue;
      final name = trimmed.substring(0, idx).trim();
      final value = trimmed.substring(idx + 1).trim();
      if (name.isEmpty) continue;
      out[name] = value;
    }
    return out;
  }

  static String headerLines(Map<String, String> headers) =>
      headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');

  /// Opt-in because the ReadMeABook config carries an API token, and that is
  /// the user's decision to make about their own storage rather than a default
  /// worth choosing for them.
  Future<bool> getSyncRmab() async =>
      await ScopedPrefs.getBool('settingsSyncIncludeRmab') ?? false;
  Future<void> setSyncRmab(bool v) =>
      ScopedPrefs.setBool('settingsSyncIncludeRmab', v);

  /// Top-level keys allowed right now, base set plus whatever the user opted
  /// into. Resolved fresh on both push and pull, and it is deliberately THIS
  /// device's choice that decides on the way in - a remote file cannot opt a
  /// device into receiving something it has turned off.
  ///
  /// Server logins are not on offer here at any setting. Beyond the tokens
  /// themselves, ABS rotates refresh tokens, so a stale one arriving from the
  /// file could overwrite a freshly rotated one and strand the session.
  Future<Set<String>> _activeKeys() async => {
        ..._syncedKeys,
        if (await getSyncRmab()) 'rmab',
      };


  /// Epoch ms of the newest payload this device has either written or applied.
  /// Both directions compare against it, so a device never re-imports its own
  /// push and never quietly loses a newer copy it has not seen.
  Future<int> _lastSeen() async =>
      await ScopedPrefs.getInt('settingsSyncLastSeen') ?? 0;

  Future<void> _setLastSeen(int v) =>
      ScopedPrefs.setInt('settingsSyncLastSeen', v);

  /// Fingerprint of the last payload actually written, ignoring its timestamp.
  Future<String?> _lastHash() => ScopedPrefs.getString('settingsSyncLastHash');
  Future<void> _setLastHash(String v) =>
      ScopedPrefs.setString('settingsSyncLastHash', v);

  /// Encode with every map's keys sorted, at every depth.
  ///
  /// Several payload buckets - book speeds, home layouts, per-library
  /// settings, ebook annotations, podcast prefs - are built by walking
  /// `prefs.getKeys()`, which has no defined order. Plain `jsonEncode` then
  /// gives two devices different text for identical content, which made every
  /// pull report a handful of phantom changes and could push when nothing had
  /// actually moved.
  static String _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => '$k').toList()..sort();
      return '{${keys.map((k) => '${jsonEncode(k)}:${_canonical(value[k])}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonical).join(',')}]';
    }
    return jsonEncode(value);
  }

  static String _hash(Map<String, dynamic> payload) {
    final copy = Map<String, dynamic>.from(payload)..remove('syncedAt');
    return sha256.convert(utf8.encode(_canonical(copy))).toString();
  }

  Future<DateTime?> getLastSyncTime() async {
    final ms = await _lastSeen();
    return ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // Lifecycle.

  /// Begin watching for settings changes when the user has this turned on.
  /// Safe to call repeatedly.
  Future<void> startIfEnabled() async {
    if (await getEnabled()) start();
  }

  void start() {
    if (_started) return;
    _started = true;
    PlayerSettings.settingsChanged.addListener(_onSettingsChanged);
    _changeCheck?.cancel();
    _changeCheck = Timer.periodic(
      _changeCheckInterval,
      (_) => unawaited(pushIfChanged()),
    );
    debugPrint(
      '[SettingsSync] started - change check every '
      '${_changeCheckInterval.inSeconds}s',
    );
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _debounce?.cancel();
    _debounce = null;
    _changeCheck?.cancel();
    _changeCheck = null;
    PlayerSettings.settingsChanged.removeListener(_onSettingsChanged);
    debugPrint('[SettingsSync] stopped');
  }

  void _onSettingsChanged() {
    final until = _suppressPushUntil;
    if (until != null && DateTime.now().isBefore(until)) return;
    _debounce?.cancel();
    // Through the content check, not straight to push. The notifier fires for
    // plenty of things that never reach the payload (and fires repeatedly for
    // one user action), and every redundant upload bumps syncedAt, which makes
    // the other device wake up and "apply" a file identical to what it has.
    _debounce = Timer(_pushDebounce, () => unawaited(pushIfChanged()));
  }

  /// Nothing pulls while the app sits open, so this is the only chance to
  /// notice another device's changes. The guard is only here to collapse the
  /// double call at startup (main() and the first foreground) and any lifecycle
  /// flapping - it is deliberately short, because a long one would skip the
  /// pull for a quick app switch and then leave the settings stale for as long
  /// as the app stayed open, which is the very thing this is meant to fix.
  static const _foregroundPullGuard = Duration(seconds: 10);

  Future<void> onAppForegrounded() async {
    if (!await getEnabled()) return;
    final now = DateTime.now();
    if (_lastPullAt != null &&
        now.difference(_lastPullAt!) < _foregroundPullGuard) {
      return;
    }
    _lastPullAt = now;
    // Send anything this device is still holding BEFORE taking the remote copy.
    // A change made just before the app was swiped away never got its push -
    // the process was gone - so it is sitting here unsent. Pulling first would
    // overwrite it with the other device's older copy and then upload that,
    // losing the change silently. Pushing first stamps our copy as the newest,
    // and the pull below then sees its own timestamp and skips.
    if (await _hasUnsentChanges()) {
      debugPrint('[SettingsSync] unsent local changes - pushing before pulling');
      await pushIfChanged();
    }
    final result = await pull();
    // Settings quietly rearranging themselves is unnerving, so say so - but
    // only when something actually landed. A pull that found nothing new, or
    // could not reach the server, is not worth interrupting anyone for.
    if (result.ok && result.message == 'applied') {
      _toastApplied(_lastApplyCount);
    }
    // Catch anything that changed while the app was away without going through
    // the settings notifier - see [pushIfChanged].
    await pushIfChanged();
  }

  /// How many entries the last applied pull actually moved. A count rather
  /// than a list of names: naming them would need a translated label for every
  /// setting, and the first pull on a new device changes everything at once,
  /// which no toast can hold. The number answers the question someone actually
  /// has when settings shift under them - was that a tweak or a wholesale
  /// replace.
  int _lastApplyCount = 0;

  @visibleForTesting
  int get debugLastApplyCount => _lastApplyCount;

  /// Entries the incoming payload would actually move. Settings are counted
  /// one by one; every other bucket counts as a single thing, since "your home
  /// screen layout changed" is one fact to a reader, not fourteen.
  ///
  /// Only keys PRESENT in [after] are considered, because that is exactly what
  /// importSettings applies - a key the remote file omits leaves the local
  /// value alone, so counting it as a change would report a wholesale replace
  /// every time an older or partial payload arrived.
  static int _countChanges(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) {
    const ignored = {'syncedAt', 'version', 'appVersion'};
    var changed = 0;
    for (final key in after.keys) {
      if (ignored.contains(key)) continue;
      if (key == 'settings') {
        final b = before['settings'] as Map? ?? const {};
        final a = after['settings'] as Map? ?? const {};
        for (final sk in a.keys) {
          if (_canonical(b[sk]) != _canonical(a[sk])) changed++;
        }
      } else if (_canonical(before[key]) != _canonical(after[key])) {
        changed++;
      }
    }
    return changed;
  }

  /// Importing only rewrites SharedPreferences. Anything already holding those
  /// values in memory keeps serving the old ones, and the absorbing lists go
  /// further and write their stale copy back over what just arrived. So after
  /// an import, tell the live app to re-read.
  Future<void> _applyToRunningApp() async {
    try {
      await applyAppearanceFromPrefs();
    } catch (e) {
      debugPrint('[SettingsSync] appearance refresh failed: $e');
    }
    try {
      final navigator = rootNavigatorKey.currentState;
      final context = navigator?.context;
      if (context != null && context.mounted) {
        await Provider.of<LibraryProvider>(
          context,
          listen: false,
        ).reloadPrefsBackedState();
      }
    } catch (e) {
      debugPrint('[SettingsSync] library reload failed: $e');
    }
    // Skip amounts, notification labels and the rest of the player's cached
    // settings come back through the normal settings-changed path.
    PlayerSettings.notifySettingsChanged();
  }

  void _toastApplied(int count) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    final l = AppLocalizations.of(navigator.context);
    showNavigatorOverlayToast(
      navigator,
      l?.syncSettingsAppliedCount(count) ??
          '$count settings updated from your other device',
      icon: Icons.cloud_done_rounded,
    );
  }

  /// A restored backup can carry the sync setup, but its content is a copy of
  /// another phone's past, not edits made here - so it must not race the
  /// server. Fingerprint the restored state as already-uploaded first (nothing
  /// pushes on its own), start syncing, then ask which copy wins: the server's
  /// last sync, or this backup - which replaces the file on the server for
  /// every synced device. Dismissing the dialog leaves the server as the
  /// source: the cleared last-seen stamp means the next pull applies it.
  Future<void> resolveSourceAfterRestore() async {
    if (!await getEnabled()) return;
    try {
      await _setLastHash(_hash(await buildPayload()));
    } catch (_) {}
    start();
    final navigator = rootNavigatorKey.currentState;
    final context = navigator?.context;
    if (context == null || !context.mounted) return;
    final l = AppLocalizations.of(context)!;
    final useBackup = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.syncSourceTitle),
        content: Text(l.syncSourceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.syncSourceUseBackup),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.syncSourceUseServer),
          ),
        ],
      ),
    );
    if (useBackup == null) return;
    if (useBackup) {
      final r = await push();
      r.ok ? _toastUploaded() : _toastProblem();
      return;
    }
    var r = await pull(force: true);
    if (r.status == SyncStatus.noRemote) {
      // Nothing on the server to prefer - seed it with what this device has.
      r = await push();
      r.ok ? _toastUploaded() : _toastProblem();
      return;
    }
    if (r.ok && r.message == 'applied') {
      _toastApplied(_lastApplyCount);
    } else if (!r.ok) {
      _toastProblem();
    }
  }

  void _toastUploaded() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    final l = AppLocalizations.of(navigator.context);
    showNavigatorOverlayToast(
      navigator,
      l?.syncSettingsUploaded ?? 'Settings uploaded',
      icon: Icons.cloud_upload_rounded,
    );
  }

  void _toastProblem() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    final l = AppLocalizations.of(navigator.context);
    showNavigatorOverlayToast(
      navigator,
      l?.syncSettingsStatusProblem ?? 'Could not reach your server',
      icon: Icons.cloud_off_rounded,
    );
  }

  /// Whether this device is holding changes it has not managed to upload.
  Future<bool> _hasUnsentChanges() async {
    try {
      return _hash(await buildPayload()) != await _lastHash();
    } catch (_) {
      return false;
    }
  }

  /// Nudge from code that writes synced data straight to prefs without going
  /// through PlayerSettings - ebook highlights and bookmarks, mainly. Without
  /// it those wait for the periodic check, which is up to 45 seconds and does
  /// not run at all once the app is backgrounded.
  void noteLocalChange() {
    if (!_started) return;
    final until = _suppressPushUntil;
    if (until != null && DateTime.now().isBefore(until)) return;
    _debounce?.cancel();
    _debounce = Timer(_pushDebounce, () => unawaited(pushIfChanged()));
  }

  /// Push when the payload's content has actually moved, regardless of whether
  /// anything fired the settings notifier.
  ///
  /// Most of what syncs is written straight through ScopedPrefs and never
  /// notifies: ebook highlights, home layouts, per-book speeds, subscribed
  /// podcasts, the absorbing lists, per-library skip overrides. Hanging uploads
  /// solely off PlayerSettings.settingsChanged would leave all of that sitting
  /// on the device until some unrelated toggle happened to move. Comparing a
  /// hash of the payload catches it without making dozens of setters notify
  /// and rebuild the UI for no reason.
  Future<SyncResult> pushIfChanged() async {
    if (!await getEnabled()) return const SyncResult(SyncStatus.notConfigured);
    try {
      final hash = _hash(await buildPayload());
      if (hash == await _lastHash()) {
        return const SyncResult(SyncStatus.ok, 'unchanged');
      }
      debugPrint('[SettingsSync] settings moved since last upload - pushing');
    } catch (e) {
      debugPrint('[SettingsSync] change check failed: $e');
    }
    return push();
  }

  /// Called when the app goes to the background, so a session's worth of
  /// highlights and layout changes ships without waiting for the next launch.
  Future<void> onAppBackgrounded() async {
    _debounce?.cancel();
    _debounce = null;
    await pushIfChanged();
  }

  /// The backup payload, reduced to what may travel.
  Future<Map<String, dynamic>> buildPayload() async {
    final full = await BackupService.exportSettings(includeAccounts: false);
    final allowed = await _activeKeys();
    final out = <String, dynamic>{
      'version': full['version'],
      'appVersion': full['appVersion'],
    };
    for (final key in allowed) {
      if (full.containsKey(key) && full[key] != null) out[key] = full[key];
    }
    out['settings'] = _stripSettings(out['settings']);
    return out;
  }

  static Map<String, dynamic> _stripSettings(Object? settings) {
    if (settings is! Map) return <String, dynamic>{};
    final copy = Map<String, dynamic>.from(settings);
    copy.removeWhere((k, _) => _deviceLocalSettings.contains(k));
    return copy;
  }

  // Transport.

  Uri? _remoteUri(String base) {
    final trimmed = base.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse('$trimmed/${_fileName()}');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }

  /// One file per account, named from a hash of the account scope so two
  /// accounts pointed at the same folder cannot stomp each other, and so the
  /// filename does not leak a server address into the user's file listing.
  String _fileName() {
    final scope = UserAccountService().activeScopeKey;
    final digest = sha256.convert(utf8.encode(scope)).toString();
    return 'absorb-settings-${digest.substring(0, 16)}.json';
  }

  /// Diagnostics for a response the app did not like. `location` matters: a
  /// server that redirects plain HTTP to HTTPS is a common reason a URL that
  /// works in a browser fails here.
  static String _http(http.Response resp, Uri uri, String method) {
    final buf = StringBuffer('$method $uri\nHTTP ${resp.statusCode}');
    final location = resp.headers['location'];
    if (location != null) buf.write('\nredirected to: $location');
    final body = resp.body.trim();
    if (body.isNotEmpty) {
      buf.write('\n${body.substring(0, body.length.clamp(0, 300))}');
    }
    return buf.toString();
  }

  /// Diagnostics for a request that never produced a response at all. The
  /// exception type is the useful half - a name that does not resolve, a
  /// refused connection and a rejected certificate all read the same once
  /// they have been flattened to a sentence.
  static String _err(Object e, Uri uri, String method) =>
      '$method $uri\n${e.runtimeType}: $e';

  Future<Map<String, String>?> _authHeaders() async {
    final user = await getUsername();
    final pass = await getPassword();
    if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
      return null;
    }
    final basic = base64Encode(utf8.encode('$user:$pass'));
    // Custom headers first so a stray `Authorization` entry can't displace the
    // credentials the user actually filled in.
    return {...await getCustomHeaders(), 'authorization': 'Basic $basic'};
  }

  /// Push local settings up. No-op while another sync is mid-flight.
  Future<SyncResult> push() async {
    if (_busy) {
      debugPrint('[SettingsSync] push skipped - another sync in flight');
      return const SyncResult(SyncStatus.ok, 'busy');
    }
    if (!await getEnabled()) {
      debugPrint('[SettingsSync] push skipped - sync is off');
      return const SyncResult(SyncStatus.notConfigured);
    }
    final base = await getUrl();
    if (base == null || base.isEmpty) {
      debugPrint('[SettingsSync] push skipped - no folder address set');
      return const SyncResult(SyncStatus.notConfigured);
    }
    final uri = _remoteUri(base);
    final headers = await _authHeaders();
    if (uri == null || headers == null) {
      debugPrint('[SettingsSync] push skipped - address or sign-in incomplete');
      return const SyncResult(SyncStatus.notConfigured);
    }

    _busy = true;
    try {
      final payload = await buildPayload();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      payload['syncedAt'] = stamp;
      final body = jsonEncode(payload);
      if (body.length > _maxPayloadBytes) {
        debugPrint(
          '[SettingsSync] payload ${body.length}b over cap - not pushing',
        );
        return const SyncResult(SyncStatus.tooLarge);
      }
      final resp = await _put(
        uri,
        {...headers, 'content-type': 'application/json'},
        body,
      ).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        return SyncResult(SyncStatus.authFailed, null, _http(resp, uri, 'PUT'));
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await _setLastSeen(stamp);
        await _setLastHash(_hash(payload));
        debugPrint(
          '[SettingsSync] pushed ${body.length}b (HTTP ${resp.statusCode})',
        );
        return const SyncResult(SyncStatus.ok);
      }
      debugPrint('[SettingsSync] push rejected - HTTP ${resp.statusCode}');
      return SyncResult(SyncStatus.network, null, _http(resp, uri, 'PUT'));
    } catch (e) {
      debugPrint('[SettingsSync] push failed: ${e.runtimeType} - $e');
      return SyncResult(SyncStatus.network, null, _err(e, uri, 'PUT'));
    } finally {
      _busy = false;
    }
  }

  /// Fetch the remote copy and apply it when it is newer than anything this
  /// device has seen. Returns [SyncStatus.noRemote] before any device has
  /// pushed for the first time.
  Future<SyncResult> pull({bool force = false}) async {
    if (_busy) {
      debugPrint('[SettingsSync] pull skipped - another sync in flight');
      return const SyncResult(SyncStatus.ok, 'busy');
    }
    if (!await getEnabled()) {
      debugPrint('[SettingsSync] pull skipped - sync is off');
      return const SyncResult(SyncStatus.notConfigured);
    }
    final base = await getUrl();
    if (base == null || base.isEmpty) {
      return const SyncResult(SyncStatus.notConfigured);
    }
    final uri = _remoteUri(base);
    final headers = await _authHeaders();
    if (uri == null || headers == null) {
      return const SyncResult(SyncStatus.notConfigured);
    }

    _busy = true;
    try {
      final resp =
          await _getUrl(uri, headers).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        return SyncResult(SyncStatus.authFailed, null, _http(resp, uri, 'GET'));
      }
      if (resp.statusCode == 404) {
        debugPrint('[SettingsSync] nothing on the server yet (404)');
        return SyncResult(SyncStatus.noRemote, null, _http(resp, uri, 'GET'));
      }
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('[SettingsSync] pull rejected - HTTP ${resp.statusCode}');
        return SyncResult(SyncStatus.network, null, _http(resp, uri, 'GET'));
      }

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return SyncResult(
          SyncStatus.network,
          'unexpected file contents',
          'GET $uri returned ${resp.statusCode} but the body was not a JSON '
              'object. First 200 chars:\n'
              '${resp.body.substring(0, resp.body.length.clamp(0, 200))}',
        );
      }
      final remoteAt = (decoded['syncedAt'] as num?)?.toInt() ?? 0;
      if (!force && remoteAt <= await _lastSeen()) {
        debugPrint('[SettingsSync] remote not newer - nothing to apply');
        return const SyncResult(SyncStatus.ok, 'up to date');
      }

      // Filter on the way in as well as out. The file sits on a server the app
      // does not control, so a payload written by a future (or tampered)
      // client cannot smuggle in accounts or a pending listening ledger.
      final allowed = await _activeKeys();
      final safe = <String, dynamic>{'version': decoded['version'] ?? 3};
      for (final key in allowed) {
        if (decoded.containsKey(key) && decoded[key] != null) {
          safe[key] = decoded[key];
        }
      }
      safe['settings'] = _stripSettings(safe['settings']);

      // Measure against what this device holds right now, before the import
      // overwrites it.
      try {
        _lastApplyCount = _countChanges(await buildPayload(), safe);
      } catch (_) {
        _lastApplyCount = 0;
      }
      _suppressPushUntil = DateTime.now().add(_suppressAfterImport);
      await BackupService.importSettings(safe);
      await _applyToRunningApp();
      await _setLastSeen(remoteAt);
      // Fingerprint what we just adopted, so the change check does not read the
      // freshly-applied remote state as a local edit and bounce it straight
      // back up.
      try {
        await _setLastHash(_hash(await buildPayload()));
      } catch (_) {}
      // Anything queued while the import was writing is the import's own echo,
      // not a user edit.
      _debounce?.cancel();
      _debounce = null;
      if (_lastApplyCount == 0) {
        // The remote file was newer but identical - nothing actually moved, so
        // there is nothing to tell the user about.
        debugPrint(
          '[SettingsSync] remote stamped $remoteAt was newer but identical',
        );
        return const SyncResult(SyncStatus.ok, 'up to date');
      }
      debugPrint(
        '[SettingsSync] applied $_lastApplyCount change(s) from remote '
        'stamped $remoteAt',
      );
      return const SyncResult(SyncStatus.ok, 'applied');
    } catch (e) {
      debugPrint('[SettingsSync] pull failed: ${e.runtimeType} - $e');
      return SyncResult(SyncStatus.network, null, _err(e, uri, 'GET'));
    } finally {
      _busy = false;
    }
  }

  /// One-shot check so the settings screen can tell the user whether the
  /// address and credentials work, without touching local settings.
  Future<SyncResult> testConnection() async {
    final base = await getUrl();
    if (base == null || base.isEmpty) {
      return const SyncResult(SyncStatus.notConfigured);
    }
    final uri = _remoteUri(base);
    final headers = await _authHeaders();
    if (uri == null || headers == null) {
      return const SyncResult(SyncStatus.notConfigured);
    }
    try {
      final resp =
          await _getUrl(uri, headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        return SyncResult(SyncStatus.authFailed, null, _http(resp, uri, 'GET'));
      }
      // A 404 only means nothing has been pushed yet, which is a fine outcome
      // for first-time setup - the address and credentials still checked out.
      if (resp.statusCode == 404) {
        return SyncResult(SyncStatus.noRemote, null, _http(resp, uri, 'GET'));
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return SyncResult(SyncStatus.ok, null, _http(resp, uri, 'GET'));
      }
      return SyncResult(SyncStatus.network, null, _http(resp, uri, 'GET'));
    } catch (e) {
      return SyncResult(SyncStatus.network, null, _err(e, uri, 'GET'));
    }
  }
}
