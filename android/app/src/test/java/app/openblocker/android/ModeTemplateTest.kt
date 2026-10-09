package app.openblocker.android

import app.openblocker.android.domain.BlockMode
import app.openblocker.android.domain.ModeDefaults
import app.openblocker.android.domain.ModeName
import app.openblocker.android.domain.ModeTemplate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ModeTemplateTest {

    @Test
    fun templateSet() {
        assertEquals(
            listOf("Deep work", "Sleep", "Mindfulness", "Family time", "Detox", "Blank"),
            ModeTemplate.entries.map { it.title }
        )
        ModeTemplate.entries.forEach { template ->
            assertFalse(template.title.contains("almost none", ignoreCase = true))
            assertFalse(template.title.contains("brick", ignoreCase = true))
            assertFalse(template.summary.contains("\u2014"))
            assertFalse((template.scheduleSummary ?: "").contains("\u2014"))
        }
    }

    @Test
    fun templatesPrefillBehavior() {
        assertEquals(BlockMode.Kind.BLOCK, ModeTemplate.DEEP_WORK.kind)
        assertEquals(BlockMode.Kind.ALLOW_ONLY, ModeTemplate.SLEEP.kind)
        assertEquals(BlockMode.Kind.BLOCK, ModeTemplate.MINDFULNESS.kind)
        assertEquals(BlockMode.Kind.ALLOW_ONLY, ModeTemplate.FAMILY_TIME.kind)
        assertEquals(BlockMode.Kind.ALLOW_ONLY, ModeTemplate.DETOX.kind)
        assertEquals(BlockMode.Kind.BLOCK, ModeTemplate.BLANK.kind)
    }

    @Test
    fun onlyTemplatesThatNeedAppsOpenThePicker() {
        assertEquals(
            listOf(ModeTemplate.DEEP_WORK, ModeTemplate.SLEEP, ModeTemplate.MINDFULNESS, ModeTemplate.FAMILY_TIME),
            ModeTemplate.entries.filter { it.opensAppPicker }
        )
    }

    @Test
    fun madeModesStartWithoutApps() {
        val detox = ModeTemplate.DETOX.makeMode()
        assertEquals("Detox", detox.name)
        assertEquals("Blocks all apps", detox.subtitle)
        assertEquals("Nothing chosen yet", ModeTemplate.DEEP_WORK.makeMode().subtitle)
        assertEquals("", ModeTemplate.BLANK.makeMode().name)
    }

    @Test
    fun sleepSuggestsAnOvernightScheduleForTheNewMode() {
        val sleep = ModeTemplate.SLEEP.makeMode()
        val schedule = ModeTemplate.SLEEP.suggestedSchedule(sleep)!!
        assertEquals(sleep.id, schedule.modeId)
        assertEquals("Sleep", schedule.name)
        assertEquals(7, schedule.weekdays.size)
        assertEquals(22 * 60, schedule.startMinute)
        assertEquals(7 * 60, schedule.endMinute)
        assertTrue(schedule.isOn)
        assertEquals("Every day, 10:00 PM - 7:00 AM", ModeTemplate.SLEEP.scheduleSummary)
    }

    @Test
    fun everyScheduleSuggestionIsUsable() {
        ModeTemplate.entries.forEach { template ->
            val schedule = template.suggestedSchedule(template.makeMode()) ?: return@forEach
            assertTrue(template.title, schedule.weekdays.isNotEmpty())
            assertTrue(template.title, schedule.olderThan15Minutes)
        }
        assertNull(ModeTemplate.DETOX.scheduleSummary)
        assertNull(ModeTemplate.BLANK.scheduleSummary)
    }

    @Test
    fun modeNamesAreTrimmedAndRequired() {
        assertEquals("Reading", ModeName.validated("  Reading  "))
        assertNull(ModeName.validated(""))
        assertNull(ModeName.validated("   \n"))
    }

    @Test
    fun freshConfigGetsAnActiveStarterMode() {
        val seeded = ModeDefaults.seeded(emptyList(), null)!!
        assertEquals(1, seeded.first.size)
        val starter = seeded.first.first()
        assertEquals(starter.id, seeded.second)
        assertEquals("Detox", starter.name)
        assertEquals(BlockMode.Kind.ALLOW_ONLY, starter.kind)
        assertEquals("Blocks all apps", starter.subtitle)
    }

    @Test
    fun existingModesAreLeftAlone() {
        assertNull(ModeDefaults.seeded(listOf(BlockMode(name = "Mine")), null))
    }
}
