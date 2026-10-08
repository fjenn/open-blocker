package app.openblocker.android.ui.screens

import android.app.Activity
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import app.openblocker.android.BuildConfig
import app.openblocker.android.data.CountManager
import app.openblocker.android.data.PreferencesManager
import app.openblocker.android.data.SessionManager
import app.openblocker.android.key.KeyMatcher
import app.openblocker.android.qr.QrScanActivity
import app.openblocker.android.util.AccessibilityUtil

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onNavigateToAppPicker: () -> Unit,
    onNavigateToTagPairing: () -> Unit,
    onNavigateToQrKey: () -> Unit,
    onNavigateToDebug: () -> Unit
) {
    val context = LocalContext.current
    val isBlocking by SessionManager.isBlocking.collectAsState()
    val blockedApps = remember { mutableStateOf(PreferencesManager.getBlockedApps()) }
    val isAccessibilityEnabled = remember { mutableStateOf(AccessibilityUtil.isAccessibilityServiceEnabled(context)) }
    val showRestrictedSettingsWarning = remember { 
        mutableStateOf(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !isAccessibilityEnabled.value)
    }
    val countMeEnabled = remember { mutableStateOf(CountManager.isCountingEnabled()) }
    val pairedKeyCount = remember { mutableStateOf(PreferencesManager.getPairedKeyCount()) }
    val lifecycleOwner = LocalLifecycleOwner.current

    fun refreshHomeState() {
        blockedApps.value = PreferencesManager.getBlockedApps()
        isAccessibilityEnabled.value = AccessibilityUtil.isAccessibilityServiceEnabled(context)
        showRestrictedSettingsWarning.value = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !isAccessibilityEnabled.value
        countMeEnabled.value = CountManager.isCountingEnabled()
        pairedKeyCount.value = PreferencesManager.getPairedKeyCount()
    }

    val qrScanLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode != Activity.RESULT_OK) return@rememberLauncherForActivityResult
        val raw = result.data?.getStringExtra(QrScanActivity.EXTRA_PAYLOAD) ?: return@rememberLauncherForActivityResult
        KeyMatcher.onQrScanned(context, raw)
        refreshHomeState()
    }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                refreshHomeState()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Open Blocker") }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
                .testTag("home_screen"),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(modifier = Modifier.height(16.dp))
            
            if (BuildConfig.TEST_MODE) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "⚠ TEST BUILD",
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            textAlign = TextAlign.Center
                        )
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        
                        Text(
                            text = "This build includes test features that allow bypassing the physical key requirement. Do not use for actual focus sessions.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            textAlign = TextAlign.Center
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = if (isBlocking) 
                        MaterialTheme.colorScheme.primaryContainer 
                    else 
                        MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = if (isBlocking) "🔒 Blocking Active" else "⏸️ Not Blocking",
                        style = MaterialTheme.typography.headlineSmall,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.testTag("home_status")
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = if (isBlocking)
                            "Tap your NFC tag or scan your QR key to end the session"
                        else
                            "Tap your NFC tag or scan your QR key to start blocking",
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = TextAlign.Center
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Blocked Apps",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    Text(
                        text = if (blockedApps.value.isEmpty()) 
                            "No apps blocked yet" 
                        else 
                            "${blockedApps.value.size} apps blocked",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.testTag("blocked_apps_count")
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Button(
                        onClick = { 
                            onNavigateToAppPicker()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("manage_blocked_apps")
                    ) {
                        Text("Manage Blocked Apps")
                    }
                }
            }
            
            if (BuildConfig.TEST_MODE && blockedApps.value.isNotEmpty()) {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Quick Test",
                            style = MaterialTheme.typography.titleMedium,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                        
                        Text(
                            text = "For testing: toggle blocking without tapping your key",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                        
                        Button(
                            onClick = { 
                                if (isBlocking) {
                                    SessionManager.endSession()
                                } else {
                                    SessionManager.startSession()
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (isBlocking) 
                                    MaterialTheme.colorScheme.error 
                                else 
                                    MaterialTheme.colorScheme.primary
                            )
                        ) {
                            Text(if (isBlocking) "Stop Session (Test)" else "Start Session (Test)")
                        }
                    }
                }
            }
            
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "NFC Tags",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    Text(
                        text = if (pairedKeyCount.value == 0) {
                            "Write or pair an NFC tag, or add a printed QR, to use as your physical blocker key"
                        } else {
                            "${pairedKeyCount.value} key(s) paired. Tap a paired tag or card, or scan a paired QR, to start or stop blocking."
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Button(
                        onClick = { onNavigateToTagPairing() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Pair NFC Tag")
                    }
                }
            }

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Printed QR key",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    Text(
                        text = "Generate a printable QR or scan one you already printed. Same format as iPhone: openblocker://tag/v1/{32 hex chars}.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = { onNavigateToQrKey() },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("add_qr_key")
                    ) {
                        Text("Add QR key")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedButton(
                        onClick = {
                            qrScanLauncher.launch(
                                QrScanActivity.intent(context, QrScanActivity.MODE_SESSION)
                            )
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("scan_qr_key")
                    ) {
                        Text("Scan QR to start or stop")
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "⚠ Honesty Note",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    Text(
                        text = "A determined user can get around the block on Android (for example via safe mode, uninstalling the app, turning off the Accessibility service, or ADB). Open Blocker adds friction, not a lock. It is a tool for people who want to focus, not a security mechanism.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            if (showRestrictedSettingsWarning.value) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "⚠ Android 13+ Restricted Settings",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                        
                        Text(
                            text = "On Android 13 and later, sideloaded apps cannot enable accessibility services directly. You must:",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                        
                        Text(
                            text = "1. Open this app's settings\n2. Allow restricted settings\n3. Return and enable accessibility",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                        
                        Button(
                            onClick = { AccessibilityUtil.openAppSettings(context) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Text("Open App Settings")
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Accessibility Permission",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    if (isAccessibilityEnabled.value) {
                        Text(
                            text = "✓ Accessibility service is enabled",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier
                                .padding(bottom = 8.dp)
                                .testTag("accessibility_enabled")
                        )
                    } else {
                        Text(
                            text = "Open Blocker needs accessibility permission to detect when blocked apps are opened and show the block screen.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Button(
                        onClick = { AccessibilityUtil.openAccessibilitySettings(context) },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Open Accessibility Settings")
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            if (BuildConfig.COUNT_ENABLED) {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Count me",
                                style = MaterialTheme.typography.titleMedium,
                                modifier = Modifier.padding(bottom = 4.dp)
                            )
                            
                            Text(
                                text = "Send one anonymous ping once, after the app successfully blocks an app for you (helps us understand reach).",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        
                        Switch(
                            checked = countMeEnabled.value,
                            onCheckedChange = { enabled ->
                                CountManager.setCountingEnabled(enabled)
                                countMeEnabled.value = enabled
                            }
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            TextButton(
                onClick = { onNavigateToDebug() },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Debug Info (for testing)")
            }
            
            Text(
                text = "Open Blocker v${BuildConfig.VERSION_NAME}\nOpen source physical phone blocker",
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
