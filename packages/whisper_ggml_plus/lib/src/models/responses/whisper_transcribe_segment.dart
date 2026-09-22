// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'whisper_transcribe_segment.freezed.dart';
part 'whisper_transcribe_segment.g.dart';

@freezed

/// Transcribe segment model
abstract class WhisperTranscribeSegment with _$WhisperTranscribeSegment {
  ///
  const factory WhisperTranscribeSegment({
    @JsonKey(
      name: 'from_ts',
      fromJson: WhisperTranscribeSegment._durationFromInt,
    )
    required Duration fromTs,
    @JsonKey(name: 'to_ts', fromJson: WhisperTranscribeSegment._durationFromInt)
    required Duration toTs,
    required String text,
  }) = _WhisperTranscribeSegment;

  /// Parse [json] to WhisperTranscribeSegment
  factory WhisperTranscribeSegment.fromJson(Map<String, dynamic> json) =>
      _$WhisperTranscribeSegmentFromJson(json);

  static Duration _durationFromInt(int timestamp) {
    return Duration(milliseconds: timestamp * 10);
  }
}
