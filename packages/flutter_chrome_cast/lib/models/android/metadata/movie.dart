import 'package:flutter_chrome_cast/common/image.dart';
import 'package:flutter_chrome_cast/entities/media_metadata/movie_media_metadata.dart';
import 'package:flutter_chrome_cast/models/android/extensions/date_time.dart';

/// Android-specific implementation of movie media metadata.
class GoogleCastMovieMediaMetadataAndroid extends GoogleCastMovieMediaMetadata {
  /// Creates an Android movie media metadata instance.
  GoogleCastMovieMediaMetadataAndroid({
    super.images,
    super.releaseDate,
    super.studio,
    super.subtitle,
    super.title,
  });

  /// Creates a movie media metadata instance from a map.
  factory GoogleCastMovieMediaMetadataAndroid.fromMap(
      Map<String, dynamic> map) {
    return GoogleCastMovieMediaMetadataAndroid(
      title: map['title'],
      subtitle: map['subtitle'],
      studio: map['studio'],
      images: map['images'] != null
          ? List<GoogleCastImage>.from(
              map['images']?.map((x) => GoogleCastImage.fromMap(x)))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTimeString.tryParse(map['releaseDate'] ?? '')
          : null,
    );
  }
}
