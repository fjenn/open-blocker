package app.openblocker.android.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalInspectionMode
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import app.openblocker.android.domain.FillLevel
import app.openblocker.android.domain.HoldFill
import app.openblocker.android.ui.haptics.HoldHaptics
import app.openblocker.android.ui.theme.KeyPalette
import kotlin.math.cos
import kotlin.math.sin

/**
 * Static puck used by Paparazzi and as a last-resort fallback when Filament
 * cannot start. The running app uses [KeyModelScene] (KeyModel.glb).
 */
@Composable
fun KeyPuck(
    progress: Float,
    yaw: Float,
    locked: Boolean,
    burst: Float = 0f,
    modifier: Modifier = Modifier
) {
    Canvas(modifier.fillMaxSize().testTag("key_view")) {
        drawPuck(progress, yaw, locked, burst)
    }
}

/**
 * Real-app key: iPhone KeyModel.glb through Filament, plus the same
 * screen-space gray fill and lock burst as iOS KeyView3D. Paparazzi keeps
 * the Canvas [KeyPuck] because layoutlib has no GL / native Filament.
 */
@Composable
fun KeyModelScene(
    progress: Float,
    yaw: Float,
    locked: Boolean,
    burst: Float = 0f,
    modifier: Modifier = Modifier
) {
    val inspection = LocalInspectionMode.current
    var failed by remember { mutableStateOf(false) }
    if (inspection || failed) {
        KeyPuck(progress, yaw, locked, burst, modifier)
        return
    }
    Box(modifier.fillMaxSize().testTag("key_view")) {
        KeyModel3D(yaw = yaw, onFailed = { failed = true }, modifier = Modifier.fillMaxSize())
        Canvas(Modifier.fillMaxSize()) {
            drawFillAndBurst(progress, yaw, locked, burst)
        }
    }
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

private val Body = KeyPalette.body
private val Fill = KeyPalette.fill
private val BodyHi = Color(0xFFA8A49E)
private val BodyLo = Color(0xFF8A8680)
private val Rim = Color(0xFF7E7A74)
private val FillHi = Color(0xFF8A8681)
private val FillLo = Color(0xFF6E6A65)

private data class PuckGeom(
    val cx: Float,
    val topCy: Float,
    val rx: Float,
    val ry: Float,
    val botCy: Float
)

private fun DrawScope.puckGeom(): PuckGeom {
    val short = size.minDimension
    val cx = size.width / 2f
    val cy = size.height / 2f + short * 0.01f
    val elevation = Math.toRadians(62.0)
    val radius = short * 0.47f
    val thickness = radius * 0.18f
    val rx = radius
    val ry = (radius * kotlin.math.abs(cos(elevation))).toFloat().coerceAtLeast(radius * 0.86f)
    val wallH = (thickness * kotlin.math.abs(sin(elevation))).toFloat().coerceAtMost(radius * 0.10f)
    val topCy = cy - wallH * 0.35f
    return PuckGeom(cx, topCy, rx, ry, topCy + wallH)
}

private fun DrawScope.drawPuck(
    progress: Float,
    yaw: Float,
    locked: Boolean,
    burst: Float
) {
    val g = puckGeom()
    val light = -2.2f + yaw
    val lightX = sin(light)

    drawOval(
        brush = Brush.radialGradient(
            colors = listOf(Color.Black.copy(alpha = 0.22f), Color.Transparent),
            center = Offset(g.cx + g.rx * 0.04f, g.botCy + g.ry * 0.62f),
            radius = g.rx * 1.05f
        ),
        topLeft = Offset(g.cx - g.rx * 0.78f, g.botCy + g.ry * 0.18f),
        size = Size(g.rx * 1.56f, g.ry * 0.62f)
    )

    val wall = Path().apply {
        moveTo(g.cx - g.rx, g.topCy)
        lineTo(g.cx - g.rx, g.botCy)
        arcTo(Rect(g.cx - g.rx, g.botCy - g.ry, g.cx + g.rx, g.botCy + g.ry), 180f, -180f, false)
        lineTo(g.cx + g.rx, g.topCy)
        arcTo(Rect(g.cx - g.rx, g.topCy - g.ry, g.cx + g.rx, g.topCy + g.ry), 0f, 180f, false)
        close()
    }
    drawPath(wall, Rim.copy(alpha = 0.55f))

    val top = Path().apply {
        addOval(Rect(g.cx - g.rx, g.topCy - g.ry, g.cx + g.rx, g.topCy + g.ry))
    }
    val highlight = Offset(g.cx + lightX * g.rx * 0.22f, g.topCy - 0.28f * g.ry)
    drawPath(
        top,
        brush = Brush.radialGradient(
            colors = listOf(BodyHi, Body, BodyLo),
            center = highlight,
            radius = g.rx * 1.55f
        )
    )

    drawFillOnTop(top, g, progress)

    drawPath(
        top,
        brush = Brush.radialGradient(
            colors = listOf(Color.White.copy(alpha = 0.05f), Color.Transparent),
            center = highlight,
            radius = g.rx * 0.55f
        )
    )

    val dimple = Offset(g.cx + lightX * g.rx * 0.008f, g.topCy + g.ry * 0.01f)
    drawCircle(Color.Black.copy(alpha = 0.16f), g.rx * 0.055f, dimple, style = Stroke(width = 2.1f))
    drawCircle(Color.Black.copy(alpha = 0.06f), g.rx * 0.038f, dimple)

    drawBurst(g.cx, g.topCy, g.rx, g.ry, locked, burst)
}

private fun DrawScope.drawFillOnTop(top: Path, g: PuckGeom, progress: Float) {
    val fillLevel = FillLevel.shaderLevel(progress.toDouble())
    if (fillLevel <= FillLevel.hidden) return
    val t = ((fillLevel + 0.02f) / 1.04f).coerceIn(0f, 1f)
    clipPath(top) {
        val bottom = g.topCy + g.ry
        val height = (g.ry * 2f) * t
        drawRect(
            brush = Brush.verticalGradient(
                listOf(FillHi, Fill, FillLo),
                startY = bottom - height,
                endY = bottom
            ),
            topLeft = Offset(g.cx - g.rx, bottom - height),
            size = Size(g.rx * 2f, height + 2f)
        )
        drawLine(
            color = Color.Black.copy(alpha = 0.16f),
            start = Offset(g.cx - g.rx, bottom - height),
            end = Offset(g.cx + g.rx, bottom - height),
            strokeWidth = 1.6f,
            cap = StrokeCap.Round
        )
    }
}

private fun DrawScope.drawFillAndBurst(
    progress: Float,
    @Suppress("UNUSED_PARAMETER") yaw: Float,
    locked: Boolean,
    burst: Float
) {
    val g = puckGeom()
    val top = Path().apply {
        addOval(Rect(g.cx - g.rx, g.topCy - g.ry, g.cx + g.rx, g.topCy + g.ry))
    }
    drawFillOnTop(top, g, progress)
    drawBurst(g.cx, g.topCy, g.rx, g.ry, locked, burst)
}

private fun DrawScope.drawBurst(
    cx: Float,
    topCy: Float,
    rx: Float,
    ry: Float,
    locked: Boolean,
    burst: Float
) {
    if (!locked && burst <= 0.04f) return
    val alpha = if (locked) 0.10f + burst * 0.12f else burst * 0.18f
    drawOval(
        color = Fill.copy(alpha = alpha),
        topLeft = Offset(cx - rx * (1.08f + burst * 0.08f), topCy - ry * (1.08f + burst * 0.08f)),
        size = Size(rx * 2f * (1.08f + burst * 0.08f), ry * 2f * (1.08f + burst * 0.08f)),
        style = Stroke(width = 1.6f + burst * 3.5f)
    )
}
