import 'package:flutter_chrome_cast/common/image.dart';
import 'package:flutter_chrome_cast/entities/media_metadata/music_track_media_metadata.dart';

/// iOS-specific implementation of music media metadata.
class GoogleCastMusicMediaMetadataIOS extends GoogleCastMusicMediaMetadata {
  /// Creates an iOS music media metadata instance.
  GoogleCastMusicMediaMetadataIOS({
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
  factory GoogleCastMusicMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastMusicMediaMetadataIOS(
      albumName: map['albumTitle'] as String?,
      title: map['title'] as String?,
      albumArtist: map['albumArtist'] as String?,
      artist: map['artist'] as String?,
      composer: map['composer'] as String?,
      trackNumber: map['trackNumber']?.toInt(),
      discNumber: map['discNumber']?.toInt(),
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
