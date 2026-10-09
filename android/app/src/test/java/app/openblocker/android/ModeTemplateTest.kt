package app.openblocker.android

import app.openblocker.android.models.ModeKind
import app.openblocker.android.models.ModeTemplate
import org.junit.Test
import org.junit.Assert.*

/**
 * Unit tests for Mode Template logic.
 */
class ModeTemplateTest {
    
    @Test
    fun `all templates have required fields`() {
        ModeTemplate.values().forEach { template ->
            assertNotNull(template.displayName)
            assertTrue(template.displayName.isNotEmpty())
            assertNotNull(template.summary)
            assertTrue(template.summary.isNotEmpty())
            assertNotNull(template.symbol)
            assertNotNull(template.kind)
        }
    }
    
    @Test
    fun `deep work has correct configuration`() {
        val template = ModeTemplate.DEEP_WORK
        assertEquals("Deep work", template.displayName)
        assertEquals(ModeKind.BLOCK, template.kind)
        assertTrue(template.opensAppPicker)
        assertNotNull(template.suggestedSchedule())
    }
    
    @Test
    fun `sleep has correct configuration`() {
        val template = ModeTemplate.SLEEP
        assertEquals("Sleep", template.displayName)
        assertEquals(ModeKind.ALLOW_ONLY, template.kind)
        assertTrue(template.opensAppPicker)
        
        val schedule = template.suggestedSchedule()
        assertNotNull(schedule)
        assertEquals(7, schedule!!.weekdays.size) // Every day
        assertEquals(22 * 60, schedule.startMinute) // 10 PM
        assertEquals(7 * 60, schedule.endMinute) // 7 AM
    }
    
    @Test
    fun `mindfulness has correct configuration`() {
        val template = ModeTemplate.MINDFULNESS
        assertEquals("Mindfulness", template.displayName)
        assertEquals(ModeKind.BLOCK, template.kind)
        assertTrue(template.opensAppPicker)
    }
    
    @Test
    fun `family time has correct configuration`() {
        val template = ModeTemplate.FAMILY_TIME
        assertEquals("Family time", template.displayName)
        assertEquals(ModeKind.ALLOW_ONLY, template.kind)
        assertTrue(template.opensAppPicker)
    }
    
    @Test
    fun `detox has correct configuration`() {
        val template = ModeTemplate.DETOX
        assertEquals("Detox", template.displayName)
        assertEquals(ModeKind.ALLOW_ONLY, template.kind)
        assertFalse(template.opensAppPicker)
    }
    
    @Test
    fun `blank has correct configuration`() {
        val template = ModeTemplate.BLANK
        assertEquals("Blank", template.displayName)
        assertEquals(ModeKind.BLOCK, template.kind)
        assertFalse(template.opensAppPicker)
        assertNull(template.suggestedSchedule())
    }
    
    @Test
    fun `deep work schedule is weekdays 9am to 12pm`() {
        val schedule = ModeTemplate.DEEP_WORK.suggestedSchedule()
        assertNotNull(schedule)
        assertEquals(setOf(2, 3, 4, 5, 6), schedule!!.weekdays) // Mon-Fri
        assertEquals(9 * 60, schedule.startMinute)
        assertEquals(12 * 60, schedule.endMinute)
    }
}
