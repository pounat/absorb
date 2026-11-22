import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/download_service.dart';
import 'card_buttons.dart' show showErrorToast;
import 'overlay_toast.dart';

/// An Audiobookshelf EPUB that reads itself aloud plays from the phone, so
/// its narration is downloaded first. Says so ([heading] and [message] for
/// a book other than the one tapped), and starts the download on the user's
/// word. True when the download started.
Future<bool> showNarrationDownloadDialog(
  BuildContext context, {
  required String itemId,
  required String title,
  String? author,
  String? coverUrl,
  String? libraryId,
  String? heading,
  String? message,
}) async {
  final l = AppLocalizations.of(context)!;
  debugPrint('[Narration] $itemId is not downloaded - asking to download it');
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.headphones_rounded),
      title: Text(heading ?? l.narrationDownloadTitle),
      content: Text(message ?? l.narrationDownloadBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.download)),
      ],
    ),
  );
  if (go != true || !context.mounted) {
    debugPrint('[Narration] $itemId: download declined');
    return false;
  }
  final api = context.read<AuthProvider>().apiService;
  if (api == null) return false;
  final error = await DownloadService().downloadItem(
    api: api,
    itemId: itemId,
    title: title,
    author: author,
    coverUrl: coverUrl,
    libraryId: libraryId,
  );
  if (!context.mounted) return error == null;
  if (error != null) {
    debugPrint('[Narration] $itemId: download did not start: $error');
    showErrorToast(context, error);
    return false;
  }
  if (!DownloadService().isDownloading(itemId)) {
    debugPrint('[Narration] $itemId: download did not start (queued, or already on the phone)');
    return false;
  }
  debugPrint('[Narration] $itemId: download started from the question');
  showOverlayToast(context, l.narrationDownloadStarted, icon: Icons.download_rounded);
  return true;
}
