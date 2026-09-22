/// Format of an HLS audio segment.
///
/// Represents the different audio codec formats that can be used
/// in HLS (HTTP Live Streaming) segments for Google Cast media.
enum CastHlsSegmentFormat {
  /// Advanced Audio Coding format.
  aac,

  /// Dolby Digital (AC-3) format.
  ac3,

  /// MPEG-1 Audio Layer III format.
  mp3,

  /// MPEG Transport Stream format.
  ts,

  /// Transport Stream with AAC audio.
  tsAac,

  /// Enhanced AC-3 (Dolby Digital Plus) format.
  eAc3,

  /// Fragmented MP4 format.
  fmp4,

  /// No specific format or unknown format.
  none;

  factory CastHlsSegmentFormat.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'AAC':
        return CastHlsSegmentFormat.aac;
      case 'AC3':
        return CastHlsSegmentFormat.ac3;
      case 'MP3':
        return CastHlsSegmentFormat.mp3;
      case 'TS':
        return CastHlsSegmentFormat.ts;
      case 'TS_AAC':
        return CastHlsSegmentFormat.tsAac;
      case 'E_AC3':
        return CastHlsSegmentFormat.eAc3;
      default:
        return CastHlsSegmentFormat.none;
    }
  }
}
