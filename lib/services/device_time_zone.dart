import 'package:flutter/services.dart';

/// The phone's time zone as the platform names it (America/Chicago).
class DeviceTimeZone {
  DeviceTimeZone._();

  static const _channel = MethodChannel('com.absorb.time_zone');

  /// The phone's zone, and whether [other] is a different distance from UTC
  /// right now: two names for the same zone, or two zones that agree today,
  /// split days the same way. A name the phone doesn't know counts as
  /// different. Null where the platform can't say.
  static Future<({String id, bool differs})?> compare(String other) async {
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>('compare', {'other': other});
      final id = r?['id'] as String?;
      final here = r?['offsetSeconds'] as int?;
      if (id == null || id.isEmpty || here == null) return null;
      final there = r?['otherOffsetSeconds'] as int?;
      return (id: id, differs: there != here);
    } catch (_) {
      return null;
    }
  }
}
