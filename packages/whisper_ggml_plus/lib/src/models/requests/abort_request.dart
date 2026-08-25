import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whisper_ggml_plus/src/models/whisper_dto.dart';

part 'abort_request.freezed.dart';

@freezed
class AbortRequest with _$AbortRequest implements WhisperRequestDto {
  const factory AbortRequest() = _AbortRequest;
  const AbortRequest._();

  @override
  String get specialType => 'abort';

  @override
  String toRequestString() {
    return json.encode({'@type': specialType});
  }
}
