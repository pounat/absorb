import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show flatNotifier;
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/chromecast_service.dart';
import '../utils/absorbing_list.dart';
import 'absorbing_card.dart';
import 'cover_glow.dart';

/// The real card of the book playing (or the first one on the Absorbing
/// page), shrunk to sit at the top of its settings. It is the card itself,
/// so every setting under it shows as it will really look; it just can't be
/// touched.
class AbsorbingCardPreview extends StatelessWidget {
  static const double height = 300;

  const AbsorbingCardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.watch<LibraryProvider>();
    final player = AudioPlayerService();
    final books = buildAbsorbingList(
      lib,
      player: player,
      cast: ChromecastService(),
      mergeLibraries: true,
    );
    final screen = MediaQuery.sizeOf(context);
    final cardWidth = math.min(screen.width, 440.0) - 40;
    final cardHeight = math.min(cardWidth * 1.8, math.max(screen.height * 0.74, 420.0));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: flatNotifier,
              builder: (_, flat, __) => flat ? const SizedBox.shrink() : const CoverGlow(height: height - 18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: books.isEmpty
                  ? Center(child: Icon(Icons.headphones_rounded, size: 40, color: cs.onSurfaceVariant))
                  : FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: AbsorbingCard(
                              key: ValueKey('preview-${absorbingKeyOf(books.first)}'),
                              item: books.first,
                              player: player,
                              preview: true,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
