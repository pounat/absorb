import 'responses/whisper_transcribe_response.dart';

class TranscribeResult {
  const TranscribeResult({
    required this.transcription,
    required this.time,
    this.language,
  });
  final WhisperTranscribeResponse transcription;
  final Duration time;

  /// Language the native side detected (or was told), e.g. "en".
  final String? language;
}
