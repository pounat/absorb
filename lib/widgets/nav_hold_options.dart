import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// One choice for what holding a nav tab does. The shell maps ids to the
/// actual actions; the settings dialog only needs ids, icons and labels for
/// its pickers, so the two can't drift apart on what exists.
///
/// Ids are flat strings, including the composite ones (`admin:users`,
/// `scan:<libraryId>`), so a choice is one value in prefs and one value in a
/// dropdown.
class NavHoldOption {
  final String id;
  final IconData icon;

  /// Opens a second sheet of choices rather than doing something itself.
  final bool isFolder;
  const NavHoldOption(this.id, this.icon, {this.isFolder = false});
}

const navHoldOptions = [
  NavHoldOption('search', Icons.search_rounded),
  NavHoldOption('switchLibrary', Icons.swap_horiz_rounded),
  NavHoldOption('bookmarks', Icons.bookmarks_rounded),
  NavHoldOption('downloads', Icons.download_rounded),
  NavHoldOption('sleep', Icons.bedtime_rounded),
  NavHoldOption('eink', Icons.contrast),
  NavHoldOption('playPause', Icons.play_arrow_rounded),
  NavHoldOption('stop', Icons.stop_rounded),
  NavHoldOption('queue', Icons.queue_music_rounded),
  NavHoldOption('offline', Icons.cloud_off_rounded),
  NavHoldOption('readBook', Icons.menu_book_rounded),
  NavHoldOption('bookDetails', Icons.info_outline_rounded),
  NavHoldOption('scanSeries', Icons.travel_explore_rounded),
  NavHoldOption('rmabSearch', Icons.auto_stories_rounded),
  NavHoldOption('rmabRequests', Icons.playlist_add_check_rounded),
  NavHoldOption('rmabWeb', Icons.public_rounded),
  NavHoldOption('admin', Icons.admin_panel_settings_rounded, isFolder: true),
  NavHoldOption('scan', Icons.sync_rounded, isFolder: true),
  NavHoldOption('menu', Icons.apps_rounded),
  NavHoldOption('none', Icons.block_rounded),
];

/// Pages inside the Admin area a hold can open directly, as `admin:<page>`.
const navHoldAdminPages = [
  'home',
  'users',
  'sessions',
  'libraries',
  'upload',
  'email',
  'apikeys',
  'settings',
  'logs',
  'stats',
];

IconData navHoldAdminIcon(String page) => switch (page) {
      'home' => Icons.admin_panel_settings_rounded,
      'users' => Icons.people_rounded,
      'sessions' => Icons.history_rounded,
      'libraries' => Icons.library_books_rounded,
      'upload' => Icons.cloud_upload_rounded,
      'email' => Icons.email_rounded,
      'apikeys' => Icons.vpn_key_rounded,
      'settings' => Icons.tune_rounded,
      'logs' => Icons.description_outlined,
      _ => Icons.bar_chart_rounded,
    };

String navHoldAdminPageLabel(String page, AppLocalizations l) => switch (page) {
      'home' => l.adminTitle,
      'users' => l.adminUsers,
      'sessions' => l.adminAllSessions,
      'libraries' => l.adminLibrariesManage,
      'upload' => l.adminUploadTitle,
      'email' => l.adminEmail,
      'apikeys' => l.adminApiKeys,
      'settings' => l.adminServerSettings,
      'logs' => l.navHoldAdminLogs,
      _ => l.adminStats,
    };

/// Label for any id, composites included. [libraryName] resolves a library id
/// for `scan:<id>`; without it the scan falls back to the generic label.
String navHoldLabel(
  String id,
  AppLocalizations l, {
  String? Function(String libraryId)? libraryName,
}) {
  if (id.startsWith('admin:')) {
    final page = id.substring(6);
    return page == 'home'
        ? l.adminTitle
        : l.navHoldAdminPage(navHoldAdminPageLabel(page, l));
  }
  if (id.startsWith('scan:')) {
    final target = id.substring(5);
    if (target == 'all') return l.navHoldScanAll;
    final name = libraryName?.call(target);
    return name == null ? l.navHoldServerScan : l.navHoldScanLibrary(name);
  }
  return switch (id) {
    'search' => l.search,
    'switchLibrary' => l.switchLibraryTooltip,
    'bookmarks' => l.bookmarksTitle,
    'downloads' => l.downloads,
    'admin' => l.admin,
    'scan' => l.navHoldServerScan,
    'sleep' => l.sleepTimer,
    'eink' => l.einkModeLabel,
    'playPause' => l.navHoldPlayPause,
    'stop' => l.navHoldStop,
    'queue' => l.absorbingManageQueue,
    'offline' => l.navHoldOfflineMode,
    'readBook' => l.navHoldReadBook,
    'bookDetails' => l.navHoldBookDetails,
    'scanSeries' => l.upcomingReleasesScanSeries,
    'rmabSearch' => l.navHoldRmabSearch,
    'rmabRequests' => l.navHoldRmabRequests,
    'rmabWeb' => l.navHoldRmabWeb,
    'menu' => l.navHoldMenu,
    'none' => l.navHoldNothing,
    _ => id,
  };
}

/// Every id a saved choice may hold, in the order the settings dropdown shows
/// them. Admin entries and server scans are only offered to admins, and the
/// ReadMeABook ones only once it is set up.
List<String> navHoldAllIds({
  required bool isAdmin,
  required List<String> libraryIds,
  bool rmabConfigured = true,
  bool rmabWeb = true,
}) =>
    [
      for (final o in navHoldOptions)
        if (!o.isFolder && navHoldIdAvailable(o.id,
            isAdmin: isAdmin, rmabConfigured: rmabConfigured, rmabWeb: rmabWeb))
          o.id,
      if (isAdmin) ...[
        for (final p in navHoldAdminPages) 'admin:$p',
        'scan:all',
        for (final id in libraryIds) 'scan:$id',
      ],
    ];

/// Whether an id can do anything on this account right now. A choice that
/// can't (admin pages after losing admin, ReadMeABook before it is set up)
/// is hidden rather than offered as a dead end.
bool navHoldIdAvailable(
  String id, {
  required bool isAdmin,
  required bool rmabConfigured,
  required bool rmabWeb,
}) {
  if (id.startsWith('admin') || id.startsWith('scan:')) return isAdmin;
  if (id == 'rmabWeb') return rmabWeb;
  if (id.startsWith('rmab')) return rmabConfigured;
  return true;
}

/// What the "Always show menu" grid holds until the user edits it: every
/// simple action available to them, folders included so admin pages and
/// scans are still reachable.
List<String> navHoldDefaultMenu({
  required bool isAdmin,
  required bool rmabConfigured,
  required bool rmabWeb,
}) =>
    [
      for (final o in navHoldOptions)
        if (o.id != 'menu' &&
            o.id != 'none' &&
            navHoldIdAvailable(o.id,
                isAdmin: isAdmin,
                rmabConfigured: rmabConfigured,
                rmabWeb: rmabWeb))
          o.id,
    ];

/// The user's own arrangement of the hold menu (ordered ids, folders and
/// composites allowed). Absent means they haven't customised it.
const navHoldMenuPrefKey = 'navHoldMenuIds';

/// Stable per-tab keys, so a hold choice follows the tab rather than its
/// position - the Podcasts tab appears and disappears, which would shift
/// every slot index after it.
const navHoldTabs = ['home', 'library', 'podcasts', 'absorbing', 'stats', 'settings'];

/// Absorbing has toggled playback on hold since before this was
/// configurable; keep that as its starting point instead of asking.
const navHoldDefaults = {'absorbing': 'playPause'};

/// Stored when the user picks "Ask next time". Absent means "never chose",
/// which is what [navHoldDefaults] answers - so the two can't be the same
/// value, or asking to be asked would silently run Absorbing's default.
const navHoldAskValue = 'ask';

String navHoldPrefKey(String tab) => 'navHold_$tab';

/// What holding [tab] should do, given what is stored for it. Null means ask
/// the user. The three states are deliberately distinct: [navHoldAskValue] was
/// chosen and must always ask, absent means never chosen and lets a tab
/// default answer, anything else is the saved action.
String? navHoldResolve(String? saved, String tab) =>
    saved == navHoldAskValue ? null : (saved ?? navHoldDefaults[tab]);

String navHoldTabLabel(String tab, AppLocalizations l) => switch (tab) {
      'home' => l.appShellHomeTab,
      'library' => l.appShellLibraryTab,
      'podcasts' => l.appShellPodcastsTab,
      'absorbing' => l.appShellAbsorbingTab,
      'stats' => l.appShellStatsTab,
      'settings' => l.appShellSettingsTab,
      _ => tab,
    };
