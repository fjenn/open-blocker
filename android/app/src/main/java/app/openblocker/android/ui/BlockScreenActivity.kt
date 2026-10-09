package app.openblocker.android.ui

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.nfc.NfcAdapter
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.lifecycleScope
import app.openblocker.android.data.AppearanceManager
import app.openblocker.android.data.SessionManager
import app.openblocker.android.domain.DurationText
import app.openblocker.android.key.KeyMatcher
import app.openblocker.android.nfc.NfcDispatch
import app.openblocker.android.nfc.NfcHandler
import app.openblocker.android.qr.QrScanActivity
import app.openblocker.android.ui.components.KeyModelScene
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.permissions.PermissionStatusReader
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.OpenBlockerTheme
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.obColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class BlockScreenActivity : ComponentActivity() {

    companion object {
        const val EXTRA_WEBSITE = "website"
    }

    private var nfcAdapter: NfcAdapter? = null
    private val nfcHandler = NfcHandler()
    private val qrScanLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode != Activity.RESULT_OK) return@registerForActivityResult
        val raw = result.data?.getStringExtra(QrScanActivity.EXTRA_PAYLOAD) ?: return@registerForActivityResult
        KeyMatcher.onQrScanned(this, raw)
    }
    private val cameraLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        PermissionStatusReader.markAsked(this, "camera")
        if (granted) {
            qrScanLauncher.launch(QrScanActivity.intent(this, QrScanActivity.MODE_SESSION))
        }
    }

    @OptIn(ExperimentalComposeUiApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                finish()
            }
        })

        setContent {
            val appearance by AppearanceManager.appearance
            OpenBlockerTheme(appearance) {
                BlockScreen(
                    onClose = { finish() },
                    onScanQr = { openQr() },
                    website = intent.getBooleanExtra(EXTRA_WEBSITE, false)
                )
            }
        }

        lifecycleScope.launch {
            SessionManager.isBlocking.collect { blocking ->
                if (!blocking) finish()
            }
        }

        handleNfcIntent(intent)
    }

    private fun openQr() {
        PermissionStatusReader.handleRuntime(
            status = PermissionStatusReader.camera(this),
            request = {
                PermissionStatusReader.markAsked(this, "camera")
                cameraLauncher.launch(Manifest.permission.CAMERA)
            },
            granted = { qrScanLauncher.launch(QrScanActivity.intent(this, QrScanActivity.MODE_SESSION)) },
            denied = {
                qrScanLauncher.launch(QrScanActivity.intent(this, QrScanActivity.MODE_SESSION))
            }
        )
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
fun BlockScreen(onClose: () -> Unit, onScanQr: () -> Unit = {}, website: Boolean = false) {
    val colors = obColors()
    val start by SessionManager.sessionStartTime.collectAsState()
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(start) {
        while (true) {
            now = System.currentTimeMillis()
            delay(1000)
        }
    }
    val seconds = if (start > 0) (now - start) / 1000 else 0L
    Surface(
        modifier = Modifier.fillMaxSize().semantics { testTagsAsResourceId = true },
        color = colors.canvas
    ) {
        Column(
            Modifier.fillMaxSize().padding(Space.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("Blocked for", style = ObText.footnote, color = colors.inkSecondary)
            Text(
                DurationText.clock(seconds),
                style = ObText.timer,
                color = colors.ink,
                modifier = Modifier.testTag("blocked_timer")
            )
            Spacer(Modifier.height(Space.l))
            KeyModelScene(progress = 1f, yaw = 0.18f, locked = true, burst = 0.45f, modifier = Modifier.size(220.dp).testTag("block_screen"))
            Spacer(Modifier.height(Space.l))
            Text(
                if (website) "This site is blocked" else "This app is blocked",
                style = ObText.title,
                color = colors.ink,
                textAlign = TextAlign.Center
            )
            Text(
                "Tap your NFC key or scan your QR key to end the session.",
                style = ObText.body,
                color = colors.inkSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = Space.s)
            )
            Spacer(Modifier.height(Space.xl))
            PrimaryButton("Scan your key to unblock", testTag = "block_scan_qr", onClick = onScanQr)
            Spacer(Modifier.height(Space.s))
            PrimaryButton("Go back", onClick = onClose)
        }
    }
}
