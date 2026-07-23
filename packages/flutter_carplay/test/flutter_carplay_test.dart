import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('com.oguzhnatly.flutter_carplay');

  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reports the native CarPlay connection state', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      receivedCall = call;
      return true;
    });

    expect(await FlutterCarplay.isConnected, isTrue);
    expect(receivedCall?.method, 'isConnected');
  });

  test('treats a missing native connection result as disconnected', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);

    expect(await FlutterCarplay.isConnected, isFalse);
  });
}
