package app.openblocker.android.ui

import android.app.Activity
import android.content.Intent
import android.nfc.NfcAdapter
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.lifecycleScope
import app.openblocker.android.data.SessionManager
import app.openblocker.android.key.KeyMatcher
import app.openblocker.android.nfc.NfcDispatch
import app.openblocker.android.nfc.NfcHandler
import app.openblocker.android.qr.QrScanActivity
import app.openblocker.android.ui.theme.OpenBlockerTheme
import kotlinx.coroutines.launch

class BlockScreenActivity : ComponentActivity() {

    private var nfcAdapter: NfcAdapter? = null
    private val nfcHandler = NfcHandler()
    private val qrScanLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode != Activity.RESULT_OK) return@registerForActivityResult
        val raw = result.data?.getStringExtra(QrScanActivity.EXTRA_PAYLOAD) ?: return@registerForActivityResult
        KeyMatcher.onQrScanned(this, raw)
    }

    @OptIn(ExperimentalComposeUiApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        nfcAdapter = NfcAdapter.getDefaultAdapter(this)

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                finish()
            }
        })

        setContent {
            OpenBlockerTheme {
                BlockScreen(
                    onClose = { finish() },
                    onScanQr = {
                        qrScanLauncher.launch(
                            QrScanActivity.intent(this, QrScanActivity.MODE_SESSION)
                        )
                    }
                )
            }
        }

        lifecycleScope.launch {
            SessionManager.isBlocking.collect { blocking ->
                if (!blocking) {
                    finish()
                }
            }
        }

        handleNfcIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        NfcDispatch.enable(this, nfcAdapter)
    }

    override fun onPause() {
        super.onPause()
        NfcDispatch.disable(this, nfcAdapter)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleNfcIntent(intent)
    }

    private fun handleNfcIntent(intent: Intent?) {
        val tag = NfcDispatch.tagFrom(intent) ?: return
        nfcHandler.handleTag(this, tag)
    }
}

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun BlockScreen(onClose: () -> Unit, onScanQr: () -> Unit = {}) {
    Surface(
        modifier = Modifier
            .fillMaxSize()
            .semantics { testTagsAsResourceId = true },
        color = MaterialTheme.colorScheme.errorContainer
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "🚫",
                style = MaterialTheme.typography.displayLarge,
                modifier = Modifier.padding(bottom = 24.dp)
            )

            Text(
                text = "App Blocked",
                style = MaterialTheme.typography.headlineLarge,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .padding(bottom = 16.dp)
                    .testTag("block_screen")
            )

            Text(
                text = "This app is blocked during your focus session.\n\nTap your NFC tag or scan your QR key to end the session.",
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onErrorContainer.copy(alpha = 0.7f)
            )

            Spacer(modifier = Modifier.height(32.dp))

            Button(
                onClick = onScanQr,
                modifier = Modifier.testTag("block_scan_qr"),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("Scan QR key")
            }

            Spacer(modifier = Modifier.height(12.dp))

            Button(
                onClick = onClose,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("Go Back")
            }
        }
    }
}
