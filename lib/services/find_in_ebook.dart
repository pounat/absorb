import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/chapter_lookup.dart';
import '../services/download_service.dart';
import '../services/progress_sync_service.dart';
import '../services/transcription_service.dart';
import '../widgets/ebook_router.dart';
import '../widgets/overlay_toast.dart';
import '../widgets/progress_dialog.dart';

/// "Find in ebook": transcribe the audio the user just heard and open the
/// companion ebook at that passage. The caller resolves the ebook file the
/// same way its Read action does; this handles the guards, the transcription
/// and the reader hand-off. The fuzzy matching itself runs inside the reader
/// (it needs the epub.js DOM).
///
/// How much audio to match on. Short keeps it fast (Whisper cost scales with
/// the decode) but too short gives fuzzy matching too few words to be unique;
/// the window ends at the pause point because that is what the user just heard.
const double findInEbookWindowSeconds = 5.0;

/// Audio chapters + total duration for [itemId], from whatever already knows
/// the book: the live player, the cached offline session, then one server
/// fetch. Empty chapters when nothing knows.
Future<({List<dynamic> chapters, double duration})> resolveAudioChapters(
    String itemId, ApiService? api) async {
  final player = AudioPlayerService();
  if (player.currentItemId == itemId && player.chapters.isNotEmpty) {
    return (chapters: player.chapters, duration: player.totalDuration);
  }
  final raw = DownloadService().getCachedSessionData(itemId);
  if (raw != null && raw.isNotEmpty) {
    try {
      final session = jsonDecode(raw) as Map<String, dynamic>;
      final chapters = session['chapters'] as List<dynamic>? ?? const [];
      final duration = (session['duration'] as num?)?.toDouble() ?? 0;
      if (chapters.isNotEmpty) return (chapters: chapters, duration: duration);
    } catch (_) {}
  }
  if (api != null) {
    try {
      final item = await api.getLibraryItem(itemId);
      final media = item?['media'] as Map<String, dynamic>? ?? {};
      final chapters = media['chapters'] as List<dynamic>? ?? const [];
      final duration = (media['duration'] as num?)?.toDouble() ?? 0;
      return (chapters: chapters, duration: duration);
    } catch (_) {}
  }
  return (chapters: const [], duration: 0.0);
}

Future<void> launchFindInEbook(
  BuildContext context, {
  required String itemId,
  required String title,
  required Map<String, dynamic>? ebookFile,
}) async {
  final l = AppLocalizations.of(context)!;

  if (ebookFile == null) {
    showOverlayToast(context, l.findInEbookNoEbook, icon: Icons.menu_book_outlined);
    return;
  }
  if (ebookExt(ebookFile) != 'epub') {
    showOverlayToast(context, l.findInEbookNeedsEpub, icon: Icons.menu_book_outlined);
    return;
  }
  if (!await PlayerSettings.getTranscriptionEnabled()) {
    if (context.mounted) {
      showOverlayToast(context, l.transcriptionDisabledHint,
          icon: Icons.record_voice_over_rounded);
    }
    return;
  }
  if (!context.mounted) return;
  if (!TranscriptionService.instance.canTranscribeBook(itemId)) {
    showOverlayToast(context, l.transcriptionNotDownloadedBook,
        icon: Icons.download_rounded);
    return;
  }

  final player = AudioPlayerService();
  double position;
  List<dynamic> chapters;
  double totalDuration;
  if (player.currentItemId == itemId) {
    if (player.isPlaying) player.pause();
    position = player.position.inMilliseconds / 1000.0;
    chapters = player.chapters;
    totalDuration = player.totalDuration;
  } else {
    // The book isn't loaded in the player (fresh app open, or Find launched
    // from an inactive card). player.position would read 0:00 and the
    // transcription would match the book's OPENING - intro music, narrator
    // credits - which the ebook text never contains, so the find "always
    // failed" before audio started. Use the saved listening position and
    // the chapters from whoever knows them instead.
    position = await ProgressSyncService().getSavedPosition(itemId);
    final audio = await resolveAudioChapters(itemId, null);
    chapters = audio.chapters;
    totalDuration = audio.duration;
  }
  if (!context.mounted) return;

  // The audio chapter at the pause point, used by the reader to search the
  // matching ebook chapter first and to cross-check the hit's location.
  String? chapterHint;
  final chIdx = ChapterLookup.indexAtWithGrace(chapters, position, totalDuration);
  if (chIdx != null) {
    final t = ((chapters[chIdx] as Map<String, dynamic>)['title'] as String?)?.trim();
    if (t != null && t.isNotEmpty) chapterHint = t;
  }

  showProgressDialog(context, l.transcribing);

  String? text;
  String? error;
  try {
    final result = await TranscriptionService.instance.transcribeAt(
      itemId: itemId,
      positionSeconds: position,
      windowSeconds: findInEbookWindowSeconds,
      leadSeconds: findInEbookWindowSeconds,
      // Matched against the ebook, never shown: speed beats accuracy.
      preferAccuracy: false,
      feature: TranscriptionFeature.readAlong,
    );
    text = result.text.trim();
    // No playback review here, so the extracted clip is done with.
    try {
      final f = File(result.audioPath);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  } on TranscriptionException catch (e) {
    error = switch (e.kind) {
      TranscriptionError.disabled => l.transcriptionDisabledHint,
      TranscriptionError.modelMissing => l.transcriptionNoModelDownloaded,
      TranscriptionError.notDownloaded => l.transcriptionNotDownloadedBook,
      TranscriptionError.noMetadata => l.transcriptionNoMetadataMsg,
      TranscriptionError.busy => l.transcriptionBusyMsg,
      TranscriptionError.empty => l.transcriptionEmptyMsg,
      _ => l.transcriptionFailedMsg,
    };
  } catch (_) {
    error = l.transcriptionFailedMsg;
  }

  if (!context.mounted) return;
  Navigator.pop(context); // dismiss the progress dialog

  if (error != null || text == null || text.isEmpty) {
    showOverlayToast(context, error ?? l.transcriptionEmptyMsg,
        icon: Icons.error_outline_rounded);
    return;
  }

  debugPrint('[FindEbook] transcript="$text" chapterHint=$chapterHint');
  await openEbookReader(
    context,
    itemId: itemId,
    title: title,
    ebookFile: ebookFile,
    findText: text,
    findChapterHint: chapterHint,
    findPositionSeconds: position,
  );
}
