package com.barnabas.absorb

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import org.json.JSONObject

/**
 * Phone-side bridge that publishes the current Absorb session to the
 * Wearable Data Layer so the paired Wear OS app can sign in without the
 * user re-entering credentials on the watch keyboard.
 *
 * The companion Wear OS app reads the resulting `/absorb/auth/v1`
 * DataItem from a WearableListenerService. Keep the path constants and
 * field names in lock-step with that side (see AbsorbWear repo,
 * com.barnabas.absorb.wear.sync.WearPaths and auth.Credentials).
 */
object WearAuthBridge {
    private const val TAG = "WearAuthBridge"

    const val AUTH_PATH = "/absorb/auth/v1"
    const val AUTH_REQUEST_PATH = "/absorb/auth/request"
    const val AUTH_SIGN_OUT_PATH = "/absorb/auth/signout"
    const val AUTH_ROTATED_PATH = "/absorb/auth/rotated"

    private const val KEY_PAYLOAD = "payload"
    private const val KEY_ISSUED_AT = "issuedAt"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /** Push the active session to every connected watch. The DataItem is
     *  persisted on both ends — a watch that comes online later still
     *  receives the latest snapshot via Google Play Services sync. */
    fun publish(
        context: Context,
        serverUrl: String,
        accessToken: String,
        refreshToken: String?,
        username: String,
        userId: String?,
        isLegacyToken: Boolean,
        customHeaders: Map<String, String> = emptyMap(),
        supportsTokenReturn: Boolean = false,
    ) {
        scope.launch {
            try {
                val now = System.currentTimeMillis()
                val headersJson = JSONObject().apply {
                    customHeaders.forEach { (k, v) -> put(k, v) }
                }
                val payloadJson = JSONObject().apply {
                    put("serverUrl", serverUrl)
                    put("accessToken", accessToken)
                    put("refreshToken", refreshToken ?: JSONObject.NULL)
                    put("username", username)
                    put("userId", userId ?: JSONObject.NULL)
                    put("isLegacyToken", isLegacyToken)
                    put("customHeaders", headersJson)
                    put("source", "phone")
                    put("supportsTokenReturn", supportsTokenReturn)
                    put("issuedAt", now)
                }.toString()

                val request = PutDataMapRequest.create(AUTH_PATH).apply {
                    // Both fields contribute to the DataItem's diff hash —
                    // without ISSUED_AT, republishing the same token (e.g.
                    // on app resume) wouldn't trigger onDataChanged on the
                    // watch because Play Services treats it as unchanged.
                    dataMap.putByteArray(KEY_PAYLOAD, payloadJson.toByteArray(Charsets.UTF_8))
                    dataMap.putLong(KEY_ISSUED_AT, now)
                }.asPutDataRequest().setUrgent()

                Wearable.getDataClient(context.applicationContext).putDataItem(request).await()
                Log.i(TAG, "Published auth DataItem for user=$username")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to publish auth DataItem", e)
            }
        }
    }

    /** Drop the persisted DataItem so any connected watch gets a TYPE_DELETED
     *  event and signs itself out. Called on logout or account switch. */
    fun clear(context: Context) {
        scope.launch {
            try {
                val uri = android.net.Uri.Builder()
                    .scheme("wear")
                    .path(AUTH_PATH)
                    .build()
                Wearable.getDataClient(context.applicationContext)
                    .deleteDataItems(uri)
                    .await()
                Log.i(TAG, "Cleared auth DataItem")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to clear auth DataItem", e)
            }
        }
    }
}
