/// Enum representing different types of media metadata for Google Cast.
enum GoogleCastMediaMetadataType {
  /// Generic media metadata type.
  genericMediaMetadata(0),

  /// Movie media metadata type.
  movieMediaMetadata(1),

  /// TV show media metadata type.
  tvShowMediaMetadata(2),

  /// Music track media metadata type.
  musicTrackMediaMetadata(3),

  /// Photo media metadata type.
  photoMediaMetadata(4);

  /// The integer value representing this metadata type.
  final int value;

  /// Creates a [GoogleCastMediaMetadataType] with the given [value].
  const GoogleCastMediaMetadataType(this.value);

  /// Creates a [GoogleCastMediaMetadataType] from an integer value.
  factory GoogleCastMediaMetadataType.fromMap(int value) {
    return values.firstWhere(
      (element) => element.value == value,
      orElse: () => genericMediaMetadata,
    );
  }
}
