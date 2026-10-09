package app.openblocker.android.domain

/** The two ways the app writes a length of time. */
object DurationText {
    /** "2h 5m". Used for totals (today, averages, day cards). */
    fun hoursMinutes(seconds: Long): String {
        val total = maxOf(0, seconds.toInt())
        return "${total / 3600}h ${(total % 3600) / 60}m"
    }

    /** "2h 05m 09s", or "5m 09s" under an hour. Live blocked timer. */
    fun clock(seconds: Long): String {
        val total = maxOf(0, seconds.toInt())
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return if (h > 0) {
            String.format("%dh %02dm %02ds", h, m, s)
        } else {
            String.format("%dm %02ds", m, s)
        }
    }
}
