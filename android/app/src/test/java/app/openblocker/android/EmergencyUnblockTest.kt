package app.openblocker.android

import app.openblocker.android.data.EmergencyUnblockManager
import org.junit.Test
import org.junit.Assert.*
import java.util.*

/**
 * Unit tests for Emergency Unblock logic.
 */
class EmergencyUnblockTest {
    
    @Test
    fun `initial status has full allowance`() {
        EmergencyUnblockManager.resetToFull()
        val status = EmergencyUnblockManager.status()
        assertEquals(5, status.remaining)
    }
    
    @Test
    fun `using one decrements remaining`() {
        EmergencyUnblockManager.resetToFull()
        val before = EmergencyUnblockManager.status()
        val success = EmergencyUnblockManager.useOne()
        val after = EmergencyUnblockManager.status()
        
        assertTrue(success)
        assertEquals(before.remaining - 1, after.remaining)
    }
    
    @Test
    fun `cannot use when empty`() {
        EmergencyUnblockManager.resetToFull()
        // Use all 5
        repeat(5) {
            EmergencyUnblockManager.useOne()
        }
        
        val success = EmergencyUnblockManager.useOne()
        assertFalse(success)
        
        val status = EmergencyUnblockManager.status()
        assertEquals(0, status.remaining)
    }
    
    @Test
    fun `reset date is 6 months after period start`() {
        EmergencyUnblockManager.resetToFull()
        val status = EmergencyUnblockManager.status()
        
        val calendar = Calendar.getInstance()
        val now = calendar.time
        calendar.time = status.resetDate
        
        val nowCal = Calendar.getInstance()
        nowCal.time = now
        
        // Reset date should be approximately 6 months later
        val monthDiff = (calendar.get(Calendar.YEAR) - nowCal.get(Calendar.YEAR)) * 12 +
                       (calendar.get(Calendar.MONTH) - nowCal.get(Calendar.MONTH))
        
        assertEquals(6, monthDiff)
    }
}
