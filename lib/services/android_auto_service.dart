import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'download_service.dart';
import 'progress_sync_service.dart';

// ─── Media ID scheme ─────────────────────────────────────────────────
//
// Root tabs (max 4):
//   continue          → list of in-progress books
//   recent            → list of recently added books (default library)
//   library           → list of book-type libraries
//   downloads         → list of downloaded books
//
// Library drilldown:
//   lib:<libraryId>              → sub-categories (Books, Series, Authors)
//   lib:<libraryId>:books        → all books in library
//   lib:<libraryId>:series       → list of series
//   lib:<libraryId>:authors      → list of authors
//   series:<seriesId>@<libId>    → books in that series
//   author:<authorId>@<libId>    → books by that author
//
// Playable items:
//   item:<absItemId>             → a playable book
// ─────────────────────────────────────────────────────────────────────

class AutoMediaIds {
  // Root tabs
  static const root = 'root';
  static const continueListening = 'continue';
  static const recent = 'recent';
  static const library = 'library';
  static const downloads = 'downloads';

  // Prefixes
  static const itemPrefix = 'item:';
  static const libPrefix = 'lib:';
  static const seriesPrefix = 'series:';
  static const authorPrefix = 'author:';

  // Build IDs
  static String itemId(String absId) => '$itemPrefix$absId';
  static String libId(String libraryId) => '$libPrefix$libraryId';
  static String libBooks(String libraryId) => '$libPrefix$libraryId:books';
  static String libSeries(String libraryId) => '$libPrefix$libraryId:series';
  static String libAuthors(String libraryId) => '$libPrefix$libraryId:authors';
  static String seriesId(String sId, String libId) => '$seriesPrefix$sId@$libId';
  static String authorId(String aId, String libId) => '$authorPrefix$aId@$libId';

  // Parse helpers
  static String? absItemId(String mediaId) =>
      mediaId.startsWith(itemPrefix) ? mediaId.substring(itemPrefix.length) : null;

  /// Parse "series:<seriesId>@<libId>" → {seriesId, libId}
  static ({String seriesId, String libId})? parseSeries(String mediaId) {
    if (!mediaId.startsWith(seriesPrefix)) return null;
    final rest = mediaId.substring(seriesPrefix.length);
    final at = rest.indexOf('@');
    if (at < 0) return null;
    return (seriesId: rest.substring(0, at), libId: rest.substring(at + 1));
  }

  /// Parse "author:<authorId>@<libId>" → {authorId, libId}
  static ({String authorId, String libId})? parseAuthor(String mediaId) {
    if (!mediaId.startsWith(authorPrefix)) return null;
    final rest = mediaId.substring(authorPrefix.length);
    final at = rest.indexOf('@');
    if (at < 0) return null;
    return (authorId: rest.substring(0, at), libId: rest.substring(at + 1));
  }

  /// Parse "lib:<libraryId>" or "lib:<libraryId>:books" etc.
  static String? parseLibId(String mediaId) {
    if (!mediaId.startsWith(libPrefix)) return null;
    final rest = mediaId.substring(libPrefix.length);
    final colon = rest.indexOf(':');
    return colon >= 0 ? rest.substring(0, colon) : rest;
  }

  /// Parse sub-category from "lib:<libraryId>:<sub>"
  static String? parseLibSub(String mediaId) {
    if (!mediaId.startsWith(libPrefix)) return null;
    final rest = mediaId.substring(libPrefix.length);
    final colon = rest.indexOf(':');
    return colon >= 0 ? rest.substring(colon + 1) : null;
  }
}

// ─── Data models ─────────────────────────────────────────────────────

class AutoBookEntry {
  final String id;
  final String title;
  final String author;
  final double duration;
  final String? coverUrl;
  final List<dynamic> chapters;
  final double? currentTime;

  const AutoBookEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    this.coverUrl,
    this.chapters = const [],
    this.currentTime,
  });

  MediaItem toMediaItem() {
    final uri = coverUrl != null ? Uri.tryParse(coverUrl!) : null;
    return MediaItem(
      id: AutoMediaIds.itemId(id),
      title: title,
      artist: author,
      album: title,
      duration: Duration(seconds: duration.round()),
      artUri: uri,
      playable: true,
      extras: uri != null ? {'artUri': uri.toString()} : null,
    );
  }
}

class AutoLibraryEntry {
  final String id;
  final String name;
  final String mediaType;

  const AutoLibraryEntry({
    required this.id,
    required this.name,
    required this.mediaType,
  });

  bool get isBook => mediaType == 'book';
}

// ─── Android Auto Service ────────────────────────────────────────────

class AndroidAutoService {
  static final AndroidAutoService _instance = AndroidAutoService._();
  factory AndroidAutoService() => _instance;
  AndroidAutoService._();

  // ── Cached data ──
  List<AutoBookEntry> _continueListening = [];
  List<AutoBookEntry> _downloaded = [];
  List<AutoBookEntry> _recentlyAdded = [];
  List<AutoLibraryEntry> _libraries = [];

  DateTime? _lastRefresh;
  bool _isRefreshing = false;

  // ── API helpers ──

  Future<ApiService?> getApi() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('server_url');
    final token = prefs.getString('token');
    if (url == null || token == null) return null;
    return ApiService(baseUrl: url, token: token);
  }

  Future<String?> getDefaultLibraryId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('default_library_id');
  }

  // ── Refresh ──

  /// Whether downloads have been populated at least once (synchronous, no server needed).
  bool _downloadsReady = false;

  /// Fire-and-forget server refresh. Downloads are already available;
  /// this populates Continue, Recent, and Library tabs in the background.
  void _backgroundRefresh() {
    refresh().then((_) {
      debugPrint('[AndroidAuto] Background refresh completed');
    }).catchError((e) {
      debugPrint('[AndroidAuto] Background refresh failed: $e');
    });
  }

  Future<void> refresh({bool force = false}) async {
    // Always populate downloads immediately — no server needed.
    // This ensures Android Auto can show the Downloads tab even if the
    // server is unreachable (e.g. no remote access, offline-only users).
    if (!_downloadsReady || force) {
      await _refreshDownloaded();
      _downloadsReady = true;
    }

    if (_isRefreshing) return;
    if (!force && _lastRefresh != null &&
        DateTime.now().difference(_lastRefresh!) < const Duration(seconds: 30)) {
      return;
    }

    _isRefreshing = true;
    debugPrint('[AndroidAuto] Refreshing browse tree...');

    // Server fetch is best-effort — don't block the browse tree
    try {
      await _refreshDownloaded(); // re-fetch in case downloads changed
      await _refreshFromServer();
      _lastRefresh = DateTime.now();
      debugPrint('[AndroidAuto] Refresh done: '
          '${_continueListening.length} continue, '
          '${_downloaded.length} downloaded, '
          '${_recentlyAdded.length} recent, '
          '${_libraries.length} libraries '
          '(${_libraries.where((l) => l.isBook).length} book-type)');
    } catch (e) {
      // Server unreachable — downloads are still available.
      _lastRefresh = DateTime.now();
      debugPrint('[AndroidAuto] Server refresh failed (downloads still available): $e');
    } finally {
      _isRefreshing = false;
      // Tell the head unit to re-fetch the root browse tree now that data has changed.
      try {
        // ignore: deprecated_member_use
        await AudioServiceBackground.notifyChildrenChanged(AutoMediaIds.root);
      } catch (_) {}
    }
  }

  /// Content provider authority for serving local cover images to Android Auto.
  /// Must match the authority registered in AndroidManifest.xml.
  static const _coverAuthority = 'com.barnabas.absorb.covers';

  /// Build a content:// URI for a locally cached cover image.
  /// Android Auto requires content:// URIs — file:// won't work.
  static String _localCoverUri(String itemId) =>
      'content://$_coverAuthority/cover/$itemId';

  Future<void> _refreshDownloaded() async {
    final ds = DownloadService();
    final api = await getApi();
    final items = ds.downloadedItems;
    final entries = <AutoBookEntry>[];

    for (final dl in items) {
      double duration = 0;
      List<dynamic> chapters = [];
      if (dl.sessionData != null) {
        try {
          final session = jsonDecode(dl.sessionData!) as Map<String, dynamic>;
          duration = (session['duration'] as num?)?.toDouble() ?? 0;
          chapters = session['chapters'] as List<dynamic>? ?? [];
        } catch (_) {}
      }

      final localPos = await ProgressSyncService().getSavedPosition(dl.itemId);

      // Use HTTP cover URLs when online (more reliable in AA browse list),
      // fall back to local content:// URIs when offline.
      String? coverUrl;
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);
      if (isOnline && api != null) {
        coverUrl = api.getCoverUrl(dl.itemId, width: 400);
      } else {
        final localCover = await ds.getLocalCoverPath(dl.itemId);
        if (localCover != null) {
          coverUrl = _localCoverUri(dl.itemId);
        }
      }

      entries.add(AutoBookEntry(
        id: dl.itemId,
        title: dl.title ?? 'Unknown',
        author: dl.author ?? '',
        duration: duration,
        coverUrl: coverUrl,
        chapters: chapters,
        currentTime: localPos > 0 ? localPos : null,
      ));
      debugPrint('[AndroidAuto] Download entry: ${dl.title} cover=${coverUrl ?? "null"}');
    }

    _downloaded = entries;
  }

  Future<void> _refreshFromServer() async {
    final api = await getApi();
    if (api == null) return;

    final prefs = await SharedPreferences.getInstance();
    final manualOffline = prefs.getBool('manual_offline_mode') ?? false;
    if (manualOffline) {
      _continueListening = [];
      _recentlyAdded = [];
      _libraries = [];
      return;
    }

    try {
      // ── Fetch all libraries (filter out podcasts) ──
      final libs = await api.getLibraries();
      _libraries = libs.map((l) {
        final m = l as Map<String, dynamic>;
        return AutoLibraryEntry(
          id: m['id'] as String? ?? '',
          name: m['name'] as String? ?? 'Library',
          mediaType: m['mediaType'] as String? ?? 'book',
        );
      }).where((l) => l.id.isNotEmpty && l.isBook).toList();

      // ── Continue Listening (from default library) ──
      final defaultLibId = await getDefaultLibraryId();
      if (defaultLibId != null) {
        final sections = await api.getPersonalizedView(
          defaultLibId,
          include: const ['numEpisodesIncomplete'],
          shelves: const ['continue-listening', 'continue-series'],
          limit: 10,
        );
        final continueEntries = <AutoBookEntry>[];
        final seenIds = <String>{};

        for (final section in sections) {
          final sectionId = section['id'] as String? ?? '';
          if (sectionId == 'continue-listening' || sectionId == 'continue-series') {
            for (final entity in (section['entities'] as List<dynamic>? ?? [])) {
              if (entity is Map<String, dynamic>) {
                final entry = _entityToEntry(entity, api);
                if (entry != null && seenIds.add(entry.id)) {
                  continueEntries.add(entry);
                }
              }
            }
          }
        }
        _continueListening = continueEntries;

        // ── Recently Added (default library) ──
        final recentResult = await api.getLibraryItems(
          defaultLibId, limit: 30, sort: 'addedAt', desc: 1,
        );
        if (recentResult != null) {
          _recentlyAdded = _resultsToEntries(recentResult, api);
        }
      }
    } catch (e) {
      // Server unreachable — clear stale tabs so only Downloads shows offline
      _continueListening = [];
      _recentlyAdded = [];
      _libraries = [];
      debugPrint('[AndroidAuto] Server fetch error: $e');
    }
  }

  // ── Data conversion ──

  List<AutoBookEntry> _resultsToEntries(
      Map<String, dynamic> result, ApiService api) {
    final results = result['results'] as List<dynamic>? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((item) => _libraryItemToEntry(item, api))
        .whereType<AutoBookEntry>()
        .toList();
  }

  AutoBookEntry? _entityToEntry(Map<String, dynamic> entity, ApiService api) {
    final id = entity['id'] as String?;
    if (id == null) return null;

    final media = entity['media'] as Map<String, dynamic>?;
    final metadata = media?['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? 'Unknown';
    final author = metadata['authorName'] as String? ?? '';
    final duration = (media?['duration'] as num?)?.toDouble() ?? 0;
    final chapters = media?['chapters'] as List<dynamic>? ?? [];

    final progress = entity['mediaProgress'] as Map<String, dynamic>?;
    final currentTime = (progress?['currentTime'] as num?)?.toDouble();

    return AutoBookEntry(
      id: id,
      title: title,
      author: author,
      duration: duration,
      coverUrl: api.getCoverUrl(id, width: 400),
      chapters: chapters,
      currentTime: currentTime,
    );
  }

  AutoBookEntry? _libraryItemToEntry(
      Map<String, dynamic> item, ApiService api) {
    final id = item['id'] as String?;
    if (id == null) return null;

    final media = item['media'] as Map<String, dynamic>?;
    final metadata = media?['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? 'Unknown';
    final author = metadata['authorName'] as String? ?? '';
    final duration = (media?['duration'] as num?)?.toDouble() ?? 0;
    final chapters = media?['chapters'] as List<dynamic>? ?? [];

    return AutoBookEntry(
      id: id,
      title: title,
      author: author,
      duration: duration,
      coverUrl: api.getCoverUrl(id, width: 400),
      chapters: chapters,
    );
  }

  // ─── Browse tree ───────────────────────────────────────────────────

  List<MediaItem> _getRootChildren() {
    final tabs = <MediaItem>[];

    if (_continueListening.isNotEmpty) {
      tabs.add(const MediaItem(
        id: AutoMediaIds.continueListening,
        title: 'Continue',
        playable: false,
      ));
    }

    if (_recentlyAdded.isNotEmpty) {
      tabs.add(const MediaItem(
        id: AutoMediaIds.recent,
        title: 'Recent',
        playable: false,
      ));
    }

    if (_libraries.isNotEmpty) {
      tabs.add(const MediaItem(
        id: AutoMediaIds.library,
        title: 'Library',
        playable: false,
      ));
    }

    if (_downloaded.isNotEmpty) {
      tabs.add(const MediaItem(
        id: AutoMediaIds.downloads,
        title: 'Downloads',
        playable: false,
      ));
    }

    if (tabs.isEmpty) {
      tabs.add(const MediaItem(
        id: AutoMediaIds.library,
        title: 'Library',
        playable: false,
      ));
    }

    return tabs;
  }

  /// Library tab → list of book-type libraries
  List<MediaItem> _getLibraryList() {
    // If only one book library, skip the picker — go straight to sub-categories
    // (handled by caller checking length)
    return _libraries.map((lib) {
      return MediaItem(
        id: AutoMediaIds.libId(lib.id),
        title: lib.name,
        playable: false,
      );
    }).toList();
  }

  /// Sub-categories for a library: Books, Series, Authors
  List<MediaItem> _getLibrarySubCategories(String libraryId) {
    return [
      MediaItem(
        id: AutoMediaIds.libBooks(libraryId),
        title: 'Books',
        playable: false,
      ),
      MediaItem(
        id: AutoMediaIds.libSeries(libraryId),
        title: 'Series',
        playable: false,
      ),
      MediaItem(
        id: AutoMediaIds.libAuthors(libraryId),
        title: 'Authors',
        playable: false,
      ),
    ];
  }

  /// Main entry point for browse tree. May make API calls for drilldowns.
  Future<List<MediaItem>> getChildrenOf(String parentMediaId) async {
    // Ensure downloads are always populated before returning root.
    // This is instant (no network) so Android Auto never waits on a server.
    if (!_downloadsReady) {
      await _refreshDownloaded();
      _downloadsReady = true;
    }

    // Kick off a full server refresh in the background if we haven't done one.
    // Don't await — return what we have now (downloads at minimum).
    if (_lastRefresh == null && !_isRefreshing) {
      _backgroundRefresh();
    }

    // ── Root ──
    if (parentMediaId == AutoMediaIds.root) {
      return _getRootChildren();
    }

    // ── Top-level tabs ──
    if (parentMediaId == AutoMediaIds.continueListening) {
      return _continueListening.map((e) => e.toMediaItem()).toList();
    }
    if (parentMediaId == AutoMediaIds.recent) {
      return _recentlyAdded.map((e) => e.toMediaItem()).toList();
    }
    if (parentMediaId == AutoMediaIds.downloads) {
      return _downloaded.map((e) => e.toMediaItem()).toList();
    }

    // ── Library tab ──
    if (parentMediaId == AutoMediaIds.library) {
      // If only one book library, skip picker → show sub-categories directly
      if (_libraries.length == 1) {
        return _getLibrarySubCategories(_libraries.first.id);
      }
      return _getLibraryList();
    }

    // ── Library drilldowns ──
    if (parentMediaId.startsWith(AutoMediaIds.libPrefix)) {
      final libId = AutoMediaIds.parseLibId(parentMediaId);
      final sub = AutoMediaIds.parseLibSub(parentMediaId);
      if (libId == null) return [];

      if (sub == null) {
        // "lib:<id>" → sub-categories
        return _getLibrarySubCategories(libId);
      }

      switch (sub) {
        case 'books':
          return _fetchLibraryBooks(libId);
        case 'series':
          return _fetchLibrarySeries(libId);
        case 'authors':
          return _fetchLibraryAuthors(libId);
      }
    }

    // ── Series drilldown ──
    final series = AutoMediaIds.parseSeries(parentMediaId);
    if (series != null) {
      return _fetchSeriesBooks(series.seriesId, series.libId);
    }

    // ── Author drilldown ──
    final author = AutoMediaIds.parseAuthor(parentMediaId);
    if (author != null) {
      return _fetchAuthorBooks(author.authorId, author.libId);
    }

    return [];
  }

  // ─── On-demand fetchers ────────────────────────────────────────────

  Future<List<MediaItem>> _fetchLibraryBooks(String libraryId) async {
    final api = await getApi();
    if (api == null) return [];

    try {
      // Android Auto has a ~1MB Binder transaction limit for onLoadChildren
      // results. With cover URLs, each MediaItem is ~1.2KB, so we cap at 200
      // items to stay safely under the limit. For larger libraries, users can
      // browse via Series or Authors instead.
      const maxItems = 200;
      final allBooks = <MediaItem>[];
      int page = 0;
      const pageSize = 100;

      while (allBooks.length < maxItems) {
        final result = await api.getLibraryItems(
          libraryId, page: page, limit: pageSize,
          sort: 'media.metadata.title', desc: 0,
        );
        if (result == null) break;

        final entries = _resultsToEntries(result, api);
        allBooks.addAll(entries.map((e) => e.toMediaItem()));

        final total = (result['total'] as num?)?.toInt() ?? 0;
        if (allBooks.length >= total || entries.length < pageSize) break;
        page++;
      }

      if (allBooks.length > maxItems) {
        debugPrint('[AndroidAuto] Trimmed books from ${allBooks.length} to $maxItems (Binder limit)');
        return allBooks.sublist(0, maxItems);
      }

      debugPrint('[AndroidAuto] Fetched ${allBooks.length} books');
      return allBooks;
    } catch (e) {
      debugPrint('[AndroidAuto] Error fetching library books: $e');
    }
    return [];
  }

  Future<List<MediaItem>> _fetchLibrarySeries(String libraryId) async {
    final api = await getApi();
    if (api == null) return [];

    try {
      // Fetch all series, paginated, sorted alphabetically
      final allSeries = <MediaItem>[];
      int page = 0;
      const pageSize = 100;

      while (true) {
        final result = await api.getLibrarySeries(
          libraryId, page: page, limit: pageSize, sort: 'name', desc: 0,
        );
        if (result == null) break;

        final seriesList = result['results'] as List<dynamic>? ?? [];
        for (final s in seriesList) {
          final sm = s as Map<String, dynamic>;
          final sId = sm['id'] as String? ?? '';
          final name = sm['name'] as String? ?? 'Unknown';
          if (sId.isEmpty) continue;
          allSeries.add(MediaItem(
            id: AutoMediaIds.seriesId(sId, libraryId),
            title: name,
            playable: false,
          ));
        }

        final total = (result['total'] as num?)?.toInt() ?? 0;
        if (allSeries.length >= total || seriesList.length < pageSize) break;
        page++;
      }

      debugPrint('[AndroidAuto] Fetched ${allSeries.length} series');
      return allSeries;
    } catch (e) {
      debugPrint('[AndroidAuto] Error fetching series: $e');
    }
    return [];
  }

  Future<List<MediaItem>> _fetchLibraryAuthors(String libraryId) async {
    final api = await getApi();
    if (api == null) return [];

    try {
      final filterData = await api.getLibraryFilterData(libraryId);
      if (filterData != null) {
        final authorsList = filterData['authors'] as List<dynamic>? ?? [];
        final items = authorsList.map((a) {
          final am = a as Map<String, dynamic>;
          final aId = am['id'] as String? ?? '';
          final name = am['name'] as String? ?? 'Unknown';
          if (aId.isEmpty) return null;
          return MediaItem(
            id: AutoMediaIds.authorId(aId, libraryId),
            title: name,
            playable: false,
          );
        }).whereType<MediaItem>().toList();

        items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        debugPrint('[AndroidAuto] Fetched ${items.length} authors');
        return items;
      }
    } catch (e) {
      debugPrint('[AndroidAuto] Error fetching authors: $e');
    }
    return [];
  }

  Future<List<MediaItem>> _fetchSeriesBooks(String seriesId, String libraryId) async {
    final api = await getApi();
    if (api == null) return [];

    try {
      final results = await api.getBooksBySeries(libraryId, seriesId);
      return results
          .whereType<Map<String, dynamic>>()
          .map((item) => _libraryItemToEntry(item, api))
          .whereType<AutoBookEntry>()
          .map((e) => e.toMediaItem())
          .toList();
    } catch (e) {
      debugPrint('[AndroidAuto] Error fetching series books: $e');
      return [];
    }
  }

  Future<List<MediaItem>> _fetchAuthorBooks(String authorId, String libraryId) async {
    final api = await getApi();
    if (api == null) return [];

    try {
      final results = await api.getBooksByAuthor(libraryId, authorId);
      return results
          .whereType<Map<String, dynamic>>()
          .map((item) => _libraryItemToEntry(item, api))
          .whereType<AutoBookEntry>()
          .map((e) => e.toMediaItem())
          .toList();
    } catch (e) {
      debugPrint('[AndroidAuto] Error fetching author books: $e');
      return [];
    }
  }

  // ─── Search ────────────────────────────────────────────────────────

  Future<List<MediaItem>> search(String query) async {
    final api = await getApi();
    final libId = await getDefaultLibraryId();
    if (api == null || libId == null) return [];

    try {
      final result = await api.searchLibrary(libId, query, limit: 20);
      if (result == null) return [];

      final items = <MediaItem>[];
      final books = result['book'] as List<dynamic>? ?? [];
      for (final b in books) {
        final bm = b as Map<String, dynamic>;
        final libraryItem = bm['libraryItem'] as Map<String, dynamic>?;
        if (libraryItem != null) {
          final entry = _libraryItemToEntry(libraryItem, api);
          if (entry != null) {
            items.add(entry.toMediaItem());
          }
        }
      }
      return items;
    } catch (e) {
      debugPrint('[AndroidAuto] Search error: $e');
      return [];
    }
  }

  // ─── Lookup helpers ────────────────────────────────────────────────

  AutoBookEntry? findEntry(String absItemId) {
    for (final list in [_continueListening, _downloaded, _recentlyAdded]) {
      for (final entry in list) {
        if (entry.id == absItemId) return entry;
      }
    }
    return null;
  }

  MediaItem? getMediaItem(String mediaId) {
    final absId = AutoMediaIds.absItemId(mediaId);
    if (absId == null) return null;
    return findEntry(absId)?.toMediaItem();
  }
}
