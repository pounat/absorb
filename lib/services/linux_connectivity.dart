import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart'
    show ConnectivityPlatform;
import 'package:flutter/foundation.dart';

Future<void> initializeLinuxConnectivity() async {
  // The Linux plugin can report a failed D-Bus subscription as an uncaught
  // asynchronous error alongside the connectivity request.
  final probe = Completer<void>();
  runZonedGuarded(
    () async {
      await Connectivity().checkConnectivity();
      if (!probe.isCompleted) probe.complete();
    },
    (error, stack) {
      if (!probe.isCompleted) probe.completeError(error, stack);
    },
  );
  try {
    await probe.future.timeout(const Duration(seconds: 1));
  } catch (error) {
    debugPrint('[Connectivity] NetworkManager unavailable: $error');
    ConnectivityPlatform.instance = _LinuxInterfaceConnectivity();
  }
}

// Linux can use another network manager or run without a system D-Bus.
// Server reachability is checked separately by the app's normal probes.
class _LinuxInterfaceConnectivity extends ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    final interfaces = await NetworkInterface.list(includeLinkLocal: true);
    return [
      interfaces.isEmpty ? ConnectivityResult.none : ConnectivityResult.other,
    ];
  }

  @override
  late final Stream<List<ConnectivityResult>> onConnectivityChanged =
      Stream.periodic(const Duration(seconds: 5))
          .asyncMap((_) => checkConnectivity())
          .asBroadcastStream(
            onListen: (subscription) => subscription.resume(),
            onCancel: (subscription) => subscription.pause(),
          );
}
