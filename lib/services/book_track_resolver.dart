import 'dart:convert';

import '../utils/episode_key.dart';
import 'api_service.dart';
import 'download_service.dart';

/// One playable track of a book: a local file path / SAF content URI, or a
/// streamed per-file URL, plus its duration in seconds.
typedef BookTrack = ({String source, double duration, bool local});

/// A global book position resolved to the track that contains it.
typedef TrackHit = ({int index, double localOffset, BookTrack track});

/// Resolves a book's audio tracks the same way for everything that needs to
/// reach into the raw files (bookmark preview, clip export): downloaded books
/// use the local files + cached track durations; streamed books build per-file
/// URLs from the library item. Kept in one place so the preview player and the
/// exporter can't drift apart on multi-file mapping.
///
/// [itemId] may be a podcast's compound "showId-episodeId" key. Downloads and
/// cached sessions are stored under the whole key; the API needs the show id
/// and the episode's own audio file.
class BookTrackResolver {
  static Future<List<BookTrack>?> resolve(String itemId, ApiService? api) async {
    // Downloaded book: local files + cached track durations.
    final localPaths = DownloadService().getLocalPaths(itemId);
    final sessionRaw = DownloadService().getCachedSessionData(itemId);
    if (localPaths != null && localPaths.isNotEmpty && sessionRaw != null) {
      try {
        final session = jsonDecode(sessionRaw) as Map<String, dynamic>;
        final audioTracks = session['audioTracks'] as List<dynamic>?;
        if (audioTracks != null && audioTracks.length == localPaths.length) {
          return [
            for (var i = 0; i < localPaths.length; i++)
              (
                source: localPaths[i],
                duration: ((audioTracks[i] as Map<String, dynamic>)['duration']
                            as num?)
                        ?.toDouble() ??
                    0,
                local: true,
              ),
          ];
        }
      } catch (_) {}
    }

    // Streamed book: build per-file URLs from the library item.
    if (api == null) return null;
    final ids = splitEpisodeKey(itemId);
    final item = await api.getLibraryItem(ids.itemId);
    if (item == null) return null;
    final media = item['media'] as Map<String, dynamic>? ?? {};

    // A podcast item has no audioFiles - each episode carries its own single
    // file, and its bookmark times are relative to that file.
    final episodeId = ids.episodeId;
    if (episodeId != null) {
      for (final ep in ((media['episodes'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()) {
        if (ep['id'] != episodeId) continue;
        final af = ep['audioFile'] as Map<String, dynamic>?;
        final ino = af?['ino']?.toString();
        if (ino == null || ino.isEmpty) return null;
        return [
          (
            source: api.buildFileUrl(ids.itemId, ino),
            duration: (af?['duration'] as num?)?.toDouble() ??
                (ep['duration'] as num?)?.toDouble() ??
                0,
            local: false,
          ),
        ];
      }
      return null;
    }

    final audioFiles = ((media['audioFiles'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) =>
          ((a['index'] as num?) ?? 0).compareTo((b['index'] as num?) ?? 0));
    if (audioFiles.isEmpty) return null;
    return [
      for (final af in audioFiles)
        (
          source: api.buildFileUrl(ids.itemId, af['ino']?.toString() ?? ''),
          duration: (af['duration'] as num?)?.toDouble() ?? 0,
          local: false,
        ),
    ];
  }

  /// Map a global position (seconds from book start) to a track + local offset
  /// within it. Falls back to the last track when the position runs past the
  /// summed durations (e.g. unknown per-track durations).
  static TrackHit mapGlobal(List<BookTrack> tracks, double globalSeconds) {
    var acc = 0.0;
    var idx = tracks.length - 1;
    var local = globalSeconds;
    for (var i = 0; i < tracks.length; i++) {
      if (globalSeconds < acc + tracks[i].duration || i == tracks.length - 1) {
        idx = i;
        final upper = tracks[i].duration > 0 ? tracks[i].duration : globalSeconds;
        local = (globalSeconds - acc).clamp(0.0, upper);
        break;
      }
      acc += tracks[i].duration;
    }
    return (index: idx, localOffset: local, track: tracks[idx]);
  }
}
