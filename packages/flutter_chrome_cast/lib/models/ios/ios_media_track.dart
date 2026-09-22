import 'package:flutter_chrome_cast/lib.dart';

/// Represents a media track for iOS platforms, extending [GoogleCastMediaTrack].
///
/// This class is used to model media track information specific to iOS when working
/// with Google Cast. It provides a convenient way to construct a media track from a map.
class IosMediaTrack extends GoogleCastMediaTrack {
  /// Creates an [IosMediaTrack] instance.
  ///
  /// [trackContentType], [trackId], and [type] are required. Other parameters are optional.
  IosMediaTrack({
    required super.trackContentType,
    required super.trackId,
    required super.type,
    super.customData,
    super.language,
    super.name,
    super.subtype,
    super.trackContentId,
  });

  /// Creates an [IosMediaTrack] from a [Map] representation, typically from platform channels.
  ///
  /// The [json] map should contain keys matching the expected track properties.
  factory IosMediaTrack.fromMap(Map json) {
    return IosMediaTrack(
      trackContentType: json['content_type'] ?? '',
      trackId: json['id'],
      type: TrackType.values[json['type']],
      language: Rfc5646Language.fromMap(json['language_code']),
      name: json['name'],
      subtype: json['subtype'] != null
          ? TextTrackType.values[json['subtype']]
          : null,
      trackContentId: json['content_id'],
      customData: json['custom_data'] != null
          ? Map<String, dynamic>.from(json['custom_data'])
          : null,
    );
  }
}
