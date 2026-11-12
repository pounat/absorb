import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/bookorbit_api_keys.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/bookorbit_pickers.dart';
import '../widgets/overlay_toast.dart';
import 'bookorbit_admin_screen.dart';
import 'bookorbit_api_keys_screen.dart';

/// The server's say over API keys, for people who manage app settings:
/// whether any key works, and how long a new one may last.
class BookOrbitApiKeySettingsScreen extends StatefulWidget {
  const BookOrbitApiKeySettingsScreen({super.key});

  @override
  State<BookOrbitApiKeySettingsScreen> createState() => _BookOrbitApiKeySettingsScreenState();
}

class _BookOrbitApiKeySettingsScreenState extends State<BookOrbitApiKeySettingsScreen> {
  static const _presets = [30, 90, 365];
  static const _maxDays = 3650;

  BoApiKeySettings? _saved;
  bool _enabled = true;
  /// Null for no limit; a preset, or whatever is in the custom field.
  int? _cap;
  bool _custom = false;
  final _customDays = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customDays.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final s = await api.adminApiKeySettings();
      if (!mounted) return;
      setState(() {
        _saved = s;
        _enabled = s.enabled;
        _cap = s.maxLifetimeDays;
        _custom = s.maxLifetimeDays != null && !_presets.contains(s.maxLifetimeDays);
        if (_custom) _customDays.text = '${s.maxLifetimeDays}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showBoApiKeyError(context, e);
    }
  }

  int? get _customValue {
    final n = int.tryParse(_customDays.text.trim());
    return n != null && n >= 1 && n <= _maxDays ? n : null;
  }

  int? get _capToSave => _custom ? _customValue : _cap;

  bool get _dirty {
    final s = _saved;
    if (s == null) return false;
    if (_custom && _customValue == null) return false;
    return s.enabled != _enabled || s.maxLifetimeDays != _capToSave;
  }

  Future<void> _save() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    setState(() => _saving = true);
    try {
      final s = await api.adminSetApiKeySettings(enabled: _enabled, maxLifetimeDays: _capToSave);
      if (!mounted) return;
      setState(() => _saved = s);
      showOverlayToast(context, l.boApiKeySettingsSaved, icon: Icons.check_rounded);
    } catch (e) {
      if (mounted) showBoApiKeyError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    Widget capTile(String label, int? value) => RadioListTile<String>(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(label),
          value: value == null ? 'none' : '$value',
          groupValue: _custom ? 'custom' : (_cap == null ? 'none' : '$_cap'),
          onChanged: _loading
              ? null
              : (_) => setState(() {
                    _custom = false;
                    _cap = value;
                  }),
        );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Row(children: [
            Expanded(child: AbsorbPageHeader(title: l.boApiKeysTitle, padding: const EdgeInsets.only(left: 20))),
            FilledButton(onPressed: _dirty && !_saving ? _save : null, child: Text(l.save)),
            IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
          ]),
          if (_loading || _saving) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(l.boApiKeySettingsIntro, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ),
                BoSection(children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(l.boApiKeySettingsEnabled),
                    subtitle: Text(l.boApiKeySettingsEnabledHint),
                    value: _enabled,
                    onChanged: _loading ? null : (v) => setState(() => _enabled = v),
                  ),
                ]),
                BoSection(title: l.boApiKeySettingsMaxLifetime, hint: l.boApiKeySettingsMaxLifetimeHint, children: [
                  capTile(l.boApiKeySettingsNoLimit, null),
                  for (final d in _presets) capTile(l.boApiKeyExpiryDays(d), d),
                  RadioListTile<String>(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(l.boApiKeySettingsCustom),
                    value: 'custom',
                    groupValue: _custom ? 'custom' : (_cap == null ? 'none' : '$_cap'),
                    onChanged: _loading ? null : (_) => setState(() => _custom = true),
                  ),
                  if (_custom)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
                      child: TextField(
                        controller: _customDays,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: l.boApiKeySettingsCustomDays,
                          errorText: _customDays.text.isNotEmpty && _customValue == null
                              ? l.boApiKeySettingsCustomRange(_maxDays)
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
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
}
