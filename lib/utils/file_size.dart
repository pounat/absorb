/// A file size the way the file info sheet shows it: "820 KB", "1.4 GB".
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).round()} KB';
  if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
}
