package app.openblocker.android.ui.screens

import android.content.Intent
import android.content.pm.PackageManager
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.PreferencesManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class AppInfo(
    val packageName: String,
    val label: String,
    val isBlocked: Boolean
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppPickerScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val apps = remember { mutableStateListOf<AppInfo>() }
    val isLoading = remember { mutableStateOf(true) }
    val loadError = remember { mutableStateOf<String?>(null) }
    
    LaunchedEffect(Unit) {
        scope.launch {
            try {
                val installedApps = withContext(Dispatchers.IO) {
                    loadInstalledApps(context.packageManager, context.packageName)
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
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Select Apps to Block") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                }
            )
        }
    ) { padding ->
        if (isLoading.value) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (loadError.value != null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(24.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = loadError.value ?: "",
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        } else if (apps.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(24.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No launchable apps found on this device.",
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .testTag("app_picker_list")
            ) {
                items(apps, key = { it.packageName }) { app ->
                    AppItem(
                        app = app,
                        onToggle = { packageName, isBlocked ->
                            if (isBlocked) {
                                PreferencesManager.addBlockedApp(packageName)
                            } else {
                                PreferencesManager.removeBlockedApp(packageName)
                            }
                            val index = apps.indexOfFirst { it.packageName == packageName }
                            if (index >= 0) {
                                apps[index] = apps[index].copy(isBlocked = isBlocked)
                            }
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun AppItem(app: AppInfo, onToggle: (String, Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("app_row_${app.packageName}")
            .clickable { onToggle(app.packageName, !app.isBlocked) }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = app.label,
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = app.packageName,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        Checkbox(
            checked = app.isBlocked,
            onCheckedChange = { checked ->
                onToggle(app.packageName, checked)
            }
        )
    }
}

private fun loadInstalledApps(
    packageManager: PackageManager,
    selfPackage: String
): List<AppInfo> {
    val blockedApps = PreferencesManager.getBlockedApps()
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
