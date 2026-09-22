import 'package:flutter_chrome_cast/entities/cast_device.dart';

/// Represents a Google Cast device specific to iOS platforms.
///
/// This class extends [GoogleCastDevice] to include iOS-specific properties
/// and construction from a map structure typically returned by iOS platform channels.
class GoogleCastIosDevice extends GoogleCastDevice {
  /// Optional index of the device in the iOS discovery list.
  final int? index;

  /// Creates a new [GoogleCastIosDevice] instance.
  ///
  /// All parameters except [index] are required and are passed to the base [GoogleCastDevice].
  GoogleCastIosDevice({
    required super.deviceID,
    required super.friendlyName,
    required super.modelName,
    required super.statusText,
    required super.deviceVersion,
    required super.isOnLocalNetwork,
    required super.category,
    required super.uniqueID,
    required this.index,
  });

  /// Creates a [GoogleCastIosDevice] from a map, typically from platform channel data.
  factory GoogleCastIosDevice.fromMap(Map<String, dynamic> map) {
    return GoogleCastIosDevice(
      deviceID: map['deviceID'] as String,
      friendlyName: map['friendlyName'] ?? '',
      modelName: map['modelName'],
      statusText: map['statusText'],
      deviceVersion: map['deviceVersion'] ?? '',
      isOnLocalNetwork: map['isOnLocalNetwork'] as bool,
      category: map['category'] as String,
      uniqueID: map['uniqueID'] as String,
      index: map['index'],
    );
  }
}
