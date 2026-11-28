import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/book_dock.dart';
import '../services/bookorbit_admin.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/bookorbit_pickers.dart';
import '../widgets/overlay_toast.dart';
import 'bookorbit_admin_screen.dart';

/// What BookOrbit does with a file that lands in the Book Dock, for people
/// who manage the dock: look its details up, add it to a library without
/// asking, or hold everything until someone does.
class BookOrbitDockSettingsScreen extends StatefulWidget {
  const BookOrbitDockSettingsScreen({super.key});

  @override
  State<BookOrbitDockSettingsScreen> createState() => _BookOrbitDockSettingsScreenState();
}

class _BookOrbitDockSettingsScreenState extends State<BookOrbitDockSettingsScreen> {
  BoDockSettings? _saved;
  BoDockSettings _s = const BoDockSettings();
  List<BookDockDestination> _destinations = const [];
  bool _paused = false;
  bool _pausing = false;
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
      final s = await api.adminDockSettings();
      final paused = await api.adminDockPaused();
      final destinations = await api.bookDockDestinations();
      if (!mounted) return;
      setState(() {
        _saved = s;
        _s = s;
        _paused = paused;
        _destinations = destinations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showBoAdminError(context, e);
    }
  }

  bool get _dirty => _saved != null && !_s.sameAs(_saved!);

  Future<void> _save() async {
    final api = boAdminApi(context);
    final l = AppLocalizations.of(context)!;
    if (api == null) return;
    setState(() => _saving = true);
    try {
      final s = await api.adminSaveDockSettings(_s);
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

  /// Pausing is its own switch on the server, so it takes effect at once.
  Future<void> _setPaused(bool paused) async {
    final api = boAdminApi(context);
    if (api == null) return;
    setState(() {
      _paused = paused;
      _pausing = true;
    });
    try {
      final now = await api.adminSetDockPaused(paused);
      if (mounted) setState(() => _paused = now);
    } catch (e) {
      if (!mounted) return;
      setState(() => _paused = !paused);
      showBoAdminError(context, e);
    } finally {
      if (mounted) setState(() => _pausing = false);
    }
  }

  void _set(BoDockSettings s) => setState(() => _s = s);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final ready = _saved != null && !_saving;
    const pad = EdgeInsets.symmetric(horizontal: 4);
    final ownDetailsOnly = _s.detailsMode == 'embedded_only';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Row(children: [
            Expanded(child: AbsorbPageHeader(title: l.boDockSettingsTitle, padding: const EdgeInsets.only(left: 20))),
            FilledButton(onPressed: ready && _dirty ? _save : null, child: Text(l.save)),
            IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
          ]),
          if (_loading || _saving || _pausing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
              BoSection(children: [
                SwitchListTile(
                  contentPadding: pad,
                  title: Text(l.boDockPaused),
                  subtitle: Text(l.boDockPausedHint),
                  value: _paused,
                  onChanged: _saved != null && !_pausing ? _setPaused : null,
                ),
                if (_s.path.isNotEmpty)
                  ListTile(contentPadding: pad, title: Text(l.boDockFolder), subtitle: Text(_s.path)),
              ]),
              BoSection(children: [
                SwitchListTile(
                  contentPadding: pad,
                  title: Text(l.boDockLookUp),
                  subtitle: Text(l.boDockLookUpHint),
                  value: _s.lookUpDetails,
                  onChanged: ready ? (v) => _set(_s.copyWith(lookUpDetails: v)) : null,
                ),
              ]),
              BoSection(title: l.boDockAutoSection, children: [
                SwitchListTile(
                  contentPadding: pad,
                  title: Text(l.boDockAutoFile),
                  subtitle: Text(l.boDockAutoFileHint),
                  value: _s.autoFile,
                  onChanged: ready ? (v) => _set(_s.copyWith(autoFile: v)) : null,
                ),
                BoSliderTile(
                  label: l.boDockAutoThreshold(_s.autoFileThreshold),
                  value: _s.autoFileThreshold,
                  min: BoDockSettings.minFileThreshold,
                  max: 100,
                  enabled: ready && _s.autoFile && !ownDetailsOnly,
                  onChanged: (v) => _set(_s.copyWith(autoFileThreshold: v)),
                ),
                BoDestinationTile(
                  title: l.boDockAutoLibrary,
                  destinations: _destinations,
                  libraryId: _s.libraryId,
                  folderId: _s.folderId,
                  noneLabel: l.boDockAutoLibraryNone,
                  enabled: ready && _s.autoFile,
                  onChanged: (lib, folder) => _set(_s.copyWith(destination: (libraryId: lib, folderId: folder))),
                ),
              ]),
              BoSection(title: l.boDockModeSection, children: [
                for (final mode in const ['safe_merge', 'fetched_only', 'embedded_only'])
                  RadioListTile<String>(
                    contentPadding: pad,
                    title: Text(switch (mode) {
                      'safe_merge' => l.boDockModeSafe,
                      'fetched_only' => l.boDockModeFound,
                      _ => l.boDockModeFile,
                    }),
                    subtitle: mode == 'embedded_only' ? Text(l.boDockModeFileHint) : null,
                    value: mode,
                    groupValue: _s.detailsMode,
                    onChanged: ready && _s.autoFile ? (v) => _set(_s.copyWith(detailsMode: v)) : null,
                  ),
              ]),
              if (_s.autoJoin != null || _s.keepOriginal != null)
                BoSection(title: l.boDockUnsortedSection, children: [
                  if (_s.autoJoin != null)
                    SwitchListTile(
                      contentPadding: pad,
                      title: Text(l.boDockAutoJoin),
                      subtitle: Text(l.boDockAutoJoinHint),
                      value: _s.autoJoin!,
                      onChanged: ready ? (v) => _set(_s.copyWith(autoJoin: v)) : null,
                    ),
                  if (_s.keepOriginal != null)
                    SwitchListTile(
                      contentPadding: pad,
                      title: Text(l.boDockKeepOriginal),
                      subtitle: Text(l.boDockKeepOriginalHint),
                      value: _s.keepOriginal!,
                      onChanged: ready ? (v) => _set(_s.copyWith(keepOriginal: v)) : null,
                    ),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
