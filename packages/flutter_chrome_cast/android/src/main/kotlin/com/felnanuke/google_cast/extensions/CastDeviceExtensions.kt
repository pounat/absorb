package com.felnanuke.google_cast.extensions

import com.google.android.gms.cast.CastDevice

/**
 * Extension functions for Google Cast CastDevice to provide Flutter-compatible data conversion
 * 
 * This extension adds functionality to convert Google Cast SDK device objects into
 * Map format suitable for transmission to Flutter. It ensures all relevant device
 * information is properly serialized and accessible from the Flutter side.
 *
 * The extension provides a standardized way to represent Cast device information
 * across the Flutter-Android bridge, maintaining consistency in device data
 * representation and ensuring compatibility with Flutter's type system.
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */

/**
 * Converts the CastDevice object to a Flutter-compatible Map
 * 
 * This extension function serializes all relevant Cast device properties into a
 * Map format that can be transmitted to Flutter via method channels. The resulting
 * Map contains all essential device information needed for device identification
 * and display in the Flutter UI.
 *
 * Map keys and their corresponding values:
 * - `id`: Device unique identifier (String)
 * - `name`: User-friendly device name for display (String)
 * - `model_name`: Device model name (e.g., "Chromecast", "Google Nest Hub") (String)
 * - `device_version`: Device firmware/software version (String)
 * - `is_on_local_network`: Boolean indicating if device is on local network (Boolean)
 *
 * @return Map containing all device properties for Flutter consumption
 * @receiver CastDevice The Cast device to convert
 * @since Android API 21 (Android 5.0)
 * 
 * Example usage:
 * ```kotlin
 * val device: CastDevice = getDiscoveredDevice()
 * val deviceMap = device.toMap()
 * channel.invokeMethod("onDeviceDiscovered", deviceMap)
 * ```
 */
fun CastDevice.toMap(): Map<*, *> {
    return mapOf(
        "id" to this.deviceId,
        "name" to this.friendlyName,
        "model_name" to this.modelName,
        "device_version" to this.deviceVersion,
        "is_on_local_network" to this.isOnLocalNetwork,
    )
}