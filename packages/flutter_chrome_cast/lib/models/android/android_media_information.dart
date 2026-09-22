import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific extension of [GoogleCastMediaInformation].
class GoogleCastMediaInformationAndroid extends GoogleCastMediaInformation {
  /// Creates a new [GoogleCastMediaInformationAndroid] instance.
  GoogleCastMediaInformationAndroid({
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

  /// Creates a [GoogleCastMediaInformationAndroid] from a map.
  factory GoogleCastMediaInformationAndroid.fromMap(Map<String, dynamic> map) {
    return GoogleCastMediaInformationAndroid(
      atvEntity: map['atvEntity'],
      breakClips: map['breakClips'] != null
          ? List<CastBreakClips>.from(
              map['breakClips']?.map((x) => CastBreakClips.fromMap(x)))
          : null,
      contentId: map['contentId'] ?? '',
      streamType: GoogleCastAndroidStreamType.fromMap(map['streamType']),
      contentType: map['contentType'] ?? '',
      metadata: map['metadata'] != null
          ? _getCastMediaMetadata(Map.from(map['metadata']))
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'].round())
          : null,
      customData: Map<String, dynamic>.from(map['customData'] ?? {}),
      breaks: map['breaks'] != null
          ? List<CastBreak>.from(
              map['breaks']?.map((x) => CastBreak.fromMap(x)))
          : null,
      contentUrl: Uri.tryParse(map['contentUrl'] ?? ''),
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
          ? List<GoogleCastMediaTrack>.from(map['tracks']?.map((x) =>
              GoogleCastMediaTrack.fromMap(Map<String, dynamic>.from(x))))
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
  final type = map['metadataType'] as int;
  GoogleCastMediaMetadata? metadata;
  switch (type) {
    //Generic
    case 0:
      metadata = GoogleCastGenericMediaMetadataAndroid.fromMap(map);
      break;
    //MOVIE
    case 1:
      metadata = GoogleCastMovieMediaMetadataAndroid.fromMap(map);
      break;
    //TV SHOW
    case 2:
      metadata = GoogleCastTvShowMediaMetadataAndroid.fromMap(map);
      break;
    //Music
    case 3:
      metadata = GoogleCastMusicMediaMetadataAndroid.fromMap(map);
      break;
    //Photo
    case 4:
      metadata = GooglCastPhotoMediaMetadataAndroid.fromMap(map);
      break;
    default:
  }
  return metadata;
}
