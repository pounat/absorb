import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../main.dart' show trueCoverColorsNotifier;
import '../services/scoped_prefs.dart';

/// A book's colors from its cover color: softened, or kept close to the
/// cover when True cover colors is on.
ColorScheme schemeFromCover(Color seed, Brightness brightness) {
  final soft = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return trueCoverColorsNotifier.value ? trueCoverScheme(seed, soft) : soft;
}

/// [soft] with its main color kept close to the cover. The second and third
/// colors stay the soft ones: the faithful style pairs a color with its
/// opposite, so a red cover got blue next to it.
ColorScheme trueCoverScheme(Color seed, ColorScheme soft) {
  final faithful = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: soft.brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  return vividInDark(
    soft.copyWith(
      primary: faithful.primary,
      onPrimary: faithful.onPrimary,
      primaryContainer: faithful.primaryContainer,
      onPrimaryContainer: faithful.onPrimaryContainer,
      surfaceTint: faithful.surfaceTint,
    ),
    seed,
  );
}

/// A cover color as the glow and card backgrounds show it: the cover's own
/// color with True cover colors on, a calmer version of the same hue otherwise.
Color shownCoverColor(Color raw) {
  final hsl = HSLColor.fromColor(raw);
  return hsl.withSaturation(hsl.saturation * (trueCoverColorsNotifier.value ? 0.8 : 0.55)).toColor();
}

/// In dark mode Material makes the main accent a pale version of the color so
/// it reads on black, which turns any red pink. With True cover colors on,
/// the accent is the cover's color, lightened enough to read and a little
/// calmer than the cover itself. A cover with no real color is left alone.
ColorScheme vividInDark(ColorScheme scheme, Color seed) {
  if (scheme.brightness != Brightness.dark) return scheme;
  final hsl = HSLColor.fromColor(seed);
  if (hsl.saturation < 0.15) return scheme;
  final primary = hsl
      .withLightness(hsl.lightness.clamp(0.6, 0.72))
      .withSaturation(hsl.saturation.clamp(0.45, 0.7))
      .toColor();
  return scheme.copyWith(
    primary: primary,
    onPrimary: primary.computeLuminance() > 0.35 ? Colors.black : Colors.white,
    surfaceTint: primary,
  );
}

/// The accent color of a cover, found once and remembered: in memory for
/// this run and in the preferences across runs, so a sheet opening on a
/// cover seen before paints in its color straight away. The palette is read
/// from a small copy of the image, a few milliseconds rather than the
/// second a full-size cover took.
class CoverAccents {
  CoverAccents._();

  // v2: picked by how vivid and how big a color is, so v1's picks are redone.
  static const _prefsKey = 'cover_accent_seeds_v2';
  static const _keep = 400;
  static final Map<String, Color?> _known = {};
  static final Map<String, Future<Color?>> _inFlight = {};
  static Map<String, int>? _saved;

  /// The accent of the cover at [url] when it is already known, else null.
  static Color? known(String url) => _known[_keyOf(url)];

  /// The accent of the cover at [url], read through [provider] when it is
  /// not known yet. Null when the cover has no usable color.
  static Future<Color?> seed(String url, ImageProvider provider) {
    final key = _keyOf(url);
    if (_known.containsKey(key)) return Future.value(_known[key]);
    final running = _inFlight[key];
    if (running != null) return running;
    // A block, not an arrow: whenComplete waits on a future its callback
    // returns, and remove would hand back this very future.
    final found = _find(key, provider).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = found;
    return found;
  }

  /// The same cover asked for at another size, or through another proxy
  /// prefix, is the same cover.
  static String _keyOf(String url) {
    var key = url;
    final api = key.indexOf('/api/');
    if (api > 0) key = key.substring(api);
    return key.replaceAll(RegExp(r'[?&]width=\d+'), '');
  }

  static Future<Map<String, int>> _loadSaved() async {
    final have = _saved;
    if (have != null) return have;
    final out = <String, int>{};
    try {
      final raw = await ScopedPrefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
          if (v is int) out[k] = v;
        });
      }
    } catch (_) {}
    return _saved ??= out;
  }

  static Future<Color?> _find(String key, ImageProvider provider) async {
    final saved = await _loadSaved();
    final argb = saved[key];
    if (argb != null) {
      final color = Color(argb);
      _known[key] = color;
      return color;
    }
    final t0 = DateTime.now();
    // The top of the cover only: the "Only from Audible" badge sits in the
    // bottom corner and would otherwise be the brightest color on a dark cover.
    // The region is in units of the cover's width, which for a square cover
    // is its height too.
    final palette = await PaletteGenerator.fromImageProvider(
      ResizeImage(provider, width: 96),
      maximumColorCount: 16,
      size: const Size(1, 1),
      region: const Rect.fromLTWH(0, 0, 1, 0.72),
    );
    final color = accentFromCoverPalette(palette);
    debugPrint('[CoverAccent] ${color == null ? 'no accent' : 'accent found'} '
        'in ${DateTime.now().difference(t0).inMilliseconds}ms for $key');
    _known[key] = color;
    if (color != null) {
      saved[key] = color.toARGB32();
      while (saved.length > _keep) {
        saved.remove(saved.keys.first);
      }
      unawaited(ScopedPrefs.setString(_prefsKey, jsonEncode(saved)));
    }
    return color;
  }
}

/// Picks an accent color from a cover's [palette].
///
/// A strong color on a cover comes back split into several shades, so shades
/// of one hue are counted together, each by how vivid it is and how much of
/// the cover it fills. Murky near-blacks and greys don't count. The winning
/// hue is shown by its most vivid shade that isn't a speck: the red title on
/// a black cover wins over the cover's near-black, and a mostly blue cover
/// stays blue. With no real color at all, the most common one is used.
Color? accentFromCoverPalette(PaletteGenerator palette) {
  final swatches = palette.paletteColors;
  final total = swatches.fold<int>(0, (n, c) => n + c.population);
  if (total == 0) return palette.dominantColor?.color;
  final score = <int, double>{};
  final share = <int, double>{};
  final members = <int, List<PaletteColor>>{};
  for (final pc in swatches) {
    final hsv = HSVColor.fromColor(pc.color);
    if (hsv.saturation * hsv.value < 0.12) continue;
    final family = ((hsv.hue + 15) % 360 ~/ 30);
    final part = pc.population / total;
    score[family] = (score[family] ?? 0) + part * hsv.saturation * hsv.saturation * hsv.value;
    share[family] = (share[family] ?? 0) + part;
    (members[family] ??= []).add(pc);
  }
  int? best;
  for (final f in score.keys) {
    if (share[f]! < 0.03) continue;
    if (best == null || score[f]! > score[best]!) best = f;
  }
  if (best == null) return palette.dominantColor?.color;
  PaletteColor? pick;
  var pickVivid = -1.0;
  for (final pc in members[best]!) {
    if (pc.population / total < 0.005) continue;
    final hsv = HSVColor.fromColor(pc.color);
    final vivid = hsv.saturation * hsv.value;
    if (vivid > pickVivid) {
      pick = pc;
      pickVivid = vivid;
    }
  }
  return (pick ?? members[best]!.first).color;
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
