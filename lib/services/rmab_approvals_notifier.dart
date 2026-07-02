import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import '../widgets/rmab_config_sheet.dart';
import 'rmab_service.dart';
import 'scoped_prefs.dart';

/// Best-effort background notifier for RMAB admin approvals.
///
/// On a periodic background-fetch tick it polls `listPendingApprovals()` and
/// fires a local notification when *new* requests have appeared since the last
/// check. Tapping the notification opens the RMAB drawer on the Approvals tab.
///
/// iOS background execution is heavily throttled by the OS, so delivery is
/// best-effort — not guaranteed or timely. The feature is opt-in (default off);
/// the dependable surface is the in-app badge ([_refreshRmabApprovalsBadge] in
/// settings) and the Approvals tab itself.
class RmabApprovalsNotifier {
  RmabApprovalsNotifier._();

  /// ScopedPrefs key: '`true`' when the user has opted in.
  static const String enabledKey = 'rmab_approval_notifs';

  /// ScopedPrefs key: comma-joined request ids already seen (the baseline we
  /// diff against, so we only notify for genuinely new requests).
  static const String _seenIdsKey = 'rmab_seen_approval_ids';

  static const String _payload = 'rmab_approvals';
  static const int _notifId = 920411;
  static const String _channelId = 'rmab_approvals';
  static const String _channelName = 'ReadMeABook approvals';

  static final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  static bool _notifReady = false;
  static bool _configured = false;

  static Future<bool> isEnabled() async =>
      (await ScopedPrefs.getString(enabledKey)) == 'true';

  /// Register the Android headless entry-point. Call once, as early as possible
  /// in `main()` (no-op on iOS).
  static void registerHeadless() {
    try {
      BackgroundFetch.registerHeadlessTask(rmabApprovalsHeadlessTask);
    } catch (e) {
      debugPrint('[RMAB] registerHeadless failed: $e');
    }
  }

  /// One-time app-start setup: init notifications, handle a cold-start tap, and
  /// configure background-fetch (started only if the user opted in).
  static Future<void> init() async {
    await _ensureNotifications();

    // Cold start launched by tapping the notification.
    final launch = await _fln.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload == _payload) {
      _navigateToApprovals();
    }

    await _configureBackgroundFetch();
  }

  static Future<void> _ensureNotifications() async {
    if (_notifReady) return;
    const android = AndroidInitializationSettings('ic_notification');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _fln.initialize(
      const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (resp) {
        if (resp.payload == _payload) _navigateToApprovals();
      },
    );
    _notifReady = true;
  }

  static Future<void> _configureBackgroundFetch() async {
    if (_configured) return;
    _configured = true;
    try {
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          stopOnTerminate: false,
          startOnBoot: true,
          enableHeadless: true,
          requiredNetworkType: NetworkType.ANY,
        ),
        (String taskId) async {
          await _poll();
          BackgroundFetch.finish(taskId);
        },
        (String taskId) async {
          // OS-imposed task timeout — must finish promptly.
          BackgroundFetch.finish(taskId);
        },
      );
      if (await isEnabled()) {
        await BackgroundFetch.start();
      } else {
        await BackgroundFetch.stop();
      }
    } catch (e) {
      debugPrint('[RMAB] background_fetch configure failed: $e');
    }
  }

  /// Opt in: request OS permission, persist, seed the baseline (so the current
  /// backlog doesn't notify immediately), and start background fetch.
  /// Returns false if the OS notification permission was denied.
  static Future<bool> enable() async {
    await _ensureNotifications();
    final granted = await _requestPermission();
    if (!granted) return false;
    await ScopedPrefs.setString(enabledKey, 'true');
    await _poll(seedOnly: true);
    await _configureBackgroundFetch();
    try {
      await BackgroundFetch.start();
    } catch (e) {
      debugPrint('[RMAB] background_fetch start failed: $e');
    }
    return true;
  }

  /// Opt out: persist, stop background fetch, clear any showing notification.
  static Future<void> disable() async {
    await ScopedPrefs.setString(enabledKey, 'false');
    try {
      await BackgroundFetch.stop();
    } catch (_) {}
    try {
      await _fln.cancel(_notifId);
    } catch (_) {}
  }

  static Future<bool> _requestPermission() async {
    try {
      final ios = _fln.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return (await ios.requestPermissions(
                alert: true, badge: true, sound: true)) ??
            false;
      }
      final android = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return (await android.requestNotificationsPermission()) ?? true;
      }
    } catch (e) {
      debugPrint('[RMAB] notif permission error: $e');
    }
    return true;
  }

  /// Fetch pending approvals and notify on ids not seen before. [seedOnly]
  /// records the baseline without notifying (used on opt-in).
  static Future<void> _poll({bool seedOnly = false}) async {
    if (!seedOnly && !(await isEnabled())) return;
    final base = await ScopedPrefs.getString(kRmabBaseUrlKey);
    final token = await ScopedPrefs.getString(kRmabApiTokenKey);
    if (base == null || base.isEmpty || token == null || token.isEmpty) return;

    final List<RmabPendingApproval> pending;
    try {
      pending = await RmabService(baseUrl: base, apiToken: token)
          .listPendingApprovals();
    } catch (e) {
      // 403 (non-admin), network, etc. — nothing to do this tick.
      debugPrint('[RMAB] approvals poll skipped: $e');
      return;
    }

    final currentIds = pending.map((e) => e.id).toSet();
    final seen = await _loadSeen();
    final newOnes = pending.where((e) => !seen.contains(e.id)).toList();

    await _saveSeen(currentIds);
    if (seedOnly || newOnes.isEmpty) return;
    await _notify(newOnes);
  }

  static Future<void> _notify(List<RmabPendingApproval> newOnes) async {
    final ctx = rootNavigatorKey.currentContext;
    final l = ctx != null ? AppLocalizations.of(ctx) : null;
    final count = newOnes.length;
    final title = l?.rmabApprovalNotifTitle ?? 'Approvals waiting';
    final body = count == 1
        ? (l?.rmabApprovalNotifBodyOne(newOnes.first.audiobook.title) ??
            '"${newOnes.first.audiobook.title}" needs your approval')
        : (l?.rmabApprovalNotifBodyMany(count) ??
            '$count requests need your approval');

    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'New ReadMeABook requests awaiting your approval',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    );
    const ios = DarwinNotificationDetails();
    await _fln.show(
      _notifId,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
      payload: _payload,
    );
  }

  static Future<Set<String>> _loadSeen() async {
    final raw = await ScopedPrefs.getString(_seenIdsKey);
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  static Future<void> _saveSeen(Set<String> ids) async {
    await ScopedPrefs.setString(_seenIdsKey, ids.join(','));
  }

  /// Open the RMAB drawer on the Approvals tab. Retries briefly so it also
  /// works from a cold start, before the navigator is mounted.
  static Future<void> _navigateToApprovals() async {
    for (var i = 0; i < 20; i++) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        await showRmabConfigSheet(ctx,
            isAdminContext: true, initialApprovals: true);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }
}

/// Android headless entry-point (fires when the app is terminated). iOS does
/// not use this path. Kept self-contained so it works in its own isolate.
@pragma('vm:entry-point')
void rmabApprovalsHeadlessTask(HeadlessTask task) async {
  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
    return;
  }
  await RmabApprovalsNotifier._ensureNotifications();
  await RmabApprovalsNotifier._poll();
  BackgroundFetch.finish(task.taskId);
}
