package app.openblocker.android.qr

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import app.openblocker.android.ui.theme.OpenBlockerTheme
import com.journeyapps.barcodescanner.DecoratedBarcodeView
import com.journeyapps.barcodescanner.DefaultDecoderFactory
import com.google.zxing.BarcodeFormat

class QrScanActivity : ComponentActivity() {

    private var permissionDenied by mutableStateOf(false)
    private var cameraGranted by mutableStateOf(false)
    private var barcodeView: DecoratedBarcodeView? = null
    private var delivered = false

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        cameraGranted = granted
        permissionDenied = !granted
    }

    @OptIn(ExperimentalComposeUiApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cameraGranted = hasCameraPermission()
        if (!cameraGranted) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
        setContent {
            OpenBlockerTheme {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .semantics { testTagsAsResourceId = true }
                ) {
                    if (cameraGranted) {
                        ScannerPane(
                            onViewCreated = { view ->
                                barcodeView = view
                                startDecoding(view)
                                try {
                                    view.resume()
                                } catch (_: RuntimeException) {
                                    permissionDenied = true
                                    cameraGranted = false
                                }
                            }
                        )
                    } else {
                        PermissionPane(
                            denied = permissionDenied,
                            onRequest = {
                                permissionLauncher.launch(Manifest.permission.CAMERA)
                            },
                            onOpenSettings = {
                                startActivity(
                                    Intent(
                                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                        Uri.fromParts("package", packageName, null)
                                    )
                                )
                            },
                            onCancel = { finish() }
                        )
                    }
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        cameraGranted = hasCameraPermission()
        if (cameraGranted) {
            permissionDenied = false
            barcodeView?.resume()
        }
    }

    override fun onPause() {
        barcodeView?.pause()
        super.onPause()
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun startDecoding(view: DecoratedBarcodeView) {
        try {
            view.barcodeView.decoderFactory = DefaultDecoderFactory(listOf(BarcodeFormat.QR_CODE))
            view.decodeContinuous { result ->
                val text = result?.text ?: return@decodeContinuous
                if (delivered) return@decodeContinuous
                delivered = true
                setResult(RESULT_OK, Intent().putExtra(EXTRA_PAYLOAD, text))
                finish()
            }
        } catch (_: RuntimeException) {
            permissionDenied = true
            cameraGranted = false
        }
    }

    companion object {
        const val EXTRA_PAYLOAD = "qr_payload"
        const val EXTRA_MODE = "qr_mode"
        const val MODE_REGISTER = "register"
        const val MODE_SESSION = "session"

        fun intent(context: Context, mode: String): Intent {
            return Intent(context, QrScanActivity::class.java).putExtra(EXTRA_MODE, mode)
        }
    }
}

@Composable
private fun ScannerPane(onViewCreated: (DecoratedBarcodeView) -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .testTag("qr_scan_screen")
    ) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { context ->
                DecoratedBarcodeView(context).also { view ->
                    view.setStatusText("Point the camera at your Open Blocker QR key")
                    onViewCreated(view)
                }
            }
        )
    }
}

@Composable
private fun PermissionPane(
    denied: Boolean,
    onRequest: () -> Unit,
    onOpenSettings: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
            .testTag("qr_permission_screen"),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = if (denied) {
                "Camera access is required to scan QR keys. Enable it in Settings, or go back."
            } else {
                "Open Blocker needs the camera only while you scan a QR key."
            },
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = if (denied) onOpenSettings else onRequest,
            modifier = Modifier
                .fillMaxWidth()
                .testTag(if (denied) "qr_open_settings" else "qr_request_camera")
        ) {
            Text(if (denied) "Open Settings" else "Allow camera")
        }
        Spacer(modifier = Modifier.height(8.dp))
        OutlinedButton(onClick = onCancel, modifier = Modifier.fillMaxWidth()) {
            Text("Cancel")
        }
    }
}
