package com.barnabas.absorb

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri

/**
 * Restores the mTLS client certificate at process start, before anything makes a
 * request. Content providers are created before `Application.onCreate`, and a
 * resumed download runs in a WorkManager worker with no Flutter engine to push
 * the certificate down the method channel.
 */
class MtlsInitProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        context?.let { MtlsCertStore.restore(it) }
        return true
    }

    override fun query(
        uri: Uri,
        projection: Array<String>?,
        selection: String?,
        selectionArgs: Array<String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<String>?,
    ): Int = 0
}
