import 'package:flutter/foundation.dart';
import '../utils/fuzzy_search.dart';
import 'api_service.dart';
import 'socket_service.dart';

/// A scored search result: the raw library item plus whether it matched on the
/// title (so callers can keep a "Books" section to title hits).
class BookSearchHit {
  final Map<String, dynamic> item;
  final double score;
  final bool titleMatch;
  const BookSearchHit(this.item, this.score, this.titleMatch);
}

class _Indexed {
  final Map<String, dynamic> item;
  final String normTitle;
  final List<String> titleTokens; // title + subtitle words
  final List<String> authorTokens;
  final List<String> seriesTokens;
  const _Indexed(this.item, this.normTitle, this.titleTokens, this.authorTokens,
      this.seriesTokens);
}

/// In-memory, per-library index of all book items, used for lenient client-side
/// search (out-of-order words, punctuation, typos) that the strict server
/// `/search` endpoint can't do. Built once per library per session, then kept
/// current by patching single entries from socket item events (edits, adds,
/// removals) - the payloads carry the full item, so no refetch is needed.
class BookSearchIndex {
  BookSearchIndex._() {
    SocketService()
      ..addItemUpdatedListener(_onItemUpdated)
      ..addItemRemovedListener(_onItemRemoved);
  }
  static final BookSearchIndex instance = BookSearchIndex._();
  factory BookSearchIndex() => instance;

  final Map<String, List<_Indexed>> _cache = {};
  final Map<String, Future<void>> _inFlight = {};
  // Libraries whose index hit the item cap: their search results are missing
  // the newest items, so callers must merge the server's results in rather
  // than replacing them (GH #349 - books past 10k vanished from search).
  final Set<String> _truncated = {};

  void _onItemUpdated(Map<String, dynamic> item) => patchItem(item);

  /// Patch or insert a single item, e.g. from a socket event or the
  /// foreground catch-up sweep. No-op for libraries that aren't indexed yet -
  /// those build fresh on demand anyway.
  void patchItem(Map<String, dynamic> item) {
    final libId = item['libraryId'] as String?;
    final id = item['id'] as String?;
    if (libId == null || id == null) return;
    final idx = _cache[libId];
    if (idx == null) return;
    final entry = _indexItem(item);
    final i = idx.indexWhere((e) => e.item['id'] == id);
    if (i >= 0) {
      idx[i] = entry;
    } else {
      idx.add(entry);
    }
  }

  void _onItemRemoved(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    if (id == null) return;
    for (final idx in _cache.values) {
      idx.removeWhere((e) => e.item['id'] == id);
    }
  }

  bool isReady(String libraryId) => _cache.containsKey(libraryId);

  /// True when the library has more items than the index cap, meaning search
  /// results from this index are incomplete for the newest items.
  bool isTruncated(String libraryId) => _truncated.contains(libraryId);

  /// Drop everything (call on logout / account switch so a reused libraryId
  /// can't serve another account's items).
  void clear() {
    _cache.clear();
    _inFlight.clear();
    _truncated.clear();
  }

  /// Build the index for [libraryId] if not already cached. Concurrent callers
  /// share the same in-flight build. A failed fetch is not cached, so the next
  /// call retries.
  Future<void> ensureIndex(ApiService api, String libraryId) {
    if (_cache.containsKey(libraryId)) return Future.value();
    final existing = _inFlight[libraryId];
    if (existing != null) return existing;
    final f = _build(api, libraryId);
    _inFlight[libraryId] = f;
    return f.whenComplete(() => _inFlight.remove(libraryId));
  }

  Future<void> _build(ApiService api, String libraryId) async {
    const pageSize = 100;
    const maxPages = 100; // ~10k items safety cap

    final first =
        await api.getLibraryItems(libraryId, page: 0, limit: pageSize);
    if (first == null) return; // offline / error: leave uncached for retry
    final items = <Map<String, dynamic>>[];
    _collect(first, items);
    final total = (first['total'] as num?)?.toInt() ?? items.length;
    final pages = (total / pageSize).ceil();
    final lastPage = pages > maxPages ? maxPages : pages;

    if (lastPage > 1) {
      final futures = <Future<Map<String, dynamic>?>>[
        for (var p = 1; p < lastPage; p++)
          api.getLibraryItems(libraryId, page: p, limit: pageSize),
      ];
      for (final pd in await Future.wait(futures)) {
        if (pd != null) _collect(pd, items);
      }
    }
    if (pages > maxPages) {
      _truncated.add(libraryId);
      debugPrint('[BookSearchIndex] $libraryId has $total items; indexed first '
          '${maxPages * pageSize}. Callers merge server results for the rest.');
    } else {
      _truncated.remove(libraryId);
    }
    _cache[libraryId] = items.map(_indexItem).toList();
  }

  void _collect(Map<String, dynamic> page, List<Map<String, dynamic>> out) {
    final results = page['results'] as List<dynamic>? ?? [];
    for (final r in results) {
      final m = (r['libraryItem'] ?? r);
      if (m is Map<String, dynamic>) out.add(m);
    }
  }

  _Indexed _indexItem(Map<String, dynamic> item) {
    final media = item['media'] as Map<String, dynamic>? ?? {};
    final md = media['metadata'] as Map<String, dynamic>? ?? {};
    final title = md['title'] as String? ?? '';
    final subtitle = md['subtitle'] as String? ?? '';
    final author = md['authorName'] as String? ?? '';
    final series = md['seriesName'] as String? ?? '';
    final normTitle = normalizeForSearch(title);
    final titleTokens = tokenize(
        subtitle.isEmpty ? normTitle : '$normTitle ${normalizeForSearch(subtitle)}'.trim());
    return _Indexed(
      item,
      normTitle,
      titleTokens,
      tokenize(normalizeForSearch(author)),
      tokenize(normalizeForSearch(series)),
    );
  }

  List<BookSearchHit> search(String libraryId, String query, {int limit = 40}) {
    final idx = _cache[libraryId];
    if (idx == null) return const [];
    final normQuery = normalizeForSearch(query);
    final qTokens = tokenize(normQuery);
    if (qTokens.isEmpty) return const [];
    final hits = <BookSearchHit>[];
    for (final e in idx) {
      final r = scoreTokens(
        qTokens: qTokens,
        normQuery: normQuery,
        normTitle: e.normTitle,
        titleTokens: e.titleTokens,
        authorTokens: e.authorTokens,
        seriesTokens: e.seriesTokens,
      );
      if (r != null) hits.add(BookSearchHit(e.item, r.score, r.titleMatch));
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.length > limit ? hits.sublist(0, limit) : hits;
  }
}
