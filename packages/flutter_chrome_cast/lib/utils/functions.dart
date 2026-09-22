import '../entities/entities.dart';

/// Calculates the playback percentage based on current position and total duration.
///
/// This function computes how much of the media has been played as a percentage
/// (0.0 to 1.0) based on the current playback position and the total media duration.
///
/// Returns null if either the current duration or media duration is null or zero.
/// Returns 1.0 if the percentage would exceed 100% (should not normally happen).
///
/// [mediaStatus] - The current media status containing duration information
/// [currentDuration] - The current playback position
double? getPlayerPercentage(
    GoggleCastMediaStatus mediaStatus, Duration? currentDuration) {
  if (currentDuration == null || currentDuration.inSeconds == 0) return null;
  final mediaDuration = mediaStatus.mediaInformation?.duration;
  if (mediaDuration == null || mediaDuration.inSeconds == 0) return null;
  final percentage = currentDuration.inSeconds / mediaDuration.inSeconds;
  if (percentage > 1) return 1;
  return percentage;
}
