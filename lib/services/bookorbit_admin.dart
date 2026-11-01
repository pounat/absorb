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
  final String userId;

  const BookOrbitAdminAccess({
    required this.isSuperuser,
    required this.manageUsers,
    required this.manageLibraries,
    this.emailSend = false,
    this.manageEmail = false,
    required this.userId,
  });

  bool get any => isSuperuser || manageUsers || manageLibraries || manageEmail;

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
      userId: '${user?['id'] ?? ''}',
    );
  }
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
  BoPermissionGroup('library', ['library_download', 'library_upload', 'library_edit_metadata', 'library_delete_books']),
  BoPermissionGroup('requests', [
    'book_request_access',
    'book_request_auto_approve',
    'book_request_self_fulfill',
    'manage_book_requests',
  ]),
  BoPermissionGroup('devices', ['kobo_sync', 'koreader_sync', 'opds_access']),
  BoPermissionGroup('integrations', ['hardcover_sync', 'readwise_sync', 'storygraph_sync']),
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
