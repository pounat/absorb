import 'dart:convert';

/// Represents current status of a break, including IDs and timing information.
class GoogleCastBrakeStatus {
  /// ID of the current break clip.
  final String? breakClipId;

  /// ID of the current break.
  final String? breakId;

  /// Time in seconds elapsed after the current break clip starts.
  /// This member is only updated sporadically, so its value is often out of date.
  /// Use the getEstimatedBreakClipTime method to get an estimate of the real playback position.
  final Duration? currentBreakClipTime;

  /// Time in seconds elapsed after the current break starts.
  /// This member is only updated sporadically, so its value is often out of date.
  /// Use the getEstimatedBreakTime method to get an estimate of the real playback position.
  final Duration? currentBreakTime;

  /// The time in seconds when this break clip becomes skippable.
  /// If not defined, the current break clip is not skippable.
  final Duration? whenSkippable;

  /// Creates a new [GoogleCastBrakeStatus] instance.
  GoogleCastBrakeStatus({
    this.breakClipId,
    this.breakId,
    this.currentBreakClipTime,
    this.currentBreakTime,
    this.whenSkippable,
  });

  /// Converts the object to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'breakClipId': breakClipId,
      'breakId': breakId,
      'currentBreakClipTime': currentBreakClipTime?.inSeconds,
      'currentBreakTime': currentBreakTime?.inSeconds,
      'whenSkippable': whenSkippable?.inSeconds,
    };
  }

  /// Creates a [GoogleCastBrakeStatus] from a map.
  factory GoogleCastBrakeStatus.fromMap(Map<String, dynamic> map) {
    return GoogleCastBrakeStatus(
      breakClipId: map['breakClipId'],
      breakId: map['breakId'],
      currentBreakClipTime: map['currentBreakClipTime'] != null
          ? Duration(seconds: map['currentBreakClipTime'].toInt())
          : null,
      currentBreakTime: map['currentBreakTime'] != null
          ? Duration(seconds: map['currentBreakTime'].toInt())
          : null,
      whenSkippable: map['whenSkippable'] != null
          ? Duration(seconds: map['whenSkippable'].toInt())
          : null,
    );
  }

  /// Converts the object to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a [GoogleCastBrakeStatus] from a JSON string.
  factory GoogleCastBrakeStatus.fromJson(String source) =>
      GoogleCastBrakeStatus.fromMap(json.decode(source));
}
