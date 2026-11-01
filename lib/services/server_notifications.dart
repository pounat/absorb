/// BookOrbit notifications: the rows its bell lists for the signed-in user,
/// and the categories its notification settings switch. Follows BookOrbit's
/// shared types (packages/types/src/notification.ts).
library;

enum NotificationSeverity { success, warning, error }

const _s = NotificationSeverity.success;
const _w = NotificationSeverity.warning;
const _e = NotificationSeverity.error;

/// Each type's category and how it went, as BookOrbit defines them.
const Map<String, (String, NotificationSeverity)> _typeMeta = {
  'scan_completed': ('scanning', _s),
  'scan_failed': ('scanning', _e),
  'books_unavailable': ('scanning', _w),
  'books_restored': ('scanning', _s),
  'metadata_fetch_completed': ('metadata', _s),
  'metadata_fetch_failed': ('metadata', _w),
  'book_dock_finalized': ('bookDock', _s),
  'book_dock_finalized_with_errors': ('bookDock', _w),
  'book_request_submitted': ('bookRequests', _s),
  'book_request_approved': ('bookRequests', _s),
  'book_request_rejected': ('bookRequests', _w),
  'book_request_available': ('bookRequests', _s),
  'book_request_needs_review': ('bookRequests', _w),
  'book_request_needs_release': ('bookRequests', _w),
  'book_request_failed': ('bookRequests', _e),
  'author_enrichment_completed': ('authorEnrichment', _s),
  'author_enrichment_failed': ('authorEnrichment', _w),
  'email_sent': ('email', _s),
  'email_failed': ('email', _e),
  'migration_completed': ('migration', _s),
  'migration_failed': ('migration', _e),
  'file_write_back_completed': ('fileWriteBack', _s),
  'file_write_back_failed': ('fileWriteBack', _e),
  'file_rename_completed': ('fileRename', _s),
  'file_rename_failed': ('fileRename', _e),
  'bulk_rename_completed': ('bulkRename', _s),
  'bulk_rename_failed': ('bulkRename', _w),
  'achievement_unlocked': ('achievements', _s),
  'read_aloud_ready': ('readAloud', _s),
  'read_aloud_needs_review': ('readAloud', _w),
  'read_aloud_failed': ('readAloud', _e),
  'read_aloud_review_expiring': ('readAloud', _w),
  'podcast_episode_published': ('podcasts', _s),
  'podcast_feed_unhealthy': ('podcasts', _w),
  'podcast_download_failed': ('podcasts', _e),
};

/// The categories a user can switch, in BookOrbit's groups. Podcasts are
/// left out the way BookOrbit leaves them out while its podcasts are off.
const notificationCategoryGroups = <String, List<String>>{
  'library': ['scanning', 'metadata', 'authorEnrichment'],
  'files': ['fileWriteBack', 'fileRename', 'bulkRename', 'readAloud', 'migration'],
  'integrations': ['bookDock', 'bookRequests', 'email'],
  'personal': ['achievements'],
};

const notificationLevelOff = 'off';
const notificationLevelProblems = 'problems';
const notificationLevelAll = 'all';

/// A category whose types all succeed can only be off or on: "problems"
/// would mean the same as off there.
bool notificationCategoryHasProblems(String category) => _typeMeta.values
    .any((m) => m.$1 == category && m.$2 != NotificationSeverity.success);

/// A stored level. Older accounts keep true or false.
String resolveNotificationLevel(Object? raw) {
  if (raw == false) return notificationLevelOff;
  if (raw == notificationLevelOff || raw == notificationLevelProblems || raw == notificationLevelAll) {
    return raw as String;
  }
  return notificationLevelAll;
}

/// Where a notification's link goes, among the places Absorb can open.
enum NotificationLinkKind { book, requests, achievements }

class NotificationLink {
  final NotificationLinkKind kind;
  final String? bookId;
  const NotificationLink(this.kind, [this.bookId]);

  static NotificationLink? parse(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    if (parts[0] == 'book' && parts.length > 1 && int.tryParse(parts[1]) != null) {
      return NotificationLink(NotificationLinkKind.book, parts[1]);
    }
    if (parts[0] == 'requests') return const NotificationLink(NotificationLinkKind.requests);
    if (parts[0] == 'statistics' && uri.queryParameters['tab'] == 'achievements') {
      return const NotificationLink(NotificationLinkKind.achievements);
    }
    return null;
  }
}

class ServerNotification {
  final int id;
  final String type;
  final String title;
  final String? message;
  final String? actionUrl;
  final Map<String, dynamic> meta;
  final bool read;

  /// How many times it happened, collapsed into this one row.
  final int count;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServerNotification({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    this.actionUrl,
    this.meta = const {},
    this.read = false,
    this.count = 1,
    this.createdAt,
    this.updatedAt,
  });

  NotificationSeverity get severity =>
      _typeMeta[type]?.$2 ??
      (type.endsWith('_failed') ? NotificationSeverity.error : NotificationSeverity.success);

  String? get category => _typeMeta[type]?.$1;

  NotificationLink? get link =>
      NotificationLink.parse(actionUrl) ??
      (type == 'achievement_unlocked' ? const NotificationLink(NotificationLinkKind.achievements) : null);

  /// The time it last happened.
  DateTime? get when => updatedAt ?? createdAt;

  ServerNotification copyWith({bool? read}) => ServerNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        actionUrl: actionUrl,
        meta: meta,
        read: read ?? this.read,
        count: count,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static ServerNotification? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = (raw['id'] as num?)?.toInt();
    if (id == null) return null;
    final message = raw['message'];
    final url = raw['actionUrl'];
    return ServerNotification(
      id: id,
      type: '${raw['type'] ?? ''}',
      title: '${raw['title'] ?? ''}',
      message: message is String && message.trim().isNotEmpty ? message : null,
      actionUrl: url is String && url.isNotEmpty ? url : null,
      meta: raw['meta'] is Map ? Map<String, dynamic>.from(raw['meta'] as Map) : const {},
      read: raw['read'] == true,
      count: (raw['count'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse('${raw['createdAt'] ?? ''}')?.toLocal(),
      updatedAt: DateTime.tryParse('${raw['updatedAt'] ?? ''}')?.toLocal(),
    );
  }
}
