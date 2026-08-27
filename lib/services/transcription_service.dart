import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

import 'download_service.dart';
import 'player_settings.dart';

/// On-device bookmark transcription using Whisper (whisper.cpp via
/// whisper_ggml_plus). Opt-in, downloaded-books only for now.
///
/// This is the single seam between the app and the underlying speech engine.
/// The UI and bookmark code only ever talk to [TranscriptionService] - the
/// concrete engine (whisper_ggml_plus today, possibly sherpa-onnx forced
/// alignment later for read-along) stays swappable behind it.
///
/// Audio is decoded to the 16kHz mono WAV Whisper requires by native code
/// (Android MediaCodec / iOS AVAssetReader) - no ffmpeg ships in the app.

enum TranscriptionModelSize { tiny, base, small }

/// Which user-facing feature a transcription job belongs to, so it can run
/// the model the user assigned to that feature.
enum TranscriptionFeature { bookmarks, readAlong }

/// Static description of a downloadable model. We deliberately pull the q5_1
/// quantized weights (roughly half the size, negligible accuracy loss) but
/// save them under the *unquantized* filename whisper.cpp's loader expects, so
/// [WhisperController] finds them. whisper.cpp loads quantized ggml transparently.
class TranscriptionModelInfo {
  const TranscriptionModelInfo({
    required this.size,
    required this.whisperModel,
    required this.downloadUrl,
    required this.fileName,
    required this.approxBytes,
  });

  final TranscriptionModelSize size;
  final WhisperModel whisperModel;
  final String downloadUrl;
  final String fileName;
  final int approxBytes;

  static const tiny = TranscriptionModelInfo(
    size: TranscriptionModelSize.tiny,
    whisperModel: WhisperModel.tiny,
    downloadUrl:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny-q5_1.bin',
    fileName: 'ggml-tiny.bin',
    approxBytes: 32 * 1024 * 1024, // ~31 MB
  );

  static const base = TranscriptionModelInfo(
    size: TranscriptionModelSize.base,
    whisperModel: WhisperModel.base,
    downloadUrl:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_1.bin',
    fileName: 'ggml-base.bin',
    approxBytes: 60 * 1024 * 1024, // ~57 MB
  );

  static const small = TranscriptionModelInfo(
    size: TranscriptionModelSize.small,
    whisperModel: WhisperModel.small,
    downloadUrl:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin',
    fileName: 'ggml-small.bin',
    approxBytes: 190 * 1024 * 1024, // ~182 MB
  );

  static TranscriptionModelInfo forSize(TranscriptionModelSize size) =>
      switch (size) {
        TranscriptionModelSize.tiny => tiny,
        TranscriptionModelSize.base => base,
        TranscriptionModelSize.small => small,
      };

}

/// Why a transcription could not be produced. The UI maps these to localized,
/// user-facing messages.
enum TranscriptionError {
  disabled,
  modelMissing,
  notDownloaded,
  noMetadata,
  extractFailed,
  transcribeFailed,
  busy,
  empty,
}

class TranscriptionException implements Exception {
  TranscriptionException(this.kind, [this.detail]);
  final TranscriptionError kind;
  final Object? detail;
  @override
  String toString() => 'TranscriptionException($kind${detail == null ? '' : ': $detail'})';
}

/// Resolve which downloaded track file contains [globalSeconds] and the offset
/// within that track. Pure function so it can be unit-tested without any
/// download state. [trackDurations] is index-aligned with the track file list.
({int index, double offset}) mapGlobalToTrack(
    List<double> trackDurations, double globalSeconds) {
  var remaining = globalSeconds < 0 ? 0.0 : globalSeconds;
  if (trackDurations.isEmpty) return (index: 0, offset: remaining);
  for (var i = 0; i < trackDurations.length; i++) {
    final d = trackDurations[i];
    final isLast = i == trackDurations.length - 1;
    if (remaining < d || isLast) {
      final maxOffset = d > 0 ? d : remaining;
      return (index: i, offset: remaining.clamp(0.0, maxOffset).toDouble());
    }
    remaining -= d;
  }
  return (index: trackDurations.length - 1, offset: 0);
}

class TranscriptionService {
  TranscriptionService._();
  static final TranscriptionService instance = TranscriptionService._();

  static const _channel = MethodChannel('com.barnabas.absorb/transcription');

  final WhisperController _whisper = WhisperController();

  // How much audio to feed Whisper around a bookmark, and how far before the
  // mark to start (so the clip captures the lead-in, not just what follows).
  static const double _windowSeconds = 30.0;
  static const double _leadSeconds = 3.0;

  bool _busy = false;
  bool _cancelDownload = false;

  /// Which model the last run actually used, after [_modelFor] had its say.
  TranscriptionModelSize? lastModelUsed;

  // Detected language per book. 'auto' makes whisper run the encoder twice
  // (once to detect, once to transcribe), so pay that only on a book's first
  // window and pass the answer explicitly from then on.
  final Map<String, String> _bookLang = {};

  // Model management

  Future<String> _modelDir() => WhisperController.getModelDir();

  Future<File> _modelFile(TranscriptionModelInfo info) async {
    final dir = await _modelDir();
    return File('$dir${Platform.pathSeparator}${info.fileName}');
  }

  Future<bool> isModelDownloaded(TranscriptionModelSize size) async {
    final file = await _modelFile(TranscriptionModelInfo.forSize(size));
    return file.existsSync() && await file.length() > 0;
  }

  /// Stream the (quantized) model to disk with progress (0..1). Writes to a
  /// `.part` file and renames on success so an interrupted download is never
  /// mistaken for a complete model. Throws on HTTP error or cancellation.
  Future<void> downloadModel(
    TranscriptionModelSize size, {
    void Function(double progress)? onProgress,
  }) async {
    _cancelDownload = false;
    final info = TranscriptionModelInfo.forSize(size);
    final file = await _modelFile(info);
    await file.parent.create(recursive: true);
    final part = File('${file.path}.part');

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(info.downloadUrl));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw TranscriptionException(
            TranscriptionError.modelMissing, 'HTTP ${response.statusCode}');
      }
      final total = response.contentLength > 0
          ? response.contentLength
          : info.approxBytes;
      final sink = part.openWrite();
      var received = 0;
      try {
        await for (final chunk in response) {
          if (_cancelDownload) {
            await sink.close();
            if (part.existsSync()) await part.delete();
            throw TranscriptionException(TranscriptionError.modelMissing, 'cancelled');
          }
          received += chunk.length;
          sink.add(chunk);
          onProgress?.call((received / total).clamp(0.0, 1.0));
        }
        await sink.flush();
        await sink.close();
      } catch (_) {
        await sink.close().catchError((_) {});
        if (part.existsSync()) await part.delete().catchError((_) => part);
        rethrow;
      }
      if (file.existsSync()) await file.delete();
      await part.rename(file.path);
      onProgress?.call(1.0);
      debugPrint('[Transcribe] Model ${info.fileName} downloaded (${received ~/ (1024 * 1024)} MB)');
    } finally {
      client.close(force: false);
    }
  }

  void cancelActiveDownload() => _cancelDownload = true;

  Future<void> deleteModel(TranscriptionModelSize size) async {
    final file = await _modelFile(TranscriptionModelInfo.forSize(size));
    if (file.existsSync()) await file.delete();
  }

  // Transcription

  /// Can this book be transcribed right now? Only downloaded books are
  /// supported (we need the local audio file to extract a window from).
  bool canTranscribeBook(String itemId) =>
      DownloadService().getLocalPaths(itemId)?.isNotEmpty ?? false;

  /// Which model to run for one job.
  ///
  /// [preferAccuracy] says whether the words have to stand on their own. When
  /// the book's EPUB is there, every word gets replaced by the book's own
  /// anyway, so tiny is enough - and being several times faster is what keeps
  /// the live transcript ahead of the narration. With no ebook the transcript
  /// IS the text, so a bigger model earns its time: small for a one-shot
  /// bookmark, base for read along, which small cannot keep realtime on.
  Future<TranscriptionModelInfo> _modelFor(
      bool? preferAccuracy, TranscriptionFeature feature) async {
    final want = preferAccuracy == false
        ? TranscriptionModelSize.tiny
        : feature == TranscriptionFeature.bookmarks
            ? TranscriptionModelSize.small
            : TranscriptionModelSize.base;
    // Only run what is actually on the device. When the intended model is
    // missing, the nearest smaller one stands in (base for small) before
    // anything bigger gets a turn.
    const ladder = [
      TranscriptionModelSize.small,
      TranscriptionModelSize.base,
      TranscriptionModelSize.tiny,
    ];
    final i = ladder.indexOf(want);
    final order = [...ladder.sublist(i), ...ladder.sublist(0, i).reversed];
    for (final s in order) {
      if (!await isModelDownloaded(s)) continue;
      final picked = TranscriptionModelInfo.forSize(s);
      if (s != want) {
        debugPrint('[Transcribe] using ${picked.fileName} - '
            '${TranscriptionModelInfo.forSize(want).fileName} is not downloaded');
      }
      return picked;
    }
    // Nothing downloaded at all - the caller turns this into modelMissing.
    return TranscriptionModelInfo.forSize(want);
  }

  /// Transcribe the audio around [positionSeconds] of [itemId]. Returns the
  /// transcript text plus the path to the extracted 16kHz WAV clip, which the
  /// caller can play back for review and MUST delete when finished. Throws
  /// [TranscriptionException] on any failure so the UI can show a specific message.
  Future<({String text, String audioPath})> transcribeAt({
    required String itemId,
    required double positionSeconds,
    double windowSeconds = _windowSeconds,
    double leadSeconds = _leadSeconds,
    bool? preferAccuracy,
    TranscriptionFeature feature = TranscriptionFeature.bookmarks,
  }) async {
    if (!await PlayerSettings.getTranscriptionEnabled()) {
      throw TranscriptionException(TranscriptionError.disabled);
    }
    if (_busy) throw TranscriptionException(TranscriptionError.busy);

    final info = await _modelFor(preferAccuracy, feature);
    if (!await isModelDownloaded(info.size)) {
      throw TranscriptionException(TranscriptionError.modelMissing);
    }
    lastModelUsed = info.size;

    final localPaths = DownloadService().getLocalPaths(itemId);
    if (localPaths == null || localPaths.isEmpty) {
      throw TranscriptionException(TranscriptionError.notDownloaded);
    }

    // Resolve which track file + offset the bookmark lands in.
    final durations = _trackDurations(itemId);
    final int trackIndex;
    final double localOffset;
    final double trackDuration;
    final double gStart = (positionSeconds - leadSeconds).clamp(0.0, double.infinity);
    if (durations != null && durations.length == localPaths.length) {
      final m = mapGlobalToTrack(durations, gStart);
      trackIndex = m.index;
      localOffset = m.offset;
      trackDuration = durations[trackIndex];
    } else if (localPaths.length == 1) {
      // Single-file book: no per-track metadata needed.
      trackIndex = 0;
      localOffset = gStart;
      trackDuration = double.infinity;
    } else {
      // Multi-file book but we can't map without durations.
      throw TranscriptionException(TranscriptionError.noMetadata);
    }

    final sourcePath = localPaths[trackIndex];
    // Books in a custom Android (SAF) folder are content:// URIs - File()
    // can't see those, but the native extractor opens them fine.
    if (!sourcePath.startsWith('content://') && !File(sourcePath).existsSync()) {
      throw TranscriptionException(TranscriptionError.notDownloaded, sourcePath);
    }

    // Clamp the window so it never runs past the end of this track (v1 doesn't
    // span file boundaries - a bookmark in the last few seconds of a track just
    // gets a shorter clip).
    final available = trackDuration.isFinite ? trackDuration - localOffset : windowSeconds;
    final window = available < windowSeconds ? available : windowSeconds;
    if (window <= 0.5) {
      throw TranscriptionException(TranscriptionError.extractFailed, 'window too short');
    }

    _busy = true;
    String? wavPath;
    final watch = Stopwatch()..start();
    try {
      wavPath = await _extractWav(
        sourcePath: sourcePath,
        startSeconds: localOffset,
        durationSeconds: window,
      );
      final extractMs = watch.elapsedMilliseconds;
      if (wavPath == null || !File(wavPath).existsSync()) {
        throw TranscriptionException(TranscriptionError.extractFailed);
      }

      // NB: TranscribeResult isn't exported by the package, so let the type be
      // inferred rather than naming it. `.transcription` is a (exported)
      // WhisperTranscribeResponse whose `.text` is the full transcript.
      final String text;
      final lang = _bookLang[itemId] ?? 'auto';
      try {
        final result = await _whisper.transcribe(
          model: info.whisperModel,
          audioPath: wavPath,
          lang: lang,
          convert: false, // we always hand it a ready 16kHz WAV
          withTimestamps: false,
          // Audiobooks are wall-to-wall speech, and Silero turned out to cost
          // more per window than the transcription itself.
          vadMode: WhisperVadMode.disabled,
          threads: _threads(),
        );
        text = (result?.transcription.text ?? '').trim();
        _cacheLanguage(itemId, result?.language, text.isNotEmpty);
      } catch (e) {
        if (e is TranscriptionException) rethrow;
        throw TranscriptionException(TranscriptionError.transcribeFailed, e);
      }
      debugPrint('[Transcribe] window=${window.toStringAsFixed(1)}s '
          'model=${info.fileName} lang=$lang extract=${extractMs}ms '
          'whisper=${watch.elapsedMilliseconds - extractMs}ms '
          'chars=${text.length}');
      if (text.isEmpty) throw TranscriptionException(TranscriptionError.empty);
      // Hand the extracted clip to the caller (for review playback). Ownership
      // transfers, so null out wavPath to skip the finally-delete below.
      final out = (text: text, audioPath: wavPath);
      wavPath = null;
      return out;
    } finally {
      _busy = false;
      if (wavPath != null) {
        try {
          final f = File(wavPath);
          if (f.existsSync()) await f.delete();
        } catch (_) {}
      }
    }
  }

  bool get isBusy => _busy;

  /// Transcribe [windowSeconds] starting at global book time [startSeconds]
  /// and return the segments with timestamps relative to the window start.
  /// For audio-to-text alignment (Find in audiobook) - the extracted clip is
  /// deleted before returning. Same guards and exceptions as [transcribeAt].
  Future<List<({double start, double end, String text})>> transcribeWindowSegments({
    required String itemId,
    required double startSeconds,
    required double windowSeconds,
    bool? preferAccuracy,
    TranscriptionFeature feature = TranscriptionFeature.readAlong,
  }) async {
    if (!await PlayerSettings.getTranscriptionEnabled()) {
      throw TranscriptionException(TranscriptionError.disabled);
    }
    if (_busy) throw TranscriptionException(TranscriptionError.busy);

    final info = await _modelFor(preferAccuracy, feature);
    if (!await isModelDownloaded(info.size)) {
      throw TranscriptionException(TranscriptionError.modelMissing);
    }
    lastModelUsed = info.size;

    final localPaths = DownloadService().getLocalPaths(itemId);
    if (localPaths == null || localPaths.isEmpty) {
      throw TranscriptionException(TranscriptionError.notDownloaded);
    }

    final durations = _trackDurations(itemId);
    final int trackIndex;
    final double localOffset;
    final double trackDuration;
    final double gStart = startSeconds.clamp(0.0, double.infinity);
    if (durations != null && durations.length == localPaths.length) {
      final m = mapGlobalToTrack(durations, gStart);
      trackIndex = m.index;
      localOffset = m.offset;
      trackDuration = durations[trackIndex];
    } else if (localPaths.length == 1) {
      trackIndex = 0;
      localOffset = gStart;
      trackDuration = double.infinity;
    } else {
      throw TranscriptionException(TranscriptionError.noMetadata);
    }

    final sourcePath = localPaths[trackIndex];
    // Books in a custom Android (SAF) folder are content:// URIs - File()
    // can't see those, but the native extractor opens them fine.
    if (!sourcePath.startsWith('content://') && !File(sourcePath).existsSync()) {
      throw TranscriptionException(TranscriptionError.notDownloaded, sourcePath);
    }

    final available = trackDuration.isFinite ? trackDuration - localOffset : windowSeconds;
    final window = available < windowSeconds ? available : windowSeconds;
    if (window <= 0.5) {
      throw TranscriptionException(TranscriptionError.extractFailed, 'window too short');
    }

    _busy = true;
    String? wavPath;
    final watch = Stopwatch()..start();
    try {
      wavPath = await _extractWav(
        sourcePath: sourcePath,
        startSeconds: localOffset,
        durationSeconds: window,
      );
      final extractMs = watch.elapsedMilliseconds;
      if (wavPath == null || !File(wavPath).existsSync()) {
        throw TranscriptionException(TranscriptionError.extractFailed);
      }

      final List<({double start, double end, String text})> segments;
      final lang = _bookLang[itemId] ?? 'auto';
      try {
        final result = await _whisper.transcribe(
          model: info.whisperModel,
          audioPath: wavPath,
          lang: lang,
          convert: false,
          withTimestamps: true,
          // See transcribeAt - Silero cost more per window than whisper.
          vadMode: WhisperVadMode.disabled,
          // This path feeds the live transcript, where a late answer is as
          // bad as a wrong one. A failed window just gets skipped over.
          noFallback: true,
          threads: _threads(),
        );
        segments = (result?.transcription.segments ?? const [])
            .map((s) => (
                  start: s.fromTs.inMilliseconds / 1000.0,
                  end: s.toTs.inMilliseconds / 1000.0,
                  text: s.text.trim(),
                ))
            .where((s) => s.text.isNotEmpty)
            .toList();
        _cacheLanguage(itemId, result?.language, segments.isNotEmpty);
      } catch (e) {
        if (e is TranscriptionException) rethrow;
        throw TranscriptionException(TranscriptionError.transcribeFailed, e);
      }
      debugPrint('[Transcribe] segments window=${window.toStringAsFixed(1)}s '
          'model=${info.fileName} lang=$lang extract=${extractMs}ms '
          'whisper=${watch.elapsedMilliseconds - extractMs}ms '
          'threads=${_threads()} segments=${segments.length}');
      if (segments.isEmpty) throw TranscriptionException(TranscriptionError.empty);
      return segments;
    } finally {
      _busy = false;
      if (wavPath != null) {
        try {
          final f = File(wavPath);
          if (f.existsSync()) await f.delete();
        } catch (_) {}
      }
    }
  }

  // Internals

  // Capped at 4, not core count: whisper barriers its threads at every layer,
  // so the slowest thread gates each step. On big.LITTLE phones a fifth and
  // sixth thread land on little cores, and once Android's touch boost decays
  // those drop to idle clocks and drag a 7s window out past 30s. Four threads
  // stay on the big and mid cores and hold their speed unboosted.
  int _threads() => (Platform.numberOfProcessors - 1).clamp(2, 4);

  /// Remember what language detection settled on, but only from a window that
  /// actually produced output - a detection made on silence or music would
  /// pin the whole book to a garbage language.
  void _cacheLanguage(String itemId, String? detected, bool hadOutput) {
    if (!hadOutput || _bookLang.containsKey(itemId)) return;
    if (detected == null || detected.isEmpty || detected == 'auto') return;
    _bookLang[itemId] = detected;
    debugPrint('[Transcribe] $itemId speaks "$detected"');
  }

  /// Per-track durations (seconds) from the cached offline session metadata,
  /// index-aligned with the downloaded track files. Null when unavailable.
  List<double>? _trackDurations(String itemId) {
    final raw = DownloadService().getCachedSessionData(itemId);
    if (raw == null || raw.isEmpty) return null;
    try {
      final session = jsonDecode(raw) as Map<String, dynamic>;
      final tracks = session['audioTracks'] as List<dynamic>?;
      if (tracks == null || tracks.isEmpty) return null;
      return tracks
          .map((t) => ((t as Map<String, dynamic>)['duration'] as num?)?.toDouble() ?? 0.0)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Decode a clip of [sourcePath] into a playable standalone WAV, for
  /// surfaces that need a small file instead of the original (the bookmark
  /// audition falls back to this when a second player can't open a huge
  /// single-file book). Never touches the whisper engine, so no gating.
  Future<String?> extractClipWav({
    required String sourcePath,
    required double startSeconds,
    required double durationSeconds,
  }) =>
      _extractWav(
        sourcePath: sourcePath,
        startSeconds: startSeconds,
        durationSeconds: durationSeconds,
      );

  /// Ask native code to decode [durationSeconds] of [sourcePath] starting at
  /// [startSeconds] into a 16kHz mono WAV, returning the temp file path.
  Future<String?> _extractWav({
    required String sourcePath,
    required double startSeconds,
    required double durationSeconds,
  }) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath =
        '${tmpDir.path}${Platform.pathSeparator}absorb_transcribe_${DateTime.now().microsecondsSinceEpoch}.wav';
    try {
      final ok = await _channel.invokeMethod<bool>('extractWav', {
        'sourcePath': sourcePath,
        'startSeconds': startSeconds,
        'durationSeconds': durationSeconds,
        'outPath': outPath,
      });
      return ok == true ? outPath : null;
    } on PlatformException catch (e) {
      throw TranscriptionException(TranscriptionError.extractFailed, e.message);
    } on MissingPluginException catch (e) {
      throw TranscriptionException(TranscriptionError.extractFailed, e.message);
    }
  }
}
