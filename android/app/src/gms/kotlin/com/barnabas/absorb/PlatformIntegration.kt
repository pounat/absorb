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
        val wearPlayer = MethodChannel(messenger, "com.barnabas.absorb/wear_player")
        WearPlayerBridge.channel = wearPlayer
        wearPlayer
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publishChapters" -> {
                        val itemId = call.argument<String>("itemId")
                        val chapters = call.argument<String>("chapters")
                        if (itemId != null && chapters != null) {
                            WearPlayerBridge.publishChapters(activity.applicationContext, itemId, chapters)
                        }
                        result.success(true)
                    }
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
                            chapterStartMs = (call.argument<Number>("chapterStartMs") ?: 0).toLong(),
                            chapterEndMs = (call.argument<Number>("chapterEndMs") ?: 0).toLong(),
                            autoRewindEnabled = call.argument<Boolean>("autoRewindEnabled") ?: true,
                            autoRewindMinSec = (call.argument<Number>("autoRewindMinSec") ?: 1.0).toDouble(),
                            autoRewindMaxSec = (call.argument<Number>("autoRewindMaxSec") ?: 30.0).toDouble(),
                            autoRewindDelaySec = (call.argument<Number>("autoRewindDelaySec") ?: 0.0).toDouble(),
                            autoRewindChapterBarrier = call.argument<Boolean>("autoRewindChapterBarrier") ?: false,
                            autoRewindSessionStart = call.argument<Boolean>("autoRewindSessionStart") ?: false,
                            skipChapterBarrier = call.argument<Boolean>("skipChapterBarrier") ?: true,
                            speedAdjustedTime = call.argument<Boolean>("speedAdjustedTime") ?: true,
                            chapterIndex = (call.argument<Number>("chapterIndex") ?: -1).toInt(),
                            chapterCount = (call.argument<Number>("chapterCount") ?: 0).toInt(),
                            sleepMode = call.argument<String>("sleepMode"),
                            sleepEndsAtMs = (call.argument<Number>("sleepEndsAtMs") ?: 0).toLong(),
                            sleepChaptersLeft = (call.argument<Number>("sleepChaptersLeft") ?: 0).toInt(),
                            sleepAddMinutes = (call.argument<Number>("sleepAddMinutes") ?: 5).toInt(),
                            speedPresets = call.argument<List<Number>>("speedPresets")?.map { it.toFloat() } ?: emptyList(),
                            themeColor = (call.argument<Number>("themeColor") ?: 0).toLong(),
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
                            backend = call.argument<String>("backend") ?: "abs",
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
