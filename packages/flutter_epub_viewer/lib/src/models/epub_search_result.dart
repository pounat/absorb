import 'package:json_annotation/json_annotation.dart';

part 'epub_search_result.g.dart';

@JsonSerializable(explicitToJson: true)
class EpubSearchResult {
  /// The cfi string search result
  String cfi;

  /// The excerpt of the search result
  String excerpt;

  /// The xpath/XPointer string of the search result
  String? xpath;

  EpubSearchResult({
    required this.cfi,
    required this.excerpt,
    this.xpath,
  });
  factory EpubSearchResult.fromJson(Map<String, dynamic> json) =>
      _$EpubSearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$EpubSearchResultToJson(this);
}
