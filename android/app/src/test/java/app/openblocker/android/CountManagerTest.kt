package app.openblocker.android

import app.openblocker.android.data.CountManager
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CountManagerTest {

    @Test
    fun countIsOnByDefault() {
        assertTrue(CountManager.enabledByDefault)
    }

    @Test
    fun settingsLineIsShort() {
        val words = CountManager.SUMMARY.split(" ")
        assertTrue(words.size <= 8)
        assertTrue(CountManager.SUMMARY.contains("No personal data"))
    }

    @Test
    fun privacyPageSaysExactlyWhatIsSent() {
        assertTrue(CountManager.DISCLOSURE.contains("random ID"))
        assertTrue(CountManager.DISCLOSURE.contains("app version"))
    }

    @Test
    fun copyHasNoOptInWordingOrEmDashes() {
        listOf(CountManager.SUMMARY, CountManager.DISCLOSURE).forEach { text ->
            assertFalse(text.contains("opt-in", ignoreCase = true))
            assertFalse(text.contains("off by default", ignoreCase = true))
            assertFalse(text.contains("\u2014"))
        }
    }
}
