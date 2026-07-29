import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:audio_service/audio_service.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'audio_player_service.dart';
import 'book_search_index.dart';
import 'download_service.dart';
import 'progress_sync_service.dart';
import 'scoped_prefs.dart';
import 'user_account_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;

// ─── Media ID scheme ─────────────────────────────────────────────────
//
// Root tabs:
//   continue          → list of in-progress books / podcast episodes
//   library           → list of all libraries (books + podcasts)
//   downloads         → list of downloaded books / podcast episodes
//
// Book library drilldown:
//   lib:<libraryId>:books        → all books in library
//   lib:<libraryId>:series       → list of series
//   lib:<libraryId>:authors      → list of authors
//   series:<seriesId>@<libId>    → books in that series
//   author:<authorId>@<libId>    → books by that author
//
// Podcast library drilldown:
//   lib:<libraryId>              → list of podcast shows
//   show:<showId>@<libId>        → episodes of a show
//
// Playable items:
//   item:<absItemId>             → a playable book
//   item:<showId>-<episodeId>    → a playable podcast episode
// ─────────────────────────────────────────────────────────────────────

class AutoMediaIds {
  // Root tabs
  static const root = 'root';
  static const continueListening = 'continue';
  static const recentlyAdded = 'recently-added';
  static const library = 'library';
  static const downloads = 'downloads';

  // Prefixes
  static const itemPrefix = 'item:';
  static const libPrefix = 'lib:';
  static const seriesPrefix = 'series:';
  static const authorPrefix = 'author:';
  static const showPrefix = 'show:';

  // Build IDs
  static String itemId(String absId) => '$itemPrefix$absId';
  static String libId(String libraryId) => '$libPrefix$libraryId';
  static String libBooks(String libraryId) => '$libPrefix$libraryId:books';
  static String libSeries(String libraryId) => '$libPrefix$libraryId:series';
  static String libAuthors(String libraryId) => '$libPrefix$libraryId:authors';
  static String libBookPrefix(String libraryId, String prefix) => '$libPrefix$libraryId:p:$prefix';
  static String seriesId(String sId, String libId) => '$seriesPrefix$sId@$libId';
  static String authorId(String aId, String libId) => '$authorPrefix$aId@$libId';
  static String showId(String sId, String libId) => '$showPrefix$sId@$libId';

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

  /// Parse "show:<showId>@<libId>" → {showId, libId}
  static ({String showId, String libId})? parseShow(String mediaId) {
    if (!mediaId.startsWith(showPrefix)) return null;
    final rest = mediaId.substring(showPrefix.length);
    final at = rest.indexOf('@');
    if (at < 0) return null;
    return (showId: rest.substring(0, at), libId: rest.substring(at + 1));
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

  /// Non-null for podcast episodes — the episode ID within the show.
  final String? episodeId;
  /// Non-null for podcast episodes — the show (podcast) ID.
  final String? showId;
  /// 'book' or 'podcast'. Used to route recently-added podcast shows into
  /// browseable show drilldown instead of unplayable item ids.
  final String mediaType;
  /// Library ID. Required to build a `show:` browse id for podcast shows.
  final String? libraryId;

  const AutoBookEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    this.coverUrl,
    this.chapters = const [],
    this.currentTime,
    this.episodeId,
    this.showId,
    this.mediaType = 'book',
    this.libraryId,
  });

  /// True when this entry represents a podcast show (not a single episode)
  /// that can only be browsed, not played directly.
  bool get _isPodcastShow =>
      mediaType == 'podcast' &&
      episodeId == null &&
      libraryId != null &&
      libraryId!.isNotEmpty;

  MediaItem toMediaItem() {
    final uri = coverUrl != null ? Uri.tryParse(coverUrl!) : null;

    // Recently-added podcast show — browseable, drills into episodes.
    if (_isPodcastShow) {
      return MediaItem(
        id: AutoMediaIds.showId(id, libraryId!),
        title: title,
        artUri: uri,
        playable: false,
        extras: uri != null ? {'artUri': uri.toString()} : null,
      );
    }

    // For podcast episodes, use compound key as the playable media ID
    final mediaId = (episodeId != null && showId != null)
        ? AutoMediaIds.itemId('$showId-$episodeId')
        : AutoMediaIds.itemId(id);
    return MediaItem(
      id: mediaId,
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
  bool get isPodcast => mediaType == 'podcast';
}

// ─── Android Auto Service ────────────────────────────────────────────

class AndroidAutoService {
  static final AndroidAutoService _instance = AndroidAutoService._();
  factory AndroidAutoService() => _instance;
  AndroidAutoService._() {
    DownloadService().addListener(_onDownloadsChanged);
  }

  Timer? _downloadsRefreshDebounce;
  void _onDownloadsChanged() {
    // Coalesce bursts (multiple state ticks during a download).
    _downloadsRefreshDebounce?.cancel();
    _downloadsRefreshDebounce = Timer(const Duration(milliseconds: 500), () async {
      await _refreshDownloaded();
      _childrenCache.remove(AutoMediaIds.downloads);
      _childrenCache.remove(AutoMediaIds.root);
      if (Platform.isAndroid) {
        try {
          // ignore: deprecated_member_use
          await AudioServiceBackground.notifyChildrenChanged(AutoMediaIds.downloads);
        } catch (_) {}
      }
      try {
        onServerDataChanged?.call();
      } catch (_) {}
    });
  }

  // ── Cached data ──
  List<AutoBookEntry> _continueListening = [];
  List<AutoBookEntry> _recentlyAdded = [];
  List<AutoBookEntry> _downloaded = [];
  List<AutoLibraryEntry> _libraries = [];

  /// Public read-only access to cached data (used by CarPlayService)
  List<AutoBookEntry> get continueListening => _continueListening;
  List<AutoBookEntry> get recentlyAdded => _recentlyAdded;
  List<AutoBookEntry> get downloaded => _downloaded;
  List<AutoLibraryEntry> get libraries => _libraries;

  DateTime? _lastRefresh;
  bool _isRefreshing = false;

  // Per-parent MediaItem list cache. Returning the same instances on
  // re-requests is what lets AA preserve scroll position when the user goes
  // into an item and presses back. Also dedupes the back-to-back getChildren
  // calls AA fires when it re-renders.
  final Map<String, List<MediaItem>> _childrenCache = {};
  final Map<String, Future<List<MediaItem>>> _childrenInFlight = {};

  /// Clear all cached browse-tree data and force a fresh server fetch
  /// on the next access.  Call when the user switches accounts or logs out.
  void clearCache() {
    _continueListening = [];
    _recentlyAdded = [];
    _downloaded = [];
    _libraries = [];
    _lastRefresh = null;
    _downloadsReady = false;
    _isRefreshing = false;
    _childrenCache.clear();
    _childrenInFlight.clear();
    debugPrint('[AutoBrowse] Cache cleared (user switch/logout)');
  }

  // Top-level parents whose contents change with server refresh. Drilldown
  // children (series/author books, podcast episodes) stay cached until the
  // user explicitly switches accounts so scroll position survives.
  static const _refreshSensitiveParents = {
    AutoMediaIds.root,
    AutoMediaIds.continueListening,
    AutoMediaIds.recentlyAdded,
    AutoMediaIds.library,
    AutoMediaIds.downloads,
  };

  void _invalidateRefreshSensitiveChildren() {
    _childrenCache.removeWhere((k, _) =>
        _refreshSensitiveParents.contains(k) ||
        k.startsWith(AutoMediaIds.libPrefix));
  }

  // ── API helpers ──

  Future<ApiService?> getApi() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('server_url');
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refresh_token');
    final username = prefs.getString('username');
    if (url == null || token == null) return null;
    Map<String, String> customHeaders = const {};
    final headersJson = prefs.getString('custom_headers');
    if (headersJson != null && headersJson.isNotEmpty) {
      try {
        customHeaders = Map<String, String>.from(jsonDecode(headersJson) as Map);
      } catch (_) {}
    }
    return ApiService(
      baseUrl: url,
      token: token,
      refreshToken: refreshToken,
      isLegacyToken: refreshToken == null,
      customHeaders: customHeaders,
      loadPersistedTokens: () =>
          UserAccountService().loadPersistedTokens(url, username),
      onTokensRefreshed: (access, refresh) =>
          UserAccountService().persistRefreshedTokens(
            access,
            refresh,
            serverUrl: url,
            username: username,
          ),
    );
  }

  Future<String?> getDefaultLibraryId() async {
    // Prefer the user's selected library (set in-app) over the server default
    final selected = await ScopedPrefs.getString('last_selected_library');
    if (selected != null) return selected;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('default_library_id');
  }

  // ── Refresh ──

  /// Whether downloads have been populated at least once (synchronous, no server needed).
  bool _downloadsReady = false;

  /// Fire-and-forget server refresh. Downloads are already available;
  /// this populates Continue and Library tabs in the background.
  void _backgroundRefresh() {
    refresh().then((_) {
      debugPrint('[AutoBrowse] Background refresh completed');
    }).catchError((e) {
      debugPrint('[AutoBrowse] Background refresh failed: $e');
    });
  }

  /// Called once the background server-side refresh completes (success or
  /// failure) so listeners can re-render their browse trees with the new
  /// data. CarPlayService sets this in init() to call refreshTemplates();
  /// AndroidAuto uses notifyChildrenChanged below independently.
  static void Function()? onServerDataChanged;

  Future<void> refresh({bool force = false}) async {
    // Always populate downloads immediately — no server needed.
    // This ensures Android Auto / CarPlay can show the Downloads tab even
    // if the server is unreachable (e.g. no remote access, offline-only
    // users).
    if (!_downloadsReady || force) {
      await _refreshDownloaded();
      _downloadsReady = true;
    }

    // Provisional Continue shelf from in-progress downloads, so it's useful
    // the moment the head unit queries it. The server fetch below can sit on
    // a 15s timeout when the server is unreachable, and by then the user is
    // already staring at an empty Continue tab. Server data replaces this
    // when (and if) it arrives.
    if (_continueListening.isEmpty) {
      await _buildOfflineContinueFromDownloads();
    }

    if (_isRefreshing) return;
    if (!force && _lastRefresh != null &&
        DateTime.now().difference(_lastRefresh!) < const Duration(seconds: 30)) {
      return;
    }

    _isRefreshing = true;
    debugPrint('[AutoBrowse] Refreshing browse tree...');
    // Kick the server fetch off in the background so callers (CarPlay scene
    // init, Android Auto media browser) don't block on a 15s `getLibraries`
    // timeout when the server is unreachable. The downloads pass above is
    // already populated; that's enough to render a useful browse tree
    // immediately. When the server data arrives (or fails) we fire the
    // listener hook so the UI re-renders with the fresh sections.
    unawaited(_refreshServerInBackground());
  }

  Future<void> _refreshServerInBackground() async {
    try {
      await _refreshDownloaded(); // re-fetch in case downloads changed
      await _refreshFromServer();
      _lastRefresh = DateTime.now();
      debugPrint('[AutoBrowse] Refresh done: '
          '${_continueListening.length} continue, '
          '${_recentlyAdded.length} recent, '
          '${_downloaded.length} downloaded, '
          '${_libraries.length} libraries '
          '(${_libraries.where((l) => l.isBook).length} book, '
          '${_libraries.where((l) => l.isPodcast).length} podcast)');
    } catch (e) {
      // Server unreachable — downloads are still available.
      _lastRefresh = DateTime.now();
      debugPrint('[AutoBrowse] Server refresh failed (downloads still available): $e');
    } finally {
      _isRefreshing = false;
      _invalidateRefreshSensitiveChildren();
      if (Platform.isAndroid) {
        // Notify every refresh-sensitive tab, not just root: the head unit
        // only re-queries nodes it's told about, so a root-only notify left
        // the Continue tab showing its pre-refresh (often empty) contents.
        for (final id in _refreshSensitiveParents) {
          try {
            // ignore: deprecated_member_use
            await AudioServiceBackground.notifyChildrenChanged(id);
          } catch (_) {}
        }
      }
      try {
        onServerDataChanged?.call();
      } catch (e) {
        debugPrint('[AutoBrowse] onServerDataChanged listener threw: $e');
      }
    }
  }

  /// Content provider authority for serving local cover images to Android Auto.
  /// Must match the authority registered in AndroidManifest.xml.
  static const _coverAuthority = 'com.barnabas.absorb.covers';

  // Per-item updatedAt for cover ?ts= cache busting on AA/CarPlay.
  static final Map<String, int> _itemUpdatedAt = {};

  static int? coverTsFor(String itemId) => _itemUpdatedAt[itemId];

  /// Build a content:// URI for a locally cached cover image.
  /// Android Auto requires content:// URIs, file:// won't work.
  static String localCoverUri(String itemId) {
    final ts = _itemUpdatedAt[itemId];
    final base = 'content://$_coverAuthority/cover/$itemId';
    return ts != null ? '$base?ts=$ts' : base;
  }

  static void notifyItemUpdated(String itemId, int updatedAt) {
    final prev = _itemUpdatedAt[itemId];
    if (prev == updatedAt) return;
    _itemUpdatedAt[itemId] = updatedAt;
    // Children cache holds old cover URIs.
    _instance._childrenCache.clear();
    try {
      onServerDataChanged?.call();
    } catch (e) {
      debugPrint('[AutoBrowse] notifyItemUpdated listener threw: $e');
    }
    if (Platform.isAndroid) {
      try {
        // ignore: deprecated_member_use
        AudioServiceBackground.notifyChildrenChanged(AutoMediaIds.root);
      } catch (_) {}
    }
  }

  Future<void> _refreshDownloaded() async {
    final ds = DownloadService();
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

      // Detect podcast episode downloads via compound key (showId-episodeId).
      final isEpisode = dl.itemId.length > 36;
      String? showId;
      String? episodeId;
      if (isEpisode) {
        showId = dl.itemId.substring(0, 36);
        episodeId = dl.itemId.substring(37);
      }

      // Podcast episode covers use the show ID so the provider can fall back
      // to /api/items/<showId>/cover.
      final coverKey = isEpisode ? showId! : dl.itemId;
      if (dl.localCoverPath != null && dl.localCoverPath!.isNotEmpty) {
        try {
          final f = File(dl.localCoverPath!);
          if (f.existsSync()) {
            final ms = f.lastModifiedSync().millisecondsSinceEpoch;
            final prev = _itemUpdatedAt[coverKey];
            if (prev == null || ms > prev) _itemUpdatedAt[coverKey] = ms;
          }
        } catch (_) {}
      }
      String coverUrl;
      if (Platform.isIOS && dl.localCoverPath != null && dl.localCoverPath!.isNotEmpty) {
        coverUrl = Uri.file(dl.localCoverPath!).toString();
        final ts = _itemUpdatedAt[coverKey];
        if (ts != null) coverUrl = '$coverUrl?ts=$ts';
      } else {
        coverUrl = localCoverUri(coverKey);
      }

      entries.add(AutoBookEntry(
        id: dl.itemId,
        title: dl.title ?? 'Unknown',
        author: dl.author ?? '',
        duration: duration,
        coverUrl: coverUrl,
        chapters: chapters,
        currentTime: localPos > 0 ? localPos : null,
        episodeId: episodeId,
        showId: showId,
        libraryId: dl.libraryId,
      ));
      debugPrint('[AutoBrowse] Download entry: ${dl.title} cover=$coverUrl');
    }

    _downloaded = entries;
  }

  /// Build the Continue shelf from in-progress downloaded books when the server
  /// is unreachable, so the user can resume in Android Auto / CarPlay without
  /// digging through the Downloads tab (Discord request). Ordered to match the
  /// in-app Continue: items the user is actively absorbing first (persisted
  /// `absorbing_seen_ids`), then most recently played. Relies on `_downloaded`
  /// already being populated (it always is by the time this runs).
  Future<void> _buildOfflineContinueFromDownloads() async {
    if (_downloaded.isEmpty) {
      _continueListening = [];
      return;
    }
    final psync = ProgressSyncService();
    final absorbingOrder = await ScopedPrefs.getStringList('absorbing_seen_ids');
    final absorbingIndex = <String, int>{};
    for (var i = 0; i < absorbingOrder.length; i++) {
      absorbingIndex.putIfAbsent(absorbingOrder[i], () => i);
    }

    // (absorbing order, last-played ms, entry); a download's id is already the
    // same key the absorbing list uses (bookId, or showId-episodeId).
    final ranked = <(int, int, AutoBookEntry)>[];
    for (final entry in _downloaded) {
      final local = await psync.getLocal(entry.id);
      if (local == null) continue;
      final pos = (local['currentTime'] as num?)?.toDouble() ?? 0;
      final finished = local['isFinished'] as bool? ?? false;
      if (finished || pos <= 0) continue; // only books in progress
      final ts = (local['timestamp'] as num?)?.toInt() ?? 0;
      final order = absorbingIndex[entry.id] ?? (1 << 30);
      ranked.add((order, ts, entry));
    }
    ranked.sort((a, b) {
      if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
      return b.$2.compareTo(a.$2);
    });
    _continueListening = ranked.map((e) => e.$3).toList();
    debugPrint(
        '[AutoBrowse] Offline Continue from downloads: ${_continueListening.length} in-progress');
  }

  Future<void> _refreshFromServer() async {
    final api = await getApi();
    if (api == null) return;

    final prefs = await SharedPreferences.getInstance();
    final manualOffline = prefs.getBool('manual_offline_mode') ?? false;
    // Skip the server fetch if we know we're offline. Without this,
    // CarPlay / AndroidAuto sit on a 15s getLibraries timeout every time
    // the user opens the app or connects to the head unit while their
    // server is unreachable.
    if (manualOffline || AudioPlayerService().knownOffline) {
      await _buildOfflineContinueFromDownloads();
      _recentlyAdded = [];
      _libraries = [];
      return;
    }

    try {
      // ── Fetch all libraries (books + podcasts) ──
      final libs = await api.getLibraries();
      if (libs.isEmpty) {
        // ApiService swallows network errors and returns an empty list, so
        // an unreachable server never reaches the catch below. A real ABS
        // account always has at least one library - treat empty as offline
        // and keep the downloads-based Continue shelf instead of wiping it.
        await _buildOfflineContinueFromDownloads();
        _recentlyAdded = [];
        _libraries = [];
        debugPrint('[AutoBrowse] getLibraries empty - treating as offline');
        return;
      }
      _libraries = libs.map((l) {
        final m = l as Map<String, dynamic>;
        return AutoLibraryEntry(
          id: m['id'] as String? ?? '',
          name: m['name'] as String? ?? 'Library',
          mediaType: m['mediaType'] as String? ?? 'book',
        );
      }).where((l) => l.id.isNotEmpty && (l.isBook || l.isPodcast)).toList();

      // ── Personalized shelves merged from all libraries ──
      // Book libraries: continue-listening / continue-series for the Continue
      // tab, recently-added for the New tab.
      // Podcast libraries: continue-listening for the Continue tab. New
      // episodes come from a separate /recent-episodes call below since the
      // personalized endpoint's `episodes-recently-added` shelf gets stripped
      // when a `shelves` filter is passed.
      final clFutures = _libraries.map((lib) => api
          .getPersonalizedView(
            lib.id,
            include: const ['numEpisodesIncomplete'],
            shelves: lib.isPodcast
                ? const ['continue-listening']
                : const ['continue-listening', 'continue-series', 'recently-added'],
            limit: 10,
          )
          .then((sections) => sections ?? const <dynamic>[]));

      // Newly added podcast episodes per podcast library (empty for book libs).
      final episodeFutures = _libraries
          .map((lib) => lib.isPodcast
              ? api.getRecentEpisodes(lib.id, limit: 10)
              : Future.value(const <dynamic>[]))
          .toList();

      final allSections = await Future.wait(clFutures);
      final allRecentEpisodes = await Future.wait(episodeFutures);

      // Continue Listening: collect, dedupe, sort by lastUpdate desc
      final continueSeenIds = <String>{};
      final continueEntities = <Map<String, dynamic>>[];
      // Recently Added: ranked entries with their addedAt for cross-library sort.
      final recentSeenKeys = <String>{};
      final recentRanked = <(double, AutoBookEntry)>[];

      for (var i = 0; i < _libraries.length; i++) {
        final lib = _libraries[i];
        final sections = allSections[i];
        for (final section in sections) {
          final sectionId = section['id'] as String? ?? '';
          final entities = section['entities'] as List<dynamic>? ?? [];
          if (sectionId == 'continue-listening' || sectionId == 'continue-series') {
            for (final entity in entities) {
              if (entity is Map<String, dynamic>) {
                final id = entity['id'] as String? ?? '';
                final ep = entity['recentEpisode'] as Map<String, dynamic>?;
                final key = ep != null ? '$id-${ep['id'] ?? ''}' : id;
                if (key.isNotEmpty && continueSeenIds.add(key)) {
                  continueEntities.add(entity);
                }
              }
            }
          } else if (sectionId == 'recently-added' && lib.isBook) {
            for (final entity in entities) {
              if (entity is! Map<String, dynamic>) continue;
              final id = entity['id'] as String? ?? '';
              if (id.isEmpty || !recentSeenKeys.add(id)) continue;
              final entry = _entityToEntry(entity, api);
              if (entry == null) continue;
              final addedAt = (entity['addedAt'] as num?)?.toDouble() ?? 0;
              recentRanked.add((addedAt, entry));
            }
          }
        }

        // Newly added podcast episodes for this library.
        if (lib.isPodcast) {
          final episodes = allRecentEpisodes[i];
          for (final ep in episodes) {
            if (ep is! Map<String, dynamic>) continue;
            final entry = _recentEpisodeToEntry(ep, lib.id);
            if (entry == null) continue;
            if (!recentSeenKeys.add(entry.id)) continue;
            final addedAt = (ep['addedAt'] as num?)?.toDouble()
                ?? (ep['publishedAt'] as num?)?.toDouble()
                ?? 0;
            recentRanked.add((addedAt, entry));
          }
        }
      }

      // Order Continue to match the in-app Absorbing page: the user's actively
      // absorbing items come first, in that page's order (most recent first).
      // The server's mediaProgress.lastUpdate gets bumped on download/sync, so
      // sorting by it alone looks like "download order" (GH #287); the persisted
      // absorbing list is the real listening order. Items not in that list
      // (e.g. continue-series next books) fall after, by lastUpdate.
      final absorbingOrder =
          await ScopedPrefs.getStringList('absorbing_seen_ids');
      final absorbingIndex = <String, int>{};
      for (var i = 0; i < absorbingOrder.length; i++) {
        absorbingIndex.putIfAbsent(absorbingOrder[i], () => i);
      }
      String continueKey(Map<String, dynamic> e) {
        final id = e['id'] as String? ?? '';
        final ep = e['recentEpisode'] as Map<String, dynamic>?;
        return ep != null ? '$id-${ep['id'] ?? ''}' : id;
      }
      continueEntities.sort((a, b) {
        final ai = absorbingIndex[continueKey(a)] ?? (1 << 30);
        final bi = absorbingIndex[continueKey(b)] ?? (1 << 30);
        if (ai != bi) return ai.compareTo(bi);
        final aTime = ((a['mediaProgress'] as Map<String, dynamic>?)?['lastUpdate'] as num?)?.toDouble() ?? 0;
        final bTime = ((b['mediaProgress'] as Map<String, dynamic>?)?['lastUpdate'] as num?)?.toDouble() ?? 0;
        return bTime.compareTo(aTime);
      });
      _continueListening = continueEntities
          .map((e) => _entityToEntry(e, api))
          .whereType<AutoBookEntry>()
          .toList();

      recentRanked.sort((a, b) => b.$1.compareTo(a.$1));
      _recentlyAdded = recentRanked.map((e) => e.$2).toList();
    } catch (e) {
      // Server unreachable - fall back to in-progress downloads for Continue so
      // the user can still resume offline, and clear the rest.
      await _buildOfflineContinueFromDownloads();
      _recentlyAdded = [];
      _libraries = [];
      debugPrint('[AutoBrowse] Server fetch error: $e');
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
    final showTitle = metadata['title'] as String? ?? 'Unknown';
    final author = metadata['authorName'] as String? ?? '';
    final mediaType = entity['mediaType'] as String? ?? 'book';
    final libraryId = entity['libraryId'] as String?;

    final progress = entity['mediaProgress'] as Map<String, dynamic>?;
    final currentTime = (progress?['currentTime'] as num?)?.toDouble();

    // Podcast entities from continue-listening have a recentEpisode field
    final recentEp = entity['recentEpisode'] as Map<String, dynamic>?;
    if (recentEp != null) {
      final episodeId = recentEp['id'] as String?;
      if (episodeId == null) return null;
      final episodeTitle = recentEp['title'] as String? ?? 'Episode';
      final epDuration = (recentEp['duration'] as num?)?.toDouble() ?? 0;
      final chapters = recentEp['chapters'] as List<dynamic>? ?? [];

      return AutoBookEntry(
        id: '$id-$episodeId', // compound key
        title: episodeTitle,
        author: showTitle,    // show name as artist
        duration: epDuration,
        coverUrl: localCoverUri(id), // show ID for cover
        chapters: chapters,
        currentTime: currentTime,
        episodeId: episodeId,
        showId: id,
        mediaType: mediaType,
        libraryId: libraryId,
      );
    }

    // Regular book entity, or recently-added podcast show.
    final duration = (media?['duration'] as num?)?.toDouble() ?? 0;
    final chapters = media?['chapters'] as List<dynamic>? ?? [];

    return AutoBookEntry(
      id: id,
      title: showTitle,
      author: author,
      duration: duration,
      coverUrl: localCoverUri(id),
      chapters: chapters,
      currentTime: currentTime,
      mediaType: mediaType,
      libraryId: libraryId,
    );
  }

  /// Convert an episode object from /api/libraries/:id/recent-episodes into
  /// an AutoBookEntry. Each episode includes the parent show's metadata under
  /// either `podcast.media.metadata` (full library item shape) or
  /// `podcast.metadata` (compact shape).
  AutoBookEntry? _recentEpisodeToEntry(Map<String, dynamic> ep, String libraryId) {
    final episodeId = ep['id'] as String?;
    if (episodeId == null || episodeId.isEmpty) return null;

    final showId = (ep['libraryItemId'] as String?)
        ?? (ep['podcastId'] as String?)
        ?? ((ep['podcast'] as Map<String, dynamic>?)?['id'] as String?);
    if (showId == null || showId.isEmpty) return null;

    final episodeTitle = ep['title'] as String? ?? 'Episode';

    String? showTitle;
    final podcast = ep['podcast'] as Map<String, dynamic>?;
    if (podcast != null) {
      final mediaMeta =
          (podcast['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?;
      showTitle = mediaMeta?['title'] as String?
          ?? (podcast['metadata'] as Map<String, dynamic>?)?['title'] as String?;
    }
    showTitle ??= ep['podcastTitle'] as String? ?? '';

    final duration = (ep['duration'] as num?)?.toDouble()
        ?? ((ep['audioFile'] as Map<String, dynamic>?)?['duration'] as num?)?.toDouble()
        ?? 0;
    final chapters = ep['chapters'] as List<dynamic>? ?? const [];

    return AutoBookEntry(
      id: '$showId-$episodeId',
      title: episodeTitle,
      author: showTitle,
      duration: duration,
      coverUrl: localCoverUri(showId),
      chapters: chapters,
      episodeId: episodeId,
      showId: showId,
      mediaType: 'podcast',
      libraryId: libraryId,
    );
  }

  AutoBookEntry? _libraryItemToEntry(
      Map<String, dynamic> item, ApiService api) {
    final id = item['id'] as String?;
    if (id == null) return null;

    final updatedAt = (item['updatedAt'] as num?)?.toInt();
    if (updatedAt != null) _itemUpdatedAt[id] = updatedAt;

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
      coverUrl: localCoverUri(id),
      chapters: chapters,
      libraryId: item['libraryId'] as String?,
    );
  }

  // ─── Browse tree ───────────────────────────────────────────────────

  AppLocalizations? _l() {
    final ctx = rootNavigatorKey.currentContext;
    return ctx != null ? AppLocalizations.of(ctx) : null;
  }

  List<MediaItem> _getRootChildren() {
    // Always show all three tabs so the layout is consistent and doesn't
    // look like a missing 4th button.  Each tab fetches on-demand if its
    // cache is empty (cold start / background refresh pending).
    final l = _l();
    return [
      MediaItem(
        id: AutoMediaIds.continueListening,
        title: l?.androidAutoTabContinue ?? 'Continue',
        playable: false,
      ),
      MediaItem(
        id: AutoMediaIds.recentlyAdded,
        title: 'New',
        playable: false,
      ),
      MediaItem(
        id: AutoMediaIds.library,
        title: l?.androidAutoTabLibrary ?? 'Library',
        playable: false,
      ),
      MediaItem(
        id: AutoMediaIds.downloads,
        title: l?.androidAutoTabDownloads ?? 'Downloads',
        playable: false,
      ),
    ];
  }

  /// Sub-categories for a book library: Books, Series, Authors
  List<MediaItem> _getBookSubCategories(String libraryId) {
    final l = _l();
    return [
      MediaItem(
        id: AutoMediaIds.libBooks(libraryId),
        title: l?.androidAutoCatBooks ?? 'Books',
        playable: false,
      ),
      MediaItem(
        id: AutoMediaIds.libSeries(libraryId),
        title: l?.androidAutoCatSeries ?? 'Series',
        playable: false,
      ),
      MediaItem(
        id: AutoMediaIds.libAuthors(libraryId),
        title: l?.androidAutoCatAuthors ?? 'Authors',
        playable: false,
      ),
    ];
  }

  /// Main entry point for browse tree. May make API calls for drilldowns.
  Future<List<MediaItem>> getChildrenOf(String parentMediaId) {
    final cached = _childrenCache[parentMediaId];
    if (cached != null) return Future.value(cached);

    final inFlight = _childrenInFlight[parentMediaId];
    if (inFlight != null) return inFlight;

    final future = () async {
      try {
        final children = await _computeChildren(parentMediaId);
        _childrenCache[parentMediaId] = children;
        return children;
      } finally {
        _childrenInFlight.remove(parentMediaId);
      }
    }();
    _childrenInFlight[parentMediaId] = future;
    return future;
  }

  Future<List<MediaItem>> _computeChildren(String parentMediaId) async {
    // Ensure downloads are always populated before returning root.
    // This is instant (no network) so Android Auto never waits on a server.
    if (!_downloadsReady) {
      await _refreshDownloaded();
      _downloadsReady = true;
    }

    // Kick off a full server refresh in the background if we haven't done one.
    // Don't await, return what we have now (downloads at minimum).
    if (_lastRefresh == null && !_isRefreshing) {
      _backgroundRefresh();
    }

    // ── Root ──
    if (parentMediaId == AutoMediaIds.root) {
      return _getRootChildren();
    }

    // ── Top-level tabs ──
    if (parentMediaId == AutoMediaIds.continueListening) {
      // If empty (cold start / background refresh pending), fetch now
      if (_continueListening.isEmpty) {
        try {
          await _refreshFromServer();
        } catch (e) {
          debugPrint('[AutoBrowse] On-demand continue fetch failed: $e');
        }
      }
      return _continueListening.map((e) => e.toMediaItem()).toList();
    }
    if (parentMediaId == AutoMediaIds.recentlyAdded) {
      if (_recentlyAdded.isEmpty) {
        try {
          await _refreshFromServer();
        } catch (e) {
          debugPrint('[AutoBrowse] On-demand recent fetch failed: $e');
        }
      }
      return _recentlyAdded.map((e) => e.toMediaItem()).toList();
    }
    if (parentMediaId == AutoMediaIds.downloads) {
      return _downloaded.map((e) => e.toMediaItem()).toList();
    }

    // ── Library list ──
    if (parentMediaId == AutoMediaIds.library) {
      // If no libraries cached yet (cold start, background refresh pending
      // or failed), fetch synchronously so the user sees real content
      // instead of an empty list.
      if (_libraries.isEmpty) {
        try {
          await _refreshFromServer();
        } catch (e) {
          debugPrint('[AutoBrowse] On-demand library fetch failed: $e');
        }
      }
      // If only one library, skip picker → go straight to its contents
      if (_libraries.length == 1) {
        final lib = _libraries.first;
        if (lib.isPodcast) return _fetchPodcastShows(lib.id);
        return _getBookSubCategories(lib.id);
      }
      return _libraries.map((lib) {
        return MediaItem(
          id: AutoMediaIds.libId(lib.id),
          title: lib.name,
          playable: false,
        );
      }).toList();
    }

    // ── Library drilldowns ──
    if (parentMediaId.startsWith(AutoMediaIds.libPrefix)) {
      final libId = AutoMediaIds.parseLibId(parentMediaId);
      final sub = AutoMediaIds.parseLibSub(parentMediaId);
      if (libId == null) return [];

      if (sub == null) {
        // "lib:<id>" — check if book or podcast library
        final lib = _libraries.cast<AutoLibraryEntry?>().firstWhere(
          (l) => l!.id == libId,
          orElse: () => null,
        );
        if (lib != null && lib.isPodcast) {
          // Podcast library → list shows directly
          return _fetchPodcastShows(libId);
        }
        // Book library → sub-categories
        return _getBookSubCategories(libId);
      }

      if (sub.startsWith('p:')) {
        return _fetchBooksAtPrefix(libId, sub.substring(2));
      }
      switch (sub) {
        case 'books':
          return _fetchBooksAtPrefix(libId, '');
        case 'series':
          return _fetchLibrarySeries(libId);
        case 'authors':
          return _fetchLibraryAuthors(libId);
      }
    }

    // ── Show drilldown (podcast episodes) ──
    final show = AutoMediaIds.parseShow(parentMediaId);
    if (show != null) {
      return _fetchShowEpisodes(show.showId, show.libId);
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

      debugPrint('[AutoBrowse] Fetched ${allSeries.length} series');
      return allSeries;
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching series: $e');
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
        debugPrint('[AutoBrowse] Fetched ${items.length} authors');
        return items;
      }
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching authors: $e');
    }
    return [];
  }

  Future<List<MediaItem>> _fetchSeriesBooks(String seriesId, String libraryId) async {
    final api = await getApi();
    if (api == null) return [];

    try {
      final results = await api.getBooksBySeries(libraryId, seriesId);
      return _sortBySeriesSequence(results, seriesId)
          .map((item) => _libraryItemToEntry(item, api))
          .whereType<AutoBookEntry>()
          .map((e) => e.toMediaItem())
          .toList();
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching series books: $e');
      return [];
    }
  }

  /// Sort raw library items by their sequence within the given series.
  /// The server's `sort=media.metadata.series.sequence` param sorts as a
  /// string, so "10" lands before "2". Books missing a sequence go last.
  static final _leadingNumberRe = RegExp(r'^[\d.]+');
  List<Map<String, dynamic>> _sortBySeriesSequence(
      List<dynamic> results, String seriesId) {
    final maps = results.whereType<Map<String, dynamic>>().toList();
    double seqFor(Map<String, dynamic> item) {
      final media = item['media'] as Map<String, dynamic>? ?? const {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
      final raw = metadata['series'];
      final seriesList = raw is List
          ? raw.whereType<Map<String, dynamic>>()
          : raw is Map<String, dynamic>
              ? [raw]
              : const <Map<String, dynamic>>[];
      for (final s in seriesList) {
        if (s['id'] != seriesId) continue;
        final match = _leadingNumberRe
            .firstMatch((s['sequence'] ?? '').toString().trim());
        if (match != null) {
          final parsed = double.tryParse(match.group(0)!);
          if (parsed != null) return parsed;
        }
      }
      return double.maxFinite;
    }

    maps.sort((a, b) => seqFor(a).compareTo(seqFor(b)));
    return maps;
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
      debugPrint('[AutoBrowse] Error fetching author books: $e');
      return [];
    }
  }

  /// Fetch all podcast shows in a library. Shows are browsable, not playable.
  Future<List<MediaItem>> _fetchPodcastShows(String libraryId) async {
    final api = await getApi();
    if (api == null) return [];

    try {
      const maxItems = 200;
      final allShows = <MediaItem>[];
      int page = 0;
      const pageSize = 100;

      while (allShows.length < maxItems) {
        final result = await api.getLibraryItems(
          libraryId, page: page, limit: pageSize,
          sort: 'media.metadata.title', desc: 0,
        );
        if (result == null) break;

        final results = result['results'] as List<dynamic>? ?? [];
        for (final item in results) {
          if (item is! Map<String, dynamic>) continue;
          final id = item['id'] as String?;
          if (id == null) continue;
          final media = item['media'] as Map<String, dynamic>?;
          final metadata = media?['metadata'] as Map<String, dynamic>? ?? {};
          final title = metadata['title'] as String? ?? 'Unknown';
          final coverUri = Uri.tryParse(localCoverUri(id));

          allShows.add(MediaItem(
            id: AutoMediaIds.showId(id, libraryId),
            title: title,
            artUri: coverUri,
            playable: false,
            extras: coverUri != null ? {'artUri': coverUri.toString()} : null,
          ));
        }

        final total = (result['total'] as num?)?.toInt() ?? 0;
        if (allShows.length >= total || results.length < pageSize) break;
        page++;
      }

      if (allShows.length > maxItems) {
        return allShows.sublist(0, maxItems);
      }

      debugPrint('[AutoBrowse] Fetched ${allShows.length} podcast shows');
      return allShows;
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching podcast shows: $e');
    }
    return [];
  }

  /// Fetch episodes for a podcast show. Sorted newest-first.
  Future<List<MediaItem>> _fetchShowEpisodes(String showId, String libraryId) async {
    final api = await getApi();
    if (api == null) return [];

    try {
      final fullItem = await api.getLibraryItem(showId);
      if (fullItem == null) return [];

      final media = fullItem['media'] as Map<String, dynamic>?;
      final metadata = media?['metadata'] as Map<String, dynamic>? ?? {};
      final showTitle = metadata['title'] as String? ?? 'Podcast';
      final episodes = media?['episodes'] as List<dynamic>? ?? [];

      // Sort newest first
      final sorted = List<dynamic>.from(episodes);
      sorted.sort((a, b) {
        final aTime = (a['publishedAt'] as num?)?.toInt() ?? 0;
        final bTime = (b['publishedAt'] as num?)?.toInt() ?? 0;
        return bTime.compareTo(aTime);
      });

      final coverUri = Uri.tryParse(localCoverUri(showId));
      final items = <MediaItem>[];

      for (final ep in sorted) {
        if (ep is! Map<String, dynamic>) continue;
        final epId = ep['id'] as String?;
        if (epId == null) continue;
        final epTitle = ep['title'] as String? ?? 'Episode';
        final epDuration = (ep['duration'] as num?)?.toDouble() ?? 0;

        items.add(MediaItem(
          id: AutoMediaIds.itemId('$showId-$epId'),
          title: epTitle,
          artist: showTitle,
          album: showTitle,
          duration: Duration(seconds: epDuration.round()),
          artUri: coverUri,
          playable: true,
          extras: coverUri != null ? {'artUri': coverUri.toString()} : null,
        ));
      }

      debugPrint('[AutoBrowse] Fetched ${items.length} episodes for "$showTitle"');
      return items;
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching show episodes: $e');
    }
    return [];
  }

  // ─── Public data fetchers (used by CarPlayService) ─────────────────

  /// Build an HTTP cover URL for use on iOS (CarPlay).
  /// Android uses content:// URIs via CoverContentProvider; iOS loads HTTP directly.
  Future<String?> getCoverHttpUrl(String itemId) async {
    final api = await getApi();
    if (api == null) return null;
    return api.getCoverUrl(itemId, updatedAt: _itemUpdatedAt[itemId]);
  }

  /// Fetch books for a library, returning raw entries.
  // ─── Alphabetical drilldown (CarPlay + Android Auto) ───────────────
  // Large libraries blow past Android Auto's ~1MB Binder limit and stampede
  // CarPlay's per-item cover loading. We group books by a growing title prefix
  // (the ABS app calls this "alphabetical drawdown"): show buckets when a list
  // exceeds [bucketThreshold], and drill one more character (T -> Th -> The) for
  // any bucket that's still too big - so a huge letter splits rather than being
  // truncated. We also skip characters that don't split (e.g. the space in
  // "The ") so the pile breaks by the real word.
  // 50 keeps final lists short and scannable (more letter drilldown) on both
  // surfaces; CarPlay's memory is handled by the patched plugin image loader,
  // so this is a navigation-feel choice, not a crash guard.
  static const int bucketThreshold = 50;

  // Cached full (title-sorted) book list per library so re-navigating doesn't
  // re-fetch the whole library each time.
  final Map<String, ({DateTime at, List<AutoBookEntry> books})> _allBooksCache = {};
  static const _booksCacheTtl = Duration(minutes: 5);

  /// Uppercased, left-trimmed title for prefix bucketing ('#' when empty).
  static String _normTitle(String title) {
    final t = title.trimLeft();
    return t.isEmpty ? '#' : t.toUpperCase();
  }

  /// The [len]-character uppercased prefix of a title (whole title if shorter).
  static String _prefixOf(String title, int len) {
    final t = _normTitle(title);
    return t.length <= len ? t : t.substring(0, len);
  }

  /// Fetch every book in the library (no cap), title-sorted. Cached for
  /// [_booksCacheTtl]. Shared by CarPlay and Android Auto.
  Future<List<AutoBookEntry>> fetchAllBooks(String libraryId) async {
    final cached = _allBooksCache[libraryId];
    if (cached != null && DateTime.now().difference(cached.at) < _booksCacheTtl) {
      return cached.books;
    }
    final api = await getApi();
    final books = <AutoBookEntry>[];
    if (api == null) return books;
    try {
      var page = 0;
      const pageSize = 100;
      while (true) {
        final result = await api.getLibraryItems(
          libraryId, page: page, limit: pageSize,
          sort: 'media.metadata.title', desc: 0,
        );
        if (result == null) break;
        final entries = _resultsToEntries(result, api);
        books.addAll(entries);
        final serverTotal = (result['total'] as num?)?.toInt() ?? 0;
        if (books.length >= serverTotal || entries.length < pageSize) break;
        page++;
      }
      _allBooksCache[libraryId] = (at: DateTime.now(), books: books);
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching all books: $e');
    }
    return books;
  }

  /// Resolve a browse level for [prefix] (empty = top). Returns either the leaf
  /// list of books to show, or the next set of (deeper) prefix buckets. Buckets
  /// are returned only when the matching list exceeds [bucketThreshold] and a
  /// longer prefix actually splits it; otherwise the matching books are a leaf.
  ({List<AutoBookEntry>? books, List<({String prefix, int count})>? buckets})
      resolveBrowseLevel(List<AutoBookEntry> all, String prefix) {
    final matching = prefix.isEmpty
        ? all
        : all.where((b) => _normTitle(b.title).startsWith(prefix)).toList();
    if (matching.length <= bucketThreshold) {
      return (books: matching, buckets: null);
    }
    // Extend the prefix one character at a time until it actually splits the
    // list (skips non-splitting chars like the space in "The ").
    var depth = prefix.length + 1;
    while (true) {
      final counts = <String, int>{};
      for (final b in matching) {
        final k = _prefixOf(b.title, depth);
        counts[k] = (counts[k] ?? 0) + 1;
      }
      if (counts.length > 1) {
        final buckets = counts.entries
            .map((e) => (prefix: e.key, count: e.value))
            .toList();
        return (books: null, buckets: buckets);
      }
      // Single bucket: go deeper only while some title is longer than [depth];
      // otherwise these titles are identical and can't be split - show them.
      if (!matching.any((b) => _normTitle(b.title).length > depth)) {
        return (books: matching, buckets: null);
      }
      depth++;
    }
  }

  /// Flatten the recursive prefix tree into a single ordered list of LEAF
  /// buckets (each <= [bucketThreshold] books). Used by CarPlay, where the
  /// recursive push drilldown isn't possible: CarPlay caps the navigation
  /// stack (~5 templates), so we show one bucket level then the books instead
  /// of pushing a template per letter the way Android Auto can.
  List<({String prefix, int count})> flattenedBookBuckets(List<AutoBookEntry> all) {
    final out = <({String prefix, int count})>[];
    void walk(String prefix) {
      final level = resolveBrowseLevel(all, prefix);
      if (level.books != null) {
        if (level.books!.isNotEmpty) {
          out.add((prefix: prefix, count: level.books!.length));
        }
        return;
      }
      for (final b in level.buckets!) {
        walk(b.prefix);
      }
    }

    walk('');
    return out;
  }

  /// All books whose title falls under [prefix] (a leaf bucket from
  /// [flattenedBookBuckets]). Empty prefix = the whole library.
  List<AutoBookEntry> booksForPrefix(List<AutoBookEntry> all, String prefix) {
    if (prefix.isEmpty) return all;
    return all.where((b) => _normTitle(b.title).startsWith(prefix)).toList();
  }

  /// Android Auto children for a books browse level at [prefix] (empty = top).
  Future<List<MediaItem>> _fetchBooksAtPrefix(String libraryId, String prefix) async {
    final all = await fetchAllBooks(libraryId);
    final level = resolveBrowseLevel(all, prefix);
    final books = level.books;
    if (books != null) {
      return books.map((e) => e.toMediaItem()).toList();
    }
    return level.buckets!
        .map((b) => MediaItem(
              id: AutoMediaIds.libBookPrefix(libraryId, b.prefix),
              title: b.prefix,
              playable: false,
            ))
        .toList();
  }

  /// Fetch series list for a library, returning id/name pairs.
  Future<List<({String id, String name})>> fetchLibrarySeriesData(String libraryId) async {
    final api = await getApi();
    if (api == null) return [];
    try {
      final allSeries = <({String id, String name})>[];
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
          if (sId.isNotEmpty) allSeries.add((id: sId, name: name));
        }
        final total = (result['total'] as num?)?.toInt() ?? 0;
        if (allSeries.length >= total || seriesList.length < pageSize) break;
        page++;
      }
      return allSeries;
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching series data: $e');
      return [];
    }
  }

  /// Fetch authors list for a library, returning id/name pairs.
  Future<List<({String id, String name})>> fetchLibraryAuthorsData(String libraryId) async {
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
          return aId.isNotEmpty ? (id: aId, name: name) : null;
        }).whereType<({String id, String name})>().toList();
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return items;
      }
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching authors data: $e');
    }
    return [];
  }

  /// Fetch books in a series, returning raw entries.
  Future<List<AutoBookEntry>> fetchSeriesBooksData(String seriesId, String libraryId) async {
    final api = await getApi();
    if (api == null) return [];
    try {
      final results = await api.getBooksBySeries(libraryId, seriesId);
      return _sortBySeriesSequence(results, seriesId)
          .map((item) => _libraryItemToEntry(item, api))
          .whereType<AutoBookEntry>()
          .toList();
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching series books data: $e');
      return [];
    }
  }

  /// Fetch books by an author, returning raw entries.
  Future<List<AutoBookEntry>> fetchAuthorBooksData(String authorId, String libraryId) async {
    final api = await getApi();
    if (api == null) return [];
    try {
      final results = await api.getBooksByAuthor(libraryId, authorId);
      return results
          .whereType<Map<String, dynamic>>()
          .map((item) => _libraryItemToEntry(item, api))
          .whereType<AutoBookEntry>()
          .toList();
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching author books data: $e');
      return [];
    }
  }

  /// Fetch podcast shows in a library, returning id/title pairs with cover URLs.
  Future<List<({String id, String title, String? coverUrl})>> fetchPodcastShowsData(String libraryId) async {
    final api = await getApi();
    if (api == null) return [];
    try {
      const maxItems = 200;
      final allShows = <({String id, String title, String? coverUrl})>[];
      int page = 0;
      const pageSize = 100;
      while (allShows.length < maxItems) {
        final result = await api.getLibraryItems(
          libraryId, page: page, limit: pageSize,
          sort: 'media.metadata.title', desc: 0,
        );
        if (result == null) break;
        final results = result['results'] as List<dynamic>? ?? [];
        for (final item in results) {
          if (item is! Map<String, dynamic>) continue;
          final id = item['id'] as String?;
          if (id == null) continue;
          final updatedAt = (item['updatedAt'] as num?)?.toInt();
          if (updatedAt != null) _itemUpdatedAt[id] = updatedAt;
          final media = item['media'] as Map<String, dynamic>?;
          final metadata = media?['metadata'] as Map<String, dynamic>? ?? {};
          final title = metadata['title'] as String? ?? 'Unknown';
          allShows.add((id: id, title: title, coverUrl: api.getCoverUrl(id, updatedAt: updatedAt)));
        }
        final total = (result['total'] as num?)?.toInt() ?? 0;
        if (allShows.length >= total || results.length < pageSize) break;
        page++;
      }
      return allShows.length > maxItems ? allShows.sublist(0, maxItems) : allShows;
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching podcast shows data: $e');
      return [];
    }
  }

  /// Fetch episodes for a podcast show, returning raw entries.
  Future<List<AutoBookEntry>> fetchShowEpisodesData(String showId, String libraryId) async {
    final api = await getApi();
    if (api == null) return [];
    try {
      final fullItem = await api.getLibraryItem(showId);
      if (fullItem == null) return [];
      final showUpdatedAt = (fullItem['updatedAt'] as num?)?.toInt();
      if (showUpdatedAt != null) _itemUpdatedAt[showId] = showUpdatedAt;
      final media = fullItem['media'] as Map<String, dynamic>?;
      final metadata = media?['metadata'] as Map<String, dynamic>? ?? {};
      final showTitle = metadata['title'] as String? ?? 'Podcast';
      final episodes = media?['episodes'] as List<dynamic>? ?? [];
      final sorted = List<dynamic>.from(episodes);
      sorted.sort((a, b) {
        final aTime = (a['publishedAt'] as num?)?.toInt() ?? 0;
        final bTime = (b['publishedAt'] as num?)?.toInt() ?? 0;
        return bTime.compareTo(aTime);
      });
      final entries = <AutoBookEntry>[];
      for (final ep in sorted) {
        if (ep is! Map<String, dynamic>) continue;
        final epId = ep['id'] as String?;
        if (epId == null) continue;
        entries.add(AutoBookEntry(
          id: '$showId-$epId',
          title: ep['title'] as String? ?? 'Episode',
          author: showTitle,
          duration: (ep['duration'] as num?)?.toDouble() ?? 0,
          coverUrl: api.getCoverUrl(showId, updatedAt: showUpdatedAt),
          chapters: ep['chapters'] as List<dynamic>? ?? [],
          episodeId: epId,
          showId: showId,
          libraryId: fullItem['libraryId'] as String? ?? libraryId,
        ));
      }
      return entries;
    } catch (e) {
      debugPrint('[AutoBrowse] Error fetching show episodes data: $e');
      return [];
    }
  }

  // ─── Search ────────────────────────────────────────────────────────

  Future<List<MediaItem>> search(String query) async {
    final api = await getApi();
    final libId = await getDefaultLibraryId();
    if (api == null || libId == null) return [];
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    try {
      final library = _libraries.cast<AutoLibraryEntry?>().firstWhere(
        (entry) => entry?.id == libId,
        orElse: () => null,
      );
      if (library?.isPodcast != true) {
        final index = BookSearchIndex();
        await index.ensureIndex(api, libId);
        if (index.isReady(libId)) {
          final hits = index
              .search(libId, trimmedQuery, limit: 20)
              .where((hit) => hit.item['mediaType'] != 'podcast')
              .map((hit) => _libraryItemToEntry(hit.item, api)?.toMediaItem())
              .whereType<MediaItem>()
              .toList();
          if (library?.isBook == true || hits.isNotEmpty) return hits;
        }
      }

      final result = await api.searchLibrary(libId, trimmedQuery, limit: 20);
      if (result == null) return [];

      final items = <MediaItem>[];
      // Search book results
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
      // Search podcast results
      final podcasts = result['podcast'] as List<dynamic>? ?? [];
      for (final p in podcasts) {
        final pm = p as Map<String, dynamic>;
        final libraryItem = pm['libraryItem'] as Map<String, dynamic>?;
        if (libraryItem != null) {
          final id = libraryItem['id'] as String?;
          if (id != null) {
            final media = libraryItem['media'] as Map<String, dynamic>?;
            final metadata = media?['metadata'] as Map<String, dynamic>? ?? {};
            final title = metadata['title'] as String? ?? 'Unknown';
            final coverUri = Uri.tryParse(localCoverUri(id));
            items.add(MediaItem(
              id: AutoMediaIds.showId(id, libId),
              title: title,
              artUri: coverUri,
              playable: false,
              extras: coverUri != null ? {'artUri': coverUri.toString()} : null,
            ));
          }
        }
      }
      return items;
    } catch (e) {
      debugPrint('[AutoBrowse] Search error: $e');
      return [];
    }
  }

  // ─── Lookup helpers ────────────────────────────────────────────────

  AutoBookEntry? findEntry(String absItemId) {
    for (final list in [_continueListening, _recentlyAdded, _downloaded]) {
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
