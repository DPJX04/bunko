package com.dpjx04.light_novel_downloader

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.IOException

/**
 * Saves files into the phone's shared Download folder through MediaStore.
 * Needs no storage permission on Android 10 and newer, the app's minSdk.
 */
object DownloadStorage {
    /**
     * Copies [sourcePath] to Download/[folder]/[fileName] and returns the new
     * file's content URI. A copy this app saved before under the same name is
     * replaced, so downloading a volume again does not leave a "(1)" file.
     *
     * With [replaceUri], the earlier copy at that URI is written over in place
     * and keeps its name and URI. If it is gone or no longer this app's (after
     * a reinstall), a new file is saved as above.
     */
    fun save(
        context: Context,
        sourcePath: String,
        folder: String,
        fileName: String,
        mimeType: String,
        replaceUri: String?,
    ): String {
        val resolver = context.contentResolver
        if (replaceUri != null && overwrite(resolver, Uri.parse(replaceUri), File(sourcePath))) {
            return replaceUri
        }
        val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/$folder/"
        deleteOwnCopy(resolver, relativePath, fileName)
        val uri = resolver.insert(downloads(), pendingRow(relativePath, fileName, mimeType))
            ?: throw IOException("MediaStore refused to create $fileName")
        try {
            copyInto(resolver, uri, File(sourcePath))
            resolver.update(uri, pending(0), null, null)
        } catch (error: Exception) {
            // Remove the half written row so no broken file shows up in Download.
            resolver.delete(uri, null, null)
            throw error
        }
        return uri.toString()
    }

    /**
     * Writes [source] over the file at [uri], hidden from other apps while it
     * is written. Returns false, changing nothing, when the file is gone or
     * belongs to another install of the app. If the write itself fails, the
     * half written file is removed and the error is passed on.
     */
    private fun overwrite(resolver: ContentResolver, uri: Uri, source: File): Boolean {
        val rows = try {
            resolver.update(uri, pending(1), null, null)
        } catch (error: SecurityException) {
            return false
        } catch (error: IllegalArgumentException) {
            return false
        }
        if (rows == 0) return false
        try {
            copyInto(resolver, uri, source, mode = "wt")
            resolver.update(uri, pending(0), null, null)
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
        return true
    }

    /** Row values that hide a file from other apps (1) or show it again (0). */
    private fun pending(flag: Int) = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, flag) }

    /** The MediaStore table for the shared Download folder. */
    private fun downloads(): Uri = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

    /** Row values for a new file, hidden from other apps until the copy ends. */
    private fun pendingRow(relativePath: String, fileName: String, mimeType: String) = ContentValues().apply {
        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
        put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
        put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
        put(MediaStore.MediaColumns.IS_PENDING, 1)
    }

    /** Deletes an earlier copy this app saved. Files other apps own are left alone. */
    private fun deleteOwnCopy(resolver: ContentResolver, relativePath: String, fileName: String) {
        val where = "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        try {
            resolver.delete(downloads(), where, arrayOf(fileName, relativePath))
        } catch (error: SecurityException) {
            // Not this app's file, for example one saved before a reinstall.
            // MediaStore then names the new copy "name (1).epub".
        }
    }

    /** Streams the file's bytes into the MediaStore row; "wt" truncates what was there. */
    private fun copyInto(resolver: ContentResolver, uri: Uri, source: File, mode: String = "w") {
        val output = resolver.openOutputStream(uri, mode) ?: throw IOException("Cannot write $uri")
        output.use { out -> source.inputStream().use { input -> input.copyTo(out) } }
    }
}
