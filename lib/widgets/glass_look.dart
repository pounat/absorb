import 'package:flutter/material.dart';
import '../services/native_tab_bar.dart';
import 'expressive.dart';

/// True while the iOS Liquid Glass look is on.
bool get glassLook => NativeTabBar.active.value;

/// The player card's corners are rounder under either of the two looks.
bool get softCardCorners => expressiveNotifier.value || glassLook;

/// The cover's own colour as a card background, pulled down to a calm shade
/// so a bright cover (a yellow one, say) doesn't flood the card. Dark themes
/// get a deep tone of it and light themes a pale one.
Color solidCoverBackground(Color cover, {required bool dark}) {
  final hsl = HSLColor.fromColor(cover);
  return hsl
      .withSaturation(hsl.saturation.clamp(0.0, dark ? 0.5 : 0.45))
      .withLightness(dark ? 0.16 : 0.87)
      .toColor();
}

/// Where a gradient card background starts: the cover's colour at a softer
/// strength, fading to the surface.
Color gradientCoverStart(Color cover, {required bool dark}) {
  final hsl = HSLColor.fromColor(cover);
  return hsl
      .withSaturation(hsl.saturation.clamp(0.0, dark ? 0.55 : 0.5))
      .withLightness(dark ? 0.24 : 0.8)
      .toColor();
}

/// The play or pause icon, with the one morphing into the other, the way
/// iOS animates the control.
class MorphingPlayIcon extends StatefulWidget {
  final bool playing;
  final double size;
  final Color color;

  const MorphingPlayIcon({
    super.key,
    required this.playing,
    required this.size,
    required this.color,
  });

  @override
  State<MorphingPlayIcon> createState() => _MorphingPlayIconState();
}

class _MorphingPlayIconState extends State<MorphingPlayIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.playing ? 1 : 0,
  );

  @override
  void didUpdateWidget(MorphingPlayIcon old) {
    super.didUpdateWidget(old);
    if (old.playing == widget.playing) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.playing ? 1 : 0;
    } else if (widget.playing) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _controller,
        size: widget.size,
        color: widget.color,
      );
}
