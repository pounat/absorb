import 'package:flutter_chrome_cast/lib.dart';

/// iOS-specific implementation of TV show media metadata.
class GoogleCastTvShowMediaMetadataIOS extends GoogleCastTvShowMediaMetadata {
  /// Creates an iOS TV show media metadata instance.
  GoogleCastTvShowMediaMetadataIOS({
    super.episode,
    super.images,
    super.originalAirDate,
    super.season,
    super.seriesTitle,
  });

  /// Creates a TV show media metadata instance from a map.
  factory GoogleCastTvShowMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastTvShowMediaMetadataIOS(
      seriesTitle: map['seriesTitle'] as String?,
      season: map['seasonNumber']?.toInt(),
      episode: map['episodeNumber']?.toInt(),
      images: map['images'] != null
          ? (map['images'] as List)
              .map((x) => GoogleCastImage.fromMap(Map<String, dynamic>.from(x)))
              .whereType<GoogleCastImage>()
              .toList()
          : null,
      originalAirDate: map['releaseDate'] != null
          ? DateTimeString.tryParse(map['releaseDate'])
          : null,
    );
  }
}
