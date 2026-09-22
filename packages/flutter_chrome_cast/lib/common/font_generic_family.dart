/// Represents generic font families for text tracks in Google Cast.
///
/// These values correspond to the CSS generic font families that can be
/// used for styling text tracks (captions/subtitles) in Cast media.
enum TextTrackFontGenericFamily {
  /// Sans-serif fonts (e.g., Arial, Helvetica).
  sansSerif,

  /// Monospaced sans-serif fonts (e.g., Courier New).
  monospacedSansSerif,

  /// Serif fonts (e.g., Times New Roman, Georgia).
  serif,

  /// Monospaced serif fonts.
  monospacedSerif,

  /// Casual or informal fonts.
  casual,

  /// Cursive or script fonts.
  cursive,

  /// Small capitals variant fonts.
  smallCapitals;

  factory TextTrackFontGenericFamily.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'SANS_SERIF':
        return TextTrackFontGenericFamily.sansSerif;
      case 'MONOSPACED_SANS_SERIF':
        return TextTrackFontGenericFamily.monospacedSansSerif;
      case 'SERIF':
        return TextTrackFontGenericFamily.serif;
      case 'MONOSPACED_SERIF':
        return TextTrackFontGenericFamily.monospacedSerif;
      case 'CASUAL':
        return TextTrackFontGenericFamily.casual;
      case 'CURSIVE':
        return TextTrackFontGenericFamily.cursive;
      case 'SMALL_CAPITALS':
        return TextTrackFontGenericFamily.smallCapitals;
      default:
        return TextTrackFontGenericFamily.sansSerif;
    }
  }
}
