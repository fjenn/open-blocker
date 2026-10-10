package app.openblocker.android

import app.openblocker.android.domain.EmergencyAllowance
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

class EmergencyUnblockTest {
    private val calendar: Calendar = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
        firstDayOfWeek = Calendar.SUNDAY
    }

    private fun date(year: Int, month: Int, day: Int): Date {
        calendar.clear()
        calendar.set(year, month - 1, day, 12, 0, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }

    @Test
    fun fiveEverySixMonths() {
        assertEquals(5, EmergencyAllowance.maxCount)
        assertEquals(6, EmergencyAllowance.periodMonths)
    }

    @Test
    fun resetDateIsSixCalendarMonthsAfterThePeriodStarts() {
        val allowance = EmergencyAllowance.full(date(2026, 10, 8))
        assertEquals(date(2027, 4, 8), allowance.resetDate(calendar))
    }

    @Test
    fun nothingChangesBeforeTheResetDate() {
        val allowance = EmergencyAllowance(remaining = 2, periodStart = date(2026, 10, 8))
        assertEquals(allowance, allowance.renewed(date(2027, 4, 7), calendar))
    }

    @Test
    fun backToFiveWithANewPeriodOnTheResetDate() {
        val allowance = EmergencyAllowance(remaining = 0, periodStart = date(2026, 10, 8))
        val now = date(2027, 4, 8)
        val renewed = allowance.renewed(now, calendar)
        assertEquals(5, renewed.remaining)
        assertEquals(now, renewed.periodStart)
        assertEquals(date(2027, 10, 8), renewed.resetDate(calendar))
    }

    @Test
    fun aNewPeriodStartsWhenTheAppOpensLate() {
        val allowance = EmergencyAllowance(remaining = 1, periodStart = date(2026, 1, 1))
        val now = date(2027, 3, 15)
        assertEquals(EmergencyAllowance.full(now), allowance.renewed(now, calendar))
    }

    @Test
    fun usingOneCountsDownAndStopsAtZero() {
        val start = date(2026, 10, 8)
        assertEquals(4, EmergencyAllowance.full(start).usingOne()?.remaining)
        assertNull(EmergencyAllowance(0, start).usingOne())
    }
}
