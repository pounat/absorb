/// Common whisper request
abstract class WhisperRequestDto {
  /// Convert current request to String encoded whisper json
  String toRequestString();

  /// Type of request or response
  String get specialType;
}
