package com.barnabas.absorb

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * GMS-backed platform channels (Chromecast foreground service + Wear OS Data
 * Layer bridges). Compiled into the `github` and `playstore` flavors via the
 * shared `src/gms` source set. The `fdroid` flavor ships a no-op twin of this
 * object so the app builds without Google Play Services.
 *
 * The non-GMS channels (EQ, storage) stay registered in MainActivity.
 */
object PlatformIntegration {
    fun registerChannels(activity: Activity, flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "com.absorb.cast_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        CastForegroundService.start(activity)
                        result.success(true)
                    }
                    "stop" -> {
                        CastForegroundService.stop(activity)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Bridge ABS playback state to the watch so it can render Now
        // Playing without making its own API calls.
        MethodChannel(messenger, "com.barnabas.absorb/wear_player")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publish" -> {
                        WearPlayerBridge.publish(
                            context = activity.applicationContext,
                            hasBook = call.argument<Boolean>("hasBook") ?: false,
                            itemId = call.argument<String>("itemId"),
                            title = call.argument<String>("title"),
                            author = call.argument<String>("author"),
                            chapter = call.argument<String>("chapter"),
                            isPlaying = call.argument<Boolean>("isPlaying") ?: false,
                            positionMs = (call.argument<Number>("positionMs") ?: 0).toLong(),
                            durationMs = (call.argument<Number>("durationMs") ?: 0).toLong(),
                            speed = (call.argument<Number>("speed") ?: 1.0).toFloat(),
                            skipBackSec = (call.argument<Number>("skipBackSec") ?: 10).toInt(),
                            skipForwardSec = (call.argument<Number>("skipForwardSec") ?: 30).toInt(),
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Bridge ABS auth state to the paired Wear OS app (AbsorbWear)
        // over the Google Play Services Wearable Data Layer.
        MethodChannel(messenger, "com.barnabas.absorb/wear_auth")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publish" -> {
                        val serverUrl = call.argument<String>("serverUrl")
                        val accessToken = call.argument<String>("accessToken")
                        val username = call.argument<String>("username") ?: ""
                        if (serverUrl == null || accessToken == null) {
                            result.error("MISSING_ARGS", "serverUrl and accessToken are required", null)
                            return@setMethodCallHandler
                        }
                        @Suppress("UNCHECKED_CAST")
                        val headers = (call.argument<Map<String, Any?>>("customHeaders") ?: emptyMap())
                            .mapNotNull { (k, v) -> if (v is String) k to v else null }
                            .toMap()
                        WearAuthBridge.publish(
                            context = activity.applicationContext,
                            serverUrl = serverUrl,
                            accessToken = accessToken,
                            refreshToken = call.argument<String>("refreshToken"),
                            username = username,
                            userId = call.argument<String>("userId"),
                            isLegacyToken = call.argument<Boolean>("isLegacyToken") ?: false,
                            customHeaders = headers,
                            supportsTokenReturn = call.argument<Boolean>("supportsTokenReturn") ?: false,
                        )
                        result.success(true)
                    }
                    "clear" -> {
                        WearAuthBridge.clear(activity.applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
