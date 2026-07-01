import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:background_downloader/background_downloader.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import 'api_service.dart';
import 'audio_player_service.dart';
import 'ebook_cache.dart';
import 'offline_source.dart';

enum DownloadStatus { none, downloading, downloaded, error }

class DownloadInfo {
  final String itemId;
  final DownloadStatus status;
  final double progress;
  final List<String> localPaths;
  final String? sessionData;
  // Metadata for offline display
  final String? title;
  final String? author;
  final String? coverUrl;
  final String? localCoverPath;
  final String? localDirPath;
  final String? libraryId;

  DownloadInfo({
    required this.itemId,
    this.status = DownloadStatus.none,
    this.progress = 0,
    this.localPaths = const [],
    this.sessionData,
    this.title,
    this.author,
    this.coverUrl,
    this.localCoverPath,
    this.localDirPath,
    this.libraryId,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'status': status.index,
    'localPaths': localPaths,
    'sessionData': sessionData,
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'localCoverPath': localCoverPath,
    if (localDirPath != null) 'localDirPath': localDirPath,
    if (libraryId != null) 'libraryId': libraryId,
  };

  factory DownloadInfo.fromJson(Map<String, dynamic> json) {
    String? title = json['title'] as String?;
    String? author = json['author'] as String?;
    String? coverUrl = json['coverUrl'] as String?;

    // Fallback: extract metadata from cached sessionData for old downloads
    if ((title == null || title.isEmpty) && json['sessionData'] != null) {
      try {
        final session = jsonDecode(json['sessionData'] as String) as Map<String, dynamic>;
        // Try session-level metadata first
        final sessionMeta = session['mediaMetadata'] as Map<String, dynamic>?;
        if (sessionMeta != null) {
          title ??= sessionMeta['title'] as String?;
          author ??= sessionMeta['authorName'] as String?;
        }
        // Try libraryItem path
        if (title == null || title.isEmpty) {
          final libItem = session['libraryItem'] as Map<String, dynamic>? ?? {};
          final media = libItem['media'] as Map<String, dynamic>? ?? {};
          final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
          title ??= metadata['title'] as String?;
          author ??= metadata['authorName'] as String?;
        }
        // Try direct displayTitle/displayAuthor
        title ??= session['displayTitle'] as String?;
        author ??= session['displayAuthor'] as String?;
      } catch (_) {}
    }

    return DownloadInfo(
      itemId: json['itemId'] as String,
      status: DownloadStatus.values[json['status'] as int? ?? 0],
      localPaths: (json['localPaths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sessionData: _stripLibraryItem(json['sessionData'] as String?),
      title: title,
      author: author,
      coverUrl: coverUrl,
      localCoverPath: json['localCoverPath'] as String?,
      localDirPath: json['localDirPath'] as String?,
      libraryId: json['libraryId'] as String?,
    );
  }
}

class _QueuedDownload {
  final ApiService api;
  final String itemId;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? episodeId;
  final String? libraryId;

  _QueuedDownload({required this.api, required this.itemId, required this.title, this.author, this.coverUrl, this.episodeId, this.libraryId});
}

/// An in-flight multi-file download. The static fields (persisted to
/// SharedPreferences) carry everything needed to finalize the book even if the
/// app is killed and relaunched while the OS finishes the transfer. The runtime
/// maps are rebuilt from the background_downloader task database on relaunch.
class _PendingBook {
  final String itemId; // composite key used in _downloads
  final String apiItemId; // real library item id for API calls
  final String? episodeId;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? localCoverPath;
  final String? libraryId;
  final String bookDir;
  final int trackCount;
  final List<String> expectedPaths; // index-aligned final file paths
  final String? slimSessionJson;

  /// When set, this book downloads to internal storage first, then its files
  /// are moved into the user's SAF folder ([safTreeUri]) under [safSubfolder]
  /// (e.g. "Author/Title") on completion. Null for internal / iOS downloads.
  final String? safTreeUri;
  final String? safSubfolder;

  /// True once the user cancels, so terminal handling cleans up instead of
  /// surfacing an error.
  bool cancelled = false;

  /// Set synchronously the moment a terminal handler (success/fail/cancel) is
  /// chosen, so a burst of terminal updates can't finalize the book twice.
  bool finalizing = false;

  /// A hard track failure aborts the whole book; remember why for the message.
  bool failing = false;
  TaskException? failException;
  int? failCode;

  final Map<int, double> trackProgress = {};
  final Map<int, TaskStatus> trackStatus = {};
  DateTime lastUi = DateTime.fromMillisecondsSinceEpoch(0);

  /// Last time any track update arrived, so the slot-leak reconciler can spot a
  /// book whose terminal updates were missed.
  DateTime lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  /// True when this book's files get moved into a SAF folder on completion.
  bool get isSaf => safTreeUri != null;

  _PendingBook({
    required this.itemId,
    required this.apiItemId,
    required this.title,
    required this.bookDir,
    required this.trackCount,
    required this.expectedPaths,
    this.episodeId,
    this.author,
    this.coverUrl,
    this.localCoverPath,
    this.libraryId,
    this.slimSessionJson,
    this.safTreeUri,
    this.safSubfolder,
  }) {
    // Start the no-progress watchdog clock at creation (fresh or restored).
    lastUpdate = DateTime.now();
  }

  double get overallProgress {
    if (trackCount == 0) return 0;
    var sum = 0.0;
    for (int i = 0; i < trackCount; i++) {
      sum += trackProgress[i] ?? 0.0;
    }
    return (sum / trackCount).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'apiItemId': apiItemId,
    'episodeId': episodeId,
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'localCoverPath': localCoverPath,
    'libraryId': libraryId,
    'bookDir': bookDir,
    'trackCount': trackCount,
    'expectedPaths': expectedPaths,
    'slimSessionJson': slimSessionJson,
    if (safTreeUri != null) 'safTreeUri': safTreeUri,
    if (safSubfolder != null) 'safSubfolder': safSubfolder,
  };

  factory _PendingBook.fromJson(Map<String, dynamic> j) => _PendingBook(
    itemId: j['itemId'] as String,
    apiItemId: j['apiItemId'] as String,
    episodeId: j['episodeId'] as String?,
    title: j['title'] as String? ?? '',
    author: j['author'] as String?,
    coverUrl: j['coverUrl'] as String?,
    localCoverPath: j['localCoverPath'] as String?,
    libraryId: j['libraryId'] as String?,
    bookDir: j['bookDir'] as String,
    trackCount: j['trackCount'] as int? ?? 0,
    expectedPaths: (j['expectedPaths'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    slimSessionJson: j['slimSessionJson'] as String?,
    safTreeUri: j['safTreeUri'] as String?,
    safSubfolder: j['safSubfolder'] as String?,
  );
}

/// Trim the bulky parts of the persisted `libraryItem` while keeping the bits
/// offline features need. Drops `media.episodes` (a podcast's full episode list
/// is hundreds of KB) and `media.audioFiles` (the server file list, unused for
/// local playback), but KEEPS `media.metadata` (so offline series auto-advance
/// still knows the book's series + sequence), `duration`, and `chapters` (so the
/// now-playing UI is correct).
String? _stripLibraryItem(String? sessionJson) {
  if (sessionJson == null) return null;
  try {
    final session = jsonDecode(sessionJson) as Map<String, dynamic>;
    final libItem = session['libraryItem'] as Map<String, dynamic>?;
    if (libItem == null) return sessionJson;
    final media = libItem['media'] as Map<String, dynamic>?;
    if (media != null) {
      media.remove('episodes');
      media.remove('audioFiles');
    }
    return jsonEncode(session);
  } catch (_) {}
  return sessionJson;
}

/// Sanitize a string for use as a filesystem directory/file name.
String _sanitizePath(String name) {
  // Replace filesystem-illegal characters with underscore
  var s = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  // Collapse multiple underscores/spaces
  s = s.replaceAll(RegExp(r'[_\s]+'), ' ').trim();
  // Fallback for empty result
  if (s.isEmpty) s = 'Unknown';
  // Limit length to avoid filesystem issues
  if (s.length > 100) s = s.substring(0, 100).trim();
  return s;
}

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._();
  factory DownloadService() => _instance;
  DownloadService._();

  final Map<String, DownloadInfo> _downloads = {};
  final Set<String> _activeDownloadIds = {};
  final Set<String> _cancelledIds = {};

  /// SAF tree URI (content://) for the Android custom download folder, or null
  /// to use internal storage. This is the only custom-location mechanism now;
  /// the old raw-path approach (MANAGE_EXTERNAL_STORAGE) is gone.
  String? _customDownloadUri;

  /// Downloaded items still pointing at raw external paths from before the SAF
  /// switch. Unreadable without the dropped storage permission, so they're kept
  /// listed for the user to re-download rather than silently deleted.
  final Set<String> _legacyExternalIds = {};

  /// All `background_downloader` tasks share this group, so a single grouped
  /// progress notification covers every active download.
  static const String _dlGroup = 'absorb_downloads';

  /// In-flight books keyed by itemId. Holds everything needed to aggregate
  /// per-track progress and finalize the book, including after an app relaunch.
  final Map<String, _PendingBook> _pending = {};

  StreamSubscription<TaskUpdate>? _updatesSub;
  bool _downloaderConfigured = false;

  /// Periodically reconverges in-flight books with the package task DB so a
  /// missed terminal update can't leave a slot leaked and wedge the queue.
  Timer? _reconcileTimer;

  /// Queue of pending download requests.
  final List<_QueuedDownload> _queue = [];

  /// The current Android SAF folder URI (content://), or null if using default.
  String? get customDownloadUri => _customDownloadUri;

  /// Items left pointing at unreadable raw external paths from before SAF.
  List<DownloadInfo> get legacyExternalDownloads => _legacyExternalIds.map((id) => _downloads[id]).whereType<DownloadInfo>().toList();

  /// Get the effective default (non-custom) download base directory.
  ///
  /// Android custom folders no longer use a filesystem base path - they go
  /// through SAF ([_customDownloadUri]) in the task builder. This getter now
  /// only resolves the built-in location: the iOS app group container (so the
  /// widget extension and native player core can read it; falls back to
  /// Documents/ if the app group lookup fails) or Android internal storage.
  Future<String> get downloadBasePath async {
    if (Platform.isIOS) {
      final groupPath = await _iosAppGroupAudioBase();
      if (groupPath != null) return groupPath;
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/downloads';
  }

  /// Always returns the internal app directory for cover caching.
  /// Covers are stored here even when audio uses a custom external path,
  /// because external storage may have permission restrictions.
  Future<String> get _internalBasePath async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/downloads';
  }

  /// Set the Android SAF custom download folder. Pass null to revert to default.
  Future<void> setCustomDownloadUri(Uri? uri) async {
    _customDownloadUri = uri?.toString();
    final prefs = await SharedPreferences.getInstance();
    if (_customDownloadUri != null && _customDownloadUri!.isNotEmpty) {
      await prefs.setString('custom_download_uri', _customDownloadUri!);
    } else {
      await prefs.remove('custom_download_uri');
    }
    notifyListeners();
  }

  /// Get a human-readable label for the current download location.
  Future<String> get downloadLocationLabel async {
    final uri = _customDownloadUri;
    if (uri != null && uri.isNotEmpty) return _friendlySafLabel(uri);
    return 'App Internal Storage (Default)';
  }

  /// Turn a SAF tree URI into a friendly folder name. Tree URIs encode the
  /// location in their last path segment, e.g.
  /// `.../tree/primary%3ADownload%2FAudiobooks` -> `Download/Audiobooks`.
  String _friendlySafLabel(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      var docId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uriString;
      docId = Uri.decodeComponent(docId);
      final colon = docId.indexOf(':');
      final rel = colon >= 0 ? docId.substring(colon + 1) : docId;
      return rel.isEmpty ? docId : rel;
    } catch (_) {
      return uriString;
    }
  }

  /// Calculate total size of all downloaded files.
  Future<int> get totalDownloadSize async {
    int total = 0;
    for (final info in _downloads.values) {
      if (info.status == DownloadStatus.downloaded) {
        for (final path in info.localPaths) {
          if (isContentUri(path)) continue; // SAF audio not counted in the tally
          try {
            final file = File(path);
            if (file.existsSync()) {
              total += file.lengthSync();
            }
          } catch (_) {}
        }
      }
    }
    return total;
  }

  /// Calculate total file size for a single download item.
  int getItemFileSize(String itemId) {
    final info = _downloads[itemId];
    if (info == null || info.status != DownloadStatus.downloaded) return 0;
    int total = 0;
    for (final path in info.localPaths) {
      if (isContentUri(path)) continue; // SAF audio not counted in the tally
      try {
        final file = File(path);
        if (file.existsSync()) {
          total += file.lengthSync();
        }
      } catch (_) {}
    }
    return total;
  }

  static const _storageChannel = MethodChannel('com.absorb.storage');
  static const _widgetChannel = MethodChannel('com.absorb.widget');

  /// Cached iOS app group container path. Populated lazily by
  /// [_iosAppGroupAudioBase] and cleared if the lookup fails so we retry
  /// (the app group entitlement may roll in mid-session).
  String? _iosAppGroupContainerPath;

  /// Stops iCloud from backing up an audio file. Audiobooks are large and
  /// re-downloadable from the user's ABS server, so eating their iCloud
  /// quota would only cause problems (system backup breaks once quota is
  /// hit). iOS-only no-op elsewhere.
  Future<void> _excludeFromBackup(String path) async {
    if (!Platform.isIOS) return;
    try {
      await _widgetChannel.invokeMethod<bool>('excludeFromBackup', {'path': path});
    } catch (e) {
      debugPrint('[Download] excludeFromBackup failed for $path: $e');
    }
  }

  /// Returns the iOS app group's audio directory (`<group>/audio/downloads`),
  /// or null on Android / when the app group entitlement isn't available.
  /// Audio downloads live here so the native player core can read them
  /// from the widget extension (the widget can't reach Documents/).
  Future<String?> _iosAppGroupAudioBase() async {
    if (!Platform.isIOS) return null;
    var groupPath = _iosAppGroupContainerPath;
    if (groupPath == null) {
      try {
        groupPath = await _widgetChannel.invokeMethod<String>('getGroupContainerPath');
      } catch (e) {
        debugPrint('[Download] getGroupContainerPath failed: $e');
        return null;
      }
      if (groupPath == null || groupPath.isEmpty) return null;
      _iosAppGroupContainerPath = groupPath;
    }
    final dir = Directory('$groupPath/audio/downloads');
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (e) {
        debugPrint('[Download] create app group audio dir failed: $e');
        return null;
      }
    }
    return dir.path;
  }

  /// Get device storage info: {totalBytes, availableBytes}. Returns null on failure.
  static Future<Map<String, int>?> getDeviceStorage() async {
    try {
      final result = await _storageChannel.invokeMethod('getDeviceStorage');
      if (result is Map) {
        return {'totalBytes': (result['totalBytes'] as num).toInt(), 'availableBytes': (result['availableBytes'] as num).toInt()};
      }
    } catch (e) {
      debugPrint('[Download] getDeviceStorage error: $e');
    }
    return null;
  }

  DownloadInfo getInfo(String itemId) => _downloads[itemId] ?? DownloadInfo(itemId: itemId);

  bool isDownloaded(String itemId) => _downloads[itemId]?.status == DownloadStatus.downloaded;

  /// Registers an ebook-only book as a completed download so it shows in the
  /// offline library and its detail sheet loads offline. There's no audio, so
  /// localPaths is empty - the book opens in the reader, never the player. The
  /// ebook bytes live in the reader's persistent cache (fetchEbookToCache).
  /// Fetches a full copy of the item so the offline sheet has the cover,
  /// description, and ebookFile - not just the title.
  Future<void> registerEbookDownload({required ApiService api, required String itemId, Map<String, dynamic>? item, String? libraryId}) async {
    Map<String, dynamic>? fullItem;
    try {
      fullItem = await api.getLibraryItem(itemId);
    } catch (_) {}
    final stored = fullItem ?? item ?? {'id': itemId};
    final media = stored['media'] as Map<String, dynamic>?;
    final metadata = media?['metadata'] as Map<String, dynamic>?;
    final title = metadata?['title'] as String?;
    final author = metadata?['authorName'] as String?;

    final localCoverPath = await _cacheCover(api, itemId, api.getCoverUrl(itemId, width: 800));
    final sessionJson = jsonEncode({'libraryItem': stored, 'mediaMetadata': metadata, 'duration': 0, 'chapters': const <dynamic>[]});
    _downloads[itemId] = DownloadInfo(
      itemId: itemId,
      status: DownloadStatus.downloaded,
      localPaths: const [],
      sessionData: sessionJson,
      title: title,
      author: author,
      localCoverPath: localCoverPath,
      libraryId: libraryId ?? stored['libraryId'] as String?,
    );
    await _save();
    notifyListeners();
  }

  bool isDownloading(String itemId) => _downloads[itemId]?.status == DownloadStatus.downloading;

  double downloadProgress(String itemId) => _downloads[itemId]?.progress ?? 0;

  /// Get all downloaded items (for home screen display).
  List<DownloadInfo> get downloadedItems => _downloads.values.where((d) => d.status == DownloadStatus.downloaded).toList();

  /// Get actively downloading items (in progress right now).
  List<DownloadInfo> get activeDownloads => _downloads.values.where((d) => d.status == DownloadStatus.downloading && _activeDownloadIds.contains(d.itemId)).toList();

  /// Get queued items (waiting for a download slot).
  List<DownloadInfo> get queuedDownloads => _queue.map((q) => _downloads[q.itemId]).whereType<DownloadInfo>().toList();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customDownloadUri = prefs.getString('custom_download_uri');
    // Legacy raw-path custom folders can't be converted to a SAF content URI
    // without a fresh user pick, and we no longer hold the storage permission
    // to write them. Drop the old setting so new downloads use SAF or internal.
    if (prefs.getString('custom_download_path') != null) {
      await prefs.remove('custom_download_path');
    }
    final json = prefs.getString('downloads');
    if (json != null) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        for (final entry in map.entries) {
          final info = DownloadInfo.fromJson(entry.value as Map<String, dynamic>);
          debugPrint(
            '[Download] Loaded: ${entry.key} '
            'title="${info.title}" author="${info.author}" '
            'cover=${info.coverUrl != null ? "yes" : "null"} '
            'sessionData=${info.sessionData != null ? "${info.sessionData!.length} chars" : "null"}',
          );
          if (info.status == DownloadStatus.downloaded) {
            _downloads[entry.key] = info;
          } else {
            debugPrint('[Download] Skipping stale ${info.status} entry: ${entry.key}');
          }
        }
      } catch (e) {
        debugPrint('[Download] Init error: $e');
      }
    }
    // On iOS, remap paths when the app container UUID changes after updates
    await _migrateIOSPaths();

    // On Android, flag downloads still pointing at raw external paths from
    // before the SAF switch so the UI can offer a re-download.
    await _detectLegacyExternal();

    // On iOS, move existing audio downloads from Documents/ into the app
    // group container so the widget / native player core can read them.
    // Runs in background so it doesn't block init() if the user has many
    // gigabytes of downloaded books to relocate.
    if (Platform.isIOS) {
      unawaited(_migrateIOSAudioToAppGroup());
    }

    // Re-save to persist any metadata extracted from sessionData
    if (_downloads.isNotEmpty) await _save();

    // Wire up native background downloads: configure the grouped notification,
    // start tracking tasks (so they persist across launches), listen for
    // updates, then rehydrate any download that was in flight when we were last
    // killed and ask the OS to redeliver completions that landed while dead.
    await _configureDownloader();
    _updatesSub ??= FileDownloader().updates.listen(_onTaskUpdate);
    await FileDownloader().trackTasks();
    await _loadPending();
    await _rehydratePending();
    await FileDownloader().resumeFromBackground();
    _startReconciler();

    notifyListeners();

    // Validate files and clean up orphans in background after startup
    _validateDownloads();
  }

  void _startReconciler() {
    _reconcileTimer?.cancel();
    _reconcileTimer = Timer.periodic(const Duration(minutes: 2), (_) => unawaited(_reconcilePending()));
  }

  /// Reconcile in-flight books against the package task DB. Two jobs:
  /// 1. If a book's terminal updates were missed (e.g. an OEM ROM killed our
  ///    callback), finalize / fail it from the DB so its slot frees.
  /// 2. If a book has made no progress and gone silent for a while, it's a dead
  ///    or zombie record (e.g. left over after an app update) holding a slot -
  ///    fail it so the queue can move on. Healthy or wifi-waiting downloads keep
  ///    emitting updates, so their lastUpdate stays fresh and they're left be.
  Future<void> _reconcilePending() async {
    if (_pending.isEmpty) return;
    List<TaskRecord> records;
    try {
      records = await FileDownloader().database.allRecords();
    } catch (_) {
      return;
    }
    final byItem = <String, Map<int, TaskStatus>>{};
    for (final r in records) {
      final meta = _decodeMeta(r.task.metaData);
      if (meta == null) continue;
      if (!_pending.containsKey(meta.$1)) continue;
      (byItem[meta.$1] ??= {})[meta.$2] = r.status;
    }
    for (final itemId in _pending.keys.toList()) {
      final p = _pending[itemId];
      if (p == null || p.finalizing) continue;
      final statuses = byItem[itemId];
      if (statuses != null && statuses.length >= p.trackCount) {
        statuses.forEach((i, s) => p.trackStatus[i] = s);
        bool allComplete = p.trackCount > 0;
        bool allTerminal = true;
        for (int i = 0; i < p.trackCount; i++) {
          final s = p.trackStatus[i];
          if (s != TaskStatus.complete) allComplete = false;
          if (s == null || !_terminal.contains(s)) allTerminal = false;
        }
        if (allComplete) {
          debugPrint('[Download] Reconciler finalizing missed-complete $itemId');
          p.finalizing = true;
          await _finalizeSuccess(itemId);
          continue;
        }
        if (allTerminal) {
          debugPrint('[Download] Reconciler failing stalled $itemId');
          p.finalizing = true;
          await _failBook(itemId, cause: 'Interrupted download');
          continue;
        }
      }
      // No progress and no updates for a while: a dead/zombie slot. Fail it.
      if (p.overallProgress == 0 && DateTime.now().difference(p.lastUpdate) > const Duration(minutes: 3)) {
        debugPrint('[Download] Reconciler failing stale $itemId (no progress)');
        p.finalizing = true;
        await _failBook(itemId, cause: 'Interrupted download');
      }
    }
  }

  /// Configure the single grouped download notification (replaces the old
  /// per-slot notifications + hand-rolled Android foreground service). The
  /// package runs a background URLSession on iOS and a foreground service on
  /// Android, so downloads continue when backgrounded, locked, or killed.
  Future<void> _configureDownloader() async {
    if (_downloaderConfigured) return;
    // Always run downloads in the Android foreground service. Without this,
    // smaller books can run as background WorkManager jobs that some OEM ROMs
    // throttle or kill, leaving downloads stuck.
    if (Platform.isAndroid) {
      try {
        await FileDownloader().configure(androidConfig: [(Config.runInForeground, Config.always)]);
      } catch (e) {
        debugPrint('[Download] androidConfig failed: $e');
      }
    }
    final l = _l();
    // NOTE: for group notifications, the count tokens ({numFinished}/{numTotal})
    // only substitute in the TITLE - in the body they print literally. {progress}
    // is valid anywhere. We keep it simple: "Downloading" + a progress bar/%.
    FileDownloader().configureNotificationForGroup(
      _dlGroup,
      running: TaskNotification(l?.downloadNotifDownloadingTitle ?? 'Downloading', '{progress}'),
      complete: TaskNotification(l?.downloadNotifCompleteTitle ?? 'Downloads complete', ''),
      error: TaskNotification(l?.downloadNotifFailedTitle ?? 'Download failed', ''),
      progressBar: true,
    );
    _downloaderConfigured = true;
  }

  AppLocalizations? _l() {
    final ctx = rootNavigatorKey.currentContext;
    return ctx != null ? AppLocalizations.of(ctx) : null;
  }

  /// On iOS, the app container UUID changes on every update, which breaks
  /// stored absolute paths. Detect stale prefixes and remap to the current
  /// container path so downloads survive TestFlight / App Store updates.
  Future<void> _migrateIOSPaths() async {
    if (!Platform.isIOS || _downloads.isEmpty) return;

    final appDir = await getApplicationDocumentsDirectory();
    final currentPrefix = appDir.path; // .../Documents
    // Audio lives in the App Group container - stable across updates in practice
    // (unlike Documents), but resolve it so we can remap audio paths too if the
    // container ever shifts. Belt and suspenders so downloads survive an update.
    final groupAudioBase = await _iosAppGroupAudioBase();

    bool changed = false;
    final entries = Map<String, DownloadInfo>.from(_downloads);

    for (final entry in entries.entries) {
      final info = entry.value;
      bool needsUpdate = false;

      // Remap localPaths (audio sits under the App Group; legacy audio under
      // Documents). Apply both: each is a no-op for paths it doesn't own.
      final newPaths = <String>[];
      for (final path in info.localPaths) {
        final remapped = _remapAppGroupPath(_remapIOSPath(path, currentPrefix), groupAudioBase);
        newPaths.add(remapped);
        if (remapped != path) needsUpdate = true;
      }

      // Covers always live in Documents, so only that prefix can go stale.
      final newCoverPath = info.localCoverPath != null ? _remapIOSPath(info.localCoverPath!, currentPrefix) : null;
      if (newCoverPath != info.localCoverPath) needsUpdate = true;

      final newDirPath = info.localDirPath != null ? _remapAppGroupPath(_remapIOSPath(info.localDirPath!, currentPrefix), groupAudioBase) : null;
      if (newDirPath != info.localDirPath) needsUpdate = true;

      if (needsUpdate) {
        _downloads[entry.key] = DownloadInfo(
          itemId: info.itemId,
          status: info.status,
          localPaths: newPaths,
          sessionData: info.sessionData,
          title: info.title,
          author: info.author,
          coverUrl: info.coverUrl,
          localCoverPath: newCoverPath,
          localDirPath: newDirPath,
          libraryId: info.libraryId,
        );
        changed = true;
      }
    }

    if (changed) {
      debugPrint('[Download] Migrated iOS paths to current container');
      await _save();
    }
  }

  /// Move existing audio files from Documents/ to the iOS app group container
  /// so the widget extension / native player core can read them. Files that
  /// fail to move stay in Documents/ where they continue to play through
  /// Flutter; we'll retry on the next launch. Atomic per-file via
  /// `File.rename()` (works because both directories are on APFS).
  Future<void> _migrateIOSAudioToAppGroup() async {
    if (!Platform.isIOS || _downloads.isEmpty) return;

    final groupBase = await _iosAppGroupAudioBase();
    if (groupBase == null) {
      debugPrint('[Download] App group not available, skipping audio migration');
      return;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final docsBase = '${appDir.path}/downloads';

    int moved = 0;
    int failed = 0;
    bool changed = false;
    final entries = Map<String, DownloadInfo>.from(_downloads);

    for (final entry in entries.entries) {
      final info = entry.value;
      if (info.status != DownloadStatus.downloaded) continue;

      final newPaths = <String>[];
      bool needsUpdate = false;
      for (final oldPath in info.localPaths) {
        // Already in app group? Keep as-is.
        if (oldPath.startsWith(groupBase)) {
          newPaths.add(oldPath);
          continue;
        }
        // Not under Documents/downloads/? Leave alone (custom path or odd).
        if (!oldPath.startsWith(docsBase)) {
          newPaths.add(oldPath);
          continue;
        }
        // Build the parallel path under the app group.
        final relative = oldPath.substring(docsBase.length);
        final newPath = '$groupBase$relative';
        try {
          final oldFile = File(oldPath);
          if (!oldFile.existsSync()) {
            // Old file gone; leave the path untouched and let the validator
            // mark it broken later.
            newPaths.add(oldPath);
            continue;
          }
          // Make sure parent dirs exist on the destination side.
          final parent = Directory(newPath.substring(0, newPath.lastIndexOf('/')));
          if (!parent.existsSync()) parent.createSync(recursive: true);
          // If dest exists already (partial prior run), remove it first.
          final newFile = File(newPath);
          if (newFile.existsSync()) {
            try {
              newFile.deleteSync();
            } catch (_) {}
          }
          await oldFile.rename(newPath);
          await _excludeFromBackup(newPath);
          newPaths.add(newPath);
          needsUpdate = true;
          moved++;
        } catch (e) {
          debugPrint('[Download] Audio migration failed for $oldPath: $e');
          newPaths.add(oldPath);
          failed++;
        }
      }

      if (needsUpdate) {
        _downloads[entry.key] = DownloadInfo(
          itemId: info.itemId,
          status: info.status,
          progress: info.progress,
          localPaths: newPaths,
          sessionData: info.sessionData,
          title: info.title,
          author: info.author,
          coverUrl: info.coverUrl,
          localCoverPath: info.localCoverPath,
          localDirPath: info.localDirPath,
          libraryId: info.libraryId,
        );
        changed = true;
      }
    }

    if (changed) {
      debugPrint('[Download] App group audio migration: moved=$moved failed=$failed');
      await _save();
      notifyListeners();
    }
  }

  /// Replace a stale iOS container prefix with the current one.
  /// Paths contain `.../Documents/...` and we split on `/Documents/` then
  /// rejoin with the current prefix.
  String _remapIOSPath(String path, String currentPrefix) {
    if (path.startsWith(currentPrefix)) return path;
    final marker = '/Documents/';
    final idx = path.indexOf(marker);
    if (idx < 0) return path;
    return '$currentPrefix/${path.substring(idx + marker.length)}';
  }

  /// Replace a stale App Group container prefix with the current one. Audio is
  /// stored at `<group>/audio/downloads/...`; if the container path ever shifts
  /// across an update, rejoin the stable `/audio/downloads` tail onto the freshly
  /// resolved base so previously-downloaded books keep playing. No-op when the
  /// path is already current (the usual case) or for non-audio paths.
  String _remapAppGroupPath(String path, String? groupAudioBase) {
    if (groupAudioBase == null || path.startsWith(groupAudioBase)) return path;
    const marker = '/audio/downloads';
    final idx = path.indexOf(marker);
    if (idx < 0) return path;
    return '$groupAudioBase${path.substring(idx + marker.length)}';
  }

  /// Flag downloaded items whose files sit at a raw external path from before
  /// the SAF switch (not a content URI, not under internal storage). Without
  /// the dropped storage permission these can't be read, so they're kept listed
  /// for re-download instead of being silently dropped by the validator.
  Future<void> _detectLegacyExternal() async {
    if (!Platform.isAndroid || _downloads.isEmpty) return;
    final appDir = await getApplicationDocumentsDirectory();
    final internalPrefix = appDir.path;
    for (final entry in _downloads.entries) {
      final info = entry.value;
      if (info.status != DownloadStatus.downloaded || info.localPaths.isEmpty) {
        continue;
      }
      final first = info.localPaths.first;
      if (isContentUri(first) || first.startsWith(internalPrefix)) continue;
      _legacyExternalIds.add(entry.key);
    }
    if (_legacyExternalIds.isNotEmpty) {
      debugPrint('[Download] ${_legacyExternalIds.length} legacy external download(s) need re-download');
    }
  }

  /// Drop a legacy external entry (its files are orphaned on storage we can no
  /// longer reach) and re-enqueue it from stored metadata so it lands in the
  /// current location (SAF folder or internal).
  Future<void> redownloadLegacy(ApiService api, String itemId) async {
    final info = _downloads[itemId];
    if (info == null) return;
    _downloads.remove(itemId);
    _legacyExternalIds.remove(itemId);
    await _save();
    notifyListeners();
    final episodeId = itemId.length > 36 ? itemId.substring(37) : null;
    await downloadItem(api: api, itemId: itemId, title: info.title ?? '', author: info.author, coverUrl: info.coverUrl, episodeId: episodeId, libraryId: info.libraryId);
  }

  /// Re-download every flagged legacy external item.
  Future<void> redownloadAllLegacy(ApiService api) async {
    for (final id in _legacyExternalIds.toList()) {
      await redownloadLegacy(api, id);
    }
  }

  /// Forget the legacy external entries without re-downloading (user dismissed).
  Future<void> dismissLegacyDownloads() async {
    if (_legacyExternalIds.isEmpty) return;
    for (final id in _legacyExternalIds) {
      _downloads.remove(id);
    }
    _legacyExternalIds.clear();
    await _save();
    notifyListeners();
  }

  /// Validate that downloaded files still exist on disk and clean up orphans.
  /// Runs in background so it doesn't block app startup.
  Future<void> _validateDownloads() async {
    try {
      final orphanIds = <String>[];
      final entries = Map<String, DownloadInfo>.from(_downloads);
      for (final entry in entries.entries) {
        if (entry.value.status != DownloadStatus.downloaded) continue;
        // Legacy external entries are kept for re-download, not validated away.
        if (_legacyExternalIds.contains(entry.key)) continue;
        bool allExist = true;
        for (final path in entry.value.localPaths) {
          // No cheap existence check for a SAF content URI; assume present and
          // let a real playback failure surface a re-download instead.
          if (isContentUri(path)) continue;
          try {
            final exists = await File(path).exists().timeout(const Duration(seconds: 3));
            if (!exists) {
              allExist = false;
              break;
            }
          } catch (_) {
            // Timeout or permission error — treat as missing
            allExist = false;
            break;
          }
        }
        if (!allExist) {
          debugPrint('[Download] Files missing for ${entry.key}, removing');
          _downloads.remove(entry.key);
          orphanIds.add(entry.key);
        }
      }
      if (orphanIds.isNotEmpty) {
        await _save();
        notifyListeners();
        // Clean up partial/orphaned files on disk
        final basePath = await downloadBasePath;
        final internalBase = await _internalBasePath;
        for (final id in orphanIds) {
          debugPrint('[Download] Cleaning up orphaned entry: $id');
          try {
            final dir = Directory('$basePath/$id');
            if (await dir.exists()) await dir.delete(recursive: true);
          } catch (_) {}
          try {
            final coverDir = Directory('$internalBase/$id');
            if (await coverDir.exists()) await coverDir.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[Download] Validation error: $e');
    }
  }

  /// Try to fill in missing metadata from the API (for old downloads).
  Future<void> enrichMetadata(ApiService api) async {
    bool changed = false;
    final entries = Map<String, DownloadInfo>.from(_downloads);
    for (final entry in entries.entries) {
      final info = entry.value;
      if (info.status != DownloadStatus.downloaded) continue;

      bool needsUpdate = false;
      String? title = info.title;
      String? author = info.author;
      String? coverUrl = info.coverUrl;
      String? localCoverPath = info.localCoverPath;

      // For podcast episodes, the itemId is a composite "showUUID-episodeId".
      // Extract the library item ID (first 36 chars = UUID) for API calls.
      final apiItemId = info.itemId.length > 36 ? info.itemId.substring(0, 36) : info.itemId;

      // Enrich missing title/author from server
      if (title == null || title.isEmpty) {
        try {
          final item = await api.getLibraryItem(apiItemId);
          if (item != null) {
            final media = item['media'] as Map<String, dynamic>? ?? {};
            final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
            title = metadata['title'] as String? ?? title;
            author = metadata['authorName'] as String? ?? author;
            coverUrl = api.getCoverUrl(apiItemId);
            needsUpdate = true;
            debugPrint('[Download] Enriched metadata for ${info.itemId}: $title');
          }
        } catch (e) {
          debugPrint('[Download] Enrich failed for ${info.itemId}: $e');
        }
      }

      // Cache cover in internal storage if not already cached
      if (localCoverPath == null || !File(localCoverPath).existsSync()) {
        final internalBase = await _internalBasePath;
        final existingCover = File('$internalBase/${info.itemId}/cover.jpg');
        if (existingCover.existsSync()) {
          // Already on disk from a previous download, just not tracked
          localCoverPath = existingCover.path;
          needsUpdate = true;
        } else {
          // Also check the custom download path (old downloads may have cover there)
          final basePath = await downloadBasePath;
          final oldCover = File('$basePath/${info.itemId}/cover.jpg');
          if (oldCover.existsSync()) {
            localCoverPath = oldCover.path;
            needsUpdate = true;
          } else {
            // Download from server into internal storage
            final url = coverUrl ?? api.getCoverUrl(apiItemId);
            try {
              final resp = await http.get(Uri.parse(url), headers: api.mediaHeaders).timeout(const Duration(seconds: 10));
              if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
                final dir = Directory('$internalBase/${info.itemId}');
                if (!dir.existsSync()) dir.createSync(recursive: true);
                final coverFile = File('${dir.path}/cover.jpg');
                await coverFile.writeAsBytes(resp.bodyBytes);
                final evicted = PaintingBinding.instance.imageCache.evict(FileImage(coverFile));
                localCoverPath = coverFile.path;
                needsUpdate = true;
                debugPrint(
                  '[Download] Cached cover for ${info.itemId} '
                  '(${resp.bodyBytes.length} bytes, evict=$evicted)',
                );
              }
            } catch (e) {
              debugPrint('[Download] Cover cache failed for ${info.itemId}: $e');
            }
          }
        }
      }

      if (needsUpdate) {
        _downloads[entry.key] = DownloadInfo(
          itemId: info.itemId,
          status: info.status,
          localPaths: info.localPaths,
          sessionData: info.sessionData,
          title: title ?? info.title,
          author: author ?? info.author,
          coverUrl: coverUrl ?? info.coverUrl,
          localCoverPath: localCoverPath,
          libraryId: info.libraryId,
        );
        changed = true;
      }
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final entry in _downloads.entries) {
      if (entry.value.status == DownloadStatus.downloaded) {
        map[entry.key] = entry.value.toJson();
      }
    }
    await prefs.setString('downloads', jsonEncode(map));
  }

  List<String>? getLocalPaths(String itemId) {
    final info = _downloads[itemId];
    if (info == null || info.status != DownloadStatus.downloaded) return null;
    return info.localPaths;
  }

  String? getCachedSessionData(String itemId) {
    return _downloads[itemId]?.sessionData;
  }

  /// Get the local cover file path for a downloaded item.
  /// Checks the persisted path first, then probes internal and download dirs.
  Future<String?> getLocalCoverPath(String itemId) async {
    final info = _downloads[itemId];
    if (info == null || info.status != DownloadStatus.downloaded) return null;

    // Check persisted path
    if (info.localCoverPath != null && File(info.localCoverPath!).existsSync()) {
      return info.localCoverPath;
    }

    // Check internal storage (where covers are now cached)
    final internalBase = await _internalBasePath;
    final internalCover = File('$internalBase/$itemId/cover.jpg');
    if (internalCover.existsSync()) return internalCover.path;

    // Check custom download path (old downloads may have cover there)
    final basePath = await downloadBasePath;
    if (basePath != internalBase) {
      final customCover = File('$basePath/$itemId/cover.jpg');
      if (customCover.existsSync()) return customCover.path;
    }

    return null;
  }

  /// Returns null on success, error message string on failure.
  /// For podcast episodes, pass [episodeId] so the correct API endpoint is used.
  Future<String?> downloadItem({required ApiService api, required String itemId, required String title, String? author, String? coverUrl, String? episodeId, String? libraryId}) async {
    if (_activeDownloadIds.contains(itemId)) return null;
    if (isDownloaded(itemId)) return null;
    // Already queued — don't duplicate
    if (_queue.any((q) => q.itemId == itemId)) return null;

    // Check wifi-only setting
    final wifiOnly = await PlayerSettings.getWifiOnlyDownloads();
    if (wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.wifi)) {
        return 'Downloads are set to Wi-Fi only. Connect to Wi-Fi or change this in Settings.';
      }
    }

    final maxConcurrent = await PlayerSettings.getMaxConcurrentDownloads();

    // If at capacity, queue this one
    if (_activeDownloadIds.length >= maxConcurrent) {
      debugPrint('[Download] Queued "$title" ($itemId); slots ${_activeDownloadIds.length}/$maxConcurrent full, ${_queue.length} waiting');
      _queue.add(_QueuedDownload(api: api, itemId: itemId, title: title, author: author, coverUrl: coverUrl, episodeId: episodeId, libraryId: libraryId));
      _downloads[itemId] = DownloadInfo(itemId: itemId, status: DownloadStatus.downloading, progress: 0, title: title, author: author, coverUrl: coverUrl, libraryId: libraryId);
      notifyListeners();
      return null;
    }

    // Launch immediately (fire-and-forget so caller doesn't block)
    unawaited(_executeDownload(api: api, itemId: itemId, title: title, author: author, coverUrl: coverUrl, episodeId: episodeId, libraryId: libraryId));
    return null;
  }

  /// Fill free download slots from the queue.
  Future<void> _processQueue() async {
    final maxConcurrent = await PlayerSettings.getMaxConcurrentDownloads();
    while (_queue.isNotEmpty && _activeDownloadIds.length < maxConcurrent) {
      final next = _queue.removeAt(0);
      // Skip if cancelled/removed while waiting
      if (isDownloaded(next.itemId)) continue;
      if (_activeDownloadIds.contains(next.itemId)) continue;
      unawaited(_executeDownload(api: next.api, itemId: next.itemId, title: next.title, author: next.author, coverUrl: next.coverUrl, episodeId: next.episodeId, libraryId: next.libraryId));
    }
  }

  static String _taskId(String itemId, int trackIndex) => '$itemId::$trackIndex';

  /// Statuses from which a task will never progress further.
  static const Set<TaskStatus> _terminal = {TaskStatus.complete, TaskStatus.failed, TaskStatus.notFound, TaskStatus.canceled};

  /// Best-effort download of a book's ebook into the persistent reader cache so
  /// it reads offline. Swallows errors - the audio download is what matters.
  Future<void> _cacheEbookForOffline(ApiService api, String itemId, Map<String, dynamic> ebookFile, String title) async {
    try {
      await fetchEbookToCache(api, itemId, ebookFile, title);
      debugPrint('[Download] cached ebook for offline: $itemId');
    } catch (e) {
      debugPrint('[Download] ebook offline cache failed for $itemId: $e');
    }
  }

  /// Resolve a book/episode to durable per-file download tasks and enqueue them.
  /// Returns once the tasks are handed to `background_downloader`; progress and
  /// completion are driven asynchronously by [_onTaskUpdate] / [_finalizeSuccess]
  /// (which also fire after an app relaunch).
  Future<void> _executeDownload({required ApiService api, required String itemId, required String title, String? author, String? coverUrl, String? episodeId, String? libraryId}) async {
    _activeDownloadIds.add(itemId);
    _cancelledIds.remove(itemId);
    debugPrint('[Download] Starting "$title" ($itemId)');

    _downloads[itemId] = DownloadInfo(itemId: itemId, status: DownloadStatus.downloading, progress: 0, title: title, author: author, coverUrl: coverUrl, libraryId: libraryId);
    notifyListeners();

    // SAF custom folder (Android only): files go to a flat per-book folder
    // under the user-granted tree via content URIs, no storage permission.
    final useSaf = Platform.isAndroid && _customDownloadUri != null && _customDownloadUri!.isNotEmpty;
    String? bookDirRef; // filesystem path or content:// URI, for cleanup
    Directory? bookDir; // filesystem branches only
    try {
      // For episodes, itemId is a composite key like 'podcastId-episodeId'.
      // Extract the real library item ID for the API call.
      final apiItemId = episodeId != null ? itemId.substring(0, itemId.length - episodeId.length - 1) : itemId;

      // The playback session is only for METADATA (durations/chapters) needed by
      // offline seeking. We do NOT download from its session-scoped contentUrls
      // (they die when the session closes); we use durable /file/:ino URLs.
      final sessionData = episodeId != null ? await api.startEpisodePlaybackSession(apiItemId, episodeId) : await api.startPlaybackSession(apiItemId);
      if (sessionData == null) throw Exception('Failed to start session');

      final audioTracks = sessionData['audioTracks'] as List<dynamic>?;
      if (audioTracks == null || audioTracks.isEmpty) {
        throw Exception('No audio tracks');
      }

      final files = await _resolveDurableFiles(api, apiItemId, episodeId, audioTracks);

      // Pull the companion ebook into the offline cache too, so a downloaded
      // book is fully readable offline. Fire-and-forget - never blocks or fails
      // the audio download.
      final ebookFile = ((sessionData['libraryItem'] as Map<String, dynamic>?)?['media'] as Map<String, dynamic>?)?['ebookFile'] as Map<String, dynamic>?;
      if (ebookFile != null) {
        unawaited(_cacheEbookForOffline(api, apiItemId, ebookFile, title));
      }

      // Per-book destination. Android downloads to internal storage first - for
      // both the internal default AND SAF custom folders. SAF books are then
      // moved into the user's chosen folder under "Author/Title" on completion
      // (a direct SAF write can't nest subfolders). iOS downloads into the app
      // group container.
      final nestedName = (author != null && author.isNotEmpty) ? '${_sanitizePath(author)}/${_sanitizePath(title)}' : _sanitizePath(title);
      String? relDir; // Android: relative to applicationDocuments
      if (Platform.isIOS) {
        final basePath = await downloadBasePath;
        bookDir = Directory('$basePath/$nestedName');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        relDir = 'downloads/$nestedName';
        bookDir = Directory('${appDir.path}/$relDir');
      }
      if (!bookDir.existsSync()) bookDir.createSync(recursive: true);
      bookDirRef = bookDir.path;
      debugPrint('[Download] "$title" location=${useSaf ? 'SAF' : 'default'} dir=${bookDir.path} tracks=${files.length}');

      final localCoverPath = await _cacheCover(api, itemId, coverUrl);

      // Strip the bulky libraryItem before persisting the session for offline use.
      final slimSession = Map<String, dynamic>.from(sessionData)..remove('libraryItem');
      final sessionId = sessionData['id'] as String?;
      if (sessionId != null) unawaited(api.closePlaybackSession(sessionId));

      // Cancelled while we were resolving? Bail before enqueueing anything.
      if (_cancelledIds.remove(itemId)) {
        await _cleanupBookDir(bookDirRef);
        _activeDownloadIds.remove(itemId);
        _downloads.remove(itemId);
        notifyListeners();
        unawaited(_processQueue());
        return;
      }

      final expectedPaths = [for (final f in files) '${bookDir.path}/${f.filename}'];
      final wifiOnly = await PlayerSettings.getWifiOnlyDownloads();

      final pending = _PendingBook(
        itemId: itemId,
        apiItemId: apiItemId,
        episodeId: episodeId,
        title: title,
        author: author,
        coverUrl: coverUrl,
        localCoverPath: localCoverPath,
        libraryId: libraryId,
        bookDir: bookDirRef,
        trackCount: files.length,
        expectedPaths: expectedPaths,
        slimSessionJson: jsonEncode(slimSession),
        safTreeUri: useSaf ? _customDownloadUri : null,
        safSubfolder: useSaf ? nestedName : null,
      );
      _pending[itemId] = pending;
      await _persistPending();

      for (int i = 0; i < files.length; i++) {
        final meta = jsonEncode({'itemId': itemId, 'i': i, 'n': files.length});
        final Task task;
        if (Platform.isIOS) {
          task = DownloadTask(
            taskId: _taskId(itemId, i),
            url: files[i].url,
            headers: api.mediaHeaders,
            filename: files[i].filename,
            baseDirectory: BaseDirectory.root,
            directory: bookDir.path,
            group: _dlGroup,
            metaData: meta,
            updates: Updates.statusAndProgress,
            requiresWiFi: wifiOnly,
            retries: 3,
            allowPause: true,
          );
        } else {
          task = DownloadTask(
            taskId: _taskId(itemId, i),
            url: files[i].url,
            headers: api.mediaHeaders,
            filename: files[i].filename,
            baseDirectory: BaseDirectory.applicationDocuments,
            directory: relDir!,
            group: _dlGroup,
            metaData: meta,
            updates: Updates.statusAndProgress,
            requiresWiFi: wifiOnly,
            retries: 3,
            allowPause: true,
          );
        }
        final ok = await FileDownloader().enqueue(task);
        debugPrint('[Download] enqueue ${i + 1}/${files.length} ok=$ok file=${files[i].filename}');
        if (!ok) throw Exception('Failed to enqueue track ${i + 1}');
      }
      debugPrint('[Download] Enqueued ${files.length} task(s) for "$title"');
    } catch (e) {
      await _failBook(itemId, cause: e, bookDirRef: bookDirRef, title: title, author: author, coverUrl: coverUrl);
    }
  }

  /// Map each playback track to a durable, session-independent file URL using
  /// the library item's audioFiles[].ino. Index-aligned with [audioTracks].
  Future<List<({String url, String filename})>> _resolveDurableFiles(ApiService api, String apiItemId, String? episodeId, List<dynamic> audioTracks) async {
    final item = await api.getLibraryItem(apiItemId);
    if (item == null) throw Exception('Failed to load item details');
    final media = item['media'] as Map<String, dynamic>? ?? {};

    List<Map<String, dynamic>> audioFiles;
    if (episodeId != null) {
      final episodes = (media['episodes'] as List<dynamic>?) ?? const [];
      Map<String, dynamic>? ep;
      for (final e in episodes) {
        if (e is Map<String, dynamic> && e['id'] == episodeId) {
          ep = e;
          break;
        }
      }
      final af = ep?['audioFile'] as Map<String, dynamic>?;
      audioFiles = af != null ? [af] : const [];
    } else {
      audioFiles = ((media['audioFiles'] as List<dynamic>?) ?? const []).whereType<Map<String, dynamic>>().toList()..sort((a, b) => ((a['index'] as num?) ?? 0).compareTo((b['index'] as num?) ?? 0));
    }

    if (audioFiles.length < audioTracks.length) {
      throw Exception('Audio file mismatch (${audioFiles.length} files vs ${audioTracks.length} tracks)');
    }

    final out = <({String url, String filename})>[];
    for (int i = 0; i < audioTracks.length; i++) {
      final track = audioTracks[i] as Map<String, dynamic>;
      final ino = audioFiles[i]['ino']?.toString();
      if (ino == null || ino.isEmpty) {
        throw Exception('Missing file inode for track ${i + 1}');
      }
      out.add((url: api.buildFileUrl(apiItemId, ino), filename: _trackFileName(track, i)));
    }
    return out;
  }

  /// Derive the on-disk filename for a track, preferring its original name so
  /// the layout matches what older (http-based) downloads produced.
  String _trackFileName(Map<String, dynamic> track, int i) {
    final contentUrl = track['contentUrl'] as String? ?? '';
    final trackMeta = track['metadata'] as Map<String, dynamic>?;
    var originalName = trackMeta?['filename'] as String? ?? '';
    if (originalName.isEmpty) {
      final contentPath = Uri.tryParse(contentUrl)?.path ?? contentUrl;
      originalName = Uri.decodeComponent(contentPath.split('/').last);
      if (originalName.contains('?')) originalName = originalName.split('?').first;
    }
    if (originalName.isNotEmpty && originalName.contains('.')) {
      return _sanitizePath(originalName.replaceAll(RegExp(r'\.[^.]+$'), '')) + originalName.substring(originalName.lastIndexOf('.'));
    }
    final mimeType = track['mimeType'] as String? ?? 'audio/mpeg';
    final ext = mimeType.contains('mp4')
        ? 'm4a'
        : mimeType.contains('flac')
        ? 'flac'
        : mimeType.contains('ogg')
        ? 'ogg'
        : 'mp3';
    return 'track_${i.toString().padLeft(3, '0')}.$ext';
  }

  /// Cache the cover into INTERNAL storage (lockscreen / Android Auto / offline).
  /// Always internal, since a custom external audio path may lack write access.
  Future<String?> _cacheCover(ApiService api, String itemId, String? coverUrl) async {
    if (coverUrl == null || coverUrl.isEmpty) return null;
    try {
      final coverResp = await http.get(Uri.parse(coverUrl), headers: api.mediaHeaders).timeout(const Duration(seconds: 10));
      if (coverResp.statusCode == 200 && coverResp.bodyBytes.isNotEmpty) {
        final internalBase = await _internalBasePath;
        final coverDir = Directory('$internalBase/$itemId');
        if (!coverDir.existsSync()) coverDir.createSync(recursive: true);
        final coverFile = File('${coverDir.path}/cover.jpg');
        await coverFile.writeAsBytes(coverResp.bodyBytes);
        debugPrint('[Download] Cached cover image: ${coverFile.path}');
        return coverFile.path;
      }
    } catch (e) {
      debugPrint('[Download] Cover cache failed (non-fatal): $e');
    }
    return null;
  }

  // ── background_downloader update handling ──

  (String, int)? _decodeMeta(String metaData) {
    if (metaData.isEmpty) return null;
    try {
      final m = jsonDecode(metaData) as Map<String, dynamic>;
      final itemId = m['itemId'] as String?;
      final i = m['i'] as int?;
      if (itemId == null || i == null) return null;
      return (itemId, i);
    } catch (_) {
      return null;
    }
  }

  void _onTaskUpdate(TaskUpdate update) {
    final meta = _decodeMeta(update.task.metaData);
    if (meta == null) return;
    final itemId = meta.$1;
    final i = meta.$2;
    final p = _pending[itemId];
    if (p == null) return;
    p.lastUpdate = DateTime.now();

    if (update is TaskProgressUpdate) {
      final prog = update.progress;
      if (prog >= 0 && prog <= 1) {
        p.trackProgress[i] = prog;
        _emitBookProgress(itemId, p);
      }
    } else if (update is TaskStatusUpdate) {
      p.trackStatus[i] = update.status;
      debugPrint(
        '[Download] task $itemId #$i status=${update.status.name}'
        '${update.exception != null ? ' ex=${update.exception}' : ''}'
        '${update.responseStatusCode != null ? ' code=${update.responseStatusCode}' : ''}',
      );
      if (update.status == TaskStatus.complete) p.trackProgress[i] = 1.0;

      // A hard failure aborts the whole book: cancel the remaining siblings so
      // it doesn't hang waiting on tracks that will never finish.
      if ((update.status == TaskStatus.failed || update.status == TaskStatus.notFound) && !p.cancelled && !p.failing) {
        p.failing = true;
        p.failException = update.exception;
        p.failCode = update.responseStatusCode;
        unawaited(_cancelSiblings(itemId, p));
      }
      _checkBookTerminal(itemId, p);
    }
  }

  void _emitBookProgress(String itemId, _PendingBook p) {
    final now = DateTime.now();
    if (now.difference(p.lastUi).inMilliseconds < 250) return;
    p.lastUi = now;
    _downloads[itemId] = DownloadInfo(itemId: itemId, status: DownloadStatus.downloading, progress: p.overallProgress, title: p.title, author: p.author, coverUrl: p.coverUrl, libraryId: p.libraryId);
    notifyListeners();
  }

  /// Once every track of a book is terminal, route to success / fail / cancel.
  void _checkBookTerminal(String itemId, _PendingBook p) {
    if (p.finalizing) return;
    for (int i = 0; i < p.trackCount; i++) {
      final s = p.trackStatus[i];
      if (s == null || !_terminal.contains(s)) return;
    }
    p.finalizing = true; // synchronous guard against a burst of terminal updates
    if (p.trackStatus.values.every((s) => s == TaskStatus.complete)) {
      unawaited(_finalizeSuccess(itemId));
    } else if (p.failing) {
      unawaited(_failBook(itemId, taskException: p.failException, responseCode: p.failCode));
    } else {
      unawaited(_handleCanceled(itemId));
    }
  }

  /// Move a completed book's internal files into the SAF folder [treeUri] under
  /// [subfolder] (e.g. "Author/Title"), via the native DocumentFile helper.
  /// Returns the created folder URI and the per-file content URIs, or null if
  /// the move failed.
  Future<({String dirUri, List<String> fileUris})?> _moveBookToSaf(String treeUri, String subfolder, List<String> filenames, List<String> tempPaths) async {
    try {
      final res = await _storageChannel.invokeMethod<Map>('moveBookToSaf', {'treeUri': treeUri, 'subfolder': subfolder, 'filenames': filenames, 'tempPaths': tempPaths});
      final dirUri = res?['dirUri'] as String?;
      final fileUris = (res?['fileUris'] as List?)?.map((e) => e as String).toList();
      if (dirUri == null || fileUris == null || fileUris.length != filenames.length) {
        return null;
      }
      return (dirUri: dirUri, fileUris: fileUris);
    } catch (e) {
      debugPrint('[Download] moveBookToSaf failed: $e');
      return null;
    }
  }

  Future<void> _finalizeSuccess(String itemId) async {
    final p = _pending[itemId];
    if (p == null) return;

    // Files always land in internal storage first.
    final localPaths = p.expectedPaths.where((path) => File(path).existsSync()).toList();
    if (localPaths.length != p.trackCount) {
      debugPrint(
        '[Download] Finalize "$itemId": only ${localPaths.length}/${p.trackCount} '
        'files present, treating as failure',
      );
      p.finalizing = false; // let _failBook proceed
      await _failBook(itemId, cause: 'Missing files after download');
      return;
    }

    var finalPaths = localPaths;
    String? finalDirPath = p.bookDir;

    // SAF: move the downloaded files into the user's chosen folder under
    // "Author/Title" and play/delete via the returned content URIs. If the move
    // fails the book stays usable from its internal copy.
    if (p.isSaf) {
      final filenames = [for (final path in localPaths) path.split('/').last];
      final moved = await _moveBookToSaf(p.safTreeUri!, p.safSubfolder ?? '', filenames, localPaths);
      if (moved != null) {
        finalPaths = moved.fileUris;
        finalDirPath = moved.dirUri;
        await _cleanupBookDir(p.bookDir); // drop the now-empty internal temp dir
      } else {
        debugPrint('[Download] SAF move failed for "$itemId", keeping internal copy');
      }
    } else if (Platform.isIOS) {
      for (final path in localPaths) {
        await _excludeFromBackup(path);
      }
    }

    _downloads[itemId] = DownloadInfo(
      itemId: itemId,
      status: DownloadStatus.downloaded,
      localPaths: finalPaths,
      sessionData: p.slimSessionJson,
      title: p.title,
      author: p.author,
      coverUrl: p.coverUrl,
      localCoverPath: p.localCoverPath,
      localDirPath: finalDirPath,
      libraryId: p.libraryId,
    );
    await _save();
    _activeDownloadIds.remove(itemId);
    _pending.remove(itemId);
    await _persistPending();
    await _deleteDbRecords(itemId, p.trackCount);
    notifyListeners();

    // Hot-swap if this book is currently streaming. switchToLocal reads the
    // live position, so it's safe even when this fires from a background update.
    try {
      final player = AudioPlayerService();
      if (player.currentProgressKey == itemId && player.hasBook) {
        await player.switchToLocal(itemId);
      }
    } catch (_) {}

    debugPrint('[Download] Complete: ${p.title} (${localPaths.length} files)');
    unawaited(_processQueue());
  }

  Future<void> _failBook(String itemId, {Object? cause, TaskException? taskException, int? responseCode, String? title, String? author, String? coverUrl, String? bookDirRef}) async {
    final p = _pending[itemId];
    if (p != null) {
      if (p.finalizing) return;
      p.finalizing = true;
    }
    final t = title ?? p?.title ?? '';
    final a = author ?? p?.author;
    final c = coverUrl ?? p?.coverUrl;
    final dir = bookDirRef ?? p?.bookDir;

    if (p != null) await _cancelSiblings(itemId, p, force: true);
    await _cleanupBookDir(dir);

    final msg = _mapError(cause, taskException, responseCode);
    _downloads[itemId] = DownloadInfo(itemId: itemId, status: DownloadStatus.error, title: t, author: a, coverUrl: c);
    _activeDownloadIds.remove(itemId);
    _pending.remove(itemId);
    await _persistPending();
    await _deleteDbRecords(itemId, p?.trackCount ?? 0);
    _cancelledIds.remove(itemId);
    debugPrint('[Download] Failed "$t": $msg (${cause ?? taskException?.description})');
    notifyListeners();
    unawaited(_processQueue());
  }

  Future<void> _handleCanceled(String itemId) async {
    final p = _pending[itemId];
    await _cleanupBookDir(p?.bookDir);
    _downloads.remove(itemId);
    _activeDownloadIds.remove(itemId);
    _pending.remove(itemId);
    await _persistPending();
    await _deleteDbRecords(itemId, p?.trackCount ?? 0);
    _cancelledIds.remove(itemId);
    debugPrint('[Download] Cancelled: ${p?.title ?? itemId}');
    notifyListeners();
    unawaited(_processQueue());
  }

  Future<void> _cancelSiblings(String itemId, _PendingBook p, {bool force = false}) async {
    final ids = <String>[];
    for (int i = 0; i < p.trackCount; i++) {
      final s = p.trackStatus[i];
      if (force || s == null || !_terminal.contains(s)) ids.add(_taskId(itemId, i));
    }
    if (ids.isNotEmpty) {
      try {
        await FileDownloader().cancelTasksWithIds(ids);
      } catch (_) {}
    }
  }

  /// Remove a book's download folder. [bookDir] is a filesystem path. SAF
  /// downloads share the user's granted folder, so there's no per-book folder
  /// to remove (cleanup of SAF files is per-file via [deleteDownload]).
  Future<void> _cleanupBookDir(String? bookDir) async {
    if (bookDir == null || isContentUri(bookDir)) return;
    final dir = Directory(bookDir);
    try {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        final parent = dir.parent;
        if (parent.existsSync() && parent.listSync().isEmpty) parent.deleteSync();
      }
    } catch (_) {}
  }

  String _mapError(Object? cause, TaskException? te, int? code) {
    final s = '${cause ?? ''} ${te?.description ?? ''}'.toLowerCase();
    if (s.contains('no space') || s.contains('enospc')) return 'Not enough storage space';
    if (s.contains('permission') || s.contains('not permitted') || code == 403) {
      return 'Permission denied - check download location in Settings';
    }
    return 'Download failed';
  }

  Future<void> _deleteDbRecords(String itemId, int trackCount) async {
    for (int i = 0; i < trackCount; i++) {
      try {
        await FileDownloader().database.deleteRecordWithId(_taskId(itemId, i));
      } catch (_) {}
    }
  }

  // ── Resume-after-kill persistence ──

  Future<void> _persistPending() async {
    final prefs = await SharedPreferences.getInstance();
    if (_pending.isEmpty) {
      await prefs.remove('pending_downloads');
      return;
    }
    final map = {for (final e in _pending.entries) e.key: e.value.toJson()};
    await prefs.setString('pending_downloads', jsonEncode(map));
  }

  Future<void> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('pending_downloads');
    if (json == null) return;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      for (final e in map.entries) {
        final p = _PendingBook.fromJson(e.value as Map<String, dynamic>);
        _pending[e.key] = p;
        _activeDownloadIds.add(e.key);
        _downloads[e.key] = DownloadInfo(itemId: e.key, status: DownloadStatus.downloading, progress: 0, title: p.title, author: p.author, coverUrl: p.coverUrl, libraryId: p.libraryId);
      }
    } catch (e) {
      debugPrint('[Download] loadPending error: $e');
    }
  }

  /// Rebuild in-flight progress from the package task DB after a relaunch, then
  /// finalize books that finished while we were dead and drop ones whose tasks
  /// are gone. Tasks still in flight keep running; their updates (plus
  /// resumeFromBackground) drive them to terminal.
  Future<void> _rehydratePending() async {
    if (_pending.isEmpty) return;
    List<TaskRecord> records;
    try {
      records = await FileDownloader().database.allRecords();
    } catch (_) {
      records = const [];
    }

    final tracked = <String, Set<int>>{};
    for (final r in records) {
      final meta = _decodeMeta(r.task.metaData);
      if (meta == null) continue;
      final p = _pending[meta.$1];
      if (p == null) continue;
      final i = meta.$2;
      p.trackStatus[i] = r.status;
      p.trackProgress[i] = r.status == TaskStatus.complete ? 1.0 : (r.progress >= 0 && r.progress <= 1 ? r.progress : 0.0);
      (tracked[meta.$1] ??= {}).add(i);
    }

    for (final itemId in _pending.keys.toList()) {
      final p = _pending[itemId]!;
      bool allComplete = p.trackCount > 0;
      bool allTerminal = true;
      for (int i = 0; i < p.trackCount; i++) {
        final s = p.trackStatus[i];
        if (s != TaskStatus.complete) allComplete = false;
        if (s == null || !_terminal.contains(s)) allTerminal = false;
      }

      if (allComplete) {
        p.finalizing = true;
        await _finalizeSuccess(itemId);
      } else if (allTerminal) {
        p.finalizing = true;
        await _failBook(itemId, cause: 'Interrupted download');
      } else if ((tracked[itemId]?.isEmpty ?? true)) {
        // The package has no record of these tasks (DB wiped) and we can't
        // rebuild durable URLs here, so surface as failed for a manual retry.
        p.finalizing = true;
        await _failBook(itemId, cause: 'Interrupted download');
      } else {
        // Still in flight: leave it; updates + resumeFromBackground finish it.
        _emitBookProgress(itemId, p);
      }
    }
  }

  Future<void> deleteDownload(String itemId, {bool skipStopCheck = false}) async {
    // If this is still downloading, cancel the in-flight transfer (which cleans
    // up partial files and the background tasks) rather than deleting.
    if (_pending.containsKey(itemId)) {
      cancelDownload(itemId);
      return;
    }

    final info = _downloads[itemId];
    if (info == null) return;

    // Stop playback if this item is currently playing to avoid crashes
    if (!skipStopCheck) {
      final player = AudioPlayerService();
      if (player.currentItemId == itemId || (itemId.length > 36 && player.currentItemId == itemId.substring(0, 36))) {
        await player.stop();
      }
    }

    for (final path in info.localPaths) {
      try {
        if (isContentUri(path)) {
          await FileDownloader().uri.deleteFile(Uri.parse(path));
        } else {
          final file = File(path);
          if (file.existsSync()) file.deleteSync();
        }
      } catch (_) {}
    }

    // Remove the download directory (new-style path from DownloadInfo, or legacy UUID path)
    try {
      final dirPath = info.localDirPath;
      if (dirPath != null && isContentUri(dirPath)) {
        // SAF book folder: best-effort delete (harmless if already emptied).
        try {
          await FileDownloader().uri.deleteFile(Uri.parse(dirPath));
        } catch (_) {}
      } else if (dirPath != null && Directory(dirPath).existsSync()) {
        Directory(dirPath).deleteSync(recursive: true);
        // Clean up empty parent (Author folder) if it's now empty
        final parent = Directory(dirPath).parent;
        if (parent.existsSync() && parent.listSync().isEmpty) {
          parent.deleteSync();
        }
      } else {
        // Legacy fallback: UUID-based directory
        final basePath = await downloadBasePath;
        final bookDir = Directory('$basePath/$itemId');
        if (bookDir.existsSync()) bookDir.deleteSync(recursive: true);
      }
    } catch (_) {}

    try {
      final internalBase = await _internalBasePath;
      final coverDir = Directory('$internalBase/$itemId');
      final coverFile = File('$internalBase/$itemId/cover.jpg');
      // FileImage caches by path; evict so a re-download at the same path renders fresh.
      if (coverFile.existsSync()) {
        final evicted = PaintingBinding.instance.imageCache.evict(FileImage(coverFile));
        debugPrint('[Download] evict cover ${coverFile.path} -> $evicted');
      }
      if (coverDir.existsSync()) coverDir.deleteSync(recursive: true);
    } catch (e) {
      debugPrint('[Download] cover cleanup failed: $e');
    }

    // Drop the offline ebook copy too, if any.
    await deleteCachedEbook(itemId);

    _downloads.remove(itemId);
    await _save();
    notifyListeners();
  }

  void cancelDownload(String itemId) {
    // Drop it from the waiting queue if it never started.
    _queue.removeWhere((q) => q.itemId == itemId);

    // Flag so an in-flight _executeDownload bails before enqueueing, and so a
    // book mid-resolution doesn't leak an active slot.
    _cancelledIds.add(itemId);

    final p = _pending[itemId];
    if (p != null && !p.finalizing) {
      p.cancelled = true;
      // Ask the package to cancel any live tasks, then clean up ourselves. We do
      // NOT wait for the package's `canceled` update: it never fires for tasks
      // the package no longer tracks (e.g. records left over after an app
      // update), which would leak the slot and wedge the whole queue.
      final ids = [for (int i = 0; i < p.trackCount; i++) _taskId(itemId, i)];
      unawaited(FileDownloader().cancelTasksWithIds(ids));
      unawaited(_handleCanceled(itemId)); // frees the slot + processes the queue
    } else {
      _activeDownloadIds.remove(itemId);
    }

    // Instant UI feedback (cleanup paths also notify).
    _downloads.remove(itemId);
    notifyListeners();
  }
}
