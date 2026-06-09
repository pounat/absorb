package com.barnabas.absorb

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.provider.MediaStore
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs

import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import com.ryanheise.just_audio.MonoController
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
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
    // Some devices (e.g. older Samsung on Android 9) have a broken audio-effect
    // HAL that fails to initialize. Constructing AudioEffects against it during
    // playback can crash the process natively, which Kotlin can't catch. Once
    // init proves the engine is unavailable, skip attaching native effects.
    private var effectsAvailable: Boolean = true

    private val AAOS_CHANNEL = "com.absorb.aaos"
    private val AAOS_SETTINGS_ACTION = "android.intent.action.APPLICATION_PREFERENCES"
    private val AAOS_MEDIA_TEMPLATE_ACTION = "android.car.intent.action.MEDIA_TEMPLATE"
    private val AAOS_MEDIA_TEMPLATE_V2_ACTION = "androidx.car.app.mediaextensions.action.MEDIA_TEMPLATE_V2"
    private val AAOS_MEDIA_COMPONENT_EXTRA = "android.car.intent.extra.MEDIA_COMPONENT"

    private var aaosChannel: MethodChannel? = null
    private var pendingAaosOpenSettings = false

    private fun isAutomotive(): Boolean =
        packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleAaosIntent(intent)
        maybeLaunchMediaCenterFromMainIntent(intent)
    }

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

        aaosChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AAOS_CHANNEL)
        aaosChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "launchMediaCenter" -> handleLaunchMediaCenter(call, result)
                "launchSignIn" -> handleLaunchSignIn(result)
                else -> result.notImplemented()
            }
        }
        notifyAaosOpenSettingsIfPending()

        // GMS-backed channels (cast foreground service, wear bridges).
        // Resolves to the real impl in github/playstore, no-op in fdroid.
        PlatformIntegration.registerChannels(this, flutterEngine)
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

            effectsAvailable = true
            Log.d(TAG, "init: $numBands bands, frequencies=$frequencies, range=[$minLevel, $maxLevel]dB")
            result.success(mapOf(
                "bands" to numBands,
                "frequencies" to frequencies,
                "minLevel" to minLevel,
                "maxLevel" to maxLevel
            ))
        } catch (e: Exception) {
            effectsAvailable = false
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

            // Don't touch the audio-effect HAL on devices where it failed to
            // init, since constructing effects there can crash natively.
            // Software presets still drive the EQ UI; we just skip hardware fx.
            if (!effectsAvailable) {
                Log.w(TAG, "attachSession: effect engine unavailable, skipping native effects for session $sessionId")
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
        setIntent(intent)
        handleAaosIntent(intent)
        maybeLaunchMediaCenterFromMainIntent(intent)
    }

    // The car settings gear opens the app through APPLICATION_PREFERENCES.
    // Forward that to Dart so it can show the settings screen while parked.
    private fun handleAaosIntent(intent: Intent?) {
        if (intent == null || !isAutomotive()) return
        if (intent.action != AAOS_SETTINGS_ACTION) return
        pendingAaosOpenSettings = true
        notifyAaosOpenSettingsIfPending()
    }

    private fun notifyAaosOpenSettingsIfPending() {
        if (!pendingAaosOpenSettings) return
        val channel = aaosChannel ?: return
        pendingAaosOpenSettings = false
        Handler(Looper.getMainLooper()).postDelayed({
            channel.invokeMethod("openSettings", null)
        }, 300)
    }

    // On the car the touch UI isn't the entry point; a plain launch should bounce
    // straight to the system media center driven by our browse service.
    private fun maybeLaunchMediaCenterFromMainIntent(intent: Intent?): Boolean {
        if (intent == null || !isAutomotive()) return false
        if (intent.action != Intent.ACTION_MAIN) return false
        if (!intent.hasCategory(Intent.CATEGORY_LAUNCHER)) return false
        return launchMediaCenterInternal(finishActivity = true)
    }

    private fun handleLaunchMediaCenter(call: MethodCall, result: MethodChannel.Result) {
        if (!isAutomotive()) {
            result.success(false)
            return
        }
        try {
            val finishActivity = call.argument<Boolean>("finishActivity") ?: false
            result.success(launchMediaCenterInternal(finishActivity = finishActivity))
        } catch (e: Exception) {
            result.error("LAUNCH_FAILED", "Failed to launch media center: ${e.message}", null)
        }
    }

    // Bring the app to the front so the user can sign in. On the car this lands
    // on the login screen since no session exists yet.
    private fun handleLaunchSignIn(result: MethodChannel.Result) {
        if (!isAutomotive()) {
            result.success(false)
            return
        }
        try {
            val intent = Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("LAUNCH_FAILED", "Failed to launch sign-in: ${e.message}", null)
        }
    }

    private fun launchMediaCenterInternal(finishActivity: Boolean): Boolean {
        val componentName = ComponentName(packageName, "com.ryanheise.audioservice.AudioService")
        return try {
            startActivity(buildMediaHostIntent(componentName))
            if (finishActivity && !isFinishing) {
                finish()
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun buildMediaHostIntent(componentName: ComponentName): Intent {
        val supportsV2 = packageManager.queryIntentActivities(
            Intent(AAOS_MEDIA_TEMPLATE_V2_ACTION),
            PackageManager.MATCH_DEFAULT_ONLY or PackageManager.MATCH_SYSTEM_ONLY,
        ).isNotEmpty()
        val action = if (supportsV2) AAOS_MEDIA_TEMPLATE_V2_ACTION else AAOS_MEDIA_TEMPLATE_ACTION
        return Intent(action)
            .putExtra(AAOS_MEDIA_COMPONENT_EXTRA, componentName.flattenToString())
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    override fun onDestroy() {
        releaseEffects()
        super.onDestroy()
    }

}
