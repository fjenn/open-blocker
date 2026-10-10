package app.openblocker.android.ui.components

import android.content.Context
import app.openblocker.android.R
import kotlin.math.PI

/**
 * Idle spin: 12 Blender frames of KeyModel.glb over 30s, same camera as iOS.
 * Missing frames fall back to the still idle/fill sprites.
 */
object KeySpin {
    const val COUNT = 12

    fun idleFrame(context: Context, yaw: Float): Int = frame(context, "key_spin", yaw, R.drawable.key_idle)

    fun fillFrame(context: Context, yaw: Float): Int = frame(context, "key_fill_spin", yaw, R.drawable.key_fill)

    private fun frame(context: Context, prefix: String, yaw: Float, fallback: Int): Int {
        val turns = ((yaw / (2f * PI.toFloat())) % 1f + 1f) % 1f
        val index = (turns * COUNT).toInt().coerceIn(0, COUNT - 1)
        val id = context.resources.getIdentifier(
            "%s_%02d".format(prefix, index),
            "drawable",
            context.packageName
        )
        return if (id != 0) id else fallback
    }
}
