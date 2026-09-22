package com.felnanuke.google_cast.extensions

import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaMetadata
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import org.json.JSONObject

/**
 * Utility class for building [MediaInfo] objects for Google Cast from map representations.
 */
class GoogleCastMediaInfo {
    companion object {
        /**
         * Creates a [MediaInfo] instance from a [Map] representation.
         *
         * @param map A [Map] containing media information. Expected keys:
         *  - "contentID": [String] (required) - The unique content ID.
         *  - "contentURL": [String]? - The URL of the content.
         *  - "contentType": [String]? - The MIME type of the content.
         *  - "tracks": [List]<[Map]<[String], Any?>>? - List of media track maps.
         *  - "metadata": [Map]<[String], Any?>? - Metadata map.
         *  - "customData": [Map]<[String], Any?>? - Custom data map.
         * @return A [MediaInfo] object if the required fields are present, otherwise null.
         */
        fun fromMap(map: Map<String, Any?>): MediaInfo? {
            val contentId = map["contentID"] as String
            val contentUrl = map["contentURL"] as String?
            val contentType = map["contentType"] as String?
            val streamType = map["streamType"] as String?
            val tracks = GoogleCastMediaTrackBuilder.listFromMap(
                map["tracks"] as List<Map<String, Any?>>? ?: listOf()
            )
            val metaData =
                GoogleCastMetadataBuilder.fromMap(map["metadata"] as Map<String, Any?>? ?: mapOf())
            val builder = MediaInfo.Builder(contentId)
            if (contentUrl != null)
                builder.setContentUrl(contentUrl)
            if (streamType != null)
                builder.setStreamType(when (streamType) {
                    "BUFFERED" -> MediaInfo.STREAM_TYPE_BUFFERED
                    "LIVE" -> MediaInfo.STREAM_TYPE_LIVE
                    "NONE" -> MediaInfo.STREAM_TYPE_NONE
                    else -> MediaInfo.STREAM_TYPE_INVALID
                })
            if (contentType != null)
                builder.setContentType(contentType)
            if (tracks.isNotEmpty())
                builder.setMediaTracks(tracks)

            if (metaData != null)
                builder.setMetadata(metaData)
            var customData = map["customData"] as Map<String, Any?>?

            if (customData != null) {
                builder.setCustomData(JSONObject(customData))
            }

            return builder.build()
        }
    }
}

//fun MediaInfo.toMap(): Map<String, Any?> {
//    var map = mutableMapOf<String, Any?>()
//    map["contentID"] = contentId
//    map["contentURL"] = contentUrl
//    map["contentType"] = contentType
//    map["streamType"] = streamType
//    map["streamDuration"] = streamDuration
//    map["tracks"] = mediaTracks?.map {
//        it.toMap()
//    }
//    map["metadata"] = null
//    return map
//
//}