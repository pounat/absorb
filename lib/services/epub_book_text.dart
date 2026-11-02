import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';

import 'media_overlay.dart';
import '../utils/percent_escapes.dart';

/// A spot found in a book's text: the spine section, where the words start
/// and end in its text, and how well they matched (0 to 1).
typedef TextMatch = ({int si, int s, int e, double fine});

final RegExp _token = RegExp(r"[\p{L}\p{N}']+", unicode: true);

/// Where [transcript] sits in [text], fuzzily: windows of the text holding
/// most of the transcript's words, scored by edit distance over the words.
/// The same scoring the reader runs on a page it has open.
({int s, int e, double fine})? matchTranscript(String text, String transcript) {
  final t = [for (final m in _token.allMatches(transcript)) m.group(0)!.toLowerCase()];
  if (t.length < 3) return null;
  final need = <String, int>{};
  for (final w in t) {
    need[w] = (need[w] ?? 0) + 1;
  }
  final tNorm = t.join(' ');
  final width = t.length;
  final st = [
    for (final m in _token.allMatches(text)) (t: m.group(0)!.toLowerCase(), s: m.start, e: m.end),
  ];
  if (st.length < 3) return null;
  final have = <String, int>{};
  var matched = 0;
  final cands = <({int i, int m})>[];
  final floor = (width * 0.4).floor() > 2 ? (width * 0.4).floor() : 2;
  for (var p = 0; p < st.length; p++) {
    final tk = st[p].t;
    have[tk] = (have[tk] ?? 0) + 1;
    if (have[tk]! <= (need[tk] ?? 0)) matched++;
    if (p >= width) {
      final old = st[p - width].t;
      if (have[old]! <= (need[old] ?? 0)) matched--;
      have[old] = have[old]! - 1;
    }
    if (matched >= floor) cands.add((i: p - width + 1 < 0 ? 0 : p - width + 1, m: matched));
  }
  cands.sort((a, b) => b.m.compareTo(a.m));
  final picked = <({int i, int m})>[];
  for (final c in cands) {
    if (picked.length >= 4) break;
    if (picked.any((p) => (p.i - c.i).abs() < width)) continue;
    picked.add(c);
  }
  ({int s, int e, double fine})? out;
  for (final c in picked) {
    final e1 = c.i + width - 1 < st.length - 1 ? c.i + width - 1 : st.length - 1;
    final win = [for (var k = c.i; k <= e1; k++) st[k].t].join(' ');
    final longest = tNorm.length > win.length ? tNorm.length : win.length;
    final fine = 1 - _levenshtein(tNorm, win) / longest;
    if (out == null || fine > out.fine) out = (s: st[c.i].s, e: st[e1].e, fine: fine);
  }
  return out;
}

int _levenshtein(String a, String b) {
  final m = a.length, n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  var prev = List<int>.generate(n + 1, (j) => j);
  var cur = List<int>.filled(n + 1, 0);
  for (var x = 1; x <= m; x++) {
    cur[0] = x;
    final ca = a.codeUnitAt(x - 1);
    for (var j = 1; j <= n; j++) {
      final cost = ca == b.codeUnitAt(j - 1) ? 0 : 1;
      final del = prev[j] + 1, ins = cur[j - 1] + 1, sub = prev[j - 1] + cost;
      cur[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    final tmp = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[n];
}

class _Section {
  _Section(this.root, this.nodes, this.starts, this.text);

  /// The html element.
  final html.Element root;
  final List<html.Text> nodes;
  final List<int> starts;
  final String text;
}

/// Text nodes directly under [parent], in order.
List<html.Text> _textKids(html.Node parent) => parent.nodes.whereType<html.Text>().toList();

/// An EPUB's text as the reader's pages hold it, read straight from the
/// file: each spine section's body text, the table of contents, and CFIs to
/// and from a spot in that text in the form the reader writes them. Lets a
/// place be found and saved with no reader open.
///
/// Sections are parsed as HTML, as the reader's epub.js does (it loads each
/// one through an iframe's srcdoc), so the text nodes, offsets and element
/// counts are the browser's: a self-closing `<span/>` swallows what follows
/// it, a table gains its tbody. Parsing as XML would place CFIs elsewhere.
class EpubBookText {
  EpubBookText._(this._input, this._archive, this.spine, this._paths, this.toc, this._spineStep,
      this.hasMediaOverlays);

  final InputFileStream _input;
  final Archive _archive;

  /// Spine hrefs in reading order, as the package lists them.
  final List<String> spine;
  final List<String> _paths;

  /// The table of contents, flattened in reading order.
  final List<({String href, String title})> toc;
  final int _spineStep;

  /// The EPUB carries its own narration (EPUB 3 media overlays).
  final bool hasMediaOverlays;

  final Map<int, _Section?> _sections = {};

  /// Opens the EPUB at [path]. Null when it isn't one.
  static EpubBookText? open(String path) {
    final input = InputFileStream(path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final book = _read(input, archive);
      if (book == null) input.closeSync();
      return book;
    } catch (_) {
      input.closeSync();
      return null;
    }
  }

  void close() => _input.closeSync();

  static String? _file(Archive archive, String name) {
    final f = archive.findFile(name);
    return f == null ? null : utf8.decode(f.content as List<int>, allowMalformed: true);
  }

  static XmlDocument? _xml(String? source) {
    if (source == null) return null;
    try {
      return XmlDocument.parse(source, entityMapping: XmlDefaultEntityMapping.html5());
    } catch (_) {
      return null;
    }
  }

  static String _dir(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i + 1);
  }

  static String _resolve(String base, String href) {
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

  static String _flat(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  static EpubBookText? _read(InputFileStream input, Archive archive) {
    final container = _xml(_file(archive, 'META-INF/container.xml'));
    final opfPath = container?.descendantElements
        .where((e) => e.localName == 'rootfile')
        .map((e) => e.getAttribute('full-path'))
        .firstWhere((p) => p != null, orElse: () => null);
    if (opfPath == null) return null;
    final opf = _xml(_file(archive, opfPath));
    final package = opf?.rootElement;
    if (package == null) return null;
    final children = package.childElements.toList();
    final spineEl = children.where((e) => e.localName == 'spine').firstOrNull;
    final manifestEl = children.where((e) => e.localName == 'manifest').firstOrNull;
    if (spineEl == null || manifestEl == null) return null;
    final manifest = <String, ({String href, String path, String type, String props})>{};
    var overlays = false;
    for (final item in manifestEl.childElements.where((e) => e.localName == 'item')) {
      final id = item.getAttribute('id'), href = item.getAttribute('href');
      if (id == null || href == null) continue;
      if (item.getAttribute('media-overlay') != null) overlays = true;
      manifest[id] = (
        href: href,
        path: _resolve(opfPath, href),
        type: item.getAttribute('media-type') ?? '',
        props: item.getAttribute('properties') ?? '',
      );
    }
    final spine = <String>[];
    final paths = <String>[];
    for (final ref in spineEl.childElements.where((e) => e.localName == 'itemref')) {
      final item = manifest[ref.getAttribute('idref')];
      spine.add(item?.href ?? '');
      paths.add(item?.path ?? '');
    }
    final toc = <({String href, String title})>[];
    final nav = manifest.values.where((v) => v.props.split(' ').contains('nav')).firstOrNull;
    if (nav != null) {
      final doc = _xml(_file(archive, nav.path));
      final navs = doc?.descendantElements.where((e) => e.localName == 'nav').toList() ?? const [];
      final tocNav = navs
              .where((e) => e.attributes.any((a) => a.localName == 'type' && a.value.split(' ').contains('toc')))
              .firstOrNull ??
          navs.firstOrNull;
      for (final a in tocNav?.descendantElements.where((e) => e.localName == 'a') ?? const <XmlElement>[]) {
        final href = a.getAttribute('href');
        if (href == null) continue;
        toc.add((href: _resolve(nav.path, href) + (href.contains('#') ? '#${href.split('#').last}' : ''),
            title: _flat(a.innerText)));
      }
    }
    if (toc.isEmpty) {
      final ncxId = spineEl.getAttribute('toc');
      final ncx = manifest[ncxId] ??
          manifest.values.where((v) => v.type == 'application/x-dtbncx+xml').firstOrNull;
      if (ncx != null) {
        final doc = _xml(_file(archive, ncx.path));
        for (final point in doc?.descendantElements.where((e) => e.localName == 'navPoint') ?? const <XmlElement>[]) {
          final src = point.childElements.where((e) => e.localName == 'content').firstOrNull?.getAttribute('src');
          final label = point.childElements.where((e) => e.localName == 'navLabel').firstOrNull;
          if (src == null || label == null) continue;
          toc.add((href: _resolve(ncx.path, src) + (src.contains('#') ? '#${src.split('#').last}' : ''),
              title: _flat(label.innerText)));
        }
      }
    }
    return EpubBookText._(input, archive, spine, paths, toc, (children.indexOf(spineEl) + 1) * 2, overlays);
  }

  _Section? _section(int si) {
    if (si < 0 || si >= _paths.length) return null;
    return _sections.putIfAbsent(si, () {
      final source = _file(_archive, _paths[si]);
      if (source == null) return null;
      final doc = html_parser.parse(source);
      final root = doc.documentElement;
      final body = doc.body;
      if (root == null || body == null) return null;
      final nodes = <html.Text>[];
      void walk(html.Node n) {
        for (final c in n.nodes) {
          if (c is html.Text) {
            nodes.add(c);
          } else if (c is html.Element) {
            walk(c);
          }
        }
      }

      walk(body);
      final starts = <int>[];
      final buf = StringBuffer();
      for (final n in nodes) {
        starts.add(buf.length);
        buf.write(n.data);
      }
      return _Section(root, nodes, starts, buf.toString());
    });
  }

  String sectionText(int si) => _section(si)?.text ?? '';

  int sectionLength(int si) => sectionText(si).length;

  /// The spine index of the document [href] names, as a media overlay or the
  /// package names it, or -1.
  int sectionOf(String href) {
    for (var i = 0; i < spine.length; i++) {
      if (MediaOverlay.sameDoc(spine[i], href)) return i;
      if (i < _paths.length && MediaOverlay.sameDoc(_paths[i], href)) return i;
    }
    return -1;
  }

  /// The text of the element [id] in section [si], spaces tidied. Null when
  /// the section has no such element.
  String? elementText(int si, String id) {
    final s = _section(si);
    if (s == null) return null;
    html.Element? find(html.Element e) {
      if (e.id == id) return e;
      for (final c in e.children) {
        final hit = find(c);
        if (hit != null) return hit;
      }
      return null;
    }

    final el = find(s.root);
    return el == null ? null : _flat(el.text);
  }

  /// Where each element with an id starts in section [si]'s text: the
  /// offset of its first text. Elements with no text are left out.
  Map<String, int> elementOffsets(int si) {
    final s = _section(si);
    if (s == null) return const {};
    final out = <String, int>{};
    for (var k = 0; k < s.nodes.length; k++) {
      for (html.Node? up = s.nodes[k].parent; up != null; up = up.parent) {
        if (up is html.Element && up.id.isNotEmpty) out.putIfAbsent(up.id, () => s.starts[k]);
        if (identical(up, s.root)) break;
      }
    }
    return out;
  }

  /// The TOC title for a spine href, matched the way the reader matches it:
  /// by file name first, then by the end of the path.
  String? chapterForHref(String href) {
    if (href.isEmpty || toc.isEmpty) return null;
    String base(String s) => undoPercentEscapes(s.split('#').first.split('/').last).toLowerCase();

    String? label(String t) => t.trim().isEmpty ? null : t.trim();
    final b = base(href);
    if (b.isNotEmpty) {
      for (final c in toc) {
        if (base(c.href) == b) return label(c.title);
      }
    }
    final path = href.split('#').first;
    for (final c in toc) {
      final p = c.href.split('#').first;
      if (p.isEmpty) continue;
      if (path.endsWith(p) || p.endsWith(path)) return label(c.title);
    }
    return null;
  }

  /// How far through the whole book's text [offset] in section [si] is.
  double fraction(int si, int offset) {
    var before = 0, total = 0;
    for (var i = 0; i < spine.length; i++) {
      final n = sectionLength(i);
      if (i < si) before += n;
      total += n;
    }
    return total <= 0 ? 0 : ((before + offset) / total).clamp(0.0, 1.0);
  }

  /// Where [transcript] is in the book: the best-matching passage of any
  /// section, the one nearest [near] (a fraction of the book) when two
  /// match about as well. Null under [minFine].
  TextMatch? findPassage(String transcript, {double? near, double minFine = 0.6}) {
    final hits = <TextMatch>[];
    for (var si = 0; si < spine.length; si++) {
      final m = matchTranscript(sectionText(si), transcript);
      if (m != null && m.fine >= minFine) hits.add((si: si, s: m.s, e: m.e, fine: m.fine));
    }
    if (hits.isEmpty) return null;
    hits.sort((a, b) => b.fine.compareTo(a.fine));
    final top = hits.where((h) => hits.first.fine - h.fine <= 0.05).toList();
    if (near == null || top.length == 1) return top.first;
    top.sort((a, b) => (fraction(a.si, a.s) - near).abs().compareTo((fraction(b.si, b.s) - near).abs()));
    return top.first;
  }

  /// The CFI for [offset] in section [si], in the form the reader writes:
  /// `epubcfi(/6/34!/4[body-id]/2/10/1:33)`. Null when the section has no
  /// parsed text.
  String? cfiAt(int si, int offset) {
    final s = _section(si);
    if (s == null || s.nodes.isEmpty) return null;
    final root = s.root;
    var k = s.nodes.length - 1;
    for (var i = 0; i < s.nodes.length; i++) {
      if (offset < s.starts[i] + s.nodes[i].data.length) {
        k = i;
        break;
      }
    }
    final node = s.nodes[k];
    final local = (offset - s.starts[k]).clamp(0, node.data.length);
    final parent = node.parent;
    if (parent == null) return null;
    final steps = <String>['${1 + 2 * _textKids(parent).indexOf(node)}'];
    for (html.Element? el = parent; el != null && !identical(el, root); el = el.parent) {
      final up = el.parent;
      if (up == null) break;
      final id = el.attributes['id'];
      steps.add('${(up.children.indexOf(el) + 1) * 2}${id == null || id.isEmpty ? '' : '[$id]'}');
    }
    return 'epubcfi(/$_spineStep/${(si + 1) * 2}!/${steps.reversed.join('/')}:$local)';
  }

  /// The section and text offset a CFI points at (a range's start). Null
  /// when it doesn't resolve in this book.
  ({int si, int offset})? locate(String cfi) {
    final m = RegExp(r'^epubcfi\((.*)\)$').firstMatch(cfi.trim());
    if (m == null) return null;
    final inner = m.group(1)!;
    final bang = inner.indexOf('!');
    if (bang < 0) return null;
    final pkg = inner.substring(0, bang).split('/').where((p) => p.isNotEmpty).toList();
    if (pkg.isEmpty) return null;
    final spineStep = int.tryParse(pkg.last.split('[').first);
    if (spineStep == null || spineStep < 2) return null;
    final si = spineStep ~/ 2 - 1;
    final parts = inner.substring(bang + 1).split(',');
    final path = parts.length > 1 ? parts[0] + parts[1] : parts[0];
    final s = _section(si);
    if (s == null) return null;
    var term = 0;
    var steps = path;
    final colon = path.lastIndexOf(':');
    if (colon >= 0) {
      term = int.tryParse(path.substring(colon + 1).split('[').first) ?? 0;
      steps = path.substring(0, colon);
    }
    html.Element el = s.root;
    html.Text? text;
    for (final raw in steps.split('/').where((p) => p.isNotEmpty)) {
      final n = int.tryParse(raw.split('[').first);
      if (n == null || text != null) return null;
      if (n.isEven) {
        final kids = el.children;
        final i = n ~/ 2 - 1;
        if (i < 0 || i >= kids.length) return null;
        el = kids[i];
      } else {
        final kids = _textKids(el);
        final i = (n - 1) ~/ 2;
        if (i < 0 || i >= kids.length) return null;
        text = kids[i];
      }
    }
    if (text != null) {
      final k = s.nodes.indexOf(text);
      if (k < 0) return null;
      return (si: si, offset: s.starts[k] + term.clamp(0, text.data.length));
    }
    // An element: where its first text starts.
    for (var k = 0; k < s.nodes.length; k++) {
      for (html.Node? up = s.nodes[k].parent; up != null; up = up.parent) {
        if (identical(up, el)) return (si: si, offset: s.starts[k]);
      }
    }
    return null;
  }
}

/// Book time of the narrated sentence a reading spot [cfi] falls in: the
/// last one in its section to start at or before it, or the section's first
/// when the spot comes before them all. Null when the spot isn't in [book] or
/// its section isn't narrated.
double? narrationTimeAtCfi(MediaOverlay overlay, EpubBookText book, String cfi) =>
    placeCfiOnNarration(overlay, book, cfi).seconds;

/// [narrationTimeAtCfi], with how the spot was found or why it wasn't.
/// Another reader's CFI can count a chapter's elements differently (an XML
/// parse against this HTML one), so the ids it names are tried first: a
/// narrated sentence it names is the answer outright, and any other named
/// element gives a place in the text when the steps don't resolve here.
({double? seconds, String how}) placeCfiOnNarration(MediaOverlay overlay, EpubBookText book, String cfi) {
  final m = RegExp(r'^epubcfi\((.*)\)$').firstMatch(cfi.trim());
  final bang = m?.group(1)?.indexOf('!') ?? -1;
  if (m == null || bang < 0) return (seconds: null, how: 'not a CFI');
  final inner = m.group(1)!;
  final pkg = inner.substring(0, bang).split('/').where((p) => p.isNotEmpty).toList();
  final spineStep = pkg.isEmpty ? null : int.tryParse(pkg.last.split('[').first);
  if (spineStep == null || spineStep < 2) return (seconds: null, how: 'no chapter in the CFI');
  final si = spineStep ~/ 2 - 1;
  final sectionOfHref = <String, int>{};
  final clips = [
    for (final c in overlay.clips)
      if (c.fragment != null && sectionOfHref.putIfAbsent(c.textHref, () => book.sectionOf(c.textHref)) == si) c,
  ];
  if (clips.isEmpty) return (seconds: null, how: 'chapter $si is not narrated');
  // The ids the CFI names, deepest first, leaving out text assertions.
  final ids = [
    for (final a in RegExp(r'\[([^\]]*)\]').allMatches(inner.substring(bang + 1)))
      if (a.group(1)!.isNotEmpty && !a.group(1)!.startsWith(';')) a.group(1)!.split(';').first,
  ].reversed.toList();
  for (final id in ids) {
    for (final c in clips) {
      if (c.fragment == id) return (seconds: overlay.startOf(c), how: 'it names sentence $id');
    }
  }
  final offsets = book.elementOffsets(si);
  var target = book.locate(cfi)?.offset;
  var how = 'its place in chapter $si';
  if (target == null) {
    for (final id in ids) {
      final off = offsets[id];
      if (off != null) {
        target = off;
        how = 'the element $id it names';
        break;
      }
    }
  }
  if (target == null) return (seconds: null, how: 'its steps and ids are not in chapter $si here');
  OverlayClip? best;
  var bestOffset = -1;
  for (final c in clips) {
    final off = offsets[c.fragment];
    if (off == null || off > target) continue;
    if (off >= bestOffset) {
      best = c;
      bestOffset = off;
    }
  }
  final pick = best ?? clips.first;
  return (seconds: overlay.startOf(pick), how: how);
}
