import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../main.dart' show rootNavigatorKey;
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/upcoming_releases_screen.dart';
import '../widgets/episode_list_sheet.dart';
import 'api_service.dart';
import 'download_service.dart';
import 'player_settings.dart';
import 'scoped_prefs.dart';
import 'user_account_service.dart';
import 'package:provider/provider.dart';

/// Background new-episode notifications (Android). A WorkManager periodic job
/// polls the subscribed shows and notifies about episodes it hasn't notified
/// about before. The job keeps its own last-seen state (notified_episodes_*),
/// separate from known_episodes_* - that one drives the in-app absorbing-queue
/// insertion and auto-download and must keep seeing "new" episodes when the
/// app next opens.
class EpisodeNotificationService {
  static const _uniqueName = 'com.barnabas.absorb.episodeNotifCheck';
  static const channelId = 'new_episodes';

  static String notifiedKey(String showId) => 'notified_episodes_$showId';

  /// Record episodes as already announced without sending anything.
  ///
  /// The in-app check runs whenever the app opens, so a user who opens Absorb
  /// inside the polling window sees and downloads the new episodes there. The
  /// job would then still notify hours later, because its ledger is separate.
  /// Once the app has shown them, they are not news any more.
  ///
  /// Only ever adds. A show whose ledger is empty is one the job has never
  /// seeded, and seeding it here would be wrong - the job seeds silently on
  /// first sight, and writing the ids now would make that silent seed a no-op
  /// rather than a deliberate one.
  static Future<void> markAlreadySurfaced(
    String showId,
    Iterable<String> episodeIds,
  ) async {
    if (episodeIds.isEmpty) return;
    final key = notifiedKey(showId);
    final seen = (await ScopedPrefs.getStringList(key)).toSet();
    if (seen.isEmpty) return;
    final before = seen.length;
    seen.addAll(episodeIds);
    if (seen.length == before) return;
    await ScopedPrefs.setStringList(key, seen.toList());
    debugPrint(
      '[EpisodeNotif] ${seen.length - before} episode(s) for $showId already '
      'surfaced in-app - will not be notified',
    );
  }

  @visibleForTesting
  static Future<void> prepareBackgroundPreferences({
    Future<void> Function()? reloadPreferences,
    Future<void> Function()? initializeAccount,
  }) async {
    if (reloadPreferences != null) {
      await reloadPreferences();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
    }

    if (initializeAccount != null) {
      await initializeAccount();
    } else {
      await UserAccountService().init();
    }
  }

  /// Register/cancel the periodic job to match the setting. Called on app
  /// start (self-healing after OEM kills) and when the setting changes.
  static Future<void> syncRegistration() async {
    if (!Platform.isAndroid) return;
    try {
      final minutes = await PlayerSettings.getEpisodeNotifIntervalMinutes();
      if (minutes <= 0) {
        await Workmanager().cancelByUniqueName(_uniqueName);
        return;
      }
      await Workmanager().initialize(episodeNotifDispatcher);
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _uniqueName,
        frequency: Duration(minutes: minutes),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.connected),
        backoffPolicy: BackoffPolicy.linear,
      );
      debugPrint('[EpisodeNotif] periodic task registered every ${minutes}m');
    } catch (e) {
      debugPrint('[EpisodeNotif] syncRegistration failed: $e');
    }
  }

  /// Foreground notification-tap wiring. Safe to call once at startup; also
  /// resolves a cold start launched from a notification.
  static Future<void> initTapHandling() async {
    if (!Platform.isAndroid) return;
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: (resp) => _handleTap(resp.payload),
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _handleTap(launch!.notificationResponse?.payload);
    }
  }

  /// Open the show's episode list once the app (navigator + session) is up.
  static Future<void> _handleTap(String? payload) async {
    if (payload == 'upcoming') {
      // Release-day notification: open the upcoming releases page.
      for (var i = 0; i < 60; i++) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          try {
            if (ctx.read<AuthProvider>().apiService != null) {
              Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => const UpcomingReleasesScreen()));
              return;
            }
          } catch (_) {}
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return;
    }
    if (payload == null || !payload.startsWith('show:')) return;
    final showId = payload.substring(5);
    for (var i = 0; i < 60; i++) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        try {
          final api = ctx.read<AuthProvider>().apiService;
          if (api != null) {
            // Warm the provider so progress/covers resolve in the sheet.
            ctx.read<LibraryProvider>();
            final item = await api.getLibraryItem(showId);
            final ctx2 = rootNavigatorKey.currentContext;
            if (item != null && ctx2 != null && ctx2.mounted) {
              EpisodeListSheet.show(ctx2, item);
            }
            return;
          }
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}

/// WorkManager entry point - runs in a fresh background isolate.
@pragma('vm:entry-point')
void episodeNotifDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await _checkAndNotify();
    } catch (e) {
      debugPrint('[EpisodeNotif] background check failed: $e');
    }
    // Never ask WorkManager to retry: the next periodic run covers it.
    return true;
  });
}

Future<void> _checkAndNotify() async {
  // WorkManager uses a separate Flutter engine whose SharedPreferences cache
  // can lag behind writes from earlier workers or the foreground app.
  await EpisodeNotificationService.prepareBackgroundPreferences();

  // Purely local, so it runs before the subscribed-podcasts early return.
  await _checkReleaseDayNotifs();

  final subscribed = await ScopedPrefs.getStringList('subscribed_podcasts');
  if (subscribed.isEmpty) return;

  final api = await _buildApiService();
  if (api == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const channel = AndroidNotificationChannel(
    EpisodeNotificationService.channelId,
    'New episodes',
    description: 'New episodes from subscribed podcasts',
    importance: Importance.defaultImportance,
  );
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  DownloadService? dl;
  for (final showId in subscribed) {
    try {
      final item = await api.getLibraryItem(showId);
      if (item == null) continue;
      final media = item['media'] as Map<String, dynamic>? ?? {};
      final episodes = (media['episodes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (episodes.isEmpty) continue;

      final key = 'notified_episodes_$showId';
      final seen = (await ScopedPrefs.getStringList(key)).toSet();
      final currentIds =
          episodes.map((e) => e['id'] as String? ?? '').where((id) => id.isNotEmpty).toList();

      // First sight of this show (fresh subscribe or feature just enabled):
      // seed silently so we don't blast the whole back catalog.
      if (seen.isEmpty) {
        await ScopedPrefs.setStringList(key, currentIds);
        continue;
      }

      final fresh = episodes
          .where((e) => !seen.contains(e['id'] as String? ?? ''))
          .toList();
      if (fresh.isEmpty) continue;

      final showTitle =
          ((media['metadata'] as Map<String, dynamic>?)?['title'] as String?) ??
              'Podcast';
      final body = fresh.length == 1
          ? (fresh.first['title'] as String? ?? 'New episode')
          : '${fresh.length} new episodes';
      await plugin.show(
        // Stable per-show id so repeat checks update rather than stack.
        0x45500000 | (showId.hashCode & 0xFFFFF),
        showTitle,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            EpisodeNotificationService.channelId,
            'New episodes',
            channelDescription: 'New episodes from subscribed podcasts',
            icon: 'drawable/ic_notification',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        payload: 'show:$showId',
      );

      await ScopedPrefs.setStringList(key, [...seen, ...fresh.map((e) => e['id'] as String)]);

      // Start the downloads now so the episodes are ready when the app next
      // opens - same auto-download behavior as the in-app catch-up (WiFi-only
      // setting respected inside enqueueBackgroundDownload). If anything here
      // fails, the in-app catch-up still downloads them: known_episodes_*
      // hasn't seen these episodes yet.
      try {
        if (dl == null) {
          DownloadService.backgroundIsolateMode = true;
          dl = DownloadService();
          await dl.init();
        }
        for (final ep in fresh) {
          final epId = ep['id'] as String;
          await dl.enqueueBackgroundDownload(
            api: api,
            itemId: '$showId-$epId',
            title: ep['title'] as String? ?? 'Episode',
            author: showTitle,
            coverUrl: api.getCoverUrl(showId),
            episodeId: epId,
            libraryId: item['libraryId'] as String?,
          );
        }
      } catch (e) {
        debugPrint('[EpisodeNotif] download enqueue failed for $showId: $e');
      }
    } catch (e) {
      debugPrint('[EpisodeNotif] check failed for $showId: $e');
    }
  }
}

/// Notify on release day for books tracked on the upcoming page. Reads the
/// cached scan results from raw prefs - no network, no account scope needed.
Future<void> _checkReleaseDayNotifs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('upcomingReleasesCache');
    if (json == null || json.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notified =
        (prefs.getStringList('upcomingReleaseDayNotified') ?? []).toSet();
    final results = jsonDecode(json) as List<dynamic>;

    final allUpcomingAsins = <String>{};
    final due = <({String asin, String title, String seriesName})>[];
    for (final r in results) {
      if (r is! Map) continue;
      final seriesName = r['seriesName'] as String? ?? '';
      for (final b in (r['upcomingBooks'] as List<dynamic>? ?? [])) {
        if (b is! Map) continue;
        final asin = b['asin'] as String? ?? '';
        final title = b['title'] as String? ?? '';
        if (asin.isEmpty || title.isEmpty) continue;
        allUpcomingAsins.add(asin);
        if (notified.contains(asin)) continue;
        final date = DateTime.tryParse(b['releaseDate'] as String? ?? '');
        if (date == null) continue;
        // Release day, or the periodic job catching up within a couple days
        final daysOut = today.difference(DateTime(date.year, date.month, date.day)).inDays;
        if (daysOut < 0 || daysOut > 2) continue;
        due.add((asin: asin, title: title, seriesName: seriesName));
      }
    }
    if (due.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const channel = AndroidNotificationChannel(
      'release_day',
      'Book releases',
      description: 'A tracked upcoming book is out',
      importance: Importance.defaultImportance,
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    for (final book in due) {
      await plugin.show(
        0x52440000 | (book.asin.hashCode & 0xFFFF),
        '${book.title} is released today!',
        book.seriesName,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'release_day',
            'Book releases',
            channelDescription: 'A tracked upcoming book is out',
            icon: 'drawable/ic_notification',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        payload: 'upcoming',
      );
    }

    // Keep only asins still tracked as upcoming - released books leave the
    // upcoming list on the next scan, so the set prunes itself.
    await prefs.setStringList('upcomingReleaseDayNotified',
        {...notified, ...due.map((b) => b.asin)}.where(allUpcomingAsins.contains).toList());
    debugPrint('[EpisodeNotif] release-day notified: ${due.length}');
  } catch (e) {
    debugPrint('[EpisodeNotif] release-day check failed: $e');
  }
}

/// ApiService from raw prefs - same pattern as the home-widget cold path
/// (server_url/token/refresh_token/custom_headers, prefer a reachable local
/// server so home-WiFi setups work).
Future<ApiService?> _buildApiService() async {
  final prefs = await SharedPreferences.getInstance();
  final remoteUrl = prefs.getString('server_url');
  final token = prefs.getString('token');
  if (remoteUrl == null || token == null) return null;
  final refreshToken = prefs.getString('refresh_token');
  final username = prefs.getString('username');

  Map<String, String>? customHeaders;
  final headersJson = prefs.getString('custom_headers');
  if (headersJson != null) {
    try {
      customHeaders = Map<String, String>.from(jsonDecode(headersJson) as Map);
    } catch (_) {}
  }
  final headers = customHeaders ?? const <String, String>{};

  String baseUrl = remoteUrl;
  final localEnabled = await PlayerSettings.getLocalServerEnabled();
  final localUrl = await PlayerSettings.getLocalServerUrl();
  if (localEnabled && localUrl.isNotEmpty) {
    final localReachable = await ApiService.pingServer(localUrl, customHeaders: headers)
        .timeout(const Duration(seconds: 3), onTimeout: () => false);
    if (localReachable) baseUrl = localUrl;
  }

  return ApiService(
    baseUrl: baseUrl,
    token: token,
    refreshToken: refreshToken,
    isLegacyToken: refreshToken == null,
    customHeaders: headers,
    loadPersistedTokens: () =>
        UserAccountService().loadPersistedTokens(remoteUrl, username),
    onTokensRefreshed: (access, refresh) =>
        UserAccountService().persistRefreshedTokens(
          access,
          refresh,
          serverUrl: remoteUrl,
          username: username,
        ),
  );
}
