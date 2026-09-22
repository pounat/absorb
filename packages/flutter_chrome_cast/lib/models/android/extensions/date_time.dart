/// Extension for DateTime string parsing.
extension DateTimeString on DateTime {
  /// Tries to parse a date string in YYYYMMDD format.
  static DateTime? tryParse(String value) {
    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(4, 6));
    final day = int.tryParse(value.substring(6, 8));
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
    return null;
  }
}
