import 'package:flutter_chrome_cast/entities/cast_session.dart';
import 'package:flutter_chrome_cast/enums/connection_state.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_device.dart';

/// Represents a Google Cast session on iOS devices.
///
/// This class extends [GoogleCastSession] and provides additional
/// functionality specific to iOS, including a factory method for
/// creating an instance from a map (typically from JSON).
class IOSGoogleCastSessions extends GoogleCastSession {
  /// Creates an [IOSGoogleCastSessions] instance.
  ///
  /// All parameters are required and are passed to the superclass constructor.
  IOSGoogleCastSessions({
    required super.device,
    required super.sessionID,
    required super.connectionState,
    required super.currentDeviceMuted,
    required super.currentDeviceVolume,
    required super.deviceStatusText,
  });

  /// Creates an [IOSGoogleCastSessions] instance from a [Map] (e.g., JSON).
  ///
  /// Returns `null` if the input [json] is `null`.
  /// Throws if required fields are missing or of incorrect type.
  static IOSGoogleCastSessions? fromMap(Map<String, dynamic>? json) {
    if (json == null) return null;
    return IOSGoogleCastSessions(
      device: GoogleCastIosDevice.fromMap(
          Map<String, dynamic>.from(json['device'])),
      sessionID: json['sessionID'],
      connectionState: GoogleCastConnectState.values[json['connectionState']],
      currentDeviceMuted: json['currentDeviceMuted'],
      currentDeviceVolume: json['currentDeviceVolume'],
      deviceStatusText: json['deviceStatusText'] ?? '',
    );
  }
}
