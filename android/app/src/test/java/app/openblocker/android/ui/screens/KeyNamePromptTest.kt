package app.openblocker.android.ui.screens

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class KeyNamePromptTest {
    @Test
    fun missingNameHintMatchesToneAndHasNoEmDash() {
        assertEquals("Add a name", MISSING_KEY_NAME_HINT)
        assertFalse(MISSING_KEY_NAME_HINT.contains("\u2014"))
        assertFalse(MISSING_KEY_NAME_HINT.contains("\u2013"))
    }
}
