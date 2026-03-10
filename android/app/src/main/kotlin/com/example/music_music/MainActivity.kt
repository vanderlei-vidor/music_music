package com.example.music_music

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    private val CHANNEL = "music_music/android_scanner"
    private val WIDGET_ACTION_CHANNEL = "com.example.music_music/widget_actions"
    private val WIDGET_REFRESH_CHANNEL = "com.example.music_music/widget_refresh"
    private val WIDGET_PREFS = "music_widget_prefs"
    private val KEY_PENDING_ACTION = "pending_widget_action"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetActionReceiver.flutterEngine = flutterEngine

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanMusic" -> {
                    if (!hasPermission()) {
                        result.error(
                            "PERMISSION_DENIED",
                            "Permissão de áudio não concedida",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val musics = scanMusic()
                    result.success(musics)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_ACTION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingWidgetAction" -> {
                    val prefs = getSharedPreferences(WIDGET_PREFS, MODE_PRIVATE)
                    val action = prefs.getString(KEY_PENDING_ACTION, null)
                    prefs.edit().remove(KEY_PENDING_ACTION).apply()
                    result.success(action)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_REFRESH_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "refreshQueueList" -> {
                    val manager = AppWidgetManager.getInstance(applicationContext)
                    val component = ComponentName(applicationContext, MusicWidgetPlayer4x4::class.java)
                    val ids = manager.getAppWidgetIds(component)
                    if (ids.isNotEmpty()) {
                        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_queue_list)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        WidgetActionReceiver.flutterEngine = null
    }

    private fun hasPermission(): Boolean {
        val permission = if (android.os.Build.VERSION.SDK_INT >= 33) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

        return ContextCompat.checkSelfPermission(
            this,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun scanMusic(): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.DURATION
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        val cursor = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            null
        )

        cursor?.use {
            val idIndex = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleIndex = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistIndex = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val durationIndex = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

            while (it.moveToNext()) {
                val id = it.getLong(idIndex)
                val title = it.getString(titleIndex)
                val artist = it.getString(artistIndex)
                val duration = it.getLong(durationIndex)

                val uri: Uri = Uri.withAppendedPath(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id.toString()
                )

                results.add(
                    mapOf(
                        "id" to id,
                        "title" to title,
                        "artist" to artist,
                        "uri" to uri.toString(),
                        "duration" to duration
                    )
                )
            }
        }

        return results
    }
}
