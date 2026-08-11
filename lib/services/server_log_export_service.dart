import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/text_file_download.dart';

class ServerLogExportService {
  const ServerLogExportService._();

  static Future<void> exportText({
    required String fileName,
    required String content,
    Rect? sharePositionOrigin,
  }) async {
    if (kIsWeb) {
      await downloadTextFile(fileName: fileName, content: content);
      return;
    }

    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      name: fileName,
      mimeType: 'text/plain',
    );
    await Share.shareXFiles(
      [file],
      subject: 'Audiobookshelf server logs',
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
