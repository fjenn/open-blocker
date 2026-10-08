package app.openblocker.android.qr

import app.openblocker.android.format.OpenBlockerFormat
import org.junit.Assert.assertEquals
import org.junit.Test

class QrCodecTest {

    @Test
    fun decodeGeneratedBitmapMatchesIosPayload() {
        val payload = "openblocker://tag/v1/550e8400e29b41d4a716446655440000"
        val decoded = QrCodec.decodeGenerated(payload)
        assertEquals(payload, decoded)
        val tag = OpenBlockerFormat.decodeFromQR(decoded)
        assertEquals(payload, OpenBlockerFormat.encodeForQR(tag))
    }

    @Test
    fun decodeGeneratedRandomTagId() {
        val payload = OpenBlockerFormat.encodeForQR(
            OpenBlockerFormat.TagData(tagId = OpenBlockerFormat.generateTagId())
        )
        assertEquals(payload, QrCodec.decodeGenerated(payload, size = 320))
    }
}
