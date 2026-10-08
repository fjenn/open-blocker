package app.openblocker.android.nfc

import org.junit.Assert.*
import org.junit.Test

class UidValidatorTest {
    
    @Test
    fun testValidUid() {
        // 7-byte UID (common for NTAG213/215/216)
        val uid = byteArrayOf(0x04.toByte(), 0x12, 0x34, 0x56, 0x78.toByte(), 0x9a.toByte(), 0xbc.toByte())
        assertNull(UidValidator.validateUid(uid))
    }
    
    @Test
    fun testRandomUid4ByteStartsWith08() {
        // 4-byte UID starting with 0x08 (random ID)
        val uid = byteArrayOf(0x08, 0x12, 0x34, 0x56)
        val error = UidValidator.validateUid(uid)
        assertNotNull(error)
        assertTrue(error!!.contains("Random UID"))
        assertTrue(error.contains("0x08"))
    }
    
    @Test
    fun testValid4ByteUid() {
        // 4-byte UID not starting with 0x08
        val uid = byteArrayOf(0x04, 0x12, 0x34, 0x56)
        assertNull(UidValidator.validateUid(uid))
    }
    
    @Test
    fun testEmptyUid() {
        val uid = byteArrayOf()
        val error = UidValidator.validateUid(uid)
        assertNotNull(error)
        assertTrue(error!!.contains("Empty"))
    }
    
    @Test
    fun testUidsMatch() {
        val uid1 = byteArrayOf(0x04, 0x12, 0x34, 0x56, 0x78.toByte())
        val uid2 = byteArrayOf(0x04, 0x12, 0x34, 0x56, 0x78.toByte())
        assertTrue(UidValidator.uidsMatch(uid1, uid2))
    }
    
    @Test
    fun testUidsDontMatch() {
        val uid1 = byteArrayOf(0x04, 0x12, 0x34, 0x56, 0x78.toByte())
        val uid2 = byteArrayOf(0x04, 0x12, 0x34, 0x56, 0x79.toByte())
        assertFalse(UidValidator.uidsMatch(uid1, uid2))
    }
    
    @Test
    fun testFormatUid() {
        val uid = byteArrayOf(0x04, 0x12, 0x34, 0x56.toByte(), 0xab.toByte(), 0xcd.toByte(), 0xef.toByte())
        assertEquals("04123456abcdef", UidValidator.formatUid(uid))
    }
    
    @Test
    fun testFormatUidWithLeadingZeros() {
        val uid = byteArrayOf(0x00, 0x01, 0x02, 0x0a)
        assertEquals("0001020a", UidValidator.formatUid(uid))
    }
}
