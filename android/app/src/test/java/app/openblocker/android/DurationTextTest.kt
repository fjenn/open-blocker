package app.openblocker.android

import app.openblocker.android.domain.DurationText
import org.junit.Assert.assertEquals
import org.junit.Test

class DurationTextTest {
    @Test
    fun hoursMinutesMatchesIos() {
        assertEquals("0h 0m", DurationText.hoursMinutes(0))
        assertEquals("0h 0m", DurationText.hoursMinutes(59))
        assertEquals("3h 7m", DurationText.hoursMinutes((3 * 3600 + 7 * 60 + 30).toLong()))
        assertEquals("0h 0m", DurationText.hoursMinutes(-5))
    }

    @Test
    fun clockOmitsHoursUnderAnHour() {
        assertEquals("30m 03s", DurationText.clock(30 * 60 + 3))
        assertEquals("1h 05m 09s", DurationText.clock(3600 + 5 * 60 + 9))
    }
}
