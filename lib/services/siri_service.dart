import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'android_auto_service.dart';
import 'api_service.dart';
import 'audio_player_service.dart';
import 'download_service.dart';
import 'home_widget_service.dart';
import 'progress_sync_service.dart';
import 'siri_matcher.dart';
import 'sleep_timer_service.dart';

/// Siri on iOS. Native code forwards the media intent ("Play Dune on Absorb")
/// and the App Shortcuts here; this side picks the book, plays it, keeps the
/// list of books Siri can name in the app group, and tells Siri what gets
/// played so it learns the listener's books.
class SiriService {
  static final SiriService _instance = SiriService._();
  factory SiriService() => _instance;
  SiriService._();

  static const _channel = MethodChannel('com.absorb.siri');
  static const _widgetChannel = MethodChannel('com.absorb.widget');
  static const catalogFileName = 'siri_catalog.json';

  /// Items the library screens have loaded (Absorbing, home shelves of every
  /// library opened). Set by LibraryProvider.
  static Iterable<Map<String, dynamic>> Function()? libraryItems;

  bool _initialized = false;
  List<SiriEntry> _catalog = const [];
  bool _catalogLoaded = false;
  Timer? _catalogTimer;
  bool _rebuilding = false;
  bool _askedAutoRefresh = false;
  String? _lastPlayKey;
  Map<String, Map<String, dynamic>> _progress = const {};
  DateTime? _progressAt;

  Future<void> init() async {
    if (_initialized || !Platform.isIOS) return;
    _initialized = true;
    _channel.setMethodCallHandler(_onCall);
    try {
      await _channel.invokeMethod('ready');
    } catch (e) {
      debugPrint('[Siri] ready failed: $e');
    }
    AudioPlayerService().addListener(_onPlayerChanged);
    AndroidAutoService.serverDataListeners.add(scheduleCatalogUpdate);
    scheduleCatalogUpdate(delay: const Duration(seconds: 8));
  }

  Future<dynamic> _onCall(MethodCall call) async {
    final args = (call.arguments as Map?) ?? const {};
    try {
      switch (call.method) {
        case 'resolve':
          return await _resolve(SiriQuery.fromArgs(args));
        case 'play':
          return await _play(args);
        case 'control':
          return await _control(args);
      }
    } catch (e) {
      debugPrint('[Siri] ${call.method} failed: $e');
      return {'ok': false, 'status': 'none', 'items': const []};
    }
    return null;
  }

  // Resolving

  Future<Map<String, dynamic>> _resolve(SiriQuery q) async {
    debugPrint('[Siri] resolve name="${q.name}" artist="${q.artist}" type=${q.type} latest=${q.latest}');
    if (q.isResume) return _resumeTarget();
    await _ensureCatalogLoaded();
    var result = siriMatch(q, _catalog);
    if (result.status != 'ok' || result.score < 85 || result.viaSeries) {
      final found = await _searchServer(q)
          .timeout(const Duration(seconds: 5), onTimeout: () => const <SiriEntry>[]);
      if (found.isNotEmpty) {
        final again = siriMatch(q, _merge(_catalog, found));
        if (again.status != 'none' && (result.status == 'none' || again.score >= result.score)) {
          result = again;
        }
      }
    }
    if (result.status == 'none' && await AndroidAutoService().getApi() == null) {
      return {'status': 'signedOut', 'items': const []};
    }
    debugPrint('[Siri] resolve -> ${result.status}: ${result.items.map((e) => e.title).join(' | ')}');
    return {'status': result.status, 'items': result.items.map(_itemJson).toList()};
  }

  Map<String, dynamic> _itemJson(SiriEntry e) => {
        'id': e.id,
        'kind': e.kind,
        'title': e.title,
        'author': e.author,
        if (e.coverPath != null) 'coverPath': e.coverPath,
      };

  Future<Map<String, dynamic>> _resumeTarget() async {
    final player = AudioPlayerService();
    if (player.hasBook) {
      return {
        'status': 'ok',
        'items': [
          {'id': 'resume', 'kind': 'book', 'title': player.currentTitle ?? '', 'author': player.currentAuthor ?? ''},
        ],
      };
    }
    final prefs = await SharedPreferences.getInstance();
    final itemId = prefs.getString('widget_item_id');
    if (itemId == null) return {'status': 'none', 'items': const []};
    final episodeId = prefs.getString('widget_episode_id');
    final key = episodeId != null ? '$itemId-$episodeId' : itemId;
    if (HomeWidgetService.lastPlayedIsFinished(await ProgressSyncService().getLocal(key))) {
      return {'status': 'none', 'items': const []};
    }
    String? title, author;
    try {
      title = await HomeWidget.getWidgetData<String>('np_title');
      author = await HomeWidget.getWidgetData<String>('np_author');
    } catch (_) {}
    return {
      'status': 'ok',
      'items': [
        {'id': 'resume', 'kind': episodeId != null ? 'episode' : 'book', 'title': title ?? '', 'author': author ?? ''},
      ],
    };
  }

  List<SiriEntry> _merge(List<SiriEntry> known, List<SiriEntry> found) {
    final byId = {for (final e in known) e.id: e};
    for (final e in found) {
      final had = byId[e.id];
      byId[e.id] = had == null
          ? e
          : had.copyWith(series: had.series.isEmpty ? e.series : had.series);
    }
    return byId.values.toList();
  }

  Future<List<SiriEntry>> _searchServer(SiriQuery q) async {
    final text = (q.name?.trim().isNotEmpty == true ? q.name! : q.artist ?? '').trim();
    if (text.isEmpty) return const [];
    final api = await AndroidAutoService().getApi();
    if (api == null) return const [];
    final libraries = await _libraries(api);
    final wantBooks = q.type == 'book' || q.type == 'any';
    final wantPodcasts = q.type != 'book';
    final out = <SiriEntry>[];
    await Future.wait(libraries.where((l) => l.isPodcast ? wantPodcasts : wantBooks).map((lib) async {
      final res = await api.searchLibrary(lib.id, text, limit: 10);
      if (res == null) return;
      for (final key in ['book', 'podcast']) {
        for (final hit in (res[key] as List<dynamic>? ?? const [])) {
          final item = (hit is Map ? hit['libraryItem'] : null) as Map<String, dynamic>?;
          final e = item == null ? null : entryFromItem(item, libraryId: lib.id);
          if (e != null) out.add(e);
        }
      }
      for (final hit in (res['series'] as List<dynamic>? ?? const [])) {
        if (hit is! Map) continue;
        final series = hit['series'] as Map<String, dynamic>?;
        final id = series?['id'] as String?;
        final name = series?['name'] as String?;
        if (id != null && name != null && name.isNotEmpty) {
          out.add(SiriEntry(kind: 'series', itemId: id, libraryId: lib.id, title: name));
        }
        for (final b in (hit['books'] as List<dynamic>? ?? const [])) {
          final e = b is Map<String, dynamic> ? entryFromItem(b, libraryId: lib.id) : null;
          if (e != null) out.add(e);
        }
      }
    }));
    debugPrint('[Siri] server search "$text" -> ${out.length} results');
    return _withProgress(out, api: api);
  }

  Future<List<AutoLibraryEntry>> _libraries(ApiService api) async {
    final known = AndroidAutoService().libraries;
    if (known.isNotEmpty) return known;
    final libs = await api.getLibraries();
    return [
      for (final l in libs.whereType<Map<String, dynamic>>())
        if (l['id'] is String)
          AutoLibraryEntry(
            id: l['id'] as String,
            name: l['name'] as String? ?? '',
            mediaType: l['mediaType'] as String? ?? 'book',
          ),
    ];
  }

  // Playing

  Future<Map<String, dynamic>> _play(Map<dynamic, dynamic> args) async {
    final id = args['id'] as String? ?? 'resume';
    final speed = (args['speed'] as num?)?.toDouble();
    final latest = args['latest'] == true;
    debugPrint('[Siri] play $id speed=$speed latest=$latest');
    final parts = id.split('|');
    String part(int i) => parts.length > i ? parts[i] : '';
    var ok = false;
    switch (parts.first) {
      case 'book':
        ok = await _playItem(part(1), null);
      case 'episode':
        ok = await _playItem(part(1), part(2).isEmpty ? null : part(2));
      case 'podcast':
        ok = await _playPodcast(part(1), latest: latest);
      case 'series':
        ok = await _playSeries(part(1), part(2));
      default:
        ok = await _resume();
    }
    final player = AudioPlayerService();
    if (ok && speed != null && speed > 0) {
      await player.setSpeed(speed.clamp(0.5, 5.0).toDouble());
    }
    debugPrint('[Siri] play $id -> ok=$ok "${player.currentTitle}"');
    return {'ok': ok, 'title': player.currentTitle ?? '', 'author': player.currentAuthor ?? ''};
  }

  Future<bool> _resume() async {
    final player = AudioPlayerService();
    if (player.hasBook) {
      if (!player.isPlaying) await player.play();
      return true;
    }
    await HomeWidgetService().resumeLastPlayedIfAvailable();
    return player.hasBook;
  }

  Future<bool> _playItem(String itemId, String? episodeId) async {
    if (itemId.isEmpty) return false;
    final player = AudioPlayerService();
    if (player.hasBook && player.currentItemId == itemId && player.currentEpisodeId == episodeId) {
      if (!player.isPlaying) await player.play();
      return true;
    }
    final handler = AudioPlayerService.handler;
    if (handler == null) return false;
    final key = episodeId == null ? itemId : '$itemId-$episodeId';
    await handler.playFromMediaId(AutoMediaIds.itemId(key));
    return player.currentItemId == itemId && player.currentEpisodeId == episodeId;
  }

  /// The episode the listener is partway through, or else the newest one
  /// not finished. "The latest episode of" always takes the newest.
  Future<bool> _playPodcast(String showId, {bool latest = false}) async {
    final api = await AndroidAutoService().getApi();
    if (api == null) return false;
    final item = await api.getLibraryItem(showId);
    final episodes = ((item?['media'] as Map<String, dynamic>?)?['episodes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (episodes.isEmpty) return false;
    int published(Map<String, dynamic> e) =>
        (e['publishedAt'] as num?)?.toInt() ?? (e['addedAt'] as num?)?.toInt() ?? 0;
    episodes.sort((a, b) => published(b).compareTo(published(a)));
    final progress = await _progressMap(api);
    Map<String, dynamic>? state(Map<String, dynamic> e) => progress['$showId-${e['id']}'];
    var pick = episodes.first;
    if (!latest) {
      final going = episodes.where((e) => _isGoing(state(e))).toList()
        ..sort((a, b) => _lastUpdate(state(b)).compareTo(_lastUpdate(state(a))));
      pick = going.isNotEmpty
          ? going.first
          : episodes.firstWhere((e) => state(e)?['isFinished'] != true, orElse: () => episodes.first);
    }
    final episodeId = pick['id'] as String?;
    if (episodeId == null) return false;
    return _playItem(showId, episodeId);
  }

  /// The book in the series the listener is on, or else the first unfinished.
  Future<bool> _playSeries(String seriesId, String libraryId) async {
    final api = await AndroidAutoService().getApi();
    if (api == null) return false;
    final books = (await api.getAllBooksBySeries(libraryId, seriesId)).whereType<Map<String, dynamic>>().toList();
    if (books.isEmpty) return false;
    final progress = await _progressMap(api);
    Map<String, dynamic>? state(Map<String, dynamic> b) => progress[b['id']];
    final going = books.where((b) => _isGoing(state(b))).toList()
      ..sort((a, b) => _lastUpdate(state(b)).compareTo(_lastUpdate(state(a))));
    final pick = going.isNotEmpty
        ? going.first
        : books.firstWhere((b) => state(b)?['isFinished'] != true, orElse: () => books.first);
    final id = pick['id'] as String?;
    return id != null && await _playItem(id, null);
  }

  static bool _isGoing(Map<String, dynamic>? p) =>
      p != null && p['isFinished'] != true && ((p['progress'] as num?) ?? 0) > 0;

  static int _lastUpdate(Map<String, dynamic>? p) => (p?['lastUpdate'] as num?)?.toInt() ?? 0;

  Future<Map<String, Map<String, dynamic>>> _progressMap(ApiService api) async {
    final at = _progressAt;
    if (at != null && DateTime.now().difference(at) < const Duration(minutes: 2)) return _progress;
    final list = await api.getAllProgress();
    if (list == null) return _progress;
    _progress = {
      for (final p in list)
        if (p['libraryItemId'] is String)
          (p['episodeId'] is String && (p['episodeId'] as String).isNotEmpty)
              ? '${p['libraryItemId']}-${p['episodeId']}'
              : p['libraryItemId'] as String: p,
    };
    _progressAt = DateTime.now();
    return _progress;
  }

  // App Shortcuts

  Future<Map<String, dynamic>> _control(Map<dynamic, dynamic> args) async {
    final action = args['action'] as String? ?? '';
    final player = AudioPlayerService();
    final handler = AudioPlayerService.handler;
    debugPrint('[Siri] control $action hasBook=${player.hasBook}');
    var ok = player.hasBook;
    switch (action) {
      case 'resume':
        ok = await _resume();
      case 'pause':
        if (ok) await player.pause();
      case 'skipBack':
        if (ok) await handler?.rewind();
      case 'skipForward':
        if (ok) await handler?.fastForward();
      case 'nextChapter':
        if (ok) await handler?.customAction('nextChapter');
      case 'previousChapter':
        if (ok) await handler?.customAction('previousChapter');
      case 'sleepMinutes':
        final minutes = (args['minutes'] as num?)?.toInt() ?? 0;
        ok = ok && minutes > 0;
        if (ok) SleepTimerService().setTimeSleep(Duration(minutes: minutes));
      case 'sleepChapterEnd':
        if (ok) SleepTimerService().setChapterSleep(1);
      case 'cancelSleep':
        ok = SleepTimerService().isActive;
        if (ok) SleepTimerService().cancelByUser();
      case 'bookmark':
        ok = ok && (await handler?.customAction('bookmark')) == true;
      case 'status':
        break;
      default:
        ok = false;
    }
    final position = player.position.inSeconds;
    final duration = player.totalDuration.round();
    return {
      'ok': ok,
      'hasBook': player.hasBook,
      'playing': player.isPlaying,
      'title': player.currentTitle ?? '',
      'author': player.currentAuthor ?? '',
      'chapter': player.currentChapter?['title'] as String? ?? '',
      'position': position,
      'duration': duration,
      'speed': player.speed,
    };
  }

  // What Siri learns

  void _onPlayerChanged() {
    final player = AudioPlayerService();
    if (!player.hasBook || !player.isPlaying) return;
    final key = '${player.currentItemId}|${player.currentEpisodeId ?? ''}';
    if (key == _lastPlayKey) return;
    _lastPlayKey = key;
    unawaited(_donate(player));
    scheduleCatalogUpdate(delay: const Duration(seconds: 30));
  }

  Future<void> _donate(AudioPlayerService player) async {
    final itemId = player.currentItemId;
    if (itemId == null) return;
    final episodeId = player.currentEpisodeId;
    final key = episodeId == null ? itemId : '$itemId-$episodeId';
    final download = DownloadService().isDownloaded(key) ? DownloadService().getInfo(key) : null;
    final entry = SiriEntry(
      kind: episodeId == null ? 'book' : 'episode',
      itemId: itemId,
      episodeId: episodeId,
      title: player.currentTitle ?? '',
      author: player.currentAuthor ?? '',
      coverPath: download?.localCoverPath,
    );
    if (entry.title.isEmpty) return;
    try {
      await _channel.invokeMethod('donate', _itemJson(entry));
    } catch (e) {
      debugPrint('[Siri] donate failed: $e');
    }
  }

  // The list of books Siri can name

  void scheduleCatalogUpdate({Duration delay = const Duration(seconds: 5)}) {
    if (!_initialized) return;
    _catalogTimer?.cancel();
    _catalogTimer = Timer(delay, () => unawaited(_rebuildCatalog()));
  }

  Future<void> _ensureCatalogLoaded() async {
    if (_catalogLoaded) return;
    _catalogLoaded = true;
    if (_catalog.isNotEmpty) return;
    try {
      final file = await _catalogFile();
      if (file == null || !file.existsSync()) return;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _catalog = (data['entries'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SiriEntry.fromJson)
          .toList();
      debugPrint('[Siri] loaded ${_catalog.length} entries from the last run');
    } catch (e) {
      debugPrint('[Siri] catalog read failed: $e');
    }
  }

  Future<File?> _catalogFile() async {
    try {
      final dir = await _widgetChannel.invokeMethod<String>('getGroupContainerPath');
      if (dir == null) return null;
      return File('$dir/$catalogFileName');
    } catch (_) {
      return null;
    }
  }

  Future<void> _rebuildCatalog() async {
    if (_rebuilding) return;
    _rebuilding = true;
    if (!_askedAutoRefresh) {
      // On iOS the car's browse lists only fill when CarPlay connects; one
      // refresh a launch gives Siri every library's Continue and Recent rows.
      // It calls back through serverDataListeners when the server answers.
      _askedAutoRefresh = true;
      unawaited(AndroidAutoService().refresh());
    }
    try {
      final entries = <String, SiriEntry>{};
      void add(SiriEntry? e) {
        if (e == null || e.title.isEmpty) return;
        final had = entries[e.id];
        if (had == null) {
          entries[e.id] = e;
        } else if (had.series.isEmpty && e.series.isNotEmpty) {
          entries[e.id] = had.copyWith(series: e.series);
        }
      }

      for (final item in libraryItems?.call() ?? const <Map<String, dynamic>>[]) {
        if (item['books'] is List && item['name'] is String) {
          final books = (item['books'] as List).whereType<Map<String, dynamic>>().toList();
          final libraryId = item['libraryId'] as String? ??
              (books.isNotEmpty ? books.first['libraryId'] as String? : null);
          if (item['id'] is String && libraryId != null) {
            add(SiriEntry(kind: 'series', itemId: item['id'] as String, libraryId: libraryId, title: item['name'] as String));
          }
          for (final b in books) {
            add(entryFromItem(b));
          }
          continue;
        }
        add(entryFromItem(item));
        add(_episodeFromItem(item));
      }
      final auto = AndroidAutoService();
      for (final e in [...auto.continueListening, ...auto.recentlyAdded, ...auto.downloaded]) {
        add(_entryFromAuto(e));
      }
      final downloads = DownloadService();
      final downloadedKeys = <String>{};
      for (final d in downloads.downloadedItems) {
        downloadedKeys.add(d.itemId);
        add(_entryFromDownload(d));
      }

      var list = entries.values.map((e) {
        final key = e.episodeId == null ? e.itemId : '${e.itemId}-${e.episodeId}';
        if (!downloadedKeys.contains(key)) return e;
        final info = downloads.getInfo(key);
        return e.copyWith(downloaded: true, coverPath: e.coverPath ?? info.localCoverPath);
      }).toList();
      final api = await auto.getApi();
      list = await _withProgress(list, api: api);
      _catalog = list;
      _catalogLoaded = true;
      await _publishCatalog(list);
    } catch (e) {
      debugPrint('[Siri] catalog rebuild failed: $e');
    } finally {
      _rebuilding = false;
    }
  }

  Future<List<SiriEntry>> _withProgress(List<SiriEntry> list, {ApiService? api}) async {
    final progress = api == null ? _progress : await _progressMap(api);
    if (progress.isEmpty) return list;
    final showLatest = <String, Map<String, dynamic>>{};
    for (final p in progress.values) {
      if (p['episodeId'] is! String) continue;
      final show = p['libraryItemId'] as String;
      if (_lastUpdate(p) > _lastUpdate(showLatest[show])) showLatest[show] = p;
    }
    return list.map((e) {
      final key = e.kind == 'episode' ? '${e.itemId}-${e.episodeId}' : e.itemId;
      final p = e.kind == 'podcast' ? showLatest[e.itemId] : progress[key];
      if (p == null) return e;
      return e.copyWith(
        progress: ((p['progress'] as num?) ?? 0).toDouble(),
        finished: e.kind != 'podcast' && p['isFinished'] == true,
        lastPlayed: _lastUpdate(p),
      );
    }).toList();
  }

  Future<void> _publishCatalog(List<SiriEntry> list) async {
    final ordered = [...list]..sort((a, b) {
        final r = (b.inProgress ? 1 : 0).compareTo(a.inProgress ? 1 : 0);
        if (r != 0) return r;
        return b.lastPlayed.compareTo(a.lastPlayed);
      });
    final file = await _catalogFile();
    if (file != null) {
      try {
        await file.writeAsString(jsonEncode({
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'entries': ordered.take(20000).map((e) => e.toJson()).toList(),
        }));
      } catch (e) {
        debugPrint('[Siri] catalog write failed: $e');
      }
    }
    List<String> unique(Iterable<String> values, int cap) {
      final seen = <String>{};
      final out = <String>[];
      for (final v in values) {
        final t = v.trim();
        if (t.isEmpty || !seen.add(t.toLowerCase())) continue;
        out.add(t);
        if (out.length == cap) break;
      }
      return out;
    }

    final books = ordered.where((e) => e.kind == 'book');
    final titles = unique(books.map((e) => e.title), 500);
    final authors = unique(books.expand((e) => e.author.split(RegExp(r',|&'))), 200);
    final series = unique(ordered.expand((e) => e.kind == 'series' ? [e.title] : e.series), 200);
    final shows = unique(ordered.where((e) => e.kind == 'podcast').map((e) => e.title), 100);
    final upNext = ordered.where((e) => e.inProgress && e.kind != 'series').take(5).map(_itemJson).toList();
    debugPrint('[Siri] catalog ${ordered.length} entries, ${titles.length} titles, '
        '${authors.length} authors, ${shows.length} shows');
    try {
      await _channel.invokeMethod('catalogUpdated', {
        'count': ordered.length,
        'titles': [...titles, ...series],
        'authors': authors,
        'shows': shows,
        'upNext': upNext,
      });
    } catch (e) {
      debugPrint('[Siri] catalogUpdated failed: $e');
    }
    await _maybeAskForSiri(ordered.isNotEmpty);
  }

  // Siri permission

  Future<String> authorizationStatus() async {
    if (!Platform.isIOS) return 'unsupported';
    try {
      return await _channel.invokeMethod<String>('authorizationStatus') ?? 'notDetermined';
    } catch (_) {
      return 'notDetermined';
    }
  }

  Future<String> requestAuthorization() async {
    if (!Platform.isIOS) return 'unsupported';
    try {
      final status = await _channel.invokeMethod<String>('requestAuthorization') ?? 'notDetermined';
      if (status == 'authorized') scheduleCatalogUpdate(delay: Duration.zero);
      return status;
    } catch (_) {
      return 'notDetermined';
    }
  }

  Future<void> openSystemSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } catch (_) {}
  }

  /// One prompt, the first time there is something to ask Siri about and the
  /// listener is looking at the app. Settings has the switch after that.
  Future<void> _maybeAskForSiri(bool hasBooks) async {
    if (!hasBooks) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('siri_auth_asked') == true) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    if (await authorizationStatus() != 'notDetermined') {
      await prefs.setBool('siri_auth_asked', true);
      return;
    }
    await prefs.setBool('siri_auth_asked', true);
    await requestAuthorization();
  }

  // Item shapes

  /// A book or podcast show from an Audiobookshelf-shaped library item.
  static SiriEntry? entryFromItem(Map<String, dynamic> item, {String? libraryId}) {
    final id = item['id'] as String?;
    final media = item['media'] as Map<String, dynamic>?;
    final meta = media?['metadata'] as Map<String, dynamic>?;
    final title = meta?['title'] as String?;
    if (id == null || media == null || title == null || title.trim().isEmpty) return null;
    final podcast = item['mediaType'] == 'podcast';
    if (!podcast && !_hasAudio(media)) return null;
    return SiriEntry(
      kind: podcast ? 'podcast' : 'book',
      itemId: id,
      libraryId: item['libraryId'] as String? ?? libraryId,
      title: title.trim(),
      author: podcast ? (meta?['author'] as String? ?? '') : _authorOf(meta!),
      series: podcast ? const [] : _seriesOf(meta!),
    );
  }

  static SiriEntry? _episodeFromItem(Map<String, dynamic> item) {
    final ep = item['recentEpisode'] as Map<String, dynamic>?;
    final id = item['id'] as String?;
    final episodeId = ep?['id'] as String?;
    final title = ep?['title'] as String?;
    if (id == null || episodeId == null || title == null || title.isEmpty) return null;
    final show = ((item['media'] as Map<String, dynamic>?)?['metadata'] as Map<String, dynamic>?)?['title'] as String?;
    return SiriEntry(
      kind: 'episode',
      itemId: id,
      episodeId: episodeId,
      libraryId: item['libraryId'] as String?,
      title: title,
      author: show ?? '',
    );
  }

  static bool _hasAudio(Map<String, dynamic> media) {
    if (media['narration'] != null) return true;
    for (final k in ['numTracks', 'numAudioFiles']) {
      final n = media[k];
      if (n is num) return n > 0;
    }
    for (final k in ['tracks', 'audioFiles']) {
      final l = media[k];
      if (l is List) return l.isNotEmpty;
    }
    final d = media['duration'];
    if (d is num) return d > 0;
    return true;
  }

  static String _authorOf(Map<String, dynamic> meta) {
    final name = meta['authorName'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return (meta['authors'] as List<dynamic>? ?? const [])
        .map((a) => a is Map ? a['name'] as String? ?? '' : '$a')
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  static final _seriesNumber = RegExp(r'\s+#\s*[\d.]+.*$');

  static List<String> _seriesOf(Map<String, dynamic> meta) {
    final list = meta['series'];
    if (list is List) {
      final names = list
          .map((s) => s is Map ? s['name'] as String? ?? '' : '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names;
    }
    final joined = meta['seriesName'] as String?;
    if (joined == null || joined.isEmpty) return const [];
    return joined
        .split(', ')
        .map((s) => s.replaceFirst(_seriesNumber, '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static SiriEntry? _entryFromAuto(AutoBookEntry e) {
    if (e.title.isEmpty) return null;
    if (e.mediaType == 'podcast' && e.episodeId != null) {
      final show = e.showId ?? (e.id.length > 36 ? e.id.substring(0, 36) : e.id);
      return SiriEntry(
        kind: 'episode',
        itemId: show,
        episodeId: e.episodeId,
        libraryId: e.libraryId,
        title: e.title,
        author: e.author,
      );
    }
    return SiriEntry(
      kind: e.mediaType == 'podcast' ? 'podcast' : 'book',
      itemId: e.id,
      libraryId: e.libraryId,
      title: e.title,
      author: e.author,
    );
  }

  static SiriEntry? _entryFromDownload(DownloadInfo d) {
    final title = d.title;
    if (title == null || title.isEmpty) return null;
    final key = d.itemId;
    final episode = key.length > 37 && key[36] == '-';
    return SiriEntry(
      kind: episode ? 'episode' : 'book',
      itemId: episode ? key.substring(0, 36) : key,
      episodeId: episode ? key.substring(37) : null,
      libraryId: d.libraryId,
      title: title,
      author: d.author ?? '',
      downloaded: true,
      coverPath: d.localCoverPath,
    );
  }
}
