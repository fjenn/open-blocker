package app.openblocker.android.ui.screens

import android.content.Intent
import android.content.pm.PackageManager
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.GlyphIcon
import app.openblocker.android.ui.components.HairlineDivider
import app.openblocker.android.ui.components.PushedHeader
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.obColors
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class AppInfo(
    val packageName: String,
    val label: String,
    val isBlocked: Boolean
)

@Composable
fun AppPickerScreen(
    onBack: () -> Unit,
    initialSelected: Set<String>? = null,
    title: String = "Select Apps to Block",
    onSave: ((Set<String>) -> Unit)? = null
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val apps = remember { mutableStateListOf<AppInfo>() }
    val isLoading = remember { mutableStateOf(true) }
    val loadError = remember { mutableStateOf<String?>(null) }
    val colors = obColors()

    LaunchedEffect(Unit) {
        scope.launch {
            try {
                val installedApps = withContext(Dispatchers.IO) {
                    loadInstalledApps(context.packageManager, context.packageName, initialSelected)
                }
                apps.clear()
                apps.addAll(installedApps)
                loadError.value = null
            } catch (e: Exception) {
                loadError.value = "Could not load apps: ${e.message ?: "unknown error"}"
            } finally {
                isLoading.value = false
            }
        }
    }

    Column(Modifier.fillMaxSize().background(colors.canvas)) {
        PushedHeader(title, onBack = {
            if (onSave != null) {
                onSave(apps.filter { it.isBlocked }.map { it.packageName }.toSet())
            } else {
                onBack()
            }
        })
        when {
            isLoading.value -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Loading apps…", style = ObText.body, color = colors.inkSecondary)
            }
            loadError.value != null -> Box(Modifier.fillMaxSize().padding(Space.xl), contentAlignment = Alignment.Center) {
                Text(loadError.value ?: "", style = ObText.body, color = colors.ink)
            }
            apps.isEmpty() -> Box(Modifier.fillMaxSize().padding(Space.xl), contentAlignment = Alignment.Center) {
                Text("No launchable apps found on this device.", style = ObText.body, color = colors.inkSecondary)
            }
            else -> LazyColumn(Modifier.fillMaxSize().testTag("app_picker_list")) {
                items(apps, key = { it.packageName }) { app ->
                    AppItem(
                        app = app,
                        onToggle = { packageName, isBlocked ->
                            if (onSave == null) {
                                if (isBlocked) {
                                    PreferencesManager.addBlockedApp(packageName)
                                } else {
                                    PreferencesManager.removeBlockedApp(packageName)
                                }
                            }
                            val index = apps.indexOfFirst { it.packageName == packageName }
                            if (index >= 0) {
                                apps[index] = apps[index].copy(isBlocked = isBlocked)
                            }
                        }
                    )
                    HairlineDivider()
                }
            }
        }
    }
}

@Composable
fun AppItem(app: AppInfo, onToggle: (String, Boolean) -> Unit) {
    val colors = obColors()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("app_row_${app.packageName}")
            .clickable { onToggle(app.packageName, !app.isBlocked) }
            .padding(horizontal = Space.margin, vertical = Space.s),
        horizontalArrangement = Arrangement.spacedBy(Space.s),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(app.label, style = ObText.body, color = colors.ink)
            Text(app.packageName, style = ObText.caption, color = colors.inkTertiary)
        }
        Box(
            Modifier
                .background(if (app.isBlocked) colors.ink else colors.fillQuiet, CircleShape)
                .padding(6.dp),
            contentAlignment = Alignment.Center
        ) {
            if (app.isBlocked) {
                GlyphIcon(Glyph.Check, colors.inkInverse, size = 12.dp)
            }
        }
    }
}

private fun loadInstalledApps(
    packageManager: PackageManager,
    selfPackage: String,
    initialSelected: Set<String>? = null
): List<AppInfo> {
    val blockedApps = initialSelected ?: PreferencesManager.getBlockedApps()
    val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
    val resolved = packageManager.queryIntentActivities(launcher, PackageManager.MATCH_ALL)

    return resolved
        .map { it.activityInfo.applicationInfo }
        .distinctBy { it.packageName }
        .filter { app ->
            LaunchableApps.shouldList(app.packageName, hasLauncherIcon = true, selfPackage = selfPackage)
        }
        .map { app ->
            AppInfo(
                packageName = app.packageName,
                label = app.loadLabel(packageManager).toString(),
                isBlocked = blockedApps.contains(app.packageName)
            )
        }
        .sortedBy { it.label.lowercase() }
}
