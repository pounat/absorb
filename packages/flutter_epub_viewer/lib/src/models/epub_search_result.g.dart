// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpubSearchResult _$EpubSearchResultFromJson(Map<String, dynamic> json) =>
    EpubSearchResult(
      cfi: json['cfi'] as String,
      excerpt: json['excerpt'] as String,
      xpath: json['xpath'] as String?,
    );

Map<String, dynamic> _$EpubSearchResultToJson(EpubSearchResult instance) =>
    <String, dynamic>{
      'cfi': instance.cfi,
      'excerpt': instance.excerpt,
      'xpath': instance.xpath,
    };
