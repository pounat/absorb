/// Enum representing the HLS video segment format types.
enum HlsVideoSegmentFormat {
  /// MPEG-2 Transport Stream format.
  mpeg2Ts,

  /// Fragmented MP4 format.
  fmp4,

  /// No specific format.
  none;

  factory HlsVideoSegmentFormat.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'MPEG2_TS':
        return HlsVideoSegmentFormat.mpeg2Ts;
      case 'FMP4':
        return HlsVideoSegmentFormat.fmp4;
      default:
        return HlsVideoSegmentFormat.none;
    }
  }
}
