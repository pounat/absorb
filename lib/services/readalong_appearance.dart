import 'dart:convert';

/// Device-local presentation only. Stored JSON is never trusted as CSS.
class ReadAlongAppearance {
  static const storageKey = 'readalong_appearance_v1';
  final double size, spacing;
  final String family, theme;
  const ReadAlongAppearance({this.size=20, this.spacing=1.75, this.family='serif', this.theme='dark'});
  factory ReadAlongAppearance.fromMap(Map value) {
    double number(Object? v, double fallback, double min, double max) =>
      v is num && v.isFinite ? v.toDouble().clamp(min,max) : fallback;
    return ReadAlongAppearance(
      size: number(value['size'],20,14,36), spacing: number(value['spacing'],1.75,1.2,2.2),
      family: const ['serif','sans','system'].contains(value['family']) ? value['family'] as String : 'serif',
      theme: const ['dark','sepia','light'].contains(value['theme']) ? value['theme'] as String : 'dark');
  }
  factory ReadAlongAppearance.decode(String? raw) {
    try {final value=jsonDecode(raw ?? 'null'); if(value is Map) return ReadAlongAppearance.fromMap(value);} catch (_) { /* discard malformed local settings */ }
    return const ReadAlongAppearance();
  }
  Map<String,dynamic> toMap() => {'size':size,'spacing':spacing,'family':family,'theme':theme};
  String encode() => jsonEncode(toMap());
}
