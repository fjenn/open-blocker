package app.openblocker.android.ui.theme

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween

/** Matches iOS Theme.Motion: standard / quick / pop / fade. */
object Motion {
    val fade = tween<Float>(durationMillis = 200, easing = EaseInOut)
    val quick = tween<Float>(durationMillis = 250, easing = EaseOut)
    val standard = spring<Float>(
        dampingRatio = 1f,
        stiffness = 195f
    )
    val pop = spring<Float>(
        dampingRatio = 0.55f,
        stiffness = 322f,
        visibilityThreshold = Spring.DefaultDisplacementThreshold
    )
    const val lockBurstMs = 700
    const val toastMs = 2800L
    const val keySpinSeconds = 30f
    const val pressedScale = 0.92f
    const val lockPopScale = 1.05f
}
