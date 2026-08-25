/// Podcast episodes are addressed by a compound "showId-episodeId" key
/// wherever the app stores per-item state - downloads, progress, bookmarks.
/// Books keep their plain 36-character item id. These three helpers put the
/// substring arithmetic in one place.
library;

bool isEpisodeKey(String key) => key.length > 36;

String episodeKeyFor(String itemId, String? episodeId) =>
    (episodeId != null && episodeId.isNotEmpty) ? '$itemId-$episodeId' : itemId;

/// Split a storage key back into the item id the server knows and, for a
/// podcast, the episode inside it.
({String itemId, String? episodeId}) splitEpisodeKey(String key) =>
    isEpisodeKey(key)
        ? (itemId: key.substring(0, 36), episodeId: key.substring(37))
        : (itemId: key, episodeId: null);
