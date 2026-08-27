import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/download_service.dart';
import 'overlay_toast.dart';

/// Offer to download the audio the transcription features need, instead of
/// only saying they can't run. Transcription reads the downloaded file, so
/// "not downloaded" is a step away from working rather than a dead end.
///
/// Returns true when a download was started.
Future<bool> promptDownloadForTranscription(
  BuildContext context, {
  required String itemId,
  String? episodeId,
  required String title,
  String? author,
  String? coverUrl,
}) async {
  final l = AppLocalizations.of(context)!;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(l.transcriptionNeedsDownload),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.download),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  final api = context.read<AuthProvider>().apiService;
  if (api == null) return false;
  final libraryId = context.read<LibraryProvider>().selectedLibraryId;
  final error = await DownloadService().downloadItem(
    api: api,
    itemId: itemId,
    episodeId: episodeId,
    title: title,
    author: author,
    coverUrl: coverUrl,
    libraryId: libraryId,
  );
  if (!context.mounted) return error == null;
  if (error != null) {
    showOverlayToast(context, error, icon: Icons.error_outline_rounded);
    return false;
  }
  showOverlayToast(context, l.transcriptionDownloadStarted,
      icon: Icons.download_rounded);
  return true;
}
