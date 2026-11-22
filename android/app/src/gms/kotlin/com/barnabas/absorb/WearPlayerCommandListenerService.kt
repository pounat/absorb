package com.barnabas.absorb

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.util.Log
import android.view.KeyEvent
import androidx.wear.remote.interactions.RemoteActivityHelper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

/**
 * Phone-side receiver for playback commands from the AbsorbWear watch.
 *
 * Kinds:
 *  - play-pause / skip-back / skip-forward: forwarded to the active
 *    MediaSession as a MEDIA_BUTTON broadcast. Same code path Bluetooth
 *    headphones and the NowPlayingWidget already use, so we get
 *    user-configured skip durations for free.
 *  - next-chapter / prev-chapter / bookmark / sleep / seek / speed /
 *    play-item: handed to the Dart player over the wear_player channel.
 *    When the app is not running it is started in the background, the way
 *    Android Auto starts it, and the request waits until it is ready.
 *    Opening the phone's screen from here is blocked by Android.
 *  - open-watch: opens the watch app on the asking watch.
 */
class WearPlayerCommandListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        when (event.path) {
            "/absorb/player/cmd/play-pause" -> playPause()
            "/absorb/player/cmd/skip-back" -> dispatchMediaButton(KeyEvent.KEYCODE_MEDIA_REWIND)
            "/absorb/player/cmd/skip-forward" -> dispatchMediaButton(KeyEvent.KEYCODE_MEDIA_FAST_FORWARD)
            "/absorb/player/cmd/play-item" -> handlePlayItem(event.data)
            "/absorb/player/cmd/volume-up" -> adjustVolume(AudioManager.ADJUST_RAISE, event.sourceNodeId)
            "/absorb/player/cmd/volume-down" -> adjustVolume(AudioManager.ADJUST_LOWER, event.sourceNodeId)
            "/absorb/player/cmd/volume-get" -> adjustVolume(AudioManager.ADJUST_SAME, event.sourceNodeId)
            "/absorb/player/cmd/next-chapter" -> command("next_chapter")
            "/absorb/player/cmd/prev-chapter" -> command("prev_chapter")
            "/absorb/player/cmd/bookmark" -> command("bookmark")
            "/absorb/player/cmd/stop" -> command("stop")
            "/absorb/player/cmd/sleep" -> command("sleep", jsonArgs(event.data))
            "/absorb/player/cmd/seek" -> command("seek", jsonArgs(event.data))
            "/absorb/player/cmd/speed" -> command("speed", jsonArgs(event.data))
            "/absorb/player/cmd/open-watch" -> openWatchApp(event.sourceNodeId)
            else -> super.onMessageReceived(event)
        }
    }

    private fun jsonArgs(data: ByteArray): Map<String, Any?> {
        if (data.isEmpty()) return emptyMap()
        return try {
            val obj = JSONObject(data.decodeToString())
            obj.keys().asSequence().associateWith { obj.get(it) }
        } catch (e: Exception) {
            Log.w(TAG, "command payload not JSON", e)
            emptyMap()
        }
    }

    // The Dart player takes it straight away while the app is up; otherwise
    // the app is started in the background and gets it once it is ready.
    private fun command(name: String, args: Map<String, Any?> = emptyMap()) {
        Log.i(TAG, "Watch -> $name $args")
        WearPlayerBridge.command(applicationContext, name, args)
    }

    // With the app up this is a media button press, like headphones. With it
    // down, a media button reaches no one, so the app is started and resumes
    // the last book itself.
    private fun playPause() {
        if (WearPlayerBridge.isReady) {
            dispatchMediaButton(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
        } else {
            command("play_pause")
        }
    }

    // The watch saw this phone start playing and has "Open when phone plays"
    // on. It may not open its own screen from the background, but Wear OS
    // will open it for us.
    private fun openWatchApp(nodeId: String) {
        val target = Intent(Intent.ACTION_VIEW)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .setData(Uri.parse("absorbwear://${applicationContext.packageName}/phone"))
        Log.i(TAG, "Watch -> open the watch app on $nodeId")
        try {
            val sent = RemoteActivityHelper(applicationContext).startRemoteActivity(target, nodeId)
            sent.addListener({
                try {
                    sent.get()
                    Log.i(TAG, "watch app open sent to $nodeId")
                } catch (e: Exception) {
                    Log.w(TAG, "opening the watch app on $nodeId failed", e)
                }
            }, { it.run() })
        } catch (e: Exception) {
            Log.w(TAG, "opening the watch app on $nodeId failed", e)
        }
    }

    private fun dispatchMediaButton(keyCode: Int) {
        Log.i(TAG, "Watch -> MediaButton keyCode=$keyCode")
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            component = ComponentName(
                applicationContext,
                "com.ryanheise.audioservice.MediaButtonReceiver",
            )
            putExtra(
                Intent.EXTRA_KEY_EVENT,
                KeyEvent(KeyEvent.ACTION_DOWN, keyCode),
            )
        }
        applicationContext.sendBroadcast(intent)
    }

    // The watch's crown, turned on its phone-remote screen: one step of
    // the media volume per message, with the system's own volume panel,
    // and the new level sent back so the watch can draw it.
    private fun adjustVolume(direction: Int, replyTo: String) {
        val audio = applicationContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        Log.i(TAG, "Watch -> volume direction=$direction")
        if (direction != AudioManager.ADJUST_SAME) {
            audio.adjustStreamVolume(AudioManager.STREAM_MUSIC, direction, AudioManager.FLAG_SHOW_UI)
        }
        val level = JSONObject()
            .put("index", audio.getStreamVolume(AudioManager.STREAM_MUSIC))
            .put("max", audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC))
            .toString()
        Wearable.getMessageClient(applicationContext)
            .sendMessage(replyTo, "/absorb/player/volume", level.toByteArray(Charsets.UTF_8))
            .addOnFailureListener { Log.w(TAG, "volume reply to $replyTo failed", it) }
    }

    private fun handlePlayItem(data: ByteArray) {
        val payload = try {
            JSONObject(data.decodeToString())
        } catch (e: Exception) {
            Log.w(TAG, "play-item payload not JSON", e); return
        }
        val itemId = payload.optString("itemId").ifBlank { null }
        if (itemId == null) {
            Log.w(TAG, "play-item missing itemId"); return
        }
        val episodeId = payload.optString("episodeId").ifBlank { null }
        // Where the watch was, so the phone carries on from there.
        val position = payload.optDouble("position").takeIf { it.isFinite() && it > 0.0 }

        val args = mutableMapOf<String, Any?>("itemId" to itemId)
        if (episodeId != null) args["episodeId"] = episodeId
        if (position != null) args["position"] = position
        command("play_item", args)
    }

    companion object {
        private const val TAG = "WearPlayerBridge"
    }
}
