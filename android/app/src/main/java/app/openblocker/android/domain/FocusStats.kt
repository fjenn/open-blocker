package app.openblocker.android.domain

data class FocusInterval(val startMs: Long, val endMs: Long)

object FocusStats {
    data class Day(val durationMs: Long, val sessions: Int)

    fun onDay(
        dayStartMs: Long,
        intervals: List<FocusInterval>,
        nowMs: Long,
        dayLengthMs: Long = 86_400_000L
    ): Day {
        val end = minOf(nowMs, dayStartMs + dayLengthMs)
        if (end <= dayStartMs) return Day(0, 0)
        var duration = 0L
        var sessions = 0
        for (interval in intervals) {
            val overlapStart = maxOf(interval.startMs, dayStartMs)
            val overlapEnd = minOf(interval.endMs, end)
            if (overlapStart < overlapEnd) {
                duration += overlapEnd - overlapStart
                sessions += 1
            }
        }
        return Day(duration, sessions)
    }

    fun weekDurations(
        weekStartMs: Long,
        intervals: List<FocusInterval>,
        nowMs: Long
    ): List<Long> = (0 until 7).map { offset ->
        onDay(weekStartMs + offset * 86_400_000L, intervals, nowMs).durationMs
    }
}
