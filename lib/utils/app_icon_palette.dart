/// The app icon colors people can pick, and the shape every one of them
/// shares. Pure Dart, so both the Settings picker and
/// scripts/make_app_icons.dart (which draws the real icon files) read the
/// same numbers. After changing anything here, run that script.
library;

class AppIconOption {
  /// Names the iOS icon set (AppIcon-<id>) and the Android launcher entry
  /// (Icon<Id>). "classic" is the original icon.
  final String id;
  final int background;

  /// The middle bar's color.
  final int ink;

  /// What the outer bars fade toward.
  final int fade;

  /// A color for each bar, left to right, in place of ink and fade.
  final List<int>? bars;

  const AppIconOption(this.id, this.background, this.ink, this.fade, {this.bars});

  int barColor(int i) => bars?[i] ?? mixArgb(ink, fade, appIconBars[i].shade);
}

/// The dev build's own icon, standing in for Classic there: the bars sweep
/// from Absorb's teal through violet to pink.
const appIconAurora = AppIconOption('classic', 0xFF0B0B14, 0xFF4CB6AC, 0xFF0B0B14, bars: [
  0xFF3FD9C1, 0xFF45C3D8, 0xFF4FA9E6, 0xFF6890F0, 0xFF8577F2,
  0xFFA56CEB, 0xFFC468DB, 0xFFDE67C3, 0xFFF06CA8,
]);

const appIconOptions = <AppIconOption>[
  AppIconOption('classic', 0xFF0F0F0F, 0xFF4CB6AC, 0xFFFFFFFF),
  AppIconOption('light', 0xFFF7F7F5, 0xFF2A9D90, 0xFFF7F7F5),
  AppIconOption('teal', 0xFF1F7A72, 0xFFFFFFFF, 0xFF1F7A72),
  AppIconOption('blue', 0xFF2F5FB3, 0xFFFFFFFF, 0xFF2F5FB3),
  AppIconOption('sky', 0xFF9FD0EE, 0xFF0F2A3D, 0xFF9FD0EE),
  AppIconOption('purple', 0xFF6A4CAF, 0xFFFFFFFF, 0xFF6A4CAF),
  AppIconOption('pink', 0xFFF2A7BB, 0xFF3D0F1F, 0xFFF2A7BB),
  AppIconOption('red', 0xFFC8432B, 0xFFFFFFFF, 0xFFC8432B),
  AppIconOption('orange', 0xFFE8833A, 0xFFFFFFFF, 0xFFE8833A),
  AppIconOption('yellow', 0xFFF2C94C, 0xFF2B2410, 0xFFF2C94C),
  AppIconOption('green', 0xFF2E7D5B, 0xFFFFFFFF, 0xFF2E7D5B),
];

/// One bar of the waveform, in a 1024 by 1024 icon.
class AppIconBar {
  final double centerX;
  final double top;
  final double bottom;

  /// How far the bar's color has moved from the ink toward the fade color.
  final double shade;

  const AppIconBar(this.centerX, this.top, this.bottom, this.shade);
}

const appIconBarWidth = 36.0;

/// Measured from the original icon.
const appIconBars = <AppIconBar>[
  AppIconBar(279.5, 432, 590, 0.51),
  AppIconBar(339.5, 352, 671, 0.37),
  AppIconBar(399.5, 272, 751, 0.22),
  AppIconBar(460, 212, 812, 0.11),
  AppIconBar(520, 192, 832, 0),
  AppIconBar(580, 232, 792, 0.11),
  AppIconBar(639.5, 312, 712, 0.27),
  AppIconBar(699.5, 382, 641, 0.40),
  AppIconBar(759, 432, 590, 0.55),
];

/// [a] moved [t] of the way to [b], both 0xAARRGGBB.
int mixArgb(int a, int b, double t) {
  int ch(int shift) {
    final x = (a >> shift) & 0xFF;
    final y = (b >> shift) & 0xFF;
    return (x + (y - x) * t).round().clamp(0, 255);
  }

  return (ch(24) << 24) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}
