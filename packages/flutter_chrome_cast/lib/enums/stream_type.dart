/// Represents the type of media stream for Google Cast playback.
///
/// This enum defines the different types of media streams that can be
/// played through Google Cast, affecting how the media is handled and controlled.
enum CastMediaStreamType {
  /// No stream type specified or unknown.
  none('NONE'),

  /// Pre-recorded content that can be buffered and seeked.
  buffered('BUFFERED'),

  /// Live streaming content that cannot be seeked.
  live('LIVE');

  /// The string value used in Cast protocol communication.
  final String value;

  /// Creates a stream type with the given protocol value.
  const CastMediaStreamType(this.value);

  /// Creates a [CastMediaStreamType] from a string value.
  ///
  /// Returns [CastMediaStreamType.none] if the value doesn't match any known type.
  factory CastMediaStreamType.fromMap(String value) =>
      CastMediaStreamType.values.firstWhere(
        (element) => element.value == value,
        orElse: () => CastMediaStreamType.none,
      );
}
