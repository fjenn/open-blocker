package app.openblocker.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.openblocker.android.key.KeyMatcher
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.GlyphIcon
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.RoundIconButton
import app.openblocker.android.ui.theme.AppAppearance
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.OpenBlockerTheme
import app.openblocker.android.ui.theme.Radius
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.asCopy
import app.openblocker.android.ui.theme.obColors

@Composable
fun QrPasteScreen(onClose: () -> Unit, onUsed: (String) -> Unit = {}, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    var payload by remember { mutableStateOf("") }
    OpenBlockerTheme(AppAppearance.DARK) {
        QrPasteContent(
            payload = payload,
            onPayload = { payload = it },
            onClose = onClose,
            onUse = {
                val trimmed = payload.trim()
                if (trimmed.isEmpty()) return@QrPasteContent
                KeyMatcher.onQrScanned(context, trimmed)
                onUsed(trimmed)
                onClose()
            },
            modifier = modifier
        )
    }
}

@Composable
fun QrPasteContent(
    payload: String,
    onPayload: (String) -> Unit,
    onClose: () -> Unit,
    onUse: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    Box(modifier.fillMaxSize().background(androidx.compose.ui.graphics.Color.Black).testTag("qr_paste_screen")) {
        Column(Modifier.fillMaxSize().padding(horizontal = Space.margin)) {
            Box(Modifier.fillMaxWidth().padding(top = Space.l)) {
                Text(
                    "Scan your QR key".asCopy(),
                    style = ObText.headline.copy(fontWeight = FontWeight.Medium),
                    color = androidx.compose.ui.graphics.Color.White,
                    modifier = Modifier.align(Alignment.Center)
                )
                RoundIconButton(
                    Glyph.Close,
                    "Cancel",
                    Modifier.align(Alignment.CenterEnd).testTag("qr_paste_close"),
                    "qr_paste_close",
                    onClose
                )
            }
            Spacer(Modifier.weight(1f))
            Column(
                Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Space.m)
            ) {
                GlyphIcon(Glyph.Qr, androidx.compose.ui.graphics.Color.White.copy(alpha = 0.8f), size = 54.dp)
                Text(
                    "The emulator has no camera.\nPaste an Open Blocker QR payload to test matching.".asCopy(),
                    style = ObText.subhead,
                    color = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.75f),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = Space.xl)
                )
                TextField(
                    value = payload,
                    onValueChange = onPayload,
                    placeholder = {
                        Text(
                            "openblocker://tag/v1/...",
                            style = ObText.subhead,
                            color = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.45f)
                        )
                    },
                    singleLine = true,
                    textStyle = ObText.subhead.copy(color = androidx.compose.ui.graphics.Color.White),
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.12f),
                        unfocusedContainerColor = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.12f),
                        focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                        unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                        cursorColor = androidx.compose.ui.graphics.Color.White
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = Space.xl)
                        .height(52.dp)
                        .background(androidx.compose.ui.graphics.Color.Transparent, RoundedCornerShape(Radius.input))
                        .testTag("qr_payload")
                )
                PrimaryButton(
                    "Use payload",
                    emphasis = ButtonEmphasis.INK,
                    testTag = "use_payload",
                    onClick = onUse,
                    modifier = Modifier.padding(horizontal = Space.xxxl)
                )
            }
            Spacer(Modifier.weight(1f))
        }
    }
}
