package app.openblocker.android.ui.components

import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import app.openblocker.android.ui.theme.KeyPalette
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive

/**
 * Interactive key with hold-to-fill: press and hold for 5 seconds to lock.
 * The key is a warm gray circle that fills with a darker gray as you hold.
 * Includes build-up haptics matching iOS.
 */
@Composable
fun KeyView(
    isLocked: Boolean,
    isEnabled: Boolean,
    onTap: () -> Unit,
    onCompleted: () -> Unit,
    modifier: Modifier = Modifier
) {
    val view = LocalView.current
    var isHolding by remember { mutableStateOf(false) }
    var progress by remember { mutableFloatStateOf(0f) }
    val scale by animateFloatAsState(
        targetValue = if (isHolding && !isLocked) 0.92f else 1f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy),
        label = "key_scale"
    )
    
    // Hold-to-fill timer
    LaunchedEffect(isHolding, isLocked) {
        if (isHolding && !isLocked) {
            val startTime = System.currentTimeMillis()
            val fillDuration = 5000L // 5 seconds
            
            while (isActive && isHolding && !isLocked) {
                val elapsed = System.currentTimeMillis() - startTime
                progress = (elapsed.toFloat() / fillDuration).coerceIn(0f, 1f)
                
                // Haptic feedback at milestones
                if (progress >= 0.1f * ((progress * 10).toInt())) {
                    performHaptic(view, progress)
                }
                
                if (progress >= 1f) {
                    // Completed
                    performLockHaptic(view)
                    onCompleted()
                    break
                }
                
                delay(16) // ~60fps
            }
        } else {
            // Drain animation when released
            while (isActive && progress > 0f && !isLocked) {
                progress = (progress - 0.016f / 0.6f).coerceAtLeast(0f) // 0.6s drain
                delay(16)
            }
            if (isLocked) {
                progress = 1f
            }
        }
    }
    
    Box(
        modifier = modifier
            .size(280.dp)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .pointerInput(isEnabled, isLocked) {
                if (!isEnabled) return@pointerInput
                
                detectTapGestures(
                    onPress = {
                        if (!isLocked) {
                            isHolding = true
                            view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                            tryAwaitRelease()
                            isHolding = false
                        }
                    },
                    onTap = {
                        if (progress < 0.25f) { // Only tap if not held long
                            onTap()
                        }
                    }
                )
            }
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawKey(progress, isLocked)
        }
    }
}

private fun DrawScope.drawKey(progress: Float, isLocked: Boolean) {
    val center = Offset(size.width / 2f, size.height / 2f)
    val radius = size.minDimension / 2.5f
    
    // Shadow
    drawCircle(
        color = Color.Black.copy(alpha = 0.15f),
        radius = radius,
        center = center.copy(y = center.y + 8f)
    )
    
    // Key body (warm gray)
    drawCircle(
        brush = Brush.radialGradient(
            colors = listOf(
                KeyPalette.body.copy(alpha = 0.95f),
                KeyPalette.body
            ),
            center = center.copy(y = center.y - radius * 0.2f),
            radius = radius
        ),
        radius = radius,
        center = center
    )
    
    // Fill (darker gray) - fills from bottom to top
    if (progress > 0f || isLocked) {
        val fillProgress = if (isLocked) 1f else progress
        val clipHeight = radius * 2f * fillProgress
        
        drawCircle(
            brush = Brush.verticalGradient(
                colors = listOf(
                    KeyPalette.fill.copy(alpha = 0.9f),
                    KeyPalette.fill
                ),
                startY = center.y + radius - clipHeight,
                endY = center.y + radius
            ),
            radius = radius,
            center = center,
            blendMode = BlendMode.SrcOver
        )
    }
    
    // Lock burst ring effect when locked
    if (isLocked) {
        val ringRadius = radius * 1.15f
        drawCircle(
            color = KeyPalette.fill.copy(alpha = 0.3f),
            radius = ringRadius,
            center = center,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4f)
        )
        
        val outerRing = radius * 1.25f
        drawCircle(
            color = KeyPalette.fill.copy(alpha = 0.15f),
            radius = outerRing,
            center = center,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 2f)
        )
    }
    
    // Subtle highlight
    drawCircle(
        brush = Brush.radialGradient(
            colors = listOf(
                Color.White.copy(alpha = 0.15f),
                Color.Transparent
            ),
            center = center.copy(y = center.y - radius * 0.4f),
            radius = radius * 0.5f
        ),
        radius = radius,
        center = center
    )
}

private fun performHaptic(view: View, progress: Float) {
    // Build-up haptics: light at start, strong at end
    val constant = when {
        progress < 0.3f -> HapticFeedbackConstants.CLOCK_TICK
        progress < 0.7f -> HapticFeedbackConstants.CONTEXT_CLICK
        else -> HapticFeedbackConstants.KEYBOARD_TAP
    }
    view.performHapticFeedback(constant)
}

private fun performLockHaptic(view: View) {
    // Strong burst at lock
    view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
}
