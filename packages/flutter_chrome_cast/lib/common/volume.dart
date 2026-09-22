import 'dart:convert';

/// Represents the volume settings for a cast media session.
class CastMediaVolume {
  ///Optional current stream volume level as
  /// a value between 0.0 and 1.0 where 1.0
  ///  is the maximum volume.
  num? level;

  ///Optional whether the Cast device is muted,
  /// independent of the volume level.
  bool? muted;

  /// Creates a new [CastMediaVolume] instance.
  ///
  /// [level] - The volume level between 0.0 and 1.0.
  /// [muted] - Whether the volume is muted.
  ///
  /// Throws an assertion error if level is not between 0 and 1.
  CastMediaVolume(this.level, this.muted)
      : assert(
          level == null || (level >= 0 && level <= 1),
          'level must be between 0 and 1',
        );

  /// Converts the [CastMediaVolume] to a map.
  ///
  /// Returns a [Map] representation of this object.
  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'muted': muted,
    };
  }

  /// Creates a [CastMediaVolume] from a map.
  ///
  /// [map] - The map to create the instance from.
  factory CastMediaVolume.fromMap(Map<String, dynamic> map) {
    return CastMediaVolume(
      map['level'],
      map['muted'],
    );
  }

  /// Converts the [CastMediaVolume] to a JSON string.
  ///
  /// Returns a JSON string representation of this object.
  String toJson() => json.encode(toMap());

  /// Creates a [CastMediaVolume] from a JSON string.
  ///
  /// [source] - The JSON string to create the instance from.
  factory CastMediaVolume.fromJson(String source) =>
      CastMediaVolume.fromMap(json.decode(source));
}
