import 'dart:convert';

/// A piece of text the media controls (notification, Android Auto, lock
/// screen, CarPlay) can show on one of their two lines.
enum NowPlayingPiece {
  chapter,
  title,
  author,
  narrator,
  series,
  percent,
  chapterNumber,
  timeLeft,
}

/// The text each piece shows for the playing item, already formatted.
class NowPlayingValues {
  final String title;
  final String author;
  final String? chapter;
  final String? narrator;
  final String? series;
  final String? percent;
  final String? chapterNumber;
  final String? timeLeft;

  const NowPlayingValues({
    required this.title,
    required this.author,
    this.chapter,
    this.narrator,
    this.series,
    this.percent,
    this.chapterNumber,
    this.timeLeft,
  });

  String textFor(NowPlayingPiece piece) {
    final text = switch (piece) {
      NowPlayingPiece.chapter => chapter,
      NowPlayingPiece.title => title,
      NowPlayingPiece.author => author,
      NowPlayingPiece.narrator => narrator,
      NowPlayingPiece.series => series,
      NowPlayingPiece.percent => percent,
      NowPlayingPiece.chapterNumber => chapterNumber,
      NowPlayingPiece.timeLeft => timeLeft,
    };
    return text?.trim() ?? '';
  }
}

/// Which pieces go on the top and second line, in order.
class NowPlayingLayout {
  final List<NowPlayingPiece> top;
  final List<NowPlayingPiece> second;

  const NowPlayingLayout({required this.top, required this.second});

  /// GH #298: the chapter on top, "Author · Book" beneath.
  static const standard = NowPlayingLayout(
    top: [NowPlayingPiece.chapter],
    second: [NowPlayingPiece.author, NowPlayingPiece.title],
  );

  static const separator = ' · ';

  // Tried in order when nothing on the top line has text (no chapters, say).
  static const _topFallbacks = [
    NowPlayingPiece.title,
    NowPlayingPiece.chapter,
    NowPlayingPiece.author,
  ];

  bool uses(NowPlayingPiece piece) =>
      top.contains(piece) || second.contains(piece);

  List<NowPlayingPiece> get unused =>
      NowPlayingPiece.values.where((p) => !uses(p)).toList();

  bool get isStandard =>
      _sameOrder(top, standard.top) && _sameOrder(second, standard.second);

  ({String title, String subtitle}) build(NowPlayingValues values) {
    String line(Iterable<NowPlayingPiece> pieces) => pieces
        .map(values.textFor)
        .where((text) => text.isNotEmpty)
        .join(separator);

    var title = line(top);
    var secondPieces = second;
    if (title.isEmpty) {
      for (final piece in _topFallbacks) {
        final text = values.textFor(piece);
        if (text.isEmpty) continue;
        title = text;
        secondPieces = second.where((p) => p != piece).toList();
        break;
      }
    }
    return (title: title, subtitle: line(secondPieces));
  }

  String toJson() => jsonEncode({
        'top': top.map((p) => p.name).toList(),
        'second': second.map((p) => p.name).toList(),
      });

  /// Unknown names are dropped and a piece only shows once; anything
  /// unreadable, or an empty top line, falls back to [standard].
  static NowPlayingLayout fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return standard;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final seen = <NowPlayingPiece>{};
      List<NowPlayingPiece> read(Object? names) => [
            for (final name in (names as List?) ?? const [])
              for (final piece in NowPlayingPiece.values)
                if (piece.name == name && seen.add(piece)) piece,
          ];
      final top = read(map['top']);
      final second = read(map['second']);
      if (top.isEmpty) return standard;
      return NowPlayingLayout(top: top, second: second);
    } catch (_) {
      return standard;
    }
  }

  static bool _sameOrder(List<NowPlayingPiece> a, List<NowPlayingPiece> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
