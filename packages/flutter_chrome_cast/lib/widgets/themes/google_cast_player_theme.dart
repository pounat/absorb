import 'package:flutter/cupertino.dart';

/// Theme data for customizing the ExpandedGoogleCastPlayerController widget.
class GoogleCastPlayerTheme {
  /// Background color for the player.
  final Color? backgroundColor;

  /// Background gradient for the player.
  final Gradient? backgroundGradient;

  /// Text style for the media title.
  final TextStyle? titleTextStyle;

  /// Text style for the device name.
  final TextStyle? deviceTextStyle;

  /// Text style for time displays.
  final TextStyle? timeTextStyle;

  /// Color for icons.
  final Color? iconColor;

  /// Color for disabled icons.
  final Color? disabledIconColor;

  /// Size of icons.
  final double? iconSize;

  /// Custom background widget.
  final Widget? backgroundWidget;

  /// Border radius for media images.
  final BorderRadius? imageBorderRadius;

  /// Shadow for media images.
  final List<BoxShadow>? imageShadow;

  /// Maximum width for media images.
  final double? imageMaxWidth;

  /// Maximum height for media images.
  final double? imageMaxHeight;

  /// Fit for media images.
  final BoxFit? imageFit;

  /// Fallback widget when no image is available.
  final Widget? noImageFallback;

  /// Background color for popup menus (like captions menu)
  final Color? popupBackgroundColor;

  /// Text color for popup menu items
  final Color? popupTextColor;

  /// Text style for popup menu items
  final TextStyle? popupTextStyle;

  /// Volume slider active color
  final Color? volumeSliderActiveColor;

  /// Volume slider inactive color
  final Color? volumeSliderInactiveColor;

  /// Volume slider thumb color
  final Color? volumeSliderThumbColor;

  /// Creates a new [GoogleCastPlayerTheme].
  const GoogleCastPlayerTheme({
    this.backgroundColor,
    this.backgroundGradient,
    this.titleTextStyle,
    this.deviceTextStyle,
    this.timeTextStyle,
    this.iconColor,
    this.disabledIconColor,
    this.iconSize,
    this.backgroundWidget,
    this.imageBorderRadius,
    this.imageShadow,
    this.imageMaxWidth,
    this.imageMaxHeight,
    this.imageFit,
    this.noImageFallback,
    this.popupBackgroundColor,
    this.popupTextColor,
    this.popupTextStyle,
    this.volumeSliderActiveColor,
    this.volumeSliderInactiveColor,
    this.volumeSliderThumbColor,
  });
}
