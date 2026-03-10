package com.example.music_music

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.KeyEvent
import androidx.core.content.ContextCompat

object WidgetUtils {
    fun getOpenAppPendingIntent(context: Context): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(Intent.ACTION_MAIN).apply {
                setPackage(context.packageName)
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun createActionPendingIntent(context: Context, action: String): PendingIntent {
        val broadcastAction = when (action) {
            "play_pause" -> WidgetActionReceiver.ACTION_PLAY_PAUSE
            "next" -> WidgetActionReceiver.ACTION_NEXT
            "previous" -> WidgetActionReceiver.ACTION_PREVIOUS
            "shuffle" -> WidgetActionReceiver.ACTION_SHUFFLE
            "repeat" -> WidgetActionReceiver.ACTION_REPEAT
            "favorite" -> WidgetActionReceiver.ACTION_FAVORITE
            else -> return getOpenAppPendingIntent(context)
        }

        val intent = Intent(context, WidgetActionReceiver::class.java)
        intent.action = broadcastAction
        intent.data = Uri.parse("widget://action/$action")
        return PendingIntent.getBroadcast(
            context,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun createQueueItemPendingIntent(context: Context, oneBasedIndex: Int): PendingIntent {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = WidgetActionReceiver.ACTION_PLAY_INDEX
            putExtra("queue_index_one_based", oneBasedIndex)
            data = Uri.parse("widget://queue/$oneBasedIndex")
        }
        return PendingIntent.getBroadcast(
            context,
            100000 + oneBasedIndex,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun createMediaButtonPendingIntent(context: Context, keyCode: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClassName(
                context.packageName,
                "com.ryanheise.audioservice.MediaButtonReceiver"
            )
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
            data = Uri.parse("widget://media/$keyCode")
        }
        return PendingIntent.getBroadcast(
            context,
            keyCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun dispatchMediaButtonAction(context: Context, keyCode: Int) {
        val serviceIntent = Intent().apply {
            setClassName(context.packageName, "com.ryanheise.audioservice.AudioService")
        }
        runCatching {
            ContextCompat.startForegroundService(context, serviceIntent)
        }

        val downIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClassName(context.packageName, "com.ryanheise.audioservice.MediaButtonReceiver")
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
            `package` = context.packageName
        }
        val upIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClassName(context.packageName, "com.ryanheise.audioservice.MediaButtonReceiver")
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, keyCode))
            `package` = context.packageName
        }
        context.sendBroadcast(downIntent)
        context.sendBroadcast(upIntent)
    }

    fun getIntCompat(prefs: SharedPreferences, key: String, defaultValue: Int): Int {
        val value = prefs.all[key] ?: return defaultValue
        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is Float -> value.toInt()
            is Double -> value.toInt()
            is String -> value.toIntOrNull() ?: defaultValue
            else -> defaultValue
        }
    }
}
