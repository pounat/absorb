package com.barnabas.absorb

import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.provider.MediaStore
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer
import android.os.Build
import android.os.Environment
import android.os.StatFs

import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import com.ryanheise.just_audio.MonoController
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val TAG = "AbsorbEQ"
    private val CHANNEL = "com.absorb.equalizer"

    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var currentSessionId: Int = 0
    private var eqEnabled: Boolean = false
    private var eqLoudnessGainMb: Int = 0  // gain from EQ loudness slider

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "moveToBackground" -> {
                        moveTaskToBack(true)
                        result.success(true)
                    }

                    "isBluetoothAudioConnected" -> {
                        result.success(isBluetoothAudioConnected())
                    }
                    "init" -> handleInit(result)
                    "attachSession" -> {
                        val sessionId = call.argument<Int>("sessionId") ?: 0
                        handleAttachSession(sessionId, result)
                    }
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        handleSetEnabled(enabled, result)
                    }
                    "setBand" -> {
                        val band = call.argument<Int>("band") ?: 0
                        val level = call.argument<Int>("level") ?: 0
                        handleSetBand(band, level, result)
                    }
                    "setBassBoost" -> {
                        val strength = call.argument<Int>("strength") ?: 0
                        handleSetBassBoost(strength, result)
                    }
                    "setVirtualizer" -> {
                        val strength = call.argument<Int>("strength") ?: 0
                        handleSetVirtualizer(strength, result)
                    }
                    "setLoudness" -> {
                        val gain = call.argument<Int>("gain") ?: 0
                        handleSetLoudness(gain, result)
                    }
                    "setMono" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        MonoController.setMonoEnabled(enabled)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        Log.d(TAG, "EQ method channel registered")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.absorb.storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceStorage" -> {
                        try {
                            val stat = StatFs(Environment.getDataDirectory().path)
                            result.success(mapOf(
                                "totalBytes" to stat.totalBytes,
                                "availableBytes" to stat.availableBytes
                            ))
                        } catch (e: Exception) {
                            result.error("STORAGE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.absorb.cast_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        CastForegroundService.start(this)
                        result.success(true)
                    }
                    "stop" -> {
                        CastForegroundService.stop(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Bridge ABS playback state to the watch so it can render Now
        // Playing without making its own API calls.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.barnabas.absorb/wear_player")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publish" -> {
                        WearPlayerBridge.publish(
                            context = applicationContext,
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.barnabas.absorb/wear_auth")
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
                            context = applicationContext,
                            serverUrl = serverUrl,
                            accessToken = accessToken,
                            refreshToken = call.argument<String>("refreshToken"),
                            username = username,
                            userId = call.argument<String>("userId"),
                            isLegacyToken = call.argument<Boolean>("isLegacyToken") ?: false,
                            customHeaders = headers,
                        )
                        result.success(true)
                    }
                    "clear" -> {
                        WearAuthBridge.clear(applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleInit(result: MethodChannel.Result) {
        try {
            val tempEq = Equalizer(0, 0)
            val numBands = tempEq.numberOfBands.toInt()
            val frequencies = mutableListOf<Int>()
            for (i in 0 until numBands) {
                frequencies.add(tempEq.getCenterFreq(i.toShort()) / 1000)
            }
            val bandRange = tempEq.bandLevelRange
            val minLevel = bandRange[0] / 100.0
            val maxLevel = bandRange[1] / 100.0
            tempEq.release()

            Log.d(TAG, "init: $numBands bands, frequencies=$frequencies, range=[$minLevel, $maxLevel]dB")
            result.success(mapOf(
                "bands" to numBands,
                "frequencies" to frequencies,
                "minLevel" to minLevel,
                "maxLevel" to maxLevel
            ))
        } catch (e: Exception) {
            Log.e(TAG, "init failed: ${e.message}")
            result.error("EQ_INIT_ERROR", e.message, null)
        }
    }

    private fun handleAttachSession(sessionId: Int, result: MethodChannel.Result) {
        try {
            Log.d(TAG, "attachSession: $sessionId (previous: $currentSessionId)")
            if (sessionId != currentSessionId) {
                releaseEffects()
            }
            currentSessionId = sessionId

            if (sessionId == 0) {
                result.success(true)
                return
            }

            equalizer = Equalizer(0, sessionId).apply { enabled = false }
            bassBoost = try {
                BassBoost(0, sessionId).apply { enabled = false }
            } catch (e: Exception) {
                Log.w(TAG, "BassBoost not supported: ${e.message}"); null
            }
            virtualizer = try {
                Virtualizer(0, sessionId).apply { enabled = false }
            } catch (e: Exception) {
                Log.w(TAG, "Virtualizer not supported: ${e.message}"); null
            }
            loudnessEnhancer = try {
                LoudnessEnhancer(sessionId).apply {
                    setTargetGain(eqLoudnessGainMb)
                    enabled = false
                }
            } catch (e: Exception) {
                Log.w(TAG, "LoudnessEnhancer not supported: ${e.message}"); null
            }

            // Alpha: capture LoudnessEnhancer/eq state on attach for GH #179 (volume falls off).
            Log.d(TAG, "Effects attached to session $sessionId: eqEnabled=$eqEnabled loudnessGainMb=$eqLoudnessGainMb loudnessEffectOk=${loudnessEnhancer != null}")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "attachSession failed: ${e.message}")
            result.error("EQ_ATTACH_ERROR", e.message, null)
        }
    }

    private fun handleSetEnabled(enabled: Boolean, result: MethodChannel.Result) {
        try {
            // Master switch gates only the band EQ. Bass / virtualizer /
            // loudness are independent and track their own values, so they
            // keep working with the equalizer off.
            eqEnabled = enabled
            equalizer?.enabled = enabled
            result.success(true)
        } catch (e: Exception) {
            result.error("EQ_ERROR", e.message, null)
        }
    }

    private fun handleSetBand(band: Int, level: Int, result: MethodChannel.Result) {
        try {
            equalizer?.setBandLevel(band.toShort(), level.toShort())
            result.success(true)
        } catch (e: Exception) {
            result.error("EQ_ERROR", e.message, null)
        }
    }

    private fun handleSetBassBoost(strength: Int, result: MethodChannel.Result) {
        try {
            val s = strength.toShort().coerceIn(0, 1000)
            bassBoost?.setStrength(s)
            // Independent of the band-EQ master: on when there's something to do.
            bassBoost?.enabled = s > 0
            result.success(true)
        } catch (e: Exception) {
            result.error("EQ_ERROR", e.message, null)
        }
    }

    private fun handleSetVirtualizer(strength: Int, result: MethodChannel.Result) {
        try {
            val s = strength.toShort().coerceIn(0, 1000)
            virtualizer?.setStrength(s)
            virtualizer?.enabled = s > 0
            result.success(true)
        } catch (e: Exception) {
            result.error("EQ_ERROR", e.message, null)
        }
    }

    private fun handleSetLoudness(gain: Int, result: MethodChannel.Result) {
        try {
            eqLoudnessGainMb = gain
            loudnessEnhancer?.setTargetGain(gain)
            loudnessEnhancer?.enabled = gain > 0
            result.success(true)
        } catch (e: Exception) {
            result.error("EQ_ERROR", e.message, null)
        }
    }

    private fun releaseEffects() {
        try { equalizer?.release() } catch (_: Exception) {}
        try { bassBoost?.release() } catch (_: Exception) {}
        try { virtualizer?.release() } catch (_: Exception) {}
        try { loudnessEnhancer?.release() } catch (_: Exception) {}
        equalizer = null
        bassBoost = null
        virtualizer = null
        loudnessEnhancer = null
        eqLoudnessGainMb = 0
        eqEnabled = false
    }

    private fun isBluetoothAudioConnected(): Boolean {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            return devices.any {
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
            }
        }
        @Suppress("DEPRECATION")
        return am.isBluetoothA2dpOn || am.isBluetoothScoOn
    }

    // Discard media search intents from Google Assistant / Android Auto so the
    // voice query text doesn't leak into the app's search field.
    override fun onNewIntent(intent: Intent) {
        val action = intent.action
        if (action == MediaStore.INTENT_ACTION_MEDIA_PLAY_FROM_SEARCH ||
            action == Intent.ACTION_SEARCH ||
            action == "android.media.action.MEDIA_PLAY_FROM_SEARCH") {
            Log.d(TAG, "Discarding search intent: $action")
            return
        }
        super.onNewIntent(intent)
    }

    override fun onDestroy() {
        releaseEffects()
        super.onDestroy()
    }

}
