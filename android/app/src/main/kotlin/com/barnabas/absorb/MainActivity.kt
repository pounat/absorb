package com.barnabas.absorb

import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.Uri
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import java.io.File
import java.io.FileInputStream
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs

import android.util.Log
import android.view.KeyEvent
import com.ryanheise.audioservice.AudioService
import com.ryanheise.audioservice.AudioServiceActivity
import com.ryanheise.audioservice.AudioServicePlugin
import com.ryanheise.just_audio.MonoController
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val TAG = "AbsorbEQ"
    private val CHANNEL = "com.absorb.equalizer"

    // Ebook reader: volume keys turn pages while watching is on. The keys are
    // consumed here so system volume doesn't change.
    private var volumeKeysChannel: MethodChannel? = null
    private var watchVolumeKeys = false

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

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        // Headless service starts (Android Auto binds, media buttons on a
        // dead process) boot the engine with no activity so the browse tree
        // works. Never attach the UI to such an engine unless it's actually
        // mid-playback - it has never rendered a frame and the launch sticks
        // on the splash screen. Tear it down and boot fresh instead.
        val cache = FlutterEngineCache.getInstance()
        val cached = cache.get(AudioServicePlugin.getFlutterEngineId())
        if (cached != null && AudioServicePlugin.wasEngineBornHeadless() &&
            !AudioService.isInstancePlaying()) {
            try {
                cache.remove(AudioServicePlugin.getFlutterEngineId())
                cached.destroy()
                Log.d(TAG, "Replaced idle headless-born engine with a fresh launch")
            } catch (e: Exception) {
                Log.e(TAG, "Headless engine teardown failed", e)
            }
        }
        return super.provideFlutterEngine(context)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.absorb.audio_diag")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "snapshot" -> result.success(AudioService.getDiagnosticSnapshot())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.absorb.update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBaseBuildNumber" ->
                        result.success(BuildConfig.ABSORB_BASE_VERSION_CODE)
                    else -> result.notImplemented()
                }
            }

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
                    "moveBookToSaf" -> handleMoveBookToSaf(call, result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.absorb.clip")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportClip" -> handleExportClip(call, result)
                    else -> result.notImplemented()
                }
            }

        // On-device bookmark transcription: decode a window of a downloaded
        // audio file into 16kHz mono WAV for Whisper. Heavy work runs on a
        // worker thread; the result is posted back on the main thread.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.barnabas.absorb/transcription")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "extractWav" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val outPath = call.argument<String>("outPath")
                        val startSeconds = call.argument<Double>("startSeconds") ?: 0.0
                        val durationSeconds = call.argument<Double>("durationSeconds") ?: 0.0
                        if (sourcePath == null || outPath == null) {
                            result.error("ARGS", "sourcePath and outPath are required", null)
                        } else {
                            Thread {
                                val ok = try {
                                    AudioWindowExtractor.extractWav(applicationContext, sourcePath, startSeconds, durationSeconds, outPath)
                                } catch (e: Exception) {
                                    Log.e(TAG, "extractWav crashed: ${e.message}")
                                    false
                                }
                                Handler(Looper.getMainLooper()).post { result.success(ok) }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        volumeKeysChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "com.absorb.volume_keys")
        volumeKeysChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "watch" -> { watchVolumeKeys = true; result.success(true) }
                "clearWatch" -> { watchVolumeKeys = false; result.success(true) }
                else -> result.notImplemented()
            }
        }

        // GMS-backed channels (cast foreground service, wear bridges).
        // Resolves to the real impl in github/playstore, no-op in fdroid.
        PlatformIntegration.registerChannels(this, flutterEngine)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (watchVolumeKeys) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    volumeKeysChannel?.invokeMethod("volumePressed", "up")
                    return true
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    volumeKeysChannel?.invokeMethod("volumePressed", "down")
                    return true
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    // Consume the matching key-up too so the system doesn't act on it.
    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (watchVolumeKeys &&
            (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)) {
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    // Physical page-turn keys - e-ink devices like the Boox Palma map their
    // side button to these. They must be grabbed BEFORE the view tree: a
    // focused WebView treats PAGE_UP/DOWN as scroll keys and shifts the
    // paginated book vertically instead of letting the app turn the page.
    // The Dart side decides what they do (page turn in the reader, play/pause
    // toggle otherwise).
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_PAGE_UP ||
            event.keyCode == KeyEvent.KEYCODE_PAGE_DOWN) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                volumeKeysChannel?.invokeMethod(
                    "pagePressed",
                    if (event.keyCode == KeyEvent.KEYCODE_PAGE_UP) "up" else "down")
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    // Move downloaded temp files into the user's SAF folder, creating the nested
    // [subfolder] (e.g. "Author/Title") under the granted tree via the DocumentFile
    // chain so files nest correctly and stay readable through the original grant.
    // The byte copy runs off the main thread.
    private fun handleMoveBookToSaf(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = call.argument<String>("treeUri")
        val subfolder = call.argument<String>("subfolder") ?: ""
        val filenames = call.argument<List<String>>("filenames")
        val tempPaths = call.argument<List<String>>("tempPaths")
        if (treeUri == null || filenames == null || tempPaths == null || filenames.size != tempPaths.size) {
            result.error("SAF_ARGS", "Invalid arguments", null)
            return
        }
        Thread {
            try {
                val tree = DocumentFile.fromTreeUri(applicationContext, Uri.parse(treeUri))
                    ?: throw IllegalStateException("Download folder not accessible")
                var dir: DocumentFile = tree
                for (segment in subfolder.split('/').filter { it.isNotBlank() }) {
                    val existing = dir.findFile(segment)
                    dir = if (existing != null && existing.isDirectory) existing
                        else (dir.createDirectory(segment)
                            ?: throw IllegalStateException("Could not create folder: $segment"))
                }
                val fileUris = ArrayList<String>(filenames.size)
                val temps = ArrayList<File>(filenames.size)
                for (i in filenames.indices) {
                    val name = filenames[i]
                    val temp = File(tempPaths[i])
                    if (!temp.exists()) throw IllegalStateException("Missing downloaded file: ${tempPaths[i]}")
                    // Replace any existing file of the same name (e.g. re-download).
                    dir.findFile(name)?.delete()
                    // octet-stream so SAF keeps the exact filename + extension (a
                    // real audio MIME makes the provider rewrite e.g. .m4b to .m4a).
                    // ExoPlayer detects the format from the file content anyway.
                    val doc = dir.createFile("application/octet-stream", name)
                        ?: throw IllegalStateException("Could not create file: $name")
                    contentResolver.openOutputStream(doc.uri)?.use { output ->
                        FileInputStream(temp).use { input -> input.copyTo(output, 64 * 1024) }
                    } ?: throw IllegalStateException("Could not write: $name")
                    temps.add(temp)
                    fileUris.add(doc.uri.toString())
                }
                // Only remove the internal copies once every file moved, so a
                // mid-way failure leaves the internal download intact to fall back on.
                temps.forEach { it.delete() }
                val dirUri = dir.uri.toString()
                runOnUiThread { result.success(mapOf("dirUri" to dirUri, "fileUris" to fileUris)) }
            } catch (e: Exception) {
                Log.e(TAG, "moveBookToSaf failed: ${e.message}", e)
                runOnUiThread { result.error("SAF_MOVE_ERROR", e.message, null) }
            }
        }.start()
    }

    // Extract a short audio window starting at a bookmark and write it as an
    // AAC .m4a clip (bookmark clip export). Runs off the main thread.
    private fun handleExportClip(call: MethodCall, result: MethodChannel.Result) {
        val source = call.argument<String>("source")
        val isLocal = call.argument<Boolean>("isLocal") ?: true
        val headers = call.argument<Map<String, String>>("headers")
        val startSeconds = call.argument<Double>("startSeconds") ?: 0.0
        val durationSeconds = call.argument<Double>("durationSeconds") ?: 60.0
        val outPath = call.argument<String>("outPath")
        if (source == null || outPath == null) {
            result.error("CLIP_ARGS", "Missing source or outPath", null)
            return
        }
        Thread {
            val ok = AudioClipExporter.exportM4a(
                applicationContext, source, isLocal, headers, startSeconds, durationSeconds, outPath)
            runOnUiThread {
                if (ok) result.success(true)
                else result.error("CLIP_FAILED", "Could not export clip", null)
            }
        }.start()
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
            Log.d(TAG, "EQ probe deferred until playback: ${e.message}")
            result.success(mapOf(
                "bands" to 5,
                "frequencies" to listOf(60, 230, 910, 3600, 14000),
                "minLevel" to -15.0,
                "maxLevel" to 15.0,
                "deferred" to true
            ))
        }
    }

    private fun handleAttachSession(sessionId: Int, result: MethodChannel.Result) {
        try {
            Log.d(TAG, "attachSession: $sessionId (previous: $currentSessionId, haveEffects=${equalizer != null})")
            // ExoPlayer reuses one audio session id across books. Re-attaching to
            // the SAME live session must reuse the effects already bound to it —
            // building a second Equalizer/BassBoost/etc. on that session without
            // releasing the old ones leaks native effects every book switch and
            // can cost our instance control of the engine, so EQ silently stops
            // affecting the sound until the process restarts. Only tear down and
            // rebuild when the session actually changed. Dart re-pushes the band /
            // enabled / effect values right after this call in either case.
            if (sessionId != 0 && sessionId == currentSessionId && equalizer != null) {
                result.success(true)
                return
            }
            releaseEffects()
            currentSessionId = sessionId

            if (sessionId == 0) {
                result.success(true)
                return
            }

            // init() probes Equalizer(0, 0) on the global output mix, which some
            // devices/HAL states reject with a catchable Error -3 right after a
            // process start (e.g. just after an app update) — which used to leave
            // effectsAvailable=false and EQ silent until a force-restart. A real
            // per-session effect usually still works, so build it here regardless
            // of the probe result and let this construction decide availability.
            // (A device that hard-crashes on construction would have crashed at
            // init already, so reaching this point means construction is catch-safe.)
            try {
                equalizer = Equalizer(0, sessionId).apply { enabled = false }
                effectsAvailable = true
            } catch (e: Exception) {
                effectsAvailable = false
                equalizer = null
                Log.w(TAG, "attachSession: Equalizer unavailable on session $sessionId: ${e.message}")
                result.success(true)
                return
            }
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
