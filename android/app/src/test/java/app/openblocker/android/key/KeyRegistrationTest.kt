package app.openblocker.android.key

import app.openblocker.android.format.OpenBlockerFormat
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyRegistrationTest {

    private val vector = "openblocker://tag/v1/550e8400e29b41d4a716446655440000"
    private val other = "openblocker://tag/v1/ffffffffffffffffffffffffffffffff"

    @Test
    fun canonicalizeReencodesValidUri() {
        assertEquals(
            vector,
            KeyRegistration.canonicalizeQR("openblocker://tag/v1/550E8400E29B41D4A716446655440000")
        )
    }

    @Test
    fun canonicalizeLeavesInvalidPayloadUnchanged() {
        assertEquals("not-a-key", KeyRegistration.canonicalizeQR("not-a-key"))
    }

    @Test
    fun qrPayloadsMatchIgnoresHexCase() {
        assertTrue(
            KeyRegistration.qrPayloadsMatch(
                vector,
                "openblocker://tag/v1/550E8400E29B41D4A716446655440000"
            )
        )
        assertFalse(KeyRegistration.qrPayloadsMatch(vector, other))
    }

    @Test
    fun isOpenBlockerQr() {
        assertTrue(KeyRegistration.isOpenBlockerQr(vector))
        assertFalse(KeyRegistration.isOpenBlockerQr("https://example.com"))
        assertFalse(KeyRegistration.isOpenBlockerQr(""))
    }

    @Test
    fun evaluateQrInvalidUnpairedAndPaired() {
        assertEquals(
            QrScanOutcome.INVALID_FORMAT,
            KeyRegistration.evaluateQr("hello world", setOf(vector))
        )
        assertEquals(
            QrScanOutcome.UNPAIRED,
            KeyRegistration.evaluateQr(other, setOf(vector))
        )
        assertEquals(
            QrScanOutcome.PAIRED,
            KeyRegistration.evaluateQr(vector, setOf(vector))
        )
        assertEquals(
            QrScanOutcome.PAIRED,
            KeyRegistration.evaluateQr("  $vector  ", setOf(vector))
        )
    }

    @Test
    fun nfcAndQrShareIsPaired() {
        val tagId = OpenBlockerFormat.bytesToHex(
            OpenBlockerFormat.hexToBytes("550e8400e29b41d4a716446655440000")
        )
        assertTrue(
            KeyRegistration.isPaired(
                ScannedKey.Qr(vector),
                storedQr = setOf(vector),
                storedTagIds = emptySet(),
                storedUids = emptySet()
            )
        )
        assertFalse(
            KeyRegistration.isPaired(
                ScannedKey.Qr(other),
                storedQr = setOf(vector),
                storedTagIds = emptySet(),
                storedUids = emptySet()
            )
        )
        assertTrue(
            KeyRegistration.isPaired(
                ScannedKey.OpenBlockerTag(tagId),
                storedQr = emptySet(),
                storedTagIds = setOf(tagId),
                storedUids = emptySet()
            )
        )
        assertTrue(
            KeyRegistration.isPaired(
                ScannedKey.Uid("04123456abcdef"),
                storedQr = emptySet(),
                storedTagIds = emptySet(),
                storedUids = setOf("04123456abcdef")
            )
        )
        assertFalse(
            KeyRegistration.isPaired(
                ScannedKey.Uid("deadbeef"),
                storedQr = setOf(vector),
                storedTagIds = setOf(tagId),
                storedUids = setOf("04123456abcdef")
            )
        )
    }

    @Test
    fun rejectMessageMatchesIos() {
        assertEquals("That's not one of your keys.", KeyRegistration.rejectMessage(true))
        assertEquals("This key isn't set up yet. Add it in Settings.", KeyRegistration.rejectMessage(false))
    }
}
