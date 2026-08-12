import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Picks an accent color from a cover's [palette].
///
/// Guards against a small but highly-saturated corner badge (e.g. the yellow
/// "Only from Audible" banner) hijacking the result. PaletteGenerator's
/// "vibrant" target is scored mostly on saturation, so a tiny vivid badge can
/// outrank the dominant artwork color - turning a mostly-blue cover's accent
/// yellow. When the vibrant swatch covers only a small slice of the cover
/// relative to the dominant color, we treat it as a badge and fall back to the
/// most prominent swatch that still reads as a real color. Genuinely vibrant
/// covers (where the vivid color IS a large share of the image) are unaffected.
Color? accentFromCoverPalette(PaletteGenerator palette) {
  final vibrant = palette.vibrantColor ??
      palette.lightVibrantColor ??
      palette.darkVibrantColor;
  final dominant = palette.dominantColor;

  if (vibrant != null &&
      dominant != null &&
      vibrant.population < dominant.population * 0.4) {
    final colorful = _mostProminentColorful(palette);
    if (colorful != null) return colorful;
    return dominant.color;
  }

  return vibrant?.color ??
      dominant?.color ??
      (palette.colors.isEmpty ? null : palette.colors.first);
}

/// Mean brightness of the top strip of a blurred cover - the strip the
/// player's progress row sits on. Read from the small blurred image the cards
/// already keep, and only every fourth pixel, so this is a few thousand
/// samples once per cover.
///
/// Deliberately averages the gamma-encoded bytes rather than linearising them:
/// the threshold this feeds is about what the eye reads as light or dark, and
/// mid-grey should land near the middle.
Future<double?> topStripLuminance(ui.Image image) async {
  try {
    final rows = (image.height * 0.28).round().clamp(1, image.height);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final bytes = data.buffer.asUint8List();
    var total = 0.0;
    var count = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < image.width; x += 4) {
        final i = (y * image.width + x) * 4;
        if (i + 2 >= bytes.length) break;
        total +=
            (0.2126 * bytes[i] + 0.7152 * bytes[i + 1] + 0.0722 * bytes[i + 2]) /
            255.0;
        count++;
      }
    }
    return count == 0 ? null : total / count;
  } catch (_) {
    return null;
  }
}

/// What the eye actually sees when a [scrim] at [scrimAlpha] is laid over
/// artwork of [artworkLuminance].
double scrimmedLuminance(
  double artworkLuminance,
  Color scrim,
  double scrimAlpha,
) =>
    artworkLuminance * (1 - scrimAlpha) +
    scrim.computeLuminance() * scrimAlpha;

/// Ink and its shadow for text drawn on a backdrop of [luminance].
///
/// The player's elapsed/percent/remaining row used to take its color from the
/// app theme, which says nothing about the cover behind it: a pale cover in
/// dark mode left white text on a near-white backdrop, which is what a user
/// reported as unreadable. Choosing by what is actually behind the text fixes
/// it in both directions, and needs no setting.
({Color ink, Color shadow}) inkForLuminance(double luminance) {
  final useLightInk = luminance < 0.45;
  return (
    ink: useLightInk
        ? Colors.white.withValues(alpha: 0.82)
        : Colors.black.withValues(alpha: 0.72),
    shadow: useLightInk
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.6),
  );
}

/// Highest-population swatch that still reads as a color - skips grey, near
/// white and near black so the fallback accent matches the artwork rather than
/// washing out.
Color? _mostProminentColorful(PaletteGenerator palette) {
  PaletteColor? best;
  for (final pc in palette.paletteColors) {
    final hsv = HSVColor.fromColor(pc.color);
    if (hsv.saturation < 0.15) continue; // grey / white / black
    if (hsv.value < 0.12) continue; // near black
    if (best == null || pc.population > best.population) best = pc;
  }
  return best?.color;
}
