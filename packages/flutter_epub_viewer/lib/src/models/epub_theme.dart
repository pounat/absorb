import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'color_converter.dart';

part 'epub_theme.g.dart';

///Theme type
enum EpubThemeType { dark, light, custom }

///Class for customizing the theme of the reader
@JsonSerializable()
@ColorConverter()
class EpubTheme {
  @JsonKey(toJson: _decorationToJson, fromJson: _decorationFromJson)
  ///Background decoration of the reader, overrides customCss
  Decoration? backgroundDecoration;
  ///Foreground color of the reader, overrides customCss
  Color? foregroundColor;
  ///Custom css for the reader
  Map<String, dynamic>? customCss;
  EpubThemeType themeType;

  EpubTheme({
    this.backgroundDecoration,
    this.foregroundColor,
    this.customCss,
    required this.themeType,
  });

  static _decorationToJson(Decoration? decoration) {
    return null;
  }

  static Decoration? _decorationFromJson(Map<String, dynamic> json) {
    return null;
  }

  /// Uses dark theme, black background and white foreground color
  factory EpubTheme.dark() {
    return EpubTheme(
      backgroundDecoration: const BoxDecoration(color: Color(0xff121212)),
      foregroundColor: Colors.white,
      themeType: EpubThemeType.dark,
    );
  }

  /// Uses light theme, white background and black foreground color
  factory EpubTheme.light() {
    return EpubTheme(
      backgroundDecoration: const BoxDecoration(color: Colors.white),
      foregroundColor: Colors.black,
      themeType: EpubThemeType.light,
    );
  }

  /// Custom theme option ,
  factory EpubTheme.custom({
    Decoration? backgroundDecoration,
    Color? foregroundColor,
    Map<String, dynamic>? customCss,
  }) {
    return EpubTheme(
      backgroundDecoration: backgroundDecoration,
      foregroundColor: foregroundColor,
      customCss: customCss,
      themeType: EpubThemeType.custom,
    );
  }

  factory EpubTheme.fromJson(Map<String, dynamic> json) =>
      _$EpubThemeFromJson(json);
  Map<String, dynamic> toJson() => _$EpubThemeToJson(this);
}
