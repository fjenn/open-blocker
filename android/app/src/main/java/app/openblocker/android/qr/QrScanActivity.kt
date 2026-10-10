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
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import app.openblocker.android.data.AppearanceManager
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.IconTile
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.permissions.PermissionStatusReader
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.OpenBlockerTheme
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.obColors
import com.google.zxing.BarcodeFormat
import com.journeyapps.barcodescanner.DecoratedBarcodeView
import com.journeyapps.barcodescanner.DefaultDecoderFactory

class QrScanActivity : ComponentActivity() {

    private var permissionDenied by mutableStateOf(false)
    private var cameraGranted by mutableStateOf(false)
    private var barcodeView: DecoratedBarcodeView? = null
    private var delivered = false

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        PermissionStatusReader.markAsked(this, "camera")
        cameraGranted = granted
        permissionDenied = !granted
    }

    @OptIn(ExperimentalComposeUiApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        cameraGranted = hasCameraPermission()
        if (!cameraGranted) {
            PermissionStatusReader.markAsked(this, "camera")
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
        setContent {
            val appearance by AppearanceManager.appearance
            OpenBlockerTheme(appearance) {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .semantics { testTagsAsResourceId = true },
                    color = obColors().canvas
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
                                PermissionStatusReader.markAsked(this, "camera")
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
    val colors = obColors()
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.canvas)
            .padding(horizontal = Space.margin)
            .testTag("qr_permission_screen"),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        IconTile(Glyph.Camera, size = 56.dp)
        Spacer(Modifier.height(Space.m))
        Text(
            if (denied) "Camera is off" else "Camera",
            style = ObText.title.copy(fontWeight = FontWeight.Medium),
            color = colors.ink,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(Space.s))
        Text(
            text = if (denied) {
                "Open Blocker uses the camera only to scan your QR key. Turn on Camera in Settings."
            } else {
                "Open Blocker uses the camera only to scan your QR key."
            },
            style = ObText.body,
            color = colors.inkSecondary,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(Space.xl))
        PrimaryButton(
            if (denied) "Open Settings" else "Allow camera",
            emphasis = ButtonEmphasis.INK,
            testTag = if (denied) "qr_open_settings" else "qr_request_camera",
            onClick = if (denied) onOpenSettings else onRequest
        )
        Spacer(Modifier.height(Space.s))
        PrimaryButton("Cancel", onClick = onCancel)
    }
}
