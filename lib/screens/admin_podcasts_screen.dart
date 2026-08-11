import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/socket_service.dart';
import 'podcast_edit_screen.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/adaptive_modal.dart';
import '../widgets/desktop_page_body.dart';
import '../widgets/html_description.dart';
import '../widgets/overlay_toast.dart';
import '../l10n/app_localizations.dart';
import '../utils/desktop_workspace.dart';
import '../utils/duration_format.dart';

/// Opens the podcast lookup used by the admin podcast manager.
///
/// When [initialQuery] is provided, the sheet carries it into the search field
/// and runs the lookup immediately.
Future<void> showAddPodcastSheet(
  BuildContext context, {
  required String libraryId,
  required String folderId,
  required VoidCallback onAdded,
  String initialQuery = '',
}) {
  return showAdaptiveActionMenu<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    desktopWidth: 640,
    desktopScrollWrap: false,
    builder: (_) => _PodcastSearchSheet(
      libraryId: libraryId,
      folderId: folderId,
      initialQuery: initialQuery,
      onAdded: onAdded,
    ),
  );
}

Future<void> showPodcastAdminSettings(
  BuildContext context, {
  required Map<String, dynamic> item,
  required String libraryId,
  required VoidCallback onChanged,
}) async {
  if (!context.read<AuthProvider>().isAdmin) return;
  final navigator = contentNavigator(context);
  final sourceContext = context;
  final sourceRoute = ModalRoute.of(context);
  if (isDesktopWorkspace(context) && sourceRoute is PopupRoute<dynamic>) {
    Navigator.of(context, rootNavigator: true).removeRoute(sourceRoute);
  }
  await navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => _PodcastDetailScreen(
        item: item,
        libraryId: libraryId,
        initialTab: 2,
        onChanged: () {
          if (sourceContext.mounted) onChanged();
        },
      ),
    ),
  );
}

class AdminPodcastsScreen extends StatefulWidget {
  final Map<String, dynamic> library;
  const AdminPodcastsScreen({super.key, required this.library});
  @override State<AdminPodcastsScreen> createState() => _AdminPodcastsScreenState();
}

class _AdminPodcastsScreenState extends State<AdminPodcastsScreen> {
  bool _loading = true;
  bool _checkingEpisodes = false;
  List<dynamic> _shows = [];

  String get _libraryId => widget.library['id'] as String? ?? '';
  String get _folderId {
    final folders = widget.library['folders'] as List?;
    if (folders != null && folders.isNotEmpty) return folders[0]['id'] as String? ?? '';
    return '';
  }

  @override
  void initState() { super.initState(); _loadShows(); }

  Future<void> _loadShows() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _loading = true);
    try {
      final r = await api.getLibraryItems(_libraryId, limit: 100);
      if (r != null && r['results'] is List) {
        _shows = (r['results'] as List).map((item) {
          if (item is Map<String, dynamic>) return item['libraryItem'] ?? item;
          return item;
        }).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _confirmCheckNewEpisodes(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.adminPodcastsCheckNewEpisodesTitle),
      content: Text(l.adminPodcastsCheckNewEpisodesContent),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        TextButton(onPressed: () { Navigator.pop(ctx); _checkNewEpisodes(); }, child: Text(l.adminPodcastsCheck)),
      ],
    ));
  }

  Future<void> _checkNewEpisodes() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _checkingEpisodes = true);
    final ok = await api.checkNewEpisodes(_libraryId);
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() => _checkingEpisodes = false);
      showOverlayToast(
        context,
        ok
            ? l.adminPodcastsCheckingForNew
            : l.adminPodcastsFailedCheckEpisodes,
        icon: ok ? Icons.refresh_rounded : Icons.error_outline_rounded,
      );
      if (ok) Future.delayed(const Duration(seconds: 3), _loadShows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: cs.primary,
        onPressed: () => _showSearchSheet(),
        child: Icon(Icons.add_rounded, color: cs.onPrimary),
      ),
      body: DesktopPageBody(maxWidth: 1040, child: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
          child: Row(children: [
            Expanded(child: AbsorbPageHeader(title: l.adminPodcasts, padding: EdgeInsets.zero)),
            _checkingEpisodes
                ? Padding(padding: const EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onSurfaceVariant.withValues(alpha: 0.6))))
                : IconButton(
                    icon: Icon(Icons.cloud_download_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.6), size: 22),
                    tooltip: l.adminPodcastsCheckFeedsTooltip,
                    onPressed: () => _confirmCheckNewEpisodes(cs, tt)),
            IconButton(icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.6)), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : RefreshIndicator(onRefresh: _loadShows, child: _buildShowList(cs, tt)),
        ),
      ]))),
    );
  }

  // ─── Show List ──────────────────────────────────────────────

  Widget _buildShowList(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    if (_shows.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.podcasts_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.1)),
        const SizedBox(height: 12),
        Text(l.adminPodcastsNoPodcastsYet, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.3))),
        const SizedBox(height: 4),
        Text(l.adminPodcastsTapPlusHint, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.2))),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: _shows.length,
      itemBuilder: (_, i) {
        final item = _shows[i] as Map<String, dynamic>;
        final media = item['media'] as Map<String, dynamic>? ?? {};
        final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
        final title = metadata['title'] as String? ?? l.unknown;
        final author = metadata['author'] as String? ?? '';
        final numEps = media['numEpisodes'] as int?
            ?? (media['episodes'] as List?)?.length
            ?? item['numEpisodes'] as int?
            ?? 0;
        final itemId = item['id'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _openShowDetail(item),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: _coverImg(cs, itemId)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (author.isNotEmpty) ...[const SizedBox(height: 2),
                    Text(author, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis)],
                  const SizedBox(height: 4),
                  Text(l.adminPodcastsEpisodesCount(numEps), style: tt.labelSmall?.copyWith(color: cs.primary.withValues(alpha: 0.7), fontSize: 11)),
                ])),
                Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.15)),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _coverImg(ColorScheme cs, String itemId) {
    final auth = context.read<AuthProvider>();
    final url = '${auth.serverUrl}/api/items/$itemId/cover?token=${auth.token}';
    return Image.network(url, width: 56, height: 56, fit: BoxFit.cover,
      headers: auth.apiService?.mediaHeaders ?? {},
      errorBuilder: (_, __, ___) => _coverPlaceholder(cs));
  }

  Widget _coverPlaceholder(ColorScheme cs) => Container(width: 56, height: 56,
    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Icon(Icons.podcasts_rounded, color: cs.primary.withValues(alpha: 0.4)));

  // ─── Search Sheet ───────────────────────────────────────────

  void _showSearchSheet() {
    showAddPodcastSheet(
      context,
      libraryId: _libraryId,
      folderId: _folderId,
      onAdded: _loadShows,
    );
  }

  // ─── Show Detail ────────────────────────────────────────────

  void _openShowDetail(Map<String, dynamic> item) {
    contentNavigator(context).push(MaterialPageRoute(
      builder: (_) => _PodcastDetailScreen(item: item, libraryId: _libraryId, onChanged: _loadShows)));
  }
}


// ═══════════════════════════════════════════════════════════════
//  Search & Add Podcast Sheet
// ═══════════════════════════════════════════════════════════════

class _PodcastSearchSheet extends StatefulWidget {
  final String libraryId;
  final String folderId;
  final String initialQuery;
  final VoidCallback onAdded;
  const _PodcastSearchSheet({
    required this.libraryId,
    required this.folderId,
    required this.initialQuery,
    required this.onAdded,
  });
  @override State<_PodcastSearchSheet> createState() => _PodcastSearchSheetState();
}

class _PodcastSearchSheetState extends State<_PodcastSearchSheet> {
  late final TextEditingController _ctrl;
  bool _searching = false;
  List<dynamic> _results = [];

  // Discover state - localized labels are read in build via _genreLabels(l).
  static const _genreIds = <int>[
    0, 1301, 1303, 1304, 1309, 1310, 1311, 1314, 1315, 1316,
    1318, 1321, 1323, 1324, 1325, 1326, 1487, 1488,
  ];

  Map<int, String> _genreLabels(AppLocalizations l) => {
    0: l.adminPodcastsGenreAll,
    1301: l.adminPodcastsGenreArts,
    1303: l.adminPodcastsGenreComedy,
    1304: l.adminPodcastsGenreEducation,
    1309: l.adminPodcastsGenreTvFilm,
    1310: l.adminPodcastsGenreMusic,
    1311: l.adminPodcastsGenreNews,
    1314: l.adminPodcastsGenreReligion,
    1315: l.adminPodcastsGenreScience,
    1316: l.adminPodcastsGenreSports,
    1318: l.adminPodcastsGenreTechnology,
    1321: l.adminPodcastsGenreBusiness,
    1323: l.adminPodcastsGenreFiction,
    1324: l.adminPodcastsGenreSocietyCulture,
    1325: l.adminPodcastsGenreHealthFitness,
    1326: l.adminPodcastsGenreTrueCrime,
    1487: l.adminPodcastsGenreHistory,
    1488: l.adminPodcastsGenreKidsFamily,
  };
  int _selectedGenre = 0;
  bool _loadingChart = true;
  List<dynamic> _chartResults = [];
  final Set<String> _lookingUp = {};

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    _loadChart();
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadChart() async {
    setState(() => _loadingChart = true);
    try {
      final genrePart = _selectedGenre > 0 ? 'genre=$_selectedGenre/' : '';
      final url = 'https://itunes.apple.com/us/rss/toppodcasts/${genrePart}limit=25/json';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final entries = data['feed']?['entry'] as List? ?? [];
        setState(() { _chartResults = entries; _loadingChart = false; });
      } else if (mounted) {
        setState(() => _loadingChart = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingChart = false);
    }
  }

  Future<void> _openChartPodcast(Map<String, dynamic> entry) async {
    // Extract iTunes ID and look up feed URL
    final idObj = entry['id'];
    final String? itunesId = idObj is Map ? (idObj['attributes']?['im:id'] as String?) : null;
    if (itunesId == null) return;

    setState(() => _lookingUp.add(itunesId));
    try {
      final response = await http.get(Uri.parse('https://itunes.apple.com/lookup?id=$itunesId&entity=podcast'));
      if (!mounted) return;
      setState(() => _lookingUp.remove(itunesId));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final raw = results[0] as Map<String, dynamic>;
          // iTunes lookup uses different keys than ABS search. Normalize so
          // ApiService.createPodcast (which reads title/cover/id/etc) works.
          final explicitness = raw['trackExplicitness'] ?? raw['collectionExplicitness'];
          final pod = <String, dynamic>{
            'title': raw['trackName'] ?? raw['collectionName'] ?? '',
            'artistName': raw['artistName'] ?? '',
            'description': '',
            'releaseDate': raw['releaseDate'] ?? '',
            'genres': raw['genres'] ?? [],
            'cover': raw['artworkUrl600'] ?? raw['artworkUrl100'] ?? '',
            'feedUrl': raw['feedUrl'] ?? '',
            'pageUrl': raw['collectionViewUrl'] ?? raw['trackViewUrl'] ?? '',
            'id': raw['collectionId']?.toString() ?? raw['trackId']?.toString() ?? '',
            'artistId': raw['artistId']?.toString() ?? '',
            'explicit': explicitness == 'explicit',
            'language': null,
          };
          _openPreview(pod);
          return;
        }
      }
      showOverlayToast(
        context,
        AppLocalizations.of(context)!.adminPodcastsCouldNotFindFeed,
        icon: Icons.search_off_rounded,
      );
    } catch (_) {
      if (mounted) setState(() => _lookingUp.remove(itunesId));
    }
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim(); if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final api = context.read<AuthProvider>().apiService;
    if (api != null) _results = await api.searchPodcasts(q);
    if (mounted) setState(() => _searching = false);
  }

  /// Extract the podcast map from a search result item
  Map<String, dynamic> _extractPod(dynamic item) {
    if (item is Map<String, dynamic>) {
      if (item.containsKey('podcast')) return item['podcast'] as Map<String, dynamic>;
      return item;
    }
    return {};
  }

  String _getImageUrl(Map<String, dynamic> pod) {
    return pod['cover'] as String?
        ?? pod['imageUrl'] as String?
        ?? pod['artworkUrl600'] as String?
        ?? pod['artworkUrl100'] as String?
        ?? '';
  }

  void _openPreview(Map<String, dynamic> pod) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PodcastPreviewScreen(
          podcast: pod,
          libraryId: widget.libraryId,
          folderId: widget.folderId,
          onAdded: () {
            widget.onAdded();
            // Close the search sheet after adding
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AdaptiveDraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.05,
        maxChildSize: 0.95,
        expand: false,
        desktopMaxHeight: 680,
        builder: (ctx, sc) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l.adminPodcastsAddPodcast, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.6), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              _buildSearchBar(cs, tt),
              Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.1)),
              Expanded(
                child: _searching
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _results.isNotEmpty
                        ? _buildResultsList(cs, tt, sc)
                        : _buildDiscover(cs, tt, sc),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiscover(ColorScheme cs, TextTheme tt, ScrollController sc) {
    final l = AppLocalizations.of(context)!;
    final genres = _genreLabels(l);
    return Column(children: [
      // Genre chips
      SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          children: _genreIds.map((id) {
            final selected = _selectedGenre == id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () { setState(() => _selectedGenre = id); _loadChart(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? cs.primary.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.06)),
                  ),
                  child: Text(genres[id] ?? '', style: tt.labelSmall?.copyWith(
                    color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 4),
      // Chart list
      Expanded(
        child: _loadingChart
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _chartResults.isEmpty
                ? Center(child: Text(l.adminPodcastsNoPodcastsFound, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24))))
                : ListView.builder(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: _chartResults.length,
                    itemBuilder: (_, i) {
                      final entry = _chartResults[i] as Map<String, dynamic>? ?? {};
                      final name = entry['im:name']?['label'] as String? ?? '';
                      final artist = entry['im:artist']?['label'] as String? ?? '';
                      final images = entry['im:image'] as List? ?? [];
                      final imageUrl = images.isNotEmpty ? (images.last['label'] as String? ?? '') : '';
                      final category = entry['category']?['attributes']?['label'] as String? ?? '';
                      final idObj = entry['id'];
                      final String? itunesId = idObj is Map ? (idObj['attributes']?['im:id'] as String?) : null;
                      final isLoading = itunesId != null && _lookingUp.contains(itunesId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: isLoading ? null : () => _openChartPodcast(entry),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(children: [
                              // Rank number
                              SizedBox(width: 24, child: Text('${i + 1}', textAlign: TextAlign.center,
                                style: tt.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.25), fontWeight: FontWeight.w700))),
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _ph(cs))
                                    : _ph(cs),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (artist.isNotEmpty) ...[const SizedBox(height: 2),
                                  Text(artist, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)],
                                if (category.isNotEmpty) ...[const SizedBox(height: 2),
                                  Text(category, style: tt.labelSmall?.copyWith(color: cs.primary.withValues(alpha: 0.5), fontSize: 10))],
                              ])),
                              const SizedBox(width: 8),
                              if (isLoading)
                                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.primary))
                              else
                                Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.15)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _buildSearchBar(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        style: TextStyle(color: cs.onSurface),
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          hintText: l.adminPodcastsSearchHint,
          hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.25)),
          prefixIcon: Icon(Icons.search_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
          suffixIcon: _searching
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                )
              : IconButton(icon: Icon(Icons.arrow_forward_rounded, color: cs.primary), onPressed: _search),
          filled: true,
          fillColor: cs.onSurface.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildResultsList(ColorScheme cs, TextTheme tt, ScrollController sc) {
    final l = AppLocalizations.of(context)!;
    return ListView.builder(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final pod = _extractPod(_results[i]);
        final title = pod['title'] as String? ?? pod['trackName'] as String? ?? pod['collectionName'] as String? ?? l.unknown;
        final author = pod['artistName'] as String? ?? pod['author'] as String? ?? '';
        final imageUrl = _getImageUrl(pod);
        final episodeCount = pod['trackCount'] as int?;
        final releaseDate = pod['releaseDate'] as String?;
        final genres = (pod['genres'] as List?)?.whereType<String>().where((g) => g != 'Podcasts').toList();

        // Format release date
        String? releaseDateStr;
        if (releaseDate != null) {
          try {
            final dt = DateTime.parse(releaseDate);
            final now = DateTime.now();
            final diff = now.difference(dt);
            if (diff.inDays < 1) {
              releaseDateStr = l.adminPodcastsRelToday;
            } else if (diff.inDays < 7) {
              releaseDateStr = l.daysAgo(diff.inDays);
            } else if (diff.inDays < 30) {
              releaseDateStr = l.adminPodcastsWeeksAgo((diff.inDays / 7).floor());
            } else if (diff.inDays < 365) {
              releaseDateStr = l.adminPodcastsMonthsAgo((diff.inDays / 30).floor());
            } else {
              releaseDateStr = l.adminPodcastsYearsAgo((diff.inDays / 365).floor());
            }
          } catch (_) {}
        }

        // Build metadata chips
        final metaParts = <String>[
          if (episodeCount != null) l.adminPodcastsEpisodesCount(episodeCount),
          if (releaseDateStr != null) l.adminPodcastsUpdated(releaseDateStr),
        ];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _openPreview(pod),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph(cs),
                          )
                        : _ph(cs),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (author.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(author, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                        if (metaParts.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(metaParts.join(' · '), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.45), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                        if (genres != null && genres.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(genres.take(3).join(', '), style: tt.labelSmall?.copyWith(color: cs.primary.withValues(alpha: 0.5), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.15)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _ph(ColorScheme cs) => Container(
    width: 50, height: 50,
    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Icon(Icons.podcasts_rounded, color: cs.primary.withValues(alpha: 0.4), size: 22),
  );

}


// ═══════════════════════════════════════════════════════════════
//  Podcast Preview / Confirmation Screen
// ═══════════════════════════════════════════════════════════════

class _PodcastPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> podcast;
  final String libraryId;
  final String folderId;
  final VoidCallback onAdded;
  const _PodcastPreviewScreen({
    required this.podcast,
    required this.libraryId,
    required this.folderId,
    required this.onAdded,
  });
  @override State<_PodcastPreviewScreen> createState() => _PodcastPreviewScreenState();
}

class _PodcastPreviewScreenState extends State<_PodcastPreviewScreen> {
  bool _loadingFeed = false;
  bool _adding = false;
  Map<String, dynamic>? _feedData;
  List<dynamic> _feedEpisodes = [];

  Map<String, dynamic> get _pod => widget.podcast;
  String get _title => _pod['title'] as String? ?? _pod['trackName'] as String? ?? _pod['collectionName'] as String? ?? AppLocalizations.of(context)!.adminPodcastsPodcastFallback;
  String get _author => _pod['artistName'] as String? ?? _pod['author'] as String? ?? '';
  String get _feedUrl => _pod['feedUrl'] as String? ?? '';
  String get _imageUrl =>
      _pod['cover'] as String? ??
      _pod['imageUrl'] as String? ??
      _pod['artworkUrl600'] as String? ?? '';
  String get _description => _feedData?['metadata']?['description'] as String? ??
      _pod['description'] as String? ?? '';
  List<dynamic> get _genres => _pod['genres'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    if (_feedUrl.isNotEmpty) _loadFeed();
  }

  Future<void> _loadFeed() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _loadingFeed = true);
    final result = await api.getPodcastFeed(_feedUrl);
    if (result != null && mounted) {
      setState(() {
        _feedData = result['podcast'] as Map<String, dynamic>? ?? result;
        _feedEpisodes = _feedData?['episodes'] as List? ?? [];
        _loadingFeed = false;
      });
    } else if (mounted) {
      setState(() => _loadingFeed = false);
    }
  }

  Future<void> _addPodcast() async {
    final l = AppLocalizations.of(context)!;
    if (_feedUrl.isEmpty) { _msg(l.adminPodcastsNoFeedFound); return; }
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _adding = true);
    final result = await api.createPodcast(
      libraryId: widget.libraryId,
      folderId: widget.folderId,
      feedUrl: _feedUrl,
      podcastData: _pod,
    );
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      setState(() => _adding = false);
      if (result != null) {
        widget.onAdded();
        _msg(l2.adminPodcastsAddedToLibrary(_title),
            icon: Icons.check_circle_outline_rounded);
        Navigator.pop(context);
      } else {
        _msg(l2.adminPodcastsFailedToAdd(_title),
            icon: Icons.error_outline_rounded);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DesktopPageBody(maxWidth: 1040, child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface.withValues(alpha: 0.54)), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  // Cover + title
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _imageUrl.isNotEmpty
                          ? Image.network(_imageUrl, width: 160, height: 160, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _coverPlaceholder(cs))
                          : _coverPlaceholder(cs),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _title,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  if (_author.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_author, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 12),

                  // Genres
                  if (_genres.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: _genres.map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(g.toString(), style: tt.labelSmall?.copyWith(color: cs.primary, fontSize: 11)),
                        )).toList(),
                      ),
                    ),

                  // Feed info
                  if (_feedUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rss_feed_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.25)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _feedUrl,
                              style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.25), fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Description
                  if (_description.isNotEmpty) ...[
                    HtmlDescription(
                      html: _description,
                      maxLines: 6,
                      style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5), height: 1.5),
                      linkColor: cs.primary,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Episode preview
                  if (_loadingFeed)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_feedEpisodes.isNotEmpty) ...[
                    Text(
                      l.adminPodcastsEpisodesInFeed(_feedEpisodes.length),
                      style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    // Show first 5 episodes as preview
                    ...(_feedEpisodes.take(5).map((ep) {
                      final epMap = ep as Map<String, dynamic>;
                      final epTitle = epMap['title'] as String? ?? l.adminPodcastsEpisodeFallback;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            epTitle,
                            style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.54)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    })),
                    if (_feedEpisodes.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l.adminPodcastsMoreEpisodes(_feedEpisodes.length - 5),
                          style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // Add button
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _adding ? null : _addPodcast,
                  icon: _adding
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface))
                      : const Icon(Icons.add_rounded),
                  label: Text(_adding ? l.adminPodcastsAdding : l.adminPodcastsAddToLibrary, style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _coverPlaceholder(ColorScheme cs) => Container(
    width: 160, height: 160,
    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
    child: Icon(Icons.podcasts_rounded, color: cs.primary.withValues(alpha: 0.3), size: 48),
  );

  void _msg(String s, {IconData? icon}) =>
      showOverlayToast(context, s, icon: icon);
}


// ═══════════════════════════════════════════════════════════════
//  Podcast Detail — Episodes per show
// ═══════════════════════════════════════════════════════════════

class _PodcastDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String libraryId;
  final int initialTab;
  final VoidCallback onChanged;
  const _PodcastDetailScreen({
    required this.item,
    required this.libraryId,
    this.initialTab = 0,
    required this.onChanged,
  });
  @override State<_PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<_PodcastDetailScreen> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _item;
  bool _loadingFeed = false;
  List<dynamic> _feedEpisodes = [];
  final Set<String> _downloading = {};
  final Set<String> _deleting = {};
  final Set<int> _selectedFeedIndices = {};
  final Set<String> _selectedDownloadedIds = {};
  int _checkLimit = 3;
  DateTime? _checkAfterDate;
  late TabController _tabCtrl;

  // Download queue
  Map<String, dynamic>? _currentDownload;
  List<dynamic> _downloadQueue = [];
  bool _pollingQueue = false;

  String get _podcastId => _item['id'] as String? ?? '';
  Map<String, dynamic> get _media => _item['media'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get _metadata => _media['metadata'] as Map<String, dynamic>? ?? {};
  List<dynamic> get _episodes => _media['episodes'] as List? ?? [];
  String get _title => _metadata['title'] as String? ?? AppLocalizations.of(context)!.adminPodcastsPodcastFallback;
  String get _feedUrl => _metadata['feedUrl'] as String? ?? _media['feedUrl'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _item = jsonDecode(jsonEncode(widget.item)) as Map<String, dynamic>;
    final initialTab = widget.initialTab >= 0 && widget.initialTab < 3
        ? widget.initialTab
        : 0;
    _lastTabIndex = initialTab;
    _tabCtrl = TabController(length: 3, initialIndex: initialTab, vsync: this)
      ..addListener(_onTabChanged);
    _initCheckDate();
    _reloadItem(); // Load full item with episodes
    _loadFeed(); // Pre-load feed so it's ready when user switches tabs
    _pollDownloadQueue(); // Check for any in-progress downloads
    SocketService().addItemUpdatedListener(_onSocketItemUpdated);
  }

  // Live-refresh when this show changes on the server (episode downloads
  // finishing, metadata edits from the web UI).
  Timer? _liveRefreshDebounce;
  void _onSocketItemUpdated(Map<String, dynamic> data) {
    if (!mounted || data['id'] != _podcastId) return;
    _liveRefreshDebounce?.cancel();
    _liveRefreshDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _reloadItem();
    });
  }

  int _lastTabIndex = 0;
  void _onTabChanged() {
    if (_tabCtrl.index != _lastTabIndex && !_tabCtrl.indexIsChanging) {
      _lastTabIndex = _tabCtrl.index;
      setState(() {});
    }
  }

  void _initCheckDate() {
    final lastCheck = _media['lastEpisodeCheck'] as num?;
    if (lastCheck != null && lastCheck > 0) {
      _checkAfterDate = DateTime.fromMillisecondsSinceEpoch(lastCheck.toInt());
    } else {
      _checkAfterDate = DateTime.now().subtract(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    SocketService().removeItemUpdatedListener(_onSocketItemUpdated);
    _liveRefreshDebounce?.cancel();
    _pollingQueue = false;
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _removeShow() async {
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.adminPodcastsRemoveShowTitle),
      content: Text(l.adminPodcastsRemoveShowContent(_title)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.remove, style: TextStyle(color: Colors.red.shade300)))],
    ));
    if (yes != true) return;
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final status = await api.deleteLibraryItem(_podcastId);
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      if (status == 200) { _msg(l2.adminPodcastsRemovedShow(_title)); widget.onChanged(); Navigator.pop(context); }
      else if (status == 403) _msg(l2.deletePermissionRequired);
      else _msg(l2.adminPodcastsFailedRemoveShow);
    }
  }

  Future<void> _reloadItem() async {
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    try {
      final found = await api.getLibraryItem(_podcastId);
      if (found != null && mounted) {
        // Deep copy to ensure nested maps are mutable
        final copy = jsonDecode(jsonEncode(found)) as Map<String, dynamic>;
        setState(() => _item = copy);
      }
    } catch (_) {}
  }

  Future<void> _loadFeed() async {
    if (_feedUrl.isEmpty) { _msg(AppLocalizations.of(context)!.adminPodcastsNoFeedAvailable); return; }
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _loadingFeed = true);
    final result = await api.getPodcastFeed(_feedUrl);
    if (result != null) {
      final podcast = result['podcast'] as Map<String, dynamic>? ?? result;
      _feedEpisodes = podcast['episodes'] as List? ?? [];
      if (!_feedNewestFirst) _applyFeedSort();
    }
    if (mounted) setState(() => _loadingFeed = false);
  }

  bool _feedNewestFirst = true;

  // Sort by publish date when the feed provides one; otherwise fall back to
  // reversing feed order (feeds are conventionally newest-first). The select
  // mode tracks episodes by index, so selection is cleared on toggle.
  void _applyFeedSort() {
    num? dateOf(dynamic e) => (e as Map)['publishedAt'] as num? ?? e['pubDate'] as num?;
    if (_feedEpisodes.every((e) => dateOf(e) != null)) {
      _feedEpisodes.sort((a, b) => _feedNewestFirst
          ? dateOf(b)!.compareTo(dateOf(a)!)
          : dateOf(a)!.compareTo(dateOf(b)!));
    } else {
      _feedEpisodes = _feedEpisodes.reversed.toList();
    }
  }

  void _toggleFeedSort() {
    setState(() {
      _feedNewestFirst = !_feedNewestFirst;
      _selectedFeedIndices.clear();
      _applyFeedSort();
    });
  }

  Future<void> _pollDownloadQueue() async {
    if (_pollingQueue) return;
    _pollingQueue = true;
    final api = context.read<AuthProvider>().apiService;
    while (_pollingQueue && mounted && api != null) {
      final data = await api.getEpisodeDownloads(widget.libraryId);
      if (!mounted) break;
      final current = data?['currentDownload'] as Map<String, dynamic>?;
      final queue = data?['queue'] as List? ?? [];
      // Filter to this podcast only
      final myId = _podcastId;
      final myCurrent = (current != null && current['libraryItemId'] == myId) ? current : null;
      final myQueue = queue.where((q) => (q as Map?)?['libraryItemId'] == myId).toList();

      setState(() {
        _currentDownload = myCurrent;
        _downloadQueue = myQueue;
      });

      // If nothing left downloading, refresh episodes and stop polling
      if (myCurrent == null && myQueue.isEmpty) {
        _pollingQueue = false;
        _reloadItem();
        break;
      }
      await Future.delayed(const Duration(seconds: 3));
    }
    _pollingQueue = false;
  }

  Future<void> _downloadEpisode(Map<String, dynamic> feedEp) async {
    final epTitle = feedEp['title'] as String? ?? '';
    final epKey = feedEp['enclosureUrl'] as String? ?? feedEp['title'] as String? ?? '';
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _downloading.add(epKey));
    final ok = await api.downloadPodcastEpisodes(_podcastId, [feedEp]);
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() => _downloading.remove(epKey));
      _msg(ok ? l.adminPodcastsDownloadingEpisode(epTitle) : l.adminPodcastsFailedDownload);
      if (ok) _pollDownloadQueue();
    }
    widget.onChanged();
  }

  Future<void> _deleteEpisode(String episodeId, String epTitle) async {
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.adminPodcastsDeleteEpisodeTitle),
      content: Text(l.adminPodcastsDeleteEpisodeContent(epTitle)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete, style: TextStyle(color: Colors.red.shade300)))],
    ));
    if (yes != true) return;
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    setState(() => _deleting.add(episodeId));
    final status = await api.deletePodcastEpisode(_podcastId, episodeId);
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      setState(() => _deleting.remove(episodeId));
      if (status == 200) { _msg(l2.adminPodcastsDeleted); _reloadItem(); widget.onChanged(); }
      else if (status == 403) _msg(l2.deletePermissionRequired);
      else _msg(l2.adminPodcastsFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final coverUrl = '${auth.serverUrl}/api/items/$_podcastId/cover?token=${auth.token}';
    final author = _metadata['author'] as String? ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DesktopPageBody(maxWidth: 1040, child: SafeArea(child: Column(children: [
        // Back button
        Padding(padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
          child: Row(children: [
            IconButton(icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface.withValues(alpha: 0.54)), onPressed: () => Navigator.pop(context)),
            const Spacer(),
            if (_tabCtrl.index == 1 && _feedEpisodes.isNotEmpty)
              IconButton(
                icon: Icon(
                  _feedNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: cs.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
                tooltip: _feedNewestFirst ? l.adminPodcastsSortNewestFirst : l.adminPodcastsSortOldestFirst,
                onPressed: _toggleFeedSort,
              ),
            if ((_tabCtrl.index == 0 && _episodes.isNotEmpty) || (_tabCtrl.index == 1 && _feedEpisodes.isNotEmpty))
              IconButton(
                icon: Icon(
                  Icons.checklist_rounded,
                  color: (_isSelectingDownloaded || _isSelecting) ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
                tooltip: l.adminPodcastsSelectMultipleTooltip,
                onPressed: () => setState(() {
                  if (_tabCtrl.index == 0) {
                    if (_isSelectingDownloaded) _selectedDownloadedIds.clear(); else _enterDownloadedSelectMode();
                  } else if (_tabCtrl.index == 1) {
                    if (_isSelecting) _selectedFeedIndices.clear(); else _enterFeedSelectMode();
                  }
                }),
              ),
            if (auth.isAdmin)
              IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 22), tooltip: l.adminPodcastsRemoveShowTooltip, onPressed: _removeShow),
          ])),

        // Show info
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(12),
              child: Image.network(coverUrl, width: 72, height: 72, fit: BoxFit.cover,
                headers: auth.apiService?.mediaHeaders ?? {},
                errorBuilder: (_, __, ___) => Container(width: 72, height: 72,
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.podcasts_rounded, color: cs.primary.withValues(alpha: 0.4), size: 28)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (author.isNotEmpty) ...[const SizedBox(height: 2),
                Text(author, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)))],
              const SizedBox(height: 6),
              Text(l.adminPodcastsDownloadedCount(_episodes.length), style: tt.labelSmall?.copyWith(color: cs.primary.withValues(alpha: 0.7), fontSize: 11)),
            ])),
          ])),

        // Tabs
        TabBar(
          controller: _tabCtrl,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.3),
          indicatorColor: cs.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: cs.onSurface.withValues(alpha: 0.06),
          tabs: [Tab(text: l.adminPodcastsTabDownloaded), Tab(text: l.adminPodcastsTabFeed), Tab(text: l.adminPodcastsTabSettings)],
          onTap: (i) {
            if (i == 1 && _feedEpisodes.isEmpty && !_loadingFeed) _loadFeed();
          },
        ),

        // Tab views
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildDownloadedTab(cs, tt),
          _buildFeedTab(cs, tt),
          _buildSettingsTab(cs, tt),
        ])),
      ]))),
    );
  }

  // ─── Downloaded Tab ─────────────────────────────────────────

  bool get _isSelectingDownloaded => _selectedDownloadedIds.isNotEmpty;

  void _enterDownloadedSelectMode() {
    // Select the first episode to kick off select mode
    final sorted = List.from(_episodes)..sort((a, b) {
      final aT = a['publishedAt'] as num? ?? 0; final bT = b['publishedAt'] as num? ?? 0;
      return bT.compareTo(aT);
    });
    if (sorted.isNotEmpty) {
      final id = (sorted[0] as Map<String, dynamic>)['id'] as String? ?? '';
      if (id.isNotEmpty) setState(() => _selectedDownloadedIds.add(id));
    }
  }

  void _toggleDownloadedSelection(String episodeId) {
    setState(() {
      if (_selectedDownloadedIds.contains(episodeId)) {
        _selectedDownloadedIds.remove(episodeId);
      } else {
        _selectedDownloadedIds.add(episodeId);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedDownloadedIds.isEmpty) return;
    final count = _selectedDownloadedIds.length;
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.adminPodcastsDeleteEpisodesTitle),
      content: Text(l.adminPodcastsDeleteEpisodesContent(count)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete, style: TextStyle(color: Colors.red.shade300))),
      ],
    ));
    if (yes != true) return;
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final ids = Set<String>.from(_selectedDownloadedIds);
    setState(() => _selectedDownloadedIds.clear());
    int deleted = 0;
    bool forbidden = false;
    for (final id in ids) {
      final status = await api.deletePodcastEpisode(_podcastId, id);
      if (status == 200) deleted++;
      else if (status == 403) { forbidden = true; break; }
    }
    if (mounted) {
      final l2 = AppLocalizations.of(context)!;
      if (forbidden && deleted == 0) _msg(l2.deletePermissionRequired);
      else _msg(l2.adminPodcastsDeletedEpisodes(deleted));
      _reloadItem();
      widget.onChanged();
    }
  }

  Widget _buildDownloadedTab(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    // Build list: active downloads first, then downloaded episodes
    final queueItems = <Map<String, dynamic>>[];
    if (_currentDownload != null) queueItems.add(_currentDownload!);
    for (final q in _downloadQueue) {
      if (q is Map<String, dynamic>) queueItems.add(q);
    }

    if (_episodes.isEmpty && queueItems.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.download_done_rounded, size: 40, color: cs.onSurface.withValues(alpha: 0.1)),
        const SizedBox(height: 8),
        Text(l.absorbingNoDownloadedEpisodes, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.3))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () { _tabCtrl.animateTo(1); if (_feedEpisodes.isEmpty && !_loadingFeed) _loadFeed(); },
          child: Text(l.adminPodcastsBrowseFeedToDownload, style: tt.bodySmall?.copyWith(color: cs.primary))),
      ]));
    }

    final sorted = List.from(_episodes)..sort((a, b) {
      final aT = a['publishedAt'] as num? ?? 0; final bT = b['publishedAt'] as num? ?? 0;
      return bT.compareTo(aT);
    });

    return Stack(children: [
      RefreshIndicator(
        onRefresh: _reloadItem,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 8, 16, _isSelectingDownloaded ? 80 : 16),
          itemCount: queueItems.length + sorted.length,
          itemBuilder: (_, i) {
            // Queue items first
            if (i < queueItems.length) {
              final q = queueItems[i];
              final isActive = i == 0 && _currentDownload != null;
              final title = q['episodeDisplayTitle'] as String? ?? l.adminPodcastsDownloadingDots;
              return Padding(padding: const EdgeInsets.only(bottom: 6), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  SizedBox(width: 18, height: 18, child: isActive
                    ? CircularProgressIndicator(strokeWidth: 1.5, color: cs.primary)
                    : Icon(Icons.hourglass_top_rounded, size: 16, color: cs.primary.withValues(alpha: 0.5))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(isActive ? l.adminPodcastsDownloadingDots : l.downloadsQueued,
                      style: tt.labelSmall?.copyWith(color: cs.primary.withValues(alpha: 0.7), fontSize: 10)),
                  ])),
                ]),
              ));
            }

            // Downloaded episodes
            final idx = i - queueItems.length;
            final ep = sorted[idx] as Map<String, dynamic>;
            final epId = ep['id'] as String? ?? '';
            final epTitle = ep['title']?.toString() ?? l.adminPodcastsEpisodeFallback;
            final pubAt = ep['publishedAt'] as num?;
            final duration = ep['duration'];
            final durStr = duration is num ? formatHm(duration.toDouble())
                : (duration is String ? _fmtDurFromStr(duration) : '');
            final selected = _selectedDownloadedIds.contains(epId);

            return Padding(padding: const EdgeInsets.only(bottom: 6), child: GestureDetector(
              onTap: _isSelectingDownloaded
                  ? () => _toggleDownloadedSelection(epId)
                  : () => _showDownloadedEpisodeDetail(ep),
              onLongPress: () => _toggleDownloadedSelection(epId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.red.withValues(alpha: 0.08) : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: selected ? Border.all(color: Colors.red.withValues(alpha: 0.2)) : null,
                ),
                child: Row(children: [
                  if (_isSelectingDownloaded) ...[
                    Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 20,
                      color: selected ? Colors.red.shade300 : cs.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(epTitle, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      if (pubAt != null) Text(_fmtDate(pubAt.toInt()), style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10)),
                      if (pubAt != null && durStr.isNotEmpty) Text(' · ', style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.15))),
                      if (durStr.isNotEmpty) Text(durStr, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10)),
                    ]),
                  ])),
                  if (!_isSelectingDownloaded) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.15)),
                  ],
                ]),
              ),
            ));
          },
        ),
      ),
      // Delete selected bar
      if (_isSelectingDownloaded)
        Positioned(left: 16, right: 16, bottom: 16,
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _selectedDownloadedIds.clear()),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Icon(Icons.close_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: _deleteSelected,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(l.adminPodcastsDeleteEpisodesCount(_selectedDownloadedIds.length),
                    style: tt.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
            )),
          ]),
        ),
    ]);
  }

  // ─── Feed Tab ───────────────────────────────────────────────

  bool get _isSelecting => _selectedFeedIndices.isNotEmpty;

  void _enterFeedSelectMode() {
    // Prefer the first not-yet-downloaded episode so the common "grab the new
    // ones" case starts pre-populated; fall back to the first episode so select
    // mode still engages when everything is already downloaded.
    final dlTitles = _episodes.map((e) => (e['title'] as String? ?? '').toLowerCase()).toSet();
    for (var i = 0; i < _feedEpisodes.length; i++) {
      final ep = _feedEpisodes[i] as Map<String, dynamic>;
      final title = (ep['title'] as String? ?? '').toLowerCase();
      if (!dlTitles.contains(title)) {
        setState(() => _selectedFeedIndices.add(i));
        return;
      }
    }
    if (_feedEpisodes.isNotEmpty) setState(() => _selectedFeedIndices.add(0));
  }

  void _toggleFeedSelection(int index) {
    setState(() {
      if (_selectedFeedIndices.contains(index)) {
        _selectedFeedIndices.remove(index);
      } else {
        _selectedFeedIndices.add(index);
      }
    });
  }

  void _selectAllFeed() {
    setState(() {
      _selectedFeedIndices
        ..clear()
        ..addAll(List.generate(_feedEpisodes.length, (i) => i));
    });
  }

  void _selectAllNewFeed() {
    final dlTitles = _episodes.map((e) => (e['title'] as String? ?? '').toLowerCase()).toSet();
    setState(() {
      _selectedFeedIndices.clear();
      for (var i = 0; i < _feedEpisodes.length; i++) {
        final ep = _feedEpisodes[i] as Map<String, dynamic>;
        final title = (ep['title'] as String? ?? '').toLowerCase();
        if (!dlTitles.contains(title)) _selectedFeedIndices.add(i);
      }
    });
  }

  Future<void> _downloadSelected() async {
    if (_selectedFeedIndices.isEmpty) return;
    final eps = _selectedFeedIndices
        .where((i) => i < _feedEpisodes.length)
        .map((i) => _feedEpisodes[i] as Map<String, dynamic>)
        .toList();
    final count = eps.length;
    setState(() => _selectedFeedIndices.clear());
    final api = context.read<AuthProvider>().apiService; if (api == null) return;
    final ok = await api.downloadPodcastEpisodes(_podcastId, eps);
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      _msg(ok ? l.adminPodcastsDownloadingCount(count) : l.adminPodcastsFailedDownload);
      if (ok) _pollDownloadQueue();
    }
    widget.onChanged();
  }

  Widget _feedQuickSelectChip(ColorScheme cs, TextTheme tt, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildFeedTab(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    if (_loadingFeed) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_feedUrl.isEmpty) return Center(child: Text(l.adminPodcastsNoFeedAvailable, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.3))));
    if (_feedEpisodes.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l.noEpisodesFound, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.3))),
        const SizedBox(height: 8),
        GestureDetector(onTap: _loadFeed,
          child: Text(l.retry, style: tt.bodySmall?.copyWith(color: cs.primary))),
      ]));
    }

    final dlTitles = _episodes.map((e) => (e['title'] as String? ?? '').toLowerCase()).toSet();

    return Stack(children: [
      RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 8, 16, _isSelecting ? 80 : 16),
          itemCount: _feedEpisodes.length,
          itemBuilder: (_, i) {
            final ep = _feedEpisodes[i] as Map<String, dynamic>;
            final epTitle = ep['title'] as String? ?? l.adminPodcastsEpisodeFallback;
            final pubDate = ep['publishedAt'] as num? ?? ep['pubDate'] as num?;
            final already = dlTitles.contains(epTitle.toLowerCase());
            final selected = _selectedFeedIndices.contains(i);

            return Padding(padding: const EdgeInsets.only(bottom: 6), child: GestureDetector(
              onTap: _isSelecting
                  ? () => _toggleFeedSelection(i)
                  : () => _showEpisodeDetail(ep, already),
              onLongPress: already ? null : () => _toggleFeedSelection(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: selected ? Border.all(color: cs.primary.withValues(alpha: 0.3)) : null,
                ),
                child: Row(children: [
                  if (_isSelecting) ...[
                    Icon(
                      selected ? Icons.check_circle_rounded : (already ? Icons.check_circle_rounded : Icons.circle_outlined),
                      size: 20,
                      color: selected ? cs.primary : (already ? Colors.green.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.2)),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(epTitle, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600,
                      color: already ? cs.onSurfaceVariant.withValues(alpha: 0.6) : cs.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (pubDate != null) ...[const SizedBox(height: 3),
                      Text(_fmtDate(pubDate.toInt()), style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))],
                  ])),
                  const SizedBox(width: 8),
                  if (!_isSelecting) ...[
                    if (already) Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.withValues(alpha: 0.5))
                    else Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.15)),
                  ],
                ]),
              ),
            ));
          },
        ),
      ),
      // Download selected bar
      if (_isSelecting)
        Positioned(left: 16, right: 16, bottom: 16,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Quick-select helpers
            Row(children: [
              _feedQuickSelectChip(cs, tt, Icons.playlist_add_check_rounded, l.adminPodcastsSelectAllNew, _selectAllNewFeed),
              const SizedBox(width: 8),
              _feedQuickSelectChip(cs, tt, Icons.done_all_rounded, l.adminPodcastsSelectAll, _selectAllFeed),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              GestureDetector(
                onTap: () => setState(() => _selectedFeedIndices.clear()),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Icon(Icons.close_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: _downloadSelected,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.download_rounded, size: 18, color: cs.onPrimary),
                    const SizedBox(width: 8),
                    Text(l.adminPodcastsDownloadEpisodesCount(_selectedFeedIndices.length),
                      style: tt.bodySmall?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w700)),
                  ]),
                ),
              )),
            ]),
          ]),
        ),
    ]);
  }

  // ─── Settings Tab ───────────────────────────────────────────

  Widget _buildSettingsTab(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    final autoDownload = _media['autoDownloadEpisodes'] == true;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
      // Check for new episodes with limit
      StatefulBuilder(builder: (ctx, setCheckState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.cloud_download_rounded, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.adminPodcastsCheckNewEpisodesTitle, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(l.adminPodcastsCheckNewEpisodesSubtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ])),
            ]),
            const SizedBox(height: 12),
            // Date picker
            Text(l.adminPodcastsLookForEpisodesAfter, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _checkAfterDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  // Also pick time
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_checkAfterDate ?? DateTime.now()),
                  );
                  final dt = time != null
                      ? DateTime(picked.year, picked.month, picked.day, time.hour, time.minute)
                      : DateTime(picked.year, picked.month, picked.day);
                  setCheckState(() => _checkAfterDate = dt);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    _checkAfterDate != null ? _fmtDateTime(_checkAfterDate!) : l.adminPodcastsSelectDate,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.2)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Limit chips
            Text(l.adminPodcastsMaxEpisodes, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final n in [1, 3, 5, 10, 25])
                GestureDetector(
                  onTap: () => setCheckState(() => _checkLimit = n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _checkLimit == n ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _checkLimit == n ? cs.primary.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.06)),
                    ),
                    child: Text('$n', style: tt.labelSmall?.copyWith(
                      color: _checkLimit == n ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                      fontWeight: _checkLimit == n ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final api = context.read<AuthProvider>().apiService;
                if (api == null) return;
                // Set lastEpisodeCheck to the selected date before checking
                if (_checkAfterDate != null) {
                  await api.updatePodcastMedia(_podcastId, {
                    'lastEpisodeCheck': _checkAfterDate!.millisecondsSinceEpoch,
                  });
                }
                _msg(l.adminPodcastsCheckingForNewDots);
                final episodes = await api.checkNewPodcastEpisodes(_podcastId, limit: _checkLimit);
                if (!mounted) return;
                if (episodes != null) {
                  _reloadItem();
                  _loadFeed();
                  if (episodes.isEmpty) {
                    _msg(l.adminPodcastsNoNewEpisodesAfter(_fmtDate(_checkAfterDate!.millisecondsSinceEpoch)));
                  } else {
                    _msg(l.adminPodcastsFoundNewEpisodes(episodes.length));
                    _pollDownloadQueue();
                  }
                } else {
                  _msg(l.adminPodcastsFailedToCheckNew);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(l.adminPodcastsCheckAndDownload, style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700))),
              ),
            ),
          ]),
        );
      }),

      // Edit show info
      if (context.read<AuthProvider>().isAdmin)
        GestureDetector(
          onTap: _openEditInfo,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(Icons.edit_note_rounded, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.adminPodcastsEditInfo, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(l.adminPodcastsEditInfoSubtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ])),
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            ]),
          ),
        ),

      // Match podcast metadata
      GestureDetector(
        onTap: () => _showMatchSheet(cs, tt),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(Icons.auto_fix_high_rounded, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.adminPodcastsMatchPodcast, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(l.adminPodcastsMatchPodcastSubtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ])),
            Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          ]),
        ),
      ),

      // Auto-download toggle
      StatefulBuilder(builder: (ctx, setLocalState) {
        final isOn = _media['autoDownloadEpisodes'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(Icons.downloading_rounded, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.adminPodcastsAutoDownloadNewEpisodes, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(
                isOn ? l.adminPodcastsAutoDownloadOnSubtitle : l.adminPodcastsAutoDownloadOffSubtitle,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ])),
            SizedBox(
              height: 32,
              child: FittedBox(fit: BoxFit.contain, child: Switch(
                value: isOn,
                onChanged: (v) async {
                  final api = context.read<AuthProvider>().apiService;
                  if (api == null) return;
                  final ok = await api.updatePodcastMedia(_podcastId, {
                    'autoDownloadEpisodes': v,
                    if (v && !isOn) 'autoDownloadSchedule': '0 * * * *',
                  });
                  if (mounted) {
                    if (ok) {
                      final media = _item['media'];
                      if (media is Map<String, dynamic>) {
                        media['autoDownloadEpisodes'] = v;
                        if (!v) media.remove('autoDownloadSchedule');
                      }
                    } else {
                      _msg(l.adminPodcastsFailedAutoDownloadUpdate);
                    }
                    setLocalState(() {});
                    setState(() {});
                    widget.onChanged();
                  }
                },
              )),
            ),
          ]),
        );
      }),

      // Schedule picker
      if (autoDownload)
        StatefulBuilder(builder: (ctx, setScheduleState) {
          final currentCron = _media['autoDownloadSchedule'] as String? ?? '0 * * * *';
          final parsed = _parseCron(currentCron);
          final freq = parsed.$1;      // 'hourly', 'daily', 'weekly'
          final hour = parsed.$2;      // 0-23
          final minute = parsed.$3;    // 0-59
          final dayOfWeek = parsed.$4; // 0-6 (Sun-Sat)
          final serverTimeZone = context.read<AuthProvider>()
              .serverSettings?['timeZone'] as String?;

          void saveCron(String f, int h, int m, int d) {
            String cron;
            if (f == 'hourly') {
              cron = '0 * * * *';
            } else if (f == 'daily') {
              cron = '$m $h * * *';
            } else {
              cron = '$m $h * * $d';
            }
            final api = context.read<AuthProvider>().apiService;
            if (api == null) return;
            api.updatePodcastMedia(_podcastId, {'autoDownloadSchedule': cron}).then((ok) {
              if (ok && mounted) {
                _media['autoDownloadSchedule'] = cron;
                setScheduleState(() {});
                widget.onChanged();
              }
            });
          }

          final days = [
            l.adminPodcastsDaySun,
            l.adminPodcastsDayMon,
            l.adminPodcastsDayTue,
            l.adminPodcastsDayWed,
            l.adminPodcastsDayThu,
            l.adminPodcastsDayFri,
            l.adminPodcastsDaySat,
          ];
          String timeLabel(int h, int m) {
            final period = h < 12 ? 'am' : 'pm';
            final displayH = h == 0 ? 12 : h > 12 ? h - 12 : h;
            return m == 0 ? '$displayH$period' : '$displayH:${m.toString().padLeft(2, '0')}$period';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.schedule_rounded, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(l.adminPodcastsCheckSchedule, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              ]),
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Text(serverTimeZone == null
                    ? l.podcastScheduleServerTimeUnknown
                    : l.podcastScheduleServerTime(serverTimeZone),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 10),
              // Frequency
              Text(l.adminPodcastsFrequency, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final f in [('hourly', l.adminPodcastsFreqHourly), ('daily', l.adminPodcastsFreqDaily), ('weekly', l.adminPodcastsFreqWeekly)])
                  _scheduleChip(cs, tt, f.$2, f.$1, freq, () => saveCron(f.$1, hour, minute, dayOfWeek)),
              ]),
              // Day of week (weekly only)
              if (freq == 'weekly') ...[
                const SizedBox(height: 12),
                Text(l.adminPodcastsDay, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (int i = 0; i < 7; i++)
                    _scheduleChip(cs, tt, days[i], i.toString(), dayOfWeek.toString(), () => saveCron(freq, hour, minute, i)),
                ]),
              ],
              // Time (daily/weekly only)
              if (freq != 'hourly') ...[
                const SizedBox(height: 12),
                Text(l.adminPodcastsTime, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: hour, minute: minute),
                      builder: (ctx, child) => MediaQuery(
                        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
                        child: child!,
                      ),
                    );
                    if (picked != null) saveCron(freq, picked.hour, picked.minute, dayOfWeek);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.access_time_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(timeLabel(hour, minute), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(currentCron, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontFamily: 'monospace', fontSize: 10)),
            ]),
          );
        }),

      // Feed URL
      if (_feedUrl.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(Icons.rss_feed_rounded, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.adminPodcastsFeedUrl, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(_feedUrl, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
    ]);
  }

  void _openEditInfo() {
    final tags = (_media['tags'] as List<dynamic>?)?.whereType<String>().toList() ?? <String>[];
    contentNavigator(context).push(MaterialPageRoute(
      builder: (_) => PodcastEditScreen(
        itemId: _podcastId,
        metadata: Map<String, dynamic>.from(_metadata),
        tags: tags,
        onSaved: () {
          _reloadItem();
          widget.onChanged();
        },
      ),
    ));
  }

  void _showMatchSheet(ColorScheme cs, TextTheme tt) {
    showAdaptiveActionMenu(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      desktopWidth: 640,
      desktopScrollWrap: false,
      builder: (_) => _PodcastMatchSheet(
        podcastId: _podcastId,
        initialQuery: _title,
        onMatched: () {
          _reloadItem();
          widget.onChanged();
        },
      ),
    );
  }

  void _showEpisodeDetail(Map<String, dynamic> ep, bool alreadyDownloaded) {
    final canDownload = context.read<AuthProvider>().isAdmin;
    showAdaptiveActionMenu(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      desktopWidth: 640,
      desktopScrollWrap: false,
      builder: (_) => _EpisodeDetailSheet(
        episode: ep,
        alreadyDownloaded: alreadyDownloaded,
        canDownload: canDownload,
        onDownload: () {
          Navigator.pop(context);
          _downloadEpisode(ep);
        },
      ),
    );
  }

  void _showDownloadedEpisodeDetail(Map<String, dynamic> ep) {
    final epId = ep['id']?.toString() ?? '';
    final epTitle = ep['title']?.toString() ?? AppLocalizations.of(context)!.adminPodcastsEpisodeFallback;
    showAdaptiveActionMenu(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      desktopWidth: 640,
      desktopScrollWrap: false,
      builder: (_) => _DownloadedEpisodeDetailSheet(
        episode: ep,
        isDeleting: _deleting.contains(epId),
        onDelete: () {
          Navigator.pop(context);
          _deleteEpisode(epId, epTitle);
        },
      ),
    );
  }

  /// Parse a cron string into (frequency, hour, minute, dayOfWeek).
  (String, int, int, int) _parseCron(String cron) {
    final parts = cron.split(' ');
    if (parts.length < 5) return ('hourly', 0, 0, 1);
    final minPart = parts[0];
    final hourPart = parts[1];
    final dowPart = parts[4];
    if (hourPart == '*' || hourPart.startsWith('*/')) return ('hourly', 0, 0, 1);
    final hour = int.tryParse(hourPart) ?? 0;
    final minute = int.tryParse(minPart) ?? 0;
    if (dowPart != '*') {
      final dow = int.tryParse(dowPart) ?? 1;
      return ('weekly', hour, minute, dow);
    }
    return ('daily', hour, minute, 1);
  }

  Widget _scheduleChip(ColorScheme cs, TextTheme tt, String label, String value, String current, VoidCallback onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: selected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? cs.primary.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? cs.primary : cs.onSurfaceVariant,
        )),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

  String _fmtDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _fmtDurFromStr(String s) {
    if (s.contains(':')) return s;
    final secs = double.tryParse(s) ?? 0;
    if (secs <= 0) return '';
    return formatHm(secs);
  }

  String _fmtDateTime(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final h = dt.hour == 0 ? 12 : dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year} $h:$min $period';
  }
  // Note: month abbreviations and AM/PM are intentionally kept inline as they
  // are date format primitives consistent with how _fmtDate is used in
  // similar admin/users context. Could be moved to ARB later if needed.

  void _msg(String s, {IconData? icon}) =>
      showOverlayToast(context, s, icon: icon);
}


// ═══════════════════════════════════════════════════════════════
//  Episode Detail Sheet
// ═══════════════════════════════════════════════════════════════

class _EpisodeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> episode;
  final bool alreadyDownloaded;
  final bool canDownload;
  final VoidCallback onDownload;
  const _EpisodeDetailSheet({required this.episode, required this.alreadyDownloaded, this.canDownload = true, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final title = episode['title']?.toString() ?? l.adminPodcastsEpisodeFallback;
    final descriptionHtml = episode['description']?.toString() ?? episode['subtitle']?.toString() ?? '';
    final pubDateRaw = episode['publishedAt'] ?? episode['pubDate'];
    final pubDate = pubDateRaw is num ? pubDateRaw : (num.tryParse(pubDateRaw?.toString() ?? ''));
    final duration = episode['duration']?.toString() ?? '';
    final season = episode['season']?.toString() ?? '';
    final episodeNum = episode['episode']?.toString() ?? '';
    final episodeType = episode['episodeType']?.toString() ?? '';

    // Size from enclosure
    final enclosure = episode['enclosure'] is Map ? episode['enclosure'] as Map<String, dynamic> : null;
    final sizeRaw = enclosure?['length'];
    final sizeBytes = sizeRaw is num ? sizeRaw.toInt() : (int.tryParse(sizeRaw?.toString() ?? '') ?? 0);
    final sizeStr = _fmtSize(sizeBytes);
    final fileType = enclosure?['type']?.toString() ?? '';

    // Build info chips
    final chips = <String>[];
    if (pubDate != null) chips.add(_fmtDate(pubDate.toInt()));
    if (duration.isNotEmpty) chips.add(duration.contains(':') ? duration : _fmtDurStr(duration));
    if (sizeStr.isNotEmpty) chips.add(sizeStr);
    if (season.isNotEmpty) chips.add(l.adminPodcastsSeasonChip(season));
    if (episodeNum.isNotEmpty) chips.add(l.adminPodcastsEpChip(episodeNum));
    if (episodeType.isNotEmpty && episodeType != 'full') chips.add(episodeType);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(color: Theme.of(context).bottomSheetTheme.backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4,
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)))),

        // Title
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Align(alignment: Alignment.centerLeft,
            child: Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 3, overflow: TextOverflow.ellipsis))),

        // Info chips
        if (chips.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Align(alignment: Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 6, children: chips.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
                child: Text(c, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11)),
              )).toList()))),

        // File type
        if (fileType.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(alignment: Alignment.centerLeft,
              child: Text(fileType, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10)))),

        // Description
        if (descriptionHtml.isNotEmpty)
          Flexible(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SingleChildScrollView(
                child: SizedBox(width: double.infinity,
                  child: HtmlDescription(
                    html: descriptionHtml,
                    maxLines: 200,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.54), height: 1.5),
                    linkColor: cs.primary,
                  )),
              )),
          ),

        // Buttons
        Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l.adminPodcastsBack, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2,
              child: FilledButton.icon(
                onPressed: (alreadyDownloaded || !canDownload) ? null : onDownload,
                icon: Icon(alreadyDownloaded ? Icons.check_circle_rounded : Icons.download_rounded, size: 18),
                label: Text(alreadyDownloaded ? l.downloaded : !canDownload ? l.adminPodcastsRootOnly : l.download,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: alreadyDownloaded ? Colors.green.withValues(alpha: 0.15) : cs.primary,
                  foregroundColor: alreadyDownloaded ? Colors.green : cs.onPrimary,
                  disabledBackgroundColor: alreadyDownloaded ? Colors.green.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.06),
                  disabledForegroundColor: alreadyDownloaded ? Colors.green : cs.onSurfaceVariant.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _fmtDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _fmtSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _fmtDurStr(String s) {
    final secs = double.tryParse(s) ?? 0;
    if (secs <= 0) return s;
    return formatHm(secs);
  }
}


// ═══════════════════════════════════════════════════════════════
//  Downloaded Episode Detail Sheet
// ═══════════════════════════════════════════════════════════════

class _DownloadedEpisodeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> episode;
  final bool isDeleting;
  final VoidCallback onDelete;
  const _DownloadedEpisodeDetailSheet({required this.episode, required this.isDeleting, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final title = episode['title']?.toString() ?? l.adminPodcastsEpisodeFallback;
    final descriptionHtml = episode['description']?.toString() ?? episode['subtitle']?.toString() ?? '';
    final pubAt = episode['publishedAt'];
    final pubDate = pubAt is num ? pubAt : (num.tryParse(pubAt?.toString() ?? ''));
    final durRaw = episode['duration'];
    final durStr = durRaw is num ? formatHm(durRaw.toDouble())
        : (durRaw is String && durRaw.isNotEmpty ? (durRaw.contains(':') ? durRaw : _fmtDurStr(durRaw)) : '');
    final season = episode['season']?.toString() ?? '';
    final episodeNum = episode['episode']?.toString() ?? '';

    // Size from audioFile if available
    final audioFile = episode['audioFile'] as Map<String, dynamic>?;
    final sizeRaw = audioFile?['metadata']?['size'] ?? episode['size'];
    final sizeBytes = sizeRaw is num ? sizeRaw.toInt() : (int.tryParse(sizeRaw?.toString() ?? '') ?? 0);
    final sizeStr = _fmtSize(sizeBytes);

    final chips = <String>[];
    if (pubDate != null) chips.add(_fmtDate(pubDate.toInt()));
    if (durStr.isNotEmpty) chips.add(durStr);
    if (sizeStr.isNotEmpty) chips.add(sizeStr);
    if (season.isNotEmpty) chips.add(l.adminPodcastsSeasonChip(season));
    if (episodeNum.isNotEmpty) chips.add(l.adminPodcastsEpChip(episodeNum));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(color: Theme.of(context).bottomSheetTheme.backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4,
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)))),

        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Align(alignment: Alignment.centerLeft,
            child: Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 3, overflow: TextOverflow.ellipsis))),

        if (chips.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Align(alignment: Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 6, children: chips.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
                child: Text(c, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11)),
              )).toList()))),

        if (descriptionHtml.isNotEmpty)
          Flexible(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SingleChildScrollView(
                child: SizedBox(width: double.infinity,
                  child: HtmlDescription(
                    html: descriptionHtml,
                    maxLines: 200,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.54), height: 1.5),
                    linkColor: cs.primary,
                  )),
              )),
          ),

        Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l.adminPodcastsBack, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2,
              child: FilledButton.icon(
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onSurface.withValues(alpha: 0.54)))
                  : const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(isDeleting ? l.adminPodcastsDeleting : l.adminPodcastsDeleteEpisode,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  foregroundColor: Colors.red.shade300,
                  disabledBackgroundColor: Colors.red.withValues(alpha: 0.08),
                  disabledForegroundColor: Colors.red.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _fmtDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _fmtSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _fmtDurStr(String s) {
    if (s.contains(':')) return s;
    final secs = double.tryParse(s) ?? 0;
    if (secs <= 0) return s;
    return formatHm(secs);
  }
}


// ═══════════════════════════════════════════════════════════════
//  Podcast Match Sheet
// ═══════════════════════════════════════════════════════════════

class _PodcastMatchSheet extends StatefulWidget {
  final String podcastId;
  final String initialQuery;
  final VoidCallback onMatched;
  const _PodcastMatchSheet({required this.podcastId, required this.initialQuery, required this.onMatched});
  @override State<_PodcastMatchSheet> createState() => _PodcastMatchSheetState();
}

class _PodcastMatchSheetState extends State<_PodcastMatchSheet> {
  late final TextEditingController _ctrl;
  bool _searching = false;
  bool _applying = false;
  List<dynamic> _results = [];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    _search();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _ctrl.text.trim(); if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final api = context.read<AuthProvider>().apiService;
    if (api != null) _results = await api.searchPodcasts(q);
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _applyMatch(Map<String, dynamic> pod) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    setState(() => _applying = true);
    final title = pod['title'] as String? ?? pod['trackName'] as String? ?? pod['collectionName'] as String?;
    final author = pod['artistName'] as String? ?? pod['author'] as String?;
    final result = await api.matchLibraryItem(
      widget.podcastId,
      title: title,
      author: author,
      overrideCover: true,
      overrideDetails: true,
    );
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() => _applying = false);
      if (result != null) {
        widget.onMatched();
        showOverlayToast(
          context,
          l.adminPodcastsPodcastMatched,
          icon: Icons.check_circle_outline_rounded,
        );
        Navigator.pop(context);
      } else {
        showOverlayToast(
          context,
          l.adminPodcastsFailedMatch,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Map<String, dynamic> _extractPod(dynamic item) {
    if (item is Map<String, dynamic>) {
      if (item.containsKey('podcast')) return item['podcast'] as Map<String, dynamic>;
      return item;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AdaptiveDraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.05,
        maxChildSize: 0.95,
        expand: false,
        desktopMaxHeight: 680,
        builder: (ctx, sc) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(children: [
              Expanded(child: Text(l.adminPodcastsMatchPodcast, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface))),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.6), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: cs.onSurface),
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: l.adminPodcastsSearchItunesHint,
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.25)),
                prefixIcon: Icon(Icons.search_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
                suffixIcon: _searching
                    ? Padding(padding: const EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onSurfaceVariant.withValues(alpha: 0.6))))
                    : IconButton(icon: Icon(Icons.arrow_forward_rounded, color: cs.primary), onPressed: _search),
                filled: true,
                fillColor: cs.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.1)),
          // Results
          Expanded(
            child: _applying
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(height: 12),
                    Text(l.adminPodcastsApplyingMatch, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
                  ]))
                : _searching
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _results.isEmpty
                        ? Center(child: Text(l.adminPodcastsNoResults, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24))))
                        : ListView.builder(
                            controller: sc,
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + MediaQuery.of(context).viewPadding.bottom),
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final pod = _extractPod(_results[i]);
                              final title = pod['title'] as String? ?? pod['trackName'] as String? ?? pod['collectionName'] as String? ?? l.unknown;
                              final author = pod['artistName'] as String? ?? pod['author'] as String? ?? '';
                              final imageUrl = pod['cover'] as String? ?? pod['imageUrl'] as String? ?? pod['artworkUrl600'] as String? ?? pod['artworkUrl100'] as String? ?? '';
                              final genres = (pod['genres'] as List?)?.whereType<String>().where((g) => g != 'Podcasts').toList();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: () => _applyMatch(pod),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cs.onSurface.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _ph(cs))
                                            : _ph(cs),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                        if (author.isNotEmpty) ...[const SizedBox(height: 2),
                                          Text(author, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                                            maxLines: 1, overflow: TextOverflow.ellipsis)],
                                        if (genres != null && genres.isNotEmpty) ...[const SizedBox(height: 3),
                                          Text(genres.take(3).join(', '), style: tt.labelSmall?.copyWith(
                                            color: cs.primary.withValues(alpha: 0.5), fontSize: 10))],
                                      ])),
                                      const SizedBox(width: 8),
                                      Icon(Icons.check_circle_outline_rounded, color: cs.primary.withValues(alpha: 0.4)),
                                    ]),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ]),
      ),
    );
  }

  Widget _ph(ColorScheme cs) => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Icon(Icons.podcasts_rounded, color: cs.primary.withValues(alpha: 0.4), size: 22),
  );
}
