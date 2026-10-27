package app.openblocker.android.domain

/**
 * Shared hold-to-block press rules. Movement inside the pressed view
 * (plus slack) must not reset the fill.
 */
object HoldPressTracking {
    /** Extra space around the view so a finger can drift without cancelling. */
    const val EXIT_TOLERANCE_DP = 36f
    /** Short presses that travel farther than this are a spin, not a tap. */
    const val TAP_MOVE_LIMIT_DP = 16f
    const val TAP_LIMIT_MS = 250L

    fun isInsideHoldArea(
        x: Float,
        y: Float,
        width: Float,
        height: Float,
        tolerance: Float
    ): Boolean {
        if (width <= 0f || height <= 0f) return true
        return x >= -tolerance &&
            y >= -tolerance &&
            x <= width + tolerance &&
            y <= height + tolerance
    }

    fun movement(dx: Float, dy: Float): Float = kotlin.math.hypot(dx, dy)

    fun isShortTap(heldMs: Long, moved: Float, tapMoveLimit: Float): Boolean {
        return heldMs < TAP_LIMIT_MS && moved < tapMoveLimit
    }
}
