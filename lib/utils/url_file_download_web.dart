import 'package:web/web.dart' as web;

Future<bool> downloadUrlFile(Uri uri) async {
  try {
    final body = web.document.body;
    if (body == null) return false;

    // Keep authenticated download URLs out of the visible tab and its
    // history. The server's Content-Disposition header still controls whether
    // this is the original file or a generated ZIP.
    final frame = web.HTMLIFrameElement()
      ..src = uri.toString()
      ..style.display = 'none';
    body.appendChild(frame);
    return true;
  } catch (_) {
    return false;
  }
}
