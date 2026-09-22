package com.felnanuke.google_cast.extensions

import com.google.android.gms.cast.MediaSeekOptions

class GoogleCastSeekOptionsBuilder {
    companion object {
        fun fromMap(arguments: Map<String, Any?>): MediaSeekOptions {
            val position = arguments["position"] as Int
            val resumeState = arguments["resumeState"] as Int
            val seekToInfinity = arguments["seekToInfinity"] as Boolean
            val builder = MediaSeekOptions.Builder()
            builder.setPosition((position * 1000).toLong())
            builder.setResumeState(resumeState)
            builder.setIsSeekToInfinite(seekToInfinity)
            return builder.build()
        }
    }
}