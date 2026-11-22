import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show rootNavigatorKey;
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../utils/cover_accent.dart';
import '../widgets/glass_look.dart' show solidCoverBackground;
import '../widgets/overlay_toast.dart';
import 'tv_cover_tile.dart';

/// Where [key]'s widget sits on screen, for growing the player out of it.
Rect? tvRectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The episode an Absorbing entry stands for, when it is one.
Map<String, dynamic>? tvEpisodeOf(Map<String, dynamic> item) => (item['recentEpisode'] as Map?)?.cast<String, dynamic>();

/// Starts [item], or [episode] of it, unless it is already the one loaded,
/// in which case it just plays. Returns the map the player card shows.
Future<Map<String, dynamic>> startTvPlayback(
  BuildContext context,
  Map<String, dynamic> item, {
  Map<String, dynamic>? episode,
  bool fromStart = false,
}) async {
  final api = context.read<AuthProvider>().apiService;
  final lib = context.read<LibraryProvider>();
  final player = AudioPlayerService();
  final itemId = item['id'] as String? ?? '';
  final episodeId = episode?['id'] as String?;
  final key = episodeId == null ? itemId : '$itemId-$episodeId';
  final cardItem = tvCardItem(item, episode);
  if (api == null || itemId.isEmpty) return cardItem;

  if (player.currentItemId == itemId && player.currentEpisodeId == episodeId) {
    if (fromStart) unawaited(player.seekTo(Duration.zero));
    if (!player.isPlaying) unawaited(player.play(fromUi: true));
    return cardItem;
  }

  unawaited(() async {
    var full = item;
    var media = (full['media'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    // Shelf entries come without chapters or a length; fetch the real thing.
    if (episode == null && media['chapters'] == null) {
      final fetched = await api.getLibraryItem(itemId);
      if (fetched != null) {
        full = fetched;
        media = (full['media'] as Map?)?.cast<String, dynamic>() ?? media;
      }
    }
    final names = tvItemNames(full);
    final episodeTitle = episode?['title'] as String?;
    final error = await player.playItem(
      api: api,
      itemId: itemId,
      title: episodeTitle ?? names.title,
      author: episode != null ? names.title : names.author,
      coverUrl: api.getCoverUrl(itemId),
      totalDuration: ((episode ?? media)['duration'] as num?)?.toDouble() ?? 0,
      chapters: ((episode ?? media)['chapters'] as List<dynamic>?) ?? const [],
      episodeId: episodeId,
      episodeTitle: episodeTitle,
      libraryId: full['libraryId'] as String?,
      fromUi: true,
      startTime: 0,
      forceStartTime: fromStart,
    );
    if (error != null) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) showOverlayToast(ctx, error, icon: Icons.error_outline_rounded);
      return;
    }
    unawaited(lib.rememberStartedInAbsorbing(key, cardItem));
  }());
  return cardItem;
}

/// The map the player card shows for [item], or [episode] of it.
Map<String, dynamic> tvCardItem(Map<String, dynamic> item, Map<String, dynamic>? episode) {
  final episodeId = episode?['id'] as String?;
  if (episodeId == null) return item;
  return {...item, 'recentEpisode': episode, '_absorbingKey': '${item['id']}-$episodeId'};
}

/// A book's cover color as the TV uses it behind things: the cover's own
/// shade, deepened into a background, once known.
Color tvCoverColor(BuildContext context, String? itemId, {VoidCallback? onFound}) {
  final fallback = solidCoverBackground(Theme.of(context).colorScheme.primary, dark: true);
  final lib = context.read<LibraryProvider>();
  final url = lib.getCoverUrl(itemId);
  if (url == null || url.isEmpty) return fallback;
  final known = CoverAccents.known(url);
  if (known != null) return solidCoverBackground(known, dark: true);
  if (onFound != null) {
    CoverAccents.seed(url, CachedNetworkImageProvider(url, headers: lib.mediaHeaders)).then((c) {
      if (c != null) onFound();
    }).catchError((_) {});
  }
  return fallback;
}
