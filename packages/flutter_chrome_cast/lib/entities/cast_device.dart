/// Represents a Google Cast device discovered on the network.
///
/// This class contains all the information about a Cast-capable device
/// that has been discovered during the device discovery process.
class GoogleCastDevice {
  /// Unique identifier for the device.
  final String deviceID;

  /// Human-readable name of the device (e.g., "Living Room TV").
  final String friendlyName;

  /// Model name of the device (e.g., "Chromecast", "Google Home").
  final String? modelName;

  /// Current status text displayed by the device.
  final String? statusText;

  /// Version information of the device firmware/software.
  final String deviceVersion;

  /// Whether the device is on the same local network.
  final bool isOnLocalNetwork;

  /// Category or type of the device.
  final String category;

  /// Globally unique identifier for the device.
  final String uniqueID;

  /// Creates a new Google Cast device instance.
  ///
  /// All parameters except [modelName] and [statusText] are required.
  GoogleCastDevice({
    required this.deviceID,
    required this.friendlyName,
    required this.modelName,
    required this.statusText,
    required this.deviceVersion,
    required this.isOnLocalNetwork,
    required this.category,
    required this.uniqueID,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GoogleCastDevice && other.deviceID == deviceID;
  }

  @override
  int get hashCode {
    return deviceID.hashCode;
  }
}
