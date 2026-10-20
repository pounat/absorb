import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/narration_download_dialog.dart';
import '../widgets/overlay_toast.dart';
import 'audio_player_service.dart';
import 'download_service.dart';
import 'narrated_books.dart';

/// An Audiobookshelf EPUB that reads itself aloud plays only once its
/// narration is downloaded, so a queue must never reach one unready. Starting
/// a book from the app when it is three quarters done offers the download of
/// an EPUB that is next in the queue; a queue that gets there anyway stops
/// (never skipping it) and says why.
class UpNextNarration {
  UpNextNarration._();
  static final UpNextNarration instance = UpNextNarration._();

  static const _nearTheEnd = 0.75;

  // Asked once a run for each up-next book, so "Not now" sticks.
  final Set<String> _asked = {};

  /// Whether [key] is a narrated EPUB on Audiobookshelf that can't play yet.
  bool needsDownload(String key) {
    if (key.length > 36 || !NarratedBooks.contains(key)) return false;
    final dl = DownloadService();
    return !dl.isDownloaded(key) && !dl.isDownloading(key);
  }

  /// A book was started from the app: past three quarters, a narrated EPUB
  /// next in the queue that still needs downloading is offered now.
  Future<void> checkOnPlay(LibraryProvider lib, String itemId) async {
    try {
      final player = AudioPlayerService();
      final total = player.totalDuration;
      if (total <= 0) return;
      final done = player.position.inMilliseconds / 1000.0 / total;
      if (done < _nearTheEnd) return;
      final next = await lib.upNextEntry(currentItemId: itemId);
      if (next == null || !needsDownload(next.key) || !_asked.add(next.key)) return;
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final api = ctx.read<AuthProvider>().apiService;
      if (api == null || api.isBookOrbit) return;
      debugPrint('[UpNext] $itemId is ${(done * 100).toStringAsFixed(0)}% done and '
          '${next.key} is next, narration not downloaded - offering it');
      final l = AppLocalizations.of(ctx)!;
      await showNarrationDownloadDialog(
        ctx,
        itemId: next.key,
        title: next.bookTitle,
        heading: l.narrationUpNextTitle,
        message: l.narrationUpNextBody(next.bookTitle),
      );
    } catch (e) {
      debugPrint('[UpNext] heads-up check failed: $e');
    }
  }

  /// The queue reached [key] without its narration: playback stops here and
  /// says why, on screen or as a notification.
  Future<void> stopped(String key, String title) async {
    debugPrint('[UpNext] queue stopped before $key: narration not downloaded');
    final ctx = rootNavigatorKey.currentContext;
    final l = ctx == null ? null : AppLocalizations.of(ctx);
    final onScreen = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (ctx != null && l != null && onScreen) {
      showOverlayToast(ctx, l.narrationQueueStopped(title), icon: Icons.download_rounded);
      return;
    }
    try {
      await FlutterLocalNotificationsPlugin().show(
        key.hashCode & 0x7FFFFFFF,
        l?.narrationDownloadTitle ?? 'Download to listen',
        l?.narrationQueueStopped(title) ?? 'Stopped before $title. Download it to keep going.',
        NotificationDetails(
          android: Platform.isAndroid
              ? const AndroidNotificationDetails('up_next', 'Up next', importance: Importance.defaultImportance)
              : null,
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('[UpNext] notification failed: $e');
    }
  }
}
