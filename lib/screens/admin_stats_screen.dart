import 'package:flutter/material.dart';
import '../widgets/expressive.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/duration_format.dart';
import '../widgets/absorb_page_header.dart';

/// Read-only server-wide statistics: library totals (GET /api/stats/server)
/// and an admin year-in-review (GET /api/stats/year/:year).
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _loading = true;
  bool _loadingYear = false;
  Map<String, dynamic>? _server;
  Map<String, dynamic>? _year;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadAll();
  }

  Future<void> _loadAll() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      api.getServerStats(),
      api.getServerYearStats(_selectedYear),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _server = results[0];
      _year = results[1];
    });
  }

  Future<void> _loadYear(int year) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() {
      _selectedYear = year;
      _loadingYear = true;
    });
    final y = await api.getServerYearStats(year);
    if (!mounted) return;
    setState(() {
      _loadingYear = false;
      _year = y;
    });
  }

  String _fmtBytes(num? bytes) {
    final b = (bytes ?? 0).toDouble();
    if (b <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var v = b;
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    final s = v >= 100 || i == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '$s ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final total = _server?['total'] as Map<String, dynamic>?;
    final books = _server?['books'] as Map<String, dynamic>?;
    final podcasts = _server?['podcasts'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: AdaptiveSpinner(strokeWidth: 2))
            : RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                      child: Row(children: [
                        Expanded(child: AbsorbPageHeader(title: l.adminStats, padding: EdgeInsets.zero)),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Library totals ──
                    _section(cs, tt, l.statsLibraryTotals),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDeco(cs),
                        child: Column(children: [
                          Row(children: [
                            _stat(tt, cs, Icons.menu_book_rounded, '${total?['numItems'] ?? 0}', l.statsTotalItems),
                            _stat(tt, cs, Icons.headphones_rounded, '${total?['numAudioFiles'] ?? 0}', l.statsAudioFiles),
                            _stat(tt, cs, Icons.sd_storage_rounded, _fmtBytes(total?['totalSize'] as num?), l.statsTotalSize),
                          ]),
                          const Divider(height: 24),
                          Row(children: [
                            _stat(tt, cs, Icons.auto_stories_rounded, '${books?['numItems'] ?? 0}', l.statsBooks),
                            _stat(tt, cs, Icons.podcasts_rounded, '${podcasts?['numItems'] ?? 0}', l.statsPodcasts),
                            _stat(tt, cs, Icons.sd_storage_outlined, _fmtBytes(books?['totalSize'] as num?), l.statsBooksSize),
                          ]),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Year in review ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Row(children: [
                        Expanded(child: Text(l.statsYearReview,
                            style: tt.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                        _yearDropdown(cs, tt),
                      ]),
                    ),
                    if (_loadingYear)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: AdaptiveSpinner(strokeWidth: 2)),
                      )
                    else
                      _yearBody(cs, tt, l),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _yearDropdown(ColorScheme cs, TextTheme tt) {
    final now = DateTime.now().year;
    final years = [for (var y = now; y >= now - 6; y--) y];
    return DropdownButton<int>(
      value: _selectedYear,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(12),
      style: tt.titleSmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
      items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
      onChanged: (y) {
        if (y != null && y != _selectedYear) _loadYear(y);
      },
    );
  }

  Widget _yearBody(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final y = _year;
    final listening = (y?['totalListeningTime'] as num?)?.toDouble() ?? 0;
    final sessions = y?['numListeningSessions'] ?? 0;
    final booksAdded = y?['numBooksAdded'] ?? 0;
    final authorsAdded = y?['numAuthorsAdded'] ?? 0;
    final hasAny = listening > 0 || (sessions as num) > 0 || (booksAdded as num) > 0;

    if (!hasAny) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(l.statsNoYearData,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        ),
      );
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(cs),
          child: Row(children: [
            _stat(tt, cs, Icons.timer_rounded, formatHm(listening), l.statsListeningTime),
            _stat(tt, cs, Icons.play_circle_outline_rounded, '$sessions', l.statsSessions),
            _stat(tt, cs, Icons.library_add_rounded, '$booksAdded', l.statsBooksAdded),
            _stat(tt, cs, Icons.person_add_alt_rounded, '$authorsAdded', l.statsAuthorsAdded),
          ]),
        ),
      ),
      const SizedBox(height: 18),
      _topList(cs, tt, l.statsTopAuthors, y?['topAuthors'], 'name'),
      _topList(cs, tt, l.statsTopNarrators, y?['topNarrators'], 'name'),
      _topList(cs, tt, l.statsTopGenres, y?['topGenres'], 'genre'),
    ]);
  }

  Widget _topList(ColorScheme cs, TextTheme tt, String title, dynamic raw, String labelKey) {
    final list = (raw as List?)?.whereType<Map>().toList() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section(cs, tt, title),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: _cardDeco(cs),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: list.map((e) {
              final name = e[labelKey]?.toString() ?? '–';
              final secs = (e['time'] as num?)?.toDouble() ?? 0;
              return ListTile(
                dense: true,
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                trailing: Text(formatHm(secs),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 18),
    ]);
  }

  Widget _section(ColorScheme cs, TextTheme tt, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Text(t,
            style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      );

  BoxDecoration _cardDeco(ColorScheme cs) =>
      BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16));

  Widget _stat(TextTheme tt, ColorScheme cs, IconData ic, String v, String label) =>
      Expanded(
        child: Column(children: [
          Icon(ic, size: 18, color: cs.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 6),
          Text(v, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10)),
        ]),
      );
}
