import 'package:universal_io/io.dart';

/// Interface for audio conversion.
/// Implement this to provide custom audio conversion logic (e.g., using FFmpeg).
abstract class WhisperAudioConverter {
  /// Converts the given [input] file to a 16kHz mono WAV file.
  /// Returns the converted [File], or null if conversion fails.
  Future<File?> convert(File input);
}
