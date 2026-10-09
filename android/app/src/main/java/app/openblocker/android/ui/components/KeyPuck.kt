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
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import app.openblocker.android.domain.FillLevel
import app.openblocker.android.domain.HoldFill
import app.openblocker.android.ui.haptics.HoldHaptics
import app.openblocker.android.ui.theme.KeyPalette
import kotlin.math.cos
import kotlin.math.sin

/**
 * The hero key: a thick matte puck seen from about 50 degrees, matching the
 * iOS SceneKit camera. USDZ/Filament is not used here so Paparazzi and
 * devices without a GL context still render the same key. Drag yaws it.
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
        KeyPuck(
            progress = fill.progress.toFloat(),
            yaw = yaw,
            locked = locked,
            burst = if (locked) maxOf(burst, 0.35f) else burst
        )
    }
}

private val Body = KeyPalette.body
private val Fill = KeyPalette.fill
private val BodyHi = Color(0xFFB8B3AC)
private val BodyMid = Color(0xFF8E8A84)
private val BodyLo = Color(0xFF5E5B56)
private val WallLo = Color(0xFF4A4743)
private val FillHi = Color(0xFF8D8883)
private val FillLo = Color(0xFF5F5C58)

private fun DrawScope.drawPuck(
    progress: Float,
    yaw: Float,
    locked: Boolean,
    burst: Float
) {
    val short = size.minDimension
    val cx = size.width / 2f
    val cy = size.height / 2f - short * 0.03f
    val elevation = Math.toRadians(50.0)
    val radius = short * 0.34f
    val thickness = radius * 0.42f
    val rx = radius
    val ry = (radius * kotlin.math.abs(cos(elevation))).toFloat()
    val wallH = (thickness * kotlin.math.abs(sin(elevation))).toFloat().coerceAtLeast(radius * 0.18f)
    val topCy = cy - wallH * 0.28f
    val botCy = topCy + wallH

    val light = -2.35f + yaw
    val lightX = sin(light)
    val shade = (0.55f + 0.45f * cos(light)).coerceIn(0.25f, 1f)

    drawOval(
        brush = Brush.radialGradient(
            colors = listOf(Color.Black.copy(alpha = 0.38f), Color.Transparent),
            center = Offset(cx + rx * 0.08f, botCy + ry * 0.72f),
            radius = rx * 0.95f
        ),
        topLeft = Offset(cx - rx * 0.72f + rx * 0.1f, botCy + ry * 0.28f),
        size = Size(rx * 1.44f, ry * 0.55f)
    )

    val wall = Path().apply {
        moveTo(cx - rx, topCy)
        lineTo(cx - rx, botCy)
        arcTo(Rect(cx - rx, botCy - ry, cx + rx, botCy + ry), 180f, -180f, false)
        lineTo(cx + rx, topCy)
        arcTo(Rect(cx - rx, topCy - ry, cx + rx, topCy + ry), 0f, 180f, false)
        close()
    }
    val wallLeft = Color(
        red = (BodyLo.red * (0.7f + 0.3f * (1f - shade))).coerceIn(0f, 1f),
        green = (BodyLo.green * (0.7f + 0.3f * (1f - shade))).coerceIn(0f, 1f),
        blue = (BodyLo.blue * (0.7f + 0.3f * (1f - shade))).coerceIn(0f, 1f)
    )
    drawPath(
        wall,
        brush = Brush.horizontalGradient(
            colors = listOf(wallLeft, BodyMid, WallLo),
            startX = cx - rx,
            endX = cx + rx
        )
    )
    drawOval(
        color = WallLo.copy(alpha = 0.95f),
        topLeft = Offset(cx - rx, botCy - ry),
        size = Size(rx * 2f, ry * 2f)
    )

    val top = Path().apply {
        addOval(Rect(cx - rx, topCy - ry, cx + rx, topCy + ry))
    }
    val highlight = Offset(cx + lightX * rx * 0.38f, topCy - 0.42f * ry)
    drawPath(
        top,
        brush = Brush.radialGradient(
            colors = listOf(BodyHi, Body, BodyLo),
            center = highlight,
            radius = rx * 1.45f
        )
    )

    val fillLevel = FillLevel.shaderLevel(progress.toDouble())
    if (fillLevel > FillLevel.hidden) {
        val t = ((fillLevel + 0.02f) / 1.04f).coerceIn(0f, 1f)
        clipPath(top) {
            val bottom = topCy + ry
            val height = (ry * 2f) * t
            drawRect(
                brush = Brush.verticalGradient(
                    listOf(FillHi, Fill, FillLo),
                    startY = bottom - height,
                    endY = bottom
                ),
                topLeft = Offset(cx - rx, bottom - height),
                size = Size(rx * 2f, height + 2f)
            )
            drawLine(
                color = Color.Black.copy(alpha = 0.22f),
                start = Offset(cx - rx, bottom - height),
                end = Offset(cx + rx, bottom - height),
                strokeWidth = 2.2f,
                cap = StrokeCap.Round
            )
        }
    }

    drawPath(
        top,
        brush = Brush.radialGradient(
            colors = listOf(Color.White.copy(alpha = 0.28f), Color.Transparent),
            center = highlight,
            radius = rx * 0.55f
        )
    )
    drawPath(top, color = Color.White.copy(alpha = 0.20f), style = Stroke(width = 3.8f))
    drawPath(top, color = Color.Black.copy(alpha = 0.16f), style = Stroke(width = 1.3f))

    val dimple = Offset(cx + lightX * rx * 0.02f, topCy + ry * 0.02f)
    drawCircle(Color.Black.copy(alpha = 0.22f), rx * 0.07f, dimple + Offset(1.4f, 2.2f))
    drawCircle(Color(0xFF6A6661), rx * 0.058f, dimple)
    drawCircle(Color.White.copy(alpha = 0.28f), rx * 0.02f, dimple + Offset(-rx * 0.018f, -ry * 0.02f))

    if (locked || burst > 0f) {
        val alpha = if (locked) 0.26f + burst * 0.28f else burst * 0.42f
        drawOval(
            color = Fill.copy(alpha = alpha),
            topLeft = Offset(cx - rx * (1.12f + burst * 0.1f), topCy - ry * (1.12f + burst * 0.1f)),
            size = Size(rx * 2f * (1.12f + burst * 0.1f), ry * 2f * (1.12f + burst * 0.1f)),
            style = Stroke(width = 3.2f + burst * 5f)
        )
        drawOval(
            color = Fill.copy(alpha = alpha * 0.4f),
            topLeft = Offset(cx - rx * (1.26f + burst * 0.14f), topCy - ry * (1.26f + burst * 0.14f)),
            size = Size(rx * 2f * (1.26f + burst * 0.14f), ry * 2f * (1.26f + burst * 0.14f)),
            style = Stroke(width = 2f)
        )
    }
}
