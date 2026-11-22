import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../main.dart' show colorSourceNotifier, coverSeedNotifier, gradientIntensityNotifier, trueCoverColorsNotifier;
import '../utils/cover_accent.dart';

/// The soft glow at the top of the main screens, in the color of the book
/// that's playing, calmed down unless True cover colors is on (the app color
/// when nothing is playing, or when the color is set by hand). It fades over
/// to the new book's color when the book changes.
/// [scrolled] is how far the page has scrolled, so the glow goes up with it
/// instead of sitting behind everything. [height] is how tall the glow is,
/// for the small copy in the Appearance preview; a page leaves it out.
class CoverGlow extends StatelessWidget {
  final double scrolled;
  final double? height;

  const CoverGlow({super.key, this.scrolled = 0, this.height});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([coverSeedNotifier, colorSourceNotifier, gradientIntensityNotifier, trueCoverColorsNotifier]),
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final cover = colorSourceNotifier.value == 'manual' ? null : coverSeedNotifier.value;
        final color = cover == null ? cs.primary : shownCoverColor(cover);
        // Glow strength runs 0 to 0.45. Curved so the whole slider does
        // something: the default (0.06) looks as it always has, and the top
        // of the range is the strongest glow rather than the top half.
        final t = (gradientIntensityNotifier.value / 0.45).clamp(0.0, 1.0);
        final strength = t <= 0 ? 0.0 : 0.9 * math.pow(t, dark ? 0.656 : 0.91).toDouble();
        if (strength <= 0) return const SizedBox.shrink();
        final height = this.height ?? MediaQuery.sizeOf(context).height * 0.6;
        return IgnorePointer(
          child: Transform.translate(
            offset: Offset(0, -scrolled.clamp(0.0, height)),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, c, _) {
                    final glow = c ?? color;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -1.1),
                          radius: 1.25,
                          colors: [
                            glow.withValues(alpha: strength),
                            glow.withValues(alpha: strength * 0.45),
                            glow.withValues(alpha: 0),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
