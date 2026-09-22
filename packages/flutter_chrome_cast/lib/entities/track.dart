import 'dart:convert';

import 'package:flutter_chrome_cast/common/rfc5646_language.dart';
import 'package:flutter_chrome_cast/enums/text_track_type.dart';
import 'package:flutter_chrome_cast/enums/track_type.dart';
import 'package:flutter_chrome_cast/models/android/extensions/track_type.dart';

/// Represents a media track, including content type, ID, type, and serialization helpers.
class GoogleCastMediaTrack {
  /// Custom data for the track.
  final Map<String, dynamic>? customData;

  /// Language of the track.
  final Rfc5646Language? language;

  /// Name of the track.
  final String? name;

  /// Subtype of the track.
  final TextTrackType? subtype;

  /// Content ID of the track.
  final String? trackContentId;

  /// Content type of the track.
  final String trackContentType;

  /// Unique identifier of the track within the context of a MediaInfo object.
  final int trackId;

  /// The type of track.
  final TrackType type;

  /// Creates a new [GoogleCastMediaTrack] instance.
  GoogleCastMediaTrack({
    this.customData,
    this.language,
    this.name,
    this.subtype,
    this.trackContentId,
    required this.trackContentType,
    required this.trackId,
    required this.type,
  });

  /// Converts the object to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'customData': customData,
      'language': language?.toString(),
      'name': name,
      'subtype': subtype?.index,
      'trackContentId': trackContentId,
      'trackContentType': trackContentType,
      'trackId': trackId,
      'type': type.index,
    };
  }

  /// Creates a [GoogleCastMediaTrack] from a map.
  factory GoogleCastMediaTrack.fromMap(Map<String, dynamic> map) {
    return GoogleCastMediaTrack(
      customData: Map<String, dynamic>.from(map['customData'] ?? {}),
      language: map['language'] != null
          ? Rfc5646Language.fromMap(map['language'])
          : null,
      name: map['name'],
      subtype: map['subtype'] != null
          ? TextTrackType.values.firstWhere(
              (e) => e.name == map['subtype'],
              orElse: () => TextTrackType.unknown,
            )
          : null,
      trackContentId: map['trackContentId'],
      trackContentType: map['trackContentType'],
      trackId: map['trackId']?.toInt() ?? 0,
      type: GoogleCastTrackTypeAndroid.fromMap(map['type']),
    );
  }

  /// Converts the object to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a [GoogleCastMediaTrack] from a JSON string.
  factory GoogleCastMediaTrack.fromJson(String source) =>
      GoogleCastMediaTrack.fromMap(json.decode(source));
}
