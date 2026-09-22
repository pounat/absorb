/// Represents the reason why media playback became idle.
///
/// This enum defines the different reasons why a Cast media session
/// might transition to an idle state, indicating why playback stopped.
enum GoogleCastMediaIdleReason {
  /// No specific reason or unknown reason.
  none,

  /// The media playback completed naturally.
  finished,

  /// A sender requested to stop playback using the STOP command.
  cancelled,

  /// INTERRUPTED - A sender requested playing a different media using the LOAD command.
  interrupted,

  ///ERROR  The media was interrupted due to an error; for example, if the player could not download the media due to network issues
  error;
}
