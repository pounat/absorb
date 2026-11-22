import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Desktop: ask where to save and write it there. The share sheet the phones
/// use has no "save to file" on Windows. A cancelled dialog saves nothing.
Future<void> downloadTextFile({
  required String fileName,
  required String content,
}) async {
  final dot = fileName.lastIndexOf('.');
  final path = await FilePicker.platform.saveFile(
    fileName: fileName,
    type: dot > 0 ? FileType.custom : FileType.any,
    allowedExtensions: dot > 0 ? [fileName.substring(dot + 1)] : null,
  );
  if (path == null) return;
  await File(path).writeAsString(content);
}
