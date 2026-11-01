package com.barnabas.absorb

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

/**
 * Takes the list of BookOrbit listening sessions the AbsorbWear watch has
 * recorded and files them beside the ones this phone recorded, so the
 * Stats screen can show them with the watch icon. BookOrbit keeps no
 * device on a session, so both lists live in Flutter's shared
 * preferences, keyed `bookId@startedAt` the way BookOrbitApiService keys
 * its own; the Dart side reads this one as the watch's.
 */
class WearSessionListenerService : WearableListenerService() {

    override fun onDataChanged(buffer: DataEventBuffer) {
        for (event in buffer) {
            if (event.type != DataEvent.TYPE_CHANGED || event.dataItem.uri.path != SESSIONS_PATH) continue
            val bytes = DataMapItem.fromDataItem(event.dataItem).dataMap.getByteArray("payload") ?: continue
            adopt(bytes)
        }
    }

    private fun adopt(bytes: ByteArray) {
        val payload = try {
            JSONObject(bytes.toString(Charsets.UTF_8))
        } catch (e: Exception) {
            Log.w(TAG, "watch session list not JSON", e)
            return
        }
        val device = payload.optString("device").ifBlank { "Wear OS watch" }
        val sessions = payload.optJSONArray("sessions") ?: return
        val prefs = applicationContext.getSharedPreferences(FLUTTER_PREFS_FILE, Context.MODE_PRIVATE)
        val known = prefs.getString(WATCH_SESSIONS_KEY, null)
            ?.let { raw -> try { JSONObject(raw) } catch (_: Exception) { null } }
            ?: JSONObject()
        var added = 0
        for (i in 0 until sessions.length()) {
            val s = sessions.optJSONObject(i) ?: continue
            val bookId = s.optString("bookId")
            val startedAt = s.optString("startedAt")
            if (bookId.isEmpty() || startedAt.isEmpty()) continue
            val key = "$bookId@$startedAt"
            if (!known.has(key)) added++
            known.put(key, device)
        }
        while (known.length() > 500) known.remove(known.keys().next())
        prefs.edit().putString(WATCH_SESSIONS_KEY, known.toString()).apply()
        Log.i(TAG, "Watch -> ${sessions.length()} BookOrbit sessions ($added new) from $device")
    }

    companion object {
        private const val TAG = "WearPlayerBridge"
        private const val SESSIONS_PATH = "/absorb/player/sessions/v1"
        private const val FLUTTER_PREFS_FILE = "FlutterSharedPreferences"
        private const val WATCH_SESSIONS_KEY = "flutter.bookorbit_watch_sessions"
    }
}
