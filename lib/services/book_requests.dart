/// BookOrbit book requests: what a request looks like, and how search
/// results become one. Follows BookOrbit's web client
/// (client/src/features/book-requests) and its shared types
/// (packages/types/src/book-request.ts).
library;

import 'bookorbit_match.dart';

const bookRequestMediaKinds = ['audiobook', 'ebook', 'comic'];

/// What a server from BookOrbit 3.4 on offers instead: comics count as
/// e-books there, and 'both' asks for the e-book and the audiobook together.
const bookRequestPairMediaKinds = ['audiobook', 'ebook', 'both'];

// What BookOrbit counts as each format a request brings (packages/types/src/book.ts).
const _requestEbookFormats = {'epub', 'kepub', 'mobi', 'azw3', 'azw', 'fb2', 'pdf', 'djvu', 'cbz', 'cbr', 'cb7', 'cbx'};
const _requestAudioFormats = {'m4b', 'mp3', 'm4a', 'opus', 'ogg', 'flac'};

/// The format a BookOrbit book could be asked for from the book itself, from
/// its detail's files: 'audiobook' when it only has something to read,
/// 'ebook' when it only has audio. Null when it has both, or when its EPUB
/// reads itself aloud, which is both already.
String? missingRequestFormat(List<Map<String, dynamic>> files) {
  var readable = false;
  var audio = false;
  for (final f in files) {
    final role = f['role'];
    if (role != 'primary' && role != 'content') continue;
    final format = '${f['format'] ?? ''}'.toLowerCase();
    if (format == 'epub' && (f['mediaOverlay'] as Map?)?['available'] == true) return null;
    if (_requestEbookFormats.contains(format)) readable = true;
    if (_requestAudioFormats.contains(format)) audio = true;
  }
  if (readable && !audio) return 'audiobook';
  if (audio && !readable) return 'ebook';
  return null;
}

/// A book's missing format and where asking for it stands.
class MissingFormatRequest {
  /// 'audiobook' or 'ebook'.
  final String mediaKind;
  final BookRequestAvailability? availability;

  const MissingFormatRequest(this.mediaKind, [this.availability]);

  /// The other format is in the library already, as a book of its own.
  int? get ownedBookId => availability?.ownedBookId;

  /// This account asked for it already.
  bool get following => ownedBookId == null && availability?.existingRequestId != null && availability!.alreadySubscribed;

  /// Someone else asked for it; this account can join.
  bool get joinable => ownedBookId == null && availability?.existingRequestId != null && !availability!.alreadySubscribed;

  bool get canAsk => ownedBookId == null && !following;
}

/// Statuses a request can still be cancelled from.
bool canCancelBookRequest(String status) => !const {'rejected', 'cancelled', 'available'}.contains(status);

/// Finished one way or another; only these can be hidden or deleted.
bool isSettledBookRequest(String status) =>
    const {'rejected', 'cancelled', 'available', 'failed'}.contains(status);

/// The server is moving these along by itself, so a list showing one is
/// worth refreshing.
bool isBookRequestWorking(String status) =>
    const {'searching', 'grabbed', 'downloading', 'importing'}.contains(status);

class BookRequestAccess {
  final bool canRequest;
  final bool canManage;
  final bool autoApprove;
  final bool selfFulfill;

  /// The server takes an e-book and audiobook request together, and no
  /// longer takes comic requests (BookOrbit 3.4).
  final bool pairs;

  const BookRequestAccess({
    this.canRequest = false,
    this.canManage = false,
    this.autoApprove = false,
    this.selfFulfill = false,
    this.pairs = false,
  });

  List<String> get mediaKinds => pairs ? bookRequestPairMediaKinds : bookRequestMediaKinds;

  static const none = BookRequestAccess();
}

class BookRequestDownload {
  final int? id;
  final String status;
  final double progressPercent;
  final String releaseTitle;
  final String? errorMessage;

  const BookRequestDownload({
    this.id,
    required this.status,
    required this.progressPercent,
    required this.releaseTitle,
    this.errorMessage,
  });

  static BookRequestDownload? fromJson(Object? json) {
    if (json is! Map) return null;
    return BookRequestDownload(
      id: (json['id'] as num?)?.toInt(),
      status: '${json['status'] ?? ''}',
      progressPercent: ((json['progressPercent'] as num?) ?? 0).toDouble().clamp(0, 100),
      releaseTitle: '${json['releaseTitle'] ?? ''}',
      errorMessage: _text(json['errorMessage']),
    );
  }
}

class BookRequest {
  final Map<String, dynamic> raw;
  const BookRequest(this.raw);

  int get id => (raw['id'] as num).toInt();
  int? get userId => (raw['userId'] as num?)?.toInt();
  String get requester => _text(raw['requesterName']) ?? _text(raw['requesterUsername']) ?? '';
  String get mediaKind => '${raw['mediaKind'] ?? ''}';
  String get status => '${raw['status'] ?? ''}';
  String get title => _text(raw['title']) ?? '';
  String? get subtitle => _text(raw['subtitle']);
  List<String> get authors => [
        for (final a in (raw['authors'] as List? ?? const []))
          if ('$a'.trim().isNotEmpty) '$a'.trim(),
      ];
  String? get seriesName => _text(raw['seriesName']);
  num? get seriesIndex => raw['seriesIndex'] as num?;
  String? get isbn => _text(raw['isbn13']) ?? _text(raw['isbn10']);
  int? get publishedYear => (raw['publishedYear'] as num?)?.toInt();
  String? get coverUrl => _text(raw['coverUrl']);
  int? get targetLibraryId => (raw['targetLibraryId'] as num?)?.toInt();
  String? get targetLibraryName => _text(raw['targetLibraryName']);
  String? get decidedBy => _text(raw['decidedByUsername']);
  DateTime? get decidedAt => _date(raw['decidedAt']);
  String? get decisionNote => _text(raw['decisionNote']);
  String? get note => _text(raw['note']);
  int? get matchedBookId => (raw['matchedBookId'] as num?)?.toInt();

  /// The other half when the e-book and audiobook were asked for together.
  int? get companionRequestId => (raw['companionRequestId'] as num?)?.toInt();

  /// Who picks the release: the self-serve user who took it on, else the
  /// requester.
  int? get fulfillerUserId => (raw['fulfillerUserId'] as num?)?.toInt() ?? userId;
  bool get selfServe => raw['selfServe'] == true;
  String? get statusReason => _text(raw['statusReason']);
  String? get failureCode => _text(raw['failureCode']);
  bool get dismissed => raw['dismissed'] == true;
  DateTime? get createdAt => _date(raw['createdAt']);
  DateTime? get updatedAt => _date(raw['updatedAt']);
  BookRequestDownload? get download => BookRequestDownload.fromJson(raw['download']);
  List<({int userId, String name})> get subscribers => [
        for (final s in (raw['subscribers'] as List? ?? const []).whereType<Map>())
          if (s['userId'] is num)
            (userId: (s['userId'] as num).toInt(), name: _text(s['name']) ?? _text(s['username']) ?? ''),
      ];
}

class BookRequestAvailability {
  final int? ownedBookId;
  final int? existingRequestId;
  final String? existingRequestStatus;
  final bool alreadySubscribed;

  const BookRequestAvailability({
    this.ownedBookId,
    this.existingRequestId,
    this.existingRequestStatus,
    this.alreadySubscribed = false,
  });

  static BookRequestAvailability? fromJson(Object? json) {
    if (json is! Map) return null;
    return BookRequestAvailability(
      ownedBookId: (json['ownedBookId'] as num?)?.toInt(),
      existingRequestId: (json['existingRequestId'] as num?)?.toInt(),
      existingRequestStatus: _text(json['existingRequestStatus']),
      alreadySubscribed: json['alreadySubscribed'] == true,
    );
  }

  /// One answer for a work from the answers for its records.
  static BookRequestAvailability? merge(Iterable<BookRequestAvailability?> all) {
    final known = all.whereType<BookRequestAvailability>().toList();
    if (known.isEmpty) return null;
    BookRequestAvailability? requested;
    for (final a in known) {
      if (a.existingRequestId != null) {
        requested = a;
        break;
      }
    }
    int? owned;
    for (final a in known) {
      if (a.ownedBookId != null) {
        owned = a.ownedBookId;
        break;
      }
    }
    return BookRequestAvailability(
      ownedBookId: owned,
      existingRequestId: requested?.existingRequestId,
      existingRequestStatus: requested?.existingRequestStatus,
      alreadySubscribed: known.any((a) => a.alreadySubscribed),
    );
  }
}

/// The outcome of asking for a book.
class BookRequestSubmitResult {
  final BookRequest? request;

  /// The book was already asked for, so this added the user to that request.
  final bool subscribed;
  final String? error;

  const BookRequestSubmitResult({this.request, this.subscribed = false, this.error});

  bool get ok => request != null;

  static BookRequestSubmitResult fromJson(Object? json) {
    if (json is! Map || json['request'] is! Map || (json['request'] as Map)['id'] is! num) {
      return const BookRequestSubmitResult();
    }
    return BookRequestSubmitResult(
      request: BookRequest(Map<String, dynamic>.from(json['request'] as Map)),
      subscribed: json['subscribed'] == true,
    );
  }
}

/// Both halves of an e-book and audiobook request made together.
class BookRequestPairResult {
  final BookRequestSubmitResult ebook;
  final BookRequestSubmitResult audiobook;
  final String? error;

  const BookRequestPairResult({
    this.ebook = const BookRequestSubmitResult(),
    this.audiobook = const BookRequestSubmitResult(),
    this.error,
  });

  bool get ok => ebook.ok && audiobook.ok;
}

enum BookRequestAction {
  cancel,
  dismiss,
  restore,
  leave,
  approve,
  reject,
  delete,

  /// File a held import into its library anyway.
  forceFile,

  /// Throw a held import away; the request fails and can be tried again.
  discardImport,

  /// Stop the running download; the request goes back to approved.
  stopDownload,
}

/// Lowercase with common accents folded and everything but letters and
/// digits dropped, like BookOrbit's `normalizeWorkToken`.
String normalizeWorkToken(String value) => normalizeForMatch(value).replaceAll(' ', '');

/// The key two records share when they describe the same work, the one
/// BookOrbit folds requests on.
String bookRequestWorkKey(String title, String? author, String mediaKind) {
  final t = normalizeWorkToken(title);
  return 'work:${t.isEmpty ? title.trim().toLowerCase() : t}:${normalizeWorkToken(author ?? '')}:$mediaKind';
}

String _digits(String? v) => (v ?? '').replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();

bool _validIsbn13(String s) {
  if (!RegExp(r'^\d{13}$').hasMatch(s)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(s[i]) * (i.isEven ? 1 : 3);
  }
  return (10 - sum % 10) % 10 == int.parse(s[12]);
}

bool _validIsbn10(String s) {
  if (!RegExp(r'^\d{9}[\dX]$').hasMatch(s)) return false;
  var sum = 0;
  for (var i = 0; i < 10; i++) {
    sum += (s[i] == 'X' ? 10 : int.parse(s[i])) * (10 - i);
  }
  return sum % 11 == 0;
}

/// A valid ISBN-13 for the record, converting an ISBN-10 when that is all
/// it has.
String? canonicalRequestIsbn(String? isbn10, String? isbn13) {
  final t = _digits(isbn13);
  if (_validIsbn13(t)) return t;
  final ten = _digits(isbn10);
  if (!_validIsbn10(ten)) return null;
  final core = '978${ten.substring(0, 9)}';
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(core[i]) * (i.isEven ? 1 : 3);
  }
  return '$core${(10 - sum % 10) % 10}';
}

/// Search results that describe the same work, shown as one row.
class BookRequestWork {
  final String key;
  final List<MatchCandidate> records;
  BookRequestAvailability? availability;

  BookRequestWork(this.key, this.records);

  /// The most complete record: cover, then ISBN, then a year.
  MatchCandidate get best {
    int score(MatchCandidate c) =>
        (c.coverUrl.isNotEmpty ? 4 : 0) + (c.isbn13.isNotEmpty ? 2 : 0) + (c.year.isNotEmpty ? 1 : 0);
    final sorted = [...records]..sort((a, b) => score(b) - score(a));
    return sorted.first;
  }

  String get title => best.title;
  List<String> get authors => best.authors;
  String? get coverUrl {
    for (final r in [best, ...records]) {
      if (r.coverUrl.startsWith('http')) return r.coverUrl;
    }
    return null;
  }

  /// The earliest edition dates the work.
  int? get year {
    final years = [for (final r in records) int.tryParse(r.year)].whereType<int>();
    return years.isEmpty ? null : years.reduce((a, b) => a < b ? a : b);
  }

  /// The ISBN most of the sources agree on.
  String? get isbn {
    final counts = <String, Set<String>>{};
    for (final r in records) {
      final i = canonicalRequestIsbn(r.isbn10, r.isbn13);
      if (i != null) (counts[i] ??= {}).add(r.provider);
    }
    if (counts.isEmpty) return null;
    final bestIsbn = canonicalRequestIsbn(best.isbn10, best.isbn13);
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final byAgreement = b.value.length - a.value.length;
        if (byAgreement != 0) return byAgreement;
        return (a.key == bestIsbn ? 0 : 1) - (b.key == bestIsbn ? 0 : 1);
      });
    return ranked.first.key;
  }

  List<String> get providers => {for (final r in records) r.provider}.toList();
}

/// Search results grouped into works, in the order the works first arrived.
List<BookRequestWork> groupRequestResults(List<MatchCandidate> results, String mediaKind) {
  final byKey = <String, BookRequestWork>{};
  for (final r in results) {
    if (r.title.isEmpty) continue;
    final key = bookRequestWorkKey(r.title, r.authors.isEmpty ? null : r.authors.first, mediaKind);
    (byKey[key] ??= BookRequestWork(key, [])).records.add(r);
  }
  return byKey.values.toList();
}

String? _clip(String? v, int max) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return null;
  return s.length > max ? s.substring(0, max) : s;
}

/// The body of `POST /book-requests` for [work]. BookOrbit refuses unknown
/// fields, so only what its form sends goes in.
Map<String, dynamic> bookRequestPayload(
  BookRequestWork work,
  String mediaKind, {
  String Function(String provider)? providerLabel,
  String? note,
  int? libraryId,
  int? targetBookId,
}) {
  final best = work.best;
  final series = best.series.isEmpty ? null : best.series.first;
  final index = double.tryParse(series?.index ?? '');
  final year = work.year;
  final cover = work.coverUrl;
  return {
    'title': _clip(work.title, 500),
    'mediaKind': mediaKind,
    if (_clip(best.subtitle, 500) != null) 'subtitle': _clip(best.subtitle, 500),
    'authors': [
      for (final a in work.authors.take(50)) _clip(a, 255)!,
    ],
    if (_clip(series?.name, 500) != null) 'seriesName': _clip(series?.name, 500),
    if (index != null && index >= 0) 'seriesIndex': index.truncate(),
    if (work.isbn != null) 'isbn13': work.isbn,
    if (year != null && year >= 0 && year <= 9999) 'publishedYear': year,
    if (_clip(best.provider, 50) != null) 'providerKey': _clip(best.provider, 50),
    if (_clip(best.providerId, 255) != null) 'providerId': _clip(best.providerId, 255),
    if (cover != null && cover.length <= 2048) 'coverUrl': cover,
    'metadataSources': [
      for (final r in work.records.take(20))
        if (r.provider.isNotEmpty && r.providerId.isNotEmpty)
          {
            'providerKey': _clip(r.provider, 50),
            'providerId': _clip(r.providerId, 255),
            'providerLabel': _clip(providerLabel?.call(r.provider) ?? r.provider, 100) ?? r.provider,
            'isbn10': _clip(r.isbn10, 20),
            'isbn13': _clip(r.isbn13, 20),
          },
    ],
    if (_clip(note, 2000) != null) 'note': _clip(note, 2000),
    'targetLibraryId': ?libraryId,
    // Joins a book that already has the other format. Only servers that take
    // pairs know this field.
    'targetBookId': ?targetBookId,
  };
}

/// The body of `POST /book-requests/pairs`: the work once, and the library
/// each format goes to.
Map<String, dynamic> bookRequestPairPayload(
  BookRequestWork work, {
  String Function(String provider)? providerLabel,
  String? note,
  int? ebookLibraryId,
  int? audiobookLibraryId,
}) {
  final body = bookRequestPayload(work, 'ebook', providerLabel: providerLabel, note: note)
    ..remove('mediaKind')
    ..remove('targetLibraryId');
  return {
    ...body,
    'ebook': {'targetLibraryId': ?ebookLibraryId},
    'audiobook': {'targetLibraryId': ?audiobookLibraryId},
  };
}

/// An Audible book's authors: a comma-joined string from the series lookups,
/// or a list from other sources.
List<String> audibleBookAuthors(Map<String, dynamic> book) {
  final raw = book['authors'];
  final names = raw is List
      ? [for (final a in raw) a is Map ? '${a['name'] ?? ''}' : '$a']
      : '${raw ?? ''}'.split(',');
  return [
    for (final n in names)
      if (n.trim().isNotEmpty) n.trim(),
  ];
}

/// The body of `POST /book-requests` for an audiobook found on Audible, as
/// the series scan and Find Missing Books list them. Null without a title.
Map<String, dynamic>? audibleBookRequestPayload(
  Map<String, dynamic> book, {
  String? seriesName,
  String? note,
  int? libraryId,
}) {
  final title = _clip('${book['title'] ?? ''}', 500);
  if (title == null) return null;
  final asin = _clip('${book['asin'] ?? ''}', 255);
  final authors = audibleBookAuthors(book);
  final index = double.tryParse('${book['sequence'] ?? ''}'.trim());
  final year = DateTime.tryParse('${book['releaseDate'] ?? ''}')?.year;
  final cover = _clip('${book['coverUrl'] ?? ''}', 2048);
  return {
    'title': title,
    'mediaKind': 'audiobook',
    'subtitle': ?_clip('${book['subtitle'] ?? ''}', 500),
    'authors': [
      for (final a in authors.take(50)) ?_clip(a, 255),
    ],
    'seriesName': ?_clip(seriesName, 500),
    if (index != null && index >= 0) 'seriesIndex': index.truncate(),
    if (year != null && year >= 0 && year <= 9999) 'publishedYear': year,
    if (cover != null && cover.startsWith('http')) 'coverUrl': cover,
    if (asin != null) ...{
      'providerKey': 'audible',
      'providerId': asin,
      'metadataSources': [
        {'providerKey': 'audible', 'providerId': asin, 'providerLabel': 'Audible'},
      ],
    },
    'note': ?_clip(note, 2000),
    'targetLibraryId': ?libraryId,
  };
}

String? _text(Object? v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

/// A release can be picked by hand from these.
bool canGrabBookRequest(String status) => const {'approved', 'searching', 'failed'}.contains(status);

class BookRequestReleaseReason {
  final String code;
  final int points;
  final String? detail;

  const BookRequestReleaseReason(this.code, this.points, this.detail);
}

/// One release an indexer offered for a request.
class BookRequestRelease {
  final Map<String, dynamic> raw;
  const BookRequestRelease(this.raw);

  int get indexerId => (raw['indexerId'] as num).toInt();
  String get indexerName => _text(raw['indexerName']) ?? '';
  String get guid => '${raw['guid'] ?? ''}';
  String get title => _text(raw['title']) ?? '';
  int? get sizeBytes => (raw['sizeBytes'] as num?)?.toInt();
  int? get seeders => (raw['seeders'] as num?)?.toInt();
  int? get leechers => (raw['leechers'] as num?)?.toInt();
  List<String> get formats {
    final all = [
      for (final f in (raw['formats'] as List? ?? const []))
        if ('$f'.trim().isNotEmpty) '$f'.trim(),
    ];
    final primary = _text(raw['format']);
    if (all.isEmpty && primary != null) return [primary];
    return all;
  }

  String? get language => _text(raw['language']);
  int? get fileCount => (raw['fileCount'] as num?)?.toInt();
  bool get freeleech => raw['freeleech'] == true;
  bool get vipOnly => raw['vipOnly'] == true;
  bool get alreadyGrabbed => raw['alreadyGrabbed'] == true;
  DateTime? get publishedAt => _date(raw['publishedAt']);
  int? get bitrateKbps => ((raw['audio'] as Map?)?['bitrateKbps'] as num?)?.round();
  double get score => ((raw['score'] as num?) ?? 0).toDouble();
  int? get tier => (raw['tier'] as num?)?.toInt();
  String? get tierName => _text(raw['tierName']);
  List<BookRequestReleaseReason> get reasons => [
        for (final r in (raw['reasons'] as List? ?? const []).whereType<Map>())
          BookRequestReleaseReason('${r['code'] ?? ''}', ((r['points'] as num?) ?? 0).round(), _text(r['detail'])),
      ];
}

class BookRequestIndexerStatus {
  final String name;
  final bool ok;
  final int count;
  final String? failure;

  const BookRequestIndexerStatus({required this.name, required this.ok, required this.count, this.failure});
}

/// What a release search found, and what it searched for.
class BookRequestReleases {
  final List<BookRequestRelease> releases;
  final List<BookRequestIndexerStatus> indexers;
  final int enabledIndexers;
  final int configuredIndexers;
  final int uncoveredIndexers;
  final bool cached;
  final String title;
  final List<String> authors;
  final String? isbn;

  const BookRequestReleases({
    required this.releases,
    required this.indexers,
    required this.enabledIndexers,
    required this.configuredIndexers,
    required this.uncoveredIndexers,
    required this.cached,
    required this.title,
    required this.authors,
    this.isbn,
  });

  static BookRequestReleases fromJson(Map<String, dynamic> json) {
    final criteria = (json['criteria'] as Map?) ?? const {};
    return BookRequestReleases(
      releases: [
        for (final r in (json['releases'] as List? ?? const []).whereType<Map>())
          if (r['indexerId'] is num && '${r['guid'] ?? ''}'.isNotEmpty) BookRequestRelease(Map<String, dynamic>.from(r)),
      ],
      indexers: [
        for (final i in (json['indexers'] as List? ?? const []).whereType<Map>())
          BookRequestIndexerStatus(
            name: _text(i['indexerName']) ?? '',
            ok: i['ok'] == true,
            count: ((i['count'] as num?) ?? 0).toInt(),
            failure: _text(i['failure']),
          ),
      ],
      enabledIndexers: ((json['enabledIndexerCount'] as num?) ?? 0).toInt(),
      configuredIndexers: ((json['configuredIndexerCount'] as num?) ?? 0).toInt(),
      uncoveredIndexers: ((json['uncoveredIndexerCount'] as num?) ?? 0).toInt(),
      cached: json['cached'] == true,
      title: _text(criteria['title']) ?? '',
      authors: [
        for (final a in (criteria['authors'] as List? ?? const []))
          if ('$a'.trim().isNotEmpty) '$a'.trim(),
      ],
      isbn: _text(criteria['activeIsbn']),
    );
  }
}

enum BookRequestReleaseSort { best, seeders, size, newest }

/// Profile tier first (no tier last), then the chosen order, then score and
/// seeders, the way BookOrbit's picker orders them.
List<BookRequestRelease> sortBookRequestReleases(List<BookRequestRelease> releases, BookRequestReleaseSort sort) {
  int byTier(int? a, int? b) {
    if (a == b) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a - b;
  }

  double orderOf(BookRequestRelease r) => switch (sort) {
        BookRequestReleaseSort.seeders => (r.seeders ?? -1).toDouble(),
        BookRequestReleaseSort.size => (r.sizeBytes ?? -1).toDouble(),
        BookRequestReleaseSort.newest => (r.publishedAt?.millisecondsSinceEpoch ?? -1).toDouble(),
        BookRequestReleaseSort.best => r.score,
      };

  return [...releases]..sort((a, b) {
      final tier = byTier(a.tier, b.tier);
      if (tier != 0) return tier;
      final order = orderOf(b).compareTo(orderOf(a));
      if (order != 0) return order;
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return (b.seeders ?? -1).compareTo(a.seeders ?? -1);
    });
}

/// Why an import is waiting on someone, and what landed.
class BookRequestReview {
  final int? score;
  final int? threshold;
  final List<({String field, String? requested, String? imported, String verdict})> rows;
  final List<({String fileName, int? size, String? role})> files;
  final int? totalSizeBytes;
  final bool canFile;
  final bool dockEntryGone;

  const BookRequestReview({
    this.score,
    this.threshold,
    this.rows = const [],
    this.files = const [],
    this.totalSizeBytes,
    this.canFile = false,
    this.dockEntryGone = false,
  });

  static BookRequestReview fromJson(Map<String, dynamic> json) {
    final v = json['verification'] as Map?;
    return BookRequestReview(
      score: (v?['score'] as num?)?.round(),
      threshold: (v?['threshold'] as num?)?.round(),
      rows: [
        for (final r in (v?['rows'] as List? ?? const []).whereType<Map>())
          (
            field: '${r['field'] ?? ''}',
            requested: _text(r['requested']),
            imported: _text(r['imported']),
            verdict: '${r['verdict'] ?? 'unknown'}',
          ),
      ],
      files: [
        for (final f in (json['files'] as List? ?? const []).whereType<Map>())
          (fileName: _text(f['fileName']) ?? '', size: (f['fileSize'] as num?)?.toInt(), role: _text(f['role'])),
      ],
      totalSizeBytes: (json['totalSizeBytes'] as num?)?.toInt(),
      canFile: json['canFile'] == true,
      dockEntryGone: json['bookDockFileId'] == null,
    );
  }
}

/// Bytes as the release lists show them.
String formatReleaseSize(int? bytes) {
  if (bytes == null || bytes < 0) return '';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return unit == 0 ? '$bytes B' : '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}
