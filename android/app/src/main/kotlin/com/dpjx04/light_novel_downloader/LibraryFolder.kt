package com.dpjx04.light_novel_downloader

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.MediaStore
import java.io.File
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import java.util.zip.Inflater

/**
 * The library folder: lists the EPUBs in it, reads what each one is, and
 * saves into a folder the owner picked. The default folder,
 * Download/LightNovel, is listed through MediaStore, which shows this install
 * only the files it saved. A picked folder is a Storage Access Framework tree,
 * where every file shows, so picking Download/LightNovel brings back volumes
 * saved before a reinstall. Driven from lib/services/download_storage.dart
 * through MainActivity.
 */
object LibraryFolder {
    /** The folder picker, opening at Download/[folder]. */
    fun pickIntent(folder: String): Intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).putExtra(
        DocumentsContract.EXTRA_INITIAL_URI,
        DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:${Environment.DIRECTORY_DOWNLOADS}/$folder",
        ),
    )

    /**
     * Lists the EPUBs in the folder at [treeUri], or in Download/[folder] when
     * null, as maps of uri, name and modified (milliseconds). Each file whose
     * URI is not in [known] also carries opf, the text of its package file, or
     * null when it cannot be read. Throws when the folder cannot be listed.
     */
    fun list(context: Context, treeUri: String?, folder: String, known: Set<String>): List<Map<String, Any?>> {
        val resolver = context.contentResolver
        val files = if (treeUri == null) listDownloads(resolver, folder) else listTree(resolver, Uri.parse(treeUri))
        return files.map { file ->
            mapOf(
                "uri" to file.uri,
                "name" to file.name,
                "modified" to file.modified,
                "opf" to if (file.uri in known) null else readOpf(resolver, Uri.parse(file.uri)),
            )
        }
    }

    /**
     * Copies [sourcePath] into the folder at [treeUri] as [fileName] and
     * returns its document URI. A file of the same name there is written over,
     * so downloading a volume again keeps one copy.
     */
    fun save(context: Context, treeUri: String, sourcePath: String, fileName: String, mimeType: String): String {
        val resolver = context.contentResolver
        val tree = Uri.parse(treeUri)
        val existing = listTree(resolver, tree).firstOrNull { it.name == fileName }?.let { Uri.parse(it.uri) }
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val target = existing
            ?: DocumentsContract.createDocument(resolver, parent, mimeType, fileName)
            ?: throw IOException("Cannot create $fileName")
        try {
            val output = resolver.openOutputStream(target, "wt") ?: throw IOException("Cannot write $target")
            output.use { out -> File(sourcePath).inputStream().use { it.copyTo(out) } }
        } catch (error: Exception) {
            // Remove a half written new file; an old one keeps what is left.
            if (existing == null) DocumentsContract.deleteDocument(resolver, target)
            throw error
        }
        return target.toString()
    }

    /** One EPUB found in the folder; modified is in milliseconds. */
    private data class Found(val uri: String, val name: String, val modified: Long)

    /** The EPUBs this install saved in Download/[folder], through MediaStore. */
    private fun listDownloads(resolver: ContentResolver, folder: String): List<Found> {
        val downloads = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val columns = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATE_MODIFIED,
        )
        val where = "${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        val home = arrayOf("${Environment.DIRECTORY_DOWNLOADS}/$folder/")
        val rows = resolver.query(downloads, columns, where, home, null) ?: throw IOException("MediaStore gave no answer")
        return rows.use { row ->
            buildList {
                while (row.moveToNext()) {
                    val name = row.getString(1) ?: continue
                    if (!name.endsWith(".epub", ignoreCase = true)) continue
                    val uri = ContentUris.withAppendedId(downloads, row.getLong(0)).toString()
                    add(Found(uri, name, row.getLong(2) * 1000))
                }
            }
        }
    }

    /** The EPUBs directly inside the picked folder [tree]. */
    private fun listTree(resolver: ContentResolver, tree: Uri): List<Found> {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        val rows = resolver.query(children, columns, null, null, null) ?: throw IOException("The folder gave no answer")
        return rows.use { row ->
            buildList {
                while (row.moveToNext()) {
                    val name = row.getString(1) ?: continue
                    if (!name.endsWith(".epub", ignoreCase = true)) continue
                    val uri = DocumentsContract.buildDocumentUriUsingTree(tree, row.getString(0)).toString()
                    add(Found(uri, name, row.getLong(2)))
                }
            }
        }
    }

    /**
     * The text of the EPUB's package file (its .opf entry), read from the
     * zip's central directory at the end of the file, so only the directory
     * and that one entry are read. Null when the file is not a readable zip.
     */
    private fun readOpf(resolver: ContentResolver, uri: Uri): String? {
        return try {
            val descriptor = resolver.openFileDescriptor(uri, "r") ?: return null
            ParcelFileDescriptor.AutoCloseInputStream(descriptor).channel.use { opfFrom(it) }
        } catch (error: Exception) {
            null
        }
    }

    /** Finds the first .opf entry in the zip on [channel] and returns its text. */
    private fun opfFrom(channel: FileChannel): String? {
        val size = channel.size()
        // The end record is 22 bytes, after at most a 65535 byte comment.
        val tailLength = minOf(size, 22L + 65_535L).toInt()
        val tail = read(channel, size - tailLength, tailLength)
        val end = (tailLength - 22 downTo 0).firstOrNull { tail.getInt(it) == END_RECORD } ?: return null
        val count = tail.getShort(end + 10).toInt() and 0xffff
        val directoryLength = tail.getInt(end + 12)
        val directoryStart = tail.getInt(end + 16).toLong() and 0xffffffffL
        // The sizes come from the file itself; a broken or crafted one must
        // not make this allocate more than a real EPUB ever needs.
        if (directoryLength !in 0..MAX_DIRECTORY || directoryStart + directoryLength > size) return null
        val directory = read(channel, directoryStart, directoryLength)
        var at = 0
        repeat(count) {
            if (directory.getInt(at) != DIRECTORY_ENTRY) return null
            val method = directory.getShort(at + 10).toInt() and 0xffff
            val packed = directory.getInt(at + 20)
            val unpacked = directory.getInt(at + 24)
            val nameLength = directory.getShort(at + 28).toInt() and 0xffff
            val extraLength = directory.getShort(at + 30).toInt() and 0xffff
            val commentLength = directory.getShort(at + 32).toInt() and 0xffff
            val local = directory.getInt(at + 42).toLong() and 0xffffffffL
            val name = ByteArray(nameLength).also { directory.position(at + 46); directory.get(it) }
            val fits = packed in 0..MAX_OPF && unpacked in 0..MAX_OPF && local + 30 + packed <= size
            if (String(name, Charsets.UTF_8).endsWith(".opf") && fits) {
                val header = read(channel, local, 30)
                val start = local + 30 + (header.getShort(26).toInt() and 0xffff) + (header.getShort(28).toInt() and 0xffff)
                val bytes = ByteArray(packed).also { read(channel, start, packed).get(it) }
                return when (method) {
                    0 -> String(bytes, Charsets.UTF_8)
                    8 -> String(inflate(bytes, unpacked), Charsets.UTF_8)
                    else -> null
                }
            }
            at += 46 + nameLength + extraLength + commentLength
        }
        return null
    }

    /** Unpacks a deflated zip entry of [length] bytes. */
    private fun inflate(bytes: ByteArray, length: Int): ByteArray {
        val inflater = Inflater(true)
        try {
            inflater.setInput(bytes)
            val out = ByteArray(length)
            inflater.inflate(out)
            return out
        } finally {
            inflater.end()
        }
    }

    /** Reads [length] bytes at [position], little endian as zip is. */
    private fun read(channel: FileChannel, position: Long, length: Int): ByteBuffer {
        val buffer = ByteBuffer.allocate(length).order(ByteOrder.LITTLE_ENDIAN)
        var at = position
        while (buffer.hasRemaining()) {
            val read = channel.read(buffer, at)
            if (read < 0) break
            at += read
        }
        buffer.flip()
        return buffer
    }

    private const val END_RECORD = 0x06054b50
    private const val DIRECTORY_ENTRY = 0x02014b50

    /** A package file is a few kilobytes; anything near this is not one. */
    private const val MAX_OPF = 4 * 1024 * 1024

    /**
     * About 80 bytes per entry, so even an EPUB of tens of thousands of files
     * fits; anything larger is not a real EPUB.
     */
    private const val MAX_DIRECTORY = 8 * 1024 * 1024
}
