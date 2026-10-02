// Whisper's languages by code. whisper.cpp does not fall back to detection
// on a code outside this table, so nothing else may be passed to it.
const _whisperLanguages = {
  'en': 'english', 'zh': 'chinese', 'de': 'german', 'es': 'spanish',
  'ru': 'russian', 'ko': 'korean', 'fr': 'french', 'ja': 'japanese',
  'pt': 'portuguese', 'tr': 'turkish', 'pl': 'polish', 'ca': 'catalan',
  'nl': 'dutch', 'ar': 'arabic', 'sv': 'swedish', 'it': 'italian',
  'id': 'indonesian', 'hi': 'hindi', 'fi': 'finnish', 'vi': 'vietnamese',
  'he': 'hebrew', 'uk': 'ukrainian', 'el': 'greek', 'ms': 'malay',
  'cs': 'czech', 'ro': 'romanian', 'da': 'danish', 'hu': 'hungarian',
  'ta': 'tamil', 'no': 'norwegian', 'th': 'thai', 'ur': 'urdu',
  'hr': 'croatian', 'bg': 'bulgarian', 'lt': 'lithuanian', 'la': 'latin',
  'mi': 'maori', 'ml': 'malayalam', 'cy': 'welsh', 'sk': 'slovak',
  'te': 'telugu', 'fa': 'persian', 'lv': 'latvian', 'bn': 'bengali',
  'sr': 'serbian', 'az': 'azerbaijani', 'sl': 'slovenian', 'kn': 'kannada',
  'et': 'estonian', 'mk': 'macedonian', 'br': 'breton', 'eu': 'basque',
  'is': 'icelandic', 'hy': 'armenian', 'ne': 'nepali', 'mn': 'mongolian',
  'bs': 'bosnian', 'kk': 'kazakh', 'sq': 'albanian', 'sw': 'swahili',
  'gl': 'galician', 'mr': 'marathi', 'pa': 'punjabi', 'si': 'sinhala',
  'km': 'khmer', 'sn': 'shona', 'yo': 'yoruba', 'so': 'somali',
  'af': 'afrikaans', 'oc': 'occitan', 'ka': 'georgian', 'be': 'belarusian',
  'tg': 'tajik', 'sd': 'sindhi', 'gu': 'gujarati', 'am': 'amharic',
  'yi': 'yiddish', 'lo': 'lao', 'uz': 'uzbek', 'fo': 'faroese',
  'ht': 'haitian creole', 'ps': 'pashto', 'tk': 'turkmen', 'nn': 'nynorsk',
  'mt': 'maltese', 'sa': 'sanskrit', 'lb': 'luxembourgish', 'my': 'myanmar',
  'bo': 'tibetan', 'tl': 'tagalog', 'mg': 'malagasy', 'as': 'assamese',
  'tt': 'tatar', 'haw': 'hawaiian', 'ln': 'lingala', 'ha': 'hausa',
  'ba': 'bashkir', 'jw': 'javanese', 'su': 'sundanese',
};

const _aliases = {
  'eng': 'en', 'deu': 'de', 'ger': 'de', 'fra': 'fr', 'fre': 'fr',
  'spa': 'es', 'ita': 'it', 'por': 'pt', 'nld': 'nl', 'dut': 'nl',
  'rus': 'ru', 'jpn': 'ja', 'zho': 'zh', 'chi': 'zh', 'kor': 'ko',
  'pol': 'pl', 'swe': 'sv', 'nor': 'no', 'nob': 'no', 'nb': 'no',
  'dan': 'da', 'fin': 'fi', 'ell': 'el', 'gre': 'el', 'ron': 'ro',
  'rum': 'ro', 'ces': 'cs', 'cze': 'cs', 'hun': 'hu', 'tur': 'tr',
  'ukr': 'uk', 'ara': 'ar', 'heb': 'he', 'iw': 'he', 'hin': 'hi',
  'cat': 'ca', 'lat': 'la', 'ind': 'id', 'vie': 'vi', 'tha': 'th',
  'deutsch': 'de', 'español': 'es', 'espanol': 'es', 'castellano': 'es',
  'castilian': 'es', 'français': 'fr', 'francais': 'fr', 'italiano': 'it',
  'português': 'pt', 'portugues': 'pt', 'nederlands': 'nl', 'flemish': 'nl',
  'русский': 'ru', '日本語': 'ja', '中文': 'zh', 'mandarin': 'zh',
  '한국어': 'ko', 'polski': 'pl', 'svenska': 'sv', 'norsk': 'no',
  'bokmål': 'no', 'dansk': 'da', 'suomi': 'fi', 'ελληνικά': 'el',
  'română': 'ro', 'romana': 'ro', 'čeština': 'cs', 'cestina': 'cs',
  'magyar': 'hu', 'türkçe': 'tr', 'turkce': 'tr', 'українська': 'uk',
  'burmese': 'my', 'farsi': 'fa', 'filipino': 'tl',
};

/// The Whisper code for a metadata language ("English", "eng", "en-US"), or
/// null when it names no single language the engine knows.
String? whisperLanguageCode(String? raw) {
  if (raw == null) return null;
  final s = raw.toLowerCase().replaceAll(RegExp(r'\([^)]*\)'), ' ').trim();
  if (s.isEmpty || RegExp(r'[,;/&+]|\band\b').hasMatch(s)) return null;
  String? known(String v) {
    if (_whisperLanguages.containsKey(v)) return v;
    final alias = _aliases[v];
    if (alias != null) return alias;
    for (final e in _whisperLanguages.entries) {
      if (e.value == v) return e.key;
    }
    return null;
  }
  final direct = known(s);
  if (direct != null) return direct;
  // "en-US", "pt_BR": the region says nothing Whisper can use.
  final tag = RegExp(r'^([a-z]{2,3})[-_][a-z0-9]{2,8}$').firstMatch(s);
  return tag == null ? null : known(tag.group(1)!);
}
