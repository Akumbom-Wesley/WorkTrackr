package com.worktrackr.worktrackr

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileOutputStream

/**
 * Saves report bytes to the device's public Downloads folder.
 *
 * API 29+ (Build.VERSION_CODES.Q): uses MediaStore.Downloads insertion via
 * ContentResolver. This is the scoped-storage-correct approach and does NOT
 * require WRITE_EXTERNAL_STORAGE or MANAGE_EXTERNAL_STORAGE — confirmed
 * empirically last session that the old raw File.writeAsBytes() path wrote
 * bytes successfully but left zero MediaStore record, which this fixes.
 *
 * Pre-29: MediaStore.Downloads.EXTERNAL_CONTENT_URI doesn't exist before Q,
 * so this falls back to a direct raw-path write into the public Downloads
 * directory (mirrors the previous Dart-side _saveToDownloads() Android
 * branch). WRITE_EXTERNAL_STORAGE (maxSdkVersion=28, already declared in
 * the manifest) covers this branch.
 *
 * NOT YET VERIFIED ON A REAL DEVICE for either branch — flagging forward
 * per the existing project convention, since the prior Dart-side
 * implementation carried the same unverified-on-hardware caveat.
 */
class MediaStoreSaver(private val context: Context) {

    /**
     * Returns the saved file's display path (best-effort human-readable
     * string) on success. Throws on failure — callers (MainActivity's
     * MethodChannel handler) are expected to catch and convert to
     * result.error(...), NOT swallow to a null/success response.
     */
    fun save(bytes: ByteArray, displayName: String, mimeType: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveViaMediaStore(bytes, displayName, mimeType)
        } else {
            saveViaRawPath(bytes, displayName)
        }
    }

    private fun saveViaMediaStore(bytes: ByteArray, displayName: String, mimeType: String): String {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, displayName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val itemUri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore.insert returned null Uri for $displayName")

        resolver.openOutputStream(itemUri)?.use { out ->
            out.write(bytes)
        } ?: throw IllegalStateException("Could not open output stream for $itemUri")

        values.clear()
        values.put(MediaStore.Downloads.IS_PENDING, 0)
        resolver.update(itemUri, values, null, null)

        return "Downloads/$displayName"
    }

    private fun saveViaRawPath(bytes: ByteArray, displayName: String): String {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()
        }
        val outFile = File(downloadsDir, displayName)
        FileOutputStream(outFile).use { out ->
            out.write(bytes)
        }
        return outFile.absolutePath
    }
}
