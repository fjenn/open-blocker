package app.openblocker.android.nfc

import org.junit.Assert.*
import org.junit.Test

class NfcIntentsTest {

    @Test
    fun acceptsNdefTechAndTagActions() {
        assertTrue(NfcIntents.isNfcTagAction(NfcIntents.ACTION_NDEF_DISCOVERED))
        assertTrue(NfcIntents.isNfcTagAction(NfcIntents.ACTION_TECH_DISCOVERED))
        assertTrue(NfcIntents.isNfcTagAction(NfcIntents.ACTION_TAG_DISCOVERED))
    }

    @Test
    fun rejectsNullAndUnrelatedActions() {
        assertFalse(NfcIntents.isNfcTagAction(null))
        assertFalse(NfcIntents.isNfcTagAction("android.intent.action.MAIN"))
        assertFalse(NfcIntents.isNfcTagAction(""))
    }
}
