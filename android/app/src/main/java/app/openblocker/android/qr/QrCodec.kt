package app.openblocker.android.qr

import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.EncodeHintType
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.BitMatrix
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel

object QrCodec {

    fun encodeMatrix(payload: String, size: Int = 512): BitMatrix {
        val hints = mapOf(
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.H,
            EncodeHintType.CHARACTER_SET to "UTF-8",
            EncodeHintType.MARGIN to 1
        )
        return QRCodeWriter().encode(payload, BarcodeFormat.QR_CODE, size, size, hints)
    }

    fun matrixToArgb(matrix: BitMatrix): IntArray {
        val width = matrix.width
        val height = matrix.height
        val pixels = IntArray(width * height)
        for (y in 0 until height) {
            for (x in 0 until width) {
                pixels[y * width + x] = if (matrix.get(x, y)) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
            }
        }
        return pixels
    }

    fun decodePixels(width: Int, height: Int, pixels: IntArray): String {
        val source = RGBLuminanceSource(width, height, pixels)
        val bitmap = BinaryBitmap(HybridBinarizer(source))
        val reader = QRCodeReader()
        return try {
            reader.decode(bitmap, mapOf(DecodeHintType.PURE_BARCODE to true)).text
        } catch (_: Exception) {
            reader.reset()
            reader.decode(bitmap, mapOf(DecodeHintType.TRY_HARDER to true)).text
        }
    }

    fun decodeGenerated(payload: String, size: Int = 256): String {
        val matrix = encodeMatrix(payload, size)
        return decodePixels(matrix.width, matrix.height, matrixToArgb(matrix))
    }
}
