package app.openblocker.android.domain

import java.util.Calendar
import java.util.UUID

data class BlockSchedule(
    val id: String = UUID.randomUUID().toString(),
    var name: String,
    var weekdays: Set<Int>,
    var startMinute: Int,
    var endMinute: Int,
    var modeId: String? = null,
    var isOn: Boolean = false
) {
    val timeRangeString: String
        get() = "${formatClock(startMinute)} - ${formatClock(endMinute)}"

    val daysString: String
        get() {
            if (weekdays.size == 7) return "Every day"
            val sorted = weekdays.sorted().map { day -> if (day == 1) 0 else (day - 1) % 7 }
            if (sorted.toSet() == setOf(0, 6)) return "Weekends"
            if (sorted.toSet() == setOf(1, 2, 3, 4, 5)) return "Weekdays"
            val names = listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
            return sorted.joinToString(", ") { names[it] }
        }

    val olderThan15Minutes: Boolean
        get() {
            val duration = if (endMinute >= startMinute) {
                endMinute - startMinute
            } else {
                (24 * 60 - startMinute) + endMinute
            }
            return duration >= 15
        }

    fun contains(now: Calendar): Boolean {
        val weekday = now.get(Calendar.DAY_OF_WEEK)
        val minute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val overnight = endMinute < startMinute
        val inWindow = if (!overnight) {
            minute in startMinute until endMinute
        } else {
            minute >= startMinute || minute < endMinute
        }
        if (!inWindow) return false
        if (!overnight) return weekdays.contains(weekday)
        // Overnight: the window belongs to the weekday of the start.
        val startWeekday = if (minute < endMinute) {
            val prev = weekday - 1
            if (prev < 1) 7 else prev
        } else {
            weekday
        }
        return weekdays.contains(startWeekday)
    }

    fun nextStartDate(now: Calendar = Calendar.getInstance()): Calendar? {
        if (weekdays.isEmpty()) return null
        val startOfToday = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        for (offset in 0..7) {
            val day = (startOfToday.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, offset) }
            val weekday = day.get(Calendar.DAY_OF_WEEK)
            if (!weekdays.contains(weekday)) continue
            val start = (day.clone() as Calendar).apply { add(Calendar.MINUTE, startMinute) }
            if (start.timeInMillis > now.timeInMillis) return start
        }
        return null
    }

    fun nextRunString(now: Calendar = Calendar.getInstance()): String {
        if (!isOn) return "Off"
        val date = nextStartDate(now) ?: return "No next run"
        val weekday = date.get(Calendar.DAY_OF_WEEK)
        val names = listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
        val day = names[(weekday - 1 + 7) % 7]
        return "Next: $day ${formatClock(startMinute)}"
    }

    companion object {
        fun formatClock(minute: Int): String {
            val hour = minute / 60
            val min = minute % 60
            val period = if (hour >= 12) "PM" else "AM"
            val displayHour = when {
                hour == 0 -> 12
                hour > 12 -> hour - 12
                else -> hour
            }
            return String.format("%d:%02d %s", displayHour, min, period)
        }
    }
}
