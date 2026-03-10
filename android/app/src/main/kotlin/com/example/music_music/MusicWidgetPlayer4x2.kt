package com.example.music_music

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MusicWidgetPlayer4x2 : HomeWidgetProvider() {
    companion object {
        private const val TAG = "MusicWidgetPlayer4x2"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate ids=${appWidgetIds.joinToString()}")
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_player_4x2)

            val title = widgetData.getString("player_title", "Nenhuma musica") ?: "Nenhuma musica"
            val artist = widgetData.getString("player_artist", "-") ?: "-"
            val isPlaying = widgetData.getBoolean("player_isPlaying", false)
            val isShuffled = widgetData.getBoolean("player_isShuffled", false)
            val repeatMode = WidgetUtils.getIntCompat(widgetData, "player_repeatMode", 0)
            val isFavorite = widgetData.getBoolean("player_isFavorite", false)

            views.setTextViewText(R.id.widget_title_music, title)
            views.setTextViewText(R.id.widget_artist, artist)

            views.setImageViewResource(
                R.id.widget_play_pause,
                if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play
            )
            views.setImageViewResource(
                R.id.widget_repeat,
                if (repeatMode == 2) R.drawable.ic_repeat_one else R.drawable.ic_repeat
            )
            views.setImageViewResource(
                R.id.widget_favorite,
                if (isFavorite) R.drawable.ic_favorite else R.drawable.ic_favorite_outline
            )

            val activeColor = 0xFFFFB347.toInt()
            val inactiveColor = 0xFFFFFFFF.toInt()

            views.setInt(
                R.id.widget_shuffle,
                "setColorFilter",
                if (isShuffled) activeColor else inactiveColor
            )
            views.setInt(
                R.id.widget_repeat,
                "setColorFilter",
                if (repeatMode == 0) inactiveColor else activeColor
            )
            views.setInt(
                R.id.widget_favorite,
                "setColorFilter",
                if (isFavorite) activeColor else inactiveColor
            )

            views.setOnClickPendingIntent(
                R.id.widget_background,
                WidgetUtils.getOpenAppPendingIntent(context)
            )
            views.setOnClickPendingIntent(
                R.id.widget_shuffle,
                WidgetUtils.createActionPendingIntent(context, "shuffle")
            )
            views.setOnClickPendingIntent(
                R.id.widget_previous,
                WidgetUtils.createActionPendingIntent(context, "previous")
            )
            views.setOnClickPendingIntent(
                R.id.widget_play_pause,
                WidgetUtils.createActionPendingIntent(context, "play_pause")
            )
            views.setOnClickPendingIntent(
                R.id.widget_next,
                WidgetUtils.createActionPendingIntent(context, "next")
            )
            views.setOnClickPendingIntent(
                R.id.widget_repeat,
                WidgetUtils.createActionPendingIntent(context, "repeat")
            )
            views.setOnClickPendingIntent(
                R.id.widget_favorite,
                WidgetUtils.createActionPendingIntent(context, "favorite")
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
