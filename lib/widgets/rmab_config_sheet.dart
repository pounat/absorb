import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../screens/admin_rmab_screen.dart';
import '../services/rmab_service.dart';
import '../services/scoped_prefs.dart';
import '../utils/desktop_workspace.dart';
import 'adaptive_modal.dart';
import 'rmab_request_status_chip.dart';
import 'stackable_sheet.dart';

/// ScopedPrefs keys used by the RMAB integration.
const String kRmabBaseUrlKey = 'rmab_base_url';
const String kRmabApiTokenKey = 'rmab_api_token';

/// JSON-encoded `Map<String, String>` of extra headers sent on every RMAB
/// request, for auth proxies (Cloudflare Access, Authelia, etc.).
const String kRmabCustomHeadersKey = 'rmab_custom_headers';

/// Load the saved RMAB custom headers, or an empty map if none / unparsable.
Future<Map<String, String>> loadRmabCustomHeaders() async {
  final raw = await ScopedPrefs.getString(kRmabCustomHeadersKey);
  if (raw == null || raw.isEmpty) return const {};
  try {
    return Map<String, String>.from(jsonDecode(raw) as Map);
  } catch (e) {
    debugPrint('[RMAB] failed to parse saved custom headers: $e');
    return const {};
  }
}

/// Legacy single-URL key. Still read so existing WebView-only users keep
/// working, and so the "Open in browser view" action prefers their
/// embedded-token URL when present.
const String kRmabLegacyUrlKey = 'rmab_url';

const String _kRmabGithubUrl = 'https://github.com/kikootwo/ReadMeABook';

/// Result returned by [showRmabConfigSheet] so the caller knows whether to
/// reload its RMAB state.
class RmabConfigResult {
  const RmabConfigResult({this.changed = false, this.disconnected = false});

  final bool changed;
  final bool disconnected;
}

/// Show the shared RMAB config bottom sheet. Used by both the admin screen
/// tile and the settings screen tile.
///
/// [isAdminContext] controls the explainer copy: admin context tells the user
/// to generate a token in RMAB themselves; user context tells them to ask
/// their server admin.
Future<RmabConfigResult?> showRmabConfigSheet(
  BuildContext context, {
  required bool isAdminContext,
}) {
  return showStackableSheet<RmabConfigResult>(
    context: context,
    initialChildSize: 0.78,
    maxChildSize: 0.95,
    showHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    useSafeArea: true,
    builder: (ctx, scrollController) => _RmabConfigSheet(
      isAdminContext: isAdminContext,
      scrollController: scrollController,
    ),
  );
}

class _RmabConfigSheet extends StatefulWidget {
  const _RmabConfigSheet({
    required this.isAdminContext,
    required this.scrollController,
  });

  final bool isAdminContext;
  final ScrollController scrollController;

  @override
  State<_RmabConfigSheet> createState() => _RmabConfigSheetState();
}

class _RmabConfigSheetState extends State<_RmabConfigSheet> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _legacyUrlController = TextEditingController();
  final _urlFocus = FocusNode();
  final _tokenFocus = FocusNode();
  final _legacyUrlFocus = FocusNode();

  bool _loadingPrefs = true;
  bool _connecting = false;
  bool _obscureToken = true;
  bool _wasConfigured = false;
  bool _showHeaders = false;
  final List<(TextEditingController, TextEditingController)>
      _headerControllers = [];
  String? _legacyUrl;
  String? _errorText;
  String? _connectedAsName;

  /// Bumped when the user successfully (re)connects or disconnects, so the
  /// My Requests tab knows to refetch.
  int _credsVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    final legacy = await ScopedPrefs.getString(kRmabLegacyUrlKey);
    final headers = await loadRmabCustomHeaders();

    // Migration: if the new base URL isn't set but a legacy URL is, try to
    // extract just the origin so the user only needs to paste a token.
    String prefilledBase = base ?? '';
    if (prefilledBase.isEmpty && legacy != null && legacy.isNotEmpty) {
      final parsed = Uri.tryParse(legacy);
      if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
        prefilledBase =
            '${parsed.scheme}://${parsed.host}${parsed.hasPort ? ':${parsed.port}' : ''}';
      }
    }

    if (!mounted) return;
    setState(() {
      _urlController.text = prefilledBase;
      _tokenController.text = token ?? '';
      _legacyUrlController.text = legacy ?? '';
      _legacyUrl = legacy;
      for (final entry in headers.entries) {
        _headerControllers.add((
          TextEditingController(text: entry.key),
          TextEditingController(text: entry.value),
        ));
      }
      _showHeaders = headers.isNotEmpty;
      _wasConfigured =
          (base ?? '').isNotEmpty && (token ?? '').isNotEmpty;
      _loadingPrefs = false;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _legacyUrlController.dispose();
    _urlFocus.dispose();
    _tokenFocus.dispose();
    _legacyUrlFocus.dispose();
    for (final (k, v) in _headerControllers) {
      k.dispose();
      v.dispose();
    }
    super.dispose();
  }

  Map<String, String> _collectHeaders() {
    final headers = <String, String>{};
    for (final (keyCtrl, valCtrl) in _headerControllers) {
      final k = keyCtrl.text.trim();
      final v = valCtrl.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) headers[k] = v;
    }
    return headers;
  }

  Uri? _parseBaseUrl(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    final u = Uri.tryParse(v);
    if (u == null || u.host.isEmpty) return null;
    if (u.scheme != 'http' && u.scheme != 'https') return null;
    return u;
  }

  Future<void> _connect() async {
    final l = AppLocalizations.of(context)!;

    final baseUri = _parseBaseUrl(_urlController.text);
    if (baseUri == null) {
      debugPrint('[RMAB] connect: invalid URL');
      setState(() => _errorText = l.rmabConfigErrorInvalidUrl);
      return;
    }
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      debugPrint('[RMAB] connect: token field empty');
      setState(() => _errorText = l.rmabConfigErrorMissingToken);
      return;
    }
    debugPrint(
        '[RMAB] connect starting (origin=${baseUri.origin} tokenLen=${token.length})');

    setState(() {
      _connecting = true;
      _errorText = null;
      _connectedAsName = null;
    });

    // Uri.origin gives scheme://host[:port] with no path/query/fragment markers.
    // Don't use Uri.replace(path:'', query:'', fragment:'') here — it preserves
    // empty `?` and `#` in toString(), which then turns appended `/api/...`
    // into a URL fragment that never reaches the server.
    final cleanBase = baseUri.origin;
    final customHeaders = _collectHeaders();

    try {
      final me = await RmabService(
        baseUrl: cleanBase,
        apiToken: token,
        customHeaders: customHeaders,
      ).me();

      await ScopedPrefs.setString(kRmabBaseUrlKey, cleanBase);
      await ScopedPrefs.setString(kRmabApiTokenKey, token);
      if (customHeaders.isNotEmpty) {
        await ScopedPrefs.setString(
            kRmabCustomHeadersKey, jsonEncode(customHeaders));
      } else {
        await ScopedPrefs.remove(kRmabCustomHeadersKey);
      }
      // Legacy URL handling depends on context:
      //   Admin: respect whatever they typed in the legacy URL field.
      //     Non-empty → save it. Empty → clear it. Gives admins explicit
      //     control over the auto-login URL used by "Open in browser view".
      //   Non-admin: legacy URL field isn't exposed. Keep any existing
      //     legacy URL (don't clobber a power-user setup); plant the base
      //     URL if none exists, so the WebView fallback has something to
      //     open (user will just see RMAB's login page).
      if (widget.isAdminContext) {
        final entered = _legacyUrlController.text.trim();
        if (entered.isNotEmpty) {
          await ScopedPrefs.setString(kRmabLegacyUrlKey, entered);
        } else {
          await ScopedPrefs.remove(kRmabLegacyUrlKey);
        }
      } else {
        final existingLegacy =
            await ScopedPrefs.getString(kRmabLegacyUrlKey);
        if (existingLegacy == null || existingLegacy.isEmpty) {
          await ScopedPrefs.setString(kRmabLegacyUrlKey, cleanBase);
        }
      }

      if (!mounted) return;
      debugPrint('[RMAB] connect ok (username=${me.username} role=${me.role})');
      // Refresh the in-memory legacy URL so the "Open in browser view"
      // button below uses the freshly-saved value without requiring a
      // sheet reopen.
      final refreshedLegacy =
          await ScopedPrefs.getString(kRmabLegacyUrlKey);
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connectedAsName = me.username;
        _wasConfigured = true;
        _credsVersion++;
        _legacyUrl = refreshedLegacy;
      });
    } on RmabException catch (e) {
      if (!mounted) return;
      debugPrint('[RMAB] connect failed: ${e.kind} ${e.message}');
      setState(() {
        _connecting = false;
        _errorText = _errorTextFor(e, l);
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[RMAB] connect unexpected error: $e');
      setState(() {
        _connecting = false;
        _errorText = '${l.rmabConfigErrorGeneric}: $e';
      });
    }
  }

  String _errorTextFor(RmabException e, AppLocalizations l) {
    switch (e.kind) {
      case RmabErrorKind.unauthorized:
        return l.rmabConfigErrorUnauthorized;
      case RmabErrorKind.forbidden:
        return l.rmabConfigErrorForbidden;
      case RmabErrorKind.network:
        return l.rmabConfigErrorNetwork;
      case RmabErrorKind.parse:
        return l.rmabConfigErrorGeneric;
      case RmabErrorKind.server:
        return '${l.rmabConfigErrorGeneric}: ${e.message}';
    }
  }

  void _toggleObscureToken() {
    setState(() => _obscureToken = !_obscureToken);
  }

  void _toggleShowHeaders() {
    setState(() => _showHeaders = !_showHeaders);
  }

  void _addHeaderRow() {
    setState(() {
      _headerControllers
          .add((TextEditingController(), TextEditingController()));
    });
  }

  void _removeHeaderRow(int i) {
    setState(() {
      _headerControllers[i].$1.dispose();
      _headerControllers[i].$2.dispose();
      _headerControllers.removeAt(i);
    });
  }

  Future<void> _disconnect() async {
    debugPrint('[RMAB] disconnect: clearing all rmab_* keys + local cache');
    await ScopedPrefs.remove(kRmabBaseUrlKey);
    await ScopedPrefs.remove(kRmabApiTokenKey);
    await ScopedPrefs.remove(kRmabLegacyUrlKey);
    await ScopedPrefs.remove(kRmabCustomHeadersKey);
    RmabLocalRequestCache.clear();
    if (!mounted) return;
    Navigator.of(context).pop(const RmabConfigResult(disconnected: true));
  }

  void _openWebView() {
    final l = AppLocalizations.of(context)!;
    final baseUri = _parseBaseUrl(_urlController.text);
    final fallbackBase = baseUri?.origin;
    final usingLegacy = _legacyUrl != null && _legacyUrl!.isNotEmpty;
    final target = usingLegacy ? _legacyUrl! : (fallbackBase ?? '');
    debugPrint(
        '[RMAB] openWebView (usingLegacy=$usingLegacy target=$target)');
    if (target.isEmpty) {
      setState(() => _errorText = l.rmabConfigErrorInvalidUrl);
      return;
    }
    final nav = contentNavigator(context);
    if (isDesktopWorkspace(context)) {
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    }
    nav.push(MaterialPageRoute(
      builder: (_) => AdminRmabScreen(url: target),
    ));
  }

  Future<void> _openGithub() async {
    await launchUrl(
      Uri.parse(_kRmabGithubUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPrefs) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_wasConfigured) {
      // Tabbed layout: My Requests (default) | Setup
      return _ConfiguredView(
        state: this,
        credsVersion: _credsVersion,
        scrollController: widget.scrollController,
      );
    }
    // First-time connect form (no tabs)
    return _UnconfiguredView(
      state: this,
      scrollController: widget.scrollController,
    );
  }
}

// ─── Unconfigured view (Phase 1 layout, no tabs) ──────────────────

class _UnconfiguredView extends StatelessWidget {
  const _UnconfiguredView({
    required this.state,
    required this.scrollController,
  });
  final _RmabConfigSheetState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(state: state),
            const SizedBox(height: 12),
            _ExplainerBlock(state: state),
            const SizedBox(height: 20),
            _SetupForm(state: state),
          ],
        ),
      ),
    );
  }
}

// ─── Configured view (tabbed) ─────────────────────────────────────

class _ConfiguredView extends StatelessWidget {
  const _ConfiguredView({
    required this.state,
    required this.credsVersion,
    required this.scrollController,
  });
  final _RmabConfigSheetState state;
  final int credsVersion;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    // No fixed SizedBox height here — the parent DraggableScrollableSheet
    // (via showStackableSheet) supplies the bounded space. The My Requests
    // tab's ListView uses [scrollController] so drag-down-when-at-top
    // bubbles up to the sheet for dismissal.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _SheetHeader(state: state),
          ),
          const SizedBox(height: 4),
          TabBar(
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
            tabs: [
              Tab(text: l.rmabMyRequestsTab),
              Tab(text: l.rmabSetupTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MyRequestsTab(
                  key: ValueKey('myrequests-$credsVersion'),
                  state: state,
                  scrollController: scrollController,
                ),
                _SetupTab(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable bits ───────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.state});
  final _RmabConfigSheetState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return Row(children: [
      Icon(Icons.menu_book_rounded, color: cs.primary, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          l.rmabConfigTitle,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ]);
  }
}

class _ExplainerBlock extends StatelessWidget {
  const _ExplainerBlock({required this.state});
  final _RmabConfigSheetState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final explainer = state.widget.isAdminContext
        ? l.rmabConfigExplainerAdmin
        : l.rmabConfigExplainerUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          explainer,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: l.rmabConfigLearnMore,
            style: tt.bodySmall?.copyWith(
              color: cs.primary,
              decoration: TextDecoration.underline,
              decorationColor: cs.primary.withValues(alpha: 0.6),
            ),
            recognizer: TapGestureRecognizer()..onTap = state._openGithub,
          ),
        ),
      ],
    );
  }
}

class _SetupForm extends StatelessWidget {
  const _SetupForm({required this.state});
  final _RmabConfigSheetState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: state._urlController,
          focusNode: state._urlFocus,
          enabled: !state._connecting,
          autocorrect: false,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l.rmabConfigBaseUrlLabel,
            hintText: l.rmabConfigBaseUrlHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => state._tokenFocus.requestFocus(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: state._tokenController,
          focusNode: state._tokenFocus,
          enabled: !state._connecting,
          autocorrect: false,
          obscureText: state._obscureToken,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            labelText: l.rmabConfigTokenLabel,
            hintText: l.rmabConfigTokenHint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(state._obscureToken
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: state._connecting ? null : state._toggleObscureToken,
            ),
          ),
          onSubmitted: (_) {
            if (state.widget.isAdminContext) {
              state._legacyUrlFocus.requestFocus();
            } else {
              state._connect();
            }
          },
        ),
        // Admin-only: web UI login URL with embedded login token, so
        // "Open in browser view" opens already signed in.
        if (state.widget.isAdminContext) ...[
          const SizedBox(height: 12),
          TextField(
            controller: state._legacyUrlController,
            focusNode: state._legacyUrlFocus,
            enabled: !state._connecting,
            autocorrect: false,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l.rmabConfigLegacyUrlLabel,
              hintText: l.rmabConfigLegacyUrlHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => state._connect(),
          ),
          const SizedBox(height: 6),
          Text(
            l.rmabConfigLegacyUrlHelp,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 14),
        InkWell(
          onTap: state._connecting ? null : state._toggleShowHeaders,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(
                state._showHeaders
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                l.loginCustomHttpHeaders,
                style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            ]),
          ),
        ),
        if (state._showHeaders) ...[
          const SizedBox(height: 4),
          Text(
            l.rmabConfigHeadersHelp,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          ...state._headerControllers.asMap().entries.map((entry) {
            final i = entry.key;
            final (keyCtrl, valCtrl) = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: keyCtrl,
                    enabled: !state._connecting,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: l.loginHeaderName,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: valCtrl,
                    enabled: !state._connecting,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: l.loginHeaderValue,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: cs.error.withValues(alpha: 0.8)),
                  onPressed: state._connecting
                      ? null
                      : () => state._removeHeaderRow(i),
                ),
              ]),
            );
          }),
          TextButton.icon(
            onPressed: state._connecting ? null : state._addHeaderRow,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l.loginAddHeader),
          ),
        ],
        if (state._errorText != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.error_outline_rounded, size: 18, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state._errorText!,
                style: tt.bodySmall?.copyWith(color: cs.error),
              ),
            ),
          ]),
        ] else if (state._connectedAsName != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.rmabConfigConnectedAs(state._connectedAsName!),
                style: tt.bodySmall?.copyWith(color: cs.primary),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: state._connecting
                  ? null
                  : () => Navigator.of(context)
                      .pop(_resultForCurrentState(state)),
              child: Text(l.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: state._connecting ? null : state._connect,
              child: state._connecting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(l.rmabConfigConnect),
            ),
          ],
        ),
        if (state._wasConfigured) ...[
          const SizedBox(height: 8),
          const Divider(height: 24),
          Row(children: [
            // The "Open in browser view" button is only useful for reaching
            // RMAB's admin-only surfaces (torrent picker, settings, etc.)
            // that aren't on the API allowlist. Regular users don't need it
            // — the native flows already cover request + status.
            if (state.widget.isAdminContext) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state._connecting ? null : state._openWebView,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                  label: Text(l.rmabConfigOpenWebView),
                ),
              ),
              const SizedBox(width: 12),
            ] else
              const Spacer(),
            TextButton(
              onPressed: state._connecting ? null : state._disconnect,
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: Text(l.rmabConfigDisconnect),
            ),
          ]),
        ],
      ],
    );
  }

  /// If the user changed credentials without a disconnect, signal `changed: true`
  /// so the caller refreshes its tile state.
  RmabConfigResult _resultForCurrentState(_RmabConfigSheetState s) {
    return s._connectedAsName != null
        ? const RmabConfigResult(changed: true)
        : const RmabConfigResult();
  }
}

class _SetupTab extends StatelessWidget {
  const _SetupTab({required this.state});
  final _RmabConfigSheetState state;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExplainerBlock(state: state),
            const SizedBox(height: 20),
            _SetupForm(state: state),
          ],
        ),
      ),
    );
  }
}

// ─── My Requests tab ─────────────────────────────────────────────

class _MyRequestsTab extends StatefulWidget {
  const _MyRequestsTab({
    super.key,
    required this.state,
    required this.scrollController,
  });
  final _RmabConfigSheetState state;
  final ScrollController scrollController;

  @override
  State<_MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<_MyRequestsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _loading = true;
  String? _error;
  RmabRequestsPage? _page;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    debugPrint('[RMAB] my-requests tab fetching');
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    final headers = await loadRmabCustomHeaders();
    if (!mounted) return;
    if (base == null || base.isEmpty || token == null || token.isEmpty) {
      debugPrint('[RMAB] my-requests: no creds, showing error');
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.rmabConfigErrorUnauthorized;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await RmabService(
              baseUrl: base, apiToken: token, customHeaders: headers)
          .listRequests(myOnly: true, take: 50);
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } on RmabException catch (e) {
      if (!mounted) return;
      debugPrint('[RMAB] my-requests error: ${e.kind} ${e.message}');
      setState(() {
        _error = _msgForException(e);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[RMAB] my-requests unexpected: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _msgForException(RmabException e) {
    final l = AppLocalizations.of(context)!;
    switch (e.kind) {
      case RmabErrorKind.unauthorized:
        return l.rmabRequestErrorTokenRejected;
      case RmabErrorKind.network:
        return l.rmabConfigErrorNetwork;
      default:
        return '${l.rmabMyRequestsError}: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        // ── Tab toolbar ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
          child: Row(children: [
            Expanded(
              child: Text(
                _page == null
                    ? ''
                    : _countLabel(_page!.counts.all, l),
                style: tt.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l.rmabMyRequestsRefresh,
              onPressed: _loading ? null : _fetch,
            ),
          ]),
        ),
        Expanded(child: _buildBody(cs, tt, l)),
      ],
    );
  }

  String _countLabel(int n, AppLocalizations l) {
    return n == 1 ? '1 request' : '$n requests';
  }

  Widget _buildBody(
      ColorScheme cs, TextTheme tt, AppLocalizations l) {
    if (_loading) {
      // Wrap the spinner in a scrollable so drag-to-dismiss still works
      // while we're fetching. AlwaysScrollableScrollPhysics ensures the
      // gesture bubbles up to the DraggableScrollableSheet for dismissal.
      return ListView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        children: const [
          Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.error),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.rmabMyRequestsRefresh),
              onPressed: _fetch,
            ),
          ),
        ],
      );
    }
    final requests = _page?.requests ?? const <RmabRequest>[];
    if (requests.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        children: [
          Icon(Icons.inbox_rounded,
              size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l.rmabMyRequestsEmpty,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          16, 4, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestRow(
        request: requests[i],
        onTap: () => _openRequestDetail(requests[i]),
      ),
    );
  }

  void _openRequestDetail(RmabRequest req) {
    showAdaptiveActionMenu<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      desktopWidth: 560,
      builder: (_) => _RequestDetailSheet(request: req),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.onTap});
  final RmabRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final book = request.audiobook;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: (book.coverArtUrl == null ||
                            book.coverArtUrl!.isEmpty)
                        ? Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.menu_book_rounded,
                                color: cs.onSurfaceVariant, size: 20),
                          )
                        : CachedNetworkImage(
                            imageUrl: book.coverArtUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: cs.surfaceContainerHighest),
                            errorWidget: (_, __, ___) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.broken_image_rounded,
                                  color: cs.onSurfaceVariant, size: 20),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (book.author.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(children: [
                        RmabRequestStatusChip(rawStatus: request.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatRelative(request.createdAt),
                            style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.7)),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    final months = diff.inDays ~/ 30;
    if (months < 12) return '${months}mo ago';
    final years = diff.inDays ~/ 365;
    return '${years}y ago';
  }
}

// ─── Request detail sub-sheet ────────────────────────────────────

class _RequestDetailSheet extends StatelessWidget {
  const _RequestDetailSheet({required this.request});
  final RmabRequest request;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final book = request.audiobook;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.rmabRequestDetailTitle,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 88,
                height: 88,
                child: (book.coverArtUrl == null ||
                        book.coverArtUrl!.isEmpty)
                    ? Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.menu_book_rounded,
                            color: cs.onSurfaceVariant, size: 28),
                      )
                    : CachedNetworkImage(
                        imageUrl: book.coverArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: cs.surfaceContainerHighest),
                        errorWidget: (_, __, ___) => Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.broken_image_rounded,
                              color: cs.onSurfaceVariant, size: 28),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (book.author.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(book.author,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                  if (book.narrator != null && book.narrator!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(l.narratedBy(book.narrator!),
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 8),
                  RmabRequestStatusChip(
                      rawStatus: request.status, dense: false),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _kvRow(context, l.rmabRequestDetailRequestedOn,
              _formatDate(request.createdAt)),
          if (request.completedAt != null)
            _kvRow(context, l.rmabRequestDetailCompletedOn,
                _formatDate(request.completedAt!)),
          if (request.statusGroup == RmabStatusGroup.active &&
              request.progress > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.rmabRequestDetailProgress,
                      style: tt.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (request.progress / 100).clamp(0, 1).toDouble(),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          if (request.errorMessage != null &&
              request.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(request.errorMessage!,
                  style: tt.bodySmall?.copyWith(color: cs.onErrorContainer)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kvRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: tt.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: tt.bodyMedium),
        ),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    // YYYY-MM-DD HH:mm in local time, matches the rest of the app's
    // unfussy date rendering.
    String two(int v) => v.toString().padLeft(2, '0');
    final l = dt.toLocal();
    return '${l.year}-${two(l.month)}-${two(l.day)} '
        '${two(l.hour)}:${two(l.minute)}';
  }
}
