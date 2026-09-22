import 'package:flutter_chrome_cast/common/image.dart';
import 'package:flutter_chrome_cast/entities/media_metadata/music_track_media_metadata.dart';
import 'package:flutter_chrome_cast/models/android/extensions/date_time.dart';

/// Android-specific implementation of music media metadata.
class GoogleCastMusicMediaMetadataAndroid extends GoogleCastMusicMediaMetadata {
  /// Creates an Android music media metadata instance.
  GoogleCastMusicMediaMetadataAndroid({
    super.albumArtist,
    super.albumName,
    super.artist,
    super.composer,
    super.discNumber,
    super.images,
    super.releaseDate,
    super.title,
    super.trackNumber,
  });

  /// Creates a music media metadata instance from a map.
  factory GoogleCastMusicMediaMetadataAndroid.fromMap(
      Map<String, dynamic> map) {
    return GoogleCastMusicMediaMetadataAndroid(
      albumName: map['albumName'],
      title: map['title'],
      albumArtist: map['albumArtist'],
      artist: map['artist'],
      composer: map['composer'],
      trackNumber: map['trackNumber']?.toInt(),
      discNumber: map['discNumber']?.toInt(),
      images: map['images'] != null
          ? List<GoogleCastImage>.from(
              map['images']?.map((x) => GoogleCastImage.fromMap(x)))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTimeString.tryParse(map['releaseDate'])
          : null,
    );
  }
}
