import 'dart:convert';

///Provides the live seekable range with start and end time in seconds.
class GoogleCastMediaLiveSeekableRange {
  ///End of the seekable range in seconds.
  /// This member is only updated sporadically,
  /// so its value is often out of date. Use
  ///  the getEstimatedLiveSeekableRange method
  ///  to get an estimate of the real position
  /// based on the last information reported
  /// by the receiver.
  final Duration? end;

  ///A boolean value indicates whether
  ///a live stream is ended. If it
  ///is done, the end of live seekable
  /// range should stop updating.
  final bool? isLiveDone;

  ///A boolean value indicates whether
  /// the live seekable range is a moving window.
  ///  If false, it will be either a expanding
  ///  range or a fixed range meaning live has ended.
  final bool? isMovingWindow;

  ///Start of the seekable range in seconds.
  ///This member is only updated sporadically,
  /// so its value is often out of date. Use
  /// the getEstimatedLiveSeekableRange method
  /// to get an estimate of the real position
  ///  based on the last information reported
  ///  by the receiver.
  final Duration? start;

  /// Creates a new [GoogleCastMediaLiveSeekableRange] instance.
  ///
  /// [end] - End of the seekable range in seconds.
  /// [isLiveDone] - Whether the live stream is ended.
  /// [isMovingWindow] - Whether the live seekable range is a moving window.
  /// [start] - Start of the seekable range in seconds.
  GoogleCastMediaLiveSeekableRange({
    this.end,
    this.isLiveDone,
    this.isMovingWindow,
    this.start,
  });

  /// Converts the [GoogleCastMediaLiveSeekableRange] to a map.
  ///
  /// Returns a [Map] representation of this object.
  Map<String, dynamic> toMap() {
    return {
      'end': end?.inSeconds,
      'isLiveDone': isLiveDone,
      'isMovingWindow': isMovingWindow,
      'start': start?.inSeconds,
    };
  }

  /// Creates a [GoogleCastMediaLiveSeekableRange] from a map.
  ///
  /// [map] - The map to create the instance from.
  factory GoogleCastMediaLiveSeekableRange.fromMap(Map<String, dynamic> map) {
    return GoogleCastMediaLiveSeekableRange(
      end: map['end'] != null ? Duration(seconds: map['end'].toInt()) : null,
      isLiveDone: map['isLiveDone'],
      isMovingWindow: map['isMovingWindow'],
      start:
          map['start'] != null ? Duration(seconds: map['start'].toInt()) : null,
    );
  }

  /// Converts the [GoogleCastMediaLiveSeekableRange] to a JSON string.
  ///
  /// Returns a JSON string representation of this object.
  String toJson() => json.encode(toMap());

  /// Creates a [GoogleCastMediaLiveSeekableRange] from a JSON string.
  ///
  /// [source] - The JSON string to create the instance from.
  factory GoogleCastMediaLiveSeekableRange.fromJson(String source) =>
      GoogleCastMediaLiveSeekableRange.fromMap(json.decode(source));
}
