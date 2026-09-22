import 'package:flutter_chrome_cast/common/image.dart';
import 'package:flutter_chrome_cast/entities/media_metadata/movie_media_metadata.dart';

/// iOS-specific implementation of movie media metadata.
class GoogleCastMovieMediaMetadataIOS extends GoogleCastMovieMediaMetadata {
  /// Creates an iOS movie media metadata instance.
  GoogleCastMovieMediaMetadataIOS({
    super.images,
    super.releaseDate,
    super.studio,
    super.subtitle,
    super.title,
  });

  /// Creates a movie media metadata instance from a map.
  factory GoogleCastMovieMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastMovieMediaMetadataIOS(
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      studio: map['studio'] as String?,
      images: map['images'] != null
          ? (map['images'] as List)
              .map((x) => GoogleCastImage.fromMap(Map<String, dynamic>.from(x)))
              .whereType<GoogleCastImage>()
              .toList()
          : null,
      releaseDate: map['releaseDate'] != null && map['releaseDate'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['releaseDate'])
          : null,
    );
  }
}
