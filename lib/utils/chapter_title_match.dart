/// True when an audio chapter title and a TOC chapter title plausibly name
/// the same chapter: equal, one's words are a subset of the other's, or they
/// share a number. Word-level, not substring - raw containment would make
/// "Chapter 1" match "Chapter 10". Spelled-out numbers normalize to digits
/// first, so "Chapter Nine" can't claim "Chapter Thirty-Nine" via word
/// subset (the hyphen splits it into two words), and "Chapter 39" matches
/// "Chapter Thirty-Nine" like it should.
bool chapterTitlesAgree(String? audio, String? toc) {
  if (audio == null || toc == null) return false;
  final a = chapterTitleWords(audio), t = chapterTitleWords(toc);
  if (a.isEmpty || t.isEmpty) return false;
  if (a.containsAll(t) || t.containsAll(a)) return true;
  final an = a.where((w) => RegExp(r'^\d+$').hasMatch(w)).toSet();
  final tn = t.where((w) => RegExp(r'^\d+$').hasMatch(w)).toSet();
  return an.isNotEmpty && an.intersection(tn).isNotEmpty;
}

const _units = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
  'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12,
  'thirteen': 13, 'fourteen': 14, 'fifteen': 15, 'sixteen': 16,
  'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
};
const _tens = {
  'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
  'seventy': 70, 'eighty': 80, 'ninety': 90,
};
const _ordinals = {
  'first': 1, 'second': 2, 'third': 3, 'fourth': 4, 'fifth': 5, 'sixth': 6,
  'seventh': 7, 'eighth': 8, 'ninth': 9, 'tenth': 10, 'eleventh': 11,
  'twelfth': 12, 'thirteenth': 13, 'fourteenth': 14, 'fifteenth': 15,
  'sixteenth': 16, 'seventeenth': 17, 'eighteenth': 18, 'nineteenth': 19,
  'twentieth': 20, 'thirtieth': 30, 'fortieth': 40, 'fiftieth': 50,
  'sixtieth': 60, 'seventieth': 70, 'eightieth': 80, 'ninetieth': 90,
};
const _headings = {
  'chapter', 'ch', 'part', 'book', 'section', 'volume', 'vol', 'act',
  'scene', 'episode', 'letter', 'canto',
};
const _romanValues = {'i': 1, 'v': 5, 'x': 10, 'l': 50, 'c': 100};
const _romanNumerals = [
  (100, 'c'), (90, 'xc'), (50, 'l'), (40, 'xl'), (10, 'x'), (9, 'ix'),
  (5, 'v'), (4, 'iv'), (1, 'i'),
];

/// [w] as a roman numeral, only when written the standard way.
int? _roman(String w) {
  if (w.isEmpty || w.length > 9) return null;
  var total = 0, highest = 0;
  for (var i = w.length - 1; i >= 0; i--) {
    final v = _romanValues[w[i]];
    if (v == null) return null;
    total += v < highest ? -v : v;
    if (v > highest) highest = v;
  }
  if (total <= 0) return null;
  var rest = total;
  final back = StringBuffer();
  for (final (value, numeral) in _romanNumerals) {
    while (rest >= value) {
      back.write(numeral);
      rest -= value;
    }
  }
  return back.toString() == w ? total : null;
}

/// Title words with numbers collapsed to digit tokens ("thirty nine" -> "39").
/// Ordinals and roman numerals only count as the chapter's number ("Chapter
/// XII", "Part the Second", "IV. The Duel"), not inside "What I Did".
Set<String> chapterTitleWords(String s) {
  final raw = s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]+', unicode: true), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  bool numeral(String w) =>
      int.tryParse(w) != null ||
      _units.containsKey(w) ||
      _tens.containsKey(w) ||
      _ordinals.containsKey(w) ||
      _roman(w) != null;
  final onlyNumeral = raw.every((w) => w == 'the' || numeral(w));
  final leadingRoman = RegExp(r'^\s*[ivxlc]+\s*[.:)\-\u2013\u2014]',
          caseSensitive: false)
      .hasMatch(s);
  bool afterHeading(int i) {
    var j = i - 1;
    if (j >= 0 && raw[j] == 'the') j--;
    return j >= 0 && _headings.contains(raw[j]);
  }
  bool beforeHeading(int i) =>
      i + 1 < raw.length && _headings.contains(raw[i + 1]);

  final out = <String>{};
  for (var i = 0; i < raw.length; i++) {
    final w = raw[i];
    final tens = _tens[w];
    if (tens != null) {
      final next = i + 1 < raw.length ? raw[i + 1] : null;
      final unit = next == null ? null : _units[next];
      if (unit != null && unit < 10) {
        out.add('${tens + unit}');
        i++;
        continue;
      }
      final ordinal = next == null ? null : _ordinals[next];
      if (ordinal != null &&
          ordinal < 10 &&
          (onlyNumeral || afterHeading(i) || beforeHeading(i + 1))) {
        out.add('${tens + ordinal}');
        i++;
        continue;
      }
      out.add('$tens');
      continue;
    }
    final unit = _units[w];
    if (unit != null) {
      out.add('$unit');
      continue;
    }
    final ordinal = _ordinals[w];
    if (ordinal != null &&
        (onlyNumeral || afterHeading(i) || beforeHeading(i))) {
      out.add('$ordinal');
      continue;
    }
    final roman = _roman(w);
    if (roman != null &&
        (onlyNumeral || afterHeading(i) || (i == 0 && leadingRoman))) {
      out.add('$roman');
      continue;
    }
    out.add(w);
  }
  return out;
}
