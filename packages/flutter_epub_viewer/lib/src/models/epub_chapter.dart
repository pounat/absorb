import 'package:json_annotation/json_annotation.dart';

part 'epub_chapter.g.dart';

/// Epub chapter object
@JsonSerializable(explicitToJson: true)
class EpubChapter {
  /// The title of the chapter
  final String title;

  /// The href of the chapter, use to navigate to the chapter
  final String href;
  final String id;

  /// The subchapters of the chapteri
  final List<EpubChapter> subitems;

  EpubChapter({
    required this.title,
    required this.href,
    required this.id,
    required this.subitems,
  });
  factory EpubChapter.fromJson(Map<String, dynamic> json) =>
      _$EpubChapterFromJson(json);
  Map<String, dynamic> toJson() => _$EpubChapterToJson(this);
}


List<EpubChapter> parseChapterList(dynamic result) {
    if (result == null) return [];

    final List<dynamic> resultList = (result is List) ? result : [result];

    return resultList.map((item) {
      return EpubChapter.fromJson(_deepConvertMap(item));
    }).toList();
  }

  Map<String, dynamic> _deepConvertMap(dynamic item) {
    if (item is! Map) return {};

    return Map<String, dynamic>.fromEntries(
      item.entries.map((entry) {
        final key = entry.key.toString();
        final value = entry.value;

        if (value is List) {
          return MapEntry(key, value.map(_deepConvertValue).toList());
        } else if (value is Map) {
          return MapEntry(key, _deepConvertMap(value));
        } else {
          return MapEntry(key, value);
        }
      }),
    );
  }

  dynamic _deepConvertValue(dynamic value) {
    if (value is Map) {
      return _deepConvertMap(value);
    } else if (value is List) {
      return value.map(_deepConvertValue).toList();
    }
    return value;
  }