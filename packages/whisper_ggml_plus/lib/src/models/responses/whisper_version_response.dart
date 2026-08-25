// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'whisper_version_response.freezed.dart';
part 'whisper_version_response.g.dart';

/// Response model of whisper getVersion
@freezed
abstract class WhisperVersionResponse with _$WhisperVersionResponse {
  ///
  const factory WhisperVersionResponse({
    @JsonKey(name: '@type') required String type,
    required String message,
  }) = _WhisperVersionResponse;

  const WhisperVersionResponse._();

  /// Parse [json] to WhisperVersionResponse
  factory WhisperVersionResponse.fromJson(Map<String, dynamic> json) =>
      _$WhisperVersionResponseFromJson(json);
}
