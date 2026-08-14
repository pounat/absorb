import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'player_settings.dart';
import 'scoped_prefs.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;

/// Result for a single series that has upcoming or recently released books.
class UpcomingSeriesResult {
  final String seriesId;
  final String seriesName;
  final String audibleAsin;
  final List<Map<String, dynamic>> upcomingBooks;
  final List<Map<String, dynamic>> recentBooks; // released in last 30 days

  UpcomingSeriesResult({
    required this.seriesId,
    required this.seriesName,
    required this.audibleAsin,
    required this.upcomingBooks,
    this.recentBooks = const [],
  });

  Map<String, dynamic> toJson() => {
    'seriesId': seriesId,
    'seriesName': seriesName,
    'audibleAsin': audibleAsin,
    'upcomingBooks': upcomingBooks,
    'recentBooks': recentBooks,
  };

  factory UpcomingSeriesResult.fromJson(Map<String, dynamic> json) => UpcomingSeriesResult(
    seriesId: json['seriesId'] as String? ?? '',
    seriesName: json['seriesName'] as String? ?? '',
    audibleAsin: json['audibleAsin'] as String? ?? '',
    upcomingBooks: (json['upcomingBooks'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [],
    recentBooks: (json['recentBooks'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [],
  );
}

/// A series the scan skipped because it looks finished, was manually
/// excluded, or couldn't be matched on Audible.
class SkippedSeries {
  final String seriesId;
  final String seriesName;
  final String audibleAsin; // '' = could not be matched on Audible
  final String newestRelease; // '' = unknown

  SkippedSeries({
    required this.seriesId,
    required this.seriesName,
    required this.audibleAsin,
    required this.newestRelease,
  });

  Map<String, dynamic> toJson() => {
    'id': seriesId,
    'name': seriesName,
    'asin': audibleAsin,
    'newestRelease': newestRelease,
  };

  factory SkippedSeries.fromJson(Map<String, dynamic> json) => SkippedSeries(
    seriesId: json['id'] as String? ?? '',
    seriesName: json['name'] as String? ?? '',
    audibleAsin: json['asin'] as String? ?? '',
    newestRelease: json['newestRelease'] as String? ?? '',
  );
}

enum SingleScanOutcome { found, none, failed }

/// Why a series is being skipped this scan: not at all, visibly (dormant /
/// excluded / unmatched), or silently (deep scan, known complete).
enum _SkipKind { none, skipped, complete }

/// Result of a deep scan for one series: released books not in the library.
class MissingSeriesResult {
  final String seriesId;
  final String seriesName;
  final String audibleAsin;
  final List<Map<String, dynamic>> missingBooks;

  MissingSeriesResult({
    required this.seriesId,
    required this.seriesName,
    required this.audibleAsin,
    required this.missingBooks,
  });

  Map<String, dynamic> toJson() => {
    'seriesId': seriesId,
    'seriesName': seriesName,
    'audibleAsin': audibleAsin,
    'missingBooks': missingBooks,
  };

  factory MissingSeriesResult.fromJson(Map<String, dynamic> json) => MissingSeriesResult(
    seriesId: json['seriesId'] as String? ?? '',
    seriesName: json['seriesName'] as String? ?? '',
    audibleAsin: json['audibleAsin'] as String? ?? '',
    missingBooks: (json['missingBooks'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [],
  );
}

/// A book the user removed from the page for good ("this and future scans").
/// Keeps enough context to restore it into the right list later.
class IgnoredBook {
  final Map<String, dynamic> book;
  final String seriesId;
  final String seriesName;
  final String audibleAsin;
  final String from; // 'upcoming' | 'recent' | 'missing'
  final int removedAtMs;

  IgnoredBook({
    required this.book,
    required this.seriesId,
    required this.seriesName,
    required this.audibleAsin,
    required this.from,
    required this.removedAtMs,
  });

  String get asin => book['asin'] as String? ?? '';

  Map<String, dynamic> toJson() => {
    'book': book,
    'seriesId': seriesId,
    'seriesName': seriesName,
    'audibleAsin': audibleAsin,
    'from': from,
    'removedAtMs': removedAtMs,
  };

  factory IgnoredBook.fromJson(Map<String, dynamic> json) => IgnoredBook(
    book: Map<String, dynamic>.from(json['book'] as Map? ?? {}),
    seriesId: json['seriesId'] as String? ?? '',
    seriesName: json['seriesName'] as String? ?? '',
    audibleAsin: json['audibleAsin'] as String? ?? '',
    from: json['from'] as String? ?? 'recent',
    removedAtMs: (json['removedAtMs'] as num?)?.toInt() ?? 0,
  );
}

/// Summary of the last completed scan, shown as the scan report.
class ScanReport {
  final int completedAtMs;
  final bool deep;
  final int checked;
  final int skipped;
  final List<String> unmatchedNames;
  final List<String> failedNames;
  final int upcoming;
  final int recent;
  final int missing;

  ScanReport({
    required this.completedAtMs,
    required this.deep,
    required this.checked,
    required this.skipped,
    required this.unmatchedNames,
    required this.failedNames,
    required this.upcoming,
    required this.recent,
    required this.missing,
  });

  DateTime get completedAt => DateTime.fromMillisecondsSinceEpoch(completedAtMs);

  Map<String, dynamic> toJson() => {
    'completedAtMs': completedAtMs,
    'deep': deep,
    'checked': checked,
    'skipped': skipped,
    'unmatchedNames': unmatchedNames,
    'failedNames': failedNames,
    'upcoming': upcoming,
    'recent': recent,
    'missing': missing,
  };

  factory ScanReport.fromJson(Map<String, dynamic> json) => ScanReport(
    completedAtMs: (json['completedAtMs'] as num?)?.toInt() ?? 0,
    deep: json['deep'] as bool? ?? false,
    checked: (json['checked'] as num?)?.toInt() ?? 0,
    skipped: (json['skipped'] as num?)?.toInt() ?? 0,
    unmatchedNames: (json['unmatchedNames'] as List<dynamic>? ?? []).cast<String>(),
    failedNames: (json['failedNames'] as List<dynamic>? ?? []).cast<String>(),
    upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
    recent: (json['recent'] as num?)?.toInt() ?? 0,
    missing: (json['missing'] as num?)?.toInt() ?? 0,
  );
}

/// What the scan remembers about a series between runs.
class _SeriesScanEntry {
  String name;
  String asin; // '' = tried to resolve, no Audible match
  String newestRelease; // newest release date seen on Audible, '' = unknown
  int lastChecked; // epoch ms of the last successful discovery
  bool missingComplete; // last deep scan found no missing books
  String newestAtMissingCheck; // newestRelease at the time of that deep scan

  _SeriesScanEntry({
    required this.name,
    this.asin = '',
    this.newestRelease = '',
    this.lastChecked = 0,
    this.missingComplete = false,
    this.newestAtMissingCheck = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'asin': asin,
    'newestRelease': newestRelease,
    'lastChecked': lastChecked,
    'missingComplete': missingComplete,
    'newestAtMissingCheck': newestAtMissingCheck,
  };

  factory _SeriesScanEntry.fromJson(Map<String, dynamic> json) => _SeriesScanEntry(
    name: json['name'] as String? ?? '',
    asin: json['asin'] as String? ?? '',
    newestRelease: json['newestRelease'] as String? ?? '',
    lastChecked: (json['lastChecked'] as num?)?.toInt() ?? 0,
    missingComplete: json['missingComplete'] as bool? ?? false,
    newestAtMissingCheck: json['newestAtMissingCheck'] as String? ?? '',
  );
}

/// Scans library series for upcoming Audible releases.
///
/// Singleton service that survives screen navigation and continues in the
/// background. Results are cached to SharedPreferences so they persist
/// across app restarts.
class UpcomingReleasesService extends ChangeNotifier {
  // Singleton
  static final UpcomingReleasesService _instance = UpcomingReleasesService._();
  factory UpcomingReleasesService() => _instance;
  UpcomingReleasesService._();

  final List<UpcomingSeriesResult> _results = [];
  List<UpcomingSeriesResult> get results => _results;

  // Deep-scan results: released books missing from the library, per series
  final List<MissingSeriesResult> _missingResults = [];
  List<MissingSeriesResult> get missingResults => _missingResults;

  DateTime? _missingCacheTime;
  DateTime? get missingCacheTime => _missingCacheTime;

  int get missingBookCount =>
      _missingResults.fold<int>(0, (sum, r) => sum + r.missingBooks.length);

  bool _isDeepScan = false;
  bool get isDeepScan => _isDeepScan;

  // Series that had upcoming/recent entries when the current scan started; a
  // deep scan must re-check these even when they're known missing-complete,
  // or their entries would silently drop out of the refreshed results.
  Set<String> _seriesWithPriorResults = {};

  // Library-wide ownership index. The per-series book fetch only sees books
  // filed in that exact ABS series, so anything owned as a standalone or
  // under a differently-named series would be flagged missing without this.
  // ASINs match precisely; titles need the author too, or generic titles
  // ("Homecoming") would mark unowned books as owned.
  Set<String> _libraryOwnedAsins = {};
  Set<String> _libraryOwnedTitleAuthor = {};
  String _ownedIndexLibraryId = '';
  DateTime? _ownedIndexAt;

  // Books already on the page when the scan started; anything discovered
  // outside this set gets a NEW badge (suppressed on the very first scan,
  // where everything would be new).
  Set<String> _priorSeenAsins = {};
  bool _priorHadData = false;

  // Scan report bookkeeping
  ScanReport? _lastReport;
  ScanReport? get lastReport => _lastReport;
  int _scanCheckedCount = 0;
  int _scanSkippedCount = 0;
  final Set<String> _scanUnmatchedNames = {};
  final List<String> _scanFailedNames = [];

  /// Whether any scan has ever completed (state exists) - drives the
  /// first-scan explainer in the UI.
  bool get hasScanKnowledge => _scanState.isNotEmpty;

  // Permanently removed books ("this and future scans")
  final List<IgnoredBook> _ignoredBooks = [];
  final Set<String> _ignoredAsins = {};
  bool _ignoredLoaded = false;
  List<IgnoredBook> get ignoredBooks => List.unmodifiable(_ignoredBooks);
  int get ignoredCount => _ignoredBooks.length;

  static const _ignoredKey = 'upcomingReleasesIgnoredBooks';

  Future<void> _loadIgnored() async {
    if (_ignoredLoaded) return;
    _ignoredLoaded = true;
    try {
      final json = await ScopedPrefs.getString(_ignoredKey);
      if (json == null || json.isEmpty) return;
      final list = jsonDecode(json) as List<dynamic>;
      _ignoredBooks
        ..clear()
        ..addAll(list.map((e) =>
            IgnoredBook.fromJson(Map<String, dynamic>.from(e as Map))));
      _ignoredAsins
        ..clear()
        ..addAll(_ignoredBooks.map((b) => b.asin).where((a) => a.isNotEmpty));
    } catch (e) {
      debugPrint('[Upcoming] loadIgnored error: $e');
    }
  }

  Future<void> _saveIgnored() async {
    try {
      await ScopedPrefs.setString(
          _ignoredKey, jsonEncode(_ignoredBooks.map((b) => b.toJson()).toList()));
    } catch (e) {
      debugPrint('[Upcoming] saveIgnored error: $e');
    }
  }

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  bool _isComplete = false;
  bool get isComplete => _isComplete;

  bool _hasCachedResults = false;
  bool get hasCachedResults => _hasCachedResults;

  int _processedCount = 0;
  int get processedCount => _processedCount;

  int _totalSeries = 0;
  int get totalSeries => _totalSeries;

  String? _currentSeriesName;
  String? get currentSeriesName => _currentSeriesName;

  String? _error;
  String? get error => _error;

  String _region = 'us';
  String get region => _region;

  int _generation = 0;

  // Cache: series ID -> Audible ASIN (or empty string if unresolvable)
  final Map<String, String> _asinCache = {};
  // Cache: Audible ASIN -> discovered books (dedup within a single run only)
  final Map<String, List<Map<String, dynamic>>> _discoveryCache = {};

  // Persisted knowledge from previous scans: series ID -> entry
  final Map<String, _SeriesScanEntry> _scanState = {};
  bool _scanStateLoaded = false;
  String _scanStateLibraryId = '';

  // Skip configuration, read once per scan
  int _finishedAfterYears = 0;
  Set<String> _alwaysScan = {};
  Set<String> _neverScan = {};

  final List<SkippedSeries> _skippedThisScan = [];
  List<SkippedSeries> _persistedSkipped = [];

  /// Series skipped as finished: the in-progress list while a scan runs,
  /// otherwise the last completed scan's list.
  List<SkippedSeries> get skippedSeries =>
      List.unmodifiable(_isRunning ? _skippedThisScan : _persistedSkipped);
  int get skippedCount => _isRunning ? _skippedThisScan.length : _persistedSkipped.length;

  /// Library the persisted skipped list was scanned from.
  String get skippedLibraryId => _scanStateLibraryId;

  // How long a skipped series stays skipped before it gets re-checked.
  static const _finishedRecheckDays = 30;
  static const _ancientDormancyYears = 5;
  static const _ancientRecheckDays = 90;
  static const _unresolvedRecheckDays = 90;

  /// Pref keys for the per-series scan overrides (ScopedPrefs string lists).
  static const alwaysScanPrefKey = 'upcoming_always_scan_series';
  static const neverScanPrefKey = 'upcoming_never_scan_series';

  // Notification
  static const _notifChannelId = 'absorb_upcoming_scan';
  String get _notifChannelName =>
      _l()?.upcomingNotifChannelName ?? 'Upcoming Release Scan';
  String get _notifChannelDesc =>
      _l()?.upcomingNotifChannelDesc ?? 'Shows progress while scanning for upcoming releases';
  static const _scanNotifId = 9100;
  static const _completeNotifId = 9101;

  AppLocalizations? _l() {
    final ctx = rootNavigatorKey.currentContext;
    return ctx != null ? AppLocalizations.of(ctx) : null;
  }

  // Persistence keys
  static const _cacheKey = 'upcomingReleasesCache';
  static const _cacheTimeKey = 'upcomingReleasesCacheTime';
  static const _cacheRegionKey = 'upcomingReleasesCacheRegion';
  static const _scanStateKey = 'upcomingReleasesScanState';
  static const _missingCacheKey = 'upcomingReleasesMissingCache';
  static const _missingCacheTimeKey = 'upcomingReleasesMissingCacheTime';
  static const _missingCacheRegionKey = 'upcomingReleasesMissingCacheRegion';

  DateTime? _cacheTime;
  DateTime? get cacheTime => _cacheTime;

  /// Whether the cache is older than 2 weeks (suggest rescan).
  bool get isCacheStale =>
      _cacheTime != null && DateTime.now().difference(_cacheTime!).inDays >= 14;

  /// Load cached results from SharedPreferences.
  /// Returns true if valid cache was loaded (regardless of age).
  Future<bool> loadCache() async {
    await _loadScanState();
    await _loadMissingCache();
    await _loadIgnored();
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimeMs = prefs.getInt(_cacheTimeKey) ?? 0;
      final cachedRegion = prefs.getString(_cacheRegionKey) ?? '';
      if (cacheTimeMs == 0) return false;
      if (cachedRegion != _region) return false;

      final json = prefs.getString(_cacheKey);
      if (json == null || json.isEmpty) return false;

      final list = jsonDecode(json) as List<dynamic>;
      _results.clear();
      for (final item in list) {
        _results.add(UpcomingSeriesResult.fromJson(item as Map<String, dynamic>));
      }
      _cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimeMs);
      _hasCachedResults = true;
      _isComplete = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Upcoming] loadCache error: $e');
      return false;
    }
  }

  /// Load the persisted per-series scan knowledge (once per session/region).
  Future<void> _loadScanState() async {
    if (_scanStateLoaded) return;
    _scanStateLoaded = true;
    try {
      final json = await ScopedPrefs.getString(_scanStateKey);
      if (json == null || json.isEmpty) return;
      final data = jsonDecode(json) as Map<String, dynamic>;
      // ASINs and release dates are region-specific
      if ((data['region'] as String? ?? '') != _region) return;
      _scanStateLibraryId = data['libraryId'] as String? ?? '';
      final series = data['series'] as Map<String, dynamic>? ?? {};
      for (final e in series.entries) {
        final entry = _SeriesScanEntry.fromJson(
            Map<String, dynamic>.from(e.value as Map));
        _scanState[e.key] = entry;
        // Only seed resolved ASINs - unresolvable series get another
        // resolution attempt once their recheck interval elapses.
        if (entry.asin.isNotEmpty) _asinCache[e.key] = entry.asin;
      }
      _persistedSkipped = (data['skipped'] as List<dynamic>? ?? [])
          .map((s) => SkippedSeries.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
      final report = data['lastReport'];
      if (report is Map) {
        _lastReport = ScanReport.fromJson(Map<String, dynamic>.from(report));
      }
    } catch (e) {
      debugPrint('[Upcoming] loadScanState error: $e');
    }
  }

  Future<void> _saveScanState() async {
    try {
      final data = {
        'region': _region,
        'libraryId': _scanStateLibraryId,
        'skipped': _persistedSkipped.map((s) => s.toJson()).toList(),
        if (_lastReport != null) 'lastReport': _lastReport!.toJson(),
        'series': {for (final e in _scanState.entries) e.key: e.value.toJson()},
      };
      await ScopedPrefs.setString(_scanStateKey, jsonEncode(data));
    } catch (e) {
      debugPrint('[Upcoming] saveScanState error: $e');
    }
  }

  void _resetScanKnowledge() {
    _scanState.clear();
    _asinCache.clear();
    _discoveryCache.clear();
    _skippedThisScan.clear();
    _persistedSkipped = [];
    _scanStateLibraryId = '';
    _scanStateLoaded = false;
    _missingResults.clear();
    _missingCacheTime = null;
    _lastReport = null;
  }

  /// Load the deep-scan results cache, once per session/region.
  Future<void> _loadMissingCache() async {
    if (_missingCacheTime != null || _missingResults.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeMs = prefs.getInt(_missingCacheTimeKey) ?? 0;
      if (timeMs == 0) return;
      if ((prefs.getString(_missingCacheRegionKey) ?? '') != _region) return;
      final json = prefs.getString(_missingCacheKey);
      if (json == null || json.isEmpty) return;
      final list = jsonDecode(json) as List<dynamic>;
      _missingResults
        ..clear()
        ..addAll(list.map((e) =>
            MissingSeriesResult.fromJson(Map<String, dynamic>.from(e as Map))));
      _missingCacheTime = DateTime.fromMillisecondsSinceEpoch(timeMs);
      notifyListeners();
    } catch (e) {
      debugPrint('[Upcoming] loadMissingCache error: $e');
    }
  }

  Future<void> _saveMissingCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_missingCacheKey,
          jsonEncode(_missingResults.map((r) => r.toJson()).toList()));
      await prefs.setInt(_missingCacheTimeKey,
          (_missingCacheTime ?? DateTime.now()).millisecondsSinceEpoch);
      await prefs.setString(_missingCacheRegionKey, _region);
    } catch (e) {
      debugPrint('[Upcoming] saveMissingCache error: $e');
    }
  }

  /// Save current results to SharedPreferences.
  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_results.map((r) => r.toJson()).toList());
      await prefs.setString(_cacheKey, json);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(_cacheRegionKey, _region);
    } catch (e) {
      debugPrint('[Upcoming] saveCache error: $e');
    }
  }

  /// Start scanning all series in the library.
  ///
  /// Uses the lightweight filter-data endpoint to get series IDs/names
  /// (avoids the heavy series endpoint that embeds all books per series,
  /// which can OOM servers when a series has 1000+ books).
  /// Then fetches a small number of books per series for ASIN resolution.
  Future<void> start({
    required ApiService api,
    required String libraryId,
    required String region,
    bool deep = false,
  }) async {
    if (_isRunning) return;
    _generation++;
    final gen = _generation;
    if (region != _region) {
      _region = region;
      _resetScanKnowledge();
    }
    _isDeepScan = deep;
    _seriesWithPriorResults = _results.map((r) => r.seriesId).toSet();
    _priorSeenAsins = {
      for (final r in _results) ...[
        ...r.upcomingBooks.map((b) => b['asin'] as String? ?? ''),
        ...r.recentBooks.map((b) => b['asin'] as String? ?? ''),
      ],
      for (final r in _missingResults) ...r.missingBooks.map((b) => b['asin'] as String? ?? ''),
    }..remove('');
    _priorHadData = _results.isNotEmpty || _missingResults.isNotEmpty;
    _scanCheckedCount = 0;
    _scanSkippedCount = 0;
    _scanUnmatchedNames.clear();
    _scanFailedNames.clear();

    _isRunning = true;
    _isComplete = false;
    _processedCount = 0;
    _totalSeries = 0;
    _error = null;
    _results.clear();
    _hasCachedResults = false;
    _currentSeriesName = null;
    _skippedThisScan.clear();
    _discoveryCache.clear();
    notifyListeners();

    await _showScanNotification(_l()?.upcomingNotifStartingScan ?? 'Starting scan...');

    _finishedAfterYears = await PlayerSettings.getUpcomingFinishedAfterYears();
    _alwaysScan = (await ScopedPrefs.getStringList(alwaysScanPrefKey)).toSet();
    _neverScan = (await ScopedPrefs.getStringList(neverScanPrefKey)).toSet();
    await _loadScanState();
    await _loadIgnored();
    await _ensureOwnedIndex(api, libraryId, gen, force: true);
    if (_generation != gen) return;

    try {
      // Use filter data to get series list - lightweight, no embedded books
      final filterData = await api.getLibraryFilterData(libraryId);
      if (_generation != gen) return;
      if (filterData == null) {
        _error = 'Failed to load series';
        _isRunning = false;
        await _cancelScanNotification();
        notifyListeners();
        return;
      }

      final seriesList = filterData['series'] as List<dynamic>? ?? [];
      _totalSeries = seriesList.length;
      notifyListeners();

      if (_totalSeries == 0) {
        _isRunning = false;
        _isComplete = true;
        await _cancelScanNotification();
        notifyListeners();
        return;
      }

      // Process each series
      for (final s in seriesList) {
        if (_generation != gen) return;
        if (s is! Map<String, dynamic>) {
          _processedCount++;
          notifyListeners();
          continue;
        }
        await _processSeries(api, libraryId, s, gen);
        // Keep resolved ASINs and release dates if the scan gets cancelled
        if (_generation == gen && _processedCount % 25 == 0) {
          await _saveScanState();
        }
      }

      if (_generation != gen) return;
      _isRunning = false;
      _isComplete = true;
      _currentSeriesName = null;
      // Only a completed scan may replace the persisted skipped list - a
      // cancelled one would leave a truncated list beside full results.
      _persistedSkipped = List.of(_skippedThisScan);
      _scanStateLibraryId = libraryId;
      _lastReport = ScanReport(
        completedAtMs: DateTime.now().millisecondsSinceEpoch,
        deep: _isDeepScan,
        checked: _scanCheckedCount,
        skipped: _scanSkippedCount,
        unmatchedNames: _scanUnmatchedNames.toList()..sort(),
        failedNames: List.of(_scanFailedNames),
        upcoming: _results.fold<int>(0, (sum, r) => sum + r.upcomingBooks.length),
        recent: _results.fold<int>(0, (sum, r) => sum + r.recentBooks.length),
        missing: missingBookCount,
      );
      debugPrint('[Upcoming] Scan complete${_isDeepScan ? ' (deep)' : ''}: '
          '${_results.length} series with results, '
          '${_results.fold<int>(0, (sum, r) => sum + r.upcomingBooks.length)} upcoming, '
          '${_results.fold<int>(0, (sum, r) => sum + r.recentBooks.length)} recent, '
          '${_skippedThisScan.length} skipped'
          '${_isDeepScan ? ', $missingBookCount missing across ${_missingResults.length} series' : ''}');
      notifyListeners();

      await _saveCache();
      await _saveScanState();
      if (_isDeepScan) {
        _missingCacheTime = DateTime.now();
        await _saveMissingCache();
      }
      await _cancelScanNotification();
      await _showCompleteNotification();
    } catch (e, st) {
      if (_generation != gen) return;
      debugPrint('[Upcoming] scan error: $e\n$st');
      _error = 'Scan failed: $e';
      _isRunning = false;
      await _cancelScanNotification();
      notifyListeners();
    }
  }

  /// Process a single series: skip it when it looks finished, otherwise
  /// resolve its ASIN, discover Audible books and filter.
  Future<void> _processSeries(ApiService api, String libraryId, Map<String, dynamic> s, int gen) async {
    final seriesId = s['id'] as String? ?? '';
    final seriesName = s['name'] as String? ?? 'Unknown Series';

    final skip = _skipKindFor(seriesId);
    if (skip != _SkipKind.none) {
      // Missing-complete skips are silent: the series was fully checked and
      // found complete, so it doesn't belong in the "not checked" list.
      if (skip == _SkipKind.skipped) {
        final entry = _scanState[seriesId];
        final unmatched = entry != null && entry.asin.isEmpty;
        if (unmatched) {
          _scanUnmatchedNames.add(seriesName);
        } else {
          _scanSkippedCount++;
        }
        _skippedThisScan.add(SkippedSeries(
          seriesId: seriesId,
          seriesName: seriesName,
          audibleAsin: entry?.asin ?? '',
          newestRelease: entry?.newestRelease ?? '',
        ));
      } else {
        _scanSkippedCount++;
      }
      _processedCount++;
      notifyListeners();
      return;
    }

    // Already found unresolvable earlier in this session - nothing to do
    if (_asinCache[seriesId] == '') {
      _scanUnmatchedNames.add(seriesName);
      _processedCount++;
      notifyListeners();
      return;
    }

    _currentSeriesName = seriesName;
    notifyListeners();

    // Update scan notification periodically
    if (_processedCount % 5 == 0) {
      final l = _l();
      await _showScanNotification(
        l?.upcomingNotifCheckingSeries(seriesName, _processedCount + 1, _totalSeries)
          ?? 'Checking $seriesName... (${_processedCount + 1}/$_totalSeries)',
      );
    }

    _scanCheckedCount++;
    final result = await _discoverOne(api, libraryId, seriesId, seriesName, gen);
    if (_generation != gen) return;
    if (result != null) _results.add(result);

    _processedCount++;
    notifyListeners();

    // Small delay between series to be nice to Audible API
    if (_generation == gen) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// The network core for one series: fetch its books, resolve the Audible
  /// series ASIN, discover the Audible catalog and filter to upcoming/recent
  /// books. Updates the persisted scan state along the way. Returns null when
  /// nothing qualifies (or on cancellation).
  Future<UpcomingSeriesResult?> _discoverOne(
      ApiService api, String libraryId, String seriesId, String seriesName, int gen) async {
    final prevNewest = DateTime.tryParse(_scanState[seriesId]?.newestRelease ?? '');

    // Fetch a small number of books for this series (for ASIN resolution
    // and ownership check) instead of relying on embedded books from the
    // series endpoint, which can OOM the server for huge series.
    List<dynamic> books;
    final cachedAsin = _asinCache[seriesId];
    if (cachedAsin != null) {
      if (cachedAsin.isEmpty) return null;
      books = await api.getBooksBySeries(libraryId, seriesId, limit: 500);
    } else {
      // Fetch a small batch for ASIN resolution first
      books = await api.getBooksBySeries(libraryId, seriesId, limit: 10);
    }
    if (_generation != gen) return null;

    // Try to resolve the Audible series ASIN
    String? audibleAsin;
    if (cachedAsin != null) {
      audibleAsin = cachedAsin;
    } else {
      final (resolved, concluded) = await _resolveSeriesAsin(books, seriesName, gen);
      if (_generation != gen) return null;
      audibleAsin = resolved;
      _asinCache[seriesId] = audibleAsin ?? '';
      final entry = _scanState.putIfAbsent(
          seriesId, () => _SeriesScanEntry(name: seriesName));
      entry.name = seriesName;
      if (audibleAsin != null) {
        entry.asin = audibleAsin;
      } else if (concluded) {
        // Audnexus answered but knows no series for these books. Park the
        // series until the unresolved recheck interval elapses; a transient
        // network failure must not park it, so lastChecked only moves here.
        entry.asin = '';
        entry.lastChecked = DateTime.now().millisecondsSinceEpoch;
        _scanUnmatchedNames.add(seriesName);
      } else {
        _scanFailedNames.add(seriesName);
      }

      // If we resolved an ASIN, fetch more books for ownership check
      if (audibleAsin != null && books.length >= 10) {
        books = await api.getBooksBySeries(libraryId, seriesId, limit: 500);
        if (_generation != gen) return null;
      }
    }

    if (audibleAsin == null || audibleAsin.isEmpty) return null;

    // Collect owned title variants and ASINs from library books
    final ownedTitles = <String>{};
    final ownedAsins = <String>{};
    for (final b in books) {
      if (b is! Map<String, dynamic>) continue;
      final media = b['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      ownedTitles.addAll(_titleVariants(metadata['title'] as String? ?? ''));
      final asin = metadata['asin'] as String? ?? '';
      if (asin.isNotEmpty) ownedAsins.add(asin);
    }

    // Get all books in the series from Audible
    List<Map<String, dynamic>> allBooks;
    var discovered = false;
    if (_discoveryCache.containsKey(audibleAsin)) {
      allBooks = _discoveryCache[audibleAsin]!;
      discovered = true;
    } else {
      allBooks = [];
      for (var attempt = 0; attempt < 3; attempt++) {
        if (_generation != gen) return null;
        try {
          allBooks = await ApiService.discoverAudibleSeries(audibleAsin, region: _region, newestOnly: !_isDeepScan);
          if (_generation != gen) return null;
          _discoveryCache[audibleAsin] = allBooks;
          discovered = true;
          break;
        } catch (e) {
          debugPrint('[Upcoming] discover error for $seriesName (attempt ${attempt + 1}/3): $e');
          if (attempt < 2) await Future.delayed(const Duration(seconds: 2));
        }
      }
      if (!discovered) _scanFailedNames.add(seriesName);
    }

    if (discovered) {
      final entry = _scanState.putIfAbsent(
          seriesId, () => _SeriesScanEntry(name: seriesName));
      entry.name = seriesName;
      entry.asin = audibleAsin;
      final newest = _newestReleaseOf(allBooks);
      if (newest.isNotEmpty) entry.newestRelease = newest;
      entry.lastChecked = DateTime.now().millisecondsSinceEpoch;

      // Deep scan: everything released and not owned is missing (same rule
      // as the per-series sheet's Missing filter).
      if (_isDeepScan) {
        final missing = allBooks
            .where((b) =>
                !_ignoredAsins.contains(b['asin'] as String? ?? '') &&
                !_isUpcoming(b) &&
                !_isOwnedBook(b, ownedTitles, ownedAsins))
            .map((b) => {...b, if (_isNewBook(b)) '_new': true})
            .toList();
        entry.missingComplete = missing.isEmpty;
        entry.newestAtMissingCheck = entry.newestRelease;
        _missingResults.removeWhere((r) => r.seriesId == seriesId);
        if (missing.isNotEmpty) {
          _missingResults.add(MissingSeriesResult(
            seriesId: seriesId,
            seriesName: seriesName,
            audibleAsin: audibleAsin,
            missingBooks: missing,
          ));
        }
      }
    }

    // Filter to upcoming and recently released. A book released after the
    // previous scan's newest known release also counts as recent even when
    // it's over 30 days old - a delayed recheck must not miss it. Books
    // already in the library are dropped: nothing to act on.
    final upcoming = allBooks
        .where((b) =>
            _isUpcoming(b) && !_ignoredAsins.contains(b['asin'] as String? ?? ''))
        .map((b) => {...b, if (_isNewBook(b)) '_new': true})
        .toList();
    final recent = <Map<String, dynamic>>[];
    for (final book in allBooks) {
      if (_isRecentRelease(book) || _isNewSinceLastScan(book, prevNewest)) {
        if (_ignoredAsins.contains(book['asin'] as String? ?? '')) continue;
        if (_isOwnedBook(book, ownedTitles, ownedAsins)) continue;
        recent.add({...book, '_owned': false, if (_isNewBook(book)) '_new': true});
      }
    }

    if (upcoming.isEmpty && recent.isEmpty) return null;
    return UpcomingSeriesResult(
      seriesId: seriesId,
      seriesName: seriesName,
      audibleAsin: audibleAsin,
      upcomingBooks: upcoming,
      recentBooks: recent,
    );
  }

  /// Build the library-wide ownership index by paging through all items.
  /// [force] rebuilds even when a fresh index exists (used by full scans).
  Future<void> _ensureOwnedIndex(ApiService api, String libraryId, int gen, {bool force = false}) async {
    final fresh = _ownedIndexLibraryId == libraryId &&
        _ownedIndexAt != null &&
        DateTime.now().difference(_ownedIndexAt!).inMinutes < 15;
    if (fresh && !force) return;
    final asins = <String>{};
    final titleAuthor = <String>{};
    try {
      var page = 0;
      while (true) {
        if (_generation != gen) return;
        final data = await api.getLibraryItems(libraryId, page: page, limit: 500);
        final results = data?['results'] as List<dynamic>? ?? [];
        for (final item in results) {
          if (item is! Map<String, dynamic>) continue;
          final media = item['media'] as Map<String, dynamic>? ?? {};
          final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
          final asin = metadata['asin'] as String? ?? '';
          if (asin.isNotEmpty) asins.add(asin);
          // Minified items carry authorName, full items an authors array
          var authorName = metadata['authorName'] as String? ?? '';
          if (authorName.isEmpty) {
            final authors = metadata['authors'] as List<dynamic>? ?? [];
            if (authors.isNotEmpty && authors.first is Map) {
              authorName = (authors.first as Map)['name'] as String? ?? '';
            }
          }
          final author = _normalizeAuthor(authorName);
          if (author.isNotEmpty) {
            for (final v in _titleVariants(metadata['title'] as String? ?? '')) {
              titleAuthor.add('$v|$author');
            }
          }
        }
        if (results.length < 500) break;
        page++;
        if (page > 100) break;
      }
      _libraryOwnedAsins = asins;
      _libraryOwnedTitleAuthor = titleAuthor;
      _ownedIndexLibraryId = libraryId;
      _ownedIndexAt = DateTime.now();
      debugPrint('[Upcoming] Owned index built: ${asins.length} asins, '
          '${titleAuthor.length} title+author keys');
    } catch (e) {
      debugPrint('[Upcoming] owned index error: $e');
    }
  }

  /// Whether this scan can skip the series based on previous-scan knowledge.
  _SkipKind _skipKindFor(String seriesId) {
    if (seriesId.isEmpty) return _SkipKind.none;
    if (_alwaysScan.contains(seriesId)) return _SkipKind.none;
    if (_neverScan.contains(seriesId)) return _SkipKind.skipped;
    final entry = _scanState[seriesId];
    if (entry == null || entry.lastChecked <= 0) return _SkipKind.none;
    final now = DateTime.now();
    final checkedDays =
        now.difference(DateTime.fromMillisecondsSinceEpoch(entry.lastChecked)).inDays;
    if (entry.asin.isEmpty) {
      // Couldn't be matched on Audible - retry resolution only occasionally.
      // With the finished-series setting off, regular scans keep the old
      // check-everything behavior; deep scans always park these.
      if (!_isDeepScan && _finishedAfterYears <= 0) return _SkipKind.none;
      return checkedDays < _unresolvedRecheckDays ? _SkipKind.skipped : _SkipKind.none;
    }
    if (_isDeepScan) {
      // Deep scans ignore dormancy. Only a series the last deep scan found
      // complete, with no release seen since, and nothing currently on the
      // page (an upcoming entry must still be refreshed) can be skipped.
      final complete = entry.missingComplete &&
          entry.newestAtMissingCheck.isNotEmpty &&
          entry.newestAtMissingCheck == entry.newestRelease &&
          !_seriesWithPriorResults.contains(seriesId);
      return complete ? _SkipKind.complete : _SkipKind.none;
    }
    if (_finishedAfterYears <= 0) return _SkipKind.none;
    final newest = DateTime.tryParse(entry.newestRelease);
    if (newest == null) return _SkipKind.none;
    final dormantDays = now.difference(newest).inDays;
    // A future newest release makes dormancy negative, so a series with a
    // known upcoming book is always checked regardless of the setting.
    if (dormantDays < _finishedAfterYears * 365) return _SkipKind.none;
    final recheckDays = dormantDays >= _ancientDormancyYears * 365
        ? _ancientRecheckDays
        : _finishedRecheckDays;
    return checkedDays < recheckDays ? _SkipKind.skipped : _SkipKind.none;
  }

  /// Newest parseable release date across discovered books, upcoming ones
  /// included, ignoring Audible's far-future placeholder dates.
  String _newestReleaseOf(List<Map<String, dynamic>> books) {
    final cap = DateTime.now().year + 5;
    String best = '';
    DateTime? bestDate;
    for (final b in books) {
      final raw = b['releaseDate'] as String? ?? '';
      final d = DateTime.tryParse(raw);
      if (d == null || d.year > cap) continue;
      if (bestDate == null || d.isAfter(bestDate)) {
        bestDate = d;
        best = raw;
      }
    }
    return best;
  }

  /// First time this book shows up on the page (suppressed while the page
  /// has no prior data at all, where everything would count as new).
  bool _isNewBook(Map<String, dynamic> book) {
    if (!_priorHadData) return false;
    final asin = book['asin'] as String? ?? '';
    return asin.isNotEmpty && !_priorSeenAsins.contains(asin);
  }

  /// Released after the previous scan's newest known release but not in the
  /// future - a surprise release found by a delayed recheck.
  bool _isNewSinceLastScan(Map<String, dynamic> book, DateTime? prevNewest) {
    if (prevNewest == null) return false;
    final date = DateTime.tryParse(book['releaseDate'] as String? ?? '');
    if (date == null) return false;
    final now = DateTime.now();
    if (date.isAfter(now)) return false;
    if (date.year > now.year + 5) return false;
    return date.isAfter(prevNewest);
  }

  /// Manually link a series to an Audible series ASIN, for series the
  /// resolver couldn't match (or matched wrongly). Clears the discovery
  /// state so the next check starts fresh with the given ASIN.
  Future<void> setSeriesAsin({
    required String seriesId,
    required String seriesName,
    required String asin,
  }) async {
    if (seriesId.isEmpty || asin.isEmpty) return;
    await _loadScanState();
    final entry = _scanState.putIfAbsent(
        seriesId, () => _SeriesScanEntry(name: seriesName));
    entry.name = seriesName;
    entry.asin = asin;
    entry.newestRelease = '';
    entry.lastChecked = 0;
    entry.missingComplete = false;
    entry.newestAtMissingCheck = '';
    _asinCache[seriesId] = asin;
    for (var i = 0; i < _persistedSkipped.length; i++) {
      if (_persistedSkipped[i].seriesId == seriesId) {
        _persistedSkipped[i] = SkippedSeries(
          seriesId: seriesId,
          seriesName: seriesName,
          audibleAsin: asin,
          newestRelease: '',
        );
      }
    }
    await _saveScanState();
    notifyListeners();
  }

  /// Rescan one series outside a full scan (from the skipped-series list).
  /// Replaces the series' entry in the results and refreshes its scan state.
  Future<SingleScanOutcome> scanSingleSeries({
    required ApiService api,
    required String libraryId,
    required String seriesId,
    required String seriesName,
  }) async {
    if (_isRunning) return SingleScanOutcome.failed;
    _generation++;
    final gen = _generation;
    _isDeepScan = false;
    await _loadScanState();
    await _loadIgnored();
    await _ensureOwnedIndex(api, libraryId, gen);
    _discoveryCache.clear();
    // Give unresolvable series another resolution attempt
    if (_asinCache[seriesId] == '') _asinCache.remove(seriesId);
    // NEW badges relative to what this series already shows
    _priorSeenAsins = {
      for (final r in _results.where((r) => r.seriesId == seriesId)) ...[
        ...r.upcomingBooks.map((b) => b['asin'] as String? ?? ''),
        ...r.recentBooks.map((b) => b['asin'] as String? ?? ''),
      ],
      for (final r in _missingResults.where((r) => r.seriesId == seriesId))
        ...r.missingBooks.map((b) => b['asin'] as String? ?? ''),
    }..remove('');
    _priorHadData = _priorSeenAsins.isNotEmpty;
    try {
      final result = await _discoverOne(api, libraryId, seriesId, seriesName, gen);
      if (_generation != gen) return SingleScanOutcome.failed;
      _results.removeWhere((r) => r.seriesId == seriesId);
      if (result != null) _results.add(result);
      _persistedSkipped.removeWhere((s) => s.seriesId == seriesId);
      if (!_isRunning) _isComplete = true;
      notifyListeners();
      await _saveCache();
      await _saveScanState();
      return result != null ? SingleScanOutcome.found : SingleScanOutcome.none;
    } catch (e) {
      debugPrint('[Upcoming] scanSingleSeries error: $e');
      return SingleScanOutcome.failed;
    }
  }

  /// Rescan a single book to refresh its release date and details.
  /// Returns the updated book data, or null on failure.
  ///
  /// When [api] + [libraryId] are provided, also searches the user's library
  /// for the book. If found, the book is removed from upcoming (since it's no
  /// longer missing) and marked as owned in the recent list.
  Future<Map<String, dynamic>?> rescanBook(
    String asin, {
    ApiService? api,
    String? libraryId,
  }) async {
    try {
      final details = await ApiService.getAudibleBookDetails(asin, region: _region);
      if (details == null) return null;

      final authors = (details['authors'] as List<dynamic>? ?? [])
          .map((a) => (a as Map<String, dynamic>)['name'] ?? '').join(', ');
      final narrators = (details['narrators'] as List<dynamic>? ?? [])
          .map((n) => (n as Map<String, dynamic>)['name'] ?? '').join(', ');
      final rating = details['rating'] as Map<String, dynamic>?;

      final updated = <String, dynamic>{
        'asin': asin,
        'title': details['title'] ?? '',
        'subtitle': details['subtitle'] ?? '',
        'authors': authors,
        'narrators': narrators,
        'releaseDate': details['release_date'] ?? '',
        'runtimeMinutes': details['runtime_length_min'] ?? 0,
        'rating': rating?['overall_distribution']?['display_average_rating'] ?? 0.0,
        'numRatings': rating?['overall_distribution']?['num_ratings'] ?? 0,
        'coverUrl': details['product_images']?['500'] ?? details['product_images']?['1024'] ?? '',
        'sequence': '',
        'sort': '0',
        'publisherSummary': details['publisher_summary'] ?? '',
      };

      // If the caller passed a library handle, check whether the book has
      // now been added to the user's library. A rescan that only refreshes
      // Audible metadata would still show the book as "missing" even after
      // the user added it - this closes that gap.
      bool ownedInLibrary = false;
      if (api != null && libraryId != null) {
        final title = updated['title'] as String? ?? '';
        if (title.isNotEmpty) {
          final search = await api.searchLibrary(libraryId, title, limit: 10);
          final ownedAsins = <String>{};
          final ownedTitles = <String>{};
          final books = (search?['book'] as List<dynamic>? ?? []);
          for (final b in books) {
            final libraryItem = (b as Map<String, dynamic>)['libraryItem'] as Map<String, dynamic>? ?? {};
            final media = libraryItem['media'] as Map<String, dynamic>? ?? {};
            final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
            ownedTitles.addAll(_titleVariants(metadata['title'] as String? ?? ''));
            final a = metadata['asin'] as String? ?? '';
            if (a.isNotEmpty) ownedAsins.add(a);
          }
          ownedInLibrary = _isOwnedBook(updated, ownedTitles, ownedAsins);
        }
      }

      // Update in results (check both upcoming and recent lists)
      for (final result in _results) {
        for (var i = 0; i < result.upcomingBooks.length; i++) {
          if (result.upcomingBooks[i]['asin'] == asin) {
            updated['sequence'] = result.upcomingBooks[i]['sequence'] ?? '';
            updated['sort'] = result.upcomingBooks[i]['sort'] ?? '0';
            updated['allAsins'] = result.upcomingBooks[i]['allAsins'] ?? <String>[asin];

            if (_isUpcoming(updated)) {
              result.upcomingBooks[i] = updated;
            } else {
              // Release date has passed. If it's already in the library
              // there's nothing to act on, so it just leaves the page;
              // otherwise it stays visible as Missing.
              result.upcomingBooks.removeAt(i);
              if (!ownedInLibrary) {
                updated['_owned'] = false;
                result.recentBooks.add(updated);
              }
            }
            break;
          }
        }
        for (var i = 0; i < result.recentBooks.length; i++) {
          if (result.recentBooks[i]['asin'] == asin) {
            if (ownedInLibrary) {
              result.recentBooks.removeAt(i);
            } else {
              updated['sequence'] = result.recentBooks[i]['sequence'] ?? '';
              updated['sort'] = result.recentBooks[i]['sort'] ?? '0';
              updated['allAsins'] = result.recentBooks[i]['allAsins'] ?? <String>[asin];
              updated['_owned'] = false;
              result.recentBooks[i] = updated;
            }
            break;
          }
        }
      }

      // A rescanned book that turned out to be in the library also clears
      // out of the deep-scan missing list.
      if (ownedInLibrary) {
        var missingChanged = false;
        for (final result in _missingResults) {
          final before = result.missingBooks.length;
          result.missingBooks.removeWhere((b) => b['asin'] == asin);
          if (result.missingBooks.length != before) missingChanged = true;
        }
        _missingResults.removeWhere((r) => r.missingBooks.isEmpty);
        if (missingChanged) await _saveMissingCache();
      }

      // Remove empty series results
      _results.removeWhere((r) => r.upcomingBooks.isEmpty && r.recentBooks.isEmpty);
      notifyListeners();
      await _saveCache();
      return updated;
    } catch (e) {
      debugPrint('[Upcoming] rescanBook error: $e');
      return null;
    }
  }

  /// Remove a book from the current results, whether it's upcoming, recent,
  /// owned or missing. Without [forever] this only edits the cached lists -
  /// a fresh scan re-discovers the book. With [forever] the book also goes
  /// on the ignore list, so scans skip it until it is restored.
  Future<void> removeBook(String asin, {bool forever = false}) async {
    if (asin.isEmpty) return;

    // Capture the book with its series context before removal so a
    // forever-removal can be restored later.
    IgnoredBook? captured;
    for (final result in _results) {
      for (final b in result.upcomingBooks) {
        if (b['asin'] == asin) {
          captured = IgnoredBook(
            book: Map<String, dynamic>.from(b),
            seriesId: result.seriesId,
            seriesName: result.seriesName,
            audibleAsin: result.audibleAsin,
            from: 'upcoming',
            removedAtMs: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
      for (final b in result.recentBooks) {
        if (b['asin'] == asin) {
          captured ??= IgnoredBook(
            book: Map<String, dynamic>.from(b),
            seriesId: result.seriesId,
            seriesName: result.seriesName,
            audibleAsin: result.audibleAsin,
            from: 'recent',
            removedAtMs: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
      result.upcomingBooks.removeWhere((b) => b['asin'] == asin);
      result.recentBooks.removeWhere((b) => b['asin'] == asin);
    }
    _results.removeWhere((r) => r.upcomingBooks.isEmpty && r.recentBooks.isEmpty);
    var missingChanged = false;
    for (final result in _missingResults) {
      for (final b in result.missingBooks) {
        if (b['asin'] == asin) {
          captured ??= IgnoredBook(
            book: Map<String, dynamic>.from(b),
            seriesId: result.seriesId,
            seriesName: result.seriesName,
            audibleAsin: result.audibleAsin,
            from: 'missing',
            removedAtMs: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
      final before = result.missingBooks.length;
      result.missingBooks.removeWhere((b) => b['asin'] == asin);
      if (result.missingBooks.length != before) missingChanged = true;
    }
    _missingResults.removeWhere((r) => r.missingBooks.isEmpty);

    if (forever && captured != null && !_ignoredAsins.contains(asin)) {
      await _loadIgnored();
      _ignoredBooks.add(captured);
      _ignoredAsins.add(asin);
      await _saveIgnored();
    }

    notifyListeners();
    await _saveCache();
    if (missingChanged) await _saveMissingCache();
  }

  /// Take a book off the ignore list. Returns true when it could be put
  /// straight back on the page; false means it will reappear on a future
  /// scan instead (e.g. a removed upcoming book that has since released).
  Future<bool> restoreBook(String asin) async {
    await _loadIgnored();
    final idx = _ignoredBooks.indexWhere((b) => b.asin == asin);
    if (idx < 0) return false;
    final entry = _ignoredBooks.removeAt(idx);
    _ignoredAsins.remove(asin);
    await _saveIgnored();

    var visible = false;
    if (entry.from == 'missing') {
      MissingSeriesResult? bucket;
      for (final r in _missingResults) {
        if (r.seriesId == entry.seriesId || r.seriesName == entry.seriesName) {
          bucket = r;
          break;
        }
      }
      if (bucket == null) {
        bucket = MissingSeriesResult(
          seriesId: entry.seriesId,
          seriesName: entry.seriesName,
          audibleAsin: entry.audibleAsin,
          missingBooks: [],
        );
        _missingResults.add(bucket);
      }
      bucket.missingBooks.add(Map<String, dynamic>.from(entry.book));
      await _saveMissingCache();
      visible = true;
    } else {
      visible = await addBook(
        entry.book,
        seriesName: entry.seriesName,
        audibleAsin: entry.audibleAsin,
        region: _region,
      );
    }
    notifyListeners();
    return visible;
  }

  /// Manually add a single discovered Audible book to the upcoming page,
  /// grouping it under [seriesName] / [audibleAsin]. Lets the user surface a
  /// freshly-added series' release without rescanning the whole library.
  ///
  /// Only upcoming or recently-released (last 30 days) books are accepted -
  /// anything else doesn't belong on this page. Returns true if added, false
  /// if the book is already present or not eligible.
  Future<bool> addBook(
    Map<String, dynamic> book, {
    required String seriesName,
    required String audibleAsin,
    required String region,
    bool owned = false,
  }) async {
    final asin = book['asin'] as String? ?? '';
    if (asin.isEmpty) return false;

    // An explicit add overrides an earlier forever-removal
    await _loadIgnored();
    if (_ignoredAsins.remove(asin)) {
      _ignoredBooks.removeWhere((b) => b.asin == asin);
      await _saveIgnored();
    }

    final upcoming = _isUpcoming(book);
    final recent = !upcoming && _isRecentRelease(book);
    if (!upcoming && !recent) return false;

    // If the upcoming page hasn't been opened this session our in-memory list
    // is empty even though a previous scan sits on disk. Load it first so we
    // append to the existing set instead of clobbering it on the next save.
    if (_results.isEmpty && !_isRunning) {
      _region = region;
      await loadCache();
    }

    // Skip if the book is already on the page anywhere.
    for (final r in _results) {
      if (r.upcomingBooks.any((b) => b['asin'] == asin) ||
          r.recentBooks.any((b) => b['asin'] == asin)) {
        return false;
      }
    }

    // Reuse this series' bucket if it's already on the page, else start one.
    UpcomingSeriesResult? target;
    for (final r in _results) {
      if ((audibleAsin.isNotEmpty && r.audibleAsin == audibleAsin) ||
          r.seriesName == seriesName) {
        target = r;
        break;
      }
    }
    if (target == null) {
      target = UpcomingSeriesResult(
        seriesId: '',
        seriesName: seriesName,
        audibleAsin: audibleAsin,
        upcomingBooks: [],
        recentBooks: [],
      );
      _results.add(target);
    }

    if (upcoming) {
      target.upcomingBooks.add(Map<String, dynamic>.from(book));
    } else {
      target.recentBooks.add({...book, '_owned': owned});
    }

    // A manually added upcoming book means the series is active again - raise
    // the remembered newest release so full scans stop skipping it.
    if (upcoming && audibleAsin.isNotEmpty) {
      await _loadScanState();
      for (final entry in _scanState.values) {
        if (entry.asin != audibleAsin) continue;
        final added = DateTime.tryParse(book['releaseDate'] as String? ?? '');
        final current = DateTime.tryParse(entry.newestRelease);
        if (added != null && (current == null || added.isAfter(current))) {
          entry.newestRelease = book['releaseDate'] as String? ?? '';
          await _saveScanState();
        }
        break;
      }
    }

    if (!_isRunning) _isComplete = true;
    notifyListeners();
    await _saveCache();
    return true;
  }

  /// Try to find the Audible series ASIN from the books' metadata ASINs via Audnexus.
  /// Only checks up to [_maxAsinAttempts] books to avoid excessive API calls on huge series.
  static const _maxAsinAttempts = 5;

  /// The bool says whether the resolution genuinely concluded: true when
  /// Audnexus answered (even with no series info) or there was nothing to
  /// try, false when every attempt died on a network error - only a
  /// concluded "no match" may be remembered as unresolvable.
  Future<(String?, bool)> _resolveSeriesAsin(List<dynamic> books, String seriesName, int gen) async {
    int audnexusAttempts = 0;
    var concluded = true;
    for (final book in books) {
      if (_generation != gen) return (null, false);
      if (book is! Map<String, dynamic>) continue;

      final media = book['media'] as Map<String, dynamic>? ?? {};
      final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
      final bookAsin = metadata['asin'] as String? ?? '';
      if (bookAsin.isEmpty) continue;
      if (audnexusAttempts >= _maxAsinAttempts) break;
      audnexusAttempts++;

      var answered = false;
      for (var attempt = 0; attempt < 3; attempt++) {
        if (_generation != gen) return (null, false);
        try {
          final audnexus = await ApiService.getAudnexusBook(bookAsin, region: _region);
          if (_generation != gen) return (null, false);
          answered = true;
          if (audnexus == null) break; // not on Audnexus, no point retrying

          final primary = audnexus['seriesPrimary'] as Map<String, dynamic>?;
          if (primary != null && primary['asin'] != null) {
            return (primary['asin'] as String, true);
          }
          final secondary = audnexus['seriesSecondary'] as Map<String, dynamic>?;
          if (secondary != null && secondary['asin'] != null) {
            return (secondary['asin'] as String, true);
          }
          break; // valid response but no series info, no point retrying
        } catch (e) {
          if (attempt < 2) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
      if (!answered) concluded = false;
    }
    return (null, concluded);
  }

  bool _isUpcoming(Map<String, dynamic> book) {
    final dateStr = book['releaseDate'] as String? ?? '';
    if (dateStr.isEmpty) return false;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    final now = DateTime.now();
    if (date.year > now.year + 5) return false;
    return date.isAfter(now);
  }

  /// Check if a book was released within the last 30 days.
  bool _isRecentRelease(Map<String, dynamic> book) {
    final dateStr = book['releaseDate'] as String? ?? '';
    if (dateStr.isEmpty) return false;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    final now = DateTime.now();
    if (date.isAfter(now)) return false; // upcoming, not recent
    return now.difference(date).inDays <= 30;
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

  /// First author only - both sides join multiple authors with ', '.
  String _normalizeAuthor(String authors) => _normalizeTitle(authors.split(',').first);

  /// Normalized matching variants for a library title: the full title plus
  /// the part before a colon. Libraries often bake the subtitle into the
  /// title ("Not Till We Are Lost: Bobiverse, Book 5") while Audible keeps
  /// title and subtitle separate.
  List<String> _titleVariants(String title) {
    final variants = <String>[];
    final full = _normalizeTitle(title);
    if (full.isNotEmpty) variants.add(full);
    final colon = title.indexOf(':');
    if (colon > 0) {
      final head = _normalizeTitle(title.substring(0, colon));
      if (head.isNotEmpty && head != full) variants.add(head);
    }
    return variants;
  }

  /// Check if a discovered Audible book is owned in the library.
  /// [ownedTitles] holds NORMALIZED title variants (see [_titleVariants])
  /// from the series' own books; the library-wide index catches books owned
  /// outside that series bucket. Besides the plain title, the title+subtitle
  /// concatenation is tried, in case the library baked the subtitle in.
  bool _isOwnedBook(Map<String, dynamic> book, Set<String> ownedTitles, Set<String> ownedAsins) {
    final asin = book['asin'] as String? ?? '';
    if (asin.isNotEmpty &&
        (ownedAsins.contains(asin) || _libraryOwnedAsins.contains(asin))) {
      return true;
    }
    final allAsins = book['allAsins'] as List<dynamic>? ?? [];
    for (final a in allAsins) {
      if (ownedAsins.contains(a) || _libraryOwnedAsins.contains(a)) return true;
    }
    final title = _normalizeTitle(book['title'] as String? ?? '');
    if (title.isEmpty) return false;
    final subtitle = book['subtitle'] as String? ?? '';
    final withSub =
        subtitle.isEmpty ? '' : _normalizeTitle('${book['title']} $subtitle');
    if (ownedTitles.contains(title)) return true;
    if (withSub.isNotEmpty && ownedTitles.contains(withSub)) return true;
    final author = _normalizeAuthor(book['authors'] as String? ?? '');
    if (author.isNotEmpty) {
      if (_libraryOwnedTitleAuthor.contains('$title|$author')) return true;
      if (withSub.isNotEmpty &&
          _libraryOwnedTitleAuthor.contains('$withSub|$author')) {
        return true;
      }
    }
    return false;
  }

  /// Cancel the current scan.
  void cancel() {
    _generation++;
    _isRunning = false;
    _currentSeriesName = null;
    _cancelScanNotification();
    notifyListeners();
  }

  /// Set region (for cache loading before scan). A region change throws away
  /// the remembered scan knowledge - ASINs and dates are region-specific.
  void setRegion(String region) {
    if (region == _region) return;
    _region = region;
    _resetScanKnowledge();
  }

  // ─── Foreground Service / Notifications ──────────────────────

  bool _foregroundActive = false;

  Future<void> _showScanNotification(String body) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidPlugin = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            _notifChannelId,
            _notifChannelName,
            description: _notifChannelDesc,
            importance: Importance.low,
            showBadge: false,
          ),
        );
      }

      final progress = _totalSeries > 0 ? _processedCount : 0;
      final max = _totalSeries > 0 ? _totalSeries : 0;

      final androidDetails = AndroidNotificationDetails(
        _notifChannelId,
        _notifChannelName,
        channelDescription: _notifChannelDesc,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        icon: 'drawable/ic_notification',
      );

      final scanTitle = _l()?.upcomingNotifScanTitle ?? 'Scanning for upcoming releases';

      // Start as foreground service on first call so the scan survives
      // the app being sent to the background.
      if (!_foregroundActive && androidPlugin != null) {
        try {
          await androidPlugin.startForegroundService(
            _scanNotifId,
            scanTitle,
            body,
            notificationDetails: androidDetails,
            payload: 'upcoming_scan',
          );
          _foregroundActive = true;
          debugPrint('[Upcoming] Foreground service started');
          return;
        } catch (e) {
          debugPrint('[Upcoming] Foreground service failed, falling back: $e');
        }
      }

      await plugin.show(
        _scanNotifId,
        scanTitle,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notifChannelId,
            _notifChannelName,
            channelDescription: _notifChannelDesc,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            showProgress: max > 0,
            maxProgress: max,
            progress: progress,
            icon: 'drawable/ic_notification',
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Upcoming] notification error: $e');
    }
  }

  Future<void> _cancelScanNotification() async {
    try {
      if (_foregroundActive) {
        final androidPlugin = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.stopForegroundService();
          debugPrint('[Upcoming] Foreground service stopped');
        }
        _foregroundActive = false;
      }
      await FlutterLocalNotificationsPlugin().cancel(_scanNotifId);
    } catch (_) {}
  }

  Future<void> _showCompleteNotification() async {
    try {
      final totalBooks = _results.fold<int>(0, (sum, r) => sum + r.upcomingBooks.length);
      if (totalBooks == 0) return;

      final plugin = FlutterLocalNotificationsPlugin();
      final androidPlugin = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            _notifChannelId,
            _notifChannelName,
            description: _notifChannelDesc,
            importance: Importance.defaultImportance,
          ),
        );
      }

      final seriesCount = _results.length;
      final l = _l();
      await plugin.show(
        _completeNotifId,
        l?.upcomingNotifFoundTitle ?? 'Upcoming releases found!',
        l?.upcomingNotifFoundBody(totalBooks, seriesCount)
            ?? '$totalBooks upcoming across $seriesCount series',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notifChannelId,
            _notifChannelName,
            channelDescription: _notifChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'drawable/ic_notification',
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Upcoming] complete notification error: $e');
    }
  }
}
