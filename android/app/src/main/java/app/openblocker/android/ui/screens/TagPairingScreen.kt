package app.openblocker.android.ui.screens

import android.app.PendingIntent
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.openblocker.android.MainActivity
import app.openblocker.android.nfc.NfcHandler
import app.openblocker.android.data.PairingStateManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TagPairingScreen(
    onBack: () -> Unit,
    onNavigateToAnyCard: () -> Unit
) {
    val context = LocalContext.current
    val pairingMode by PairingStateManager.mode.collectAsState()
    
    DisposableEffect(Unit) {
        onDispose {
            if (pairingMode != PairingStateManager.Mode.None) {
                PairingStateManager.clearMode()
            }
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Pair NFC Tag") },
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
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "Choose how to pair your NFC tag",
                style = MaterialTheme.typography.headlineSmall,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Write Open Blocker Format",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    Text(
                        text = "Write the Open Blocker tag format to a new or existing NFC tag. This is the recommended method.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )
                    
                    Button(
                        onClick = { PairingStateManager.setMode(PairingStateManager.Mode.WriteTag) },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Write Tag")
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
                        text = "Pair by UID (Fallback)",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    Text(
                        text = "You can use an existing tag without modifying it. The app will recognize it by its hardware UID. You can also register many NFC cards you already own (many transit cards, hotel keys, work badges). Test yours.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )
                    
                    OutlinedButton(
                        onClick = { PairingStateManager.setMode(PairingStateManager.Mode.PairByUid) },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Pair by UID")
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    OutlinedButton(
                        onClick = { onNavigateToAnyCard() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Pair Any Card (Transit, Hotel, Badge)")
                    }
                }
            }
            
            if (pairingMode != PairingStateManager.Mode.None) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "📱",
                            style = MaterialTheme.typography.displayMedium
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = when (pairingMode) {
                                is PairingStateManager.Mode.WriteTag -> "Ready to write tag"
                                is PairingStateManager.Mode.PairByUid -> "Ready to pair tag by UID"
                                else -> ""
                            },
                            style = MaterialTheme.typography.titleLarge,
                            textAlign = TextAlign.Center
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = "Hold your NFC tag near the back of your phone",
                            style = MaterialTheme.typography.bodyMedium,
                            textAlign = TextAlign.Center
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        TextButton(onClick = { PairingStateManager.clearMode() }) {
                            Text("Cancel")
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            Text(
                text = "Note: NFC must be enabled in your phone settings",
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
