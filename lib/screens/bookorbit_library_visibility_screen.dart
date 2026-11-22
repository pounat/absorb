import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../widgets/overlay_toast.dart';

/// Hide BookOrbit libraries from the reading shelves, Series or Stats. The
/// choice lives on the account, so the web app and Absorb share it.
class BookOrbitLibraryVisibilityScreen extends StatefulWidget {
  const BookOrbitLibraryVisibilityScreen({super.key});

  @override
  State<BookOrbitLibraryVisibilityScreen> createState() => _BookOrbitLibraryVisibilityScreenState();
}

class _BookOrbitLibraryVisibilityScreenState extends State<BookOrbitLibraryVisibilityScreen> {
  Map<String, Set<String>>? _hidden;
  bool _failed = false;

  BookOrbitApiService? get _api {
    final api = context.read<AuthProvider>().apiService;
    return api is BookOrbitApiService ? api : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final hidden = await _api?.libraryVisibility();
      if (mounted) setState(() => _hidden = hidden);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggle(String place, String libraryId, bool hide) async {
    final api = _api;
    final before = _hidden;
    if (api == null || before == null) return;
    final next = {for (final e in before.entries) e.key: {...e.value}};
    hide ? next[place]!.add(libraryId) : next[place]!.remove(libraryId);
    setState(() => _hidden = next);
    final ok = await api.setLibraryVisibility(next);
    if (!mounted) return;
    if (!ok) {
      setState(() => _hidden = before);
      showOverlayToast(context, AppLocalizations.of(context)!.boLibraryVisibilitySaveFailed,
          icon: Icons.error_outline_rounded);
      return;
    }
    // The home shelves and stats come from the server, which now leaves the
    // hidden library out.
    context.read<LibraryProvider>().refresh();
  }

  String _placeLabel(AppLocalizations l, String place) => switch (place) {
        'shelves' => l.boLibraryVisibilityShelves,
        'series' => l.boLibraryVisibilitySeries,
        _ => l.boLibraryVisibilityStats,
      };

  String _placeHint(AppLocalizations l, String place) => switch (place) {
        'shelves' => l.boLibraryVisibilityShelvesDesc,
        'series' => l.boLibraryVisibilitySeriesDesc,
        _ => l.boLibraryVisibilityStatsDesc,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final libraries = context.watch<LibraryProvider>().libraries.whereType<Map>().toList();
    final hidden = _hidden;
    return Scaffold(
      appBar: AppBar(title: Text(l.boLibraryVisibilityTitle)),
      body: hidden == null
          ? Center(
              child: _failed
                  ? TextButton(
                      onPressed: () {
                        setState(() => _failed = false);
                        _load();
                      },
                      child: Text(l.retry),
                    )
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(l.boLibraryVisibilityIntro, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
                for (final place in BookOrbitApiService.libraryVisibilityPlaces)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '${_placeLabel(l, place)}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: _placeHint(l, place)),
                    ]), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                const SizedBox(height: 16),
                for (final lib in libraries)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${lib['name'] ?? ''}', style: tt.titleSmall),
                          const SizedBox(height: 4),
                          for (final place in BookOrbitApiService.libraryVisibilityPlaces)
                            SwitchListTile.adaptive(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(_placeLabel(l, place)),
                              value: !(hidden[place]?.contains('${lib['id']}') ?? false),
                              onChanged: (show) => _toggle(place, '${lib['id']}', !show),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
