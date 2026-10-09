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
import androidx.compose.ui.unit.dp
import app.openblocker.android.BuildConfig
import app.openblocker.android.data.AppearanceManager
import app.openblocker.android.data.CountManager
import app.openblocker.android.data.EmergencyUnblockManager
import app.openblocker.android.ui.components.*
import app.openblocker.android.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun SettingsScreen(
    onNavigateToEmergencyUnblock: () -> Unit,
    onNavigateToPrivacy: () -> Unit,
    onNavigateToHelp: () -> Unit,
    onNavigateToContact: () -> Unit,
    onNavigateToAbout: () -> Unit,
    modifier: Modifier = Modifier
) {
    val appearance by AppearanceManager.appearance
    val emergencyStatus = remember { EmergencyUnblockManager.status() }
    var countEnabled by remember { mutableStateOf(CountManager.isCountingEnabled()) }
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Space.margin)
            .padding(bottom = Space.tabBarClearance)
    ) {
        // Header
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(Metrics.headerButton)
                .padding(top = Space.xs),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "Settings",
                style = OpenBlockerTextStyle.headline.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Medium),
                color = MaterialTheme.colorScheme.onBackground
            )
        }
        
        Spacer(modifier = Modifier.height(Space.l))
        
        // Emergency Unblock, Help, Contact, About, Privacy
        SettingsGroup {
            SettingsRow(
                icon = "lifepreserver",
                title = "Emergency Unblock",
                detail = "${emergencyStatus.remaining} left",
                testTag = "settings_emergency",
                onClick = onNavigateToEmergencyUnblock
            )
            HairlineDivider()
            SettingsRow(
                icon = "help",
                title = "Help",
                testTag = "settings_help",
                onClick = onNavigateToHelp
            )
            HairlineDivider()
            SettingsRow(
                icon = "contact",
                title = "Contact",
                testTag = "settings_contact",
                onClick = onNavigateToContact
            )
            HairlineDivider()
            SettingsRow(
                icon = "about",
                title = "About",
                testTag = "settings_about",
                onClick = onNavigateToAbout
            )
            HairlineDivider()
            SettingsRow(
                icon = "privacy",
                title = "Privacy",
                testTag = "settings_privacy",
                onClick = onNavigateToPrivacy
            )
        }
        
        Spacer(modifier = Modifier.height(Space.m))
        
        // Appearance
        SettingsGroup {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(Space.m),
                verticalArrangement = Arrangement.spacedBy(Space.s)
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(Space.s),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RowGlyph(iconName = "appearance")
                    Text(
                        text = "Appearance",
                        style = OpenBlockerTextStyle.body.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Medium),
                        color = MaterialTheme.colorScheme.onBackground
                    )
                }
                
                SegmentedPill(
                    options = listOf(
                        "Light" to AppAppearance.LIGHT,
                        "Dark" to AppAppearance.DARK,
                        "System" to AppAppearance.SYSTEM
                    ),
                    selectedValue = appearance,
                    onValueChange = { AppearanceManager.setAppearance(it) },
                    testTag = "appearance_picker"
                )
            }
        }
        
        Spacer(modifier = Modifier.height(Space.m))
        
        // Share anonymous count
        SettingsGroup {
            SettingsToggleRow(
                icon = "person",
                title = "Share anonymous count",
                subtitle = "Helps us count users. No personal data.",
                isOn = countEnabled,
                onToggle = {
                    CountManager.setCountingEnabled(it)
                    countEnabled = it
                },
                testTag = "count_toggle"
            )
        }
        
        Spacer(modifier = Modifier.height(Space.l))
        
        // Brand and version
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Space.xxs)
        ) {
            BrandMark(size = 30.dp)
            
            Spacer(modifier = Modifier.height(Space.xxs))
            
            Text(
                text = "Open Blocker",
                style = OpenBlockerTextStyle.headline,
                color = MaterialTheme.colorScheme.onBackground
            )
            
            Text(
                text = "Version ${BuildConfig.VERSION_NAME} · MIT License",
                style = OpenBlockerTextStyle.footnote.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Normal),
                color = MaterialTheme.colorScheme.outline
            )
        }
        
        Spacer(modifier = Modifier.height(Space.l))
    }
}

@Composable
fun BrandMark(size: androidx.compose.ui.unit.Dp, modifier: Modifier = Modifier) {
    // Placeholder for brand mark - would need the actual logo asset
    Box(
        modifier = modifier
            .size(size)
            .background(
                color = androidx.compose.ui.graphics.Color(0xFF4450F2),
                shape = androidx.compose.foundation.shape.CircleShape
            )
    )
}
