package app.openblocker.android.key

import android.content.Context
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.data.SessionManager
import app.openblocker.android.format.OpenBlockerFormat
import app.openblocker.android.ui.AppNotice
import app.openblocker.android.ui.haptics.AppHaptics

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
        AppHaptics.success(context)
        if (SessionManager.isBlocking.value) {
            SessionManager.endSession()
        } else {
            SessionManager.startSession(SessionManager.SOURCE_KEY)
        }
    }

    fun rejectMessage(): String {
        return KeyRegistration.rejectMessage(SessionManager.isBlocking.value)
    }

    fun onQrScanned(context: Context, raw: String) {
        when (KeyRegistration.evaluateQr(raw, PreferencesManager.getPairedQrPayloads())) {
            QrScanOutcome.INVALID_FORMAT -> reject(context, "This QR is not an Open Blocker key.")
            QrScanOutcome.UNPAIRED -> reject(context, rejectMessage())
            QrScanOutcome.PAIRED -> applyPairedKey(context)
        }
    }

    fun reject(context: Context, message: String = rejectMessage()) {
        AppHaptics.error(context)
        AppNotice.show(message)
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
