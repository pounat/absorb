import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/player_settings.dart';
import '../services/rmab_service.dart';
import '../services/scoped_prefs.dart';
import '../services/upcoming_releases_service.dart';
import '../utils/app_platform.dart';
import 'overlay_toast.dart';
import 'rmab_book_detail_sheet.dart';
import 'rmab_config_sheet.dart' show kRmabBaseUrlKey, kRmabApiTokenKey;
import 'stackable_sheet.dart';

/// Show a bottom sheet with Audible series discovery results.
/// Shows missing books and upcoming releases for a series.
void showAudibleSeriesSheet(BuildContext context, {
  required String seriesName,
  required String seriesAsin,
  required Set<String> ownedTitles,
  required Set<String> ownedAsins,
}) {
  showStackableSheet(
    context: context,
    showHandle: true,
    builder: (ctx, scrollController) => AudibleSeriesSheet(
      seriesName: seriesName,
      seriesAsin: seriesAsin,
      ownedTitles: ownedTitles,
      ownedAsins: ownedAsins,
      scrollController: scrollController,
    ),
  );
}

class AudibleSeriesSheet extends StatefulWidget {
  final String seriesName;
  final String seriesAsin;
  final Set<String> ownedTitles;
  final Set<String> ownedAsins;
  final ScrollController scrollController;

  const AudibleSeriesSheet({
    super.key,
    required this.seriesName,
    required this.seriesAsin,
    required this.ownedTitles,
    required this.ownedAsins,
    required this.scrollController,
  });

  @override
  State<AudibleSeriesSheet> createState() => _AudibleSeriesSheetState();
}

class _AudibleSeriesSheetState extends State<AudibleSeriesSheet> {
  List<Map<String, dynamic>> _allBooks = [];
  bool _isLoading = true;
  String? _error;
  int _filter = 0; // 0 = missing, 1 = upcoming, 2 = all
  late String _region;
  bool _rmabConfigured = false;

  @override
  void initState() {
    super.initState();
    _region = ApiService.debugRegion;
    _loadRegionAndFetch();
    _loadRmabConfigured();
  }

  Future<void> _loadRmabConfigured() async {
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    if (!mounted) return;
    final next =
        (base ?? '').isNotEmpty && (token ?? '').isNotEmpty;
    debugPrint('[RMAB] audible-series: _rmabConfigured=$next');
    if (next != _rmabConfigured) {
      setState(() => _rmabConfigured = next);
    }
  }

  Future<void> _loadRegionAndFetch() async {
    final saved = await PlayerSettings.getAudibleRegion();
    if (saved.isNotEmpty && ApiService.audibleRegions.containsKey(saved)) {
      _region = saved;
    }
    _fetchSeries();
  }

  Future<void> _fetchSeries() async {
    setState(() { _isLoading = true; _error = null; _allBooks = []; });
    try {
      final books = await ApiService.discoverAudibleSeries(widget.seriesAsin, region: _region);
      if (!mounted) return;
      if (books.isEmpty) {
        setState(() { _isLoading = false; _error = AppLocalizations.of(context)!.audibleSeriesNoBooksFound; });
        return;
      }
      setState(() { _allBooks = books; _isLoading = false; });
    } catch (e, st) {
      debugPrint('[AudibleSeries] discoverAudibleSeries error: $e\n$st');
      if (!mounted) return;
      setState(() { _isLoading = false; _error = AppLocalizations.of(context)!.audibleSeriesFailedToLoad; });
    }
  }

  void _showRegionPicker() async {
    final chosen = await showAudibleRegionPicker(context, currentRegion: _region);
    if (chosen != null && chosen != _region && mounted) {
      setState(() => _region = chosen);
      PlayerSettings.setAudibleRegion(chosen);
      _fetchSeries();
    }
  }

  static final _parenthetical = RegExp(r'\s*\([^)]*\)\s*');
  static final _nonAlphaNum = RegExp(r'[^a-z0-9 ]');
  static final _multiSpace = RegExp(r'\s+');

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(_parenthetical, ' ')
        .replaceAll(_nonAlphaNum, ' ')
        .replaceAll(_multiSpace, ' ')
        .trim();
  }

  bool _isOwned(Map<String, dynamic> book) {
    final asin = book['asin'] as String? ?? '';
    if (widget.ownedAsins.contains(asin)) return true;
    // Check all regional ASIN variants
    final allAsins = book['allAsins'] as List<dynamic>? ?? [];
    for (final a in allAsins) {
      if (widget.ownedAsins.contains(a)) return true;
    }
    final title = _normalizeTitle(book['title'] as String? ?? '');
    if (title.isEmpty) return false;
    for (final owned in widget.ownedTitles) {
      if (_normalizeTitle(owned) == title) return true;
    }
    return false;
  }

  bool _isUpcoming(Map<String, dynamic> book) {
    final dateStr = book['releaseDate'] as String? ?? '';
    if (dateStr.isEmpty) return false;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    final now = DateTime.now();
    // Ignore bogus far-future dates (placeholder data from Audible)
    if (date.year > now.year + 5) return false;
    return date.isAfter(now);
  }

  void _openBookMenu(
    Map<String, dynamic> book, {
    required bool owned,
    required bool upcoming,
  }) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    // Surface the RMAB Request action only for missing-but-released books,
    // and only when the user has RMAB configured.
    final showRequest = _rmabConfigured && !owned && !upcoming;
    // Let upcoming or recently-released books be pushed onto the upcoming page
    // without rescanning the whole library.
    final canAddToUpcoming = upcoming || _isRecent(book);
    showAudibleBookMenu(
      context,
      book: book,
      seriesName: widget.seriesName,
      region: _region,
      extraActions: [
        if (canAddToUpcoming)
          ListTile(
            leading: Icon(Icons.event_available_rounded,
                color: cs.primary, size: 22),
            title: Text(l.audibleSeriesAddToUpcoming,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            dense: true,
            visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(context);
              _addToUpcoming(book, owned: owned);
            },
          ),
        if (showRequest)
          ListTile(
            leading: Icon(Icons.menu_book_rounded,
                color: cs.primary, size: 22),
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
                  '[RMAB] audible-series Request tapped (asin=$asin title="$title")');
              showRmabBookDetailSheet(
                context,
                book: RmabSearchResult.fromUpcomingBookMap(book),
              );
            },
          ),
      ],
    );
  }

  Future<void> _addToUpcoming(Map<String, dynamic> book, {required bool owned}) async {
    final l = AppLocalizations.of(context)!;
    final added = await UpcomingReleasesService().addBook(
      book,
      seriesName: widget.seriesName,
      audibleAsin: widget.seriesAsin,
      region: _region,
      owned: owned,
    );
    if (!mounted) return;
    showOverlayToast(
      context,
      added ? l.audibleSeriesAddedToUpcoming : l.audibleSeriesAlreadyInUpcoming,
      icon: added ? Icons.event_available_rounded : Icons.info_outline_rounded,
    );
  }

  /// Released within the last 30 days - mirrors UpcomingReleasesService so the
  /// "Add to upcoming releases" action only shows for books that page accepts.
  bool _isRecent(Map<String, dynamic> book) {
    final dateStr = book['releaseDate'] as String? ?? '';
    if (dateStr.isEmpty) return false;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    final now = DateTime.now();
    if (date.isAfter(now)) return false;
    return now.difference(date).inDays <= 30;
  }

  String _formatRuntime(dynamic minutes) {
    final mins = (minutes is num) ? minutes.toInt() : 0;
    if (mins <= 0) return '';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final missingCount = _allBooks.where((b) => !_isOwned(b) && !_isUpcoming(b)).length;
    final upcomingCount = _allBooks.where((b) => _isUpcoming(b)).length;

    final displayBooks = switch (_filter) {
      0 => _allBooks.where((b) => !_isOwned(b) && !_isUpcoming(b)).toList(),
      1 => _allBooks.where((b) => _isUpcoming(b)).toList(),
      _ => _allBooks,
    };

    return ClipRect(child: Column(
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Column(children: [
                Icon(Icons.travel_explore_rounded, size: 20, color: cs.primary),
                const SizedBox(height: 4),
                Text(widget.seriesName,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 4),
        if (!_isLoading && _error == null)
          Text(
            upcomingCount > 0
                ? l.audibleSeriesSummaryWithUpcoming(_allBooks.length, missingCount, upcomingCount)
                : l.audibleSeriesSummary(_allBooks.length, missingCount),
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _showRegionPicker,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.language_rounded, size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              ApiService.audibleRegions[_region] ?? _region.toUpperCase(),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          ]),
        ),
        const SizedBox(height: 8),

        // Filter toggle
        if (!_isLoading && _error == null && _allBooks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _filterChip(cs, l.audibleSeriesFilterMissing(missingCount), _filter == 0, () => setState(() => _filter = 0)),
              const SizedBox(width: 8),
              if (upcomingCount > 0) ...[
                _filterChip(cs, l.audibleSeriesFilterUpcoming(upcomingCount), _filter == 1, () => setState(() => _filter = 1)),
                const SizedBox(width: 8),
              ],
              _filterChip(cs, l.audibleSeriesFilterAll(_allBooks.length), _filter == 2, () => setState(() => _filter = 2)),
            ]),
          ),
        const SizedBox(height: 8),

        // Content
        if (_isLoading)
          Expanded(child: ListView(controller: widget.scrollController, children: [
            const SizedBox(height: 80),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(height: 12),
            Center(child: Text(l.audibleSeriesSearching, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)))),
          ]))
        else if (_error != null)
          Expanded(child: ListView(controller: widget.scrollController, children: [
            const SizedBox(height: 80),
            Center(child: Text(_error!, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant))),
          ]))
        else if (displayBooks.isEmpty)
          Expanded(child: ListView(controller: widget.scrollController, children: [
            const SizedBox(height: 80),
            Icon(
              _filter == 1 ? Icons.event_available_rounded : Icons.check_circle_outline_rounded,
              size: 48, color: cs.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Center(child: Text(
              _filter == 0 ? l.audibleSeriesCompleteSeries
                  : _filter == 1 ? l.audibleSeriesNoUpcoming
                  : l.noBooksFound,
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant))),
          ]))
        else
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom),
              itemCount: displayBooks.length,
              itemBuilder: (context, index) => _buildBookCard(cs, tt, l, displayBooks[index]),
            ),
          ),
      ],
    ));
  }

  Widget _filterChip(ColorScheme cs, String label, bool selected, VoidCallback onTap) {
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

  Widget _buildBookCard(ColorScheme cs, TextTheme tt, AppLocalizations l, Map<String, dynamic> book) {
    final title = book['title'] as String? ?? '';
    final subtitle = book['subtitle'] as String? ?? '';
    final authors = book['authors'] as String? ?? '';
    final narrators = book['narrators'] as String? ?? '';
    final sequence = book['sequence'] as String? ?? '';
    final coverUrl = book['coverUrl'] as String? ?? '';
    final releaseDate = book['releaseDate'] as String? ?? '';
    final runtime = _formatRuntime(book['runtimeMinutes']);
    final bookFormat = (book['bookFormat'] as String? ?? '').toLowerCase();
    final isAbridged = bookFormat.contains('abridg');
    final owned = _isOwned(book);
    final upcoming = _isUpcoming(book);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _openBookMenu(book, owned: owned, upcoming: upcoming),
        child: Card(
        elevation: 0,
        color: upcoming
            ? cs.primaryContainer.withValues(alpha: 0.3)
            : owned
                ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
                : cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Cover - keep square regardless of row height
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 112,
                  height: 112,
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
                        child: Text('#$sequence', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (upcoming)
                    Positioned(bottom: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
                        child: Text(l.audibleSeriesUpcomingBadge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (owned)
                    Positioned(bottom: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, size: 12,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent[400] : Colors.green.shade700),
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
                          Icon(upcoming ? Icons.event_rounded : Icons.calendar_today_rounded,
                            size: 11, color: upcoming ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(_formatDate(releaseDate),
                            style: TextStyle(fontSize: 10, fontWeight: upcoming ? FontWeight.w600 : FontWeight.w400,
                              color: upcoming ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5))),
                        ],
                        if (releaseDate.isNotEmpty && runtime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('·', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 10)),
                          ),
                        if (isAbridged) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: cs.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(l.audibleSeriesAbridged, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: cs.error)),
                          ),
                          if (releaseDate.isNotEmpty || runtime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('·', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3), fontSize: 10)),
                            ),
                        ],
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
      child: Center(child: Icon(Icons.auto_stories_rounded, color: cs.onSurface.withValues(alpha: 0.15), size: 32)),
    );
  }
}

/// Shared Audible region picker bottom sheet.
/// Returns the selected region code, or null if dismissed.
Future<String?> showAudibleRegionPicker(BuildContext context, {required String currentRegion}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
            Text(l.audibleSeriesRegionTitle, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
          ]),
        ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shrinkWrap: true,
            children: ApiService.audibleRegions.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, e.key),
                child: Container(height: 40,
                  decoration: BoxDecoration(
                    color: e.key == currentRegion ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: e.key == currentRegion ? cs.primary.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.1)),
                  ),
                  child: Center(child: Text(e.value, style: TextStyle(
                    color: e.key == currentRegion ? cs.primary : cs.onSurfaceVariant,
                    fontSize: 13, fontWeight: FontWeight.w500)))),
              ),
            )).toList(),
          ),
        ),
      ]),
    ),
  );
}

/// Show a bottom sheet menu for an Audible book with Open, Calendar, etc.
void showAudibleBookMenu(BuildContext context, {
  required Map<String, dynamic> book,
  required String seriesName,
  required String region,
  List<Widget> extraActions = const [],
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final l = AppLocalizations.of(context)!;
  final title = book['title'] as String? ?? '';
  final asin = book['asin'] as String? ?? '';
  final releaseDate = book['releaseDate'] as String? ?? '';

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
          child: Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
        if (releaseDate.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(_formatBookDate(releaseDate),
              style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 12),
        if (asin.isNotEmpty)
          ListTile(
            leading: Icon(Icons.open_in_new_rounded, color: cs.primary, size: 22),
            title: Text(l.audibleSeriesOpenOnAudible, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(ctx);
              _openOnAudible(context, asin, region);
            },
          ),
        if (releaseDate.isNotEmpty)
          ListTile(
            leading: Icon(Icons.calendar_month_rounded, color: cs.primary, size: 22),
            title: Text(l.audibleSeriesAddToCalendar, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            dense: true, visualDensity: VisualDensity.compact,
            onTap: () {
              Navigator.pop(ctx);
              _addToCalendar(context, title, seriesName, releaseDate);
            },
          ),
        ...extraActions,
        const SizedBox(height: 8),
      ]),
    ),
  );
}

String _formatBookDate(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _audibleTldForRegion(String region) {
  const tlds = {
    'us': '.com', 'uk': '.co.uk', 'gb': '.co.uk', 'au': '.com.au',
    'ca': '.ca', 'de': '.de', 'fr': '.fr', 'it': '.it', 'es': '.es',
    'jp': '.co.jp', 'in': '.in', 'br': '.com.br',
  };
  return tlds[region] ?? '.com';
}

Future<void> _openOnAudible(BuildContext context, String asin, String region) async {
  final tld = _audibleTldForRegion(region);
  final uri = Uri.parse('https://www.audible$tld/pd/$asin');
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (context.mounted) showOverlayToast(context, AppLocalizations.of(context)!.audibleSeriesCouldNotOpenAudible, icon: Icons.error_outline_rounded);
  }
}

Future<void> _addToCalendar(BuildContext context, String title, String seriesName, String dateStr) async {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return;
  final l = AppLocalizations.of(context)!;

  final eventTitle = '$title - $seriesName';
  final description = l.audibleSeriesCalendarDescription(seriesName);

  if (AppPlatform.isAndroid) {
    final begin = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59).millisecondsSinceEpoch;
    final uri = Uri.parse(
      'content://com.android.calendar/events'
      '?title=${Uri.encodeComponent(eventTitle)}'
      '&description=${Uri.encodeComponent(description)}'
      '&beginTime=$begin'
      '&endTime=$end'
      '&allDay=1',
    );
    try {
      await launchUrl(uri);
      return;
    } catch (_) {}
  }

  final dateFormatted = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  final uri = Uri.parse(
    'https://calendar.google.com/calendar/render?action=TEMPLATE'
    '&text=${Uri.encodeComponent(eventTitle)}'
    '&dates=$dateFormatted/$dateFormatted'
    '&details=${Uri.encodeComponent(description)}',
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (context.mounted) showOverlayToast(context, AppLocalizations.of(context)!.audibleSeriesCouldNotOpenCalendar, icon: Icons.error_outline_rounded);
  }
}
