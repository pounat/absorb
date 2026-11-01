import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/bookorbit_notification_socket.dart';
import '../services/server_notifications.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/book_detail_sheet.dart' show showBookDetailSheet;
import '../widgets/overlay_toast.dart';
import 'achievements_screen.dart';
import 'book_requests_screen.dart';

/// A notification that just came in, shown as a toast wherever the app is.
/// Tapping it opens the list. The list itself shows new ones as they come.
void showIncomingNotificationToast(ServerNotification n) {
  if (ServerNotificationsScreen._open > 0) return;
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;
  showNavigatorOverlayToast(
    navigator,
    n.message == null ? n.title : '${n.title}: ${n.message}',
    icon: notificationCategoryIcon(n.category),
    onTap: () => navigator.push(MaterialPageRoute(builder: (_) => const ServerNotificationsScreen())),
  );
}

/// The notifications BookOrbit keeps for the signed-in user, like the bell
/// in its web app: read, dismiss, clear, and pick which ones it sends.
class ServerNotificationsScreen extends StatefulWidget {
  const ServerNotificationsScreen({super.key});

  static int _open = 0;

  static Future<void> open(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ServerNotificationsScreen()),
      );

  @override
  State<ServerNotificationsScreen> createState() => _ServerNotificationsScreenState();
}

class _ServerNotificationsScreenState extends State<ServerNotificationsScreen> {
  static const _pageSize = 30;

  final _scroll = ScrollController();
  List<ServerNotification> _items = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  final _live = <StreamSubscription<ServerNotification>>[];

  ApiService? get _api => context.read<AuthProvider>().apiService;

  @override
  void initState() {
    super.initState();
    ServerNotificationsScreen._open++;
    _scroll.addListener(_maybeLoadMore);
    final feed = BookOrbitNotificationSocket.instance;
    _live
      ..add(feed.incoming.listen((n) => _arrived(n, isNew: true)))
      ..add(feed.updated.listen((n) => _arrived(n, isNew: false)));
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    ServerNotificationsScreen._open--;
    for (final s in _live) {
      s.cancel();
    }
    _scroll.dispose();
    super.dispose();
  }

  /// A notification from the live feed goes to the top, replacing its old
  /// row when it is one that happened again.
  void _arrived(ServerNotification n, {required bool isNew}) {
    if (!mounted) return;
    final had = _items.any((i) => i.id == n.id);
    setState(() {
      _items = [n, ..._items.where((i) => i.id != n.id)];
      if (!had && isNew) _total++;
    });
  }

  Future<void> _reload() async {
    final api = _api;
    if (api == null) return;
    setState(() => _loading = true);
    final page = await api.serverNotifications(limit: _pageSize);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = page == null;
      if (page != null) {
        _items = page.items;
        _total = page.total;
      }
    });
  }

  void _maybeLoadMore() {
    if (_loadingMore || _items.length >= _total) return;
    if (_scroll.position.extentAfter > 400) return;
    _loadMore();
  }

  Future<void> _loadMore() async {
    final api = _api;
    if (api == null) return;
    _loadingMore = true;
    final page = await api.serverNotifications(limit: _pageSize, offset: _items.length);
    _loadingMore = false;
    if (!mounted || page == null) return;
    final seen = {for (final n in _items) n.id};
    setState(() {
      _items = [..._items, ...page.items.where((n) => !seen.contains(n.id))];
      _total = page.total;
    });
  }

  void _failedToast() {
    if (!mounted) return;
    showOverlayToast(context, AppLocalizations.of(context)!.boNotificationsUpdateFailed,
        icon: Icons.error_outline_rounded);
  }

  Future<void> _open(ServerNotification n) async {
    final api = _api;
    if (api == null) return;
    if (!n.read) {
      setState(() => _items = [for (final i in _items) i.id == n.id ? i.copyWith(read: true) : i]);
      if (!await api.markNotificationRead(n.id)) {
        if (!mounted) return;
        setState(() => _items = [for (final i in _items) i.id == n.id ? i.copyWith(read: false) : i]);
        _failedToast();
        return;
      }
    }
    if (!mounted) return;
    final link = n.link;
    switch (link?.kind) {
      case NotificationLinkKind.book:
        showBookDetailSheet(context, link!.bookId!);
      case NotificationLinkKind.requests:
        BookRequestsScreen.open(context, openList: true);
      case NotificationLinkKind.achievements:
        AchievementsScreen.open(context);
      case null:
        break;
    }
  }

  Future<void> _dismiss(ServerNotification n) async {
    final api = _api;
    if (api == null) return;
    final index = _items.indexWhere((i) => i.id == n.id);
    if (index < 0) return;
    setState(() {
      _items = [..._items]..removeAt(index);
      _total = (_total - 1).clamp(0, 1 << 30);
    });
    if (await api.dismissNotification(n.id)) return;
    if (!mounted) return;
    setState(() {
      _items = [..._items]..insert(index.clamp(0, _items.length), n);
      _total++;
    });
    _failedToast();
  }

  Future<void> _markAllRead() async {
    final api = _api;
    if (api == null) return;
    final before = _items;
    setState(() => _items = [for (final i in _items) i.copyWith(read: true)]);
    if (await api.markAllNotificationsRead()) return;
    if (!mounted) return;
    setState(() => _items = before);
    _failedToast();
  }

  Future<void> _clearAll() async {
    final api = _api;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.boNotificationsClearTitle),
        content: Text(l.boNotificationsClearBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.boNotificationsClearAll),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final before = (_items, _total);
    setState(() {
      _items = [];
      _total = 0;
    });
    if (await api.clearNotifications()) return;
    if (!mounted) return;
    setState(() {
      _items = before.$1;
      _total = before.$2;
    });
    _failedToast();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final hasUnread = _items.any((n) => !n.read);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.notifications, padding: EdgeInsets.zero)),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
                onSelected: (v) {
                  switch (v) {
                    case 'read':
                      _markAllRead();
                    case 'clear':
                      _clearAll();
                    case 'settings':
                      NotificationSettingsSheet.show(context);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'read', enabled: hasUnread, child: Text(l.boNotificationsMarkAllRead)),
                  PopupMenuItem(value: 'clear', enabled: _items.isNotEmpty, child: Text(l.boNotificationsClearAll)),
                  PopupMenuItem(value: 'settings', child: Text(l.boNotificationsSettings)),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: _items.isEmpty && !_loading
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Icon(_failed ? Icons.cloud_off_rounded : Icons.notifications_none_rounded,
                          size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(_failed ? l.boNotificationsLoadFailed : l.boNotificationsEmpty,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                      ),
                    ])
                  : ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _items.length + (_items.length < _total ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                          );
                        }
                        final n = _items[i];
                        return Dismissible(
                          key: ValueKey('notification-${n.id}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _dismiss(n),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                                color: cs.errorContainer, borderRadius: BorderRadius.circular(16)),
                            child: Icon(Icons.delete_outline_rounded, color: cs.onErrorContainer),
                          ),
                          child: _NotificationTile(notification: n, onTap: () => _open(n)),
                        );
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

IconData notificationCategoryIcon(String? category) => switch (category) {
      'scanning' => Icons.document_scanner_rounded,
      'metadata' => Icons.sell_rounded,
      'authorEnrichment' => Icons.people_alt_rounded,
      'fileWriteBack' => Icons.save_alt_rounded,
      'fileRename' || 'bulkRename' => Icons.drive_file_rename_outline_rounded,
      'migration' => Icons.sync_alt_rounded,
      'bookDock' => Icons.move_to_inbox_rounded,
      'bookRequests' => Icons.library_add_rounded,
      'email' => Icons.mail_outline_rounded,
      'achievements' => Icons.emoji_events_rounded,
      'podcasts' => Icons.podcasts_rounded,
      'readAloud' => Icons.record_voice_over_rounded,
      _ => Icons.notifications_rounded,
    };

String notificationTimeAgo(AppLocalizations l, DateTime? when, String locale) {
  if (when == null) return '';
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return l.justNow;
  if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l.daysAgo(diff.inDays);
  return DateFormat.yMMMd(locale).format(when);
}

class _NotificationTile extends StatelessWidget {
  final ServerNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final n = notification;
    final color = switch (n.severity) {
      NotificationSeverity.success => cs.primary,
      NotificationSeverity.warning => Colors.amber.shade700,
      NotificationSeverity.error => cs.error,
    };
    final when = notificationTimeAgo(l, n.when, Localizations.localeOf(context).toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: n.read ? cs.surfaceContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(notificationCategoryIcon(n.category), size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.title,
                      style: tt.bodyMedium?.copyWith(fontWeight: n.read ? FontWeight.w500 : FontWeight.w700)),
                  if (n.message != null) ...[
                    const SizedBox(height: 2),
                    Text(n.message!,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    [when, if (n.count > 1) l.boNotificationsOccurrences(n.count)].where((s) => s.isNotEmpty).join('  ·  '),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ]),
              ),
              if (!n.read)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Which notifications BookOrbit keeps for this account, by category, the
/// way its web app's notification settings set them.
class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => const NotificationSettingsSheet(),
      );

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  Map<String, String>? _levels;
  bool _requests = false;
  bool _readAlongs = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final (levels, access, readAlongs) = await (
      api.notificationLevels(),
      api.bookRequestAccess(),
      api is BookOrbitApiService ? api.canMakeReadAlongs() : Future.value(false),
    ).wait;
    if (!mounted) return;
    setState(() {
      _levels = levels;
      _requests = access.canRequest;
      _readAlongs = readAlongs;
      _failed = levels == null;
    });
  }

  Future<void> _set(String category, String level) async {
    final api = context.read<AuthProvider>().apiService;
    final levels = _levels;
    if (api == null || levels == null) return;
    final before = levels[category];
    setState(() => _levels = {...levels, category: level});
    if (await api.setNotificationLevels({category: level})) return;
    if (!mounted) return;
    setState(() => _levels = {..._levels!, category: ?before});
    showOverlayToast(context, AppLocalizations.of(context)!.boNotificationsSaveFailed,
        icon: Icons.error_outline_rounded);
  }

  String _groupLabel(AppLocalizations l, String group) => switch (group) {
        'library' => l.boNotificationGroupLibrary,
        'files' => l.boNotificationGroupFiles,
        'integrations' => l.boNotificationGroupIntegrations,
        _ => l.boNotificationGroupPersonal,
      };

  (String, String) _categoryText(AppLocalizations l, String category) => switch (category) {
        'scanning' => (l.boNotifyScanning, l.boNotifyScanningDesc),
        'metadata' => (l.boNotifyMetadata, l.boNotifyMetadataDesc),
        'authorEnrichment' => (l.boNotifyAuthorEnrichment, l.boNotifyAuthorEnrichmentDesc),
        'fileWriteBack' => (l.boNotifyFileWriteBack, l.boNotifyFileWriteBackDesc),
        'fileRename' => (l.boNotifyFileRename, l.boNotifyFileRenameDesc),
        'bulkRename' => (l.boNotifyBulkRename, l.boNotifyBulkRenameDesc),
        'migration' => (l.boNotifyMigration, l.boNotifyMigrationDesc),
        'bookDock' => (l.boNotifyBookDock, l.boNotifyBookDockDesc),
        'bookRequests' => (l.boNotifyBookRequests, l.boNotifyBookRequestsDesc),
        'email' => (l.boNotifyEmail, l.boNotifyEmailDesc),
        'achievements' => (l.boNotifyAchievements, l.boNotifyAchievementsDesc),
        'readAloud' => (l.boNotifyReadAlong, l.boNotifyReadAlongDesc),
        _ => (category, ''),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final levels = _levels;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.boNotificationsSettings, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(l.boNotificationsSettingsIntro, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(l.boNotificationsProblemsHint,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
          if (levels == null && !_failed)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          if (_failed)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(l.boNotificationsLoadFailed, style: tt.bodyMedium)),
            ),
          if (levels != null)
            for (final MapEntry(key: group, value: categories) in notificationCategoryGroups.entries) ...[
              const SizedBox(height: 20),
              Text(_groupLabel(l, group).toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              for (final category in categories)
                if ((category != 'bookRequests' || _requests) && (category != 'readAloud' || _readAlongs))
                  _categoryRow(cs, tt, l, category, levels[category] ?? notificationLevelAll),
            ],
        ],
      ),
    );
  }

  Widget _categoryRow(ColorScheme cs, TextTheme tt, AppLocalizations l, String category, String level) {
    final (label, description) = _categoryText(l, category);
    final problems = notificationCategoryHasProblems(category);
    final options = [
      notificationLevelOff,
      if (problems) notificationLevelProblems,
      notificationLevelAll,
    ];
    final shown = options.contains(level) ? level : notificationLevelAll;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(notificationCategoryIcon(category), size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ]),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: Text(description, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 8),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              for (final o in options)
                ButtonSegment(
                  value: o,
                  label: Text(switch (o) {
                    notificationLevelOff => l.boNotificationLevelOff,
                    notificationLevelProblems => l.boNotificationLevelProblems,
                    _ => l.boNotificationLevelAll,
                  }),
                ),
            ],
            selected: {shown},
            onSelectionChanged: (s) => _set(category, s.first),
          ),
        ),
      ]),
    );
  }
}
