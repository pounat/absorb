// Absorb patch: the engine and its controller for platforms without dart:ffi
// (the web). Same public surface as whisper.dart and whisper_controller.dart,
// so the app compiles for the browser; every call reports that transcription
// is not available there. Picked by the conditional exports in
// whisper_ggml_plus.dart.
import 'package:whisper_ggml_plus/src/models/whisper_model.dart';

import 'models/requests/transcribe_request.dart';
import 'models/requests/whisper_vad_mode.dart';
import 'models/responses/whisper_transcribe_response.dart';
import 'models/whisper_result.dart';
import 'whisper_audio_convert.dart';

UnsupportedError _unsupported() =>
    UnsupportedError('On-device transcription is not available in a browser');

class Whisper {
  const Whisper({required this.model, this.modelDir});

  final WhisperModel model;
  final String? modelDir;

  static final bool usesCompatEngine = false;

  Future<({WhisperTranscribeResponse response, String? language})> transcribe({
    required TranscribeRequest transcribeRequest,
    required String modelPath,
  }) async {
    throw _unsupported();
  }

  Future<String?> getVersion() async => null;

  Future<void> abort() async {}

  Future<void> dispose() async {}
}

class WhisperController {
  static void registerAudioConverter(WhisperAudioConverter converter) {}

  Future<void> initModel(WhisperModel model) async {}

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
    throw _unsupported();
  }

  // No model directory in a browser: nothing can be downloaded to it, so
  // isModelDownloaded reads false and the app treats the model as missing.
  static Future<String> getModelDir() async => '';

  Future<String> getPath(WhisperModel model) async =>
      'ggml-${model.modelName}.bin';

  Future<String> downloadModel(WhisperModel model) async {
    throw _unsupported();
  }

  Future<void> dispose({WhisperModel model = WhisperModel.base}) async {}
}
