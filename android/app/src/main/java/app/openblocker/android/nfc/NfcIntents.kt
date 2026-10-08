package app.openblocker.android.nfc

/**
 * NFC intent actions the app accepts. Foreground dispatch with a tech list
 * delivers TECH_DISCOVERED, not TAG_DISCOVERED, so all three must be handled.
 */
object NfcIntents {
    const val ACTION_NDEF_DISCOVERED = "android.nfc.action.NDEF_DISCOVERED"
    const val ACTION_TECH_DISCOVERED = "android.nfc.action.TECH_DISCOVERED"
    const val ACTION_TAG_DISCOVERED = "android.nfc.action.TAG_DISCOVERED"

    fun isNfcTagAction(action: String?): Boolean {
        return action == ACTION_NDEF_DISCOVERED ||
            action == ACTION_TECH_DISCOVERED ||
            action == ACTION_TAG_DISCOVERED
    }
}
