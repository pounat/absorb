import 'dart:convert';

import 'package:whisper_ggml_plus/src/models/whisper_dto.dart';

class DisposeRequest implements WhisperRequestDto {
  const DisposeRequest();

  @override
  String get specialType => 'dispose';

  @override
  String toRequestString() {
    return json.encode({'@type': specialType});
  }
}
