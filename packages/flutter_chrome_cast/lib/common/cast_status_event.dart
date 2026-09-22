/// Represents different types of cast status events.
///
/// These events are used to categorize different types of status updates
/// that can be received from a Google Cast session.
enum CastStatusType {
  /// Media status events related to playback state, position, etc.
  mediaStatus('MEDIA_STATUS'),

  /// Receiver status events related to device state, volume, etc.
  receiverStatus('RECEIVER_STATUS'),

  /// Unknown or unhandled status event type.
  unknow('UNKNOW');

  /// The raw string value associated with this status type.
  final String rawValue;

  /// Creates a cast status type with the given raw value.
  const CastStatusType(this.rawValue);

  /// Creates a [CastStatusType] from a string value.
  ///
  /// Returns [CastStatusType.unknow] if the string doesn't match any known type.
  factory CastStatusType.fromString(String name) {
    return CastStatusType.values.firstWhere(
        (element) => element.rawValue == name,
        orElse: () => CastStatusType.unknow);
  }
}

/// Represents a cast message event received from a Google Cast session.
///
/// This class encapsulates status updates and other messages that are
/// sent from the Cast receiver to the sender application.
class CastMessageEvent {
  /// The type of status event this message represents.
  final CastStatusType type;

  /// Creates a new cast message event.
  ///
  /// [type] specifies the category of this status event.
  CastMessageEvent({
    required this.type,
  });
}
