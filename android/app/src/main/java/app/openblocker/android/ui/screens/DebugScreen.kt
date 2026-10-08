package app.openblocker.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.DebugDataManager
import app.openblocker.android.data.PreferencesManager
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DebugScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val lastTagUid = remember { mutableStateOf(DebugDataManager.getLastTagUid()) }
    val lastTagId = remember { mutableStateOf(DebugDataManager.getLastTagId()) }
    val lastTagPackage = remember { mutableStateOf(DebugDataManager.getLastTagPackage()) }
    val lastScanTime = remember { mutableStateOf(DebugDataManager.getLastScanTime()) }
    val lastScanSuccess = remember { mutableStateOf(DebugDataManager.getLastScanSuccess()) }
    val lastScanError = remember { mutableStateOf(DebugDataManager.getLastScanError()) }
    val pairedTagIds = remember { mutableStateOf(PreferencesManager.getPairedTagIds()) }
    val pairedTagUids = remember { mutableStateOf(PreferencesManager.getPairedTagUids()) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Debug Info") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Last Scanned Tag",
                style = MaterialTheme.typography.headlineSmall
            )
            
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    if (lastScanTime.value > 0) {
                        val dateFormat = SimpleDateFormat("MMM dd, HH:mm:ss", Locale.getDefault())
                        Text(
                            text = "Time: ${dateFormat.format(Date(lastScanTime.value))}",
                            style = MaterialTheme.typography.bodyMedium
                        )
                        
                        Text(
                            text = "Status: ${if (lastScanSuccess.value) "✓ Success" else "✗ Failed"}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (lastScanSuccess.value) 
                                MaterialTheme.colorScheme.primary 
                            else 
                                MaterialTheme.colorScheme.error
                        )
                        
                        if (lastTagUid.value != null) {
                            Text(
                                text = "Hardware UID:",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = lastTagUid.value ?: "",
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                            )
                        }
                        
                        if (lastTagId.value != null) {
                            Text(
                                text = "Open Blocker Tag ID:",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = lastTagId.value ?: "",
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                            )
                        }
                        
                        if (lastTagPackage.value != null) {
                            Text(
                                text = "Package: ${lastTagPackage.value}",
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        
                        if (!lastScanSuccess.value && lastScanError.value != null) {
                            Text(
                                text = "Error: ${lastScanError.value}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    } else {
                        Text(
                            text = "No tags scanned yet",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
            
            Text(
                text = "Paired Tags",
                style = MaterialTheme.typography.headlineSmall
            )
            
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Open Blocker Format (${pairedTagIds.value.size}):",
                        style = MaterialTheme.typography.titleSmall
                    )
                    
                    if (pairedTagIds.value.isEmpty()) {
                        Text(
                            text = "None",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        pairedTagIds.value.forEach { id ->
                            Text(
                                text = id,
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = "By UID (${pairedTagUids.value.size}):",
                        style = MaterialTheme.typography.titleSmall
                    )
                    
                    if (pairedTagUids.value.isEmpty()) {
                        Text(
                            text = "None",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        pairedTagUids.value.forEach { uid ->
                            Text(
                                text = uid,
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                            )
                        }
                    }
                }
            }
            
            Button(
                onClick = {
                    lastTagUid.value = DebugDataManager.getLastTagUid()
                    lastTagId.value = DebugDataManager.getLastTagId()
                    lastTagPackage.value = DebugDataManager.getLastTagPackage()
                    lastScanTime.value = DebugDataManager.getLastScanTime()
                    lastScanSuccess.value = DebugDataManager.getLastScanSuccess()
                    lastScanError.value = DebugDataManager.getLastScanError()
                    pairedTagIds.value = PreferencesManager.getPairedTagIds()
                    pairedTagUids.value = PreferencesManager.getPairedTagUids()
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Refresh")
            }
        }
    }
}
