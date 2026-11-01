import 'responses/whisper_transcribe_response.dart';

class TranscribeResult {
  const TranscribeResult({
    required this.transcription,
    required this.time,
    this.language,
    this.backend,
    this.log,
  });
  final WhisperTranscribeResponse transcription;
  final Duration time;

  /// Language the native side detected (or was told), e.g. "en".
  final String? language;

  /// Where whisper ran this time ("metal" or "cpu"); iOS only.
  final String? backend;

  /// What ggml and whisper logged during this request; iOS only.
  final String? log;
}
