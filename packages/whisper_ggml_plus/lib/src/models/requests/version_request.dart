import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whisper_ggml_plus/src/models/whisper_dto.dart';

part 'version_request.freezed.dart';

/// Get whisper version request
@freezed
class VersionRequest with _$VersionRequest implements WhisperRequestDto {
  ///
  const factory VersionRequest() = _VersionRequest;
  const VersionRequest._();

  @override
  String get specialType => 'getVersion';

  @override
  String toRequestString() {
    return json.encode({'@type': specialType});
  }
}
