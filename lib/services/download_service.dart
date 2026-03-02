import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'audio_player_service.dart';
import 'download_notification_service.dart';

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
      localPaths: (json['localPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sessionData: json['sessionData'] as String?,
      title: title,
      author: author,
      coverUrl: coverUrl,
      localCoverPath: json['localCoverPath'] as String?,
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

  _QueuedDownload({
    required this.api,
    required this.itemId,
    required this.title,
    this.author,
    this.coverUrl,
    this.episodeId,
  });
}

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._();
  factory DownloadService() => _instance;
  DownloadService._();

  final Map<String, DownloadInfo> _downloads = {};
  String? _activeDownloadId;
  http.Client? _httpClient;
  bool _cancelled = false;
  String? _customDownloadPath;

  /// Queue of pending download requests.
  final List<_QueuedDownload> _queue = [];
  bool _processingQueue = false;

  /// The current download directory path, or null if using default.
  String? get customDownloadPath => _customDownloadPath;

  /// Get the effective download base directory.
  Future<String> get downloadBasePath async {
    if (_customDownloadPath != null && _customDownloadPath!.isNotEmpty) {
      return _customDownloadPath!;
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

  /// Set a custom download location. Pass null to revert to default.
  Future<void> setCustomDownloadPath(String? path) async {
    _customDownloadPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null && path.isNotEmpty) {
      await prefs.setString('custom_download_path', path);
    } else {
      await prefs.remove('custom_download_path');
    }
    notifyListeners();
  }

  /// Get a human-readable label for the current download location.
  Future<String> get downloadLocationLabel async {
    if (_customDownloadPath != null && _customDownloadPath!.isNotEmpty) {
      // Shorten the path for display
      final path = _customDownloadPath!;
      // Try to show a friendly path relative to common roots
      if (path.contains('/emulated/0/')) {
        return path.split('/emulated/0/').last;
      }
      if (path.contains('/storage/')) {
        return path.split('/storage/').last;
      }
      // Last two segments
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.length >= 2) {
        return '${segments[segments.length - 2]}/${segments.last}';
      }
      return path;
    }
    return 'App Internal Storage (Default)';
  }

  /// Calculate total size of all downloaded files.
  Future<int> get totalDownloadSize async {
    int total = 0;
    for (final info in _downloads.values) {
      if (info.status == DownloadStatus.downloaded) {
        for (final path in info.localPaths) {
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

  DownloadInfo getInfo(String itemId) =>
      _downloads[itemId] ?? DownloadInfo(itemId: itemId);

  bool isDownloaded(String itemId) =>
      _downloads[itemId]?.status == DownloadStatus.downloaded;

  bool isDownloading(String itemId) =>
      _downloads[itemId]?.status == DownloadStatus.downloading;

  double downloadProgress(String itemId) =>
      _downloads[itemId]?.progress ?? 0;

  /// Get all downloaded items (for home screen display).
  List<DownloadInfo> get downloadedItems =>
      _downloads.values
          .where((d) => d.status == DownloadStatus.downloaded)
          .toList();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customDownloadPath = prefs.getString('custom_download_path');
    final json = prefs.getString('downloads');
    if (json != null) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        for (final entry in map.entries) {
          final info =
              DownloadInfo.fromJson(entry.value as Map<String, dynamic>);
          debugPrint('[Download] Loaded: ${entry.key} '
              'title="${info.title}" author="${info.author}" '
              'cover=${info.coverUrl != null ? "yes" : "null"} '
              'sessionData=${info.sessionData != null ? "${info.sessionData!.length} chars" : "null"}');
          if (info.status == DownloadStatus.downloaded) {
            bool allExist = true;
            for (final path in info.localPaths) {
              if (!File(path).existsSync()) {
                allExist = false;
                break;
              }
            }
            if (allExist) {
              _downloads[entry.key] = info;
            }
          }
        }
      } catch (e) {
        debugPrint('[Download] Init error: $e');
      }
    }
    // Re-save to persist any metadata extracted from sessionData
    if (_downloads.isNotEmpty) await _save();
    notifyListeners();
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
      final apiItemId = info.itemId.length > 36
          ? info.itemId.substring(0, 36)
          : info.itemId;

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
              final resp = await http.get(Uri.parse(url), headers: api.mediaHeaders)
                  .timeout(const Duration(seconds: 10));
              if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
                final dir = Directory('$internalBase/${info.itemId}');
                if (!dir.existsSync()) dir.createSync(recursive: true);
                final coverFile = File('${dir.path}/cover.jpg');
                await coverFile.writeAsBytes(resp.bodyBytes);
                localCoverPath = coverFile.path;
                needsUpdate = true;
                debugPrint('[Download] Cached cover for ${info.itemId}');
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
  Future<String?> downloadItem({
    required ApiService api,
    required String itemId,
    required String title,
    String? author,
    String? coverUrl,
    String? episodeId,
    bool waitForCompletion = true,
  }) async {
    if (_activeDownloadId == itemId) return null;
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

    // If another download is active, queue this one
    if (_activeDownloadId != null) {
      _queue.add(_QueuedDownload(
        api: api,
        itemId: itemId,
        title: title,
        author: author,
        coverUrl: coverUrl,
        episodeId: episodeId,
      ));
      _downloads[itemId] = DownloadInfo(
        itemId: itemId,
        status: DownloadStatus.downloading,
        progress: 0,
        title: title,
        author: author,
        coverUrl: coverUrl,
      );
      notifyListeners();
      // Ensure queue processor is running
      if (!_processingQueue) unawaited(_processQueue());
      return null;
    }

    if (waitForCompletion) {
      await _executeDownload(
        api: api,
        itemId: itemId,
        title: title,
        author: author,
        coverUrl: coverUrl,
        episodeId: episodeId,
      );
      // Process any queued downloads
      if (_queue.isNotEmpty && !_processingQueue) {
        unawaited(_processQueue());
      }
    } else {
      unawaited(
        _executeDownload(
          api: api,
          itemId: itemId,
          title: title,
          author: author,
          coverUrl: coverUrl,
          episodeId: episodeId,
        ).whenComplete(() {
          if (_queue.isNotEmpty && !_processingQueue) {
            unawaited(_processQueue());
          }
        }),
      );
    }
    return null;
  }

  Future<void> _processQueue() async {
    _processingQueue = true;
    while (_activeDownloadId != null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    while (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      // Skip if cancelled/removed while waiting
      if (isDownloaded(next.itemId)) continue;
      await _executeDownload(
        api: next.api, itemId: next.itemId, title: next.title,
        author: next.author, coverUrl: next.coverUrl, episodeId: next.episodeId,
      );
    }
    _processingQueue = false;
  }

  Future<void> _executeDownload({
    required ApiService api,
    required String itemId,
    required String title,
    String? author,
    String? coverUrl,
    String? episodeId,
  }) async {
    _activeDownloadId = itemId;
    _cancelled = false;
    _downloads[itemId] = DownloadInfo(
      itemId: itemId,
      status: DownloadStatus.downloading,
      progress: 0,
      title: title,
      author: author,
      coverUrl: coverUrl,
    );
    notifyListeners();

    // Show persistent download notification via foreground service
    final notif = DownloadNotificationService();
    try {
      await notif.startForeground(title: title, author: author);
    } catch (e) {
      debugPrint('[Download] startForeground non-fatal error: $e');
    }

    try {
      // For episodes, itemId is a composite key like 'podcastId-episodeId'.
      // Extract the real library item ID for the API call.
      final apiItemId = episodeId != null
          ? itemId.substring(0, itemId.length - episodeId.length - 1)
          : itemId;
      final sessionData = episodeId != null
          ? await api.startEpisodePlaybackSession(apiItemId, episodeId)
          : await api.startPlaybackSession(apiItemId);
      if (sessionData == null) throw Exception('Failed to start session');

      final audioTracks = sessionData['audioTracks'] as List<dynamic>?;
      if (audioTracks == null || audioTracks.isEmpty) {
        throw Exception('No audio tracks');
      }

      final basePath = await downloadBasePath;
      final bookDir = Directory('$basePath/$itemId');
      if (!bookDir.existsSync()) {
        bookDir.createSync(recursive: true);
      }

      // Cache the cover image in internal storage for offline use (lockscreen, Android Auto).
      // Always use internal path — custom external paths may lack write permission.
      String? localCoverPath;
      if (coverUrl != null && coverUrl.isNotEmpty) {
        try {
          final coverResp = await http.get(Uri.parse(coverUrl), headers: api.mediaHeaders)
              .timeout(const Duration(seconds: 10));
          if (coverResp.statusCode == 200 && coverResp.bodyBytes.isNotEmpty) {
            final internalBase = await _internalBasePath;
            final coverDir = Directory('$internalBase/$itemId');
            if (!coverDir.existsSync()) coverDir.createSync(recursive: true);
            final coverFile = File('${coverDir.path}/cover.jpg');
            await coverFile.writeAsBytes(coverResp.bodyBytes);
            localCoverPath = coverFile.path;
            debugPrint('[Download] Cached cover image: $localCoverPath');
          }
        } catch (e) {
          debugPrint('[Download] Cover cache failed (non-fatal): $e');
        }
      }

      final localPaths = List<String?>.filled(audioTracks.length, null);
      _httpClient = http.Client();

      // Track progress per-track for overall calculation
      final trackProgress = List<double>.filled(audioTracks.length, 0.0);
      int _lastNotifPercent = -1;
      DateTime _lastUIUpdate = DateTime.now();

      void _updateProgress() {
        final overall = trackProgress.reduce((a, b) => a + b) / audioTracks.length;
        final now = DateTime.now();
        // Throttle UI updates to max ~4/sec
        if (now.difference(_lastUIUpdate).inMilliseconds > 250) {
          _lastUIUpdate = now;
          _downloads[itemId] = DownloadInfo(
            itemId: itemId,
            status: DownloadStatus.downloading,
            progress: overall,
            title: title,
            author: author,
            coverUrl: coverUrl,
          );
          notifyListeners();
        }
        // Throttle notification to every 2%
        final pct = (overall * 50).round();
        if (pct != _lastNotifPercent) {
          _lastNotifPercent = pct;
          unawaited(
            notif
                .showProgress(title: title, author: author, progress: overall)
                .catchError((Object e) {
              debugPrint('[Download] showProgress non-fatal error: $e');
            }),
          );
        }
      }

      Future<void> _downloadTrack(int i) async {
        final track = audioTracks[i] as Map<String, dynamic>;
        final contentUrl = track['contentUrl'] as String? ?? '';
        final fullUrl = api.buildTrackUrl(contentUrl);

        final mimeType = track['mimeType'] as String? ?? 'audio/mpeg';
        final ext = mimeType.contains('mp4')
            ? 'm4a'
            : mimeType.contains('flac')
                ? 'flac'
                : mimeType.contains('ogg')
                    ? 'ogg'
                    : 'mp3';

        final filePath =
            '${bookDir.path}/track_${i.toString().padLeft(3, '0')}.$ext';
        final file = File(filePath);

        debugPrint('[Download] Track ${i + 1}/${audioTracks.length}: $fullUrl');

        final request = http.Request('GET', Uri.parse(fullUrl));
        api.mediaHeaders.forEach((key, value) => request.headers[key] = value);
        final response = await _httpClient!.send(request)
            .timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode} for track ${i + 1}');
        }

        final totalBytes = response.contentLength ?? -1;
        int receivedBytes = 0;
        final sink = file.openWrite();

        await for (final chunk in response.stream.timeout(const Duration(seconds: 60))) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          trackProgress[i] = totalBytes > 0 ? receivedBytes / totalBytes : 0.5;
          _updateProgress();
        }

        await sink.close();
        localPaths[i] = filePath;
      }

      // Download tracks in parallel batches of 3
      const concurrency = 3;
      for (int batch = 0; batch < audioTracks.length; batch += concurrency) {
        final end = (batch + concurrency).clamp(0, audioTracks.length);
        await Future.wait([
          for (int i = batch; i < end; i++) _downloadTrack(i),
        ]);
      }

      // Final UI update
      _downloads[itemId] = DownloadInfo(
        itemId: itemId,
        status: DownloadStatus.downloading,
        progress: 1.0,
        title: title,
        author: author,
        coverUrl: coverUrl,
      );
      notifyListeners();

      final completedPaths = localPaths.whereType<String>().toList();

      final sessionId = sessionData['id'] as String?;
      if (sessionId != null) {
        try {
          await api.closePlaybackSession(sessionId);
        } catch (_) {}
      }

      _downloads[itemId] = DownloadInfo(
        itemId: itemId,
        status: DownloadStatus.downloaded,
        localPaths: completedPaths,
        sessionData: jsonEncode(sessionData),
        title: title,
        author: author,
        coverUrl: coverUrl,
        localCoverPath: localCoverPath,
      );
      await _save();
      notifyListeners();

      // Show completion notification
      try {
        await notif.showComplete(title: title);
      } catch (_) {}

      // If this book is currently streaming, hot-swap to local files
      try {
        final player = AudioPlayerService();
        if (player.currentItemId == itemId && player.hasBook) {
          await player.switchToLocal(itemId);
        }
      } catch (_) {}

      debugPrint('[Download] Complete: $title (${completedPaths.length} files)');
    } catch (e) {
      if (_cancelled) {
        debugPrint('[Download] Cancelled: $title');
        _downloads.remove(itemId);
        // Clean up partial files
        final basePath = await downloadBasePath;
        final bookDir = Directory('$basePath/$itemId');
        if (bookDir.existsSync()) bookDir.deleteSync(recursive: true);
      } else {
        debugPrint('[Download] Error: $e');
        _downloads[itemId] = DownloadInfo(
          itemId: itemId,
          status: DownloadStatus.error,
          title: title,
          author: author,
          coverUrl: coverUrl,
        );
        // Show error notification
        try {
          await notif.showError(title: title, message: 'Download failed: $title');
        } catch (notifErr) {
          debugPrint('[Download] showError non-fatal error: $notifErr');
        }
      }
    }

    _activeDownloadId = null;
    _httpClient = null;

    notifyListeners();
  }

  Future<void> deleteDownload(String itemId) async {
    final info = _downloads[itemId];
    if (info == null) return;

    for (final path in info.localPaths) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }

    try {
      final basePath = await downloadBasePath;
      final bookDir = Directory('$basePath/$itemId');
      if (bookDir.existsSync()) bookDir.deleteSync(recursive: true);
    } catch (_) {}

    _downloads.remove(itemId);
    await _save();
    notifyListeners();
  }

  void cancelDownload(String itemId) {
    if (_activeDownloadId == itemId) {
      _cancelled = true;
      _httpClient?.close();
      _httpClient = null;
      _activeDownloadId = null;
      unawaited(
        DownloadNotificationService().dismiss().catchError((Object e) {
          debugPrint('[Download] dismiss non-fatal error: $e');
        }),
      );
    }
    // Remove from queue if it was waiting
    _queue.removeWhere((q) => q.itemId == itemId);
    _downloads.remove(itemId);
    notifyListeners();
  }
}
