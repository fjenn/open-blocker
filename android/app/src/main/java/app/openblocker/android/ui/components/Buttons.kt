package app.openblocker.android.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import app.openblocker.android.ui.theme.*

enum class ButtonEmphasis {
    QUIET,  // raised pill with a thin outline
    INK     // solid ink: the confirm action
}

/**
 * Primary capsule button matching iOS design.
 */
@Composable
fun PrimaryButton(
    title: String,
    modifier: Modifier = Modifier,
    emphasis: ButtonEmphasis = ButtonEmphasis.QUIET,
    isEnabled: Boolean = true,
    testTag: String? = null,
    onClick: () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.97f else 1f,
        label = "button_scale"
    )
    
    val backgroundColor = when (emphasis) {
        ButtonEmphasis.QUIET -> OpenBlockerColors.surfaceRaised()
        ButtonEmphasis.INK -> androidx.compose.material3.MaterialTheme.colorScheme.onBackground
    }
    
    val textColor = when (emphasis) {
        ButtonEmphasis.QUIET -> androidx.compose.material3.MaterialTheme.colorScheme.onBackground
        ButtonEmphasis.INK -> OpenBlockerColors.inkInverse()
    }
    
    Box(
        modifier = modifier
            .scale(scale)
            .height(Metrics.buttonHeight)
            .shadow(
                elevation = if (emphasis == ButtonEmphasis.QUIET) 14.dp else 7.dp,
                shape = RoundedCornerShape(50),
                ambientColor = if (isEnabled) {
                    androidx.compose.material3.MaterialTheme.colorScheme.scrim.copy(
                        alpha = if (emphasis == ButtonEmphasis.QUIET) 1f else 0.5f
                    )
                } else Color.Transparent
            )
            .background(
                color = backgroundColor.copy(alpha = if (isEnabled) 1f else 0.45f),
                shape = RoundedCornerShape(50)
            )
            .clip(RoundedCornerShape(50))
            .clickable(
                enabled = isEnabled,
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .then(
                if (testTag != null) Modifier.testTag(testTag) else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title,
            style = OpenBlockerTextStyle.button,
            color = textColor.copy(alpha = if (isEnabled) 1f else 0.45f),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = Space.l)
        )
    }
}

/**
 * 40dp round icon button (back, close, more).
 */
@Composable
fun RoundIconButton(
    iconName: String,
    contentDescription: String,
    modifier: Modifier = Modifier,
    testTag: String? = null,
    onClick: () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.97f else 1f,
        label = "icon_button_scale"
    )
    
    Box(
        modifier = modifier
            .scale(scale)
            .size(Metrics.headerButton)
            .shadow(
                elevation = 8.dp,
                shape = CircleShape,
                ambientColor = androidx.compose.material3.MaterialTheme.colorScheme.scrim
            )
            .background(
                color = OpenBlockerColors.surfaceRaised(),
                shape = CircleShape
            )
            .clip(CircleShape)
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .then(
                if (testTag != null) Modifier.testTag(testTag) else Modifier
            )
            .semantics { this.contentDescription = contentDescription },
        contentAlignment = Alignment.Center
    ) {
        Icon(
            painter = painterResource(
                id = android.R.drawable.ic_menu_revert  // Placeholder, will use proper icon
            ),
            contentDescription = contentDescription,
            tint = androidx.compose.material3.MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.size(16.dp)
        )
    }
}
