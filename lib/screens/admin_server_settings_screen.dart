import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';

/// Server-wide settings editor. Current values are read from
/// AuthProvider.serverSettings (delivered in the login payload; there is no GET
/// endpoint), and saved with PATCH /api/settings. Sorting prefixes have their
/// own endpoint (PATCH /api/sorting-prefixes) and save separately.
class AdminServerSettingsScreen extends StatefulWidget {
  const AdminServerSettingsScreen({super.key});

  @override
  State<AdminServerSettingsScreen> createState() => _AdminServerSettingsScreenState();
}

class _AdminServerSettingsScreenState extends State<AdminServerSettingsScreen> {
  static const _coverProviders = [
    'google', 'openlibrary', 'itunes',
    'audible', 'audible.ca', 'audible.uk', 'audible.au', 'audible.fr',
    'audible.de', 'audible.jp', 'audible.it', 'audible.in', 'audible.es',
    'fantlab', 'audiobookcovers',
  ];
  static const _metadataFormats = ['json', 'abs'];

  bool _saving = false;
  bool _savingPrefixes = false;

  // Scanner
  bool _findCovers = false;
  String _coverProvider = 'google';
  bool _parseSubtitle = false;
  bool _preferMatched = false;
  bool _disableWatcher = false;
  // Storage
  bool _storeCover = false;
  bool _storeMetadata = false;
  String _metadataFormat = 'json';
  // Display & format
  final _dateFormat = TextEditingController();
  final _timeFormat = TextEditingController();
  final _language = TextEditingController();
  bool _chromecast = false;
  bool _allowIframe = false;
  // Sorting
  bool _ignorePrefix = false;
  List<String> _prefixes = [];
  final _newPrefix = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AuthProvider>().serverSettings ?? {};
    _findCovers = s['scannerFindCovers'] as bool? ?? false;
    // Keep the raw provider so an unlisted/custom one isn't silently reset on save.
    _coverProvider = (s['scannerCoverProvider'] as String?) ?? 'google';
    _parseSubtitle = s['scannerParseSubtitle'] as bool? ?? false;
    _preferMatched = s['scannerPreferMatchedMetadata'] as bool? ?? false;
    _disableWatcher = s['scannerDisableWatcher'] as bool? ?? false;
    _storeCover = s['storeCoverWithItem'] as bool? ?? false;
    _storeMetadata = s['storeMetadataWithItem'] as bool? ?? false;
    _metadataFormat = _oneOf(s['metadataFileFormat'], _metadataFormats, 'json');
    _dateFormat.text = (s['dateFormat'] as String?) ?? '';
    _timeFormat.text = (s['timeFormat'] as String?) ?? '';
    _language.text = (s['language'] as String?) ?? '';
    _chromecast = s['chromecastEnabled'] as bool? ?? false;
    _allowIframe = s['allowIframe'] as bool? ?? false;
    _ignorePrefix = s['sortingIgnorePrefix'] as bool? ?? false;
    _prefixes = ((s['sortingPrefixes'] as List?) ?? []).map((e) => e.toString()).toList();
  }

  String _oneOf(dynamic value, List<String> allowed, String fallback) {
    final v = value?.toString();
    return (v != null && allowed.contains(v)) ? v : fallback;
  }

  // Include the current value so a provider outside the built-in list stays selectable.
  List<String> get _coverProviderOptions =>
      _coverProviders.contains(_coverProvider) ? _coverProviders : [_coverProvider, ..._coverProviders];

  @override
  void dispose() {
    _dateFormat.dispose();
    _timeFormat.dispose();
    _language.dispose();
    _newPrefix.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() => {
        'scannerFindCovers': _findCovers,
        'scannerCoverProvider': _coverProvider,
        'scannerParseSubtitle': _parseSubtitle,
        'scannerPreferMatchedMetadata': _preferMatched,
        'scannerDisableWatcher': _disableWatcher,
        'storeCoverWithItem': _storeCover,
        'storeMetadataWithItem': _storeMetadata,
        'metadataFileFormat': _metadataFormat,
        'dateFormat': _dateFormat.text.trim(),
        'timeFormat': _timeFormat.text.trim(),
        'language': _language.text.trim(),
        'chromecastEnabled': _chromecast,
        'allowIframe': _allowIframe,
        'sortingIgnorePrefix': _ignorePrefix,
      };

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    final updated = await api.updateServerSettings(_payload());
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated != null) auth.applyServerSettings(updated);
    showOverlayToast(context, updated != null ? l.srvSaved : l.srvSaveFailed,
        icon: updated != null ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded);
  }

  Future<void> _savePrefixes() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null || _prefixes.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _savingPrefixes = true);
    final updated = await api.updateSortingPrefixes(_prefixes);
    if (!mounted) return;
    setState(() => _savingPrefixes = false);
    if (updated != null) auth.applyServerSettings(updated);
    showOverlayToast(context, updated != null ? l.srvPrefixesSaved : l.srvSaveFailed,
        icon: updated != null ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded);
  }

  void _addPrefix() {
    final p = _newPrefix.text.trim().toLowerCase();
    if (p.isEmpty || _prefixes.contains(p)) return;
    setState(() {
      _prefixes = [..._prefixes, p];
      _newPrefix.clear();
    });
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
              Expanded(child: AbsorbPageHeader(title: l.adminServerSettings, padding: EdgeInsets.zero)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                // ── Scanner ──
                _section(cs, tt, l.srvScannerSection),
                _card(cs, [
                  _switch(cs, tt, l.srvFindCovers, _findCovers, (v) => setState(() => _findCovers = v)),
                  if (_findCovers)
                    _dropdown<String>(cs, tt, l.srvCoverProvider, _coverProvider, _coverProviderOptions,
                        (v) => setState(() => _coverProvider = v)),
                  _switch(cs, tt, l.srvParseSubtitles, _parseSubtitle, (v) => setState(() => _parseSubtitle = v)),
                  _switch(cs, tt, l.srvPreferMatched, _preferMatched, (v) => setState(() => _preferMatched = v)),
                  _switch(cs, tt, l.srvDisableWatcher, _disableWatcher, (v) => setState(() => _disableWatcher = v)),
                ]),
                const SizedBox(height: 24),

                // ── Storage ──
                _section(cs, tt, l.srvStorageSection),
                _card(cs, [
                  _switch(cs, tt, l.srvStoreCover, _storeCover, (v) => setState(() => _storeCover = v)),
                  _switch(cs, tt, l.srvStoreMetadata, _storeMetadata, (v) => setState(() => _storeMetadata = v)),
                  _dropdown<String>(cs, tt, l.srvMetadataFormat, _metadataFormat, _metadataFormats,
                      (v) => setState(() => _metadataFormat = v)),
                ]),
                const SizedBox(height: 24),

                // ── Display & format ──
                _section(cs, tt, l.srvFormatSection),
                _card(cs, [
                  TextField(controller: _dateFormat,
                      decoration: InputDecoration(labelText: l.srvDateFormat, hintText: 'MM/dd/yyyy')),
                  const SizedBox(height: 12),
                  TextField(controller: _timeFormat,
                      decoration: InputDecoration(labelText: l.srvTimeFormat, hintText: 'HH:mm')),
                  const SizedBox(height: 12),
                  TextField(controller: _language,
                      decoration: InputDecoration(labelText: l.srvLanguage, hintText: 'en-us')),
                  _switch(cs, tt, l.srvChromecast, _chromecast, (v) => setState(() => _chromecast = v)),
                  _switch(cs, tt, l.srvAllowIframe, _allowIframe, (v) => setState(() => _allowIframe = v)),
                ]),
                const SizedBox(height: 16),
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
                const SizedBox(height: 28),

                // ── Sorting ──
                _section(cs, tt, l.srvSortingSection),
                _card(cs, [
                  _switch(cs, tt, l.srvIgnorePrefixes, _ignorePrefix, (v) => setState(() => _ignorePrefix = v)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l.srvSortingPrefixes,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final p in _prefixes)
                      Chip(
                        label: Text(p),
                        onDeleted: () => setState(() => _prefixes = _prefixes.where((x) => x != p).toList()),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _newPrefix,
                      decoration: InputDecoration(labelText: l.srvAddPrefix),
                      onSubmitted: (_) => _addPrefix(),
                    )),
                    const SizedBox(width: 8),
                    IconButton(onPressed: _addPrefix, icon: const Icon(Icons.add_rounded)),
                  ]),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _savingPrefixes || _prefixes.isEmpty ? null : _savePrefixes,
                      icon: _savingPrefixes
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 16),
                      label: Text(l.srvSavePrefixes),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _section(ColorScheme cs, TextTheme tt, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Text(t,
            style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      );

  Widget _card(ColorScheme cs, List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      );

  Widget _switch(ColorScheme cs, TextTheme tt, String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: tt.bodyMedium),
        value: value,
        onChanged: onChanged,
      );

  Widget _dropdown<T>(ColorScheme cs, TextTheme tt, String label, T value, List<T> options,
          ValueChanged<T> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Text(label, style: tt.bodyMedium)),
          DropdownButton<T>(
            value: value,
            borderRadius: BorderRadius.circular(12),
            underline: const SizedBox.shrink(),
            items: options
                .map((o) => DropdownMenuItem<T>(value: o, child: Text('$o')))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ]),
      );
}
