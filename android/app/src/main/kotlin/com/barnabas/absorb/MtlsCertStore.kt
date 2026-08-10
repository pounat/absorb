package com.barnabas.absorb

import android.content.Context
import android.util.Log
import java.io.File
import java.net.InetAddress
import java.net.Socket
import java.security.KeyStore
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocketFactory

private const val TAG = "AbsorbMtls"

/**
 * Client certificate for the native networking stack.
 *
 * ExoPlayer and background_downloader use [java.net.HttpURLConnection] and never
 * go through Dart, so the certificate is installed as the default socket factory
 * and mirrored to app-private storage for UI-less starts. See [MtlsInitProvider].
 */
object MtlsCertStore {
    private const val BUNDLE_FILE = "mtls_client.p12"
    private const val PREFS = "absorb_mtls"
    private const val KEY_PASSWORD = "bundle_password"
    private const val KEY_HOST = "bundle_host"
    private const val KEY_PORT = "bundle_port"

    private var originalFactory: SSLSocketFactory? = null
    private var installed = false

    private fun bundleFile(context: Context) = File(context.filesDir, BUNDLE_FILE)

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Stores the bundle and installs it process-wide. False when it is unusable. */
    fun setCertificate(
        context: Context,
        bundle: ByteArray,
        password: String,
        host: String,
        port: Int,
    ): Boolean {
        if (host.isEmpty()) {
            // Without a host it would go to every server that asks for one.
            Log.w(TAG, "No server host for the client certificate")
            return false
        }
        // Eagerly: the answer tells Dart whether playback is covered.
        val factory = buildSocketFactory(bundle, password) ?: return false
        try {
            bundleFile(context).writeBytes(bundle)
            prefs(context).edit()
                .putString(KEY_PASSWORD, password)
                .putString(KEY_HOST, host)
                .putInt(KEY_PORT, port)
                .apply()
        } catch (e: Exception) {
            // Still install it: the current session works either way.
            Log.e(TAG, "Could not persist the client certificate", e)
        }
        install(lazyOf(factory), host, port)
        return true
    }

    fun clearCertificate(context: Context) {
        try {
            bundleFile(context).delete()
            prefs(context).edit().remove(KEY_PASSWORD).remove(KEY_HOST).remove(KEY_PORT).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Could not remove the stored client certificate", e)
        }
        uninstall()
    }

    /**
     * Re-installs a stored certificate. Call once per process, as early as
     * possible. Parsed on first use, since this runs on the main thread of every
     * process start.
     */
    fun restore(context: Context) {
        try {
            val file = bundleFile(context)
            if (!file.exists()) return
            val stored = prefs(context)
            val host = stored.getString(KEY_HOST, "") ?: ""
            if (host.isEmpty()) {
                Log.w(TAG, "Stored client certificate has no host")
                return
            }
            val password = stored.getString(KEY_PASSWORD, "") ?: ""
            install(
                lazy {
                    // Forced from createSocket, so nothing may escape from here.
                    try {
                        buildSocketFactory(file.readBytes(), password)
                    } catch (e: Exception) {
                        Log.e(TAG, "Could not read the stored client certificate", e)
                        null
                    }
                },
                host,
                stored.getInt(KEY_PORT, 443),
            )
        } catch (e: Exception) {
            Log.e(TAG, "Could not restore the client certificate", e)
        }
    }

    /**
     * Null trust managers leave Android's defaults in place, so server
     * verification — network_security_config included — stays as it was.
     */
    private fun buildSocketFactory(bundle: ByteArray, password: String): SSLSocketFactory? {
        return try {
            val chars = password.toCharArray()
            val keyStore = KeyStore.getInstance("PKCS12").apply { load(bundle.inputStream(), chars) }
            val kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
                .apply { init(keyStore, chars) }
            SSLContext.getInstance("TLS").apply { init(kmf.keyManagers, null, null) }.socketFactory
        } catch (e: Exception) {
            Log.e(TAG, "Client certificate bundle rejected", e)
            null
        }
    }

    @Synchronized
    private fun install(factory: Lazy<SSLSocketFactory?>, host: String, port: Int) {
        val original = originalFactory
            ?: HttpsURLConnection.getDefaultSSLSocketFactory().also { originalFactory = it }
        HttpsURLConnection.setDefaultSSLSocketFactory(
            HostScopedSocketFactory(factory, original, host, port))
        installed = true
    }

    @Synchronized
    private fun uninstall() {
        if (!installed) return
        originalFactory?.let { HttpsURLConnection.setDefaultSSLSocketFactory(it) }
        installed = false
    }
}

/**
 * Presents the client certificate to one host only: the default socket factory is
 * process-wide, and an identity is not something to hand to every host that asks.
 */
private class HostScopedSocketFactory(
    private val identity: Lazy<SSLSocketFactory?>,
    private val fallback: SSLSocketFactory,
    private val host: String,
    private val port: Int,
) : SSLSocketFactory() {
    private fun factoryFor(candidate: String?, candidatePort: Int): SSLSocketFactory {
        if (candidate == null || candidatePort != port || !candidate.equals(host, ignoreCase = true)) {
            return fallback
        }
        return identity.value ?: fallback
    }

    // SocketFactory's own version throws, unlike the platform factory's.
    override fun createSocket(): Socket = fallback.createSocket()

    // From the platform factory, to avoid parsing the bundle for this.
    override fun getDefaultCipherSuites(): Array<String> = fallback.defaultCipherSuites

    override fun getSupportedCipherSuites(): Array<String> = fallback.supportedCipherSuites

    override fun createSocket(s: Socket, host: String, port: Int, autoClose: Boolean): Socket =
        factoryFor(host, port).createSocket(s, host, port, autoClose)

    override fun createSocket(host: String, port: Int): Socket =
        factoryFor(host, port).createSocket(host, port)

    override fun createSocket(host: String, port: Int, localHost: InetAddress?, localPort: Int): Socket =
        factoryFor(host, port).createSocket(host, port, localHost, localPort)

    // No host name to match, so the identity stays out of it.
    override fun createSocket(host: InetAddress, port: Int): Socket =
        fallback.createSocket(host, port)

    override fun createSocket(
        address: InetAddress,
        port: Int,
        localAddress: InetAddress?,
        localPort: Int,
    ): Socket = fallback.createSocket(address, port, localAddress, localPort)
}
