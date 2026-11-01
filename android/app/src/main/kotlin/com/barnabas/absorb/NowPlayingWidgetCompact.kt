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
import android.graphics.RectF
import android.view.KeyEvent
import android.view.View
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

class NowPlayingWidgetCompact : AppWidgetProvider() {

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
                android.util.Log.e("NowPlayingWidgetCompact", "updateWidget failed", e)
            }
        }
    }

    // Re-render on resize so the short-row layout follows the height the
    // launcher actually gives the widget.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        try {
            updateWidget(context, appWidgetManager, appWidgetId)
        } catch (e: Exception) {
            android.util.Log.e("NowPlayingWidgetCompact", "resize update failed", e)
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
        const val ACTION_TOGGLE_PLAYBACK = "com.barnabas.absorb.ACTION_TOGGLE_PLAYBACK_COMPACT"

        private fun roundBitmap(bitmap: Bitmap, radiusDp: Float, context: Context): Bitmap {
            val density = context.resources.displayMetrics.density
            // Scale radius relative to the bitmap so corners look correct
            // after the ImageView's centerCrop scales the bitmap to fit.
            val displayPx = 150f * density
            val scale = minOf(bitmap.width, bitmap.height).toFloat() / displayPx
            val radiusPx = radiusDp * density * scale
            val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(output)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            val rect = RectF(0f, 0f, bitmap.width.toFloat(), bitmap.height.toFloat())
            canvas.drawRoundRect(rect, radiusPx, radiusPx, paint)
            paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
            canvas.drawBitmap(bitmap, 0f, 0f, paint)
            return output
        }

        private fun mediaButtonPendingIntent(
            context: Context,
            keyCode: Int,
            requestCode: Int
        ): PendingIntent {
            val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                component = ComponentName(
                    context,
                    "com.ryanheise.audioservice.MediaButtonReceiver"
                )
                putExtra(
                    Intent.EXTRA_KEY_EVENT,
                    KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
                )
            }
            return PendingIntent.getBroadcast(
                context, requestCode + 10, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.now_playing_widget_compact)

            // OnePlus and Nothing launchers add their own generous widget
            // padding, so zero ours out to avoid double-padding.
            if (Build.MANUFACTURER.lowercase() in setOf("oneplus", "nothing")) {
                views.setViewPadding(R.id.widget_outer, 0, 0, 0, 0)
            }

            // A launcher row shorter than the layout was drawn for: pull the
            // vertical slack out and shrink the transport so the title and
            // the buttons both fit instead of the pill being cut off.
            val heightDp = WidgetClock.portraitHeightDp(appWidgetManager.getAppWidgetOptions(appWidgetId))
            val shortRow = heightDp in 1 until WidgetClock.SHORT_ROW_MAX_HEIGHT_DP
            if (shortRow) {
                val density = context.resources.displayMetrics.density
                val pad = (2 * density).toInt()
                views.setViewPadding(R.id.widget_text_col, 0, pad, 0, pad)
                views.setTextViewTextSize(R.id.widget_title, TypedValue.COMPLEX_UNIT_SP, 12f)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    views.setViewLayoutMargin(R.id.widget_controls, RemoteViews.MARGIN_TOP, 2f, TypedValue.COMPLEX_UNIT_DIP)
                    views.setViewLayoutHeight(R.id.widget_play_pause, 32f, TypedValue.COMPLEX_UNIT_DIP)
                    views.setViewLayoutWidth(R.id.widget_play_pause, 48f, TypedValue.COMPLEX_UNIT_DIP)
                    views.setViewLayoutHeight(R.id.widget_skip_back, 32f, TypedValue.COMPLEX_UNIT_DIP)
                    views.setViewLayoutHeight(R.id.widget_skip_forward, 32f, TypedValue.COMPLEX_UNIT_DIP)
                }
            }

            val title = widgetData.getString("widget_title", null)
            val hasBook = widgetData.getBoolean("widget_has_book", false)
            val canControl = (hasBook || !title.isNullOrEmpty()) && WidgetClock.isEngineAlive()
            val isPlaying = widgetData.getBoolean("widget_is_playing", false)
            val coverPath = widgetData.getString("widget_cover_path", null)
            val skipBack = widgetData.getInt("widget_skip_back", 10)
            val skipForward = widgetData.getInt("widget_skip_forward", 30)

            views.setTextViewText(R.id.widget_skip_back_text, skipBack.toString())
            views.setTextViewText(R.id.widget_skip_forward_text, skipForward.toString())

            if (!title.isNullOrEmpty()) {
                // Just the title and the transport row - no author/progress/
                // clocks, so the card fits the shorter 1-cell heights on
                // Samsung-style launchers.
                views.setTextViewText(R.id.widget_title, title)
                views.setViewVisibility(R.id.widget_author, View.GONE)
                views.setViewVisibility(R.id.widget_controls, View.VISIBLE)

                if (WidgetClock.pendingPlay(widgetData, isPlaying)) {
                    // Tap registered, audio not started yet (cold start can
                    // take seconds) - spin instead of looking dead.
                    views.setImageViewResource(R.id.widget_play_pause, android.R.color.transparent)
                    views.setViewVisibility(R.id.widget_play_pending, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_play_pending, View.GONE)
                    if (isPlaying) {
                        views.setImageViewResource(R.id.widget_play_pause, R.drawable.ic_widget_pause_dark)
                    } else {
                        views.setImageViewResource(R.id.widget_play_pause, R.drawable.ic_widget_play_dark)
                    }
                }

                // Cover art from file (rounded corners)
                if (coverPath != null) {
                    val file = File(coverPath)
                    if (file.exists()) {
                        val options = BitmapFactory.Options().apply { inSampleSize = 2 }
                        val bitmap = BitmapFactory.decodeFile(file.absolutePath, options)
                        if (bitmap != null) {
                            val rounded = roundBitmap(bitmap, 24f, context)
                            views.setImageViewBitmap(R.id.widget_cover, rounded)
                            // Recycle only the source. RemoteViews serialises
                            // `rounded` later in updateAppWidget (Android 17 copies
                            // it to shared memory at that point) - recycling it here
                            // throws "Can't copy a recycled bitmap" and crashes the
                            // whole app when the widget is on the home screen.
                            bitmap.recycle()
                        } else {
                            views.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher)
                        }
                    } else {
                        views.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher)
                    }
                } else {
                    views.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher)
                }
            } else {
                // Idle state
                views.setTextViewText(R.id.widget_title, "Absorb")
                views.setTextViewText(R.id.widget_author, "Not playing")
                views.setViewVisibility(R.id.widget_author, View.VISIBLE)
                views.setViewVisibility(R.id.widget_controls, View.GONE)
                views.setViewVisibility(R.id.widget_play_pending, View.GONE)
                views.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher)
            }

            // Tap widget body to bring existing app to front
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                val pendingIntent = PendingIntent.getActivity(
                    context, 5, launchIntent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            // Playback controls
            views.setOnClickPendingIntent(
                R.id.widget_skip_back,
                mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_REWIND, 12)
            )
            val playPauseIntent = if (canControl) {
                val toggleIntent = Intent(context, NowPlayingWidgetCompact::class.java).apply {
                    action = ACTION_TOGGLE_PLAYBACK
                }
                PendingIntent.getBroadcast(
                    context, 11, toggleIntent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
            } else {
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("absorb://widget/play_pause")
                )
            }
            views.setOnClickPendingIntent(R.id.widget_play_pause, playPauseIntent)
            views.setOnClickPendingIntent(
                R.id.widget_skip_forward,
                mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_FAST_FORWARD, 13)
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
            WidgetClock.syncTicker(context)
        }
    }
}
