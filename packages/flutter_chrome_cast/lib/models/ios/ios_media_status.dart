import 'package:flutter_chrome_cast/lib.dart';

/// Represents the media status for a Google Cast session on iOS.
///
/// This class extends [GoggleCastMediaStatus] and provides additional
/// iOS-specific mapping and construction from platform channel data.
class GoogleCastIOSMediaStatus extends GoggleCastMediaStatus {
  /// Creates a new [GoogleCastIOSMediaStatus] instance.
  ///
  /// All parameters are forwarded to the base [GoggleCastMediaStatus].
  GoogleCastIOSMediaStatus({
    required super.mediaSessionID,
    required super.playerState,
    required super.playbackRate,
    required super.volume,
    required super.isMuted,
    required super.repeatMode,
    super.activeTrackIds,
    super.adBreakStatus,
    super.currentItemId,
    super.idleReason,
    super.liveSeekableRange,
    super.mediaInformation,
    // super.queueData,
  });

  /// Creates a [GoogleCastIOSMediaStatus] from a map received from the platform channel.
  ///
  /// The [map] parameter must contain the expected keys and value types as sent from iOS.
  factory GoogleCastIOSMediaStatus.fromMap(Map<String, dynamic> map) {
    return GoogleCastIOSMediaStatus(
      mediaSessionID: map['mediaSessionID']?.toInt() ?? 0,
      playerState: CastMediaPlayerState.values[map['playerState']],
      idleReason: map['idleReason'] != null
          ? GoogleCastMediaIdleReason.values[map['idleReason']]
          : null,
      playbackRate: map['playbackRate'] ?? 0,
      mediaInformation: map['mediaInformation'] != null
          ? GoogleCastMediaInformationIOS.fromMap(
              Map<String, dynamic>.from(map['mediaInformation']))
          : null,

      volume: map['volume'] ?? 0,
      isMuted: map['isMuted'] ?? true,
      repeatMode: GoogleCastMediaRepeatMode.values[(map['repeatMode'])],
      currentItemId: map['currentItemId']?.toInt(),

      activeTrackIds: map['activeTrackIds'] != null
          ? List<int>.from(map['activeTrackIds'])
          : [],
      // adBreakStatus: map['adBreakStatus'] != null
      //     ? GoogleCastBrakeStatus.fromMap(map['adBreakStatus'])
      //     : null,
      liveSeekableRange: map['liveSeekableRange'] != null
          ? GoogleCastMediaLiveSeekableRange.fromMap(map['liveSeekableRange'])
          : null,
      // queueData: map['queueData'] != null
      //     ? GoogleCastMediaQueueData.fromMap(map['queueData'])
      //     : null,
    );
  }
}
