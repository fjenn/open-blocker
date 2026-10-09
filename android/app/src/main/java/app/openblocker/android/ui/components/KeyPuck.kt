package app.openblocker.android.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import app.openblocker.android.R
import app.openblocker.android.domain.FillLevel
import app.openblocker.android.domain.HoldFill
import app.openblocker.android.ui.haptics.HoldHaptics
import app.openblocker.android.ui.theme.KeyPalette
import app.openblocker.android.ui.theme.obColors

/**
 * Offline Blender render of KeyModel.glb (see android/tools/render_key.py).
 * Idle and fill sprites share one camera; hold / blocked reveal the fill
 * sprite from the bottom. Paparazzi and the running app use the same path.
 */
@Composable
fun KeyPuck(
    progress: Float,
    @Suppress("UNUSED_PARAMETER") yaw: Float,
    locked: Boolean,
    burst: Float = 0f,
    modifier: Modifier = Modifier
) {
    KeySprite(progress = progress, locked = locked, burst = burst, modifier = modifier)
}

@Composable
fun KeyModelScene(
    progress: Float,
    yaw: Float,
    locked: Boolean,
    burst: Float = 0f,
    modifier: Modifier = Modifier
) {
    KeyPuck(progress, yaw, locked, burst, modifier)
}

@Composable
fun KeyStage(
    locked: Boolean,
    enabled: Boolean,
    onCompleted: () -> Unit,
    onTap: () -> Unit,
    onHoldWhileLocked: () -> Unit,
    onProgress: (HoldFill) -> Unit = {},
    previewFill: HoldFill? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val view = LocalView.current
    val haptics = remember { HoldHaptics(context, view) }
    val fill = remember { previewFill ?: HoldFill() }
    var tick by remember { mutableIntStateOf(0) }
    var yaw by remember { mutableFloatStateOf(0.18f) }
    var dragging by remember { mutableStateOf(false) }
    var burst by remember { mutableFloatStateOf(if (locked) 0.35f else 0f) }
    var pressStartedAt by remember { mutableLongStateOf(0L) }

    fun publish() {
        tick++
        onProgress(fill.copy())
    }

    LaunchedEffect(locked) {
        fill.applyLocked(locked)
        if (locked) {
            fill.snapToRest()
            burst = 1f
        }
        publish()
    }

    LaunchedEffect(tick, fill.isHolding, fill.isLocked) {
        var last = 0L
        while (!fill.isSettled) {
            withFrameNanos { now ->
                if (last != 0L) {
                    val dt = (now - last) / 1_000_000_000.0
                    fill.step(dt).forEach { event ->
                        when (event) {
                            is HoldFill.Event.Tick -> haptics.step(event.n)
                            HoldFill.Event.COMPLETED -> {
                                haptics.climax()
                                burst = 1f
                                onCompleted()
                            }
                        }
                    }
                    publish()
                }
                last = now
            }
        }
    }

    LaunchedEffect(burst) {
        if (burst <= 0.02f) return@LaunchedEffect
        var last = 0L
        while (burst > 0.02f) {
            withFrameNanos { now ->
                if (last != 0L) {
                    burst = (burst - (now - last) / 1_000_000_000f / 0.7f).coerceAtLeast(0f)
                }
                last = now
            }
        }
    }

    LaunchedEffect(dragging, fill.isHolding) {
        if (dragging || fill.isHolding) return@LaunchedEffect
        var last = 0L
        while (true) {
            withFrameNanos { now ->
                if (last != 0L && !dragging && !fill.isHolding) {
                    yaw += ((now - last) / 1_000_000_000f) * 0.21f
                }
                last = now
            }
        }
    }

    Box(
        modifier.pointerInput(enabled, locked) {
            detectTapGestures(
                onPress = {
                    if (!enabled) return@detectTapGestures
                    pressStartedAt = System.currentTimeMillis()
                    if (locked) {
                        tryAwaitRelease()
                        if (System.currentTimeMillis() - pressStartedAt > 250) onHoldWhileLocked()
                        return@detectTapGestures
                    }
                    if (fill.press()) {
                        haptics.prepare()
                        haptics.beginBuildUp(fill.progress)
                        publish()
                    }
                    tryAwaitRelease()
                    fill.release()
                    haptics.stopBuildUp()
                    publish()
                    if (!dragging && System.currentTimeMillis() - pressStartedAt < 250) {
                        onTap()
                    }
                }
            )
        }.pointerInput(enabled) {
            detectDragGestures(
                onDragStart = {
                    dragging = true
                    fill.release()
                    haptics.stopBuildUp()
                    publish()
                },
                onDragEnd = { dragging = false },
                onDragCancel = { dragging = false },
                onDrag = { change, amount ->
                    change.consume()
                    yaw += amount.x * 0.012f
                }
            )
        }
    ) {
        KeyModelScene(
            progress = fill.progress.toFloat(),
            yaw = yaw,
            locked = locked,
            burst = if (locked) maxOf(burst, 0.35f) else burst
        )
    }
}

@Composable
private fun KeySprite(
    progress: Float,
    locked: Boolean,
    burst: Float,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    val fillLevel = FillLevel.shaderLevel(progress.toDouble())
    val reveal = when {
        locked || progress >= 0.98f -> 1f
        fillLevel <= FillLevel.hidden -> 0f
        else -> ((fillLevel + 0.02f) / 1.04f).coerceIn(0f, 1f)
    }
    val shadowAlpha = if (colors.isDark) 0.55f else 0.20f

    BoxWithConstraints(modifier.fillMaxSize().testTag("key_view"), contentAlignment = Alignment.Center) {
        val frameHeight = maxHeight
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                val w = size.minDimension
                drawOval(
                    brush = Brush.radialGradient(
                        colors = listOf(Color.Black.copy(alpha = shadowAlpha), Color.Transparent),
                        center = Offset(size.width / 2f + w * 0.04f, size.height / 2f + w * 0.30f),
                        radius = w * 0.42f
                    ),
                    topLeft = Offset(size.width / 2f - w * 0.30f + w * 0.04f, size.height / 2f + w * 0.22f),
                    size = Size(w * 0.60f, w * 0.16f)
                )
            }
            Image(
                painter = painterResource(R.drawable.key_idle),
                contentDescription = null,
                contentScale = ContentScale.Fit,
                modifier = Modifier.fillMaxSize()
            )
            if (reveal > 0f) {
                Box(
                    Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .height(frameHeight * reveal)
                        .clipToBounds()
                ) {
                    Image(
                        painter = painterResource(R.drawable.key_fill),
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(frameHeight)
                            .align(Alignment.BottomCenter)
                    )
                }
            }
            Canvas(Modifier.fillMaxSize()) {
                drawBurst(burst, locked)
            }
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawBurst(burst: Float, locked: Boolean) {
    if (!locked && burst <= 0.04f) return
    val w = size.minDimension
    val cx = size.width / 2f
    val cy = size.height / 2f + w * 0.02f
    val rx = w * 0.36f
    val ry = rx * 0.42f
    val alpha = if (locked) 0.10f + burst * 0.12f else burst * 0.18f
    val grow = 1.08f + burst * 0.08f
    drawOval(
        color = KeyPalette.fill.copy(alpha = alpha),
        topLeft = Offset(cx - rx * grow, cy - ry * grow),
        size = Size(rx * 2f * grow, ry * 2f * grow),
        style = Stroke(width = 1.6f + burst * 3.5f)
    )
}
