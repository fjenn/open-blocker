package app.openblocker.android.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

enum class Glyph {
    Back, Close, Plus, Chevron, Check,
    Key, Bell, Privacy, Help, Contact, About, Appearance, People,
    LifeRing, Calendar, Grid, Nfc, Camera, Hourglass, Moon, Leaf,
    Family, Detox, Blank, Scope, Info, Notifications, Pencil
}

@Composable
fun GlyphIcon(
    glyph: Glyph,
    color: Color,
    modifier: Modifier = Modifier,
    size: Dp = 16.dp
) {
    Canvas(modifier.size(size)) {
        val s = this.size.minDimension
        val stroke = Stroke(width = s * 0.09f, cap = StrokeCap.Round)
        when (glyph) {
            Glyph.Back -> {
                drawLine(color, Offset(s * 0.62f, s * 0.22f), Offset(s * 0.32f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.32f, s * 0.5f), Offset(s * 0.62f, s * 0.78f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Close -> {
                drawLine(color, Offset(s * 0.28f, s * 0.28f), Offset(s * 0.72f, s * 0.72f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.72f, s * 0.28f), Offset(s * 0.28f, s * 0.72f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Plus -> {
                drawLine(color, Offset(s * 0.5f, s * 0.22f), Offset(s * 0.5f, s * 0.78f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.22f, s * 0.5f), Offset(s * 0.78f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Chevron -> {
                drawLine(color, Offset(s * 0.38f, s * 0.22f), Offset(s * 0.68f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.68f, s * 0.5f), Offset(s * 0.38f, s * 0.78f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Check -> {
                drawLine(color, Offset(s * 0.22f, s * 0.52f), Offset(s * 0.42f, s * 0.72f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.42f, s * 0.72f), Offset(s * 0.8f, s * 0.28f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Key -> {
                drawCircle(color, s * 0.16f, Offset(s * 0.32f, s * 0.38f), style = stroke)
                drawLine(color, Offset(s * 0.44f, s * 0.5f), Offset(s * 0.78f, s * 0.78f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.62f, s * 0.64f), Offset(s * 0.74f, s * 0.52f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Bell -> {
                drawArc(color, 200f, 140f, false, Offset(s * 0.22f, s * 0.18f), Size(s * 0.56f, s * 0.62f), style = stroke)
                drawLine(color, Offset(s * 0.28f, s * 0.7f), Offset(s * 0.72f, s * 0.7f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawArc(color, 0f, 180f, false, Offset(s * 0.4f, s * 0.68f), Size(s * 0.2f, s * 0.16f), style = stroke)
            }
            Glyph.Privacy -> {
                drawCircle(color, s * 0.16f, Offset(s * 0.5f, s * 0.32f), style = stroke)
                drawArc(color, 200f, 140f, false, Offset(s * 0.22f, s * 0.42f), Size(s * 0.56f, s * 0.46f), style = stroke)
            }
            Glyph.Help -> {
                drawCircle(color, s * 0.38f, Offset(s * 0.5f, s * 0.5f), style = stroke)
                drawCircle(color, s * 0.045f, Offset(s * 0.5f, s * 0.72f))
                drawArc(color, 200f, 220f, false, Offset(s * 0.36f, s * 0.28f), Size(s * 0.28f, s * 0.28f), style = stroke)
            }
            Glyph.Contact -> {
                drawCircle(color, s * 0.14f, Offset(s * 0.5f, s * 0.32f), style = stroke)
                drawArc(color, 200f, 140f, false, Offset(s * 0.22f, s * 0.5f), Size(s * 0.56f, s * 0.36f), style = stroke)
            }
            Glyph.About -> {
                drawCircle(color, s * 0.38f, Offset(s * 0.5f, s * 0.5f), style = stroke)
                drawLine(color, Offset(s * 0.5f, s * 0.42f), Offset(s * 0.5f, s * 0.7f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawCircle(color, s * 0.04f, Offset(s * 0.5f, s * 0.3f))
            }
            Glyph.Appearance -> {
                drawArc(color, 90f, 180f, true, Offset(s * 0.16f, s * 0.16f), Size(s * 0.68f, s * 0.68f))
                drawCircle(color, s * 0.34f, Offset(s * 0.5f, s * 0.5f), style = stroke)
            }
            Glyph.People -> {
                drawCircle(color, s * 0.12f, Offset(s * 0.34f, s * 0.32f), style = stroke)
                drawCircle(color, s * 0.12f, Offset(s * 0.64f, s * 0.32f), style = stroke)
                drawArc(color, 200f, 140f, false, Offset(s * 0.16f, s * 0.5f), Size(s * 0.36f, s * 0.3f), style = stroke)
                drawArc(color, 200f, 140f, false, Offset(s * 0.46f, s * 0.5f), Size(s * 0.36f, s * 0.3f), style = stroke)
            }
            Glyph.LifeRing -> {
                drawCircle(color, s * 0.34f, Offset(s * 0.5f, s * 0.5f), style = stroke)
                drawCircle(color, s * 0.16f, Offset(s * 0.5f, s * 0.5f), style = stroke)
                drawLine(color, Offset(s * 0.28f, s * 0.28f), Offset(s * 0.4f, s * 0.4f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.72f, s * 0.28f), Offset(s * 0.6f, s * 0.4f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Calendar -> {
                drawRoundRect(color, Offset(s * 0.2f, s * 0.28f), Size(s * 0.6f, s * 0.52f), style = stroke, cornerRadius = androidx.compose.ui.geometry.CornerRadius(s * 0.06f))
                drawLine(color, Offset(s * 0.32f, s * 0.18f), Offset(s * 0.32f, s * 0.36f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.68f, s * 0.18f), Offset(s * 0.68f, s * 0.36f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Grid -> {
                val gap = s * 0.08f
                val cell = s * 0.22f
                for (x in 0..1) for (y in 0..1) {
                    drawRoundRect(
                        color,
                        Offset(s * 0.22f + x * (cell + gap), s * 0.22f + y * (cell + gap)),
                        Size(cell, cell),
                        cornerRadius = androidx.compose.ui.geometry.CornerRadius(s * 0.04f)
                    )
                }
            }
            Glyph.Nfc -> {
                drawArc(color, 220f, 80f, false, Offset(s * 0.18f, s * 0.18f), Size(s * 0.64f, s * 0.64f), style = stroke)
                drawArc(color, 220f, 80f, false, Offset(s * 0.3f, s * 0.3f), Size(s * 0.4f, s * 0.4f), style = stroke)
                drawCircle(color, s * 0.05f, Offset(s * 0.5f, s * 0.5f))
            }
            Glyph.Camera -> {
                drawRoundRect(color, Offset(s * 0.16f, s * 0.32f), Size(s * 0.68f, s * 0.46f), style = stroke, cornerRadius = androidx.compose.ui.geometry.CornerRadius(s * 0.08f))
                drawCircle(color, s * 0.12f, Offset(s * 0.5f, s * 0.55f), style = stroke)
                drawRoundRect(color, Offset(s * 0.36f, s * 0.22f), Size(s * 0.2f, s * 0.12f), cornerRadius = androidx.compose.ui.geometry.CornerRadius(s * 0.03f))
            }
            Glyph.Hourglass -> {
                drawLine(color, Offset(s * 0.3f, s * 0.2f), Offset(s * 0.7f, s * 0.2f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.3f, s * 0.8f), Offset(s * 0.7f, s * 0.8f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.32f, s * 0.2f), Offset(s * 0.5f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.68f, s * 0.2f), Offset(s * 0.5f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.32f, s * 0.8f), Offset(s * 0.5f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.68f, s * 0.8f), Offset(s * 0.5f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Moon -> drawArc(color, 40f, 280f, false, Offset(s * 0.22f, s * 0.18f), Size(s * 0.56f, s * 0.64f), style = stroke)
            Glyph.Leaf -> {
                drawArc(color, 200f, 220f, false, Offset(s * 0.22f, s * 0.22f), Size(s * 0.5f, s * 0.56f), style = stroke)
                drawLine(color, Offset(s * 0.38f, s * 0.7f), Offset(s * 0.58f, s * 0.38f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Family -> {
                drawCircle(color, s * 0.1f, Offset(s * 0.32f, s * 0.3f), style = stroke)
                drawCircle(color, s * 0.1f, Offset(s * 0.62f, s * 0.3f), style = stroke)
                drawCircle(color, s * 0.08f, Offset(s * 0.48f, s * 0.48f), style = stroke)
            }
            Glyph.Detox -> {
                drawCircle(color, s * 0.34f, Offset(s * 0.5f, s * 0.5f), style = stroke)
                drawLine(color, Offset(s * 0.28f, s * 0.28f), Offset(s * 0.72f, s * 0.72f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Blank -> {
                drawRoundRect(color, Offset(s * 0.22f, s * 0.22f), Size(s * 0.56f, s * 0.56f), style = stroke, cornerRadius = androidx.compose.ui.geometry.CornerRadius(s * 0.08f))
            }
            Glyph.Scope -> {
                drawCircle(color, s * 0.28f, Offset(s * 0.5f, s * 0.5f), style = stroke)
                drawLine(color, Offset(s * 0.5f, s * 0.12f), Offset(s * 0.5f, s * 0.28f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.5f, s * 0.72f), Offset(s * 0.5f, s * 0.88f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.12f, s * 0.5f), Offset(s * 0.28f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.72f, s * 0.5f), Offset(s * 0.88f, s * 0.5f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
            Glyph.Info -> {
                drawCircle(color, s * 0.38f, Offset(s * 0.5f, s * 0.5f), style = stroke)
                drawLine(color, Offset(s * 0.5f, s * 0.42f), Offset(s * 0.5f, s * 0.7f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawCircle(color, s * 0.04f, Offset(s * 0.5f, s * 0.3f))
            }
            Glyph.Notifications -> {
                drawCircle(color, s * 0.08f, Offset(s * 0.5f, s * 0.28f))
                drawRoundRect(color, Offset(s * 0.32f, s * 0.4f), Size(s * 0.36f, s * 0.36f), style = stroke, cornerRadius = androidx.compose.ui.geometry.CornerRadius(s * 0.04f))
            }
            Glyph.Pencil -> {
                drawLine(color, Offset(s * 0.28f, s * 0.72f), Offset(s * 0.7f, s * 0.3f), strokeWidth = stroke.width, cap = StrokeCap.Round)
                drawLine(color, Offset(s * 0.28f, s * 0.72f), Offset(s * 0.22f, s * 0.8f), strokeWidth = stroke.width, cap = StrokeCap.Round)
            }
        }
    }
}

fun ModeTemplateGlyph(raw: String): Glyph = when (raw) {
    "deepWork" -> Glyph.Scope
    "sleep" -> Glyph.Moon
    "mindfulness" -> Glyph.Leaf
    "familyTime" -> Glyph.Family
    "detox" -> Glyph.Detox
    else -> Glyph.Blank
}
