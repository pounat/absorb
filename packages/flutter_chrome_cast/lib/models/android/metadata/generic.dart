import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific implementation of generic media metadata.
class GoogleCastGenericMediaMetadataAndroid
    extends GoogleCastGenericMediaMetadata {
  /// Creates an Android generic media metadata instance.
  GoogleCastGenericMediaMetadataAndroid({
    required super.title,
    required super.subtitle,
    required super.images,
    super.releaseDate,
  });

  /// Creates a generic media metadata instance from a map.
  factory GoogleCastGenericMediaMetadataAndroid.fromMap(
      Map<String, dynamic> map) {
    return GoogleCastGenericMediaMetadataAndroid(
      title: map['title'],
      subtitle: map['subtitle'],
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
