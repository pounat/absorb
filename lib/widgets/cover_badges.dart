import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// State banner across the bottom of cover art: a finished check + "Finished"
/// (green) and a downloaded arrow + "Downloaded" (white), stacked, over a strong
/// dark scrim so they stay legible on any artwork. Place across the bottom of a
/// cover Stack:
///   Positioned(left: 0, right: 0, bottom: 0, child: CoverStateBadges(...))
class CoverStateBadges extends StatelessWidget {
  final bool isDownloaded;
  final bool isFinished;
  final double iconSize;

  /// Shows just the icons (no text labels), for covers too small to fit the
  /// full banner like the search result tiles.
  final bool iconOnly;

  /// Rounds the banner's bottom corners to match covers that aren't clipped by
  /// a parent ClipRRect (e.g. some cards).
  final BorderRadius? borderRadius;

  const CoverStateBadges({
    super.key,
    required this.isDownloaded,
    required this.isFinished,
    this.iconSize = 13,
    this.iconOnly = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDownloaded && !isFinished) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final green = Colors.greenAccent.shade400;
    if (iconOnly) return _iconOnly(green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isFinished) _row(Icons.check_circle_rounded, l.finished, green),
          if (isFinished && isDownloaded) const SizedBox(height: 2),
          if (isDownloaded) _row(Icons.download_rounded, l.saved, Colors.white),
        ],
      ),
    );
  }

  Widget _iconOnly(Color green) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFinished) Icon(Icons.check_circle_rounded, size: iconSize, color: green),
          if (isFinished && isDownloaded) const SizedBox(width: 3),
          if (isDownloaded) Icon(Icons.download_rounded, size: iconSize, color: Colors.white),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

/// Small book icon for a cover corner, on books that come with an ebook:
///   Positioned(top: 4, left: 4, child: EbookCoverBadge())
class EbookCoverBadge extends StatelessWidget {
  const EbookCoverBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.menu_book_rounded, size: 11, color: Colors.white),
    );
  }
}
