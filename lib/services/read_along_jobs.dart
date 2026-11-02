/// BookOrbit's read along maker (3.6.0 and up): it matches an audiobook's
/// narration to the book's EPUB and adds an EPUB that highlights along with
/// the audio. Follows BookOrbit's shared types (packages/types/src/read-aloud.ts).
library;

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

double? _double(Object? v) => v is num ? v.toDouble() : null;

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

List<Map<String, dynamic>> _maps(Object? v) =>
    (v is List ? v : const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();

/// A file on the book a read along can be made from.
class ReadAlongSource {
  final int id;
  final String filename;
  final int? size;
  final double? duration;

  const ReadAlongSource({required this.id, required this.filename, this.size, this.duration});

  static ReadAlongSource? fromJson(Map<String, dynamic> json) {
    final id = _int(json['id']);
    if (id == null) return null;
    return ReadAlongSource(
      id: id,
      filename: '${json['filename'] ?? ''}',
      size: _int(json['sizeBytes']),
      duration: _double(json['durationSeconds']),
    );
  }
}

/// A read along EPUB the book already has.
class ReadAlongExisting {
  final int fileId;
  final String filename;
  final int? size;

  /// Made by BookOrbit rather than imported, so it's safe to overwrite.
  final bool madeByBookOrbit;

  const ReadAlongExisting({required this.fileId, required this.filename, this.size, this.madeByBookOrbit = false});

  static ReadAlongExisting? fromJson(Map<String, dynamic> json) {
    final id = _int(json['fileId']);
    if (id == null) return null;
    return ReadAlongExisting(
      fileId: id,
      filename: '${json['filename'] ?? ''}',
      size: _int(json['sizeBytes']),
      madeByBookOrbit: json['generatedByJobId'] != null,
    );
  }
}

/// What the job card shows of the worker's own stages.
const readAlongSteps = <(String, List<String>)>[
  ('audio', ['preparing_audio']),
  ('speech', ['downloading_model', 'generating_emissions']),
  ('text', ['marking_up_ebook']),
  ('align', ['aligning']),
  ('check', ['validating']),
  ('publish', ['awaiting_review', 'publishing', 'completed']),
];

/// Index into [readAlongSteps] for [stage], -1 while queued or for a stage
/// this build doesn't know.
int readAlongStepOf(String stage) => readAlongSteps.indexWhere((s) => s.$2.contains(stage));

class ReadAlongJob {
  final String id;
  final String bookId;
  final String status;
  final String stage;

  /// 0 to 100.
  final double progress;
  final int? stageCurrent;
  final int? stageTotal;
  final String? stageUnit;

  /// Jobs ahead of this one while it waits.
  final int? queuePosition;
  final int? epubFileId;
  final List<int> audioFileIds;
  final String? language;
  final String granularity;
  final int? replaceFileId;
  final int? outputFileId;
  final List<String> warnings;
  final String? errorCode;
  final bool cancelRequested;
  final bool cancellable;

  /// Whether this account may cancel, add, retry or dismiss it.
  final bool canManage;
  final int? requestedById;
  final String? requestedByName;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? dismissedAt;

  /// When output waiting for review is thrown away on its own.
  final DateTime? expiresAt;

  /// Until when Retry picks up from the last finished step.
  final DateTime? retryableUntil;

  /// Sentences with narration timing, and the sentences the narration
  /// covers (front and back matter left out when the server could tell).
  final int? matchedSentences;
  final int? totalSentences;

  /// Share of the audio placed against the text, 0 to 1.
  final double? audioUsed;

  /// Chapters the narration never reads, so they have no audio.
  final List<String> outsideTitles;
  final int outsideMore;

  const ReadAlongJob({
    required this.id,
    required this.bookId,
    required this.status,
    required this.stage,
    this.progress = 0,
    this.stageCurrent,
    this.stageTotal,
    this.stageUnit,
    this.queuePosition,
    this.epubFileId,
    this.audioFileIds = const [],
    this.language,
    this.granularity = 'sentence',
    this.replaceFileId,
    this.outputFileId,
    this.warnings = const [],
    this.errorCode,
    this.cancelRequested = false,
    this.cancellable = false,
    this.canManage = false,
    this.requestedById,
    this.requestedByName,
    this.startedAt,
    this.updatedAt,
    this.dismissedAt,
    this.expiresAt,
    this.retryableUntil,
    this.matchedSentences,
    this.totalSentences,
    this.audioUsed,
    this.outsideTitles = const [],
    this.outsideMore = 0,
  });

  static ReadAlongJob? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final id = json['id'];
    final status = json['status'];
    if (id is! String || status is! String) return null;
    final input = json['input'] is Map ? Map<String, dynamic>.from(json['input'] as Map) : const <String, dynamic>{};
    final detail = json['stageDetail'] is Map ? json['stageDetail'] as Map : null;
    final requester = json['requestedBy'] is Map ? json['requestedBy'] as Map : const {};
    final report = json['report'] is Map ? json['report'] as Map : null;
    final coverage = json['coverage'] is Map ? json['coverage'] as Map : null;

    int? matched;
    int? total;
    double? audioUsed;
    final sentences = _int(report?['sentences']) ?? 0;
    if (report != null && sentences > 0) {
      total = coverage != null ? (_int(coverage['storySentences']) ?? sentences) : sentences;
      final hit = (_int(report['matchedSentences']) ?? 0) + (_int(report['interpolatedSentences']) ?? 0);
      matched = hit > total ? total : hit;
      final seconds = _double(report['seconds']) ?? 0;
      if (seconds > 0) {
        final placed = (_double(report['matchedSeconds']) ?? 0) + (_double(report['interpolatedSeconds']) ?? 0);
        audioUsed = (placed / seconds).clamp(0.0, 1.0);
      }
    }
    final outside = [
      for (final t in (coverage?['outsideTitles'] as List? ?? const []))
        if (t is String && t.trim().isNotEmpty) t.trim(),
    ];
    final outsideCount = _int(coverage?['outsideChapterCount']) ?? outside.length;

    return ReadAlongJob(
      id: id,
      bookId: '${json['bookId'] ?? ''}',
      status: status,
      stage: '${json['stage'] ?? ''}',
      progress: (_double(json['progress']) ?? 0).clamp(0.0, 100.0),
      stageCurrent: _int(detail?['current']),
      stageTotal: _int(detail?['total']),
      stageUnit: detail?['unit'] as String?,
      queuePosition: _int(json['queuePosition']),
      epubFileId: _int(input['epubFileId']),
      audioFileIds: [for (final v in (input['audioFileIds'] as List? ?? const [])) ?_int(v)],
      language: input['language'] as String?,
      granularity: input['granularity'] == 'word' ? 'word' : 'sentence',
      replaceFileId: _int(input['replaceFileId']),
      outputFileId: _int(json['outputFileId']),
      warnings: [for (final w in (json['warnings'] as List? ?? const [])) '$w'],
      errorCode: json['errorCode'] as String?,
      cancelRequested: json['cancelRequested'] == true,
      cancellable: json['cancellable'] == true,
      canManage: json['canManage'] == true,
      requestedById: _int(requester['id']),
      requestedByName: requester['name'] as String?,
      startedAt: _date(json['startedAt']),
      updatedAt: _date(json['updatedAt']),
      dismissedAt: _date(json['dismissedAt']),
      expiresAt: _date(json['expiresAt']),
      retryableUntil: _date(json['retryableUntil']),
      matchedSentences: matched,
      totalSentences: total,
      audioUsed: audioUsed,
      outsideTitles: outside,
      outsideMore: outsideCount > outside.length ? outsideCount - outside.length : 0,
    );
  }

  bool get queued => status == 'queued';
  bool get processing => status == 'processing';
  bool get running => queued || processing;
  bool get stopping => running && cancelRequested;
  bool get awaitingReview => status == 'awaiting_review';

  /// Still holding the book's slot, so it can change.
  bool get active => running || awaitingReview;
  bool get completed => status == 'completed' || status == 'completed_with_warnings';
  bool get failed => status == 'failed';
  bool get cancelled => status == 'cancelled';
  bool get finished => completed || failed || cancelled;
  bool get expired => errorCode == 'review_expired';

  /// Output thrown away at review, or left there too long.
  bool get discarded => expired || errorCode == 'discarded';

  bool canRetry(DateTime now) => failed && !expired && (retryableUntil?.isAfter(now) ?? false);

  /// Whether Cancel would still be taken: not once the file is being added.
  bool get canCancel => running && canManage && cancellable && !cancelRequested && stage != 'publishing';
}

/// What the book's Create read along button shows.
enum ReadAlongEntry { hidden, available, blocked }

class ReadAlongCapability {
  final List<String> languages;
  final bool workerConfigured;
  final String? device;
  final int? workerFreeBytes;
  final bool eligible;

  /// Why a read along can't be made right now, in BookOrbit's codes.
  final String? reason;
  final List<ReadAlongSource> epubs;
  final List<ReadAlongSource> audio;
  final List<ReadAlongExisting> existing;
  final int? estimatedSize;
  final ReadAlongJob? latestJob;

  const ReadAlongCapability({
    this.languages = const [],
    this.workerConfigured = false,
    this.device,
    this.workerFreeBytes,
    this.eligible = false,
    this.reason,
    this.epubs = const [],
    this.audio = const [],
    this.existing = const [],
    this.estimatedSize,
    this.latestJob,
  });

  static ReadAlongCapability fromJson(Map<String, dynamic> json) => ReadAlongCapability(
        languages: [for (final c in (json['supportedLanguages'] as List? ?? const [])) '$c'],
        workerConfigured: json['workerConfigured'] == true,
        device: json['workerDevice'] as String?,
        workerFreeBytes: _int(json['workerFreeBytes']),
        eligible: json['eligible'] == true,
        reason: json['reason'] as String?,
        epubs: [for (final f in _maps(json['epubFiles'])) ?ReadAlongSource.fromJson(f)],
        audio: [for (final f in _maps(json['audioFiles'])) ?ReadAlongSource.fromJson(f)],
        existing: [for (final f in _maps(json['existingReadAlongs'])) ?ReadAlongExisting.fromJson(f)],
        estimatedSize: _int(json['estimatedOutputBytes']),
        latestJob: ReadAlongJob.fromJson(json['latestJob']),
      );

  // Reasons only an admin or a library change can clear: a button that can
  // never work on this book would just sit there on every visit.
  static const _hiddenReasons = {'worker_not_configured', 'single_file_library', 'no_audiobook'};

  ReadAlongEntry entry(ReadAlongJob? job) {
    if (!workerConfigured || _hiddenReasons.contains(reason)) return ReadAlongEntry.hidden;
    if (job != null && job.active) return ReadAlongEntry.blocked;
    if (reason != null || !eligible) return ReadAlongEntry.blocked;
    return ReadAlongEntry.available;
  }

  /// Working space a fresh run needs on the worker, BookOrbit's own
  /// estimate: 4x the audio, 7x the EPUB, the speech model's output and
  /// 512 MB to spare.
  static int workBytes({required int audioBytes, required int epubBytes, double? audioSeconds}) {
    final seconds = audioSeconds ?? audioBytes / 8000;
    return 4 * audioBytes + 7 * epubBytes + (seconds * 3200).ceil() + 512 * 1024 * 1024;
  }
}

/// Why a read along request didn't go through.
enum ReadAlongFailure {
  /// A file picked is gone or no longer fits (400).
  invalid,
  forbidden,

  /// Another job is running for the book, or this one moved on (409).
  conflict,

  /// The worker is offline (503).
  unavailable,

  /// The job is gone (404).
  gone,
  failed,
}

ReadAlongFailure readAlongFailureFor(int status) => switch (status) {
      400 => ReadAlongFailure.invalid,
      403 => ReadAlongFailure.forbidden,
      404 => ReadAlongFailure.gone,
      409 => ReadAlongFailure.conflict,
      503 => ReadAlongFailure.unavailable,
      _ => ReadAlongFailure.failed,
    };

/// The languages BookOrbit's speech model knows, each in its own script.
const readAlongLanguageNames = <String, String>{
  'ar': 'العربية',
  'ca': 'Català',
  'de': 'Deutsch',
  'en': 'English',
  'es': 'Español',
  'fo': 'Føroyskt',
  'fr': 'Français',
  'hy': 'Հայերեն',
  'is': 'Íslenska',
  'it': 'Italiano',
  'ja': '日本語',
  'kk': 'Қазақ тілі',
  'mt': 'Malti',
  'pl': 'Polski',
  'pt': 'Português',
  'ru': 'Русский',
  'zh': '中文',
};

const _englishNames = <String, String>{
  'arabic': 'ar',
  'catalan': 'ca',
  'german': 'de',
  'english': 'en',
  'spanish': 'es',
  'faroese': 'fo',
  'french': 'fr',
  'armenian': 'hy',
  'icelandic': 'is',
  'italian': 'it',
  'japanese': 'ja',
  'kazakh': 'kk',
  'maltese': 'mt',
  'polish': 'pl',
  'portuguese': 'pt',
  'russian': 'ru',
  'chinese': 'zh',
};

const _threeLetterCodes = <String, String>{
  'ara': 'ar',
  'cat': 'ca',
  'ger': 'de',
  'deu': 'de',
  'eng': 'en',
  'spa': 'es',
  'fao': 'fo',
  'fre': 'fr',
  'fra': 'fr',
  'arm': 'hy',
  'hye': 'hy',
  'ice': 'is',
  'isl': 'is',
  'ita': 'it',
  'jpn': 'ja',
  'kaz': 'kk',
  'mlt': 'mt',
  'pol': 'pl',
  'por': 'pt',
  'rus': 'ru',
  'chi': 'zh',
  'zho': 'zh',
};

/// The language code a book's language field means, among [supported].
/// Metadata often says "English", "eng" or "en-US" rather than "en".
String? readAlongLanguageOf(String? value, List<String> supported) {
  final v = value?.trim().toLowerCase();
  if (v == null || v.isEmpty) return null;
  String? code = _englishNames[v];
  if (code == null) {
    for (final e in readAlongLanguageNames.entries) {
      if (e.value.toLowerCase() == v) code = e.key;
    }
  }
  if (code == null) {
    final first = v.split(RegExp(r'[-_ ]')).first;
    code = _threeLetterCodes[first] ?? first;
  }
  return supported.contains(code) ? code : null;
}
