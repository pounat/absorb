package com.barnabas.absorb

import android.content.SharedPreferences
import android.util.Base64
import android.util.Log
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Renews the phone's BookOrbit session when the watch asks for a fresh token.
 *
 * The phone and the watch share one BookOrbit session, and BookOrbit ends the
 * whole session when a refresh token it already swapped is sent again more
 * than 30 seconds later. So the watch never spends that token itself: it asks
 * the phone, and the phone renews it here from the stored pair, the same one
 * every refresh in the app reads right before it goes out.
 */
object BookOrbitSessionRenewer {
    private const val TAG = "WearAuthBridge"
    private const val WEB_REFRESH_PREFIX = "web:"

    /** Wider than the watch's own minute of headroom, so a watch that finds
     *  its token about to run out always gets a renewed one back. */
    private const val RENEW_WITHIN_MS = 3 * 60_000L

    private val lock = Any()
    private val refreshCookie = Regex("refresh_token=([^;,\\s]+)")

    /** Renews the stored BookOrbit pair when its access token runs out within
     *  a few minutes. Blocks on the network, so call it off the main thread. */
    fun renewIfExpiring(prefs: SharedPreferences) {
        synchronized(lock) {
            if (prefs.getString("flutter.server_backend", null) != "bookorbit") return
            val access = prefs.getString("flutter.token", null) ?: return
            val refresh = prefs.getString("flutter.refresh_token", null) ?: return
            val expiresAt = jwtExpiryMillis(access) ?: return
            if (System.currentTimeMillis() + RENEW_WITHIN_MS < expiresAt) return
            val server = prefs.getString("flutter.server_url", null)?.trimEnd('/') ?: return
            val username = prefs.getString("flutter.username", null)

            val renewed = send(server, refresh, customHeaders(prefs)) ?: return

            // Something else in the app renewed it while this was out. Within
            // BookOrbit's grace both got the same pair back; past it, theirs
            // is the newer one. Either way, keep what is stored.
            if (prefs.getString("flutter.refresh_token", null) != refresh ||
                prefs.getString("flutter.server_url", null)?.trimEnd('/') != server ||
                prefs.getString("flutter.username", null) != username
            ) {
                Log.i(TAG, "BookOrbit session was renewed elsewhere meanwhile; keeping the stored pair")
                return
            }
            val saved = prefs.edit()
                .putString("flutter.refresh_token", renewed.second)
                .putString("flutter.token", renewed.first)
                .putLong("flutter.token_saved_at", System.currentTimeMillis())
                .putBoolean("flutter.wear_token_pair_pending", true)
                .commit()
            if (saved) Log.i(TAG, "Renewed the BookOrbit session for the watch")
            else Log.w(TAG, "Renewed the BookOrbit session but could not store it")
        }
    }

    /** The renewed access and refresh tokens, or null when BookOrbit could
     *  not be reached or turned the token down. */
    private fun send(server: String, refresh: String, headers: Map<String, String>): Pair<String, String>? {
        val webSession = refresh.startsWith(WEB_REFRESH_PREFIX)
        val conn = try {
            (URL("$server/api/v1/auth/refresh").openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 10_000
                readTimeout = 15_000
                doOutput = true
                setRequestProperty("Accept", "application/json")
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("User-Agent", "Absorb/${BuildConfig.VERSION_NAME}")
                headers.forEach { (k, v) -> setRequestProperty(k, v) }
                if (webSession) {
                    setRequestProperty("Cookie", "refresh_token=" + refresh.removePrefix(WEB_REFRESH_PREFIX))
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "BookOrbit renewal: cannot open connection", e)
            return null
        }
        return try {
            val body = if (webSession) "{}" else JSONObject().put("refreshToken", refresh).toString()
            conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            val code = conn.responseCode
            if (code !in 200..299) {
                Log.w(TAG, "BookOrbit renewal turned down: HTTP $code")
                return null
            }
            val json = JSONObject(conn.inputStream.bufferedReader().use { it.readText() })
            val user = json.optJSONObject("user")
            val access = user?.optString("accessToken")?.takeIf { it.isNotEmpty() }
                ?: json.optString("accessToken").takeIf { it.isNotEmpty() }
                ?: return null
            val next = if (webSession) {
                conn.headerFields["Set-Cookie"]
                    ?.firstNotNullOfOrNull { refreshCookie.find(it)?.groupValues?.get(1) }
                    ?.let { WEB_REFRESH_PREFIX + it }
            } else {
                user?.optString("refreshToken")?.takeIf { it.isNotEmpty() }
                    ?: json.optString("refreshToken").takeIf { it.isNotEmpty() }
            }
            access to (next ?: refresh)
        } catch (e: Exception) {
            Log.w(TAG, "BookOrbit renewal failed", e)
            null
        } finally {
            conn.disconnect()
        }
    }

    private fun customHeaders(prefs: SharedPreferences): Map<String, String> {
        val raw = prefs.getString("flutter.custom_headers", null) ?: return emptyMap()
        return try {
            val obj = JSONObject(raw)
            obj.keys().asSequence().associateWith { obj.optString(it) }
        } catch (_: Exception) {
            emptyMap()
        }
    }

    /** Epoch millis stamped in a JWT's `exp`, or null when the token isn't one. */
    private fun jwtExpiryMillis(token: String): Long? {
        val parts = token.split('.')
        if (parts.size != 3) return null
        return try {
            val payload = String(Base64.decode(parts[1], Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP))
            JSONObject(payload).optLong("exp", 0L).takeIf { it > 0L }?.times(1000)
        } catch (_: Exception) {
            null
        }
    }
}
