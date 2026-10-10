package app.openblocker.android.ui.screens

import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.openblocker.android.data.KeyStore
import app.openblocker.android.data.StoredKey
import app.openblocker.android.format.OpenBlockerFormat
import app.openblocker.android.qr.QrBitmaps
import app.openblocker.android.ui.components.ButtonEmphasis
import app.openblocker.android.ui.components.CardSurface
import app.openblocker.android.ui.components.Glyph
import app.openblocker.android.ui.components.GlyphIcon
import app.openblocker.android.ui.components.PrimaryButton
import app.openblocker.android.ui.components.ScrollColumn
import app.openblocker.android.ui.components.SegmentedPill
import app.openblocker.android.ui.components.SettingsGroup
import app.openblocker.android.ui.components.SheetHeader
import app.openblocker.android.ui.haptics.AppHaptics
import app.openblocker.android.ui.theme.Motion
import app.openblocker.android.ui.theme.ObText
import app.openblocker.android.ui.theme.Radius
import app.openblocker.android.ui.theme.Space
import app.openblocker.android.ui.theme.asCopy
import app.openblocker.android.ui.theme.obColors

fun isEmulatorDevice(): Boolean {
    val fingerprint = Build.FINGERPRINT
    val model = Build.MODEL
    val product = Build.PRODUCT
    val hardware = Build.HARDWARE
    return fingerprint.contains("generic", ignoreCase = true) ||
        fingerprint.contains("emulator", ignoreCase = true) ||
        model.contains("sdk", ignoreCase = true) ||
        model.contains("Emulator", ignoreCase = true) ||
        product.contains("sdk", ignoreCase = true) ||
        hardware.contains("ranchu", ignoreCase = true) ||
        hardware.contains("goldfish", ignoreCase = true)
}

@Composable
fun AddKeySheet(onClose: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    var kind by remember { mutableStateOf(StoredKey.Kind.QR) }
    var name by remember { mutableStateOf("") }
    var secret by remember { mutableStateOf("") }
    var qrBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var nfcStatus by remember { mutableStateOf<String?>(null) }
    var nfcGood by remember { mutableStateOf(false) }
    var cardFirst by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }

    fun resetSecret() {
        secret = ""
        qrBitmap = null
        nfcStatus = null
        nfcGood = false
        cardFirst = null
        busy = false
    }

    AddKeyContent(
        kind = kind,
        onKind = {
            kind = it
            resetSecret()
        },
        name = name,
        onName = { name = it },
        secret = secret,
        qrBitmap = qrBitmap,
        nfcStatus = nfcStatus,
        nfcGood = nfcGood,
        cardFirst = cardFirst,
        busy = busy,
        onMakeQr = {
            val data = OpenBlockerFormat.TagData(tagId = OpenBlockerFormat.generateTagId())
            val uri = OpenBlockerFormat.encodeForQR(data)
            secret = uri
            qrBitmap = QrBitmaps.toBitmap(uri)
        },
        onShareQr = {
            val image = qrBitmap ?: return@AddKeyContent
            val uri = QrBitmaps.shareUri(context, image)
            val share = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_TEXT, secret)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(Intent.createChooser(share, "Share QR key"))
        },
        onScanTag = {
            busy = true
            val uid = KeyStore.MOCK_NFC_UID
            secret = uid
            nfcStatus = "Tag ready."
            nfcGood = true
            busy = false
        },
        onScanCard = {
            if (secret.isNotEmpty()) {
                secret = ""
                cardFirst = null
                nfcStatus = null
                nfcGood = false
                return@AddKeyContent
            }
            busy = true
            val uid = KeyStore.MOCK_NFC_UID
            val first = cardFirst
            if (first == null) {
                cardFirst = uid
                nfcStatus = "Got it. Scan the same card once more."
                nfcGood = false
            } else if (first.equals(uid, ignoreCase = true)) {
                secret = uid
                nfcStatus = "Card ready."
                nfcGood = true
            } else {
                cardFirst = null
                nfcStatus = "That card's ID changed between scans. Try another card."
                nfcGood = false
            }
            busy = false
        },
        onClose = onClose,
        onSave = {
            val trimmed = name.trim()
            if (trimmed.isEmpty() || secret.isEmpty()) return@AddKeyContent
            KeyStore.add(StoredKey(name = trimmed, kind = kind, secret = secret))
            AppHaptics.success(context)
            onClose()
        },
        modifier = modifier
    )
}

@Composable
fun AddKeyContent(
    kind: StoredKey.Kind,
    onKind: (StoredKey.Kind) -> Unit,
    name: String,
    onName: (String) -> Unit,
    secret: String,
    qrBitmap: Bitmap?,
    nfcStatus: String?,
    nfcGood: Boolean,
    cardFirst: String?,
    busy: Boolean,
    onMakeQr: () -> Unit,
    onShareQr: () -> Unit,
    onScanTag: () -> Unit,
    onScanCard: () -> Unit,
    onClose: () -> Unit,
    onSave: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = obColors()
    val canSave = name.trim().isNotEmpty() && secret.isNotEmpty()
    Column(modifier.fillMaxSize().background(colors.sheet).testTag("add_key_sheet")) {
        SheetHeader("Add Key", onClose)
        ScrollColumn {
            SegmentedPill(
                options = listOf(
                    "QR code" to StoredKey.Kind.QR,
                    "NFC tag" to StoredKey.Kind.NFC_TAG,
                    "Card" to StoredKey.Kind.CARD
                ),
                selected = kind,
                onSelect = onKind,
                testTag = "key_kind"
            )
            Spacer(Modifier.height(Space.s))
            SettingsGroup {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = Space.m).height(54.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Key Name", style = ObText.subhead, color = colors.inkSecondary)
                    TextField(
                        value = name,
                        onValueChange = onName,
                        placeholder = {
                            Text(kind.placeholder, style = ObText.subhead, color = colors.inkTertiary)
                        },
                        singleLine = true,
                        textStyle = ObText.subhead.copy(fontWeight = FontWeight.SemiBold, color = colors.ink),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent
                        ),
                        modifier = Modifier.weight(1f).testTag("key_name")
                    )
                }
            }
            Spacer(Modifier.height(Space.s))
            AnimatedContent(
                targetState = kind,
                transitionSpec = { fadeIn(Motion.fade) togetherWith fadeOut(Motion.fade) },
                label = "key-kind"
            ) { current ->
                when (current) {
                    StoredKey.Kind.QR -> QrSetupPanel(qrBitmap, secret, onMakeQr, onShareQr)
                    StoredKey.Kind.NFC_TAG -> SetupPanel(
                        glyph = Glyph.Nfc,
                        title = "An NFC sticker",
                        message = "Use a blank NTAG213, 215 or 216. Open Blocker writes its own record onto it.",
                        status = nfcStatus,
                        statusGood = nfcGood,
                        action = if (secret.isEmpty()) "Scan tag" else "Scan again",
                        busy = busy,
                        busyLabel = "Hold it near the phone",
                        testTag = "scan_tag",
                        onAction = onScanTag
                    )
                    StoredKey.Kind.CARD -> SetupPanel(
                        glyph = Glyph.Card,
                        title = "A card you own",
                        message = "Transit cards, hotel keys and work badges often work. Not every card works. Test yours. Scan it twice so we know its ID is stable.",
                        status = nfcStatus,
                        statusGood = nfcGood,
                        action = when {
                            secret.isNotEmpty() -> "Start over"
                            cardFirst != null -> "Scan it again"
                            else -> "Scan card"
                        },
                        busy = busy,
                        busyLabel = "Hold it near the phone",
                        testTag = "scan_card",
                        onAction = onScanCard
                    )
                }
            }
            Spacer(Modifier.height(Space.m))
            PrimaryButton(
                "Save Key",
                emphasis = ButtonEmphasis.INK,
                enabled = canSave,
                testTag = "save_key",
                onClick = onSave
            )
            Spacer(Modifier.height(Space.l))
        }
    }
}

@Composable
private fun QrSetupPanel(
    bitmap: Bitmap?,
    payload: String,
    onMake: () -> Unit,
    onShare: () -> Unit
) {
    val colors = obColors()
    if (bitmap == null) {
        SetupPanel(
            glyph = Glyph.Qr,
            title = "A printed QR key",
            message = "Make a code, print it, and keep it away from your phone.",
            action = "Make QR code",
            testTag = "make_qr",
            onAction = onMake
        )
    } else {
        Column(
            Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Space.m)
        ) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = "Open Blocker QR key",
                modifier = Modifier
                    .size(240.dp)
                    .shadow(20.dp, RoundedCornerShape(Radius.card), ambientColor = colors.shadow, spotColor = colors.shadow)
                    .background(androidx.compose.ui.graphics.Color.White, RoundedCornerShape(Radius.card))
                    .padding(Space.l)
                    .testTag("qr_preview")
            )
            Text(
                "Print it or save it somewhere you have to walk to. Scan it to unblock.".asCopy(),
                style = ObText.subhead,
                color = colors.inkSecondary,
                textAlign = TextAlign.Center
            )
            Text(
                "Share or print".asCopy(),
                style = ObText.footnote.copy(fontWeight = FontWeight.SemiBold),
                color = colors.ink,
                modifier = Modifier
                    .background(colors.fillQuiet, RoundedCornerShape(50))
                    .clickable(onClick = onShare)
                    .padding(horizontal = Space.m, vertical = 10.dp)
                    .testTag("share_qr")
            )
            if (payload.isNotEmpty()) {
                Text(payload, style = ObText.footnote, color = colors.inkTertiary, textAlign = TextAlign.Center)
            }
        }
    }
}

@Composable
fun SetupPanel(
    glyph: Glyph,
    title: String,
    message: String,
    action: String,
    testTag: String,
    onAction: () -> Unit,
    status: String? = null,
    statusGood: Boolean = false,
    busy: Boolean = false,
    busyLabel: String = "Hold it near the phone"
) {
    val colors = obColors()
    CardSurface {
        Column(
            Modifier.fillMaxWidth().padding(Space.l),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Space.m)
        ) {
            Box(
                Modifier.size(64.dp).background(colors.fillQuiet, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                GlyphIcon(glyph, colors.ink, size = 26.dp)
            }
            Text(title.asCopy(), style = ObText.headline, color = colors.ink, textAlign = TextAlign.Center)
            Text(message.asCopy(), style = ObText.subhead, color = colors.inkSecondary, textAlign = TextAlign.Center)
            if (status != null) {
                Text(
                    status.asCopy(),
                    style = ObText.footnote,
                    color = if (statusGood) colors.success else colors.inkSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.testTag("setup_status")
                )
            }
            PrimaryButton(
                if (busy) busyLabel else action,
                enabled = !busy,
                testTag = testTag,
                onClick = onAction
            )
        }
    }
}
