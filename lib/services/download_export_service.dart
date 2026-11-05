import 'dart:io';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// A download is incomplete or its audio files can no longer be read.
class DownloadExportUnavailable implements Exception {}

/// Shares the original audio tracks without reading an audiobook into memory.
///
/// On iOS this works for both App Group and legacy Documents downloads. The
/// share sheet offers AirDrop and Save to Files without moving playback files
/// out of the App Group used by the widget.
class DownloadExportService {
  Future<ShareResult> shareAudioFiles(
    List<String> localPaths, {
    required Rect sharePositionOrigin,
  }) async {
    if (localPaths.isEmpty) throw DownloadExportUnavailable();

    final files = <XFile>[];
    for (final path in localPaths) {
      try {
        final file = File(path);
        final stat = await file.stat();
        if (stat.type != FileSystemEntityType.file || stat.size == 0) {
          throw DownloadExportUnavailable();
        }
        // Validate every track so a missing chapter never produces a partial
        // export, including when stat succeeds but read access is denied.
        final handle = await file.open();
        await handle.close();
        files.add(XFile(path));
      } on FileSystemException {
        throw DownloadExportUnavailable();
      }
    }

    return Share.shareXFiles(files, sharePositionOrigin: sharePositionOrigin);
  }
}
