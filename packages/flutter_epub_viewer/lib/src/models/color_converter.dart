import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

class ColorConverter implements JsonConverter<Color?, String?> {
  const ColorConverter();

  @override
  Color? fromJson(String? json) {
    if (json == null) {
      return null;
    }
    return Color(int.parse(json, radix: 16));
  }

  @override
  String? toJson(Color? color) {
    if (color == null) {
      return null;
    }
    return color.value.toRadixString(16);
  }
}
