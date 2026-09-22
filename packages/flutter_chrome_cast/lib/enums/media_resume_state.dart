/// Enum representing different media resume states for Google Cast.
enum GoogleCastMediaResumeState {
  ///A resume state indicating that the player state should be left unchanged.
  unchanged,

  ///A resume state indicating that the player should be playing, regardless of its current state.
  play,

  ///A resume state indicating that the player should be paused, regardless of its current state.
  pause;
}
