import '../services/transcript_line_store.dart';

/// Word-level alignment between what Whisper heard and what the book says.
///
/// Whisper gives timestamps per segment, not per word, and the ebook
/// correction hands back a passage in the book's own words that only roughly
/// corresponds to the segments. Spreading that passage over the segment times
/// by character share (the old approach) drifts further the longer a chunk
/// runs, because the book's phrasing and the narrator's pace don't line up
/// character for character.
///
/// So instead: give every heard word a time inside its own segment, then
/// align the book's words onto the heard words and let each one inherit the
/// time of the word it matched. Anchors land every few words rather than
/// every 30 seconds, and text the alignment can't account for is dropped
/// rather than given an invented timestamp.

/// A word and when it is spoken, in the item's own seconds.
class TimedWord {
  final String text;
  final double start;
  final double end;
  const TimedWord(this.text, this.start, this.end);
}

final _wordRe = RegExp(r'\S+');

/// Strip a word down to what two spellings of it have in common, for matching.
String normalizeWord(String w) {
  final buf = StringBuffer();
  for (final c in w.toLowerCase().codeUnits) {
    final isDigit = c >= 0x30 && c <= 0x39;
    final isLower = c >= 0x61 && c <= 0x7A;
    final isApos = c == 0x27;
    if (isDigit || isLower || isApos) buf.writeCharCode(c);
  }
  return buf.toString().replaceAll("'", '');
}

/// Every word of [segments], timed inside its own segment by character share.
/// The segment bounds are real Whisper timestamps, so a word is never more
/// than one segment away from solid ground.
List<TimedWord> wordsFromSegments(
    List<({double start, double end, String text})> segments) {
  final out = <TimedWord>[];
  for (final seg in segments) {
    final text = seg.text;
    final matches = _wordRe.allMatches(text).toList();
    if (matches.isEmpty) continue;
    final span = seg.end - seg.start;
    final chars = text.length;
    double at(int offset) =>
        chars <= 0 ? seg.start : seg.start + span * (offset / chars);
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final start = at(m.start);
      final end = i + 1 < matches.length ? at(matches[i + 1].start) : seg.end;
      out.add(TimedWord(m.group(0)!, start, end < start ? start : end));
    }
  }
  return out;
}

/// True when two words are the same word, allowing for one character of
/// Whisper mishearing on words long enough for that to be a typo rather than
/// a different word.
bool _sameWord(String a, String b) {
  if (a == b) return true;
  if (a.length < 4 || b.length < 4) return false;
  if ((a.length - b.length).abs() > 1) return false;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length == b.length) {
      i++;
      j++;
    } else if (a.length > b.length) {
      i++;
    } else {
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}

/// Result of laying the book's words over the heard ones.
typedef AlignedText = ({List<TimedWord> words, int matched, int total});

/// Time [corrected] (the book's own wording) against [spoken] (what Whisper
/// heard, already timed). Book words that matched a heard word take its time;
/// runs in between are spread across the gap by character share. Text before
/// the first match is dropped, and text after the last match is kept only far
/// enough to finish the sentence in progress - the passage matcher snaps out
/// to sentence boundaries, so anything beyond that was never in this stretch
/// of audio.
///
/// Returns null when too little of the passage lines up to trust it, which
/// leaves the honest Whisper text in place rather than showing the right
/// words at the wrong moments.
AlignedText? alignCorrected(List<TimedWord> spoken, String corrected,
    {double minMatchRatio = 0.5}) {
  if (spoken.isEmpty) return null;
  final bookWords =
      _wordRe.allMatches(corrected).map((m) => m.group(0)!).toList();
  if (bookWords.isEmpty) return null;

  final a = [for (final w in spoken) normalizeWord(w.text)];
  final b = [for (final w in bookWords) normalizeWord(w)];

  // Longest common subsequence over the two word lists; the backtrack gives
  // the pairs that anchor the book's words to real timestamps.
  final n = a.length, m = b.length;
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      dp[i][j] = a[i].isNotEmpty && _sameWord(a[i], b[j])
          ? dp[i + 1][j + 1] + 1
          : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }
  final anchors = <({int book, int heard})>[];
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i].isNotEmpty && _sameWord(a[i], b[j])) {
      anchors.add((book: j, heard: i));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  if (anchors.isEmpty) return null;
  final shorter = n < m ? n : m;
  if (anchors.length < (shorter * minMatchRatio)) {
    return (words: const [], matched: anchors.length, total: shorter);
  }

  final out = <TimedWord>[];
  void addAnchor(int idx) {
    final at = anchors[idx];
    final s = spoken[at.heard];
    out.add(TimedWord(bookWords[at.book], s.start, s.end));
  }

  addAnchor(0);
  for (var t = 1; t < anchors.length; t++) {
    final prev = anchors[t - 1], next = anchors[t];
    final from = spoken[prev.heard].end;
    final to = spoken[next.heard].start;
    final span = to > from ? to - from : 0.0;
    var total = 0;
    for (var q = prev.book + 1; q < next.book; q++) {
      total += bookWords[q].length + 1;
    }
    // Words the narrator's version didn't have: share the gap between the two
    // anchors out by how much text each one is.
    var before = 0;
    for (var q = prev.book + 1; q < next.book; q++) {
      final start = total <= 0 ? from : from + span * (before / total);
      out.add(TimedWord(bookWords[q], start, start));
      before += bookWords[q].length + 1;
    }
    addAnchor(t);
  }
  // Finish the sentence the last anchor sits in. The window cut it off
  // mid-flow and Whisper garbles the truncated edge, so its closing words
  // anchor in neither this chunk nor the next - without this they vanish
  // from the transcript entirely (the store then rejects the next chunk's
  // overlapping partial repeat of the same sentence). Timing is estimated
  // from this chunk's own word pace and capped, so the reach past the last
  // real timestamp stays small.
  final lastBook = anchors.last.book;
  if (lastBook + 1 < bookWords.length &&
      !_endsSentence.hasMatch(bookWords[lastBook])) {
    final avgWord = ((spoken.last.end - spoken.first.start) / spoken.length)
        .clamp(0.15, 0.6);
    var at = out.last.end;
    final capEnd = out.last.end + 3.0;
    for (var q = lastBook + 1;
        q < bookWords.length && q <= lastBook + 12 && at < capEnd;
        q++) {
      final end = (at + avgWord) > capEnd ? capEnd : at + avgWord;
      out.add(TimedWord(bookWords[q], at, end));
      at = end;
      if (_endsSentence.hasMatch(bookWords[q])) break;
    }
  }
  // Every word ends where the next one starts, so a line's span is continuous.
  for (var k = 0; k < out.length; k++) {
    final end = k + 1 < out.length ? out[k + 1].start : out[k].end;
    if (end > out[k].start) {
      out[k] = TimedWord(out[k].text, out[k].start, end);
    }
  }
  return (words: out, matched: anchors.length, total: shorter);
}

final _endsSentence = RegExp(r'''[.!?]["'”’)\]]*$''');

/// [text]'s words timed by a flat per-word estimate from [from] - for the
/// preview of book sentences no audio has reached yet.
List<TimedWord> estimatedWords(String text, double from, double perWord) {
  final out = <TimedWord>[];
  var at = from;
  for (final m in _wordRe.allMatches(text)) {
    out.add(TimedWord(m.group(0)!, at, at + perWord));
    at += perWord;
  }
  return out;
}

/// Group timed words into one line per sentence, each carrying its words'
/// start times for word-by-word read along.
List<TranscriptLine> linesFromWords(List<TimedWord> words,
    {required bool exact, bool approx = false}) {
  final out = <TranscriptLine>[];
  var from = 0;
  void flush(int to) {
    if (to <= from) return;
    final run = words.sublist(from, to);
    final text = run.map((w) => w.text).join(' ');
    if (text.trim().isNotEmpty) {
      out.add(TranscriptLine(run.first.start, run.last.end, text,
          exact: exact,
          approx: approx,
          wordStarts: [for (final w in run) w.start]));
    }
    from = to;
  }

  for (var i = 0; i < words.length; i++) {
    if (_endsSentence.hasMatch(words[i].text)) flush(i + 1);
  }
  flush(words.length);
  return out;
}
