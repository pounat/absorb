import 'dart:convert';
import 'dart:ui';

class Utils {
  static String encodeMap(Map<String, dynamic> data) {
    return jsonEncode(data);
  }
}

extension ColorToHex on Color {
  /// Converts the [Color] to a hex string in the format #RRGGBB.
  /// If [includeAlpha] is true, the format will be #AARRGGBB.
  String toHex({bool includeAlpha = false}) {
    final argb = toARGB32();
    String part(int shift) => ((argb >> shift) & 0xFF).toRadixString(16).padLeft(2, '0');
    return '#${includeAlpha ? part(24) : ''}${part(16)}${part(8)}${part(0)}';
  }
}
