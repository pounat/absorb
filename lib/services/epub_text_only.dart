import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

const _narrationExts = {
  '.mp3', '.m4a', '.m4b', '.mp4', '.aac', '.ogg', '.oga', '.opus', '.wav', '.flac', '.smil',
};

bool isNarrationEntry(String name) {
  final base = name.split('/').last;
  final dot = base.lastIndexOf('.');
  return dot >= 0 && _narrationExts.contains(base.substring(dot).toLowerCase());
}

/// Rebuilds a narrated EPUB as a plain one: the audio, the SMIL timings and
/// the package's mentions of them all go, so readers and Send to Kindle see
/// an ordinary book. Text, images, styles and fonts are kept as they are.
Uint8List stripNarrationFromEpub(Uint8List epub) {
  final archive = ZipDecoder().decodeBytes(epub);
  final opfPath = _opfPath(archive);
  final dropped = <String>{};
  String? cleanOpf;

  final opfEntry = opfPath == null ? null : archive.findFile(opfPath);
  if (opfEntry != null) {
    final doc = XmlDocument.parse(utf8.decode(opfEntry.content, allowMalformed: true));
    final dir = opfPath!.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
    final droppedIds = <String>{};
    for (final item in doc.findAllElements('item', namespace: '*').toList()) {
      final type = (item.getAttribute('media-type') ?? '').toLowerCase();
      final href = item.getAttribute('href') ?? '';
      if (type == 'application/smil+xml' || type.startsWith('audio/') || isNarrationEntry(href)) {
        final id = item.getAttribute('id');
        if (id != null) droppedIds.add(id);
        dropped.add(_resolve(dir, href));
        item.remove();
      } else {
        item.removeAttribute('media-overlay');
      }
    }
    for (final ref in doc.findAllElements('itemref', namespace: '*').toList()) {
      if (droppedIds.contains(ref.getAttribute('idref'))) ref.remove();
    }
    for (final meta in doc.findAllElements('meta', namespace: '*').toList()) {
      final property = meta.getAttribute('property') ?? '';
      if (property.startsWith('media:')) meta.remove();
    }
    cleanOpf = doc.toXmlString();
  }

  final out = Archive();
  final mimetype = archive.findFile('mimetype');
  out.addFile(ArchiveFile.noCompress(
    'mimetype',
    mimetype?.size ?? 20,
    mimetype?.content ?? utf8.encode('application/epub+zip'),
  ));
  for (final f in archive.files) {
    if (!f.isFile || f.name == 'mimetype') continue;
    if (isNarrationEntry(f.name) || dropped.contains(f.name)) continue;
    if (f.name == opfPath && cleanOpf != null) {
      out.addFile(ArchiveFile.string(f.name, cleanOpf));
    } else {
      out.addFile(ArchiveFile.bytes(f.name, f.content));
    }
  }
  return ZipEncoder().encodeBytes(out);
}

String? _opfPath(Archive archive) {
  final container = archive.findFile('META-INF/container.xml');
  if (container != null) {
    try {
      final doc = XmlDocument.parse(utf8.decode(container.content, allowMalformed: true));
      final path = doc.findAllElements('rootfile', namespace: '*').firstOrNull?.getAttribute('full-path');
      if (path != null && path.isNotEmpty) return path;
    } catch (_) {}
  }
  return archive.files.where((f) => f.name.toLowerCase().endsWith('.opf')).firstOrNull?.name;
}

String _resolve(String dir, String href) {
  var path = href.split('#').first;
  try {
    path = Uri.decodeComponent(path);
  } catch (_) {}
  final parts = <String>[];
  for (final p in '$dir$path'.split('/')) {
    if (p == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (p.isNotEmpty && p != '.') {
      parts.add(p);
    }
  }
  return parts.join('/');
}
