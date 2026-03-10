package com.example.music_music

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.os.Build
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MusicWidgetPlayer4x4 : HomeWidgetProvider() {
    companion object {
        private const val QUEUE_JSON_KEY = "player_queue_all_json"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_player_4x4)

            val title = widgetData.getString("player_title", "Nenhuma musica") ?: "Nenhuma musica"
            val artist = widgetData.getString("player_artist", "-") ?: "-"
            val isPlaying = widgetData.getBoolean("player_isPlaying", false)
            val isShuffled = widgetData.getBoolean("player_isShuffled", false)
            val repeatMode = WidgetUtils.getIntCompat(widgetData, "player_repeatMode", 0)
            val isFavorite = widgetData.getBoolean("player_isFavorite", false)
            val queueCount = WidgetUtils.getIntCompat(widgetData, "player_queue_count", 0)
            val themeColor = WidgetUtils.getIntCompat(widgetData, "player_theme_color", 0xFFFFE0A3.toInt())
            val queueStartPosition = WidgetUtils.getIntCompat(widgetData, "player_queue_start_position", 1)
            val currentPosition = WidgetUtils.getIntCompat(widgetData, "player_current_position", 1)
            val totalTracks = WidgetUtils.getIntCompat(widgetData, "player_total_tracks", 0)
            val queueJson = widgetData.getString(QUEUE_JSON_KEY, "[]") ?: "[]"

            views.setTextViewText(R.id.widget_title_music, title)
            views.setTextViewText(R.id.widget_artist, artist)
            views.setTextViewText(R.id.widget_queue_header, "Proximas ($queueCount)")
            views.setTextViewText(
                R.id.widget_now_playing,
                if (totalTracks > 0) {
                    if (isPlaying) ">> Tocando #$currentPosition de $totalTracks" else "Pausado #$currentPosition de $totalTracks"
                } else {
                    if (isPlaying) ">> Tocando agora" else "Pausado"
                }
            )

            views.setTextColor(R.id.widget_queue_header, themeColor)
            views.setTextColor(R.id.widget_now_playing, themeColor)

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
            views.setInt(R.id.widget_shuffle, "setColorFilter", if (isShuffled) activeColor else inactiveColor)
            views.setInt(R.id.widget_repeat, "setColorFilter", if (repeatMode == 0) inactiveColor else activeColor)
            views.setInt(R.id.widget_favorite, "setColorFilter", if (isFavorite) activeColor else inactiveColor)

            views.setOnClickPendingIntent(R.id.widget_background, WidgetUtils.getOpenAppPendingIntent(context))
            views.setOnClickPendingIntent(R.id.widget_shuffle, WidgetUtils.createActionPendingIntent(context, "shuffle"))
            views.setOnClickPendingIntent(R.id.widget_previous, WidgetUtils.createActionPendingIntent(context, "previous"))
            views.setOnClickPendingIntent(R.id.widget_play_pause, WidgetUtils.createActionPendingIntent(context, "play_pause"))
            views.setOnClickPendingIntent(R.id.widget_next, WidgetUtils.createActionPendingIntent(context, "next"))
            views.setOnClickPendingIntent(R.id.widget_repeat, WidgetUtils.createActionPendingIntent(context, "repeat"))
            views.setOnClickPendingIntent(R.id.widget_favorite, WidgetUtils.createActionPendingIntent(context, "favorite"))

            val serviceIntent = Intent(context, MusicWidgetQueueService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                putExtra("queue_json", queueJson)
                putExtra("queue_start_position", queueStartPosition)
                putExtra("theme_color", themeColor)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_queue_list, serviceIntent)

            val templateIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = WidgetActionReceiver.ACTION_PLAY_INDEX
            }
            val templatePendingIntent = PendingIntent.getBroadcast(
                context,
                widgetId,
                templateIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutableFlag()
            )
            views.setPendingIntentTemplate(R.id.widget_queue_list, templatePendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_queue_list)
        }
    }

    private fun pendingIntentMutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_IMMUTABLE
        }
    }
}
