package app.openblocker.android.format

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class OpenBlockerFormatQrTest {

    @Test
    fun encodeMatchesIosVector() {
        val tagId = OpenBlockerFormat.hexToBytes("550e8400e29b41d4a716446655440000")
        val encoded = OpenBlockerFormat.encodeForQR(OpenBlockerFormat.TagData(tagId = tagId))
        assertEquals("openblocker://tag/v1/550e8400e29b41d4a716446655440000", encoded)
    }

    @Test
    fun decodeRoundTripLowercaseHex() {
        val uri = "openblocker://tag/v1/550e8400e29b41d4a716446655440000"
        val decoded = OpenBlockerFormat.decodeFromQR(uri)
        assertEquals(16, decoded.tagId.size)
        assertEquals(uri, OpenBlockerFormat.encodeForQR(decoded))
        assertArrayEquals(
            OpenBlockerFormat.hexToBytes("550e8400e29b41d4a716446655440000"),
            decoded.tagId
        )
    }

    @Test
    fun decodeAcceptsUppercaseHexThenEncodeLowercases() {
        val decoded = OpenBlockerFormat.decodeFromQR(
            "openblocker://tag/v1/550E8400E29B41D4A716446655440000"
        )
        assertEquals(
            "openblocker://tag/v1/550e8400e29b41d4a716446655440000",
            OpenBlockerFormat.encodeForQR(decoded)
        )
    }

    @Test
    fun decodeRejectsWrongPrefix() {
        assertThrows(IllegalArgumentException::class.java) {
            OpenBlockerFormat.decodeFromQR("https://example.com/v1/550e8400e29b41d4a716446655440000")
        }
    }

    @Test
    fun decodeRejectsWrongHexLength() {
        assertThrows(IllegalArgumentException::class.java) {
            OpenBlockerFormat.decodeFromQR("openblocker://tag/v1/550e8400")
        }
    }

    @Test
    fun decodeRejectsNonHex() {
        assertThrows(IllegalArgumentException::class.java) {
            OpenBlockerFormat.decodeFromQR("openblocker://tag/v1/zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz")
        }
    }
}
