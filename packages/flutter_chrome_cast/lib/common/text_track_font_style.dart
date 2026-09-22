///Possible text track font style.
enum TextTrackFontStyle {
  /// Normal font style.
  normal,

  /// Bold font style.
  bold,

  /// Bold italic font style.
  boldItalic,

  /// Italic font style.
  italic;

  factory TextTrackFontStyle.fromMap(String value) {
    // Try matching by name (lowerCamelCase)
    for (final v in values) {
      if (v.name == value) return v;
    }
    // Fallback: match legacy UPPER_SNAKE_CASE
    switch (value) {
      case 'NORMAL':
        return TextTrackFontStyle.normal;
      case 'BOLD':
        return TextTrackFontStyle.bold;
      case 'BOLD_ITALIC':
        return TextTrackFontStyle.boldItalic;
      case 'ITALIC':
        return TextTrackFontStyle.italic;
      default:
        return TextTrackFontStyle.normal;
    }
  }
}
