package app.openblocker.android.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import app.openblocker.android.ui.theme.Metrics
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Radius
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.asCopy
import app.openblocker.android.ui.theme.obColors

enum class ButtonEmphasis { QUIET, INK }

@Composable
fun ScreenCanvas(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().background(obColors().canvas))
}

@Composable
fun StatusBarScrim(modifier: Modifier = Modifier) {
    val color = obColors().canvas
    Box(
        modifier
            .fillMaxWidth()
            .height(28.dp)
            .background(Brush.verticalGradient(listOf(color, color.copy(alpha = 0f))))
    )
}

@Composable
fun CardSurface(
    modifier: Modifier = Modifier,
    raised: Boolean = false,
    content: @Composable ColumnScope.() -> Unit
) {
    val colors = obColors()
    Column(
        modifier
            .shadow(
                elevation = if (raised) 14.dp else 8.dp,
                shape = RoundedCornerShape(Radius.card),
                ambientColor = colors.shadow,
                spotColor = colors.shadow
            )
            .background(if (raised) colors.surfaceRaised else colors.surface, RoundedCornerShape(Radius.card))
            .clip(RoundedCornerShape(Radius.card)),
        content = content
    )
}

@Composable
fun PrimaryButton(
    title: String,
    modifier: Modifier = Modifier,
    emphasis: ButtonEmphasis = ButtonEmphasis.QUIET,
    enabled: Boolean = true,
    progress: Float = 0f,
    testTag: String? = null,
    onClick: () -> Unit
) {
    val colors = obColors()
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.97f else 1f, label = "btn")
    val fill = if (emphasis == ButtonEmphasis.INK) colors.ink else colors.surfaceRaised
    val text = if (emphasis == ButtonEmphasis.INK) colors.inkInverse else colors.ink
    Box(
        modifier
            .scale(scale)
            .fillMaxWidth()
            .height(Metrics.buttonHeight)
            .shadow(14.dp, RoundedCornerShape(50), ambientColor = colors.shadow, spotColor = colors.shadow)
            .background(fill.copy(alpha = if (enabled) 1f else 0.45f), RoundedCornerShape(50))
            .then(
                if (emphasis == ButtonEmphasis.QUIET) {
                    Modifier.border(0.5.dp, colors.hairline, RoundedCornerShape(50))
                } else Modifier
            )
            .clip(RoundedCornerShape(50))
            .clickable(enabled = enabled, interactionSource = interaction, indication = null, onClick = onClick)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        contentAlignment = Alignment.Center
    ) {
        if (progress > 0f && emphasis == ButtonEmphasis.QUIET) {
            Box(
                Modifier
                    .align(Alignment.CenterStart)
                    .fillMaxHeight()
                    .fillMaxWidth(progress.coerceIn(0f, 1f))
                    .background(colors.ink.copy(alpha = 0.08f))
            )
        }
        Text(
            title.asCopy(),
            style = ObText.button,
            color = text.copy(alpha = if (enabled) 1f else 0.45f),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = Space.l)
        )
    }
}

@Composable
fun RoundIconButton(
    glyph: Glyph,
    contentDescription: String,
    modifier: Modifier = Modifier,
    testTag: String? = null,
    onClick: () -> Unit
) {
    val colors = obColors()
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.97f else 1f, label = "icon")
    Box(
        modifier
            .scale(scale)
            .size(Metrics.headerButton)
            .shadow(8.dp, CircleShape, ambientColor = colors.shadow, spotColor = colors.shadow)
            .background(colors.surfaceRaised, CircleShape)
            .clip(CircleShape)
            .clickable(interactionSource = interaction, indication = null, onClick = onClick)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier)
            .semantics { this.contentDescription = contentDescription },
        contentAlignment = Alignment.Center
    ) {
        GlyphIcon(glyph, colors.ink, size = 16.dp)
    }
}

@Composable
fun SettingsGroup(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    val colors = obColors()
    Column(
        modifier
            .fillMaxWidth()
            .shadow(8.dp, RoundedCornerShape(Radius.group), ambientColor = colors.shadow.copy(alpha = 0.45f), spotColor = colors.shadow)
            .background(colors.surface, RoundedCornerShape(Radius.group))
            .clip(RoundedCornerShape(Radius.group)),
        content = content
    )
}

@Composable
fun HairlineDivider() {
    val colors = obColors()
    Box(
        Modifier
            .fillMaxWidth()
            .height(0.5.dp)
            .padding(start = Space.m + 22.dp + Space.s)
            .background(colors.hairline)
    )
}

@Composable
fun SettingsRow(
    glyph: Glyph,
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    detail: String? = null,
    chevron: Boolean = true,
    testTag: String? = null,
    onClick: (() -> Unit)? = null
) {
    val colors = obColors()
    Row(
        modifier
            .fillMaxWidth()
            .heightIn(min = 54.dp)
            .clickable(enabled = onClick != null, indication = null, interactionSource = remember { MutableInteractionSource() }) {
                onClick?.invoke()
            }
            .padding(horizontal = Space.m, vertical = if (subtitle != null) Space.s else 0.dp)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Space.s)
    ) {
        GlyphIcon(glyph, colors.ink, Modifier.width(22.dp), 15.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title.asCopy(), style = ObText.body.copy(fontWeight = FontWeight.Medium), color = colors.ink, maxLines = 2)
            if (subtitle != null) {
                Text(subtitle.asCopy(), style = ObText.footnote.copy(fontWeight = FontWeight.Normal), color = colors.inkSecondary)
            }
        }
        if (detail != null) {
            Text(detail.asCopy(), style = ObText.subhead, color = colors.inkSecondary)
        }
        if (chevron) GlyphIcon(Glyph.Chevron, colors.inkTertiary, size = 12.dp)
    }
}

@Composable
fun SettingsToggleRow(
    glyph: Glyph,
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    testTag: String? = null
) {
    val colors = obColors()
    Row(
        modifier
            .fillMaxWidth()
            .heightIn(min = 54.dp)
            .padding(horizontal = Space.m, vertical = if (subtitle != null) Space.s else 0.dp)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Space.s)
    ) {
        GlyphIcon(glyph, colors.ink, Modifier.width(22.dp), 15.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title.asCopy(), style = ObText.body.copy(fontWeight = FontWeight.Medium), color = colors.ink)
            if (subtitle != null) {
                Text(subtitle.asCopy(), style = ObText.footnote.copy(fontWeight = FontWeight.Normal), color = colors.inkSecondary)
            }
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = colors.accent,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = colors.fillQuiet
            )
        )
    }
}

@Composable
fun <T> SegmentedPill(
    options: List<Pair<String, T>>,
    selected: T,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
    testTag: String? = null
) {
    val colors = obColors()
    Row(
        modifier
            .fillMaxWidth()
            .background(colors.fillQuiet, RoundedCornerShape(Radius.chip))
            .padding(3.dp)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        options.forEach { (label, value) ->
            val on = value == selected
            Box(
                Modifier
                    .weight(1f)
                    .height(38.dp)
                    .background(if (on) colors.ink else Color.Transparent, RoundedCornerShape(Radius.tile))
                    .clip(RoundedCornerShape(Radius.tile))
                    .clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) { onSelect(value) },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    label.asCopy(),
                    style = ObText.subhead.copy(fontWeight = FontWeight.SemiBold),
                    color = if (on) colors.inkInverse else colors.inkSecondary,
                    maxLines = 1
                )
            }
        }
    }
}

@Composable
fun TodayPill(seconds: Long, modifier: Modifier = Modifier) {
    val colors = obColors()
    val label = app.openblocker.android.domain.DurationText.hoursMinutes(seconds)
    Row(
        modifier
            .shadow(10.dp, RoundedCornerShape(Radius.chip), ambientColor = colors.shadow, spotColor = colors.shadow)
            .background(colors.surfaceRaised, RoundedCornerShape(Radius.chip))
            .padding(horizontal = 14.dp, vertical = 9.dp)
            .testTag("today_pill"),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label.asCopy(), style = ObText.headline.copy(fontWeight = FontWeight.Bold), color = colors.ink, maxLines = 1)
        Text("blocked today".asCopy(), style = ObText.footnote, color = colors.inkSecondary, maxLines = 1)
    }
}

@Composable
fun TabHeader(title: String, modifier: Modifier = Modifier, trailing: @Composable RowScope.() -> Unit = {}) {
    val colors = obColors()
    Box(
        modifier
            .fillMaxWidth()
            .heightIn(min = Metrics.headerButton)
            .padding(top = Space.xs)
    ) {
        Text(
            title.asCopy(),
            style = ObText.headline.copy(fontWeight = FontWeight.Medium),
            color = colors.ink,
            modifier = Modifier.align(Alignment.Center)
        )
        Row(Modifier.align(Alignment.CenterEnd), content = trailing)
    }
}

@Composable
fun PushedHeader(title: String, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val colors = obColors()
    Box(
        modifier
            .fillMaxWidth()
            .padding(horizontal = Space.margin)
            .padding(top = Space.xs, bottom = Space.s)
    ) {
        Text(
            title.asCopy(),
            style = ObText.headline.copy(fontWeight = FontWeight.Medium),
            color = colors.ink,
            modifier = Modifier.align(Alignment.Center)
        )
        RoundIconButton(Glyph.Back, "Back", Modifier.align(Alignment.CenterStart).testTag("nav_back"), "nav_back", onBack)
    }
}

@Composable
fun SheetHeader(
    title: String,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    onLeading: (() -> Unit)? = null,
    leadingGlyph: Glyph = Glyph.Back
) {
    val colors = obColors()
    Box(
        modifier
            .fillMaxWidth()
            .padding(horizontal = Space.margin)
            .padding(top = Space.l, bottom = Space.m)
    ) {
        Text(
            title.asCopy(),
            style = ObText.headline.copy(fontWeight = FontWeight.Medium),
            color = colors.ink,
            modifier = Modifier.align(Alignment.Center)
        )
        if (onLeading != null) {
            RoundIconButton(leadingGlyph, "Back", Modifier.align(Alignment.CenterStart), onClick = onLeading)
        }
        RoundIconButton(Glyph.Close, "Close", Modifier.align(Alignment.CenterEnd).testTag("sheet_close"), "sheet_close", onClose)
    }
}

@Composable
fun InfoNote(text: String, modifier: Modifier = Modifier) {
    val colors = obColors()
    Row(
        modifier
            .fillMaxWidth()
            .background(colors.fillQuiet.copy(alpha = 0.7f), RoundedCornerShape(Radius.chip))
            .padding(Space.s),
        horizontalArrangement = Arrangement.spacedBy(Space.xs)
    ) {
        GlyphIcon(Glyph.Info, colors.inkSecondary, size = 13.dp)
        Text(text.asCopy(), style = ObText.footnote.copy(fontWeight = FontWeight.Normal), color = colors.inkSecondary)
    }
}

@Composable
fun EmptyState(title: String, message: String, modifier: Modifier = Modifier) {
    val colors = obColors()
    Column(
        modifier.fillMaxWidth().padding(Space.xxxl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Space.m)
    ) {
        Box(
            Modifier.size(88.dp).background(colors.fillQuiet, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            GlyphIcon(Glyph.Calendar, colors.inkSecondary, size = 34.dp)
        }
        Text(title.asCopy(), style = ObText.headline, color = colors.ink, textAlign = TextAlign.Center)
        Text(message.asCopy(), style = ObText.subhead, color = colors.inkSecondary, textAlign = TextAlign.Center)
    }
}

@Composable
fun BrandMark(size: Dp, modifier: Modifier = Modifier) {
    Box(
        modifier
            .size(size)
            .clip(CircleShape)
            .background(Color(0xFF4450F2)),
        contentAlignment = Alignment.Center
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .padding(size * 50f / 512f)
                .border(size * 10f / 512f, Color.White.copy(alpha = 0.35f), CircleShape)
        )
        Canvas(Modifier.fillMaxSize()) {
            val s = size.toPx() / 512f
            val hole = Path().apply {
                addOval(Rect((256f - 62f) * s, (214f - 62f) * s, (256f + 62f) * s, (214f + 62f) * s))
                moveTo(226f * s, 250f * s)
                lineTo(286f * s, 250f * s)
                lineTo(306f * s, 366f * s)
                quadraticBezierTo(308f * s, 380f * s, 294f * s, 380f * s)
                lineTo(218f * s, 380f * s)
                quadraticBezierTo(204f * s, 380f * s, 206f * s, 366f * s)
                close()
            }
            drawPath(hole, Color.White)
        }
    }
}

enum class AppTab(val label: String, val testTag: String) {
    BLOCK("Block", "tab_block"),
    SCHEDULE("Schedule", "tab_schedule"),
    ACTIVITY("Activity", "tab_activity"),
    SETTINGS("Settings", "tab_settings")
}

@Composable
fun TextTabBar(selected: AppTab, onSelect: (AppTab) -> Unit, modifier: Modifier = Modifier) {
    val colors = obColors()
    Row(
        modifier
            .fillMaxWidth()
            .height(Metrics.tabBarHeight)
            .padding(horizontal = Space.xs)
    ) {
        AppTab.entries.forEach { tab ->
            val on = selected == tab
            Column(
                Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) { onSelect(tab) }
                    .testTag(tab.testTag),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    tab.label.asCopy(),
                    style = ObText.subhead.copy(fontWeight = if (on) FontWeight.SemiBold else FontWeight.Medium),
                    color = if (on) colors.ink else colors.inkSecondary
                )
                Spacer(Modifier.height(5.dp))
                Box(
                    Modifier
                        .size(4.dp)
                        .background(if (on) colors.ink else Color.Transparent, CircleShape)
                )
            }
        }
    }
}

@Composable
fun PhoneShell(
    tab: AppTab,
    onTab: (AppTab) -> Unit = {},
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val colors = obColors()
    Column(modifier.fillMaxSize().background(colors.chrome).testTag("phone_shell")) {
        Box(
            Modifier
                .weight(1f)
                .shadow(
                    18.dp,
                    RoundedCornerShape(bottomStart = Radius.screen, bottomEnd = Radius.screen),
                    ambientColor = colors.shadow,
                    spotColor = colors.shadow
                )
                .clip(RoundedCornerShape(bottomStart = Radius.screen, bottomEnd = Radius.screen))
                .background(colors.canvas)
        ) {
            content()
        }
        TextTabBar(tab, onTab)
    }
}

@Composable
fun ScrollColumn(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Space.margin)
            .padding(bottom = Space.tabBarClearance),
        content = content
    )
}

@Composable
fun IconTile(glyph: Glyph, modifier: Modifier = Modifier, size: androidx.compose.ui.unit.Dp = 40.dp) {
    val colors = obColors()
    Box(
        modifier
            .size(size)
            .background(colors.fillQuiet, RoundedCornerShape(Radius.tile)),
        contentAlignment = Alignment.Center
    ) {
        GlyphIcon(glyph, colors.ink, size = size * 0.42f)
    }
}
