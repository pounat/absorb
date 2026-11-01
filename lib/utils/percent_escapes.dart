import 'dart:convert';

/// [text] with its `%XX` escapes turned back into the characters they stand
/// for and everything else left as it is. Uri.decodeComponent throws on any
/// character outside ASCII and Uri.decodeFull leaves reserved ones like %2C
/// escaped, so a name like `Bob)꞉ Bobiverse%2C Book 1` came back unchanged.
String undoPercentEscapes(String text) {
  if (!text.contains('%')) return text;
  bool hex(int c) => (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x46) || (c >= 0x61 && c <= 0x66);
  final bytes = utf8.encode(text);
  final out = <int>[];
  for (var i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    if (b == 0x25 && i + 2 < bytes.length && hex(bytes[i + 1]) && hex(bytes[i + 2])) {
      out.add(int.parse(String.fromCharCodes([bytes[i + 1], bytes[i + 2]]), radix: 16));
      i += 2;
    } else {
      out.add(b);
    }
  }
  return utf8.decode(out, allowMalformed: true);
}

/// A path with each segment's escapes undone, so an escaped slash can't
/// split a name into folders.
String undoPathEscapes(String path) =>
    path.contains('%') ? path.split('/').map(undoPercentEscapes).join('/') : path;
