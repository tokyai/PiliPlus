package com.example.piliplus

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class GoProxyForegroundService : Service() {
    companion object {
        private const val ACTION_START = "com.example.piliplus.action.GOPROXY_FG_START"
        private const val ACTION_STOP = "com.example.piliplus.action.GOPROXY_FG_STOP"
        private const val EXTRA_PROXY_URL = "proxy_url"
        private const val EXTRA_COMMAND_LINE = "command_line"
        private const val CHANNEL_ID = "peekpili_goproxy_runtime"
        private const val CHANNEL_NAME = "GoProxy Runtime"
        private const val NOTIFICATION_ID = 30111

        @Volatile
        private var running: Boolean = false

        fun buildStartIntent(
            context: Context,
            proxyUrl: String,
            commandLine: String
        ): Intent = Intent(context, GoProxyForegroundService::class.java).apply {
            action = ACTION_START
            putExtra(EXTRA_PROXY_URL, proxyUrl)
            putExtra(EXTRA_COMMAND_LINE, commandLine)
        }

        fun buildStopIntent(context: Context): Intent =
            Intent(context, GoProxyForegroundService::class.java).apply {
                action = ACTION_STOP
            }

        fun isRunning(): Boolean = running
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForegroundCompat()
            stopSelf()
            running = false
            return START_NOT_STICKY
        }

        val proxyUrl = intent?.getStringExtra(EXTRA_PROXY_URL).orEmpty()
        val commandLine = intent?.getStringExtra(EXTRA_COMMAND_LINE).orEmpty()
        createNotificationChannel()
        startForeground(
            NOTIFICATION_ID,
            buildNotification(proxyUrl, commandLine)
        )
        running = true
        return START_STICKY
    }

    override fun onDestroy() {
        running = false
        stopForegroundCompat()
        super.onDestroy()
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun buildNotification(proxyUrl: String, commandLine: String) =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("GoProxy running")
            .setContentText(
                if (proxyUrl.isNotEmpty()) {
                    "Proxy: $proxyUrl"
                } else {
                    "Proxy process active"
                }
            )
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    if (commandLine.isNotEmpty()) {
                        "Command: $commandLine"
                    } else {
                        "GoProxy process active"
                    }
                )
            )
            .setContentIntent(buildOpenAppPendingIntent())
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                buildStopPendingIntent()
            )
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

    private fun buildOpenAppPendingIntent(): PendingIntent {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
        launchIntent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        return PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun buildStopPendingIntent(): PendingIntent =
        PendingIntent.getService(
            this,
            1,
            buildStopIntent(this),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = NotificationManagerCompat.from(this)
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Keeps GoProxy runtime visible while process is active."
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }
}
