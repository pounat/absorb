import 'package:flutter_chrome_cast/enums/media_resume_state.dart';

///Enum defining the media control channel resume state.
class GoogleCastMediaSeekOption {
  /// The position to seek to.
  final Duration position;

  /// Whether the seek is relative to current position.
  final bool relative;

  /// The resume state after seeking.
  final GoogleCastMediaResumeState resumeState;

  /// Whether to seek to infinity (live content).
  final bool seekToInfinity;

  /// Creates a new [GoogleCastMediaSeekOption].
  GoogleCastMediaSeekOption({
    required this.position,
    this.relative = false,
    this.resumeState = GoogleCastMediaResumeState.play,
    this.seekToInfinity = false,
  });

  /// Converts these seek options to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'position': position.inSeconds,
      'relative': relative,
      'resumeState': resumeState.index,
      'seekToInfinity': seekToInfinity,
    };
  }
}
