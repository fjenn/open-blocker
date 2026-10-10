package app.openblocker.android.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect
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
import app.openblocker.android.ui.theme.Motion
import app.openblocker.android.ui.theme.obColors

/**
 * Offline Blender render of KeyModel.glb (see android/tools/render_key.py).
 * Idle and fill sprites share the iOS camera. Hold reveals the fill sprite
 * from the bottom with a clip. Once locked the key returns to the idle body
 * (iOS keeps the lighter puck; the liquid is only while holding).
 */
@Composable
fun KeyPuck(
    progress: Float,
    yaw: Float,
    locked: Boolean,
    burst: Float = 0f,
    holding: Boolean = false,
    modifier: Modifier = Modifier
) {
    KeySprite(progress = progress, yaw = yaw, locked = locked, burst = burst, holding = holding, modifier = modifier)
}

@Composable
fun KeyModelScene(
    progress: Float,
    yaw: Float,
    locked: Boolean,
    burst: Float = 0f,
    modifier: Modifier = Modifier
) {
    KeyPuck(progress, yaw, locked, burst, holding = progress > 0.02f && !locked, modifier = modifier)
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
                    } else if (locked) {
                        haptics.fail()
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
        val press = animateFloatAsState(
            targetValue = if (fill.isHolding && !locked) Motion.pressedScale else 1f,
            animationSpec = Motion.quick,
            label = "key-press"
        )
        val pop = animateFloatAsState(
            targetValue = if (locked && burst > 0.7f) Motion.lockPopScale else 1f,
            animationSpec = Motion.pop,
            label = "key-pop"
        )
        KeyModelScene(
            progress = fill.progress.toFloat(),
            yaw = yaw,
            locked = locked,
            burst = burst,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    val s = press.value * pop.value
                    scaleX = s
                    scaleY = s
                }
        )
    }
}

@Composable
private fun KeySprite(
    progress: Float,
    yaw: Float,
    locked: Boolean,
    burst: Float,
    @Suppress("UNUSED_PARAMETER") holding: Boolean,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    val fillLevel = FillLevel.shaderLevel(progress.toDouble())
    val reveal = when {
        locked -> 0f
        fillLevel <= FillLevel.hidden -> 0f
        else -> ((fillLevel + 0.02f) / 1.04f).coerceIn(0f, 1f)
    }
    val shadowAlpha = if (colors.isDark) 0.55f else 0.20f
    val idleFilter = ColorFilter.colorMatrix(
        ColorMatrix(
            floatArrayOf(
                0.95f, 0f, 0f, 0f, 0f,
                0f, 0.93f, 0f, 0f, 0f,
                0f, 0f, 0.90f, 0f, 0f,
                0f, 0f, 0f, 1f, 0f
            )
        )
    )

    Box(modifier.fillMaxSize().testTag("key_view")) {
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
        val idle = painterResource(KeySpin.idleFrame(LocalContext.current, yaw))
        val fill = painterResource(KeySpin.fillFrame(LocalContext.current, yaw))
        Image(
            painter = idle,
            contentDescription = null,
            contentScale = ContentScale.Fit,
            colorFilter = idleFilter,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    scaleX = 0.96f
                    scaleY = 0.96f
                }
        )
        if (reveal > 0f) {
            Image(
                painter = fill,
                contentDescription = null,
                contentScale = ContentScale.Fit,
                colorFilter = ColorFilter.colorMatrix(
                    ColorMatrix(
                        floatArrayOf(
                            0.62f, 0f, 0f, 0f, 0f,
                            0f, 0.60f, 0f, 0f, 0f,
                            0f, 0f, 0.58f, 0f, 0f,
                            0f, 0f, 0f, 1f, 0f
                        )
                    )
                ),
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer {
                        scaleX = 0.96f
                        scaleY = 0.96f
                    }
                    .drawWithContent {
                        val top = size.height * (1f - reveal)
                        clipRect(left = 0f, top = top, right = size.width, bottom = size.height) {
                            this@drawWithContent.drawContent()
                        }
                    }
            )
        }
        Canvas(Modifier.fillMaxSize()) {
            drawBurst(burst, locked)
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
