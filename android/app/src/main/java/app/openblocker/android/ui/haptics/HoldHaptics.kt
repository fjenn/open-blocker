package app.openblocker.android.ui.haptics

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import android.view.View
import app.openblocker.android.domain.HoldFill
import app.openblocker.android.domain.HoldHapticCurve
import kotlin.math.roundToInt

/**
 * Hold-to-block haptics: a rising composition of ticks, then a lock burst.
 * Uses VibrationEffect.Composition when the device has it, amplitude
 * waveforms next, then HapticFeedbackConstants.
 */
class HoldHaptics(private val context: Context, private val view: View? = null) {
    private val vibrator: Vibrator? = vibratorOf(context)
    private var playing = false

    fun prepare() {
        if (Build.VERSION.SDK_INT >= 31) {
            vibrator?.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK))
        }
    }

    fun beginBuildUp(progress: Double) {
        stopBuildUp()
        playing = true
        val remaining = HoldHapticCurve.tapProgress.filter { it >= progress }
        if (remaining.isEmpty()) return
        when {
            supportsComposition() -> playComposition(progress, remaining)
            supportsWaveform() -> playWaveform(progress)
            else -> view?.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
        }
    }

    fun step(tick: Int) {
        if (supportsComposition() || supportsWaveform()) return
        val progress = tick.toDouble() / HoldFill.tickCount
        val strength = HoldHapticCurve.intensity(progress)
        val constant = when {
            strength < 0.4 -> HapticFeedbackConstants.CLOCK_TICK
            strength < 0.7 -> HapticFeedbackConstants.KEYBOARD_TAP
            else -> HapticFeedbackConstants.CONTEXT_CLICK
        }
        view?.performHapticFeedback(constant)
    }

    fun stopBuildUp() {
        playing = false
        vibrator?.cancel()
    }

    fun climax() {
        stopBuildUp()
        when {
            supportsComposition() -> playClimaxComposition()
            supportsWaveform() -> playClimaxWaveform()
            else -> {
                view?.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                view?.postDelayed({
                    view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
                }, 90)
            }
        }
    }

    fun fail() {
        stopBuildUp()
        view?.performHapticFeedback(HapticFeedbackConstants.REJECT)
    }

    private fun playComposition(start: Double, taps: List<Double>) {
        if (Build.VERSION.SDK_INT < 30) return
        val duration = HoldFill.fillDuration
        val startTime = start.coerceIn(0.0, 1.0) * duration
        val builder = VibrationEffect.startComposition()
        var last = 0.0
        taps.forEach { p ->
            val at = p * duration - startTime
            if (at < 0) return@forEach
            val delay = ((at - last) * 1000).roundToInt().coerceAtLeast(0)
            val primitive = when {
                p < 0.28 && Build.VERSION.SDK_INT >= 31 -> VibrationEffect.Composition.PRIMITIVE_LOW_TICK
                p < 0.62 -> VibrationEffect.Composition.PRIMITIVE_TICK
                p < 0.85 -> VibrationEffect.Composition.PRIMITIVE_CLICK
                Build.VERSION.SDK_INT >= 31 -> VibrationEffect.Composition.PRIMITIVE_THUD
                else -> VibrationEffect.Composition.PRIMITIVE_CLICK
            }
            val scale = HoldHapticCurve.intensity(p).toFloat().coerceIn(0.1f, 1f)
            try {
                builder.addPrimitive(primitive, scale, delay)
            } catch (_: IllegalArgumentException) {
                builder.addPrimitive(VibrationEffect.Composition.PRIMITIVE_TICK, scale, delay)
            }
            last = at
        }
        try {
            vibrator?.vibrate(builder.compose())
        } catch (_: Exception) {
            playWaveform(start)
        }
    }

    private fun playClimaxComposition() {
        if (Build.VERSION.SDK_INT < 30) return
        val builder = VibrationEffect.startComposition()
        try {
            builder.addPrimitive(VibrationEffect.Composition.PRIMITIVE_CLICK, 1f, 0)
            builder.addPrimitive(VibrationEffect.Composition.PRIMITIVE_CLICK, 0.85f, 12)
            if (Build.VERSION.SDK_INT >= 31) {
                builder.addPrimitive(VibrationEffect.Composition.PRIMITIVE_THUD, 1f, 20)
                builder.addPrimitive(VibrationEffect.Composition.PRIMITIVE_QUICK_FALL, 0.8f, 40)
            } else {
                builder.addPrimitive(VibrationEffect.Composition.PRIMITIVE_CLICK, 1f, 30)
            }
            vibrator?.vibrate(builder.compose())
        } catch (_: Exception) {
            playClimaxWaveform()
        }
    }

    private fun playWaveform(start: Double) {
        if (Build.VERSION.SDK_INT < 26) return
        val duration = HoldFill.fillDuration
        val startTime = start.coerceIn(0.0, 1.0) * duration
        val remainingMs = ((duration - startTime) * 1000).toLong().coerceAtLeast(50)
        val steps = 16
        val timings = LongArray(steps) { remainingMs / steps }
        val amps = IntArray(steps) { i ->
            val p = start + (1.0 - start) * i / (steps - 1)
            (HoldHapticCurve.intensity(p) * 255).roundToInt().coerceIn(1, 255)
        }
        vibrator?.vibrate(VibrationEffect.createWaveform(timings, amps, -1))
    }

    private fun playClimaxWaveform() {
        if (Build.VERSION.SDK_INT < 26) return
        val timings = longArrayOf(0, 18, 12, 28, 80, 140, 180)
        val amps = intArrayOf(255, 0, 220, 0, 180, 80, 0)
        vibrator?.vibrate(VibrationEffect.createWaveform(timings, amps, -1))
    }

    private fun supportsComposition(): Boolean {
        if (Build.VERSION.SDK_INT < 30) return false
        val v = vibrator ?: return false
        return if (Build.VERSION.SDK_INT >= 31) {
            v.areAllPrimitivesSupported(
                VibrationEffect.Composition.PRIMITIVE_TICK,
                VibrationEffect.Composition.PRIMITIVE_CLICK
            )
        } else {
            true
        }
    }

    private fun supportsWaveform(): Boolean {
        return Build.VERSION.SDK_INT >= 26 && vibrator?.hasVibrator() == true
    }

    companion object {
        private fun vibratorOf(context: Context): Vibrator? {
            return if (Build.VERSION.SDK_INT >= 31) {
                context.getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Vibrator::class.java)
            }
        }
    }
}
