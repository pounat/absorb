package com.barnabas.absorb

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import android.util.Log
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

/**
 * ContentProvider that serves cover images to Android Auto.
 *
 * Android Auto cannot load HTTP or file:// URIs directly — it requires
 * content:// URIs.  This provider maps:
 *   content://com.barnabas.absorb.covers/cover/<itemId>
 *
 * Lookup order:
 *   1. Locally downloaded cover (item's download directory)
 *   2. Cached cover fetched from the ABS server (cacheDir/aa_covers/)
 *   3. Fetch from server on-demand → cache → serve
 */
class CoverContentProvider : ContentProvider() {

    companion object {
        const val AUTHORITY = "com.barnabas.absorb.covers"
        private const val TAG = "CoverProvider"
        private val refreshLock = Any()

        fun buildCoverUri(itemId: String): Uri {
            return Uri.parse("content://$AUTHORITY/cover/$itemId")
        }
    }

    override fun onCreate(): Boolean = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor? {
        val itemId = extractItemId(uri) ?: return null
        val context = context ?: return null
        val ts = uri.getQueryParameter("ts")
        invalidateStaleCacheIfNeeded(context, itemId, uri)
        val coverFile = findCoverFile(context, itemId)
        if (coverFile != null) {
            Log.d(TAG, "openFile $itemId ts=$ts served=${coverFile.path} mtime=${coverFile.lastModified()}")
            return ParcelFileDescriptor.open(coverFile, ParcelFileDescriptor.MODE_READ_ONLY)
        }

        // Not available locally — try fetching from the server and caching
        val cached = fetchAndCache(context, itemId) ?: return null
        Log.d(TAG, "openFile $itemId ts=$ts fetched=${cached.path} mtime=${cached.lastModified()}")
        return ParcelFileDescriptor.open(cached, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String = "image/jpeg"

    override fun getStreamTypes(uri: Uri, mimeTypeFilter: String): Array<String>? {
        if (mimeTypeFilter == "*/*" ||
            mimeTypeFilter == "image/*" ||
            mimeTypeFilter == "image/jpeg") {
            return arrayOf("image/jpeg")
        }
        return null
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor? {
        val itemId = extractItemId(uri) ?: return null
        val context = context ?: return null
        invalidateStaleCacheIfNeeded(context, itemId, uri)
        val coverFile = findCoverFile(context, itemId)
            ?: fetchAndCache(context, itemId)
            ?: return null

        val cols = projection ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        val cursor = MatrixCursor(cols.map { it }.toTypedArray())
        val row = cols.map { col ->
            when (col) {
                OpenableColumns.DISPLAY_NAME -> "cover.jpg"
                OpenableColumns.SIZE -> coverFile.length()
                else -> null
            }
        }.toTypedArray()
        cursor.addRow(row)
        return cursor
    }

    // ── Server fetch + cache ──

    private fun fetchAndCache(context: android.content.Context, itemId: String): File? {
        try {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", android.content.Context.MODE_PRIVATE
            )
            val serverUrl = prefs.getString("flutter.server_url", null)
            var token = prefs.getString("flutter.token", null)
            if (serverUrl.isNullOrEmpty() || token.isNullOrEmpty()) {
                Log.w(TAG, "No server_url or token in prefs - cannot fetch cover")
                return null
            }

            val cleanUrl = serverUrl.trimEnd('/')
            val customHeaders = readCustomHeaders(prefs)
            val cacheDir = File(context.cacheDir, "aa_covers")
            if (!cacheDir.exists()) cacheDir.mkdirs()
            val cacheFile = File(cacheDir, "$itemId.jpg")

            var result = fetchCover(cleanUrl, itemId, token, cacheFile, customHeaders)
            if (result == 401) {
                // Access token expired - try refreshing via the refresh token
                val newToken = refreshAccessToken(cleanUrl, token, prefs, customHeaders)
                if (newToken != null) {
                    token = newToken
                    result = fetchCover(cleanUrl, itemId, token, cacheFile, customHeaders)
                }
            }

            if (result == 200 && cacheFile.exists() && cacheFile.length() > 0) {
                Log.d(TAG, "Cached cover for $itemId (${cacheFile.length()} bytes)")
                return cacheFile
            }
            cacheFile.delete()
            return null
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching cover for $itemId", e)
            return null
        }
    }

    private fun fetchCover(
        serverUrl: String,
        itemId: String,
        token: String,
        outFile: File,
        customHeaders: Map<String, String>,
    ): Int {
        val fetchUrl = "$serverUrl/api/items/$itemId/cover?width=400&token=$token"
        val connection = URL(fetchUrl).openConnection() as HttpURLConnection
        connection.connectTimeout = 5000
        connection.readTimeout = 5000
        connection.instanceFollowRedirects = true
        connection.setRequestProperty("User-Agent", "Absorb Android Auto")
        customHeaders.forEach { (key, value) -> connection.setRequestProperty(key, value) }
        try {
            val code = connection.responseCode
            if (code != 200) {
                Log.w(TAG, "Cover fetch failed: HTTP $code for $itemId")
                return code
            }
            connection.inputStream.use { input ->
                outFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            return 200
        } finally {
            connection.disconnect()
        }
    }

    private fun refreshAccessToken(
        serverUrl: String,
        staleAccessToken: String,
        prefs: android.content.SharedPreferences,
        customHeaders: Map<String, String>,
    ): String? = synchronized(refreshLock) {
        // Flutter or another provider request may have completed the rotation
        // while this cover request was receiving its 401.
        val latestAccess = prefs.getString("flutter.token", null)
        if (!latestAccess.isNullOrEmpty() && latestAccess != staleAccessToken) {
            return@synchronized latestAccess
        }

        val refreshToken = prefs.getString("flutter.refresh_token", null)
        if (refreshToken.isNullOrEmpty()) {
            Log.w(TAG, "No refresh token available")
            return@synchronized null
        }
        try {
            val connection = URL("$serverUrl/auth/refresh").openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.setRequestProperty("x-refresh-token", refreshToken)
            connection.setRequestProperty("User-Agent", "Absorb Android Auto")
            customHeaders.forEach { (key, value) -> connection.setRequestProperty(key, value) }
            try {
                if (connection.responseCode != 200) {
                    Log.w(TAG, "Token refresh failed: HTTP ${connection.responseCode}")
                    return@synchronized null
                }
                val body = connection.inputStream.bufferedReader().readText()
                val tokens = parseCoverRefreshTokens(body)
                if (tokens != null) {
                    // Commit the rotating pair together so no reader can see a
                    // new access token paired with the spent refresh token.
                    val saved = prefs.edit()
                        .putString("flutter.token", tokens.accessToken)
                        .putString("flutter.refresh_token", tokens.refreshToken)
                        .commit()
                    if (!saved) return@synchronized null
                    Log.d(TAG, "Token refreshed successfully from CoverContentProvider")
                    return@synchronized tokens.accessToken
                }
            } finally {
                connection.disconnect()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Token refresh error", e)
        }
        null
    }

    private fun readCustomHeaders(
        prefs: android.content.SharedPreferences,
    ): Map<String, String> {
        val raw = prefs.getString("flutter.custom_headers", null) ?: return emptyMap()
        return try {
            val json = JSONObject(raw)
            buildMap {
                json.keys().forEach { key ->
                    val value = json.optString(key)
                    if (value.isNotEmpty()) put(key, value)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to decode custom headers", e)
            emptyMap()
        }
    }

    // If the URI carries a `ts` query param newer than the aa_covers file's
    // mtime, drop the file so the next lookup re-fetches from the server.
    // Downloaded covers are owned by the download pipeline, not touched here.
    private fun invalidateStaleCacheIfNeeded(
        context: android.content.Context,
        itemId: String,
        uri: Uri
    ) {
        val tsParam = uri.getQueryParameter("ts")?.toLongOrNull() ?: return
        val cacheFile = File(context.cacheDir, "aa_covers/$itemId.jpg")
        if (cacheFile.exists()) {
            if (cacheFile.lastModified() < tsParam) {
                Log.d(TAG, "Invalidating stale aa_covers for $itemId (file=${cacheFile.lastModified()} < ts=$tsParam)")
                cacheFile.delete()
            } else {
                Log.d(TAG, "aa_covers fresh for $itemId (file=${cacheFile.lastModified()} >= ts=$tsParam)")
            }
        }
    }

    // ── Helpers ──

    private fun extractItemId(uri: Uri): String? {
        val segments = uri.pathSegments
        // Expected: /cover/<itemId>
        if (segments.size != 2 || segments[0] != "cover") return null
        val itemId = segments[1]
        // Sanitize — only allow alphanumeric, hyphens, underscores
        if (!itemId.matches(Regex("^[a-zA-Z0-9_\\-]+$"))) return null
        return itemId
    }

    private fun findCoverFile(context: android.content.Context, itemId: String): File? {
        // Check custom download path first (stored in SharedPreferences)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
        val customPath = prefs.getString("flutter.custom_download_path", null)

        if (customPath != null && customPath.isNotEmpty()) {
            val file = File("$customPath/$itemId/cover.jpg")
            if (file.exists() && file.canRead()) return file
        }

        // Default: app documents directory
        val docsDir = context.filesDir?.parentFile?.let { File(it, "app_flutter/downloads") }
        if (docsDir != null) {
            val file = File("$docsDir/$itemId/cover.jpg")
            if (file.exists() && file.canRead()) return file
        }

        // Also try getExternalFilesDir path
        val extDir = context.getExternalFilesDir(null)
        if (extDir != null) {
            val file = File("${extDir.parent}/app_flutter/downloads/$itemId/cover.jpg")
            if (file.exists() && file.canRead()) return file
        }

        // Check the server-fetch cache
        val cacheFile = File(context.cacheDir, "aa_covers/$itemId.jpg")
        if (cacheFile.exists() && cacheFile.length() > 0) return cacheFile

        return null
    }

    // Not used — read-only provider
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun update(uri: Uri, values: ContentValues?, s: String?, sa: Array<out String>?): Int = 0
    override fun delete(uri: Uri, s: String?, sa: Array<out String>?): Int = 0
}

internal data class CoverRefreshTokens(
    val accessToken: String,
    val refreshToken: String,
)

internal fun parseCoverRefreshTokens(json: String): CoverRefreshTokens? {
    fun value(key: String): String? {
        val match = Regex("\"$key\"\\s*:\\s*\"([^\"]+)\"").find(json)
        return match?.groupValues?.get(1)
    }
    val accessToken = value("accessToken") ?: return null
    val refreshToken = value("refreshToken") ?: return null
    return CoverRefreshTokens(accessToken, refreshToken)
}
