package app.openblocker.android.format

import org.junit.Assert.*
import org.junit.Test

class OpenBlockerFormatTest {

    @Test
    fun encodeDecodeRoundTripWithAar() {
        val tagId = OpenBlockerFormat.generateTagId()
        val encoded = OpenBlockerFormat.encode(
            OpenBlockerFormat.TagData(
                tagId = tagId,
                androidPackage = "app.openblocker.android"
            )
        )
        val decoded = OpenBlockerFormat.decode(encoded)
        assertArrayEquals(tagId, decoded.tagId)
        assertEquals("app.openblocker.android", decoded.androidPackage)
        assertEquals(OpenBlockerFormat.VERSION, decoded.version)
    }

    @Test
    fun generateTagIdIsSixteenRandomBytes() {
        val a = OpenBlockerFormat.generateTagId()
        val b = OpenBlockerFormat.generateTagId()
        assertEquals(16, a.size)
        assertEquals(16, b.size)
        assertFalse(a.contentEquals(b))
    }

    @Test
    fun hexRoundTrip() {
        val bytes = byteArrayOf(0x00, 0x01, 0x0a, 0xff.toByte())
        assertEquals("00010aff", OpenBlockerFormat.bytesToHex(bytes))
        assertArrayEquals(bytes, OpenBlockerFormat.hexToBytes("00010aff"))
    }
}
