package app.openblocker.android.nfc

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build

object NfcDispatch {

    fun enable(activity: Activity, adapter: NfcAdapter?) {
        if (adapter == null) return
        val intent = Intent(activity, activity.javaClass).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            activity,
            0,
            intent,
            PendingIntent.FLAG_MUTABLE
        )
        // null filters and tech lists: deliver every NFC intent to this activity
        adapter.enableForegroundDispatch(activity, pendingIntent, null, null)
    }

    fun disable(activity: Activity, adapter: NfcAdapter?) {
        try {
            adapter?.disableForegroundDispatch(activity)
        } catch (_: IllegalStateException) {
            // Already paused
        }
    }

    @Suppress("DEPRECATION")
    fun tagFrom(intent: Intent?): Tag? {
        if (intent == null || !NfcIntents.isNfcTagAction(intent.action)) {
            return null
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
        } else {
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
        }
    }
}
