import 'dart:convert';
import 'dart:math';

import 'package:archive/archive_io.dart';

/// One narrated sentence: where its text is and which stretch of which audio
/// file reads it.
class OverlayClip {
  final int section;
  final String textHref;
  final String? fragment;
  final int track;
  final double begin;
  final double end;

  const OverlayClip({
    required this.section,
    required this.textHref,
    required this.fragment,
    required this.track,
    required this.begin,
    required this.end,
  });
}

/// An audio file inside the EPUB, placed on the book's timeline.
class OverlayTrack {
  final String href;
  final String mediaType;
  final double duration;
  final double start;

  const OverlayTrack(this.href, this.mediaType, this.duration, this.start);
}

/// A narrated chapter (spine item) and where its narration starts.
class OverlaySection {
  final int index;
  final String href;
  final String? label;
  final double start;

  const OverlaySection(this.index, this.href, this.label, this.start);
}

class _RawClip {
  final int section;
  final String textHref;
  final String? fragment;
  final String audioHref;
  final double begin;
  double? end;
  _RawClip(this.section, this.textHref, this.fragment, this.audioHref, this.begin, this.end);
}

/// An EPUB 3 media overlay (a narrated or "read along" EPUB) laid out the way
/// the player sees it: the audio files end to end, each sentence a stretch of
/// one file. Built from BookOrbit's playlist or straight from the EPUB.
class MediaOverlay {
  final List<OverlayTrack> tracks;
  final List<OverlayClip> clips;
  final List<OverlaySection> sections;
  final List<List<int>> _byTrack;

  MediaOverlay._(this.tracks, this.clips, this.sections)
      : _byTrack = List.generate(tracks.length, (_) => <int>[]) {
    for (var i = 0; i < clips.length; i++) {
      _byTrack[clips[i].track].add(i);
    }
    for (final list in _byTrack) {
      list.sort((a, b) => clips[a].begin.compareTo(clips[b].begin));
    }
  }

  double get duration => tracks.isEmpty ? 0 : tracks.last.start + tracks.last.duration;

  bool get isEmpty => clips.isEmpty;

  static MediaOverlay? _build(
    List<_RawClip> raw, {
    required Map<String, String> mediaTypes,
    required Map<int, ({String href, String? label})> sectionInfo,
  }) {
    if (raw.isEmpty) return null;
    final order = <String, int>{};
    for (final c in raw) {
      order.putIfAbsent(c.audioHref, () => order.length);
    }
    // A clip with no end runs to the next clip in the same file.
    final byFile = <String, List<_RawClip>>{};
    for (final c in raw) {
      (byFile[c.audioHref] ??= []).add(c);
    }
    for (final list in byFile.values) {
      list.sort((a, b) => a.begin.compareTo(b.begin));
      for (var i = 0; i < list.length; i++) {
        if (list[i].end != null) continue;
        list[i].end = i + 1 < list.length ? list[i + 1].begin : list[i].begin;
      }
    }
    final tracks = <OverlayTrack>[];
    var start = 0.0;
    for (final href in order.keys) {
      final d = byFile[href]!.fold<double>(0, (m, c) => max(m, c.end ?? c.begin));
      tracks.add(OverlayTrack(href, mediaTypes[href] ?? _guessType(href), d, start));
      start += d;
    }
    final clips = [
      for (final c in raw)
        OverlayClip(
          section: c.section,
          textHref: c.textHref,
          fragment: c.fragment,
          track: order[c.audioHref]!,
          begin: c.begin,
          end: c.end ?? c.begin,
        ),
    ];
    final sections = <OverlaySection>[];
    final seen = <int>{};
    for (final c in clips) {
      if (!seen.add(c.section)) continue;
      final info = sectionInfo[c.section];
      sections.add(OverlaySection(
        c.section,
        info?.href ?? c.textHref,
        info?.label,
        tracks[c.track].start + c.begin,
      ));
    }
    sections.sort((a, b) => a.start.compareTo(b.start));
    return MediaOverlay._(tracks, clips, sections);
  }

  static String _guessType(String href) {
    final ext = href.split('.').last.toLowerCase();
    return switch (ext) {
      'mp3' => 'audio/mpeg',
      'm4a' || 'm4b' || 'mp4' || 'aac' => 'audio/mp4',
      'ogg' || 'oga' || 'opus' => 'audio/ogg',
      'wav' => 'audio/wav',
      _ => 'application/octet-stream',
    };
  }

  /// The track playing at book time [t].
  int trackAt(double t) {
    var lo = 0, hi = tracks.length - 1, ans = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (tracks[mid].start <= t) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }

  /// The sentence being read at book time [t]: the last one to have started
  /// in the file playing then, so the gap after a sentence keeps it lit.
  OverlayClip? clipAt(double t) {
    if (tracks.isEmpty) return null;
    final track = trackAt(t);
    final local = t - tracks[track].start;
    final list = _byTrack[track];
    var lo = 0, hi = list.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (clips[list[mid]].begin <= local + 0.001) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (ans < 0) return list.isEmpty ? null : clips[list.first];
    return clips[list[ans]];
  }

  /// Book time where [clip] starts.
  double startOf(OverlayClip clip) => tracks[clip.track].start + clip.begin;

  static bool sameDoc(String a, String b) {
    if (a == b) return true;
    final x = a.split('#').first, y = b.split('#').first;
    return x == y || x.endsWith('/$y') || y.endsWith('/$x');
  }

  /// The first sentence whose element is [fragment] in [href], or the first
  /// one in [href] when the fragment isn't narrated.
  OverlayClip? clipFor(String href, String? fragment) {
    OverlayClip? first;
    for (final c in clips) {
      if (!sameDoc(c.textHref, href)) continue;
      first ??= c;
      if (fragment != null && c.fragment == fragment) return c;
    }
    return first;
  }

  /// The chapters Absorb shows. With the book's contents to go by, each
  /// named section starts a chapter and the sections after it that the
  /// contents leave out carry it on (one chapter split over several files),
  /// and an unnamed opening, such as the title read aloud, joins the first
  /// chapter. A book with no usable contents gets one chapter per section.
  List<Map<String, dynamic>> chapters() {
    final named = sections.any((s) => s.label?.trim().isNotEmpty == true);
    final out = <Map<String, dynamic>>[];
    var openingUnnamed = false;
    for (var i = 0; i < sections.length; i++) {
      final s = sections[i];
      final end = i + 1 < sections.length ? sections[i + 1].start : duration;
      if (end <= s.start) continue;
      final label = s.label?.trim() ?? '';
      if (named && label.isEmpty && out.isNotEmpty) {
        out.last['end'] = end;
        continue;
      }
      if (out.isEmpty) openingUnnamed = named && label.isEmpty;
      out.add({
        'id': out.length,
        'start': s.start,
        'end': end,
        'title': label.isNotEmpty ? label : 'Chapter ${out.length + 1}',
      });
    }
    if (openingUnnamed && out.length > 1) {
      out[1]['start'] = out[0]['start'];
      out.removeAt(0);
      for (var i = 0; i < out.length; i++) {
        out[i]['id'] = i;
      }
    }
    return out;
  }

  /// The sections named from the book's contents: [spine] is every file in
  /// reading order, [labels] the first contents entry pointing into each.
  /// An entry on a file with no narration (a chapter's title page) names
  /// the next narrated file the contents leave out.
  MediaOverlay withContents(List<String> spine, Map<String, String> labels) {
    final names = <int, String?>{};
    String? pending;
    for (final href in spine) {
      final own = labels[href];
      OverlaySection? section;
      for (final s in sections) {
        if (sameDoc(s.href, href)) {
          section = s;
          break;
        }
      }
      if (section == null) {
        if (own != null) pending = own;
        continue;
      }
      names[section.index] = own ?? pending ?? section.label;
      pending = null;
    }
    return MediaOverlay._(tracks, clips, [
      for (final s in sections)
        OverlaySection(s.index, s.href, names.containsKey(s.index) ? names[s.index] : s.label, s.start),
    ]);
  }

  /// Audiobookshelf-shaped audio tracks, with [url] giving each file's address.
  List<Map<String, dynamic>> audioTracks(String Function(OverlayTrack track) url) => [
        for (var i = 0; i < tracks.length; i++)
          {
            'index': i + 1,
            'startOffset': tracks[i].start,
            'duration': tracks[i].duration,
            'title': tracks[i].href.split('/').last,
            'contentUrl': url(tracks[i]),
            'mimeType': tracks[i].mediaType,
            // Numbered, so same-named files in different folders can't collide.
            'metadata': {'filename': '${(i + 1).toString().padLeft(3, '0')} ${tracks[i].href.split('/').last}'},
          },
      ];

  /// The same narration laid out on each audio file's measured length. A
  /// missing measurement, or one shorter than the file's last sentence, keeps
  /// the length the timings imply.
  MediaOverlay withTrackDurations(List<double?> measured) {
    final laid = <OverlayTrack>[];
    var start = 0.0;
    for (var i = 0; i < tracks.length; i++) {
      final m = i < measured.length ? measured[i] : null;
      final d = m != null && m >= tracks[i].duration - 0.5 ? m : tracks[i].duration;
      laid.add(OverlayTrack(tracks[i].href, tracks[i].mediaType, d, start));
      start += d;
    }
    final first = <int, OverlayClip>{};
    for (final c in clips) {
      first.putIfAbsent(c.section, () => c);
    }
    final secs = [
      for (final s in sections)
        OverlaySection(s.index, s.href, s.label,
            first[s.index] == null ? s.start : laid[first[s.index]!.track].start + first[s.index]!.begin),
    ];
    return MediaOverlay._(laid, clips, secs);
  }

  /// The clip in this narration reading the same sentence as [other], which
  /// may come from an earlier layout of it.
  OverlayClip? sameClip(OverlayClip other) {
    for (final c in clips) {
      if (c.fragment == other.fragment && c.textHref == other.textHref && c.begin == other.begin) return c;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'tracks': [
          for (final t in tracks)
            {'href': t.href, 'type': t.mediaType, 'duration': t.duration, 'start': t.start},
        ],
        'clips': [
          for (final c in clips)
            [c.section, c.textHref, c.fragment, c.track, c.begin, c.end],
        ],
        'sections': [
          for (final s in sections) {'index': s.index, 'href': s.href, 'label': s.label, 'start': s.start},
        ],
      };

  static MediaOverlay? fromJson(Map<String, dynamic> j) {
    try {
      final tracks = [
        for (final t in (j['tracks'] as List<dynamic>).cast<Map<String, dynamic>>())
          OverlayTrack(t['href'] as String, t['type'] as String, (t['duration'] as num).toDouble(),
              (t['start'] as num).toDouble()),
      ];
      final clips = [
        for (final c in (j['clips'] as List<dynamic>).cast<List<dynamic>>())
          OverlayClip(
            section: (c[0] as num).toInt(),
            textHref: c[1] as String,
            fragment: c[2] as String?,
            track: (c[3] as num).toInt(),
            begin: (c[4] as num).toDouble(),
            end: (c[5] as num).toDouble(),
          ),
      ];
      final sections = [
        for (final s in (j['sections'] as List<dynamic>).cast<Map<String, dynamic>>())
          OverlaySection((s['index'] as num).toInt(), s['href'] as String, s['label'] as String?,
              (s['start'] as num).toDouble()),
      ];
      if (tracks.isEmpty || clips.isEmpty) return null;
      return MediaOverlay._(tracks, clips, sections);
    } catch (_) {
      return null;
    }
  }

  /// From BookOrbit's `/epub/:bookId/media-overlay` playlist.
  static MediaOverlay? fromBookOrbit(Map<String, dynamic> playlist) {
    final types = <String, String>{
      for (final r in (playlist['resources'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>())
        if (r['href'] is String) r['href'] as String: r['mediaType'] as String? ?? '',
    };
    final sectionInfo = <int, ({String href, String? label})>{
      for (final s in (playlist['sections'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>())
        if (s['index'] is num && s['href'] is String)
          (s['index'] as num).toInt(): (href: s['href'] as String, label: s['label'] as String?),
    };
    final raw = <_RawClip>[];
    for (final i in (playlist['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>()) {
      final audio = i['audioHref'] as String?;
      final text = i['textHref'] as String?;
      final begin = (i['clipBeginSeconds'] as num?)?.toDouble();
      if (audio == null || text == null || begin == null) continue;
      final section = (i['sectionIndex'] as num?)?.toInt() ?? 0;
      raw.add(_RawClip(section, text, i['textFragment'] as String?, audio, begin,
          (i['clipEndSeconds'] as num?)?.toDouble()));
      if (!sectionInfo.containsKey(section) && i['label'] is String) {
        sectionInfo[section] = (href: text, label: i['label'] as String);
      }
    }
    types.removeWhere((_, v) => v.isEmpty);
    return _build(raw, mediaTypes: types, sectionInfo: sectionInfo);
  }

  /// Straight from an EPUB's package and SMIL files. Null when the book has
  /// no narration.
  static Future<MediaOverlay?> fromEpub(Archive archive) =>
      fromFiles((name) async => _text(archive, name));

  /// The same, with the EPUB's files read through [load] (a local zip, or
  /// range requests to one on the server). [onNarrated] hears as soon as the
  /// package shows the book reads itself aloud, with the length it states,
  /// before the timing files are read.
  static Future<MediaOverlay?> fromFiles(
    Future<String?> Function(String name) load, {
    void Function(double? duration)? onNarrated,
  }) async {
    final container = await load('META-INF/container.xml');
    if (container == null) return null;
    final rootfile = _rootfileTag.firstMatch(container);
    final opfPath = rootfile == null ? null : _attrs(rootfile.group(0)!)['full-path'];
    if (opfPath == null) return null;
    final opf = await load(opfPath);
    if (opf == null) return null;

    final byId = <String, ({String href, String type, String? overlay, String props})>{};
    for (final m in _itemTag.allMatches(opf)) {
      final a = _attrs(m.group(0)!);
      final id = a['id'], href = a['href'];
      if (id == null || href == null) continue;
      byId[id] = (
        href: _resolve(opfPath, href),
        type: a['media-type'] ?? '',
        overlay: a['media-overlay'],
        props: a['properties'] ?? '',
      );
    }
    final types = {for (final v in byId.values) v.href: v.type};
    final overlayIds = {for (final v in byId.values) if (v.overlay != null) v.overlay!};
    if (overlayIds.isEmpty) return null;
    onNarrated?.call(_packageDuration(opf));
    final labels = await _navLabels(load, byId.values.where((v) => v.props.split(' ').contains('nav')).map((v) => v.href));

    // On a server each timing file is a request of its own, so they come a
    // few at a time; one after another took half a minute on a big book.
    final smilPaths = <String>[];
    for (final m in _itemrefTag.allMatches(opf)) {
      final ref = _attrs(m.group(0)!)['idref'];
      final overlayId = ref == null ? null : byId[ref]?.overlay;
      final path = overlayId == null ? null : byId[overlayId]?.href;
      if (path != null && !smilPaths.contains(path)) smilPaths.add(path);
    }
    final smils = <String, String?>{};
    for (var i = 0; i < smilPaths.length; i += 8) {
      final batch = smilPaths.sublist(i, min(i + 8, smilPaths.length));
      final got = await Future.wait(batch.map(load));
      for (var j = 0; j < batch.length; j++) {
        smils[batch[j]] = got[j];
      }
    }

    final raw = <_RawClip>[];
    final sectionInfo = <int, ({String href, String? label})>{};
    final spine = <String>[];
    var index = 0;
    for (final m in _itemrefTag.allMatches(opf)) {
      final spineIndex = index++;
      final ref = _attrs(m.group(0)!)['idref'];
      final item = ref == null ? null : byId[ref];
      if (item != null) spine.add(item.href);
      final overlayId = item?.overlay;
      if (item == null || overlayId == null) continue;
      final smilPath = byId[overlayId]?.href;
      final smil = smilPath == null ? null : smils[smilPath];
      if (smil == null) continue;
      sectionInfo[spineIndex] = (href: item.href, label: labels[item.href]);
      for (final par in _parBlock.allMatches(smil)) {
        final body = par.group(1)!;
        final text = _textTag.firstMatch(body);
        final audio = _audioTag.firstMatch(body);
        if (text == null || audio == null) continue;
        final t = _attrs(text.group(0)!), au = _attrs(audio.group(0)!);
        final src = t['src'], audioSrc = au['src'];
        if (src == null || audioSrc == null) continue;
        final begin = parseClock(au['clipbegin']) ?? 0;
        final hash = src.indexOf('#');
        raw.add(_RawClip(
          spineIndex,
          _resolve(smilPath!, src),
          hash < 0 ? null : Uri.decodeComponent(src.substring(hash + 1)),
          _resolve(smilPath, audioSrc),
          begin,
          parseClock(au['clipend']),
        ));
      }
    }
    return _build(raw, mediaTypes: types, sectionInfo: sectionInfo)?.withContents(spine, labels);
  }

  /// The narration's whole length as the package states it: the
  /// `media:duration` meta that refines nothing. Null when it isn't given.
  static double? _packageDuration(String opf) {
    for (final m in _metaTag.allMatches(opf)) {
      final a = _attrs(m.group(1)!);
      if (a['property'] != 'media:duration' || a.containsKey('refines')) continue;
      return parseClock(m.group(2)!.trim());
    }
    return null;
  }

  static final _metaTag = RegExp(r'<(?:\w+:)?meta\b([^>]*)>([^<]*)</(?:\w+:)?meta>', caseSensitive: false);

  /// [withContents] from BookOrbit's book info: its spine and table of
  /// contents, the first entry in each file.
  MediaOverlay withBookOrbitContents(Map<String, dynamic> info) {
    final spine = [
      for (final s in (info['spine'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>())
        if (s['href'] is String) s['href'] as String,
    ];
    final labels = <String, String>{};
    void visit(Object? node) {
      if (node is! Map) return;
      final href = node['href'], label = node['label'];
      if (href is String && label is String && label.trim().isNotEmpty) {
        labels.putIfAbsent(href.split('#').first, () => label.trim());
      }
      for (final child in (node['children'] as List<dynamic>? ?? const [])) {
        visit(child);
      }
    }

    visit(info['toc']);
    if (spine.isEmpty || labels.isEmpty) return this;
    return withContents(spine, labels);
  }

  /// SMIL clock values: "1:02:03.5", "02:03.5", "12.5s", "250ms", "1.5min",
  /// "2h", or plain seconds.
  static double? parseClock(String? v) {
    if (v == null) return null;
    final s = v.trim();
    if (s.isEmpty) return null;
    if (s.contains(':')) {
      final parts = s.split(':').map((p) => double.tryParse(p.trim())).toList();
      if (parts.any((p) => p == null)) return null;
      return parts.fold<double>(0, (acc, p) => acc * 60 + p!);
    }
    final m = RegExp(r'^([\d.]+)\s*(h|min|s|ms)?$').firstMatch(s);
    if (m == null) return null;
    final n = double.tryParse(m.group(1)!);
    if (n == null) return null;
    return switch (m.group(2)) {
      'h' => n * 3600,
      'min' => n * 60,
      'ms' => n / 1000,
      _ => n,
    };
  }
}

final _attr = RegExp(r'''([\w:.-]+)\s*=\s*("([^"]*)"|'([^']*)')''');
final _itemTag = RegExp(r'<(?:\w+:)?item\b[^>]*>', caseSensitive: false);
final _itemrefTag = RegExp(r'<(?:\w+:)?itemref\b[^>]*>', caseSensitive: false);
final _rootfileTag = RegExp(r'<(?:\w+:)?rootfile\b[^>]*>', caseSensitive: false);
final _parBlock = RegExp(r'<(?:\w+:)?par\b[^>]*>(.*?)</(?:\w+:)?par\s*>', caseSensitive: false, dotAll: true);
final _textTag = RegExp(r'<(?:\w+:)?text\b[^>]*>', caseSensitive: false);
final _audioTag = RegExp(r'<(?:\w+:)?audio\b[^>]*>', caseSensitive: false);
final _navLink = RegExp(r'''<a\b[^>]*href\s*=\s*("([^"]*)"|'([^']*)')[^>]*>(.*?)</a\s*>''', caseSensitive: false, dotAll: true);
final _tags = RegExp(r'<[^>]*>');
final _space = RegExp(r'\s+');

Map<String, String> _attrs(String tag) {
  final out = <String, String>{};
  for (final m in _attr.allMatches(tag)) {
    var name = m.group(1)!.toLowerCase();
    final colon = name.lastIndexOf(':');
    if (colon >= 0 && !name.startsWith('xml')) name = name.substring(colon + 1);
    out.putIfAbsent(name, () => _unescape(m.group(3) ?? m.group(4) ?? ''));
  }
  return out;
}

String _unescape(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');

String _dir(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 ? '' : path.substring(0, i + 1);
}

/// [href] relative to [base]'s folder, as a path inside the zip.
String _resolve(String base, String href) {
  final clean = Uri.decodeFull(href.split('#').first.split('?').first);
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

/// Chapter names from the navigation document, by the file they point at.
Future<Map<String, String>> _navLabels(
    Future<String?> Function(String name) load, Iterable<String> navPaths) async {
  final out = <String, String>{};
  for (final path in navPaths) {
    final doc = await load(path);
    if (doc == null) continue;
    for (final m in _navLink.allMatches(doc)) {
      final href = m.group(2) ?? m.group(3) ?? '';
      final label = _unescape(m.group(4)!.replaceAll(_tags, ' ')).replaceAll(_space, ' ').trim();
      if (href.isEmpty || label.isEmpty) continue;
      out.putIfAbsent(_resolve(path, href), () => label);
    }
  }
  return out;
}
