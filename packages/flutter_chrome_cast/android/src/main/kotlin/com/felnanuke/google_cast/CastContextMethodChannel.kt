package com.felnanuke.google_cast

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import com.google.android.gms.cast.LaunchOptions
import java.util.concurrent.Executors

/**
 * Tag for logging Cast context operations
 */
private const val TAG = "CastContext"

/**
 * Flutter method channel for Google Cast context management
 * 
 * This class handles all Google Cast context-related operations, including SDK initialization,
 * configuration management, and Cast framework setup. It serves as the primary interface
 * between Flutter and the Google Cast SDK for Android context operations.
 *
 * Key responsibilities:
 * - Google Cast SDK initialization and configuration
 * - Cast context lifecycle management
 * - Permission handling for device discovery (Android 13+)
 * - Integration with other Cast method channels
 * - Activity lifecycle awareness for proper context management
 *
 * Architecture:
 * The class coordinates multiple Cast SDK components:
 * - DiscoveryManagerMethodChannel: Handles device discovery operations
 * - SessionManagerMethodChannel: Manages Cast session lifecycle
 * - CastContext: Core Google Cast SDK context for all operations
 *
 * The class implements ActivityAware to properly handle Android activity lifecycle
 * events and ensure Cast SDK operations work correctly with the host application.
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
class CastContextMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    /**
     * Flutter method channel for Cast context communication
     * 
     * This channel handles method calls related to Cast context operations,
     * including initialization, configuration, and state management.
     * Channel name: "com.felnanuke.google_cast.context"
     */
    private lateinit var channel: MethodChannel
    
    /**
     * Android application context for Cast SDK operations
     * 
     * Required for Google Cast SDK initialization and provides access
     * to system services and application-level resources needed for
     * Cast functionality.
     */
    private lateinit var appContext: Context
    
    /**
     * Discovery manager method channel for device discovery operations
     * 
     * Handles all Cast device discovery functionality including starting/stopping
     * discovery, managing discovered devices, and notifying Flutter of device changes.
     */
    private val discoveryManager = DiscoveryManagerMethodChannel()
    
    /**
     * Session manager method channel for Cast session management
     * 
     * Manages Cast session lifecycle including session creation, connection,
     * disconnection, and session state monitoring. Initialized with discovery manager
     * reference for device selection during session creation.
     */
    private lateinit var sessionManagerMethodChannel: SessionManagerMethodChannel
    
    /**
     * Permission launcher for nearby WiFi devices (Android 13+)
     * 
     * Handles runtime permission requests for accessing nearby WiFi devices,
     * which is required for Cast device discovery on Android 13 and higher.
     * Uses the new runtime permission system for enhanced privacy.
     */
    private lateinit var nearbyWifiDevicesPermissionLauncher: ActivityResultLauncher<String>
    
    /**
     * Executor for Cast context operations
     * 
     * Single-threaded executor used for Cast SDK operations that need to be
     * performed off the main thread to avoid blocking the UI.
     */
    private val executor = Executors.newSingleThreadExecutor()

    // MARK: - Flutter Plugin Lifecycle


    /**
     * Called when the Flutter plugin is attached to the Flutter engine
     * 
     * Initializes the Cast context method channel and sets up all necessary
     * components for Cast SDK operations. This method prepares the plugin
     * for Cast functionality by establishing communication channels and
     * initializing dependent components.
     *
     * Setup operations:
     * - Stores application context for Cast SDK operations
     * - Creates and configures the Cast context method channel
     * - Initializes the discovery manager for device discovery
     * - Sets up the session manager with discovery manager reference
     * - Prepares all components for Cast operations
     *
     * @param binding Flutter plugin binding providing access to engine resources
     */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.context")
        channel.setMethodCallHandler(this)
        discoveryManager.onAttachedToEngine(binding)
        sessionManagerMethodChannel = SessionManagerMethodChannel(discoveryManager)
        sessionManagerMethodChannel.onAttachedToEngine(binding)

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clean up session manager listener to prevent memory leaks
        try {
            CastContext.getSharedInstance(appContext)?.sessionManager?.removeSessionManagerListener(sessionManagerMethodChannel)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to remove session manager listener", e)
        }
    }


    // MethodCallHandler
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setSharedInstance" -> setSharedInstance(call.arguments, result)
            else -> result.notImplemented()
        }
    }

    private fun setupActivityResult(activity: ComponentActivity) {
        nearbyWifiDevicesPermissionLauncher =
            activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted: Boolean ->
                if (isGranted) {
                    Log.d(TAG, "Nearby WiFi devices permission granted")
                } else {
                    Log.w(TAG, "Nearby WiFi devices permission denied")
                }
            }
    }


    private fun setSharedInstance(arguments: Any?, result: MethodChannel.Result) {
        try {
            val map = arguments as HashMap<*, *>
            val optionsBuilder = CastOptions.Builder()
            optionsBuilder.setReceiverApplicationId(map["appId"] as String)
            val launcherOptions = LaunchOptions.Builder().setAndroidReceiverCompatible(true).build()
            optionsBuilder.setLaunchOptions(launcherOptions)
            optionsBuilder.setResumeSavedSession(true)
            optionsBuilder.setEnableReconnectionService(true)
            GoogleCastOptionsProvider.options = optionsBuilder.build()
            
            // Store the stopCastingOnAppTerminated option
            val stopCastingOnAppTerminated = map["stopCastingOnAppTerminated"] as? Boolean ?: false
            GoogleCastOptionsProvider.stopCastingOnAppTerminated = stopCastingOnAppTerminated
            Log.d(TAG, "stopCastingOnAppTerminated set to: $stopCastingOnAppTerminated")
            
            CastContext.getSharedInstance(appContext).sessionManager.addSessionManagerListener(sessionManagerMethodChannel)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set shared instance", e)
            result.error("CAST_ERROR", "Failed to initialize Cast context: ${e.message}", null)
        }
    }

}