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

enum TranscriptionModelSize { tiny, small }

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

  static const small = TranscriptionModelInfo(
    size: TranscriptionModelSize.small,
    whisperModel: WhisperModel.small,
    downloadUrl:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin',
    fileName: 'ggml-small.bin',
    approxBytes: 190 * 1024 * 1024, // ~182 MB
  );

  static TranscriptionModelInfo forSize(TranscriptionModelSize size) =>
      size == TranscriptionModelSize.small ? small : tiny;

  static TranscriptionModelInfo fromPref(String value) =>
      value == 'small' ? small : tiny;
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

  /// Transcribe the audio around [positionSeconds] of [itemId]. Returns the
  /// transcript text plus the path to the extracted 16kHz WAV clip, which the
  /// caller can play back for review and MUST delete when finished. Throws
  /// [TranscriptionException] on any failure so the UI can show a specific message.
  Future<({String text, String audioPath})> transcribeAt({
    required String itemId,
    required double positionSeconds,
    double windowSeconds = _windowSeconds,
    double leadSeconds = _leadSeconds,
  }) async {
    if (!await PlayerSettings.getTranscriptionEnabled()) {
      throw TranscriptionException(TranscriptionError.disabled);
    }
    if (_busy) throw TranscriptionException(TranscriptionError.busy);

    final info = TranscriptionModelInfo.fromPref(
        await PlayerSettings.getTranscriptionModel());
    if (!await isModelDownloaded(info.size)) {
      throw TranscriptionException(TranscriptionError.modelMissing);
    }

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
    if (!File(sourcePath).existsSync()) {
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
      try {
        final result = await _whisper.transcribe(
          model: info.whisperModel,
          audioPath: wavPath,
          lang: 'auto',
          convert: false, // we always hand it a ready 16kHz WAV
          withTimestamps: false,
          // Must be auto/enabled, NOT disabled: with disabled the package sends
          // vad_model_path as JSON null and the native parser does .get<string>()
          // on it, throwing "type must be string, but is null". auto makes the
          // package extract its bundled Silero VAD model and pass a real path.
          vadMode: WhisperVadMode.auto,
          threads: _threads(),
        );
        text = (result?.transcription.text ?? '').trim();
      } catch (e) {
        if (e is TranscriptionException) rethrow;
        throw TranscriptionException(TranscriptionError.transcribeFailed, e);
      }
      debugPrint('[Transcribe] window=${window.toStringAsFixed(1)}s '
          'model=${info.fileName} extract=${extractMs}ms '
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
  }) async {
    if (!await PlayerSettings.getTranscriptionEnabled()) {
      throw TranscriptionException(TranscriptionError.disabled);
    }
    if (_busy) throw TranscriptionException(TranscriptionError.busy);

    final info = TranscriptionModelInfo.fromPref(
        await PlayerSettings.getTranscriptionModel());
    if (!await isModelDownloaded(info.size)) {
      throw TranscriptionException(TranscriptionError.modelMissing);
    }

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
    if (!File(sourcePath).existsSync()) {
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
      try {
        final result = await _whisper.transcribe(
          model: info.whisperModel,
          audioPath: wavPath,
          lang: 'auto',
          convert: false,
          withTimestamps: true,
          // Must be auto, not disabled - see transcribeAt.
          vadMode: WhisperVadMode.auto,
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
      } catch (e) {
        if (e is TranscriptionException) rethrow;
        throw TranscriptionException(TranscriptionError.transcribeFailed, e);
      }
      debugPrint('[Transcribe] segments window=${window.toStringAsFixed(1)}s '
          'model=${info.fileName} extract=${extractMs}ms '
          'whisper=${watch.elapsedMilliseconds - extractMs}ms '
          'segments=${segments.length}');
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

  int _threads() => (Platform.numberOfProcessors - 1).clamp(2, 6);

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
