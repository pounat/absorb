import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;

/// Manages notifications for audiobook downloads.
/// Uses an Android **foreground service** for a summary notification so the OS
/// won't kill the download when the app is backgrounded or the screen is locked.
/// Each concurrent download gets its own progress notification.
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
  String get _progressChannelName =>
      _l()?.downloadNotifProgressChannelName ?? 'Download Progress';
  String get _progressChannelDesc =>
      _l()?.downloadNotifProgressChannelDesc ?? 'Shows progress during audiobook downloads';

  // Alert channel for completion / error (heads-up + sound)
  static const _alertChannelId = 'absorb_download_alerts';
  String get _alertChannelName =>
      _l()?.downloadNotifAlertChannelName ?? 'Download Alerts';
  String get _alertChannelDesc =>
      _l()?.downloadNotifAlertChannelDesc ?? 'Notifications when downloads finish or fail';

  AppLocalizations? _l() {
    final ctx = rootNavigatorKey.currentContext;
    return ctx != null ? AppLocalizations.of(ctx) : null;
  }

  // Notification IDs
  static const _foregroundNotifId = 9000; // summary foreground service
  // Per-download progress: 9001 + slot (slots 0–4)
  static int _progressNotifId(int slot) => 9001 + slot;
  // Alerts use incrementing IDs so they stack
  int _nextAlertId = 9010;

  int _activeCount = 0;

  // Track last shown percent per slot so we can throttle progress updates. iOS
  // re-banners each notification update (even with the same ID), so even with
  // passive interruption we want to keep the update rate low.
  final Map<int, int> _lastShownPercent = {};

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);

    // Create notification channels (Android 8+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Progress channel; default importance so the foreground service
      // notification stays visible in the shade without making noise.
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _progressChannelId,
          _progressChannelName,
          description: _progressChannelDesc,
          importance: Importance.defaultImportance,
          showBadge: false,
        ),
      );

      // High-importance alert channel for completion / errors
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
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

  /// Start tracking a new download. Starts the foreground service if this is
  /// the first active download. Shows an individual progress notification.
  Future<void> startDownload({
    required int slot,
    required String title,
    String? author,
  }) async {
    if (!_initialized) await init();
    _activeCount++;
    _lastShownPercent.remove(slot);

    // Start foreground service if this is the first download
    if (_activeCount == 1) {
      await _startForeground();
    } else {
      await _updateForegroundSummary();
    }

    // Show individual progress notification
    await _showSlotProgress(
      slot: slot,
      title: title,
      author: author,
      percent: 0,
      starting: true,
    );
  }

  /// Update progress for an individual download.
  Future<void> updateProgress({
    required int slot,
    required String title,
    required double progress,
    String? author,
  }) async {
    if (!_initialized) await init();
    final percent = (progress * 100).round().clamp(0, 100);

    // Throttle to 10% increments (plus always emit the 100% completion).
    final last = _lastShownPercent[slot];
    if (last != null && percent < 100 && (percent - last) < 10) return;
    _lastShownPercent[slot] = percent;

    await _showSlotProgress(
      slot: slot,
      title: title,
      author: author,
      percent: percent,
    );
  }

  /// Mark a download as finished (success or error). Cancels its progress
  /// notification, shows an alert, and stops the foreground service if no
  /// downloads remain.
  Future<void> finishDownload({
    required int slot,
    required String title,
    bool success = true,
    String? errorMessage,
  }) async {
    if (!_initialized) await init();

    // Cancel individual progress notification
    try {
      await _plugin.cancel(_progressNotifId(slot));
    } catch (e) {
      debugPrint('[DownloadNotif] Cancel slot $slot failed: $e');
    }

    _activeCount = (_activeCount - 1).clamp(0, 99);
    _lastShownPercent.remove(slot);

    if (_activeCount == 0) {
      await _stopForeground();
    } else {
      await _updateForegroundSummary();
    }

    // Show alert
    final l = _l();
    if (success) {
      await _showAlert(
        title: l?.downloadNotifCompleteTitle ?? 'Download Complete',
        body: l?.downloadNotifCompleteBody(title) ?? '$title is ready to listen offline',
      );
    } else {
      await _showAlert(
        title: l?.downloadNotifFailedTitle ?? 'Download Failed',
        body: errorMessage ?? title,
      );
    }
  }

  /// Cancel a download's notification without showing an alert.
  Future<void> cancelDownload(int slot) async {
    try {
      await _plugin.cancel(_progressNotifId(slot));
    } catch (e) {
      debugPrint('[DownloadNotif] Cancel slot $slot failed: $e');
    }

    _activeCount = (_activeCount - 1).clamp(0, 99);
    _lastShownPercent.remove(slot);

    if (_activeCount == 0) {
      await _stopForeground();
    } else {
      await _updateForegroundSummary();
    }
  }

  /// Dismiss all download notifications and stop the foreground service.
  Future<void> dismiss() async {
    await _stopForeground();
    _activeCount = 0;
    _lastShownPercent.clear();
    // Cancel all possible slot notifications
    for (int i = 0; i < 5; i++) {
      try {
        await _plugin.cancel(_progressNotifId(i));
      } catch (_) {}
    }
  }

  // ── Private helpers ──

  Future<void> _startForeground() async {
    final androidDetails = AndroidNotificationDetails(
      _progressChannelId,
      _progressChannelName,
      channelDescription: _progressChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
      icon: 'drawable/ic_notification',
    );

    final l = _l();
    final title = l?.downloadNotifDownloadingTitle ?? 'Downloading...';
    final subtitle = l?.downloadNotifActiveCount(1) ?? '1 download active';

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        await androidPlugin.startForegroundService(
          _foregroundNotifId,
          title,
          subtitle,
          notificationDetails: androidDetails,
          payload: 'download',
        );
        _foregroundActive = true;
        debugPrint('[DownloadNotif] Foreground service started');
      } catch (e) {
        debugPrint('[DownloadNotif] Foreground service failed, falling back: $e');
        await _plugin.show(
          _foregroundNotifId,
          title,
          subtitle,
          NotificationDetails(android: androidDetails),
        );
        _foregroundActive = false;
      }
    }
  }

  Future<void> _updateForegroundSummary() async {
    if (_activeCount <= 0) return;
    final l = _l();
    final subtitle = l?.downloadNotifActiveCount(_activeCount)
        ?? '$_activeCount download${_activeCount == 1 ? '' : 's'} active';

    final androidDetails = AndroidNotificationDetails(
      _progressChannelId,
      _progressChannelName,
      channelDescription: _progressChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
      icon: 'drawable/ic_notification',
    );

    await _plugin.show(
      _foregroundNotifId,
      l?.downloadNotifDownloadingTitle ?? 'Downloading...',
      subtitle,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _stopForeground() async {
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
      await _plugin.cancel(_foregroundNotifId);
    } catch (e) {
      debugPrint('[DownloadNotif] Cancel foreground failed: $e');
    }
  }

  Future<void> _showSlotProgress({
    required int slot,
    required String title,
    String? author,
    required int percent,
    bool starting = false,
  }) async {
    final l = _l();
    final startingLabel = l?.downloadNotifStartingLabel ?? 'Starting\u2026';
    final subtitle = starting
        ? (author != null && author.isNotEmpty ? '$author \u2022 $startingLabel' : startingLabel)
        : (author != null && author.isNotEmpty ? '$author \u2022 $percent%' : '$percent%');

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
      _progressNotifId(slot),
      l?.downloadNotifSlotTitle(title) ?? 'Downloading: $title',
      subtitle,
      NotificationDetails(
        android: androidDetails,
        // Passive interruption: iOS updates the notification without showing
        // a banner or playing sound on each progress tick.
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBanner: false,
          presentSound: false,
          interruptionLevel: InterruptionLevel.passive,
        ),
      ),
    );
  }

  Future<void> _showAlert({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      channelDescription: _alertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      icon: 'drawable/ic_notification',
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
    );

    final alertId = _nextAlertId++;
    // Wrap around to avoid unbounded growth
    if (_nextAlertId > 9099) _nextAlertId = 9010;

    await _plugin.show(
      alertId,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
