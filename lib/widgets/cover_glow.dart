import 'package:flutter/material.dart';

import '../main.dart' show colorSourceNotifier, coverSeedNotifier, gradientIntensityNotifier, trueCoverColorsNotifier;
import '../utils/cover_accent.dart';

/// The soft glow at the top of the main screens, in the color of the book
/// that's playing, calmed down unless True cover colors is on (the app color
/// when nothing is playing, or when the color is set by hand). It fades over
/// to the new book's color when the book changes.
/// [scrolled] is how far the page has scrolled, so the glow goes up with it
/// instead of sitting behind everything.
class CoverGlow extends StatelessWidget {
  final double scrolled;

  const CoverGlow({super.key, this.scrolled = 0});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([coverSeedNotifier, colorSourceNotifier, gradientIntensityNotifier, trueCoverColorsNotifier]),
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final cover = colorSourceNotifier.value == 'manual' ? null : coverSeedNotifier.value;
        final color = cover == null ? cs.primary : shownCoverColor(cover);
        // The Background intensity setting still sets how strong it is.
        final strength = (gradientIntensityNotifier.value * (dark ? 4.0 : 2.4)).clamp(0.0, 0.9);
        if (strength <= 0) return const SizedBox.shrink();
        final height = MediaQuery.sizeOf(context).height * 0.6;
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
