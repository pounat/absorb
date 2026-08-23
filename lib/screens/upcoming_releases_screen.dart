import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/rmab_service.dart';
import '../services/scoped_prefs.dart';
import '../services/upcoming_releases_service.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/audible_series_sheet.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/rmab_book_detail_sheet.dart';
import '../widgets/rmab_config_sheet.dart'
    show kRmabBaseUrlKey, kRmabApiTokenKey, loadRmabCustomHeaders;
import '../widgets/series_books_sheet.dart';
import '../widgets/stackable_sheet.dart';
import '../l10n/app_localizations.dart';

class UpcomingReleasesScreen extends StatefulWidget {
  /// Opens the Scan series chooser as soon as the screen is up, for entry
  /// points whose whole purpose is starting a scan (the nav-tab shortcut).
  final bool openScanChooser;
  const UpcomingReleasesScreen({super.key, this.openScanChooser = false});

  @override
  State<UpcomingReleasesScreen> createState() => _UpcomingReleasesScreenState();
}

class _UpcomingReleasesScreenState extends State<UpcomingReleasesScreen> {
  final _service = UpcomingReleasesService();
  String _region = 'us';
  bool _sortByDate = false;
  bool _rmabConfigured = false;
  int _finishedAfterYears = 3;
  int _viewFilter = 0; // 0 = upcoming, 1 = missing
  final Set<String> _selectedAsins = {};
  bool get _selecting => _selectedAsins.isNotEmpty;
  bool _bulkBusy = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _initAndStart();
    _loadRmabConfigured();
    if (widget.openScanChooser) {
      // After the first frame so the sheet has a laid-out screen behind it,
      // and not while a scan the screen kicked off itself is already running.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_service.isRunning) _showScanChooserSheet();
      });
    }
  }

  Future<void> _loadRmabConfigured() async {
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    if (!mounted) return;
    final next =
        (base ?? '').isNotEmpty && (token ?? '').isNotEmpty;
    debugPrint('[RMAB] upcoming: _rmabConfigured=$next');
    if (next != _rmabConfigured) {
      setState(() => _rmabConfigured = next);
    }
  }

  Future<void> _initAndStart() async {
    final saved = await PlayerSettings.getAudibleRegion();
    _region = saved.isNotEmpty ? saved : ApiService.debugRegion;
    _sortByDate = await PlayerSettings.getUpcomingReleasesSortByDate();
    _finishedAfterYears = await PlayerSettings.getUpcomingFinishedAfterYears();
    _service.setRegion(_region);

    // If already running (e.g. came back to this screen), just attach
    if (_service.isRunning) {
      if (mounted) setState(() {});
      return;
    }

    // Try loading cache first
    final hasCache = await _service.loadCache();
    if (mounted) setState(() {});
    if (hasCache) {
      // If cache is stale, prompt for rescan
      if (_service.isCacheStale && mounted) {
        _showStalePrompt();
      }
      return;
    }

    // No cache - start a fresh scan
    _startScan();
  }

  void _startScan({bool deep = false}) {
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    final libraryId = lib.selectedLibraryId;
    if (api == null || libraryId == null) return;

    _service.start(api: api, libraryId: libraryId, region: _region, deep: deep);
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasViewChips =>
      _service.missingResults.isNotEmpty || _service.missingCacheTime != null;

  bool get _showDateChip =>
      _service.isComplete && _service.results.isNotEmpty && _viewFilter == 0;

  Future<void> _changeRegion() async {
    final chosen = await showAudibleRegionPicker(context, currentRegion: _region);
    if (chosen == null || chosen == _region || !mounted) return;

    await PlayerSettings.setAudibleRegion(chosen);
    setState(() => _region = chosen);
    _service.setRegion(chosen);
    _startScan();
  }

  void _rescan() {
    _startScan();
  }

  void _showStalePrompt() {
    final l = AppLocalizations.of(context)!;
    final days = DateTime.now().difference(_service.cacheTime!).inDays;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.upcomingReleasesRescanTitle),
        content: Text(l.upcomingReleasesRescanContent(days)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.upcomingReleasesNotNow)),
          FilledButton(onPressed: () { Navigator.pop(ctx); _rescan(); }, child: Text(l.upcomingReleasesRescan)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  Future<void> _showScanSettingsSheet() async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    const options = [1, 2, 3, 0];
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
              Center(child: Text(l.upcomingReleasesScanSettingsTitle,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
              const SizedBox(height: 16),
              Text(l.upcomingReleasesFinishedAfterTitle,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(l.upcomingReleasesFinishedAfterDesc,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
              const SizedBox(height: 12),
              Row(children: [
                for (final v in options) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        PlayerSettings.setUpcomingFinishedAfterYears(v);
                        setState(() => _finishedAfterYears = v);
                        setSheetState(() {});
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: v == _finishedAfterYears
                              ? cs.primary.withValues(alpha: 0.15)
                              : cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: v == _finishedAfterYears
                              ? cs.primary.withValues(alpha: 0.3)
                              : cs.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: Center(child: Text(
                          v == 0 ? l.upcomingReleasesFinishedAfterNever : l.upcomingReleasesFinishedAfterYears(v),
                          style: TextStyle(
                            color: v == _finishedAfterYears ? cs.primary : cs.onSurfaceVariant,
                            fontSize: 12, fontWeight: FontWeight.w500),
                        )),
                      ),
                    ),
                  ),
                  if (v != options.last) const SizedBox(width: 6),
                ],
              ]),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.visibility_off_rounded, color: cs.primary, size: 22),
                title: Text(l.upcomingReleasesSkippedTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: _service.skippedCount == 0
                    ? Text(l.upcomingReleasesSkippedNone, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))
                    : Text(l.upcomingReleasesSkippedCount(_service.skippedCount),
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                dense: true,
                enabled: _service.skippedCount > 0,
                onTap: _service.skippedCount == 0 ? null : () {
                  Navigator.pop(ctx);
                  _showSkippedSeriesSheet();
                },
              ),
              if (_service.ignoredCount > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.playlist_remove_rounded, color: cs.primary, size: 22),
                  title: Text(l.upcomingReleasesRemovedBooksTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.upcomingReleasesRemovedCount(_service.ignoredCount),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRemovedBooksSheet();
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.language_rounded, color: cs.primary, size: 22),
                title: Text(l.audibleSeriesRegionTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(ApiService.audibleRegions[_region] ?? _region.toUpperCase(),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _changeRegion();
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showSkippedSeriesSheet() {
    showStackableSheet(
      context: context,
      showHandle: true,
      builder: (ctx, scrollController) => _SkippedSeriesSheet(
        scrollController: scrollController,
        region: _region,
      ),
    );
  }

  void _showRemovedBooksSheet() {
    showStackableSheet(
      context: context,
      showHandle: true,
      builder: (ctx, scrollController) => _RemovedBooksSheet(
        scrollController: scrollController,
      ),
    );
  }

  Widget _scanOptionCard(ColorScheme cs, IconData icon, String title, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 24, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }

  Future<void> _showScanChooserSheet() async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final report = _service.lastReport;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
            Center(child: Text(l.upcomingReleasesScanSeries,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            const SizedBox(height: 12),
            if (!_service.hasScanKnowledge)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.upcomingReleasesFirstScanNote,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
                ]),
              ),
            _scanOptionCard(cs, Icons.event_rounded,
              l.upcomingReleasesScanUpcomingOption,
              l.upcomingReleasesScanUpcomingOptionDesc, () {
              Navigator.pop(ctx);
              setState(() => _viewFilter = 0);
              _startScan();
            }),
            _scanOptionCard(cs, Icons.travel_explore_rounded,
              l.upcomingReleasesScanDeepOption,
              l.upcomingReleasesScanDeepOptionDesc, () {
              Navigator.pop(ctx);
              setState(() => _viewFilter = 1);
              _startScan(deep: true);
            }),
            if (report != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.receipt_long_rounded, color: cs.primary, size: 22),
                title: Text(l.upcomingReleasesLastScanReport,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(
                  report.deep
                      ? l.upcomingReleasesReportFoundDeep(report.upcoming, report.recent, report.missing)
                      : l.upcomingReleasesReportFound(report.upcoming, report.recent),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                dense: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _showScanReportSheet();
                },
              ),
          ]),
        ),
      ),
    );
  }

  Widget _reportRow(ColorScheme cs, IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: color ?? cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: cs.onSurface))),
      ]),
    );
  }

  String _reportNames(List<String> names) {
    final l = AppLocalizations.of(context)!;
    const cap = 12;
    if (names.length <= cap) return names.join(', ');
    return '${names.take(cap).join(', ')} ${l.upcomingReleasesReportMore(names.length - cap)}';
  }

  Future<void> _showScanReportSheet() async {
    final report = _service.lastReport;
    if (report == null) return;
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final age = DateTime.now().difference(report.completedAt).inDays;
    final ageLabel = age == 0
        ? l.upcomingReleasesScannedToday
        : age == 1
            ? l.upcomingReleasesScannedYesterday
            : l.upcomingReleasesScannedDaysAgo(age);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
              Center(child: Text(l.upcomingReleasesLastScanReport,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
              const SizedBox(height: 2),
              Center(child: Text(
                report.deep ? '${l.upcomingReleasesScanDeepOption} - $ageLabel' : ageLabel,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11))),
              const SizedBox(height: 12),
              _reportRow(cs, Icons.check_circle_outline_rounded,
                l.upcomingReleasesReportChecked(report.checked)),
              _reportRow(cs, Icons.visibility_off_rounded,
                l.upcomingReleasesReportSkipped(report.skipped)),
              _reportRow(cs, Icons.event_available_rounded,
                report.deep
                    ? l.upcomingReleasesReportFoundDeep(report.upcoming, report.recent, report.missing)
                    : l.upcomingReleasesReportFound(report.upcoming, report.recent),
                color: cs.primary),
              _reportRow(cs, Icons.help_outline_rounded,
                l.upcomingReleasesReportUnmatched(report.unmatchedNames.length)),
              if (report.unmatchedNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 28, bottom: 6),
                  child: Text(_reportNames(report.unmatchedNames),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ),
              _reportRow(cs, Icons.error_outline_rounded,
                l.upcomingReleasesReportFailed(report.failedNames.length),
                color: report.failedNames.isEmpty ? null : cs.error),
              if (report.failedNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(_reportNames(report.failedNames),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr, AppLocalizations l) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final monthName = _monthShort(date.month, l);
    return l.upcomingReleasesDateFormat(monthName, date.day, date.year);
  }

  String _monthShort(int m, AppLocalizations l) {
    switch (m) {
      case 1: return l.statsScreenMonthJan;
      case 2: return l.statsScreenMonthFeb;
      case 3: return l.statsScreenMonthMar;
      case 4: return l.statsScreenMonthApr;
      case 5: return l.statsScreenMonthMay;
      case 6: return l.statsScreenMonthJun;
      case 7: return l.statsScreenMonthJul;
      case 8: return l.statsScreenMonthAug;
      case 9: return l.statsScreenMonthSep;
      case 10: return l.statsScreenMonthOct;
      case 11: return l.statsScreenMonthNov;
      case 12: return l.statsScreenMonthDec;
    }
    return '';
  }

  String _formatRuntime(dynamic minutes, AppLocalizations l) {
    final mins = (minutes is num) ? minutes.toInt() : 0;
    if (mins <= 0) return '';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return l.statsScreenDurationHm(h, m);
    if (h > 0) return l.statsScreenDurationShortH(h);
    return l.statsScreenDurationShortM(m);
  }

  /// Find which series bucket on the page holds this book, for actions that
  /// need the series' identity (like opening the Audible series sheet).
  ({String seriesId, String audibleAsin})? _seriesContextFor(String asin) {
    if (asin.isEmpty) return null;
    for (final r in _service.results) {
      if (r.upcomingBooks.any((b) => b['asin'] == asin) ||
          r.recentBooks.any((b) => b['asin'] == asin)) {
        return (seriesId: r.seriesId, audibleAsin: r.audibleAsin);
      }
    }
    for (final r in _service.missingResults) {
      if (r.missingBooks.any((b) => b['asin'] == asin)) {
        return (seriesId: r.seriesId, audibleAsin: r.audibleAsin);
      }
    }
    return null;
  }

  void _showBookMenu(Map<String, dynamic> book, String seriesName,
      {bool isUpcoming = false}) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isOwned = book['_owned'] == true;
    final seriesContext = _seriesContextFor(book['asin'] as String? ?? '');
    // Show the RMAB request entry only for books that have been released but
    // aren't in the library yet, and only when the user has RMAB configured.
    final showRequest = _rmabConfigured && !isOwned && !isUpcoming;
    showAudibleBookMenu(context,
      book: book,
      seriesName: seriesName,
      region: _region,
      extraActions: [
        if (seriesContext != null && seriesContext.seriesId.isNotEmpty)
          ListTile(
            leading: Icon(Icons.collections_bookmark_rounded, color: cs.primary, size: 22),
            title: Text(l.upcomingReleasesOpenLibrarySeries,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(context);
              final auth = context.read<AuthProvider>();
              final lib = context.read<LibraryProvider>();
              showSeriesBooksSheet(context,
                seriesName: seriesName,
                seriesId: seriesContext.seriesId,
                serverUrl: auth.serverUrl,
                token: auth.token,
                libraryId: lib.selectedLibraryId,
              );
            },
          ),
        ListTile(
          leading: Icon(Icons.refresh_rounded, color: cs.primary, size: 22),
          title: Text(l.upcomingReleasesRescanReleaseDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          dense: true, visualDensity: VisualDensity.compact,
          onTap: () {
            Navigator.pop(context);
            _rescanBook(book['asin'] as String? ?? '');
          },
        ),
        if (showRequest)
          ListTile(
            leading: Icon(Icons.menu_book_rounded, color: cs.primary, size: 22),
            title: Text(l.rmabRequestCta,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            dense: true,
            visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(context);
              final asin = book['asin'] as String? ?? '';
              final title = book['title'] as String? ?? '';
              debugPrint(
                  '[RMAB] upcoming Request tapped (asin=$asin title="$title")');
              showRmabBookDetailSheet(
                context,
                book: RmabSearchResult.fromUpcomingBookMap(book),
              );
            },
          ),
        ListTile(
          leading: Icon(Icons.playlist_remove_rounded, color: cs.error, size: 22),
          title: Text(l.upcomingReleasesRemoveFromList, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          dense: true, visualDensity: VisualDensity.compact,
          onTap: () {
            Navigator.pop(context);
            _removeBook(book['asin'] as String? ?? '');
          },
        ),
      ],
    );
  }

  Future<void> _removeBook(String asin) async {
    final l = AppLocalizations.of(context)!;
    final forever = await _askRemoveMode(count: 1);
    if (forever == null || !mounted) return;
    await _service.removeBook(asin, forever: forever);
    if (!mounted) return;
    showOverlayToast(context,
        forever ? l.upcomingReleasesRemovedForeverToast : l.upcomingReleasesRemovedFromList,
        icon: Icons.playlist_remove_rounded);
  }

  /// null = cancelled, false = this scan only, true = this and future scans.
  Future<bool?> _askRemoveMode({required int count}) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 12),
            decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
          Text(l.upcomingReleasesRemoveTitle(count),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.playlist_remove_rounded, color: cs.primary, size: 22),
            title: Text(l.upcomingReleasesRemoveThisScan,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(l.upcomingReleasesRemoveThisScanDesc,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () => Navigator.pop(ctx, false),
          ),
          ListTile(
            leading: Icon(Icons.block_rounded, color: cs.error, size: 22),
            title: Text(l.upcomingReleasesRemoveForever,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(l.upcomingReleasesRemoveForeverDesc,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  /// All books currently on the page, keyed by ASIN, for multi-select.
  Map<String, ({Map<String, dynamic> book, bool isUpcoming})> _selectableBooks() {
    final map = <String, ({Map<String, dynamic> book, bool isUpcoming})>{};
    for (final r in _service.results) {
      for (final b in r.upcomingBooks) {
        final a = b['asin'] as String? ?? '';
        if (a.isNotEmpty) map[a] = (book: b, isUpcoming: true);
      }
      for (final b in r.recentBooks) {
        final a = b['asin'] as String? ?? '';
        if (a.isNotEmpty) map[a] = (book: b, isUpcoming: false);
      }
    }
    for (final r in _service.missingResults) {
      for (final b in r.missingBooks) {
        final a = b['asin'] as String? ?? '';
        if (a.isNotEmpty) map.putIfAbsent(a, () => (book: b, isUpcoming: false));
      }
    }
    return map;
  }

  void _toggleSelected(String asin) {
    if (asin.isEmpty) return;
    setState(() {
      if (!_selectedAsins.remove(asin)) _selectedAsins.add(asin);
    });
  }

  Future<void> _bulkRemove() async {
    final l = AppLocalizations.of(context)!;
    final forever = await _askRemoveMode(count: _selectedAsins.length);
    if (forever == null || !mounted) return;
    setState(() => _bulkBusy = true);
    final asins = List.of(_selectedAsins);
    for (final a in asins) {
      await _service.removeBook(a, forever: forever);
    }
    if (!mounted) return;
    setState(() {
      _bulkBusy = false;
      _selectedAsins.clear();
    });
    showOverlayToast(context, l.upcomingReleasesBulkRemoved(asins.length),
        icon: Icons.playlist_remove_rounded);
  }

  Future<void> _bulkRequest() async {
    final l = AppLocalizations.of(context)!;
    final books = _selectableBooks();
    final targets = <Map<String, dynamic>>[
      for (final a in _selectedAsins)
        if (books[a] != null && !books[a]!.isUpcoming && books[a]!.book['_owned'] != true)
          books[a]!.book,
    ];
    if (targets.isEmpty) return;
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    final headers = await loadRmabCustomHeaders();
    if (!mounted) return;
    if (base == null || base.isEmpty || token == null || token.isEmpty) {
      showOverlayToast(context, l.rmabRequestErrorTokenRejected, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _bulkBusy = true);
    final rmab = RmabService(baseUrl: base, apiToken: token, customHeaders: headers);
    var sent = 0;
    var skipped = 0;
    for (final book in targets) {
      try {
        final result = await rmab.createRequest(
            RmabRequestInput.fromSearchResult(RmabSearchResult.fromUpcomingBookMap(book)));
        if (result is RmabCreateSuccess) {
          RmabLocalRequestCache.markRequested(
              book['asin'] as String? ?? '', result.request.status);
          sent++;
        } else {
          skipped++;
        }
      } catch (e) {
        debugPrint('[RMAB] bulk request error: $e');
        skipped++;
      }
    }
    if (!mounted) return;
    setState(() {
      _bulkBusy = false;
      _selectedAsins.clear();
    });
    showOverlayToast(context,
        skipped == 0
            ? l.upcomingReleasesBulkRequestDone(sent)
            : '${l.upcomingReleasesBulkRequestDone(sent)} - ${l.upcomingReleasesBulkRequestSkipped(skipped)}',
        icon: sent > 0 ? Icons.check_rounded : Icons.error_outline_rounded);
  }

  Future<void> _rescanBook(String asin) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    final libraryId = lib.selectedLibraryId;
    showOverlayToast(context, l.upcomingReleasesRescanning, icon: Icons.refresh_rounded);
    final updated = await _service.rescanBook(asin, api: api, libraryId: libraryId);
    if (!mounted) return;
    if (updated != null) {
      final newDate = updated['releaseDate'] as String? ?? '';
      if (newDate.isNotEmpty) {
        showOverlayToast(context, l.upcomingReleasesUpdatedWithDate(_formatDate(newDate, l)), icon: Icons.check_rounded);
      } else {
        showOverlayToast(context, l.upcomingReleasesNoReleaseDateFound, icon: Icons.info_outline_rounded);
      }
    } else {
      showOverlayToast(context, l.upcomingReleasesRescanFailed, icon: Icons.error_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      bottomNavigationBar: _selecting ? _buildSelectionBar(cs, tt, l) : null,
      body: SafeArea(
        child: Column(
          children: [
            AbsorbPageHeader(
              title: l.upcomingReleasesTitle,
              actions: [
                // Scan chooser (only when not already scanning)
                if (!_service.isRunning)
                  GestureDetector(
                    onTap: _showScanChooserSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.refresh_rounded, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(l.upcomingReleasesScanSeries,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                      ]),
                    ),
                  ),
                // Scan settings
                GestureDetector(
                  onTap: _showScanSettingsSheet,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.tune_rounded, size: 18, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),

            // Progress indicator
            if (_service.isRunning) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _service.totalSeries > 0
                            ? _service.processedCount / _service.totalSeries
                            : null,
                        minHeight: 3,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _service.currentSeriesName != null
                          ? l.upcomingReleasesCheckingSeries(_service.currentSeriesName!, _service.processedCount, _service.totalSeries)
                          : l.upcomingReleasesLoadingSeries,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],

            // Summary when complete
            if (_service.isComplete)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  Flexible(
                    child: Text(
                      _buildSummary(l),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_service.hasCachedResults && _service.cacheTime != null) ...[
                    const SizedBox(width: 6),
                    Text(_cacheAgeLabel(l), style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11)),
                  ],
                  if (_service.skippedCount > 0) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _showSkippedSeriesSheet,
                      child: Text(
                        l.upcomingReleasesSkippedCount(_service.skippedCount),
                        style: tt.bodySmall?.copyWith(
                          color: cs.primary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ]),
              ),

            // View toggle (once a deep scan exists) + date sort, on their own
            // row so the header actions keep full-size touch targets
            if (_hasViewChips || _showDateChip)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(children: [
                  if (_hasViewChips) ...[
                    _viewChip(cs, l.upcomingReleasesChipUpcoming, _viewFilter == 0,
                        () => setState(() => _viewFilter = 0)),
                    const SizedBox(width: 8),
                    _viewChip(cs, l.upcomingReleasesChipMissing(_service.missingBookCount),
                        _viewFilter == 1, () => setState(() => _viewFilter = 1)),
                  ],
                  const Spacer(),
                  if (_showDateChip)
                    GestureDetector(
                      onTap: () {
                        final next = !_sortByDate;
                        setState(() => _sortByDate = next);
                        PlayerSettings.setUpcomingReleasesSortByDate(next);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: _sortByDate ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: _sortByDate ? Border.all(color: cs.primary.withValues(alpha: 0.3)) : null,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.calendar_today_rounded, size: 13,
                            color: _sortByDate ? cs.primary : cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(l.upcomingReleasesDateChip, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: _sortByDate ? cs.primary : cs.onSurfaceVariant)),
                        ]),
                      ),
                    ),
                ]),
              ),

            const SizedBox(height: 8),

            // Results list
            Expanded(
              child: _buildContent(cs, tt, l),
            ),
          ],
        ),
      ),
    );
  }

  String _cacheAgeLabel(AppLocalizations l) {
    final age = DateTime.now().difference(_service.cacheTime!);
    if (age.inDays == 0) return l.upcomingReleasesScannedToday;
    if (age.inDays == 1) return l.upcomingReleasesScannedYesterday;
    return l.upcomingReleasesScannedDaysAgo(age.inDays);
  }

  String _buildSummary(AppLocalizations l) {
    final totalUpcoming = _service.results.fold<int>(0, (sum, r) => sum + r.upcomingBooks.length);
    final totalRecent = _service.results.fold<int>(0, (sum, r) => sum + r.recentBooks.length);
    final parts = <String>[];
    if (totalUpcoming > 0) parts.add(l.upcomingReleasesUpcomingCount(totalUpcoming));
    if (totalRecent > 0) parts.add(l.upcomingReleasesRecentCount(totalRecent));
    if (parts.isEmpty) return l.upcomingReleasesNoneFound;
    final seriesCount = _service.results.length;
    return l.upcomingReleasesAcrossSeries(parts.join(', '), seriesCount);
  }

  Widget _buildContent(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    if (_service.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(_service.error!, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    if (_viewFilter == 1) {
      return _buildMissingList(cs, tt, l);
    }

    if (_service.isComplete && _service.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_available_rounded, size: 48, color: cs.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(l.upcomingReleasesNoneFound, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(l.upcomingReleasesCheckedSeries(_service.totalSeries),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
              textAlign: TextAlign.center),
            if (_service.skippedCount > 0) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _showSkippedSeriesSheet,
                child: Text(l.upcomingReleasesSkippedCount(_service.skippedCount),
                  style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              ),
            ],
          ]),
        ),
      );
    }

    if (!_service.isRunning && !_service.isComplete && _service.results.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_sortByDate && !_service.isRunning) {
      return _buildDateSortedList(cs, tt, l);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _service.results.length + (_service.isRunning ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _service.results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _buildSeriesSection(cs, tt, l, _service.results[index]);
      },
    );
  }

  Widget _buildSelectionBar(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final books = _selectableBooks();
    final requestable = _rmabConfigured
        ? _selectedAsins.where((a) {
            final e = books[a];
            return e != null && !e.isUpcoming && e.book['_owned'] != true;
          }).length
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
          child: Row(children: [
            Text(l.upcomingReleasesSelectedCount(_selectedAsins.length),
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_bulkBusy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              if (_rmabConfigured)
                TextButton.icon(
                  onPressed: requestable == 0 ? null : _bulkRequest,
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(l.upcomingReleasesBulkRequest),
                ),
              TextButton.icon(
                onPressed: _bulkRemove,
                icon: const Icon(Icons.playlist_remove_rounded, size: 18),
                label: Text(l.upcomingReleasesBulkRemove),
              ),
            ],
            IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
              onPressed: _bulkBusy ? null : () => setState(() => _selectedAsins.clear()),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _viewChip(ColorScheme cs, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? cs.primary.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.1)),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? cs.primary : cs.onSurfaceVariant,
          fontSize: 12, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }

  Widget _buildMissingList(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    final results = _service.missingResults;
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_service.isRunning) ...[
              const CircularProgressIndicator(strokeWidth: 2),
            ] else ...[
              Icon(Icons.check_circle_outline_rounded, size: 48, color: cs.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(l.upcomingReleasesNoMissing,
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            ],
          ]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: results.length + (_service.isRunning ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final r = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Row(children: [
                  Expanded(
                    child: Text(r.seriesName,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${r.missingBooks.length}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.error)),
                  ),
                ]),
              ),
              ...r.missingBooks.map((book) =>
                  _buildBookCard(cs, tt, l, book, r.seriesName, isUpcoming: false, seriesAsin: r.audibleAsin)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSortedList(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    // Flatten all books with their series name and upcoming/recent status
    final allBooks = <({Map<String, dynamic> book, String seriesName, bool isUpcoming, String seriesAsin})>[];
    for (final result in _service.results) {
      for (final book in result.upcomingBooks) {
        allBooks.add((book: book, seriesName: result.seriesName, isUpcoming: true, seriesAsin: result.audibleAsin));
      }
      for (final book in result.recentBooks) {
        allBooks.add((book: book, seriesName: result.seriesName, isUpcoming: false, seriesAsin: result.audibleAsin));
      }
    }

    // Sort by release date (soonest first for upcoming, most recent first for recent)
    allBooks.sort((a, b) {
      final dateA = DateTime.tryParse(a.book['releaseDate'] as String? ?? '') ?? DateTime(2099);
      final dateB = DateTime.tryParse(b.book['releaseDate'] as String? ?? '') ?? DateTime(2099);
      return dateA.compareTo(dateB);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: allBooks.length,
      itemBuilder: (context, index) {
        final entry = allBooks[index];
        return _buildDateSortedCard(cs, tt, l, entry.book, entry.seriesName, entry.isUpcoming, entry.seriesAsin);
      },
    );
  }

  Widget _buildDateSortedCard(ColorScheme cs, TextTheme tt, AppLocalizations l, Map<String, dynamic> book, String seriesName, bool isUpcoming, String seriesAsin) {
    final title = book['title'] as String? ?? '';
    final subtitle = book['subtitle'] as String? ?? '';
    final authors = book['authors'] as String? ?? '';
    final sequence = book['sequence'] as String? ?? '';
    final coverUrl = book['coverUrl'] as String? ?? '';
    final releaseDate = book['releaseDate'] as String? ?? '';
    final runtime = _formatRuntime(book['runtimeMinutes'], l);
    final isOwned = book['_owned'] == true;
    final isNew = book['_new'] == true;
    final selected = _selectedAsins.contains(book['asin'] as String? ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadGreen = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _selecting
            ? _toggleSelected(book['asin'] as String? ?? '')
            : _showBookMenu(book, seriesName, isUpcoming: isUpcoming),
        onLongPress: () => _toggleSelected(book['asin'] as String? ?? ''),
        child: Card(
          elevation: 0,
          color: isUpcoming
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : isOwned
                  ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
                  : cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: selected
                ? BorderSide(color: cs.primary, width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Cover
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(children: [
                    Positioned.fill(
                      child: coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: coverUrl, fit: BoxFit.cover,
                              placeholder: (_, __) => _placeholder(cs),
                              errorWidget: (_, __, ___) => _placeholder(cs))
                          : _placeholder(cs),
                    ),
                    if (sequence.isNotEmpty)
                      Positioned(top: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
                          child: Text(l.upcomingReleasesSequenceLabel(sequence), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (isNew)
                      Positioned(top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
                          child: Text(l.upcomingReleasesBadgeNew, style: TextStyle(color: cs.onTertiary, fontSize: 8, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (selected)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: Center(child: Icon(Icons.check_circle_rounded, color: cs.primary, size: 32)),
                        ),
                      ),
                    if (isUpcoming)
                      Positioned(bottom: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
                          child: Text(l.upcomingReleasesBadgeUpcoming, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (!isUpcoming)
                      Positioned(bottom: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOwned ? downloadGreen.withValues(alpha: 0.9) : cs.error.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(isOwned ? l.upcomingReleasesBadgeAdded : l.upcomingReleasesBadgeMissing,
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ]),
                ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Series name label
                      Text(seriesName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11)),
                        ),
                      const SizedBox(height: 4),
                      if (authors.isNotEmpty)
                        Text(authors, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
                      const SizedBox(height: 4),
                      Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                        if (releaseDate.isNotEmpty) ...[
                          Icon(isUpcoming ? Icons.event_rounded : Icons.calendar_today_rounded,
                            size: 11, color: isUpcoming ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(_formatDate(releaseDate, l),
                            style: TextStyle(fontSize: 10,
                              fontWeight: isUpcoming ? FontWeight.w600 : FontWeight.w400,
                              color: isUpcoming ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5))),
                        ],
                        if (releaseDate.isNotEmpty && runtime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('.', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 10)),
                          ),
                        if (runtime.isNotEmpty) ...[
                          Icon(Icons.schedule_rounded, size: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(runtime, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                        ],
                        if (seriesAsin.isNotEmpty) ...[
                          if (releaseDate.isNotEmpty || runtime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('.', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 10)),
                            ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: seriesAsin));
                              showOverlayToast(context, l.upcomingReleasesAsinCopied, icon: Icons.copy_rounded);
                            },
                            child: Text(seriesAsin,
                              style: TextStyle(fontSize: 10, letterSpacing: 0.3,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesSection(ColorScheme cs, TextTheme tt, AppLocalizations l, UpcomingSeriesResult result) {
    final totalCount = result.upcomingBooks.length + result.recentBooks.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Series header
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(children: [
              Expanded(
                child: Text(
                  result.seriesName,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalCount',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
                ),
              ),
            ]),
          ),
          // Upcoming books
          ...result.upcomingBooks.map((book) => _buildBookCard(cs, tt, l, book, result.seriesName, isUpcoming: true, seriesAsin: result.audibleAsin)),
          // Recent releases
          ...result.recentBooks.map((book) => _buildBookCard(cs, tt, l, book, result.seriesName, isUpcoming: false, seriesAsin: result.audibleAsin)),
        ],
      ),
    );
  }

  Widget _buildBookCard(ColorScheme cs, TextTheme tt, AppLocalizations l, Map<String, dynamic> book, String seriesName, {required bool isUpcoming, String seriesAsin = ''}) {
    final title = book['title'] as String? ?? '';
    final subtitle = book['subtitle'] as String? ?? '';
    final authors = book['authors'] as String? ?? '';
    final narrators = book['narrators'] as String? ?? '';
    final sequence = book['sequence'] as String? ?? '';
    final coverUrl = book['coverUrl'] as String? ?? '';
    final releaseDate = book['releaseDate'] as String? ?? '';
    final runtime = _formatRuntime(book['runtimeMinutes'], l);
    final isOwned = book['_owned'] == true;
    final isNew = book['_new'] == true;
    final selected = _selectedAsins.contains(book['asin'] as String? ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadGreen = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _selecting
            ? _toggleSelected(book['asin'] as String? ?? '')
            : _showBookMenu(book, seriesName, isUpcoming: isUpcoming),
        onLongPress: () => _toggleSelected(book['asin'] as String? ?? ''),
        child: Card(
          elevation: 0,
          color: isUpcoming
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : isOwned
                  ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
                  : cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: selected
                ? BorderSide(color: cs.primary, width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Cover
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(children: [
                    Positioned.fill(
                      child: coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: coverUrl, fit: BoxFit.cover,
                              placeholder: (_, __) => _placeholder(cs),
                              errorWidget: (_, __, ___) => _placeholder(cs))
                          : _placeholder(cs),
                    ),
                    if (sequence.isNotEmpty)
                      Positioned(top: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
                          child: Text(l.upcomingReleasesSequenceLabel(sequence), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (isNew)
                      Positioned(top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
                          child: Text(l.upcomingReleasesBadgeNew, style: TextStyle(color: cs.onTertiary, fontSize: 8, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (selected)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: Center(child: Icon(Icons.check_circle_rounded, color: cs.primary, size: 32)),
                        ),
                      ),
                    if (isUpcoming)
                      Positioned(bottom: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
                          child: Text(l.upcomingReleasesBadgeUpcoming, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (!isUpcoming)
                      Positioned(bottom: 4, left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOwned
                                ? downloadGreen.withValues(alpha: 0.9)
                                : cs.error.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOwned ? l.upcomingReleasesBadgeAdded : l.upcomingReleasesBadgeMissing,
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11)),
                        ),
                      const SizedBox(height: 6),
                      if (authors.isNotEmpty)
                        Text(authors, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
                      if (narrators.isNotEmpty)
                        Text(l.narratedBy(narrators), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10)),
                      const SizedBox(height: 4),
                      Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                        if (releaseDate.isNotEmpty) ...[
                          Icon(isUpcoming ? Icons.event_rounded : Icons.calendar_today_rounded,
                            size: 11, color: isUpcoming ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(_formatDate(releaseDate, l),
                            style: TextStyle(fontSize: 10,
                              fontWeight: isUpcoming ? FontWeight.w600 : FontWeight.w400,
                              color: isUpcoming ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5))),
                        ],
                        if (releaseDate.isNotEmpty && runtime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('.', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 10)),
                          ),
                        if (runtime.isNotEmpty) ...[
                          Icon(Icons.schedule_rounded, size: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(runtime, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                        ],
                        if (seriesAsin.isNotEmpty) ...[
                          if (releaseDate.isNotEmpty || runtime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('.', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 10)),
                            ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: seriesAsin));
                              showOverlayToast(context, l.upcomingReleasesAsinCopied, icon: Icons.copy_rounded);
                            },
                            child: Text(seriesAsin,
                              style: TextStyle(fontSize: 10, letterSpacing: 0.3,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(child: Icon(Icons.auto_stories_rounded, color: cs.onSurface.withValues(alpha: 0.15), size: 28)),
    );
  }
}

/// Bottom sheet listing forever-removed books, with restore.
class _RemovedBooksSheet extends StatefulWidget {
  final ScrollController scrollController;

  const _RemovedBooksSheet({required this.scrollController});

  @override
  State<_RemovedBooksSheet> createState() => _RemovedBooksSheetState();
}

class _RemovedBooksSheetState extends State<_RemovedBooksSheet> {
  final _service = UpcomingReleasesService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _restore(IgnoredBook entry) async {
    final l = AppLocalizations.of(context)!;
    final visible = await _service.restoreBook(entry.asin);
    if (!mounted) return;
    showOverlayToast(
      context,
      visible ? l.upcomingReleasesRestoredToast : l.upcomingReleasesRestoredNextScan,
      icon: Icons.restore_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final entries = _service.ignoredBooks;

    return ClipRect(child: Column(
      children: [
        Icon(Icons.playlist_remove_rounded, size: 20, color: cs.primary),
        const SizedBox(height: 4),
        Text(l.upcomingReleasesRemovedBooksTitle,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(l.upcomingReleasesRemovedCount(entries.length),
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        Expanded(
          child: entries.isEmpty
              ? ListView(controller: widget.scrollController, children: [
                  const SizedBox(height: 80),
                  Center(child: Text(l.upcomingReleasesRemovedNone,
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant))),
                ])
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final coverUrl = entry.book['coverUrl'] as String? ?? '';
                    final title = entry.book['title'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        elevation: 0,
                        color: cs.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: coverUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: coverUrl, fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(color: cs.surfaceContainerHighest))
                                    : Container(color: cs.surfaceContainerHighest),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                if (entry.seriesName.isNotEmpty)
                                  Text(entry.seriesName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
                              ]),
                            ),
                            TextButton(
                              onPressed: () => _restore(entry),
                              child: Text(l.upcomingReleasesRestore),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ));
  }
}

/// Bottom sheet listing the series the scan skipped as finished, with
/// per-series rescan and always/never overrides.
class _SkippedSeriesSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String region;

  const _SkippedSeriesSheet({required this.scrollController, required this.region});

  @override
  State<_SkippedSeriesSheet> createState() => _SkippedSeriesSheetState();
}

class _SkippedSeriesSheetState extends State<_SkippedSeriesSheet> {
  final _service = UpcomingReleasesService();
  Set<String> _alwaysScan = {};
  Set<String> _neverScan = {};
  String? _busySeriesId;
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;
  bool _bulkBusy = false;

  void _toggleSelected(String seriesId) {
    setState(() {
      if (!_selected.remove(seriesId)) _selected.add(seriesId);
    });
  }

  Future<void> _bulkOverride({required bool always}) async {
    setState(() {
      final target = always ? _alwaysScan : _neverScan;
      final other = always ? _neverScan : _alwaysScan;
      target.addAll(_selected);
      other.removeAll(_selected);
    });
    await ScopedPrefs.setStringList(
        UpcomingReleasesService.alwaysScanPrefKey, _alwaysScan.toList());
    await ScopedPrefs.setStringList(
        UpcomingReleasesService.neverScanPrefKey, _neverScan.toList());
    if (mounted) setState(() => _selected.clear());
  }

  Future<void> _bulkScanNow() async {
    final l = AppLocalizations.of(context)!;
    final targets = _service.skippedSeries
        .where((s) => _selected.contains(s.seriesId))
        .toList();
    if (targets.isEmpty) return;
    final api = context.read<AuthProvider>().apiService;
    final libraryId = context.read<LibraryProvider>().selectedLibraryId;
    if (api == null || libraryId == null) return;
    setState(() => _bulkBusy = true);
    var found = 0;
    for (final s in targets) {
      final outcome = await _service.scanSingleSeries(
        api: api,
        libraryId: libraryId,
        seriesId: s.seriesId,
        seriesName: s.seriesName,
      );
      if (outcome == SingleScanOutcome.found) found++;
    }
    if (!mounted) return;
    setState(() {
      _bulkBusy = false;
      _selected.clear();
    });
    showOverlayToast(
      context,
      found > 0
          ? '${l.upcomingReleasesBulkScanned(targets.length)} - ${l.upcomingReleasesBulkScanFound(found)}'
          : l.upcomingReleasesBulkScanned(targets.length),
      icon: Icons.refresh_rounded,
    );
  }

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _loadOverrides();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadOverrides() async {
    final always = (await ScopedPrefs.getStringList(UpcomingReleasesService.alwaysScanPrefKey)).toSet();
    final never = (await ScopedPrefs.getStringList(UpcomingReleasesService.neverScanPrefKey)).toSet();
    if (!mounted) return;
    setState(() {
      _alwaysScan = always;
      _neverScan = never;
    });
  }

  Future<void> _toggleOverride(SkippedSeries s, {required bool always}) async {
    final target = always ? _alwaysScan : _neverScan;
    final other = always ? _neverScan : _alwaysScan;
    setState(() {
      if (target.contains(s.seriesId)) {
        target.remove(s.seriesId);
      } else {
        target.add(s.seriesId);
        other.remove(s.seriesId);
      }
    });
    await ScopedPrefs.setStringList(
        UpcomingReleasesService.alwaysScanPrefKey, _alwaysScan.toList());
    await ScopedPrefs.setStringList(
        UpcomingReleasesService.neverScanPrefKey, _neverScan.toList());
  }

  bool get _libraryMismatch {
    final libraryId = context.read<LibraryProvider>().selectedLibraryId;
    final stateLib = _service.skippedLibraryId;
    return stateLib.isNotEmpty && libraryId != null && stateLib != libraryId;
  }

  Future<void> _scanNow(SkippedSeries s) async {
    if (_busySeriesId != null) return;
    final l = AppLocalizations.of(context)!;
    final api = context.read<AuthProvider>().apiService;
    final libraryId = context.read<LibraryProvider>().selectedLibraryId;
    if (api == null || libraryId == null) return;
    setState(() => _busySeriesId = s.seriesId);
    final outcome = await _service.scanSingleSeries(
      api: api,
      libraryId: libraryId,
      seriesId: s.seriesId,
      seriesName: s.seriesName,
    );
    if (!mounted) return;
    setState(() => _busySeriesId = null);
    switch (outcome) {
      case SingleScanOutcome.found:
        showOverlayToast(context, l.upcomingReleasesSkippedScanFound(s.seriesName),
            icon: Icons.event_available_rounded);
      case SingleScanOutcome.none:
        showOverlayToast(context, l.upcomingReleasesSkippedScanNone(s.seriesName),
            icon: Icons.check_rounded);
      case SingleScanOutcome.failed:
        showOverlayToast(context, l.upcomingReleasesRescanFailed,
            icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _openSeriesSheet(SkippedSeries s) async {
    if (s.audibleAsin.isEmpty || _busySeriesId != null) return;
    final api = context.read<AuthProvider>().apiService;
    final libraryId = context.read<LibraryProvider>().selectedLibraryId;
    if (api == null || libraryId == null) return;
    setState(() => _busySeriesId = s.seriesId);
    final books = await api.getBooksBySeries(libraryId, s.seriesId, limit: 500);
    if (!mounted) return;
    setState(() => _busySeriesId = null);
    final ownedTitles = <String>{};
    final ownedAsins = <String>{};
    for (final b in books) {
      if (b is! Map<String, dynamic>) continue;
      final media = b['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final title = metadata['title'] as String? ?? '';
      final asin = metadata['asin'] as String? ?? '';
      if (title.isNotEmpty) ownedTitles.add(title);
      if (asin.isNotEmpty) ownedAsins.add(asin);
    }
    if (!mounted) return;
    showAudibleSeriesSheet(context,
      seriesName: s.seriesName,
      seriesAsin: s.audibleAsin,
      ownedTitles: ownedTitles,
      ownedAsins: ownedAsins,
    );
  }

  static final _asinPattern = RegExp(r'B0[0-9A-Z]{8}', caseSensitive: false);

  Future<void> _promptSeriesAsin(SkippedSeries s) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(
        text: s.audibleAsin.isNotEmpty ? s.audibleAsin : '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.upcomingReleasesSetSeriesAsin),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.seriesName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
          const SizedBox(height: 8),
          Text(l.upcomingReleasesSetAsinInstructions,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l.upcomingReleasesSetAsinHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.upcomingReleasesNotNow)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l.upcomingReleasesSetAsinSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null || !mounted) return;
    final match = _asinPattern.firstMatch(saved);
    if (match == null) {
      showOverlayToast(context, l.upcomingReleasesSetAsinInvalid, icon: Icons.error_outline_rounded);
      return;
    }
    final asin = match.group(0)!.toUpperCase();
    await _service.setSeriesAsin(seriesId: s.seriesId, seriesName: s.seriesName, asin: asin);
    if (!mounted) return;
    showOverlayToast(context, l.upcomingReleasesSetAsinSaved, icon: Icons.link_rounded);
    await _scanNow(SkippedSeries(
      seriesId: s.seriesId,
      seriesName: s.seriesName,
      audibleAsin: asin,
      newestRelease: '',
    ));
  }

  void _showRowMenu(SkippedSeries s) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isAlways = _alwaysScan.contains(s.seriesId);
    final isNever = _neverScan.contains(s.seriesId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 12),
            decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(s.seriesName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          if (s.audibleAsin.isNotEmpty)
            ListTile(
              leading: Icon(Icons.travel_explore_rounded, color: cs.primary, size: 22),
              title: Text(l.seriesBooksFindMissingTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              dense: true, visualDensity: VisualDensity.compact,
              onTap: () {
                Navigator.pop(ctx);
                _openSeriesSheet(s);
              },
            ),
          ListTile(
            leading: Icon(Icons.refresh_rounded, color: cs.primary, size: 22),
            title: Text(l.upcomingReleasesSkippedScanNow,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(ctx);
              _scanNow(s);
            },
          ),
          ListTile(
            leading: Icon(Icons.link_rounded, color: cs.primary, size: 22),
            title: Text(l.upcomingReleasesSetSeriesAsin,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(ctx);
              _promptSeriesAsin(s);
            },
          ),
          ListTile(
            leading: Icon(isAlways ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
              color: cs.primary, size: 22),
            title: Text(l.upcomingReleasesSkippedAlwaysScan,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: isAlways ? Icon(Icons.check_rounded, color: cs.primary, size: 18) : null,
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(ctx);
              _toggleOverride(s, always: true);
            },
          ),
          ListTile(
            leading: Icon(isNever ? Icons.block_rounded : Icons.block_outlined,
              color: cs.error, size: 22),
            title: Text(l.upcomingReleasesSkippedNeverScan,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: isNever ? Icon(Icons.check_rounded, color: cs.error, size: 18) : null,
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(ctx);
              _toggleOverride(s, always: false);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final skipped = _service.skippedSeries;
    final mismatch = _libraryMismatch;

    return ClipRect(child: Column(
      children: [
        Icon(Icons.visibility_off_rounded, size: 20, color: cs.primary),
        const SizedBox(height: 4),
        Text(l.upcomingReleasesSkippedTitle,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(l.upcomingReleasesSkippedCount(skipped.length),
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        if (mismatch)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(l.upcomingReleasesSkippedOtherLibrary,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.error, fontSize: 11)),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: skipped.isEmpty
              ? ListView(controller: widget.scrollController, children: [
                  const SizedBox(height: 80),
                  Center(child: Text(l.upcomingReleasesSkippedNone,
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant))),
                ])
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
                  itemCount: skipped.length,
                  itemBuilder: (context, index) => _buildRow(cs, tt, l, skipped[index], mismatch),
                ),
        ),
        if (_selecting)
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                child: Row(children: [
                  Text(l.upcomingReleasesSelectedCount(_selected.length),
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_bulkBusy)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else ...[
                    IconButton(
                      tooltip: l.upcomingReleasesSkippedScanNow,
                      icon: Icon(Icons.refresh_rounded, color: cs.primary),
                      onPressed: _bulkScanNow,
                    ),
                    IconButton(
                      tooltip: l.upcomingReleasesSkippedAlwaysScan,
                      icon: Icon(Icons.check_circle_outline_rounded, color: cs.primary),
                      onPressed: () => _bulkOverride(always: true),
                    ),
                    IconButton(
                      tooltip: l.upcomingReleasesSkippedNeverScan,
                      icon: Icon(Icons.block_rounded, color: cs.error),
                      onPressed: () => _bulkOverride(always: false),
                    ),
                  ],
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    onPressed: _bulkBusy ? null : () => setState(() => _selected.clear()),
                  ),
                ]),
              ),
            ),
          ),
      ],
    ));
  }

  Widget _buildRow(ColorScheme cs, TextTheme tt, AppLocalizations l, SkippedSeries s, bool mismatch) {
    final unmatched = s.audibleAsin.isEmpty;
    final isNever = _neverScan.contains(s.seriesId);
    final isAlways = _alwaysScan.contains(s.seriesId);
    final busy = _busySeriesId == s.seriesId;

    String? subtitle;
    if (unmatched) {
      subtitle = l.upcomingReleasesSkippedUnmatched;
    } else {
      final newest = DateTime.tryParse(s.newestRelease);
      if (newest != null) {
        final years = DateTime.now().difference(newest).inDays ~/ 365;
        subtitle = l.upcomingReleasesSkippedLastBook(years);
      }
    }

    final selected = _selected.contains(s.seriesId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: mismatch
            ? null
            : _selecting
                ? () => _toggleSelected(s.seriesId)
                : () => _showRowMenu(s),
        onLongPress: mismatch ? null : () => _toggleSelected(s.seriesId),
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: selected
                ? BorderSide(color: cs.primary, width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(s.seriesName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                    ),
                    if (isNever || isAlways) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isNever ? cs.error : cs.primary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isNever ? l.upcomingReleasesSkippedNeverScan : l.upcomingReleasesSkippedAlwaysScan,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            color: isNever ? cs.error : cs.primary),
                        ),
                      ),
                    ],
                  ]),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
                    ),
                ]),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (!mismatch)
                IconButton(
                  icon: Icon(
                    selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: selected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  onPressed: () => _toggleSelected(s.seriesId),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
