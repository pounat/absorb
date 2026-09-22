package com.felnanuke.google_cast

import android.content.Context
import android.util.Log
import androidx.mediarouter.media.MediaControlIntent
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.felnanuke.google_cast.extensions.toMap
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.CastMediaControlIntent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.google.gson.Gson

/**
 * Tag for logging discovery manager operations
 */
private const val TAG = "DiscoveryManager"

/**
 * Flutter method channel for Google Cast device discovery operations
 * 
 * This class manages the discovery of Google Cast devices on the local network using
 * Android's MediaRouter framework. It handles device discovery lifecycle, maintains
 * discovered device state, and communicates device availability changes to Flutter.
 *
 * Key responsibilities:
 * - Cast device discovery management (start/stop)
 * - Real-time device availability monitoring
 * - Device state synchronization with Flutter
 * - Integration with Android MediaRouter framework
 * - Device selection and routing preparation
 *
 * Architecture:
 * The class uses Android's MediaRouter system to discover Cast devices:
 * - MediaRouter: Core Android component for device discovery
 * - MediaRouteSelector: Defines criteria for Cast device discovery
 * - DiscoveryRouterCallback: Handles device discovery events
 * - Device state management for Flutter communication
 *
 * Discovery Process:
 * 1. Creates MediaRouteSelector for Cast devices
 * 2. Registers callback with MediaRouter for device events
 * 3. Monitors device availability changes in real-time
 * 4. Notifies Flutter of discovered/removed devices
 * 5. Maintains device list for session creation
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
class DiscoveryManagerMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    /**
     * Flutter method channel for discovery communication
     * 
     * Handles method calls related to device discovery operations and sends
     * device availability updates to Flutter. Channel name: 
     * "com.felnanuke.google_cast.discovery_manager"
     */
    lateinit var channel: MethodChannel
    
    /**
     * Media router callback for device discovery events
     * 
     * Receives callbacks from Android's MediaRouter when Cast devices are
     * discovered, updated, or removed from the network. Implements the
     * callback interface to handle real-time device state changes.
     */
    val routerCallBack: DiscoveryRouterCallback = DiscoveryRouterCallback()
    
    /**
     * Android MediaRouter instance for device discovery
     * 
     * Core Android component that handles media device discovery and routing.
     * Provides access to available Cast devices on the local network and
     * manages the discovery process lifecycle.
     */
    val router: MediaRouter
        get() = MediaRouter.getInstance(context)
        
    /**
     * Android application context for system services
     * 
     * Required for accessing MediaRouter instance and other system services
     * needed for Cast device discovery operations.
     */
    private lateinit var context: Context

    // MARK: - Flutter Plugin Lifecycle


    /**
     * Called when the Flutter plugin is attached to the Flutter engine
     * 
     * Initializes the discovery manager method channel and prepares the
     * component for Cast device discovery operations.
     *
     * Setup operations:
     * - Creates the discovery manager method channel
     * - Registers this class as the method call handler
     * - Stores application context for MediaRouter access
     * - Prepares discovery infrastructure
     *
     * @param binding Flutter plugin binding providing access to engine resources
     */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.discovery_manager")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    /**
     * Called when the Flutter plugin is detached from the Flutter engine
     * 
     * Performs cleanup of discovery manager resources to prevent memory leaks.
     *
     * Cleanup operations:
     * - Removes method call handler from the channel
     * - Stops any active discovery operations
     * - Releases discovery-related resources
     *
     * @param binding Flutter plugin binding being detached
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    /**
     * Handles method calls from the Flutter side
     * 
     * Processes incoming method calls for device discovery operations.
     * Manages the discovery lifecycle and device state synchronization.
     *
     * Supported methods:
     * - `startDiscovery`: Begins Cast device discovery on the local network
     * - `stopDiscovery`: Stops Cast device discovery and clears device list
     *
     * @param call The method call from Flutter containing method name and arguments
     * @param result The result callback to return responses to Flutter
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDiscovery" -> {
                startDiscovery()
                result.success(true)
            }
            "stopDiscovery" -> {
                stopDiscovery()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun stopDiscovery() {

        router.removeCallback(routerCallBack)
    }

    private fun startDiscovery() {
        router.removeCallback(routerCallBack)
        val selector = MediaRouteSelector.Builder()
            .addControlCategories(listOf(CastMediaControlIntent.categoryForRemotePlayback()))
            .build()
        router.addCallback(
            selector, routerCallBack, MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY
        )

        routerCallBack.getCastDevicesMap()
    }

    inner class DiscoveryRouterCallback : MediaRouter.Callback() {

        override fun onRouteUnselected(
            router: MediaRouter, route: MediaRouter.RouteInfo, reason: Int
        ) {
            super.onRouteUnselected(router, route, reason)
            Log.d(TAG, "Route unselected, total routes: ${router.routes.size}")
        }

        override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteAdded(router, route)
            getCastDevicesMap()
        }

        override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteRemoved(router, route)
            getCastDevicesMap()
        }

        override fun onRouteChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteChanged(router, route)
            getCastDevicesMap()
        }

        override fun onRouteVolumeChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteVolumeChanged(router, route)
            getCastDevicesMap()
        }


        override fun onProviderAdded(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderAdded(router, provider)
            Log.d(TAG, "Provider added, total routes: ${router.routes.size}")
        }

        override fun onProviderRemoved(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderRemoved(router, provider)
            Log.d(TAG, "Provider removed, total routes: ${router.routes.size}")
        }

        override fun onProviderChanged(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderChanged(router, provider)
            Log.d(TAG, "Provider changed, total routes: ${router.routes.size}")
        }

        private fun getCastDevice(routeInfo: MediaRouter.RouteInfo): Map<*, *>? {
            val device = CastDevice.getFromBundle(routeInfo.extras)
            return device?.let {
                device.toMap()
            }


        }

        fun getCastDevicesMap() {
            val devices = mutableListOf<kotlin.collections.Map<*, *>>()
            val seenDeviceIds = mutableSetOf<String>()
            val seenDeviceSignatures = mutableSetOf<String>()
            
            for (route in router.routes) {
                val device = getCastDevice(route)
                if (device != null) {
                    val deviceId = device["id"] as? String
                    val deviceName = device["name"] as? String
                    val deviceModel = device["model_name"] as? String
                    val deviceSignature = "${deviceName}_${deviceModel}"
                    
                    Log.d(TAG, "Found route with device ID: $deviceId, name: $deviceName, model: $deviceModel")
                    
                    // Skip devices we've already seen by ID or by name+model combination
                    if (deviceId != null && 
                        !seenDeviceIds.contains(deviceId) && 
                        !seenDeviceSignatures.contains(deviceSignature)) {
                        seenDeviceIds.add(deviceId)
                        seenDeviceSignatures.add(deviceSignature)
                        devices.add(device)
                        Log.d(TAG, "Added unique device: $deviceId ($deviceSignature)")
                    } else {
                        Log.w(TAG, "Skipping duplicate device - ID: $deviceId, signature: $deviceSignature")
                    }
                }
            }
            val json = Gson().toJson(devices)
            this@DiscoveryManagerMethodChannel.channel.invokeMethod("onDevicesChanged", json)
            Log.w(TAG, "onDevicesChanged $json")
        }
    }

    fun selectRoute(id: String) {
        val routes = router?.routes
        val selectedRoute = routes?.find {
            val device = CastDevice.getFromBundle(it.extras)
            device?.deviceId == id
        }
        if (selectedRoute != null) {
            this.router?.selectRoute(selectedRoute)
        }
    }


}