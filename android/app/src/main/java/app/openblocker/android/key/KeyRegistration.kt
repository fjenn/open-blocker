package app.openblocker.android.key

import app.openblocker.android.format.OpenBlockerFormat

enum class QrScanOutcome {
    INVALID_FORMAT,
    UNPAIRED,
    PAIRED
}

object KeyRegistration {

    fun canonicalizeQR(payload: String): String {
        return try {
            OpenBlockerFormat.encodeForQR(OpenBlockerFormat.decodeFromQR(payload))
        } catch (_: IllegalArgumentException) {
            payload
        }
    }

    fun qrPayloadsMatch(stored: String, scanned: String): Boolean {
        return canonicalizeQR(stored) == canonicalizeQR(scanned)
    }

    fun isOpenBlockerQr(payload: String): Boolean {
        return try {
            OpenBlockerFormat.decodeFromQR(payload)
            true
        } catch (_: IllegalArgumentException) {
            false
        }
    }

    fun evaluateQr(raw: String, storedPayloads: Set<String>): QrScanOutcome {
        val trimmed = raw.trim()
        if (!isOpenBlockerQr(trimmed)) {
            return QrScanOutcome.INVALID_FORMAT
        }
        val canonical = canonicalizeQR(trimmed)
        return if (storedPayloads.any { qrPayloadsMatch(it, canonical) }) {
            QrScanOutcome.PAIRED
        } else {
            QrScanOutcome.UNPAIRED
        }
    }

    fun isPaired(
        scanned: ScannedKey,
        storedQr: Set<String>,
        storedTagIds: Set<String>,
        storedUids: Set<String>
    ): Boolean {
        return when (scanned) {
            is ScannedKey.Qr -> storedQr.any { qrPayloadsMatch(it, scanned.payload) }
            is ScannedKey.OpenBlockerTag -> storedTagIds.contains(scanned.tagIdHex)
            is ScannedKey.Uid -> storedUids.contains(scanned.uidHex)
        }
    }

    fun rejectMessage(blocking: Boolean): String {
        return if (blocking) {
            "Wrong key. Use the NFC tag, card, or QR you paired to end the session."
        } else {
            "This is not a paired key. Pair this tag, card, or QR before using it."
        }
    }
}
