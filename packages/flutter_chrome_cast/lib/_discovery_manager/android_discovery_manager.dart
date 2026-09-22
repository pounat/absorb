import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/models/android/cast_device.dart';
import 'package:rxdart/subjects.dart';

/// Android-specific implementation of the Google Cast discovery manager.
///
/// This class handles the discovery of Google Cast devices on Android platform
/// using method channels to communicate with the native Android implementation.
class GoogleCastDiscoveryManagerMethodChannelAndroid
    implements GoogleCastDiscoveryManagerPlatformInterface {
  /// Creates a new instance of the Android discovery manager.
  ///
  /// Sets up the method call handler to receive updates from the native side.
  GoogleCastDiscoveryManagerMethodChannelAndroid() {
    _channel.setMethodCallHandler(_onMethodCallHandler);
  }

  final _channel =
      const MethodChannel('com.felnanuke.google_cast.discovery_manager');

  final _devicesStreamController = BehaviorSubject<List<GoogleCastDevice>>()
    ..add([]);

  @override
  List<GoogleCastDevice> get devices => _devicesStreamController.value;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream =>
      _devicesStreamController.stream;

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) {
    throw UnimplementedError('IOS Only');
  }

  @override
  Future<void> startDiscovery() async {
    _channel.invokeMethod('startDiscovery');
    return;
  }

  @override
  Future<void> stopDiscovery() async {
    _channel.invokeMethod('stopDiscovery');
    return;
  }

  Future _onMethodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onDevicesChanged':
        return _onDevicesChanged(call.arguments);

      default:
    }
  }

  void _onDevicesChanged(dynamic arguments) {
    try {
      arguments as String;
      final list = jsonDecode(arguments);
      final listMap = List.from(list);
      final devices = GoogleCastAndroidDevices.fromMap(listMap);

      if (kDebugMode) {
        print('Received ${devices.length} devices from native');
        for (final device in devices) {
          print(
              'Device: ${device.deviceID} - ${device.friendlyName} (${device.modelName})');
        }
      }

      // Enhanced deduplication: remove devices with same name and model
      final Map<String, GoogleCastDevice> uniqueDevices = {};
      for (final device in devices) {
        final key = '${device.friendlyName}_${device.modelName}';
        if (!uniqueDevices.containsKey(key)) {
          uniqueDevices[key] = device;
          if (kDebugMode) {
            print('Added unique device with key: $key');
          }
        } else {
          if (kDebugMode) {
            print('Skipped duplicate device with key: $key');
          }
        }
      }

      if (kDebugMode) {
        print(
            'Final device count after deduplication: ${uniqueDevices.length}');
      }
      _devicesStreamController.add(uniqueDevices.values.toList());
    } catch (e) {
      rethrow;
    }
  }
}
