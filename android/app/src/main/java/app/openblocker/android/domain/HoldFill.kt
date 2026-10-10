package app.openblocker.android.domain

/**
 * Hold-to-block fill logic. Pure value type so it is unit tested.
 */
data class HoldFill(
    var progress: Double = 0.0,
    var isHolding: Boolean = false,
    var isLocked: Boolean = false,
    var ticksFired: Int = 0,
    var snapsWhenIdle: Boolean = false
) {
    sealed class Event {
        data object COMPLETED : Event()
        data class Tick(val n: Int) : Event()
    }

    val restingProgress: Double get() = if (isLocked) 1.0 else 0.0
    val isSettled: Boolean get() = !isHolding && progress == restingProgress

    fun press(): Boolean {
        if (isLocked) return false
        isHolding = true
        return true
    }

    fun release() {
        isHolding = false
    }

    fun applyLocked(locked: Boolean) {
        isLocked = locked
        if (locked) isHolding = false
    }

    fun snapToRest() {
        isHolding = false
        progress = restingProgress
        ticksFired = if (isLocked) tickCount else 0
    }

    fun step(dt: Double): List<Event> {
        if (dt <= 0) return emptyList()
        if (isHolding) return fill(dt)
        val target = restingProgress
        progress = when {
            snapsWhenIdle -> target
            progress < target -> minOf(target, progress + dt / settleDuration)
            progress > target -> maxOf(target, progress - dt / drainDuration)
            else -> progress
        }
        ticksFired = minOf(ticksFired, (progress * tickCount).toInt())
        return emptyList()
    }

    private fun fill(dt: Double): List<Event> {
        val events = mutableListOf<Event>()
        progress = minOf(1.0, progress + dt / fillDuration)
        val reached = (progress * tickCount).toInt()
        while (ticksFired < minOf(reached, tickCount - 1)) {
            ticksFired += 1
            events += Event.Tick(ticksFired)
        }
        if (progress >= 1.0) {
            isHolding = false
            ticksFired = tickCount
            events += Event.COMPLETED
        }
        return events
    }

    companion object {
        const val fillDuration = 5.0
        const val drainDuration = 0.6
        const val settleDuration = 0.6
        const val tickCount = 10
    }
}

/** Maps 0...1 hold progress to the fill line. Empty hides the fill; full overshoots. */
object FillLevel {
    const val hidden = -1f

    fun shaderLevel(progress: Double): Float {
        if (progress <= 0.001) return hidden
        return (-0.02 + minOf(progress, 1.0) * 1.04).toFloat()
    }
}
