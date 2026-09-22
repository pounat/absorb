import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/enums/connection_state.dart';

/// Represents a Google Cast session.
abstract class GoogleCastSession {
  /// The device associated with this session.
  final GoogleCastDevice? device;

  /// The unique session ID.
  final String? sessionID;

  /// The current connection state.
  final GoogleCastConnectState connectionState;

  /// Whether the current device is muted.
  final bool currentDeviceMuted;

  /// The current device volume level.
  final double currentDeviceVolume;

  /// The device status text.
  final String deviceStatusText;

  /// Creates a new [GoogleCastSession].
  GoogleCastSession({
    required this.device,
    required this.sessionID,
    required this.connectionState,
    required this.currentDeviceMuted,
    required this.currentDeviceVolume,
    required this.deviceStatusText,
  });
}
