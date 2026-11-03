package com.dpjx04.light_novel_downloader

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.net.Uri
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
import java.util.concurrent.Executors

/**
 * Hosts Flutter and answers the app's native channels: saving to Download,
 * opening a saved EPUB in a reader, and the background service that keeps
 * downloads running.
 */
class MainActivity : FlutterActivity() {
    private val background = Executors.newSingleThreadExecutor()
    private val mainThread = Handler(Looper.getMainLooper())
    private var backgroundChannel: MethodChannel? = null

    /** The Dart call waiting for the folder picker to close, if any. */
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result -> handleStorage(call, result) }
        MethodChannel(messenger, OPENER_CHANNEL)
            .setMethodCallHandler { call, result -> handleOpen(call, result) }
        backgroundChannel = MethodChannel(messenger, BACKGROUND_CHANNEL).apply {
            setMethodCallHandler { call, result -> handleBackground(call, result) }
        }
    }

    /** Opens the Downloads tab when the download notification brings the app back. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getStringExtra(DownloadService.EXTRA_OPEN) == DownloadService.OPEN_DOWNLOADS) {
            backgroundChannel?.invokeMethod("openDownloads", null)
        }
    }

    /** The queue runs in this activity's Flutter engine and ends with it, so its notification goes too. */
    override fun onDestroy() {
        DownloadService.stop(applicationContext)
        super.onDestroy()
    }

    /**
     * Answers the library folder calls. Saving and listing run on a background
     * thread, so copying a large EPUB or reading every volume in a folder
     * never freezes the screen.
     */
    private fun handleStorage(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveToDownloads" -> save(call, result)
            "saveToFolder" -> inBackground(result, "save_failed") {
                LibraryFolder.save(
                    context = applicationContext,
                    treeUri = call.argument<String>("folderUri")!!,
                    sourcePath = call.argument<String>("sourcePath")!!,
                    fileName = call.argument<String>("fileName")!!,
                    mimeType = call.argument<String>("mimeType")!!,
                )
            }
            "listLibrary" -> inBackground(result, "list_failed") {
                LibraryFolder.list(
                    context = applicationContext,
                    treeUri = call.argument<String>("folderUri"),
                    folder = call.argument<String>("folder")!!,
                    known = call.argument<List<String>>("known")!!.toSet(),
                )
            }
            "pickLibraryFolder" -> pickFolder(call, result)
            else -> result.notImplemented()
        }
    }

    /** Runs [work] on the background thread and answers with its result, or [code] if it throws. */
    private fun inBackground(result: MethodChannel.Result, code: String, work: () -> Any?) {
        background.execute {
            try {
                val answer = work()
                mainThread.post { result.success(answer) }
            } catch (error: Exception) {
                mainThread.post { result.error(code, error.message, null) }
            }
        }
    }

    /** Opens Android's folder picker; the answer comes in [onActivityResult]. */
    private fun pickFolder(call: MethodCall, result: MethodChannel.Result) {
        pendingPick?.success(null)
        pendingPick = result
        startActivityForResult(LibraryFolder.pickIntent(call.argument<String>("folder")!!), PICK_FOLDER)
    }

    /**
     * Keeps the right to the picked folder across restarts and answers the
     * waiting Dart call with its tree URI, or null when the picker was closed.
     */
    @Deprecated("FlutterActivity has no Activity Result API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_FOLDER) return
        val folder = if (resultCode == RESULT_OK) data?.data else null
        if (folder != null) {
            contentResolver.takePersistableUriPermission(
                folder,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        }
        pendingPick?.success(folder?.toString())
        pendingPick = null
    }

    /** Copies a finished EPUB into Download/LightNovel. */
    private fun save(call: MethodCall, result: MethodChannel.Result) {
        background.execute {
            try {
                val uri = DownloadStorage.save(
                    context = applicationContext,
                    sourcePath = call.argument<String>("sourcePath")!!,
                    folder = call.argument<String>("folder")!!,
                    fileName = call.argument<String>("fileName")!!,
                    mimeType = call.argument<String>("mimeType")!!,
                    replaceUri = call.argument<String>("replaceUri"),
                )
                mainThread.post { result.success(uri) }
            } catch (error: Exception) {
                mainThread.post { result.error("save_failed", error.message, null) }
            }
        }
    }

    /**
     * Opens a saved EPUB in a reader app. The error codes, 'missing' and
     * 'no_reader', become sentences in lib/utils/error_messages.dart.
     */
    private fun handleOpen(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "openEpub") return result.notImplemented()
        try {
            FileOpener.openEpub(this, Uri.parse(call.argument<String>("uri")!!))
            result.success(null)
        } catch (error: FileNotFoundException) {
            result.error("missing", error.message, null)
        } catch (error: ActivityNotFoundException) {
            result.error("no_reader", error.message, null)
        }
    }

    /** Starts, updates and stops the background service, and asks for the notification permission. */
    private fun handleBackground(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "requestNotificationPermission" -> requestNotificationPermission()
                "start" -> DownloadService.start(applicationContext, notice(call))
                "update" -> DownloadService.update(applicationContext, notice(call))
                "stop" -> DownloadService.stop(applicationContext)
                else -> return result.notImplemented()
            }
            result.success(null)
        } catch (error: Exception) {
            result.error("background_failed", error.message, null)
        }
    }

    /** Shows Android 13's notification permission prompt, without waiting for the answer. */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val permission = Manifest.permission.POST_NOTIFICATIONS
        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) return
        requestPermissions(arrayOf(permission), NOTIFICATION_REQUEST)
    }

    /** Reads a notice sent by lib/services/background_service.dart. */
    private fun notice(call: MethodCall) = DownloadService.Notice(
        title = call.argument<String>("title")!!,
        text = call.argument<String>("text")!!,
        book = call.argument<String>("book")!!,
        percent = call.argument<Int>("percent")!!,
    )

    companion object {
        /** Must match the channel name in lib/services/download_storage.dart. */
        private const val STORAGE_CHANNEL = "light_novel_downloader/download_storage"

        /** Marks the folder picker's answer in onActivityResult. */
        private const val PICK_FOLDER = 41

        /** Must match the channel name in lib/services/file_opener.dart. */
        private const val OPENER_CHANNEL = "light_novel_downloader/file_opener"

        /** Must match the channel name in lib/services/background_service.dart. */
        private const val BACKGROUND_CHANNEL = "light_novel_downloader/background"

        private const val NOTIFICATION_REQUEST = 1
    }
}
