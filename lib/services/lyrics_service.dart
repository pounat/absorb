import 'dart:async';

import 'package:flutter/widgets.dart';

import 'audio_player_service.dart';
import 'ebook_cache.dart';
import 'transcript_chunker.dart';
import 'transcript_line_store.dart';
import 'transcription_service.dart';

/// Live transcript ("lyrics") mode: while enabled, transcribes ahead of the
/// playhead in 30s chunks and exposes the line under the current position for
/// the player to display. Lines go through [TranscriptLineStore], so a
/// listened stretch is never transcribed twice - and the store persists, so
/// a book you ran this on before starts with its runway already built.
///
/// The loop builds a deep runway: it transcribes flat-out until it is
/// [_targetListeningSeconds] of listening time ahead, then idles and tops
/// back up as you listen. Lines are held back until an initial
/// [_gateListeningSeconds] of runway exists, so the transcript never starts
/// in a stutter - the overlay shows build progress until then. It always
/// yields to user-triggered transcriptions (bookmark transcribe, the find
/// features), which the deep runway absorbs without visible gaps, and stops
/// with the mode, the screen, or playback.
/// Watches for the app leaving the foreground. Transcribing is heavy enough
/// to be felt on the whole phone, and it is only worth anything while you are
/// looking at it - so backgrounding the app stops it, and it has to be turned
/// on again deliberately.
class _LyricsLifecycle extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` also fires for a pulled-down notification shade or a
    // permission dialog, which shouldn't count as leaving.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      final svc = LyricsService.instance;
      if (!svc.isOn) return;
      // The transcript is only worth anything on screen, so it stops. The
      // runway built so far is on disk and is still there next time.
      debugPrint('[Lyrics] app backgrounded - stopping');
      svc.disable();
    }
  }
}

class LyricsService extends ChangeNotifier {
  LyricsService._();
  static final LyricsService instance = LyricsService._();

  final _LyricsLifecycle _lifecycle = _LyricsLifecycle();
  TranscriptChunker? _chunker;
  bool _watching = false;

  /// How much runway to build, in seconds of listening time - multiplied by
  /// the playback speed to get book-seconds. Deep on purpose: momentary
  /// stalls (model load, a bookmark transcription borrowing the engine, one
  /// slow chunk) drain a shallow buffer and put gaps on screen; a deep one
  /// absorbs them.
  static const double _targetListeningSeconds = 600;

  /// Runway required before lines are shown, in seconds of listening time.
  /// Starting to display with no slack means the first hiccup stutters;
  /// holding lines back until this much is banked means once the transcript
  /// appears, it stays. Books with saved coverage pass instantly.
  static const double _gateListeningSeconds = 60;

  static const double _chunkSeconds = 30;

  bool _on = false;
  String? _key;
  String? _epubItemId; // itemId to look for a cached EPUB under (books only)
  Timer? _tick;
  bool _working = false;
  TranscriptLine? _current;
  bool _transcribingVisible = false;
  bool _pastCoverage = false;
  bool _gatePassed = false;
  double _gateProgress = 0;
  double fontSize = 16;
  int maxLines = 3;
  bool fullCover = true;
  /// Read-along coloring: the ARGB value the spoken words are painted in,
  /// and whether tracking follows single words or whole sentences.
  int readAlongColor = PlayerSettings.defaultReadAlongColor;
  String readAlongMode = 'word';
  int _wordIndex = -1;
  int _probeTick = 0;
  double? _rate;
  /// Milliseconds the transcript is held back to match what you are hearing,
  /// and which output that figure belongs to.
  int offsetMs = 0;
  bool onBluetooth = false;
  bool _routeLoaded = false;
  int _routeTick = 0;
  int _slowChunks = 0;
  bool _forceFastModel = false;
  bool _reachedEnd = false;

  bool get isOn => _on;
  /// The store key lyrics are currently running for, so card overlays can
  /// render only on the playing item's card.
  String? get activeKey => _key;
  TranscriptLine? get current => _current;
  /// The transcript sync offset in seconds - subtract it from the playhead to
  /// get the moment you are actually hearing.
  double get offsetSeconds => offsetMs / 1000.0;


  /// 0-1 progress toward the initial runway while lines are still held back,
  /// or null once the gate has passed and lines are showing.
  double? get gateProgress => _gatePassed ? null : _gateProgress;

  /// True when this device measurably cannot transcribe as fast as you are
  /// listening, so the transcript is going to keep running out.
  bool get cannotKeepUp {
    final rate = _rate;
    if (rate == null) return false;
    return rate < AudioPlayerService().speed * 1.2;
  }

  /// Which word of [current] is being spoken, or -1 when the line has no word
  /// timing or word tracking is off.
  int get currentWordIndex => readAlongMode == 'word' ? _wordIndex : -1;
  /// True when the transcript has taken this item's cover over, so the card
  /// should hide its artwork and let the transcript sit on the card's own
  /// background instead.
  bool coversArtFor(String key) => _on && fullCover && _key == key;

  /// True when the playhead is past coverage and a chunk is being worked on -
  /// the overlay shows a subtle "listening ahead" state instead of nothing.
  bool get buffering => _on && _current == null && _pastCoverage;

  /// The store key for what the player has loaded right now, matching the
  /// download map's keying: composite for podcast episodes, itemId for books.
  static String? playerKey() {
    final p = AudioPlayerService();
    final itemId = p.currentItemId;
    if (itemId == null) return null;
    final ep = p.currentEpisodeId;
    return ep != null ? '$itemId-$ep' : itemId;
  }

  Future<void> enableForCurrent() async {
    final key = playerKey();
    if (key == null) return;
    _key = key;
    final ep = AudioPlayerService().currentEpisodeId;
    _epubItemId = ep == null ? AudioPlayerService().currentItemId : null;
    _chunker = TranscriptChunker(key: key, epubItemId: _epubItemId);
    _on = true;
    _rate = null;
    _slowChunks = 0;
    _forceFastModel = false;
    _gatePassed = false;
    _gateProgress = 0;
    _reachedEnd = false;
    _chunker?.reset();
    _routeLoaded = false;
    if (!_watching) {
      _watching = true;
      WidgetsBinding.instance.addObserver(_lifecycle);
    }
    await _refreshRoute();
    await reloadDisplayPrefs();
    await TranscriptLineStore.instance.hydrate(key);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) => _onTick());
    notifyListeners();
    final pos = AudioPlayerService().position.inMilliseconds / 1000.0;
    final covered = TranscriptLineStore.instance.coveredUntil(key, pos);
    debugPrint('[Lyrics] enabled for $key (epub lookup: ${_epubItemId != null}, '
        'saved runway ${(covered - pos).clamp(0, double.infinity).toStringAsFixed(0)}s '
        'from pos ${pos.toStringAsFixed(0)}s)');
    unawaited(_autoCacheEpub());
  }

  bool _epubFetching = false;

  /// Correction scans the whole EPUB per chunk, so a giant one is a per-chunk
  /// CPU tax on top of an unasked-for background download - past this size the
  /// book only gets corrections once the user opens it in the reader.
  static const int _epubAutoFetchCapBytes = 50 * 1024 * 1024;

  /// Downloads the book's EPUB into the reader cache when it isn't there yet,
  /// so chunk correction has the author's words even on a device where the
  /// book was never opened in the reader. Fire-and-forget: the chunker
  /// re-checks the cache each chunk, so corrections start with the first
  /// chunk after the file lands (and the model pick flips to tiny with it).
  /// Every failure just leaves honest Whisper.
  Future<void> _autoCacheEpub() async {
    final itemId = _epubItemId;
    if (itemId == null || _epubFetching) return;
    _epubFetching = true;
    try {
      final cached = await cachedEbookFileFor(itemId);
      if (cached != null && ebookExtFromFile(cached) == '.epub') return;
      final api = AudioPlayerService().currentApi;
      if (api == null) return;
      final item = await api.getLibraryItem(itemId);
      if (item == null) {
        debugPrint('[Lyrics] epub auto-fetch skipped - item lookup failed');
        return;
      }
      final ef = resolveEbookFile(item);
      if (ef == null || ebookExtFromFile(ef) != '.epub') {
        debugPrint('[Lyrics] no epub to correct against');
        return;
      }
      final size =
          ((ef['metadata'] as Map<String, dynamic>?)?['size'] as num?)?.toInt() ?? 0;
      if (size > _epubAutoFetchCapBytes) {
        debugPrint('[Lyrics] epub too big to auto-fetch '
            '(${(size / (1024 * 1024)).toStringAsFixed(0)} MB) - open it in '
            'the reader once to get corrected lines');
        return;
      }
      final f = await fetchEbookToCache(api, itemId, ef, '');
      final mb = (await f.length()) / (1024 * 1024);
      debugPrint(
          '[Lyrics] epub cached for correction (${mb.toStringAsFixed(1)} MB)');
    } catch (e) {
      debugPrint('[Lyrics] epub auto-fetch failed: $e');
    } finally {
      _epubFetching = false;
    }
  }

  /// Re-read the overlay display settings; the settings screen calls this so
  /// changes apply live while lyrics are running.
  Future<void> reloadDisplayPrefs() async {
    fontSize = await PlayerSettings.getLyricsFontSize();
    maxLines = await PlayerSettings.getLyricsMaxLines();
    fullCover = await PlayerSettings.getLyricsFullCover();
    readAlongColor = await PlayerSettings.getReadAlongColor();
    readAlongMode = await PlayerSettings.getReadAlongMode();
    notifyListeners();
  }

  void disable() {
    _on = false;
    if (_watching) {
      _watching = false;
      WidgetsBinding.instance.removeObserver(_lifecycle);
    }
    _tick?.cancel();
    _tick = null;
    _current = null;
    _wordIndex = -1;
    _key = null;
    notifyListeners();
    debugPrint('[Lyrics] disabled');
  }

  void _onTick() {
    if (!_on) return;
    final key = _key;
    if (key == null) return;
    // The player moved to a different book/episode: follow it.
    final nowKey = playerKey();
    if (nowKey == null) {
      disable();
      return;
    }
    if (nowKey != key) {
      // A different book or episode started. Don't carry the transcript over
      // to it - it costs battery and processing, so it stays something you
      // switch on deliberately, every time.
      debugPrint('[Lyrics] the player moved to $nowKey - stopping');
      disable();
      return;
    }
    final pos = AudioPlayerService().position.inMilliseconds / 1000.0;
    if (++_routeTick % 25 == 0) _refreshRoute();
    final speed = AudioPlayerService().speed;
    final covered = TranscriptLineStore.instance.coveredUntil(key, pos);
    final lead = covered - pos;
    _pastCoverage = lead <= 0.5;

    // Hold lines back until the initial runway exists (or the book's end is
    // inside it) - showing lines with no slack means the first stall
    // stutters. Once passed, the gate stays passed for the session, even if
    // the runway later drains: switching the display off mid-listen would
    // hide lines that are still correct.
    if (!_gatePassed) {
      // Once this device's real rate is known, the gate only needs enough
      // runway to ride out a couple of chunks' worth of transcription time -
      // on a fast device that's a fraction of the full gate, so lines appear
      // in seconds instead of half a minute. Until a rate exists, or on a
      // slow device, the full gate stands.
      var gateNeed = _gateListeningSeconds * speed;
      final r = _rate;
      if (r != null && r > 0) {
        final adaptive =
            ((_chunkSeconds / r) * speed * 2.5).clamp(10.0, gateNeed);
        gateNeed = adaptive;
      }
      final progress = (lead / gateNeed).clamp(0.0, 1.0).toDouble();
      final total = AudioPlayerService().totalDuration;
      final endInReach =
          _reachedEnd || (total > 0 && covered >= total - _chunkSeconds);
      if (lead >= gateNeed || endInReach) {
        _gatePassed = true;
        debugPrint('[Lyrics] gate passed: ${lead.toStringAsFixed(0)}s of '
            'runway banked (needed ${gateNeed.toStringAsFixed(0)}s at '
            '${speed}x${endInReach ? ', end of item in reach' : ''})');
        notifyListeners();
      } else if ((progress - _gateProgress).abs() > 0.01) {
        _gateProgress = progress;
        notifyListeners();
      }
    }

    // What you are hearing right now, which on Bluetooth is a fraction of a
    // second behind the playhead. Only the display is shifted - transcribing
    // still works from the real position.
    final heard = pos - offsetSeconds;
    // Small display lead: a line arriving a beat early reads like lyrics, a
    // beat late reads like subtitles falling behind. The gap-tolerant lookup
    // holds a line through the short silences Whisper's VAD trims out.
    // The lead is in book-seconds, so scale it by playback speed to keep the
    // same wall-clock feel at 1.5x or 2x.
    final line = _gatePassed
        ? TranscriptLineStore.instance.lineNear(key, heard + 0.35 * speed)
        : null;
    var changed = line?.start != _current?.start || line?.text != _current?.text;
    _current = line;
    // Previews have guessed timing - a moving word highlight on them would
    // look confidently wrong, so they show as a whole dimmed line instead.
    final wordIndex = line == null || line.approx
        ? -1
        : line.wordIndexAt(heard + 0.15 * speed);
    if (wordIndex != _wordIndex) {
      _wordIndex = wordIndex;
      if (readAlongMode == 'word') changed = true;
    }
    if (changed) notifyListeners();
    // The one line that tells the whole story in a shared log: where the
    // playhead is, how much runway is banked against the target, and whether
    // this device is outrunning the narration.
    if (_routeTick % 75 == 0) {
      debugPrint('[Lyrics] status pos=${pos.toStringAsFixed(0)}s '
          'lead=${lead.toStringAsFixed(0)}s/'
          '${(_targetListeningSeconds * speed).toStringAsFixed(0)}s '
          'gate=${_gatePassed ? 'open' : '${(_gateProgress * 100).round()}%'} '
          'rate=${_rate?.toStringAsFixed(2) ?? '?'}x speed=${speed}x '
          'fastModel=$_forceFastModel end=$_reachedEnd');
    }
    _probe(pos, line);
    _ensureAhead(key, pos, covered);
  }

  /// Re-read which output is in use and load that output's offset. Cheap
  /// enough to run every few seconds, which is how a headphone connection
  /// mid-listen gets picked up.
  Future<void> _refreshRoute() async {
    final bt = await AudioPlayerService.isBluetoothAudioConnected();
    if (_routeLoaded && bt == onBluetooth) return;
    onBluetooth = bt;
    _routeLoaded = true;
    offsetMs = await PlayerSettings.getTranscriptOffsetMs(bluetooth: bt);
    debugPrint('[Lyrics] output is ${bt ? 'bluetooth' : 'the device'}, '
        'sync offset ${offsetMs}ms');
    notifyListeners();
  }

  /// Shift the transcript against the audio by [deltaMs], remembered against
  /// whichever output you are on.
  Future<void> nudgeOffset(int deltaMs) async {
    offsetMs = (offsetMs + deltaMs).clamp(-1000, 2000);
    notifyListeners();
    await PlayerSettings.setTranscriptOffsetMs(offsetMs, bluetooth: onBluetooth);
  }

  Future<void> clearOffset() async {
    offsetMs = 0;
    notifyListeners();
    await PlayerSettings.setTranscriptOffsetMs(0, bluetooth: onBluetooth);
  }

  /// How fast this device transcribes, in book-seconds per wall-second,
  /// smoothed over recent chunks. Below the playback speed the transcript can
  /// never catch the narration.
  void _noteRate(double span, double wall, double speed) {
    if (wall < 0.5 || span < 1) return;
    final rate = span / wall;
    _rate = _rate == null ? rate : _rate! * 0.6 + rate * 0.4;
    final need = speed * 1.2;
    debugPrint('[Lyrics] transcribed ${span.toStringAsFixed(0)}s in '
        '${wall.toStringAsFixed(1)}s = ${rate.toStringAsFixed(2)}x '
        '(need ${need.toStringAsFixed(2)}x at ${speed}x playback)');
    if (_rate! >= need) {
      _slowChunks = 0;
      return;
    }
    _slowChunks++;
    // One badly slow chunk, or two merely slow ones - the first chunk carries
    // the model load, so a single mild miss isn't proof on its own.
    if (_forceFastModel || !(_slowChunks >= 2 || rate < speed * 0.6)) return;
    _forceFastModel = true;
    _slowChunks = 0;
    final fastest = TranscriptionService.instance.lastModelUsed ==
        TranscriptionModelSize.tiny;
    if (fastest) {
      // Already on the fastest model: nothing to switch to, and the gaps are
      // this device's limit rather than a setting to fix. Keep the measured
      // rate - aiming chunks ahead is all that is left.
      debugPrint('[Lyrics] cannot keep up at ${speed}x even on the fast '
          'model - the transcript will have gaps');
      return;
    }
    // Re-measure from scratch: the slow model's rate would otherwise aim the
    // next chunk far ahead and skip audio the fast model could have covered.
    _rate = null;
    debugPrint('[Lyrics] too slow to keep up at ${speed}x - switching to the '
        'fast model for the rest of this session');
  }

  /// Once a second, write down where the audio is and what we believe is
  /// being said there. Played back against a screen recording it shows
  /// whether a line is early, late, or simply the wrong line.
  void _probe(double pos, TranscriptLine? line) {
    if (++_probeTick % 5 != 0) return;
    if (line == null) {
      debugPrint('[LyricsSync] pos=${pos.toStringAsFixed(1)} no line '
          '(${_pastCoverage ? 'past coverage' : 'gap'})');
      return;
    }
    final words = line.words;
    final word = _wordIndex >= 0 && _wordIndex < words.length
        ? words[_wordIndex]
        : '-';
    final text = line.text.length > 70
        ? '${line.text.substring(0, 70)}...'
        : line.text;
    debugPrint('[LyricsSync] pos=${pos.toStringAsFixed(1)} '
        'line=[${line.start.toStringAsFixed(1)}-${line.end.toStringAsFixed(1)}] '
        'word=$_wordIndex/${line.wordStarts.length} "$word" '
        'exact=${line.exact} offset=${offsetMs}ms | $text');
  }

  Future<void> _ensureAhead(String key, double pos, double covered) async {
    if (_working) return;
    final speed = AudioPlayerService().speed;
    // The end of the item is inside coverage: the runway is as deep as it
    // will ever need to be.
    final dur = AudioPlayerService().totalDuration;
    if (_reachedEnd || (dur > 0 && covered >= dur - 1)) {
      if (!_reachedEnd) {
        _reachedEnd = true;
        debugPrint('[Lyrics] coverage reached the end of $key');
      }
      if (_transcribingVisible) {
        _transcribingVisible = false;
        notifyListeners();
      }
      return;
    }
    // The target is listening time, so it scales with the playback speed -
    // ten minutes of runway at 1.5x is ten minutes of runway at 1x.
    if (covered - pos >= _targetListeningSeconds * speed) {
      if (_transcribingVisible) {
        _transcribingVisible = false;
        notifyListeners();
      }
      return;
    }
    // User-triggered transcriptions (bookmark, find) always win the engine.
    if (TranscriptionService.instance.isBusy) return;
    _working = true;
    _transcribingVisible = true;
    notifyListeners();
    // Starting at or behind the playhead, begin a few seconds early: pressing
    // play auto-rewinds, and a runway that starts exactly at the playhead
    // leaves that rewind in a hole with zero lead. Overlap with anything
    // already stored is dropped by the store.
    var start = covered > pos ? covered : (pos - 5).clamp(0.0, pos);
    if (covered <= pos + 1 && _rate != null && AudioPlayerService().isPlaying) {
      // Behind while playing. Transcribing from where you are now hands back
      // audio you have already heard by the time it finishes, and it never
      // catches up - so aim at where the playhead will BE when this chunk is
      // done. The stretch in between is skipped rather than shown late.
      // Only while playing: a paused playhead never moves into the chunk, and
      // an aim past the store's gap tolerance would pin the lead at zero
      // forever - the loop re-aims at the same unreachable spot every pass.
      final wall = _chunkSeconds / _rate!;
      start = pos + wall * speed + 1.5;
      debugPrint('[Lyrics] behind the playhead, aiming '
          '${(start - pos).toStringAsFixed(1)}s ahead');
    }
    try {
      // With the book's EPUB cached, every word gets replaced by the book's
      // own, so tiny is enough and its speed is what keeps the transcript
      // ahead of the narration. Without one, these words are what you read -
      // unless this device can't transcribe them fast enough to be read at
      // all, in which case the fast model beats a blank screen.
      // Sprint the session's first window: a short one puts the first line
      // (and the rate measurement the adaptive gate needs) on screen in a
      // few seconds; full windows take over from there.
      final out = await _chunker!.transcribeInto(
        start: start,
        windowSeconds: _rate == null ? 12.0 : _chunkSeconds,
        preferAccuracy: !_forceFastModel,
      );
      // A chunk can outlive its session - whisper can't be interrupted, so a
      // book switch mid-transcription lets the old item's chunk finish after
      // the new session started. Its lines landed in the right store, but its
      // timing must not steer this session's rate (a slow model's wall time
      // would skip the sprint and mis-aim the catch-up).
      if (!_on || key != _key) return;
      _noteRate(out.span, out.wall, speed);
      if (out.lines > 0) {
        debugPrint('[Lyrics] chunk at ${start.toStringAsFixed(1)}s: '
            '${out.lines} lines, exact=${out.exact}');
      }
    } on TranscriptionException catch (e) {
      if (!_on || key != _key) return;
      if (e.kind == TranscriptionError.empty) {
        // Silence or music: mark the stretch covered so the loop moves past
        // it instead of retrying the same window forever.
        await TranscriptLineStore.instance.addLines(key, [
          TranscriptLine(start, start + _chunkSeconds, ' '),
        ]);
      } else if (e.kind == TranscriptionError.extractFailed &&
          dur > 0 &&
          start + _chunkSeconds >= dur - 1) {
        // The window ran off the end of the audio.
        _reachedEnd = true;
        debugPrint('[Lyrics] the last window ran past the end of $key');
      } else {
        debugPrint('[Lyrics] chunk failed: $e');
        // Setup problems (model gone, download removed) end the session.
        if (e.kind != TranscriptionError.busy) disable();
      }
    } catch (e) {
      debugPrint('[Lyrics] chunk failed: $e');
    } finally {
      _working = false;
    }
  }

}
