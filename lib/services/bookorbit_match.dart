/// BookOrbit's match flow, ported from its web editor (client/src/features/
/// book/lib/metadata-match.ts and metadata-diff-fields.ts): every source is
/// searched at once, results are ranked against the book, and each field can
/// be kept or taken from any result.
library;

/// One search result from one source.
class MatchCandidate {
  final Map<String, dynamic> raw;
  const MatchCandidate(this.raw);

  String get provider => '${raw['provider'] ?? ''}';
  String get providerId => '${raw['providerId'] ?? ''}';

  /// Names the result a pick came from.
  String get key => '$provider:$providerId';

  String get title => _s(raw['displayTitle']) ?? _s(raw['title']) ?? '';
  String get subtitle => _s(raw['subtitle']) ?? '';
  List<String> get authors => _list(raw['authors']);
  List<String> get narrators => _list(raw['narrators']);
  List<String> get genres => _list(raw['genres']);
  String get description => _s(raw['description']) ?? '';
  String get publisher => _s(raw['publisher']) ?? '';
  String get language => _s(raw['language']) ?? '';
  String get isbn13 => _s(raw['isbn13']) ?? '';
  String get isbn10 => _s(raw['isbn10']) ?? '';
  String get isbn => isbn13.isNotEmpty ? isbn13 : isbn10;
  String get coverUrl => _s(raw['coverUrl']) ?? '';

  /// The date when the source has one, else the year.
  String get published =>
      _s(raw['publishedDate']) ?? (raw['publishedYear'] == null ? '' : '${raw['publishedYear']}');
  String get year => published.length >= 4 ? published.substring(0, 4) : published;

  /// Every series the source lists, first one first.
  List<({String name, String? index})> get series {
    final out = <({String name, String? index})>[];
    for (final m in (raw['seriesMemberships'] as List? ?? const []).whereType<Map>()) {
      final name = _s(m['seriesName']);
      if (name != null) out.add((name: name, index: _s(m['seriesIndex'])));
    }
    if (out.isEmpty) {
      final name = _s(raw['seriesName']);
      if (name != null) out.add((name: name, index: _s(raw['seriesIndex'])));
    }
    return out;
  }

  /// Fields that matter which the result fills; few means a thin record.
  int get filledFields => [
        title,
        subtitle,
        authors.isEmpty ? '' : 'x',
        description,
        publisher,
        published,
        language,
        raw['pageCount'] == null || raw['pageCount'] == 0 ? '' : 'x',
        series.isEmpty ? '' : 'x',
        isbn,
        genres.isEmpty ? '' : 'x',
        raw['communityRating'] == null || raw['communityRating'] == 0 ? '' : 'x',
        coverUrl,
      ].where((v) => v.isNotEmpty).length;

  static String? _s(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static List<String> _list(Object? v) => [
        for (final e in (v as List? ?? const []))
          if ('$e'.trim().isNotEmpty) '$e'.trim(),
      ];
}

/// What the book has now, as the editor shows it.
class MatchCurrent {
  final String title;
  final String subtitle;
  final List<String> authors;
  final List<String> narrators;
  final List<String> genres;
  final String description;
  final String publisher;
  final String published;
  final String language;
  final String isbn;
  final List<({String name, String? index})> series;

  /// Provider key (goodreads, audible, ...) to the id the book holds.
  final Map<String, String> providerIds;

  const MatchCurrent({
    this.title = '',
    this.subtitle = '',
    this.authors = const [],
    this.narrators = const [],
    this.genres = const [],
    this.description = '',
    this.publisher = '',
    this.published = '',
    this.language = '',
    this.isbn = '',
    this.series = const [],
    this.providerIds = const {},
  });
}

enum MatchTier { strong, possible, weak }

class MatchAssessment {
  final MatchTier tier;
  final double score;
  final bool linked;
  final bool isbnMatch;
  final bool sparse;

  const MatchAssessment({
    required this.tier,
    required this.score,
    required this.linked,
    required this.isbnMatch,
    required this.sparse,
  });
}

/// Lowercase, accents folded where common, everything but letters and
/// digits as single spaces.
String normalizeForMatch(String value) {
  var s = value.toLowerCase();
  const folds = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i',
    'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ø': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y',
  };
  folds.forEach((from, to) => s = s.replaceAll(from, to));
  return s.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();
}

String _titleCore(String title) => normalizeForMatch(title
    .replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' ')
    .replaceAll(RegExp(r'\s+by\s+[^:]+$', caseSensitive: false), ''));

String _lastName(String name) {
  // "Sanderson, Brandon" puts the last name first.
  final comma = name.indexOf(',');
  if (comma > 0) return normalizeForMatch(name.substring(0, comma));
  final parts = normalizeForMatch(name).split(' ');
  return parts.isEmpty ? '' : parts.last;
}

String _bareIsbn(String v) => v.replaceAll(RegExp(r'[^0-9xX]'), '').toUpperCase();

/// How likely [c] is to be this book: a record the book is linked to or one
/// sharing its ISBN is strong, the same title and author is possible, the
/// rest are usually other books sharing words with the title.
MatchAssessment assessMatch(MatchCandidate c, MatchCurrent book) {
  final linkedId = book.providerIds[c.provider == 'audnexus' ? 'audible' : c.provider];
  final linked = linkedId != null && linkedId.isNotEmpty && linkedId == c.providerId;
  final bookIsbn = _bareIsbn(book.isbn);
  final isbnMatch = bookIsbn.isNotEmpty &&
      [_bareIsbn(c.isbn13), _bareIsbn(c.isbn10)].any((i) => i.isNotEmpty && i == bookIsbn);
  final bookTitle = _titleCore(book.title);
  final resultTitle = _titleCore(c.title);
  final sameTitle = bookTitle.isNotEmpty && resultTitle == bookTitle;
  final longerTitle = !sameTitle &&
      bookTitle.isNotEmpty &&
      resultTitle.isNotEmpty &&
      (resultTitle.startsWith(bookTitle) || bookTitle.startsWith(resultTitle));
  final bookAuthors = book.authors.map(normalizeForMatch).where((a) => a.isNotEmpty).toSet();
  final bookLastNames = book.authors.map(_lastName).where((a) => a.isNotEmpty).toSet();
  final authorMatch = c.authors
      .any((a) => bookAuthors.contains(normalizeForMatch(a)) || bookLastNames.contains(_lastName(a)));
  final bookSeries = book.series.isEmpty ? null : book.series.first;
  final resultSeries = c.series.isEmpty ? null : c.series.first;
  final seriesMatch = bookSeries != null &&
      resultSeries != null &&
      normalizeForMatch(bookSeries.name) == normalizeForMatch(resultSeries.name) &&
      (bookSeries.index ?? '') == (resultSeries.index ?? '');
  final filled = c.filledFields;
  final tier = linked || isbnMatch
      ? MatchTier.strong
      : sameTitle && authorMatch
          ? MatchTier.possible
          : MatchTier.weak;
  final score = (linked ? 60 : 0) +
      (isbnMatch ? 45 : 0) +
      (sameTitle ? 25 : longerTitle ? 6 : 0) +
      (authorMatch ? 20 : 0) +
      (seriesMatch ? 10 : 0) +
      filled * 0.6;
  return MatchAssessment(tier: tier, score: score, linked: linked, isbnMatch: isbnMatch, sparse: filled <= 4);
}

/// Best first: by tier, then score, then the server's source order, then
/// arrival.
List<({MatchCandidate candidate, MatchAssessment assessment})> rankMatches(
  List<MatchCandidate> candidates,
  MatchCurrent book, {
  List<String> providerOrder = const [],
}) {
  final order = {for (var i = 0; i < providerOrder.length; i++) providerOrder[i]: i};
  final ranked = [
    for (var i = 0; i < candidates.length; i++)
      (candidate: candidates[i], assessment: assessMatch(candidates[i], book), index: i),
  ];
  ranked.sort((a, b) {
    final tier = a.assessment.tier.index.compareTo(b.assessment.tier.index);
    if (tier != 0) return tier;
    final score = b.assessment.score.compareTo(a.assessment.score);
    if (score != 0) return score;
    final provider = (order[a.candidate.provider] ?? 1 << 30).compareTo(order[b.candidate.provider] ?? 1 << 30);
    if (provider != 0) return provider;
    return a.index.compareTo(b.index);
  });
  return [for (final r in ranked) (candidate: r.candidate, assessment: r.assessment)];
}

enum MatchField { title, subtitle, authors, narrators, series, description, publisher, published, language, isbn, genres }

/// fill: the book has nothing there; change: it differs; minor: only
/// capitalization, punctuation, order or the like; same; missing: the result
/// has nothing there.
enum DiffKind { fill, change, minor, same, missing }

bool isActionable(DiffKind kind) => kind == DiffKind.fill || kind == DiffKind.change || kind == DiffKind.minor;

/// HTML description as readable text.
String descriptionPlainText(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</(p|div|li|h\d|blockquote)>', caseSensitive: false), '\n\n')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .replaceAll(RegExp(r' *\n *'), '\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

String _seriesText(List<({String name, String? index})> series) => series
    .map((s) => s.index == null || s.index!.isEmpty ? s.name : '${s.name} #${s.index}')
    .join(', ');

/// What [field] shows for the book now.
String currentValue(MatchCurrent book, MatchField field) => switch (field) {
      MatchField.title => book.title,
      MatchField.subtitle => book.subtitle,
      MatchField.authors => book.authors.join(', '),
      MatchField.narrators => book.narrators.join(', '),
      MatchField.series => _seriesText(book.series),
      MatchField.description => descriptionPlainText(book.description),
      MatchField.publisher => book.publisher,
      MatchField.published => book.published,
      MatchField.language => book.language,
      MatchField.isbn => book.isbn,
      MatchField.genres => book.genres.join(', '),
    };

/// What [field] would become from [c].
String candidateValue(MatchCandidate c, MatchField field) => switch (field) {
      MatchField.title => c.title,
      MatchField.subtitle => c.subtitle,
      MatchField.authors => c.authors.join(', '),
      MatchField.narrators => c.narrators.join(', '),
      MatchField.series => _seriesText(c.series),
      MatchField.description => descriptionPlainText(c.description),
      MatchField.publisher => c.publisher,
      MatchField.published => c.published,
      MatchField.language => c.language,
      MatchField.isbn => c.isbn,
      MatchField.genres => c.genres.join(', '),
    };

List<String> _currentList(MatchCurrent book, MatchField field) => switch (field) {
      MatchField.authors => book.authors,
      MatchField.narrators => book.narrators,
      MatchField.genres => book.genres,
      _ => const [],
    };

List<String> _candidateList(MatchCandidate c, MatchField field) => switch (field) {
      MatchField.authors => c.authors,
      MatchField.narrators => c.narrators,
      MatchField.genres => c.genres,
      _ => const [],
    };

const _listFields = {MatchField.authors, MatchField.narrators, MatchField.genres};

const _languageNames = {
  'en': 'english', 'eng': 'english', 'de': 'german', 'ger': 'german', 'deu': 'german',
  'fr': 'french', 'fre': 'french', 'fra': 'french', 'es': 'spanish', 'spa': 'spanish',
  'it': 'italian', 'ita': 'italian', 'nl': 'dutch', 'dut': 'dutch', 'nld': 'dutch',
  'pt': 'portuguese', 'por': 'portuguese', 'ru': 'russian', 'rus': 'russian',
  'ja': 'japanese', 'jpn': 'japanese', 'zh': 'chinese', 'chi': 'chinese', 'zho': 'chinese',
  'pl': 'polish', 'pol': 'polish', 'sv': 'swedish', 'swe': 'swedish', 'da': 'danish',
  'dan': 'danish', 'no': 'norwegian', 'nor': 'norwegian', 'fi': 'finnish', 'fin': 'finnish',
  'cs': 'czech', 'cze': 'czech', 'ces': 'czech', 'el': 'greek', 'gre': 'greek', 'ell': 'greek',
  'ro': 'romanian', 'rum': 'romanian', 'ron': 'romanian', 'ko': 'korean', 'kor': 'korean',
};

String _languageToken(String v) {
  final t = v.trim().toLowerCase();
  return _languageNames[t.split(RegExp(r'[-_]')).first] ?? t;
}

DiffKind _classifyText(String a, String b) {
  a = a.trim();
  b = b.trim();
  if (b.isEmpty) return DiffKind.missing;
  if (a.isEmpty) return DiffKind.fill;
  if (a == b) return DiffKind.same;
  if (a.toLowerCase() == b.toLowerCase() || normalizeForMatch(a) == normalizeForMatch(b)) return DiffKind.minor;
  return DiffKind.change;
}

/// How the book's [field] compares with [c]'s.
DiffKind classifyField(MatchCurrent book, MatchCandidate c, MatchField field) {
  if (_listFields.contains(field)) {
    final a = _currentList(book, field);
    final b = _candidateList(c, field);
    if (b.isEmpty) return DiffKind.missing;
    if (a.isEmpty) return DiffKind.fill;
    final left = a.map(normalizeForMatch).toSet();
    final right = b.map(normalizeForMatch).toSet();
    if (left.length != right.length || !left.containsAll(right)) return DiffKind.change;
    return a.join('\u0000') == b.join('\u0000') ? DiffKind.same : DiffKind.minor;
  }
  final a = currentValue(book, field);
  final b = candidateValue(c, field);
  switch (field) {
    case MatchField.published:
      if (b.isEmpty) return DiffKind.missing;
      if (a.isEmpty) return DiffKind.fill;
      if (a == b) return DiffKind.same;
      return a.length >= 4 && b.length >= 4 && a.substring(0, 4) == b.substring(0, 4)
          ? DiffKind.minor
          : DiffKind.change;
    case MatchField.language:
      if (b.trim().isEmpty) return DiffKind.missing;
      if (a.trim().isEmpty) return DiffKind.fill;
      if (a.trim() == b.trim()) return DiffKind.same;
      return _languageToken(a) == _languageToken(b) ? DiffKind.minor : DiffKind.change;
    case MatchField.isbn:
      if (b.isEmpty) return DiffKind.missing;
      if (a.isEmpty) return DiffKind.fill;
      return _bareIsbn(a) == _bareIsbn(b) ? DiffKind.same : DiffKind.change;
    default:
      return _classifyText(a, b);
  }
}

/// How many fields [c] would fill and change against the book.
({int fills, int changes}) summarizeDifferences(MatchCurrent book, MatchCandidate c) {
  var fills = 0, changes = 0;
  for (final field in MatchField.values) {
    final kind = classifyField(book, c, field);
    if (kind == DiffKind.fill) fills++;
    if (kind == DiffKind.change) changes++;
  }
  return (fills: fills, changes: changes);
}

/// Values of [field] other results hold, grouped by value, leaving out
/// [active]'s own and values equal to it.
List<({String value, List<MatchCandidate> from})> otherValues(
  MatchField field,
  MatchCandidate active,
  List<MatchCandidate> alternatives,
) {
  String comparable(MatchCandidate c) => _listFields.contains(field)
      ? (_candidateList(c, field).map(normalizeForMatch).toList()..sort()).join('\u0000')
      : normalizeForMatch(candidateValue(c, field));
  final own = comparable(active);
  final groups = <String, ({String value, List<MatchCandidate> from})>{};
  for (final c in alternatives) {
    if (c.key == active.key) continue;
    final display = candidateValue(c, field);
    if (display.isEmpty) continue;
    final k = comparable(c);
    if (k.isEmpty || k == own) continue;
    groups.putIfAbsent(k, () => (value: display, from: <MatchCandidate>[])).from.add(c);
  }
  return groups.values.toList();
}

/// The provider ids BookOrbit stores per book, by search provider key.
const bookOrbitProviderIdFields = {
  'google': 'googleBooksId',
  'goodreads': 'goodreadsId',
  'amazon': 'amazonId',
  'hardcover': 'hardcoverId',
  'openLibrary': 'openLibraryId',
  'itunes': 'itunesId',
  'audible': 'audibleId',
  'audnexus': 'audibleId',
  'librofm': 'librofmId',
  'comicvine': 'comicvineId',
  'ranobedb': 'ranobedbId',
  'kobo': 'koboId',
  'lubimyczytac': 'lubimyczytacId',
  'aladin': 'aladinId',
};

/// The edit the picks make, in the Audiobookshelf media shape Absorb saves
/// with, plus the cover URL to set. Each field comes from the result it was
/// picked from. Results that gave something also link the book to their
/// source when it isn't linked there yet (`bookOrbitProviderIds`).
({Map<String, dynamic> metadata, String? coverUrl}) buildMatchUpdate(
  MatchCurrent book,
  Map<MatchField, MatchCandidate> picks, {
  MatchCandidate? cover,
  bool mergeGenres = true,
}) {
  final metadata = <String, dynamic>{};
  final used = <MatchCandidate>[];
  picks.forEach((field, c) {
    used.add(c);
    switch (field) {
      case MatchField.title:
        metadata['title'] = c.title;
      case MatchField.subtitle:
        metadata['subtitle'] = c.subtitle;
      case MatchField.authors:
        metadata['authors'] = [for (final a in c.authors) {'name': a}];
      case MatchField.narrators:
        metadata['narrators'] = c.narrators;
      case MatchField.series:
        metadata['series'] = [for (final s in c.series) {'name': s.name, 'sequence': s.index ?? ''}];
      case MatchField.description:
        metadata['description'] = c.description;
      case MatchField.publisher:
        metadata['publisher'] = c.publisher;
      case MatchField.published:
        metadata['publishedYear'] = c.published;
      case MatchField.language:
        metadata['language'] = c.language;
      case MatchField.isbn:
        metadata['isbn'] = c.isbn;
      case MatchField.genres:
        if (mergeGenres) {
          final seen = {for (final g in book.genres) normalizeForMatch(g)};
          metadata['genres'] = [
            ...book.genres,
            for (final g in c.genres)
              if (seen.add(normalizeForMatch(g))) g,
          ];
        } else {
          metadata['genres'] = c.genres;
        }
    }
  });
  if (cover != null) used.add(cover);
  final ids = <String, String>{};
  for (final c in used) {
    final provider = c.provider == 'audnexus' ? 'audible' : c.provider;
    if (c.providerId.isEmpty || !bookOrbitProviderIdFields.containsKey(provider)) continue;
    if ((book.providerIds[provider] ?? '').isNotEmpty) continue;
    ids[provider] = c.providerId;
  }
  if (ids.isNotEmpty) metadata['bookOrbitProviderIds'] = ids;
  return (metadata: metadata, coverUrl: cover?.coverUrl.isNotEmpty == true ? cover!.coverUrl : null);
}

/// A search event: a result, or a source saying how it stopped early.
class MatchSearchEvent {
  final MatchCandidate? candidate;
  final String? provider;
  final String? outcome;

  const MatchSearchEvent.result(MatchCandidate this.candidate)
      : provider = null,
        outcome = null;
  const MatchSearchEvent.status(String this.provider, String this.outcome) : candidate = null;
}
