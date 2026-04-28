package com.example.piliplus

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class GoProxyForegroundService : Service() {
    companion object {
        private const val ACTION_START = "com.example.piliplus.action.GOPROXY_FG_START"
        private const val ACTION_STOP = "com.example.piliplus.action.GOPROXY_FG_STOP"
        private const val EXTRA_PROXY_URL = "proxy_url"
        private const val EXTRA_COMMAND_LINE = "command_line"
        private const val EXTRA_PROCESS_PID = "process_pid"
        private const val CHANNEL_ID = "peekpili_goproxy_runtime"
        private const val CHANNEL_NAME = "GoProxy Runtime"
        private const val NOTIFICATION_ID = 30111

        @Volatile
        private var running: Boolean = false
        @Volatile
        private var wakeLockHeld: Boolean = false
        @Volatile
        private var wifiLockHeld: Boolean = false
        @Volatile
        private var processPid: Int = -1

        fun buildStartIntent(
            context: Context,
            proxyUrl: String,
            commandLine: String,
            processPid: Int
        ): Intent = Intent(context, GoProxyForegroundService::class.java).apply {
            action = ACTION_START
            putExtra(EXTRA_PROXY_URL, proxyUrl)
            putExtra(EXTRA_COMMAND_LINE, commandLine)
            putExtra(EXTRA_PROCESS_PID, processPid)
        }

        fun buildStopIntent(context: Context): Intent =
            Intent(context, GoProxyForegroundService::class.java).apply {
                action = ACTION_STOP
            }

        fun isRunning(): Boolean = running
        fun isWakeLockHeld(): Boolean = wakeLockHeld
        fun isWifiLockHeld(): Boolean = wifiLockHeld
        fun getTrackedProcessPid(): Int = processPid
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopTrackedProcess()
            releaseRuntimeLocks()
            stopForegroundCompat()
            stopSelf()
            running = false
            return START_NOT_STICKY
        }

        val proxyUrl = intent?.getStringExtra(EXTRA_PROXY_URL).orEmpty()
        val commandLine = intent?.getStringExtra(EXTRA_COMMAND_LINE).orEmpty()
        processPid = intent?.getIntExtra(EXTRA_PROCESS_PID, -1) ?: -1
        createNotificationChannel()
        startForeground(
            NOTIFICATION_ID,
            buildNotification(proxyUrl, commandLine)
        )
        acquireRuntimeLocks()
        running = true
        return START_STICKY
    }

    override fun onDestroy() {
        processPid = -1
        releaseRuntimeLocks()
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

    private fun acquireRuntimeLocks() {
        acquireWakeLock()
        acquireWifiLock()
    }

    private fun releaseRuntimeLocks() {
        releaseWakeLock()
        releaseWifiLock()
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) {
            wakeLockHeld = true
            return
        }
        val manager = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return
        runCatching {
            val lock = manager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "peekpili:goproxy_wake_lock"
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
            wakeLock = lock
            wakeLockHeld = lock.isHeld
        }.onFailure {
            wakeLockHeld = false
        }
    }

    private fun releaseWakeLock() {
        runCatching {
            wakeLock?.takeIf { it.isHeld }?.release()
        }
        wakeLock = null
        wakeLockHeld = false
    }

    private fun acquireWifiLock() {
        if (wifiLock?.isHeld == true) {
            wifiLockHeld = true
            return
        }
        val manager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: return
        runCatching {
            val lockMode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                WifiManager.WIFI_MODE_FULL_LOW_LATENCY
            } else {
                @Suppress("DEPRECATION")
                WifiManager.WIFI_MODE_FULL_HIGH_PERF
            }
            val lock = manager.createWifiLock(lockMode, "peekpili:goproxy_wifi_lock").apply {
                setReferenceCounted(false)
                acquire()
            }
            wifiLock = lock
            wifiLockHeld = lock.isHeld
        }.onFailure {
            wifiLockHeld = false
        }
    }

    private fun releaseWifiLock() {
        runCatching {
            wifiLock?.takeIf { it.isHeld }?.release()
        }
        wifiLock = null
        wifiLockHeld = false
    }

    private fun stopTrackedProcess() {
        val pid = processPid
        if (pid <= 0) return
        runCatching {
            Runtime.getRuntime().exec(arrayOf("sh", "-c", "kill -TERM $pid"))
        }
        processPid = -1
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
