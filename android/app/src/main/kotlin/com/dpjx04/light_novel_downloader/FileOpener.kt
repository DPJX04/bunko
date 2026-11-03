package com.dpjx04.light_novel_downloader

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import java.io.FileNotFoundException

/**
 * Opens a saved EPUB in a reader app through Android's "Open with" list,
 * every time, so the user picks which app to import it into. Driven from
 * lib/services/file_opener.dart through MainActivity.
 */
object FileOpener {
    private const val EPUB = "application/epub+zip"

    /**
     * Opens the EPUB at [uri], a MediaStore content URI this app saved, and
     * lets the reader read it. Throws [FileNotFoundException] when the file is
     * gone, and android.content.ActivityNotFoundException when no app reads
     * EPUB.
     */
    fun openEpub(activity: Activity, uri: Uri) {
        if (!exists(activity.contentResolver, uri)) throw FileNotFoundException(uri.toString())
        val view = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, EPUB)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        // The chooser shows "No apps can perform this action" rather than
        // failing, so check first to keep the plain sentence. The <queries>
        // entry in the manifest lets this see the reader apps.
        if (view.resolveActivity(activity.packageManager) == null) throw ActivityNotFoundException(EPUB)
        // createChooser carries the read permission over to the app picked.
        activity.startActivity(Intent.createChooser(view, "Open with"))
    }

    /**
     * True when the file is still there and this install may read it. The
     * name column is one both MediaStore and a picked folder answer.
     */
    private fun exists(resolver: ContentResolver, uri: Uri): Boolean {
        return try {
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { it.moveToFirst() } ?: false
        } catch (error: SecurityException) {
            false
        } catch (error: IllegalArgumentException) {
            false
        }
    }
}
