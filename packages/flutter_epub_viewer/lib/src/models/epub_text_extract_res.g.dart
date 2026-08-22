// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_text_extract_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpubTextExtractRes _$EpubTextExtractResFromJson(Map<String, dynamic> json) =>
    EpubTextExtractRes(
      text: json['text'] as String?,
      cfiRange: json['cfiRange'] as String?,
      xpathRange: json['xpathRange'] as String?,
    );

Map<String, dynamic> _$EpubTextExtractResToJson(EpubTextExtractRes instance) =>
    <String, dynamic>{
      'text': instance.text,
      'cfiRange': instance.cfiRange,
      'xpathRange': instance.xpathRange,
    };
