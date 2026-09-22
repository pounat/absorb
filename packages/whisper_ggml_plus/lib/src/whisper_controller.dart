import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:whisper_ggml_plus/src/models/whisper_model.dart';

import 'models/whisper_result.dart';
import 'whisper.dart';

class WhisperController {
  String _modelPath = '';
  String? _dir;

  /// Global audio converter instance.
  /// Can be registered by external packages like whisper_ggml_plus_ffmpeg.
  static WhisperAudioConverter? _audioConverter;

  /// Register a custom audio converter.
  static void registerAudioConverter(WhisperAudioConverter converter) {
    _audioConverter = converter;
    debugPrint('🚀 [WHISPER ENGINE] Audio converter registered');
  }

  Future<void> initModel(WhisperModel model) async {
    _dir ??= await getModelDir();
    _modelPath = '$_dir/ggml-${model.modelName}.bin';
  }

  Future<TranscribeResult?> transcribe({
    required WhisperModel model,
    required String audioPath,
    String lang = 'en',
    bool diarize = false,
    bool withTimestamps = true,
    bool splitOnWord = false,
    bool convert = true,
    int threads = 6,
    bool isTranslate = false,
    bool speedUp = false,
    bool noFallback = false,
    WhisperVadMode vadMode = WhisperVadMode.auto,
    String? vadModelPath,
  }) async {
    await initModel(model);

    final Whisper whisper = Whisper(model: model);
    final DateTime start = DateTime.now();

    try {
      String finalAudioPath = audioPath;

      // Automatic conversion logic
      final bool isWav = audioPath.toLowerCase().endsWith('.wav');

      if (convert && !isWav) {
        if (_audioConverter != null) {
          debugPrint(
              '⚙️  [WHISPER ENGINE] Converting audio using registered converter...');
          final File? convertedFile =
              await _audioConverter!.convert(File(audioPath));
          if (convertedFile != null) {
            finalAudioPath = convertedFile.path;
          } else {
            debugPrint('⚠️  [WHISPER ENGINE] Audio conversion failed');
          }
        } else {
          debugPrint('⚠️  [WHISPER ENGINE] No audio converter registered. '
              'Please install whisper_ggml_plus_ffmpeg or provide a 16kHz WAV file.');
        }
      }

      final result = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: finalAudioPath,
          language: lang,
          isTranslate: isTranslate,
          threads: threads,
          isNoTimestamps: !withTimestamps,
          splitOnWord: splitOnWord,
          isRealtime: true,
          diarize: diarize,
          speedUp: speedUp,
          noFallback: noFallback,
          vadMode: vadMode,
          vadModelPath: vadModelPath,
        ),
        modelPath: _modelPath,
      );

      final DateTime end = DateTime.now();
      final Duration totalDuration = end.difference(start);

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [TRANSCRIPTION COMPLETE]');
      debugPrint(
          '⏱️  Total time (inc. conversion): ${totalDuration.inMilliseconds}ms');
      debugPrint('📊 Segments: ${result.response.segments?.length ?? 0}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return TranscribeResult(
        time: totalDuration,
        transcription: result.response,
        language: result.language,
      );
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  static Future<String> getModelDir() async {
    final Directory libraryDirectory = Platform.isIOS || Platform.isMacOS
        ? await getLibraryDirectory()
        : await getApplicationSupportDirectory();
    return libraryDirectory.path;
  }

  /// Get local path of model file
  Future<String> getPath(WhisperModel model) async {
    _dir ??= await getModelDir();
    return '$_dir/ggml-${model.modelName}.bin';
  }

  /// Download [model] to [destinationPath]
  Future<String> downloadModel(WhisperModel model) async {
    if (!File(await getPath(model)).existsSync()) {
      final request = await HttpClient().getUrl(model.modelUri);

      final response = await request.close();

      final bytes = await consolidateHttpClientResponseBytes(response);

      final File file = File(await getPath(model));
      await file.writeAsBytes(bytes);

      return file.path;
    } else {
      return await getPath(model);
    }
  }

  Future<void> dispose({WhisperModel model = WhisperModel.base}) async {
    final Whisper whisper = Whisper(model: model);
    await whisper.dispose();
    _modelPath = '';
  }
}
