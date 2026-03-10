package com.example.music_music

import android.content.Context
import android.content.Intent
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
    private var queueStartPosition: Int = 1
    private var themeColor: Int = 0xFFFFE0A3.toInt()

    override fun onCreate() {
        loadFromIntent()
    }

    override fun onDataSetChanged() {
        loadFromIntent()
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_player_4x4_list_item)
        val absoluteIndex = queueStartPosition + position
        val title = items.getOrNull(position) ?: "-"
        views.setTextViewText(R.id.widget_queue_item_text, "$absoluteIndex. $title")

        val color = if (position == 0) themeColor else 0xE6FFFFFF.toInt()
        views.setTextColor(R.id.widget_queue_item_text, color)

        val fillInIntent = Intent().apply {
            action = WidgetActionReceiver.ACTION_PLAY_INDEX
            putExtra("queue_index_one_based", absoluteIndex)
        }
        views.setOnClickFillInIntent(R.id.widget_queue_item_root, fillInIntent)
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun loadFromIntent() {
        val queueJson = intent.getStringExtra("queue_json") ?: "[]"
        queueStartPosition = intent.getIntExtra("queue_start_position", 1)
        themeColor = intent.getIntExtra("theme_color", 0xFFFFE0A3.toInt())

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
    }
}
