package app.openblocker.android.ui.haptics

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import android.view.View

/** One-shot success / error / selection pulses (iOS UINotification / UISelection). */
object AppHaptics {
    fun success(context: Context, view: View? = null) {
        if (Build.VERSION.SDK_INT >= 29) {
            view?.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
        }
        pulse(context, 18, 220)
    }

    fun error(context: Context, view: View? = null) {
        if (Build.VERSION.SDK_INT >= 30) {
            view?.performHapticFeedback(HapticFeedbackConstants.REJECT)
        }
        pulse(context, 40, 255)
    }

    fun selection(view: View? = null) {
        view?.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
    }

    private fun pulse(context: Context, ms: Long, amp: Int) {
        val vibrator = vibratorOf(context) ?: return
        if (Build.VERSION.SDK_INT >= 26) {
            vibrator.vibrate(VibrationEffect.createOneShot(ms, amp))
        }
    }

    private fun vibratorOf(context: Context): Vibrator? {
        return if (Build.VERSION.SDK_INT >= 31) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Vibrator::class.java)
        }
    }
}
