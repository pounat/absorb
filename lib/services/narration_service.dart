import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';
import 'audio_file_duration.dart';
import 'audio_player_service.dart';
import 'download_service.dart';
import 'ebook_cache.dart';
import 'epub_book_text.dart';
import 'media_overlay.dart';
import 'narrated_books.dart';
import 'remote_zip.dart';
import 'scoped_prefs.dart';

Future<MediaOverlay?> _parseEpub(String path) async {
  final input = InputFileStream(path);
  try {
    return await MediaOverlay.fromEpub(ZipDecoder().decodeStream(input));
  } catch (e) {
    debugPrint('[Narration] reading $path failed: $e');
    return null;
  } finally {
    input.closeSync();
  }
}

List<String> _extract(({String epub, String dir, List<String> hrefs, List<String> names}) job) {
  final input = InputFileStream(job.epub);
  try {
    final archive = ZipDecoder().decodeStream(input);
    Directory(job.dir).createSync(recursive: true);
    final out = <String>[];
    for (var i = 0; i < job.hrefs.length; i++) {
      final entry = archive.findFile(job.hrefs[i]);
      if (entry == null) throw StateError('${job.hrefs[i]} is not in the EPUB');
      final path = '${job.dir}/${job.names[i]}';
      final file = File(path);
      if (!(file.existsSync() && file.lengthSync() == entry.size)) {
        final output = OutputFileStream(path);
        try {
          entry.writeContent(output);
        } finally {
          output.closeSync();
        }
      }
      out.add(path);
    }
    return out;
  } finally {
    input.closeSync();
  }
}

/// A copy of the EPUB at [from] without the files in [skip], written to [to]:
/// the narrated book as the reader opens it, light enough to load.
void _copyWithout(({String from, String to, List<String> skip}) job) {
  final input = InputFileStream(job.from);
  final part = '${job.to}.part';
  try {
    File(job.to).parent.createSync(recursive: true);
    final archive = ZipDecoder().decodeStream(input);
    final skip = job.skip.toSet();
    final out = ZipFileEncoder()..create(part);
    try {
      for (final f in archive.files) {
        if (!skip.contains(f.name)) out.addArchiveFile(f);
      }
    } finally {
      out.closeSync();
    }
    File(part).renameSync(job.to);
  } finally {
    input.closeSync();
    final left = File(part);
    if (left.existsSync()) left.deleteSync();
  }
}

/// Narrated EPUBs (EPUB 3 media overlays): the narration as the book's
/// audio, and the sentence timings read along follows.
///
/// BookOrbit knows which books these are and streams their narration. An
/// Audiobookshelf server treats them as plain ebooks, so there it all
/// happens on the phone: the EPUB is looked into with range requests (its
/// index and timings), the reader gets a copy without the audio, and the
/// narration plays once downloaded: the whole EPUB comes down as a normal
/// background download and its audio files are taken out of it here.
class NarrationService {
  NarrationService._();
  static final NarrationService instance = NarrationService._();

  final Map<String, MediaOverlay> _overlays = {};
  final Map<String, double> _known = {};
  static String _key(String itemId) => 'narration_$itemId';
  static String _timedKey(String itemId) => 'narration_timed2_$itemId';

  /// What this phone has found out about the book's EPUB: true when it reads
  /// itself aloud, false when it was checked and doesn't, null when unknown.
  Future<bool?> knownNarrated(String itemId) async {
    final v = _known[itemId] ?? await ScopedPrefs.getDouble(_key(itemId));
    if (v == null) return null;
    _known[itemId] = v;
    return v > 0;
  }

  /// Counts [itemId] as an audiobook from now on. Only for a book with no
  /// audio of its own: one with an audiobook beside its narrated EPUB keeps
  /// that audiobook.
  Future<void> markAudiobook(String itemId, MediaOverlay o) => NarratedBooks.set(itemId, o.duration);

  Future<void> _remember(String itemId, MediaOverlay? o) async {
    if (o != null && hasLocalAudio(itemId) && await ScopedPrefs.getBool(_timedKey(itemId)) != true) {
      o = await _timedFromDownload(itemId, o);
    }
    final v = o == null ? -1.0 : o.duration;
    _known[itemId] = v;
    await ScopedPrefs.setDouble(_key(itemId), v);
    if (o == null || NarratedBooks.contains(itemId)) await NarratedBooks.set(itemId, o?.duration);
    if (o == null) return;
    _overlays[itemId] = o;
    await _save(itemId, o);
  }

  /// Timings read again over a narration already downloaded: laid on its
  /// files' real lengths, with the download's chapters brought up to date.
  Future<MediaOverlay> _timedFromDownload(String itemId, MediaOverlay o) async {
    final paths = DownloadService().getLocalPaths(itemId);
    if (paths == null || paths.length != o.tracks.length) return o;
    final measured = [for (final p in paths) await audioFileDuration(p)];
    final timed = o.withTrackDurations(measured);
    if (measured.every((m) => m != null)) await ScopedPrefs.setBool(_timedKey(itemId), true);
    await DownloadService().updateNarrationTimeline(
      itemId,
      duration: timed.duration,
      chapters: timed.chapters(),
      audioTracks: timed.audioTracks((t) => t.href),
    );
    return timed;
  }

  Future<File> _file(String itemId) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/narration');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}/$itemId.v2.json');
  }

  Future<void> _save(String itemId, MediaOverlay o) async {
    try {
      await (await _file(itemId)).writeAsString(jsonEncode(o.toJson()));
    } catch (e) {
      debugPrint('[Narration] saving the timings for $itemId failed: $e');
    }
  }

  /// The narration this phone knows for [itemId], from memory or disk.
  Future<MediaOverlay?> localOverlay(String itemId) async {
    final mem = _overlays[itemId];
    if (mem != null) return mem;
    try {
      final f = await _file(itemId);
      if (!f.existsSync()) return null;
      final o = MediaOverlay.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      if (o != null) _overlays[itemId] = o;
      return o;
    } catch (_) {
      return null;
    }
  }

  /// The narration of [itemId], for read along. [fromServer] when BookOrbit
  /// plays it as the book's audio; otherwise the timings found on this phone.
  Future<({MediaOverlay overlay, bool fromServer})?> overlayFor(
    ApiService api,
    String itemId, {
    File? epub,
  }) async {
    if (api is BookOrbitApiService) {
      final o = await api.narrationFor(itemId);
      if (o != null) {
        _overlays[itemId] = o;
        unawaited(_save(itemId, o));
        return (overlay: o, fromServer: true);
      }
      final saved = await localOverlay(itemId);
      return saved == null ? null : (overlay: saved, fromServer: true);
    }
    final known = await localOverlay(itemId);
    if (known != null) return (overlay: known, fromServer: false);
    if (await knownNarrated(itemId) == false) return null;
    if (epub == null || !epub.existsSync()) return null;
    final o = await compute(_parseEpub, epub.path);
    await _remember(itemId, o == null || o.isEmpty ? null : o);
    final found = _overlays[itemId];
    if (found == null) return null;
    debugPrint('[Narration] $itemId reads itself aloud: ${found.tracks.length} files, '
        '${found.clips.length} sentences, ${found.duration.toStringAsFixed(0)}s');
    return (overlay: found, fromServer: false);
  }

  /// [item] with its narration as audio, the way BookOrbit's books arrive:
  /// a duration (so it isn't ebook-only), chapters, and the narration marker.
  Map<String, dynamic> withNarration(Map<String, dynamic> item, MediaOverlay o) {
    final media = Map<String, dynamic>.from(item['media'] as Map? ?? const {});
    if (((media['duration'] as num?) ?? 0) > 0) return item;
    media['duration'] = o.duration;
    media['chapters'] = o.chapters();
    media['narration'] = {'duration': o.duration, 'local': true};
    return {...item, 'media': media};
  }

  RemoteZip? _openZip;
  String? _openZipItem;
  DateTime _openZipAt = DateTime(0);

  /// The EPUB on the server, its index read once. Opened again after a while
  /// so the token in its URL stays current.
  Future<RemoteZip> _remote(ApiService api, String itemId, Map<String, dynamic> ebookFile) async {
    final open = _openZip;
    if (_openZipItem == itemId &&
        open != null &&
        DateTime.now().difference(_openZipAt) < const Duration(minutes: 10)) {
      return open;
    }
    final ino = ebookFile['ino'] as String?;
    if (ino == null) throw RemoteZipException('no ebook file');
    final zip = await RemoteZip.open(Uri.parse(api.buildFileUrl(itemId, ino)), headers: api.mediaHeaders);
    _openZip?.close();
    _openZip = zip;
    _openZipItem = itemId;
    _openZipAt = DateTime.now();
    return zip;
  }

  static String _ext(String href) {
    final name = href.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot).toLowerCase();
  }

  /// Looks into an Audiobookshelf book's EPUB on the server (its index and
  /// timings only) to see whether it reads itself aloud. Remembered, so it is
  /// asked once per book.
  ///
  /// [onNarrated] hears as soon as the EPUB's package shows narration, with
  /// the length it states, while the timings are still coming. One look per
  /// book at a time: a second caller waits on the first.
  Future<MediaOverlay?> probe(
    ApiService api,
    Map<String, dynamic> item, {
    void Function(double? duration)? onNarrated,
  }) {
    final itemId = item['id'] as String?;
    if (itemId == null) return Future.value(null);
    if (onNarrated != null) {
      if (_seenNarrated.containsKey(itemId)) {
        onNarrated(_seenNarrated[itemId]);
      } else {
        (_onNarrated[itemId] ??= []).add(onNarrated);
      }
    }
    final running = _probing[itemId];
    if (running != null) {
      debugPrint('[Narration] $itemId is already being looked into - waiting on that look');
      return running;
    }
    final look = () async {
      try {
        return await _probe(api, item, itemId);
      } finally {
        _probing.remove(itemId);
        _onNarrated.remove(itemId);
        _seenNarrated.remove(itemId);
      }
    }();
    _probing[itemId] = look;
    return look;
  }

  final Map<String, Future<MediaOverlay?>> _probing = {};
  final Map<String, List<void Function(double? duration)>> _onNarrated = {};
  final Map<String, double?> _seenNarrated = {};

  Future<MediaOverlay?> _probe(ApiService api, Map<String, dynamic> item, String itemId) async {
    final ebookFile = resolveEbookFile(item);
    if (ebookFile == null || api.isBookOrbit) return null;
    if (ebookExtFromFile(ebookFile) != '.epub') return null;
    if (await knownNarrated(itemId) == false) return null;
    final local = await localOverlay(itemId);
    if (local != null) return local;
    final started = DateTime.now();
    try {
      final zip = await _remote(api, itemId, ebookFile);
      final o = await MediaOverlay.fromFiles((name) async {
        final e = zip.entry(name);
        return e == null ? null : utf8.decode(await zip.read(e), allowMalformed: true);
      }, onNarrated: (duration) {
        debugPrint('[Narration] $itemId: its package lists narration '
            '(${duration == null ? 'no length given' : '${duration.toStringAsFixed(0)}s'}) after '
            '${DateTime.now().difference(started).inMilliseconds}ms - reading the timings');
        _seenNarrated[itemId] = duration;
        for (final cb in _onNarrated.remove(itemId) ?? const <void Function(double?)>[]) {
          cb(duration);
        }
      });
      debugPrint('[Narration] looked into $itemId on the server in '
          '${DateTime.now().difference(started).inMilliseconds}ms: '
          '${o == null ? 'no narration' : '${o.clips.length} sentences, ${o.duration.toStringAsFixed(0)}s'} '
          '(${zip.length} bytes, ${zip.entries.length} files)');
      final found = o == null || o.isEmpty ? null : o;
      await _remember(itemId, found);
      return found == null ? null : _overlays[itemId];
    } catch (e) {
      debugPrint('[Narration] could not look into $itemId on the server: $e');
      return null;
    }
  }

  /// The EPUB the reader opens. A narrated book on Audiobookshelf gets a copy
  /// without its audio, pulled from the server a piece at a time, so a
  /// several hundred MB file opens in seconds. Anything else is the usual
  /// cached download.
  Future<File> readerFile(
    ApiService api,
    String itemId,
    Map<String, dynamic> ebookFile,
    String title,
  ) async {
    final cached = await ebookCacheFileFor(itemId, ebookFile);
    if (cached.existsSync() && cached.lengthSync() > 0) {
      if (_slimFailed.contains(itemId) || !await _cachedWithAudio(api, itemId, ebookFile, cached)) {
        debugPrint('[EbookCache] cache hit item=$itemId bytes=${cached.lengthSync()}');
        return cached;
      }
      // An earlier copy kept the narration inside: hundreds of MB the reader
      // can't open. Swap in one without it, keeping the old one if that fails.
      final aside = File('${cached.path}.withaudio');
      debugPrint('[EbookCache] $itemId is cached with its narration audio '
          '(${cached.lengthSync()} bytes) - getting a copy without it');
      await cached.rename(aside.path);
      try {
        final slim = await _freshReaderFile(api, itemId, ebookFile, title, cached, wholeFallback: false);
        if (aside.existsSync()) await aside.delete();
        return slim;
      } catch (e) {
        debugPrint('[EbookCache] copy without audio failed for $itemId ($e) - keeping the full one');
        _slimFailed.add(itemId);
        if (cached.existsSync()) await cached.delete();
        await aside.rename(cached.path);
        return cached;
      }
    }
    return _freshReaderFile(api, itemId, ebookFile, title, cached);
  }

  /// A cached EPUB that still holds the narration: big, the book reads
  /// itself aloud, and the copy is about the size of the server's file.
  Future<bool> _cachedWithAudio(
    ApiService api,
    String itemId,
    Map<String, dynamic> ebookFile,
    File cached,
  ) async {
    if (ebookExtFromFile(ebookFile) != '.epub') return false;
    final length = cached.lengthSync();
    if (length < 50 * 1024 * 1024) return false;
    final narrated =
        api.isBookOrbit ? _bookOrbitNarrated(api, itemId, ebookFile) : await knownNarrated(itemId) == true;
    if (!narrated) return false;
    final size = ((ebookFile['metadata'] as Map?)?['size'] as num?)?.toInt() ?? 0;
    return size <= 0 || length >= size * 0.9;
  }

  Future<File> _freshReaderFile(
    ApiService api,
    String itemId,
    Map<String, dynamic> ebookFile,
    String title,
    File cached, {
    bool wholeFallback = true,
  }) async {
    if (ebookExtFromFile(ebookFile) == '.epub') {
      final slim = api.isBookOrbit
          ? await _slimBookOrbit(api, itemId, ebookFile, cached)
          : await _slimAbs(api, itemId, ebookFile, cached);
      if (slim != null) return slim;
    }
    // BookOrbit's own download leaves the audio out, when it can build it.
    if (!wholeFallback && !api.isBookOrbit) throw StateError('no copy without the audio');
    return fetchEbookToCache(api, itemId, ebookFile, title);
  }

  final Set<String> _slimFailed = {};

  static const _audioExts = {'.mp3', '.m4a', '.m4b', '.mp4', '.aac', '.ogg', '.oga', '.opus', '.wav', '.flac'};

  bool _bookOrbitNarrated(ApiService api, String itemId, Map<String, dynamic> ebookFile) {
    final ino = ebookFile['ino'] as String?;
    return api.isBookOrbit && ino != null && api.buildReaderEbookUrl(itemId, ino) != api.buildEbookUrl(itemId, ino);
  }

  Future<File?> _slimAbs(ApiService api, String itemId, Map<String, dynamic> ebookFile, File cached) async {
    final o = await probe(api, {
      'id': itemId,
      'media': {'ebookFile': ebookFile},
    });
    if (o == null) return null;
    final started = DateTime.now();
    try {
      final zip = await _remote(api, itemId, ebookFile);
      final audio = o.tracks.map((t) => t.href).toSet();
      await zip.writeCopy(cached, (e) => !audio.contains(e.name));
      debugPrint('[EbookCache] narrated EPUB $itemId opened without its audio: '
          '${cached.lengthSync()} of ${zip.length} bytes in '
          '${DateTime.now().difference(started).inMilliseconds}ms');
      return cached;
    } catch (e) {
      debugPrint('[EbookCache] copy without audio failed for $itemId ($e) - downloading it whole');
      return null;
    }
  }

  /// BookOrbit builds a copy without the audio itself, but turns big books
  /// away, so the copy is made here from its file with ranges, as on
  /// Audiobookshelf.
  Future<File?> _slimBookOrbit(ApiService api, String itemId, Map<String, dynamic> ebookFile, File cached) async {
    if (!_bookOrbitNarrated(api, itemId, ebookFile)) return null;
    final started = DateTime.now();
    RemoteZip? zip;
    try {
      zip = await RemoteZip.open(Uri.parse(api.buildEbookUrl(itemId, ebookFile['ino'] as String)));
      await zip.writeCopy(cached, (e) => !_audioExts.contains(_ext(e.name)));
      debugPrint('[EbookCache] narrated EPUB $itemId opened without its audio: '
          '${cached.lengthSync()} of ${zip.length} bytes in '
          '${DateTime.now().difference(started).inMilliseconds}ms');
      return cached;
    } catch (e) {
      debugPrint('[EbookCache] copy without audio failed for $itemId ($e) - asking BookOrbit for one');
      return null;
    } finally {
      zip?.close();
    }
  }

  /// Narration already on the phone as the book's audio.
  bool hasLocalAudio(String itemId) =>
      (DownloadService().getLocalPaths(itemId)?.isNotEmpty ?? false);

  /// The narration when it is the book's audio: an Audiobookshelf EPUB with
  /// no audiobook of its own, or a book BookOrbit plays from its EPUB. Its
  /// timings say which sentence is being read at every moment, so nothing
  /// needs transcribing. Null for any other book, or when the timings aren't
  /// on this phone yet.
  Future<MediaOverlay?> audioNarration(ApiService? api, String itemId) async {
    if (api is BookOrbitApiService) return api.narrationFor(itemId);
    if (!NarratedBooks.contains(itemId)) return null;
    return localOverlay(itemId);
  }

  List<String> _trackNames(List<Map<String, dynamic>> tracks) => [
        for (final t in tracks)
          ((t['metadata'] as Map)['filename'] as String).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'),
      ];

  /// The narration laid on the audio files' real lengths, saved, and kept as
  /// the book's download.
  Future<void> _keep(
    ApiService? api,
    Map<String, dynamic> item,
    String itemId,
    MediaOverlay o,
    String dir,
    List<String> paths, {
    String? localCoverPath,
  }) async {
    final measured = <double?>[];
    for (final p in paths) {
      measured.add(await audioFileDuration(p));
    }
    final timed = o.withTrackDurations(measured);
    debugPrint('[Narration] $itemId measured ${measured.where((m) => m != null).length} of '
        '${paths.length} files: ${o.duration.toStringAsFixed(0)}s from the timings, '
        '${timed.duration.toStringAsFixed(0)}s from the audio');
    await _remember(itemId, timed);
    await markAudiobook(itemId, timed);
    if (measured.every((m) => m != null)) await ScopedPrefs.setBool(_timedKey(itemId), true);
    await DownloadService().registerNarration(
      api: api,
      localCoverPath: localCoverPath,
      itemId: itemId,
      item: item,
      dirPath: dir,
      paths: paths,
      duration: timed.duration,
      chapters: timed.chapters(),
      audioTracks: timed.audioTracks((t) => t.href),
    );
  }

  /// A narrated EPUB downloaded whole to [epubPath]: its audio files are taken
  /// out into [dir] and kept as the book's download, the reader gets a copy
  /// without the audio when it has none yet, and the EPUB is deleted. False
  /// when it holds no narration after all.
  Future<bool> keepFromEpub(
    Map<String, dynamic> item,
    String itemId,
    String epubPath,
    String dir, {
    String? localCoverPath,
  }) async {
    final started = DateTime.now();
    final o = await compute(_parseEpub, epubPath);
    if (o == null || o.isEmpty) {
      debugPrint('[Narration] the downloaded EPUB for $itemId holds no narration');
      await _remember(itemId, null);
      return false;
    }
    final hrefs = o.tracks.map((t) => t.href).toList();
    final names = _trackNames(o.audioTracks((t) => t.href));
    final paths = await compute(_extract, (epub: epubPath, dir: dir, hrefs: hrefs, names: names));
    debugPrint('[Narration] took ${paths.length} audio files out of the downloaded EPUB for $itemId '
        'in ${DateTime.now().difference(started).inMilliseconds}ms');
    final ebookFile = resolveEbookFile(item);
    if (ebookFile != null) {
      try {
        final reader = await ebookCacheFileFor(itemId, ebookFile);
        if (reader.existsSync() && reader.lengthSync() > 0) {
          debugPrint('[EbookCache] $itemId already has a reader copy (${reader.lengthSync()} bytes)');
        } else {
          final at = DateTime.now();
          await compute(_copyWithout, (from: epubPath, to: reader.path, skip: hrefs));
          debugPrint('[EbookCache] narrated EPUB $itemId kept for the reader without its audio: '
              '${reader.lengthSync()} bytes in ${DateTime.now().difference(at).inMilliseconds}ms');
        }
      } catch (e) {
        debugPrint('[EbookCache] reader copy of $itemId not made from the download: $e');
      }
    }
    try {
      File(epubPath).deleteSync();
    } catch (e) {
      debugPrint('[Narration] the downloaded EPUB for $itemId was not deleted: $e');
    }
    await _keep(null, item, itemId, o, dir, paths, localCoverPath: localCoverPath);
    return true;
  }

  /// Plays the narration, from the sentence [from] when given (read along
  /// starting at the page in view, "play from here"). An Audiobookshelf book
  /// plays it once downloaded: false until then.
  Future<bool> play(
    ApiService api,
    Map<String, dynamic> item, {
    OverlayClip? from,
    String? coverUrl,
  }) async {
    final itemId = item['id'] as String?;
    if (itemId == null) return false;
    if (!api.isBookOrbit && !hasLocalAudio(itemId)) return false;
    final o = await localOverlay(itemId);
    double? startTime;
    if (from != null && o != null) {
      final c = o.sameClip(from);
      if (c != null) startTime = o.startOf(c);
    }
    final shaped = o == null || api.isBookOrbit ? item : withNarration(item, o);
    final media = shaped['media'] as Map<String, dynamic>? ?? const {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? const {};
    final error = await AudioPlayerService().playItem(
      api: api,
      itemId: itemId,
      title: metadata['title'] as String? ?? '',
      author: metadata['authorName'] as String? ?? '',
      coverUrl: coverUrl ?? api.getCoverUrl(itemId),
      totalDuration: (media['duration'] as num?)?.toDouble() ?? 0,
      chapters: media['chapters'] as List<dynamic>? ?? const [],
      startTime: startTime ?? 0,
      forceStartTime: startTime != null,
      libraryId: item['libraryId'] as String?,
      fromUi: true,
    );
    if (error != null) debugPrint('[Narration] play $itemId failed: $error');
    return error == null;
  }
}

/// The book's own words narrated between [from] and [to] seconds: each
/// sentence read in that stretch, in order, from the EPUB at [epubPath].
/// Runs through [compute], so the EPUB is read off the main isolate.
String narratedTextIn(({String epubPath, MediaOverlay overlay, double from, double to}) a) {
  final book = EpubBookText.open(a.epubPath);
  if (book == null) return '';
  try {
    final out = <String>[];
    final seen = <String>{};
    for (final c in a.overlay.clips) {
      final id = c.fragment;
      if (id == null) continue;
      final start = a.overlay.startOf(c);
      final end = start + (c.end - c.begin);
      if (end <= a.from || start >= a.to) continue;
      if (!seen.add('${c.textHref}#$id')) continue;
      final si = book.sectionOf(c.textHref);
      if (si < 0) continue;
      final text = book.elementText(si, id);
      if (text != null && text.isNotEmpty) out.add(text);
    }
    return out.join(' ');
  } finally {
    book.close();
  }
}
