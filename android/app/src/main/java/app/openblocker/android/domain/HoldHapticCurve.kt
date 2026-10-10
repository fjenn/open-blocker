package app.openblocker.android.domain

/**
 * The shape of the hold-to-block haptic build-up, as pure numbers.
 * Progress runs 0...1 over [HoldFill.fillDuration].
 */
object HoldHapticCurve {
    fun intensity(progress: Double): Double = 0.2 + 0.8 * ease(progress)

    fun sharpness(progress: Double): Double = -0.25 + 0.6 * ease(progress)

    fun tapInterval(progress: Double): Double = 0.42 - 0.35 * ease(progress)

    /** Absolute seconds from press, matching iOS HoldHaptics (21 accelerating taps). */
    val tapTimes: List<Double> = listOf(
        0.12, 0.54, 0.95, 1.36, 1.74, 2.10, 2.44, 2.75, 3.03, 3.29,
        3.53, 3.75, 3.94, 4.12, 4.27, 4.41, 4.54, 4.66, 4.76, 4.86, 4.94
    )

    val tapProgress: List<Double> by lazy {
        tapTimes.map { it / HoldFill.fillDuration }
    }

    private fun ease(progress: Double): Double {
        val p = progress.coerceIn(0.0, 1.0)
        return p * p * (1.6 - 0.6 * p)
    }
}
