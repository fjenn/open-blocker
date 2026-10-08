package app.openblocker.format

import java.security.SecureRandom
import java.util.UUID

/**
 * Open Blocker Tag Format v1.0
 *
 * Encodes and decodes NDEF messages for Open Blocker NFC tags.
 */
object OpenBlockerFormat {

    const val VERSION: Byte = 0x01

    // TNF (Type Name Format) values
    private const val TNF_EXTERNAL_TYPE: Byte = 0x04

    // Record flags
    private const val FLAG_MB: Byte = 0x80.toByte() // Message Begin
    private const val FLAG_ME: Byte = 0x40 // Message End
    private const val FLAG_SR: Byte = 0x10 // Short Record

    // Type strings
    private const val TYPE_EXTERNAL = "openblocker.org:tag"
    private const val TYPE_AAR = "android.com:pkg"

    /**
     * Represents an Open Blocker tag configuration.
     */
    data class TagData(
        val version: Byte = VERSION,
        val tagId: ByteArray,
        val androidPackage: String? = null
    ) {
        init {
            require(tagId.size == 16) { "Tag ID must be exactly 16 bytes" }
            require(version == VERSION) { "Unsupported version: $version" }
        }

        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (other !is TagData) return false
            return version == other.version &&
                   tagId.contentEquals(other.tagId) &&
                   androidPackage == other.androidPackage
        }

        override fun hashCode(): Int {
            var result = version.toInt()
            result = 31 * result + tagId.contentHashCode()
            result = 31 * result + (androidPackage?.hashCode() ?: 0)
            return result
        }
    }

    /**
     * Generates a new random 16-byte tag ID.
     */
    fun generateTagId(): ByteArray {
        val random = SecureRandom()
        val bytes = ByteArray(16)
        random.nextBytes(bytes)
        return bytes
    }

    /**
     * Converts a UUID to a 16-byte tag ID.
     */
    fun uuidToTagId(uuid: UUID): ByteArray {
        val buffer = ByteArray(16)
        val msb = uuid.mostSignificantBits
        val lsb = uuid.leastSignificantBits

        for (i in 0..7) {
            buffer[i] = (msb shr (8 * (7 - i))).toByte()
        }
        for (i in 0..7) {
            buffer[8 + i] = (lsb shr (8 * (7 - i))).toByte()
        }
        return buffer
    }

    /**
     * Converts a 16-byte tag ID to a UUID.
     */
    fun tagIdToUuid(tagId: ByteArray): UUID {
        require(tagId.size == 16) { "Tag ID must be 16 bytes" }

        var msb = 0L
        var lsb = 0L

        for (i in 0..7) {
            msb = (msb shl 8) or (tagId[i].toLong() and 0xff)
        }
        for (i in 0..7) {
            lsb = (lsb shl 8) or (tagId[8 + i].toLong() and 0xff)
        }

        return UUID(msb, lsb)
    }

    /**
     * Encodes TagData into an NDEF message byte array.
     *
     * The message contains:
     * - Record 1: External type record with version and tag ID
     * - Record 2 (optional): Android Application Record
     */
    fun encode(data: TagData): ByteArray {
        val records = mutableListOf<ByteArray>()

        // Record 1: External type with tag ID
        val payload1 = ByteArray(17)
        payload1[0] = data.version
        System.arraycopy(data.tagId, 0, payload1, 1, 16)

        val typeBytes1 = TYPE_EXTERNAL.toByteArray()
        val record1 = encodeRecord(
            flags = if (data.androidPackage == null) 
                (FLAG_MB.toInt() or FLAG_ME.toInt() or FLAG_SR.toInt()).toByte() 
                else 
                (FLAG_MB.toInt() or FLAG_SR.toInt()).toByte(),
            tnf = TNF_EXTERNAL_TYPE,
            type = typeBytes1,
            payload = payload1
        )
        records.add(record1)

        // Record 2: Android Application Record (if specified)
        if (data.androidPackage != null) {
            val payload2 = data.androidPackage.toByteArray()
            val typeBytes2 = TYPE_AAR.toByteArray()
            val record2 = encodeRecord(
                flags = (FLAG_ME.toInt() or FLAG_SR.toInt()).toByte(),
                tnf = TNF_EXTERNAL_TYPE,
                type = typeBytes2,
                payload = payload2
            )
            records.add(record2)
        }

        // Combine records
        val totalSize = records.sumOf { it.size }
        val result = ByteArray(totalSize)
        var offset = 0
        for (record in records) {
            System.arraycopy(record, 0, result, offset, record.size)
            offset += record.size
        }

        return result
    }

    /**
     * Encodes a single NDEF record.
     */
    private fun encodeRecord(flags: Byte, tnf: Byte, type: ByteArray, payload: ByteArray): ByteArray {
        val header = ByteArray(3 + type.size)
        header[0] = ((flags.toInt() and 0xF0) or (tnf.toInt() and 0x07)).toByte()
        header[1] = type.size.toByte()
        header[2] = payload.size.toByte()
        System.arraycopy(type, 0, header, 3, type.size)

        val result = ByteArray(header.size + payload.size)
        System.arraycopy(header, 0, result, 0, header.size)
        System.arraycopy(payload, 0, result, header.size, payload.size)

        return result
    }

    /**
     * Wraps an NDEF message in TLV format for writing to a tag.
     */
    fun wrapInTLV(ndefMessage: ByteArray): ByteArray {
        require(ndefMessage.size < 255) { "NDEF message too large for single-byte length" }

        val result = ByteArray(ndefMessage.size + 3)
        result[0] = 0x03 // NDEF Message TLV type
        result[1] = ndefMessage.size.toByte()
        System.arraycopy(ndefMessage, 0, result, 2, ndefMessage.size)
        result[result.size - 1] = 0xFE.toByte() // Terminator TLV

        return result
    }

    /**
     * Decodes an NDEF message byte array into TagData.
     *
     * @throws IllegalArgumentException if the message is not a valid Open Blocker format
     */
    fun decode(ndefMessage: ByteArray): TagData {
        var offset = 0

        // Read first record
        require(offset < ndefMessage.size) { "Empty NDEF message" }

        val flags1 = ndefMessage[offset].toInt()
        val tnf1 = flags1 and 0x07
        val mb = (flags1 and 0x80) != 0
        val sr1 = (flags1 and 0x10) != 0

        require(mb) { "First record must have MB flag" }
        require(tnf1 == TNF_EXTERNAL_TYPE.toInt()) { "Expected external type, got TNF=$tnf1" }
        require(sr1) { "Expected short record" }

        offset++

        val typeLength1 = ndefMessage[offset].toInt() and 0xff
        offset++

        val payloadLength1 = ndefMessage[offset].toInt() and 0xff
        offset++

        val type1 = String(ndefMessage, offset, typeLength1)
        offset += typeLength1

        require(type1 == TYPE_EXTERNAL) { "Expected type '$TYPE_EXTERNAL', got '$type1'" }
        require(payloadLength1 == 17) { "Expected payload length 17, got $payloadLength1" }

        val version = ndefMessage[offset]
        offset++

        val tagId = ByteArray(16)
        System.arraycopy(ndefMessage, offset, tagId, 0, 16)
        offset += 16

        // Check if there's a second record (AAR)
        var androidPackage: String? = null

        if (offset < ndefMessage.size) {
            val flags2 = ndefMessage[offset].toInt()
            val tnf2 = flags2 and 0x07
            val me = (flags2 and 0x40) != 0
            val sr2 = (flags2 and 0x10) != 0

            require(me) { "Second record must have ME flag" }
            require(tnf2 == TNF_EXTERNAL_TYPE.toInt()) { "Expected external type for AAR" }
            require(sr2) { "Expected short record for AAR" }

            offset++

            val typeLength2 = ndefMessage[offset].toInt() and 0xff
            offset++

            val payloadLength2 = ndefMessage[offset].toInt() and 0xff
            offset++

            val type2 = String(ndefMessage, offset, typeLength2)
            offset += typeLength2

            require(type2 == TYPE_AAR) { "Expected AAR type '$TYPE_AAR', got '$type2'" }

            androidPackage = String(ndefMessage, offset, payloadLength2)
        }

        return TagData(version, tagId, androidPackage)
    }

    fun bytesToHex(bytes: ByteArray): String {
        return bytes.joinToString("") { "%02x".format(it) }
    }

    fun hexToBytes(hex: String): ByteArray {
        require(hex.length % 2 == 0) { "Hex string must have even length" }
        require(hex.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }) {
            "Invalid hex"
        }
        return hex.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    }

    const val QR_PREFIX = "openblocker://tag/v1/"

    fun encodeForQR(data: TagData): String {
        return QR_PREFIX + bytesToHex(data.tagId)
    }

    fun decodeFromQR(qrString: String): TagData {
        require(qrString.startsWith(QR_PREFIX)) { "Invalid QR format" }
        val hexString = qrString.removePrefix(QR_PREFIX)
        require(hexString.length == 32) { "Invalid QR format" }
        val tagId = hexToBytes(hexString)
        require(tagId.size == 16) { "Invalid QR format" }
        return TagData(tagId = tagId)
    }

    /**
     * Unwraps an NDEF message from TLV format.
     */
    fun unwrapFromTLV(tlvData: ByteArray): ByteArray {
        require(tlvData.isNotEmpty()) { "Empty TLV data" }
        require(tlvData[0] == 0x03.toByte()) { "Expected NDEF Message TLV type (0x03)" }

        val length = tlvData[1].toInt() and 0xff
        require(tlvData.size >= length + 2) { "TLV length exceeds data size" }

        val ndefMessage = ByteArray(length)
        System.arraycopy(tlvData, 2, ndefMessage, 0, length)

        return ndefMessage
    }
}
