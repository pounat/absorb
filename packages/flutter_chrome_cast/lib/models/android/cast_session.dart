import 'package:flutter_chrome_cast/lib.dart';

/// Represents a Google Cast session on Android devices.
///
/// This class extends [GoogleCastSession] and provides Android-specific
/// session details and mapping utilities.
class GoogleCastSessionAndroid extends GoogleCastSession {
  /// Creates a [GoogleCastSessionAndroid] instance with the given parameters.
  ///
  /// [device] is the Android device associated with the session.
  /// [sessionID] is the unique identifier for the session.
  /// [connectionState] indicates the current connection state.
  /// [currentDeviceMuted] is true if the device is muted.
  /// [currentDeviceVolume] is the current volume level.
  /// [deviceStatusText] is a status message from the device.
  GoogleCastSessionAndroid({
    required super.device,
    required super.sessionID,
    required super.connectionState,
    required super.currentDeviceMuted,
    required super.currentDeviceVolume,
    required super.deviceStatusText,
  });

  /// Creates a [GoogleCastSessionAndroid] from a map, typically received from platform channels.
  ///
  /// The [map] parameter should contain keys for device, sessionID, connectionState, isMute, volume, and statusMessage.
  factory GoogleCastSessionAndroid.fromMap(Map<String, dynamic> map) {
    final device = map['device'];
    return GoogleCastSessionAndroid(
      device: device != null
          ? GoogleCastAndroidDevice.fromMap(Map.from(map['device']))
          : null,
      sessionID: map['sessionID'],
      connectionState: GoogleCastConnectState.values[map['connectionState']],
      currentDeviceMuted: map['isMute'],
      currentDeviceVolume: map['volume'],
      deviceStatusText: map['statusMessage'] ?? '',
    );
  }
}
