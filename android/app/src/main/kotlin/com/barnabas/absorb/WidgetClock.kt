package com.barnabas.absorb

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.view.KeyEvent
import android.widget.RemoteViews
import com.ryanheise.audioservice.AudioServicePlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.embedding.engine.FlutterEngineCache
import org.json.JSONArray

// Shared live-clock machinery for the now-playing widgets: the squiggle
// progress bar bitmap, elapsed/remaining formatting, position extrapolation
// between the app's throttled data pushes, and a per-second ticker that
// patches only the clock text (plus an occasional bar refresh) via
// partiallyUpdateAppWidget - the cover bitmap is never re-sent, so a tick is
// a few bytes of IPC. Skips all work while the screen is off and stops itself
// when playback stops. The process is alive whenever this matters because
// playback holds a foreground service.
internal object WidgetClock {
    // Android's own cell-size formula: 70dp per cell, 30dp inter-cell gap.
    fun cellsFor(dp: Int): Int = if (dp <= 0) 1 else (dp + 30) / 70

    // Launcher rows are not one size: a 1-row widget is ~121dp on the Pixel,
    // ~102dp on One UI and under 90dp on Nothing and OnePlus launchers. A
    // row-height widget below this gets the tightened one-line layout, or
    // the play pill is cut off at the bottom.
    const val SHORT_ROW_MAX_HEIGHT_DP = 95

    /// Portrait height in dp from the widget options (MAX_HEIGHT is the
    /// portrait figure; fall back to the landscape one when it is missing).
    fun portraitHeightDp(options: android.os.Bundle): Int {
        val max = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        if (max > 0) return max
        return options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
    }

    // widget_has_book / widget_title are stashed prefs that outlive the app
    // process, so they still read true after a swipe-close. Routing a tap
    // through the MediaSession broadcast in that state is a dead end -
    // AudioService.onCreate only adopts a cached engine, never creates one,
    // so a truly dead process can't pick the button press up at all. Gate on
    // whether an engine is actually cached to tell "session still alive" from
    // "just stale prefs" and fall back to a normal cold-start app launch.
    fun isEngineAlive(): Boolean =
        FlutterEngineCache.getInstance().get(AudioServicePlugin.getFlutterEngineId()) != null

    // The widgets' play/pause tap, shared by all three sizes. While the engine
    // is alive the MediaSession broadcast toggles playback without opening the
    // app. When the process died since the button was wired (nothing re-renders
    // widgets at engine death, so the wiring goes stale), that broadcast is a
    // dead end - AudioService never creates an engine - and the tap used to do
    // nothing until a second tap hit the re-wired button. Fall back to the same
    // cold-start launch the render-time wiring uses when it knows the app is
    // dead: open the app with the play deep link.
    fun sendPlayPause(context: Context) {
        if (isEngineAlive()) {
            val mediaIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                component = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
                putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE))
            }
            context.sendBroadcast(mediaIntent)
            return
        }
        try {
            HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java,
                Uri.parse("absorb://widget/play_pause")
            ).send()
        } catch (e: Exception) {
            android.util.Log.e("WidgetClock", "cold-start launch from widget tap failed", e)
        }
    }

    // A play tap can take seconds to produce audio (a cold start boots the
    // whole app first), and a button that doesn't react reads as dead. Taps
    // that should START playback stamp this; renders show a spinner on the
    // play pill until real state arrives or the window expires.
    private const val PENDING_PLAY_WINDOW_MS = 15_000L
    private const val PENDING_TAP_DEBOUNCE_MS = 2_500L

    fun pendingPlay(widgetData: SharedPreferences, isPlaying: Boolean): Boolean {
        val at = widgetData.getLong("widget_pending_play_at", 0L)
        if (at == 0L) return false
        if (isPlaying || System.currentTimeMillis() - at > PENDING_PLAY_WINDOW_MS) {
            widgetData.edit().remove("widget_pending_play_at").apply()
            return false
        }
        return true
    }

    fun renderAllNowPlaying(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        for (id in ids(context, mgr, NowPlayingWidget::class.java)) {
            try { NowPlayingWidget.updateWidget(context, mgr, id) } catch (e: Exception) {
                android.util.Log.e("WidgetClock", "render failed", e)
            }
        }
        for (id in ids(context, mgr, NowPlayingWidgetCompact::class.java)) {
            try { NowPlayingWidgetCompact.updateWidget(context, mgr, id) } catch (e: Exception) {
                android.util.Log.e("WidgetClock", "render failed", e)
            }
        }
        for (id in ids(context, mgr, NowPlayingWidgetTiny::class.java)) {
            try { NowPlayingWidgetTiny.updateWidget(context, mgr, id) } catch (e: Exception) {
                android.util.Log.e("WidgetClock", "render failed", e)
            }
        }
    }

    // Shared ACTION_TOGGLE_PLAYBACK handler for all three widget sizes.
    // Optimistic UI for pause only - never mark the widget playing before the
    // audio service confirms there is actually audio. Resume taps show the
    // pending spinner immediately and are debounced so mashing a slow-to-
    // react button doesn't queue extra toggles that pause it again.
    fun handleToggleTap(context: Context) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val now = System.currentTimeMillis()
        val wasPlaying = widgetData.getBoolean("widget_is_playing", false)
        if (!wasPlaying &&
            now - widgetData.getLong("widget_pending_play_at", 0L) < PENDING_TAP_DEBOUNCE_MS) {
            return
        }
        val edit = widgetData.edit().putBoolean("widget_is_playing", false)
        if (!wasPlaying) {
            edit.putLong("widget_pending_play_at", now)
        } else {
            edit.remove("widget_pending_play_at")
        }
        edit.apply()
        renderAllNowPlaying(context)
        if (!wasPlaying) {
            // Self-heal: if playback never materialises, a re-render after the
            // window clears the spinner instead of leaving it forever.
            val app = context.applicationContext
            tickHandler.postDelayed({
                try { renderAllNowPlaying(app) } catch (_: Exception) {}
            }, PENDING_PLAY_WINDOW_MS + 500L)
        }
        sendPlayPause(context)
    }

    // Width gate for the tiny widget's clocks beside the progress bar.
    // Measured: 2 real cells report 171dp (Pixel) / 201dp (One UI), 3 cells
    // 266dp / 315dp - so 230 means "at least 3 cells wide" on both.
    const val TINY_TIMES_MIN_WIDTH_DP = 230

    fun fmtTime(ms: Long): String {
        val totalS = ms / 1000
        val h = totalS / 3600
        val m = (totalS % 3600) / 60
        val s = totalS % 60
        return if (h > 0) String.format("%d:%02d:%02d", h, m, s) else String.format("%d:%02d", m, s)
    }

    data class ScopeTimes(val elapsedMs: Long, val remainingMs: Long, val fraction: Float)

    // Live position for the clocks and the bar. The app only pushes state
    // every couple of seconds (and much less often in the background), so
    // extrapolate from the last pushed position + timestamp + speed. In
    // chapter mode, resolve which chapter the extrapolated position falls in
    // from the stashed chapter list - that way the clock and bar roll over to
    // the next chapter on time even between pushes. Times are displayed as
    // listening time (content time / speed), matching the app and the
    // notification at non-1x speeds; it also makes the clock advance one
    // second per real second instead of jumping.
    fun computeTimes(widgetData: SharedPreferences): ScopeTimes? {
        val baseMs = widgetData.getInt("widget_pos_abs_ms", -1)
        val totalMs = widgetData.getInt("widget_total_ms", 0)
        if (baseMs < 0 || totalMs <= 0) return null

        val speedX100 = widgetData.getInt("widget_speed_x100", 100).coerceAtLeast(1)
        var absMs = baseMs.toLong()
        if (widgetData.getBoolean("widget_is_playing", false)) {
            val atS = widgetData.getInt("widget_pos_at_s", 0)
            if (atS > 0) {
                val realMs = System.currentTimeMillis() - atS * 1000L
                if (realMs > 0) absMs += realMs * speedX100 / 100
            }
        }
        absMs = absMs.coerceIn(0L, totalMs.toLong())

        var scopeStart = 0L
        var scopeEnd = totalMs.toLong()
        if (widgetData.getBoolean("widget_chapter_mode", false)) {
            val json = widgetData.getString("np_chapters_json", null)
            if (!json.isNullOrEmpty()) {
                try {
                    val arr = JSONArray(json)
                    for (i in 0 until arr.length()) {
                        val ch = arr.optJSONObject(i) ?: continue
                        val startMs = (ch.optDouble("start", -1.0) * 1000).toLong()
                        val endMs = (ch.optDouble("end", -1.0) * 1000).toLong()
                        if (startMs < 0 || endMs <= startMs) continue
                        if (absMs >= startMs && (absMs < endMs || i == arr.length() - 1)) {
                            scopeStart = startMs
                            scopeEnd = endMs
                            break
                        }
                    }
                } catch (_: Exception) {
                }
            }
        }

        val scopeLen = (scopeEnd - scopeStart).coerceAtLeast(1L)
        val elapsed = (absMs - scopeStart).coerceIn(0L, scopeLen)
        return ScopeTimes(
            elapsed * 100 / speedX100,
            (scopeLen - elapsed) * 100 / speedX100,
            elapsed.toFloat() / scopeLen
        )
    }

    // Progress bar drawn by hand so we can give it the Android-Auto squiggle:
    // the played portion waves while playing and flattens when paused, the
    // rest stays a dim straight track. The wave is static, not animated.
    fun drawProgressBar(
        widthPx: Int,
        heightPx: Int,
        fraction: Float,
        playing: Boolean,
        density: Float
    ): Bitmap {
        val w = widthPx.coerceAtLeast(1)
        val h = heightPx.coerceAtLeast(1)
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val centerY = h / 2f
        val stroke = 2.5f * density
        val inset = stroke
        val progressX = (w * fraction.coerceIn(0f, 1f)).coerceIn(inset, w - inset)

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0x66FFFFFF
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
        }
        val activePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFFFFFFF.toInt()
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
        }

        canvas.drawLine(progressX, centerY, w - inset, centerY, trackPaint)

        if (playing) {
            // Capped so the wave fits thinner bars (the compact strip).
            val amplitude = minOf(1.8f * density, (h - stroke * 2) / 2f).coerceAtLeast(0.75f)
            val wavelength = 36f * density
            val path = Path()
            path.moveTo(inset, centerY)
            var x = inset
            while (x < progressX) {
                val y = centerY + amplitude * Math.sin((x / wavelength) * 2.0 * Math.PI).toFloat()
                path.lineTo(x, y)
                x += 1.5f
            }
            path.lineTo(progressX, centerY + amplitude * Math.sin((progressX / wavelength) * 2.0 * Math.PI).toFloat())
            canvas.drawPath(path, activePaint)
        } else {
            canvas.drawLine(inset, centerY, progressX, centerY, activePaint)
        }

        return bmp
    }

    // Bar bitmap width estimates per widget. The bars are stretched with
    // fitXY, so these only need to be close: the tiny widget's row padding
    // eats ~36dp and its two clocks ~110dp; the big widget loses its cover
    // and text padding.
    fun tinyBarWidthPx(widthDp: Int, showTimes: Boolean, density: Float): Int =
        ((widthDp - 36 - if (showTimes) 110 else 0).coerceAtLeast(40) * density).toInt()

    fun bigBarWidthPx(widthDp: Int, density: Float): Int =
        ((widthDp - 160).coerceAtLeast(60) * density).toInt()

    // ── Per-second ticker ──

    private val tickHandler = Handler(Looper.getMainLooper())
    private var ticking = false
    private var tickCount = 0
    private var tickContext: Context? = null

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (!ticking) return
            val ctx = tickContext ?: return
            try {
                doTick(ctx)
            } catch (e: Exception) {
                android.util.Log.e("WidgetClock", "tick failed", e)
            }
            if (ticking) tickHandler.postDelayed(this, 1000L)
        }
    }

    private fun ids(context: Context, mgr: AppWidgetManager, cls: Class<*>): IntArray =
        mgr.getAppWidgetIds(ComponentName(context, cls))

    private fun minWidthDp(mgr: AppWidgetManager, id: Int): Int =
        mgr.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)

    fun syncTicker(context: Context) {
        val app = context.applicationContext
        val widgetData = HomeWidgetPlugin.getData(app)
        val hasPlayableItem = widgetData.getBoolean("widget_has_book", false) ||
            !widgetData.getString("widget_title", null).isNullOrEmpty()
        var shouldTick = hasPlayableItem &&
            widgetData.getBoolean("widget_is_playing", false)
        if (shouldTick) {
            // The compact widget shows no clocks or progress, so it never
            // needs ticks - only the big and (2+ cells wide) tiny widgets do.
            val mgr = AppWidgetManager.getInstance(app)
            shouldTick = ids(app, mgr, NowPlayingWidget::class.java).isNotEmpty() ||
                ids(app, mgr, NowPlayingWidgetTiny::class.java).any { cellsFor(minWidthDp(mgr, it)) >= 2 }
        }
        if (shouldTick && !ticking) {
            ticking = true
            tickCount = 0
            tickContext = app
            tickHandler.postDelayed(tickRunnable, 1000L)
        } else if (!shouldTick && ticking) {
            ticking = false
            tickContext = null
            tickHandler.removeCallbacks(tickRunnable)
        }
    }

    private fun doTick(context: Context) {
        tickCount++
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isInteractive) return
        val widgetData = HomeWidgetPlugin.getData(context)
        if (!widgetData.getBoolean("widget_is_playing", false)) {
            syncTicker(context)
            return
        }
        val times = computeTimes(widgetData) ?: return
        val density = context.resources.displayMetrics.density
        val mgr = AppWidgetManager.getInstance(context)
        val refreshBar = tickCount % 10 == 0
        val elapsed = fmtTime(times.elapsedMs)
        val remaining = "-" + fmtTime(times.remainingMs)

        for (id in ids(context, mgr, NowPlayingWidgetTiny::class.java)) {
            val widthDp = minWidthDp(mgr, id)
            if (cellsFor(widthDp) < 2) continue
            val showTimes = widthDp >= TINY_TIMES_MIN_WIDTH_DP
            if (!showTimes && !refreshBar) continue
            val partial = RemoteViews(context.packageName, R.layout.now_playing_widget_tiny)
            if (showTimes) {
                partial.setTextViewText(R.id.widget_time_elapsed, elapsed)
                partial.setTextViewText(R.id.widget_time_remaining, remaining)
            }
            if (refreshBar) {
                partial.setImageViewBitmap(
                    R.id.widget_progress,
                    drawProgressBar(tinyBarWidthPx(widthDp, showTimes, density), (12 * density).toInt(), times.fraction, true, density)
                )
            }
            mgr.partiallyUpdateAppWidget(id, partial)
        }

        for (id in ids(context, mgr, NowPlayingWidget::class.java)) {
            val partial = RemoteViews(context.packageName, R.layout.now_playing_widget)
            partial.setTextViewText(R.id.widget_time_elapsed, elapsed)
            partial.setTextViewText(R.id.widget_time_remaining, remaining)
            if (refreshBar) {
                partial.setImageViewBitmap(
                    R.id.widget_progress,
                    drawProgressBar(bigBarWidthPx(minWidthDp(mgr, id), density), (12 * density).toInt(), times.fraction, true, density)
                )
            }
            mgr.partiallyUpdateAppWidget(id, partial)
        }
    }
}
