import 'package:flutter_chrome_cast/lib.dart';

/// iOS-specific implementation of photo media metadata.
class GooglCastPhotoMediaMetadataIOS extends GoogleCastPhotoMediaMetadata {
  /// Creates an iOS photo media metadata instance.
  GooglCastPhotoMediaMetadataIOS({
    super.artist,
    super.creationDateTime,
    super.height,
    super.latitude,
    super.location,
    super.longitude,
    super.title,
    super.width,
  });

  /// Creates a photo media metadata instance from a map.
  factory GooglCastPhotoMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GooglCastPhotoMediaMetadataIOS(
      title: map['title'],
      artist: map['albumArtist'],
      location: map['locationName'],
      latitude: map['locationLatitude']?.toDouble(),
      longitude: map['locationLongitude']?.toDouble(),
      width: map['width']?.toInt(),
      height: map['height']?.toInt(),
      creationDateTime: map['creationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['creationDate'] ?? 0)
          : null,
    );
  }
}
