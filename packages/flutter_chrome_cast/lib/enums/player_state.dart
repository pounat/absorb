/// Represents the current state of the media player.
///
/// This enum defines the different states that a Cast media player
/// can be in during media playback and control operations.
enum CastMediaPlayerState {
  /// Unknown or uninitialized state.
  unknown,

  /// IDLE - Player has not been loaded yet or has finished playback.
  idle,

  /// Player is actively playing content.
  playing,

  /// Player is paused.
  paused,

  /// Player is in PLAY mode but not actively playing content (currentTime is not changing).
  /// This typically occurs when the player is loading or buffering content.
  buffering,

  /// Player is loading media.
  loading;
}
