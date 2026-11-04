package app.openblocker.android.domain

import java.util.Calendar

/**
 * Pure schedule start/end decisions. Mirrors iOS Reconcile: a key unblock
 * during a scheduled window must clear the block and suppress re-arming until
 * that window ends; the next occurrence still starts normally.
 */
object ScheduleTick {

    data class Suppression(val scheduleId: String, val untilMs: Long)

    sealed class Decision {
        data object None : Decision()
        data class Start(val schedule: BlockSchedule) : Decision()
        data object End : Decision()
    }

    const val SOURCE_SCHEDULE = "schedule"

    fun decision(
        schedules: List<BlockSchedule>,
        isBlocking: Boolean,
        source: String,
        now: Calendar,
        suppression: Suppression?
    ): Decision {
        val active = schedules.filter { it.isOn && it.contains(now) }
        val nowMs = now.timeInMillis
        return when {
            active.isNotEmpty() && !isBlocking -> {
                val schedule = active.first()
                if (suppression != null &&
                    suppression.scheduleId == schedule.id &&
                    suppression.untilMs > nowMs
                ) {
                    Decision.None
                } else {
                    Decision.Start(schedule)
                }
            }
            isBlocking &&
                source == SOURCE_SCHEDULE &&
                active.isEmpty() -> Decision.End
            else -> Decision.None
        }
    }

    /** Absolute end of the schedule window that currently contains [now]. */
    fun windowEndMs(schedule: BlockSchedule, now: Calendar): Long {
        val cal = now.clone() as Calendar
        val minute = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        val overnight = schedule.endMinute < schedule.startMinute
        if (overnight && minute >= schedule.startMinute) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        cal.set(Calendar.HOUR_OF_DAY, schedule.endMinute / 60)
        cal.set(Calendar.MINUTE, schedule.endMinute % 60)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    /**
     * After a key ends an active scheduled session, suppress the rest of the
     * current window so [decision] does not immediately Start again.
     */
    fun suppressionAfterKeyUnblock(
        source: String,
        schedules: List<BlockSchedule>,
        now: Calendar
    ): Suppression? {
        if (source != SOURCE_SCHEDULE) return null
        val active = schedules.firstOrNull { it.isOn && it.contains(now) } ?: return null
        return Suppression(active.id, windowEndMs(active, now))
    }
}
