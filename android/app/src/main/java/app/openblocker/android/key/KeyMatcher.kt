package app.openblocker.android.key

import android.content.Context
import android.widget.Toast
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.data.SessionManager
import app.openblocker.android.format.OpenBlockerFormat

object KeyMatcher {

    fun isPaired(scanned: ScannedKey): Boolean {
        return KeyRegistration.isPaired(
            scanned = scanned,
            storedQr = PreferencesManager.getPairedQrPayloads(),
            storedTagIds = PreferencesManager.getPairedTagIds(),
            storedUids = PreferencesManager.getPairedTagUids() + PreferencesManager.getAnyCardUids()
        )
    }

    fun applyPairedKey(context: Context) {
        if (SessionManager.isBlocking.value) {
            SessionManager.endSession()
            Toast.makeText(context, "Blocking session ended", Toast.LENGTH_SHORT).show()
        } else {
            SessionManager.startSession()
            Toast.makeText(context, "Blocking session started", Toast.LENGTH_SHORT).show()
        }
    }

    fun rejectMessage(): String {
        return KeyRegistration.rejectMessage(SessionManager.isBlocking.value)
    }

    fun onQrScanned(context: Context, raw: String) {
        when (KeyRegistration.evaluateQr(raw, PreferencesManager.getPairedQrPayloads())) {
            QrScanOutcome.INVALID_FORMAT ->
                Toast.makeText(context, "This QR is not an Open Blocker key.", Toast.LENGTH_LONG).show()
            QrScanOutcome.UNPAIRED ->
                Toast.makeText(context, rejectMessage(), Toast.LENGTH_LONG).show()
            QrScanOutcome.PAIRED ->
                applyPairedKey(context)
        }
    }

    fun registerQr(raw: String): String? {
        val data = try {
            OpenBlockerFormat.decodeFromQR(raw.trim())
        } catch (_: IllegalArgumentException) {
            return null
        }
        val canonical = OpenBlockerFormat.encodeForQR(data)
        PreferencesManager.addPairedQrPayload(canonical)
        return canonical
    }
}
