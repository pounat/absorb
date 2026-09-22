package com.felnanuke.google_cast

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider

/**
 * Google Cast options provider for Flutter Google Cast plugin
 * 
 * This class provides Cast framework configuration options that are set up
 * during plugin initialization. It implements the OptionsProvider interface
 * required by the Google Cast SDK for Android.
 *
 * The options are configured dynamically through the Flutter plugin and
 * stored in the companion object for access by the Cast framework.
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
class GoogleCastOptionsProvider : OptionsProvider {
    
    companion object {
        /**
         * Cast options configured by the Flutter plugin
         * 
         * These options are set by the CastContextMethodChannel during
         * Cast context initialization and include receiver application ID,
         * launch options, and other Cast framework configuration.
         */
        lateinit var options: CastOptions
        
        /**
         * Whether to stop casting when the app is terminated
         * 
         * When true, the plugin will automatically end the cast session
         * and stop casting on the receiver when the app is killed.
         * Default is false (casting continues after app is closed).
         */
        var stopCastingOnAppTerminated: Boolean = false
    }
    
    /**
     * Provides Cast options to the Google Cast framework
     * 
     * @param context Android application context
     * @return Configured Cast options for the framework
     */
    override fun getCastOptions(context: Context): CastOptions {
        return options
    }

    /**
     * Provides additional session providers for custom Cast functionality
     * 
     * Currently returns null as no additional session providers are needed
     * for basic Cast functionality.
     * 
     * @param context Android application context
     * @return List of additional session providers, or null if none needed
     */
    override fun getAdditionalSessionProviders(context: Context): MutableList<SessionProvider>? {
        return null
    }
}