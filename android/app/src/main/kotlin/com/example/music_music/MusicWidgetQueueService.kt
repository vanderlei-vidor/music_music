package com.example.music_music

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

class MusicWidgetQueueService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return QueueViewsFactory(applicationContext, intent)
    }
}

private class QueueViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {
    private var items: List<String> = emptyList()
    private var currentPosition: Int = 1
    private var themeColor: Int = 0xFFFFE0A3.toInt()
    private var pendingIndex: Int = -1
    private var isPlaceholder = false

    override fun onCreate() {
        loadFromPrefs()
    }

    override fun onDataSetChanged() {
        loadFromPrefs()
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_player_4x4_list_item)
        val absoluteIndex = position + 1
        val title = items.getOrNull(position) ?: "-"
        val displayText = if (isPlaceholder) {
            title
        } else if (absoluteIndex == pendingIndex && absoluteIndex != currentPosition) {
            "$absoluteIndex. $title (Carregando...)"
        } else {
            "$absoluteIndex. $title"
        }
        views.setTextViewText(R.id.widget_queue_item_text, displayText)

        val isCurrent = !isPlaceholder && absoluteIndex == currentPosition
        val isPending = absoluteIndex == pendingIndex && !isCurrent

        val textColor = when {
            isCurrent -> themeColor
            isPending -> 0xFFFFD180.toInt()
            else -> 0xE6FFFFFF.toInt()
        }
        views.setTextColor(R.id.widget_queue_item_text, textColor)

        if (isCurrent) {
            views.setViewVisibility(R.id.widget_queue_item_indicator, View.VISIBLE)
            val icon = R.drawable.ic_music_note
            views.setImageViewResource(R.id.widget_queue_item_indicator, icon)
            views.setInt(R.id.widget_queue_item_indicator, "setColorFilter", themeColor)
        } else {
            views.setViewVisibility(R.id.widget_queue_item_indicator, View.GONE)
        }

        val fillInIntent = Intent().apply {
            action = WidgetActionReceiver.ACTION_PLAY_INDEX
            if (isPlaceholder) {
                putExtra("open_app", true)
            } else {
                putExtra("queue_index_one_based", absoluteIndex)
            }
        }
        views.setOnClickFillInIntent(R.id.widget_queue_item_root, fillInIntent)
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun loadFromPrefs() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val queueJson = prefs.getString("player_queue_all_json", "[]") ?: "[]"
        currentPosition = WidgetUtils.getIntCompat(prefs, "player_current_position", 1)
        themeColor = WidgetUtils.getIntCompat(prefs, "player_theme_color", 0xFFFFE0A3.toInt())
        pendingIndex = WidgetUtils.getIntCompat(prefs, "player_pending_index", -1)

        items = try {
            val arr = JSONArray(queueJson)
            buildList(arr.length()) {
                for (idx in 0 until arr.length()) {
                    add(arr.optString(idx, "-"))
                }
            }
        } catch (_: Throwable) {
            emptyList()
        }
        isPlaceholder = items.isEmpty()
        if (isPlaceholder) {
            items = listOf("Fila vazia - abrir app")
            pendingIndex = -1
        }
    }
}
