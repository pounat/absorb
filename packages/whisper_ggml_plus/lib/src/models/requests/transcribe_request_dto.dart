// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whisper_ggml_plus/src/models/requests/transcribe_request.dart';
import 'package:whisper_ggml_plus/src/models/requests/whisper_vad_mode.dart';
import 'package:whisper_ggml_plus/src/models/whisper_dto.dart';

part 'transcribe_request_dto.freezed.dart';
part 'transcribe_request_dto.g.dart';

/// Transcribe request sent to whisper.cpp
@freezed
abstract class TranscribeRequestDto
    with _$TranscribeRequestDto
    implements WhisperRequestDto {
  ///
  const factory TranscribeRequestDto({
    required String audio,
    required String model,
    @JsonKey(name: 'is_translate') required bool isTranslate,
    required int threads,
    @JsonKey(name: 'is_verbose') required bool isVerbose,
    required String language,
    @JsonKey(name: 'is_special_tokens') required bool isSpecialTokens,
    @JsonKey(name: 'is_no_timestamps') required bool isNoTimestamps,
    @JsonKey(name: 'n_processors') required int nProcessors,
    @JsonKey(name: 'split_on_word') required bool splitOnWord,
    @JsonKey(name: 'no_fallback') required bool noFallback,
    @JsonKey(name: 'is_realtime') required bool isRealtime,
    required bool diarize,
    @JsonKey(name: 'speed_up') required bool speedUp,
    @JsonKey(name: 'vad_mode') required String vadMode,
    @JsonKey(name: 'vad_model_path') String? vadModelPath,
  }) = _TranscribeRequestDto;

  /// Convert [request] to TranscribeRequestDto with specified [modelPath]
  factory TranscribeRequestDto.fromTranscribeRequest(
    TranscribeRequest request,
    String modelPath,
  ) {
    return TranscribeRequestDto(
      audio: request.audio,
      model: modelPath,
      isTranslate: request.isTranslate,
      threads: request.threads,
      isVerbose: request.isVerbose,
      language: request.language,
      isSpecialTokens: request.isSpecialTokens,
      isNoTimestamps: request.isNoTimestamps,
      nProcessors: request.nProcessors,
      splitOnWord: request.splitOnWord,
      noFallback: request.noFallback,
      diarize: request.diarize,
      speedUp: request.speedUp,
      isRealtime: request.isRealtime,
      vadMode: request.vadMode.wireValue,
      vadModelPath: request.vadModelPath,
    );
  }
  const TranscribeRequestDto._();

  /// Create request json
  factory TranscribeRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TranscribeRequestDtoFromJson(json);

  @override
  String get specialType => 'getTextFromWavFile';

  @override
  String toRequestString() {
    return json.encode({'@type': specialType, ...toJson()});
  }
}
