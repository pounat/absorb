// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_theme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpubTheme _$EpubThemeFromJson(Map<String, dynamic> json) => EpubTheme(
  backgroundDecoration: EpubTheme._decorationFromJson(
    json['backgroundDecoration'] as Map<String, dynamic>,
  ),
  foregroundColor: const ColorConverter().fromJson(
    json['foregroundColor'] as String?,
  ),
  themeType: $enumDecode(_$EpubThemeTypeEnumMap, json['themeType']),
);

Map<String, dynamic> _$EpubThemeToJson(EpubTheme instance) => <String, dynamic>{
  'backgroundDecoration': EpubTheme._decorationToJson(
    instance.backgroundDecoration,
  ),
  'foregroundColor': const ColorConverter().toJson(instance.foregroundColor),
  'themeType': _$EpubThemeTypeEnumMap[instance.themeType]!,
};

const _$EpubThemeTypeEnumMap = {
  EpubThemeType.dark: 'dark',
  EpubThemeType.light: 'light',
  EpubThemeType.custom: 'custom',
};
