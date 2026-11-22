import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/overlay_toast.dart';
import 'api_service.dart';
import 'audio_locator.dart';
import 'audio_player_service.dart';
import 'ebook_cache.dart';
import 'ebook_history.dart';
import 'epub_book_text.dart';
import 'narration_service.dart';
import 'progress_sync_service.dart';
import 'scoped_prefs.dart';
import 'sync_point_store.dart';
import 'transcription_service.dart';

/// An EPUB file read with no reader open, as Find in audiobook's view of
/// the book.
class _FileBookText implements BookTextSource {
  _FileBookText(this.book);

  final EpubBookText book;

  @override
  Future<List<String>> spineHrefs() async => book.spine;

  @override
  String? chapterForHref(String href) => book.chapterForHref(href);

  @override
  Future<List<double>> sectionCharCounts(int from, int to) async => [
        for (var i = from; i <= to && i < book.spine.length; i++) book.sectionLength(i).toDouble(),
      ];

  @override
  Future<Map<String, dynamic>?> locateTranscriptInSection(int si, String transcript) async {
    final m = matchTranscript(book.sectionText(si), transcript);
    return m == null ? null : {'s': m.s, 'e': m.e, 'fine': m.fine};
  }
}

/// Where the words just heard are in the book, worked out in the background
/// isolate: the spot's CFI and place in the book, and where the saved ebook
/// spot [current] is, to compare.
typedef _Placed = ({
  String cfi,
  double fraction,
  int si,
  int offset,
  int? currentSi,
  int? currentOffset,
  double? currentFraction,
  String? currentChapter,
  bool narrated,
});

_Placed? _placeInBook(String path, String transcript, double near, String? current) {
  final book = EpubBookText.open(path);
  if (book == null) return null;
  try {
    final hit = book.findPassage(transcript, near: near);
    if (hit == null) return null;
    final cfi = book.cfiAt(hit.si, hit.e);
    if (cfi == null) return null;
    final now = current == null ? null : book.locate(current);
    return (
      cfi: cfi,
      fraction: book.fraction(hit.si, hit.e),
      si: hit.si,
      offset: hit.e,
      currentSi: now?.si,
      currentOffset: now?.offset,
      currentFraction: now == null ? null : book.fraction(now.si, now.offset),
      currentChapter: now == null || now.si >= book.spine.length ? null : book.chapterForHref(book.spine[now.si]),
      narrated: book.hasMediaOverlays,
    );
  } finally {
    book.close();
  }
}

/// Which side a sync is moving: the ebook to the audio, or the audio to the
/// page.
enum SyncTarget { ebook, audio }

/// Where the CFI [cfi] is in the book, worked out in the background isolate
/// (placing it in the whole book reads every section).
typedef _Spot = ({int si, int offset, int total, String href, double pct, bool narrated});

_Spot? _spotInBook(String path, String cfi) {
  final book = EpubBookText.open(path);
  if (book == null) return null;
  try {
    final at = book.locate(cfi);
    if (at == null) return null;
    return (
      si: at.si,
      offset: at.offset,
      total: book.sectionLength(at.si),
      href: at.si < book.spine.length ? book.spine[at.si] : '',
      pct: book.fraction(at.si, at.offset),
      narrated: book.hasMediaOverlays,
    );
  } finally {
    book.close();
  }
}

Future<_Placed?> _placeAsync(String path, String transcript, double near, String? current) =>
    Isolate.run(() => _placeInBook(path, transcript, near, current));

Future<_Spot?> _spotAsync(String path, String cfi) => Isolate.run(() => _spotInBook(path, cfi));

/// Keeps an audiobook and its separate ebook at the same spot, when the
/// setting is on. When listening stops (paused for a couple of minutes,
/// stopped, or another book started), the ebook moves to the words last
/// heard. When the reader closes after reading, the audiobook moves to the
/// page. Only ever forward, found by transcribing the audio the way Find in
/// ebook and Find in audiobook do, one book at a time, with a toast when the
/// app is on screen. An EPUB that narrates itself keeps the two together
/// already, so it is left alone.
class ReadListenSync {
  ReadListenSync._();
  static final ReadListenSync instance = ReadListenSync._();

  static const _stopWait = Duration(minutes: 2);

  Timer? _stopTimer;
  String? _item;
  bool _wasPlaying = false;
  bool _started = false;
  Future<void> _queue = Future.value();
  final Set<String> _readerOpen = {};
  final Map<String, Completer<double?>> _finding = {};
  final Map<String, DateTime> _playedAt = {};

  /// Books being synced right now, and which side is moving, for the details
  /// sheet to show.
  final ValueNotifier<Map<String, SyncTarget>> syncing = ValueNotifier(const {});

  /// Books whose last sync couldn't find the spot, and which side it was
  /// moving, for the details sheet to say so. Cleared by the next look at the
  /// book that finds its place, or finds nothing to move.
  final ValueNotifier<Map<String, SyncTarget>> failed = ValueNotifier(const {});

  void _setFailed(String itemId, SyncTarget? to) {
    final now = Map<String, SyncTarget>.from(failed.value);
    if (to == null) {
      if (now.remove(itemId) == null) return;
    } else {
      if (now[itemId] == to) return;
      now[itemId] = to;
    }
    failed.value = now;
  }

  void _setSyncing(String itemId, SyncTarget? to) {
    final now = Map<String, SyncTarget>.from(syncing.value);
    if (to == null) {
      if (now.remove(itemId) == null) return;
    } else {
      if (now[itemId] == to) return;
      now[itemId] = to;
    }
    syncing.value = now;
  }

  static String _heardKey(String itemId) => 'rls_heard_$itemId';
  static String _readKey(String itemId) => 'rls_read_$itemId';

  void start() {
    if (_started) return;
    _started = true;
    AudioPlayerService().addListener(_onPlayer);
  }

  void _onPlayer() {
    final p = AudioPlayerService();
    final id = p.hasBook && p.currentEpisodeId == null ? p.currentItemId : null;
    if (id != _item) {
      final left = _item;
      _item = id;
      _wasPlaying = false;
      _stopTimer?.cancel();
      _stopTimer = null;
      if (left != null) {
        debugPrint('[SyncSpot] $left: ${id == null ? 'playback stopped' : 'another book started'} - checking the ebook');
        _run(() => _audioToEbook(left));
      }
    }
    if (id == null) return;
    final playing = p.isPlaying;
    if (playing == _wasPlaying) return;
    _wasPlaying = playing;
    if (playing) _playedAt[id] = DateTime.now();
    _stopTimer?.cancel();
    _stopTimer = null;
    if (!playing) {
      _stopTimer = Timer(_stopWait, () {
        _stopTimer = null;
        final now = AudioPlayerService();
        if (_item == id && !now.isPlaying) {
          debugPrint('[SyncSpot] $id: paused for ${_stopWait.inMinutes} minutes - checking the ebook');
          _run(() => _audioToEbook(id));
        }
      });
    }
  }

  void _run(Future<void> Function() job) {
    _queue = _queue.then((_) => job()).catchError((Object e) {
      debugPrint('[SyncSpot] failed: $e');
    });
  }

  /// The reader shows this book now and keeps its own spot meanwhile.
  void readerOpened(String itemId) => _readerOpen.add(itemId);

  /// The reader closed on [cfi]; [moved] when pages were turned since it
  /// opened. Reading ahead of the audio moves the audio there.
  void readerClosed(String itemId, String? cfi, {required bool moved}) {
    _readerOpen.remove(itemId);
    if (cfi == null || cfi.isEmpty || !moved) return;
    debugPrint('[SyncSpot] $itemId: reader closed after reading - checking the audio');
    final done = _finding[itemId] = Completer<double?>();
    _run(() async {
      double? t;
      try {
        t = await _ebookToAudio(itemId, cfi);
      } finally {
        if (identical(_finding[itemId], done)) _finding.remove(itemId);
        done.complete(t);
      }
    });
  }

  /// The audio spot being found for [itemId] since its reader closed, for a
  /// play that should start there. Null when nothing is being found.
  Future<double?>? audioSpotBeingFound(String itemId) => _finding[itemId]?.future;

  /// For a reader opening while the audio is ahead: the ebook spot moved to
  /// the words last heard, or null when it stays put.
  Future<String?> ebookSpotForReader(String itemId) {
    final done = Completer<String?>();
    _run(() async {
      String? spot;
      try {
        spot = await _audioToEbook(itemId, fromReader: true);
      } finally {
        done.complete(spot);
      }
    });
    return done.future;
  }

  static ApiService? get _api {
    final ctx = rootNavigatorKey.currentContext;
    return ctx?.read<AuthProvider>().apiService ?? AudioPlayerService().currentApi;
  }

  static bool get _onScreen => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  static void _toast(String Function(AppLocalizations l) text, IconData icon, {VoidCallback? onTap}) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !_onScreen) return;
    final l = AppLocalizations.of(ctx);
    if (l != null) showOverlayToast(ctx, text(l), icon: icon, onTap: onTap);
  }

  static Future<bool> _canListen(String itemId, {bool manual = false}) async {
    if (!manual && !await PlayerSettings.getSyncReadingListening()) return false;
    final why = await _whyNot(itemId);
    if (why == null) return true;
    debugPrint('[SyncSpot] $itemId: ${why.log} - not syncing');
    return false;
  }

  /// Why [itemId] can't be synced by transcribing right now, for the log and
  /// to say on screen, or null when it can.
  static Future<({String log, String Function(AppLocalizations l) say})?> _whyNot(String itemId) async {
    if (!await PlayerSettings.getTranscriptionEnabled()) {
      return (log: 'transcription is off', say: (AppLocalizations l) => l.transcriptionDisabledHint);
    }
    final t = TranscriptionService.instance;
    if (!t.canTranscribeBook(itemId)) {
      return (log: 'this book can not be transcribed', say: (AppLocalizations l) => l.transcriptionNotDownloadedBook);
    }
    for (final size in TranscriptionModelSize.values) {
      if (await t.isModelDownloaded(size)) return null;
    }
    return (log: 'no transcription model downloaded', say: (AppLocalizations l) => l.transcriptionNoModelDownloaded);
  }

  /// The audiobook and ebook of [itemId], when it has both and isn't done.
  static Future<({Map<String, dynamic> item, Map<String, dynamic> ebook, double duration})?> _book(
      ApiService api, String itemId) async {
    final item = await api.getLibraryItem(itemId);
    if (item == null) return null;
    final media = item['media'] as Map<String, dynamic>? ?? const {};
    // A book whose audio is its EPUB's own narration keeps them together.
    if (media['narration'] != null) return null;
    final duration = (media['duration'] as num?)?.toDouble() ?? 0;
    final ebook = resolveEbookFile(item);
    if (duration <= 0 || ebook == null || ebookExtFromFile(ebook) != '.epub') return null;
    final progress = item['userMediaProgress'] as Map<String, dynamic>?;
    if (progress?['isFinished'] == true) return null;
    return (item: item, ebook: ebook, duration: duration);
  }

  static Future<double?> _heardAt(String itemId) async {
    final p = AudioPlayerService();
    if (p.currentItemId == itemId && p.currentEpisodeId == null) return p.position.inMilliseconds / 1000.0;
    final local = await ProgressSyncService().getLocal(itemId);
    return (local?['currentTime'] as num?)?.toDouble();
  }

  static Future<String?> _ebookSpot(ApiService api, String itemId) async {
    final pending = (await ProgressSyncService().getPendingEbookProgress())[itemId];
    final queued = pending?['loc'] as String?;
    if (queued != null && queued.startsWith('epubcfi(')) return queued;
    final ctx = rootNavigatorKey.currentContext;
    final local = ctx?.read<LibraryProvider>().getProgressData(itemId)?['ebookLocation'] as String?;
    try {
      final server = (await api.getEbookPosition(itemId))?['ebookLocation'] as String?;
      if (server != null && server.startsWith('epubcfi(')) return server;
    } catch (_) {}
    return local != null && local.startsWith('epubcfi(') ? local : null;
  }

  /// Listening stopped: the ebook spot moves to the words last heard, when
  /// those are past it. Returns the new spot. [manual] is the Sync position
  /// button: the setting isn't needed, and it looks again even when nothing
  /// was heard since the last look.
  Future<String?> _audioToEbook(String itemId, {bool fromReader = false, bool manual = false}) async {
    // Whether the words heard were placed in the ebook, once a look started.
    bool? found;
    try {
      if (!fromReader && _readerOpen.contains(itemId)) return null;
      if (!await _canListen(itemId, manual: manual)) return null;
      final api = _api;
      if (api == null) return null;
      final heard = await _heardAt(itemId);
      if (heard == null || heard < 30) return null;
      final last = await ScopedPrefs.getDouble(_heardKey(itemId));
      if (!manual && last != null && (heard - last).abs() < 20) return null;
      final book = await _book(api, itemId);
      if (book == null) return null;
      final started = DateTime.now();
      _setSyncing(itemId, SyncTarget.ebook);
      found = false;
      final title = ((book.item['media'] as Map?)?['metadata'] as Map?)?['title'] as String? ?? '';
      final epub = await NarrationService.instance.readerFile(api, itemId, book.ebook, title);
      final from = max(0.0, heard - 15);
      final segs = await TranscriptionService.instance.transcribeWindowSegments(
        itemId: itemId,
        startSeconds: from,
        windowSeconds: heard - from,
        preferAccuracy: false,
      );
      final transcript = segs.map((s) => s.text).join(' ').trim();
      if (transcript.split(RegExp(r'\s+')).length < 5) {
        debugPrint('[SyncSpot] $itemId: too few words heard at ${heard.toStringAsFixed(0)}s to place them');
        return null;
      }
      final current = await _ebookSpot(api, itemId);
      final near = (heard / book.duration).clamp(0.0, 1.0);
      final placed = await _placeAsync(epub.path, transcript, near, current);
      await ScopedPrefs.setDouble(_heardKey(itemId), heard);
      if (placed == null) {
        debugPrint('[SyncSpot] $itemId: the words at ${heard.toStringAsFixed(0)}s are not in the ebook');
        return null;
      }
      found = true;
      // BookOrbit moves a narrated EPUB along with the audiobook itself.
      if (placed.narrated && api.isBookOrbit) return null;
      final cs = placed.currentSi, co = placed.currentOffset;
      if (cs != null && co != null && (cs > placed.si || (cs == placed.si && co >= placed.offset))) {
        debugPrint('[SyncSpot] $itemId: the ebook is already at or past ${heard.toStringAsFixed(0)}s');
        return null;
      }
      if (current != null) {
        await EbookHistory.instance.record(itemId,
            cfi: current,
            reason: EbookSpotReason.beforeSync,
            progress: placed.currentFraction,
            chapter: placed.currentChapter);
      }
      await ProgressSyncService().pushEbookProgress(api, itemId, location: placed.cfi, progress: placed.fraction);
      rootNavigatorKey.currentContext
          ?.read<LibraryProvider>()
          .applyLocalEbookProgress(itemId, location: placed.cfi, progress: placed.fraction);
      await ScopedPrefs.setString(_readKey(itemId), placed.cfi);
      await SyncPointStore.instance.add(
        itemId,
        SyncPoint(t: heard, si: placed.si, off: placed.offset.toDouble(), src: 'e', err: 3,
            at: DateTime.now().millisecondsSinceEpoch),
        audioDuration: book.duration,
      );
      debugPrint('[SyncSpot] $itemId: ebook moved to ${heard.toStringAsFixed(0)}s '
          '(section ${placed.si}, ${(placed.fraction * 100).toStringAsFixed(1)}%) '
          'in ${DateTime.now().difference(started).inMilliseconds}ms');
      if (!fromReader) _toast((l) => l.syncEbookMoved, Icons.menu_book_rounded);
      return placed.cfi;
    } finally {
      _setSyncing(itemId, null);
      if (found != null) _setFailed(itemId, found ? null : SyncTarget.ebook);
    }
  }

  /// The reader closed after reading: the audiobook moves to the page, when
  /// the page is past it. Returns the new spot. [manual] is the Sync position
  /// button: the setting isn't needed, it looks again at a page it has seen,
  /// and it moves the audio even while it plays, since that was asked for.
  Future<double?> _ebookToAudio(String itemId, String cfi, {bool manual = false}) async {
    // Whether the page was found in the audio, once a look started.
    bool? found;
    try {
      final began = DateTime.now();
      if (!await _canListen(itemId, manual: manual)) return null;
      if (!manual && await ScopedPrefs.getString(_readKey(itemId)) == cfi) return null;
      final api = _api;
      if (api == null) return null;
      final player = AudioPlayerService();
      if (!manual && player.currentItemId == itemId && player.currentEpisodeId == null && player.isPlaying) {
        return null;
      }
      final heard = await _heardAt(itemId) ?? 0;
      final book = await _book(api, itemId);
      if (book == null) return null;
      final title = ((book.item['media'] as Map?)?['metadata'] as Map?)?['title'] as String? ?? '';
      final file = await NarrationService.instance.readerFile(api, itemId, book.ebook, title);
      if (!file.existsSync()) return null;
      final spot = await _spotAsync(file.path, cfi);
      if (spot == null) {
        debugPrint('[SyncSpot] $itemId: the saved page is not in this ebook');
        found = false;
        return null;
      }
      if (spot.narrated && api.isBookOrbit) return null;
      final text = EpubBookText.open(file.path);
      if (text == null) return null;
      try {
        final info = <String, dynamic>{
          'si': spot.si,
          'offset': spot.offset,
          'total': spot.total,
          'href': spot.href,
          'pct': spot.pct,
        };
        await ScopedPrefs.setString(_readKey(itemId), cfi);
        final locator = AudioLocator(itemId, _FileBookText(text));
        // Nothing is transcribed while the page is plainly behind the audio.
        final rough = await locator.estimate(info, api);
        final guess = rough?.est ?? (info['pct'] as double) * book.duration;
        if (guess <= heard + 60) {
          debugPrint('[SyncSpot] $itemId: the page (about ${guess.toStringAsFixed(0)}s) '
              'is not ahead of the audio (${heard.toStringAsFixed(0)}s)');
          found = true;
          return null;
        }
        final started = DateTime.now();
        _setSyncing(itemId, SyncTarget.audio);
        found = false;
        final t = await locator.locate(info, api);
        if (t == null) {
          debugPrint('[SyncSpot] $itemId: the page was not found in the audio');
          return null;
        }
        found = true;
        if (t <= heard + 15) return null;
        final now = AudioPlayerService();
        final inPlayer = now.currentItemId == itemId && now.currentEpisodeId == null;
        // Playback started while this was being found: the audio is never moved
        // under it. The spot is offered instead.
        if (!manual && ((_playedAt[itemId]?.isAfter(began) ?? false) || (inPlayer && now.isPlaying))) {
          debugPrint('[SyncSpot] $itemId: found ${t.toStringAsFixed(0)}s after playback started - offering it');
          _toast((l) => l.syncAudioOffer, Icons.headphones_rounded, onTap: () {
            final p = AudioPlayerService();
            if (p.currentItemId == itemId) unawaited(p.seekTo(Duration(milliseconds: (t * 1000).round())));
          });
          return null;
        }
        if (inPlayer) {
          await now.seekTo(Duration(milliseconds: (t * 1000).round()));
        } else {
          final local = await ProgressSyncService().getLocal(itemId);
          await ProgressSyncService().saveLocal(
            itemId: itemId,
            currentTime: t,
            duration: book.duration,
            speed: (local?['speed'] as num?)?.toDouble() ?? 1.0,
          );
          try {
            await api.updateProgress(itemId, currentTime: t, duration: book.duration);
          } catch (e) {
            debugPrint('[SyncSpot] $itemId: audio spot not sent: $e');
          }
        }
        await ScopedPrefs.setDouble(_heardKey(itemId), t);
        debugPrint('[SyncSpot] $itemId: audio moved ${heard.toStringAsFixed(0)}s -> '
            '${t.toStringAsFixed(0)}s in ${DateTime.now().difference(started).inMilliseconds}ms');
        _toast((l) => l.syncAudioMoved, Icons.headphones_rounded);
        return t;
      } finally {
        text.close();
      }
    } finally {
      _setSyncing(itemId, null);
      if (found != null) _setFailed(itemId, found ? null : SyncTarget.audio);
    }
  }

  /// The Sync position button, for when the automatic sync is off: whichever
  /// of the audio and the ebook is behind moves up to the other, and a toast
  /// says how it went.
  Future<void> syncNow(String itemId) {
    final done = Completer<void>();
    _run(() async {
      try {
        await _syncNow(itemId);
      } finally {
        done.complete();
      }
    });
    return done.future;
  }

  Future<void> _syncNow(String itemId) async {
    final why = await _whyNot(itemId);
    if (why != null) {
      debugPrint('[SyncSpot] $itemId: sync asked for, but ${why.log}');
      _toast(why.say, Icons.record_voice_over_rounded);
      return;
    }
    final api = _api;
    if (api == null) return;
    debugPrint('[SyncSpot] $itemId: sync asked for');
    _setFailed(itemId, null);
    // The page first: when it is ahead, the audio moves up to it.
    final cfi = await _ebookSpot(api, itemId);
    if (cfi != null && await _ebookToAudio(itemId, cfi, manual: true) != null) return;
    if (!failed.value.containsKey(itemId) && await _audioToEbook(itemId, manual: true) != null) return;
    if (failed.value.containsKey(itemId)) {
      _toast((l) => l.syncFailed, Icons.sync_problem_rounded);
      return;
    }
    _toast((l) => l.syncAlreadyTogether, Icons.check_rounded);
  }

}
