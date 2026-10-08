package app.openblocker.android.qr

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream

object QrBitmaps {

    fun toBitmap(payload: String, size: Int = 512): Bitmap {
        val matrix = QrCodec.encodeMatrix(payload, size)
        val pixels = QrCodec.matrixToArgb(matrix)
        return Bitmap.createBitmap(pixels, matrix.width, matrix.height, Bitmap.Config.ARGB_8888)
    }

    fun shareUri(context: Context, bitmap: Bitmap): Uri {
        val dir = File(context.cacheDir, "qr")
        dir.mkdirs()
        val file = File(dir, "openblocker-key.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )
    }
}
