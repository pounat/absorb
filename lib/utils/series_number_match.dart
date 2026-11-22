final _parenthetical = RegExp(r'\s*\([^)]*\)\s*');
final _nonAlphaNum = RegExp(r'[^a-z0-9 ]');
final _multiSpace = RegExp(r'\s+');

/// Lowercase, no parentheticals or punctuation - how library and Audible
/// titles are compared when checking which series books are owned.
String normalizeSeriesTitle(String title) {
  return title
      .toLowerCase()
      .replaceAll(_parenthetical, ' ')
      .replaceAll(_nonAlphaNum, ' ')
      .replaceAll(_multiSpace, ' ')
      .trim();
}

/// A series number in one comparable form ("2.0" and "2" agree), or '' when
/// there is none.
String normalizeSeriesNumber(Object? raw) {
  final s = raw?.toString().trim() ?? '';
  if (s.isEmpty) return '';
  final n = double.tryParse(s);
  if (n == null) return s.toLowerCase();
  return n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
}

/// A library book's number in [seriesId]: series listings name it in a
/// single map, full items list every series the book is in.
String? librarySeriesNumber(Map<String, dynamic> metadata, String seriesId) {
  final raw = metadata['series'];
  if (raw is Map) return raw['sequence']?.toString();
  if (raw is List) {
    for (final s in raw) {
      if (s is Map && s['id'] == seriesId) return s['sequence']?.toString();
    }
  }
  return null;
}

/// The library side of matching an Audible series listing by number, for
/// books whose title and ASIN don't match: another region's or language's
/// edition, a reworded title, or a server whose listings carry no ASINs.
class SeriesNumberOwnership {
  final _byNumber = <String, List<({List<String> titles, String asin})>>{};

  void add(Object? number, String title, String asin) {
    final n = normalizeSeriesNumber(number);
    if (n.isEmpty) return;
    final titles = <String>[normalizeSeriesTitle(title)];
    final colon = title.indexOf(':');
    if (colon > 0) titles.add(normalizeSeriesTitle(title.substring(0, colon)));
    _byNumber.putIfAbsent(n, () => []).add((titles: titles, asin: asin));
  }

  /// Whether the library has a book numbered like [book], an entry of the
  /// Audible [listing], that no listing entry already matches by ASIN or
  /// title. That last part keeps one library book from owning two entries
  /// when the library and Audible number the series differently.
  bool owns(Map<String, dynamic> book, List<Map<String, dynamic>> listing) {
    final n = normalizeSeriesNumber(book['sequence']);
    if (n.isEmpty) return false;
    final owned = _byNumber[n];
    if (owned == null) return false;
    return owned.any((o) => !listing.any((entry) => _matches(entry, o.titles, o.asin)));
  }

  static bool _matches(Map<String, dynamic> entry, List<String> titles, String asin) {
    if (asin.isNotEmpty) {
      if (entry['asin'] == asin) return true;
      final all = entry['allAsins'] as List<dynamic>? ?? const [];
      if (all.contains(asin)) return true;
    }
    final title = normalizeSeriesTitle(entry['title'] as String? ?? '');
    if (title.isEmpty) return false;
    if (titles.contains(title)) return true;
    final subtitle = entry['subtitle'] as String? ?? '';
    return subtitle.isNotEmpty &&
        titles.contains(normalizeSeriesTitle('${entry['title']} $subtitle'));
  }
}
