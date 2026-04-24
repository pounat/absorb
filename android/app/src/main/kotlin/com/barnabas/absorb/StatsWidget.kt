package com.barnabas.absorb

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class StatsWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {

        private fun formatTime(seconds: Int): String {
            if (seconds <= 0) return "0m"
            val hours = seconds / 3600
            val minutes = (seconds % 3600) / 60
            return if (hours > 0) {
                if (minutes == 0) "${hours}h" else "${hours}h ${minutes}m"
            } else {
                "${minutes}m"
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.stats_widget)

            // OnePlus launchers add their own generous widget padding,
            // so zero ours out to avoid double-padding.
            if (Build.MANUFACTURER.equals("OnePlus", ignoreCase = true)) {
                views.setViewPadding(R.id.widget_outer, 0, 0, 0, 0)
            }

            val todaySeconds = widgetData.getInt("widget_stats_today", 0)
            val weekSeconds = widgetData.getInt("widget_stats_week", 0)
            val streakDays = widgetData.getInt("widget_stats_streak", 0)
            val booksYear = widgetData.getInt("widget_stats_books_year", 0)

            Log.d(
                "StatsWidget",
                "update id=$appWidgetId today=${todaySeconds}s week=${weekSeconds}s streak=${streakDays}d booksYear=$booksYear"
            )

            views.setTextViewText(R.id.widget_stat_today_value, formatTime(todaySeconds))
            views.setTextViewText(R.id.widget_stat_week_value, formatTime(weekSeconds))
            views.setTextViewText(R.id.widget_stat_streak_value, streakDays.toString())
            views.setTextViewText(R.id.widget_stat_books_year_value, booksYear.toString())

            // Tap anywhere on the widget opens the app.
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
