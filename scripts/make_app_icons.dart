// Draws the app icon colors for iOS and Android from
// lib/utils/app_icon_palette.dart, plus the dark and tinted versions of the
// main iOS icon. Run from the repo root after changing the palette:
//
//   dart run scripts/make_app_icons.dart
//
// iOS: the main icon (AppIcon) is one full-bleed 1024 picture, with no
// rounded corners drawn in, since iOS rounds it; corners drawn into it showed
// as white wings while the app closed. Each color is its own AppIcon-<id> set.
// Android: each color is an adaptive icon (its background color and a
// foreground of bars), plus a plain picture for Android older than 8.
import 'dart:io';
import 'dart:math' as math;

import 'package:absorb/utils/app_icon_palette.dart';
import 'package:image/image.dart' as img;

const _ios = 'ios/Runner/Assets.xcassets';
const _res = 'android/app/src/main/res';

const _densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};

void main() {
  if (!File('pubspec.yaml').existsSync() || !Directory(_ios).existsSync()) {
    stderr.writeln('Run this from the Absorb repo root.');
    exit(1);
  }
  final classic = appIconOptions.first;
  _writeIosMain(classic);
  final colors = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n');
  for (final o in appIconOptions.skip(1)) {
    _writeIosAlternate(o);
    _writeAndroid(o);
    colors.writeln('    <color name="icon_bg_${o.id}">${_hex(o.background)}</color>');
  }
  colors.writeln('</resources>');
  File('$_res/values/app_icon_colors.xml').writeAsStringSync(colors.toString());
  _writeAndroidDev();
  _writeIosDev();
  _writeWatch();
  stdout.writeln('Done: ${appIconOptions.length - 1} colors plus the main icon.');
}

String _hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// How much of the pixel at ([x], [y]) a bar covers, 0 to 1. Each bar is a
/// rounded line (a capsule), so its edge is smooth at any size.
double _barCover(double x, double y, double cx, double top, double bottom, double width) {
  final r = width / 2;
  final cy = y.clamp(top + r, bottom - r);
  final d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) - r;
  return (0.5 - d).clamp(0.0, 1.0);
}

/// The waveform at [size] pixels across, laid over [background] (null for
/// a transparent picture). [scale] and the centers map the 1024 layout onto
/// the picture, so the Android foreground can sit smaller in its canvas.
img.Image _draw(
  int size,
  AppIconOption o, {
  int? background,
  double scale = 1,
  double fromCenterX = 512,
  double fromCenterY = 512,
  double toCenterX = 512,
  double toCenterY = 512,
}) {
  final k = size / 1024;
  final pic = img.Image(width: size, height: size, numChannels: 4);
  final bg = background;
  final bars = [
    for (var i = 0; i < appIconBars.length; i++)
      (
        cx: (toCenterX + (appIconBars[i].centerX - fromCenterX) * scale) * k,
        top: (toCenterY + (appIconBars[i].top - fromCenterY) * scale) * k,
        bottom: (toCenterY + (appIconBars[i].bottom - fromCenterY) * scale) * k,
        color: o.barColor(i),
      ),
  ];
  final width = appIconBarWidth * scale * k;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final px = x + 0.5, py = y + 0.5;
      var color = bg ?? 0x00000000;
      for (final b in bars) {
        if ((px - b.cx).abs() > width) continue;
        final cover = _barCover(px, py, b.cx, b.top, b.bottom, width);
        if (cover <= 0) continue;
        color = bg == null
            ? (cover >= 1 ? b.color : ((b.color & 0xFFFFFF) | ((cover * 255).round() << 24)))
            : mixArgb(color, b.color, cover);
      }
      pic.setPixelRgba(x, y, (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, (color >> 24) & 0xFF);
    }
  }
  return pic;
}

/// The App Store won't take an icon with transparency in it.
img.Image _opaque(img.Image pic) => pic.convert(numChannels: 3);

void _png(String path, img.Image pic) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(pic));
}

String _iosContents(List<({String file, String? look})> images) {
  final entries = images.map((i) {
    final look = i.look == null
        ? ''
        : ',\n      "appearances": [\n        {\n          "appearance": "luminosity",\n          "value": "${i.look}"\n        }\n      ]';
    return '    {\n      "filename": "${i.file}",\n      "idiom": "universal",\n      "platform": "ios",\n      "size": "1024x1024"$look\n    }';
  }).join(',\n');
  return '{\n  "images": [\n$entries\n  ],\n  "info": {\n    "author": "xcode",\n    "version": 1\n  }\n}\n';
}

void _writeIosMain(AppIconOption classic) {
  final dir = Directory('$_ios/AppIcon.appiconset');
  // The old per-size pictures had the corners drawn in; one 1024 picture
  // now covers every size.
  for (final f in dir.listSync().whereType<File>()) {
    if (f.path.endsWith('.png')) f.deleteSync();
  }
  _png('${dir.path}/AppIcon.png', _opaque(_draw(1024, classic, background: classic.background)));
  // iOS draws the dark version on its own dark backdrop and the tinted one
  // in the tint the person picked, from a grayscale picture.
  _png('${dir.path}/AppIcon-Dark.png', _opaque(_draw(1024, classic, background: 0xFF000000)));
  const tinted = AppIconOption('tinted', 0xFF000000, 0xFFFFFFFF, 0xFF000000);
  _png('${dir.path}/AppIcon-Tinted.png', _opaque(_draw(1024, tinted, background: 0xFF000000)));
  File('${dir.path}/Contents.json').writeAsStringSync(_iosContents([
    (file: 'AppIcon.png', look: null),
    (file: 'AppIcon-Dark.png', look: 'dark'),
    (file: 'AppIcon-Tinted.png', look: 'tinted'),
  ]));
}

/// The Absorb Dev iPhone app's icon, Aurora, matching the Android dev
/// build. scripts/ios-dev-rename copies these over the main icon when
/// Codemagic builds that app; the real app never carries them.
void _writeIosDev() {
  final dir = Directory('ios/DevIcon')..createSync(recursive: true);
  for (final f in dir.listSync().whereType<File>()) {
    if (f.path.endsWith('.png')) f.deleteSync();
  }
  _png('${dir.path}/AppIcon.png', _opaque(_draw(1024, appIconAurora, background: appIconAurora.background)));
  _png('${dir.path}/AppIcon-Dark.png', _opaque(_draw(1024, appIconAurora, background: 0xFF000000)));
}

void _writeIosAlternate(AppIconOption o) {
  final dir = '$_ios/AppIcon-${o.id}.appiconset';
  _png('$dir/AppIcon-${o.id}.png', _opaque(_draw(1024, o, background: o.background)));
  File('$dir/Contents.json').writeAsStringSync(_iosContents([(file: 'AppIcon-${o.id}.png', look: null)]));
}

void _writeAndroid(AppIconOption o) {
  for (final e in _densities.entries) {
    // The adaptive foreground: a 108dp canvas with the bars at the size and
    // place the original foreground has them.
    final canvas = (108 * e.value).round();
    _png(
      '$_res/drawable-${e.key}/ic_launcher_${o.id}_foreground.png',
      _draw(canvas, o, scale: 0.375 * 1024 / 432, fromCenterX: 519, toCenterX: 225 * 1024 / 432, toCenterY: 216 * 1024 / 432),
    );
    // Android older than 8 shows a plain picture: the full icon, rounded.
    final legacy = (48 * e.value).round();
    _png('$_res/mipmap-${e.key}/ic_launcher_${o.id}.png', _rounded(_draw(legacy, o, background: o.background)));
  }
  File('$_res/mipmap-anydpi-v26/ic_launcher_${o.id}.xml').writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/icon_bg_${o.id}"/>
  <foreground>
      <inset
          android:drawable="@drawable/ic_launcher_${o.id}_foreground"
          android:inset="16%" />
  </foreground>
</adaptive-icon>
''');
}

/// The dev build's own launcher icon, Aurora, in place of the main one. Only
/// the dev flavor carries these files.
void _writeAndroidDev() {
  const dev = 'android/app/src/dev/res';
  for (final e in _densities.entries) {
    final canvas = (108 * e.value).round();
    _png(
      '$dev/drawable-${e.key}/ic_launcher_foreground.png',
      _draw(canvas, appIconAurora,
          scale: 0.375 * 1024 / 432, fromCenterX: 519, toCenterX: 225 * 1024 / 432, toCenterY: 216 * 1024 / 432),
    );
  }
  File('$dev/values/colors.xml').writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Dev flavor: its own icon, Aurora, so the testing install is told
         apart from the stable one at a glance. Drawn by
         scripts/make_app_icons.dart. -->
    <color name="ic_launcher_background">${_hex(appIconAurora.background)}</color>
</resources>
''');
}

/// The watch app's own copies, when the AbsorbWear repo sits beside this
/// one: the same colors, so the watch can show the icon picked on the phone.
/// The watch's foreground is a 1024 picture with the bars a little smaller.
void _writeWatch() {
  const wear = '../AbsorbWear/app/src';
  if (!Directory(wear).existsSync()) {
    stdout.writeln('AbsorbWear not found beside this repo; skipped the watch icons.');
    return;
  }
  img.Image foreground(AppIconOption o) =>
      _draw(1024, o, scale: 0.89, fromCenterX: 519, toCenterX: 534, toCenterY: 512);
  final colors = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n');
  for (final o in appIconOptions.skip(1)) {
    _png('$wear/main/res/drawable/ic_launcher_${o.id}_foreground.png', foreground(o));
    colors.writeln('    <color name="icon_bg_${o.id}">${_hex(o.background)}</color>');
    File('$wear/main/res/mipmap-anydpi-v26/ic_launcher_${o.id}.xml').writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/icon_bg_${o.id}" />
    <foreground android:drawable="@drawable/ic_launcher_${o.id}_foreground" />
</adaptive-icon>
''');
  }
  colors.writeln('</resources>');
  File('$wear/main/res/values/app_icon_colors.xml').writeAsStringSync(colors.toString());
  // The dev watch build's own icon, Aurora, as on the phone's Absorb Dev.
  _png('$wear/dev/res/drawable/ic_launcher_foreground.png', foreground(appIconAurora));
  File('$wear/dev/res/values/colors.xml').writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Dev flavor: its own icon, Aurora, the same as the phone's Absorb Dev.
         Drawn by Absorb's scripts/make_app_icons.dart. -->
    <color name="ic_launcher_background">${_hex(appIconAurora.background)}</color>
</resources>
''');
  stdout.writeln('Watch icons written.');
}

/// Cuts [pic] to a rounded square, smoothly.
img.Image _rounded(img.Image pic) {
  final size = pic.width;
  final r = size * 0.2;
  final out = img.Image(width: size, height: size, numChannels: 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final px = x + 0.5, py = y + 0.5;
      final dx = math.max(0.0, math.max(r - px, px - (size - r)));
      final dy = math.max(0.0, math.max(r - py, py - (size - r)));
      final cover = (r - math.sqrt(dx * dx + dy * dy) + 0.5).clamp(0.0, 1.0);
      final p = pic.getPixel(x, y);
      out.setPixelRgba(x, y, p.r, p.g, p.b, (p.a * cover).round());
    }
  }
  return out;
}
