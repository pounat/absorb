import 'package:freezed_annotation/freezed_annotation.dart';

import 'whisper_vad_mode.dart';

part 'transcribe_request.freezed.dart';

/// Transcription request parameters
@freezed
abstract class TranscribeRequest with _$TranscribeRequest {
  const factory TranscribeRequest({
    required String audio,
    @Default(false) bool isTranslate,
    @Default(6) int threads,
    @Default(false) bool isVerbose,
    @Default('en') String language,
    @Default(false) bool isSpecialTokens,
    @Default(false) bool isNoTimestamps,
    @Default(false) bool isRealtime,
    @Default(1) int nProcessors,
    @Default(false) bool splitOnWord,
    @Default(false) bool noFallback,
    @Default(false) bool diarize,
    @Default(false) bool speedUp,
    @Default(WhisperVadMode.auto) WhisperVadMode vadMode,
    String? vadModelPath,
    @Default(null) Stream<String>? realtimeStream,
  }) = _TranscribeRequest;
  const TranscribeRequest._();
}
