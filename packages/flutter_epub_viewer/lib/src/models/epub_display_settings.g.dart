// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epub_display_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpubDisplaySettings _$EpubDisplaySettingsFromJson(Map<String, dynamic> json) =>
    EpubDisplaySettings(
      fontSize: (json['fontSize'] as num?)?.toInt() ?? 15,
      spread:
          $enumDecodeNullable(_$EpubSpreadEnumMap, json['spread']) ??
          EpubSpread.auto,
      flow:
          $enumDecodeNullable(_$EpubFlowEnumMap, json['flow']) ??
          EpubFlow.paginated,
      allowScriptedContent: json['allowScriptedContent'] as bool? ?? false,
      defaultDirection:
          $enumDecodeNullable(
            _$EpubDefaultDirectionEnumMap,
            json['defaultDirection'],
          ) ??
          EpubDefaultDirection.ltr,
      snap: json['snap'] as bool? ?? true,
      useSnapAnimationAndroid:
          json['useSnapAnimationAndroid'] as bool? ?? false,
      manager:
          $enumDecodeNullable(_$EpubManagerEnumMap, json['manager']) ??
          EpubManager.continuous,
      theme: json['theme'] == null
          ? null
          : EpubTheme.fromJson(json['theme'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EpubDisplaySettingsToJson(
  EpubDisplaySettings instance,
) => <String, dynamic>{
  'fontSize': instance.fontSize,
  'spread': _$EpubSpreadEnumMap[instance.spread]!,
  'flow': _$EpubFlowEnumMap[instance.flow]!,
  'defaultDirection': _$EpubDefaultDirectionEnumMap[instance.defaultDirection]!,
  'allowScriptedContent': instance.allowScriptedContent,
  'manager': _$EpubManagerEnumMap[instance.manager]!,
  'snap': instance.snap,
  'useSnapAnimationAndroid': instance.useSnapAnimationAndroid,
  'theme': ?instance.theme?.toJson(),
};

const _$EpubSpreadEnumMap = {
  EpubSpread.none: 'none',
  EpubSpread.always: 'always',
  EpubSpread.auto: 'auto',
};

const _$EpubFlowEnumMap = {
  EpubFlow.paginated: 'paginated',
  EpubFlow.scrolled: 'scrolled',
};

const _$EpubDefaultDirectionEnumMap = {
  EpubDefaultDirection.ltr: 'ltr',
  EpubDefaultDirection.rtl: 'rtl',
};

const _$EpubManagerEnumMap = {EpubManager.continuous: 'continuous'};
