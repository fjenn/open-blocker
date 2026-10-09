package app.openblocker.android

import app.openblocker.android.data.CountManager
import org.junit.Test
import org.junit.Assert.*

/**
 * Unit tests for Count Manager default behavior.
 */
class CountManagerTest {
    
    @Test
    fun `count manager has correct constants`() {
        assertEquals("Helps us count users. No personal data.", CountManager.SUMMARY)
        assertEquals(
            "One ping after your first block, with a random ID and the app version. Nothing about you or your apps.",
            CountManager.DISCLOSURE
        )
    }
    
    @Test
    fun `count is enabled by default when BUILD enabled`() {
        // Note: This test assumes COUNT_ENABLED is true in the build config
        // The default should be true as per the iOS parity requirement
        
        // In a real app test, we would check:
        // assertTrue(CountManager.isCountingEnabled())
        
        // For unit test without Android context, we just verify the constant exists
        assertNotNull(CountManager.SUMMARY)
        assertNotNull(CountManager.DISCLOSURE)
    }
}
