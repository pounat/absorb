/// BookOrbit server administration: the people on it and its libraries.
/// The calls live on BookOrbitApiService (bookorbit_admin_api.dart).
library;

/// An admin request BookOrbit turned down, with its own reason when it gave
/// one ("Only administrators can edit administrator accounts").
class BookOrbitAdminError implements Exception {
  final int status;
  final String? message;
  final String? code;

  const BookOrbitAdminError(this.status, [this.message, this.code]);

  @override
  String toString() => 'BookOrbit admin $status: ${message ?? ''}';
}

/// What the signed-in BookOrbit user may administer.
class BookOrbitAdminAccess {
  final bool isSuperuser;
  final bool manageUsers;
  final bool manageLibraries;
  final bool emailSend;
  final bool manageEmail;
  final bool viewUserActivity;
  final bool manageAppSettings;
  final bool manageBookDock;
  final String userId;

  const BookOrbitAdminAccess({
    required this.isSuperuser,
    required this.manageUsers,
    required this.manageLibraries,
    this.emailSend = false,
    this.manageEmail = false,
    this.viewUserActivity = false,
    this.manageAppSettings = false,
    this.manageBookDock = false,
    required this.userId,
  });

  bool get any => isSuperuser || manageUsers || manageLibraries || manageEmail || manageAppSettings || manageBookDock;

  /// Whether the email settings have anything for this user.
  bool get email => emailSend || manageEmail;

  static BookOrbitAdminAccess? fromUser(Map<String, dynamic>? user) {
    final bo = user?['bookOrbit'];
    if (bo is! Map) return null;
    final superuser = bo['isSuperuser'] == true;
    final perms = {for (final p in (bo['permissions'] as List? ?? const [])) '$p'};
    return BookOrbitAdminAccess(
      isSuperuser: superuser,
      manageUsers: superuser || perms.contains('manage_users'),
      manageLibraries: superuser || perms.contains('manage_libraries'),
      emailSend: superuser || perms.contains('email_send'),
      manageEmail: superuser || perms.contains('manage_email'),
      viewUserActivity: superuser || perms.contains('view_user_activity'),
      manageAppSettings: superuser || perms.contains('manage_app_settings'),
      manageBookDock: superuser || perms.contains('manage_book_dock'),
      userId: '${user?['id'] ?? ''}',
    );
  }
}

/// How a request to email a password link went.
enum BoPasswordResetResult { sent, notSetUp, tooManyTries, failed }

/// One line of a breakdown of someone's reading time.
class BoReadingTime {
  final String name;
  final int seconds;
  const BoReadingTime(this.name, this.seconds);

  static List<BoReadingTime> listFrom(Object? v, {String key = 'name'}) => [
        for (final e in (v is List ? v : const []).whereType<Map<String, dynamic>>())
          BoReadingTime('${e[key] ?? ''}', _int(e['readingSeconds'])),
      ];
}

/// What someone chose to share about their reading over a period.
class BoReadingSummary {
  final bool detailed;
  final int activeDays;
  final int readingSeconds;
  final int sessions;
  final int booksStarted;
  final int booksCompleted;
  final List<BoReadingTime> formats;
  final List<BoReadingTime> genres;
  final List<BoReadingTime> sources;
  final List<({DateTime day, int seconds})> trend;

  const BoReadingSummary({
    this.detailed = false,
    this.activeDays = 0,
    this.readingSeconds = 0,
    this.sessions = 0,
    this.booksStarted = 0,
    this.booksCompleted = 0,
    this.formats = const [],
    this.genres = const [],
    this.sources = const [],
    this.trend = const [],
  });

  bool get hasReading =>
      sessions > 0 ||
      booksStarted > 0 ||
      booksCompleted > 0 ||
      formats.isNotEmpty ||
      genres.isNotEmpty ||
      sources.isNotEmpty;

  factory BoReadingSummary.fromJson(Map<String, dynamic> j) => BoReadingSummary(
        detailed: j['sharingLevel'] == 'detailed',
        activeDays: _int(j['activeDays']),
        readingSeconds: _int(j['readingSeconds']),
        sessions: _int(j['sessionsCount']),
        booksStarted: _int(j['booksStarted']),
        booksCompleted: _int(j['booksCompleted']),
        formats: BoReadingTime.listFrom(j['formatDistribution']),
        genres: BoReadingTime.listFrom(j['genreDistribution']),
        sources: BoReadingTime.listFrom(j['sourceCoverage'], key: 'source'),
        trend: [
          for (final p in (j['trend'] as List? ?? const []).whereType<Map<String, dynamic>>())
            if (DateTime.tryParse('${p['day']}') case final day?) (day: day, seconds: _int(p['readingSeconds'])),
        ],
      );
}

class BoReadingBook {
  final String? title;
  final int seconds;
  final DateTime? lastRead;
  const BoReadingBook({this.title, this.seconds = 0, this.lastRead});

  static List<BoReadingBook> listFrom(Object? v) => [
        for (final b in (v is List ? v : const []).whereType<Map<String, dynamic>>())
          BoReadingBook(
            title: b['title'] as String?,
            seconds: _int(b['readingSeconds']),
            lastRead: _date(b['lastReadAt']),
          ),
      ];
}

/// The books and names behind a summary, for someone who shares details.
class BoReadingDetail {
  final List<BoReadingBook> recentBooks;
  final List<BoReadingBook> topBooks;
  final List<BoReadingTime> topAuthors;
  final List<BoReadingTime> topGenres;
  final List<BoReadingTime> topSeries;
  final List<BoReadingTime> topNarrators;

  const BoReadingDetail({
    this.recentBooks = const [],
    this.topBooks = const [],
    this.topAuthors = const [],
    this.topGenres = const [],
    this.topSeries = const [],
    this.topNarrators = const [],
  });

  factory BoReadingDetail.fromJson(Map<String, dynamic> j) => BoReadingDetail(
        recentBooks: BoReadingBook.listFrom(j['recentBooks']),
        topBooks: BoReadingBook.listFrom(j['topBooks']),
        topAuthors: BoReadingTime.listFrom(j['topAuthors']),
        topGenres: BoReadingTime.listFrom(j['topGenres']),
        topSeries: BoReadingTime.listFrom(j['topSeries']),
        topNarrators: BoReadingTime.listFrom(j['topNarrators']),
      );
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
Set<String> _strings(Object? v) => {for (final s in (v is List ? v : const [])) '$s'};

/// One row of the user list.
class BoUser {
  final int id;
  final String username;
  final String name;
  final String? email;
  final bool active;
  final bool isSuperuser;
  final bool isDefaultPassword;
  final DateTime? lockedUntil;
  final DateTime? lastActive;
  final DateTime? createdAt;
  final Set<String> permissions;
  final int libraryAccessCount;
  final String? provisioningMethod;

  const BoUser({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    this.active = true,
    this.isSuperuser = false,
    this.isDefaultPassword = false,
    this.lockedUntil,
    this.lastActive,
    this.createdAt,
    this.permissions = const {},
    this.libraryAccessCount = 0,
    this.provisioningMethod,
  });

  bool get locked => lockedUntil != null && lockedUntil!.isAfter(DateTime.now());

  /// Signed in through a single sign-on provider, so BookOrbit can't send
  /// it a password link.
  bool get external => provisioningMethod != null && provisioningMethod != 'local';

  factory BoUser.fromJson(Map<String, dynamic> j) => BoUser(
        id: _int(j['id']),
        username: '${j['username'] ?? ''}',
        name: '${j['name'] ?? j['username'] ?? ''}',
        email: j['email'] as String?,
        active: j['active'] != false,
        isSuperuser: j['isSuperuser'] == true,
        isDefaultPassword: j['isDefaultPassword'] == true,
        lockedUntil: _date(j['lockedUntil']),
        lastActive: _date(j['lastAuthenticatedAt']),
        createdAt: _date(j['createdAt']),
        permissions: _strings(j['permissions']),
        libraryAccessCount: _int(j['libraryAccessCount']),
        provisioningMethod: j['provisioningMethod'] as String?,
      );
}

class BoUserPage {
  final List<BoUser> users;
  final int total;
  const BoUserPage(this.users, this.total);
}

/// The filters on the user list, as BookOrbit names them.
enum BoUserFilter { all, admins, active, inactive, attention }

class BoUserCounts {
  final int total;
  final int admins;
  final int active;
  final int inactive;
  final int attention;

  const BoUserCounts({this.total = 0, this.admins = 0, this.active = 0, this.inactive = 0, this.attention = 0});

  factory BoUserCounts.fromJson(Map<String, dynamic> j) => BoUserCounts(
        total: _int(j['total']),
        admins: _int(j['admins']),
        active: _int(j['active']),
        inactive: _int(j['inactive']),
        attention: _int(j['attention']),
      );

  int of(BoUserFilter f) => switch (f) {
        BoUserFilter.all => total,
        BoUserFilter.admins => admins,
        BoUserFilter.active => active,
        BoUserFilter.inactive => inactive,
        BoUserFilter.attention => attention,
      };
}

/// A new account, and the link that lets its owner set a password. The link
/// lasts 15 minutes.
class BoCreatedUser {
  final int id;
  final String username;
  final String? resetUrl;
  const BoCreatedUser(this.id, this.username, this.resetUrl);
}

/// A permission group as BookOrbit's own admin page lays them out.
class BoPermissionGroup {
  final String key;
  final List<String> permissions;
  const BoPermissionGroup(this.key, this.permissions);
}

/// Podcasts are switched off in BookOrbit, so their permissions are left out.
const boPermissionGroups = [
  BoPermissionGroup('library', [
    'library_download',
    'library_upload',
    'library_edit_metadata',
    'library_delete_books',
    'library_merge_books',
    'library_generate_read_aloud',
  ]),
  BoPermissionGroup('requests', [
    'book_request_access',
    'book_request_auto_approve',
    'book_request_self_fulfill',
    'manage_book_requests',
  ]),
  BoPermissionGroup('devices', ['kobo_sync', 'koreader_sync', 'opds_access']),
  BoPermissionGroup('integrations', ['hardcover_sync', 'readwise_sync', 'storygraph_sync', 'api_keys']),
  BoPermissionGroup('dock', ['book_dock_access', 'manage_book_dock']),
  BoPermissionGroup('email', ['email_send', 'notification_access', 'manage_email']),
  BoPermissionGroup('admin', [
    'manage_libraries',
    'manage_metadata_config',
    'manage_icons',
    'manage_users',
    'view_user_activity',
    'view_audit_log',
    'manage_app_settings',
  ]),
];

/// BookOrbit's "Standard" preset.
const boStandardPermissions = {
  'library_download',
  'kobo_sync',
  'koreader_sync',
  'hardcover_sync',
  'readwise_sync',
  'storygraph_sync',
  'opds_access',
};

Set<String> get boAllPermissions => {for (final g in boPermissionGroups) ...g.permissions};

/// Requests that need others, added the way BookOrbit adds them itself.
Set<String> boWithRequiredPermissions(Set<String> picked) {
  const needsAccess = {'book_request_auto_approve', 'book_request_self_fulfill', 'manage_book_requests'};
  return {...picked, if (picked.any(needsAccess.contains)) 'book_request_access'};
}

class BoScan {
  final String status;
  final String? triggeredBy;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int added;
  final int updated;
  final int missing;
  final String? error;

  const BoScan({
    required this.status,
    this.triggeredBy,
    this.startedAt,
    this.completedAt,
    this.added = 0,
    this.updated = 0,
    this.missing = 0,
    this.error,
  });

  bool get running => status == 'running';
  bool get failed => status == 'failed';

  static BoScan? fromJson(Object? j) {
    if (j is! Map) return null;
    return BoScan(
      status: '${j['status'] ?? ''}',
      triggeredBy: j['triggeredBy'] as String?,
      startedAt: _date(j['startedAt']),
      completedAt: _date(j['completedAt']),
      added: _int(j['addedCount']),
      updated: _int(j['updatedCount']),
      missing: _int(j['missingCount']),
      error: j['errorMessage'] as String?,
    );
  }
}

class BoLibrary {
  final int id;
  final String name;
  final String icon;
  final String type;
  final int displayOrder;
  final String coverAspectRatio;
  final bool watch;
  final String? autoScanCron;
  final String organizationMode;
  final List<String> folders;
  final int? bookCount;

  const BoLibrary({
    required this.id,
    required this.name,
    this.icon = 'Library',
    this.type = 'books',
    this.displayOrder = 0,
    this.coverAspectRatio = '2/3',
    this.watch = false,
    this.autoScanCron,
    this.organizationMode = 'book_per_folder',
    this.folders = const [],
    this.bookCount,
  });

  factory BoLibrary.fromJson(Map<String, dynamic> j) => BoLibrary(
        id: _int(j['id']),
        name: '${j['name'] ?? ''}',
        icon: (j['icon'] as String?) ?? 'Library',
        type: (j['type'] as String?) ?? 'books',
        displayOrder: _int(j['displayOrder']),
        coverAspectRatio: (j['coverAspectRatio'] as String?) ?? '2/3',
        watch: j['watch'] == true,
        autoScanCron: j['autoScanCronExpression'] as String?,
        organizationMode: (j['organizationMode'] as String?) ?? 'book_per_folder',
        folders: [
          for (final f in (j['folders'] as List? ?? const []))
            if (f is Map && f['role'] != 'local') '${f['path']}' else if (f is String) f,
        ],
        bookCount: j['bookCount'] is num ? (j['bookCount'] as num).toInt() : null,
      );
}

class BoLibraryOverview {
  final int libraryId;
  final int totalBooks;
  final int totalSizeBytes;
  final BoScan? lastScan;

  const BoLibraryOverview(this.libraryId, this.totalBooks, this.totalSizeBytes, this.lastScan);

  factory BoLibraryOverview.fromJson(Map<String, dynamic> j) => BoLibraryOverview(
        _int(j['libraryId']),
        _int(j['totalBooks']),
        _int(j['totalSizeBytes']),
        BoScan.fromJson(j['lastScan']),
      );
}

/// One person's access to a library: viewer, editor or owner.
class BoLibraryAccess {
  final int userId;
  final String username;
  final String name;
  final String level;

  const BoLibraryAccess(this.userId, this.username, this.name, this.level);

  factory BoLibraryAccess.fromJson(Map<String, dynamic> j) => BoLibraryAccess(
        _int(j['userId']),
        '${j['username'] ?? ''}',
        '${j['name'] ?? j['username'] ?? ''}',
        '${j['accessLevel'] ?? 'viewer'}',
      );
}

const boAccessLevels = ['viewer', 'editor', 'owner'];

/// Someone who can be given access to a library: active, and not an admin
/// (admins see every library).
class BoAssignableUser {
  final int id;
  final String username;
  final String name;
  const BoAssignableUser(this.id, this.username, this.name);
}

/// A folder in the server's library area.
class BoFolder {
  final String name;
  final String path;
  const BoFolder(this.name, this.path);
}

/// What a folder would bring into a library, before it is added.
class BoFolderCheck {
  final String path;
  final bool accessible;
  final int fileCount;
  final String? overlapLibrary;
  final String? error;

  const BoFolderCheck(this.path, this.accessible, this.fileCount, this.overlapLibrary, this.error);

  factory BoFolderCheck.fromJson(Map<String, dynamic> j) => BoFolderCheck(
        '${j['path'] ?? ''}',
        j['accessible'] == true,
        _int(j['fileCount']),
        j['overlapLibrary'] is Map ? '${(j['overlapLibrary'] as Map)['name'] ?? ''}' : j['overlapLibrary'] as String?,
        j['error'] as String?,
      );
}

/// Library icons offered on the phone: BookOrbit's icon names (Lucide), a
/// small common set. Others a library already has are kept as they are.
const boLibraryIcons = [
  'Library',
  'BookOpen',
  'Book',
  'BookMarked',
  'Headphones',
  'GraduationCap',
  'Baby',
  'Sparkles',
  'Rocket',
  'Ghost',
  'Heart',
  'Swords',
];

/// Ready-made scan schedules, as cron. The time is the server's.
const boScanSchedules = {
  'daily': '0 3 * * *',
  'weekly': '0 3 * * 0',
};

/// How BookOrbit handles book requests on its own: what it downloads
/// without being asked, how it checks a download, and where it files one.
/// Release profiles (the ranked edition lists) stay on the web.
class BoRequestSettings {
  static const minGrabScore = 50;
  static const maxGrabAttempts = 10;
  static const maxSearchIntervalHours = 168;
  static const maxSearchAgeDays = 365;

  final bool autoGrab;
  final int autoGrabMinScore;
  final bool autoRetry;
  final int maxAttempts;
  final bool autoSearch;
  final int searchIntervalHours;
  final int searchMaxAgeDays;
  final bool verification;
  final int verificationThreshold;

  /// 'all' keeps every format a download holds, 'preferred' only the best.
  final String importFormats;
  final int? ebookLibraryId;
  final int? ebookFolderId;
  final int? audiobookLibraryId;
  final int? audiobookFolderId;

  const BoRequestSettings({
    this.autoGrab = false,
    this.autoGrabMinScore = 80,
    this.autoRetry = true,
    this.maxAttempts = 3,
    this.autoSearch = false,
    this.searchIntervalHours = 24,
    this.searchMaxAgeDays = 60,
    this.verification = true,
    this.verificationThreshold = 70,
    this.importFormats = 'all',
    this.ebookLibraryId,
    this.ebookFolderId,
    this.audiobookLibraryId,
    this.audiobookFolderId,
  });

  factory BoRequestSettings.fromJson(Map<String, dynamic> j) {
    int? at(String kind, String key) {
      final d = (j['destinations'] as Map?)?[kind];
      return d is Map ? (d[key] as num?)?.toInt() : null;
    }

    return BoRequestSettings(
      autoGrab: j['autoGrabEnabled'] == true,
      autoGrabMinScore: (j['autoGrabMinScore'] as num?)?.toInt() ?? 80,
      autoRetry: j['autoRetryEnabled'] != false,
      maxAttempts: (j['maxAutoGrabAttempts'] as num?)?.toInt() ?? 3,
      autoSearch: j['autoSearchEnabled'] == true,
      searchIntervalHours: (j['autoSearchIntervalHours'] as num?)?.toInt() ?? 24,
      searchMaxAgeDays: (j['autoSearchMaxAgeDays'] as num?)?.toInt() ?? 60,
      verification: j['verificationEnabled'] != false,
      verificationThreshold: (j['verificationThreshold'] as num?)?.toInt() ?? 70,
      importFormats: j['importFormats'] == 'preferred' ? 'preferred' : 'all',
      ebookLibraryId: at('ebook', 'libraryId'),
      ebookFolderId: at('ebook', 'folderId'),
      audiobookLibraryId: at('audiobook', 'libraryId'),
      audiobookFolderId: at('audiobook', 'folderId'),
    );
  }

  BoRequestSettings copyWith({
    bool? autoGrab,
    int? autoGrabMinScore,
    bool? autoRetry,
    int? maxAttempts,
    bool? autoSearch,
    int? searchIntervalHours,
    int? searchMaxAgeDays,
    bool? verification,
    int? verificationThreshold,
    String? importFormats,
    ({int? libraryId, int? folderId})? ebook,
    ({int? libraryId, int? folderId})? audiobook,
  }) =>
      BoRequestSettings(
        autoGrab: autoGrab ?? this.autoGrab,
        autoGrabMinScore: autoGrabMinScore ?? this.autoGrabMinScore,
        autoRetry: autoRetry ?? this.autoRetry,
        maxAttempts: maxAttempts ?? this.maxAttempts,
        autoSearch: autoSearch ?? this.autoSearch,
        searchIntervalHours: searchIntervalHours ?? this.searchIntervalHours,
        searchMaxAgeDays: searchMaxAgeDays ?? this.searchMaxAgeDays,
        verification: verification ?? this.verification,
        verificationThreshold: verificationThreshold ?? this.verificationThreshold,
        importFormats: importFormats ?? this.importFormats,
        ebookLibraryId: ebook == null ? ebookLibraryId : ebook.libraryId,
        ebookFolderId: ebook == null ? ebookFolderId : ebook.folderId,
        audiobookLibraryId: audiobook == null ? audiobookLibraryId : audiobook.libraryId,
        audiobookFolderId: audiobook == null ? audiobookFolderId : audiobook.folderId,
      );

  /// Only what differs from [saved], which is all the server needs.
  Map<String, dynamic> changesFrom(BoRequestSettings saved) {
    final ebookMoved = ebookLibraryId != saved.ebookLibraryId || ebookFolderId != saved.ebookFolderId;
    final audiobookMoved =
        audiobookLibraryId != saved.audiobookLibraryId || audiobookFolderId != saved.audiobookFolderId;
    return {
      if (autoGrab != saved.autoGrab) 'autoGrabEnabled': autoGrab,
      if (autoGrabMinScore != saved.autoGrabMinScore) 'autoGrabMinScore': autoGrabMinScore,
      if (autoRetry != saved.autoRetry) 'autoRetryEnabled': autoRetry,
      if (maxAttempts != saved.maxAttempts) 'maxAutoGrabAttempts': maxAttempts,
      if (autoSearch != saved.autoSearch) 'autoSearchEnabled': autoSearch,
      if (searchIntervalHours != saved.searchIntervalHours) 'autoSearchIntervalHours': searchIntervalHours,
      if (searchMaxAgeDays != saved.searchMaxAgeDays) 'autoSearchMaxAgeDays': searchMaxAgeDays,
      if (verification != saved.verification) 'verificationEnabled': verification,
      if (verificationThreshold != saved.verificationThreshold) 'verificationThreshold': verificationThreshold,
      if (importFormats != saved.importFormats) 'importFormats': importFormats,
      if (ebookMoved || audiobookMoved)
        'destinations': {
          if (ebookMoved) 'ebook': {'libraryId': ebookLibraryId, 'folderId': ebookFolderId},
          if (audiobookMoved) 'audiobook': {'libraryId': audiobookLibraryId, 'folderId': audiobookFolderId},
        },
    };
  }
}

/// How the Book Dock treats a file that lands in it.
class BoDockSettings {
  static const minFileThreshold = 50;

  /// Where the dock folder sits on the server. Read only.
  final String path;
  final bool lookUpDetails;
  final bool autoFile;
  final int autoFileThreshold;
  final int? libraryId;
  final int? folderId;

  /// 'safe_merge', 'fetched_only' or 'embedded_only'.
  final String detailsMode;

  /// Null on a server from before these two.
  final bool? autoJoin;
  final bool? keepOriginal;

  const BoDockSettings({
    this.path = '',
    this.lookUpDetails = true,
    this.autoFile = false,
    this.autoFileThreshold = 85,
    this.libraryId,
    this.folderId,
    this.detailsMode = 'safe_merge',
    this.autoJoin,
    this.keepOriginal,
  });

  factory BoDockSettings.fromJson(Map<String, dynamic> j) => BoDockSettings(
        path: '${j['bookDockPath'] ?? ''}',
        lookUpDetails: j['autoFetchMetadata'] != false,
        autoFile: j['autoFinalizeEnabled'] == true,
        autoFileThreshold: (j['autoFinalizeThreshold'] as num?)?.toInt() ?? 85,
        libraryId: (j['autoFinalizeLibraryId'] as num?)?.toInt(),
        folderId: (j['autoFinalizeFolderId'] as num?)?.toInt(),
        detailsMode: '${j['autoFinalizeMetadataMode'] ?? 'safe_merge'}',
        autoJoin: j['unsortedAutoJoin'] as bool?,
        keepOriginal: j['unsortedKeepOriginal'] as bool?,
      );

  BoDockSettings copyWith({
    bool? lookUpDetails,
    bool? autoFile,
    int? autoFileThreshold,
    ({int? libraryId, int? folderId})? destination,
    String? detailsMode,
    bool? autoJoin,
    bool? keepOriginal,
  }) =>
      BoDockSettings(
        path: path,
        lookUpDetails: lookUpDetails ?? this.lookUpDetails,
        autoFile: autoFile ?? this.autoFile,
        autoFileThreshold: autoFileThreshold ?? this.autoFileThreshold,
        libraryId: destination == null ? libraryId : destination.libraryId,
        folderId: destination == null ? folderId : destination.folderId,
        detailsMode: detailsMode ?? this.detailsMode,
        autoJoin: autoJoin ?? this.autoJoin,
        keepOriginal: keepOriginal ?? this.keepOriginal,
      );

  /// The server takes the whole set at once.
  Map<String, dynamic> toJson() => {
        'autoFetchMetadata': lookUpDetails,
        'autoFinalizeEnabled': autoFile,
        'autoFinalizeThreshold': autoFileThreshold,
        'autoFinalizeLibraryId': libraryId,
        'autoFinalizeFolderId': folderId,
        'autoFinalizeMetadataMode': detailsMode,
        'unsortedAutoJoin': ?autoJoin,
        'unsortedKeepOriginal': ?keepOriginal,
      };

  bool sameAs(BoDockSettings o) =>
      lookUpDetails == o.lookUpDetails &&
      autoFile == o.autoFile &&
      autoFileThreshold == o.autoFileThreshold &&
      libraryId == o.libraryId &&
      folderId == o.folderId &&
      detailsMode == o.detailsMode &&
      autoJoin == o.autoJoin &&
      keepOriginal == o.keepOriginal;
}
