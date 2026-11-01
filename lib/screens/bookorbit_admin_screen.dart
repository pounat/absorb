import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/bookorbit_admin.dart';
import '../widgets/absorb_page_header.dart';
import '../widgets/overlay_toast.dart';
import 'bookorbit_email_screen.dart';
import 'bookorbit_libraries_screen.dart';
import 'bookorbit_users_screen.dart';

/// BookOrbit server administration: users, libraries and mail servers.
class BookOrbitAdminScreen extends StatefulWidget {
  const BookOrbitAdminScreen({super.key});

  @override
  State<BookOrbitAdminScreen> createState() => _BookOrbitAdminScreenState();
}

class _BookOrbitAdminScreenState extends State<BookOrbitAdminScreen> {
  int? _users;
  int? _libraries;
  int? _servers;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    final access = auth.bookOrbitAdmin;
    if (api is! BookOrbitApiService || access == null) return;
    try {
      if (access.manageUsers) {
        final counts = await api.adminUserCounts();
        if (mounted) setState(() => _users = counts.total);
      }
      if (access.manageLibraries) {
        final libs = await api.adminLibraries();
        if (mounted) setState(() => _libraries = libs.length);
      }
      if (access.manageEmail) {
        final servers = await api.emailServers();
        if (mounted) setState(() => _servers = servers.length);
      }
    } on BookOrbitAdminError {
      // The counts are only a nicety on the tiles.
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final access = context.watch<AuthProvider>().bookOrbitAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(children: [
              Expanded(child: AbsorbPageHeader(title: l.boAdminTitle, padding: const EdgeInsets.only(left: 4))),
              IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 12),
            if (access?.manageUsers == true)
              _HubTile(
                icon: Icons.people_alt_rounded,
                title: l.boAdminUsers,
                subtitle: _users == null ? null : l.boAdminUserCount(_users!),
                onTap: () => _open(const BookOrbitUsersScreen()),
              ),
            if (access?.manageLibraries == true)
              _HubTile(
                icon: Icons.local_library_rounded,
                title: l.boAdminLibraries,
                subtitle: _libraries == null ? null : l.boAdminLibraryCount(_libraries!),
                onTap: () => _open(const BookOrbitLibrariesScreen()),
              ),
            if (access?.manageEmail == true)
              _HubTile(
                icon: Icons.forward_to_inbox_rounded,
                title: l.boEmailTabServers,
                subtitle: _servers == null ? null : l.boAdminServerCount(_servers!),
                onTap: () => _open(const BookOrbitEmailScreen(initialTab: BoEmailTab.servers)),
              ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _HubTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Icon(icon, color: cs.primary),
          title: Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// The API for the signed-in BookOrbit server, for the admin screens.
BookOrbitApiService? boAdminApi(BuildContext context) {
  final api = context.read<AuthProvider>().apiService;
  return api is BookOrbitApiService ? api : null;
}

/// Shows why an admin request failed, in BookOrbit's words when it gave any.
void showBoAdminError(BuildContext context, Object error) {
  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  final message = error is BookOrbitAdminError
      ? (error.status == 0 ? l.boAdminOffline : (error.message ?? l.boAdminFailed))
      : l.boAdminFailed;
  showOverlayToast(context, message, icon: Icons.error_outline_rounded);
}

String boPermissionGroupLabel(AppLocalizations l, String key) => switch (key) {
      'library' => l.boPermGroupLibrary,
      'requests' => l.boPermGroupRequests,
      'devices' => l.boPermGroupDevices,
      'integrations' => l.boPermGroupIntegrations,
      'dock' => l.boPermGroupDock,
      'email' => l.boPermGroupEmail,
      'admin' => l.boPermGroupAdmin,
      _ => key,
    };

String boPermissionLabel(AppLocalizations l, String permission) => switch (permission) {
      'library_download' => l.boPermLibraryDownload,
      'library_upload' => l.boPermLibraryUpload,
      'library_edit_metadata' => l.boPermLibraryEditMetadata,
      'library_delete_books' => l.boPermLibraryDeleteBooks,
      'book_request_access' => l.boPermBookRequestAccess,
      'book_request_auto_approve' => l.boPermBookRequestAutoApprove,
      'book_request_self_fulfill' => l.boPermBookRequestSelfFulfill,
      'manage_book_requests' => l.boPermManageBookRequests,
      'kobo_sync' => l.boPermKoboSync,
      'koreader_sync' => l.boPermKoreaderSync,
      'opds_access' => l.boPermOpdsAccess,
      'hardcover_sync' => l.boPermHardcoverSync,
      'readwise_sync' => l.boPermReadwiseSync,
      'storygraph_sync' => l.boPermStorygraphSync,
      'book_dock_access' => l.boPermBookDockAccess,
      'manage_book_dock' => l.boPermManageBookDock,
      'email_send' => l.boPermEmailSend,
      'notification_access' => l.boPermNotificationAccess,
      'manage_email' => l.boPermManageEmail,
      'manage_libraries' => l.boPermManageLibraries,
      'manage_metadata_config' => l.boPermManageMetadataConfig,
      'manage_icons' => l.boPermManageIcons,
      'manage_users' => l.boPermManageUsers,
      'view_user_activity' => l.boPermViewUserActivity,
      'view_audit_log' => l.boPermViewAuditLog,
      'manage_app_settings' => l.boPermManageAppSettings,
      _ => permission,
    };

/// A stand-in for BookOrbit's library icon (a Lucide name).
IconData boLibraryIcon(String name) => switch (name) {
      'BookOpen' => Icons.menu_book_rounded,
      'Book' => Icons.book_rounded,
      'BookMarked' => Icons.bookmark_rounded,
      'Headphones' => Icons.headphones_rounded,
      'GraduationCap' => Icons.school_rounded,
      'Baby' => Icons.child_care_rounded,
      'Sparkles' => Icons.auto_awesome_rounded,
      'Rocket' => Icons.rocket_launch_rounded,
      'Ghost' => Icons.blur_on_rounded,
      'Heart' => Icons.favorite_rounded,
      'Swords' => Icons.shield_rounded,
      _ => Icons.local_library_rounded,
    };
