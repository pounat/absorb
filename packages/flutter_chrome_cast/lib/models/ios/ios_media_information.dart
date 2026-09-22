import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/models/ios/ios_media_track.dart';

import 'metadata/generic.dart';
import 'metadata/movie.dart';
import 'metadata/music.dart';
import 'metadata/photo.dart';
import 'metadata/tv_show.dart';

/// iOS-specific implementation of [GoogleCastMediaInformation].
///
/// This class represents the media information required to load and control media playback
/// on Google Cast devices from iOS. It extends the cross-platform [GoogleCastMediaInformation]
/// and provides a factory for constructing from a platform channel map.
///
/// Typical usage involves creating an instance with all required media details, or using
/// [GoogleCastMediaInformationIOS.fromMap] to parse data received from the native iOS layer.
///
/// See also:
/// - [GoogleCastMediaInformation] for the base class and common fields
/// - [GoogleCastRemoteMediaClient] for loading and controlling media
/// - [GoogleCastMediaTrack] for track details
/// - [GoogleCastMediaMetadataType] for supported metadata types
class GoogleCastMediaInformationIOS extends GoogleCastMediaInformation {
  /// Creates a new [GoogleCastMediaInformationIOS] instance.
  ///
  /// All parameters are forwarded to the base [GoogleCastMediaInformation].
  GoogleCastMediaInformationIOS({
    required super.contentId,
    required super.streamType,
    required super.contentType,
    super.atvEntity,
    super.breakClips,
    super.breaks,
    super.contentUrl,
    super.customData,
    super.duration,
    super.entity,
    super.hlsSegmentFormat,
    super.hlsVideoSegmentFormat,
    super.metadata,
    super.startAbsoluteTime,
    super.textTrackStyle,
    super.tracks,
    super.userActionStates,
    super.vmapAdsRequest,
  });

  /// Creates a [GoogleCastMediaInformationIOS] from a [Map] received from the platform channel.
  ///
  /// The [map] parameter must contain the expected keys and value types as sent from iOS.
  factory GoogleCastMediaInformationIOS.fromMap(Map<String, dynamic> map) {
    return GoogleCastMediaInformationIOS(
      atvEntity: map['atvEntity'],
      breakClips: map['breakClips'] != null
          ? List<CastBreakClips>.from(
              map['breakClips']?.map((x) => CastBreakClips.fromMap(x)))
          : null,
      contentId: map['contentID'] ?? '',
      streamType: CastMediaStreamType.values[map['streamType']],
      contentType: map['contentType'] ?? '',
      metadata: map['metadata'] != null
          ? _getCastMediaMetadata(Map<String, dynamic>.from(map['metadata']))
          : null,
      duration: map['duration'] != null
          ? Duration(milliseconds: (map['duration'] * 1000).round())
          : null,
      customData: map['customData'] != null
          ? Map<String, dynamic>.from(map['customData'])
          : null,
      breaks: map['breaks'] != null
          ? List<CastBreak>.from(
              map['breaks']?.map((x) => CastBreak.fromMap(x)))
          : null,
      contentUrl: Uri.tryParse(map['contentURL'] ?? ''),
      entity: map['entity'],
      hlsSegmentFormat: map['hlsSegmentFormat'] != null
          ? CastHlsSegmentFormat.fromMap(map['hlsSegmentFormat'])
          : null,
      hlsVideoSegmentFormat: map['hlsVideoSegmentFormat'] != null
          ? HlsVideoSegmentFormat.fromMap(map['hlsVideoSegmentFormat'])
          : null,
      startAbsoluteTime: map['startAbsoluteTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startAbsoluteTime'])
          : null,
      textTrackStyle: map['textTrackStyle'] != null
          ? TextTrackStyle.fromMap(map['textTrackStyle'])
          : null,
      tracks: map['tracks'] != null
          ? List<GoogleCastMediaTrack>.from(
              map['tracks']?.map(
                (x) => IosMediaTrack.fromMap(x),
              ),
            )
          : null,
      userActionStates: map['userActionStates'] != null
          ? List<UserActionState>.from(
              map['userActionStates']?.map((x) => UserActionState.fromMap(x)))
          : null,
      vmapAdsRequest: map['vmapAdsRequest'] != null
          ? VastAdsRequest.fromMap(map['vmapAdsRequest'])
          : null,
    );
  }
}

GoogleCastMediaMetadata? _getCastMediaMetadata(Map<String, dynamic> map) {
  final typeIndex = map['type'] ?? map['metadataType'];
  if (typeIndex == null) return null;
  final type = GoogleCastMediaMetadataType.values[typeIndex];
  if (type == GoogleCastMediaMetadataType.genericMediaMetadata) {
    return GoogleCastGenericMediaMetadataIOS.fromMap(map);
  } else if (type == GoogleCastMediaMetadataType.movieMediaMetadata) {
    return GoogleCastMovieMediaMetadataIOS.fromMap(map);
  } else if (type == GoogleCastMediaMetadataType.tvShowMediaMetadata) {
    return GoogleCastTvShowMediaMetadataIOS.fromMap(map);
  } else if (type == GoogleCastMediaMetadataType.musicTrackMediaMetadata) {
    return GoogleCastMusicMediaMetadataIOS.fromMap(map);
  } else if (type == GoogleCastMediaMetadataType.photoMediaMetadata) {
    return GooglCastPhotoMediaMetadataIOS.fromMap(map);
  } else {
    return null;
  }
}
