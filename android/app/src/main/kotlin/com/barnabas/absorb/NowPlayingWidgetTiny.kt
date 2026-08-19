package com.barnabas.absorb

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.KeyEvent
import android.view.View
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

// Adaptive now-playing widget. At 1x1 it's just the cover with a centered
// play/pause tap target. Resize it larger and a notification-style player panel
// (title / author / chapter / progress / transport) fades in over the bottom of
// the cover; rows appear as the widget grows enough to hold them.
class NowPlayingWidgetTiny : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // Never let a widget render failure crash the whole app.
            try {
                updateWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                android.util.Log.e("NowPlayingWidgetTiny", "updateWidget failed", e)
            }
        }
    }

    // Re-render when the user resizes so the player panel appears/disappears
    // and the cover is decoded at a resolution that fits the new size.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        try {
            updateWidget(context, appWidgetManager, appWidgetId)
        } catch (e: Exception) {
            android.util.Log.e("NowPlayingWidgetTiny", "resize update failed", e)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        WidgetClock.syncTicker(context)
    }

    override fun onDisabled(context: Context) {
        WidgetClock.syncTicker(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TOGGLE_PLAYBACK) {
            WidgetClock.handleToggleTap(context)
            return
        }
        super.onReceive(context, intent)
    }

    companion object {
        const val ACTION_TOGGLE_PLAYBACK = "com.barnabas.absorb.ACTION_TOGGLE_PLAYBACK_TINY"

        // Portrait-height (dp) gates for the panel rows, measured across
        // launchers whose row heights differ a lot. A 1-row-tall widget reports
        // ~102dp (One UI) to ~121dp (Pixel); 2 rows ~233-257; 3 rows ~363-393.
        // These sit safely between those bands so tiers match on both.
        private const val INFO_MIN_HEIGHT_DP = 175
        private const val CHAPTER_MIN_HEIGHT_DP = 310

        private fun mediaButtonPendingIntent(
            context: Context,
            keyCode: Int,
            requestCode: Int
        ): PendingIntent {
            val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                component = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
                putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
            }
            return PendingIntent.getBroadcast(
                context, requestCode, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        }

        // Active-session play/pause: flip the icon instantly via our receiver,
        // which then forwards to the MediaSession.
        private fun togglePendingIntent(context: Context): PendingIntent {
            val toggleIntent = Intent(context, NowPlayingWidgetTiny::class.java).apply {
                action = ACTION_TOGGLE_PLAYBACK
            }
            return PendingIntent.getBroadcast(
                context, 1, toggleIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        }

        private fun openAppPendingIntent(context: Context): PendingIntent =
            HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("absorb://widget/open")
            )

        /// Mean brightness of the bottom slice of the cover - the part the
        /// player panel sits over. Sampled on a coarse grid rather than every
        /// pixel; this runs on every widget update and the answer only has to
        /// be right enough to pick between two scrims.
        private fun bottomBrightness(bitmap: Bitmap): Double {
            val h = bitmap.height
            val w = bitmap.width
            if (h <= 0 || w <= 0) return 0.0
            val startY = (h * 0.55).toInt().coerceIn(0, h - 1)
            val stepX = (w / 16).coerceAtLeast(1)
            val stepY = ((h - startY) / 12).coerceAtLeast(1)
            var total = 0.0
            var count = 0
            var y = startY
            while (y < h) {
                var x = 0
                while (x < w) {
                    val c = bitmap.getPixel(x, y)
                    if (((c shr 24) and 0xFF) > 8) {
                        val r = (c shr 16) and 0xFF
                        val g = (c shr 8) and 0xFF
                        val b = c and 0xFF
                        // Rec. 601 luma - closer to perceived brightness than a
                        // plain channel average, which reads blue as too light.
                        total += 0.299 * r + 0.587 * g + 0.114 * b
                        count++
                    }
                    x += stepX
                }
                y += stepY
            }
            return if (count == 0) 0.0 else total / count
        }

        // Above this the cover is bright enough that white text needs the full
        // scrim; below it the artwork already does the job.
        // Widest cover edge handed to RemoteViews. 768px in ARGB_8888 is about
        // 2.4MB, well clear of what a widget update will carry, and still twice
        // the linear detail of the 400px the player uses.
        private const val MAX_COVER_PX = 768

        private const val SCRIM_BRIGHTNESS_THRESHOLD = 88.0

        // Decode the cover no larger than the widget needs, then mask rounded
        // corners. targetPx keeps a big cover crisp without decoding a huge
        // bitmap that RemoteViews would refuse to serialise.
        private fun loadCover(path: String, targetPx: Int, radiusDp: Float, density: Float): Bitmap? {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            val srcEdge = minOf(bounds.outWidth, bounds.outHeight)
            var sample = 1
            while (srcEdge / (sample * 2) >= targetPx) sample *= 2

            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            val bitmap = BitmapFactory.decodeFile(path, opts) ?: return null

            // Scale the corner radius to the decoded bitmap so it looks right
            // after the ImageView's centerCrop maps it onto the tile.
            val displayPx = targetPx.toFloat().coerceAtLeast(1f)
            val scale = minOf(bitmap.width, bitmap.height).toFloat() / displayPx
            val radiusPx = radiusDp * density * scale
            // Hard ceiling on what gets handed to RemoteViews. inSampleSize only
            // halves, so a 1000px source against a 1050px target stays at full
            // size - 1000x1000 in ARGB_8888 is 4MB, and an oversized bitmap does
            // not degrade, it makes the widget update fail silently. Scale to a
            // known-safe edge instead of hoping.
            val edge = minOf(bitmap.width, bitmap.height)
            val outEdge = minOf(edge, MAX_COVER_PX)
            val output = Bitmap.createBitmap(outEdge, outEdge, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(output)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            val outRadius = radiusPx * outEdge / edge.toFloat()
            canvas.drawRoundRect(RectF(0f, 0f, outEdge.toFloat(), outEdge.toFloat()), outRadius, outRadius, paint)
            paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
            // Centre-crop the source square into the output, matching what the
            // ImageView would have done anyway.
            val srcLeft = (bitmap.width - edge) / 2
            val srcTop = (bitmap.height - edge) / 2
            canvas.drawBitmap(
                bitmap,
                Rect(srcLeft, srcTop, srcLeft + edge, srcTop + edge),
                RectF(0f, 0f, outEdge.toFloat(), outEdge.toFloat()),
                paint,
            )
            // Recycle only the source: RemoteViews serialises `output` later in
            // updateAppWidget, so recycling it here crashes the app.
            bitmap.recycle()
            return output
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.now_playing_widget_tiny)

            // OnePlus launchers add their own generous widget padding,
            // so zero ours out to avoid double-padding.
            if (Build.MANUFACTURER.equals("OnePlus", ignoreCase = true)) {
                views.setViewPadding(R.id.widget_outer, 0, 0, 0, 0)
            }

            val hasBook = widgetData.getBoolean("widget_has_book", false)
            val isPlaying = widgetData.getBoolean("widget_is_playing", false)
            val title = widgetData.getString("widget_title", null)
            val canControl = (hasBook || !title.isNullOrEmpty()) && WidgetClock.isEngineAlive()
            val coverPath = widgetData.getString("widget_cover_path", null)

            // Current widget size. Portrait reports width via MIN_WIDTH and
            // height via MAX_HEIGHT; use the largest edge to size the cover.
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 40)
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 40)
            val density = context.resources.displayMetrics.density
            val targetPx = (maxOf(widthDp, heightDp, 80) * density).toInt()

            // Wide enough (2+ cells) for the transport row, and a session to control.
            val showPanel = canControl && WidgetClock.cellsFor(widthDp) >= 2
            // Reveal the info rows by how many dp of height the launcher actually
            // gives the widget, not by cell count: launcher row heights vary too
            // much (a 1-row widget reports ~102dp on One UI but ~121dp on Pixel),
            // and the old 70dp-cell formula miscounted the taller one as 2 rows.
            val showInfo = showPanel && heightDp >= INFO_MIN_HEIGHT_DP
            val showChapter = showPanel && heightDp >= CHAPTER_MIN_HEIGHT_DP

            // Cover art (rounded corners)
            var cover: Bitmap? = null
            if (coverPath != null) {
                val file = File(coverPath)
                if (file.exists()) {
                    cover = loadCover(file.absolutePath, targetPx, 16f, density)
                }
            }
            if (cover != null) {
                views.setImageViewBitmap(R.id.widget_cover, cover)
            } else {
                views.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher)
            }

            // The panel's background IS the scrim, so the taller the panel gets
            // the more artwork it fades out - worst on a big widget, which is
            // exactly where the cover is worth looking at. Match the fade to
            // the cover instead of always assuming the worst case: a dark cover
            // carries white text unaided, a pale one still needs the full wash.
            val darkCover = cover != null && bottomBrightness(cover) < SCRIM_BRIGHTNESS_THRESHOLD
            views.setInt(
                R.id.widget_panel,
                "setBackgroundResource",
                if (darkCover) R.drawable.widget_controls_scrim_soft
                else R.drawable.widget_controls_scrim,
            )

            val playPauseIcon = if (isPlaying) R.drawable.ic_widget_pause_dark else R.drawable.ic_widget_play_dark
            // Tap registered, audio not started yet (cold start can take
            // seconds) - spin instead of looking dead.
            val pendingPlay = WidgetClock.pendingPlay(widgetData, isPlaying)

            if (showPanel) {
                // Larger size: hide the centered dot, show the player panel.
                views.setViewVisibility(R.id.widget_play_pause, View.GONE)
                views.setViewVisibility(R.id.widget_panel, View.VISIBLE)

                // When it's only tall enough for the button row, keep the panel
                // tight; give it breathing room once text/progress appear.
                val pad = ((if (showInfo) 22 else 4) * density).toInt()
                views.setViewPadding(R.id.widget_panel, 0, pad, 0, pad)

                // The short tier now also carries a title line (see below), so
                // the transport row no longer fits at its full-height size
                // without getting clipped by the panel's available height -
                // shrink it to the same 40dp the compact widget uses, which is
                // also exactly what the pill drawable's corner radius is tuned
                // for.
                if (!showInfo && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    views.setViewLayoutHeight(R.id.widget_pp, 40f, TypedValue.COMPLEX_UNIT_DIP)
                    views.setViewLayoutWidth(R.id.widget_pp, 56f, TypedValue.COMPLEX_UNIT_DIP)
                    views.setViewLayoutHeight(R.id.widget_skip_back, 40f, TypedValue.COMPLEX_UNIT_DIP)
                    views.setViewLayoutHeight(R.id.widget_skip_forward, 40f, TypedValue.COMPLEX_UNIT_DIP)
                }

                // Transport + progress are in every panel size, including the
                // short buttons-only one (cover + squiggle + controls, like a
                // compact notification).
                views.setTextViewText(R.id.widget_skip_back_text, widgetData.getInt("widget_skip_back", 10).toString())
                views.setTextViewText(R.id.widget_skip_forward_text, widgetData.getInt("widget_skip_forward", 30).toString())
                if (pendingPlay) {
                    views.setImageViewResource(R.id.widget_pp, android.R.color.transparent)
                    views.setViewVisibility(R.id.widget_play_pending, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_play_pending, View.GONE)
                    views.setImageViewResource(R.id.widget_pp, playPauseIcon)
                }
                views.setViewVisibility(R.id.widget_play_pending_tile, View.GONE)

                val times = WidgetClock.computeTimes(widgetData)
                val fraction = times?.fraction ?: (widgetData.getInt("widget_progress", 0) / 1000f)
                val showTimes = widthDp >= WidgetClock.TINY_TIMES_MIN_WIDTH_DP && times != null
                views.setImageViewBitmap(
                    R.id.widget_progress,
                    WidgetClock.drawProgressBar(WidgetClock.tinyBarWidthPx(widthDp, showTimes, density), (12 * density).toInt(), fraction, isPlaying, density)
                )
                views.setViewVisibility(R.id.widget_progress_row, View.VISIBLE)

                // Elapsed / remaining clocks flank the bar on wide widgets;
                // the per-second ticker keeps them live while playing.
                if (showTimes) {
                    views.setTextViewText(R.id.widget_time_elapsed, WidgetClock.fmtTime(times!!.elapsedMs))
                    views.setTextViewText(R.id.widget_time_remaining, "-" + WidgetClock.fmtTime(times.remainingMs))
                    views.setViewVisibility(R.id.widget_time_elapsed, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_time_remaining, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_time_elapsed, View.GONE)
                    views.setViewVisibility(R.id.widget_time_remaining, View.GONE)
                }

                // Title shows as soon as the panel does, even at a 1-row
                // height (same as the compact widget) - just smaller and
                // alone. Author needs the extra vertical room from showInfo.
                views.setTextViewText(R.id.widget_title, if (title.isNullOrEmpty()) "Absorb" else title)
                views.setViewVisibility(R.id.widget_title, View.VISIBLE)
                if (showInfo) {
                    views.setTextViewTextSize(R.id.widget_title, TypedValue.COMPLEX_UNIT_SP, 15f)
                    val author = widgetData.getString("widget_author", null)
                    if (author.isNullOrEmpty()) {
                        views.setViewVisibility(R.id.widget_author, View.GONE)
                    } else {
                        views.setTextViewText(R.id.widget_author, author)
                        views.setViewVisibility(R.id.widget_author, View.VISIBLE)
                    }
                } else {
                    views.setTextViewTextSize(R.id.widget_title, TypedValue.COMPLEX_UNIT_SP, 12f)
                    views.setViewVisibility(R.id.widget_author, View.GONE)
                }

                val chapter = widgetData.getString("widget_chapter", null)
                if (showChapter && !chapter.isNullOrEmpty()) {
                    views.setTextViewText(R.id.widget_chapter, chapter)
                    views.setViewVisibility(R.id.widget_chapter, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_chapter, View.GONE)
                }

                views.setOnClickPendingIntent(
                    R.id.widget_skip_back,
                    mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_REWIND, 22)
                )
                views.setOnClickPendingIntent(R.id.widget_pp, togglePendingIntent(context))
                views.setOnClickPendingIntent(
                    R.id.widget_skip_forward,
                    mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_FAST_FORWARD, 23)
                )

                // Tapping the cover itself opens the app (buttons handle playback).
                views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent(context))
            } else {
                // 1x1: centered indicator, whole tile toggles play/pause.
                views.setViewVisibility(R.id.widget_panel, View.GONE)
                if (canControl) {
                    views.setViewVisibility(R.id.widget_play_pause, View.VISIBLE)
                    if (pendingPlay) {
                        views.setImageViewResource(R.id.widget_play_pause, android.R.color.transparent)
                        views.setViewVisibility(R.id.widget_play_pending_tile, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_play_pending_tile, View.GONE)
                        views.setImageViewResource(R.id.widget_play_pause, playPauseIcon)
                    }
                } else {
                    views.setViewVisibility(R.id.widget_play_pause, View.GONE)
                    views.setViewVisibility(R.id.widget_play_pending_tile, View.GONE)
                }

                val tapIntent = if (canControl) {
                    togglePendingIntent(context)
                } else {
                    HomeWidgetLaunchIntent.getActivity(
                        context, MainActivity::class.java, Uri.parse("absorb://widget/play_pause")
                    )
                }
                views.setOnClickPendingIntent(R.id.widget_root, tapIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            WidgetClock.syncTicker(context)
        }
    }
}
