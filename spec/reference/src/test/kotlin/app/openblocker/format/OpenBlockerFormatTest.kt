package app.openblocker.format

import org.junit.Assert.*
import org.junit.Test
import java.util.UUID

class OpenBlockerFormatTest {

    @Test
    fun testGenerateTagId() {
        val id1 = OpenBlockerFormat.generateTagId()
        val id2 = OpenBlockerFormat.generateTagId()

        assertEquals(16, id1.size)
        assertEquals(16, id2.size)
        assertFalse(id1.contentEquals(id2))
    }

    @Test
    fun testUuidConversion() {
        val uuid = UUID.fromString("550e8400-e29b-41d4-a716-446655440000")
        val tagId = OpenBlockerFormat.uuidToTagId(uuid)

        assertEquals(16, tagId.size)

        val recovered = OpenBlockerFormat.tagIdToUuid(tagId)
        assertEquals(uuid, recovered)
    }

    @Test
    fun testEncodeDecodeMinimal() {
        val tagId = OpenBlockerFormat.uuidToTagId(
            UUID.fromString("550e8400-e29b-41d4-a716-446655440000")
        )
        val data = OpenBlockerFormat.TagData(
            version = OpenBlockerFormat.VERSION,
            tagId = tagId,
            androidPackage = "app.openblocker.android"
        )

        val encoded = OpenBlockerFormat.encode(data)
        val decoded = OpenBlockerFormat.decode(encoded)

        assertEquals(data, decoded)
    }

    @Test
    fun testEncodeDecodeWithoutAAR() {
        val tagId = OpenBlockerFormat.uuidToTagId(
            UUID.fromString("f47ac10b-58cc-4372-a567-0e02b2c3d479")
        )
        val data = OpenBlockerFormat.TagData(
            version = OpenBlockerFormat.VERSION,
            tagId = tagId,
            androidPackage = null
        )

        val encoded = OpenBlockerFormat.encode(data)
        val decoded = OpenBlockerFormat.decode(encoded)

        assertEquals(data, decoded)
    }

    @Test
    fun testTLVWrapping() {
        val tagId = OpenBlockerFormat.generateTagId()
        val data = OpenBlockerFormat.TagData(
            tagId = tagId,
            androidPackage = "app.openblocker.android"
        )

        val ndefMessage = OpenBlockerFormat.encode(data)
        val tlvWrapped = OpenBlockerFormat.wrapInTLV(ndefMessage)

        assertEquals(0x03, tlvWrapped[0].toInt())
        assertEquals(ndefMessage.size, tlvWrapped[1].toInt() and 0xff)
        assertEquals(0xFE.toByte(), tlvWrapped[tlvWrapped.size - 1])

        val unwrapped = OpenBlockerFormat.unwrapFromTLV(tlvWrapped)
        assertArrayEquals(ndefMessage, unwrapped)
    }

    @Test
    fun testTestVector1() {
        // Test Vector 1 from spec
        val tagId = OpenBlockerFormat.uuidToTagId(
            UUID.fromString("550e8400-e29b-41d4-a716-446655440000")
        )
        val data = OpenBlockerFormat.TagData(
            tagId = tagId,
            androidPackage = "app.openblocker.android"
        )

        val encoded = OpenBlockerFormat.encode(data)

        // Verify structure
        assertTrue(encoded.size < 144) // Fits in NTAG213

        // Verify it can be decoded back
        val decoded = OpenBlockerFormat.decode(encoded)
        assertEquals(data, decoded)
    }

    @Test
    fun testTestVector2() {
        // Test Vector 2 from spec
        val tagId = OpenBlockerFormat.uuidToTagId(
            UUID.fromString("f47ac10b-58cc-4372-a567-0e02b2c3d479")
        )
        val data = OpenBlockerFormat.TagData(
            tagId = tagId,
            androidPackage = null
        )

        val encoded = OpenBlockerFormat.encode(data)

        // Verify structure
        assertTrue(encoded.size < 144) // Fits in NTAG213

        // Verify it can be decoded back
        val decoded = OpenBlockerFormat.decode(encoded)
        assertEquals(data, decoded)
    }

    @Test
    fun testMessageSize() {
        // Verify that messages fit comfortably in NTAG213 (144 bytes user memory)
        val tagId = OpenBlockerFormat.generateTagId()
        val data = OpenBlockerFormat.TagData(
            tagId = tagId,
            androidPackage = "app.openblocker.android.verylongpackagename"
        )

        val encoded = OpenBlockerFormat.encode(data)
        val tlvWrapped = OpenBlockerFormat.wrapInTLV(encoded)

        assertTrue("TLV message should fit in NTAG213", tlvWrapped.size < 144)
    }

    @Test(expected = IllegalArgumentException::class)
    fun testInvalidTagIdSize() {
        OpenBlockerFormat.TagData(
            tagId = ByteArray(15),
            androidPackage = null
        )
    }

    @Test(expected = IllegalArgumentException::class)
    fun testDecodeInvalidMessage() {
        val invalid = byteArrayOf(0x00, 0x01, 0x02)
        OpenBlockerFormat.decode(invalid)
    }

    @Test
    fun testQrEncodingMatchesSpecVector() {
        val tagId = OpenBlockerFormat.uuidToTagId(
            UUID.fromString("550e8400-e29b-41d4-a716-446655440000")
        )
        val encoded = OpenBlockerFormat.encodeForQR(OpenBlockerFormat.TagData(tagId = tagId))
        assertEquals("openblocker://tag/v1/550e8400e29b41d4a716446655440000", encoded)
        val decoded = OpenBlockerFormat.decodeFromQR(encoded)
        assertArrayEquals(tagId, decoded.tagId)
    }

    @Test(expected = IllegalArgumentException::class)
    fun testQrDecodeRejectsWrongPrefix() {
        OpenBlockerFormat.decodeFromQR("not-an-openblocker-qr")
    }

    @Test
    fun testEncodeExactBytes() {
        // Verify the exact byte structure for documentation
        val tagId = OpenBlockerFormat.uuidToTagId(
            UUID.fromString("550e8400-e29b-41d4-a716-446655440000")
        )
        val data = OpenBlockerFormat.TagData(
            tagId = tagId,
            androidPackage = "app.openblocker.android"
        )

        val encoded = OpenBlockerFormat.encode(data)

        // First byte should be flags with MB, SR, TNF=0x04
        val flags1 = encoded[0].toInt() and 0xff
        assertEquals(0x94, flags1) // MB=1, ME=0, SR=1, TNF=4

        // Type length
        assertEquals(19, encoded[1].toInt() and 0xff)

        // Payload length
        assertEquals(17, encoded[2].toInt() and 0xff)

        // Type string should be "openblocker.org:tag"
        val type1 = String(encoded, 3, 19)
        assertEquals("openblocker.org:tag", type1)

        // Version byte
        assertEquals(0x01, encoded[22].toInt() and 0xff)

        // Tag ID
        val extractedId = ByteArray(16)
        System.arraycopy(encoded, 23, extractedId, 0, 16)
        assertArrayEquals(tagId, extractedId)
    }
}
