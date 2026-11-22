export 'src/models/whisper_model.dart';
// Absorb patch: the ffi engine only where dart:ffi exists; the browser gets
// a stub with the same surface that reports transcription as unavailable.
export 'src/whisper_unsupported.dart' if (dart.library.ffi) 'src/whisper.dart';
export 'src/whisper_audio_convert.dart';
export 'src/whisper_unsupported.dart' if (dart.library.ffi) 'src/whisper_controller.dart';
export 'src/models/_models.dart';
