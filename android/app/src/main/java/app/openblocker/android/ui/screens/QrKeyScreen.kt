package app.openblocker.android.ui.screens

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.openblocker.android.format.OpenBlockerFormat
import app.openblocker.android.key.KeyMatcher
import app.openblocker.android.qr.QrBitmaps
import app.openblocker.android.qr.QrScanActivity

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QrKeyScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    var payload by remember { mutableStateOf<String?>(null) }
    var bitmap by remember { mutableStateOf<Bitmap?>(null) }

    val scanLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode != Activity.RESULT_OK) return@rememberLauncherForActivityResult
        val raw = result.data?.getStringExtra(QrScanActivity.EXTRA_PAYLOAD) ?: return@rememberLauncherForActivityResult
        val saved = KeyMatcher.registerQr(raw)
        if (saved == null) {
            Toast.makeText(context, "This QR is not an Open Blocker key.", Toast.LENGTH_LONG).show()
        } else {
            payload = saved
            bitmap = QrBitmaps.toBitmap(saved)
            Toast.makeText(context, "QR key saved. Print or share it, then scan to start or stop blocking.", Toast.LENGTH_LONG).show()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Printed QR key") },
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
                .padding(16.dp)
                .testTag("qr_key_screen"),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Generate a printable Open Blocker QR, or scan one you already printed (including one from iPhone). The same URI works on both apps.",
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center
            )

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    val image = bitmap
                    if (image != null) {
                        Image(
                            bitmap = image.asImageBitmap(),
                            contentDescription = "Open Blocker QR key",
                            modifier = Modifier
                                .size(240.dp)
                                .testTag("qr_preview")
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = payload ?: "",
                            style = MaterialTheme.typography.bodySmall,
                            textAlign = TextAlign.Center
                        )
                    } else {
                        Text(
                            text = "No QR generated yet",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = {
                            val data = OpenBlockerFormat.TagData(
                                tagId = OpenBlockerFormat.generateTagId()
                            )
                            val uri = OpenBlockerFormat.encodeForQR(data)
                            KeyMatcher.registerQr(uri)
                            payload = uri
                            bitmap = QrBitmaps.toBitmap(uri)
                            Toast.makeText(context, "QR key saved. Print or share it.", Toast.LENGTH_SHORT).show()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("generate_qr")
                    ) {
                        Text("Generate QR Code")
                    }
                    if (bitmap != null) {
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedButton(
                            onClick = {
                                val uri = QrBitmaps.shareUri(context, bitmap!!)
                                val share = Intent(Intent.ACTION_SEND).apply {
                                    type = "image/png"
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    putExtra(Intent.EXTRA_TEXT, payload)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                context.startActivity(Intent.createChooser(share, "Share QR key"))
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("share_qr")
                        ) {
                            Text("Share or print")
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
                        text = "Scan an existing QR",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    Text(
                        text = "Register a printed Open Blocker QR (for example one generated on iPhone) as a key on this phone.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )
                    Button(
                        onClick = {
                            scanLauncher.launch(
                                QrScanActivity.intent(context, QrScanActivity.MODE_REGISTER)
                            )
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("scan_to_register")
                    ) {
                        Text("Scan with camera")
                    }
                }
            }
        }
    }
}
