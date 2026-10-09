package app.openblocker.android.domain

/**
 * The shape of the hold-to-block haptic build-up, as pure numbers.
 * Progress runs 0...1 over [HoldFill.fillDuration].
 */
object HoldHapticCurve {
    fun intensity(progress: Double): Double = 0.2 + 0.8 * ease(progress)

    fun sharpness(progress: Double): Double = -0.25 + 0.6 * ease(progress)

    fun tapInterval(progress: Double): Double = 0.42 - 0.35 * ease(progress)

    val tapProgress: List<Double> by lazy {
        val taps = mutableListOf<Double>()
        var time = 0.12
        val duration = HoldFill.fillDuration
        while (time < duration) {
            taps += time / duration
            time += tapInterval(time / duration)
        }
        taps
    }

    private fun ease(progress: Double): Double {
        val p = progress.coerceIn(0.0, 1.0)
        return p * p * (1.6 - 0.6 * p)
    }
}
