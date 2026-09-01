import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:whisper_ggml_plus/src/models/whisper_model.dart';

import 'bundled_vad_model_resolver.dart';
import 'models/requests/abort_request.dart';
import 'models/requests/dispose_request.dart';
import 'models/requests/transcribe_request.dart';
import 'models/requests/transcribe_request_dto.dart';
import 'models/requests/version_request.dart';
import 'models/responses/whisper_transcribe_response.dart';
import 'models/responses/whisper_version_response.dart';
import 'models/whisper_dto.dart';

export 'models/_models.dart';
export 'whisper_audio_convert.dart';

/// Native request type
typedef WReqNative = Pointer<Utf8> Function(Pointer<Utf8> body);
typedef WFreeStringNative = Void Function(Pointer<Utf8> response);

/// Entry point
class Whisper {
  /// [model] is required
  /// [modelDir] is path where downloaded model will be stored.
  /// Default to library directory
  const Whisper({required this.model, this.modelDir});

  /// model used for transcription
  final WhisperModel model;

  /// override of model storage path
  final String? modelDir;

  /// The arm64 libwhisper.so is compiled for armv8.2-a+dotprod+fp16, which
  /// Cortex-A73-class and older cores (Boox Palma, SD835-era phones) cannot
  /// execute - the first call SIGILLs. Those CPUs get the baseline
  /// libwhisper_compat.so instead. Requiring the extensions on every core
  /// keeps mixed-cluster devices on the safe side.
  static final bool usesCompatEngine = _detectCompatEngine();

  static bool _detectCompatEngine() {
    if (!Platform.isAndroid) return false;
    try {
      final features = File('/proc/cpuinfo')
          .readAsLinesSync()
          .where((line) => line.startsWith('Features'));
      if (features.isEmpty) return false;
      return !features.every(
        (line) => line.contains('asimddp') && line.contains('asimdhp'),
      );
    } catch (_) {
      return false;
    }
  }

  DynamicLibrary _openLib() {
    if (Platform.isAndroid) {
      if (usesCompatEngine) {
        try {
          return DynamicLibrary.open('libwhisper_compat.so');
        } catch (_) {
          // Only packaged for arm64-v8a; every other ABI's libwhisper.so is
          // already a baseline build.
        }
      }
      return DynamicLibrary.open('libwhisper.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('whisper_ggml_plus.dll');
    } else {
      return DynamicLibrary.process();
    }
  }

  Future<Map<String, dynamic>> _request({
    required WhisperRequestDto whisperRequest,
  }) async {
    return Isolate.run(() async {
      final DynamicLibrary library = _openLib();
      final WReqNative requestNative =
          library.lookupFunction<WReqNative, WReqNative>('request');
      final void Function(Pointer<Utf8>) freeStringNative = library
          .lookupFunction<WFreeStringNative, void Function(Pointer<Utf8>)>(
        'free_string',
      );
      final Pointer<Utf8> data =
          whisperRequest.toRequestString().toNativeUtf8();
      Pointer<Utf8> response = Pointer<Utf8>.fromAddress(0);

      try {
        response = requestNative(data);
        if (response.address == 0) {
          throw Exception('Native request returned null');
        }

        return json.decode(response.toDartString()) as Map<String, dynamic>;
      } finally {
        malloc.free(data);
        if (response.address != 0) {
          freeStringNative(response);
        }
      }
    });
  }

  /// Transcribe audio file to text. [language] is what the native side
  /// detected (or was told), e.g. "en".
  Future<({WhisperTranscribeResponse response, String? language})> transcribe({
    required TranscribeRequest transcribeRequest,
    required String modelPath,
  }) async {
    try {
      final TranscribeRequest resolvedRequest =
          await resolveVadModelPath(transcribeRequest);
      final Map<String, dynamic> result = await _request(
        whisperRequest: TranscribeRequestDto.fromTranscribeRequest(
          resolvedRequest,
          modelPath,
        ),
      );

      if (result['text'] == null) {
        throw Exception(result['message']);
      }
      return (
        response: WhisperTranscribeResponse.fromJson(result),
        language: result['language'] as String?,
      );
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  /// Get whisper version
  Future<String?> getVersion() async {
    final Map<String, dynamic> result = await _request(
      whisperRequest: const VersionRequest(),
    );

    final WhisperVersionResponse response = WhisperVersionResponse.fromJson(
      result,
    );
    return response.message;
  }

  Future<void> abort() async {
    await _request(whisperRequest: const AbortRequest());
  }

  Future<void> dispose() async {
    await _request(whisperRequest: const DisposeRequest());
  }
}
