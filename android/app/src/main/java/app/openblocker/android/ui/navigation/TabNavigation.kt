package app.openblocker.android.ui.navigation

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import app.openblocker.android.ui.theme.*

enum class AppTab(val displayName: String, val testTag: String) {
    BLOCK("Block", "tab_block"),
    SCHEDULE("Schedule", "tab_schedule"),
    ACTIVITY("Activity", "tab_activity"),
    SETTINGS("Settings", "tab_settings")
}

/**
 * Text-only tab bar matching iOS design.
 * The selected tab is bold with a dot under it.
 */
@Composable
fun TextTabBar(
    selectedTab: AppTab,
    onTabSelected: (AppTab) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(Metrics.tabBarHeight)
            .padding(horizontal = Space.xs),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        AppTab.values().forEach { tab ->
            TabItem(
                tab = tab,
                isSelected = selectedTab == tab,
                onClick = { onTabSelected(tab) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun TabItem(
    tab: AppTab,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxHeight()
            .clip(androidx.compose.foundation.shape.RoundedCornerShape(0.dp))
            .clickable(onClick = onClick)
            .testTag(tab.testTag),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = tab.displayName,
            style = OpenBlockerTextStyle.subhead.copy(
                fontWeight = if (isSelected) {
                    androidx.compose.ui.text.font.FontWeight.SemiBold
                } else {
                    androidx.compose.ui.text.font.FontWeight.Medium
                }
            ),
            color = if (isSelected) {
                MaterialTheme.colorScheme.onBackground
            } else {
                MaterialTheme.colorScheme.onSurfaceVariant
            }
        )
        
        Spacer(modifier = Modifier.height(5.dp))
        
        Box(
            modifier = Modifier
                .size(4.dp)
                .clip(CircleShape)
                .background(
                    if (isSelected) {
                        MaterialTheme.colorScheme.onBackground
                    } else {
                        Color.Transparent
                    }
                )
        )
    }
}
