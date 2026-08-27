import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

/// Pure-Dart port of the reader's fuzzy passage matcher (ebook_reader_view's
/// in-WebView JS), for places with no epub.js available - correcting a
/// bookmark transcript against the ebook's real text. Same scoring, same
/// device-tuned thresholds: token bag-of-words narrows candidate windows,
/// character-level Levenshtein on the normalized window ranks them, and a
/// clear winner is required before anything is trusted.

// Accept a match at this similarity, with this margin over the runner-up
// (unless both point at the same spot). Slightly stricter than the reader's
// jump gate: a wrong jump is undoable, a wrong note replacement is silent.
const double _acceptFine = 0.68;
const double _margin = 0.05;

final RegExp _tokenRe = RegExp(r"[\p{L}\p{N}']+", unicode: true);

/// Locate [args.transcript] in the EPUB at [args.epubPath] and return the
/// book's own text for that passage, snapped to sentence boundaries - or null
/// when no confident match exists. Runs standalone so it can go through
/// compute(); a whole-book scan takes well under a second in an isolate.
String? correctFromEpub(({String epubPath, String transcript}) args) {
  // Whisper sometimes emits bracketed non-speech tags; they'd poison matching.
  final query = args.transcript
      .replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final qTokens =
      _tokenRe.allMatches(query.toLowerCase()).map((m) => m.group(0)!).toList();
  if (qTokens.length < 3) return null;

  final List<String> sections;
  try {
    sections = _epubSectionTexts(args.epubPath);
  } catch (e) {
    debugPrint('[PassageMatch] epub read failed: $e');
    return null;
  }
  if (sections.isEmpty) return null;

  final need = <String, int>{};
  for (final t in qTokens) {
    need[t] = (need[t] ?? 0) + 1;
  }
  final qNorm = qTokens.join(' ');
  final w = qTokens.length;

  _Candidate? best;
  _Candidate? second;
  void offer(_Candidate c) {
    if (best == null || c.fine > best!.fine) {
      second = best;
      best = c;
    } else if (second == null || c.fine > second!.fine) {
      second = c;
    }
  }

  for (var si = 0; si < sections.length; si++) {
    final text = sections[si];
    final toks = _tokenRe
        .allMatches(text.toLowerCase())
        .map((m) => (t: m.group(0)!, s: m.start, e: m.end))
        .toList();
    if (toks.length < 3) continue;

    // Rolling multiset intersection over a query-sized token window.
    final have = <String, int>{};
    var matched = 0;
    final cands = <({int i, int m})>[];
    for (var p = 0; p < toks.length; p++) {
      final tk = toks[p].t;
      have[tk] = (have[tk] ?? 0) + 1;
      if (have[tk]! <= (need[tk] ?? 0)) matched++;
      if (p >= w) {
        final old = toks[p - w].t;
        if (have[old]! <= (need[old] ?? 0)) matched--;
        have[old] = have[old]! - 1;
      }
      if (matched >= (w * 0.4).floor().clamp(2, w)) {
        cands.add((i: (p - w + 1).clamp(0, toks.length - 1), m: matched));
      }
    }
    cands.sort((a, b) => b.m.compareTo(a.m));
    final used = <int>[];
    for (final c in cands) {
      if (used.length >= 4) break;
      if (used.any((u) => (u - c.i).abs() < w)) continue;
      used.add(c.i);
      final s1 = c.i;
      final e1 = (s1 + w - 1).clamp(0, toks.length - 1);
      final winNorm =
          toks.sublist(s1, e1 + 1).map((x) => x.t).join(' ');
      final dl = _levenshtein(qNorm, winNorm);
      final fine = 1 -
          dl / (qNorm.length > winNorm.length ? qNorm.length : winNorm.length);
      offer(_Candidate(si, toks[s1].s, toks[e1].e, fine));
    }
  }

  final b = best;
  if (b == null) return null;
  final s = second;
  final sameSpot =
      s != null && s.section == b.section && (s.start - b.start).abs() < 200;
  final confident = b.fine >= _acceptFine &&
      (s == null || sameSpot || b.fine - s.fine >= _margin);
  debugPrint('[PassageMatch] best fine=${b.fine.toStringAsFixed(3)} '
      'second=${s?.fine.toStringAsFixed(3)} sameSpot=$sameSpot '
      'confident=$confident');
  if (!confident) return null;
  return _snapToSentences(sections[b.section], b.start, b.end);
}

/// What the book says next, after a matched passage.
typedef PassageWithNext = ({String passage, String continuation});

/// [correctFromEpub], plus the book's next couple of sentences after the
/// matched passage. The continuation is text the audio window never reached -
/// the live transcript shows it as an estimated preview until the real
/// transcription of that stretch lands.
PassageWithNext? correctFromEpubWithNext(
    ({String epubPath, String transcript}) args) {
  final passage = correctFromEpub(args);
  if (passage == null) return null;
  // Find the passage again to know where it ends. Cheap next to the match
  // itself, and it keeps correctFromEpub's shape untouched for its other
  // callers.
  try {
    for (final text in _epubSectionTexts(args.epubPath)) {
      final normalized = text.replaceAll(RegExp(r'\s+'), ' ');
      final idx = normalized.indexOf(passage);
      if (idx < 0) continue;
      return (
        passage: passage,
        continuation: _followingSentences(normalized, idx + passage.length),
      );
    }
  } catch (e) {
    debugPrint('[PassageMatch] continuation lookup failed: $e');
  }
  return (passage: passage, continuation: '');
}

/// Up to two sentences (bounded) after [from], for the estimated preview.
String _followingSentences(String text, int from) {
  final maxE = (from + 320).clamp(0, text.length);
  var sentences = 0;
  var e = maxE;
  for (var i = from; i < maxE; i++) {
    final c = text[i];
    if (c == '.' || c == '!' || c == '?') {
      var j = i + 1;
      while (j < text.length && const ['"', "'", '”', '’'].contains(text[j])) {
        j++;
      }
      if (++sentences >= 2) {
        e = j;
        break;
      }
    }
  }
  return text.substring(from, e).trim();
}

class _Candidate {
  final int section;
  final int start;
  final int end;
  final double fine;
  const _Candidate(this.section, this.start, this.end, this.fine);
}

/// Text content of every content document in the EPUB. Spine order doesn't
/// matter for matching, so this just takes the (x)html entries as stored.
List<String> _epubSectionTexts(String epubPath) {
  final archive = ZipDecoder().decodeBytes(File(epubPath).readAsBytesSync());
  final out = <String>[];
  for (final f in archive.files) {
    if (!f.isFile) continue;
    final name = f.name.toLowerCase();
    if (!name.endsWith('.xhtml') && !name.endsWith('.html') && !name.endsWith('.htm')) {
      continue;
    }
    final raw = utf8.decode(f.content as List<int>, allowMalformed: true);
    final text = _stripHtml(raw);
    if (text.length > 200) out.add(text);
  }
  return out;
}

String _stripHtml(String html) {
  var s = html
      .replaceAll(RegExp(r'<head[\s\S]*?</head>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<(script|style)[\s\S]*?</\1>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'</(p|div|h[1-6]|li|blockquote)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ');
  s = s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAllMapped(RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)))
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
  // Collapse runs of spaces but keep the newlines - they mark paragraph
  // boundaries for sentence snapping.
  return s.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n\s*'), '\n').trim();
}

int _levenshtein(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (j) => j);
  var cur = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    cur[0] = i;
    final ca = a.codeUnitAt(i - 1);
    for (var j = 1; j <= b.length; j++) {
      final cost = ca == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost]
          .reduce((x, y) => x < y ? x : y);
    }
    final tmp = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[b.length];
}

/// Grow a matched span outward to clean sentence boundaries so the note reads
/// like the book, not like a window that starts and ends mid-sentence.
String _snapToSentences(String text, int start, int end) {
  var s = start;
  var e = end;
  final minS = (start - 220).clamp(0, text.length);
  for (var i = start - 1; i >= minS; i--) {
    final c = text[i];
    if (c == '\n') {
      s = i + 1;
      break;
    }
    if (c == '.' || c == '!' || c == '?') {
      s = i + 1;
      break;
    }
  }
  final maxE = (end + 260).clamp(0, text.length);
  for (var i = end; i < maxE; i++) {
    final c = text[i];
    if (c == '.' || c == '!' || c == '?') {
      var j = i + 1;
      while (j < text.length && const ['"', "'", '”', '’'].contains(text[j])) {
        j++;
      }
      e = j;
      break;
    }
    if (c == '\n') {
      e = i;
      break;
    }
  }
  return text.substring(s, e).trim().replaceAll(RegExp(r'\s+'), ' ');
}
