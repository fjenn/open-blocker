package app.openblocker.android.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import app.openblocker.android.ui.theme.*

/**
 * Settings row with icon, title, optional subtitle, detail text and chevron.
 */
@Composable
fun SettingsRow(
    icon: String,
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    detail: String? = null,
    showsChevron: Boolean = true,
    testTag: String? = null,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 54.dp)
            .clickable(enabled = onClick != null) { onClick?.invoke() }
            .padding(horizontal = Space.m, vertical = if (subtitle != null) Space.s else 0.dp)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        horizontalArrangement = Arrangement.spacedBy(Space.s),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RowGlyph(iconName = icon)
        
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = title,
                style = OpenBlockerTextStyle.body.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Medium),
                color = androidx.compose.material3.MaterialTheme.colorScheme.onBackground,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = OpenBlockerTextStyle.footnote.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Normal),
                    color = androidx.compose.material3.MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        if (detail != null) {
            Text(
                text = detail,
                style = OpenBlockerTextStyle.subhead,
                color = androidx.compose.material3.MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        if (showsChevron) {
            Icon(
                painter = painterResource(android.R.drawable.ic_media_ff),
                contentDescription = null,
                tint = androidx.compose.material3.MaterialTheme.colorScheme.outline,
                modifier = Modifier.size(12.dp)
            )
        }
    }
}

/**
 * Settings row with a toggle switch.
 */
@Composable
fun SettingsToggleRow(
    icon: String,
    title: String,
    isOn: Boolean,
    onToggle: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    testTag: String? = null
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 54.dp)
            .padding(horizontal = Space.m, vertical = if (subtitle != null) Space.s else 0.dp)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        horizontalArrangement = Arrangement.spacedBy(Space.s),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RowGlyph(iconName = icon)
        
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = title,
                style = OpenBlockerTextStyle.body.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Medium),
                color = androidx.compose.material3.MaterialTheme.colorScheme.onBackground,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = OpenBlockerTextStyle.footnote.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Normal),
                    color = androidx.compose.material3.MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        Switch(
            checked = isOn,
            onCheckedChange = onToggle,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = androidx.compose.material3.MaterialTheme.colorScheme.primary,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = androidx.compose.material3.MaterialTheme.colorScheme.outlineVariant
            )
        )
    }
}

/**
 * Small icon glyph at the start of a row.
 */
@Composable
fun RowGlyph(iconName: String, modifier: Modifier = Modifier) {
    Icon(
        painter = painterResource(android.R.drawable.ic_menu_info_details),
        contentDescription = null,
        tint = androidx.compose.material3.MaterialTheme.colorScheme.onBackground,
        modifier = modifier.size(15.dp).width(22.dp)
    )
}

/**
 * Group container for settings rows.
 */
@Composable
fun SettingsGroup(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(Radius.group),
                ambientColor = androidx.compose.material3.MaterialTheme.colorScheme.scrim.copy(alpha = 0.45f)
            )
            .background(
                color = androidx.compose.material3.MaterialTheme.colorScheme.surface,
                shape = RoundedCornerShape(Radius.group)
            )
            .clip(RoundedCornerShape(Radius.group)),
        content = content
    )
}

/**
 * Thin divider line between settings rows.
 */
@Composable
fun HairlineDivider(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(0.5.dp)
            .padding(start = Space.m + 22.dp + Space.s)
            .background(OpenBlockerColors.hairline())
    )
}

/**
 * Capsule segmented control (Light/Dark/System).
 */
@Composable
fun <T> SegmentedPill(
    options: List<Pair<String, T>>,
    selectedValue: T,
    onValueChange: (T) -> Unit,
    modifier: Modifier = Modifier,
    testTag: String? = null
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(
                color = OpenBlockerColors.fillQuiet(),
                shape = RoundedCornerShape(Radius.chip)
            )
            .padding(3.dp)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        options.forEach { (label, value) ->
            val isSelected = value == selectedValue
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(38.dp)
                    .background(
                        color = if (isSelected) {
                            androidx.compose.material3.MaterialTheme.colorScheme.onBackground
                        } else {
                            Color.Transparent
                        },
                        shape = RoundedCornerShape(Radius.tile)
                    )
                    .clip(RoundedCornerShape(Radius.tile))
                    .clickable { onValueChange(value) },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = label,
                    style = OpenBlockerTextStyle.subhead.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold),
                    color = if (isSelected) {
                        OpenBlockerColors.inkInverse()
                    } else {
                        androidx.compose.material3.MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )
            }
        }
    }
}

/**
 * "0h 32m blocked today" pill.
 */
@Composable
fun TodayPill(
    hours: Int,
    minutes: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .shadow(
                elevation = 10.dp,
                shape = RoundedCornerShape(Radius.chip),
                ambientColor = androidx.compose.material3.MaterialTheme.colorScheme.scrim
            )
            .background(
                color = OpenBlockerColors.surfaceRaised(),
                shape = RoundedCornerShape(Radius.chip)
            )
            .padding(horizontal = 14.dp, vertical = 9.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "${hours}h ${minutes}m",
            style = OpenBlockerTextStyle.headline.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
            color = androidx.compose.material3.MaterialTheme.colorScheme.onBackground,
            maxLines = 1
        )
        Text(
            text = "blocked today",
            style = OpenBlockerTextStyle.footnote,
            color = androidx.compose.material3.MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1
        )
    }
}
