package app.openblocker.android.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.EmergencyUnblockManager
import app.openblocker.android.data.SessionManager
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.RoundIconButton
import app.openblocker.android.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun EmergencyUnblockScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var status by remember { mutableStateOf(EmergencyUnblockManager.status()) }
    var confirming by remember { mutableStateOf(false) }
    var notice by remember { mutableStateOf<String?>(null) }
    val isBlocking by SessionManager.isBlocking.collectAsState()
    
    val maxCount = 5
    val dateFormat = remember { SimpleDateFormat("MMM d, yyyy", Locale.getDefault()) }
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Header
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Space.margin, vertical = Space.xs)
        ) {
            Text(
                text = "Emergency Unblock",
                style = OpenBlockerTextStyle.headline.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Medium),
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.align(Alignment.Center)
            )
            RoundIconButton(
                iconName = "back",
                contentDescription = "Back",
                onClick = onBack,
                modifier = Modifier.align(Alignment.CenterStart)
            )
        }
        
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = Space.margin),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(1f))
            
            // Capsule indicators
            Row(
                horizontalArrangement = Arrangement.spacedBy(Space.xs),
                modifier = Modifier.padding(bottom = Space.m)
            ) {
                repeat(maxCount) { index ->
                    Box(
                        modifier = Modifier
                            .width(28.dp)
                            .height(8.dp)
                            .clip(RoundedCornerShape(50))
                            .background(
                                if (index < status.remaining) {
                                    MaterialTheme.colorScheme.onBackground
                                } else {
                                    OpenBlockerColors.fillQuiet()
                                }
                            )
                    )
                }
            }
            
            // Count
            Text(
                text = "${status.remaining} left",
                style = OpenBlockerTextStyle.timer,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.testTag("emergency_count")
            )
            
            Text(
                text = "End a block without your key. Honesty, not a lock you cannot break.",
                style = OpenBlockerTextStyle.body,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = Space.xxxl, vertical = Space.m)
            )
            
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = "You get $maxCount every 6 months.",
                    style = OpenBlockerTextStyle.subhead,
                    color = MaterialTheme.colorScheme.outline,
                    textAlign = TextAlign.Center
                )
                Text(
                    text = "Resets on ${dateFormat.format(status.resetDate)}",
                    style = OpenBlockerTextStyle.subhead,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.testTag("emergency_reset")
                )
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Action area
            AnimatedVisibility(
                visible = confirming,
                enter = slideInVertically { it / 2 } + fadeIn(),
                exit = slideOutVertically { it / 2 } + fadeOut()
            ) {
                ConfirmPanel(
                    remaining = status.remaining,
                    onCancel = { confirming = false },
                    onConfirm = {
                        val success = EmergencyUnblockManager.useOne()
                        if (success) {
                            status = EmergencyUnblockManager.status()
                            SessionManager.endSession()
                            notice = "Unblocked."
                        } else {
                            notice = "Could not use one right now."
                        }
                        confirming = false
                    }
                )
            }
            
            AnimatedVisibility(
                visible = !confirming,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                PrimaryButton(
                    title = "Use an emergency unblock",
                    emphasis = ButtonEmphasis.INK,
                    isEnabled = status.remaining > 0,
                    testTag = "emergency_use",
                    onClick = {
                        if (status.remaining > 0) {
                            if (isBlocking) {
                                notice = null
                                confirming = true
                            } else {
                                notice = "You're not blocked right now. This only works during a block."
                            }
                        }
                    },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            
            if (notice != null) {
                Text(
                    text = notice!!,
                    style = OpenBlockerTextStyle.subhead,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(top = Space.m)
                )
            }
            
            Spacer(modifier = Modifier.height(Space.xl))
        }
    }
}

@Composable
private fun ConfirmPanel(
    remaining: Int,
    onCancel: () -> Unit,
    onConfirm: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(
                elevation = 14.dp,
                shape = RoundedCornerShape(Radius.card),
                ambientColor = MaterialTheme.colorScheme.scrim.copy(alpha = 0.9f)
            )
            .background(
                color = OpenBlockerColors.surfaceRaised(),
                shape = RoundedCornerShape(Radius.card)
            )
            .padding(Space.l),
        verticalArrangement = Arrangement.spacedBy(Space.m),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Unblock without your key?",
            style = OpenBlockerTextStyle.headline,
            color = MaterialTheme.colorScheme.onBackground
        )
        
        Text(
            text = "You'll have ${maxOf(remaining - 1, 0)} left.",
            style = OpenBlockerTextStyle.subhead,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Row(
            horizontalArrangement = Arrangement.spacedBy(Space.s)
        ) {
            PrimaryButton(
                title = "Cancel",
                onClick = onCancel,
                modifier = Modifier.weight(1f)
            )
            PrimaryButton(
                title = "Use",
                emphasis = ButtonEmphasis.INK,
                testTag = "emergency_confirm",
                onClick = onConfirm,
                modifier = Modifier.weight(1f)
            )
        }
    }
}
