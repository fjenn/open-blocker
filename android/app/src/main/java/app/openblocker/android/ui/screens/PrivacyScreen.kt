package app.openblocker.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.CountManager
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.RoundIconButton
import app.openblocker.android.ui.components.SettingsGroup
import app.openblocker.android.ui.components.SettingsRow
import app.openblocker.android.ui.theme.*

@Composable
fun PrivacyScreen(
    onBack: () -> Unit,
    onOpenFullPolicy: () -> Unit,
    modifier: Modifier = Modifier
) {
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
                text = "Privacy",
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
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Space.margin)
                .padding(top = Space.xs, bottom = Space.xxl),
            verticalArrangement = Arrangement.spacedBy(Space.s)
        ) {
            // Stays on your phone
            InfoCard(
                title = "Stays on your phone",
                text = "Your modes, keys, schedules and history stay on your phone. Open Blocker has no accounts and no ads."
            )
            
            // Anonymous count
            InfoCard(
                title = "Anonymous count",
                text = CountManager.DISCLOSURE + " Turn it off in Settings any time."
            )
            
            // Permissions header
            Text(
                text = "Permissions",
                style = OpenBlockerTextStyle.subhead.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = Space.xxs, vertical = Space.s)
            )
            
            // Permissions list
            SettingsGroup {
                PermissionRow(
                    icon = "usage",
                    title = "Usage Access",
                    reason = "Required on Android to detect when blocked apps are opened and to show the block screen. We don't read or track your usage. Time blocked is our own count."
                )
                androidx.compose.foundation.layout.Spacer(modifier = Modifier.height(0.5.dp))
                PermissionRow(
                    icon = "accessibility",
                    title = "Accessibility",
                    reason = "Required on Android to block apps and show the block screen. We don't read screen content or track your activity."
                )
                androidx.compose.foundation.layout.Spacer(modifier = Modifier.height(0.5.dp))
                PermissionRow(
                    icon = "nfc",
                    title = "NFC",
                    reason = "Reads your key tag or card, and sets up new tags. No permission needed on Android."
                )
                androidx.compose.foundation.layout.Spacer(modifier = Modifier.height(0.5.dp))
                PermissionRow(
                    icon = "camera",
                    title = "Camera",
                    reason = "Scans your QR key. Nothing is recorded."
                )
                androidx.compose.foundation.layout.Spacer(modifier = Modifier.height(0.5.dp))
                PermissionRow(
                    icon = "notifications",
                    title = "Notifications",
                    reason = "Tells you when a block ends, if you turn it on."
                )
            }
            
            PrimaryButton(
                title = "Full privacy policy",
                onClick = onOpenFullPolicy,
                modifier = Modifier.padding(top = Space.s)
            )
        }
    }
}

@Composable
private fun InfoCard(
    title: String,
    text: String,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(Radius.card),
                ambientColor = MaterialTheme.colorScheme.scrim.copy(alpha = 0.45f)
            )
            .background(
                color = MaterialTheme.colorScheme.surface,
                shape = RoundedCornerShape(Radius.card)
            )
            .padding(Space.l),
        verticalArrangement = Arrangement.spacedBy(Space.xs)
    ) {
        Text(
            text = title,
            style = OpenBlockerTextStyle.headline,
            color = MaterialTheme.colorScheme.onBackground
        )
        Text(
            text = text,
            style = OpenBlockerTextStyle.body,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun PermissionRow(
    icon: String,
    title: String,
    reason: String,
    modifier: Modifier = Modifier
) {
    SettingsRow(
        icon = icon,
        title = title,
        subtitle = reason,
        showsChevron = false,
        modifier = modifier
    )
}

// CountManager constants that should match iOS
object CountManagerConstants {
    const val SUMMARY = "Helps us count users. No personal data."
    const val DISCLOSURE = "One ping after your first block, with a random ID and the app version. Nothing about you or your apps."
}

// Add these to CountManager.kt
private const val SUMMARY = CountManagerConstants.SUMMARY
private const val DISCLOSURE = CountManagerConstants.DISCLOSURE
