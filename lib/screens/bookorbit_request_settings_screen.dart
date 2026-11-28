import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/book_dock.dart';
import '../services/bookorbit_admin.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/bookorbit_pickers.dart';
import '../widgets/overlay_toast.dart';
import 'bookorbit_admin_screen.dart';

/// How BookOrbit handles book requests by itself, for people who manage app
/// settings: downloading without asking, looking again, checking what was
/// downloaded, and where a request goes when nobody says.
class BookOrbitRequestSettingsScreen extends StatefulWidget {
  const BookOrbitRequestSettingsScreen({super.key});

  @override
  State<BookOrbitRequestSettingsScreen> createState() => _BookOrbitRequestSettingsScreenState();
}

class _BookOrbitRequestSettingsScreenState extends State<BookOrbitRequestSettingsScreen> {
  BoRequestSettings? _saved;
  BoRequestSettings _s = const BoRequestSettings();
  List<BookDockDestination> _destinations = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = boAdminApi(context);
    if (api == null) return;
    try {
      final s = await api.adminRequestSettings();
      final destinations = await api.bookDockDestinations();
      if (!mounted) return;
      setState(() {
        _saved = s;
        _s = s;
        _destinations = destinations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showBoAdminError(context, e);
    }
  }

  Map<String, dynamic> get _changes => _saved == null ? const {} : _s.changesFrom(_saved!);

  Future<void> _save() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    setState(() => _saving = true);
    try {
      final s = await api.adminSaveRequestSettings(_changes);
      if (!mounted) return;
      setState(() {
        _saved = s;
        _s = s;
      });
      showOverlayToast(context, l.boSettingsSaved, icon: Icons.check_rounded);
    } catch (e) {
      if (mounted) showBoAdminError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _set(BoRequestSettings s) => setState(() => _s = s);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final ready = _saved != null && !_saving;
    const pad = EdgeInsets.symmetric(horizontal: 4);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Row(children: [
            Expanded(child: AbsorbPageHeader(title: l.boReqSettingsTitle, padding: const EdgeInsets.only(left: 20))),
            FilledButton(onPressed: ready && _changes.isNotEmpty ? _save : null, child: Text(l.save)),
            IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
          ]),
          if (_loading || _saving) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
              BoSection(title: l.boReqAutoSection, children: [
                SwitchListTile(
                  contentPadding: pad,
                  title: Text(l.boReqAutoGrab),
                  subtitle: Text(l.boReqAutoGrabHint),
                  value: _s.autoGrab,
                  onChanged: ready ? (v) => _set(_s.copyWith(autoGrab: v)) : null,
                ),
                BoSliderTile(
                  label: l.boReqAutoGrabScore(_s.autoGrabMinScore),
                  value: _s.autoGrabMinScore,
                  min: BoRequestSettings.minGrabScore,
                  max: 100,
                  enabled: ready && _s.autoGrab,
                  onChanged: (v) => _set(_s.copyWith(autoGrabMinScore: v)),
                ),
                SwitchListTile(
                  contentPadding: pad,
                  title: Text(l.boReqAutoRetry),
                  value: _s.autoRetry,
                  onChanged: ready && _s.autoGrab ? (v) => _set(_s.copyWith(autoRetry: v)) : null,
                ),
                BoSliderTile(
                  label: l.boReqAttempts(_s.maxAttempts),
                  value: _s.maxAttempts,
                  min: 1,
                  max: BoRequestSettings.maxGrabAttempts,
                  enabled: ready && _s.autoGrab && _s.autoRetry,
                  onChanged: (v) => _set(_s.copyWith(maxAttempts: v)),
                ),
              ]),
              BoSection(title: l.boReqSearchSection, children: [
                SwitchListTile(
                  contentPadding: pad,
                  title: Text(l.boReqAutoSearch),
                  subtitle: Text(l.boReqAutoSearchHint),
                  value: _s.autoSearch,
                  onChanged: ready ? (v) => _set(_s.copyWith(autoSearch: v)) : null,
                ),
                BoSliderTile(
                  label: l.boReqSearchInterval(_s.searchIntervalHours),
                  value: _s.searchIntervalHours,
                  min: 1,
                  max: BoRequestSettings.maxSearchIntervalHours,
                  enabled: ready && _s.autoSearch,
                  onChanged: (v) => _set(_s.copyWith(searchIntervalHours: v)),
                ),
                BoSliderTile(
                  label: l.boReqSearchMaxAge(_s.searchMaxAgeDays),
                  value: _s.searchMaxAgeDays,
                  min: 1,
                  max: BoRequestSettings.maxSearchAgeDays,
                  enabled: ready && _s.autoSearch,
                  onChanged: (v) => _set(_s.copyWith(searchMaxAgeDays: v)),
                ),
              ]),
              BoSection(title: l.boReqVerifySection, children: [
                SwitchListTile(
                  contentPadding: pad,
                  title: Text(l.boReqVerify),
                  subtitle: Text(l.boReqVerifyHint),
                  value: _s.verification,
                  onChanged: ready ? (v) => _set(_s.copyWith(verification: v)) : null,
                ),
                BoSliderTile(
                  label: l.boReqVerifyThreshold(_s.verificationThreshold),
                  value: _s.verificationThreshold,
                  min: 0,
                  max: 100,
                  enabled: ready && _s.verification,
                  onChanged: (v) => _set(_s.copyWith(verificationThreshold: v)),
                ),
              ]),
              BoSection(title: l.boReqFormatsSection, children: [
                for (final f in const ['all', 'preferred'])
                  RadioListTile<String>(
                    contentPadding: pad,
                    title: Text(f == 'all' ? l.boReqFormatsAll : l.boReqFormatsPreferred),
                    value: f,
                    groupValue: _s.importFormats,
                    onChanged: ready ? (v) => _set(_s.copyWith(importFormats: v)) : null,
                  ),
              ]),
              BoSection(title: l.boReqDestSection, hint: l.boReqDestHint, children: [
                BoDestinationTile(
                  title: l.boReqDestEbooks,
                  destinations: _destinations,
                  libraryId: _s.ebookLibraryId,
                  folderId: _s.ebookFolderId,
                  noneLabel: l.boDestinationNone,
                  enabled: ready,
                  onChanged: (lib, folder) => _set(_s.copyWith(ebook: (libraryId: lib, folderId: folder))),
                ),
                BoDestinationTile(
                  title: l.boReqDestAudiobooks,
                  destinations: _destinations,
                  libraryId: _s.audiobookLibraryId,
                  folderId: _s.audiobookFolderId,
                  noneLabel: l.boDestinationNone,
                  enabled: ready,
                  onChanged: (lib, folder) => _set(_s.copyWith(audiobook: (libraryId: lib, folderId: folder))),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(l.boReqProfilesNote, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
