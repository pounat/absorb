package com.felnanuke.google_cast.extensions

import com.google.android.gms.cast.MediaLoadOptions

/**
 * Extension class for converting Flutter/Dart map data to Google Cast MediaLoadOptions.
 * 
 * This class provides utility methods to create MediaLoadOptions objects from Flutter's
 * map representation, facilitating the bridge between Flutter and native Android Google Cast API.
 */
class GoogleCastMediaLoadOptions {
    companion object {
        /**
         * Converts a Flutter map to a MediaLoadOptions object for Google Cast.
         * 
         * This method takes a map containing media load configuration parameters
         * and creates a properly configured MediaLoadOptions instance that can be
         * used with the Google Cast SDK.
         * 
         * @param map A map containing the following keys:
         *   - autoPlay (Boolean): Whether the media should start playing automatically
         *   - playPosition (Int): The starting position in seconds (will be converted to milliseconds)
         *   - activeTrackIds (ArrayList<Long>?): Optional list of track IDs to activate (e.g., subtitles, audio tracks)
         *   - credentials (String?): Optional credentials for authentication
         *   - credentialsType (String?): Optional type of credentials being used
         *   - playbackRate (Double): The playback rate (1.0 = normal speed)
         * 
         * @return MediaLoadOptions A configured MediaLoadOptions object ready for use with Google Cast
         * 
         * @throws ClassCastException if any of the map values are not of the expected type
         */
        fun fromMap(map: Map<String, Any?>): MediaLoadOptions {
            // Extract configuration values from the Flutter map
            val autoPlay = map["autoPlay"] as Boolean
            val playPosition = map["playPosition"] as Int
            val activeTrackIds = map["activeTrackIds"] as ArrayList<Long>?
            val credentials = map["credentials"] as String?
            val credentialsType = map["credentialsType"] as String?
            val playbackRate = map["playbackRate"] as Double
            
            // Build MediaLoadOptions using the builder pattern
            val builder = MediaLoadOptions.Builder()
            builder.setAutoplay(autoPlay)
            // Convert play position from seconds to milliseconds as required by the Google Cast API
            builder.setPlayPosition((playPosition * 1000).toLong())
            
            // Set active track IDs if provided (for subtitles, audio tracks, etc.)
            if (activeTrackIds != null)
                builder.setActiveTrackIds(activeTrackIds.toLongArray())
                
            // Set authentication credentials if provided
            builder.setCredentials(credentials)
            builder.setCredentialsType(credentialsType)
            
            // Set playback rate (1.0 = normal speed, 2.0 = double speed, etc.)
            builder.setPlaybackRate(playbackRate)
            
            return builder.build()
        }
    }
}