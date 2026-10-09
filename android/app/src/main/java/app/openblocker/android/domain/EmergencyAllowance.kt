package app.openblocker.android.domain

import java.util.Calendar
import java.util.Date

/**
 * Five emergency unblocks per six-month period. When the period runs out
 * the allowance goes back to five and a new period starts.
 */
data class EmergencyAllowance(
    val remaining: Int,
    val periodStart: Date
) {
    fun resetDate(calendar: Calendar = Calendar.getInstance()): Date {
        val cal = calendar.clone() as Calendar
        cal.time = periodStart
        cal.add(Calendar.MONTH, periodMonths)
        return cal.time
    }

    fun renewed(at: Date, calendar: Calendar = Calendar.getInstance()): EmergencyAllowance {
        return if (at.time >= resetDate(calendar).time) full(startingAt = at) else this
    }

    fun usingOne(): EmergencyAllowance? {
        return if (remaining > 0) copy(remaining = remaining - 1) else null
    }

    companion object {
        const val maxCount = 5
        const val periodMonths = 6

        fun full(startingAt: Date): EmergencyAllowance =
            EmergencyAllowance(remaining = maxCount, periodStart = startingAt)
    }
}
