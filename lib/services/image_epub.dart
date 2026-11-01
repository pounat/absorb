import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;

import '../utils/percent_escapes.dart';

/// EPUBs whose pages are pictures (scanned or comic-style books) carry no
/// text for the EPUB reader to lay out or index, so they read better in the
/// comic reader. This finds their page images in reading order.

class ImageEpubPage {
  /// The picture's path inside the zip.
  final String entry;

  /// The picture's EPUB position, so the page can be saved where any EPUB
  /// reader finds it.
  final String cfi;
  const ImageEpubPage(this.entry, this.cfi);
}

final _attr = RegExp(r'''([\w:-]+)\s*=\s*("([^"]*)"|'([^']*)')''');
final _itemTag = RegExp(r'<(?:\w+:)?item\b[^>]*>', caseSensitive: false);
final _itemrefTag = RegExp(r'<(?:\w+:)?itemref\b[^>]*>', caseSensitive: false);
final _rootfileTag = RegExp(r'<(?:\w+:)?rootfile\b[^>]*>', caseSensitive: false);
final _markup = RegExp(
    r'''<!--.*?-->|<!\[CDATA\[.*?\]\]>|<[!?][^>]*>|<(/?)([\w:.-]+)((?:[^>"']|"[^"]*"|'[^']*')*?)(/?)>''',
    dotAll: true);
final _head = RegExp(r'<head\b.*?</head>', caseSensitive: false, dotAll: true);
final _tags = RegExp(r'<[^>]*>');
final _entities = RegExp(r'&#?\w+;');
final _space = RegExp(r'\s+');
const _voidTags = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'source', 'track', 'wbr'};

Map<String, String> _attrs(String tag) => {
      for (final m in _attr.allMatches(tag)) m.group(1)!.toLowerCase(): m.group(3) ?? m.group(4) ?? '',
    };

String _dir(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 ? '' : path.substring(0, i + 1);
}

/// [href] relative to [base]'s folder, as a path inside the zip.
String _resolve(String base, String href) {
  final clean = undoPathEscapes(href.split('#').first.split('?').first);
  final parts = <String>[];
  for (final p in '${_dir(base)}$clean'.split('/')) {
    if (p.isEmpty || p == '.') continue;
    if (p == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(p);
    }
  }
  return parts.join('/');
}

String? _text(Archive archive, String name) {
  final f = archive.findFile(name);
  if (f == null) return null;
  return utf8.decode(f.content as List<int>, allowMalformed: true);
}

/// Every picture in an XHTML page, in document order, with the EPUB path
/// steps to it from the root element.
List<({String src, List<int> steps})> _pictures(String doc) {
  final out = <({String src, List<int> steps})>[];
  final counts = <int>[0];
  final path = <int>[];
  for (final m in _markup.allMatches(doc)) {
    final name = m.group(2);
    if (name == null) continue;
    if (m.group(1) == '/') {
      if (path.isNotEmpty) {
        path.removeLast();
        counts.removeLast();
      }
      continue;
    }
    counts[counts.length - 1]++;
    final step = counts.last * 2;
    final local = name.substring(name.indexOf(':') + 1).toLowerCase();
    if (local == 'img' || local == 'image') {
      final a = _attrs(m.group(3) ?? '');
      final src = a['src'] ?? a['xlink:href'] ?? a['href'];
      if (src != null && src.isNotEmpty) out.add((src: src, steps: [...path, step]));
    }
    if (m.group(4) != '/' && !_voidTags.contains(local)) {
      path.add(step);
      counts.add(0);
    }
  }
  return out;
}

/// The page images in reading order when the book is pictures with next to
/// no text, one per page or many on one long page; null for an ordinary EPUB.
///
/// [why], when given, gets a line saying what decided it, for the log.
List<ImageEpubPage>? imageEpubPages(Archive archive, {void Function(String)? why}) {
  List<ImageEpubPage>? no(String reason) {
    why?.call(reason);
    return null;
  }

  final container = _text(archive, 'META-INF/container.xml');
  if (container == null) return no('no META-INF/container.xml');
  final rootTag = _rootfileTag.firstMatch(container)?.group(0);
  final opfPath = rootTag == null ? null : _attrs(rootTag)['full-path'];
  if (opfPath == null || opfPath.isEmpty) return no('no package file named');
  final opf = _text(archive, opfPath);
  if (opf == null) return no('package file $opfPath missing');

  final hrefById = <String, String>{};
  for (final m in _itemTag.allMatches(opf)) {
    final a = _attrs(m.group(0)!);
    final id = a['id'], href = a['href'];
    if (id != null && href != null) hrefById[id] = _resolve(opfPath, href);
  }
  final spine = [
    for (final m in _itemrefTag.allMatches(opf)) _attrs(m.group(0)!)['idref'] ?? '',
  ];
  if (spine.isEmpty) return no('empty spine');

  // A cover, title page or copyright notice is allowed, a book of text isn't.
  final allowedTextPages = spine.length ~/ 10 < 2 ? 2 : spine.length ~/ 10;
  final pages = <ImageEpubPage>[];
  var textPages = 0;
  for (var i = 0; i < spine.length; i++) {
    final docPath = hrefById[spine[i]];
    final doc = docPath == null ? null : _text(archive, docPath);
    if (doc == null) continue;
    final words = doc
        .replaceAll(_head, ' ')
        .replaceAll(_tags, ' ')
        .replaceAll(_entities, ' ')
        .replaceAll(_space, ' ')
        .trim();
    final pictures = _pictures(doc);
    // A page number or a caption per picture is fine; prose isn't.
    if (pictures.isNotEmpty && words.length <= 40 * pictures.length) {
      for (final p in pictures) {
        final entry = _resolve(docPath!, p.src);
        if (archive.findFile(entry) == null || p.steps.length < 2) continue;
        pages.add(ImageEpubPage(entry, 'epubcfi(/6/${(i + 1) * 2}!/${p.steps.skip(1).join('/')})'));
      }
    } else if (words.isNotEmpty) {
      if (++textPages > allowedTextPages) {
        return no('text on more than $allowedTextPages of ${spine.length} spine items');
      }
    }
  }
  if (pages.length < 3) return no('only ${pages.length} pictures in ${spine.length} spine items');
  why?.call('${pages.length} pictures in ${spine.length} spine items');
  return pages;
}

/// The whole-number steps of an EPUB position, in a form that orders
/// positions: character offsets, ranges and id assertions are dropped.
List<int>? cfiSteps(String? cfi) {
  final m = RegExp(r'^epubcfi\((.*)\)$').firstMatch(cfi?.trim() ?? '');
  if (m == null) return null;
  var body = m.group(1)!;
  final comma = body.indexOf(',');
  if (comma >= 0) body = body.substring(0, comma);
  body = body.replaceAll(RegExp(r'\[[^\]]*\]'), '').replaceAll(RegExp(r':\d+.*$'), '');
  final steps = [for (final s in RegExp(r'/(\d+)').allMatches(body)) int.parse(s.group(1)!)];
  return steps.isEmpty ? null : steps;
}

int _compareSteps(List<int> a, List<int> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return a.length.compareTo(b.length);
}

/// The index of the page a saved EPUB position falls on: the last page that
/// starts at or before it. Null when [cfi] isn't an EPUB position.
int? pageIndexForCfi(List<String> pageCfis, String? cfi) {
  final target = cfiSteps(cfi);
  if (target == null) return null;
  var index = 0;
  for (var i = 0; i < pageCfis.length; i++) {
    final steps = cfiSteps(pageCfis[i]);
    if (steps == null) continue;
    if (_compareSteps(steps, target) > 0) break;
    index = i;
  }
  return index;
}

/// Pages in an image-only EPUB (0 for an ordinary one) and what decided it.
/// Runs in an isolate.
List<Object> countImageEpubPages(String path) {
  final input = InputFileStream(path);
  try {
    var reason = '';
    final pages = imageEpubPages(ZipDecoder().decodeStream(input), why: (r) => reason = r);
    return [pages?.length ?? 0, reason];
  } catch (e) {
    return [0, 'unreadable: $e'];
  } finally {
    input.closeSync();
  }
}

/// Writes an image-only EPUB's pages into [args][1] as 00000.jpg, ... with
/// their EPUB positions in `.cfis`, one per line. Runs in an isolate. Returns the paths.
List<String> extractImageEpubPages(List<String> args) {
  final src = args[0], dest = args[1];
  final input = InputFileStream(src);
  try {
    final archive = ZipDecoder().decodeStream(input);
    final pages = imageEpubPages(archive) ?? const <ImageEpubPage>[];
    Directory(dest).createSync(recursive: true);
    final paths = <String>[];
    for (var i = 0; i < pages.length; i++) {
      final name = pages[i].entry;
      final ext = name.substring(name.lastIndexOf('.') + 1).toLowerCase();
      final path = '$dest${Platform.pathSeparator}${i.toString().padLeft(5, '0')}.$ext';
      final out = OutputFileStream(path);
      archive.findFile(name)!.writeContent(out);
      out.closeSync();
      paths.add(path);
    }
    File('$dest${Platform.pathSeparator}.cfis').writeAsStringSync(pages.map((p) => p.cfi).join('\n'));
    File('$dest${Platform.pathSeparator}.done').writeAsStringSync('${paths.length}');
    return paths;
  } finally {
    input.closeSync();
  }
}

/// Page count when [file] is an image-only EPUB, 0 otherwise. The answer is
/// kept beside the file, so each version of a book is only looked at once.
Future<int> imageEpubPageCount(File file) async {
  final marker = File('${file.path}.imagepages');
  final key = 'v$imageEpubScanVersion:${await file.length()}';
  try {
    final saved = marker.existsSync() ? marker.readAsStringSync() : '';
    if (saved.startsWith('$key:')) return int.tryParse(saved.substring(key.length + 1)) ?? 0;
  } catch (_) {}
  final result = await compute(countImageEpubPages, file.path);
  final count = result[0] as int;
  debugPrint('[ImageEpub] ${file.uri.pathSegments.last}: '
      '${count > 0 ? 'picture book' : 'regular EPUB'} - ${result[1]}');
  try {
    marker.writeAsStringSync('$key:$count');
  } catch (_) {}
  return count;
}

/// Bumped whenever the picture-book check changes, so a book an older check
/// turned down gets looked at again.
const imageEpubScanVersion = 2;
