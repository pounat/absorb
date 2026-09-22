package com.felnanuke.google_cast

import android.media.session.MediaSession
import android.util.Log
import com.felnanuke.google_cast.extensions.*
import com.google.android.gms.cast.MediaStatus.REPEAT_MODE_REPEAT_ALL
import com.google.android.gms.cast.MediaStatus.REPEAT_MODE_REPEAT_ALL_AND_SHUFFLE
import com.google.android.gms.cast.MediaStatus.REPEAT_MODE_REPEAT_OFF
import com.google.android.gms.cast.MediaStatus.REPEAT_MODE_REPEAT_SINGLE
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Tag for logging remote media client operations
 */
private const val TAG = "RemoteMediaClient"

/**
 * Flutter method channel for Google Cast remote media client operations
 *
 * This class manages all media-related operations for Google Cast sessions, providing
 * comprehensive control over media playback, queue management, and media status monitoring.
 * It implements Google Cast remote media client callback interfaces to receive media
 * events and progress updates, communicating these changes to Flutter in real-time.
 *
 * Key responsibilities:
 * - Media loading and queue management operations
 * - Playback controls (play, pause, stop, seek)
 * - Volume and audio track management
 * - Media progress and status monitoring
 * - Queue operations (insert, remove, reorder items)
 * - Text track and subtitle controls
 * - Real-time media updates to Flutter
 *
 * Architecture:
 * The class integrates with Google Cast SDK media components:
 * - RemoteMediaClient: Core Cast SDK media control interface
 * - RemoteMediaClient.Callback: Receives media status change events
 * - RemoteMediaClient.ProgressListener: Monitors media playback progress
 * - Media queue management for playlist functionality
 * - Automatic progress tracking during media playback
 *
 * Media Operations:
 * 1. Media loading with metadata and options
 * 2. Queue management for playlist functionality
 * 3. Playback control and seeking operations
 * 4. Track selection and subtitle management
 * 5. Progress monitoring and status updates
 * 6. Event propagation to Flutter for UI updates
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
class RemoteMediaClientMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler,
    RemoteMediaClient.Callback(), RemoteMediaClient.ProgressListener {

    /**
     * Flutter method channel for remote media client communication
     *
     * Handles method calls related to media control operations and sends
     * media status and progress updates to Flutter. Channel name:
     * "com.felnanuke.google_cast.remote_media_client"
     */
    private lateinit var channel: MethodChannel

    /**
     * Current remote media client instance for the active Cast session
     *
     * Provides access to the media client for the current Cast session.
     * Returns null if no Cast session is active or no media client is available.
     *
     * @return The current remote media client, or null if not available
     */
    private val currentRemoteMediaClient: RemoteMediaClient?
        get() =
            CastContext.getSharedInstance()?.sessionManager?.currentCastSession?.remoteMediaClient

    // MARK: - Flutter Plugin Lifecycle


    /**
     * Called when the Flutter plugin is attached to the Flutter engine
     *
     * Initializes the remote media client method channel for media operations.
     *
     * Setup operations:
     * - Creates the remote media client method channel
     * - Registers this class as the method call handler
     * - Prepares media control infrastructure
     *
     * @param binding Flutter plugin binding providing access to engine resources
     */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.remote_media_client")
        channel.setMethodCallHandler(this)
    }

    /**
     * Called when the Flutter plugin is detached from the Flutter engine
     *
     * Performs cleanup of remote media client resources to prevent memory leaks.
     *
     * Cleanup operations:
     * - Removes method call handler from the channel
     * - Stops media monitoring
     * - Releases media-related resources
     *
     * @param binding Flutter plugin binding being detached
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clean up media client listeners to prevent memory leaks
        endListen()
    }

    // MARK: - Flutter Method Call Handling

    /**
     * Handles method calls from the Flutter side
     *
     * Processes incoming method calls for media control operations. Supports
     * comprehensive media management including loading, playback control,
     * queue management, and track selection.
     *
     * Supported methods:
     * - `loadMedia`: Load a single media item with options
     * - `queueLoadItems`: Load multiple items into a media queue
     * - `queueInsertItems`: Insert items into existing queue
     * - `queueInsertItemAndPlay`: Insert item and start playback
     * - `queueNextItem`: Skip to next item in queue
     * - `queuePrevItem`: Skip to previous item in queue
     * - `queueJumpToItemWithId`: Jump to specific queue item
     * - `queueRemoveItemsWithIds`: Remove items from queue
     * - `queueReorderItems`: Reorder queue items
     * - `seek`: Seek to specific position in media
     * - `setActiveTrackIds`: Select audio/subtitle tracks
     * - `setPlaybackRate`: Adjust playback speed
     * - `setTextTrackStyle`: Configure subtitle appearance
     * - `play`: Start or resume media playback
     * - `pause`: Pause media playback
     * - And many more media control operations...
     *
     * @param call The method call from Flutter containing method name and arguments
     * @param result The result callback to return responses to Flutter
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadMedia" -> {
                loadMedia(call.arguments as Map<String, Any?>)
                result.success(true)
            }

            "queueLoadItems" -> {
                queueLoadItems(call.arguments as Map<String, Any?>)
                result.success(true)
            }

            "queueInsertItems" -> {
                queueInsertItems(call.arguments as Map<String, Any?>)
                result.success(true)
            }

            "queueInsertItemAndPlay" -> {
                queueInsertItemAndPlay(call.arguments as Map<String, Any?>)
                result.success(true)
            }

            "queueNextItem" -> {
                queueNextItem()
                result.success(true)
            }

            "queuePrevItem" -> {
                queuePrevItem()
                result.success(true)
            }

            "queueJumpToItemWithId" -> {
                queueJumpToItemWithId(call.arguments)
                result.success(true)
            }

            "queueRemoveItemsWithIds" -> {
                queueRemoveItemsWithIds(call.arguments)
                result.success(true)
            }

            "queueReorderItems" -> {
                queueReorderItems(call.arguments)
                result.success(true)
            }

            "seek" -> {
                seek(call.arguments)
                result.success(true)
            }

            "setActiveTrackIds" -> {
                setActiveTrackIds(call.arguments)
                result.success(true)
            }

            "setPlaybackRate" -> {
                setPlaybackRate(call.arguments)
                result.success(true)
            }

            "setTextTrackStyle" -> {
                setTextTrackStyle(call.arguments)
                result.success(true)
            }

            "play" -> {
                play()
                result.success(true)
            }

            "pause" -> {
                pause()
                result.success(true)
            }
            "stop" -> {
                stop()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private fun setTextTrackStyle(arguments: Any?) {

    }

    private fun setPlaybackRate(arguments: Any?) {
        val playbackRate = arguments as Double
        currentRemoteMediaClient?.setPlaybackRate(playbackRate)
    }

    private fun setActiveTrackIds(arguments: Any?) {
        arguments as ArrayList<Long>
        val longArray = arguments.map {
            it.toLong()
        }
        currentRemoteMediaClient?.setActiveMediaTracks(longArray.toLongArray())
            ?.addStatusListener { status ->
                if (status.isSuccess) {

                    Log.w(TAG, "setActiveTrackIds success $longArray")
                } else {
                    Log.w(TAG, "setActiveTrackIds failed $longArray")
                }

            }


    }

    private fun seek(arguments: Any?) {
        arguments as Map<String, Any?>
        val options = GoogleCastSeekOptionsBuilder.fromMap(arguments)
        currentRemoteMediaClient?.seek(options)
    }

    private fun queueReorderItems(arguments: Any?) {
        arguments as Map<String, Any?>
        val itemIds = arguments["itemsIds"] as IntArray
        val beforeItemWithId =
            (arguments["beforeItemWithId"] as Int?) ?: MediaSession.QueueItem.UNKNOWN_ID
        currentRemoteMediaClient?.queueReorderItems(itemIds, beforeItemWithId, JSONObject())
    }

    private fun queueRemoveItemsWithIds(arguments: Any?) {
        arguments as IntArray
        currentRemoteMediaClient?.queueRemoveItems(arguments, JSONObject())
    }

    private fun queueJumpToItemWithId(arguments: Any?) {
        val itemId = arguments as Int
        currentRemoteMediaClient?.queueJumpToItem(itemId, JSONObject())

    }

    private fun queuePrevItem() {
        currentRemoteMediaClient?.queuePrev(JSONObject())
    }

    private fun queueNextItem() {
        currentRemoteMediaClient?.queueNext(JSONObject())
    }

    private fun queueInsertItemAndPlay(arguments: Map<String, Any?>) {
        val item =
            GoogleCastQueueItemBuilder.fromMap(arguments["item"] as Map<String, Any?>) ?: return
        val beforeItemWithId = arguments["beforeItemWithId"] as Int
        var jsonObject = JSONObject()
        currentRemoteMediaClient?.queueInsertAndPlayItem(item, beforeItemWithId, jsonObject)

    }

    private fun queueInsertItems(arguments: Map<String, Any?>) {
        val items =
            GoogleCastQueueItemBuilder.listFromMap(arguments["items"] as List<Map<String, Any?>>)
        val beforeItemWithId =
            (arguments["beforeItemWithId"] as Int?) ?: MediaSession.QueueItem.UNKNOWN_ID
        var jsonObject = JSONObject()
        currentRemoteMediaClient?.queueInsertItems(
            items.toTypedArray(),
            beforeItemWithId,
            jsonObject
        )

    }

    private fun pause() {
        currentRemoteMediaClient?.pause()
    }

    private fun play() {
        currentRemoteMediaClient?.play()

    }

    private fun stop() {
        currentRemoteMediaClient?.stop()
    }

    private fun queueLoadItems(arguments: Map<String, Any?>) {
        val queueItemsData = arguments["queueItems"] as List<Map<String, Any?>>
        val optionsData = arguments["options"] as Map<String, Any?>
        val startIndex = optionsData["startIndex"] as Int
        val repeatMode = optionsData["repeatMode"] as String?
        val playPosition = optionsData["playPosition"] as Int
        val queueItems = GoogleCastQueueItemBuilder.listFromMap(queueItemsData)
        currentRemoteMediaClient?.queueLoad(
            queueItems.toTypedArray(),
            startIndex,
            when (repeatMode) {
                "OFF" -> REPEAT_MODE_REPEAT_OFF
                "ALL" -> REPEAT_MODE_REPEAT_ALL
                "SINGLE" -> REPEAT_MODE_REPEAT_SINGLE
                "ALL_AND_SHUFFLE" -> REPEAT_MODE_REPEAT_ALL_AND_SHUFFLE
                else -> REPEAT_MODE_REPEAT_OFF
            },
            playPosition.toLong() * 1000,
            JSONObject()
        )
    }

    private fun loadMedia(arguments: Map<String, Any?>) {
        val mediaInfo =
            GoogleCastMediaInfo.fromMap(arguments["mediaInfo"] as Map<String, Any?>) ?: return
        val options = GoogleCastMediaLoadOptions.fromMap(arguments)
        currentRemoteMediaClient?.load(mediaInfo, options)
    }

    fun startListen() {
        currentRemoteMediaClient?.registerCallback(this)
        currentRemoteMediaClient?.addProgressListener(this, 500)
    }

    fun endListen() {
        currentRemoteMediaClient?.removeProgressListener(this)
        currentRemoteMediaClient?.unregisterCallback(this)
    }

    // ProgressListener
    override fun onProgressUpdated(progress: Long, duration: Long) {
        var data = mapOf<String, Any?>(
            "progress" to progress,
            "duration" to duration,
        )
        channel.invokeMethod("onPlayerPositionChanged", data)
    }
    // RemoteMediaCallBack

    override fun onStatusUpdated() {
        super.onStatusUpdated()
        val mediaStatus = currentRemoteMediaClient?.mediaStatus
        val jsonObject = currentRemoteMediaClient?.mediaStatus?.toJson()
        jsonObject?.put("activeTrackIds", Gson().toJson(mediaStatus?.activeTrackIds))
        Log.w(TAG, "onStatusUpdated $jsonObject")
        val json = jsonObject?.toString()
        channel.invokeMethod("onMediaStatusChanged", json)
    }

    override fun onQueueStatusUpdated() {
        super.onQueueStatusUpdated()
        val list = currentRemoteMediaClient?.mediaStatus?.queueItems?.map {
            it.toJson().toString()
        }
        channel.invokeMethod("onQueueStatusChanged", list)


    }
}
