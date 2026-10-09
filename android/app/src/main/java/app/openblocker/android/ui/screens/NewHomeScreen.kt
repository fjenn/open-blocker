package app.openblocker.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.SessionManager
import app.openblocker.android.ui.components.KeyView
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.TodayPill
import app.openblocker.android.ui.theme.*

/**
 * New home screen matching iOS design:
 * - 3D key with hold-to-fill (5s)
 * - "0h 32m blocked today" pill
 * - "Blocked for" counter when locked
 * - Lock burst halo when locked
 */
@Composable
fun NewHomeScreen(
    onNavigateToScan: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isBlocking by SessionManager.isBlocking.collectAsState()
    val blockedDuration by remember { mutableStateOf(0L) } // TODO: Track actual blocked time
    
    val hours = (blockedDuration / 3600).toInt()
    val minutes = ((blockedDuration % 3600) / 60).toInt()
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Space.margin)
            .padding(bottom = Space.tabBarClearance),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(Space.xl))
        
        // Blocked today pill
        if (blockedDuration > 0) {
            TodayPill(
                hours = hours,
                minutes = minutes,
                modifier = Modifier.testTag("today_pill")
            )
            
            Spacer(modifier = Modifier.height(Space.m))
        }
        
        Spacer(modifier = Modifier.weight(0.3f))
        
        // Key view with hold-to-fill
        KeyView(
            isLocked = isBlocking,
            isEnabled = true,
            onTap = onNavigateToScan,
            onCompleted = {
                SessionManager.startSession()
            },
            modifier = Modifier.testTag("key_view")
        )
        
        Spacer(modifier = Modifier.height(Space.l))
        
        // Status text
        if (isBlocking) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Space.xs)
            ) {
                Text(
                    text = "Blocked for",
                    style = OpenBlockerTextStyle.subhead,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "Deep work", // TODO: Show actual mode name
                    style = OpenBlockerTextStyle.headline,
                    color = MaterialTheme.colorScheme.onBackground,
                    modifier = Modifier.testTag("mode_name")
                )
            }
        } else {
            Text(
                text = "Tap your key or hold to block",
                style = OpenBlockerTextStyle.body,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
        
        Spacer(modifier = Modifier.weight(0.5f))
        
        // Action button
        PrimaryButton(
            title = if (isBlocking) {
                "Tap your key to unblock"
            } else {
                "Scan QR key"
            },
            onClick = onNavigateToScan,
            testTag = "action_button",
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(Space.xl))
    }
}
