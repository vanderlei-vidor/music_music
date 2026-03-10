package com.example.music_music

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class WidgetActionReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "WidgetActionReceiver"
        const val ACTION_PLAY_PAUSE = "com.example.music_music.PLAY_PAUSE"
        const val ACTION_NEXT = "com.example.music_music.NEXT"
        const val ACTION_PREVIOUS = "com.example.music_music.PREVIOUS"
        const val ACTION_SHUFFLE = "com.example.music_music.SHUFFLE"
        const val ACTION_REPEAT = "com.example.music_music.REPEAT"
        const val ACTION_FAVORITE = "com.example.music_music.FAVORITE"
        const val ACTION_PLAY_INDEX = "com.example.music_music.PLAY_INDEX"
        private const val PREFS_NAME = "music_widget_prefs"
        private const val KEY_PENDING_ACTION = "pending_widget_action"

        var flutterEngine: FlutterEngine? = null
        private var headlessEngine: FlutterEngine? = null
        private val mainHandler = Handler(Looper.getMainLooper())
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Widget action received: $action")

        if (action == ACTION_PLAY_INDEX && intent.getBooleanExtra("open_app", false)) {
            WidgetUtils.clearPendingQueueIndex(context)
            WidgetUtils.refreshQueueList(context, MusicWidgetPlayer4x4::class.java)
            WidgetUtils.openAppNow(context)
            return
        }

        val widgetAction = when (action) {
            ACTION_PLAY_PAUSE -> "play_pause"
            ACTION_NEXT -> "next"
            ACTION_PREVIOUS -> "previous"
            ACTION_SHUFFLE -> "shuffle"
            ACTION_REPEAT -> "repeat"
            ACTION_FAVORITE -> "favorite"
            ACTION_PLAY_INDEX -> {
                val index = intent.getIntExtra("queue_index_one_based", -1)
                if (index > 0) {
                    WidgetUtils.setPendingQueueIndex(context, index)
                    WidgetUtils.refreshQueueList(context, MusicWidgetPlayer4x4::class.java)
                    "play_index:$index"
                } else {
                    Log.w(TAG, "PLAY_INDEX sem indice valido")
                    null
                }
            }
            else -> null
        } ?: return

        val activeEngine = flutterEngine
        if (activeEngine != null) {
            dispatchToFlutter(activeEngine, widgetAction, delayMs = 0L)
            return
        }

        val isCustomAction = when (action) {
            ACTION_SHUFFLE, ACTION_REPEAT, ACTION_FAVORITE, ACTION_PLAY_INDEX -> true
            else -> false
        }
        if (isCustomAction) {
            val pendingResult = goAsync()
            val customAction = when (action) {
                ACTION_SHUFFLE -> "toggle_shuffle"
                ACTION_REPEAT -> "toggle_repeat"
                ACTION_FAVORITE -> "toggle_favorite"
                ACTION_PLAY_INDEX -> "play_index"
                else -> "toggle_shuffle"
            }
            val extras = android.os.Bundle()
            if (action == ACTION_PLAY_INDEX) {
                val index = intent.getIntExtra("queue_index_one_based", -1)
                if (index > 0) {
                    extras.putInt("index", index)
                }
            }

            WidgetMediaController.sendCustomAction(context, customAction, extras) { success ->
                if (success) {
                    Log.d(TAG, "Custom action enviada ao AudioService: $customAction")
                    pendingResult.finish()
                    return@sendCustomAction
                }

                val engine = headlessEngine ?: createHeadlessEngine(context)
                if (engine != null) {
                    dispatchToFlutter(engine, widgetAction, delayMs = 1400L)
                    Log.d(TAG, "Fallback headless para action: $widgetAction")
                    pendingResult.finish()
                    return@sendCustomAction
                }

                val prefs: SharedPreferences =
                    context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putString(KEY_PENDING_ACTION, widgetAction).apply()
                Log.d(TAG, "Fallback pendente salvo: $widgetAction")
                pendingResult.finish()
            }
            return
        }

        val mediaKeyCode = when (action) {
            ACTION_PLAY_PAUSE -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            ACTION_NEXT -> KeyEvent.KEYCODE_MEDIA_NEXT
            ACTION_PREVIOUS -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            else -> null
        }
        if (mediaKeyCode != null) {
            WidgetUtils.dispatchMediaButtonAction(context, mediaKeyCode)
            Log.d(TAG, "Media action enviada em background: $widgetAction")
            return
        }

        val engine = headlessEngine ?: createHeadlessEngine(context)
        if (engine != null) {
            dispatchToFlutter(engine, widgetAction, delayMs = 1400L)
            Log.d(TAG, "Acao enviada para headless engine: $widgetAction")
            return
        }

        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_PENDING_ACTION, widgetAction).apply()
        Log.d(TAG, "Headless indisponivel; acao pendente salva: $widgetAction")
    }

    private fun createHeadlessEngine(context: Context): FlutterEngine? {
        return try {
            val engine = FlutterEngine(context.applicationContext)
            GeneratedPluginRegistrant.registerWith(engine)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            headlessEngine = engine
            engine
        } catch (e: Throwable) {
            Log.e(TAG, "Falha ao iniciar headless engine", e)
            null
        }
    }

    private fun dispatchToFlutter(engine: FlutterEngine, widgetAction: String, delayMs: Long) {
        mainHandler.postDelayed({
            runCatching {
                MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    "com.example.music_music/widget_actions"
                ).invokeMethod("onWidgetAction", widgetAction)
            }.onFailure {
                Log.e(TAG, "Falha ao enviar acao para Flutter: $widgetAction", it)
            }
        }, delayMs)
    }
}
