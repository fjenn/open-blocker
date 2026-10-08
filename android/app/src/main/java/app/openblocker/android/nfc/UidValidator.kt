package app.openblocker.android.nfc

object UidValidator {
    
    /**
     * Checks if a UID is likely a random/changing UID that can't be used as a stable key.
     * 
     * Returns null if valid, or an error message if invalid.
     */
    fun validateUid(uid: ByteArray): String? {
        if (uid.isEmpty()) {
            return "Empty UID"
        }
        
        // Check for random UIDs: 4-byte UIDs starting with 0x08 (ISO 14443 random ID range)
        if (uid.size == 4 && uid[0] == 0x08.toByte()) {
            return "Random UID detected (starts with 0x08). This card generates a different ID each tap and cannot be used as a key."
        }
        
        return null
    }
    
    /**
     * Checks if two UIDs match exactly.
     */
    fun uidsMatch(uid1: ByteArray, uid2: ByteArray): Boolean {
        return uid1.contentEquals(uid2)
    }
    
    /**
     * Formats a UID as a hex string for display and storage.
     */
    fun formatUid(uid: ByteArray): String {
        return uid.joinToString("") { "%02x".format(it) }
    }
}
