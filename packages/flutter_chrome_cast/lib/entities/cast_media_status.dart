import 'package:flutter_chrome_cast/common/live_seekable_range.dart';
import 'package:flutter_chrome_cast/enums/repeat_mode.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/enums/idle_reason.dart';
import 'package:flutter_chrome_cast/enums/player_state.dart';
import 'break_status.dart';

/// Represents the status of a media session, including player state, volume, repeat mode, and more.
class GoggleCastMediaStatus {
  /// Unique ID for the playback of this specific session.
  final int mediaSessionID;

  /// Describes the state of the player as one of the following: [CastMediaPlayerState].
  final CastMediaPlayerState playerState;

  /// If the playerState is IDLE and the reason it became IDLE is known, this property is provided.
  final GoogleCastMediaIdleReason? idleReason;

  /// Indicates whether the media time is progressing, and at what rate.
  /// 1.0 is regular time, 0.5 is slow motion.
  final num playbackRate;

  /// The media information for the current session.
  final GoogleCastMediaInformation? mediaInformation;

  /// The current position of the media player since the beginning of the content, in seconds.
  /// For live streams, this is the time from the beginning of the event.
  final num volume;

  /// The stream muted state.
  final bool isMuted;

  /// The repeat mode for playing the queue.
  final GoogleCastMediaRepeatMode repeatMode;

  /// Item ID of the item that was active in the queue (it may not be playing)
  /// at the time the media status change happened.
  final int? currentItemId;

  /// List of IDs corresponding to the active Tracks.
  final List<int>? activeTrackIds;

  /// Status of a break when a break is playing
  /// on the receiver. This field will be
  /// defined when the receiver is playing
  /// a break, empty when a break is not playing,
  /// but is present in the content, and
  /// undefined if the content contains
  /// no breaks.
  final GoogleCastBrakeStatus? adBreakStatus;

  /// Seekable range of a live or event stream. I
  /// t uses relative media time in seconds.
  /// It will be undefined for VOD streams.
  final GoogleCastMediaLiveSeekableRange? liveSeekableRange;

  /// Item ID of the item that is currently loading
  /// on the receiver. Null if no item is currently
  /// loading.

  /// Queue data
  // final GoogleCastMediaQueueData? queueData;
  GoggleCastMediaStatus({
    required this.mediaSessionID,
    required this.playerState,
    this.idleReason,
    required this.playbackRate,
    this.mediaInformation,
    required this.volume,
    required this.isMuted,
    required this.repeatMode,
    this.currentItemId,
    this.activeTrackIds,
    this.adBreakStatus,
    this.liveSeekableRange,
    // this.queueData,
  });
}
