import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages notifications for audiobook downloads.
/// Uses an Android **foreground service** for progress so the OS won't kill
/// the download when the app is backgrounded or the screen is locked.
/// A separate high-importance channel handles completion/error alerts.
class DownloadNotificationService {
  // Singleton
  static final DownloadNotificationService _instance = DownloadNotificationService._();
  factory DownloadNotificationService() => _instance;
  DownloadNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _foregroundActive = false;

  // Foreground service / progress channel
  static const _progressChannelId = 'absorb_downloads';
  static const _progressChannelName = 'Download Progress';
  static const _progressChannelDesc = 'Shows progress during audiobook downloads';
  static const _progressNotifId = 9001;

  // Alert channel for completion / error (heads-up + sound)
  static const _alertChannelId = 'absorb_download_alerts';
  static const _alertChannelName = 'Download Alerts';
  static const _alertChannelDesc = 'Notifications when downloads finish or fail';
  static const _alertNotifId = 9002;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('drawable/ic_notification');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    // Create notification channels (Android 8+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Progress channel — default importance so the foreground service
      // notification stays visible in the shade without making noise.
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _progressChannelId,
          _progressChannelName,
          description: _progressChannelDesc,
          importance: Importance.defaultImportance,
          showBadge: false,
        ),
      );

      // High-importance alert channel for completion / errors
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _alertChannelId,
          _alertChannelName,
          description: _alertChannelDesc,
          importance: Importance.high,
          showBadge: true,
        ),
      );

      // Request notification permission (Android 13+)
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Start the foreground service and show initial progress notification.
  /// Call once at the start of a download.
  Future<void> startForeground({
    required String title,
    String? author,
  }) async {
    if (!_initialized) await init();

    final subtitle = author != null && author.isNotEmpty
        ? '$author • Starting…'
        : 'Starting…';

    final androidDetails = AndroidNotificationDetails(
      _progressChannelId,
      _progressChannelName,
      channelDescription: _progressChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showProgress: true,
      maxProgress: 100,
      progress: 0,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
      icon: 'drawable/ic_notification',
    );

    // Start as a foreground service — this prevents Android from killing
    // the process while the download is active.
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        await androidPlugin.startForegroundService(
          _progressNotifId,
          'Downloading: $title',
          subtitle,
          notificationDetails: androidDetails,
          payload: 'download',
        );
        _foregroundActive = true;
        debugPrint('[DownloadNotif] Foreground service started');
      } catch (e) {
        debugPrint('[DownloadNotif] Foreground service failed, falling back: $e');
        // Fall back to a regular notification
        await _plugin.show(
          _progressNotifId,
          'Downloading: $title',
          subtitle,
          NotificationDetails(android: androidDetails),
        );
        _foregroundActive = false;
      }
    }
  }

  /// Show or update the download progress notification.
  Future<void> showProgress({
    required String title,
    required double progress,
    String? author,
  }) async {
    if (!_initialized) await init();

    final percent = (progress * 100).round().clamp(0, 100);
    final subtitle = author != null && author.isNotEmpty
        ? '$author • $percent%'
        : '$percent%';

    final androidDetails = AndroidNotificationDetails(
      _progressChannelId,
      _progressChannelName,
      channelDescription: _progressChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showProgress: true,
      maxProgress: 100,
      progress: percent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
      icon: 'drawable/ic_notification',
    );

    await _plugin.show(
      _progressNotifId,
      'Downloading: $title',
      subtitle,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Stop the foreground service and clear the progress notification.
  Future<void> stopForeground() async {
    if (_foregroundActive) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        try {
          await androidPlugin.stopForegroundService();
          debugPrint('[DownloadNotif] Foreground service stopped');
        } catch (e) {
          debugPrint('[DownloadNotif] Stop foreground failed: $e');
        }
      }
      _foregroundActive = false;
    }
    try {
      await _plugin.cancel(_progressNotifId);
    } catch (e) {
      debugPrint('[DownloadNotif] Cancel progress failed: $e');
    }
  }

  /// Show a heads-up completion notification with sound.
  /// Stops the foreground service and dismisses the progress notification first.
  Future<void> showComplete({required String title}) async {
    if (!_initialized) await init();

    // Stop the foreground service + clear progress
    await stopForeground();

    const androidDetails = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      channelDescription: _alertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      icon: 'drawable/ic_notification',
      ticker: 'Download complete',
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
    );

    await _plugin.show(
      _alertNotifId,
      'Download Complete',
      '$title is ready to listen offline',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Show a heads-up error notification with sound.
  /// Stops the foreground service and dismisses the progress notification first.
  Future<void> showError({required String title, String? message}) async {
    if (!_initialized) await init();

    // Stop the foreground service + clear progress
    await stopForeground();

    const androidDetails = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      channelDescription: _alertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      icon: 'drawable/ic_notification',
      ticker: 'Download failed',
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
    );

    await _plugin.show(
      _alertNotifId,
      'Download Failed',
      message ?? title,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Dismiss all download notifications and stop the foreground service.
  Future<void> dismiss() async {
    await stopForeground();
    try {
      await _plugin.cancel(_alertNotifId);
    } catch (e) {
      debugPrint('[DownloadNotif] Cancel alert failed: $e');
    }
  }
}
