import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific implementation of TV show media metadata.
class GoogleCastTvShowMediaMetadataAndroid
    extends GoogleCastTvShowMediaMetadata {
  /// Creates an Android TV show media metadata instance.
  GoogleCastTvShowMediaMetadataAndroid({
    super.episode,
    super.images,
    super.originalAirDate,
    super.season,
    super.seriesTitle,
  });

  /// Creates a TV show media metadata instance from a map.
  factory GoogleCastTvShowMediaMetadataAndroid.fromMap(
      Map<String, dynamic> map) {
    return GoogleCastTvShowMediaMetadataAndroid(
      seriesTitle: map['seriesTitle'],
      season: map['season']?.toInt(),
      episode: map['episode']?.toInt(),
      images: map['images'] != null
          ? List<GoogleCastImage>.from(
              map['images']?.map((x) => GoogleCastImage.fromMap(x)))
          : null,
      originalAirDate: map['originalAirDate'] != null
          ? DateTimeString.tryParse(map['originalAirDate'])
          : null,
    );
  }
}
