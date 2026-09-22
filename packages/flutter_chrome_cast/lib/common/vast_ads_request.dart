import 'dart:convert';

///VAST ad request configuration.
class VastAdsRequest {
  /// Specifies a VAST document to be used as
  /// the ads response instead of making a request
  /// via an ad tag URL. This can be useful for debugging
  /// and other situations where a VAST
  ///  response is already available.

  final String? adsResponse;

  /// URL for VAST file.

  final String? adTagUrl;

  /// Creates a new [VastAdsRequest] instance.
  ///
  /// [adsResponse] - Specifies a VAST document to be used as the ads response.
  /// [adTagUrl] - URL for VAST file.
  VastAdsRequest({
    this.adsResponse,
    this.adTagUrl,
  });

  /// Converts the [VastAdsRequest] to a map.
  ///
  /// Returns a [Map] representation of this object.
  Map<String, dynamic> toMap() {
    return {
      'adsResponse': adsResponse,
      'adTagUrl': adTagUrl,
    };
  }

  /// Creates a [VastAdsRequest] from a map.
  ///
  /// [map] - The map to create the instance from.
  factory VastAdsRequest.fromMap(Map<String, dynamic> map) {
    return VastAdsRequest(
      adsResponse: map['adsResponse'],
      adTagUrl: map['adTagUrl'],
    );
  }

  /// Converts the [VastAdsRequest] to a JSON string.
  ///
  /// Returns a JSON string representation of this object.
  String toJson() => json.encode(toMap());

  /// Creates a [VastAdsRequest] from a JSON string.
  ///
  /// [source] - The JSON string to create the instance from.
  factory VastAdsRequest.fromJson(String source) =>
      VastAdsRequest.fromMap(json.decode(source));
}
