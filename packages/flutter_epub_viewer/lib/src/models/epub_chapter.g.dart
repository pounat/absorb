// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpubChapter _$EpubChapterFromJson(Map<String, dynamic> json) => EpubChapter(
  title: json['title'] as String,
  href: json['href'] as String,
  id: json['id'] as String,
  subitems: (json['subitems'] as List<dynamic>)
      .map((e) => EpubChapter.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EpubChapterToJson(EpubChapter instance) =>
    <String, dynamic>{
      'title': instance.title,
      'href': instance.href,
      'id': instance.id,
      'subitems': instance.subitems.map((e) => e.toJson()).toList(),
    };
