/// BookOrbit's chapter editor (3.6.0 and newer): the stored list with its
/// revision, where it came from, and what else can name a book's chapters.
library;

class BoChapter {
  final String title;
  final int startMs;
  const BoChapter(this.title, this.startMs);

  static List<BoChapter> listFrom(Object? raw) => [
        for (final c in (raw as List<dynamic>? ?? const []).whereType<Map>())
          BoChapter('${c['title'] ?? ''}', (c['startMs'] as num?)?.round() ?? 0),
      ];

  Map<String, dynamic> toJson() => {'title': title, 'startMs': startMs};
}

class BoChapterState {
  final List<BoChapter> chapters;

  /// embedded, tracks, provider, migration or manual.
  final String? source;

  /// Nothing stored: one chapter per audio file, worked out on the fly.
  final bool derived;

  /// Rescans and metadata refreshes leave the list alone.
  final bool locked;
  final String revision;
  final DateTime? updatedAt;
  final String? updatedBy;
  final int? totalDurationMs;
  final String? audibleId;
  final int versionCount;
  final String audibleRegion;
  final int? ebookFileId;
  final int? readAlongFileId;
  final bool canWrite;
  final String? writeBlockedReason;
  final int writeFileCount;

  const BoChapterState({
    required this.chapters,
    required this.source,
    required this.derived,
    required this.locked,
    required this.revision,
    this.updatedAt,
    this.updatedBy,
    this.totalDurationMs,
    this.audibleId,
    this.versionCount = 0,
    this.audibleRegion = 'us',
    this.ebookFileId,
    this.readAlongFileId,
    this.canWrite = false,
    this.writeBlockedReason,
    this.writeFileCount = 0,
  });

  static BoChapterState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final revision = raw['revision'];
    if (revision is! String || revision.isEmpty) return null;
    final sources = raw['sources'] as Map? ?? const {};
    final write = raw['writeBack'] as Map? ?? const {};
    return BoChapterState(
      chapters: BoChapter.listFrom(raw['chapters']),
      source: raw['source'] as String?,
      derived: raw['derived'] == true,
      locked: raw['locked'] == true,
      revision: revision,
      updatedAt: DateTime.tryParse('${raw['updatedAt'] ?? ''}'),
      updatedBy: (raw['updatedBy'] as Map?)?['name'] as String?,
      totalDurationMs: (raw['totalDurationMs'] as num?)?.round(),
      audibleId: raw['audibleId'] as String?,
      versionCount: (raw['versionCount'] as num?)?.toInt() ?? 0,
      audibleRegion: raw['audibleRegion'] as String? ?? 'us',
      ebookFileId: (sources['ebookFileId'] as num?)?.toInt(),
      readAlongFileId: (sources['readAlongFileId'] as num?)?.toInt(),
      canWrite: write['available'] == true,
      writeBlockedReason: write['reason'] as String?,
      writeFileCount: (write['fileCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class BoChapterVersion {
  final int id;
  final String source;
  final int chapterCount;
  final DateTime? createdAt;
  final String? createdBy;
  final List<BoChapter> chapters;

  const BoChapterVersion({
    required this.id,
    required this.source,
    required this.chapterCount,
    this.createdAt,
    this.createdBy,
    this.chapters = const [],
  });

  static BoChapterVersion? fromJson(Object? raw) {
    if (raw is! Map || raw['id'] is! num) return null;
    return BoChapterVersion(
      id: (raw['id'] as num).toInt(),
      source: '${raw['source'] ?? 'manual'}',
      chapterCount: (raw['chapterCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse('${raw['createdAt'] ?? ''}'),
      createdBy: (raw['createdBy'] as Map?)?['name'] as String?,
      chapters: BoChapter.listFrom(raw['chapters']),
    );
  }
}

/// Chapters read from the book's EPUB: its contents (titles in order, no
/// times) or its read along (times on the narration's own timeline).
class BoEbookChapters {
  final List<BoChapter> chapters;
  final bool titlesOnly;
  final int? runtimeMs;
  const BoEbookChapters(this.chapters, {required this.titlesOnly, this.runtimeMs});
}

/// Why a chapter call didn't go through. [stale]: someone saved a newer list
/// since this one was loaded.
enum BoChapterFailure { stale, invalid, notFound, unavailable, forbidden, failed }

BoChapterFailure boChapterFailureFor(int status, String? errorCode) {
  if (errorCode == 'CHAPTERS_STALE') return BoChapterFailure.stale;
  if (errorCode == 'CHAPTERS_LOOKUP_NOT_FOUND') return BoChapterFailure.notFound;
  if (errorCode == 'CHAPTERS_LOOKUP_UNAVAILABLE' ||
      errorCode == 'CHAPTERS_EBOOK_UNAVAILABLE' ||
      errorCode == 'CHAPTERS_WRITE_UNAVAILABLE' ||
      errorCode == 'CHAPTERS_NOTHING_TO_WRITE' ||
      errorCode == 'CHAPTERS_FILES_UNREADABLE') {
    return BoChapterFailure.unavailable;
  }
  return switch (status) {
    400 => BoChapterFailure.invalid,
    403 => BoChapterFailure.forbidden,
    404 => BoChapterFailure.notFound,
    409 || 503 => BoChapterFailure.unavailable,
    _ => BoChapterFailure.failed,
  };
}

/// A write into the audio files, a revert, or a read of the files' own
/// chapters, which BookOrbit runs in the background.
class BoChapterJob {
  final String id;
  final String kind;
  final String status;
  final int filesWritten;
  final int filesTotal;
  final Map<String, dynamic>? result;
  final String? errorCode;

  const BoChapterJob({
    required this.id,
    required this.kind,
    required this.status,
    this.filesWritten = 0,
    this.filesTotal = 0,
    this.result,
    this.errorCode,
  });

  bool get finished => status == 'success' || status == 'failed';
  bool get succeeded => status == 'success';

  static BoChapterJob? fromJson(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    return BoChapterJob(
      id: raw['id'] as String,
      kind: '${raw['kind'] ?? ''}',
      status: '${raw['status'] ?? 'queued'}',
      filesWritten: (raw['filesWritten'] as num?)?.toInt() ?? 0,
      filesTotal: (raw['filesTotal'] as num?)?.toInt() ?? 0,
      result: (raw['result'] as Map?)?.cast<String, dynamic>(),
      errorCode: raw['errorCode'] as String?,
    );
  }
}

/// A BookOrbit lookup in the Audnexus shape the chapter editor's lookup
/// takes. Audible nests chapters under parts; a part keeps its own chapter,
/// since it usually carries a few seconds of announcement.
Map<String, dynamic> boLookupAsAudnexus(Map<String, dynamic> lookup) {
  final flat = <Map<String, dynamic>>[];
  void walk(Object? nodes) {
    for (final n in (nodes as List<dynamic>? ?? const []).whereType<Map>()) {
      final start = (n['startMs'] as num?)?.round() ?? 0;
      final children = (n['children'] as List<dynamic>? ?? const []).whereType<Map>().toList();
      final firstChild = children.isEmpty ? null : (children.first['startMs'] as num?)?.round();
      // A part with no audio of its own starts with its first chapter.
      if (firstChild != null && start >= firstChild) {
        walk(children);
        continue;
      }
      flat.add({
        'title': '${n['title'] ?? ''}',
        'startOffsetMs': start,
        'startOffsetSec': start ~/ 1000,
        'lengthMs': (n['lengthMs'] as num?)?.round() ?? 0,
      });
      walk(n['children']);
    }
  }

  walk(lookup['chapters']);
  flat.sort((a, b) => (a['startOffsetMs'] as int).compareTo(b['startOffsetMs'] as int));
  return {
    'asin': lookup['asin'],
    'brandIntroDurationMs': (lookup['brandIntroMs'] as num?)?.round() ?? 0,
    'brandOutroDurationMs': (lookup['brandOutroMs'] as num?)?.round() ?? 0,
    'isAccurate': lookup['isAccurate'],
    if (lookup['runtimeMs'] is num) 'runtimeLengthMs': (lookup['runtimeMs'] as num).round(),
    'chapters': flat,
  };
}
