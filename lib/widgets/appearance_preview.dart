import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart'
    show
        colorSourceNotifier,
        coverSeedNotifier,
        einkModeNotifier,
        flatNotifier,
        trueCoverColorsNotifier,
        useColorEverywhereNotifier;
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/wording.dart';
import '../utils/app_platform.dart';
import '../utils/cover_accent.dart';
import 'cover_glow.dart';
import 'glass_look.dart';

/// A small copy of a page with the playing card on it, at the top of the
/// Appearance settings: the page background, the glow behind it and the card
/// all change as the settings under it do.
class AppearancePreview extends StatefulWidget {
  static const double height = 204;

  const AppearancePreview({super.key});

  @override
  State<AppearancePreview> createState() => _AppearancePreviewState();
}

class _AppearancePreviewState extends State<AppearancePreview> {
  String _cardBackground = AppPlatform.isTv ? 'solid' : 'blurred';

  @override
  void initState() {
    super.initState();
    if (AppPlatform.isTv) return;
    PlayerSettings.getCardBackgroundRaw().then((v) {
      if (mounted && v != _cardBackground) setState(() => _cardBackground = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              flatNotifier,
              einkModeNotifier,
              colorSourceNotifier,
              useColorEverywhereNotifier,
              coverSeedNotifier,
              trueCoverColorsNotifier,
            ]),
            builder: (context, _) {
              final eink = einkModeNotifier.value;
              final plain = eink || flatNotifier.value;
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: eink ? 1 : 0.5)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!plain)
                      const Positioned.fill(
                        child: CoverGlow(height: AppearancePreview.height - 18),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            Wording.of(context).absorbingTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Expanded(child: _card(context, eink: eink)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required bool eink}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final dark = theme.brightness == Brightness.dark;
    final lib = context.watch<LibraryProvider>();
    final player = AudioPlayerService();

    final playingId = player.currentItemId;
    final key = playingId ?? (lib.absorbingBookIds.isNotEmpty ? lib.absorbingBookIds.first : null);
    final coverUrl = lib.getCoverUrl(key, width: 400);
    var title = playingId == null ? null : player.currentTitle;
    var author = playingId == null ? null : player.currentAuthor;
    if (title == null && key != null) {
      final media = lib.absorbingItemCache[key]?['media'];
      final meta = media is Map ? media['metadata'] : null;
      if (meta is Map) {
        if (meta['title'] is String) title = meta['title'] as String;
        if (meta['authorName'] is String) author = meta['authorName'] as String;
      }
    }

    final manual = colorSourceNotifier.value == 'manual';
    final everywhere = manual && useColorEverywhereNotifier.value;
    final cover = coverSeedNotifier.value;
    // With a picked color that isn't used everywhere, the card still wears
    // its own book's color.
    final accent = (manual && !everywhere && !eink && cover != null)
        ? schemeFromCover(cover, theme.brightness).primary
        : cs.primary;
    final tint = (eink || everywhere || cover == null) ? null : shownCoverColor(cover);
    final background = eink ? 'off' : _cardBackground;

    final image = _coverImage(coverUrl, lib);
    final Widget backdrop;
    if (background == 'off') {
      backdrop = ColoredBox(color: cs.surface);
    } else if (background == 'solid') {
      backdrop = ColoredBox(color: solidCoverBackground(tint ?? cs.primary, dark: dark));
    } else if (background == 'blurred' && image != null) {
      backdrop = RepaintBoundary(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18, tileMode: TileMode.clamp),
          child: Image(image: image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ColoredBox(color: cs.surface)),
        ),
      );
    } else {
      backdrop = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint == null ? cs.primaryContainer : gradientCoverStart(tint, dark: dark),
              cs.surface,
            ],
          ),
        ),
      );
    }
    final List<double> scrim = switch (background) {
      'off' || 'solid' => const [0, 0, 0],
      'blurred' => dark ? const [0.3, 0.6, 0.85] : const [0.4, 0.7, 0.9],
      _ => dark ? const [0.15, 0.4, 0.68] : const [0.25, 0.55, 0.8],
    };
    final scrimColor = dark ? Colors.black : Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: eink ? 1 : 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            backdrop,
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [for (final a in scrim) scrimColor.withValues(alpha: a)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: image == null
                          ? _noCover(cs)
                          : Image(image: image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _noCover(cs)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          )
                        else
                          _bar(cs.onSurface.withValues(alpha: 0.5), 120),
                        const SizedBox(height: 3),
                        if (author != null)
                          Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          )
                        else if (title == null)
                          _bar(cs.onSurface.withValues(alpha: 0.25), 80),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: 0.42,
                            minHeight: 5,
                            color: accent,
                            backgroundColor: cs.onSurface.withValues(alpha: 0.14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.replay_10_rounded, size: 22, color: cs.onSurface),
                            const SizedBox(width: 18),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 24,
                                color: accent.computeLuminance() > 0.35 ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Icon(Icons.forward_30_rounded, size: 22, color: cs.onSurface),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _coverImage(String? url, LibraryProvider lib) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('/')) return FileImage(File(url));
    return CachedNetworkImageProvider(url, headers: lib.mediaHeaders);
  }

  Widget _noCover(ColorScheme cs) => ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.headphones_rounded, color: cs.onSurfaceVariant),
      );

  Widget _bar(Color color, double width) => Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      );
}
