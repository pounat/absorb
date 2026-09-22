import 'package:flutter_chrome_cast/lib.dart';

/// iOS-specific implementation of generic media metadata.
class GoogleCastGenericMediaMetadataIOS extends GoogleCastGenericMediaMetadata {
  /// Creates an iOS generic media metadata instance.
  GoogleCastGenericMediaMetadataIOS({
    required super.title,
    required super.subtitle,
    required super.images,
    super.releaseDate,
  });

  /// Creates a generic media metadata instance from a map.
  factory GoogleCastGenericMediaMetadataIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastGenericMediaMetadataIOS(
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
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
