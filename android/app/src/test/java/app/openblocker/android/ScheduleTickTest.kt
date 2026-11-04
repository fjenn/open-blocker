package app.openblocker.android

import app.openblocker.android.domain.BlockSchedule
import app.openblocker.android.domain.ScheduleTick
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class ScheduleTickTest {
    private val calendar: Calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
        firstDayOfWeek = Calendar.SUNDAY
    }

    private fun at(year: Int, month: Int, day: Int, hour: Int, minute: Int): Calendar {
        calendar.clear()
        calendar.set(year, month - 1, day, hour, minute, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.clone() as Calendar
    }

    /** Friday 9:00–17:00. Calendar.FRIDAY == 6. */
    private fun workHours(id: String = "sched-1") = BlockSchedule(
        id = id,
        name = "Work",
        weekdays = setOf(Calendar.FRIDAY),
        startMinute = 9 * 60,
        endMinute = 17 * 60,
        modeId = "mode-1",
        isOn = true
    )

    @Test
    fun keyUnblockDuringWindowClearsAndSuppresses() {
        val schedule = workHours()
        val unblockAt = at(2026, 1, 9, 10, 0) // Friday
        assertTrue(schedule.contains(unblockAt))

        val suppression = ScheduleTick.suppressionAfterKeyUnblock(
            source = ScheduleTick.SOURCE_SCHEDULE,
            schedules = listOf(schedule),
            now = unblockAt
        )
        assertEquals(schedule.id, suppression!!.scheduleId)
        assertEquals(ScheduleTick.windowEndMs(schedule, unblockAt), suppression.untilMs)

        // Same window: tick must not re-arm (shields stay clear).
        val mid = ScheduleTick.decision(
            schedules = listOf(schedule),
            isBlocking = false,
            source = "",
            now = at(2026, 1, 9, 14, 0),
            suppression = suppression
        )
        assertEquals(ScheduleTick.Decision.None, mid)
    }

    @Test
    fun scheduleDoesNotRearmWithinSameWindow() {
        val schedule = workHours()
        val suppression = ScheduleTick.Suppression(
            scheduleId = schedule.id,
            untilMs = ScheduleTick.windowEndMs(schedule, at(2026, 1, 9, 10, 0))
        )
        assertEquals(
            ScheduleTick.Decision.None,
            ScheduleTick.decision(
                schedules = listOf(schedule),
                isBlocking = false,
                source = "",
                now = at(2026, 1, 9, 16, 59),
                suppression = suppression
            )
        )
    }

    @Test
    fun nextOccurrenceStillBlocks() {
        val schedule = workHours()
        val suppression = ScheduleTick.Suppression(
            scheduleId = schedule.id,
            untilMs = ScheduleTick.windowEndMs(schedule, at(2026, 1, 9, 10, 0))
        )
        // Next Friday 10:00 — previous Friday's override has expired.
        val next = ScheduleTick.decision(
            schedules = listOf(schedule),
            isBlocking = false,
            source = "",
            now = at(2026, 1, 16, 10, 0),
            suppression = suppression
        )
        assertEquals(ScheduleTick.Decision.Start(schedule), next)
    }

    @Test
    fun scheduledEndStillAutoUnblocks() {
        val schedule = workHours()
        // Still inside the window while blocking: no end yet.
        assertEquals(
            ScheduleTick.Decision.None,
            ScheduleTick.decision(
                schedules = listOf(schedule),
                isBlocking = true,
                source = ScheduleTick.SOURCE_SCHEDULE,
                now = at(2026, 1, 9, 16, 0),
                suppression = null
            )
        )
        // After the window: auto-end the scheduled session.
        assertEquals(
            ScheduleTick.Decision.End,
            ScheduleTick.decision(
                schedules = listOf(schedule),
                isBlocking = true,
                source = ScheduleTick.SOURCE_SCHEDULE,
                now = at(2026, 1, 9, 17, 0),
                suppression = null
            )
        )
    }

    @Test
    fun startsWhenIdleInsideWindowWithNoSuppression() {
        val schedule = workHours()
        assertEquals(
            ScheduleTick.Decision.Start(schedule),
            ScheduleTick.decision(
                schedules = listOf(schedule),
                isBlocking = false,
                source = "",
                now = at(2026, 1, 9, 10, 0),
                suppression = null
            )
        )
    }

    @Test
    fun keyUnblockOfManualSessionDoesNotSuppress() {
        val schedule = workHours()
        assertNull(
            ScheduleTick.suppressionAfterKeyUnblock(
                source = "key",
                schedules = listOf(schedule),
                now = at(2026, 1, 9, 10, 0)
            )
        )
    }

    @Test
    fun windowEndMsSameDay() {
        val schedule = workHours()
        val now = at(2026, 1, 9, 10, 0)
        val end = at(2026, 1, 9, 17, 0)
        assertEquals(end.timeInMillis, ScheduleTick.windowEndMs(schedule, now))
    }

    @Test
    fun windowEndMsOvernightBeforeMidnight() {
        val schedule = BlockSchedule(
            id = "sleep",
            name = "Sleep",
            weekdays = setOf(Calendar.MONDAY),
            startMinute = 22 * 60,
            endMinute = 7 * 60,
            isOn = true
        )
        val now = at(2026, 1, 5, 23, 0) // Monday 23:00
        val end = at(2026, 1, 6, 7, 0)
        assertEquals(end.timeInMillis, ScheduleTick.windowEndMs(schedule, now))
    }

    @Test
    fun windowEndMsOvernightAfterMidnight() {
        val schedule = BlockSchedule(
            id = "sleep",
            name = "Sleep",
            weekdays = setOf(Calendar.MONDAY),
            startMinute = 22 * 60,
            endMinute = 7 * 60,
            isOn = true
        )
        val now = at(2026, 1, 6, 3, 0) // Tuesday 03:00, still Monday's window
        val end = at(2026, 1, 6, 7, 0)
        assertEquals(end.timeInMillis, ScheduleTick.windowEndMs(schedule, now))
    }
}
