import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:rxdart/subjects.dart';

/// iOS-specific implementation of Google Cast session manager functionality.
class GoogleCastSessionManagerIOSMethodChannel
    implements GoogleCastSessionManagerPlatformInterface {
  /// Creates a new iOS session manager method channel.
  GoogleCastSessionManagerIOSMethodChannel() {
    _channel.setMethodCallHandler(
      (call) => _methodCallHandler(call),
    );
  }

  final _channel = const MethodChannel('google_cast.session_manager');

  @override
  Stream<GoogleCastSession?> get currentSessionStream =>
      _currentSessionStreamController.stream;

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    device as GoogleCastIosDevice;
    return await _channel.invokeMethod(
      'startSessionWithDevice',
      device.index,
    );
  }

  @override
  GoogleCastConnectState get connectionState =>
      currentSession?.connectionState ?? GoogleCastConnectState.disconnected;

  /// Returns the current cast session if available.
  ///
  /// This method is not implemented for iOS and will throw an [UnimplementedError].
  /// Use [currentSession] instead which is properly implemented for iOS.
  GoogleCastSession? get currentCastSession => throw UnimplementedError();

  @override
  GoogleCastSession? get currentSession =>
      _currentSessionStreamController.value;

  @override
  Future<bool> endSession() async {
    return await _channel.invokeMethod('endSession');
  }

  @override
  Future<bool> endSessionAndStopCasting() async {
    return await _channel.invokeMethod('endSessionAndStopCasting');
  }

  @override
  bool get hasConnectedSession =>
      connectionState == GoogleCastConnectState.connected;

  @override
  Future<void> setDefaultSessionOptions() {
    // TODO: implement setDefaultSessionOptions
    throw UnimplementedError();
  }

  @override
  Future<bool> startSessionWithOpenURLOptions() {
    // TODO: implement startSessionWithOpenURLOptions
    throw UnimplementedError();
  }

  @override
  Future<bool> suspendSessionWithReason() {
    // TODO: implement suspendSessionWithReason
    throw UnimplementedError();
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onCurrentSessionChanged':
        return _onCurrentSessionChanged(call.arguments);
    }
  }

  void _onCurrentSessionChanged(dynamic arguments) async {
    try {
      final session = IOSGoogleCastSessions.fromMap(
          arguments == null ? null : Map<String, dynamic>.from(arguments));
      _currentSessionStreamController.add(session);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void setDeviceVolume(double value) {
    _channel.invokeMethod('setDeviceVolume', value);
  }
}
