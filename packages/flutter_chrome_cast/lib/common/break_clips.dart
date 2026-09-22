import 'dart:convert';

import 'package:flutter_chrome_cast/common/hls_segment_format.dart';
import 'package:flutter_chrome_cast/common/vast_ads_request.dart';

///Represents a break clip (e.g. a clip of an ad during an ad break)

class CastBreakClips {
  ///URL of the page that the sender will display,
  ///when the end user clicks the link on the sender
  ///UI, while the receiver is playing this clip.

  final String? clickThroughUrl;

  /// The URL or content ID of the break media playing on the receiver.

  final String? contentId;

  ///The content MIME type.
  final String? contentType;

  ///Optional break media URL, to allow using contentId
  ///for the real ID. If contentUrl is provided, it will
  /// be used as the media URL, otherwise
  /// the contentId will be used as the media URL.

  final String? contentUrl;

  ///Application-specific break clip data.
  final Map<String, dynamic>? customData;

  ///Duration of a break clip in seconds.
  final Duration? duration;

  ///The format of the HLS media segment.
  final CastHlsSegmentFormat? hlsSegmentFormat;

  ///Unique ID of break clip.
  final String id;

  /// URL of content that the sender will
  ///  display while the receiver is playing this clip.

  final String? posterUrl;

  ///Title of a break clip. Sender might display this on its screen, if provided.
  final String? title;

  ///VAST ad request configuration. Used if contentId or contentUrl is not provided.
  final VastAdsRequest? vastAdsRequest;

  ///The time in seconds when this break clip becomes skippable.
  /// 5 means that end user can skip this break clip after 5 seconds.
  ///  If this field is not defined or is a negative value, it means that
  /// current break clip is not shippable.

  final Duration? whenSkippable;

  /// Creates a new [CastBreakClips] instance.
  ///
  /// [clickThroughUrl] - URL of the page that the sender will display when clicked.
  /// [contentId] - The content ID of the break media.
  /// [contentType] - The content MIME type.
  /// [contentUrl] - Optional break media URL.
  /// [customData] - Application-specific break clip data.
  /// [duration] - Duration of a break clip in seconds.
  /// [hlsSegmentFormat] - The format of the HLS media segment.
  /// [id] - Unique ID of break clip, required.
  /// [posterUrl] - URL of content that the sender will display.
  /// [title] - Title of a break clip.
  /// [vastAdsRequest] - VAST ad request configuration, required.
  /// [whenSkippable] - The time in seconds when this break clip becomes skippable.
  CastBreakClips({
    this.clickThroughUrl,
    this.contentId,
    this.contentType,
    this.contentUrl,
    this.customData,
    this.duration,
    this.hlsSegmentFormat,
    required this.id,
    this.posterUrl,
    this.title,
    this.vastAdsRequest,
    this.whenSkippable,
  });

  /// Converts the break clip object to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'clickThroughUrl': clickThroughUrl,
      'contentId': contentId,
      'contentType': contentType,
      'contentUrl': contentUrl,
      'customData': customData,
      'duration': duration?.inSeconds,
      'hlsSegmentFormat': hlsSegmentFormat?.name,
      'id': id,
      'posterUrl': posterUrl,
      'title': title,
      'vastAdsRequest': vastAdsRequest?.toMap(),
      'whenSkippable': whenSkippable?.inSeconds,
    };
  }

  /// Creates a [CastBreakClips] instance from a map.
  ///
  /// [map] - The map to create the instance from.
  factory CastBreakClips.fromMap(Map<String, dynamic> map) {
    return CastBreakClips(
      clickThroughUrl: map['clickThroughUrl'],
      contentId: map['contentId'],
      contentType: map['contentType'],
      contentUrl: map['contentUrl'],
      customData: map['customData'] != null
          ? Map<String, dynamic>.from(map['customData'])
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'].round())
          : null,
      hlsSegmentFormat: map['hlsSegmentFormat'] != null
          ? CastHlsSegmentFormat.fromMap(map['hlsSegmentFormat'])
          : null,
      id: map['id'] ?? '',
      posterUrl: map['posterUrl'],
      title: map['title'],
      vastAdsRequest: map['vastAdsRequest'] != null
          ? VastAdsRequest.fromMap(map['vastAdsRequest'])
          : null,
      whenSkippable: map['whenSkippable'] != null
          ? Duration(seconds: map['whenSkippable'].round())
          : null,
    );
  }

  /// Converts the [CastBreakClips] to a JSON string.
  ///
  /// Returns a JSON string representation of this object.
  String toJson() => json.encode(toMap());

  /// Creates a [CastBreakClips] from a JSON string.
  ///
  /// [source] - The JSON string to create the instance from.
  factory CastBreakClips.fromJson(String source) =>
      CastBreakClips.fromMap(json.decode(source));
}
