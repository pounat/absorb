package com.barnabas.absorb

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

/**
 * Phone-side endpoint for watch -> phone Data Layer messages.
 *
 * The watch sends two paths:
 *  - /absorb/auth/request — sent on watch cold start when no credentials
 *    are cached. We respond by republishing the current session from
 *    Flutter SharedPreferences.
 *  - /absorb/auth/signout — sent when the user signs out from the watch.
 *    We wipe the published DataItem so the watch stays signed-out even
 *    after Play Services resyncs.
 *
 * Reads creds directly from the Flutter shared_preferences plugin's
 * backing XML (FlutterSharedPreferences) so we don't have to spin up the
 * Flutter engine just to answer a sync request when the phone app is
 * cold.
 */
class WearAuthListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        when (event.path) {
            WearAuthBridge.AUTH_REQUEST_PATH -> republishFromStoredPrefs()
            WearAuthBridge.AUTH_SIGN_OUT_PATH -> WearAuthBridge.clear(applicationContext)
            WearAuthBridge.AUTH_ROTATED_PATH -> adoptRotatedTokens(event.data)
            else -> super.onMessageReceived(event)
        }
    }

    private fun adoptRotatedTokens(bytes: ByteArray) {
        val payload = try {
            JSONObject(bytes.toString(Charsets.UTF_8))
        } catch (e: Exception) {
            Log.w(TAG, "Watch returned malformed credentials", e)
            return
        }
        val accessToken = payload.optString("accessToken").takeIf { it.isNotEmpty() }
        val refreshToken = payload.optString("refreshToken").takeIf { it.isNotEmpty() }
        val serverUrl = payload.optString("serverUrl").trimEnd('/')
        val username = payload.optString("username")
        if (accessToken == null || refreshToken == null || serverUrl.isEmpty()) {
            Log.w(TAG, "Watch returned an incomplete token pair")
            return
        }

        val prefs = applicationContext.getSharedPreferences(
            FLUTTER_PREFS_FILE,
            Context.MODE_PRIVATE,
        )
        val activeServer = prefs.getString("flutter.server_url", null)?.trimEnd('/')
        val activeUsername = prefs.getString("flutter.username", null) ?: ""
        if (!serverUrl.equals(activeServer, ignoreCase = true) || username != activeUsername) {
            Log.w(TAG, "Ignoring rotated credentials for a different account")
            return
        }

        // One synchronous commit keeps the access/refresh pair indivisible for
        // Android Auto and Flutter readers in other isolates.
        val saved = prefs.edit()
            .putString("flutter.token", accessToken)
            .putString("flutter.refresh_token", refreshToken)
            .putBoolean("flutter.wear_token_pair_pending", true)
            .commit()
        if (!saved) {
            Log.w(TAG, "Failed to persist rotated credentials from watch")
            return
        }
        Log.i(TAG, "Adopted rotated credentials returned by watch")
        republishFromStoredPrefs()
    }

    private fun republishFromStoredPrefs() {
        val prefs = applicationContext.getSharedPreferences(
            FLUTTER_PREFS_FILE,
            Context.MODE_PRIVATE,
        )
        val serverUrl = prefs.getString("flutter.server_url", null)
        val token = prefs.getString("flutter.token", null)
        if (serverUrl == null || token == null) {
            Log.i(TAG, "Watch requested sync but no stored session on phone")
            return
        }
        val refreshToken = prefs.getString("flutter.refresh_token", null)
        val username = prefs.getString("flutter.username", null) ?: ""
        val userId = prefs.getString("flutter.user_id", null)
        // AuthProvider treats absence of refresh_token as a legacy/API-key
        // session; mirror that heuristic here so the watch knows not to
        // try the refresh endpoint.
        val isLegacy = refreshToken == null

        // Flutter writes customHeaders as a JSON-encoded string under
        // `custom_headers` — decode and forward so Cloudflare Access /
        // proxy-auth users don't 403 when the watch makes ABS calls.
        val headers = mutableMapOf<String, String>()
        prefs.getString("flutter.custom_headers", null)?.let { raw ->
            try {
                val obj = JSONObject(raw)
                obj.keys().forEach { k -> obj.optString(k)?.let { headers[k] = it } }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to decode custom_headers from prefs", e)
            }
        }

        WearAuthBridge.publish(
            context = applicationContext,
            serverUrl = serverUrl,
            accessToken = token,
            refreshToken = refreshToken,
            username = username,
            userId = userId,
            isLegacyToken = isLegacy,
            customHeaders = headers,
            supportsTokenReturn = true,
        )
    }

    companion object {
        private const val TAG = "WearAuthBridge"
        // Hardcoded by the flutter/shared_preferences plugin on Android.
        private const val FLUTTER_PREFS_FILE = "FlutterSharedPreferences"
    }
}
