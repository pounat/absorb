package com.felnanuke.google_cast.extensions

import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.framework.CastSession
import com.google.gson.Gson

fun CastSession.toMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    map["device"] = this.castDevice?.toMap()
    map["sessionID"] = this.sessionId
    map["connectionState"] = this.connectState()
    map["isMute"] = this.isMute
    map["statusMessage"] = this.applicationStatus
    map["volume"] = this.volume
    return map
}

fun CastSession.connectState(): Int {
    return when (true) {
        this.isDisconnected -> 0
        this.isConnecting -> 1
        this.isConnected -> 2
        this.isDisconnecting -> 3
        else -> 0
    }
}

