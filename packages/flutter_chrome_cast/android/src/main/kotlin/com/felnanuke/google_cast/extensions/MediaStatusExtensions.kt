package com.felnanuke.google_cast.extensions

import com.google.android.gms.cast.MediaStatus
import com.google.gson.Gson

/**
 * Extension class for Google Cast MediaStatus operations.
 * 
 * This class provides utilities for working with MediaStatus objects in the context
 * of the Flutter Google Cast plugin, facilitating data conversion between native
 * Android and Flutter/Dart representations.
 */
class GoogleCastMediaStatusExtensions {
    // This class serves as a container for MediaStatus-related extension functions
    // and utilities that may be added in the future.
}

/**
 * Converts a MediaStatus object to a Map representation suitable for Flutter.
 * 
 * This extension function transforms a Google Cast MediaStatus object into a map
 * that can be easily serialized and passed to the Flutter layer. It extracts
 * all relevant media playback state information.
 * 
 * @return Map<String, Any?> A map containing the following keys:
 *   - activeTrackIds: Array of currently active track IDs (subtitles, audio tracks, etc.)
 *   - currentItemId: ID of the currently playing queue item
 *   - idleReason: Reason why the player is idle (if applicable)
 *   - isMute: Boolean indicating if the player is muted
 *   - isPlayingAd: Boolean indicating if an advertisement is currently playing
 *   - loadingItemId: ID of the item currently being loaded
 *   - mediaInfo: String representation of the current media information
 *   - playbackRate: Current playback rate (1.0 = normal speed)
 *   - playerState: Current state of the media player
 *   - preloadedItemId: ID of the preloaded queue item
 *   - queueItemCount: Total number of items in the queue
 *   - queueRepeatMode: Current repeat mode for the queue
 *   - streamVolume: Current volume level of the stream
 */
fun MediaStatus.toMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    
    // Track information
    map["activeTrackIds"] = activeTrackIds
    
    // Queue and item management
    map["currentItemId"] = this.currentItemId
    map["loadingItemId"] = this.loadingItemId
    map["preloadedItemId"] = this.preloadedItemId
    map["queueItemCount"] = this.queueItemCount
    map["queueRepeatMode"] = this.queueRepeatMode
    
    // Player state information
    map["playerState"] = this.playerState
    map["idleReason"] = this.idleReason
    map["playbackRate"] = this.playbackRate
    
    // Audio and media information
    map["isMute"] = this.isMute
    map["streamVolume"] = this.streamVolume
    map["mediaInfo"] = this.mediaInfo?.toString()
    
    // Advertisement state
    map["isPlayingAd"] = this.isPlayingAd

    // Live seekable range
    map["liveSeekableRange"] = this.liveSeekableRange?.let { range ->
        mapOf(
            "start" to range.startTime,
            "end" to range.endTime,
            "isMovingWindow" to range.isMovingWindow,
            "isLiveDone" to range.isLiveDone
        )
    }

    return map
}