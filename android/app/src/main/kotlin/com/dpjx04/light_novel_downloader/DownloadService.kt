package com.dpjx04.light_novel_downloader

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/**
 * Keeps the app alive while the download queue runs and the app is in the
 * background: a dataSync foreground service with a progress notification and
 * a partial wake lock, so the rate-limited requests keep their timers with the
 * screen off. The queue itself runs in Dart; this service only holds the
 * process up. Tapping the notification opens the Downloads tab.
 *
 * Driven from lib/services/background_service.dart through MainActivity.
 */
class DownloadService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        val power = getSystemService(PowerManager::class.java)
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG).apply {
            setReferenceCounted(false)
            acquire(WAKE_LOCK_LIMIT_MS)
        }
    }

    /**
     * Enters the foreground on every command, as Android requires soon after
     * startForegroundService, then stops if the command says so. Handling the
     * stop here, in order, means a quick start and stop can never crash.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, notification(this, notice), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            // Stops only if no newer start is waiting behind this command.
            stopSelf(startId)
        }
        return START_NOT_STICKY
    }

    /** Android 15 gives dataSync services 6 hours a day; let go cleanly when that runs out. */
    override fun onTimeout(startId: Int, fgsType: Int) {
        stopSelf()
    }

    /**
     * Also runs when Android or the phone maker stops the service on its own,
     * so the next update knows to start it again.
     */
    override fun onDestroy() {
        isRunning = false
        wakeLock?.release()
        super.onDestroy()
    }

    /** What the notification shows, as sent by lib/services/background_service.dart. */
    data class Notice(val title: String, val text: String, val book: String, val percent: Int)

    companion object {
        /** Intent extra MainActivity reads to open the Downloads tab. */
        const val EXTRA_OPEN = "open"
        const val OPEN_DOWNLOADS = "downloads"

        private const val CHANNEL_ID = "downloads"
        private const val NOTIFICATION_ID = 7
        private const val ACTION_STOP = "com.dpjx04.light_novel_downloader.STOP_DOWNLOADS"
        private const val WAKE_LOCK_TAG = "LightNovel:downloads"

        /** A safety limit: the wake lock lets go after 6 hours even if never released. */
        private const val WAKE_LOCK_LIMIT_MS = 6 * 60 * 60 * 1000L

        /** The notice on show now; the service rebuilds its notification from it. */
        private var notice = Notice("", "", "", 0)

        /** True from start until the service stops, by stop or by the system. */
        private var isRunning = false

        /** Starts the service with its first notice. Only works while the app is on screen. */
        fun start(context: Context, first: Notice) {
            notice = first
            isRunning = true
            createChannel(context)
            context.startForegroundService(Intent(context, DownloadService::class.java))
        }

        /**
         * Replaces the running service's notification with [next]. If the
         * system stopped the service while downloads still run, starts it
         * again; Android refuses that while the app is in the background, so
         * it succeeds at the first update after the app is back on screen.
         */
        fun update(context: Context, next: Notice) {
            notice = next
            if (!isRunning) {
                restart(context)
                return
            }
            context.getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, notification(context, next))
        }

        /** Starts the service again after the system stopped it, when Android allows it. */
        private fun restart(context: Context) {
            try {
                start(context, notice)
            } catch (error: IllegalStateException) {
                // ForegroundServiceStartNotAllowedException: the app is in the
                // background. The next update tries again.
                isRunning = false
            }
        }

        /** Stops the service and removes its notification, if it runs. */
        fun stop(context: Context) {
            if (!isRunning) return
            isRunning = false
            // Sent as a command, not stopService, so it arrives after the start.
            // The running foreground service lets the app send it from the background.
            context.startService(Intent(context, DownloadService::class.java).setAction(ACTION_STOP))
        }

        /** The "Downloads" channel: quiet, since progress updates every few seconds. */
        private fun createChannel(context: Context) {
            val channel = NotificationChannel(CHANNEL_ID, "Downloads", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Progress of volumes downloading in the background"
                setShowBadge(false)
            }
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        /** "Downloading 第2卷", "42% · 2 more waiting", the book, a progress bar; a tap opens Downloads. */
        private fun notification(context: Context, notice: Notice): Notification {
            val open = Intent(context, MainActivity::class.java)
                .putExtra(EXTRA_OPEN, OPEN_DOWNLOADS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            val tap = PendingIntent.getActivity(
                context,
                0,
                open,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val builder = Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle(notice.title)
                .setContentText(notice.text)
                .setSubText(notice.book)
                .setProgress(100, notice.percent, false)
                .setContentIntent(tap)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setCategory(Notification.CATEGORY_PROGRESS)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Show it at once instead of after Android 12's 10 second grace.
                builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            }
            return builder.build()
        }
    }
}
