/// Enum representing different types of text tracks for Google Cast.
enum TextTrackType {
  /// Unknown text track type.
  unknown,

  ///Transcription or translation of the dialogue,
  /// suitable for when the sound is available
  /// but not understood (e.g. because the user
  ///  does not understand the language of
  /// the media resource's soundtrack).
  subtitles,

  ///Transcription or translation of the dialogue,
  /// sound effects, relevant musical cues, and
  /// other relevant audio information, suitable
  ///  for when the soundtrack is unavailable
  /// (e.g. because it is muted or because
  /// the user is deaf). Displayed over the
  /// video; labeled as appropriate for
  /// the hard-of-hearing.
  captions,

  ///Textual descriptions of the video component
  /// of the media resource, intended for audio synthesis
  ///  when the visual component is unavailable
  /// (e.g. because the user is interacting with the
  /// application without a screen, or because the user is blind).
  ///  Synthesized as separate audio track.
  descriptions,

  ///Chapter titles, intended to be used
  /// for navigating the media resource.
  chapters,

  /// Tracks intended for use from script.
  metadata;
}
