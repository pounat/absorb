import 'dart:math';

/// One thing Siri can be asked to play: a book, a podcast show, an episode or
/// a series (which plays its next unfinished book).
class SiriEntry {
  final String kind;
  final String itemId;
  final String? episodeId;
  final String? libraryId;
  final String title;
  final String author;
  final List<String> series;
  final double progress;
  final bool finished;
  final int lastPlayed;
  final bool downloaded;
  final String? coverPath;

  const SiriEntry({
    required this.kind,
    required this.itemId,
    required this.title,
    this.episodeId,
    this.libraryId,
    this.author = '',
    this.series = const [],
    this.progress = 0,
    this.finished = false,
    this.lastPlayed = 0,
    this.downloaded = false,
    this.coverPath,
  });

  /// The identifier Siri hands back when it asks the app to play this.
  String get id => switch (kind) {
        'episode' => 'episode|$itemId|${episodeId ?? ''}',
        'series' => 'series|$itemId|${libraryId ?? ''}',
        _ => '$kind|$itemId',
      };

  bool get inProgress => progress > 0 && !finished;

  SiriEntry copyWith({
    double? progress,
    bool? finished,
    int? lastPlayed,
    bool? downloaded,
    String? coverPath,
    List<String>? series,
  }) =>
      SiriEntry(
        kind: kind,
        itemId: itemId,
        episodeId: episodeId,
        libraryId: libraryId,
        title: title,
        author: author,
        series: series ?? this.series,
        progress: progress ?? this.progress,
        finished: finished ?? this.finished,
        lastPlayed: lastPlayed ?? this.lastPlayed,
        downloaded: downloaded ?? this.downloaded,
        coverPath: coverPath ?? this.coverPath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'itemId': itemId,
        if (episodeId != null) 'episodeId': episodeId,
        if (libraryId != null) 'libraryId': libraryId,
        'title': title,
        'author': author,
        if (series.isNotEmpty) 'series': series,
        'progress': progress,
        'finished': finished,
        'lastPlayed': lastPlayed,
        'downloaded': downloaded,
        if (coverPath != null) 'coverPath': coverPath,
      };

  factory SiriEntry.fromJson(Map<String, dynamic> j) => SiriEntry(
        kind: j['kind'] as String? ?? 'book',
        itemId: j['itemId'] as String? ?? '',
        episodeId: j['episodeId'] as String?,
        libraryId: j['libraryId'] as String?,
        title: j['title'] as String? ?? '',
        author: j['author'] as String? ?? '',
        series: (j['series'] as List<dynamic>? ?? const []).whereType<String>().toList(),
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
        finished: j['finished'] == true,
        lastPlayed: (j['lastPlayed'] as num?)?.toInt() ?? 0,
        downloaded: j['downloaded'] == true,
        coverPath: j['coverPath'] as String?,
      );
}

/// What Siri asked for. [type] is 'book', 'podcast', 'episode' or 'any';
/// [latest] is set when the request asked for the newest episode.
class SiriQuery {
  final String? name;
  final String? artist;
  final String type;
  final bool latest;

  const SiriQuery({this.name, this.artist, this.type = 'any', this.latest = false});

  factory SiriQuery.fromArgs(Map<dynamic, dynamic> args) {
    String? clean(Object? v) {
      final s = (v as String?)?.trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return SiriQuery(
      name: clean(args['name']),
      artist: clean(args['artist']),
      type: clean(args['type']) ?? 'any',
      latest: args['latest'] == true,
    );
  }

  /// "Resume Absorb", "Play my audiobook in Absorb": nothing to search for.
  bool get isResume => _nameKey.isEmpty && (artist == null || siriNormalize(artist!).isEmpty);

  String get _nameKey {
    final key = siriNormalize(_stripNoise(name ?? ''));
    return _fillerNames.contains(key) ? '' : key;
  }

  /// "Podcast" or "episode" said out loud, rather than Siri's own guess.
  bool get _saysPodcast => RegExp(r'\b(podcast|episode)s?\b', caseSensitive: false).hasMatch(name ?? '');
}

const _fillerNames = {
  'my', 'my book', 'book', 'books', 'my books', 'my audiobooks', 'my show',
  'my podcasts', 'something', 'anything', 'last', 'my last book', 'latest',
  'where i left off', 'what i was listening to', 'my current book',
  'current book', 'my story', 'music',
};

class SiriMatch {
  /// 'ok', 'ambiguous' or 'none'.
  final String status;
  final List<SiriEntry> items;
  final double score;

  /// The pick came from a series name rather than a title, so the series'
  /// own next book may be a better answer than the books on hand.
  final bool viaSeries;

  const SiriMatch(this.status, this.items, this.score, {this.viaSeries = false});

  static const none = SiriMatch('none', [], 0);
}

const _numberWords = {
  'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
  'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'ten': '10',
  'eleven': '11', 'twelve': '12', 'thirteen': '13', 'fourteen': '14',
  'fifteen': '15', 'sixteen': '16', 'seventeen': '17', 'eighteen': '18',
  'nineteen': '19', 'twenty': '20',
};

const _foldFrom = 'àáâãäåāăąçćčďèéêëēėęěìíîïīįłñńňòóôõöøōőřśšşťùúûüūůűųýÿžźżß';
const _foldTo = 'aaaaaaaaaccc' 'deeeeeeee' 'iiiiiilnnn' 'oooooooo' 'rsss' 't' 'uuuuuuuu' 'yy' 'zzz' 's';

String _fold(String s) {
  final out = StringBuffer();
  for (final ch in s.split('')) {
    final i = _foldFrom.indexOf(ch);
    out.write(i >= 0 && i < _foldTo.length ? _foldTo[i] : ch);
  }
  return out.toString();
}

final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final _leadingArticle = RegExp(r'^(the|a|an) ');
final _noise = RegExp(
    r'\b(the )?(audio ?book|podcast|latest episode of|newest episode of|new episode of|episode of)\b',
    caseSensitive: false);

String _stripNoise(String s) => s.replaceAll(_noise, ' ');

/// Lowercase, accents folded, punctuation dropped, number words as digits and
/// a leading article removed, so "The Wheel of Time: Book One" and "wheel of
/// time book 1" compare equal.
String siriNormalize(String s) {
  var t = _fold(s.toLowerCase()).replaceAll('&', ' and ').replaceAll(RegExp(r"['’]"), '');
  t = t.replaceAll(_nonWord, ' ').trim();
  if (t.isEmpty) return t;
  t = t.split(RegExp(r'\s+')).map((w) => _numberWords[w] ?? w).join(' ');
  return t.replaceFirst(_leadingArticle, '');
}

double _similarity(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  final m = a.length, n = b.length;
  var prev = List<int>.generate(n + 1, (j) => j);
  for (var i = 1; i <= m; i++) {
    final cur = List<int>.filled(n + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = min(min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
    }
    prev = cur;
  }
  return 1 - prev[n] / max(m, n);
}

bool _hasPhrase(String hay, String needle) => ' $hay '.contains(' $needle ');

/// How well a spoken [query] names [target], 0 to 100. Both normalized.
double siriTextScore(String query, String target) {
  if (query.isEmpty || target.isEmpty) return 0;
  if (query == target) return 100;
  var best = 0.0;
  if (_hasPhrase(target, query)) {
    best = max(best, 78 + 17 * query.length / target.length);
  }
  if (_hasPhrase(query, target)) {
    best = max(best, 74 + 16 * target.length / query.length);
  }
  final qt = query.split(' ').toSet();
  final tt = target.split(' ').toSet();
  final shared = qt.intersection(tt).length;
  if (shared > 0) {
    final overlap = shared / max(qt.length, tt.length);
    final allQuery = shared == qt.length;
    best = max(best, (allQuery ? 72 : 60) * overlap);
  }
  final sim = _similarity(query, target);
  if (sim >= 0.75) best = max(best, 92 * sim);
  return best;
}

class _Scored {
  final SiriEntry entry;
  final double score;
  final bool bySeries;
  const _Scored(this.entry, this.score, this.bySeries);
}

bool _kindFits(String kind, String type) => switch (type) {
      'book' => kind == 'book' || kind == 'series',
      'podcast' => kind == 'podcast' || kind == 'episode',
      'episode' => kind == 'episode' || kind == 'podcast',
      _ => true,
    };

int _rank(SiriEntry e) => e.inProgress ? 2 : (e.finished ? 0 : 1);

/// Picks what a Siri request means from [entries]. A clear winner is 'ok';
/// close calls come back 'ambiguous' for Siri to ask which one.
SiriMatch siriMatch(SiriQuery query, List<SiriEntry> entries) {
  final name = query._nameKey;
  final artist = query.artist == null ? '' : siriNormalize(query.artist!);
  // The kind is Siri's own guess as often as the listener's word (a book
  // title it also knows as a podcast show gets called a podcast), so it only
  // settles ties and never hides a better match. Saying "podcast" counts.
  final saysPodcast = query._saysPodcast;
  final pool = saysPodcast ? entries.where((e) => _kindFits(e.kind, 'podcast')).toList() : entries;
  if (pool.isEmpty) return SiriMatch.none;

  if (name.isEmpty) {
    if (artist.isEmpty) return SiriMatch.none;
    return _byAuthor(artist, pool);
  }

  final scored = <_Scored>[];
  for (final e in pool) {
    // "The Dungeon Crawler Carl Podcast" is asked for the way the query is
    // read, with "podcast" dropped. Unless "podcast" was said, a title that
    // is the name outright beats one that only is without that word.
    final bare = siriNormalize(_stripNoise(e.title));
    final bareScore = bare.isEmpty ? 0.0 : siriTextScore(name, bare) * (saysPodcast ? 1.0 : 0.95);
    final titleScore = max(siriTextScore(name, siriNormalize(e.title)), bareScore);
    var seriesScore = 0.0;
    for (final s in e.series) {
      seriesScore = max(seriesScore, siriTextScore(name, siriNormalize(s)) * 0.96);
    }
    final bySeries = seriesScore > titleScore;
    var score = max(titleScore, seriesScore);
    if (artist.isNotEmpty && score > 0) {
      final a = siriTextScore(artist, siriNormalize(e.author));
      score = a >= 70 ? min(100.0, score + 4) : score * 0.85;
    }
    if (score > 0) scored.add(_Scored(e, score, bySeries));
  }

  // "Play Brandon Sanderson": the name is an author, not a title.
  final bestTitle = scored.fold<double>(0, (m, s) => max(m, s.score));
  if (bestTitle < 80) {
    final asAuthor = _byAuthor(name, pool);
    if (asAuthor.status != 'none' && asAuthor.score > bestTitle) return asAuthor;
  }
  if (scored.isEmpty) return SiriMatch.none;

  int fits(_Scored s) => _kindFits(s.entry.kind, query.type) ? 1 : 0;
  scored.sort((a, b) {
    final c = b.score.compareTo(a.score);
    if (c != 0) return c;
    final f = fits(b).compareTo(fits(a));
    if (f != 0) return f;
    final r = _rank(b.entry).compareTo(_rank(a.entry));
    if (r != 0) return r;
    return b.entry.lastPlayed.compareTo(a.entry.lastPlayed);
  });

  var top = scored.first;
  if (top.score < 60) return SiriMatch.none;
  // A series named for its first book, which is finished while a later one
  // is under way: the listener means the series.
  if (top.entry.kind == 'book' && !top.bySeries && top.entry.finished) {
    final onNow = scored
        .map((s) => s.entry)
        .where((e) =>
            e.kind == 'book' &&
            e.inProgress &&
            e.series.any((x) => siriTextScore(name, siriNormalize(x)) >= 90))
        .toList()
      ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    if (onNow.isNotEmpty) return SiriMatch('ok', [onNow.first], top.score, viaSeries: true);
  }
  // A book and its series named the same: the book is the likelier ask.
  if (top.entry.kind == 'series') {
    final book = scored.firstWhere(
        (s) => s.entry.kind == 'book' && !s.bySeries && top.score - s.score < 1,
        orElse: () => top);
    if (book != top) {
      scored.remove(book);
      scored.insert(0, book);
      top = book;
    }
  }

  // A series name: its books tie, so play the one the listener is on, or the
  // first not finished.
  if (top.bySeries) {
    final inSeries = scored.where((s) => s.bySeries && top.score - s.score < 3).map((s) => s.entry).toList();
    return SiriMatch('ok', [_nextInSeries(inSeries)], top.score, viaSeries: true);
  }

  // When the pick is the kind asked for, the other kinds don't make it a
  // close call.
  final topFits = fits(top) == 1;
  final rivals = scored
      .skip(1)
      .where((s) =>
          s.entry.id != top.entry.id &&
          (!topFits || fits(s) == 1) &&
          !(s.entry.kind == 'series' && top.entry.kind == 'book' && top.score - s.score < 1))
      .toList();
  if (rivals.isEmpty ||
      top.score - rivals.first.score > 10 ||
      (top.score >= 97 && rivals.first.score < 97)) {
    return SiriMatch('ok', [top.entry], top.score);
  }
  final close = [top.entry];
  for (final s in rivals) {
    if (top.score - s.score > 10 || close.length == 4) break;
    if (!close.any((e) => e.id == s.entry.id)) close.add(s.entry);
  }
  return SiriMatch('ambiguous', close, top.score);
}

SiriEntry _nextInSeries(List<SiriEntry> books) {
  final playing = books.where((e) => e.inProgress).toList()
    ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
  if (playing.isNotEmpty) return playing.first;
  return books.firstWhere((e) => !e.finished, orElse: () => books.first);
}

SiriMatch _byAuthor(String author, List<SiriEntry> pool) {
  final hits = <_Scored>[];
  for (final e in pool) {
    if (e.kind == 'series') continue;
    final names = e.author.split(RegExp(r',|&| and ')).map(siriNormalize).where((n) => n.isNotEmpty);
    var s = siriTextScore(author, siriNormalize(e.author));
    for (final n in names) {
      s = max(s, siriTextScore(author, n));
    }
    if (s >= 85) hits.add(_Scored(e, s, false));
  }
  if (hits.isEmpty) return SiriMatch.none;
  hits.sort((a, b) {
    final r = _rank(b.entry).compareTo(_rank(a.entry));
    if (r != 0) return r;
    return b.entry.lastPlayed.compareTo(a.entry.lastPlayed);
  });
  final best = hits.first;
  if (best.entry.inProgress || hits.length == 1) {
    return SiriMatch('ok', [best.entry], best.score);
  }
  return SiriMatch('ambiguous', hits.take(4).map((s) => s.entry).toList(), best.score);
}
