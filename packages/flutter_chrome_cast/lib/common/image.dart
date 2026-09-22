import 'dart:convert';

/// Represents an image for Google Cast.
class GoogleCastImage {
  ///url 	URI 	URI for the image
  final Uri url;

  ///height 	integer 	optional Height of the image
  final int? height;

  ///width 	integer 	optional Width of the image
  final int? width;

  /// Creates a new [GoogleCastImage] instance.
  GoogleCastImage({
    required this.url,
    this.height,
    this.width,
  });

  /// Converts this image to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'url': url.toString(),
      'height': height,
      'width': width,
    };
  }

  /// Creates a [GoogleCastImage] from a map representation.
  /// Returns null if the URL is missing or invalid.
  static GoogleCastImage? fromMap(Map<String, dynamic> map) {
    final urlString = map['url'];
    if (urlString == null || urlString is! String || urlString.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(urlString);
    if (uri == null) return null;
    return GoogleCastImage(
      url: uri,
      height: map['height']?.toInt(),
      width: map['width']?.toInt(),
    );
  }

  /// Converts this image to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a [GoogleCastImage] from a JSON string.
  static GoogleCastImage? fromJson(String source) =>
      GoogleCastImage.fromMap(json.decode(source));
}
