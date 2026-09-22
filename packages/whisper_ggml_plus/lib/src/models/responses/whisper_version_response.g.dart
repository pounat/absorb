// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whisper_version_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WhisperVersionResponse _$WhisperVersionResponseFromJson(
        Map<String, dynamic> json) =>
    _WhisperVersionResponse(
      type: json['@type'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$WhisperVersionResponseToJson(
        _WhisperVersionResponse instance) =>
    <String, dynamic>{
      '@type': instance.type,
      'message': instance.message,
    };
