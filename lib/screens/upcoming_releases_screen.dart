import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/rmab_service.dart';
import '../services/scoped_prefs.dart';
import '../services/upcoming_releases_service.dart';
import '../utils/desktop_workspace.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/audible_series_sheet.dart';
import '../widgets/desktop_page_body.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/rmab_book_detail_sheet.dart';
import '../widgets/rmab_config_sheet.dart'
    show kRmabBaseUrlKey, kRmabApiTokenKey;
import '../l10n/app_localizations.dart';

class UpcomingReleasesScreen extends StatefulWidget {
  const UpcomingReleasesScreen({super.key});

  @override
  State<UpcomingReleasesScreen> createState() => _UpcomingReleasesScreenState();
}

class _UpcomingReleasesScreenState extends State<UpcomingReleasesScreen> {
  final _service = UpcomingReleasesService();
  String _region = 'us';
  bool _sortByDate = false;
  bool _rmabConfigured = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _initAndStart();
    _loadRmabConfigured();
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

  void _startScan() {
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();
    final api = auth.apiService;
    final libraryId = lib.selectedLibraryId;
    if (api == null || libraryId == null) return;

    _service.start(api: api, libraryId: libraryId, region: _region);
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

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

  void _showBookMenu(Map<String, dynamic> book, String seriesName,
      {bool isUpcoming = false}) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isOwned = book['_owned'] == true;
    // Show the RMAB request entry only for books that have been released but
    // aren't in the library yet, and only when the user has RMAB configured.
    final showRequest = _rmabConfigured && !isOwned && !isUpcoming;
    showAudibleBookMenu(context,
      book: book,
      seriesName: seriesName,
      region: _region,
      extraActions: [
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
    await _service.removeBook(asin);
    if (!mounted) return;
    showOverlayToast(context, l.upcomingReleasesRemovedFromList, icon: Icons.playlist_remove_rounded);
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
    final desktopWorkspace = isDesktopWorkspace(context);

    return Scaffold(
      body: SafeArea(
        child: DesktopPageBody(
          maxWidth: 1080,
          child: Column(
          children: [
            AbsorbPageHeader(
              title: l.upcomingReleasesTitle,
              actions: [
                // Sort by date toggle (only when scan is done and has results)
                if (_service.isComplete && _service.results.isNotEmpty)
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
                // Rescan button (only when not already scanning)
                if (_service.isComplete)
                  GestureDetector(
                    onTap: _rescan,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.refresh_rounded, size: 18, color: cs.onSurfaceVariant),
                    ),
                  ),
                // Region button
                GestureDetector(
                  onTap: _changeRegion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.language_rounded, size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        ApiService.audibleRegions[_region] ?? _region.toUpperCase(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
                      ),
                    ]),
                  ),
                ),
                if (desktopWorkspace)
                  IconButton(
                    key: const Key('upcoming-releases-close'),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: cs.onSurfaceVariant,
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
                  Text(
                    _buildSummary(l),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (_service.hasCachedResults && _service.cacheTime != null) ...[
                    const SizedBox(width: 6),
                    Text(_cacheAgeLabel(l), style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11)),
                  ],
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

  Widget _buildDateSortedList(ColorScheme cs, TextTheme tt, AppLocalizations l) {
    // Flatten all books with their series name and upcoming/recent status
    final allBooks = <({Map<String, dynamic> book, String seriesName, bool isUpcoming})>[];
    for (final result in _service.results) {
      for (final book in result.upcomingBooks) {
        allBooks.add((book: book, seriesName: result.seriesName, isUpcoming: true));
      }
      for (final book in result.recentBooks) {
        allBooks.add((book: book, seriesName: result.seriesName, isUpcoming: false));
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
        return _buildDateSortedCard(cs, tt, l, entry.book, entry.seriesName, entry.isUpcoming);
      },
    );
  }

  Widget _buildDateSortedCard(ColorScheme cs, TextTheme tt, AppLocalizations l, Map<String, dynamic> book, String seriesName, bool isUpcoming) {
    final title = book['title'] as String? ?? '';
    final subtitle = book['subtitle'] as String? ?? '';
    final authors = book['authors'] as String? ?? '';
    final sequence = book['sequence'] as String? ?? '';
    final coverUrl = book['coverUrl'] as String? ?? '';
    final releaseDate = book['releaseDate'] as String? ?? '';
    final runtime = _formatRuntime(book['runtimeMinutes'], l);
    final isOwned = book['_owned'] == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadGreen = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _showBookMenu(book, seriesName, isUpcoming: isUpcoming),
        child: Card(
          elevation: 0,
          color: isUpcoming
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : isOwned
                  ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
                  : cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      Row(children: [
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
          ...result.upcomingBooks.map((book) => _buildBookCard(cs, tt, l, book, result.seriesName, isUpcoming: true)),
          // Recent releases
          ...result.recentBooks.map((book) => _buildBookCard(cs, tt, l, book, result.seriesName, isUpcoming: false)),
        ],
      ),
    );
  }

  Widget _buildBookCard(ColorScheme cs, TextTheme tt, AppLocalizations l, Map<String, dynamic> book, String seriesName, {required bool isUpcoming}) {
    final title = book['title'] as String? ?? '';
    final subtitle = book['subtitle'] as String? ?? '';
    final authors = book['authors'] as String? ?? '';
    final narrators = book['narrators'] as String? ?? '';
    final sequence = book['sequence'] as String? ?? '';
    final coverUrl = book['coverUrl'] as String? ?? '';
    final releaseDate = book['releaseDate'] as String? ?? '';
    final runtime = _formatRuntime(book['runtimeMinutes'], l);
    final isOwned = book['_owned'] == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadGreen = isDark ? Colors.greenAccent[400]! : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _showBookMenu(book, seriesName, isUpcoming: isUpcoming),
        child: Card(
          elevation: 0,
          color: isUpcoming
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : isOwned
                  ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
                  : cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      Row(children: [
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
