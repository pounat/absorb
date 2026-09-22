import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific implementation of photo media metadata.
class GooglCastPhotoMediaMetadataAndroid extends GoogleCastPhotoMediaMetadata {
  /// Creates an Android photo media metadata instance.
  GooglCastPhotoMediaMetadataAndroid({
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
  factory GooglCastPhotoMediaMetadataAndroid.fromMap(Map<String, dynamic> map) {
    return GooglCastPhotoMediaMetadataAndroid(
      title: map['title'],
      artist: map['artist'],
      location: map['location'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      width: map['width']?.toInt(),
      height: map['height']?.toInt(),
      creationDateTime: map['creationDateTime'] != null
          ? DateTimeString.tryParse(map['creationDateTime'])
          : null,
    );
  }
}
