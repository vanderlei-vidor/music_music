package com.example.music_music

import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat

object WidgetMediaController {
    private const val TAG = "WidgetMediaController"
    private const val TIMEOUT_MS = 3500L

    fun sendCustomAction(
        context: Context,
        action: String,
        extras: Bundle? = null,
        onComplete: (Boolean) -> Unit
    ) {
        val appContext = context.applicationContext
        val component = ComponentName(
            appContext,
            "com.ryanheise.audioservice.AudioService"
        )
        val handler = Handler(Looper.getMainLooper())
        var finished = false

        lateinit var mediaBrowser: MediaBrowserCompat
        mediaBrowser = MediaBrowserCompat(
            appContext,
            component,
            object : MediaBrowserCompat.ConnectionCallback() {
                override fun onConnected() {
                    if (finished) return
                    try {
                        val controller = MediaControllerCompat(
                            appContext,
                            mediaBrowser.sessionToken
                        )
                        controller.transportControls.sendCustomAction(action, extras)
                        finished = true
                        safeDisconnect(mediaBrowser)
                        onComplete(true)
                    } catch (e: Throwable) {
                        Log.e(TAG, "Falha ao enviar customAction=$action", e)
                        finished = true
                        safeDisconnect(mediaBrowser)
                        onComplete(false)
                    }
                }

                override fun onConnectionFailed() {
                    if (finished) return
                    Log.w(TAG, "Conexao com AudioService falhou")
                    finished = true
                    safeDisconnect(mediaBrowser)
                    onComplete(false)
                }

                override fun onConnectionSuspended() {
                    if (finished) return
                    Log.w(TAG, "Conexao com AudioService suspensa")
                    finished = true
                    safeDisconnect(mediaBrowser)
                    onComplete(false)
                }
            },
            null
        )

        mediaBrowser.connect()

        handler.postDelayed({
            if (finished) return@postDelayed
            finished = true
            safeDisconnect(mediaBrowser)
            onComplete(false)
        }, TIMEOUT_MS)
    }

    private fun safeDisconnect(browser: MediaBrowserCompat) {
        if (browser.isConnected) {
            browser.disconnect()
        }
    }
}
