package com.barnabas.absorb

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import org.json.JSONArray
import org.json.JSONObject

/**
 * Pushes the current ABS playback snapshot to the paired Wear OS app
 * (AbsorbWear) so the watch can render "Now Playing" without making any
 * direct calls to the server.
 *
 * Keep the field set in sync with `com.barnabas.absorb.wear.player.PlayerState`
 * on the watch side. Bump the path version (`v1` → `v2`) when the shape
 * changes — DataItems are persistent and stale watches will still see the
 * last published payload until you republish.
 */
object WearPlayerBridge {
    private const val TAG = "WearPlayerBridge"

    const val STATE_PATH = "/absorb/player/state/v1"
    const val CHAPTERS_PATH = "/absorb/player/chapters/v1"

    private const val KEY_PAYLOAD = "payload"
    private const val KEY_ISSUED_AT = "issuedAt"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val main = Handler(Looper.getMainLooper())

    /** The Dart side's channel while the engine is up; the watch's extra
     *  actions (chapters, bookmark, sleep timer, seek) go through it. */
    @Volatile
    var channel: MethodChannel? = null

    /** Push the current playback snapshot. Call from the same throttle
     *  loop that updates the home widget — anything finer-grained than
     *  ~2s is wasted bandwidth. */
    fun publish(
        context: Context,
        hasBook: Boolean,
        itemId: String?,
        title: String?,
        author: String?,
        chapter: String?,
        isPlaying: Boolean,
        positionMs: Long,
        durationMs: Long,
        speed: Float,
        skipBackSec: Int,
        skipForwardSec: Int,
        chapterStartMs: Long = 0L,
        chapterEndMs: Long = 0L,
        autoRewindEnabled: Boolean = true,
        autoRewindMinSec: Double = 1.0,
        autoRewindMaxSec: Double = 30.0,
        autoRewindDelaySec: Double = 0.0,
        autoRewindChapterBarrier: Boolean = false,
        autoRewindSessionStart: Boolean = false,
        skipChapterBarrier: Boolean = true,
        speedAdjustedTime: Boolean = true,
        chapterIndex: Int = -1,
        chapterCount: Int = 0,
        sleepMode: String? = null,
        sleepEndsAtMs: Long = 0L,
        sleepChaptersLeft: Int = 0,
        sleepAddMinutes: Int = 5,
        speedPresets: List<Float> = emptyList(),
        themeColor: Long = 0L,
    ) {
        scope.launch {
            try {
                val now = System.currentTimeMillis()
                val payload = JSONObject().apply {
                    put("hasBook", hasBook)
                    put("itemId", itemId ?: JSONObject.NULL)
                    put("title", title ?: JSONObject.NULL)
                    put("author", author ?: JSONObject.NULL)
                    put("chapter", chapter ?: JSONObject.NULL)
                    put("isPlaying", isPlaying)
                    put("positionMs", positionMs)
                    put("durationMs", durationMs)
                    put("speed", speed.toDouble())
                    put("skipBackSec", skipBackSec)
                    put("skipForwardSec", skipForwardSec)
                    put("chapterStartMs", chapterStartMs)
                    put("chapterEndMs", chapterEndMs)
                    // The playback settings the watch copies, so a book sounds
                    // the same from either device.
                    put("autoRewindEnabled", autoRewindEnabled)
                    put("autoRewindMinSec", autoRewindMinSec)
                    put("autoRewindMaxSec", autoRewindMaxSec)
                    put("autoRewindDelaySec", autoRewindDelaySec)
                    put("autoRewindChapterBarrier", autoRewindChapterBarrier)
                    put("autoRewindSessionStart", autoRewindSessionStart)
                    put("skipChapterBarrier", skipChapterBarrier)
                    put("speedAdjustedTime", speedAdjustedTime)
                    put("chapterIndex", chapterIndex)
                    put("chapterCount", chapterCount)
                    put("sleepMode", sleepMode ?: JSONObject.NULL)
                    put("sleepEndsAtMs", sleepEndsAtMs)
                    put("sleepChaptersLeft", sleepChaptersLeft)
                    put("sleepAddMinutes", sleepAddMinutes)
                    put("speedPresets", JSONArray().apply { for (p in speedPresets) put(p.toDouble()) })
                    put("themeColor", themeColor)
                    put("issuedAt", now)
                }.toString()

                val request = PutDataMapRequest.create(STATE_PATH).apply {
                    // Both fields contribute to the diff hash — the timestamp
                    // alone keeps republishes of identical metadata flowing
                    // (so position-tick updates still propagate).
                    dataMap.putByteArray(KEY_PAYLOAD, payload.toByteArray(Charsets.UTF_8))
                    dataMap.putLong(KEY_ISSUED_AT, now)
                }.asPutDataRequest().setUrgent()

                Wearable.getDataClient(context.applicationContext).putDataItem(request).await()
            } catch (e: Exception) {
                Log.w(TAG, "Failed to publish player state", e)
            }
        }
    }

    /** The playing book's chapter list, once per book, for the watch's
     *  chapter page. [chaptersJson] is a JSON array of
     *  `{"title","start","end"}` with seconds. */
    fun publishChapters(context: Context, itemId: String, chaptersJson: String) {
        scope.launch {
            try {
                val payload = JSONObject().apply {
                    put("itemId", itemId)
                    put("chapters", JSONArray(chaptersJson))
                }.toString()
                val request = PutDataMapRequest.create(CHAPTERS_PATH).apply {
                    dataMap.putByteArray(KEY_PAYLOAD, payload.toByteArray(Charsets.UTF_8))
                    dataMap.putLong(KEY_ISSUED_AT, System.currentTimeMillis())
                }.asPutDataRequest().setUrgent()
                Wearable.getDataClient(context.applicationContext).putDataItem(request).await()
                Log.i(TAG, "published chapters for $itemId")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to publish chapters", e)
            }
        }
    }

    /** Hands a watch command to the Dart player. False when the Flutter
     *  engine is not up, so the caller can wake the app instead. */
    fun command(name: String, args: Map<String, Any?> = emptyMap()): Boolean {
        val ch = channel ?: return false
        main.post {
            try {
                ch.invokeMethod("command", HashMap<String, Any?>(args).apply { put("name", name) })
            } catch (e: Exception) {
                Log.w(TAG, "command $name failed", e)
            }
        }
        return true
    }
}
