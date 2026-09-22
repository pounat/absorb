import 'package:json_annotation/json_annotation.dart';

part 'epub_text_extract_res.g.dart';

@JsonSerializable(explicitToJson: true)

///Epub text extraction callback object
class EpubTextExtractRes {
  String? text;
  String? cfiRange;
  String? xpathRange;

  EpubTextExtractRes({
    this.text,
    this.cfiRange,
    this.xpathRange,
  });
  factory EpubTextExtractRes.fromJson(Map<String, dynamic> json) =>
      _$EpubTextExtractResFromJson(json);
  Map<String, dynamic> toJson() => _$EpubTextExtractResToJson(this);
}
