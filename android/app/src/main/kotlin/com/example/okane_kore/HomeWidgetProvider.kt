package com.example.okane_kore

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class HomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        for (widgetId in appWidgetIds) {
            val streak = prefs.getInt("streak", 0)
            val level = prefs.getInt("level", 1)
            val mission = prefs.getString("todayMissionTitle", "ミッションを確認しよう")
            val views = RemoteViews(context.packageName, R.layout.home_widget_layout)
            views.setTextViewText(R.id.widget_streak_text, "🔥 ${streak}日連続")
            views.setTextViewText(R.id.widget_level_text, "Lv.${level}")
            views.setTextViewText(R.id.widget_mission_text, mission)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
