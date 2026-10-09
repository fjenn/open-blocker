package app.openblocker.android.ui.screens

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
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
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.CardSurface
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.PushedHeader
import app.openblocker.android.ui.components.ScrollColumn
import app.openblocker.android.ui.permissions.PermissionKind
import app.openblocker.android.ui.permissions.PermissionStatusReader
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.obColors

@Composable
fun QrKeyScreen(
    onBack: () -> Unit,
    onDenied: (PermissionKind) -> Unit = {}
) {
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
    val cameraLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        PermissionStatusReader.markAsked(context, "camera")
        if (granted) {
            scanLauncher.launch(QrScanActivity.intent(context, QrScanActivity.MODE_REGISTER))
        } else {
            onDenied(PermissionKind.CAMERA)
        }
    }

    fun openScanner() {
        PermissionStatusReader.handleRuntime(
            status = PermissionStatusReader.camera(context),
            request = {
                PermissionStatusReader.markAsked(context, "camera")
                cameraLauncher.launch(Manifest.permission.CAMERA)
            },
            granted = { scanLauncher.launch(QrScanActivity.intent(context, QrScanActivity.MODE_REGISTER)) },
            denied = { onDenied(PermissionKind.CAMERA) }
        )
    }

    val colors = obColors()
    Column(Modifier.fillMaxSize().background(colors.canvas).testTag("qr_key_screen")) {
        PushedHeader("Printed QR key", onBack)
        ScrollColumn {
            Text(
                "Generate a printable Open Blocker QR, or scan one you already printed. The same URI works on both apps.",
                style = ObText.body,
                color = colors.inkSecondary,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(Space.m))
            CardSurface {
                Column(
                    Modifier.padding(Space.l),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(Space.s)
                ) {
                    val image = bitmap
                    if (image != null) {
                        Image(
                            bitmap = image.asImageBitmap(),
                            contentDescription = "Open Blocker QR key",
                            modifier = Modifier.size(240.dp).testTag("qr_preview")
                        )
                        Text(payload ?: "", style = ObText.footnote, color = colors.inkSecondary, textAlign = TextAlign.Center)
                    } else {
                        Text("No QR generated yet", style = ObText.body, color = colors.inkSecondary)
                    }
                    PrimaryButton(
                        "Generate QR code",
                        emphasis = ButtonEmphasis.INK,
                        testTag = "generate_qr",
                        onClick = {
                            val data = OpenBlockerFormat.TagData(tagId = OpenBlockerFormat.generateTagId())
                            val uri = OpenBlockerFormat.encodeForQR(data)
                            KeyMatcher.registerQr(uri)
                            payload = uri
                            bitmap = QrBitmaps.toBitmap(uri)
                            Toast.makeText(context, "QR key saved. Print or share it.", Toast.LENGTH_SHORT).show()
                        }
                    )
                    if (bitmap != null) {
                        PrimaryButton(
                            "Share or print",
                            testTag = "share_qr",
                            onClick = {
                                val uri = QrBitmaps.shareUri(context, bitmap!!)
                                val share = Intent(Intent.ACTION_SEND).apply {
                                    type = "image/png"
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    putExtra(Intent.EXTRA_TEXT, payload)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                context.startActivity(Intent.createChooser(share, "Share QR key"))
                            }
                        )
                    }
                }
            }
            Spacer(Modifier.height(Space.m))
            CardSurface {
                Column(Modifier.padding(Space.l), verticalArrangement = Arrangement.spacedBy(Space.s)) {
                    Text("Scan an existing QR", style = ObText.headline, color = colors.ink)
                    Text(
                        "Register a printed Open Blocker QR as a key on this phone.",
                        style = ObText.body,
                        color = colors.inkSecondary
                    )
                    PrimaryButton("Scan with camera", testTag = "scan_to_register", onClick = { openScanner() })
                }
            }
        }
    }
}
