/// Represents the connection state of a Google Cast session.
///
/// This enum defines the possible states of a Cast connection,
/// from disconnected to fully connected and ready for media control.
enum GoogleCastConnectState {
  /// Disconnected from the device or application.
  disconnected,

  /// Connecting to the device or application.
  connecting,

  /// Connected to the device or application.
  connected,

  ///Disconnecting from the device.
  disconnecting,
}
